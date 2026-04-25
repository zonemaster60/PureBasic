; Declarations, constants, and globals

#APP_NAME   = "HandySearch"
#EMAIL_NAME = "zonemaster60@gmail.com"
Global version.s = "v1.0.1.7"

; Crash logging (best-effort)
Declare InitCrashLogging()
Declare LogLine(msg.s)
Declare CrashErrorHandler()

Structure IndexRecord
  Path.s
  Name.s
  Dir.s
  Size.q
  MTime.q
  IsDir.i
  ScanId.q
EndStructure

Structure SearchParams
  Directory.s
  Pattern.s
  IncludeContent.i
  UseRegex.i
  UseFuzzy.i
EndStructure

Structure WorkerParams
  Dummy.i
EndStructure

Procedure.b HasArg(arg$)
  Protected i
  For i = 1 To CountProgramParameters()
    If LCase(ProgramParameter(i - 1)) = LCase(arg$)
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

Global gInstallStartupTaskMode.i = HasArg("--installstartup")
Global gRemoveStartupTaskMode.i  = HasArg("--removestartup")

Global AppPath.s = GetPathPart(ProgramFilename())
Global ConfigIniPath.s
Global CrashLogPath.s
Global CrashLogInHandler.i
Global gLastExecExitCode.i

; Forward declarations (avoid ordering issues)
; Startup/OS integration
Declare.i OpenCrashLogFile(filePath.s)
Declare.s ChooseCrashLogPath()
Declare.s RunAndCapture(exe.s, args.s)
Declare.i IsInStartup()
Declare.i AddToStartup()
Declare.i RemoveFromStartup()
Declare RemoveLegacyStartupRegistryEntry()
Declare.s NormalizePath(path.s)
Declare.i EnsureDirectoryTree(dirPath.s)
Declare.i EnsureParentDirectoryForFile(filePath.s)
Declare.s GetWritableAppDataFolder()

; Config/INI
Declare ClearExcludes()
Declare.i IsExcludedFileName(fileName.s)
Declare.i IsExcludedDirName(dirName.s)
Declare.i IsExcludedPathPrefix(path.s)
Declare WriteDefaultExcludesIni(filePath.s)
Declare ClampConfigValues()
Declare LoadExcludesIni(filePath.s)
Declare SaveIniKey(filePath.s, sectionName.s, keyName.s, value.s)
Declare SaveSettingsIni()
Declare.s GetConfigPath()

; Database layer
Declare.s ResolveDbPath(dbPath.s)
Declare InitDatabase()
Declare.q GetIndexedCountFast()
Declare.i ExecDb(sql.s)
Declare.i ExecDbLocked(sql.s)
Declare.q GetIndexedCountCached()
Declare SetIndexedCount(count.q)
Declare FlushIndexBatchToDb(List batch.IndexRecord())
Declare FinalizeCompletedScan()
Declare.b RebuildIndexDatabase()

; Search query engine
Declare.b IsMatchAllQuery(query.s)
Declare.s QueryToLikePattern(query.s)
Declare.s ParseRegexQueryPattern(query.s, *ignoreCase.Integer)
Declare.s RegexLiteralHint(pattern.s)
Declare RefreshResultsFromDb(query.s)

; Indexing pipeline
Declare EnqueueResult(path.s)
Declare EnqueueResultsBatch(List batch.s())
Declare.i PendingResultsCount()
Declare DbWriterThreadProc(dummy.i)
Declare IndexThreadProc(*params.SearchParams)

; Actions/settings
Declare.b ConfirmExit()
Declare.s SelectedResultPath()
Declare OpenPath(path.s, showError.i)
Declare OpenConfig(showError.i)
Declare OpenCrashLog(showError.i)
Declare WebSearch(showError.i)
Declare EditExcludeLists()
Declare EditSettings()
Declare OpenContainingFolder(filePath.s, showError.i)
Declare OpenDbFolder(showError.i)
Declare ShowDiagnostics()
Declare StopIndexingAndWait()
Declare StartIndexing(rebuild.i)
Declare SetIndexingActive(active.i)
Declare SetIndexingPaused(paused.i)
Declare RequestIndexStop()

; UI shell/events
Declare SyncUiState()
Declare UpdateStartupMenuState()
Declare UpdateControlStates()
Declare RequestUiStateSync()
Declare.i GetFileIconIndex(path.s)
Declare ResizeMainWindow()
Declare SetCompactMode(enable.i)
Declare InitGUI()
Declare ToggleMainWindow()
Declare PumpPendingResults(maxItems.i)
Declare MainLoop()

; === Constants and Globals ===
#Window_Main = 0
#Menu_Main = 0
#Menu_ResultsPopup = 1
#Menu_TrayPopup = 2
#Gadget_SearchBar = 1
#Gadget_ResultsList = 2
#Timer_PumpResults = 1
#StatusBar_Main = 0

; Main menu actions
#Menu_OpenFile = 100
#Menu_OpenFolder = 101
#Menu_StartSearchShortcut = 102
#Menu_Index_StartResume = 299
#Menu_Index_Rebuild = 300
#Menu_Index_Stop = 301
#Menu_Index_PauseResume = 306
#Menu_App_RunAtStartup = 309
#Menu_App_EditExcludes = 315
#Menu_Tools_Settings = 302
#Menu_Tools_OpenIni = 310
#Menu_Tools_Web = 303
#Menu_View_Compact = 307
#Menu_View_LiveMatchFullPath = 308
#Menu_Help_About = 304
#Menu_File_Exit = 305

; System tray
#SysTray_Main = 1
#Menu_Tray_ShowHide = 200
#Menu_Tray_RebuildIndex = 201
#Menu_Tray_OpenDbFolder = 203
#Menu_Tray_ShowIndexedCount = 204
#Menu_Tray_ShowDbPath = 205
#Menu_Tray_Diagnostics = 206
#Menu_Tray_OpenCrashLog = 212
#Menu_Tray_PauseResume = 207
#Menu_Tray_RunAtStartup = 208
#Menu_Tray_Settings = 211
#Menu_Tray_Exit = 202

#Open_ShowError = 1
#Open_Silent = 0

Global IndexThread.i
Global StopIndexingRequested.i
Global ResultMutex.i
Global ProgressMutex.i
Global ExcludeMutex.i

; System tray + window behavior
Global AppStartMinimized.i = 0
Global AppCloseToTray.i = 1
Global AppMinimizeToTray.i = 1
Global AppRunAtStartup.i = 0
Global AppAutoStartIndex.i = 0
Global AppCompactMode.i = 0

; Global state
Global IndexingActive.i
Global IndexingPaused.i
Global IndexPauseEvent.i ; event handle for worker pause
Global PendingUiStateSync.i
Global LastTrayTooltip.s
Global LastQueryText.s
Global QueryDirty.i
Global QueryNextAtMS.i
Global LiveMatcherMode.i ; 0=contains, 1=wildcard, 2=regex
Global LiveMatcherNeedle.s
Global LiveMatcherRegexID.i
Global LiveMatchFullPath.i = 1

; Stats
Global FilesScanned.q
Global DirsScanned.q
Global IndexTotalFiles.q
Global CurrentFolder.s

; Database/Index Config
#INI_FILE = "HandySearch.ini"
Global IndexDbPath.s = "HandySearch.db"
Global IndexDbId.i
Global DbMutex.i
Global SearchMaxResults.i = 10000
Global SearchDebounceMS.i = 120
Global ConfigThreadCount.i = 0
Global ConfigBatchSize.i = 200
Global CurrentScanId.q

; Global state duplicates removed
Global CompactSavedW.i = 0
Global CompactSavedH.i = 0
Global CompactSavedX.i = 0
Global CompactSavedY.i = 0

; SQLite index + query settings
Global CachedIndexedCount.q = -1
Global CachedIndexedCountAtMS.q

; Global reparse point tracking to prevent loops
Global NewMap VisitedFolders.i()
Global VisitedFoldersMutex.i

; Icon management
Global NewMap IconCache.i()
Global IconMutex.i

; Live incremental results (from worker threads -> UI)
Global NewMap LiveShownPaths.i() ; path -> 1 (GUI thread only)

; Tray icon handle when using embedded EXE icon
Global TrayIconHandle.i

; Search worker pool (used for indexing)
Global ScanStateMutex.i
Global DirQueueSem.i
Global NewList DirQueue.s()
Global QueueCount.i
Global ActiveDirCount.i
Global WorkStop.i
Global WorkerCount.i
Global Dim WorkerThreads.i(0)

; DB Writer thread objects
Global DbWriterThread.i
Global DbWriterStop.i
Global DbWriterQueueMutex.i
Global DbWriterQueueSem.i
Global NewList DbWriterQueue.IndexRecord()

Global NewList PendingResults.s()
Global NewMap ExcludeDirNames.i()
Global NewMap ExcludeFileNames.i()
Global NewMap ExcludePathPrefixes.i()

Global hMutex.i

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 4
; Folding = -
; EnableXP
; DPIAware