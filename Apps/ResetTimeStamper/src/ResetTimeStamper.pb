;===========================================================
; File Timestamp Resetter
; - Resets file timestamps to current date/time
; - Simple GUI for selecting files
;===========================================================

EnableExplicit

#App_Name = "ResetTimeStamper"
#EMAIL_NAME = "zonemaster60@gmail.com"
Global version.s = "v1.0.0.4"

Declare WriteLog(msg.s)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #App_Name + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #App_Name + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Procedure.i ConfirmExit()
  Protected req.i

  req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  ProcedureReturn Bool(req = #PB_MessageRequester_Yes)
EndProcedure

Procedure Shutdown()
  WriteLog("Application closed")

  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
EndProcedure

Procedure ShowAbout()
  Protected msg.s
  msg = #App_Name + " - " + version + #CRLF$ +
        "-----------------------------------------" + #CRLF$ +
        "Resets file modified timestamps to the current time." + #CRLF$ +
        "Contact: " + #EMAIL_NAME + #CRLF$ +
        "Website: https://github.com/zonemaster60"
  MessageRequester("About", msg, #PB_MessageRequester_Info)
EndProcedure

#Log_MaxSize = 1048576
#Log_MaxBackups = 5

#Color_StatusFuture = $C8C8FF
#Color_StatusCreatedAfterModified = $C8E6FF
#Color_StatusOld = $C8FFFF
#Color_StatusOk = $C8FFC8
#Color_StatusError = $9696FF
#Color_SearchMatch = $C8FFFF
#Color_SearchDefault = $FFFFFF

#Win_Main = 0
#Win_LogViewer = 1
#Gad_Browse = 1
#Gad_Reset = 2
#Gad_List = 3
#Gad_Clear = 4
#Gad_Cancel = 5
#Gad_Search = 6
#Gad_SearchText = 7
#Gad_ViewLog = 8
#Gad_DriveCombo = 9
#Gad_BrowseFolder = 10
#Gad_CheckTimestamps = 11
#Gad_LogEditor = 12
#StatusBar_Main = 0

#Menu_Exit = 1
#Menu_About = 2
#Menu_ViewLog = 3
#Menu_CheckTimestamps = 4
#Menu_CancelOperation = 5
#Shortcut_Cancel = 100

Global NewList FileList.s()
Global NewList FileNeedsReset.i()
Global LogFile.s
Global LogEnabled.i = #True
Global NewList SearchResults.s()
Global LastBrowsePath.s
Global CancelRequested.i
Global OperationActive.i

LogFile = GetPathPart(ProgramFilename()) + #App_Name + ".log"


Procedure WriteLog(msg.s)
  Protected file.i
  
  If Not LogEnabled
    ProcedureReturn
  EndIf
  
  file = OpenFile(#PB_Any, LogFile, #PB_File_Append | #PB_File_SharedRead)
  If file
    WriteStringN(file, FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + msg)
    CloseFile(file)
  EndIf
EndProcedure

Procedure RotateLog()
  Protected logSize.q
  Protected i.i
  Protected oldFile.s, newFile.s
  
  If Not FileSize(LogFile) >= 0
    ProcedureReturn
  EndIf
  
  logSize = FileSize(LogFile)
  
  If logSize >= #Log_MaxSize
    For i = #Log_MaxBackups - 1 To 1 Step -1
      oldFile = LogFile + "." + Str(i)
      newFile = LogFile + "." + Str(i + 1)
      
      If FileSize(oldFile) >= 0
        DeleteFile(newFile)
        RenameFile(oldFile, newFile)
      EndIf
    Next
    
    newFile = LogFile + ".1"
    DeleteFile(newFile)
    RenameFile(LogFile, newFile)
    
    WriteLog("Log rotated - new log file started")
  EndIf
EndProcedure

Procedure SetStatus(msg.s)
  StatusBarText(#StatusBar_Main, 0, msg)
  WriteLog(msg)
EndProcedure

Procedure BeginOperation(operationName.s)
  OperationActive = #True
  CancelRequested = #False
  DisableMenuItem(0, #Menu_CancelOperation, #False)
  DisableGadget(#Gad_Cancel, #False)
  SetStatus(operationName + "... Press Cancel to stop.")
EndProcedure

Procedure EndOperation(statusText.s = "")
  OperationActive = #False
  CancelRequested = #False
  DisableMenuItem(0, #Menu_CancelOperation, #True)
  DisableGadget(#Gad_Cancel, #True)

  If statusText <> ""
    SetStatus(statusText)
  EndIf
EndProcedure

Procedure RequestCancel()
  If OperationActive And CancelRequested = #False
    CancelRequested = #True
    SetStatus("Cancel requested... finishing current step.")
    WriteLog("Operation cancellation requested by user")
  EndIf
EndProcedure

Procedure.i PumpUi()
  Protected event.i
  Protected menuId.i

  Repeat
    event = WindowEvent()
    If event = 0
      Break
    EndIf

    Select event
      Case #PB_Event_Gadget
        If EventGadget() = #Gad_Cancel
          RequestCancel()
        EndIf

      Case #PB_Event_Menu
        menuId = EventMenu()
        If menuId = #Menu_CancelOperation Or menuId = #Shortcut_Cancel
          RequestCancel()
        EndIf
    EndSelect
  ForEver

  ProcedureReturn CancelRequested
EndProcedure

Procedure UpdateActionButtons()
  Protected hasFiles.i
  Protected disableState.i

  hasFiles = Bool(ListSize(FileList()) > 0)
  disableState = Bool(hasFiles = #False)
  DisableGadget(#Gad_Reset, disableState)
  DisableGadget(#Gad_Clear, disableState)
  DisableGadget(#Gad_CheckTimestamps, disableState)
EndProcedure

Procedure.i FileAlreadyListed(filePath.s)
  ForEach FileList()
    If LCase(FileList()) = LCase(filePath)
      ProcedureReturn #True
    EndIf
  Next

  ProcedureReturn #False
EndProcedure

Procedure SetListRowColor(itemIndex.i, color.i)
  SetGadgetItemColor(#Gad_List, itemIndex, #PB_Gadget_BackColor, color)
EndProcedure

Procedure SetTimestampStatus(itemIndex.i, statusText.s, color.i, needsReset.i)
  SetGadgetItemText(#Gad_List, itemIndex, statusText, 1)
  SetListRowColor(itemIndex, color)
  FileNeedsReset() = needsReset
EndProcedure

Procedure ClearSelection()
  ClearList(FileList())
  ClearList(FileNeedsReset())
  ClearGadgetItems(#Gad_List)
  UpdateActionButtons()
  SetGadgetText(#Gad_SearchText, "")
  SetStatus("Ready. Select files to reset their timestamps.")
EndProcedure

Procedure AddFileToList(filePath.s, skipGadget.i = #False)
  Protected itemIndex.i
  
  If filePath = "" Or FileSize(filePath) < 0 Or FileAlreadyListed(filePath)
    ProcedureReturn
  EndIf
  
  AddElement(FileList())
  FileList() = filePath
  AddElement(FileNeedsReset())
  FileNeedsReset() = #True
  
  If Not skipGadget
    itemIndex = AddGadgetItem(#Gad_List, -1, filePath + #TAB$ + "Ready")
  EndIf
EndProcedure

Procedure SearchInDirectory(directory.s, searchText.s, *count.Integer)
  Protected dir.i
  Protected entry.s
  Protected fullPath.s
  Protected searchTextLower.s
  Protected currentDirectory.s
  Protected lastUpdate.i
  Protected NewList pendingDirectories.s()

  If Right(directory, 1) <> "\" And Right(directory, 1) <> "/"
    directory + "\"
  EndIf

  AddElement(pendingDirectories())
  pendingDirectories() = directory
  searchTextLower = LCase(searchText)
  lastUpdate = ElapsedMilliseconds()

  While ListSize(pendingDirectories()) > 0
    LastElement(pendingDirectories())
    currentDirectory = pendingDirectories()
    DeleteElement(pendingDirectories())

    dir = ExamineDirectory(#PB_Any, currentDirectory, "*.*")
    If dir = 0
      WriteLog("WARNING: Cannot access folder during search: " + currentDirectory)
      If PumpUi()
        ProcedureReturn
      EndIf
      Continue
    EndIf

    While NextDirectoryEntry(dir)
      If CancelRequested
        FinishDirectory(dir)
        ProcedureReturn
      EndIf

      entry = DirectoryEntryName(dir)

      If entry <> "." And entry <> ".."
        fullPath = currentDirectory + entry

        If DirectoryEntryType(dir) = #PB_DirectoryEntry_Directory
          If Right(fullPath, 1) <> "\" And Right(fullPath, 1) <> "/"
            fullPath + "\"
          EndIf

          AddElement(pendingDirectories())
          pendingDirectories() = fullPath
        ElseIf searchText = "*" Or
               FindString(LCase(entry), searchTextLower, 1) > 0 Or
               FindString(LCase(fullPath), searchTextLower, 1) > 0
          AddElement(SearchResults())
          SearchResults() = fullPath
          *count\i + 1

          If ElapsedMilliseconds() - lastUpdate > 100
            SetStatus("Searching... Found " + Str(*count\i) + " file(s)")
            If PumpUi()
              FinishDirectory(dir)
              ProcedureReturn
            EndIf
            lastUpdate = ElapsedMilliseconds()
          EndIf
        EndIf
      EndIf
    Wend

    FinishDirectory(dir)

    If PumpUi()
      ProcedureReturn
    EndIf
  Wend
EndProcedure


Procedure CheckTimestamps()
  Protected itemIndex.i = 0
  Protected fileDate.i
  Protected createdDate.i
  Protected currentDate.i
  Protected dateDiff.i
  Protected dateStr.s
  Protected flagged.i = 0
  Protected total.i
  
  If ListSize(FileList()) = 0
    SetStatus("No files to check.")
    ProcedureReturn
  EndIf
  
  total = ListSize(FileList())
  currentDate = Date()
  WriteLog("Checking timestamps for " + Str(total) + " file(s)")
  SetStatus("Checking timestamps...")
  
  ResetList(FileNeedsReset())
  ForEach FileList()
    NextElement(FileNeedsReset())
    
    fileDate = GetFileDate(FileList(), #PB_Date_Modified)
    createdDate = GetFileDate(FileList(), #PB_Date_Created)
    
    If fileDate > 0
      dateStr = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", fileDate)
      dateDiff = (currentDate - fileDate) / (3600 * 24)
      
      If fileDate > currentDate
        SetTimestampStatus(itemIndex, "FUTURE (" + dateStr + ")", #Color_StatusFuture, #True)
        flagged + 1
        WriteLog("FLAGGED (Future): " + FileList())
      ElseIf createdDate > fileDate
        SetTimestampStatus(itemIndex, "Created>Modified (" + dateStr + ")", #Color_StatusCreatedAfterModified, #True)
        flagged + 1
        WriteLog("FLAGGED (Created>Modified): " + FileList())
      ElseIf dateDiff > 365
        SetTimestampStatus(itemIndex, ">1 year old (" + dateStr + ")", #Color_StatusOld, #True)
        flagged + 1
        WriteLog("FLAGGED (Old): " + FileList())
      Else
        SetTimestampStatus(itemIndex, "OK (" + dateStr + ")", #Color_StatusOk, #False)
      EndIf
    Else
      SetTimestampStatus(itemIndex, "ERROR - Cannot read", #Color_StatusError, #True)
      flagged + 1
      WriteLog("FLAGGED (Error): " + FileList())
    EndIf
    
    itemIndex + 1
    
    If itemIndex % 50 = 0
      SetStatus("Checking... " + Str(itemIndex) + "/" + Str(total))
      PumpUi()
    EndIf
  Next
  
  SetStatus("Check complete. " + Str(flagged) + " flagged, " + Str(total - flagged) + " OK")
  WriteLog("Timestamp check complete. Flagged: " + Str(flagged) + ", OK: " + Str(total - flagged))
  
  MessageRequester("Timestamp Check", 
                   "Total files: " + Str(total) + #CRLF$ +
                   "Flagged: " + Str(flagged) + #CRLF$ +
                   "OK: " + Str(total - flagged) + #CRLF$ + #CRLF$ +
                   "Color legend:" + #CRLF$ +
                   "Red = Future date" + #CRLF$ +
                   "Orange = Created date later than modified date" + #CRLF$ +
                   "Yellow = Over 1 year old" + #CRLF$ +
                   "Green = OK",
                   #PB_MessageRequester_Info)
EndProcedure

Procedure SearchFiles()
  Protected searchText.s
  Protected count.i = 0
  Protected itemIndex.i = 0
  Protected filePath.s
  Protected found.i
  Protected drive.s
  Protected countPtr.Integer
  Protected searchWasCancelled.i
  
  searchText = GetGadgetText(#Gad_SearchText)
  
  If searchText = ""
    MessageRequester("Search", "Please enter a search term.", #PB_MessageRequester_Warning)
    ProcedureReturn
  EndIf
  
  If ListSize(FileList()) > 0
    WriteLog("Searching in file list for: " + searchText)
    
    ForEach FileList()
      filePath = FileList()
      found = FindString(LCase(filePath), LCase(searchText), 1)
      
      If found > 0
        SetListRowColor(itemIndex, #Color_SearchMatch)
        count + 1
      Else
        SetListRowColor(itemIndex, #Color_SearchDefault)
      EndIf
      itemIndex + 1
    Next
    
    SetStatus("Found " + Str(count) + " file(s) matching '" + searchText + "' in the current list")
    WriteLog("Search results: " + Str(count) + " matches")
  Else
    drive = GetGadgetText(#Gad_DriveCombo)
    
    If drive = ""
      MessageRequester("Search", "Please select a drive to search.", #PB_MessageRequester_Warning)
      ProcedureReturn
    EndIf
    
    WriteLog("Searching drive " + drive + " for: " + searchText)
    BeginOperation("Searching drive " + drive + " for '" + searchText + "'")
    
    ClearList(SearchResults())
    countPtr\i = 0
    
    SearchInDirectory(drive, searchText, @countPtr)
    searchWasCancelled = CancelRequested
    
    ClearSelection()
    
    ForEach SearchResults()
      AddFileToList(SearchResults())
    Next
    
    UpdateActionButtons()

    If searchWasCancelled
      EndOperation("Search cancelled. Found " + Str(countPtr\i) + " file(s) before cancellation.")
      WriteLog("Drive search cancelled: " + Str(countPtr\i) + " matches before cancellation")
    Else
      EndOperation("Search complete. Found " + Str(countPtr\i) + " file(s) matching '" + searchText + "'")
      WriteLog("Drive search complete: " + Str(countPtr\i) + " matches")
    EndIf
    
    If countPtr\i = 0 And searchWasCancelled = #False
      MessageRequester("Search", "No files found matching '" + searchText + "'", #PB_MessageRequester_Info)
    EndIf
  EndIf
EndProcedure

Procedure ResetTimestamps()
  Protected count.i = 0
  Protected failed.i = 0
  Protected skipped.i = 0
  Protected currentTime.i
  Protected itemIndex.i = 0
  Protected ok.i
  
  If ListSize(FileList()) = 0
    SetStatus("No files selected.")
    ProcedureReturn
  EndIf
  
  currentTime = Date()
  WriteLog("Starting timestamp reset for flagged files")
  
  ResetList(FileNeedsReset())
  ForEach FileList()
    NextElement(FileNeedsReset())
    
    If FileNeedsReset()
      ok = SetFileDate(FileList(), #PB_Date_Modified, currentTime)
      If ok
        count + 1
        SetGadgetItemText(#Gad_List, itemIndex, "Success", 1)
        WriteLog("SUCCESS: " + FileList())
      Else
        failed + 1
        SetGadgetItemText(#Gad_List, itemIndex, "Failed", 1)
        WriteLog("FAILED: " + FileList())
      EndIf
    Else
      skipped + 1
      WriteLog("SKIPPED (already OK): " + FileList())
    EndIf
    itemIndex + 1
    
    If itemIndex % 50 = 0
      SetStatus("Resetting... " + Str(count) + " done, " + Str(itemIndex) + "/" + Str(ListSize(FileList())))
      PumpUi()
    EndIf
  Next
  
  SetStatus("Reset " + Str(count) + " file(s). Failed: " + Str(failed) + ", Skipped: " + Str(skipped))
  WriteLog("Timestamp reset complete. Success: " + Str(count) + ", Failed: " + Str(failed) + ", Skipped: " + Str(skipped))
  
  RotateLog()
  
  If count > 0
    MessageRequester("Success", "Successfully reset timestamps for " + Str(count) + " file(s)." + 
                     #CRLF$ + "Skipped (already OK): " + Str(skipped) +
                     #CRLF$ + "New timestamp: " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", currentTime),
                     #PB_MessageRequester_Info)
    CheckTimestamps()
  ElseIf skipped > 0
    MessageRequester("Info", "All files are already OK. No timestamps were reset.", #PB_MessageRequester_Info)
  EndIf
EndProcedure

Procedure BrowseFiles()
  Protected pattern.s
  Protected defaultPath.s
  
  If LastBrowsePath <> ""
    defaultPath = LastBrowsePath
  Else
    defaultPath = GetCurrentDirectory()
  EndIf
  
  pattern = OpenFileRequester("Select Files", defaultPath, "All Files (*.*)|*.*", 0, #PB_Requester_MultiSelection)
  
  If pattern <> ""
    LastBrowsePath = GetPathPart(pattern)
    
    ClearSelection()
    
    While pattern <> ""
      AddFileToList(pattern)
      pattern = NextSelectedFileName()
    Wend
    
    UpdateActionButtons()
    SetStatus("Selected " + Str(ListSize(FileList())) + " file(s)")
  EndIf
EndProcedure

Procedure AddFilesFromDirectory(directory.s, *count.Integer)
  Protected dir.i
  Protected entry.s
  Protected fullPath.s
  Protected currentDirectory.s
  Protected NewList pendingDirectories.s()

  If Right(directory, 1) <> "\" And Right(directory, 1) <> "/"
    directory + "\"
  EndIf

  AddElement(pendingDirectories())
  pendingDirectories() = directory

  While ListSize(pendingDirectories()) > 0
    LastElement(pendingDirectories())
    currentDirectory = pendingDirectories()
    DeleteElement(pendingDirectories())

    dir = ExamineDirectory(#PB_Any, currentDirectory, "*.*")
    If dir = 0
      WriteLog("WARNING: Cannot access folder while loading: " + currentDirectory)
      If PumpUi()
        ProcedureReturn
      EndIf
      Continue
    EndIf

    While NextDirectoryEntry(dir)
      If CancelRequested
        FinishDirectory(dir)
        ProcedureReturn
      EndIf

      entry = DirectoryEntryName(dir)

      If entry <> "." And entry <> ".."
        fullPath = currentDirectory + entry

        If DirectoryEntryType(dir) = #PB_DirectoryEntry_File
          AddFileToList(fullPath, #True)
          *count\i + 1

          If *count\i % 100 = 0
            SetStatus("Loading... " + Str(*count\i) + " file(s)")
            If PumpUi()
              FinishDirectory(dir)
              ProcedureReturn
            EndIf
          EndIf
        Else
          If Right(fullPath, 1) <> "\" And Right(fullPath, 1) <> "/"
            fullPath + "\"
          EndIf

          AddElement(pendingDirectories())
          pendingDirectories() = fullPath
        EndIf
      EndIf
    Wend

    FinishDirectory(dir)

    If PumpUi()
      ProcedureReturn
    EndIf
  Wend
EndProcedure


Procedure BrowseFolder()
  Protected folder.s
  Protected countPtr.Integer
  Protected i.i
  Protected defaultPath.s
  Protected loadWasCancelled.i
  
  If LastBrowsePath <> ""
    defaultPath = LastBrowsePath
  Else
    defaultPath = GetCurrentDirectory()
  EndIf
  
  folder = PathRequester("Select Folder", defaultPath)
  
  If folder <> ""
    LastBrowsePath = folder
    
    ClearSelection()
    
    WriteLog("Browsing folder: " + folder)
    BeginOperation("Loading files from folder")
    
    countPtr\i = 0
    AddFilesFromDirectory(folder, @countPtr)
    loadWasCancelled = CancelRequested
    
    SetStatus("Populating list...")
    ForEach FileList()
      If i % 500 = 0 And PumpUi()
        loadWasCancelled = #True
        Break
      EndIf

      AddGadgetItem(#Gad_List, -1, FileList() + #TAB$ + "Ready")
      i + 1
      If i % 500 = 0
        SetStatus("Populating list... " + Str(i) + "/" + Str(countPtr\i))
      EndIf
    Next
    
    UpdateActionButtons()

    If loadWasCancelled
      EndOperation("Folder load cancelled. Loaded " + Str(ListSize(FileList())) + " file(s) before cancellation.")
      WriteLog("Folder load cancelled: " + Str(ListSize(FileList())) + " file(s) loaded before cancellation")
    Else
      EndOperation("Loaded " + Str(ListSize(FileList())) + " file(s) from folder")
      WriteLog("Loaded " + Str(ListSize(FileList())) + " file(s) from folder")
    EndIf
  EndIf
EndProcedure

Procedure ViewLog()
  Protected file.i
  Protected content.s = ""
  Protected line.s
  Protected event.i
  
  If FileSize(LogFile) < 0
    MessageRequester("View Log", "Log file not found or empty.", #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf
  
  file = ReadFile(#PB_Any, LogFile, #PB_File_SharedRead)
  If file
    While Not Eof(file)
      line = ReadString(file)
      content + line + #CRLF$
    Wend
    CloseFile(file)
    
    If OpenWindow(#Win_LogViewer, 0, 0, 600, 400, "Log File - " + LogFile,
                  #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_WindowCentered)
      
      EditorGadget(#Gad_LogEditor, 0, 0, 600, 400, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
      SetGadgetText(#Gad_LogEditor, content)
      
      Repeat
        event = WaitWindowEvent()
        If event = #PB_Event_CloseWindow And EventWindow() = #Win_LogViewer
          Break
        EndIf
      ForEver
      
      CloseWindow(#Win_LogViewer)
    EndIf
  Else
    MessageRequester("Error", "Could not open log file.", #PB_MessageRequester_Error)
  EndIf
EndProcedure

Procedure PopulateDrives()
  Protected drive.i
  Protected drivePath.s
  
  For drive = Asc("A") To Asc("Z")
    drivePath = Chr(drive) + ":\"
    If FileSize(drivePath) = -2
      AddGadgetItem(#Gad_DriveCombo, -1, Chr(drive) + ":\")
    EndIf
  Next
  
  SetGadgetState(#Gad_DriveCombo, 0)
EndProcedure

Procedure CreateMainWindow()
  If OpenWindow(#Win_Main, 0, 0, 700, 520, #App_Name + " - " + version, 
                 #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
    
    CreateMenu(0, WindowID(#Win_Main))
    MenuTitle("File")
    MenuItem(#Menu_Exit, "Exit")
    MenuTitle("Tools")
    MenuItem(#Menu_ViewLog, "View Log")
    MenuItem(#Menu_CheckTimestamps, "Check Timestamps")
    MenuItem(#Menu_CancelOperation, "Cancel Current Operation")
    DisableMenuItem(0, #Menu_CancelOperation, #True)
    MenuTitle("Help")
    MenuItem(#Menu_About, "About...")
    AddKeyboardShortcut(#Win_Main, #PB_Shortcut_Escape, #Shortcut_Cancel)
    
    ; Action Group
    ContainerGadget(#PB_Any, 10, 10, 680, 50, #PB_Container_Flat)
      ButtonGadget(#Gad_Browse, 5, 10, 100, 30, "Browse Files")
      ButtonGadget(#Gad_BrowseFolder, 110, 10, 110, 30, "Browse Folder")
      ButtonGadget(#Gad_CheckTimestamps, 225, 10, 130, 30, "Check Timestamps")
      ButtonGadget(#Gad_Reset, 360, 10, 130, 30, "Reset Timestamps")
      DisableGadget(#Gad_Reset, #True)
      ButtonGadget(#Gad_Clear, 495, 10, 80, 30, "Clear List")
      ButtonGadget(#Gad_ViewLog, 580, 10, 90, 30, "View Log")
    CloseGadgetList()
    
    ; Search Group
    ContainerGadget(#PB_Any, 10, 65, 680, 45, #PB_Container_Flat)
      TextGadget(#PB_Any, 10, 15, 40, 20, "Drive:")
      ComboBoxGadget(#Gad_DriveCombo, 50, 12, 80, 24)
      PopulateDrives()
      
      TextGadget(#PB_Any, 150, 15, 80, 20, "Search Term:")
      StringGadget(#Gad_SearchText, 235, 12, 340, 24, "")
      ButtonGadget(#Gad_Search, 580, 11, 90, 26, "Search")
    CloseGadgetList()

    ListIconGadget(#Gad_List, 10, 115, 680, 330, "Selected Files", 450, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(#Gad_List, 1, "Timestamp Status", 200)
    EnableGadgetDrop(#Gad_List, #PB_Drop_Files, #PB_Drag_Copy)
    ButtonGadget(#Gad_Cancel, 590, 452, 100, 26, "Cancel")
    DisableGadget(#Gad_Cancel, #True)
    
    CreateStatusBar(#StatusBar_Main, WindowID(#Win_Main))
    AddStatusBarField(#PB_Ignore)
    DisableGadget(#Gad_Clear, #True)
    SetStatus("Ready. Select files to reset their timestamps.")
  EndIf
EndProcedure


WriteLog("Application started - " + #App_Name + " - " + version)

CreateMainWindow()


Define Event, Gadget
Define droppedFile.s, dropCount.i, i.i

Repeat
  Event = WaitWindowEvent()
  
  Select Event
    Case #PB_Event_Gadget
      Gadget = EventGadget()
      
      Select Gadget
        Case #Gad_Browse
          BrowseFiles()
          
        Case #Gad_BrowseFolder
          BrowseFolder()
          
        Case #Gad_CheckTimestamps
          CheckTimestamps()
          
        Case #Gad_Reset
          ResetTimestamps()
          
        Case #Gad_Clear
          ClearSelection()
          
        Case #Gad_Search
          SearchFiles()
          
        Case #Gad_ViewLog
          ViewLog()
          
        Case #Gad_Cancel
          RequestCancel()
                     
      EndSelect
      
    Case #PB_Event_Menu
      Select EventMenu()
        Case #Menu_Exit
            If ConfirmExit()
              Break
            EndIf
          
        Case #Menu_About
          ShowAbout()
          
        Case #Menu_ViewLog
          ViewLog()
          
        Case #Menu_CheckTimestamps
          CheckTimestamps()

        Case #Menu_CancelOperation, #Shortcut_Cancel
          RequestCancel()
      EndSelect
      
    Case #PB_Event_GadgetDrop
      If EventGadget() = #Gad_List
        droppedFile = EventDropFiles()
        
        ClearSelection()
        While droppedFile <> ""
          If FileSize(droppedFile) >= 0
            AddFileToList(droppedFile)
          EndIf
          droppedFile = EventDropFiles()
        Wend
        
        UpdateActionButtons()
        SetStatus("Selected " + Str(ListSize(FileList())) + " file(s)")
      EndIf
      
    Case #PB_Event_CloseWindow
      If ConfirmExit()
        Break
      EndIf
      
  EndSelect
ForEver

Shutdown()

End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 10
; Folding = -----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = ResetTimeStamper.ico
; Executable = ..\ResetTimeStamper.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,4
; VersionField1 = 1,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = ResetTimeStamper
; VersionField4 = 1.0.0.4
; VersionField5 = 1.0.0.4
; VersionField6 = Resets any file/files timestamp
; VersionField7 = ResetTimeStamper
; VersionField8 = ResetTimeStamper.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60