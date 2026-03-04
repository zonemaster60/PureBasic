#APP_NAME   = "Html_2_Text"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.2"

; Prevent multiple instances
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = #ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Procedure.s DecodeHtmlEntities(text.s)
  ; Basic Named Entities
  text = ReplaceString(text, "&lt;", "<")
  text = ReplaceString(text, "&gt;", ">")
  text = ReplaceString(text, "&amp;", "&")
  text = ReplaceString(text, "&quot;", #DQUOTE$)
  text = ReplaceString(text, "&apos;", "'")
  text = ReplaceString(text, "&nbsp;", " ")
  text = ReplaceString(text, "&copy;", "(c)")
  text = ReplaceString(text, "&reg;", "(r)")
  
  ; Simple Numeric Entity Support (&#123; or &#x7B;)
  Protected pos = FindString(text, "&#")
  While pos > 0
    Protected endPos = FindString(text, ";", pos)
    If endPos > pos And endPos - pos < 10
      Protected entity.s = Mid(text, pos + 2, endPos - pos - 2)
      Protected value.i = 0
      If Left(entity, 1) = "x" Or Left(entity, 1) = "X"
        value = Val("$" + Mid(entity, 2))
      Else
        value = Val(entity)
      EndIf
      If value > 0
        text = ReplaceString(text, "&#" + entity + ";", Chr(value))
      EndIf
    EndIf
    pos = FindString(text, "&#", pos + 1)
  Wend
  
  ProcedureReturn text
EndProcedure

Procedure.s StripHtmlTags(html.s)
  Protected result.s = ""
  Protected i.i, char.s, tagContent.s, tagName.s
  Protected inTag.b = #False
  Protected skipContent.b = #False
  Protected length.i = Len(html)
  
  i = 1
  While i <= length
    char = Mid(html, i, 1)
    
    If char = "<"
      inTag = #True
      tagContent = ""
      
      ; Peek at the tag name to see if it's a script/style block
      Protected j = i + 1
      tagName = ""
      While j <= length And Mid(html, j, 1) <> " " And Mid(html, j, 1) <> ">" And Mid(html, j, 1) <> "/"
        tagName + LCase(Mid(html, j, 1))
        j + 1
      Wend
      
      ; Handle block tags and special skip blocks
      If tagName = "p" Or tagName = "br" Or tagName = "div" Or tagName = "li" Or tagName = "tr" Or tagName = "h1" Or tagName = "h2" Or tagName = "h3"
        result + #CRLF$
      EndIf
      
      ; Logic to skip script and style content
      If tagName = "script" Or tagName = "style"
        ; Find closing tag
        Protected closeTag.s = "</" + tagName + ">"
        Protected closePos = FindString(html, closeTag, i, #PB_String_NoCase)
        If closePos > 0
          i = closePos + Len(closeTag) - 1
          inTag = #False
        EndIf
      EndIf
      
    ElseIf char = ">" And inTag
      inTag = #False
      result + " "
      
    ElseIf Not inTag
      result + char
    EndIf
    
    i + 1
  Wend
  
  ; Post-processing: Normalize whitespace and line breaks
  result = ReplaceString(result, #TAB$, " ")
  
  ; Remove triple newlines or more
  While FindString(result, #CRLF$ + #CRLF$ + #CRLF$)
    result = ReplaceString(result, #CRLF$ + #CRLF$ + #CRLF$, #CRLF$ + #CRLF$)
  Wend
  
  ; Clean up multiple spaces
  While FindString(result, "  ")
    result = ReplaceString(result, "  ", " ")
  Wend
  
  ProcedureReturn Trim(result)
EndProcedure

Define.i fileIn, fileOut
Define.s inputFile, outputFile, html, text

If OpenConsole()
  If CountProgramParameters() >= 2
    inputFile = ProgramParameter(0)
    outputFile = ProgramParameter(1)
    
    fileIn = ReadFile(#PB_Any, inputFile, #PB_UTF8)
    If fileIn
      html = ReadString(fileIn, #PB_File_IgnoreEOL | #PB_UTF8)
      CloseFile(fileIn)
      
      text = StripHtmlTags(html)
      text = DecodeHtmlEntities(text)
      
      fileOut = CreateFile(#PB_Any, outputFile, #PB_UTF8)
      If fileOut
        WriteString(fileOut, text, #PB_UTF8)
        CloseFile(fileOut)
        PrintN(#APP_NAME + " conversion completed successfully.")
      Else
        PrintN("Error: Could not create output file: " + outputFile)
      EndIf
    Else
      PrintN("Error: Could not read input file: " + inputFile)
    EndIf
    
  Else
    PrintN("Usage: " + #APP_NAME + " <input.html> <output.txt>")
    PrintN("Version: " + version)
    
    MessageRequester("About " + #APP_NAME, 
                     #APP_NAME + " " + version + #CRLF$ + 
                     "A simple HTML to Text converter." + #CRLF$ + #CRLF$ +
                     "Contact: " + #EMAIL_NAME + #CRLF$ +
                     "GitHub: https://github.com/zonemaster60", 
                     #PB_MessageRequester_Info)
  EndIf
EndIf

If hMutex : CloseHandle_(hMutex) : EndIf

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 3
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = html_2_text.ico
; Executable = ..\html_2_text.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = html_2_text
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = Convert HTML documents to readable text
; VersionField7 = html_2_text
; VersionField8 = html_2_text.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60