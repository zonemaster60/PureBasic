Global isUserSeeking.i = 0

; Global variables moved to State structure or handled by Include
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
  album.s
  year.s
  genre.s
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
  continuousPlay.i
  shufflePlay.i
  repeatPlay.i
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
Declare CloseCurrentMedia()
Declare StopPlayback()
Declare TogglePlayback()
Declare StartLoadedPlayback()
Declare ApplyAudioSettings()
Declare UpdatePlaybackStatus(prefix.s)
Declare SetProgressPosition(position.q)
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
Declare.s FindArtworkFileForTrack(*metadata.TrackMetadata)
Declare.i DownloadLyricsText(*metadata.TrackMetadata, *lyrics.String)
Declare.s FindLyricsFileForTrack(*metadata.TrackMetadata)
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
Declare PlayPlaylistIndexAndStart(index.i)
Declare PlayNextTrack(direction.i)
Declare.i GetSelectedPlaylistIndex()
Declare.s GetPlaylistPathAtIndex(index.i)
Declare PlaySelectedPlaylistItem()
Declare ShowArtworkPreview()
Declare ShowVideoWindow()
Declare UpdateArtworkPreview()
Declare ToggleArtworkPreviewWindow()
Declare ToggleLyricsWindow()
Declare ToggleHelpWindow()
Declare TogglePlaylistWindow()
Declare ToggleVideoWindow()
Declare.s QuoteArg(value.s)
Declare.i IsMediaFile(path.s)
Declare BuildLibraryTree(rootPath.s)
Declare RefreshPlaylistGadget()
Declare AddToPlaylist(path.s)
Declare AddFolderToPlaylist(folderPath.s)
Declare.i FindPlaylistIndex(path.s)
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
Declare.i GetNextPlaylistIndex(direction.i)
Declare ShowPlaylistWindow()
Declare UpdatePlaylistWindowLayout()
Declare UpdateSeekPositionFromGadget(gadget.i)
Declare ProgressBarSeekForGadget()
Declare ProgressBarClickToSeekForGadget()
Declare UpdateNowPlayingLabel()

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 3
; EnableXP
; DPIAware
