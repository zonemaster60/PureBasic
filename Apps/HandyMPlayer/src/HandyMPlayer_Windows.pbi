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

Procedure ToggleArtworkPreviewWindow()
  If IsWindow(#Window_ArtworkPreview) And IsWindowVisible_(WindowID(#Window_ArtworkPreview))
    HideWindow(#Window_ArtworkPreview, 1)
  Else
    ShowArtworkPreview()
  EndIf
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
  If State\lyricsFile = "" Or FileSize(State\lyricsFile) <= 0
    ProcedureReturn
  EndIf

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

Procedure ToggleLyricsWindow()
  If IsWindow(#Window_Lyrics) And IsWindowVisible_(WindowID(#Window_Lyrics))
    HideWindow(#Window_Lyrics, 1)
  Else
    ShowLyricsWindow()
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
  helpText + "4. Use File > Load Playlist / Save Playlist to work with M3U playlists." + #CRLF$
  helpText + "5. Use File > Close Media to unload the current media and clear the playlist." + #CRLF$ + #CRLF$
  helpText + "Playback" + #CRLF$
  helpText + "- Toolbar Play/Pause starts or toggles playback for the currently loaded media." + #CRLF$
  helpText + "- Stop stops the current file." + #CRLF$
  helpText + "- The progress bar can be clicked or dragged to seek." + #CRLF$
  helpText + "- Left / Right arrow keys move to previous / next queued-or-playlist track." + #CRLF$ + #CRLF$
  helpText + "View Windows" + #CRLF$
  helpText + "- Use the View menu to toggle Playlist, Lyrics, Artwork, Video, and Visualization windows." + #CRLF$
  helpText + "- Video opens in its own separate window when a video file is played." + #CRLF$ + #CRLF$
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
  helpText + "- Saved artwork in the downloads\\album-art folder is loaded automatically for matching tracks." + #CRLF$
  helpText + "- Common folder artwork names include cover, folder, front, album, artwork, or the same basename as the track." + #CRLF$
  helpText + "- Supported folder artwork formats include JPG, JPEG, PNG, GIF, and BMP." + #CRLF$
  helpText + "- Click the artwork image to open a larger preview." + #CRLF$
  helpText + "- The artwork preview window can be shown or hidden from the View menu." + #CRLF$ + #CRLF$
  helpText + "Lyrics" + #CRLF$
  helpText + "- Lyrics embedded in supported audio files are loaded automatically when a track is opened." + #CRLF$
  helpText + "- Saved lyrics in the downloads\\lyrics folder are loaded automatically for matching tracks." + #CRLF$
  helpText + "- You can attach a .txt or .lrc file by dropping it onto the main window while an audio track is loaded." + #CRLF$
  helpText + "- Downloaded or attached lyrics can be reopened from View > Lyrics." + #CRLF$ + #CRLF$
  helpText + "Visualization" + #CRLF$
  helpText + "- View > Visualization opens a retro digital VU-style display window for audio playback." + #CRLF$
  helpText + "- The visualization is decorative and tempo-styled, not true audio beat detection." + #CRLF$ + #CRLF$
  helpText + "Tips" + #CRLF$
  helpText + "- If the music tree looks out of date, reload the folder." + #CRLF$
  helpText + "- For best metadata display, keep filenames in Artist - Title format when tags are missing." + #CRLF$
  helpText + "- The current library root, current playlist, sidebar width, and queue are remembered between runs." + #CRLF$ + #CRLF$
  helpText + "Troubleshooting" + #CRLF$
  helpText + "- If a selected file does not play, try double-clicking it in the tree or adding it to the playlist first." + #CRLF$
  helpText + "- If artwork does not appear, check for saved artwork, embedded art, or an image file in the same folder as the track." + #CRLF$
  helpText + "- If lyrics do not appear, check for saved lyrics, embedded lyrics, or attach/download lyrics for the track." + #CRLF$
  helpText + "- Video resizing commands affect video files only." + #CRLF$
  helpText + "- Close Media clears the current playlist as well as unloading the current track." + #CRLF$

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

Procedure ToggleHelpWindow()
  If IsWindow(#Window_Help) And IsWindowVisible_(WindowID(#Window_Help))
    HideWindow(#Window_Help, 1)
  Else
    ShowHelpWindow()
  EndIf
EndProcedure

Procedure UpdatePlaylistWindowLayout()
  Protected winW.i
  Protected winH.i

  If IsWindow(#Window_Playlist) = 0
    ProcedureReturn
  EndIf

  winW = WindowWidth(#Window_Playlist, #PB_Window_InnerCoordinate)
  winH = WindowHeight(#Window_Playlist, #PB_Window_InnerCoordinate)

  ResizeGadget(#Gadget_PlaylistTitle, 10, 10, winW - 20, 18)
  ResizeGadget(#Gadget_PlaylistProgress, 10, 32, winW - 20, #ProgressBarHeight + 6)
  ResizeGadget(#Gadget_PlaylistNowPlaying, 10, 56, winW - 20, 18)
  ResizeGadget(#Gadget_PlaylistTabs, 10, 78, winW - 20, 28)
  ResizeGadget(#Gadget_PlaylistNew, 10, 110, 30, 24)
  ResizeGadget(#Gadget_PlaylistRename, 45, 110, 30, 24)
  ResizeGadget(#Gadget_PlaylistDelete, 80, 110, 30, 24)
  ResizeGadget(#Gadget_PlaylistShuffle, winW - 205, 110, 45, 24)
  ResizeGadget(#Gadget_PlaylistPlay, winW - 155, 110, 45, 24)
  ResizeGadget(#Gadget_PlaylistPause, winW - 105, 110, 45, 24)
  ResizeGadget(#Gadget_PlaylistStop, winW - 55, 110, 45, 24)
  ResizeGadget(#Gadget_Playlist, 10, 138, winW - 20, 150)
  ResizeGadget(#Gadget_PlaylistUp, 10, 292, 65, #SidebarButtonHeight)
  ResizeGadget(#Gadget_PlaylistDown, 80, 292, 65, #SidebarButtonHeight)
  ResizeGadget(#Gadget_PlaylistRemove, 150, 292, 75, #SidebarButtonHeight)
  ResizeGadget(#Gadget_PlaylistClear, 230, 292, 65, #SidebarButtonHeight)
  ResizeGadget(#Gadget_QueueTitle, 10, 332, winW - 20, 18)
  ResizeGadget(#Gadget_QueueList, 10, 354, winW - 100, 108)
  ResizeGadget(#Gadget_QueueAdd, winW - 80, 354, 70, 24)
  ResizeGadget(#Gadget_QueueClear, winW - 80, 384, 70, 24)
  ResizeGadget(#Gadget_QueueUp, 10, 466, 50, 24)
  ResizeGadget(#Gadget_QueueDown, 65, 466, 50, 24)
  ResizeGadget(#Gadget_QueueRemove, 120, 466, 75, 24)
EndProcedure

Procedure ShowPlaylistWindow()
  If IsWindow(#Window_Playlist) = 0
    If OpenWindow(#Window_Playlist, #PB_Ignore, #PB_Ignore, #PlaylistWindowWidth, #PlaylistWindowHeight, "Playlist", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#Window_Main))
      TextGadget(#Gadget_PlaylistTitle, 10, 10, 200, 18, "Playlist")
      TrackBarGadget(#Gadget_PlaylistProgress, 10, 32, 390, #ProgressBarHeight + 6, 0, #ProgressScaleMax)
      TextGadget(#Gadget_PlaylistNowPlaying, 10, 56, 390, 18, "Now Playing: nothing loaded")
      ComboBoxGadget(#Gadget_PlaylistTabs, 10, 78, 200, 28)
      ButtonGadget(#Gadget_PlaylistNew, 10, 110, 30, 24, "+")
      ButtonGadget(#Gadget_PlaylistRename, 45, 110, 30, 24, "R")
      ButtonGadget(#Gadget_PlaylistDelete, 80, 110, 30, 24, "-")
      ButtonGadget(#Gadget_PlaylistShuffle, 205, 110, 45, 24, "Rnd")
      ButtonGadget(#Gadget_PlaylistPlay, 255, 110, 45, 24, "Play")
      ButtonGadget(#Gadget_PlaylistPause, 305, 110, 45, 24, "Pause")
      ButtonGadget(#Gadget_PlaylistStop, 355, 110, 45, 24, "Stop")
      ListViewGadget(#Gadget_Playlist, 10, 138, 390, 150)
      ButtonGadget(#Gadget_PlaylistUp, 10, 292, 65, #SidebarButtonHeight, "Up")
      ButtonGadget(#Gadget_PlaylistDown, 80, 292, 65, #SidebarButtonHeight, "Down")
      ButtonGadget(#Gadget_PlaylistRemove, 150, 292, 75, #SidebarButtonHeight, "Remove")
      ButtonGadget(#Gadget_PlaylistClear, 230, 292, 65, #SidebarButtonHeight, "Clear")
      TextGadget(#Gadget_QueueTitle, 10, 332, 200, 18, "Queue")
      ListViewGadget(#Gadget_QueueList, 10, 354, 310, 108)
      ButtonGadget(#Gadget_QueueAdd, 330, 354, 70, 24, "Enqueue")
      ButtonGadget(#Gadget_QueueClear, 330, 384, 70, 24, "Clear")
      ButtonGadget(#Gadget_QueueUp, 10, 466, 50, 24, "Up")
      ButtonGadget(#Gadget_QueueDown, 65, 466, 50, 24, "Down")
      ButtonGadget(#Gadget_QueueRemove, 120, 466, 75, 24, "Remove")
      BindGadgetEvent(#Gadget_PlaylistProgress, @ProgressBarSeekForGadget())
      BindGadgetEvent(#Gadget_PlaylistProgress, @ProgressBarClickToSeekForGadget(), #PB_EventType_LeftClick)
      RefreshPlaylistSelector()
      RefreshPlaylistGadget()
      RefreshQueueGadget()
      GadgetToolTip(#Gadget_PlaylistShuffle, "Toggle playlist shuffle/random")
      SetProgressPosition(0)
      UpdatePlaylistWindowLayout()
    EndIf
  EndIf

  If IsWindow(#Window_Playlist)
    HideWindow(#Window_Playlist, 0)
    SetActiveWindow(#Window_Playlist)
  EndIf
EndProcedure

Procedure TogglePlaylistWindow()
  If IsWindow(#Window_Playlist) And IsWindowVisible_(WindowID(#Window_Playlist))
    HideWindow(#Window_Playlist, 1)
  Else
    ShowPlaylistWindow()
  EndIf
EndProcedure

Procedure UpdateVisualizationWindow()
  Protected canvasW.i
  Protected canvasH.i
  Protected barCount.i = 20
  Protected gap.i = 5
  Protected meterLeft.i
  Protected meterTop.i = 44
  Protected meterBottom.i
  Protected meterHeight.i
  Protected barWidth.i
  Protected i.i
  Protected activeHeight.i
  Protected peakHeight.i
  Protected trackSeed.i
  Protected bpm.d
  Protected beatPosition.d
  Protected beatStrength.d
  Protected beatCurve.d
  Protected stereoBias.d
  Protected stereoPhase.d
  Protected wobble.d
  Protected sway.d
  Protected flicker.d
  Protected leftWeight.d
  Protected rightWeight.d
  Protected volumeScale.d
  Protected barX.i
  Protected barY.i
  Protected segmentCount.i = 18
  Protected segmentGap.i = 2
  Protected segmentHeight.i
  Protected segmentIndex.i
  Protected segmentY.i
  Protected litThreshold.i
  Protected baseColor.i
  Protected dimColor.i
  Protected gridColor.i
  Protected labelText.s
  Protected channelLabel.s
  Protected centerGap.i = 18
  Protected channelMid.i
  Protected x.i
  Protected y.i

  If IsWindow(#Window_Visualization) = 0 Or IsGadget(#Gadget_VisualizationCanvas) = 0
    ProcedureReturn
  EndIf

  canvasW = GadgetWidth(#Gadget_VisualizationCanvas)
  canvasH = GadgetHeight(#Gadget_VisualizationCanvas)
  If canvasW <= 0 Or canvasH <= 0
    ProcedureReturn
  EndIf

  meterLeft = 18
  meterBottom = canvasH - 22
  meterHeight = meterBottom - meterTop
  If meterHeight <= 40
    ProcedureReturn
  EndIf

  barWidth = (canvasW - (meterLeft * 2) - ((barCount - 1) * gap)) / barCount
  If barWidth < 8
    barWidth = 8
  EndIf

  channelMid = meterLeft + ((barCount / 2) * (barWidth + gap)) - (gap / 2)

  volumeScale = State\volume / 100.0
  If volumeScale < 0.08
    volumeScale = 0.08
  EndIf

  trackSeed = Len(State\moviePath) + (Len(GetTrackDisplayName()) * 11)
  bpm = 92 + Mod(trackSeed, 56)
  If bpm < 92 : bpm = 92 : EndIf
  If bpm > 147 : bpm = 147 : EndIf

  If State\movieLoaded And State\movieHasVideo = 0
    If State\movieState = #MovieState_Playing And State\audioStartMS > 0
      beatPosition = (ElapsedMilliseconds() - State\audioStartMS) / (60000.0 / bpm)
    Else
      beatPosition = State\audioPausedElapsedMS / (60000.0 / bpm)
    EndIf
  Else
    beatPosition = ElapsedMilliseconds() / (60000.0 / bpm)
  EndIf

  beatPosition - Int(beatPosition)
  beatCurve = 1.0 - beatPosition
  beatStrength = 0.24 + (beatCurve * beatCurve * 0.76)

  If StartDrawing(CanvasOutput(#Gadget_VisualizationCanvas))
    Box(0, 0, canvasW, canvasH, RGB(6, 10, 14))
    gridColor = RGB(14, 24, 18)
    For x = 0 To canvasW Step 14
      Line(x, 0, 1, canvasH, gridColor)
    Next
    For y = 0 To canvasH Step 14
      Line(0, y, canvasW, 1, gridColor)
    Next

    Box(meterLeft - 10, meterTop - 10, canvasW - ((meterLeft - 10) * 2), meterHeight + 20, RGB(10, 18, 14))
    Line(channelMid - (centerGap / 2), meterTop - 2, 2, meterHeight + 4, RGB(26, 40, 34))
    Line(channelMid + (centerGap / 2), meterTop - 2, 2, meterHeight + 4, RGB(26, 40, 34))

    DrawingMode(#PB_2DDrawing_Transparent)
    FrontColor(RGB(92, 255, 214))

    If State\movieLoaded And State\movieHasVideo = 0
      labelText = "DIGITAL VU " + UCase(GetTrackDisplayName())
    ElseIf State\movieLoaded And State\movieHasVideo
      labelText = "DIGITAL VU VIDEO MODE"
    Else
      labelText = "DIGITAL VU NO AUDIO LOADED"
    EndIf
    DrawText(18, 14, labelText)

    If State\movieLoaded And State\movieHasVideo = 0 And State\movieState = #MovieState_Playing
      segmentHeight = (meterHeight - ((segmentCount - 1) * segmentGap)) / segmentCount
      If segmentHeight < 4
        segmentHeight = 4
      EndIf

      For i = 0 To barCount - 1
        stereoPhase = (beatPosition * 6.28318) + (trackSeed * 0.013)
        stereoBias = (Sin(stereoPhase) + 1.0) * 0.5
        leftWeight = 0.72 + ((1.0 - stereoBias) * 0.55)
        rightWeight = 0.72 + (stereoBias * 0.55)

        If i < barCount / 2
          wobble = (Sin((beatPosition * 6.28318) + (i * 0.34) + (trackSeed * 0.01)) + 1.0) * 0.5
          sway = (Sin((beatPosition * 18.84954) + (i * 0.28)) + 1.0) * 0.5
          flicker = (Sin((beatPosition * 37.69908) + (i * 0.17)) + 1.0) * 0.5
          activeHeight = meterHeight * volumeScale * leftWeight * (0.10 + (beatStrength * 0.62) + (wobble * 0.12) + (sway * 0.10) + (flicker * 0.06))
          channelLabel = "L"
        Else
          wobble = (Sin((beatPosition * 6.28318) + (i * 0.38) + 1.4 + (trackSeed * 0.01)) + 1.0) * 0.5
          sway = (Sin((beatPosition * 21.99114) + (i * 0.31)) + 1.0) * 0.5
          flicker = (Sin((beatPosition * 43.98228) + (i * 0.19)) + 1.0) * 0.5
          activeHeight = meterHeight * volumeScale * rightWeight * (0.10 + (beatStrength * 0.62) + (wobble * 0.12) + (sway * 0.10) + (flicker * 0.06))
          channelLabel = "R"
        EndIf

        peakHeight = activeHeight + (meterHeight * 0.06)
        If peakHeight > meterHeight
          peakHeight = meterHeight
        EndIf

        litThreshold = (activeHeight * segmentCount) / meterHeight
        If litThreshold < 1
          litThreshold = 1
        EndIf
        If litThreshold > segmentCount
          litThreshold = segmentCount
        EndIf

        barX = meterLeft + (i * (barWidth + gap))
        For segmentIndex = 0 To segmentCount - 1
          segmentY = meterBottom - ((segmentIndex + 1) * segmentHeight) - (segmentIndex * segmentGap)

          If segmentIndex < litThreshold
            If segmentIndex >= segmentCount - 3
              baseColor = RGB(255, 86, 86)
            ElseIf segmentIndex >= segmentCount - 7
              baseColor = RGB(255, 210, 64)
            Else
              baseColor = RGB(84, 255, 150)
            EndIf
          Else
            baseColor = RGB(20, 34, 24)
          EndIf

          Box(barX, segmentY, barWidth, segmentHeight, baseColor)
          Box(barX + 1, segmentY + 1, barWidth - 2, segmentHeight - 2, RGB(Red(baseColor) / 2, Green(baseColor) / 2, Blue(baseColor) / 2))
        Next

        If peakHeight > 0
          barY = meterBottom - peakHeight
          Box(barX, barY, barWidth, 3, RGB(220, 245, 255))
        EndIf

        If i = 0
          DrawText(barX, meterBottom + 4, channelLabel)
        ElseIf i = barCount / 2
          DrawText(barX, meterBottom + 4, channelLabel)
        EndIf
      Next
    Else
      dimColor = RGB(28, 46, 34)
      For i = 0 To barCount - 1
        barX = meterLeft + (i * (barWidth + gap))
        For segmentIndex = 0 To segmentCount - 1
          segmentY = meterBottom - ((segmentIndex + 1) * segmentHeight) - (segmentIndex * segmentGap)
          Box(barX, segmentY, barWidth, segmentHeight, dimColor)
          Box(barX + 1, segmentY + 1, barWidth - 2, segmentHeight - 2, RGB(10, 18, 14))
        Next
      Next
      DrawText(meterLeft, meterBottom + 4, "L")
      DrawText(meterLeft + ((barCount / 2) * (barWidth + gap)), meterBottom + 4, "R")
    EndIf

    StopDrawing()
  EndIf
EndProcedure

Procedure ShowVisualizationWindow()
  If IsWindow(#Window_Visualization) = 0
    If OpenWindow(#Window_Visualization, #PB_Ignore, #PB_Ignore, #VisualizationWindowWidth, #VisualizationWindowHeight, "Visualization", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#Window_Main))
      CanvasGadget(#Gadget_VisualizationCanvas, 0, 0, WindowWidth(#Window_Visualization, #PB_Window_InnerCoordinate), WindowHeight(#Window_Visualization, #PB_Window_InnerCoordinate))
    EndIf
  EndIf

  If IsWindow(#Window_Visualization)
    ResizeGadget(#Gadget_VisualizationCanvas, 0, 0, WindowWidth(#Window_Visualization, #PB_Window_InnerCoordinate), WindowHeight(#Window_Visualization, #PB_Window_InnerCoordinate))
    UpdateVisualizationWindow()
    HideWindow(#Window_Visualization, 0)
    SetActiveWindow(#Window_Visualization)
  EndIf
EndProcedure

Procedure ToggleVisualizationWindow()
  If IsWindow(#Window_Visualization) And IsWindowVisible_(WindowID(#Window_Visualization))
    HideWindow(#Window_Visualization, 1)
  Else
    ShowVisualizationWindow()
  EndIf
EndProcedure

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 449
; FirstLine = 413
; Folding = --
; EnableXP
; DPIAware
; Executable = ..\HandyMPlayer.exe
