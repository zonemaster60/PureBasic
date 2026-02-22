; Windows Search Desktop App

EnableExplicit

#APP_NAME   = "HandySearch"
#EMAIL_NAME = "zonemaster60@gmail.com"
Global version.s = "v1.0.0.7"

Procedure.b HasArg(arg$)
  Protected i
  For i = 1 To CountProgramParameters()
    If LCase(ProgramParameter(i - 1)) = LCase(arg$)
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

Global gInstallStartupTaskMode.i = HasArg("--installstartup")
Global gRemoveStartupTaskMode.i  = HasArg("--removestartup")

Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
; Allow helper modes to run even if the GUI app is running.
Global hMutex.i
If gInstallStartupTaskMode = #False And gRemoveStartupTaskMode = #False
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
  If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
    CloseHandle_(hMutex)
    End
  EndIf
EndIf

; Exit confirmation
Procedure.b ConfirmExit()
  Protected req.i
  req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  ProcedureReturn Bool(req = #PB_MessageRequester_Yes)
EndProcedure

#SW_SHOWNORMAL = 1
#WAIT_TIMEOUT = 258

; Forward declarations (avoid ordering issues)
Declare.s ResolveDbPath(dbPath.s)
Declare OpenPath(path.s, showError.i)
Declare EnqueueResult(path.s)
Declare EnqueueResultsBatch(List batch.s())
Declare InitDatabase()
Declare.q GetIndexedCountFast()

; Startup (run at login) helpers
Declare.i IsInStartup()
Declare AddToStartup()
Declare RemoveFromStartup()
Declare UpdateStartupMenuState()

; === Constants and Globals ===
#Window_Main = 0
#Gadget_SearchBar = 1
#Gadget_ResultsList = 2
#Gadget_StartButton = 3
#Gadget_StopButton = 4
#Gadget_FolderPath = 5
#Gadget_BrowseButton = 6
#Gadget_AboutButton = 7
#Gadget_ExitButton = 8
#Gadget_ConfigButton = 9
#Gadget_WebButton = 10
#Timer_PumpResults = 1
#StatusBar_Main = 0

; Query debounce runs off the pump timer.

#Menu_Main = 0
#Menu_ResultsPopup = 1
#Menu_OpenFile = 100
#Menu_OpenFolder = 101
#Menu_StartSearchShortcut = 102

  ; Main menu actions
    #Menu_Index_StartResume = 299
    #Menu_Index_Rebuild = 300
    #Menu_Index_Stop = 301
    #Menu_Index_PauseResume = 306
    #Menu_App_RunAtStartup = 309

  #Menu_Tools_Settings = 302
  #Menu_Tools_OpenIni = 310
  #Menu_Tools_Web = 303
  #Menu_View_Compact = 307
  #Menu_View_LiveMatchFullPath = 308

#Menu_Help_About = 304
#Menu_File_Exit = 305

; System tray
#SysTray_Main = 1
#Menu_TrayPopup = 2
  #Menu_Tray_ShowHide = 200
  #Menu_Tray_RebuildIndex = 201
  #Menu_Tray_OpenDbFolder = 203
  #Menu_Tray_ShowIndexedCount = 204
  #Menu_Tray_ShowDbPath = 205
  #Menu_Tray_Diagnostics = 206
  #Menu_Tray_PauseResume = 207
  #Menu_Tray_RunAtStartup = 208
  #Menu_Tray_Settings = 211
  #Menu_Tray_Exit = 202

#Open_ShowError = 1
#Open_Silent = 0

Global SearchThread.i
Global StopSearch.i
Global SearchActive.i ; legacy
Global ResultMutex.i
Global ProgressMutex.i

; System tray + window behavior
Global AppStartMinimized.i = 0
Global AppCloseToTray.i = 1
Global AppMinimizeToTray.i = 1
Global AppRunAtStartup.i = 0
Global AppAutoStartIndex.i = 0
Global AppCompactMode.i = 0
Global LiveMatchFullPath.i = 1
Global CompactSavedW.i = 0
Global CompactSavedH.i = 0
Global CompactSavedX.i = 0
Global CompactSavedY.i = 0

; SQLite index + query settings
Global IndexDbPath.s = "HandySearch.db"
Global EffectiveDbPath.s = ""
Global SearchMaxResults.i = 10000
Global SearchDebounceMS.i = 120
Global IndexDbId.i = 0
Global IndexingActive.i
Global IndexingPaused.i
Global IndexPauseEvent.i
Global IndexTotalFiles.q
Global CachedIndexedCount.q = -1
Global CachedIndexedCountAtMS.q
Global QueryDirty.i
Global QueryNextAtMS.i
Global LastQueryText.s

; Live incremental results (from worker threads -> UI)
Global LiveMatcherMode.i ; 0=contains, 1=wildcard-regex, 2=regex-query
Global LiveMatcherNeedle.s
Global LiveMatcherRegexID.i
Global NewMap LiveShownPaths.i() ; path -> 1 (GUI thread only)

; Tray icon handle when using embedded EXE icon
Global TrayIconHandle.i
Global LastTrayTooltip.s

; Search worker pool (used for indexing)
Global ConfigBatchSize.i = 200
Global ConfigThreadCount.i = 0 ; 0 = auto

Global ScanStateMutex.i
Global DirQueueSem.i
Global NewList DirQueue.s()
Global QueueCount.i
Global ActiveDirCount.i
Global WorkStop.i
Global WorkerCount.i
Global Dim WorkerThreads.i(0)
 
Global NewList PendingResults.s()
Global NewMap ExcludeDirNames.i()
Global NewMap ExcludeFileNames.i()

Global CurrentFolder.s
Global FilesScanned.q
Global DirsScanned.q
Global MatchesFound.q

#INI_FILE = "HandySearch.ini"

Procedure ClearExcludes()
  ClearMap(ExcludeDirNames())
  ClearMap(ExcludeFileNames())
EndProcedure

Procedure.i IsExcludedFileName(fileName.s)
  Protected key.s = LCase(Trim(fileName))
  If key = "" : ProcedureReturn 0 : EndIf
  ProcedureReturn FindMapElement(ExcludeFileNames(), key)
EndProcedure

Procedure WriteDefaultExcludesIni(filePath.s)
  Protected f.i

  f = CreateFile(#PB_Any, filePath)
  If f = 0
    ProcedureReturn
  EndIf

  WriteStringN(f, "; HandySearch configuration")
  WriteStringN(f, "; Lines are matched case-insensitively against the base name.")
  WriteStringN(f, ";")
  WriteStringN(f, "; Sections:")
  WriteStringN(f, ";   [App]         - UI behavior")
  WriteStringN(f, ";   [Index]       - index/database")
  WriteStringN(f, ";   [Search]      - query behavior")
  WriteStringN(f, ";   [Performance] - performance tuning")
  WriteStringN(f, ";   [ExcludeDirs]  - folder names to skip")
  WriteStringN(f, ";   [ExcludeFiles] - file names to skip")
  WriteStringN(f, "")

  WriteStringN(f, "[App]")
  WriteStringN(f, "; StartMinimized=1 starts hidden in the tray")
  WriteStringN(f, "StartMinimized=0")
  WriteStringN(f, "; CloseToTray=1 makes the X button hide to tray")
  WriteStringN(f, "CloseToTray=1")
  WriteStringN(f, "; MinimizeToTray=1 hides when minimized")
  WriteStringN(f, "MinimizeToTray=1")
  WriteStringN(f, "; RunAtStartup=1 registers a Task Scheduler logon task")
  WriteStringN(f, "RunAtStartup=0")
  WriteStringN(f, "; AutoStartIndex=1 starts indexing on launch")
  WriteStringN(f, "AutoStartIndex=0")
  WriteStringN(f, "; LiveMatchFullPath=1 makes live streamed results match full paths")
  WriteStringN(f, "LiveMatchFullPath=1")
  WriteStringN(f, "")

  WriteStringN(f, "[Index]")
  WriteStringN(f, "; DbPath is relative to the EXE folder if not absolute")
  WriteStringN(f, "DbPath=HandySearch.db")
  WriteStringN(f, "")

  WriteStringN(f, "[Search]")
  WriteStringN(f, "MaxResults=10000")
  WriteStringN(f, "DebounceMS=120")
  WriteStringN(f, "")

  WriteStringN(f, "[Performance]")
  WriteStringN(f, "; Threads=0 means auto (2x CPU, max 32)")
  WriteStringN(f, "Threads=0")
  WriteStringN(f, "; BatchSize controls how many results are queued per lock")
  WriteStringN(f, "BatchSize=200")
  WriteStringN(f, "")
 
  WriteStringN(f, "[ExcludeDirs]")
  ; Keep defaults small so it behaves closer to Everything.
  WriteStringN(f, "programdata")
  WriteStringN(f, "$recycle.bin")
  WriteStringN(f, "system volume information")
  WriteStringN(f, "windows")
  WriteStringN(f, "")

  WriteStringN(f, "[ExcludeFiles]")
  WriteStringN(f, "desktop.ini")
  WriteStringN(f, "pagefile.sys")
  WriteStringN(f, "swapfile.sys")

  CloseFile(f)
EndProcedure

Procedure ClampConfigValues()
  If ConfigThreadCount < 0
    ConfigThreadCount = 0
  EndIf

  If ConfigBatchSize < 10
    ConfigBatchSize = 10
  EndIf
  If ConfigBatchSize > 5000
    ConfigBatchSize = 5000
  EndIf

  If SearchMaxResults < 100
    SearchMaxResults = 100
  EndIf
  If SearchMaxResults > 200000
    SearchMaxResults = 200000
  EndIf

  If SearchDebounceMS < 0
    SearchDebounceMS = 0
  EndIf
  If SearchDebounceMS > 5000
    SearchDebounceMS = 5000
  EndIf

  If Trim(IndexDbPath) = ""
    IndexDbPath = "HandySearch.db"
  EndIf
EndProcedure

Procedure LoadExcludesIni(filePath.s)
  Protected line.s, section.s, item.s
  Protected pos.i, f.i
  Protected key.s, value.s
  Protected vLower.s

  ClearExcludes()

  If FileSize(filePath) < 0
    WriteDefaultExcludesIni(filePath)
  EndIf

  If FileSize(filePath) < 0
    ProcedureReturn
  EndIf

  f = ReadFile(#PB_Any, filePath)
  If f = 0
    ProcedureReturn
  EndIf

  section = ""
  While Eof(f) = 0
    line = Trim(ReadString(f))

    If line = "" : Continue : EndIf
    If Left(line, 1) = ";" Or Left(line, 1) = "#" : Continue : EndIf

    pos = FindString(line, ";", 1)
    If pos > 0
      line = Trim(Left(line, pos - 1))
    EndIf
    If line = "" : Continue : EndIf

    If Left(line, 1) = "[" And Right(line, 1) = "]"
      section = LCase(Trim(Mid(line, 2, Len(line) - 2)))
      Continue
    EndIf

    ; Allow either "name" or "key=name" formats.
    pos = FindString(line, "=", 1)
    If pos > 0
      key = LCase(Trim(Left(line, pos - 1)))
      value = Trim(Mid(line, pos + 1))
    Else
      key = ""
      value = Trim(line)
    EndIf

    ; For exclude lists we also accept "name=" (empty value).
    If value = ""
      If section <> "excludedirs" And section <> "excludedir" And section <> "excludefiles" And section <> "excludefile"
        Continue
      EndIf
    EndIf

      Select section
        Case "app"
          Select key
            Case "startminimized"
              AppStartMinimized = Val(value)
            Case "closetotray"
              AppCloseToTray = Val(value)
            Case "minimizetotray"
              AppMinimizeToTray = Val(value)
            Case "runatstartup"
              AppRunAtStartup = Val(value)
            Case "autostartindex"
              AppAutoStartIndex = Val(value)
            Case "livematchfullpath"
              LiveMatchFullPath = Val(value)
          EndSelect

        Case "index"
          Select key
            Case "dbpath"
              IndexDbPath = value
          EndSelect

        Case "search"
          Select key
            Case "maxresults"
              SearchMaxResults = Val(value)
            Case "debouncems"
              SearchDebounceMS = Val(value)
          EndSelect

        Case "performance"
          Select key
            Case "threads"
              ConfigThreadCount = Val(value)
            Case "batchsize"
              ConfigBatchSize = Val(value)
          EndSelect

        Case "excludedirs", "excludedir"
          ; Support lines like:
          ;   windows
          ;   windows=
          ;   windows=1
          ;   enabled=windows
          item = ""
          If key <> ""
            vLower = LCase(Trim(value))
            Select vLower
              Case "", "1", "true", "yes", "on"
                item = key
              Case "0", "false", "no", "off"
                item = ""
              Default
                item = value
            EndSelect
          Else
            item = value
          EndIf

          item = LCase(Trim(item))
          If item <> ""
            ExcludeDirNames(item) = 1
          EndIf

        Case "excludefiles", "excludefile"
          ; Same rules as ExcludeDirs.
          item = ""
          If key <> ""
            vLower = LCase(Trim(value))
            Select vLower
              Case "", "1", "true", "yes", "on"
                item = key
              Case "0", "false", "no", "off"
                item = ""
              Default
                item = value
            EndSelect
          Else
            item = value
          EndIf

          item = LCase(Trim(item))
          If item <> ""
            ExcludeFileNames(item) = 1
          EndIf

      EndSelect

  Wend

  CloseFile(f)
  ClampConfigValues()
EndProcedure

Procedure SaveIniKey(filePath.s, sectionName.s, keyName.s, value.s)
  ; Best-effort: updates/creates a simple key=value entry.
  ; If the file doesn't exist yet, create defaults first.
  If FileSize(filePath) < 0
    WriteDefaultExcludesIni(filePath)
  EndIf

  If FileSize(filePath) < 0
    ProcedureReturn
  EndIf

  If OpenPreferences(filePath)
    PreferenceGroup(sectionName)
    WritePreferenceString(keyName, value)
    ClosePreferences()
  EndIf
EndProcedure

Procedure.i IsExcludedDirName(dirName.s)
  Protected key.s = LCase(Trim(dirName))
  If key = "" : ProcedureReturn 0 : EndIf
  ProcedureReturn FindMapElement(ExcludeDirNames(), key)
EndProcedure

Procedure.s StartupTaskName()
  ProcedureReturn #APP_NAME
EndProcedure

Procedure.s StartupTaskUserId()
  Protected user.s = GetEnvironmentVariable("USERNAME")
  Protected domain.s = GetEnvironmentVariable("USERDOMAIN")

  If user = ""
    ProcedureReturn ""
  EndIf

  If domain <> ""
    ProcedureReturn domain + "\\" + user
  EndIf

  ProcedureReturn user
EndProcedure

Procedure RemoveLegacyStartupRegistryEntry()
  ; Older versions may have used HKCU\...\Run. Best-effort cleanup.
  Protected cmd.s = "reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v " + #APP_NAME + " /f"
  RunProgram("cmd.exe", "/c " + cmd, "", #PB_Program_Hide)
EndProcedure

Global gLastExecExitCode.i

Procedure.s RunAndCapture(exe.s, args.s)
  Protected output.s = ""

  Protected program = RunProgram(exe, args, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If program = 0
    gLastExecExitCode = -1
    ProcedureReturn output
  EndIf

  While ProgramRunning(program)
    While AvailableProgramOutput(program)
      output + ReadProgramString(program) + #CRLF$
    Wend
  Wend

  While AvailableProgramOutput(program)
    output + ReadProgramString(program) + #CRLF$
  Wend

  gLastExecExitCode = ProgramExitCode(program)
  CloseProgram(program)

  ProcedureReturn output
EndProcedure

Procedure.b IsProcessElevated()
  ; TokenElevation (20)
  #TokenElevation = 20

  Protected hToken.i
  If OpenProcessToken_(GetCurrentProcess_(), $0008, @hToken) = 0
    ProcedureReturn #False
  EndIf

  Protected elevation.l
  Protected cbSize.l
  Protected ok = GetTokenInformation_(hToken, #TokenElevation, @elevation, SizeOf(Long), @cbSize)
  CloseHandle_(hToken)

  If ok = 0
    ProcedureReturn #False
  EndIf

  ProcedureReturn Bool(elevation <> 0)
EndProcedure

Procedure RelaunchSelfElevated(args.s)
  Protected exe$ = ProgramFilename()
  ShellExecute_(0, "runas", exe$, args, AppPath, 1)
EndProcedure

Procedure AddToStartup()
  RemoveLegacyStartupRegistryEntry()

  ; Create/update an interactive scheduled task so the tray icon shows up.
  Protected taskName.s = StartupTaskName()

  Protected psTaskName.s = ReplaceString(taskName, "'", "''")
  Protected psExe.s = ReplaceString(ProgramFilename(), "'", "''")
  Protected psWorkDir.s = ReplaceString(AppPath, "'", "''")
  Protected psUser.s = ReplaceString(StartupTaskUserId(), "'", "''")

  Protected psCmd.s
  psCmd = "try {" +
          " $ErrorActionPreference='Stop';" +
          " $taskName='" + psTaskName + "';" +
          " $exe='" + psExe + "';" +
          " $wd='" + psWorkDir + "';" +
          " $user='" + psUser + "';" +
          " if ($user -eq '') { throw 'Unable to determine current user for scheduled task.' };" +
          " $action=New-ScheduledTaskAction -Execute $exe -WorkingDirectory $wd;" +
          " $trigger=New-ScheduledTaskTrigger -AtLogOn -User $user;" +
          " $trigger.Delay='PT1M';" +
          " $settings=New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew;" +
          " $principal=New-ScheduledTaskPrincipal -UserId $user -LogonType Interactive -RunLevel Highest;" +
          " Register-ScheduledTask -TaskName $taskName -Action $action -Trigger $trigger -Settings $settings -Principal $principal -Force | Out-Null;" +
          " Write-Output ('OK: task created/updated: ' + $taskName);" +
          "} catch {" +
          " Write-Output ('ERROR: ' + $_.Exception.Message);" +
          " if ($_.ScriptStackTrace) { Write-Output $_.ScriptStackTrace };" +
          " exit 1" +
          "}"

  RunAndCapture("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -Command " + Chr(34) + psCmd + Chr(34))
EndProcedure

Procedure RemoveFromStartup()
  RemoveLegacyStartupRegistryEntry()

  If IsProcessElevated() = #False And gRemoveStartupTaskMode = #False
    RelaunchSelfElevated("--removestartup")
    ProcedureReturn
  EndIf

  Protected nameQuoted.s = Chr(34) + StartupTaskName() + Chr(34)
  Protected cmd.s = "/c schtasks /Delete /TN " + nameQuoted + " /F"
  RunAndCapture("cmd.exe", cmd)
EndProcedure

Procedure.i IsInStartup()
  Protected nameQuoted.s = Chr(34) + StartupTaskName() + Chr(34)
  Protected cmd.s = "schtasks /Query /TN " + nameQuoted

  Protected program = RunProgram("cmd.exe", "/c " + cmd, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If program
    While ProgramRunning(program)
      While AvailableProgramOutput(program)
        ReadProgramString(program)
      Wend
    Wend

    Protected code.i = ProgramExitCode(program)
    CloseProgram(program)
    ProcedureReturn Bool(code = 0)
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure UpdateStartupMenuState()
  If IsMenu(#Menu_Main)
    SetMenuItemState(#Menu_Main, #Menu_App_RunAtStartup, Bool(AppRunAtStartup))
  EndIf

  If IsMenu(#Menu_TrayPopup)
    SetMenuItemState(#Menu_TrayPopup, #Menu_Tray_RunAtStartup, Bool(AppRunAtStartup))
  EndIf
EndProcedure

Procedure UpdateControlStates()
  ; Only call this on the main (GUI) thread.
  ; Buttons are now a menu, so the only thing to keep responsive
  ; is the search bar.
  DisableGadget(#Gadget_SearchBar, #False)
EndProcedure

; === Search Parameters ===
Structure SearchParams
  Directory.s
  Pattern.s
  IncludeContent.i
  UseRegex.i
  UseFuzzy.i
EndStructure

Procedure.s WildcardToRegex(pattern.s)
  Protected out.s = "^"
  Protected i.i, ch.s

  For i = 1 To Len(pattern)
    ch = Mid(pattern, i, 1)
    Select ch
      Case "*"
        out + ".*"

      Case "?"
        out + "."

      ; Regex metacharacters that must be escaped with a single backslash
      Case ".", "^", "$", "+", "(", ")", "[", "]", "{", "}", "|"
        out + "\" + ch

      ; Literal backslash in the input pattern
      Case "\"
        out + "\"

      Default
        out + ch
    EndSelect
  Next

  ProcedureReturn out + "$"
EndProcedure

Procedure.i MatchPatternPrecompiled(text.s, pattern.s, regexID.i)
  If regexID
    ProcedureReturn MatchRegularExpression(regexID, text)
  EndIf

  ; Fallback: if regex compilation fails, do a simple case-insensitive contains.
  ; Strip wildcards so "*foo*" behaves like contains("foo").
  Protected needle.s = ReplaceString(pattern, "*", "")
  needle = ReplaceString(needle, "?", "")
  needle = Trim(needle)
  If needle <> "" And FindString(LCase(text), LCase(needle), 1)
    ProcedureReturn 1
  EndIf

  ProcedureReturn 0
EndProcedure

Procedure.s NormalizePath(path.s)
  Protected p.s = Trim(path)
  Protected prefix.s = ""
  Protected back.s = Chr(92)
  Protected dbl.s = back + back

  ; Collapse repeated backslashes, but preserve UNC prefix (\\Server\Share).
  If Left(p, 2) = dbl
    prefix = dbl
    p = Mid(p, 3)

    ; Drop any additional slashes after the UNC prefix.
    While Left(p, 1) = back
      p = Mid(p, 2)
    Wend
  EndIf

  While FindString(p, dbl, 1)
    p = ReplaceString(p, dbl, back)
  Wend

  ProcedureReturn prefix + p
EndProcedure

Procedure AddProgressFiles(scannedFiles.q, matches.q)
  If ProgressMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ProgressMutex)
  FilesScanned + scannedFiles
  MatchesFound + matches
  UnlockMutex(ProgressMutex)
EndProcedure

Procedure AddProgressDir()
  If ProgressMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ProgressMutex)
  DirsScanned + 1
  UnlockMutex(ProgressMutex)
EndProcedure

Procedure SetProgressFolder(folder.s)
  If ProgressMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ProgressMutex)
  CurrentFolder = folder
  UnlockMutex(ProgressMutex)
EndProcedure

Procedure EnqueueResult(path.s)
  If ResultMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ResultMutex)
  AddElement(PendingResults())
  PendingResults() = path
  UnlockMutex(ResultMutex)
EndProcedure

Procedure EnqueueResultsBatch(List batch.s())
  If ResultMutex = 0
    ProcedureReturn
  EndIf

  If ListSize(batch()) = 0
    ProcedureReturn
  EndIf

  LockMutex(ResultMutex)
  ForEach batch()
    AddElement(PendingResults())
    PendingResults() = batch()
  Next
  UnlockMutex(ResultMutex)
EndProcedure

Procedure PushDirectory(dir.s)
  ; Expect normalized dirs with trailing backslash
  LockMutex(ScanStateMutex)
  AddElement(DirQueue())
  DirQueue() = dir
  QueueCount + 1
  UnlockMutex(ScanStateMutex)

  ReleaseSemaphore_(DirQueueSem, 1, 0)
EndProcedure

Procedure.s PopDirectory()
  Protected dir.s

  LockMutex(ScanStateMutex)
  If FirstElement(DirQueue())
    dir = DirQueue()
    DeleteElement(DirQueue())
    QueueCount - 1
    ActiveDirCount + 1
  EndIf
  UnlockMutex(ScanStateMutex)

  ProcedureReturn dir
EndProcedure

Procedure MarkDirectoryDone()
  LockMutex(ScanStateMutex)
  If ActiveDirCount > 0
    ActiveDirCount - 1
  EndIf
  UnlockMutex(ScanStateMutex)
EndProcedure

Procedure SearchDirectoryWorker(dir.s, pattern.s, regexID.i, List localResults.s())
  ; Deprecated: kept for compatibility with older structure.
EndProcedure

Structure IndexRecord
  Path.s
  Name.s
  Dir.s
  Size.q
  MTime.q
EndStructure

Procedure.b IsReparsePoint(fullPath.s)
  Protected attrs.i = GetFileAttributes_(fullPath)
  If attrs = -1
    ProcedureReturn #False
  EndIf
  ProcedureReturn Bool(attrs & $400) ; FILE_ATTRIBUTE_REPARSE_POINT
EndProcedure

Procedure IndexDirectoryWorker(dir.s, List batch.IndexRecord())
  Protected dirID.i, entryName.s, fullpath.s
  Protected localFiles.q

  If WorkStop Or StopSearch
    ProcedureReturn
  EndIf

  If Right(dir, 1) <> "\"
    dir = dir + "\"
  EndIf

  SetProgressFolder(dir)
  AddProgressDir()

  dirID = ExamineDirectory(#PB_Any, dir, "*.*")
  If dirID = 0
    ProcedureReturn
  EndIf

  While NextDirectoryEntry(dirID)
    If WorkStop Or StopSearch : Break : EndIf

    entryName = DirectoryEntryName(dirID)
    If entryName = "." Or entryName = ".."
      Continue
    EndIf

    fullpath = dir + entryName

    Select DirectoryEntryType(dirID)
      Case #PB_DirectoryEntry_File
        localFiles + 1
        If IsExcludedFileName(entryName) = 0
          AddElement(batch())
          batch()\Path = fullpath
          batch()\Name = entryName
          batch()\Dir = dir
          batch()\Size = DirectoryEntrySize(dirID)
          batch()\MTime = DirectoryEntryDate(dirID, #PB_Date_Modified)
        EndIf

      Case #PB_DirectoryEntry_Directory
        If IsExcludedDirName(entryName) = 0
          ; Avoid junction loops. Best-effort: check the directory entry itself.
          If IsReparsePoint(fullpath) = 0
            PushDirectory(fullpath + "\")
          EndIf
        EndIf

    EndSelect

  Wend

  FinishDirectory(dirID)

  If localFiles
    AddProgressFiles(localFiles, 0)
  EndIf
EndProcedure

; === GUI Setup ===
Procedure ResizeMainWindow()
  If IsWindow(#Window_Main) = 0
    ProcedureReturn
  EndIf

  ; Use the inner client size so gadget layout doesn't drift
  ; due to border/titlebar sizing differences.
  Protected w.i = WindowWidth(#Window_Main, #PB_Window_InnerCoordinate)
  Protected h.i = WindowHeight(#Window_Main, #PB_Window_InnerCoordinate)
  Protected margin.i
  Protected searchH.i
  Protected listTop.i
  Protected listH.i

  If AppCompactMode
    margin = 6
    searchH = 22
  Else
    margin = 10
    searchH = 25
  EndIf

  listTop = margin + searchH + 5

  ; StatusBarHeight() occasionally returns 0 during resize on some setups.
  ; Fall back to measuring the underlying control height.
  Protected statusH.i = 0
  statusH = StatusBarHeight(#StatusBar_Main)
  If statusH <= 0
    ; Avoid naming conflicts with system/resident RECT.
    Structure HS_RECT
      left.l
      top.l
      right.l
      bottom.l
    EndStructure
    Protected r.HS_RECT
    Protected hStatus.i = StatusBarID(#StatusBar_Main)
    If hStatus And GetWindowRect_(hStatus, @r)
      statusH = r\bottom - r\top
    EndIf
  EndIf
  If statusH < 0 : statusH = 0 : EndIf

  listH = h - listTop - margin - statusH
  If listH < 50 : listH = 50 : EndIf

  Protected usableW.i = w - margin * 2
  If usableW < 50 : usableW = 50 : EndIf

  ResizeGadget(#Gadget_SearchBar, margin, margin, usableW, searchH)
  ResizeGadget(#Gadget_ResultsList, margin, listTop, usableW, listH)
EndProcedure

Procedure SetCompactMode(enable.i)
  If AppCompactMode = Bool(enable)
    ProcedureReturn
  EndIf

  AppCompactMode = Bool(enable)

  If AppCompactMode
    ; Save current position/size, then shrink.
    CompactSavedX = WindowX(#Window_Main)
    CompactSavedY = WindowY(#Window_Main)
    CompactSavedW = WindowWidth(#Window_Main)
    CompactSavedH = WindowHeight(#Window_Main)
    ResizeWindow(#Window_Main, #PB_Ignore, #PB_Ignore, 640, 380)
  Else
    ; Restore previous position/size if we have it.
    If CompactSavedW > 0 And CompactSavedH > 0
      ResizeWindow(#Window_Main, CompactSavedX, CompactSavedY, CompactSavedW, CompactSavedH)
    EndIf
  EndIf

  If IsMenu(#Menu_Main)
    SetMenuItemState(#Menu_Main, #Menu_View_Compact, AppCompactMode)
    SetMenuItemState(#Menu_Main, #Menu_View_LiveMatchFullPath, LiveMatchFullPath)
  EndIf

  ResizeMainWindow()
EndProcedure

Procedure InitGUI()
  OpenWindow(#Window_Main, 100, 100, 800, 600, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget |
                                                                        #PB_Window_ScreenCentered | #PB_Window_SizeGadget)

  ; Prevent resizing so small that gadgets overlap system chrome.
  WindowBounds(#Window_Main, 420, 220, #PB_Ignore, #PB_Ignore)

  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_Return, #Menu_StartSearchShortcut)

  ; Main menu (replaces the button bar).
  CreateMenu(#Menu_Main, WindowID(#Window_Main))
  MenuTitle("File")
  MenuItem(#Menu_File_Exit, "Exit")
  MenuTitle("Index")
  MenuItem(#Menu_Index_StartResume, "Start/Resume")
  MenuItem(#Menu_Index_Rebuild, "Rebuild")
  MenuItem(#Menu_Index_PauseResume, "Pause")
  MenuItem(#Menu_Index_Stop, "Stop")
  MenuTitle("View")
  MenuItem(#Menu_View_Compact, "Compact mode")
  MenuItem(#Menu_View_LiveMatchFullPath, "Live match full path")
  MenuTitle("App")
  MenuItem(#Menu_App_RunAtStartup, "Run at startup")
  SetMenuItemState(#Menu_Main, #Menu_App_RunAtStartup, Bool(AppRunAtStartup))
  MenuTitle("Tools")
  MenuItem(#Menu_Tools_Settings, "Settings")
  MenuItem(#Menu_Tools_OpenIni, "Open INI")
  MenuItem(#Menu_Tools_Web, "Web")
  MenuTitle("Help")
  MenuItem(#Menu_Help_About, "About")

  StringGadget(#Gadget_SearchBar, 10, 10, 780, 25, "*.*")
  ListViewGadget(#Gadget_ResultsList, 10, 40, 780, 510)

  ; Legacy gadgets kept (in case other code relies on IDs), but hidden.
  StringGadget(#Gadget_FolderPath, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_BrowseButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_AboutButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_ExitButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_StartButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_StopButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_ConfigButton, 0, 0, 0, 0, "")
  ButtonGadget(#Gadget_WebButton, 0, 0, 0, 0, "")
  HideGadget(#Gadget_FolderPath, 1)
  HideGadget(#Gadget_BrowseButton, 1)
  HideGadget(#Gadget_AboutButton, 1)
  HideGadget(#Gadget_ExitButton, 1)
  HideGadget(#Gadget_StartButton, 1)
  HideGadget(#Gadget_StopButton, 1)
  HideGadget(#Gadget_ConfigButton, 1)
  HideGadget(#Gadget_WebButton, 1)

  CreatePopupMenu(#Menu_ResultsPopup)
  MenuItem(#Menu_OpenFile, "Open")
  MenuItem(#Menu_OpenFolder, "Open containing folder")

  CreatePopupMenu(#Menu_TrayPopup)
  MenuItem(#Menu_Tray_ShowHide, "Show/Hide")
  MenuItem(#Menu_Tray_RebuildIndex, "Rebuild index (clears DB)")
  MenuItem(#Menu_Tray_OpenDbFolder, "Open DB folder")
  MenuItem(#Menu_Tray_ShowIndexedCount, "Show indexed count")
  MenuItem(#Menu_Tray_ShowDbPath, "Show DB path")
  MenuItem(#Menu_Tray_Diagnostics, "Diagnostics")
  MenuItem(#Menu_Tray_PauseResume, "Pause")
  MenuBar()
  MenuItem(#Menu_Tray_RunAtStartup, "Run at startup")
  SetMenuItemState(#Menu_TrayPopup, #Menu_Tray_RunAtStartup, Bool(AppRunAtStartup))
  MenuItem(#Menu_Tray_Settings, "Settings")
  MenuBar()
  MenuItem(#Menu_Tray_Exit, "Exit")

  CreateStatusBar(#StatusBar_Main, WindowID(#Window_Main))
  AddStatusBarField(540)
  AddStatusBarField(#PB_Ignore)

  StatusBarText(#StatusBar_Main, 0, "Idle")
  StatusBarText(#StatusBar_Main, 1, "")

  AddWindowTimer(#Window_Main, #Timer_PumpResults, 50)
  ResizeMainWindow()

  ; Tray icon: prefer HandySearch.ico next to the EXE, otherwise use the embedded EXE icon.
  Protected trayImage.i
  Protected trayIcon.i
  Protected appExe.s

  TrayIconHandle = 0
  trayImage = LoadImage(#PB_Any, "HandySearch.ico")

  If trayImage
    trayIcon = ImageID(trayImage)
  Else
    ; Extract a small icon from the running EXE and use the HICON directly.
    appExe = ProgramFilename()
    If appExe <> ""
      Protected smallIcon.i
      Protected largeIcon.i
      If ExtractIconEx_(appExe, 0, @largeIcon, @smallIcon, 1) > 0
        If smallIcon
          TrayIconHandle = smallIcon
        ElseIf largeIcon
          TrayIconHandle = largeIcon
        EndIf
      EndIf
      ; If we didn't use one of them, destroy it.
      If largeIcon And largeIcon <> TrayIconHandle : DestroyIcon_(largeIcon) : EndIf
      If smallIcon And smallIcon <> TrayIconHandle : DestroyIcon_(smallIcon) : EndIf
    EndIf
  EndIf

  ; Add a tray icon (best effort).
  If TrayIconHandle
    AddSysTrayIcon(#SysTray_Main, WindowID(#Window_Main), TrayIconHandle)
  ElseIf trayImage
    AddSysTrayIcon(#SysTray_Main, WindowID(#Window_Main), trayIcon)
  Else
    ; Final fallback: placeholder image.
    trayImage = CreateImage(#PB_Any, 16, 16)
    If trayImage
      StartDrawing(ImageOutput(trayImage))
      Box(0, 0, 16, 16, RGB(10, 120, 220))
      StopDrawing()
      AddSysTrayIcon(#SysTray_Main, WindowID(#Window_Main), ImageID(trayImage))
    EndIf
  EndIf

  UpdateControlStates()
EndProcedure

; === File Search Thread ===
Structure WorkerParams
  Dummy.i
EndStructure

; DB insert batching is done per worker; DB access is protected by a single mutex.
Global DbMutex.i

Procedure.s DbEscape(text.s)
  ; SQLite uses single quotes, escaped as doubled single quotes.
  ProcedureReturn ReplaceString(text, "'", "''")
EndProcedure

Procedure FlushIndexBatchToDb(List batch.IndexRecord())
  Protected sql.s
  Protected values.s
  Protected cnt.i
  Protected rowCount.i
  Protected NewList pathsForUi.s()
 
  If IndexDbId = 0 Or DbMutex = 0
    ClearList(batch())
    ProcedureReturn
  EndIf
 
  rowCount = ListSize(batch())
  If rowCount = 0
    ProcedureReturn
  EndIf
 
  ; Build a single INSERT with many VALUES to reduce SQLite parse overhead.
  ; Chunk so the SQL statement doesn't grow unbounded.
  LockMutex(DbMutex)
 
  DatabaseUpdate(IndexDbId, "BEGIN TRANSACTION;")
 
  cnt = 0
  values = ""
  ForEach batch()
    If values <> "" : values + "," : EndIf
    values + "('" + DbEscape(batch()\Path) + "','" + DbEscape(batch()\Name) + "','" + DbEscape(batch()\Dir) + "'," +
              Str(batch()\Size) + "," + Str(batch()\MTime) + ")"
 
    ; Stream paths to the UI so results can appear as indexing runs.
    AddElement(pathsForUi())
    pathsForUi() = batch()\Path
 
    IndexTotalFiles + 1
    cnt + 1
 
    ; ~500 rows per statement keeps it snappy and avoids huge SQL strings.
    If cnt >= 500
      sql = "INSERT OR REPLACE INTO files(path,name,dir,size,mtime) VALUES" + values + ";"
      DatabaseUpdate(IndexDbId, sql)
      values = ""
      cnt = 0
    EndIf
  Next
 
  If values <> ""
    sql = "INSERT OR REPLACE INTO files(path,name,dir,size,mtime) VALUES" + values + ";"
    DatabaseUpdate(IndexDbId, sql)
  EndIf
 
  ; Persist the running count so showing it is instant.
  DatabaseUpdate(IndexDbId, "INSERT OR REPLACE INTO meta(key,value) VALUES('indexed_count','" + Str(IndexTotalFiles) + "');")
 
  DatabaseUpdate(IndexDbId, "COMMIT;")
 
  UnlockMutex(DbMutex)
  EnqueueResultsBatch(pathsForUi())
 
  ClearList(batch())
EndProcedure

Procedure WorkerThreadProc(*params.WorkerParams)
  Protected dir.s
  Protected NewList batch.IndexRecord()
 
  While WorkStop = 0 And StopSearch = 0
    ; Pause support: block workers while paused (but re-check stop regularly).
    If IndexingPaused And IndexPauseEvent
      WaitForSingleObject_(IndexPauseEvent, 200)
      Continue
    EndIf

    If WaitForSingleObject_(DirQueueSem, 200) = #WAIT_TIMEOUT

      LockMutex(ScanStateMutex)
      If QueueCount = 0 And ActiveDirCount = 0
        UnlockMutex(ScanStateMutex)
        Break
      EndIf
      UnlockMutex(ScanStateMutex)
      Continue
    EndIf

    If WorkStop Or StopSearch
      Break
    EndIf

    dir = PopDirectory()
    If dir = ""
      Continue
    EndIf

    IndexDirectoryWorker(dir, batch())
    If ListSize(batch()) >= ConfigBatchSize
      FlushIndexBatchToDb(batch())
    EndIf

    MarkDirectoryDone()
  Wend

  If ListSize(batch()) > 0
    FlushIndexBatchToDb(batch())
  EndIf
EndProcedure

Procedure.i GetCpuCount()
  Protected cpu.i = Val(GetEnvironmentVariable("NUMBER_OF_PROCESSORS"))
  If cpu < 1
    cpu = 4
  EndIf
  ProcedureReturn cpu
EndProcedure

Procedure GetAllFixedDriveRoots(List roots.s())
  ; GetLogicalDriveStrings_ returns a MULTI_SZ in TCHARs (Unicode on modern PB).
  Protected bufChars.i = 4096
  Protected *buf
  Protected posChars.i
  Protected drive.s
  Protected dt.i
 
  ClearList(roots())
 
  *buf = AllocateMemory(bufChars * SizeOf(Character))
  If *buf = 0
    ProcedureReturn
  EndIf
 
  If GetLogicalDriveStrings_(bufChars, *buf) = 0
    FreeMemory(*buf)
    ProcedureReturn
  EndIf
 
  posChars = 0
  While PeekS(*buf + posChars * SizeOf(Character), -1) <> ""
    drive = PeekS(*buf + posChars * SizeOf(Character), -1)
    posChars + Len(drive) + 1
 
    dt = GetDriveType_(drive)
    If dt = 3 ; DRIVE_FIXED
      AddElement(roots())
      roots() = drive
    EndIf
  Wend
 
  FreeMemory(*buf)
EndProcedure

Procedure StartIndexingAllFixedDrives()
  Protected i.i
  Protected NewList roots.s()
  Protected *wparams.WorkerParams
 
  ; Note: stopping/waiting an existing run is handled by StartIndexing() on the main thread.
 
  StopSearch = 0
  WorkStop = 0
  IndexTotalFiles = 0
  WorkerCount = -1 ; diagnostics: thread entered

  ; Ensure pause event exists and start unpaused.
  If IndexPauseEvent = 0
    ; Manual reset event: signaled = running, unsignaled = paused.
    IndexPauseEvent = CreateEvent_(0, 1, 1, 0)
  Else
    SetEvent_(IndexPauseEvent)
  EndIf
  IndexingPaused = 0

  If ProgressMutex
    LockMutex(ProgressMutex)
    CurrentFolder = ""
    FilesScanned = 0
    DirsScanned = 0
    MatchesFound = 0
    UnlockMutex(ProgressMutex)
  EndIf

  ; Ensure scan state objects.
  If ScanStateMutex = 0
    ScanStateMutex = CreateMutex()
  EndIf
  If DirQueueSem = 0
    DirQueueSem = CreateSemaphore_(0, 0, 2147483647, 0)
  EndIf

  ; Reset queue.
  LockMutex(ScanStateMutex)
  ClearList(DirQueue())
  QueueCount = 0
  ActiveDirCount = 0
  UnlockMutex(ScanStateMutex)

  GetAllFixedDriveRoots(roots())
  If ListSize(roots()) = 0
    AddElement(roots()) : roots() = "C:\"
  EndIf

  ForEach roots()
    PushDirectory(roots())
  Next

  ; Worker count: [Performance] Threads=0 means auto
  WorkerCount = ConfigThreadCount
  If WorkerCount <= 0
    WorkerCount = GetCpuCount() * 2
    If WorkerCount < 2
      WorkerCount = 4
    EndIf
    If WorkerCount > 32
      WorkerCount = 32
    EndIf
  Else
    If WorkerCount < 1
      WorkerCount = 1
    EndIf
    If WorkerCount > 64
      WorkerCount = 64
    EndIf
  EndIf

  IndexingActive = 1

  ReDim WorkerThreads(WorkerCount - 1)
  *wparams = AllocateStructure(WorkerParams)
  If *wparams
    *wparams\Dummy = 0
  EndIf

  For i = 0 To WorkerCount - 1
    WorkerThreads(i) = CreateThread(@WorkerThreadProc(), *wparams)
  Next

  ; Wait for workers (in this thread)
  For i = 0 To WorkerCount - 1
    If WorkerThreads(i)
      WaitThread(WorkerThreads(i))
      WorkerThreads(i) = 0
    EndIf
  Next

  If *wparams
    FreeStructure(*wparams)
  EndIf

  IndexingActive = 0
EndProcedure

Procedure SearchThreadProc(*params.SearchParams)
  ; Legacy entrypoint name: now runs indexing.
  StartIndexingAllFixedDrives()
  If *params
    FreeStructure(*params)
  EndIf
EndProcedure

Procedure.s SelectedResultPath()
  Protected idx.i = GetGadgetState(#Gadget_ResultsList)
  If idx >= 0
    ProcedureReturn GetGadgetItemText(#Gadget_ResultsList, idx)
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure.s UrlEncode(text.s)
  Protected i.i, n.i, ch.i
  Protected out.s = ""
  Protected len.i = StringByteLength(text, #PB_UTF8)

  If len <= 0
    ProcedureReturn ""
  EndIf

  Protected *mem = AllocateMemory(len + 1)
  If *mem = 0
    ProcedureReturn ""
  EndIf

  PokeS(*mem, text, -1, #PB_UTF8)

  For i = 0 To len - 1
    ch = PeekA(*mem + i) & $FF
    Select ch
      Case '0' To '9', 'A' To 'Z', 'a' To 'z', 45, 46, 95, 126 ; - . _ ~
        out + Chr(ch)
      Case 32
        out + "+"
      Default
        out + "%" + RSet(UCase(Hex(ch)), 2, "0")
    EndSelect
  Next

  FreeMemory(*mem)
  ProcedureReturn out
EndProcedure

Procedure WebSearch(showError.i)
  Protected query.s = Trim(GetGadgetText(#Gadget_SearchBar))
  Protected url.s

  If query = ""
    ProcedureReturn
  EndIf

  url = "https://www.google.com/search?q=" + UrlEncode(query)
  If ShellExecute_(0, "open", url, 0, 0, #SW_SHOWNORMAL) <= 32
    If showError
      MessageRequester(#APP_NAME, "Failed To open browser for:" + #CRLF$ + url, #PB_MessageRequester_Error)
    EndIf
  EndIf
EndProcedure

Procedure OpenPath(path.s, showError.i)
  If path = ""
    ProcedureReturn
  EndIf

  If FileSize(path) < 0
    If showError
      MessageRequester(#APP_NAME, "Path Not found:" + #CRLF$ + path, #PB_MessageRequester_Error)
    EndIf
    ProcedureReturn
  EndIf

  If ShellExecute_(0, "open", path, 0, 0, #SW_SHOWNORMAL) <= 32
    If showError
      MessageRequester(#APP_NAME, "Failed To open:" + #CRLF$ + path, #PB_MessageRequester_Error)
    EndIf
  EndIf
EndProcedure

Procedure OpenConfig(showError.i)
  Protected iniPath.s = AppPath + #INI_FILE

  If FileSize(iniPath) < 0
    WriteDefaultExcludesIni(iniPath)
  EndIf

  If FileSize(iniPath) < 0
    If showError
      MessageRequester(#APP_NAME, "INI file could not be created:" + #CRLF$ + iniPath, #PB_MessageRequester_Error)
    EndIf
    ProcedureReturn
  EndIf

  OpenPath(iniPath, showError)
EndProcedure

Procedure.i ClampSettingInt(*changed.Integer, currentValue.i, newValue.i, minValue.i, maxValue.i)
  Protected v.i = newValue
  If v < minValue : v = minValue : EndIf
  If v > maxValue : v = maxValue : EndIf
  If v <> currentValue
    *changed\i = #True
    ProcedureReturn v
  EndIf
  ProcedureReturn currentValue
EndProcedure

Procedure EditSettings()
  ; PureBasic InputRequester-based settings like HandyDrvLED.
  ; Values are persisted to HandySearch.ini via SaveIniKey().
  Protected changed.Integer
  Protected oldDbPath.s = IndexDbPath
  Protected dbPathChanged.i

  Protected newDebounce.s
  Protected newMax.s
  Protected newThreads.s
  Protected newBatch.s
  Protected newDbPath.s
  Protected newStartMin.s
  Protected newCloseTray.s
  Protected newMinTray.s
  Protected newAutoIndex.s
  Protected newLiveFullPath.s

  ; [Search]
  newMax = InputRequester("Edit Settings", "MaxResults (100..200000) (current: " + Str(SearchMaxResults) + "):", Str(SearchMaxResults))
  If newMax <> ""
    SearchMaxResults = ClampSettingInt(@changed, SearchMaxResults, Val(newMax), 100, 200000)
  EndIf

  newDebounce = InputRequester("Edit Settings", "DebounceMS (0..5000) (current: " + Str(SearchDebounceMS) + "):", Str(SearchDebounceMS))
  If newDebounce <> ""
    SearchDebounceMS = ClampSettingInt(@changed, SearchDebounceMS, Val(newDebounce), 0, 5000)
  EndIf

  ; [Performance]
  newThreads = InputRequester("Edit Settings", "Threads (0=auto, 0..32) (current: " + Str(ConfigThreadCount) + "):", Str(ConfigThreadCount))
  If newThreads <> ""
    ConfigThreadCount = ClampSettingInt(@changed, ConfigThreadCount, Val(newThreads), 0, 32)
  EndIf

  newBatch = InputRequester("Edit Settings", "BatchSize (10..5000) (current: " + Str(ConfigBatchSize) + "):", Str(ConfigBatchSize))
  If newBatch <> ""
    ConfigBatchSize = ClampSettingInt(@changed, ConfigBatchSize, Val(newBatch), 10, 5000)
  EndIf

  ; [Index]
  newDbPath = InputRequester("Edit Settings", "DbPath (current: " + IndexDbPath + "):", IndexDbPath)
  If newDbPath <> ""
    newDbPath = Trim(newDbPath)
    If newDbPath <> "" And newDbPath <> IndexDbPath
      IndexDbPath = newDbPath
      changed\i = #True
    EndIf
  EndIf

  ; [App]
  newStartMin = InputRequester("Edit Settings", "StartMinimized (0/1) (current: " + Str(AppStartMinimized) + "):", Str(AppStartMinimized))
  If newStartMin <> ""
    AppStartMinimized = ClampSettingInt(@changed, AppStartMinimized, Val(newStartMin), 0, 1)
  EndIf

  newCloseTray = InputRequester("Edit Settings", "CloseToTray (0/1) (current: " + Str(AppCloseToTray) + "):", Str(AppCloseToTray))
  If newCloseTray <> ""
    AppCloseToTray = ClampSettingInt(@changed, AppCloseToTray, Val(newCloseTray), 0, 1)
  EndIf

  newMinTray = InputRequester("Edit Settings", "MinimizeToTray (0/1) (current: " + Str(AppMinimizeToTray) + "):", Str(AppMinimizeToTray))
  If newMinTray <> ""
    AppMinimizeToTray = ClampSettingInt(@changed, AppMinimizeToTray, Val(newMinTray), 0, 1)
  EndIf

  newAutoIndex = InputRequester("Edit Settings", "AutoStartIndex (0/1) (current: " + Str(AppAutoStartIndex) + "):", Str(AppAutoStartIndex))
  If newAutoIndex <> ""
    AppAutoStartIndex = ClampSettingInt(@changed, AppAutoStartIndex, Val(newAutoIndex), 0, 1)
  EndIf

  newLiveFullPath = InputRequester("Edit Settings", "LiveMatchFullPath (0/1) (current: " + Str(LiveMatchFullPath) + "):", Str(LiveMatchFullPath))
  If newLiveFullPath <> ""
    LiveMatchFullPath = ClampSettingInt(@changed, LiveMatchFullPath, Val(newLiveFullPath), 0, 1)
  EndIf

  ClampConfigValues()

  If changed\i
    SaveIniKey(AppPath + #INI_FILE, "Search", "MaxResults", Str(SearchMaxResults))
    SaveIniKey(AppPath + #INI_FILE, "Search", "DebounceMS", Str(SearchDebounceMS))
    SaveIniKey(AppPath + #INI_FILE, "Performance", "Threads", Str(ConfigThreadCount))
    SaveIniKey(AppPath + #INI_FILE, "Performance", "BatchSize", Str(ConfigBatchSize))
    SaveIniKey(AppPath + #INI_FILE, "Index", "DbPath", IndexDbPath)
    SaveIniKey(AppPath + #INI_FILE, "App", "StartMinimized", Str(AppStartMinimized))
    SaveIniKey(AppPath + #INI_FILE, "App", "CloseToTray", Str(AppCloseToTray))
    SaveIniKey(AppPath + #INI_FILE, "App", "MinimizeToTray", Str(AppMinimizeToTray))
    SaveIniKey(AppPath + #INI_FILE, "App", "AutoStartIndex", Str(AppAutoStartIndex))
    SaveIniKey(AppPath + #INI_FILE, "App", "LiveMatchFullPath", Str(LiveMatchFullPath))

    If IsMenu(#Menu_Main)
      SetMenuItemState(#Menu_Main, #Menu_View_LiveMatchFullPath, LiveMatchFullPath)
    EndIf

    ; Reload INI so runtime reflects the persisted settings.
    LoadExcludesIni(AppPath + #INI_FILE)

    ; Apply DB path changes immediately when safe.
    dbPathChanged = Bool(LCase(Trim(oldDbPath)) <> LCase(Trim(IndexDbPath)))
    If dbPathChanged
      If IndexingActive = 0
        If IndexDbId : CloseDatabase(IndexDbId) : IndexDbId = 0 : EndIf
        CachedIndexedCount = -1
        CachedIndexedCountAtMS = 0
        InitDatabase()
        IndexTotalFiles = GetIndexedCountFast()
      EndIf
    EndIf

    ; Refresh results with new MaxResults / matching behavior.
    QueryDirty = 1
    QueryNextAtMS = ElapsedMilliseconds()

    If IsMenu(#Menu_Main)
      SetMenuItemState(#Menu_Main, #Menu_View_LiveMatchFullPath, LiveMatchFullPath)
    EndIf

    If dbPathChanged And IndexingActive
      MessageRequester("Settings Saved", "Settings saved. DbPath will apply after stopping indexing.", #PB_MessageRequester_Info)
    Else
      MessageRequester("Settings Saved", "Settings have been saved successfully.", #PB_MessageRequester_Info)
    EndIf
  EndIf
EndProcedure

Procedure OpenContainingFolder(filePath.s, showError.i)
  Protected args.s
 
  If filePath = ""
    ProcedureReturn
  EndIf
 
  args = "/select," + Chr(34) + filePath + Chr(34)
  If RunProgram("explorer.exe", args, "") = 0 And showError
    MessageRequester(#APP_NAME, "Failed To open Explorer For:" + #CRLF$ + filePath, #PB_MessageRequester_Error)
  EndIf
EndProcedure

Procedure OpenDbFolder(showError.i)
  Protected dbPath.s
  Protected folder.s
  Protected args.s
 
  dbPath = ResolveDbPath(IndexDbPath)
  folder = GetPathPart(dbPath)
  If folder = ""
    folder = AppPath
  EndIf
 
  If FileSize(dbPath) >= 0
    args = "/select," + Chr(34) + dbPath + Chr(34)
    If RunProgram("explorer.exe", args, "") = 0 And showError
      MessageRequester(#APP_NAME, "Failed To open Explorer for:" + #CRLF$ + dbPath, #PB_MessageRequester_Error)
    EndIf
  Else
    If RunProgram("explorer.exe", folder, "") = 0 And showError
      MessageRequester(#APP_NAME, "Index DB does not exist yet." + #CRLF$ + 
                                  "Expected path: " + dbPath + #CRLF$ +
                                  "Tried opening folder: " + folder, #PB_MessageRequester_Error)
    EndIf
  EndIf
EndProcedure

Procedure.q GetIndexedCountFromDbSlow()
  Protected sql.s
  Protected cnt.q

  If IndexDbId = 0
    ProcedureReturn 0
  EndIf

  LockMutex(DbMutex)
  sql = "SELECT COUNT(*) FROM files;"
  If DatabaseQuery(IndexDbId, sql)
    If NextDatabaseRow(IndexDbId)
      cnt = GetDatabaseQuad(IndexDbId, 0)
    EndIf
    FinishDatabaseQuery(IndexDbId)
  EndIf
  UnlockMutex(DbMutex)

  ProcedureReturn cnt
EndProcedure

Procedure.q GetIndexedCountFast()
  ; Prefer a maintained meta counter; fall back to COUNT(*) if missing.
  Protected now.q = ElapsedMilliseconds()
  If CachedIndexedCount >= 0 And (now - CachedIndexedCountAtMS) < 5000
    ProcedureReturn CachedIndexedCount
  EndIf

  Protected cnt.q = -1

  If IndexDbId = 0
    ProcedureReturn 0
  EndIf

  LockMutex(DbMutex)
  If DatabaseQuery(IndexDbId, "SELECT value FROM meta WHERE key='indexed_count' LIMIT 1;")
    If NextDatabaseRow(IndexDbId)
      cnt = Val(GetDatabaseString(IndexDbId, 0))
    EndIf
    FinishDatabaseQuery(IndexDbId)
  EndIf
  UnlockMutex(DbMutex)

  If cnt < 0
    cnt = GetIndexedCountFromDbSlow()
    ; Backfill meta so next time is instant.
    If IndexDbId And DbMutex
      LockMutex(DbMutex)
      DatabaseUpdate(IndexDbId, "INSERT OR REPLACE INTO meta(key,value) VALUES('indexed_count','" + Str(cnt) + "');")
      UnlockMutex(DbMutex)
    EndIf
  EndIf

  CachedIndexedCount = cnt
  CachedIndexedCountAtMS = now
  ProcedureReturn cnt
EndProcedure

Procedure ShowDiagnostics()
  Protected msg.s
  Protected dbPath.s
  Protected iniPath.s
  Protected qc.i
  Protected ac.i
  Protected wc.i
  Protected paused.i
  Protected exDirCount.i
  Protected exFileCount.i
  Protected hasWindows.i
 
  dbPath = ResolveDbPath(IndexDbPath)
  iniPath = AppPath + #INI_FILE
 
  exDirCount = MapSize(ExcludeDirNames())
  exFileCount = MapSize(ExcludeFileNames())
  hasWindows = Bool(FindMapElement(ExcludeDirNames(), "windows") <> 0)
 
  If ScanStateMutex
    LockMutex(ScanStateMutex)
    qc = QueueCount
    ac = ActiveDirCount
    UnlockMutex(ScanStateMutex)
  EndIf
  wc = WorkerCount
  paused = IndexingPaused
 
  msg = "INI path: " + iniPath + #CRLF$ +
        "ExcludeDirs: " + Str(exDirCount) + " (has 'windows': " + Str(hasWindows) + ")" + #CRLF$ +
        "ExcludeFiles: " + Str(exFileCount) + #CRLF$ +
        "DB path: " + dbPath + #CRLF$ +
        "DB open: " + Str(Bool(IndexDbId <> 0)) + #CRLF$ +
        "IndexingActive: " + Str(IndexingActive) + #CRLF$ +
        "IndexingPaused: " + Str(paused) + #CRLF$ +
        "WorkerCount: " + Str(wc) + #CRLF$ +
        "QueueCount: " + Str(qc) + #CRLF$ +
        "ActiveDirCount: " + Str(ac) + #CRLF$ +
        "FilesScanned: " + Str(FilesScanned) + #CRLF$ +
        "DirsScanned: " + Str(DirsScanned) + #CRLF$ +
        "IndexTotalFiles: " + Str(IndexTotalFiles)
 
  MessageRequester(#APP_NAME + " Diagnostics", msg, #PB_MessageRequester_Info)
EndProcedure

Procedure.s QueryToLikePattern(query.s)
  Protected p.s = Trim(query)
  If p = ""
    p = "*.*"
  EndIf

  ; If plain text (no wildcards), do contains.
  If FindString(p, "*", 1) = 0 And FindString(p, "?", 1) = 0
    p = "*" + p + "*"
  EndIf

  p = ReplaceString(p, "*", "%")
  p = ReplaceString(p, "?", "_")
  p = ReplaceString(p, "'", "''")
  ProcedureReturn p
EndProcedure

Procedure.s ParseRegexQueryPattern(query.s, *ignoreCase.Integer)
  ; Supported syntaxes:
  ;   re:<pattern>      (case-insensitive)
  ;   recs:<pattern>    (case-sensitive)
  ;   /<pattern>/       (case-sensitive)
  ;   /<pattern>/i      (case-insensitive)
  Protected q.s = Trim(query)
  Protected lower.s = LCase(q)
  Protected lastSlash.i
  Protected pos.i
  Protected flags.s

  If *ignoreCase
    *ignoreCase\i = 1
  EndIf

  If Left(lower, 3) = "re:"
    If *ignoreCase : *ignoreCase\i = 1 : EndIf
    ProcedureReturn Trim(Mid(q, 4))
  EndIf

  If Left(lower, 5) = "recs:"
    If *ignoreCase : *ignoreCase\i = 0 : EndIf
    ProcedureReturn Trim(Mid(q, 6))
  EndIf

  If Left(q, 1) = "/"
    ; Find the last '/' manually (avoid PB-version-specific FindString flags).
    lastSlash = 0
    For pos = Len(q) To 2 Step -1
      If Mid(q, pos, 1) = "/"
        lastSlash = pos
        Break
      EndIf
    Next

    If lastSlash > 1
      flags = Trim(Mid(q, lastSlash + 1))
      If *ignoreCase
        *ignoreCase\i = Bool(FindString(LCase(flags), "i", 1) > 0)
      EndIf
      ProcedureReturn Trim(Mid(q, 2, lastSlash - 2))
    EndIf
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s RegexLiteralHint(pattern.s)
  ; Best-effort: returns the longest run of literal characters in a regex.
  ; Used only to build a SQL LIKE pre-filter.
  Protected i.i, ch.s
  Protected escaped.i
  Protected curr.s = ""
  Protected best.s = ""

  For i = 1 To Len(pattern)
    ch = Mid(pattern, i, 1)

    If escaped
      curr + ch
      escaped = 0
      Continue
    EndIf

    If ch = "\\"
      escaped = 1
      Continue
    EndIf

    Select ch
      Case ".", "^", "$", "*", "+", "?", "(", ")", "[", "]", "{", "}", "|"
        If Len(curr) > Len(best)
          best = curr
        EndIf
        curr = ""

      Default
        curr + ch
    EndSelect
  Next

  If Len(curr) > Len(best)
    best = curr
  EndIf

  best = Trim(best)
  If Len(best) < 3
    ProcedureReturn ""
  EndIf

  ProcedureReturn best
EndProcedure

Procedure RefreshResultsFromDb(query.s)
  Protected likePattern.s
  Protected sql.s
  Protected shown.i
  Protected ignoreCase.i
  Protected regexPattern.s
  Protected regexID.i
  Protected hint.s
  Protected candidateLimit.i
  Protected rowName.s
  Protected rowPath.s

  If IndexDbId = 0
    ProcedureReturn
  EndIf

  ClearGadgetItems(#Gadget_ResultsList)

  ignoreCase = 1
  regexPattern = ParseRegexQueryPattern(query, @ignoreCase)

  ; Regex mode: scan candidate names/paths and post-filter via PB regex.
  If regexPattern <> "" And Trim(regexPattern) <> ""
    If ignoreCase
      regexID = CreateRegularExpression(#PB_Any, regexPattern, #PB_RegularExpression_NoCase)
    Else
      regexID = CreateRegularExpression(#PB_Any, regexPattern)
    EndIf

    If regexID
      hint = RegexLiteralHint(regexPattern)

      candidateLimit = SearchMaxResults * 40
      If candidateLimit < 10000 : candidateLimit = 10000 : EndIf
      If candidateLimit > 200000 : candidateLimit = 200000 : EndIf

      sql = "SELECT name, path FROM files"
      If hint <> ""
        hint = ReplaceString(hint, "'", "''")
        sql + " WHERE name LIKE '%" + hint + "%' COLLATE NOCASE"
      EndIf
      sql + " LIMIT " + Str(candidateLimit) + ";"

      LockMutex(DbMutex)
      If DatabaseQuery(IndexDbId, sql)
        While NextDatabaseRow(IndexDbId)
          rowName = GetDatabaseString(IndexDbId, 0)
          rowPath = GetDatabaseString(IndexDbId, 1)

          If MatchRegularExpression(regexID, rowName)
            AddGadgetItem(#Gadget_ResultsList, -1, rowPath)
            LiveShownPaths(rowPath) = 1
            shown + 1
            If shown >= SearchMaxResults
              Break
            EndIf
          EndIf
        Wend
        FinishDatabaseQuery(IndexDbId)
      EndIf
      UnlockMutex(DbMutex)

      FreeRegularExpression(regexID)

      StatusBarText(#StatusBar_Main, 1, "Showing: " + Str(shown) + "  (regex)  Indexed: " + Str(IndexTotalFiles))
      ProcedureReturn
    EndIf
  EndIf

  ; Default LIKE-based name search.
  likePattern = QueryToLikePattern(query)

  LockMutex(DbMutex)
  sql = "SELECT path FROM files WHERE name LIKE '" + likePattern + "' COLLATE NOCASE LIMIT " + Str(SearchMaxResults) + ";"
  If DatabaseQuery(IndexDbId, sql)
    While NextDatabaseRow(IndexDbId)
      rowPath = GetDatabaseString(IndexDbId, 0)
      AddGadgetItem(#Gadget_ResultsList, -1, rowPath)
      LiveShownPaths(rowPath) = 1
      shown + 1
    Wend
    FinishDatabaseQuery(IndexDbId)
  EndIf
  UnlockMutex(DbMutex)

  StatusBarText(#StatusBar_Main, 1, "Showing: " + Str(shown) + "  Indexed: " + Str(IndexTotalFiles))
EndProcedure

Procedure PumpPendingResults(maxItems.i)
  ; Timer-based UI updates: query debounce + status + live result appends.
  Protected folder.s, files.q, dirs.q
  Protected now.i = ElapsedMilliseconds()
  Protected pulled.i
  Protected path.s
  Protected fileName.s
  Protected query.s
  Protected ignoreCase.i
  Protected regexPattern.s
  Protected trayTip.s

  ; Keep title/menu state updates on the GUI thread.
  If IndexingActive
    SetWindowTitle(#Window_Main, #APP_NAME + " - indexing...")
    trayTip = #APP_NAME + " - indexing"
  Else
    trayTip = #APP_NAME + " - ready"
  EndIf

  If trayTip <> "" And trayTip <> LastTrayTooltip
    SysTrayIconToolTip(#SysTray_Main, trayTip)
    LastTrayTooltip = trayTip
  EndIf

  If QueryDirty And now >= QueryNextAtMS
    QueryDirty = 0
    LastQueryText = GetGadgetText(#Gadget_SearchBar)

    ; Reset matching state on query change (keep queue; re-filter on drain).
    ClearMap(LiveShownPaths())

    If LiveMatcherRegexID
      FreeRegularExpression(LiveMatcherRegexID)
      LiveMatcherRegexID = 0
    EndIf

    query = Trim(LastQueryText)

    ; Determine matcher type for live filtering.
    ignoreCase = 1
    regexPattern = ParseRegexQueryPattern(query, @ignoreCase)
    If regexPattern <> "" And Trim(regexPattern) <> ""
      LiveMatcherMode = 2
      If ignoreCase
        LiveMatcherRegexID = CreateRegularExpression(#PB_Any, regexPattern, #PB_RegularExpression_NoCase)
      Else
        LiveMatcherRegexID = CreateRegularExpression(#PB_Any, regexPattern)
      EndIf
      If LiveMatcherRegexID = 0
        LiveMatcherMode = 0
      EndIf
    Else
      If FindString(query, "*", 1) Or FindString(query, "?", 1)
        LiveMatcherMode = 1
        regexPattern = WildcardToRegex(query)
        LiveMatcherRegexID = CreateRegularExpression(#PB_Any, regexPattern, #PB_RegularExpression_NoCase)
        If LiveMatcherRegexID = 0
          LiveMatcherMode = 0
        EndIf
      Else
        LiveMatcherMode = 0
        LiveMatcherNeedle = LCase(query)
      EndIf
    EndIf

    ; Seed the list from the DB (dedupe map gets populated there),
    ; then continue appending queued results that match.
    RefreshResultsFromDb(LastQueryText)
  EndIf

  ; Drain worker-produced paths and append matches live.
  If ResultMutex
    LockMutex(ResultMutex)
    While pulled < maxItems And FirstElement(PendingResults())
      path = PendingResults()
      DeleteElement(PendingResults())
      pulled + 1

      ; Dedupe UI entries.
      If FindMapElement(LiveShownPaths(), path) = 0
        LiveShownPaths(path) = 1

        If LiveMatchFullPath
          fileName = path
        Else
          fileName = GetFilePart(path)
        EndIf

        Select LiveMatcherMode
          Case 2, 1
            If LiveMatcherRegexID And MatchRegularExpression(LiveMatcherRegexID, fileName)
              AddGadgetItem(#Gadget_ResultsList, -1, path)
            EndIf

          Default
            If LiveMatcherNeedle = "" Or FindString(LCase(fileName), LiveMatcherNeedle, 1)
              AddGadgetItem(#Gadget_ResultsList, -1, path)
            EndIf
        EndSelect
      EndIf
    Wend
    UnlockMutex(ResultMutex)
  EndIf

  If ProgressMutex
    LockMutex(ProgressMutex)
    folder = CurrentFolder
    files = FilesScanned
    dirs = DirsScanned
    UnlockMutex(ProgressMutex)

    If IndexingActive
      StatusBarText(#StatusBar_Main, 0, "Indexing: " + folder)
    Else
      StatusBarText(#StatusBar_Main, 0, "Ready")
    EndIf

    If IndexingActive
      StatusBarText(#StatusBar_Main, 1, "Dirs: " + Str(dirs) + "  Files: " + Str(files) + "  Indexed: " + Str(IndexTotalFiles))
    Else
      ; Idle: keep the search status while also showing the index size.
      If LiveMatcherMode = 2 Or LiveMatcherMode = 1
        StatusBarText(#StatusBar_Main, 1, "Showing: " + Str(CountGadgetItems(#Gadget_ResultsList)) + "  (regex)  Indexed: " + Str(IndexTotalFiles))
      Else
        StatusBarText(#StatusBar_Main, 1, "Showing: " + Str(CountGadgetItems(#Gadget_ResultsList)) + "  Indexed: " + Str(IndexTotalFiles))
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure StopIndexingAndWait()
  ; Main-thread only helper.
  Protected releaseCount.i

  If SearchThread
    StopSearch = 1
    WorkStop = 1
    If IndexPauseEvent : SetEvent_(IndexPauseEvent) : EndIf
    IndexingPaused = 0

    ; Wake any workers blocked on the queue semaphore.
    releaseCount = WorkerCount
    If releaseCount < 1
      releaseCount = 64
    EndIf
    If DirQueueSem
      ReleaseSemaphore_(DirQueueSem, releaseCount, 0)
    EndIf

    WaitThread(SearchThread)
    SearchThread = 0
  EndIf
EndProcedure

Procedure.b RebuildIndexDatabase()
  ; Rebuild is implemented by recreating the SQLite file instead of VACUUM,
  ; which can fail/crash on some setups (WAL/journal/locking edge cases).
  Protected dbPath.s
  Protected ok.i

  If DbMutex = 0
    DbMutex = CreateMutex()
  EndIf

  dbPath = ResolveDbPath(IndexDbPath)
  If dbPath = ""
    MessageRequester(#APP_NAME, "Rebuild failed: DB path is empty.", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  ; Close current DB connection so the file can be recreated.
  If IndexDbId
    LockMutex(DbMutex)
    CloseDatabase(IndexDbId)
    IndexDbId = 0
    UnlockMutex(DbMutex)
  EndIf

  ; Best-effort delete of DB and WAL/SHM sidecars.
  If FileSize(dbPath) >= 0
    DeleteFile(dbPath)
  EndIf
  If FileSize(dbPath + "-wal") >= 0
    DeleteFile(dbPath + "-wal")
  EndIf
  If FileSize(dbPath + "-shm") >= 0
    DeleteFile(dbPath + "-shm")
  EndIf

  InitDatabase()
  ok = Bool(IndexDbId <> 0)
  If ok = 0
    MessageRequester(#APP_NAME, "Rebuild failed: could not open index database:" + #CRLF$ + dbPath + #CRLF$ + DatabaseError(), #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  ; Ensure a clean slate even if file deletion fails.
  LockMutex(DbMutex)
  DatabaseUpdate(IndexDbId, "DELETE FROM files;")
  UnlockMutex(DbMutex)

  ; Ensure meta starts at 0 for instant count.
  LockMutex(DbMutex)
  DatabaseUpdate(IndexDbId, "INSERT OR REPLACE INTO meta(key,value) VALUES('indexed_count','0');")
  UnlockMutex(DbMutex)

  IndexTotalFiles = 0
  CachedIndexedCount = 0
  CachedIndexedCountAtMS = ElapsedMilliseconds()
  ProcedureReturn #True
EndProcedure

Procedure StartIndexing(rebuild.i)
  Protected *params.SearchParams

  ; If already indexing and this is just "start/resume", do nothing.
  If rebuild = 0 And IndexingActive
    ProcedureReturn
  EndIf
 
  StopIndexingAndWait()

  If rebuild
    If RebuildIndexDatabase() = #False
      ; Don't start indexing if the DB couldn't be recreated.
      IndexingActive = 0
      UpdateControlStates()
      ProcedureReturn
    EndIf

    ; Force a UI refresh (DB is now empty).
    QueryDirty = 1
    QueryNextAtMS = ElapsedMilliseconds()
  EndIf
 
  StopSearch = 0
  WorkStop = 0
 
  *params = AllocateStructure(SearchParams)
  If *params = 0
    ProcedureReturn
  EndIf
 
  IndexingActive = 1
  UpdateControlStates()
 
  SearchThread = CreateThread(@SearchThreadProc(), *params)
  If SearchThread = 0
    IndexingActive = 0
    UpdateControlStates()
    MessageRequester(#APP_NAME, "Failed to create index thread." + #CRLF$ + 
                                "This EXE must be compiled with threading enabled.", #PB_MessageRequester_Error)
    FreeStructure(*params)
  EndIf
EndProcedure

; === Event Loop ===
Procedure ToggleMainWindow()
  If IsWindowVisible_(WindowID(#Window_Main))
    HideWindow(#Window_Main, 1)
  Else
    HideWindow(#Window_Main, 0)
    SetWindowState(#Window_Main, #PB_Window_Normal)
    SetActiveWindow(#Window_Main)
  EndIf
EndProcedure

Procedure MainLoop()
  Protected event.i
  Protected quit.b
 
  Repeat
    event = WaitWindowEvent()
    Select event
      Case #PB_Event_CloseWindow
        ; Close (X) behavior is configurable: hide-to-tray or exit.
        If AppCloseToTray
          HideWindow(#Window_Main, 1)
        Else
          If ConfirmExit()
            quit = #True
          EndIf
        EndIf

      Case #PB_Event_MinimizeWindow
        ; Minimize-to-tray: hide the window so it disappears from the taskbar.
        If AppMinimizeToTray
          HideWindow(#Window_Main, 1)
        EndIf
 
      Case #PB_Event_SysTray
        Select EventType()
          Case #PB_EventType_LeftClick
            ToggleMainWindow()
          Case #PB_EventType_RightClick
            DisplayPopupMenu(#Menu_TrayPopup, WindowID(#Window_Main))
        EndSelect

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #Gadget_SearchBar
            If EventType() = #PB_EventType_Change
              QueryDirty = 1
              QueryNextAtMS = ElapsedMilliseconds() + SearchDebounceMS
            EndIf

          Case #Gadget_ResultsList
            Select EventType()
              Case #PB_EventType_LeftDoubleClick
                OpenPath(SelectedResultPath(), #Open_Silent)
 
              Case #PB_EventType_RightClick
                DisplayPopupMenu(#Menu_ResultsPopup, WindowID(#Window_Main))
            EndSelect
        EndSelect
 
      Case #PB_Event_Menu
        Select EventMenu()
          Case #Menu_StartSearchShortcut
            If GetActiveGadget() = #Gadget_SearchBar
              QueryDirty = 1
              QueryNextAtMS = ElapsedMilliseconds() + SearchDebounceMS
            EndIf

          Case #Menu_OpenFile
            OpenPath(SelectedResultPath(), #Open_ShowError)
 
          Case #Menu_OpenFolder
            OpenContainingFolder(SelectedResultPath(), #Open_ShowError)

          Case #Menu_Index_StartResume
            StartIndexing(#False)

          Case #Menu_Index_Rebuild
            StartIndexing(#True)

          Case #Menu_Index_PauseResume
            If IndexingActive
              If IndexingPaused
                IndexingPaused = 0
                If IndexPauseEvent : SetEvent_(IndexPauseEvent) : EndIf
              Else
                IndexingPaused = 1
                If IndexPauseEvent : ResetEvent_(IndexPauseEvent) : EndIf
              EndIf
            EndIf

          Case #Menu_Index_Stop
            StopSearch = 1
            WorkStop = 1
            If IndexPauseEvent : SetEvent_(IndexPauseEvent) : EndIf
            IndexingPaused = 0
            If DirQueueSem And WorkerCount > 0
              ReleaseSemaphore_(DirQueueSem, WorkerCount, 0)
            EndIf

          Case #Menu_View_Compact
            SetCompactMode(1 - Bool(AppCompactMode))

           Case #Menu_View_LiveMatchFullPath
             LiveMatchFullPath = 1 - Bool(LiveMatchFullPath)
             If IsMenu(#Menu_Main)
               SetMenuItemState(#Menu_Main, #Menu_View_LiveMatchFullPath, LiveMatchFullPath)
             EndIf
             SaveIniKey(AppPath + #INI_FILE, "App", "LiveMatchFullPath", Str(LiveMatchFullPath))
             ; Force refresh so the list updates under the new mode.
             QueryDirty = 1
             QueryNextAtMS = ElapsedMilliseconds()

           Case #Menu_App_RunAtStartup, #Menu_Tray_RunAtStartup
              AppRunAtStartup = 1 - Bool(AppRunAtStartup)
              If AppRunAtStartup
                AddToStartup()
              Else
                RemoveFromStartup()
              EndIf
              SaveIniKey(AppPath + #INI_FILE, "App", "RunAtStartup", Str(AppRunAtStartup))
              UpdateStartupMenuState()

            Case #Menu_Tray_Settings
              EditSettings()

          Case #Menu_Tools_Settings
            EditSettings()

          Case #Menu_Tools_OpenIni
            OpenConfig(#Open_ShowError)

          Case #Menu_Tools_Web
            WebSearch(#Open_ShowError)

          Case #Menu_Help_About
            MessageRequester("About", #APP_NAME + " - " + version + #CRLF$ +
                                      "For searching your files and/or the web" + #CRLF$ +
                                      "----------------------------------------" + #CRLF$ +
                                      "Contact: zonemaster60@gmail.com" + #CRLF$ +
                                      "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)

          Case #Menu_File_Exit
            If ConfirmExit()
              quit = #True
            EndIf

          Case #Menu_Tray_ShowHide
            ToggleMainWindow()

          Case #Menu_Tray_RebuildIndex
            StartIndexing(#True)

          Case #Menu_Tray_OpenDbFolder
            OpenDbFolder(#Open_ShowError)

          Case #Menu_Tray_ShowIndexedCount
             MessageRequester(#APP_NAME, "Indexed files: " + Str(GetIndexedCountFast()), #PB_MessageRequester_Info)

          Case #Menu_Tray_ShowDbPath
            MessageRequester(#APP_NAME, "DB path: " + ResolveDbPath(IndexDbPath), #PB_MessageRequester_Info)

          Case #Menu_Tray_Diagnostics
            ShowDiagnostics()

          Case #Menu_Tray_PauseResume
            If IndexingActive
              If IndexingPaused
                IndexingPaused = 0
                If IndexPauseEvent : SetEvent_(IndexPauseEvent) : EndIf
              Else
                IndexingPaused = 1
                If IndexPauseEvent : ResetEvent_(IndexPauseEvent) : EndIf
              EndIf
            EndIf
 
          Case #Menu_Tray_Exit
            If ConfirmExit()
              quit = #True
            EndIf

        EndSelect
 
      Case #PB_Event_SizeWindow
        ResizeMainWindow()

      Case #PB_Event_Timer
        If EventTimer() = #Timer_PumpResults
          PumpPendingResults(200)
          UpdateControlStates()
          If IndexingActive = 0 And IsWindowVisible_(WindowID(#Window_Main))
            SetWindowTitle(#Window_Main, #APP_NAME + " - " + version + " Desktop")
          EndIf
        EndIf
 
    EndSelect
  Until quit
 
  StopIndexingAndWait()
EndProcedure

Procedure.s ResolveDbPath(dbPath.s)
  Protected p.s = Trim(dbPath)
  Protected appData.s
  Protected candidate.s
  Protected f.i
 
  If p = ""
    p = "HandySearch.db"
  EndIf
 
  ; If path has no drive/UNC, treat as relative to app.
  If FindString(p, ":\", 1) = 0 And Left(p, 2) <> "\"
    p = AppPath + p
  EndIf
 
  ; If DB doesn't exist and EXE folder isn't writable, fall back to AppData.
  If FileSize(p) < 0
    f = CreateFile(#PB_Any, p)
    If f
      CloseFile(f)
      DeleteFile(p)
    Else
      appData = GetEnvironmentVariable("APPDATA")
      If appData <> "" And Right(appData, 1) <> "\"
        appData + "\"
      EndIf
      candidate = appData + #APP_NAME + "\HandySearch.db"
      p = candidate
    EndIf
  EndIf
 
  ProcedureReturn p
EndProcedure

Procedure InitDatabase()
  Protected dbPath.s
  Protected folder.s
 
  dbPath = ResolveDbPath(IndexDbPath)
  folder = GetPathPart(dbPath)
  If folder <> "" And FileSize(folder) <> -2
    CreateDirectory(folder)
  EndIf
 
  If UseSQLiteDatabase() = 0
    MessageRequester(#APP_NAME, "SQLite database support is not available.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
 
  ; Open existing DB, or create a new one if missing.
  IndexDbId = OpenDatabase(#PB_Any, dbPath, "", "", #PB_Database_SQLite)
  If IndexDbId = 0 And FileSize(dbPath) < 0
    ; SQLite will initialize an empty file, but ensure the path is writable.
    Protected f.i
    f = CreateFile(#PB_Any, dbPath)
    If f
      CloseFile(f)
      IndexDbId = OpenDatabase(#PB_Any, dbPath, "", "", #PB_Database_SQLite)
    EndIf
  EndIf
  If IndexDbId = 0
    MessageRequester(#APP_NAME, "Failed to open index database: " + dbPath + #CRLF$ +
                                " " + DatabaseError(), #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
 
  LockMutex(DbMutex)
  DatabaseUpdate(IndexDbId, "PRAGMA journal_mode=WAL;")
  DatabaseUpdate(IndexDbId, "PRAGMA synchronous=NORMAL;")
  DatabaseUpdate(IndexDbId, "PRAGMA temp_store=MEMORY;")
  DatabaseUpdate(IndexDbId, "PRAGMA mmap_size=268435456;")
  DatabaseUpdate(IndexDbId, "PRAGMA cache_size=-200000;")
  DatabaseUpdate(IndexDbId, "CREATE TABLE IF NOT EXISTS files(path TEXT PRIMARY KEY, name TEXT, dir TEXT, size INTEGER, mtime INTEGER);")
  DatabaseUpdate(IndexDbId, "CREATE INDEX IF NOT EXISTS idx_files_name ON files(name);")
  DatabaseUpdate(IndexDbId, "CREATE INDEX IF NOT EXISTS idx_files_dir ON files(dir);")
  DatabaseUpdate(IndexDbId, "CREATE TABLE IF NOT EXISTS meta(key TEXT PRIMARY KEY, value TEXT);")
  UnlockMutex(DbMutex)
EndProcedure

; === Main ===

If gInstallStartupTaskMode
  AddToStartup()
  End
EndIf

If gRemoveStartupTaskMode
  ; Uses elevation relaunch internally if needed.
  RemoveFromStartup()
  End
EndIf

; Best-effort cleanup of any old registry startup entry.
RemoveLegacyStartupRegistryEntry()

ResultMutex = CreateMutex()
ProgressMutex = CreateMutex()
DbMutex = CreateMutex()
LoadExcludesIni(AppPath + #INI_FILE)

; Ensure menu checkmarks reflect INI state.
; Must run after InitGUI() creates the menu.

; Ensure INI state reflects actual Task Scheduler state.
AppRunAtStartup = IsInStartup()
SaveIniKey(AppPath + #INI_FILE, "App", "RunAtStartup", Str(AppRunAtStartup))

InitDatabase()

; Initialize cached count from DB meta (fast path).
CachedIndexedCount = -1
CachedIndexedCountAtMS = 0
IndexTotalFiles = GetIndexedCountFast()

InitGUI()

; Apply initial menu states now that the menu exists.
If IsMenu(#Menu_Main)
  SetMenuItemState(#Menu_Main, #Menu_View_Compact, AppCompactMode)
  SetMenuItemState(#Menu_Main, #Menu_View_LiveMatchFullPath, LiveMatchFullPath)
EndIf

UpdateStartupMenuState()

; Start query right away.
QueryDirty = 1
QueryNextAtMS = 0

; Optionally start indexing on launch.
If AppAutoStartIndex
  StartIndexing(#False)
EndIf

If AppStartMinimized
  HideWindow(#Window_Main, 1)
EndIf

MainLoop()

If LiveMatcherRegexID : FreeRegularExpression(LiveMatcherRegexID) : LiveMatcherRegexID = 0 : EndIf
If IndexDbId : CloseDatabase(IndexDbId) : EndIf
If ResultMutex : FreeMutex(ResultMutex) : EndIf
If ProgressMutex : FreeMutex(ProgressMutex) : EndIf
If DbMutex : FreeMutex(DbMutex) : EndIf
If ScanStateMutex : FreeMutex(ScanStateMutex) : EndIf
If DirQueueSem : CloseHandle_(DirQueueSem) : EndIf
If IndexPauseEvent : CloseHandle_(IndexPauseEvent) : EndIf
If TrayIconHandle : DestroyIcon_(TrayIconHandle) : TrayIconHandle = 0 : EndIf
If hMutex : CloseHandle_(hMutex) : EndIf

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 6
; Folding = ------------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandySearch.ico
; Executable = ..\HandySearch.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,7
; VersionField1 = 1,0,0,7
; VersionField2 = ZoneSoft
; VersionField3 = HandySearch
; VersionField4 = 1.0.0.7
; VersionField5 = 1.0.0.7
; VersionField6 = Everything-like search tool for desktop and web
; VersionField7 = HandySearch
; VersionField8 = HandySearch.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60