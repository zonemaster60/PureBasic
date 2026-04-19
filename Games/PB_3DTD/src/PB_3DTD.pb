EnableExplicit

#WindowWidth = 1280
#WindowHeight = 780
#RenderWidth = 944
#SidebarX = 960
#SidebarWidth = 304

#GridWidth = 12
#GridHeight = 8
#CellSize = 2.5
#MaxPathPoints = 128
#MaxWaves = 12
#LevelCount = 6
#AmbientCount = 10
#RangeSegmentCount = 28
#Tau = 6.2831853

#Pick_Cell = 1 << 1
#VK_LBUTTON = $01
#VK_RBUTTON = $02
#SND_ASYNC = $0001
#SND_NODEFAULT = $0002
#SND_ALIAS = $00010000

Enumeration
  #Window_Main
EndEnumeration

Enumeration
  #Cell_Empty
  #Cell_Path
EndEnumeration

Enumeration
  #TowerType_None
  #TowerType_Pulse
  #TowerType_Cannon
  #TowerType_Frost
  #TowerType_Beam
  #TowerType_Mortar
  #TowerType_Sky
  #TowerType_Block
EndEnumeration

Enumeration
  #EnemyType_Runner
  #EnemyType_Brute
  #EnemyType_Swarm
  #EnemyType_Shield
  #EnemyType_Splitter
  #EnemyType_Glider
  #EnemyType_Leech
  #EnemyType_Siege
  #EnemyType_Overseer
  #EnemyType_Boss
EndEnumeration

Enumeration
  #Challenge_Standard
  #Challenge_Frugal
  #Challenge_Blitz
  #Challenge_IronCore
EndEnumeration

Enumeration
  #GameState_Playing
  #GameState_Victory
  #GameState_Defeat
EndEnumeration

Enumeration
  #GridAction_None
  #GridAction_Upgrade
  #GridAction_Sell
EndEnumeration

Enumeration
  #TargetMode_First
  #TargetMode_Nearest
  #TargetMode_Strongest
EndEnumeration

Enumeration
  #Gadget_Title
  #Gadget_Info
  #Gadget_Forecast
  #Gadget_LevelCycle
  #Gadget_BuildPulse
  #Gadget_BuildCannon
  #Gadget_BuildFrost
  #Gadget_BuildBeam
  #Gadget_BuildMortar
  #Gadget_BuildSky
  #Gadget_BuildBlock
  #Gadget_Upgrade
  #Gadget_Sell
  #Gadget_Wave
  #Gadget_Speed
  #Gadget_Pause
  #Gadget_TargetMode
  #Gadget_Selected
  #Gadget_Message
  #Gadget_Controls
  #Gadget_MenuTitle
  #Gadget_MenuInfo
  #Gadget_MenuStart
  #Gadget_MenuContinue
  #Gadget_MenuLevel
  #Gadget_MenuRunMode
  #Gadget_MenuProgress
  #Gadget_MenuChallenge
  #Gadget_MenuQuit
  #Gadget_DebugBack
  #Gadget_DebugTitle
  #Gadget_DebugInfo
  #Gadget_DebugGold
  #Gadget_DebugWave
  #Gadget_DebugLife
  #Gadget_DebugClear
EndEnumeration

Structure Cell
  entity.i
  decoEntity.i
  kind.i
  towerID.i
EndStructure

Structure Tower
  id.i
  type.i
  level.i
  gx.i
  gz.i
  baseEntity.i
  headEntity.i
  muzzleEntity.i
  muzzleTimer.f
  range.f
  damage.f
  fireDelay.f
  cooldown.f
  projectileSpeed.f
  splash.f
  slowPower.f
  slowTime.f
  targetMode.i
  totalValue.i
  shotCount.i
EndStructure

Structure Enemy
  id.i
  type.i
  entity.i
  accentEntity.i
  hpBackEntity.i
  hpFillEntity.i
  flashTimer.f
  hp.f
  maxHP.f
  speed.f
  burnTimer.f
  burnTick.f
  burnDamage.f
  slowFactor.f
  slowTimer.f
  shield.f
  segment.i
  progress.f
  x.f
  y.f
  z.f
  reward.i
  damageToCore.i
  flyer.i
  flightPhase.f
  regenRate.f
  slowCap.f
  abilityCooldown.f
  abilityTimer.f
  abilityState.i
  bossPhase.i
EndStructure

Structure Projectile
  id.i
  type.i
  entity.i
  targetID.i
  x.f
  y.f
  z.f
  speed.f
  damage.f
  splash.f
  slowPower.f
  slowTime.f
  special.i
EndStructure

Global version.s = "v1.0.0.3"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

Global Dim Grid.Cell(#GridWidth - 1, #GridHeight - 1)
Global Dim BasePathGX.i(#MaxPathPoints - 1)
Global Dim BasePathGZ.i(#MaxPathPoints - 1)
Global BasePathPointCount.i
Global Dim BasePathMask.i(#GridWidth - 1, #GridHeight - 1)
Global Dim PathGX.i(#MaxPathPoints - 1)
Global Dim PathGZ.i(#MaxPathPoints - 1)
Global Dim PathWX.f(#MaxPathPoints - 1)
Global Dim PathWZ.f(#MaxPathPoints - 1)
Global Dim SegmentLength.f(#MaxPathPoints - 2)
Global Dim SegmentDirX.f(#MaxPathPoints - 2)
Global Dim SegmentDirZ.f(#MaxPathPoints - 2)
Global PathPointCount.i

Global NewList Towers.Tower()
Global NewList Enemies.Enemy()
Global NewList Projectiles.Projectile()

Global NextTowerID.i = 1
Global NextEnemyID.i = 1
Global NextProjectileID.i = 1
Global EnemyAliveCount.i

Global MeshCube.i
Global MeshSphere.i
Global MeshCylinder.i
Global MeshCone.i

Global MatFloor.i
Global MatPath.i
Global MatPulse.i
Global MatCannon.i
Global MatFrost.i
Global MatBeam.i
Global MatMortar.i
Global MatSky.i
Global MatBlock.i
Global MatRunner.i
Global MatRunnerAccent.i
Global MatBrute.i
Global MatBruteAccent.i
Global MatSwarm.i
Global MatSwarmAccent.i
Global MatShield.i
Global MatShieldAccent.i
Global MatSplitter.i
Global MatSplitterAccent.i
Global MatGlider.i
Global MatGliderAccent.i
Global MatLeech.i
Global MatLeechAccent.i
Global MatSiege.i
Global MatSiegeAccent.i
Global MatOverseer.i
Global MatOverseerAccent.i
Global MatBoss.i
Global MatBossAccent.i
Global MatProjectilePulse.i
Global MatProjectileCannon.i
Global MatProjectileFrost.i
Global MatProjectileBeam.i
Global MatProjectileMortar.i
Global MatProjectileSky.i
Global MatHoverGood.i
Global MatHoverBad.i
Global MatHoverUpgrade.i
Global MatHoverSell.i
Global MatRange.i
Global MatCore.i
Global MatAccent.i
Global MatFlash.i
Global MatMuzzlePulse.i
Global MatMuzzleCannon.i
Global MatMuzzleFrost.i
Global MatMuzzleBeam.i
Global MatMuzzleMortar.i
Global MatMuzzleSky.i
Global MatHealthBack.i
Global MatHealthFillHigh.i
Global MatHealthFillMid.i
Global MatHealthFillLow.i
Global MatDecoStone.i
Global MatDecoMarker.i
Global MatAmbientA.i
Global MatAmbientB.i
Global HoverEntity.i
Global CoreEntity.i
Global Dim RangeSegments.i(#RangeSegmentCount - 1)
Global Dim AmbientEntity.i(#AmbientCount - 1)
Global Dim AmbientBaseX.f(#AmbientCount - 1)
Global Dim AmbientBaseZ.f(#AmbientCount - 1)
Global Dim AmbientPhase.f(#AmbientCount - 1)
Global RangePreviewActive.i

Global SelectedTowerID.i
Global CurrentBuildType.i = #TowerType_Pulse
Global PendingGridAction.i = #GridAction_None
Global HoverGX.i = -1
Global HoverGZ.i = -1

Global CoreLives.i = 20
Global Gold.i = 180
Global Wave.i
Global WaveActive.i
Global WaveSpawnTimer.f
Global WaveSpawned.i
Global WaveToSpawn.i
Global WaveCountdown.f = 4.0
Global GameSpeedIndex.i = 0
Global GameSpeed.f = 1.0
Global Paused.i
Global GameState.i = #GameState_Playing
Global StartOverlayActive.i = #True
Global CurrentLevel.i = 1
Global CampaignMode.i = #True
Global ChallengeMode.i = #Challenge_Standard
Global HighestWaveReached.i
Global HighestLevelCleared.i
Global TotalVictories.i
Global ChallengeStartGold.i = 180
Global ChallengeCoreLives.i = 20
Global ChallengeEnemyHealthScale.f = 1.0
Global ChallengeEnemySpeedScale.f = 1.0
Global ChallengeWaveDelayScale.f = 1.0
Global ConfigTowerDamageScale.f = 1.0
Global ConfigTowerRangeScale.f = 1.0
Global ConfigEnemyHealthScale.f = 1.0
Global ConfigEnemySpeedScale.f = 1.0
Global ConfigBurnScale.f = 1.0

Global MessageText.s = "Press Start to open the arena, then build before the first wave arrives."
Global MessageLogText.s = ""
Global MessageTimer.f = 5.0
Global DebugPanelVisible.i

Global LeftWasDown.i
Global RightWasDown.i
Global Key1WasDown.i
Global Key2WasDown.i
Global Key3WasDown.i
Global Key4WasDown.i
Global Key5WasDown.i
Global Key6WasDown.i
Global Key7WasDown.i
Global KeySpaceWasDown.i
Global KeyUWasDown.i
Global KeyTWasDown.i
Global KeySWasDown.i
Global KeyEnterWasDown.i
Global KeyPlaceWasDown.i
Global KeyF1WasDown.i
Global KeyGWasDown.i
Global KeyLWasDown.i
Global KeyNWasDown.i
Global KeyKWasDown.i

Declare.f WorldXFromGrid(GX.i)
Declare.f WorldZFromGrid(GZ.i)
Declare.i GridXFromWorld(X.f)
Declare.i GridZFromWorld(Z.f)
Declare.i IsPathCell(GX.i, GZ.i)
Declare.i WaveRemainder(Value.i, Divisor.i)
Declare.i TowerBaseCost(TowerType.i)
Declare.s TowerName(TowerType.i)
Declare.s EnemyName(EnemyType.i)
Declare.s TargetModeName(TargetMode.i)
Declare.s LevelName(Level.i)
Declare.s LevelDescription(Level.i)
Declare.s LevelBriefingText()
Declare.s RunModeName()
Declare.s ChallengeModeName(Mode.i)
Declare LoadBalanceConfig()
Declare SaveBalanceConfig()
Declare LoadProgression()
Declare SaveProgression()
Declare ApplyChallengeMode(Mode.i)
Declare SetStatus(Text.s, Duration.f)
Declare BuildPath()
Declare MarkPathSegment(X1.i, Z1.i, X2.i, Z2.i)
Declare.i RecalculatePath(ApplyToEnemies.i, ExtraBlockGX.i = -1, ExtraBlockGZ.i = -1, PreviewOnly.i = #False)
Declare RefreshBoardRouteVisuals()
Declare.i IsRouteEndpoint(GX.i, GZ.i)
Declare.i CellCanHostTower(GX.i, GZ.i, TowerType.i)
Declare.i CanPlaceBlockAt(GX.i, GZ.i)
Declare CreateFloorDecoration(GX.i, GZ.i, X.f, Z.f)
Declare FreeBoardVisuals()
Declare RebuildBoard()
Declare SetupAmbientScene()
Declare CreateMaterials()
Declare CreateMeshes()
Declare CreateBoard()
Declare CreateScene()
Declare CreateSidebar()
Declare UpdateBuildButtons()
Declare RefreshSidebar()
Declare SelectTower(TowerID.i)
Declare HideRangeIndicators()
Declare ShowRangeIndicators(CenterX.f, CenterZ.f, Radius.f)
Declare.i FindTower(TowerID.i)
Declare.i FindTowerPointer(TowerID.i)
Declare.i AnyUpgradeableTower()
Declare.f TowerPreviewRange(TowerType.i)
Declare ConfigureTowerStats(*Tower.Tower)
Declare.i BuildTower(GX.i, GZ.i, TowerType.i)
Declare UpgradeSelectedTower()
Declare UpgradeTowerByID(TowerID.i)
Declare SellSelectedTower()
Declare SellTowerByID(TowerID.i)
Declare.i PlannedBossType(CurrentWave.i)
Declare.i PlannedEnemyType(CurrentWave.i, SpawnIndex.i, SpawnCount.i)
Declare SpawnEnemy(EnemyType.i, CurrentWave.i)
Declare StartWave(EarlyBonus.i)
Declare UpdateSpawner(DT.f)
Declare.i FindEnemyPointer(EnemyID.i)
Declare UpdateEnemies(DT.f)
Declare UpdateTowers(DT.f)
Declare SpawnProjectile(*Tower.Tower, TargetID.i)
Declare ApplySlowToEnemy(*Enemy.Enemy, SlowPower.f, SlowTime.f)
Declare ApplyHitFeedback(*Enemy.Enemy, SourceType.i)
Declare DestroyEnemy(*Enemy.Enemy)
Declare ApplyImpactToEnemy(*Enemy.Enemy, Damage.f, SlowPower.f, SlowTime.f, SourceType.i)
Declare ApplyImpact(TargetID.i, X.f, Z.f, Damage.f, Splash.f, SlowPower.f, SlowTime.f, SourceType.i)
Declare UpdateProjectiles(DT.f)
Declare SpawnSplitSwarm(SourceSegment.i, SourceProgress.f)
Declare TriggerBossAbility(*Enemy.Enemy)
Declare.f EnemyTargetMetric(*Enemy.Enemy, TowerX.f, TowerZ.f, TargetMode.i)
Declare CheckWaveFinished()
Declare UpdateHover()
Declare HandleBoardClick()
Declare HandleGadget(Gadget.i)
Declare ProcessInput()
Declare QuitGame()
Declare StartGame()
Declare RestartGame()
Declare SetGameControlsEnabled(State.i)
Declare SetOverlayVisible(Visible.i, ShowContinue.i, ShowLevel.i)
Declare CloseOverlay()
Declare SetLevel(Level.i)
Declare SetDebugPanelVisible(Visible.i)
Declare ApplyDebugAction(Action.i)
Declare FreeEnemyVisuals(*Enemy.Enemy)
Declare UpdateEnemyHealthBar(*Enemy.Enemy)
Declare UpdateEnemyAccent(*Enemy.Enemy)
Declare ReprojectEnemiesToPath()
Declare.i TowerCanTargetEnemy(*Tower.Tower, *Enemy.Enemy)
Declare UpdateAmbientScene(DT.f)
Declare UpdateEffects(DT.f)
Declare ShowEndOverlay()
Declare.s BuildWaveForecast(CurrentWave.i)
Declare PlayUISound(AliasName.s)
Declare PlayTowerFireSound(TowerType.i)
Declare PlayHitSound()
Declare PlayWaveSound()

XIncludeFile "td_ui.pbi"
XIncludeFile "td_scene.pbi"
XIncludeFile "td_towers.pbi"
XIncludeFile "td_combat.pbi"
XIncludeFile "td_input.pbi"

CreateScene()
CreateSidebar()

Define LastTick.i = ElapsedMilliseconds()
Define Now.i
Define RealDT.f
Define GameDT.f

Repeat
  Now = ElapsedMilliseconds()
  RealDT = (Now - LastTick) / 1000.0
  LastTick = Now

  If RealDT > 0.05
    RealDT = 0.05
  EndIf

  ProcessInput()

  If MessageTimer > 0
    MessageTimer - RealDT
    If MessageTimer < 0
      MessageTimer = 0
    EndIf
  EndIf

  If StartOverlayActive Or Paused Or GameState <> #GameState_Playing
    GameDT = 0
  Else
    GameDT = RealDT * GameSpeed
  EndIf

  If GameDT > 0
    UpdateSpawner(GameDT)
    UpdateEnemies(GameDT)
    UpdateTowers(GameDT)
    UpdateProjectiles(GameDT)
    UpdateEffects(GameDT)

    If WaveActive = 0 And GameState = #GameState_Playing And Wave < #MaxWaves
      WaveCountdown - GameDT
      If WaveCountdown <= 0
        StartWave(#False)
      EndIf
    EndIf

    CheckWaveFinished()
  EndIf

  RefreshSidebar()
  RenderWorld()
  FlipBuffers()
ForEver

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 202
; FirstLine = 174
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_3DTD.ico
; Executable = ..\PB_3DTD.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,3
; VersionField1 = 1,0,0,3
; VersionField2 = ZoneSoft
; VersionField3 = PB_3DTD
; VersionField4 = 1.0.0.3
; VersionField5 = 1.0.0.3
; VersionField6 = A 3D Tower Defense game with levels
; VersionField7 = PB_3DTD
; VersionField8 = PB_3DTD.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60