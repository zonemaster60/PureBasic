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

#APP_NAME = "PB_PassGen"
#EMAIL_NAME = "zonemaster60@gmail.com"
#MIN_PASSWORD_LENGTH = 8
#ERROR_ALREADY_EXISTS = 183

#HELP_TEXT = "" + #CRLF$ +
             #APP_NAME + ": F1 = Help; ESC = End" + #CRLF$ +
             "---------------------------------------------" + #CRLF$ +
             "Interactive mode:" + #CRLF$ +
             "  - Prompts for user/site/length/count" + #CRLF$ +
             "  - Can enable screen-only and no-ambiguous" + #CRLF$ +
             "" + #CRLF$ +
             "CLI mode examples:" + #CRLF$ +
             "  PassGen --site example.com --user bob --len 20 --count 5" + #CRLF$ +
             "  PassGen --site example.com --len 16 --screen-only" + #CRLF$ +
             "  PassGen --site example.com --len 16 --no-ambiguous" + #CRLF$ +
             "  PassGen /site example.com /len 16 /screen-only" + #CRLF$ +
             "" + #CRLF$ +
             "Options:" + #CRLF$ +
             "  --len N, --count N, --user NAME, --site SITE" + #CRLF$ +
             "  --outfile FILE, --screen-only, --no-ambiguous" + #CRLF$ +
             "  --no-special, --copy" + #CRLF$ +
             "  --help" + #CRLF$ +
             "" + #CRLF$ +
             "Tip: highlight a password and press CTRL-C" + #CRLF$ +
             "to copy from the console."

Global version.s = "v1.0.0.4"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Initialize cryptographically secure RNG once per run
If OpenCryptRandom() = 0
  MessageRequester(#APP_NAME, "Error: Could not initialize secure random number generator.", #PB_MessageRequester_Error)
  End
EndIf

; Early help/version handling (must run before mutex)
; Some launchers don't show console output reliably, so use a dialog.
Define earlyArg.s
Define earlyIdx.i
For earlyIdx = 0 To CountProgramParameters() - 1
  earlyArg = LCase(ProgramParameter(earlyIdx))
  If earlyArg = "--help" Or earlyArg = "-h" Or earlyArg = "/help" Or earlyArg = "/h" Or earlyArg = "/?"
    MessageRequester(#APP_NAME + " " + version, #HELP_TEXT, #PB_MessageRequester_Info)
    CloseCryptRandom()
    End
  EndIf
Next

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
Global ownsMutex.b
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex = 0
  MessageRequester("Error", "Unable to create application mutex.", #PB_MessageRequester_Error)
  CloseCryptRandom()
  End
EndIf
If GetLastError_() = #ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  CloseCryptRandom()
  End
EndIf
If hMutex
  ownsMutex = #True
EndIf

Procedure Cleanup()
  If ownsMutex And hMutex
    ReleaseMutex_(hMutex)
  EndIf
  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
  CloseCryptRandom()
EndProcedure

Procedure.s CanonicalSwitch(arg.s)
  Define s.s = LCase(Trim(arg))

  If s = ""
    ProcedureReturn ""
  EndIf

  If Left(s, 1) = "/"
    Select s
      Case "/?", "/h", "/help"
        ProcedureReturn "--help"
      Default
        s = "--" + Mid(s, 2)
    EndSelect
  EndIf

  Select s
    Case "--help", "-h"
      ProcedureReturn "--help"
    Case "--len", "--count", "--user", "--site", "--outfile", "--screen-only", "--no-ambiguous", "--no-special", "--copy"
      ProcedureReturn s
  EndSelect

  ProcedureReturn ""
EndProcedure

Procedure.s RandomCharFromSet(charset.s)
  Define n.i = Len(charset)
  If n < 1
    ProcedureReturn ""
  EndIf
  ProcedureReturn Mid(charset, 1 + CryptRandom(n - 1), 1)
EndProcedure

Procedure.s RemoveChars(source.s, remove.s)
  Define i.i, c.s, out.s
  Define n = Len(source)
  For i = 1 To n
    c = Mid(source, i, 1)
    If FindString(remove, c) = 0
      out + c
    EndIf
  Next
  ProcedureReturn out
EndProcedure

Procedure.s NormalizeSite(site.s)
  Define s.s = Trim(site)
  Define cutPos.i
  If s = ""
    ProcedureReturn ""
  EndIf
  If Left(LCase(s), 7) = "http://"
    s = Mid(s, 8)
  ElseIf Left(LCase(s), 8) = "https://"
    s = Mid(s, 9)
  EndIf
  If FindString(s, "@", 1)
    s = StringField(s, 2, "@")
  EndIf
  cutPos = FindString(s, "/", 1)
  If cutPos = 0
    cutPos = FindString(s, "?", 1)
  EndIf
  If cutPos = 0
    cutPos = FindString(s, "#", 1)
  EndIf
  If cutPos > 0
    s = Left(s, cutPos - 1)
  EndIf
  ProcedureReturn Trim(s)
EndProcedure

Procedure.s DefaultOutFileName()
  ProcedureReturn "MyPasswords_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".txt"
EndProcedure

Procedure.b AskYesNo(prompt.s)
  PrintN(prompt)
  ProcedureReturn Bool(LCase(Left(Trim(Input()), 1)) = "y")
EndProcedure

Procedure.s ShuffleString(s.s)
  ; Fisher-Yates shuffle on string characters (using pointers for efficiency)
  Define n.i = Len(s)
  Define i.i, j.i, tmp.c
  If n < 2 : ProcedureReturn s : EndIf
  For i = n - 1 To 1 Step -1
    j = CryptRandom(i)
    tmp = PeekC(@s + i * SizeOf(Character))
    PokeC(@s + i * SizeOf(Character), PeekC(@s + j * SizeOf(Character)))
    PokeC(@s + j * SizeOf(Character), tmp)
  Next
  ProcedureReturn s
EndProcedure

Procedure.s GeneratePassword(pwlen.i, excludeAmbiguous.b, noSpecial.b = #False)
  Static lower_base.s = "abcdefghijklmnopqrstuvwxyz"
  Static upper_base.s = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
  Static digits_base.s = "0123456789"
  Static other_base.s = ~"!\"#$%&'()*+,-./:;<=>?@[]^_{|}~"
  Static ambiguous.s = "O0Il1"

  Define lower.s = lower_base
  Define upper.s = upper_base
  Define digits.s = digits_base
  Define other.s = other_base

  If excludeAmbiguous
    lower = RemoveChars(lower, ambiguous)
    upper = RemoveChars(upper, ambiguous)
    digits = RemoveChars(digits, ambiguous)
  EndIf
  
  If noSpecial
    other = ""
  EndIf

  Define allChars.s = lower + upper + digits + other

  If pwlen < #MIN_PASSWORD_LENGTH
    ProcedureReturn ""
  EndIf
  If lower = "" Or upper = "" Or digits = "" Or (other = "" And noSpecial = #False)
    ProcedureReturn ""
  EndIf

  ; Ensure at least one from each group
  Define pw.s = Space(pwlen)
  Define *p.Character = @pw
  
  PokeC(*p, Asc(RandomCharFromSet(lower))) : *p + SizeOf(Character)
  PokeC(*p, Asc(RandomCharFromSet(upper))) : *p + SizeOf(Character)
  PokeC(*p, Asc(RandomCharFromSet(digits))) : *p + SizeOf(Character)
  
  If noSpecial = #False
    PokeC(*p, Asc(RandomCharFromSet(other))) : *p + SizeOf(Character)
  EndIf

  While *p < @pw + pwlen * SizeOf(Character)
    PokeC(*p, Asc(RandomCharFromSet(allChars)))
    *p + SizeOf(Character)
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
  Define txt.s, s.s, r.i
  Print(prompt)
  Repeat
    s = Inkey()
    If s <> ""
      Select Asc(s)
        Case 13 ; Enter
          Break
        Case 27 ; Esc
          txt = ""
          Break
        Case 8 ; Backspace
          If Len(txt) > 0
            txt = Left(txt, Len(txt) - 1)
            Print(Chr(8) + " " + Chr(8))
          EndIf
        Case '0' To '9'
          txt + s
          Print(s)
      EndSelect
    ElseIf RawKey()
      r = RawKey()
      If r = 112 ; F1
        PrintN("")
        PrintHelp()
        Print(#CRLF$ + prompt + txt)
      EndIf
    EndIf
    Delay(20)
  ForEver
  PrintN("")
  ProcedureReturn txt
EndProcedure

Procedure.s InputLineHdl(prompt.s="")
  ; Line input with F1 help + Backspace support
  Define txt.s,
         s.s,
         r.i

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
       noSpecial.b,
       copyToClipboard.b,
       arg.s,
       nextArg.s,
       cliError.s

; Defaults
pwlen = 16
n_of_pw = 1
screenOnly = #False
excludeAmbiguous = #False
noSpecial = #False
copyToClipboard = #False
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
  Define switch.s, value.s, hasValue.b, eqPos.i

  For i = 0 To CountProgramParameters() - 1
    arg = ProgramParameter(i)

    ; Split --key=value form
    hasValue = #False
    value = ""
    eqPos = FindString(arg, "=", 1)
    If eqPos
      switch = Left(arg, eqPos - 1)
      value  = Mid(arg, eqPos + 1)
      hasValue = #True
    Else
      switch = arg
    EndIf

    switch = CanonicalSwitch(switch)

    If switch = ""
      If cliError = ""
        cliError = "Unknown option: " + arg
      EndIf
      Continue
    EndIf

    nextArg = ""
    If i + 1 < CountProgramParameters()
      nextArg = ProgramParameter(i + 1)
    EndIf

    Select switch
      Case "--help"
        MessageRequester(#APP_NAME + " " + version, #HELP_TEXT, #PB_MessageRequester_Info)
        Cleanup()
        End

      Case "--screen-only"
        screenOnly = #True

      Case "--no-ambiguous"
        excludeAmbiguous = #True

      Case "--no-special"
        noSpecial = #True

      Case "--copy"
        copyToClipboard = #True

      Case "--len"
        If hasValue = #False And i + 1 < CountProgramParameters() And CanonicalSwitch(nextArg) = ""
          value = ProgramParameter(i + 1)
          i + 1
        EndIf
        If value = "" And cliError = ""
          cliError = "Missing value for --len"
        EndIf
        pwlen = Abs(Val(value))

      Case "--count"
        If hasValue = #False And i + 1 < CountProgramParameters() And CanonicalSwitch(nextArg) = ""
          value = ProgramParameter(i + 1)
          i + 1
        EndIf
        If value = "" And cliError = ""
          cliError = "Missing value for --count"
        EndIf
        n_of_pw = Abs(Val(value))

      Case "--user"
        If hasValue = #False And i + 1 < CountProgramParameters() And CanonicalSwitch(nextArg) = ""
          value = ProgramParameter(i + 1)
          i + 1
        EndIf
        If value = "" And cliError = ""
          cliError = "Missing value for --user"
        EndIf
        pname = value

      Case "--site"
        If hasValue = #False And i + 1 < CountProgramParameters() And CanonicalSwitch(nextArg) = ""
          value = ProgramParameter(i + 1)
          i + 1
        EndIf
        If value = "" And cliError = ""
          cliError = "Missing value for --site"
        EndIf
        wname = value

      Case "--outfile"
        If hasValue = #False And i + 1 < CountProgramParameters() And CanonicalSwitch(nextArg) = ""
          value = ProgramParameter(i + 1)
          i + 1
        EndIf
        If value = "" And cliError = ""
          cliError = "Missing value for --outfile"
        EndIf
        outFile = value
    EndSelect
  Next
EndIf

wname = NormalizeSite(wname)

EnableGraphicalConsole(1)
OpenConsole(#APP_NAME + ": F1 = Help; ESC = End")

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

    arg = InputHdl("Enter password length (#>=" + Str(#MIN_PASSWORD_LENGTH) + "): ")
    If Len(Trim(arg)) < 1
      Break
    EndIf
    pwlen = Abs(Val(arg))
    If pwlen < #MIN_PASSWORD_LENGTH
      PrintN("Length must be >= " + Str(#MIN_PASSWORD_LENGTH) + ".")
      PrintN("(Press ENTER to continue...)")
      Input()
      Continue
    EndIf

    arg = InputHdl("Enter # of passwords (#>=1): ")
    If Len(Trim(arg)) < 1
      Break
    EndIf
    n_of_pw = Abs(Val(arg))
    If n_of_pw < 1
      Break
    EndIf

    excludeAmbiguous = AskYesNo("Exclude ambiguous characters (O 0 I l 1)? (y/N): ")
    noSpecial = AskYesNo("Exclude special characters (!@#$%...)? (y/N): ")
    copyToClipboard = AskYesNo("Copy first password to clipboard? (y/N): ")
    screenOnly = AskYesNo("Screen-only (do not write a file)? (y/N): ")

    If screenOnly = #False
      outFile = DefaultOutFileName()
    EndIf
  Else
    If cliError <> ""
      PrintN(cliError)
      PrintN("Run with --help.")
      Cleanup()
      End
    EndIf
    If pwlen < #MIN_PASSWORD_LENGTH Or n_of_pw < 1 Or Len(wname) < 1
      PrintN("Invalid arguments. Run with --help.")
      Cleanup()
      End
    EndIf
    If screenOnly = #False And outFile = ""
      outFile = DefaultOutFileName()
    EndIf
  EndIf

  If screenOnly = #False
    If CreateFile(0, outFile) = 0
      MessageRequester("Error", "Can't create the file: " + outFile + #CRLF$ + "Check if you have write permissions or if the file is open in another program.", #PB_MessageRequester_Error)
      Break
    EndIf
  EndIf

  PrintN("")
  For i = 1 To n_of_pw
    pwstr = GeneratePassword(pwlen, excludeAmbiguous, noSpecial)
    If pwstr = ""
      If screenOnly = #False
        CloseFile(0)
      EndIf
      MessageRequester("Error", "Failed to generate password.", #PB_MessageRequester_Error)
      Break 2
    EndIf

    If i = 1 And copyToClipboard
      SetClipboardText(pwstr)
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

  If copyToClipboard
    PrintN("(First password copied to clipboard.)")
  EndIf

  If useCli
    Cleanup()
    End
  EndIf

  PrintN("(Press ENTER for another run...)" )
  Input()
ForEver

MessageRequester("Info", #APP_NAME + " " + version + #CRLF$ +
                         "Thank you for using this free tool!" + #CRLF$ +
                         "Contact: " + #EMAIL_NAME + #CRLF$ +
                         "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
Cleanup()
End

  

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 48
; FirstLine = 27
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_PassGen.ico
; Executable = ..\PB_PassGen.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,4
; VersionField1 = 1,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = PassGen
; VersionField4 = 1.0.0.4
; VersionField5 = 1.0.0.4
; VersionField6 = Generates website passwords
; VersionField7 = PassGen
; VersionField8 = PassGen.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60