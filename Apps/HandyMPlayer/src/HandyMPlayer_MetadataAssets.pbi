Procedure.q ReadSyncSafeInteger(*buffer, offset.i)
  ProcedureReturn ((PeekA(*buffer + offset) & $7F) << 21) | ((PeekA(*buffer + offset + 1) & $7F) << 14) | ((PeekA(*buffer + offset + 2) & $7F) << 7) | (PeekA(*buffer + offset + 3) & $7F)
EndProcedure

Procedure.q ReadBigEndianInteger(*buffer, offset.i, length.i)
  Protected result.q
  Protected i.i

  For i = 0 To length - 1
    result = (result << 8) | (PeekA(*buffer + offset + i) & $FF)
  Next

  ProcedureReturn result
EndProcedure

Procedure.s ReadID3TextFrame(*buffer, length.i)
  Protected encoding.i
  Protected start.i = 1
  Protected text.s
  Protected usableLength.i

  If *buffer = 0 Or length <= 1
    ProcedureReturn ""
  EndIf

  encoding = PeekA(*buffer) & $FF
  usableLength = length - 1

  Select encoding
    Case 0
      text = PeekS(*buffer + start, usableLength, #PB_Ascii)

    Case 1
      If usableLength >= 2 And PeekA(*buffer + start) = $FF And PeekA(*buffer + start + 1) = $FE
        text = PeekS(*buffer + start + 2, (usableLength - 2) / 2, #PB_Unicode)
      ElseIf usableLength >= 2 And PeekA(*buffer + start) = $FE And PeekA(*buffer + start + 1) = $FF
        text = PeekS(*buffer + start + 2, (usableLength - 2) / 2, #PB_UTF16BE)
      Else
        text = PeekS(*buffer + start, usableLength / 2, #PB_Unicode)
      EndIf

    Case 2
      text = PeekS(*buffer + start, usableLength / 2, #PB_UTF16BE)

    Case 3
      text = PeekS(*buffer + start, usableLength, #PB_UTF8 | #PB_ByteLength)

    Default
      text = ""
  EndSelect

  ProcedureReturn Trim(ReplaceString(ReplaceString(text, Chr(0), ""), #CR$, ""))
EndProcedure

Procedure.i FindTerminatorOffset(*buffer, start.i, maxLength.i, encoding.i)
  Protected i.i

  Select encoding
    Case 0, 3
      For i = start To maxLength - 1
        If PeekA(*buffer + i) = 0
          ProcedureReturn i
        EndIf
      Next

    Default
      For i = start To maxLength - 2 Step 2
        If PeekA(*buffer + i) = 0 And PeekA(*buffer + i + 1) = 0
          ProcedureReturn i
        EndIf
      Next
  EndSelect

  ProcedureReturn -1
EndProcedure

Procedure.s ReadEncodedField(*buffer, start.i, endOffset.i, encoding.i)
  Protected length.i = endOffset - start

  If length <= 0
    ProcedureReturn ""
  EndIf

  Select encoding
    Case 0
      ProcedureReturn PeekS(*buffer + start, length, #PB_Ascii)

    Case 1
      If length >= 2 And PeekA(*buffer + start) = $FF And PeekA(*buffer + start + 1) = $FE
        ProcedureReturn PeekS(*buffer + start + 2, (length - 2) / 2, #PB_Unicode)
      ElseIf length >= 2 And PeekA(*buffer + start) = $FE And PeekA(*buffer + start + 1) = $FF
        ProcedureReturn PeekS(*buffer + start + 2, (length - 2) / 2, #PB_UTF16BE)
      Else
        ProcedureReturn PeekS(*buffer + start, length / 2, #PB_Unicode)
      EndIf

    Case 2
      ProcedureReturn PeekS(*buffer + start, length / 2, #PB_UTF16BE)

    Case 3
      ProcedureReturn PeekS(*buffer + start, length, #PB_UTF8 | #PB_ByteLength)
  EndSelect

  ProcedureReturn ""
EndProcedure

Procedure.i AttachArtworkFile(path.s)
  Protected targetFolder.s
  Protected targetFile.s

  If State\movieLoaded = 0 Or State\movieHasVideo
    ProcedureReturn #False
  EndIf

  If IsImageFile(path) = 0 Or FileSize(path) < 0
    ProcedureReturn #False
  EndIf

  targetFolder = AppPath + #AlbumArtFolder
  If EnsureDirectoryPath(targetFolder) = 0
    ProcedureReturn #False
  EndIf

  targetFile = targetFolder + SanitizeFileComponent(GetTrackDisplayName()) + ".png"
  If LCase(GetExtensionPart(path)) = "png"
    If CopyFile(path, targetFile) = 0
      ProcedureReturn #False
    EndIf
  Else
    If LoadArtworkImage(path) = 0
      ProcedureReturn #False
    EndIf
    If SaveImage(State\artworkImage, targetFile, #PB_ImagePlugin_PNG) = 0
      ProcedureReturn #False
    EndIf
  EndIf

  If LoadArtworkImage(targetFile)
    State\artworkSource = "attached"
    ResizeMainForAudio(#True)
    UpdateLayout()
    UpdateMetadataPanel()
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.i AttachLyricsFile(path.s)
  Protected content.s
  Protected targetFolder.s
  Protected targetFile.s

  If State\movieLoaded = 0 Or IsLyricsFile(path) = 0 Or FileSize(path) < 0
    ProcedureReturn #False
  EndIf

  If ReadFile(0, path)
    content = ReadString(0, #PB_File_IgnoreEOL)
    While Eof(0) = 0
      content + #CRLF$ + ReadString(0, #PB_File_IgnoreEOL)
    Wend
    CloseFile(0)
  EndIf

  If Trim(content) = ""
    ProcedureReturn #False
  EndIf

  targetFolder = AppPath + #LyricsFolder
  If EnsureDirectoryPath(targetFolder) = 0
    ProcedureReturn #False
  EndIf

  targetFile = targetFolder + SanitizeFileComponent(GetTrackDisplayName()) + "-attached.txt"
  If CreateFile(0, targetFile) = 0
    ProcedureReturn #False
  EndIf

  WriteString(0, NormalizeLineBreaks(content), #PB_UTF8)
  CloseFile(0)
  State\lyricsFile = targetFile
  State\lyricsSource = "attached"
  UpdateMetadataPanel()
  UpdateLyricsWindow()
  ProcedureReturn #True
EndProcedure

Procedure.s ReadUTF8LengthPrefixedString(*buffer, *offset.Integer)
  Protected length.i
  Protected value.s

  length = PeekL(*buffer + *offset\i)
  *offset\i + 4
  If length > 0
    value = PeekS(*buffer + *offset\i, length, #PB_UTF8 | #PB_ByteLength)
    *offset\i + length
  EndIf

  ProcedureReturn value
EndProcedure

Procedure.i ParseFLACMediaInfo(path.s, *info.EmbeddedMediaInfo)
  Protected file.i
  Protected fileSize.q
  Protected *buffer
  Protected offset.i
  Protected lastBlock.i
  Protected blockType.i
  Protected blockLength.i
  Protected commentOffset.Integer
  Protected vendorLength.i
  Protected commentCount.i
  Protected i.i
  Protected keyValue.s
  Protected separator.i
  Protected key.s
  Protected value.s
  Protected pictureOffset.Integer
  Protected pictureDataLength.i
  Protected pictureType.i
  Protected mimeLength.i
  Protected descriptionLength.i
  Protected mimeType.s
  Protected artworkExtension.s
  Protected targetFile.s

  If *info = 0 Or FileSize(path) <= 0
    ProcedureReturn #False
  EndIf

  file = ReadFile(#PB_Any, path)
  If file = 0
    ProcedureReturn #False
  EndIf

  fileSize = Lof(file)
  *buffer = AllocateMemory(fileSize)
  If *buffer = 0
    CloseFile(file)
    ProcedureReturn #False
  EndIf

  If ReadData(file, *buffer, fileSize) <> fileSize
    FreeMemory(*buffer)
    CloseFile(file)
    ProcedureReturn #False
  EndIf
  CloseFile(file)

  If fileSize < 4 Or PeekS(*buffer, 4, #PB_Ascii) <> "fLaC"
    FreeMemory(*buffer)
    ProcedureReturn #False
  EndIf

  offset = 4
  Repeat
    If offset + 4 > fileSize
      Break
    EndIf

    lastBlock = Bool((PeekA(*buffer + offset) & $80) <> 0)
    blockType = PeekA(*buffer + offset) & $7F
    blockLength = ReadBigEndianInteger(*buffer, offset + 1, 3)
    offset + 4
    If offset + blockLength > fileSize
      Break
    EndIf

    Select blockType
      Case 4
        commentOffset\i = offset
        vendorLength = PeekL(*buffer + commentOffset\i)
        commentOffset\i + 4 + vendorLength
        If commentOffset\i + 4 <= offset + blockLength
          commentCount = PeekL(*buffer + commentOffset\i)
          commentOffset\i + 4
          For i = 1 To commentCount
            If commentOffset\i + 4 > offset + blockLength
              Break
            EndIf
            keyValue = ReadUTF8LengthPrefixedString(*buffer, @commentOffset)
            separator = FindString(keyValue, "=")
            If separator > 0
              key = UCase(Left(keyValue, separator - 1))
              value = Mid(keyValue, separator + 1)
              Select key
                Case "ARTIST"
                  If *info\artist = "" : *info\artist = value : EndIf
                Case "TITLE"
                  If *info\title = "" : *info\title = value : EndIf
                Case "LYRICS", "UNSYNCEDLYRICS"
                  If *info\lyrics = "" : *info\lyrics = NormalizeLineBreaks(value) : EndIf
              EndSelect
            EndIf
          Next
        EndIf

      Case 6
        If *info\artworkFile = ""
          pictureOffset\i = offset
          pictureType = ReadBigEndianInteger(*buffer, pictureOffset\i, 4)
          pictureOffset\i + 4
          mimeLength = ReadBigEndianInteger(*buffer, pictureOffset\i, 4)
          pictureOffset\i + 4
          mimeType = PeekS(*buffer + pictureOffset\i, mimeLength, #PB_Ascii)
          pictureOffset\i + mimeLength
          descriptionLength = ReadBigEndianInteger(*buffer, pictureOffset\i, 4)
          pictureOffset\i + 4
          pictureOffset\i + descriptionLength
          pictureOffset\i + 16
          pictureDataLength = ReadBigEndianInteger(*buffer, pictureOffset\i, 4)
          pictureOffset\i + 4
          If pictureType >= 0 And pictureDataLength > 0 And pictureOffset\i + pictureDataLength <= offset + blockLength
            artworkExtension = ".bin"
            If FindString(LCase(mimeType), "png")
              artworkExtension = ".png"
            ElseIf FindString(LCase(mimeType), "jpeg") Or FindString(LCase(mimeType), "jpg")
              artworkExtension = ".jpg"
            EndIf
            targetFile = AppPath + #CacheFolder + SanitizeFileComponent(StripAudioExtension(GetFilePart(path))) + "-flac-picture" + artworkExtension
            If EnsureDirectoryPath(GetPathPart(targetFile))
              If CreateFile(0, targetFile)
                WriteData(0, *buffer + pictureOffset\i, pictureDataLength)
                CloseFile(0)
                *info\artworkFile = targetFile
              EndIf
            EndIf
          EndIf
        EndIf
    EndSelect

    offset + blockLength
  Until lastBlock

  FreeMemory(*buffer)
  ProcedureReturn Bool(*info\artist <> "" Or *info\title <> "" Or *info\lyrics <> "" Or *info\artworkFile <> "")
EndProcedure

Procedure.i ExtractEmbeddedMediaInfo(path.s, *info.EmbeddedMediaInfo)
  Protected extension.s = GetFileExtensionLower(path)

  If extension = "flac"
    ProcedureReturn ParseFLACMediaInfo(path, *info)
  EndIf

  ProcedureReturn ParseEmbeddedMediaInfo(path, *info)
EndProcedure

Procedure ClearArtworkImage()
  If State\artworkImage And IsImage(State\artworkImage)
    FreeImage(State\artworkImage)
    State\artworkImage = 0
  EndIf

  State\artworkFile = ""

  If IsGadget(#Gadget_Artwork)
    SetGadgetState(#Gadget_Artwork, 0)
    GadgetToolTip(#Gadget_Artwork, "")
  EndIf

  If State\artworkPreviewImage And IsImage(State\artworkPreviewImage)
    FreeImage(State\artworkPreviewImage)
    State\artworkPreviewImage = 0
  EndIf
EndProcedure

Procedure.i LoadArtworkImage(filePath.s)
  Protected sourceImage.i
  Protected thumbImage.i
  Protected imageWidth.i
  Protected imageHeight.i
  Protected scaledWidth.i
  Protected scaledHeight.i

  ClearArtworkImage()

  If filePath = "" Or FileSize(filePath) < 0
    ProcedureReturn #False
  EndIf

  sourceImage = LoadImage(#PB_Any, filePath)
  If sourceImage = 0
    ProcedureReturn #False
  EndIf

  imageWidth = ImageWidth(sourceImage)
  imageHeight = ImageHeight(sourceImage)
  If imageWidth <= 0 Or imageHeight <= 0
    FreeImage(sourceImage)
    ProcedureReturn #False
  EndIf

  scaledWidth = #DefaultArtworkSize
  scaledHeight = (imageHeight * #DefaultArtworkSize) / imageWidth
  If scaledHeight > #DefaultArtworkSize
    scaledHeight = #DefaultArtworkSize
    scaledWidth = (imageWidth * #DefaultArtworkSize) / imageHeight
  EndIf
  If scaledWidth < 1 : scaledWidth = 1 : EndIf
  If scaledHeight < 1 : scaledHeight = 1 : EndIf

  thumbImage = CopyImage(sourceImage, #PB_Any)
  FreeImage(sourceImage)
  If thumbImage = 0
    ProcedureReturn #False
  EndIf

  ResizeImage(thumbImage, scaledWidth, scaledHeight)
  State\artworkImage = thumbImage
  State\artworkFile = filePath

  If IsGadget(#Gadget_Artwork)
    SetGadgetState(#Gadget_Artwork, ImageID(State\artworkImage))
    GadgetToolTip(#Gadget_Artwork, filePath)
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i ParseEmbeddedMediaInfo(path.s, *info.EmbeddedMediaInfo)
  Protected file.i
  Protected fileSize.q
  Protected *buffer
  Protected tagSize.q
  Protected offset.q
  Protected versionMajor.i
  Protected frameHeaderSize.i
  Protected frameId.s
  Protected frameSize.q
  Protected frameDataOffset.q
  Protected frameEncoding.i
  Protected mimeEnd.i
  Protected descEnd.i
  Protected pictureOffset.i
  Protected pictureSize.i
  Protected extHeaderSize.q
  Protected tempArtist.s
  Protected tempTitle.s
  Protected tempLyrics.s
  Protected targetFile.s
  Protected id3v1Offset.q

  If *info = 0 Or path = "" Or FileSize(path) <= 0
    ProcedureReturn #False
  EndIf

  *info\artist = ""
  *info\title = ""
  *info\lyrics = ""
  *info\artworkFile = ""

  file = ReadFile(#PB_Any, path)
  If file = 0
    ProcedureReturn #False
  EndIf

  fileSize = Lof(file)
  If fileSize <= 0
    CloseFile(file)
    ProcedureReturn #False
  EndIf

  *buffer = AllocateMemory(fileSize)
  If *buffer = 0
    CloseFile(file)
    ProcedureReturn #False
  EndIf

  If ReadData(file, *buffer, fileSize) <> fileSize
    FreeMemory(*buffer)
    CloseFile(file)
    ProcedureReturn #False
  EndIf
  CloseFile(file)

  If fileSize >= 10 And PeekS(*buffer, 3, #PB_Ascii) = "ID3"
    versionMajor = PeekA(*buffer + 3) & $FF
    tagSize = ReadSyncSafeInteger(*buffer, 6)
    offset = 10
    frameHeaderSize = 10

    If (PeekA(*buffer + 5) & $40) And versionMajor >= 3
      If versionMajor = 4
        extHeaderSize = ReadSyncSafeInteger(*buffer, offset)
      Else
        extHeaderSize = ReadBigEndianInteger(*buffer, offset, 4)
      EndIf
      offset + extHeaderSize
    EndIf

    While offset + frameHeaderSize <= 10 + tagSize And offset + frameHeaderSize <= fileSize
      frameId = PeekS(*buffer + offset, 4, #PB_Ascii)
      If frameId = "" Or Trim(frameId) = ""
        Break
      EndIf

      If versionMajor = 4
        frameSize = ReadSyncSafeInteger(*buffer, offset + 4)
      Else
        frameSize = ReadBigEndianInteger(*buffer, offset + 4, 4)
      EndIf

      If frameSize <= 0
        Break
      EndIf

      frameDataOffset = offset + frameHeaderSize
      If frameDataOffset + frameSize > fileSize
        Break
      EndIf

      Select frameId
        Case "TPE1"
          tempArtist = ReadID3TextFrame(*buffer + frameDataOffset, frameSize)
          If tempArtist <> "" : *info\artist = tempArtist : EndIf

        Case "TIT2"
          tempTitle = ReadID3TextFrame(*buffer + frameDataOffset, frameSize)
          If tempTitle <> "" : *info\title = tempTitle : EndIf

        Case "USLT"
          If frameSize > 4
            frameEncoding = PeekA(*buffer + frameDataOffset) & $FF
            descEnd = FindTerminatorOffset(*buffer + frameDataOffset, 4, frameSize, frameEncoding)
            If descEnd >= 0 And descEnd < frameSize
              If frameEncoding = 0 Or frameEncoding = 3
                tempLyrics = ReadEncodedField(*buffer + frameDataOffset, descEnd + 1, frameSize, frameEncoding)
              Else
                tempLyrics = ReadEncodedField(*buffer + frameDataOffset, descEnd + 2, frameSize, frameEncoding)
              EndIf
              If tempLyrics <> "" : *info\lyrics = NormalizeLineBreaks(tempLyrics) : EndIf
            EndIf
          EndIf

        Case "APIC"
          If frameSize > 4 And *info\artworkFile = ""
            frameEncoding = PeekA(*buffer + frameDataOffset) & $FF
            mimeEnd = FindTerminatorOffset(*buffer + frameDataOffset, 1, frameSize, 0)
            If mimeEnd > 1 And mimeEnd < frameSize - 1
              If frameEncoding = 0 Or frameEncoding = 3
                descEnd = FindTerminatorOffset(*buffer + frameDataOffset, mimeEnd + 3, frameSize, frameEncoding)
                If descEnd >= 0
                  pictureOffset = descEnd + 1
                EndIf
              Else
                descEnd = FindTerminatorOffset(*buffer + frameDataOffset, mimeEnd + 3, frameSize, frameEncoding)
                If descEnd >= 0
                  pictureOffset = descEnd + 2
                EndIf
              EndIf

              If pictureOffset > 0 And pictureOffset < frameSize
                pictureSize = frameSize - pictureOffset
                targetFile = AppPath + #CacheFolder + SanitizeFileComponent(StripAudioExtension(GetFilePart(path))) + "-embedded.png"
                If EnsureDirectoryPath(GetPathPart(targetFile))
                  If CreateFile(0, targetFile)
                    WriteData(0, *buffer + frameDataOffset + pictureOffset, pictureSize)
                    CloseFile(0)
                    *info\artworkFile = targetFile
                  EndIf
                EndIf
              EndIf
            EndIf
          EndIf
      EndSelect

      offset + frameHeaderSize + frameSize
    Wend
  EndIf

  If (*info\artist = "" Or *info\title = "") And fileSize >= 128
    id3v1Offset = fileSize - 128
    If PeekS(*buffer + id3v1Offset, 3, #PB_Ascii) = "TAG"
      If *info\title = ""
        *info\title = Trim(PeekS(*buffer + id3v1Offset + 3, 30, #PB_Ascii))
      EndIf
      If *info\artist = ""
        *info\artist = Trim(PeekS(*buffer + id3v1Offset + 33, 30, #PB_Ascii))
      EndIf
    EndIf
  EndIf

  FreeMemory(*buffer)
  ProcedureReturn Bool(*info\artist <> "" Or *info\title <> "" Or *info\lyrics <> "" Or *info\artworkFile <> "")
EndProcedure

Procedure.i FillTrackMetadataFromCurrentMedia(*metadata.TrackMetadata)
  Protected embedded.EmbeddedMediaInfo

  If *metadata = 0
    ProcedureReturn #False
  EndIf

  *metadata\artist = Trim(State\artist)
  *metadata\title = Trim(State\title)
  *metadata\query = ""
  *metadata\safeBaseName = SanitizeFileComponent(StripAudioExtension(State\fileName))

  If *metadata\artist = "" And *metadata\title = "" And State\moviePath <> ""
    ExtractEmbeddedMediaInfo(State\moviePath, @embedded)
    If embedded\artist <> "" : *metadata\artist = embedded\artist : EndIf
    If embedded\title <> "" : *metadata\title = embedded\title : EndIf
  EndIf

  If *metadata\artist = "" And *metadata\title = ""
    ExtractMetadataFromFilename(State\fileName, *metadata)
  Else
    If *metadata\artist <> "" And *metadata\title <> ""
      *metadata\query = *metadata\artist + " " + *metadata\title
      *metadata\safeBaseName = SanitizeFileComponent(*metadata\artist + " - " + *metadata\title)
    ElseIf *metadata\title <> ""
      *metadata\query = *metadata\title
    Else
      *metadata\query = *metadata\artist
    EndIf
  EndIf

  ProcedureReturn Bool(*metadata\query <> "")
EndProcedure

Procedure.s GetSelectedLibraryFile()
  Protected key.s = GetSelectedLibraryNodeKey()

  If key = ""
    ProcedureReturn ""
  EndIf

  If FindMapElement(LibraryNodePath(), key) And FindMapElement(LibraryNodeKind(), key)
    If LibraryNodeKind() = #PB_DirectoryEntry_File
      ProcedureReturn LibraryNodePath()
    EndIf
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.i FillTrackMetadataFromPath(path.s, *metadata.TrackMetadata)
  Protected embedded.EmbeddedMediaInfo
  Protected fileName.s

  If *metadata = 0 Or path = ""
    ProcedureReturn #False
  EndIf

  fileName = GetFilePart(path)
  *metadata\artist = ""
  *metadata\title = ""
  *metadata\query = ""
  *metadata\safeBaseName = SanitizeFileComponent(StripAudioExtension(fileName))

  ExtractEmbeddedMediaInfo(path, @embedded)
  If embedded\artist <> "" : *metadata\artist = embedded\artist : EndIf
  If embedded\title <> "" : *metadata\title = embedded\title : EndIf

  If *metadata\artist = "" And *metadata\title = ""
    ExtractMetadataFromFilename(fileName, *metadata)
  Else
    If *metadata\artist <> "" And *metadata\title <> ""
      *metadata\query = *metadata\artist + " " + *metadata\title
      *metadata\safeBaseName = SanitizeFileComponent(*metadata\artist + " - " + *metadata\title)
    ElseIf *metadata\title <> ""
      *metadata\query = *metadata\title
    Else
      *metadata\query = *metadata\artist
    EndIf
  EndIf

  ProcedureReturn Bool(*metadata\query <> "")
EndProcedure

Procedure.i DownloadAlbumArtToFile(*metadata.TrackMetadata, *targetFile.String)
  Protected lookup.TrackLookup
  Protected targetFolder.s
  Protected savedFile.s

  If *metadata = 0 Or *targetFile = 0
    ProcedureReturn #False
  EndIf

  If ResolveTrackLookup(*metadata, @lookup) = 0 Or lookup\artworkUrl = ""
    ProcedureReturn #False
  EndIf

  targetFolder = AppPath + #AlbumArtFolder
  If EnsureDirectoryPath(targetFolder) = 0
    ProcedureReturn #False
  EndIf

  If lookup\artist <> "" And lookup\title <> ""
    savedFile = targetFolder + SanitizeFileComponent(lookup\artist + " - " + lookup\title) + ".png"
  Else
    savedFile = targetFolder + *metadata\safeBaseName + ".png"
  EndIf

  If SaveHTTPImageAsPNG(lookup\artworkUrl, savedFile) = 0
    ProcedureReturn #False
  EndIf

  *targetFile\s = savedFile
  ProcedureReturn #True
EndProcedure

Procedure.i DownloadLyricsText(*metadata.TrackMetadata, *lyrics.String)
  Protected lookup.TrackLookup
  Protected response.s
  Protected json.i
  Protected root.i
  Protected artistForQuery.s
  Protected titleForQuery.s

  If *metadata = 0 Or *lyrics = 0
    ProcedureReturn #False
  EndIf

  ResolveTrackLookup(*metadata, @lookup)

  artistForQuery = *metadata\artist
  titleForQuery = *metadata\title
  If lookup\artist <> "" : artistForQuery = lookup\artist : EndIf
  If lookup\title <> "" : titleForQuery = lookup\title : EndIf

  If artistForQuery = "" Or titleForQuery = ""
    ProcedureReturn #False
  EndIf

  response = DownloadText("https://api.lyrics.ovh/v1/" + UrlEncodeUTF8(artistForQuery) + "/" + UrlEncodeUTF8(titleForQuery))
  If response = ""
    ProcedureReturn #False
  EndIf

  json = CreateJSON(#PB_Any)
  If json = 0
    ProcedureReturn #False
  EndIf

  If ParseJSON(json, response) = 0
    FreeJSON(json)
    ProcedureReturn #False
  EndIf

  root = JSONValue(json)
  response = NormalizeLineBreaks(DecodeHtmlEntities(GetJSONMemberStringSafe(root, "lyrics")))
  FreeJSON(json)

  response = Trim(response)
  If response = ""
    ProcedureReturn #False
  EndIf

  *lyrics\s = response
  ProcedureReturn #True
EndProcedure

Procedure.i ExtractMetadataFromFilename(fileName.s, *metadata.TrackMetadata)
  Protected baseName.s = StripAudioExtension(fileName)
  Protected separator.i

  If *metadata = 0
    ProcedureReturn #False
  EndIf

  *metadata\artist = ""
  *metadata\title = ""
  *metadata\query = Trim(baseName)
  *metadata\safeBaseName = SanitizeFileComponent(baseName)

  separator = FindString(baseName, " - ")
  If separator > 0
    *metadata\artist = Trim(Left(baseName, separator - 1))
    *metadata\title = Trim(Mid(baseName, separator + 3))
  Else
    separator = FindString(baseName, " – ")
    If separator > 0
      *metadata\artist = Trim(Left(baseName, separator - 1))
      *metadata\title = Trim(Mid(baseName, separator + 3))
    EndIf
  EndIf

  If *metadata\artist <> "" And *metadata\title <> ""
    *metadata\query = *metadata\artist + " " + *metadata\title
    *metadata\safeBaseName = SanitizeFileComponent(*metadata\artist + " - " + *metadata\title)
    ProcedureReturn #True
  EndIf

  ProcedureReturn Bool(*metadata\query <> "")
EndProcedure

Procedure.s DownloadText(url.s)
  Protected *buffer
  Protected result.s
  Protected size.i

  *buffer = ReceiveHTTPMemory(url, 0, #HTTPUserAgent)
  If *buffer
    size = MemorySize(*buffer)
    If size > 0
      result = PeekS(*buffer, size, #PB_UTF8 | #PB_ByteLength)
    EndIf
    FreeMemory(*buffer)
  EndIf

  ProcedureReturn result
EndProcedure

Procedure.s GetJSONMemberStringSafe(node.i, key.s)
  Protected member.i

  If node = 0
    ProcedureReturn ""
  EndIf

  member = GetJSONMember(node, key)
  If member
    ProcedureReturn GetJSONString(member)
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.i SaveHTTPImageAsPNG(url.s, destinationFile.s)
  Protected result.i = #False
  Protected image.i = #PB_Any
  Protected tempFolder.s
  Protected tempFile.s

  If url = "" Or destinationFile = ""
    ProcedureReturn #False
  EndIf

  tempFolder = AppPath + #CacheFolder
  If EnsureDirectoryPath(tempFolder) = 0
    ProcedureReturn #False
  EndIf

  tempFile = tempFolder + "downloaded-artwork.tmp"
  If ReceiveHTTPFile(url, tempFile, 0, #HTTPUserAgent) = 0
    ProcedureReturn #False
  EndIf

  image = LoadImage(#PB_Any, tempFile)
  If image
    result = SaveImage(image, destinationFile, #PB_ImagePlugin_PNG)
    FreeImage(image)
  EndIf

  If FileSize(tempFile) >= 0
    DeleteFile(tempFile)
  EndIf

  ProcedureReturn result
EndProcedure

Procedure.i ResolveTrackLookup(*metadata.TrackMetadata, *lookup.TrackLookup)
  Protected response.s
  Protected json.i
  Protected root.i
  Protected results.i
  Protected firstItem.i

  If *metadata = 0 Or *lookup = 0
    ProcedureReturn #False
  EndIf

  If *metadata\query = ""
    ProcedureReturn #False
  EndIf

  response = DownloadText("https://itunes.apple.com/search?media=music&entity=song&limit=1&term=" + UrlEncodeUTF8(*metadata\query))
  If response = ""
    ProcedureReturn #False
  EndIf

  json = CreateJSON(#PB_Any)
  If json = 0
    ProcedureReturn #False
  EndIf

  If ParseJSON(json, response) = 0
    FreeJSON(json)
    ProcedureReturn #False
  EndIf

  root = JSONValue(json)
  results = GetJSONMember(root, "results")
  If results And JSONArraySize(results) > 0
    firstItem = GetJSONElement(results, 0)
    If firstItem
      *lookup\artist = GetJSONMemberStringSafe(firstItem, "artistName")
      *lookup\title = GetJSONMemberStringSafe(firstItem, "trackName")
      *lookup\artworkUrl = GetJSONMemberStringSafe(firstItem, "artworkUrl100")
      If *lookup\artworkUrl <> ""
        *lookup\artworkUrl = ReplaceString(*lookup\artworkUrl, "100x100bb", "1000x1000bb")
      EndIf
      FreeJSON(json)
      ProcedureReturn Bool(*lookup\artist <> "" Or *lookup\title <> "" Or *lookup\artworkUrl <> "")
    EndIf
  EndIf

  FreeJSON(json)
  ProcedureReturn #False
EndProcedure

Procedure.i DownloadAlbumArtForCurrentMedia()
  Protected metadata.TrackMetadata
  Protected targetFile.String
  Protected selectedFile.s
  Protected shouldApplyToCurrentTrack.i = #False

  selectedFile = GetSelectedLibraryFile()
  If selectedFile <> ""
    If FillTrackMetadataFromPath(selectedFile, @metadata) = 0
      MessageRequester("Album Art", "Could not determine artist/title for the selected file.", #PB_MessageRequester_Warning)
      ProcedureReturn #False
    EndIf
    shouldApplyToCurrentTrack = Bool(State\movieLoaded And State\moviePath <> "" And LCase(State\moviePath) = LCase(selectedFile))
  Else
    If State\movieLoaded = 0 Or State\moviePath = ""
      MessageRequester("Album Art", "Select a file in the music tree or load an audio file first.", #PB_MessageRequester_Info)
      ProcedureReturn #False
    EndIf

    If State\movieHasVideo
      MessageRequester("Album Art", "Album art download is only available for audio files.", #PB_MessageRequester_Info)
      ProcedureReturn #False
    EndIf

    If FillTrackMetadataFromCurrentMedia(@metadata) = 0
      MessageRequester("Album Art", "Could not determine artist/title for the current track.", #PB_MessageRequester_Warning)
      ProcedureReturn #False
    EndIf
    shouldApplyToCurrentTrack = #True
  EndIf

  If metadata\query = ""
    MessageRequester("Album Art", "Could not determine artist/title for the selected track.", #PB_MessageRequester_Warning)
    ProcedureReturn #False
  EndIf

  If DownloadAlbumArtToFile(@metadata, @targetFile) = 0
    MessageRequester("Album Art", "No album art result was found online for this track.", #PB_MessageRequester_Warning)
    ProcedureReturn #False
  EndIf

  If shouldApplyToCurrentTrack
    If LoadArtworkImage(targetFile\s)
      If State\movieHasVideo = 0
        ResizeMainForAudio(#True)
      EndIf
      State\artworkSource = "downloaded"
      UpdateMetadataPanel()
      UpdateLayout()
      StatusBarText(0, 0, "Album art saved to '" + GetFilePart(targetFile\s) + "'.", #PB_StatusBar_Center)
      MessageRequester("Album Art", "Album art saved to:" + #CRLF$ + targetFile\s, #PB_MessageRequester_Info)
      ProcedureReturn #True
    EndIf

    MessageRequester("Album Art", "Album art download failed.", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  StatusBarText(0, 0, "Album art saved to '" + GetFilePart(targetFile\s) + "'.", #PB_StatusBar_Center)
  MessageRequester("Album Art", "Album art saved to:" + #CRLF$ + targetFile\s, #PB_MessageRequester_Info)
  ProcedureReturn #True
EndProcedure

Procedure.i DownloadLyricsForCurrentMedia()
  Protected metadata.TrackMetadata
  Protected targetFolder.s
  Protected targetFile.s
  Protected lyrics.String
  Protected selectedFile.s

  selectedFile = GetSelectedLibraryFile()
  If selectedFile <> ""
    If FillTrackMetadataFromPath(selectedFile, @metadata) = 0
      MessageRequester("Lyrics", "Could not determine artist/title for the selected file.", #PB_MessageRequester_Warning)
      ProcedureReturn #False
    EndIf
  Else
    If State\fileName = ""
      MessageRequester("Lyrics", "Select a file in the music tree or load an audio file first.", #PB_MessageRequester_Info)
      ProcedureReturn #False
    EndIf

    If FillTrackMetadataFromCurrentMedia(@metadata) = 0
      MessageRequester("Lyrics", "Could not determine artist/title for the current track.", #PB_MessageRequester_Warning)
      ProcedureReturn #False
    EndIf
  EndIf

  If DownloadLyricsText(@metadata, @lyrics) = 0
    MessageRequester("Lyrics", "No lyrics result was found online for this track.", #PB_MessageRequester_Warning)
    ProcedureReturn #False
  EndIf

  targetFolder = AppPath + #LyricsFolder
  If EnsureDirectoryPath(targetFolder) = 0
    MessageRequester("Lyrics", "Could not create the lyrics download folder.", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  targetFile = targetFolder + metadata\safeBaseName + ".txt"
  If CreateFile(0, targetFile)
    WriteString(0, lyrics\s, #PB_UTF8)
    CloseFile(0)
    State\lyricsFile = targetFile
    State\lyricsSource = "downloaded"
    UpdateMetadataPanel()
    StatusBarText(0, 0, "Lyrics saved to '" + GetFilePart(targetFile) + "'.", #PB_StatusBar_Center)
    ShowLyricsWindow()
    MessageRequester("Lyrics", "Lyrics saved to:" + #CRLF$ + targetFile, #PB_MessageRequester_Info)
    ProcedureReturn #True
  EndIf

  MessageRequester("Lyrics", "Could not save the lyrics file.", #PB_MessageRequester_Error)
  ProcedureReturn #False
EndProcedure
