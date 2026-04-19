EnableExplicit

; Native memory-list purge (no RAMMap dependency)
; ---------------------------------------------------------
Prototype.l ProtoNtSetSystemInformation(SystemInformationClass.l, SystemInformation.i, SystemInformationLength.l)
Prototype.l ProtoRtlAdjustPrivilege(Privilege.l, Enable.l, CurrentThread.l, *Enabled)
Global gNtdll.i, NtSetSystemInformation.ProtoNtSetSystemInformation, RtlAdjustPrivilege.ProtoRtlAdjustPrivilege

; ---------------------------------------------------------
; Tray & UI constants
; ---------------------------------------------------------

#TRAY_ICON       = 1
#TRAY_MENU       = 2
#MENU_RUNNOW     = 10
#MENU_STARTUP    = 11
#MENU_LOGTOGGLE  = 12
#MENU_EDITSETTINGS = 13
#MENU_MEMTHRESHOLD = 14
#MENU_RELOADSETTINGS = 15
#MENU_ABOUT      = 16
#MENU_EXIT       = 17
#ICON_GREEN_BASE  = 101
#ICON_RED_BASE    = 102
#ICON_YELLOW_BASE = 103
#ICON_ACTIVE_BASE = 104
#ICON_LIBRARY_INDEX_ACTIVE = 0
#ICON_LIBRARY_INDEX_GREEN  = 1
#ICON_LIBRARY_INDEX_RED    = 2
#ICON_LIBRARY_INDEX_YELLOW = 3


Global quitProgram      = #False
Global startupEnabled   = #False ; desired startup state
Global AppPath.s        = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

Global gSingleRunMode.i = #False ; --clearonce helper mode

; Global interval + countdown timestamp
Global IntervalMinutes  = 5
Global IntervalMS       = 5 * 60000
Global g_TimerNextRun.q = 0
Global gTooltipOverrideUntil.q = 0
Global gTooltipOverrideText.s = ""

; Logging toggle
Global loggingEnabled   = #True
Global version.s = "v1.0.1.6"

; Memory threshold (auto-clean when available RAM <= threshold)
Global gMemThresholdEnabled.i = #False
Global gMemThresholdAvailMB.i = 1024
Global gMemThresholdWasBelow.i = #False

; Logging paths + rotation
#LOG_FILE        = "ClearRam.log"
Global gLogPath.s = ""
Global gLogRotateEnabled.i = #True
Global gLogRotateMaxBytes.q = 1024 * 1024 ; 1 MiB
Global gLogRotateKeep.i = 3
Global gLogMutex.i = CreateMutex()
Global gUiMutex.i = CreateMutex()
Global gRunStateMutex.i = CreateMutex()
Global gTimerThread.i = 0
Global gWorkerThread.i = 0
Global gTrayBusy.i = #False
Global gTrayIconReady.i = #False
Global gTrayBaseImageForPct.i = 0
Global gTrayYellowThresholdPct.i = 50
Global gTrayRedThresholdPct.i = 75
Global gTrayGreenIconHandle.i = 0
Global gTrayRedIconHandle.i = 0
Global gTrayYellowIconHandle.i = 0
Global gTrayActiveIconHandle.i = 0
Global gPendingTrayBusyValid.i = #False
Global gPendingTrayBusy.i = #False
Global gPendingTooltipMode.i = 0
Global gPendingTooltipText.s = ""
Global gPendingTooltipHoldMs.q = 0

; Paths / config
#INI_FILE        = "ClearRam.ini"
#APP_NAME        = "ClearRam"
#EMAIL_NAME      = "zonemaster60@gmail.com"

Declare.i GetTotalPhysMB()
Declare.i GetAvailPhysMB()
Declare.i GetUsedMemPercent()
Declare NormalizeTrayUsageThresholds()
Declare.b OpenOrCreateSettingsPreferences(iniFile.s)
Declare.i LoadTrayIconHandle(iconLibraryPath.s, iconIndex.i)
Declare.b LoadTrayIconsFromLibrary(iconLibraryPath.s)
Declare DestroyTrayIcons()
Declare.i GetTrayIconHandle(iconNumber.i)
Declare.b EnsureTrayIconReady()
Declare.b EnsureAppDirectory(dirPath.s)
Declare EnsureAppDirectories()
Declare SetTrayBusyState(isBusy.i)
Declare SetTooltipOverride(text$, holdMs.q)
Declare UpdateTrayTooltip(status.s)
Declare QueueTrayBusyState(isBusy.i)
Declare QueueTrayTooltip(status.s)
Declare QueueTrayTooltipOverride(text.s, holdMs.q)
Declare ApplyPendingTrayUpdates()

Procedure.b HasArg(arg$)
  Protected i
  For i = 1 To CountProgramParameters()
    If LCase(ProgramParameter(i - 1)) = LCase(arg$)
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

gSingleRunMode = HasArg("--clearonce")
Global gInstallStartupTaskMode.i = HasArg("--installstartup")
Global gRemoveStartupTaskMode.i  = HasArg("--removestartup")
Global gHelperMode.i = Bool(gSingleRunMode Or gInstallStartupTaskMode Or gRemoveStartupTaskMode)

; Prevent multiple instances (don't rely on window title text)
; Allow helper modes to run even if the tray app is running.
Global hMutex.i
If gHelperMode = #False
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
  If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
    CloseHandle_(hMutex)
    End
  EndIf
EndIf

; ---------------------------------------------------------
; Logging helper
; ---------------------------------------------------------

Procedure LogRotateIfNeeded()
  If loggingEnabled = #False Or gLogRotateEnabled = #False Or gLogPath = ""
    ProcedureReturn
  EndIf

  If gLogRotateKeep < 1 Or gLogRotateMaxBytes < 1
    ProcedureReturn
  EndIf

  LockMutex(gLogMutex)

  Protected size.q = FileSize(gLogPath)
  If size < 0 Or size <= gLogRotateMaxBytes
    UnlockMutex(gLogMutex)
    ProcedureReturn
  EndIf

  Protected i.i
  Protected src$
  Protected dst$

  dst$ = gLogPath + "." + Str(gLogRotateKeep)
  If FileSize(dst$) >= 0
    DeleteFile(dst$)
  EndIf

  For i = gLogRotateKeep - 1 To 1 Step -1
    src$ = gLogPath + "." + Str(i)
    If FileSize(src$) >= 0
      RenameFile(src$, gLogPath + "." + Str(i + 1))
    EndIf
  Next

  RenameFile(gLogPath, gLogPath + ".1")
  UnlockMutex(gLogMutex)
EndProcedure

Procedure LogMessage(msg.s)
  If loggingEnabled = #False Or gLogPath = ""
    ProcedureReturn
  EndIf

  LogRotateIfNeeded()

  LockMutex(gLogMutex)
  Protected file = OpenFile(#PB_Any, gLogPath, #PB_File_SharedRead | #PB_File_SharedWrite)
  If file = 0
    file = CreateFile(#PB_Any, gLogPath)
  EndIf

  If file
    FileSeek(file, Lof(file))
    WriteStringN(file, FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + msg)
    CloseFile(file)
  EndIf
  UnlockMutex(gLogMutex)
EndProcedure

Procedure.b EnsureAppDirectory(dirPath.s)
  If FileSize(dirPath) = -2
    ProcedureReturn #True
  EndIf

  ProcedureReturn Bool(CreateDirectory(dirPath))
EndProcedure

Procedure EnsureAppDirectories()
  EnsureAppDirectory(AppPath + "files")
  EnsureAppDirectory(AppPath + "Logs")
EndProcedure

; ---------------------------------------------------------
; Load INI settings
; ---------------------------------------------------------

Procedure LoadSettings()
  Protected iniFile.s = AppPath + "files\" + #INI_FILE

  EnsureAppDirectories()

  ; Defaults
  IntervalMinutes = 5
  loggingEnabled  = #True
  startupEnabled  = 0
  gLogRotateEnabled = #True
  gLogRotateMaxBytes = 1024 * 1024
  gLogRotateKeep = 3
  gMemThresholdEnabled = #False
  gMemThresholdAvailMB = 1024
  gTrayYellowThresholdPct = 50
  gTrayRedThresholdPct = 75

  If OpenPreferences(iniFile)
    IntervalMinutes = ReadPreferenceInteger("IntervalMinutes", IntervalMinutes)
    If IntervalMinutes <= 0 : IntervalMinutes = 5 : EndIf

    loggingEnabled = ReadPreferenceInteger("LoggingEnabled", 1)
    If loggingEnabled <> 0 And loggingEnabled <> 1
      loggingEnabled = #True
    EndIf

    startupEnabled = ReadPreferenceInteger("RunAtStartup", 0)
    If startupEnabled <> 0 And startupEnabled <> 1
      startupEnabled = 0
    EndIf

    gLogRotateEnabled = ReadPreferenceInteger("LogRotateEnabled", 1)
    If gLogRotateEnabled <> 0 And gLogRotateEnabled <> 1
      gLogRotateEnabled = #True
    EndIf

    gLogRotateKeep = ReadPreferenceInteger("LogRotateKeep", gLogRotateKeep)
    If gLogRotateKeep < 1 : gLogRotateKeep = 1 : EndIf

    ; Stored as KB to keep INI human-friendly
    Protected maxKb = ReadPreferenceInteger("LogRotateMaxKB", 1024)
    If maxKb < 1 : maxKb = 1 : EndIf
    gLogRotateMaxBytes = maxKb * 1024

    gMemThresholdEnabled = ReadPreferenceInteger("MemThresholdEnabled", 0)
    If gMemThresholdEnabled <> 0 And gMemThresholdEnabled <> 1
      gMemThresholdEnabled = #False
    EndIf

    ; Cache total RAM for clamping/conversions (0 if call fails)
    Protected totalPhysMB.i = GetTotalPhysMB()

    ; Available RAM threshold in MB (auto-clean triggers when avail <= this)
    gMemThresholdAvailMB = ReadPreferenceInteger("MemThresholdAvailMB", -1)
    If gMemThresholdAvailMB < 0
      ; Backward-compat: derive from legacy MemThresholdPercent (used%) if present
      Protected legacyUsedPct.i = ReadPreferenceInteger("MemThresholdPercent", 85)
      If legacyUsedPct < 50 : legacyUsedPct = 50 : EndIf
      If legacyUsedPct > 99 : legacyUsedPct = 99 : EndIf
      If totalPhysMB > 0
        gMemThresholdAvailMB = (totalPhysMB * (100 - legacyUsedPct)) / 100
      Else
        gMemThresholdAvailMB = 1024
      EndIf
    EndIf
    If gMemThresholdAvailMB < 64 : gMemThresholdAvailMB = 64 : EndIf
    If totalPhysMB > 0 And gMemThresholdAvailMB > totalPhysMB : gMemThresholdAvailMB = totalPhysMB : EndIf

    gTrayYellowThresholdPct = ReadPreferenceInteger("TrayYellowThresholdPct", gTrayYellowThresholdPct)
    gTrayRedThresholdPct = ReadPreferenceInteger("TrayRedThresholdPct", gTrayRedThresholdPct)

    ClosePreferences()
  Else
    ; Create INI with defaults
    If CreatePreferences(iniFile)
      WritePreferenceInteger("IntervalMinutes", IntervalMinutes)
      WritePreferenceInteger("LoggingEnabled", 1)
      WritePreferenceInteger("RunAtStartup", 0)
      WritePreferenceInteger("LogRotateEnabled", 1)
      WritePreferenceInteger("LogRotateKeep", gLogRotateKeep)
      WritePreferenceInteger("LogRotateMaxKB", 1024)
      WritePreferenceInteger("MemThresholdEnabled", 0)
      WritePreferenceInteger("MemThresholdAvailMB", 1024)
      WritePreferenceInteger("TrayYellowThresholdPct", gTrayYellowThresholdPct)
      WritePreferenceInteger("TrayRedThresholdPct", gTrayRedThresholdPct)
      ClosePreferences()
    EndIf
  EndIf

  NormalizeTrayUsageThresholds()

  IntervalMS = IntervalMinutes * 60000

  gLogPath = AppPath + "Logs\" + #LOG_FILE
  LogRotateIfNeeded()

   LogMessage("Loaded settings: Interval=" + Str(IntervalMinutes) + " minutes, Logging=" + Str(loggingEnabled) +
              ", Rotate=" + Str(gLogRotateEnabled) + " keep=" + Str(gLogRotateKeep) + " maxKB=" + Str(gLogRotateMaxBytes / 1024) +
              ", MemThreshold=" + Str(gMemThresholdEnabled) + "@" + Str(gMemThresholdAvailMB) + "MB(avail)" +
              ", TrayThresholds yellow=" + Str(gTrayYellowThresholdPct) + "% red=" + Str(gTrayRedThresholdPct) + "%")

EndProcedure

Procedure.b OpenOrCreateSettingsPreferences(iniFile.s)
  If FileSize(iniFile) >= 0
    If OpenPreferences(iniFile)
      ProcedureReturn #True
    EndIf
  EndIf

  ProcedureReturn Bool(CreatePreferences(iniFile))
EndProcedure

Procedure SaveSettings()
  Protected iniFile.s = AppPath + "files\" + #INI_FILE

  EnsureAppDirectories()

  If IntervalMinutes <= 0 : IntervalMinutes = 5 : EndIf
  If gLogRotateKeep < 1 : gLogRotateKeep = 1 : EndIf
  If gLogRotateMaxBytes < 1024 : gLogRotateMaxBytes = 1024 : EndIf

  Protected totalPhysMB.i = GetTotalPhysMB()
  If gMemThresholdAvailMB < 64 : gMemThresholdAvailMB = 64 : EndIf
  If totalPhysMB > 0 And gMemThresholdAvailMB > totalPhysMB : gMemThresholdAvailMB = totalPhysMB : EndIf

  NormalizeTrayUsageThresholds()

  If OpenOrCreateSettingsPreferences(iniFile)
    WritePreferenceInteger("IntervalMinutes", IntervalMinutes)
    WritePreferenceInteger("LoggingEnabled", loggingEnabled)
    WritePreferenceInteger("RunAtStartup", startupEnabled)
    WritePreferenceInteger("LogRotateEnabled", gLogRotateEnabled)
    WritePreferenceInteger("LogRotateKeep", gLogRotateKeep)
    WritePreferenceInteger("LogRotateMaxKB", gLogRotateMaxBytes / 1024)
    WritePreferenceInteger("MemThresholdEnabled", gMemThresholdEnabled)
    WritePreferenceInteger("MemThresholdAvailMB", gMemThresholdAvailMB)
    WritePreferenceInteger("TrayYellowThresholdPct", gTrayYellowThresholdPct)
    WritePreferenceInteger("TrayRedThresholdPct", gTrayRedThresholdPct)
    ClosePreferences()
    LogMessage("Settings saved.")
  Else
    LogMessage("Failed to save settings to: " + iniFile)
  EndIf
EndProcedure

; ---------------------------------------------------------
; Memory threshold slider dialog
; ---------------------------------------------------------

Procedure.b EditMemoryThresholdSlider()
  Protected oldEnabled.i = gMemThresholdEnabled
  Protected oldMB.i = gMemThresholdAvailMB
  Protected stepMB.i = 64

  Protected w = 420
  Protected h = 170

  Protected win = OpenWindow(#PB_Any, 0, 0, w, h, "Memory Threshold", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If win = 0
    ProcedureReturn #False
  EndIf

  Protected gadEnable = CheckBoxGadget(#PB_Any, 12, 12, w - 24, 20, "Enable auto-clean when available memory is low")
  SetGadgetState(gadEnable, gMemThresholdEnabled)

  Protected gadLabel = TextGadget(#PB_Any, 12, 44, w - 24, 18, "Clean when Available RAM <= " + Str(gMemThresholdAvailMB) + " MB")
  Protected totalMB.i = GetTotalPhysMB()
  If totalMB < 64 : totalMB = 64 : EndIf
  Protected gadSlider = TrackBarGadget(#PB_Any, 12, 66, w - 24, 28, 64, totalMB)
  Protected initMB.i = gMemThresholdAvailMB
  If initMB > totalMB : initMB = totalMB : EndIf
  If initMB < 64 : initMB = 64 : EndIf
  ; Snap to step increments (64MB by default)
  initMB = ((initMB + (stepMB / 2)) / stepMB) * stepMB
  If initMB > totalMB : initMB = totalMB : EndIf
  SetGadgetState(gadSlider, initMB)

  Protected gadCurr = TextGadget(#PB_Any, 12, 98, w - 24, 18, "Current Available RAM: " + Str(GetAvailPhysMB()) + " MB")

  Protected gadOk = ButtonGadget(#PB_Any, w - 180, h - 42, 80, 26, "OK")
  Protected gadCancel = ButtonGadget(#PB_Any, w - 92, h - 42, 80, 26, "Cancel")

  Protected ev, g
  Protected nextRefresh.q = ElapsedMilliseconds() + 500
  Protected done.i = #False
  Protected apply.i = #False

  Repeat
    ev = WaitWindowEvent(50)
    If ElapsedMilliseconds() >= nextRefresh
      SetGadgetText(gadCurr, "Current Available RAM: " + Str(GetAvailPhysMB()) + " MB")
      nextRefresh = ElapsedMilliseconds() + 500
    EndIf

    Select ev
      Case #PB_Event_CloseWindow
        done = #True

      Case #PB_Event_Gadget
        g = EventGadget()
        If g = gadSlider
          Protected v.i = GetGadgetState(gadSlider)
          Protected snapped.i = ((v + (stepMB / 2)) / stepMB) * stepMB
          If snapped < 64 : snapped = 64 : EndIf
          If snapped > totalMB : snapped = totalMB : EndIf
          If snapped <> v
            SetGadgetState(gadSlider, snapped)
          EndIf
          SetGadgetText(gadLabel, "Clean when Available RAM <= " + Str(snapped) + " MB")
          SetGadgetText(gadCurr, "Current Available RAM: " + Str(GetAvailPhysMB()) + " MB")
        ElseIf g = gadOk
          apply = #True
          done = #True
        ElseIf g = gadCancel
          done = #True
        EndIf
    EndSelect
  Until done

  If apply
    gMemThresholdEnabled = Bool(GetGadgetState(gadEnable) <> 0)
    gMemThresholdAvailMB = GetGadgetState(gadSlider)
    gMemThresholdAvailMB = ((gMemThresholdAvailMB + (stepMB / 2)) / stepMB) * stepMB
    If gMemThresholdAvailMB < 64 : gMemThresholdAvailMB = 64 : EndIf

    ; Avoid an immediate trigger after changing threshold.
    gMemThresholdWasBelow = Bool(gMemThresholdEnabled And GetAvailPhysMB() <= gMemThresholdAvailMB)

    If oldEnabled <> gMemThresholdEnabled Or oldMB <> gMemThresholdAvailMB
      SaveSettings()
      LogMessage("Memory threshold updated: enabled=" + Str(gMemThresholdEnabled) + " availMB=" + Str(gMemThresholdAvailMB))
      CloseWindow(win)
      ProcedureReturn #True
    EndIf
  EndIf

  CloseWindow(win)
  ProcedureReturn apply
EndProcedure

; ---------------------------------------------------------
; Task Scheduler startup helpers
; ---------------------------------------------------------

Procedure.s StartupTaskName()
  ProcedureReturn "ClearRam"
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
  ; Older versions used HKCU\...\Run. Best-effort cleanup.
  Protected cmd.s = "reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v " + #APP_NAME + " /f"
  RunProgram("cmd.exe", "/c " + cmd, "", #PB_Program_Hide)
EndProcedure

Declare.i IsInStartup()
Declare RunClearRam_Thread(*unused)

; ---------------------------------------------------------
; Task Scheduler helpers (logging + elevation)
; ---------------------------------------------------------

Global gLastExecExitCode.i

Procedure.s RunAndCapture(exe.s, args.s)
  Protected output.s = ""

  LogMessage("RUN: " + exe + " " + args)

  Protected program = RunProgram(exe, args, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If program = 0
    gLastExecExitCode = -1
    LogMessage("ERROR: failed to start process")
    ProcedureReturn output
  EndIf

  While ProgramRunning(program)
    While AvailableProgramOutput(program)
      output + ReadProgramString(program) + #CRLF$
    Wend
    Delay(10)
  Wend

  While AvailableProgramOutput(program)
    output + ReadProgramString(program) + #CRLF$
  Wend

  gLastExecExitCode = ProgramExitCode(program)
  CloseProgram(program)

  LogMessage("EXITCODE: " + Str(gLastExecExitCode))
  If Trim(output) <> ""
    LogMessage("OUTPUT: " + ReplaceString(output, #CRLF$, " | "))
  EndIf

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
  LogMessage("Requesting elevation: " + exe$ + " " + args)
  ShellExecute_(0, "runas", exe$, args, AppPath, 1)
EndProcedure

Procedure AddToStartup()
  RemoveLegacyStartupRegistryEntry()

  LogMessage("AddToStartup: task='" + StartupTaskName() + "' exe='" + ProgramFilename() + "'")

  If IsProcessElevated() = #False And gInstallStartupTaskMode = #False
    RelaunchSelfElevated("--installstartup")
    ProcedureReturn
  EndIf

  ; Task is created to run in the current user session (interactive),
  ; so the tray icon is visible after logon.

  ; Fully automated task creation (no external XML file).
  ; Runs at logon for the current user, delays 60 seconds, highest privileges,
  ; and runs as soon as possible if a scheduled start is missed.
  ; NOTE: Running as SYSTEM prevents the tray icon from showing in the user session.
  Protected taskName.s = StartupTaskName()

  ; Build a PowerShell Register-ScheduledTask command.
  Protected psTaskName.s = ReplaceString(taskName, "'", "''")
  Protected psExe.s = ReplaceString(ProgramFilename(), "'", "''")
  Protected psWorkDir.s = ReplaceString(AppPath, "'", "''")
  Protected psUser.s = ReplaceString(StartupTaskUserId(), "'", "''")

  ; Use explicit try/catch so any errors go to stdout.
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

  ; Verify task now exists.
  If IsInStartup()
    LogMessage("Startup task ensured: " + StartupTaskName())
  Else
    LogMessage("ERROR: Startup task not present after create attempt")
  EndIf
EndProcedure

Procedure RemoveFromStartup()
  RemoveLegacyStartupRegistryEntry()

  LogMessage("RemoveFromStartup: task='" + StartupTaskName() + "'")

  If IsProcessElevated() = #False And gRemoveStartupTaskMode = #False
    RelaunchSelfElevated("--removestartup")
    ProcedureReturn
  EndIf

  Protected nameQuoted.s = Chr(34) + StartupTaskName() + Chr(34)
  Protected cmd.s = "/c schtasks /Delete /TN " + nameQuoted + " /F"
  RunAndCapture("cmd.exe", cmd)

  If IsInStartup() = #False
    LogMessage("Startup task removed: " + StartupTaskName())
  Else
    LogMessage("WARN: Startup task still present after delete attempt")
  EndIf
EndProcedure

Procedure.i IsInStartup()
  Protected nameQuoted.s = Chr(34) + StartupTaskName() + Chr(34)
  Protected cmd.s = "schtasks /Query /TN " + nameQuoted

  Protected program = RunProgram("cmd.exe", "/c " + cmd, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If program
    While ProgramRunning(program)
      While AvailableProgramOutput(program)
        ReadProgramString(program) ; drain output
      Wend
      Delay(10)
    Wend

    Protected code.i = ProgramExitCode(program)
    CloseProgram(program)
    ProcedureReturn Bool(code = 0)
  EndIf

  ProcedureReturn #False
EndProcedure

; ---------------------------------------------------------
; Tray helpers
; ---------------------------------------------------------

Procedure NormalizeTrayUsageThresholds()
  If gTrayYellowThresholdPct < 1 : gTrayYellowThresholdPct = 1 : EndIf
  If gTrayYellowThresholdPct > 99 : gTrayYellowThresholdPct = 99 : EndIf
  If gTrayRedThresholdPct < 2 : gTrayRedThresholdPct = 2 : EndIf
  If gTrayRedThresholdPct > 100 : gTrayRedThresholdPct = 100 : EndIf

  If gTrayRedThresholdPct <= gTrayYellowThresholdPct
    gTrayRedThresholdPct = gTrayYellowThresholdPct + 1
    If gTrayRedThresholdPct > 100
      gTrayRedThresholdPct = 100
      gTrayYellowThresholdPct = 99
    EndIf
  EndIf
EndProcedure

Procedure.i LoadTrayIconHandle(iconLibraryPath.s, iconIndex.i)
  Protected smallIcon.i

  If ExtractIconEx_(iconLibraryPath, iconIndex, 0, @smallIcon, 1) <> 1
    ProcedureReturn 0
  EndIf

  ProcedureReturn smallIcon
EndProcedure

Procedure DestroyTrayIcons()
  If gTrayGreenIconHandle
    DestroyIcon_(gTrayGreenIconHandle)
    gTrayGreenIconHandle = 0
  EndIf
  If gTrayRedIconHandle
    DestroyIcon_(gTrayRedIconHandle)
    gTrayRedIconHandle = 0
  EndIf
  If gTrayYellowIconHandle
    DestroyIcon_(gTrayYellowIconHandle)
    gTrayYellowIconHandle = 0
  EndIf
  If gTrayActiveIconHandle
    DestroyIcon_(gTrayActiveIconHandle)
    gTrayActiveIconHandle = 0
  EndIf
EndProcedure

Procedure.b LoadTrayIconsFromLibrary(iconLibraryPath.s)
  DestroyTrayIcons()

  If FileSize(iconLibraryPath) < 0
    ProcedureReturn #False
  EndIf

  gTrayActiveIconHandle = LoadTrayIconHandle(iconLibraryPath, #ICON_LIBRARY_INDEX_ACTIVE)
  gTrayRedIconHandle = LoadTrayIconHandle(iconLibraryPath, #ICON_LIBRARY_INDEX_RED)
  gTrayGreenIconHandle = LoadTrayIconHandle(iconLibraryPath, #ICON_LIBRARY_INDEX_GREEN)
  gTrayYellowIconHandle = LoadTrayIconHandle(iconLibraryPath, #ICON_LIBRARY_INDEX_YELLOW)

  If gTrayActiveIconHandle = 0 Or gTrayRedIconHandle = 0 Or gTrayGreenIconHandle = 0 Or gTrayYellowIconHandle = 0
    DestroyTrayIcons()
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i GetTrayIconHandle(iconNumber.i)
  Select iconNumber
    Case #ICON_RED_BASE
      ProcedureReturn gTrayRedIconHandle
    Case #ICON_YELLOW_BASE
      ProcedureReturn gTrayYellowIconHandle
    Case #ICON_ACTIVE_BASE
      ProcedureReturn gTrayActiveIconHandle
    Default
      ProcedureReturn gTrayGreenIconHandle
  EndSelect
EndProcedure

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    LogMessage("Program exiting")
    quitProgram = #True

    Protected timerThread.i
    Protected workerThread.i

    LockMutex(gRunStateMutex)
    timerThread = gTimerThread
    workerThread = gWorkerThread
    UnlockMutex(gRunStateMutex)

    If timerThread
      WaitThread(timerThread, 3000)
    EndIf

    If workerThread
      WaitThread(workerThread, 3000)
    EndIf

    ; Proper cleanup
    RemoveWindowTimer(0, 2)
    RemoveSysTrayIcon(#TRAY_ICON)
    FreeMenu(#TRAY_MENU)
    DestroyTrayIcons()

    If IsLibrary(gNtdll)
      CloseLibrary(gNtdll)
    EndIf

    If gRunStateMutex
      FreeMutex(gRunStateMutex)
      gRunStateMutex = 0
    EndIf
    If gUiMutex
      FreeMutex(gUiMutex)
      gUiMutex = 0
    EndIf
    If gLogMutex
      FreeMutex(gLogMutex)
      gLogMutex = 0
    EndIf
    If hMutex
      CloseHandle_(hMutex)
      hMutex = 0
    EndIf
    End
  EndIf
EndProcedure

Procedure SetTooltipOverride(text$, holdMs.q)
  gTooltipOverrideText = text$
  gTooltipOverrideUntil = ElapsedMilliseconds() + holdMs
  If gTrayIconReady
    SysTrayIconToolTip(#TRAY_ICON, gTooltipOverrideText)
  EndIf
EndProcedure

Procedure ShutdownAndExit()
  quitProgram = #True

  If IsLibrary(gNtdll)
    CloseLibrary(gNtdll)
  EndIf

  If gUiMutex
    FreeMutex(gUiMutex)
    gUiMutex = 0
  EndIf

  If gRunStateMutex
    FreeMutex(gRunStateMutex)
    gRunStateMutex = 0
  EndIf

  If gLogMutex
    FreeMutex(gLogMutex)
    gLogMutex = 0
  EndIf

  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf

  End
EndProcedure

Procedure QueueTrayBusyState(isBusy.i)
  LockMutex(gUiMutex)
  gPendingTrayBusyValid = #True
  gPendingTrayBusy = Bool(isBusy <> 0)
  UnlockMutex(gUiMutex)
EndProcedure

Procedure QueueTrayTooltip(status.s)
  LockMutex(gUiMutex)
  gPendingTooltipMode = 1
  gPendingTooltipText = status
  gPendingTooltipHoldMs = 0
  UnlockMutex(gUiMutex)
EndProcedure

Procedure QueueTrayTooltipOverride(text.s, holdMs.q)
  LockMutex(gUiMutex)
  gPendingTooltipMode = 2
  gPendingTooltipText = text
  gPendingTooltipHoldMs = holdMs
  UnlockMutex(gUiMutex)
EndProcedure

Procedure ApplyPendingTrayUpdates()
  Protected hasBusy.i = #False
  Protected busyState.i = #False
  Protected tooltipMode.i = 0
  Protected tooltipText.s = ""
  Protected tooltipHoldMs.q = 0

  LockMutex(gUiMutex)
  hasBusy = gPendingTrayBusyValid
  busyState = gPendingTrayBusy
  tooltipMode = gPendingTooltipMode
  tooltipText = gPendingTooltipText
  tooltipHoldMs = gPendingTooltipHoldMs
  gPendingTrayBusyValid = #False
  gPendingTooltipMode = 0
  gPendingTooltipText = ""
  gPendingTooltipHoldMs = 0
  UnlockMutex(gUiMutex)

  If hasBusy
    SetTrayBusyState(busyState)
  EndIf

  Select tooltipMode
    Case 1
      UpdateTrayTooltip(tooltipText)
    Case 2
      SetTooltipOverride(tooltipText, tooltipHoldMs)
  EndSelect
EndProcedure

Procedure UpdateTrayTooltip(status.s)
  If gTrayIconReady
    SysTrayIconToolTip(#TRAY_ICON, #APP_NAME + " - " + status)
  EndIf
EndProcedure

Procedure UpdateStartupMenuLabel()
  If startupEnabled
    SetMenuItemText(#TRAY_MENU, #MENU_STARTUP, "Disable Run at Startup")
  Else
    SetMenuItemText(#TRAY_MENU, #MENU_STARTUP, "Enable Run at Startup")
  EndIf
EndProcedure

Procedure UpdateLogMenuLabel()
  If loggingEnabled
    SetMenuItemText(#TRAY_MENU, #MENU_LOGTOGGLE, "Disable Logging")
  Else
    SetMenuItemText(#TRAY_MENU, #MENU_LOGTOGGLE, "Enable Logging")
  EndIf
EndProcedure

Procedure.i ClampPercent(value.i)
  If value < 0
    ProcedureReturn 0
  EndIf

  If value > 100
    ProcedureReturn 100
  EndIf

  ProcedureReturn value
EndProcedure

Procedure.i GetCurrentTrayImageNumber()
  If gTrayBusy
    ProcedureReturn #ICON_ACTIVE_BASE
  EndIf

  If gTrayBaseImageForPct
    ProcedureReturn gTrayBaseImageForPct
  EndIf

  ProcedureReturn #ICON_GREEN_BASE
EndProcedure

Procedure.i GetTrayBaseImageForUsage(usedPct.i)
  usedPct = ClampPercent(usedPct)

  If usedPct >= gTrayRedThresholdPct
    ProcedureReturn #ICON_RED_BASE
  EndIf

  If usedPct >= gTrayYellowThresholdPct
    ProcedureReturn #ICON_YELLOW_BASE
  EndIf

  ProcedureReturn #ICON_GREEN_BASE
EndProcedure

Procedure UpdateTrayIconVisual(usedPct.i, force.i)
  Protected nextImage.i = GetTrayBaseImageForUsage(usedPct)

  If force = #False And gTrayBusy = #False And nextImage = gTrayBaseImageForPct
    ProcedureReturn
  EndIf

  gTrayBaseImageForPct = nextImage

  If gTrayIconReady
    ChangeSysTrayIcon(#TRAY_ICON, GetTrayIconHandle(GetCurrentTrayImageNumber()))
  EndIf
EndProcedure

Procedure SetTrayBusyState(isBusy.i)
  gTrayBusy = Bool(isBusy <> 0)
  UpdateTrayIconVisual(GetUsedMemPercent(), #True)
EndProcedure

Procedure.b EnsureTrayIconReady()
  If gTrayIconReady
    ProcedureReturn #True
  EndIf

  If AddSysTrayIcon(#TRAY_ICON, WindowID(0), GetTrayIconHandle(GetCurrentTrayImageNumber()))
    gTrayIconReady = #True
    UpdateTrayTooltip("Idle")
    LogMessage("Tray icon registered")
  EndIf

  ProcedureReturn gTrayIconReady
EndProcedure

; ---------------------------------------------------------
; Native memory-list purge (no RAMMap dependency)
; ---------------------------------------------------------

; Uses NtSetSystemInformation(SystemMemoryListInformation, ...) to request trims.
; Note: these calls usually require admin + privileges to have impact.

; SYSTEM_INFORMATION_CLASS (winternl): SystemMemoryListInformation is commonly 80.
Enumeration 80
  #SystemMemoryListInformation
EndEnumeration

; SYSTEM_MEMORY_LIST_COMMAND values (must match Windows):
#MemoryEmptyWorkingSets           = 2
#MemoryFlushModifiedList          = 3
#MemoryPurgeStandbyList           = 4
#MemoryPurgeLowPriorityStandbyList = 5

; Privilege IDs for RtlAdjustPrivilege (checked best-effort)
#SE_PROFILE_SINGLE_PROCESS_PRIVILEGE = 13
#SE_DEBUG_PRIVILEGE                = 20


Global gRunInProgress.i = #False

Procedure.b QueueRunClearRam()
  Protected queued.b = #False

  LockMutex(gRunStateMutex)
  If quitProgram = #False And gRunInProgress = #False And gWorkerThread = 0
    gWorkerThread = CreateThread(@RunClearRam_Thread(), 0)
    queued = Bool(gWorkerThread <> 0)
  EndIf
  UnlockMutex(gRunStateMutex)

  If queued = #False And quitProgram = #False
    LogMessage("Run requested but already queued/running; ignoring")
  EndIf

  ProcedureReturn queued
EndProcedure

Procedure EnsureNtdll()
  If IsLibrary(gNtdll)
    ProcedureReturn
  EndIf

  gNtdll = OpenLibrary(#PB_Any, "ntdll.dll")
  If IsLibrary(gNtdll)
    NtSetSystemInformation = GetFunction(gNtdll, "NtSetSystemInformation")
    RtlAdjustPrivilege     = GetFunction(gNtdll, "RtlAdjustPrivilege")
  EndIf
EndProcedure

Procedure.b EnablePrivilege(privilegeId.l)
  EnsureNtdll()
  If RtlAdjustPrivilege = 0
    ProcedureReturn #False
  EndIf

  Protected wasEnabled.l
  Protected status.l = RtlAdjustPrivilege(privilegeId, 1, 0, @wasEnabled)
  ProcedureReturn Bool(status = 0)
EndProcedure

Procedure.b GetMemoryStatus( *ms.MEMORYSTATUSEX )
  *ms\dwLength = SizeOf(MEMORYSTATUSEX)
  ProcedureReturn Bool(GlobalMemoryStatusEx_(*ms) <> 0)
EndProcedure

Procedure.q GetAvailPhysBytes()
  Protected ms.MEMORYSTATUSEX
  If GetMemoryStatus(@ms)
    ProcedureReturn ms\ullAvailPhys
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i GetAvailPhysMB()
  ProcedureReturn GetAvailPhysBytes() / 1024 / 1024
EndProcedure

Procedure.i GetTotalPhysMB()
  Protected ms.MEMORYSTATUSEX
  If GetMemoryStatus(@ms)
    ProcedureReturn ms\ullTotalPhys / 1024 / 1024
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i GetUsedMemPercent()
  Protected ms.MEMORYSTATUSEX
  If GetMemoryStatus(@ms)
    Protected totalPhys.q = ms\ullTotalPhys
    If totalPhys <= 0
      ProcedureReturn 0
    EndIf

    Protected usedPhys.q = totalPhys - ms\ullAvailPhys
    If usedPhys < 0 : usedPhys = 0 : EndIf
    ProcedureReturn ClampPercent((usedPhys * 100) / totalPhys)
  EndIf
  ProcedureReturn 0
EndProcedure


Procedure.b ShouldTriggerThresholdClear()
  If gMemThresholdEnabled = #False
    gMemThresholdWasBelow = #False
    ProcedureReturn #False
  EndIf

  Protected availMB.i = GetAvailPhysMB()
  If availMB <= gMemThresholdAvailMB
    If gMemThresholdWasBelow = #False
      gMemThresholdWasBelow = #True
      ProcedureReturn #True
    EndIf
  Else
    gMemThresholdWasBelow = #False
  EndIf

  ProcedureReturn #False
EndProcedure

Declare ElevateAndClearOnce()

Global gLastNtStatus.l

Procedure.b NtPurgeMemoryList(command.l)
  EnsureNtdll()
  If NtSetSystemInformation = 0
    gLastNtStatus = -1
    LogMessage("ERROR: failed to load NtSetSystemInformation")
    ProcedureReturn #False
  EndIf

  Protected cmd.l = command
  Protected status.l = NtSetSystemInformation(#SystemMemoryListInformation, @cmd, SizeOf(Long))
  gLastNtStatus = status

  If status <> 0
    LogMessage("WARN: NtSetSystemInformation cmd=" + Str(command) + " status=0x" + RSet(Hex(status), 8, "0"))
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.l RunClearRamInternal(showUi.i)
  If showUi
    QueueTrayBusyState(#True)
    QueueTrayTooltip("Clearing RAM...")
  EndIf

  ; Try to enable privileges that make these calls effective
  EnablePrivilege(#SE_PROFILE_SINGLE_PROCESS_PRIVILEGE)
  EnablePrivilege(#SE_DEBUG_PRIVILEGE)

  Protected availBefore.q = GetAvailPhysBytes()
  LogMessage("Available RAM before: " + Str(availBefore / 1024 / 1024) + " MB")

  LogMessage("Flushing Modified Page List...")
  Protected okModified.b = NtPurgeMemoryList(#MemoryFlushModifiedList)

  LogMessage("Purging Standby List...")
  Protected okStandby.b = NtPurgeMemoryList(#MemoryPurgeStandbyList)

  LogMessage("Purging Priority 0 Standby List...")
  Protected okLow.b = NtPurgeMemoryList(#MemoryPurgeLowPriorityStandbyList)

  LogMessage("Emptying Working Sets...")
  Protected okWs.b = NtPurgeMemoryList(#MemoryEmptyWorkingSets)

  Delay(200)
  Protected availAfter.q = GetAvailPhysBytes()
  LogMessage("Available RAM after: " + Str(availAfter / 1024 / 1024) + " MB")

  If showUi
    QueueTrayBusyState(#False)
    If availAfter > availBefore
      QueueTrayTooltipOverride("Freed ~" + Str((availAfter - availBefore) / 1024 / 1024) + " MB", 5000)
    Else
      QueueTrayTooltip("No change (try Run as Admin)")
    EndIf
  EndIf

  If okModified And okStandby And okLow And okWs
    ProcedureReturn 0
  EndIf

  ; If any operation failed, return the last NTSTATUS we saw.
  ProcedureReturn gLastNtStatus
EndProcedure

Procedure RunClearRam()
  LockMutex(gRunStateMutex)
  If quitProgram Or gRunInProgress
    UnlockMutex(gRunStateMutex)
    LogMessage("Run requested but already running; ignoring")
    ProcedureReturn
  EndIf
  gRunInProgress = #True
  UnlockMutex(gRunStateMutex)

  Protected status.l = RunClearRamInternal(#True)
  If status = $C0000061 ; STATUS_PRIVILEGE_NOT_HELD
    LogMessage("Not enough privilege; requesting elevation")
    QueueTrayTooltip("Requesting admin...")
    ElevateAndClearOnce()
  EndIf

  LogMessage(#APP_NAME + " execution complete")

  LockMutex(gRunStateMutex)
  gRunInProgress = #False
  UnlockMutex(gRunStateMutex)
EndProcedure

Procedure ElevateAndClearOnce()
  Protected exe$ = ProgramFilename()
  Protected params$ = "--clearonce"
  ShellExecute_(0, "runas", exe$, params$, AppPath, 1)
EndProcedure

Procedure RunClearRam_Thread(*unused)
  RunClearRam()

  LockMutex(gRunStateMutex)
  gWorkerThread = 0
  UnlockMutex(gRunStateMutex)
EndProcedure

; ---------------------------------------------------------
; Timer thread
; ---------------------------------------------------------

Procedure TimerThread(*unused)
  LogMessage("Timer thread started. Interval: " + Str(IntervalMinutes) + " minutes")

  g_TimerNextRun = ElapsedMilliseconds() + IntervalMS

  While quitProgram = #False
    Delay(1000)

    If quitProgram : Break : EndIf

    If ShouldTriggerThresholdClear()
      LogMessage("Memory threshold reached (avail <= " + Str(gMemThresholdAvailMB) + "MB), triggering clean")
      QueueRunClearRam()
    EndIf

    If ElapsedMilliseconds() >= g_TimerNextRun
      QueueRunClearRam()
      g_TimerNextRun = ElapsedMilliseconds() + IntervalMS
    EndIf
  Wend

  LogMessage("Timer thread exiting")

  LockMutex(gRunStateMutex)
  gTimerThread = 0
  UnlockMutex(gRunStateMutex)
EndProcedure

; ---------------------------------------------------------
; Countdown formatter
; ---------------------------------------------------------

Procedure.s FormatCountdown(ms.q)
  If ms < 0 : ms = 0 : EndIf

  Protected totalSec = ms / 1000
  Protected min      = totalSec / 60
  Protected sec      = totalSec % 60

  ProcedureReturn Str(min) + "m " + RSet(Str(sec), 2, "0") + "s"
EndProcedure

Procedure ReloadSettingsFromFile()
  LoadSettings()
  gMemThresholdWasBelow = Bool(gMemThresholdEnabled And GetAvailPhysMB() <= gMemThresholdAvailMB)
  UpdateStartupMenuLabel()
  UpdateLogMenuLabel()
  UpdateTrayIconVisual(GetUsedMemPercent(), #True)
  MessageRequester("Settings Reloaded", "Settings have been reloaded from " + #INI_FILE, #PB_MessageRequester_Info)
  LogMessage("Settings manually reloaded from INI file")
EndProcedure

Procedure EditSettings()
  Protected w = 350
  Protected h = 320
  Protected win = OpenWindow(#PB_Any, 0, 0, w, h, "Edit Settings", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If win = 0 : ProcedureReturn : EndIf

  Protected ly = 15
  TextGadget(#PB_Any, 15, ly, 150, 20, "Interval (Minutes):")
  Protected gadInterval = StringGadget(#PB_Any, 170, ly, 150, 20, Str(IntervalMinutes), #PB_String_Numeric)
  
  ly + 30
  Protected gadLogging = CheckBoxGadget(#PB_Any, 15, ly, 300, 20, "Enable Logging")
  SetGadgetState(gadLogging, loggingEnabled)

  ly + 30
  Protected gadRotate = CheckBoxGadget(#PB_Any, 15, ly, 300, 20, "Enable Log Rotation")
  SetGadgetState(gadRotate, gLogRotateEnabled)

  ly + 30
  TextGadget(#PB_Any, 15, ly, 150, 20, "Rotate Keep Files:")
  Protected gadRotKeep = StringGadget(#PB_Any, 170, ly, 150, 20, Str(gLogRotateKeep), #PB_String_Numeric)

  ly + 30
  TextGadget(#PB_Any, 15, ly, 150, 20, "Rotate Max KB:")
  Protected gadRotMax = StringGadget(#PB_Any, 170, ly, 150, 20, Str(gLogRotateMaxBytes / 1024), #PB_String_Numeric)

  ly + 30
  TextGadget(#PB_Any, 15, ly, 150, 20, "Yellow At Used %:")
  Protected gadTrayYellow = StringGadget(#PB_Any, 170, ly, 150, 20, Str(gTrayYellowThresholdPct), #PB_String_Numeric)

  ly + 30
  TextGadget(#PB_Any, 15, ly, 150, 20, "Red At Used %:")
  Protected gadTrayRed = StringGadget(#PB_Any, 170, ly, 150, 20, Str(gTrayRedThresholdPct), #PB_String_Numeric)

  ly + 50
  Protected gadOk = ButtonGadget(#PB_Any, w - 180, h - 40, 80, 25, "OK")
  Protected gadCancel = ButtonGadget(#PB_Any, w - 90, h - 40, 80, 25, "Cancel")

  Protected done = #False, changed = #False
  Repeat
    Protected ev = WaitWindowEvent()
    If ev = #PB_Event_CloseWindow
      done = #True
    ElseIf ev = #PB_Event_Gadget
      Protected g = EventGadget()
      If g = gadOk
        Protected newInt = Val(GetGadgetText(gadInterval))
        If newInt > 0 And newInt <> IntervalMinutes
          IntervalMinutes = newInt
          IntervalMS = IntervalMinutes * 60000
          g_TimerNextRun = ElapsedMilliseconds() + IntervalMS
          changed = #True
        EndIf

        If GetGadgetState(gadLogging) <> loggingEnabled
          loggingEnabled = GetGadgetState(gadLogging)
          changed = #True
        EndIf

        If GetGadgetState(gadRotate) <> gLogRotateEnabled
          gLogRotateEnabled = GetGadgetState(gadRotate)
          changed = #True
        EndIf

        Protected newKeep = Val(GetGadgetText(gadRotKeep))
        If newKeep > 0 And newKeep <> gLogRotateKeep
          gLogRotateKeep = newKeep
          changed = #True
        EndIf

        Protected newMax = Val(GetGadgetText(gadRotMax))
        If newMax > 0 And (newMax * 1024) <> gLogRotateMaxBytes
          gLogRotateMaxBytes = newMax * 1024
          changed = #True
        EndIf

        Protected oldTrayYellow.i = gTrayYellowThresholdPct
        Protected oldTrayRed.i = gTrayRedThresholdPct
        gTrayYellowThresholdPct = Val(GetGadgetText(gadTrayYellow))
        gTrayRedThresholdPct = Val(GetGadgetText(gadTrayRed))
        NormalizeTrayUsageThresholds()
        If gTrayYellowThresholdPct <> oldTrayYellow Or gTrayRedThresholdPct <> oldTrayRed
          changed = #True
        EndIf

        If changed
          SaveSettings()
          UpdateLogMenuLabel()
          UpdateTrayIconVisual(GetUsedMemPercent(), #True)
          LogMessage("Settings updated via dialog")
        EndIf
        done = #True
      ElseIf g = gadCancel
        done = #True
      EndIf
    EndIf
  Until done
  CloseWindow(win)
EndProcedure

; ---------------------------------------------------------
; About dialog
; ---------------------------------------------------------

Procedure ShowAbout()
  Protected logState.s

  If loggingEnabled
    logState = "Enabled"
  Else
    logState = "Disabled"
  EndIf

  Protected msg.s
  msg = #APP_NAME + " - " + version + #CRLF$ +
        "Interval: " + Str(IntervalMinutes) + " minutes" + #CRLF$ +
        "Memory threshold: " + Str(gMemThresholdEnabled) + " @ " + Str(gMemThresholdAvailMB) + "MB available" + #CRLF$ +
        "Logging: " + logState + #CRLF$ +
        "INI file: " + "files\" + #INI_FILE + #CRLF$ +
        "Contact: " + #EMAIL_NAME + #CRLF$ +
        "Website: https://github.com/zonemaster60"

  MessageRequester("About " + #APP_NAME, msg, #PB_MessageRequester_Info)
EndProcedure

; ---------------------------------------------------------
; Main
; ---------------------------------------------------------

LoadSettings()

; Initialize threshold latch based on current usage
gMemThresholdWasBelow = Bool(gMemThresholdEnabled And GetAvailPhysMB() <= gMemThresholdAvailMB)

If gSingleRunMode
  ; Elevated helper mode: clear once then exit.
  LogMessage("--clearonce: running one purge")
  RunClearRamInternal(#False)
  ShutdownAndExit()
EndIf

If gInstallStartupTaskMode
  LogMessage("--installstartup: ensuring startup task")
  AddToStartup()
  ShutdownAndExit()
EndIf

If gRemoveStartupTaskMode
  LogMessage("--removestartup: removing startup task")
  RemoveFromStartup()
  ShutdownAndExit()
EndIf

; Best-effort cleanup of old registry startup entry.
RemoveLegacyStartupRegistryEntry()

; Do not create/remove tasks automatically at every launch.
; The tray menu toggle controls whether the task exists.
LogMessage(#APP_NAME + " starting up...")


; load the icons
Global IconLibraryPath.s = AppPath + "files\ClearRam.icl"

If LoadTrayIconsFromLibrary(IconLibraryPath) = 0
  MessageRequester("Error", "Failed to load tray icons from: " + IconLibraryPath, #PB_MessageRequester_Error)
  ShutdownAndExit()
EndIf

UpdateTrayIconVisual(GetUsedMemPercent(), #True)

; Hidden window
OpenWindow(0, 0, 0, 10, 10, #APP_NAME, #PB_Window_Invisible)

; Countdown timer (1 second)
AddWindowTimer(0, 2, 1000)

; Tray icon
EnsureTrayIconReady()

; Tray menu
CreatePopupMenu(#TRAY_MENU)
MenuItem(#MENU_RUNNOW,     "Run Now")
MenuBar()
MenuItem(#MENU_STARTUP,    "")
MenuItem(#MENU_LOGTOGGLE,  "")
MenuBar()
MenuItem(#MENU_EDITSETTINGS, "Edit Settings")
MenuItem(#MENU_MEMTHRESHOLD, "Memory Threshold...")
MenuItem(#MENU_RELOADSETTINGS, "Reload Settings")
MenuBar()
MenuItem(#MENU_ABOUT,      "About")
MenuItem(#MENU_EXIT,       "Exit")

; Ensure menu reflects actual Task Scheduler state
Define actualStartup.i = IsInStartup()
If startupEnabled <> actualStartup
  startupEnabled = actualStartup
  SaveSettings()
EndIf

UpdateStartupMenuLabel()
UpdateLogMenuLabel()


; Start timer thread
gTimerThread = CreateThread(@TimerThread(), 0)

; Initialize countdown
g_TimerNextRun = ElapsedMilliseconds() + IntervalMS

; run initially
QueueRunClearRam()

; ---------------------------------------------------------
; Main event loop
; ---------------------------------------------------------

Define event, menuID, remaining.q, text.s

Repeat
  ApplyPendingTrayUpdates()
  event = WaitWindowEvent(100)
  ApplyPendingTrayUpdates()

  Select event

    Case #PB_Event_Timer
      If EventTimer() = 2
        EnsureTrayIconReady()
        Define usedPct.i = GetUsedMemPercent()
        UpdateTrayIconVisual(usedPct, #False)

        ; If we recently showed a "Freed" message, hold it briefly.
        If gTooltipOverrideUntil > ElapsedMilliseconds()
          SysTrayIconToolTip(#TRAY_ICON, gTooltipOverrideText)
        ElseIf gTrayBusy = #False
          gTooltipOverrideUntil = 0
          remaining = g_TimerNextRun - ElapsedMilliseconds()
          If remaining < 0 : remaining = 0 : EndIf
          Define availMB.i = GetAvailPhysMB()

          ; Tray icon tooltips are length-limited (often ~64 chars).
          ; Keep it compact + single-line so it doesn't truncate.
          text = "Avl:" + Str(availMB) + "MB Usg:" + Str(usedPct) + "% "
          If gMemThresholdEnabled
            text = text + "Trg<=" + Str(gMemThresholdAvailMB) + "MB "
          Else
            text = text + "Trg:off"
          EndIf
          text = text + "Nxt:" + FormatCountdown(remaining)

          SysTrayIconToolTip(#TRAY_ICON, text)
        EndIf
      EndIf
      
    Case #PB_Event_SysTray
      If EventType() = #PB_EventType_RightClick
        DisplayPopupMenu(#TRAY_MENU, WindowID(0))
      EndIf
      If EventType() = #PB_EventType_LeftClick
         QueueRunClearRam()
      EndIf
      
    Case #PB_Event_Menu
      menuID = EventMenu()

      Select menuID

        Case #MENU_RUNNOW
          QueueRunClearRam()
            
        Case #MENU_STARTUP
          If startupEnabled
            RemoveFromStartup()
          Else
            AddToStartup()
          EndIf
          startupEnabled = IsInStartup()
          UpdateStartupMenuLabel()
          SaveSettings()

        Case #MENU_LOGTOGGLE
          loggingEnabled ! 1
          UpdateLogMenuLabel()
          SaveSettings()
          If loggingEnabled
            LogMessage("Logging ENABLED from menu.")
          EndIf

        Case #MENU_EDITSETTINGS
          EditSettings()

        Case #MENU_MEMTHRESHOLD
          EditMemoryThresholdSlider()

        Case #MENU_RELOADSETTINGS
          ReloadSettingsFromFile()

        Case #MENU_ABOUT
          ShowAbout()

        Case #MENU_EXIT
          Exit()
          Continue
          
      EndSelect

  EndSelect

Until quitProgram = #True
; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 48
; Folding = ----------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = ClearRam.ico
; Executable = ..\ClearRam.exe
; DisableDebugger
; IncludeVersionInfo
; VersionField0 = 1,0,1,6
; VersionField1 = 1,0,1,6
; VersionField2 = ZoneSoft
; VersionField3 = ClearRam
; VersionField4 = 1.0.1.6
; VersionField5 = 1.0.1.6
; VersionField6 = Clears RAM using native Windows APIs
; VersionField7 = ClearRam
; VersionField8 = ClearRam.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60