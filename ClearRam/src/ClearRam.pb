EnableExplicit

; ---------------------------------------------------------
; Tray & UI constants
; ---------------------------------------------------------

#TRAY_ICON       = 1
#TRAY_MENU       = 2
#MENU_STARTUP    = 10
#MENU_LOGTOGGLE  = 11
#MENU_ABOUT      = 12
#MENU_EXIT       = 13
#ICON_IDLE       = 100
#ICON_ACTIVE     = 101

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
Global version.s = "v1.0.0.4"

; Logging paths + rotation
#LOG_FILE        = "ClearRam.log"
Global gLogPath.s = ""
Global gLogRotateEnabled.i = #True
Global gLogRotateMaxBytes.q = 1024 * 1024 ; 1 MiB
Global gLogRotateKeep.i = 3

; Paths / config
#INI_FILE        = "ClearRam.ini"
#APP_NAME        = "ClearRam"
#EMAIL_NAME      = "zonemaster60@gmail.com"

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

  Protected size.q = FileSize(gLogPath)
  If size < 0
    ProcedureReturn
  EndIf

  If size <= gLogRotateMaxBytes
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
EndProcedure

Procedure LogMessage(msg.s)
  If loggingEnabled = #False Or gLogPath = ""
    ProcedureReturn
  EndIf

  Protected file = OpenFile(#PB_Any, gLogPath)
  If file = 0
    file = CreateFile(#PB_Any, gLogPath)
  EndIf

  If file
    FileSeek(file, Lof(file))
    WriteStringN(file, FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + msg)
    CloseFile(file)
  EndIf
EndProcedure

; ---------------------------------------------------------
; Load INI settings
; ---------------------------------------------------------

Procedure LoadSettings()
  Protected iniFile.s = AppPath + #INI_FILE

  ; Defaults
  IntervalMinutes = 5
  loggingEnabled  = #True
  startupEnabled  = 0
  gLogRotateEnabled = #True
  gLogRotateMaxBytes = 1024 * 1024
  gLogRotateKeep = 3

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
      ClosePreferences()
    EndIf
  EndIf

  IntervalMS = IntervalMinutes * 60000

  gLogPath = AppPath + #LOG_FILE
  LogRotateIfNeeded()

   LogMessage("Loaded settings: Interval=" + Str(IntervalMinutes) + " minutes, Logging=" + Str(loggingEnabled) +
              ", Rotate=" + Str(gLogRotateEnabled) + " keep=" + Str(gLogRotateKeep) + " maxKB=" + Str(gLogRotateMaxBytes / 1024))

EndProcedure

Procedure SaveSettings()
  Protected iniFile.s = AppPath + #INI_FILE

  If CreatePreferences(iniFile)
    WritePreferenceInteger("IntervalMinutes", IntervalMinutes)
    WritePreferenceInteger("LoggingEnabled", loggingEnabled)
    WritePreferenceInteger("RunAtStartup", startupEnabled)
    WritePreferenceInteger("LogRotateEnabled", gLogRotateEnabled)
    WritePreferenceInteger("LogRotateKeep", gLogRotateKeep)
    WritePreferenceInteger("LogRotateMaxKB", gLogRotateMaxBytes / 1024)
    ClosePreferences()
    LogMessage("Settings saved.")
  EndIf
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

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    LogMessage("Program exiting")
    CloseHandle_(hMutex)
    End
  EndIf
EndProcedure

Procedure SetTooltipOverride(text$, holdMs.q)
  gTooltipOverrideText = text$
  gTooltipOverrideUntil = ElapsedMilliseconds() + holdMs
  SysTrayIconToolTip(#TRAY_ICON, gTooltipOverrideText)
EndProcedure

Procedure UpdateTrayTooltip(status.s)
  SysTrayIconToolTip(#TRAY_ICON, #APP_NAME + " - " + status)
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

; ---------------------------------------------------------
; Native memory-list purge (no RAMMap dependency)
; ---------------------------------------------------------

; Uses NtSetSystemInformation(SystemMemoryListInformation, ...) to request trims.
; Note: these calls usually require admin + privileges to have impact.

Prototype.l ProtoNtSetSystemInformation(SystemInformationClass.l, SystemInformation.i, SystemInformationLength.l)
; Use LONGs here to avoid PB's "native types with pointers" restrictions
Prototype.l ProtoRtlAdjustPrivilege(Privilege.l, Enable.l, CurrentThread.l, *Enabled)

Global gNtdll.i
Global NtSetSystemInformation.ProtoNtSetSystemInformation
Global RtlAdjustPrivilege.ProtoRtlAdjustPrivilege

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

Procedure EnsureNtdll()
  If gNtdll
    ProcedureReturn
  EndIf

  gNtdll = OpenLibrary(#PB_Any, "ntdll.dll")
  If gNtdll
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

Procedure.q GetAvailPhysBytes()
  Protected ms.MEMORYSTATUSEX
  ms\dwLength = SizeOf(MEMORYSTATUSEX)
  If GlobalMemoryStatusEx_(@ms) = 0
    ProcedureReturn 0
  EndIf
  ProcedureReturn ms\ullAvailPhys
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
    ChangeSysTrayIcon(#TRAY_ICON, ImageID(#ICON_ACTIVE))
    UpdateTrayTooltip("Clearing RAM...")
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
    If availAfter > availBefore
      SetTooltipOverride("Freed ~" + Str((availAfter - availBefore) / 1024 / 1024) + " MB", 5000)
    Else
      UpdateTrayTooltip("No change (try Run as Admin)")
    EndIf
    ChangeSysTrayIcon(#TRAY_ICON, ImageID(#ICON_IDLE))
  EndIf

  If okModified And okStandby And okLow And okWs
    ProcedureReturn 0
  EndIf

  ; If any operation failed, return the last NTSTATUS we saw.
  ProcedureReturn gLastNtStatus
EndProcedure

Procedure RunClearRam()
  If gRunInProgress
    LogMessage("Run requested but already running; ignoring")
    ProcedureReturn
  EndIf

  gRunInProgress = #True

  Protected status.l = RunClearRamInternal(#True)
  If status = $C0000061 ; STATUS_PRIVILEGE_NOT_HELD
    LogMessage("Not enough privilege; requesting elevation")
    UpdateTrayTooltip("Requesting admin...")
    ElevateAndClearOnce()
  EndIf

  LogMessage(#APP_NAME + " execution complete")

  gRunInProgress = #False
EndProcedure

Procedure ElevateAndClearOnce()
  Protected exe$ = ProgramFilename()
  Protected params$ = "--clearonce"
  ShellExecute_(0, "runas", exe$, params$, AppPath, 1)
EndProcedure

Procedure RunClearRam_Thread(*unused)
  RunClearRam()
EndProcedure

; ---------------------------------------------------------
; Timer thread
; ---------------------------------------------------------

Procedure TimerThread(*unused)
  Protected i

  LogMessage("Timer thread started. Interval: " + Str(IntervalMinutes) + " minutes")

  g_TimerNextRun = ElapsedMilliseconds() + IntervalMS

  While quitProgram = #False

    For i = 1 To IntervalMS / 1000
      If quitProgram : Break : EndIf
      Delay(1000)
    Next

    If quitProgram : Break : EndIf

    CreateThread(@RunClearRam_Thread(), 0)
    g_TimerNextRun = ElapsedMilliseconds() + IntervalMS

  Wend

  LogMessage("Timer thread exiting")
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
  msg = #APP_NAME + " - " + version + " - ram cleaner" + #CRLF$ +
        "Interval: " + Str(IntervalMinutes) + " minutes" + #CRLF$ +
        "Logging: " + logState + #CRLF$ +
        "INI file: " + #INI_FILE + #CRLF$ +
        "Contact: David Scouten (" + #EMAIL_NAME + ")" + #CRLF$ +
        "Website: https://github.com/zonemaster60"

  MessageRequester("About " + #APP_NAME, msg, #PB_MessageRequester_Info)
EndProcedure

; ---------------------------------------------------------
; Main
; ---------------------------------------------------------

LoadSettings()

If gSingleRunMode
  ; Elevated helper mode: clear once then exit.
  LogMessage("--clearonce: running one purge")
  RunClearRamInternal(#False)
  End
EndIf

If gInstallStartupTaskMode
  LogMessage("--installstartup: ensuring startup task")
  AddToStartup()
  End
EndIf

If gRemoveStartupTaskMode
  LogMessage("--removestartup: removing startup task")
  RemoveFromStartup()
  End
EndIf

; Best-effort cleanup of old registry startup entry.
RemoveLegacyStartupRegistryEntry()

; Do not create/remove tasks automatically at every launch.
; The tray menu toggle controls whether the task exists.
LogMessage(#APP_NAME + " starting up...")


; load the icons
Global IconIdlePath.s   = AppPath + "files\" + #APP_NAME + "-idle.ico"
Global IconActivePath.s = AppPath + "files\" + #APP_NAME + "-active.ico"

If LoadImage(#ICON_IDLE, IconIdlePath) = 0
  MessageRequester("Error", "Failed to load idle icon at: " + IconIdlePath, #PB_MessageRequester_Error)
  CloseHandle_(hMutex)
  End
EndIf

If LoadImage(#ICON_ACTIVE, IconActivePath) = 0
  MessageRequester("Error", "Failed to load active icon at: " + IconActivePath, #PB_MessageRequester_Error)
  CloseHandle_(hMutex)
  End
EndIf

; Hidden window
OpenWindow(0, 0, 0, 10, 10, #APP_NAME, #PB_Window_Invisible)

; Countdown timer (1 second)
AddWindowTimer(0, 2, 1000)

; Tray icon
AddSysTrayIcon(#TRAY_ICON, WindowID(0), ImageID(#ICON_IDLE))
UpdateTrayTooltip("Idle")

; Tray menu
CreatePopupMenu(#TRAY_MENU)
MenuItem(#MENU_STARTUP,    "")
MenuItem(#MENU_LOGTOGGLE,  "")
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
CreateThread(@TimerThread(), 0)

; Initialize countdown
g_TimerNextRun = ElapsedMilliseconds() + IntervalMS

; run initially
CreateThread(@RunClearRam_Thread(), 0)

; ---------------------------------------------------------
; Main event loop
; ---------------------------------------------------------

Define event, menuID, remaining.q, text.s

Repeat
  event = WaitWindowEvent(100)

  Select event

    Case #PB_Event_Timer
      If EventTimer() = 2
        ; If we recently showed a "Freed" message, hold it briefly.
        If gTooltipOverrideUntil > ElapsedMilliseconds()
          SysTrayIconToolTip(#TRAY_ICON, gTooltipOverrideText)
        Else
          gTooltipOverrideUntil = 0
          remaining = g_TimerNextRun - ElapsedMilliseconds()
          If remaining < 0 : remaining = 0 : EndIf
          text = "(Left Click to Run Now);" + #CRLF$ +
                 "Next RAM clear in: " + FormatCountdown(remaining)
          SysTrayIconToolTip(#TRAY_ICON, text)
        EndIf
      EndIf
      
    Case #PB_Event_SysTray
      If EventType() = #PB_EventType_RightClick
        DisplayPopupMenu(#TRAY_MENU, WindowID(0))
      EndIf
      If EventType() = #PB_EventType_LeftClick
         CreateThread(@RunClearRam_Thread(), 0)
      EndIf
      
    Case #PB_Event_Menu
      menuID = EventMenu()

      Select menuID
          
        Case #MENU_STARTUP
          If startupEnabled
            startupEnabled = #False
            RemoveFromStartup()
          Else
            startupEnabled = #True
            AddToStartup()
          EndIf
          UpdateStartupMenuLabel()
          SaveSettings()

        Case #MENU_LOGTOGGLE
          loggingEnabled ! 1
          UpdateLogMenuLabel()
          SaveSettings()
          If loggingEnabled
            LogMessage("Logging ENABLED from menu.")
          EndIf

        Case #MENU_ABOUT
          ShowAbout()

        Case #MENU_EXIT
          Exit()
          Continue
          
      EndSelect

  EndSelect

Until quitProgram = #True
; IDE Options = PureBasic 6.30 beta 6 (Windows - x64)
; CursorPosition = 31
; FirstLine = 12
; Folding = ------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = ..\files\ClearRam.ico
; Executable = ..\ClearRam.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,4
; VersionField1 = 1,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = ClearRam
; VersionField4 = 1.0.0.4
; VersionField5 = 1.0.0.4
; VersionField6 = Clears RAM using native Windows APIs
; VersionField7 = ClearRam
; VersionField8 = ClearRam.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60