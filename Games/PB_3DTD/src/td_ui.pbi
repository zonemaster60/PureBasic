
#APP_NAME = "PB_3DTD"

; Prevent multiple instances (don't rely on window title text)
; Allow helper modes to run even if the tray app is running.
Global hMutex.i
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
  If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
    MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
    CloseHandle_(hMutex)
    End
  EndIf
  
Procedure Exit()
  Define Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseHandle_(hMutex)
    End
  EndIf
EndProcedure

Procedure QuitGame()
  ReleaseMouse(#True)
  Exit()
EndProcedure

Procedure PlayUISound(AliasName.s)
  PlaySound_(AliasName, 0, #SND_ASYNC | #SND_ALIAS | #SND_NODEFAULT)
EndProcedure

Procedure PlayTowerFireSound(TowerType.i)
  Select TowerType
    Case #TowerType_Pulse
      PlayUISound("SystemAsterisk")
    Case #TowerType_Cannon
      PlayUISound("SystemExclamation")
    Case #TowerType_Frost
      PlayUISound("SystemQuestion")
    Case #TowerType_Beam
      PlayUISound("SystemAsterisk")
    Case #TowerType_Mortar
      PlayUISound("SystemExclamation")
    Case #TowerType_Sky
      PlayUISound("SystemQuestion")
  EndSelect
EndProcedure

Procedure PlayHitSound()
  PlayUISound("SystemHand")
EndProcedure

Procedure PlayWaveSound()
  PlayUISound("SystemStart")
EndProcedure

Procedure.s RunModeName()
  If CampaignMode
    ProcedureReturn "Campaign"
  EndIf

  ProcedureReturn "Skirmish"
EndProcedure

Procedure.i AnySellableTower()
  If ListSize(Towers()) > 0
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.s BuildWaveForecast(CurrentWave.i)
  Protected NextWave.i = CurrentWave + 1
  Protected SpawnCount.i
  Protected SpawnIndex.i
  Protected FastCount.i
  Protected HeavyCount.i
  Protected PressureCount.i
  Protected AirBossCount.i
  Protected EnemyType.i

  If NextWave > #MaxWaves
    ProcedureReturn "Forecast: no remaining waves"
  EndIf

  SpawnCount = 9 + NextWave * 2

  For SpawnIndex = 0 To SpawnCount - 1
    EnemyType = PlannedEnemyType(NextWave, SpawnIndex, SpawnCount)
    Select EnemyType
      Case #EnemyType_Runner
        FastCount + 1
      Case #EnemyType_Swarm, #EnemyType_Glider, #EnemyType_Leech
        PressureCount + 1
      Case #EnemyType_Brute, #EnemyType_Shield, #EnemyType_Siege
        HeavyCount + 1
      Case #EnemyType_Boss, #EnemyType_Overseer
        AirBossCount + 1
      Case #EnemyType_Splitter
        PressureCount + 1
    EndSelect
  Next

  ProcedureReturn "Forecast W" + Str(NextWave) + ": Fast " + Str(FastCount) + "  Heavy " + Str(HeavyCount) + #LF$ + "Pressure " + Str(PressureCount) + "  Boss " + Str(AirBossCount)
EndProcedure

Procedure SetGameControlsEnabled(State.i)
  Protected Disabled.i

  If State = 0
    Disabled = #True
  Else
    Disabled = #False
  EndIf

  DisableGadget(#Gadget_BuildPulse, Disabled)
  DisableGadget(#Gadget_BuildCannon, Disabled)
  DisableGadget(#Gadget_BuildFrost, Disabled)
  DisableGadget(#Gadget_BuildBeam, Disabled)
  DisableGadget(#Gadget_BuildMortar, Disabled)
  DisableGadget(#Gadget_BuildSky, Disabled)
  DisableGadget(#Gadget_BuildBlock, Disabled)
  DisableGadget(#Gadget_LevelCycle, Disabled)
  DisableGadget(#Gadget_Upgrade, Disabled)
  DisableGadget(#Gadget_Sell, Disabled)
  DisableGadget(#Gadget_Wave, Disabled)
  DisableGadget(#Gadget_Speed, Disabled)
  DisableGadget(#Gadget_Pause, Disabled)
  DisableGadget(#Gadget_TargetMode, Disabled)
EndProcedure

Procedure SetOverlayVisible(Visible.i, ShowContinue.i, ShowLevel.i)
  HideGadget(#Gadget_MenuTitle, Bool(Visible = 0))
  HideGadget(#Gadget_MenuInfo, Bool(Visible = 0))
  HideGadget(#Gadget_MenuStart, Bool(Visible = 0))
  HideGadget(#Gadget_MenuQuit, Bool(Visible = 0))
  HideGadget(#Gadget_MenuLevel, Bool(ShowLevel = 0))
  HideGadget(#Gadget_MenuRunMode, Bool(ShowLevel = 0))
  HideGadget(#Gadget_MenuProgress, Bool(Visible = 0))
  HideGadget(#Gadget_MenuChallenge, Bool(ShowLevel = 0))

  If ShowContinue
    HideGadget(#Gadget_MenuContinue, #False)
  Else
    HideGadget(#Gadget_MenuContinue, #True)
  EndIf
EndProcedure

Procedure SetDebugPanelVisible(Visible.i)
  DebugPanelVisible = Visible
  HideGadget(#Gadget_DebugBack, Bool(Visible = 0))
  HideGadget(#Gadget_DebugTitle, Bool(Visible = 0))
  HideGadget(#Gadget_DebugInfo, Bool(Visible = 0))
  HideGadget(#Gadget_DebugGold, Bool(Visible = 0))
  HideGadget(#Gadget_DebugWave, Bool(Visible = 0))
  HideGadget(#Gadget_DebugLife, Bool(Visible = 0))
  HideGadget(#Gadget_DebugClear, Bool(Visible = 0))
EndProcedure

Procedure ApplyDebugAction(Action.i)
  Select Action
    Case #Gadget_DebugGold
      Gold + 100
      SetStatus("Debug: added 100 gold.", 1.0)

    Case #Gadget_DebugWave
      If WaveActive = 0 And GameState = #GameState_Playing And Wave < #MaxWaves And StartOverlayActive = 0
        StartWave(#False)
        SetStatus("Debug: forced the next wave.", 1.0)
      EndIf

    Case #Gadget_DebugLife
      CoreLives + 5
      If CoreLives > 99
        CoreLives = 99
      EndIf
      SetStatus("Debug: repaired the core by 5.", 1.0)

    Case #Gadget_DebugClear
      ForEach Enemies()
        FreeEnemyVisuals(@Enemies())
        FreeEntity(Enemies()\entity)
        DeleteElement(Enemies())
      Next
      EnemyAliveCount = 0
      WaveActive = 0
      WaveSpawned = WaveToSpawn
      SetStatus("Debug: cleared all active enemies.", 1.0)
  EndSelect

  If Wave > HighestWaveReached
    HighestWaveReached = Wave
    SaveProgression()
  EndIf

  RefreshSidebar()
EndProcedure

Procedure CloseOverlay()
  SetOverlayVisible(#False, #False, #False)
  StartOverlayActive = #False
EndProcedure

Procedure SetLevel(Level.i)
  If Level < 1
    Level = #LevelCount
  ElseIf Level > #LevelCount
    Level = 1
  EndIf

  CurrentLevel = Level
  SetGadgetText(#Gadget_MenuLevel, "Level: " + Str(CurrentLevel) + " - " + LevelName(CurrentLevel))
  SetGadgetText(#Gadget_LevelCycle, "Level: " + Str(CurrentLevel) + " - " + LevelName(CurrentLevel))
  SetGadgetText(#Gadget_MenuRunMode, "Run Mode: " + RunModeName())
  SetGadgetText(#Gadget_MenuProgress, "Progress: cleared " + Str(HighestLevelCleared) + "/" + Str(#LevelCount) + "  wins " + Str(TotalVictories) + #LF$ + "Best wave: " + Str(HighestWaveReached))
  SetGadgetText(#Gadget_MenuChallenge, "Challenge: " + ChallengeModeName(ChallengeMode))
  If StartOverlayActive
    SetGadgetText(#Gadget_MenuInfo, LevelName(CurrentLevel) + #LF$ + LevelDescription(CurrentLevel) + #LF$ + #LF$ + "Run Mode: " + RunModeName() + #LF$ + "Challenge: " + ChallengeModeName(ChallengeMode) + #LF$ + "Build around the route, reroute with blocks when needed, protect the core, and survive 12 waves." + #LF$ + #LF$ + "Shortcuts: 1-7 choose builds, Space launches a wave, U upgrades, S sells, Esc quits.")
  EndIf
  SetStatus("Selected level: " + LevelName(CurrentLevel) + ".", 1.0)
EndProcedure

Procedure StartGame()
  If StartOverlayActive = 0
    ProcedureReturn
  EndIf

  StartOverlayActive = #False
  Paused = #False
  SetGameControlsEnabled(#True)
  SetOverlayVisible(#False, #False, #False)
  SetStatus("Arena live. Use 1 to 7 to pick a build.", 2.5)
  RefreshSidebar()
EndProcedure

Procedure RestartGame()
  Protected GX.i
  Protected GZ.i
  Protected I.i

  ForEach Towers()
    FreeEntity(Towers()\baseEntity)
    FreeEntity(Towers()\headEntity)
    FreeEntity(Towers()\muzzleEntity)
  Next
  ClearList(Towers())

  ForEach Enemies()
    FreeEnemyVisuals(@Enemies())
    FreeEntity(Enemies()\entity)
  Next
  ClearList(Enemies())

  ForEach Projectiles()
    FreeEntity(Projectiles()\entity)
  Next
  ClearList(Projectiles())

  For GX = 0 To #GridWidth - 1
    For GZ = 0 To #GridHeight - 1
      Grid(GX, GZ)\towerID = 0
    Next
  Next

  For I = 0 To #RangeSegmentCount - 1
    MoveEntity(RangeSegments(I), 0, -10, 0, #PB_Absolute)
  Next

  MoveEntity(HoverEntity, 0, -10, 0, #PB_Absolute)
  SelectedTowerID = 0
  CurrentBuildType = #TowerType_Pulse
  PendingGridAction = #GridAction_None
  HoverGX = -1
  HoverGZ = -1
  NextTowerID = 1
  NextEnemyID = 1
  NextProjectileID = 1
  EnemyAliveCount = 0
  CoreLives = ChallengeCoreLives
  Gold = ChallengeStartGold
  Wave = 0
  WaveActive = 0
  WaveSpawnTimer = 0
  WaveSpawned = 0
  WaveToSpawn = 0
  WaveCountdown = 4.0 * ChallengeWaveDelayScale
  GameSpeedIndex = 0
  GameSpeed = 1.0
  Paused = #False
  GameState = #GameState_Playing
  StartOverlayActive = #True
  MessageText = "Press Start to open the arena, then build before the first wave arrives."
  MessageLogText = MessageText
  MessageTimer = 5.0

  RebuildBoard()

  SetGadgetText(#Gadget_MenuTitle, "3D TOWER DEFENSE" + #LF$ + version)
  SetGadgetText(#Gadget_MenuInfo, LevelName(CurrentLevel) + #LF$ + LevelDescription(CurrentLevel) + #LF$ + #LF$ + "Run Mode: " + RunModeName() + #LF$ + "Challenge: " + ChallengeModeName(ChallengeMode) + #LF$ + "Build around the route, reroute with blocks when needed, protect the core, and survive 12 waves." + #LF$ + #LF$ + "Shortcuts: 1-7 choose builds, Space launches a wave, U upgrades, S sells, Esc quits.")
  SetGadgetText(#Gadget_MenuStart, "Deploy Run")
  SetGadgetText(#Gadget_MenuContinue, "")
  SetGadgetText(#Gadget_MenuQuit, "Quit")
  SetLevel(CurrentLevel)
  SetOverlayVisible(#True, #False, #True)
  SetGameControlsEnabled(#False)
  UpdateBuildButtons()
  RefreshSidebar()
EndProcedure

Procedure ShowEndOverlay()
  If GameState = #GameState_Victory
    If CurrentLevel > HighestLevelCleared
      HighestLevelCleared = CurrentLevel
    EndIf
    TotalVictories + 1
    SaveProgression()
    SetGadgetText(#Gadget_MenuTitle, "VICTORY")
    If CampaignMode And CurrentLevel < #LevelCount
      SetGadgetText(#Gadget_MenuInfo, LevelName(CurrentLevel) + " secured." + #LF$ + #LF$ + "All 12 waves were cleared." + #LF$ + #LF$ + "Next up: " + LevelName(CurrentLevel + 1))
    Else
      SetGadgetText(#Gadget_MenuInfo, LevelName(CurrentLevel) + " secured." + #LF$ + #LF$ + "All 12 waves were cleared." + #LF$ + #LF$ + "You cleared every level in the current set.")
    EndIf
  ElseIf GameState = #GameState_Defeat
    SaveProgression()
    SetGadgetText(#Gadget_MenuTitle, "DEFEAT")
    SetGadgetText(#Gadget_MenuInfo, "The core was breached on " + LevelName(CurrentLevel) + "." + #LF$ + #LF$ + "Adjust your layout and try another run.")
  EndIf

  If GameState = #GameState_Victory And CampaignMode And CurrentLevel < #LevelCount
    SetGadgetText(#Gadget_MenuStart, "Next Level")
  Else
    SetGadgetText(#Gadget_MenuStart, "Restart Run")
  EndIf
  SetGadgetText(#Gadget_MenuProgress, "Progress: cleared " + Str(HighestLevelCleared) + "/" + Str(#LevelCount) + "  wins " + Str(TotalVictories) + #LF$ + "Best wave: " + Str(HighestWaveReached))
  SetGadgetText(#Gadget_MenuContinue, "Continue Watching")
  SetOverlayVisible(#True, #True, #False)
  DisableGadget(#Gadget_MenuStart, #False)
  SetGadgetText(#Gadget_MenuQuit, "Quit")
  StartOverlayActive = #True
EndProcedure

Procedure CreateSidebar()
  Protected SidebarLeft.i = #SidebarX + 12
  Protected SidebarInnerWidth.i = #SidebarWidth - 24

  TextGadget(#Gadget_Title, #SidebarX, 18, #SidebarWidth - 16, 36, "3D TOWER DEFENSE", #PB_Text_Center)
  TextGadget(#Gadget_Info, SidebarLeft, 64, SidebarInnerWidth, 136, "")
  TextGadget(#Gadget_Forecast, SidebarLeft, 204, SidebarInnerWidth, 34, "")
  ButtonGadget(#Gadget_LevelCycle, SidebarLeft, 244, SidebarInnerWidth, 20, "Level: " + Str(CurrentLevel) + " - " + LevelName(CurrentLevel))

  ButtonGadget(#Gadget_BuildPulse, SidebarLeft, 268, SidebarInnerWidth, 20, "")
  ButtonGadget(#Gadget_BuildCannon, SidebarLeft, 292, SidebarInnerWidth, 20, "")
  ButtonGadget(#Gadget_BuildFrost, SidebarLeft, 316, SidebarInnerWidth, 20, "")
  ButtonGadget(#Gadget_BuildBeam, SidebarLeft, 340, SidebarInnerWidth, 20, "")
  ButtonGadget(#Gadget_BuildMortar, SidebarLeft, 364, SidebarInnerWidth, 20, "")
  ButtonGadget(#Gadget_BuildSky, SidebarLeft, 388, SidebarInnerWidth, 20, "")
  ButtonGadget(#Gadget_BuildBlock, SidebarLeft, 412, SidebarInnerWidth, 20, "")
  ButtonGadget(#Gadget_Upgrade, SidebarLeft, 442, SidebarInnerWidth, 22, "Upgrade")
  ButtonGadget(#Gadget_Sell, SidebarLeft, 468, SidebarInnerWidth, 22, "Sell")
  ButtonGadget(#Gadget_Wave, SidebarLeft, 498, SidebarInnerWidth, 24, "Launch next wave")
  ButtonGadget(#Gadget_Speed, SidebarLeft, 528, SidebarInnerWidth, 22, "Speed: 1x")
  ButtonGadget(#Gadget_Pause, SidebarLeft, 554, SidebarInnerWidth, 22, "Pause")
  ButtonGadget(#Gadget_TargetMode, SidebarLeft, 580, SidebarInnerWidth, 20, "Target: First")

  TextGadget(#Gadget_Selected, SidebarLeft, 608, SidebarInnerWidth, 72, "")
  EditorGadget(#Gadget_Message, SidebarLeft, 684, SidebarInnerWidth, 54, #PB_Editor_ReadOnly)
  TextGadget(#Gadget_Controls, SidebarLeft, 742, SidebarInnerWidth, 30, "1-7 builds, Level cycles maps." + #LF$ + "Space wave, U upgrade, S sell")

  TextGadget(#Gadget_MenuTitle, 190, 138, 560, 110, "3D TOWER DEFENSE" + #LF$ + version, #PB_Text_Center)
  TextGadget(#Gadget_MenuInfo, 230, 260, 480, 156, LevelName(CurrentLevel) + #LF$ + LevelDescription(CurrentLevel) + #LF$ + #LF$ + "Run Mode: " + RunModeName() + #LF$ + "Challenge: " + ChallengeModeName(ChallengeMode) + #LF$ + "Build around the route, reroute with blocks when needed, protect the core, and survive 12 waves." + #LF$ + #LF$ + "Shortcuts: 1-7 choose builds, Space launches a wave, U upgrades, S sells, Esc quits.")
  ButtonGadget(#Gadget_MenuLevel, 110, 630, 130, 30, "Level: " + Str(CurrentLevel) + " - " + LevelName(CurrentLevel))
  ButtonGadget(#Gadget_MenuRunMode, 250, 630, 130, 30, "Run Mode: " + RunModeName())
  ButtonGadget(#Gadget_MenuChallenge, 390, 630, 130, 30, "Challenge: " + ChallengeModeName(ChallengeMode))
  TextGadget(#Gadget_MenuProgress, 300, 540, 340, 34, "")
  ButtonGadget(#Gadget_MenuStart, 530, 630, 130, 30, "Deploy Run")
  ButtonGadget(#Gadget_MenuContinue, 530, 620, 130, 30, "")
  ButtonGadget(#Gadget_MenuQuit, 670, 630, 130, 30, "Quit")
  HideGadget(#Gadget_MenuContinue, #True)

  TextGadget(#Gadget_DebugBack, 8, 8, 332, 84, "")
  TextGadget(#Gadget_DebugTitle, 16, 12, 220, 18, "DEBUG")
  TextGadget(#Gadget_DebugInfo, 16, 30, 312, 34, "F1 toggle   G +100 gold   N next wave" + #LF$ + "L +5 lives   K clear enemies")
  ButtonGadget(#Gadget_DebugGold, 16, 66, 68, 22, "+100G")
  ButtonGadget(#Gadget_DebugWave, 88, 66, 68, 22, "+Wave")
  ButtonGadget(#Gadget_DebugLife, 160, 66, 68, 22, "+Life")
  ButtonGadget(#Gadget_DebugClear, 232, 66, 52, 22, "Clear")
  SetDebugPanelVisible(#False)

  SetGameControlsEnabled(#False)

  UpdateBuildButtons()
  RefreshSidebar()
EndProcedure

Procedure UpdateBuildButtons()
  Protected PrefixPulse.s = "  "
  Protected PrefixCannon.s = "  "
  Protected PrefixFrost.s = "  "
  Protected PrefixBeam.s = "  "
  Protected PrefixMortar.s = "  "
  Protected PrefixSky.s = "  "
  Protected PrefixBlock.s = "  "

  If CurrentBuildType = #TowerType_Pulse
    PrefixPulse = "> "
  ElseIf CurrentBuildType = #TowerType_Cannon
    PrefixCannon = "> "
  ElseIf CurrentBuildType = #TowerType_Frost
    PrefixFrost = "> "
  ElseIf CurrentBuildType = #TowerType_Beam
    PrefixBeam = "> "
  ElseIf CurrentBuildType = #TowerType_Mortar
    PrefixMortar = "> "
  ElseIf CurrentBuildType = #TowerType_Sky
    PrefixSky = "> "
  ElseIf CurrentBuildType = #TowerType_Block
    PrefixBlock = "> "
  EndIf

  SetGadgetText(#Gadget_BuildPulse, PrefixPulse + "1 Pulse   - 70")
  SetGadgetText(#Gadget_BuildCannon, PrefixCannon + "2 Cannon - 110")
  SetGadgetText(#Gadget_BuildFrost, PrefixFrost + "3 Frost  - 90")
  SetGadgetText(#Gadget_BuildBeam, PrefixBeam + "4 Beam   - 125")
  SetGadgetText(#Gadget_BuildMortar, PrefixMortar + "5 Mortar - 150")
  SetGadgetText(#Gadget_BuildSky, PrefixSky + "6 Sky    - 135")
  SetGadgetText(#Gadget_BuildBlock, PrefixBlock + "7 Block  - 50")
EndProcedure

Procedure RefreshSidebar()
  Protected InfoText.s
  Protected SelectedText.s
  Protected UpgradeCost.i
  Protected SellValue.i
  Protected WaveText.s
  Protected HoverTowerID.i
  Protected BuildCost.i

  If GameState = #GameState_Victory
    WaveText = "All 12 waves cleared"
  ElseIf GameState = #GameState_Defeat
    WaveText = "Core lost"
  ElseIf StartOverlayActive
    WaveText = "Press Start to begin"
  ElseIf WaveActive
    WaveText = "Wave " + Str(Wave) + " in progress"
  ElseIf Wave < #MaxWaves
    WaveText = "Next wave in " + StrF(WaveCountdown, 1) + "s"
  Else
    WaveText = "Arena secure"
  EndIf

  InfoText = "Wave: " + Str(Wave) + "/" + Str(#MaxWaves) + "  Level: " + Str(CurrentLevel) + "/" + Str(#LevelCount) + #LF$
  InfoText + "Core: " + Str(CoreLives) + "  Gold: " + Str(Gold) + #LF$
  InfoText + "Enemies: " + Str(EnemyAliveCount) + #LF$
  InfoText + WaveText

  If StartOverlayActive
    InfoText + #LF$ + "State: waiting to start"
  ElseIf Paused
    InfoText + #LF$ + "State: paused"
  Else
    InfoText + #LF$ + "State: live at " + StrF(GameSpeed, 0) + "x"
  EndIf

  InfoText + #LF$ + "Mode: " + ChallengeModeName(ChallengeMode) + "  Run: " + RunModeName()
  InfoText + #LF$ + "Best wave: " + Str(HighestWaveReached)

  HoverTowerID = 0
  If HoverGX >= 0 And HoverGX < #GridWidth And HoverGZ >= 0 And HoverGZ < #GridHeight
    HoverTowerID = Grid(HoverGX, HoverGZ)\towerID
  EndIf

  If SelectedTowerID = 0
    SelectedText = "Selected: none" + #LF$
    If PendingGridAction = #GridAction_Upgrade
      SelectedText + "Upgrade mode active." + #LF$
      If HoverTowerID <> 0 And FindTower(HoverTowerID)
        ForEach Towers()
          If Towers()\id = HoverTowerID
            If Towers()\type = #TowerType_Block
              SelectedText + "Blocks cannot be upgraded"
            ElseIf Towers()\level < 3
              UpgradeCost = Int(TowerBaseCost(Towers()\type) * (0.65 + 0.30 * Towers()\level))
              SelectedText + TowerName(Towers()\type) + " ready: " + Str(UpgradeCost) + " gold"
            Else
              SelectedText + TowerName(Towers()\type) + " is already maxed"
            EndIf
            Break
          EndIf
        Next
      Else
        SelectedText + "Click a placed tower to upgrade it."
      EndIf
    ElseIf PendingGridAction = #GridAction_Sell
      SelectedText + "Sell mode active." + #LF$
      If HoverTowerID <> 0 And FindTower(HoverTowerID)
        ForEach Towers()
          If Towers()\id = HoverTowerID
            SellValue = Int(Towers()\totalValue * 0.75)
            SelectedText + TowerName(Towers()\type) + " refund: " + Str(SellValue) + " gold"
            Break
          EndIf
        Next
      Else
        SelectedText + "Click a placed tower to sell it."
      EndIf
    Else
      If CurrentBuildType <> #TowerType_None
        BuildCost = TowerBaseCost(CurrentBuildType)
        SelectedText + TowerName(CurrentBuildType) + " build mode." + #LF$

        If HoverGX = -1 Or HoverGZ = -1
          SelectedText + "Move over a free tile to preview placement."
        ElseIf Grid(HoverGX, HoverGZ)\towerID <> 0
          SelectedText + "Blocked: tile occupied" + #LF$
          SelectedText + "Cost: " + Str(BuildCost) + " gold"
        ElseIf CurrentBuildType = #TowerType_Block And IsRouteEndpoint(HoverGX, HoverGZ)
          SelectedText + "Blocked: route endpoint" + #LF$
          SelectedText + "Cost: " + Str(BuildCost) + " gold"
        ElseIf CurrentBuildType = #TowerType_Block And (Grid(HoverGX, HoverGZ)\kind <> #Cell_Path And BasePathMask(HoverGX, HoverGZ) = #False)
          SelectedText + "Blocked: only route tiles" + #LF$
          SelectedText + "Cost: " + Str(BuildCost) + " gold"
        ElseIf CurrentBuildType = #TowerType_Block And CanPlaceBlockAt(HoverGX, HoverGZ) = #False
          SelectedText + "Blocked: would seal route" + #LF$
          SelectedText + "Cost: " + Str(BuildCost) + " gold"
        ElseIf CurrentBuildType <> #TowerType_Block And Grid(HoverGX, HoverGZ)\kind = #Cell_Path
          SelectedText + "Blocked: path tile" + #LF$
          SelectedText + "Cost: " + Str(BuildCost) + " gold"
        ElseIf Gold < BuildCost
          SelectedText + "Ready to build here" + #LF$
          SelectedText + "Need " + Str(BuildCost) + " gold"
        Else
          SelectedText + "Ready to build here" + #LF$
          SelectedText + "Cost: " + Str(BuildCost) + " gold"
        EndIf
      Else
        SelectedText + "Choose a build mode, then click a valid tile." + #LF$
        SelectedText + "Blocks reroute enemies from path tiles."
      EndIf
    EndIf
    If PendingGridAction = #GridAction_Upgrade
      SetGadgetText(#Gadget_Upgrade, "Upgrade: pick tower")
    Else
      SetGadgetText(#Gadget_Upgrade, "Upgrade")
    EndIf
    If PendingGridAction = #GridAction_Sell
      SetGadgetText(#Gadget_Sell, "Sell: pick tower")
    Else
      SetGadgetText(#Gadget_Sell, "Sell")
    EndIf
    DisableGadget(#Gadget_Upgrade, Bool(AnyUpgradeableTower() = 0 And PendingGridAction <> #GridAction_Upgrade))
    DisableGadget(#Gadget_Sell, Bool(AnySellableTower() = 0 And PendingGridAction <> #GridAction_Sell))
  Else
    ForEach Towers()
      If Towers()\id = SelectedTowerID
        UpgradeCost = Int(TowerBaseCost(Towers()\type) * (0.65 + 0.30 * Towers()\level))
        SellValue = Int(Towers()\totalValue * 0.75)
        SelectedText = TowerName(Towers()\type) + " tower" + #LF$
        If Towers()\type = #TowerType_Block
          SelectedText + "Reroutes ground enemies" + #LF$
          SelectedText + "No attacks or upgrades" + #LF$
          SelectedText + "Sell value: " + Str(SellValue)
          DisableGadget(#Gadget_Upgrade, #True)
          SetGadgetText(#Gadget_Upgrade, "Upgrade (n/a)")
        Else
          SelectedText + "Level " + Str(Towers()\level) + "   Range " + StrF(Towers()\range, 1) + #LF$
          SelectedText + "Damage " + StrF(Towers()\damage, 0) + "   Reload " + StrF(Towers()\fireDelay, 2) + "s" + #LF$
          SelectedText + "Targeting: " + TargetModeName(Towers()\targetMode) + #LF$
          If Towers()\type = #TowerType_Pulse Or Towers()\type = #TowerType_Beam Or Towers()\type = #TowerType_Sky
            SelectedText + "Can hit flyers" + #LF$
          Else
            SelectedText + "Ground only" + #LF$
          EndIf
          If Towers()\type = #TowerType_Pulse And Towers()\level >= 3
            SelectedText + "Special: pulse burst" + #LF$
          ElseIf Towers()\type = #TowerType_Frost And Towers()\level >= 3
            SelectedText + "Special: frost nova" + #LF$
          ElseIf Towers()\type = #TowerType_Mortar And Towers()\level >= 3
            SelectedText + "Special: impact chill" + #LF$
          ElseIf Towers()\type = #TowerType_Sky And Towers()\level >= 3
            SelectedText + "Special: twin interceptor" + #LF$
          EndIf
          If Towers()\level < 3
            SelectedText + "Upgrade: " + Str(UpgradeCost) + " gold" + #LF$
            DisableGadget(#Gadget_Upgrade, #False)
            If PendingGridAction = #GridAction_Upgrade
              SetGadgetText(#Gadget_Upgrade, "Upgrade: pick tower")
            Else
              SetGadgetText(#Gadget_Upgrade, "Upgrade")
            EndIf
          Else
            SelectedText + "Upgrade: maxed" + #LF$
            DisableGadget(#Gadget_Upgrade, #False)
            If PendingGridAction = #GridAction_Upgrade
              SetGadgetText(#Gadget_Upgrade, "Upgrade: pick tower")
            Else
              SetGadgetText(#Gadget_Upgrade, "Upgrade (max)")
            EndIf
          EndIf
          SelectedText + "Sell value: " + Str(SellValue)
        EndIf
        DisableGadget(#Gadget_Sell, Bool(AnySellableTower() = 0 And PendingGridAction <> #GridAction_Sell))
        If PendingGridAction = #GridAction_Sell
          SetGadgetText(#Gadget_Sell, "Sell: pick tower")
        Else
          SetGadgetText(#Gadget_Sell, "Sell")
        EndIf
        Break
      EndIf
    Next
  EndIf

  If GameState <> #GameState_Playing Or Wave >= #MaxWaves And WaveActive = 0
    SetGadgetText(#Gadget_Wave, "No more waves")
  ElseIf WaveActive = 0
    SetGadgetText(#Gadget_Wave, "Launch next wave (+15 gold)")
  Else
    SetGadgetText(#Gadget_Wave, "Wave underway")
  EndIf

  SetGadgetText(#Gadget_Speed, "Speed: " + StrF(GameSpeed, 0) + "x")

  If Paused
    SetGadgetText(#Gadget_Pause, "Resume")
  Else
    SetGadgetText(#Gadget_Pause, "Pause")
  EndIf

  If SelectedTowerID = 0
    SetGadgetText(#Gadget_TargetMode, "Target: none")
    DisableGadget(#Gadget_TargetMode, #True)
  Else
    ForEach Towers()
      If Towers()\id = SelectedTowerID
        If Towers()\type = #TowerType_Block
          SetGadgetText(#Gadget_TargetMode, "Target: n/a")
          DisableGadget(#Gadget_TargetMode, #True)
        Else
          SetGadgetText(#Gadget_TargetMode, "Target: " + TargetModeName(Towers()\targetMode))
          DisableGadget(#Gadget_TargetMode, #False)
        EndIf
        Break
      EndIf
    Next
  EndIf

  SetGadgetText(#Gadget_Info, InfoText)
  SetGadgetText(#Gadget_Forecast, BuildWaveForecast(Wave))
  SetGadgetText(#Gadget_Selected, SelectedText)
  SetGadgetText(#Gadget_Message, MessageLogText)

  If DebugPanelVisible
    SetGadgetText(#Gadget_DebugInfo, "F1 toggle   G +100 gold   N next wave" + #LF$ + "L +5 lives   K clear enemies" + #LF$ + "Build: " + TowerName(CurrentBuildType))
  EndIf
EndProcedure

Procedure HandleGadget(Gadget.i)
  Select Gadget
    Case #Gadget_MenuStart
      If GameState = #GameState_Playing
        If StartOverlayActive
          StartGame()
        Else
          ProcedureReturn
        EndIf
      ElseIf GameState = #GameState_Victory
        If CampaignMode And CurrentLevel < #LevelCount
          SetLevel(CurrentLevel + 1)
        EndIf
        RestartGame()
      Else
        RestartGame()
      EndIf

    Case #Gadget_MenuContinue
      CloseOverlay()

    Case #Gadget_MenuLevel
      If StartOverlayActive And Wave = 0 And EnemyAliveCount = 0 And ListSize(Towers()) = 0
        SetLevel(CurrentLevel + 1)
        RebuildBoard()
      EndIf

    Case #Gadget_MenuRunMode
      If StartOverlayActive And Wave = 0 And EnemyAliveCount = 0 And ListSize(Towers()) = 0
        CampaignMode = Bool(CampaignMode = 0)
        SetGadgetText(#Gadget_MenuRunMode, "Run Mode: " + RunModeName())
        SetLevel(CurrentLevel)
        SetStatus("Run mode set to " + RunModeName() + ".", 1.0)
      EndIf

    Case #Gadget_MenuChallenge
      If StartOverlayActive And Wave = 0 And EnemyAliveCount = 0 And ListSize(Towers()) = 0
        ApplyChallengeMode(ChallengeMode + 1)
        If ChallengeMode > #Challenge_IronCore
          ApplyChallengeMode(#Challenge_Standard)
        EndIf
        SetGadgetText(#Gadget_MenuChallenge, "Challenge: " + ChallengeModeName(ChallengeMode))
        SetLevel(CurrentLevel)
        SetStatus("Challenge set to " + ChallengeModeName(ChallengeMode) + ".", 1.0)
      EndIf

    Case #Gadget_MenuQuit
      QuitGame()

    Case #Gadget_DebugGold, #Gadget_DebugWave, #Gadget_DebugLife, #Gadget_DebugClear
      ApplyDebugAction(Gadget)

    Case #Gadget_LevelCycle
      If Wave = 0 And EnemyAliveCount = 0 And ListSize(Towers()) = 0
        SetLevel(CurrentLevel + 1)
        RebuildBoard()
      Else
        SetLevel(CurrentLevel + 1)
        RestartGame()
        SetStatus("Switched to " + LevelName(CurrentLevel) + ".", 1.0)
      EndIf

    Case #Gadget_BuildPulse
      CurrentBuildType = #TowerType_Pulse
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()

    Case #Gadget_BuildCannon
      CurrentBuildType = #TowerType_Cannon
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()

    Case #Gadget_BuildFrost
      CurrentBuildType = #TowerType_Frost
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()

    Case #Gadget_BuildBeam
      CurrentBuildType = #TowerType_Beam
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()

    Case #Gadget_BuildMortar
      CurrentBuildType = #TowerType_Mortar
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()

    Case #Gadget_BuildSky
      CurrentBuildType = #TowerType_Sky
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()

    Case #Gadget_BuildBlock
      CurrentBuildType = #TowerType_Block
      PendingGridAction = #GridAction_None
      UpdateBuildButtons()

    Case #Gadget_TargetMode
      If SelectedTowerID <> 0
        ForEach Towers()
          If Towers()\id = SelectedTowerID
            If Towers()\type = #TowerType_Block
              SetStatus("Blocks do not use targeting.", 0.9)
              Break
            EndIf
            Towers()\targetMode + 1
            If Towers()\targetMode > #TargetMode_Strongest
              Towers()\targetMode = #TargetMode_First
            EndIf
            SetStatus("Target mode: " + TargetModeName(Towers()\targetMode) + ".", 0.9)
            Break
          EndIf
        Next
      EndIf

    Case #Gadget_Upgrade
      If AnyUpgradeableTower()
        PendingGridAction = #GridAction_Upgrade
        CurrentBuildType = #TowerType_None
        UpdateBuildButtons()
        SetStatus("Upgrade mode active. Click a placed tower.", 1.2)
      Else
        SetStatus("No placed towers can be upgraded right now.", 1.2)
      EndIf

    Case #Gadget_Sell
      If AnySellableTower()
        PendingGridAction = #GridAction_Sell
        CurrentBuildType = #TowerType_None
        UpdateBuildButtons()
        SetStatus("Sell mode active. Click a placed tower.", 1.2)
      Else
        SetStatus("There is nothing to sell right now.", 1.2)
      EndIf

    Case #Gadget_Wave
      If WaveActive = 0 And GameState = #GameState_Playing And Wave < #MaxWaves
        StartWave(#True)
      EndIf

    Case #Gadget_Speed
      GameSpeedIndex + 1
      If GameSpeedIndex > 2
        GameSpeedIndex = 0
      EndIf

      Select GameSpeedIndex
        Case 0
          GameSpeed = 1.0
        Case 1
          GameSpeed = 2.0
        Case 2
          GameSpeed = 4.0
      EndSelect

    Case #Gadget_Pause
      If GameState = #GameState_Playing
        If Paused
          Paused = #False
        Else
          Paused = #True
        EndIf
      EndIf
  EndSelect

  RefreshSidebar()
EndProcedure

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 383
; FirstLine = 363
; Folding = ----
; EnableXP
; DPIAware
