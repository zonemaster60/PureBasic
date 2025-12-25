EnableExplicit

;==================================================================
; Password generator
;
;	Create a password generation program which will generate passwords
; containing random ASCII characters from the following groups:
;	   lower-case letters:  a-z
;	   upper-case letters:  A-Z
;	   digits:  0-9
;	   other characters:  !"#$%&'()*+,-./:;<=>?@[]^_{|}~ 
;	   (the above character list excludes white-space, backslash and grave) 
;
;	The generated password(s) must include at least one
; (of each of the four groups):
;	   lower-case letter, 
;	   upper-case letter,
;	   digit (numeral), and 
;	   one "other" character. 
; =================================================================

#APP_NAME = "passwordgenerator"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.1"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Procedure.b CheckPW(pw.s)
  Define flag.b=#True,
         tmp.b=#False,
         c.c,
         s.s,
         i.i  
  For c='a' To 'z'
    tmp=Bool(FindString(pw,Chr(c)))
    If tmp : Break : EndIf
  Next  
  flag & tmp
  tmp=#False  
  For c='A' To 'Z'
    tmp=Bool(FindString(pw,Chr(c)))
    If tmp : Break : EndIf
  Next  
  flag & tmp
  tmp=#False  
  For c='0' To '9'
    tmp=Bool(FindString(pw,Chr(c)))
    If tmp : Break : EndIf
  Next  
  flag & tmp
  tmp=#False  
  For c='!' To '/'
    s+Chr(c)
  Next  
  For c=':' To '@'
    s+Chr(c)
  Next  
  s+"[]^_{|}~"  
  For i=1 To Len(pw)
    tmp=Bool(FindString(s,Mid(pw,i,1)))
    If tmp : Break : EndIf
  Next    
  flag & tmp  
  ProcedureReturn flag
EndProcedure
 
Procedure.s InputHdl(prompt.s="")
  Define txt.s,
         s.s,
         r.i,
         hlp.s
  Restore Help_01
  Read.s hlp  
  Print(prompt)       
  Repeat
    s=Inkey()    
    If s<>""
      If FindString("0123456789",s)
        txt+s
        Print(s)
      EndIf
      If s=Chr(27)
        txt="0"
        Break
      EndIf            
    ElseIf RawKey()
      r=RawKey()      
      If r=112
        PrintN("")
        PrintN(hlp)  
        Print(~"\n"+prompt)
      EndIf
    EndIf
    Delay(20)
  Until s=Chr(13)
  PrintN("")  
  ProcedureReturn txt
EndProcedure
 
NewList PasswordChar.c()
Define c.c,
       pwlen.i,
       n_of_pw.i,
       pwstr.s,
       i.i,
       Req.i,
       pname.s,
       wname.s
For c='!' To '~'
  If c<>'\' And c<>'`'
    AddElement(PasswordChar()) : PasswordChar()=c
  EndIf  
Next
EnableGraphicalConsole(1)
OpenConsole(#APP_NAME + ": F1 = Help; ESC or 0 = End")
Restart:
Repeat
  PrintN("Enter username: ")
  pname=Input()
  PrintN("Enter sitename: ")
  wname=Input()
  If Len(pname)<1 Or Len(wname)<1 : Break : EndIf
  pwlen=Abs(Val(InputHdl("Enter the password length (#>=8): ")))
  If pwlen<1 Or pwlen=0 : Break : EndIf
  If pwlen<8 : Continue : EndIf
  n_of_pw=Abs(Val(InputHdl("Enter the # of password(s) (#>=1): ")))
  If n_of_pw<1 : Break : EndIf
  PrintN("")
  If CreateFile(0, "MyPasswords.txt")
  Else
    MessageRequester("Error:", "Can't create the file!",#PB_MessageRequester_Error)
  EndIf
  For i=1 To n_of_pw    
    Repeat      
      pwstr=Mid(pwstr,2)
      RandomizeList(PasswordChar())
      ResetList(PasswordChar())      
      While NextElement(PasswordChar())
        pwstr+Chr(PasswordChar())
        If Len(pwstr)>=pwlen : Break : EndIf
      Wend
    Until CheckPW(pwstr)
    PrintN(RSet(Str(i),Len(Str(n_of_pw))," ")+") user: "+pname+" | "+" pass: "+pwstr+" | "+" site: "+"https://"+wname)
    WriteStringN(0, RSet(Str(i),Len(Str(n_of_pw))," ")+") user: "+pname+" | "+" pass: "+pwstr+" | "+" site: "+"https://"+wname)
    pwstr=""
  Next
  PrintN("")
  CloseFile(0)
ForEver
pname=""
PrintN("")
If i > 0
  PrintN("Password(s) saved to 'MyPasswords.txt' file...")
  PrintN("")
  PrintN("(Press ENTER to continue...)")
  Input()
EndIf
  MessageRequester("Info", #APP_NAME +" "+ version + #CRLF$ +
                             "Thank you for using this free tool!" + #CRLF$ +
                             "Contact: " + #EMAIL_NAME, #PB_MessageRequester_Info)
  End
ClearConsole()
Goto Restart
  
DataSection
  Help_01:
  Data.s ~"\n" + #APP_NAME + ": F1 = Help; ESC or 0 = End\n"+
         ~"---------------------------------------------\n"+
         ~"1) Enter the username (login):\n"+
         ~"2) Enter the sitename (http://):\n"+
         ~"3) Enter the password length (#>=8):\n"+
         ~"4) Enter the # of password(s) (#>=1):\n"+
         ~"5) The result(s) will be displayed.\n"+
         ~"6) You can highlight the password and\n "+
         ~"press CTRL-C to copy to the clipboard.\n"+
         ~"(Enter 0 or ESC will exit the program.)\n"+
         ~"(Passwords are saved to 'MyPasswords.txt')"
  EndOfHelp:
EndDataSection

; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 28
; FirstLine = 15
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = passwordgenerator.ico
; Executable = ..\passwordgenerator.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,1
; VersionField1 = 1,0,0,1
; VersionField2 = ZoneSoft
; VersionField3 = passwordgenerator
; VersionField4 = 1.0.0.1
; VersionField5 = 1.0.0.1
; VersionField6 = Generates website passwords
; VersionField7 = passwordgenerator
; VersionField8 = passwordgenerator.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60