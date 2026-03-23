; Core helpers, logging, DPI, elevation, power/session handling.

Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    If IsLaunchActive()
      PrepareForApplicationExit()
      ProcedureReturn
    EndIf
    FinalizeApplicationExit()
  EndIf
EndProcedure

Procedure.i IsLaunchActive()
  If LaunchActive
    ProcedureReturn 1
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure PrepareForApplicationExit()
  AppQuitting = 1
  If IsWindow(0)
    HideWindow(0, 1)
  EndIf
EndProcedure

Procedure FinalizeApplicationExit()
  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
  End
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
  t + "   - Import Steam Game: opens a picker for one installed Steam game and launches via AppID" + #CRLF$
  t + "2) Edit a game:" + #CRLF$
  t + "   - Select a game -> Edit -> set priority + pick services" + #CRLF$
  t + "   - In the services picker you can also right-click selected rows to Start/Stop now." + #CRLF$
  t + "   - Drag games in the main list to reorder them, or use Move Up / Move Down." + #CRLF$
  t + "3) Run:" + #CRLF$
  t + "   - Select a game -> Run" + #CRLF$ + #CRLF$
  t + "Services (important)" + #CRLF$
  t + "- Services you check are saved per game." + #CRLF$
  t + "- When you click Run, " + #APP_NAME + " stops services and records ONLY those it actually stopped." + #CRLF$
  t + "- On exit, it restarts exactly that recorded set." + #CRLF$
  t + "- If a service fails to stop/start, the log records the error." + #CRLF$ + #CRLF$
  t + "Crash recovery" + #CRLF$
  t + "- While a game is running, session.ini is marked 'dirty' and stores:" + #CRLF$
  t + "  - the previous power plan GUID" + #CRLF$
  t + "  - the effective list of stopped services" + #CRLF$
  t + "- Next time " + #APP_NAME + " starts, it detects a dirty session and restores power plan/services." + #CRLF$ + #CRLF$
  t + "Where files are" + #CRLF$
  t + "- games.ini, session.ini, " + #APP_NAME + ".log are stored next to the EXE." + #CRLF$
  t + "- Use the Open Log button to open " + #APP_NAME + ".log." + #CRLF$ + #CRLF$
  t + "Troubleshooting" + #CRLF$
  t + "- Admin rights: service control requires an elevated process. " + #APP_NAME + " auto-prompts via UAC." + #CRLF$
  t + "- Steam games: " + #APP_NAME + " waits for a new process whose EXE path starts with the game's install folder." + #CRLF$
  t + "- If Run 'does nothing', make sure a game is selected, then check " + #APP_NAME + ".log." + #CRLF$
  ProcedureReturn t
EndProcedure

Procedure ShowHelp()
  Protected w.i, gText.i, gClose.i, gOpenLog.i
  Protected ev.i

  w = OpenWindow(#PB_Any, 0, 0, 820, 620, "Help", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If w
    DisableWindow(0, 1)
    gText = EditorGadget(#PB_Any, 10, 10, 800, 560)
    SetGadgetText(gText, HelpText())
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
  RunProgram(LogPath, "", "", #PB_Program_Open)
EndProcedure

Procedure.i ScaleX(x.i)
  ProcedureReturn DesktopScaledX(x)
EndProcedure

Procedure.i ScaleY(y.i)
  ProcedureReturn DesktopScaledY(y)
EndProcedure

Procedure InitFonts()
  Protected baseSize.i = 10
  FontUI = LoadFont(#PB_Any, "Segoe UI", ScaleY(baseSize))
  FontSmall = LoadFont(#PB_Any, "Segoe UI", ScaleY(baseSize - 1))
  FontTitle = LoadFont(#PB_Any, "Segoe UI", ScaleY(baseSize + 5), #PB_Font_Bold)
EndProcedure

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

Procedure.s RunProgramAndCapture(exe.s, args.s)
  Protected p.i, out.s, line.s
  p = RunProgram(exe, args, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
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

Procedure.s RunAndCapture(cmd.s)
  ProcedureReturn RunProgramAndCapture("cmd.exe", "/c " + cmd)
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
  s = ReplaceString(s, "\\", "\")
  s = ReplaceString(s, "\\" + Chr(34), Chr(34))
  ProcedureReturn s
EndProcedure

Procedure.i ClampSteamDetectTimeout(timeoutMs.i)
  If timeoutMs < 5000 : ProcedureReturn 60000 : EndIf
  If timeoutMs > 300000 : ProcedureReturn 300000 : EndIf
  ProcedureReturn timeoutMs
EndProcedure

Procedure.s CollapseBackslashes(p.s)
  While FindString(p, "\\\\", 1)
    p = ReplaceString(p, "\\\\", "\\")
  Wend
  ProcedureReturn p
EndProcedure

Procedure.s GetActivePowerGuid()
  Protected out.s = RunAndCapture("powercfg /getactivescheme")
  Protected p.i = FindString(out, ":", 1)
  If p = 0 : p = FindString(out, "GUID", 1) : EndIf
  Protected i.i, token.s, c.s
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
    cleanExit = ReadPreferenceInteger("cleanExit", 1)
    ClosePreferences()
  EndIf

  If cleanExit = 0
    LogLine("Dirty session detected; restoring")
    If didStopServices And stoppedServices <> ""
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

Procedure CleanupAfterLaunch(prevPowerGuid.s, didSwitchPower.i, stoppedServices.s)
  Protected restoredPower.i
  If stoppedServices <> ""
    RestartServicesPipeListAndLog(stoppedServices, "cleanup")
  EndIf
  If didSwitchPower And prevPowerGuid <> ""
    SetActivePowerGuid(prevPowerGuid)
    restoredPower = 1
    LogLine("Power plan restored: " + prevPowerGuid)
  EndIf
  If (stoppedServices <> "") Or restoredPower
    MarkSessionClean()
  EndIf
EndProcedure

Procedure PrepareBoostSession(*g.GameEntry, *ctx.BoostSessionContext)
  *ctx\PrevPowerGuid = GetActivePowerGuid()
  *ctx\DidSwitchPower = 0
  *ctx\StoppedServices = ""

  If *ctx\PrevPowerGuid <> ""
    *ctx\DidSwitchPower = 1
    SaveSession(*ctx\PrevPowerGuid, 1, "")
    RunAndCapture("powercfg /setactive SCHEME_MIN")
    LogLine("Power plan -> High performance; prev=" + *ctx\PrevPowerGuid)
  EndIf

  If *g\Services <> ""
    LogLine("Stopping services (configured): " + *g\Services)
    *ctx\StoppedServices = StopServicesCsvAndLog(*g\Services, *g\Name)
    LogLine("Stopped services (effective): " + *ctx\StoppedServices)
    If *ctx\StoppedServices <> "" Or *ctx\DidSwitchPower
      SaveSession(*ctx\PrevPowerGuid, *ctx\DidSwitchPower, *ctx\StoppedServices)
    EndIf
  EndIf
EndProcedure

Procedure CleanupBoostSession(*ctx.BoostSessionContext)
  CleanupAfterLaunch(*ctx\PrevPowerGuid, *ctx\DidSwitchPower, *ctx\StoppedServices)
EndProcedure

Procedure ApplyProcessBoost(hProcess.i, *g.GameEntry)
  If *g\Priority
    SetPriorityClass_(hProcess, *g\Priority)
    LogLine("Set priority class=" + Str(*g\Priority))
  EndIf
  If *g\Affinity
    SetProcessAffinityMask_(hProcess, *g\Affinity)
    LogLine("Set affinity mask=" + Hex(*g\Affinity))
  EndIf
EndProcedure

Procedure RestoreProcessBoost(hProcess.i, gotAffinity.i, origPriority.l, processAffinity.q)
  If gotAffinity
    SetProcessAffinityMask_(hProcess, processAffinity)
  EndIf
  If origPriority
    SetPriorityClass_(hProcess, origPriority)
  EndIf
EndProcedure
