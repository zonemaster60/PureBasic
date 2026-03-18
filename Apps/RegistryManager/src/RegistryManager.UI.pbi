; Main UI, favorites, navigation

;- Main Window

Procedure CreateGUI()
  Protected window.i, menu.i
  
  LogInfo("CreateGUI", "Creating main window and GUI")
  
  window = OpenWindow(#WINDOW_MAIN, 0, 0, 1024, 768, "Registry Manager " + AppVersion + " - Editor | Cleaner | Backup | Restore | Compactor", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_MaximizeGadget | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered)
  
  If window
    ; Create Address Bar (at the top)

    StringGadget(#GADGET_ADDRESS_BAR, 5, 5, 960, 25, "")
    ButtonGadget(#GADGET_ADDRESS_GO, 970, 5, 45, 25, "Go")
    
    ; Create Menu

    menu = CreateMenu(#GADGET_MENU, WindowID(#WINDOW_MAIN))
    If menu
      MenuTitle("File")
      MenuItem(#MENU_FILE_EXPORT, "Export Key...")
      MenuItem(#MENU_FILE_IMPORT, "Import .reg File...")
      MenuBar()
      MenuItem(#MENU_FILE_EXIT, "Exit")
      
      MenuTitle("Edit")
      MenuItem(#MENU_EDIT_NEW_KEY, "New Key")
      MenuItem(#MENU_EDIT_NEW_VALUE, "New Value")
      MenuItem(#MENU_EDIT_DELETE, "Delete")
      MenuItem(#MENU_EDIT_RENAME, "Rename")
      
      MenuTitle("Tools")
      MenuItem(#MENU_TOOLS_CLEANER, "Registry Cleaner...")
      MenuItem(#MENU_TOOLS_BACKUP, "Backup Registry...")
      MenuItem(#MENU_TOOLS_RESTORE, "Restore Registry...")
      MenuItem(#MENU_TOOLS_COMPACT, "Compact Registry...")
      MenuBar()
      MenuItem(#MENU_TOOLS_MONITOR, "Registry Monitor...")
      MenuItem(#MENU_TOOLS_SNAPSHOT, "Snapshot Manager...")
      MenuItem(#MENU_TOOLS_HEX_EXTERNAL, "Hex Editor (External File)...")
      
      MenuTitle("View")
      MenuItem(#MENU_VIEW_64BIT, "64-bit Registry View")
      SetMenuItemState(#GADGET_MENU, #MENU_VIEW_64BIT, #True)
      MenuItem(#MENU_VIEW_REFRESH, "Refresh" + Chr(9) + "F5")
      
      MenuTitle("Favorites")
      MenuItem(#MENU_FAV_ADD, "Add Current Path to Favorites" + Chr(9) + "Ctrl+D")
      MenuItem(#MENU_FAV_MANAGE, "Manage Favorites...")
      MenuBar()
      ; Dynamic favorites populated at startup or via UpdateFavoritesMenu
      LoadFavorites()
      ForEach Favorites()
        MenuItem(#MENU_FAV_START + ListIndex(Favorites()), Favorites())
      Next
      
      MenuTitle("Help")
      MenuItem(#MENU_HELP_ONLINE, "Online Help" + Chr(9) + "F1")
      MenuItem(#MENU_HELP_ABOUT, "About Registry Manager")
      
      ; Add Keyboard Shortcuts
      AddKeyboardShortcut(#WINDOW_MAIN, #PB_Shortcut_Return, #GADGET_ADDRESS_GO)
      AddKeyboardShortcut(#WINDOW_MAIN, #PB_Shortcut_F1, #MENU_HELP_ONLINE)
      AddKeyboardShortcut(#WINDOW_MAIN, #PB_Shortcut_F5, #MENU_VIEW_REFRESH)

      AddKeyboardShortcut(#WINDOW_MAIN, #PB_Shortcut_Control | #PB_Shortcut_F, 40)
      AddKeyboardShortcut(#WINDOW_MAIN, #PB_Shortcut_Control | #PB_Shortcut_D, #MENU_FAV_ADD)

      
      LogInfo("CreateGUI", "Menu created successfully")
    Else
      LogError("CreateGUI", "Failed to create menu")
    EndIf
    
    ; Create Status Bar
    CreateStatusBar(#GADGET_STATUSBAR, WindowID(#WINDOW_MAIN))
    AddStatusBarField(#PB_Ignore)
    UpdateStatusBar("Ready - Log file: " + ErrorLogPath)
    
    ; Create Tree for Registry Keys
    If Not TreeGadget(#GADGET_TREE, 0, 0, 300, WindowHeight(#WINDOW_MAIN) - 20)
      LogError("CreateGUI", "Failed to create tree gadget")
      ProcedureReturn #False
    EndIf
    
    ; Add standard system icons for the tree (Folder/Registry)
    Protected hSmallIcons.i = ImageList_Create_(16, 16, #ILC_COLOR32 | #ILC_MASK, 2, 2)
    If hSmallIcons
      ; 1: Closed Folder, 2: Open Folder, 3: Registry Key
      ; Using shell icons for consistency
      Protected shInfo.SHFILEINFO
    SHGetFileInfo_("C:\Windows", #FILE_ATTRIBUTE_DIRECTORY, @shInfo, SizeOf(SHFILEINFO), #SHGFI_ICON | #SHGFI_SMALLICON | #SHGFI_USEFILEATTRIBUTES)
      ImageList_AddIcon_(hSmallIcons, shInfo\hIcon)
      
      DestroyIcon_(shInfo\hIcon)
      
      ; Registry icon (usually index 16 in shell32.dll)
      ExtractIconEx_("shell32.dll", 16, 0, @shInfo\hIcon, 1)
      ImageList_AddIcon_(hSmallIcons, shInfo\hIcon)
      DestroyIcon_(shInfo\hIcon)
      
      SendMessage_(GadgetID(#GADGET_TREE), #TVM_SETIMAGELIST, #TVSIL_NORMAL, hSmallIcons)
    EndIf

    
     ; Add root keys to tree
     Define rootCR.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_CLASSES_ROOT", 0, 0)
     Define rootCU.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_CURRENT_USER", 0, 0)
     Define rootLM.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_LOCAL_MACHINE", 0, 0)
     Define rootUS.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_USERS", 0, 0)
     Define rootCC.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_CURRENT_CONFIG", 0, 0)

     
      ; Lazy load subkeys on double-click (avoid freezing on startup).
      ClearMap(TreeChildrenLoaded())
      TreeChildrenLoaded(Str(rootCR)) = #False
      TreeChildrenLoaded(Str(rootCU)) = #False
      TreeChildrenLoaded(Str(rootLM)) = #False
      TreeChildrenLoaded(Str(rootUS)) = #False
      TreeChildrenLoaded(Str(rootCC)) = #False
    
    ; Create ListView for Values
    If Not ListIconGadget(#GADGET_LISTVIEW, 300, 0, WindowWidth(#WINDOW_MAIN) - 300, WindowHeight(#WINDOW_MAIN) - 20, "Name", 250, #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
      LogError("CreateGUI", "Failed to create listview gadget")
      ProcedureReturn #False
    EndIf
    AddGadgetColumn(#GADGET_LISTVIEW, 1, "Type", 120)
    AddGadgetColumn(#GADGET_LISTVIEW, 2, "Data", 500)
    
    ; Apply Explorer Theme to both gadgets now that they both exist
    SendMessage_(GadgetID(#GADGET_TREE), 4381, 0, RGB(255, 255, 255)) ; #TVM_SETBKCOLOR
    SendMessage_(GadgetID(#GADGET_LISTVIEW), #LVM_SETEXTENDEDLISTVIEWSTYLE, #LVS_EX_FULLROWSELECT | #LVS_EX_DOUBLEBUFFER, #LVS_EX_FULLROWSELECT | #LVS_EX_DOUBLEBUFFER)
    SetWindowTheme(GadgetID(#GADGET_TREE), "Explorer", 0)
    SetWindowTheme(GadgetID(#GADGET_LISTVIEW), "Explorer", 0)

    ; Add value type icons

    Protected hListIcons.i = ImageList_Create_(16, 16, #ILC_COLOR32 | #ILC_MASK, 4, 4)
    If hListIcons
      Protected iconInfo.SHFILEINFO
      ; 0: Default Registry/String (ID 16 in shell32)
      ExtractIconEx_("shell32.dll", 16, 0, @iconInfo\hIcon, 1)
      ImageList_AddIcon_(hListIcons, iconInfo\hIcon)
      DestroyIcon_(iconInfo\hIcon)
      
      ; 1: Binary (ID 254 in shell32 - Binary file icon)
      ExtractIconEx_("shell32.dll", 254, 0, @iconInfo\hIcon, 1)
      ImageList_AddIcon_(hListIcons, iconInfo\hIcon)
      DestroyIcon_(iconInfo\hIcon)
      
      ; 2: Numeric/DWORD (ID 12 in shell32 - Calculator or similar)
      ExtractIconEx_("shell32.dll", 12, 0, @iconInfo\hIcon, 1)
      ImageList_AddIcon_(hListIcons, iconInfo\hIcon)
      DestroyIcon_(iconInfo\hIcon)
      
      SendMessage_(GadgetID(#GADGET_LISTVIEW), #LVM_SETIMAGELIST, #LVSIL_SMALL, hListIcons)
    EndIf

    
    ; Create Splitter with existing Tree and ListView
    If Not SplitterGadget(#GADGET_SPLITTER, 0, 35, WindowWidth(#WINDOW_MAIN), WindowHeight(#WINDOW_MAIN) - 55, #GADGET_TREE, #GADGET_LISTVIEW)
      LogError("CreateGUI", "Failed to create splitter gadget")
      ProcedureReturn #False
    EndIf

    
    SetGadgetAttribute(#GADGET_SPLITTER, #PB_Splitter_FirstMinimumSize, 200)
    SetGadgetAttribute(#GADGET_SPLITTER, #PB_Splitter_SecondMinimumSize, 300)
    
    ; Create Popup Menus
    If CreatePopupMenu(#GADGET_POPUP_TREE)
      MenuItem(#MENU_EDIT_NEW_KEY, "New Key")
      MenuItem(#MENU_EDIT_NEW_VALUE, "New Value")
      MenuBar()
      MenuItem(#MENU_EDIT_RENAME, "Rename Key")
      MenuItem(#MENU_EDIT_DELETE, "Delete Key")
      MenuBar()
      MenuItem(#MENU_EDIT_COPY_PATH, "Copy Key Path")
      MenuItem(#MENU_EDIT_PERMISSIONS, "Permissions...")
      MenuBar()
      MenuItem(#MENU_FILE_EXPORT, "Export Key...")
    EndIf

    
    If CreatePopupMenu(#GADGET_POPUP_LIST)
      MenuItem(#MENU_EDIT_NEW_VALUE, "New Value")
      MenuBar()
      MenuItem(#MENU_EDIT_RENAME, "Rename Value")
      MenuItem(#MENU_EDIT_DELETE, "Delete Value")
    EndIf
    
    LogInfo("CreateGUI", "GUI created successfully")
    ProcedureReturn #True
  Else
    LogError("CreateGUI", "Failed to create main window")
  EndIf
  
  ProcedureReturn #False
EndProcedure

;- Favorites Persistence

Procedure SaveFavorites()
  Protected file.i, favPath.s = AppPath + "Favorites.txt"
  file = CreateFile(#PB_Any, favPath)
  If file
    ForEach Favorites()
      WriteStringN(file, Favorites())
    Next
    CloseFile(file)
  EndIf
EndProcedure

Procedure LoadFavorites()
  Protected file.i, favPath.s = AppPath + "Favorites.txt"
  ClearList(Favorites())
  file = ReadFile(#PB_Any, favPath)
  If file
    While Not Eof(file)
      Define line.s = ReadString(file)
      If line <> ""
        AddElement(Favorites())
        Favorites() = line
      EndIf
    Wend
    CloseFile(file)
  EndIf
EndProcedure

Procedure UpdateFavoritesMenu()
  If Not IsMenu(#GADGET_MENU) : ProcedureReturn : EndIf
  
  ; Note: PureBasic doesn't allow easy deletion of dynamic menu items without 
  ; clearing the whole title or using WinAPI.
  
  LogInfo("UpdateFavoritesMenu", "Refreshing favorites list")
  LoadFavorites()
  
  Protected hMenu = MenuID(#GADGET_MENU)
  ; Favorites is the 5th title (File=0, Edit=1, Tools=2, View=3, Favorites=4, Help=5)
  Protected hFavMenu = GetSubMenu_(hMenu, 4)
  
  If hFavMenu
    ; Remove items from the end up to the separator (which is at position 2)
    ; 0: Add Favorite
    ; 1: Manage Favorites
    ; 2: Separator
    ; 3+: Dynamic items
    Protected i.i
    For i = GetMenuItemCount_(hFavMenu) - 1 To 3 Step -1
      DeleteMenu_(hFavMenu, i, #MF_BYPOSITION)
    Next
    
    ; Re-add from list
    ForEach Favorites()
      MenuItem(#MENU_FAV_START + ListIndex(Favorites()), Favorites())
    Next
    
    DrawMenuBar_(WindowID(#WINDOW_MAIN))
  EndIf
EndProcedure

;- Favorites UI

Procedure OpenFavoritesManager()
  Protected win = OpenWindow(#PB_Any, 0, 0, 400, 300, "Manage Favorites", #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
  If win
    ListViewGadget(500, 10, 10, 380, 230)
    LoadFavorites()
    ForEach Favorites()
      AddGadgetItem(500, -1, Favorites())
    Next
    
    ButtonGadget(501, 10, 250, 100, 30, "Remove")
    ButtonGadget(502, 120, 250, 100, 30, "Jump To")
    ButtonGadget(503, 290, 250, 100, 30, "Close")
    If CountGadgetItems(500) = 0
      DisableGadget(501, #True)
      DisableGadget(502, #True)
    EndIf
    
    Repeat
      Define ev = WaitWindowEvent()
      If ev = #PB_Event_CloseWindow And EventWindow() = win
        Break
      ElseIf ev = #PB_Event_Gadget
        If EventGadget() = 503
          Break
        ElseIf EventGadget() = 501
          Define sel = GetGadgetState(500)
          If sel <> -1
            SelectElement(Favorites(), sel)
            DeleteElement(Favorites())
            RemoveGadgetItem(500, sel)
            SaveFavorites()
            UpdateFavoritesMenu()
          EndIf
        ElseIf EventGadget() = 502
          Define sel = GetGadgetState(500)
          If sel <> -1
            SelectElement(Favorites(), sel)
            JumpToPath(Favorites())
            Break
          EndIf
        EndIf
      EndIf
    ForEver
    CloseWindow(win)
  EndIf
EndProcedure

;- Favorites Actions


Procedure AddFavorite(path.s)
  Protected exists = #False
  ForEach Favorites()
    If Favorites() = path
      exists = #True
      Break
    EndIf
  Next
  
  If Not exists
    AddElement(Favorites())
    Favorites() = path
    SaveFavorites()
    UpdateFavoritesMenu()
    MessageRequester("Favorites", "Added to favorites: " + path, #PB_MessageRequester_Info)
    ProcedureReturn #True
  Else
    MessageRequester("Favorites", "Already in favorites!", #PB_MessageRequester_Warning)
    ProcedureReturn #False
  EndIf
EndProcedure


;- Navigation


Procedure JumpToPath(fullPath.s)
  Protected rootKey.i, keyPath.s, rootPart.s
  
  If fullPath = "" : ProcedureReturn : EndIf
  
    ; Standardize Path (Remove leading/trailing backslashes)
    fullPath = Trim(fullPath, "\")
    
    rootPart = StringField(fullPath, 1, "\")
    keyPath = Mid(fullPath, Len(rootPart) + 2)
    
    Select rootPart
      Case "HKEY_CLASSES_ROOT", "HKCR": rootKey = #HKEY_CLASSES_ROOT : rootPart = "HKEY_CLASSES_ROOT"
      Case "HKEY_CURRENT_USER", "HKCU": rootKey = #HKEY_CURRENT_USER : rootPart = "HKEY_CURRENT_USER"
      Case "HKEY_LOCAL_MACHINE", "HKLM": rootKey = #HKEY_LOCAL_MACHINE : rootPart = "HKEY_LOCAL_MACHINE"
      Case "HKEY_USERS", "HKU": rootKey = #HKEY_USERS : rootPart = "HKEY_USERS"
      Case "HKEY_CURRENT_CONFIG", "HKCC": rootKey = #HKEY_CURRENT_CONFIG : rootPart = "HKEY_CURRENT_CONFIG"
      Default: ProcedureReturn
    EndSelect
    
    LogInfo("JumpToPath", "Navigating to: " + fullPath)
    
    ; Clear Status
    UpdateStatusBar("Navigating to: " + rootPart + "\" + keyPath)
    
    ; Find root item
    Protected count.i = CountGadgetItems(#GADGET_TREE)
    Protected currentItem.i = -1
    Protected i.i
    For i = 0 To count - 1
      If GetGadgetItemText(#GADGET_TREE, i) = rootPart And GetGadgetItemAttribute(#GADGET_TREE, i, #PB_Tree_SubLevel) = 0
        currentItem = i
        Break
      EndIf
    Next
    
    If currentItem = -1 : ProcedureReturn : EndIf
    
    ; Traverse segments
    Protected remaining.s = keyPath
    Protected currentPath.s = ""
    
    While remaining <> ""
      Protected segment.s = StringField(remaining, 1, "\")
      remaining = Mid(remaining, Len(segment) + 2)
      
      ; Expand current item if needed
      If FindMapElement(TreeChildrenLoaded(), Str(currentItem)) = 0 Or TreeChildrenLoaded(Str(currentItem)) = #False
        ; LoadSubKeys should ideally have a synchronous flag for jumps
          If Not LoadSubKeys(currentItem, rootKey, currentPath, GetDefaultSAM())
            LogWarning("JumpToPath", "Could not start subtree load for: " + currentPath)
            UpdateStatusBar("Navigation failed: could not load path")
            ProcedureReturn
          EndIf
        
        ; DETERMINISTIC WAIT: We wait for the thread to actually add items.
        ; This ensures we don't skip segments because they weren't loaded yet.
        Protected startWait = ElapsedMilliseconds()
        While (FindMapElement(ActiveLoadThreads(), Str(currentItem)) <> 0) And (ElapsedMilliseconds() - startWait < 5000)
          While WindowEvent() : Wend
          Delay(20)
        Wend
        If FindMapElement(ActiveLoadThreads(), Str(currentItem)) = 0
          TreeChildrenLoaded(Str(currentItem)) = #True
        EndIf
      EndIf

      SetGadgetItemState(#GADGET_TREE, currentItem, #PB_Tree_Expanded)
      
      ; Find the child segment
      Protected found.i = -1
      Protected parentLevel.i = GetGadgetItemAttribute(#GADGET_TREE, currentItem, #PB_Tree_SubLevel)
      count = CountGadgetItems(#GADGET_TREE)
      For i = currentItem + 1 To count - 1
        Protected level.i = GetGadgetItemAttribute(#GADGET_TREE, i, #PB_Tree_SubLevel)
        If level <= parentLevel : Break : EndIf
        If level = parentLevel + 1
          If GetGadgetItemText(#GADGET_TREE, i) = segment
            found = i
            Break
          EndIf
        EndIf
      Next
      
      If found = -1
        LogWarning("JumpToPath", "Segment not found: " + segment)
        Break
      EndIf
      
      currentItem = found
      If currentPath <> "" : currentPath + "\" : EndIf
      currentPath + segment
    Wend
    
    ; Select final item
    SetGadgetState(#GADGET_TREE, currentItem)
    ; Force a selection event update
    CurrentRootKey = rootKey
    CurrentKeyPath = keyPath
    LoadValues(CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
    SetGadgetText(#GADGET_ADDRESS_BAR, GetRootKeyName(rootKey) + "\" + CurrentKeyPath)
    
    ; Scroll into view
    Define hItem = GadgetItemID(#GADGET_TREE, currentItem)
    SendMessage_(GadgetID(#GADGET_TREE), #TVM_ENSUREVISIBLE, 0, hItem)
    SendMessage_(GadgetID(#GADGET_TREE), #TVM_SELECTITEM, #TVGN_CARET, hItem)
    
    UpdateStatusBar("Ready")
EndProcedure

Procedure HandleFileMenu(menuID.i)
  Protected fileName.s

  Select menuID
    Case #MENU_FILE_EXPORT
      fileName = SaveFileRequester("Export Registry Key", "", "Registry Files (*.reg)|*.reg|All Files (*.*)|*.*", 0)
      If fileName <> ""
        If CurrentRootKey And CurrentKeyPath <> ""
          ExportRegistryKey(CurrentRootKey, CurrentKeyPath, fileName)
        Else
          LogWarning("Main", "Export attempted without selecting a key")
          MessageRequester("Error", "Please select a registry key first!", #PB_MessageRequester_Error)
        EndIf
      Else
        LogInfo("Main", "User cancelled export")
      EndIf

    Case #MENU_FILE_IMPORT
      fileName = OpenFileRequester("Import Registry File", "", "Registry Files (*.reg)|*.reg|All Files (*.*)|*.*", 0)
      If fileName <> ""
        RestoreRegistry(fileName)
      Else
        LogInfo("Main", "User cancelled import")
      EndIf

    Case #MENU_FILE_EXIT
      LogInfo("Main", "User selected Exit from menu")
      Exit()

  EndSelect
EndProcedure

Procedure HandleEditMenu(menuID.i)
  Select menuID
    Case #MENU_EDIT_NEW_KEY
      If CurrentRootKey <> 0
        Define newKeyName.s = InputRequester("New Registry Key", "Enter name for the new subkey:", "New Key")
        If newKeyName <> ""
          Define fullNewPath.s = CurrentKeyPath
          If fullNewPath <> "" : fullNewPath + "\" : EndIf
          fullNewPath + newKeyName
          If CreateRegistryKey(CurrentRootKey, fullNewPath, GetDefaultSAM())
            Define currentItem.i = GetGadgetState(#GADGET_TREE)
            If currentItem <> -1
              Define nextItem.i = currentItem + 1
              Define parentLevelNew.i = GetGadgetItemAttribute(#GADGET_TREE, currentItem, #PB_Tree_SubLevel)
              While nextItem < CountGadgetItems(#GADGET_TREE) And GetGadgetItemAttribute(#GADGET_TREE, nextItem, #PB_Tree_SubLevel) > parentLevelNew
                RemoveGadgetItem(#GADGET_TREE, nextItem)
              Wend
              TreeChildrenLoaded(Str(currentItem)) = #False
              LoadSubKeys(currentItem, CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
              SetGadgetItemState(#GADGET_TREE, currentItem, #PB_Tree_Expanded)
            EndIf
          EndIf
        EndIf
      Else
        MessageRequester("Error", "Please select a parent registry key first!", #PB_MessageRequester_Error)
      EndIf

    Case #MENU_EDIT_NEW_VALUE
      If CurrentRootKey <> 0
        OpenValueEditor(CurrentRootKey, CurrentKeyPath)
      Else
        MessageRequester("Error", "Please select a registry key first!", #PB_MessageRequester_Error)
      EndIf

    Case #MENU_EDIT_DELETE
      If CurrentRootKey <> 0 And CurrentKeyPath <> ""
        Define choice.i = MessageRequester("Delete What?", "What do you want to delete?" + #CRLF$ + #CRLF$ + "Current key: " + GetRootKeyName(CurrentRootKey) + "\" + CurrentKeyPath, #PB_MessageRequester_YesNoCancel)
        If choice = #PB_MessageRequester_Yes
          If DeleteRegistryKey(CurrentRootKey, CurrentKeyPath)
            Define selItem.i = GetGadgetState(#GADGET_TREE)
            If selItem <> -1
              Define pItem.i = -1
              Define pIdx.i
              Define sLevel.i = GetGadgetItemAttribute(#GADGET_TREE, selItem, #PB_Tree_SubLevel)
              If sLevel > 0
                For pIdx = selItem - 1 To 0 Step -1
                  If GetGadgetItemAttribute(#GADGET_TREE, pIdx, #PB_Tree_SubLevel) < sLevel
                    pItem = pIdx
                    Break
                  EndIf
                Next
              EndIf
              RemoveGadgetItem(#GADGET_TREE, selItem)
              If pItem <> -1
                SetGadgetState(#GADGET_TREE, pItem)
                PostEvent(#PB_Event_Gadget, #WINDOW_MAIN, #GADGET_TREE, #PB_EventType_LeftClick)
              EndIf
            EndIf
          EndIf
        ElseIf choice = #PB_MessageRequester_No
          Define selectedVal.i = GetGadgetState(#GADGET_LISTVIEW)
          If selectedVal <> -1
            Define valName.s = GetGadgetItemText(#GADGET_LISTVIEW, selectedVal, 0)
            If DeleteRegistryValue(CurrentRootKey, CurrentKeyPath, valName, GetDefaultSAM())
              LoadValues(CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
            EndIf
          Else
            MessageRequester("Info", "Select a value from the list first, then use this menu.", #PB_MessageRequester_Info)
          EndIf
        EndIf
      Else
        MessageRequester("Error", "Please select a registry key first!", #PB_MessageRequester_Error)
      EndIf

    Case #MENU_EDIT_COPY_PATH
      If CurrentRootKey <> 0
        SetClipboardText(GetRootKeyName(CurrentRootKey) + "\" + CurrentKeyPath)
        UpdateStatusBar("Key path copied to clipboard")
      EndIf

    Case #MENU_EDIT_PERMISSIONS
      If CurrentRootKey <> 0
        RunProgram("powershell.exe", "-Command " + Chr(34) + "Start-Process regedit.exe" + Chr(34), "", #PB_Program_Wait | #PB_Program_Hide)
        MessageRequester("Permissions", "Registry Permissions are best managed via the native Security Editor." + #CRLF$ + "Native Regedit has been launched to assist.", #PB_MessageRequester_Info)
      EndIf

    Case #MENU_EDIT_RENAME
      If CurrentRootKey <> 0
        Define selectedVal.i = GetGadgetState(#GADGET_LISTVIEW)
        If selectedVal <> -1
          Define oldValName.s = GetGadgetItemText(#GADGET_LISTVIEW, selectedVal, 0)
          OpenValueEditor(CurrentRootKey, CurrentKeyPath, oldValName)
        Else
          Define currentItem.i = GetGadgetState(#GADGET_TREE)
          If currentItem <> -1
            Define oldKeyName.s = GetGadgetItemText(#GADGET_TREE, currentItem, 0)
            If oldKeyName = "HKEY_CLASSES_ROOT" Or oldKeyName = "HKEY_CURRENT_USER" Or oldKeyName = "HKEY_LOCAL_MACHINE" Or oldKeyName = "HKEY_USERS" Or oldKeyName = "HKEY_CURRENT_CONFIG"
              MessageRequester("Error", "Root hives cannot be renamed!", #PB_MessageRequester_Error)
            Else
              Define newKeyName.s = InputRequester("Rename Key", "Enter new name for key '" + oldKeyName + "':", oldKeyName)
              If newKeyName <> "" And newKeyName <> oldKeyName
                Define parentPath.s = ""
                If CountString(CurrentKeyPath, "\") > 0
                  parentPath = Left(CurrentKeyPath, Len(CurrentKeyPath) - Len(oldKeyName) - 1)
                EndIf
                If EnsureBackupBeforeChange("Rename registry key: " + oldKeyName + " to " + newKeyName)
                  UpdateStatusBar("Renaming key... this may take a moment")
                  Define source.s = GetRootKeyName(CurrentRootKey) + "\" + CurrentKeyPath
                  Define destination.s = GetRootKeyName(CurrentRootKey) + "\"
                  If parentPath <> "" : destination + parentPath + "\" : EndIf
                  destination + newKeyName
                  Define renameWow64.i = GetRegistryWow64Flag(GetDefaultSAM())
                  Define prog.i = RunProgram("reg", "copy " + Chr(34) + source + Chr(34) + " " + Chr(34) + destination + Chr(34) + " /s /f", "", #PB_Program_Wait | #PB_Program_Hide)
                  If prog And ProgramExitCode(prog) = 0
                    Registry::DeleteTree(CurrentRootKey, CurrentKeyPath, renameWow64)
                    SetGadgetItemText(#GADGET_TREE, currentItem, newKeyName)
                    CurrentKeyPath = parentPath
                    If CurrentKeyPath <> "" : CurrentKeyPath + "\" : EndIf
                    CurrentKeyPath + newKeyName
                    UpdateStatusBar("Key renamed successfully")
                  Else
                    LogError("Rename", "Failed to copy key for rename")
                    MessageRequester("Error", "Failed to rename registry key!", #PB_MessageRequester_Error)
                  EndIf
                EndIf
              EndIf
            EndIf
          EndIf
        EndIf
      Else
        MessageRequester("Error", "Please select a key or value to rename!", #PB_MessageRequester_Error)
      EndIf

  EndSelect
EndProcedure

Procedure HandleToolsMenu(menuID.i)
  Protected fileName.s

  Select menuID
    Case #MENU_TOOLS_CLEANER
      CleanRegistry()

    Case #MENU_TOOLS_BACKUP
      fileName = SaveFileRequester("Backup Registry", "registry_backup_" + FormatDate("%yyyy%mm%dd", Date()) + ".reg", "Registry Files (*.reg)|*.reg", 0)
      If fileName <> ""
        BackupRegistry(fileName)
      Else
        LogInfo("Main", "User cancelled backup")
      EndIf

    Case #MENU_TOOLS_RESTORE
      fileName = OpenFileRequester("Restore Registry", "", "Registry Files (*.reg)|*.reg|All Files (*.*)|*.*", 0)
      If fileName <> ""
        RestoreRegistry(fileName)
      Else
        LogInfo("Main", "User cancelled restore")
      EndIf

    Case #MENU_TOOLS_COMPACT
      CompactRegistry()

    Case #MENU_TOOLS_MONITOR
      LogInfo("Main", "Opening registry monitor")
      OpenMonitorWindow()

    Case #MENU_TOOLS_SNAPSHOT
      LogInfo("Main", "Opening snapshot manager")
      OpenSnapshotWindow()

    Case #MENU_TOOLS_HEX_EXTERNAL
      Define hexFilePath.s = OpenFileRequester("Open Binary File for Hex Editing", "", "All Files (*.*)|*.*", 0)
      If hexFilePath <> ""
        OpenHexEditor(0, "", "", hexFilePath)
      EndIf

  EndSelect
EndProcedure

Procedure HandleViewMenu(menuID.i)
  Select menuID
    Case #MENU_VIEW_64BIT
      View64Bit = 1 - View64Bit
      SetMenuItemState(#GADGET_MENU, #MENU_VIEW_64BIT, View64Bit)
      If View64Bit
        UpdateStatusBar("View mode: 64-bit Registry")
      Else
        UpdateStatusBar("View mode: 32-bit Registry (WOW64)")
      EndIf
      SendMessage_(GadgetID(#GADGET_TREE), #WM_SETREDRAW, #False, 0)
      ClearGadgetItems(#GADGET_TREE)
      ClearMap(TreeChildrenLoaded())
      Define rootCR.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_CLASSES_ROOT", 0, 0)
      Define rootCU.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_CURRENT_USER", 0, 0)
      Define rootLM.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_LOCAL_MACHINE", 0, 0)
      Define rootUS.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_USERS", 0, 0)
      Define rootCC.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_CURRENT_CONFIG", 0, 0)
      TreeChildrenLoaded(Str(rootCR)) = #False
      TreeChildrenLoaded(Str(rootCU)) = #False
      TreeChildrenLoaded(Str(rootLM)) = #False
      TreeChildrenLoaded(Str(rootUS)) = #False
      TreeChildrenLoaded(Str(rootCC)) = #False
      SendMessage_(GadgetID(#GADGET_TREE), #WM_SETREDRAW, #True, 0)
      InvalidateRect_(GadgetID(#GADGET_TREE), 0, #True)
      ClearGadgetItems(#GADGET_LISTVIEW)
      CurrentRootKey = 0
      CurrentKeyPath = ""
      SetGadgetText(#GADGET_ADDRESS_BAR, "")
      LogInfo("Main", "Registry view toggled. View64Bit=" + Str(View64Bit))

    Case #MENU_VIEW_REFRESH
      If CurrentRootKey <> 0
        LoadValues(CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
        Define sel.i = GetGadgetState(#GADGET_TREE)
        If sel <> -1
          Define nextItem.i = sel + 1
          Define parentLevel.i = GetGadgetItemAttribute(#GADGET_TREE, sel, #PB_Tree_SubLevel)
          While nextItem < CountGadgetItems(#GADGET_TREE) And GetGadgetItemAttribute(#GADGET_TREE, nextItem, #PB_Tree_SubLevel) > parentLevel
            RemoveGadgetItem(#GADGET_TREE, nextItem)
          Wend
          TreeChildrenLoaded(Str(sel)) = #False
          LoadSubKeys(sel, CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
        EndIf
      EndIf

  EndSelect
EndProcedure

Procedure HandleHelpMenu(menuID.i)
  Protected helpPath.s

  Select menuID
    Case #MENU_HELP_ONLINE
      LogInfo("Main", "Opening help system")
      helpPath = GetCurrentDirectory() + "RegistryManager_Help.html"
      If FileSize(helpPath) > 0
        RunProgram(helpPath, "", "", #PB_Program_Open)
        UpdateStatusBar("Help opened in browser")
      Else
        MessageRequester("Help Not Found", "Help file not found: " + helpPath + #CRLF$ + #CRLF$ + "Please ensure RegistryManager_Help.html is in the same folder as RegistryManager.exe", #PB_MessageRequester_Warning)
        LogWarning("Main", "Help file not found: " + helpPath)
      EndIf

    Case #MENU_HELP_ABOUT
      LogInfo("Main", "Displaying About dialog")
      MessageRequester("About Registry Manager", "Registry Manager " + AppVersion + #CRLF$ + #CRLF$ + "All-in-One Registry Tool with Auto-Backup" + #CRLF$ + #CRLF$ + "Features:" + #CRLF$ + "Registry Editor" + #CRLF$ + "Registry Cleaner" + #CRLF$ + "Backup & Restore" + #CRLF$ + "Registry Compactor" + #CRLF$ + "Automatic Safety Backups" + #CRLF$ + "Real-Time Registry Monitor" + #CRLF$ + "Snapshot Manager & Comparison" + #CRLF$ + #CRLF$ + "Built with PureBasic 6.30+" + #CRLF$ + #CRLF$ + "Log file: " + ErrorLogPath + #CRLF$ + "Backup directory: " + GetBackupDirectory() + #CRLF$ + "Snapshot directory: " + GetSnapshotDirectory() + #CRLF$ + "Last backup: " + AutoBackupPath + #CRLF$ + "Monitor events: " + Str(MonitorEventCount) + #CRLF$ + "Snapshots: " + Str(ListSize(Snapshots())), #PB_MessageRequester_Info)

  EndSelect
EndProcedure

Procedure HandleFavoritesMenu(menuID.i)
  Select menuID
    Case 40
      OpenSearchWindow()

    Case #MENU_DEBUG_STRESS
      ToggleStressTest()

    Case #MENU_FAV_ADD
      If CurrentRootKey <> 0
        Define fullFavPath.s = GetRootKeyName(CurrentRootKey)
        If CurrentKeyPath <> "" : fullFavPath + "\" + CurrentKeyPath : EndIf
        AddFavorite(fullFavPath)
      EndIf

    Case #MENU_FAV_MANAGE
      OpenFavoritesManager()

    Default
      If menuID >= #MENU_FAV_START And menuID < #MENU_FAV_START + 100
        Define favIndex.i = menuID - #MENU_FAV_START
        SelectElement(Favorites(), favIndex)
        JumpToPath(Favorites())
      EndIf

  EndSelect
EndProcedure

Procedure HandleMenuEvent(menuID.i)
  Select menuID
    Case #MENU_FILE_EXPORT, #MENU_FILE_IMPORT, #MENU_FILE_EXIT
      HandleFileMenu(menuID)

    Case #MENU_EDIT_NEW_KEY, #MENU_EDIT_NEW_VALUE, #MENU_EDIT_DELETE, #MENU_EDIT_COPY_PATH, #MENU_EDIT_PERMISSIONS, #MENU_EDIT_RENAME
      HandleEditMenu(menuID)

    Case #MENU_TOOLS_CLEANER, #MENU_TOOLS_BACKUP, #MENU_TOOLS_RESTORE, #MENU_TOOLS_COMPACT, #MENU_TOOLS_MONITOR, #MENU_TOOLS_SNAPSHOT, #MENU_TOOLS_HEX_EXTERNAL
      HandleToolsMenu(menuID)

    Case #MENU_VIEW_64BIT, #MENU_VIEW_REFRESH
      HandleViewMenu(menuID)

    Case #MENU_HELP_ONLINE, #MENU_HELP_ABOUT
      HandleHelpMenu(menuID)

    Default
      HandleFavoritesMenu(menuID)
  EndSelect
EndProcedure

Procedure HandleMainWindowGadget(gadgetID.i)
  Select gadgetID
    Case #GADGET_TREE
      If EventWindow() = #WINDOW_MAIN
        If Not IsUpdatingTree
          Define item.i = GetGadgetState(#GADGET_TREE)
          If item <> -1
            Define tempPath.s = GetGadgetItemText(#GADGET_TREE, item, 0)
            CurrentRootKey = GetRootKeyFromTreeItem(item)
            If CurrentRootKey <> 0
              Define isHiveRoot.i = #False
              If tempPath = "HKEY_CLASSES_ROOT" Or tempPath = "HKEY_CURRENT_USER" Or tempPath = "HKEY_LOCAL_MACHINE" Or tempPath = "HKEY_USERS" Or tempPath = "HKEY_CURRENT_CONFIG"
                isHiveRoot = #True
                CurrentKeyPath = ""
              Else
                CurrentKeyPath = ""
                Define level.i = GetGadgetItemAttribute(#GADGET_TREE, item, #PB_Tree_SubLevel)
                NewList RegPathSegments.s()
                InsertElement(RegPathSegments())
                RegPathSegments() = tempPath
                Define currentLevel.i = level
                Define pIdx.i
                For pIdx = item - 1 To 0 Step -1
                  Define pLevel.i = GetGadgetItemAttribute(#GADGET_TREE, pIdx, #PB_Tree_SubLevel)
                  If pLevel < currentLevel
                    InsertElement(RegPathSegments())
                    RegPathSegments() = GetGadgetItemText(#GADGET_TREE, pIdx)
                    currentLevel = pLevel
                  EndIf
                  If pLevel = 0 : Break : EndIf
                Next
                SelectElement(RegPathSegments(), 0)
                Define firstSeg.s = RegPathSegments()
                If firstSeg = "HKEY_CLASSES_ROOT" Or firstSeg = "HKEY_CURRENT_USER" Or firstSeg = "HKEY_LOCAL_MACHINE" Or firstSeg = "HKEY_USERS" Or firstSeg = "HKEY_CURRENT_CONFIG"
                  DeleteElement(RegPathSegments())
                EndIf
                CurrentKeyPath = ""
                ForEach RegPathSegments()
                  If CurrentKeyPath <> "" : CurrentKeyPath + "\" : EndIf
                  CurrentKeyPath + RegPathSegments()
                Next
              EndIf
              If isHiveRoot
                SetGadgetText(#GADGET_ADDRESS_BAR, tempPath)
                CurrentKeyPath = ""
              Else
                SetGadgetText(#GADGET_ADDRESS_BAR, GetRootKeyName(CurrentRootKey) + "\" + CurrentKeyPath)
              EndIf
              If item <> LastSelectedItem Or EventType() = #PB_EventType_LeftClick
                LogInfo("Main", "Tree item selected: " + tempPath + " (Root: " + Hex(CurrentRootKey) + ", Path: '" + CurrentKeyPath + "')")
                LoadValues(CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
                LastSelectedItem = item
              EndIf
              If EventType() = #PB_EventType_LeftDoubleClick Or (GetGadgetItemState(#GADGET_TREE, item) & #PB_Tree_Expanded)
                If FindMapElement(TreeChildrenLoaded(), Str(item)) = 0 Or TreeChildrenLoaded(Str(item)) = #False
                  UpdateStatusBar("Loading subkeys for: " + tempPath)
                  SetCursor_(LoadCursor_(LoadLibrary_("user32.dll"), #IDC_WAIT))
                  IsUpdatingTree = #True
                  Define nextCheck.i = item + 1
                  Define pLevelCheck.i = GetGadgetItemAttribute(#GADGET_TREE, item, #PB_Tree_SubLevel)
                  While nextCheck < CountGadgetItems(#GADGET_TREE) And GetGadgetItemAttribute(#GADGET_TREE, nextCheck, #PB_Tree_SubLevel) > pLevelCheck
                    RemoveGadgetItem(#GADGET_TREE, nextCheck)
                  Wend
                  IsUpdatingTree = #False
                  TreeChildrenLoaded(Str(item)) = #False
                  LoadSubKeys(item, CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
                  UpdateStatusBar("Ready")
                  SetCursor_(LoadCursor_(0, #IDC_ARROW))
                EndIf
              EndIf
              If EventType() = #PB_EventType_RightClick
                DisplayPopupMenu(#GADGET_POPUP_TREE, WindowID(#WINDOW_MAIN))
              EndIf
            Else
              LogWarning("Main", "Could not determine root key for selected item")
            EndIf
          EndIf
        EndIf
      EndIf

    Case #GADGET_ADDRESS_GO
      If EventWindow() = #WINDOW_MAIN
        JumpToPath(GetGadgetText(#GADGET_ADDRESS_BAR))
      EndIf

    Case #GADGET_LISTVIEW
      If EventWindow() = #WINDOW_MAIN And EventType() = #PB_EventType_RightClick
        DisplayPopupMenu(#GADGET_POPUP_LIST, WindowID(#WINDOW_MAIN))
      EndIf

  EndSelect
EndProcedure

Procedure HandleMonitorWindowGadget(gadgetID.i)
  Select gadgetID

    Case #GADGET_MONITOR_START
      If EventWindow() = #WINDOW_MONITOR
        LogInfo("Main", "Monitor: Start button clicked")
        If StartRegistryMonitor()
          DisableGadget(#GADGET_MONITOR_START, #True)
          DisableGadget(#GADGET_MONITOR_STOP, #False)
          RefreshMonitorWindow()
          UpdateStatusBar("Registry monitor started")
        EndIf
      EndIf

    Case #GADGET_MONITOR_STOP
      If EventWindow() = #WINDOW_MONITOR
        LogInfo("Main", "Monitor: Stop button clicked")
        If StopRegistryMonitor()
          DisableGadget(#GADGET_MONITOR_START, #False)
          DisableGadget(#GADGET_MONITOR_STOP, #True)
          RefreshMonitorWindow()
          UpdateStatusBar("Registry monitor stopped")
        EndIf
      EndIf

    Case #GADGET_MONITOR_CLEAR
      If EventWindow() = #WINDOW_MONITOR
        LogInfo("Main", "Monitor: Clear button clicked")
        If MessageRequester("Confirm Clear", "Clear all monitor events?" + #CRLF$ + "This cannot be undone!", #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
          LockMutex(MonitorMutex)
          ClearList(MonitorEvents())
          MonitorEventCount = 0
          UnlockMutex(MonitorMutex)
          MonitorLastShownCount = 0
          ClearGadgetItems(#GADGET_MONITOR_LIST)
          RefreshMonitorWindow()
          LogInfo("Main", "Monitor log cleared")
          UpdateStatusBar("Monitor log cleared")
        EndIf
      EndIf

    Case #GADGET_MONITOR_SAVE
      If EventWindow() = #WINDOW_MONITOR
        LogInfo("Main", "Monitor: Save button clicked")
        Define fileName.s = SaveFileRequester("Save Monitor Log", "RegistryMonitor_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".log", "Log Files (*.log)|*.log|Text Files (*.txt)|*.txt|All Files (*.*)|*.*", 0)
        If fileName <> ""
          SaveMonitorLog(fileName)
        EndIf
      EndIf

  EndSelect
EndProcedure

Procedure HandleSnapshotWindowGadget(gadgetID.i)
  Select gadgetID

    Case #GADGET_SNAPSHOT_CREATE
      If EventWindow() = #WINDOW_SNAPSHOT
        LogInfo("Main", "Snapshot: Create button clicked")
        Define name.s = InputRequester("Create Snapshot", "Enter snapshot name:", "Snapshot_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()))
        If name <> ""
          Define description.s = InputRequester("Description (Optional)", "Enter description:", "Manual snapshot")
          If description = "" : description = "Manual snapshot" : EndIf
          SetSnapshotControlsEnabled(#False)
          UpdateStatusBar("Creating snapshot... this can take a while")
          name = SanitizeFileName(name)
          If name = ""
            name = "Snapshot_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date())
          EndIf
          Define *snapParams.SnapshotThreadParams = AllocateMemory(SizeOf(SnapshotThreadParams))
          If *snapParams
            *snapParams\Name = name
            *snapParams\Description = description
            SnapshotCreationActive = 1
            If Not CreateThread(@SnapshotThread(), *snapParams)
              SnapshotCreationActive = 0
              SetSnapshotControlsEnabled(#True)
              FreeMemory(*snapParams)
              LogError("Snapshot", "Failed to start snapshot thread")
              MessageRequester("Error", "Failed to start snapshot creation thread.", #PB_MessageRequester_Error)
            EndIf
          Else
            SnapshotCreationActive = 0
            SetSnapshotControlsEnabled(#True)
            MessageRequester("Error", "Failed to allocate snapshot parameters.", #PB_MessageRequester_Error)
          EndIf
        EndIf
      EndIf

    Case #GADGET_SNAPSHOT_DELETE
      If EventWindow() = #WINDOW_SNAPSHOT
        Define i.i, name.s, deletedCount.i = 0
        Define currentSelected.i = GetGadgetState(#GADGET_SNAPSHOT_LIST)
        NewList ToDelete.s()
        For i = 0 To CountGadgetItems(#GADGET_SNAPSHOT_LIST) - 1
          If i = currentSelected Or (GetGadgetItemState(#GADGET_SNAPSHOT_LIST, i) & #PB_ListIcon_Checked)
            name = StringField(GetGadgetItemText(#GADGET_SNAPSHOT_LIST, i, 0), 1, Chr(9))
            If name <> ""
              AddElement(ToDelete())
              ToDelete() = name
            EndIf
          EndIf
        Next
        If ListSize(ToDelete()) > 0
          If MessageRequester("Confirm Delete", "Delete " + Str(ListSize(ToDelete())) + " selected snapshot(s)?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
            LoadSnapshots()
            ForEach ToDelete()
              name = ToDelete()
              LogInfo("Main", "Attempting to delete snapshot name: '" + name + "'")
              If DeleteSnapshot(name, #True)
                deletedCount + 1
              Else
                LogError("Main", "Failed to delete snapshot: '" + name + "'")
              EndIf
            Next
            RefreshSnapshotList()
            UpdateStatusBar("Deleted " + Str(deletedCount) + " snapshots")
            If deletedCount < ListSize(ToDelete())
              MessageRequester("Partial Failure", "Only " + Str(deletedCount) + " of " + Str(ListSize(ToDelete())) + " snapshots were deleted." + #CRLF$ + "Check logs for details.", #PB_MessageRequester_Warning)
            EndIf
          EndIf
        Else
          MessageRequester("Info", "Please select or check snapshots to delete.", #PB_MessageRequester_Info)
        EndIf
      EndIf

    Case #GADGET_SNAPSHOT_COMPARE
      If EventWindow() = #WINDOW_SNAPSHOT
        Define checkedCount.i = 0
        Define snapshot1.s, snapshot2.s
        Define selectedIdx.i
        For selectedIdx = 0 To CountGadgetItems(#GADGET_SNAPSHOT_LIST) - 1
          If GetGadgetItemState(#GADGET_SNAPSHOT_LIST, selectedIdx) & #PB_ListIcon_Checked
            checkedCount + 1
            If checkedCount = 1
              snapshot1 = GetGadgetItemText(#GADGET_SNAPSHOT_LIST, selectedIdx, 0)
            ElseIf checkedCount = 2
              snapshot2 = GetGadgetItemText(#GADGET_SNAPSHOT_LIST, selectedIdx, 0)
            EndIf
          EndIf
        Next
        If checkedCount = 2
          If CompareThreadID = 0
            SetSnapshotControlsEnabled(#False)
            UpdateStatusBar("Starting background comparison...")
            Define *p.CompareThreadParams = AllocateMemory(SizeOf(CompareThreadParams))
            If *p
              *p\Snapshot1 = snapshot1
              *p\Snapshot2 = snapshot2
              CompareThreadID = CreateThread(@CompareThread(), *p)
              AddWindowTimer(#WINDOW_SNAPSHOT, 4002, 500)
            EndIf
          EndIf
        Else
          MessageRequester("Info", "Please check exactly 2 snapshots to compare.", #PB_MessageRequester_Info)
        EndIf
      EndIf

    Case #GADGET_SNAPSHOT_EXPORT
      If EventWindow() = #WINDOW_SNAPSHOT
        If ListSize(DiffResults()) > 0
          Define fileName.s = SaveFileRequester("Export Comparison Report", "SnapshotDiff_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".txt", "Text Files (*.txt)|*.txt|All Files (*.*)|*.*", 0)
          If fileName <> ""
            ExportDifferences(fileName)
          EndIf
        Else
          MessageRequester("Info", "No comparison results to export. Compare snapshots first.", #PB_MessageRequester_Info)
        EndIf
      EndIf

  EndSelect
EndProcedure

Procedure HandleSearchWindowGadget(gadgetID.i)
  Select gadgetID

    Case #GADGET_SEARCH_START
      If EventWindow() = #WINDOW_SEARCH
        Define searchStr.s = GetGadgetText(#GADGET_SEARCH_STRING)
        If searchStr <> ""
          ClearGadgetItems(#GADGET_SEARCH_RESULTS)
          ClearList(SearchResults())
          SearchStopRequested = #False
          DisableGadget(#GADGET_SEARCH_START, #True)
          DisableGadget(#GADGET_SEARCH_STOP, #False)
          UpdateSearchStatusLabel(#True)
          Define *sp.SearchThreadParams = AllocateMemory(SizeOf(SearchThreadParams))
          If *sp
            *sp\SearchString = searchStr
            *sp\RootKey = CurrentRootKey
            *sp\KeyPath = CurrentKeyPath
            *sp\SearchKeys = GetGadgetState(#GADGET_SEARCH_KEYS)
            *sp\SearchValues = GetGadgetState(#GADGET_SEARCH_VALUES)
            *sp\SearchData = GetGadgetState(#GADGET_SEARCH_DATA)
            SearchThreadID = CreateThread(@SearchThread(), *sp)
            AddWindowTimer(#WINDOW_SEARCH, 4001, 200)
          EndIf
        EndIf
      EndIf

    Case #GADGET_SEARCH_STOP
      If EventWindow() = #WINDOW_SEARCH
        SearchStopRequested = #True
      EndIf

    Case #GADGET_SEARCH_RESULTS
      If EventWindow() = #WINDOW_SEARCH
        If EventType() = #PB_EventType_LeftDoubleClick Or (EventType() = #PB_EventType_Change And GetGadgetState(#GADGET_SEARCH_RESULTS) <> -1)
          Define selectedResult.i = GetGadgetState(#GADGET_SEARCH_RESULTS)
          If selectedResult <> -1
            If Not SearchResultsMutex : SearchResultsMutex = CreateMutex() : EndIf
            LockMutex(SearchResultsMutex)
            SelectElement(SearchResults(), selectedResult)
            Define sRoot.i = SearchResults()\RootKey
            Define sPath.s = SearchResults()\KeyPath
            Define sValue.s = SearchResults()\ValueName
            UnlockMutex(SearchResultsMutex)
            JumpToPath(GetRootKeyName(sRoot) + "\" + sPath)
            Define vIdx.i, vCount.i = CountGadgetItems(#GADGET_LISTVIEW)
            For vIdx = 0 To vCount - 1
              If GetGadgetItemText(#GADGET_LISTVIEW, vIdx, 0) = sValue
                Define lvi.LVITEM
                lvi\mask = #LVIF_STATE
                lvi\stateMask = #LVIS_SELECTED
                lvi\state = 0
                SendMessage_(GadgetID(#GADGET_LISTVIEW), #LVM_SETITEMSTATE, -1, @lvi)
                SetGadgetState(#GADGET_LISTVIEW, vIdx)
                SendMessage_(GadgetID(#GADGET_LISTVIEW), #LVM_ENSUREVISIBLE, vIdx, #False)
                lvi\state = #LVIS_SELECTED | #LVIS_FOCUSED
                lvi\stateMask = #LVIS_SELECTED | #LVIS_FOCUSED
                SendMessage_(GadgetID(#GADGET_LISTVIEW), #LVM_SETITEMSTATE, vIdx, @lvi)
                SetActiveGadget(#GADGET_LISTVIEW)
                Break
              EndIf
            Next
          EndIf
        EndIf
      EndIf

  EndSelect
EndProcedure

Procedure HandleGadgetEvent(gadgetID.i)
  Select EventWindow()
    Case #WINDOW_MAIN
      HandleMainWindowGadget(gadgetID)

    Case #WINDOW_MONITOR
      HandleMonitorWindowGadget(gadgetID)

    Case #WINDOW_SNAPSHOT
      HandleSnapshotWindowGadget(gadgetID)

    Case #WINDOW_SEARCH
      HandleSearchWindowGadget(gadgetID)
  EndSelect
EndProcedure

Procedure HandleSizeWindowEvent()
  Select EventWindow()
    Case #WINDOW_MAIN
      ResizeGadget(#GADGET_ADDRESS_BAR, 5, 5, WindowWidth(#WINDOW_MAIN) - 60, 25)
      ResizeGadget(#GADGET_ADDRESS_GO, WindowWidth(#WINDOW_MAIN) - 50, 5, 45, 25)
      ResizeGadget(#GADGET_SPLITTER, 0, 35, WindowWidth(#WINDOW_MAIN), WindowHeight(#WINDOW_MAIN) - 55)

    Case #WINDOW_SEARCH
      ResizeGadget(#GADGET_SEARCH_STRING, 90, 10, WindowWidth(#WINDOW_SEARCH) - 300, 25)
      ResizeGadget(#GADGET_SEARCH_KEYS, 90, 40, 60, 20)
      ResizeGadget(#GADGET_SEARCH_VALUES, 160, 40, 70, 20)
      ResizeGadget(#GADGET_SEARCH_DATA, 240, 40, 60, 20)
      ResizeGadget(#GADGET_SEARCH_START, WindowWidth(#WINDOW_SEARCH) - 200, 10, 90, 25)
      ResizeGadget(#GADGET_SEARCH_STOP, WindowWidth(#WINDOW_SEARCH) - 100, 10, 90, 25)
      ResizeGadget(#GADGET_SEARCH_RESULTS, 10, 65, WindowWidth(#WINDOW_SEARCH) - 20, WindowHeight(#WINDOW_SEARCH) - 100)
      ResizeGadget(#GADGET_SEARCH_STATUS, 10, WindowHeight(#WINDOW_SEARCH) - 25, WindowWidth(#WINDOW_SEARCH) - 20, 20)

    Case #WINDOW_MONITOR
      ResizeGadget(#GADGET_MONITOR_LIST, 10, 10, WindowWidth(#WINDOW_MONITOR) - 20, WindowHeight(#WINDOW_MONITOR) - 100)
      ResizeGadget(#GADGET_MONITOR_START, 10, WindowHeight(#WINDOW_MONITOR) - 80, #PB_Ignore, #PB_Ignore)
      ResizeGadget(#GADGET_MONITOR_STOP, 120, WindowHeight(#WINDOW_MONITOR) - 80, #PB_Ignore, #PB_Ignore)
      ResizeGadget(#GADGET_MONITOR_CLEAR, 230, WindowHeight(#WINDOW_MONITOR) - 80, #PB_Ignore, #PB_Ignore)
      ResizeGadget(#GADGET_MONITOR_SAVE, 340, WindowHeight(#WINDOW_MONITOR) - 80, #PB_Ignore, #PB_Ignore)
      ResizeGadget(MonitorStatusTextGadget, WindowWidth(#WINDOW_MONITOR) - 410, WindowHeight(#WINDOW_MONITOR) - 75, 400, #PB_Ignore)

    Case #WINDOW_SNAPSHOT
      ResizeGadget(#GADGET_SNAPSHOT_LIST, 10, 10, WindowWidth(#WINDOW_SNAPSHOT) - 20, (WindowHeight(#WINDOW_SNAPSHOT) - 100) * 0.5)
      Define listHeight.i = GadgetHeight(#GADGET_SNAPSHOT_LIST)
      ResizeGadget(#GADGET_SNAPSHOT_CREATE, 10, listHeight + 20, #PB_Ignore, #PB_Ignore)
      ResizeGadget(#GADGET_SNAPSHOT_DELETE, 140, listHeight + 20, #PB_Ignore, #PB_Ignore)
      ResizeGadget(#GADGET_SNAPSHOT_COMPARE, 270, listHeight + 20, #PB_Ignore, #PB_Ignore)
      ResizeGadget(#GADGET_SNAPSHOT_EXPORT, 400, listHeight + 20, #PB_Ignore, #PB_Ignore)
      ResizeGadget(#GADGET_SNAPSHOT_DIFF, 10, listHeight + 80, WindowWidth(#WINDOW_SNAPSHOT) - 20, WindowHeight(#WINDOW_SNAPSHOT) - listHeight - 140)
  EndSelect
EndProcedure

