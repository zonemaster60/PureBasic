EnableExplicit

; ---------------------------------------------------------
; Tray & UI constants
; ---------------------------------------------------------

#TRAY_ICON       = 1
#TRAY_MENU       = 2
#MENU_RUNNOW     = 10
#MENU_STARTUP    = 11
#MENU_LOGTOGGLE  = 12
#MENU_ABOUT      = 13
#MENU_EXIT       = 14
#ICON_IDLE       = 100
#ICON_ACTIVE     = 101

Global quitProgram      = #False
Global startupEnabled   = #False
Global AppPath.s        = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Global interval + countdown timestamp
Global IntervalMinutes  = 5
Global IntervalMS       = 5 * 60000
Global g_TimerNextRun.q = 0

; Logging toggle
Global loggingEnabled   = #True

; Paths / config
#RAMMAP_REL_PATH = "files\RAMMap64.exe"
#LOG_FILE        = "ClearRam.log"
#INI_FILE        = "ClearRam.ini"
#APP_NAME        = "ClearRam"
#EMAIL_NAME      = "zonemaster60@gmail.com"
#MAX_RUNTIME_MS  = 15000   ; 15 seconds

; ---------------------------------------------------------
; Logging helper
; ---------------------------------------------------------

Procedure LogMessage(msg.s)
  If loggingEnabled = #False
    DeleteFile(#LOG_FILE)
    ProcedureReturn
  EndIf

  Protected file = OpenFile(#PB_Any, AppPath + #LOG_FILE, #PB_File_Append)
  If file
    WriteStringN(file, FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + msg)
    CloseFile(file)
  EndIf
EndProcedure

; ---------------------------------------------------------
; Load INI settings
; ---------------------------------------------------------

Procedure LoadSettings()
  Protected iniFile.s = AppPath + #INI_FILE

  If OpenPreferences(iniFile)
    IntervalMinutes = ReadPreferenceInteger("IntervalMinutes", 5)
    If IntervalMinutes <= 0 : IntervalMinutes = 5 : EndIf

    loggingEnabled = ReadPreferenceInteger("LoggingEnabled", 1)
    If loggingEnabled <> 0 And loggingEnabled <> 1
      loggingEnabled = #True
    EndIf

    ClosePreferences()
  Else
    CreatePreferences(iniFile)
    WritePreferenceInteger("IntervalMinutes", 5)
    WritePreferenceInteger("LoggingEnabled", 1)
    ClosePreferences()

    IntervalMinutes = 5
    loggingEnabled  = #True
  EndIf

  IntervalMS = IntervalMinutes * 60000
  LogMessage("Loaded settings: Interval=" + Str(IntervalMinutes) + " minutes, Logging=" + Str(loggingEnabled))
EndProcedure

Procedure SaveSettings()
  Protected iniFile.s = AppPath + #INI_FILE

  If CreatePreferences(iniFile)
    WritePreferenceInteger("IntervalMinutes", IntervalMinutes)
    WritePreferenceInteger("LoggingEnabled", loggingEnabled)
    ClosePreferences()
    LogMessage("Settings saved.")
  EndIf
EndProcedure

; ---------------------------------------------------------
; Registry helpers
; ---------------------------------------------------------

Procedure AddToStartup()
  Protected exe.s = Chr(34) + ProgramFilename() + Chr(34)
  Protected cmd.s = "reg add HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v " + #APP_NAME + " /t REG_SZ /d " + exe + " /f"
  RunProgram("cmd.exe", "/c " + cmd, "", #PB_Program_Hide)
  LogMessage("Startup entry added: " + exe)
EndProcedure

Procedure RemoveFromStartup()
  Protected cmd.s = "reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v " + #APP_NAME + " /f"
  RunProgram("cmd.exe", "/c " + cmd, "", #PB_Program_Hide)
  LogMessage("Startup entry removed.")
EndProcedure

Procedure.i IsInStartup()
  Protected result  = #False
  Protected cmd.s   = "reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v " + #APP_NAME
  Protected program = RunProgram("cmd.exe", "/c " + cmd, "", #PB_Program_Open | #PB_Program_Read)

  If program
    While ProgramRunning(program)
      If AvailableProgramOutput(program)
        If FindString(LCase(ReadProgramString(program)), LCase(#APP_NAME))
          result = #True
        EndIf
      EndIf
    Wend
    CloseProgram(program)
  EndIf

  ProcedureReturn result
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
    End
  EndIf
EndProcedure

Procedure UpdateTrayTooltip(status.s)
  SysTrayIconToolTip(#TRAY_ICON, #APP_NAME + " - " + status)
EndProcedure

Procedure UpdateLogMenuLabel()
  If loggingEnabled
    SetMenuItemText(#TRAY_MENU, #MENU_LOGTOGGLE, "Disable Logging")
  Else
    SetMenuItemText(#TRAY_MENU, #MENU_LOGTOGGLE, "Enable Logging")
  EndIf
EndProcedure

; ---------------------------------------------------------
; RAMMap runner
; ---------------------------------------------------------

Procedure RunRAMMap()
  Protected program, startTime.q
  Protected exePath.s = AppPath + #RAMMAP_REL_PATH

  If FileSize(exePath) = -1
    LogMessage("ERROR: RAMMap64.exe not found at: " + exePath)
    UpdateTrayTooltip("ERROR: RAMMap64.exe not found!")
    ProcedureReturn
  EndIf

  ChangeSysTrayIcon(#TRAY_ICON, ImageID(#ICON_ACTIVE))
  UpdateTrayTooltip("Running ClearRam...")

  program = RunProgram(exePath, "-Em", "", #PB_Program_Open | #PB_Program_Wait)
  LogMessage("Emptying Modified Page List...")

  program = RunProgram(exePath, "-Es", "", #PB_Program_Open | #PB_Program_Wait)
  LogMessage("Emptying System Working Sets...")

  program = RunProgram(exePath, "-Et", "", #PB_Program_Open | #PB_Program_Wait)
  LogMessage("Emptying Standby List...")

  program = RunProgram(exePath, "-Ew", "", #PB_Program_Open | #PB_Program_Wait)
  LogMessage("Emptying Working Sets...")

  program = RunProgram(exePath, "-E0", "", #PB_Program_Open | #PB_Program_Wait)
  LogMessage("Emptying Priority 0 Standby List...")

  startTime = ElapsedMilliseconds()

  While ProgramRunning(program)
    Delay(50)
    If ElapsedMilliseconds() - startTime > #MAX_RUNTIME_MS
      LogMessage("ClearRam timeout — killing process")
      KillProgram(program)
      Break
    EndIf
  Wend

  LogMessage("ClearRam execution complete")

  ChangeSysTrayIcon(#TRAY_ICON, ImageID(#ICON_IDLE))
  UpdateTrayTooltip("Idle")
EndProcedure

Procedure RunRAMMap_Thread(*unused)
  RunRAMMap()
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

    CreateThread(@RunRAMMap_Thread(), 0)
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
  msg = #APP_NAME + " v1.0.0.0 - ram cleaner" + #CRLF$ +
        "Interval: " + Str(IntervalMinutes) + " minutes" + #CRLF$ +
        "Logging: " + logState + #CRLF$ +
        "INI file: " + #INI_FILE + #CRLF$ +
        "Contact: David Scouten (" + #EMAIL_NAME + ")" + #CRLF$ +
        "RAMMap is a product of Sysinternals Mark Russinovich"

  MessageRequester("About " + #APP_NAME, msg, #PB_MessageRequester_Info)
EndProcedure

; ---------------------------------------------------------
; Main
; ---------------------------------------------------------

LoadSettings()
LogMessage(#APP_NAME + " starting up...")

; load the icons
Global IconIdlePath.s   = AppPath + "files\ClearRam-idle.ico"
Global IconActivePath.s = AppPath + "files\ClearRam-active.ico"

If LoadImage(#ICON_IDLE, IconIdlePath) = 0
  MessageRequester("Error", "Failed to load idle icon at: " + IconIdlePath, #PB_MessageRequester_Error)
  End
EndIf

If LoadImage(#ICON_ACTIVE, IconActivePath) = 0
  MessageRequester("Error", "Failed to load active icon at: " + IconActivePath, #PB_MessageRequester_Error)
  End
EndIf

; Check for running instance
If FindWindow_(0, #APP_NAME)
  MessageRequester("Info", "ClearRam is already running.", #PB_MessageRequester_Info)
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
MenuItem(#MENU_RUNNOW,     "Run Now")
MenuBar()
MenuItem(#MENU_STARTUP,    "Toggle Startup")
MenuItem(#MENU_LOGTOGGLE,  "")
MenuBar()
MenuItem(#MENU_ABOUT,      "About")
MenuItem(#MENU_EXIT,       "Exit")

UpdateLogMenuLabel()

startupEnabled = IsInStartup()

; Start timer thread
CreateThread(@TimerThread(), 0)

; Initialize countdown
g_TimerNextRun = ElapsedMilliseconds() + IntervalMS

; ---------------------------------------------------------
; Main event loop
; ---------------------------------------------------------

Define event, menuID, remaining.q, text.s

Repeat
  event = WaitWindowEvent(100)

  Select event

    Case #PB_Event_Timer
      If EventTimer() = 2
        remaining = g_TimerNextRun - ElapsedMilliseconds()
        If remaining < 0 : remaining = 0 : EndIf
        text = "Next RAM clear in: " + FormatCountdown(remaining)
        SysTrayIconToolTip(#TRAY_ICON, text)
      EndIf

    Case #PB_Event_SysTray
      If EventType() = #PB_EventType_RightClick
        DisplayPopupMenu(#TRAY_MENU, WindowID(0))
      EndIf
      If EventType() = #PB_EventType_LeftClick
        CreateThread(@RunRAMMap_Thread(), 0)
      EndIf
      
    Case #PB_Event_Menu
      menuID = EventMenu()

      Select menuID

        Case #MENU_RUNNOW
          CreateThread(@RunRAMMap_Thread(), 0)

        Case #MENU_STARTUP
          If startupEnabled
            RemoveFromStartup()
            startupEnabled = #False
          Else
            AddToStartup()
            startupEnabled = #True
          EndIf

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
; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 271
; FirstLine = 252
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; DllProtection
; UseIcon = ..\files\ClearRam-idle.ico
; Executable = ClearRam.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = ClearRam
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = Clears Ram using Sysinternals RAMMap
; VersionField7 = ClearRam.exe
; VersionField8 = ClearRam.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster@yahoo.com
; VersionField14 = https://github.com/zonemaster60