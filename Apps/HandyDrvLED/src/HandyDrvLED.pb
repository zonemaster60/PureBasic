; Author: David Scouten
; zonemaster@yahoo.com
; PureBasic v6.30 (x64)
; Highly improved version: Threaded, DPI-aware, Modular, Localized

#APP_NAME = "HandyDrvLED"

IncludeFile "Globals.pbi"
IncludeFile "Localization.pbi"
IncludeFile "DiskLogic.pbi"
IncludeFile "UI_Drives.pbi"

; Prevent multiple instances (don't rely on window title text)
; Allow helper modes to run even if the tray app is running.
Global hMutex.i
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
  If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
    CloseHandle_(hMutex)
    End
  EndIf

Procedure.s FindCmdArgValue(name.s)
  Protected i.i, key.s = LCase(name)
  For i = 0 To CountProgramParameters() - 1
    If LCase(ProgramParameter(i)) = key
      If i + 1 <= CountProgramParameters() - 1 : ProcedureReturn ProgramParameter(i + 1) : EndIf
      ProcedureReturn ""
    EndIf
  Next
  ProcedureReturn ""
EndProcedure

; --- Initialization ---
Procedure InitializeApp()
  ; Helper-modes for startup task management
  If CountProgramParameters() > 0
    Select LCase(ProgramParameter(0))
      Case "--installstartup"
        Define targetUser.s = FindCmdArgValue("--user")
        If InstallStartupTask(targetUser) : End : Else : End : EndIf
      Case "--removestartup"
        If RemoveFromStartup() : End : Else : End : EndIf
    EndSelect
  EndIf

  LoadSettings()
  numicl = CountIconLibraries()
  If StartWithRandomIconSet : icon1 = Random(numicl, 1) : Else : icon1 = DefaultIconSet : EndIf
  icon1 = ClampI(icon1, 1, numicl)
  If Not LoadIconSet(icon1) : LogLine("Failed to load icon set") : End : EndIf
  
  If OpenPhysDrive(0) = #INVALID_HANDLE_VALUE
    MessageRequester(Lng\AppName, "Unable to open drive!", #PB_MessageRequester_Error) : End
  EndIf
  
  ; Start Background Monitor Thread
  Thread_Monitor = CreateThread(@MonitorThread(), 0)
EndProcedure

; --- Main Loop ---
InitializeApp()

Define Event.i, EventMenu.i, EventWindow.i, EventType.i
Define ioErr.l, useP.i, qry.i, forceP.i, currentForce.i, result.i

OpenWindow(#Window_Main, 0, 0, 0, 0, Lng\AppName, #PB_Window_Invisible)
CreatePopupMenu(#Menu_Main)
MenuItem(#MenuItem_About, Lng\About)
MenuItem(#MenuItem_Help, Lng\Help)
MenuBar()
MenuItem(#MenuItem_Drives, Lng\Drives)
MenuItem(#MenuItem_Diagnostics, Lng\Diagnostics)
MenuItem(#MenuItem_Reload, Lng\Reload)
MenuItem(#MenuItem_Edit, Lng\Edit)
MenuBar()
MenuItem(#MenuItem_Startup, Lng\Startup)
MenuItem(#MenuItem_ForcePdh, Lng\PdhOnly)
MenuBar()
MenuItem(#MenuItem_Exit, Lng\Exit)

AddSysTrayIcon(1, WindowID(#Window_Main), IdIcon3)
SysTrayIconToolTip(1, Lng\AppName + " " + version)

  StartupEnabled = IsInStartup()
  SetMenuItemState(#Menu_Main, #MenuItem_Startup, StartupEnabled)
  ForcePdhOnly = ForcePdhOnlyDefault
  SetMenuItemState(#Menu_Main, #MenuItem_ForcePdh, ForcePdhOnly)
  
  Repeat
    Event = WaitWindowEvent()

  
  Select Event
    Case #Event_UpdateTrayIcon
      LockMutex(Mutex_DiskData)
      ChangeSysTrayIcon(1, CurrentIconID)
      SysTrayIconToolTip(1, Lng\AppName + " " + version + #CRLF$ + CurrentTooltip)
      UnlockMutex(Mutex_DiskData)
      
    Case #PB_Event_SysTray
      If EventType() = #PB_EventType_RightClick
        DisplayPopupMenu(#Menu_Main, WindowID(#Window_Main))
      EndIf
      
    Case #PB_Event_Menu
      Select EventMenu()
        Case #MenuItem_About : About(icon1)
        Case #MenuItem_Help : Help()
        Case #MenuItem_Drives : DrivesWindow("")
        Case #MenuItem_Diagnostics
          LockMutex(Mutex_DiskData)
          ioErr = LastIoctlError
          useP = UsePdh
          qry = PdhQuery
          forceP = ForcePdhOnly
          UnlockMutex(Mutex_DiskData)
          MessageRequester("Diagnostics", "IOCTL Last Error: " + Str(ioErr) + #CRLF$ +
                                       "Force PDH Active: " + Str(forceP) + #CRLF$ +
                                       "PDH Initialized: " + Str(useP) + #CRLF$ +
                                       "PDH Query Handle: " + Str(qry), #PB_MessageRequester_Info)
        Case #MenuItem_ForcePdh
          LockMutex(Mutex_DiskData)
          ForcePdhOnly ! 1
          currentForce = ForcePdhOnly
          UnlockMutex(Mutex_DiskData)
          SetMenuItemState(#Menu_Main, #MenuItem_ForcePdh, currentForce)
        Case #MenuItem_Reload : LoadSettings()
        Case #MenuItem_Edit : EditSettings()
        Case #MenuItem_Startup
          StartupEnabled ! 1
          If StartupEnabled
            result = AddToStartup(CurrentUserSam())
          Else
            result = RemoveFromStartup()
          EndIf
          If result
            SetMenuItemState(#Menu_Main, #MenuItem_Startup, StartupEnabled)
          Else
            StartupEnabled = IsInStartup()
            SetMenuItemState(#Menu_Main, #MenuItem_Startup, StartupEnabled)
            MessageRequester("Error", "Unable to change startup setting.", #PB_MessageRequester_Error)
          EndIf
        Case #MenuItem_Exit : If Exit() : QuitThread = #True : Break : EndIf
      EndSelect
      
    Case #PB_Event_CloseWindow
      If EventWindow() = #Window_Main : If Exit() : QuitThread = #True : Break : EndIf : EndIf
  EndSelect
ForEver

; --- Shutdown ---
If IsThread(Thread_Monitor) : WaitThread(Thread_Monitor, 1000) : EndIf
Cleanup()
End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 6
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyDrvLED.ico
; Executable = ..\HandyDrvLED.exe
; IncludeVersionInfo
; VersionField0 = 1,0,3,2
; VersionField1 = 1,0,3,2
; VersionField2 = ZoneSoft
; VersionField3 = HandyDrvLED
; VersionField4 = 1.0.3.2
; VersionField5 = 1.0.3.2
; VersionField6 = A handy drive monitor - with tons of features
; VersionField7 = HandyDrvLED
; VersionField8 = HandyDrvLED.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60