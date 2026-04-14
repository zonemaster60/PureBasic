Procedure.s NormalizeLineBreaks(text.s)
  Protected normalized.s = ReplaceString(text, #CRLF$, #LF$)
  normalized = ReplaceString(normalized, #LFCR$, #LF$)
  normalized = ReplaceString(normalized, #CR$, #LF$)
  ProcedureReturn ReplaceString(normalized, #LF$, #CRLF$)
EndProcedure

Procedure.s GetTrackDisplayName()
  If State\artist <> "" And State\title <> ""
    ProcedureReturn State\artist + " - " + State\title
  EndIf

  If State\fileName <> ""
    ProcedureReturn State\fileName
  EndIf

  ProcedureReturn #APP_NAME
EndProcedure

Procedure.s GetFileExtensionLower(path.s)
  Protected extension.s = LCase(GetExtensionPart(path))
  ProcedureReturn extension
EndProcedure

Procedure.i IsMediaFile(path.s)
  Protected extension.s = GetFileExtensionLower(path)
  ProcedureReturn Bool(extension = "asf" Or extension = "avi" Or extension = "flac" Or extension = "mid" Or extension = "mp3" Or extension = "mp4" Or extension = "mpg" Or extension = "wav" Or extension = "wmv")
EndProcedure

Procedure.i IsImageFile(path.s)
  Protected extension.s = GetFileExtensionLower(path)
  ProcedureReturn Bool(extension = "jpg" Or extension = "jpeg" Or extension = "png" Or extension = "gif" Or extension = "bmp")
EndProcedure

Procedure.i IsLyricsFile(path.s)
  Protected extension.s = GetFileExtensionLower(path)
  ProcedureReturn Bool(extension = "txt" Or extension = "lrc")
EndProcedure

Procedure.s QuoteArg(value.s)
  ProcedureReturn Chr(34) + ReplaceString(value, Chr(34), Chr(34) + Chr(34)) + Chr(34)
EndProcedure

Procedure.i EnsureDirectoryPath(path.s)
  Protected current.s = path
  Protected partial.s
  Protected part.s
  Protected slashPos.i
  Protected startPos.i

  If current = ""
    ProcedureReturn #False
  EndIf

  If Right(current, 1) <> "\\" And Right(current, 1) <> "/"
    current + "\\"
  EndIf

  If FileSize(current) = -2
    ProcedureReturn #True
  EndIf

  startPos = 1
  If Mid(current, 2, 1) = ":"
    partial = Left(current, 3)
    startPos = 4
  EndIf

  While startPos <= Len(current)
    slashPos = FindString(current, "\\", startPos)
    If slashPos = 0
      part = Mid(current, startPos)
      startPos = Len(current) + 1
    Else
      part = Mid(current, startPos, slashPos - startPos)
      startPos = slashPos + 1
    EndIf

    If part <> ""
      partial + part + "\\"
      If FileSize(partial) <> -2
        If CreateDirectory(partial) = 0 And FileSize(partial) <> -2
          ProcedureReturn #False
        EndIf
      EndIf
    EndIf
  Wend

  ProcedureReturn Bool(FileSize(current) = -2)
EndProcedure

Procedure.s SanitizeFileComponent(value.s)
  Protected cleaned.s = Trim(value)

  cleaned = ReplaceString(cleaned, "/", "-")
  cleaned = ReplaceString(cleaned, "\\", "-")
  cleaned = ReplaceString(cleaned, ":", "-")
  cleaned = ReplaceString(cleaned, "*", "")
  cleaned = ReplaceString(cleaned, "?", "")
  cleaned = ReplaceString(cleaned, Chr(34), "'")
  cleaned = ReplaceString(cleaned, "<", "(")
  cleaned = ReplaceString(cleaned, ">", ")")
  cleaned = ReplaceString(cleaned, "|", "-")

  While FindString(cleaned, "  ")
    cleaned = ReplaceString(cleaned, "  ", " ")
  Wend

  cleaned = Trim(Trim(cleaned, "."), " ")
  If cleaned = ""
    cleaned = "unknown"
  EndIf

  ProcedureReturn cleaned
EndProcedure

Procedure.s UrlEncodeUTF8(value.s)
  ProcedureReturn URLEncoder(value, #PB_UTF8)
EndProcedure

Procedure.s DecodeHtmlEntities(value.s)
  Protected decoded.s = value

  decoded = ReplaceString(decoded, "&amp;", "&")
  decoded = ReplaceString(decoded, "&quot;", Chr(34))
  decoded = ReplaceString(decoded, "&#39;", "'")
  decoded = ReplaceString(decoded, "&apos;", "'")
  decoded = ReplaceString(decoded, "&lt;", "<")
  decoded = ReplaceString(decoded, "&gt;", ">")

  ProcedureReturn decoded
EndProcedure

Procedure.s StripAudioExtension(name.s)
  Protected base.s = name
  Protected dot.i = FindString(base, ".", -1)

  If dot > 0
    base = Left(base, dot - 1)
  EndIf

  ProcedureReturn base
EndProcedure

Procedure.s FindFolderArtwork(path.s)
  Protected folderPath.s = GetPathPart(path)
  Protected baseName.s = LCase(StripAudioExtension(GetFilePart(path)))
  Protected candidate.s
  Protected preferredNames.s
  Protected name.s
  Protected idx.i
  Protected dir.i
  Protected entry.s
  Protected fullPath.s

  If folderPath = ""
    ProcedureReturn ""
  EndIf

  preferredNames = baseName + "|cover|folder|front|album|artwork"

  For idx = 1 To CountString(preferredNames, "|") + 1
    name = StringField(preferredNames, idx, "|")

    candidate = folderPath + name + ".jpg"
    If FileSize(candidate) >= 0 : ProcedureReturn candidate : EndIf
    candidate = folderPath + name + ".jpeg"
    If FileSize(candidate) >= 0 : ProcedureReturn candidate : EndIf
    candidate = folderPath + name + ".png"
    If FileSize(candidate) >= 0 : ProcedureReturn candidate : EndIf
    candidate = folderPath + name + ".gif"
    If FileSize(candidate) >= 0 : ProcedureReturn candidate : EndIf
  Next

  dir = ExamineDirectory(#PB_Any, folderPath, "*")
  If dir
    While NextDirectoryEntry(dir)
      entry = DirectoryEntryName(dir)
      If entry = "." Or entry = ".."
        Continue
      EndIf

      fullPath = folderPath + entry
      If DirectoryEntryType(dir) = #PB_DirectoryEntry_File And IsImageFile(fullPath)
        FinishDirectory(dir)
        ProcedureReturn fullPath
      EndIf
    Wend
    FinishDirectory(dir)
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s FormatTime(seconds.q)
  Protected mm.q = seconds / 60
  Protected ss.q = seconds % 60
  ProcedureReturn RSet(Str(mm), 2, "0") + ":" + RSet(Str(ss), 2, "0")
EndProcedure
