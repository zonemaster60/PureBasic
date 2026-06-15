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
    If OpenWindow(#Window_ArtworkPreview, #PB_Ignore, #PB_Ignore, #ArtworkPreviewWindowWidth, #ArtworkPreviewWindowHeight, "Artwork", #PB_Window_SizeGadget | #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#Window_Main))
      ApplyWindowTheme(#Window_ArtworkPreview)
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
    If OpenWindow(#Window_Lyrics, #PB_Ignore, #PB_Ignore, #LyricsWindowWidth, #LyricsWindowHeight, "Lyrics", #PB_Window_SizeGadget | #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#Window_Main))
      ApplyWindowTheme(#Window_Lyrics)
      EditorGadget(#Gadget_LyricsEditor, 0, 0, WindowWidth(#Window_Lyrics), WindowHeight(#Window_Lyrics), #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
      ApplyGadgetTheme(#Gadget_LyricsEditor)
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
  helpText = "" + #CRLF$
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
  helpText + "- Use the View menu to toggle Playlist, Lyrics, Artwork, Video, Browser, and Theme Settings windows." + #CRLF$
  helpText + "- Video opens in its own separate window when a video file is played." + #CRLF$ + #CRLF$
  helpText + "Browser" + #CRLF$
  helpText + "- Open View > Browser to browse, search, and play YouTube videos." + #CRLF$
  helpText + "- Enter a URL or search text, then press Enter or Go." + #CRLF$
  helpText + "- Back, Next, Reload, and Home navigate the browser history and YouTube home." + #CRLF$
  helpText + "- Play, Pause, and Stop control the current HTML5 video when the embedded browser allows page scripting." + #CRLF$ + #CRLF$
  helpText + "Theme Settings" + #CRLF$
  helpText + "- Open View > Theme Settings to change application colors." + #CRLF$
  helpText + "- System, Light, Dark, Blue, and Forest apply built-in color presets." + #CRLF$
  helpText + "- Window, Panel, Text, and Accent buttons open color pickers for a custom theme." + #CRLF$
  helpText + "- Theme changes apply immediately to open windows and are saved in files\\HandyMPlayer.ini." + #CRLF$
  helpText + "- Native Windows controls such as buttons may keep their system styling, but windows, text panels, lists, editors, and progress accents use the selected colors." + #CRLF$ + #CRLF$
  helpText + "Reusable Theme Code" + #CRLF$
  helpText + "- The reusable theme helper is saved as src\\HandyTheme_Reusable.pbi." + #CRLF$
  helpText + "- A minimal copy-and-run example is saved as src\\HandyTheme_Example.pb." + #CRLF$
  helpText + "- Include HandyTheme_Reusable.pbi in another PureBasic project to reuse the preset, custom color, and preference helper procedures." + #CRLF$ + #CRLF$
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
    If OpenWindow(#Window_Help, #PB_Ignore, #PB_Ignore, #HelpWindowWidth, #HelpWindowHeight, "Help", #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#Window_Main))
      ApplyWindowTheme(#Window_Help)
      EditorGadget(#Gadget_HelpEditor, 0, 0, WindowWidth(#Window_Help), WindowHeight(#Window_Help), #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
      SetGadgetText(#Gadget_HelpEditor, GetHelpText())
      ApplyGadgetTheme(#Gadget_HelpEditor)
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
  Protected totalMS.q
  Protected titleText.s

  If IsWindow(#Window_Playlist) = 0
    ProcedureReturn
  EndIf

  winW = WindowWidth(#Window_Playlist, #PB_Window_InnerCoordinate)
  winH = WindowHeight(#Window_Playlist, #PB_Window_InnerCoordinate)
  totalMS = GetCurrentMediaLengthMS()

  titleText = "Playlist"
  If totalMS > 0
    titleText + " (" + FormatTime(totalMS / 1000) + ")"
  EndIf
  SetGadgetText(#Gadget_PlaylistTitle, titleText)

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
    If OpenWindow(#Window_Playlist, #PB_Ignore, #PB_Ignore, #PlaylistWindowWidth, #PlaylistWindowHeight, "Playlist", #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#Window_Main))
      ApplyWindowTheme(#Window_Playlist)
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
      ApplyGadgetTheme(#Gadget_PlaylistTitle, #True)
      ApplyGadgetTheme(#Gadget_PlaylistNowPlaying, #True)
      ApplyGadgetTheme(#Gadget_PlaylistTabs)
      ApplyGadgetTheme(#Gadget_Playlist)
      ApplyGadgetTheme(#Gadget_QueueTitle, #True)
      ApplyGadgetTheme(#Gadget_QueueList)
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

Procedure.s BrowserBuildUrl(value.s)
  Protected address.s = Trim(value)

  If address = ""
    ProcedureReturn #BrowserHomeUrl
  EndIf

  If FindString(LCase(address), "http://") = 1 Or FindString(LCase(address), "https://") = 1 Or FindString(LCase(address), "file://") = 1
    ProcedureReturn address
  EndIf

  If FindString(address, ".") > 0 And FindString(address, " ") = 0
    ProcedureReturn "https://" + address
  EndIf

  ProcedureReturn "https://www.youtube.com/results?search_query=" + UrlEncodeUTF8(address)
EndProcedure

Procedure BrowserNavigate()
  If IsGadget(#Gadget_BrowserWeb) = 0 Or IsGadget(#Gadget_BrowserAddress) = 0
    ProcedureReturn
  EndIf

  SetGadgetText(#Gadget_BrowserWeb, BrowserBuildUrl(GetGadgetText(#Gadget_BrowserAddress)))
EndProcedure

Procedure BrowserRunScript(script.s)
  If IsGadget(#Gadget_BrowserWeb) = 0
    ProcedureReturn
  EndIf

  SetGadgetText(#Gadget_BrowserWeb, "javascript:" + script)
EndProcedure

Procedure BrowserPlay()
  BrowserRunScript("(function(){var v=document.querySelector('video');if(v){v.play();}else{var b=document.querySelector('.ytp-play-button');if(b&&b.getAttribute('title')!='Pause'){b.click();}}})();")
EndProcedure

Procedure BrowserPause()
  BrowserRunScript("(function(){var v=document.querySelector('video');if(v){v.pause();}else{var b=document.querySelector('.ytp-play-button');if(b&&b.getAttribute('title')!='Play'){b.click();}}})();")
EndProcedure

Procedure BrowserStop()
  BrowserRunScript("(function(){var v=document.querySelector('video');if(v){v.pause();try{v.currentTime=0;}catch(e){}}})();")
EndProcedure

Procedure UpdateBrowserWindowLayout()
  Protected winW.i
  Protected winH.i
  Protected topH.i = 72
  Protected buttonY.i = 10
  Protected mediaY.i = 42

  If IsWindow(#Window_Browser) = 0
    ProcedureReturn
  EndIf

  winW = WindowWidth(#Window_Browser, #PB_Window_InnerCoordinate)
  winH = WindowHeight(#Window_Browser, #PB_Window_InnerCoordinate)

  If IsGadget(#Gadget_BrowserBack)
    ResizeGadget(#Gadget_BrowserBack, 10, buttonY, 50, 24)
  EndIf
  If IsGadget(#Gadget_BrowserForward)
    ResizeGadget(#Gadget_BrowserForward, 65, buttonY, 50, 24)
  EndIf
  If IsGadget(#Gadget_BrowserReload)
    ResizeGadget(#Gadget_BrowserReload, 120, buttonY, 60, 24)
  EndIf
  If IsGadget(#Gadget_BrowserHome)
    ResizeGadget(#Gadget_BrowserHome, 185, buttonY, 55, 24)
  EndIf
  If IsGadget(#Gadget_BrowserAddress)
    ResizeGadget(#Gadget_BrowserAddress, 250, buttonY, winW - 320, 24)
  EndIf
  If IsGadget(#Gadget_BrowserGo)
    ResizeGadget(#Gadget_BrowserGo, winW - 60, buttonY, 50, 24)
  EndIf
  If IsGadget(#Gadget_BrowserPlay)
    ResizeGadget(#Gadget_BrowserPlay, 10, mediaY, 55, 24)
  EndIf
  If IsGadget(#Gadget_BrowserPause)
    ResizeGadget(#Gadget_BrowserPause, 70, mediaY, 55, 24)
  EndIf
  If IsGadget(#Gadget_BrowserStop)
    ResizeGadget(#Gadget_BrowserStop, 130, mediaY, 55, 24)
  EndIf
  If IsGadget(#Gadget_BrowserWeb)
    ResizeGadget(#Gadget_BrowserWeb, 0, topH, winW, winH - topH)
  EndIf
EndProcedure

Procedure ShowBrowserWindow()
  If IsWindow(#Window_Browser) = 0
    If OpenWindow(#Window_Browser, #PB_Ignore, #PB_Ignore, #BrowserWindowWidth, #BrowserWindowHeight, "Browser", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#Window_Main))
      ApplyWindowTheme(#Window_Browser)
      ButtonGadget(#Gadget_BrowserBack, 10, 10, 50, 24, "Back")
      ButtonGadget(#Gadget_BrowserForward, 65, 10, 50, 24, "Next")
      ButtonGadget(#Gadget_BrowserReload, 120, 10, 60, 24, "Reload")
      ButtonGadget(#Gadget_BrowserHome, 185, 10, 55, 24, "Home")
      StringGadget(#Gadget_BrowserAddress, 250, 10, 720, 24, #BrowserHomeUrl)
      ButtonGadget(#Gadget_BrowserGo, 980, 10, 50, 24, "Go")
      ButtonGadget(#Gadget_BrowserPlay, 10, 42, 55, 24, "Play")
      ButtonGadget(#Gadget_BrowserPause, 70, 42, 55, 24, "Pause")
      ButtonGadget(#Gadget_BrowserStop, 130, 42, 55, 24, "Stop")
      WebGadget(#Gadget_BrowserWeb, 0, 72, WindowWidth(#Window_Browser, #PB_Window_InnerCoordinate), WindowHeight(#Window_Browser, #PB_Window_InnerCoordinate) - 72, #BrowserHomeUrl, #PB_Web_Edge)
      ApplyGadgetTheme(#Gadget_BrowserAddress)
      GadgetToolTip(#Gadget_BrowserAddress, "Enter a URL or YouTube search text, then press Enter or Go")
      GadgetToolTip(#Gadget_BrowserPlay, "Play the current YouTube/video page")
      GadgetToolTip(#Gadget_BrowserPause, "Pause the current YouTube/video page")
      GadgetToolTip(#Gadget_BrowserStop, "Pause and rewind the current YouTube/video page")
      AddKeyboardShortcut(#Window_Browser, #PB_Shortcut_Return, #Command_BrowserNavigate)
      UpdateBrowserWindowLayout()
    EndIf
  EndIf

  If IsWindow(#Window_Browser)
    HideWindow(#Window_Browser, 0)
    SetActiveWindow(#Window_Browser)
  EndIf
EndProcedure

Procedure ToggleBrowserWindow()
  If IsWindow(#Window_Browser) And IsWindowVisible_(WindowID(#Window_Browser))
    HideWindow(#Window_Browser, 1)
  Else
    ShowBrowserWindow()
  EndIf
EndProcedure

Procedure UpdateThemePreviewText()
  If IsGadget(#Gadget_ThemePreview)
    SetGadgetText(#Gadget_ThemePreview, "Theme preview" + #CRLF$ + "Window, panel, text, and accent colors update open windows immediately.")
    ApplyGadgetTheme(#Gadget_ThemePreview)
  EndIf
EndProcedure

Procedure ApplyThemePreset(preset.i)
  State\themePreset = preset

  Select preset
    Case #Theme_Light
      State\themeWindowColor = RGB(245, 247, 250)
      State\themePanelColor = RGB(255, 255, 255)
      State\themeTextColor = RGB(32, 35, 39)
      State\themeAccentColor = RGB(0, 120, 215)

    Case #Theme_Dark
      State\themeWindowColor = RGB(32, 32, 36)
      State\themePanelColor = RGB(45, 45, 50)
      State\themeTextColor = RGB(235, 235, 235)
      State\themeAccentColor = RGB(86, 156, 214)

    Case #Theme_Blue
      State\themeWindowColor = RGB(225, 238, 252)
      State\themePanelColor = RGB(244, 249, 255)
      State\themeTextColor = RGB(21, 45, 75)
      State\themeAccentColor = RGB(0, 99, 177)

    Case #Theme_Forest
      State\themeWindowColor = RGB(226, 238, 225)
      State\themePanelColor = RGB(246, 250, 245)
      State\themeTextColor = RGB(31, 57, 35)
      State\themeAccentColor = RGB(47, 125, 64)

    Default
      State\themePreset = #Theme_System
      State\themeWindowColor = SystemColor(#COLOR_BTNFACE)
      State\themePanelColor = SystemColor(#COLOR_WINDOW)
      State\themeTextColor = SystemColor(#COLOR_WINDOWTEXT)
      State\themeAccentColor = SystemColor(#COLOR_HIGHLIGHT)
  EndSelect

  ApplyThemeToOpenWindows()
  UpdateThemePreviewText()
EndProcedure

Procedure PickThemeColor(colorKind.i)
  Protected currentColor.i
  Protected pickedColor.i

  Select colorKind
    Case 0
      currentColor = State\themeWindowColor
    Case 1
      currentColor = State\themePanelColor
    Case 2
      currentColor = State\themeTextColor
    Default
      currentColor = State\themeAccentColor
  EndSelect

  pickedColor = ColorRequester(currentColor)
  If pickedColor = -1
    ProcedureReturn
  EndIf

  State\themePreset = #Theme_Custom
  Select colorKind
    Case 0
      State\themeWindowColor = pickedColor
    Case 1
      State\themePanelColor = pickedColor
    Case 2
      State\themeTextColor = pickedColor
    Default
      State\themeAccentColor = pickedColor
  EndSelect

  ApplyThemeToOpenWindows()
  UpdateThemePreviewText()
EndProcedure

Procedure UpdateThemeWindowLayout()
  Protected winW.i
  Protected winH.i

  If IsWindow(#Window_Theme) = 0
    ProcedureReturn
  EndIf

  winW = WindowWidth(#Window_Theme, #PB_Window_InnerCoordinate)
  winH = WindowHeight(#Window_Theme, #PB_Window_InnerCoordinate)

  ResizeGadget(#Gadget_ThemeTitle, 10, 10, winW - 20, 20)
  ResizeGadget(#Gadget_ThemeSystem, 10, 40, 80, 28)
  ResizeGadget(#Gadget_ThemeLight, 95, 40, 80, 28)
  ResizeGadget(#Gadget_ThemeDark, 180, 40, 80, 28)
  ResizeGadget(#Gadget_ThemeBlue, 265, 40, 80, 28)
  ResizeGadget(#Gadget_ThemeForest, 350, 40, 90, 28)
  ResizeGadget(#Gadget_ThemeWindowColor, 10, 82, 105, 28)
  ResizeGadget(#Gadget_ThemePanelColor, 120, 82, 105, 28)
  ResizeGadget(#Gadget_ThemeTextColor, 230, 82, 105, 28)
  ResizeGadget(#Gadget_ThemeAccentColor, 340, 82, 105, 28)
  ResizeGadget(#Gadget_ThemePreview, 10, 125, winW - 20, winH - 170)
  ResizeGadget(#Gadget_ThemeClose, winW - 100, winH - 35, 90, 26)
EndProcedure

Procedure ShowThemeWindow()
  If IsWindow(#Window_Theme) = 0
    If OpenWindow(#Window_Theme, #PB_Ignore, #PB_Ignore, #ThemeWindowWidth, #ThemeWindowHeight, "Theme Settings", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#Window_Main))
      ApplyWindowTheme(#Window_Theme)
      TextGadget(#Gadget_ThemeTitle, 10, 10, 420, 20, "Choose a preset or customize colors:")
      ButtonGadget(#Gadget_ThemeSystem, 10, 40, 80, 28, "System")
      ButtonGadget(#Gadget_ThemeLight, 95, 40, 80, 28, "Light")
      ButtonGadget(#Gadget_ThemeDark, 180, 40, 80, 28, "Dark")
      ButtonGadget(#Gadget_ThemeBlue, 265, 40, 80, 28, "Blue")
      ButtonGadget(#Gadget_ThemeForest, 350, 40, 90, 28, "Forest")
      ButtonGadget(#Gadget_ThemeWindowColor, 10, 82, 105, 28, "Window")
      ButtonGadget(#Gadget_ThemePanelColor, 120, 82, 105, 28, "Panel")
      ButtonGadget(#Gadget_ThemeTextColor, 230, 82, 105, 28, "Text")
      ButtonGadget(#Gadget_ThemeAccentColor, 340, 82, 105, 28, "Accent")
      EditorGadget(#Gadget_ThemePreview, 10, 125, 430, 90, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
      ButtonGadget(#Gadget_ThemeClose, 350, 225, 90, 26, "Close")
      UpdateThemePreviewText()
      ApplyThemeToOpenWindows()
      UpdateThemeWindowLayout()
    EndIf
  EndIf

  If IsWindow(#Window_Theme)
    HideWindow(#Window_Theme, 0)
    SetActiveWindow(#Window_Theme)
  EndIf
EndProcedure

Procedure ToggleThemeWindow()
  If IsWindow(#Window_Theme) And IsWindowVisible_(WindowID(#Window_Theme))
    HideWindow(#Window_Theme, 1)
  Else
    ShowThemeWindow()
  EndIf
EndProcedure

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 386
; FirstLine = 346
; Folding = ----
; EnableXP
; DPIAware
; Executable = ..\HandyMPlayer.exe
