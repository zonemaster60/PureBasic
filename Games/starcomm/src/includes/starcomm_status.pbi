; starcomm_status.pbi
; Status display: IsAlive, PrintStatusGalaxy, PrintStatusTactical
; XIncluded from starcomm.pb

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
  Print(FormatStardate())
  If gCheatCode <> "" And gCheatsUnlocked = 0
    ConsoleColor(#C_YELLOW, #C_BLACK)
    Print("   *** SECRET CODE: " + gCheatCode + " ***")
  EndIf
  PrintN("")
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
  If *p\fuel <= 10
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("  !! LOW FUEL: " + Str(*p\fuel) + " remaining - dock at a starbase or use REFUEL !!")
    ResetColor()
  EndIf
  Protected totalCargo.i = *p\ore + *p\dilithium
  Protected maxCargo.i   = *p\oreMax + *p\dilithiumMax
  If maxCargo > 0 And (totalCargo * 100 / maxCargo) >= 90
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("  !! CARGO NEARLY FULL: " + Str(totalCargo) + "/" + Str(maxCargo) + " - sell or refine at a station !!")
    ResetColor()
  EndIf
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
    PrintN("  WARP RECHARGING: " + Str(gWarpCooldown) + " turn(s) remaining (costs 5 dilithium)")
    ResetColor()
  ElseIf *p\dilithium >= 5
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
    PrintN("  WARP READY: costs 5 dilithium (you have " + Str(*p\dilithium) + ")")
    ResetColor()
  Else
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("  WARP OFFLINE: need 5 dilithium (you have " + Str(*p\dilithium) + ")")
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
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
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
    Print("Your Fleet: ")
    Protected pflIdx.i
    For pflIdx = 1 To gPlayerFleetCount
      Print("#" + Str(pflIdx) + ":")
      SetColorForPercent(Int(100.0 * gPlayerFleet(pflIdx)\hull / ClampInt(gPlayerFleet(pflIdx)\hullMax, 1, 999999)))
      Print(Str(gPlayerFleet(pflIdx)\hull) + "/" + Str(gPlayerFleet(pflIdx)\hullMax))
      ResetColor()
      Print(" ")
    Next
    PrintN("")
  EndIf
  If gEnemyFleetCount > 0
    Print("Enemy Fleet: ")
    Protected eflIdx.i
    For eflIdx = 1 To gEnemyFleetCount
      Print("#" + Str(eflIdx) + ":")
      SetColorForPercent(Int(100.0 * gEnemyFleet(eflIdx)\hull / ClampInt(gEnemyFleet(eflIdx)\hullMax, 1, 999999)))
      Print(Str(gEnemyFleet(eflIdx)\hull) + "/" + Str(gEnemyFleet(eflIdx)\hullMax))
      ResetColor()
      Print(" ")
    Next
    PrintN("")
  EndIf
  PrintN("You:   " + *p\name + " [" + *p\class + "]")
  Print("  Hull: ")
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
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
  Print("  Crew: Helm:")
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  If *p\crew1\name <> ""
    Print(*p\crew1\name + "(Lv" + Str(*p\crew1\level) + ")")
  Else
    Print("None")
  EndIf
  ResetColor()
  Print(" | Wpn:")
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  If *p\crew2\name <> ""
    Print(*p\crew2\name + "(Lv" + Str(*p\crew2\level) + ")")
  Else
    Print("None")
  EndIf
  ResetColor()
  Print(" | Shld:")
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  If *p\crew3\name <> ""
    Print(*p\crew3\name + "(Lv" + Str(*p\crew3\level) + ")")
  Else
    Print("None")
  EndIf
  ResetColor()
  Print(" | Eng:")
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  If *p\crew4\name <> ""
    PrintN(*p\crew4\name + "(Lv" + Str(*p\crew4\level) + ")")
  Else
    PrintN("None")
  EndIf
  ResetColor()

  PrintArenaTactical(*p, *e, *cs)
  PrintN("")

  ; Check if in range for weapons (Typical range for drones/enemy attacks is <= 15)
  If *cs\range <= 15 And (*p\weaponCap > 0 Or *p\torp > 0) And *p\sysWeapons <> #SYS_DISABLED
    ConsoleColor(#C_CYAN, #C_BLACK)
    PrintN("You are now in range. Ready to fire!")
    ResetColor()
  EndIf

  ConsoleColor(#C_LIGHTRED, #C_BLACK)

  PrintN("Enemy: " + *e\name + " [" + *e\class + "]")
  ResetColor()
  Print("  Hull: ")
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  SetColorForPercent(Int(100.0 * *e\hull / ClampInt(*e\hullMax, 1, 999999)))
  Print(Str(*e\hull) + "/" + Str(*e\hullMax))
  ResetColor()
  Print("  Shields: ")
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN(Str(*e\shields) + "/" + Str(*e\shieldsMax))
  ResetColor()
  PrintDivider()
EndProcedure
