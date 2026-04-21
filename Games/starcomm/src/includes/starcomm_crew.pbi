; starcomm_crew.pbi
; Crew system: InitCrew, RankName, FleetRank, CrewRoleName, GainCrewXP, CrewBonus, PrintCrew, InitRecruitNames, GenerateRecruits, DismissCrew, RecruitCrew, CrewPositionFilled, AllCrewPositionsFilled, LoadShip, LoadGameSettingString, SaveAlloc
; XIncluded from starcomm.pb

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

;==============================================================================
; FleetRank(*s.Ship) -> Integer [1..5]
; Returns the player's current fleet command rank, computed as the minimum
; level across all four crew members, clamped to [1, 5].
; Fleet rank 1 = can command 1 fleet ship; rank 5 = max 5 fleet ships.
;==============================================================================
Procedure.i FleetRank(*s.Ship)
  Protected minLvl.i = *s\crew1\level
  If *s\crew2\level < minLvl : minLvl = *s\crew2\level : EndIf
  If *s\crew3\level < minLvl : minLvl = *s\crew3\level : EndIf
  If *s\crew4\level < minLvl : minLvl = *s\crew4\level : EndIf
  ProcedureReturn ClampInt(minLvl, 1, 5)
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
  Protected fleetRankBefore.i = FleetRank(*s)
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

  ; Check if Fleet Rank increased due to this level-up
  Protected fleetRankAfter.i = FleetRank(*s)
  If fleetRankAfter > fleetRankBefore
    PrintN("")
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("*** Fleet Rank increased to " + Str(fleetRankAfter) + "/5! You can now command " + Str(fleetRankAfter) + " supporting ships! ***")
    ResetColor()
    LogLine("FLEET RANK UP: now rank " + Str(fleetRankAfter))
  EndIf
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

  Protected recruitCost.i = 75  ; base signing fee in credits
  If gCredits < recruitCost
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("Not enough credits to recruit! Signing fee: " + Str(recruitCost) + " credits (have " + Str(gCredits) + ").")
    ResetColor()
    ProcedureReturn
  EndIf

  Protected roleName.s = gRecruitRoles(index)
  Protected newName.s = gRecruitNames(index)

  gCredits - recruitCost
  ConsoleColor(#C_YELLOW, #C_BLACK)
  PrintN("Signing fee paid: -" + Str(recruitCost) + " credits.")
  ResetColor()

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

  LogLine("CREW: recruited " + newName + " as " + roleName + " (-" + Str(recruitCost) + " cr)")

  ; Generate new recruits
  GenerateRecruits()
EndProcedure

Procedure RecruitHeadhunter(*p.Ship, role.i)
  Protected headhunterCost.i = 500
  Protected fleetRankCap.i = FleetRank(*p)
  
  ; Check if player can command more fleet ships
  If gPlayerFleetCount >= fleetRankCap
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("Fleet is full! (Fleet Rank " + Str(fleetRankCap) + " allows " + Str(fleetRankCap) + " ships).")
    PrintN("Level up your existing crew to expand your command capacity.")
    ResetColor()
    ProcedureReturn
  EndIf

  If gCredits < headhunterCost
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("Not enough credits for headhunting! Fee: " + Str(headhunterCost) + " credits (have " + Str(gCredits) + ").")
    ResetColor()
    ProcedureReturn
  EndIf

  gCredits - headhunterCost
  
  ; Create a new fleet ship instead of replacing main crew
  Protected newFleetIdx.i = gPlayerFleetCount + 1
  CopyStructure(*p, @gPlayerFleet(newFleetIdx), Ship)
  
  ; If Power Overwhelming is active, new fleet ships should not inherit the doubled stats permanently
  If gPowerBuff = 1
    gPlayerFleet(newFleetIdx)\hullMax      = gPlayerFleet(newFleetIdx)\hullMax      / 2
    gPlayerFleet(newFleetIdx)\shieldsMax   = gPlayerFleet(newFleetIdx)\shieldsMax   / 2
    gPlayerFleet(newFleetIdx)\reactorMax   = gPlayerFleet(newFleetIdx)\reactorMax   / 2
    gPlayerFleet(newFleetIdx)\weaponCapMax = gPlayerFleet(newFleetIdx)\weaponCapMax / 2
    gPlayerFleet(newFleetIdx)\warpMax      = gPlayerFleet(newFleetIdx)\warpMax      / 2.0
    gPlayerFleet(newFleetIdx)\impulseMax   = gPlayerFleet(newFleetIdx)\impulseMax   / 2.0
    gPlayerFleet(newFleetIdx)\phaserBanks  = gPlayerFleet(newFleetIdx)\phaserBanks  - 1
    gPlayerFleet(newFleetIdx)\torpTubes    = gPlayerFleet(newFleetIdx)\torpTubes    - 1
    gPlayerFleet(newFleetIdx)\torpMax      = gPlayerFleet(newFleetIdx)\torpMax      / 2
    gPlayerFleet(newFleetIdx)\sensorRange  = gPlayerFleet(newFleetIdx)\sensorRange  - 5
    gPlayerFleet(newFleetIdx)\fuelMax      = gPlayerFleet(newFleetIdx)\fuelMax      / 2
    gPlayerFleet(newFleetIdx)\oreMax       = gPlayerFleet(newFleetIdx)\oreMax       / 2
    gPlayerFleet(newFleetIdx)\dilithiumMax = gPlayerFleet(newFleetIdx)\dilithiumMax / 2
    gPlayerFleet(newFleetIdx)\probesMax    = gPlayerFleet(newFleetIdx)\probesMax    / 2
  EndIf

  Protected roleName.s = CrewRoleName(role)
  Protected newName.s = gFirstNames(Random(29)) + " " + gLastNames(Random(29))
  
  gPlayerFleet(newFleetIdx)\name = "Fleet " + roleName + " (" + newName + ")"
  gPlayerFleet(newFleetIdx)\hull = gPlayerFleet(newFleetIdx)\hullMax
  gPlayerFleet(newFleetIdx)\shields = gPlayerFleet(newFleetIdx)\shieldsMax
  
  ; Set the ship's specialization based on the role
  Select role
    Case #CREW_HELM
      gPlayerFleet(newFleetIdx)\allocEngines = 60
      gPlayerFleet(newFleetIdx)\allocWeapons = 20
      gPlayerFleet(newFleetIdx)\allocShields = 20
    Case #CREW_WEAPONS
      gPlayerFleet(newFleetIdx)\allocEngines = 20
      gPlayerFleet(newFleetIdx)\allocWeapons = 60
      gPlayerFleet(newFleetIdx)\allocShields = 20
    Case #CREW_SHIELDS
      gPlayerFleet(newFleetIdx)\allocEngines = 20
      gPlayerFleet(newFleetIdx)\allocWeapons = 20
      gPlayerFleet(newFleetIdx)\allocShields = 60
    Case #CREW_ENGINEERING
      gPlayerFleet(newFleetIdx)\allocEngines = 33
      gPlayerFleet(newFleetIdx)\allocWeapons = 33
      gPlayerFleet(newFleetIdx)\allocShields = 34
  EndSelect
  
  gPlayerFleetCount = newFleetIdx
  
  ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
  PrintN("Headhunter " + newName + " has joined your fleet in a specialized " + roleName + " ship!")
  ResetColor()
  
  LogLine("FLEET: headhunted " + roleName + " ship (" + newName + ") for " + Str(headhunterCost) + " cr")
EndProcedure

Procedure ResetCrewMember(*c.Crew, role.i)
  *c\name = "Replacement " + Str(Random(999))
  *c\role = role
  *c\rank = #RANK_ENSIGN
  *c\xp = 0
  *c\level = 1
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

  ; Sane clamps (Raised for Tier 2 and Power Overwhelming compatibility)
  *s\hullMax     = ClampInt(*s\hullMax, 10, 2000)
  *s\shieldsMax  = ClampInt(*s\shieldsMax, 0, 2000)
  *s\reactorMax  = ClampInt(*s\reactorMax, 50, 2000)
  *s\warpMax     = ClampF(*s\warpMax, 0.0, 30.0)
  *s\impulseMax  = ClampF(*s\impulseMax, 0.0, 5.0)
  *s\phaserBanks = ClampInt(*s\phaserBanks, 0, 50)
  *s\torpMax     = ClampInt(*s\torpMax, 0, 200)
  *s\torpTubes   = ClampInt(*s\torpTubes, 0, 16)
  If *s\torpMax > 0 And *s\torpTubes > *s\torpMax : *s\torpTubes = *s\torpMax : EndIf
  *s\sensorRange = ClampInt(*s\sensorRange, 1, 120)
  *s\weaponCapMax= ClampInt(*s\weaponCapMax, 10, 4000)
  *s\fuelMax     = ClampInt(*s\fuelMax, 10, 2000)
  *s\oreMax      = ClampInt(*s\oreMax, 0, 1000)
  *s\dilithiumMax = ClampInt(*s\dilithiumMax, 0, 200)
  *s\probesMax    = ClampInt(*s\probesMax, 0, 100)

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
  *s\weaponCap = *s\weaponCapMax
  *s\fuel      = *s\fuelMax
  *s\probes    = *s\probesMax
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
