EnableExplicit

#APP_NAME   = "HandyWSERTool"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.9"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Procedure CloseAppMutex()
  If hMutex
    ReleaseMutex_(hMutex)
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
EndProcedure

Procedure Exit()
  Define Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo)
  If Req = #PB_MessageRequester_Yes
    CloseAppMutex()
    End
  EndIf
EndProcedure

XIncludeFile "EnvSys.pbi"
XIncludeFile "AppShared.pbi"
XIncludeFile "Logging.pbi"
XIncludeFile "UI.pbi"
XIncludeFile "ScanRepair.pbi"
XIncludeFile "ImportExport.pbi"

Repeat
  Define event.i = WaitWindowEvent()
  Select event
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #BtnScan
          ScanEnvironment()
        Case #BtnRepair
          RepairEnvironment()
        Case #BtnExport
          DoExport()
        Case #BtnImport
          DoImport()
        Case #BtnAbout
          MessageRequester("Info", #APP_NAME + " - " + version + #CRLF$ +
                                   "Thank you for using this free tool!" + #CRLF$ +
                                   "Contact: " + #EMAIL_NAME + #CRLF$ +
                                   "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
        Case #BtnFixRefs
          FixReferencedMissingVars()
        Case #BtnExit
          Exit()
      EndSelect

    Case #PB_Event_CloseWindow
      Exit()
  EndSelect
ForEver

; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; EnableAdmin
; DPIAware
; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 5
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyWSERTool.ico
; Executable = ..\HandyWSERTool.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,9
; VersionField1 = 1,0,0,9
; VersionField2 = ZoneSoft
; VersionField3 = HandyWSERTool
; VersionField4 = 1.0.0.9
; VersionField5 = 1.0.0.9
; VersionField6 = Windows System Environment Repair Tool
; VersionField7 = HandyWSERTool
; VersionField8 = HandyWSERTool.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60