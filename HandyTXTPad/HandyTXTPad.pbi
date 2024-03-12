Procedure SetMainTitle()
  SetWindowTitle(#Dlg1, "HandyTXTPad" + GetFilePart(gsFilename))
EndProcedure

Procedure mnuNew(eventid)
  gsFilename = ""
  SetGadgetText(#Editor1, "")
  SetMainTitle()
EndProcedure

Procedure mnuOpen(eventid)
  Protected sOpenfile.s = OpenFileRequester("Select file to open...", "", "", 0)
  If sOpenfile <> ""
    Protected hFile = ReadFile(#PB_Any, sOpenfile)
    If hFile = 0
      MessageRequester("Error", "Couldn't open file!", #PB_MessageRequester_Error)
    Else
      Protected sBuf.s
      sBuf = ReadString(hFile, #PB_Ascii | #PB_File_IgnoreEOL, -1)
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
      WriteString(hFile, GetGadgetText(#Editor1), #PB_Ascii)
      CloseFile(hFile)
      gsFilename = sFile
    EndIf
    SetMainTitle()
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
  Define version.s = " v0.0.0.4 (20241302)"
  MessageRequester("Info", "HandyTXTPad" +version + #CRLF$ +
                          "A handy little text editor", #PB_MessageRequester_Info)
EndProcedure
; IDE Options = PureBasic 6.10 beta 6 (Windows - x64)
; CursorPosition = 62
; FirstLine = 39
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = editdocument_24.png
; Executable = pbnotepad.exe