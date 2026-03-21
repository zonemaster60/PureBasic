EnableExplicit

; Constants and Enumerations
#APP_NAME      = "LoadTextFile"
#APP_VERSION   = "v1.0.0.2"
#EMAIL_NAME    = "zonemaster60@gmail.com"
#OPEN_FILTER   = "Text and code files|*.txt;*.log;*.md;*.csv;*.json;*.xml;*.ini;*.cfg;*.yml;*.yaml;*.pb;*.pbi;*.c;*.cpp;*.h;*.hpp;*.py;*.js;*.ts;*.html;*.css|All files|*.*"
#TEXT_EXTENSIONS = "|txt|log|md|csv|json|xml|ini|cfg|conf|yml|yaml|toml|pb|pbi|c|cpp|h|hpp|py|js|ts|html|htm|css|bat|cmd|ps1|sql|sh|"
#WINDOW_MARGIN = 10
#MAX_RECENT_FILES = 5

Enumeration Windows
  #WinMain
EndEnumeration

Enumeration Gadgets
  #EditorMain
EndEnumeration

Enumeration Menus
  #MenuMain
EndEnumeration

Enumeration StatusBars
  #StatusMain
EndEnumeration

Enumeration MenuItems
  #MenuOpen
  #MenuRecent1
  #MenuRecent2
  #MenuRecent3
  #MenuRecent4
  #MenuRecent5
  #MenuAbout
  #MenuExit
EndEnumeration

Global CurrentFile.s
Global Dim RecentFiles.s(#MAX_RECENT_FILES - 1)

Declare.i LoadFileToEditor(Filename.s)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = #ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; --- Procedures ---

Procedure Shutdown()
  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
  End
EndProcedure

Procedure ExitApp()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    Shutdown()
  EndIf
EndProcedure

Procedure.i IsSupportedTextFile(Filename.s)
  Protected Extension.s

  If FileSize(Filename) < 0
    ProcedureReturn #False
  EndIf

  Extension = LCase(GetExtensionPart(Filename))
  If Extension = ""
    ProcedureReturn #True
  EndIf

  If FindString(#TEXT_EXTENSIONS, "|" + Extension + "|", 1)
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.i CountLines(Text.s)
  If Text = ""
    ProcedureReturn 0
  EndIf

  ProcedureReturn CountString(Text, #CRLF$) + 1
EndProcedure

Procedure UpdateWindowTitle(Filename.s = "")
  If Filename
    SetWindowTitle(#WinMain, #APP_NAME + " - " + GetFilePart(Filename))
  Else
    SetWindowTitle(#WinMain, #APP_NAME)
  EndIf
EndProcedure

Procedure UpdateStatusBar(Filename.s, Content.s)
  Protected LineCount.i = CountLines(Content)
  Protected CharacterCount.i = Len(Content)

  If Filename
    StatusBarText(#StatusMain, 0, Filename)
  Else
    StatusBarText(#StatusMain, 0, "Ready - press Ctrl+O or drop a file here")
  EndIf

  StatusBarText(#StatusMain, 1, "Lines: " + Str(LineCount), #PB_StatusBar_Right)
  StatusBarText(#StatusMain, 2, "Chars: " + Str(CharacterCount), #PB_StatusBar_Right)
EndProcedure

Procedure UpdateRecentFilesMenu()
  Protected Index.i
  Protected MenuItemID.i

  For Index = 0 To #MAX_RECENT_FILES - 1
    MenuItemID = #MenuRecent1 + Index

    If RecentFiles(Index)
      SetMenuItemText(#MenuMain, MenuItemID, "&" + Str(Index + 1) + " " + GetFilePart(RecentFiles(Index)) + #TAB$ + RecentFiles(Index))
      DisableMenuItem(#MenuMain, MenuItemID, 0)
    Else
      SetMenuItemText(#MenuMain, MenuItemID, "(empty)")
      DisableMenuItem(#MenuMain, MenuItemID, 1)
    EndIf
  Next
EndProcedure

Procedure AddRecentFile(Filename.s)
  Protected Index.i
  Protected ExistingIndex.i = -1

  For Index = 0 To #MAX_RECENT_FILES - 1
    If RecentFiles(Index) = Filename
      ExistingIndex = Index
      Break
    EndIf
  Next

  If ExistingIndex > 0
    For Index = ExistingIndex To 1 Step -1
      RecentFiles(Index) = RecentFiles(Index - 1)
    Next
  ElseIf ExistingIndex = -1
    For Index = #MAX_RECENT_FILES - 1 To 1 Step -1
      RecentFiles(Index) = RecentFiles(Index - 1)
    Next
  EndIf

  RecentFiles(0) = Filename
  UpdateRecentFilesMenu()
EndProcedure

Procedure OpenRecentFile(Index.i)
  Protected ShiftIndex.i

  If Index < 0 Or Index >= #MAX_RECENT_FILES
    ProcedureReturn
  EndIf

  If RecentFiles(Index) = ""
    ProcedureReturn
  EndIf

  If FileSize(RecentFiles(Index)) >= 0
    LoadFileToEditor(RecentFiles(Index))
  Else
    MessageRequester("Missing file", "This recent file is no longer available:" + #CRLF$ + RecentFiles(Index), #PB_MessageRequester_Warning)

    For ShiftIndex = Index To #MAX_RECENT_FILES - 2
      RecentFiles(ShiftIndex) = RecentFiles(ShiftIndex + 1)
    Next
    RecentFiles(#MAX_RECENT_FILES - 1) = ""
    UpdateRecentFilesMenu()
  EndIf
EndProcedure

Procedure LoadFileToEditor(Filename.s)
  Protected FileID.i
  Protected Content.s
  Protected Format.i
  Protected Line.s
  
  FileID = ReadFile(#PB_Any, Filename)
  If FileID
    Format = ReadStringFormat(FileID) ; Automatically detect BOM (UTF-8, UTF-16, etc.)

    While Eof(FileID) = 0
      Line = ReadString(FileID, Format)
      If Content
        Content + #CRLF$
      EndIf
      Content + Line
    Wend

    CloseFile(FileID)
    
    CurrentFile = Filename
    SetGadgetText(#EditorMain, Content)
    UpdateWindowTitle(Filename)
    UpdateStatusBar(Filename, Content)
    AddRecentFile(Filename)
    ProcedureReturn #True
  Else
    MessageRequester("Error", "Unable to open file:" + #CRLF$ + Filename, #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure OpenTextFile()
  Protected InitialPath.s
  Protected Filename.s

  If CurrentFile
    InitialPath = GetPathPart(CurrentFile)
  EndIf

  Filename = OpenFileRequester("Open text file", InitialPath, #OPEN_FILTER, 0)
  If Filename
    LoadFileToEditor(Filename)
  EndIf
EndProcedure

Procedure LoadDroppedFiles(Files.s)
  Protected Index.i
  Protected Filename.s

  For Index = 1 To CountString(Files, Chr(10)) + 1
    Filename = RemoveString(StringField(Files, Index, Chr(10)), Chr(13))

    If IsSupportedTextFile(Filename)
      LoadFileToEditor(Filename)
      ProcedureReturn
    EndIf
  Next

  If Files
    MessageRequester("Unsupported file", "Drop a supported text file such as TXT, LOG, JSON, PB, PY, JS, or similar text-based formats.", #PB_MessageRequester_Warning)
  EndIf
EndProcedure

Procedure OnResize()
  Protected Margin.i = DesktopScaledX(#WINDOW_MARGIN)
  Protected TopMargin.i = DesktopScaledY(#WINDOW_MARGIN)
  Protected BottomMargin.i = DesktopScaledY(#WINDOW_MARGIN)
  Protected StatusHeight.i = DesktopScaledY(24)
  Protected Width.i = WindowWidth(#WinMain) - (Margin * 2)
  Protected Height.i = WindowHeight(#WinMain) - TopMargin - BottomMargin - StatusHeight

  If Width < 0
    Width = 0
  EndIf
  If Height < 0
    Height = 0
  EndIf

  ResizeGadget(#EditorMain, Margin, TopMargin, Width, Height)
EndProcedure

; --- Main Execution ---

If OpenWindow(#WinMain, 100, 100, 720, 540, #APP_NAME, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | 
                                                     #PB_Window_MaximizeGadget | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)

  WindowBounds(#WinMain, 420, 300, #PB_Ignore, #PB_Ignore)

  ; Build File menu
  If CreateMenu(#MenuMain, WindowID(#WinMain))
    MenuTitle("File")
    MenuItem(#MenuOpen, "Open" + #TAB$ + "Ctrl+O")
    OpenSubMenu("Recent Files")
      MenuItem(#MenuRecent1, "(empty)")
      MenuItem(#MenuRecent2, "(empty)")
      MenuItem(#MenuRecent3, "(empty)")
      MenuItem(#MenuRecent4, "(empty)")
      MenuItem(#MenuRecent5, "(empty)")
    CloseSubMenu()
    MenuBar()
    MenuItem(#MenuAbout, "About")
    MenuItem(#MenuExit, "Exit")

    UpdateRecentFilesMenu()
  EndIf
  
  ; Shortcuts
  AddKeyboardShortcut(#WinMain, #PB_Shortcut_Control | #PB_Shortcut_O, #MenuOpen)

  ; Editor gadget with scrollbars and read-only mode
  EditorGadget(#EditorMain, 0, 0, 0, 0, #PB_Editor_WordWrap | #PB_Editor_ReadOnly)
  EnableGadgetDrop(#EditorMain, #PB_Drop_Files, #PB_Drag_Copy)

  If CreateStatusBar(#StatusMain, WindowID(#WinMain))
    AddStatusBarField(#PB_Ignore)
    AddStatusBarField(110)
    AddStatusBarField(110)
    UpdateStatusBar("", "")
  EndIf
  
  ; Bind resize event
  BindEvent(#PB_Event_SizeWindow, @OnResize(), #WinMain)
  OnResize()

  ; Load file if provided via command-line argument
  If ProgramParameter(0)
    LoadFileToEditor(ProgramParameter(0))
  Else
    UpdateWindowTitle()
  EndIf

  Repeat
    Define Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_CloseWindow
        ExitApp()

      Case #PB_Event_Menu
        Select EventMenu()
        
          Case #MenuOpen  ; Open file
            OpenTextFile()

          Case #MenuRecent1
            OpenRecentFile(0)

          Case #MenuRecent2
            OpenRecentFile(1)

          Case #MenuRecent3
            OpenRecentFile(2)

          Case #MenuRecent4
            OpenRecentFile(3)

          Case #MenuRecent5
            OpenRecentFile(4)

          Case #MenuAbout
            MessageRequester("About", #APP_NAME + " - " + #APP_VERSION + #CRLF$ + 
                                     "Thank you for using this free tool!" + #CRLF$ +
                                     "Contact: " + #EMAIL_NAME + #CRLF$ +
                                     "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
            
          Case #MenuExit  ; Exit
            ExitApp()

        EndSelect

      Case #PB_Event_GadgetDrop
        If EventGadget() = #EditorMain
          LoadDroppedFiles(EventDropFiles())
        EndIf

    EndSelect
  ForEver

EndIf

Shutdown()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 4
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = loadtextfile.ico
; Executable = ..\loadtextfile.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = loadtextfile
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = Loads and displays text files
; VersionField7 = loadtextfile
; VersionField8 = loadtextfile.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60