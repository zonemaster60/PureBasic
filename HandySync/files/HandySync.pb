; ***************** handysync by David Scouten *****************
; ******************* zonemaster@yahoo.com ********************
;
EnableExplicit

; Structure to hold file metadata (currently just the timestamp)
Structure FileInfo
  time.q
EndStructure

Enumeration
  #BufferSizeCombo
EndEnumeration

; Folder paths
Global folderA.s
Global folderB.s
Global NewMap folderPaths.s() ; Holds relative folder paths
Global NewMap createdFolders.i() ; Tracks folders created during this session

; Logging
Global logFile.s = GetUserDirectory(#PB_Directory_Documents) + "HandySync.log"
Global loggingEnabled.i = #True, changeFolder = #False

; Sync Timing
Global syncTime.i = 5000 ;change this to adjust time between syncing.
Global syncStartTime.q, syncEndTime.q, syncDuration.d, syncPaused.i = #False
Global blinkTimer.q = 0, blinkState.i = 0

; UI elements
Global progressWindow, progressBar, progressLabel, fileList, loggingCheckbox, pauseButton
Global folderButton, exitButton

; Counters
Global totalFiles.i, currentFileIndex.i
Global copiedCount.i, updatedCount.i, errorCount.i, folderCount.i
Global version.s = "v0.1.2.0"

; Exit here
Procedure Exit()
Protected Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure

; Logs sync actions to a file with timestamp
Procedure LogSync(action.s, source.s, dest.s)
  If IsGadget(loggingCheckbox) And GetGadgetState(loggingCheckbox) = 0
    ProcedureReturn ; Skip logging if checkbox is unchecked
  EndIf
  Protected timestamp.s = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  Protected entry.s = timestamp + " | " + action + " | " + source + " → " + dest + #CRLF$
  If OpenFile(0, logFile, #PB_File_Append)
    WriteString(0, entry)
    CloseFile(0)
  Else
    MessageRequester("Error", "Failed to write to log file: " + logFile, #PB_MessageRequester_Error)
  EndIf
EndProcedure

; Retrieves the last modified time of a file using Windows API
Procedure.q GetFileTime(path.s)
  Protected info.FILETIME, hFile = CreateFile_(path, #GENERIC_READ, #FILE_SHARE_READ, 0, #OPEN_EXISTING, #FILE_ATTRIBUTE_NORMAL, 0)
  If hFile
    GetFileTime_(hFile, 0, 0, @info)
    CloseHandle_(hFile)
    ProcedureReturn (info\dwHighDateTime << 32) + info\dwLowDateTime
  EndIf
  ProcedureReturn 0
EndProcedure

; Get and return the bufferSize
Procedure GetSelectedBufferSize()
  Select GetGadgetText(#BufferSizeCombo)
    Case "64 KB"   : ProcedureReturn 65536
    Case "128 KB"  : ProcedureReturn 131072
    Case "256 KB"  : ProcedureReturn 262144
    Case "512 KB"  : ProcedureReturn 524288
    Case "1 MB"    : ProcedureReturn 1048576
  EndSelect
  ProcedureReturn 262144 ; Default fallback
EndProcedure

; fast file copy
Procedure FastCopyFile(source.s, dest.s)

  Protected bufferSize = 262144 ; 256KB Buffer
  Protected *buffer = AllocateMemory(bufferSize)
  If *buffer = 0
    AddGadgetItem(fileList, -1, "[ERROR] Memory allocation failed")
    ProcedureReturn #False
  EndIf

  Protected srcID = OpenFile(#PB_Any, source)
  If srcID = 0
    AddGadgetItem(fileList, -1, "[ERROR] Failed to open source: " + source)
    LogSync("[Error] Failed to open source: ", "", source)
    FreeMemory(*buffer)
    ProcedureReturn #False
  EndIf

  Protected dstID = CreateFile(#PB_Any, dest)
  If dstID = 0
    AddGadgetItem(fileList, -1, "[ERROR] Failed to create destination: " + dest)
    LogSync("[Error] Failed to create destination: ", "", dest)
    CloseFile(srcID)
    FreeMemory(*buffer)
    ProcedureReturn #False
  EndIf
  
  While Not Eof(srcID)
    Protected bytesRead = ReadData(srcID, *buffer, bufferSize)
    If bytesRead > 0 : WriteData(dstID, *buffer, bytesRead) : EndIf
  Wend

  CloseFile(srcID)
  CloseFile(dstID)
  FreeMemory(*buffer)

  ; Preserve timestamp
  Protected ts.q = GetFileTime(source)
  If ts : SetFileDate(dest, #PB_Date_Modified, ts) : EndIf

  ProcedureReturn #True
EndProcedure

; Recursively scans a folder and its subfolders, storing file timestamps
Procedure RecursiveScan(folder.s, base.s, Map files.FileInfo())
  Protected dirID = ExamineDirectory(#PB_Any, folder, "*.*")
  If dirID
    AddMapElement(folderPaths(), base) ; Track this folder
    folderCount + 1
    While NextDirectoryEntry(dirID)
      Protected name.s = DirectoryEntryName(dirID)
      Protected fullPath.s = folder + name
      Protected relative.s = base + name

      If DirectoryEntryType(dirID) = #PB_DirectoryEntry_File
        AddMapElement(files(), relative)
        files()\time = GetFileTime(fullPath)
      ElseIf DirectoryEntryType(dirID) = #PB_DirectoryEntry_Directory
        If name <> "." And name <> ".."
          RecursiveScan(fullPath + "\", relative + "\", files())
        EndIf
      EndIf
    Wend
    FinishDirectory(dirID)
  EndIf
EndProcedure

; Ensures all folders in a path exist, creating them if needed
Procedure EnsurePathExists(path.s)
  Protected parts.s = ""
  Protected i, segment.s
  
  path = Trim(path)
  If Right(path, 1) = "\" : path = Left(path, Len(path) - 1) : EndIf

  ; Handle drive root (e.g., "C:\")
  If Mid(path, 2, 2) = ":\"
    parts = Left(path, 3)
    i = 4
  Else
    AddGadgetItem(fileList, -1, "[ERROR] Invalid path: " + path)
    LogSync("[Error] Invalid path: ", "", path)
    ProcedureReturn #False
  EndIf

  ; Build each subfolder step-by-step
  While i <= Len(path)
    segment = ""
    While i <= Len(path) And Mid(path, i, 1) <> "\"
      segment + Mid(path, i, 1)
      i + 1
    Wend
    i + 1 ; Skip backslash
    If segment <> ""
      parts + segment + "\"
      If FileSize(parts) = -1
        If CreateDirectory(parts) = 0
          AddGadgetItem(fileList, -1, "[ERROR] Failed to create folder: " + parts)
          LogSync("[Error] Failed to create folder: ", "", parts)
          errorCount + 1
          ProcedureReturn #False
        Else
          If Not FindMapElement(createdFolders(), parts)
            AddMapElement(createdFolders(), parts)
            LogSync("Folder Created", "", parts)
            AddGadgetItem(fileList, -1, "[Folder] " + parts)
          EndIf
        EndIf
      EndIf
    EndIf
  Wend

  ProcedureReturn #True
EndProcedure

; Initializes the progress window and its gadgets
Procedure InitProgressWindow()
  progressWindow = OpenWindow(#PB_Any, 0, 0, 420, 420, "HandySync - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered |
                                                                                 #PB_Window_MinimizeGadget)
  fileList = ListViewGadget(#PB_Any, 10, 10, 400, 260, #PB_ListView_MultiSelect)
  progressLabel = TextGadget(#PB_Any, 10, 280, 400, 50, "Status: Starting...")
  progressBar = ProgressBarGadget(#PB_Any, 10, 330, 400, 20, 0, 100)
  GadgetToolTip(progressBar, "Current file being processed")
  loggingCheckbox = CheckBoxGadget(#PB_Any, 10, 360, 105, 20, "Enable Logging")
  SetGadgetState(loggingCheckbox, #True)
  folderButton = ButtonGadget(#PB_Any, 120, 360, 90, 20, "Change Folders")
  GadgetToolTip(folderButton,"Change the Source and Destination folders")
  pauseButton = ButtonGadget(#PB_Any, 220, 360, 90, 20, "Sync->Pause")
  GadgetToolTip(pauseButton, "Pause or Resume the current sync")
  exitButton = ButtonGadget(#PB_Any, 320, 360, 90, 20, "Exit")
  GadgetToolTip(exitButton, "Exit the program")
  ComboBoxGadget(#BufferSizeCombo, 10, 390, 90, 20)
  AddGadgetItem(#BufferSizeCombo, -1, "64 KB")
  AddGadgetItem(#BufferSizeCombo, -1, "128 KB")
  AddGadgetItem(#BufferSizeCombo, -1, "256 KB")
  AddGadgetItem(#BufferSizeCombo, -1, "512 KB")
  AddGadgetItem(#BufferSizeCombo, -1, "1 MB")
  SetGadgetState(#BufferSizeCombo, 2) ; Default to 256 KB
  GadgetToolTip(#BufferSizeCombo, "Select Buffer Size")
EndProcedure

; Updates the progress bar and file list during sync
Procedure UpdateProgressUI(currentFile.s)
  SetGadgetText(progressLabel, "Status: Copying: " + currentFile)
  If totalFiles > 0
    SetGadgetState(progressBar, currentFileIndex * 100 / totalFiles)
  Else
    SetGadgetState(progressBar, 0)
  EndIf
  AddGadgetItem(fileList, -1, currentFile)
  While WindowEvent() : Wend ; Refresh UI
EndProcedure

; Copies a file and logs the result, with error handling
Procedure CopyFileWithProgress(source.s, dest.s, action.s)
  If FileSize(source) = -1
    AddGadgetItem(fileList, -1, "[ERROR] Source missing: " + source)
    LogSync("[Error] Source missing: ", "", source)
    errorCount + 1
    ProcedureReturn
  EndIf
  
  Protected destFolder.s = GetPathPart(dest)
  AddGadgetItem(fileList, -1, "Ensuring path exists: " + destFolder)
  If EnsurePathExists(destFolder) = #False
    LogSync("[Error] path doesn't exist: ", "", destFolder) 
    errorCount + 1
    ProcedureReturn
  EndIf
  
  currentFileIndex + 1
  UpdateProgressUI(source) 
  
  ; Perform a fast file copy (NOT working right)
  If FastCopyFile(source, dest) = #False
    AddGadgetItem(fileList, -1, "[ERROR] FastCopy failed: " + source)
    LogSync("[Error] FastCopy failed: ", "", source)
    errorCount + 1
    ProcedureReturn
  EndIf
    
; Log successful copy/update
  LogSync(action, source, dest)
  If action = "Copied"
    copiedCount + 1
  ElseIf action = "Updated"
    updatedCount + 1
  EndIf
EndProcedure

; Counts how many files need syncing between two folders
Procedure CountSyncableFiles(folderA.s, folderB.s)
  Protected count = 0
  Protected NewMap filesA.FileInfo()
  Protected NewMap filesB.FileInfo()
  RecursiveScan(folderA, "", filesA())
  RecursiveScan(folderB, "", filesB())

  ForEach filesA()
    If FindMapElement(filesB(), MapKey(filesA()))
      If filesA()\time <> filesB()\time
        count + 1
      EndIf
    Else
      count + 1
    EndIf
  Next

  ForEach filesB()
    If Not FindMapElement(filesA(), MapKey(filesB()))
      count + 1
    EndIf
  Next

  ProcedureReturn count
EndProcedure

; Performs the actual sync between folders
Procedure SyncFolders()
  Protected NewMap filesA.FileInfo()
  Protected NewMap filesB.FileInfo()
  
  copiedCount = 0
  updatedCount = 0
  errorCount  = 0
  folderCount = 0
  currentFileIndex = 0

  syncStartTime = ElapsedMilliseconds()
  
  RecursiveScan(folderA, "", filesA())
  RecursiveScan(folderB, "", filesB())
  
  ForEach folderPaths()
    Protected relFolder.s = MapKey(folderPaths())
    Protected destFolder.s = folderB + relFolder
    If Not EnsurePathExists(destFolder)
      AddGadgetItem(fileList, -1, "[ERROR] Failed to create folder: " + destFolder)
      LogSync("[Error] Failed to create folder: ", "", destFolder)
      errorCount + 1
    EndIf
  Next

; Sync from A to B
  ForEach filesA()
    Protected rel.s = MapKey(filesA())
    Protected srcA.s = folderA + rel
    Protected srcB.s = folderB + rel
    
    If FindMapElement(filesB(), rel)
      ; ✅ Compare timestamps using GetFileTime()
      If GetFileTime(srcA) > GetFileTime(srcB)
        CopyFileWithProgress(srcA, srcB, "Updated")
        updatedCount + 1
      EndIf
    Else
      ; ✅ File only exists in A, copy it to B
      CopyFileWithProgress(srcA, srcB, "Copied")
      copiedCount + 1
    EndIf
  Next
  
; Sync from B to A (for files only in B)
  ForEach filesB()
    If FindMapElement(filesA(), rel)
      ; ✅ Compare timestamps using GetFileTime()
      If GetFileTime(srcB) > GetFileTime(srcA)
        CopyFileWithProgress(srcB, srcA, "Updated")
        updatedCount + 1
      EndIf
    Else
      ; ✅ File only exists in B, copy it to A
      CopyFileWithProgress(srcB, srcA, "Copied")
      copiedCount + 1
    EndIf
  Next
  
  syncEndTime = ElapsedMilliseconds()
  syncDuration = (syncEndTime - syncStartTime) / 1000.0
  
 ; Final summary 
  SetGadgetText(progressLabel, "Status: Sync complete: " + 
    Str(copiedCount) + " copied, " + 
    Str(updatedCount) + " updated, " + 
    Str(errorCount) + " errors, " + 
    Str(folderCount) + " folders scanned. Time: " + 
    StrF(syncDuration, 2) + " seconds.")
    
  SetGadgetState(progressBar, 100)
  LogSync("Status", "Sync Completed", Str(copiedCount) + " copied, " + Str(updatedCount) +
                                      " updated, " + Str(errorCount) + " errors, " + Str(folderCount) +
                                      " folders scanned. Time: " + StrF(syncDuration, 2) + " seconds.")
changeFolder = #True
EndProcedure

; select folders
Procedure SelectFolders()
  ; 🗂 Folder selection
folderA = PathRequester("Select 'Source' Folder to Sync", "C:\")
If folderA = ""
  MessageRequester("Error", "'Source' Folder not selected, Exiting.", #PB_MessageRequester_Error)
  End
EndIf
LogSync(">>>>> SOURCE <<<<<: ", "", folderA)

folderB = PathRequester("Select 'Dest' Folder to Sync", "C:\")
If folderB = ""
  MessageRequester("Error", "'Dest' Folder not selected, Exiting.", #PB_MessageRequester_Error)
  End
EndIf
LogSync(">>>>> DESTIN <<<<<: ", "", folderB)

If Right(folderA, 1) <> "\" : folderA + "\" : EndIf
If Right(folderB, 1) <> "\" : folderB + "\" : EndIf

EndProcedure

; Main loop that monitors folders and triggers sync
Procedure MonitorFolders()
  Protected lastSync = ElapsedMilliseconds()
  LogSync("Startup", "System", "Monitoring started")
  InitProgressWindow()
  totalFiles = CountSyncableFiles(folderA, folderB)
  currentFileIndex = 0

  If totalFiles = 0
    AddGadgetItem(fileList, -1, "No files/folders to sync.")
    SetGadgetText(progressLabel, "Status: No files/folders to sync.")
  EndIf

  Repeat
    If syncPaused = #False And ElapsedMilliseconds() - lastSync > syncTime
      SyncFolders()
      lastSync = ElapsedMilliseconds()
    EndIf
    
    If syncPaused
      If ElapsedMilliseconds() - blinkTimer > 500
        blinkTimer = ElapsedMilliseconds()
        blinkState = 1 - blinkState
        If blinkState
          SetGadgetText(pauseButton, "⏸ PAUSED")
        Else
          SetGadgetText(pauseButton, "         ")
        EndIf
      EndIf
    Else
      SetGadgetText(pauseButton, "Sync->Pause")
    EndIf

    Select WaitWindowEvent(100)
      Case #PB_Event_Gadget
        Select EventGadget()
          Case pauseButton
          syncPaused = 1 - syncPaused ; Toggle
          blinkTimer = ElapsedMilliseconds()
          blinkState = 0
          If syncPaused
            SetGadgetText(pauseButton, "Sync->Resume")
            SetGadgetText(progressLabel, "Status: PAUSED.")
          Else
            SetGadgetText(pauseButton, "Sync->Pause")
            SetGadgetText(progressLabel, "Status: RESUMED.")
          EndIf
          Case folderButton
            If changeFolder = #True
              CloseWindow(progressWindow)
              SelectFolders()
              MonitorFolders()
            EndIf
          Case exitButton
            Exit()
          EndSelect

      Case #PB_Event_CloseWindow
        Exit()
    EndSelect

  ForEver

  LogSync("Shutdown", "System", "Monitoring stopped")
EndProcedure

; select the folders
SelectFolders()

; monitor the folders for changes
MonitorFolders()

; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 72
; FirstLine = 21
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DllProtection
; UseIcon = HandySync.ico
; Executable = ..\HandySync.exe
; IncludeVersionInfo
; VersionField0 = 0,0,0,0
; VersionField1 = 0,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = SyncStuff
; VersionField6 = Syncs Files and Folders
; VersionField9 = David Scouten
; VersionField13 = zonemaster@yahoo.com
; VersionField14 = www.github.com/zonemaster60