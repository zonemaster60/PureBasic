; starcomm_combat.pbi
; Combat mechanics: EvasionBonus, HitChance, ApplyDamage, RegenAndRepair, CombatMaxMove, PlayerMove, PlayerPhaser, PlayerTorpedo, PlayerTractor, EnemyAI, EnemyGalaxyAI, PrintScanTactical
; XIncluded from starcomm.pb

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
      If *s\shields > 0 : *s\shields + 1 : EndIf  ; Only regen shields that are still active (not from 0 - shields stay down once drained)
    Else
      *s\shields + (shP / 3)
      GainCrewXP(*s, #CREW_SHIELDS, 5)
    EndIf
    If *s\shields > *s\shieldsMax : *s\shields = *s\shieldsMax : EndIf
  EndIf

  If (*s\sysWeapons & #SYS_DISABLED) = 0
    If (*s\sysWeapons & #SYS_DAMAGED) : wP / 2 : EndIf
    *s\weaponCap + wP
    If *s\weaponCap > *s\weaponCapMax : *s\weaponCap = *s\weaponCapMax : EndIf
    If isEnemy = 0 : GainCrewXP(*s, #CREW_ENGINEERING, 5) : EndIf
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
      GainCrewXP(*p, #CREW_HELM, 10)
    Case "retreat"
      *cs\range + amount
      If *cs\range > 40 : *cs\range = 40 : EndIf
      *p\fuel - 1
      PrintN("You open distance by " + Str(amount) + ".")
      GainCrewXP(*p, #CREW_HELM, 10)
    Case "hold"
      PrintN("You hold position.")
      GainCrewXP(*p, #CREW_HELM, 2)
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
        *e\shields - dmg
        If *e\shields < 0 : *e\shields = 0 : EndIf
        PrintN("Phasers hit! (" + Str(dmg) + " shields).")
      EndIf
    Else
      ; Shields down - phasers damage hull directly
      *e\hull - dmg
      If *e\hull < 0 : *e\hull = 0 : EndIf
      PrintN("Phasers hit HULL! (" + Str(dmg) + " hull damage)!")
    EndIf
    *cs\pAim = 0
    GainCrewXP(*p, #CREW_WEAPONS, 2 + dmg / 10)
  Else
    PrintN("Phasers miss.")
    *cs\pAim = ClampInt(*cs\pAim + 7, 0, 28)
    GainCrewXP(*p, #CREW_WEAPONS, 1)
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
      GainCrewXP(*p, #CREW_WEAPONS, 4 + dmg / 12)
    Else
      PrintN("Torpedo misses.")
      *cs\pAim = ClampInt(*cs\pAim + 7, 0, 28)
      GainCrewXP(*p, #CREW_WEAPONS, 2)
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
  
  ; Predatory AI: higher movement chance if player has dilithium
  If *p\dilithium >= 5
    moveChance = 60
  EndIf
  
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
    ; Predatory AI: prefer closing distance if player is carrying dilithium
    If *p\dilithium >= 5
      moveType = 0 ; Always approach
    EndIf
    
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
  Protected moveChance.i = 30
  Protected enemy.Ship
  
  ; Base movement chance is fixed, logic below handles "intent"
  If Random(99) >= moveChance
    ProcedureReturn
  EndIf
  
  ; Pirate behavior scales with Dilithium
  ; 0-9 units:  Low profile, pirates mostly ignore or wander away
  ; 10-19 units: Moderate interest
  ; 20+ units:   Aggressive hunting
  Protected dilFactor.i = *p\dilithium
  
  For my = 0 To #GALAXY_H - 1
    For mx = 0 To #GALAXY_W - 1
      ; Only move enemies in current or adjacent galaxy sectors to player for performance
      If Abs(mx - gMapX) > 1 Or Abs(my - gMapY) > 1 : Continue : EndIf
      
      For y = 0 To #MAP_H - 1
        For x = 0 To #MAP_W - 1
          Protected entType.i = gGalaxy(mx, my, x, y)\entType
          If entType <> #ENT_ENEMY And entType <> #ENT_PIRATE And entType <> #ENT_PLANETKILLER
            Continue
          EndIf
          
          targetFound = 0
          targetX = -1
          targetY = -1
          
          ; AI Logic: Priority 1 - Hunt player if in same galaxy sector
          If mx = gMapX And my = gMapY
            ; PIRATE SPECIFIC BEHAVIOR
            If entType = #ENT_PIRATE
              If dilFactor < 10
                ; Wandering/Avoidance: Move AWAY from player if too close, or wander
                If Abs(x - gx) < 4 And Abs(y - gy) < 4
                  targetFound = 1
                  targetX = x - Sign(gx - x) * 3
                  targetY = y - Sign(gy - y) * 3
                ElseIf Random(99) < 40
                  targetFound = 1
                  targetX = x + (Random(2) - 1) * 2
                  targetY = y + (Random(2) - 1) * 2
                EndIf
              ElseIf dilFactor < 20
                ; Moderate interest: Only hunt if already somewhat close
                If Abs(x - gx) < 6 And Abs(y - gy) < 6
                  targetFound = 1
                  targetX = gx
                  targetY = gy
                ElseIf Random(99) < 30
                  targetFound = 1
                  targetX = x + (Random(2) - 1)
                  targetY = y + (Random(2) - 1)
                EndIf
              Else
                ; High Dilithium: Aggressive pursuit
                targetFound = 1
                targetX = gx
                targetY = gy
              EndIf
            Else
              ; Standard Enemy/Planet Killer: Always hunt player in same sector
              targetFound = 1
              targetX = gx
              targetY = gy
            EndIf
          Else
            ; Priority 2 - Move toward player's galaxy sector
            ; Pirates only change galaxy sectors if player has 15+ dilithium
            If entType <> #ENT_PIRATE Or dilFactor >= 15
              targetFound = 1
              targetX = x + Sign(gMapX - mx) * 5
              targetY = y + Sign(gMapY - my) * 5
            EndIf
          EndIf
          
          If targetFound = 1
            Protected moveX.i = x + Sign(targetX - x)
            Protected moveY.i = y + Sign(targetY - y)
            
            ; Handle galaxy sector transitions if at edge
            If moveX < 0 Or moveX >= #MAP_W Or moveY < 0 Or moveY >= #MAP_H
               ; For now, keep them in sector but they've "tried" to move
               moveX = ClampInt(moveX, 0, #MAP_W - 1)
               moveY = ClampInt(moveY, 0, #MAP_H - 1)
            EndIf

            If gGalaxy(mx, my, moveX, moveY)\entType = #ENT_EMPTY
              Protected oldEnt.i = gGalaxy(mx, my, x, y)\entType
              Protected oldName.s = gGalaxy(mx, my, x, y)\name
              Protected oldLevel.i = gGalaxy(mx, my, x, y)\enemyLevel
              If oldLevel < 1 : oldLevel = 1 : EndIf
              
              gGalaxy(mx, my, x, y)\entType = #ENT_EMPTY
              gGalaxy(mx, my, x, y)\name = ""
              gGalaxy(mx, my, x, y)\enemyLevel = 0
              
              gGalaxy(mx, my, moveX, moveY)\entType = oldEnt
              gGalaxy(mx, my, moveX, moveY)\name = oldName
              gGalaxy(mx, my, moveX, moveY)\enemyLevel = oldLevel
              
              ; Check for immediate combat
              If mx = gMapX And my = gMapY And moveX = gx And moveY = gy
                ; ... (combat logic handled in the loop below or via player move)
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

; IDE Options = PureBasic 6.30 (Windows - x64)
; Folding = ---
; EnableXP
; DPIAware