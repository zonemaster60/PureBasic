EnableExplicit

; Constants and Enumerations
#APP_NAME   = "LoadTextFile"
#EMAIL_NAME = "zonemaster60@gmail.com"

Enumeration Windows
  #WinMain
EndEnumeration

Enumeration Gadgets
  #EditorMain
EndEnumeration

Enumeration Menus
  #MenuMain
EndEnumeration

Enumeration MenuItems
  #MenuOpen
  #MenuAbout
  #MenuExit
EndEnumeration

Global version.s = "v1.0.0.1"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

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

Procedure LoadFileToEditor(Filename.s)
  Protected FileID.i, Content.s, Format.i
  
  FileID = ReadFile(#PB_Any, Filename)
  If FileID
    Format = ReadStringFormat(FileID) ; Automatically detect BOM (UTF-8, UTF-16, etc.)
    Content = ReadString(FileID, #PB_File_IgnoreEOL | Format)
    CloseFile(FileID)
    
    SetGadgetText(#EditorMain, Content)
    SetWindowTitle(#WinMain, #APP_NAME + " - " + GetFilePart(Filename))
    ProcedureReturn #True
  Else
    MessageRequester("Error", "Unable to open file:" + #CRLF$ + Filename, #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure OnResize()
  ResizeGadget(#EditorMain, 10, 10, WindowWidth(#WinMain) - 20, WindowHeight(#WinMain) - 20)
EndProcedure

; --- Main Execution ---

If OpenWindow(#WinMain, 100, 100, 720, 540, #APP_NAME, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | 
                                                     #PB_Window_MaximizeGadget | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)

  ; Build File menu
  CreateMenu(#MenuMain, WindowID(#WinMain))
  MenuTitle("File")
  MenuItem(#MenuOpen, "Open" + #TAB$ + "Ctrl+O")
  MenuBar()
  MenuItem(#MenuAbout, "About")
  MenuItem(#MenuExit, "Exit")
  
  ; Shortcuts
  AddKeyboardShortcut(#WinMain, #PB_Shortcut_Control | #PB_Shortcut_O, #MenuOpen)

  ; Editor gadget with scrollbars and read-only mode
  EditorGadget(#EditorMain, 10, 10, 700, 500, #PB_Editor_WordWrap | #PB_Editor_ReadOnly)
  
  ; Bind resize event
  BindEvent(#PB_Event_SizeWindow, @OnResize(), #WinMain)

  ; Load file if provided via command-line argument
  If ProgramParameter(0)
    LoadFileToEditor(ProgramParameter(0))
  EndIf

  Repeat
    Define Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_CloseWindow
        ExitApp()

      Case #PB_Event_Menu
        Select EventMenu()
        
          Case #MenuOpen  ; Open file
            Define Filename.s = OpenFileRequester("Open text file", "", "Text files|*.txt;*.log;*.json|All files|*.*", 0)
            If Filename
              LoadFileToEditor(Filename)
            EndIf

          Case #MenuAbout
            MessageRequester("About", #APP_NAME + " - " + version + #CRLF$ + 
                                     "Thank you for using this free tool!" + #CRLF$ +
                                     "Contact: " + #EMAIL_NAME + #CRLF$ +
                                     "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
            
          Case #MenuExit  ; Exit
            ExitApp()

        EndSelect

    EndSelect
  ForEver

EndIf

Shutdown()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 24
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = loadtextfile.ico
; Executable = ..\loadtextfile.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,1
; VersionField1 = 1,0,0,1
; VersionField2 = ZoneSoft
; VersionField3 = loadtextfile
; VersionField4 = 1.0.0.1
; VersionField5 = 1.0.0.1
; VersionField6 = Loads and displays text files
; VersionField7 = loadtextfile
; VersionField8 = loadtextfile.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60