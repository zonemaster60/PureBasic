Global gsFilename.s
XIncludeFile("HandyTXTPad.pbf")
XIncludeFile("HandyTXTPad.pbi")

OpenDlg1()

Define event.i
Repeat         ;main message loop
  event = WaitWindowEvent()
  Dlg1_Events (event)
Until event = #PB_Event_CloseWindow
Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 2
; Optimizer
; EnableXP
; EnableUser
; DPIAware
; UseIcon = HandyTXTPad.ico
; Executable = HandyTXTPad.exe
; IncludeVersionInfo
; VersionField0 = 0.0.0.1
; VersionField1 = 0.0.0.1
; VersionField2 = ZoneSoft
; VersionField4 = v0.0.0.1
; VersionField7 = HandyTXTPad.exe
; VersionField8 = HandyTXTPad.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster@yahoo.com