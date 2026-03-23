; Editor, search, registry operations, export, compact

;- Tree Loading

Procedure LoadKeysThread(param.i)
  Protected *p.LoadKeysParams = param
  If *p = 0 : ProcedureReturn : EndIf
  
  Protected parentItem.i = *p\ParentItem
  Protected rootKey.i = *p\RootKey
  Protected keyPath.s = *p\KeyPath
  Protected sam.l = *p\SAM
  FreeStructure(*p)
  
  Protected i.i, count.i, subKeyName.s
  Protected ret.Registry::RegValue
  Protected wow64.i = GetRegistryWow64Flag(sam)
  
  ; Create result structure immediately
  Protected *res.LoadKeysThreadResult = AllocateStructure(LoadKeysThreadResult)
  If Not *res : ProcedureReturn : EndIf
  *res\ParentItem = parentItem

  LogInfo("LoadKeysThread", "Attempting load for TopKey: " + Hex(rootKey) + " Path: '" + keyPath + "'")
  
  ; 1. Fast Count
  count = Registry::CountSubKeys(rootKey, keyPath, wow64, @ret)
  If ret\ERROR <> 0
    LogError("LoadKeysThread", "Registry Error " + Str(ret\ERROR) + ": " + ret\ERRORSTR + " (Path: " + keyPath + ")")
    *res\Error = ret\ERROR
    *res\ErrorStr = ret\ERRORSTR
    PostEvent(#EVENT_LOAD_COMPLETE, #WINDOW_MAIN, #GADGET_TREE, 0, *res)
    ProcedureReturn
  EndIf

  If count = 0
    PostEvent(#EVENT_LOAD_COMPLETE, #WINDOW_MAIN, #GADGET_TREE, 0, *res)
    ProcedureReturn
  EndIf

  ; 2. Collect Names
  Protected maxKeys.i = 5000
  If count > maxKeys : count = maxKeys : EndIf
  
  For i = 0 To count - 1
    subKeyName = Registry::ListSubKey(rootKey, keyPath, i, wow64, @ret)
    If subKeyName <> ""
      AddElement(*res\SubKeys())
      *res\SubKeys() = subKeyName
    EndIf
  Next
  
  PostEvent(#EVENT_LOAD_COMPLETE, #WINDOW_MAIN, #GADGET_TREE, 0, *res)
EndProcedure

Procedure.i LoadSubKeys(parentItem.i, rootKey.i, keyPath.s, sam.l = 0)
  If Not LoadKeysMutex : LoadKeysMutex = CreateMutex() : EndIf
  
  LockMutex(LoadKeysMutex)
  ; Check if a thread is already loading this specific item
  If FindMapElement(ActiveLoadThreads(), Str(parentItem))
    UnlockMutex(LoadKeysMutex)
    ProcedureReturn #False 
  EndIf
  UnlockMutex(LoadKeysMutex)
  
  If sam = 0 : sam = GetDefaultSAM() : EndIf
  
  Protected *p.LoadKeysParams = AllocateStructure(LoadKeysParams)
  If *p
    *p\ParentItem = parentItem
    *p\RootKey = rootKey
    *p\KeyPath = keyPath
    *p\SAM = sam
    
    LockMutex(LoadKeysMutex)
    Protected thread = CreateThread(@LoadKeysThread(), *p)
    If thread
      ActiveLoadThreads(Str(parentItem)) = thread
    Else
      FreeStructure(*p)
    EndIf
    UnlockMutex(LoadKeysMutex)
    
    ProcedureReturn #True
  EndIf
  
  ProcedureReturn #False
EndProcedure

;- Search Engine

Procedure RecursiveSearchInternal(rootKey.i, currentPath.s, searchStr.s, wow64.i, searchKeys.i, searchValues.i, searchData.i)
  Protected i.i, subKeyCount.i, valueCount.i, subKeyName.s, valueName.s, valueData.s, valueType.i
  Protected ret.Registry::RegValue
  
  If SearchStopRequested : ProcedureReturn : EndIf
  
  ; 1. Search in Values and Data of current path
  If searchValues Or searchData
    valueCount = Registry::CountSubValues(rootKey, currentPath, wow64, @ret)
    For i = 0 To valueCount - 1
      If SearchStopRequested : Break : EndIf
      valueName = Registry::ListSubValue(rootKey, currentPath, i, wow64, @ret)
      
      Protected match.i = #False
      If searchValues And FindString(valueName, searchStr, 1, #PB_String_NoCase)
        match = #True
      ElseIf searchData
        valueData = Registry::ReadValue(rootKey, currentPath, valueName, wow64, @ret)
        If FindString(valueData, searchStr, 1, #PB_String_NoCase)
          match = #True
        EndIf
        If ret\BINARY : FreeMemory(ret\BINARY) : EndIf
      EndIf
      
      If match
        If Not SearchResultsMutex : SearchResultsMutex = CreateMutex() : EndIf
        LockMutex(SearchResultsMutex)
        AddElement(SearchResults())
        SearchResults()\RootKey = rootKey
        SearchResults()\KeyPath = currentPath
        SearchResults()\ValueName = valueName
        SearchResults()\ValueType = Registry::ReadType(rootKey, currentPath, valueName, wow64, @ret)
        SearchResults()\ValueData = Registry::ReadValue(rootKey, currentPath, valueName, wow64, @ret)
        If ret\BINARY : FreeMemory(ret\BINARY) : EndIf
        UnlockMutex(SearchResultsMutex)
      EndIf
    Next
  EndIf
  
  ; 2. Search in subkeys (recursive)
  subKeyCount = Registry::CountSubKeys(rootKey, currentPath, wow64, @ret)
  For i = 0 To subKeyCount - 1
    If SearchStopRequested : Break : EndIf
    subKeyName = Registry::ListSubKey(rootKey, currentPath, i, wow64, @ret)
    
    If searchKeys And FindString(subKeyName, searchStr, 1, #PB_String_NoCase)
      If Not SearchResultsMutex : SearchResultsMutex = CreateMutex() : EndIf
      LockMutex(SearchResultsMutex)
      AddElement(SearchResults())
      SearchResults()\RootKey = rootKey
      SearchResults()\KeyPath = currentPath + "\" + subKeyName
      SearchResults()\ValueName = "(Key Match)"
      UnlockMutex(SearchResultsMutex)
    EndIf
    
    Define nextPath.s = currentPath
    If nextPath <> "" : nextPath + "\" : EndIf
    nextPath + subKeyName
    RecursiveSearchInternal(rootKey, nextPath, searchStr, wow64, searchKeys, searchValues, searchData)
  Next
EndProcedure

Procedure SearchThread(param.i)
  Protected *p.SearchThreadParams = param
  If *p = 0 : ProcedureReturn : EndIf
  
  Protected searchStr.s = *p\SearchString
  Protected rootKey.i = *p\RootKey
  Protected keyPath.s = *p\KeyPath
  Protected sKeys.i = *p\SearchKeys
  Protected sVals.i = *p\SearchValues
  Protected sData.i = *p\SearchData
  FreeStructure(*p)
  
  Protected wow64.i = GetRegistryWow64Flag()
  
  If Not SearchResultsMutex : SearchResultsMutex = CreateMutex() : EndIf
  LogInfo("SearchThread", "Starting recursive search for: " + searchStr)
  RecursiveSearchInternal(rootKey, keyPath, searchStr, wow64, sKeys, sVals, sData)

  
  SearchThreadID = 0
  If SearchStopRequested
    LogInfo("SearchThread", "Search cancelled by user")
  Else
    LockMutex(SearchResultsMutex)
    Protected resultCount.i = ListSize(SearchResults())
    UnlockMutex(SearchResultsMutex)
    LogInfo("SearchThread", "Search completed. Found " + Str(resultCount) + " matches.")
  EndIf
EndProcedure

;- Hex Editor

Structure HexEditorContext
  Window.i
  Grid.i
  Input.i
  Buffer.i
  DataSize.i
  SelectedRow.i
  SelectedByte.i
EndStructure

Procedure UpdateHexRow(context.i, row.i)
  Protected *ctx.HexEditorContext = context
  Protected updatedHex.s = ""
  Protected updatedAscii.s = ""
  Protected byteVal.i, i.i
  
  For i = 0 To 15
    If (row * 16 + i) < *ctx\DataSize
      byteVal = PeekA(*ctx\Buffer + row * 16 + i) & $FF
      updatedHex + RSet(Hex(byteVal), 2, "0") + " "
      If byteVal >= 32 And byteVal <= 126 : updatedAscii + Chr(byteVal) : Else : updatedAscii + "." : EndIf
    Else
      updatedHex + "   "
    EndIf
  Next
  SetGadgetItemText(*ctx\Grid, row, updatedHex, 1)
  SetGadgetItemText(*ctx\Grid, row, updatedAscii, 2)
EndProcedure

Procedure OpenHexEditor(rootKey.i, keyPath.s, valueName.s, filePath.s = "")
  Protected ret.Registry::RegValue
  Protected wow64.i = GetRegistryWow64Flag()
  Protected ctx.HexEditorContext
  Protected isFile.i = #False
  
  If filePath <> ""
    isFile = #True
    Define file = ReadFile(#PB_Any, filePath)
    If file
      ctx\DataSize = FileSize(filePath)
      ctx\Buffer = AllocateMemory(ctx\DataSize)
      If Not ctx\Buffer And ctx\DataSize > 0
        CloseFile(file)
        MessageRequester("Error", "Not enough memory to load file into the hex editor.", #PB_MessageRequester_Error)
        ProcedureReturn
      EndIf
      If ctx\Buffer : ReadData(file, ctx\Buffer, ctx\DataSize) : EndIf
      CloseFile(file)
    Else
      MessageRequester("Error", "Could not open file: " + filePath, #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
  Else
    Registry::ReadValue(rootKey, keyPath, valueName, wow64, @ret)
    
    If ret\TYPE <> #REG_BINARY Or ret\BINARY = 0
      MessageRequester("Error", "Selected value is not binary data or could not be read.", #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
    
    ctx\DataSize = ret\SIZE
    ctx\Buffer = AllocateMemory(ctx\DataSize)
    If Not ctx\Buffer And ctx\DataSize > 0
      If ret\BINARY : FreeMemory(ret\BINARY) : EndIf
      MessageRequester("Error", "Not enough memory to load binary registry data.", #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
    If ctx\Buffer : CopyMemory(ret\BINARY, ctx\Buffer, ctx\DataSize) : EndIf
  EndIf
  
  Protected winWidth = 620
  Protected winHeight = 500
  Protected title.s = "Hex Editor: " + valueName
  If isFile : title = "Hex Editor: " + GetFilePart(filePath) : EndIf
  
  ctx\Window = OpenWindow(#PB_Any, 0, 0, winWidth, winHeight, title, #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
  
  If ctx\Window
    ctx\Grid = ListIconGadget(#PB_Any, 10, 10, winWidth - 20, winHeight - 80, "Address", 80, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(ctx\Grid, 1, "00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F", 370)
    AddGadgetColumn(ctx\Grid, 2, "ASCII", 130)
    
    SetWindowTheme(GadgetID(ctx\Grid), "Explorer", 0)

    Protected i.i, row.s, hexPart.s, asciiPart.s, byte.i
    SendMessage_(GadgetID(ctx\Grid), #WM_SETREDRAW, #False, 0)
    For i = 0 To ctx\DataSize - 1 Step 16
      row = RSet(Hex(i), 8, "0") + Chr(10)
      hexPart = "" : asciiPart = ""
      Protected j.i
      For j = 0 To 15
        If (i + j) < ctx\DataSize
          byte = PeekA(ctx\Buffer + i + j) & $FF
          hexPart + RSet(Hex(byte), 2, "0") + " "
          If byte >= 32 And byte <= 126 : asciiPart + Chr(byte) : Else : asciiPart + "." : EndIf
        Else
          hexPart + "   "
        EndIf
      Next
      AddGadgetItem(ctx\Grid, -1, row + hexPart + Chr(10) + asciiPart)
    Next
    SendMessage_(GadgetID(ctx\Grid), #WM_SETREDRAW, #True, 0)
    
    ctx\Input = StringGadget(#PB_Any, 0, 0, 0, 0, "", #PB_String_UpperCase)
    HideGadget(ctx\Input, #True)
    SetGadgetAttribute(ctx\Input, #PB_String_MaximumLength, 2)
    
    ButtonGadget(#GADGET_VALUE_EDITOR_HEX_SAVE, winWidth - 220, winHeight - 40, 100, 30, "Save")
    ButtonGadget(#GADGET_VALUE_EDITOR_HEX_CANCEL, winWidth - 110, winHeight - 40, 100, 30, "Cancel")
    TextGadget(#PB_Any, 15, winHeight - 35, 350, 20, "Tip: Double-click a byte to edit in-place.")
    
    ctx\SelectedRow = -1
    ctx\SelectedByte = -1
    
    Repeat
      Protected ev = WaitWindowEvent(10)
      If ev = #PB_Event_CloseWindow And EventWindow() = ctx\Window
        Break
      ElseIf ev = #PB_Event_Gadget
        Protected gadget = EventGadget()
        If gadget = #GADGET_VALUE_EDITOR_HEX_CANCEL
          Break
        ElseIf gadget = #GADGET_VALUE_EDITOR_HEX_SAVE
          If isFile
             Define saveFile = CreateFile(#PB_Any, filePath)
             If saveFile
               WriteData(saveFile, ctx\Buffer, ctx\DataSize)
               CloseFile(saveFile)
               UpdateStatusBar("File saved: " + GetFilePart(filePath))
               Break
             Else
               MessageRequester("Error", "Failed to save file: " + filePath, #PB_MessageRequester_Error)
             EndIf
          Else
            If EnsureBackupBeforeChange("Hex edit registry value: " + valueName)
              Protected saveRet.Registry::RegValue
              saveRet\BINARY = ctx\Buffer
              saveRet\SIZE = ctx\DataSize
              saveRet\TYPE = #REG_BINARY
              If Registry::WriteValue(rootKey, keyPath, valueName, "", #REG_BINARY, wow64, @saveRet)
                UpdateStatusBar("Binary value saved")
                LoadValues(rootKey, keyPath, GetDefaultSAM())
                Break
              Else
                MessageRequester("Error", "Failed to save binary value: " + saveRet\ERRORSTR, #PB_MessageRequester_Error)
              EndIf
            EndIf
          EndIf
        ElseIf gadget = ctx\Grid And EventType() = #PB_EventType_LeftDoubleClick
          ; --- In-place editing logic ---
          Protected selRow = GetGadgetState(ctx\Grid)
          If selRow <> -1
            Protected p.POINT
            GetCursorPos_(@p)
            ScreenToClient_(GadgetID(ctx\Grid), @p)
            
            ; 80px address col, then bytes are roughly 23px each (370/16)
            Protected clickX = p\x - 80
            If clickX > 0 And clickX < 370
              Protected byteIdx = clickX / 23
              If (selRow * 16 + byteIdx) < ctx\DataSize
                ctx\SelectedRow = selRow
                ctx\SelectedByte = byteIdx
                
                ; Position the input gadget overlay
                Protected rect.RECT
                rect\top = 1
                SendMessage_(GadgetID(ctx\Grid), #LVM_GETSUBITEMRECT, selRow, @rect)
                ResizeGadget(ctx\Input, rect\left + (byteIdx * 23), rect\top + 1, 22, rect\bottom - rect\top - 2)
                SetGadgetText(ctx\Input, RSet(Hex(PeekA(ctx\Buffer + selRow * 16 + byteIdx) & $FF), 2, "0"))
                HideGadget(ctx\Input, #False)
                SetActiveGadget(ctx\Input)
                SendMessage_(GadgetID(ctx\Input), #EM_SETSEL, 0, -1) ; Select all text in the overlay input
              EndIf
            EndIf
          EndIf
        ElseIf gadget = ctx\Input
          If EventType() = #PB_EventType_LostFocus
            HideGadget(ctx\Input, #True)
          EndIf
        EndIf
      ElseIf ev = #PB_Event_Menu ; Catch Enter key in input
        If GetActiveGadget() = ctx\Input
          Protected newVal.s = GetGadgetText(ctx\Input)
          If Len(newVal) = 2 And FindString("0123456789ABCDEF", Left(newVal, 1), 1) And FindString("0123456789ABCDEF", Right(newVal, 1), 1)
            PokeA(ctx\Buffer + ctx\SelectedRow * 16 + ctx\SelectedByte, Val("$" + newVal))
            UpdateHexRow(@ctx, ctx\SelectedRow)
          ElseIf newVal <> ""
            MessageRequester("Invalid Byte", "Enter exactly two hexadecimal characters (00-FF).", #PB_MessageRequester_Warning)
          EndIf
          HideGadget(ctx\Input, #True)
          SetActiveGadget(ctx\Grid)
        EndIf
      EndIf
    ForEver
    
    If ctx\Buffer : FreeMemory(ctx\Buffer) : EndIf
    CloseWindow(ctx\Window)
  EndIf
  If Not isFile And ret\BINARY : FreeMemory(ret\BINARY) : EndIf
EndProcedure

;- Value Editor

Procedure OpenValueEditor(rootKey.i, keyPath.s, valueName.s = "")
  Protected isNew.i = #True
  If valueName <> "" : isNew = #False : EndIf
  
  Protected winTitle.s = "New Value"
  If Not isNew : winTitle = "Edit Value: " + valueName : EndIf
  
  Protected win = OpenWindow(#PB_Any, 0, 0, 450, 320, winTitle, #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
  If win
    TextGadget(#PB_Any, 10, 15, 80, 20, "Name:")
    StringGadget(#GADGET_VALUE_EDITOR_NAME, 90, 10, 340, 25, valueName)
    If Not isNew : DisableGadget(#GADGET_VALUE_EDITOR_NAME, #True) : EndIf
    
    TextGadget(#PB_Any, 10, 50, 80, 20, "Type:")
    ComboBoxGadget(#GADGET_VALUE_EDITOR_TYPE, 90, 45, 340, 25)
    AddGadgetItem(#GADGET_VALUE_EDITOR_TYPE, -1, "REG_SZ")
    AddGadgetItem(#GADGET_VALUE_EDITOR_TYPE, -1, "REG_DWORD")
    AddGadgetItem(#GADGET_VALUE_EDITOR_TYPE, -1, "REG_QWORD")
    AddGadgetItem(#GADGET_VALUE_EDITOR_TYPE, -1, "REG_EXPAND_SZ")
    AddGadgetItem(#GADGET_VALUE_EDITOR_TYPE, -1, "REG_BINARY")
    
    Protected currentType.i = #REG_SZ
    Protected currentData.s = ""
    If Not isNew
      Protected ret.Registry::RegValue
      currentType = Registry::ReadType(rootKey, keyPath, valueName, GetRegistryWow64Flag(), @ret)
      currentData = Registry::ReadValue(rootKey, keyPath, valueName, GetRegistryWow64Flag(), @ret)
      ; Clean up BINARY if it was allocated
      If ret\BINARY : FreeMemory(ret\BINARY) : EndIf
    EndIf
    
    Select currentType
      Case #REG_DWORD : SetGadgetState(#GADGET_VALUE_EDITOR_TYPE, 1)
      Case #REG_QWORD : SetGadgetState(#GADGET_VALUE_EDITOR_TYPE, 2)
      Case #REG_EXPAND_SZ : SetGadgetState(#GADGET_VALUE_EDITOR_TYPE, 3)
      Case #REG_BINARY : SetGadgetState(#GADGET_VALUE_EDITOR_TYPE, 4)
      Default : SetGadgetState(#GADGET_VALUE_EDITOR_TYPE, 0)
    EndSelect
    
    TextGadget(#PB_Any, 10, 85, 80, 20, "Value Data:")
    EditorGadget(#GADGET_VALUE_EDITOR_DATA, 90, 80, 340, 120, #PB_Editor_WordWrap)
    SetGadgetText(#GADGET_VALUE_EDITOR_DATA, currentData)
    
    ; Hex Editor Launch Button
    Protected btnHexEdit = ButtonGadget(#PB_Any, 90, 205, 120, 25, "Open Hex Editor...")
    If currentType <> #REG_BINARY : DisableGadget(btnHexEdit, #True) : EndIf
    
    ; DWORD/QWORD options
    OptionGadget(#GADGET_VALUE_EDITOR_HEX, 230, 210, 80, 20, "Hexadecimal")
    OptionGadget(#GADGET_VALUE_EDITOR_DEC, 320, 210, 80, 20, "Decimal")
    SetGadgetState(#GADGET_VALUE_EDITOR_DEC, #True)
    If currentType <> #REG_DWORD And currentType <> #REG_QWORD
      DisableGadget(#GADGET_VALUE_EDITOR_HEX, #True)
      DisableGadget(#GADGET_VALUE_EDITOR_DEC, #True)
    EndIf
    
    ButtonGadget(#GADGET_VALUE_EDITOR_OK, 230, 270, 100, 30, "OK")
    ButtonGadget(#GADGET_VALUE_EDITOR_CANCEL, 340, 270, 100, 30, "Cancel")
    
    Repeat
      Define ev = WaitWindowEvent()
      If ev = #PB_Event_CloseWindow And EventWindow() = win
        Break
      ElseIf ev = #PB_Event_Gadget
        If EventGadget() = #GADGET_VALUE_EDITOR_CANCEL
          Break
        ElseIf EventGadget() = btnHexEdit
          OpenHexEditor(rootKey, keyPath, valueName)
        ElseIf EventGadget() = #GADGET_VALUE_EDITOR_TYPE
          Protected st = GetGadgetState(#GADGET_VALUE_EDITOR_TYPE)
          If st = 4 ; REG_BINARY
            DisableGadget(btnHexEdit, #False)
            DisableGadget(#GADGET_VALUE_EDITOR_HEX, #True)
            DisableGadget(#GADGET_VALUE_EDITOR_DEC, #True)
          ElseIf st = 1 Or st = 2 ; DWORD/QWORD
            DisableGadget(btnHexEdit, #True)
            DisableGadget(#GADGET_VALUE_EDITOR_HEX, #False)
            DisableGadget(#GADGET_VALUE_EDITOR_DEC, #False)
          Else
            DisableGadget(btnHexEdit, #True)
            DisableGadget(#GADGET_VALUE_EDITOR_HEX, #True)
            DisableGadget(#GADGET_VALUE_EDITOR_DEC, #True)
          EndIf
        ElseIf EventGadget() = #GADGET_VALUE_EDITOR_OK
          Define nName.s = GetGadgetText(#GADGET_VALUE_EDITOR_NAME)
          Define nTypeIdx.i = GetGadgetState(#GADGET_VALUE_EDITOR_TYPE)
          Define nData.s = GetGadgetText(#GADGET_VALUE_EDITOR_DATA)
          Define nType.i = #REG_SZ
          Select nTypeIdx
            Case 1 : nType = #REG_DWORD
            Case 2 : nType = #REG_QWORD
            Case 3 : nType = #REG_EXPAND_SZ
            Case 4 : nType = #REG_BINARY
          EndSelect

          If nType = #REG_DWORD Or nType = #REG_QWORD
            If GetGadgetState(#GADGET_VALUE_EDITOR_HEX)
              If Left(LCase(nData), 2) = "0x"
                nData = Mid(nData, 3)
              EndIf
              If Left(nData, 1) <> "$"
                nData = "$" + nData
              EndIf
            EndIf
          EndIf
          
          If nName <> ""
            If WriteRegistryValue(rootKey, keyPath, nName, nData, nType, GetDefaultSAM())
              LoadValues(rootKey, keyPath, GetDefaultSAM())
              Break
            EndIf
          EndIf
        EndIf
      EndIf
    ForEver
    CloseWindow(win)
  EndIf
EndProcedure

;- Search Window

Procedure OpenSearchWindow()
  If IsWindow(#WINDOW_SEARCH)
    StickyWindow(#WINDOW_SEARCH, #True)
    ProcedureReturn
  EndIf
  
  If OpenWindow(#WINDOW_SEARCH, 0, 0, 800, 500, "Registry Search - " + GetRootKeyName(CurrentRootKey) + "\" + CurrentKeyPath, #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
    TextGadget(#PB_Any, 10, 15, 80, 20, "Find what:")
    StringGadget(#GADGET_SEARCH_STRING, 90, 10, 500, 25, "")
    
    CheckBoxGadget(#GADGET_SEARCH_KEYS, 90, 40, 60, 20, "Keys")
    CheckBoxGadget(#GADGET_SEARCH_VALUES, 160, 40, 70, 20, "Values")
    CheckBoxGadget(#GADGET_SEARCH_DATA, 240, 40, 60, 20, "Data")
    SetGadgetState(#GADGET_SEARCH_KEYS, #True)
    SetGadgetState(#GADGET_SEARCH_VALUES, #True)
    SetGadgetState(#GADGET_SEARCH_DATA, #True)
    
    ButtonGadget(#GADGET_SEARCH_START, 600, 10, 90, 25, "Search")
    ButtonGadget(#GADGET_SEARCH_STOP, 700, 10, 90, 25, "Stop")
    DisableGadget(#GADGET_SEARCH_STOP, #True)
    
    ListIconGadget(#GADGET_SEARCH_RESULTS, 10, 65, 780, 400, "Path", 300, #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_GridLines)

    SetWindowTheme(GadgetID(#GADGET_SEARCH_RESULTS), "Explorer", 0)

    AddGadgetColumn(#GADGET_SEARCH_RESULTS, 1, "Name", 150)

    AddGadgetColumn(#GADGET_SEARCH_RESULTS, 2, "Type", 100)
    AddGadgetColumn(#GADGET_SEARCH_RESULTS, 3, "Data", 210)
    
    TextGadget(#GADGET_SEARCH_STATUS, 10, 475, 780, 20, "Ready to search.")
  EndIf
EndProcedure


;- Value Loading



Procedure LoadValuesThread(param.i)
  Protected *p.LoadValuesParams = param
  If *p = 0 : ProcedureReturn : EndIf
  
  Protected rootKey.i = *p\RootKey
  Protected keyPath.s = *p\KeyPath
  Protected sam.l = *p\SAM
  FreeStructure(*p)
  
  Protected i.i, count.i, valueName.s, valueData.s, valueType.i
  Protected ret.Registry::RegValue
  Protected wow64.i = GetRegistryWow64Flag(sam)
  
  Protected *res.LoadValuesResult = AllocateStructure(LoadValuesResult)
  If Not *res : ProcedureReturn : EndIf
  
  LogInfo("LoadValuesThread", "Loading values from: " + GetRootKeyName(rootKey) + " Path: '" + keyPath + "'")
  
  count = Registry::CountSubValues(rootKey, keyPath, wow64, @ret)
  If ret\ERROR <> 0
    LogError("LoadValuesThread", "Registry Error " + Str(ret\ERROR) + " (" + ret\ERRORSTR + ") for path: " + keyPath)
    *res\Error = ret\ERROR
    *res\ErrorStr = ret\ERRORSTR
    PostEvent(#EVENT_LOAD_VALUES_COMPLETE, #WINDOW_MAIN, #GADGET_LISTVIEW, 0, *res)
    ProcedureReturn
  EndIf
  
  *res\Count = count
  
  If count > 0
    For i = 0 To count - 1
      valueName = Registry::ListSubValue(rootKey, keyPath, i, wow64, @ret)
      If ret\ERROR <> 0 : Continue : EndIf
      
      If valueName <> ""
        valueType = Registry::ReadType(rootKey, keyPath, valueName, wow64, @ret)
        valueData = Registry::ReadValue(rootKey, keyPath, valueName, wow64, @ret)
        
        AddElement(*res\Values())
        *res\Values()\Name = valueName
        *res\Values()\Type = valueType
        *res\Values()\Data = valueData
        If ret\BINARY : FreeMemory(ret\BINARY) : EndIf
      EndIf
      
      ; Optional: Cap for massive keys like CLSID to keep it usable
      If i > 5000 : Break : EndIf 
    Next
  EndIf
  
  PostEvent(#EVENT_LOAD_VALUES_COMPLETE, #WINDOW_MAIN, #GADGET_LISTVIEW, 0, *res)
EndProcedure

Procedure LoadValues(rootKey.i, keyPath.s, sam.l = 0)
  If Not IsGadget(#GADGET_LISTVIEW)
    LogError("LoadValues", "ListView gadget not available")
    ProcedureReturn #False
  EndIf
  
  If sam = 0 : sam = GetDefaultSAM() : EndIf
  If Not LoadValuesMutex : LoadValuesMutex = CreateMutex() : EndIf
  
  ; Clear current view immediately
  SendMessage_(GadgetID(#GADGET_LISTVIEW), #WM_SETREDRAW, #False, 0)
  ClearGadgetItems(#GADGET_LISTVIEW)
  ClearList(RegValues())
  SendMessage_(GadgetID(#GADGET_LISTVIEW), #WM_SETREDRAW, #True, 0)
  InvalidateRect_(GadgetID(#GADGET_LISTVIEW), 0, #True)
  
  UpdateStatusBar("Loading values...")
  
  ; Launch thread
  Protected *p.LoadValuesParams = AllocateStructure(LoadValuesParams)
  If *p
    *p\RootKey = rootKey
    *p\KeyPath = keyPath
    *p\SAM = sam
    
    LockMutex(LoadValuesMutex)
    If LoadValuesThreadID And IsThread(LoadValuesThreadID)
      ; We don't necessarily kill it, but we could if needed. 
      ; For simplicity, we just launch the new one.
    EndIf
    LoadValuesThreadID = CreateThread(@LoadValuesThread(), *p)
    UnlockMutex(LoadValuesMutex)
    
    ProcedureReturn #True
  EndIf
  
  ProcedureReturn #False
EndProcedure


;- Registry Modification

Procedure.i CreateRegistryKey(rootKey.i, keyPath.s, sam.l = #KEY_ALL_ACCESS)
  Protected ret.Registry::RegValue
  Protected hKey.i, create.i
  
  ; Ensure backup before modification
  If Not EnsureBackupBeforeChange("Create registry key: " + GetRootKeyName(rootKey) + "\" + keyPath)
    ProcedureReturn #False
  EndIf
  
  LogInfo("CreateRegistryKey", "Creating key: " + GetRootKeyName(rootKey) + "\" + keyPath + " with SAM: " + Hex(sam))
  
  ; Using the Registry module's logic via RegCreateKeyEx_ directly or extending the module
  ; For consistency, let's use the API with the provided SAM
  If RegCreateKeyEx_(rootKey, keyPath, 0, #Null$, 0, sam, 0, @hKey, @create) = 0
    RegCloseKey_(hKey)
    LogInfo("CreateRegistryKey", "Successfully created/opened key (Result: " + Str(create) + ")")
    UpdateStatusBar("Key created successfully")
    ProcedureReturn #True
  Else
    LogError("CreateRegistryKey", "Failed to create key")
    UpdateStatusBar("Error: Failed to create key")
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure.i DeleteRegistryKey(rootKey.i, keyPath.s, sam.l = #KEY_ALL_ACCESS)
  Protected ret.Registry::RegValue
  
  ; Ensure backup before destructive operation
  If Not EnsureBackupBeforeChange("Delete registry key: " + GetRootKeyName(rootKey) + "\" + keyPath)
    ProcedureReturn #False
  EndIf
  
  LogInfo("DeleteRegistryKey", "Deleting key: " + GetRootKeyName(rootKey) + "\" + keyPath + " (SAM: " + Hex(sam) + ")")
  
  ; Check for WOW64 flag in SAM
  Protected wow64.i = GetRegistryWow64Flag(sam)
  
  If Registry::DeleteKey(rootKey, keyPath, wow64, @ret)
    LogInfo("DeleteRegistryKey", "Successfully deleted key")
    UpdateStatusBar("Key deleted successfully")
    ProcedureReturn #True
  Else
    LogError("DeleteRegistryKey", "Failed to delete key: " + ret\ERRORSTR, ret\ERROR)
    MessageRequester("Error", "Failed to delete registry key!" + #CRLF$ + ret\ERRORSTR, #PB_MessageRequester_Error)
    UpdateStatusBar("Error: Failed to delete key")
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure.i DeleteRegistryValue(rootKey.i, keyPath.s, valueName.s, sam.l = #KEY_ALL_ACCESS)
  Protected ret.Registry::RegValue
  
  ; Ensure backup before destructive operation
  If Not EnsureBackupBeforeChange("Delete registry value: " + valueName + " in " + GetRootKeyName(rootKey) + "\" + keyPath)
    ProcedureReturn #False
  EndIf
  
  LogInfo("DeleteRegistryValue", "Deleting value: " + valueName + " from " + GetRootKeyName(rootKey) + "\" + keyPath)
  
  Protected wow64.i = GetRegistryWow64Flag(sam)
  
  If Registry::DeleteValue(rootKey, keyPath, valueName, wow64, @ret)
    LogInfo("DeleteRegistryValue", "Successfully deleted value")
    UpdateStatusBar("Value deleted successfully")
    ProcedureReturn #True
  Else
    LogError("DeleteRegistryValue", "Failed to delete value: " + ret\ERRORSTR, ret\ERROR)
    MessageRequester("Error", "Failed to delete registry value!" + #CRLF$ + ret\ERRORSTR, #PB_MessageRequester_Error)
    UpdateStatusBar("Error: Failed to delete value")
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure.i WriteRegistryValue(rootKey.i, keyPath.s, valueName.s, value.s, valueType.i, sam.l = #KEY_ALL_ACCESS)
  Protected ret.Registry::RegValue
  
  ; Ensure backup before modification
  If Not EnsureBackupBeforeChange("Write registry value: " + valueName + " in " + GetRootKeyName(rootKey) + "\" + keyPath)
    ProcedureReturn #False
  EndIf
  
  LogInfo("WriteRegistryValue", "Writing value: " + valueName + " = " + value + " (Type: " + GetTypeName(valueType) + ")")
  
  Protected wow64.i = GetRegistryWow64Flag(sam)
  
  If Registry::WriteValue(rootKey, keyPath, valueName, value, valueType, wow64, @ret)
    LogInfo("WriteRegistryValue", "Successfully wrote value")
    UpdateStatusBar("Value written successfully")
    ProcedureReturn #True
  Else
    LogError("WriteRegistryValue", "Failed to write value: " + ret\ERRORSTR, ret\ERROR)
    MessageRequester("Error", "Failed to write registry value!" + #CRLF$ + ret\ERRORSTR, #PB_MessageRequester_Error)
    UpdateStatusBar("Error: Failed to write value")
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure.i DeleteRegistryTree(rootKey.i, keyPath.s)
  Protected ret.Registry::RegValue
  Protected wow64.i = GetRegistryWow64Flag()
  
  ; Ensure backup before destructive operation
  If Not EnsureBackupBeforeChange("Delete registry tree: " + GetRootKeyName(rootKey) + "\" + keyPath)
    ProcedureReturn #False
  EndIf
  
  LogInfo("DeleteRegistryTree", "Deleting tree: " + GetRootKeyName(rootKey) + "\" + keyPath)
  
  If MessageRequester("Confirm Deletion", 
                      "This will delete the entire registry tree:" + #CRLF$ + 
                      GetRootKeyName(rootKey) + "\" + keyPath + #CRLF$ + #CRLF$ +
                      "This operation is IRREVERSIBLE!" + #CRLF$ + #CRLF$ +
                      "Continue?", 
                      #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
    
    If Registry::DeleteTree(rootKey, keyPath, wow64, @ret)
      LogInfo("DeleteRegistryTree", "Successfully deleted tree")
      UpdateStatusBar("Registry tree deleted successfully")
      ProcedureReturn #True
    Else
      LogError("DeleteRegistryTree", "Failed to delete tree: " + ret\ERRORSTR, ret\ERROR)
      MessageRequester("Error", "Failed to delete registry tree!" + #CRLF$ + ret\ERRORSTR, #PB_MessageRequester_Error)
      UpdateStatusBar("Error: Failed to delete tree")
      ProcedureReturn #False
    EndIf
  Else
    LogInfo("DeleteRegistryTree", "User cancelled tree deletion")
    UpdateStatusBar("Operation cancelled")
    ProcedureReturn #False
  EndIf
EndProcedure

;- Export And Restore
Structure ExportThreadParams
  RootKey.i
  KeyPath.s
  FileName.s
  IsRestore.i ; 0 = Export, 1 = Restore
EndStructure

Procedure ExportThread(param.i)
  Protected *p.ExportThreadParams = param
  If *p = 0 : ProcedureReturn : EndIf
  
  Protected rootKey.i = *p\RootKey
  Protected keyPath.s = *p\KeyPath
  Protected fileName.s = *p\FileName
  Protected isRestore.i = *p\IsRestore
  FreeStructure(*p)
  
  Protected program.i, exitCode.i, rootName.s
  Select rootKey
    Case #HKEY_CLASSES_ROOT : rootName = "HKCR"
    Case #HKEY_CURRENT_USER : rootName = "HKCU"
    Case #HKEY_LOCAL_MACHINE : rootName = "HKLM"
    Case #HKEY_USERS : rootName = "HKU"
    Case #HKEY_CURRENT_CONFIG : rootName = "HKCC"
    Default : rootName = "HKLM" ; Fallback
  EndSelect
  
  If isRestore
    ; RESTORE Logic
    program = RunProgram("reg", "import " + Chr(34) + fileName + Chr(34), "", #PB_Program_Wait | #PB_Program_Hide)
  Else
    ; EXPORT Logic
    Protected fullPath.s = rootName + "\" + keyPath
    program = RunProgram("reg", "export " + Chr(34) + fullPath + Chr(34) + " " + Chr(34) + fileName + Chr(34) + " /y", "", #PB_Program_Wait | #PB_Program_Hide)
  EndIf
  
  If program
    exitCode = ProgramExitCode(program)
  Else
    exitCode = -1
  EndIf
  
  PostEvent(#EVENT_EXPORT_COMPLETE, #WINDOW_MAIN, 0, exitCode, isRestore)
EndProcedure

Procedure ExportRegistryKey(rootKey.i, keyPath.s, fileName.s)
  If fileName = "" : ProcedureReturn #False : EndIf
  
  LogInfo("ExportRegistryKey", "Queuing export to " + fileName)
  UpdateStatusBar("Background export started...")
  
  Protected *p.ExportThreadParams = AllocateStructure(ExportThreadParams)
  If *p
    *p\RootKey = rootKey
    *p\KeyPath = keyPath
    *p\FileName = fileName
    *p\IsRestore = #False
    If CreateThread(@ExportThread(), *p) : ProcedureReturn #True : EndIf
    FreeStructure(*p)
  EndIf
  UpdateStatusBar("Error: Could not start export task")
  MessageRequester("Export Failed", "Could not start the export task.", #PB_MessageRequester_Error)
  ProcedureReturn #False
EndProcedure

Procedure RestoreRegistry(fileName.s)
  If fileName = "" Or FileSize(fileName) <= 0 : ProcedureReturn #False : EndIf
  
  If Not EnsureBackupBeforeChange("Restore registry from file: " + fileName)
    ProcedureReturn #False
  EndIf
  
  If MessageRequester("Confirm Restore", "This will restore registry settings from file. Continue?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
    UpdateStatusBar("Background restore started...")
    
    Protected *p.ExportThreadParams = AllocateStructure(ExportThreadParams)
    If *p
      *p\FileName = fileName
      *p\IsRestore = #True
      If CreateThread(@ExportThread(), *p) : ProcedureReturn #True : EndIf
      FreeStructure(*p)
    EndIf
    UpdateStatusBar("Error: Could not start restore task")
    MessageRequester("Restore Failed", "Could not start the restore task.", #PB_MessageRequester_Error)
  EndIf
  ProcedureReturn #False
EndProcedure

;- Registry Utilities

Procedure CompactRegistry()
  Protected program.i, exitCode.i, hivePath.s
  
  LogInfo("CompactRegistry", "User requested registry compaction")
  
  If MessageRequester("Registry Optimization", "This tool will create an optimized, 'compacted' copy of your Current User registry hive." + #CRLF$ + #CRLF$ +
                                                "How it works:" + #CRLF$ +
                                                "1. It exports the HKCU hive to a new file using RegSaveKey logic." + #CRLF$ +
                                                "2. This removes internal gaps and fragmentation." + #CRLF$ +
                                                "3. The original registry is NOT modified or replaced automatically for your safety." + #CRLF$ + #CRLF$ +
                                                "Do you want to generate an optimized hive file?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info) = #PB_MessageRequester_Yes
    UpdateStatusBar("Optimizing HKCU hive...")
    
    ; Create a safe timestamped filename in the snapshots directory
    Protected filename.s = "Optimized_HKCU_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".hiv"
    Protected fullPath.s = GetSnapshotDirectory() + filename
    
    ; Use the native Registry::CompactHive API instead of reg.exe
    If Registry::CompactHive(#HKEY_CURRENT_USER, fullPath, GetRegistryWow64Flag())
      LogInfo("CompactRegistry", "HKCU optimized and saved to: " + fullPath)
      
      ; Calculate size difference
      Protected optimizedSize.q = FileSize(fullPath)
      LogInfo("CompactRegistry", "Optimized Hive Size: " + Str(optimizedSize) + " bytes")
      
      UpdateStatusBar("Optimization complete. Size: " + Str(optimizedSize / 1024) + " KB")
      MessageRequester("Optimization Complete", "A compacted copy of your HKCU hive has been created at:" + #CRLF$ + 
                                                fullPath + #CRLF$ + #CRLF$ +
                                                "Optimized Size: " + Str(optimizedSize / 1024) + " KB" + #CRLF$ +
                                                "The size of this file represents the minimum footprint of your current settings." + #CRLF$ +
                                                "Your live registry remains untouched.", #PB_MessageRequester_Info)
    Else
      LogError("CompactRegistry", "Optimization failed. Ensure you have Administrator privileges.")
      MessageRequester("Error", "Failed to optimize registry hive." + #CRLF$ + 
                                "This operation usually requires Administrator privileges and the 'Backup' privilege.", #PB_MessageRequester_Error)
      UpdateStatusBar("Optimization failed.")
    EndIf
    UpdateStatusBar("Ready")


  Else
    LogInfo("CompactRegistry", "User cancelled optimization")
    UpdateStatusBar("Ready")
  EndIf
EndProcedure

