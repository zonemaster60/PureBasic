; Core shared definitions, globals, and cross-feature helpers

;- Windows API Imports

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

Import "uxtheme.lib"
  SetWindowTheme(hwnd.i, pszSubAppName.p-unicode, pszSubIdList.i)
EndImport

;- Core Types

#APP_NAME = "RegistryManager"

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
  ValueName.s
  ChangeType.s
  OldData.s
  NewData.s
  Details.s
EndStructure

Structure BackupThreadParams
  FileName.s
  Reason.s
  IsAuto.i
EndStructure

Structure LoadValuesParams
  RootKey.i
  KeyPath.s
  SAM.l
EndStructure

Structure LoadValuesResult
  Count.i
  Error.l
  ErrorStr.s
  List Values.RegValueInfo()
EndStructure

Structure SnapshotInfo
  Name.s
  Timestamp.s
  FilePath.s
  Description.s
  FileSize.q
EndStructure

Structure CleanerParams
  MuiCache.i
  InstallerRefs.i
  FileAssoc.i
  ObsoleteSw.i
  Shortcuts.i
  EmptyKeys.i
  IsCleaning.i
  Wow64.i
  WindowID.i
  EditorID.i
  BtnScan.i
  BtnClean.i
  BtnClose.i
EndStructure

Structure CompareThreadParams
  Snapshot1.s
  Snapshot2.s
EndStructure

Structure AsyncStatusEvent
  Text.s
EndStructure

Structure AsyncMessageEvent
  Title.s
  Text.s
  Flags.i
EndStructure

Structure SnapshotThreadParams
  Name.s
  Description.s
EndStructure

Structure SnapshotCreationResult
  Success.i
  Name.s
  Description.s
  ErrorText.s
EndStructure

Structure LoadKeysParams
  ParentItem.i
  RootKey.i
  KeyPath.s
  SAM.l
EndStructure

Structure LoadKeysThreadResult
  ParentItem.i
  List SubKeys.s()
  Error.l
  ErrorStr.s
EndStructure

Structure SearchThreadParams
  SearchString.s
  RootKey.i
  KeyPath.s
  SearchKeys.i
  SearchValues.i
  SearchData.i
EndStructure

Structure SearchResult
  RootKey.i
  KeyPath.s
  ValueName.s
  ValueType.i
  ValueData.s
EndStructure

;- Global State

Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

Global AppVersion.s = "v1.0.1.4"
Global MonitorActive.i = #False
Global MonitorEventCount.i = 0
Global MonitorMutex.i = 0
Global MonitorWindow.i = 0
Global MonitorLastShownCount.i = 0
Global LogFile.i = 0
Global LogMutex.i = 0
Global ErrorLogPath.s = ""
Global AutoBackupPath.s = ""
Global LastBackupTime.i = 0
Global View64Bit.i = #True
Global CurrentRootKey.i = 0
Global CurrentKeyPath.s = ""
Global SnapshotWindow.i = 0
Global SnapshotCreationActive.i = #False
Global SnapshotDirectory.s = ""
Global BackupProgram.i = 0
Global BackupScriptFile.s = ""
Global BackupOutputFile.s = ""
Global BackupOutputFolder.s = ""
Global BackupReason.s = ""
Global BackupIsAuto.i = #False
Global BackupStatusFile.s = ""
Global BackupCurrentStage.s = ""
Global BackupCurrentMode.s = ""
Global LoadValuesThreadID.i = 0
Global StressTestActive.i = #False
Global StressThreadID.i = 0

Global NewList Favorites.s()
Global NewList MonitorEvents.RegMonitorEvent()
Global NewList DiffResults.RegMonitorEvent()
Global DiffResultsMutex.i = 0
Global NewList Snapshots.SnapshotInfo()
Global NewList RegValues.RegValueInfo()
Global NewMap TreeChildrenLoaded.i()
Global NewList PendingMonitorEvents.RegMonitorEvent()
Global PendingEventsMutex.i = 0
Global SearchResultsMutex.i = 0
Global NewList SearchResults.SearchResult()
Global SearchThreadID.i = 0
Global SearchStopRequested.i = #False
Global CleanerThreadID.i = 0
Global CleanerStopRequested.i = #False
Global MonitorStatusTextGadget.i = 0
Global CompareThreadID.i = 0
Global CompareAddedCount.i = 0
Global CompareRemovedCount.i = 0
Global CompareModifiedCount.i = 0
Global MonitorThread1.i = 0
Global MonitorThread2.i = 0
Global MonitorThread3.i = 0
Global MonitorThread4.i = 0
Global MonitorThread5.i = 0
Global IsUpdatingTree.i = #False
Global LastSelectedItem.i = -1
Global NewMap ActiveLoadThreads.i()
Global LoadKeysMutex.i = 0
Global LoadValuesMutex.i = 0

;- App Constants

#AUTO_BACKUP_INTERVAL = 3600000
#BACKUP_DIR_NAME = "Backups"
#SNAPSHOT_DIR_NAME = "Snapshots"

#WINDOW_MAIN = 0
#WINDOW_MONITOR = 1
#WINDOW_SNAPSHOT = 2
#WINDOW_CLEANER = 3
#WINDOW_SEARCH = 4

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
#GADGET_VALUE_EDITOR_HEX_GRID = 407
#GADGET_VALUE_EDITOR_HEX_SAVE = 408
#GADGET_VALUE_EDITOR_HEX_CANCEL = 409
#GADGET_VALUE_EDITOR_HEX_INPUT = 410
#GADGET_SEARCH_STRING = 300
#GADGET_SEARCH_START = 301
#GADGET_SEARCH_STOP = 302
#GADGET_SEARCH_RESULTS = 303
#GADGET_SEARCH_KEYS = 304
#GADGET_SEARCH_VALUES = 305
#GADGET_SEARCH_DATA = 306
#GADGET_SEARCH_STATUS = 307

#EVENT_LOAD_COMPLETE = #PB_Event_FirstCustomValue + 1
#EVENT_LOAD_VALUES_COMPLETE = #PB_Event_FirstCustomValue + 2
#EVENT_EXPORT_COMPLETE = #PB_Event_FirstCustomValue + 3
#EVENT_COMPARE_COMPLETE = #PB_Event_FirstCustomValue + 4
#EVENT_SNAPSHOT_CREATED = #PB_Event_FirstCustomValue + 5
#EVENT_CLEANER_MSG = #PB_Event_FirstCustomValue + 6
#EVENT_CLEANER_DONE = #PB_Event_FirstCustomValue + 7
#EVENT_ASYNC_STATUS = #PB_Event_FirstCustomValue + 8
#EVENT_ASYNC_MESSAGE = #PB_Event_FirstCustomValue + 9

#MENU_FILE_EXPORT = 1
#MENU_FILE_IMPORT = 2
#MENU_FILE_EXIT = 3
#MENU_EDIT_NEW_KEY = 10
#MENU_EDIT_NEW_VALUE = 11
#MENU_EDIT_DELETE = 12
#MENU_EDIT_RENAME = 13
#MENU_EDIT_COPY_PATH = 14
#MENU_EDIT_PERMISSIONS = 15
#MENU_TOOLS_CLEANER = 20
#MENU_TOOLS_BACKUP = 21
#MENU_TOOLS_RESTORE = 22
#MENU_TOOLS_COMPACT = 23
#MENU_TOOLS_MONITOR = 24
#MENU_TOOLS_SNAPSHOT = 25
#MENU_TOOLS_HEX_EXTERNAL = 26
#MENU_HELP_ONLINE = 30
#MENU_HELP_ABOUT = 31
#MENU_DEBUG_STRESS = 32
#MENU_VIEW_64BIT = 40
#MENU_VIEW_REFRESH = 41
#MENU_FAV_ADD = 50
#MENU_FAV_MANAGE = 51
#MENU_FAV_START = 1000

#REG_NOTIFY_CHANGE_NAME = $1
#REG_NOTIFY_CHANGE_ATTRIBUTES = $2
#REG_NOTIFY_CHANGE_LAST_SET = $4
#REG_NOTIFY_CHANGE_SECURITY = $8
#REG_NOTIFY_THREAD_AGNOSTIC = $10000000

#MONITOR_THREAD_ID = 1
#TIMER_MONITOR_REFRESH = 1001
#TIMER_BACKUP_REFRESH = 1002
#MONITOR_REFRESH_INTERVAL = 200

#ICON_STRING = 0
#ICON_BINARY = 1
#ICON_NUMERIC = 2

;- Cross-Feature Declarations

Declare LogInfo(location.s, infoMsg.s)
Declare LogError(location.s, errorMsg.s, errorCode.i = 0)
Declare LogWarning(location.s, warnMsg.s)
Declare UpdateStatusBar(text.s)
Declare BackupRegistry(fileName.s)
Declare BackupCurrentKey(rootKey.i, keyPath.s, fileName.s)
Declare CleanupOldBackups(daysToKeep.i = 7)
Declare JumpToPath(fullPath.s)
Declare.s GetRootKeyName(rootKey.i)
Declare.s GetSnapshotDirectory()
Declare LoadFavorites()
Declare SaveFavorites()
Declare.i CompareSnapshots(snapshot1.s, snapshot2.s)
Declare.i WriteRegistryValue(rootKey.i, keyPath.s, valueName.s, value.s, valueType.i, sam.l = #KEY_ALL_ACCESS)
Declare.i LoadValues(rootKey.i, keyPath.s, sam.l = 0)
Declare.l GetDefaultSAM()
Declare.i LoadSubKeys(parentItem.i, rootKey.i, keyPath.s, sam.l = 0)
Declare RefreshMonitorWindow()
Declare StartRegistryMonitor()
Declare StopRegistryMonitor()
Declare CloseErrorLog()
Declare.i Exit()
Declare.i GetRegistryWow64Flag(sam.l = 0)
Declare.i ExportRegistryHives(fileName.s)
Declare PostAsyncStatus(text.s)
Declare PostAsyncMessage(title.s, text.s, flags.i)
Declare SnapshotThread(param.i)
Declare.i GetRootKeyFromTreeItem(item.i)
Declare.i AddSnapshotDiff(changeType.s, keyPath.s, valueName.s = "", oldData.s = "", newData.s = "")
Declare.i FindRegEntrySeparator(line.s)
Declare LoadRegSnapshotIntoMap(filePath.s, Map target.s())
Declare RefreshSnapshotList()
Declare SetSnapshotControlsEnabled(enabled.i)
Declare UpdateSearchStatusLabel(active.i)
Declare AddMonitorEvent(rootKey.s, keyPath.s, changeType.s, details.s = "")
Declare CompareThread(param.i)
Declare HandleCloseWindowEvent()
Declare HandleTimerEvent()
Declare HandleCustomEvent(eventID.i)
Declare HandleMenuEvent(menuID.i)
Declare HandleGadgetEvent(gadgetID.i)
Declare HandleSizeWindowEvent()
Declare HandleFileMenu(menuID.i)
Declare HandleEditMenu(menuID.i)
Declare HandleToolsMenu(menuID.i)
Declare HandleViewMenu(menuID.i)
Declare HandleHelpMenu(menuID.i)
Declare HandleFavoritesMenu(menuID.i)
Declare HandleMainWindowGadget(gadgetID.i)
Declare HandleMonitorWindowGadget(gadgetID.i)
Declare HandleSnapshotWindowGadget(gadgetID.i)
Declare HandleSearchWindowGadget(gadgetID.i)
Declare.s EscapePowerShellLiteral(text.s)
Declare.i StartBackupProcess(fileName.s, reason.s, isAuto.i, mode.s = "full", rootKey.i = 0, keyPath.s = "")

;- Logging, App Lifecycle, and Shared Helpers

Procedure.i InitErrorLog()
  ErrorLogPath = AppPath + "RegistryManager.log"
  If Not LogMutex
    LogMutex = CreateMutex()
  EndIf
  LogFile = OpenFile(#PB_Any, ErrorLogPath, #PB_File_Append | #PB_File_SharedRead)
  If LogFile
    LockMutex(LogMutex)
    WriteStringN(LogFile, "--- Log Session Started: " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()) + " ---")
    UnlockMutex(LogMutex)
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Procedure.i Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    If StressTestActive
      LogInfo("Exit", "Stopping active Stress Test before shutdown")
      StressTestActive = #False
      If StressThreadID And IsThread(StressThreadID)
        WaitThread(StressThreadID, 2000)
      EndIf
    EndIf

    If MonitorActive
      StopRegistryMonitor()
    EndIf

    If MonitorMutex
      FreeMutex(MonitorMutex)
      MonitorMutex = 0
    EndIf

    CloseErrorLog()

    If hMutex
      CloseHandle_(hMutex)
      hMutex = 0
    EndIf

    End
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure SnapshotThread(param.i)
  Protected *p.SnapshotThreadParams = param
  Protected *res.SnapshotCreationResult
  Protected snapshotFile.s

  If *p = 0 : ProcedureReturn : EndIf

  *res = AllocateStructure(SnapshotCreationResult)
  If *res = 0
    FreeStructure(*p)
    ProcedureReturn
  EndIf

  *res\Name = *p\Name
  *res\Description = *p\Description
  snapshotFile = GetSnapshotDirectory() + *p\Name + ".reg"

  LogInfo("SnapshotThread", "Creating snapshot: " + snapshotFile)
  If ExportRegistryHives(snapshotFile)
    *res\Success = #True
  Else
    *res\Success = #False
    *res\ErrorText = "Failed to create registry snapshot file."
  EndIf

  FreeStructure(*p)
  PostEvent(#EVENT_SNAPSHOT_CREATED, #WINDOW_MAIN, 0, 0, *res)
EndProcedure

Procedure CompareThread(param.i)
  Protected *p.CompareThreadParams = param
  If *p = 0 : ProcedureReturn : EndIf

  Protected s1.s = *p\Snapshot1
  Protected s2.s = *p\Snapshot2
  FreeStructure(*p)

  LogInfo("CompareThread", "Starting comparison in background: " + s1 + " vs " + s2)
  CompareSnapshots(s1, s2)

  CompareThreadID = 0
  PostEvent(#EVENT_COMPARE_COMPLETE, #WINDOW_SNAPSHOT, 0, 0, 0)
  LogInfo("CompareThread", "Comparison thread finished")
EndProcedure

Procedure RefreshMonitorWindow()
  If Not IsWindow(#WINDOW_MONITOR) : ProcedureReturn : EndIf
  If Not IsGadget(#GADGET_MONITOR_LIST) : ProcedureReturn : EndIf

  If MonitorStatusTextGadget And IsGadget(MonitorStatusTextGadget)
    Protected statusText.s
    If MonitorActive : statusText = "Running" : Else : statusText = "Stopped" : EndIf
    SetGadgetText(MonitorStatusTextGadget, "Events: " + Str(MonitorEventCount) + " | Status: " + statusText)
  EndIf

  If Not PendingEventsMutex : PendingEventsMutex = CreateMutex() : EndIf

  LockMutex(PendingEventsMutex)
  If ListSize(PendingMonitorEvents()) > 0
    SendMessage_(GadgetID(#GADGET_MONITOR_LIST), #WM_SETREDRAW, #False, 0)

    ForEach PendingMonitorEvents()
      AddGadgetItem(#GADGET_MONITOR_LIST, -1, PendingMonitorEvents()\Timestamp + Chr(9) + PendingMonitorEvents()\RootKey + Chr(9) + PendingMonitorEvents()\KeyPath + Chr(9) + PendingMonitorEvents()\ChangeType + Chr(9) + PendingMonitorEvents()\Details)

      If Not MonitorMutex : MonitorMutex = CreateMutex() : EndIf
      LockMutex(MonitorMutex)
      AddElement(MonitorEvents())
      MonitorEvents() = PendingMonitorEvents()
      MonitorEventCount + 1
      UnlockMutex(MonitorMutex)

      If CountGadgetItems(#GADGET_MONITOR_LIST) > 5000
        RemoveGadgetItem(#GADGET_MONITOR_LIST, 0)
      EndIf
    Next

    ClearList(PendingMonitorEvents())
    SendMessage_(GadgetID(#GADGET_MONITOR_LIST), #WM_SETREDRAW, #True, 0)
    InvalidateRect_(GadgetID(#GADGET_MONITOR_LIST), 0, #True)
    SendMessage_(GadgetID(#GADGET_MONITOR_LIST), #LVM_ENSUREVISIBLE, CountGadgetItems(#GADGET_MONITOR_LIST) - 1, #False)
  EndIf
  UnlockMutex(PendingEventsMutex)
EndProcedure

Procedure LogError(location.s, errorMsg.s, errorCode.i = 0)
  Protected timestamp.s, logMsg.s
  timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  logMsg = "[" + timestamp + "] ERROR in " + location + ": " + errorMsg
  If errorCode <> 0
    logMsg + " (Code: " + Str(errorCode) + ")"
  EndIf
  If LogFile
    If Not LogMutex : LogMutex = CreateMutex() : EndIf
    LockMutex(LogMutex)
    WriteStringN(LogFile, logMsg)
    FlushFileBuffers(LogFile)
    UnlockMutex(LogMutex)
  EndIf
  Debug logMsg
EndProcedure

Procedure LogInfo(location.s, infoMsg.s)
  Protected timestamp.s, logMsg.s
  timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  logMsg = "[" + timestamp + "] INFO in " + location + ": " + infoMsg
  If LogFile
    If Not LogMutex : LogMutex = CreateMutex() : EndIf
    LockMutex(LogMutex)
    WriteStringN(LogFile, logMsg)
    FlushFileBuffers(LogFile)
    UnlockMutex(LogMutex)
  EndIf
  Debug logMsg
EndProcedure

Procedure LogWarning(location.s, warnMsg.s)
  Protected timestamp.s, logMsg.s
  timestamp = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  logMsg = "[" + timestamp + "] WARNING in " + location + ": " + warnMsg
  If LogFile
    If Not LogMutex : LogMutex = CreateMutex() : EndIf
    LockMutex(LogMutex)
    WriteStringN(LogFile, logMsg)
    FlushFileBuffers(LogFile)
    UnlockMutex(LogMutex)
  EndIf
  Debug logMsg
EndProcedure

Procedure CloseErrorLog()
  If LogFile
    If Not LogMutex : LogMutex = CreateMutex() : EndIf
    LockMutex(LogMutex)
    WriteStringN(LogFile, "")
    WriteStringN(LogFile, "=" + Space(60) + "=")
    WriteStringN(LogFile, "Log closed at " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()))
    CloseFile(LogFile)
    LogFile = 0
    UnlockMutex(LogMutex)
  EndIf
EndProcedure

Procedure PostAsyncStatus(text.s)
  Protected *payload.AsyncStatusEvent = AllocateStructure(AsyncStatusEvent)
  If *payload
    *payload\Text = text
    PostEvent(#EVENT_ASYNC_STATUS, #WINDOW_MAIN, 0, 0, *payload)
  EndIf
EndProcedure

Procedure PostAsyncMessage(title.s, text.s, flags.i)
  Protected *payload.AsyncMessageEvent = AllocateStructure(AsyncMessageEvent)
  If *payload
    *payload\Title = title
    *payload\Text = text
    *payload\Flags = flags
    PostEvent(#EVENT_ASYNC_MESSAGE, #WINDOW_MAIN, 0, 0, *payload)
  EndIf
EndProcedure

Procedure.s EscapePowerShellLiteral(text.s)
  ProcedureReturn ReplaceString(text, "'", "''")
EndProcedure

Procedure.i StartBackupProcess(fileName.s, reason.s, isAuto.i, mode.s = "full", rootKey.i = 0, keyPath.s = "")
  Protected scriptFile.s, statusFile.s, scriptHandle.i, program.i, i.i, entryCount.i
  Protected Dim hiveNames.s(4)
  Protected Dim hiveShortNames.s(4)
  Protected Dim tempFiles.s(4)
  Protected script.s
  Protected rootName.s, sourcePath.s, baseName.s, extPos.i, targetFolder.s, folderName.s

  If fileName = ""
    ProcedureReturn #False
  EndIf

  If BackupProgram And ProgramRunning(BackupProgram)
    LogWarning("StartBackupProcess", "Backup already running")
    ProcedureReturn #False
  EndIf

  BackupOutputFolder = ""

  If LCase(mode) = "key" And rootKey <> 0
    Select rootKey
      Case #HKEY_CLASSES_ROOT : rootName = "HKEY_CLASSES_ROOT" : hiveShortNames(0) = "HKCR"
      Case #HKEY_CURRENT_USER : rootName = "HKEY_CURRENT_USER" : hiveShortNames(0) = "HKCU"
      Case #HKEY_LOCAL_MACHINE : rootName = "HKEY_LOCAL_MACHINE" : hiveShortNames(0) = "HKLM"
      Case #HKEY_USERS : rootName = "HKEY_USERS" : hiveShortNames(0) = "HKU"
      Case #HKEY_CURRENT_CONFIG : rootName = "HKEY_CURRENT_CONFIG" : hiveShortNames(0) = "HKCC"
    EndSelect
    If rootName = ""
      LogError("StartBackupProcess", "Invalid root key for key backup")
      ProcedureReturn #False
    EndIf
    sourcePath = rootName
    If keyPath <> "" : sourcePath + "\" + keyPath : EndIf
    hiveNames(0) = sourcePath
    tempFiles(0) = fileName
    entryCount = 1
  Else
    hiveNames(0) = "HKEY_CLASSES_ROOT"
    hiveNames(1) = "HKEY_CURRENT_USER"
    hiveNames(2) = "HKEY_LOCAL_MACHINE"
    hiveNames(3) = "HKEY_USERS"
    hiveNames(4) = "HKEY_CURRENT_CONFIG"
    hiveShortNames(0) = "HKCR"
    hiveShortNames(1) = "HKCU"
    hiveShortNames(2) = "HKLM"
    hiveShortNames(3) = "HKU"
    hiveShortNames(4) = "HKCC"

    extPos = FindString(fileName, ".", Len(fileName) - 4)
    If extPos > 0
      baseName = Left(fileName, extPos - 1)
    Else
      baseName = fileName
    EndIf

    folderName = GetFilePart(baseName)
    targetFolder = GetPathPart(fileName) + folderName + "\"
    If FileSize(targetFolder) <> -2
      If Not CreateDirectory(targetFolder)
        LogError("StartBackupProcess", "Failed to create backup folder: " + targetFolder)
        ProcedureReturn #False
      EndIf
    EndIf
    BackupOutputFolder = targetFolder

    For i = 0 To ArraySize(hiveNames())
      tempFiles(i) = targetFolder + folderName + "_" + hiveShortNames(i) + ".reg"
    Next
    entryCount = ArraySize(hiveNames()) + 1
  EndIf

  scriptFile = GetTemporaryDirectory() + "RegistryManager_Backup_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".ps1"
  statusFile = GetTemporaryDirectory() + "RegistryManager_BackupStatus_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".txt"
  script + "$ErrorActionPreference = 'Stop'" + #CRLF$
  script + "$status = '" + EscapePowerShellLiteral(statusFile) + "'" + #CRLF$
  script + "$entries = @(" + #CRLF$
  For i = 0 To entryCount - 1
    script + "  @{ Hive = '" + EscapePowerShellLiteral(hiveNames(i)) + "'; File = '" + EscapePowerShellLiteral(tempFiles(i)) + "' }"
    If i < entryCount - 1
      script + ","
    EndIf
    script + #CRLF$
  Next
  script + ")" + #CRLF$
  script + "try {" + #CRLF$
  script + "  foreach ($entry in $entries) {" + #CRLF$
  script + "    Set-Content -LiteralPath $status -Value ('Exporting ' + $entry.Hive) -Encoding UTF8" + #CRLF$
  script + "    & reg.exe export $entry.Hive $entry.File /y | Out-Null" + #CRLF$
  script + "    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $entry.File) -or ((Get-Item -LiteralPath $entry.File).Length -le 0)) {" + #CRLF$
  script + "      throw ('Failed exporting ' + $entry.Hive)" + #CRLF$
  script + "    }" + #CRLF$
  script + "  }" + #CRLF$
  script + "  Set-Content -LiteralPath $status -Value 'Backup complete' -Encoding UTF8" + #CRLF$
  script + "  exit 0" + #CRLF$
  script + "}" + #CRLF$
  script + "catch {" + #CRLF$
  script + "  Set-Content -LiteralPath $status -Value ('Failed: ' + $_.Exception.Message) -Encoding UTF8" + #CRLF$
  script + "  exit 1" + #CRLF$
  script + "}" + #CRLF$

  scriptHandle = CreateFile(#PB_Any, scriptFile)
  If Not scriptHandle
    LogError("StartBackupProcess", "Failed to create backup script: " + scriptFile)
    ProcedureReturn #False
  EndIf
  WriteString(scriptHandle, script, #PB_UTF8)
  CloseFile(scriptHandle)

  LogInfo("StartBackupProcess", "Launching backup process for: " + reason)
  program = RunProgram("powershell", "-NoProfile -ExecutionPolicy Bypass -File " + Chr(34) + scriptFile + Chr(34), "", #PB_Program_Open | #PB_Program_Hide)
  If Not program
    DeleteFile(scriptFile)
    LogError("StartBackupProcess", "Failed to start PowerShell backup process")
    ProcedureReturn #False
  EndIf

  BackupProgram = program
  BackupScriptFile = scriptFile
  BackupStatusFile = statusFile
  BackupOutputFile = fileName
  BackupReason = reason
  BackupIsAuto = isAuto
  BackupCurrentMode = LCase(mode)
  BackupCurrentStage = "Starting backup..."
  AddWindowTimer(#WINDOW_MAIN, #TIMER_BACKUP_REFRESH, 250)
  ProcedureReturn #True
EndProcedure

Procedure.i ExportRegistryHives(fileName.s)
  Protected tempFile.s, scriptFile.s, scriptHandle.i, i.i, exitCode.i, program.i, mergeProgram.i
  Protected Dim hiveNames.s(4)
  Protected Dim hiveShortNames.s(4)
  Protected Dim tempFiles.s(4)
  Protected script.s

  If fileName = ""
    ProcedureReturn #False
  EndIf

  hiveNames(0) = "HKEY_CLASSES_ROOT"
  hiveNames(1) = "HKEY_CURRENT_USER"
  hiveNames(2) = "HKEY_LOCAL_MACHINE"
  hiveNames(3) = "HKEY_USERS"
  hiveNames(4) = "HKEY_CURRENT_CONFIG"
  hiveShortNames(0) = "HKCR"
  hiveShortNames(1) = "HKCU"
  hiveShortNames(2) = "HKLM"
  hiveShortNames(3) = "HKU"
  hiveShortNames(4) = "HKCC"

  For i = 0 To ArraySize(hiveNames())
    tempFile = GetTemporaryDirectory() + "RegistryManager_" + hiveShortNames(i) + "_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + "_" + Str(i) + ".reg"
    tempFiles(i) = tempFile
    If FileSize(tempFile) >= 0
      DeleteFile(tempFile)
    EndIf

    LogInfo("ExportRegistryHives", "Exporting hive: " + hiveNames(i))
    program = RunProgram("reg", "export " + hiveNames(i) + " " + Chr(34) + tempFile + Chr(34) + " /y", "", #PB_Program_Wait | #PB_Program_Hide)
    If program
      exitCode = ProgramExitCode(program)
      CloseProgram(program)
      If exitCode <> 0 Or FileSize(tempFile) <= 0
        If FileSize(fileName) >= 0 : DeleteFile(fileName) : EndIf
        If FileSize(tempFile) >= 0 : DeleteFile(tempFile) : EndIf
        LogError("ExportRegistryHives", "Failed exporting hive " + hiveNames(i) + " (exit code " + Str(exitCode) + ")")
        ProcedureReturn #False
      EndIf
    Else
      If FileSize(fileName) >= 0 : DeleteFile(fileName) : EndIf
      LogError("ExportRegistryHives", "Failed to execute reg.exe for hive " + hiveNames(i))
      ProcedureReturn #False
    EndIf
  Next

  scriptFile = GetTemporaryDirectory() + "RegistryManager_Merge_" + FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date()) + ".ps1"
  script = "$files = @(" + #CRLF$
  For i = 0 To ArraySize(tempFiles())
    script + "  '" + EscapePowerShellLiteral(tempFiles(i)) + "'"
    If i < ArraySize(tempFiles())
      script + ","
    EndIf
    script + #CRLF$
  Next
  script + ")" + #CRLF$
  script + "$out = '" + EscapePowerShellLiteral(fileName) + "'" + #CRLF$
  script + "$enc = New-Object System.Text.UnicodeEncoding($false, $true)" + #CRLF$
  script + "$writer = New-Object System.IO.StreamWriter($out, $false, $enc)" + #CRLF$
  script + "$writer.NewLine = '`r`n'" + #CRLF$
  script + "$writer.WriteLine('Windows Registry Editor Version 5.00')" + #CRLF$
  script + "$writer.WriteLine()" + #CRLF$
  script + "foreach ($file in $files) {" + #CRLF$
  script + "  Get-Content -LiteralPath $file | Select-Object -Skip 2 | ForEach-Object { $writer.WriteLine($_) }" + #CRLF$
  script + "  $writer.WriteLine()" + #CRLF$
  script + "}" + #CRLF$
  script + "$writer.Close()" + #CRLF$

  scriptHandle = CreateFile(#PB_Any, scriptFile)
  If Not scriptHandle
    LogError("ExportRegistryHives", "Failed to create merge script: " + scriptFile)
    For i = 0 To ArraySize(tempFiles())
      If FileSize(tempFiles(i)) >= 0 : DeleteFile(tempFiles(i)) : EndIf
    Next
    ProcedureReturn #False
  EndIf
  WriteString(scriptHandle, script, #PB_UTF8)
  CloseFile(scriptHandle)

  LogInfo("ExportRegistryHives", "Merging exported hives into: " + fileName)
  mergeProgram = RunProgram("powershell", "-NoProfile -ExecutionPolicy Bypass -File " + Chr(34) + scriptFile + Chr(34), "", #PB_Program_Wait | #PB_Program_Hide)
  If mergeProgram
    exitCode = ProgramExitCode(mergeProgram)
    CloseProgram(mergeProgram)
  Else
    exitCode = -1
  EndIf

  DeleteFile(scriptFile)
  For i = 0 To ArraySize(tempFiles())
    If FileSize(tempFiles(i)) >= 0 : DeleteFile(tempFiles(i)) : EndIf
  Next

  If exitCode <> 0 Or FileSize(fileName) <= 0
    If FileSize(fileName) >= 0 : DeleteFile(fileName) : EndIf
    LogError("ExportRegistryHives", "Failed merging exported hives (exit code " + Str(exitCode) + ")")
    ProcedureReturn #False
  EndIf

  LogInfo("ExportRegistryHives", "Registry export completed successfully")
  ProcedureReturn #True
EndProcedure

Procedure.s GetBackupDirectory()
  Protected backupDir.s
  backupDir = AppPath + #BACKUP_DIR_NAME + "\"
  If FileSize(backupDir) <> -2
    If CreateDirectory(backupDir)
      LogInfo("GetBackupDirectory", "Created backup directory: " + backupDir)
    Else
      LogError("GetBackupDirectory", "Failed to create backup directory: " + backupDir)
      backupDir = GetTemporaryDirectory() + "RegistryManager_Backups\"
      CreateDirectory(backupDir)
    EndIf
  EndIf
  ProcedureReturn backupDir
EndProcedure

Procedure.i CreateAutoBackup(reason.s = "Auto-backup before changes")
  Protected backupFile.s, backupDir.s, timestamp.s

  timestamp = FormatDate("%yyyy%mm%dd_%hh%ii%ss", Date())
  backupDir = GetBackupDirectory()
  backupFile = backupDir + "AutoBackup_" + timestamp + ".reg"

  LogInfo("CreateAutoBackup", "Queuing automatic backup: " + reason)
  UpdateStatusBar("Background backup started... You can continue working.")

  ProcedureReturn StartBackupProcess(backupFile, reason, #True, "full")
EndProcedure

Procedure BackupRegistry(fileName.s)
  If fileName = ""
    LogError("BackupRegistry", "Empty filename provided")
    UpdateStatusBar("Error: No filename specified")
    ProcedureReturn #False
  EndIf

  LogInfo("BackupRegistry", "Queuing manual backup to: " + fileName)
  UpdateStatusBar("Background backup started...")

  If StartBackupProcess(fileName, "Manual User Backup", #False, "full")
    ProcedureReturn #True
  EndIf

  UpdateStatusBar("Error: Could not start backup process")
  MessageRequester("Backup Failed", "Could not start the backup task.", #PB_MessageRequester_Error)
  ProcedureReturn #False
EndProcedure

Procedure BackupCurrentKey(rootKey.i, keyPath.s, fileName.s)
  If rootKey = 0 Or fileName = ""
    ProcedureReturn #False
  EndIf

  LogInfo("BackupCurrentKey", "Queuing current key backup to: " + fileName)
  UpdateStatusBar("Background key backup started...")

  If StartBackupProcess(fileName, "Current Key Backup", #False, "key", rootKey, keyPath)
    ProcedureReturn #True
  EndIf

  UpdateStatusBar("Error: Could not start key backup process")
  MessageRequester("Backup Failed", "Could not start the key backup task.", #PB_MessageRequester_Error)
  ProcedureReturn #False
EndProcedure

Procedure.i EnsureBackupBeforeChange(operation.s)
  Protected result.i
  LogInfo("EnsureBackupBeforeChange", "Checking backup requirement for: " + operation)

  If AutoBackupPath = "" Or (ElapsedMilliseconds() - LastBackupTime) > #AUTO_BACKUP_INTERVAL
    LogInfo("EnsureBackupBeforeChange", "Creating new backup (reason: " + operation + ")")
    result = MessageRequester("Safety Backup Required", "Registry Manager will create a full registry backup before:" + #CRLF$ + operation + #CRLF$ + #CRLF$ + "This backup can be used to restore your registry if needed." + #CRLF$ + #CRLF$ + "Continue?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)

    If result = #PB_MessageRequester_Yes
      If Not CreateAutoBackup(operation)
        result = MessageRequester("Backup Failed", "Failed to create safety backup!" + #CRLF$ + #CRLF$ + "Do you want to continue WITHOUT backup?" + #CRLF$ + "(NOT RECOMMENDED)", #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning)
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
    LogInfo("EnsureBackupBeforeChange", "Using existing backup file: " + AutoBackupPath)
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

Procedure UpdateStatusBar(text.s)
  If IsStatusBar(#GADGET_STATUSBAR)
    StatusBarText(#GADGET_STATUSBAR, 0, text)
  EndIf
  LogInfo("StatusBar", text)
EndProcedure

Procedure.s GetRootKeyName(rootKey.i)
  Select rootKey
    Case #HKEY_CLASSES_ROOT : ProcedureReturn "HKEY_CLASSES_ROOT"
    Case #HKEY_CURRENT_USER : ProcedureReturn "HKEY_CURRENT_USER"
    Case #HKEY_LOCAL_MACHINE : ProcedureReturn "HKEY_LOCAL_MACHINE"
    Case #HKEY_USERS : ProcedureReturn "HKEY_USERS"
    Case #HKEY_CURRENT_CONFIG : ProcedureReturn "HKEY_CURRENT_CONFIG"
  EndSelect
  LogWarning("GetRootKeyName", "Unknown root key: " + Str(rootKey))
  ProcedureReturn "UNKNOWN"
EndProcedure

Procedure.i GetRegistryWow64Flag(sam.l = 0)
  If sam = 0
    sam = GetDefaultSAM()
  EndIf
  If sam & #KEY_WOW64_32KEY
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.i GetRootKeyFromTreeItem(item.i)
  Protected rootName.s

  If item < 0
    LogError("GetRootKeyFromTreeItem", "Invalid tree item: " + Str(item))
    ProcedureReturn 0
  EndIf

  Protected current.i = item
  While current >= 0 And GetGadgetItemAttribute(#GADGET_TREE, current, #PB_Tree_SubLevel) > 0
    Protected level.i = GetGadgetItemAttribute(#GADGET_TREE, current, #PB_Tree_SubLevel)
    Protected p.i
    Protected found.i = #False
    For p = current - 1 To 0 Step -1
      If GetGadgetItemAttribute(#GADGET_TREE, p, #PB_Tree_SubLevel) < level
        current = p
        found = #True
        Break
      EndIf
    Next
    If Not found : Break : EndIf
  Wend

  rootName = GetGadgetItemText(#GADGET_TREE, current)
  Select rootName
    Case "HKEY_CLASSES_ROOT" : ProcedureReturn #HKEY_CLASSES_ROOT
    Case "HKEY_CURRENT_USER" : ProcedureReturn #HKEY_CURRENT_USER
    Case "HKEY_LOCAL_MACHINE" : ProcedureReturn #HKEY_LOCAL_MACHINE
    Case "HKEY_USERS" : ProcedureReturn #HKEY_USERS
    Case "HKEY_CURRENT_CONFIG" : ProcedureReturn #HKEY_CURRENT_CONFIG
  EndSelect

  LogWarning("GetRootKeyFromTreeItem", "Unknown root key name: '" + rootName + "' at index " + Str(current))
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
    Case #REG_SZ : ProcedureReturn "REG_SZ"
    Case #REG_DWORD : ProcedureReturn "REG_DWORD"
    Case #REG_BINARY : ProcedureReturn "REG_BINARY"
    Case #REG_EXPAND_SZ : ProcedureReturn "REG_EXPAND_SZ"
    Case #REG_MULTI_SZ : ProcedureReturn "REG_MULTI_SZ"
    Case #REG_QWORD : ProcedureReturn "REG_QWORD"
    Case #REG_NONE : ProcedureReturn "REG_NONE"
    Default : ProcedureReturn "Unknown (" + Str(type) + ")"
  EndSelect
EndProcedure

Procedure HandleCloseWindowEvent()
  Select EventWindow()
    Case #WINDOW_MAIN
      LogInfo("Main", "User attempted to close main window")
      Exit()

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
      CloseWindow(#WINDOW_SNAPSHOT)
      SnapshotWindow = 0

    Case #WINDOW_SEARCH
      SearchStopRequested = #True
      CloseWindow(#WINDOW_SEARCH)
  EndSelect
EndProcedure

Procedure HandleTimerEvent()
  If EventWindow() = #WINDOW_MONITOR And EventTimer() = #TIMER_MONITOR_REFRESH
    RefreshMonitorWindow()
  ElseIf EventWindow() = #WINDOW_SEARCH And EventTimer() = 4001
    If Not SearchResultsMutex : SearchResultsMutex = CreateMutex() : EndIf
    LockMutex(SearchResultsMutex)
    Define currentResults.i = ListSize(SearchResults())
    Define displayedResults.i = CountGadgetItems(#GADGET_SEARCH_RESULTS)

    If currentResults > displayedResults
      SelectElement(SearchResults(), displayedResults)
      While displayedResults < currentResults
        AddGadgetItem(#GADGET_SEARCH_RESULTS, -1, SearchResults()\KeyPath + Chr(10) + SearchResults()\ValueName + Chr(10) + GetTypeName(SearchResults()\ValueType) + Chr(10) + Left(SearchResults()\ValueData, 100))
        displayedResults + 1
        If NextElement(SearchResults()) = 0 : Break : EndIf
      Wend
    EndIf
    UnlockMutex(SearchResultsMutex)

    If SearchThreadID = 0
      RemoveWindowTimer(#WINDOW_SEARCH, 4001)
      DisableGadget(#GADGET_SEARCH_START, #False)
      DisableGadget(#GADGET_SEARCH_STOP, #True)
      UpdateSearchStatusLabel(#False)
    Else
      UpdateSearchStatusLabel(#True)
    EndIf
  ElseIf EventWindow() = #WINDOW_SNAPSHOT And EventTimer() = 4002
    If CompareThreadID <> 0
      UpdateStatusBar("Comparing snapshots in background... Found " + Str(ListSize(DiffResults())) + " diffs")
    EndIf
  ElseIf EventWindow() = #WINDOW_MAIN And EventTimer() = #TIMER_BACKUP_REFRESH
    If BackupProgram
      If BackupStatusFile <> "" And FileSize(BackupStatusFile) > 0
        Protected statusReader.i = ReadFile(#PB_Any, BackupStatusFile)
        If statusReader
          Protected latestStatus.s = ""
          While Not Eof(statusReader)
            latestStatus = ReadString(statusReader)
          Wend
          CloseFile(statusReader)
          If latestStatus <> "" And latestStatus <> BackupCurrentStage
            BackupCurrentStage = latestStatus
            UpdateStatusBar(latestStatus)
          EndIf
        EndIf
      EndIf

      If ProgramRunning(BackupProgram)
        ProcedureReturn
      EndIf

      Define backupExitCode.i = ProgramExitCode(BackupProgram)
      CloseProgram(BackupProgram)
      BackupProgram = 0
      RemoveWindowTimer(#WINDOW_MAIN, #TIMER_BACKUP_REFRESH)
      If BackupScriptFile <> "" And FileSize(BackupScriptFile) >= 0
        DeleteFile(BackupScriptFile)
      EndIf
      If BackupStatusFile <> "" And FileSize(BackupStatusFile) >= 0
        DeleteFile(BackupStatusFile)
      EndIf

      If backupExitCode = 0
        If BackupIsAuto
          AutoBackupPath = BackupOutputFile
          LastBackupTime = ElapsedMilliseconds()
        EndIf
        If BackupCurrentMode = "full"
          LogInfo("HandleTimerEvent", "Backup completed successfully: " + BackupOutputFile)
          UpdateStatusBar("Full backup completed in separate hive files")
          If Not BackupIsAuto
            MessageRequester("Backup Complete", "Full registry backup completed." + #CRLF$ + #CRLF$ + "Files were written to folder:" + #CRLF$ + BackupOutputFolder, #PB_MessageRequester_Info)
          EndIf
        ElseIf FileSize(BackupOutputFile) > 0
          LogInfo("HandleTimerEvent", "Key backup completed successfully: " + BackupOutputFile)
          UpdateStatusBar("Backup completed: " + GetFilePart(BackupOutputFile))
          If Not BackupIsAuto
            MessageRequester("Backup Complete", "Registry key backup completed:" + #CRLF$ + BackupOutputFile, #PB_MessageRequester_Info)
          EndIf
        Else
          LogError("HandleTimerEvent", "Key backup finished but output file is missing: " + BackupOutputFile)
          UpdateStatusBar("Error: Backup failed!")
        EndIf
      Else
        If FileSize(BackupOutputFile) = 0
          DeleteFile(BackupOutputFile)
        EndIf
        LogError("HandleTimerEvent", "Backup process failed for: " + BackupOutputFile + " (exit code " + Str(backupExitCode) + ")")
        UpdateStatusBar("Error: Backup failed!")
        If Not BackupIsAuto
          MessageRequester("Backup Failed", "Failed to create registry backup file." + #CRLF$ + "Check the log for details.", #PB_MessageRequester_Error)
        EndIf
      EndIf

      BackupScriptFile = ""
      BackupStatusFile = ""
      BackupOutputFile = ""
      BackupOutputFolder = ""
      BackupReason = ""
      BackupIsAuto = #False
      BackupCurrentMode = ""
      BackupCurrentStage = ""
    EndIf
  EndIf
EndProcedure

Procedure HandleCustomEvent(eventID.i)
  Select eventID
    Case #EVENT_EXPORT_COMPLETE
      Define exitCodeExport.i = EventType()
      Define isRestoreExport.i = EventData()

      If exitCodeExport = 0
        If isRestoreExport
          UpdateStatusBar("Registry restoration successful")
          MessageRequester("Success", "Registry restored successfully. You should restart your computer for changes to take full effect.", #PB_MessageRequester_Info)
        Else
          UpdateStatusBar("Registry export successful")
        EndIf
      Else
        If isRestoreExport
          UpdateStatusBar("Registry restoration failed")
          MessageRequester("Error", "Registry restoration failed with exit code " + Str(exitCodeExport), #PB_MessageRequester_Error)
        Else
          UpdateStatusBar("Registry export failed")
          MessageRequester("Error", "Registry export failed with exit code " + Str(exitCodeExport), #PB_MessageRequester_Error)
        EndIf
      EndIf

    Case #EVENT_SNAPSHOT_CREATED
      Define *snapRes.SnapshotCreationResult = EventData()
      If *snapRes
        SnapshotCreationActive = 0
        SetSnapshotControlsEnabled(#True)
        RefreshSnapshotList()
        If *snapRes\Success
          UpdateStatusBar("Snapshot creation complete")
          MessageRequester("Success", "Registry snapshot created successfully!", #PB_MessageRequester_Info)
        Else
          UpdateStatusBar("Snapshot creation failed")
          MessageRequester("Error", *snapRes\ErrorText + #CRLF$ + "Check the log for details.", #PB_MessageRequester_Error)
        EndIf
        FreeStructure(*snapRes)
      EndIf

    Case #EVENT_ASYNC_STATUS
      Define *status.AsyncStatusEvent = EventData()
      If *status
        UpdateStatusBar(*status\Text)
        FreeStructure(*status)
      EndIf

    Case #EVENT_ASYNC_MESSAGE
      Define *asyncMsg.AsyncMessageEvent = EventData()
      If *asyncMsg
        MessageRequester(*asyncMsg\Title, *asyncMsg\Text, *asyncMsg\Flags)
        FreeStructure(*asyncMsg)
      EndIf

    Case #EVENT_COMPARE_COMPLETE
      RemoveWindowTimer(#WINDOW_SNAPSHOT, 4002)
      UpdateStatusBar("Comparison complete.")
      SetSnapshotControlsEnabled(#True)
      ClearGadgetItems(#GADGET_SNAPSHOT_DIFF)
      If Not DiffResultsMutex : DiffResultsMutex = CreateMutex() : EndIf
      LockMutex(DiffResultsMutex)
      ForEach DiffResults()
        Define displayDetails.s = DiffResults()\ValueName
        If displayDetails <> "" : displayDetails + " -> " : EndIf
        displayDetails + DiffResults()\NewData + " " + DiffResults()\OldData
        AddGadgetItem(#GADGET_SNAPSHOT_DIFF, -1, DiffResults()\ChangeType + Chr(9) + DiffResults()\KeyPath + Chr(9) + displayDetails)
      Next
      UnlockMutex(DiffResultsMutex)
      MessageRequester("Comparison Complete", "Results:" + #CRLF$ + "Added: " + Str(CompareAddedCount) + #CRLF$ + "Removed: " + Str(CompareRemovedCount) + #CRLF$ + "Modified: " + Str(CompareModifiedCount), #PB_MessageRequester_Info)

    Case #EVENT_LOAD_VALUES_COMPLETE
      Define *vres.LoadValuesResult = EventData()
      If *vres
        If *vres\Error <> 0
          UpdateStatusBar("Error: " + *vres\ErrorStr)
        EndIf

        SendMessage_(GadgetID(#GADGET_LISTVIEW), #WM_SETREDRAW, #False, 0)
        ClearGadgetItems(#GADGET_LISTVIEW)
        ClearList(RegValues())
        ForEach *vres\Values()
          AddElement(RegValues())
          RegValues()\Name = *vres\Values()\Name
          RegValues()\Type = *vres\Values()\Type
          RegValues()\Data = *vres\Values()\Data

          Define vIconIdx.i = 0
          Select *vres\Values()\Type
            Case #REG_BINARY : vIconIdx = 1
            Case #REG_DWORD, #REG_QWORD : vIconIdx = 2
          EndSelect

          AddGadgetItem(#GADGET_LISTVIEW, -1, *vres\Values()\Name + Chr(10) + GetTypeName(*vres\Values()\Type) + Chr(10) + Left(*vres\Values()\Data, 200), vIconIdx)
        Next
        SendMessage_(GadgetID(#GADGET_LISTVIEW), #WM_SETREDRAW, #True, 0)
        InvalidateRect_(GadgetID(#GADGET_LISTVIEW), 0, #True)
        UpdateStatusBar("Loaded " + Str(*vres\Count) + " value(s)")
        FreeStructure(*vres)
      EndIf

    Case #EVENT_LOAD_COMPLETE
      Define *res.LoadKeysThreadResult = EventData()
      If *res
        Define parentItem.i = *res\ParentItem
        If *res\Error <> 0
          UpdateStatusBar("Error loading subkeys: " + *res\ErrorStr)
        EndIf

        IsUpdatingTree = #True
        SendMessage_(GadgetID(#GADGET_TREE), #WM_SETREDRAW, #False, 0)
        Define insertPos.i = parentItem + 1
        Define parentLevel.i = GetGadgetItemAttribute(#GADGET_TREE, parentItem, #PB_Tree_SubLevel)
        Define childLevel.i = parentLevel + 1
        ForEach *res\SubKeys()
          AddGadgetItem(#GADGET_TREE, insertPos, *res\SubKeys(), 0, childLevel)
          insertPos + 1
        Next
        SendMessage_(GadgetID(#GADGET_TREE), #WM_SETREDRAW, #True, 0)
        IsUpdatingTree = #False

        LockMutex(LoadKeysMutex)
        DeleteMapElement(ActiveLoadThreads(), Str(parentItem))
        UnlockMutex(LoadKeysMutex)
        FreeStructure(*res)
      EndIf
  EndSelect
EndProcedure

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 154
; FirstLine = 141
; Folding = -----
; EnableXP
; DPIAware