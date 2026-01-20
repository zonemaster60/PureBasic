;===========================================================
; File Timestamp Resetter
; - Resets file timestamps to current date/time
; - Simple GUI for selecting files
;===========================================================

EnableExplicit

#App_Name = "ResetTimeStamper"
#App_Version = "v1.0.0.2"
#EMAIL_NAME = "zonemaster60@gmail.com"

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

#Log_MaxSize = 1048576
#Log_MaxBackups = 5

#Win_Main = 0
#Win_LogViewer = 1
#Gad_Browse = 1
#Gad_Reset = 2
#Gad_List = 3
#Gad_Clear = 4
#Gad_Exit = 5
#Gad_Search = 6
#Gad_SearchText = 7
#Gad_ViewLog = 8
#Gad_DriveCombo = 9
#Gad_BrowseFolder = 10
#Gad_CheckTimestamps = 11
#Gad_LogEditor = 12
#StatusBar_Main = 0

Global NewList FileList.s()
Global NewList FileNeedsReset.i()
Global DirtySelection.i
Global LogFile.s
Global LogEnabled.i = #True
Global NewList SearchResults.s()
Global LastBrowsePath.s

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

Procedure ClearSelection()
  ClearList(FileList())
  ClearList(FileNeedsReset())
  ClearGadgetItems(#Gad_List)
  DirtySelection = #False
  DisableGadget(#Gad_Reset, #True)
  DisableGadget(#Gad_Clear, #True)
  DisableGadget(#Gad_CheckTimestamps, #True)
  SetGadgetText(#Gad_SearchText, "")
  SetStatus("Ready. Select files to reset their timestamps.")
EndProcedure

Procedure AddFileToList(filePath.s, skipGadget.i = #False)
  Protected itemIndex.i
  
  If filePath = ""
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
  
  dir = ExamineDirectory(#PB_Any, directory, "*.*")
  If dir
    While NextDirectoryEntry(dir)
      entry = DirectoryEntryName(dir)
      
      If entry <> "." And entry <> ".."
        fullPath = directory + entry
        
        If DirectoryEntryType(dir) = #PB_DirectoryEntry_Directory
          SearchInDirectory(fullPath + "\", searchText, *count)
        Else
          If FindString(LCase(entry), LCase(searchText), 1) > 0 Or
             FindString(LCase(fullPath), LCase(searchText), 1) > 0
            AddElement(SearchResults())
            SearchResults() = fullPath
            *count\i + 1
            
            If *count\i % 100 = 0
              SetStatus("Searching... Found " + Str(*count\i) + " file(s)")
            EndIf
          EndIf
        EndIf
      EndIf
    Wend
    FinishDirectory(dir)
  EndIf
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
        SetGadgetItemText(#Gad_List, itemIndex, "FUTURE (" + dateStr + ")", 1)
        SetGadgetItemColor(#Gad_List, itemIndex, #PB_Gadget_BackColor, RGB(255, 200, 200))
        flagged + 1
        FileNeedsReset() = #True
        WriteLog("FLAGGED (Future): " + FileList())
      ElseIf createdDate > fileDate
        SetGadgetItemText(#Gad_List, itemIndex, "Created>Modified (" + dateStr + ")", 1)
        SetGadgetItemColor(#Gad_List, itemIndex, #PB_Gadget_BackColor, RGB(255, 230, 200))
        flagged + 1
        FileNeedsReset() = #True
        WriteLog("FLAGGED (Created>Modified): " + FileList())
      ElseIf dateDiff > 365
        SetGadgetItemText(#Gad_List, itemIndex, ">1 year old (" + dateStr + ")", 1)
        SetGadgetItemColor(#Gad_List, itemIndex, #PB_Gadget_BackColor, RGB(255, 255, 200))
        flagged + 1
        FileNeedsReset() = #True
        WriteLog("FLAGGED (Old): " + FileList())
      Else
        SetGadgetItemText(#Gad_List, itemIndex, "OK (" + dateStr + ")", 1)
        SetGadgetItemColor(#Gad_List, itemIndex, #PB_Gadget_BackColor, RGB(200, 255, 200))
        FileNeedsReset() = #False
      EndIf
    Else
      SetGadgetItemText(#Gad_List, itemIndex, "ERROR - Cannot read", 1)
      SetGadgetItemColor(#Gad_List, itemIndex, #PB_Gadget_BackColor, RGB(255, 150, 150))
      flagged + 1
      FileNeedsReset() = #True
      WriteLog("FLAGGED (Error): " + FileList())
    EndIf
    
    itemIndex + 1
    
    If itemIndex % 50 = 0
      SetStatus("Checking... " + Str(itemIndex) + "/" + Str(total))
      WindowEvent()
    EndIf
  Next
  
  SetStatus("Check complete. " + Str(flagged) + " flagged, " + Str(total - flagged) + " OK")
  WriteLog("Timestamp check complete. Flagged: " + Str(flagged) + ", OK: " + Str(total - flagged))
  
  MessageRequester("Timestamp Check", 
                   "Total files: " + Str(total) + #CRLF$ +
                   "Flagged: " + Str(flagged) + #CRLF$ +
                   "OK: " + Str(total - flagged) + #CRLF$ + #CRLF$ +
                   "Flags:" + #CRLF$ +
                   "Red = Future date" + #CRLF$ +
                   "Orange = Created date > Modified date" + #CRLF$ +
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
        SetGadgetItemColor(#Gad_List, itemIndex, #PB_Gadget_BackColor, RGB(255, 255, 200))
        count + 1
      Else
        SetGadgetItemColor(#Gad_List, itemIndex, #PB_Gadget_BackColor, RGB(255, 255, 255))
      EndIf
      itemIndex + 1
    Next
    
    SetStatus("Found " + Str(count) + " file(s) matching '" + searchText + "'")
    WriteLog("Search results: " + Str(count) + " matches")
  Else
    drive = GetGadgetText(#Gad_DriveCombo)
    
    If drive = ""
      MessageRequester("Search", "Please select a drive to search.", #PB_MessageRequester_Warning)
      ProcedureReturn
    EndIf
    
    WriteLog("Searching drive " + drive + " for: " + searchText)
    SetStatus("Searching drive " + drive + " for '" + searchText + "'...")
    
    ClearList(SearchResults())
    countPtr\i = 0
    
    SearchInDirectory(drive, searchText, @countPtr)
    
    ClearSelection()
    
    ForEach SearchResults()
      AddFileToList(SearchResults())
    Next
    
    DisableGadget(#Gad_Reset, Bool(ListSize(FileList()) = 0))
    DisableGadget(#Gad_Clear, Bool(ListSize(FileList()) = 0))
    DisableGadget(#Gad_CheckTimestamps, Bool(ListSize(FileList()) = 0))
    
    SetStatus("Search complete. Found " + Str(countPtr\i) + " file(s) matching '" + searchText + "'")
    WriteLog("Drive search complete: " + Str(countPtr\i) + " matches")
    
    If countPtr\i = 0
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
      WindowEvent()
    EndIf
  Next
  
  DirtySelection = #True
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
    
    DisableGadget(#Gad_Reset, Bool(ListSize(FileList()) = 0))
    DisableGadget(#Gad_Clear, Bool(ListSize(FileList()) = 0))
    DisableGadget(#Gad_CheckTimestamps, Bool(ListSize(FileList()) = 0))
    SetStatus("Selected " + Str(ListSize(FileList())) + " file(s)")
  EndIf
EndProcedure

Procedure AddFilesFromDirectory(directory.s, *count.Integer)
  Protected dir.i
  Protected entry.s
  Protected fullPath.s
  
  dir = ExamineDirectory(#PB_Any, directory, "*.*")
  If dir
    While NextDirectoryEntry(dir)
      entry = DirectoryEntryName(dir)
      
      If entry <> "." And entry <> ".."
        fullPath = directory + entry
        
        If DirectoryEntryType(dir) = #PB_DirectoryEntry_File
          AddFileToList(fullPath, #True)
          *count\i + 1
          
          If *count\i % 100 = 0
            SetStatus("Loading... " + Str(*count\i) + " file(s)")
            WindowEvent()
          EndIf
        Else
          AddFilesFromDirectory(fullPath + "\", *count)
        EndIf
      EndIf
    Wend
    FinishDirectory(dir)
  EndIf
EndProcedure

Procedure BrowseFolder()
  Protected folder.s
  Protected countPtr.Integer
  Protected i.i
  Protected defaultPath.s
  
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
    SetStatus("Loading files from folder...")
    
    countPtr\i = 0
    AddFilesFromDirectory(folder, @countPtr)
    
    SetStatus("Populating list...")
    ForEach FileList()
      AddGadgetItem(#Gad_List, -1, FileList() + #TAB$ + "Ready")
      i + 1
      If i % 500 = 0
        SetStatus("Populating list... " + Str(i) + "/" + Str(countPtr\i))
        WindowEvent()
      EndIf
    Next
    
    DisableGadget(#Gad_Reset, Bool(ListSize(FileList()) = 0))
    DisableGadget(#Gad_Clear, Bool(ListSize(FileList()) = 0))
    DisableGadget(#Gad_CheckTimestamps, Bool(ListSize(FileList()) = 0))
    SetStatus("Loaded " + Str(ListSize(FileList())) + " file(s) from folder")
    WriteLog("Loaded " + Str(ListSize(FileList())) + " file(s) from folder")
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

Procedure ShowAbout()
  Protected msg.s
  msg = #App_Name + " - " + #App_Version + #CRLF$ +
        "-----------------------------------------" + #CRLF$ +
        "Resets file modified timestamps to the current time." + #CRLF$ +
        "Contact: " + #EMAIL_NAME + #CRLF$ +
        "Website: https://github.com/zonemaster60"
  MessageRequester("About", msg, #PB_MessageRequester_Info)
EndProcedure

Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseHandle_(hMutex)
    End
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
  If OpenWindow(#Win_Main, 0, 0, 700, 480, #App_Name, 
                #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
    
    CreateMenu(0, WindowID(#Win_Main))
    MenuTitle("File")
    MenuItem(1, "Exit")
    MenuTitle("Tools")
    MenuItem(3, "View Log")
    MenuItem(4, "Check Timestamps")
    MenuTitle("Help")
    MenuItem(2, "About...")
    
    ButtonGadget(#Gad_Browse, 10, 10, 100, 30, "Browse Files")
    ButtonGadget(#Gad_BrowseFolder, 120, 10, 100, 30, "Browse Folder")
    ButtonGadget(#Gad_CheckTimestamps, 230, 10, 130, 30, "Check Timestamps")
    ButtonGadget(#Gad_Reset, 370, 10, 130, 30, "Reset Timestamps")
    DisableGadget(#Gad_Reset, #True)
    ButtonGadget(#Gad_Clear, 510, 10, 60, 30, "Clear")
    ButtonGadget(#Gad_ViewLog, 580, 10, 80, 30, "View Log")
    
    TextGadget(#PB_Any, 10, 50, 50, 20, "Drive:")
    ComboBoxGadget(#Gad_DriveCombo, 60, 48, 80, 24)
    PopulateDrives()
    
    TextGadget(#PB_Any, 150, 50, 50, 20, "Search:")
    StringGadget(#Gad_SearchText, 200, 48, 300, 24, "")
    ButtonGadget(#Gad_Search, 510, 48, 80, 24, "Search")
    
    ListIconGadget(#Gad_List, 10, 80, 680, 360, "Selected Files", 480, #PB_ListIcon_GridLines)
    AddGadgetColumn(#Gad_List, 1, "Timestamp Status", 180)
    EnableGadgetDrop(#Gad_List, #PB_Drop_Files, #PB_Drag_Copy)
    
    CreateStatusBar(#StatusBar_Main, WindowID(#Win_Main))
    AddStatusBarField(#PB_Ignore)
    DisableGadget(#Gad_Clear, #True)
    SetStatus("Ready. Select files to reset their timestamps.")
  EndIf
EndProcedure

LogFile = GetCurrentDirectory() + #App_Name + ".log"
WriteLog("Application started - " + #App_Name + " - " + #App_Version)

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
          
        Case #Gad_Exit
          Exit()
                    
      EndSelect
      
    Case #PB_Event_Menu
      Select EventMenu()
        Case 1
          Exit()
          
        Case 2
          ShowAbout()
          
        Case 3
          ViewLog()
          
        Case 4
          CheckTimestamps()
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
        
        DisableGadget(#Gad_Reset, Bool(ListSize(FileList()) = 0))
        DisableGadget(#Gad_Clear, Bool(ListSize(FileList()) = 0))
        DisableGadget(#Gad_CheckTimestamps, Bool(ListSize(FileList()) = 0))
        SetStatus("Selected " + Str(ListSize(FileList())) + " file(s)")
      EndIf
      
    Case #PB_Event_CloseWindow
      Exit()
      
  EndSelect
ForEver

WriteLog("Application closed")

End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 9
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = ResetTimeStamper.ico
; Executable = ..\ResetTimeStamper.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = ResetTimeStamper
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = Resets any file/files timestamp
; VersionField7 = ResetTimeStamper
; VersionField8 = ResetTimeStamper.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60