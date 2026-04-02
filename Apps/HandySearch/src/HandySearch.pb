; Windows Search Desktop App

EnableExplicit

XIncludeFile "HandySearch.Declarations.pbi"

SetCurrentDirectory(AppPath)

InitCrashLogging()

; Prevent multiple instances (don't rely on window title text)
; Allow helper modes to run even if the GUI app is running.
If gInstallStartupTaskMode = #False And gRemoveStartupTaskMode = #False
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
  If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
    CloseHandle_(hMutex)
    End
  EndIf
EndIf

XIncludeFile "HandySearch.StartupOs.pbi"
XIncludeFile "HandySearch.ConfigIni.pbi"
XIncludeFile "HandySearch.Database.pbi"
XIncludeFile "HandySearch.SearchQuery.pbi"
XIncludeFile "HandySearch.IndexingPipeline.pbi"
XIncludeFile "HandySearch.ActionsSettings.pbi"
XIncludeFile "HandySearch.UiShell.pbi"
XIncludeFile "HandySearch.UiEvents.pbi"

; === Main ===

If gInstallStartupTaskMode
  AddToStartup()
  End
EndIf

If gRemoveStartupTaskMode
  ; Uses elevation relaunch internally if needed.
  RemoveFromStartup()
  End
EndIf

; Best-effort cleanup of any old registry startup entry.
RemoveLegacyStartupRegistryEntry()

ResultMutex = CreateMutex()
ProgressMutex = CreateMutex()
ExcludeMutex = CreateMutex()
DbMutex = CreateMutex()
IconMutex = CreateMutex()
VisitedFoldersMutex = CreateMutex()
DbWriterQueueMutex = CreateMutex()
DbWriterQueueSem = CreateSemaphore_(0, 0, 2147483647, 0)

LoadExcludesIni(GetConfigPath())

; Ensure menu checkmarks reflect INI state.
; Must run after InitGUI() creates the menu.

; Ensure INI state reflects actual Task Scheduler state.
AppRunAtStartup = IsInStartup()
SaveIniKey(GetConfigPath(), "App", "RunAtStartup", Str(AppRunAtStartup))

InitDatabase()

; Initialize cached count from DB meta (fast path).
CachedIndexedCount = -1
CachedIndexedCountAtMS = 0
IndexTotalFiles = GetIndexedCountFast()

InitGUI()

; Apply initial menu states now that the menu exists.
SyncUiState()

; Start query right away.
QueryDirty = 1
QueryNextAtMS = 0

; Optionally start indexing on launch.
If AppAutoStartIndex
  StartIndexing(#False)
EndIf

If AppStartMinimized
  HideWindow(#Window_Main, 1)
EndIf

MainLoop()

If LiveMatcherRegexID : FreeRegularExpression(LiveMatcherRegexID) : LiveMatcherRegexID = 0 : EndIf
If IndexDbId : CloseDatabase(IndexDbId) : EndIf
If ResultMutex : FreeMutex(ResultMutex) : EndIf
If ProgressMutex : FreeMutex(ProgressMutex) : EndIf
If ExcludeMutex : FreeMutex(ExcludeMutex) : EndIf
If DbMutex : FreeMutex(DbMutex) : EndIf
If IconMutex : FreeMutex(IconMutex) : EndIf
If VisitedFoldersMutex : FreeMutex(VisitedFoldersMutex) : EndIf
If DbWriterQueueMutex : FreeMutex(DbWriterQueueMutex) : EndIf
If DbWriterQueueSem : CloseHandle_(DbWriterQueueSem) : EndIf
If ScanStateMutex : FreeMutex(ScanStateMutex) : EndIf
If DirQueueSem : CloseHandle_(DirQueueSem) : EndIf
If IndexPauseEvent : CloseHandle_(IndexPauseEvent) : EndIf
If TrayIconHandle : DestroyIcon_(TrayIconHandle) : TrayIconHandle = 0 : EndIf
If hMutex : CloseHandle_(hMutex) : EndIf

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 6
; Folding = ----------------
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; UseIcon = HandySearch.ico
; Executable = ..\HandySearch.exe
; IncludeVersionInfo
; VersionField0 = 1,0,1,6
; VersionField1 = 1,0,1,6
; VersionField2 = ZoneSoft
; VersionField3 = HandySearch
; VersionField4 = 1.0.1.6
; VersionField5 = 1.0.1.6
; VersionField6 = Everything-like search tool for desktop and web
; VersionField7 = HandySearch
; VersionField8 = HandySearch.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
