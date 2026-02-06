
#APP_NAME   = "Html_2_Text"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.1"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = #ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Procedure.s StripHtmlTags(html.s)
  Protected result.s, i, inTag = #False
  For i = 1 To Len(html)
    char$ = Mid(html, i, 1)
    If char$ = "<"
      inTag = #True
    ElseIf char$ = ">"
      inTag = #False
    ElseIf inTag = #False
      result + char$
    EndIf
  Next
  ProcedureReturn result
EndProcedure

Procedure.s DecodeHtmlEntities(text.s)
  text = ReplaceString(text, "&lt;", "<")
  text = ReplaceString(text, "&gt;", ">")
  text = ReplaceString(text, "&amp;", "&")
  text = ReplaceString(text, "&quot;", Chr(34))
  text = ReplaceString(text, "&apos;", "'")
  text = ReplaceString(text, "&nbsp;", " ")
  ProcedureReturn text
EndProcedure

If OpenConsole()
  If CountProgramParameters() >= 2
    inputFile$ = ProgramParameter(0)
    outputFile$ = ProgramParameter(1)
    If ReadFile(0, inputFile$)
      html$ = ""
      While Not Eof(0)
        html$ + ReadString(0) + Chr(10)
      Wend
      CloseFile(0)
      text$ = StripHtmlTags(html$)
      text$ = DecodeHtmlEntities(text$)
      If CreateFile(1, outputFile$)
        WriteString(1, text$)
        CloseFile(1)
        PrintN(#APP_NAME + " conversion completed successfully.")
      Else
        PrintN("Error: Could not create output file.")
      EndIf
    Else
      PrintN("Error: Could not read input file.")
    EndIf
  Else
    PrintN("Usage: " + #APP_NAME + " < input.html > < output.txt >")
  EndIf
  MessageRequester("Info", #APP_NAME + " - " + version + #CRLF$ + 
                           "Thank you for using this free tool!" + #CRLF$ +
                           "Contact: " + #EMAIL_NAME + #CRLF$ +
                           "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf
; IDE Options = PureBasic 6.30 beta 7 (Windows - x64)
; CursorPosition = 67
; FirstLine = 45
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = html_2_text.ico
; Executable = html_2_text.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,1
; VersionField1 = 1,0,0,1
; VersionField2 = ZoneSoft
; VersionField3 = html_2_text
; VersionField4 = 1.0.0.1
; VersionField5 = 1.0.0.1
; VersionField6 = Convert HTML documents to readable text
; VersionField7 = html_2_text
; VersionField8 = html_2_text.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60