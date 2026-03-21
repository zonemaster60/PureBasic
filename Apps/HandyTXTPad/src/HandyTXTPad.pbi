
Global version.s = "v1.0.0.9"

#WM_CUT   = $0300
#WM_COPY  = $0301
#WM_PASTE = $0302
#WM_UNDO  = $0304
#EM_CANUNDO = $00C6
#EM_CANREDO = $0455
#EM_REDO  = $0454

Procedure.s EncodingName(format.i)
  Select format
    Case #PB_Ascii
      ProcedureReturn "ASCII"
    Case #PB_UTF8
      ProcedureReturn "UTF-8"
    Case #PB_Unicode
      ProcedureReturn "UTF-16 LE"
    Case #PB_UTF16BE
      ProcedureReturn "UTF-16 BE"
    Case #PB_UTF32
      ProcedureReturn "UTF-32 LE"
    Case #PB_UTF32BE
      ProcedureReturn "UTF-32 BE"
  EndSelect

  ProcedureReturn "Unknown"
EndProcedure

Procedure.s PreferencesPath()
  ProcedureReturn AppPath + #PREFS_FILE
EndProcedure

Procedure UpdateRecentFilesMenu()
  Protected menuId.i = #mnuRecent1
  Protected index.i
  Protected text.s

  For index = 0 To #MAX_RECENT_FILES - 1
    If gRecentFiles(index) <> ""
      text = Str(index + 1) + ". " + gRecentFiles(index)
      SetMenuItemText(0, menuId + index, text)
      DisableMenuItem(0, menuId + index, 0)
    Else
      SetMenuItemText(0, menuId + index, Str(index + 1) + ". (Empty)")
      DisableMenuItem(0, menuId + index, 1)
    EndIf
  Next index
EndProcedure

Procedure SaveRecentFiles()
  Protected index.i

  If CreatePreferences(PreferencesPath(), #PB_Preference_GroupSeparator)
    PreferenceGroup("RecentFiles")
    For index = 0 To #MAX_RECENT_FILES - 1
      WritePreferenceString("File" + Str(index), gRecentFiles(index))
    Next index
    ClosePreferences()
  EndIf
EndProcedure

Procedure LoadRecentFiles()
  Protected index.i

  For index = 0 To #MAX_RECENT_FILES - 1
    gRecentFiles(index) = ""
  Next index

  If OpenPreferences(PreferencesPath())
    PreferenceGroup("RecentFiles")
    For index = 0 To #MAX_RECENT_FILES - 1
      gRecentFiles(index) = ReadPreferenceString("File" + Str(index), "")
    Next index
    ClosePreferences()
  EndIf
EndProcedure

Procedure AddRecentFile(sFile.s)
  Protected index.i
  Protected foundIndex.i = -1

  If sFile = ""
    ProcedureReturn
  EndIf

  For index = 0 To #MAX_RECENT_FILES - 1
    If gRecentFiles(index) = sFile
      foundIndex = index
      Break
    EndIf
  Next index

  If foundIndex = -1
    For index = #MAX_RECENT_FILES - 1 To 1 Step -1
      gRecentFiles(index) = gRecentFiles(index - 1)
    Next index
  Else
    For index = foundIndex To 1 Step -1
      gRecentFiles(index) = gRecentFiles(index - 1)
    Next index
  EndIf

  gRecentFiles(0) = sFile

  SaveRecentFiles()
  UpdateRecentFilesMenu()
EndProcedure

Procedure RemoveRecentFile(sFile.s)
  Protected index.i

  For index = 0 To #MAX_RECENT_FILES - 1
    If gRecentFiles(index) = sFile
      While index < #MAX_RECENT_FILES - 1
        gRecentFiles(index) = gRecentFiles(index + 1)
        index + 1
      Wend
      gRecentFiles(#MAX_RECENT_FILES - 1) = ""
      Break
    EndIf
  Next index

  SaveRecentFiles()
  UpdateRecentFilesMenu()
EndProcedure

Procedure.i EditorCanUndo()
  ProcedureReturn Bool(SendMessage_(GadgetID(#Editor1), #EM_CANUNDO, 0, 0) <> 0)
EndProcedure

Procedure.i EditorCanRedo()
  ProcedureReturn Bool(SendMessage_(GadgetID(#Editor1), #EM_CANREDO, 0, 0) <> 0)
EndProcedure

Procedure EditorCut()
  SendMessage_(GadgetID(#Editor1), #WM_CUT, 0, 0)
EndProcedure

Procedure EditorCopy()
  SendMessage_(GadgetID(#Editor1), #WM_COPY, 0, 0)
EndProcedure

Procedure EditorPaste()
  SendMessage_(GadgetID(#Editor1), #WM_PASTE, 0, 0)
EndProcedure

Procedure EditorUndo()
  SendMessage_(GadgetID(#Editor1), #WM_UNDO, 0, 0)
EndProcedure

Procedure EditorRedo()
  SendMessage_(GadgetID(#Editor1), #EM_REDO, 0, 0)
EndProcedure

Procedure SetMainTitle()
  Protected sTitle.s = #APP_NAME
  If gsFilename <> ""
    sTitle + " - [" + GetFilePart(gsFilename) + "]"
  Else
    sTitle + " - [Untitled]"
  EndIf
  If gIsDirty
    sTitle + " *"
  EndIf
  SetWindowTitle(#Dlg1, sTitle)
EndProcedure

Procedure UpdateStatusBar()
  Protected sPath.s

  If gsFilename <> ""
    sPath = gsFilename
  Else
    sPath = "Unsaved document"
  EndIf

  StatusBarText(#StatusBar1, 0, gsFileEncoding)
  StatusBarText(#StatusBar1, 1, sPath)
EndProcedure

Procedure SetDirtyState(isDirty.i)
  gIsDirty = Bool(isDirty)
  SetMainTitle()
  UpdateStatusBar()
EndProcedure

Procedure LoadEditorText(text.s)
  gIsUpdatingEditor = #True
  SetGadgetText(#Editor1, text)
  gsSavedText = text
  gIsUpdatingEditor = #False
  SetDirtyState(#False)
EndProcedure

Procedure.i ConfirmSaveChanges(promptTitle.s, promptText.s)
  Protected response.i

  If gIsDirty = #False
    ProcedureReturn #True
  EndIf

  response = MessageRequester(promptTitle, promptText, #PB_MessageRequester_YesNoCancel | #PB_MessageRequester_Info)

  Select response
    Case #PB_MessageRequester_Yes
      mnuSave(0)
      ProcedureReturn Bool(gIsDirty = #False)
    Case #PB_MessageRequester_No
      ProcedureReturn #True
  EndSelect

  ProcedureReturn #False
EndProcedure

Procedure.i RequestExit()
  ProcedureReturn ConfirmSaveChanges("Exit", "Save changes before exiting?")
EndProcedure

Procedure.i LoadFileIntoEditor(sOpenfile.s)
  Protected hFile.i
  Protected format.i
  Protected readFormat.i
  Protected sBuf.s

  hFile = ReadFile(#PB_Any, sOpenfile, #PB_File_SharedRead)
  If hFile = 0
    MessageRequester("Error", "Couldn't open file!", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  format = ReadStringFormat(hFile)
  gsFileEncoding = EncodingName(format)

  Select format
    Case #PB_Ascii, #PB_UTF8, #PB_Unicode
      readFormat = format
    Default
      CloseFile(hFile)
      MessageRequester("Error", "This file encoding is not supported.", #PB_MessageRequester_Error)
      ProcedureReturn #False
  EndSelect

  While Eof(hFile) = 0
    sBuf + ReadString(hFile, readFormat | #PB_File_IgnoreEOL)
  Wend
  CloseFile(hFile)

  gsFilename = sOpenfile
  LoadEditorText(sBuf)
  AddRecentFile(sOpenfile)
  UpdateStatusBar()
  ProcedureReturn #True
EndProcedure

Procedure OpenRecentFile(index.i)
  If index < 0 Or index >= #MAX_RECENT_FILES
    ProcedureReturn
  EndIf

  If gRecentFiles(index) = ""
    ProcedureReturn
  EndIf

  If FileSize(gRecentFiles(index)) < 0
    MessageRequester("Error", "The recent file could not be found.", #PB_MessageRequester_Error)
    RemoveRecentFile(gRecentFiles(index))
    ProcedureReturn
  EndIf

  OpenSelectedFile(gRecentFiles(index))
EndProcedure

Procedure.i OpenSelectedFile(sOpenfile.s)
  If sOpenfile = ""
    ProcedureReturn #False
  EndIf

  If ConfirmSaveChanges("Open", "Save changes before opening another file?") = #False
    ProcedureReturn #False
  EndIf

  ProcedureReturn LoadFileIntoEditor(sOpenfile)
EndProcedure

Procedure HandleEditorChanged()
  If gIsUpdatingEditor
    ProcedureReturn
  EndIf

  SetDirtyState(Bool(GetGadgetText(#Editor1) <> gsSavedText))
EndProcedure

Procedure HandleWindowDrop()
  Protected sFiles.s
  Protected sFirstFile.s

  If EventDropType() <> #PB_Drop_Files
    ProcedureReturn
  EndIf

  sFiles = EventDropFiles()
  If sFiles = ""
    ProcedureReturn
  EndIf

  sFirstFile = StringField(sFiles, 1, Chr(10))
  OpenSelectedFile(sFirstFile)
EndProcedure

Procedure mnuNew(eventid.i)
  If ConfirmSaveChanges("New", "Save changes before creating a new document?") = #False
    ProcedureReturn
  EndIf

  gsFilename = ""
  gsFileEncoding = "UTF-8"
  LoadEditorText("")
  UpdateStatusBar()
EndProcedure

Procedure mnuOpen(eventid.i)
  Protected sOpenfile.s = OpenFileRequester("Select file to open...", "", "Text (*.txt)|*.txt|All files (*.*)|*.*", 0)
  OpenSelectedFile(sOpenfile)
EndProcedure

Procedure.i SaveToFile(sFile.s)
  Protected hFile = CreateFile(#PB_Any, sFile)
  If hFile = 0
    MessageRequester("Error", "Couldn't create file!", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  WriteStringFormat(hFile, #PB_UTF8)
  WriteString(hFile, GetGadgetText(#Editor1), #PB_UTF8)
  CloseFile(hFile)

  gsFilename = sFile
  gsFileEncoding = "UTF-8"
  gsSavedText = GetGadgetText(#Editor1)
  SetDirtyState(#False)
  AddRecentFile(sFile)
  UpdateStatusBar()
  ProcedureReturn #True
EndProcedure

Procedure mnuSaveAs(eventid.i)
  Protected sFile.s = SaveFileRequester("Save file as...", gsFilename, "Text (*.txt)|*.txt|All files (*.*)|*.*", 0)
  If sFile <> ""
    SaveToFile(sFile)
  EndIf
EndProcedure

Procedure mnuSave(eventid.i)
  If gsFilename <> ""
    SaveToFile(gsFilename)
  Else
    mnuSaveAs(eventid)
  EndIf
EndProcedure

Procedure mnuUndo(eventid.i)
  If EditorCanUndo()
    EditorUndo()
  EndIf
EndProcedure

Procedure mnuRedo(eventid.i)
  If EditorCanRedo()
    EditorRedo()
  EndIf
EndProcedure

Procedure mnuCut(eventid.i)
  EditorCut()
EndProcedure

Procedure mnuCopy(eventid.i)
  EditorCopy()
EndProcedure

Procedure mnuPaste(eventid.i)
  EditorPaste()
EndProcedure

Procedure mnuExit(eventid.i)
  If RequestExit()
    gShouldExit = #True
  EndIf
EndProcedure

Procedure mnuAbout(eventid.i)
  MessageRequester("Info", #APP_NAME + " - " + version + #CRLF$ +
                           "A handy little text editor" + #CRLF$ +
                           "----------------------------------------" + #CRLF$ +
                           "Contact: " + #EMAIL_NAME + #CRLF$ +
                           "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
EndProcedure
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 1
; Folding = -------
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = editdocument_24.png
; Executable = pbnotepad.exe