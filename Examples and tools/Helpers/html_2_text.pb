

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
        PrintN("HTML to text conversion completed successfully.")
      Else
        PrintN("Error: Could not create output file.")
      EndIf
    Else
      PrintN("Error: Could not read input file.")
    EndIf
  Else
    PrintN("Usage: htmltotext input.html output.txt")
  EndIf
  PrintN("")
  PrintN("Press Enter to exit...")
  Input()
EndIf
; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 47
; FirstLine = 26
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = html_2_text.ico
; Executable = html2txt.exe