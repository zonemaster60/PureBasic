; Launch flows, UI helpers, and application window.

Procedure ResetLaunchState()
  ClearMap(LaunchBaseline())
  LaunchGame\Name = ""
  LaunchGame\ExePath = ""
  LaunchGame\Args = ""
  LaunchGame\WorkDir = ""
  LaunchGame\Priority = 0
  LaunchGame\Affinity = 0
  LaunchGame\Services = ""
  LaunchGame\LaunchMode = 0
  LaunchGame\SteamAppId = 0
  LaunchGame\SteamExe = ""
  LaunchGame\SteamClientArgs = ""
  LaunchGame\SteamGameArgs = ""
  LaunchGame\SteamDetectTimeoutMs = 0
  LaunchGame\GameRoot = ""
  LaunchGame\Preset = #PRESET_BALANCED
  LaunchGame\PowerMode = #POWERMODE_HIGH
  LaunchGame\OptimizeBackground = 1
  LaunchGame\Notes = ""
  LaunchGame\Tags = ""
  LaunchGame\LaunchCount = 0
  LaunchGame\LastPlayed = 0
  LaunchGame\LastDurationSec = 0
  LaunchCtx\PrevPowerGuid = ""
  LaunchCtx\AppliedPowerGuid = ""
  LaunchCtx\DidSwitchPower = 0
  LaunchCtx\StoppedServices = ""
  LaunchProcess = 0
  LaunchDetectDeadline = 0
  LaunchOrigPriority = 0
  LaunchProcessAffinity = 0
  LaunchSystemAffinity = 0
  LaunchGotAffinity = 0
  LaunchGameRoot = ""
  LaunchState = 0
  LaunchActive = 0
  LaunchStartedAt = 0
  ClearMap(LaunchTunedPriority())
  ClearMap(LaunchTunedName())
EndProcedure

Procedure CopyLaunchGame(*src.GameEntry)
  LaunchGame\Name = *src\Name
  LaunchGame\ExePath = *src\ExePath
  LaunchGame\Args = *src\Args
  LaunchGame\WorkDir = *src\WorkDir
  LaunchGame\Priority = *src\Priority
  LaunchGame\Affinity = *src\Affinity
  LaunchGame\Services = *src\Services
  LaunchGame\LaunchMode = *src\LaunchMode
  LaunchGame\SteamAppId = *src\SteamAppId
  LaunchGame\SteamExe = *src\SteamExe
  LaunchGame\SteamClientArgs = *src\SteamClientArgs
  LaunchGame\SteamGameArgs = *src\SteamGameArgs
  LaunchGame\SteamDetectTimeoutMs = *src\SteamDetectTimeoutMs
  LaunchGame\GameRoot = *src\GameRoot
  LaunchGame\Preset = *src\Preset
  LaunchGame\PowerMode = *src\PowerMode
  LaunchGame\OptimizeBackground = *src\OptimizeBackground
  LaunchGame\Notes = *src\Notes
  LaunchGame\Tags = *src\Tags
  LaunchGame\LaunchCount = *src\LaunchCount
  LaunchGame\LastPlayed = *src\LastPlayed
  LaunchGame\LastDurationSec = *src\LastDurationSec
EndProcedure

Procedure.i ShouldTuneBackgroundProcess(exePath.s, gameExePath.s, gameRoot.s)
  Protected pathLower.s
  Protected fileLower.s
  Protected selfExe.s = LCase(ProgramFilename())

  exePath = CollapseBackslashes(exePath)
  If exePath = ""
    ProcedureReturn 0
  EndIf

  pathLower = LCase(exePath)
  fileLower = LCase(GetFilePart(exePath))
  gameExePath = LCase(CollapseBackslashes(gameExePath))
  gameRoot = LCase(EnsureTrailingSlash(CollapseBackslashes(gameRoot)))

  If pathLower = selfExe
    ProcedureReturn 0
  EndIf
  If gameExePath <> "" And pathLower = gameExePath
    ProcedureReturn 0
  EndIf
  If gameRoot <> "" And StartsWithNoCase(pathLower, gameRoot)
    ProcedureReturn 0
  EndIf
  If FindString(pathLower, "\\windows\\", 1)
    ProcedureReturn 0
  EndIf
  If FindString(pathLower, "\\program files\\windowsapps\\", 1)
    ProcedureReturn 0
  EndIf

  Select fileLower
    Case "explorer.exe", "dwm.exe", "taskmgr.exe", "steam.exe", "gameoverlayui.exe", "steamwebhelper.exe", "discord.exe", "teams.exe", "searchhost.exe", "startmenuexperiencehost.exe", "shellexperiencehost.exe", "audiodg.exe", "msedgewebview2.exe"
      ProcedureReturn 0
  EndSelect

  If FindString(fileLower, "anticheat", 1) Or FindString(fileLower, "battleye", 1) Or FindString(fileLower, "easyanticheat", 1)
    ProcedureReturn 0
  EndIf
  If FindString(fileLower, "nvidia", 1) Or FindString(fileLower, "radeon", 1) Or FindString(fileLower, "rtss", 1) Or FindString(fileLower, "obs", 1)
    ProcedureReturn 0
  EndIf
  If FindString(fileLower, "vpn", 1) Or FindString(fileLower, "audio", 1)
    ProcedureReturn 0
  EndIf

  ProcedureReturn 1
EndProcedure

Procedure TuneBackgroundProcesses(*g.GameEntry)
  Protected snap.i
  Protected pe.OC_PROCESSENTRY32
  Protected pid.i, hProc.i
  Protected exePath.s
  Protected currentPriority.l
  Protected gameRoot.s

  ClearMap(LaunchTunedPriority())
  ClearMap(LaunchTunedName())

  If *g\OptimizeBackground = 0
    ProcedureReturn
  EndIf

  gameRoot = *g\GameRoot
  If *g\LaunchMode = 1 And gameRoot = ""
    gameRoot = ResolveSteamGameRoot(*g)
  EndIf

  snap = CreateToolhelp32Snapshot_(#TH32CS_SNAPPROCESS, 0)
  If snap = -1
    ProcedureReturn
  EndIf

  pe\dwSize = SizeOf(OC_PROCESSENTRY32)
  If Process32First_(snap, @pe)
    Repeat
      pid = pe\th32ProcessID
      If pid <> GetCurrentProcessId_()
        exePath = GetMainModulePath(pid)
        If ShouldTuneBackgroundProcess(exePath, *g\ExePath, gameRoot)
          hProc = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_SET_INFORMATION, #False, pid)
          If hProc = 0
            hProc = OpenProcess_(#PROCESS_QUERY_LIMITED_INFORMATION | #PROCESS_SET_INFORMATION, #False, pid)
          EndIf
          If hProc
            currentPriority = GetPriorityClass_(hProc)
            If currentPriority = #NORMAL_PRIORITY_CLASS Or currentPriority = #ABOVE_NORMAL_PRIORITY_CLASS Or currentPriority = #HIGH_PRIORITY_CLASS
              If SetPriorityClass_(hProc, #BELOW_NORMAL_PRIORITY_CLASS)
                LaunchTunedPriority(Str(pid)) = currentPriority
                LaunchTunedName(Str(pid)) = GetFilePart(exePath)
              EndIf
            EndIf
            CloseHandle_(hProc)
          EndIf
        EndIf
      EndIf
    Until Process32Next_(snap, @pe) = 0
  EndIf
  CloseHandle_(snap)

  If MapSize(LaunchTunedPriority()) > 0
    LogLine("Background optimizer tuned " + Str(MapSize(LaunchTunedPriority())) + " process(es)")
  EndIf
EndProcedure

Procedure RestoreBackgroundProcesses()
  Protected pid.s
  Protected hProc.i

  ForEach LaunchTunedPriority()
    pid = MapKey(LaunchTunedPriority())
    hProc = OpenProcess_(#PROCESS_SET_INFORMATION, #False, Val(pid))
    If hProc = 0
      hProc = OpenProcess_(#PROCESS_QUERY_LIMITED_INFORMATION | #PROCESS_SET_INFORMATION, #False, Val(pid))
    EndIf
    If hProc
      SetPriorityClass_(hProc, LaunchTunedPriority())
      CloseHandle_(hProc)
    EndIf
  Next

  If MapSize(LaunchTunedPriority()) > 0
    LogLine("Background optimizer restored " + Str(MapSize(LaunchTunedPriority())) + " process(es)")
  EndIf
  ClearMap(LaunchTunedPriority())
  ClearMap(LaunchTunedName())
EndProcedure

Procedure.s BackgroundOptimizationLabel(enabled.i)
  If enabled
    ProcedureReturn "enabled"
  EndIf
  ProcedureReturn "disabled"
EndProcedure

Procedure.i ThumbnailImageForGame(*g.GameEntry)
  Protected key.s = GameIdentity(*g) + ":" + Str(*g\Preset) + ":" + Str(ThumbnailSize)
  Protected img.i
  Protected bg.i, fg.i = RGB(255, 255, 255)
  Protected label.s

  If FindMapElement(GameThumbnail(), key)
    ProcedureReturn GameThumbnail()
  EndIf

  If *g\LaunchMode = 1
    EnsureSteamArtwork(*g\SteamAppId)
    img = LoadImage(#PB_Any, SteamArtworkPath(*g\SteamAppId))
    If img
      GameThumbnail(key) = img
      ProcedureReturn img
    EndIf
  EndIf

  If *g\LaunchMode = 0 And *g\ExePath <> ""
    img = IconThumbnailFromPath(*g\ExePath, ThumbnailSize)
    If img
      GameThumbnail(key) = img
      ProcedureReturn img
    EndIf
  EndIf

  img = CreateImage(#PB_Any, ThumbnailSize, ThumbnailSize, 32, RGB(220, 220, 220))
  If img = 0
    ProcedureReturn 0
  EndIf

  Select *g\Preset
    Case #PRESET_SAFE
      bg = RGB(46, 125, 50)
      label = "S"
    Case #PRESET_AGGRESSIVE
      bg = RGB(183, 28, 28)
      label = "A"
    Default
      bg = RGB(25, 118, 210)
      label = "B"
  EndSelect

  If StartDrawing(ImageOutput(img))
    Box(0, 0, ThumbnailSize, ThumbnailSize, bg)
    DrawingMode(#PB_2DDrawing_Transparent)
    If FontSmall
      DrawingFont(FontID(FontSmall))
    EndIf
    DrawText(4, 1, label, fg)
    StopDrawing()
  EndIf

  GameThumbnail(key) = img
  ProcedureReturn img
EndProcedure

Procedure.s SteamArtworkPath(appId.i)
  If FileSize(ArtworkDir) <> -2
    CreateDirectory(ArtworkDir)
  EndIf
  ProcedureReturn ArtworkDir + Str(appId) + ".jpg"
EndProcedure

Procedure EnsureSteamArtwork(appId.i)
  Protected path.s, url.s
  If appId <= 0
    ProcedureReturn
  EndIf
  path = SteamArtworkPath(appId)
  If FileSize(path) > 0
    ProcedureReturn
  EndIf
  url = "https://cdn.cloudflare.steamstatic.com/steam/apps/" + Str(appId) + "/library_600x900_2x.jpg"
  ReceiveHTTPFile(url, path)
EndProcedure

Procedure.i IconThumbnailFromPath(exePath.s, size.i)
  ProcedureReturn 0
EndProcedure

Procedure.i GameIndexFromVisibleIndex(visibleIdx.i)
  Protected i.i
  If visibleIdx < 0 Or visibleIdx >= ListSize(VisibleGameIndex())
    ProcedureReturn -1
  EndIf
  i = 0
  ForEach VisibleGameIndex()
    If i = visibleIdx
      ProcedureReturn VisibleGameIndex()
    EndIf
    i + 1
  Next
  ProcedureReturn -1
EndProcedure

Procedure.i VisibleIndexFromGameIndex(gameIdx.i)
  Protected i.i
  i = 0
  ForEach VisibleGameIndex()
    If VisibleGameIndex() = gameIdx
      ProcedureReturn i
    EndIf
    i + 1
  Next
  ProcedureReturn -1
EndProcedure

Procedure SetLaunchUiState(active.i, statusText.s = "")
  Protected pulse.s

  DisableGadget(#G_Tool_Add, active)
  DisableGadget(#G_Tool_BrowseExe, active)
  DisableGadget(#G_Tool_AddFolder, active)
  DisableGadget(#G_Tool_ImportSteamGame, active)
  DisableGadget(#G_OpenFolder, active)
  DisableGadget(#G_MoveUp, active)
  DisableGadget(#G_MoveDown, active)
  DisableGadget(#G_Remove, active)
  DisableGadget(#G_Edit, active)
  DisableGadget(#G_Launch, active)
  DisableGadget(#G_List, active)
  If IsGadget(#G_CancelWait)
    DisableGadget(#G_CancelWait, Bool(active = 0 Or LaunchState <> 1))
  EndIf

  If IsMenu(#Menu_Main)
    DisableMenuItem(#Menu_Main, #MI_File_Add, active)
    DisableMenuItem(#Menu_Main, #MI_File_BrowseExe, active)
    DisableMenuItem(#Menu_Main, #MI_File_AddFolder, active)
    DisableMenuItem(#Menu_Main, #MI_File_ImportSteamGame, active)
    DisableMenuItem(#Menu_Main, #MI_Game_Run, active)
    DisableMenuItem(#Menu_Main, #MI_Game_Edit, active)
    DisableMenuItem(#Menu_Main, #MI_Game_MoveUp, active)
    DisableMenuItem(#Menu_Main, #MI_Game_MoveDown, active)
    DisableMenuItem(#Menu_Main, #MI_Game_Remove, active)
    DisableMenuItem(#Menu_Main, #MI_Game_OpenFolder, active)
  EndIf

  If MainStatusBar And statusText <> ""
    StatusBarText(MainStatusBar, 0, statusText)
  EndIf

  If IsGadget(#G_LaunchState)
    If active
      Select LaunchUiPulse
        Case 0
          pulse = "."
        Case 1
          pulse = ".."
        Default
          pulse = "..."
      EndSelect
      SetGadgetText(#G_LaunchState, "Launch in progress" + pulse + "  " + statusText)
      HideGadget(#G_LaunchState, 0)
    Else
      SetGadgetText(#G_LaunchState, "")
      HideGadget(#G_LaunchState, 1)
    EndIf
  EndIf

  If IsGadget(#G_CancelWait)
    HideGadget(#G_CancelWait, Bool(active = 0 Or LaunchState <> 1))
  EndIf
EndProcedure

Procedure UpdateListHint()
  If IsGadget(#G_Subtitle) = 0
    ProcedureReturn
  EndIf

  If DragGameIndex >= 0
    SetGadgetText(#G_Subtitle, "Drag a game to a new position in the list to reorder it")
  ElseIf Trim(FilterQuery) <> ""
    SetGadgetText(#G_Subtitle, "Showing " + Str(ListSize(VisibleGameIndex())) + " game(s) for '" + FilterQuery + "'")
  ElseIf LibraryView = #LIBRARY_STEAM
    SetGadgetText(#G_Subtitle, "Library: Steam")
  ElseIf LibraryView = #LIBRARY_EXE
    SetGadgetText(#G_Subtitle, "Library: EXE")
  ElseIf LibraryView = #LIBRARY_RECENT
    SetGadgetText(#G_Subtitle, "Library: Recently Played")
  ElseIf LibraryView = #LIBRARY_MOSTPLAYED
    SetGadgetText(#G_Subtitle, "Library: Most Played")
  ElseIf LibraryView = #LIBRARY_TAGGED
    SetGadgetText(#G_Subtitle, "Library: Tagged")
  ElseIf SortMode = #SORT_LAST_PLAYED
    SetGadgetText(#G_Subtitle, "Sorted by last played")
  ElseIf SortMode = #SORT_RUNS_DESC
    SetGadgetText(#G_Subtitle, "Sorted by run count")
  Else
    SetGadgetText(#G_Subtitle, "Safer game launching with Steam support, per-game power profiles, launch history, and service control")
  EndIf
EndProcedure

Procedure CancelPendingLaunch()
  Protected waitMessage.s

  If LaunchActive = 0 Or LaunchState <> 1
    ProcedureReturn
  EndIf

  LogLine("Launch canceled while waiting for Steam game process: " + LaunchGame\Name)
  waitMessage = "Canceled waiting for the Steam game process." + #LF$ + #LF$ +
                "If Steam started successfully, you can retry with a longer detect timeout."
  FinishLaunch(0, waitMessage)
EndProcedure

Procedure FinishLaunch(success.i, message.s = "")
  Protected finalStatus.s
  Protected durationSec.i

  If LaunchProcess
    CloseHandle_(LaunchProcess)
    LaunchProcess = 0
  EndIf

  If message <> ""
    finalStatus = "Launch failed: " + LaunchGame\Name
  ElseIf success
    finalStatus = "Launch finished: " + LaunchGame\Name
  Else
    finalStatus = "Ready"
  EndIf

  If LaunchStartedAt > 0
    durationSec = ElapsedMilliseconds() - LaunchStartedAt
    If durationSec < 0
      durationSec = 0
    EndIf
    durationSec / 1000
  EndIf

  If success
    RecordLaunchResult(@LaunchGame, durationSec)
  EndIf

  RestoreBackgroundProcesses()
  CleanupBoostSession(@LaunchCtx)
  If message <> ""
    LogLine(finalStatus)
  ElseIf success
    LogLine(finalStatus + " | duration=" + FormatDurationSeconds(durationSec))
  EndIf

  SetLaunchUiState(0, finalStatus)
  ResetLaunchState()
  UpdateSelectionUI()

  If message <> "" And AppQuitting = 0
    MessageRequester(#APP_NAME, message)
  ElseIf success
    LogLine("Launch session completed")
  EndIf

  If AppQuitting
    FinalizeApplicationExit()
  EndIf
EndProcedure

Procedure BeginExeLaunch(*g.GameEntry)
  Protected si.STARTUPINFO, pi.PROCESS_INFORMATION
  Protected cmd.s, workdir.s
  Protected *cmdMem

  If IsLaunchActive()
    ProcedureReturn
  EndIf

  CopyLaunchGame(*g)
  workdir = LaunchGame\WorkDir
  If workdir = "" : workdir = GetPathPart(LaunchGame\ExePath) : EndIf
  cmd = QuoteArg(LaunchGame\ExePath)
  If LaunchGame\Args <> "" : cmd + " " + LaunchGame\Args : EndIf

  LogLine("Launch EXE: " + LaunchGame\Name + " | " + CollapseBackslashes(LaunchGame\ExePath))
  PrepareBoostSession(@LaunchGame, @LaunchCtx)

  *cmdMem = AllocateMemory((Len(cmd) + 2) * SizeOf(Character))
  If *cmdMem = 0
    FinishLaunch(0, "Failed to allocate launch command buffer.")
    ProcedureReturn
  EndIf
  PokeS(*cmdMem, cmd, -1)

  si\cb = SizeOf(STARTUPINFO)
  If CreateProcess_(0, *cmdMem, 0, 0, #False, 0, 0, workdir, @si, @pi) = 0
    FreeMemory(*cmdMem)
    FinishLaunch(0, "Failed to launch:" + #LF$ + LaunchGame\ExePath)
    ProcedureReturn
  EndIf
  FreeMemory(*cmdMem)

  LaunchProcess = pi\hProcess
  CloseHandle_(pi\hThread)
  LaunchOrigPriority = GetPriorityClass_(LaunchProcess)
  LaunchGotAffinity  = GetProcessAffinityMask_(LaunchProcess, @LaunchProcessAffinity, @LaunchSystemAffinity)
  ApplyProcessBoost(LaunchProcess, @LaunchGame)
  TuneBackgroundProcesses(@LaunchGame)
  LogLine("Monitoring EXE process for: " + LaunchGame\Name)
  LaunchState = 2
  LaunchActive = 1
  LaunchStartedAt = ElapsedMilliseconds()
  SetLaunchUiState(1, "Running: " + LaunchGame\Name)
EndProcedure

Procedure BeginSteamLaunch(*g.GameEntry)
  Protected si.STARTUPINFO, pi.PROCESS_INFORMATION
  Protected cmd.s, workdir.s
  Protected *cmdMem

  If IsLaunchActive()
    ProcedureReturn
  EndIf

  CopyLaunchGame(*g)
  If LaunchGame\SteamExe = "" Or FileSize(LaunchGame\SteamExe) <= 0
    LaunchGame\SteamExe = FindSteamExe()
  EndIf
  If LaunchGame\SteamExe = "" Or FileSize(LaunchGame\SteamExe) <= 0
    MessageRequester(#APP_NAME, "Steam executable not set/found.")
    ProcedureReturn
  EndIf
  If LaunchGame\SteamAppId <= 0
    MessageRequester(#APP_NAME, "Invalid Steam AppID.")
    ProcedureReturn
  EndIf

  LaunchGameRoot = ResolveSteamGameRoot(@LaunchGame)
  If LaunchGameRoot = ""
    MessageRequester(#APP_NAME, "Could not resolve Steam install folder for this game." + #LF$ + #LF$ +
                              "Try: import the Steam game again so appmanifest_*.acf is available and make sure the game is installed.")
    ProcedureReturn
  EndIf

  LogLine("Launch Steam: " + LaunchGame\Name + " | AppID=" + Str(LaunchGame\SteamAppId))
  PrepareBoostSession(@LaunchGame, @LaunchCtx)
  SnapshotPids(LaunchBaseline())
  LogLine("Waiting for Steam game process in: " + CollapseBackslashes(LaunchGameRoot))

  workdir = GetPathPart(LaunchGame\SteamExe)
  cmd = QuoteArg(LaunchGame\SteamExe)
  If Trim(LaunchGame\SteamClientArgs) <> "" : cmd + " " + Trim(LaunchGame\SteamClientArgs) : EndIf
  cmd + " -applaunch " + Str(LaunchGame\SteamAppId)
  If Trim(LaunchGame\SteamGameArgs) <> "" : cmd + " " + Trim(LaunchGame\SteamGameArgs) : EndIf

  *cmdMem = AllocateMemory((Len(cmd) + 2) * SizeOf(Character))
  If *cmdMem = 0
    FinishLaunch(0, "Failed to allocate Steam launch command buffer.")
    ProcedureReturn
  EndIf
  PokeS(*cmdMem, cmd, -1)

  si\cb = SizeOf(STARTUPINFO)
  If CreateProcess_(0, *cmdMem, 0, 0, #False, 0, 0, workdir, @si, @pi) = 0
    FreeMemory(*cmdMem)
    FinishLaunch(0, "Failed to start Steam.")
    ProcedureReturn
  EndIf
  FreeMemory(*cmdMem)

  CloseHandle_(pi\hThread)
  CloseHandle_(pi\hProcess)
  LaunchDetectDeadline = ElapsedMilliseconds() + ClampSteamDetectTimeout(LaunchGame\SteamDetectTimeoutMs)
  LogLine("Steam game detect timeout: " + Str(ClampSteamDetectTimeout(LaunchGame\SteamDetectTimeoutMs)) + " ms")
  LaunchState = 1
  LaunchActive = 1
  SetLaunchUiState(1, "Waiting for game process: " + LaunchGame\Name)
EndProcedure

Procedure.i LaunchBoosted(*g.GameEntry)
  BeginExeLaunch(*g)
  ProcedureReturn Bool(IsLaunchActive())
EndProcedure

Procedure.i LaunchSteamBoosted(*g.GameEntry)
  BeginSteamLaunch(*g)
  ProcedureReturn Bool(IsLaunchActive())
EndProcedure

Procedure PollLaunchState()
  Protected waitResult.i, pidGame.i, hGame.i

  If LaunchActive = 0
    ProcedureReturn
  EndIf

  LaunchUiPulse = (LaunchUiPulse + 1) % 3
  If LaunchState = 1
    SetLaunchUiState(1, "Waiting for game process: " + LaunchGame\Name)
  ElseIf LaunchState = 2
    SetLaunchUiState(1, "Running: " + LaunchGame\Name)
  EndIf

  Select LaunchState
    Case 1
      pidGame = FindNewProcessInFolderOnce(LaunchGameRoot, LaunchBaseline())
      If pidGame
        LogLine("Detected game PID=" + Str(pidGame))
        hGame = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_SET_INFORMATION | #SYNCHRONIZE, #False, pidGame)
        If hGame = 0
          hGame = OpenProcess_(#PROCESS_QUERY_LIMITED_INFORMATION | #PROCESS_SET_INFORMATION | #SYNCHRONIZE, #False, pidGame)
        EndIf
        If hGame = 0
          FinishLaunch(0, "Detected game PID " + Str(pidGame) + " but could not open process.")
          ProcedureReturn
        EndIf

        LaunchProcess = hGame
        LaunchOrigPriority = GetPriorityClass_(LaunchProcess)
        LaunchGotAffinity  = GetProcessAffinityMask_(LaunchProcess, @LaunchProcessAffinity, @LaunchSystemAffinity)
        ApplyProcessBoost(LaunchProcess, @LaunchGame)
        TuneBackgroundProcesses(@LaunchGame)
        LogLine("Monitoring detected game process for: " + LaunchGame\Name)
        LaunchState = 2
        LaunchStartedAt = ElapsedMilliseconds()
        SetLaunchUiState(1, "Running: " + LaunchGame\Name)
      ElseIf ElapsedMilliseconds() >= LaunchDetectDeadline
        FinishLaunch(0, "Could not detect game process (timeout)." + #LF$ + #LF$ +
                        "Try: re-import Steam metadata for the game and increase the detect timeout.")
      EndIf

    Case 2
      If LaunchProcess = 0
        FinishLaunch(0, "Launch process handle was lost.")
        ProcedureReturn
      EndIf

      waitResult = WaitForSingleObject_(LaunchProcess, 0)
      If waitResult = #WAIT_OBJECT_0
        RestoreProcessBoost(LaunchProcess, LaunchGotAffinity, LaunchOrigPriority, LaunchProcessAffinity)
        FinishLaunch(1)
      EndIf
  EndSelect
EndProcedure

Procedure.s ServicesSummary(csv.s)
  Protected n.i, a.s, b.s
  csv = Trim(csv)
  If csv = "" : ProcedureReturn "" : EndIf
  n = CountString(csv, ",") + 1
  a = Trim(StringField(csv, 1, ","))
  b = Trim(StringField(csv, 2, ","))
  If n = 1 : ProcedureReturn a : EndIf
  If n = 2 : ProcedureReturn a + "," + b : EndIf
  ProcedureReturn a + "," + b + " +" + Str(n - 2)
EndProcedure

Procedure UpdateSelectionUI()
  Protected idxSel.i = GetGadgetState(#G_List)
  Protected gameIdx.i = GameIndexFromVisibleIndex(idxSel)
  Protected canAct.i = Bool(gameIdx >= 0)
  Protected canMoveUp.i = Bool(gameIdx > 0 And FilterQuery = "" And SortMode = #SORT_NAME_ASC And LibraryView = #LIBRARY_ALL)
  Protected canMoveDown.i = Bool(gameIdx >= 0 And gameIdx < ListSize(Games()) - 1 And FilterQuery = "" And SortMode = #SORT_NAME_ASC And LibraryView = #LIBRARY_ALL)
  Protected gg.GameEntry
  Protected detail.s
  If IsLaunchActive()
    canAct = 0
    canMoveUp = 0
    canMoveDown = 0
  EndIf
  DisableGadget(#G_OpenFolder, Bool(canAct = 0))
  DisableGadget(#G_MoveUp, Bool(canMoveUp = 0))
  DisableGadget(#G_MoveDown, Bool(canMoveDown = 0))
  DisableGadget(#G_Remove, Bool(canAct = 0))
  DisableGadget(#G_Edit, Bool(canAct = 0))
  DisableGadget(#G_Launch, Bool(canAct = 0))

  If IsMenu(#Menu_Main)
    DisableMenuItem(#Menu_Main, #MI_Game_Run, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_Edit, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_MoveUp, Bool(canMoveUp = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_MoveDown, Bool(canMoveDown = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_Remove, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_OpenFolder, Bool(canAct = 0))
  EndIf

  If MainStatusBar
    If IsLaunchActive()
        If LaunchState = 1
          StatusBarText(MainStatusBar, 0, "Waiting for game process: " + LaunchGame\Name)
        Else
          StatusBarText(MainStatusBar, 0, "Running: " + LaunchGame\Name + " | BG tuned: " + Str(MapSize(LaunchTunedPriority())))
        EndIf
    ElseIf canAct
      If SelectGameByIndex(gameIdx, @gg)
        detail = "Selected: " + gg\Name + " | Preset: " + FormatPresetLabel(gg\Preset) + " | Power: " + FormatPowerModeLabel(gg\PowerMode)
        If gg\OptimizeBackground
          detail + " | BG: On"
        Else
          detail + " | BG: Off"
        EndIf
        If Trim(gg\Tags) <> ""
          detail + " | Tags: " + gg\Tags
        EndIf
        detail + " | Launches: " + Str(gg\LaunchCount)
        If gg\LastPlayed > 0
          detail + " | Last: " + FormatDate("%yyyy-%mm-%dd", gg\LastPlayed)
        EndIf
        If gg\LastDurationSec > 0
          detail + " | Session: " + FormatDurationSeconds(gg\LastDurationSec)
        EndIf
        StatusBarText(MainStatusBar, 0, detail)
      Else
        StatusBarText(MainStatusBar, 0, "Selected: " + GetGadgetItemText(#G_List, idxSel, 0))
      EndIf
    Else
      StatusBarText(MainStatusBar, 0, "Ready")
    EndIf
  EndIf
  UpdateListHint()
EndProcedure

Procedure OpenSelectedGameFolder(idxSel.i)
  Protected gg.GameEntry
  Protected folder.s
  If idxSel < 0 : ProcedureReturn : EndIf
  If SelectGameByIndex(idxSel, @gg) = 0 : ProcedureReturn : EndIf
  If gg\LaunchMode = 1
    folder = ResolveSteamGameRoot(@gg)
  Else
    folder = gg\WorkDir
    If folder = "" : folder = GetPathPart(gg\ExePath) : EndIf
  EndIf
  folder = EnsureTrailingSlash(folder)
  If folder <> "" And FileSize(folder) = -2
    RunProgram("explorer.exe", #DQUOTE$ + folder + #DQUOTE$, "", #PB_Program_Open)
  ElseIf gg\LaunchMode = 1
    MessageRequester(#APP_NAME, "Could not resolve the Steam install folder for this game.")
  EndIf
EndProcedure

Procedure ShowDiagnostics()
  Enumeration _DiagWindows 6000
    #W_Diag
  EndEnumeration
  Enumeration _DiagGadgets 6100
    #D_Info
    #D_Refresh
    #D_Close
  EndEnumeration

  Protected w.i, ev.i
  Protected info.s
  Protected mem.OC_MEMORYSTATUSEX
  Protected cpu.q

  w = OpenWindow(#W_Diag, 0, 0, 560, 360, "Diagnostics", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If w = 0
    ProcedureReturn
  EndIf

  If IsWindow(0)
    DisableWindow(0, 1)
  EndIf

  EditorGadget(#D_Info, 12, 12, 536, 286)
  SetGadgetAttribute(#D_Info, #PB_Editor_ReadOnly, 1)
  ButtonGadget(#D_Refresh, 356, 314, 90, 30, "Refresh")
  ButtonGadget(#D_Close, 458, 314, 90, 30, "Close")

  If FontUI
    SetGadgetFont(#D_Info, FontID(FontUI))
    SetGadgetFont(#D_Refresh, FontID(FontUI))
    SetGadgetFont(#D_Close, FontID(FontUI))
  EndIf

  Repeat
    mem\dwLength = SizeOf(OC_MEMORYSTATUSEX)
    info = #APP_NAME + " Diagnostics" + #CRLF$ + #CRLF$
    info + "Active power plan: " + CurrentPowerPlanName() + #CRLF$
    info + "Power plan GUID: " + GetActivePowerGuid() + #CRLF$
    cpu = CpuUsagePercent()
    If cpu >= 0
      info + "CPU usage: " + Str(cpu) + "%" + #CRLF$
    Else
      info + "CPU usage: collecting..." + #CRLF$
    EndIf
    If SystemMemoryStatus(@mem)
      info + "Memory load: " + Str(mem\dwMemoryLoad) + "%" + #CRLF$
      info + "Installed RAM: " + FormatBytes(mem\ullTotalPhys) + #CRLF$
      info + "Available RAM: " + FormatBytes(mem\ullAvailPhys) + #CRLF$
    Else
      info + "Memory status: unavailable" + #CRLF$
    EndIf
    If IsLaunchActive()
      info + #CRLF$ + "Current session" + #CRLF$
      info + "Game: " + LaunchGame\Name + #CRLF$
      info + "Preset: " + FormatPresetLabel(LaunchGame\Preset) + #CRLF$
      info + "Power mode: " + FormatPowerModeLabel(LaunchGame\PowerMode) + #CRLF$
      info + "Background optimization: " + BackgroundOptimizationLabel(LaunchGame\OptimizeBackground) + #CRLF$
      info + "Tuned processes: " + Str(MapSize(LaunchTunedPriority())) + #CRLF$
      If MapSize(LaunchTunedName()) > 0
        info + "Process list:" + #CRLF$
        ForEach LaunchTunedName()
          info + "- " + LaunchTunedName() + #CRLF$
        Next
      EndIf
    EndIf
    SetGadgetText(#D_Info, info)

    ev = WaitWindowEvent(1000)
    Select ev
      Case #PB_Event_Gadget
        Select EventGadget()
          Case #D_Refresh
            Continue
          Case #D_Close
            Break
        EndSelect
      Case #PB_Event_CloseWindow
        Break
    EndSelect
  ForEver

  CloseWindow(#W_Diag)
  If IsWindow(0)
    DisableWindow(0, 0)
  EndIf
EndProcedure

Procedure RefreshList()
  Protected meta.s, tagsText.s, notesText.s
  Protected idx.i
  Protected gg.GameEntry
  Protected NewList rows.GameViewRow()
  Protected row.GameViewRow
  Protected inserted.i

  ClearList(VisibleGameIndex())
  ClearGadgetItems(#G_List)
  idx = 0
  ForEach Games()
    gg = Games()
    If MatchesLibraryView(@gg, LibraryView) And MatchesFilter(@gg, FilterQuery)
      meta = FormatPresetLabel(gg\Preset) + " | " + FormatPowerModeLabel(gg\PowerMode)
      If gg\OptimizeBackground
        meta + " | BG On"
      Else
        meta + " | BG Off"
      EndIf
      meta + " | Runs " + Str(gg\LaunchCount)
      If gg\LastPlayed > 0
        meta + " | " + FormatDate("%yyyy-%mm-%dd", gg\LastPlayed)
      EndIf
      If gg\LastDurationSec > 0
        meta + " | " + FormatDurationSeconds(gg\LastDurationSec)
      EndIf

      tagsText = Trim(gg\Tags)
      notesText = Trim(gg\Notes)
      If tagsText <> ""
        tagsText = " [" + tagsText + "]"
      EndIf

      row\SourceIndex = idx
      row\Name = gg\Name
      row\LaunchCount = gg\LaunchCount
      row\LastPlayed = gg\LastPlayed
      If gg\LaunchMode = 1
        row\ItemText = gg\Name + tagsText + Chr(10) + "Steam" + Chr(10) + "AppID " + Str(gg\SteamAppId) + " | " + meta + Chr(10) + ServicesSummary(gg\Services)
      Else
        row\ItemText = gg\Name + tagsText + Chr(10) + "EXE" + Chr(10) + gg\ExePath + " | " + meta + Chr(10) + ServicesSummary(gg\Services)
      EndIf
      If notesText <> ""
        row\ItemText = row\ItemText + " | Note"
      EndIf

      inserted = 0
      ForEach rows()
        Select sortMode
          Case #SORT_LAST_PLAYED
            If row\LastPlayed > rows()\LastPlayed Or (row\LastPlayed = rows()\LastPlayed And LCase(row\Name) < LCase(rows()\Name))
              InsertElement(rows())
              rows() = row
              inserted = 1
              Break
            EndIf
          Case #SORT_RUNS_DESC
            If row\LaunchCount > rows()\LaunchCount Or (row\LaunchCount = rows()\LaunchCount And LCase(row\Name) < LCase(rows()\Name))
              InsertElement(rows())
              rows() = row
              inserted = 1
              Break
            EndIf
          Default
            If LCase(row\Name) < LCase(rows()\Name)
              InsertElement(rows())
              rows() = row
              inserted = 1
              Break
            EndIf
        EndSelect
      Next
      If inserted = 0
        AddElement(rows())
        rows() = row
      EndIf
    EndIf
    idx + 1
  Next

  ForEach rows()
    If SelectGameByIndex(rows()\SourceIndex, @gg)
      AddGadgetItem(#G_List, -1, rows()\ItemText, ImageID(ThumbnailImageForGame(@gg)))
    Else
      AddGadgetItem(#G_List, -1, rows()\ItemText)
    EndIf
    AddElement(VisibleGameIndex())
    VisibleGameIndex() = rows()\SourceIndex
  Next

  For idx = 0 To CountGadgetItems(#G_List) - 1
    If FindString(GetGadgetItemText(#G_List, idx, 2), "Safe", 1)
      SetGadgetItemColor(#G_List, idx, #PB_Gadget_FrontColor, RGB(20, 90, 20))
    ElseIf FindString(GetGadgetItemText(#G_List, idx, 2), "Aggressive", 1)
      SetGadgetItemColor(#G_List, idx, #PB_Gadget_FrontColor, RGB(140, 40, 20))
    Else
      SetGadgetItemColor(#G_List, idx, #PB_Gadget_FrontColor, RGB(30, 30, 120))
    EndIf
  Next

  If IsGadget(#G_Filter)
    If Trim(FilterQuery) <> ""
      SetGadgetText(#G_Subtitle, "Showing " + Str(ListSize(VisibleGameIndex())) + " game(s) for '" + FilterQuery + "'")
    Else
      SetGadgetText(#G_Subtitle, "Showing " + Str(ListSize(VisibleGameIndex())) + " game(s)")
    EndIf
  EndIf

  UpdateSelectionUI()
EndProcedure

Procedure RunApplication()
  Protected launchIdx.i
  Protected selectedLaunchGame.GameEntry
  Protected newIndex.i

  If OpenWindow(0, 0, 0, ScaleX(1080), ScaleY(600), #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
    If CreateMenu(#Menu_Main, WindowID(0))
      MenuTitle("File")
      MenuItem(#MI_File_Add, "Add Game")
      MenuItem(#MI_File_BrowseExe, "Browse EXE")
      MenuItem(#MI_File_AddFolder, "Add Folder")
      MenuItem(#MI_File_ImportSteamGame, "Import Steam Game")
      MenuItem(#MI_File_ImportProfiles, "Import Profiles")
      MenuItem(#MI_File_ExportProfiles, "Export Profiles")
      MenuItem(#MI_File_CreateSnapshot, "Create Snapshot")
      MenuItem(#MI_File_RestoreSnapshot, "Restore Snapshot")
      MenuItem(#MI_File_Undo, "Undo Last Change")
      MenuItem(#MI_File_Redo, "Redo Last Change")
      MenuBar()
      MenuItem(#MI_File_Exit, "Exit")

      MenuTitle("Game")
      MenuItem(#MI_Game_Run, "Run")
      MenuItem(#MI_Game_Edit, "Edit...")
      MenuItem(#MI_Game_MoveUp, "Move Up")
      MenuItem(#MI_Game_MoveDown, "Move Down")
      MenuItem(#MI_Game_Remove, "Remove")
      MenuBar()
      MenuItem(#MI_Game_OpenFolder, "Open Install Folder")

      MenuTitle("Tools")
      MenuItem(#MI_Tools_ViewLog, "View Log")
      MenuItem(#MI_Tools_Diagnostics, "Diagnostics")
      MenuItem(#MI_Tools_History, "History")
      MenuItem(#MI_Tools_Settings, "Settings")

      MenuTitle("Help")
      MenuItem(#MI_Help_Help, "Help")
      MenuItem(#MI_Help_About, "About")
    EndIf

    TextGadget(#G_Title, ScaleX(18), ScaleY(14), ScaleX(1040), ScaleY(30), #APP_NAME)
    TextGadget(#G_Subtitle, ScaleX(18), ScaleY(44), ScaleX(1040), ScaleY(20), "Safer game launching with Steam support, per-game power profiles, launch history, and service control")

    ButtonGadget(#G_Tool_Add, ScaleX(18), ScaleY(78), ScaleX(120), ScaleY(32), "Add Game")
    ButtonGadget(#G_Tool_BrowseExe, ScaleX(146), ScaleY(78), ScaleX(120), ScaleY(32), "Browse EXE")
    ButtonGadget(#G_Tool_AddFolder, ScaleX(274), ScaleY(78), ScaleX(120), ScaleY(32), "Add Folder")
    ButtonGadget(#G_Tool_ImportSteamGame, ScaleX(402), ScaleY(78), ScaleX(178), ScaleY(32), "Import Steam Game")
    ListViewGadget(#G_Library, ScaleX(18), ScaleY(118), ScaleX(170), ScaleY(438))
    AddGadgetItem(#G_Library, -1, "All Games")
    AddGadgetItem(#G_Library, -1, "Steam")
    AddGadgetItem(#G_Library, -1, "EXE")
    AddGadgetItem(#G_Library, -1, "Recently Played")
    AddGadgetItem(#G_Library, -1, "Most Played")
    AddGadgetItem(#G_Library, -1, "Tagged")
    SetGadgetState(#G_Library, LibraryView)
    StringGadget(#G_Filter, ScaleX(598), ScaleY(82), ScaleX(220), ScaleY(24), "")
    ComboBoxGadget(#G_Sort, ScaleX(828), ScaleY(82), ScaleX(232), ScaleY(24))
    AddGadgetItem(#G_Sort, -1, "Sort: Name")
    AddGadgetItem(#G_Sort, -1, "Sort: Last Played")
    AddGadgetItem(#G_Sort, -1, "Sort: Run Count")
    SetGadgetState(#G_Sort, SortMode)

    TextGadget(#G_LaunchState, ScaleX(198), ScaleY(122), ScaleX(680), ScaleY(18), "")
    ButtonGadget(#G_CancelWait, ScaleX(900), ScaleY(116), ScaleX(160), ScaleY(30), "Cancel Wait")

    ListIconGadget(#G_List, ScaleX(198), ScaleY(154), ScaleX(862), ScaleY(350), "Game", ScaleX(240), #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
    AddGadgetColumn(#G_List, 1, "Type", ScaleX(90))
    AddGadgetColumn(#G_List, 2, "Path / AppID / Profile", ScaleX(590))
    AddGadgetColumn(#G_List, 3, "Services", ScaleX(90))

    If FontTitle : SetGadgetFont(#G_Title, FontID(FontTitle)) : EndIf
    If FontSmall : SetGadgetFont(#G_Subtitle, FontID(FontSmall)) : EndIf
    If FontSmall : SetGadgetFont(#G_LaunchState, FontID(FontSmall)) : EndIf
    If FontUI : SetGadgetFont(#G_Library, FontID(FontUI)) : EndIf
    If FontUI : SetGadgetFont(#G_List, FontID(FontUI)) : EndIf
    If FontUI : SetGadgetFont(#G_Tool_Add, FontID(FontUI)) : EndIf
    If FontUI : SetGadgetFont(#G_Tool_BrowseExe, FontID(FontUI)) : EndIf
    If FontUI : SetGadgetFont(#G_Tool_AddFolder, FontID(FontUI)) : EndIf
    If FontUI : SetGadgetFont(#G_Tool_ImportSteamGame, FontID(FontUI)) : EndIf
    If FontUI : SetGadgetFont(#G_Filter, FontID(FontUI)) : EndIf
    If FontUI : SetGadgetFont(#G_Sort, FontID(FontUI)) : EndIf
    If FontUI : SetGadgetFont(#G_CancelWait, FontID(FontUI)) : EndIf
    HideGadget(#G_LaunchState, 1)
    HideGadget(#G_CancelWait, 1)
    EnableGadgetDrop(#G_List, #PB_Drop_Private, #PB_Drag_Move, #PRIVATE_DROP_GAME)

    ButtonGadget(#G_OpenFolder, ScaleX(198), ScaleY(520), ScaleX(146), ScaleY(36), "Open Folder")
    ButtonGadget(#G_MoveUp, ScaleX(516), ScaleY(520), ScaleX(100), ScaleY(36), "Move Up")
    ButtonGadget(#G_MoveDown, ScaleX(624), ScaleY(520), ScaleX(100), ScaleY(36), "Move Down")
    ButtonGadget(#G_Remove, ScaleX(732), ScaleY(520), ScaleX(96), ScaleY(36), "Remove")
    ButtonGadget(#G_Edit, ScaleX(836), ScaleY(520), ScaleX(96), ScaleY(36), "Edit")
    ButtonGadget(#G_Launch, ScaleX(940), ScaleY(520), ScaleX(100), ScaleY(36), "Run")
    If FontUI
      SetGadgetFont(#G_OpenFolder, FontID(FontUI))
      SetGadgetFont(#G_MoveUp, FontID(FontUI))
      SetGadgetFont(#G_MoveDown, FontID(FontUI))
      SetGadgetFont(#G_Remove, FontID(FontUI))
      SetGadgetFont(#G_Edit, FontID(FontUI))
      SetGadgetFont(#G_Launch, FontID(FontUI))
    EndIf

    MainStatusBar = CreateStatusBar(#PB_Any, WindowID(0))
    If MainStatusBar
      AddStatusBarField(ScaleX(1080))
      StatusBarText(MainStatusBar, 0, "Ready")
    EndIf

    RefreshList()
    UpdateSelectionUI()

    Repeat
      PollLaunchState()
      Select WaitWindowEvent(100)
        Case #PB_Event_Gadget
          Select EventGadget()
            Case #G_List
              If EventType() = #PB_EventType_DragStart
                If IsLaunchActive() = 0 And FilterQuery = "" And SortMode = #SORT_NAME_ASC And LibraryView = #LIBRARY_ALL
                  DragGameIndex = GameIndexFromVisibleIndex(GetGadgetState(#G_List))
                  If DragGameIndex >= 0
                    UpdateListHint()
                    DragPrivate(#PRIVATE_DROP_GAME, #PB_Drag_Move)
                    DragGameIndex = -1
                    UpdateListHint()
                  EndIf
                EndIf
              Else
                UpdateSelectionUI()
              EndIf
            Case #G_Library
              LibraryView = GetGadgetState(#G_Library)
              SaveSettings()
              RefreshList()
            Case #G_Tool_Add
              CaptureUndoState("Add Game")
              AddGameSimple()
            Case #G_Tool_BrowseExe
              BrowseExePath = OpenFileRequester("Select game exe", "", "Executables (*.exe)|*.exe|All files (*.*)|*.*", 0)
              If BrowseExePath <> ""
                CaptureUndoState("Browse EXE")
                BeforeCount = ListSize(Games())
                AddExeEntry(BrowseExePath)
                If ListSize(Games()) > BeforeCount
                  SaveGames()
                  RefreshList()
                  SetGadgetState(#G_List, CountGadgetItems(#G_List) - 1)
                  SetGadgetItemState(#G_List, CountGadgetItems(#G_List) - 1, #PB_ListIcon_Selected)
                  SetActiveGadget(#G_List)
                EndIf
              EndIf
            Case #G_Tool_AddFolder
              CaptureUndoState("Add Folder")
              ImportFolderGames()
            Case #G_Tool_ImportSteamGame
              CaptureUndoState("Import Steam Game")
              BeforeCount = CountGadgetItems(#G_List)
              ImportSingleSteamGame()
              If CountGadgetItems(#G_List) > BeforeCount
                SetGadgetState(#G_List, CountGadgetItems(#G_List) - 1)
                SetGadgetItemState(#G_List, CountGadgetItems(#G_List) - 1, #PB_ListIcon_Selected)
                SetActiveGadget(#G_List)
              EndIf
            Case #G_Filter
              FilterQuery = Trim(GetGadgetText(#G_Filter))
              RefreshList()
            Case #G_Sort
              SortMode = GetGadgetState(#G_Sort)
              SaveSettings()
              RefreshList()
            Case #G_OpenFolder
              OpenSelectedGameFolder(GameIndexFromVisibleIndex(GetGadgetState(#G_List)))
            Case #G_MoveUp
              newIndex = GetGadgetState(#G_List) - 1
              launchIdx = GameIndexFromVisibleIndex(GetGadgetState(#G_List))
              CaptureUndoState("Move Game Up")
              If launchIdx >= 0 And MoveGameByIndex(launchIdx, -1)
                SetGadgetState(#G_List, newIndex)
                SetGadgetItemState(#G_List, newIndex, #PB_ListIcon_Selected)
                SetActiveGadget(#G_List)
              EndIf
            Case #G_MoveDown
              newIndex = GetGadgetState(#G_List) + 1
              launchIdx = GameIndexFromVisibleIndex(GetGadgetState(#G_List))
              CaptureUndoState("Move Game Down")
              If launchIdx >= 0 And MoveGameByIndex(launchIdx, 1)
                SetGadgetState(#G_List, newIndex)
                SetGadgetItemState(#G_List, newIndex, #PB_ListIcon_Selected)
                SetActiveGadget(#G_List)
              EndIf
            Case #G_Remove
              launchIdx = GameIndexFromVisibleIndex(GetGadgetState(#G_List))
              If launchIdx >= 0
                CaptureUndoState("Remove Game")
                RemoveGameByIndex(launchIdx)
              EndIf
              UpdateSelectionUI()
            Case #G_Edit
              launchIdx = GameIndexFromVisibleIndex(GetGadgetState(#G_List))
              If launchIdx >= 0
                CaptureUndoState("Edit Game")
                EditGameByIndex(launchIdx, #G_List)
              EndIf
              UpdateSelectionUI()
            Case #G_CancelWait
              CancelPendingLaunch()
            Case #G_Launch
              launchIdx = GameIndexFromVisibleIndex(GetGadgetState(#G_List))
              If launchIdx >= 0 And IsLaunchActive() = 0
                If SelectGameByIndex(launchIdx, @selectedLaunchGame)
                  If selectedLaunchGame\LaunchMode = 1
                    LaunchSteamBoosted(@selectedLaunchGame)
                  Else
                    LaunchBoosted(@selectedLaunchGame)
                  EndIf
                EndIf
              EndIf
          EndSelect

        Case #PB_Event_Menu
          Select EventMenu()
            Case #MI_File_Add
              PostEvent(#PB_Event_Gadget, 0, #G_Tool_Add)
            Case #MI_File_BrowseExe
              PostEvent(#PB_Event_Gadget, 0, #G_Tool_BrowseExe)
            Case #MI_File_AddFolder
              PostEvent(#PB_Event_Gadget, 0, #G_Tool_AddFolder)
            Case #MI_File_ImportSteamGame
              PostEvent(#PB_Event_Gadget, 0, #G_Tool_ImportSteamGame)
            Case #MI_File_ImportProfiles
              CaptureUndoState("Import Profiles")
              ImportGamesProfile()
            Case #MI_File_ExportProfiles
              ExportGamesProfile()
            Case #MI_File_CreateSnapshot
              CreateProfileSnapshot()
            Case #MI_File_RestoreSnapshot
              CaptureUndoState("Restore Snapshot")
              RestoreProfileSnapshot()
            Case #MI_File_Undo
              UndoLastLibraryChange()
            Case #MI_File_Redo
              RedoLastLibraryChange()
            Case #MI_File_Exit
              Exit()
            Case #MI_Game_Run
              PostEvent(#PB_Event_Gadget, 0, #G_Launch)
            Case #MI_Game_Edit
              PostEvent(#PB_Event_Gadget, 0, #G_Edit)
            Case #MI_Game_MoveUp
              PostEvent(#PB_Event_Gadget, 0, #G_MoveUp)
            Case #MI_Game_MoveDown
              PostEvent(#PB_Event_Gadget, 0, #G_MoveDown)
            Case #MI_Game_Remove
              PostEvent(#PB_Event_Gadget, 0, #G_Remove)
            Case #MI_Game_OpenFolder
              PostEvent(#PB_Event_Gadget, 0, #G_OpenFolder)
            Case #MI_Tools_ViewLog
              ViewLog()
            Case #MI_Tools_Diagnostics
              ShowDiagnostics()
            Case #MI_Tools_History
              ShowHistory()
            Case #MI_Tools_Settings
              ShowSettings()
            Case #MI_Help_Help
              ShowHelp()
            Case #MI_Help_About
              MessageRequester("About", #APP_NAME + " - " + version + #CRLF$ +
                                        "A Safe Game Booster for all your games" + #CRLF$ +
                                        "--------------------------------------" + #CRLF$ +
                                        "Contact: zonemaster60@gmail.com" + #CRLF$ +
                                        "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
          EndSelect

        Case #PB_Event_CloseWindow
          Exit()

        Case #PB_Event_GadgetDrop
          If EventGadget() = #G_List And EventDropType() = #PB_Drop_Private And IsLaunchActive() = 0 And DragGameIndex >= 0 And FilterQuery = "" And SortMode = #SORT_NAME_ASC And LibraryView = #LIBRARY_ALL
            newIndex = GameIndexFromVisibleIndex(ListIndexFromCursor(#G_List))
            If newIndex < 0
              newIndex = ListSize(Games()) - 1
            EndIf
            CaptureUndoState("Reorder Games")
            If MoveGameToIndex(DragGameIndex, newIndex)
              SetGadgetState(#G_List, newIndex)
              SetGadgetItemState(#G_List, newIndex, #PB_ListIcon_Selected)
              SetActiveGadget(#G_List)
            EndIf
            DragGameIndex = -1
            UpdateSelectionUI()
          EndIf
      EndSelect
    ForEver
  EndIf
EndProcedure

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 435
; FirstLine = 426
; Folding = ---
; EnableXP
; DPIAware
