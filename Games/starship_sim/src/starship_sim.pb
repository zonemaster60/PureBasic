; Starship simulation (PureBasic 6.30)
; - Galaxy map: planets (mining), stars (obstacles), starbases (dock)
; - Tactical combat when you encounter enemies
; Data-driven ship stats loaded from ships.ini

EnableExplicit

#APP_NAME = "starship_sim"

Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Forward declarations (PureBasic requires declaring procedures used before definition)
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
Declare PrintCmd(cmd.s)
Declare PrintLegendLine(indent.s)
Declare.i LoadShip(section.s, *s.Ship)
Declare.s LoadGameSettingString(key.s, defaultValue.s)
Declare.s SafeField(s.s)
Declare SaveAlloc(section.s, *s.Ship)
Declare.i IsAlive(*s.Ship)
Declare PrintStatusGalaxy(*p.Ship)
Declare PrintStatusTactical(*p.Ship, *e.Ship, *cs.CombatState)
Declare.i EvasionBonus(*target.Ship)
Declare.i HitChance(range.i, *attacker.Ship, *target.Ship)
Declare ApplyDamage(*target.Ship, dmg.i)
Declare RegenAndRepair(*s.Ship)
Declare.i CombatMaxMove(*p.Ship)
Declare PlayerMove(*p.Ship, *cs.CombatState, dir.s, amount.i)
Declare PlayerPhaser(*p.Ship, *e.Ship, *cs.CombatState, power.i)
Declare PlayerTorpedo(*p.Ship, *e.Ship, *cs.CombatState, count.i)
Declare EnemyAI(*e.Ship, *p.Ship, *cs.CombatState)
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
Declare MinePlanet(*p.Ship)
Declare Nav(*p.Ship, dir.s, steps.i)
Declare EnterCombat(*p.Ship, *enemy.Ship, *cs.CombatState)
Declare LeaveCombat()

; Missions
Declare GenerateMission(*p.Ship)
Declare PrintMission(*p.Ship)
Declare AcceptMission(*p.Ship)
Declare AbandonMission()
Declare DeliverMission(*p.Ship)
Declare CheckMissionCompletion(*p.Ship)
Declare.i FindRandomCellOfType(entType.i, *outMapX.Integer, *outMapY.Integer, *outX.Integer, *outY.Integer)
Declare.s LocText(mapX.i, mapY.i, x.i, y.i)
Declare.i SaveGame(*p.Ship)
Declare.i LoadGame(*p.Ship)
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
EndEnumeration

Enumeration
  #MIS_NONE = 0
  #MIS_DELIVER_ORE
  #MIS_BOUNTY
  #MIS_SURVEY
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
EndEnumeration

#GALAXY_W = 10
#GALAXY_H = 10
#MAP_W = 10
#MAP_H = 10

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

  allocShields.i
  allocWeapons.i
  allocEngines.i

  sysEngines.i
  sysWeapons.i
  sysShields.i
EndStructure

Structure CombatState
  range.i
  turn.i
EndStructure

Structure Cell
  entType.i
  name.s
  richness.i
  enemyLevel.i
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

  rewardCredits.i
EndStructure

Global gIniPath.s = #APP_NAME + "_ships.ini"
Global gSavePath.s = #APP_NAME + "_save.txt"

Global gCredits.i = 0
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

Global Dim gLog.s(11)
Global gLogPos.i = 0

Macro CurCell(x, y)
  gGalaxy(gMapX, gMapY, x, y)
EndMacro

Procedure LogLine(s.s)
  gLog(gLogPos) = s
  gLogPos + 1
  If gLogPos > ArraySize(gLog())
    gLogPos = 0
  EndIf
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

Procedure RedrawGalaxy(*p.Ship)
  ClearConsole()
  ResetColor()
  PrintN("Starship Console (Galaxy + Tactical)")
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  PrintN("Galaxy (" + Str(gMapX) + "," + Str(gMapY) + ") of " + Str(#GALAXY_W) + "x" + Str(#GALAXY_H) + "    Type HELP for commands")
  ResetColor()
  PrintN("")
  PrintStatusGalaxy(*p)
  PrintMap()
  PrintDivider()
  PrintN("Recent")
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
  ConsoleColor(#C_YELLOW, #C_BLACK) : Print("*") : ResetColor() : Print("=Star(blocked) ")
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK) : Print("%") : ResetColor() : Print("=Base ")
  ConsoleColor(#C_LIGHTRED, #C_BLACK) : Print("E") : ResetColor() : Print("=Enemy ")
  ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK) : Print("#") : ResetColor() : Print("=Wormhole ")
  ConsoleColor(#C_WHITE, #C_BLACK) : Print("?") : ResetColor() : Print("=BlackHole ")
  ConsoleColor(#C_BROWN, #C_BLACK) : Print("S") : ResetColor() : PrintN("=Sun(blocked)")
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
    Case #ENT_ENEMY
      ConsoleColor(#C_LIGHTRED, #C_BLACK)
    Case #ENT_WORMHOLE
      ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK)
    Case #ENT_BLACKHOLE
      ConsoleColor(#C_WHITE, #C_BLACK)
    Case #ENT_SUN
      ; Approx orange
      ConsoleColor(#C_BROWN, #C_BLACK)
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
  PrintCmd("STATUS")
  PrintN("    Show ship status, fuel, ore, and systems")
  PrintN("")
  PrintCmd("MAP")
  PrintN("    Show the sector map")
  PrintN("    Legend:")
  PrintLegendLine("      ")
  PrintN("")
  PrintCmd("SCAN")
  PrintN("    Show non-empty contents of adjacent sectors")
  PrintN("")
  PrintCmd("NAV <N|S|E|W> [steps]")
  PrintN("    Move 1-5 sectors, costs 1 fuel per step")
  PrintN("    Crossing the sector-map edge moves to the next map in the galaxy")
  PrintN("    Examples: NAV N     | NAV E 3")
  PrintN("")
  PrintCmd("MINE")
  PrintN("    Mine ore when in a planet sector (O), costs 2 fuel")
  PrintN("    Example: MINE")
  PrintN("")
  PrintCmd("DOCK")
  PrintN("    Dock when in a starbase sector (%): repair/refuel/rearm")
  PrintN("    Example: DOCK")
  PrintN("")

  PrintCmd("MISSIONS")
  PrintN("    Show mission board + current mission")
  PrintN("    Example: MISSIONS")
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
  PrintN("    S = Sun (blocked; gravity well may pull you in if adjacent)")
  PrintN("")

  PrintCmd("QUIT")
  PrintN("    Exit the game")
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
                  Str(*p\allocShields) + "|" + Str(*p\allocWeapons) + "|" + Str(*p\allocEngines) + "|" +
                  Str(*p\sysEngines) + "|" + Str(*p\sysWeapons) + "|" + Str(*p\sysShields))

  WriteStringN(f, "mission|" + Str(gMission\active) + "|" + Str(gMission\type) + "|" +
                  SafeField(gMission\title) + "|" + SafeField(gMission\desc) + "|" +
                  Str(gMission\oreRequired) + "|" +
                  Str(gMission\killsRequired) + "|" + Str(gMission\killsDone) + "|" +
                  Str(gMission\destMapX) + "|" + Str(gMission\destMapY) + "|" + Str(gMission\destX) + "|" + Str(gMission\destY) + "|" +
                  Str(gMission\destEntType) + "|" + SafeField(gMission\destName) + "|" +
                  Str(gMission\rewardCredits))

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
        gMode = Val(StringField(line, 2, "|"))
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
        *p\allocShields= Val(StringField(line, 22, "|"))
        *p\allocWeapons= Val(StringField(line, 23, "|"))
        *p\allocEngines= Val(StringField(line, 24, "|"))
        *p\sysEngines  = Val(StringField(line, 25, "|"))
        *p\sysWeapons  = Val(StringField(line, 26, "|"))
        *p\sysShields  = Val(StringField(line, 27, "|"))
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
  PrintCmd("STATUS")
  PrintN("    Show tactical status (range, hull, shields, capacitor, torps)")
  PrintN("")
  PrintCmd("SCAN")
  PrintN("    Show detailed sensor report if within SensorRange")
  PrintN("")
  PrintCmd("ALLOC <shields%> <weapons%> <engines%>")
  PrintN("    Set reactor allocation; sum must be <= 100")
  PrintN("    Examples: ALLOC 50 30 20  |  ALLOC 40 40 20")
  PrintN("")
  PrintCmd("MOVE <APPROACH|RETREAT|HOLD> [amount]")
  PrintN("    Change range; amount is limited by Engines allocation")
  PrintN("    Costs 1 fuel per MOVE")
  PrintN("    Examples: MOVE APPROACH 2  |  MOVE RETREAT 1  |  MOVE HOLD")
  PrintN("")
  PrintCmd("PHASER <power>")
  PrintN("    Fire phasers using WeaponCap; power is capped per turn by PhaserBanks")
  PrintN("    Tip: if WeaponCap is 0, use END to recharge or ALLOC more to weapons")
  PrintN("    Example: PHASER 40")
  PrintN("")
  PrintCmd("TORPEDO [count]")
  PrintN("    Fire 1+ torpedoes; count capped by TorpedoTubes and remaining torps")
  PrintN("    Effective range: <= 22")
  PrintN("    Example: TORPEDO 1  |  TORPEDO 2")
  PrintN("")
  PrintCmd("FLEE")
  PrintN("    Attempt to disengage; success improves at longer range")
  PrintN("    Example: FLEE")
  PrintN("")
  PrintCmd("END")
  PrintN("    End your turn (regen/repair happens, then enemy acts)")
  PrintN("")
  PrintCmd("QUIT")
  PrintN("    Exit the game")
  PrintDivider()
EndProcedure

Procedure.i LoadShip(section.s, *s.Ship)
  If OpenPreferences(gIniPath) = 0
    ProcedureReturn 0
  EndIf

  PreferenceGroup(section)

  *s\name        = ReadPreferenceString("Name", section)
  *s\class       = ReadPreferenceString("Class", "")
  *s\hullMax     = ReadPreferenceLong("HullMax", 100)
  *s\shieldsMax  = ReadPreferenceLong("ShieldsMax", 100)
  *s\reactorMax  = ReadPreferenceLong("ReactorMax", 200)
  *s\warpMax     = ReadPreferenceFloat("WarpMax", 9.0)
  *s\impulseMax  = ReadPreferenceFloat("ImpulseMax", 1.0)
  *s\phaserBanks = ReadPreferenceLong("PhaserBanks", 4)
  *s\torpTubes   = ReadPreferenceLong("TorpedoTubes", 2)
  *s\torpMax     = ReadPreferenceLong("TorpedoesMax", 10)
  *s\sensorRange = ReadPreferenceLong("SensorRange", 20)
  *s\weaponCapMax= ReadPreferenceLong("WeaponCapMax", *s\reactorMax)
  *s\fuelMax     = ReadPreferenceLong("FuelMax", 100)
  *s\oreMax      = ReadPreferenceLong("OreMax", 50)

  *s\allocShields = ReadPreferenceLong("AllocShields", 40)
  *s\allocWeapons = ReadPreferenceLong("AllocWeapons", 40)
  *s\allocEngines = ReadPreferenceLong("AllocEngines", 20)

  ClosePreferences()

  *s\hull      = *s\hullMax
  *s\shields   = *s\shieldsMax
  *s\torp      = *s\torpMax
  *s\weaponCap = *s\weaponCapMax / 2
  *s\fuel      = *s\fuelMax
  *s\ore       = 0

  *s\sysEngines = #SYS_OK
  *s\sysWeapons = #SYS_OK
  *s\sysShields = #SYS_OK

  ProcedureReturn 1
EndProcedure

Procedure.s LoadGameSettingString(key.s, defaultValue.s)
  Protected out.s = defaultValue
  If OpenPreferences(gIniPath) = 0
    ProcedureReturn out
  EndIf
  PreferenceGroup("Game")
  out = ReadPreferenceString(key, defaultValue)
  ClosePreferences()
  ProcedureReturn out
EndProcedure

Procedure SaveAlloc(section.s, *s.Ship)
  If OpenPreferences(gIniPath) = 0
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
    EndIf
  ElseIf gMission\type <> #MIS_NONE
    PrintN("Mission offer: " + gMission\title + " (type MISSIONS)")
  EndIf
  Print("Fuel: ")
  SetColorForPercent(Int(100.0 * *p\fuel / ClampInt(*p\fuelMax, 1, 999999)))
  Print(Str(*p\fuel) + "/" + Str(*p\fuelMax))
  ResetColor()
  Print("  Ore: ")
  ConsoleColor(#C_BROWN, #C_BLACK)
  PrintN(Str(*p\ore) + "/" + Str(*p\oreMax))
  ResetColor()
  PrintN("Ship: " + *p\name + " [" + *p\class + "]")
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
  PrintDivider()
EndProcedure

Procedure PrintStatusTactical(*p.Ship, *e.Ship, *cs.CombatState)
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

Procedure.i EvasionBonus(*target.Ship)
  Protected bonus.i = *target\allocEngines / 10
  If (*target\sysEngines & #SYS_DAMAGED) : bonus / 2 : EndIf
  If (*target\sysEngines & #SYS_DISABLED) : bonus = 0 : EndIf
  ProcedureReturn ClampInt(bonus, 0, 12)
EndProcedure

Procedure.i HitChance(range.i, *attacker.Ship, *target.Ship)
  Protected c.i = 85 - range * 4
  c - EvasionBonus(*target)
  If (*attacker\sysWeapons & #SYS_DAMAGED) : c - 8 : EndIf
  If (*attacker\sysWeapons & #SYS_DISABLED) : c = 0 : EndIf
  ProcedureReturn ClampInt(c, 5, 90)
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

Procedure RegenAndRepair(*s.Ship)
  Protected reactor.i = *s\reactorMax
  Protected shP.i = reactor * *s\allocShields / 100
  Protected wP.i  = reactor * *s\allocWeapons / 100

  If (*s\sysShields & #SYS_DISABLED) = 0
    If (*s\sysShields & #SYS_DAMAGED) : shP / 2 : EndIf
    *s\shields + (shP / 3)
    If *s\shields > *s\shieldsMax : *s\shields = *s\shieldsMax : EndIf
  EndIf

  If (*s\sysWeapons & #SYS_DISABLED) = 0
    If (*s\sysWeapons & #SYS_DAMAGED) : wP / 2 : EndIf
    *s\weaponCap + wP
    If *s\weaponCap > *s\weaponCapMax : *s\weaponCap = *s\weaponCapMax : EndIf
  EndIf

  If *s\hull < *s\hullMax And Random(99) < 30
    *s\hull + 1
  EndIf

  If (*s\sysEngines & #SYS_DAMAGED) And Random(99) < 18 : *s\sysEngines = #SYS_OK : EndIf
  If (*s\sysWeapons & #SYS_DAMAGED) And Random(99) < 18 : *s\sysWeapons = #SYS_OK : EndIf
  If (*s\sysShields & #SYS_DAMAGED) And Random(99) < 18 : *s\sysShields = #SYS_OK : EndIf
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

  Protected chance.i = HitChance(*cs\range, *p, *e)
  If Random(99) < chance
    Protected base.i = (power / 3) + Random(ClampInt(power / 3, 0, 999999))
    If base < 1 : base = 1 : EndIf

    Protected falloff.f = 1.0 - (*cs\range / 55.0)
    falloff = ClampF(falloff, 0.25, 1.0)
    Protected dmg.i = Int(base * falloff)
    If dmg < 1 : dmg = 1 : EndIf

    ApplyDamage(*e, dmg)
    PrintN("Phasers hit (" + Str(dmg) + ").")
  Else
    PrintN("Phasers miss.")
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
  If *cs\range > 22
    PrintN("Target out of torpedo effective range.")
    ProcedureReturn
  EndIf

  count = ClampInt(count, 1, *p\torpTubes)
  count = ClampInt(count, 1, *p\torp)

  Protected i.i
  For i = 1 To count
    *p\torp - 1
    Protected chance.i = ClampInt(HitChance(*cs\range, *p, *e) - 8, 5, 85)
    If Random(99) < chance
      Protected dmg.i = 32 + Random(24)
      If *cs\range > 16 : dmg - 6 : EndIf
      If dmg < 1 : dmg = 1 : EndIf
      ApplyDamage(*e, dmg)
      PrintN("Torpedo impact (" + Str(dmg) + ").")
    Else
      PrintN("Torpedo misses.")
    EndIf
    If *e\hull <= 0 : Break : EndIf
  Next
EndProcedure

Procedure EnemyAI(*e.Ship, *p.Ship, *cs.CombatState)
  If *e\hull <= 0 : ProcedureReturn : EndIf

  If *cs\range > 12 And ((*e\sysEngines & #SYS_DISABLED) = 0)
    *cs\range - (1 + Random(3))
    If *cs\range < 1 : *cs\range = 1 : EndIf
    PrintN("Enemy maneuvers to close range.")
    ProcedureReturn
  EndIf

  If *e\torp > 0 And *cs\range <= 18 And Random(99) < 30 And ((*e\sysWeapons & #SYS_DISABLED) = 0)
    Protected cnt.i = 1
    If *e\torpTubes > 1 And Random(99) < 25 : cnt = 2 : EndIf
    cnt = ClampInt(cnt, 1, *e\torpTubes)
    cnt = ClampInt(cnt, 1, *e\torp)

    Protected i.i
    For i = 1 To cnt
      *e\torp - 1
      If Random(99) < ClampInt(HitChance(*cs\range, *e, *p) - 5, 10, 85)
        Protected tdmg.i = 28 + Random(22)
        ApplyDamage(*p, tdmg)
        PrintN("Enemy torpedo hits (" + Str(tdmg) + ").")
      Else
        PrintN("Enemy torpedo misses.")
      EndIf
      If *p\hull <= 0 : Break : EndIf
    Next
    ProcedureReturn
  EndIf

  If (*e\sysWeapons & #SYS_DISABLED) = 0 And *e\weaponCap > 0
    Protected maxTurn.i = *e\phaserBanks * 20
    Protected spend.i = ClampInt(15 + Random(35), 5, *e\weaponCap)
    spend = ClampInt(spend, 1, maxTurn)
    *e\weaponCap - spend

    If Random(99) < HitChance(*cs\range, *e, *p)
      Protected base.i = (spend / 3) + Random(ClampInt(spend / 3, 0, 999999))
      If base < 1 : base = 1 : EndIf
      Protected falloff.f = 1.0 - (*cs\range / 55.0)
      falloff = ClampF(falloff, 0.25, 1.0)
      Protected pdmg.i = Int(base * falloff)
      If pdmg < 1 : pdmg = 1 : EndIf
      ApplyDamage(*p, pdmg)
      PrintN("Enemy phasers hit (" + Str(pdmg) + ").")
    Else
      PrintN("Enemy phasers miss.")
    EndIf
  Else
    PrintN("Enemy holds fire.")
  EndIf
EndProcedure

Procedure PrintScanTactical(*p.Ship, *e.Ship, *cs.CombatState)
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
    Case #ENT_WORMHOLE: ProcedureReturn "#"
    Case #ENT_BLACKHOLE: ProcedureReturn "?"
    Case #ENT_SUN: ProcedureReturn "S"
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
      LogLine("SUN: gravity well pulls you in")
      ProcedureReturn 1
    EndIf
  ElseIf foundBH
    If Random(99) < 55
      gx = bhX : gy = bhY
      LogLine("BLACK HOLE: gravity well pulls you in")
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
  LogLine("SUN: ship incinerated")
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
        LogLine("BLACK HOLE: spacetime shear - displaced")
        ProcedureReturn 1
      EndIf
    ElseIf r < 85
      ; Severe damage
      Protected dmg.i = 60 + Random(60)
      ApplyDamage(*p, dmg)
      LogLine("BLACK HOLE: tidal forces hit for " + Str(dmg))

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
      LogLine("BLACK HOLE: ship lost")
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

  ; Enemies
  For x = 1 To 4 + Random(6)
    ex = Random(#MAP_W - 1)
    ey = Random(#MAP_H - 1)
    If gGalaxy(mapX, mapY, ex, ey)\entType = #ENT_EMPTY
      gGalaxy(mapX, mapY, ex, ey)\entType = #ENT_ENEMY
      gGalaxy(mapX, mapY, ex, ey)\name = "Hostile Contact"
      gGalaxy(mapX, mapY, ex, ey)\enemyLevel = 1 + Random(3) + (mapX + mapY) / 6
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

  For row = 0 To maxRows - 1
    ; Sector map (left)
    If row < #MAP_H
      For x = 0 To #MAP_W - 1
        If x = gx And row = gy
          ConsoleColor(#C_WHITE, #C_BLACK)
          Print("@ ")
          ResetColor()
        Else
          SetColorForEnt(CurCell(x, row)\entType)
          Print(EntSymbol(CurCell(x, row)\entType) + " ")
          ResetColor()
        EndIf
      Next
    Else
      Print(Space(#MAP_W * 2))
    EndIf

    Print("   ")

    ; Galaxy map (right)
    If row < #GALAXY_H
      For x = 0 To #GALAXY_W - 1
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
  ConsoleColor(#C_WHITE, #C_BLACK) : Print("X") : ResetColor() : PrintN("=Current map")
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
  If roll < 50
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
  ElseIf roll < 85
    ; Bounty
    gMission\type = #MIS_BOUNTY
    gMission\title = "Bounty"
    gMission\killsRequired = 2 + Random(4)
    gMission\killsDone = 0
    gMission\rewardCredits = 120 + gMission\killsRequired * 80
    gMission\desc = "Destroy " + Str(gMission\killsRequired) + " enemy ships (E)."
  Else
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
    PrintN("  Reward: " + Str(gMission\rewardCredits) + " credits")
    PrintN("  Type ACCEPT to take it")
  Else
    PrintN("  Active: " + gMission\title)
    PrintN("  " + gMission\desc)
    If gMission\type = #MIS_BOUNTY
      PrintN("  Progress: " + Str(gMission\killsDone) + "/" + Str(gMission\killsRequired))
    ElseIf gMission\type = #MIS_DELIVER_ORE
      PrintN("  Cargo: need " + Str(gMission\oreRequired) + " ore; you have " + Str(*p\ore))
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
EndProcedure

Procedure AbandonMission()
  If gMission\active = 0
    LogLine("MISSION: none active")
    ProcedureReturn
  EndIf
  ClearStructure(@gMission, Mission)
  gMission\type = #MIS_NONE
  LogLine("MISSION ABANDONED")
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
  EndSelect
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
  If CurCell(gx, gy)\entType <> #ENT_PLANET
    PrintN("No planet in this sector.")
    ProcedureReturn
  EndIf
  If *p\fuel < 2
    PrintN("Insufficient fuel for mining operations.")
    ProcedureReturn
  EndIf
  If *p\ore >= *p\oreMax
    PrintN("Ore holds are full.")
    ProcedureReturn
  EndIf

  Protected pull.i = 1 + Random(CurCell(gx, gy)\richness)
  pull = ClampInt(pull, 1, 20)
  Protected space.i = *p\oreMax - *p\ore
  If pull > space : pull = space : EndIf
  *p\ore + pull
  *p\fuel - 2
  LogLine("MINE: +" + Str(pull) + " ore")
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
    Default
      PrintN("NAV expects N, S, E, or W.")
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
      LogLine("CONTACT: enemy detected")
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

Procedure EnterCombat(*p.Ship, *enemy.Ship, *cs.CombatState)
  gMode = #MODE_TACTICAL
  *cs\range = 16 + Random(10)
  *cs\turn = 1
  PrintN("")
  PrintN("Red alert! Entering tactical mode.")
  PrintHelpTactical()
  PrintStatusTactical(*p, *enemy, *cs)
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

  ConsoleColor(#C_LIGHTGRAY, #C_BLACK)
  PrintN("Starship Console (Galaxy + Tactical)")
  ConsoleColor(#C_DARKGRAY, #C_BLACK)
  PrintN("Data: " + gIniPath)
  ResetColor()
  PrintN("")

  playerSection = LoadGameSettingString("PlayerSection", "PlayerShip")
  enemySection  = LoadGameSettingString("EnemySection",  "EnemyShip")

  If LoadShip(playerSection, @player) = 0
    PrintN("Could not open " + #APP_NAME + "_ships.ini. Place it Next To the executable.")
    Input()
    End
  EndIf

  If LoadShip(enemySection, @enemyTemplate) = 0
    PrintN("Missing enemy section '" + enemySection + "' in " + #APP_NAME + "_ships.ini.")
    Input()
    End
  EndIf

  GenerateGalaxy()
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

    Protected line.s = Trim(lineRaw)
    Protected cmd.s  = TrimLower(TokenAt(line, 1))
    If cmd = "" : cmd = "end" : EndIf

    If gMode = #MODE_GALAXY
      If cmd = "help"
        ClearConsole()
        PrintHelpGalaxy()
        PrintN("")
        PrintN("Press Enter...")
        Input()
        RedrawGalaxy(@player)
      ElseIf cmd = "status"
        RedrawGalaxy(@player)
      ElseIf cmd = "map"
        RedrawGalaxy(@player)
      ElseIf cmd = "scan"
        ClearConsole()
        PrintHelpGalaxy()
        PrintN("")
        ScanGalaxy()
        PrintN("Press Enter...")
        Input()
        RedrawGalaxy(@player)
      ElseIf cmd = "nav"
        Protected navDir.s = TokenAt(line, 2)
        Protected navSteps.i = ParseIntSafe(TokenAt(line, 3), 1)
        Nav(@player, navDir, navSteps)

        RedrawGalaxy(@player)

        If CurCell(gx, gy)\entType = #ENT_ENEMY
          enemy = enemyTemplate
          Protected lvl.i = CurCell(gx, gy)\enemyLevel
          If lvl < 1 : lvl = 1 : EndIf
          enemy\hullMax + (lvl * 10) : enemy\hull = enemy\hullMax
          enemy\shieldsMax + (lvl * 12) : enemy\shields = enemy\shieldsMax
          enemy\weaponCapMax + (lvl * 20) : enemy\weaponCap = enemy\weaponCapMax / 2
          EnterCombat(@player, @enemy, @cs)
        EndIf
      ElseIf cmd = "mine"
        MinePlanet(@player)
        RedrawGalaxy(@player)
      ElseIf cmd = "dock"
        DockAtBase(@player)
        RedrawGalaxy(@player)
      ElseIf cmd = "missions"
        ClearConsole()
        GenerateMission(@player)
        PrintMission(@player)
        PrintN("Press Enter...")
        Input()
        RedrawGalaxy(@player)
      ElseIf cmd = "accept"
        GenerateMission(@player)
        AcceptMission(@player)
        RedrawGalaxy(@player)
      ElseIf cmd = "abandon"
        AbandonMission()
        GenerateMission(@player)
        RedrawGalaxy(@player)
      ElseIf cmd = "save"
        SaveGame(@player)
        RedrawGalaxy(@player)
      ElseIf cmd = "load"
        If LoadGame(@player)
          RedrawGalaxy(@player)
        Else
          RedrawGalaxy(@player)
        EndIf
      ElseIf cmd = "quit"
        Break
      ElseIf cmd = "end"
        ; no-op
      ElseIf cmd = "phaser" Or cmd = "torpedo" Or cmd = "alloc" Or cmd = "move" Or cmd = "flee"
        LogLine("Tactical only: move into an E sector to engage")
        RedrawGalaxy(@player)
      Else
        LogLine("Unknown: " + cmd)
        RedrawGalaxy(@player)
      EndIf

    Else
      ; Tactical mode
      If cmd = "help"
        ClearConsole()
        PrintHelpTactical()
        PrintN("")
        PrintN("Press Enter...")
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
        PrintN("Press Enter...")
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
      ElseIf cmd = "move"
        Protected moveDir.s = TokenAt(line, 2)
        Protected moveAmt.i = ParseIntSafe(TokenAt(line, 3), 2)
        PlayerMove(@player, @cs, moveDir, moveAmt)
      ElseIf cmd = "phaser"
        Protected pwr.i = ParseIntSafe(TokenAt(line, 2), 30)
        PlayerPhaser(@player, @enemy, @cs, pwr)
      ElseIf cmd = "torpedo"
        Protected cnt.i = ParseIntSafe(TokenAt(line, 2), 1)
        PlayerTorpedo(@player, @enemy, @cs, cnt)
      ElseIf cmd = "flee"
        If player\fuel <= 0
          PrintN("Fuel depleted. Cannot flee.")
        ElseIf Random(99) < ClampInt(55 - cs\range, 15, 60)
          player\fuel - 1
          PrintN("You disengage and escape to the galaxy map.")
          LeaveCombat()
          PrintHelpGalaxy()
          Continue
        Else
          PrintN("Flee attempt fails.")
        EndIf
      ElseIf cmd = "end"
        ; no-op
      ElseIf cmd = "quit"
        Break
      Else
        PrintN("Unknown command. Type HELP.")
      EndIf

      If gMode = #MODE_TACTICAL And IsAlive(@player) And IsAlive(@enemy)
        RegenAndRepair(@player)
        RegenAndRepair(@enemy)
        EnemyAI(@enemy, @player, @cs)
        cs\turn + 1

        If enemy\hull <= 0
          PrintDivider()
          PrintN("Enemy destroyed.")
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

          If gEnemyMapX >= 0 And gEnemyMapY >= 0 And gEnemyX >= 0 And gEnemyY >= 0
            gGalaxy(gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)\entType = #ENT_EMPTY
            gGalaxy(gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)\name = ""
            gGalaxy(gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)\enemyLevel = 0
          EndIf
          player\ore = ClampInt(player\ore + (3 + Random(10)), 0, player\oreMax)
          LeaveCombat()
          PrintHelpGalaxy()
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
  Else
    PrintN("Session ended.")
  EndIf
  PrintDivider()
  PrintN("Press Enter...")
  Input()
EndProcedure

Main()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 1578
; FirstLine = 1569
; Folding = ----------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = starship_sim.ico
; Executable = ..\starship_sim.exe
