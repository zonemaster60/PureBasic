EnableExplicit

#APP_NAME   = "LoadTextFile"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.2"
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

; Variable definitions
Define filename.s, content.s, line.s

Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseHandle_(hMutex)
    End
  EndIf
EndProcedure

; Create the main window
If OpenWindow(0, 100, 100, 720, 540, #APP_NAME, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | 
                                                #PB_Window_ScreenCentered)

  ; Build File menu
  CreateMenu(0, WindowID(0))
  MenuTitle("File")
  MenuItem(1, "Open")
  MenuBar()
  MenuItem(2, "About")
  MenuItem(3, "Exit")

  ; Editor gadget with scrollbars and read-only mode
  EditorGadget(0, 10, 10, 700, 500, #PB_Editor_WordWrap | #PB_Editor_ReadOnly)

  ; Load file if provided via command-line argument
  If ProgramParameter(0)
    filename = ProgramParameter(0)
    If ReadFile(1, filename, #PB_UTF8)
      content = ""
      While Not Eof(1)
        line = ReadString(1, #PB_File_IgnoreEOL)
        content + line + #CRLF$
      Wend
      CloseFile(1)
      SetGadgetText(0, content)
      SetWindowTitle(0, #APP_NAME + " - " + filename)
    Else
      MessageRequester("Error", "Unable to open file from argument.", #PB_MessageRequester_Error)
      CloseHandle_(hMutex)
      End
    EndIf
  EndIf

  Repeat
    Define Event = WaitWindowEvent()
    Select Event

      Case #PB_Event_Menu
        Select EventMenu()
        
          Case 1  ; Open file
            filename = OpenFileRequester("Open text file", "", "Text files|*.txt|All files|*.*", 0)
            If filename
              If ReadFile(1, filename, #PB_UTF8)
                content = ""
                While Not Eof(1)
                  line = ReadString(1, #PB_File_IgnoreEOL)
                  content + line + #CRLF$
                Wend
                CloseFile(1)
                SetGadgetText(0, content)
                SetWindowTitle(0, #APP_NAME + " - " + filename)
              Else
                MessageRequester("Error", "Unable to open the file.", #PB_MessageRequester_Error)
                CloseHandle_(hMutex)
                End
              EndIf
            EndIf
          Case 2
            MessageRequester("Info", #APP_NAME + " - " + version + #CRLF$ + 
                                     "Thank you for using this free tool!" + #CRLF$ +
                                     "Contact: " + #EMAIL_NAME + #CRLF$ +
                                     "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
            
          Case 3  ; Exit
            Exit()

        EndSelect

      Case #PB_Event_CloseWindow
        Exit()

    EndSelect
  ForEver

EndIf

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 29
; FirstLine = 6
; Folding = -
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