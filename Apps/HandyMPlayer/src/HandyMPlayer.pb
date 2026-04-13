;
; Handy Media Player
;

IncludeFile "HandyMPlayer_Inc.pb"

EnableExplicit

UseJPEGImageDecoder()
UseJPEGImageEncoder()
UsePNGImageDecoder()
UsePNGImageEncoder()

Global isUserSeeking.i = 0

; Global variables moved to State structure or handled by Include
Global version.s = "v1.0.3.0"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Initialize Resources
Global hMutex.i, iconlib.s, AboutIcon.i, LoadIcon.i, PauseIcon.i, PlayIcon.i, StopIcon.i

Structure PlayerState
  volume.i
  balance.i
  winX.i
  winY.i
  movieLoaded.i
  moviePath.s
  movieState.i
  movieLengthFrames.q
  movieFPS_x1000.q
  movieHasVideo.i
  
  audioStartMS.q
  audioPausedElapsedMS.q
  audioTotalMS.q
  audioTotalFrames.q
  
  previousMovieStatus.q
  lastProgressUpdate.i
  currentVolume.i
  currentBalance.i
  fileName.s
  artist.s
  title.s
  metadataSource.s
  lyricsSource.s
  artworkSource.s
  lyricsFile.s
  artworkFile.s
  artworkImage.i
  artworkPreviewImage.i
  playlistIndex.i
  sidebarWidth.i
  draggingSidebar.i
  targetW.i
  targetH.i
EndStructure

Global State.PlayerState
Global NewList Playlist.s()
Global NewList PlaylistNames.s()
Global NewList QueueTracks.s()
Global NewList LibraryFiles.s()
Global NewMap LibraryNodePath.s()
Global NewMap LibraryNodeKind.i()
Global NewMap PlaylistSearch.s()
Global LibraryRootPath.s
Global LastPlaylistPath.s
Global CurrentPlaylistName.s

Declare EnsureVideoHostWindow()
Declare KeepStatusBarOnTop()
Declare UpdateLayout()
Declare ResizeMainForAudio(hasArtwork.i)
Declare LoadFile(path.s)
Declare StopPlayback()
Declare TogglePlayback()
Declare.s FormatTime(seconds.q)
Declare.i EnsureDirectoryPath(path.s)
Declare.s SanitizeFileComponent(value.s)
Declare.s UrlEncodeUTF8(value.s)
Declare.s DecodeHtmlEntities(value.s)
Declare.s StripAudioExtension(name.s)
Declare.i ExtractMetadataFromFilename(fileName.s, *metadata.TrackMetadata)
Declare.s DownloadText(url.s)
Declare.i DownloadAlbumArtForCurrentMedia()
Declare.i DownloadLyricsForCurrentMedia()
Declare.s GetJSONMemberStringSafe(node.i, key.s)
Declare.i SaveHTTPImageAsPNG(url.s, destinationFile.s)
Declare.i ResolveTrackLookup(*metadata.TrackMetadata, *lookup.TrackLookup)
Declare.s NormalizeLineBreaks(text.s)
Declare.s GetTrackDisplayName()
Declare.i ParseEmbeddedMediaInfo(path.s, *info.EmbeddedMediaInfo)
Declare.i FillTrackMetadataFromCurrentMedia(*metadata.TrackMetadata)
Declare.i FillTrackMetadataFromPath(path.s, *metadata.TrackMetadata)
Declare.s GetSelectedLibraryFile()
Declare.i LoadArtworkImage(filePath.s)
Declare.i DownloadAlbumArtToFile(*metadata.TrackMetadata, *targetFile.String)
Declare.i DownloadLyricsText(*metadata.TrackMetadata, *lyrics.String)
Declare ShowLyricsWindow()
Declare UpdateLyricsWindow()
Declare ClearArtworkImage()
Declare UpdateMetadataPanel()
Declare.s GetFileExtensionLower(path.s)
Declare.i IsImageFile(path.s)
Declare.i IsLyricsFile(path.s)
Declare.s FindFolderArtwork(path.s)
Declare.i AttachArtworkFile(path.s)
Declare.i AttachLyricsFile(path.s)
Declare.i ParseFLACMediaInfo(path.s, *info.EmbeddedMediaInfo)
Declare.i ExtractEmbeddedMediaInfo(path.s, *info.EmbeddedMediaInfo)
Declare.s ReadUTF8LengthPrefixedString(*buffer, *offset.Integer)
Declare LoadPlaylistFromRequester()
Declare LoadPlaylistFiles(List files.s())
Declare PlayPlaylistIndex(index.i)
Declare PlayNextTrack(direction.i)
Declare ShowArtworkPreview()
Declare UpdateArtworkPreview()
Declare.s QuoteArg(value.s)
Declare.i IsMediaFile(path.s)
Declare BuildLibraryTree(rootPath.s)
Declare RefreshPlaylistGadget()
Declare AddToPlaylist(path.s)
Declare AddFolderToPlaylist(folderPath.s)
Declare PlaySelectedLibraryItem()
Declare AddSelectedLibraryItemToPlaylist()
Declare BuildLibraryTreeFiltered(rootPath.s, filterText.s)
Declare.i AddLibraryFolderRecursiveFiltered(basePath.s, relativePath.s, depth.i, filterText.s)
Declare.i RelativePathMatchesFilter(relativePath.s, filterText.s)
Declare RevealSelectedLibraryItem()
Declare SavePlaylistToFile()
Declare LoadPlaylistFromM3U()
Declare LoadPlaylistFromPath(path.s)
Declare RemoveSelectedPlaylistItem()
Declare ClearPlaylistItems()
Declare MovePlaylistItem(direction.i)
Declare ResetPlaylistState(clearLastPath.i = #False)
Declare RefreshPlaylistSelector()
Declare SaveCurrentPlaylistStore()
Declare LoadNamedPlaylist(name.s)
Declare SaveNamedPlaylist(name.s)
Declare LoadStoredPlaylists()
Declare CreateNewPlaylist()
Declare RenameCurrentPlaylist()
Declare DeleteCurrentPlaylist()
Declare HighlightNowPlaying()
Declare RefreshQueueGadget()
Declare AddSelectedLibraryItemToQueue()
Declare PlayNextQueuedOrPlaylist(direction.i)
Declare SaveQueueStore()
Declare LoadQueueStore()
Declare RemoveSelectedQueueItem()
Declare MoveQueueItem(direction.i)
Declare.s GetSelectedLibraryNodeKey()
Declare.s GetSelectedLibraryFileByText()
Declare.s GetHelpText()
Declare ShowHelpWindow()

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

Procedure UpdateMetadataPanel()
  Protected primary.s
  Protected secondary.s

  primary = GetTrackDisplayName()
  If State\movieLoaded = 0
    primary = "No media loaded"
  EndIf

  secondary = "Metadata: "
  If State\metadataSource <> ""
    secondary + State\metadataSource
  Else
    secondary + "none"
  EndIf

  secondary + "   Artwork: "
  If State\artworkSource <> ""
    secondary + State\artworkSource
  Else
    secondary + "none"
  EndIf

  secondary + "   Lyrics: "
  If State\lyricsSource <> ""
    secondary + State\lyricsSource
  Else
    secondary + "none"
  EndIf

  If IsGadget(#Gadget_MetadataPrimary)
    SetGadgetText(#Gadget_MetadataPrimary, primary)
  EndIf

  If IsGadget(#Gadget_MetadataSecondary)
    SetGadgetText(#Gadget_MetadataSecondary, secondary)
  EndIf
EndProcedure

Procedure.s QuoteArg(value.s)
  ProcedureReturn Chr(34) + ReplaceString(value, Chr(34), Chr(34) + Chr(34)) + Chr(34)
EndProcedure

Procedure RefreshPlaylistGadget()
  Protected index.i = 0

  If IsGadget(#Gadget_Playlist) = 0
    ProcedureReturn
  EndIf

  ClearGadgetItems(#Gadget_Playlist)
  ForEach Playlist()
    AddGadgetItem(#Gadget_Playlist, -1, GetFilePart(Playlist()))
    SetGadgetItemData(#Gadget_Playlist, index, index)
    If index = State\playlistIndex
      SetGadgetState(#Gadget_Playlist, index)
      SetGadgetItemColor(#Gadget_Playlist, index, #PB_Gadget_FrontColor, RGB(0, 80, 180))
    EndIf
    index + 1
  Next
EndProcedure

Procedure RefreshPlaylistSelector()
  Protected index.i = 0

  If IsGadget(#Gadget_PlaylistTabs) = 0
    ProcedureReturn
  EndIf

  ClearGadgetItems(#Gadget_PlaylistTabs)
  ForEach PlaylistNames()
    AddGadgetItem(#Gadget_PlaylistTabs, -1, PlaylistNames())
    If PlaylistNames() = CurrentPlaylistName
      SetGadgetState(#Gadget_PlaylistTabs, index)
    EndIf
    index + 1
  Next
EndProcedure

Procedure RefreshQueueGadget()
  If IsGadget(#Gadget_QueueList) = 0
    ProcedureReturn
  EndIf

  ClearGadgetItems(#Gadget_QueueList)
  ForEach QueueTracks()
    AddGadgetItem(#Gadget_QueueList, -1, GetFilePart(QueueTracks()))
  Next
EndProcedure

Procedure SaveQueueStore()
  EnsureDirectoryPath(AppPath + #PlaylistStoreFolder)
  If CreateFile(0, AppPath + #QueueStoreFile)
    WriteStringN(0, "#EXTM3U", #PB_UTF8)
    ForEach QueueTracks()
      WriteStringN(0, QueueTracks(), #PB_UTF8)
    Next
    CloseFile(0)
  EndIf
EndProcedure

Procedure LoadQueueStore()
  Protected line.s
  Protected basePath.s = AppPath + #PlaylistStoreFolder

  ClearList(QueueTracks())
  If ReadFile(0, AppPath + #QueueStoreFile)
    While Eof(0) = 0
      line = Trim(ReadString(0))
      If line <> "" And Left(line, 1) <> "#"
        If FindString(line, ":") = 0 And Left(line, 2) <> "\\"
          line = basePath + "\" + line
        EndIf
        If IsMediaFile(line)
          AddElement(QueueTracks())
          QueueTracks() = line
        EndIf
      EndIf
    Wend
    CloseFile(0)
  EndIf
  RefreshQueueGadget()
EndProcedure

Procedure RemoveSelectedQueueItem()
  Protected selected.i = GetGadgetState(#Gadget_QueueList)
  Protected index.i = 0

  If selected < 0
    ProcedureReturn
  EndIf

  ForEach QueueTracks()
    If index = selected
      DeleteElement(QueueTracks())
      Break
    EndIf
    index + 1
  Next

  RefreshQueueGadget()
  SaveQueueStore()
EndProcedure

Procedure MoveQueueItem(direction.i)
  Protected selected.i = GetGadgetState(#Gadget_QueueList)
  Protected swapIndex.i = selected + direction
  Protected index.i = 0
  Protected currentValue.s
  Protected swapValue.s

  If selected < 0 Or swapIndex < 0 Or swapIndex >= ListSize(QueueTracks())
    ProcedureReturn
  EndIf

  ForEach QueueTracks()
    If index = selected
      currentValue = QueueTracks()
    ElseIf index = swapIndex
      swapValue = QueueTracks()
    EndIf
    index + 1
  Next

  index = 0
  ForEach QueueTracks()
    If index = selected
      QueueTracks() = swapValue
    ElseIf index = swapIndex
      QueueTracks() = currentValue
    EndIf
    index + 1
  Next

  RefreshQueueGadget()
  SetGadgetState(#Gadget_QueueList, swapIndex)
  SaveQueueStore()
EndProcedure

Procedure SaveNamedPlaylist(name.s)
  Protected filePath.s

  If name = ""
    ProcedureReturn
  EndIf

  EnsureDirectoryPath(AppPath + #PlaylistStoreFolder)
  filePath = AppPath + #PlaylistStoreFolder + SanitizeFileComponent(name) + ".m3u"
  If CreateFile(0, filePath)
    WriteStringN(0, "#EXTM3U", #PB_UTF8)
    ForEach Playlist()
      WriteStringN(0, Playlist(), #PB_UTF8)
    Next
    CloseFile(0)
    LastPlaylistPath = filePath
  EndIf
EndProcedure

Procedure SaveCurrentPlaylistStore()
  SaveNamedPlaylist(CurrentPlaylistName)
EndProcedure

Procedure LoadNamedPlaylist(name.s)
  Protected path.s

  If name = ""
    ProcedureReturn
  EndIf

  path = AppPath + #PlaylistStoreFolder + SanitizeFileComponent(name) + ".m3u"
  If FileSize(path) >= 0
    CurrentPlaylistName = name
    If FindMapElement(PlaylistSearch(), CurrentPlaylistName)
      SetGadgetText(#Gadget_LibrarySearch, PlaylistSearch())
    Else
      SetGadgetText(#Gadget_LibrarySearch, "")
    EndIf
    LoadPlaylistFromPath(path)
    RefreshPlaylistSelector()
  EndIf
EndProcedure

Procedure LoadStoredPlaylists()
  Protected dir.i
  Protected entry.s
  Protected baseName.s

  ClearList(PlaylistNames())
  EnsureDirectoryPath(AppPath + #PlaylistStoreFolder)

  dir = ExamineDirectory(#PB_Any, AppPath + #PlaylistStoreFolder, "*.m3u")
  If dir
    While NextDirectoryEntry(dir)
      entry = DirectoryEntryName(dir)
      baseName = GetFilePart(entry, #PB_FileSystem_NoExtension)
      AddElement(PlaylistNames())
      PlaylistNames() = baseName
    Wend
    FinishDirectory(dir)
  EndIf

  If ListSize(PlaylistNames()) = 0
    AddElement(PlaylistNames())
    PlaylistNames() = "Default"
    CurrentPlaylistName = "Default"
    SaveNamedPlaylist(CurrentPlaylistName)
  ElseIf CurrentPlaylistName = ""
    FirstElement(PlaylistNames())
    CurrentPlaylistName = PlaylistNames()
  EndIf

  RefreshPlaylistSelector()
EndProcedure

Procedure CreateNewPlaylist()
  Protected name.s = InputRequester("New Playlist", "Playlist name:", "New Playlist")

  name = Trim(name)
  If name = ""
    ProcedureReturn
  EndIf

  AddElement(PlaylistNames())
  PlaylistNames() = name
  CurrentPlaylistName = name
  PlaylistSearch(CurrentPlaylistName) = ""
  ResetPlaylistState()
  SaveNamedPlaylist(CurrentPlaylistName)
  RefreshPlaylistSelector()
EndProcedure

Procedure RenameCurrentPlaylist()
  Protected name.s
  Protected oldPath.s
  Protected newPath.s

  If CurrentPlaylistName = ""
    ProcedureReturn
  EndIf

  name = InputRequester("Rename Playlist", "Playlist name:", CurrentPlaylistName)
  name = Trim(name)
  If name = "" Or name = CurrentPlaylistName
    ProcedureReturn
  EndIf

  oldPath = AppPath + #PlaylistStoreFolder + SanitizeFileComponent(CurrentPlaylistName) + ".m3u"
  newPath = AppPath + #PlaylistStoreFolder + SanitizeFileComponent(name) + ".m3u"
  RenameFile(oldPath, newPath)
  If FindMapElement(PlaylistSearch(), CurrentPlaylistName)
    PlaylistSearch(name) = PlaylistSearch()
    DeleteMapElement(PlaylistSearch())
  EndIf
  CurrentPlaylistName = name
  LoadStoredPlaylists()
  RefreshPlaylistSelector()
EndProcedure

Procedure DeleteCurrentPlaylist()
  Protected path.s

  If CurrentPlaylistName = ""
    ProcedureReturn
  EndIf

  path = AppPath + #PlaylistStoreFolder + SanitizeFileComponent(CurrentPlaylistName) + ".m3u"
  If FileSize(path) >= 0
    DeleteFile(path)
  EndIf

  If FindMapElement(PlaylistSearch(), CurrentPlaylistName)
    DeleteMapElement(PlaylistSearch())
  EndIf

  ResetPlaylistState()
  CurrentPlaylistName = ""
  LoadStoredPlaylists()
  If CurrentPlaylistName <> ""
    LoadNamedPlaylist(CurrentPlaylistName)
  EndIf
EndProcedure

Procedure HighlightNowPlaying()
  Protected itemCount.i
  Protected i.i
  Protected key.s

  If IsGadget(#Gadget_Playlist)
    itemCount = CountGadgetItems(#Gadget_Playlist)
    For i = 0 To itemCount - 1
      SetGadgetItemColor(#Gadget_Playlist, i, #PB_Gadget_FrontColor, RGB(0, 0, 0))
    Next
    If State\playlistIndex >= 0 And State\playlistIndex < itemCount
      SetGadgetItemColor(#Gadget_Playlist, State\playlistIndex, #PB_Gadget_FrontColor, RGB(0, 80, 180))
    EndIf
  EndIf

  If IsGadget(#Gadget_LibraryTree)
    itemCount = CountGadgetItems(#Gadget_LibraryTree)
    For i = 0 To itemCount - 1
      SetGadgetItemColor(#Gadget_LibraryTree, i, #PB_Gadget_FrontColor, RGB(0, 0, 0))
      key = Str(GetGadgetItemData(#Gadget_LibraryTree, i))
      If FindMapElement(LibraryNodePath(), key) And LibraryNodePath() = State\moviePath
        SetGadgetItemColor(#Gadget_LibraryTree, i, #PB_Gadget_FrontColor, RGB(0, 80, 180))
      EndIf
    Next
  EndIf
EndProcedure

Procedure.s GetSelectedLibraryNodeKey()
  Protected index.i = GetGadgetState(#Gadget_LibraryTree)
  Protected rowKey.s
  Protected dataKey.s
  Protected itemText.s

  If index < 0
    ProcedureReturn ""
  EndIf

  itemText = GetGadgetItemText(#Gadget_LibraryTree, index)
  rowKey = Str(index)
  dataKey = Str(GetGadgetItemData(#Gadget_LibraryTree, index))

  If FindMapElement(LibraryNodePath(), rowKey)
    If GetFilePart(LibraryNodePath()) = itemText
      ProcedureReturn rowKey
    EndIf
  EndIf

  If FindMapElement(LibraryNodePath(), dataKey)
    If GetFilePart(LibraryNodePath()) = itemText
      ProcedureReturn dataKey
    EndIf
  EndIf

  If FindMapElement(LibraryNodePath(), dataKey)
    ProcedureReturn dataKey
  EndIf

  If FindMapElement(LibraryNodePath(), rowKey)
    ProcedureReturn rowKey
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s GetSelectedLibraryFileByText()
  Protected index.i = GetGadgetState(#Gadget_LibraryTree)
  Protected itemText.s
  Protected key.s

  If index < 0
    ProcedureReturn ""
  EndIf

  itemText = GetGadgetItemText(#Gadget_LibraryTree, index)

  ForEach LibraryNodePath()
    key = MapKey(LibraryNodePath())
    If FindMapElement(LibraryNodeKind(), key)
      If LibraryNodeKind() = #PB_DirectoryEntry_File And GetFilePart(LibraryNodePath()) = itemText
        ProcedureReturn LibraryNodePath()
      EndIf
    EndIf
  Next

  ProcedureReturn ""
EndProcedure

Procedure AddSelectedLibraryItemToQueue()
  Protected key.s = GetSelectedLibraryNodeKey()

  If key = "" Or FindMapElement(LibraryNodePath(), key) = 0
    ProcedureReturn
  EndIf

  If FindMapElement(LibraryNodeKind(), key)
    If LibraryNodeKind() = #PB_DirectoryEntry_File
      AddElement(QueueTracks())
      QueueTracks() = LibraryNodePath()
    EndIf
    RefreshQueueGadget()
    SaveQueueStore()
  EndIf
EndProcedure

Procedure PlayNextQueuedOrPlaylist(direction.i)
  If ListSize(QueueTracks()) > 0
    FirstElement(QueueTracks())
    LoadFile(QueueTracks())
    DeleteElement(QueueTracks())
    RefreshQueueGadget()
    SaveQueueStore()
  Else
    PlayNextTrack(direction)
  EndIf
EndProcedure

Procedure RemoveSelectedPlaylistItem()
  Protected selected.i = GetGadgetState(#Gadget_Playlist)
  Protected index.i = 0

  If selected < 0
    ProcedureReturn
  EndIf

  ForEach Playlist()
    If index = selected
      DeleteElement(Playlist())
      Break
    EndIf
    index + 1
  Next

  If ListSize(Playlist()) = 0
    State\playlistIndex = -1
  ElseIf State\playlistIndex >= ListSize(Playlist())
    State\playlistIndex = ListSize(Playlist()) - 1
  ElseIf selected <= State\playlistIndex And State\playlistIndex > 0
    State\playlistIndex - 1
  EndIf

  RefreshPlaylistGadget()
  SaveCurrentPlaylistStore()
EndProcedure

Procedure ResetPlaylistState(clearLastPath.i = #False)
  ClearList(Playlist())
  State\playlistIndex = -1
  RefreshPlaylistGadget()
  If clearLastPath
    LastPlaylistPath = ""
  EndIf
EndProcedure

Procedure ClearPlaylistItems()
  ResetPlaylistState(#True)
  SaveCurrentPlaylistStore()
EndProcedure

Procedure MovePlaylistItem(direction.i)
  Protected selected.i = GetGadgetState(#Gadget_Playlist)
  Protected swapIndex.i = selected + direction
  Protected index.i = 0
  Protected currentValue.s
  Protected swapValue.s

  If selected < 0 Or swapIndex < 0 Or swapIndex >= ListSize(Playlist())
    ProcedureReturn
  EndIf

  ForEach Playlist()
    If index = selected
      currentValue = Playlist()
    ElseIf index = swapIndex
      swapValue = Playlist()
    EndIf
    index + 1
  Next

  index = 0
  ForEach Playlist()
    If index = selected
      Playlist() = swapValue
    ElseIf index = swapIndex
      Playlist() = currentValue
    EndIf
    index + 1
  Next

  If State\playlistIndex = selected
    State\playlistIndex = swapIndex
  ElseIf State\playlistIndex = swapIndex
    State\playlistIndex = selected
  EndIf

  RefreshPlaylistGadget()
  SetGadgetState(#Gadget_Playlist, swapIndex)
  SaveCurrentPlaylistStore()
EndProcedure

Procedure AddToPlaylist(path.s)
  If path = "" Or IsMediaFile(path) = 0
    ProcedureReturn
  EndIf

  AddElement(Playlist())
  Playlist() = path
  RefreshPlaylistGadget()
  SaveCurrentPlaylistStore()
EndProcedure

Procedure.i FindPlaylistIndex(path.s)
  Protected index.i = 0

  ForEach Playlist()
    If Playlist() = path
      ProcedureReturn index
    EndIf
    index + 1
  Next

  ProcedureReturn -1
EndProcedure

Procedure AddFolderToPlaylist(folderPath.s)
  Protected dir.i
  Protected entry.s
  Protected fullPath.s
  Protected type.i

  dir = ExamineDirectory(#PB_Any, folderPath, "*")
  If dir = 0
    ProcedureReturn
  EndIf

  While NextDirectoryEntry(dir)
    entry = DirectoryEntryName(dir)
    If entry = "." Or entry = ".."
      Continue
    EndIf

      fullPath = folderPath + "\" + entry
      type = DirectoryEntryType(dir)
      If type = #PB_DirectoryEntry_File
        If IsMediaFile(fullPath)
          If FindPlaylistIndex(fullPath) = -1
            AddElement(Playlist())
            Playlist() = fullPath
          EndIf
        EndIf
      ElseIf type = #PB_DirectoryEntry_Directory
        AddFolderToPlaylist(fullPath)
    EndIf
  Wend

  FinishDirectory(dir)
EndProcedure

Procedure.i RelativePathMatchesFilter(relativePath.s, filterText.s)
  If filterText = ""
    ProcedureReturn #True
  EndIf

  ProcedureReturn Bool(FindString(LCase(relativePath), LCase(filterText)) > 0)
EndProcedure

Procedure.i AddLibraryFolderRecursiveFiltered(basePath.s, relativePath.s, depth.i, filterText.s)
  Protected currentPath.s
  Protected dir.i
  Protected entry.s
  Protected fullPath.s
  Protected relativeChild.s
  Protected itemIndex.i
  Protected type.i
  Protected folderAdded.i
  Protected childAdded.i
  Protected mapKey.s

  currentPath = basePath
  If relativePath <> ""
    currentPath + "\" + relativePath
  EndIf

  dir = ExamineDirectory(#PB_Any, currentPath, "*")
  If dir = 0
    ProcedureReturn 0
  EndIf

  While NextDirectoryEntry(dir)
    entry = DirectoryEntryName(dir)
    If entry = "." Or entry = ".."
      Continue
    EndIf

    fullPath = currentPath + "\" + entry
    type = DirectoryEntryType(dir)
    If relativePath <> ""
      relativeChild = relativePath + "\" + entry
    Else
      relativeChild = entry
    EndIf

    If type = #PB_DirectoryEntry_Directory
      itemIndex = CountGadgetItems(#Gadget_LibraryTree)
      AddGadgetItem(#Gadget_LibraryTree, -1, entry, 0, depth)
      SetGadgetItemData(#Gadget_LibraryTree, itemIndex, itemIndex)
      mapKey = Str(itemIndex)
      LibraryNodePath(mapKey) = fullPath
      LibraryNodeKind(mapKey) = #PB_DirectoryEntry_Directory

      childAdded = AddLibraryFolderRecursiveFiltered(basePath, relativeChild, depth + 1, filterText)
      If childAdded Or filterText = ""
        folderAdded = #True
      Else
        RemoveGadgetItem(#Gadget_LibraryTree, itemIndex)
        DeleteMapElement(LibraryNodePath(), mapKey)
        DeleteMapElement(LibraryNodeKind(), mapKey)
      EndIf
    ElseIf type = #PB_DirectoryEntry_File And IsMediaFile(fullPath)
      AddElement(LibraryFiles())
      LibraryFiles() = fullPath
      If RelativePathMatchesFilter(relativeChild, filterText)
        itemIndex = CountGadgetItems(#Gadget_LibraryTree)
        AddGadgetItem(#Gadget_LibraryTree, -1, entry, 0, depth)
        SetGadgetItemData(#Gadget_LibraryTree, itemIndex, itemIndex)
        LibraryNodePath(Str(itemIndex)) = fullPath
        LibraryNodeKind(Str(itemIndex)) = #PB_DirectoryEntry_File
        folderAdded = #True
      EndIf
    EndIf
  Wend

  FinishDirectory(dir)
  ProcedureReturn folderAdded
EndProcedure

Procedure BuildLibraryTreeFiltered(rootPath.s, filterText.s)
  Protected rootName.s

  If IsGadget(#Gadget_LibraryTree) = 0 Or rootPath = ""
    ProcedureReturn
  EndIf

  ClearMap(LibraryNodePath())
  ClearMap(LibraryNodeKind())
  ClearList(LibraryFiles())
  ClearGadgetItems(#Gadget_LibraryTree)
  LibraryRootPath = rootPath

  rootName = GetFilePart(rootPath)
  If rootName = ""
    rootName = rootPath
  EndIf

  AddLibraryFolderRecursiveFiltered(rootPath, "", 0, filterText)

  If CountGadgetItems(#Gadget_LibraryTree) = 0
    AddGadgetItem(#Gadget_LibraryTree, -1, rootName + " (empty)", 0, 0)
  Else
    SetGadgetState(#Gadget_LibraryTree, 0)
  EndIf
EndProcedure

Procedure RevealSelectedLibraryItem()
  Protected path.s
  Protected key.s = GetSelectedLibraryNodeKey()

  If key = "" Or FindMapElement(LibraryNodePath(), key) = 0
    ProcedureReturn
  EndIf

  path = LibraryNodePath()
  If FileSize(path) = -2
    RunProgram("explorer", QuoteArg(path), "")
  ElseIf FileSize(path) >= 0
    RunProgram("explorer", "/select," + QuoteArg(path), "")
  EndIf
EndProcedure

Procedure SavePlaylistToFile()
  Protected target.s

  target = SaveFileRequester("Save playlist", AppPath + "playlist.m3u", "M3U Playlist|*.m3u", 0)
  If target = ""
    ProcedureReturn
  EndIf

  If CreateFile(0, target)
    WriteStringN(0, "#EXTM3U", #PB_UTF8)
    ForEach Playlist()
      WriteStringN(0, Playlist(), #PB_UTF8)
    Next
    CloseFile(0)
    LastPlaylistPath = target
  EndIf
EndProcedure

Procedure LoadPlaylistFromPath(path.s)
  Protected line.s
  Protected basePath.s
  Protected NewList files.s()

  If path = ""
    ProcedureReturn
  EndIf

  basePath = GetPathPart(path)
  If ReadFile(0, path)
    While Eof(0) = 0
      line = Trim(ReadString(0))
      If line <> "" And Left(line, 1) <> "#"
        If FindString(line, ":") = 0 And Left(line, 2) <> "\\"
          line = basePath + line
        EndIf
        If IsMediaFile(line)
          AddElement(files())
          files() = line
        EndIf
      EndIf
    Wend
    CloseFile(0)
  EndIf

  If ListSize(files()) > 0
    LastPlaylistPath = path
    LoadPlaylistFiles(files())
  Else
    ClearPlaylistItems()
  EndIf
EndProcedure

Procedure LoadPlaylistFromM3U()
  Protected source.s

  source = OpenFileRequester("Load playlist", AppPath, "M3U Playlist|*.m3u", 0)
  If source <> ""
    LoadPlaylistFromPath(source)
  EndIf
EndProcedure

Procedure BuildLibraryTree(rootPath.s)
  BuildLibraryTreeFiltered(rootPath, GetGadgetText(#Gadget_LibrarySearch))
EndProcedure

Procedure PlaySelectedLibraryItem()
  Protected path.s = GetSelectedLibraryFileByText()

  If path = ""
    ProcedureReturn
  EndIf

  State\playlistIndex = FindPlaylistIndex(path)
  If State\playlistIndex = -1
    AddElement(Playlist())
    Playlist() = path
    State\playlistIndex = ListSize(Playlist()) - 1
  EndIf
  RefreshPlaylistGadget()
  LoadFile(path)
  TogglePlayback()
EndProcedure

Procedure AddSelectedLibraryItemToPlaylist()
  Protected key.s = GetSelectedLibraryNodeKey()

  If key = "" Or FindMapElement(LibraryNodePath(), key) = 0 Or FindMapElement(LibraryNodeKind(), key) = 0
    ProcedureReturn
  EndIf

  If LibraryNodeKind() = #PB_DirectoryEntry_File
    AddToPlaylist(LibraryNodePath())
  ElseIf LibraryNodeKind() = #PB_DirectoryEntry_Directory
    AddFolderToPlaylist(LibraryNodePath())
    RefreshPlaylistGadget()
  EndIf
EndProcedure

Procedure LoadPlaylistFiles(List files.s())
  ClearList(Playlist())
  ForEach files()
    If files() <> ""
      AddElement(Playlist())
      Playlist() = files()
    EndIf
  Next

  State\playlistIndex = -1
  RefreshPlaylistGadget()
  If ListSize(Playlist()) > 0
    PlayPlaylistIndex(0)
  EndIf
  SaveCurrentPlaylistStore()
EndProcedure

Procedure LoadPlaylistFromRequester()
  Protected selected.s
  Protected NewList files.s()

  selected = OpenFileRequester("Load media files", "", "Media files|*.asf;*.avi;*.flac;*.mid;*.mp3;*.mp4;*.mpg;*.wav;*.wmv|All Files|*.*", 0, #PB_Requester_MultiSelection)
  While selected
    AddElement(files())
    files() = selected
    selected = NextSelectedFileName()
  Wend

  If ListSize(files()) > 0
    LoadPlaylistFiles(files())
  EndIf
EndProcedure

Procedure PlayPlaylistIndex(index.i)
  Protected i.i

  If index < 0 Or index >= ListSize(Playlist())
    ProcedureReturn
  EndIf

  FirstElement(Playlist())
  For i = 0 To index - 1
    NextElement(Playlist())
  Next

  State\playlistIndex = index
  RefreshPlaylistGadget()
  LoadFile(Playlist())
  HighlightNowPlaying()
EndProcedure

Procedure PlayNextTrack(direction.i)
  If ListSize(Playlist()) = 0
    ProcedureReturn
  EndIf

  PlayPlaylistIndex((State\playlistIndex + direction + ListSize(Playlist())) % ListSize(Playlist()))
EndProcedure

Procedure UpdateArtworkPreview()
  Protected previewImage.i
  Protected width.i
  Protected height.i

  If IsWindow(#Window_ArtworkPreview) = 0 Or State\artworkFile = "" Or FileSize(State\artworkFile) < 0
    ProcedureReturn
  EndIf

  If State\artworkPreviewImage And IsImage(State\artworkPreviewImage)
    FreeImage(State\artworkPreviewImage)
    State\artworkPreviewImage = 0
  EndIf

  previewImage = LoadImage(#PB_Any, State\artworkFile)
  If previewImage = 0
    ProcedureReturn
  EndIf

  State\artworkPreviewImage = previewImage
  width = ImageWidth(previewImage)
  height = ImageHeight(previewImage)
  SetGadgetAttribute(#Gadget_ArtworkScroll, #PB_ScrollArea_InnerWidth, width)
  SetGadgetAttribute(#Gadget_ArtworkScroll, #PB_ScrollArea_InnerHeight, height)
  ResizeGadget(#Gadget_ArtworkPreviewImage, 0, 0, width, height)
  SetGadgetState(#Gadget_ArtworkPreviewImage, ImageID(previewImage))
  SetWindowTitle(#Window_ArtworkPreview, "Artwork - " + GetTrackDisplayName())
EndProcedure

Procedure ShowArtworkPreview()
  If State\artworkFile = "" Or FileSize(State\artworkFile) < 0
    ProcedureReturn
  EndIf

  If IsWindow(#Window_ArtworkPreview) = 0
    If OpenWindow(#Window_ArtworkPreview, #PB_Ignore, #PB_Ignore, #ArtworkPreviewWindowWidth, #ArtworkPreviewWindowHeight, "Artwork", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#Window_Main))
      ScrollAreaGadget(#Gadget_ArtworkScroll, 0, 0, WindowWidth(#Window_ArtworkPreview), WindowHeight(#Window_ArtworkPreview), 400, 400, 16)
      ImageGadget(#Gadget_ArtworkPreviewImage, 0, 0, 400, 400, 0)
      CloseGadgetList()
    EndIf
  EndIf

  If IsWindow(#Window_ArtworkPreview)
    ResizeGadget(#Gadget_ArtworkScroll, 0, 0, WindowWidth(#Window_ArtworkPreview, #PB_Window_InnerCoordinate), WindowHeight(#Window_ArtworkPreview, #PB_Window_InnerCoordinate))
    UpdateArtworkPreview()
    HideWindow(#Window_ArtworkPreview, 0)
    SetActiveWindow(#Window_ArtworkPreview)
  EndIf
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
      Case 4 ; VORBIS_COMMENT
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

      Case 6 ; PICTURE
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

Procedure UpdateLyricsWindow()
  If IsWindow(#Window_Lyrics) = 0
    ProcedureReturn
  EndIf

  SetWindowTitle(#Window_Lyrics, "Lyrics - " + GetTrackDisplayName())
  If IsGadget(#Gadget_LyricsEditor)
    If State\lyricsFile <> "" And ReadFile(0, State\lyricsFile)
      SetGadgetText(#Gadget_LyricsEditor, ReadString(0, #PB_File_IgnoreEOL))
      While Eof(0) = 0
        SetGadgetText(#Gadget_LyricsEditor, GetGadgetText(#Gadget_LyricsEditor) + #CRLF$ + ReadString(0, #PB_File_IgnoreEOL))
      Wend
      CloseFile(0)
    Else
      SetGadgetText(#Gadget_LyricsEditor, "No lyrics loaded for the current track.")
    EndIf
  EndIf
EndProcedure

Procedure ShowLyricsWindow()
  If IsWindow(#Window_Lyrics) = 0
    If OpenWindow(#Window_Lyrics, #PB_Ignore, #PB_Ignore, #LyricsWindowWidth, #LyricsWindowHeight, "Lyrics", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#Window_Main))
      EditorGadget(#Gadget_LyricsEditor, 0, 0, WindowWidth(#Window_Lyrics), WindowHeight(#Window_Lyrics), #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
    EndIf
  EndIf

  If IsWindow(#Window_Lyrics)
    ResizeGadget(#Gadget_LyricsEditor, 0, 0, WindowWidth(#Window_Lyrics, #PB_Window_InnerCoordinate), WindowHeight(#Window_Lyrics, #PB_Window_InnerCoordinate))
    UpdateLyricsWindow()
    HideWindow(#Window_Lyrics, 0)
    SetActiveWindow(#Window_Lyrics)
  EndIf
EndProcedure

Procedure.s GetHelpText()
  Protected helpText.s

  helpText = #APP_NAME + " Help" + #CRLF$ + #CRLF$
  helpText + "Overview" + #CRLF$
  helpText + "HandyMPlayer is a desktop media player for audio and video with a music library tree, named playlists, queue support, and artwork display when available." + #CRLF$ + #CRLF$
  helpText + "Getting Started" + #CRLF$
  helpText + "1. Use File > Load Folder to scan a music library folder recursively." + #CRLF$
  helpText + "2. Select a file in the Library tree and click Play to load and start playback." + #CRLF$
  helpText + "3. Use File > Load to open one or more media files directly into the current playlist." + #CRLF$
  helpText + "4. Use File > Load Playlist / Save Playlist to work with M3U playlists." + #CRLF$ + #CRLF$
  helpText + "Playback" + #CRLF$
  helpText + "- Toolbar Play/Pause starts or toggles playback for the currently loaded media." + #CRLF$
  helpText + "- Stop stops the current file." + #CRLF$
  helpText + "- The progress bar can be clicked or dragged to seek." + #CRLF$
  helpText + "- Left / Right arrow keys move to previous / next queued-or-playlist track." + #CRLF$ + #CRLF$
  helpText + "Library Tree" + #CRLF$
  helpText + "- The Library tree shows folders and supported media files from the loaded root folder." + #CRLF$
  helpText + "- The search box filters the visible library entries." + #CRLF$
  helpText + "- Play loads the selected file and starts playback." + #CRLF$
  helpText + "- Add adds the selected file, or all supported files under a selected folder, to the current playlist." + #CRLF$
  helpText + "- Right-click a library item for Play, Add To Playlist, and Reveal In Explorer." + #CRLF$ + #CRLF$
  helpText + "Playlists" + #CRLF$
  helpText + "- The playlist selector switches between named playlists." + #CRLF$
  helpText + "- + creates a new playlist, R renames it, and - deletes it." + #CRLF$
  helpText + "- Up / Down reorder items in the current playlist." + #CRLF$
  helpText + "- Remove deletes the selected playlist item." + #CRLF$
  helpText + "- Clear empties the current playlist." + #CRLF$
  helpText + "- Double-click a playlist item to load and play it." + #CRLF$ + #CRLF$
  helpText + "Queue" + #CRLF$
  helpText + "- Enqueue adds the selected library file to the queue." + #CRLF$
  helpText + "- The queue is played before the normal playlist next-track behavior." + #CRLF$
  helpText + "- Queue Up / Down reorder queued items." + #CRLF$
  helpText + "- Queue Remove deletes the selected queued item." + #CRLF$
  helpText + "- Queue Clear empties the queue." + #CRLF$ + #CRLF$
  helpText + "Artwork" + #CRLF$
  helpText + "- Audio tracks can show embedded artwork or artwork found in the same folder." + #CRLF$
  helpText + "- Common folder artwork names include cover, folder, front, album, artwork, or the same basename as the track." + #CRLF$
  helpText + "- Supported folder artwork formats include JPG, JPEG, PNG, GIF, and BMP." + #CRLF$
  helpText + "- Click the artwork image to open a larger preview." + #CRLF$ + #CRLF$
  helpText + "Tips" + #CRLF$
  helpText + "- If the music tree looks out of date, reload the folder." + #CRLF$
  helpText + "- For best metadata display, keep filenames in Artist - Title format when tags are missing." + #CRLF$
  helpText + "- The current library root, current playlist, sidebar width, and queue are remembered between runs." + #CRLF$ + #CRLF$
  helpText + "Troubleshooting" + #CRLF$
  helpText + "- If a selected file does not play, try double-clicking it in the tree or adding it to the playlist first." + #CRLF$
  helpText + "- If artwork does not appear, check for embedded art or an image file in the same folder as the track." + #CRLF$
  helpText + "- Video resizing commands affect video files only." + #CRLF$

  ProcedureReturn helpText
EndProcedure

Procedure ShowHelpWindow()
  If IsWindow(#Window_Help) = 0
    If OpenWindow(#Window_Help, #PB_Ignore, #PB_Ignore, #HelpWindowWidth, #HelpWindowHeight, #APP_NAME + " Help", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#Window_Main))
      EditorGadget(#Gadget_HelpEditor, 0, 0, WindowWidth(#Window_Help), WindowHeight(#Window_Help), #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
      SetGadgetText(#Gadget_HelpEditor, GetHelpText())
    EndIf
  EndIf

  If IsWindow(#Window_Help)
    ResizeGadget(#Gadget_HelpEditor, 0, 0, WindowWidth(#Window_Help, #PB_Window_InnerCoordinate), WindowHeight(#Window_Help, #PB_Window_InnerCoordinate))
    HideWindow(#Window_Help, 0)
    SetActiveWindow(#Window_Help)
  EndIf
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

Procedure SetProgressPosition(position.q)
  If IsGadget(#Gadget_Progress)
    isUserSeeking = 0
    SetGadgetState(#Gadget_Progress, position)
    isUserSeeking = 1
  EndIf
EndProcedure

Procedure ResetPlaybackState(clearMediaInfo.i = #True)
  State\movieLoaded = 0
  State\movieState = #MovieState_Ready
  State\movieLengthFrames = 0
  State\movieFPS_x1000 = 0
  State\movieHasVideo = 0
  State\audioStartMS = 0
  State\audioPausedElapsedMS = 0
  State\audioTotalMS = 0
  State\audioTotalFrames = 0
  State\previousMovieStatus = 0
  State\lastProgressUpdate = ElapsedMilliseconds()
  State\currentVolume = -1
  State\currentBalance = -999
  State\artist = ""
  State\title = ""
  State\metadataSource = ""
    State\lyricsSource = ""
    State\artworkSource = ""
    State\lyricsFile = ""
    State\targetW = #WindowWidth + 50
  State\targetH = #WindowHeight + 25

  ClearArtworkImage()
  UpdateMetadataPanel()

  If clearMediaInfo
    State\moviePath = ""
    State\fileName = ""
  EndIf

  SetProgressPosition(0)

  If IsWindow(#Window_Video)
    HideWindow(#Window_Video, 1)
    ResizeWindow(#Window_Video, 0, 0, 0, 0)
  EndIf
EndProcedure

Procedure UpdatePlaybackStatus(prefix.s)
  Protected message.s = prefix

  If GetTrackDisplayName() <> ""
    message + " <> '" + GetTrackDisplayName() + "'"
  EndIf

  If IsStatusBar(0)
    StatusBarText(0, 0, message, #PB_StatusBar_Center)
  EndIf

  If IsGadget(#Gadget_Progress)
    GadgetToolTip(#Gadget_Progress, message)
  EndIf
EndProcedure

Procedure UpdateAudioTimeStatus(elapsedMS.q)
  If IsStatusBar(0) = 0
    ProcedureReturn
  EndIf

  If State\audioTotalMS > 0
    StatusBarText(0, 0, GetTrackDisplayName() + "  " + FormatTime(elapsedMS / 1000) + "/" + FormatTime(State\audioTotalMS / 1000), #PB_StatusBar_Center)
  ElseIf GetTrackDisplayName() <> ""
    StatusBarText(0, 0, GetTrackDisplayName() + "  " + FormatTime(elapsedMS / 1000), #PB_StatusBar_Center)
  EndIf
EndProcedure

Procedure ApplyAudioSettings()
  If State\movieLoaded And IsMovie(0)
    If State\currentVolume <> State\volume Or State\currentBalance <> State\balance
      MovieAudio(0, State\volume, State\balance)
      State\currentVolume = State\volume
      State\currentBalance = State\balance
    EndIf
  EndIf
EndProcedure

Procedure PausePlayback()
  If State\movieLoaded And State\movieState = #MovieState_Playing
    PauseMovie(0)
    State\movieState = #MovieState_Paused
    UpdatePlaybackStatus("Paused")

    If State\movieHasVideo = 0 And State\audioStartMS > 0
      State\audioPausedElapsedMS = ElapsedMilliseconds() - State\audioStartMS
    EndIf
  EndIf
EndProcedure

Procedure StopPlayback()
  If State\movieLoaded And (State\movieState = #MovieState_Playing Or State\movieState = #MovieState_Paused)
    StopMovie(0)
    State\movieState = #MovieState_Stopped
    State\previousMovieStatus = 0
    State\audioStartMS = 0
    State\audioPausedElapsedMS = 0
    SetProgressPosition(0)
    UpdatePlaybackStatus("Stopped")

    If State\movieHasVideo
      UpdateLayout()
    Else
      UpdateAudioTimeStatus(0)
    EndIf
  EndIf
EndProcedure

Procedure TogglePlayback()
  If State\movieLoaded = 0
    ProcedureReturn
  EndIf

  Select State\movieState
    Case #MovieState_Playing
      PausePlayback()

    Case #MovieState_Paused
      ResumeMovie(0)
      If State\movieHasVideo = 0
        State\audioStartMS = ElapsedMilliseconds() - State\audioPausedElapsedMS
      EndIf
      State\movieState = #MovieState_Playing
      ApplyAudioSettings()
      UpdatePlaybackStatus("Playing")

    Default
      If State\movieHasVideo
        EnsureVideoHostWindow()
        PlayMovie(0, WindowID(#Window_Video))
      Else
        PlayMovie(0, WindowID(#Window_Main))
        State\audioStartMS = ElapsedMilliseconds()
        State\audioPausedElapsedMS = 0
      EndIf

      UpdateLayout()
      KeepStatusBarOnTop()
      State\movieState = #MovieState_Playing
      ApplyAudioSettings()
      UpdatePlaybackStatus("Playing")
  EndSelect
EndProcedure

Procedure SaveSettings()
  Protected winX.i = State\winX
  Protected winY.i = State\winY

  If IsWindow(#Window_Main)
    winX = WindowX(#Window_Main)
    winY = WindowY(#Window_Main)
  EndIf

  If CreatePreferences(AppPath + "HandyMPlayer.ini")
    PreferenceGroup("Settings")
    WritePreferenceInteger("Volume", State\volume)
    WritePreferenceInteger("Balance", State\balance)
    WritePreferenceInteger("WinX", winX)
    WritePreferenceInteger("WinY", winY)
    WritePreferenceInteger("SidebarWidth", State\sidebarWidth)
    WritePreferenceString("LibraryRoot", LibraryRootPath)
    WritePreferenceString("LastPlaylist", LastPlaylistPath)
    WritePreferenceString("CurrentPlaylist", CurrentPlaylistName)
    ClosePreferences()
  EndIf
EndProcedure

Procedure LoadSettings()
  If OpenPreferences(AppPath + "HandyMPlayer.ini")
    PreferenceGroup("Settings")
    State\volume = ReadPreferenceInteger("Volume", 100)
    State\balance = ReadPreferenceInteger("Balance", 0)
    State\winX = ReadPreferenceInteger("WinX", -1)
    State\winY = ReadPreferenceInteger("WinY", -1)
    State\sidebarWidth = ReadPreferenceInteger("SidebarWidth", #SidebarWidth)
    LibraryRootPath = ReadPreferenceString("LibraryRoot", "")
    LastPlaylistPath = ReadPreferenceString("LastPlaylist", "")
    CurrentPlaylistName = ReadPreferenceString("CurrentPlaylist", "")
    ClosePreferences()
  Else
    State\volume = 100
    State\balance = 0
    State\winX = -1
    State\winY = -1
    State\sidebarWidth = #SidebarWidth
    LibraryRootPath = ""
    LastPlaylistPath = ""
    CurrentPlaylistName = ""
  EndIf
EndProcedure

Procedure CleanupResources()
  SaveSettings()
  ClearArtworkImage()
  If IsMovie(0) : FreeMovie(0) : EndIf
  If AboutIcon : DestroyIcon_(AboutIcon) : AboutIcon = 0 : EndIf
  If LoadIcon : DestroyIcon_(LoadIcon) : LoadIcon = 0 : EndIf
  If PauseIcon : DestroyIcon_(PauseIcon) : PauseIcon = 0 : EndIf
  If PlayIcon : DestroyIcon_(PlayIcon) : PlayIcon = 0 : EndIf
  If StopIcon : DestroyIcon_(StopIcon) : StopIcon = 0 : EndIf
  If hMutex
    ReleaseMutex_(hMutex)
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
EndProcedure

Procedure.s FormatTime(seconds.q)
  Protected mm.q = seconds / 60
  Protected ss.q = seconds % 60
  ProcedureReturn RSet(Str(mm), 2, "0") + ":" + RSet(Str(ss), 2, "0")
EndProcedure

Procedure.q MovieLengthMS(movie.i)
  Protected ms.q = 0

  ; Prefer GetMovieLength() (returns milliseconds) when present.
  CompilerIf Defined(GetMovieLength, #PB_Procedure)
    ms = GetMovieLength(movie)
  CompilerEndIf

  ProcedureReturn ms
EndProcedure

Procedure ResizeMainForVideo(videoW.i, videoH.i)
  Protected toolH.i = ToolBarHeight(0)
  Protected statusH.i = StatusBarHeight(0)
  Protected sidebarMinW.i = DesktopScaledX(State\sidebarWidth + #SidebarSplitterWidth + (#LayoutPadding * 3) + videoW)
  Protected sidebarMinH.i = DesktopScaledY(#SidebarMinHeight)

  ; Reserve room for toolbar + trackbar + status bar.
  Protected pbH.i = DesktopScaledY(#ProgressBarHeight + 6)
  Protected metaH.i = DesktopScaledY(#MetadataPanelHeight)

  Protected innerW.i = DesktopScaledX(videoW)
  Protected innerH.i = toolH + DesktopScaledY(#LayoutPadding) + pbH + DesktopScaledY(#LayoutPadding) + metaH + DesktopScaledY(#LayoutPadding) + videoH + statusH

  If innerW < DesktopScaledX(#WindowWidth) : innerW = DesktopScaledX(#WindowWidth) : EndIf
  If innerW < sidebarMinW : innerW = sidebarMinW : EndIf
  If innerH < DesktopScaledY(#WindowHeight + 25) : innerH = DesktopScaledY(#WindowHeight + 25) : EndIf
  If innerH < sidebarMinH : innerH = sidebarMinH : EndIf

  ; ResizeWindow uses frame coordinates, so convert inner->frame delta.
  Protected frameDeltaW.i = WindowWidth(#Window_Main, #PB_Window_FrameCoordinate) - WindowWidth(#Window_Main, #PB_Window_InnerCoordinate)
  Protected frameDeltaH.i = WindowHeight(#Window_Main, #PB_Window_FrameCoordinate) - WindowHeight(#Window_Main, #PB_Window_InnerCoordinate)

  ResizeWindow(#Window_Main, #PB_Ignore, #PB_Ignore, innerW + frameDeltaW, innerH + frameDeltaH)
EndProcedure

Procedure ResizeMainForAudio(hasArtwork.i)
  Protected toolH.i = ToolBarHeight(0)
  Protected statusH.i = StatusBarHeight(0)
  Protected pbH.i = DesktopScaledY(#ProgressBarHeight + 6)
  Protected metaH.i = DesktopScaledY(#MetadataPanelHeight)
  Protected artworkH.i = 0
  Protected innerW.i = DesktopScaledX(#WindowWidth + 50)
  Protected innerH.i
  Protected frameDeltaW.i
  Protected frameDeltaH.i
  Protected sidebarMinW.i = DesktopScaledX(State\sidebarWidth + #SidebarSplitterWidth + (#LayoutPadding * 3) + #WindowWidth)
  Protected sidebarMinH.i = DesktopScaledY(#SidebarMinHeight)

  If hasArtwork
    artworkH = DesktopScaledY(#DefaultArtworkSize + (#LayoutPadding * 2))
    innerW = DesktopScaledX(#DefaultArtworkSize + 40)
  EndIf

  innerH = toolH + DesktopScaledY(#LayoutPadding) + pbH + DesktopScaledY(#LayoutPadding) + metaH + DesktopScaledY(#LayoutPadding) + artworkH + statusH
  If innerH < DesktopScaledY(#WindowHeight + 25) : innerH = DesktopScaledY(#WindowHeight + 25) : EndIf
  If innerW < sidebarMinW : innerW = sidebarMinW : EndIf
  If innerH < sidebarMinH : innerH = sidebarMinH : EndIf

  frameDeltaW = WindowWidth(#Window_Main, #PB_Window_FrameCoordinate) - WindowWidth(#Window_Main, #PB_Window_InnerCoordinate)
  frameDeltaH = WindowHeight(#Window_Main, #PB_Window_FrameCoordinate) - WindowHeight(#Window_Main, #PB_Window_InnerCoordinate)
  ResizeWindow(#Window_Main, #PB_Ignore, #PB_Ignore, innerW + frameDeltaW, innerH + frameDeltaH)
EndProcedure

Procedure EnsureVideoHostWindow()
  If IsWindow(#Window_Video)
    ProcedureReturn
  EndIf

  ; Borderless child window for video rendering.
  Protected flags.i = #PB_Window_Invisible | #PB_Window_BorderLess

  If OpenWindow(#Window_Video, 0, 0, 10, 10, "", flags, WindowID(#Window_Main))
    Protected hVideo.i = WindowID(#Window_Video)
    Protected hMain.i = WindowID(#Window_Main)

    SetParent_(hVideo, hMain)

    Protected style.i = GetWindowLongPtr_(hVideo, #GWL_STYLE)
    style = style | #WS_CHILD | #WS_CLIPCHILDREN | #WS_CLIPSIBLINGS
    SetWindowLongPtr_(hVideo, #GWL_STYLE, style)

    ; Keep it behind UI siblings. (No ZORDER change needed here, but frame refresh helps.)
    SetWindowPos_(hVideo, 0, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOZORDER | #SWP_FRAMECHANGED)
  EndIf
EndProcedure

Procedure ProgressBarSeek()
  Protected pbMax.q, seekTarget.q
  If State\movieLoaded = 0 Or IsMovie(0) = 0
    ProcedureReturn
  EndIf

  ; Only seek when playing or paused.
  If State\movieState <> #MovieState_Playing And State\movieState <> #MovieState_Paused
    ProcedureReturn
  EndIf

  ; Only handle user-driven seek.
  If isUserSeeking = 0
    ProcedureReturn
  EndIf

  pbMax = GetGadgetAttribute(#Gadget_Progress, #PB_TrackBar_Maximum)
  If pbMax <= 0
    ProcedureReturn
  EndIf

  seekTarget = GetGadgetState(#Gadget_Progress)

  If State\movieHasVideo
    If State\movieLengthFrames > 0
      seekTarget = (State\movieLengthFrames * seekTarget) / pbMax
      MovieSeek(0, seekTarget)
    EndIf
  Else
    ; Audio-only: use a seekable unit.
    ; Some audio formats report MovieLength() = 0 (no "frames"), but GetMovieLength() can still provide ms.
    If State\audioTotalFrames > 0
      seekTarget = (State\audioTotalFrames * seekTarget) / pbMax
      MovieSeek(0, seekTarget)

      ; Keep our elapsed-time tracking roughly consistent (best-effort).
      If State\audioTotalMS > 0
        If State\audioTotalFrames = State\audioTotalMS
          State\audioPausedElapsedMS = seekTarget
        Else
          State\audioPausedElapsedMS = (State\audioTotalMS * seekTarget) / State\audioTotalFrames
        EndIf
        State\audioStartMS = ElapsedMilliseconds() - State\audioPausedElapsedMS
      EndIf
    Else
      ; Unknown length: can't seek reliably.
      ProcedureReturn
    EndIf
  EndIf
EndProcedure

Procedure ProgressBarClickToSeek()
  If IsGadget(#Gadget_Progress) = 0
    ProcedureReturn
  EndIf

  ; Map pointer X position to trackbar range and force a seek.
  Protected pt.WinPOINT
  Protected rc.WinRECT
  Protected barW.i
  Protected x.i
  Protected newPos.q

  If GetCursorPos_(@pt) = 0
    ProcedureReturn
  EndIf

  ScreenToClient_(GadgetID(#Gadget_Progress), @pt)

  Protected pbMax.q
  If GetClientRect_(GadgetID(#Gadget_Progress), @rc) = 0
    ProcedureReturn
  EndIf

  barW = rc\right - rc\left
  If barW <= 0
    ProcedureReturn
  EndIf

  pbMax = GetGadgetAttribute(#Gadget_Progress, #PB_TrackBar_Maximum)
  If pbMax <= 0
    pbMax = #ProgressScaleMax
  EndIf

  x = pt\x
  If x < 0 : x = 0 : EndIf
  If x > barW : x = barW : EndIf

  newPos = (pbMax * x) / barW

  isUserSeeking = 1
  SetGadgetState(#Gadget_Progress, newPos)
  ProgressBarSeek()
EndProcedure

Procedure KeepStatusBarOnTop()
  If IsStatusBar(0)
    Protected hStatus.i = StatusBarID(0)
    If hStatus
      SetWindowPos_(hStatus, #HWND_TOP, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOACTIVATE)
    EndIf
  EndIf
EndProcedure

Procedure KeepVideoBehindUI()
  If IsWindow(#Window_Video)
    Protected hVideo.i = WindowID(#Window_Video)
    If hVideo
      SetWindowPos_(hVideo, #HWND_BOTTOM, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOACTIVATE)
    EndIf
  EndIf
EndProcedure

Procedure UpdateLayout()
  Protected toolH.i = ToolBarHeight(0)
  Protected statusH.i = StatusBarHeight(0)

  Protected winW.i = WindowWidth(#Window_Main, #PB_Window_InnerCoordinate)
  Protected winH.i = WindowHeight(#Window_Main, #PB_Window_InnerCoordinate)
  Protected sidebarW.i = DesktopScaledX(State\sidebarWidth)
  Protected splitterW.i = DesktopScaledX(#SidebarSplitterWidth)
  Protected contentX.i = sidebarW + splitterW + DesktopScaledX(#LayoutPadding)
  Protected contentW.i = winW - contentX - DesktopScaledX(#LayoutPadding)
  Protected sidebarTop.i = toolH + DesktopScaledY(#LayoutPadding)
  Protected sidebarH.i = winH - toolH - statusH - DesktopScaledY(#LayoutPadding * 2)
  Protected playlistY.i
  Protected playlistH.i
  Protected queueY.i
  Protected queueBlockH.i = DesktopScaledY(142)

  Protected pbX.i = contentX + DesktopScaledX(#ProgressBarLeft)
  Protected pbY.i = toolH + DesktopScaledY(#LayoutPadding)
  Protected pbW.i = contentW - DesktopScaledX(#ProgressBarLeft + #ProgressBarRightMargin)
  Protected pbH.i = DesktopScaledY(#ProgressBarHeight + 6)
  Protected metaY.i
  If pbW < 10 : pbW = 10 : EndIf
  If contentW < 50 : contentW = 50 : EndIf

  playlistY = sidebarTop + DesktopScaledY(220)
  queueY = sidebarTop + sidebarH - queueBlockH.i
  playlistH = queueY - playlistY - DesktopScaledY(8)
  If playlistH < 100 : playlistH = 100 : EndIf

  If IsGadget(#Gadget_SidebarSplitter)
    ResizeGadget(#Gadget_SidebarSplitter, sidebarW, toolH, splitterW, winH - toolH - statusH)
  EndIf

  If IsGadget(#Gadget_LibraryTitle)
    ResizeGadget(#Gadget_LibraryTitle, DesktopScaledX(#LayoutPadding), sidebarTop, sidebarW - DesktopScaledX(#LayoutPadding * 2), DesktopScaledY(18))
  EndIf
  If IsGadget(#Gadget_LibrarySearch)
    ResizeGadget(#Gadget_LibrarySearch, DesktopScaledX(#LayoutPadding), sidebarTop + DesktopScaledY(20), sidebarW - DesktopScaledX(#LayoutPadding * 2), DesktopScaledY(24))
  EndIf
  If IsGadget(#Gadget_LibraryTree)
    ResizeGadget(#Gadget_LibraryTree, DesktopScaledX(#LayoutPadding), sidebarTop + DesktopScaledY(48), sidebarW - DesktopScaledX(#LayoutPadding * 2), DesktopScaledY(122))
  EndIf
  If IsGadget(#Gadget_LibraryPlay)
    ResizeGadget(#Gadget_LibraryPlay, DesktopScaledX(#LayoutPadding), sidebarTop + DesktopScaledY(176), (sidebarW - DesktopScaledX(#LayoutPadding * 3)) / 2, DesktopScaledY(#SidebarButtonHeight))
  EndIf
  If IsGadget(#Gadget_LibraryAdd)
    ResizeGadget(#Gadget_LibraryAdd, DesktopScaledX(#LayoutPadding) + ((sidebarW - DesktopScaledX(#LayoutPadding * 3)) / 2) + DesktopScaledX(#LayoutPadding), sidebarTop + DesktopScaledY(176), (sidebarW - DesktopScaledX(#LayoutPadding * 3)) / 2, DesktopScaledY(#SidebarButtonHeight))
  EndIf
  If IsGadget(#Gadget_PlaylistTitle)
    ResizeGadget(#Gadget_PlaylistTitle, DesktopScaledX(#LayoutPadding), playlistY, sidebarW - DesktopScaledX(#LayoutPadding * 2), DesktopScaledY(18))
  EndIf
  If IsGadget(#Gadget_PlaylistTabs)
    ResizeGadget(#Gadget_PlaylistTabs, DesktopScaledX(#LayoutPadding), playlistY + DesktopScaledY(20), sidebarW - DesktopScaledX(#LayoutPadding * 2), DesktopScaledY(28))
  EndIf
  If IsGadget(#Gadget_PlaylistNew)
    ResizeGadget(#Gadget_PlaylistNew, DesktopScaledX(#LayoutPadding), playlistY + DesktopScaledY(52), DesktopScaledX(30), DesktopScaledY(24))
  EndIf
  If IsGadget(#Gadget_PlaylistRename)
    ResizeGadget(#Gadget_PlaylistRename, DesktopScaledX(#LayoutPadding + 35), playlistY + DesktopScaledY(52), DesktopScaledX(30), DesktopScaledY(24))
  EndIf
  If IsGadget(#Gadget_PlaylistDelete)
    ResizeGadget(#Gadget_PlaylistDelete, DesktopScaledX(#LayoutPadding + 70), playlistY + DesktopScaledY(52), DesktopScaledX(30), DesktopScaledY(24))
  EndIf
  If IsGadget(#Gadget_Playlist)
    ResizeGadget(#Gadget_Playlist, DesktopScaledX(#LayoutPadding), playlistY + DesktopScaledY(82), sidebarW - DesktopScaledX(#LayoutPadding * 2), playlistH - DesktopScaledY(118))
  EndIf
  If IsGadget(#Gadget_PlaylistUp)
    ResizeGadget(#Gadget_PlaylistUp, DesktopScaledX(#LayoutPadding), playlistY + playlistH - DesktopScaledY(30), DesktopScaledX(65), DesktopScaledY(#SidebarButtonHeight))
  EndIf
  If IsGadget(#Gadget_PlaylistDown)
    ResizeGadget(#Gadget_PlaylistDown, DesktopScaledX(#LayoutPadding + 70), playlistY + playlistH - DesktopScaledY(30), DesktopScaledX(65), DesktopScaledY(#SidebarButtonHeight))
  EndIf
  If IsGadget(#Gadget_PlaylistRemove)
    ResizeGadget(#Gadget_PlaylistRemove, DesktopScaledX(#LayoutPadding + 140), playlistY + playlistH - DesktopScaledY(30), DesktopScaledX(75), DesktopScaledY(#SidebarButtonHeight))
  EndIf
  If IsGadget(#Gadget_PlaylistClear)
    ResizeGadget(#Gadget_PlaylistClear, DesktopScaledX(#LayoutPadding + 220), playlistY + playlistH - DesktopScaledY(30), DesktopScaledX(65), DesktopScaledY(#SidebarButtonHeight))
  EndIf
  If IsGadget(#Gadget_QueueTitle)
    ResizeGadget(#Gadget_QueueTitle, DesktopScaledX(#LayoutPadding), queueY, sidebarW - DesktopScaledX(#LayoutPadding * 2), DesktopScaledY(18))
  EndIf
  If IsGadget(#Gadget_QueueList)
    ResizeGadget(#Gadget_QueueList, DesktopScaledX(#LayoutPadding), queueY + DesktopScaledY(20), sidebarW - DesktopScaledX(90), DesktopScaledY(66))
  EndIf
  If IsGadget(#Gadget_QueueAdd)
    ResizeGadget(#Gadget_QueueAdd, sidebarW - DesktopScaledX(80), queueY + DesktopScaledY(20), DesktopScaledX(70), DesktopScaledY(24))
  EndIf
  If IsGadget(#Gadget_QueueClear)
    ResizeGadget(#Gadget_QueueClear, sidebarW - DesktopScaledX(80), queueY + DesktopScaledY(48), DesktopScaledX(70), DesktopScaledY(24))
  EndIf
  If IsGadget(#Gadget_QueueUp)
    ResizeGadget(#Gadget_QueueUp, DesktopScaledX(#LayoutPadding), queueY + DesktopScaledY(90), DesktopScaledX(50), DesktopScaledY(24))
  EndIf
  If IsGadget(#Gadget_QueueDown)
    ResizeGadget(#Gadget_QueueDown, DesktopScaledX(#LayoutPadding + 55), queueY + DesktopScaledY(90), DesktopScaledX(50), DesktopScaledY(24))
  EndIf
  If IsGadget(#Gadget_QueueRemove)
    ResizeGadget(#Gadget_QueueRemove, DesktopScaledX(#LayoutPadding + 110), queueY + DesktopScaledY(90), DesktopScaledX(75), DesktopScaledY(24))
  EndIf

  If IsGadget(#Gadget_Progress)
    ; Avoid resizing if dimensions didn't change to reduce flicker
    If GadgetWidth(#Gadget_Progress) <> pbW Or GadgetHeight(#Gadget_Progress) <> pbH
      ResizeGadget(#Gadget_Progress, pbX, pbY, pbW, pbH)
    EndIf
  EndIf

  metaY = pbY + pbH + DesktopScaledY(#LayoutPadding)
  If IsGadget(#Gadget_MetadataPrimary)
    ResizeGadget(#Gadget_MetadataPrimary, pbX, metaY, pbW, DesktopScaledY(18))
  EndIf
  If IsGadget(#Gadget_MetadataSecondary)
    ResizeGadget(#Gadget_MetadataSecondary, pbX, metaY + DesktopScaledY(18), pbW, DesktopScaledY(18))
  EndIf

  Protected videoTop.i = metaY + DesktopScaledY(#MetadataPanelHeight) + DesktopScaledY(#LayoutPadding)
  Protected videoH.i = winH - videoTop - statusH
  If videoH < 0 : videoH = 0 : EndIf

  If IsGadget(#Gadget_Artwork)
    If State\movieHasVideo = 0 And State\artworkImage And IsImage(State\artworkImage)
      Protected artW.i = ImageWidth(State\artworkImage)
      Protected artH.i = ImageHeight(State\artworkImage)
      Protected artX.i = contentX + ((contentW - artW) / 2)
      If artX < 0 : artX = 0 : EndIf
      HideGadget(#Gadget_Artwork, 0)
      ResizeGadget(#Gadget_Artwork, artX, videoTop, artW, artH)
      videoTop + artH + DesktopScaledY(#LayoutPadding)
    Else
      HideGadget(#Gadget_Artwork, 1)
      ResizeGadget(#Gadget_Artwork, 0, videoTop, 0, 0)
    EndIf
  EndIf

  videoH = winH - videoTop - statusH
  If videoH < 0 : videoH = 0 : EndIf

  EnsureVideoHostWindow()
  If IsWindow(#Window_Video)
    If State\movieHasVideo
      HideWindow(#Window_Video, 0)
      ResizeWindow(#Window_Video, contentX, videoTop, contentW, videoH)
      SetWindowPos_(WindowID(#Window_Video), 0, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOZORDER | #SWP_FRAMECHANGED)
    Else
      HideWindow(#Window_Video, 1)
      ResizeWindow(#Window_Video, contentX, videoTop, contentW, 0)
    EndIf
  EndIf

  ; Some renderers still overpaint siblings; force the UI above.
  KeepVideoBehindUI()
  KeepStatusBarOnTop()

  If IsWindow(#Window_Video)
    SetParent_(WindowID(#Window_Video), WindowID(#Window_Main))
  EndIf

  If State\movieHasVideo And IsMovie(0) And IsWindow(#Window_Video)
    ResizeMovie(0, 0, 0, WindowWidth(#Window_Video, #PB_Window_InnerCoordinate), WindowHeight(#Window_Video, #PB_Window_InnerCoordinate))
  EndIf
EndProcedure

Procedure LoadFile(path.s)
  Protected embedded.EmbeddedMediaInfo
  Protected folderArtwork.s

  If path = "" : ProcedureReturn : EndIf
  
  If IsMovie(0)
    FreeMovie(0)
  EndIf

  ResetPlaybackState()

  If LoadMovie(0, path)
    State\movieHasVideo = Bool(MovieHeight(0) > 0)

    State\targetW = MovieWidth(0) / 2
    State\targetH = MovieHeight(0) / 2

    If State\movieHasVideo = 0
      State\targetW = #WindowWidth + 50
      State\targetH = #WindowHeight + 25
    EndIf

    SetProgressPosition(0)
    State\moviePath = path
    State\fileName = GetFilePart(path)
    State\artist = ""
    State\title = ""
    State\metadataSource = ""
    State\lyricsSource = ""
    State\artworkSource = ""
    State\lyricsFile = ""

    State\movieLoaded = 1
    State\movieState = #MovieState_Ready
    State\previousMovieStatus = 0
    State\lastProgressUpdate = ElapsedMilliseconds()

    State\movieLengthFrames = MovieLength(0)
    State\movieFPS_x1000 = 0
    If State\movieHasVideo
      State\movieFPS_x1000 = MovieInfo(0, 0)
    EndIf

    State\audioTotalMS = 0
    State\audioTotalFrames = 0
    If State\movieHasVideo = 0
      ExtractEmbeddedMediaInfo(path, @embedded)
      If embedded\artist <> "" : State\artist = embedded\artist : EndIf
      If embedded\title <> "" : State\title = embedded\title : EndIf
      If State\artist <> "" Or State\title <> ""
        State\metadataSource = "embedded"
      ElseIf State\fileName <> ""
        State\metadataSource = "filename"
      EndIf
      If embedded\lyrics <> ""
        If EnsureDirectoryPath(AppPath + #LyricsFolder)
          State\lyricsFile = AppPath + #LyricsFolder + SanitizeFileComponent(GetTrackDisplayName()) + "-embedded.txt"
          If CreateFile(0, State\lyricsFile)
            WriteString(0, embedded\lyrics, #PB_UTF8)
            CloseFile(0)
            State\lyricsSource = "embedded"
          Else
            State\lyricsFile = ""
          EndIf
        EndIf
      EndIf
      folderArtwork = FindFolderArtwork(path)

      If embedded\artworkFile <> "" And LoadArtworkImage(embedded\artworkFile)
        State\artworkSource = "embedded"
        ResizeMainForAudio(#True)
      ElseIf folderArtwork <> "" And LoadArtworkImage(folderArtwork)
        State\artworkSource = "folder"
        ResizeMainForAudio(#True)
      Else
        ResizeMainForAudio(#False)
      EndIf
      State\audioTotalMS = MovieLengthMS(0)
      State\audioTotalFrames = State\movieLengthFrames
      If State\audioTotalFrames <= 0 And State\audioTotalMS > 0
        State\audioTotalFrames = State\audioTotalMS
      EndIf
      State\audioStartMS = 0
      State\audioPausedElapsedMS = 0
    EndIf

    If State\movieHasVideo
      ResizeMainForVideo(State\targetW, State\targetH)
      StatusBarText(0, 0, "Video '" + State\fileName + "' loaded.", #PB_StatusBar_Center)
      GadgetToolTip(#Gadget_Progress, "Video '" + State\fileName + "' loaded.")
    Else
      StatusBarText(0, 0, "Audio '" + GetTrackDisplayName() + "' loaded.", #PB_StatusBar_Center)
      GadgetToolTip(#Gadget_Progress, "Audio '" + GetTrackDisplayName() + "' loaded.")
    EndIf

    UpdateMetadataPanel()
    HighlightNowPlaying()
    UpdateLayout()
  Else
    UpdateLayout()
    UpdatePlaybackStatus("Can't load the file '" + GetFilePart(path) + "'")
  EndIf
EndProcedure

Procedure ExitApplication(confirm.i = #True)
  If confirm = #False Or MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info) = #PB_MessageRequester_Yes
    CleanupResources()
    End
  EndIf
EndProcedure

Procedure Main()
  Protected now.i, st.q, curSec.q, totalSec.q, elapsedMS.q, windowMS.q, pos.i, mainStyle.i
  Protected windowFlags.i
  Protected windowX.i
  Protected windowY.i
  Protected droppedFile.s
  Protected folderPath.s

  LoadSettings()
  If State\sidebarWidth <= 0
    State\sidebarWidth = #SidebarWidth
  EndIf
  ResetPlaybackState()

  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
  If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
    CloseHandle_(hMutex)
    hMutex = 0
    ProcedureReturn
  EndIf

  iconlib = AppPath + "files\" + #APP_NAME + ".icl"
  AboutIcon = ExtractIcon_(0, iconlib, 0)
  LoadIcon  = ExtractIcon_(0, iconlib, 1)
  PauseIcon = ExtractIcon_(0, iconlib, 2)
  PlayIcon  = ExtractIcon_(0, iconlib, 3)
  StopIcon  = ExtractIcon_(0, iconlib, 4)

  If InitMovie() = 0
    MessageRequester("Error", "Can't initialize video playback!", #PB_MessageRequester_Error)
    CleanupResources()
    ProcedureReturn
  EndIf

  windowFlags = #PB_Window_Invisible | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget
  windowX = State\winX
  windowY = State\winY

  If windowX = -1 Or windowY = -1
    windowX = 0
    windowY = 0
    windowFlags = windowFlags | #PB_Window_ScreenCentered
  EndIf

  If OpenWindow(#Window_Main, windowX, windowY, #WindowWidth + 50, #WindowHeight + 25, #APP_NAME + " - " + version, windowFlags)

  EnableWindowDrop(#Window_Main, #PB_Drop_Files, #PB_Drag_Copy)

  ; Add Keyboard Shortcuts
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_Space, #Command_PlayPause)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_M, #Command_VolumeMute)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_Escape, #Command_Exit)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_L, #Command_Load)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_F, #Command_LoadFolder)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_S, #Command_Stop)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_Right, #Command_PlayNext)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_Left, #Command_PlayPrevious)

  
  ; Improve child clipping (helps keep status bar visible).
  mainStyle.i = GetWindowLongPtr_(WindowID(#Window_Main), #GWL_STYLE)
  mainStyle = mainStyle | #WS_CLIPCHILDREN | #WS_CLIPSIBLINGS
  SetWindowLongPtr_(WindowID(#Window_Main), #GWL_STYLE, mainStyle)

  ; create the program menu
  If CreateMenu(0, WindowID(#Window_Main))
      MenuTitle("File")
      MenuItem(#Command_Load, "Load")
      MenuItem(#Command_LoadFolder, "Load Folder")
      MenuItem(#Command_LoadPlaylist, "Load Playlist")
      MenuItem(#Command_SavePlaylist, "Save Playlist")
      MenuBar()
      MenuItem(#Command_Exit, "Exit")
      MenuTitle("Play")
      MenuItem(#Command_PlayPause, "Play")
      MenuItem(#Command_Pause, "Pause")
      MenuItem(#Command_PlayPrevious, "Previous")
      MenuItem(#Command_PlayNext, "Next")
      MenuBar()
      MenuItem(#Command_Stop, "Stop")
      MenuBar()
      OpenSubMenu("Video")
        MenuItem(#Command_SizeDefault, "Default")
        MenuItem(#Command_SizeX1, "Size x1")
        MenuItem(#Command_SizeX2, "Size x2")
      CloseSubMenu()
      OpenSubMenu("Volume")
        MenuItem(#Command_VolumeFull, "Full (100%)")
        MenuItem(#Command_VolumeHalf, "Half (50%)")
        MenuItem(#Command_VolumeMute, "Mute (0%)")
      CloseSubMenu()
      OpenSubMenu("Balance")
        MenuItem(#Command_BalanceCenter, "Both (L+R)")
        MenuItem(#Command_BalanceLeft, "Left (L)")
        MenuItem(#Command_BalanceRight, "Right (R)")
      CloseSubMenu()
      MenuTitle("Help")
      MenuItem(#Command_Help, "Help")
      MenuItem(#Command_About, "About")
    EndIf
    
  ; create the toolbar
  If CreateToolBar(0, WindowID(#Window_Main))
    ToolBarImageButton(#Command_Load, LoadIcon)
    ToolBarSeparator()
    ToolBarImageButton(#Command_PlayPause, PlayIcon)
    ToolBarSeparator()
    ToolBarImageButton(#Command_Pause, PauseIcon)
    ToolBarImageButton(#Command_Stop, StopIcon)
    ToolBarSeparator()
    ToolBarImageButton(#Command_About, AboutIcon)
  EndIf
  
  If CreateStatusBar(0, WindowID(#Window_Main))
    AddStatusBarField(8192) ; Maximum value of 8192 pixels, to have a field which take all the window width !
    StatusBarText(0, 0, "-=[Welcome to " + #APP_NAME + "!]=-", #PB_StatusBar_Center)
  EndIf
  
  HideWindow(#Window_Main, 0) ; Show the window once all toolbar/menus has been created...

  ; Pre-create gadgets once (recreating them causes flicker)
  TextGadget(#Gadget_LibraryTitle, 10, 30, 200, 18, "Library")
  StringGadget(#Gadget_LibrarySearch, 10, 50, 200, 24, "")
  TreeGadget(#Gadget_LibraryTree, 10, 78, 200, 122)
  ButtonGadget(#Gadget_LibraryPlay, 10, 206, 95, #SidebarButtonHeight, "Play")
  ButtonGadget(#Gadget_LibraryAdd, 115, 206, 95, #SidebarButtonHeight, "Add")
  CanvasGadget(#Gadget_SidebarSplitter, 300, 24, #SidebarSplitterWidth, 300)
  TextGadget(#Gadget_PlaylistTitle, 10, 240, 200, 18, "Playlist")
  ComboBoxGadget(#Gadget_PlaylistTabs, 10, 260, 200, 28)
  ButtonGadget(#Gadget_PlaylistNew, 10, 292, 30, 24, "+")
  ButtonGadget(#Gadget_PlaylistRename, 45, 292, 30, 24, "R")
  ButtonGadget(#Gadget_PlaylistDelete, 80, 292, 30, 24, "-")
  ListViewGadget(#Gadget_Playlist, 10, 322, 200, 78)
  ButtonGadget(#Gadget_PlaylistUp, 10, 404, 65, #SidebarButtonHeight, "Up")
  ButtonGadget(#Gadget_PlaylistDown, 80, 404, 65, #SidebarButtonHeight, "Down")
  ButtonGadget(#Gadget_PlaylistRemove, 150, 404, 75, #SidebarButtonHeight, "Remove")
  ButtonGadget(#Gadget_PlaylistClear, 230, 404, 65, #SidebarButtonHeight, "Clear")
  TextGadget(#Gadget_QueueTitle, 10, 440, 200, 18, "Queue")
  ListViewGadget(#Gadget_QueueList, 10, 460, 160, 70)
  ButtonGadget(#Gadget_QueueAdd, 175, 460, 70, 24, "Enqueue")
  ButtonGadget(#Gadget_QueueClear, 175, 490, 70, 24, "Clear")
  ButtonGadget(#Gadget_QueueUp, 10, 534, 50, 24, "Up")
  ButtonGadget(#Gadget_QueueDown, 65, 534, 50, 24, "Down")
  ButtonGadget(#Gadget_QueueRemove, 120, 534, 70, 24, "Remove")
  TrackBarGadget(#Gadget_Progress, 10, 30, 395, #ProgressBarHeight + 6, 0, #ProgressScaleMax)
  TextGadget(#Gadget_MetadataPrimary, 10, 52, 395, 18, "No media loaded")
  TextGadget(#Gadget_MetadataSecondary, 10, 70, 395, 18, "Metadata: none   Artwork: none   Lyrics: none")
  ImageGadget(#Gadget_Artwork, 0, 0, #DefaultArtworkSize, #DefaultArtworkSize, 0, #PB_Image_Border)
  HideGadget(#Gadget_Artwork, 1)
  SetProgressPosition(0)
  isUserSeeking = 1
  UpdateMetadataPanel()
  LoadStoredPlaylists()

  If CreatePopupImageMenu(1)
    MenuItem(#Command_ContextPlay, "Play")
    MenuItem(#Command_ContextAdd, "Add To Playlist")
    MenuItem(#Command_ContextReveal, "Reveal In Explorer")
  EndIf

  ; Dragging thumb triggers seek (PB default event)
  BindGadgetEvent(#Gadget_Progress, @ProgressBarSeek())
  ; Clicking anywhere on the bar jumps there then seeks
  BindGadgetEvent(#Gadget_Progress, @ProgressBarClickToSeek(), #PB_EventType_LeftClick)

  ; Create a dedicated child window for video rendering.
  EnsureVideoHostWindow()

  ResizeMainForAudio(#False)
  UpdateLayout()

  If LibraryRootPath <> "" And FileSize(LibraryRootPath) = -2
    BuildLibraryTree(LibraryRootPath)
  EndIf

  If LastPlaylistPath <> "" And FileSize(LastPlaylistPath) >= 0
    LoadPlaylistFromPath(LastPlaylistPath)
  ElseIf CurrentPlaylistName <> ""
    LoadNamedPlaylist(CurrentPlaylistName)
  EndIf
  
  Repeat
    ; Use a small wait to avoid CPU spinning and reduce flicker.
    Select WaitWindowEvent(15)

      Case #PB_Event_Menu
        If EventWindow() = #Window_Main
          Select EventMenu()
            
            Case #Command_Load ; Load
               LoadPlaylistFromRequester()

           Case #Command_LoadFolder
              folderPath = PathRequester("Load music folder", "")
              If folderPath <> ""
                BuildLibraryTree(folderPath)
              EndIf

           Case #Command_LoadPlaylist
             LoadPlaylistFromM3U()

           Case #Command_SavePlaylist
             SavePlaylistToFile()
        
          Case #Command_Exit ; Exit
            ExitApplication()

          ; ---------------- Movie controls -------------------
            
           Case #Command_PlayPause ; Play/Pause Toggle (Space/Button)
             TogglePlayback()
            
           Case #Command_Stop ; Stop
              StopPlayback()

           Case #Command_ContextPlay
              PlaySelectedLibraryItem()

           Case #Command_ContextAdd
              AddSelectedLibraryItemToPlaylist()

           Case #Command_ContextReveal
              RevealSelectedLibraryItem()

           Case #Command_PlaylistRemove
              RemoveSelectedPlaylistItem()

           Case #Command_PlaylistClear
              ClearPlaylistItems()

           Case #Command_PlaylistMoveUp
              MovePlaylistItem(-1)

           Case #Command_PlaylistMoveDown
              MovePlaylistItem(1)

            Case #Command_PlayPrevious
               PlayNextQueuedOrPlaylist(-1)

            Case #Command_PlayNext
               PlayNextQueuedOrPlaylist(1)
            
           Case #Command_Pause ; Pause
             PausePlayback()
            
          ; ---------------- Volume -------------------
            
           Case #Command_VolumeFull ; Full 100%
              State\volume = 100
              ApplyAudioSettings()

           Case #Command_VolumeHalf ; Half 50%
              State\volume = 50
              ApplyAudioSettings()

            Case #Command_VolumeMute ; Mute 0%
              If State\volume > 0
                State\volume = 0
              Else
                State\volume = 100
              EndIf
              ApplyAudioSettings()

            
           ; ---------------- Balance -------------------

           Case #Command_BalanceCenter ; Both (L+R)
              State\balance = 0
              ApplyAudioSettings()

           Case #Command_BalanceLeft ; Left (L)
              State\balance = -100
              ApplyAudioSettings()

           Case #Command_BalanceRight ; Right (R)
              State\balance = 100
              ApplyAudioSettings()


           ; ---------------------------------------------
            
            Case #Command_Help ; Help
               ShowHelpWindow()
            
          ; ------------------ Size ---------------------
 
           Case #Command_SizeDefault ; Default (50%)
             If State\movieLoaded And State\movieHasVideo
                ResizeMainForVideo(State\targetW, State\targetH)
                UpdateLayout()
             EndIf

           Case #Command_SizeX1 ; Size x1 (100%)
             If State\movieLoaded And State\movieHasVideo
                ResizeMainForVideo(MovieWidth(0), MovieHeight(0))
                UpdateLayout()
             EndIf

           Case #Command_SizeX2 ; Size x2 (200%)
             If State\movieLoaded And State\movieHasVideo
                ResizeMainForVideo(MovieWidth(0) * 2, MovieHeight(0) * 2)
                UpdateLayout()
             EndIf
         
          ; ---------------- Misc -------------------
            
            Case #Command_About ; About
             MessageRequester("About", #APP_NAME + " - " + version + #CRLF$ +
                                       "A compact media player for playing audio/video files." + #CRLF$ +
                                       "-----------------------------------------------------" + #CRLF$ +
                                       "Contact: " + #EMAIL_NAME + #CRLF$ +
                                       "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)

          EndSelect
        EndIf

      Case #PB_Event_WindowDrop
        If EventWindow() = #Window_Main
          droppedFile = EventDropFiles()
          If State\movieLoaded And State\movieHasVideo = 0
            If AttachArtworkFile(droppedFile)
              StatusBarText(0, 0, "Attached artwork '" + GetFilePart(droppedFile) + "'.", #PB_StatusBar_Center)
            ElseIf AttachLyricsFile(droppedFile)
              StatusBarText(0, 0, "Attached lyrics '" + GetFilePart(droppedFile) + "'.", #PB_StatusBar_Center)
              ShowLyricsWindow()
            Else
              LoadFile(droppedFile)
            EndIf
          Else
            LoadFile(droppedFile)
          EndIf
        EndIf
      
      Case #PB_Event_CloseWindow
        If EventWindow() = #Window_Main
          ExitApplication()
        ElseIf EventWindow() = #Window_Lyrics
          HideWindow(#Window_Lyrics, 1)
        ElseIf EventWindow() = #Window_ArtworkPreview
          HideWindow(#Window_ArtworkPreview, 1)
        ElseIf EventWindow() = #Window_Help
          HideWindow(#Window_Help, 1)
        EndIf
        
      Case #PB_Event_SizeWindow
        If EventWindow() = #Window_Main
          UpdateLayout()
          KeepStatusBarOnTop()
        ElseIf EventWindow() = #Window_Lyrics And IsGadget(#Gadget_LyricsEditor)
          ResizeGadget(#Gadget_LyricsEditor, 0, 0, WindowWidth(#Window_Lyrics, #PB_Window_InnerCoordinate), WindowHeight(#Window_Lyrics, #PB_Window_InnerCoordinate))
        ElseIf EventWindow() = #Window_ArtworkPreview And IsGadget(#Gadget_ArtworkScroll)
          ResizeGadget(#Gadget_ArtworkScroll, 0, 0, WindowWidth(#Window_ArtworkPreview, #PB_Window_InnerCoordinate), WindowHeight(#Window_ArtworkPreview, #PB_Window_InnerCoordinate))
          UpdateArtworkPreview()
        ElseIf EventWindow() = #Window_Help And IsGadget(#Gadget_HelpEditor)
          ResizeGadget(#Gadget_HelpEditor, 0, 0, WindowWidth(#Window_Help, #PB_Window_InnerCoordinate), WindowHeight(#Window_Help, #PB_Window_InnerCoordinate))
        EndIf

      Case #PB_Event_Gadget
        If EventGadget() = #Gadget_Artwork And EventType() = #PB_EventType_LeftClick
          ShowArtworkPreview()
        ElseIf EventGadget() = #Gadget_LibraryPlay
          PlaySelectedLibraryItem()
        ElseIf EventGadget() = #Gadget_LibraryAdd
          AddSelectedLibraryItemToPlaylist()
        ElseIf EventGadget() = #Gadget_PlaylistUp
          MovePlaylistItem(-1)
        ElseIf EventGadget() = #Gadget_PlaylistDown
          MovePlaylistItem(1)
        ElseIf EventGadget() = #Gadget_PlaylistRemove
          RemoveSelectedPlaylistItem()
        ElseIf EventGadget() = #Gadget_PlaylistClear
          ClearPlaylistItems()
        ElseIf EventGadget() = #Gadget_PlaylistNew
          CreateNewPlaylist()
        ElseIf EventGadget() = #Gadget_PlaylistRename
          RenameCurrentPlaylist()
        ElseIf EventGadget() = #Gadget_PlaylistDelete
          DeleteCurrentPlaylist()
        ElseIf EventGadget() = #Gadget_PlaylistTabs And EventType() = #PB_EventType_Change
          If GetGadgetState(#Gadget_PlaylistTabs) >= 0
            CurrentPlaylistName = GetGadgetItemText(#Gadget_PlaylistTabs, GetGadgetState(#Gadget_PlaylistTabs))
            LoadNamedPlaylist(CurrentPlaylistName)
          EndIf
        ElseIf EventGadget() = #Gadget_QueueAdd
          AddSelectedLibraryItemToQueue()
        ElseIf EventGadget() = #Gadget_QueueClear
          ClearGadgetItems(#Gadget_QueueList)
          ClearList(QueueTracks())
          SaveQueueStore()
        ElseIf EventGadget() = #Gadget_QueueUp
          MoveQueueItem(-1)
        ElseIf EventGadget() = #Gadget_QueueDown
          MoveQueueItem(1)
        ElseIf EventGadget() = #Gadget_QueueRemove
          RemoveSelectedQueueItem()
        ElseIf EventGadget() = #Gadget_SidebarSplitter And EventType() = #PB_EventType_LeftButtonDown
          State\draggingSidebar = #True
        ElseIf EventGadget() = #Gadget_LibrarySearch And EventType() = #PB_EventType_Change
          If CurrentPlaylistName <> ""
            PlaylistSearch(CurrentPlaylistName) = GetGadgetText(#Gadget_LibrarySearch)
          EndIf
          If LibraryRootPath <> ""
            BuildLibraryTreeFiltered(LibraryRootPath, GetGadgetText(#Gadget_LibrarySearch))
          EndIf
        ElseIf EventGadget() = #Gadget_LibraryTree And EventType() = #PB_EventType_LeftDoubleClick
          PlaySelectedLibraryItem()
        ElseIf EventGadget() = #Gadget_LibraryTree And EventType() = #PB_EventType_RightClick
          DisplayPopupMenu(1, WindowID(#Window_Main))
        ElseIf EventGadget() = #Gadget_Playlist And EventType() = #PB_EventType_LeftDoubleClick
          If GetGadgetState(#Gadget_Playlist) >= 0
            PlayPlaylistIndex(GetGadgetState(#Gadget_Playlist))
          EndIf
        EndIf
        
      Case 0
          If State\draggingSidebar And GetAsyncKeyState_(#VK_LBUTTON) >= 0
            State\draggingSidebar = #False
          ElseIf State\draggingSidebar
            Protected cursor.WinPOINT
            If GetCursorPos_(@cursor)
              ScreenToClient_(WindowID(#Window_Main), @cursor)
              State\sidebarWidth = cursor\x
              If State\sidebarWidth < #SidebarMinWidth : State\sidebarWidth = #SidebarMinWidth : EndIf
              If State\sidebarWidth > #SidebarMaxWidth : State\sidebarWidth = #SidebarMaxWidth : EndIf
              UpdateLayout()
            EndIf
          EndIf

          If EventWindow() = #Window_Main And State\movieLoaded
            now = ElapsedMilliseconds()
            st = MovieStatus(0) ; -1 paused, 0 stopped, >0 current frame

            ApplyAudioSettings()

            If State\movieState = #MovieState_Playing And now - State\lastProgressUpdate >= 250
              If State\movieHasVideo
                If st > 0
                  If State\movieLengthFrames > 0 And st > State\movieLengthFrames
                    st = State\movieLengthFrames
                  EndIf
                  If State\movieLengthFrames > 0
                    SetProgressPosition((st * #ProgressScaleMax) / State\movieLengthFrames)
                  EndIf

                  ; Optional: show human time if FPS is known
                  If State\movieFPS_x1000 > 0
                    curSec = (st * 1000) / State\movieFPS_x1000
                    totalSec = 0
                    If State\movieLengthFrames > 0
                      totalSec = (State\movieLengthFrames * 1000) / State\movieFPS_x1000
                    EndIf
                    StatusBarText(0, 0, State\fileName + "  " + FormatTime(curSec) + "/" + FormatTime(totalSec), #PB_StatusBar_Center)
                  EndIf
                EndIf
              Else
                  ; Audio-only progress: prefer MovieStatus + a seekable unit.
                  ; When MovieLength() is 0, we fall back to milliseconds.
                  If State\audioTotalFrames > 0
                    st = MovieStatus(0)
                    If st < 0 : st = 0 : EndIf
                    If st > State\audioTotalFrames : st = State\audioTotalFrames : EndIf

                    SetProgressPosition((st * #ProgressScaleMax) / State\audioTotalFrames)

                    If State\audioTotalMS > 0
                      ; If audioTotalFrames was forced to ms, st is already ms.
                      If State\audioTotalFrames = State\audioTotalMS
                        elapsedMS = st
                      Else
                        elapsedMS = (State\audioTotalMS * st) / State\audioTotalFrames
                      EndIf
                      UpdateAudioTimeStatus(elapsedMS)
                    Else
                      UpdateAudioTimeStatus(0)
                    EndIf
                  Else
                    ; If even MovieLength() isn't available, fall back to a moving indicator.
                    If State\audioStartMS > 0
                      elapsedMS = now - State\audioStartMS
                      windowMS = 600000
                      pos = (elapsedMS % windowMS) * #ProgressScaleMax / windowMS
                      SetProgressPosition(pos)
                      UpdateAudioTimeStatus(elapsedMS)
                    EndIf
                  EndIf

              EndIf
              State\lastProgressUpdate = now
            EndIf

            If st <> State\previousMovieStatus
              Select st
                Case -1
                  UpdatePlaybackStatus("Paused")

                Case 0
                  UpdatePlaybackStatus("Stopped")
                  If State\movieState = #MovieState_Playing
                    State\movieState = #MovieState_Stopped
                    If ListSize(QueueTracks()) > 0 Or ListSize(Playlist()) > 1
                      PlayNextQueuedOrPlaylist(1)
                    EndIf
                  EndIf

                Default
                  If State\movieLengthFrames > 0
                    If st > State\movieLengthFrames
                      st = State\movieLengthFrames
                    EndIf
                    SetProgressPosition((st * #ProgressScaleMax) / State\movieLengthFrames)
                  EndIf
              EndSelect

              State\previousMovieStatus = st
            EndIf
          EndIf

     EndSelect
  ForEver
  Else
    CleanupResources()
  EndIf
EndProcedure

Main()
End

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 16
; Folding = ------------------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyMPlayer.ico
; Executable = ..\HandyMPlayer.exe
; Debugger = IDE
; IncludeVersionInfo
; VersionField0 = 1,0,3,0
; VersionField1 = 1,0,3,0
; VersionField2 = ZoneSoft
; VersionField3 = HandyMPlayer
; VersionField4 = 1.0.3.0
; VersionField5 = 1.0.3.0
; VersionField6 = A Handy Compact Media Player
; VersionField7 = HandyMPlayer
; VersionField8 = HandyMPlayer.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP
