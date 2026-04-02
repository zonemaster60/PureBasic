; UI event handling and timer-driven UI updates

Procedure PumpPendingResults(maxItems.i)
  Protected folder.s, files.q, dirs.q
  Protected now.i = ElapsedMilliseconds()
  Protected pulled.i
  Protected path.s
  Protected query.s
  Protected ignoreCase.i
  Protected regexPattern.s
  Protected trayTip.s
  Protected testSubject.s
  Protected pathImg.i
  Protected defImg.i

  If IndexingActive
    SetWindowTitle(#Window_Main, #APP_NAME + " - indexing...")
    trayTip = #APP_NAME + " - indexing"
  Else
    trayTip = #APP_NAME + " - ready"
  EndIf

  If trayTip <> "" And trayTip <> LastTrayTooltip
    SysTrayIconToolTip(#SysTray_Main, trayTip)
    LastTrayTooltip = trayTip
  EndIf

  If QueryDirty And now >= QueryNextAtMS
    QueryDirty = 0
    LastQueryText = GetGadgetText(#Gadget_SearchBar)
    ClearMap(LiveShownPaths())

    If LiveMatcherRegexID
      FreeRegularExpression(LiveMatcherRegexID)
      LiveMatcherRegexID = 0
    EndIf

    query = Trim(LastQueryText)
    ignoreCase = 1
    regexPattern = ParseRegexQueryPattern(query, @ignoreCase)

    If IsMatchAllQuery(query)
      LiveMatcherMode = 0
      LiveMatcherNeedle = ""
    ElseIf regexPattern <> "" And Trim(regexPattern) <> ""
      LiveMatcherMode = 2
      If ignoreCase
        LiveMatcherRegexID = CreateRegularExpression(#PB_Any, regexPattern, #PB_RegularExpression_NoCase)
      Else
        LiveMatcherRegexID = CreateRegularExpression(#PB_Any, regexPattern)
      EndIf
      If LiveMatcherRegexID = 0
        LiveMatcherMode = 0
      EndIf
    Else
      If FindString(query, "*", 1) Or FindString(query, "?", 1)
        LiveMatcherMode = 1
        regexPattern = WildcardToRegex(query)
        LiveMatcherRegexID = CreateRegularExpression(#PB_Any, regexPattern, #PB_RegularExpression_NoCase)
        If LiveMatcherRegexID = 0
          LiveMatcherMode = 0
        EndIf
      Else
        LiveMatcherMode = 0
        LiveMatcherNeedle = LCase(query)
      EndIf
    EndIf

    RefreshResultsFromDb(LastQueryText)
  EndIf

  If ResultMutex
    LockMutex(ResultMutex)
    While pulled < maxItems And FirstElement(PendingResults())
      path = PendingResults()
      DeleteElement(PendingResults())
      pulled + 1

      If FindMapElement(LiveShownPaths(), path) = 0
        If CountGadgetItems(#Gadget_ResultsList) >= SearchMaxResults
          Continue
        EndIf

        LiveShownPaths(path) = 1

        If LiveMatchFullPath
          testSubject = LCase(path)
        Else
          testSubject = LCase(GetFilePart(path))
        EndIf

        Select LiveMatcherMode
          Case 2, 1
            If LiveMatcherRegexID And MatchRegularExpression(LiveMatcherRegexID, testSubject)
              pathImg = GetFileIconIndex(path)
              If pathImg
                AddGadgetItem(#Gadget_ResultsList, -1, path, ImageID(pathImg))
              Else
                AddGadgetItem(#Gadget_ResultsList, -1, path)
              EndIf
            EndIf

          Default
            If LiveMatcherNeedle = "" Or FindString(testSubject, LiveMatcherNeedle, 1)
              defImg = GetFileIconIndex(path)
              If defImg
                AddGadgetItem(#Gadget_ResultsList, -1, path, ImageID(defImg))
              Else
                AddGadgetItem(#Gadget_ResultsList, -1, path)
              EndIf
            EndIf
        EndSelect
      EndIf
    Wend
    UnlockMutex(ResultMutex)
  EndIf

  If ProgressMutex
    LockMutex(ProgressMutex)
    folder = CurrentFolder
    files = FilesScanned
    dirs = DirsScanned
    UnlockMutex(ProgressMutex)

    If IndexingActive And IndexingPaused = 0
      StatusBarText(#StatusBar_Main, 0, "Indexing: " + folder)
      StatusBarText(#StatusBar_Main, 1, "Dirs: " + Str(dirs) + "  Files: " + Str(files) + "  Indexed: " + Str(IndexTotalFiles))
    ElseIf IndexingActive And IndexingPaused
      StatusBarText(#StatusBar_Main, 0, "Indexing: PAUSED")
      StatusBarText(#StatusBar_Main, 1, "Indexed: " + Str(IndexTotalFiles))
    Else
      StatusBarText(#StatusBar_Main, 0, "Ready")
      If LiveMatcherMode = 2 Or LiveMatcherMode = 1
        StatusBarText(#StatusBar_Main, 1, "Showing: " + Str(CountGadgetItems(#Gadget_ResultsList)) + "  (regex)  Indexed: " + Str(IndexTotalFiles))
      Else
        StatusBarText(#StatusBar_Main, 1, "Showing: " + Str(CountGadgetItems(#Gadget_ResultsList)) + "  Indexed: " + Str(IndexTotalFiles))
      EndIf
    EndIf
  EndIf
EndProcedure

Procedure MainLoop()
  Protected event.i
  Protected quit.b
  Protected desiredStartupState.i
  Protected startupOk.i

  Repeat
    event = WaitWindowEvent()
    Select event
      Case #PB_Event_CloseWindow
        If AppCloseToTray
          HideWindow(#Window_Main, 1)
        ElseIf ConfirmExit()
          quit = #True
        EndIf

      Case #PB_Event_MinimizeWindow
        If AppMinimizeToTray
          HideWindow(#Window_Main, 1)
        EndIf

      Case #PB_Event_SysTray
        Select EventType()
          Case #PB_EventType_LeftClick
            ToggleMainWindow()
          Case #PB_EventType_RightClick
            DisplayPopupMenu(#Menu_TrayPopup, WindowID(#Window_Main))
        EndSelect

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #Gadget_SearchBar
            If EventType() = #PB_EventType_Change
              QueryDirty = 1
              QueryNextAtMS = ElapsedMilliseconds() + SearchDebounceMS
            EndIf

          Case #Gadget_ResultsList
            Select EventType()
              Case #PB_EventType_LeftDoubleClick
                OpenPath(SelectedResultPath(), #Open_Silent)
              Case #PB_EventType_RightClick
                DisplayPopupMenu(#Menu_ResultsPopup, WindowID(#Window_Main))
            EndSelect
        EndSelect

      Case #PB_Event_Menu
        Select EventMenu()
          Case #Menu_StartSearchShortcut
            If GetActiveGadget() = #Gadget_SearchBar
              QueryDirty = 1
              QueryNextAtMS = ElapsedMilliseconds() + SearchDebounceMS
            EndIf

          Case #Menu_OpenFile
            OpenPath(SelectedResultPath(), #Open_ShowError)

          Case #Menu_OpenFolder
            OpenContainingFolder(SelectedResultPath(), #Open_ShowError)

          Case #Menu_Index_StartResume
            StartIndexing(#False)

          Case #Menu_Index_Rebuild
            StartIndexing(#True)

          Case #Menu_Index_PauseResume, #Menu_Tray_PauseResume
            If IndexingActive
              If IndexingPaused
                IndexingPaused = 0
                If IndexPauseEvent : SetEvent_(IndexPauseEvent) : EndIf
              Else
                IndexingPaused = 1
                If IndexPauseEvent : ResetEvent_(IndexPauseEvent) : EndIf
              EndIf
              SyncUiState()
            EndIf

          Case #Menu_Index_Stop
            StopSearch = 1
            WorkStop = 1
            If IndexPauseEvent : SetEvent_(IndexPauseEvent) : EndIf
            IndexingPaused = 0
            SyncUiState()
            If DirQueueSem And WorkerCount > 0
              ReleaseSemaphore_(DirQueueSem, WorkerCount, 0)
            EndIf

          Case #Menu_View_Compact
            SetCompactMode(1 - Bool(AppCompactMode))

          Case #Menu_View_LiveMatchFullPath
            LiveMatchFullPath = 1 - Bool(LiveMatchFullPath)
            If IsMenu(#Menu_Main)
              SetMenuItemState(#Menu_Main, #Menu_View_LiveMatchFullPath, LiveMatchFullPath)
            EndIf
            SaveIniKey(GetConfigPath(), "App", "LiveMatchFullPath", Str(LiveMatchFullPath))
            QueryDirty = 1
            QueryNextAtMS = ElapsedMilliseconds()

          Case #Menu_App_RunAtStartup, #Menu_Tray_RunAtStartup
            desiredStartupState = 1 - Bool(AppRunAtStartup)
            If desiredStartupState
              startupOk = AddToStartup()
            Else
              startupOk = RemoveFromStartup()
            EndIf

            If startupOk
              AppRunAtStartup = desiredStartupState
              SaveIniKey(GetConfigPath(), "App", "RunAtStartup", Str(AppRunAtStartup))
            Else
              MessageRequester(#APP_NAME, "Failed to update the run-at-startup task.", #PB_MessageRequester_Error)
            EndIf
            UpdateStartupMenuState()

          Case #Menu_App_EditExcludes
            EditExcludeLists()

          Case #Menu_Tray_Settings, #Menu_Tools_Settings
            EditSettings()

          Case #Menu_Tools_OpenIni
            OpenConfig(#Open_ShowError)

          Case #Menu_Tools_Web
            WebSearch(#Open_ShowError)

          Case #Menu_Help_About
            MessageRequester("About", #APP_NAME + " - " + version + #CRLF$ +
                                      "For searching your files and/or the web" + #CRLF$ +
                                      "----------------------------------------" + #CRLF$ +
                                      "Contact: zonemaster60@gmail.com" + #CRLF$ +
                                      "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)

          Case #Menu_File_Exit, #Menu_Tray_Exit
            If ConfirmExit()
              quit = #True
            EndIf

          Case #Menu_Tray_ShowHide
            ToggleMainWindow()

          Case #Menu_Tray_RebuildIndex
            StartIndexing(#True)

          Case #Menu_Tray_OpenDbFolder
            OpenDbFolder(#Open_ShowError)

          Case #Menu_Tray_ShowIndexedCount
            MessageRequester(#APP_NAME, "Indexed files: " + Str(GetIndexedCountFast()), #PB_MessageRequester_Info)

          Case #Menu_Tray_ShowDbPath
            MessageRequester(#APP_NAME, "DB path: " + ResolveDbPath(IndexDbPath), #PB_MessageRequester_Info)

          Case #Menu_Tray_Diagnostics
            ShowDiagnostics()

          Case #Menu_Tray_OpenCrashLog
            OpenCrashLog(#Open_ShowError)
        EndSelect

      Case #PB_Event_SizeWindow
        ResizeMainWindow()

      Case #PB_Event_Timer
        If EventTimer() = #Timer_PumpResults
          If PendingUiStateSync
            PendingUiStateSync = #False
            UpdateControlStates()
          EndIf
          PumpPendingResults(50)
          If IndexingActive = 0 And IsWindowVisible_(WindowID(#Window_Main))
            SetWindowTitle(#Window_Main, #APP_NAME + " - " + version + " Desktop")
          EndIf
        EndIf
    EndSelect
  Until quit

  StopIndexingAndWait()
EndProcedure
