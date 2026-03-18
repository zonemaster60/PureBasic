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
  LaunchCtx\PrevPowerGuid = ""
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
EndProcedure

Procedure SetLaunchUiState(active.i, statusText.s = "")
  Protected pulse.s

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
    DisableMenuItem(#Menu_Main, #MI_File_ImportSteam, active)
    DisableMenuItem(#Menu_Main, #MI_Game_Run, active)
    DisableMenuItem(#Menu_Main, #MI_Game_Edit, active)
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

  CleanupBoostSession(@LaunchCtx)
  If message <> ""
    LogLine(finalStatus)
  ElseIf success
    LogLine(finalStatus)
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
  LogLine("Monitoring EXE process for: " + LaunchGame\Name)
  LaunchState = 2
  LaunchActive = 1
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
                              "Try: Import Steam again (so appmanifest_*.acf is available) and make sure the game is installed.")
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
        LogLine("Monitoring detected game process for: " + LaunchGame\Name)
        LaunchState = 2
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
  Protected canAct.i = Bool(idxSel >= 0)
  If IsLaunchActive()
    canAct = 0
  EndIf
  DisableGadget(#G_Edit, Bool(canAct = 0))
  DisableGadget(#G_Launch, Bool(canAct = 0))

  If IsMenu(#Menu_Main)
    DisableMenuItem(#Menu_Main, #MI_Game_Run, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_Edit, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_Remove, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_OpenFolder, Bool(canAct = 0))
  EndIf

  If MainStatusBar
    If IsLaunchActive()
      If LaunchState = 1
        StatusBarText(MainStatusBar, 0, "Waiting for game process: " + LaunchGame\Name)
      Else
        StatusBarText(MainStatusBar, 0, "Running: " + LaunchGame\Name)
      EndIf
    ElseIf canAct
      StatusBarText(MainStatusBar, 0, "Selected: " + GetGadgetItemText(#G_List, idxSel, 0))
    Else
      StatusBarText(MainStatusBar, 0, "Ready")
    EndIf
  EndIf
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

Procedure RefreshList()
  ClearGadgetItems(#G_List)
  ForEach Games()
    If Games()\LaunchMode = 1
      AddGadgetItem(#G_List, -1, Games()\Name + Chr(10) + "Steam" + Chr(10) + "AppID " + Str(Games()\SteamAppId) + Chr(10) + ServicesSummary(Games()\Services))
    Else
      AddGadgetItem(#G_List, -1, Games()\Name + Chr(10) + "EXE" + Chr(10) + Games()\ExePath + Chr(10) + ServicesSummary(Games()\Services))
    EndIf
  Next
  UpdateSelectionUI()
EndProcedure

Procedure RunApplication()
  Protected launchIdx.i
  Protected selectedLaunchGame.GameEntry

  If OpenWindow(0, 0, 0, ScaleX(980), ScaleY(510), "SafeGameBooster - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
    If CreateMenu(#Menu_Main, WindowID(0))
      MenuTitle("File")
      MenuItem(#MI_File_Add, "Add...")
      MenuItem(#MI_File_BrowseExe, "Browse EXE...")
      MenuItem(#MI_File_AddFolder, "Add Folder...")
      MenuItem(#MI_File_ImportSteam, "Import Steam")
      MenuBar()
      MenuItem(#MI_File_Exit, "Exit")

      MenuTitle("Game")
      MenuItem(#MI_Game_Run, "Run")
      MenuItem(#MI_Game_Edit, "Edit...")
      MenuItem(#MI_Game_Remove, "Remove")
      MenuBar()
      MenuItem(#MI_Game_OpenFolder, "Open Install Folder")

      MenuTitle("Tools")
      MenuItem(#MI_Tools_ViewLog, "View Log")

      MenuTitle("Help")
      MenuItem(#MI_Help_Help, "Help")
      MenuItem(#MI_Help_About, "About")
    EndIf

    TextGadget(#G_Title, ScaleX(10), ScaleY(10), ScaleX(960), ScaleY(28), #APP_NAME)
    TextGadget(#G_Subtitle, ScaleX(10), ScaleY(38), ScaleX(960), ScaleY(18), "Safe, temporary boosts: power plan + priority/affinity + optional service stop/start")
    TextGadget(#G_LaunchState, ScaleX(10), ScaleY(56), ScaleX(700), ScaleY(16), "")
    ButtonGadget(#G_CancelWait, ScaleX(720), ScaleY(52), ScaleX(110), ScaleY(24), "Cancel Wait")
    ListIconGadget(#G_List, ScaleX(10), ScaleY(70), ScaleX(960), ScaleY(340), "Game", ScaleX(260), #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
    AddGadgetColumn(#G_List, 1, "Type", ScaleX(70))
    AddGadgetColumn(#G_List, 2, "Path / AppID", ScaleX(460))
    AddGadgetColumn(#G_List, 3, "Services", ScaleX(150))

    If FontTitle : SetGadgetFont(#G_Title, FontID(FontTitle)) : EndIf
    If FontSmall : SetGadgetFont(#G_Subtitle, FontID(FontSmall)) : EndIf
    If FontSmall : SetGadgetFont(#G_LaunchState, FontID(FontSmall)) : EndIf
    If FontUI : SetGadgetFont(#G_List, FontID(FontUI)) : EndIf
    If FontUI : SetGadgetFont(#G_CancelWait, FontID(FontUI)) : EndIf
    HideGadget(#G_LaunchState, 1)
    HideGadget(#G_CancelWait, 1)

    ButtonGadget(#G_Edit, ScaleX(740), ScaleY(420), ScaleX(110), ScaleY(34), "Edit")
    ButtonGadget(#G_Launch, ScaleX(860), ScaleY(420), ScaleX(110), ScaleY(34), "Run")
    If FontUI
      SetGadgetFont(#G_Edit, FontID(FontUI))
      SetGadgetFont(#G_Launch, FontID(FontUI))
    EndIf

    MainStatusBar = CreateStatusBar(#PB_Any, WindowID(0))
    If MainStatusBar
      AddStatusBarField(ScaleX(980))
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
              UpdateSelectionUI()
            Case #G_Edit
              If GetGadgetState(#G_List) >= 0
                EditGameByIndex(GetGadgetState(#G_List), #G_List)
              EndIf
              UpdateSelectionUI()
            Case #G_CancelWait
              CancelPendingLaunch()
            Case #G_Launch
              launchIdx = GetGadgetState(#G_List)
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
              AddGameSimple()
            Case #MI_File_BrowseExe
              BrowseExePath = OpenFileRequester("Select game exe", "", "Executables (*.exe)|*.exe|All files (*.*)|*.*", 0)
              If BrowseExePath <> ""
                BeforeCount = ListSize(Games())
                AddExeEntry(BrowseExePath)
                If ListSize(Games()) > BeforeCount
                  SaveGames()
                  RefreshList()
                EndIf
              EndIf
            Case #MI_File_AddFolder
              ImportFolderGames()
            Case #MI_File_ImportSteam
              ImportSteamGames()
            Case #MI_File_Exit
              Exit()
            Case #MI_Game_Run
              PostEvent(#PB_Event_Gadget, 0, #G_Launch)
            Case #MI_Game_Edit
              PostEvent(#PB_Event_Gadget, 0, #G_Edit)
            Case #MI_Game_Remove
              If GetGadgetState(#G_List) >= 0
                RemoveGameByIndex(GetGadgetState(#G_List))
              EndIf
              UpdateSelectionUI()
            Case #MI_Game_OpenFolder
              OpenSelectedGameFolder(GetGadgetState(#G_List))
            Case #MI_Tools_ViewLog
              ViewLog()
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
      EndSelect
    ForEver
  EndIf
EndProcedure
