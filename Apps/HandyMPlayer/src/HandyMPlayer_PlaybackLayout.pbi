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

Procedure StartLoadedPlayback()
  If State\movieLoaded = 0
    ProcedureReturn
  EndIf

  If State\movieHasVideo
    ShowVideoWindow()
    PlayMovie(0, WindowID(#Window_Video))
    If IsWindow(#Window_Video)
      ResizeMovie(0, 0, 0, WindowWidth(#Window_Video, #PB_Window_InnerCoordinate), WindowHeight(#Window_Video, #PB_Window_InnerCoordinate))
    EndIf
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
EndProcedure

Procedure PlayPlaylistIndexAndStart(index.i)
  PlayPlaylistIndex(index)
  If State\movieLoaded And State\movieState <> #MovieState_Playing
    StartLoadedPlayback()
  EndIf
EndProcedure

Procedure PlayNextTrack(direction.i)
  Protected nextIndex.i

  If ListSize(Playlist()) = 0
    ProcedureReturn
  EndIf

  nextIndex = GetNextPlaylistIndex(direction)
  If nextIndex >= 0
    PlayPlaylistIndexAndStart(nextIndex)
  EndIf
EndProcedure

Procedure SetProgressPosition(position.q)
  If IsGadget(#Gadget_Progress)
    isUserSeeking = 0
    SetGadgetState(#Gadget_Progress, position)
    isUserSeeking = 1
  EndIf

  If IsGadget(#Gadget_PlaylistProgress)
    isUserSeeking = 0
    SetGadgetState(#Gadget_PlaylistProgress, position)
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
  EndIf
EndProcedure

Procedure UpdatePlaybackStatus(prefix.s)
  Protected message.s = prefix

  If GetTrackDisplayName() <> ""
    message + ": '" + GetTrackDisplayName() + "'"
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
      StartLoadedPlayback()
  EndSelect
EndProcedure

Procedure SaveSettings()
  Protected winX.i = State\winX
  Protected winY.i = State\winY
  Protected settingsPath.s = AppPath + "files\HandyMPlayer.ini"

  If IsWindow(#Window_Main)
    winX = WindowX(#Window_Main)
    winY = WindowY(#Window_Main)
  EndIf

  EnsureDirectoryPath(AppPath + "files\")
  If CreatePreferences(settingsPath)
    PreferenceGroup("Settings")
    WritePreferenceInteger("Volume", State\volume)
    WritePreferenceInteger("Balance", State\balance)
    WritePreferenceInteger("WinX", winX)
    WritePreferenceInteger("WinY", winY)
    WritePreferenceInteger("SidebarWidth", State\sidebarWidth)
    WritePreferenceInteger("ContinuousPlay", State\continuousPlay)
    WritePreferenceInteger("ShufflePlay", State\shufflePlay)
    WritePreferenceInteger("RepeatPlay", State\repeatPlay)
    WritePreferenceString("LibraryRoot", LibraryRootPath)
    WritePreferenceString("LastPlaylist", LastPlaylistPath)
    WritePreferenceString("CurrentPlaylist", CurrentPlaylistName)
    ClosePreferences()
  EndIf
EndProcedure

Procedure LoadSettings()
  Protected settingsPath.s = AppPath + "files\HandyMPlayer.ini"

  If OpenPreferences(settingsPath)
    PreferenceGroup("Settings")
    State\volume = ReadPreferenceInteger("Volume", 100)
    State\balance = ReadPreferenceInteger("Balance", 0)
    State\winX = ReadPreferenceInteger("WinX", -1)
    State\winY = ReadPreferenceInteger("WinY", -1)
    State\sidebarWidth = ReadPreferenceInteger("SidebarWidth", #SidebarWidth)
    State\continuousPlay = ReadPreferenceInteger("ContinuousPlay", #True)
    State\shufflePlay = ReadPreferenceInteger("ShufflePlay", #False)
    State\repeatPlay = ReadPreferenceInteger("RepeatPlay", #False)
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
    State\continuousPlay = #True
    State\shufflePlay = #False
    State\repeatPlay = #False
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

Procedure.q MovieLengthMS(movie.i)
  Protected ms.q = 0

  CompilerIf Defined(GetMovieLength, #PB_Procedure)
    ms = GetMovieLength(movie)
  CompilerEndIf

  ProcedureReturn ms
EndProcedure

Procedure ResizeMainForVideo(videoW.i, videoH.i)
  Protected innerW.i = DesktopScaledX(videoW)
  Protected innerH.i = DesktopScaledY(videoH)
  Protected frameDeltaW.i
  Protected frameDeltaH.i

  If innerW < DesktopScaledX(320) : innerW = DesktopScaledX(320) : EndIf
  If innerH < DesktopScaledY(240) : innerH = DesktopScaledY(240) : EndIf

  EnsureVideoHostWindow()
  If IsWindow(#Window_Video)
    frameDeltaW = WindowWidth(#Window_Video, #PB_Window_FrameCoordinate) - WindowWidth(#Window_Video, #PB_Window_InnerCoordinate)
    frameDeltaH = WindowHeight(#Window_Video, #PB_Window_FrameCoordinate) - WindowHeight(#Window_Video, #PB_Window_InnerCoordinate)
    ResizeWindow(#Window_Video, #PB_Ignore, #PB_Ignore, innerW + frameDeltaW, innerH + frameDeltaH)
    SetWindowTitle(#Window_Video, "Video - " + State\fileName)
    HideWindow(#Window_Video, 0)
    If State\movieLoaded And IsMovie(0)
      ResizeMovie(0, 0, 0, WindowWidth(#Window_Video, #PB_Window_InnerCoordinate), WindowHeight(#Window_Video, #PB_Window_InnerCoordinate))
    EndIf
  EndIf
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

  If IsWindow(#Window_Video)
    HideWindow(#Window_Video, 1)
  EndIf
EndProcedure

Procedure EnsureVideoHostWindow()
  If IsWindow(#Window_Video)
    ProcedureReturn
  EndIf

  Protected initialW.i = DesktopScaledX(State\targetW)
  Protected initialH.i = DesktopScaledY(State\targetH)

  If initialW < DesktopScaledX(320) : initialW = DesktopScaledX(320) : EndIf
  If initialH < DesktopScaledY(240) : initialH = DesktopScaledY(240) : EndIf

  If OpenWindow(#Window_Video, #PB_Ignore, #PB_Ignore, initialW, initialH, "Video", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#Window_Main))
    HideWindow(#Window_Video, 1)
  EndIf
EndProcedure

Procedure ShowVideoWindow()
  If State\movieLoaded = 0 Or State\movieHasVideo = 0
    ProcedureReturn
  EndIf

  EnsureVideoHostWindow()
  If IsWindow(#Window_Video)
    SetWindowTitle(#Window_Video, "Video - " + State\fileName)
    HideWindow(#Window_Video, 0)
    SetActiveWindow(#Window_Video)
    If IsMovie(0)
      ResizeMovie(0, 0, 0, WindowWidth(#Window_Video, #PB_Window_InnerCoordinate), WindowHeight(#Window_Video, #PB_Window_InnerCoordinate))
    EndIf
  EndIf
EndProcedure

Procedure ToggleVideoWindow()
  If IsWindow(#Window_Video) And IsWindowVisible_(WindowID(#Window_Video))
    HideWindow(#Window_Video, 1)
  Else
    ShowVideoWindow()
  EndIf
EndProcedure

Procedure UpdateSeekPositionFromGadget(gadget.i)
  Protected pbMax.q, seekTarget.q

  If State\movieLoaded = 0 Or IsMovie(0) = 0
    ProcedureReturn
  EndIf

  If State\movieState <> #MovieState_Playing And State\movieState <> #MovieState_Paused
    ProcedureReturn
  EndIf

  If isUserSeeking = 0
    ProcedureReturn
  EndIf

  pbMax = GetGadgetAttribute(gadget, #PB_TrackBar_Maximum)
  If pbMax <= 0
    ProcedureReturn
  EndIf

  seekTarget = GetGadgetState(gadget)

  If State\movieHasVideo
    If State\movieLengthFrames > 0
      seekTarget = (State\movieLengthFrames * seekTarget) / pbMax
      MovieSeek(0, seekTarget)
    EndIf
  Else
    If State\audioTotalFrames > 0
      seekTarget = (State\audioTotalFrames * seekTarget) / pbMax
      MovieSeek(0, seekTarget)

      If State\audioTotalMS > 0
        If State\audioTotalFrames = State\audioTotalMS
          State\audioPausedElapsedMS = seekTarget
        Else
          State\audioPausedElapsedMS = (State\audioTotalMS * seekTarget) / State\audioTotalFrames
        EndIf
        State\audioStartMS = ElapsedMilliseconds() - State\audioPausedElapsedMS
      EndIf
    Else
      ProcedureReturn
    EndIf
  EndIf
EndProcedure

Procedure ProgressBarSeek()
  UpdateSeekPositionFromGadget(#Gadget_Progress)
EndProcedure

Procedure ProgressBarSeekForGadget()
  UpdateSeekPositionFromGadget(EventGadget())
EndProcedure

Procedure ProgressBarClickToSeekForGadget()
  Protected gadget.i = EventGadget()

  If IsGadget(gadget) = 0
    ProcedureReturn
  EndIf

  Protected pt.WinPOINT
  Protected rc.WinRECT
  Protected barW.i
  Protected x.i
  Protected newPos.q

  If GetCursorPos_(@pt) = 0
    ProcedureReturn
  EndIf

  ScreenToClient_(GadgetID(gadget), @pt)

  Protected pbMax.q
  If GetClientRect_(GadgetID(gadget), @rc) = 0
    ProcedureReturn
  EndIf

  barW = rc\right - rc\left
  If barW <= 0
    ProcedureReturn
  EndIf

  pbMax = GetGadgetAttribute(gadget, #PB_TrackBar_Maximum)
  If pbMax <= 0
    pbMax = #ProgressScaleMax
  EndIf

  x = pt\x
  If x < 0 : x = 0 : EndIf
  If x > barW : x = barW : EndIf

  newPos = (pbMax * x) / barW

  isUserSeeking = 1
  SetGadgetState(gadget, newPos)
  UpdateSeekPositionFromGadget(gadget)
EndProcedure

Procedure ProgressBarClickToSeek()
  If IsGadget(#Gadget_Progress) = 0
    ProcedureReturn
  EndIf

  Protected pt.WinPOINT
  Protected rc.WinRECT
  Protected barW.i
  Protected x.i
  Protected newPos.q
  Protected pbMax.q

  If GetCursorPos_(@pt) = 0
    ProcedureReturn
  EndIf

  ScreenToClient_(GadgetID(#Gadget_Progress), @pt)

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
  UpdateSeekPositionFromGadget(#Gadget_Progress)
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
  Protected pbX.i = contentX + DesktopScaledX(#ProgressBarLeft)
  Protected pbY.i = toolH + DesktopScaledY(#LayoutPadding)
  Protected pbW.i = contentW - DesktopScaledX(#ProgressBarLeft + #ProgressBarRightMargin)
  Protected pbH.i = DesktopScaledY(#ProgressBarHeight + 6)
  Protected metaY.i
  If pbW < 10 : pbW = 10 : EndIf
  If contentW < 50 : contentW = 50 : EndIf

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
  If IsGadget(#Gadget_Progress)
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

  KeepStatusBarOnTop()
EndProcedure

Procedure LoadFile(path.s)
  Protected embedded.EmbeddedMediaInfo
  Protected metadata.TrackMetadata
  Protected existingArtworkFile.s
  Protected folderArtwork.s
  Protected existingLyricsFile.s

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
      FillTrackMetadataFromPath(path, @metadata)
      existingArtworkFile = FindArtworkFileForTrack(@metadata)
      existingLyricsFile = FindLyricsFileForTrack(@metadata)

      If existingArtworkFile <> "" And LoadArtworkImage(existingArtworkFile)
        State\artworkSource = "downloaded"
      EndIf

      If existingLyricsFile <> ""
        State\lyricsFile = existingLyricsFile
        If Right(LCase(GetFilePart(existingLyricsFile)), 12) = "-attached.txt" Or Right(LCase(GetFilePart(existingLyricsFile)), 12) = "-attached.lrc"
          State\lyricsSource = "attached"
        ElseIf Right(LCase(GetFilePart(existingLyricsFile)), 12) = "-embedded.txt" Or Right(LCase(GetFilePart(existingLyricsFile)), 12) = "-embedded.lrc"
          State\lyricsSource = "embedded"
        Else
          State\lyricsSource = "downloaded"
        EndIf
      EndIf

      ExtractEmbeddedMediaInfo(path, @embedded)
      If embedded\artist <> "" : State\artist = embedded\artist : EndIf
      If embedded\title <> "" : State\title = embedded\title : EndIf
      If State\artist <> "" Or State\title <> ""
        State\metadataSource = "embedded"
      ElseIf State\fileName <> ""
        State\metadataSource = "filename"
      EndIf
      If State\lyricsFile = "" And embedded\lyrics <> ""
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

      If State\artworkFile <> ""
        ResizeMainForAudio(#True)
      ElseIf embedded\artworkFile <> "" And LoadArtworkImage(embedded\artworkFile)
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

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 389
; FirstLine = 447
; Folding = ------
; EnableXP
; DPIAware
