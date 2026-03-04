;
; Handy Media Player
;

IncludeFile "HandyMPlayer_Inc.pb"

EnableExplicit

Global isUserSeeking.i = 0

; Global variables moved to State structure or handled by Include
Global version.s = "v1.0.2.5"
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
  movieState.i ; 0:stopped/init, 1:playing, 2:paused, 3:stopped
  movieLengthFrames.q
  movieFPS_x1000.q
  movieHasVideo.i
  
  audioStartMS.q
  audioPausedElapsedMS.q
  audioTotalMS.q
  audioTotalFrames.q
  audioProgressMaxMS.q
  
  previousMovieStatus.q
  lastProgressUpdate.i
  currentVolume.i
  currentBalance.i
  fileName.s
  targetW.i
  targetH.i
EndStructure

Global State.PlayerState

Procedure SaveSettings()
  If CreatePreferences(AppPath + "HandyMPlayer.ini")
    PreferenceGroup("Settings")
    WritePreferenceInteger("Volume", State\volume)
    WritePreferenceInteger("Balance", State\balance)
    WritePreferenceInteger("WinX", WindowX(#Window_Main))
    WritePreferenceInteger("WinY", WindowY(#Window_Main))
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
  If AboutIcon : DestroyIcon_(AboutIcon) : EndIf
  If LoadIcon : DestroyIcon_(LoadIcon) : EndIf
  If PauseIcon : DestroyIcon_(PauseIcon) : EndIf
  If PlayIcon : DestroyIcon_(PlayIcon) : EndIf
  If StopIcon : DestroyIcon_(StopIcon) : EndIf
  If hMutex
    ReleaseMutex_(hMutex)
    CloseHandle_(hMutex)
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

    ; Encourage compositor to reduce flicker.
    Protected exstyle.i = GetWindowLongPtr_(hVideo, #GWL_EXSTYLE)
    exstyle = exstyle | #WS_EX_COMPOSITED
    SetWindowLongPtr_(hVideo, #GWL_EXSTYLE, exstyle)

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
  If State\movieState <> 1 And State\movieState <> 2
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
          MovieSeek(0, seekTarget)
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

  State\movieLoaded = 0
  State\movieState = 0
  State\audioStartMS = 0
  State\audioPausedElapsedMS = 0
  State\audioTotalMS = 0
  State\audioProgressMaxMS = 0

  If LoadMovie(0, path)
    State\movieHasVideo = Bool(MovieHeight(0) > 0)

    State\targetW = MovieWidth(0) / 2
    State\targetH = MovieHeight(0) / 2

    If State\movieHasVideo = 0
      State\targetW = #WindowWidth + 50
      State\targetH = #WindowHeight + 25
    EndIf

    SetGadgetState(#Gadget_Progress, 0)
    State\moviePath = path
    State\fileName = GetFilePart(path)

    State\movieLoaded = 1
    State\movieState = 0
    State\previousMovieStatus = 0
    State\lastProgressUpdate = ElapsedMilliseconds()

    State\movieLengthFrames = MovieLength(0)
    State\movieFPS_x1000 = 0
    If State\movieHasVideo
      State\movieFPS_x1000 = MovieInfo(0, 0)
    EndIf

    State\audioTotalMS = 0
    State\audioProgressMaxMS = 0
    If State\movieHasVideo = 0
      State\audioTotalMS = MovieLengthMS(0)
      State\audioTotalFrames = State\movieLengthFrames
      If State\audioTotalFrames <= 0 And State\audioTotalMS > 0
        State\audioTotalFrames = State\audioTotalMS
      EndIf
      State\audioStartMS = 0
      State\audioPausedElapsedMS = 0
      If State\audioTotalMS > 0
        State\audioProgressMaxMS = State\audioTotalMS
      Else
        State\audioProgressMaxMS = 0
      EndIf
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
    StatusBarText(0, 0, "Can't load the file '" + GetFilePart(path) + "' ", #PB_StatusBar_Center)
  EndIf
EndProcedure

Procedure Exit()
  If MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info) = #PB_MessageRequester_Yes
    CleanupResources()
    End
  EndIf
EndProcedure

; Initialize Resources
LoadSettings()

hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

iconlib = AppPath + "files\" + #APP_NAME + ".icl"
AboutIcon = ExtractIcon_(0, iconlib, 0)
LoadIcon  = ExtractIcon_(0, iconlib, 1)
PauseIcon = ExtractIcon_(0, iconlib, 2)
PlayIcon  = ExtractIcon_(0, iconlib, 3)
StopIcon  = ExtractIcon_(0, iconlib, 4)

State\currentVolume = -1
State\currentBalance = -999
State\lastProgressUpdate = ElapsedMilliseconds()

; temp vars (main loop) - can't use Protected outside procedures
Global now.i, st.q, curSec.q, totalSec.q, elapsedMS.q, seekTarget.q, pbMax.q, windowMS.q, pos.i, mainStyle.i

If InitMovie() = 0
  MessageRequester("Error", "Can't initialize video playback!", #PB_MessageRequester_Error)
  End
EndIf

If OpenWindow(#Window_Main, State\winX, State\winY, #WindowWidth+50, #WindowHeight+25, #APP_NAME + " - " +
              version, #PB_Window_Invisible | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_ScreenCentered)
  
  If State\winX = -1
    ; Center if no previous position
  Else
    ResizeWindow(#Window_Main, State\winX, State\winY, #PB_Ignore, #PB_Ignore)
  EndIf

  EnableWindowDrop(#Window_Main, #PB_Drop_Files, #PB_Drag_Copy)

  ; Add Keyboard Shortcuts
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_Space, 2)  ; Play/Pause (mapped to Play for now)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_M, 8)      ; Mute (Case 8)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_Escape, 1) ; Exit (Case 1)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_L, 0)      ; Load (Case 0)
  AddKeyboardShortcut(#Window_Main, #PB_Shortcut_S, 3)      ; Stop (Case 3)

  
  ; Improve child clipping (helps keep status bar visible).
  mainStyle.i = GetWindowLongPtr_(WindowID(#Window_Main), #GWL_STYLE)
  mainStyle = mainStyle | #WS_CLIPCHILDREN | #WS_CLIPSIBLINGS
  SetWindowLongPtr_(WindowID(#Window_Main), #GWL_STYLE, mainStyle)

  ; create the program menu
  If CreateMenu(0, WindowID(#Window_Main))
      MenuTitle("File")
      MenuItem(0, "Load")
      MenuBar()
      MenuItem(1, "Exit")     
      MenuTitle("Play")
      MenuItem(2, "Play")
      MenuItem(4, "Pause")
      MenuBar()
      MenuItem(3, "Stop")
      MenuBar()
      OpenSubMenu("Video")
        MenuItem(13, "Default")
        MenuItem(14, "Size x1")
        MenuItem(15, "Size x2")
      CloseSubMenu()
      OpenSubMenu("Volume")
        MenuItem(6, "Full (100%)")
        MenuItem(7, "Half (50%)")
        MenuItem(8, "Mute (0%)")
      CloseSubMenu()
      OpenSubMenu("Balance")
        MenuItem( 9, "Both (L+R)")
        MenuItem(10, "Left (L)")
        MenuItem(11, "Right (R)")
      CloseSubMenu()
      MenuTitle("Help")
      MenuItem(12, "Help")
      MenuItem(16, "About")
    EndIf
    
  ; create the toolbar
  If CreateToolBar(0, WindowID(#Window_Main))
    ToolBarImageButton(0, LoadIcon)
    ToolBarSeparator()
    ToolBarImageButton(2, PlayIcon)
    ToolBarSeparator()
    ToolBarImageButton(4, PauseIcon)
    ToolBarImageButton(3, StopIcon)
    ToolBarSeparator()
    ToolBarImageButton(16, AboutIcon)
  EndIf
  
  If CreateStatusBar(0, WindowID(#Window_Main))
    AddStatusBarField(8192) ; Maximum value of 8192 pixels, to have a field which take all the window width !
    StatusBarText(0, 0, "-=[Welcome to " + #APP_NAME + "!]=-", #PB_StatusBar_Center)
  EndIf
  
  HideWindow(#Window_Main, 0) ; Show the window once all toolbar/menus has been created...

  ; Pre-create gadgets once (recreating them causes flicker)
  TrackBarGadget(#Gadget_Progress, 10, 30, 395, #ProgressBarHeight + 6, 0, #ProgressScaleMax)
  SetGadgetState(#Gadget_Progress, 0)
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
            
            Case 0 ; Load
               LoadFile(OpenFileRequester("Load a file", "",
                                            "Media files|*.asf;*.avi;*.flac;*.mid;*.mp3;*.mp4;*.mpg;*.wav;*.wmv|All Files|*.*", 0))
        
          Case 1 ; Exit
            Exit()
            
          ; ---------------- Movie controls -------------------
            
           Case 2 ; Play/Pause Toggle (Space/Button)
                 If State\movieLoaded
                   If State\movieState = 1 ; If playing, Pause
                      PauseMovie(0)
                      State\movieState = 2 ; Paused
                      StatusBarText(0, 0, "Paused <> '" + State\fileName + "'", #PB_StatusBar_Center)
                      GadgetToolTip(#Gadget_Progress, "Paused <> '" + State\fileName + "'")
                      If State\movieHasVideo = 0 And State\audioStartMS > 0
                        State\audioPausedElapsedMS = ElapsedMilliseconds() - State\audioStartMS
                      EndIf
                   ElseIf State\movieState = 2 ; If paused, Resume
                      ResumeMovie(0)
                      If State\movieHasVideo = 0
                        State\audioStartMS = ElapsedMilliseconds() - State\audioPausedElapsedMS
                      EndIf
                      State\movieState = 1
                   Else ; If stopped or init, Play
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
                      State\movieState = 1 ; Playing
                   EndIf
                  
                  MovieAudio(0, State\volume, State\balance)
                  State\currentVolume = State\volume
                  State\currentBalance = State\balance
                  If State\movieState = 1
                    GadgetToolTip(#Gadget_Progress, "Playing <> '" + State\fileName + "'")
                  EndIf
                EndIf
            
           Case 3 ; Stop
               If State\movieLoaded And State\movieState = 1
                 StopMovie(0)
                 State\movieState = 3 ; Stopped
                 StatusBarText(0, 0, "Stopped <> '" + State\fileName + "'", #PB_StatusBar_Center)
                 GadgetToolTip(#Gadget_Progress, "Stopped <> '" + State\fileName + "'")
                 If State\movieHasVideo
                   UpdateLayout()
                 Else
                   State\audioStartMS = 0
                   State\audioPausedElapsedMS = 0
                   SetGadgetState(#Gadget_Progress, 0)
                   If State\audioTotalMS > 0
                     StatusBarText(0, 0, State\fileName + "  00:00/" + FormatTime(State\audioTotalMS / 1000), #PB_StatusBar_Center)
                   EndIf
                 EndIf
               EndIf
            
           Case 4 ; Pause
              If State\movieLoaded And State\movieState = 1
                PauseMovie(0)
                State\movieState = 2 ; Paused
                StatusBarText(0, 0, "Paused <> '" + State\fileName + "'", #PB_StatusBar_Center)
                GadgetToolTip(#Gadget_Progress, "Paused <> '" + State\fileName + "'")
                If State\movieHasVideo = 0 And State\audioStartMS > 0
                  State\audioPausedElapsedMS = ElapsedMilliseconds() - State\audioStartMS
                EndIf
              EndIf
            
          ; ---------------- Volume -------------------
            
           Case 6 ; Full 100%
             State\volume = 100

           Case 7 ; Half 50%
             State\volume = 50

            Case 8 ; Mute 0%
             If State\volume > 0
               State\volume = 0
             Else
               State\volume = 100
             EndIf

            
           ; ---------------- Balance -------------------

           Case 9 ; Both (L+R)
             State\balance = 0

           Case 10 ; Left (L)
             State\balance = -100

           Case 11 ; Right (R)
             State\balance = 100


           ; ---------------------------------------------
            
           Case 12 ; Help
             MessageRequester("Help", "There will be some help, eventually!", #PB_MessageRequester_Info)
            
          ; ------------------ Size ---------------------
 
           Case 13 ; Default (50%)
             If State\movieLoaded And State\movieHasVideo
                ResizeMainForVideo(State\targetW, State\targetH)
                UpdateLayout()
             EndIf

           Case 14 ; Size x1 (100%)
             If State\movieLoaded And State\movieHasVideo
                ResizeMainForVideo(MovieWidth(0), MovieHeight(0))
                UpdateLayout()
             EndIf

           Case 15 ; Size x2 (200%)
             If State\movieLoaded And State\movieHasVideo
                ResizeMainForVideo(MovieWidth(0) * 2, MovieHeight(0) * 2)
                UpdateLayout()
             EndIf
         
          ; ---------------- Misc -------------------
            
            Case 16 ; About
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

        If State\movieLoaded

           If State\currentVolume <> State\volume Or State\currentBalance <> State\balance
             MovieAudio(0, State\volume, State\balance)
             State\currentVolume = State\volume
             State\currentBalance = State\balance
           EndIf
         EndIf
     
      Case #PB_Event_CloseWindow
        If EventWindow() = #Window_Main
          Exit()
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

            If State\movieState = 1 And now - State\lastProgressUpdate >= 250
              If State\movieHasVideo
                If st > 0
                  If State\movieLengthFrames > 0 And st > State\movieLengthFrames
                    st = State\movieLengthFrames
                  EndIf
                    If State\movieLengthFrames > 0
                      isUserSeeking = 0
                      SetGadgetState(#Gadget_Progress, (st * #ProgressScaleMax) / State\movieLengthFrames)
                      isUserSeeking = 1
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

                    isUserSeeking = 0
                    SetGadgetState(#Gadget_Progress, (st * #ProgressScaleMax) / State\audioTotalFrames)
                    isUserSeeking = 1

                    If State\audioTotalMS > 0
                      ; If audioTotalFrames was forced to ms, st is already ms.
                      If State\audioTotalFrames = State\audioTotalMS
                        elapsedMS = st
                      Else
                        elapsedMS = (State\audioTotalMS * st) / State\audioTotalFrames
                      EndIf
                      StatusBarText(0, 0, State\fileName + "  " + FormatTime(elapsedMS / 1000) + "/" + FormatTime(State\audioTotalMS / 1000), #PB_StatusBar_Center)
                    Else
                      StatusBarText(0, 0, State\fileName, #PB_StatusBar_Center)
                    EndIf
                  Else
                   ; If even MovieLength() isn't available, fall back to a moving indicator.
                   If State\audioStartMS > 0
                     elapsedMS = now - State\audioStartMS
                     windowMS = 600000
                     pos = (elapsedMS % windowMS) * #ProgressScaleMax / windowMS
                     isUserSeeking = 0
                     SetGadgetState(#Gadget_Progress, pos)
                     isUserSeeking = 1
                     StatusBarText(0, 0, State\fileName + "  " + FormatTime(elapsedMS / 1000), #PB_StatusBar_Center)
                   EndIf
                 EndIf

              EndIf
              State\lastProgressUpdate = now
            EndIf

            If st <> State\previousMovieStatus
              Select st
                Case -1
                  StatusBarText(0, 0, "Paused <> '" + State\fileName + "'", #PB_StatusBar_Center)
                  GadgetToolTip(#Gadget_Progress, "Paused <> '" + State\fileName + "'")

                Case 0
                  StatusBarText(0, 0, "Stopped <> '" + State\fileName + "'", #PB_StatusBar_Center)
                  GadgetToolTip(#Gadget_Progress, "Stopped <> '" + State\fileName + "'")
                  If State\movieState = 1
                    State\movieState = 3
                  EndIf

                Default
                  If State\movieLengthFrames > 0
                    If st > State\movieLengthFrames
                      st = State\movieLengthFrames
                    EndIf
                    isUserSeeking = 0
                    SetGadgetState(#Gadget_Progress, (st * #ProgressScaleMax) / State\movieLengthFrames)
                    isUserSeeking = 1
                  EndIf
              EndSelect

              State\previousMovieStatus = st
            EndIf
          EndIf

     EndSelect
  ForEver
EndIf
End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 11
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyMPlayer.ico
; Executable = ..\HandyMPlayer.exe
; Debugger = IDE
; IncludeVersionInfo
; VersionField0 = 1,0,2,5
; VersionField1 = 1,0,2,5
; VersionField2 = ZoneSoft
; VersionField3 = HandyMPlayer
; VersionField4 = 1.0.2.5
; VersionField5 = 1.0.2.5
; VersionField6 = A Handy Compact Media Player
; VersionField7 = HandyMPlayer
; VersionField8 = HandyMPlayer.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP