; Starship simulation (PureBasic 6.30)
; - Galaxy map: planets (mining), stars (obstacles), starbases (dock)
; - Tactical combat when you encounter enemies
; Data-driven ship stats loaded from ships.ini

EnableExplicit

#APP_NAME = "Starship_Sim"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)
Global version.s = "v1.0.2.0"

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
Declare PrintArenaFrame(posP.i, posE.i, fxPos.i, fxChar.s, beam.i, attackerIsEnemy.i)
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
  #ENT_WORMHOLE
  #ENT_BLACKHOLE
  #ENT_SUN
  #ENT_DILITHIUM
  ; Keep appended to preserve save-game entType values
  #ENT_SHIPYARD
  #ENT_ANOMALY
  #ENT_PLANETKILLER
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
  #C_LIGHTGRAY
  #C_DARKGRAY
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
EndStructure

Structure Cell
  entType.i
  name.s
  richness.i
  enemyLevel.i
  spawned.i  ; 1 if spawned by cheat, 0 otherwise
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

Global gIniPath.s = #APP_NAME + "_ships.ini"
Global gDatPath.s = #APP_NAME + "_ships.dat"
Global gUserIniPath.s = #APP_NAME + "_user.ini"
Global gSavePath.s = #APP_NAME + "_save.txt"

Global gSessionLogPath.s = #APP_NAME + "_session.log"
Global gCrashLogPath.s   = #APP_NAME + "_crash.log"
Global gLastCmdLine.s = ""

Global gShipsText.s = ""
Global gShipDataDesc.s = ""
Global gShipDatErr.s = ""

Global gCredits.i = 0
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

Global gDocked.i = 0

; Undo system - save state before each command
Global gUndoAvailable.i = 0
Global gUndoMapX.i, gUndoMapY.i, gUndoX.i, gUndoY.i
Global gUndoFuel.i, gUndoHull.i, gUndoShields.i
Global gUndoCredits.i, gUndoMode.i
Global gUndoOre.i, gUndoDilithium.i

; Autosave system
Global gAutosaveInterval.i = 0  ; 0 = disabled, otherwise save every N turns
Global gAutosaveCounter.i = 0

; Warp system
Global gWarpCooldown.i = 0  ; turns until next warp

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

; Undo system
Procedure SaveUndoState(fuel.i, hull.i, shields.i, credits.i, ore.i, dilithium.i, mapX.i, mapY.i, x.i, y.i, mode.i)
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
  gUndoAvailable = 1
EndProcedure

Procedure RestoreUndoState(*fuel.Integer, *hull.Integer, *shields.Integer, *credits.Integer, *ore.Integer, *dilithium.Integer, *mapX.Integer, *mapY.Integer, *x.Integer, *y.Integer, *mode.Integer)
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
  gShipsText + "AllocShields=40" + Chr(10)
  gShipsText + "AllocWeapons=40" + Chr(10)
  gShipsText + "AllocEngines=20" + Chr(10)
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
  gShipsText + "AllocShields=35" + Chr(10)
  gShipsText + "AllocWeapons=45" + Chr(10)
  gShipsText + "AllocEngines=20" + Chr(10)
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

Procedure ClearLog()
  Protected n.i = ArraySize(gLog()) + 1
  Protected i.i
  For i = 0 To n - 1
    gLog(i) = ""
  Next
  gLogPos = 0
EndProcedure

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
  ConsoleColor(#C_LIGHTGRAY, #C_BLACK)
EndProcedure

Procedure ResetColor()
  ConsoleColor(#C_LIGHTGRAY, #C_BLACK)
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
  ConsoleColor(#C_WHITE, #C_BLACK) : Print("@") : ResetColor() : Print("=You ")
  ConsoleColor(#C_DARKGRAY, #C_BLACK) : Print(".") : ResetColor() : Print("=Empty ")
  ConsoleColor(#C_LIGHTBLUE, #C_BLACK) : Print("O") : ResetColor() : Print("=Planet ")
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("*") : ResetColor() : Print("=Star(blocked)")
  PrintN("")
  Print(indent)
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK) : Print("%") : ResetColor() : Print("=Base ")
  ConsoleColor(#C_GREEN, #C_BLACK) : Print("+") : ResetColor() : Print("=Shipyard ")
  ConsoleColor(#C_LIGHTRED, #C_BLACK) : Print("E") : ResetColor() : Print("=Enemy ")
  ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK) : Print("#") : ResetColor() : Print("=Wormhole")
  PrintN("")
  Print(indent)
  ConsoleColor(#C_WHITE, #C_BLACK) : Print("?") : ResetColor() : Print("=BlackHole ")
  ConsoleColor(#C_BROWN, #C_BLACK) : Print("S") : ResetColor() : Print("=Sun(blocked) ")
  ConsoleColor(#C_MAGENTA, #C_BLACK) : Print("D") : ResetColor() : Print("=Dilithium ")
  ConsoleColor(#C_LIGHTBLUE, #C_BLACK) : Print("A") : ResetColor() : PrintN("=Anomaly")
  Print(indent)
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK) : Print("<") : ResetColor() : PrintN("=Planet Killer")
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
  PrintCmd("CREW")
  PrintN("    Show crew members and their experience")
  PrintN("")
  PrintCmd("MAP")
  PrintN("    Show the sector map")
  PrintN("    Legend:")
  PrintLegendLine("      ")
  PrintN("    M=Mission map   !=Mission target")
  PrintN("")
  PrintCmd("CLEAR")
  PrintN("    Clear console and refresh the galaxy map")
  PrintN("")
  PrintCmd("UNDO")
  PrintN("    Undo last command (restore position and resources)")
  PrintN("    Useful if you get sucked into a black hole or sun!")
  PrintN("")
  PrintCmd("SCAN")
  PrintN("    Show non-empty contents of adjacent sectors")
  PrintN("")
  PrintCmd("LONGSCAN")
  PrintN("    Long range scan - shows sectors within 2 steps")
  PrintN("")
  PrintCmd("NAV <N|S|E|W|NW|NE|SW|SE> [steps]")
  PrintN("    Move 1-5 sectors, costs 1 fuel per step")
  PrintN("    Crossing the sector-map edge moves to the next map in the galaxy")
  PrintN("    Examples: NAV N     | NAV E 3 | NAV NW 2 | NAV SE")
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
  PrintCmd("REFUEL")
  PrintN("    Convert dilithium crystals to fuel (10 fuel per crystal)")
  PrintN("    Example: REFUEL")
  PrintN("")
  PrintCmd("DOCK")
  PrintN("    Dock when in a starbase (%) or shipyard (+): repair/refuel/rearm")
  PrintN("    Shipyards also offer upgrades")
  PrintN("    Example: DOCK")
  PrintN("")
  PrintCmd("UNDOCK")
  PrintN("    Undock from a starbase or shipyard to resume flying")
  PrintN("    Example: UNDOCK")
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
  PrintN("Notes:")
  PrintN("    Deliver missions complete when you DOCK at the destination base.")
  PrintN("    Survey missions complete when you SCAN while at the destination planet.")
  PrintN("")
  PrintN("Combat:")
  PrintN("    Enemies are marked E. Moving into an enemy sector enters tactical mode.")
  PrintN("    In tactical mode, type HELP for PHASER/TORPEDO/MOVE/ALLOC/FLEE.")
  PrintN("")
  PrintN("Hazards:")
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
        *p\allocShields= Val(StringField(line, 24, "|"))
        *p\allocWeapons= Val(StringField(line, 25, "|"))
        *p\allocEngines= Val(StringField(line, 26, "|"))
        *p\sysEngines  = Val(StringField(line, 27, "|"))
        *p\sysWeapons  = Val(StringField(line, 28, "|"))
        *p\sysShields  = Val(StringField(line, 29, "|"))
        ; Backward compatibility: ensure dilithium fields exist
        If *p\dilithiumMax <= 0 : *p\dilithiumMax = 20 : EndIf
        If *p\dilithium > *p\dilithiumMax : *p\dilithium = *p\dilithiumMax : EndIf
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
  PrintCmd("ALLOC <shields%> <weapons%> <engines%>")
  PrintN("    Set reactor allocation; sum must be <= 100")
  PrintN("    Examples: ALLOC 50 30 20 | ALLOC 40 40 20")
  PrintN("")
  PrintCmd("MOVE <APPROACH|RETREAT|HOLD> [amount]")
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
  PrintN("    Example: TRACTOR HOLD | TRACTOR PULL | TRACTOR PUSH")
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
  Print("Helm Lv" + Str(*s\crew1\level))
  Protected xpNeed1.i = *s\crew1\level * 100
  Print(" XP: " + Str(*s\crew1\xp) + "/" + Str(xpNeed1))
  PrintN("")
  
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  Print("  " + *s\crew2\name + " [" + RankName(*s\crew2\rank) + "] ")
  ResetColor()
  Print("Weapons Lv" + Str(*s\crew2\level))
  Protected xpNeed2.i = *s\crew2\level * 100
  Print(" XP: " + Str(*s\crew2\xp) + "/" + Str(xpNeed2))
  PrintN("")
  
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  Print("  " + *s\crew3\name + " [" + RankName(*s\crew3\rank) + "] ")
  ResetColor()
  Print("Shields Lv" + Str(*s\crew3\level))
  Protected xpNeed3.i = *s\crew3\level * 100
  Print(" XP: " + Str(*s\crew3\xp) + "/" + Str(xpNeed3))
  PrintN("")
  
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  Print("  " + *s\crew4\name + " [" + RankName(*s\crew4\rank) + "] ")
  ResetColor()
  Print("Engineering Lv" + Str(*s\crew4\level))
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

Procedure PrintStatusGalaxy(*p.Ship)
  PrintDivider()
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
  PrintN(Str(*p\torp))
  ResetColor()
  PrintN("  Systems: Engines " + SysText(*p\sysEngines) + ", Weapons " + SysText(*p\sysWeapons) + ", Shields " + SysText(*p\sysShields))
  PrintCrew(*p)
  PrintDivider()
EndProcedure

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
  Print("  Fuel: ")
  SetColorForPercent(Int(100.0 * *p\fuel / ClampInt(*p\fuelMax, 1, 999999)))
  PrintN(Str(*p\fuel))
  ResetColor()
  PrintN("  Alloc: S " + Str(*p\allocShields) + "%  W " + Str(*p\allocWeapons) + "%  E " + Str(*p\allocEngines) + "%")
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
  PrintArenaFrame(posP\i, posE\i, -1, "", 0, 0)
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

Procedure PrintArenaFrame(posP.i, posE.i, fxPos.i, fxChar.s, beam.i, attackerIsEnemy.i)
  ; Draws a 5-row arena with optional effect: either a beam line or a single character.
  ; attackerIsEnemy: 0 = player, 1 = enemy
  ; Player phaser: cyan '=' | Player torpedo: yellow '*'
  ; Enemy disruptor: red '-' | Enemy torpedo: green '*'
  Protected aw.i = 33
  Protected interior.i = aw - 2
  Protected rowMid.i = 2

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
        Print("E")
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
  PrintArenaFrame(posP\i, posE\i, -1, "", 1, attackerIsEnemy)
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
  PrintArenaFrame(posP\i, posE\i, fx, "*", 0, attackerIsEnemy)
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

Procedure ApplyDamage(*target.Ship, dmg.i)
  If dmg <= 0 : ProcedureReturn : EndIf

  If *target\shields > 0 And ((*target\sysShields & #SYS_DISABLED) = 0)
    Protected sHit.i = dmg
    If sHit > *target\shields : sHit = *target\shields : EndIf
    *target\shields - sHit
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

Procedure RegenAndRepair(*s.Ship, isEnemy.i)
  Protected reactor.i = *s\reactorMax
  Protected shP.i = reactor * *s\allocShields / 100
  Protected wP.i  = reactor * *s\allocWeapons / 100
  
  shP + CrewBonus(*s, #CREW_SHIELDS)
  wP + CrewBonus(*s, #CREW_ENGINEERING)

  If isEnemy
    ; Enemies regenerate/repair less so fights don't drag.
    shP = Int(shP * 0.55)
    wP  = Int(wP  * 0.55)
  EndIf

  If (*s\sysShields & #SYS_DISABLED) = 0
    If (*s\sysShields & #SYS_DAMAGED) : shP / 2 : EndIf
    If isEnemy
      *s\shields + (shP / 4)
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

  TacticalFxPhaser(*cs\range, 0)

  Protected chance.i = HitChance(*cs\range, *p, *e) + *cs\pAim
  If Random(99) < chance
    Protected base.i = (power / 3) + Random(ClampInt(power / 3, 0, 999999))
    If base < 1 : base = 1 : EndIf

    Protected falloff.f = 1.0 - (*cs\range / 55.0)
    falloff = ClampF(falloff, 0.25, 1.0)
    Protected dmg.i = Int(base * falloff)
    If dmg < 1 : dmg = 1 : EndIf

    ApplyDamage(*e, dmg)
    PrintN("Phasers hit! (" + Str(dmg) + ").")
    *cs\pAim = 0
    GainCrewXP(*p, #CREW_WEAPONS, 5 + dmg / 10)
  Else
    PrintN("Phasers miss.")
    *cs\pAim = ClampInt(*cs\pAim + 7, 0, 28)
  EndIf
EndProcedure

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

    TacticalFxTorpedo(*cs\range, 0)
    ; Torpedoes are more reliable at close range, less at long range.
    Protected chance.i = HitChance(*cs\range, *p, *e) + 10 - Int(*cs\range / 2) + *cs\pAim
    chance = ClampInt(chance, 20, 95)
    If Random(99) < chance
      Protected dmg.i = 44 + Random(34)
      If *cs\range > 20 : dmg - 6 : EndIf
      If dmg < 1 : dmg = 1 : EndIf

      ; Torpedoes partially punch through shields to prevent endless shield regen stalemates.
      Protected shieldDmg.i = dmg
      Protected hullDmg.i = dmg / 5
      If hullDmg < 1 : hullDmg = 1 : EndIf

      ApplyDamage(*e, shieldDmg)
      If *e\hull > 0
        *e\hull - hullDmg
        If *e\hull < 0 : *e\hull = 0 : EndIf
      EndIf
      PrintN("Torpedo impact! (" + Str(dmg) + ", +" + Str(hullDmg) + " hull breach).")
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
    
    Protected chance.i = HitChance(*cs\range, *e, *p) + *cs\eAim
    If Random(99) < chance
      Protected base.i = (phaserPower / 3) + Random(ClampInt(phaserPower / 3, 0, 999999))
      If base < 1 : base = 1 : EndIf
      Protected falloff.f = 1.0 - (*cs\range / 55.0)
      falloff = ClampF(falloff, 0.25, 1.0)
      Protected dmg.i = Int(base * falloff)
      If dmg < 1 : dmg = 1 : EndIf
      
      ApplyDamage(*p, dmg)
      PrintN("Enemy fires disruptors! (" + Str(dmg) + ")")
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
      
      Protected torpChance.i = HitChance(*cs\range, *e, *p) + 10 - Int(*cs\range / 2) + *cs\eAim
      torpChance = ClampInt(torpChance, 20, 95)
      If Random(99) < torpChance
        Protected torpDmg.i = 40 + Random(30)
        If *cs\range > 20 : torpDmg - 6 : EndIf
        If torpDmg < 1 : torpDmg = 1 : EndIf
        
        Protected shieldDmg.i = torpDmg
        Protected hullDmg.i = torpDmg / 5
        If hullDmg < 1 : hullDmg = 1 : EndIf
        
        ApplyDamage(*p, shieldDmg)
        If *p\hull > 0
          *p\hull - hullDmg
          If *p\hull < 0 : *p\hull = 0 : EndIf
        EndIf
        PrintN("Enemy torpedo impact! (" + Str(torpDmg) + ", +" + Str(hullDmg) + " hull breach).")
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
    Case #ENT_SHIPYARD: ProcedureReturn "+"
    Case #ENT_WORMHOLE: ProcedureReturn "#"
    Case #ENT_BLACKHOLE: ProcedureReturn "?"
    Case #ENT_SUN: ProcedureReturn "S"
    Case #ENT_DILITHIUM: ProcedureReturn "D"
    Case #ENT_ANOMALY: ProcedureReturn "A"
    Case #ENT_PLANETKILLER: ProcedureReturn "<"
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

          SetColorForEnt(CurCell(x, row)\entType)
          Print(EntSymbol(CurCell(x, row)\entType) + " ")
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
  PrintN("weapons rearmed, fuel refilled.")
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
  *p\sysEngines = #SYS_OK
  *p\sysWeapons = #SYS_OK
  *p\sysShields = #SYS_OK
  LogLine("DOCK: refueled, rearmed, and repaired")

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
    LogLine("MINE: +" + Str(dpull) + " dilithium")
    PrintN("Mined " + Str(dpull) + " dilithium crystals.")
  Else
    PrintN("No mineable resource in this sector (need Planet O or Dilithium D).")
  EndIf
EndProcedure

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
    PrintN("D) Dilithium Bay   (+10 DilithiumMax) cost 90")
    PrintN("E) Cargo Hold      (+20 OreMax)       cost 80")
    PrintN("")
    PrintN("0) Leave")
    PrintN("")
    PrintN("CHEATS (type number/letter or word):")
    PrintN("  showmethemoney = +500 credits")
    PrintN("  poweroverwhelming = all stats x2 for 30 turns")
    Print("")
    Print("YARD> ")
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
        LogLine("UPGRADE: hull +20 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "2"
        cost = 100
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\hullMax = ClampInt(*p\hullMax + 15, 10, 800)
        *p\hull = *p\hullMax
        LogLine("UPGRADE: armor +15 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "3"
        cost = 140
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\shieldsMax = ClampInt(*p\shieldsMax + 20, 0, 800)
        *p\shields = *p\shieldsMax
        LogLine("UPGRADE: shields +20 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "4"
        cost = 110
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\shieldsMax = ClampInt(*p\shieldsMax + 15, 0, 800)
        *p\shields = *p\shieldsMax
        LogLine("UPGRADE: emitters +15 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "5"
        cost = 160
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\phaserBanks = ClampInt(*p\phaserBanks + 1, 0, 30)
        LogLine("UPGRADE: phasers +1 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "6"
        cost = 110
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\torpMax = ClampInt(*p\torpMax + 4, 0, 80)
        *p\torp = ClampInt(*p\torp + 4, 0, *p\torpMax)
        LogLine("UPGRADE: torpMax +4 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "7"
        cost = 200
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\torpTubes = ClampInt(*p\torpTubes + 1, 1, 6)
        If *p\torpTubes > *p\torpMax : *p\torpTubes = *p\torpMax : EndIf
        LogLine("UPGRADE: tubes +1 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "8"
        cost = 130
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\sensorRange = ClampInt(*p\sensorRange + 5, 1, 60)
        LogLine("UPGRADE: sensors +5 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "9"
        cost = 250
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\warpMax = ClampF(*p\warpMax + 1.0, 0.0, 12.0)
        LogLine("UPGRADE: warp +1.0 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "a"
        cost = 150
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\impulseMax = ClampF(*p\impulseMax + 0.3, 0.0, 2.5)
        LogLine("UPGRADE: impulse +0.3 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "b"
        cost = 100
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\fuelMax = ClampInt(*p\fuelMax + 25, 10, 600)
        *p\fuel = *p\fuelMax
        LogLine("UPGRADE: fuel +25 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "c"
        cost = 180
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\reactorMax = ClampInt(*p\reactorMax + 30, 50, 900)
        *p\weaponCapMax = ClampInt(*p\weaponCapMax + 30, 10, 1400)
        *p\weaponCap = ClampInt(*p\weaponCap, 0, *p\weaponCapMax)
        LogLine("UPGRADE: reactor +30 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "d"
        cost = 90
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\dilithiumMax = ClampInt(*p\dilithiumMax + 10, 0, 50)
        LogLine("UPGRADE: dilithium +10 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Case "e"
        cost = 80
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\oreMax = ClampInt(*p\oreMax + 20, 0, 250)
        LogLine("UPGRADE: cargo +20 (-" + Str(cost) + ")")
        PrintN("Upgrade installed.")
      Default
        PrintN("Unknown selection.")
    EndSelect
  Wend
EndProcedure

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
  Select dir
    Case "n" : dy = -1
    Case "s" : dy = 1
    Case "w" : dx = -1
    Case "e" : dx = 1
    Case "nw", "ne", "sw", "se"
      If dir = "nw" : dx = -1 : dy = -1
      ElseIf dir = "ne" : dx = 1 : dy = -1
      ElseIf dir = "sw" : dx = -1 : dy = 1
      ElseIf dir = "se" : dx = 1 : dy = 1
      EndIf
    Default
      PrintN("NAV expects N, NE, E, SE, S, SW, W, NW")
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

    If CurCell(gx, gy)\entType = #ENT_ENEMY
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
    If CurCell(gx, gy)\entType = #ENT_ENEMY
      PrintN("Autopilot: enemy contact detected.")
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

Procedure EnterCombat(*p.Ship, *enemy.Ship, *cs.CombatState)
  ; Ensure player has hull to fight
  If *p\hull <= 0
    *p\hull = *p\hullMax
    *p\shields = *p\shieldsMax
  EndIf
  
  gMode = #MODE_TACTICAL
  *cs\range = 16 + Random(10)
  *cs\turn = 1
  *cs\pAim = 0
  *cs\eAim = 0
  PrintN("")
  PrintN("Red alert! Engaging enemy!")
  PrintStatusTactical(*p, *enemy, *cs)
  PrintN("")
  PrintN("Type HELP for combat commands.")
EndProcedure

Procedure LeaveCombat()
  gMode = #MODE_GALAXY
EndProcedure

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

  ConsoleColor(#C_LIGHTGRAY, #C_BLACK)
  PrintN("Starship Console (Galaxy + Tactical)")
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  PrintN("Data: " + gDatPath + " (fallback " + gIniPath + ")")
  ResetColor()
  PrintN("")

  InitShipData()

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
  RedrawGalaxy(@player)

  While IsAlive(@player)
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
      ElseIf cmd = "crew"
        ClearConsole()
        PrintN("Crew Status:")
        PrintN("")
        PrintCrew(@player)
        PrintN("< Press ENTER >")
        Input()
        RedrawGalaxy(@player)
      ElseIf cmd = "map"
        RedrawGalaxy(@player)
      ElseIf cmd = "clear"
        ClearLog()
        RedrawGalaxy(@player)
      ElseIf cmd = "undo"
        If gUndoAvailable = 0
          PrintN("No undo available.")
        Else
          Protected fuel.i, hull.i, shields.i, credits.i, ore.i, dilithium.i
          Protected mapX.i, mapY.i, x.i, y.i, mode.i
          If RestoreUndoState(@fuel, @hull, @shields, @credits, @ore, @dilithium, @mapX, @mapY, @x, @y, @mode)
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
          SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode)
          Protected navDir.s = TokenAt(line, 2)
          Protected navSteps.i = ParseIntSafe(TokenAt(line, 3), 1)
          Nav(@player, navDir, navSteps)

        CheckMissionCompletion(@player)
        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        RedrawGalaxy(@player)

        If CurCell(gx, gy)\entType = #ENT_ENEMY
          CopyStructure(@enemyTemplate, @enemy, Ship)
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
            SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode)
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
            SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode)
            MinePlanet(@player)
          EndIf
        EndIf

        CheckMissionCompletion(@player)
        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        EnemyGalaxyAI(@player, @enemyTemplate, @cs)
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
        SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode)
        If CurCell(gx, gy)\entType = #ENT_SHIPYARD
          DockAtShipyard(@player, @enemyTemplate)
        ElseIf CurCell(gx, gy)\entType = #ENT_BASE
          DockAtBase(@player)
        Else
          PrintN("No starbase or shipyard in this sector.")
        EndIf

        CheckMissionCompletion(@player)
        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        EnemyGalaxyAI(@player, @enemyTemplate, @cs)
        RedrawGalaxy(@player)
      ElseIf cmd = "undock"
        SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode)
        If gDocked = 0
          PrintN("You are not docked.")
        Else
          gDocked = 0
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
          Else
            PrintN("Undocking... (no empty space, staying put)")
          EndIf
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
            EndIf
          EndIf
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "refuel"
        SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode)
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
        Protected confirm.i = MessageRequester("Starship Sim", "Are you sure you want to exit?", #PB_MessageRequester_YesNo)
        If confirm = #PB_MessageRequester_Yes
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
        
        ; Handle autosave
        If gAutosaveInterval > 0
          gAutosaveCounter + 1
          If gAutosaveCounter >= gAutosaveInterval
            SaveGame(@player)
            LogLine("AUTOSAVE: saved at turn " + Str(gAutosaveCounter))
            gAutosaveCounter = 0
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
        Protected pctShields.i = ParseIntSafe(TokenAt(line, 2), player\allocShields)
        Protected pctWeapons.i = ParseIntSafe(TokenAt(line, 3), player\allocWeapons)
        Protected pctEngines.i = ParseIntSafe(TokenAt(line, 4), player\allocEngines)

        pctShields = ClampInt(pctShields, 0, 100)
        pctWeapons = ClampInt(pctWeapons, 0, 100)
        pctEngines = ClampInt(pctEngines, 0, 100)

        If pctShields + pctWeapons + pctEngines > 100
          PrintN("Allocation sum must be <= 100.")
        Else
          player\allocShields = pctShields
          player\allocWeapons = pctWeapons
          player\allocEngines = pctEngines
          SaveAlloc("PlayerShip", @player)
          PrintN("Allocation updated.")
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
        If enemy\hull <= 0
          PrintN("Enemy destroyed!")
          Goto HandleEnemyDestroyed
        EndIf
      ElseIf cmd = "torpedo"
        Protected cnt.i = ParseIntSafe(TokenAt(line, 2), 1)
        PlayerTorpedo(@player, @enemy, @cs, cnt)
        If enemy\hull <= 0
          PrintN("Enemy destroyed!")
          Goto HandleEnemyDestroyed
        EndIf
      ElseIf cmd = "tractor"
        Protected tractorMode.s = TokenAt(line, 2)
        If tractorMode = ""
          PrintN("Usage: TRACTOR <HOLD|PULL|PUSH>")
          PrintN("  HOLD - lock enemy in place (1 fuel/turn)")
          PrintN("  PULL - pull enemy closer (1 dilithium or fuel)")
          Continue
        EndIf
        PlayerTractor(@player, @enemy, @cs, tractorMode)
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
        ; no-op
      ElseIf cmd = "quit" Or cmd = "exit"
        CloseConsole()
        End
      Else
        PrintN("Unknown command. Type HELP.")
        Continue
      EndIf

      If gMode = #MODE_TACTICAL And IsAlive(@player) And IsAlive(@enemy)
        RegenAndRepair(@player, 0)
        
        ; Check if enemy already dead before AI runs
        If enemy\hull <= 0
          Goto HandleEnemyDestroyed
        EndIf
        
        RegenAndRepair(@enemy, 1)
        EnemyAI(@enemy, @player, @cs)
        cs\turn + 1

        If enemy\hull <= 0
          HandleEnemyDestroyed:
          PrintDivider()
          PrintN("Enemy destroyed!")
          PrintDivider()

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
  Else
    PrintN("Session ended.")
  EndIf
  PrintDivider()
  PrintN("< Press ENTER >")
  Input()
EndProcedure

Main()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 1305
; FirstLine = 2163
; Folding = ------------------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = starship_sim.ico
; Executable = ..\Starship_Sim.exe
; IncludeVersionInfo
; VersionField0 = 1,0,2,0
; VersionField1 = 1,0,2,0
; VersionField2 = ZoneSoft
; VersionField3 = StarShip_Sim
; VersionField4 = 1.0.2.0
; VersionField5 = 1.0.2.0
; VersionField6 = A starship sim based on an old scifi TV series
; VersionField7 = StarShip_Sim
; VersionField8 = StarShip_Sim.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60