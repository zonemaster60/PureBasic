; starcomm_missions.pbi
; Mission system: LocText, FindRandomCellOfType, GenerateMission, HQOrdersTier, GenerateHQMission, PrintMission, AcceptMission, IsDangerousCell, StepCoord, FindPathMission, AbandonMission, CheckMissionCompletion, DefendMissionTick, DeliverMission
; XIncluded from starcomm.pb

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
    gMission\rewardCredits = 1000 + gMission\threatLevel * 300
    gMission\desc = "Proceed to " + gMission\destName + " at " + LocText(mxY, myY, xY, yY) + " and DOCK to hold the line for " + Str(gMission\turnsLeft) + " turns."
    gMission\rewardCredits = Int(gMission\rewardCredits * (1.0 + (HQOrdersTier() * 0.05))) ; Tier bonus
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
    gMission\rewardCredits = 250 + gMission\oreRequired * 25
    gMission\desc = "Deliver " + Str(gMission\oreRequired) + " ore to " + gMission\destName + " at " + LocText(mx, my, x, y)
    gMission\rewardCredits = Int(gMission\rewardCredits * (1.0 + (HQOrdersTier() * 0.05))) ; Tier bonus
  ElseIf roll < 88
    ; Bounty
    gMission\type = #MIS_BOUNTY
    gMission\title = "Bounty"
    gMission\killsRequired = 2 + Random(4)
    gMission\killsDone = 0
    gMission\threatLevel = ClampInt(1 + Random(2) + (gMapX + gMapY) / 4, 1, 10)
    gMission\rewardCredits = 500 + (gMission\killsRequired * 250) + (gMission\threatLevel * 150)
    gMission\desc = "Destroy " + Str(gMission\killsRequired) + " enemy ships (E). Threat level: " + Str(gMission\threatLevel) + "."
    ; No fixed location for bounty missions
    gMission\destMapX = -1 : gMission\destMapY = -1 : gMission\destX = -1 : gMission\destY = -1
    gMission\destEntType = #ENT_EMPTY
    gMission\destName = ""
    gMission\rewardCredits = Int(gMission\rewardCredits * (1.0 + (HQOrdersTier() * 0.05))) ; Tier bonus
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
    gMission\rewardCredits = 750 + Random(500)
    gMission\desc = "Travel to " + gMission\destName + " at " + LocText(mx2, my2, x2, y2) + " and perform a scan (SCAN)."
    gMission\rewardCredits = Int(gMission\rewardCredits * (1.0 + (HQOrdersTier() * 0.05))) ; Tier bonus
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
    gMission\rewardCredits = 3500 + Random(2500)
    gMission\desc = "Locate and destroy the Planet Killer at " + LocText(mxPK, myPK, xPK, yPK) + ". Warning: extremely dangerous!"
    gMission\rewardCredits = Int(gMission\rewardCredits * (1.0 + (HQOrdersTier() * 0.05))) ; Tier bonus
  EndIf

EndProcedure

;==============================================================================
; HQOrdersTier()
; Returns the current Standing Orders tier (0-3) based on HQ missions done.
;==============================================================================
Procedure.i HQOrdersTier()
  If gHQMissionsCompleted >= 6 : ProcedureReturn 3 : EndIf
  If gHQMissionsCompleted >= 3 : ProcedureReturn 2 : EndIf
  If gHQMissionsCompleted >= 1 : ProcedureReturn 1 : EndIf
  ProcedureReturn 0
EndProcedure

;==============================================================================
; GenerateHQMission(*p.Ship)
; Offers a high-reward priority mission exclusive to Starcomm HQ.
; Only activates if no mission is currently active.
;==============================================================================
Procedure GenerateHQMission(*p.Ship)
  If gMission\active
    ProcedureReturn   ; Don't overwrite an existing mission
  EndIf

  ; Generate a priority bounty with 2x reward
  gMission\active        = 1
  gMission\type          = #MIS_BOUNTY
  gMission\title         = "HQ Priority Bounty"
  gMission\killsRequired = 3 + Random(4)    ; 3-6 kills
  gMission\killsDone     = 0
  gMission\rewardCredits = (500 + Random(500)) * 2   ; 1000-2000 cr (2x standard)
  gMission\destMapX      = -1
  gMission\destMapY      = -1
  gMission\destX         = -1
  gMission\destY         = -1
  gMission\destEntType   = #ENT_EMPTY
  gMission\destName      = ""
  gMission\desc          = "Destroy " + Str(gMission\killsRequired) + " hostile vessels. Priority clearance granted."

  PrintN("")
  ConsoleColor(#C_YELLOW, #C_BLACK)
  PrintN("=== HQ PRIORITY MISSION BOARD ===")
  ResetColor()
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN("MISSION: HQ Priority Bounty")
  ResetColor()
  PrintN("Starcomm Command orders: eliminate " + Str(gMission\killsRequired) + " hostile vessels. Priority clearance granted.")
  PrintN("Reward: " + Str(gMission\rewardCredits) + " credits")
  PrintN("(Mission auto-accepted. Report back to any base when complete.)")
  PrintN("")
EndProcedure

Procedure PrintMission(*p.Ship)
  PrintDivider()
  If gMission\type = #MIS_NONE
    ConsoleColor(#C_DARKGRAY, #C_BLACK)
    PrintN("  MISSIONS No offer available. Explore or visit a starbase.")
    ResetColor()

  ElseIf gMission\active = 0
    ; === MISSION OFFER ===
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("  !! MISSION OFFER !!")
    ResetColor()
    ConsoleColor(#C_WHITE, #C_BLACK)
    PrintN("  " + gMission\title)
    ResetColor()
    PrintN("  " + gMission\desc)
    If gMission\destEntType <> #ENT_EMPTY
      ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
      Print("  Destination: ")
      ResetColor()
      PrintN(LocText(gMission\destMapX, gMission\destMapY, gMission\destX, gMission\destY))
      PrintN("  Distance: Galaxy offset (" + Str(gMission\destMapX - gMapX) + "," + Str(gMission\destMapY - gMapY) + ")  Sector offset (" + Str(gMission\destX - gx) + "," + Str(gMission\destY - gy) + ")")
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      PrintN("  Tip: MAP shows M markers. Use COMPUTER to navigate there.")
      ResetColor()
    EndIf
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("  Reward:  " + Str(gMission\rewardCredits) + " credits")
    ResetColor()
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
    PrintN("  >> Type ACCEPT to take this mission <<")
    ResetColor()

  Else
    ; === ACTIVE MISSION ===
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
    PrintN("  MISSION IN PROGRESS")
    ResetColor()
    ConsoleColor(#C_WHITE, #C_BLACK)
    PrintN("  " + gMission\title)
    ResetColor()
    PrintN("  " + gMission\desc)
    If gMission\destEntType <> #ENT_EMPTY
      ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
      Print("  Destination: ")
      ResetColor()
      PrintN(LocText(gMission\destMapX, gMission\destMapY, gMission\destX, gMission\destY))
      PrintN("  Distance: Galaxy offset (" + Str(gMission\destMapX - gMapX) + "," + Str(gMission\destMapY - gMapY) + ")  Sector offset (" + Str(gMission\destX - gx) + "," + Str(gMission\destY - gy) + ")")
    EndIf
    If gMission\type = #MIS_BOUNTY
      ConsoleColor(#C_YELLOW, #C_BLACK)
      PrintN("  Progress: " + Str(gMission\killsDone) + "/" + Str(gMission\killsRequired) + " kills")
      ResetColor()
    ElseIf gMission\type = #MIS_DELIVER_ORE
      Protected oreHave.i = *p\ore
      If oreHave >= gMission\oreRequired
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("  Cargo: " + Str(oreHave) + "/" + Str(gMission\oreRequired) + " ore READY TO DELIVER!")
      Else
        ConsoleColor(#C_YELLOW, #C_BLACK)
        PrintN("  Cargo: " + Str(oreHave) + "/" + Str(gMission\oreRequired) + " ore needed")
      EndIf
      ResetColor()
    ElseIf gMission\type = #MIS_DEFEND_YARD
      ConsoleColor(#C_LIGHTRED, #C_BLACK)
      PrintN("  Defend: " + gMission\destName + "   Turns left: " + Str(gMission\turnsLeft) + "   Yard HP: " + Str(gMission\yardHP))
      ResetColor()
    ElseIf gMission\type = #MIS_PLANETKILLER
      ConsoleColor(#C_LIGHTRED, #C_BLACK)
      PrintN("  !! CRITICAL Destroy the Planet Killer !!")
      ConsoleColor(#C_CYAN, #C_BLACK)
      PrintN("  TARGET: " + gMission\destName + " at " + LocText(gMission\destMapX, gMission\destMapY, gMission\destX, gMission\destY))
      ResetColor()
    EndIf
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("  Reward: " + Str(gMission\rewardCredits) + " credits on completion")
    ResetColor()
    ConsoleColor(#C_DARKGRAY, #C_BLACK)
    PrintN("  Type ABANDON to cancel this mission.")
    ResetColor()
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
    PrintN("Navigation computer available: type COMPUTER to route to the mission destination.")
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
    gEnemyIsPirate = 0
    gEnemyIsPlanetKiller = 0
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
    gTotalCreditsEarned + gMission\rewardCredits
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
    PrintDivider()
    PrintN("*** MISSION COMPLETE: Shipyard secured! (+" + Str(gMission\rewardCredits) + " credits) ***")
    PrintDivider()
    ResetColor()
    LogLine("MISSION COMPLETE: defend shipyard (+" + Str(gMission\rewardCredits) + " credits)")
    ClearStructure(@gMission, Mission)
    gMission\type = #MIS_NONE
    gTotalMissions + 1
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
  gTotalCreditsEarned + gMission\rewardCredits
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  PrintDivider()
  PrintN("*** MISSION COMPLETE: Ore delivered! (+" + Str(gMission\rewardCredits) + " credits) ***")
  PrintDivider()
  ResetColor()
  LogLine("MISSION COMPLETE: delivered ore (+" + Str(gMission\rewardCredits) + " credits)")
  ClearStructure(@gMission, Mission)
  gMission\type = #MIS_NONE
  gTotalMissions + 1
EndProcedure
