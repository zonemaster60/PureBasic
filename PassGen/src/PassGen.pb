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

#APP_NAME = "PassGen"
#EMAIL_NAME = "zonemaster60@gmail.com"

#HELP_TEXT = "" + #CRLF$ +
             #APP_NAME + ": F1 = Help; ESC = End" + #CRLF$ +
             "---------------------------------------------" + #CRLF$ +
             "Interactive mode:" + #CRLF$ +
             "  - Prompts for user/site/length/count" + #CRLF$ +
             "  - Can enable screen-only and no-ambiguous" + #CRLF$ +
             "" + #CRLF$ +
             "CLI mode examples:" + #CRLF$ +
             "  passwordgenerator --site example.com --user bob --len 20 --count 5" + #CRLF$ +
             "  passwordgenerator --site example.com --len 16 --screen-only" + #CRLF$ +
             "  passwordgenerator --site example.com --len 16 --no-ambiguous" + #CRLF$ +
             "" + #CRLF$ +
             "Options:" + #CRLF$ +
             "  --len N, --count N, --user NAME, --site SITE" + #CRLF$ +
             "  --outfile FILE, --screen-only, --no-ambiguous" + #CRLF$ +
             "  --help" + #CRLF$ +
             "" + #CRLF$ +
             "Tip: highlight a password and press CTRL-C" + #CRLF$ +
             "to copy from the console."

Global version.s = "v1.0.0.2"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Seed RNG once per run
RandomSeed(Date() ! ElapsedMilliseconds())

; Early help/version handling (must run before mutex)
; Some launchers don't show console output reliably, so use a dialog.
Define earlyArg.s
Define earlyIdx.i
For earlyIdx = 0 To CountProgramParameters() - 1
  earlyArg = LCase(ProgramParameter(earlyIdx))
  If earlyArg = "--help" Or earlyArg = "-h" Or earlyArg = "/help" Or earlyArg = "/h" Or earlyArg = "/?"
    MessageRequester(#APP_NAME + " " + version, #HELP_TEXT, #PB_MessageRequester_Info)
    End
  EndIf
Next

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Procedure.s RandomCharFromSet(charset.s)
  If Len(charset) < 1
    ProcedureReturn ""
  EndIf
  ProcedureReturn Mid(charset, 1 + Random(Len(charset) - 1), 1)
EndProcedure

Procedure.s RemoveChars(source.s, remove.s)
  Define i.i, c.s, out.s
  For i = 1 To Len(source)
    c = Mid(source, i, 1)
    If FindString(remove, c, 1) = 0
      out + c
    EndIf
  Next
  ProcedureReturn out
EndProcedure

Procedure.s NormalizeSite(site.s)
  Define s.s = Trim(site)
  If s = ""
    ProcedureReturn ""
  EndIf
  If Left(LCase(s), 7) = "http://"
    s = Mid(s, 8)
  ElseIf Left(LCase(s), 8) = "https://"
    s = Mid(s, 9)
  EndIf
  ProcedureReturn Trim(s)
EndProcedure

Procedure.s ShuffleString(s.s)
  ; Fisher-Yates shuffle on string characters
  Define i.i, j.i, tmp.s
  For i = Len(s) To 2 Step -1
    j = 1 + Random(i - 1)
    tmp = Mid(s, i, 1)
    s = Left(s, i - 1) + Mid(s, j, 1) + Mid(s, i + 1)
    s = Left(s, j - 1) + tmp + Mid(s, j + 1)
  Next
  ProcedureReturn s
EndProcedure

Procedure.s GeneratePassword(pwlen.i, excludeAmbiguous.b)
  Define lower.s = "abcdefghijklmnopqrstuvwxyz"
  Define upper.s = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  Define digits.s = "0123456789"
  Define other.s
  Define ambiguous.s = "O0Il1"

  other = ~"!\"#$%&'()*+,-./:;<=>?@[]^_{|}~"

  If excludeAmbiguous
    lower = RemoveChars(lower, ambiguous)
    upper = RemoveChars(upper, ambiguous)
    digits = RemoveChars(digits, ambiguous)
  EndIf

  Define allChars.s = lower + upper + digits + other

  If pwlen < 8
    ProcedureReturn ""
  EndIf
  If Len(lower) = 0 Or Len(upper) = 0 Or Len(digits) = 0 Or Len(other) = 0
    ProcedureReturn ""
  EndIf

  ; Ensure at least one from each group
  Define pw.s
  pw + RandomCharFromSet(lower)
  pw + RandomCharFromSet(upper)
  pw + RandomCharFromSet(digits)
  pw + RandomCharFromSet(other)

  While Len(pw) < pwlen
    pw + RandomCharFromSet(allChars)
  Wend

  ProcedureReturn ShuffleString(pw)
EndProcedure
 
Procedure.s GetHelpText()
  ProcedureReturn #HELP_TEXT
EndProcedure

Procedure PrintHelp()
  Define helpText.s = GetHelpText()
  Define pos.i, line.s

  Repeat
    pos = FindString(helpText, #CRLF$, 1)
    If pos
      line = Left(helpText, pos - 1)
      helpText = Mid(helpText, pos + Len(#CRLF$))
    Else
      line = helpText
      helpText = ""
    EndIf

    PrintN(line)
  Until helpText = ""
EndProcedure

Procedure.s InputHdl(prompt.s="")
  Define txt.s,
         s.s,
         r.i,
         hlp.s
  hlp = GetHelpText()
  Print(prompt)
  Repeat
    s = Inkey()
    If s <> ""
      If FindString("0123456789", s)
        txt + s
        Print(s)
      EndIf
      If s = Chr(27)
        txt = "0"
        Break
      EndIf
    ElseIf RawKey()
      r = RawKey()
      If r = 112
        PrintN("")
        PrintHelp()
        Print(#CRLF$ + prompt)
      EndIf
    EndIf
    Delay(20)
  Until s = Chr(13)
  PrintN("")
  ProcedureReturn txt
EndProcedure

Procedure.s InputLineHdl(prompt.s="")
  ; Line input with F1 help + Backspace support
  Define txt.s,
         s.s,
         r.i,
         hlp.s
  hlp = GetHelpText()

  Print(prompt)
  Repeat
    s = Inkey()
    If s <> ""
      Select Asc(s)
        Case 13
          Break

        Case 27
          txt = ""
          Break

        Case 8
          If Len(txt) > 0
            txt = Left(txt, Len(txt) - 1)
            Print(Chr(8) + " " + Chr(8))
          EndIf

        Default
          ; Filter out control characters
          If Asc(s) >= 32
            txt + s
            Print(s)
          EndIf
      EndSelect

    ElseIf RawKey()
      r = RawKey()
      If r = 112
        PrintN("")
        PrintHelp()
        Print(#CRLF$ + prompt + txt)
      ElseIf r = 27
        txt = ""
        Break
      EndIf
    EndIf

    Delay(20)
  ForEver

  PrintN("")
  ProcedureReturn txt
EndProcedure
 
Define pwlen.i,
       n_of_pw.i,
       pwstr.s,
       i.i,
       pname.s,
       wname.s,
       outFile.s,
       line.s,
       useCli.b,
       screenOnly.b,
       excludeAmbiguous.b,
       arg.s,
       nextArg.s

; Defaults
pwlen = 16
n_of_pw = 1
screenOnly = #False
excludeAmbiguous = #False
outFile = ""

; Parse CLI args
; Notes:
; - Windows users often pass switches with '/' (e.g. /len 16)
; - Values may legitimately start with '-' (e.g. "-foo") so we only
;   treat "-" as meaning "next switch" when it actually matches a known one.
If CountProgramParameters() > 0
  useCli = #True

  ; Normalize switch to lowercase and allow /foo == --foo
  ; Supports both "--len 16" and "--len=16" forms.
  Define switch.s, value.s, hasValue.b

  For i = 0 To CountProgramParameters() - 1
    arg = ProgramParameter(i)

    ; Split --key=value form
    hasValue = #False
    value = ""
    If FindString(arg, "=", 1)
      switch = StringField(arg, 1, "=")
      value  = StringField(arg, 2, "=")
      hasValue = #True
    Else
      switch = arg
    EndIf

    switch = LCase(switch)
    If Left(switch, 1) = "/"
      ; accept /len, /h, /? etc
      switch = "/" + Mid(switch, 2)
    EndIf

    ; Peek next argument only when needed
    nextArg = ""
    If i + 1 < CountProgramParameters()
      nextArg = ProgramParameter(i + 1)
    EndIf

    Select switch
      Case "--help", "-h", "/help", "/h", "/?"
        ; Always show help even when no console is attached.
        ; Note: depending on how the process is launched, cmd.exe may intercept '/?'
        ; before it reaches this program. '/help' and '--help' are reliable.
    MessageRequester(#APP_NAME + " " + version, #HELP_TEXT, #PB_MessageRequester_Info)

        End

      Case "--screen-only"
        screenOnly = #True

      Case "--no-ambiguous"
        excludeAmbiguous = #True

      Case "--len"
        If hasValue = #False
          value = nextArg
          i + 1
        EndIf
        pwlen = Abs(Val(value))

      Case "--count"
        If hasValue = #False
          value = nextArg
          i + 1
        EndIf
        n_of_pw = Abs(Val(value))

      Case "--user"
        If hasValue = #False
          value = nextArg
          i + 1
        EndIf
        pname = value

      Case "--site"
        If hasValue = #False
          value = nextArg
          i + 1
        EndIf
        wname = value

      Case "--outfile"
        If hasValue = #False
          value = nextArg
          i + 1
        EndIf
        outFile = value
    EndSelect
  Next
EndIf

wname = NormalizeSite(wname)

EnableGraphicalConsole(1)
OpenConsole(#APP_NAME + ": F1 = Help; ESC = End")

Restart:
Repeat
  If useCli = #False
    ClearConsole()
    PrintN(#APP_NAME + " - " + version)
    PrintN("")
    pname = InputLineHdl("Enter username (blank = exit): ")
    If Len(Trim(pname)) < 1
      Break
    EndIf

    wname = InputLineHdl("Enter sitename (e.g. example.com): ")
    wname = NormalizeSite(wname)
    If Len(Trim(wname)) < 1
      Break
    EndIf

    pwlen = Abs(Val(InputHdl("Enter password length (#>=8): ")))
    If pwlen < 8
      PrintN("Length must be >= 8.")
      PrintN("(Press ENTER to continue...)")
      Input()
      Continue
    EndIf

    n_of_pw = Abs(Val(InputHdl("Enter # of passwords (#>=1): ")))
    If n_of_pw < 1
      Break
    EndIf

    PrintN("Exclude ambiguous characters (O 0 I l 1)? (y/N): ")
    If LCase(Left(Trim(Input()), 1)) = "y"
      excludeAmbiguous = #True
    Else
      excludeAmbiguous = #False
    EndIf

    PrintN("Screen-only (do not write a file)? (y/N): ")
    If LCase(Left(Trim(Input()), 1)) = "y"
      screenOnly = #True
    Else
      screenOnly = #False
    EndIf

    If screenOnly = #False
      outFile = "MyPasswords_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".txt"
    EndIf
  Else
    If pwlen < 8 Or n_of_pw < 1 Or Len(wname) < 1
      PrintN("Invalid arguments. Run with --help.")
      End
    EndIf
    If screenOnly = #False And outFile = ""
      outFile = "MyPasswords_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".txt"
    EndIf
  EndIf

  If screenOnly = #False
    If CreateFile(0, outFile) = 0
      MessageRequester("Error", "Can't create the file: " + outFile, #PB_MessageRequester_Error)
      Break
    EndIf
  EndIf

  PrintN("")
  For i = 1 To n_of_pw
    pwstr = GeneratePassword(pwlen, excludeAmbiguous)
    If pwstr = ""
      If screenOnly = #False
        CloseFile(0)
      EndIf
      MessageRequester("Error", "Failed to generate password.", #PB_MessageRequester_Error)
      Break 2
    EndIf

    line = RSet(Str(i), Len(Str(n_of_pw)), " ") + ")"
    If Len(Trim(pname)) > 0
      line + " user: " + pname + " |"
    EndIf
    line + " pass: " + pwstr
    If Len(Trim(wname)) > 0
      line + " | site: https://" + wname
    EndIf

    PrintN(line)
    If screenOnly = #False
      WriteStringN(0, line)
    EndIf
  Next

  If screenOnly = #False
    CloseFile(0)
    PrintN("")
    PrintN("Password(s) saved to '" + outFile + "'.")
  Else
    PrintN("")
    PrintN("(Screen-only mode: no file written.)")
  EndIf

  If useCli
    CloseHandle_(hMutex)
    End
  EndIf

  PrintN("(Press ENTER for another run...)" )
  Input()
ForEver

MessageRequester("Info", #APP_NAME + " " + version + #CRLF$ +
                         "Thank you for using this free tool!" + #CRLF$ +
                         "Contact: " + #EMAIL_NAME + #CRLF$ +
                         "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
CloseHandle_(hMutex)
End

  

; IDE Options = PureBasic 6.30 beta 6 (Windows - x64)
; CursorPosition = 21
; FirstLine = 6
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PassGen.ico
; Executable = ..\PassGen.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = PasswordGenerator
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = Generates website passwords
; VersionField7 = PasswordGenerator
; VersionField8 = PasswordGenerator.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60