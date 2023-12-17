EnableExplicit

Procedure JustExit()
  Define Req.i
  Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    ;CloseWindow(#Window_0)
    End
  EndIf
EndProcedure

;JustExit()
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 11
; Folding = -
; EnableXP
; DPIAware