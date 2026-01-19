; HandyTXTPad
;
#APP_NAME               = "HandyTXTPad"
#EMAIL_NAME             = "zonemaster60@gmail.com"

Global AppPath.s        = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Global gsFilename.s
XIncludeFile(#APP_NAME + ".pbf")
XIncludeFile(#APP_NAME + ".pbi")

OpenDlg1()

Define event.i

Repeat         ;main message loop
event = WaitWindowEvent()
  Dlg1_Events (event)
Until event = #PB_Event_CloseWindow
Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 15
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyTXTPad.ico
; Executable = ..\HandyTXTPad.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,7
; VersionField1 = 1,0,0,7
; VersionField2 = ZoneSoft
; VersionField3 = HandyTXTPad
; VersionField4 = 1.0.0.7
; VersionField5 = 1.0.0.7
; VersionField6 = A Handy Little Text Pad Program
; VersionField7 = HandyTXTPad
; VersionField8 = HandyTXTPad.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60