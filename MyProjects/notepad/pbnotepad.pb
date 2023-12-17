Global gsFilename.s
XIncludeFile("pbnotepad.pbf")
XIncludeFile("helpers.pbi")

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
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 14
; Optimizer
; EnableThread
; EnableXP
; EnableUser
; DPIAware
; UseIcon = pbnotepad.ico
; Executable = pbnotepad.exe