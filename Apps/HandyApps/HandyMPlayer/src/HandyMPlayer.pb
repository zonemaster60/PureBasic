;
; Handy Media Player
;

EnableExplicit

#WindowWidth = 365
#WindowHeight = 70
#APP_NAME = "HandyMPlayer"
#EMAIL_NAME = "zonemaster60@gmail.com"

#Window_Main = 0
#Window_Video = 1

#Gadget_Progress = 0
Global isUserSeeking.i = 0

#LayoutPadding = 5
#ProgressBarHeight = 15
#ProgressBarLeft = 10
#ProgressBarRightMargin = 10

#ProgressScaleMax = 10000

Structure WinPOINT
  x.l
  y.l
EndStructure

Structure WinRECT
  left.l
  top.l
  right.l
  bottom.l
EndStructure

Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Global iconlib.s = AppPath + "files\" + #APP_NAME + ".icl"
Global AboutIcon.i = ExtractIcon_(0, iconlib, 0)
Global LoadIcon.i  = ExtractIcon_(0, iconlib, 1)
Global PauseIcon.i = ExtractIcon_(0, iconlib, 2)
Global PlayIcon.i  = ExtractIcon_(0, iconlib, 3)
Global StopIcon.i  = ExtractIcon_(0, iconlib, 4)

Global volume.i = 100
Global balance.i = 0
Global movieLoaded.i = 0
Global moviePath.s
Global movieState.i = 0
Global movieLengthFrames.q = 0
Global movieFPS_x1000.q = 0
Global movieHasVideo.i = 0

; Audio-only progress tracking
Global audioStartMS.q = 0
Global audioPausedElapsedMS.q = 0
Global audioTotalMS.q = 0
Global audioTotalFrames.q = 0
Global audioProgressMaxMS.q = 0


#GWL_STYLE = -16
#WS_CHILD = $40000000
#WS_CLIPCHILDREN = $02000000
#WS_CLIPSIBLINGS = $04000000
#WS_EX_COMPOSITED = $02000000
#GWL_EXSTYLE = -20

#SWP_NOMOVE = $0002
#SWP_NOSIZE = $0001
#SWP_NOZORDER = $0004
#SWP_FRAMECHANGED = $0020
#HWND_TOP = 0
#HWND_BOTTOM = 1
#SWP_NOACTIVATE = $0010

Global previousMovieStatus.q = 0
Global lastProgressUpdate.i = ElapsedMilliseconds()
Global currentVolume.i = -1
Global currentBalance.i = -999
Global fileName.s = ""
Global targetW.i = 0
Global targetH.i = 0

; temp vars (main loop) - can't use Protected outside procedures
Global now.i
Global st.q
Global curSec.q
Global totalSec.q
Global elapsedMS.q
Global seekTarget.q
Global pbMax.q
Global windowMS.q
Global pos.i
Global mainStyle.i

Global vers$ = "1.0.2.4 (20252312)"

Procedure Exit()
  Protected req.i
  req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If req = #PB_MessageRequester_Yes
    End
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
  Protected pbH.i = #ProgressBarHeight + 6

  Protected innerW.i = videoW
  Protected innerH.i = toolH + #LayoutPadding + pbH + #LayoutPadding + videoH + statusH

  If innerW < #WindowWidth : innerW = #WindowWidth : EndIf
  If innerH < (#WindowHeight + 25) : innerH = #WindowHeight + 25 : EndIf

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
  If movieLoaded = 0 Or IsMovie(0) = 0
    ProcedureReturn
  EndIf

  ; Only seek when playing or paused.
  If movieState <> 1 And movieState <> 2
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

  If movieHasVideo
    If movieLengthFrames > 0
      seekTarget = (movieLengthFrames * seekTarget) / pbMax
      MovieSeek(0, seekTarget)
    EndIf
  Else
    ; Audio-only: use a seekable unit.
    ; Some audio formats report MovieLength() = 0 (no "frames"), but GetMovieLength() can still provide ms.
    If audioTotalFrames > 0
      seekTarget = (audioTotalFrames * seekTarget) / pbMax
      MovieSeek(0, seekTarget)

      ; Keep our elapsed-time tracking roughly consistent (best-effort).
      If audioTotalMS > 0
        If audioTotalFrames = audioTotalMS
          audioPausedElapsedMS = seekTarget
          MovieSeek(0, seekTarget)
        Else
          audioPausedElapsedMS = (audioTotalMS * seekTarget) / audioTotalFrames
        EndIf
        audioStartMS = ElapsedMilliseconds() - audioPausedElapsedMS
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

  Protected pbX.i = #ProgressBarLeft
  Protected pbY.i = toolH + #LayoutPadding
  Protected pbW.i = winW - (#ProgressBarLeft + #ProgressBarRightMargin)
  If pbW < 10 : pbW = 10 : EndIf

  If IsGadget(#Gadget_Progress)
    ResizeGadget(#Gadget_Progress, pbX, pbY, pbW, #ProgressBarHeight + 6)
  EndIf

  Protected videoTop.i = pbY + (#ProgressBarHeight + 6) + #LayoutPadding
  Protected videoH.i = winH - videoTop - statusH
  If videoH < 0 : videoH = 0 : EndIf

  EnsureVideoHostWindow()
  If IsWindow(#Window_Video)
    If movieHasVideo
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

  If movieHasVideo And IsMovie(0) And IsWindow(#Window_Video)
    ResizeMovie(0, 0, 0, WindowWidth(#Window_Video, #PB_Window_InnerCoordinate), WindowHeight(#Window_Video, #PB_Window_InnerCoordinate))
  EndIf
EndProcedure

If InitMovie() = 0
  MessageRequester("Error", "Can't initialize video playback!", #PB_MessageRequester_Error)
  End
EndIf


If OpenWindow(#Window_Main, 100, 100, #WindowWidth+50, #WindowHeight+25, #APP_NAME + " v" +
              vers$, #PB_Window_Invisible | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget)
  
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

              moviePath = OpenFileRequester("Load a file", "",
                                            "Media files|*.asf;*.avi;*.flac;*.mid;*.mp3;*.mp4;*.mpg;*.wav;*.wmv|All Files|*.*", 0)
              If moviePath
                If IsMovie(0)
                  FreeMovie(0)
                EndIf

                movieLoaded = 0
                movieState = 0
                audioStartMS = 0
                audioPausedElapsedMS = 0
                audioTotalMS = 0
                audioProgressMaxMS = 0

                 If LoadMovie(0, moviePath)
                   movieHasVideo = Bool(MovieHeight(0) > 0)

                   targetW = MovieWidth(0) / 2
                   targetH = MovieHeight(0) / 2

                   ; Audio-only files (e.g. FLAC) sometimes report 0x0.
                   ; Keep a sane window size and avoid 0-size resizes.
                   If movieHasVideo = 0
                     targetW = #WindowWidth + 50
                     targetH = #WindowHeight + 25
                   EndIf

                  SetGadgetState(#Gadget_Progress, 0)
                  fileName = GetFilePart(moviePath)

                  movieLoaded = 1
                  movieState = 0
                  previousMovieStatus = 0
                  lastProgressUpdate = ElapsedMilliseconds()

                  movieLengthFrames = MovieLength(0)

                  ; Some formats (especially audio-only) can trigger PB internal math issues
                  ; when querying FPS. Only query it when we actually have video.
                  movieFPS_x1000 = 0
                  If movieHasVideo
                    movieFPS_x1000 = MovieInfo(0, 0) ; frames per second (*1000)
                  EndIf

                   ; Audio length in ms (if supported by PB runtime)
                   audioTotalMS = 0
                   audioProgressMaxMS = 0
                   If movieHasVideo = 0
                     audioTotalMS = MovieLengthMS(0)

                     ; Prefer MovieLength() units when available, otherwise fall back to milliseconds.
                     audioTotalFrames = movieLengthFrames
                     If audioTotalFrames <= 0 And audioTotalMS > 0
                       audioTotalFrames = audioTotalMS
                     EndIf

                     audioStartMS = 0
                     audioPausedElapsedMS = 0

                     If audioTotalMS > 0
                       audioProgressMaxMS = audioTotalMS
                     Else
                       audioProgressMaxMS = 0
                     EndIf
                   EndIf

                   ; Trackbar range stays constant (0..#ProgressScaleMax).

                   If movieHasVideo ; Audio/Video file...
                     ResizeMainForVideo(targetW, targetH)
                     StatusBarText(0, 0, "Video '" + fileName + "' loaded.", #PB_StatusBar_Center)
                     GadgetToolTip(#Gadget_Progress, "Video '" + fileName + "' loaded.")
                    Else ; Audio only file...
                      StatusBarText(0, 0, "Audio '" + fileName + "' loaded.", #PB_StatusBar_Center)
                      GadgetToolTip(#Gadget_Progress, "Audio '" + fileName + "' loaded.")
                    EndIf
 
                    UpdateLayout()
                Else
                  StatusBarText(0, 0, "Can't load the file '" + GetFilePart(moviePath) + "' ", #PB_StatusBar_Center)
                EndIf
              EndIf

          
          Case 1 ; Exit
            Exit()
            
          ; ---------------- Movie controls -------------------
            
           Case 2 ; Play
                 If movieLoaded
                   If movieState = 2
                     ResumeMovie(0)
                     If movieHasVideo = 0
                       audioStartMS = ElapsedMilliseconds() - audioPausedElapsedMS
                     EndIf
                   Else
                      If movieHasVideo
                        EnsureVideoHostWindow()
                        PlayMovie(0, WindowID(#Window_Video))
                     Else
                       ; Audio-only (e.g. FLAC): play on the main window.
                       PlayMovie(0, WindowID(#Window_Main))
                       audioStartMS = ElapsedMilliseconds()
                       audioPausedElapsedMS = 0
                     EndIf
                     UpdateLayout()
                     KeepStatusBarOnTop()
                  EndIf
                  movieState = 1 ; Playing
                  MovieAudio(0, volume, balance)
                  currentVolume = volume
                  currentBalance = balance
                  GadgetToolTip(#Gadget_Progress, "Playing <> '" + fileName + "'")
                EndIf
            
           Case 3 ; Stop
               If movieLoaded And movieState = 1
                 StopMovie(0)
                 movieState = 3 ; Stopped
                 StatusBarText(0, 0, "Stopped <> '" + fileName + "'", #PB_StatusBar_Center)
                 GadgetToolTip(#Gadget_Progress, "Stopped <> '" + fileName + "'")
                 If movieHasVideo
                   UpdateLayout()
                 Else
                   audioStartMS = 0
                   audioPausedElapsedMS = 0
                   SetGadgetState(#Gadget_Progress, 0)
                   If audioTotalMS > 0
                     StatusBarText(0, 0, fileName + "  00:00/" + FormatTime(audioTotalMS / 1000), #PB_StatusBar_Center)
                   EndIf
                 EndIf
               EndIf
            
           Case 4 ; Pause
              If movieLoaded And movieState = 1
                PauseMovie(0)
                movieState = 2 ; Paused
                StatusBarText(0, 0, "Paused <> '" + fileName + "'", #PB_StatusBar_Center)
                GadgetToolTip(#Gadget_Progress, "Paused <> '" + fileName + "'")
                If movieHasVideo = 0 And audioStartMS > 0
                  audioPausedElapsedMS = ElapsedMilliseconds() - audioStartMS
                EndIf
              EndIf
            
          ; ---------------- Volume -------------------
            
           Case 6 ; Full 100%
             volume = 100

           Case 7 ; Half 50%
             volume = 50

           Case 8 ; Mute 0%
             volume = 0
            
           ; ---------------- Balance -------------------

           Case 9 ; Both (L+R)
             balance = 0

           Case 10 ; Left (L)
             balance = -100

           Case 11 ; Right (R)
             balance = 100

           ; ---------------------------------------------
            
           Case 12 ; Help
             MessageRequester("Help", "There will be some help, eventually!", #PB_MessageRequester_Info)
            
          ; ------------------ Size ---------------------
 
           Case 13 ; Default (50%)
             If movieLoaded And movieHasVideo
                ResizeMainForVideo(targetW, targetH)
                UpdateLayout()
             EndIf



           Case 14 ; Size x1 (100%)
             If movieLoaded And movieHasVideo
                ResizeMainForVideo(MovieWidth(0), MovieHeight(0))
                UpdateLayout()
             EndIf


           Case 15 ; Size x2 (200%)
             If movieLoaded And movieHasVideo
                ResizeMainForVideo(MovieWidth(0) * 2, MovieHeight(0) * 2)
                UpdateLayout()
             EndIf


            
          ; ---------------- Misc -------------------
            
           Case 16 ; About
             MessageRequester("About", #APP_NAME + " v" + vers$ + #CRLF$ +
                                       "A compact media player for playing audio/video files." + #CRLF$ +
                                       "-----------------------------------------------------" + #CRLF$ +
                                       "Contact: " + #EMAIL_NAME + #CRLF$ +
                                       "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)

          EndSelect
        EndIf

        If movieLoaded
           If currentVolume <> volume Or currentBalance <> balance
             MovieAudio(0, volume, balance)
             currentVolume = volume
             currentBalance = balance
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
          If EventWindow() = #Window_Main And movieLoaded
            now = ElapsedMilliseconds()
            st = MovieStatus(0) ; -1 paused, 0 stopped, >0 current frame


            If movieState = 1 And now - lastProgressUpdate >= 250
              If movieHasVideo
                If st > 0
                  If movieLengthFrames > 0 And st > movieLengthFrames
                    st = movieLengthFrames
                  EndIf
                    If movieLengthFrames > 0
                      isUserSeeking = 0
                      SetGadgetState(#Gadget_Progress, (st * #ProgressScaleMax) / movieLengthFrames)
                      isUserSeeking = 1
                    EndIf

                  ; Optional: show human time if FPS is known
                  If movieFPS_x1000 > 0
                    curSec = (st * 1000) / movieFPS_x1000
                    totalSec = 0
                    If movieLengthFrames > 0
                      totalSec = (movieLengthFrames * 1000) / movieFPS_x1000
                    EndIf
                    StatusBarText(0, 0, fileName + "  " + FormatTime(curSec) + "/" + FormatTime(totalSec), #PB_StatusBar_Center)
                  EndIf
                EndIf
              Else
                  ; Audio-only progress: prefer MovieStatus + a seekable unit.
                  ; When MovieLength() is 0, we fall back to milliseconds.
                  If audioTotalFrames > 0
                    st = MovieStatus(0)
                    If st < 0 : st = 0 : EndIf
                    If st > audioTotalFrames : st = audioTotalFrames : EndIf

                    isUserSeeking = 0
                    SetGadgetState(#Gadget_Progress, (st * #ProgressScaleMax) / audioTotalFrames)
                    isUserSeeking = 1

                    If audioTotalMS > 0
                      ; If audioTotalFrames was forced to ms, st is already ms.
                      If audioTotalFrames = audioTotalMS
                        elapsedMS = st
                      Else
                        elapsedMS = (audioTotalMS * st) / audioTotalFrames
                      EndIf
                      StatusBarText(0, 0, fileName + "  " + FormatTime(elapsedMS / 1000) + "/" + FormatTime(audioTotalMS / 1000), #PB_StatusBar_Center)
                    Else
                      StatusBarText(0, 0, fileName, #PB_StatusBar_Center)
                    EndIf
                  Else
                   ; If even MovieLength() isn't available, fall back to a moving indicator.
                   If audioStartMS > 0
                     elapsedMS = now - audioStartMS
                     windowMS = 600000
                     pos = (elapsedMS % windowMS) * #ProgressScaleMax / windowMS
                     isUserSeeking = 0
                     SetGadgetState(#Gadget_Progress, pos)
                     isUserSeeking = 1
                     StatusBarText(0, 0, fileName + "  " + FormatTime(elapsedMS / 1000), #PB_StatusBar_Center)
                   EndIf
                 EndIf

              EndIf
              lastProgressUpdate = now
            EndIf

            If st <> previousMovieStatus
              Select st
                Case -1
                  StatusBarText(0, 0, "Paused <> '" + fileName + "'", #PB_StatusBar_Center)
                  GadgetToolTip(#Gadget_Progress, "Paused <> '" + fileName + "'")

                Case 0
                  StatusBarText(0, 0, "Stopped <> '" + fileName + "'", #PB_StatusBar_Center)
                  GadgetToolTip(#Gadget_Progress, "Stopped <> '" + fileName + "'")
                  If movieState = 1
                    movieState = 3
                  EndIf

                Default
                  If movieLengthFrames > 0
                    If st > movieLengthFrames
                      st = movieLengthFrames
                    EndIf
                    isUserSeeking = 0
                    SetGadgetState(#Gadget_Progress, (st * #ProgressScaleMax) / movieLengthFrames)
                    isUserSeeking = 1
                  EndIf
              EndSelect

              previousMovieStatus = st
            EndIf
          EndIf

     EndSelect
  ForEver
EndIf
End

; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 9
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyMPlayer.ico
; Executable = ..\HandyMPlayer.exe
; Debugger = IDE
; IncludeVersionInfo
; VersionField0 = 1,0,2,4
; VersionField1 = 1,0,2,4
; VersionField2 = ZoneSoft
; VersionField3 = HandyMPlayer
; VersionField4 = 1.0.2.4
; VersionField5 = 1.0.2.4
; VersionField6 = A Handy Compact Media Player
; VersionField7 = HandyMPlayer
; VersionField8 = HandyMPlayer.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP