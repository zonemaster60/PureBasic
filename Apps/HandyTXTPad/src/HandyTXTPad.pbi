
Global version.s = "v1.0.1.0"

#WM_CUT   = $0300
#WM_COPY  = $0301
#WM_PASTE = $0302
#WM_UNDO  = $0304
#EM_CANUNDO = $00C6
#EM_CANREDO = $0455
#EM_REDO  = $0454

Structure APP_COPYDATASTRUCT
  dwData.i
  cbData.i
  lpData.i
EndStructure

Procedure.i SendFileToExistingInstance(sFile.s)
  Protected hwnd.i = 0
  Protected candidate.i
  Protected copyData.APP_COPYDATASTRUCT

  Repeat
    candidate = FindWindowEx_(0, candidate, 0, 0)
    If candidate And GetProp_(candidate, #APP_NAME + "_hwnd")
      hwnd = candidate
      Break
    EndIf
  Until candidate = 0

  If hwnd = 0
    ProcedureReturn #False
  EndIf

  copyData\dwData = #APP_COPYDATA_FILE
  copyData\cbData = (Len(sFile) + 1) * SizeOf(Character)
  copyData\lpData = @sFile
  SendMessage_(hwnd, #WM_COPYDATA, 0, @copyData)
  SetForegroundWindow_(hwnd)

  ProcedureReturn #True
EndProcedure

Procedure WindowCallback(hwnd.i, message.i, wParam.i, lParam.i)
  Protected *data.APP_COPYDATASTRUCT
  Protected sFile.s

  If message = #WM_COPYDATA
    *data = lParam
    If *data And *data\dwData = #APP_COPYDATA_FILE And *data\lpData
      sFile = PeekS(*data\lpData)
      If sFile <> ""
        OpenSelectedFile(sFile)
      EndIf
      ProcedureReturn #True
    EndIf
  EndIf

  ProcedureReturn #PB_ProcessPureBasicEvents
EndProcedure

Procedure.i SetRegistryString(rootKey.i, keyPath.s, valueName.s, value.s)
  Protected hKey.i
  Protected result.i

  result = RegCreateKeyEx_(rootKey, keyPath, 0, 0, #REG_OPTION_NON_VOLATILE, #KEY_WRITE, 0, @hKey, 0)
  If result <> 0
    ProcedureReturn #False
  EndIf

  If valueName = ""
    result = RegSetValueEx_(hKey, 0, 0, #REG_SZ, @value, (Len(value) + 1) * SizeOf(Character))
  Else
    result = RegSetValueEx_(hKey, valueName, 0, #REG_SZ, @value, (Len(value) + 1) * SizeOf(Character))
  EndIf

  RegCloseKey_(hKey)
  ProcedureReturn Bool(result = 0)
EndProcedure

Procedure.i RegisterExplorerContextMenuForExtension(extension.s)
  Protected keyPath.s = "Software\Classes\SystemFileAssociations\" + extension + "\shell\HandyTXTPad"
  Protected menuText.s = "Open with " + #APP_NAME
  Protected command.s = #DQUOTE$ + ProgramFilename() + #DQUOTE$ + " " + #DQUOTE$ + "%1" + #DQUOTE$
  Protected success.i = #True

  If SetRegistryString(#HKEY_CURRENT_USER, keyPath, "", menuText) = #False
    success = #False
  EndIf
  If SetRegistryString(#HKEY_CURRENT_USER, keyPath, "MUIVerb", menuText) = #False
    success = #False
  EndIf
  If SetRegistryString(#HKEY_CURRENT_USER, keyPath, "Icon", ProgramFilename()) = #False
    success = #False
  EndIf
  If SetRegistryString(#HKEY_CURRENT_USER, keyPath + "\command", "", command) = #False
    success = #False
  EndIf

  ProcedureReturn success
EndProcedure

Procedure RegisterExplorerContextMenus()
  RegisterExplorerContextMenuForExtension(".txt")
  RegisterExplorerContextMenuForExtension(".pdf")
EndProcedure

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

Procedure.i IsPdfFile(sFile.s)
  ProcedureReturn Bool(UCase(GetExtensionPart(sFile)) = "PDF")
EndProcedure

Procedure.i ContainsReadableText(text.s)
  Protected index.i
  Protected character.i
  Protected readableCount.i

  For index = 1 To Len(text)
    character = Asc(Mid(text, index, 1))
    If (character >= 'A' And character <= 'Z') Or (character >= 'a' And character <= 'z') Or (character >= '0' And character <= '9')
      readableCount + 1
      If readableCount >= 2
        ProcedureReturn #True
      EndIf
    EndIf
  Next index

  ProcedureReturn #False
EndProcedure

Procedure.s DecodePdfLiteralString(encoded.s)
  Protected index.i = 1
  Protected character.s
  Protected nextCharacter.s
  Protected decoded.s
  Protected octalValue.i
  Protected octalDigits.i

  While index <= Len(encoded)
    character = Mid(encoded, index, 1)
    If character = "\" And index < Len(encoded)
      index + 1
      nextCharacter = Mid(encoded, index, 1)
      Select nextCharacter
        Case "n"
          decoded + #LF$
        Case "r"
          decoded + #CR$
        Case "t"
          decoded + Chr(9)
        Case "b"
          decoded + Chr(8)
        Case "f"
          decoded + Chr(12)
        Case "(", ")", "\"
          decoded + nextCharacter
        Case "0", "1", "2", "3", "4", "5", "6", "7"
          octalValue = Val(nextCharacter)
          octalDigits = 1
          While index < Len(encoded) And octalDigits < 3
            nextCharacter = Mid(encoded, index + 1, 1)
            If nextCharacter < "0" Or nextCharacter > "7"
              Break
            EndIf
            index + 1
            octalValue = (octalValue * 8) + Val(nextCharacter)
            octalDigits + 1
          Wend
          decoded + Chr(octalValue)
        Default
          decoded + nextCharacter
      EndSelect
    Else
      decoded + character
    EndIf
    index + 1
  Wend

  ProcedureReturn decoded
EndProcedure

Procedure.s DecodePdfHexString(hexText.s)
  Protected index.i
  Protected value.i
  Protected decoded.s
  Protected cleanHex.s
  Protected character.s

  For index = 1 To Len(hexText)
    character = UCase(Mid(hexText, index, 1))
    If (character >= "0" And character <= "9") Or (character >= "A" And character <= "F")
      cleanHex + character
    EndIf
  Next index

  If Len(cleanHex) < 2
    ProcedureReturn ""
  EndIf

  If Len(cleanHex) % 2 = 1
    cleanHex + "0"
  EndIf

  If Left(cleanHex, 4) = "FEFF"
    index = 5
    While index + 3 <= Len(cleanHex)
      value = Val("$" + Mid(cleanHex, index, 4))
      If value >= 32 Or value = 9 Or value = 10 Or value = 13
        decoded + Chr(value)
      EndIf
      index + 4
    Wend
  Else
    index = 1
    While index + 1 <= Len(cleanHex)
      value = Val("$" + Mid(cleanHex, index, 2))
      If value >= 32 And value <= 126
        decoded + Chr(value)
      EndIf
      index + 2
    Wend
  EndIf

  ProcedureReturn decoded
EndProcedure

Procedure.s ExtractPdfText(rawPdf.s)
  Protected index.i = 1
  Protected depth.i
  Protected character.s
  Protected encoded.s
  Protected decoded.s
  Protected extractedText.s

  While index <= Len(rawPdf)
    character = Mid(rawPdf, index, 1)
    If character = "("
      depth = 1
      encoded = ""
      index + 1
      While index <= Len(rawPdf) And depth > 0
        character = Mid(rawPdf, index, 1)
        If character = "\" And index < Len(rawPdf)
          encoded + character + Mid(rawPdf, index + 1, 1)
          index + 2
        ElseIf character = "("
          depth + 1
          encoded + character
          index + 1
        ElseIf character = ")"
          depth - 1
          If depth > 0
            encoded + character
          EndIf
          index + 1
        Else
          encoded + character
          index + 1
        EndIf
      Wend
      decoded = Trim(DecodePdfLiteralString(encoded))
      If Len(decoded) > 1 And ContainsReadableText(decoded)
        extractedText + decoded + #CRLF$
      EndIf
    ElseIf character = "<" And Mid(rawPdf, index + 1, 1) <> "<"
      encoded = ""
      index + 1
      While index <= Len(rawPdf)
        character = Mid(rawPdf, index, 1)
        If character = ">"
          Break
        EndIf
        encoded + character
        index + 1
      Wend
      decoded = Trim(DecodePdfHexString(encoded))
      If Len(decoded) > 1 And ContainsReadableText(decoded)
        extractedText + decoded + #CRLF$
      EndIf
      index + 1
    Else
      index + 1
    EndIf
  Wend

  ProcedureReturn Trim(extractedText)
EndProcedure

Procedure.s ReadPdfAsSearchableText(sOpenfile.s)
  Protected hFile.i
  Protected fileSize.q
  Protected offset.q
  Protected byte.i
  Protected rawPdf.s
  Protected *buffer

  hFile = ReadFile(#PB_Any, sOpenfile, #PB_File_SharedRead)
  If hFile = 0
    ProcedureReturn ""
  EndIf

  fileSize = Lof(hFile)
  If fileSize <= 0 Or fileSize > 26214400
    CloseFile(hFile)
    ProcedureReturn ""
  EndIf

  *buffer = AllocateMemory(fileSize)
  If *buffer = 0
    CloseFile(hFile)
    ProcedureReturn ""
  EndIf

  ReadData(hFile, *buffer, fileSize)
  CloseFile(hFile)

  For offset = 0 To fileSize - 1
    byte = PeekA(*buffer + offset) & $FF
    If byte >= 9 And byte <> 0
      rawPdf + Chr(byte)
    Else
      rawPdf + " "
    EndIf
  Next offset

  FreeMemory(*buffer)
  ProcedureReturn ExtractPdfText(rawPdf)
EndProcedure

Procedure.i LoadPdfIntoEditor(sOpenfile.s)
  Protected sText.s = ReadPdfAsSearchableText(sOpenfile)

  If sText = ""
    MessageRequester("PDF Import", "No readable text could be extracted from this PDF. Scanned image PDFs and compressed PDF streams may require OCR or a dedicated PDF library.", #PB_MessageRequester_Warning)
    ProcedureReturn #False
  EndIf

  gsFilename = sOpenfile
  gsFileEncoding = "PDF text import"
  gIsPdfDocument = #True
  LoadEditorText(sText)
  AddRecentFile(sOpenfile)
  UpdateStatusBar()
  ProcedureReturn #True
EndProcedure

Procedure.i LoadFileIntoEditor(sOpenfile.s)
  Protected hFile.i
  Protected format.i
  Protected readFormat.i
  Protected sBuf.s

  If IsPdfFile(sOpenfile)
    ProcedureReturn LoadPdfIntoEditor(sOpenfile)
  EndIf

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
  gIsPdfDocument = #False
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
  gIsPdfDocument = #False
  LoadEditorText("")
  UpdateStatusBar()
EndProcedure

Procedure mnuOpen(eventid.i)
  Protected sOpenfile.s = OpenFileRequester("Select file to open...", "", "Supported files (*.txt;*.pdf)|*.txt;*.pdf|Text (*.txt)|*.txt|PDF (*.pdf)|*.pdf|All files (*.*)|*.*", 0)
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
  gIsPdfDocument = #False
  gsSavedText = GetGadgetText(#Editor1)
  SetDirtyState(#False)
  AddRecentFile(sFile)
  UpdateStatusBar()
  ProcedureReturn #True
EndProcedure

Procedure mnuSaveAs(eventid.i)
  Protected defaultFile.s = gsFilename
  Protected sFile.s

  If gIsPdfDocument And IsPdfFile(defaultFile)
    defaultFile = Left(defaultFile, Len(defaultFile) - 4) + ".txt"
  EndIf

  sFile = SaveFileRequester("Save file as...", defaultFile, "Text (*.txt)|*.txt|All files (*.*)|*.*", 0)
  If sFile <> ""
    SaveToFile(sFile)
  EndIf
EndProcedure

Procedure mnuSave(eventid.i)
  If gIsPdfDocument
    MessageRequester("PDF Import", "PDF text imports are saved as text files. Choose a .txt file name to save the extracted text.", #PB_MessageRequester_Info)
    mnuSaveAs(eventid)
  ElseIf gsFilename <> ""
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
; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 1
; Folding = --------
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = editdocument_24.png
; Executable = pbnotepad.exe
