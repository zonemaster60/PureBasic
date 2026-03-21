#APP_NAME   = "Html_2_Text"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.3"

Procedure.s DecodeNamedHtmlEntity(entity.s)
  Select LCase(entity)
    Case "amp" : ProcedureReturn "&"
    Case "apos" : ProcedureReturn "'"
    Case "bull" : ProcedureReturn "*"
    Case "cent" : ProcedureReturn "cent"
    Case "copy" : ProcedureReturn "(c)"
    Case "deg" : ProcedureReturn " deg"
    Case "divide" : ProcedureReturn "/"
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
    Case "nbsp", "thinsp", "ensp", "emsp" : ProcedureReturn " "
    Case "para" : ProcedureReturn "P"
    Case "plusmn" : ProcedureReturn "+/-"
    Case "pound" : ProcedureReturn "GBP"
    Case "quot" : ProcedureReturn #DQUOTE$
    Case "raquo" : ProcedureReturn #DQUOTE$
    Case "reg" : ProcedureReturn "(r)"
    Case "sect" : ProcedureReturn "S"
    Case "sup1" : ProcedureReturn "^1"
    Case "sup2" : ProcedureReturn "^2"
    Case "sup3" : ProcedureReturn "^3"
    Case "times" : ProcedureReturn "x"
    Case "trade" : ProcedureReturn "(TM)"
    Case "yen" : ProcedureReturn "JPY"
  EndSelect

  ProcedureReturn ""
EndProcedure

Procedure.s DecodeHtmlEntities(text.s)
  Protected pos.i = FindString(text, "&")
  Protected endPos.i
  Protected entity.s
  Protected replacement.s
  Protected value.i

  While pos > 0
    endPos = FindString(text, ";", pos + 1)
    If endPos > pos And endPos - pos <= 12
      entity = Mid(text, pos + 1, endPos - pos - 1)
      replacement = ""

      If Left(entity, 1) = "#"
        If Left(entity, 2) = "#x" Or Left(entity, 2) = "#X"
          value = Val("$" + Mid(entity, 3))
        Else
          value = Val(Mid(entity, 2))
        EndIf

        If value > 0
          replacement = Chr(value)
        EndIf
      Else
        replacement = DecodeNamedHtmlEntity(entity)
      EndIf

      If replacement <> ""
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
    Case "script", "style", "noscript"
      ProcedureReturn #True
  EndSelect

  ProcedureReturn #False
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
  Protected closeTag.s

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
        tagEnd = FindString(html, ">", i + 1)
        If tagEnd = 0
          result + Mid(html, i)
          Break
        EndIf

        tagContent = Trim(Mid(html, i + 1, tagEnd - i - 1))
        tagName = ExtractTagName(tagContent)

        If IsSkipTag(tagName)
          closeTag = "</" + tagName
          closePos = FindString(html, closeTag, tagEnd + 1, #PB_String_NoCase)
          If closePos > 0
            closeEnd = FindString(html, ">", closePos + Len(closeTag))
            If closeEnd > 0
              i = closeEnd
            Else
              i = length
            EndIf
          Else
            i = tagEnd
          EndIf
        Else
          Select tagName
            Case "br", "hr", "li", "tr", "p", "div", "h1", "h2", "h3", "h4", "h5", "h6", "section", "article", "header", "footer", "nav", "aside", "blockquote", "ul", "ol", "table", "pre"
              result = AddSeparator(result, #LF$)
            Case "td", "th"
              result = AddSeparator(result, " ")
            Default
              If IsBlockTag(tagName)
                result = AddSeparator(result, #LF$)
              EndIf
          EndSelect

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

  ProcedureReturn NormalizeText(result)
EndProcedure

Define.i fileIn, fileOut, exitCode
Define.s inputFile, outputFile, html, text

exitCode = 0

If OpenConsole()
  If CountProgramParameters() >= 2
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
      text = DecodeHtmlEntities(text)

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
     
  Else
    PrintN("Usage: " + #APP_NAME + " <input.html> <output.txt>")
    PrintN("Version: " + version)
    PrintN("A simple HTML to Text converter.")
    PrintN("Contact: " + #EMAIL_NAME)
    PrintN("GitHub: https://github.com/zonemaster60")
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
; VersionField0 = 1,0,0,3
; VersionField1 = 1,0,0,3
; VersionField2 = ZoneSoft
; VersionField3 = html_2_text
; VersionField4 = 1.0.0.3
; VersionField5 = 1.0.0.3
; VersionField6 = Convert HTML documents to readable text
; VersionField7 = html_2_text
; VersionField8 = html_2_text.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60