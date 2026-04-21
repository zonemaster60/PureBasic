; starcomm_combat2.pbi
; Combat entry/exit: EnterCombat, LeaveCombat
; XIncluded from starcomm.pb

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
  *p\sysTractor = *p\sysTractor & ~#SYS_TRACTOR
  gMode = #MODE_TACTICAL
  *cs\range = 16 + Random(10)
  *cs\turn = 1
  *cs\pAim = 0
  *cs\eAim = 0
  *cs\pFleetAttack = 0
  *cs\pFleetHit = 0
  *cs\eFleetAttack = 0
  *cs\eFleetHit = 0
  
  ; Spawn enemy fleet based on the tracked hostile contact, not the player's cell.
  Protected enemyLvl.i = 1
  If gEnemyMapX >= 0 And gEnemyMapY >= 0 And gEnemyX >= 0 And gEnemyY >= 0
    enemyLvl = gGalaxy(gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)\enemyLevel
  EndIf
  If enemyLvl < 1 : enemyLvl = 1 : EndIf
  
  ; Tier 2 Enemy Scaling: Levels 10+ gain significant stat boosts to match Tier 2 player
  If enemyLvl >= 10
    *enemy\hullMax + (enemyLvl - 9) * 100
    *enemy\hull = *enemy\hullMax
    *enemy\shieldsMax + (enemyLvl - 9) * 80
    *enemy\shields = *enemy\shieldsMax
    *enemy\phaserBanks + (enemyLvl / 5)
    *enemy\torpTubes + (enemyLvl / 10)
    *enemy\weaponCapMax + (enemyLvl * 50)
    *enemy\weaponCap = *enemy\weaponCapMax
    If *enemy\class = "Planet Killer"
      *enemy\hullMax * 1.5
      *enemy\hull = *enemy\hullMax
      *enemy\shieldsMax * 1.5
      *enemy\shields = *enemy\shieldsMax
    EndIf
  EndIf

  If enemyLvl > 3 And *enemy\class <> "Planet Killer"
    gEnemyFleetCount = Random(1) + 1  ; 1-2 fleet ships
    ; Level 10+ enemies bring more support
    If enemyLvl >= 10 : gEnemyFleetCount + 1 : EndIf
    If enemyLvl >= 15 : gEnemyFleetCount + 1 : EndIf
    
    Protected efSetup.i
    For efSetup = 1 To gEnemyFleetCount
      CopyStructure(*enemy, @gEnemyFleet(efSetup), Ship)
      gEnemyFleet(efSetup)\hull = gEnemyFleet(efSetup)\hullMax
      gEnemyFleet(efSetup)\shields = gEnemyFleet(efSetup)\shieldsMax
      gEnemyFleet(efSetup)\name = "Enemy Fleet " + Str(efSetup)
    Next
  Else
    gEnemyFleetCount = 0
  EndIf

  PrintN("")
  PrintN("Red alert! Engaging enemy!")
  If gEnemyFleetCount > 0
    PrintN("WARNING: Enemy has " + Str(gEnemyFleetCount) + " supporting ships!")
  EndIf
  PrintStatusTactical(*p, *enemy, *cs)
  PrintN("")
  PrintN("Type HELP for combat commands.")
  PrintN("< Press ENTER to start battle >")
  Input()
  
  ; Log combat entry
  AddCaptainLog("COMBAT: Engaged " + *enemy\name + " at range " + Str(*cs\range))
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
  StopEngineLoop()
  gEnemyFleetCount = 0
  gEnemyIsPirate = 0
  gEnemyIsPlanetKiller = 0
  gEnemyMapX = -1 : gEnemyMapY = -1 : gEnemyX = -1 : gEnemyY = -1
  ; Combat-only tractor holds should not persist after battle.
  ; The active player ship instance remains in scope after returning to galaxy mode.
  If gDocked = 0
    StartEngineLoop()
  EndIf
EndProcedure
