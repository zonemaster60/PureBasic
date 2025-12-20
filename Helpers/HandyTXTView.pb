; HandyTXTView

#APP_NAME   = "HandyTXTView"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global AppPath.s        = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; name of text file to view
Define filename.s, content.s, line.s

Procedure Exit()
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    MessageRequester("Info", #APP_NAME + " v1.0.0.0"+ #CRLF$ + 
                             "Thank you for using this free tool!" + #CRLF$ +
                             "Contact: " + #EMAIL_NAME, #PB_MessageRequester_Info)
    End
  EndIf
EndProcedure

If ReadFile(0, #APP_NAME + ".ini")        ; if the file could be read, we continue ...
    Format = ReadStringFormat(0)
    While Eof(0) = 0                ; loop as long the 'end of file' isn't reached
      filename = ReadString(0, Format)   ; display line by line in the debug window
    Wend
    CloseFile(0)                    ; close the previously opened file
  Else
    MessageRequester("Error", "Failed to open the file!", #PB_MessageRequester_Error | #PB_MessageRequester_Ok)
    End
EndIf

; Open a window
OpenWindow(0, 100, 100, 600, 400, #APP_NAME, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)

; Create an EditorGadget to display text
EditorGadget(0, 10, 10, 580, 380)

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
      End
    EndIf
  EndIf

; Load a text file and display its content
If ReadFile(0, filename)
  While Eof(0) = 0
    AddGadgetItem(0, -1, ReadString(0))
  Wend
  CloseFile(0)
Else
  MessageRequester("Error", "Failed to open the file.", #PB_MessageRequester_Error | #PB_MessageRequester_Ok)
  End
EndIf

; Main event loop
Repeat
  Event = WaitWindowEvent()
Until Event = #PB_Event_CloseWindow
Exit()

; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 71
; FirstLine = 43
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = src\HandyTXTView.ico
; Executable = HandyTXTView.exe