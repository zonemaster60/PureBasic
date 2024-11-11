; HandyTXTPad
;
Global gsFilename.s
XIncludeFile("HandyTXTPad.pbf")
XIncludeFile("HandyTXTPad.pbi")

If FindWindow_(0,"HandyTXTPad")
  MessageRequester("Info", "HandyTXTPad is already running.", #PB_MessageRequester_Info)
  End
EndIf 

OpenDlg1()

Define event.i

Repeat         ;main message loop
event = WaitWindowEvent()
  Dlg1_Events (event)
Until event = #PB_Event_CloseWindow
Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
; IDE Options = PureBasic 6.11 LTS Beta 3 (Windows - x64)
; CursorPosition = 1
; Optimizer
; EnableXP
; EnableUser
; DPIAware
; UseIcon = HandyTXTPad.ico
; Executable = HandyTXTPad.exe
; IncludeVersionInfo
; VersionField0 = 0,0,0,1
; VersionField1 = 0,0,0,6
; VersionField2 = ZoneSoft
; VersionField3 = HandyTXTPad.exe
; VersionField4 = v0.0.0.6
; VersionField5 = v0.0.0.1
; VersionField6 = A Handy Little Text Pad Program
; VersionField7 = HandyTXTPad.exe
; VersionField8 = HandyTXTPad.exe
; VersionField9 = David Scouten
; VersionField10 = David Scouten
; VersionField13 = zonemaster@yahoo.com