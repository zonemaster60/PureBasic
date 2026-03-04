
#APP_NAME = "HandyTXTPad"
Global version.s = "v1.0.0.8"

Procedure SetMainTitle()
  Protected sTitle.s = #APP_NAME
  If gsFilename <> ""
    sTitle + " - [" + GetFilePart(gsFilename) + "]"
  EndIf
  SetWindowTitle(#Dlg1, sTitle)
EndProcedure

Procedure mnuNew(eventid)
  If GetGadgetText(#Editor1) <> ""
    If MessageRequester("New", "Clear current text?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_No
      ProcedureReturn
    EndIf
  EndIf
  gsFilename = ""
  SetGadgetText(#Editor1, "")
  SetMainTitle()
EndProcedure

Procedure mnuOpen(eventid)
  Protected sOpenfile.s = OpenFileRequester("Select file to open...", "", "Text (*.txt)|*.txt|All files (*.*)|*.*", 0)
  If sOpenfile <> ""
    Protected hFile = ReadFile(#PB_Any, sOpenfile, #PB_File_SharedRead)
    If hFile = 0
      MessageRequester("Error", "Couldn't open file!", #PB_MessageRequester_Error)
    Else
      Protected format = ReadStringFormat(hFile)
      Protected sBuf.s = ReadString(hFile, format | #PB_File_IgnoreEOL)
      CloseFile(hFile)
      SetGadgetText(#Editor1, sBuf)
      gsFilename = sOpenfile
      SetMainTitle()
    EndIf
  EndIf
EndProcedure

Procedure SaveToFile(sFile.s)
    Protected hFile = CreateFile(#PB_Any, sFile)
    If hFile = 0
      MessageRequester("Error", "Couldn't create file!", #PB_MessageRequester_Error)
    Else
      WriteStringFormat(hFile, #PB_UTF8)
      WriteString(hFile, GetGadgetText(#Editor1), #PB_UTF8)
      CloseFile(hFile)
      gsFilename = sFile
      SetMainTitle()
    EndIf
EndProcedure

Procedure mnuSaveAs(eventid)
  Protected sFile.s = SaveFileRequester("Save file as...", "", "", 0)
  If sFile <> ""
    SaveToFile(sFile)
  EndIf
EndProcedure

Procedure mnuSave(eventid)
  If gsFilename <> ""
    SaveToFile(gsFileName)
  Else
    mnuSaveAs(eventid)
  EndIf
EndProcedure

Procedure mnuExit(eventid)
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_Info | #PB_MessageRequester_YesNo)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure

Procedure mnuAbout(eventid)
  MessageRequester("Info", #APP_NAME + " - " + version + #CRLF$ +
                           "A handy little text editor" + #CRLF$ +
                           "----------------------------------------" + #CRLF$ +
                           "Contact: " + #EMAIL_NAME + #CRLF$ +
                           "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
EndProcedure
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 75
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = editdocument_24.png
; Executable = pbnotepad.exe