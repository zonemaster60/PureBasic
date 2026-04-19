;
; Handy Media Player
;

IncludeFile "HandyMPlayer_Inc.pb"
Global version.s = "v1.0.4.0"

EnableExplicit

UseJPEGImageDecoder()
UseJPEGImageEncoder()
UsePNGImageDecoder()
UsePNGImageEncoder()

IncludeFile "HandyMPlayer_State.pbi"
IncludeFile "HandyMPlayer_Utils.pbi"
IncludeFile "HandyMPlayer_LibraryPlaylist.pbi"
IncludeFile "HandyMPlayer_Windows.pbi"
IncludeFile "HandyMPlayer_MetadataAssets.pbi"
IncludeFile "HandyMPlayer_PlaybackLayout.pbi"

Global LastHighlightedMenuCommand.i = -1

Procedure ExitApplication(confirm.i = #True)
  If confirm = #False Or MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info) = #PB_MessageRequester_Yes
    CleanupResources()
    End
  EndIf
EndProcedure

Procedure UpdateHighlightedMenuItem(command.i)
  Select command
    Case #Command_Load, #Command_LoadFolder, #Command_LoadPlaylist, #Command_SavePlaylist, #Command_CloseMedia, #Command_Exit,
         #Command_PlayPause, #Command_Pause, #Command_PlayPrevious, #Command_PlayNext, #Command_PlaybackContinuous, #Command_PlaybackShuffle,
         #Command_PlaybackRepeat, #Command_Stop, #Command_SizeHalf, #Command_SizeDefault, #Command_SizeFit, #Command_SizeX1,
         #Command_SizeX15, #Command_SizeX2, #Command_SizeX3, #Command_SizeStepDown, #Command_SizeStepUp, #Command_VolumeFull,
         #Command_Volume75, #Command_VolumeHalf, #Command_Volume25, #Command_VolumeMute, #Command_VolumeUp, #Command_VolumeDown,
         #Command_BalanceCenter, #Command_BalanceSlightLeft, #Command_BalanceLeft, #Command_BalanceSlightRight, #Command_BalanceRight,
         #Command_ShowPlaylist, #Command_ShowLyrics, #Command_ShowArtwork, #Command_ShowVideo, #Command_Help, #Command_About
        If LastHighlightedMenuCommand >= 0
          SetMenuItemState(0, LastHighlightedMenuCommand, #False)
        EndIf
        SetMenuItemState(0, command, #True)
        LastHighlightedMenuCommand = command
  EndSelect
EndProcedure

Procedure Main()
  Protected now.i, st.q, curSec.q, totalSec.q, elapsedMS.q, windowMS.q, pos.i, mainStyle.i, currentMenuCommand.i
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
      MenuItem(#Command_CloseMedia, "Close Media")
      MenuBar()
      MenuItem(#Command_Exit, "Exit")
      MenuTitle("Play")
      MenuItem(#Command_PlayPause, "Play")
      MenuItem(#Command_Pause, "Pause")
      MenuItem(#Command_PlayPrevious, "Previous")
      MenuItem(#Command_PlayNext, "Next")
      MenuBar()
      MenuItem(#Command_PlaybackContinuous, "Continuous Playback")
      MenuItem(#Command_PlaybackShuffle, "Shuffle")
      MenuItem(#Command_PlaybackRepeat, "Repeat Current")
      MenuBar()
      MenuItem(#Command_Stop, "Stop")
      MenuBar()
      OpenSubMenu("Video")
        MenuItem(#Command_SizeHalf, "Size x0.5")
        MenuItem(#Command_SizeDefault, "Default")
        MenuItem(#Command_SizeFit, "Fit Window")
        MenuItem(#Command_SizeX1, "Size x1")
        MenuItem(#Command_SizeX15, "Size x1.5")
        MenuItem(#Command_SizeX2, "Size x2")
        MenuItem(#Command_SizeX3, "Size x3")
        MenuBar()
        MenuItem(#Command_SizeStepDown, "Smaller")
        MenuItem(#Command_SizeStepUp, "Larger")
      CloseSubMenu()
      OpenSubMenu("Volume")
        MenuItem(#Command_VolumeFull, "Full (100%)")
        MenuItem(#Command_Volume75, "High (75%)")
        MenuItem(#Command_VolumeHalf, "Half (50%)")
        MenuItem(#Command_Volume25, "Low (25%)")
        MenuItem(#Command_VolumeMute, "Mute (0%)")
        MenuBar()
        MenuItem(#Command_VolumeUp, "Volume Up")
        MenuItem(#Command_VolumeDown, "Volume Down")
      CloseSubMenu()
      OpenSubMenu("Balance")
        MenuItem(#Command_BalanceCenter, "Both (L+R)")
        MenuItem(#Command_BalanceSlightLeft, "Slight Left")
        MenuItem(#Command_BalanceLeft, "Left (L)")
        MenuItem(#Command_BalanceSlightRight, "Slight Right")
        MenuItem(#Command_BalanceRight, "Right (R)")
      CloseSubMenu()
      MenuTitle("View")
      MenuItem(#Command_ShowPlaylist, "Playlist")
      MenuItem(#Command_ShowLyrics, "Lyrics")
      MenuItem(#Command_ShowArtwork, "Artwork")
      MenuItem(#Command_ShowVideo, "Video")
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
  EditorGadget(#Gadget_LibraryInfo, 10, 206, 200, 56, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
  SetGadgetText(#Gadget_LibraryInfo, "No media loaded")
  ButtonGadget(#Gadget_LibraryPlay, 10, 268, 95, #SidebarButtonHeight, "Play")
  ButtonGadget(#Gadget_LibraryAdd, 115, 268, 95, #SidebarButtonHeight, "Add")
  CanvasGadget(#Gadget_SidebarSplitter, 300, 24, #SidebarSplitterWidth, 300)
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
    If CurrentPlaylistName = ""
      LoadPlaylistFromPath(LastPlaylistPath)
    EndIf
  EndIf

  If CurrentPlaylistName <> ""
    LoadNamedPlaylist(CurrentPlaylistName)
  EndIf

  LoadQueueStore()

  ShowPlaylistWindow()
  
  Repeat
    ; Use a small wait to avoid CPU spinning and reduce flicker.
    Select WaitWindowEvent(15)

      Case #PB_Event_Menu
        If EventWindow() = #Window_Main
          currentMenuCommand = EventMenu()
          UpdateHighlightedMenuItem(currentMenuCommand)
          Select currentMenuCommand
            
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

            Case #Command_CloseMedia
              ClearPlaylistItems()
         
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

            Case #Command_PlaybackContinuous
               State\continuousPlay = Bool(1 - State\continuousPlay)
               If State\continuousPlay
                 UpdatePlaybackStatus("Continuous playback enabled")
               Else
                 UpdatePlaybackStatus("Continuous playback disabled")
               EndIf

            Case #Command_PlaybackShuffle
               State\shufflePlay = Bool(1 - State\shufflePlay)
               If State\shufflePlay
                 State\repeatPlay = #False
               EndIf
               If State\shufflePlay
                 UpdatePlaybackStatus("Shuffle enabled")
               Else
                 UpdatePlaybackStatus("Shuffle disabled")
               EndIf

            Case #Command_PlaybackRepeat
               State\repeatPlay = Bool(1 - State\repeatPlay)
               If State\repeatPlay
                 State\shufflePlay = #False
               EndIf
               If State\repeatPlay
                 UpdatePlaybackStatus("Repeat enabled")
               Else
                 UpdatePlaybackStatus("Repeat disabled")
               EndIf
            
           Case #Command_Pause ; Pause
             PausePlayback()
            
          ; ---------------- Volume -------------------
            
            Case #Command_VolumeFull ; Full 100%
               State\volume = 100
               ApplyAudioSettings()

            Case #Command_Volume75
               State\volume = 75
               ApplyAudioSettings()

            Case #Command_VolumeHalf ; Half 50%
               State\volume = 50
               ApplyAudioSettings()

            Case #Command_Volume25
               State\volume = 25
               ApplyAudioSettings()

             Case #Command_VolumeMute ; Mute 0%
               If State\volume > 0
                 State\volume = 0
               Else
                 State\volume = 100
               EndIf
               ApplyAudioSettings()

            Case #Command_VolumeUp
               State\volume + 10
               If State\volume > 100 : State\volume = 100 : EndIf
               ApplyAudioSettings()

            Case #Command_VolumeDown
               State\volume - 10
               If State\volume < 0 : State\volume = 0 : EndIf
               ApplyAudioSettings()

            
           ; ---------------- Balance -------------------

            Case #Command_BalanceCenter ; Both (L+R)
               State\balance = 0
               ApplyAudioSettings()

            Case #Command_BalanceSlightLeft
               State\balance = -50
               ApplyAudioSettings()

            Case #Command_BalanceLeft ; Left (L)
               State\balance = -100
               ApplyAudioSettings()

            Case #Command_BalanceSlightRight
               State\balance = 50
               ApplyAudioSettings()

            Case #Command_BalanceRight ; Right (R)
               State\balance = 100
               ApplyAudioSettings()


           ; ---------------------------------------------
            
            Case #Command_Help ; Help
               ShowHelpWindow()

            Case #Command_ShowPlaylist
               TogglePlaylistWindow()

            Case #Command_ShowLyrics
               ToggleLyricsWindow()

            Case #Command_ShowArtwork
               ToggleArtworkPreviewWindow()

            Case #Command_ShowVideo
               ToggleVideoWindow()
              
          ; ------------------ Size ---------------------
 
            Case #Command_SizeHalf
              If State\movieLoaded And State\movieHasVideo
                 ResizeMainForVideo(MovieWidth(0) / 2, MovieHeight(0) / 2)
                 UpdateLayout()
              EndIf

            Case #Command_SizeDefault ; Default (50%)
              If State\movieLoaded And State\movieHasVideo
                 ResizeMainForVideo(State\targetW, State\targetH)
                 UpdateLayout()
              EndIf

            Case #Command_SizeFit
              If State\movieLoaded And State\movieHasVideo And IsWindow(#Window_Video)
                 ResizeMainForVideo(WindowWidth(#Window_Video, #PB_Window_InnerCoordinate), WindowHeight(#Window_Video, #PB_Window_InnerCoordinate))
                 UpdateLayout()
              EndIf

            Case #Command_SizeX1 ; Size x1 (100%)
              If State\movieLoaded And State\movieHasVideo
                 ResizeMainForVideo(MovieWidth(0), MovieHeight(0))
                 UpdateLayout()
              EndIf

            Case #Command_SizeX15
              If State\movieLoaded And State\movieHasVideo
                 ResizeMainForVideo(MovieWidth(0) * 3 / 2, MovieHeight(0) * 3 / 2)
                 UpdateLayout()
              EndIf

            Case #Command_SizeX2 ; Size x2 (200%)
              If State\movieLoaded And State\movieHasVideo
                 ResizeMainForVideo(MovieWidth(0) * 2, MovieHeight(0) * 2)
                 UpdateLayout()
              EndIf

            Case #Command_SizeX3
              If State\movieLoaded And State\movieHasVideo
                 ResizeMainForVideo(MovieWidth(0) * 3, MovieHeight(0) * 3)
                 UpdateLayout()
              EndIf

            Case #Command_SizeStepDown
              If State\movieLoaded And State\movieHasVideo And IsWindow(#Window_Video)
                 ResizeMainForVideo(WindowWidth(#Window_Video, #PB_Window_InnerCoordinate) * 9 / 10, WindowHeight(#Window_Video, #PB_Window_InnerCoordinate) * 9 / 10)
                 UpdateLayout()
              EndIf

            Case #Command_SizeStepUp
              If State\movieLoaded And State\movieHasVideo And IsWindow(#Window_Video)
                 ResizeMainForVideo(WindowWidth(#Window_Video, #PB_Window_InnerCoordinate) * 11 / 10, WindowHeight(#Window_Video, #PB_Window_InnerCoordinate) * 11 / 10)
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
        ElseIf EventWindow() = #Window_Playlist
          HideWindow(#Window_Playlist, 1)
        ElseIf EventWindow() = #Window_Video
          HideWindow(#Window_Video, 1)
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
        ElseIf EventWindow() = #Window_Video And State\movieHasVideo And IsMovie(0)
          If IsGadget(#Gadget_VideoPlay)
            ResizeGadget(#Gadget_VideoPlay, 10, 10, 55, 24)
          EndIf
          If IsGadget(#Gadget_VideoPause)
            ResizeGadget(#Gadget_VideoPause, 70, 10, 55, 24)
          EndIf
          If IsGadget(#Gadget_VideoStop)
            ResizeGadget(#Gadget_VideoStop, 130, 10, 55, 24)
          EndIf
          If IsGadget(#Gadget_VideoHost)
            ResizeGadget(#Gadget_VideoHost, 0, 40, WindowWidth(#Window_Video, #PB_Window_InnerCoordinate), WindowHeight(#Window_Video, #PB_Window_InnerCoordinate) - 40)
            ResizeMovie(0, 0, 0, GadgetWidth(#Gadget_VideoHost), GadgetHeight(#Gadget_VideoHost))
          EndIf
        ElseIf EventWindow() = #Window_Help And IsGadget(#Gadget_HelpEditor)
          ResizeGadget(#Gadget_HelpEditor, 0, 0, WindowWidth(#Window_Help, #PB_Window_InnerCoordinate), WindowHeight(#Window_Help, #PB_Window_InnerCoordinate))
        ElseIf EventWindow() = #Window_Playlist
          UpdatePlaylistWindowLayout()
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
        ElseIf EventWindow() = #Window_Playlist And EventGadget() = #Gadget_PlaylistPlay
          PlaySelectedPlaylistItem()
        ElseIf EventWindow() = #Window_Playlist And EventGadget() = #Gadget_PlaylistShuffle
          State\shufflePlay = Bool(1 - State\shufflePlay)
          If State\shufflePlay
            State\repeatPlay = #False
            UpdatePlaybackStatus("Playlist random enabled")
          Else
            UpdatePlaybackStatus("Playlist random disabled")
          EndIf
        ElseIf EventWindow() = #Window_Playlist And EventGadget() = #Gadget_PlaylistPause
          PausePlayback()
        ElseIf EventWindow() = #Window_Playlist And EventGadget() = #Gadget_PlaylistStop
          StopPlayback()
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
        ElseIf EventWindow() = #Window_Video And EventGadget() = #Gadget_VideoPlay
          TogglePlayback()
        ElseIf EventWindow() = #Window_Video And EventGadget() = #Gadget_VideoPause
          PausePlayback()
        ElseIf EventWindow() = #Window_Video And EventGadget() = #Gadget_VideoStop
          StopPlayback()
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
        ElseIf EventWindow() = #Window_Playlist And EventGadget() = #Gadget_Playlist And EventType() = #PB_EventType_LeftDoubleClick
          PlaySelectedPlaylistItem()
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

          If State\movieLoaded
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
                    If ListSize(QueueTracks()) > 0 Or State\continuousPlay Or State\repeatPlay Or State\shufflePlay
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
; CursorPosition = 5
; FirstLine = 2
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyMPlayer.ico
; Executable = ..\HandyMPlayer.exe
; Debugger = IDE
; IncludeVersionInfo
; VersionField0 = 1,0,4,0
; VersionField1 = 1,0,4,0
; VersionField2 = ZoneSoft
; VersionField3 = HandyMPlayer
; VersionField4 = 1.0.4.0
; VersionField5 = 1.0.4.0
; VersionField6 = A Handy Compact Audio/Video Player
; VersionField7 = HandyMPlayer
; VersionField8 = HandyMPlayer.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP
