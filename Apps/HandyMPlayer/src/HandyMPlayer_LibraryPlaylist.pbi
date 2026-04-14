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
  Protected sanitizedCurrent.s

  ClearList(PlaylistNames())
  EnsureDirectoryPath(AppPath + #PlaylistStoreFolder)

  dir = ExamineDirectory(#PB_Any, AppPath + #PlaylistStoreFolder, "*.m3u")
  If dir
    While NextDirectoryEntry(dir)
      entry = DirectoryEntryName(dir)
      If LCase(entry) = LCase(GetFilePart(#QueueStoreFile))
        Continue
      EndIf
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
  Else
    If CurrentPlaylistName <> ""
      sanitizedCurrent = SanitizeFileComponent(CurrentPlaylistName)
      ForEach PlaylistNames()
        If SanitizeFileComponent(PlaylistNames()) = sanitizedCurrent
          CurrentPlaylistName = PlaylistNames()
          Break
        EndIf
      Next
    EndIf

    If CurrentPlaylistName = ""
      FirstElement(PlaylistNames())
      CurrentPlaylistName = PlaylistNames()
    EndIf
  EndIf

  RefreshPlaylistSelector()
EndProcedure

Procedure CreateNewPlaylist()
  Protected name.s = InputRequester("New Playlist", "Playlist name:", "New Playlist")

  name = Trim(name)
  If name = ""
    ProcedureReturn
  EndIf

  ForEach PlaylistNames()
    If LCase(PlaylistNames()) = LCase(name) Or SanitizeFileComponent(PlaylistNames()) = SanitizeFileComponent(name)
      MessageRequester("Playlist", "A playlist with that name already exists.", #PB_MessageRequester_Warning)
      ProcedureReturn
    EndIf
  Next

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

  ForEach PlaylistNames()
    If LCase(PlaylistNames()) = LCase(name) Or SanitizeFileComponent(PlaylistNames()) = SanitizeFileComponent(name)
      If PlaylistNames() <> CurrentPlaylistName
        MessageRequester("Playlist", "A playlist with that name already exists.", #PB_MessageRequester_Warning)
        ProcedureReturn
      EndIf
    EndIf
  Next

  oldPath = AppPath + #PlaylistStoreFolder + SanitizeFileComponent(CurrentPlaylistName) + ".m3u"
  newPath = AppPath + #PlaylistStoreFolder + SanitizeFileComponent(name) + ".m3u"
  If RenameFile(oldPath, newPath) = 0
    MessageRequester("Playlist", "Could not rename the playlist file.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
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
    Next
  EndIf

  UpdateNowPlayingLabel()
EndProcedure

Procedure UpdateNowPlayingLabel()
  Protected labelText.s = "Now Playing: "

  If State\movieLoaded And GetTrackDisplayName() <> ""
    labelText + GetTrackDisplayName()
  Else
    labelText + "nothing loaded"
  EndIf

  If IsGadget(#Gadget_PlaylistNowPlaying)
    SetGadgetText(#Gadget_PlaylistNowPlaying, labelText)
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
  ProcedureReturn GetSelectedLibraryFile()
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
    TogglePlayback()
  ElseIf ListSize(Playlist()) > 0
    PlayNextTrack(direction)
  EndIf
EndProcedure

Procedure.i GetNextPlaylistIndex(direction.i)
  Protected listSize.i = ListSize(Playlist())
  Protected nextIndex.i

  If listSize = 0
    ProcedureReturn -1
  EndIf

  If State\repeatPlay And State\playlistIndex >= 0
    ProcedureReturn State\playlistIndex
  EndIf

  If State\shufflePlay And listSize > 1
    Repeat
      nextIndex = Random(listSize - 1)
    Until nextIndex <> State\playlistIndex
    ProcedureReturn nextIndex
  EndIf

  If State\playlistIndex < 0
    ProcedureReturn 0
  EndIf

  nextIndex = State\playlistIndex + direction
  If nextIndex >= listSize
    If State\continuousPlay
      ProcedureReturn 0
    EndIf
    ProcedureReturn -1
  EndIf

  If nextIndex < 0
    If State\continuousPlay
      ProcedureReturn listSize - 1
    EndIf
    ProcedureReturn -1
  EndIf

  ProcedureReturn nextIndex
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
  ElseIf selected < State\playlistIndex And State\playlistIndex > 0
    State\playlistIndex - 1
  ElseIf selected = State\playlistIndex
    State\playlistIndex = -1
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
  If State\movieLoaded And State\movieState <> #MovieState_Playing
    TogglePlayback()
  EndIf
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
    SaveCurrentPlaylistStore()
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
  Protected path.s

  If index < 0 Or index >= ListSize(Playlist())
    ProcedureReturn
  EndIf

  path = GetPlaylistPathAtIndex(index)
  If path = ""
    ProcedureReturn
  EndIf

  State\playlistIndex = index
  RefreshPlaylistGadget()
  LoadFile(path)
  HighlightNowPlaying()
EndProcedure

Procedure.i GetSelectedPlaylistIndex()
  Protected selected.i = GetGadgetState(#Gadget_Playlist)

  If selected >= 0 And selected < ListSize(Playlist())
    ProcedureReturn selected
  EndIf

  ProcedureReturn -1
EndProcedure

Procedure.s GetPlaylistPathAtIndex(index.i)
  Protected current.i = 0

  If index < 0 Or index >= ListSize(Playlist())
    ProcedureReturn ""
  EndIf

  ForEach Playlist()
    If current = index
      ProcedureReturn Playlist()
    EndIf
    current + 1
  Next

  ProcedureReturn ""
EndProcedure

Procedure PlaySelectedPlaylistItem()
  Protected selected.i = GetSelectedPlaylistIndex()
  Protected path.s

  If selected < 0
    ProcedureReturn
  EndIf

  path = GetPlaylistPathAtIndex(selected)

  If path = ""
    ProcedureReturn
  EndIf

  State\playlistIndex = selected
  RefreshPlaylistGadget()
  If IsGadget(#Gadget_LibraryTree)
    SetGadgetState(#Gadget_LibraryTree, -1)
  EndIf
  LoadFile(path)
  StartLoadedPlayback()
EndProcedure
