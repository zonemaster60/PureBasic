; Starship simulation (PureBasic 6.30)
; - Galaxy map: planets (mining), stars (obstacles), starbases (dock)
; - Tactical combat when you encounter enemies
; Data-driven ship stats loaded from ships.ini

EnableExplicit

#APP_NAME = "Starship_Sim"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)
Global version.s = "v1.0.8.0"

; Probe system
Global gProbeRange.i = 3
Global gProbeAccuracy.i = 75

; Transporter system
Global gTransporterPower.i = 50
Global gTransporterRange.i = 5
Global gTransporterCrew.i = 2

; Shuttle system
Global gShuttleLaunched.i = 0
Global gShuttleCrew.i = 2
Global gShuttleCargoOre.i = 0
Global gShuttleCargoDilithium.i = 0
Global gShuttleMaxCargo.i = 10
Global gShuttleMaxCrew.i = 6
Global gShuttleAttackRange.i = 10

; Shipyard upgrades tracking
Global gUpgradeHull.i = 0
Global gUpgradeShields.i = 0
Global gUpgradeWeapons.i = 0
Global gUpgradePropulsion.i = 0
Global gUpgradePowerCargo.i = 0
Global gUpgradeProbes.i = 0
Global gUpgradeShuttle.i = 0

; Refinery system
Global gIron.i = 0
Global gAluminum.i = 0
Global gCopper.i = 0
Global gTin.i = 0
Global gBronze.i = 0

; Sound system - PureBasic Sound library
Global gSoundEnabled.i = 1
Global gSoundInitialized.i = 0

Global SoundPhaser.i
Global SoundTorpedo.i
Global SoundDisruptor.i
Global SoundExplode.i
Global SoundEngine.i
Global SoundDock.i
Global SoundAlarm.i
Global SoundWarp.i
Global SoundScan.i
Global SoundRadio.i
Global SoundPress.i
Global SoundSelect.i
Global SoundEngage.i
Global SoundClapping.i

Global gSoundEnabledSave = gSoundEnabled
Global gEngineLoopChannel.i = -1

Procedure InitSounds()
  If gSoundInitialized = 1 : ProcedureReturn : EndIf
  
  InitSound()
  
  Protected altPath.s = AppPath + "sounds" + #PS$
  
  SoundPhaser = LoadSound(#PB_Any, altPath + "phaser.wav")
  SoundTorpedo = LoadSound(#PB_Any, altPath + "torpedo.wav")
  SoundDisruptor = LoadSound(#PB_Any, altPath + "disruptor.wav")
  SoundExplode = LoadSound(#PB_Any, altPath + "explode.wav")
  SoundEngine = LoadSound(#PB_Any, altPath + "engines.wav")
  SoundDock = LoadSound(#PB_Any, altPath + "dock.wav")
  SoundAlarm = LoadSound(#PB_Any, altPath + "alarm.wav")
  SoundWarp = LoadSound(#PB_Any, altPath + "warp.wav")
  SoundScan = LoadSound(#PB_Any, altPath + "scan.wav")
  SoundRadio = LoadSound(#PB_Any, altPath + "radio.wav")
  SoundPress = LoadSound(#PB_Any, altPath + "press.wav")
  SoundSelect = LoadSound(#PB_Any, altPath + "select.wav")
  SoundEngage = LoadSound(#PB_Any, altPath + "engage.wav")
  SoundClapping = LoadSound(#PB_Any, altPath + "clapping.wav")
  
  gSoundInitialized = 1
EndProcedure

Procedure PlaySoundFX(id.i)
  If gSoundEnabled = 0 : ProcedureReturn : EndIf
  If id = 0 : ProcedureReturn : EndIf
  If IsSound(id)
    Delay(10)
    PlaySound(id)
  EndIf
EndProcedure

Declare PlayEngineSound()
Declare StartEngineLoop()
Declare StopEngineLoop()

; All sound implementations using wav files
Procedure PlayComputerBeep()
  PlaySoundFX(SoundPress)
  Delay(50)
  PlaySoundFX(SoundSelect)
EndProcedure

Procedure PlayLogBeep()
  PlaySoundFX(SoundPress)
EndProcedure

Procedure PlayErrorBeep()
  PlaySoundFX(SoundAlarm)
EndProcedure

Procedure PlayPhaserSound()
  PlaySoundFX(SoundPhaser)
EndProcedure

Procedure PlayTorpedoSound()
  PlaySoundFX(SoundTorpedo)
EndProcedure

Procedure PlayDisruptorSound()
  PlaySoundFX(SoundDisruptor)
EndProcedure

Procedure PlayImpactSound()
  PlaySoundFX(SoundExplode)
EndProcedure

Procedure PlayTransportSound()
  PlaySoundFX(SoundRadio)
  Delay(40)
  PlaySoundFX(SoundRadio)
EndProcedure

Procedure PlayMiningSound()
  PlaySoundFX(SoundRadio)
  Delay(50)
  PlaySoundFX(SoundRadio)
  Delay(50)
  PlaySoundFX(SoundRadio)
EndProcedure

Procedure PlayRedAlert()
  PlaySoundFX(SoundAlarm)
  Delay(100)
  PlaySoundFX(SoundAlarm)
  Delay(100)
  PlaySoundFX(SoundAlarm)
EndProcedure

Procedure PlayWeldingSound()
  PlaySoundFX(SoundRadio)
  Delay(30)
  PlaySoundFX(SoundRadio)
  Delay(30)
  PlaySoundFX(SoundRadio)
EndProcedure

Procedure PlayDockingSound()
  PlaySoundFX(SoundDock)
EndProcedure

Procedure PlayUndockingSound()
  PlaySoundFX(SoundDock)
  Delay(100)
  PlaySoundFX(SoundEngine)
EndProcedure

Procedure PlayExplosionSound()
  PlaySoundFX(SoundExplode)
EndProcedure

Procedure PlayProbeSound()
  PlaySoundFX(SoundScan)
EndProcedure

Procedure PlayTractorBeamSound()
  PlaySoundFX(SoundRadio)
  Delay(40)
  PlaySoundFX(SoundRadio)
  Delay(40)
  PlaySoundFX(SoundRadio)
EndProcedure

Procedure PlayCommunicationSound()
  PlaySoundFX(SoundRadio)
EndProcedure

Procedure PlayCrewChatterSound()
  PlaySoundFX(SoundRadio)
  Delay(50)
  PlaySoundFX(SoundRadio)
EndProcedure

Procedure PlayPlanetKillerSound()
  PlaySoundFX(SoundAlarm)
  Delay(50)
  PlaySoundFX(SoundAlarm)
  Delay(50)
  PlaySoundFX(SoundAlarm)
EndProcedure

Procedure PlayPlanetKillerAttackSound()
  PlaySoundFX(SoundExplode)
  Delay(80)
  PlaySoundFX(SoundExplode)
  Delay(80)
  PlaySoundFX(SoundExplode)
EndProcedure

Procedure PlayEngineSound()
  ; Engine loop now handles all engine sounds
  Global gDocked
  If gDocked = 0
    StartEngineLoop()
  EndIf
EndProcedure

Procedure StartEngineLoop()
  Global gDocked
  If gSoundEnabled = 0 : ProcedureReturn : EndIf
  If gDocked = 1 : ProcedureReturn : EndIf
  If gEngineLoopChannel > 0
    ProcedureReturn
  EndIf
  If SoundEngine And IsSound(SoundEngine)
    gEngineLoopChannel = PlaySound(SoundEngine, #PB_Sound_Loop)
    If gEngineLoopChannel = 0
      gEngineLoopChannel = -1
    EndIf
  EndIf
EndProcedure

Procedure StopEngineLoop()
  If gEngineLoopChannel > 0
    StopSound(gEngineLoopChannel)
  EndIf
  gEngineLoopChannel = -1
EndProcedure

Procedure PlayAmbientChatter()
  If gSoundEnabled = 0 : ProcedureReturn : EndIf
  If Random(100) < 15 : PlaySoundFX(SoundRadio) : EndIf
EndProcedure

Procedure PlayBeepTest()
  PlaySoundFX(SoundSelect)
  Delay(100)
  PlaySoundFX(SoundEngage)
  Delay(100)
  PlaySoundFX(SoundPress)
EndProcedure
   
Procedure PlaySoundEffect(n.s)
  Select UCase(n)
    Case "COMPUTER": PlayComputerBeep()
    Case "LOG": PlayLogBeep()
    Case "ERROR": PlayErrorBeep()
    Case "PHASER": PlayPhaserSound()
    Case "TORPEDO": PlayTorpedoSound()
    Case "IMPACT": PlayImpactSound()
    Case "TRANSPORT": PlayTransportSound()
    Case "MINING": PlayMiningSound()
    Case "REDALERT": PlayRedAlert()
    Case "WELDING": PlayWeldingSound()
    Case "DOCKING": PlayDockingSound()
    Case "UNDOCKING": PlayUndockingSound()
    Case "EXPLOSION": PlayExplosionSound()
    Case "PROBE": PlayProbeSound()
    Case "TRACTOR": PlayTractorBeamSound()
    Case "COMM": PlayCommunicationSound()
    Case "CHATTER": PlayCrewChatterSound()
    Case "PLANETKILLER": PlayPlanetKillerSound()
    Case "PKATTACK": PlayPlanetKillerAttackSound()
    Case "ENGINE": PlayEngineSound()
  EndSelect
EndProcedure

; Forward declarations (PureBasic requires declaring procedures used before definition)
Declare.s Timestamp()
Declare AppendFileLine(path.s, line.s)
Declare InitLogging()
Declare CrashHandler()
Declare.i InitShipData()
Declare.i LoadShipDataFromDat(path.s)
Declare.s ReadAllText(path.s)
Declare.i ChecksumFNV32(*mem, len.i)
Declare XorScramble(*mem, len.i, seed.i)
Declare.s IniGet(section.s, key.s, defaultValue.s)
Declare.i IniGetLong(section.s, key.s, defaultValue.i)
Declare.f IniGetFloat(section.s, key.s, defaultValue.f)
Declare LoadAllocOverrides(section.s, *s.Ship)
Declare.i PackShipsDatFromIni()
Declare DefaultShipsIniText()
Declare LogLine(s.s)
Declare PrintLog()
Declare AddCaptainLog(entry.s)
Declare PrintCaptainLog(search.s)
Declare AdvanceStardate(steps.i = 1)
Declare.s FormatStardate()
Declare RedrawGalaxy(*p.Ship)
Declare.i ClampInt(v.i, lo.i, hi.i)
Declare.f ClampF(v.f, lo.f, hi.f)
Declare.s TrimLower(s.s)
Declare.i ParseIntSafe(s.s, defaultValue.i)
Declare.s TokenAt(line.s, idx.i)
Declare.s CleanLine(s.s)
Declare PrintDivider()
Declare ResetColor()
Declare SetColorForEnt(t.i)
Declare SetColorForPercent(pct.i)
Declare.s SysText(flags.i)
Declare PrintHelpGalaxy()
Declare PrintHelpTactical()
Declare PrintAbout()
Declare PrintCmd(cmd.s)
Declare PrintLegendLine(indent.s)
Declare.i LoadShip(section.s, *s.Ship)
Declare.s LoadGameSettingString(key.s, defaultValue.s)
Declare.s SafeField(s.s)
Declare SaveAlloc(section.s, *s.Ship)
Declare.i IsAlive(*s.Ship)
Declare PrintStatusGalaxy(*p.Ship)
Declare PrintStatusTactical(*p.Ship, *e.Ship, *cs.CombatState)
Declare PrintArenaTactical(*p.Ship, *e.Ship, *cs.CombatState)
Declare ArenaPositions(range.i, *posP.Integer, *posE.Integer, *interior.Integer)
Declare PrintArenaFrame(posP.i, posE.i, fxPos.i, fxChar.s, beam.i, attackerIsEnemy.i, *cs.CombatState = 0, *e.Ship = 0)
Declare TacticalFxPhaser(range.i, attackerIsEnemy.i)
Declare TacticalFxTorpedo(range.i, attackerIsEnemy.i)
Declare.i EvasionBonus(*target.Ship)
Declare.i HitChance(range.i, *attacker.Ship, *target.Ship)
Declare ApplyDamage(*target.Ship, dmg.i)
Declare RegenAndRepair(*s.Ship, isEnemy.i)
Declare.i CombatMaxMove(*p.Ship)
Declare InitCrew(*s.Ship)
Declare.s RankName(rank.i)
Declare.s CrewRoleName(role.i)
Declare GainCrewXP(*s.Ship, role.i, xpGain.i)
Declare.i CrewBonus(*s.Ship, role.i)
Declare PrintCrew(*s.Ship)
Declare PlayerMove(*p.Ship, *cs.CombatState, dir.s, amount.i)
Declare PlayerPhaser(*p.Ship, *e.Ship, *cs.CombatState, power.i)
Declare PlayerTorpedo(*p.Ship, *e.Ship, *cs.CombatState, count.i)
Declare PlayerTractor(*p.Ship, *e.Ship, *cs.CombatState, mode.s)
Declare EnemyAI(*e.Ship, *p.Ship, *cs.CombatState)
Declare EnemyGalaxyAI(*p.Ship, *enemyTemplate.Ship, *cs.CombatState)
Declare PrintScanTactical(*p.Ship, *e.Ship, *cs.CombatState)
Declare.s EntSymbol(t.i)
Declare.i RandomEmptyCell(mapX.i, mapY.i, *outX.Integer, *outY.Integer)
Declare.i HandleArrival(*p.Ship)
Declare.i ApplyGravityWell(*p.Ship)
Declare.i HandleSun(*p.Ship)
Declare ClearSectorMap(mapX.i, mapY.i)
Declare GenerateSectorMap(mapX.i, mapY.i)
Declare GenerateGalaxy()
Declare PrintMap()
Declare ScanGalaxy()
Declare DockAtBase(*p.Ship)
Declare DockAtRefinery(*p.Ship)
Declare DockAtShipyard(*p.Ship, *base.Ship)
Declare MinePlanet(*p.Ship)
Declare Nav(*p.Ship, dir.s, steps.i)
Declare EnterCombat(*p.Ship, *enemy.Ship, *cs.CombatState)
Declare LeaveCombat()

; Autopilot
Declare.i AutopilotToMission(*p.Ship, *enemyTemplate.Ship, *enemy.Ship, *cs.CombatState)
Declare.s FindPathMission(startMapX.i, startMapY.i, startX.i, startY.i, destMapX.i, destMapY.i, destX.i, destY.i, allowWormhole.i, allowBlackhole.i, allowEnemy.i)
Declare.i StepCoord(mapX.i, mapY.i, x.i, y.i, dir.s, *outMapX.Integer, *outMapY.Integer, *outX.Integer, *outY.Integer)
Declare.i IsDangerousCell(mapX.i, mapY.i, x.i, y.i)

; Missions
Declare GenerateMission(*p.Ship)
Declare PrintMission(*p.Ship)
Declare AcceptMission(*p.Ship)
Declare AbandonMission()
Declare DeliverMission(*p.Ship)
Declare CheckMissionCompletion(*p.Ship)
Declare DefendMissionTick(*p.Ship, *enemyTemplate.Ship, *enemy.Ship, *cs.CombatState)
Declare.i FindRandomCellOfType(entType.i, *outMapX.Integer, *outMapY.Integer, *outX.Integer, *outY.Integer)
Declare.s LocText(mapX.i, mapY.i, x.i, y.i)
Declare.i SaveGame(*p.Ship)
Declare.i LoadGame(*p.Ship)

; Crew recruitment
Declare InitRecruitNames()
Declare GenerateRecruits()
Declare DismissCrew(*p.Ship, role.i)
Declare RecruitCrew(*p.Ship, index.i)
Declare.i CrewPositionFilled(*p.Ship, role.i)
Declare Main()

Enumeration
  #MODE_GALAXY = 1
  #MODE_TACTICAL = 2
EndEnumeration

Enumeration
  #ENT_EMPTY = 0
  #ENT_STAR
  #ENT_PLANET
  #ENT_BASE
  #ENT_ENEMY
  #ENT_PIRATE
  #ENT_WORMHOLE
  #ENT_BLACKHOLE
  #ENT_SUN
  #ENT_DILITHIUM
  ; Keep appended to preserve save-game entType values
  #ENT_SHIPYARD
  #ENT_ANOMALY
  #ENT_PLANETKILLER
  #ENT_REFINERY
EndEnumeration

Enumeration
  #MIS_NONE = 0
  #MIS_DELIVER_ORE
  #MIS_BOUNTY
  #MIS_SURVEY
  #MIS_DEFEND_YARD
  #MIS_PLANETKILLER
EndEnumeration

Enumeration
  #C_BLACK = 0
  #C_BLUE
  #C_GREEN
  #C_CYAN
  #C_RED
  #C_MAGENTA
  #C_BROWN
  #C_LIGHTGRAY = 7
  #C_DARKGRAY = 8
  #C_LIGHTBLUE
  #C_LIGHTGREEN
  #C_LIGHTCYAN
  #C_LIGHTRED
  #C_LIGHTMAGENTA
  #C_YELLOW
  #C_WHITE
EndEnumeration

EnumerationBinary
  #SYS_OK = 1
  #SYS_DAMAGED = 2
  #SYS_DISABLED = 4
  #SYS_TRACTOR = 8  ; Tractor beam active this turn
EndEnumeration

#GALAXY_W = 10
#GALAXY_H = 10
#MAP_W = 10
#MAP_H = 10

Enumeration
  #CREW_HELM = 1
  #CREW_WEAPONS
  #CREW_SHIELDS
  #CREW_ENGINEERING
EndEnumeration

Enumeration
  #RANK_ENSIGN = 1
  #RANK_LIEUTENANT
  #RANK_LT_COMMANDER
  #RANK_COMMANDER
  #RANK_CAPTAIN
  #RANK_ADMIRAL
EndEnumeration

Structure Crew
  name.s
  role.i
  rank.i
  xp.i
  level.i
EndStructure

Structure Ship
  name.s
  class.s
  hullMax.i
  hull.i
  shieldsMax.i
  shields.i
  reactorMax.i
  warpMax.f
  impulseMax.f
  phaserBanks.i
  torpTubes.i
  torpMax.i
  torp.i
  sensorRange.i

  weaponCapMax.i
  weaponCap.i

  fuelMax.i
  fuel.i
  oreMax.i
  ore.i
  dilithiumMax.i
  dilithium.i

  probesMax.i
  probes.i

  allocShields.i
  allocWeapons.i
  allocEngines.i

  sysEngines.i
  sysWeapons.i
  sysShields.i
  sysTractor.i
  
  crew1.Crew
  crew2.Crew
  crew3.Crew
  crew4.Crew
EndStructure

Structure CombatState
  range.i
  turn.i
  pAim.i
  eAim.i
  ; Fleet combat states (bitmask: bit 0 = ship 1, bit 1 = ship 2, etc.)
  pFleetAttack.i  ; Bitmask of which player fleet ships attacked
  pFleetHit.i     ; Bitmask of which player fleet ships got hit
  eFleetAttack.i  ; Bitmask of which enemy fleet ships attacked
  eFleetHit.i     ; Bitmask of which enemy fleet ships got hit
EndStructure

Structure Cell
  entType.i
  name.s
  richness.i
  enemyLevel.i
  spawned.i
  ore.i
  dilithium.i
EndStructure

Structure Mission
  active.i
  type.i
  title.s
  desc.s

  oreRequired.i
  killsRequired.i
  killsDone.i

  destMapX.i
  destMapY.i
  destX.i
  destY.i
  destEntType.i
  destName.s

  ; Defend shipyard mission
  turnsLeft.i
  yardHP.i
  threatLevel.i

  rewardCredits.i
EndStructure

Global LogPath.s = AppPath + "logs" + #PS$
Global DataPath.s = AppPath + "data" + #PS$
Global SavePath.s = AppPath + "save" + #PS$

Global gIniPath.s = DataPath + #APP_NAME + "_ships.ini"
Global gDatPath.s = DataPath + #APP_NAME + "_ships.dat"
Global gUserIniPath.s = DataPath + #APP_NAME + "_user.ini"

Global gSavePath.s = SavePath + #APP_NAME + "_save.txt"

Global gSessionLogPath.s = LogPath + #APP_NAME + "_session.log"
Global gCrashLogPath.s = LogPath + #APP_NAME + "_crash.log"

Global gLastCmdLine.s = ""
Global gShipsText.s = ""
Global gShipDataDesc.s = ""
Global gShipDatErr.s = ""

Global gCredits.i = 0

; Refined metals cargo
Global gIron.i = 0
Global gAluminum.i = 0
Global gCopper.i = 0
Global gTin.i = 0
Global gBronze.i = 0

Global gPowerBuff.i = 0
Global gPowerBuffTurns.i = 0
Global gMission.Mission

Global Dim gGalaxy.Cell(#GALAXY_W - 1, #GALAXY_H - 1, #MAP_W - 1, #MAP_H - 1)
Global gMode.i = #MODE_GALAXY
Global gMapX.i = 0
Global gMapY.i = 0
Global gx.i = 0
Global gy.i = 0

Global gEnemyMapX.i = -1
Global gEnemyMapY.i = -1
Global gEnemyX.i = -1
Global gEnemyY.i = -1

; Player fleet - up to 5 computer-controlled ships
Global Dim gPlayerFleet.Ship(5)
Global gPlayerFleetCount.i = 0

; Enemy fleet - up to 5 computer-controlled ships
Global Dim gEnemyFleet.Ship(5)
Global gEnemyFleetCount.i = 0

Global gDocked.i = 0

; Undo system - save state before each command
Global gUndoAvailable.i = 0
Global gUndoMapX.i, gUndoMapY.i, gUndoX.i, gUndoY.i
Global gUndoFuel.i, gUndoHull.i, gUndoShields.i
Global gUndoCredits.i, gUndoMode.i
Global gUndoOre.i, gUndoDilithium.i
Global gUndoIron.i, gUndoAluminum.i, gUndoCopper.i, gUndoTin.i, gUndoBronze.i

; Autosave system
Global gAutosaveInterval.i = 10  ; 0 = disabled, otherwise save every N turns
Global gAutosaveCounter.i = 0
Global gAutoclearInterval.i = 5  ; 0 = disabled, otherwise clear every N steps
Global gAutoclearCounter.i = 0

; Warp system
Global gWarpCooldown.i = 0  ; turns until next warp

; Stardate / Julian time system
Global gStardate.f = 25000.0  ; Starting stardate (simplified julian)
Global gGameDay.i = 1  ; Day counter

; Anomaly effects
Global gIonStormTurns.i = 0  ; ion storm reduces shields
Global gRadiationTurns.i = 0  ; radiation lowers crew rank

; Crew recruitment system
Global Dim gRecruitNames.s(3)
Global Dim gRecruitRoles.s(3)
Global gRecruitCount.i = 0

Global Dim gFirstNames.s(30)
Global Dim gLastNames.s(30)

Global Dim gLog.s(11)
Global gLogPos.i = 0

; Captain's Log - records all player actions with archives
Global Dim gCaptainLog.s(1000)  ; Current log (1000 entries)
Global gCaptainLogCount.i = 0
Global gCurrentArchive.i = 0  ; 0 = current log, 1-10 = archives

; Archives - up to 10 archives of 1000 entries each (10000 total)
Global Dim gCaptainArchive1.s(1000)
Global Dim gCaptainArchive2.s(1000)
Global Dim gCaptainArchive3.s(1000)
Global Dim gCaptainArchive4.s(1000)
Global Dim gCaptainArchive5.s(1000)
Global Dim gCaptainArchive6.s(1000)
Global Dim gCaptainArchive7.s(1000)
Global Dim gCaptainArchive8.s(1000)
Global Dim gCaptainArchive9.s(1000)
Global Dim gCaptainArchive10.s(1000)
Global Dim gArchive1Count.i(10)
Global gTotalArchives.i = 0

; Undo system
Procedure SaveUndoState(fuel.i, hull.i, shields.i, credits.i, ore.i, dilithium.i, mapX.i, mapY.i, x.i, y.i, mode.i, iron.i, aluminum.i, copper.i, tin.i, bronze.i)
  gUndoFuel = fuel
  gUndoHull = hull
  gUndoShields = shields
  gUndoCredits = credits
  gUndoOre = ore
  gUndoDilithium = dilithium
  gUndoMapX = mapX
  gUndoMapY = mapY
  gUndoX = x
  gUndoY = y
  gUndoMode = mode
  gUndoIron = iron
  gUndoAluminum = aluminum
  gUndoCopper = copper
  gUndoTin = tin
  gUndoBronze = bronze
  gUndoAvailable = 1
EndProcedure

Procedure RestoreUndoState(*fuel.Integer, *hull.Integer, *shields.Integer, *credits.Integer, *ore.Integer, *dilithium.Integer, *mapX.Integer, *mapY.Integer, *x.Integer, *y.Integer, *mode.Integer, *iron.Integer, *aluminum.Integer, *copper.Integer, *tin.Integer, *bronze.Integer)
  If gUndoAvailable = 0
    ProcedureReturn 0
  EndIf
  *fuel\i = gUndoFuel
  *hull\i = gUndoHull
  *shields\i = gUndoShields
  *credits\i = gUndoCredits
  *ore\i = gUndoOre
  *dilithium\i = gUndoDilithium
  *mapX\i = gUndoMapX
  *mapY\i = gUndoMapY
  *x\i = gUndoX
  *y\i = gUndoY
  *mode\i = gUndoMode
  *iron\i = gUndoIron
  *aluminum\i = gUndoAluminum
  *copper\i = gUndoCopper
  *tin\i = gUndoTin
  *bronze\i = gUndoBronze
  gUndoAvailable = 0
  ProcedureReturn 1
EndProcedure

Procedure.s Timestamp()
  ProcedureReturn FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
EndProcedure

Procedure AppendFileLine(path.s, line.s)
  ; Best-effort logging: never crash gameplay.
  Protected f.i
  If path = "" : ProcedureReturn : EndIf
  f = OpenFile(#PB_Any, path, #PB_File_Append)
  If f = 0
    f = CreateFile(#PB_Any, path)
  EndIf
  If f
    WriteStringN(f, line)
    CloseFile(f)
  EndIf
EndProcedure

Procedure.s ReadAllText(path.s)
  Protected f.i = ReadFile(#PB_Any, path)
  If f = 0 : ProcedureReturn "" : EndIf
  Protected len.i = Lof(f)
  If len <= 0
    CloseFile(f)
    ProcedureReturn ""
  EndIf
  Protected *m = AllocateMemory(len + 1)
  If *m = 0
    CloseFile(f)
    ProcedureReturn ""
  EndIf
  ReadData(f, *m, len)
  CloseFile(f)
  PokeB(*m + len, 0)
  Protected out.s = PeekS(*m, len, #PB_UTF8)
  FreeMemory(*m)
  ProcedureReturn out
EndProcedure

Procedure.i ChecksumFNV32(*mem, len.i)
  ; 32-bit FNV-1a (good enough to detect casual tampering)
  Protected h.q = 2166136261
  Protected i.i, b.i
  For i = 0 To len - 1
    b = PeekB(*mem + i) & $FF
    h = (h ! b) & $FFFFFFFF
    h = (h * 16777619) & $FFFFFFFF
  Next
  ProcedureReturn h & $FFFFFFFF
EndProcedure

Procedure XorScramble(*mem, len.i, seed.i)
  ; Simple stream XOR (obfuscation, not real security)
  Protected x.q = (seed & $FFFFFFFF) ! $A5A5A5A5
  Protected i.i, k.i, b.i
  For i = 0 To len - 1
    x = (x * 1664525 + 1013904223) & $FFFFFFFF
    k = (x >> 24) & $FF
    b = (PeekB(*mem + i) & $FF) ! k
    PokeB(*mem + i, b)
  Next
EndProcedure

Procedure.i LoadShipDataFromDat(path.s)
  gShipDatErr = ""
  Protected f.i = ReadFile(#PB_Any, path)
  If f = 0
    gShipDatErr = "open failed!"
    ProcedureReturn 0
  EndIf
  Protected len.i = Lof(f)
  If len < 8 + 12
    CloseFile(f)
    gShipDatErr = "file too short!"
    ProcedureReturn 0
  EndIf

  Protected *m = AllocateMemory(len)
  If *m = 0
    CloseFile(f)
    gShipDatErr = "alloc failed!"
    ProcedureReturn 0
  EndIf
  ReadData(f, *m, len)
  CloseFile(f)

  Protected magic.s = PeekS(*m, 8, #PB_Ascii)
  If magic <> "SSIMDAT1"
    FreeMemory(*m)
    gShipDatErr = "bad magic!"
    ProcedureReturn 0
  EndIf

  ; PeekL() returns signed 32-bit. On x64 builds, assigning that to .i
  ; sign-extends values with the high bit set (>= $80000000). Mask to 32-bit
  ; so comparisons use the same bit pattern as the written unsigned value.
  Protected seed.i = PeekL(*m + 8) & $FFFFFFFF
  Protected plainLen.i = PeekL(*m + 12) & $FFFFFFFF
  Protected want.i = PeekL(*m + 16) & $FFFFFFFF
  Protected payloadOffset.i = 20

  If plainLen <= 0 Or payloadOffset + plainLen > len
    FreeMemory(*m)
    gShipDatErr = "bad length!"
    ProcedureReturn 0
  EndIf

  Protected *p = *m + payloadOffset
  XorScramble(*p, plainLen, seed)
  Protected got.i = ChecksumFNV32(*p, plainLen) & $FFFFFFFF
  If got <> want
    FreeMemory(*m)
    gShipDatErr = "checksum mismatch!"
    ProcedureReturn 0
  EndIf

  gShipsText = PeekS(*p, plainLen, #PB_UTF8)
  FreeMemory(*m)
  ProcedureReturn Bool(gShipsText <> "")
EndProcedure

Procedure.s IniGet(section.s, key.s, defaultValue.s)
  Protected text.s = gShipsText
  If text = "" : ProcedureReturn defaultValue : EndIf

  text = ReplaceString(text, Chr(13), "")
  Protected n.i = CountString(text, Chr(10)) + 1
  Protected i.i, line.s, curSec.s, pos.i, k.s, v.s
  For i = 1 To n
    line = Trim(StringField(text, i, Chr(10)))
    If line = "" : Continue : EndIf
    If Left(line, 1) = ";" Or Left(line, 1) = "#" : Continue : EndIf

    If Left(line, 1) = "[" And Right(line, 1) = "]"
      curSec = Trim(Mid(line, 2, Len(line) - 2))
      Continue
    EndIf

    If LCase(curSec) <> LCase(section) : Continue : EndIf
    pos = FindString(line, "=", 1)
    If pos <= 0 : Continue : EndIf
    k = Trim(Left(line, pos - 1))
    If LCase(k) <> LCase(key) : Continue : EndIf
    v = Trim(Mid(line, pos + 1))
    ProcedureReturn v
  Next
  ProcedureReturn defaultValue
EndProcedure

Procedure.i IniGetLong(section.s, key.s, defaultValue.i)
  Protected t.s = IniGet(section, key, "")
  If t = "" : ProcedureReturn defaultValue : EndIf
  ProcedureReturn Val(t)
EndProcedure

Procedure.f IniGetFloat(section.s, key.s, defaultValue.f)
  Protected t.s = IniGet(section, key, "")
  If t = "" : ProcedureReturn defaultValue : EndIf
  ProcedureReturn ValF(t)
EndProcedure

Procedure LoadAllocOverrides(section.s, *s.Ship)
  If OpenPreferences(gUserIniPath) = 0
    ProcedureReturn
  EndIf
  PreferenceGroup(section)
  *s\allocShields = ReadPreferenceLong("AllocShields", *s\allocShields)
  *s\allocWeapons = ReadPreferenceLong("AllocWeapons", *s\allocWeapons)
  *s\allocEngines = ReadPreferenceLong("AllocEngines", *s\allocEngines)
  ClosePreferences()
EndProcedure

Procedure.i InitShipData()
  ; Prefer scrambled ships.dat; if missing, fall back to ships.ini.
  gShipsText = ""
  gShipDataDesc = "(embedded defaults)"

  If FileSize(gDatPath) > 0
    If LoadShipDataFromDat(gDatPath)
      gShipDataDesc = gDatPath
      LogLine("SHIPDATA: loaded " + gDatPath)
      ProcedureReturn 1
    Else
      LogLine("SHIPDATA: invalid " + gDatPath + " (" + gShipDatErr + ") - trying " + gIniPath)
    EndIf
  EndIf

  If FileSize(gIniPath) > 0
    gShipsText = ReadAllText(gIniPath)
    If gShipsText <> ""
      gShipDataDesc = gIniPath
      LogLine("SHIPDATA: loaded " + gIniPath)
      ProcedureReturn 1
    EndIf
  EndIf

  LogLine("SHIPDATA: no ships data found - using defaults")
  DefaultShipsIniText()
  gShipDataDesc = "defaults"
  ProcedureReturn 1
EndProcedure

Procedure DefaultShipsIniText()
  ; Minimal built-in defaults so the game runs even without ships.dat/ships.ini.
  gShipsText = "[Game]" + Chr(10)
  gShipsText + "PlayerSection=PlayerShip" + Chr(10)
  gShipsText + "EnemySection=EnemyShip" + Chr(10)
  gShipsText + Chr(10)
  gShipsText + "[PlayerShip]" + Chr(10)
  gShipsText + "Name=Player" + Chr(10)
  gShipsText + "Class=Frigate" + Chr(10)
  gShipsText + "HullMax=120" + Chr(10)
  gShipsText + "ShieldsMax=120" + Chr(10)
  gShipsText + "ReactorMax=240" + Chr(10)
  gShipsText + "WarpMax=9.0" + Chr(10)
  gShipsText + "ImpulseMax=1.0" + Chr(10)
  gShipsText + "PhaserBanks=8" + Chr(10)
  gShipsText + "TorpedoTubes=2" + Chr(10)
  gShipsText + "TorpedoesMax=12" + Chr(10)
  gShipsText + "SensorRange=20" + Chr(10)
  gShipsText + "WeaponCapMax=240" + Chr(10)
  gShipsText + "FuelMax=120" + Chr(10)
  gShipsText + "OreMax=60" + Chr(10)
  gShipsText + "DilithiumMax=20" + Chr(10)
  gShipsText + "AllocShields=33" + Chr(10)
  gShipsText + "AllocWeapons=34" + Chr(10)
  gShipsText + "AllocEngines=33" + Chr(10)
  gShipsText + Chr(10)
  gShipsText + "[EnemyShip]" + Chr(10)
  gShipsText + "Name=Raider" + Chr(10)
  gShipsText + "Class=Raider" + Chr(10)
  gShipsText + "HullMax=100" + Chr(10)
  gShipsText + "ShieldsMax=90" + Chr(10)
  gShipsText + "ReactorMax=210" + Chr(10)
  gShipsText + "WarpMax=8.0" + Chr(10)
  gShipsText + "ImpulseMax=1.0" + Chr(10)
  gShipsText + "PhaserBanks=6" + Chr(10)
  gShipsText + "TorpedoTubes=2" + Chr(10)
  gShipsText + "TorpedoesMax=8" + Chr(10)
  gShipsText + "SensorRange=18" + Chr(10)
  gShipsText + "WeaponCapMax=210" + Chr(10)
  gShipsText + "FuelMax=100" + Chr(10)
  gShipsText + "OreMax=0" + Chr(10)
  gShipsText + "AllocShields=33" + Chr(10)
  gShipsText + "AllocWeapons=34" + Chr(10)
  gShipsText + "AllocEngines=33" + Chr(10)
EndProcedure

Procedure.i PackShipsDatFromIni()
  Protected text.s = ReadAllText(gIniPath)
  If text = "" : ProcedureReturn 0 : EndIf

  Protected plainLen.i = StringByteLength(text, #PB_UTF8)
  If plainLen <= 0 : ProcedureReturn 0 : EndIf

  ; StringByteLength() excludes NUL; PokeS(...,-1,UTF8) writes a terminator.
  ; Allocate one extra byte to avoid heap overrun/corruption.
  Protected *p = AllocateMemory(plainLen + 1)
  If *p = 0 : ProcedureReturn 0 : EndIf
  PokeS(*p, text, -1, #PB_UTF8)
  PokeB(*p + plainLen, 0)

  Protected fnv.i = ChecksumFNV32(*p, plainLen)
  Protected seed.i = (Date() & $7FFFFFFF) ! $13579BDF
  XorScramble(*p, plainLen, seed)

  Protected f.i = CreateFile(#PB_Any, gDatPath)
  If f = 0
    FreeMemory(*p)
    ProcedureReturn 0
  EndIf
  WriteString(f, "SSIMDAT1", #PB_Ascii)
  WriteLong(f, seed)
  WriteLong(f, plainLen)
  WriteLong(f, fnv)
  WriteData(f, *p, plainLen)
  CloseFile(f)
  FreeMemory(*p)
  ProcedureReturn 1
EndProcedure

Procedure InitLogging()
  AppendFileLine(gSessionLogPath, "---")
  AppendFileLine(gSessionLogPath, Timestamp() + " session start")
  AppendFileLine(gSessionLogPath, "data=" + gDatPath + " (fallback " + gIniPath + ")")
EndProcedure

Procedure CrashHandler()
  ; Called by OnErrorCall(); keep this short/safe.
  Protected msg.s
  msg = Timestamp() + " crash"
  msg + " | msg=" + ErrorMessage()
  msg + " | code=" + Str(ErrorCode())
  msg + " | file=" + ErrorFile()
  msg + " | line=" + Str(ErrorLine())
  msg + " | addr=" + Str(ErrorAddress())
  msg + " | mode=" + Str(gMode)
  msg + " | loc=" + Str(gMapX) + "," + Str(gMapY) + "," + Str(gx) + "," + Str(gy)
  msg + " | last_cmd=" + gLastCmdLine
  AppendFileLine(gCrashLogPath, msg)
  AppendFileLine(gSessionLogPath, msg)
EndProcedure

Macro CurCell(x, y)
  gGalaxy(gMapX, gMapY, x, y)
EndMacro

Procedure LogLine(s.s)
  gLog(gLogPos) = s
  gLogPos + 1
  If gLogPos > ArraySize(gLog())
    gLogPos = 0
  EndIf

  AppendFileLine(gSessionLogPath, Timestamp() + " " + s)
EndProcedure

Procedure PrintLog()
  Protected n.i = ArraySize(gLog()) + 1
  Protected i.i, idx.i, line.s
  For i = 0 To n - 1
    idx = (gLogPos + i) % n
    line = gLog(idx)
    If line <> ""
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      Print("- ")
      ResetColor()
      PrintN(line)
    EndIf
  Next
EndProcedure

Procedure AdvanceStardate(steps.i = 1)
  ; Each turn advances stardate by 0.1 per step
  gStardate = gStardate + (0.1 * steps)
  ; Every 10 turns = 1 day
  Protected totalTurns.i = Int(gStardate * 10) - 250000
  gGameDay = Int(totalTurns / 10) + 1
EndProcedure

Procedure.s FormatStardate()
  Protected dayStr.s = "Day " + Str(gGameDay)
  Protected stardateStr.s = " [" + FormatNumber(gStardate, 1) + "]"
  ProcedureReturn dayStr + stardateStr
EndProcedure

Procedure AddCaptainLog(entry.s)
  ; Prepend stardate to entry
  Protected loggedEntry.s = FormatStardate() + " " + entry
  
  If gCaptainLogCount < ArraySize(gCaptainLog())
    gCaptainLog(gCaptainLogCount) = entry
    gCaptainLogCount + 1
  Else
    ; Log is full - archive it
    If gTotalArchives < 10
      ; Archive current log
      gTotalArchives + 1
      Protected arcNum.i = gTotalArchives
      
      ; Copy current log to archive
      Protected j.i
      Select arcNum
        Case 1
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive1(j) = gCaptainLog(j)
          Next
          gArchive1Count(1) = ArraySize(gCaptainLog())
        Case 2
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive2(j) = gCaptainLog(j)
          Next
          gArchive1Count(2) = ArraySize(gCaptainLog())
        Case 3
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive3(j) = gCaptainLog(j)
          Next
          gArchive1Count(3) = ArraySize(gCaptainLog())
        Case 4
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive4(j) = gCaptainLog(j)
          Next
          gArchive1Count(4) = ArraySize(gCaptainLog())
        Case 5
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive5(j) = gCaptainLog(j)
          Next
          gArchive1Count(5) = ArraySize(gCaptainLog())
        Case 6
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive6(j) = gCaptainLog(j)
          Next
          gArchive1Count(6) = ArraySize(gCaptainLog())
        Case 7
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive7(j) = gCaptainLog(j)
          Next
          gArchive1Count(7) = ArraySize(gCaptainLog())
        Case 8
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive8(j) = gCaptainLog(j)
          Next
          gArchive1Count(8) = ArraySize(gCaptainLog())
        Case 9
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive9(j) = gCaptainLog(j)
          Next
          gArchive1Count(9) = ArraySize(gCaptainLog())
        Case 10
          For j = 0 To ArraySize(gCaptainLog()) - 1
            gCaptainArchive10(j) = gCaptainLog(j)
          Next
          gArchive1Count(10) = ArraySize(gCaptainLog())
      EndSelect
      
      ; Clear current log and add new entry
      Protected k.i
      For k = 0 To ArraySize(gCaptainLog()) - 1
        gCaptainLog(k) = ""
      Next
      gCaptainLog(0) = entry
      gCaptainLogCount = 1
    Else
      ; All archives full - shift current log like before
      Protected m.i
      For m = 0 To ArraySize(gCaptainLog()) - 2
        gCaptainLog(m) = gCaptainLog(m + 1)
      Next
      gCaptainLog(ArraySize(gCaptainLog())) = entry
    EndIf
  EndIf
EndProcedure

Procedure PrintCaptainLog(search.s)
  Protected shownCount.i, a.i, viewArc.i, startIdx.i, j.i
  Protected searchArc.s, arcPrefix.s, arcNum.s, arrPtr.s, entryLower.s
  Protected maxShow.i = 20
  Protected i.i
  
  PrintDivider()
  
  ; Check for archive selection
  search = TrimLower(search)
  shownCount = 0
  
  ; Handle archive commands
  If search = "archives" Or search = "archive"
    PrintN("Captain's Log Archives:")
    PrintN("")
    PrintN("Current Log: " + Str(gCaptainLogCount) + " entries")
    For a = 1 To gTotalArchives
      PrintN("Archive " + Str(a) + ": " + Str(gArchive1Count(a)) + " entries")
    Next
    If gTotalArchives = 0
      PrintN("No archives yet.")
    EndIf
    PrintN("")
    PrintN("Use LOG to view current, or LOG ARCHIVE <1-" + Str(gTotalArchives) + "> to view an archive.")
    PrintDivider()
    ProcedureReturn
  EndIf
  
  arcPrefix = "ARCHIVE "
  If FindString(search, arcPrefix) = 1
    ; View specific archive
    arcNum = RemoveString(search, arcPrefix)
    arcNum = RemoveString(arcNum, " ")
    viewArc = ParseIntSafe(arcNum, 0)
    
    If viewArc < 1 Or viewArc > gTotalArchives
      PrintN("Archive " + Str(viewArc) + " does not exist.")
      PrintDivider()
      ProcedureReturn
    EndIf
    
    ; Show archive
    PrintN("Captain's Log - Archive " + Str(viewArc) + ":")
    PrintN("")
    
    startIdx = gArchive1Count(viewArc) - 20
    If startIdx < 0 : startIdx = 0 : EndIf
    
    searchArc = RemoveString(search, "archive " + arcNum)
    searchArc = Trim(searchArc)
    
    For j = startIdx To gArchive1Count(viewArc) - 1
      Select viewArc
        Case 1 : arrPtr = gCaptainArchive1(j)
        Case 2 : arrPtr = gCaptainArchive2(j)
        Case 3 : arrPtr = gCaptainArchive3(j)
        Case 4 : arrPtr = gCaptainArchive4(j)
        Case 5 : arrPtr = gCaptainArchive5(j)
        Case 6 : arrPtr = gCaptainArchive6(j)
        Case 7 : arrPtr = gCaptainArchive7(j)
        Case 8 : arrPtr = gCaptainArchive8(j)
        Case 9 : arrPtr = gCaptainArchive9(j)
        Case 10 : arrPtr = gCaptainArchive10(j)
      EndSelect
      
      If arrPtr <> ""
        If searchArc <> ""
          If FindString(TrimLower(arrPtr), searchArc) > 0
            PrintN(arrPtr)
            shownCount + 1
          EndIf
        Else
          PrintN(arrPtr)
          shownCount + 1
        EndIf
      EndIf
    Next
    
    If shownCount = 0
      If searchArc <> ""
        PrintN("No entries found matching: " + searchArc)
      Else
        PrintN("No entries in this archive.")
      EndIf
    EndIf
    PrintN("")
    PrintN("Total entries: " + Str(gArchive1Count(viewArc)))
    PrintDivider()
    ProcedureReturn
  EndIf
  
  ; Show current log
  PrintN("Captain's Log:")
  PrintN("")
  
  If search = ""
    ; Show last entries
    startIdx = gCaptainLogCount - maxShow
    If startIdx < 0 : startIdx = 0 : EndIf
    
    For i = startIdx To gCaptainLogCount - 1
      If i >= 0 And i < ArraySize(gCaptainLog()) + 1
        If gCaptainLog(i) <> ""
          PrintN(gCaptainLog(i))
          shownCount + 1
        EndIf
      EndIf
    Next
  Else
    ; Search entries
    For i = 0 To gCaptainLogCount - 1
      If gCaptainLog(i) <> ""
        entryLower = TrimLower(gCaptainLog(i))
        If FindString(entryLower, search) > 0
          PrintN(gCaptainLog(i))
          shownCount + 1
        EndIf
      EndIf
    Next
  EndIf
  
  If shownCount = 0
    If search <> ""
      PrintN("No entries found matching: " + search)
    Else
      PrintN("No log entries yet.")
    EndIf
  EndIf
  PrintN("")
  PrintN("Total entries: " + Str(gCaptainLogCount))
  If gTotalArchives > 0
    PrintN("Archives available: " + Str(gTotalArchives))
  EndIf
  PrintN("Usage: LOG - show recent | LOG <search> - search entries")
  PrintN("       LOG ARCHIVES - list all archives")
  PrintN("       LOG ARCHIVE <1-10> - view archive (add search term)")
  PrintN("       LOG PURGE YES - delete all current log entries")
  PrintDivider()
EndProcedure

Procedure ClearLog()
  Protected n.i = ArraySize(gLog()) + 1
  Protected i.i
  For i = 0 To n - 1
    gLog(i) = ""
  Next
  gLogPos = 0
EndProcedure

;==============================================================================
; RedrawGalaxy(*p.Ship)
; Refreshes the galaxy display by showing:
;   - Status panel (ship info, fuel, cargo, location)
;   - Sector/galaxy map (dual-panel display)
;   - Legend for map symbols
; Called after every player command to keep display current.
;==============================================================================
Procedure RedrawGalaxy(*p.Ship)
  ClearConsole()
  ResetColor()
  PrintN("Starship Console: (Galaxy + Tactical)")
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  PrintN("Galaxy: (" + Str(gMapX) + "," + Str(gMapY) + ") of " + Str(#GALAXY_W) + "x" + Str(#GALAXY_H) + " Type HELP for commands")
  ResetColor()
  PrintN("")
  PrintStatusGalaxy(*p)
  PrintMap()
  PrintDivider()
  PrintN("Recent:")
  PrintLog()
  PrintDivider()
EndProcedure

Procedure.i ClampInt(v.i, lo.i, hi.i)
  If hi < lo : ProcedureReturn lo : EndIf
  If v < lo : ProcedureReturn lo : EndIf
  If v > hi : ProcedureReturn hi : EndIf
  ProcedureReturn v
EndProcedure

Procedure.f ClampF(v.f, lo.f, hi.f)
  If hi < lo : ProcedureReturn lo : EndIf
  If v < lo : ProcedureReturn lo : EndIf
  If v > hi : ProcedureReturn hi : EndIf
  ProcedureReturn v
EndProcedure

Procedure.s TrimLower(s.s)
  ProcedureReturn LCase(Trim(s))
EndProcedure

Procedure.i ParseIntSafe(s.s, defaultValue.i)
  Protected t.s = Trim(s)
  If t = "" : ProcedureReturn defaultValue : EndIf
  ProcedureReturn Val(t)
EndProcedure

Procedure.s TokenAt(line.s, idx.i)
  Protected n.i = CountString(Trim(line), " ") + 1
  Protected i.i, t.s, c.i
  line = Trim(line)
  If line = "" : ProcedureReturn "" : EndIf
  For i = 1 To n
    t = StringField(line, i, " ")
    If t <> ""
      c + 1
      If c = idx : ProcedureReturn t : EndIf
    EndIf
  Next
  ProcedureReturn ""
EndProcedure

Procedure.s CleanLine(s.s)
  ; Keep only printable ASCII plus spaces; avoids stray control chars from some consoles/stdin.
  Protected out.s = ""
  Protected i.i, ch.i
  For i = 1 To Len(s)
    ch = Asc(Mid(s, i, 1))
    If ch = 9
      out + " "
    ElseIf ch >= 32 And ch <= 126
      out + Chr(ch)
    EndIf
  Next
  ProcedureReturn out
EndProcedure

Procedure.s SafeField(s.s)
  ; Save-file fields are | delimited and line-based.
  s = ReplaceString(s, Chr(13), " ")
  s = ReplaceString(s, Chr(10), " ")
  s = ReplaceString(s, "|", "/")
  ProcedureReturn s
EndProcedure

Procedure PrintDivider()
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  PrintN("------------------------------------------------------------")
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
EndProcedure

Procedure ResetColor()
  ConsoleColor(#C_WHITE, #C_BLACK)
EndProcedure

Procedure PrintCmd(cmd.s)
  ; Simple emphasis for command words in help
  ConsoleColor(#C_WHITE, #C_BLACK)
  PrintN("  " + cmd)
  ResetColor()
EndProcedure

Procedure PrintLegendLine(indent.s)
  ; Prints a colorized legend line (caller controls surrounding text)
  Print(indent)
  ConsoleColor(#C_WHITE, #C_BLACK) : Print("@") : ResetColor() : Print("=YourShip")
  PrintN("")
  Print(indent)
  ConsoleColor(#C_DARKGRAY, #C_BLACK) : Print(".") : ResetColor() : Print("=EmptySector ")
  ConsoleColor(#C_LIGHTBLUE, #C_BLACK) : Print("O") : ResetColor() : Print("=Planet ")
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("*") : ResetColor() : Print("=Star (blocked) ")
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK) : Print("%") : ResetColor() : Print("=Starbase ")
  ConsoleColor(#C_GREEN, #C_BLACK) : Print("+") : ResetColor() : Print("=Shipyard")
  PrintN("")
  Print(indent)
  ConsoleColor(#C_LIGHTRED, #C_BLACK) : Print("E") : ResetColor() : Print("=EnemyShip ")
  ConsoleColor(#C_LIGHTRED, #C_BLACK) : Print("P") : ResetColor() : Print("=PirateShip ")
  ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK) : Print("#") : ResetColor() : Print("=Wormhole ")
  ConsoleColor(#C_WHITE, #C_BLACK) : Print("?") : ResetColor() : Print("=Blackhole ")
  ConsoleColor(#C_BROWN, #C_BLACK) : Print("S") : ResetColor() : Print("=Sun (blocked)")
  PrintN("")
  Print(indent)
  ConsoleColor(#C_MAGENTA, #C_BLACK) : Print("D") : ResetColor() : Print("=Dilithium ")
  ConsoleColor(#C_LIGHTBLUE, #C_BLACK) : Print("A") : ResetColor() : Print("=Anomaly ")
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK) : Print("<") : ResetColor() : Print("=Planet Killer ")
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("R") : ResetColor() : PrintN("=Refinery")
EndProcedure

Procedure SetColorForEnt(t.i)
  Select t
    Case #ENT_EMPTY
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
    Case #ENT_STAR
      ConsoleColor(#C_YELLOW, #C_BLACK)
    Case #ENT_PLANET
      ConsoleColor(#C_LIGHTBLUE, #C_BLACK)
    Case #ENT_BASE
      ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    Case #ENT_SHIPYARD
      ConsoleColor(#C_GREEN, #C_BLACK)
    Case #ENT_ENEMY
      ConsoleColor(#C_LIGHTRED, #C_BLACK)
    Case #ENT_PIRATE
      ConsoleColor(#C_LIGHTRED, #C_BLACK)
    Case #ENT_WORMHOLE
      ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK)
    Case #ENT_BLACKHOLE
      ConsoleColor(#C_WHITE, #C_BLACK)
    Case #ENT_SUN
      ; Approx orange
      ConsoleColor(#C_BROWN, #C_BLACK)
    Case #ENT_DILITHIUM
      ConsoleColor(#C_MAGENTA, #C_BLACK)
    Case #ENT_ANOMALY
      ConsoleColor(#C_CYAN, #C_BLACK)
    Case #ENT_PLANETKILLER
      ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    Case #ENT_REFINERY
      ConsoleColor(#C_YELLOW, #C_BLACK)
    Default
      ResetColor()
  EndSelect
EndProcedure

Procedure SetColorForPercent(pct.i)
  pct = ClampInt(pct, 0, 100)
  If pct >= 67
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  ElseIf pct >= 34
    ConsoleColor(#C_YELLOW, #C_BLACK)
  Else
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
  EndIf
EndProcedure

Procedure.s SysText(flags.i)
  If (flags & #SYS_DISABLED) : ProcedureReturn "DISABLED" : EndIf
  If (flags & #SYS_DAMAGED)  : ProcedureReturn "DAMAGED"  : EndIf
  ProcedureReturn "OK"
EndProcedure

Procedure PrintHelpGalaxy()
  PrintDivider()
  PrintN("Galaxy Commands:")
  PrintCmd("HELP")
  PrintN("    Show this help")
  PrintN("")
  PrintCmd("ABOUT")
  PrintN("    Show app info (name, version, creator, email, website)")
  PrintN("")
  PrintCmd("STATUS")
  PrintN("    Show ship status, fuel, ore, and systems")
  PrintN("")
  PrintCmd("ALLOC <engines> <weapons> <shields>")
  PrintN("    Set reactor power distribution (sum must be <= 100)")
  PrintN("    Default: 33 34 33")
  PrintN("    Example: ALLOC 40 40 20")
  PrintN("")
  PrintCmd("CREW")
  PrintN("    Show crew members and their experience")
  PrintN("")
  PrintCmd("LOG <search>")
  PrintN("    View captain's log or search for entries")
  PrintN("    LOG ARCHIVES - list all archives")
  PrintN("    LOG ARCHIVE <1-10> <search> - view archive")
  PrintN("    LOG PURGE YES - delete all current log entries")
  PrintN("    Example: LOG        (show recent)")
  PrintN("    Example: LOG planet (search for 'planet')")
  PrintN("")
  PrintCmd("MAP")
  PrintN("    Show the sector map")
  PrintN("    Legend:")
  PrintLegendLine("      ")
  PrintN("      X=Current map M=Mission map !=Mission target")
  PrintN("")
  PrintCmd("CLEAR")
  PrintN("    Clear console and refresh the galaxy map")
  PrintN("")
  PrintCmd("UNDO")
  PrintN("    Undo last command (restore position and resources)")
  PrintN("    Useful if you get sucked into a black hole or sun!")
  PrintN("")
  PrintCmd("UPGRADES")
  PrintN("    Show installed shipyard upgrades")
  PrintN("")
  PrintCmd("FLEET")
  PrintN("    Manage your fleet (up to 5 computer-controlled ships)")
  PrintN("    FLEET ADD    - Add ship to fleet (must be docked)")
  PrintN("    FLEET REMOVE - Remove last fleet ship")
  PrintN("")
  PrintCmd("SCAN")
  PrintN("    Show non-empty contents of adjacent sectors")
  PrintN("")
  PrintCmd("LONGSCAN")
  PrintN("    Long range scan - shows sectors within 2 steps")
  PrintN("")
  PrintCmd("NAV <heading> <steps>")
  PrintN("    Move using compass heading: 0=N, 45=NE, 90=E, 135=SE,")
  PrintN("    180=S, 225=SW, 270=W, 315=NW")
  PrintN("    Costs 1 fuel per sector")
  PrintN("    Examples: NAV 0 2 | NAV 90 3 | NAV 315 1")
  PrintN("")
  PrintCmd("WARP <x> <y>")
  PrintN("    Warp to a specific galaxy location (right side map)")
  PrintN("    Costs 5 dilithium, 10 turn cooldown between warps")
  PrintN("    Example: WARP 3 2")
  PrintN("")
  PrintCmd("MINE")
  PrintN("    Mine ore when in a planet sector (O), costs 2 fuel")
  PrintN("    Can also mine dilithium crystals (D)")
  PrintN("    Example: MINE")
  PrintN("    Cheat: MINE miner2049er fills cargo hold")
  PrintN("")
  PrintCmd("LAUNCHPROBE <x> <y>")
  PrintN("    Launch a probe to scan a distant galaxy sector")
  PrintN("    Reveals all stars, planets, enemies, bases, etc.")
  PrintN("    Example: LAUNCHPROBE 3 2")
  PrintN("")
  PrintCmd("LAUNCHSHUTTLE [LAUNCH|RECALL|MINE] [crew]")
  PrintN("    Launch shuttle craft (must be docked at starbase)")
  PrintN("    LAUNCHSHUTTLE LAUNCH [n] - Launch with 2-" + Str(gShuttleMaxCrew) + " crew")
  PrintN("    LAUNCHSHUTTLE RECALL    - Return shuttle, transfer cargo to ship")
  PrintN("    LAUNCHSHUTTLE MINE      - Collect resources from planet/cluster")
  PrintN("    Can attack enemies in combat or mine resources from planets")
  PrintN("    Shuttle capacity: " + Str(gShuttleMaxCargo) + " units ore/dilithium, up to " + Str(gShuttleMaxCrew) + " crew")
  PrintN("")
  PrintCmd("TRANSPORTER <ORE|DILITHIUM|ALL>")
  PrintN("    Beam up mined resources from planet/cluster to cargo")
  PrintN("    Use after MINE to transport extracted resources")
  PrintN("    Example: TRANSPORTER ALL")
  PrintN("")
  PrintCmd("REFUEL")
  PrintN("    Convert dilithium crystals to fuel (10 fuel per crystal)")
  PrintN("    Example: REFUEL")
  PrintN("")
  PrintCmd("DOCK")
  PrintN("    Dock when in a starbase (%), shipyard (+), or refinery (R)")
  PrintN("    Starbases/shipyards: repair/refuel/rearm")
  PrintN("    Refineries: REFINE ore / dilithium, SELL ore/metals")
  PrintN("    Example: DOCK")
  PrintN("")
  PrintN("  Refinery Commands (when docked at R):")
  PrintN("    REFINE           - Convert 1 ore to random refined metal (free)")
  PrintN("    REFINE ALL       - Convert all ore in cargo to refined metals")
  PrintN("    SELL ORE         - Sell all ore (1 credit each)")
  PrintN("    SELL IRON        - Sell all iron (5 credits each)")
  PrintN("    SELL ALUMINUM    - Sell all aluminum (8 credits each)")
  PrintN("    SELL COPPER      - Sell all copper (12 credits each)")
  PrintN("    SELL TIN         - Sell all tin (15 credits each)")
  PrintN("    SELL BRONZE      - Sell all bronze (25 credits each)")
  PrintN("    SELL ALL         - Sell all cargo")
  PrintN("")
  PrintCmd("RECRUIT <number>")
  PrintN("    Hire a recruit (available at starbases)")
  PrintN("    Example: RECRUIT 1")
  PrintN("")
  PrintCmd("DISMISS <role>")
  PrintN("    Dismiss crew member: HELM, WEAPONS, SHIELDS, or ENGINEERING")
  PrintN("    Example: DISMISS WEAPONS")
  PrintN("")
  PrintCmd("CLEAR")
  PrintN("    Clear console and refresh the galaxy map display")
  PrintN("    Example: CLEAR")
  PrintN("")
  PrintCmd("SHOWMETHEMONEY")
  PrintN("    Cheat: +500 credits (works in galaxy mode)")
  PrintN("")
  PrintCmd("SPAWNYARD")
  PrintN("    Cheat: spawn a shipyard in current sector")
  PrintN("")
  PrintCmd("SPAWNBASE")
  PrintN("    Cheat: spawn a starbase in current sector")
  PrintN("")
  PrintCmd("SPAWNREFINERY")
  PrintN("    Cheat: spawn a refinery in current sector")
  PrintN("")
  PrintCmd("SPAWNCLUSTER")
  PrintN("    Cheat: spawn a dilithium cluster in current sector")
  PrintN("")
  PrintCmd("SPAWNWORMHOLE")
  PrintN("    Cheat: spawn a wormhole in current sector")
  PrintN("")
  PrintCmd("SPAWNANOMALY")
  PrintN("    Cheat: spawn a spatial anomaly in current sector")
  PrintN("")
  PrintCmd("SPAWNPLANETKILLER")
  PrintN("    Cheat: spawn a Planet Killer in current sector")
  PrintN("")
  PrintCmd("REMOVESPAWN")
  PrintN("    Remove spawned objects (base, yard, cluster, wormhole, anomaly, planetkiller)")
  PrintN("")
  PrintCmd("SAVE")
  PrintN("    Save game to file")
  PrintN("")
  PrintCmd("AUTOSAVE <turns>")
  PrintN("    Enable autosave every N turns (0 to disable)")
  PrintN("    Example: AUTOSAVE 10")
  PrintN("")
  PrintCmd("AUTOCLEAR <turns>")
  PrintN("    Enable autoclear every N turns (0 to disable)")
  PrintN("    Example: AUTOCLEAR 5")
  PrintN("")
  PrintCmd("MISSIONS")
  PrintN("    Show mission board + current mission")
  PrintN("    Example: MISSIONS")
  PrintN("")
  PrintCmd("COMPUTER")
  PrintN("    Autopilot to the active mission destination")
  PrintN("    Stops early on enemy contact, hazards, or low fuel")
  PrintN("")
  PrintCmd("ACCEPT")
  PrintN("    Accept the offered mission")
  PrintN("    Example: ACCEPT")
  PrintN("")
  PrintCmd("ABANDON")
  PrintN("    Abandon your current mission")
  PrintN("    Example: ABANDON")
  PrintN("")
  PrintCmd("SAVE")
  PrintN("    Save the current session state")
  PrintN("    Example: SAVE")
  PrintN("")
  PrintCmd("PACK")
  PrintN("    Create/refresh " + gDatPath + " from " + gIniPath)
  PrintN("    This is an obfuscated ship data file with a tamper checksum")
  PrintN("    Example: PACK")
  PrintN("")
  PrintCmd("LOAD")
  PrintN("    Load the last saved session state")
  PrintN("    Example: LOAD")
  PrintN("")
  PrintN("  Notes:")
  PrintN("    Deliver missions complete when you DOCK at the destination base.")
  PrintN("    Survey missions complete when you SCAN while at the destination planet.")
  PrintN("")
  PrintN("  Combat:")
  PrintN("    Enemies are marked E. Moving into an enemy sector enters tactical mode.")
  PrintN("    In tactical mode, type HELP for PHASER/TRACTOR/TRANSPORTER/TORPEDO/MOVE/ALLOC/FLEE.")
  PrintN("")
  PrintN("  Hazards:")
  PrintN("    # = Wormhole (teleports you to a random map/sector, costs 1 fuel)")
  PrintN("    ? = Black hole (gravity well; on entry: random teleport, severe damage + scramble, or destruction)")
  PrintN("    S = Sun (fatal; gravity well may pull you in if adjacent)")
  PrintN("")
  PrintCmd("QUIT")
  PrintCmd("EXIT")
  PrintN("    Exit the game")
  PrintDivider()
EndProcedure

Procedure PrintAbout()
  PrintDivider()
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  PrintN(#APP_NAME + " - " + version)
  ResetColor()
  PrintN("-----------------------")
  PrintN("Creator: David Scouten (zonemaster60)")
  PrintN("Email: " + #EMAIL_NAME)
  PrintN("Website: https://github.com/zonemaster60")
  PrintDivider()
EndProcedure

Procedure.i SaveGame(*p.Ship)
  Protected f.i = CreateFile(#PB_Any, gSavePath)
  If f = 0
    LogLine("SAVE: failed to write " + gSavePath)
    ProcedureReturn 0
  EndIf

  WriteStringN(f, "version|1")
  WriteStringN(f, "mode|" + Str(gMode))
  WriteStringN(f, "pos|" + Str(gMapX) + "|" + Str(gMapY) + "|" + Str(gx) + "|" + Str(gy))
  WriteStringN(f, "credits|" + Str(gCredits))
  WriteStringN(f, "stardate|" + StrF(gStardate) + "|" + Str(gGameDay))
  WriteStringN(f, "metals|" + Str(gIron) + "|" + Str(gAluminum) + "|" + Str(gCopper) + "|" + Str(gTin) + "|" + Str(gBronze))
  WriteStringN(f, "settings|" + Str(gAutosaveInterval) + "|" + Str(gAutoclearInterval))
  WriteStringN(f, "transporter|" + Str(gTransporterPower) + "|" + Str(gTransporterRange) + "|" + Str(gTransporterCrew))
  WriteStringN(f, "probesys|" + Str(gProbeRange) + "|" + Str(gProbeAccuracy))
  WriteStringN(f, "sound|" + Str(gSoundEnabled))
  WriteStringN(f, "shuttle|" + Str(gShuttleLaunched) + "|" + Str(gShuttleCrew) + "|" + Str(gShuttleCargoOre) + "|" + Str(gShuttleCargoDilithium) + "|" + Str(gShuttleMaxCargo) + "|" + Str(gShuttleMaxCrew) + "|" + Str(gShuttleAttackRange))
  WriteStringN(f, "upgrades|" + Str(gUpgradeHull) + "|" + Str(gUpgradeShields) + "|" + Str(gUpgradeWeapons) + "|" + Str(gUpgradePropulsion) + "|" + Str(gUpgradePowerCargo) + "|" + Str(gUpgradeProbes) + "|" + Str(gUpgradeShuttle))

  ; Save player fleet
  WriteStringN(f, "playerfleet|" + Str(gPlayerFleetCount))
  Protected pf.i
  For pf = 1 To gPlayerFleetCount
    WriteStringN(f, "pfleet|" + Str(pf) + "|" + SafeField(gPlayerFleet(pf)\name) + "|" + SafeField(gPlayerFleet(pf)\class) + "|" +
                    Str(gPlayerFleet(pf)\hullMax) + "|" + Str(gPlayerFleet(pf)\hull) + "|" +
                    Str(gPlayerFleet(pf)\shieldsMax) + "|" + Str(gPlayerFleet(pf)\shields))
  Next

  WriteStringN(f, "player|" + SafeField(*p\name) + "|" + SafeField(*p\class) + "|" +
                  Str(*p\hullMax) + "|" + Str(*p\hull) + "|" +
                  Str(*p\shieldsMax) + "|" + Str(*p\shields) + "|" +
                  Str(*p\reactorMax) + "|" + StrF(*p\warpMax) + "|" + StrF(*p\impulseMax) + "|" +
                  Str(*p\phaserBanks) + "|" + Str(*p\torpTubes) + "|" +
                  Str(*p\torpMax) + "|" + Str(*p\torp) + "|" +
                  Str(*p\sensorRange) + "|" +
                  Str(*p\weaponCapMax) + "|" + Str(*p\weaponCap) + "|" +
                  Str(*p\fuelMax) + "|" + Str(*p\fuel) + "|" +
                  Str(*p\oreMax) + "|" + Str(*p\ore) + "|" +
                  Str(*p\dilithiumMax) + "|" + Str(*p\dilithium) + "|" +
                  Str(*p\probesMax) + "|" + Str(*p\probes) + "|" +
                  Str(*p\allocShields) + "|" + Str(*p\allocWeapons) + "|" + Str(*p\allocEngines) + "|" +
                  Str(*p\sysEngines) + "|" + Str(*p\sysWeapons) + "|" + Str(*p\sysShields))
  
  WriteStringN(f, "crew|0|" + SafeField(*p\crew1\name) + "|" + Str(*p\crew1\role) + "|" + Str(*p\crew1\rank) + "|" + Str(*p\crew1\xp) + "|" + Str(*p\crew1\level))
  WriteStringN(f, "crew|1|" + SafeField(*p\crew2\name) + "|" + Str(*p\crew2\role) + "|" + Str(*p\crew2\rank) + "|" + Str(*p\crew2\xp) + "|" + Str(*p\crew2\level))
  WriteStringN(f, "crew|2|" + SafeField(*p\crew3\name) + "|" + Str(*p\crew3\role) + "|" + Str(*p\crew3\rank) + "|" + Str(*p\crew3\xp) + "|" + Str(*p\crew3\level))
  WriteStringN(f, "crew|3|" + SafeField(*p\crew4\name) + "|" + Str(*p\crew4\role) + "|" + Str(*p\crew4\rank) + "|" + Str(*p\crew4\xp) + "|" + Str(*p\crew4\level))

  ; Save recruits
  WriteStringN(f, "recruits|" + Str(gRecruitCount))
  Protected r.i
  For r = 0 To gRecruitCount - 1
    WriteStringN(f, "recruit|" + Str(r) + "|" + SafeField(gRecruitNames(r)) + "|" + SafeField(gRecruitRoles(r)))
  Next

  WriteStringN(f, "mission|" + Str(gMission\active) + "|" + Str(gMission\type) + "|" +
                  SafeField(gMission\title) + "|" + SafeField(gMission\desc) + "|" +
                  Str(gMission\oreRequired) + "|" +
                  Str(gMission\killsRequired) + "|" + Str(gMission\killsDone) + "|" +
                  Str(gMission\destMapX) + "|" + Str(gMission\destMapY) + "|" + Str(gMission\destX) + "|" + Str(gMission\destY) + "|" +
                  Str(gMission\destEntType) + "|" + SafeField(gMission\destName) + "|" +
                  Str(gMission\rewardCredits) + "|" +
                  Str(gMission\turnsLeft) + "|" + Str(gMission\yardHP) + "|" + Str(gMission\threatLevel))

  ; Save captain's log
  WriteStringN(f, "caplog|" + Str(gCaptainLogCount))
  Protected c.i
  For c = 0 To gCaptainLogCount - 1
    WriteStringN(f, "capentry|" + SafeField(gCaptainLog(c)))
  Next

  ; Galaxy cells: store all non-empty cells.
  Protected mx.i, my.i, x.i, y.i
  For my = 0 To #GALAXY_H - 1
    For mx = 0 To #GALAXY_W - 1
      For y = 0 To #MAP_H - 1
        For x = 0 To #MAP_W - 1
          If gGalaxy(mx, my, x, y)\entType <> #ENT_EMPTY
            WriteStringN(f, "cell|" + Str(mx) + "|" + Str(my) + "|" + Str(x) + "|" + Str(y) + "|" +
                            Str(gGalaxy(mx, my, x, y)\entType) + "|" +
                            Str(gGalaxy(mx, my, x, y)\richness) + "|" +
                            Str(gGalaxy(mx, my, x, y)\enemyLevel) + "|" +
                            SafeField(gGalaxy(mx, my, x, y)\name))
          EndIf
        Next
      Next
    Next
  Next

  CloseFile(f)
  LogLine("SAVE: wrote " + gSavePath)
  ProcedureReturn 1
EndProcedure

Procedure.i LoadGame(*p.Ship)
  Protected f.i = ReadFile(#PB_Any, gSavePath)
  If f = 0
    LogLine("LOAD: no save file")
    ProcedureReturn 0
  EndIf

  ; Clear galaxy before applying saved cells
  Protected mx.i, my.i
  For my = 0 To #GALAXY_H - 1
    For mx = 0 To #GALAXY_W - 1
      ClearSectorMap(mx, my)
    Next
  Next

  ClearStructure(@gMission, Mission)
  gMission\type = #MIS_NONE
  gCredits = 0

  Protected line.s, kind.s
  While Eof(f) = 0
    line = ReadString(f)
    line = Trim(line)
    If line = "" : Continue : EndIf
    kind = StringField(line, 1, "|")
    Select kind
      Case "version"
        ; reserved
      Case "mode"
        ; Always start in galaxy mode when loading - never load into combat
        gMode = #MODE_GALAXY
      Case "pos"
        gMapX = Val(StringField(line, 2, "|"))
        gMapY = Val(StringField(line, 3, "|"))
        gx    = Val(StringField(line, 4, "|"))
        gy    = Val(StringField(line, 5, "|"))
      Case "credits"
        gCredits = Val(StringField(line, 2, "|"))
      Case "stardate"
        gStardate = ValF(StringField(line, 2, "|"))
        gGameDay = Val(StringField(line, 3, "|"))
      Case "metals"
        gIron      = Val(StringField(line, 2, "|"))
        gAluminum  = Val(StringField(line, 3, "|"))
        gCopper    = Val(StringField(line, 4, "|"))
        gTin       = Val(StringField(line, 5, "|"))
        gBronze    = Val(StringField(line, 6, "|"))
      Case "settings"
        gAutosaveInterval  = Val(StringField(line, 2, "|"))
        gAutoclearInterval = Val(StringField(line, 3, "|"))
      Case "transporter"
        gTransporterPower = Val(StringField(line, 2, "|"))
        gTransporterRange = Val(StringField(line, 3, "|"))
        gTransporterCrew = Val(StringField(line, 4, "|"))
        If gTransporterPower <= 0 : gTransporterPower = 50 : EndIf
        If gTransporterRange <= 0 : gTransporterRange = 5 : EndIf
        If gTransporterCrew <= 0 : gTransporterCrew = 2 : EndIf
      Case "probesys"
        gProbeRange = Val(StringField(line, 2, "|"))
        gProbeAccuracy = Val(StringField(line, 3, "|"))
        If gProbeRange <= 0 : gProbeRange = 3 : EndIf
        If gProbeAccuracy <= 0 : gProbeAccuracy = 75 : EndIf
      Case "shuttle"
        gShuttleLaunched = Val(StringField(line, 2, "|"))
        gShuttleCrew = Val(StringField(line, 3, "|"))
        gShuttleCargoOre = Val(StringField(line, 4, "|"))
        gShuttleCargoDilithium = Val(StringField(line, 5, "|"))
        gShuttleMaxCargo = Val(StringField(line, 6, "|"))
        gShuttleMaxCrew = Val(StringField(line, 7, "|"))
        gShuttleAttackRange = Val(StringField(line, 8, "|"))
        If gShuttleMaxCargo <= 0 : gShuttleMaxCargo = 10 : EndIf
        If gShuttleMaxCrew <= 0 : gShuttleMaxCrew = 6 : EndIf
        If gShuttleAttackRange <= 0 : gShuttleAttackRange = 10 : EndIf
      Case "upgrades"
        gUpgradeHull = Val(StringField(line, 2, "|"))
        gUpgradeShields = Val(StringField(line, 3, "|"))
        gUpgradeWeapons = Val(StringField(line, 4, "|"))
        gUpgradePropulsion = Val(StringField(line, 5, "|"))
        gUpgradePowerCargo = Val(StringField(line, 6, "|"))
        gUpgradeProbes = Val(StringField(line, 7, "|"))
        gUpgradeShuttle = Val(StringField(line, 8, "|"))
        If gUpgradeHull < 0 : gUpgradeHull = 0 : EndIf
        If gUpgradeShields < 0 : gUpgradeShields = 0 : EndIf
        If gUpgradeWeapons < 0 : gUpgradeWeapons = 0 : EndIf
        If gUpgradePropulsion < 0 : gUpgradePropulsion = 0 : EndIf
        If gUpgradePowerCargo < 0 : gUpgradePowerCargo = 0 : EndIf
        If gUpgradeProbes < 0 : gUpgradeProbes = 0 : EndIf
        If gUpgradeShuttle < 0 : gUpgradeShuttle = 0 : EndIf
      Case "playerfleet"
        gPlayerFleetCount = Val(StringField(line, 2, "|"))
        If gPlayerFleetCount < 0 : gPlayerFleetCount = 0 : EndIf
        If gPlayerFleetCount > 5 : gPlayerFleetCount = 5 : EndIf
      Case "pfleet"
        Protected pfLoad.i = Val(StringField(line, 2, "|"))
        If pfLoad >= 1 And pfLoad <= 5
          gPlayerFleet(pfLoad)\name     = StringField(line, 3, "|")
          gPlayerFleet(pfLoad)\class    = StringField(line, 4, "|")
          gPlayerFleet(pfLoad)\hullMax   = Val(StringField(line, 5, "|"))
          gPlayerFleet(pfLoad)\hull      = Val(StringField(line, 6, "|"))
          gPlayerFleet(pfLoad)\shieldsMax = Val(StringField(line, 7, "|"))
          gPlayerFleet(pfLoad)\shields   = Val(StringField(line, 8, "|"))
        EndIf
      Case "player"
        *p\name        = StringField(line, 2, "|")
        *p\class       = StringField(line, 3, "|")
        *p\hullMax     = Val(StringField(line, 4, "|"))
        *p\hull        = Val(StringField(line, 5, "|"))
        *p\shieldsMax  = Val(StringField(line, 6, "|"))
        *p\shields     = Val(StringField(line, 7, "|"))
        *p\reactorMax  = Val(StringField(line, 8, "|"))
        *p\warpMax     = ValF(StringField(line, 9, "|"))
        *p\impulseMax  = ValF(StringField(line, 10, "|"))
        *p\phaserBanks = Val(StringField(line, 11, "|"))
        *p\torpTubes   = Val(StringField(line, 12, "|"))
        *p\torpMax     = Val(StringField(line, 13, "|"))
        *p\torp        = Val(StringField(line, 14, "|"))
        *p\sensorRange = Val(StringField(line, 15, "|"))
        *p\weaponCapMax= Val(StringField(line, 16, "|"))
        *p\weaponCap   = Val(StringField(line, 17, "|"))
        *p\fuelMax     = Val(StringField(line, 18, "|"))
        *p\fuel        = Val(StringField(line, 19, "|"))
        *p\oreMax      = Val(StringField(line, 20, "|"))
        *p\ore         = Val(StringField(line, 21, "|"))
        *p\dilithiumMax = Val(StringField(line, 22, "|"))
        *p\dilithium   = Val(StringField(line, 23, "|"))
        *p\probesMax   = Val(StringField(line, 24, "|"))
        *p\probes      = Val(StringField(line, 25, "|"))
        *p\allocShields= Val(StringField(line, 26, "|"))
        *p\allocWeapons= Val(StringField(line, 27, "|"))
        *p\allocEngines= Val(StringField(line, 28, "|"))
        *p\sysEngines  = Val(StringField(line, 29, "|"))
        *p\sysWeapons  = Val(StringField(line, 30, "|"))
        *p\sysShields  = Val(StringField(line, 31, "|"))
        ; Backward compatibility: ensure dilithium fields exist
        If *p\dilithiumMax <= 0 : *p\dilithiumMax = 20 : EndIf
        If *p\dilithium > *p\dilithiumMax : *p\dilithium = *p\dilithiumMax : EndIf
        ; Backward compatibility: ensure probes exist
        If *p\probesMax <= 0 : *p\probesMax = 5 : EndIf
        If *p\probes > *p\probesMax : *p\probes = *p\probesMax : EndIf
      Case "crew"
        Protected crewIdx.i = Val(StringField(line, 2, "|"))
        Select crewIdx
          Case 0
            *p\crew1\name   = StringField(line, 3, "|")
            *p\crew1\role   = Val(StringField(line, 4, "|"))
            *p\crew1\rank   = Val(StringField(line, 5, "|"))
            *p\crew1\xp     = Val(StringField(line, 6, "|"))
            *p\crew1\level  = Val(StringField(line, 7, "|"))
          Case 1
            *p\crew2\name   = StringField(line, 3, "|")
            *p\crew2\role   = Val(StringField(line, 4, "|"))
            *p\crew2\rank   = Val(StringField(line, 5, "|"))
            *p\crew2\xp     = Val(StringField(line, 6, "|"))
            *p\crew2\level  = Val(StringField(line, 7, "|"))
          Case 2
            *p\crew3\name   = StringField(line, 3, "|")
            *p\crew3\role   = Val(StringField(line, 4, "|"))
            *p\crew3\rank   = Val(StringField(line, 5, "|"))
            *p\crew3\xp     = Val(StringField(line, 6, "|"))
            *p\crew3\level  = Val(StringField(line, 7, "|"))
          Case 3
            *p\crew4\name   = StringField(line, 3, "|")
            *p\crew4\role   = Val(StringField(line, 4, "|"))
            *p\crew4\rank   = Val(StringField(line, 5, "|"))
            *p\crew4\xp     = Val(StringField(line, 6, "|"))
            *p\crew4\level  = Val(StringField(line, 7, "|"))
        EndSelect
      Case "recruits"
        gRecruitCount = Val(StringField(line, 2, "|"))
        If gRecruitCount < 0 Or gRecruitCount > 3
          gRecruitCount = 0
        EndIf
      Case "recruit"
        Protected recIdx.i = Val(StringField(line, 2, "|"))
        If recIdx >= 0 And recIdx < 3
          gRecruitNames(recIdx) = StringField(line, 3, "|")
          gRecruitRoles(recIdx) = StringField(line, 4, "|")
        EndIf
      Case "mission"
        gMission\active        = Val(StringField(line, 2, "|"))
        gMission\type          = Val(StringField(line, 3, "|"))
        gMission\title         = StringField(line, 4, "|")
        gMission\desc          = StringField(line, 5, "|")
        gMission\oreRequired   = Val(StringField(line, 6, "|"))
        gMission\killsRequired = Val(StringField(line, 7, "|"))
        gMission\killsDone     = Val(StringField(line, 8, "|"))
        gMission\destMapX      = Val(StringField(line, 9, "|"))
        gMission\destMapY      = Val(StringField(line, 10, "|"))
        gMission\destX         = Val(StringField(line, 11, "|"))
        gMission\destY         = Val(StringField(line, 12, "|"))
        gMission\destEntType   = Val(StringField(line, 13, "|"))
        gMission\destName      = StringField(line, 14, "|")
        gMission\rewardCredits = Val(StringField(line, 15, "|"))
        gMission\turnsLeft     = Val(StringField(line, 16, "|"))
        gMission\yardHP        = Val(StringField(line, 17, "|"))
        gMission\threatLevel   = Val(StringField(line, 18, "|"))
      Case "caplog"
        gCaptainLogCount = 0
      Case "capentry"
        If gCaptainLogCount >= 0 And gCaptainLogCount < ArraySize(gCaptainLog())
          gCaptainLog(gCaptainLogCount) = StringField(line, 2, "|")
          gCaptainLogCount + 1
        EndIf
      Case "cell"
        Protected cx.i = Val(StringField(line, 2, "|"))
        Protected cy.i = Val(StringField(line, 3, "|"))
        Protected sx.i = Val(StringField(line, 4, "|"))
        Protected sy.i = Val(StringField(line, 5, "|"))
        If cx >= 0 And cx < #GALAXY_W And cy >= 0 And cy < #GALAXY_H And sx >= 0 And sx < #MAP_W And sy >= 0 And sy < #MAP_H
          gGalaxy(cx, cy, sx, sy)\entType    = Val(StringField(line, 6, "|"))
          gGalaxy(cx, cy, sx, sy)\richness   = Val(StringField(line, 7, "|"))
          gGalaxy(cx, cy, sx, sy)\enemyLevel = Val(StringField(line, 8, "|"))
          gGalaxy(cx, cy, sx, sy)\name       = StringField(line, 9, "|")
        EndIf
    EndSelect
  Wend

  CloseFile(f)

  ; Safety: clamp and reset transient enemy pointers
  gMapX = ClampInt(gMapX, 0, #GALAXY_W - 1)
  gMapY = ClampInt(gMapY, 0, #GALAXY_H - 1)
  gx    = ClampInt(gx, 0, #MAP_W - 1)
  gy    = ClampInt(gy, 0, #MAP_H - 1)
  gEnemyMapX = -1 : gEnemyMapY = -1 : gEnemyX = -1 : gEnemyY = -1

  ; If loaded into tactical mode, fall back to galaxy (no tactical persistence yet)
  If gMode <> #MODE_GALAXY
    gMode = #MODE_GALAXY
  EndIf
  
  ; Start engine loop if undocked
  If gDocked = 0
    StartEngineLoop()
  EndIf
  
  LogLine("LOAD: loaded " + gSavePath)
  ProcedureReturn 1
EndProcedure

Procedure PrintHelpTactical()
  PrintDivider()
  PrintN("Tactical Commands:")
  PrintCmd("HELP")
  PrintN("    Show this help")
  PrintN("")
  PrintCmd("ABOUT")
  PrintN("    Show app info (name, version, creator, email, website)")
  PrintN("")
  PrintCmd("STATUS")
  PrintN("    Show tactical status (range, hull, shields, capacitor, torps)")
  PrintN("")
  PrintCmd("SCAN")
  PrintN("    Show detailed sensor report if within SensorRange")
  PrintN("")
  PrintCmd("ALLOC <engines> <weapons> <shields>")
  PrintN("    Set reactor power distribution (sum must be <= 100)")
  PrintN("    Default: 33 34 33")
  PrintN("    Examples: ALLOC 40 40 20 | ALLOC 33 34 33")
  PrintN("")
  PrintCmd("MOVE <APPROACH|RETREAT|HOLD> <amount>")
  PrintN("    Change range; amount is limited by Engines allocation")
  PrintN("    Costs 1 fuel per MOVE")
  PrintN("    Examples: MOVE APPROACH 2 | MOVE RETREAT 1 | MOVE HOLD")
  PrintN("")
  PrintCmd("PHASER <power>")
  PrintN("    Fire phasers using WeaponCap; power is capped per turn by PhaserBanks")
  PrintN("    Tip: if WeaponCap is 0, use END to recharge or ALLOC more to weapons")
  PrintN("    Example: PHASER 40")
  PrintN("")
  PrintCmd("TORPEDO <count>")
  PrintN("    Fire 1+ torpedoes; count capped by TorpedoTubes and remaining torps")
  PrintN("    Effective range: <= 24")
  PrintN("    Example: TORPEDO 1 | TORPEDO 2")
  PrintN("")
  PrintCmd("TRACTOR <HOLD|PULL|PUSH>")
  PrintN("    Tractor beam (green) - costs 1 fuel/dilithium per use")
  PrintN("    HOLD - lock enemy in place, prevents movement this turn")
  PrintN("    PULL - pull enemy 2 sectors closer (1 dilithium or fuel)")
  PrintN("    PUSH - push enemy into adjacent hazard (sun/blackhole/wormhole)")
    PrintN("  Example: TRACTOR HOLD | TRACTOR PULL | TRACTOR PUSH")
  PrintN("")
  PrintCmd("TRANSPORTER <ATTACK>")
  PrintN("    Beam away team to enemy ship for boarding action")
  PrintN("    ATTACK - send away team to attack and capture enemy")
  PrintN("    Success depends on power, crew size, and enemy range")
  PrintN("    Example: TRANSPORTER ATTACK")
  PrintN("")
  PrintCmd("SHUTTLE <ATTACK|INFO>")
  PrintN("    Launch shuttle for combat operations (must be launched in galaxy mode)")
  PrintN("    ATTACK - shuttle attacks enemy ship (range <= " + Str(gShuttleAttackRange) + ")")
  PrintN("    INFO   - show shuttle status")
  PrintN("    Shuttle has its own crew, can damage enemy systems")
  PrintN("    Example: SHUTTLE ATTACK")
  PrintN("")
  PrintCmd("FLEE")
  PrintN("    Attempt to disengage; success improves at longer range")
  PrintN("    Example: FLEE")
  PrintN("")
  PrintCmd("END")
  PrintN("    End your turn (regen/repair happens, then enemy acts)")
  PrintN("")
  PrintCmd("QUIT")
  PrintCmd("EXIT")
  PrintN("    Exit the game")
  PrintDivider()
EndProcedure

;==============================================================================
; InitCrew(*s.Ship)
; Initializes a ship's crew with starting members.
; 
; Crew roles (4 total):
;   - Commander: Ship command, affects all systems
;   - Engineer: Repairs, affects engine efficiency
;   - Gunner: Weapons accuracy and damage
;   - Pilot: Movement range, evasion
;
; Each crew member has:
;   - Name (randomly generated)
;   - Role/position
;   - Experience points (XP)
;   - Skill level (based on XP)
;
; Crew gain XP through actions:
;   - Fighting: Gunner gains weapons XP
;   - Traveling: Pilot gains navigation XP
;   - Repairs: Engineer gains repair XP
;==============================================================================
Procedure InitCrew(*s.Ship)
  *s\crew1\name = "Cmdr. Johnson"
  *s\crew1\role = #CREW_HELM
  *s\crew1\rank = #RANK_LIEUTENANT
  *s\crew1\xp = 50
  *s\crew1\level = 1
  
  *s\crew2\name = "Lt. Torres"
  *s\crew2\role = #CREW_WEAPONS
  *s\crew2\rank = #RANK_LIEUTENANT
  *s\crew2\xp = 50
  *s\crew2\level = 1
  
  *s\crew3\name = "Ens. Crusher"
  *s\crew3\role = #CREW_SHIELDS
  *s\crew3\rank = #RANK_ENSIGN
  *s\crew3\xp = 20
  *s\crew3\level = 1
  
  *s\crew4\name = "Chief Scott"
  *s\crew4\role = #CREW_ENGINEERING
  *s\crew4\rank = #RANK_LIEUTENANT
  *s\crew4\xp = 60
  *s\crew4\level = 2
EndProcedure

Procedure.s RankName(rank.i)
  Select rank
    Case #RANK_ENSIGN : ProcedureReturn "Ensign"
    Case #RANK_LIEUTENANT : ProcedureReturn "Lieutenant"
    Case #RANK_LT_COMMANDER : ProcedureReturn "Lt. Commander"
    Case #RANK_COMMANDER : ProcedureReturn "Commander"
    Case #RANK_CAPTAIN : ProcedureReturn "Captain"
    Case #RANK_ADMIRAL : ProcedureReturn "Admiral"
    Default : ProcedureReturn "Unknown"
  EndSelect
EndProcedure

Procedure.s CrewRoleName(role.i)
  Select role
    Case #CREW_HELM : ProcedureReturn "Helm"
    Case #CREW_WEAPONS : ProcedureReturn "Weapons"
    Case #CREW_SHIELDS : ProcedureReturn "Shields"
    Case #CREW_ENGINEERING : ProcedureReturn "Engineering"
    Default : ProcedureReturn "Unknown"
  EndSelect
EndProcedure

Procedure GainCrewXP(*s.Ship, role.i, xpGain.i)
  Select role
    Case #CREW_HELM
      *s\crew1\xp + xpGain
      Protected xpNeeded1.i = *s\crew1\level * 100
      If *s\crew1\xp >= xpNeeded1
        *s\crew1\xp - xpNeeded1
        *s\crew1\level + 1
        If *s\crew1\rank < #RANK_ADMIRAL
          *s\crew1\rank + 1
        EndIf
        LogLine("CREW LEVEL UP: " + *s\crew1\name + " promoted to " + RankName(*s\crew1\rank))
        PrintN("")
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("*** " + *s\crew1\name + " promoted to " + RankName(*s\crew1\rank) + " (Helm)! ***")
        ResetColor()
      EndIf
    Case #CREW_WEAPONS
      *s\crew2\xp + xpGain
      Protected xpNeeded2.i = *s\crew2\level * 100
      If *s\crew2\xp >= xpNeeded2
        *s\crew2\xp - xpNeeded2
        *s\crew2\level + 1
        If *s\crew2\rank < #RANK_ADMIRAL
          *s\crew2\rank + 1
        EndIf
        LogLine("CREW LEVEL UP: " + *s\crew2\name + " promoted to " + RankName(*s\crew2\rank))
        PrintN("")
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("*** " + *s\crew2\name + " promoted to " + RankName(*s\crew2\rank) + " (Weapons)! ***")
        ResetColor()
      EndIf
    Case #CREW_SHIELDS
      *s\crew3\xp + xpGain
      Protected xpNeeded3.i = *s\crew3\level * 100
      If *s\crew3\xp >= xpNeeded3
        *s\crew3\xp - xpNeeded3
        *s\crew3\level + 1
        If *s\crew3\rank < #RANK_ADMIRAL
          *s\crew3\rank + 1
        EndIf
        LogLine("CREW LEVEL UP: " + *s\crew3\name + " promoted to " + RankName(*s\crew3\rank))
        PrintN("")
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("*** " + *s\crew3\name + " promoted to " + RankName(*s\crew3\rank) + " (Shields)! ***")
        ResetColor()
      EndIf
    Case #CREW_ENGINEERING
      *s\crew4\xp + xpGain
      Protected xpNeeded4.i = *s\crew4\level * 100
      If *s\crew4\xp >= xpNeeded4
        *s\crew4\xp - xpNeeded4
        *s\crew4\level + 1
        If *s\crew4\rank < #RANK_ADMIRAL
          *s\crew4\rank + 1
        EndIf
        LogLine("CREW LEVEL UP: " + *s\crew4\name + " promoted to " + RankName(*s\crew4\rank))
        PrintN("")
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("*** " + *s\crew4\name + " promoted to " + RankName(*s\crew4\rank) + " (Engineering)! ***")
        ResetColor()
      EndIf
  EndSelect
EndProcedure

Procedure.i CrewBonus(*s.Ship, role.i)
  Select role
    Case #CREW_HELM
      ProcedureReturn *s\crew1\level * 3 + (*s\crew1\rank * 2)
    Case #CREW_WEAPONS
      ProcedureReturn *s\crew2\level * 3 + (*s\crew2\rank * 2)
    Case #CREW_SHIELDS
      ProcedureReturn *s\crew3\level * 3 + (*s\crew3\rank * 2)
    Case #CREW_ENGINEERING
      ProcedureReturn *s\crew4\level * 3 + (*s\crew4\rank * 2)
  EndSelect
  ProcedureReturn 0
EndProcedure

Procedure PrintCrew(*s.Ship)
  PrintN("Crew:")
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  Print("  " + *s\crew1\name + " [" + RankName(*s\crew1\rank) + "] ")
  ResetColor()
  Print("Helm Lvl" + Str(*s\crew1\level))
  Protected xpNeed1.i = *s\crew1\level * 100
  Print(" XP: " + Str(*s\crew1\xp) + "/" + Str(xpNeed1))
  PrintN("")
  
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  Print("  " + *s\crew2\name + " [" + RankName(*s\crew2\rank) + "] ")
  ResetColor()
  Print("Weapons Lvl" + Str(*s\crew2\level))
  Protected xpNeed2.i = *s\crew2\level * 100
  Print(" XP: " + Str(*s\crew2\xp) + "/" + Str(xpNeed2))
  PrintN("")
  
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  Print("  " + *s\crew3\name + " [" + RankName(*s\crew3\rank) + "] ")
  ResetColor()
  Print("Shields Lvl" + Str(*s\crew3\level))
  Protected xpNeed3.i = *s\crew3\level * 100
  Print(" XP: " + Str(*s\crew3\xp) + "/" + Str(xpNeed3))
  PrintN("")
  
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  Print("  " + *s\crew4\name + " [" + RankName(*s\crew4\rank) + "] ")
  ResetColor()
  Print("Engineering Lvl" + Str(*s\crew4\level))
  Protected xpNeed4.i = *s\crew4\level * 100
  Print(" XP: " + Str(*s\crew4\xp) + "/" + Str(xpNeed4))
  PrintN("")
EndProcedure

Procedure InitRecruitNames()
  gFirstNames(0) = "James"
  gFirstNames(1) = "John"
  gFirstNames(2) = "Robert"
  gFirstNames(3) = "Michael"
  gFirstNames(4) = "William"
  gFirstNames(5) = "David"
  gFirstNames(6) = "Richard"
  gFirstNames(7) = "Joseph"
  gFirstNames(8) = "Thomas"
  gFirstNames(9) = "Charles"
  gFirstNames(10) = "Mary"
  gFirstNames(11) = "Patricia"
  gFirstNames(12) = "Jennifer"
  gFirstNames(13) = "Linda"
  gFirstNames(14) = "Elizabeth"
  gFirstNames(15) = "Barbara"
  gFirstNames(16) = "Susan"
  gFirstNames(17) = "Jessica"
  gFirstNames(18) = "Sarah"
  gFirstNames(19) = "Karen"
  gFirstNames(20) = "Nancy"
  gFirstNames(21) = "Lisa"
  gFirstNames(22) = "Betty"
  gFirstNames(23) = "Margaret"
  gFirstNames(24) = "Sandra"
  gFirstNames(25) = "Ashley"
  gFirstNames(26) = "Kimberly"
  gFirstNames(27) = "Emily"
  gFirstNames(28) = "Donna"
  gFirstNames(29) = "Michelle"

  gLastNames(0) = "Smith"
  gLastNames(1) = "Johnson"
  gLastNames(2) = "Williams"
  gLastNames(3) = "Brown"
  gLastNames(4) = "Jones"
  gLastNames(5) = "Garcia"
  gLastNames(6) = "Miller"
  gLastNames(7) = "Davis"
  gLastNames(8) = "Rodriguez"
  gLastNames(9) = "Martinez"
  gLastNames(10) = "Hernandez"
  gLastNames(11) = "Lopez"
  gLastNames(12) = "Gonzalez"
  gLastNames(13) = "Wilson"
  gLastNames(14) = "Anderson"
  gLastNames(15) = "Thomas"
  gLastNames(16) = "Taylor"
  gLastNames(17) = "Moore"
  gLastNames(18) = "Jackson"
  gLastNames(19) = "Martin"
  gLastNames(20) = "Lee"
  gLastNames(21) = "Perez"
  gLastNames(22) = "Thompson"
  gLastNames(23) = "White"
  gLastNames(24) = "Harris"
  gLastNames(25) = "Sanchez"
  gLastNames(26) = "Clark"
  gLastNames(27) = "Ramirez"
  gLastNames(28) = "Lewis"
  gLastNames(29) = "Robinson"
EndProcedure

Procedure GenerateRecruits()
  gRecruitCount = 3
  Protected i.i
  For i = 0 To 2
    Protected firstIdx.i = Random(29)
    Protected lastIdx.i = Random(29)
    Protected roleRoll.i = Random(3)
    Protected roleName.s
    Select roleRoll
      Case 0 : roleName = "Helm"
      Case 1 : roleName = "Weapons"
      Case 2 : roleName = "Shields"
      Case 3 : roleName = "Engineering"
    EndSelect
    gRecruitNames(i) = gFirstNames(firstIdx) + " " + gLastNames(lastIdx)
    gRecruitRoles(i) = roleName
  Next
EndProcedure

Procedure DismissCrew(*p.Ship, role.i)
  Select role
    Case #CREW_HELM
      *p\crew1\name = ""
      *p\crew1\rank = #RANK_ENSIGN
      *p\crew1\xp = 0
      *p\crew1\level = 1
      PrintN("Helm officer dismissed.")
    Case #CREW_WEAPONS
      *p\crew2\name = ""
      *p\crew2\rank = #RANK_ENSIGN
      *p\crew2\xp = 0
      *p\crew2\level = 1
      PrintN("Weapons officer dismissed.")
    Case #CREW_SHIELDS
      *p\crew3\name = ""
      *p\crew3\rank = #RANK_ENSIGN
      *p\crew3\xp = 0
      *p\crew3\level = 1
      PrintN("Shields officer dismissed.")
    Case #CREW_ENGINEERING
      *p\crew4\name = ""
      *p\crew4\rank = #RANK_ENSIGN
      *p\crew4\xp = 0
      *p\crew4\level = 1
      PrintN("Engineering officer dismissed.")
  EndSelect
  LogLine("CREW: dismissed " + Str(role))
EndProcedure

Procedure RecruitCrew(*p.Ship, index.i)
  If index < 0 Or index >= gRecruitCount
    PrintN("Invalid recruit number.")
    ProcedureReturn
  EndIf
  
  Protected roleName.s = gRecruitRoles(index)
  Protected newName.s = gRecruitNames(index)
  
  Select roleName
    Case "Helm"
      *p\crew1\name = newName
      *p\crew1\rank = #RANK_ENSIGN
      *p\crew1\xp = 0
      *p\crew1\level = 1
      PrintN(newName + " recruited as Helm officer (Lv1).")
    Case "Weapons"
      *p\crew2\name = newName
      *p\crew2\rank = #RANK_ENSIGN
      *p\crew2\xp = 0
      *p\crew2\level = 1
      PrintN(newName + " recruited as Weapons officer (Lv1).")
    Case "Shields"
      *p\crew3\name = newName
      *p\crew3\rank = #RANK_ENSIGN
      *p\crew3\xp = 0
      *p\crew3\level = 1
      PrintN(newName + " recruited as Shields officer (Lv1).")
    Case "Engineering"
      *p\crew4\name = newName
      *p\crew4\rank = #RANK_ENSIGN
      *p\crew4\xp = 0
      *p\crew4\level = 1
      PrintN(newName + " recruited as Engineering officer (Lv1).")
  EndSelect
  
  LogLine("CREW: recruited " + newName + " as " + roleName)
  
  ; Generate new recruits
  GenerateRecruits()
EndProcedure

Procedure.i CrewPositionFilled(*p.Ship, role.i)
  Select role
    Case #CREW_HELM
      If *p\crew1\name <> "" : ProcedureReturn 1 : Else : ProcedureReturn 0 : EndIf
    Case #CREW_WEAPONS
      If *p\crew2\name <> "" : ProcedureReturn 1 : Else : ProcedureReturn 0 : EndIf
    Case #CREW_SHIELDS
      If *p\crew3\name <> "" : ProcedureReturn 1 : Else : ProcedureReturn 0 : EndIf
    Case #CREW_ENGINEERING
      If *p\crew4\name <> "" : ProcedureReturn 1 : Else : ProcedureReturn 0 : EndIf
  EndSelect
  ProcedureReturn 0
EndProcedure

Procedure.i AllCrewPositionsFilled(*p.Ship)
  If *p\crew1\name = "" : ProcedureReturn 0 : EndIf
  If *p\crew2\name = "" : ProcedureReturn 0 : EndIf
  If *p\crew3\name = "" : ProcedureReturn 0 : EndIf
  If *p\crew4\name = "" : ProcedureReturn 0 : EndIf
  ProcedureReturn 1
EndProcedure

Procedure.i LoadShip(section.s, *s.Ship)
  ; Load from ships.dat/ships.ini text; clamp to sane ranges.
  Protected reactorDefault.i = 200
  Protected hullDefault.i = 100
  Protected shieldsDefault.i = 100

  *s\name        = IniGet(section, "Name", section)
  *s\class       = IniGet(section, "Class", "")
  *s\hullMax     = IniGetLong(section, "HullMax", hullDefault)
  *s\shieldsMax  = IniGetLong(section, "ShieldsMax", shieldsDefault)
  *s\reactorMax  = IniGetLong(section, "ReactorMax", reactorDefault)
  *s\warpMax     = IniGetFloat(section, "WarpMax", 9.0)
  *s\impulseMax  = IniGetFloat(section, "ImpulseMax", 1.0)
  *s\phaserBanks = IniGetLong(section, "PhaserBanks", 4)
  *s\torpTubes   = IniGetLong(section, "TorpedoTubes", 2)
  *s\torpMax     = IniGetLong(section, "TorpedoesMax", 10)
  *s\sensorRange = IniGetLong(section, "SensorRange", 20)
  *s\weaponCapMax= IniGetLong(section, "WeaponCapMax", *s\reactorMax)
  *s\fuelMax     = IniGetLong(section, "FuelMax", 100)
  *s\oreMax      = IniGetLong(section, "OreMax", 50)
  *s\dilithiumMax = IniGetLong(section, "DilithiumMax", 20)
  *s\probesMax    = IniGetLong(section, "ProbesMax", 5)
  *s\probes       = *s\probesMax
  *s\allocShields = IniGetLong(section, "AllocShields", 33)
  *s\allocWeapons = IniGetLong(section, "AllocWeapons", 34)
  *s\allocEngines = IniGetLong(section, "AllocEngines", 33)
  LoadAllocOverrides(section, *s)

  ; Sane clamps
  *s\hullMax     = ClampInt(*s\hullMax, 10, 600)
  *s\shieldsMax  = ClampInt(*s\shieldsMax, 0, 600)
  *s\reactorMax  = ClampInt(*s\reactorMax, 50, 600)
  *s\warpMax     = ClampF(*s\warpMax, 0.0, 12.0)
  *s\impulseMax  = ClampF(*s\impulseMax, 0.0, 2.5)
  *s\phaserBanks = ClampInt(*s\phaserBanks, 0, 20)
  *s\torpMax     = ClampInt(*s\torpMax, 0, 50)
  *s\torpTubes   = ClampInt(*s\torpTubes, 1, 6)
  If *s\torpMax > 0 And *s\torpTubes > *s\torpMax : *s\torpTubes = *s\torpMax : EndIf
  *s\sensorRange = ClampInt(*s\sensorRange, 1, 60)
  *s\weaponCapMax= ClampInt(*s\weaponCapMax, 10, 1200)
  *s\fuelMax     = ClampInt(*s\fuelMax, 10, 600)
  *s\oreMax      = ClampInt(*s\oreMax, 0, 250)
  *s\dilithiumMax = ClampInt(*s\dilithiumMax, 0, 50)
  *s\probesMax    = ClampInt(*s\probesMax, 0, 20)
  If *s\probes > *s\probesMax : *s\probes = *s\probesMax : EndIf
  *s\allocShields = ClampInt(*s\allocShields, 0, 100)
  *s\allocWeapons = ClampInt(*s\allocWeapons, 0, 100)
  *s\allocEngines = ClampInt(*s\allocEngines, 0, 100)
  If *s\allocShields + *s\allocWeapons + *s\allocEngines > 100
    *s\allocShields = 33
    *s\allocWeapons = 34
    *s\allocEngines = 33
  EndIf

  *s\hull      = *s\hullMax
  *s\shields   = *s\shieldsMax
  *s\torp      = *s\torpMax
  *s\weaponCap = *s\weaponCapMax / 2
  *s\fuel      = *s\fuelMax
  *s\ore       = 0
  *s\dilithium = 0

  *s\sysEngines = #SYS_OK
  *s\sysWeapons = #SYS_OK
  *s\sysShields = #SYS_OK
  *s\sysTractor = #SYS_OK

  ProcedureReturn 1
EndProcedure

Procedure.s LoadGameSettingString(key.s, defaultValue.s)
  ProcedureReturn IniGet("Game", key, defaultValue)
EndProcedure

Procedure SaveAlloc(section.s, *s.Ship)
  ; Store user overrides separately so ships data stays immutable.
  If OpenPreferences(gUserIniPath) = 0
    ProcedureReturn
  EndIf
  PreferenceGroup(section)
  WritePreferenceLong("AllocShields", *s\allocShields)
  WritePreferenceLong("AllocWeapons", *s\allocWeapons)
  WritePreferenceLong("AllocEngines", *s\allocEngines)
  ClosePreferences()
EndProcedure

Procedure.i IsAlive(*s.Ship)
  ProcedureReturn Bool(*s\hull > 0)
EndProcedure

;==============================================================================
; PrintStatusGalaxy(*p.Ship)
; Displays the galaxy mode status HUD showing:
;   - Ship name and class
;   - Hull and shields (with percentages)
;   - Fuel, Ore, Dilithium cargo
;   - Credits
;   - Current location (galaxy X,Y and sector X,Y)
;   - Current stardate
;   - Active mission info (if any)
;   - System status (OK/DAMAGED/DISABLED)
;==============================================================================
Procedure PrintStatusGalaxy(*p.Ship)
  PrintDivider()
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  PrintN(FormatStardate())
  ResetColor()
  PrintN("Galaxy: (" + Str(gMapX) + "," + Str(gMapY) + ")  Sector: (" + Str(gx) + "," + Str(gy) + ")")
  PrintN("Credits: " + Str(gCredits))
  If gMission\active
    PrintN("Mission: " + gMission\title)
    If gMission\type = #MIS_BOUNTY
      PrintN("  Progress: " + Str(gMission\killsDone) + "/" + Str(gMission\killsRequired))
    ElseIf gMission\type = #MIS_DELIVER_ORE
      PrintN("  Deliver: " + Str(gMission\oreRequired) + " ore to " + gMission\destName)
    ElseIf gMission\type = #MIS_SURVEY
      PrintN("  Survey: " + gMission\destName)
    ElseIf gMission\type = #MIS_PLANETKILLER
      ConsoleColor(#C_CYAN, #C_BLACK)
      PrintN("  DESTROY: " + gMission\destName)
      ResetColor()
    EndIf
  ElseIf gMission\type <> #MIS_NONE
    PrintN("Mission offer: " + gMission\title + " (type MISSIONS)")
  EndIf
  If gDocked
    ConsoleColor(#C_GREEN, #C_BLACK)
    PrintN("*** DOCKED - type UNDOCK to leave ***")
    ResetColor()
  EndIf
  Print("Fuel: ")
  SetColorForPercent(Int(100.0 * *p\fuel / ClampInt(*p\fuelMax, 1, 999999)))
  Print(Str(*p\fuel) + "/" + Str(*p\fuelMax))
  ResetColor()
  Print("  Ore: ")
  ConsoleColor(#C_BROWN, #C_BLACK)
  Print(Str(*p\ore) + "/" + Str(*p\oreMax))
  ResetColor()
  Print("  Dilithium: ")
  ConsoleColor(#C_MAGENTA, #C_BLACK)
  PrintN(Str(*p\dilithium) + "/" + Str(*p\dilithiumMax))
  ResetColor()
  Print("  Iron: " + Str(gIron))
  Print("  Aluminum: " + Str(gAluminum))
  Print("  Copper: " + Str(gCopper))
  Print("  Tin: " + Str(gTin))
  PrintN("  Bronze: " + Str(gBronze))
  PrintN("Ship: " + *p\name + " [" + *p\class + "]")
  If gPowerBuff = 1
    ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK)
    PrintN("  ** POWER OVERWHELMING BUFF: " + Str(gPowerBuffTurns) + " turns **")
    ResetColor()
  EndIf
  If gWarpCooldown > 0
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("  Warp ready in " + Str(gWarpCooldown) + " turn(s)")
    ResetColor()
  EndIf
  If gIonStormTurns > 0
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("  !! ION STORM: shields reduced for " + Str(gIonStormTurns) + " turn(s) !!")
    ResetColor()
  EndIf
  If gRadiationTurns > 0
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("  !! RADIATION: crew effectiveness reduced for " + Str(gRadiationTurns) + " turn(s) !!")
    ResetColor()
  EndIf
  Print("  Hull: ")
  SetColorForPercent(Int(100.0 * *p\hull / ClampInt(*p\hullMax, 1, 999999)))
  Print(Str(*p\hull) + "/" + Str(*p\hullMax))
  ResetColor()
  Print("  Shields: ")
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN(Str(*p\shields) + "/" + Str(*p\shieldsMax))
  ResetColor()

  Print("  WeaponCap: ")
  ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK)
  Print(Str(*p\weaponCap) + "/" + Str(*p\weaponCapMax))
  ResetColor()
  Print("  Torps: ")
  ConsoleColor(#C_YELLOW, #C_BLACK)
  Print(Str(*p\torp))
  ResetColor()
  Print("  Probes: ")
  ConsoleColor(#C_CYAN, #C_BLACK)
  PrintN(Str(*p\probes) + "/" + Str(*p\probesMax))
  ResetColor()
  PrintN("  Alloc: " + Str(*p\allocEngines) + " | " + Str(*p\allocWeapons) + " | " + Str(*p\allocShields))
  PrintN("  Systems: Engines " + SysText(*p\sysEngines) + ", Weapons " + SysText(*p\sysWeapons) + ", Shields " + SysText(*p\sysShields))
  PrintCrew(*p)
  PrintDivider()
EndProcedure

;==============================================================================
; PrintStatusTactical(*p.Ship, *e.Ship, *cs.CombatState)
; Displays the tactical combat HUD showing:
; - Player ship name, class, hull, shields, weapon power, torpedoes
; - Enemy ship name, class, hull, shields
; - Turn number and combat range
; - Fleet status (player and enemy fleet ships with their hull status)
; - Visual arena showing positions of ships and fleet
;==============================================================================
Procedure PrintStatusTactical(*p.Ship, *e.Ship, *cs.CombatState)
  ; Ensure enemy has valid stats (defensive)
  If *e\name = "" Or *e\hullMax <= 0
    *e\name = "Raider"
    *e\class = "Raider"
    *e\hullMax = 100
    *e\hull = 100
    *e\shieldsMax = 90
    *e\shields = 90
    *e\weaponCapMax = 210
    *e\weaponCap = 105
    *e\phaserBanks = 6
    *e\torpTubes = 2
    *e\torpMax = 8
    *e\torp = 8
  EndIf
  
  PrintDivider()
  PrintN("Tactical Turn: " + Str(*cs\turn) + "  Range: " + Str(*cs\range))
  If gPlayerFleetCount > 0
    PrintN("Your Fleet: " + Str(gPlayerFleetCount) + " ships")
  EndIf
  If gEnemyFleetCount > 0
    PrintN("Enemy Fleet: " + Str(gEnemyFleetCount) + " ships")
  EndIf
  PrintN("You:   " + *p\name + " [" + *p\class + "]")
  Print("  Hull: ")
  SetColorForPercent(Int(100.0 * *p\hull / ClampInt(*p\hullMax, 1, 999999)))
  Print(Str(*p\hull) + "/" + Str(*p\hullMax))
  ResetColor()
  Print("  Shields: ")
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN(Str(*p\shields) + "/" + Str(*p\shieldsMax))
  ResetColor()

  Print("  WeaponCap: ")
  ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK)
  Print(Str(*p\weaponCap) + "/" + Str(*p\weaponCapMax))
  ResetColor()
  Print("  Torps: ")
  ConsoleColor(#C_YELLOW, #C_BLACK)
  Print(Str(*p\torp))
  ResetColor()
  Print("  Probes: ")
  ConsoleColor(#C_YELLOW, #C_BLACK)
  Print(Str(*p\probes) + "/" + Str(*p\probesMax))
  ResetColor()
  Print("  Fuel: ")
  SetColorForPercent(Int(100.0 * *p\fuel / ClampInt(*p\fuelMax, 1, 999999)))
  PrintN(Str(*p\fuel))
  ResetColor()
  PrintN("  Alloc: " + Str(*p\allocEngines) + " | " + Str(*p\allocWeapons) + " | " + Str(*p\allocShields))
  PrintN("  Systems: Engines " + SysText(*p\sysEngines) + ", Weapons " + SysText(*p\sysWeapons) + ", Shields " + SysText(*p\sysShields))

  PrintArenaTactical(*p, *e, *cs)
  PrintN("")
  ConsoleColor(#C_LIGHTRED, #C_BLACK)
  PrintN("Enemy: " + *e\name + " [" + *e\class + "]")
  ResetColor()
  Print("  Hull: ")
  SetColorForPercent(Int(100.0 * *e\hull / ClampInt(*e\hullMax, 1, 999999)))
  Print(Str(*e\hull) + "/" + Str(*e\hullMax))
  ResetColor()
  Print("  Shields: ")
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN(Str(*e\shields) + "/" + Str(*e\shieldsMax))
  ResetColor()
  PrintDivider()
EndProcedure

Procedure PrintArenaTactical(*p.Ship, *e.Ship, *cs.CombatState)
  Protected posP.Integer, posE.Integer, interior.Integer
  ArenaPositions(*cs\range, @posP, @posE, @interior)
  PrintN("")
  PrintArenaFrame(posP\i, posE\i, -1, "", 0, 0, *cs, *e)
EndProcedure

Procedure ArenaPositions(range.i, *posP.Integer, *posE.Integer, *interior.Integer)
  Protected aw.i = 33
  Protected interior.i = aw - 2
  Protected scaleMax.i = 40
  Protected r.i = ClampInt(range, 1, scaleMax)

  Protected posP.i = 2
  Protected posE.i = posP + 2 + Int(r * (interior - 6) / scaleMax)
  posE = ClampInt(posE, posP + 2, interior - 3)

  *posP\i = posP
  *posE\i = posE
  *interior\i = interior
EndProcedure

Procedure PrintArenaFrame(posP.i, posE.i, fxPos.i, fxChar.s, beam.i, attackerIsEnemy.i, *cs.CombatState = 0, *e.Ship = 0)
  ; Draws a 5-row arena with optional effect: either a beam line or a single character.
  ; attackerIsEnemy: 0 = player, 1 = enemy
  ; Player phaser: cyan '=' | Player torpedo: yellow '*'
  ; Enemy disruptor: red '-' | Enemy torpedo: green '*'
  ; Fleet ships: '>' for player fleet (white=idle, yellow=attacking, red=hit)
  ;              '<' for enemy fleet (white=idle, yellow=attacking, red=hit)
  ; Pirate ships: 'P' instead of 'E'
  Protected aw.i = 33
  Protected interior.i = aw - 2
  Protected rowMid.i = 2
  
  Protected pFleetOffset.i = 3  ; Distance from player ship to first fleet ship
  Protected eFleetOffset.i = 3  ; Distance from enemy ship to first fleet ship (to the left)
  
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  PrintN("Arena")
  PrintN("+" + LSet("", aw - 2, "-") + "+")
  ResetColor()

  Protected y.i, x.i
  For y = 0 To 4
    ConsoleColor(#C_DARKGRAY, #C_BLACK)
    Print("|")
    ResetColor()

    For x = 0 To interior - 1
      Protected isFleetPos.i = 0
      
      ; Player fleet formation: 1 above, 2 below, 1-2 behind
      ; Ship 1: above @ (y=1, x=posP)
      ; Ship 2: below @ first (y=3, x=posP)
      ; Ship 3: below @ second (y=3, x=posP+2)
      ; Ship 4: behind @ (y=2, x=posP+2)
      ; Ship 5: behind @ (y=2, x=posP+4)
      If gPlayerFleetCount > 0
        Protected pfi.i
        For pfi = 1 To gPlayerFleetCount
          Protected pfY.i, pfX.i
          Select pfi
            Case 1
              pfY = 1  ; above
              pfX = posP
            Case 2
              pfY = 3  ; below first
              pfX = posP
            Case 3
              pfY = 3  ; below second
              pfX = posP + 2
            Case 4
              pfY = 2  ; behind
              pfX = posP + 2
            Case 5
              pfY = 2  ; behind second
              pfX = posP + 4
          EndSelect
          If pfX < posE - 2 And y = pfY And x = pfX
            If *cs And ((*cs\pFleetHit & (1 << (pfi - 1))) <> 0)
              ConsoleColor(#C_RED, #C_DARKGRAY)
              Print(">")
            ElseIf *cs And ((*cs\pFleetAttack & (1 << (pfi - 1))) <> 0)
              ConsoleColor(#C_YELLOW, #C_DARKGRAY)
              Print(">")
            Else
              ConsoleColor(#C_WHITE, #C_BLACK)
              Print(">")
            EndIf
            ResetColor()
            isFleetPos = 1
            Break
          EndIf
        Next
      EndIf
      
      ; Enemy fleet formation: 1 above, 2 below, 1-2 behind
      ; Ship 1: above E (y=1, x=posE)
      ; Ship 2: below E first (y=3, x=posE)
      ; Ship 3: below E second (y=3, x=posE-2)
      ; Ship 4: behind E (y=2, x=posE-2)
      ; Ship 5: behind E (y=2, x=posE-4)
      If isFleetPos = 0 And gEnemyFleetCount > 0
        Protected efi.i
        For efi = 1 To gEnemyFleetCount
          Protected efY.i, efX.i
          Select efi
            Case 1
              efY = 1  ; above
              efX = posE
            Case 2
              efY = 3  ; below first
              efX = posE
            Case 3
              efY = 3  ; below second
              efX = posE - 2
            Case 4
              efY = 2  ; behind
              efX = posE - 2
            Case 5
              efY = 2  ; behind second
              efX = posE - 4
          EndSelect
          If efX > posP + 2 And y = efY And x = efX
            If *cs And ((*cs\eFleetHit & (1 << (efi - 1))) <> 0)
              ConsoleColor(#C_RED, #C_DARKGRAY)
              Print("<")
            ElseIf *cs And ((*cs\eFleetAttack & (1 << (efi - 1))) <> 0)
              ConsoleColor(#C_YELLOW, #C_DARKGRAY)
              Print("<")
            Else
              ConsoleColor(#C_WHITE, #C_BLACK)
              Print("<")
            EndIf
            ResetColor()
            isFleetPos = 1
            Break
          EndIf
        Next
      EndIf
      
      If isFleetPos = 1
        Continue
      EndIf

      If y = rowMid And beam And x > posP And x < posE
        ; Beam: cyan '=' for player, red '-' for enemy
        If attackerIsEnemy = 0
          ConsoleColor(#C_CYAN, #C_BLACK)
          Print("=")
        Else
          ConsoleColor(#C_RED, #C_BLACK)
          Print("-")
        EndIf
        ResetColor()
        Continue
      EndIf

      If y = rowMid And fxPos >= 0 And x = fxPos
        ; Torpedo: yellow '*' for player, green '*' for enemy
        If attackerIsEnemy = 0
          ConsoleColor(#C_YELLOW, #C_BLACK)
        Else
          ConsoleColor(#C_GREEN, #C_BLACK)
        EndIf
        Print(fxChar)
        ResetColor()
        Continue
      EndIf

      If y = rowMid And x = posP
        ConsoleColor(#C_WHITE, #C_BLACK)
        Print("@")
        ResetColor()
      ElseIf y = rowMid And x = posE
        ConsoleColor(#C_LIGHTRED, #C_BLACK)
        ; Check if enemy is a pirate by entity type in galaxy
        If CurCell(gx, gy)\entType = #ENT_PIRATE
          Print("P")
        Else
          Print("E")
        EndIf
        ResetColor()
      Else
        ConsoleColor(#C_DARKGRAY, #C_BLACK)
        Print(".")
        ResetColor()
      EndIf
    Next

    ConsoleColor(#C_DARKGRAY, #C_BLACK)
    PrintN("|")
    ResetColor()
  Next

  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  PrintN("+" + LSet("", aw - 2, "-") + "+")
  ResetColor()
EndProcedure

Procedure TacticalFxPhaser(range.i, attackerIsEnemy.i)
  Protected posP.Integer, posE.Integer, interior.Integer
  ArenaPositions(range, @posP, @posE, @interior)
  ; Beam frame
  PrintArenaFrame(posP\i, posE\i, -1, "", 1, attackerIsEnemy, 0)
EndProcedure

Procedure TacticalFxTorpedo(range.i, attackerIsEnemy.i)
  Protected posP.Integer, posE.Integer, interior.Integer
  ArenaPositions(range, @posP, @posE, @interior)
  Protected fromPos.i = posP\i
  Protected toPos.i = posE\i
  If attackerIsEnemy
    fromPos = posE\i
    toPos = posP\i
  EndIf

  ; Single-frame projectile marker roughly mid-flight.
  Protected fx.i = (fromPos + toPos) / 2
  If fx = fromPos : fx + 1 : EndIf
  If fx = toPos : fx - 1 : EndIf
  PrintArenaFrame(posP\i, posE\i, fx, "*", 0, attackerIsEnemy, 0)
EndProcedure

Procedure.i EvasionBonus(*target.Ship)
  Protected bonus.i = *target\allocEngines / 10
  If (*target\sysEngines & #SYS_DAMAGED) : bonus / 2 : EndIf
  If (*target\sysEngines & #SYS_DISABLED) : bonus = 0 : EndIf
  bonus + CrewBonus(*target, #CREW_HELM)
  ProcedureReturn ClampInt(bonus, 0, 20)
EndProcedure

Procedure.i HitChance(range.i, *attacker.Ship, *target.Ship)
  ; Base hit chance: keep fights moving; range matters but shouldn't be a whiff-fest.
  Protected c.i = 92 - range * 3
  c - EvasionBonus(*target)
  If (*attacker\sysWeapons & #SYS_DAMAGED) : c - 8 : EndIf
  If (*attacker\sysWeapons & #SYS_DISABLED) : c = 0 : EndIf
  c + CrewBonus(*attacker, #CREW_WEAPONS)
  ProcedureReturn ClampInt(c, 12, 92)
EndProcedure

;==============================================================================
; ApplyDamage(*target.Ship, dmg.i)
; Applies damage to a ship, checking for system damage.
; Parameters:
;   *target - Ship to damage
;   dmg - Amount of damage to apply
; 
; What happens:
;   - Damage first reduces shields to 0, then hull
;   - If hull reaches 0, ship is destroyed
;   - 15% chance per damage instance to damage a random system:
;     * Weapons: Phasers/torpedoes may become disabled
;     * Shields: Shield regeneration stops
;     * Engines: Ship can't move
;     * Sensors: Can't scan
;     * Life Support: Crew takes damage
;     * Communications: Can't contact bases
;==============================================================================
Procedure ApplyDamage(*target.Ship, dmg.i)
  If dmg <= 0 : ProcedureReturn : EndIf

  If *target\shields > 0 And ((*target\sysShields & #SYS_DISABLED) = 0)
    Protected sHit.i = dmg
    If sHit > *target\shields : sHit = *target\shields : EndIf
    *target\shields - sHit
    If *target\shields < 0 : *target\shields = 0 : EndIf
    dmg - sHit
  EndIf

  If dmg > 0
    *target\hull - dmg
    If *target\hull < 0 : *target\hull = 0 : EndIf
  EndIf

  If dmg > 0 And Random(99) < 22
    Select Random(2)
      Case 0 : *target\sysEngines = *target\sysEngines | #SYS_DAMAGED
      Case 1 : *target\sysWeapons = *target\sysWeapons | #SYS_DAMAGED
      Case 2 : *target\sysShields = *target\sysShields | #SYS_DAMAGED
    EndSelect
  EndIf

  If (*target\sysEngines & #SYS_DAMAGED) And Random(99) < 10 : *target\sysEngines = *target\sysEngines | #SYS_DISABLED : EndIf
  If (*target\sysWeapons & #SYS_DAMAGED) And Random(99) < 10 : *target\sysWeapons = *target\sysWeapons | #SYS_DISABLED : EndIf
  If (*target\sysShields & #SYS_DAMAGED) And Random(99) < 10 : *target\sysShields = *target\sysShields | #SYS_DISABLED : EndIf
EndProcedure

;==============================================================================
; RegenAndRepair(*s.Ship, isEnemy.i)
; Regenerates shields and repairs hull at the end of each combat turn.
; Parameters:
;   *s - Ship to repair
;   isEnemy - 1 if enemy ship, 0 if player (affects repair rates)
; 
; Shield regeneration:
;   - Based on shield allocation percentage
;   - 10-30 shield points per turn depending on allocation
;   - Not affected by damage (shields always regen)
;
; Hull repair:
;   - 1-5 hull points per turn (random)
;   - Only if hull > 0 and not critically damaged
;   - Enemy ships repair slower than player
;==============================================================================
Procedure RegenAndRepair(*s.Ship, isEnemy.i)
  Protected reactor.i = *s\reactorMax
  Protected shP.i = reactor * *s\allocShields / 100
  Protected wP.i  = reactor * *s\allocWeapons / 100
  
  shP + CrewBonus(*s, #CREW_SHIELDS)
  wP + CrewBonus(*s, #CREW_ENGINEERING)

  If isEnemy
    ; Enemies regenerate/repair less so fights don't drag.
    shP = Int(shP * 0.25)
    wP  = Int(wP  * 0.55)
  EndIf
  
  If (*s\sysShields & #SYS_DISABLED) = 0
    If (*s\sysShields & #SYS_DAMAGED) : shP / 2 : EndIf
    If isEnemy
      *s\shields + 1  ; Enemies get minimal shield regen (1 per turn)
    Else
      *s\shields + (shP / 3)
    EndIf
    If *s\shields > *s\shieldsMax : *s\shields = *s\shieldsMax : EndIf
  EndIf

  If (*s\sysWeapons & #SYS_DISABLED) = 0
    If (*s\sysWeapons & #SYS_DAMAGED) : wP / 2 : EndIf
    *s\weaponCap + wP
    If *s\weaponCap > *s\weaponCapMax : *s\weaponCap = *s\weaponCapMax : EndIf
  EndIf

  Protected hullRepairChance.i = 30
  If isEnemy : hullRepairChance = 10 : EndIf
  hullRepairChance + CrewBonus(*s, #CREW_ENGINEERING)
  If *s\hull < *s\hullMax And Random(99) < hullRepairChance
    *s\hull + 1
  EndIf

  Protected sysFixChance.i = 18
  If isEnemy : sysFixChance = 8 : EndIf
  sysFixChance + CrewBonus(*s, #CREW_ENGINEERING)
  If (*s\sysEngines & #SYS_DAMAGED) And Random(99) < sysFixChance : *s\sysEngines = #SYS_OK : EndIf
  If (*s\sysWeapons & #SYS_DAMAGED) And Random(99) < sysFixChance : *s\sysWeapons = #SYS_OK : EndIf
  If (*s\sysShields & #SYS_DAMAGED) And Random(99) < sysFixChance : *s\sysShields = #SYS_OK : EndIf
EndProcedure

Procedure.i CombatMaxMove(*p.Ship)
  Protected maxMove.i = 1 + (*p\allocEngines / 20)
  If (*p\sysEngines & #SYS_DAMAGED) : maxMove = ClampInt(maxMove / 2, 1, 6) : EndIf
  If (*p\sysEngines & #SYS_DISABLED) : maxMove = 0 : EndIf
  ProcedureReturn ClampInt(maxMove, 0, 6)
EndProcedure

;==============================================================================
; PlayerMove(*p.Ship, *cs.CombatState, dir.s, amount.i)
; Moves the player ship in combat (changes range to enemy).
; Parameters:
;   *p - Pointer to player ship
;   *cs - Pointer to combat state
;   dir - Direction: "closer" or "away" (or "in" / "out")
;   amount - How many units to move (default 2)
; 
; What it does:
; - Consumes fuel for each move (1 fuel per move)
; - Changes combat range: closer moves toward enemy, away moves farther
; - Minimum range is 1, maximum is 40
; - Each move uses engine power from weapon cap
;==============================================================================
Procedure PlayerMove(*p.Ship, *cs.CombatState, dir.s, amount.i)
  Protected maxMove.i = CombatMaxMove(*p)
  If maxMove <= 0
    PrintN("Engines are disabled.")
    ProcedureReturn
  EndIf
  If *p\fuel <= 0
    LogLine("MOVE: fuel depleted")
    PrintN("Fuel depleted.")
    ProcedureReturn
  EndIf

  dir = TrimLower(dir)
  amount = ClampInt(amount, 1, maxMove)

  Select dir
    Case "approach"
      *cs\range - amount
      If *cs\range < 1 : *cs\range = 1 : EndIf
      *p\fuel - 1
      PrintN("You close distance by " + Str(amount) + ".")
    Case "retreat"
      *cs\range + amount
      If *cs\range > 40 : *cs\range = 40 : EndIf
      *p\fuel - 1
      PrintN("You open distance by " + Str(amount) + ".")
    Case "hold"
      PrintN("You hold position.")
    Default
      PrintN("MOVE expects APPROACH, RETREAT, or HOLD.")
  EndSelect
EndProcedure

;==============================================================================
; PlayerPhaser(*p.Ship, *e.Ship, *cs.CombatState, power.i)
; Executes player's phaser attack on enemy ship.
; Parameters:
;   *p - Pointer to player ship
;   *e - Pointer to enemy ship
;   *cs - Pointer to combat state
;   power - Power level for phasers (1-100, default 30)
; 
; What it does:
; - Checks if weapons are operational
; - Calculates phaser power based on weapon cap and power level
; - 80% base hit chance, reduced by range
; - Damage reduced by enemy shields first, then hull
; - Plays phaser sound and shows tactical effect
;==============================================================================
Procedure PlayerPhaser(*p.Ship, *e.Ship, *cs.CombatState, power.i)
  If (*p\sysWeapons & #SYS_DISABLED)
    PrintN("Weapons are disabled.")
    ProcedureReturn
  EndIf
  If *p\weaponCap <= 0
    PrintN("Weapon capacitor empty.")
    ProcedureReturn
  EndIf

  Protected maxPerTurn.i = *p\phaserBanks * 25
  power = ClampInt(power, 1, *p\weaponCap)
  power = ClampInt(power, 1, maxPerTurn)

  *p\weaponCap - power

  PlayPhaserSound()
  TacticalFxPhaser(*cs\range, 0)

  Protected chance.i = HitChance(*cs\range, *p, *e) + *cs\pAim
  If Random(99) < chance
    Protected base.i = (power / 3) + Random(ClampInt(power / 3, 0, 999999))
    If base < 1 : base = 1 : EndIf

    Protected falloff.f = 1.0 - (*cs\range / 55.0)
    falloff = ClampF(falloff, 0.25, 1.0)
    Protected dmg.i = Int(base * falloff)
    If dmg < 1 : dmg = 1 : EndIf

    ; Phasers damage shields first, then hull when shields are down
    If *e\shields > 0 And ((*e\sysShields & #SYS_DISABLED) = 0)
      If dmg > *e\shields
        Protected remaining.i = dmg - *e\shields
        *e\shields = 0
        *e\hull - remaining
        If *e\hull < 0 : *e\hull = 0 : EndIf
        PrintN("Phasers hit! (" + Str(dmg) + " shields, " + Str(remaining) + " hull)!")
    Else
      *p\shields - dmg
      If *p\shields < 0 : *p\shields = 0 : EndIf
      PrintN("Phasers hit! (" + Str(dmg) + " shields).")
    EndIf
  Else
    ; Shields down - phasers damage hull directly
      *e\hull - dmg
      If *e\hull < 0 : *e\hull = 0 : EndIf
      PrintN("Phasers hit HULL! (" + Str(dmg) + " hull damage)!")
    EndIf
    *cs\pAim = 0
    GainCrewXP(*p, #CREW_WEAPONS, 5 + dmg / 10)
  Else
    PrintN("Phasers miss.")
    *cs\pAim = ClampInt(*cs\pAim + 7, 0, 28)
  EndIf
EndProcedure

;==============================================================================
; PlayerTorpedo(*p.Ship, *e.Ship, *cs.CombatState, count.i)
; Executes player's photon torpedo attack on enemy ship.
; Parameters:
;   *p - Pointer to player ship
;   *e - Pointer to enemy ship
;   *cs - Pointer to combat state
;   count - Number of torpedoes to fire (default 1)
; 
; What it does:
; - Checks if torpedoes are available and weapons operational
; - Requires close range (torpedoes only work at range < 15)
; - Each torpedo has high damage (50-80) but 40% miss chance
; - Consumes torpedoes from inventory
; - Plays torpedo sound and shows tactical effect
;==============================================================================
Procedure PlayerTorpedo(*p.Ship, *e.Ship, *cs.CombatState, count.i)
  If (*p\sysWeapons & #SYS_DISABLED)
    PrintN("Weapons are disabled.")
    ProcedureReturn
  EndIf
  If *p\torp <= 0
    PrintN("No torpedoes remaining.")
    ProcedureReturn
  EndIf
  If *cs\range > 24
    PrintN("Target out of torpedo effective range.")
    ProcedureReturn
  EndIf

  count = ClampInt(count, 1, *p\torpTubes)
  count = ClampInt(count, 1, *p\torp)

  Protected i.i
  For i = 1 To count
    *p\torp - 1

    PlayTorpedoSound()
    TacticalFxTorpedo(*cs\range, 0)
    ; Torpedoes are more reliable at close range, less at long range.
    Protected chance.i = HitChance(*cs\range, *p, *e) + 10 - Int(*cs\range / 2) + *cs\pAim
    chance = ClampInt(chance, 20, 95)
    If Random(99) < chance
      Protected dmg.i = 44 + Random(34)
      If *cs\range > 20 : dmg - 6 : EndIf
      If dmg < 1 : dmg = 1 : EndIf

      ; Torpedo shield penetration chance based on range
      ; Close range = high penetration, far range = low penetration
      Protected penetrationChance.i = 90 - (*cs\range * 2)
      If penetrationChance < 10 : penetrationChance = 10 : EndIf
      
      ; Torpedoes punch through shields at close range, otherwise damage both
      If *e\shields > 0 And ((*e\sysShields & #SYS_DISABLED) = 0)
        If Random(99) < penetrationChance
          ; Shield penetration - damage hull directly
          If dmg > *e\shields
            Protected remaining.i = dmg - *e\shields
            *e\shields = 0
            *e\hull - remaining
            If *e\hull < 0 : *e\hull = 0 : EndIf
            PrintN("Torpedo impact! PENETRATION (" + Str(dmg) + " shields, " + Str(remaining) + " hull)!")
          Else
            *e\shields - dmg
            If *e\shields < 0 : *e\shields = 0 : EndIf
            PrintN("Torpedo impact! PENETRATION (" + Str(dmg) + " shields)!")
          EndIf
        Else
          ; No penetration - damage shields only
          If dmg > *e\shields
            *e\shields = 0
          Else
            *e\shields - dmg
            If *e\shields < 0 : *e\shields = 0 : EndIf
          EndIf
          PrintN("Torpedo impact! (" + Str(dmg) + " shields).")
        EndIf
      Else
        ; No shields - direct hull damage
        *e\hull - dmg
        If *e\hull < 0 : *e\hull = 0 : EndIf
        PrintN("Torpedo impact! (" + Str(dmg) + " hull damage)!")
      EndIf
      *cs\pAim = 0
      GainCrewXP(*p, #CREW_WEAPONS, 8 + dmg / 8)
    Else
      PrintN("Torpedo misses.")
      *cs\pAim = ClampInt(*cs\pAim + 7, 0, 28)
    EndIf
    If *e\hull <= 0 : Break : EndIf
  Next
EndProcedure

Procedure PlayerTractor(*p.Ship, *e.Ship, *cs.CombatState, mode.s)
  If (*p\sysTractor & #SYS_DISABLED)
    PrintN("Tractor beam is disabled.")
    ProcedureReturn
  EndIf
  
  mode = TrimLower(mode)
  
  Protected costType.s = "fuel"
  Protected costAmount.i = 1
  
  If mode = "pull"
    ; Pull mode costs dilithium
    If *p\dilithium < 1 And *p\fuel < 1
      PrintN("Not enough fuel or dilithium for tractor beam.")
      ProcedureReturn
    EndIf
    If *p\dilithium >= 1
      *p\dilithium - 1
      costType = "dilithium"
    Else
      *p\fuel - 1
    EndIf
    
    ; Cannot pull if already very close
    If *cs\range <= 3
      PrintN("Target already in close range!")
      ProcedureReturn
    EndIf
    
    ; Pull enemy 2 sectors closer
    *cs\range - 2
    If *cs\range < 1 : *cs\range = 1 : EndIf
    
    ; Check if enemy can resist (smaller chance at close range)
    Protected resistChance.i = 40 - (30 - *cs\range) * 2
    If resistChance < 10 : resistChance = 10 : EndIf
    
    If Random(99) < resistChance
      ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
      PrintN(">>> TRACTOR BEAM: Pulling target closer! <<<")
      ResetColor()
      PrintN("Target is now at range " + Str(*cs\range) + ".")
    Else
      PrintN("Tractor beam fails to hold the target.")
    EndIf
    
  ElseIf mode = "push"
    ; Push mode - push enemy into adjacent hazard
    If *p\fuel < 1
      PrintN("Not enough fuel for tractor beam (1 fuel/turn).")
      ProcedureReturn
    EndIf
    *p\fuel - 1
    
    ; Find adjacent hazard cells (sun, blackhole, wormhole)
    Protected foundHazard.i = 0
    Protected pushX.i = gEnemyX
    Protected pushY.i = gEnemyY
    Protected hazardType.i = #ENT_EMPTY
    
    ; Check all adjacent cells for hazards
    Protected dx.i, dy.i
    For dy = -1 To 1
      For dx = -1 To 1
        If dx = 0 And dy = 0 : Continue : EndIf
        Protected nx.i = gEnemyX + dx
        Protected ny.i = gEnemyY + dy
        If nx >= 0 And nx < #MAP_W And ny >= 0 And ny < #MAP_H
          Protected adjEnt.i = gGalaxy(gMapX, gMapY, nx, ny)\entType
          If adjEnt = #ENT_SUN Or adjEnt = #ENT_BLACKHOLE Or adjEnt = #ENT_WORMHOLE
            foundHazard = 1
            pushX = nx
            pushY = ny
            hazardType = adjEnt
            Break 2
          EndIf
        EndIf
      Next
    Next
    
    If foundHazard = 0
      ; No hazard nearby, just push enemy further away
      *cs\range + 2 + Random(2)
      If *cs\range > 40 : *cs\range = 40 : EndIf
      
      ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
      PrintN(">>> TRACTOR BEAM: Pushing target away! <<<")
      ResetColor()
      PrintN("Target pushed to range " + Str(*cs\range) + ".")
    Else
      ; Push into hazard!
      ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
      PrintN(">>> TRACTOR BEAM: Pushing target into hazard! <<<")
      ResetColor()
      
      Select hazardType
        Case #ENT_SUN
          *e\hull = 0
          PrintN("The enemy is pushed into a SUN and disintegrates!")
          LogLine("TRACTOR: pushed enemy into sun")
        Case #ENT_BLACKHOLE
          *e\hull = 0
          PrintN("The enemy is swallowed by a BLACK HOLE!")
          LogLine("TRACTOR: pushed enemy into black hole")
        Case #ENT_WORMHOLE
          PrintN("The enemy is pulled into a WORMHOLE and teleports away!")
          *e\hull = 0
          LogLine("TRACTOR: pushed enemy into wormhole")
      EndSelect
      
      ; Enemy is destroyed - trigger victory
      *cs\range = -1
    EndIf
    
  Else
    ; HOLD mode (default) - costs 1 fuel
    If *p\fuel < 1
      PrintN("Not enough fuel for tractor beam (1 fuel/turn).")
      ProcedureReturn
    EndIf
    *p\fuel - 1
    
    ; Hold enemy in place - affects enemy movement
    *p\sysTractor = *p\sysTractor | #SYS_TRACTOR
    
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
    PrintN(">>> TRACTOR BEAM: Target locked in place! <<<")
    ResetColor()
    PrintN("Enemy cannot move this turn.")
  EndIf
  
  LogLine("TRACTOR: " + mode + " (range=" + Str(*cs\range) + ")")
EndProcedure

;==============================================================================
; EnemyAI(*e.Ship, *p.Ship, *cs.CombatState)
; Controls enemy ship behavior during combat. Called at the end of each turn.
; Parameters:
;   *e - Pointer to enemy ship
;   *p - Pointer to player ship
;   *cs - Pointer to combat state
; 
; AI Decision Logic:
; - If shields low: recharge shields before attacking
; - If far away: move closer or hold position
; - If close enough: attack with phasers or torpedoes
; - Random targeting and power management based on hull/shield status
; - 40% chance to use torpedoes if available, otherwise phasers
;==============================================================================
Procedure EnemyAI(*e.Ship, *p.Ship, *cs.CombatState)
  If *e\hull <= 0 : ProcedureReturn : EndIf
  
  ; Enemy decides: 40% move, 40% phaser attack, 20% torpedo attack (if able)
  Protected actionRoll.i = Random(99)
  
  ; Check if weapons are functional
  Protected weaponsOk.i = Bool(( *e\sysWeapons & #SYS_DISABLED) = 0)
  
  ; Phaser attack (40% chance)
  If actionRoll < 40 And weaponsOk
    Protected maxPhaser.i = *e\phaserBanks * 20
    Protected phaserPower.i = Random(maxPhaser)
    If phaserPower < 5 : phaserPower = 5 : EndIf
    
    TacticalFxPhaser(*cs\range, 1)
    PlayDisruptorSound()
    
    Protected chance.i = HitChance(*cs\range, *e, *p) + *cs\eAim
    If Random(99) < chance
      Protected base.i = (phaserPower / 3) + Random(ClampInt(phaserPower / 3, 0, 999999))
      If base < 1 : base = 1 : EndIf
      Protected falloff.f = 1.0 - (*cs\range / 55.0)
      falloff = ClampF(falloff, 0.25, 1.0)
      Protected dmg.i = Int(base * falloff)
      If dmg < 1 : dmg = 1 : EndIf
      
      ; Enemy phasers damage shields first, then hull when shields are down
      If *p\shields > 0 And ((*p\sysShields & #SYS_DISABLED) = 0)
        If dmg > *p\shields
          Protected rem.i = dmg - *p\shields
          *p\shields = 0
          *p\hull - rem
          If *p\hull < 0 : *p\hull = 0 : EndIf
          PrintN("Enemy fires disruptors! (" + Str(dmg) + " shields, " + Str(rem) + " hull)!")
        Else
          *p\shields - dmg
          If *p\shields < 0 : *p\shields = 0 : EndIf
          PrintN("Enemy fires disruptors! (" + Str(dmg) + " shields).")
        EndIf
      Else
        ; Shields down - phasers damage hull directly
        *p\hull - dmg
        If *p\hull < 0 : *p\hull = 0 : EndIf
        PrintN("Enemy disruptors hit HULL! (" + Str(dmg) + " hull damage)!")
      EndIf
      *cs\eAim = 0
    Else
      PrintN("Enemy disruptors miss.")
      *cs\eAim = ClampInt(*cs\eAim + 7, 0, 28)
    EndIf
    ProcedureReturn
  EndIf
  
  ; Torpedo attack (20% chance, if torpedoes available and in range)
  If actionRoll < 60 And weaponsOk And *e\torp > 0 And *cs\range <= 24
    Protected torpCount.i = 1
    If *e\torpTubes > 1 And *e\torp > 1 And Random(1) = 0
      torpCount = 2
    EndIf
    torpCount = ClampInt(torpCount, 1, *e\torp)
    
    Protected i.i
    For i = 1 To torpCount
      *e\torp - 1
      
      TacticalFxTorpedo(*cs\range, 1)
      PlayTorpedoSound()
      
      Protected torpChance.i = HitChance(*cs\range, *e, *p) + 10 - Int(*cs\range / 2) + *cs\eAim
      torpChance = ClampInt(torpChance, 20, 95)
      If Random(99) < torpChance
        Protected torpDmg.i = 40 + Random(30)
        If *cs\range > 20 : torpDmg - 6 : EndIf
        If torpDmg < 1 : torpDmg = 1 : EndIf
        
        ; Torpedo shield penetration chance based on range
        Protected penetrationChance.i = 90 - (*cs\range * 2)
        If penetrationChance < 10 : penetrationChance = 10 : EndIf
        
        ; Enemy torpedoes punch through shields at close range
        If *p\shields > 0 And ((*p\sysShields & #SYS_DISABLED) = 0)
          If Random(99) < penetrationChance
            ; Shield penetration - damage hull directly
            If torpDmg > *p\shields
              Protected remaining.i = torpDmg - *p\shields
              *p\shields = 0
              *p\hull - remaining
              If *p\hull < 0 : *p\hull = 0 : EndIf
              PrintN("Enemy torpedo impact! PENETRATION (" + Str(torpDmg) + " shields, " + Str(remaining) + " hull)!")
            Else
              *p\shields - torpDmg
              If *p\shields < 0 : *p\shields = 0 : EndIf
              PrintN("Enemy torpedo impact! PENETRATION (" + Str(torpDmg) + " shields)!")
            EndIf
          Else
            ; No penetration - damage shields only
            If torpDmg > *p\shields
              *p\shields = 0
            Else
              *p\shields - torpDmg
              If *p\shields < 0 : *p\shields = 0 : EndIf
            EndIf
            PrintN("Enemy torpedo impact! (" + Str(torpDmg) + " shields).")
          EndIf
        Else
          ; No shields - direct hull damage
          *p\hull - torpDmg
          If *p\hull < 0 : *p\hull = 0 : EndIf
          PrintN("Enemy torpedo impact! (" + Str(torpDmg) + " hull damage)!")
        EndIf
        *cs\eAim = 0
      Else
        PrintN("Enemy torpedo misses.")
        *cs\eAim = ClampInt(*cs\eAim + 7, 0, 28)
      EndIf
    Next
    ProcedureReturn
  EndIf
  
  ; Movement (remaining 40% or if can't attack)
  Protected moveChance.i = 35
  
  ; Check if tractor beam is holding enemy
  If (*p\sysTractor & #SYS_TRACTOR)
    PrintN("Tractor beam holds enemy in place!")
    *p\sysTractor = *p\sysTractor & ~#SYS_TRACTOR  ; Clear tractor flag
    ProcedureReturn
  EndIf
  
  If Random(99) >= moveChance
    PrintN("Enemy holds position.")
    ProcedureReturn
  EndIf
  
  If (*e\sysEngines & #SYS_DISABLED) = 0
    Protected moveType.i = Random(1)
    If moveType = 0
      *cs\range - 1 - Random(2)
      If *cs\range < 1 : *cs\range = 1 : EndIf
      PrintN("Enemy maneuvers to close distance.")
    Else
      *cs\range + 1 + Random(2)
      If *cs\range > 40 : *cs\range = 40 : EndIf
      PrintN("Enemy maneuvers to increase distance.")
    EndIf
  Else
    PrintN("Enemy engines disabled - holds position.")
  EndIf
EndProcedure

;==============================================================================
; EnemyGalaxyAI(*p.Ship, *enemyTemplate.Ship, *cs.CombatState)
; Controls enemy ship movement and behavior in galaxy mode.
; Called at the end of each player turn when enemies are present.
; 
; AI behavior:
;   - Enemies move toward player if in same galaxy
;   - Movement speed based on enemy level (higher = faster)
;   - If enemy enters player's sector, combat begins
;   - Enemy names update as they upgrade (Raider -> Fighter -> Cruiser -> Destroyer)
;   - Higher level enemies have more hull, shields, and weapons
;==============================================================================
Procedure EnemyGalaxyAI(*p.Ship, *enemyTemplate.Ship, *cs.CombatState)
  Protected mx.i, my.i, x.i, y.i, dx.i, dy.i, nx.i, ny.i
  Protected targetFound.i, targetX.i, targetY.i
  Protected moveChance.i = 35
  Protected enemy.Ship
  
  If Random(99) >= moveChance
    ProcedureReturn
  EndIf
  
  For my = 0 To #GALAXY_H - 1
    For mx = 0 To #GALAXY_W - 1
      For y = 0 To #MAP_H - 1
        For x = 0 To #MAP_W - 1
          If gGalaxy(mx, my, x, y)\entType <> #ENT_ENEMY
            Continue
          EndIf
          
          targetFound = 0
          targetX = -1
          targetY = -1
          
          For dy = -1 To 1
            For dx = -1 To 1
              If dx = 0 And dy = 0 : Continue : EndIf
              nx = x + dx
              ny = y + dy
              
              If nx < 0 Or nx >= #MAP_W Or ny < 0 Or ny >= #MAP_H
                Continue
              EndIf
              
              Protected ent.i = gGalaxy(mx, my, nx, ny)\entType
              
              If mx = gMapX And my = gMapY And nx = gx And ny = gy
                Protected lvl.i = gGalaxy(mx, my, x, y)\enemyLevel
                If lvl < 1 : lvl = 1 : EndIf
                CopyStructure(*enemyTemplate, @enemy, Ship)
                ; Check for Planet Killer (very powerful)
                If enemy\name = "Planet Killer"
                  enemy\class = "Planet Killer"
                  enemy\hullMax = 500 + (lvl * 50)
                  enemy\hull = enemy\hullMax
                  enemy\shieldsMax = 400 + (lvl * 40)
                  enemy\shields = enemy\shieldsMax
                  enemy\weaponCapMax = 600 + (lvl * 50)
                  enemy\weaponCap = enemy\weaponCapMax
                  enemy\phaserBanks = 12
                  enemy\torpTubes = 4
                  enemy\torpMax = 20
            enemy\torp = enemy\torpMax
          ElseIf CurCell(gx, gy)\entType = #ENT_PIRATE And enemy\name = ""
            enemy\name = "Pirate Hunter"
            enemy\class = "Pirate"
          ElseIf enemy\name = "" Or enemy\hullMax <= 0
                  enemy\name = "Raider"
                  enemy\class = "Raider"
                  enemy\hullMax = 100
                  enemy\hull = 100
                  enemy\shieldsMax = 90
                  enemy\shields = 90
                  enemy\weaponCapMax = 210
                  enemy\weaponCap = 105
                  enemy\phaserBanks = 6
                  enemy\torpTubes = 2
                  enemy\torpMax = 8
                  enemy\torp = 8
                EndIf
                enemy\hullMax = enemy\hullMax + (lvl * 10)
                enemy\hull = enemy\hullMax
                enemy\shieldsMax = enemy\shieldsMax + (lvl * 12)
                enemy\shields = enemy\shieldsMax
                enemy\weaponCapMax = enemy\weaponCapMax + (lvl * 20)
                enemy\weaponCap = enemy\weaponCapMax / 2
                enemy\torp = enemy\torpMax
                gEnemyMapX = mx : gEnemyMapY = my : gEnemyX = x : gEnemyY = y
                EnterCombat(*p, @enemy, *cs)
                ProcedureReturn
              EndIf
              
              If ent = #ENT_BASE Or ent = #ENT_PLANET Or ent = #ENT_WORMHOLE Or ent = #ENT_SHIPYARD Or ent = #ENT_DILITHIUM
                If targetFound = 0 Or Random(1) = 0
                  targetFound = 1
                  targetX = nx
                  targetY = ny
                EndIf
              EndIf
            Next
          Next
          
          If targetFound = 1 And targetX >= 0 And targetY >= 0
            If gGalaxy(mx, my, targetX, targetY)\entType = #ENT_EMPTY
              Protected moveX.i = x + Sign(targetX - x)
              Protected moveY.i = y + Sign(targetY - y)
              
                If moveX >= 0 And moveX < #MAP_W And moveY >= 0 And moveY < #MAP_H
                If gGalaxy(mx, my, moveX, moveY)\entType = #ENT_EMPTY
                  Protected oldName.s = gGalaxy(mx, my, x, y)\name
                  Protected oldLevel.i = gGalaxy(mx, my, x, y)\enemyLevel
                  If oldLevel < 1 : oldLevel = 1 : EndIf
                  If oldName = "" : oldName = "Raider" : EndIf
                  gGalaxy(mx, my, x, y)\entType = #ENT_EMPTY
                  gGalaxy(mx, my, x, y)\name = ""
                  gGalaxy(mx, my, x, y)\enemyLevel = 0
                  gGalaxy(mx, my, moveX, moveY)\entType = #ENT_ENEMY
                  gGalaxy(mx, my, moveX, moveY)\name = oldName
                  gGalaxy(mx, my, moveX, moveY)\enemyLevel = oldLevel
                  
                  If mx = gMapX And my = gMapY And moveX = gx And moveY = gy
                    Protected newLvl.i = gGalaxy(mx, my, moveX, moveY)\enemyLevel
                    If newLvl < 1 : newLvl = 1 : EndIf
                    CopyStructure(*enemyTemplate, @enemy, Ship)
                    ; Ensure enemy has valid stats and name
                    If enemy\name = "" Or enemy\hullMax <= 0
                      enemy\name = "Raider"
                      enemy\class = "Raider"
                      enemy\hullMax = 100
                      enemy\hull = 100
                      enemy\shieldsMax = 90
                      enemy\shields = 90
                      enemy\weaponCapMax = 210
                      enemy\weaponCap = 105
                      enemy\phaserBanks = 6
                      enemy\torpTubes = 2
                      enemy\torpMax = 8
                      enemy\torp = 8
                    EndIf
                    enemy\hullMax = enemy\hullMax + (newLvl * 10)
                    enemy\hull = enemy\hullMax
                    enemy\shieldsMax = enemy\shieldsMax + (newLvl * 12)
                    enemy\shields = enemy\shieldsMax
                    enemy\weaponCapMax = enemy\weaponCapMax + (newLvl * 20)
                    enemy\weaponCap = enemy\weaponCapMax / 2
                    enemy\torp = enemy\torpMax
                    gEnemyMapX = mx : gEnemyMapY = my : gEnemyX = moveX : gEnemyY = moveY
                    EnterCombat(*p, @enemy, *cs)
                    ProcedureReturn
            EndIf
          EndIf
        EndIf
        
        ; Player's fleet attacks automatically after player fires (BEFORE display so color shows)
        If gPlayerFleetCount > 0 And enemy\hull > 0
          Protected pf.i, pfDmg.i
          For pf = 1 To gPlayerFleetCount
            If gPlayerFleet(pf)\hull > 0
              pfDmg = Random(25) + 5
              *cs\pFleetAttack = *cs\pFleetAttack | (1 << (pf - 1))
              PlaySoundFX(SoundPhaser)
              If Random(99) < 50
                enemy\shields - pfDmg
                If enemy\shields < 0
                  enemy\hull + enemy\shields
                  enemy\shields = 0
                EndIf
                PrintN("Fleet ship " + Str(pf) + " fires at enemy! " + Str(pfDmg) + " damage!")
              Else
                PrintN("Fleet ship " + Str(pf) + " fires but misses!")
              EndIf
            EndIf
          Next
        EndIf
        
        PrintStatusTactical(*p, @enemy, *cs)
            EndIf
          EndIf
        Next
      Next
    Next
  Next
EndProcedure

Procedure PrintScanTactical(*p.Ship, *e.Ship, *cs.CombatState)
  ; Ensure enemy has valid stats (defensive)
  If *e\name = "" Or *e\hullMax <= 0
    *e\name = "Raider"
    *e\class = "Raider"
    *e\hullMax = 100
    *e\hull = 100
    *e\shieldsMax = 90
    *e\shields = 90
    *e\weaponCapMax = 210
    *e\weaponCap = 105
    *e\phaserBanks = 6
    *e\torpTubes = 2
    *e\torpMax = 8
    *e\torp = 8
  EndIf
  
  If *cs\range > *p\sensorRange
    PrintN("Sensors: contact beyond effective range.")
    ProcedureReturn
  EndIf
  PrintDivider()
  PrintN("Sensors Report")
  PrintN("  Contact: " + *e\name + " [" + *e\class + "]")
  PrintN("  Range:   " + Str(*cs\range))
  PrintN("  Shields: " + Str(*e\shields) + "/" + Str(*e\shieldsMax) + " (" + SysText(*e\sysShields) + ")")
  PrintN("  Hull:    " + Str(*e\hull) + "/" + Str(*e\hullMax))
  PrintDivider()
EndProcedure

Procedure.s EntSymbol(t.i)
  Select t
    Case #ENT_EMPTY  : ProcedureReturn "."
    Case #ENT_STAR   : ProcedureReturn "*"
    Case #ENT_PLANET : ProcedureReturn "O"
    Case #ENT_BASE   : ProcedureReturn "%"
    Case #ENT_ENEMY  : ProcedureReturn "E"
    Case #ENT_PIRATE : ProcedureReturn "P"
    Case #ENT_SHIPYARD: ProcedureReturn "+"
    Case #ENT_WORMHOLE: ProcedureReturn "#"
    Case #ENT_BLACKHOLE: ProcedureReturn "?"
    Case #ENT_SUN: ProcedureReturn "S"
    Case #ENT_DILITHIUM: ProcedureReturn "D"
    Case #ENT_ANOMALY: ProcedureReturn "A"
    Case #ENT_PLANETKILLER: ProcedureReturn "<"
    Case #ENT_REFINERY: ProcedureReturn "R"
  EndSelect
  ProcedureReturn "?"
EndProcedure

; Gravity well: when adjacent to a SUN or BLACKHOLE, may pull you onto it.
; Returns 1 if it moved the player and caller should re-process arrival.
Procedure.i ApplyGravityWell(*p.Ship)
  Protected dx.i, dy.i, nx.i, ny.i
  Protected foundSun.i = 0
  Protected foundBH.i = 0
  Protected sunX.i, sunY.i, bhX.i, bhY.i

  ; Only cardinal adjacency (1 move away)
  For dy = -1 To 1
    For dx = -1 To 1
      If Abs(dx) + Abs(dy) <> 1 : Continue : EndIf
      nx = gx + dx
      ny = gy + dy
      If nx < 0 Or nx >= #MAP_W Or ny < 0 Or ny >= #MAP_H
        Continue
      EndIf
      Select CurCell(nx, ny)\entType
        Case #ENT_SUN
          foundSun = 1 : sunX = nx : sunY = ny
        Case #ENT_BLACKHOLE
          foundBH = 1 : bhX = nx : bhY = ny
      EndSelect
    Next
  Next

  ; Prefer SUN pull over BLACKHOLE if both present.
  If foundSun
    If Random(99) < 85
      gx = sunX : gy = sunY
      LogLine("SUN: gravity well pulls you in!")
      PrintN("Warning: sun gravity well! Pulled into the sun.")
      ProcedureReturn 1
    EndIf
  ElseIf foundBH
    If Random(99) < 55
      gx = bhX : gy = bhY
      LogLine("BLACK HOLE: gravity well pulls you in!")
      PrintN("Warning: black hole gravity well! Pulled into the black hole.")
      ProcedureReturn 1
    EndIf
  EndIf

  ProcedureReturn 0
EndProcedure

; Returns 1 if the sun effect triggers and caller should stop further processing.
Procedure.i HandleSun(*p.Ship)
  If CurCell(gx, gy)\entType <> #ENT_SUN
    ProcedureReturn 0
  EndIf

  *p\hull = 0
  *p\shields = 0
  LogLine("SUN: your ship was incinerated!")
  PrintN("You are consumed by the sun. Ship incinerated.")
  ProcedureReturn 1
EndProcedure

Procedure.i RandomEmptyCell(mapX.i, mapY.i, *outX.Integer, *outY.Integer)
  Protected tries.i, x.i, y.i
  For tries = 1 To 400
    x = Random(#MAP_W - 1)
    y = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, x, y)\entType = #ENT_EMPTY
      *outX\i = x
      *outY\i = y
      ProcedureReturn 1
    EndIf
  Next
  ProcedureReturn 0
EndProcedure

; Returns 1 if it moved the player (teleport/scramble) and caller should stop further processing.
Procedure.i HandleArrival(*p.Ship)
  Protected t.i = CurCell(gx, gy)\entType
  Protected mx.i, my.i, nx.i, ny.i

  If t = #ENT_WORMHOLE
    If *p\fuel > 0 : *p\fuel - 1 : EndIf
    mx = Random(#GALAXY_W - 1)
    my = Random(#GALAXY_H - 1)
    If RandomEmptyCell(mx, my, @nx, @ny)
      gMapX = mx : gMapY = my
      gx = nx : gy = ny
      LogLine("WORMHOLE: transit to Galaxy (" + Str(gMapX) + "," + Str(gMapY) + ") Sector (" + Str(gx) + "," + Str(gy) + ")")
      PrintN("Wormhole transit! New location: Galaxy (" + Str(gMapX) + "," + Str(gMapY) + ") Sector (" + Str(gx) + "," + Str(gy) + ")")
      ProcedureReturn 1
    EndIf
  ElseIf t = #ENT_BLACKHOLE
    Protected r.i = Random(99)
    If r < 40
      ; Random relocation
      mx = Random(#GALAXY_W - 1)
      my = Random(#GALAXY_H - 1)
      If RandomEmptyCell(mx, my, @nx, @ny)
        gMapX = mx : gMapY = my
        gx = nx : gy = ny
        LogLine("BLACK HOLE: spacetime shear - displaced.")
        PrintN("Black hole encounter! Spacetime shear displaces you.")
        ProcedureReturn 1
      EndIf
    ElseIf r < 85
      ; Severe damage
      Protected dmg.i = 60 + Random(60)
      ApplyDamage(*p, dmg)
      LogLine("BLACK HOLE: tidal forces hit for " + Str(dmg) + "!")
      PrintN("Black hole tidal forces hit for " + Str(dmg) + ".")

      ; Scramble to a nearby sector if possible
      Protected tries.i
      For tries = 1 To 25
        nx = gx + (Random(2) - 1)
        ny = gy + (Random(2) - 1)
        If nx >= 0 And nx < #MAP_W And ny >= 0 And ny < #MAP_H
          If CurCell(nx, ny)\entType = #ENT_EMPTY
            gx = nx : gy = ny
            ProcedureReturn 1
          EndIf
        EndIf
      Next
    Else
      ; Destroyed
      *p\hull = 0
      *p\shields = 0
      LogLine("BLACK HOLE: your ship was lost!")
      PrintN("The black hole consumes your ship. Ship lost.")
      ProcedureReturn 0
    EndIf
  EndIf

  ProcedureReturn 0
EndProcedure

Procedure ClearSectorMap(mapX.i, mapY.i)
  Protected x.i, y.i
  For y = 0 To #MAP_H - 1
    For x = 0 To #MAP_W - 1
      gGalaxy(mapX, mapY, x, y)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, x, y)\name = ""
      gGalaxy(mapX, mapY, x, y)\richness = 0
      gGalaxy(mapX, mapY, x, y)\enemyLevel = 0
    Next
  Next
EndProcedure

;==============================================================================
; GenerateSectorMap(mapX.i, mapY.i)
; Generates contents for a single sector within a galaxy.
; Parameters:
;   mapX - Galaxy X coordinate (0-3)
;   mapY - Galaxy Y coordinate (0-3)
; 
; Populates the 8x8 sector with random entities based on probability:
;   - Empty space (.)
;   - Stars (*)
;   - Planets (O)
;   - Dilithium asteroids (D) with richness 1-10
;   - Anomalies (A)
;   - Enemy spawns based on player progress/difficulty
;==============================================================================
Procedure GenerateSectorMap(mapX.i, mapY.i)
  ; Deterministic-ish per map for variety
  Protected x.i
  Protected sx.i, sy.i, px.i, py.i, bx.i, by.i, ex.i, ey.i
  ClearSectorMap(mapX, mapY)

  ; SUN (usually near center)
  If Random(99) < 80
    Protected cx.i = #MAP_W / 2
    Protected cy.i = #MAP_H / 2
    Protected triesSun.i
    For triesSun = 1 To 12
      sx = ClampInt(cx + (Random(2) - 1), 0, #MAP_W - 1)
      sy = ClampInt(cy + (Random(2) - 1), 0, #MAP_H - 1)
      If gGalaxy(mapX, mapY, sx, sy)\entType = #ENT_EMPTY
        gGalaxy(mapX, mapY, sx, sy)\entType = #ENT_SUN
        gGalaxy(mapX, mapY, sx, sy)\name = "Sun"
        Break
      EndIf
    Next
  EndIf

  ; Stars (obstacles)
  For x = 1 To 8 + Random(4)
    sx = Random(#MAP_W - 1)
    sy = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, sx, sy)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, sx, sy)\entType = #ENT_STAR
      gGalaxy(mapX, mapY, sx, sy)\name = "Star"
    EndIf
  Next

  ; Planets (mining)
  For x = 1 To 6 + Random(5)
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_PLANET
      gGalaxy(mapX, mapY, px, py)\name = "Planet-" + Str(mapX) + "-" + Str(mapY) + ":" + Str(px) + "-" + Str(py)
      gGalaxy(mapX, mapY, px, py)\richness = 5 + Random(25)
    EndIf
  Next

  ; Starbases (rare)
  If Random(99) < 22
    bx = Random(#MAP_W - 1)
    by = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, bx, by)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, bx, by)\entType = #ENT_BASE
      gGalaxy(mapX, mapY, bx, by)\name = "Starbase-" + Str(mapX) + "-" + Str(mapY)
    EndIf
  EndIf

  ; Shipyards (very rare)
  If Random(99) < 10
    bx = Random(#MAP_W - 1)
    by = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, bx, by)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, bx, by)\entType = #ENT_SHIPYARD
      gGalaxy(mapX, mapY, bx, by)\name = "Shipyard-" + Str(mapX) + "-" + Str(mapY)
    EndIf
  EndIf
  
  ; Refineries (rare)
  If Random(99) < 8
    bx = Random(#MAP_W - 1)
    by = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, bx, by)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, bx, by)\entType = #ENT_REFINERY
      gGalaxy(mapX, mapY, bx, by)\name = "Refinery-" + Str(mapX) + "-" + Str(mapY)
    EndIf
  EndIf

  ; Enemies
  For x = 1 To 4 + Random(6)
    ex = Random(#MAP_W - 1)
    ey = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, ex, ey)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, ex, ey)\entType = #ENT_ENEMY
      gGalaxy(mapX, mapY, ex, ey)\name = "Raider"
      gGalaxy(mapX, mapY, ex, ey)\enemyLevel = 1 + Random(3) + (mapX + mapY) / 6
      If gGalaxy(mapX, mapY, ex, ey)\enemyLevel < 1
        gGalaxy(mapX, mapY, ex, ey)\enemyLevel = 1
      EndIf
    EndIf
  Next

  ; Wormholes (rare)
  If Random(99) < 12
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_WORMHOLE
      gGalaxy(mapX, mapY, px, py)\name = "Wormhole"
    EndIf
  EndIf

  ; Black holes (very rare)
  If Random(99) < 6
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_BLACKHOLE
      gGalaxy(mapX, mapY, px, py)\name = "Black hole"
    EndIf
  EndIf

  ; Dilithium crystals (rare, valuable for power)
  If Random(99) < 8
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_DILITHIUM
      gGalaxy(mapX, mapY, px, py)\name = "Dilithium Cluster"
      gGalaxy(mapX, mapY, px, py)\richness = 3 + Random(8)
    EndIf
  EndIf

  ; Anomalies (rare, random effects)
  If Random(99) < 5
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_ANOMALY
      gGalaxy(mapX, mapY, px, py)\name = "Spatial Anomaly"
    EndIf
  EndIf

  ; Planet Killers (very rare - less than 1% chance)
  If Random(99) < 1
    px = Random(#MAP_W - 1)
    py = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, px, py)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, px, py)\entType = #ENT_PLANETKILLER
      gGalaxy(mapX, mapY, px, py)\name = "Planet Killer"
      gGalaxy(mapX, mapY, px, py)\enemyLevel = 5 + Random(10)  ; very high level
    EndIf
  EndIf
EndProcedure

;==============================================================================
; GenerateGalaxy()
; Creates the entire game universe - all galaxies, sectors, and entities.
; 
; What it generates for each galaxy (4x4 grid):
;   - 8x8 sector grid per galaxy
;   - Random stars (*), planets (O), dilithium (D), anomalies (A)
;   - Starbases (%) at random locations
;   - Shipyards (+) at random locations
;   - Wormholes (#) and black holes (?) in some galaxies
;   - Enemy spawns based on difficulty level
;   - Refineries (R) in random locations
;
; Probability distribution:
;   - Stars: ~15% of sectors
;   - Planets: ~10% of sectors
;   - Dilithium: ~8% of sectors (richness varies)
;   - Anomalies: ~3% of sectors
;   - Starbases: 1-2 per galaxy
;   - Shipyards: 1 per galaxy
;   - Wormholes: 0-2 per galaxy
;   - Black holes: 0-1 per galaxy
;==============================================================================
Procedure GenerateGalaxy()
  Protected mx.i, my.i
  For my = 0 To #GALAXY_H - 1
    For mx = 0 To #GALAXY_W - 1
      GenerateSectorMap(mx, my)
    Next
  Next

  ; Starting map + position
  gMapX = Random(#GALAXY_W - 1)
  gMapY = Random(#GALAXY_H - 1)
  gx = Random(#MAP_W - 1)
  gy = Random(#MAP_H - 1)
  If CurCell(gx, gy)\entType <> #ENT_EMPTY
    gx = 0 : gy = 0
    CurCell(gx, gy)\entType = #ENT_EMPTY
  EndIf
EndProcedure

;==============================================================================
; PrintMap()
; Displays the dual-panel galaxy/sector display.
; 
; Left panel (8x8): Current sector view
;   - Shows entities in current sector
;   - @ = Player, E = Enemy, P = Pirate, O = Planet
;   - * = Star, D = Dilithium, A = Anomaly
;   - % = Starbase, + = Shipyard, R = Refinery
;   - # = Wormhole, ? = Black Hole, S = Sun
;
; Right panel (4x4): Galaxy overview
;   - Shows which galaxies have been visited
;   - X = Current galaxy, M = Mission galaxy
;   - ! = Mission target location
;   - . = Unexplored galaxy
;==============================================================================
Procedure PrintMap()
  Protected x.i, row.i
  Protected maxRows.i = #MAP_H
  If #GALAXY_H > maxRows : maxRows = #GALAXY_H : EndIf

  PrintDivider()
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  Print("Sector ")
  ResetColor()
  Print("(" + Str(gx) + "," + Str(gy) + ")")
  Print("        ")
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  Print("Galaxy ")
  ResetColor()
  PrintN("(" + Str(gMapX) + "," + Str(gMapY) + ") of " + Str(#GALAXY_W) + "x" + Str(#GALAXY_H))

  ; Axis labels
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  Print("   ")
  For x = 0 To #MAP_W - 1
    Print(Str(x) + " ")
  Next
  Print("   ")
  Print("   ")
  For x = 0 To #GALAXY_W - 1
    Print(Str(x) + " ")
  Next
  ResetColor()
  PrintN("")

  For row = 0 To maxRows - 1
    ; Sector map (left)
    If row < #MAP_H
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      Print(" " + Str(row) + " ")
      ResetColor()
      For x = 0 To #MAP_W - 1
        If x = gx And row = gy
          ; Show base/yard symbol if player is docked there
          If CurCell(gx, gy)\entType = #ENT_BASE
            ConsoleColor(#C_CYAN, #C_BLACK)
            Print("% ")
          ElseIf CurCell(gx, gy)\entType = #ENT_SHIPYARD
            ConsoleColor(#C_GREEN, #C_BLACK)
            Print("+ ")
          Else
            ConsoleColor(#C_WHITE, #C_BLACK)
            Print("@ ")
          EndIf
          ResetColor()
        Else
          ; Mission bookmark in this map
          If gMission\type <> #MIS_NONE And gMission\destEntType <> #ENT_EMPTY
            If gMapX = gMission\destMapX And gMapY = gMission\destMapY And x = gMission\destX And row = gMission\destY
              ConsoleColor(#C_YELLOW, #C_BLACK)
              Print("! ")
              ResetColor()
              Continue
            EndIf
          EndIf

          ; Check for pirate ships (show as 'P')
          If CurCell(x, row)\entType = #ENT_PIRATE
            ConsoleColor(#C_LIGHTRED, #C_BLACK)
            Print("P ")
          Else
            SetColorForEnt(CurCell(x, row)\entType)
            Print(EntSymbol(CurCell(x, row)\entType) + " ")
          EndIf
          ResetColor()
        EndIf
      Next
    Else
      Print("   ")
      Print(Space(#MAP_W * 2))
    EndIf

    Print("   ")

    ; Galaxy map (right)
    If row < #GALAXY_H
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      Print(" " + Str(row) + " ")
      ResetColor()
      For x = 0 To #GALAXY_W - 1
        ; Bookmark the mission target map
        If gMission\type <> #MIS_NONE And gMission\destEntType <> #ENT_EMPTY
          If x = gMission\destMapX And row = gMission\destMapY
            If x = gMapX And row = gMapY
              ConsoleColor(#C_YELLOW, #C_BLACK)
              Print("X ")
              ResetColor()
              Continue
            Else
              ConsoleColor(#C_YELLOW, #C_BLACK)
              Print("M ")
              ResetColor()
              Continue
            EndIf
          EndIf
        EndIf

        If x = gMapX And row = gMapY
          ConsoleColor(#C_WHITE, #C_BLACK)
          Print("X ")
          ResetColor()
        Else
          ConsoleColor(#C_DARKGRAY, #C_BLACK)
          Print(". ")
          ResetColor()
        EndIf
      Next
    EndIf

    PrintN("")
  Next

  PrintLegendLine("Legend: ")
  Print("Galaxy: ")
  ConsoleColor(#C_WHITE, #C_BLACK) : Print("X") : ResetColor() : Print("=Current map ")
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("M") : ResetColor() : Print("=Mission map ")
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("!") : ResetColor() : PrintN("=Mission target")
  PrintDivider()
EndProcedure

Procedure ScanGalaxy()
  Protected dx.i, dy.i, nx.i, ny.i
  PrintDivider()
  PrintN("Local Scan:")
  
  ; Show current sector
  If CurCell(gx, gy)\entType <> #ENT_EMPTY
    Print("  CURRENT (")
    Print(Str(gx) + "," + Str(gy) + ") ")
    SetColorForEnt(CurCell(gx, gy)\entType)
    Print(EntSymbol(CurCell(gx, gy)\entType))
    ResetColor()
    PrintN(" " + CurCell(gx, gy)\name)
    
    ; Show anomaly details if on one
    If CurCell(gx, gy)\entType = #ENT_ANOMALY
      Protected anomalyRoll.i = Random(99)
      If anomalyRoll < 40
        PrintN("  Ion storm detected - shields will be reduced when entering")
      ElseIf anomalyRoll < 70
        PrintN("  Radiation detected - crew effectiveness reduced")
      Else
        PrintN("  Readings indicate a stable anomaly")
      EndIf
    EndIf
  EndIf

  ; Mission: survey completes when you scan at the destination planet
  If gMission\active And gMission\type = #MIS_SURVEY
    If gMapX = gMission\destMapX And gMapY = gMission\destMapY And gx = gMission\destX And gy = gMission\destY
      gCredits + gMission\rewardCredits
      LogLine("MISSION COMPLETE: survey (+" + Str(gMission\rewardCredits) + " credits)")
      ClearStructure(@gMission, Mission)
      gMission\type = #MIS_NONE
    EndIf
  EndIf

  For dy = -1 To 1
    For dx = -1 To 1
      If dx = 0 And dy = 0 : Continue : EndIf
      nx = gx + dx
      ny = gy + dy
      If nx >= 0 And nx < #MAP_W And ny >= 0 And ny < #MAP_H
        If CurCell(nx, ny)\entType <> #ENT_EMPTY
          Print("  (" + Str(nx) + "," + Str(ny) + ") ")
          SetColorForEnt(CurCell(nx, ny)\entType)
          Print(EntSymbol(CurCell(nx, ny)\entType))
          ResetColor()
          PrintN(" " + CurCell(nx, ny)\name)
        EndIf
      EndIf
    Next
  Next
  PrintDivider()
EndProcedure

Procedure ScanGalaxyLong()
  Protected dx.i, dy.i, nx.i, ny.i, range.i = 2
  PrintDivider()
  PrintN("Long Range Scan (2 sector range):")
  
  ; Show current sector
  If CurCell(gx, gy)\entType <> #ENT_EMPTY
    Print("  CURRENT (")
    Print(Str(gx) + "," + Str(gy) + ") ")
    SetColorForEnt(CurCell(gx, gy)\entType)
    Print(EntSymbol(CurCell(gx, gy)\entType))
    ResetColor()
    PrintN(" " + CurCell(gx, gy)\name)
  EndIf

  For dy = -range To range
    For dx = -range To range
      If dx = 0 And dy = 0 : Continue : EndIf
      nx = gx + dx
      ny = gy + dy
      If nx >= 0 And nx < #MAP_W And ny >= 0 And ny < #MAP_H
        If CurCell(nx, ny)\entType <> #ENT_EMPTY
          Print("  (" + Str(nx) + "," + Str(ny) + ") ")
          SetColorForEnt(CurCell(nx, ny)\entType)
          Print(EntSymbol(CurCell(nx, ny)\entType))
          ResetColor()
          PrintN(" " + CurCell(nx, ny)\name)
        EndIf
      EndIf
    Next
  Next
  PrintDivider()
EndProcedure

Procedure.s LocText(mapX.i, mapY.i, x.i, y.i)
  ProcedureReturn "Galaxy (" + Str(mapX) + "," + Str(mapY) + ") Sector (" + Str(x) + "," + Str(y) + ")"
EndProcedure

Procedure.i FindRandomCellOfType(entType.i, *outMapX.Integer, *outMapY.Integer, *outX.Integer, *outY.Integer)
  Protected tries.i, mx.i, my.i, x.i, y.i
  For tries = 1 To 2000
    mx = Random(#GALAXY_W - 1)
    my = Random(#GALAXY_H - 1)
    x = Random(#MAP_W - 1)
    y = Random(#MAP_H - 1)
    If gGalaxy(mx, my, x, y)\entType = entType
      *outMapX\i = mx
      *outMapY\i = my
      *outX\i = x
      *outY\i = y
      ProcedureReturn 1
    EndIf
  Next
  ProcedureReturn 0
EndProcedure

;==============================================================================
; GenerateMission(*p.Ship)
; Creates a new random mission for the player to undertake.
; 
; Mission types:
;   - #MIS_NONE: No active mission
;   - #MIS_BOUNTY: Hunt and destroy X enemies
;   - #MIS_ESCORT: Protect a ship to destination
;   - #MIS_DELIVER: Deliver cargo/passengers to destination
;   - #MIS_SCOUT: Explore and scan a specific galaxy
;   - #MIS_PLANETKILLER: Hunt down the Planet Killer ship
;
; Each mission has:
;   - Type and description
;   - Target location (galaxy X/Y, sector X/Y)
;   - Reward credits
;   - Difficulty/threat level
;   - For bounties: number of kills required
;==============================================================================
Procedure GenerateMission(*p.Ship)
  ; Only generate an offer when none exists.
  If gMission\type <> #MIS_NONE
    ProcedureReturn
  EndIf

  ClearStructure(@gMission, Mission)
  gMission\active = 0

  Protected roll.i = Random(99)
  If roll < 18
    ; Defend a shipyard
    Protected mxY.i, myY.i, xY.i, yY.i
    If FindRandomCellOfType(#ENT_SHIPYARD, @mxY, @myY, @xY, @yY) = 0
      ProcedureReturn
    EndIf
    gMission\type = #MIS_DEFEND_YARD
    gMission\title = "Defend Shipyard"
    gMission\destEntType = #ENT_SHIPYARD
    gMission\destMapX = mxY : gMission\destMapY = myY : gMission\destX = xY : gMission\destY = yY
    gMission\destName = gGalaxy(mxY, myY, xY, yY)\name
    gMission\turnsLeft = 16 + Random(8)
    gMission\yardHP = 6
    gMission\threatLevel = 1 + Random(3) + (mxY + myY) / 6
    gMission\rewardCredits = 220 + gMission\threatLevel * 120
    gMission\desc = "Proceed to " + gMission\destName + " at " + LocText(mxY, myY, xY, yY) + " and DOCK to hold the line for " + Str(gMission\turnsLeft) + " turns."

  ElseIf roll < 56
    ; Deliver ore to a starbase
    Protected mx.i, my.i, x.i, y.i
    If FindRandomCellOfType(#ENT_BASE, @mx, @my, @x, @y) = 0
      ProcedureReturn
    EndIf
    gMission\type = #MIS_DELIVER_ORE
    gMission\title = "Freight Contract"
    gMission\oreRequired = 10 + Random(25)
    gMission\destEntType = #ENT_BASE
    gMission\destMapX = mx : gMission\destMapY = my : gMission\destX = x : gMission\destY = y
    gMission\destName = gGalaxy(mx, my, x, y)\name
    gMission\rewardCredits = 40 + gMission\oreRequired * 6
    gMission\desc = "Deliver " + Str(gMission\oreRequired) + " ore to " + gMission\destName + " at " + LocText(mx, my, x, y)
  ElseIf roll < 88
    ; Bounty
    gMission\type = #MIS_BOUNTY
    gMission\title = "Bounty"
    gMission\killsRequired = 2 + Random(4)
    gMission\killsDone = 0
    gMission\rewardCredits = 120 + gMission\killsRequired * 80
    gMission\desc = "Destroy " + Str(gMission\killsRequired) + " enemy ships (E)."
    ; No fixed location for bounty missions
    gMission\destMapX = -1 : gMission\destMapY = -1 : gMission\destX = -1 : gMission\destY = -1
    gMission\destEntType = #ENT_EMPTY
    gMission\destName = ""
  ElseIf roll < 96
    ; Survey a planet
    Protected mx2.i, my2.i, x2.i, y2.i
    If FindRandomCellOfType(#ENT_PLANET, @mx2, @my2, @x2, @y2) = 0
      ProcedureReturn
    EndIf
    gMission\type = #MIS_SURVEY
    gMission\title = "Survey"
    gMission\destEntType = #ENT_PLANET
    gMission\destMapX = mx2 : gMission\destMapY = my2 : gMission\destX = x2 : gMission\destY = y2
    gMission\destName = gGalaxy(mx2, my2, x2, y2)\name
    gMission\rewardCredits = 160 + Random(120)
    gMission\desc = "Travel to " + gMission\destName + " at " + LocText(mx2, my2, x2, y2) + " and perform a scan (SCAN)."
  Else
    ; Hunt a Planet Killer (rare mission)
    Protected mxPK.i, myPK.i, xPK.i, yPK.i
    If FindRandomCellOfType(#ENT_PLANETKILLER, @mxPK, @myPK, @xPK, @yPK) = 0
      ProcedureReturn
    EndIf
    gMission\type = #MIS_PLANETKILLER
    gMission\title = "Hunt Planet Killer"
    gMission\destEntType = #ENT_PLANETKILLER
    gMission\destMapX = mxPK : gMission\destMapY = myPK : gMission\destX = xPK : gMission\destY = yPK
    gMission\destName = gGalaxy(mxPK, myPK, xPK, yPK)\name
    gMission\rewardCredits = 800 + Random(600)
    gMission\desc = "Locate and destroy the Planet Killer at " + LocText(mxPK, myPK, xPK, yPK) + ". Warning: extremely dangerous!"
  EndIf

EndProcedure

Procedure PrintMission(*p.Ship)
  PrintDivider()
  PrintN("Missions")
  If gMission\type = #MIS_NONE
    PrintN("  No mission offer available.")
  ElseIf gMission\active = 0
    PrintN("  Offer: " + gMission\title)
    PrintN("  " + gMission\desc)
    If gMission\destEntType <> #ENT_EMPTY
      PrintN("  Location: " + LocText(gMission\destMapX, gMission\destMapY, gMission\destX, gMission\destY))
      PrintN("  From you: dGalaxy=(" + Str(gMission\destMapX - gMapX) + "," + Str(gMission\destMapY - gMapY) + ") dSector=(" + Str(gMission\destX - gx) + "," + Str(gMission\destY - gy) + ")")
      PrintN("  Bookmark: MAP shows M/! markers")
    EndIf
    PrintN("  Reward: " + Str(gMission\rewardCredits) + " credits")
    PrintN("  Type ACCEPT to take it")
  Else
    PrintN("  Active: " + gMission\title)
    PrintN("  " + gMission\desc)
    If gMission\destEntType <> #ENT_EMPTY
      PrintN("  Location: " + LocText(gMission\destMapX, gMission\destMapY, gMission\destX, gMission\destY))
      PrintN("  From you: dGalaxy=(" + Str(gMission\destMapX - gMapX) + "," + Str(gMission\destMapY - gMapY) + ") dSector=(" + Str(gMission\destX - gx) + "," + Str(gMission\destY - gy) + ")")
      PrintN("  Bookmark: MAP shows M/! markers")
    EndIf
    If gMission\type = #MIS_BOUNTY
      PrintN("  Progress: " + Str(gMission\killsDone) + "/" + Str(gMission\killsRequired))
    ElseIf gMission\type = #MIS_DELIVER_ORE
      PrintN("  Cargo: need " + Str(gMission\oreRequired) + " ore; you have " + Str(*p\ore))
    ElseIf gMission\type = #MIS_DEFEND_YARD
      PrintN("  Defend: " + gMission\destName + "  Turns left: " + Str(gMission\turnsLeft) + "  Yard HP: " + Str(gMission\yardHP))
    ElseIf gMission\type = #MIS_PLANETKILLER
      ConsoleColor(#C_CYAN, #C_BLACK)
      PrintN("  TARGET: " + gMission\destName + " at " + LocText(gMission\destMapX, gMission\destMapY, gMission\destX, gMission\destY))
      ResetColor()
    EndIf
  EndIf
  PrintDivider()
EndProcedure

Procedure AcceptMission(*p.Ship)
  If gMission\type = #MIS_NONE
    LogLine("MISSIONS: no offer")
    ProcedureReturn
  EndIf
  If gMission\active
    LogLine("MISSIONS: already active")
    ProcedureReturn
  EndIf
  gMission\active = 1
  LogLine("MISSION ACCEPTED: " + gMission\title)

  ; Offer autopilot convenience immediately after accepting.
  If gMission\destEntType <> #ENT_EMPTY
    PrintN("Autopilot available: type COMPUTER to navigate to the mission destination.")
  EndIf
EndProcedure

Procedure.i IsDangerousCell(mapX.i, mapY.i, x.i, y.i)
  If mapX < 0 Or mapX >= #GALAXY_W Or mapY < 0 Or mapY >= #GALAXY_H : ProcedureReturn 1 : EndIf
  If x < 0 Or x >= #MAP_W Or y < 0 Or y >= #MAP_H : ProcedureReturn 1 : EndIf
  Select gGalaxy(mapX, mapY, x, y)\entType
    Case #ENT_STAR, #ENT_SUN
      ProcedureReturn 1
    Case #ENT_BLACKHOLE
      ; Very risky; autopilot tries to route around unless explicitly allowed.
      ProcedureReturn 1
  EndSelect
  ProcedureReturn 0
EndProcedure

; Computes next coordinate for a direction with galaxy-edge wrapping rules (like NAV does).
; Returns 1 if step is valid; 0 if galaxy edge blocks it.
Procedure.i StepCoord(mapX.i, mapY.i, x.i, y.i, dir.s, *outMapX.Integer, *outMapY.Integer, *outX.Integer, *outY.Integer)
  Protected nx.i = x
  Protected ny.i = y
  Protected mx.i = mapX
  Protected my.i = mapY

  Select dir
    Case "n" : ny - 1
    Case "s" : ny + 1
    Case "w" : nx - 1
    Case "e" : nx + 1
    Default
      ProcedureReturn 0
  EndSelect

  ; Wrap across sector edges into neighboring galaxy maps
  If nx < 0
    If mx > 0
      mx - 1
      nx = #MAP_W - 1
    Else
      ProcedureReturn 0
    EndIf
  ElseIf nx >= #MAP_W
    If mx < #GALAXY_W - 1
      mx + 1
      nx = 0
    Else
      ProcedureReturn 0
    EndIf
  EndIf

  If ny < 0
    If my > 0
      my - 1
      ny = #MAP_H - 1
    Else
      ProcedureReturn 0
    EndIf
  ElseIf ny >= #MAP_H
    If my < #GALAXY_H - 1
      my + 1
      ny = 0
    Else
      ProcedureReturn 0
    EndIf
  EndIf

  *outMapX\i = mx
  *outMapY\i = my
  *outX\i = nx
  *outY\i = ny
  ProcedureReturn 1
EndProcedure

; Very small BFS pathfinder across the whole galaxy grid.
; Returns a string of directions (n/s/e/w) or "" if no safe path.
Procedure.s FindPathMission(startMapX.i, startMapY.i, startX.i, startY.i, destMapX.i, destMapY.i, destX.i, destY.i, allowWormhole.i, allowBlackhole.i, allowEnemy.i)
  Protected total.i = #GALAXY_W * #GALAXY_H * #MAP_W * #MAP_H
  If total <= 0 : ProcedureReturn "" : EndIf

  Protected startIdx.i = (((startMapY * #GALAXY_W) + startMapX) * #MAP_H + startY) * #MAP_W + startX
  Protected destIdx.i  = (((destMapY * #GALAXY_W) + destMapX) * #MAP_H + destY) * #MAP_W + destX
  If startIdx = destIdx : ProcedureReturn "" : EndIf

  Protected Dim prev.i(total - 1)
  Protected Dim prevDir.b(total - 1)
  Protected Dim q.i(total - 1)
  Protected i.i
  For i = 0 To total - 1
    prev(i) = -2
    prevDir(i) = 0
  Next

  Protected head.i = 0, tail.i = 0
  q(tail) = startIdx : tail + 1
  prev(startIdx) = -1

  Protected dirs.s = "nsew"
  Protected found.i = 0
  While head < tail
    Protected cur.i = q(head) : head + 1
    If cur = destIdx : found = 1 : Break : EndIf

    Protected tmp.i = cur
    Protected cx.i = tmp % #MAP_W : tmp / #MAP_W
    Protected cy.i = tmp % #MAP_H : tmp / #MAP_H
    Protected cm.i = tmp % (#GALAXY_W * #GALAXY_H)
    Protected cmx.i = cm % #GALAXY_W
    Protected cmy.i = cm / #GALAXY_W

    Protected di.i
    For di = 1 To 4
      Protected d.s = Mid(dirs, di, 1)
      Protected nmx.Integer, nmy.Integer, nx.Integer, ny.Integer
      If StepCoord(cmx, cmy, cx, cy, d, @nmx, @nmy, @nx, @ny) = 0
        Continue
      EndIf

      ; Blocked hazards/obstacles
      Protected ent.i = gGalaxy(nmx\i, nmy\i, nx\i, ny\i)\entType
      If ent = #ENT_STAR Or ent = #ENT_SUN
        Continue
      EndIf
      If ent = #ENT_BLACKHOLE And allowBlackhole = 0
        Continue
      EndIf
      If ent = #ENT_WORMHOLE And allowWormhole = 0
        Continue
      EndIf
      If ent = #ENT_ENEMY And allowEnemy = 0
        Continue
      EndIf

      Protected nid.i = (((nmy\i * #GALAXY_W) + nmx\i) * #MAP_H + ny\i) * #MAP_W + nx\i
      If prev(nid) <> -2
        Continue
      EndIf
      prev(nid) = cur
      prevDir(nid) = Asc(d)
      q(tail) = nid : tail + 1
      If tail >= total
        ; Should not happen, but avoid overruns
        Break
      EndIf
    Next
  Wend

  If found = 0
    ProcedureReturn ""
  EndIf

  ; Reconstruct path
  Protected path.s = ""
  Protected at.i = destIdx
  While at <> startIdx And at >= 0
    path = Chr(prevDir(at)) + path
    at = prev(at)
  Wend
  ProcedureReturn path
EndProcedure

Procedure AbandonMission()
  If gMission\active = 0
    LogLine("MISSION: none active")
    ProcedureReturn
  EndIf
  ClearStructure(@gMission, Mission)
  gMission\type = #MIS_NONE
  LogLine("MISSION ABANDONED!")
EndProcedure

Procedure CheckMissionCompletion(*p.Ship)
  If gMission\active = 0
    ProcedureReturn
  EndIf

  Select gMission\type
    Case #MIS_DELIVER_ORE
      ; Completion is handled at starbase delivery
    Case #MIS_SURVEY
      ; Completion is handled via SCAN at destination
    Case #MIS_DEFEND_YARD
      ; Completion handled by DefendMissionTick()
  EndSelect
EndProcedure

Procedure DefendMissionTick(*p.Ship, *enemyTemplate.Ship, *enemy.Ship, *cs.CombatState)
  If gMission\active = 0 Or gMission\type <> #MIS_DEFEND_YARD
    ProcedureReturn
  EndIf

  ; Fail if yard is gone (by mission state)
  If gMission\yardHP <= 0
    PrintDivider()
    PrintN("Mission failed: shipyard destroyed.")
    PrintDivider()
    LogLine("MISSION FAILED: shipyard destroyed!")
    ClearStructure(@gMission, Mission)
    gMission\type = #MIS_NONE
    ProcedureReturn
  EndIf

  ; Only tick down while player is physically at the yard
  If gMode <> #MODE_GALAXY : ProcedureReturn : EndIf
  If CurCell(gx, gy)\entType <> #ENT_SHIPYARD : ProcedureReturn : EndIf
  If gMapX <> gMission\destMapX Or gMapY <> gMission\destMapY Or gx <> gMission\destX Or gy <> gMission\destY
    ProcedureReturn
  EndIf

  gMission\turnsLeft - 1

  ; Chance of attack each turn while defending
  Protected attackChance.i = ClampInt(35 + gMission\threatLevel * 8, 35, 70)
  If Random(99) < attackChance
    LogLine("ALERT: shipyard under attack!")
    ; Spawn an enemy encounter
    CopyStructure(*enemyTemplate, *enemy, Ship)
    *enemy\sysEngines = #SYS_OK
    *enemy\sysWeapons = #SYS_OK
    *enemy\sysShields = #SYS_OK
    *enemy\sysTractor = #SYS_OK

    Protected lvl.i = ClampInt(gMission\threatLevel, 1, 10)
    ; Ensure valid enemy stats
    If *enemy\name = "" Or *enemy\hullMax <= 0
      *enemy\name = "Raider"
      *enemy\class = "Raider"
      *enemy\hullMax = 100
      *enemy\hull = 100
      *enemy\shieldsMax = 90
      *enemy\shields = 90
      *enemy\weaponCapMax = 210
      *enemy\weaponCap = 105
      *enemy\phaserBanks = 6
      *enemy\torpTubes = 2
      *enemy\torpMax = 8
      *enemy\torp = 8
    EndIf
    *enemy\hullMax = *enemy\hullMax + (lvl * 10)
    *enemy\hull = *enemy\hullMax
    *enemy\shieldsMax = *enemy\shieldsMax + (lvl * 12)
    *enemy\shields = *enemy\shieldsMax
    *enemy\weaponCapMax = *enemy\weaponCapMax + (lvl * 20)
    *enemy\weaponCap = *enemy\weaponCapMax / 2
    *enemy\torp = *enemy\torpMax

    EnterCombat(*p, *enemy, *cs)
    ProcedureReturn
  EndIf

  ; Yard takes attrition sometimes even without direct combat
  If Random(99) < ClampInt(10 + gMission\threatLevel * 4, 10, 35)
    gMission\yardHP - 1
    If gMission\yardHP < 0 : gMission\yardHP = 0 : EndIf
    LogLine("YARD HIT: hp=" + Str(gMission\yardHP))
  EndIf

  If gMission\turnsLeft <= 0
    gCredits + gMission\rewardCredits
    PrintDivider()
    PrintN("Mission complete: shipyard secured ( +" + Str(gMission\rewardCredits) + " credits )")
    PrintDivider()
    LogLine("MISSION COMPLETE: defend shipyard (+" + Str(gMission\rewardCredits) + " credits)")
    ClearStructure(@gMission, Mission)
    gMission\type = #MIS_NONE
  EndIf
EndProcedure

Procedure DeliverMission(*p.Ship)
  If gMission\active = 0 : ProcedureReturn : EndIf
  If gMission\type <> #MIS_DELIVER_ORE : ProcedureReturn : EndIf

  If CurCell(gx, gy)\entType <> #ENT_BASE
    PrintN("You must be at a starbase to deliver.")
    ProcedureReturn
  EndIf

  If gMapX <> gMission\destMapX Or gMapY <> gMission\destMapY Or gx <> gMission\destX Or gy <> gMission\destY
    ProcedureReturn
  EndIf

  If *p\ore < gMission\oreRequired
    PrintN("Insufficient ore to deliver.")
    ProcedureReturn
  EndIf

  *p\ore - gMission\oreRequired
  gCredits + gMission\rewardCredits
  LogLine("MISSION COMPLETE: delivered ore (+" + Str(gMission\rewardCredits) + " credits)")
  ClearStructure(@gMission, Mission)
  gMission\type = #MIS_NONE
EndProcedure

;==============================================================================
; DockAtBase(*p.Ship)
; Docks player ship at a starbase for repairs and supplies.
; 
; What happens when docked:
;   - Full hull and shield repair (free)
;   - Refuel ship (costs credits based on amount)
;   - Repair ship systems (costs credits)
;   - Access to shipyard for upgrades
;   - Can add/remove fleet ships
;   - Ship automatically stops moving (engine loop stops)
;==============================================================================
Procedure DockAtBase(*p.Ship)
  If CurCell(gx, gy)\entType <> #ENT_BASE
    PrintN("No starbase in this sector.")
    ProcedureReturn
  EndIf
  
  If gDocked
    PrintN("You are already docked.")
    ProcedureReturn
  EndIf
  
  gDocked = 1
  StopEngineLoop()
  
  Protected dockCmd.s = TrimLower(TokenAt(gLastCmdLine, 1))
  If dockCmd = "poweroverwhelming"
    gPowerBuff = 1
    gPowerBuffTurns = 30
    *p\hullMax = *p\hullMax * 2.0
    *p\shieldsMax = *p\shieldsMax * 2.0
    *p\reactorMax = *p\reactorMax * 2.0
    *p\weaponCapMax = *p\weaponCapMax * 2.0
    *p\warpMax = *p\warpMax * 2.0
    *p\impulseMax = *p\impulseMax * 2.0
    *p\phaserBanks = *p\phaserBanks + 1
    *p\torpTubes = *p\torpTubes + 1
    *p\torpMax = *p\torpMax * 2.0
    *p\sensorRange = *p\sensorRange + 5
    *p\fuelMax = *p\fuelMax * 2.0
    *p\oreMax = *p\oreMax * 2.0
    *p\dilithiumMax = *p\dilithiumMax * 2.0
    *p\hull = *p\hullMax
    *p\shields = *p\shieldsMax
    *p\weaponCap = *p\weaponCapMax
    *p\torp = *p\torpMax
    *p\fuel = *p\fuelMax
    LogLine("CHEAT: poweroverwhelming (buff active)")
    PrintN("Cheat activated: POWER OVERWHELMING! All systems doubled!")
    PrintN("Buff will last for 30 turns or until death.")
    ProcedureReturn
  EndIf
  
  PrintN("Starbase services: hull repaired, shields restored,")
  PrintN("weapons rearmed, fuel & probes refilled.")
  PlayDockingSound()
  PrintN("")
  PrintN("CHEATS:")
  PrintN("  poweroverwhelming = all stats x2 for 30 turns")
  PrintN("")
  
  ; Show available recruits
  PrintN("Recruits available:")
  Protected i.i
  For i = 0 To gRecruitCount - 1
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
    Print("  [" + Str(i + 1) + "] ")
    ResetColor()
    Print(gRecruitNames(i) + " - " + gRecruitRoles(i))
    PrintN("")
  Next
  PrintN("Commands: RECRUIT <1-3> to hire | DISMISS <HELM|WEAPONS|SHIELDS|ENGINEERING> to fire")
  PrintN("")
  
  *p\hull = *p\hullMax
  *p\shields = *p\shieldsMax
  *p\weaponCap = *p\weaponCapMax
  *p\torp = *p\torpMax
  *p\fuel = *p\fuelMax
  *p\probes = *p\probesMax
  *p\sysEngines = #SYS_OK
  *p\sysWeapons = #SYS_OK
  *p\sysShields = #SYS_OK
  LogLine("DOCK: refueled, rearmed, repaired, probes restocked")

  ; Mission delivery happens at starbases
  DeliverMission(*p)
EndProcedure

Procedure MinePlanet(*p.Ship)
  If CurCell(gx, gy)\entType = #ENT_PLANET Or CurCell(gx, gy)\entType = #ENT_DILITHIUM
    Protected mineCmd.s = TrimLower(TokenAt(gLastCmdLine, 2))
    If mineCmd = "miner2049er"
      Protected fillOre.i = *p\oreMax - *p\ore
      Protected fillDil.i = *p\dilithiumMax - *p\dilithium
      *p\ore = *p\oreMax
      *p\dilithium = *p\dilithiumMax
      LogLine("CHEAT: miner2049er (filled cargo)")
      PrintN("Cheat activated: Cargo hold filled!")
      ProcedureReturn
    EndIf
  EndIf
  
  If CurCell(gx, gy)\entType = #ENT_PLANET
    If *p\fuel < 2
      PrintN("Insufficient fuel for mining operations.")
      ProcedureReturn
    EndIf
    If *p\ore >= *p\oreMax
      PrintN("Ore holds are full.")
      ProcedureReturn
    EndIf

    Protected rmax.i = CurCell(gx, gy)\richness
    If rmax < 0 : rmax = 0 : EndIf
    Protected pull.i = 1 + Random(rmax)
    pull = ClampInt(pull, 1, 20)
    Protected space.i = *p\oreMax - *p\ore
    If pull > space : pull = space : EndIf
    *p\ore + pull
    *p\fuel - 2
    PlayMiningSound()
    LogLine("MINE: +" + Str(pull) + " ore")
    PrintN("Mined " + Str(pull) + " ore.")
  ElseIf CurCell(gx, gy)\entType = #ENT_DILITHIUM
    If *p\fuel < 2
      PrintN("Insufficient fuel for mining operations.")
      ProcedureReturn
    EndIf
    If *p\dilithium >= *p\dilithiumMax
      PrintN("Dilithium holds are full.")
      ProcedureReturn
    EndIf

    Protected drmax.i = CurCell(gx, gy)\richness
    If drmax < 0 : drmax = 0 : EndIf
    Protected dpull.i = 1 + Random(drmax)
    dpull = ClampInt(dpull, 1, 8)
    Protected dspace.i = *p\dilithiumMax - *p\dilithium
    If dpull > dspace : dpull = dspace : EndIf
    *p\dilithium + dpull
    *p\fuel - 2
    PlayMiningSound()
    LogLine("MINE: +" + Str(dpull) + " dilithium")
    PrintN("Mined " + Str(dpull) + " dilithium crystals.")
  Else
    PrintN("No mineable resource in this sector (need Planet O or Dilithium D).")
  EndIf
EndProcedure

Procedure PrintProbeScan(mapX.i, mapY.i)
  PrintN("")
  PrintN("=== PROBE SCAN: Galaxy (" + Str(mapX) + "," + Str(mapY) + ") ===")
  Protected x.i, y.i
  Protected hasContent.i = 0
  
  For y = 0 To #MAP_H - 1
    Protected line.s = "  "
    For x = 0 To #MAP_W - 1
      Protected ent.i = gGalaxy(mapX, mapY, x, y)\entType
      Select ent
        Case #ENT_EMPTY
          line + ". "
        Case #ENT_PLANET
          line + "O "
        Case #ENT_STAR
          line + "* "
        Case #ENT_BASE
          line + "% "
        Case #ENT_SHIPYARD
          line + "+ "
        Case #ENT_ENEMY
          line + "E "
        Case #ENT_WORMHOLE
          line + "# "
        Case #ENT_BLACKHOLE
          line + "? "
        Case #ENT_SUN
          line + "S "
        Case #ENT_DILITHIUM
          line + "D "
        Case #ENT_ANOMALY
          line + "A "
        Case #ENT_PLANETKILLER
          line + "< "
        Case #ENT_REFINERY
          line + "R "
        Default
          line + ". "
      EndSelect
    Next
    PrintN(line)
  Next
  
  PrintN("Legend: @=YourShip")
  PrintN("        .=EmptySector O=Planet *=Star (blocked) %=Starbase +=Shipyard")
  PrintN("        E=EnemyShip P=PirateShip #=Wormhole ?=Blackhole S=Sun (blocked)")
  PrintN("        D=Dilithium A=Anomaly <=Planet Killer R=Refinery")
  PrintN("")
EndProcedure

Procedure TransporterBeam(*p.Ship, mode.s)
  If CurCell(gx, gy)\entType <> #ENT_PLANET And CurCell(gx, gy)\entType <> #ENT_DILITHIUM
    PrintN("No planet or dilithium cluster in this sector.")
    ProcedureReturn
  EndIf
  
  Protected oreToTrans.i = 0
  Protected dilToTrans.i = 0
  
  If mode = "ore" Or mode = "all"
    oreToTrans = CurCell(gx, gy)\ore
    If oreToTrans > 0
      Protected oreSpace.i = *p\oreMax - *p\ore
      If oreToTrans > oreSpace : oreToTrans = oreSpace : EndIf
      *p\ore + oreToTrans
      CurCell(gx, gy)\ore - oreToTrans
      PrintN("Transporter: +" + Str(oreToTrans) + " ore beamed to cargo.")
      LogLine("TRANSPORTER: +" + Str(oreToTrans) + " ore")
    Else
      PrintN("No ore remaining on this planet.")
    EndIf
  EndIf
  
  If mode = "dilithium" Or mode = "all"
    dilToTrans = CurCell(gx, gy)\dilithium
    If dilToTrans > 0
      Protected dilSpace.i = *p\dilithiumMax - *p\dilithium
      If dilToTrans > dilSpace : dilToTrans = dilSpace : EndIf
      *p\dilithium + dilToTrans
      CurCell(gx, gy)\dilithium - dilToTrans
      PrintN("Transporter: +" + Str(dilToTrans) + " dilithium beamed to cargo.")
      LogLine("TRANSPORTER: +" + Str(dilToTrans) + " dilithium")
    Else
      PrintN("No dilithium remaining on this cluster.")
    EndIf
  EndIf
  
  If oreToTrans = 0 And dilToTrans = 0
    PrintN("No resources to beam up.")
  EndIf
EndProcedure

Procedure ShuttleMine()
  If gShuttleLaunched = 0
    PrintN("Shuttle is not launched.")
    ProcedureReturn
  EndIf
  
  If CurCell(gx, gy)\entType <> #ENT_PLANET And CurCell(gx, gy)\entType <> #ENT_DILITHIUM
    PrintN("No planet or dilithium cluster in this sector.")
    ProcedureReturn
  EndIf
  
  Protected shuttleSpace.i = gShuttleMaxCargo - (gShuttleCargoOre + gShuttleCargoDilithium)
  If shuttleSpace <= 0
    PrintN("Shuttle cargo full!")
    ProcedureReturn
  EndIf
  
  Protected oreCollect.i = 0
  Protected dilCollect.i = 0
  
  If CurCell(gx, gy)\entType = #ENT_PLANET
    oreCollect = CurCell(gx, gy)\ore
    If oreCollect > shuttleSpace
      oreCollect = shuttleSpace
    EndIf
    If oreCollect > 0
      gShuttleCargoOre + oreCollect
      CurCell(gx, gy)\ore - oreCollect
      PrintN("Shuttle collected " + Str(oreCollect) + " ore!")
    Else
      PrintN("No ore on this planet.")
    EndIf
  EndIf
  
  If CurCell(gx, gy)\entType = #ENT_DILITHIUM
    shuttleSpace = gShuttleMaxCargo - (gShuttleCargoOre + gShuttleCargoDilithium)
    dilCollect = CurCell(gx, gy)\dilithium
    If dilCollect > shuttleSpace
      dilCollect = shuttleSpace
    EndIf
    If dilCollect > 0
      gShuttleCargoDilithium + dilCollect
      CurCell(gx, gy)\dilithium - dilCollect
      PrintN("Shuttle collected " + Str(dilCollect) + " dilithium!")
    Else
      PrintN("No dilithium in this cluster.")
    EndIf
  EndIf
  
  If oreCollect = 0 And dilCollect = 0
    PrintN("No resources collected.")
  Else
    AddCaptainLog("SHUTTLE: collected " + Str(oreCollect) + " ore, " + Str(dilCollect) + " dilithium")
  EndIf
EndProcedure

;==============================================================================
; DockAtShipyard(*p.Ship, *base.Ship)
; Docks player ship at a shipyard for upgrades and repairs.
; 
; Shipyard services:
;   - Repair hull: 1 credit per 2 hull points
;   - Upgrade hull: +10-50 max hull (costs credits based on amount)
;   - Upgrade shields: +10-40 max shields
;   - Upgrade weapons: +20-50 max weapon capacity
;   - Upgrade propulsion: +fuel efficiency
;   - Upgrade power/cargo: +cargo capacity
;   - Upgrade probes: +probe capacity and range
;   - Build/upgrade shuttle: Enable or improve shuttle
;
; Each upgrade has a base cost and is tracked in gUpgrade* variables.
;==============================================================================
Procedure DockAtShipyard(*p.Ship, *base.Ship)
  If CurCell(gx, gy)\entType <> #ENT_SHIPYARD
    PrintN("No shipyard in this sector.")
    ProcedureReturn
  EndIf
  
  If gDocked
    PrintN("You are already docked.")
    ProcedureReturn
  EndIf
  
  gDocked = 1

  ; Same baseline services as a starbase
  *p\hull = *p\hullMax
  *p\shields = *p\shieldsMax
  *p\weaponCap = *p\weaponCapMax
  *p\fuel = *p\fuelMax
  *p\sysEngines = #SYS_OK
  *p\sysWeapons = #SYS_OK
  *p\sysShields = #SYS_OK
  LogLine("DOCK: shipyard services")

  ; Upgrade menu
  While #True
    PrintDivider()
    PrintN("Shipyard: " + CurCell(gx, gy)\name)
    PrintN("Credits: " + Str(gCredits))
    PrintN("")
    PrintN("HULL & STRUCTURE:")
    PrintN("1) Reinforced Hull  (+20 HullMax)     cost 120")
    PrintN("2) Ablative Armor   (+15 HullMax)     cost 100")
    PrintN("")
    PrintN("SHIELDS:")
    PrintN("3) Shield Grid      (+20 ShieldsMax)  cost 140")
    PrintN("4) Shield Emitters  (+15 ShieldsMax)  cost 110")
    PrintN("")
    PrintN("WEAPONS:")
    PrintN("5) Phaser Banks     (+1 PhaserBanks)  cost 160")
    PrintN("6) Torpedo Racks    (+4 TorpMax)      cost 110")
    PrintN("7) Torpedo Tubes    (+1 TorpTubes)    cost 200")
    PrintN("8) Targeting Matrix (+5 SensorRange)  cost 130")
    PrintN("")
    PrintN("PROPULSION:")
    PrintN("9) Warp Core        (+1.0 WarpMax)    cost 250")
    PrintN("A) Impulse Engines  (+0.3 ImpulseMax) cost 150")
    PrintN("B) Fuel Tanks       (+25 FuelMax)     cost 100")
    PrintN("")
    PrintN("POWER & CARGO:")
    PrintN("C) Reactor Upgrade (+30 ReactorMax)   cost 180")
    PrintN("D) Dilithium Bay   (+10 Di-lithiumMax) cost 90")
    PrintN("E) Cargo Hold      (+20 OreMax)        cost 80")
    PrintN("")
    PrintN("PROBES:")
    PrintN("F) Probe Bay        (+2 ProbesMax)      cost 60")
    PrintN("G) Probe Scanner    (+1 Probe Range)    cost 100")
    PrintN("H) Probe Targeting  (5% Probe Accuracy) cost 120")
    PrintN("")
    PrintN("SHUTTLE:")
    PrintN("I) Shuttle Bay      (+10 Cargo Max)     cost 120")
    PrintN("J) Shuttle Crew 1    (+2 Crew Max)      cost 150")
    PrintN("K) Shuttle Crew 2    (+2 Crew Max)      cost 300")    
    PrintN("L) Shuttle Attack   (+1 Attack Range)   cost 200")
    PrintN("")
    PrintN("0) Leave")
    PrintN("")
    PrintN("CHEATS (type number/letter or word):")
    PrintN("  showmethemoney = +500 credits")
    PrintN("  poweroverwhelming = all stats x2 for 30 turns")
    Print("")
    Print("YARD> ")
    ConsoleColor(#C_WHITE, #C_BLACK)
    Protected choice.s = TrimLower(Input())
    If choice = "0" Or choice = "leave" Or choice = "exit" Or choice = "undock"
      gDocked = 0
      ; Find an empty adjacent spot to undock to
      Protected yardFoundEmpty.i = 0
      Protected yardDx.i, yardDy.i
      For yardDy = -1 To 1
        For yardDx = -1 To 1
          If yardDx = 0 And yardDy = 0 : Continue : EndIf
          Protected ynx.i = gx + yardDx
          Protected yny.i = gy + yardDy
          If ynx >= 0 And ynx < #MAP_W And yny >= 0 And yny < #MAP_H
            If gGalaxy(gMapX, gMapY, ynx, yny)\entType = #ENT_EMPTY
              gx = ynx
              gy = yny
              yardFoundEmpty = 1
              Break 2
            EndIf
          EndIf
        Next
      Next
      PrintN("Undocking...")
      StartEngineLoop()
      Break
    EndIf
    If choice = "showmethemoney"
      gCredits + 500
      LogLine("CHEAT: showmethemoney (+500 credits)")
      PrintN("Cheat activated: +500 credits!")
      Continue
    EndIf
    If choice = "poweroverwhelming"
      gPowerBuff = 1
      gPowerBuffTurns = 30
      *p\hullMax = *p\hullMax * 2.0
      *p\shieldsMax = *p\shieldsMax * 2.0
      *p\reactorMax = *p\reactorMax * 2.0
      *p\weaponCapMax = *p\weaponCapMax * 2.0
      *p\warpMax = *p\warpMax * 2.0
      *p\impulseMax = *p\impulseMax * 2.0
      *p\phaserBanks = *p\phaserBanks + 1
      *p\torpTubes = *p\torpTubes + 1
      *p\torpMax = *p\torpMax * 2.0
      *p\sensorRange = *p\sensorRange + 5
      *p\fuelMax = *p\fuelMax * 2.0
      *p\oreMax = *p\oreMax * 2.0
      *p\dilithiumMax = *p\dilithiumMax * 2.0
      *p\hull = *p\hullMax
      *p\shields = *p\shieldsMax
      *p\weaponCap = *p\weaponCapMax
      *p\torp = *p\torpMax
      *p\fuel = *p\fuelMax
      LogLine("CHEAT: poweroverwhelming (buff active)")
      PrintN("Cheat activated: POWER OVERWHELMING! all systems doubled!")
      PrintN("Buff will last for 30 turns or until death.")
      Continue
    EndIf

    Protected cost.i = 0
    Select choice
      Case "1"
        cost = 120
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\hullMax = ClampInt(*p\hullMax + 20, 10, 800)
        *p\hull = *p\hullMax
        gUpgradeHull + 1
        LogLine("UPGRADE: hull +20 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: hull upgrade +20")
        PrintN("Upgrade installed.")
      Case "2"
        cost = 100
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\hullMax = ClampInt(*p\hullMax + 15, 10, 800)
        *p\hull = *p\hullMax
        gUpgradeHull + 1
        LogLine("UPGRADE: armor +15 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: armor upgrade +15")
        PrintN("Upgrade installed.")
      Case "3"
        cost = 140
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\shieldsMax = ClampInt(*p\shieldsMax + 20, 0, 800)
        *p\shields = *p\shieldsMax
        gUpgradeShields + 1
        LogLine("UPGRADE: shields +20 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: shields upgrade +20")
      Case "4"
        cost = 110
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\shieldsMax = ClampInt(*p\shieldsMax + 15, 0, 800)
        *p\shields = *p\shieldsMax
        gUpgradeShields + 1
        LogLine("UPGRADE: emitters +15 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: emitters upgrade +15")
      Case "5"
        cost = 160
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\phaserBanks = ClampInt(*p\phaserBanks + 1, 0, 30)
        gUpgradeWeapons + 1
        LogLine("UPGRADE: phasers +1 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: phaser banks +1")
      Case "6"
        cost = 110
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\torpMax = ClampInt(*p\torpMax + 4, 0, 80)
        *p\torp = ClampInt(*p\torp + 4, 0, *p\torpMax)
        gUpgradeWeapons + 1
        LogLine("UPGRADE: torpMax +4 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: torpedo capacity +4")
      Case "7"
        cost = 200
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\torpTubes = ClampInt(*p\torpTubes + 1, 1, 6)
        If *p\torpTubes > *p\torpMax : *p\torpTubes = *p\torpMax : EndIf
        gUpgradeWeapons + 1
        LogLine("UPGRADE: tubes +1 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: torpedo tubes +1")
      Case "8"
        cost = 130
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\sensorRange = ClampInt(*p\sensorRange + 5, 1, 60)
        gUpgradeWeapons + 1
        LogLine("UPGRADE: sensors +5 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: sensor range +5")
      Case "9"
        cost = 250
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\warpMax = ClampF(*p\warpMax + 1.0, 0.0, 12.0)
        gUpgradePropulsion + 1
        LogLine("UPGRADE: warp +1.0 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: warp drive +1")
      Case "a"
        cost = 150
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\impulseMax = ClampF(*p\impulseMax + 0.3, 0.0, 2.5)
        gUpgradePropulsion + 1
        LogLine("UPGRADE: impulse +0.3 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: impulse engines +0.3")
      Case "b"
        cost = 100
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\fuelMax = ClampInt(*p\fuelMax + 25, 10, 600)
        *p\fuel = *p\fuelMax
        gUpgradePropulsion + 1
        LogLine("UPGRADE: fuel +25 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: fuel tanks +25")
      Case "c"
        cost = 180
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\reactorMax = ClampInt(*p\reactorMax + 30, 50, 900)
        *p\weaponCapMax = ClampInt(*p\weaponCapMax + 30, 10, 1400)
        *p\weaponCap = ClampInt(*p\weaponCap, 0, *p\weaponCapMax)
        gUpgradePowerCargo + 1
        LogLine("UPGRADE: reactor +30 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: reactor +30")
      Case "d"
        cost = 90
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\dilithiumMax = ClampInt(*p\dilithiumMax + 10, 0, 50)
        gUpgradePowerCargo + 1
        LogLine("UPGRADE: di-lithium +10 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: dilithium storage +10")
      Case "e"
        cost = 80
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\oreMax = ClampInt(*p\oreMax + 20, 0, 250)
        gUpgradePowerCargo + 1
        LogLine("UPGRADE: cargo +20 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: cargo hold +20")
      Case "f"
        cost = 60
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\probesMax = ClampInt(*p\probesMax + 2, 0, 20)
        *p\probes = *p\probesMax
        gUpgradeProbes + 1
        LogLine("UPGRADE: probes +2 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: probe bay +2")
      Case "g"
        cost = 100
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gProbeRange = ClampInt(gProbeRange + 1, 1, 10)
        gUpgradeProbes + 1
        LogLine("UPGRADE: probe range +1 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: probe scanner +1")
      Case "h"
        cost = 120
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gProbeAccuracy = ClampInt(gProbeAccuracy + 5, 50, 100)
        gUpgradeProbes + 1
        LogLine("UPGRADE: probe accuracy +5% (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: probe targeting +5%")
      Case "i"
        cost = 120
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gShuttleMaxCargo = ClampInt(gShuttleMaxCargo + 10, 10, 50)
        gUpgradeShuttle + 1
        LogLine("UPGRADE: shuttle cargo +10 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: shuttle cargo +10")
      Case "j"
        cost = 150
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gShuttleMaxCrew = ClampInt(gShuttleMaxCrew + 2, 2, 10)
        gUpgradeShuttle + 1
        LogLine("UPGRADE: shuttle crew +2 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: shuttle crew +2")
      Case "k"
        cost = 300
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gShuttleMaxCrew = ClampInt(gShuttleMaxCrew + 2, 2, 10)
        gUpgradeShuttle + 1
        LogLine("UPGRADE: shuttle crew +2 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: shuttle crew +2")
      Case "l"
        cost = 200
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gShuttleAttackRange = ClampInt(gShuttleAttackRange + 1, 10, 20)
        gUpgradeShuttle + 1
        LogLine("UPGRADE: shuttle attack range +1 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: shuttle attack +1")
        PrintN("Upgrade installed. Shuttle attack range: " + Str(gShuttleAttackRange))
      Default
        PrintN("Unknown selection.")
    EndSelect
  Wend
EndProcedure

;==============================================================================
; DockAtRefinery(*p.Ship)
; Docks player ship at a dilithium refinery to process ore and trade.
; 
; Refinery functions:
;   - REFINE: Convert raw ore to dilithium crystals (costs fuel)
;   - SELL: Sell dilithium for credits (price varies randomly)
;   - BUY: Buy dilithium to transport (price varies randomly)
;   - CARGO: Show current cargo hold
;   - STATUS: Show refinery status and prices
; 
; The refinery acts as a marketplace for dilithium with fluctuating prices.
; High dilithium cargo attracts pirates when leaving!
;==============================================================================
Procedure DockAtRefinery(*p.Ship)
  If CurCell(gx, gy)\entType <> #ENT_REFINERY
    PrintN("No refinery in this sector.")
    ProcedureReturn
  EndIf
  
  If gDocked
    PrintN("You are already docked.")
    ProcedureReturn
  EndIf
  
  gDocked = 1
  
  While #True
    ; Randomize prices for fluctuating economy
    Protected basePrice.i = 1 + Random(3)
    Protected ironPrice.i = 5 + Random(4)
    Protected alumPrice.i = 8 + Random(5)
    Protected copperPrice.i = 12 + Random(6)
    Protected tinPrice.i = 15 + Random(8)
    Protected bronzePrice.i = 25 + Random(10)
    Protected dilithiumPrice.i = 50 + Random(30)  ; Very valuable!
    
    PrintDivider()
    PrintN("Refinery: " + CurCell(gx, gy)\name)
    PrintN("Credits: " + Str(gCredits))
    PrintN("")
    PrintN("SHIP CARGO:")
    PrintN("  Ore in cargo: " + Str(*p\ore) + "/" + Str(*p\oreMax))
    PrintN("  Dilithium: " + Str(*p\dilithium) + "/" + Str(*p\dilithiumMax) + " crystals")
    PrintN("")
    PrintN("CARGO HOLD (refined metals):")
    PrintN("  Iron: " + Str(gIron))
    PrintN("  Aluminum: " + Str(gAluminum))
    PrintN("  Copper: " + Str(gCopper))
    PrintN("  Tin: " + Str(gTin))
    PrintN("  Bronze: " + Str(gBronze))
    PrintN("")
    PrintN("CURRENT PRICES:")
    PrintN("  Ore: " + Str(basePrice) + " | Iron: " + Str(ironPrice) + " | Aluminum: " + Str(alumPrice))
    PrintN("  Copper: " + Str(copperPrice) + " | Tin: " + Str(tinPrice) + " | Bronze: " + Str(bronzePrice))
    PrintN("  Dilithium: " + Str(dilithiumPrice) + " (very valuable!)")
    PrintN("")
    PrintN("COMMANDS:")
    PrintN("  REFINE             - Convert 1 ore to random refined metal (free)")
    PrintN("  REFINE ALL         - Convert all ore to refined metals")
    PrintN("  REFINE DILITHIUM   - Convert 1 dilithium crystal to 5 ore")
    PrintN("  SELL ORE           - Sell all ore (" + Str(basePrice) + " credits each)")
    PrintN("  SELL IRON          - Sell all iron (" + Str(ironPrice) + " credits each)")
    PrintN("  SELL ALUMINUM      - Sell all aluminum (" + Str(alumPrice) + " credits each)")
    PrintN("  SELL COPPER        - Sell all copper (" + Str(copperPrice) + " credits each)")
    PrintN("  SELL TIN           - Sell all tin (" + Str(tinPrice) + " credits each)")
    PrintN("  SELL BRONZE        - Sell all bronze (" + Str(bronzePrice) + " credits each)")
    PrintN("  SELL DILITHIUM     - Sell all dilithium (" + Str(dilithiumPrice) + " credits each)")
    PrintN("  SELL ALL           - Sell all cargo")
    PrintN("  UNDOCK             - Leave the refinery")
    Print("")
    ConsoleColor(#C_WHITE, #C_BLACK)
    Print("REFINERY> ")
    Protected cmd.s = TrimLower(Input())
    
    If cmd = "undock" Or cmd = "leave" Or cmd = "exit" Or cmd = "0"
      gDocked = 0
      Protected refFoundEmpty.i = 0
      Protected refDx.i, refDy.i
      For refDy = -1 To 1
        For refDx = -1 To 1
          If refDx = 0 And refDy = 0 : Continue : EndIf
          Protected rnx.i = gx + refDx
          Protected rny.i = gy + refDy
          If rnx >= 0 And rnx < #MAP_W And rny >= 0 And rny < #MAP_H
            If gGalaxy(gMapX, gMapY, rnx, rny)\entType = #ENT_EMPTY
              gx = rnx
              gy = rny
              refFoundEmpty = 1
              Break 2
            EndIf
          EndIf
        Next
      Next
      PrintN("Undocking...")
      StartEngineLoop()
      Break
    EndIf
    
    If cmd = "refine"
      If *p\ore <= 0
        PrintN("No ore to refine.")
        Continue
      EndIf
      *p\ore - 1
      Protected metalType.i = Random(4)
      Select metalType
        Case 0
          gIron + 1
          PrintN("Refined 1 ore -> 1 Iron")
        Case 1
          gAluminum + 1
          PrintN("Refined 1 ore -> 1 Aluminum")
        Case 2
          gCopper + 1
          PrintN("Refined 1 ore -> 1 Copper")
        Case 3
          gTin + 1
          PrintN("Refined 1 ore -> 1 Tin")
        Case 4
          gBronze + 1
          PrintN("Refined 1 ore -> 1 Bronze")
      EndSelect
      LogLine("REFINE: ore -> metal type " + Str(metalType))
      AddCaptainLog("REFINERY: refined 1 ore")
      Continue
    EndIf
    
    If cmd = "refine all"
      If *p\ore <= 0
        PrintN("No ore to refine.")
        Continue
      EndIf
      Protected refinedCount.i = 0
      While *p\ore > 0
        *p\ore - 1
        metalType = Random(4)
        Select metalType
          Case 0
            gIron + 1
          Case 1
            gAluminum + 1
          Case 2
            gCopper + 1
          Case 3
            gTin + 1
          Case 4
            gBronze + 1
        EndSelect
        refinedCount + 1
      Wend
      PrintN("Refined " + Str(refinedCount) + " ore into refined metals.")
      LogLine("REFINE ALL: " + Str(refinedCount) + " ore refined")
      AddCaptainLog("REFINERY: refined all ore (" + Str(refinedCount) + ")")
      Continue
    EndIf
    
    If cmd = "refine dilithium"
      If *p\dilithium <= 0
        PrintN("No dilithium crystals to refine.")
        Continue
      EndIf
      *p\dilithium - 1
      Protected oreGain.i = 5
      *p\ore + oreGain
      If *p\ore > *p\oreMax
        *p\ore = *p\oreMax
      EndIf
      PrintN("Refined 1 dilithium crystal -> " + Str(oreGain) + " ore")
      LogLine("REFINE DILITHIUM: 1 crystal -> " + Str(oreGain) + " ore")
      AddCaptainLog("REFINERY: refined 1 dilithium crystal")
      Continue
    EndIf
    
    Protected sellCmd.s = StringField(cmd, 1, " ")
    Protected sellQty.i = 0
    Protected sellPrice.i = 0
    
    If sellCmd = "sell"
      Protected sellTarget.s = TrimLower(StringField(cmd, 2, " "))
      
      If sellTarget = "ore"
        If *p\ore <= 0
          PrintN("No ore to sell.")
          Continue
        EndIf
        sellQty = *p\ore
        sellPrice = basePrice
        *p\ore = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " ore for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " ore for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " ore")
        Continue
      ElseIf sellTarget = "iron"
        If gIron <= 0
          PrintN("No iron to sell.")
          Continue
        EndIf
        sellQty = gIron
        sellPrice = ironPrice
        gIron = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " iron for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " iron for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " iron")
        Continue
      ElseIf sellTarget = "aluminum"
        If gAluminum <= 0
          PrintN("No aluminum to sell.")
          Continue
        EndIf
        sellQty = gAluminum
        sellPrice = alumPrice
        gAluminum = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " aluminum for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " aluminum for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " aluminum")
        Continue
      ElseIf sellTarget = "copper"
        If gCopper <= 0
          PrintN("No copper to sell.")
          Continue
        EndIf
        sellQty = gCopper
        sellPrice = copperPrice
        gCopper = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " copper for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " copper for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " copper")
        Continue
      ElseIf sellTarget = "tin"
        If gTin <= 0
          PrintN("No tin to sell.")
          Continue
        EndIf
        sellQty = gTin
        sellPrice = tinPrice
        gTin = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " tin for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " tin for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " tin")
        Continue
      ElseIf sellTarget = "bronze"
        If gBronze <= 0
          PrintN("No bronze to sell.")
          Continue
        EndIf
        sellQty = gBronze
        sellPrice = bronzePrice
        gBronze = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " bronze for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " bronze for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " bronze")
        Continue
      ElseIf sellTarget = "dilithium"
        If *p\dilithium <= 0
          PrintN("No dilithium to sell.")
          Continue
        EndIf
        sellQty = *p\dilithium
        sellPrice = dilithiumPrice
        *p\dilithium = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " dilithium for " + Str(sellQty * sellPrice) + " credits!")
        PrintN("WARNING: High-value cargo will attract pirates!")
        LogLine("SELL: " + Str(sellQty) + " dilithium for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " dilithium")
      ElseIf sellTarget = "all"
        Protected totalCredits.i = 0
        If *p\ore > 0
          totalCredits + (*p\ore * basePrice)
          *p\ore = 0
        EndIf
        If *p\dilithium > 0
          totalCredits + (*p\dilithium * dilithiumPrice)
          *p\dilithium = 0
        EndIf
        If gIron > 0
          totalCredits + (gIron * ironPrice)
          gIron = 0
        EndIf
        If gAluminum > 0
          totalCredits + (gAluminum * alumPrice)
          gAluminum = 0
        EndIf
        If gCopper > 0
          totalCredits + (gCopper * copperPrice)
          gCopper = 0
        EndIf
        If gTin > 0
          totalCredits + (gTin * tinPrice)
          gTin = 0
        EndIf
        If gBronze > 0
          totalCredits + (gBronze * bronzePrice)
          gBronze = 0
        EndIf
        gCredits + totalCredits
        PrintN("Sold all cargo for " + Str(totalCredits) + " credits.")
        LogLine("SELL ALL: " + Str(totalCredits) + " credits")
        AddCaptainLog("REFINERY: sold all cargo for " + Str(totalCredits) + " credits")
      Else
        PrintN("Unknown sell target. Use: ORE, IRON, ALUMINUM, COPPER, TIN, BRONZE, or ALL")
      EndIf
      Continue
    EndIf
    
    PrintN("Unknown command. Type UNDOCK to leave.")
  Wend
EndProcedure

;==============================================================================
; Nav(*p.Ship, dir.s, steps.i)
; Handles player movement in galaxy mode - moves ship to adjacent sector.
; Parameters:
;   *p - Pointer to player ship
;   dir - Direction (n/s/e/w or north/south/east/west)
;   steps - Number of sectors to move (default 1)
; 
; What it does:
; - Validates move is within sector bounds (0-7)
; - Consumes fuel: 1 fuel per move
; - Triggers random events during travel (radiation, ion storms)
; - Checks for enemy encounters in new sector
; - Handles movement into special entities (planets, bases, etc.)
; - Triggers pirate attacks if carrying high-value dilithium cargo
;==============================================================================
Procedure Nav(*p.Ship, dir.s, steps.i)
  dir = TrimLower(dir)
  steps = ClampInt(steps, 1, 5)

  Protected moved.i = 0
  Protected startMapX.i = gMapX
  Protected startMapY.i = gMapY
  Protected startX.i = gx
  Protected startY.i = gy

  Protected dx.i = 0
  Protected dy.i = 0
  
  ; Convert compass heading to direction
  Protected heading.i = ParseIntSafe(dir, -1)
  Select heading
    Case 0    ; North
      dy = -1
    Case 180  ; South
      dy = 1
    Case 90   ; East
      dx = 1
    Case 270  ; West
      dx = -1
    Case 45   ; Northeast
      dx = 1 : dy = -1
    Case 135  ; Southeast
      dx = 1 : dy = 1
    Case 225  ; Southwest
      dx = -1 : dy = 1
    Case 315  ; Northwest
      dx = -1 : dy = -1
    Default
      PrintN("NAV expects compass heading: 0=N, 45=NE, 90=E, 135=SE, 180=S, 225=SW, 270=W, 315=NW")
      PrintN("Example: NAV 45 2  (northeast 2 sectors)")
      ProcedureReturn
  EndSelect

  Protected i.i
  For i = 1 To steps
    If *p\fuel <= 0
      LogLine("NAV: fuel depleted")
      PrintN("Fuel depleted.")
      Break
    EndIf

    Protected nx.i = gx + dx
    Protected ny.i = gy + dy

    ; Wrap to next/prev map when leaving sector grid
    If nx < 0
      If gMapX > 0
        gMapX - 1
        nx = #MAP_W - 1
      Else
        LogLine("NAV: edge of the galaxy")
        PrintN("Edge of the galaxy.")
        Break
      EndIf
    ElseIf nx >= #MAP_W
      If gMapX < #GALAXY_W - 1
        gMapX + 1
        nx = 0
      Else
        LogLine("NAV: edge of the galaxy")
        PrintN("Edge of the galaxy.")
        Break
      EndIf
    EndIf

    If ny < 0
      If gMapY > 0
        gMapY - 1
        ny = #MAP_H - 1
      Else
        LogLine("NAV: edge of the galaxy")
        PrintN("Edge of the galaxy.")
        Break
      EndIf
    ElseIf ny >= #MAP_H
      If gMapY < #GALAXY_H - 1
        gMapY + 1
        ny = 0
      Else
        LogLine("NAV: edge of the galaxy")
        PrintN("Edge of the galaxy.")
        Break
      EndIf
    EndIf

    If CurCell(nx, ny)\entType = #ENT_STAR
      LogLine("NAV: blocked by star")
      PrintN("Navigation blocked by stellar hazard.")
      Break
    EndIf

    If CurCell(nx, ny)\entType = #ENT_SUN
      LogLine("NAV: blocked by sun")
      PrintN("Navigation blocked by stellar hazard.")
      Break
    EndIf

    gx = nx
    gy = ny
    *p\fuel - 1
    moved + 1

    ; Immediate on-arrival effects
    Protected chain.i
    For chain = 1 To 4
      If HandleSun(*p)
        Break
      EndIf
      If CurCell(gx, gy)\entType = #ENT_WORMHOLE Or CurCell(gx, gy)\entType = #ENT_BLACKHOLE
        If HandleArrival(*p)
          ; Player moved (teleport/scramble); re-process hazards at new location.
          Continue
        EndIf
        If *p\hull <= 0
          Break
        EndIf
      EndIf
      
      ; Anomaly effects
      If CurCell(gx, gy)\entType = #ENT_ANOMALY
        Protected anomalyRoll.i = Random(99)
        If anomalyRoll < 40
          ; Ion storm - reduces shields
          gIonStormTurns = 1 + Random(4)
          *p\shields = Int(*p\shields / 2)
          PrintN("WARNING: Ion storm detected! Shields scrambled.")
          LogLine("ANOMALY: ion storm - " + Str(gIonStormTurns) + " turns")
        ElseIf anomalyRoll < 70
          ; Radiation - lowers crew rank
          gRadiationTurns = 1 + Random(4)
          PrintN("WARNING: Radiation anomaly! Crew effectiveness reduced.")
          LogLine("ANOMALY: radiation - " + Str(gRadiationTurns) + " turns")
        Else
          PrintN("Sensors detect anomalous readings. No immediate effect.")
        EndIf
      EndIf
      
      If ApplyGravityWell(*p)
        ; Pulled into a hazard; process arrival next loop iteration.
        Continue
      EndIf
      Break
    Next

    If *p\hull <= 0
      Break
    EndIf

    If CurCell(gx, gy)\entType = #ENT_ENEMY Or CurCell(gx, gy)\entType = #ENT_PIRATE
      gEnemyMapX = gMapX
      gEnemyMapY = gMapY
      gEnemyX = gx
      gEnemyY = gy
      LogLine("CONTACT: enemy detected!")
      Break
    EndIf
  Next

  If moved > 0
    If startMapX <> gMapX Or startMapY <> gMapY
      LogLine("NAV " + UCase(dir) + " " + Str(steps) + ": moved " + Str(moved) + " step(s) to Galaxy (" + Str(gMapX) + "," + Str(gMapY) + ") Sector (" + Str(gx) + "," + Str(gy) + ")")
    ElseIf startX <> gx Or startY <> gy
      LogLine("NAV " + UCase(dir) + " " + Str(steps) + ": moved " + Str(moved) + " step(s) to Sector (" + Str(gx) + "," + Str(gy) + ")")
    EndIf
  EndIf
EndProcedure

; Returns 1 if it did something (moved or provided a message).
Procedure.i AutopilotToMission(*p.Ship, *enemyTemplate.Ship, *enemy.Ship, *cs.CombatState)
  If gMission\active = 0
    PrintN("Autopilot: no active mission.")
    ProcedureReturn 1
  EndIf
  If gMission\destEntType = #ENT_EMPTY
    PrintN("Autopilot: this mission has no fixed destination.")
    ProcedureReturn 1
  EndIf

  ; Already there
  If gMapX = gMission\destMapX And gMapY = gMission\destMapY And gx = gMission\destX And gy = gMission\destY
    PrintN("Autopilot: you are at the mission destination.")
    ProcedureReturn 1
  EndIf

  Protected path.s
  path = FindPathMission(gMapX, gMapY, gx, gy, gMission\destMapX, gMission\destMapY, gMission\destX, gMission\destY, 0, 0, 0)
  If path = ""
    ; Try again allowing wormholes (still avoids black holes)
    path = FindPathMission(gMapX, gMapY, gx, gy, gMission\destMapX, gMission\destMapY, gMission\destX, gMission\destY, 1, 0, 0)
  EndIf
  If path = ""
    PrintN("Autopilot: no safe route found (blocked by hazards/obstacles).")
    PrintN("Tip: you can try manual NAV around stars/suns, or risk a wormhole (#).")
    ProcedureReturn 1
  EndIf

  Protected movedAny.i = 0
  Protected i.i
  For i = 1 To Len(path)
    If *p\fuel <= 0
      PrintN("Autopilot: fuel depleted.")
      Break
    EndIf
    If *p\hull <= 0
      Break
    EndIf

    Protected d.s = Mid(path, i, 1)
    Protected beforeMapX.i = gMapX, beforeMapY.i = gMapY, beforeX.i = gx, beforeY.i = gy
    Nav(*p, d, 1)
    If gMapX <> beforeMapX Or gMapY <> beforeMapY Or gx <> beforeX Or gy <> beforeY
      movedAny = 1
    EndIf

    ; Enemy contact should interrupt. Let the player choose whether to engage.
    If CurCell(gx, gy)\entType = #ENT_ENEMY Or CurCell(gx, gy)\entType = #ENT_PIRATE
      PrintN("Autopilot: enemy contact detected.")
      ConsoleColor(#C_WHITE, #C_BLACK)
      Print("Engage? (F)ight / (A)bort > ")
      Protected respRaw.s = Input()
      respRaw = ReplaceString(respRaw, Chr(13), "")
      respRaw = ReplaceString(respRaw, Chr(10), "")
      respRaw = CleanLine(respRaw)
      Protected resp.s = TrimLower(Trim(respRaw))

      If resp = "f" Or resp = "fight" Or resp = "y" Or resp = "yes" Or resp = ""
        CopyStructure(*enemyTemplate, *enemy, Ship)
        Protected lvl.i = CurCell(gx, gy)\enemyLevel
        If lvl < 1 : lvl = 1 : EndIf
        ; Ensure valid enemy stats
        If *enemy\name = "" Or *enemy\hullMax <= 0
          *enemy\name = "Raider"
          *enemy\class = "Raider"
          *enemy\hullMax = 100
          *enemy\hull = 100
          *enemy\shieldsMax = 90
          *enemy\shields = 90
          *enemy\weaponCapMax = 210
          *enemy\weaponCap = 105
          *enemy\phaserBanks = 6
          *enemy\torpTubes = 2
          *enemy\torpMax = 8
          *enemy\torp = 8
        EndIf
        *enemy\hullMax = *enemy\hullMax + (lvl * 10)
        *enemy\hull = *enemy\hullMax
        *enemy\shieldsMax = *enemy\shieldsMax + (lvl * 12)
        *enemy\shields = *enemy\shieldsMax
        *enemy\weaponCapMax = *enemy\weaponCapMax + (lvl * 20)
        *enemy\weaponCap = *enemy\weaponCapMax / 2
        *enemy\torp = *enemy\torpMax
        EnterCombat(*p, *enemy, *cs)
        PrintN("Autopilot: engaging.")
      Else
        PrintN("Autopilot: aborted. Manual control.")
      EndIf
      Break
    EndIf

    If gMapX = gMission\destMapX And gMapY = gMission\destMapY And gx = gMission\destX And gy = gMission\destY
      PrintN("Autopilot: arrived at mission destination.")
      Break
    EndIf
  Next

  If movedAny = 0
    PrintN("Autopilot: unable to make progress.")
  EndIf
  ProcedureReturn 1
EndProcedure

;==============================================================================
; EnterCombat(*p.Ship, *enemy.Ship, *cs.CombatState)
; Transitions the game from galaxy mode to tactical combat mode.
; Parameters:
;   *p - Pointer to player ship structure
;   *enemy - Pointer to enemy ship structure
;   *cs - Pointer to combat state (range, turn, aim, fleet states)
; 
; What it does:
; - Ensures player and enemy have valid hull/shields (fixes ghost ships)
; - Sets game mode to tactical combat
; - Initializes combat state (range, turn counter, fleet states)
; - Plays red alert sound
; - Displays combat status and instructions
; - Logs combat entry to captain's log
; - Spawns enemy fleet for high-level enemies (level > 3)
;==============================================================================
Procedure EnterCombat(*p.Ship, *enemy.Ship, *cs.CombatState)
  ; Ensure player has hull to fight
  If *p\hull <= 0
    *p\hull = *p\hullMax
    *p\shields = *p\shieldsMax
  EndIf
  
  ; Ensure enemy has valid stats (fix ghost ships)
  If *enemy\hullMax <= 0
    *enemy\hullMax = 100
    *enemy\hull = 100
    *enemy\shieldsMax = 90
    *enemy\shields = 90
    *enemy\weaponCapMax = 210
    *enemy\weaponCap = 105
    *enemy\phaserBanks = 6
    *enemy\torpTubes = 2
    *enemy\torpMax = 8
    *enemy\torp = 8
    *enemy\name = "Raider"
    *enemy\class = "Raider"
  EndIf
  If *enemy\hull <= 0
    *enemy\hull = *enemy\hullMax
  EndIf
  If *enemy\shields <= 0
    *enemy\shields = *enemy\shieldsMax
  EndIf
  
  PlayRedAlert()
  gMode = #MODE_TACTICAL
  *cs\range = 16 + Random(10)
  *cs\turn = 1
  *cs\pAim = 0
  *cs\eAim = 0
  *cs\pFleetAttack = 0
  *cs\pFleetHit = 0
  *cs\eFleetAttack = 0
  *cs\eFleetHit = 0
  PrintN("")
  PrintN("Red alert! Engaging enemy!")
  PrintStatusTactical(*p, *enemy, *cs)
  PrintN("")
  PrintN("Type HELP for combat commands.")
  
  ; Log combat entry
  AddCaptainLog("COMBAT: Engaged " + *enemy\name + " at range " + Str(*cs\range))
  
  ; Spawn enemy fleet based on enemy level
  Protected enemyLvl.i = CurCell(gx, gy)\enemyLevel
  If enemyLvl > 3
    gEnemyFleetCount = Random(2)  ; 0-2 fleet ships
    Protected efSetup.i
    For efSetup = 1 To gEnemyFleetCount
      CopyStructure(*enemy, @gEnemyFleet(efSetup), Ship)
      gEnemyFleet(efSetup)\hull = gEnemyFleet(efSetup)\hullMax
      gEnemyFleet(efSetup)\shields = gEnemyFleet(efSetup)\shieldsMax
      gEnemyFleet(efSetup)\name = "Enemy Fleet " + Str(efSetup)
    Next
    If gEnemyFleetCount > 0
      PrintN("WARNING: Enemy has " + Str(gEnemyFleetCount) + " supporting ships!")
    EndIf
  EndIf
EndProcedure

;==============================================================================
; LeaveCombat()
; Called when combat ends (player wins, flees, or enemy is destroyed).
; - Sets game mode back to galaxy exploration
; - Stops combat sounds and restarts engine loop if undocked
; - Clears enemy fleet count
;==============================================================================
Procedure LeaveCombat()
  gMode = #MODE_GALAXY
  gEngineLoopChannel = -1
  gEnemyFleetCount = 0
  If gDocked = 0
    StartEngineLoop()
  EndIf
EndProcedure

;==============================================================================
; Main()
; Entry point for the entire game. Initializes all game systems, loads data,
; generates the galaxy, and starts the main game loop. Handles both galaxy mode
; (exploration) and tactical mode (combat).
; - Initializes console, logging, sounds, and ship data
; - Generates the galaxy map with planets, stars, enemies, etc.
; - Runs the main command loop (CMD>) for player input
; - Handles transitions between galaxy and combat modes
;==============================================================================
Procedure Main()
  Protected player.Ship
  Protected enemyTemplate.Ship
  Protected enemy.Ship
  Protected cs.CombatState
  Protected playerSection.s
  Protected enemySection.s

  RandomSeed(Date())

  If OpenConsole() = 0
    MessageRequester("Error", "Unable to open console")
    End
  EndIf

  InitLogging()
  OnErrorCall(@CrashHandler())

  ConsoleColor(#C_WHITE, #C_BLACK)
  PrintN("Starship Console (Galaxy + Tactical)")
  ConsoleColor(#C_WHITE, #C_BLACK)
  PrintN("Data: " + gDatPath + " (fallback " + gIniPath + ")")
  ResetColor()
  PrintN("")

  InitShipData()
  InitSounds()

  playerSection = LoadGameSettingString("PlayerSection", "PlayerShip")
  enemySection  = LoadGameSettingString("EnemySection",  "EnemyShip")

  If LoadShip(playerSection, @player) = 0
    PrintN("Could not load ship data section '" + playerSection + "'.")
    Input()
    End
  EndIf
  
  InitCrew(@player)

  If LoadShip(enemySection, @enemyTemplate) = 0
    PrintN("Could not load ship data section '" + enemySection + "'.")
    Input()
    End
  EndIf

  GenerateGalaxy()
  InitRecruitNames()
  GenerateRecruits()
  GenerateMission(@player)
  LogLine("Welcome aboard")
  PrintN("Sound: " + Str(gSoundEnabled))
  PlayBeepTest()
  If gDocked = 0
    StartEngineLoop()
  EndIf
  RedrawGalaxy(@player)

  While IsAlive(@player)
    ConsoleColor(#C_WHITE, #C_BLACK)
    Print("CMD> ")
    Protected lineRaw.s = Input()
    ; When stdin is closed (eg. redirected), some consoles feed EOF as control chars.
    If lineRaw = Chr(4) Or lineRaw = Chr(26)
      Break
    EndIf

    ; Normalize line endings and stray control chars
    lineRaw = ReplaceString(lineRaw, Chr(13), "")
    lineRaw = ReplaceString(lineRaw, Chr(10), "")
    lineRaw = CleanLine(lineRaw)

    gLastCmdLine = lineRaw

    Protected line.s = Trim(lineRaw)
    Protected cmd.s  = TrimLower(TokenAt(line, 1))
    If cmd = "" : cmd = "end" : EndIf
    
    ; Log every command for the captain's log
    If cmd <> "" And cmd <> "end"
      AddCaptainLog("CMD: " + line)
    EndIf
    
    PlaySoundFX(SoundSelect)

      If gMode = #MODE_GALAXY
        If cmd = "help"
        ClearConsole()
        PrintHelpGalaxy()
        PrintN("")
        PrintN("< Press ENTER >")
        Input()
        RedrawGalaxy(@player)
      ElseIf cmd = "about"
        ClearConsole()
        PrintAbout()
        PrintN("< Press ENTER >")
        Input()
        RedrawGalaxy(@player)
      ElseIf cmd = "status"
        RedrawGalaxy(@player)
      ElseIf cmd = "alloc"
        Protected galPctShields.i = ParseIntSafe(TokenAt(line, 4), player\allocShields)
        Protected galPctWeapons.i = ParseIntSafe(TokenAt(line, 3), player\allocWeapons)
        Protected galPctEngines.i = ParseIntSafe(TokenAt(line, 2), player\allocEngines)
        
        galPctShields = ClampInt(galPctShields, 0, 100)
        galPctWeapons = ClampInt(galPctWeapons, 0, 100)
        galPctEngines = ClampInt(galPctEngines, 0, 100)
        
        If galPctShields + galPctWeapons + galPctEngines > 100
          PrintN("Allocation sum must be <= 100.")
        ElseIf TokenAt(line, 2) = ""
          PrintN("Current allocation: Engines=" + Str(player\allocEngines) + " | Weapons=" + Str(player\allocWeapons) + " | Shields=" + Str(player\allocShields))
          PrintN("Usage: ALLOC <engines> <weapons> <shields>")
          PrintN("Example: ALLOC 33 34 33")
        Else
          player\allocShields = galPctShields
          player\allocWeapons = galPctWeapons
          player\allocEngines = galPctEngines
          SaveAlloc("PlayerShip", @player)
          PrintN("Allocation set: Engines=" + Str(player\allocEngines) + " | Weapons=" + Str(player\allocWeapons) + " | Shields=" + Str(player\allocShields))
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "crew"
        ClearConsole()
        PrintN("Crew Status:")
        PrintN("")
        PrintCrew(@player)
        PrintN("< Press ENTER >")
        Input()
        RedrawGalaxy(@player)
      ElseIf cmd = "log"
        PlaySoundFX(SoundRadio)
        Protected logSearch.s = Trim(TokenAt(line, 2))
        If logSearch = "purge" Or logSearch = "clear"
          Protected confirm.s = Trim(LCase(TokenAt(line, 3)))
          If confirm = "yes"
            Protected clearIdx.i
            For clearIdx = 0 To ArraySize(gCaptainLog()) - 1
              gCaptainLog(clearIdx) = ""
            Next
            gCaptainLogCount = 0
            PrintN("Captain's log purged.")
            AddCaptainLog("LOG: purged")
          Else
            PrintN("LOG PURGE - Delete all current log entries")
            PrintN("  Usage: LOG PURGE YES")
            PrintN("  This will permanently delete all current log entries!")
          EndIf
        Else
          PrintCaptainLog(logSearch)
          PrintN("< Press ENTER >")
          Input()
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "launchshuttle"
        If gShuttleLaunched = 1
          PrintN("Shuttle is already launched.")
        ElseIf gDocked = 0
          PrintN("Must be docked at a starbase to launch shuttle.")
        Else
          Protected shuttleAction.s = TrimLower(TokenAt(line, 2))
          If shuttleAction = ""
            PrintN("LAUNCHSHUTTLE - Launch shuttle craft")
            PrintN("  LAUNCHSHUTTLE LAUNCH [crew] - Launch shuttle with crew (1-" + Str(gShuttleMaxCrew) + ")")
            PrintN("  LAUNCHSHUTTLE RECALL          - Recall shuttle to ship")
            PrintN("  LAUNCHSHUTTLE MINE            - Collect resources from planet (if on planet)")
            PrintN("  In combat: use SHUTTLE ATTACK to attack enemy")
            PrintN("Current shuttle: Crew=" + Str(gShuttleCrew) + " Ore=" + Str(gShuttleCargoOre) + " Dilithium=" + Str(gShuttleCargoDilithium))
          ElseIf shuttleAction = "launch"
            Protected shuttleCrew.i = ParseIntSafe(TokenAt(line, 3), gShuttleCrew)
            If shuttleCrew < 1 : shuttleCrew = 1 : EndIf
            If shuttleCrew > gShuttleMaxCrew : shuttleCrew = gShuttleMaxCrew : EndIf
            gShuttleCrew = shuttleCrew
            gShuttleLaunched = 1
            gShuttleCargoOre = 0
            gShuttleCargoDilithium = 0
            PrintN("Shuttle launched with " + Str(gShuttleCrew) + " crew.")
            AddCaptainLog("SHUTTLE: launched with " + Str(gShuttleCrew) + " crew")
            PlayEngineSound()
          ElseIf shuttleAction = "recall"
            If gShuttleLaunched = 0
              PrintN("Shuttle is not launched.")
            Else
              player\ore + gShuttleCargoOre
              player\dilithium + gShuttleCargoDilithium
              PrintN("Shuttle recalled. Retrieved " + Str(gShuttleCargoOre) + " ore and " + Str(gShuttleCargoDilithium) + " dilithium.")
              AddCaptainLog("SHUTTLE: recalled with " + Str(gShuttleCargoOre) + " ore, " + Str(gShuttleCargoDilithium) + " dilithium")
              gShuttleLaunched = 0
              gShuttleCargoOre = 0
              gShuttleCargoDilithium = 0
              PlayEngineSound()
            EndIf
          ElseIf shuttleAction = "mine" Or shuttleAction = "collect"
            If gShuttleLaunched = 0
              PrintN("Shuttle is not launched.")
            Else
              ShuttleMine()
              PlayMiningSound()
            EndIf
          Else
            PrintN("Unknown shuttle command. Use LAUNCHSHUTTLE for help.")
          EndIf
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "map"
        RedrawGalaxy(@player)
      ElseIf cmd = "clear"
        ClearLog()
        RedrawGalaxy(@player)
      ElseIf cmd = "upgrades"
        PrintN("=== INSTALLED UPGRADES ===")
        PrintN("HULL & ARMOR:      " + Str(gUpgradeHull) + " upgrades")
        PrintN("SHIELDS:           " + Str(gUpgradeShields) + " upgrades")
        PrintN("WEAPONS:           " + Str(gUpgradeWeapons) + " upgrades")
        PrintN("PROPULSION:        " + Str(gUpgradePropulsion) + " upgrades")
        PrintN("POWER & CARGO:     " + Str(gUpgradePowerCargo) + " upgrades")
        PrintN("PROBES:            " + Str(gUpgradeProbes) + " upgrades")
        PrintN("SHUTTLE:           " + Str(gUpgradeShuttle) + " upgrades")
        PrintN("")
        PrintN("Total upgrades: " + Str(gUpgradeHull + gUpgradeShields + gUpgradeWeapons + gUpgradePropulsion + gUpgradePowerCargo + gUpgradeProbes + gUpgradeShuttle))
        RedrawGalaxy(@player)
      ElseIf cmd = "fleet"
        Protected fleetCmd.s = TrimLower(TokenAt(line, 2))
        If fleetCmd = ""
          PrintN("=== YOUR FLEET ===")
          PrintN("Player ship: " + player\name + " (" + player\class + ")")
          If gPlayerFleetCount > 0
            Protected f.i
            For f = 1 To gPlayerFleetCount
              PrintN("  Fleet " + Str(f) + ": " + gPlayerFleet(f)\name + " (" + gPlayerFleet(f)\class + ") - Hull: " + Str(gPlayerFleet(f)\hull) + "/" + Str(gPlayerFleet(f)\hullMax))
            Next
          EndIf
          PrintN("Total fleet ships: " + Str(gPlayerFleetCount) + "/5")
          ElseIf fleetCmd = "add"
          If gPlayerFleetCount >= 5
            PrintN("Fleet is full (max 5 ships).")
          ElseIf gDocked = 0
            PrintN("Must be docked at a starbase to add fleet ships.")
          Else
            gPlayerFleetCount = gPlayerFleetCount + 1
            Protected newFleetIdx.i = gPlayerFleetCount
            CopyStructure(@player, @gPlayerFleet(newFleetIdx), Ship)
            gPlayerFleet(newFleetIdx)\name = "Fleet Ship " + Str(newFleetIdx)
            gPlayerFleet(newFleetIdx)\hull = gPlayerFleet(newFleetIdx)\hullMax
            gPlayerFleet(newFleetIdx)\shields = gPlayerFleet(newFleetIdx)\shieldsMax
            PrintN("Added " + gPlayerFleet(newFleetIdx)\name + " to fleet.")
            AddCaptainLog("FLEET: added ship to fleet")
          EndIf
        ElseIf fleetCmd = "remove"
          If gPlayerFleetCount = 0
            PrintN("No fleet ships to remove.")
          Else
            gPlayerFleetCount = gPlayerFleetCount - 1
            PrintN("Removed last fleet ship from fleet.")
            AddCaptainLog("FLEET: removed ship from fleet")
          EndIf
        Else
          PrintN("FLEET - Manage your fleet (up to 5 ships)")
          PrintN("  FLEET           - Show fleet status")
          PrintN("  FLEET ADD       - Add current ship to fleet (docked at starbase)")
          PrintN("  FLEET REMOVE    - Remove last fleet ship")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "undo"
        If gUndoAvailable = 0
          PrintN("No undo available.")
        Else
          Protected fuel.i, hull.i, shields.i, credits.i, ore.i, dilithium.i
          Protected mapX.i, mapY.i, x.i, y.i, mode.i
          Protected iron.i, aluminum.i, copper.i, tin.i, bronze.i
          If RestoreUndoState(@fuel, @hull, @shields, @credits, @ore, @dilithium, @mapX, @mapY, @x, @y, @mode, @iron, @aluminum, @copper, @tin, @bronze)
            player\fuel = fuel
            player\hull = hull
            player\shields = shields
            gCredits = credits
            player\ore = ore
            player\dilithium = dilithium
            gMapX = mapX
            gMapY = mapY
            gx = x
            gy = y
            gMode = mode
            gIron = iron
            gAluminum = aluminum
            gCopper = copper
            gTin = tin
            gBronze = bronze
            PrintN("*** UNDO: Time rewound! ***")
            LogLine("UNDO: state restored")
            RedrawGalaxy(@player)
          Else
            PrintN("Undo failed.")
          EndIf
        EndIf
      ElseIf cmd = "scan"
        ClearConsole()
        PrintHelpGalaxy()
        PrintN("")
        ScanGalaxy()
        PrintN("< Press ENTER >")
        Input()

        CheckMissionCompletion(@player)
        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        RedrawGalaxy(@player)
      ElseIf cmd = "longscan"
        ClearConsole()
        ScanGalaxyLong()
        PrintN("< Press ENTER >")
        Input()
        RedrawGalaxy(@player)
      ElseIf cmd = "nav"
        If gDocked
          PrintN("You are docked. Use UNDOCK first.")
          RedrawGalaxy(@player)
        Else
          SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode, gIron, gAluminum, gCopper, gTin, gBronze)
          Protected navDir.s = TokenAt(line, 2)
          Protected navSteps.i = ParseIntSafe(TokenAt(line, 3), 1)
          Protected oldX.i = gx
          Protected oldY.i = gy
          Nav(@player, navDir, navSteps)
          
          ; Log the movement
          If gx <> oldX Or gy <> oldY
            AddCaptainLog("NAV: " + navDir + " to (" + Str(gMapX) + "," + Str(gMapY) + ") sector (" + Str(gx) + "," + Str(gy) + ")")
          EndIf
          
          CheckMissionCompletion(@player)
          DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
          AdvanceStardate(navSteps)
          
          ; Dilithium bounty - high dilithium attracts pirates!
          If player\dilithium >= 5
            Protected bountyRoll.i = Random(99)
            Protected bountyChance.i = (player\dilithium - 4) * 3  ; 3% per crystal over 4
            If bountyChance > 30 : bountyChance = 30 : EndIf
            If bountyRoll < bountyChance
              ; Spawn a pirate to hunt the player!
              Protected huntX.i, huntY.i
              For huntY = 0 To #MAP_H - 1
                For huntX = 0 To #MAP_W - 1
                  If gGalaxy(gMapX, gMapY, huntX, huntY)\entType = #ENT_EMPTY
                    gGalaxy(gMapX, gMapY, huntX, huntY)\entType = #ENT_PIRATE
                    gGalaxy(gMapX, gMapY, huntX, huntY)\enemyLevel = 2 + Int(player\dilithium / 3)
                    If gGalaxy(gMapX, gMapY, huntX, huntY)\enemyLevel > 10
                      gGalaxy(gMapX, gMapY, huntX, huntY)\enemyLevel = 10
                    EndIf
                    gGalaxy(gMapX, gMapY, huntX, huntY)\name = "Pirate Hunter"
                    PrintN("WARNING: Pirates have detected your dilithium cargo!")
                    PrintN("A Pirate Hunter has warped into the sector!")
                    LogLine("BOUNTY: pirate detected dilithium cargo (" + Str(player\dilithium) + " crystals)")
                    Break 2
                  EndIf
                Next
              Next
            EndIf
          EndIf
          
          PlayEngineSound()
          PlayAmbientChatter()
          RedrawGalaxy(@player)

        If CurCell(gx, gy)\entType = #ENT_ENEMY Or CurCell(gx, gy)\entType = #ENT_PIRATE
          CopyStructure(@enemyTemplate, @enemy, Ship)
          ; Override name from galaxy cell (e.g., "Pirate Hunter")
          If CurCell(gx, gy)\name <> ""
            enemy\name = CurCell(gx, gy)\name
          EndIf
          Protected lvl.i = CurCell(gx, gy)\enemyLevel
          If lvl < 1 : lvl = 1 : EndIf
          ; Check for Planet Killer (very powerful)
          If CurCell(gx, gy)\entType = #ENT_PLANETKILLER
            enemy\name = "Planet Killer"
            enemy\class = "Planet Killer"
            enemy\hullMax = 500 + (lvl * 50)
            enemy\hull = enemy\hullMax
            enemy\shieldsMax = 400 + (lvl * 40)
            enemy\shields = enemy\shieldsMax
            enemy\weaponCapMax = 600 + (lvl * 50)
            enemy\weaponCap = enemy\weaponCapMax
            enemy\phaserBanks = 12
            enemy\torpTubes = 4
            enemy\torpMax = 20
            enemy\torp = enemy\torpMax
          ElseIf enemy\name = "" Or enemy\hullMax <= 0
            enemy\name = "Raider"
            enemy\class = "Raider"
            enemy\hullMax = 100
            enemy\hull = 100
            enemy\shieldsMax = 90
            enemy\shields = 90
            enemy\weaponCapMax = 210
            enemy\weaponCap = 105
            enemy\phaserBanks = 6
            enemy\torpTubes = 2
            enemy\torpMax = 8
            enemy\torp = 8
          EndIf
          enemy\hullMax = enemy\hullMax + (lvl * 10)
          enemy\hull = enemy\hullMax
          enemy\shieldsMax = enemy\shieldsMax + (lvl * 12)
          enemy\shields = enemy\shieldsMax
          enemy\weaponCapMax = enemy\weaponCapMax + (lvl * 20)
          enemy\weaponCap = enemy\weaponCapMax / 2
          enemy\torp = enemy\torpMax
          EnterCombat(@player, @enemy, @cs)
        EndIf

        ; If we're defending a yard and left, give the yard a chance to take damage.
        If gMission\active And gMission\type = #MIS_DEFEND_YARD
          If (gMapX <> gMission\destMapX Or gMapY <> gMission\destMapY Or gx <> gMission\destX Or gy <> gMission\destY)
            If Random(99) < ClampInt(25 + gMission\threatLevel * 8, 25, 70)
              gMission\yardHP - 1
              If gMission\yardHP < 0 : gMission\yardHP = 0 : EndIf
              LogLine("YARD HIT (away): hp=" + Str(gMission\yardHP))
            EndIf
          EndIf
        EndIf
        
        EnemyGalaxyAI(@player, @enemyTemplate, @cs)
        EndIf
      ElseIf cmd = "warp"
        If gDocked
          PrintN("You are docked. Use UNDOCK first.")
        ElseIf gWarpCooldown > 0
          PrintN("Warp engines recharging. " + Str(gWarpCooldown) + " turn(s) remaining.")
        ElseIf player\dilithium < 5
          PrintN("Insufficient dilithium. Need 5 to warp.")
        Else
          Protected warpX.i = ParseIntSafe(TokenAt(line, 2), -1)
          Protected warpY.i = ParseIntSafe(TokenAt(line, 3), -1)
          If warpX < 0 Or warpX >= #GALAXY_W Or warpY < 0 Or warpY >= #GALAXY_H
            PrintN("Invalid coordinates. Use: WARP x y (e.g., WARP 3 2) for galaxy coordinates 0-" + Str(#GALAXY_W-1) + ",0-" + Str(#GALAXY_H-1))
          ElseIf warpX = gMapX And warpY = gMapY
            PrintN("Already in that galaxy location. Use NAV to move within the sector.")
          Else
            SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode, gIron, gAluminum, gCopper, gTin, gBronze)
            player\dilithium - 5
            gWarpCooldown = 10
            gMapX = warpX
            gMapY = warpY
            gx = Random(#MAP_W - 1)
            gy = Random(#MAP_H - 1)
            PrintN("Warping to galaxy (" + Str(warpX) + "," + Str(warpY) + ")!")
            LogLine("WARP: to galaxy " + Str(warpX) + "," + Str(warpY))
          EndIf
        EndIf
        CheckMissionCompletion(@player)
        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        EnemyGalaxyAI(@player, @enemyTemplate, @cs)
        AdvanceStardate()
        RedrawGalaxy(@player)
      ElseIf cmd = "mine"
        If gDocked
          PrintN("You are docked. Use UNDOCK first.")
        Else
          Protected mineArg.s = TrimLower(TokenAt(line, 2))
          If mineArg = "miner2049er"
            player\ore = player\oreMax
            player\dilithium = player\dilithiumMax
            LogLine("CHEAT: miner2049er (filled cargo)")
            PrintN("Cheat activated: Cargo hold filled!")
          Else
            SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode, gIron, gAluminum, gCopper, gTin, gBronze)
          MinePlanet(@player)
          EndIf
        EndIf

      ElseIf cmd = "launchprobe"
        If gDocked
          PrintN("You are docked. Use UNDOCK first.")
        ElseIf player\probes <= 0
          PrintN("No probes remaining!")
        Else
          Protected probeX.s = TokenAt(line, 2)
          Protected probeY.s = TokenAt(line, 3)
          If probeX = "" Or probeY = ""
            PrintN("Usage: LAUNCHPROBE <galaxyX> <galaxyY>")
            PrintN("  Example: LAUNCHPROBE 3 2")
            PrintN("  Current probes: " + Str(player\probes))
          Else
            Protected targetMapX.i = Val(probeX)
            Protected targetMapY.i = Val(probeY)
            If targetMapX < 0 Or targetMapX >= #GALAXY_W Or targetMapY < 0 Or targetMapY >= #GALAXY_H
              PrintN("Invalid coordinates. Galaxy is " + Str(#GALAXY_W) + "x" + Str(#GALAXY_H))
            ElseIf targetMapX = gMapX And targetMapY = gMapY
              PrintN("Target is current galaxy sector. Use SCAN instead.")
            Else
              player\probes - 1
              SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode, gIron, gAluminum, gCopper, gTin, gBronze)
              LogLine("PROBE: launched to " + Str(targetMapX) + "," + Str(targetMapY))
              PrintN("Launching probe to galaxy (" + Str(targetMapX) + "," + Str(targetMapY) + ")...")
              PlayProbeSound()
              PrintProbeScan(targetMapX, targetMapY)
              AdvanceStardate()
              PlayEngineSound()
              PlayAmbientChatter()
              RedrawGalaxy(@player)
            EndIf
          EndIf
        EndIf

      ElseIf cmd = "transporter"
        If gDocked
          PrintN("You are docked. Use UNDOCK first.")
        Else
          Protected transMode.s = TrimLower(TokenAt(line, 2))
          If transMode = ""
            PrintN("TRANSPORTER - Beam up resources from planet/cluster")
            PrintN("  TRANSPORTER ORE     - Beam up all ore")
            PrintN("  TRANSPORTER DILITHIUM - Beam up all dilithium")
            PrintN("  TRANSPORTER ALL     - Beam up all resources")
            If CurCell(gx, gy)\ore > 0
              PrintN("  Planet ore available: " + Str(CurCell(gx, gy)\ore))
            EndIf
            If CurCell(gx, gy)\dilithium > 0
              PrintN("  Cluster dilithium available: " + Str(CurCell(gx, gy)\dilithium))
            EndIf
          ElseIf transMode = "ore"
            TransporterBeam(@player, "ore")
          ElseIf transMode = "dilithium"
            TransporterBeam(@player, "dilithium")
          ElseIf transMode = "all"
            TransporterBeam(@player, "all")
          Else
            PrintN("Unknown transporter mode. Use: ORE, DILITHIUM, or ALL")
          EndIf
        EndIf

        CheckMissionCompletion(@player)
        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        EnemyGalaxyAI(@player, @enemyTemplate, @cs)
        AdvanceStardate()
        PlayEngineSound()
        PlayAmbientChatter()
        RedrawGalaxy(@player)
        ElseIf cmd = "refuel"
        If player\dilithium <= 0
          PrintN("No dilithium crystals to convert to fuel.")
        ElseIf player\fuel >= player\fuelMax
          PrintN("Fuel tanks already full.")
        Else
          Protected convert.i = 1
          Protected fuelNeeded.i = player\fuelMax - player\fuel
          If fuelNeeded < 10
            convert = 1
          ElseIf fuelNeeded >= 30
            convert = 3
          Else
            convert = 2
          EndIf
          If convert > player\dilithium : convert = player\dilithium : EndIf
          If convert > fuelNeeded / 10 : convert = (fuelNeeded + 9) / 10 : EndIf
          player\dilithium - convert
          player\fuel + (convert * 10)
          If player\fuel > player\fuelMax : player\fuel = player\fuelMax : EndIf
          LogLine("REFUEL: converted " + Str(convert) + " dilithium (+" + Str(convert * 10) + " fuel)")
          PrintN("Converted " + Str(convert) + " dilithium crystals to " + Str(convert * 10) + " fuel.")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "dock"
        SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode, gIron, gAluminum, gCopper, gTin, gBronze)
        If CurCell(gx, gy)\entType = #ENT_SHIPYARD
          DockAtShipyard(@player, @enemyTemplate)
          AddCaptainLog("DOCKED at shipyard")
        ElseIf CurCell(gx, gy)\entType = #ENT_BASE
          DockAtBase(@player)
          AddCaptainLog("DOCKED at starbase")
        ElseIf CurCell(gx, gy)\entType = #ENT_REFINERY
          DockAtRefinery(@player)
          AddCaptainLog("DOCKED at refinery")
        Else
          PrintN("No starbase, shipyard, or refinery in this sector.")
        EndIf

        CheckMissionCompletion(@player)
        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        EnemyGalaxyAI(@player, @enemyTemplate, @cs)
        AdvanceStardate()
        PlayEngineSound()
        PlayAmbientChatter()
        RedrawGalaxy(@player)
      ElseIf cmd = "undock"
        SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode, gIron, gAluminum, gCopper, gTin, gBronze)
        If gDocked = 0
          PrintN("You are not docked.")
        Else
          gDocked = 0
          PlayUndockingSound()
          ; Find an empty adjacent spot to undock to
          Protected foundEmpty.i = 0
          Protected dx.i, dy.i
          For dy = -1 To 1
            For dx = -1 To 1
              If dx = 0 And dy = 0 : Continue : EndIf
              Protected nx.i = gx + dx
              Protected ny.i = gy + dy
              If nx >= 0 And nx < #MAP_W And ny >= 0 And ny < #MAP_H
                If gGalaxy(gMapX, gMapY, nx, ny)\entType = #ENT_EMPTY
                  gx = nx
                  gy = ny
                  foundEmpty = 1
                  Break 2
                EndIf
              EndIf
            Next
          Next
          If foundEmpty
            PrintN("Undocking...")
            AddCaptainLog("UNDOCKED from starbase")
          Else
            PrintN("Undocking... (no empty space, staying put)")
          EndIf
          StartEngineLoop()
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "recruit"
        If gDocked = 0
          PrintN("You must be docked at a starbase to recruit crew.")
        Else
          Protected recruitIdx.s = TokenAt(line, 2)
          If recruitIdx = ""
            PrintN("Usage: RECRUIT <1-3>")
            PrintN("  Shows available recruits: RECRUIT")
          Else
            Protected idx.i = ParseIntSafe(recruitIdx, 0) - 1
            If idx < 0 Or idx >= gRecruitCount
              PrintN("Invalid recruit number. Choose 1-" + Str(gRecruitCount) + ".")
            Else
              RecruitCrew(@player, idx)
              AddCaptainLog("STARBASE: recruited " + gRecruitNames(idx))
            EndIf
          EndIf
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "dismiss"
        If gDocked = 0
          PrintN("You must be docked at a starbase to dismiss crew.")
        Else
          Protected dismissRole.s = TrimLower(TokenAt(line, 2))
          If dismissRole = ""
            PrintN("Usage: DISMISS <HELM|WEAPONS|SHIELDS|ENGINEERING>")
          Else
            Protected dismissRoleId.i = 0
            If dismissRole = "helm"
              dismissRoleId = #CREW_HELM
            ElseIf dismissRole = "weapons"
              dismissRoleId = #CREW_WEAPONS
            ElseIf dismissRole = "shields"
              dismissRoleId = #CREW_SHIELDS
            ElseIf dismissRole = "engineering"
              dismissRoleId = #CREW_ENGINEERING
            Else
              PrintN("Invalid role. Use: HELM, WEAPONS, SHIELDS, or ENGINEERING")
            EndIf
            If dismissRoleId > 0
              DismissCrew(@player, dismissRoleId)
              AddCaptainLog("STARBASE: dismissed crew member")
            EndIf
          EndIf
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "refuel"
        SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode, gIron, gAluminum, gCopper, gTin, gBronze)
        ClearConsole()
        GenerateMission(@player)
        PrintMission(@player)
        PrintN("< Press ENTER >")
        Input()
        RedrawGalaxy(@player)
      ElseIf cmd = "accept"
        GenerateMission(@player)
        AcceptMission(@player)

        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        RedrawGalaxy(@player)

      ElseIf cmd = "computer"
        ; Autopilot to mission destination (best-effort)
        AutopilotToMission(@player, @enemyTemplate, @enemy, @cs)

        CheckMissionCompletion(@player)
        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        RedrawGalaxy(@player)
      ElseIf cmd = "abandon"
        AbandonMission()
        GenerateMission(@player)

        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        RedrawGalaxy(@player)
      ElseIf cmd = "save"
        SaveGame(@player)
        RedrawGalaxy(@player)
      ElseIf cmd = "autosave"
        Protected autosaveVal.i = ParseIntSafe(TokenAt(line, 2), 0)
        If autosaveVal <= 0
          gAutosaveInterval = 0
          gAutosaveCounter = 0
          PrintN("Autosave disabled.")
        Else
          gAutosaveInterval = autosaveVal
          gAutosaveCounter = 0
          PrintN("Autosave enabled: save every " + Str(autosaveVal) + " turn(s).")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "autoclear"
        Protected autoclearVal.i = ParseIntSafe(TokenAt(line, 2), 0)
        If autoclearVal <= 0
          gAutoclearInterval = 0
          gAutoclearCounter = 0
          PrintN("Autoclear disabled.")
        Else
          gAutoclearInterval = autoclearVal
          gAutoclearCounter = 0
          PrintN("Autoclear enabled: clear every " + Str(autoclearVal) + " turn(s).")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "pack"
        If PackShipsDatFromIni()
          LogLine("SHIPDATA: packed " + gIniPath + " -> " + gDatPath)
        Else
          LogLine("SHIPDATA: pack failed (need readable " + gIniPath + ")")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "load"
        If LoadGame(@player)
          RedrawGalaxy(@player)
        Else
          RedrawGalaxy(@player)
        EndIf
      ElseIf cmd = "showmethemoney"
        gCredits + 500
        LogLine("CHEAT: showmethemoney (+500 credits)")
        PrintN("Cheat activated: +500 credits!")
        RedrawGalaxy(@player)
      ElseIf cmd = "spawnyard"
        Protected spawnX.i = -1, spawnY.i = 0
        Protected attempts.i = 0
        While attempts < 50 And spawnX = -1
          spawnX = Random(#MAP_W - 1)
          spawnY = Random(#MAP_H - 1)
          If gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_EMPTY
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_SHIPYARD
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\name = "Shipyard-" + Str(gMapX) + "-" + Str(gMapY)
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\spawned = 1
            LogLine("CHEAT: spawnyard at " + Str(spawnX) + "," + Str(spawnY))
            PrintN("Cheat activated: Shipyard spawned at sector (" + Str(spawnX) + "," + Str(spawnY) + ")!")
          Else
            spawnX = -1
          EndIf
          attempts + 1
        Wend
        If spawnX = -1
          PrintN("No empty space in sector!")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "spawnbase"
        spawnX = -1
        attempts = 0
        While attempts < 50 And spawnX = -1
          spawnX = Random(#MAP_W - 1)
          spawnY = Random(#MAP_H - 1)
          If gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_EMPTY
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_BASE
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\name = "Starbase-" + Str(gMapX) + "-" + Str(gMapY)
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\spawned = 1
            LogLine("CHEAT: spawnbase at " + Str(spawnX) + "," + Str(spawnY))
            PrintN("Cheat activated: Starbase spawned at sector (" + Str(spawnX) + "," + Str(spawnY) + ")!")
          Else
            spawnX = -1
          EndIf
          attempts + 1
        Wend
        If spawnX = -1
          PrintN("No empty space in sector!")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "spawnrefinery"
        spawnX = -1
        attempts = 0
        While attempts < 50 And spawnX = -1
          spawnX = Random(#MAP_W - 1)
          spawnY = Random(#MAP_H - 1)
          If gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_EMPTY
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_REFINERY
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\name = "Refinery-" + Str(gMapX) + "-" + Str(gMapY)
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\spawned = 1
            LogLine("CHEAT: spawnrefinery at " + Str(spawnX) + "," + Str(spawnY))
            PrintN("Cheat activated: Refinery spawned at sector (" + Str(spawnX) + "," + Str(spawnY) + ")!")
          Else
            spawnX = -1
          EndIf
          attempts + 1
        Wend
        If spawnX = -1
          PrintN("No empty space in sector!")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "spawncluster"
        spawnX = -1
        attempts = 0
        While attempts < 50 And spawnX = -1
          spawnX = Random(#MAP_W - 1)
          spawnY = Random(#MAP_H - 1)
          If gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_EMPTY
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_DILITHIUM
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\name = "Dilithium Cluster"
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\richness = 5 + Random(10)
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\spawned = 1
            LogLine("CHEAT: spawncluster at " + Str(spawnX) + "," + Str(spawnY))
            PrintN("Cheat activated: Dilithium cluster spawned at sector (" + Str(spawnX) + "," + Str(spawnY) + ")!")
          Else
            spawnX = -1
          EndIf
          attempts + 1
        Wend
        If spawnX = -1
          PrintN("No empty space in sector!")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "spawnwormhole"
        spawnX = -1
        attempts = 0
        While attempts < 50 And spawnX = -1
          spawnX = Random(#MAP_W - 1)
          spawnY = Random(#MAP_H - 1)
          If gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_EMPTY
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_WORMHOLE
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\name = "Wormhole"
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\spawned = 1
            LogLine("CHEAT: spawnwormhole at " + Str(spawnX) + "," + Str(spawnY))
            PrintN("Cheat activated: Wormhole spawned at sector (" + Str(spawnX) + "," + Str(spawnY) + ")!")
          Else
            spawnX = -1
          EndIf
          attempts + 1
        Wend
        If spawnX = -1
          PrintN("No empty space in sector!")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "spawnanomaly"
        spawnX = -1
        attempts = 0
        While attempts < 50 And spawnX = -1
          spawnX = Random(#MAP_W - 1)
          spawnY = Random(#MAP_H - 1)
          If gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_EMPTY
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_ANOMALY
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\name = "Spatial Anomaly"
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\spawned = 1
            LogLine("CHEAT: spawnanomaly at " + Str(spawnX) + "," + Str(spawnY))
            PrintN("Cheat activated: Anomaly spawned at sector (" + Str(spawnX) + "," + Str(spawnY) + ")!")
          Else
            spawnX = -1
          EndIf
          attempts + 1
        Wend
        If spawnX = -1
          PrintN("No empty space in sector!")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "spawnplanetkiller"
        spawnX = -1
        attempts = 0
        While attempts < 50 And spawnX = -1
          spawnX = Random(#MAP_W - 1)
          spawnY = Random(#MAP_H - 1)
          If gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_EMPTY
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\entType = #ENT_PLANETKILLER
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\name = "Planet Killer"
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\spawned = 1
            LogLine("CHEAT: spawnplanetkiller at " + Str(spawnX) + "," + Str(spawnY))
            PrintN("Cheat activated: Planet Killer spawned at sector (" + Str(spawnX) + "," + Str(spawnY) + ")!")
          Else
            spawnX = -1
          EndIf
          attempts + 1
        Wend
        If spawnX = -1
          PrintN("No empty space in sector!")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "removespawn"
        If CurCell(gx, gy)\spawned = 1
          Protected removedType.i = CurCell(gx, gy)\entType
          CurCell(gx, gy)\entType = #ENT_EMPTY
          CurCell(gx, gy)\name = ""
          CurCell(gx, gy)\spawned = 0
          Select removedType
            Case #ENT_BASE
              PrintN("Spawned starbase removed.")
            Case #ENT_SHIPYARD
              PrintN("Spawned shipyard removed.")
            Case #ENT_DILITHIUM
              PrintN("Spawned dilithium cluster removed.")
            Case #ENT_WORMHOLE
              PrintN("Spawned wormhole removed.")
            Case #ENT_ANOMALY
              PrintN("Spawned anomaly removed.")
            Case #ENT_PLANETKILLER
              PrintN("Spawned Planet Killer removed.")
          EndSelect
          LogLine("CHEAT: removespawn at " + Str(gx) + "," + Str(gy))
        Else
          PrintN("No spawned object here to remove.")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "quit" Or cmd = "exit"
        Protected quitConfirm.i = MessageRequester("Starship Sim", "Are you sure you want to exit?", #PB_MessageRequester_YesNo)
        If quitConfirm = #PB_MessageRequester_Yes
          CloseConsole()
          End
        Else
          RedrawGalaxy(@player)
        EndIf
      ElseIf cmd = "end"
        ; no-op
      Else
        LogLine("Unknown: " + cmd)
        RedrawGalaxy(@player)
      EndIf

      ; Handle autoclear and autosave (run even if mode changed to tactical during command)
      If gAutoclearInterval > 0
        gAutoclearCounter + 1
        If gAutoclearCounter >= gAutoclearInterval
          ClearLog()
          ClearConsole()
          RedrawGalaxy(@player)
          gAutoclearCounter = 0
        EndIf
      EndIf
      
      If gAutosaveInterval > 0
        gAutosaveCounter + 1
        If gAutosaveCounter >= gAutosaveInterval
          SaveGame(@player)
          LogLine("AUTOSAVE: saved at turn " + Str(gAutosaveCounter))
          gAutosaveCounter = 0
        EndIf
      EndIf

      ; Mission housekeeping after any galaxy command that consumes a turn.
      If gMode = #MODE_GALAXY
        GenerateMission(@player)
        
        ; Handle power buff expiration
        If gPowerBuff = 1
          gPowerBuffTurns - 1
          If gPowerBuffTurns <= 0
            gPowerBuff = 0
            LogLine("POWERBUFF: expired")
            PrintN("The power overwhelming buff has expired.")
          EndIf
        EndIf
        
        ; Handle warp cooldown
        If gWarpCooldown > 0
          gWarpCooldown - 1
        EndIf
        
        ; Handle anomaly effects
        If gIonStormTurns > 0
          gIonStormTurns - 1
        EndIf
        If gRadiationTurns > 0
          gRadiationTurns - 1
        EndIf
      EndIf

    Else
      ; Tactical mode
      If cmd = "help"
        ClearConsole()
        PrintHelpTactical()
        PrintN("")
        PrintN("< Press ENTER >")
        Input()
        PrintStatusTactical(@player, @enemy, @cs)
        Continue
      ElseIf cmd = "about"
        ClearConsole()
        PrintAbout()
        PrintN("< Press ENTER >")
        Input()
        PrintStatusTactical(@player, @enemy, @cs)
        Continue
      ElseIf cmd = "status"
        PrintStatusTactical(@player, @enemy, @cs)
        Continue
      ElseIf cmd = "scan"
        ClearConsole()
        PrintScanTactical(@player, @enemy, @cs)
        PrintN("")
        PrintN("< Press ENTER >")
        Input()
        PrintStatusTactical(@player, @enemy, @cs)
        Continue
      ElseIf cmd = "alloc"
        Protected pctShields.i = ParseIntSafe(TokenAt(line, 4), player\allocShields)
        Protected pctWeapons.i = ParseIntSafe(TokenAt(line, 3), player\allocWeapons)
        Protected pctEngines.i = ParseIntSafe(TokenAt(line, 2), player\allocEngines)

        pctShields = ClampInt(pctShields, 0, 100)
        pctWeapons = ClampInt(pctWeapons, 0, 100)
        pctEngines = ClampInt(pctEngines, 0, 100)

        If pctShields + pctWeapons + pctEngines > 100
          PrintN("Allocation sum must be <= 100.")
        ElseIf TokenAt(line, 2) = ""
          PrintN("Current: Engines=" + Str(player\allocEngines) + " | Weapons=" + Str(player\allocWeapons) + " | Shields=" + Str(player\allocShields))
        Else
          player\allocShields = pctShields
          player\allocWeapons = pctWeapons
          player\allocEngines = pctEngines
          SaveAlloc("PlayerShip", @player)
          PrintN("Allocation set: Engines=" + Str(player\allocEngines) + " | Weapons=" + Str(player\allocWeapons) + " | Shields=" + Str(player\allocShields))
        EndIf
        PrintStatusTactical(@player, @enemy, @cs)
        Continue
      ElseIf cmd = "move"
        Protected moveDir.s = TokenAt(line, 2)
        Protected moveAmt.i = ParseIntSafe(TokenAt(line, 3), 2)
        PlayerMove(@player, @cs, moveDir, moveAmt)
        PrintStatusTactical(@player, @enemy, @cs)
      ElseIf cmd = "phaser"
        Protected pwr.i = ParseIntSafe(TokenAt(line, 2), 30)
        PlayerPhaser(@player, @enemy, @cs, pwr)
        
        ; Check if player wants to target fleet
        Protected phaserTarget.s = TokenAt(line, 3)
        If phaserTarget = "fleet" And gEnemyFleetCount > 0
          Protected pfHit.i = Random(gEnemyFleetCount) + 1
          If gEnemyFleet(pfHit)\hull > 0
            Protected pfDmg.i = Random(pwr / 2) + 5
            gEnemyFleet(pfHit)\hull - pfDmg
            cs\eFleetHit = cs\eFleetHit | (1 << (pfHit - 1))  ; Mark enemy fleet ship as hit
            PrintN("Phasers hit enemy fleet ship " + Str(pfHit) + " for " + Str(pfDmg) + " damage!")
            If gEnemyFleet(pfHit)\hull <= 0
              PrintN("Enemy fleet ship " + Str(pfHit) + " destroyed!")
              Protected efCompact1.i
              For efCompact1 = pfHit To gEnemyFleetCount - 1
                CopyStructure(@gEnemyFleet(efCompact1 + 1), @gEnemyFleet(efCompact1), Ship)
              Next
              gEnemyFleetCount - 1
            EndIf
          EndIf
        EndIf
        
        PrintStatusTactical(@player, @enemy, @cs)
        
        If enemy\hull <= 0
          PrintN("Enemy destroyed!")
          Goto HandleEnemyDestroyed
        EndIf
      ElseIf cmd = "torpedo"
        Protected cnt.i = ParseIntSafe(TokenAt(line, 2), 1)
        PlayerTorpedo(@player, @enemy, @cs, cnt)
        
        ; Check if player wants to target fleet
        Protected torpTarget.s = TokenAt(line, 3)
        If torpTarget = "fleet" And gEnemyFleetCount > 0
          Protected tfHit.i = Random(gEnemyFleetCount) + 1
          If gEnemyFleet(tfHit)\hull > 0
            Protected tfDmg.i = Random(50) + 30
            gEnemyFleet(tfHit)\hull - tfDmg
            cs\eFleetHit = cs\eFleetHit | (1 << (tfHit - 1))  ; Mark enemy fleet ship as hit
            PrintN("Torpedo hits enemy fleet ship " + Str(tfHit) + " for " + Str(tfDmg) + " damage!")
            If gEnemyFleet(tfHit)\hull <= 0
              PrintN("Enemy fleet ship " + Str(tfHit) + " destroyed!")
              Protected efCompact2.i
              For efCompact2 = tfHit To gEnemyFleetCount - 1
                CopyStructure(@gEnemyFleet(efCompact2 + 1), @gEnemyFleet(efCompact2), Ship)
              Next
              gEnemyFleetCount - 1
            EndIf
          EndIf
        EndIf
        
        ; Player's fleet attacks automatically after player fires (BEFORE display so color shows)
        If gPlayerFleetCount > 0 And enemy\hull > 0
          Protected pf.i
          For pf = 1 To gPlayerFleetCount
            If gPlayerFleet(pf)\hull > 0
              pfDmg.i = Random(25) + 5
              cs\pFleetAttack = cs\pFleetAttack | (1 << (pf - 1))
              PlaySoundFX(SoundPhaser)
              If Random(99) < 50
                enemy\shields - pfDmg
                If enemy\shields < 0
                  enemy\hull + enemy\shields
                  enemy\shields = 0
                EndIf
                PrintN("Fleet ship " + Str(pf) + " fires at enemy! " + Str(pfDmg) + " damage!")
              Else
                PrintN("Fleet ship " + Str(pf) + " fires but misses!")
              EndIf
            EndIf
          Next
        EndIf
        
        PrintStatusTactical(@player, @enemy, @cs)
        
        If enemy\hull <= 0
          PrintN("Enemy destroyed!")
          Goto HandleEnemyDestroyed
        EndIf
      ElseIf cmd = "tractor"
        Protected tractorMode.s = TokenAt(line, 2)
        If tractorMode = ""
          PrintN("Usage: TRACTOR <HOLD|PULL|PUSH>")
          PrintN("  HOLD - lock enemy in place (1 fuel/turn)")
          PrintN("  PULL - pull enemy closer   (1 dilithium or fuel)")
          Continue
        EndIf
        PlayerTractor(@player, @enemy, @cs, tractorMode)
      ElseIf cmd = "transporter"
        Protected trMode.s = TokenAt(line, 2)
        
        ; Check if range is close enough
        If cs\range > gTransporterRange
          PrintN("Target out of transporter range! Range: " + Str(gTransporterRange) + ", Enemy distance: " + Str(cs\range))
          PrintStatusTactical(@player, @enemy, @cs)
          Continue
        EndIf
        
        If trMode = ""
          PrintN("TRANSPORTER - Away team combat boarding")
          PrintN("  TRANSPORTER ATTACK - Send away team to capture enemy ship")
          PrintN("  Requires: transporter range, crew")
          PrintN("  Power: " + Str(gTransporterPower) + " | Range: " + Str(gTransporterRange) + " | Crew: " + Str(gTransporterCrew))
          PrintN("  Enemy distance: " + Str(cs\range))
          PrintStatusTactical(@player, @enemy, @cs)
          Continue
        ElseIf trMode = "attack" Or trMode = "away"
          ; Calculate success chance
          Protected attackRoll.i = Random(99) + 1
          Protected successChance.i = gTransporterPower + (gTransporterCrew * 10) - (cs\range * 5)
          successChance = ClampInt(successChance, 10, 95)
          
          PrintN("Away team beamed over!")
          PrintN("Team size: " + Str(gTransporterCrew) + " | Power: " + Str(gTransporterPower) + " | Success chance: " + Str(successChance) + "%")
          
          If attackRoll <= successChance
            ; Success - damage enemy and maybe capture
            Protected dmgToEnemy.i = gTransporterPower + (gTransporterCrew * 15) + Random(30)
            enemy\hull - dmgToEnemy
            If enemy\hull < 0 : enemy\hull = 0 : EndIf
            PrintN("Away team attacks! " + Str(dmgToEnemy) + " damage to enemy!")
            PlaySoundEffect("ENGAGE")
            
            ; Chance to disable enemy systems
            If Random(99) < 40
              Protected sysRoll.i = Random(2)
              Select sysRoll
                Case 0
                  enemy\sysWeapons = #SYS_DAMAGED
                  PrintN("Away team damaged enemy weapons!")
                Case 1
                  enemy\sysShields = #SYS_DAMAGED
                  PrintN("Away team damaged enemy shields!")
                Case 2
                  enemy\sysEngines = #SYS_DAMAGED
                  PrintN("Away team damaged enemy engines!")
              EndSelect
            EndIf
            
            ; Chance to capture
            If enemy\hull < enemy\hullMax / 4 And Random(99) < 30
              Protected shipValue.i = enemy\hullMax * 10 + Random(500)
              gCredits + shipValue
              PrintN("Away team captured the enemy ship for " + Str(shipValue) + " credits!")
              AddCaptainLog("CAPTURED enemy ship " + enemy\name + " for " + Str(shipValue) + " credits!")
              enemy\hull = 0
            EndIf
            
            LogLine("TRANSPORTER: away team attacked, " + Str(dmgToEnemy) + " dmg")
          Else
            PrintN("Away team failed to damage the enemy!")
            LogLine("TRANSPORTER: away team failed")
          EndIf
          
          If enemy\hull <= 0
            PrintN("Enemy destroyed!")
            Goto HandleEnemyDestroyed
          EndIf
        Else
          PrintN("Unknown transporter command. Use: TRANSPORTER ATTACK")
        EndIf
      ElseIf cmd = "shuttle" Or cmd = "launchshuttle"
        Protected shutMode.s = TrimLower(TokenAt(line, 2))
        If gShuttleLaunched = 0
          PrintN("Shuttle is not launched. Use LAUNCHSHUTTLE LAUNCH from galaxy mode first.")
        ElseIf shutMode = ""
          PrintN("SHUTTLE - Shuttle combat operations")
          PrintN("  SHUTTLE ATTACK - Launch shuttle attack on enemy ship")
          PrintN("  SHUTTLE INFO   - Show shuttle status")
          PrintN("  Current: Crew=" + Str(gShuttleCrew) + " Cargo Ore=" + Str(gShuttleCargoOre) + " Dilithium=" + Str(gShuttleCargoDilithium))
        ElseIf shutMode = "attack" Or shutMode = "assault"
          If cs\range > gShuttleAttackRange
            PrintN("Enemy too far for shuttle attack! Range: " + Str(cs\range) + " (max " + Str(gShuttleAttackRange) + ")")
          ElseIf gShuttleCrew < 1
            PrintN("No crew in shuttle!")
          Else
            Protected shutPower.i = (gShuttleCrew * 40) + Random(50)
            enemy\hull - shutPower
            If enemy\hull < 0 : enemy\hull = 0 : EndIf
            PrintN("Shuttle attack! " + Str(shutPower) + " damage to enemy!")
            PlaySoundEffect("ENGAGE")
            If Random(99) < 25
              Protected sysHit.i = Random(2)
              Select sysHit
                Case 0
                  enemy\sysWeapons = #SYS_DAMAGED
                  PrintN("Shuttle damaged enemy weapons systems!")
                Case 1
                  enemy\sysShields = #SYS_DAMAGED
                  PrintN("Shuttle damaged enemy shield generators!")
                Case 2
                  enemy\sysEngines = #SYS_DAMAGED
                  PrintN("Shuttle damaged enemy engines!")
              EndSelect
            EndIf
            If enemy\hull <= 0
              PrintN("Enemy destroyed!")
              Goto HandleEnemyDestroyed
            EndIf
          EndIf
        ElseIf shutMode = "info"
          PrintN("Shuttle Status:")
          PrintN("  Crew: " + Str(gShuttleCrew) + "/" + Str(gShuttleMaxCrew) + " | Attack Range: " + Str(gShuttleAttackRange))
          PrintN("  Cargo: Ore=" + Str(gShuttleCargoOre) + "/" + Str(gShuttleMaxCargo) + " | Dilithium=" + Str(gShuttleCargoDilithium) + "/" + Str(gShuttleMaxCargo))
        Else
          PrintN("Unknown shuttle command. Use SHUTTLE for help.")
        EndIf
      ElseIf cmd = "flee"
        If player\fuel <= 0
          PrintN("Fuel depleted. Cannot flee.")
        ElseIf Random(99) < ClampInt(18 + (cs\range * 2), 15, 65)
          player\fuel - 1
          PrintN("You disengage and escape to the galaxy map.")
          LeaveCombat()
          RedrawGalaxy(@player)
          Continue
        Else
          PrintN("Flee attempt fails.")
        EndIf
        PrintStatusTactical(@player, @enemy, @cs)
      ElseIf cmd = "end"
        ; Player's fleet attacks enemy
        If gPlayerFleetCount > 0 And enemy\hull > 0
          For pf = 1 To gPlayerFleetCount
            If gPlayerFleet(pf)\hull > 0
              pfDmg.i = Random(25) + 5
              cs\pFleetAttack = cs\pFleetAttack | (1 << (pf - 1))
              PlaySoundFX(SoundPhaser)
              If Random(99) < 50
                enemy\shields - pfDmg
                If enemy\shields < 0
                  enemy\hull + enemy\shields
                  enemy\shields = 0
                EndIf
                PrintN("Fleet ship " + Str(pf) + " fires at enemy! " + Str(pfDmg) + " damage!")
              Else
                PrintN("Fleet ship " + Str(pf) + " fires but misses!")
              EndIf
            EndIf
          Next
        EndIf
        
        PrintStatusTactical(@player, @enemy, @cs)
        
        ; no-op
      ElseIf cmd = "quit" Or cmd = "exit"
        CloseConsole()
        End
      Else
        PrintN("Unknown command. Type HELP.")
        Continue
      EndIf

      If gMode = #MODE_TACTICAL And IsAlive(@player) And IsAlive(@enemy)
        ; Reset fleet combat states at start of turn
        cs\pFleetAttack = 0
        cs\pFleetHit = 0
        cs\eFleetAttack = 0
        cs\eFleetHit = 0
        
        RegenAndRepair(@player, 0)
        
        ; Check if enemy already dead before AI runs
        If enemy\hull <= 0
          Goto HandleEnemyDestroyed
        EndIf
        
        RegenAndRepair(@enemy, 1)
        EnemyAI(@enemy, @player, @cs)
        
        ; Enemy fleet attacks player and player's fleet
        If gEnemyFleetCount > 0 And enemy\hull > 0
          Protected ef.i
          For ef = 1 To gEnemyFleetCount
            If gEnemyFleet(ef)\hull > 0
              Protected efDmg.i = Random(30) + 10
              cs\eFleetAttack = cs\eFleetAttack | (1 << (ef - 1))  ; Mark enemy fleet ship as attacking
              PlaySoundFX(SoundDisruptor)  ; Enemy fleet fires
              If Random(99) < 60  ; 60% chance to hit
                ; 50% chance to hit player, 50% chance to hit fleet
                If gPlayerFleetCount > 0 And Random(99) < 50
                  Protected pfTarget.i = Random(gPlayerFleetCount) + 1
                  If gPlayerFleet(pfTarget)\hull > 0
                    gPlayerFleet(pfTarget)\hull - efDmg
                    cs\pFleetHit = cs\pFleetHit | (1 << (pfTarget - 1))  ; Mark player fleet ship as hit
                    PlaySoundFX(SoundExplode)  ; Fleet ship hit!
                    PrintN("Enemy fleet ship " + Str(ef) + " fires at your fleet! " + Str(efDmg) + " damage to fleet " + Str(pfTarget) + "!")
                    If gPlayerFleet(pfTarget)\hull <= 0
                      PrintN("Your fleet ship " + Str(pfTarget) + " was destroyed!")
                      ; Compact array - shift remaining ships down
                      Protected compact.i
                      For compact = pfTarget To gPlayerFleetCount - 1
                        CopyStructure(@gPlayerFleet(compact + 1), @gPlayerFleet(compact), Ship)
                      Next
                      gPlayerFleetCount - 1
                    EndIf
                  EndIf
                Else
                  player\shields - efDmg
                  If player\shields < 0
                    player\hull + player\shields
                    player\shields = 0
                  EndIf
                  PrintN("Enemy fleet ship " + Str(ef) + " fires! " + Str(efDmg) + " damage to shields!")
                EndIf
              Else
                PrintN("Enemy fleet ship " + Str(ef) + " fires but misses!")
              EndIf
            EndIf
          Next
        EndIf
        
        PrintStatusTactical(@player, @enemy, @cs)
        
        cs\turn + 1

        If enemy\hull <= 0
          HandleEnemyDestroyed:
          PlayExplosionSound()
          PrintDivider()
          PrintN("Enemy destroyed!")
          PrintDivider()
          
          ; Log victory
          AddCaptainLog("COMBAT: Destroyed " + enemy\name)

          ; Mission: bounty progress
          If gMission\active And gMission\type = #MIS_BOUNTY
            gMission\killsDone + 1
            If gMission\killsDone >= gMission\killsRequired
              gCredits + gMission\rewardCredits
              LogLine("MISSION COMPLETE: bounty (+" + Str(gMission\rewardCredits) + " credits)")
              ClearStructure(@gMission, Mission)
              gMission\type = #MIS_NONE
            Else
              LogLine("BOUNTY: " + Str(gMission\killsDone) + "/" + Str(gMission\killsRequired))
            EndIf
          EndIf

          ; Mission: Planet Killer hunt
          If gMission\active And gMission\type = #MIS_PLANETKILLER
            gCredits + gMission\rewardCredits
            LogLine("MISSION COMPLETE: Planet Killer hunt (+" + Str(gMission\rewardCredits) + " credits)")
            ClearStructure(@gMission, Mission)
            gMission\type = #MIS_NONE
          EndIf

          ; Bonus XP for destroying Planet Killer
          If enemy\name = "Planet Killer"
            GainCrewXP(@player, #CREW_WEAPONS, 50)
            PrintN("The crew earned extra experience from defeating the Planet Killer!")
          EndIf

          If gEnemyMapX >= 0 And gEnemyMapY >= 0 And gEnemyX >= 0 And gEnemyY >= 0
            gGalaxy(gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)\entType = #ENT_EMPTY
            gGalaxy(gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)\name = ""
            gGalaxy(gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)\enemyLevel = 0
          EndIf
          player\ore = ClampInt(player\ore + (3 + Random(10)), 0, player\oreMax)
          player\torp = ClampInt(player\torp + (1 + Random(2)), 0, player\torpMax)
          
          ; Combat rewards: credits and crew XP
          Protected rewardCredits.i = 50 + Random(100) + (cs\turn * 5)
          gCredits + rewardCredits
          PrintN("You salvage " + Str(rewardCredits) + " credits from the wreckage.")
          
          ; Crew XP for all roles
          GainCrewXP(@player, #CREW_WEAPONS, 15 + cs\turn)
          GainCrewXP(@player, #CREW_HELM, 10 + cs\turn)
          GainCrewXP(@player, #CREW_ENGINEERING, 8 + cs\turn)
          GainCrewXP(@player, #CREW_SHIELDS, 5 + cs\turn)
          PrintN("Crew gains experience from the battle.")
          
          LeaveCombat()
          RedrawGalaxy(@player)
        ElseIf player\hull <= 0
          ; loop ends
        Else
          PrintStatusTactical(@player, @enemy, @cs)
        EndIf
      EndIf
    EndIf
  Wend

  PrintDivider()
  If player\hull <= 0
    PrintN("Your ship is lost.")
    gPowerBuff = 0
    gPowerBuffTurns = 0
    gPlayerFleetCount = 0
    gEnemyFleetCount = 0
  Else
    PrintN("Session ended.")
  EndIf
  StopEngineLoop()
  If gShuttleLaunched = 1
    player\ore + gShuttleCargoOre
    player\dilithium + gShuttleCargoDilithium
  EndIf
  PrintDivider()
  PrintN("< Press ENTER >")
  Input()
EndProcedure

Main()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 444
; FirstLine = 420
; Folding = ------------------------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = starship_sim.ico
; Executable = ..\Starship_Sim.exe
; IncludeVersionInfo
; VersionField0 = 1,0,8,0
; VersionField1 = 1,0,8,0
; VersionField2 = ZoneSoft
; VersionField3 = StarShip_Sim
; VersionField4 = 1.0.8.0
; VersionField5 = 1.0.8.0
; VersionField6 = A starship sim based on an old scifi TV series
; VersionField7 = StarShip_Sim
; VersionField8 = StarShip_Sim.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60