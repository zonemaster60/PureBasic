; Launch flows, UI helpers, and application window.

Procedure.i LaunchBoosted(*g.GameEntry)
  Protected si.STARTUPINFO, pi.PROCESS_INFORMATION
  Protected cmd.s, workdir.s
  Protected ctx.BoostSessionContext
  Protected origPriority.l
  Protected processAffinity.q, systemAffinity.q
  Protected gotAffinity.i

  si\cb = SizeOf(STARTUPINFO)
  workdir = *g\WorkDir
  If workdir = "" : workdir = GetPathPart(*g\ExePath) : EndIf
  cmd = QuoteArg(*g\ExePath)
  If *g\Args <> "" : cmd + " " + *g\Args : EndIf
  LogLine("Launch EXE: " + *g\Name + " | " + CollapseBackslashes(*g\ExePath))

  PrepareBoostSession(*g, @ctx)

  Protected *cmdMem = AllocateMemory((Len(cmd) + 2) * SizeOf(Character))
  If *cmdMem = 0
    CleanupBoostSession(@ctx)
    ProcedureReturn 0
  EndIf
  PokeS(*cmdMem, cmd, -1)

  Protected cpResult.i = CreateProcess_(0, *cmdMem, 0, 0, #False, 0, 0, workdir, @si, @pi)
  FreeMemory(*cmdMem)
  If cpResult = 0
    CleanupBoostSession(@ctx)
    MessageRequester(#APP_NAME, "Failed to launch:" + #LF$ + *g\ExePath)
    ProcedureReturn 0
  EndIf

  origPriority = GetPriorityClass_(pi\hProcess)
  gotAffinity  = GetProcessAffinityMask_(pi\hProcess, @processAffinity, @systemAffinity)
  ApplyProcessBoost(pi\hProcess, *g)
  WaitForSingleObject_(pi\hProcess, #INFINITE)
  RestoreProcessBoost(pi\hProcess, gotAffinity, origPriority, processAffinity)
  CloseHandle_(pi\hThread)
  CloseHandle_(pi\hProcess)
  CleanupBoostSession(@ctx)
  ProcedureReturn 1
EndProcedure

Procedure.i LaunchSteamBoosted(*g.GameEntry)
  Protected si.STARTUPINFO, pi.PROCESS_INFORMATION
  Protected ctx.BoostSessionContext
  Protected cmd.s, workdir.s
  Protected gameRoot.s
  Protected NewMap baseline.i()
  Protected pidGame.i, hGame.i
  Protected origPriority.l
  Protected processAffinity.q, systemAffinity.q
  Protected gotAffinity.i
  Protected timeoutMs.i

  If *g\SteamExe = "" Or FileSize(*g\SteamExe) <= 0
    *g\SteamExe = FindSteamExe()
  EndIf
  If *g\SteamExe = "" Or FileSize(*g\SteamExe) <= 0
    MessageRequester(#APP_NAME, "Steam executable not set/found.")
    ProcedureReturn 0
  EndIf
  If *g\SteamAppId <= 0
    MessageRequester(#APP_NAME, "Invalid Steam AppID.")
    ProcedureReturn 0
  EndIf
  gameRoot = ResolveSteamGameRoot(*g)
  If gameRoot = ""
    MessageRequester(#APP_NAME, "Could not resolve Steam install folder for this game." + #LF$ + #LF$ +
                              "Try: Import Steam again (so appmanifest_*.acf is available) and make sure the game is installed.")
    ProcedureReturn 0
  EndIf

  LogLine("Launch Steam: " + *g\Name + " | AppID=" + Str(*g\SteamAppId))
  PrepareBoostSession(*g, @ctx)
  SnapshotPids(baseline())

  si\cb = SizeOf(STARTUPINFO)
  workdir = GetPathPart(*g\SteamExe)
  cmd = QuoteArg(*g\SteamExe)
  If Trim(*g\SteamClientArgs) <> "" : cmd + " " + Trim(*g\SteamClientArgs) : EndIf
  cmd + " -applaunch " + Str(*g\SteamAppId)
  If Trim(*g\SteamGameArgs) <> "" : cmd + " " + Trim(*g\SteamGameArgs) : EndIf

  Protected *cmdMem = AllocateMemory((Len(cmd) + 2) * SizeOf(Character))
  If *cmdMem = 0
    CleanupBoostSession(@ctx)
    ProcedureReturn 0
  EndIf
  PokeS(*cmdMem, cmd, -1)

  Protected cpResult.i = CreateProcess_(0, *cmdMem, 0, 0, #False, 0, 0, workdir, @si, @pi)
  FreeMemory(*cmdMem)
  If cpResult = 0
    CleanupBoostSession(@ctx)
    MessageRequester(#APP_NAME, "Failed to start Steam.")
    ProcedureReturn 0
  EndIf
  CloseHandle_(pi\hThread)
  CloseHandle_(pi\hProcess)

  timeoutMs = ClampSteamDetectTimeout(*g\SteamDetectTimeoutMs)
  pidGame = FindNewProcessInFolder(gameRoot, baseline(), timeoutMs)
  If pidGame = 0
    CleanupBoostSession(@ctx)
    MessageRequester(#APP_NAME, "Could not detect game process (timeout)." + #LF$ + #LF$ +
                              "Try: re-import Steam metadata for the game and increase the detect timeout.")
    ProcedureReturn 0
  EndIf
  LogLine("Detected game PID=" + Str(pidGame))

  hGame = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_SET_INFORMATION | #SYNCHRONIZE, #False, pidGame)
  If hGame = 0
    hGame = OpenProcess_(#PROCESS_QUERY_LIMITED_INFORMATION | #PROCESS_SET_INFORMATION | #SYNCHRONIZE, #False, pidGame)
  EndIf
  If hGame = 0
    CleanupBoostSession(@ctx)
    MessageRequester(#APP_NAME, "Detected game PID " + Str(pidGame) + " but could not open process.")
    ProcedureReturn 0
  EndIf

  origPriority = GetPriorityClass_(hGame)
  gotAffinity  = GetProcessAffinityMask_(hGame, @processAffinity, @systemAffinity)
  ApplyProcessBoost(hGame, *g)
  WaitForSingleObject_(hGame, #INFINITE)
  RestoreProcessBoost(hGame, gotAffinity, origPriority, processAffinity)
  CloseHandle_(hGame)
  CleanupBoostSession(@ctx)
  ProcedureReturn 1
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
  DisableGadget(#G_Edit, Bool(canAct = 0))
  DisableGadget(#G_Launch, Bool(canAct = 0))

  If IsMenu(#Menu_Main)
    DisableMenuItem(#Menu_Main, #MI_Game_Run, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_Edit, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_Remove, Bool(canAct = 0))
    DisableMenuItem(#Menu_Main, #MI_Game_OpenFolder, Bool(canAct = 0))
  EndIf

  If MainStatusBar
    If canAct
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
    ListIconGadget(#G_List, ScaleX(10), ScaleY(70), ScaleX(960), ScaleY(340), "Game", ScaleX(260), #PB_ListIcon_FullRowSelect | #PB_ListIcon_GridLines)
    AddGadgetColumn(#G_List, 1, "Type", ScaleX(70))
    AddGadgetColumn(#G_List, 2, "Path / AppID", ScaleX(460))
    AddGadgetColumn(#G_List, 3, "Services", ScaleX(150))

    If FontTitle : SetGadgetFont(#G_Title, FontID(FontTitle)) : EndIf
    If FontSmall : SetGadgetFont(#G_Subtitle, FontID(FontSmall)) : EndIf
    If FontUI : SetGadgetFont(#G_List, FontID(FontUI)) : EndIf

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
      Select WaitWindowEvent()
        Case #PB_Event_Gadget
          Select EventGadget()
            Case #G_List
              UpdateSelectionUI()
            Case #G_Edit
              If GetGadgetState(#G_List) >= 0
                EditGameByIndex(GetGadgetState(#G_List), #G_List)
              EndIf
              UpdateSelectionUI()
            Case #G_Launch
              idx = GetGadgetState(#G_List)
              If idx >= 0
                If SelectGameByIndex(idx, @g)
                  If g\LaunchMode = 1
                    LaunchSteamBoosted(@g)
                  Else
                    LaunchBoosted(@g)
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
