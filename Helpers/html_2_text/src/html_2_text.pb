#APP_NAME   = "Html_2_Text"
#EMAIL_NAME = "zonemaster60@gmail.com"
#VERSION    = "v1.0.0.4"

Procedure PrintUsage()
  PrintN("Usage: " + #APP_NAME + " <input.html> <output.txt>")
  PrintN("Version: " + #VERSION)
  PrintN("A simple HTML to Text converter.")
  PrintN("Contact: " + #EMAIL_NAME)
  PrintN("GitHub: https://github.com/zonemaster60")
EndProcedure

Procedure.b IsDecimalDigits(value.s)
  Protected i.i
  Protected char.s

  If value = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(value)
    char = Mid(value, i, 1)
    If FindString("0123456789", char) = 0
      ProcedureReturn #False
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.b IsHexDigits(value.s)
  Protected i.i
  Protected char.s

  If value = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(value)
    char = UCase(Mid(value, i, 1))
    If FindString("0123456789ABCDEF", char) = 0
      ProcedureReturn #False
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.b IsValidCodePoint(value.i)
  If value = 9 Or value = 10 Or value = 13
    ProcedureReturn #True
  EndIf

  If value >= 32 And value <= $D7FF
    ProcedureReturn #True
  EndIf

  If value >= $E000 And value <= $10FFFF
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.s DecodeNamedHtmlEntity(entity.s)
  Select LCase(entity)
    Case "amp" : ProcedureReturn "&"
    Case "apos" : ProcedureReturn "'"
    Case "bdquo" : ProcedureReturn #DQUOTE$
    Case "brvbar" : ProcedureReturn "|"
    Case "bull" : ProcedureReturn "*"
    Case "cedil" : ProcedureReturn ","
    Case "cent" : ProcedureReturn "cent"
    Case "copy" : ProcedureReturn "(c)"
    Case "curren" : ProcedureReturn "currency"
    Case "deg" : ProcedureReturn " deg"
    Case "divide" : ProcedureReturn "/"
    Case "emsp", "ensp", "nbsp", "thinsp" : ProcedureReturn " "
    Case "euro" : ProcedureReturn "EUR"
    Case "frac12" : ProcedureReturn "1/2"
    Case "frac14" : ProcedureReturn "1/4"
    Case "frac34" : ProcedureReturn "3/4"
    Case "gt" : ProcedureReturn ">"
    Case "hellip" : ProcedureReturn "..."
    Case "iexcl" : ProcedureReturn "!"
    Case "iquest" : ProcedureReturn "?"
    Case "laquo" : ProcedureReturn #DQUOTE$
    Case "ldquo", "rdquo" : ProcedureReturn #DQUOTE$
    Case "lsaquo", "rsaquo" : ProcedureReturn "'"
    Case "lsquo", "rsquo" : ProcedureReturn "'"
    Case "lt" : ProcedureReturn "<"
    Case "mdash" : ProcedureReturn "--"
    Case "micro" : ProcedureReturn "u"
    Case "middot" : ProcedureReturn "-"
    Case "minus", "ndash" : ProcedureReturn "-"
    Case "not" : ProcedureReturn "not"
    Case "para" : ProcedureReturn "P"
    Case "permil" : ProcedureReturn " per mille"
    Case "plusmn" : ProcedureReturn "+/-"
    Case "pound" : ProcedureReturn "GBP"
    Case "quot" : ProcedureReturn #DQUOTE$
    Case "raquo" : ProcedureReturn #DQUOTE$
    Case "reg" : ProcedureReturn "(r)"
    Case "sbquo" : ProcedureReturn "'"
    Case "sect" : ProcedureReturn "S"
    Case "shy" : ProcedureReturn ""
    Case "sup1" : ProcedureReturn "^1"
    Case "sup2" : ProcedureReturn "^2"
    Case "sup3" : ProcedureReturn "^3"
    Case "times" : ProcedureReturn "x"
    Case "trade" : ProcedureReturn "(TM)"
    Case "yen" : ProcedureReturn "JPY"
  EndSelect

  ProcedureReturn ""
EndProcedure

Procedure.b IsRemovableHtmlEntity(entity.s)
  Select LCase(entity)
    Case "shy"
      ProcedureReturn #True
  EndSelect

  ProcedureReturn #False
EndProcedure

Procedure.s DecodeHtmlEntities(text.s)
  Protected pos.i = FindString(text, "&")
  Protected endPos.i
  Protected entity.s
  Protected replacement.s
  Protected value.i
  Protected digits.s

  While pos > 0
    endPos = FindString(text, ";", pos + 1)
    If endPos > pos And endPos - pos <= 12
      entity = Mid(text, pos + 1, endPos - pos - 1)
      replacement = ""

      If Left(entity, 1) = "#"
        If Left(entity, 2) = "#x" Or Left(entity, 2) = "#X"
          digits = Mid(entity, 3)
          If IsHexDigits(digits)
            value = Val("$" + digits)
          Else
            value = -1
          EndIf
        Else
          digits = Mid(entity, 2)
          If IsDecimalDigits(digits)
            value = Val(digits)
          Else
            value = -1
          EndIf
        EndIf

        If IsValidCodePoint(value)
          replacement = Chr(value)
        EndIf
      Else
        replacement = DecodeNamedHtmlEntity(entity)
      EndIf

      If replacement <> "" Or IsRemovableHtmlEntity(entity)
        text = Left(text, pos - 1) + replacement + Mid(text, endPos + 1)
        pos = FindString(text, "&", pos + Len(replacement))
      Else
        pos = FindString(text, "&", pos + 1)
      EndIf
    Else
      pos = FindString(text, "&", pos + 1)
    EndIf
  Wend

  ProcedureReturn text
EndProcedure

Procedure.b IsWhitespaceChar(char.s)
  ProcedureReturn Bool(char = " " Or char = #TAB$ Or char = #CR$ Or char = #LF$)
EndProcedure

Procedure.b IsBlockTag(tagName.s)
  Select tagName
    Case "address", "article", "aside", "blockquote", "br", "dd", "div", "dl", "dt", "fieldset", "figcaption", "figure", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6", "header", "hr", "li", "main", "nav", "ol", "p", "pre", "section", "table", "td", "th", "tr", "ul"
      ProcedureReturn #True
  EndSelect

  ProcedureReturn #False
EndProcedure

Procedure.b IsSkipTag(tagName.s)
  Select tagName
    Case "iframe", "noembed", "noframes", "noscript", "script", "style", "svg", "template"
      ProcedureReturn #True
  EndSelect

  ProcedureReturn #False
EndProcedure

Procedure.b IsLineBreakTag(tagName.s)
  Select tagName
    Case "article", "aside", "blockquote", "br", "div", "footer", "form", "h1", "h2", "h3", "h4", "h5", "h6", "header", "hr", "li", "main", "nav", "ol", "p", "pre", "section", "table", "tr", "ul"
      ProcedureReturn #True
  EndSelect

  ProcedureReturn #False
EndProcedure

Procedure.i FindTagEnd(html.s, startPos.i)
  Protected i.i
  Protected length.i = Len(html)
  Protected char.s
  Protected quote.s = ""

  For i = startPos + 1 To length
    char = Mid(html, i, 1)

    If quote <> ""
      If char = quote
        quote = ""
      EndIf
    ElseIf char = #DQUOTE$ Or char = "'"
      quote = char
    ElseIf char = ">"
      ProcedureReturn i
    EndIf
  Next

  ProcedureReturn 0
EndProcedure

Procedure.i FindSkipTagEnd(html.s, tagName.s, searchStart.i)
  Protected closeTag.s = "</" + tagName
  Protected closePos.i
  Protected closeEnd.i
  Protected charAfter.s

  closePos = FindString(html, closeTag, searchStart, #PB_String_NoCase)
  While closePos > 0
    charAfter = Mid(html, closePos + Len(closeTag), 1)
    If charAfter = "" Or charAfter = ">" Or IsWhitespaceChar(charAfter)
      closeEnd = FindTagEnd(html, closePos)
      If closeEnd > 0
        ProcedureReturn closeEnd
      EndIf

      ProcedureReturn Len(html)
    EndIf

    closePos = FindString(html, closeTag, closePos + Len(closeTag), #PB_String_NoCase)
  Wend

  ProcedureReturn 0
EndProcedure

Procedure.s ExtractTagName(tagContent.s)
  Protected tagName.s
  Protected i.i
  Protected currentChar.s

  tagName = LCase(Trim(tagContent))
  If tagName = ""
    ProcedureReturn ""
  EndIf

  While Left(tagName, 1) = "/" Or Left(tagName, 1) = "!" Or Left(tagName, 1) = "?"
    tagName = Mid(tagName, 2)
    If tagName = ""
      ProcedureReturn ""
    EndIf
  Wend

  For i = 1 To Len(tagName)
    currentChar = Mid(tagName, i, 1)
    If IsWhitespaceChar(currentChar) Or currentChar = "/" Or currentChar = ">"
      ProcedureReturn Left(tagName, i - 1)
    EndIf
  Next

  ProcedureReturn tagName
EndProcedure

Procedure.s AddSeparator(text.s, separator.s)
  Protected textLength.i

  textLength = Len(text)
  While textLength > 0 And Right(text, 1) = " "
    text = Left(text, textLength - 1)
    textLength - 1
  Wend

  If separator = #LF$
    If textLength > 0 And Right(text, 1) <> #LF$
      text + #LF$
    EndIf
  ElseIf separator = " "
    If textLength > 0 And Right(text, 1) <> " " And Right(text, 1) <> #LF$
      text + " "
    EndIf
  EndIf

  ProcedureReturn text
EndProcedure

Procedure.s NormalizeText(text.s)
  text = ReplaceString(text, #CRLF$, #LF$)
  text = ReplaceString(text, #CR$, #LF$)
  text = ReplaceString(text, #TAB$, " ")

  While FindString(text, "  ")
    text = ReplaceString(text, "  ", " ")
  Wend

  While FindString(text, #LF$ + " ")
    text = ReplaceString(text, #LF$ + " ", #LF$)
  Wend

  While FindString(text, " " + #LF$)
    text = ReplaceString(text, " " + #LF$, #LF$)
  Wend

  While FindString(text, #LF$ + #LF$ + #LF$)
    text = ReplaceString(text, #LF$ + #LF$ + #LF$, #LF$ + #LF$)
  Wend

  text = Trim(text)
  text = ReplaceString(text, #LF$, #CRLF$)

  ProcedureReturn text
EndProcedure

Procedure.s StripHtmlTags(html.s)
  Protected result.s = ""
  Protected i.i
  Protected length.i = Len(html)
  Protected tagEnd.i
  Protected closePos.i
  Protected closeEnd.i
  Protected char.s
  Protected tagContent.s
  Protected tagName.s
  Protected normalized.s

  i = 1
  While i <= length
    char = Mid(html, i, 1)

    If char = "<"
      If Mid(html, i, 4) = "<!--"
        closePos = FindString(html, "-->", i + 4)
        If closePos = 0
          Break
        EndIf
        i = closePos + 2
      Else
        tagEnd = FindTagEnd(html, i)
        If tagEnd = 0
          result + Mid(html, i)
          Break
        EndIf

        tagContent = Trim(Mid(html, i + 1, tagEnd - i - 1))
        tagName = ExtractTagName(tagContent)

        If IsSkipTag(tagName)
          closeEnd = FindSkipTagEnd(html, tagName, tagEnd + 1)
          If closeEnd > 0
            i = closeEnd
          Else
            i = tagEnd
          EndIf
        Else
          If tagName = "td" Or tagName = "th"
            result = AddSeparator(result, " ")
          ElseIf IsLineBreakTag(tagName) Or IsBlockTag(tagName)
            result = AddSeparator(result, #LF$)
          EndIf

          i = tagEnd
        EndIf
      EndIf
    ElseIf IsWhitespaceChar(char)
      result = AddSeparator(result, " ")
    Else
      result + char
    EndIf

    i + 1
  Wend

  normalized = DecodeHtmlEntities(result)

  ProcedureReturn NormalizeText(normalized)
EndProcedure

Define.i fileIn, fileOut, exitCode
Define.s inputFile, outputFile, html, text

exitCode = 0

If OpenConsole()
  If CountProgramParameters() = 2
    inputFile = ProgramParameter(0)
    outputFile = ProgramParameter(1)

    fileIn = ReadFile(#PB_Any, inputFile, #PB_UTF8)
    If fileIn
      While Eof(fileIn) = 0
        html + ReadString(fileIn, #PB_UTF8)
        If Eof(fileIn) = 0
          html + #LF$
        EndIf
      Wend
      CloseFile(fileIn)

      text = StripHtmlTags(html)

      fileOut = CreateFile(#PB_Any, outputFile, #PB_UTF8)
      If fileOut
        WriteString(fileOut, text, #PB_UTF8)
        CloseFile(fileOut)
        PrintN(#APP_NAME + " conversion completed successfully.")
      Else
        PrintN("Error: Could not create output file: " + outputFile)
        exitCode = 3
      EndIf
    Else
      PrintN("Error: Could not read input file: " + inputFile)
      exitCode = 2
    EndIf
     
  ElseIf CountProgramParameters() = 1 And (ProgramParameter(0) = "--help" Or ProgramParameter(0) = "-h" Or ProgramParameter(0) = "/?")
    PrintUsage()
  Else
    PrintUsage()
    exitCode = 1
  EndIf
Else
  exitCode = 4
EndIf

End exitCode

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 3
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = html_2_text.ico
; Executable = ..\html_2_text.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,4
; VersionField1 = 1,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = html_2_text
; VersionField4 = 1.0.0.4
; VersionField5 = 1.0.0.4
; VersionField6 = Convert HTML documents to readable text
; VersionField7 = html_2_text
; VersionField8 = html_2_text.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
