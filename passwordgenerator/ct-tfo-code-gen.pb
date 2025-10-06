Start:

Repeat
  Code = Random(1999999999, 1111111111)
  Choice = MessageRequester("Generate code", "Code: " + Code + ", generate again?", #PB_MessageRequester_YesNo)
Until Choice = #PB_MessageRequester_No  

CreateFile(0, "ct-tfo-code.txt")
  WriteStringN(0, "When prompted, type in this code: "+Str(Code))
  CloseFile(0)
  
  MessageRequester("Info","Code saved to file.",#PB_MessageRequester_Info)
  Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
Goto Start
; IDE Options = PureBasic 6.11 LTS Beta 2 (Windows - x64)
; CursorPosition = 11
; Optimizer
; EnableThread
; EnableXP
; EnableUser
; UseIcon = passwordgen.ico
; Executable = ct-tfo-code-gen.exe