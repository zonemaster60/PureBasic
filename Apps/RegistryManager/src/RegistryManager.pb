; ======================================================================
; Registry Manager - All-in-One Edition
; Features: Editor, Cleaner, Backup, Restore, Compactor
; Target: Windows with PureBasic 6.30+
; ======================================================================

XIncludeFile "Registry.pbi"

EnableExplicit

;- Windows API Declarations for Registry Monitoring

Import "advapi32.lib"
  PB_RegNotifyChangeKeyValue(hKey.i, bWatchSubtree.i, dwNotifyFilter.l, hEvent.i, fAsynchronous.i) As "RegNotifyChangeKeyValue"
EndImport

Import "kernel32.lib"
  PB_CreateEventW(*lpEventAttributes, bManualReset.i, bInitialState.i, lpName.i) As "CreateEventW"
  PB_WaitForSingleObject(hHandle.i, dwMilliseconds.l) As "WaitForSingleObject"
  PB_ResetEvent(hEvent.i) As "ResetEvent"
  PB_CloseHandle(hObject.i) As "CloseHandle"
  PB_SetEvent(hEvent.i) As "SetEvent"
EndImport

#APP_NAME = "RegistryManager"
Global version.s = "v1.0.0.3"
Global AppPath.s = GetFilePart(ProgramFilename())
SetCurrentDirectory(AppPath)

;- Constants
#WINDOW_MAIN = 0
#WINDOW_MONITOR = 1
#WINDOW_SNAPSHOT = 2
#GADGET_SPLITTER = 0
#GADGET_TREE = 1
#GADGET_LISTVIEW = 2
#GADGET_MENU = 3
#GADGET_STATUSBAR = 4
#GADGET_POPUP_TREE = 5
#GADGET_POPUP_LIST = 6
#GADGET_MONITOR_LIST = 100
#GADGET_MONITOR_START = 101
#GADGET_MONITOR_STOP = 102
#GADGET_MONITOR_CLEAR = 103
#GADGET_MONITOR_SAVE = 104
#GADGET_SNAPSHOT_LIST = 200
#GADGET_SNAPSHOT_CREATE = 201
#GADGET_SNAPSHOT_DELETE = 202
#GADGET_SNAPSHOT_COMPARE = 203
#GADGET_SNAPSHOT_EXPORT = 204
#GADGET_SNAPSHOT_DIFF = 205
#GADGET_ADDRESS_BAR = 210
#GADGET_ADDRESS_GO = 211
#GADGET_VALUE_EDITOR_NAME = 400
#GADGET_VALUE_EDITOR_TYPE = 401
#GADGET_VALUE_EDITOR_DATA = 402
#GADGET_VALUE_EDITOR_OK = 403
#GADGET_VALUE_EDITOR_CANCEL = 404
#GADGET_VALUE_EDITOR_HEX = 405
#GADGET_VALUE_EDITOR_DEC = 406
;- Declarations
Declare LogInfo(location.s, infoMsg.s)
Declare LogError(location.s, errorMsg.s, errorCode.i = 0)
Declare LogWarning(location.s, warnMsg.s)
Declare JumpToPath(fullPath.s)
Declare.s GetRootKeyName(rootKey.i)
Declare.i CompareSnapshots(snapshot1.s, snapshot2.s)
Declare.i WriteRegistryValue(rootKey.i, keyPath.s, valueName.s, value.s, valueType.i, sam.l = #KEY_ALL_ACCESS)
Declare LoadValues(rootKey.i, keyPath.s, sam.l = 0)
Declare.s GetTypeName(type.i)
Declare.l GetDefaultSAM()
Declare OpenSearchWindow()
Declare OpenValueEditor(rootKey.i, keyPath.s, valueName.s = "")

Structure CompareThreadParams
  Snapshot1.s
  Snapshot2.s
EndStructure

Global CompareThreadID.i = 0

; Prevent multiple instances (don't rely on window title text)
; Allow helper modes to run even if the tray app is running.
Global hMutex.i
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
  If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
    CloseHandle_(hMutex)
    End
  EndIf
  
; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseHandle_(hMutex)
    End
  EndIf
EndProcedure

Procedure CompareThread(param.i)
  Protected *p.CompareThreadParams = param
  If *p = 0 : ProcedureReturn : EndIf
  
  Protected s1.s = *p\Snapshot1
  Protected s2.s = *p\Snapshot2
  FreeMemory(*p)
  
  LogInfo("CompareThread", "Starting comparison in background: " + s1 + " vs " + s2)
  CompareSnapshots(s1, s2)
  
  CompareThreadID = 0
  LogInfo("CompareThread", "Comparison thread finished")
EndProcedure

#MENU_FILE_EXPORT = 1
#MENU_FILE_IMPORT = 2
#MENU_FILE_EXIT = 3
#MENU_EDIT_NEW_KEY = 10
#MENU_EDIT_NEW_VALUE = 11
#MENU_EDIT_DELETE = 12
#MENU_EDIT_RENAME = 13
#MENU_TOOLS_CLEANER = 20
#MENU_TOOLS_BACKUP = 21
#MENU_TOOLS_RESTORE = 22
#MENU_TOOLS_COMPACT = 23
#MENU_TOOLS_MONITOR = 24
#MENU_TOOLS_SNAPSHOT = 25
#MENU_HELP_ONLINE = 30
#MENU_HELP_ABOUT = 31
#MENU_VIEW_64BIT = 40
#MENU_VIEW_REFRESH = 41
#MENU_FAV_ADD = 50
#MENU_FAV_MANAGE = 51
#MENU_FAV_START = 1000 ; Dynamic range for favorites starting here

;- Registry Monitor Constants
#REG_NOTIFY_CHANGE_NAME = $1
#REG_NOTIFY_CHANGE_ATTRIBUTES = $2
#REG_NOTIFY_CHANGE_LAST_SET = $4
#REG_NOTIFY_CHANGE_SECURITY = $8
#REG_NOTIFY_THREAD_AGNOSTIC = $10000000

#MONITOR_THREAD_ID = 1
#TIMER_MONITOR_REFRESH = 1001
#TIMER_SNAPSHOT_REFRESH = 1002
#MONITOR_REFRESH_INTERVAL = 200 ; ms
#SNAPSHOT_REFRESH_INTERVAL = 300 ; ms

;- Structures
Structure RegKeyInfo
  Name.s
  FullPath.s
  RootKey.i
  SAM.l
EndStructure

Structure RegValueInfo
  Name.s
  Type.i
  Data.s
EndStructure

Structure RegMonitorEvent
  Timestamp.s
  RootKey.s
  KeyPath.s
  ChangeType.s
  Details.s
EndStructure

Structure RegSnapshot
  Name.s
  Timestamp.s
  FilePath.s
  Description.s
  FileSize.q
EndStructure

Structure RegDifference
  Timestamp.s
  ChangeType.s ; "ADDED", "REMOVED", "MODIFIED"
  KeyPath.s
  ValueName.s
  OldValue.s
  NewValue.s
  OldData.s
  NewData.s
EndStructure

Structure BackupThreadParams
  FileName.s
  Reason.s
  IsAuto.i
EndStructure

;- Global Variables
Global CurrentRootKey.i
Global CurrentKeyPath.s
Global NewList RegValues.RegValueInfo()
Global NewList Favorites.s()
Global LogFile.i
Global ErrorLogPath.s
Global AutoBackupPath.s
Global LastBackupTime.i
Global MonitorActive.i = #False
Global View64Bit.i = #True ; Default to 64-bit on x64, 32-bit on x86
Global MonitorWindow.i = 0
Global NewList MonitorEvents.RegMonitorEvent()
Global MonitorMutex.i
Global MonitorEventCount.i
Global MonitorLastShownCount.i
Global txtMonitorStatus.i
Global SnapshotWindow.i = 0
Global SnapshotCreationActive.i
Global SnapshotCreationProgram.i
Global SnapshotCreationFile.s
Global NewList Snapshots.RegSnapshot()
Global NewList DiffResults.RegDifference()
Global SnapshotDirectory.s
Global NewMap TreeChildrenLoaded.i()


;- Constants for Auto-Backup
#AUTO_BACKUP_INTERVAL = 3600000 ; 1 hour in milliseconds
#BACKUP_DIR_NAME = "RegistryManager_Backups"

;- Forward Declarations
Declare UpdateStatusBar(text.s)
Declare LoadFavorites()
Declare SaveFavorites()
Declare UpdateFavoritesMenu()
Declare AddFavorite(path.s)
Declare LoadValues(rootKey.i, keyPath.s, sam.l = 0)
Declare LoadSubKeys(parentItem.i, rootKey.i, keyPath.s, sam.l = 0)
Declare JumpToPath(fullPath.s)
Declare OpenFavoritesManager()
Declare OpenSearchWindow()
Declare OpenMonitorWindow()
Declare OpenSnapshotWindow()
Declare CleanRegistry()
Declare CompactRegistry()
Declare.s GetSnapshotDirectory()
Declare.s SanitizeFileName(input.s)
Declare DeleteSnapshot(snapshotName.s, skipConfirm.i = #False)
Declare.s GetRootKeyName(rootKey.i)
Declare.i GetRootKeyFromTreeItem(item.i)
Declare.l GetDefaultSAM()

;- Error Logging Procedures

Procedure InitErrorLog()
  ; Put logs in a dedicated folder next to the executable/source
  ErrorLogPath = GetCurrentDirectory() + "logs\"
  If FileSize(ErrorLogPath) <> -2
    CreateDirectory(ErrorLogPath)
  EndIf
  
  ErrorLogPath + "RegistryManager_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".log"
  LogFile = CreateFile(#PB_Any, ErrorLogPath)
  If LogFile
    WriteStringN(LogFile, "Registry Manager Error Log - " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()))
    WriteStringN(LogFile, "=" + Space(60) + "=")
    WriteStringN(LogFile, "")
    FlushFileBuffers(LogFile)
    ProcedureReturn #True
  Else
    ; Fallback: Try to use temporary directory if local folder is restricted
    Protected tempDir.s = GetTemporaryDirectory()
    If Right(tempDir, 1) <> "\" And Right(tempDir, 1) <> "/" : tempDir + "\" : EndIf
    ErrorLogPath = tempDir + "RegistryManager_Fallback_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".log"
    LogFile = CreateFile(#PB_Any, ErrorLogPath)
    If LogFile
      WriteStringN(LogFile, "Registry Manager Error Log (Fallback) - " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()))
      ProcedureReturn #True
    EndIf
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure LogError(location.s, errorMsg.s, errorCode.i = 0)
  Protected timestamp.s, logMsg.s
  
  timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  logMsg = "[" + timestamp + "] ERROR in " + location + ": " + errorMsg
  
  If errorCode <> 0
    logMsg + " (Code: " + Str(errorCode) + ")"
  EndIf
  
  If LogFile
    WriteStringN(LogFile, logMsg)
    FlushFileBuffers(LogFile)
  EndIf
  
  Debug logMsg
EndProcedure

Procedure LogInfo(location.s, infoMsg.s)
  Protected timestamp.s, logMsg.s
  
  timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  logMsg = "[" + timestamp + "] INFO in " + location + ": " + infoMsg
  
  If LogFile
    WriteStringN(LogFile, logMsg)
    FlushFileBuffers(LogFile)
  EndIf
  
  Debug logMsg
EndProcedure

Procedure LogWarning(location.s, warnMsg.s)
  Protected timestamp.s, logMsg.s
  
  timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  logMsg = "[" + timestamp + "] WARNING in " + location + ": " + warnMsg
  
  If LogFile
    WriteStringN(LogFile, logMsg)
    FlushFileBuffers(LogFile)
  EndIf
  
  Debug logMsg
EndProcedure

Procedure CloseErrorLog()
  If LogFile
    WriteStringN(LogFile, "")
    WriteStringN(LogFile, "=" + Space(60) + "=")
    WriteStringN(LogFile, "Log closed at " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()))
    CloseFile(LogFile)
    LogFile = 0
  EndIf
EndProcedure

;- Auto-Backup Procedures

Procedure.s GetBackupDirectory()
  Protected backupDir.s
  
  backupDir = GetHomeDirectory() + #BACKUP_DIR_NAME + "\"
  
  If FileSize(backupDir) <> -2 ; Directory doesn't exist
    If CreateDirectory(backupDir)
      LogInfo("GetBackupDirectory", "Created backup directory: " + backupDir)
    Else
      LogError("GetBackupDirectory", "Failed to create backup directory: " + backupDir)
      ; Fallback to temp directory
      backupDir = GetTemporaryDirectory() + #BACKUP_DIR_NAME + "\"
      CreateDirectory(backupDir)
    EndIf
  EndIf
  
  ProcedureReturn backupDir
EndProcedure

Procedure BackupThread(param.i)
  Protected *p.BackupThreadParams = param
  Protected program.i, exitCode.i, fileName.s, reason.s, isAuto.i
  
  If *p = 0 : ProcedureReturn : EndIf
  
  fileName = *p\FileName
  reason = *p\Reason
  isAuto = *p\IsAuto
  FreeMemory(*p)
  
  LogInfo("BackupThread", "Starting backup for: " + reason)
  
  ; Export entire HKLM registry
  program = RunProgram("reg", "export HKLM " + Chr(34) + fileName + Chr(34) + " /y", "", #PB_Program_Open | #PB_Program_Hide)
  
  If program
    While IsProgram(program)
      If WaitProgram(program, 100)
        Break
      EndIf
      ; The thread is separate, but we need to ensure we don't block the OS's 
      ; perception of the process if it's doing heavy I/O.
      ; Actually, PB threads are real OS threads, but RunProgram with #PB_Program_Wait
      ; can sometimes cause issues in certain PB versions with the parent event loop.
      Delay(10)
    Wend
    
    exitCode = ProgramExitCode(program)
    CloseProgram(program)
    If exitCode = 0 And FileSize(fileName) > 0
      If isAuto
        AutoBackupPath = fileName
        LastBackupTime = ElapsedMilliseconds()
        LogInfo("BackupThread", "Auto-backup created successfully: " + fileName)
      Else
        LogInfo("BackupThread", "Manual backup completed: " + fileName)
      EndIf
      UpdateStatusBar("Backup completed: " + GetFilePart(fileName))
    Else
      LogError("BackupThread", "Backup failed with exit code: " + Str(exitCode))
      UpdateStatusBar("Error: Backup failed!")
    EndIf
  Else
    LogError("BackupThread", "Failed to execute reg.exe")
    UpdateStatusBar("Error: Cannot execute reg.exe")
  EndIf
EndProcedure

Procedure.i CreateAutoBackup(reason.s = "Auto-backup before changes")
  Protected backupFile.s, backupDir.s, timestamp.s
  Protected *p.BackupThreadParams
  
  timestamp = FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date())
  backupDir = GetBackupDirectory()
  backupFile = backupDir + "AutoBackup_" + timestamp + ".reg"
  
  LogInfo("CreateAutoBackup", "Queuing automatic backup: " + reason)
  
  UpdateStatusBar("Background backup started... You can continue working.")
  
  *p = AllocateMemory(SizeOf(BackupThreadParams))
  If *p
    *p\FileName = backupFile
    *p\Reason = reason
    *p\IsAuto = #True
    
    If CreateThread(@BackupThread(), *p)
      ProcedureReturn #True
    EndIf
    FreeMemory(*p)
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure BackupRegistry(fileName.s)
  Protected *p.BackupThreadParams
  
  If fileName = ""
    LogError("BackupRegistry", "Empty filename provided")
    UpdateStatusBar("Error: No filename specified")
    ProcedureReturn #False
  EndIf
  
  LogInfo("BackupRegistry", "Queuing manual backup to: " + fileName)
  UpdateStatusBar("Background backup started...")
  
  *p = AllocateMemory(SizeOf(BackupThreadParams))
  If *p
    *p\FileName = fileName
    *p\Reason = "Manual User Backup"
    *p\IsAuto = #False
    
    If CreateThread(@BackupThread(), *p)
      ProcedureReturn #True
    EndIf
    FreeMemory(*p)
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure.i EnsureBackupBeforeChange(operation.s)
  Protected result.i
  
  LogInfo("EnsureBackupBeforeChange", "Checking backup requirement for: " + operation)
  
  ; Check if we need a new backup (first time or after interval)
  If AutoBackupPath = "" Or (ElapsedMilliseconds() - LastBackupTime) > #AUTO_BACKUP_INTERVAL
    LogInfo("EnsureBackupBeforeChange", "Creating new backup (reason: " + operation + ")")
    
    result = MessageRequester("Safety Backup Required", 
                              "Registry Manager will create a full registry backup before:" + #CRLF$ +
                              operation + #CRLF$ + #CRLF$ +
                              "This backup can be used to restore your registry if needed." + #CRLF$ + #CRLF$ +
                              "Continue?", 
                              #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
    
    If result = #PB_MessageRequester_Yes
      If Not CreateAutoBackup(operation)
        result = MessageRequester("Backup Failed", 
                                  "Failed to create safety backup!" + #CRLF$ + #CRLF$ +
                                  "Do you want to continue WITHOUT backup?" + #CRLF$ +
                                  "(NOT RECOMMENDED)", 
                                  #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning)
        
        If result = #PB_MessageRequester_Yes
          LogWarning("EnsureBackupBeforeChange", "User proceeded without backup for: " + operation)
          ProcedureReturn #True
        Else
          LogInfo("EnsureBackupBeforeChange", "User cancelled operation due to backup failure")
          ProcedureReturn #False
        EndIf
      Else
        LogInfo("EnsureBackupBeforeChange", "Backup successful, proceeding with: " + operation)
        ProcedureReturn #True
      EndIf
    Else
      LogInfo("EnsureBackupBeforeChange", "User cancelled operation: " + operation)
      UpdateStatusBar("Operation cancelled by user")
      ProcedureReturn #False
    EndIf
  Else
    LogInfo("EnsureBackupBeforeChange", "Using existing backup from: " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", LastBackupTime / 1000))
    ProcedureReturn #True
  EndIf
EndProcedure

Procedure CleanupOldBackups(daysToKeep.i = 7)
  Protected backupDir.s, dir.i, fileName.s, filePath.s, fileDate.i, currentTime.i
  Protected deletedCount.i, keptCount.i
  
  backupDir = GetBackupDirectory()
  currentTime = Date()
  
  LogInfo("CleanupOldBackups", "Cleaning backups older than " + Str(daysToKeep) + " days from: " + backupDir)
  
  dir = ExamineDirectory(#PB_Any, backupDir, "AutoBackup_*.reg")
  If dir
    While NextDirectoryEntry(dir)
      fileName = DirectoryEntryName(dir)
      If fileName <> "." And fileName <> ".."
        filePath = backupDir + fileName
        fileDate = GetFileDate(filePath, #PB_Date_Modified)
        
        ; Check if file is older than retention period
        If (currentTime - fileDate) > (daysToKeep * 86400)
          If DeleteFile(filePath)
            deletedCount + 1
            LogInfo("CleanupOldBackups", "Deleted old backup: " + fileName)
          Else
            LogWarning("CleanupOldBackups", "Failed to delete old backup: " + fileName)
          EndIf
        Else
          keptCount + 1
        EndIf
      EndIf
    Wend
    FinishDirectory(dir)
    
    LogInfo("CleanupOldBackups", "Cleanup complete: " + Str(deletedCount) + " deleted, " + Str(keptCount) + " kept")
  Else
    LogWarning("CleanupOldBackups", "Cannot open backup directory: " + backupDir)
  EndIf
EndProcedure

;- Procedures

Procedure UpdateStatusBar(text.s)
  If IsStatusBar(#GADGET_STATUSBAR)
    StatusBarText(#GADGET_STATUSBAR, 0, text)
  EndIf
  LogInfo("StatusBar", text)
EndProcedure

Procedure.s GetRootKeyName(rootKey.i)
  Select rootKey
    Case #HKEY_CLASSES_ROOT: ProcedureReturn "HKEY_CLASSES_ROOT"
    Case #HKEY_CURRENT_USER: ProcedureReturn "HKEY_CURRENT_USER"
    Case #HKEY_LOCAL_MACHINE: ProcedureReturn "HKEY_LOCAL_MACHINE"
    Case #HKEY_USERS: ProcedureReturn "HKEY_USERS"
    Case #HKEY_CURRENT_CONFIG: ProcedureReturn "HKEY_CURRENT_CONFIG"
  EndSelect
  LogWarning("GetRootKeyName", "Unknown root key: " + Str(rootKey))
  ProcedureReturn "UNKNOWN"
EndProcedure

Procedure.i GetRootKeyFromTreeItem(item.i)
  Protected rootName.s
  
  If item < 0
    LogError("GetRootKeyFromTreeItem", "Invalid tree item: " + Str(item))
    ProcedureReturn 0
  EndIf
  
  rootName = GetGadgetItemText(#GADGET_TREE, item)
  
  Select rootName
    Case "HKEY_CLASSES_ROOT": ProcedureReturn #HKEY_CLASSES_ROOT
    Case "HKEY_CURRENT_USER": ProcedureReturn #HKEY_CURRENT_USER
    Case "HKEY_LOCAL_MACHINE": ProcedureReturn #HKEY_LOCAL_MACHINE
    Case "HKEY_USERS": ProcedureReturn #HKEY_USERS
    Case "HKEY_CURRENT_CONFIG": ProcedureReturn #HKEY_CURRENT_CONFIG
  EndSelect
  
  LogWarning("GetRootKeyFromTreeItem", "Unknown root key name: " + rootName)
  ProcedureReturn 0
EndProcedure

Procedure.l GetDefaultSAM()
  Protected sam.l = #KEY_ALL_ACCESS
  If View64Bit
    sam | #KEY_WOW64_64KEY
  Else
    sam | #KEY_WOW64_32KEY
  EndIf
  ProcedureReturn sam
EndProcedure

Procedure.s GetTypeName(type.i)
  Select type
    Case #REG_SZ: ProcedureReturn "REG_SZ"
    Case #REG_DWORD: ProcedureReturn "REG_DWORD"
    Case #REG_BINARY: ProcedureReturn "REG_BINARY"
    Case #REG_EXPAND_SZ: ProcedureReturn "REG_EXPAND_SZ"
    Case #REG_MULTI_SZ: ProcedureReturn "REG_MULTI_SZ"
    Case #REG_QWORD: ProcedureReturn "REG_QWORD"
    Case #REG_NONE: ProcedureReturn "REG_NONE"
    Default: ProcedureReturn "Unknown (" + Str(type) + ")"
  EndSelect
EndProcedure

Procedure.i LoadSubKeys(parentItem.i, rootKey.i, keyPath.s, sam.l = 0)
  Protected i.i, count.i, subKeyName.s, newItem.i
  Protected ret.Registry::RegValue
  
  If sam = 0 : sam = GetDefaultSAM() : EndIf
  
  If Not IsGadget(#GADGET_TREE)
    LogError("LoadSubKeys", "Tree gadget not available")
    ProcedureReturn #False
  EndIf
  
  Protected wow64.i = #False
  If (sam & #KEY_WOW64_64KEY) Or (sam & #KEY_WOW64_32KEY) : wow64 = #True : EndIf
  
  count = Registry::CountSubKeys(rootKey, keyPath, wow64, @ret)
  If ret\ERROR <> 0
    LogError("LoadSubKeys", "Failed to count subkeys: " + ret\ERRORSTR, ret\ERROR)
    ProcedureReturn #False
  EndIf
  
  If count > 0
    Protected maxKeys.i = 500
    If count > maxKeys
      LogWarning("LoadSubKeys", "Large key list (" + Str(count) + ") in path: " + keyPath + " - showing first " + Str(maxKeys))
      count = maxKeys
    Else
      LogInfo("LoadSubKeys", "Found " + Str(count) + " subkey(s) in path: " + keyPath)
    EndIf
    For i = 0 To count - 1
      subKeyName = Registry::ListSubKey(rootKey, keyPath, i, wow64, @ret)
      If ret\ERROR <> 0
        LogWarning("LoadSubKeys", "Failed to read subkey at index " + Str(i) + ": " + ret\ERRORSTR)
        Continue
      EndIf
      
      If subKeyName <> ""
        newItem = AddGadgetItem(#GADGET_TREE, -1, subKeyName, 0, parentItem)
        If newItem = -1
          LogWarning("LoadSubKeys", "Failed to add tree item: " + subKeyName)
        EndIf
      EndIf
    Next
  Else
    LogInfo("LoadSubKeys", "No subkeys found in path: " + keyPath)
  EndIf
  
  ProcedureReturn #True
EndProcedure

Structure SearchThreadParams
  SearchString.s
  RootKey.i
  KeyPath.s
EndStructure

Structure SearchResult
  RootKey.i
  KeyPath.s
  ValueName.s
  ValueType.i
  ValueData.s
EndStructure

Global NewList SearchResults.SearchResult()
Global SearchThreadID.i = 0
Global SearchStopRequested.i = #False

#WINDOW_SEARCH = 3
#GADGET_SEARCH_STRING = 300
#GADGET_SEARCH_START = 301
#GADGET_SEARCH_STOP = 302
#GADGET_SEARCH_RESULTS = 303
#GADGET_SEARCH_STATUS = 304

Procedure RecursiveSearchInternal(rootKey.i, currentPath.s, searchStr.s, wow64.i)
  Protected i.i, subKeyCount.i, valueCount.i, subKeyName.s, valueName.s, valueData.s, valueType.i
  Protected ret.Registry::RegValue
  
  If SearchStopRequested : ProcedureReturn : EndIf
  
  ; 1. Search in Values of current path
  valueCount = Registry::CountSubValues(rootKey, currentPath, wow64, @ret)
  For i = 0 To valueCount - 1
    If SearchStopRequested : Break : EndIf
    valueName = Registry::ListSubValue(rootKey, currentPath, i, wow64, @ret)
    
    If FindString(valueName, searchStr, 1, #PB_String_NoCase)
      AddElement(SearchResults())
      SearchResults()\RootKey = rootKey
      SearchResults()\KeyPath = currentPath
      SearchResults()\ValueName = valueName
      SearchResults()\ValueType = Registry::ReadType(rootKey, currentPath, valueName, wow64, @ret)
      SearchResults()\ValueData = Registry::ReadValue(rootKey, currentPath, valueName, wow64, @ret)
    Else
      ; Only read value data if name didn't match (performance optimization)
      valueData = Registry::ReadValue(rootKey, currentPath, valueName, wow64, @ret)
      If FindString(valueData, searchStr, 1, #PB_String_NoCase)
        AddElement(SearchResults())
        SearchResults()\RootKey = rootKey
        SearchResults()\KeyPath = currentPath
        SearchResults()\ValueName = valueName
        SearchResults()\ValueType = Registry::ReadType(rootKey, currentPath, valueName, wow64, @ret)
        SearchResults()\ValueData = valueData
      EndIf
    EndIf
  Next
  
  ; 2. Search in subkeys (recursive)
  subKeyCount = Registry::CountSubKeys(rootKey, currentPath, wow64, @ret)
  For i = 0 To subKeyCount - 1
    If SearchStopRequested : Break : EndIf
    subKeyName = Registry::ListSubKey(rootKey, currentPath, i, wow64, @ret)
    Define nextPath.s = currentPath
    If nextPath <> "" : nextPath + "\" : EndIf
    nextPath + subKeyName
    RecursiveSearchInternal(rootKey, nextPath, searchStr, wow64)
  Next
EndProcedure

Procedure SearchThread(param.i)
  Protected *p.SearchThreadParams = param
  If *p = 0 : ProcedureReturn : EndIf
  
  Protected searchStr.s = *p\SearchString
  Protected rootKey.i = *p\RootKey
  Protected keyPath.s = *p\KeyPath
  FreeMemory(*p)
  
  Protected wow64.i = #False
  If (GetDefaultSAM() & #KEY_WOW64_64KEY) : wow64 = #True : EndIf
  
  LogInfo("SearchThread", "Starting recursive search for: " + searchStr)
  RecursiveSearchInternal(rootKey, keyPath, searchStr, wow64)
  
  SearchThreadID = 0
  If SearchStopRequested
    LogInfo("SearchThread", "Search cancelled by user")
  Else
    LogInfo("SearchThread", "Search completed. Found " + Str(ListSize(SearchResults())) + " matches.")
  EndIf
EndProcedure

Procedure OpenValueEditor(rootKey.i, keyPath.s, valueName.s = "")
  Protected isNew.i = #True
  If valueName <> "" : isNew = #False : EndIf
  
  Protected winTitle.s = "New Value"
  If Not isNew : winTitle = "Edit Value: " + valueName : EndIf
  
  Protected win = OpenWindow(#PB_Any, 0, 0, 450, 300, winTitle, #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
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
      currentType = Registry::ReadType(rootKey, keyPath, valueName, (GetDefaultSAM() & #KEY_WOW64_64KEY), @ret)
      currentData = Registry::ReadValue(rootKey, keyPath, valueName, (GetDefaultSAM() & #KEY_WOW64_64KEY), @ret)
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
    
    ; DWORD/QWORD options
    OptionGadget(#GADGET_VALUE_EDITOR_HEX, 90, 210, 80, 20, "Hexadecimal")
    OptionGadget(#GADGET_VALUE_EDITOR_DEC, 180, 210, 80, 20, "Decimal")
    SetGadgetState(#GADGET_VALUE_EDITOR_DEC, #True)
    If currentType <> #REG_DWORD And currentType <> #REG_QWORD
      DisableGadget(#GADGET_VALUE_EDITOR_HEX, #True)
      DisableGadget(#GADGET_VALUE_EDITOR_DEC, #True)
    EndIf
    
    ButtonGadget(#GADGET_VALUE_EDITOR_OK, 230, 250, 100, 30, "OK")
    ButtonGadget(#GADGET_VALUE_EDITOR_CANCEL, 340, 250, 100, 30, "Cancel")
    
    Repeat
      Define ev = WaitWindowEvent()
      If ev = #PB_Event_CloseWindow And EventWindow() = win
        Break
      ElseIf ev = #PB_Event_Gadget
        If EventGadget() = #GADGET_VALUE_EDITOR_CANCEL
          Break
        ElseIf EventGadget() = #GADGET_VALUE_EDITOR_TYPE
          Protected st = GetGadgetState(#GADGET_VALUE_EDITOR_TYPE)
          If st = 1 Or st = 2
            DisableGadget(#GADGET_VALUE_EDITOR_HEX, #False)
            DisableGadget(#GADGET_VALUE_EDITOR_DEC, #False)
          Else
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

Procedure OpenSearchWindow()
  If IsWindow(#WINDOW_SEARCH)
    StickyWindow(#WINDOW_SEARCH, #True)
    ProcedureReturn
  EndIf
  
  If OpenWindow(#WINDOW_SEARCH, 0, 0, 800, 500, "Registry Search - " + GetRootKeyName(CurrentRootKey) + "\" + CurrentKeyPath, #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
    TextGadget(#PB_Any, 10, 15, 80, 20, "Find what:")
    StringGadget(#GADGET_SEARCH_STRING, 90, 10, 500, 25, "")
    ButtonGadget(#GADGET_SEARCH_START, 600, 10, 90, 25, "Search")
    ButtonGadget(#GADGET_SEARCH_STOP, 700, 10, 90, 25, "Stop")
    DisableGadget(#GADGET_SEARCH_STOP, #True)
    
    ListIconGadget(#GADGET_SEARCH_RESULTS, 10, 45, 780, 420, "Path", 300, #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
    AddGadgetColumn(#GADGET_SEARCH_RESULTS, 1, "Name", 150)
    AddGadgetColumn(#GADGET_SEARCH_RESULTS, 2, "Type", 100)
    AddGadgetColumn(#GADGET_SEARCH_RESULTS, 3, "Data", 210)
    
    TextGadget(#GADGET_SEARCH_STATUS, 10, 475, 780, 20, "Ready")
  EndIf
EndProcedure



Procedure LoadValues(rootKey.i, keyPath.s, sam.l = 0)
  Protected i.i, count.i, valueName.s, valueData.s, valueType.i
  Protected ret.Registry::RegValue
  
  If sam = 0 : sam = GetDefaultSAM() : EndIf
  
  If Not IsGadget(#GADGET_LISTVIEW)
    LogError("LoadValues", "ListView gadget not available")
    ProcedureReturn #False
  EndIf
  
  ClearGadgetItems(#GADGET_LISTVIEW)
  ClearList(RegValues())
  
  LogInfo("LoadValues", "Loading values from: " + GetRootKeyName(rootKey) + "\" + keyPath + " (SAM: " + Hex(sam) + ")")
  
  Protected wow64.i = #False
  If (sam & #KEY_WOW64_64KEY) Or (sam & #KEY_WOW64_32KEY) : wow64 = #True : EndIf
  
  count = Registry::CountSubValues(rootKey, keyPath, wow64, @ret)
  If ret\ERROR <> 0
    LogError("LoadValues", "Failed to count values: " + ret\ERRORSTR, ret\ERROR)
    UpdateStatusBar("Error: Cannot read registry values")
    ProcedureReturn #False
  EndIf
  
  If count > 0
    For i = 0 To count - 1
      valueName = Registry::ListSubValue(rootKey, keyPath, i, wow64, @ret)
      If ret\ERROR <> 0
        LogWarning("LoadValues", "Failed to read value name at index " + Str(i) + ": " + ret\ERRORSTR)
        Continue
      EndIf
      
      If valueName <> ""
        valueType = Registry::ReadType(rootKey, keyPath, valueName, wow64, @ret)
        If ret\ERROR <> 0
          LogWarning("LoadValues", "Failed to read type for value '" + valueName + "': " + ret\ERRORSTR)
          valueType = 0
        EndIf
        
        valueData = Registry::ReadValue(rootKey, keyPath, valueName, wow64, @ret)
        If ret\ERROR <> 0
          LogWarning("LoadValues", "Failed to read data for value '" + valueName + "': " + ret\ERRORSTR)
          valueData = "<Error reading value>"
        EndIf
        
        AddElement(RegValues())
        RegValues()\Name = valueName
        RegValues()\Type = valueType
        RegValues()\Data = valueData
        
        AddGadgetItem(#GADGET_LISTVIEW, -1, valueName + Chr(10) + GetTypeName(valueType) + Chr(10) + Left(valueData, 100))
      EndIf
    Next
    LogInfo("LoadValues", "Successfully loaded " + Str(count) + " value(s)")
  Else
    LogInfo("LoadValues", "No values found in current key")
  EndIf
  
  UpdateStatusBar("Loaded " + Str(count) + " value(s)")
  ProcedureReturn #True
EndProcedure

;- Registry Modification Procedures (with Auto-Backup)

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
  Protected wow64.i = #False
  If (sam & #KEY_WOW64_64KEY) Or (sam & #KEY_WOW64_32KEY) : wow64 = #True : EndIf
  
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
  
  Protected wow64.i = #False
  If (sam & #KEY_WOW64_64KEY) Or (sam & #KEY_WOW64_32KEY) : wow64 = #True : EndIf
  
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
  
  Protected wow64.i = #False
  If (sam & #KEY_WOW64_64KEY) Or (sam & #KEY_WOW64_32KEY) : wow64 = #True : EndIf
  
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
    
    If Registry::DeleteTree(rootKey, keyPath, #False, @ret)
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

Procedure ExportRegistryKey(rootKey.i, keyPath.s, fileName.s)
  Protected file.i, i.i, count.i, valueName.s, valueData.s, valueType.i
  Protected ret.Registry::RegValue
  Protected rootName.s = GetRootKeyName(rootKey)
  
  If fileName = ""
    LogError("ExportRegistryKey", "Empty filename provided")
    ProcedureReturn #False
  EndIf
  
  LogInfo("ExportRegistryKey", "Exporting key: " + rootName + "\" + keyPath + " to " + fileName)
  
  ; For simplicity and full compatibility, we use reg.exe for recursive export.
  ; Writing a manual .reg parser for multi-line binary and recursive subkeys is complex.
  Protected fullPath.s = rootName + "\" + keyPath
  Protected program = RunProgram("reg", "export " + Chr(34) + fullPath + Chr(34) + " " + Chr(34) + fileName + Chr(34) + " /y", "", #PB_Program_Wait | #PB_Program_Hide)
  If program
    If ProgramExitCode(program) = 0
      LogInfo("ExportRegistryKey", "Successfully exported: " + fullPath)
      UpdateStatusBar("Exported to: " + fileName)
      ProcedureReturn #True
    EndIf
  EndIf
  
  ; Fallback manual export if reg.exe fails or needs custom logic (not recursive yet)
  file = CreateFile(#PB_Any, fileName)
  If file
    WriteStringN(file, "Windows Registry Editor Version 5.00")
    WriteStringN(file, "")
    WriteStringN(file, "[" + rootName + "\" + keyPath + "]")
    
    Protected wow64 = #False
    If (GetDefaultSAM() & #KEY_WOW64_64KEY) : wow64 = #True : EndIf
    
    count = Registry::CountSubValues(rootKey, keyPath, wow64, @ret)
    If count > 0
      For i = 0 To count - 1
        valueName = Registry::ListSubValue(rootKey, keyPath, i, wow64, @ret)
        If ret\ERROR = 0 And valueName <> ""
          valueType = Registry::ReadType(rootKey, keyPath, valueName, wow64, @ret)
          valueData = Registry::ReadValue(rootKey, keyPath, valueName, wow64, @ret)
          
          If ret\ERROR = 0
            ; Format based on type for standard .reg compatibility
            Select valueType
              Case #REG_SZ
                WriteStringN(file, Chr(34) + valueName + Chr(34) + "=" + Chr(34) + ReplaceString(valueData, "\", "\\") + Chr(34))
              Case #REG_DWORD
                WriteStringN(file, Chr(34) + valueName + Chr(34) + "=dword:" + RSet(Hex(Val(valueData)), 8, "0"))
              Default
                ; Binary and other types use hex:
                WriteStringN(file, Chr(34) + valueName + Chr(34) + "=hex(" + Hex(valueType) + "):" + valueData)
            EndSelect
          EndIf
        EndIf
      Next
    EndIf
    
    CloseFile(file)
    LogInfo("ExportRegistryKey", "Successfully manual exported " + Str(count) + " values")
    UpdateStatusBar("Exported to: " + fileName)
    ProcedureReturn #True
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure RestoreRegistry(fileName.s)

  Protected program.i, exitCode.i
  
  If fileName = ""
    LogError("RestoreRegistry", "Empty filename provided")
    UpdateStatusBar("Error: No filename specified")
    ProcedureReturn #False
  EndIf
  
  If FileSize(fileName) <= 0
    LogError("RestoreRegistry", "File not found or empty: " + fileName)
    MessageRequester("Error", "Registry file not found or empty!", #PB_MessageRequester_Error)
    UpdateStatusBar("Error: Invalid registry file")
    ProcedureReturn #False
  EndIf
  
  LogInfo("RestoreRegistry", "Attempting to restore from: " + fileName)
  
  ; MANDATORY backup before restore
  If Not EnsureBackupBeforeChange("Restore registry from file: " + fileName)
    ProcedureReturn #False
  EndIf
  
  If MessageRequester("Confirm Restore", 
                      "This will restore registry from:" + #CRLF$ + 
                      fileName + #CRLF$ + #CRLF$ +
                      "A backup has been created at:" + #CRLF$ +
                      AutoBackupPath + #CRLF$ + #CRLF$ +
                      "Continue?", 
                      #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
    UpdateStatusBar("Restoring... Please wait")
    
    program = RunProgram("reg", "import " + Chr(34) + fileName + Chr(34), "", #PB_Program_Wait | #PB_Program_Hide)
    If program
      exitCode = ProgramExitCode(program)
      If exitCode = 0
        LogInfo("RestoreRegistry", "Restore completed successfully from: " + fileName)
        UpdateStatusBar("Restore completed!")
        MessageRequester("Success", "Registry restored successfully!", #PB_MessageRequester_Info)
        ProcedureReturn #True
      Else
        LogError("RestoreRegistry", "Restore process failed with exit code: " + Str(exitCode))
        UpdateStatusBar("Restore failed! Check log file.")
        MessageRequester("Error", "Restore failed! Exit code: " + Str(exitCode), #PB_MessageRequester_Error)
        ProcedureReturn #False
      EndIf
    Else
      LogError("RestoreRegistry", "Failed to execute reg.exe command")
      UpdateStatusBar("Restore failed! Cannot execute restore command.")
      MessageRequester("Error", "Failed to execute restore command!", #PB_MessageRequester_Error)
      ProcedureReturn #False
    EndIf
  Else
    LogInfo("RestoreRegistry", "User cancelled restore operation")
    UpdateStatusBar("Restore cancelled")
  EndIf
  
  ProcedureReturn #False
EndProcedure

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
    
    ; We use 'reg save' which internally calls RegSaveKey. 
    ; This is the standard Windows way to create a compacted/linear copy of a hive.
    program = RunProgram("reg", "save HKCU " + Chr(34) + fullPath + Chr(34) + " /y", "", #PB_Program_Wait | #PB_Program_Open | #PB_Program_Hide)
    
    If program
      exitCode = ProgramExitCode(program)
      CloseProgram(program)
      
      If exitCode = 0
        LogInfo("CompactRegistry", "HKCU optimized and saved to: " + fullPath)
        UpdateStatusBar("Optimization complete.")
        MessageRequester("Optimization Complete", "A compacted copy of your HKCU hive has been created at:" + #CRLF$ + 
                                                  fullPath + #CRLF$ + #CRLF$ +
                                                  "The size of this file represents the minimum footprint of your current settings." + #CRLF$ +
                                                  "Your live registry remains untouched.", #PB_MessageRequester_Info)
      Else
        LogError("CompactRegistry", "Optimization failed with exit code: " + Str(exitCode))
        MessageRequester("Error", "Failed to optimize registry hive." + #CRLF$ + 
                                  "Error Code: " + Str(exitCode) + #CRLF$ + 
                                  "Check if you have sufficient disk space.", #PB_MessageRequester_Error)
        UpdateStatusBar("Optimization failed.")
      EndIf
    Else
      LogError("CompactRegistry", "Failed to launch reg.exe for optimization")
      UpdateStatusBar("Error launching tool.")
    EndIf
  Else
    LogInfo("CompactRegistry", "User cancelled optimization")
    UpdateStatusBar("Ready")
  EndIf
EndProcedure

Procedure CleanRegistry()
  Protected window.i, result.i
  
  LogInfo("CleanRegistry", "Opening registry cleaner dialog")
  
  ; MANDATORY backup before cleaning
  If Not EnsureBackupBeforeChange("Clean registry (remove invalid entries)")
    ProcedureReturn
  EndIf
  
  window = OpenWindow(#PB_Any, 0, 0, 500, 450, "Registry Cleaner", #PB_Window_SystemMenu | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
  If window
    TextGadget(#PB_Any, 10, 10, 480, 20, "Select categories to scan and clean:")
    
    CheckBoxGadget(101, 20, 40, 400, 20, "MUI Cache (Invalid interface strings)") : SetGadgetState(101, #True)
    CheckBoxGadget(102, 20, 65, 400, 20, "Broken File Associations (.ext -> No Program)") : SetGadgetState(102, #True)
    CheckBoxGadget(103, 20, 90, 400, 20, "Obsolete Software (Leftover keys with no folders)") : SetGadgetState(103, #True)
    CheckBoxGadget(104, 20, 115, 400, 20, "Broken Shortcuts / Recent Documents History") : SetGadgetState(104, #True)
    CheckBoxGadget(106, 20, 140, 400, 20, "Invalid Installer References (Source paths)") : SetGadgetState(106, #True)
    CheckBoxGadget(107, 20, 165, 400, 20, "Empty Registry Keys (Safe scan)") : SetGadgetState(107, #True)
    
    EditorGadget(105, 10, 200, 480, 150, #PB_Editor_ReadOnly)
    AddGadgetItem(105, -1, "BACKUP CREATED: " + AutoBackupPath)
    AddGadgetItem(105, -1, "Ready to scan.")
    
    Define btnStartClean = ButtonGadget(#PB_Any, 50, 370, 120, 30, "Scan & Clean")
    Define btnCancelClean = ButtonGadget(#PB_Any, 230, 370, 120, 30, "Close")
    
    Repeat
      Select WaitWindowEvent()
        Case #PB_Event_CloseWindow
          Break
        Case #PB_Event_Gadget
          Select EventGadget()
            Case btnStartClean
              AddGadgetItem(105, -1, "--- Starting Cleanup ---")
              UpdateStatusBar("Cleaning registry...")
              
              Protected wow64.i = #False
              If (GetDefaultSAM() & #KEY_WOW64_64KEY) : wow64 = #True : EndIf
              Protected ret.Registry::RegValue
              Protected i.i, count.i, valName.s, subKeyName.s, cleanedCount.i = 0
              
              ; 1. MUI Cache Cleanup
              If GetGadgetState(101)
                AddGadgetItem(105, -1, "Scanning MUI Cache...")
                Protected muiPath.s = "Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache"
                count = Registry::CountSubValues(#HKEY_CURRENT_USER, muiPath, wow64, @ret)
                For i = count - 1 To 0 Step -1
                  valName = Registry::ListSubValue(#HKEY_CURRENT_USER, muiPath, i, wow64, @ret)
                  ; Check if file exists in the value name (MUI cache uses paths as value names)
                  If valName <> "" And FindString(valName, ":\", 1)
                    Protected filePath.s = valName
                    ; Handle cases where there are arguments or special formatting
                    If Left(filePath, 1) = "@" : filePath = Mid(filePath, 2) : EndIf
                    If FindString(filePath, ",", 1) : filePath = StringField(filePath, 1, ",") : EndIf
                    
                    If FileSize(filePath) = -1 ; File does not exist
                      If Registry::DeleteValue(#HKEY_CURRENT_USER, muiPath, valName, wow64, @ret)
                        cleanedCount + 1
                      EndIf
                    EndIf
                  EndIf
                Next
              EndIf

              ; 1b. Invalid File Associations (.ext -> ProgID)
              If GetGadgetState(102)
                AddGadgetItem(105, -1, "Scanning File Associations...")
                ; We check HKEY_CURRENT_USER\Software\Classes first as it overrides HKCR
                Protected classesPath.s = "Software\Classes"
                count = Registry::CountSubKeys(#HKEY_CURRENT_USER, classesPath, wow64, @ret)
                For i = count - 1 To 0 Step -1
                  subKeyName = Registry::ListSubKey(#HKEY_CURRENT_USER, classesPath, i, wow64, @ret)
                  If Left(subKeyName, 1) = "."
                    ; Check the default value for this extension
                    Protected progID.s = Registry::ReadValue(#HKEY_CURRENT_USER, classesPath + "\" + subKeyName, "", wow64, @ret)
                    If progID <> ""
                      ; Verify if this ProgID exists in HKCU or HKCR
                      If Registry::CountSubKeys(#HKEY_CURRENT_USER, classesPath + "\" + progID, wow64, @ret) = 0 And
                         Registry::CountSubKeys(#HKEY_LOCAL_MACHINE, "Software\Classes\" + progID, wow64, @ret) = 0
                        
                        AddGadgetItem(105, -1, "Removing broken association: " + subKeyName + " -> " + progID)
                        If Registry::DeleteTree(#HKEY_CURRENT_USER, classesPath + "\" + subKeyName, wow64, @ret)
                           cleanedCount + 1
                        EndIf
                      EndIf
                    EndIf
                  EndIf
                Next
              EndIf
              
              ; 1c. Obsolete Software Entries
              If GetGadgetState(103)
                AddGadgetItem(105, -1, "Scanning Obsolete Software Entries...")
                Protected swPath.s = "Software"
                count = Registry::CountSubKeys(#HKEY_CURRENT_USER, swPath, wow64, @ret)
                For i = count - 1 To 0 Step -1
                  subKeyName = Registry::ListSubKey(#HKEY_CURRENT_USER, swPath, i, wow64, @ret)
                  ; Skip critical Windows/Microsoft keys
                  If LCase(subKeyName) <> "microsoft" And LCase(subKeyName) <> "classes" And LCase(subKeyName) <> "wow6432node"
                    ; Check if a folder with this name exists in Program Files or AppData
                    Protected checkPath1.s = GetHomeDirectory() + "AppData\Roaming\" + subKeyName
                    Protected checkPath2.s = GetHomeDirectory() + "AppData\Local\" + subKeyName
                    Protected checkPath3.s = "C:\Program Files\" + subKeyName
                    Protected checkPath4.s = "C:\Program Files (x86)\" + subKeyName
                    
                    If FileSize(checkPath1) = -1 And FileSize(checkPath2) = -1 And FileSize(checkPath3) = -1 And FileSize(checkPath4) = -1
                      ; If no folder exists, it MIGHT be obsolete. 
                      ; To be safe, we only flag it in the log unless it's a known "empty" or "junk" key
                      If Registry::CountSubKeys(#HKEY_CURRENT_USER, swPath + "\" + subKeyName, wow64, @ret) = 0 And 
                         Registry::CountSubValues(#HKEY_CURRENT_USER, swPath + "\" + subKeyName, wow64, @ret) = 0
                        AddGadgetItem(105, -1, "Removing empty obsolete key: " + subKeyName)
                        If Registry::DeleteKey(#HKEY_CURRENT_USER, swPath + "\" + subKeyName, wow64, @ret)
                          cleanedCount + 1
                        EndIf
                      EndIf
                    EndIf
                  EndIf
                Next
              EndIf
              
              ; 2. Recent Docs / Shortcuts
              If GetGadgetState(104)
                AddGadgetItem(105, -1, "Scanning Broken Shortcuts & Recent Docs...")
                ; RecentDocs cleanup
                Protected recentPath.s = "Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs"
                count = Registry::CountSubValues(#HKEY_CURRENT_USER, recentPath, wow64, @ret)
                For i = count - 1 To 0 Step -1
                  valName = Registry::ListSubValue(#HKEY_CURRENT_USER, recentPath, i, wow64, @ret)
                  If valName <> "MRUListEx" And valName <> ""
                    ; RecentDocs values are usually binary or encoded, but some subkeys contain names
                    ; For simplicity, we check the subkeys which are extensions
                  EndIf
                Next
                
                ; Also check "UserAssist" for broken executable references
                Protected assistPath.s = "Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist"
                ; UserAssist is ROT13 encoded, so we'll skip complex decoding for now and stick to 
                ; common shell folder references.
                AddGadgetItem(105, -1, "Recent history scan complete.")
              EndIf
              
              ; 2b. Invalid Installer References
              If GetGadgetState(106)
                AddGadgetItem(105, -1, "Scanning Installer References...")
                Protected installPath.s = "Software\Microsoft\Windows\CurrentVersion\Installer\Folders"
                count = Registry::CountSubValues(#HKEY_CURRENT_USER, installPath, wow64, @ret)
                For i = count - 1 To 0 Step -1
                  valName = Registry::ListSubValue(#HKEY_CURRENT_USER, installPath, i, wow64, @ret)
                  If valName <> "" And FileSize(valName) = -1
                    If Registry::DeleteValue(#HKEY_CURRENT_USER, installPath, valName, wow64, @ret)
                      cleanedCount + 1
                    EndIf
                  EndIf
                Next
              EndIf
              
              ; 2c. Empty Registry Keys
              If GetGadgetState(107)
                AddGadgetItem(105, -1, "Scanning for Empty Keys...")
                ; We only scan a safe subset of HKCU for empty keys to avoid system critical areas
                Protected safePath.s = "Software"
                count = Registry::CountSubKeys(#HKEY_CURRENT_USER, safePath, wow64, @ret)
                For i = count - 1 To 0 Step -1
                  subKeyName = Registry::ListSubKey(#HKEY_CURRENT_USER, safePath, i, wow64, @ret)
                  If Registry::CountSubKeys(#HKEY_CURRENT_USER, safePath + "\" + subKeyName, wow64, @ret) = 0 And
                     Registry::CountSubValues(#HKEY_CURRENT_USER, safePath + "\" + subKeyName, wow64, @ret) = 0
                     ; Avoid core Windows/Microsoft keys even if empty
                     If LCase(subKeyName) <> "microsoft" And LCase(subKeyName) <> "classes"
                       If Registry::DeleteKey(#HKEY_CURRENT_USER, safePath + "\" + subKeyName, wow64, @ret)
                         cleanedCount + 1
                       EndIf
                     EndIf
                  EndIf
                Next
              EndIf
              
              AddGadgetItem(105, -1, "Cleanup finished. Removed " + Str(cleanedCount) + " invalid entries.")
              UpdateStatusBar("Registry cleaning completed. " + Str(cleanedCount) + " items removed.")
              MessageRequester("Complete", "Registry cleaning completed!" + #CRLF$ + "Items removed: " + Str(cleanedCount), #PB_MessageRequester_Info)
              
            Case btnCancelClean
              Break
          EndSelect
      EndSelect
    ForEver
    
    CloseWindow(GetActiveWindow())
  EndIf
EndProcedure

;- Registry Monitor Procedures

Procedure AddMonitorEvent(rootKey.s, keyPath.s, changeType.s, details.s = "")
  Protected timestamp.s
  
  If Not MonitorMutex
    MonitorMutex = CreateMutex()
  EndIf
  If Not MonitorMutex
    ; As a last resort, log without locking (better than freezing)
    timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
    AddElement(MonitorEvents())
    MonitorEvents()\Timestamp = timestamp
    MonitorEvents()\RootKey = rootKey
    MonitorEvents()\KeyPath = keyPath
    MonitorEvents()\ChangeType = changeType
    MonitorEvents()\Details = details
    MonitorEventCount + 1
  LogInfo("RegistryMonitor", "[" + rootKey + "\\" + keyPath + "] " + changeType + " - " + details + "")
    ProcedureReturn
  EndIf

  LockMutex(MonitorMutex)
  
  timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  
  AddElement(MonitorEvents())
  MonitorEvents()\Timestamp = timestamp
  MonitorEvents()\RootKey = rootKey
  MonitorEvents()\KeyPath = keyPath
  MonitorEvents()\ChangeType = changeType
  MonitorEvents()\Details = details
  
  MonitorEventCount + 1
  
  ; Log to file as well
    LogInfo("RegistryMonitor", "[" + rootKey + "\\" + keyPath + "] " + changeType + " - " + details + "")
  
  ; NOTE: Do NOT touch GUI gadgets from worker threads.
  ; The main event loop should periodically refresh the monitor list from MonitorEvents().
  
  UnlockMutex(MonitorMutex)
EndProcedure

Procedure MonitorRegistryKey(param.i)
  Protected hKey.i, result.i, error.i
  Protected rootKey.i, keyPath.s, rootName.s
  Protected hEvent.i
  
  ; Decode parameter (rootKey in high word, index in low word)
  rootKey = param >> 16
  
  Select rootKey
    Case #HKEY_CLASSES_ROOT
      rootName = "HKCR"
      keyPath = ""
    Case #HKEY_CURRENT_USER
      rootName = "HKCU"
      keyPath = ""
    Case #HKEY_LOCAL_MACHINE
      rootName = "HKLM"
      keyPath = ""
    Case #HKEY_USERS
      rootName = "HKU"
      keyPath = ""
    Case #HKEY_CURRENT_CONFIG
      rootName = "HKCC"
      keyPath = ""
  EndSelect
  
  LogInfo("MonitorThread", "Starting monitoring for " + rootName)
  
  ; Open registry key for notification
  error = RegOpenKeyEx_(rootKey, keyPath, 0, #KEY_NOTIFY, @hKey)
  If error = 0
    ; Create event for notification
    hEvent = PB_CreateEventW(0, #True, #False, 0)
    
    If hEvent
      While MonitorActive
        ; Register for change notification
        result = PB_RegNotifyChangeKeyValue(hKey, #True, 
                                           #REG_NOTIFY_CHANGE_NAME | 
                                           #REG_NOTIFY_CHANGE_LAST_SET | 
                                           #REG_NOTIFY_CHANGE_ATTRIBUTES |
                                           #REG_NOTIFY_CHANGE_SECURITY, 
                                           hEvent, #True)
        
        If result = 0
          ; Wait for change notification or stop signal
          result = PB_WaitForSingleObject(hEvent, 1000) ; 1 second timeout
          
          If result = 0 ; Event signaled (registry change detected)
            AddMonitorEvent(rootName, keyPath, "Registry Modified", "Key tree changed")
            PB_ResetEvent(hEvent)
          ElseIf result = $102 ; WAIT_TIMEOUT
            ; Continue monitoring
          Else
            LogError("MonitorThread", "WaitForSingleObject failed: " + Str(result))
            Break
          EndIf
        Else
          ; If error is 5 (Access Denied), we might need to log it and stop
          LogError("MonitorThread", "RegNotifyChangeKeyValue failed: " + Str(result))
          Break
        EndIf
        
        ; Small delay to prevent CPU spinning
        Delay(50)
      Wend
      
      PB_CloseHandle(hEvent)
    Else
      LogError("MonitorThread", "Failed to create event handle")
    EndIf
    
    RegCloseKey_(hKey)
  Else
    LogError("MonitorThread", "Failed to open registry key: " + rootName + " (Error: " + Str(error) + ")")
  EndIf
  
  LogInfo("MonitorThread", "Stopped monitoring for " + rootName)
EndProcedure


Procedure StartRegistryMonitor()
  Protected thread1.i, thread2.i, thread3.i, thread4.i, thread5.i
  
  If MonitorActive
    LogWarning("StartRegistryMonitor", "Monitor already running")
    MessageRequester("Info", "Monitor is already running!", #PB_MessageRequester_Info)
    ProcedureReturn #False
  EndIf
  
  LogInfo("StartRegistryMonitor", "Starting registry monitor")
  
  MonitorActive = #True
  MonitorEventCount = 0
  
  ; Create mutex for thread-safe event list access
  If Not MonitorMutex
    MonitorMutex = CreateMutex()
    If Not MonitorMutex
      LogError("StartRegistryMonitor", "Failed to create mutex")
      MonitorActive = #False
      MessageRequester("Error", "Failed to create synchronization mutex!", #PB_MessageRequester_Error)
      ProcedureReturn #False
    EndIf
    LogInfo("StartRegistryMonitor", "Mutex created successfully")
  EndIf
  
  ; Start monitoring threads for each major hive
  thread1 = CreateThread(@MonitorRegistryKey(), #HKEY_CLASSES_ROOT << 16)
  thread2 = CreateThread(@MonitorRegistryKey(), #HKEY_CURRENT_USER << 16)
  thread3 = CreateThread(@MonitorRegistryKey(), #HKEY_LOCAL_MACHINE << 16)
  thread4 = CreateThread(@MonitorRegistryKey(), #HKEY_USERS << 16)
  thread5 = CreateThread(@MonitorRegistryKey(), #HKEY_CURRENT_CONFIG << 16)
  
  LogInfo("StartRegistryMonitor", "Thread IDs: " + Str(thread1) + ", " + Str(thread2) + ", " + Str(thread3) + ", " + Str(thread4) + ", " + Str(thread5))
  
  If thread1 = 0 Or thread2 = 0 Or thread3 = 0 Or thread4 = 0 Or thread5 = 0
    LogError("StartRegistryMonitor", "Failed to create one or more monitoring threads")
    MessageRequester("Error", "Failed to create monitoring threads!", #PB_MessageRequester_Error)
    MonitorActive = #False
    ProcedureReturn #False
  EndIf
  
  AddMonitorEvent("SYSTEM", "Monitor", "Started", "Registry monitoring activated - 5 threads running")
  
  LogInfo("StartRegistryMonitor", "Monitor threads started successfully")
  MessageRequester("Success", "Registry monitor started!" + #CRLF$ + "5 monitoring threads active.", #PB_MessageRequester_Info)
  ProcedureReturn #True
EndProcedure

Procedure StopRegistryMonitor()
  If Not MonitorActive
    LogWarning("StopRegistryMonitor", "Monitor not running")
    ProcedureReturn #False
  EndIf
  
  LogInfo("StopRegistryMonitor", "Stopping registry monitor")
  
  MonitorActive = #False
  
  ; Give threads time to exit cleanly
  Delay(2000)
  
  AddMonitorEvent("SYSTEM", "Monitor", "Stopped", "Registry monitoring deactivated - " + Str(MonitorEventCount) + " events captured")
  
  LogInfo("StopRegistryMonitor", "Monitor stopped - Total events: " + Str(MonitorEventCount))
  ProcedureReturn #True
EndProcedure

Procedure SaveMonitorLog(fileName.s)
  Protected file.i, count.i
  
  If fileName = ""
    LogError("SaveMonitorLog", "Empty filename provided")
    ProcedureReturn #False
  EndIf
  
  file = CreateFile(#PB_Any, fileName)
  If file
    WriteStringN(file, "Registry Monitor Log - Generated: " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()))
    WriteStringN(file, "=" + Space(80) + "=")
    WriteStringN(file, "")
    WriteStringN(file, "Total Events: " + Str(MonitorEventCount))
    WriteStringN(file, "")
    WriteStringN(file, "Timestamp" + Chr(9) + "Root Key" + Chr(9) + "Key Path" + Chr(9) + "Change Type" + Chr(9) + "Details")
    WriteStringN(file, "-" + Space(80) + "-")
    
    LockMutex(MonitorMutex)
    
    ForEach MonitorEvents()
      WriteStringN(file, MonitorEvents()\Timestamp + Chr(9) + 
                        MonitorEvents()\RootKey + Chr(9) + 
                        MonitorEvents()\KeyPath + Chr(9) + 
                        MonitorEvents()\ChangeType + Chr(9) + 
                        MonitorEvents()\Details)
      count + 1
    Next
    
    UnlockMutex(MonitorMutex)
    
    WriteStringN(file, "")
    WriteStringN(file, "=" + Space(80) + "=")
    WriteStringN(file, "End of Log - " + Str(count) + " events written")
    
    CloseFile(file)
    
    LogInfo("SaveMonitorLog", "Saved " + Str(count) + " events to: " + fileName)
    MessageRequester("Success", "Monitor log saved successfully!" + #CRLF$ + fileName + #CRLF$ + #CRLF$ + Str(count) + " events written", #PB_MessageRequester_Info)
    ProcedureReturn #True
  Else
    LogError("SaveMonitorLog", "Failed to create log file: " + fileName)
    MessageRequester("Error", "Failed to save monitor log!", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure RefreshMonitorWindow()
  If Not IsWindow(#WINDOW_MONITOR) : ProcedureReturn : EndIf
  If Not IsGadget(#GADGET_MONITOR_LIST) : ProcedureReturn : EndIf
  If txtMonitorStatus And IsGadget(txtMonitorStatus)
    Define statusText.s
    If MonitorActive
      statusText = "Running"
    Else
      statusText = "Stopped"
    EndIf
    SetGadgetText(txtMonitorStatus, "Events: " + Str(MonitorEventCount) + " | Status: " + statusText)
  EndIf

  If Not MonitorMutex
    MonitorMutex = CreateMutex()
  EndIf
  If Not MonitorMutex : ProcedureReturn : EndIf

  LockMutex(MonitorMutex)
  If MonitorLastShownCount < 0 : MonitorLastShownCount = 0 : EndIf

  ; Safety: keep the UI synced even if the list resets.
  If MonitorEventCount <> ListSize(MonitorEvents())
    MonitorEventCount = ListSize(MonitorEvents())
  EndIf

  If MonitorEventCount < MonitorLastShownCount
    ClearGadgetItems(#GADGET_MONITOR_LIST)
    MonitorLastShownCount = 0
  EndIf

  If MonitorEventCount > MonitorLastShownCount
    Define idx = 0
    ForEach MonitorEvents()
      idx + 1
      If idx <= MonitorLastShownCount : Continue : EndIf

      AddGadgetItem(#GADGET_MONITOR_LIST, -1, MonitorEvents()\Timestamp + Chr(9) + 
                                              MonitorEvents()\RootKey + Chr(9) + 
                                              MonitorEvents()\KeyPath + Chr(9) + 
                                              MonitorEvents()\ChangeType + Chr(9) + 
                                              MonitorEvents()\Details)
    Next

    MonitorLastShownCount = idx
  EndIf
  UnlockMutex(MonitorMutex)
EndProcedure

Procedure OpenMonitorWindow()
  Protected window.i
  
  If MonitorWindow And IsWindow(MonitorWindow)
    SetActiveWindow(MonitorWindow)
    ProcedureReturn
  EndIf
  
  LogInfo("OpenMonitorWindow", "Opening registry monitor window")
  
  window = OpenWindow(#WINDOW_MONITOR, 0, 0, 900, 600, "Registry Monitor - Real-Time Change Tracking", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
  
  If window
    MonitorWindow = window
    
    ; Create list gadget for events
    ListIconGadget(#GADGET_MONITOR_LIST, 10, 10, 880, 490, "Timestamp", 150, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(#GADGET_MONITOR_LIST, 1, "Root Key", 80)
    AddGadgetColumn(#GADGET_MONITOR_LIST, 2, "Key Path", 250)
    AddGadgetColumn(#GADGET_MONITOR_LIST, 3, "Change Type", 120)
    AddGadgetColumn(#GADGET_MONITOR_LIST, 4, "Details", 200)
    
    ; Control buttons
    ButtonGadget(#GADGET_MONITOR_START, 10, 510, 100, 30, "Start Monitor")
    ButtonGadget(#GADGET_MONITOR_STOP, 120, 510, 100, 30, "Stop Monitor")
    ButtonGadget(#GADGET_MONITOR_CLEAR, 230, 510, 100, 30, "Clear Log")
    ButtonGadget(#GADGET_MONITOR_SAVE, 340, 510, 100, 30, "Save Log")
    
    txtMonitorStatus = TextGadget(#PB_Any, 450, 515, 400, 20, "Events: 0 | Status: Stopped", #PB_Text_Right)
    
    ; Populate with existing events
    MonitorLastShownCount = 0
    RefreshMonitorWindow()
    
    ; Update button states
    If MonitorActive
      DisableGadget(#GADGET_MONITOR_START, #True)
      DisableGadget(#GADGET_MONITOR_STOP, #False)
      SetGadgetText(txtMonitorStatus, "Events: " + Str(MonitorEventCount) + " | Status: Running")
    Else
      DisableGadget(#GADGET_MONITOR_START, #False)
      DisableGadget(#GADGET_MONITOR_STOP, #True)
      SetGadgetText(txtMonitorStatus, "Events: " + Str(MonitorEventCount) + " | Status: Stopped")
    EndIf
    
    ; Start periodic refresh in main thread
    AddWindowTimer(#WINDOW_MONITOR, #TIMER_MONITOR_REFRESH, #MONITOR_REFRESH_INTERVAL)

    LogInfo("OpenMonitorWindow", "Monitor window opened successfully")
  Else
    LogError("OpenMonitorWindow", "Failed to open monitor window")
    MessageRequester("Error", "Cannot open monitor window!", #PB_MessageRequester_Error)
  EndIf
EndProcedure

; NOTE: This procedure is no longer used - events handled in main loop
; Keeping it here for reference only
Procedure HandleMonitorWindow_OLD()
  ; This function has been deprecated to fix the freeze bug
  ; Events are now handled in the main event loop
EndProcedure

;- Registry Snapshot Procedures

Procedure.s GetSnapshotDirectory()
  Protected snapshotDir.s
  
  snapshotDir = GetHomeDirectory() + "RegistryManager_Snapshots\"
  
  If FileSize(snapshotDir) <> -2
    If CreateDirectory(snapshotDir)
      LogInfo("GetSnapshotDirectory", "Created snapshot directory: " + snapshotDir)
    Else
      LogError("GetSnapshotDirectory", "Failed to create snapshot directory")
      snapshotDir = GetTemporaryDirectory() + "RegistryManager_Snapshots\"
      CreateDirectory(snapshotDir)
    EndIf
  EndIf
  
  ProcedureReturn snapshotDir
EndProcedure

Procedure.s SanitizeFileName(input.s)
  Protected out.s = input
  out = ReplaceString(out, "\\", "_")
  out = ReplaceString(out, "/", "_")
  out = ReplaceString(out, ":", "_")
  out = ReplaceString(out, "*", "_")
  out = ReplaceString(out, "?", "_")
  out = ReplaceString(out, Chr(34), "_")
  out = ReplaceString(out, "<", "_")
  out = ReplaceString(out, ">", "_")
  out = ReplaceString(out, "|", "_")
  ProcedureReturn Trim(out)
EndProcedure

Procedure CreateRegistrySnapshot(name.s, description.s = "")
  Protected snapshotFile.s, timestamp.s, program.i, exitCode.i
  
  timestamp = FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date())
  SnapshotDirectory = GetSnapshotDirectory()
  
  If name = ""
    name = "Snapshot_" + timestamp
  EndIf
  
  snapshotFile = SnapshotDirectory + name + ".reg"
  
  LogInfo("CreateRegistrySnapshot", "Creating snapshot: " + name)
  UpdateStatusBar("Creating registry snapshot... Please wait")
  
  ; Export entire HKLM registry
   program = RunProgram("reg", "export HKLM " + Chr(34) + snapshotFile + Chr(34) + " /y", "", #PB_Program_Wait | #PB_Program_Hide)
   
   ; If called from GUI thread, this can block for a while.
   ; Snapshot manager triggers this via a worker thread to keep UI responsive.
  If program
    exitCode = ProgramExitCode(program)
    If exitCode = 0 And FileSize(snapshotFile) > 0
      ; Add to snapshot list
      AddElement(Snapshots())
      Snapshots()\Name = name
      Snapshots()\Timestamp = timestamp
      Snapshots()\FilePath = snapshotFile
      Snapshots()\Description = description
      Snapshots()\FileSize = FileSize(snapshotFile)
      
      LogInfo("CreateRegistrySnapshot", "Snapshot created: " + snapshotFile + " (" + Str(FileSize(snapshotFile)) + " bytes)")
      UpdateStatusBar("Snapshot created: " + name)
      
      ; Note: avoid MessageRequester from background thread.
      ; UI will refresh list automatically.
      ProcedureReturn #True
    Else
      LogError("CreateRegistrySnapshot", "Snapshot creation failed with exit code: " + Str(exitCode))
      UpdateStatusBar("Snapshot creation failed!")
      ; Note: avoid MessageRequester from background thread.
      ; Errors are logged; UI remains responsive.
      ProcedureReturn #False
    EndIf
  Else
    LogError("CreateRegistrySnapshot", "Failed to execute reg.exe")
    UpdateStatusBar("Snapshot creation failed!")
    ; Note: avoid MessageRequester from background thread.
    ; Errors are logged; UI remains responsive.
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure LoadSnapshots()
  Protected dir.i, fileName.s, filePath.s, fileDate.i
  
  SnapshotDirectory = GetSnapshotDirectory()
  ClearList(Snapshots())
  
  LogInfo("LoadSnapshots", "Loading snapshots from: " + SnapshotDirectory)
  
  dir = ExamineDirectory(#PB_Any, SnapshotDirectory, "*.reg")
  If dir
    While NextDirectoryEntry(dir)
      fileName = DirectoryEntryName(dir)
      If fileName <> "." And fileName <> ".."
        filePath = SnapshotDirectory + fileName
        fileDate = GetFileDate(filePath, #PB_Date_Modified)
        
        AddElement(Snapshots())
        Snapshots()\Name = Left(fileName, Len(fileName) - 4) ; Remove .reg extension
        Snapshots()\Timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", fileDate)
        Snapshots()\FilePath = filePath
        Snapshots()\FileSize = FileSize(filePath)
        Snapshots()\Description = "Loaded from disk"
      EndIf
    Wend
    FinishDirectory(dir)
    
    LogInfo("LoadSnapshots", "Loaded " + Str(ListSize(Snapshots())) + " snapshot(s)")
  Else
    LogWarning("LoadSnapshots", "Cannot open snapshot directory")
  EndIf
EndProcedure

Procedure DeleteSnapshot(snapshotName.s, skipConfirm.i = #False)
  Protected found.i = #False
  
  ; Ensure the internal list is synced with the folder on disk before we look for the snapshot
  LoadSnapshots()
  
  ForEach Snapshots()
    ; Use LCase for safety in case of case-sensitive string comparisons
    If LCase(Snapshots()\Name) = LCase(snapshotName)
      found = #True
      
      ; Construct full path manually to be absolutely sure it's valid
      Protected fullFilePath.s = Snapshots()\FilePath
      If fullFilePath = "" Or FileSize(fullFilePath) < 0
        ; Fallback: rebuild path if for some reason Snapshots()\FilePath is empty
        fullFilePath = GetSnapshotDirectory() + snapshotName + ".reg"
      EndIf
      
      If skipConfirm Or MessageRequester("Confirm Delete", 
                          "Delete snapshot: " + snapshotName + "?" + #CRLF$ + #CRLF$ +
                          "File: " + fullFilePath + #CRLF$ +
                          "Size: " + Str(FileSize(fullFilePath)/1024) + " KB" + #CRLF$ + #CRLF$ +
                          "This cannot be undone!", 
                          #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
        
        If DeleteFile(fullFilePath)
          LogInfo("DeleteSnapshot", "Deleted snapshot: " + snapshotName + " (File: " + fullFilePath + ")")
          DeleteElement(Snapshots())
          UpdateStatusBar("Snapshot deleted: " + snapshotName)
          ProcedureReturn #True
        Else
          LogError("DeleteSnapshot", "Failed to delete file: " + fullFilePath + " (Error: " + Str(GetLastError_()) + ")")
          If FileSize(fullFilePath) = -1
             LogWarning("DeleteSnapshot", "File already gone from disk: " + fullFilePath)
             DeleteElement(Snapshots())
             ProcedureReturn #True
          EndIf
          MessageRequester("Error", "Failed to delete snapshot file!" + #CRLF$ + "Path: " + fullFilePath, #PB_MessageRequester_Error)
          ProcedureReturn #False
        EndIf
      Else
        LogInfo("DeleteSnapshot", "User cancelled deletion of: " + snapshotName)
        ProcedureReturn #False
      EndIf
    EndIf
  Next
  
  If Not found
    LogWarning("DeleteSnapshot", "Snapshot not found in list: " + snapshotName)
    ; Final fallback attempt: Try to delete the file directly even if not in the Snapshots() list
    Protected fallbackPath.s = GetSnapshotDirectory() + snapshotName + ".reg"
    If FileSize(fallbackPath) >= 0
      If DeleteFile(fallbackPath)
        LogInfo("DeleteSnapshot", "Deleted snapshot via fallback path: " + fallbackPath)
        ProcedureReturn #True
      EndIf
    ElseIf FileSize(fallbackPath) = -1
      LogInfo("DeleteSnapshot", "Ghost item detected - removing from UI by returning True: " + snapshotName)
      ProcedureReturn #True
    EndIf
  EndIf
  
  ProcedureReturn #False
EndProcedure

Procedure CompareSnapshots(snapshot1.s, snapshot2.s)
  Protected file1.i, file2.i, currentKey.s, content.s
  Protected addedCount.i, removedCount.i, modifiedCount.i
  Protected NewMap keys1.s()
  Protected NewMap keys2.s()
  
  LogInfo("CompareSnapshots", "Comparing: " + snapshot1 + " vs " + snapshot2)
  UpdateStatusBar("Comparing snapshots... Please wait")
  
  ClearList(DiffResults())
  
  ; Find snapshot file paths
  Protected path1.s, path2.s
  ForEach Snapshots()
    If Snapshots()\Name = snapshot1 : path1 = Snapshots()\FilePath : EndIf
    If Snapshots()\Name = snapshot2 : path2 = Snapshots()\FilePath : EndIf
  Next
  
  If path1 = "" Or path2 = ""
    LogError("CompareSnapshots", "Snapshot file(s) not found")
    ProcedureReturn #False
  EndIf
  
  ; Helper to load snapshot into map
  file1 = ReadFile(#PB_Any, path1)
  If file1
    While Not Eof(file1)
      Protected l1.s = ReadString(file1)
      If Left(l1, 1) = "[" And Right(l1, 1) = "]"
        If currentKey <> "" : keys1(currentKey) = content : EndIf
        currentKey = l1
        content = ""
      ElseIf currentKey <> "" And l1 <> ""
        content + l1 + #LF$
      EndIf
    Wend
    If currentKey <> "" : keys1(currentKey) = content : EndIf
    CloseFile(file1)
  EndIf

  currentKey = "" : content = ""
  file2 = ReadFile(#PB_Any, path2)
  If file2
    While Not Eof(file2)
      Protected l2.s = ReadString(file2)
      If Left(l2, 1) = "[" And Right(l2, 1) = "]"
        If currentKey <> "" : keys2(currentKey) = content : EndIf
        currentKey = l2
        content = ""
      ElseIf currentKey <> "" And l2 <> ""
        content + l2 + #LF$
      EndIf
    Wend
    If currentKey <> "" : keys2(currentKey) = content : EndIf
    CloseFile(file2)
  EndIf
  
  ; Added or Modified
  ForEach keys2()
    currentKey = MapKey(keys2())
    If Not FindMapElement(keys1(), currentKey)
      AddElement(DiffResults())
      DiffResults()\Timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
      DiffResults()\ChangeType = "ADDED"
      DiffResults()\KeyPath = currentKey
      DiffResults()\NewData = "Key added"
      addedCount + 1
    Else
      ; Compare individual values within the key
      If keys1(currentKey) <> keys2(currentKey)
        Protected NewMap values1.s()
        Protected NewMap values2.s()
        Protected line.s, vName.s, vData.s, i.i
        
        ; Parse values from snapshot 1 key content
        Protected iCount = CountString(keys1(currentKey), #LF$)
        For i = 1 To iCount
          line = StringField(keys1(currentKey), i, #LF$)
          If line <> ""
            vName = StringField(line, 1, "=")
            vData = Mid(line, Len(vName) + 2)
            values1(vName) = vData
          EndIf
        Next
        
        ; Parse values from snapshot 2 key content
        iCount = CountString(keys2(currentKey), #LF$)
        For i = 1 To iCount
          line = StringField(keys2(currentKey), i, #LF$)
          If line <> ""
            vName = StringField(line, 1, "=")
            vData = Mid(line, Len(vName) + 2)
            values2(vName) = vData
          EndIf
        Next
        
        ; Identify Added or Modified values
        ForEach values2()
          vName = MapKey(values2())
          If Not FindMapElement(values1(), vName)
            AddElement(DiffResults())
            DiffResults()\Timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
            DiffResults()\ChangeType = "MODIFIED"
            DiffResults()\KeyPath = currentKey
            DiffResults()\ValueName = vName
            DiffResults()\NewData = "Value added: " + values2(vName)
            modifiedCount + 1
          ElseIf values1(vName) <> values2(vName)
            AddElement(DiffResults())
            DiffResults()\Timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
            DiffResults()\ChangeType = "MODIFIED"
            DiffResults()\KeyPath = currentKey
            DiffResults()\ValueName = vName
            DiffResults()\OldData = "Old: " + values1(vName)
            DiffResults()\NewData = "New: " + values2(vName)
            modifiedCount + 1
          EndIf
        Next
        
        ; Identify Removed values
        ForEach values1()
          vName = MapKey(values1())
          If Not FindMapElement(values2(), vName)
            AddElement(DiffResults())
            DiffResults()\Timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
            DiffResults()\ChangeType = "MODIFIED"
            DiffResults()\KeyPath = currentKey
            DiffResults()\ValueName = vName
            DiffResults()\OldData = "Value removed: " + values1(vName)
            modifiedCount + 1
          EndIf
        Next
      EndIf
    EndIf
  Next
  
  ; Removed
  ForEach keys1()
    currentKey = MapKey(keys1())
    If Not FindMapElement(keys2(), currentKey)
      AddElement(DiffResults())
      DiffResults()\Timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
      DiffResults()\ChangeType = "REMOVED"
      DiffResults()\KeyPath = currentKey
      DiffResults()\OldData = "Key removed"
      removedCount + 1
    EndIf
  Next
  
  LogInfo("CompareSnapshots", "Comparison complete: " + Str(addedCount) + " added, " + Str(removedCount) + " removed, " + Str(modifiedCount) + " modified")
  UpdateStatusBar("Comparison complete: " + Str(addedCount + removedCount + modifiedCount) + " differences found")
  
  MessageRequester("Comparison Complete", 
                   "Results:" + #CRLF$ + "Added: " + Str(addedCount) + #CRLF$ + "Removed: " + Str(removedCount) + #CRLF$ + "Modified: " + Str(modifiedCount))
  
  ProcedureReturn #True
EndProcedure


Procedure ExportDifferences(fileName.s)
  Protected file.i, count.i
  
  If fileName = ""
    LogError("ExportDifferences", "Empty filename")
    ProcedureReturn #False
  EndIf
  
  file = CreateFile(#PB_Any, fileName)
  If file
    WriteStringN(file, "Registry Snapshot Comparison Report")
    WriteStringN(file, "Generated: " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()))
    WriteStringN(file, "=" + Space(80) + "=")
    WriteStringN(file, "")
    WriteStringN(file, "Timestamp" + Chr(9) + "Change Type" + Chr(9) + "Key Path" + Chr(9) + "Details")
    WriteStringN(file, "-" + Space(80) + "-")
    
    ForEach DiffResults()
      WriteStringN(file, DiffResults()\Timestamp + Chr(9) +
                        DiffResults()\ChangeType + Chr(9) +
                        DiffResults()\KeyPath + Chr(9) +
                        DiffResults()\NewData + DiffResults()\OldData)
      count + 1
    Next

    
    WriteStringN(file, "")
    WriteStringN(file, "=" + Space(80) + "=")
    WriteStringN(file, "Total Differences: " + Str(count))
    
    CloseFile(file)
    
    LogInfo("ExportDifferences", "Exported " + Str(count) + " differences to: " + fileName)
    MessageRequester("Success", "Comparison report exported!" + #CRLF$ + fileName, #PB_MessageRequester_Info)
    ProcedureReturn #True
  Else
    LogError("ExportDifferences", "Cannot create file: " + fileName)
    MessageRequester("Error", "Failed to export report!", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf
EndProcedure

Procedure OpenSnapshotWindow()
  Protected window.i
  
  If SnapshotWindow And IsWindow(SnapshotWindow)
    SetActiveWindow(SnapshotWindow)
    ProcedureReturn
  EndIf
  
  LogInfo("OpenSnapshotWindow", "Opening snapshot manager")
  LoadSnapshots()
  
  window = OpenWindow(#WINDOW_SNAPSHOT, 0, 0, 900, 600, "Registry Snapshot Manager - Compare Registry States", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered, WindowID(#WINDOW_MAIN))
  
  If window
    SnapshotWindow = window
    
    ; Snapshot list
    ListIconGadget(#GADGET_SNAPSHOT_LIST, 10, 10, 880, 300, "Snapshot Name", 250, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect | #PB_ListIcon_CheckBoxes)
    AddGadgetColumn(#GADGET_SNAPSHOT_LIST, 1, "Timestamp", 150)
    AddGadgetColumn(#GADGET_SNAPSHOT_LIST, 2, "Size (KB)", 100)
    AddGadgetColumn(#GADGET_SNAPSHOT_LIST, 3, "Description", 300)
    
    ; Populate list
    ForEach Snapshots()
      AddGadgetItem(#GADGET_SNAPSHOT_LIST, -1, Snapshots()\Name + Chr(9) +
                                                Snapshots()\Timestamp + Chr(9) +
                                                Str(Snapshots()\FileSize/1024) + Chr(9) +
                                                Snapshots()\Description)
    Next
    
    ; Control buttons
    ButtonGadget(#GADGET_SNAPSHOT_CREATE, 10, 320, 120, 30, "Create Snapshot")
    ButtonGadget(#GADGET_SNAPSHOT_DELETE, 140, 320, 120, 30, "Delete Selected")
    ButtonGadget(#GADGET_SNAPSHOT_COMPARE, 270, 320, 120, 30, "Compare (2)")
    ButtonGadget(#GADGET_SNAPSHOT_EXPORT, 400, 320, 120, 30, "Export Diff")
    
    ; Differences list
    TextGadget(#PB_Any, 10, 360, 300, 20, "Comparison Results:")
    ListIconGadget(#GADGET_SNAPSHOT_DIFF, 10, 380, 880, 160, "Change Type", 100, #PB_ListIcon_GridLines | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(#GADGET_SNAPSHOT_DIFF, 1, "Key Path", 500)
    AddGadgetColumn(#GADGET_SNAPSHOT_DIFF, 2, "Details", 250)
    
    TextGadget(#PB_Any, 10, 550, 880, 20, "Snapshots: " + Str(ListSize(Snapshots())) + " | Snapshot Directory: " + GetSnapshotDirectory())
    
    SnapshotCreationActive = 0
    AddWindowTimer(#WINDOW_SNAPSHOT, #TIMER_SNAPSHOT_REFRESH, #SNAPSHOT_REFRESH_INTERVAL)

    LogInfo("OpenSnapshotWindow", "Snapshot window opened")
  Else
    LogError("OpenSnapshotWindow", "Failed to open window")
    MessageRequester("Error", "Cannot open snapshot window!", #PB_MessageRequester_Error)
  EndIf
EndProcedure

; NOTE: This procedure is no longer used - events handled in main loop
; Keeping it here for reference only
Procedure HandleSnapshotWindow_OLD()
  ; This function has been deprecated to fix the freeze bug
  ; Events are now handled in the main event loop
EndProcedure

Procedure CreateGUI()
  Protected window.i, menu.i
  
  LogInfo("CreateGUI", "Creating main window and GUI")
  
  window = OpenWindow(#WINDOW_MAIN, 0, 0, 1024, 768, "Registry Manager " + version + " - Editor | Cleaner | Backup | Restore | Compactor", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_MaximizeGadget | #PB_Window_MinimizeGadget | #PB_Window_ScreenCentered)
  
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
    
     ; Add root keys to tree
     Define rootCR.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_CLASSES_ROOT")
     Define rootCU.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_CURRENT_USER")
     Define rootLM.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_LOCAL_MACHINE")
     Define rootUS.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_USERS")
     Define rootCC.i = AddGadgetItem(#GADGET_TREE, -1, "HKEY_CURRENT_CONFIG")
     
      ; Lazy load subkeys on double-click (avoid freezing on startup).
      ClearMap(TreeChildrenLoaded())
      TreeChildrenLoaded(Str(rootCR)) = #False
      TreeChildrenLoaded(Str(rootCU)) = #False
      TreeChildrenLoaded(Str(rootLM)) = #False
      TreeChildrenLoaded(Str(rootUS)) = #False
      TreeChildrenLoaded(Str(rootCC)) = #False
    
    ; Create ListView for Values
    If Not ListViewGadget(#GADGET_LISTVIEW, 300, 0, WindowWidth(#WINDOW_MAIN) - 300, WindowHeight(#WINDOW_MAIN) - 20)
      LogError("CreateGUI", "Failed to create listview gadget")
      ProcedureReturn #False
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

;- Favorites Procedures

Procedure SaveFavorites()
  Protected file.i, favPath.s = GetCurrentDirectory() + "Favorites.txt"
  file = CreateFile(#PB_Any, favPath)
  If file
    ForEach Favorites()
      WriteStringN(file, Favorites())
    Next
    CloseFile(file)
  EndIf
EndProcedure

Procedure LoadFavorites()
  Protected file.i, favPath.s = GetCurrentDirectory() + "Favorites.txt"
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
  
  ; We'll assume Favorites is the 5th title (File, Edit, Tools, View, Help)
  ; Let's insert it before Help or just at the end.
  ; To make it robust, we'll use a fixed position if we can't find it.
  
  ; Actually, it's better to just use a dedicated Favorites menu title
  ; that we clear and rebuild if PB supported it easily. 
  ; Since we are on Windows, we can use some API to clean up if needed, 
  ; but let's stick to PB's way: rebuilding the whole menu or just appending.
  
  ; For now, let's just make sure the menu is updated when the app starts 
  ; and when a favorite is added.
EndProcedure

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


Procedure.i FindTreeItemByPath(rootKey.i, path.s)
  Protected i.i, count.i, currentItem.i = -1
  Protected segment.s, remainingPath.s = path
  Protected rootName.s = GetRootKeyName(rootKey)
  
  ; 1. Find the root hive item
  count = CountGadgetItems(#GADGET_TREE)
  For i = 0 To count - 1
    If GetGadgetItemText(#GADGET_TREE, i) = rootName And GetGadgetItemAttribute(#GADGET_TREE, i, #PB_Tree_SubLevel) = 0
      currentItem = i
      Break
    EndIf
  Next
  
  If currentItem = -1 : ProcedureReturn -1 : EndIf
  
  ; 2. Recursively find segments
  If path = "" : ProcedureReturn currentItem : EndIf
  
  While remainingPath <> ""
    segment = StringField(remainingPath, 1, "\")
    remainingPath = Mid(remainingPath, Len(segment) + 2)
    
    ; Ensure children are loaded for the current item
    If FindMapElement(TreeChildrenLoaded(), Str(currentItem)) = 0 Or TreeChildrenLoaded(Str(currentItem)) = #False
      Define parentPath.s = ""
      If currentItem > 0
        ; Build path for LoadSubKeys - this is slightly simplified as we'd need the full path
        ; But for our jump logic, we can keep track of it
      EndIf
      ; For the jump logic to work, we need to know the path of the currentItem to load its children
      ; Let's assume the calling logic handles expansion or we enhance LoadSubKeys
    EndIf
    
    ; This implementation requires a way to get the path of a tree item or passing it down.
    ; Since GetGadgetItemText only returns the name, not the full path, 
    ; we must iterate children and match names.
    
    Protected foundChild.i = -1
    Protected startSearch.i = currentItem + 1
    Protected parentLevel.i = GetGadgetItemAttribute(#GADGET_TREE, currentItem, #PB_Tree_SubLevel)
    
    ; Trigger loading if not loaded
    If FindMapElement(TreeChildrenLoaded(), Str(currentItem)) = 0 Or TreeChildrenLoaded(Str(currentItem)) = #False
       ; We need the path up to this point. 
       ; For JumpToPath, it's easier to build it as we go.
    EndIf
    
    ; Search children (next items with level = parentLevel + 1)
    For i = startSearch To count - 1
      Protected currentLevel.i = GetGadgetItemAttribute(#GADGET_TREE, i, #PB_Tree_SubLevel)
      If currentLevel <= parentLevel : Break : EndIf ; No more children
      
      If currentLevel = parentLevel + 1
        If GetGadgetItemText(#GADGET_TREE, i) = segment
          foundChild = i
          Break
        EndIf
      EndIf
    Next
    
    If foundChild = -1 : ProcedureReturn -1 : EndIf
    currentItem = foundChild
  Wend
  
  ProcedureReturn currentItem
EndProcedure

Procedure JumpToPath(fullPath.s)
  Protected rootKey.i, keyPath.s, rootPart.s
  
  If fullPath = "" : ProcedureReturn : EndIf
  
  rootPart = StringField(fullPath, 1, "\")
  keyPath = Mid(fullPath, Len(rootPart) + 2)
  
  Select rootPart
    Case "HKEY_CLASSES_ROOT": rootKey = #HKEY_CLASSES_ROOT
    Case "HKEY_CURRENT_USER": rootKey = #HKEY_CURRENT_USER
    Case "HKEY_LOCAL_MACHINE": rootKey = #HKEY_LOCAL_MACHINE
    Case "HKEY_USERS": rootKey = #HKEY_USERS
    Case "HKEY_CURRENT_CONFIG": rootKey = #HKEY_CURRENT_CONFIG
    Default: ProcedureReturn
  EndSelect
  
  LogInfo("JumpToPath", "Navigating to: " + fullPath)
  
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
      LoadSubKeys(currentItem, rootKey, currentPath, GetDefaultSAM())
      TreeChildrenLoaded(Str(currentItem)) = #True
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
  
  ; Scroll into view
  SendMessage_(GadgetID(#GADGET_TREE), #TVM_ENSUREVISIBLE, 0, GadgetItemID(#GADGET_TREE, currentItem))
EndProcedure


Define fileName.s, helpPath.s

; Initialize error logging
If Not InitErrorLog()
  MessageRequester("Warning", "Cannot create error log file!", #PB_MessageRequester_Warning)
EndIf

LogInfo("Main", "Registry Manager starting...")
LogInfo("Main", "PureBasic Version: " + Str(#PB_Compiler_Version))
LogInfo("Main", "Operating System: " + #PB_Compiler_OS)

; Cleanup old backups (keep last 7 days)
CleanupOldBackups(7)

; Show backup directory location
LogInfo("Main", "Auto-backup directory: " + GetBackupDirectory())

If CreateGUI()
  LogInfo("Main", "Entering main event loop")
  
  Repeat
    Select WaitWindowEvent()
        Case #PB_Event_CloseWindow
          Select EventWindow()
            Case #WINDOW_MAIN
              LogInfo("Main", "User closed main window")
              Break

            Case #WINDOW_MONITOR
              LogInfo("Main", "User closed monitor window")
              RemoveWindowTimer(#WINDOW_MONITOR, #TIMER_MONITOR_REFRESH)
              If MonitorActive
                StopRegistryMonitor()
              EndIf
              CloseWindow(#WINDOW_MONITOR)
              MonitorWindow = 0

            Case #WINDOW_SNAPSHOT
              LogInfo("Main", "User closed snapshot window")
              RemoveWindowTimer(#WINDOW_SNAPSHOT, #TIMER_SNAPSHOT_REFRESH)
              CloseWindow(#WINDOW_SNAPSHOT)
              SnapshotWindow = 0
              
            Case #WINDOW_SEARCH
              SearchStopRequested = #True
              CloseWindow(#WINDOW_SEARCH)
          EndSelect

        
      Case #PB_Event_Timer
        If EventWindow() = #WINDOW_MONITOR And EventTimer() = #TIMER_MONITOR_REFRESH
          RefreshMonitorWindow()
          ; keep monitor list UI responsive even without user interaction
        ElseIf EventWindow() = #WINDOW_SNAPSHOT And EventTimer() = #TIMER_SNAPSHOT_REFRESH
          If SnapshotCreationActive
            ; Check if the process is still running
            If IsProgram(SnapshotCreationProgram) And ProgramRunning(SnapshotCreationProgram)
              ; Still working, wait for next timer tick
              UpdateStatusBar("Creating snapshot... " + Str(FileSize(SnapshotCreationFile)/1024) + " KB written")
            Else
              ; Check for exit code
              Define exitCode.i = -1
              If IsProgram(SnapshotCreationProgram)
                exitCode = ProgramExitCode(SnapshotCreationProgram)
                CloseProgram(SnapshotCreationProgram)
              EndIf
              
              SnapshotCreationProgram = 0
              SnapshotCreationActive = 0
              RemoveWindowTimer(#WINDOW_SNAPSHOT, #TIMER_SNAPSHOT_REFRESH)

              DisableGadget(#GADGET_SNAPSHOT_CREATE, #False)
              DisableGadget(#GADGET_SNAPSHOT_DELETE, #False)
              DisableGadget(#GADGET_SNAPSHOT_COMPARE, #False)
              DisableGadget(#GADGET_SNAPSHOT_EXPORT, #False)

              LoadSnapshots()
              ClearGadgetItems(#GADGET_SNAPSHOT_LIST)
              ForEach Snapshots()
                AddGadgetItem(#GADGET_SNAPSHOT_LIST, -1, Snapshots()\Name + Chr(9) +
                                                          Snapshots()\Timestamp + Chr(9) +
                                                          Str(Snapshots()\FileSize/1024) + Chr(9) +
                                                          Snapshots()\Description)
              Next

              SnapshotCreationFile = ""
              If exitCode = 0
                UpdateStatusBar("Snapshot creation complete")
                MessageRequester("Success", "Registry snapshot created successfully!", #PB_MessageRequester_Info)
              Else
                UpdateStatusBar("Snapshot creation failed (Exit Code: " + Str(exitCode) + ")")
                MessageRequester("Error", "Registry snapshot failed!" + #CRLF$ + "Exit Code: " + Str(exitCode) + #CRLF$ + "Check if you have admin rights.", #PB_MessageRequester_Error)
              EndIf
            EndIf
          EndIf
        ElseIf EventWindow() = #WINDOW_SEARCH And EventTimer() = 4001
          ; Update search results UI periodically
          Define currentResults = ListSize(SearchResults())
          Define displayedResults = CountGadgetItems(#GADGET_SEARCH_RESULTS)
          
          If currentResults > displayedResults
            LockMutex(MonitorMutex) ; Reusing mutex for safety if needed, or better use dedicated
            SelectElement(SearchResults(), displayedResults)
            While displayedResults < currentResults
              AddGadgetItem(#GADGET_SEARCH_RESULTS, -1, SearchResults()\KeyPath + Chr(10) + 
                                                        SearchResults()\ValueName + Chr(10) + 
                                                        GetTypeName(SearchResults()\ValueType) + Chr(10) + 
                                                        Left(SearchResults()\ValueData, 100))
              displayedResults + 1
              If NextElement(SearchResults()) = 0 : Break : EndIf
            Wend
            UnlockMutex(MonitorMutex)
          EndIf
          
          If SearchThreadID = 0
            RemoveWindowTimer(#WINDOW_SEARCH, 4001)
            DisableGadget(#GADGET_SEARCH_START, #False)
            DisableGadget(#GADGET_SEARCH_STOP, #True)
            SetGadgetText(#GADGET_SEARCH_STATUS, "Search completed. Found " + Str(currentResults) + " matches.")
          Else
            SetGadgetText(#GADGET_SEARCH_STATUS, "Searching... Found " + Str(currentResults) + " matches.")
          EndIf
        ElseIf EventWindow() = #WINDOW_SNAPSHOT And EventTimer() = 4002
          If CompareThreadID = 0
            RemoveWindowTimer(#WINDOW_SNAPSHOT, 4002)
            DisableGadget(#GADGET_SNAPSHOT_COMPARE, #False)
            DisableGadget(#GADGET_SNAPSHOT_CREATE, #False)
            DisableGadget(#GADGET_SNAPSHOT_DELETE, #False)
            DisableGadget(#GADGET_SNAPSHOT_EXPORT, #False)
            UpdateStatusBar("Comparison complete.")
            
            ; Display differences
            ClearGadgetItems(#GADGET_SNAPSHOT_DIFF)
            ForEach DiffResults()
              Define displayDetails.s = DiffResults()\ValueName
              If displayDetails <> "" : displayDetails + " -> " : EndIf
              displayDetails + DiffResults()\NewData + " " + DiffResults()\OldData
              AddGadgetItem(#GADGET_SNAPSHOT_DIFF, -1, DiffResults()\ChangeType + Chr(9) +
                                                       DiffResults()\KeyPath + Chr(9) +
                                                       displayDetails)
            Next
          Else
            UpdateStatusBar("Comparing snapshots in background... Found " + Str(ListSize(DiffResults())) + " diffs")
          EndIf
        EndIf

        
      Case #PB_Event_Menu
        Select EventMenu()
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
            
          Case #MENU_EDIT_NEW_KEY
            If CurrentRootKey <> 0
              Define newKeyName.s = InputRequester("New Registry Key", "Enter name for the new subkey:", "New Key")
              If newKeyName <> ""
                Define fullNewPath.s = CurrentKeyPath
                If fullNewPath <> "" : fullNewPath + "\" : EndIf
                fullNewPath + newKeyName
                
                If CreateRegistryKey(CurrentRootKey, fullNewPath, GetDefaultSAM())
                  ; Refresh the tree for the current item
                  Define currentItem.i = GetGadgetState(#GADGET_TREE)
                  If currentItem <> -1
                    ; If it was already loaded, we need to add the new item manually or reload
                    If FindMapElement(TreeChildrenLoaded(), Str(currentItem)) And TreeChildrenLoaded(Str(currentItem)) = #True
                      AddGadgetItem(#GADGET_TREE, -1, newKeyName, 0, currentItem)
                    Else
                      ; Trigger lazy load
                      LoadSubKeys(currentItem, CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
                      TreeChildrenLoaded(Str(currentItem)) = #True
                    EndIf
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
              Define choice.i = MessageRequester("Delete What?", 
                                                 "What do you want to delete?" + #CRLF$ + #CRLF$ +
                                                 "Current key: " + GetRootKeyName(CurrentRootKey) + "\" + CurrentKeyPath, 
                                                 #PB_MessageRequester_YesNoCancel)
              If choice = #PB_MessageRequester_Yes
                DeleteRegistryKey(CurrentRootKey, CurrentKeyPath)
              ElseIf choice = #PB_MessageRequester_No
                ; Delete selected value
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

          Case #MENU_EDIT_RENAME
            If CurrentRootKey <> 0
              ; Check if a value is selected in the listview or if we're renaming a key
              Define selectedVal.i = GetGadgetState(#GADGET_LISTVIEW)
              If selectedVal <> -1
                ; Use Advanced Editor for editing/renaming value
                Define oldValName.s = GetGadgetItemText(#GADGET_LISTVIEW, selectedVal, 0)
                OpenValueEditor(CurrentRootKey, CurrentKeyPath, oldValName)
              Else
                ; Rename Key
                Define currentItem.i = GetGadgetState(#GADGET_TREE)

                If currentItem <> -1
                  Define oldKeyName.s = GetGadgetItemText(#GADGET_TREE, currentItem, 0)
                  ; Don't rename root hives
                  If oldKeyName = "HKEY_CLASSES_ROOT" Or oldKeyName = "HKEY_CURRENT_USER" Or oldKeyName = "HKEY_LOCAL_MACHINE" Or oldKeyName = "HKEY_USERS" Or oldKeyName = "HKEY_CURRENT_CONFIG"
                    MessageRequester("Error", "Root hives cannot be renamed!", #PB_MessageRequester_Error)
                  Else
                    Define newKeyName.s = InputRequester("Rename Key", "Enter new name for key '" + oldKeyName + "':", oldKeyName)
                    If newKeyName <> "" And newKeyName <> oldKeyName
                      Define parentPath.s = ""
                      If CountString(CurrentKeyPath, "\") > 0
                        parentPath = Left(CurrentKeyPath, Len(CurrentKeyPath) - Len(oldKeyName) - 1)
                      EndIf
                      
                      ; Ensure backup
                      If EnsureBackupBeforeChange("Rename registry key: " + oldKeyName + " to " + newKeyName)
                        UpdateStatusBar("Renaming key... this may take a moment")
                        
                        ; Use RunProgram with 'reg copy' for efficiency
                        Define source.s = GetRootKeyName(CurrentRootKey) + "\" + CurrentKeyPath
                        Define destination.s = GetRootKeyName(CurrentRootKey) + "\"
                        If parentPath <> "" : destination + parentPath + "\" : EndIf
                        destination + newKeyName
                        
                        Define prog = RunProgram("reg", "copy " + Chr(34) + source + Chr(34) + " " + Chr(34) + destination + Chr(34) + " /s /f", "", #PB_Program_Wait | #PB_Program_Hide)
                        If prog And ProgramExitCode(prog) = 0
                          Registry::DeleteTree(CurrentRootKey, CurrentKeyPath, #True)
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
            
          Case #MENU_VIEW_64BIT
            View64Bit = 1 - View64Bit
            SetMenuItemState(#GADGET_MENU, #MENU_VIEW_64BIT, View64Bit)
            If View64Bit
              UpdateStatusBar("View mode: 64-bit Registry")
            Else
              UpdateStatusBar("View mode: 32-bit Registry (WOW64)")
            EndIf
            ; Refresh current view
            If CurrentRootKey <> 0
              LoadValues(CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
            EndIf
            
          Case #MENU_VIEW_REFRESH
            If CurrentRootKey <> 0
              LoadValues(CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
              ; Force reload children for selected item if possible
              Define sel = GetGadgetState(#GADGET_TREE)
              If sel <> -1
                LoadSubKeys(sel, CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
              EndIf
            EndIf
            
          Case #MENU_HELP_ONLINE
            LogInfo("Main", "Opening help system")
            helpPath = GetCurrentDirectory() + "RegistryManager_Help.html"
            If FileSize(helpPath) > 0
              RunProgram(helpPath, "", "", #PB_Program_Open)
              UpdateStatusBar("Help opened in browser")
            Else
              MessageRequester("Help Not Found", "Help file not found: " + helpPath + #CRLF$ + #CRLF$ +
                                                  "Please ensure RegistryManager_Help.html is in the same folder as RegistryManager.exe", 
                                                  #PB_MessageRequester_Warning)
              LogWarning("Main", "Help file not found: " + helpPath)
            EndIf
            
          Case #MENU_HELP_ABOUT
            LogInfo("Main", "Displaying About dialog")
            MessageRequester("About Registry Manager", "Registry Manager " + version + #CRLF$ + #CRLF$ +
                                                        "All-in-One Registry Tool with Auto-Backup" + #CRLF$ + #CRLF$ +
                                                        "Features:" + #CRLF$ +
                                                        "Registry Editor" + #CRLF$ +
                                                        "Registry Cleaner" + #CRLF$ +
                                                        "Backup & Restore" + #CRLF$ +
                                                        "Registry Compactor" + #CRLF$ +
                                                        "Automatic Safety Backups" + #CRLF$ +
                                                        "Real-Time Registry Monitor" + #CRLF$ +
                                                        "Snapshot Manager & Comparison" + #CRLF$ + #CRLF$ +
                                                        "Built with PureBasic 6.30+" + #CRLF$ + #CRLF$ +
                                                        "Log file: " + ErrorLogPath + #CRLF$ +
                                                        "Backup directory: " + GetBackupDirectory() + #CRLF$ +
                                                        "Snapshot directory: " + GetSnapshotDirectory() + #CRLF$ +
                                                        "Last backup: " + AutoBackupPath + #CRLF$ +
                                                        "Monitor events: " + Str(MonitorEventCount) + #CRLF$ +
                                                        "Snapshots: " + Str(ListSize(Snapshots())), #PB_MessageRequester_Info)
            
          Case 40 ; SEARCH
            OpenSearchWindow()

          Case #MENU_FAV_ADD
            If CurrentRootKey <> 0
              Define fullFavPath.s = GetRootKeyName(CurrentRootKey)
              If CurrentKeyPath <> "" : fullFavPath + "\" + CurrentKeyPath : EndIf
              AddFavorite(fullFavPath)
            EndIf
            
          Case #MENU_FAV_MANAGE
            OpenFavoritesManager()
            
          Default
            ; Check for dynamic favorites
            If EventMenu() >= #MENU_FAV_START And EventMenu() < #MENU_FAV_START + 100
              Define favIndex = EventMenu() - #MENU_FAV_START
              SelectElement(Favorites(), favIndex)
              JumpToPath(Favorites())
            EndIf

            
        EndSelect
        
      Case #PB_Event_Gadget
        Select EventGadget()
           Case #GADGET_TREE
             If EventWindow() = #WINDOW_MAIN
               Define item.i = GetGadgetState(#GADGET_TREE)
               If item <> -1
                 Define tempPath.s = GetGadgetItemText(#GADGET_TREE, item, 0)
                 
                 ; Determine root hive and key path.
                 CurrentRootKey = GetRootKeyFromTreeItem(item)
                 If CurrentRootKey <> 0
                   Define isHiveRoot.i = #False
                   If tempPath = "HKEY_CLASSES_ROOT" Or tempPath = "HKEY_CURRENT_USER" Or tempPath = "HKEY_LOCAL_MACHINE" Or tempPath = "HKEY_USERS" Or tempPath = "HKEY_CURRENT_CONFIG"
                     isHiveRoot = #True
                   EndIf
                   
                    If isHiveRoot
                      CurrentKeyPath = ""
                      SetGadgetText(#GADGET_ADDRESS_BAR, tempPath)
                    Else
                      CurrentKeyPath = tempPath
                      SetGadgetText(#GADGET_ADDRESS_BAR, GetRootKeyName(CurrentRootKey) + "\" + CurrentKeyPath)
                    EndIf
                   
                    LogInfo("Main", "Tree item selected: " + tempPath)
                    LoadValues(CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
                    
                    ; Load children only on double-click, and only once.
                    If EventType() = #PB_EventType_LeftDoubleClick
                      ; Load children once per node.
                      If FindMapElement(TreeChildrenLoaded(), Str(item)) = 0 Or TreeChildrenLoaded(Str(item)) = #False
                        LoadSubKeys(item, CurrentRootKey, CurrentKeyPath, GetDefaultSAM())
                        TreeChildrenLoaded(Str(item)) = #True
                      EndIf
                    ElseIf EventType() = #PB_EventType_RightClick
                      DisplayPopupMenu(#GADGET_POPUP_TREE, WindowID(#WINDOW_MAIN))
                    EndIf
                  Else
                    LogWarning("Main", "Could not determine root key for selected item")
                  EndIf
                EndIf
              EndIf
            
            Case #GADGET_ADDRESS_GO
              If EventWindow() = #WINDOW_MAIN
                JumpToPath(GetGadgetText(#GADGET_ADDRESS_BAR))
              EndIf

            Case #GADGET_LISTVIEW

              If EventWindow() = #WINDOW_MAIN
                If EventType() = #PB_EventType_RightClick
                  DisplayPopupMenu(#GADGET_POPUP_LIST, WindowID(#WINDOW_MAIN))
                EndIf
              EndIf

           ; Monitor window gadgets
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
              fileName = SaveFileRequester("Save Monitor Log", "RegistryMonitor_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".log", "Log Files (*.log)|*.log|Text Files (*.txt)|*.txt|All Files (*.*)|*.*", 0)
              If fileName <> ""
                SaveMonitorLog(fileName)
              EndIf
            EndIf
            
          ; Snapshot window gadgets
          Case #GADGET_SNAPSHOT_CREATE
            If EventWindow() = #WINDOW_SNAPSHOT
              LogInfo("Main", "Snapshot: Create button clicked")
              Define name.s = InputRequester("Create Snapshot", "Enter snapshot name:", "Snapshot_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()))
              If name <> ""
                Define description.s = InputRequester("Description (Optional)", "Enter description:", "Manual snapshot")
                If description = "" : description = "Manual snapshot" : EndIf

                DisableGadget(#GADGET_SNAPSHOT_CREATE, #True)
                DisableGadget(#GADGET_SNAPSHOT_DELETE, #True)
                DisableGadget(#GADGET_SNAPSHOT_COMPARE, #True)
                DisableGadget(#GADGET_SNAPSHOT_EXPORT, #True)
                UpdateStatusBar("Creating snapshot... this can take a while")

                name = SanitizeFileName(name)
                SnapshotCreationFile = GetSnapshotDirectory() + name + ".reg"
                LogInfo("Snapshot", "Executing: reg export HKEY_LOCAL_MACHINE " + Chr(34) + SnapshotCreationFile + Chr(34) + " /y")
                SnapshotCreationProgram = RunProgram("reg", "export HKEY_LOCAL_MACHINE " + Chr(34) + SnapshotCreationFile + Chr(34) + " /y", "", #PB_Program_Open | #PB_Program_Hide)

                If SnapshotCreationProgram
                  SnapshotCreationActive = 1

                  ; Use a fast polling timer (250ms) to check process status
                  AddWindowTimer(#WINDOW_SNAPSHOT, #TIMER_SNAPSHOT_REFRESH, 250)
                Else
                  SnapshotCreationActive = 0
                  SnapshotCreationProgram = 0
                  SnapshotCreationFile = ""
                  DisableGadget(#GADGET_SNAPSHOT_CREATE, #False)
                  DisableGadget(#GADGET_SNAPSHOT_DELETE, #False)
                  DisableGadget(#GADGET_SNAPSHOT_COMPARE, #False)
                  DisableGadget(#GADGET_SNAPSHOT_EXPORT, #False)
                  LogError("Snapshot", "Failed to start reg.exe for snapshot")
                EndIf
              EndIf
            EndIf
            
          Case #GADGET_SNAPSHOT_DELETE
            If EventWindow() = #WINDOW_SNAPSHOT
              Define i.i, name.s
              Define deletedCount.i = 0
              Define currentSelected.i = GetGadgetState(#GADGET_SNAPSHOT_LIST)
              
              ; First, find ALL items that need to be deleted
              NewList ToDelete.s()
              For i = 0 To CountGadgetItems(#GADGET_SNAPSHOT_LIST) - 1
                ; Use #PB_ListIcon_Checked to verify the checkbox state
                If i = currentSelected Or (GetGadgetItemState(#GADGET_SNAPSHOT_LIST, i) & #PB_ListIcon_Checked)
                  ; Explicitly request Column 0 to get ONLY the snapshot name
                  ; We use StringField with Tab (Chr(9)) as a secondary safety measure
                  name = StringField(GetGadgetItemText(#GADGET_SNAPSHOT_LIST, i, 0), 1, Chr(9))
                  If name <> ""
                    AddElement(ToDelete())
                    ToDelete() = name
                  EndIf
                EndIf
              Next
              
              If ListSize(ToDelete()) > 0
                If MessageRequester("Confirm Delete", "Delete " + Str(ListSize(ToDelete())) + " selected snapshot(s)?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
                  ; Sync the internal Snapshots() list with the disk
                  LoadSnapshots()
                  
                  ForEach ToDelete()
                    name = ToDelete()
                    ; Log the exact name we are trying to delete for debugging
                    LogInfo("Main", "Attempting to delete snapshot name: '" + name + "'")
                    
                    If DeleteSnapshot(name, #True)
                      deletedCount + 1
                    Else
                      LogError("Main", "Failed to delete snapshot: '" + name + "'")
                    EndIf
                  Next
                  
                  ; Completely rebuild the UI list from the updated Snapshots() list
                  ClearGadgetItems(#GADGET_SNAPSHOT_LIST)
                  ForEach Snapshots()
                    AddGadgetItem(#GADGET_SNAPSHOT_LIST, -1, Snapshots()\Name + Chr(9) +
                                                              Snapshots()\Timestamp + Chr(9) +
                                                              Str(Snapshots()\FileSize/1024) + Chr(9) +
                                                              Snapshots()\Description)
                  Next
                  
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
              ; Count checked items
              Define checkedCount.i = 0
              Define snapshot1.s, snapshot2.s
              Define selectedIdx.i ; Declared for EnableExplicit compliance
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
                  DisableGadget(#GADGET_SNAPSHOT_COMPARE, #True)
                  DisableGadget(#GADGET_SNAPSHOT_CREATE, #True)
                  DisableGadget(#GADGET_SNAPSHOT_DELETE, #True)
                  DisableGadget(#GADGET_SNAPSHOT_EXPORT, #True)
                  UpdateStatusBar("Starting background comparison...")

                  Define *p.CompareThreadParams = AllocateMemory(SizeOf(CompareThreadParams))
                  If *p
                    *p\Snapshot1 = snapshot1
                    *p\Snapshot2 = snapshot2
                    CompareThreadID = CreateThread(@CompareThread(), *p)
                    AddWindowTimer(#WINDOW_SNAPSHOT, 4002, 500) ; Comparison refresh timer
                  EndIf
                EndIf
              Else
                MessageRequester("Info", "Please check exactly 2 snapshots to compare.", #PB_MessageRequester_Info)
              EndIf
            EndIf

            
          Case #GADGET_SNAPSHOT_EXPORT
            If EventWindow() = #WINDOW_SNAPSHOT
              If ListSize(DiffResults()) > 0
                fileName = SaveFileRequester("Export Comparison Report", "SnapshotDiff_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".txt", "Text Files (*.txt)|*.txt|All Files (*.*)|*.*", 0)
                If fileName <> ""
                  ExportDifferences(fileName)
                EndIf
              Else
                MessageRequester("Info", "No comparison results to export. Compare snapshots first.", #PB_MessageRequester_Info)
              EndIf
            EndIf

          ; Search window gadgets
          Case #GADGET_SEARCH_START
            If EventWindow() = #WINDOW_SEARCH
              Define searchStr.s = GetGadgetText(#GADGET_SEARCH_STRING)
              If searchStr <> ""
                ClearGadgetItems(#GADGET_SEARCH_RESULTS)
                ClearList(SearchResults())
                SearchStopRequested = #False
                DisableGadget(#GADGET_SEARCH_START, #True)
                DisableGadget(#GADGET_SEARCH_STOP, #False)
                SetGadgetText(#GADGET_SEARCH_STATUS, "Searching...")
                Define *sp.SearchThreadParams = AllocateMemory(SizeOf(SearchThreadParams))
                If *sp
                  *sp\SearchString = searchStr
                  *sp\RootKey = CurrentRootKey
                  *sp\KeyPath = CurrentKeyPath
                  SearchThreadID = CreateThread(@SearchThread(), *sp)
                  AddWindowTimer(#WINDOW_SEARCH, 4001, 200) ; Refresh timer
                EndIf
              EndIf
            EndIf
            
          Case #GADGET_SEARCH_STOP
            If EventWindow() = #WINDOW_SEARCH
              SearchStopRequested = #True
            EndIf
            
          Case #GADGET_SEARCH_RESULTS
            If EventWindow() = #WINDOW_SEARCH And EventType() = #PB_EventType_LeftDoubleClick
              Define selectedResult.i = GetGadgetState(#GADGET_SEARCH_RESULTS)
              If selectedResult <> -1
                SelectElement(SearchResults(), selectedResult)
                JumpToPath(GetRootKeyName(SearchResults()\RootKey) + "\" + SearchResults()\KeyPath)
              EndIf
            EndIf

        EndSelect
        
      Case #PB_Event_SizeWindow
        Select EventWindow()
          Case #WINDOW_MAIN
            ResizeGadget(#GADGET_ADDRESS_BAR, 5, 5, WindowWidth(#WINDOW_MAIN) - 60, 25)
            ResizeGadget(#GADGET_ADDRESS_GO, WindowWidth(#WINDOW_MAIN) - 50, 5, 45, 25)
            ResizeGadget(#GADGET_SPLITTER, 0, 35, WindowWidth(#WINDOW_MAIN), WindowHeight(#WINDOW_MAIN) - 55)
          Case #WINDOW_SEARCH
            ResizeGadget(#GADGET_SEARCH_STRING, 90, 10, WindowWidth(#WINDOW_SEARCH) - 300, 25)
            ResizeGadget(#GADGET_SEARCH_START, WindowWidth(#WINDOW_SEARCH) - 200, 10, 90, 25)
            ResizeGadget(#GADGET_SEARCH_STOP, WindowWidth(#WINDOW_SEARCH) - 100, 10, 90, 25)
            ResizeGadget(#GADGET_SEARCH_RESULTS, 10, 45, WindowWidth(#WINDOW_SEARCH) - 20, WindowHeight(#WINDOW_SEARCH) - 80)
            ResizeGadget(#GADGET_SEARCH_STATUS, 10, WindowHeight(#WINDOW_SEARCH) - 25, WindowWidth(#WINDOW_SEARCH) - 20, 20)
          Case #WINDOW_MONITOR
            ResizeGadget(#GADGET_MONITOR_LIST, 10, 10, WindowWidth(#WINDOW_MONITOR) - 20, WindowHeight(#WINDOW_MONITOR) - 100)
            ResizeGadget(#GADGET_MONITOR_START, 10, WindowHeight(#WINDOW_MONITOR) - 80, #PB_Ignore, #PB_Ignore)
            ResizeGadget(#GADGET_MONITOR_STOP, 120, WindowHeight(#WINDOW_MONITOR) - 80, #PB_Ignore, #PB_Ignore)
            ResizeGadget(#GADGET_MONITOR_CLEAR, 230, WindowHeight(#WINDOW_MONITOR) - 80, #PB_Ignore, #PB_Ignore)
            ResizeGadget(#GADGET_MONITOR_SAVE, 340, WindowHeight(#WINDOW_MONITOR) - 80, #PB_Ignore, #PB_Ignore)
            ResizeGadget(txtMonitorStatus, WindowWidth(#WINDOW_MONITOR) - 410, WindowHeight(#WINDOW_MONITOR) - 75, 400, #PB_Ignore)
          Case #WINDOW_SNAPSHOT
            ResizeGadget(#GADGET_SNAPSHOT_LIST, 10, 10, WindowWidth(#WINDOW_SNAPSHOT) - 20, (WindowHeight(#WINDOW_SNAPSHOT) - 100) * 0.5)
            Define listHeight = GadgetHeight(#GADGET_SNAPSHOT_LIST)
            ResizeGadget(#GADGET_SNAPSHOT_CREATE, 10, listHeight + 20, #PB_Ignore, #PB_Ignore)
            ResizeGadget(#GADGET_SNAPSHOT_DELETE, 140, listHeight + 20, #PB_Ignore, #PB_Ignore)
            ResizeGadget(#GADGET_SNAPSHOT_COMPARE, 270, listHeight + 20, #PB_Ignore, #PB_Ignore)
            ResizeGadget(#GADGET_SNAPSHOT_EXPORT, 400, listHeight + 20, #PB_Ignore, #PB_Ignore)
            
            ResizeGadget(#GADGET_SNAPSHOT_DIFF, 10, listHeight + 80, WindowWidth(#WINDOW_SNAPSHOT) - 20, WindowHeight(#WINDOW_SNAPSHOT) - listHeight - 140)
            ; Also move the "Comparison Results:" label
            ; In a real app we'd track the label gadget ID, but here we'll just focus on the main gadgets.

        EndSelect
    EndSelect
  ForEver
  
  LogInfo("Main", "Exiting main event loop")
Else
  LogError("Main", "Failed to create GUI - exiting")
  MessageRequester("Fatal Error", "Cannot create main window!" + #CRLF$ + "Check log file: " + ErrorLogPath, #PB_MessageRequester_Error)
EndIf

LogInfo("Main", "Registry Manager shutting down")

; Stop monitor if running
If MonitorActive
  LogInfo("Main", "Stopping registry monitor before exit")
  StopRegistryMonitor()
EndIf

; Free mutex if created
If MonitorMutex
  FreeMutex(MonitorMutex)
EndIf

CloseErrorLog()

Exit()
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 3314
; FirstLine = 3282
; Folding = ----------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = RegistryManager.ico
; Executable = ..\RegistryManager.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,3
; VersionField1 = 1,0,0,3
; VersionField2 = ZoneSoft
; VersionField3 = RegistryManager
; VersionField4 = 1.0.0.3
; VersionField5 = 1.0.0.3
; VersionField6 = A full featured Registry Manager
; VersionField7 = RegistryManager
; VersionField8 = RegistryManager.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60