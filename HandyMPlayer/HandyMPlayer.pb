;PB4.00
;20061127, now works with unicode executables

Declare createShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index)
Declare.s getSpecialFolder(id)

Procedure.s getSpecialFolder(id)
  Protected path.s, *ItemId.ITEMIDLIST
 
  *itemId = #Null
  If SHGetSpecialFolderLocation_(0, id, @*ItemId) = #NOERROR
    path = Space(#MAX_PATH)
    If SHGetPathFromIDList_(*itemId, @path)
      If Right(path, 1) <> "\"
        path + "\"
      EndIf
      ProcedureReturn path
    EndIf
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure createShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index)
  ;obj - path to the exe that is linked to, lnk - link name, dir - working
  ;directory, icon - path to the icon file, index - icon index in iconfile
  Protected hRes.l, mem.s, ppf.IPersistFile
  CompilerIf #PB_Compiler_Unicode
    Protected psl.IShellLinkW
  CompilerElse
    Protected psl.IShellLinkA
  CompilerEndIf

  ;make shure COM is active
  CoInitialize_(0)
  hRes = CoCreateInstance_(?CLSID_ShellLink, 0, 1, ?IID_IShellLink, @psl)

  If hRes = 0
    psl\SetPath(Obj)
    psl\SetArguments(arg)
    psl\SetDescription(desc)
    psl\SetWorkingDirectory(dir)
    psl\SetIconLocation(icon, index)
    ;query IShellLink for the IPersistFile interface for saving the
    ;link in persistent storage
    hRes = psl\QueryInterface(?IID_IPersistFile, @ppf)

    If hRes = 0
      ;CompilerIf #PB_Compiler_Unicode
        ;save the link
        hRes = ppf\Save(lnk, #True)
;       CompilerElse
;         ;ensure that the string is ansi unicode
;         mem = Space(#MAX_PATH)
;         MultiByteToWideChar_(#CP_ACP, 0, lnk, -1, mem, #MAX_PATH)
;         ;save the link
;         hRes = ppf\Save(mem, #True)
;       CompilerEndIf
      ppf\Release()
    EndIf
    psl\Release()
  EndIf

  ;shut down COM
  CoUninitialize_()

  DataSection
    CLSID_ShellLink:
    Data.l $00021401
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
    IID_IShellLink:
    CompilerIf #PB_Compiler_Unicode
      Data.l $000214F9
    CompilerElse
      Data.l $000214EE
    CompilerEndIf
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
    IID_IPersistFile:
    Data.l $0000010b
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
  EndDataSection
  ProcedureReturn hRes
EndProcedure

#CSIDL_WINDOWS = $24
#CSIDL_DESKTOPDIRECTORY = $10

Global obj.s, obj2.s, lnk.s, lnk2.s

obj = getSpecialFolder(#CSIDL_PROGRAM_FILES) + "HandyMPlayer\HandyMPlayer.exe"
obj2 = getSpecialFolder(#CSIDL_PROGRAM_FILES) + "HandyMPlayer"
lnk = getSpecialFolder(#CSIDL_ALTSTARTUP)
lnk2 = getSpecialFolder(#CSIDL_DESKTOPDIRECTORY)

; check for existence of desktop link
If FileSize(lnk2 + "HandyMPlayer.lnk") = -1
  If createShellLink(obj, lnk2 + "HandyMPlayer.lnk", "", "Start HandyMPlayer", obj2, obj, 0) = 0
    MessageRequester("Info", "A Desktop link was created.", #PB_MessageRequester_Info)
  EndIf
EndIf

;
; Handy Media Player
;

#WindowWidth=365
#WindowHeight=70

iconlib.s = "HandyMPlayer.icl"
AboutIcon = ExtractIcon_(0, iconlib, 0)     
LoadIcon = ExtractIcon_(0, iconlib, 1)
PauseIcon = ExtractIcon_(0, iconlib, 2)
PlayIcon = ExtractIcon_(0, iconlib, 3)
StopIcon = ExtractIcon_(0, iconlib, 4)

Procedure Exit()
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure
          
If InitMovie() = 0
  MessageRequester("Error", "Can't initialize video playback!", #PB_MessageRequester_Error)
  End
EndIf

; check for running instance
If FindWindow_(0, "Handy Media Player")
  MessageRequester("Info", "Handy Media Player is already running.", #PB_MessageRequester_Info)
  End
EndIf  

vers$ = " v0.1.2.1 (20242404)"
File1Size = 0
FileDevide = 245

If OpenWindow(0, 100, 100, #WindowWidth+50, #WindowHeight+25, "Handy Media Player"+
              vers$, #PB_Window_Invisible | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget)
  
  ; create the program menu
  If CreateMenu(0, WindowID(0))
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
  If CreateToolBar(0, WindowID(0))
    ToolBarImageButton(0, LoadIcon)
    ToolBarSeparator()
    ToolBarImageButton(2, PlayIcon)
    ToolBarSeparator()
    ToolBarImageButton(4, PauseIcon)
    ToolBarImageButton(3, StopIcon)
    ToolBarSeparator()
    ToolBarImageButton(16, AboutIcon)
  EndIf
  
  If CreateStatusBar(0, WindowID(0))
    AddStatusBarField(8192) ; Maximum value of 8192 pixels, to have a field which take all the window width !
    StatusBarText(0, 0, "-=[Welcome to Handy Media Player!]=-", #PB_StatusBar_Center)
  EndIf
  
  HideWindow(0, 0) ; Show the window once all toolbar/menus has been created...
  Volume = 100
  
  Repeat
    Select WindowEvent()
      Case #PB_Event_Menu
     
        Select EventMenu()
            
          Case 0 ; Load 
           MovieName$ = OpenFileRequester("Load a file", "",
                                          "Media files|*.asf;*.avi;*.flac;*.mid;*.mp3;*.mp4;*.mpg;*.wav;*.wmv|All Files|*.*", 0)
            If MovieName$
              If LoadMovie(0, MovieName$)
                ProgressBarGadget(0, 10, 30 , 395, 15, 0, 100)
                SetGadgetState(0, 0)
                File1$ = GetFilePart(MovieName$)
                File1Size = FileSize(MovieName$)
                MovieLoaded = 1
                MovieState = 0              
                If MovieHeight(0) > 0 ; Audio/Video file...
                  MovieWidth = MovieWidth(0)/2
                  MovieHeight = MovieHeight(0)/2
                  ResizeWindow(0, #PB_Ignore, #PB_Ignore, MovieWidth, MovieHeight)
                  StatusBarText(0, 0, "Video '" + File1$ + "' loaded.", #PB_StatusBar_Center)
                  GadgetToolTip(0, "Video '" + File1$ + "' loaded.")
                Else ; Audio only file...
                  StatusBarText(0, 0, "Audio '" + File1$ + "' loaded.", #PB_StatusBar_Center)
                  GadgetToolTip(0, "Audio '" + File1$ + "' loaded.")
                EndIf
              Else
                StatusBarText(0, 0, "Can't load the file '" + File1$ + "' ", #PB_StatusBar_Center)
              EndIf
            EndIf   
          
          Case 1 ; Exit
            Exit()
            
          ; ---------------- Movie controls -------------------
            
          Case 2 ; Play  
            If MovieLoaded
              If MovieState = 2
                ResumeMovie(0)
              Else
                PlayMovie(0, WindowID(0))
              EndIf
              MovieState = 1 ; Playing
              GadgetToolTip(0, "Playing <> '" + File1$ + "'")
            EndIf
            
          Case 3 ; Stop
            If MovieLoaded And MovieState = 1
              StopMovie(0)
              MovieState = 3 ; Stopped
              StatusBarText(0, 0, "Stopped <> '" + File1$ + "'", #PB_StatusBar_Center)
              GadgetToolTip(0, "Stopped <> '" + File1$ + "'")
            EndIf
            
          Case 4 ; Pause
            If MovieLoaded And MovieState = 1
              PauseMovie(0)
              MovieState = 2 ; Paused
              StatusBarText(0, 0, "Paused <> '" + File1$ + "'", #PB_StatusBar_Center)
              GadgetToolTip(0, "Paused <> '" + File1$ + "'")
            EndIf
            
          ; ---------------- Volume -------------------
            
          Case 6 ; Full 100%
            Volume = 100
            
          Case 7 ; Half 50%
            Volume = 50
            
          Case 8 ; Mute 0%
            Volume = 0
            
          ; ---------------- Balance -------------------
                        
          Case 9 ; Both (L<>R)
            Balance = 0
            
          Case 10 ; Left (L)
            Balance = -100
            
          Case 11 ; Right (R)
            Balance = 100
          
            MovieAudio(0, Volume, Balance) ; update the volume and balance
          ; --------------------------------------------- 
            
          Case 12 ; Help
            MessageRequester("Help", "There will be some help, eventually!", #PB_MessageRequester_Info)
            
          ; ------------------ Size ---------------------
 
          Case 13 ; Default (50%)
            If MovieLoaded And MovieHeight(0) > 0
              MovieWidth = MovieWidth(0)/2
              MovieHeight = MovieHeight(0)/2
            EndIf
            
          Case 14 ; Size x1 (100%)
            If MovieLoaded And MovieHeight(0) > 0
              MovieWidth = MovieWidth(0)
              MovieHeight = MovieHeight(0)
            EndIf
                    
          Case 15 ; Size x2 (200%)
            If MovieLoaded And MovieHeight(0) > 0
              MovieWidth = MovieWidth(0)*2
              MovieHeight = MovieHeight(0)*2
            EndIf
            
          ; ---------------- Misc -------------------
            
          Case 16 ; About
            MessageRequester("About", "Handy Media Player v" + vers$ + #CRLF$+
                                      "Email: zonemaster@yahoo.com", #PB_MessageRequester_Info)
                                 
        EndSelect
        
        If MovieLoaded
          If CurrentWidth <> MovieWidth Or CurrentHeight <> MovieHeight
            ResizeWindow(0, #PB_Ignore, #PB_Ignore, MovieWidth, MovieHeight) ; Video will be resized in the #PB_WindowSizeEvent
            CurrentWidth = MovieWidth
            CurrentHeight = MovieHeight
          EndIf
          If CurrentVolume <> Volume Or CurrentBalance <> Balance ; We need to update the audio stuff
            MovieAudio(0, Volume, Balance)
            CurrentVolume = Volume
            CurrentBalance = Balance
          EndIf
        EndIf
        
      Case #PB_Event_CloseWindow
        Exit()
        
      Case #PB_Event_SizeWindow
        If IsMovie(0)
          ResizeMovie(0, 0, 80, WindowWidth(0), WindowHeight(0))
        EndIf
        
      Case 0
        If MovieLoaded And MovieStatus(0) <> PreviousMovieStatus
                      
          Select MovieStatus(0)
            Case -1
              StatusBarText(0, 0, "Paused <> '" + File1$ + "'", #PB_StatusBar_Center)
              GadgetToolTip(0, "Paused <> '" + File1$ + "'")
              
            Case 0
              StatusBarText(0, 0, "Stopped <> '" + File1$ + "'", #PB_StatusBar_Center)
              GadgetToolTip(0, "Stopped <> '" + File1$ + "'")
              
            Default              
              MaxProgress = File1Size
              MovieProgress = ((MovieStatus(0)/MaxProgress)*(File1Size/FileDevide))
              If MovieProgress < MaxProgress
                ProgressBarGadget(0, 10, 30 , 395, 15, 0, MaxProgress)
                SetGadgetState(0, MovieProgress)
              ElseIf MovieProgress > MaxProgress
                MovieProgress = MaxProgress
                ProgressBarGadget(0, 10, 30 , 395, 15, 0, MaxProgress)
                SetGadgetState(0, MovieProgress)
              EndIf                    
          EndSelect   
          If MovieProgress => MaxProgress And MovieState = 1
            MovieState = 3
          EndIf         
          PreviousMovieStatus = MovieStatus(0)
        EndIf          
    EndSelect
  ForEver
EndIf
End

; IDE Options = PureBasic 6.11 LTS Beta 1 (Windows - x64)
; CursorPosition = 135
; FirstLine = 345
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableUser
; UseIcon = HandyMPlayer.ico
; Executable = HandyMPlayer.exe
; Debugger = IDE
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 0,1,2,1
; VersionField2 = ZoneSoft Software
; VersionField3 = Handy Media Player
; VersionField4 = 0.1.2.1
; VersionField5 = 1.0.0.0
; VersionField6 = A Handy Compact Media Player
; VersionField7 = Handy Media Player
; VersionField8 = Handy Media Player
; VersionField9 = David Scouten
; VersionField10 = David Scouten
; VersionField13 = zonemaster@yahoo.com
; VersionField14 = http://www.facebook.com/DavesPCPortal
; VersionField15 = VOS_NT_WINDOWS32
; VersionField16 = VFT_APP
; Watchlist = MaxProgress;MovieProgress;MovieState