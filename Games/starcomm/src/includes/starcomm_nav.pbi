; starcomm_nav.pbi
; Navigation: Nav, AutopilotToMission
; XIncluded from starcomm.pb

Procedure Nav(*p.Ship, dir.s, steps.i, *enemyTemplate.Ship = 0, *cs.CombatState = 0)
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
    
    ; Helm officer gains XP for navigation
    GainCrewXP(*p, #CREW_HELM, 4)
    
    ; Engineering officer gains XP for managing reactor/fuel during transit
    GainCrewXP(*p, #CREW_ENGINEERING, 2)

    ; Shields officer gains XP for keeping shields stable in transit
    GainCrewXP(*p, #CREW_SHIELDS, 1)

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
      
    ; Enemy contact
    If CurCell(gx, gy)\entType = #ENT_ENEMY Or CurCell(gx, gy)\entType = #ENT_PIRATE Or CurCell(gx, gy)\entType = #ENT_PLANETKILLER
      gEnemyMapX = gMapX
      gEnemyMapY = gMapY
      gEnemyX = gx
      gEnemyY = gy
      LogLine("CONTACT: enemy detected!")
      
      ; Pirate Interdiction: If it's a pirate, 30% chance to force immediate combat
      If CurCell(gx, gy)\entType = #ENT_PIRATE And *enemyTemplate <> 0 And *cs <> 0 And Random(99) < 30
        ConsoleColor(#C_LIGHTRED, #C_BLACK)
        PrintN("!! INTERDICTED !! Pirate " + CurCell(gx, gy)\name + " has pulled you out of navigation!")
        ResetColor()
        LogLine("INTERDICTION: pirate " + CurCell(gx, gy)\name + " forced combat")
        
        ; Setup enemy and enter combat immediately
        Protected interEnemy.Ship
        CopyStructure(*enemyTemplate, @interEnemy, Ship)
        If CurCell(gx, gy)\name <> "" : interEnemy\name = CurCell(gx, gy)\name : EndIf
        Protected interLvl.i = CurCell(gx, gy)\enemyLevel
        If interLvl < 1 : interLvl = 1 : EndIf
        interEnemy\hullMax = interEnemy\hullMax + (interLvl * 10)
        interEnemy\hull = interEnemy\hullMax
        interEnemy\shieldsMax = interEnemy\shieldsMax + (interLvl * 12)
        interEnemy\shields = interEnemy\shieldsMax
        interEnemy\weaponCapMax = interEnemy\weaponCapMax + (interLvl * 20)
        interEnemy\weaponCap = interEnemy\weaponCapMax / 2
        interEnemy\torp = interEnemy\torpMax
        gEnemyIsPirate = 1
        gEnemyIsPlanetKiller = 0
        
        EnterCombat(*p, @interEnemy, *cs)
        ProcedureReturn ; Exit Nav procedure as we are now in combat mode
      EndIf
      
      Break
    EndIf
      Break
    Next

    If *p\hull <= 0
      PrintN("")
      ConsoleColor(#C_LIGHTRED, #C_BLACK)
      PrintN("*** GAME OVER ***")
      PrintN("Your ship has been destroyed!")
      ResetColor()
      PrintN("")
      PrintN("Press ENTER to quit...")
      Input()
      End
    EndIf
  Next

  If moved > 0
    If startMapX <> gMapX Or startMapY <> gMapY
      LogLine("NAV " + UCase(dir) + " " + Str(steps) + ": moved " + Str(moved) + " step(s) to Galaxy (" + Str(gMapX) + "," + Str(gMapY) + ") Sector (" + Str(gx) + "," + Str(gy) + ")")
    ElseIf startX <> gx Or startY <> gy
      LogLine("NAV " + UCase(dir) + " " + Str(steps) + ": moved " + Str(moved) + " step(s) to Sector (" + Str(gx) + "," + Str(gy) + ")")
    EndIf
    gGameTurn = gGameTurn + 1
    ; Bank Interest: 1% every 50 turns
    If gGameTurn > 0 And gGameTurn % 50 = 0 And gBankBalance > 0
      Protected interest.i = Int(gBankBalance * 0.01)
      If interest < 1 : interest = 1 : EndIf
      gBankBalance + interest
      ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
      PrintN("BANK NOTIFICATION: Interest earned! (+" + Str(interest) + " credits)")
      ResetColor()
    EndIf
    GenerateCheatCode()
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

  Protected apSteps.i = Len(path)
  PrintN("Autopilot: route found - " + Str(apSteps) + " step(s) to " + gMission\destName + ".")
  If gMapX <> gMission\destMapX Or gMapY <> gMission\destMapY
    PrintN("  Galaxy (" + Str(gMapX) + "," + Str(gMapY) + ") -> (" + Str(gMission\destMapX) + "," + Str(gMission\destMapY) + ")")
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
        If CurCell(gx, gy)\entType = #ENT_PIRATE
          gEnemyIsPirate = 1
        Else
          gEnemyIsPirate = 0
        EndIf
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
