; PureBasic 6.30 x64 - Safe Game Booster (MVP)
; - Launch EXE directly or via Steam
; - Set priority + optional affinity
; - Always switch to High performance while boosting and restore after

EnableExplicit

#APP_NAME = "SafeGameBooster"

Global DataDir.s, GamesIni.s, SessionIni.s
DataDir = GetPathPart(ProgramFilename())
GamesIni = DataDir + "games.ini"
SessionIni = DataDir + "session.ini"
Global LogPath.s
LogPath = DataDir + #APP_NAME + ".log"

Global FontUI.i, FontTitle.i, FontSmall.i
Global MainStatusBar.i
Global version.s = "v1.0.0.1"

Declare ViewLog()

; Prevent multiple instances (don't rely on window title text)
; Allow helper modes to run even if the tray app is running.
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

Procedure.s HelpText()
  Protected t.s
  t + #APP_NAME + " - In-App Help" + #CRLF$ + #CRLF$
  t + "What it does" + #CRLF$
  t + "- Launches a game (EXE or Steam) and applies temporary boosts." + #CRLF$
  t + "- Always switches Windows power plan to High performance while the game runs, then restores your previous plan." + #CRLF$
  t + "- Optionally stops selected services during gameplay, then starts them again when you exit." + #CRLF$
  t + "- Logs actions to " + #APP_NAME + ".log and can restore after a crash." + #CRLF$ + #CRLF$
  t + "What it does NOT do" + #CRLF$
  t + "- It does not permanently change Windows settings." + #CRLF$
  t + "- It does not 'disable' services (startup type). It only stops/starts them temporarily." + #CRLF$ + #CRLF$
  t + "Quick start" + #CRLF$
  t + "1) Add games:" + #CRLF$
  t + "   - Add: prompts for name + EXE + args" + #CRLF$
  t + "   - Browse EXE: adds one EXE quickly (deduped)" + #CRLF$
  t + "   - Add Folder: scans a folder and tries to pick the main EXE per game folder" + #CRLF$
  t + "   - Import Steam: imports installed Steam games and launches via AppID" + #CRLF$
  t + "2) Edit a game:" + #CRLF$
  t + "   - Select a game -> Edit -> set priority + pick services" + #CRLF$
  t + "   - In the services picker you can also right-click selected rows to Start/Stop now." + #CRLF$
  t + "3) Run:" + #CRLF$
  t + "   - Select a game -> Run" + #CRLF$ + #CRLF$
  t + "Services (important)" + #CRLF$
  t + "- Services you check are saved per game." + #CRLF$
  t + "- When you click Run, SafeBooster stops services and records ONLY those it actually stopped." + #CRLF$
  t + "- On exit, it restarts exactly that recorded set." + #CRLF$
  t + "- If a service fails to stop/start, the log records the error." + #CRLF$ + #CRLF$
  t + "Crash recovery" + #CRLF$
  t + "- While a game is running, session.ini is marked 'dirty' and stores:" + #CRLF$
  t + "  - the previous power plan GUID" + #CRLF$
  t + "  - the effective list of stopped services" + #CRLF$
  t + "- Next time SafeBooster starts, it detects a dirty session and restores power plan/services." + #CRLF$ + #CRLF$
  t + "Where files are" + #CRLF$
  t + "- games.ini, session.ini, " + #APP_NAME + ".log are stored next to the EXE." + #CRLF$
  t + "- Use the Log button to open " + #APP_NAME + ".log." + #CRLF$ + #CRLF$
  t + "Troubleshooting" + #CRLF$
  t + "- Admin rights: service control requires an elevated process. SafeBooster auto-prompts via UAC." + #CRLF$
  t + "- Steam games: SafeBooster waits for a new process whose EXE path starts with the game's install folder." + #CRLF$
  t + "- If Run 'does nothing', make sure a game is selected, then check " + #APP_NAME + ".log." + #CRLF$
  ProcedureReturn t
EndProcedure

Procedure ShowHelp()
  Protected w.i, gText.i, gClose.i, gOpenLog.i
  Protected ev.i

  ; Use #PB_Any to avoid very large object IDs.
  w = OpenWindow(#PB_Any, 0, 0, 820, 620, "Help", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If w
    DisableWindow(0, 1)

    gText = EditorGadget(#PB_Any, 10, 10, 800, 560)
    SetGadgetText(gText, HelpText())
    ; Keep it scrollable, but read-only.
    SetGadgetAttribute(gText, #PB_Editor_ReadOnly, 1)

    gOpenLog = ButtonGadget(#PB_Any, 10, 580, 120, 30, "Open Log")
    gClose   = ButtonGadget(#PB_Any, 690, 580, 120, 30, "Close")

    If FontUI
      SetGadgetFont(gText, FontID(FontUI))
      SetGadgetFont(gOpenLog, FontID(FontUI))
      SetGadgetFont(gClose, FontID(FontUI))
    EndIf

    Repeat
      ev = WaitWindowEvent()
      Select ev
        Case #PB_Event_Gadget
          Select EventGadget()
            Case gOpenLog
              ViewLog()
            Case gClose
              CloseWindow(w)
              Break
          EndSelect

        Case #PB_Event_CloseWindow
          If EventWindow() = w
            CloseWindow(w)
            Break
          EndIf
      EndSelect
    ForEver

    DisableWindow(0, 0)
  EndIf
EndProcedure

; ---------- Windows constants ----------

#NORMAL_PRIORITY_CLASS      = $00000020
#ABOVE_NORMAL_PRIORITY_CLASS= $00008000
#HIGH_PRIORITY_CLASS        = $00000080

; Process access rights
CompilerIf Defined(PROCESS_QUERY_LIMITED_INFORMATION, #PB_Constant) = 0
  #PROCESS_QUERY_LIMITED_INFORMATION = $1000
CompilerEndIf

#WAIT_OBJECT_0 = 0

Structure GameEntry
  Name.s
  ExePath.s
  Args.s
  WorkDir.s
  Priority.l     ; 0 = don't change
  Affinity.q     ; 0 = don't change
  Services.s     ; comma-separated service names to stop while boosting
  ; Launch
  LaunchMode.i   ; 0 = exe, 1 = steam
  SteamAppId.i
  SteamExe.s
  SteamClientArgs.s        ; optional args for Steam.exe itself
  SteamGameArgs.s          ; optional args passed after -applaunch <appid>
  SteamDetectTimeoutMs.i   ; wait for game process detection
  GameRoot.s     ; for Steam: install folder prefix to match process
  ; Legacy (kept for backward compatibility; ignored)
  PowerGuid.s
EndStructure

Global NewList Games.GameEntry()
Global CurrentIndex.i = -1
Global idx.i
Global g.GameEntry
Global BrowseExePath.s
Global BeforeCount.i

Procedure.s NowStamp()
  ProcedureReturn FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
EndProcedure

Procedure LogLine(msg.s)
  Protected f.i
  If FileSize(LogPath) >= 0
    f = OpenFile(#PB_Any, LogPath)
    If f
      FileSeek(f, Lof(f))
    EndIf
  Else
    f = CreateFile(#PB_Any, LogPath)
  EndIf

  If f
    WriteStringN(f, NowStamp() + "  " + msg)
    CloseFile(f)
  EndIf
EndProcedure

Procedure ViewLog()
  If FileSize(LogPath) < 0
    LogLine("Log created")
  EndIf
  RunProgram("notepad.exe", #DQUOTE$ + LogPath + #DQUOTE$, "", #PB_Program_Open)
EndProcedure

Procedure InitFonts()
  ; Use Windows UI fonts for a more modern look.
  FontUI = LoadFont(#PB_Any, "Segoe UI", 10)
  FontSmall = LoadFont(#PB_Any, "Segoe UI", 9)
  FontTitle = LoadFont(#PB_Any, "Segoe UI", 15, #PB_Font_Bold)
EndProcedure

; ---------- Elevation / Services (requires admin) ----------

#TOKEN_QUERY = $0008
#TokenElevation = 20

Structure OC_TOKEN_ELEVATION
  TokenIsElevated.l
EndStructure

Procedure.i IsProcessElevated()
  Protected hToken.i, elev.OC_TOKEN_ELEVATION, cb.l
  If OpenProcessToken_(GetCurrentProcess_(), #TOKEN_QUERY, @hToken) = 0
    ProcedureReturn 0
  EndIf
  cb = SizeOf(OC_TOKEN_ELEVATION)
  If GetTokenInformation_(hToken, #TokenElevation, @elev, cb, @cb) = 0
    CloseHandle_(hToken)
    ProcedureReturn 0
  EndIf
  CloseHandle_(hToken)
  ProcedureReturn elev\TokenIsElevated
EndProcedure

Procedure EnsureElevatedOrRelaunch()
  If IsProcessElevated() = 0
    LogLine("Not elevated (you may be in Administrators group, but process isn't elevated). Relaunching with UAC")
    If ShellExecute_(0, "runas", ProgramFilename(), "", GetPathPart(ProgramFilename()), #SW_SHOWNORMAL) > 32
      End
    EndIf
    LogLine("UAC relaunch failed")
    MessageRequester(#APP_NAME, "Admin rights are required (elevated process).")
    End
  EndIf
  LogLine("Running elevated")
EndProcedure

Declare SaveGames()
Declare RefreshList()

Declare ImportFolderGames()
Declare MarkSessionClean()
Declare.i SetActivePowerGuid(guid.s)
Declare.i SelectGameByIndex(idx.i, *out.GameEntry)
Declare.s PshEscapeSingle(s.s)
Declare.s GetSteamGameRootByAppId(steamExe.s, appId.i)
Declare.i LaunchBoosted(*g.GameEntry)
Declare.i LaunchSteamBoosted(*g.GameEntry)

; ---------- Helpers ----------
Procedure.s QuoteArg(s.s)
  If FindString(s, " ", 1) Or FindString(s, #DQUOTE$, 1)
    s = ReplaceString(s, #DQUOTE$, "\" + #DQUOTE$)
    ProcedureReturn #DQUOTE$ + s + #DQUOTE$
  EndIf
  ProcedureReturn s
EndProcedure

Procedure.s TrimCRLF(s.s)
  s = ReplaceString(s, #CRLF$, #LF$)
  s = ReplaceString(s, #CR$, #LF$)
  While Right(s, 1) = #LF$
    s = Left(s, Len(s) - 1)
  Wend
  ProcedureReturn s
EndProcedure

Procedure.s RunAndCapture(cmd.s)
  Protected p, out.s, line.s
  p = RunProgram("cmd.exe", "/c " + cmd, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If p
    While ProgramRunning(p)
      If AvailableProgramOutput(p)
        line = ReadProgramString(p)
        out + line + #LF$
      Else
        Delay(5)
      EndIf
    Wend
    While AvailableProgramOutput(p)
      line = ReadProgramString(p)
      out + line + #LF$
    Wend
    CloseProgram(p)
  EndIf
  ProcedureReturn TrimCRLF(out)
EndProcedure

Procedure.s EnsureTrailingSlash(p.s)
  If p = "" : ProcedureReturn "" : EndIf
  If Right(p, 1) <> "\\" And Right(p, 1) <> "/"
    p + "\\"
  EndIf
  ProcedureReturn p
EndProcedure

Procedure.s PathJoin(a.s, b.s)
  a = EnsureTrailingSlash(a)
  If Left(b, 1) = "\\" Or Left(b, 1) = "/"
    b = Mid(b, 2)
  EndIf
  ProcedureReturn a + b
EndProcedure

Procedure.s QuotedField(line.s, n.i)
  ; Returns the Nth quoted string from a line, or "".
  Protected i.i, q.i, start.i, count.i
  For i = 1 To Len(line)
    If Mid(line, i, 1) = #DQUOTE$
      If q = 0
        q = 1
        start = i + 1
      Else
        q = 0
        count + 1
        If count = n
          ProcedureReturn Mid(line, start, i - start)
        EndIf
      EndIf
    EndIf
  Next
  ProcedureReturn ""
EndProcedure

Procedure.s VdfUnescape(s.s)
  ; Minimal unescape for VDF-style strings
  s = ReplaceString(s, "\\\\", "\\")
  s = ReplaceString(s, "\\" + Chr(34), Chr(34))
  ProcedureReturn s
EndProcedure

; ---------- Registry (Steam discovery) ----------

#HKEY_CURRENT_USER  = $80000001
#HKEY_LOCAL_MACHINE = $80000002
#KEY_READ           = $20019
#REG_SZ             = 1
#REG_EXPAND_SZ      = 2

Procedure.s RegReadString(root.i, subKey.s, valueName.s)
  Protected hKey.i, type.l, cb.l
  Protected out.s

  If RegOpenKeyEx_(root, subKey, 0, #KEY_READ, @hKey)
    ProcedureReturn ""
  EndIf

  If RegQueryValueEx_(hKey, valueName, 0, @type, 0, @cb)
    RegCloseKey_(hKey)
    ProcedureReturn ""
  EndIf
  If (type <> #REG_SZ And type <> #REG_EXPAND_SZ) Or cb <= 2
    RegCloseKey_(hKey)
    ProcedureReturn ""
  EndIf

  out = Space((cb / SizeOf(Character)) + 2)
  If RegQueryValueEx_(hKey, valueName, 0, @type, @out, @cb) = 0
    out = PeekS(@out, -1)
  Else
    out = ""
  EndIf
  RegCloseKey_(hKey)
  ProcedureReturn out
EndProcedure

Procedure.s FindSteamExe()
  Protected p.s
  p = RegReadString(#HKEY_CURRENT_USER, "Software\\Valve\\Steam", "SteamExe")
  If p <> "" And LCase(GetExtensionPart(p)) = "exe" : ProcedureReturn p : EndIf

  p = RegReadString(#HKEY_CURRENT_USER, "Software\\Valve\\Steam", "SteamPath")
  If p <> ""
    p = EnsureTrailingSlash(p) + "Steam.exe"
    If FileSize(p) > 0 : ProcedureReturn p : EndIf
  EndIf

  p = RegReadString(#HKEY_LOCAL_MACHINE, "SOFTWARE\\WOW6432Node\\Valve\\Steam", "InstallPath")
  If p <> ""
    p = EnsureTrailingSlash(p) + "Steam.exe"
    If FileSize(p) > 0 : ProcedureReturn p : EndIf
  EndIf

  p = RegReadString(#HKEY_LOCAL_MACHINE, "SOFTWARE\\Valve\\Steam", "InstallPath")
  If p <> ""
    p = EnsureTrailingSlash(p) + "Steam.exe"
    If FileSize(p) > 0 : ProcedureReturn p : EndIf
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure AddUniqueString(List L.s(), s.s)
  If s = "" : ProcedureReturn : EndIf
  ForEach L()
    If LCase(L()) = LCase(s)
      ProcedureReturn
    EndIf
  Next
  AddElement(L())
  L() = s
EndProcedure

Procedure GetSteamLibraries(steamRoot.s, List libs.s())
  ClearList(libs())
  steamRoot = EnsureTrailingSlash(steamRoot)
  AddUniqueString(libs(), steamRoot)

  Protected vdf.s = PathJoin(steamRoot, "steamapps\\libraryfolders.vdf")
  If FileSize(vdf) <= 0 : ProcedureReturn : EndIf

  Protected line.s, k.s, v.s
  If ReadFile(0, vdf)
    While Eof(0) = 0
      line = ReadString(0)
      k = QuotedField(line, 1)
      v = VdfUnescape(QuotedField(line, 2))
      If v <> ""
        If LCase(k) = "path"
          AddUniqueString(libs(), EnsureTrailingSlash(v))
        ElseIf Val(k) > 0 Or k = "0"
          If FindString(v, ":\\", 1) Or Left(v, 2) = "\\\\"
            AddUniqueString(libs(), EnsureTrailingSlash(v))
          EndIf
        EndIf
      EndIf
    Wend
    CloseFile(0)
  EndIf
EndProcedure

Procedure.s ReadAcfField(acfPath.s, keyWanted.s)
  Protected line.s, k.s, v.s
  If ReadFile(0, acfPath)
    While Eof(0) = 0
      line = ReadString(0)
      k = QuotedField(line, 1)
      If LCase(k) = LCase(keyWanted)
        v = QuotedField(line, 2)
        CloseFile(0)
        ProcedureReturn v
      EndIf
    Wend
    CloseFile(0)
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure.i GamesHasSteamApp(appId.i)
  If appId <= 0 : ProcedureReturn 0 : EndIf
  ForEach Games()
    If Games()\LaunchMode = 1 And Games()\SteamAppId = appId
      ProcedureReturn 1
    EndIf
  Next
  ProcedureReturn 0
EndProcedure

Procedure.s GetSteamGameRootByAppId(steamExe.s, appId.i)
  ; Returns install folder prefix (steamapps\common\<installdir>\) for an AppID.
  ; Uses Steam's own library metadata, so the user doesn't need to edit paths.
  Protected steamRoot.s, steamapps.s, acf.s, installdir.s
  Protected NewList libs.s()
  Protected lib.s, commonRoot.s

  If appId <= 0 : ProcedureReturn "" : EndIf
  If steamExe = "" Or FileSize(steamExe) <= 0
    steamExe = FindSteamExe()
  EndIf
  If steamExe = "" Or FileSize(steamExe) <= 0 : ProcedureReturn "" : EndIf

  steamRoot = EnsureTrailingSlash(GetPathPart(steamExe))
  GetSteamLibraries(steamRoot, libs())
  If ListSize(libs()) = 0 : ProcedureReturn "" : EndIf

  ForEach libs()
    lib = EnsureTrailingSlash(libs())
    steamapps = PathJoin(lib, "steamapps\\")
    If FileSize(steamapps) <> -2
      Continue
    EndIf
    acf = PathJoin(steamapps, "appmanifest_" + Str(appId) + ".acf")
    If FileSize(acf) > 0
      installdir = ReadAcfField(acf, "installdir")
      If installdir <> ""
        commonRoot = PathJoin(lib, "steamapps\\common\\")
        ProcedureReturn EnsureTrailingSlash(PathJoin(commonRoot, installdir))
      EndIf
    EndIf
  Next

  ProcedureReturn ""
EndProcedure

Procedure ImportSteamGames()
  Protected steamExe.s = FindSteamExe()
  If steamExe = ""
    MessageRequester(#APP_NAME, "Steam not found (registry).")
    ProcedureReturn
  EndIf
  LogLine("Import Steam requested")

  Protected steamRoot.s = EnsureTrailingSlash(GetPathPart(steamExe))
  Protected NewList libs.s()
  GetSteamLibraries(steamRoot, libs())

  Protected lib.s, steamapps.s, file.s, appId.i, name.s, installdir.s
  Protected commonRoot.s
  Protected added.i
  ForEach libs()
    lib = EnsureTrailingSlash(libs())
    steamapps = PathJoin(lib, "steamapps\\")
    If FileSize(steamapps) <> -2
      Continue
    EndIf

    If ExamineDirectory(1, steamapps, "appmanifest_*.acf")
      While NextDirectoryEntry(1)
        If DirectoryEntryType(1) = #PB_DirectoryEntry_File
          file = DirectoryEntryName(1)
          appId = Val(ReplaceString(ReplaceString(file, "appmanifest_", ""), ".acf", ""))
          If appId > 0 And GamesHasSteamApp(appId) = 0
            name = ReadAcfField(PathJoin(steamapps, file), "name")
            installdir = ReadAcfField(PathJoin(steamapps, file), "installdir")
            If name <> "" And installdir <> ""
              AddElement(Games())
              Games()\Name = name
              Games()\ExePath = ""
              Games()\Args = ""
              Games()\WorkDir = ""
              Games()\Priority = #ABOVE_NORMAL_PRIORITY_CLASS
              Games()\Affinity = 0
              Games()\Services = ""
              Games()\LaunchMode = 1
              Games()\SteamAppId = appId
              Games()\SteamExe = steamExe
              Games()\SteamClientArgs = ""
              Games()\SteamGameArgs = ""
              Games()\SteamDetectTimeoutMs = 60000
              commonRoot = PathJoin(lib, "steamapps\\common\\")
              Games()\GameRoot = EnsureTrailingSlash(PathJoin(commonRoot, installdir))
              Games()\PowerGuid = ""
              added + 1
            EndIf
          EndIf
        EndIf
      Wend
      FinishDirectory(1)
    EndIf
  Next

  SaveGames()
  RefreshList()
  MessageRequester(#APP_NAME, "Imported " + Str(added) + " Steam game(s).")
  LogLine("Imported Steam games: " + Str(added))
EndProcedure

Procedure.s RunPowerShellAndCapture(ps.s)
  Protected p, out.s, line.s
  p = RunProgram("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -Command " + #DQUOTE$ + ps + #DQUOTE$, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If p
    While ProgramRunning(p)
      If AvailableProgramOutput(p)
        line = ReadProgramString(p)
        out + line + #LF$
      Else
        Delay(5)
      EndIf
    Wend
    While AvailableProgramOutput(p)
      line = ReadProgramString(p)
      out + line + #LF$
    Wend
    CloseProgram(p)
  EndIf
  ProcedureReturn TrimCRLF(out)
EndProcedure

Procedure.s StopServicesCsvAndLog(csv.s, context.s)
  ; Returns '|' delimited list of services that we actually stopped.
  Protected out.s, line.s
  Protected sep.s = Chr(31)
  Protected i.i, n.i
  Protected name.s, action.s, result.s, before.s, after.s
  Protected stoppedPipe.s
  Protected ps.s

  csv = Trim(csv)
  If csv = "" : ProcedureReturn "" : EndIf

  ps = "$sep=[char]31;"
  ps + "$names='" + PshEscapeSingle(csv) + "'.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ };"
  ps + "foreach($n in $names){"
  ps + "  $before='';$after='';$result='';"
  ps + "  try{"
  ps + "    $svc=Get-Service -Name $n -ErrorAction Stop;"
  ps + "    $before=$svc.Status.ToString();"
  ps + "    if($svc.Status -ne 'Stopped'){"
  ps + "      Stop-Service -Name $n -Force -ErrorAction Stop;"
  ps + "      Start-Sleep -Milliseconds 200;"
  ps + "      $after=(Get-Service -Name $n -ErrorAction SilentlyContinue).Status.ToString();"
  ps + "      $result='OK';"
  ps + "    } else { $after=$before; $result='AlreadyStopped' }"
  ps + "  } catch { $msg=$_.Exception.Message -replace '[\r\n\t]',' '; $result='Error:'+$msg }"
  ps + "  $n+$sep+'Stop'+$sep+$result+$sep+$before+$sep+$after"
  ps + "}"
  out = RunPowerShellAndCapture(ps)

  n = CountString(out, #LF$) + 1
  For i = 1 To n
    line = StringField(out, i, #LF$)
    If line = "" : Continue : EndIf
    name   = Trim(StringField(line, 1, sep))
    action = Trim(StringField(line, 2, sep))
    result = Trim(StringField(line, 3, sep))
    before = Trim(StringField(line, 4, sep))
    after  = Trim(StringField(line, 5, sep))

    If name <> ""
      If context <> ""
        LogLine("[" + context + "] " + action + " " + name + " before=" + before + " after=" + after + " result=" + result)
      Else
        LogLine(action + " " + name + " before=" + before + " after=" + after + " result=" + result)
      EndIf
    EndIf

    If LCase(action) = "stop" And LCase(result) = "ok" And LCase(after) = "stopped"
      If stoppedPipe <> "" : stoppedPipe + "|" : EndIf
      stoppedPipe + name
    EndIf
  Next

  ProcedureReturn stoppedPipe
EndProcedure

Procedure StartServicesCsvAndLog(csv.s, context.s)
  Protected out.s, line.s
  Protected sep.s = Chr(31)
  Protected i.i, n.i
  Protected name.s, action.s, result.s, before.s, after.s
  Protected ps.s

  csv = Trim(csv)
  If csv = "" : ProcedureReturn : EndIf

  ps = "$sep=[char]31;"
  ps + "$names='" + PshEscapeSingle(csv) + "'.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ };"
  ps + "foreach($n in $names){"
  ps + "  $before='';$after='';$result='';"
  ps + "  try{"
  ps + "    $svc=Get-Service -Name $n -ErrorAction Stop;"
  ps + "    $before=$svc.Status.ToString();"
  ps + "    if($svc.Status -ne 'Running'){"
  ps + "      Start-Service -Name $n -ErrorAction Stop;"
  ps + "      Start-Sleep -Milliseconds 200;"
  ps + "      $after=(Get-Service -Name $n -ErrorAction SilentlyContinue).Status.ToString();"
  ps + "      $result='OK';"
  ps + "    } else { $after=$before; $result='AlreadyRunning' }"
  ps + "  } catch { $msg=$_.Exception.Message -replace '[\r\n\t]',' '; $result='Error:'+$msg }"
  ps + "  $n+$sep+'Start'+$sep+$result+$sep+$before+$sep+$after"
  ps + "}"
  out = RunPowerShellAndCapture(ps)

  n = CountString(out, #LF$) + 1
  For i = 1 To n
    line = StringField(out, i, #LF$)
    If line = "" : Continue : EndIf
    name   = Trim(StringField(line, 1, sep))
    action = Trim(StringField(line, 2, sep))
    result = Trim(StringField(line, 3, sep))
    before = Trim(StringField(line, 4, sep))
    after  = Trim(StringField(line, 5, sep))
    If name <> ""
      If context <> ""
        LogLine("[" + context + "] " + action + " " + name + " before=" + before + " after=" + after + " result=" + result)
      Else
        LogLine(action + " " + name + " before=" + before + " after=" + after + " result=" + result)
      EndIf
    EndIf
  Next
EndProcedure

Procedure.s PshEscapeSingle(s.s)
  ProcedureReturn ReplaceString(s, "'", "''")
EndProcedure

Procedure RestartServicesPipeList(stoppedServices.s)
  ; stoppedServices is '|' delimited, as returned by stop routine
  If stoppedServices = "" : ProcedureReturn : EndIf
  LogLine("Restarting services: " + stoppedServices)
  RunPowerShellAndCapture("$s='" + PshEscapeSingle(stoppedServices) + "'.Split('|') ; foreach($n in $s){ if($n){ try{ Start-Service -Name $n -ErrorAction SilentlyContinue } catch{} } }")
EndProcedure

Procedure RestartServicesPipeListAndLog(stoppedServices.s, context.s)
  ; stoppedServices is '|' delimited.
  If stoppedServices = "" : ProcedureReturn : EndIf
  Protected csv.s = ReplaceString(stoppedServices, "|", ",")
  If context <> ""
    LogLine("[" + context + "] Restarting services: " + stoppedServices)
  Else
    LogLine("Restarting services: " + stoppedServices)
  EndIf
  StartServicesCsvAndLog(csv, context)
EndProcedure

Procedure CleanupAfterLaunch(prevPowerGuid.s, didSwitchPower.i, stoppedServices.s)
  ; Best-effort cleanup for both success and failure paths.
  Protected restoredPower.i
  If stoppedServices <> ""
    RestartServicesPipeListAndLog(stoppedServices, "cleanup")
  EndIf
  If didSwitchPower And prevPowerGuid <> ""
    SetActivePowerGuid(prevPowerGuid)
    restoredPower = 1
    LogLine("Power plan restored: " + prevPowerGuid)
  EndIf
  ; Only mark clean if we actually restored what we changed.
  If (stoppedServices <> "") Or restoredPower
    MarkSessionClean()
  EndIf
EndProcedure

; ---------- Service picker / Editing ----------

Structure ServiceInfo
  Name.s
  DisplayName.s
  Status.s
  StartType.s
EndStructure

Procedure GetAllServices(List out.ServiceInfo())
  ClearList(out())
  Protected raw.s, line.s, n.i
  Protected sep.s = Chr(31)
  raw = RunPowerShellAndCapture("Get-Service | ForEach-Object { $_.Name + [char]31 + $_.DisplayName + [char]31 + $_.Status + [char]31 + $_.StartType }")
  If raw = "" : ProcedureReturn : EndIf
  n = CountString(raw, #LF$) + 1

  Protected i.i
  Protected si.ServiceInfo
  For i = 1 To n
    line = StringField(raw, i, #LF$)
    If line = "" : Continue : EndIf
    si\Name        = StringField(line, 1, sep)
    si\DisplayName = StringField(line, 2, sep)
    si\Status      = StringField(line, 3, sep)
    si\StartType   = StringField(line, 4, sep)
    If si\Name <> ""
      AddElement(out())
      out() = si
    EndIf
  Next
EndProcedure

Procedure.i ServicesContains(currentCsv.s, svcName.s)
  ; case-insensitive match against comma-separated list
  Protected i.i, n.i, item.s
  svcName = LCase(Trim(svcName))
  If svcName = "" : ProcedureReturn 0 : EndIf
  n = CountString(currentCsv, ",") + 1
  For i = 1 To n
    item = LCase(Trim(StringField(currentCsv, i, ",")))
    If item = svcName : ProcedureReturn 1 : EndIf
  Next
  ProcedureReturn 0
EndProcedure

Procedure FillServiceList(listGadget.i, showAll.i, Map selected.i(), List all.ServiceInfo(), List recommended.s(), Map byName.ServiceInfo())
  ClearGadgetItems(listGadget)
  Protected sel.s, key.s
  Protected si.ServiceInfo

  If showAll
    ForEach all()
      sel = ""
      If FindMapElement(selected(), LCase(all()\Name)) And selected() : sel = "X" : EndIf
      AddGadgetItem(listGadget, -1, sel + Chr(10) + all()\Name + Chr(10) + all()\DisplayName + Chr(10) + all()\Status + Chr(10) + all()\StartType)
    Next
  Else
    ForEach recommended()
      key = LCase(recommended())
      If FindMapElement(byName(), key)
        si = byName()
        sel = ""
        If FindMapElement(selected(), LCase(si\Name)) And selected() : sel = "X" : EndIf
        AddGadgetItem(listGadget, -1, sel + Chr(10) + si\Name + Chr(10) + si\DisplayName + Chr(10) + si\Status + Chr(10) + si\StartType)
      EndIf
    Next
  EndIf
EndProcedure

Procedure ToggleSelectedRows(listGadget.i, Map selected.i(), Map selectedName.s())
  Protected r.i, nameOrig.s, nameKey.s
  For r = 0 To CountGadgetItems(listGadget) - 1
    If GetGadgetItemState(listGadget, r) & #PB_ListIcon_Selected
      nameOrig = Trim(GetGadgetItemText(listGadget, r, 1))
      nameKey = LCase(nameOrig)
      If nameKey <> ""
        If FindMapElement(selected(), nameKey) And selected()
          selected() = 0
          SetGadgetItemText(listGadget, r, "", 0)
        Else
          selected(nameKey) = 1
          selectedName(nameKey) = nameOrig
          SetGadgetItemText(listGadget, r, "X", 0)
        EndIf
      EndIf
    EndIf
  Next
EndProcedure

Procedure ClearAllSelected(listGadget.i, Map selected.i(), Map selectedName.s())
  ClearMap(selected())
  ClearMap(selectedName())
  Protected r.i
  For r = 0 To CountGadgetItems(listGadget) - 1
    SetGadgetItemText(listGadget, r, "", 0)
  Next
EndProcedure

Procedure SelectAllShown(listGadget.i, Map selected.i(), Map selectedName.s())
  Protected r.i, nameOrig.s, nameKey.s
  For r = 0 To CountGadgetItems(listGadget) - 1
    nameOrig = Trim(GetGadgetItemText(listGadget, r, 1))
    nameKey = LCase(nameOrig)
    If nameKey <> ""
      selected(nameKey) = 1
      selectedName(nameKey) = nameOrig
      SetGadgetItemText(listGadget, r, "X", 0)
    EndIf
  Next
EndProcedure

Procedure.s SelectedNamesCsv(listGadget.i)
  Protected r.i, nameOrig.s, csv.s
  For r = 0 To CountGadgetItems(listGadget) - 1
    If GetGadgetItemState(listGadget, r) & #PB_ListIcon_Selected
      nameOrig = Trim(GetGadgetItemText(listGadget, r, 1))
      If nameOrig <> ""
        If csv <> "" : csv + "," : EndIf
        csv + nameOrig
      EndIf
    EndIf
  Next
  ProcedureReturn csv
EndProcedure

Procedure StopServicesNow(csv.s)
  csv = Trim(csv)
  If csv = "" : ProcedureReturn : EndIf
  LogLine("Stop now (picker): " + csv)
  RunPowerShellAndCapture("$names='" + PshEscapeSingle(csv) + "'.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ } ; foreach($n in $names){ try{ Stop-Service -Name $n -Force -ErrorAction SilentlyContinue } catch{} }")
EndProcedure

Procedure StartServicesNow(csv.s)
  csv = Trim(csv)
  If csv = "" : ProcedureReturn : EndIf
  LogLine("Start now (picker): " + csv)
  RunPowerShellAndCapture("$names='" + PshEscapeSingle(csv) + "'.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ } ; foreach($n in $names){ try{ Start-Service -Name $n -ErrorAction SilentlyContinue } catch{} }")
EndProcedure

Procedure RefreshServicesData(listGadget.i, showAllGadget.i, Map selected.i(), List all.ServiceInfo(), List recommended.s(), Map byName.ServiceInfo())
  ; refresh status/start type after manual Start/Stop
  GetAllServices(all())
  ClearMap(byName())
  ForEach all()
    byName(LCase(all()\Name)) = all()
  Next
  FillServiceList(listGadget, GetGadgetState(showAllGadget), selected(), all(), recommended(), byName())
EndProcedure

Procedure.s ServicesPickDialog(initialCsv.s, *autoRun.Integer)
  Enumeration _SvcWindows 1000
    #W_Svc
  EndEnumeration
  Enumeration _SvcGadgets 2000
    #S_List
    #S_BtnOk
    #S_BtnCancel
    #S_ShowAll
    #S_AutoRun
  EndEnumeration

  Protected NewList recommended.s()
  ; Recommended (commonly stoppable) services. Not guaranteed safe everywhere.
  AddElement(recommended()) : recommended() = "Spooler"        ; Print Spooler
  AddElement(recommended()) : recommended() = "WSearch"        ; Windows Search
  AddElement(recommended()) : recommended() = "SysMain"        ; SysMain/Superfetch
  AddElement(recommended()) : recommended() = "WerSvc"         ; Error Reporting
  AddElement(recommended()) : recommended() = "DiagTrack"      ; Telemetry
  AddElement(recommended()) : recommended() = "TrkWks"         ; Link Tracking
  AddElement(recommended()) : recommended() = "MapsBroker"     ; Downloaded Maps
  AddElement(recommended()) : recommended() = "Fax"            ; Fax
  AddElement(recommended()) : recommended() = "WMPNetworkSvc"  ; WMP Sharing
  AddElement(recommended()) : recommended() = "XblAuthManager" ; Xbox Live Auth
  AddElement(recommended()) : recommended() = "XblGameSave"    ; Xbox Live Save
  AddElement(recommended()) : recommended() = "XboxGipSvc"     ; Xbox Accessories

  Protected NewList all.ServiceInfo()
  GetAllServices(all())
  Protected NewMap byName.ServiceInfo()
  ForEach all()
    byName(LCase(all()\Name)) = all()
  Next

  ; Track selection state separately so it survives switching views.
  Protected NewMap selected.i()
  Protected NewMap selectedName.s()
  Protected i.i, n.i, item.s
  n = CountString(initialCsv, ",") + 1
  For i = 1 To n
    item = LCase(Trim(StringField(initialCsv, i, ",")))
    If item <> ""
      selected(item) = 1
      selectedName(item) = Trim(StringField(initialCsv, i, ","))
    EndIf
  Next

  ; Context menu
  Enumeration 3000
    #M_Svc
  EndEnumeration
  Enumeration 3100
    #MI_Toggle
    #MI_SelectAll
    #MI_ClearAll
    #MI_StopNow
    #MI_StartNow
    #MI_OpenServices
  EndEnumeration

  If OpenWindow(#W_Svc, 0, 0, 860, 520, "Pick Services (temporary)", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    TextGadget(#PB_Any, 10, 10, 840, 35, "Select services to stop while the game runs. Only choose what you understand; stopping a service can break features.")
    CheckBoxGadget(#S_ShowAll, 10, 45, 240, 22, "Show all services")
    ListIconGadget(#S_List, 10, 75, 840, 380, "Sel", 40, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines | #PB_ListIcon_MultiSelect)
    AddGadgetColumn(#S_List, 1, "Service", 170)
    AddGadgetColumn(#S_List, 2, "Display name", 360)
    AddGadgetColumn(#S_List, 3, "Status", 90)
    AddGadgetColumn(#S_List, 4, "Start", 120)

    CheckBoxGadget(#S_AutoRun, 10, 472, 280, 22, "Auto-run game after OK")
    If *autoRun
      SetGadgetState(#S_AutoRun, Bool(*autoRun\i))
    EndIf

    ButtonGadget(#S_BtnOk, 650, 470, 90, 30, "OK")
    ButtonGadget(#S_BtnCancel, 760, 470, 90, 30, "Cancel")

    If CreatePopupMenu(#M_Svc)
      MenuItem(#MI_Toggle, "Toggle select")
      MenuBar()
      MenuItem(#MI_SelectAll, "Select all (shown)")
      MenuItem(#MI_ClearAll, "Clear all")
      MenuBar()
      MenuItem(#MI_StopNow, "Stop service now")
      MenuItem(#MI_StartNow, "Start service now")
      MenuBar()
      MenuItem(#MI_OpenServices, "Open Services (services.msc)")
    EndIf

    FillServiceList(#S_List, 0, selected(), all(), recommended(), byName())

    Protected ev.i, outCsv.s, s.s, row.i
    Repeat
      ev = WaitWindowEvent()
      Select ev
        Case #PB_Event_Gadget
          Select EventGadget()
            Case #S_ShowAll
              FillServiceList(#S_List, GetGadgetState(#S_ShowAll), selected(), all(), recommended(), byName())

            Case #S_List
              If EventType() = #PB_EventType_LeftDoubleClick
                ToggleSelectedRows(#S_List, selected(), selectedName())
              ElseIf EventType() = #PB_EventType_RightClick
                If GetGadgetState(#S_List) >= 0
                  DisplayPopupMenu(#M_Svc, WindowID(#W_Svc))
                EndIf
              EndIf

            Case #S_BtnOk
              outCsv = ""
              ; Serialize from selected() map
              ForEach selected()
                If selected()
                  If outCsv <> "" : outCsv + "," : EndIf
                  If FindMapElement(selectedName(), MapKey(selected())) And selectedName() <> ""
                    outCsv + selectedName()
                  Else
                    outCsv + MapKey(selected())
                  EndIf
                EndIf
              Next
              If *autoRun
                *autoRun\i = GetGadgetState(#S_AutoRun)
              EndIf
              CloseWindow(#W_Svc)
              ProcedureReturn outCsv

            Case #S_BtnCancel
              If *autoRun
                *autoRun\i = 0
              EndIf
              CloseWindow(#W_Svc)
              ProcedureReturn initialCsv
          EndSelect

        Case #PB_Event_CloseWindow
          If *autoRun
            *autoRun\i = 0
          EndIf
          CloseWindow(#W_Svc)
          ProcedureReturn initialCsv

        Case #PB_Event_Menu
          Select EventMenu()
            Case #MI_Toggle
              ToggleSelectedRows(#S_List, selected(), selectedName())

            Case #MI_SelectAll
              SelectAllShown(#S_List, selected(), selectedName())

            Case #MI_ClearAll
              ClearAllSelected(#S_List, selected(), selectedName())

            Case #MI_StopNow
              StopServicesNow(SelectedNamesCsv(#S_List))
              RefreshServicesData(#S_List, #S_ShowAll, selected(), all(), recommended(), byName())

            Case #MI_StartNow
              StartServicesNow(SelectedNamesCsv(#S_List))
              RefreshServicesData(#S_List, #S_ShowAll, selected(), all(), recommended(), byName())

            Case #MI_OpenServices
              RunProgram("services.msc", "", "", #PB_Program_Open)
          EndSelect
      EndSelect
    ForEver
  EndIf

  ProcedureReturn initialCsv
EndProcedure

Procedure.i PriorityToChoice(p.l)
  Select p
    Case 0 : ProcedureReturn 0
    Case #NORMAL_PRIORITY_CLASS : ProcedureReturn 1
    Case #ABOVE_NORMAL_PRIORITY_CLASS : ProcedureReturn 2
    Case #HIGH_PRIORITY_CLASS : ProcedureReturn 3
  EndSelect
  ProcedureReturn 2
EndProcedure

Procedure.l ChoiceToPriority(choice.i)
  Select choice
    Case 0 : ProcedureReturn 0
    Case 1 : ProcedureReturn #NORMAL_PRIORITY_CLASS
    Case 3 : ProcedureReturn #HIGH_PRIORITY_CLASS
  EndSelect
  ProcedureReturn #ABOVE_NORMAL_PRIORITY_CLASS
EndProcedure

Procedure.i EditGameByIndex(idx.i, listGadget.i)
  Protected cur.GameEntry
  If SelectGameByIndex(idx, @cur) = 0 : ProcedureReturn 0 : EndIf
  Protected autoRun.i

  Protected newName.s = InputRequester(#APP_NAME, "Game name:", cur\Name)
  If newName = "" : ProcedureReturn 0 : EndIf
  cur\Name = newName

  If cur\LaunchMode = 0
    cur\Args = InputRequester(#APP_NAME, "Launch arguments (optional):", cur\Args)
  Else
    cur\SteamGameArgs = InputRequester(#APP_NAME, "Game launch arguments (Steam - optional):", cur\SteamGameArgs)
    cur\SteamClientArgs = InputRequester(#APP_NAME, "Steam client arguments (optional):", cur\SteamClientArgs)
    ; GameRoot is auto-resolved from Steam libraries.
    cur\SteamDetectTimeoutMs = Val(InputRequester(#APP_NAME, "Steam game detect timeout (ms):", Str(cur\SteamDetectTimeoutMs)))
    If cur\SteamDetectTimeoutMs < 5000 : cur\SteamDetectTimeoutMs = 60000 : EndIf
    If cur\SteamDetectTimeoutMs > 300000 : cur\SteamDetectTimeoutMs = 300000 : EndIf
  EndIf

  Protected pChoice.i = PriorityToChoice(cur\Priority)
  pChoice = Val(InputRequester(#APP_NAME, "Priority (0=Don't change, 1=Normal, 2=Above normal, 3=High):", Str(pChoice)))
  If pChoice < 0 : pChoice = 0 : EndIf
  If pChoice > 3 : pChoice = 3 : EndIf
  cur\Priority = ChoiceToPriority(pChoice)

  cur\Services = ServicesPickDialog(cur\Services, @autoRun)

  Protected i.i = 0
  ForEach Games()
    If i = idx
      Games() = cur
      SaveGames()
      RefreshList()
      ; RefreshList() clears selection; restore the edited row.
      If idx >= 0 And idx < CountGadgetItems(listGadget)
        SetGadgetState(listGadget, idx)
        SetGadgetItemState(listGadget, idx, #PB_ListIcon_Selected)
        SetActiveGadget(listGadget)
      EndIf
      LogLine("Edited game: " + cur\Name)
      If autoRun
        LogLine("Auto-run after edit: " + cur\Name)
        If cur\LaunchMode = 1
          LaunchSteamBoosted(@cur)
        Else
          LaunchBoosted(@cur)
        EndIf
      EndIf
      ProcedureReturn 1
    EndIf
    i + 1
  Next
  ProcedureReturn 0
EndProcedure

Procedure.s CollapseBackslashes(p.s)
  ; UI/storage helper: reduce accidental repeated backslashes
  While FindString(p, "\\\\", 1)
    p = ReplaceString(p, "\\\\", "\\")
  Wend
  ProcedureReturn p
EndProcedure

; ---------- Manual add / Folder import (EXE scan) ----------

Procedure AddExeEntry(exePath.s)
  Protected ge.GameEntry
  If exePath = "" : ProcedureReturn : EndIf
  If FileSize(exePath) <= 0 : ProcedureReturn : EndIf

  ; Dedupe: don't add same EXE twice (case-insensitive)
  ForEach Games()
    If Games()\LaunchMode = 0 And Games()\ExePath <> ""
      If LCase(Games()\ExePath) = LCase(exePath)
        ProcedureReturn
      EndIf
    EndIf
  Next

  ge\Name = GetFilePart(exePath, #PB_FileSystem_NoExtension)
  ge\Name = ReplaceString(ge\Name, "_", " ")
  ge\ExePath = exePath
  ge\Args = ""
  ge\WorkDir = GetPathPart(exePath)
  ge\Priority = #ABOVE_NORMAL_PRIORITY_CLASS
  ge\Affinity = 0
  ge\Services = ""
  ge\LaunchMode = 0
  ge\SteamAppId = 0
  ge\SteamExe = ""
  ge\SteamClientArgs = ""
  ge\SteamGameArgs = ""
  ge\SteamDetectTimeoutMs = 60000
  ge\GameRoot = ""
  ge\PowerGuid = ""

  AddElement(Games())
  Games() = ge
EndProcedure

Procedure.s NormalizeName(s.s)
  s = LCase(s)
  s = ReplaceString(s, " ", "")
  s = ReplaceString(s, "_", "")
  s = ReplaceString(s, "-", "")
  ProcedureReturn s
EndProcedure

Procedure.s TopFolderKey(baseFolder.s, fullExePath.s)
  Protected base.s = EnsureTrailingSlash(baseFolder)
  Protected rel.s, p.i
  If LCase(Left(fullExePath, Len(base))) <> LCase(base)
    ProcedureReturn "__" + LCase(GetFilePart(fullExePath))
  EndIf
  rel = Mid(fullExePath, Len(base) + 1)
  p = FindString(rel, "\\", 1)
  If p > 0
    ProcedureReturn Left(rel, p - 1)
  EndIf
  ; EXE directly under selected folder: keep unique
  ProcedureReturn "__root__" + LCase(fullExePath)
EndProcedure

Procedure.q ScoreExeCandidate(baseFolder.s, fullExePath.s)
  Protected size.q = FileSize(fullExePath)
  Protected score.q = size
  Protected file.s = LCase(GetFilePart(fullExePath))
  Protected baseName.s = GetFilePart(fullExePath, #PB_FileSystem_NoExtension)
  Protected key.s = TopFolderKey(baseFolder, fullExePath)

  ; Prefer big executables, but penalize common non-game binaries
  If FindString(file, "launcher", 1) : score / 3 : EndIf
  If FindString(file, "crash", 1)    : score / 4 : EndIf
  If FindString(file, "report", 1)   : score / 4 : EndIf
  If FindString(file, "updater", 1)  : score / 4 : EndIf
  If FindString(file, "helper", 1)   : score / 4 : EndIf
  If FindString(file, "server", 1)   : score / 6 : EndIf
  If FindString(file, "editor", 1)   : score / 6 : EndIf
  If FindString(file, "dedicated", 1): score / 6 : EndIf

  ; Bonus if EXE name matches top-level folder
  If Left(key, 8) <> "__root__"
    If NormalizeName(baseName) = NormalizeName(key)
      score + (size / 2)
    EndIf
  EndIf

  ; Slightly prefer shallower paths
  Protected base.s = EnsureTrailingSlash(baseFolder)
  Protected relDir.s = ""
  If LCase(Left(GetPathPart(fullExePath), Len(base))) = LCase(base)
    relDir = Mid(GetPathPart(fullExePath), Len(base) + 1)
  EndIf
  Protected depth.i = CountString(relDir, "\\")
  score - (depth * 10 * 1024 * 1024)
  If score < 0 : score = 0 : EndIf

  ProcedureReturn score
EndProcedure

Procedure.i ShouldSkipExe(fileName.s)
  Protected f.s = LCase(fileName)
  If Left(f, 5) = "unins" : ProcedureReturn 1 : EndIf
  If Left(f, 5) = "setup" : ProcedureReturn 1 : EndIf
  If f = "dxsetup.exe" : ProcedureReturn 1 : EndIf
  If f = "uninstall.exe" : ProcedureReturn 1 : EndIf
  If f = "steam.exe" : ProcedureReturn 1 : EndIf
  If f = "steamcmd.exe" : ProcedureReturn 1 : EndIf
  If f = "steamservice.exe" : ProcedureReturn 1 : EndIf
  If f = "steamwebhelper.exe" : ProcedureReturn 1 : EndIf
  If f = "gameoverlayui.exe" : ProcedureReturn 1 : EndIf
  If f = "steamerrorreporter.exe" : ProcedureReturn 1 : EndIf
  If FindString(f, "vcredist", 1) : ProcedureReturn 1 : EndIf
  If FindString(f, "vc_redist", 1) : ProcedureReturn 1 : EndIf
  If FindString(f, "dotnet", 1) : ProcedureReturn 1 : EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i ShouldSkipExePath(fullPath.s, fileName.s)
  Protected p.s = LCase(fullPath)
  If ShouldSkipExe(fileName) : ProcedureReturn 1 : EndIf

  ; Common non-game bins / redists inside game folders
  If FindString(p, "\\_commonredist\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\commonredist\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\redist\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\directx\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\dotnet\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\vcredist\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\vc_redist\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\installers\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\installer\\", 1) : ProcedureReturn 1 : EndIf

  ; Anti-cheat installers
  If FindString(p, "\\easyanticheat\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\battleye\\", 1) : ProcedureReturn 1 : EndIf
  If FindString(p, "\\punkbuster\\", 1) : ProcedureReturn 1 : EndIf

  ProcedureReturn 0
EndProcedure

Procedure.i ShouldSkipDir(dirName.s)
  Protected d.s = LCase(dirName)
  ; Keep folder scans usable when Steam is co-located.
  If d = "steamapps" : ProcedureReturn 1 : EndIf
  If d = "userdata"  : ProcedureReturn 1 : EndIf
  If d = "appcache"  : ProcedureReturn 1 : EndIf
  If d = "config"    : ProcedureReturn 1 : EndIf
  If d = "dumps"     : ProcedureReturn 1 : EndIf
  If d = "logs"      : ProcedureReturn 1 : EndIf
  If d = "package"   : ProcedureReturn 1 : EndIf
  If d = "depotcache": ProcedureReturn 1 : EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i DirHasAnyFile(dir.s, pattern.s)
  If ExamineDirectory(10, dir, pattern)
    While NextDirectoryEntry(10)
      If DirectoryEntryType(10) = #PB_DirectoryEntry_File
        FinishDirectory(10)
        ProcedureReturn 1
      EndIf
    Wend
    FinishDirectory(10)
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i LooksLikeSteamFolder(folder.s)
  Protected steamapps.s
  folder = EnsureTrailingSlash(folder)

  ; Steam install
  If FileSize(folder + "steam.exe") > 0
    ProcedureReturn 1
  EndIf

  ; Steam library/root
  steamapps = folder + "steamapps\\"
  If FileSize(steamapps) = -2
    If FileSize(steamapps + "libraryfolders.vdf") > 0 : ProcedureReturn 1 : EndIf
    If DirHasAnyFile(steamapps, "appmanifest_*.acf") : ProcedureReturn 1 : EndIf
  EndIf

  ProcedureReturn 0
EndProcedure

Procedure ScanExeRecursive(dir.s, depth.i, List out.s(), dirId.i)
  Protected full.s, name.s
  If depth < 0 : ProcedureReturn : EndIf
  dir = EnsureTrailingSlash(dir)
  If ExamineDirectory(dirId, dir, "*")
    While NextDirectoryEntry(dirId)
      name = DirectoryEntryName(dirId)
      If name = "." Or name = ".." : Continue : EndIf
      full = dir + name
      If DirectoryEntryType(dirId) = #PB_DirectoryEntry_Directory
        ; Skip noisy Steam install/library folders when co-located
        If ShouldSkipDir(name) = 0 And LooksLikeSteamFolder(full) = 0
          ScanExeRecursive(full, depth - 1, out(), dirId + 1)
        EndIf
      ElseIf DirectoryEntryType(dirId) = #PB_DirectoryEntry_File
        If LCase(GetExtensionPart(name)) = "exe"
          If ShouldSkipExePath(full, name) = 0
            AddElement(out())
            out() = full
          EndIf
        EndIf
      EndIf
    Wend
    FinishDirectory(dirId)
  EndIf
EndProcedure

Procedure ImportFolderGames()
  Protected folder.s = PathRequester("Select folder to scan", "")
  If folder = "" : ProcedureReturn : EndIf

  LogLine("Folder import requested: " + CollapseBackslashes(folder))

  Protected looksSteam.i = LooksLikeSteamFolder(folder)

  Protected NewList exes.s()
  ; Depth 3 catches most common layouts without going too broad.
  ScanExeRecursive(folder, 3, exes(), 2)

  Structure BestPick
    score.q
    path.s
  EndStructure
  Protected NewMap best.BestPick()
  Protected key.s, s.q
  ForEach exes()
    key = TopFolderKey(folder, exes())
    s = ScoreExeCandidate(folder, exes())
    If FindMapElement(best(), key) = 0
      best(key)\score = s
      best(key)\path = exes()
    ElseIf s > best()\score
      best()\score = s
      best()\path = exes()
    EndIf
  Next

  Protected added.i, before.i
  ForEach best()
    before = ListSize(Games())
    AddExeEntry(best()\path)
    If ListSize(Games()) > before
      added + 1
    EndIf
  Next

  If added
    SaveGames()
    RefreshList()
  EndIf
  LogLine("Folder import added=" + Str(added))
  If looksSteam
    MessageRequester(#APP_NAME, "Added " + Str(added) + " game(s) from folder." + #LF$ + #LF$ +
                         "Note: Steam install/library detected. Steam folders are skipped here; use 'Import Steam' for Steam titles.")
  Else
    MessageRequester(#APP_NAME, "Added " + Str(added) + " game(s) from folder.")
  EndIf
EndProcedure

; ---------- Process discovery (Steam-launched game) ----------

#TH32CS_SNAPPROCESS  = $00000002
#TH32CS_SNAPMODULE   = $00000008
#TH32CS_SNAPMODULE32 = $00000010

Structure OC_PROCESSENTRY32
  dwSize.l
  cntUsage.l
  th32ProcessID.l
  th32DefaultHeapID.i
  th32ModuleID.l
  cntThreads.l
  th32ParentProcessID.l
  pcPriClassBase.l
  dwFlags.l
  szExeFile.u[#MAX_PATH]
EndStructure

Structure OC_MODULEENTRY32
  dwSize.l
  th32ModuleID.l
  th32ProcessID.l
  GlblcntUsage.l
  ProccntUsage.l
  modBaseAddr.i
  modBaseSize.l
  hModule.i
  szModule.u[256]
  szExePath.u[#MAX_PATH]
EndStructure

Procedure SnapshotPids(Map pids.i())
  ClearMap(pids())
  Protected snap.i = CreateToolhelp32Snapshot_(#TH32CS_SNAPPROCESS, 0)
  Protected pe.OC_PROCESSENTRY32
  If snap = -1 : ProcedureReturn : EndIf
  pe\dwSize = SizeOf(OC_PROCESSENTRY32)
  If Process32First_(snap, @pe)
    Repeat
      pids(Str(pe\th32ProcessID)) = 1
    Until Process32Next_(snap, @pe) = 0
  EndIf
  CloseHandle_(snap)
EndProcedure

Procedure.s GetMainModulePath(pid.i)
  Protected snap.i = CreateToolhelp32Snapshot_(#TH32CS_SNAPMODULE | #TH32CS_SNAPMODULE32, pid)
  Protected me.OC_MODULEENTRY32
  Protected path.s = ""
  If snap = -1 : ProcedureReturn "" : EndIf
  me\dwSize = SizeOf(OC_MODULEENTRY32)
  If Module32First_(snap, @me)
    path = PeekS(@me\szExePath[0], -1)
  EndIf
  CloseHandle_(snap)
  ProcedureReturn path
EndProcedure

Procedure.i StartsWithNoCase(s.s, prefix.s)
  If prefix = "" : ProcedureReturn 0 : EndIf
  If Len(s) < Len(prefix) : ProcedureReturn 0 : EndIf
  If LCase(Left(s, Len(prefix))) = LCase(prefix)
    ProcedureReturn 1
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i FindNewProcessInFolder(gameRoot.s, Map baseline.i(), timeoutMs.i)
  Protected start.i = ElapsedMilliseconds()
  Protected NewMap cur.i()
  Protected key.s, pid.i, exe.s
  gameRoot = EnsureTrailingSlash(gameRoot)

  While ElapsedMilliseconds() - start < timeoutMs
    SnapshotPids(cur())
    ForEach cur()
      key = MapKey(cur())
      If FindMapElement(baseline(), key) = 0
        pid = Val(key)
        exe = GetMainModulePath(pid)
        If exe <> "" And StartsWithNoCase(exe, gameRoot)
          ProcedureReturn pid
        EndIf
      EndIf
    Next
    Delay(200)
  Wend

  ProcedureReturn 0
EndProcedure

Procedure.s GetActivePowerGuid()
  ; powercfg /getactivescheme -> "... GUID  (Name)"
  Protected out.s = RunAndCapture("powercfg /getactivescheme")
  Protected p.i = FindString(out, ":", 1)
  If p = 0 : p = FindString(out, "GUID", 1) : EndIf
  ; Extract first GUID-looking token
  Protected i, token.s, c.s
  For i = 1 To Len(out)
    c = Mid(out, i, 1)
    If (c >= "0" And c <= "9") Or (c >= "a" And c <= "f") Or (c >= "A" And c <= "F") Or c = "-"
      token + c
      If Len(token) >= 36
        ProcedureReturn Left(token, 36)
      EndIf
    Else
      token = ""
    EndIf
  Next
  ProcedureReturn ""
EndProcedure

Procedure.i SetActivePowerGuid(guid.s)
  If guid = "" : ProcedureReturn 0 : EndIf
  RunAndCapture("powercfg /setactive " + guid)
  ProcedureReturn 1
EndProcedure

Procedure.i OpenOrCreatePreferences(filePath.s)
  If OpenPreferences(filePath)
    ProcedureReturn 1
  EndIf
  If CreatePreferences(filePath)
    ProcedureReturn 1
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure SaveSession(prevPowerGuid.s, didSwitchPower.i, stoppedServices.s)
  If OpenOrCreatePreferences(SessionIni)
    PreferenceGroup("session")
    WritePreferenceInteger("didSwitchPower", didSwitchPower)
    WritePreferenceString("prevPowerGuid", prevPowerGuid)
    WritePreferenceInteger("didStopServices", Bool(stoppedServices <> ""))
    WritePreferenceString("stoppedServices", stoppedServices)
    WritePreferenceInteger("cleanExit", 0)
    ClosePreferences()
    LogLine("Session saved; powerSwitched=" + Str(didSwitchPower) + " servicesStopped=" + Str(Bool(stoppedServices <> "")))
  EndIf
EndProcedure

Procedure MarkSessionClean()
  If OpenOrCreatePreferences(SessionIni)
    PreferenceGroup("session")
    WritePreferenceInteger("cleanExit", 1)
    ClosePreferences()
    LogLine("Session marked clean")
  EndIf
EndProcedure

Procedure RestoreIfDirtySession()
  Protected didSwitchPower.i, cleanExit.i
  Protected prevPowerGuid.s
  Protected didStopServices.i
  Protected stoppedServices.s

  If FileSize(SessionIni) <= 0 : ProcedureReturn : EndIf

  If OpenPreferences(SessionIni)
    PreferenceGroup("session")
    didSwitchPower = ReadPreferenceInteger("didSwitchPower", 0)
    prevPowerGuid  = ReadPreferenceString("prevPowerGuid", "")
    didStopServices = ReadPreferenceInteger("didStopServices", 0)
    stoppedServices = ReadPreferenceString("stoppedServices", "")
    cleanExit      = ReadPreferenceInteger("cleanExit", 1)
    ClosePreferences()
  EndIf

  If cleanExit = 0
    LogLine("Dirty session detected; restoring")
    If didStopServices And stoppedServices <> ""
      ; Best-effort restart
      LogLine("Restarting services from crash: " + stoppedServices)
      RestartServicesPipeListAndLog(stoppedServices, "crash-restore")
    EndIf
    If didSwitchPower And prevPowerGuid <> ""
      LogLine("Restoring power plan: " + prevPowerGuid)
      SetActivePowerGuid(prevPowerGuid)
    EndIf
    MarkSessionClean()
  EndIf
EndProcedure

; ---------- Games persistence ----------
Procedure LoadGames()
  ClearList(Games())

  If OpenPreferences(GamesIni)
    Protected count.i, i.i, g.GameEntry
    PreferenceGroup("meta")
    count = ReadPreferenceInteger("count", 0)

    For i = 0 To count - 1
      PreferenceGroup("game_" + Str(i))
      g\Name     = ReadPreferenceString("name", "")
      g\ExePath  = ReadPreferenceString("exe", "")
      g\Args     = ReadPreferenceString("args", "")
      g\WorkDir  = ReadPreferenceString("workdir", "")
      g\Priority = ReadPreferenceInteger("priority", 0)
      g\Affinity = ReadPreferenceQuad("affinity", 0)
      g\Services = ReadPreferenceString("services", "")
      g\LaunchMode = ReadPreferenceInteger("launchMode", 0)
      g\SteamAppId  = ReadPreferenceInteger("steamAppId", 0)
      g\SteamExe    = ReadPreferenceString("steamExe", "")
      g\SteamClientArgs = ReadPreferenceString("steamClientArgs", "")
      g\SteamGameArgs   = ReadPreferenceString("steamGameArgs", "")
      g\SteamDetectTimeoutMs = ReadPreferenceInteger("steamTimeoutMs", 60000)
      ; GameRoot is resolved dynamically from Steam libraries; keep legacy field for backward compatibility.
      g\GameRoot    = ReadPreferenceString("gameRoot", "")
      g\PowerGuid   = ReadPreferenceString("powerGuid", "")
      If g\LaunchMode <> 1
        g\LaunchMode = 0
        g\SteamAppId = 0
        g\SteamExe = ""
        g\SteamClientArgs = ""
        g\SteamGameArgs = ""
        g\SteamDetectTimeoutMs = 60000
        g\GameRoot = ""
      EndIf
      If g\LaunchMode = 1
        g\GameRoot = ""
      EndIf
      If g\LaunchMode = 1
        If g\SteamDetectTimeoutMs < 5000 : g\SteamDetectTimeoutMs = 60000 : EndIf
        If g\SteamDetectTimeoutMs > 300000 : g\SteamDetectTimeoutMs = 300000 : EndIf
      EndIf
      If g\Name <> "" And g\ExePath <> ""
        AddElement(Games())
        Games() = g
      ElseIf g\Name <> "" And g\LaunchMode = 1 And g\SteamAppId > 0
        AddElement(Games())
        Games() = g
      EndIf
    Next

    ClosePreferences()
  EndIf
EndProcedure

Procedure SaveGames()
  If OpenOrCreatePreferences(GamesIni)
    LogLine("Saving games.ini; count=" + Str(ListSize(Games())))
    Protected i.i = 0
    PreferenceGroup("meta")
    WritePreferenceInteger("count", ListSize(Games()))

    ForEach Games()
      PreferenceGroup("game_" + Str(i))
      WritePreferenceString("name", Games()\Name)
      WritePreferenceString("exe", Games()\ExePath)
      WritePreferenceString("args", Games()\Args)
      WritePreferenceString("workdir", Games()\WorkDir)
      WritePreferenceInteger("priority", Games()\Priority)
      WritePreferenceQuad("affinity", Games()\Affinity)
      WritePreferenceString("services", Games()\Services)
      WritePreferenceInteger("launchMode", Games()\LaunchMode)
      WritePreferenceInteger("steamAppId", Games()\SteamAppId)
      WritePreferenceString("steamExe", Games()\SteamExe)
      WritePreferenceString("steamClientArgs", Games()\SteamClientArgs)
      WritePreferenceString("steamGameArgs", Games()\SteamGameArgs)
      WritePreferenceInteger("steamTimeoutMs", Games()\SteamDetectTimeoutMs)
      ; gameRoot kept for backward compatibility; no longer user-editable.
      WritePreferenceString("gameRoot", Games()\GameRoot)
      WritePreferenceString("powerGuid", Games()\PowerGuid)
      i + 1
    Next

    ClosePreferences()
  EndIf
EndProcedure

; ---------- Launch + boost ----------
Procedure.i LaunchBoosted(*g.GameEntry)
  Protected si.STARTUPINFO, pi.PROCESS_INFORMATION
  Protected cmd.s, workdir.s
  Protected prevPowerGuid.s, didSwitchPower.i
  Protected stoppedServices.s
  Protected origPriority.l
  Protected processAffinity.q, systemAffinity.q
  Protected gotAffinity.i

  si\cb = SizeOf(STARTUPINFO)

  workdir = *g\WorkDir
  If workdir = "" : workdir = GetPathPart(*g\ExePath) : EndIf

  ; Build command line: "exe" + args
  cmd = QuoteArg(*g\ExePath)
  If *g\Args <> "" : cmd + " " + *g\Args : EndIf
  LogLine("Launch EXE: " + *g\Name + " | " + CollapseBackslashes(*g\ExePath))

  ; Always switch to High performance while boosting
  prevPowerGuid = GetActivePowerGuid()
  If prevPowerGuid <> ""
    didSwitchPower = 1
    SaveSession(prevPowerGuid, 1, "")
    RunAndCapture("powercfg /setactive SCHEME_MIN")
    LogLine("Power plan -> High performance; prev=" + prevPowerGuid)
  EndIf

  ; Stop configured services (admin required)
  If *g\Services <> ""
    LogLine("Stopping services (configured): " + *g\Services)
    stoppedServices = StopServicesCsvAndLog(*g\Services, *g\Name)
    LogLine("Stopped services (effective): " + stoppedServices)
    If stoppedServices <> "" Or didSwitchPower
      SaveSession(prevPowerGuid, didSwitchPower, stoppedServices)
    EndIf
  EndIf

  ; CreateProcess needs writable command buffer
  Protected *cmdMem = AllocateMemory((Len(cmd) + 2) * SizeOf(Character))
  If *cmdMem = 0
    CleanupAfterLaunch(prevPowerGuid, didSwitchPower, stoppedServices)
    ProcedureReturn 0
  EndIf
  PokeS(*cmdMem, cmd, -1)

  If CreateProcess_(0, *cmdMem, 0, 0, #False, 0, 0, workdir, @si, @pi) = 0
    FreeMemory(*cmdMem)
    CleanupAfterLaunch(prevPowerGuid, didSwitchPower, stoppedServices)
    MessageRequester(#APP_NAME, "Failed to launch:" + #LF$ + *g\ExePath)
    ProcedureReturn 0
  EndIf
  FreeMemory(*cmdMem)

  ; Record originals
  origPriority = GetPriorityClass_(pi\hProcess)
  gotAffinity  = GetProcessAffinityMask_(pi\hProcess, @processAffinity, @systemAffinity)

  ; Apply boost
  If *g\Priority
    SetPriorityClass_(pi\hProcess, *g\Priority)
    LogLine("Set priority class=" + Str(*g\Priority))
  EndIf
  If *g\Affinity
    SetProcessAffinityMask_(pi\hProcess, *g\Affinity)
    LogLine("Set affinity mask=" + Hex(*g\Affinity))
  EndIf

  ; Wait for game to exit
  WaitForSingleObject_(pi\hProcess, #INFINITE)

  ; Restore (best-effort)
  If gotAffinity
    SetProcessAffinityMask_(pi\hProcess, processAffinity)
  EndIf
  If origPriority
    SetPriorityClass_(pi\hProcess, origPriority)
  EndIf

  CloseHandle_(pi\hThread)
  CloseHandle_(pi\hProcess)

  CleanupAfterLaunch(prevPowerGuid, didSwitchPower, stoppedServices)

  ProcedureReturn 1
EndProcedure

Procedure.i LaunchSteamBoosted(*g.GameEntry)
  Protected si.STARTUPINFO, pi.PROCESS_INFORMATION
  Protected prevPowerGuid.s, didSwitchPower.i
  Protected stoppedServices.s
  Protected cmd.s, workdir.s
  Protected NewMap baseline.i()
  Protected pidGame.i, hGame.i
  Protected origPriority.l
  Protected processAffinity.q, systemAffinity.q
  Protected gotAffinity.i
  Protected timeoutMs.i

  If *g\SteamExe = "" Or FileSize(*g\SteamExe) <= 0
    *g\SteamExe = FindSteamExe()
  EndIf
  If *g\SteamExe = "" Or FileSize(*g\SteamExe) <= 0
    MessageRequester(#APP_NAME, "Steam executable not set/found.")
    ProcedureReturn 0
  EndIf
  If *g\SteamAppId <= 0
    MessageRequester(#APP_NAME, "Invalid Steam AppID.")
    ProcedureReturn 0
  EndIf
  If *g\GameRoot = ""
    *g\GameRoot = GetSteamGameRootByAppId(*g\SteamExe, *g\SteamAppId)
  EndIf
  If *g\GameRoot = ""
    MessageRequester(#APP_NAME, "Could not resolve Steam install folder for this game." + #LF$ + #LF$ +
                              "Try: Import Steam again (so appmanifest_*.acf is available) and make sure the game is installed.")
    ProcedureReturn 0
  EndIf

  LogLine("Launch Steam: " + *g\Name + " | AppID=" + Str(*g\SteamAppId))

  ; Always switch to High performance while boosting
  prevPowerGuid = GetActivePowerGuid()
  If prevPowerGuid <> ""
    didSwitchPower = 1
    SaveSession(prevPowerGuid, 1, "")
    RunAndCapture("powercfg /setactive SCHEME_MIN")
    LogLine("Power plan -> High performance; prev=" + prevPowerGuid)
  EndIf

  ; Stop configured services (admin required)
  If *g\Services <> ""
    LogLine("Stopping services (configured): " + *g\Services)
    stoppedServices = StopServicesCsvAndLog(*g\Services, *g\Name)
    LogLine("Stopped services (effective): " + stoppedServices)
    If stoppedServices <> "" Or didSwitchPower
      SaveSession(prevPowerGuid, didSwitchPower, stoppedServices)
    EndIf
  EndIf

  SnapshotPids(baseline())

  si\cb = SizeOf(STARTUPINFO)
  workdir = GetPathPart(*g\SteamExe)
  cmd = QuoteArg(*g\SteamExe)
  If Trim(*g\SteamClientArgs) <> "" : cmd + " " + Trim(*g\SteamClientArgs) : EndIf
  cmd + " -applaunch " + Str(*g\SteamAppId)
  If Trim(*g\SteamGameArgs) <> "" : cmd + " " + Trim(*g\SteamGameArgs) : EndIf

  Protected *cmdMem = AllocateMemory((Len(cmd) + 2) * SizeOf(Character))
  If *cmdMem = 0
    CleanupAfterLaunch(prevPowerGuid, didSwitchPower, stoppedServices)
    ProcedureReturn 0
  EndIf
  PokeS(*cmdMem, cmd, -1)

  If CreateProcess_(0, *cmdMem, 0, 0, #False, 0, 0, workdir, @si, @pi) = 0
    FreeMemory(*cmdMem)
    CleanupAfterLaunch(prevPowerGuid, didSwitchPower, stoppedServices)
    MessageRequester(#APP_NAME, "Failed to start Steam.")
    ProcedureReturn 0
  EndIf
  FreeMemory(*cmdMem)
  CloseHandle_(pi\hThread)
  CloseHandle_(pi\hProcess)

  timeoutMs = *g\SteamDetectTimeoutMs
  If timeoutMs < 5000 : timeoutMs = 60000 : EndIf
  If timeoutMs > 300000 : timeoutMs = 300000 : EndIf
  pidGame = FindNewProcessInFolder(*g\GameRoot, baseline(), timeoutMs)
  If pidGame = 0
    CleanupAfterLaunch(prevPowerGuid, didSwitchPower, stoppedServices)
    MessageRequester(#APP_NAME, "Could not detect game process (timeout)." + #LF$ + #LF$ +
                              "Try: Edit the game -> verify Install Folder + increase detect timeout.")
    ProcedureReturn 0
  EndIf
  LogLine("Detected game PID=" + Str(pidGame))

  ; Some protected games deny PROCESS_QUERY_INFORMATION but allow limited query.
  hGame = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_SET_INFORMATION | #SYNCHRONIZE, #False, pidGame)
  If hGame = 0
    hGame = OpenProcess_(#PROCESS_QUERY_LIMITED_INFORMATION | #PROCESS_SET_INFORMATION | #SYNCHRONIZE, #False, pidGame)
  EndIf
  If hGame = 0
    CleanupAfterLaunch(prevPowerGuid, didSwitchPower, stoppedServices)
    MessageRequester(#APP_NAME, "Detected game PID " + Str(pidGame) + " but could not open process.")
    ProcedureReturn 0
  EndIf

  origPriority = GetPriorityClass_(hGame)
  gotAffinity  = GetProcessAffinityMask_(hGame, @processAffinity, @systemAffinity)

  If *g\Priority
    SetPriorityClass_(hGame, *g\Priority)
    LogLine("Set priority class=" + Str(*g\Priority))
  EndIf
  If *g\Affinity
    SetProcessAffinityMask_(hGame, *g\Affinity)
    LogLine("Set affinity mask=" + Hex(*g\Affinity))
  EndIf

  WaitForSingleObject_(hGame, #INFINITE)

  If gotAffinity
    SetProcessAffinityMask_(hGame, processAffinity)
  EndIf
  If origPriority
    SetPriorityClass_(hGame, origPriority)
  EndIf
  CloseHandle_(hGame)

  CleanupAfterLaunch(prevPowerGuid, didSwitchPower, stoppedServices)

  ProcedureReturn 1
EndProcedure

; ---------- Minimal UI ----------
Enumeration Gadgets
  #G_List
  #G_Title
  #G_Subtitle
  #G_Edit
  #G_Launch
EndEnumeration

Enumeration Menus
  #Menu_Main
EndEnumeration

Enumeration MenuItems
  #MI_File_Add
  #MI_File_BrowseExe
  #MI_File_AddFolder
  #MI_File_ImportSteam
  #MI_File_Exit

  #MI_Game_Run
  #MI_Game_Edit
  #MI_Game_Remove
  #MI_Game_OpenFolder

  #MI_Tools_ViewLog

  #MI_Help_Help
  #MI_Help_About
EndEnumeration

Procedure.s ServicesSummary(csv.s)
  Protected n.i, a.s, b.s
  csv = Trim(csv)
  If csv = "" : ProcedureReturn "" : EndIf
  n = CountString(csv, ",") + 1
  a = Trim(StringField(csv, 1, ","))
  b = Trim(StringField(csv, 2, ","))
  If n = 1 : ProcedureReturn a : EndIf
  If n = 2 : ProcedureReturn a + "," + b : EndIf
  ProcedureReturn a + "," + b + " +" + Str(n - 2)
EndProcedure

Procedure UpdateSelectionUI()
  Protected idxSel.i = GetGadgetState(#G_List)
  Protected canAct.i = Bool(idxSel >= 0)
  DisableGadget(#G_Edit, Bool(canAct = 0))
  DisableGadget(#G_Launch, Bool(canAct = 0))

  If IsMenu(#Menu_Main)
    DisableMenuItem(#Menu_Main, #MI_Game_Run, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_Edit, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_Remove, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_OpenFolder, Bool(canAct = 0))
  EndIf

  If MainStatusBar
    If canAct
      StatusBarText(MainStatusBar, 0, "Selected: " + GetGadgetItemText(#G_List, idxSel, 0))
    Else
      StatusBarText(MainStatusBar, 0, "Ready")
    EndIf
  EndIf
EndProcedure

Procedure OpenSelectedGameFolder(idxSel.i)
  Protected gg.GameEntry
  Protected folder.s
  If idxSel < 0 : ProcedureReturn : EndIf
  If SelectGameByIndex(idxSel, @gg) = 0 : ProcedureReturn : EndIf
  If gg\LaunchMode = 1
    folder = gg\GameRoot
  Else
    folder = gg\WorkDir
    If folder = "" : folder = GetPathPart(gg\ExePath) : EndIf
  EndIf
  folder = EnsureTrailingSlash(folder)
  If folder <> "" And FileSize(folder) = -2
    RunProgram("explorer.exe", #DQUOTE$ + folder + #DQUOTE$, "", #PB_Program_Open)
  EndIf
EndProcedure

Procedure RefreshList()
  ClearGadgetItems(#G_List)
  ForEach Games()
    If Games()\LaunchMode = 1
      AddGadgetItem(#G_List, -1, Games()\Name + Chr(10) + "Steam" + Chr(10) + "AppID " + Str(Games()\SteamAppId) + Chr(10) + ServicesSummary(Games()\Services))
    Else
      AddGadgetItem(#G_List, -1, Games()\Name + Chr(10) + "EXE" + Chr(10) + Games()\ExePath + Chr(10) + ServicesSummary(Games()\Services))
    EndIf
  Next
  UpdateSelectionUI()
EndProcedure

Procedure.i SelectGameByIndex(idx.i, *out.GameEntry)
  Protected i.i = 0
  ForEach Games()
    If i = idx
      *out\Name     = Games()\Name
      *out\ExePath  = Games()\ExePath
      *out\Args     = Games()\Args
      *out\WorkDir  = Games()\WorkDir
      *out\Priority = Games()\Priority
      *out\Affinity = Games()\Affinity
      *out\Services = Games()\Services
      *out\LaunchMode = Games()\LaunchMode
      *out\SteamAppId  = Games()\SteamAppId
      *out\SteamExe    = Games()\SteamExe
      *out\SteamClientArgs = Games()\SteamClientArgs
      *out\SteamGameArgs   = Games()\SteamGameArgs
      *out\SteamDetectTimeoutMs = Games()\SteamDetectTimeoutMs
      *out\GameRoot    = Games()\GameRoot
      *out\PowerGuid   = Games()\PowerGuid
      ProcedureReturn 1
    EndIf
    i + 1
  Next
  ProcedureReturn 0
EndProcedure

Procedure AddGameSimple()
  Protected g.GameEntry

  g\Name = InputRequester(#APP_NAME, "Game name:", "")
  If g\Name = "" : ProcedureReturn : EndIf

  g\ExePath = OpenFileRequester("Select game exe", "", "Executables (*.exe)|*.exe|All files (*.*)|*.*", 0)
  If g\ExePath = "" : ProcedureReturn : EndIf

  g\Args = InputRequester(#APP_NAME, "Launch arguments (optional):", "")
  g\WorkDir = GetPathPart(g\ExePath)

  g\Services = InputRequester(#APP_NAME, "Services to stop while boosting (comma-separated, optional):", "")

  ; Safe defaults
  g\Priority = #ABOVE_NORMAL_PRIORITY_CLASS
  g\Affinity = 0                 ; don't change by default
  g\LaunchMode = 0
  g\SteamAppId = 0
  g\SteamExe = ""
  g\SteamClientArgs = ""
  g\SteamGameArgs = ""
  g\SteamDetectTimeoutMs = 60000
  g\GameRoot = ""
  g\PowerGuid = ""               ; legacy (ignored)

  AddElement(Games())
  Games() = g
  SaveGames()
  RefreshList()
EndProcedure

Procedure RemoveGameByIndex(idx.i)
  Protected i.i = 0
  ForEach Games()
    If i = idx
      DeleteElement(Games())
      Break
    EndIf
    i + 1
  Next
  SaveGames()
  RefreshList()
EndProcedure

; ---------- Main ----------
EnsureElevatedOrRelaunch()
RestoreIfDirtySession()
LoadGames()

InitFonts()

If OpenWindow(0, 0, 0, 980, 510, "SafeGameBooster" + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
  If CreateMenu(#Menu_Main, WindowID(0))
    MenuTitle("File")
    MenuItem(#MI_File_Add, "Add...")
    MenuItem(#MI_File_BrowseExe, "Browse EXE...")
    MenuItem(#MI_File_AddFolder, "Add Folder...")
    MenuItem(#MI_File_ImportSteam, "Import Steam")
    MenuBar()
    MenuItem(#MI_File_Exit, "Exit")

    MenuTitle("Game")
    MenuItem(#MI_Game_Run, "Run")
    MenuItem(#MI_Game_Edit, "Edit...")
    MenuItem(#MI_Game_Remove, "Remove")
    MenuBar()
    MenuItem(#MI_Game_OpenFolder, "Open Install Folder")

    MenuTitle("Tools")
    MenuItem(#MI_Tools_ViewLog, "View Log")

    MenuTitle("Help")
    MenuItem(#MI_Help_Help, "Help")
    MenuItem(#MI_Help_About, "About")
  EndIf

  TextGadget(#G_Title, 10, 10, 960, 28, #APP_NAME)
  TextGadget(#G_Subtitle, 10, 38, 960, 18, "Safe, temporary boosts: power plan + priority/affinity + optional service stop/start")

  ; Leave space for bottom buttons + status bar.
  ListIconGadget(#G_List, 10, 70, 960, 340, "Game", 260, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
  AddGadgetColumn(#G_List, 1, "Type", 70)
  AddGadgetColumn(#G_List, 2, "Path / AppID", 460)
  AddGadgetColumn(#G_List, 3, "Services", 150)

  If FontTitle : SetGadgetFont(#G_Title, FontID(FontTitle)) : EndIf
  If FontSmall : SetGadgetFont(#G_Subtitle, FontID(FontSmall)) : EndIf
  If FontUI
    SetGadgetFont(#G_List, FontID(FontUI))
  EndIf

  ButtonGadget(#G_Edit, 740, 420, 110, 34, "Edit")
  ButtonGadget(#G_Launch, 860, 420, 110, 34, "Run")

  If FontUI
    SetGadgetFont(#G_Edit, FontID(FontUI))
    SetGadgetFont(#G_Launch, FontID(FontUI))
  EndIf

  MainStatusBar = CreateStatusBar(#PB_Any, WindowID(0))
  If MainStatusBar
    AddStatusBarField(980)
    StatusBarText(MainStatusBar, 0, "Ready")
  EndIf

  RefreshList()
  UpdateSelectionUI()

  Repeat
    Select WaitWindowEvent()
      Case #PB_Event_Gadget
        Select EventGadget()
          Case #G_List
            UpdateSelectionUI()

          Case #G_Edit
            If GetGadgetState(#G_List) >= 0
              EditGameByIndex(GetGadgetState(#G_List), #G_List)
            EndIf
            UpdateSelectionUI()
               
          Case #G_Launch
            idx = GetGadgetState(#G_List)
            If idx >= 0
              If SelectGameByIndex(idx, @g)
                If g\LaunchMode = 1
                  LaunchSteamBoosted(@g)
                Else
                  LaunchBoosted(@g)
                EndIf
              EndIf
            EndIf
            
        EndSelect

      Case #PB_Event_Menu
        Select EventMenu()
          Case #MI_File_Add
            AddGameSimple()

          Case #MI_File_BrowseExe
            BrowseExePath = OpenFileRequester("Select game exe", "", "Executables (*.exe)|*.exe|All files (*.*)|*.*", 0)
            If BrowseExePath <> ""
              BeforeCount = ListSize(Games())
              AddExeEntry(BrowseExePath)
              If ListSize(Games()) > BeforeCount
                SaveGames()
                RefreshList()
              EndIf
            EndIf

          Case #MI_File_AddFolder
            ImportFolderGames()

          Case #MI_File_ImportSteam
            ImportSteamGames()

          Case #MI_File_Exit
            Exit()

          Case #MI_Game_Run
            PostEvent(#PB_Event_Gadget, 0, #G_Launch)

          Case #MI_Game_Edit
            PostEvent(#PB_Event_Gadget, 0, #G_Edit)

          Case #MI_Game_Remove
            If GetGadgetState(#G_List) >= 0
              RemoveGameByIndex(GetGadgetState(#G_List))
            EndIf
            UpdateSelectionUI()

          Case #MI_Game_OpenFolder
            OpenSelectedGameFolder(GetGadgetState(#G_List))

          Case #MI_Tools_ViewLog
            ViewLog()

          Case #MI_Help_Help
            ShowHelp()

          Case #MI_Help_About
            MessageRequester("About", #APP_NAME + " - " + version + #CRLF$ +
                                      "A Safe Game Booster for all your games"+ #CRLF$ +
                                      "--------------------------------------" + #CRLF$ +
                                      "Contact: zonemaster60@gmail.com" + #CRLF$ +
                                      "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)

        EndSelect

      Case #PB_Event_CloseWindow
        Exit()
    EndSelect
  ForEver
EndIf

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 18
; Folding = --------------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; DllProtection
; UseIcon = SafeGameBooster.ico
; Executable = SafeGameBooster.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,1
; VersionField1 = 1,0,0,1
; VersionField2 = ZoneSoft
; VersionField3 = SafeGameBooster
; VersionField4 = 1.0.0.1
; VersionField5 = 1.0.0.1
; VersionField6 = A Safe Game Booster made with PureBasic
; VersionField7 = SafeGameBooster
; VersionField8 = SafeGameBooster.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60