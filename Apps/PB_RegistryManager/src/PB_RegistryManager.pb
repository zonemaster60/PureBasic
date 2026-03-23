; ======================================================================
; Registry Manager - All-in-One Edition
; Features: Editor, Cleaner, Backup, Restore, Compactor
; Target: Windows with PureBasic 6.30+
; ======================================================================

XIncludeFile "Registry.pbi"

EnableExplicit

XIncludeFile "PB_RegistryManager.Shared.pbi"
XIncludeFile "PB_RegistryManager.Editor.pbi"
XIncludeFile "PB_RegistryManager.Tools.pbi"
XIncludeFile "PB_RegistryManager.UI.pbi"

Define fileName.s, helpPath.s

; Initialize error logging
If Not InitErrorLog()
  MessageRequester("Warning", "Cannot create error log file!", #PB_MessageRequester_Warning)
EndIf

LogInfo("Main", "Registry Manager starting...")
LogInfo("Main", "PureBasic Version: " + Str(#PB_Compiler_Version))
LogInfo("Main", "Operating System: " + #PB_Compiler_OS)

; Cleanup old backups (keep last 7 days)
CleanupOldBackups(7)

; Show backup directory location
LogInfo("Main", "Auto-backup directory: " + GetBackupDirectory())

If CreateGUI()
  LogInfo("Main", "Entering main event loop")
  
  Repeat
    Define eventID.i = WaitWindowEvent()
    Select eventID
      Case #PB_Event_CloseWindow
        HandleCloseWindowEvent()

      Case #PB_Event_Timer
        HandleTimerEvent()

      Case #EVENT_EXPORT_COMPLETE, #EVENT_SNAPSHOT_CREATED, #EVENT_ASYNC_STATUS, #EVENT_ASYNC_MESSAGE, #EVENT_COMPARE_COMPLETE, #EVENT_LOAD_VALUES_COMPLETE, #EVENT_LOAD_COMPLETE
        HandleCustomEvent(eventID)

      Case #PB_Event_Menu
        HandleMenuEvent(EventMenu())

      Case #PB_Event_Gadget
        HandleGadgetEvent(EventGadget())

      Case #PB_Event_SizeWindow
        HandleSizeWindowEvent()
    EndSelect
  ForEver
  
  LogInfo("Main", "Exiting main event loop")
Else
  LogError("Main", "Failed to create GUI - exiting")
  MessageRequester("Fatal Error", "Cannot create main window!" + #CRLF$ + "Check log file: " + ErrorLogPath, #PB_MessageRequester_Error)
EndIf

LogInfo("Main", "Registry Manager shutting down")

; No need for manual cleanup here anymore as Exit() handles it
Exit()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 10
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_RegistryManager.ico
; Executable = ..\PB_RegistryManager.exe
; IncludeVersionInfo
; VersionField0 = 1,0,1,4
; VersionField1 = 1,0,1,4
; VersionField2 = ZoneSoft
; VersionField3 = PB_RegistryManager
; VersionField4 = 1.0.1.4
; VersionField5 = 1.0.1.4
; VersionField6 = A full featured Registry Manager built with PureBasic
; VersionField7 = PB_RegistryManager
; VersionField8 = PB_RegistryManager.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60