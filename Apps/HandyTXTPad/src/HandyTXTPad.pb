; HandyTXTPad
;
EnableExplicit

#APP_NAME               = "HandyTXTPad"
#EMAIL_NAME             = "zonemaster60@gmail.com"
#StatusMain             = 0
#PREFS_FILE             = "HandyTXTPad.ini"
#MAX_RECENT_FILES       = 5

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
Global gsFileEncoding.s = "UTF-8"
Global gsSavedText.s
Global Dim gRecentFiles.s(#MAX_RECENT_FILES - 1)
Global gShouldExit.i
Global gIsDirty.i
Global gIsUpdatingEditor.i
XIncludeFile(#APP_NAME + ".pbf")
XIncludeFile(#APP_NAME + ".pbi")

OpenDlg1()
EnableGadgetDrop(#Editor1, #PB_Drop_Files, #PB_Drag_Copy)
EnableWindowDrop(#Dlg1, #PB_Drop_Files, #PB_Drag_Copy)
AddKeyboardShortcut(#Dlg1, #PB_Shortcut_Control | #PB_Shortcut_N, #mnuNew)
AddKeyboardShortcut(#Dlg1, #PB_Shortcut_Control | #PB_Shortcut_O, #mnuOpen)
AddKeyboardShortcut(#Dlg1, #PB_Shortcut_Control | #PB_Shortcut_S, #mnuSave)
AddKeyboardShortcut(#Dlg1, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_S, #mnuSaveAs)
AddKeyboardShortcut(#Dlg1, #PB_Shortcut_Control | #PB_Shortcut_Z, #mnuUndo)
AddKeyboardShortcut(#Dlg1, #PB_Shortcut_Control | #PB_Shortcut_Y, #mnuRedo)
AddKeyboardShortcut(#Dlg1, #PB_Shortcut_Control | #PB_Shortcut_X, #mnuCut)
AddKeyboardShortcut(#Dlg1, #PB_Shortcut_Control | #PB_Shortcut_C, #mnuCopy)
AddKeyboardShortcut(#Dlg1, #PB_Shortcut_Control | #PB_Shortcut_V, #mnuPaste)
AddKeyboardShortcut(#Dlg1, #PB_Shortcut_F1, #mnuAbout)
LoadRecentFiles()
SetMainTitle()
UpdateStatusBar()
UpdateRecentFilesMenu()

Define event.i
Repeat         ;main message loop
  event = WaitWindowEvent()
  If event = #PB_Event_CloseWindow
    If RequestExit()
      gShouldExit = #True
    EndIf
  Else
    If Dlg1_Events(event) = #False
      If RequestExit()
        gShouldExit = #True
      EndIf
    EndIf
  EndIf
Until gShouldExit

If hMutex
  CloseHandle_(hMutex)
EndIf
End
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 5
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyTXTPad.ico
; Executable = ..\HandyTXTPad.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,9
; VersionField1 = 1,0,0,9
; VersionField2 = ZoneSoft
; VersionField3 = HandyTXTPad
; VersionField4 = 1.0.0.9
; VersionField5 = 1.0.0.9
; VersionField6 = A Handy Little Full-Featured Text Pad app
; VersionField7 = HandyTXTPad
; VersionField8 = HandyTXTPad.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60