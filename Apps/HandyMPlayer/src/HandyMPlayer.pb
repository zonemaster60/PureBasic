;
; Handy Media Player
;

IncludeFile "HandyMPlayer_Inc.pb"

EnableExplicit

Global isUserSeeking.i = 0

; Global variables moved to State structure or handled by Include
Global version.s = "v1.0.2.6"
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
  targetW.i
  targetH.i
EndStructure

Global State.PlayerState

Declare EnsureVideoHostWindow()
Declare KeepStatusBarOnTop()
Declare UpdateLayout()
Declare.s FormatTime(seconds.q)

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
  State\targetW = #WindowWidth + 50
  State\targetH = #WindowHeight + 25

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

  If State\fileName <> ""
    message + " <> '" + State\fileName + "'"
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
    StatusBarText(0, 0, State\fileName + "  " + FormatTime(elapsedMS / 1000) + "/" + FormatTime(State\audioTotalMS / 1000), #PB_StatusBar_Center)
  ElseIf State\fileName <> ""
    StatusBarText(0, 0, State\fileName + "  " + FormatTime(elapsedMS / 1000), #PB_StatusBar_Center)
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
    ClosePreferences()
  Else
    State\volume = 100
    State\balance = 0
    State\winX = -1
    State\winY = -1
  EndIf
EndProcedure

Procedure CleanupResources()
  SaveSettings()
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

  ; Reserve room for toolbar + trackbar + status bar.
  Protected pbH.i = DesktopScaledY(#ProgressBarHeight + 6)

  Protected innerW.i = videoW
  Protected innerH.i = toolH + DesktopScaledY(#LayoutPadding) + pbH + DesktopScaledY(#LayoutPadding) + videoH + statusH

  If innerW < DesktopScaledX(#WindowWidth) : innerW = DesktopScaledX(#WindowWidth) : EndIf
  If innerH < DesktopScaledY(#WindowHeight + 25) : innerH = DesktopScaledY(#WindowHeight + 25) : EndIf

  ; ResizeWindow uses frame coordinates, so convert inner->frame delta.
  Protected frameDeltaW.i = WindowWidth(#Window_Main, #PB_Window_FrameCoordinate) - WindowWidth(#Window_Main, #PB_Window_InnerCoordinate)
  Protected frameDeltaH.i = WindowHeight(#Window_Main, #PB_Window_FrameCoordinate) - WindowHeight(#Window_Main, #PB_Window_InnerCoordinate)

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

  Protected pbX.i = DesktopScaledX(#ProgressBarLeft)
  Protected pbY.i = toolH + DesktopScaledY(#LayoutPadding)
  Protected pbW.i = winW - DesktopScaledX(#ProgressBarLeft + #ProgressBarRightMargin)
  Protected pbH.i = DesktopScaledY(#ProgressBarHeight + 6)
  If pbW < 10 : pbW = 10 : EndIf

  If IsGadget(#Gadget_Progress)
    ; Avoid resizing if dimensions didn't change to reduce flicker
    If GadgetWidth(#Gadget_Progress) <> pbW Or GadgetHeight(#Gadget_Progress) <> pbH
      ResizeGadget(#Gadget_Progress, pbX, pbY, pbW, pbH)
    EndIf
  EndIf

  Protected videoTop.i = pbY + pbH + DesktopScaledY(#LayoutPadding)
  Protected videoH.i = winH - videoTop - statusH
  If videoH < 0 : videoH = 0 : EndIf

  EnsureVideoHostWindow()
  If IsWindow(#Window_Video)
    If State\movieHasVideo
      HideWindow(#Window_Video, 0)
      ResizeWindow(#Window_Video, 0, videoTop, winW, videoH)
      SetWindowPos_(WindowID(#Window_Video), 0, 0, 0, 0, 0, #SWP_NOMOVE | #SWP_NOSIZE | #SWP_NOZORDER | #SWP_FRAMECHANGED)
    Else
      HideWindow(#Window_Video, 1)
      ResizeWindow(#Window_Video, 0, videoTop, winW, 0)
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
      StatusBarText(0, 0, "Audio '" + State\fileName + "' loaded.", #PB_StatusBar_Center)
      GadgetToolTip(#Gadget_Progress, "Audio '" + State\fileName + "' loaded.")
    EndIf

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

  LoadSettings()
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
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_S, #Command_Stop)

  
  ; Improve child clipping (helps keep status bar visible).
  mainStyle.i = GetWindowLongPtr_(WindowID(#Window_Main), #GWL_STYLE)
  mainStyle = mainStyle | #WS_CLIPCHILDREN | #WS_CLIPSIBLINGS
  SetWindowLongPtr_(WindowID(#Window_Main), #GWL_STYLE, mainStyle)

  ; create the program menu
  If CreateMenu(0, WindowID(#Window_Main))
      MenuTitle("File")
      MenuItem(#Command_Load, "Load")
      MenuBar()
      MenuItem(#Command_Exit, "Exit")
      MenuTitle("Play")
      MenuItem(#Command_PlayPause, "Play")
      MenuItem(#Command_Pause, "Pause")
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
  TrackBarGadget(#Gadget_Progress, 10, 30, 395, #ProgressBarHeight + 6, 0, #ProgressScaleMax)
  SetProgressPosition(0)
  isUserSeeking = 1

  ; Dragging thumb triggers seek (PB default event)
  BindGadgetEvent(#Gadget_Progress, @ProgressBarSeek())
  ; Clicking anywhere on the bar jumps there then seeks
  BindGadgetEvent(#Gadget_Progress, @ProgressBarClickToSeek(), #PB_EventType_LeftClick)

  ; Create a dedicated child window for video rendering.
  EnsureVideoHostWindow()

  UpdateLayout()
  
  Repeat
    ; Use a small wait to avoid CPU spinning and reduce flicker.
    Select WaitWindowEvent(15)

      Case #PB_Event_Menu
        If EventWindow() = #Window_Main
          Select EventMenu()
            
            Case #Command_Load ; Load
               LoadFile(OpenFileRequester("Load a file", "",
                                            "Media files|*.asf;*.avi;*.flac;*.mid;*.mp3;*.mp4;*.mpg;*.wav;*.wmv|All Files|*.*", 0))
        
          Case #Command_Exit ; Exit
            ExitApplication()
            
          ; ---------------- Movie controls -------------------
            
           Case #Command_PlayPause ; Play/Pause Toggle (Space/Button)
             TogglePlayback()
            
           Case #Command_Stop ; Stop
             StopPlayback()
            
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
              MessageRequester("Help", "There will be some help, eventually!", #PB_MessageRequester_Info)
            
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
          LoadFile(EventDropFiles())
        EndIf
      
      Case #PB_Event_CloseWindow
        If EventWindow() = #Window_Main
          ExitApplication()
        EndIf
        
      Case #PB_Event_SizeWindow
        If EventWindow() = #Window_Main
          UpdateLayout()
          KeepStatusBarOnTop()
        EndIf
        
      Case 0
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

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 11
; Folding = -----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyMPlayer.ico
; Executable = ..\HandyMPlayer.exe
; Debugger = IDE
; IncludeVersionInfo
; VersionField0 = 1,0,2,6
; VersionField1 = 1,0,2,6
; VersionField2 = ZoneSoft
; VersionField3 = HandyMPlayer
; VersionField4 = 1.0.2.6
; VersionField5 = 1.0.2.6
; VersionField6 = A Handy Compact Media Player
; VersionField7 = HandyMPlayer
; VersionField8 = HandyMPlayer.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP