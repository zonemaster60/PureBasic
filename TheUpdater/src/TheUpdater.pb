; UpdateHubLike - PureBasic 6.30 beta
; Windows 11 x64
;
; Phase 1:
; - Self-elevate (UAC)
; - Single instance (mutex)
; - Check winget presence with a nice dialog
; - Show installed packages and upgrades via winget JSON

EnableExplicit

#APP_NAME = "TheUpdater"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.1"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseHandle_(hMutex)
    End
  EndIf
EndProcedure

Procedure ShowAbout()
  Protected msg.s
  msg = #APP_NAME + " - " + version + #CRLF$ +
        "For updating your installed programs." + #CRLF$ +
        "---------------------------------------" + #CRLF$ +
        "Contact: " + #EMAIL_NAME + #CRLF$ +
        "Website: https://github.com/zonemaster60"

  MessageRequester("About " + #APP_NAME, msg, #PB_MessageRequester_Info)
EndProcedure

; -------------------- Constants / Globals --------------------

Global MainWindowTitle$ = #APP_NAME
Global MutexName$ = "Local\TheUpdater_Mutex_3D6F7A1E"
Global SettingsPath$ = #APP_NAME + "TheUpdater_settings.ini"
Global ErrorLogPath$ = #APP_NAME + "TheUpdater_errors.log"

Enumeration WindowIds
  #WinMain
EndEnumeration

Enumeration GadgetIds
  #G_List
  #G_BtnLoadInstalled
  #G_BtnCheckUpgrades
  #G_BtnUpgradeSelected
  #G_BtnOpenHomepage
  #G_BtnScanPortable
  #G_BtnMatchPortable
  #G_BtnPortableSettings
  #G_ChkIncludeSystem
  #G_ChkIncludeWindowsApps
  #G_BtnViewLog
  #G_BtnAbout
  #G_Status
EndEnumeration

Enumeration WingetDialogResult
  #WingetDlg_Install = 1
  #WingetDlg_Retry
  #WingetDlg_Limited
  #WingetDlg_Exit
EndEnumeration

Enumeration WingetDialogGadgets
  #WingetDlg_Text
  #WingetDlg_CheckNoAsk
  #WingetDlg_BtnInstall
  #WingetDlg_BtnRetry
  #WingetDlg_BtnLimited
  #WingetDlg_BtnExit
EndEnumeration

Structure SoftwareItem
  id.s
  name.s
  installedVersion.s
  availableVersion.s
  source.s
  homepage.s
  installPath.s ; for portable apps
EndStructure

Global NewList Items.SoftwareItem()
Global WingetEnabled.b
Global NewList PortableRoots.s()
Global NewMap PortableMap.s() ; key=exe full path (lower), value=wingetId
Global NewMap PortableSeenExePaths.b() ; per-scan set
Global PortableScanExeTotal.i
Global PortableScanAdded.i

Global IncludeSystemComponents.b
Global IncludeWindowsApps.b

; Forward declarations (PureBasic requires this when used earlier)
Declare RefreshListGadget()
Declare.b ParseWingetListTable(text$)
Declare.b ParseWingetUpgradeTable(text$)
Declare.s CollapseMultiSpaceToTabs(line$)
Declare LoadIncludeOptions()
Declare SaveIncludeOptions()
Declare LogError(context$, details$ = "")
Declare LogInfo(context$, details$ = "")
Declare OpenErrorLog()
Declare.s NormalizeFolderPath(path$)
Declare.s JoinPath(base$, part$)

; -------------------- WinAPI imports --------------------

Import "kernel32.lib"
  CreateMutex_(lpMutexAttributes.i, bInitialOwner.i, lpName.p-unicode) As "CreateMutexW"
  OpenMutex_(dwDesiredAccess.i, bInheritHandle.i, lpName.p-unicode) As "OpenMutexW"
  CloseHandle_(hObject.i) As "CloseHandle"
  GetLastError_() As "GetLastError"
EndImport

Import "shell32.lib"
  ShellExecute_(hwnd.i, lpOperation.p-unicode, lpFile.p-unicode, lpParameters.p-unicode, lpDirectory.p-unicode, nShowCmd.i) As "ShellExecuteW"
  IsUserAnAdmin_() As "IsUserAnAdmin"
EndImport

Import "user32.lib"
  FindWindow_(lpClassName.p-unicode, lpWindowName.p-unicode) As "FindWindowW"
  ShowWindow_(hWnd.i, nCmdShowCmd.i) As "ShowWindow"
  SetForegroundWindow_(hWnd.i) As "SetForegroundWindow"
EndImport

Import "advapi32.lib"
  RegOpenKeyEx_(hKey.i, lpSubKey.p-unicode, ulOptions.l, samDesired.l, *phkResult) As "RegOpenKeyExW"
  RegCloseKey_(hKey.i) As "RegCloseKey"
  RegEnumKeyEx_(hKey.i, dwIndex.l, lpName.i, *lpcchName, lpReserved.i, lpClass.i, *lpcchClass, lpftLastWriteTime.i) As "RegEnumKeyExW"
  RegQueryValueEx_(hKey.i, lpValueName.p-unicode, lpReserved.i, *lpType, lpData.i, *lpcbData) As "RegQueryValueExW"
EndImport

Import "version.lib"
  GetFileVersionInfoSize_(lptstrFilename.p-unicode, lpdwHandle.i) As "GetFileVersionInfoSizeW"
  GetFileVersionInfo_(lptstrFilename.p-unicode, dwHandle.i, dwLen.i, lpData.i) As "GetFileVersionInfoW"
  VerQueryValue_(pBlock.i, lpSubBlock.p-unicode, *lplpBuffer, *puLen) As "VerQueryValueW"
EndImport

#KEY_READ = $20019
#HKEY_LOCAL_MACHINE = $80000002
#HKEY_CURRENT_USER  = $80000001
#ERROR_NO_MORE_ITEMS = 259
#REG_SZ = 1
#REG_EXPAND_SZ = 2
#REG_DWORD = 4

#ERROR_ALREADY_EXISTS = 183
#MUTEX_ACCESS = $00100000 ; SYNCHRONIZE
#SW_SHOWNORMAL = 1

; -------------------- Utilities --------------------

Procedure EnsureSettingsDir()
  Protected dir$ = GetPathPart(SettingsPath$)
  If FileSize(dir$) <> -2
    CreateDirectory(dir$)
  EndIf
EndProcedure

Procedure.s TimestampIsoLocal()
  Protected q.q = Date()
  ProcedureReturn FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", q)
EndProcedure

Procedure AppendLogLine(filePath$, line$)
  EnsureSettingsDir()

  Protected f
  If FileSize(filePath$) >= 0
    f = OpenFile(#PB_Any, filePath$)
    If f
      FileSeek(f, Lof(f))
    EndIf
  Else
    f = CreateFile(#PB_Any, filePath$)
  EndIf

  If f
    WriteStringN(f, line$)
    CloseFile(f)
  EndIf
EndProcedure

Procedure LogError(context$, details$ = "")
  Protected line$ = TimestampIsoLocal() + " [ERROR] " + context$
  If details$ <> ""
    line$ + " | " + details$
  EndIf
  AppendLogLine(ErrorLogPath$, line$)
EndProcedure

Procedure LogInfo(context$, details$ = "")
  Protected line$ = TimestampIsoLocal() + " [INFO ] " + context$
  If details$ <> ""
    line$ + " | " + details$
  EndIf
  AppendLogLine(ErrorLogPath$, line$)
EndProcedure

Procedure OpenErrorLog()
  EnsureSettingsDir()

  If FileSize(ErrorLogPath$) < 0
    Protected f = CreateFile(#PB_Any, ErrorLogPath$)
    If f
      CloseFile(f)
    EndIf
  EndIf

  RunProgram("notepad.exe", Chr(34) + ErrorLogPath$ + Chr(34), "", #PB_Program_Open)
EndProcedure

Procedure.b OpenSettings(createIfMissing.b)
  EnsureSettingsDir()

  If OpenPreferences(SettingsPath$)
    ProcedureReturn #True
  EndIf

  If createIfMissing
    ; On a fresh install, settings.ini may not exist yet.
    ; Create it so subsequent reads/writes work.
    If CreatePreferences(SettingsPath$)
      ClosePreferences()
      If OpenPreferences(SettingsPath$)
        ProcedureReturn #True
      EndIf
    EndIf
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.b ReadSuppressWingetPrompt()
  If OpenSettings(#False)
    PreferenceGroup("Startup")
    Protected v = ReadPreferenceLong("SuppressWingetPrompt", 0)
    ClosePreferences()
    ProcedureReturn Bool(v <> 0)
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure WriteSuppressWingetPrompt(value.b)
  If OpenSettings(#True)
    PreferenceGroup("Startup")
    WritePreferenceLong("SuppressWingetPrompt", Bool(value))
    ClosePreferences()
  Else
    LogError("Failed to open settings for write", SettingsPath$)
  EndIf
EndProcedure

Procedure LoadIncludeOptions()
  ; Default: don't include system components; include Windows apps.
  IncludeSystemComponents = #False
  IncludeWindowsApps = #True

  If OpenSettings(#False)
    PreferenceGroup("Inventory")
    IncludeSystemComponents = Bool(ReadPreferenceLong("IncludeSystemComponents", 0) <> 0)
    IncludeWindowsApps = Bool(ReadPreferenceLong("IncludeWindowsApps", 1) <> 0)
    ClosePreferences()
  EndIf
EndProcedure

Procedure SaveIncludeOptions()
  If OpenSettings(#True)
    PreferenceGroup("Inventory")
    WritePreferenceLong("IncludeSystemComponents", Bool(IncludeSystemComponents))
    WritePreferenceLong("IncludeWindowsApps", Bool(IncludeWindowsApps))
    ClosePreferences()
  Else
    LogError("Failed to open settings for write", SettingsPath$)
  EndIf
EndProcedure

Procedure LoadPortableRoots()
  ClearList(PortableRoots())

  If OpenSettings(#False)
    PreferenceGroup("PortableScan")
    Protected count = ReadPreferenceLong("RootCount", 0)
    Protected i

    For i = 0 To count - 1
      Protected root$ = ReadPreferenceString("Root" + Str(i), "")
       If root$ <> "" 
         root$ = NormalizeFolderPath(root$)
         If root$ <> "" And FileSize(root$) = -2
           AddElement(PortableRoots())
           PortableRoots() = root$
         EndIf
       EndIf

    Next

    ClosePreferences()
  EndIf
EndProcedure

Procedure SavePortableRoots()
  If OpenSettings(#True)
    PreferenceGroup("PortableScan")

    ; wipe old entries by rewriting count and keys
    Protected count = ListSize(PortableRoots())
    WritePreferenceLong("RootCount", count)

    Protected i = 0
    ForEach PortableRoots()
      WritePreferenceString("Root" + Str(i), PortableRoots())
      i + 1
    Next

    ; clear stale entries if the list shrank
    WritePreferenceString("Root" + Str(i), "")

    ClosePreferences()
  Else
    LogError("Failed to open settings for write", SettingsPath$)
  EndIf
EndProcedure

Procedure LoadPortableMap()
  ClearMap(PortableMap())

  If OpenSettings(#False)
    PreferenceGroup("PortableMap")
    ExaminePreferenceKeys()
    While NextPreferenceKey()
      Protected exeKey$ = PreferenceKeyName()
      Protected wingetId$ = ReadPreferenceString(exeKey$, "")
      If exeKey$ <> "" And wingetId$ <> ""
        PortableMap(LCase(exeKey$)) = wingetId$
      EndIf
    Wend
    ClosePreferences()
  EndIf
EndProcedure

Procedure SavePortableMap()
  If OpenSettings(#True)
    PreferenceGroup("PortableMap")

    ; easiest way: rewrite each mapping key
    ; Note: PureBasic Preferences API doesn't have an explicit clear-group call.
    ; This will update/append keys; stale keys can remain if removed.
    ; For now, we keep it simple and only ever add/update mappings.
    ForEach PortableMap()
      WritePreferenceString(MapKey(PortableMap()), PortableMap())
    Next

    ClosePreferences()
  Else
    LogError("Failed to open settings for write", SettingsPath$)
  EndIf
EndProcedure

Procedure.s NormalizePathKey(path$)
  ProcedureReturn LCase(path$)
EndProcedure

Procedure.s NormalizeFolderPath(path$)
  path$ = Trim(path$)

  ; normalize slashes
  path$ = ReplaceString(path$, "/", "\\")

  ; strip trailing backslashes (but keep root like C:\)
  While Len(path$) > 3 And Right(path$, 1) = "\\"
    path$ = Left(path$, Len(path$) - 1)
  Wend

  ProcedureReturn path$
EndProcedure

Procedure.s JoinPath(base$, part$)
  base$ = NormalizeFolderPath(base$)
  If base$ = ""
    ProcedureReturn part$
  EndIf

  If Right(base$, 1) = "\\"
    ProcedureReturn base$ + part$
  EndIf

  ProcedureReturn base$ + "\\" + part$
EndProcedure

Procedure.s GetPortableMappedWingetId(exePath$)
  Protected key$ = NormalizePathKey(exePath$)
  If FindMapElement(PortableMap(), key$)
    ProcedureReturn PortableMap()
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure SetPortableMappedWingetId(exePath$, wingetId$)
  If exePath$ = "" Or wingetId$ = ""
    ProcedureReturn
  EndIf

  PortableMap(NormalizePathKey(exePath$)) = wingetId$
  SavePortableMap()
EndProcedure

Procedure.s QueryVersionString(*viMem, langId, codePage, name$)
  Protected *buf, len
  Protected subBlock$ = "\\StringFileInfo\\" + RSet(Hex(langId), 4, "0") + RSet(Hex(codePage), 4, "0") + "\\" + name$

  If VerQueryValue_(*viMem, subBlock$, @*buf, @len)
    If *buf And len > 0
      ProcedureReturn PeekS(*buf, len - 1, #PB_Unicode)
    EndIf
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s GetExeFileVersion(exePath$)
  Protected handle, size = GetFileVersionInfoSize_(exePath$, @handle)
  If size <= 0
    ProcedureReturn ""
  EndIf

  Protected *mem = AllocateMemory(size)
  If *mem = 0
    ProcedureReturn ""
  EndIf

  If GetFileVersionInfo_(exePath$, 0, size, *mem) = 0
    FreeMemory(*mem)
    ProcedureReturn ""
  EndIf

  Protected *ffi.VS_FIXEDFILEINFO, ffiLen
  If VerQueryValue_(*mem, "\\", @*ffi, @ffiLen) = 0 Or *ffi = 0
    FreeMemory(*mem)
    ProcedureReturn ""
  EndIf

  Protected major = (*ffi\dwFileVersionMS >> 16) & $FFFF
  Protected minor = (*ffi\dwFileVersionMS) & $FFFF
  Protected build = (*ffi\dwFileVersionLS >> 16) & $FFFF
  Protected revision = (*ffi\dwFileVersionLS) & $FFFF

  FreeMemory(*mem)
  ProcedureReturn Str(major) + "." + Str(minor) + "." + Str(build) + "." + Str(revision)
EndProcedure

Procedure.s GetExeProductName(exePath$)
  Protected handle, size = GetFileVersionInfoSize_(exePath$, @handle)
  If size <= 0
    ProcedureReturn ""
  EndIf

  Protected *mem = AllocateMemory(size)
  If *mem = 0
    ProcedureReturn ""
  EndIf

  If GetFileVersionInfo_(exePath$, 0, size, *mem) = 0
    FreeMemory(*mem)
    ProcedureReturn ""
  EndIf

  ; Get first translation
  Protected *trans, transLen
  Protected langId, codePage

  If VerQueryValue_(*mem, "\\VarFileInfo\\Translation", @*trans, @transLen) And *trans And transLen >= 4
    langId = PeekW(*trans)
    codePage = PeekW(*trans + 2)
  Else
    langId = $0409
    codePage = $04B0
  EndIf

  Protected product$ = QueryVersionString(*mem, langId, codePage, "ProductName")
  If product$ = ""
    product$ = QueryVersionString(*mem, langId, codePage, "FileDescription")
  EndIf

  FreeMemory(*mem)
  ProcedureReturn product$
EndProcedure

Procedure.b IsLikelyPortableExe(exePath$)
  ; Basic filters to reduce noise.
  Protected name$ = LCase(GetFilePart(exePath$))

  If name$ = "unins000.exe" Or name$ = "uninstall.exe" Or name$ = "setup.exe" Or name$ = "update.exe"
    ProcedureReturn #False
  EndIf

  If FindString(name$, "installer", 1)
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure AddPortableItem(exePath$)
  Protected pathKey$ = NormalizePathKey(exePath$)
  If FindMapElement(PortableSeenExePaths(), pathKey$)
    ProcedureReturn
  EndIf
  PortableSeenExePaths(pathKey$) = #True
 
  ; count added item
  PortableScanAdded + 1
 
  Protected product$ = GetExeProductName(exePath$)

  If product$ = ""
    product$ = GetFilePart(exePath$)
  EndIf

  Protected version$ = GetExeFileVersion(exePath$)
  Protected mappedId$ = GetPortableMappedWingetId(exePath$)

  AddElement(Items())
  Items()\id = mappedId$
  Items()\name = product$
  Items()\installedVersion = version$
  Items()\availableVersion = ""
  Items()\source = "Portable"
  Items()\installPath = exePath$
EndProcedure

Procedure ScanPortableRoot(root$)
  root$ = NormalizeFolderPath(root$)
  Protected dir = ExamineDirectory(#PB_Any, root$, "*.*")
  If dir = 0
    ProcedureReturn
  EndIf

  While NextDirectoryEntry(dir)
    Protected entryName$ = DirectoryEntryName(dir)
    Protected full$ = JoinPath(root$, entryName$)

    If DirectoryEntryType(dir) = #PB_DirectoryEntry_Directory
      If entryName$ <> "." And entryName$ <> ".."
        ScanPortableRoot(full$)
      EndIf

    Else
      If LCase(GetExtensionPart(entryName$)) = "exe"
        PortableScanExeTotal + 1
        If IsLikelyPortableExe(full$)
          AddPortableItem(full$)
        EndIf
      EndIf
    EndIf
  Wend

  FinishDirectory(dir)
EndProcedure

Procedure ScanPortableFolders()
  IncludeSystemComponents = Bool(GetGadgetState(#G_ChkIncludeSystem) <> 0)
  IncludeWindowsApps = Bool(GetGadgetState(#G_ChkIncludeWindowsApps) <> 0)
  SaveIncludeOptions()

  LoadPortableRoots()
  LoadPortableMap()
  ClearMap(PortableSeenExePaths())

  PortableScanExeTotal = 0
  PortableScanAdded = 0

  If ListSize(PortableRoots()) = 0
    MessageRequester("Portable scan", "No portable folders configured. Click 'Folders' to add some.", #PB_MessageRequester_Ok)
    ProcedureReturn
  EndIf

  SetGadgetText(#G_Status, "Scanning portable folders...")

  Protected beforeCount = ListSize(Items())

  ForEach PortableRoots()
    ScanPortableRoot(PortableRoots())
  Next

  RefreshListGadget()

  Protected afterCount = ListSize(Items())
  LogInfo("Portable scan complete", "roots=" + Str(ListSize(PortableRoots())) + " exeSeen=" + Str(PortableScanExeTotal) + " added=" + Str(PortableScanAdded) + " itemsBefore=" + Str(beforeCount) + " itemsAfter=" + Str(afterCount))

  SetGadgetText(#G_Status, "Portable scan done (exe: " + Str(PortableScanExeTotal) + ", added: " + Str(PortableScanAdded) + ")")
EndProcedure

Procedure.s UrlEncodeQuery(text$)
  ; Simple URL encoder for query strings.
  ; Encodes non-alnum as %HH, spaces as +.

  Protected out$, i, ch, hex$
  For i = 1 To Len(text$)
    ch = Asc(Mid(text$, i, 1))

    Select ch
      Case 'a' To 'z', 'A' To 'Z', '0' To '9'
        out$ + Chr(ch)

      Case ' '
        out$ + "+"

      Case '-', '_', '.', '~'
        out$ + Chr(ch)

      Default
        hex$ = RSet(Hex(ch), 2, "0")
        out$ + "%" + hex$
    EndSelect
  Next

  ProcedureReturn out$
EndProcedure

Procedure OpenUrl(url$)
  If url$ <> ""
    RunProgram("cmd.exe", "/c start " + Chr(34) + Chr(34) + " " + Chr(34) + url$ + Chr(34), "", #PB_Program_Hide)
  EndIf
EndProcedure

Procedure.s RunAndCapture(exe$, args$)
  ; Run a console command and capture output.
  ; Important: winget can write heavily to stderr; if stderr isn't drained, the
  ; child process can block and the GUI appears frozen. PureBasic doesn't expose
  ; a portable stderr-read API across builds, so we redirect stderr -> stdout.
  ;
  ; Also, winget can prompt for Store source agreements; make background calls
  ; non-interactive so they never block waiting for input.
  Protected program, output$, line$
  Protected cmd$, cmdArgs$

  If LCase(exe$) = "winget"
    ; Keep winget non-interactive to avoid UI hangs.
    If FindString(args$, "--disable-interactivity", 1) = 0
      args$ + " --disable-interactivity"
    EndIf

    ; Agreements: not all subcommands support the same switches.
    ; `list` in v1.12 rejects `--accept-package-agreements`, so only add it
    ; for commands that actually install/upgrade.
    If FindString(args$, "--accept-source-agreements", 1) = 0
      args$ + " --accept-source-agreements"
    EndIf

    Protected cmdLower$ = LCase(Trim(StringField(args$, 1, " ")))
    If cmdLower$ = "upgrade" Or cmdLower$ = "install" Or cmdLower$ = "uninstall" Or cmdLower$ = "repair"
      If FindString(args$, "--accept-package-agreements", 1) = 0
        args$ + " --accept-package-agreements"
      EndIf
    EndIf
  EndIf

  cmd$ = "cmd.exe"
  cmdArgs$ = "/c " + Chr(34) + exe$ + " " + args$ + " 2^>^&1" + Chr(34)

  program = RunProgram(cmd$, cmdArgs$, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If program
    While ProgramRunning(program)
      If AvailableProgramOutput(program)
        line$ = ReadProgramString(program)
        output$ + line$ + #LF$
      Else
        WindowEvent()
        Delay(10)
      EndIf
    Wend

    While AvailableProgramOutput(program)
      output$ + ReadProgramString(program) + #LF$
    Wend

    CloseProgram(program)
  Else
    LogError("RunProgram failed", cmd$ + " " + cmdArgs$)
  EndIf

  ProcedureReturn Trim(output$)
EndProcedure

Procedure.b HasWinget()
  Protected out$

  out$ = RunAndCapture("winget", "--version")
  If Len(out$) > 0
    ProcedureReturn #True
  EndIf

  Protected localAppData$ = GetEnvironmentVariable("LOCALAPPDATA")
  Protected aliasPath$ = localAppData$ + "\\Microsoft\\WindowsApps\\winget.exe"
  If FileSize(aliasPath$) > 0
    out$ = RunAndCapture(aliasPath$, "--version")
    If Len(out$) > 0
      ProcedureReturn #True
    EndIf
  EndIf

  ProcedureReturn #False
EndProcedure

; -------------------- Single instance + elevation --------------------
Procedure ActivateExistingWindow()
  Protected hWnd = FindWindow_("", MainWindowTitle$)
  If hWnd
    ShowWindow_(hWnd, #SW_SHOWNORMAL)
    SetForegroundWindow_(hWnd)
  EndIf
EndProcedure

Procedure.b ActivateIfAlreadyRunning()
  Protected hMutex = OpenMutex_(#MUTEX_ACCESS, 0, MutexName$)
  If hMutex
    CloseHandle_(hMutex)
    ActivateExistingWindow()
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure EnsureElevated()
  If IsUserAnAdmin_()
    ProcedureReturn
  EndIf

  Protected exe$ = ProgramFilename()
  Protected params$ = ""

  If ShellExecute_(0, "runas", exe$, params$, GetPathPart(exe$), #SW_SHOWNORMAL) <= 32
    LogError("UAC elevation denied/failed", exe$)
    MessageRequester("Admin required", "Please allow UAC elevation to run this app.", #PB_MessageRequester_Ok)
  Else
    LogInfo("UAC elevation requested", exe$)
  EndIf

  End
EndProcedure

Procedure CreateAndOwnMutexOrExit()
  Protected hMutex = CreateMutex_(0, 1, MutexName$)
  If hMutex = 0
    LogError("CreateMutex failed", "GetLastError=" + Str(GetLastError_()) + " name=" + MutexName$)
    MessageRequester("Error", "Failed to create mutex. GetLastError=" + Str(GetLastError_()), #PB_MessageRequester_Ok)
    End
  EndIf

  If GetLastError_() = #ERROR_ALREADY_EXISTS
    LogInfo("Mutex already exists", MutexName$)
    CloseHandle_(hMutex)
    ActivateExistingWindow()
    End
  EndIf

  LogInfo("Mutex acquired", MutexName$)
  ; Keep hMutex open until exit
EndProcedure

; -------------------- Winget dialog --------------------

Procedure.i WingetMissingDialog(parentWindowID.i = 0)
  Protected w = 580, h = 250
  Protected winFlags = #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_TitleBar

  Protected win = OpenWindow(#PB_Any, 0, 0, w, h, "Winget required", winFlags, parentWindowID)
  If win = 0
    ProcedureReturn #WingetDlg_Exit
  EndIf

  Protected msg$
  msg$ = "Winget was not found (Microsoft 'App Installer' missing or disabled)." + #CRLF$ + #CRLF$ +
         "Without winget, large-catalog update checks (500+ apps) won't work." + #CRLF$ +
         "You can continue in limited mode (registry + portable scan only)."

  TextGadget(#WingetDlg_Text, 16, 16, w - 32, 110, msg$)
  CheckBoxGadget(#WingetDlg_CheckNoAsk, 16, 140, w - 32, 22, "Don't show this again")
  SetGadgetState(#WingetDlg_CheckNoAsk, Bool(ReadSuppressWingetPrompt()))

  ButtonGadget(#WingetDlg_BtnInstall, 16, 180, 120, 28, "Install")
  ButtonGadget(#WingetDlg_BtnRetry, 150, 180, 120, 28, "Retry")
  ButtonGadget(#WingetDlg_BtnLimited, 284, 180, 160, 28, "Continue limited")
  ButtonGadget(#WingetDlg_BtnExit, w - 16 - 80, 180, 80, 28, "Exit")

  Protected result = #WingetDlg_Exit
  Protected ev, gid

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_Gadget
        gid = EventGadget()
        Select gid
          Case #WingetDlg_BtnInstall
            result = #WingetDlg_Install
            Break
          Case #WingetDlg_BtnRetry
            result = #WingetDlg_Retry
            Break
          Case #WingetDlg_BtnLimited
            result = #WingetDlg_Limited
            Break
          Case #WingetDlg_BtnExit
            result = #WingetDlg_Exit
            Break
        EndSelect

      Case #PB_Event_CloseWindow
        result = #WingetDlg_Exit
        Break
    EndSelect
  ForEver

  WriteSuppressWingetPrompt(Bool(GetGadgetState(#WingetDlg_CheckNoAsk) <> 0))
  CloseWindow(win)

  ProcedureReturn result
EndProcedure

Procedure.b EnsureWingetOrLimitedModeNice(parentWindowID.i = 0)
  If HasWinget()
    LogInfo("Winget found")
    ProcedureReturn #True
  EndIf

  LogError("Winget missing")

  If ReadSuppressWingetPrompt()
    ProcedureReturn #False
  EndIf

  Repeat
    Select WingetMissingDialog(parentWindowID)
      Case #WingetDlg_Install
        OpenUrl("https://aka.ms/getwinget")

      Case #WingetDlg_Retry
        If HasWinget()
          ProcedureReturn #True
        Else
          MessageRequester("Still missing", "Winget is still not available. If you just installed it, wait a moment and retry.", #PB_MessageRequester_Ok)
        EndIf

      Case #WingetDlg_Limited
        ProcedureReturn #False

      Case #WingetDlg_Exit
        End
    EndSelect
  ForEver
EndProcedure

; -------------------- ARP + Windows Apps inventory --------------------

Procedure.s RegReadString(hKey, valueName$)
  Protected type.l, bytes.l

  If RegQueryValueEx_(hKey, valueName$, 0, @type, 0, @bytes) <> 0
    ProcedureReturn ""
  EndIf

  If bytes <= 2
    ProcedureReturn ""
  EndIf

  If type <> #REG_SZ And type <> #REG_EXPAND_SZ
    ProcedureReturn ""
  EndIf

  Protected *buf = AllocateMemory(bytes)
  If *buf = 0
    ProcedureReturn ""
  EndIf

  If RegQueryValueEx_(hKey, valueName$, 0, @type, *buf, @bytes) <> 0
    FreeMemory(*buf)
    ProcedureReturn ""
  EndIf

  Protected s$ = PeekS(*buf, -1, #PB_Unicode)
  FreeMemory(*buf)
  ProcedureReturn Trim(s$)
EndProcedure

Procedure.l RegReadDword(hKey, valueName$)
  Protected type.l, bytes.l = 4
  Protected v.l

  If RegQueryValueEx_(hKey, valueName$, 0, @type, @v, @bytes) <> 0
    ProcedureReturn 0
  EndIf

  If type <> #REG_DWORD
    ProcedureReturn 0
  EndIf

  ProcedureReturn v
EndProcedure

Procedure AddArpEntry(hKey)
  Protected name$ = RegReadString(hKey, "DisplayName")
  If name$ = ""
    ProcedureReturn
  EndIf

  If IncludeSystemComponents = #False
    If RegReadDword(hKey, "SystemComponent") <> 0
      ProcedureReturn
    EndIf
  EndIf

  Protected version$ = RegReadString(hKey, "DisplayVersion")
  Protected publisher$ = RegReadString(hKey, "Publisher")

  AddElement(Items())
  Items()\id = ""
  Items()\name = name$
  Items()\installedVersion = version$
  Items()\availableVersion = ""
  Items()\source = "ARP"
  If publisher$ <> ""
    Items()\source = "ARP - " + publisher$
  EndIf
EndProcedure

Procedure ScanArpRegistryPath(hiveHandle, subPath$)
  Protected hRoot.i
  If RegOpenKeyEx_(hiveHandle, subPath$, 0, #KEY_READ, @hRoot) <> 0
    LogError("RegOpenKeyEx failed", subPath$)
    ProcedureReturn
  EndIf

  Protected index.l = 0
  Protected keyName$ = Space(260)
  Protected nameLen.l

  While #True
    nameLen = 260

    ; RegEnumKeyExW expects a WCHAR buffer
    Protected rc = RegEnumKeyEx_(hRoot, index, @keyName$, @nameLen, 0, 0, 0, 0)
    If rc = #ERROR_NO_MORE_ITEMS
      Break
    EndIf

    If rc = 0
      Protected subKey$ = Left(keyName$, nameLen)
      Protected hSub.i
      If RegOpenKeyEx_(hRoot, subKey$, 0, #KEY_READ, @hSub) = 0
        AddArpEntry(hSub)
        RegCloseKey_(hSub)
      EndIf
    EndIf

    ; Keep UI responsive during large registry walks
    WindowEvent()

    index + 1
  Wend

  RegCloseKey_(hRoot)
EndProcedure

Procedure LoadInstalledFromARP()
  ScanArpRegistryPath(#HKEY_LOCAL_MACHINE, "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
  ScanArpRegistryPath(#HKEY_LOCAL_MACHINE, "Software\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
  ScanArpRegistryPath(#HKEY_CURRENT_USER, "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall")
EndProcedure

Procedure LoadWindowsAppsFromPowerShell()
  ; Best-effort: list Appx packages
  ; This can be slow; only run when enabled.

  Protected ps$ = "powershell"
  Protected args$ = "-NoProfile -ExecutionPolicy Bypass -Command " + Chr(34) + "Get-AppxPackage | Select-Object -Property Name, Version | Format-Table -HideTableHeaders" + Chr(34)

  Protected out$ = RunAndCapture(ps$, args$)
  If out$ = ""
    LogError("PowerShell Appx query returned empty", args$)
    ProcedureReturn
  EndIf

  Protected lines = CountString(out$, #LF$) + 1
  Protected i

  For i = 1 To lines
    ; Keep UI responsive when parsing many Appx packages
    If (i % 50) = 0
      WindowEvent()
    EndIf

    Protected line$ = Trim(StringField(out$, i, #LF$))
    If line$ = ""
      Continue
    EndIf

    ; Collapse multiple spaces (so we can split into two columns)
    line$ = CollapseMultiSpaceToTabs(line$)
    Protected cols = CountString(line$, Chr(9)) + 1
    If cols < 2
      Continue
    EndIf

    Protected name$ = Trim(StringField(line$, 1, Chr(9)))
    Protected ver$ = Trim(StringField(line$, 2, Chr(9)))

    If name$ <> ""
      AddElement(Items())
      Items()\id = ""
      Items()\name = name$
      Items()\installedVersion = ver$
      Items()\availableVersion = ""
      Items()\source = "Windows App"
    EndIf
  Next
EndProcedure

; -------------------- Winget JSON parsing --------------------

Procedure ClearItems()
  ClearList(Items())
  If IsGadget(#G_List)
    ClearGadgetItems(#G_List)
  EndIf
EndProcedure

Procedure AddOrUpdateItem(id$, name$, installed$, available$, source$)
  Protected found.b
  ForEach Items()
    If LCase(Items()\id) = LCase(id$) And id$ <> ""
      Items()\name = name$
      Items()\installedVersion = installed$
      Items()\availableVersion = available$
      Items()\source = source$
      found = #True
      Break
    EndIf
  Next

  If found = #False
    AddElement(Items())
    Items()\id = id$
    Items()\name = name$
    Items()\installedVersion = installed$
    Items()\availableVersion = available$
    Items()\source = source$
  EndIf
EndProcedure

Procedure.s NormalizeNameForMatch(name$)
  ; Normalizes names for loose matching across sources.
  ; Keep alnum plus '+' and '#', strip everything else.
  Protected out$, i, ch

  name$ = LCase(Trim(name$))

  For i = 1 To Len(name$)
    ch = Asc(Mid(name$, i, 1))

    Select ch
      Case 'a' To 'z', '0' To '9'
        out$ + Chr(ch)

      Case '+', '#'
        out$ + Chr(ch)
    EndSelect
  Next

  ProcedureReturn out$
EndProcedure

Procedure MergePreferExisting(*dst.SoftwareItem, *src.SoftwareItem)
  If *dst = 0 Or *src = 0
    ProcedureReturn
  EndIf

  If *dst\name = "" And *src\name <> ""
    *dst\name = *src\name
  EndIf

  If *dst\installedVersion = "" And *src\installedVersion <> ""
    *dst\installedVersion = *src\installedVersion
  EndIf

  If *dst\availableVersion = "" And *src\availableVersion <> ""
    *dst\availableVersion = *src\availableVersion
  EndIf

  If *dst\source = "" And *src\source <> ""
    *dst\source = *src\source
  EndIf

  If *dst\homepage = "" And *src\homepage <> ""
    *dst\homepage = *src\homepage
  EndIf

  If *dst\installPath = "" And *src\installPath <> ""
    *dst\installPath = *src\installPath
  EndIf

  If *dst\id = "" And *src\id <> ""
    *dst\id = *src\id
  EndIf
EndProcedure

Procedure DedupeItems()
  ; Rebuilds the Items() list without in-place deletes.
  ; Rules:
  ; - Prefer winget (any item with Id) over ARP matching by name
  ; - Dedupe ARP across hives
  ; - Dedupe portable duplicates by (name, version)
  ; - Merge duplicates by winget Id

  Protected NewMap byId.SoftwareItem()
  Protected NewMap nameHasWinget.b()
  Protected NewMap arpByKey.SoftwareItem()
  Protected NewMap portableByKey.SoftwareItem()
  Protected NewList others.SoftwareItem()

  ; 1) First pass: collect by winget Id (if present) and build nameHasWinget.
  ForEach Items()
    If Items()\id <> ""
      Protected idKey$ = LCase(Items()\id)

      If FindMapElement(byId(), idKey$)
        MergePreferExisting(@byId(), @Items())
      Else
        byId(idKey$) = Items()
      EndIf

      nameHasWinget(NormalizeNameForMatch(Items()\name)) = #True
    EndIf
  Next

  ; 2) Second pass: handle items without Id.
  ForEach Items()
    If Items()\id <> ""
      Continue
    EndIf

    Protected srcLower$ = LCase(Items()\source)

    ; Prefer winget over ARP duplicates
    If Left(srcLower$, 3) = "arp"
      If FindMapElement(nameHasWinget(), NormalizeNameForMatch(Items()\name))
        Continue
      EndIf

      Protected aKey$ = NormalizeNameForMatch(Items()\name) + "|" + Items()\installedVersion
      If FindMapElement(arpByKey(), aKey$)
        ; keep first, but merge missing fields just in case
        MergePreferExisting(@arpByKey(), @Items())
      Else
        arpByKey(aKey$) = Items()
      EndIf

      Continue
    EndIf

    ; Portable duplicates: dedupe by (name, version)
    If Items()\source = "Portable"
      Protected pKey$ = NormalizeNameForMatch(Items()\name) + "|" + Items()\installedVersion
      If FindMapElement(portableByKey(), pKey$)
        MergePreferExisting(@portableByKey(), @Items())
      Else
        portableByKey(pKey$) = Items()
      EndIf

      Continue
    EndIf

    ; Everything else (Windows App, etc.): keep as-is
    AddElement(others())
    others() = Items()
  Next

  ; 3) Rebuild Items() from the maps/lists.
  ClearList(Items())

  ForEach byId()
    AddElement(Items())
    Items() = byId()
  Next

  ForEach portableByKey()
    AddElement(Items())
    Items() = portableByKey()
  Next

  ForEach arpByKey()
    AddElement(Items())
    Items() = arpByKey()
  Next

  ForEach others()
    AddElement(Items())
    Items() = others()
  Next
EndProcedure

Procedure RefreshListGadget()
  If IsGadget(#G_List) = 0
    ProcedureReturn
  EndIf

  DedupeItems()

  ; Default sort by name (case-insensitive)
  SortStructuredList(Items(), #PB_Sort_Ascending | #PB_Sort_NoCase, OffsetOf(SoftwareItem\name), #PB_String)

  ClearGadgetItems(#G_List)

  ForEach Items()
    AddGadgetItem(#G_List, -1, Items()\name + Chr(10) + Items()\id + Chr(10) + Items()\installedVersion + Chr(10) + Items()\availableVersion + Chr(10) + Items()\source)
  Next

  SetGadgetText(#G_Status, Str(ListSize(Items())) + " items")
EndProcedure

Procedure.s JsonStr(node)
  If node
    ProcedureReturn GetJSONString(node)
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure.s ExtractJsonPayload(text$)
  ; Winget may print non-JSON text (banners, warnings) before/after the JSON.
  ; Extract the first balanced JSON object/array payload if present.

  Protected iObj = FindString(text$, "{", 1)
  Protected iArr = FindString(text$, "[", 1)
  Protected start

  If iObj = 0 And iArr = 0
    ProcedureReturn ""
  EndIf

  If iObj = 0
    start = iArr
  ElseIf iArr = 0
    start = iObj
  Else
    start = iObj
    If iArr < iObj
      start = iArr
    EndIf
  EndIf

  Protected payload$ = Mid(text$, start)
  Protected i, depth, inString.b, escape.b, ch

  For i = 1 To Len(payload$)
    ch = Asc(Mid(payload$, i, 1))

    If inString
      If escape
        escape = #False
        Continue
      EndIf

      If ch = '\'
        escape = #True
        Continue
      EndIf

      If ch = '"'
        inString = #False
      EndIf

      Continue
    EndIf

    If ch = '"'
      inString = #True
      Continue
    EndIf

    If ch = '{' Or ch = '['
      depth + 1
      Continue
    EndIf

    If ch = '}' Or ch = ']'
      depth - 1
      If depth = 0
        ProcedureReturn Trim(Left(payload$, i))
      EndIf
    EndIf
  Next

  ; If we couldn't find a balanced end, fall back to what we have.
  ProcedureReturn Trim(payload$)
EndProcedure

Procedure.i FindHeaderLine(text$, header1$, header2$)
  ; Returns line number (1-based) containing both header strings (case-insensitive).
  Protected lines = CountString(text$, #LF$) + 1
  Protected i

  Protected h1$ = LCase(header1$)
  Protected h2$ = LCase(header2$)

  For i = 1 To lines
    Protected line$ = LCase(StringField(text$, i, #LF$))
    If FindString(line$, h1$, 1) And FindString(line$, h2$, 1)
      ProcedureReturn i
    EndIf
  Next

  ProcedureReturn 0
EndProcedure

Procedure.s CollapseMultiSpaceToTabs(line$)
  ; Converts 2+ spaces into a single TAB delimiter.
  ; Keeps single spaces intact so names can contain spaces.

  Protected out$, i = 1, spaceCount

  While i <= Len(line$)
    Protected ch$ = Mid(line$, i, 1)
    If ch$ = " "
      spaceCount = 0
      While i <= Len(line$) And Mid(line$, i, 1) = " "
        spaceCount + 1
        i + 1
      Wend

      If spaceCount >= 2
        out$ + Chr(9)
      Else
        out$ + " "
      EndIf

      Continue
    EndIf

    out$ + ch$
    i + 1
  Wend

  ; collapse multiple tabs
  While FindString(out$, Chr(9) + Chr(9), 1)
    out$ = ReplaceString(out$, Chr(9) + Chr(9), Chr(9))
  Wend

  ProcedureReturn Trim(out$)
EndProcedure

Procedure SaveDebugTextFile(fileName$, content$)
  EnsureSettingsDir()
  Protected path$ = GetPathPart(SettingsPath$) + fileName$

  Protected f = CreateFile(#PB_Any, path$)
  If f
    WriteString(f, content$)
    CloseFile(f)
  EndIf
EndProcedure

Procedure.s SliceColumn(line$, startPos, endPos)
  ; startPos/endPos are 0-based indices into the string.
  If startPos < 0 : startPos = 0 : EndIf
  If endPos <= startPos
    ProcedureReturn Trim(Mid(line$, startPos + 1))
  EndIf

  ProcedureReturn Trim(Mid(line$, startPos + 1, endPos - startPos))
EndProcedure

Procedure.b ParseWingetListTable(text$)
  ; Parses the table output of: winget list
  ; Handles both cases:
  ; - list shows: Name Id Version Available Source
  ; - list shows: Name Id Version Source

  ClearItems()

  Protected headerLine = FindHeaderLine(text$, "name", "id")
  If headerLine = 0
    ProcedureReturn #False
  EndIf

  Protected startDataLine = headerLine + 2
  Protected lines = CountString(text$, #LF$) + 1
  Protected i

  For i = startDataLine To lines
    Protected lineRaw$ = StringField(text$, i, #LF$)
    Protected line$ = Trim(lineRaw$)

    If line$ = ""
      Continue
    EndIf

    ; Skip banners/help and separators
    If Left(line$, 2) = "--" Or FindString(line$, "More help", 1)
      Continue
    EndIf

    line$ = CollapseMultiSpaceToTabs(line$)
    Protected cols = CountString(line$, Chr(9)) + 1
    If cols < 3
      Continue
    EndIf

    Protected name$ = Trim(StringField(line$, 1, Chr(9)))
    Protected id$ = Trim(StringField(line$, 2, Chr(9)))
    Protected ver$ = Trim(StringField(line$, 3, Chr(9)))
    Protected available$ = ""
    Protected source$ = ""

    If cols >= 5
      available$ = Trim(StringField(line$, 4, Chr(9)))
      source$ = Trim(StringField(line$, 5, Chr(9)))
    ElseIf cols = 4
      source$ = Trim(StringField(line$, 4, Chr(9)))
    EndIf

    If name$ <> ""
      AddOrUpdateItem(id$, name$, ver$, available$, source$)
    EndIf
  Next

  ProcedureReturn Bool(ListSize(Items()) > 0)
EndProcedure

Procedure.b ParseWingetUpgradeTable(text$)
  ; Parses: winget upgrade
  ; Expected columns: Name Id Version Available Source

  Protected headerLine = FindHeaderLine(text$, "Name", "Available")
  If headerLine = 0
    ProcedureReturn #False
  EndIf

  Protected header$ = StringField(text$, headerLine, #LF$)
  Protected namePos = FindString(header$, "Name", 1) - 1
  Protected idPos = FindString(header$, "Id", 1) - 1
  Protected verPos = FindString(header$, "Version", 1) - 1
  Protected availPos = FindString(header$, "Available", 1) - 1
  Protected srcPos = FindString(header$, "Source", 1) - 1

  Protected startDataLine = headerLine + 2
  Protected lines = CountString(text$, #LF$) + 1
  Protected i

  For i = startDataLine To lines
    Protected line$ = StringField(text$, i, #LF$)
    If Trim(line$) = ""
      Continue
    EndIf

    Protected name$ = SliceColumn(line$, namePos, idPos)
    Protected id$ = SliceColumn(line$, idPos, verPos)
    Protected installed$ = SliceColumn(line$, verPos, availPos)
    Protected available$ = ""
    Protected source$ = ""

    If srcPos > 0
      available$ = SliceColumn(line$, availPos, srcPos)
      source$ = Trim(Mid(line$, srcPos + 1))
    Else
      available$ = Trim(Mid(line$, availPos + 1))
    EndIf

    If name$ <> "" And available$ <> ""
      AddOrUpdateItem(id$, name$, installed$, available$, source$)
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.b ParseWingetListJson(text$)
  ; winget list --output json
  ; Expected keys vary slightly across versions; handle multiple common cases.

  Protected json$ = ExtractJsonPayload(text$)
  If json$ = ""
    ProcedureReturn #False
  EndIf

  Protected jsonDoc = ParseJSON(#PB_Any, json$)
  If jsonDoc = 0
    ProcedureReturn #False
  EndIf

  Protected root = JSONValue(jsonDoc)
  If root = 0
    FreeJSON(jsonDoc)
    ProcedureReturn #False
  EndIf

  Protected id$, name$, installed$, source$
  Protected sources = GetJSONMember(root, "Sources")
  Protected dataNode = GetJSONMember(root, "Data")

  If sources
    Protected sourcesArr = JSONArraySize(sources)
    Protected i, j

    For i = 0 To sourcesArr - 1
      Protected sourceObj = GetJSONElement(sources, i)
      If sourceObj
        Protected pkgs = GetJSONMember(sourceObj, "Packages")
        If pkgs
          For j = 0 To JSONArraySize(pkgs) - 1
            Protected pkgObj = GetJSONElement(pkgs, j)
            If pkgObj
              id$ = JsonStr(GetJSONMember(pkgObj, "PackageIdentifier"))
              If id$ = "" : id$ = JsonStr(GetJSONMember(pkgObj, "Id")) : EndIf

              name$ = JsonStr(GetJSONMember(pkgObj, "Name"))

              installed$ = JsonStr(GetJSONMember(pkgObj, "InstalledVersion"))
              If installed$ = "" : installed$ = JsonStr(GetJSONMember(pkgObj, "Version")) : EndIf

              source$ = JsonStr(GetJSONMember(pkgObj, "Source"))

              If name$ <> ""
                AddOrUpdateItem(id$, name$, installed$, "", source$)
              EndIf
            EndIf
          Next
        EndIf
      EndIf
    Next

    FreeJSON(jsonDoc)
    ProcedureReturn #True
  EndIf

  If dataNode
    Protected n = JSONArraySize(dataNode)
    Protected k

    For k = 0 To n - 1
      Protected obj = GetJSONElement(dataNode, k)
      If obj
        id$ = JsonStr(GetJSONMember(obj, "PackageIdentifier"))
        If id$ = "" : id$ = JsonStr(GetJSONMember(obj, "Id")) : EndIf

        name$ = JsonStr(GetJSONMember(obj, "Name"))

        installed$ = JsonStr(GetJSONMember(obj, "InstalledVersion"))
        If installed$ = "" : installed$ = JsonStr(GetJSONMember(obj, "Version")) : EndIf

        source$ = JsonStr(GetJSONMember(obj, "Source"))

        If name$ <> ""
          AddOrUpdateItem(id$, name$, installed$, "", source$)
        EndIf
      EndIf
    Next

    FreeJSON(jsonDoc)
    ProcedureReturn #True
  EndIf

  FreeJSON(jsonDoc)
  ProcedureReturn #False
EndProcedure

Procedure.b ParseWingetUpgradeJson(text$)
  ; winget upgrade --output json
  ; Expected keys vary slightly. We try several common ones.

  Protected json$ = ExtractJsonPayload(text$)
  If json$ = ""
    ProcedureReturn #False
  EndIf

  Protected jsonDoc = ParseJSON(#PB_Any, json$)
  If jsonDoc = 0
    ProcedureReturn #False
  EndIf

  Protected root = JSONValue(jsonDoc)
  If root = 0
    FreeJSON(jsonDoc)
    ProcedureReturn #False
  EndIf

  Protected id$, name$, installed$, available$, source$
  Protected sources = GetJSONMember(root, "Sources")
  Protected dataNode = GetJSONMember(root, "Data")

  If sources
    Protected sourcesArr = JSONArraySize(sources)
    Protected i, j

    For i = 0 To sourcesArr - 1
      Protected sourceObj = GetJSONElement(sources, i)
      If sourceObj
        Protected pkgs = GetJSONMember(sourceObj, "Packages")
        If pkgs
          For j = 0 To JSONArraySize(pkgs) - 1
            Protected pkgObj = GetJSONElement(pkgs, j)
            If pkgObj
              id$ = JsonStr(GetJSONMember(pkgObj, "PackageIdentifier"))
              If id$ = "" : id$ = JsonStr(GetJSONMember(pkgObj, "Id")) : EndIf

              name$ = JsonStr(GetJSONMember(pkgObj, "Name"))

              installed$ = JsonStr(GetJSONMember(pkgObj, "InstalledVersion"))
              If installed$ = "" : installed$ = JsonStr(GetJSONMember(pkgObj, "Version")) : EndIf

              available$ = JsonStr(GetJSONMember(pkgObj, "AvailableVersion"))
              If available$ = "" : available$ = JsonStr(GetJSONMember(pkgObj, "UpgradeVersion")) : EndIf

              source$ = JsonStr(GetJSONMember(pkgObj, "Source"))

              If name$ <> "" And available$ <> ""
                AddOrUpdateItem(id$, name$, installed$, available$, source$)
              EndIf
            EndIf
          Next
        EndIf
      EndIf
    Next

    FreeJSON(jsonDoc)
    ProcedureReturn #True
  EndIf

  If dataNode
    Protected n = JSONArraySize(dataNode)
    Protected k

    For k = 0 To n - 1
      Protected obj = GetJSONElement(dataNode, k)
      If obj
        id$ = JsonStr(GetJSONMember(obj, "PackageIdentifier"))
        If id$ = "" : id$ = JsonStr(GetJSONMember(obj, "Id")) : EndIf

        name$ = JsonStr(GetJSONMember(obj, "Name"))

        installed$ = JsonStr(GetJSONMember(obj, "InstalledVersion"))
        If installed$ = "" : installed$ = JsonStr(GetJSONMember(obj, "Version")) : EndIf

        available$ = JsonStr(GetJSONMember(obj, "AvailableVersion"))
        If available$ = "" : available$ = JsonStr(GetJSONMember(obj, "UpgradeVersion")) : EndIf

        source$ = JsonStr(GetJSONMember(obj, "Source"))

        If name$ <> "" And available$ <> ""
          AddOrUpdateItem(id$, name$, installed$, available$, source$)
        EndIf
      EndIf
    Next

    FreeJSON(jsonDoc)
    ProcedureReturn #True
  EndIf

  FreeJSON(jsonDoc)
  ProcedureReturn #False
EndProcedure

Procedure LoadInstalledFromWinget()
  IncludeSystemComponents = Bool(GetGadgetState(#G_ChkIncludeSystem) <> 0)
  IncludeWindowsApps = Bool(GetGadgetState(#G_ChkIncludeWindowsApps) <> 0)
  SaveIncludeOptions()

  SetGadgetText(#G_Status, "Loading installed packages...")

  ClearItems()

  ; 1) winget managed packages (no system components)
  If WingetEnabled
    Protected out$ = RunAndCapture("winget", "list --output json")
    If FindString(out$, "Argument name was not recognized", 1) Or out$ = ""
      out$ = RunAndCapture("winget", "list")
    EndIf

    If out$ <> ""
      If ParseWingetListJson(out$) = #False
        If ParseWingetListTable(out$) = #False
          LogError("Failed to parse winget list output", "Saved winget-list-debug.txt")
          SaveDebugTextFile("winget-list-debug.txt", out$)
        EndIf
      EndIf
    EndIf
  EndIf

  ; 2) ARP (Add/Remove Programs), optionally including SystemComponent entries
  LoadInstalledFromARP()

  ; 3) Windows apps (Appx) via PowerShell, optional
  If IncludeWindowsApps
    LoadWindowsAppsFromPowerShell()
  EndIf

  RefreshListGadget()
EndProcedure

Procedure CheckUpgradesFromWinget()
  IncludeSystemComponents = Bool(GetGadgetState(#G_ChkIncludeSystem) <> 0)
  IncludeWindowsApps = Bool(GetGadgetState(#G_ChkIncludeWindowsApps) <> 0)
  SaveIncludeOptions()

  If WingetEnabled = #False
    MessageRequester("Limited mode", "Winget is disabled/missing. Install winget to check upgrades.", #PB_MessageRequester_Ok)
    ProcedureReturn
  EndIf

  SetGadgetText(#G_Status, "Checking upgrades...")

  ; Prefer JSON if supported, fall back to table output.
  Protected out$ = RunAndCapture("winget", "upgrade --output json")
  If FindString(out$, "Argument name was not recognized", 1) Or out$ = ""
    out$ = RunAndCapture("winget", "upgrade")
  EndIf

  If out$ = ""
    LogError("winget upgrade returned empty")
    MessageRequester("Error", "Failed to run winget upgrade.", #PB_MessageRequester_Ok)
    SetGadgetText(#G_Status, "winget upgrade failed")
    ProcedureReturn
  EndIf

  ; Keep current list; just fill available versions for any upgradable packages.
  If ParseWingetUpgradeJson(out$) = #False
    If ParseWingetUpgradeTable(out$) = #False
      LogError("Failed to parse winget upgrade output", "Saved winget-upgrade-debug.txt")
      SaveDebugTextFile("winget-upgrade-debug.txt", out$)
      MessageRequester("Error", "Failed to parse winget upgrade output.", #PB_MessageRequester_Ok)
      SetGadgetText(#G_Status, "parse error")
      ProcedureReturn
    EndIf
  EndIf

  RefreshListGadget()
EndProcedure

Procedure.s GetSelectedId()
  Protected idx = GetGadgetState(#G_List)
  If idx < 0
    ProcedureReturn ""
  EndIf

  ProcedureReturn GetGadgetItemText(#G_List, idx, 1)
EndProcedure

Procedure.s GetSelectedName()
  Protected idx = GetGadgetState(#G_List)
  If idx < 0
    ProcedureReturn ""
  EndIf

  ProcedureReturn GetGadgetItemText(#G_List, idx, 0)
EndProcedure

Procedure UpgradeSelected()
  If WingetEnabled = #False
    MessageRequester("Limited mode", "Winget is disabled/missing.", #PB_MessageRequester_Ok)
    ProcedureReturn
  EndIf

  Protected id$ = GetSelectedId()
  Protected name$ = GetSelectedName()
  If id$ = ""
    MessageRequester("Select an item", "Select an item that has a winget Id.", #PB_MessageRequester_Ok)
    ProcedureReturn
  EndIf

  If MessageRequester("Upgrade", "Upgrade now?" + #CRLF$ + name$ + " (" + id$ + ")", #PB_MessageRequester_YesNo) <> #PB_MessageRequester_Yes
    ProcedureReturn
  EndIf

  ; Run winget and wait for completion, then refresh inventory.
  ; Use RunAndCapture() so we can wait reliably and avoid agreement prompts.
  SetGadgetText(#G_Status, "Upgrading " + name$ + "...")

  Protected out$ = RunAndCapture("winget", "upgrade --id " + Chr(34) + id$ + Chr(34) + " -e")
  If out$ = ""
    LogError("winget upgrade returned empty", id$)
  EndIf

  ; Refresh installed list and upgrade availability
  LoadInstalledFromWinget()
  CheckUpgradesFromWinget()
EndProcedure

Procedure.s ExtractFirstHttpUrl(text$)
  Protected i = FindString(text$, "http://", 1)
  Protected j = FindString(text$, "https://", 1)
  Protected start

  If i = 0 And j = 0
    ProcedureReturn ""
  EndIf

  start = i
  If start = 0 Or (j > 0 And j < start)
    start = j
  EndIf

  Protected rest$ = Mid(text$, start)

  ; Stop at first whitespace
  Protected k
  For k = 1 To Len(rest$)
    Protected ch$ = Mid(rest$, k, 1)
    If ch$ = " " Or ch$ = #CR$ Or ch$ = #LF$ Or ch$ = Chr(9)
      ProcedureReturn Left(rest$, k - 1)
    EndIf
  Next

  ProcedureReturn rest$
EndProcedure

Procedure.s WingetGetHomepageUrl(id$)
  If WingetEnabled = #False Or id$ = ""
    ProcedureReturn ""
  EndIf

  ; Parse text output of `winget show` and pick first URL from relevant fields.
  Protected out$ = RunAndCapture("winget", "show --id " + Chr(34) + id$ + Chr(34) + " -e")
  If out$ = ""
    ProcedureReturn ""
  EndIf

  ; Prefer lines containing these labels.
  Protected lines = CountString(out$, #LF$) + 1
  Protected i

  For i = 1 To lines
    Protected line$ = Trim(StringField(out$, i, #LF$))
    Protected ll$ = LCase(line$)

    If FindString(ll$, "homepage", 1) Or FindString(ll$, "publisher", 1) Or FindString(ll$, "support", 1) Or FindString(ll$, "license", 1)
      Protected url$ = ExtractFirstHttpUrl(line$)
      If url$ <> ""
        ProcedureReturn url$
      EndIf
    EndIf
  Next

  ; fallback: any URL at all
  ProcedureReturn ExtractFirstHttpUrl(out$)
EndProcedure

Procedure OpenHomepageForSelected()
  Protected id$ = GetSelectedId()
  Protected name$ = GetSelectedName()

  If id$ <> ""
    Protected url$ = WingetGetHomepageUrl(id$)
    If url$ <> ""
      OpenUrl(url$)
      ProcedureReturn
    EndIf

    ; fallback to winget.run package page
    OpenUrl("https://winget.run/pkg/" + id$)
    ProcedureReturn
  EndIf

  If name$ <> ""
    OpenUrl("https://www.bing.com/search?q=" + UrlEncodeQuery(name$ + " download"))
  EndIf
EndProcedure

Procedure.s WingetPickIdBySearch(query$)
  If WingetEnabled = #False
    MessageRequester("Winget disabled", "Winget is missing/disabled; cannot search.", #PB_MessageRequester_Ok)
    ProcedureReturn ""
  EndIf

  If query$ = ""
    ProcedureReturn ""
  EndIf

  ; We parse the text output. JSON output for 'winget search' is not consistent across all versions.
  Protected out$ = RunAndCapture("winget", "search " + Chr(34) + query$ + Chr(34))
  If out$ = ""
    ProcedureReturn ""
  EndIf

  ; Create a picker window with detected Ids.
  Protected w = 820, h = 520
  Protected win = OpenWindow(#PB_Any, 0, 0, w, h, "Select winget package", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_TitleBar, WindowID(#WinMain))
  If win = 0
    ProcedureReturn ""
  EndIf

  Protected idList = 2000
  Protected btnOk = 2001
  Protected btnCancel = 2002

  TextGadget(#PB_Any, 12, 12, w - 24, 40, "Search results for: " + query$ + #CRLF$ + "Select the best matching Id.")

  ListIconGadget(idList, 12, 60, w - 24, h - 130, "Row", 60, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(idList, 1, "Id", 260)
  AddGadgetColumn(idList, 2, "Version", 120)
  AddGadgetColumn(idList, 3, "Source", 100)
  AddGadgetColumn(idList, 4, "Name", 240)

  ButtonGadget(btnOk, w - 12 - 190, h - 55, 90, 28, "OK")
  ButtonGadget(btnCancel, w - 12 - 90, h - 55, 90, 28, "Cancel")

  ; Parse winget search table output.
  ; We look for rows containing at least 3+ spaces and try to split columns by 2+ spaces.
  Protected lines = CountString(out$, #LF$) + 1
  Protected i

  For i = 1 To lines
    Protected line$ = Trim(StringField(out$, i, #LF$))

    If line$ = "" Or Left(line$, 2) = "--" Or FindString(line$, "Name", 1) And FindString(line$, "Id", 1)
      Continue
    EndIf

    ; Collapse multiple spaces to a delimiter.
    Protected tmp$ = line$
    While FindString(tmp$, "  ", 1)
      tmp$ = ReplaceString(tmp$, "  ", Chr(9))
    Wend

    ; Now split by tabs.
    Protected fCount = CountString(tmp$, Chr(9)) + 1
    If fCount < 3
      Continue
    EndIf

    Protected nameCol$ = Trim(StringField(tmp$, 1, Chr(9)))
    Protected idCol$ = Trim(StringField(tmp$, 2, Chr(9)))
    Protected verCol$ = Trim(StringField(tmp$, 3, Chr(9)))
    Protected srcCol$ = ""
    If fCount >= 4
      srcCol$ = Trim(StringField(tmp$, 4, Chr(9)))
    EndIf

    If idCol$ <> ""
      AddGadgetItem(idList, -1, Str(CountGadgetItems(idList) + 1) + Chr(10) + idCol$ + Chr(10) + verCol$ + Chr(10) + srcCol$ + Chr(10) + nameCol$)
    EndIf
  Next

  Protected selectedId$ = ""
  Protected ev, gid

  Repeat
    ev = WaitWindowEvent()

    Select ev
      Case #PB_Event_CloseWindow
        Break

      Case #PB_Event_Gadget
        gid = EventGadget()
        Select gid
          Case btnOk
            Protected idx = GetGadgetState(idList)
            If idx >= 0
              selectedId$ = GetGadgetItemText(idList, idx, 1)
            EndIf
            Break

          Case btnCancel
            Break

          Case idList
            If EventType() = #PB_EventType_LeftDoubleClick
              Protected didx = GetGadgetState(idList)
              If didx >= 0
                selectedId$ = GetGadgetItemText(idList, didx, 1)
                Break
              EndIf
            EndIf
        EndSelect
    EndSelect

    If selectedId$ <> ""
      Break
    EndIf
  ForEver

  CloseWindow(win)
  ProcedureReturn selectedId$
EndProcedure

Procedure MatchSelectedPortableToWinget()
  Protected idx = GetGadgetState(#G_List)
  If idx < 0
    MessageRequester("Match", "Select a portable item first.", #PB_MessageRequester_Ok)
    ProcedureReturn
  EndIf

  ; For portables, path is stored in the hidden field, not displayed.
  ; We reconstruct by searching our Items() list by row index.
  Protected row = idx
  Protected i = 0
  Protected exePath$ = ""
  Protected currentId$ = GetGadgetItemText(#G_List, idx, 1)

  ForEach Items()
    If i = row
      If Items()\source = "Portable"
        exePath$ = Items()\installPath
      EndIf
      Break
    EndIf
    i + 1
  Next

  If exePath$ = ""
    MessageRequester("Match", "Selected row is not a portable item.", #PB_MessageRequester_Ok)
    ProcedureReturn
  EndIf

  Protected query$ = GetGadgetItemText(#G_List, idx, 0)
  Protected selectedId$ = WingetPickIdBySearch(query$)
  If selectedId$ = ""
    ProcedureReturn
  EndIf

  SetPortableMappedWingetId(exePath$, selectedId$)

  ; update row display + in-memory item
  SetGadgetItemText(#G_List, idx, selectedId$, 1)

  i = 0
  ForEach Items()
    If i = row
      Items()\id = selectedId$
      Break
    EndIf
    i + 1
  Next

  MessageRequester("Mapped", "Mapped portable app to winget Id:" + #CRLF$ + selectedId$, #PB_MessageRequester_Ok)
EndProcedure

; -------------------- Portable settings UI --------------------

Procedure OpenPortableSettingsWindow(parentWin = #WinMain)
  LoadPortableRoots()

  Protected w = 650, h = 420
  Protected win = OpenWindow(#PB_Any, 0, 0, w, h, "Portable scan folders", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_TitleBar, WindowID(parentWin))
  If win = 0
    ProcedureReturn
  EndIf

  Protected gList = 1000
  Protected gAdd = 1001
  Protected gRemove = 1002
  Protected gSave = 1003
  Protected gCancel = 1004

  TextGadget(#PB_Any, 12, 12, w - 24, 40, "Add one or more folders that contain portable apps (e.g. C:\\PortableApps)." + #CRLF$ + "Scanning the whole disk is not recommended.")

  ListViewGadget(gList, 12, 60, w - 24, h - 125)
  ForEach PortableRoots()
    AddGadgetItem(gList, -1, PortableRoots())
  Next

  ButtonGadget(gAdd, 12, h - 55, 110, 28, "Add...")
  ButtonGadget(gRemove, 132, h - 55, 110, 28, "Remove")

  ButtonGadget(gSave, w - 12 - 200, h - 55, 95, 28, "Save")
  ButtonGadget(gCancel, w - 12 - 95, h - 55, 95, 28, "Cancel")

  Protected ev, gid

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_CloseWindow
        Break

      Case #PB_Event_Gadget
        gid = EventGadget()
        Select gid
          Case gAdd
            Protected folder$ = PathRequester("Choose portable apps folder", "")
            folder$ = NormalizeFolderPath(folder$)
            If folder$ <> "" And FileSize(folder$) = -2
              ; de-dupe
              Protected exists.b
              Protected i
              For i = 0 To CountGadgetItems(gList) - 1
                If LCase(GetGadgetItemText(gList, i)) = LCase(folder$)
                  exists = #True
                  Break
                EndIf
              Next

              If exists = #False
                AddGadgetItem(gList, -1, folder$)
              EndIf
            EndIf

          Case gRemove
            Protected idx = GetGadgetState(gList)
            If idx >= 0
              RemoveGadgetItem(gList, idx)
            EndIf

          Case gSave
            ClearList(PortableRoots())
            Protected c = CountGadgetItems(gList)
            Protected n
              For n = 0 To c - 1
                Protected p$ = NormalizeFolderPath(GetGadgetItemText(gList, n))
                If p$ <> "" And FileSize(p$) = -2
                  AddElement(PortableRoots())
                  PortableRoots() = p$
                EndIf
              Next

            SavePortableRoots()
            Break

          Case gCancel
            Break
        EndSelect
    EndSelect
  ForEver

  CloseWindow(win)
EndProcedure

; -------------------- UI --------------------

Procedure CreateMainWindow()
  Protected w = 1000, h = 650

  OpenWindow(#WinMain, 0, 0, w, h, MainWindowTitle$ + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget)

  ListIconGadget(#G_List, 10, 10, w - 20, h - 125, "Name", 280, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#G_List, 1, "Id", 260)
  AddGadgetColumn(#G_List, 2, "Installed", 120)
  AddGadgetColumn(#G_List, 3, "Available", 120)
  AddGadgetColumn(#G_List, 4, "Source", 200)

  CheckBoxGadget(#G_ChkIncludeSystem, 10, h - 105, 180, 20, "Include system components")
  SetGadgetState(#G_ChkIncludeSystem, Bool(IncludeSystemComponents))

  CheckBoxGadget(#G_ChkIncludeWindowsApps, 200, h - 105, 220, 20, "Include Windows apps")
  SetGadgetState(#G_ChkIncludeWindowsApps, Bool(IncludeWindowsApps))

  ButtonGadget(#G_BtnLoadInstalled, 10, h - 75, 150, 28, "Load Installed")
  ButtonGadget(#G_BtnCheckUpgrades, 170, h - 75, 150, 28, "Check Upgrades")
  ButtonGadget(#G_BtnUpgradeSelected, 330, h - 75, 150, 28, "Upgrade Selected")
  ButtonGadget(#G_BtnOpenHomepage, 490, h - 75, 110, 28, "Open Page")

  ButtonGadget(#G_BtnScanPortable, 610, h - 75, 120, 28, "Scan Portable")
  ButtonGadget(#G_BtnMatchPortable, 740, h - 75, 150, 28, "Match to winget")
  ButtonGadget(#G_BtnAbout, w - 100, h - 108, 90, 28, "About")
  ButtonGadget(#G_BtnPortableSettings, 900, h - 75, 90, 28, "Folders")
  TextGadget(#G_Status, 10, h - 42, w - 130, 20, "Ready")
  ButtonGadget(#G_BtnViewLog, w - 100, h - 42, 90, 28, "View log")
  
EndProcedure

; -------------------- Main --------------------

If ActivateIfAlreadyRunning()
  CloseHandle_(hMutex)
  End
EndIf

EnsureElevated()
CreateAndOwnMutexOrExit()

LoadIncludeOptions()
CreateMainWindow()
WingetEnabled = EnsureWingetOrLimitedModeNice(WindowID(#WinMain))
LoadPortableMap()

If WingetEnabled
  SetGadgetText(#G_Status, "Winget enabled")
Else
  SetGadgetText(#G_Status, "Limited mode (winget missing)")
EndIf

Define ev, gid

Repeat
  ev = WaitWindowEvent()
  Select ev
    Case #PB_Event_Gadget
      gid = EventGadget()
      Select gid
        Case #G_ChkIncludeSystem, #G_ChkIncludeWindowsApps
          IncludeSystemComponents = Bool(GetGadgetState(#G_ChkIncludeSystem) <> 0)
          IncludeWindowsApps = Bool(GetGadgetState(#G_ChkIncludeWindowsApps) <> 0)
          SaveIncludeOptions()

        Case #G_BtnLoadInstalled
          LoadInstalledFromWinget()

        Case #G_BtnCheckUpgrades
          CheckUpgradesFromWinget()

        Case #G_BtnUpgradeSelected
          UpgradeSelected()

        Case #G_BtnOpenHomepage
          OpenHomepageForSelected()

        Case #G_BtnScanPortable
          ScanPortableFolders()

        Case #G_BtnMatchPortable
          MatchSelectedPortableToWinget()

        Case #G_BtnPortableSettings
          OpenPortableSettingsWindow(#WinMain)

        Case #G_BtnViewLog
          OpenErrorLog()
          
        Case #G_BtnAbout
          ShowAbout()  
      EndSelect

    Case #PB_Event_CloseWindow
      Exit()
  EndSelect
ForEver

End

; IDE Options = PureBasic 6.30 beta 7 (Windows - x64)
; CursorPosition = 1283
; FirstLine = 1279
; Folding = -------------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = TheUpdater.ico
; Executable = ..\TheUpdater.exe
; DisableDebugger
; IncludeVersionInfo
; VersionField0 = 1,0,0,1
; VersionField1 = 1,0,0,1
; VersionField2 = ZoneSoft
; VersionField3 = TheUpdater
; VersionField4 = 1.0.0.1
; VersionField5 = 1.0.0.1
; VersionField6 = Updates your installed programs (winget)
; VersionField7 = TheUpdater
; VersionField8 = TheUpdater.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60