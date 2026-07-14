; User actions, settings flows, and non-shell helpers

Procedure.b ConfirmExit()
  If IndexingActive
    If MessageRequester("Exit", "Indexing is currently active. Do you want to stop indexing and exit?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
      ProcedureReturn #True
    Else
      ProcedureReturn #False
    EndIf
  EndIf
  ProcedureReturn #True
EndProcedure

Procedure.s SelectedResultPath()
  Protected idx.i = GetGadgetState(#Gadget_ResultsList)
  If idx >= 0
    ProcedureReturn GetGadgetItemText(#Gadget_ResultsList, idx)
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure.s UrlEncode(text.s)
  Protected i.i, ch.i
  Protected out.s = ""
  Protected len.i = StringByteLength(text, #PB_UTF8)
  Protected *mem

  If len <= 0
    ProcedureReturn ""
  EndIf

  *mem = AllocateMemory(len + 1)
  If *mem = 0
    ProcedureReturn ""
  EndIf

  PokeS(*mem, text, -1, #PB_UTF8)

  For i = 0 To len - 1
    ch = PeekA(*mem + i) & $FF
    Select ch
      Case '0' To '9', 'A' To 'Z', 'a' To 'z', 45, 46, 95, 126
        out + Chr(ch)
      Case 32
        out + "+"
      Default
        out + "%" + RSet(UCase(Hex(ch)), 2, "0")
    EndSelect
  Next

  FreeMemory(*mem)
  ProcedureReturn out
EndProcedure

Procedure WebSearch(showError.i)
  Protected query.s = Trim(GetGadgetText(#Gadget_SearchBar))
  Protected url.s

  If query = ""
    ProcedureReturn
  EndIf

  url = "https://www.google.com/search?q=" + UrlEncode(query)
  If ShellExecute_(0, "open", url, 0, 0, #SW_SHOWNORMAL) <= 32
    If showError
      MessageRequester(#APP_NAME, "Failed To open browser for:" + #CRLF$ + url, #PB_MessageRequester_Error)
    EndIf
  EndIf
EndProcedure

Procedure OpenPath(path.s, showError.i)
  Protected pathType.i

  If path = ""
    ProcedureReturn
  EndIf

  pathType = FileSize(path)
  If pathType = -1
    If showError
      MessageRequester(#APP_NAME, "Path Not found:" + #CRLF$ + path, #PB_MessageRequester_Error)
    EndIf
    ProcedureReturn
  EndIf

  If ShellExecute_(0, "open", path, 0, 0, #SW_SHOWNORMAL) <= 32
    If showError
      MessageRequester(#APP_NAME, "Failed To open:" + #CRLF$ + path, #PB_MessageRequester_Error)
    EndIf
  EndIf
EndProcedure

Procedure OpenConfig(showError.i)
  Protected iniPath.s = GetConfigPath()

  If FileSize(iniPath) < 0
    WriteDefaultExcludesIni(iniPath)
  EndIf

  If FileSize(iniPath) < 0
    If showError
      MessageRequester(#APP_NAME, "INI file could not be created:" + #CRLF$ + iniPath, #PB_MessageRequester_Error)
    EndIf
    ProcedureReturn
  EndIf

  OpenPath(iniPath, showError)
EndProcedure

Procedure OpenCrashLog(showError.i)
  Protected f.i

  If CrashLogPath = ""
    CrashLogPath = ChooseCrashLogPath()
  EndIf

  If CrashLogPath = ""
    If showError
      MessageRequester(#APP_NAME, "Crash log path is not available in the Logs folder.", #PB_MessageRequester_Error)
    EndIf
    ProcedureReturn
  EndIf

  f = OpenCrashLogFile(CrashLogPath)
  If f
    CloseFile(f)
  EndIf

  OpenPath(CrashLogPath, showError)
EndProcedure

Procedure.i ClampSettingInt(*changed.Integer, currentValue.i, newValue.i, minValue.i, maxValue.i)
  Protected v.i = newValue
  If v < minValue : v = minValue : EndIf
  If v > maxValue : v = maxValue : EndIf
  If v <> currentValue
    *changed\i = #True
    ProcedureReturn v
  EndIf
  ProcedureReturn currentValue
EndProcedure

Procedure EditExcludeLists()
  Protected newDirs.s, newFiles.s, newPaths.s
  Protected currentDirs.s, currentFiles.s, currentPaths.s
  Protected changed.i = #False
  Protected i.i
  Protected count.i
  Protected part.s

  If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf
  ForEach ExcludeDirNames()
    If currentDirs <> "" : currentDirs + ", " : EndIf
    currentDirs + MapKey(ExcludeDirNames())
  Next
  ForEach ExcludeFileNames()
    If currentFiles <> "" : currentFiles + ", " : EndIf
    currentFiles + MapKey(ExcludeFileNames())
  Next
  ForEach ExcludePathPrefixes()
    If currentPaths <> "" : currentPaths + ", " : EndIf
    currentPaths + MapKey(ExcludePathPrefixes())
  Next
  If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf

  newDirs = InputRequester("Edit Exclude Folders", "Enter folder names to skip (comma-separated):", currentDirs)
  If newDirs <> currentDirs
    If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf
    ClearMap(ExcludeDirNames())
    count = CountString(newDirs, ",") + 1
    For i = 1 To count
      part = LCase(Trim(StringField(newDirs, i, ",")))
      If part <> "" : ExcludeDirNames(part) = 1 : EndIf
    Next
    If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf
    changed = #True
  EndIf

  newFiles = InputRequester("Edit Exclude Files", "Enter file names to skip (comma-separated):", currentFiles)
  If newFiles <> currentFiles
    If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf
    ClearMap(ExcludeFileNames())
    count = CountString(newFiles, ",") + 1
    For i = 1 To count
      part = LCase(Trim(StringField(newFiles, i, ",")))
      If part <> "" : ExcludeFileNames(part) = 1 : EndIf
    Next
    If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf
    changed = #True
  EndIf

  newPaths = InputRequester("Edit Exclude Paths", "Enter full path prefixes to skip (comma-separated):", currentPaths)
  If newPaths <> currentPaths
    If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf
    ClearMap(ExcludePathPrefixes())
    count = CountString(newPaths, ",") + 1
    For i = 1 To count
      part = LCase(NormalizePath(Trim(StringField(newPaths, i, ","))))
      If part <> ""
        If Left(part, 1) <> "\" And FindString(part, ":\", 1) = 0 And Left(part, 2) <> "\\"
          part = "\" + part
        EndIf
        ExcludePathPrefixes(part) = 1
      EndIf
    Next
    If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf
    changed = #True
  EndIf

  If changed
    SaveSettingsIni()
    LoadExcludesIni(GetConfigPath())
    MessageRequester(#APP_NAME, "Exclusion lists updated and saved.", #PB_MessageRequester_Info)
  EndIf
EndProcedure

Procedure SaveSettingsIni()
  Protected iniPath.s = GetConfigPath()

  EnsureParentDirectoryForFile(iniPath)

  If OpenPreferences(iniPath)
    PreferenceGroup("Search")
    WritePreferenceString("MaxResults", Str(SearchMaxResults))
    WritePreferenceString("DebounceMS", Str(SearchDebounceMS))

    PreferenceGroup("Performance")
    WritePreferenceString("Threads", Str(ConfigThreadCount))
    WritePreferenceString("BatchSize", Str(ConfigBatchSize))

    PreferenceGroup("Index")
    WritePreferenceString("DbPath", IndexDbPath)

    PreferenceGroup("App")
    WritePreferenceString("StartMinimized", Str(AppStartMinimized))
    WritePreferenceString("CloseToTray", Str(AppCloseToTray))
    WritePreferenceString("MinimizeToTray", Str(AppMinimizeToTray))
    WritePreferenceString("AutoStartIndex", Str(AppAutoStartIndex))
    WritePreferenceString("LiveMatchFullPath", Str(LiveMatchFullPath))
    WritePreferenceString("RunAtStartup", Str(AppRunAtStartup))

    If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf

    RemovePreferenceGroup("ExcludeDirs")
    PreferenceGroup("ExcludeDirs")
    ForEach ExcludeDirNames()
      WritePreferenceString(MapKey(ExcludeDirNames()), "")
    Next

    RemovePreferenceGroup("ExcludeFiles")
    PreferenceGroup("ExcludeFiles")
    ForEach ExcludeFileNames()
      WritePreferenceString(MapKey(ExcludeFileNames()), "")
    Next

    RemovePreferenceGroup("ExcludePaths")
    PreferenceGroup("ExcludePaths")
    ForEach ExcludePathPrefixes()
      WritePreferenceString(MapKey(ExcludePathPrefixes()), "")
    Next

    If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf
    ClosePreferences()
  ElseIf FileSize(iniPath) < 0
    WriteDefaultExcludesIni(iniPath)
    If OpenPreferences(iniPath)
      ClosePreferences()
    EndIf
  EndIf
EndProcedure

Procedure EditSettings()
  Protected changed.Integer
  Protected oldDbPath.s = IndexDbPath
  Protected dbPathChanged.i
  Protected newDebounce.s
  Protected newMax.s
  Protected newThreads.s
  Protected newBatch.s
  Protected newDbPath.s
  Protected newStartMin.s
  Protected newCloseTray.s
  Protected newMinTray.s
  Protected newAutoIndex.s
  Protected newLiveFullPath.s

  newMax = InputRequester("Edit Settings", "MaxResults (100..200000) (current: " + Str(SearchMaxResults) + "): ", Str(SearchMaxResults))
  If newMax <> ""
    SearchMaxResults = ClampSettingInt(@changed, SearchMaxResults, Val(newMax), 100, 200000)
  EndIf

  newDebounce = InputRequester("Edit Settings", "DebounceMS (0..5000) (current: " + Str(SearchDebounceMS) + "): ", Str(SearchDebounceMS))
  If newDebounce <> ""
    SearchDebounceMS = ClampSettingInt(@changed, SearchDebounceMS, Val(newDebounce), 0, 5000)
  EndIf

  newThreads = InputRequester("Edit Settings", "Threads (0=auto, 0..32) (current: " + Str(ConfigThreadCount) + "): ", Str(ConfigThreadCount))
  If newThreads <> ""
    ConfigThreadCount = ClampSettingInt(@changed, ConfigThreadCount, Val(newThreads), 0, 32)
  EndIf

  newBatch = InputRequester("Edit Settings", "BatchSize (10..5000) (current: " + Str(ConfigBatchSize) + "): ", Str(ConfigBatchSize))
  If newBatch <> ""
    ConfigBatchSize = ClampSettingInt(@changed, ConfigBatchSize, Val(newBatch), 10, 5000)
  EndIf

  newDbPath = InputRequester("Edit Settings", "DbPath (current: " + IndexDbPath + "): ", IndexDbPath)
  If newDbPath <> ""
    newDbPath = Trim(newDbPath)
    If newDbPath <> "" And newDbPath <> IndexDbPath
      IndexDbPath = newDbPath
      changed\i = #True
    EndIf
  EndIf

  newStartMin = InputRequester("Edit Settings", "StartMinimized (0/1) (current: " + Str(AppStartMinimized) + "): ", Str(AppStartMinimized))
  If newStartMin <> ""
    AppStartMinimized = ClampSettingInt(@changed, AppStartMinimized, Val(newStartMin), 0, 1)
  EndIf

  newCloseTray = InputRequester("Edit Settings", "CloseToTray (0/1) (current: " + Str(AppCloseToTray) + "): ", Str(AppCloseToTray))
  If newCloseTray <> ""
    AppCloseToTray = ClampSettingInt(@changed, AppCloseToTray, Val(newCloseTray), 0, 1)
  EndIf

  newMinTray = InputRequester("Edit Settings", "MinimizeToTray (0/1) (current: " + Str(AppMinimizeToTray) + "): ", Str(AppMinimizeToTray))
  If newMinTray <> ""
    AppMinimizeToTray = ClampSettingInt(@changed, AppMinimizeToTray, Val(newMinTray), 0, 1)
  EndIf

  newAutoIndex = InputRequester("Edit Settings", "AutoStartIndex (0/1) (current: " + Str(AppAutoStartIndex) + "): ", Str(AppAutoStartIndex))
  If newAutoIndex <> ""
    AppAutoStartIndex = ClampSettingInt(@changed, AppAutoStartIndex, Val(newAutoIndex), 0, 1)
  EndIf

  newLiveFullPath = InputRequester("Edit Settings", "LiveMatchFullPath (0/1) (current: " + Str(LiveMatchFullPath) + "): ", Str(LiveMatchFullPath))
  If newLiveFullPath <> ""
    LiveMatchFullPath = ClampSettingInt(@changed, LiveMatchFullPath, Val(newLiveFullPath), 0, 1)
  EndIf

  ClampConfigValues()

  If changed\i
    SaveSettingsIni()
    SyncUiState()
    LoadExcludesIni(GetConfigPath())

    dbPathChanged = Bool(LCase(Trim(oldDbPath)) <> LCase(Trim(IndexDbPath)))
    If dbPathChanged
      If IndexingActive = 0
        If IndexDbId : CloseDatabase(IndexDbId) : IndexDbId = 0 : EndIf
        CachedIndexedCount = -1
        CachedIndexedCountAtMS = 0
        InitDatabase()
        IndexTotalFiles = GetIndexedCountFast()
      EndIf
    EndIf

    QueryDirty = 1
    QueryNextAtMS = ElapsedMilliseconds()

    If dbPathChanged And IndexingActive
      MessageRequester("Settings Saved", "Settings saved. DbPath will apply after stopping indexing.", #PB_MessageRequester_Info)
    Else
      MessageRequester("Settings Saved", "Settings have been saved successfully.", #PB_MessageRequester_Info)
    EndIf
  EndIf
EndProcedure

Procedure OpenContainingFolder(filePath.s, showError.i)
  Protected args.s
  Protected pathType.i

  If filePath = ""
    ProcedureReturn
  EndIf

  pathType = FileSize(filePath)
  If pathType = -2
    OpenPath(filePath, showError)
    ProcedureReturn
  EndIf

  args = "/select," + Chr(34) + filePath + Chr(34)
  If RunProgram("explorer.exe", args, "") = 0 And showError
    MessageRequester(#APP_NAME, "Failed To open Explorer For:" + #CRLF$ + filePath, #PB_MessageRequester_Error)
  EndIf
EndProcedure

Procedure OpenDbFolder(showError.i)
  Protected dbPath.s
  Protected folder.s
  Protected args.s

  dbPath = ResolveDbPath(IndexDbPath)
  LogLine("OpenDbFolder dbPath=" + dbPath)
  folder = GetPathPart(dbPath)
  If folder = ""
    folder = AppPath
  EndIf

  If FileSize(dbPath) >= 0
    args = "/select," + Chr(34) + dbPath + Chr(34)
    If RunProgram("explorer.exe", args, "") = 0 And showError
      MessageRequester(#APP_NAME, "Failed To open Explorer for:" + #CRLF$ + dbPath, #PB_MessageRequester_Error)
    EndIf
  Else
    If RunProgram("explorer.exe", folder, "") = 0 And showError
      MessageRequester(#APP_NAME, "Index DB does not exist yet." + #CRLF$ +
                                  "Expected path: " + dbPath + #CRLF$ +
                                  "Tried opening folder: " + folder, #PB_MessageRequester_Error)
    EndIf
  EndIf
EndProcedure

Procedure ShowDiagnostics()
  Protected msg.s
  Protected dbPath.s
  Protected iniPath.s
  Protected crashLogPath.s
  Protected qc.i
  Protected ac.i
  Protected wc.i
  Protected paused.i
  Protected exDirCount.i
  Protected exFileCount.i
  Protected exPathCount.i
  Protected hasWindows.i

  dbPath = ResolveDbPath(IndexDbPath)
  LogLine("ShowDiagnostics dbPath=" + dbPath)
  iniPath = GetConfigPath()
  crashLogPath = CrashLogPath
  If crashLogPath = ""
    crashLogPath = ChooseCrashLogPath()
  EndIf

  If ExcludeMutex : LockMutex(ExcludeMutex) : EndIf
  exDirCount = MapSize(ExcludeDirNames())
  exFileCount = MapSize(ExcludeFileNames())
  hasWindows = Bool(FindMapElement(ExcludeDirNames(), "windows") <> 0)
  exPathCount = MapSize(ExcludePathPrefixes())
  If ExcludeMutex : UnlockMutex(ExcludeMutex) : EndIf

  If ScanStateMutex
    LockMutex(ScanStateMutex)
    qc = QueueCount
    ac = ActiveDirCount
    UnlockMutex(ScanStateMutex)
  EndIf
  wc = WorkerCount
  paused = IndexingPaused

  msg = "INI path: " + iniPath + #CRLF$ +
        "Crash log path: " + crashLogPath + #CRLF$ +
        "ExcludeDirs: " + Str(exDirCount) + " (has 'windows': " + Str(hasWindows) + ")" + #CRLF$ +
        "ExcludeFiles: " + Str(exFileCount) + #CRLF$ +
        "ExcludePaths: " + Str(exPathCount) + #CRLF$ +
        "DB path: " + dbPath + #CRLF$ +
        "DB open: " + Str(Bool(IndexDbId <> 0)) + #CRLF$ +
        "IndexingActive: " + Str(IndexingActive) + #CRLF$ +
        "IndexingPaused: " + Str(paused) + #CRLF$ +
        "WorkerCount: " + Str(wc) + #CRLF$ +
        "QueueCount: " + Str(qc) + #CRLF$ +
        "ActiveDirCount: " + Str(ac) + #CRLF$ +
        "FilesScanned: " + Str(FilesScanned) + #CRLF$ +
        "DirsScanned: " + Str(DirsScanned) + #CRLF$ +
        "IndexTotalFiles: " + Str(IndexTotalFiles)

  MessageRequester(#APP_NAME + " Diagnostics", msg, #PB_MessageRequester_Info)
EndProcedure

Procedure StopIndexingAndWait()
  If IndexThread
    RequestIndexStop()
    WaitThread(IndexThread)
    IndexThread = 0
  EndIf
EndProcedure

Procedure StartIndexing(rebuild.i)
  Protected *params.SearchParams

  LogLine("StartIndexing rebuild=" + Str(rebuild))

  If rebuild = 0 And IndexingActive
    ProcedureReturn
  EndIf

  StopIndexingAndWait()

  If rebuild
    If RebuildIndexDatabase() = #False
      SetIndexingActive(#False)
      UpdateControlStates()
      ProcedureReturn
    EndIf

    QueryDirty = 1
    QueryNextAtMS = ElapsedMilliseconds()
  EndIf

  StopIndexingRequested = 0
  WorkStop = 0

  *params = AllocateStructure(SearchParams)
  If *params = 0
    ProcedureReturn
  EndIf

  SetIndexingActive(#True)
  SetIndexingPaused(#False)
  UpdateControlStates()

  IndexThread = CreateThread(@IndexThreadProc(), *params)
  If IndexThread = 0
    SetIndexingActive(#False)
    UpdateControlStates()
    MessageRequester(#APP_NAME, "Failed to create index thread." + #CRLF$ +
                                "This EXE must be compiled with threading enabled.", #PB_MessageRequester_Error)
    FreeStructure(*params)
  EndIf
EndProcedure
