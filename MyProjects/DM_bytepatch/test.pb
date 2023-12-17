;Daniel Middelhede - 2003

;Open an msg dialog:
MessageRequester("daniels software","REGISTER")
;Get the serial
serial.s=InputRequester("daniels software","serial number:","")
;Test
If serial.s="fjolle"
MessageRequester("daniels software","Serial OK")
Else
MessageRequester("daniels software","Wrong serial")
EndIf
; ExecutableFormat=Windows
; Executable=C:\Documents and Settings\fjolle\Skrivebord\test.exe
; EOF
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; EnableXP
; DPIAware
; Executable = test.exe