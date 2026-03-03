; - Starship simulation (PureBasic 6.30)
; - Galaxy map: planets (mining), stars (obstacles), starbases (dock)
; - Tactical combat when you encounter enemies
; - Data-driven ship stats loaded from ships.ini

EnableExplicit

#APP_NAME = "starcomm"
#EMAIL_NAME = "zonemaster60@gmail.com"
#MACRO_QUEUE_MAX = 500  ; max commands queued (large to accommodate REPEAT expansion)

Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)
Global version.s = "v1.1.5.0"

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

XIncludeFile "includes/starcomm_sound.pbi"

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
Declare.i FleetRank(*s.Ship)
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
Declare PrintCompassRow(compassRow.i)
Declare ScanGalaxy()
Declare DockAtBase(*p.Ship)
Declare DockAtRefinery(*p.Ship)
Declare DockAtShipyard(*p.Ship, *base.Ship)
Declare GenerateOneNPCShip(*ds.DockedShip, status.s, stationType.i)
Declare GenerateDockedShips(stationType.i)
Declare RefreshDockedShips()
Declare PrintDockedShips(*p.Ship)
Declare MinePlanet(*p.Ship)
Declare Nav(*p.Ship, dir.s, steps.i, *enemyTemplate.Ship = 0, *cs.CombatState = 0)
Declare EnterCombat(*p.Ship, *enemy.Ship, *cs.CombatState)
Declare LeaveCombat()

; Autopilot
Declare.i AutopilotToMission(*p.Ship, *enemyTemplate.Ship, *enemy.Ship, *cs.CombatState)
Declare.s FindPathMission(startMapX.i, startMapY.i, startX.i, startY.i, destMapX.i, destMapY.i, destX.i, destY.i, allowWormhole.i, allowBlackhole.i, allowEnemy.i)
Declare.i StepCoord(mapX.i, mapY.i, x.i, y.i, dir.s, *outMapX.Integer, *outMapY.Integer, *outX.Integer, *outY.Integer)
Declare.i IsDangerousCell(mapX.i, mapY.i, x.i, y.i)
Declare GenerateCheatCode()
Declare.i CheckCheatCode(code.s)

; Missions
Declare GenerateMission(*p.Ship)
Declare.i HQOrdersTier()
Declare GenerateHQMission(*p.Ship)
Declare PrintMission(*p.Ship)
Declare AcceptMission(*p.Ship)
Declare AbandonMission()
Declare DeliverMission(*p.Ship)
Declare CheckMissionCompletion(*p.Ship)
Declare DefendMissionTick(*p.Ship, *enemyTemplate.Ship, *enemy.Ship, *cs.CombatState)
Declare.i FindRandomCellOfType(entType.i, *outMapX.Integer, *outMapY.Integer, *outX.Integer, *outY.Integer)
Declare.s LocText(mapX.i, mapY.i, x.i, y.i)
Declare.i SaveGame(*p.Ship, slotName.s = "autosave")
Declare.i LoadGame(*p.Ship, slotName.s = "autosave")
Declare DeleteSaveGame(slotName.s)
Declare ListSaveGames()
Declare SaveGameManager(*p.Ship)


; Crew recruitment
Declare InitRecruitNames()
Declare GenerateRecruits()
Declare DismissCrew(*p.Ship, role.i)
Declare RecruitCrew(*p.Ship, index.i)
Declare.i CrewPositionFilled(*p.Ship, role.i)
Declare ShipComputerTerminal(*p.Ship)
Declare.s GetNextInput()
Declare InitMacroFolder()
Declare MacroList()
Declare MacroCreate(name.s)
Declare MacroRun(name.s)
Declare MacroChainInsert(name.s)
Declare MacroEdit(name.s)
Declare MacroDelete(name.s)
Declare MacroShow(name.s)
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
  #ENT_HQ
  #ENT_CARGO
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

; Alias for readability (same as #C_CYAN in 16-color palette)
#C_DARKCYAN = #C_CYAN

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

Structure DockedShip

  name.s
  class.s
  hull.i
  hullMax.i
  shields.i
  shieldsMax.i
  status.s    ; "Docked", "Docking...", "Undocking..."
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

Global LogPath.s   = AppPath + "logs"   + #PS$
Global DataPath.s  = AppPath + "data"   + #PS$
Global SavePath.s  = AppPath + "save"   + #PS$
Global MacroPath.s = AppPath + "macros" + #PS$

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
Global gBankBalance.i = 0  ; STARCOMM HQ Bank Balance


; Refined metals cargo
Global gIron.i = 0
Global gAluminum.i = 0
Global gCopper.i = 0
Global gTin.i = 0
Global gBronze.i = 0

Global gPowerBuff.i = 0
Global gPowerBuffTurns.i = 0
Global gCheatCode.s = ""      ; Current 4-digit cheat code
Global gCheatCodeTurn.i = 0   ; Turn when code was generated
Global gCheatsUnlocked.i = 0  ; Whether player has entered correct code
Global gGameTurn.i = 0        ; Global turn counter for cheat code generation
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
Global gEnemyIsPirate.i = 0  ; Track if current enemy is a pirate
Global gEnemyIsPlanetKiller.i = 0 ; Track if current enemy is a planet killer

; Player fleet - up to 5 computer-controlled ships
Global Dim gPlayerFleet.Ship(5)
Global gPlayerFleetCount.i = 0

; Starcomm HQ - one per game, player home base
Global gHQMapX.i = 0   ; Galaxy sector X containing HQ
Global gHQMapY.i = 0   ; Galaxy sector Y containing HQ
Global gHQX.i    = 0   ; Cell X within that sector
Global gHQY.i    = 0   ; Cell Y within that sector
; HQ standing orders and recall beacon
Global gHQMissionsCompleted.i = 0  ; HQ Priority Bounties completed
Global gRecallArmed.i         = 0  ; 1 = recall beacon is armed

; Lifetime combat record (for MANIFEST)
Global gTotalKills.i          = 0
Global gTotalMissions.i       = 0
Global gTotalCreditsEarned.i  = 0

; Compass: last NAV heading in degrees (-1 = no heading set yet)
Global gLastHeading.i = -1

; Enemy fleet - up to 5 computer-controlled ships
Global Dim gEnemyFleet.Ship(5)
Global gEnemyFleetCount.i = 0

; NPC ships docked at the current station (regenerated each visit)
Global Dim gDockedShips.DockedShip(11)
Global gDockedShipCount.i = 0
Global gStationType.i     = 0  ; 0=starbase, 1=refinery, 2=shipyard

Global gDocked.i = 0

; Macro playback queue - injected commands run via GetNextInput()
Global gMacroPlaybackActive.i = 0
Global gMacroPlaybackName.s   = ""
Global gMacroQueueSize.i      = 0
Global gMacroQueuePos.i       = 0
Global Dim gMacroQueue.s(#MACRO_QUEUE_MAX - 1)

; Refinery market system
Global gRefineryPriceBase.i = 100
Global gRefineryPriceMod.f = 1.0
Global gRefineryUpdateTurns.i = 20

; Macro conditional mirrors - updated each main-loop tick so GetNextInput() can
; check ship state without needing a pointer to the player structure.
Global gMacroFuelPct.i    = 100
Global gMacroHullPct.i    = 100
Global gMacroShieldsPct.i = 100
Global gMacroTorpCount.i  = 0
Global gMacroOre.i        = 0
Global gMacroDilithium.i  = 0
Global gMacroOreMax.i     = 0

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

Macro CurCell(x, y)
  gGalaxy(gMapX, gMapY, x, y)
EndMacro

XIncludeFile "includes/starcomm_undo.pbi"

XIncludeFile "includes/starcomm_util.pbi"

XIncludeFile "includes/starcomm_shipdata.pbi"

XIncludeFile "includes/starcomm_log.pbi"



;==============================================================================
; RedrawGalaxy(*p.Ship)
; Refreshes the galaxy display by showing:
;   - Status panel (ship info, fuel, cargo, location)
;   - Sector/galaxy map (dual-panel display)
;   - Legend for map symbols
; Called after every player command to keep display current.
;==============================================================================
XIncludeFile "includes/starcomm_display.pbi"

XIncludeFile "includes/starcomm_savegame.pbi"

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
XIncludeFile "includes/starcomm_crew.pbi"

XIncludeFile "includes/starcomm_status.pbi"

XIncludeFile "includes/starcomm_tactical.pbi"

XIncludeFile "includes/starcomm_combat.pbi"

XIncludeFile "includes/starcomm_galaxy.pbi"

XIncludeFile "includes/starcomm_missions.pbi"

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
;==============================================================================
; GenerateOneNPCShip(*ds.DockedShip, status.s, stationType.i)
; Fills a DockedShip structure with a random NPC ship name, class and stats.
; stationType: 0=starbase (mixed), 1=refinery (cargo/industrial), 2=shipyard (military)
;==============================================================================
XIncludeFile "includes/starcomm_docking.pbi"

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
XIncludeFile "includes/starcomm_nav.pbi"

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
XIncludeFile "includes/starcomm_combat2.pbi"

;==============================================================================
; InitMacroFolder()
; Creates the 'macros' folder if it doesn't already exist.
;==============================================================================
XIncludeFile "includes/starcomm_macros.pbi"

;==============================================================================
; ShipComputerTerminal(*p.Ship)
; Interactive onboard ship computer terminal accessible via the TERMINAL command.
; Provides system diagnostics, entity database, threat scanning, cargo manifest,
; command history, and colour-coded ship alerts.
; Sub-commands: HELP, STATUS, DIAG, DB <topic>, THREAT, CARGO, HISTORY, ALERTS, EXIT
;==============================================================================
XIncludeFile "includes/starcomm_terminal.pbi"

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
XIncludeFile "includes/starcomm_main.pbi"

Main()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 13
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = starcomm.ico
; Executable = ..\starcomm.exe
; IncludeVersionInfo
; VersionField0 = 1,1,5,0
; VersionField1 = 1,1,5,0
; VersionField2 = ZoneSoft
; VersionField3 = StarComm
; VersionField4 = 1.1.5.0
; VersionField5 = 1.1.5.0
; VersionField6 = A starship sim based on an old scifi TV series
; VersionField7 = StarComm
; VersionField8 = StarComm.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60