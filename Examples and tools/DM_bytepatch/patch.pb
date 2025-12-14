;Daniel Middelhede - 2003

;This is a procedure made with help from Paul, that patches the file.
Procedure.l Patch(file.s,location.l,byte.b) 
;Make an backup of the file
CopyFile(file,file+".bak")
;Open file
  If OpenFile(0,file) 
   ;Find the place with the old bytes
    FileSeek(0,location) 
    ;Write new bytes
    WriteData(0,@byte,1) 
    ;And close it
    CloseFile(0) 
    ;Return 1 if this was ok.
    ProcedureReturn 1
  EndIf 
EndProcedure 

;How to use the procedure: 
;Patch(filename,offset,byte)
;When writing HEX in purebasic, put an $ before
;the value. Simple!

;Debug is written before patch, so the returned value
;gets by the debugger, which reports the number to the
;programmer. This can easly be removed.
Debug Patch("test.exe",$6FB,$90) 
Debug Patch("test.exe",$6FC,$90) 
; ExecutableFormat=Windows
; Executable=C:\Documents and Settings\fjolle\Skrivebord\Examples.exe
; EOF
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 25
; FirstLine = 6
; Folding = -
; EnableXP
; DPIAware
; Executable = patch.exe