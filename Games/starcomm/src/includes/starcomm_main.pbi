; starcomm_main.pbi
; Main game loop: Main()
; XIncluded from starcomm.pb

Procedure ResetGameState(*p.Ship)
  ; 1. Clear ship structure (crew, components, stats)
  StopEngineLoop()
  ClearStructure(*p, Ship)
  
  ; 2. Reset Global Game Progress
  gCredits = 0
  gBankBalance = 0
  gTotalKills = 0
  gTotalMissions = 0
  gTotalCreditsEarned = 0
  gGameTurn = 0
  gStardate = 25000.0
  gGameDay = 1
  
  ; 3. Reset Economy / Cargo
  gIron = 0 : gAluminum = 0 : gCopper = 0 : gTin = 0 : gBronze = 0
  
  ; 4. Reset Upgrades
  gUpgradeHull = 0 : gUpgradeShields = 0 : gUpgradeWeapons = 0
  gUpgradePropulsion = 0 : gUpgradePowerCargo = 0 : gUpgradeProbes = 0 : gUpgradeShuttle = 0
  
  ; 5. Reset Mission state
  ClearStructure(@gMission, Mission)
  gMission\type = #MIS_NONE
  
  ; 6. Reset World State
  gHQMissionsCompleted = 0
  gRecallArmed = 0
  gDocked = 0
  gWarpCooldown = 0
  gIonStormTurns = 0
  gRadiationTurns = 0
  gPowerBuff = 0
  gPowerBuffTurns = 0
  gCheatsUnlocked = 0
  gCheatCode = ""
  gCheatCodeTurn = 0
  gLastHeading = -1
  gAutosaveCounter = 0
  gAutoclearCounter = 0
  
  ; 7. Reset Fleet
  gPlayerFleetCount = 0
  Dim gPlayerFleet.Ship(5)
  
  ; 8. Reset Logging
  gCaptainLogCount = 0
  gCurrentArchive = 0
  gTotalArchives = 0
  Dim gCaptainLog.s(1000)
  Dim gCaptainArchive1.s(1000)
  Dim gCaptainArchive2.s(1000)
  Dim gCaptainArchive3.s(1000)
  Dim gCaptainArchive4.s(1000)
  Dim gCaptainArchive5.s(1000)
  Dim gCaptainArchive6.s(1000)
  Dim gCaptainArchive7.s(1000)
  Dim gCaptainArchive8.s(1000)
  Dim gCaptainArchive9.s(1000)
  Dim gCaptainArchive10.s(1000)
  Dim gArchive1Count.i(10)

  ; 9. Reset transient command/session state
  gUndoAvailable = 0
  gUndoMapX = 0 : gUndoMapY = 0 : gUndoX = 0 : gUndoY = 0
  gUndoFuel = 0 : gUndoHull = 0 : gUndoShields = 0
  gUndoCredits = 0 : gUndoMode = 0
  gUndoOre = 0 : gUndoDilithium = 0
  gUndoIron = 0 : gUndoAluminum = 0 : gUndoCopper = 0 : gUndoTin = 0 : gUndoBronze = 0
  gMacroPlaybackActive = 0
  gMacroPlaybackName = ""
  gMacroQueueSize = 0
  gMacroQueuePos = 0
  Dim gMacroQueue.s(#MACRO_QUEUE_MAX - 1)
  gShuttleLaunched = 0
  gShuttleCrew = 2
  gShuttleCargoOre = 0
  gShuttleCargoDilithium = 0
  gShuttleMaxCargo = 10
  gShuttleMaxCrew = 6
  gShuttleAttackRange = 10
  gTransporterPower = 50
  gTransporterRange = 5
  gTransporterCrew = 2
  gProbeRange = 3
  gProbeAccuracy = 75
  gEnemyMapX = -1 : gEnemyMapY = -1 : gEnemyX = -1 : gEnemyY = -1
  gEnemyIsPirate = 0
  gEnemyIsPlanetKiller = 0
  gEnemyFleetCount = 0
  gDockedShipCount = 0
  gStationType = 0

  ; 10. Reset Galaxy
  GenerateGalaxy()

  ; 11. Re-initialize basic data
  InitRecruitNames()
  GenerateRecruits()
  
  ; LogLine("Game state reset to factory defaults.") ; Silenced for cleaner startup
EndProcedure

Procedure BeginEnemyContact(*p.Ship, *enemyTemplate.Ship, *enemy.Ship, *cs.CombatState, mapX.i, mapY.i, x.i, y.i)
  Protected entType.i = gGalaxy(mapX, mapY, x, y)\entType
  Protected lvl.i = gGalaxy(mapX, mapY, x, y)\enemyLevel
  If lvl < 1 : lvl = 1 : EndIf

  gEnemyMapX = mapX
  gEnemyMapY = mapY
  gEnemyX = x
  gEnemyY = y

  CopyStructure(*enemyTemplate, *enemy, Ship)
  If gGalaxy(mapX, mapY, x, y)\name <> ""
    *enemy\name = gGalaxy(mapX, mapY, x, y)\name
  EndIf

  If entType = #ENT_PLANETKILLER
    *enemy\name = "Planet Killer"
    *enemy\class = "Planet Killer"
    *enemy\hullMax = 500 + (lvl * 50)
    *enemy\hull = *enemy\hullMax
    *enemy\shieldsMax = 400 + (lvl * 40)
    *enemy\shields = *enemy\shieldsMax
    *enemy\weaponCapMax = 600 + (lvl * 50)
    *enemy\weaponCap = *enemy\weaponCapMax
    *enemy\phaserBanks = 12
    *enemy\torpTubes = 4
    *enemy\torpMax = 20
    *enemy\torp = *enemy\torpMax
  Else
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
    *enemy\hullMax + (lvl * 10)
    *enemy\hull = *enemy\hullMax
    *enemy\shieldsMax + (lvl * 12)
    *enemy\shields = *enemy\shieldsMax
    *enemy\weaponCapMax + (lvl * 20)
    *enemy\weaponCap = *enemy\weaponCapMax / 2
    *enemy\torp = *enemy\torpMax
  EndIf

  gEnemyIsPirate = Bool(entType = #ENT_PIRATE)
  gEnemyIsPlanetKiller = Bool(entType = #ENT_PLANETKILLER)
  EnterCombat(*p, *enemy, *cs)
EndProcedure

Procedure Main()
  Protected player.Ship
  Protected enemyTemplate.Ship
  Protected enemy.Ship
  Protected cs.CombatState
  Protected enemyAIPendingContact.i
  Protected playerSection.s
  Protected enemySection.s


  RandomSeed(Date())

  If OpenConsole(#APP_NAME + " " + version) = 0
    MessageRequester("Error", "Unable to open console")
    End
  EndIf

  InitLogging()
  InitMacroFolder()
  OnErrorCall(@CrashHandler())

  ConsoleColor(#C_WHITE, #C_BLACK)
  PrintN("Starship Console (Galaxy + Tactical)")
  ConsoleColor(#C_WHITE, #C_BLACK)
  PrintN("Data: " + GetFilePart(gDatPath) + " (fallback " + GetFilePart(gIniPath) + ")")
  ResetColor()
  PrintN("")

  InitShipData()
  InitSounds()

  Repeat ; Main Loop for returning to Startup Menu
    ; Initial state for a fresh game
    ResetGameState(@player)
    
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

    ; Starcomm Startup Console
    ClearConsole()
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("--- STARCOMM STARTUP CONSOLE ---")
    ConsoleColor(#C_WHITE, #C_BLACK)
    PrintN("")
    Print("Welcome, Captain ")
    ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
    Print(player\crew1\name)
    ConsoleColor(#C_WHITE, #C_BLACK)
    PrintN(".")
    PrintN("")
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("Choose an option:")
    ConsoleColor(#C_WHITE, #C_BLACK)
    PrintN("  1. Start New Game")
    PrintN("  2. Load Game / Save Manager")
    If gSoundEnabled
      PrintN("  3. Sound: [ON]  (Type '3' to toggle)")
    Else
      PrintN("  3. Sound: [OFF] (Type '3' to toggle)")
    EndIf
    PrintN("  4. Exit")
    PrintN("")
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    Print("OPTION> ")
    ResetColor()
    Protected startupChoice.s = Trim(ReadConsoleInput())
    If startupChoice = Chr(4) Or startupChoice = Chr(26)
      End
    EndIf
    Protected skipInit.i = #False
    If startupChoice = "1"
      ; start new game
    ElseIf startupChoice = "2"
      If SaveGameManager(@player)
        skipInit = #True
      Else
        Continue
      EndIf
    ElseIf startupChoice = "3"
      gSoundEnabled = 1 - gSoundEnabled
      Continue
    ElseIf startupChoice = "4"
      PlaySoundFX(SoundAlarm)
      Protected quitStartup.i = MessageRequester("Starcomm", "Are you sure you want to exit?", #PB_MessageRequester_YesNo)
      If quitStartup = #PB_MessageRequester_Yes
        End
      Else
        Continue ; Return to startup menu
      EndIf
    Else
      PrintN("Invalid option. Choose 1, 2, 3, or 4.")
      Delay(700)
      Continue
    EndIf

    ; If we reach here, we are starting or continuing a game
    If skipInit = #False
      GenerateMission(@player)
    EndIf

    LogLine("Welcome aboard")

    PrintN("Sound: " + Str(gSoundEnabled))
    PlayBeepTest()
    If gDocked = 0
      StartEngineLoop()
    EndIf
    RedrawGalaxy(@player)

    While IsAlive(@player)
      Protected loopTurnStart.i = gGameTurn
      Protected loopStardateStart.f = gStardate
      ; Refresh macro conditional mirrors so GetNextInput() can check ship state
      If player\fuelMax    > 0 : gMacroFuelPct    = (player\fuel    * 100) / player\fuelMax    : EndIf
      If player\hullMax    > 0 : gMacroHullPct    = (player\hull    * 100) / player\hullMax    : EndIf
      If player\shieldsMax > 0 : gMacroShieldsPct = (player\shields * 100) / player\shieldsMax : EndIf
      gMacroTorpCount = player\torp
      gMacroOre       = player\ore
      gMacroDilithium = player\dilithium
      gMacroOreMax    = player\oreMax
      ; RECALL auto-prompt: warn when hull is critical and beacon is armed
      If gRecallArmed = 1 And gDocked = 0 And player\hullMax > 0
        If player\hull <= Int(player\hullMax * 0.25)
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("Hull critical! RECALL beacon armed - type RECALL to emergency jump home.")
          ResetColor()
        EndIf
      EndIf
      ConsoleColor(#C_WHITE, #C_BLACK)
      If gMacroPlaybackActive = 0
        Print("CMD> ")
      EndIf
      Protected lineRaw.s = GetNextInput()
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
      
      If cmd = "exit" Or cmd = "quit"
        Break ; Return to the startup menu
      EndIf


    If cmd = "" : cmd = "end" : EndIf

    ; RECALL: emergency jump to HQ (any mode, not docked)
    If cmd = "recall" And gDocked = 0
      If gRecallArmed = 0
        PrintN("No recall beacon armed. Dock at Starcomm HQ and type RECALL to arm one.")
      ElseIf gMapX = gHQMapX And gMapY = gHQMapY
        PrintN("Already in HQ sector. Recall not needed.")
      Else
        ; Jump to HQ sector, adjacent to HQ cell
        Protected recallDestX.i = gHQX
        Protected recallDestY.i = gHQY - 1
        If recallDestY < 0 : recallDestY = gHQY + 1 : EndIf
        If recallDestY >= #MAP_H : recallDestY = gHQY : EndIf
        gMapX = gHQMapX
        gMapY = gHQMapY
        gx    = recallDestX
        gy    = recallDestY
        player\fuel = 0
        gRecallArmed = 0
        ConsoleColor(#C_YELLOW, #C_BLACK)
        PrintDivider()
        PrintN("*** EMERGENCY RECALL ACTIVATED - jumped to Starcomm HQ. Fuel depleted. ***")
        PrintDivider()
        ResetColor()
        LogLine("RECALL: emergency jump to HQ (" + Str(gHQMapX) + "," + Str(gHQMapY) + "), fuel depleted")
        AddCaptainLog("RECALL: jumped home")
        PlaySoundFX(SoundWarp)
        RedrawGalaxy(@player)
      EndIf
      Continue
    EndIf

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
      ElseIf cmd = "code"
        Protected galCodeArg.s = TokenAt(line, 2)
        If gCheatsUnlocked = 1
          PrintN("Cheats are already unlocked!")
        ElseIf galCodeArg = ""
          PrintN("Usage: CODE <4-digit-number>")
          PrintN("A secret code appears every 10 turns. Watch for it!")
        ElseIf CheckCheatCode(galCodeArg)
          ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
          PrintN("*** CHEATS UNLOCKED! ***")
          PrintN("You now have access to all cheat commands!")
          ResetColor()
        Else
          ConsoleColor(#C_LIGHTRED, #C_BLACK)
          PrintN("Invalid code. The code changes every 10 turns.")
          ResetColor()
        EndIf
      ElseIf cmd = "status"
        RedrawGalaxy(@player)
        PrintN("Fleet Rank: " + Str(FleetRank(@player)) + "/5  (can command " + Str(FleetRank(@player)) + " fleet ships)")
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
        Protected logQuickStart.i = gCaptainLogCount - 20
        If logQuickStart < 0 : logQuickStart = 0 : EndIf
        PrintDivider()
        PrintN("Captain's Log (last 20 entries):")
        PrintN("")
        Protected logQuickI.i
        For logQuickI = logQuickStart To gCaptainLogCount - 1
          If gCaptainLog(logQuickI) <> ""
            PrintN(gCaptainLog(logQuickI))
          EndIf
        Next
        PrintN("")
        PrintN("Total entries: " + Str(gCaptainLogCount))
        PrintN("Use TERMINAL > LOG for search, archives and purge.")
        PrintDivider()
        PrintN("< Press ENTER >")
        Input()
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
        Protected totalUpgrades.i = gUpgradeHull + gUpgradeShields + gUpgradeWeapons + gUpgradePropulsion + gUpgradePowerCargo + gUpgradeProbes + gUpgradeShuttle
        PrintN("=== INSTALLED UPGRADES ===")
        If totalUpgrades >= 21
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("--- TIER 2 ADVANCED STATUS ---")
          ResetColor()
        Else
          PrintN("--- TIER 1 STANDARD STATUS ---")
        EndIf
        PrintN("HULL & ARMOR:      " + Str(gUpgradeHull) + " upgrades")
        PrintN("SHIELDS:           " + Str(gUpgradeShields) + " upgrades")
        PrintN("WEAPONS:           " + Str(gUpgradeWeapons) + " upgrades")
        PrintN("PROPULSION:        " + Str(gUpgradePropulsion) + " upgrades")
        PrintN("POWER & CARGO:     " + Str(gUpgradePowerCargo) + " upgrades")
        PrintN("PROBES:            " + Str(gUpgradeProbes) + " upgrades")
        PrintN("SHUTTLE:           " + Str(gUpgradeShuttle) + " upgrades")
        PrintN("")
        PrintN("Total upgrades: " + Str(totalUpgrades))
        If totalUpgrades < 21
          PrintN("Install " + Str(21 - totalUpgrades) + " more standard upgrades to unlock Tier 2.")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "fleet"
        Protected fleetCmd.s = TrimLower(TokenAt(line, 2))
        If fleetCmd = ""
          PrintN("=== YOUR FLEET ===")
          Protected fleetRankDisp.i = FleetRank(@player)
          PrintN("Fleet Rank: " + Str(fleetRankDisp) + "/5  (max " + Str(fleetRankDisp) + " ships)")
          PrintN("Player ship: " + player\name + " (" + player\class + ")")
          If gPlayerFleetCount > 0
            Protected f.i
            For f = 1 To gPlayerFleetCount
              PrintN("  Fleet " + Str(f) + ": " + gPlayerFleet(f)\name + " (" + gPlayerFleet(f)\class + ") - Hull: " + Str(gPlayerFleet(f)\hull) + "/" + Str(gPlayerFleet(f)\hullMax))
            Next
          EndIf
          PrintN("Total fleet ships: " + Str(gPlayerFleetCount) + "/" + Str(FleetRank(@player)))
        ElseIf fleetCmd = "add"
          Protected fleetRankCap.i = FleetRank(@player)
          If gPlayerFleetCount >= fleetRankCap
            PrintN("Fleet is full (Fleet Rank " + Str(fleetRankCap) + " allows " + Str(fleetRankCap) + " ships). Level up all crew to expand.")
          ElseIf gDocked = 0
            PrintN("Must be docked at a starbase to add fleet ships.")
          Else
            Protected newFleetIdx.i = gPlayerFleetCount + 1
            CopyStructure(@player, @gPlayerFleet(newFleetIdx), Ship)
            gPlayerFleet(newFleetIdx)\name = "Fleet Ship " + Str(newFleetIdx)
            gPlayerFleet(newFleetIdx)\hull = gPlayerFleet(newFleetIdx)\hullMax
            gPlayerFleet(newFleetIdx)\shields = gPlayerFleet(newFleetIdx)\shieldsMax
            gPlayerFleetCount = newFleetIdx
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
          Protected navDir.s = TokenAt(line, 2)
          If navDir = ""
            PrintN("Usage: NAV <heading> [steps]")
            PrintN("  Headings : 0=N  45=NE  90=E  135=SE  180=S  225=SW  270=W  315=NW")
            PrintN("  Examples : NAV 0       (north 1 sector, costs 1 fuel)")
            PrintN("             NAV 90 3    (east 3 sectors, costs 3 fuel)")
            PrintN("             NAV 225 2   (southwest 2 sectors, costs 2 fuel)")
            RedrawGalaxy(@player)
            Continue
          Else
          SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode, gIron, gAluminum, gCopper, gTin, gBronze)
          Protected navSteps.i = ParseIntSafe(TokenAt(line, 3), 1)
          Protected navMoved.i
          Protected oldX.i = gx
          Protected oldY.i = gy
          navMoved = Nav(@player, navDir, navSteps, @enemyTemplate, @cs)
          If gMode = #MODE_TACTICAL : Continue : EndIf
          If navMoved <= 0
            RedrawGalaxy(@player)
            Continue
          EndIf

          ; Track last intended heading for compass display (set even if movement was blocked)
          Protected navHeadVal.i = ParseIntSafe(navDir, -1)
          Select navHeadVal
            Case 0, 45, 90, 135, 180, 225, 270, 315
              gLastHeading = navHeadVal
          EndSelect

          ; Log the movement
          If gx <> oldX Or gy <> oldY
            AddCaptainLog("NAV: " + navDir + " to (" + Str(gMapX) + "," + Str(gMapY) + ") sector (" + Str(gx) + "," + Str(gy) + ")")
          EndIf
          
          If navMoved > 0
            AdvanceStardate(navMoved)
          EndIf
          
          ; Dilithium bounty - high dilithium attracts pirates!
          If player\dilithium >= 15
            Protected bountyRoll.i = Random(99)
            Protected bountyChance.i = (player\dilithium - 14) * 2  ; 2% per crystal over 14
            If bountyChance > 20 : bountyChance = 20 : EndIf
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
          EndIf  ; end navDir <> "" check

        If CurCell(gx, gy)\entType = #ENT_ENEMY Or CurCell(gx, gy)\entType = #ENT_PIRATE Or CurCell(gx, gy)\entType = #ENT_PLANETKILLER
          Protected contactLvl.i = CurCell(gx, gy)\enemyLevel
          Protected threatStr.s
          If contactLvl <= 2
            threatStr = "Minor"
          ElseIf contactLvl <= 4
            threatStr = "Moderate"
          ElseIf contactLvl <= 6
            threatStr = "Serious"
          ElseIf contactLvl <= 8
            threatStr = "Severe"
          Else
            threatStr = "Critical"
          EndIf
          ConsoleColor(#C_LIGHTRED, #C_BLACK)
          PrintN("!! ENEMY CONTACT !! " + CurCell(gx, gy)\name + " (Level " + Str(contactLvl) + " - " + threatStr + ")")
          ResetColor()
          ConsoleColor(#C_WHITE, #C_BLACK)
          Print("Engage? (F)ight / (A)bort > ")
          Protected engageResp.s = Input()
          engageResp = ReplaceString(engageResp, Chr(13), "")
          engageResp = ReplaceString(engageResp, Chr(10), "")
          engageResp = TrimLower(Trim(engageResp))
          
          If engageResp <> "a" And engageResp <> "abort"
            ; Fight!
            BeginEnemyContact(@player, @enemyTemplate, @enemy, @cs, gMapX, gMapY, gx, gy)
            Continue
          Else
            PrintN("You evade the enemy and continue exploring.")
          EndIf
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
        
        enemyAIPendingContact = EnemyGalaxyAI(@player, @enemyTemplate, @cs)
        If enemyAIPendingContact
          ConsoleColor(#C_LIGHTRED, #C_BLACK)
          PrintN("Enemy contact! Hostile vessel has closed to your position.")
          ResetColor()
          BeginEnemyContact(@player, @enemyTemplate, @enemy, @cs, gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)
          Continue
        EndIf
        EndIf
      ElseIf cmd = "warp"
        If gDocked
          PrintN("You are docked. Use UNDOCK first.")
        ElseIf gWarpCooldown > 0
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("Warp engines recharging: " + Str(gWarpCooldown) + " turn(s) remaining. (costs 5 dilithium per jump)")
          ResetColor()
        ElseIf player\dilithium < 5
          ConsoleColor(#C_LIGHTRED, #C_BLACK)
          PrintN("Insufficient dilithium. Need 5 to warp (have " + Str(player\dilithium) + ").")
          ResetColor()
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
            PlaySoundFX(SoundEngage)
            Delay(100)
            PlaySoundFX(SoundWarp)
            PrintN("Warping to galaxy (" + Str(warpX) + "," + Str(warpY) + ")!")
            LogLine("WARP: to galaxy " + Str(warpX) + "," + Str(warpY))
            
            ; Pirate Interdiction: Chance to be intercepted by a pirate during warp exit
            ; Prevent interdiction if warping into a Starcomm HQ sector
            If Random(99) < 15 And gGalaxy(gMapX, gMapY, gx, gy)\entType <> #ENT_HQ
              Protected warpPirateX.i, warpPirateY.i
              If RandomEmptyCell(gMapX, gMapY, @warpPirateX, @warpPirateY)
                gx = warpPirateX
                gy = warpPirateY
                gGalaxy(gMapX, gMapY, gx, gy)\entType = #ENT_PIRATE
                gGalaxy(gMapX, gMapY, gx, gy)\name = "Interdictor Raider"
                gGalaxy(gMapX, gMapY, gx, gy)\enemyLevel = 3 + Random(4)
                
                ConsoleColor(#C_LIGHTRED, #C_BLACK)
                PrintN("!! WARP INTERDICTED !! A pirate fleet has pulled you out of warp!")
                ResetColor()
                LogLine("INTERDICTION: pirate intercepted warp exit")
                
                ; Setup enemy and enter combat immediately
                BeginEnemyContact(@player, @enemyTemplate, @enemy, @cs, gMapX, gMapY, gx, gy)
                RedrawGalaxy(@player)
                Continue
              EndIf
            EndIf
          EndIf
        EndIf
        CheckMissionCompletion(@player)
        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        enemyAIPendingContact = EnemyGalaxyAI(@player, @enemyTemplate, @cs)
        If enemyAIPendingContact
          ConsoleColor(#C_LIGHTRED, #C_BLACK)
          PrintN("Enemy contact! Hostile vessel has closed to your position.")
          ResetColor()
          BeginEnemyContact(@player, @enemyTemplate, @enemy, @cs, gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)
          Continue
        EndIf
        AdvanceGameTurn(1)
        AdvanceStardate()
        RedrawGalaxy(@player)
      ElseIf cmd = "mine"
        If gDocked
          PrintN("You are docked. Use UNDOCK first.")
        Else
          SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode, gIron, gAluminum, gCopper, gTin, gBronze)
          MinePlanet(@player)
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
              SaveUndoState(player\fuel, player\hull, player\shields, gCredits, player\ore, player\dilithium, gMapX, gMapY, gx, gy, gMode, gIron, gAluminum, gCopper, gTin, gBronze)
              player\probes - 1
              LogLine("PROBE: launched to " + Str(targetMapX) + "," + Str(targetMapY))
              PrintN("Launching probe to galaxy (" + Str(targetMapX) + "," + Str(targetMapY) + ")...")
              PlayProbeSound()
              PrintProbeScan(targetMapX, targetMapY)
              AdvanceGameTurn(1)
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
        enemyAIPendingContact = EnemyGalaxyAI(@player, @enemyTemplate, @cs)
        If enemyAIPendingContact
          ConsoleColor(#C_LIGHTRED, #C_BLACK)
          PrintN("Enemy contact! Hostile vessel has closed to your position.")
          ResetColor()
          BeginEnemyContact(@player, @enemyTemplate, @enemy, @cs, gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)
          Continue
        EndIf
        AdvanceGameTurn(1)
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
        ElseIf CurCell(gx, gy)\entType = #ENT_BASE Or CurCell(gx, gy)\entType = #ENT_HQ
          DockAtBase(@player)
          If CurCell(gx, gy)\entType = #ENT_HQ
            AddCaptainLog("DOCKED at Starcomm HQ")
          Else
            AddCaptainLog("DOCKED at starbase")
          EndIf
        ElseIf CurCell(gx, gy)\entType = #ENT_REFINERY
          DockAtRefinery(@player)
          AddCaptainLog("DOCKED at refinery")
        Else
          PrintN("No starbase, shipyard, or refinery in this sector.")
        EndIf

        CheckMissionCompletion(@player)
        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        enemyAIPendingContact = EnemyGalaxyAI(@player, @enemyTemplate, @cs)
        If enemyAIPendingContact
          ConsoleColor(#C_LIGHTRED, #C_BLACK)
          PrintN("Enemy contact! Hostile vessel has closed to your position.")
          ResetColor()
          BeginEnemyContact(@player, @enemyTemplate, @enemy, @cs, gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)
          Continue
        EndIf
        AdvanceGameTurn(1)
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
          Protected recruitArg1.s = TrimLower(TokenAt(line, 2))
          If recruitArg1 = "head"
            Protected headRoleStrM.s = TrimLower(TokenAt(line, 3))
            Protected headRoleIdM.i = 0
            If headRoleStrM = "helm" : headRoleIdM = #CREW_HELM : EndIf
            If headRoleStrM = "weapons" : headRoleIdM = #CREW_WEAPONS : EndIf
            If headRoleStrM = "shields" : headRoleIdM = #CREW_SHIELDS : EndIf
            If headRoleStrM = "engineering" : headRoleIdM = #CREW_ENGINEERING : EndIf
            
            If headRoleIdM > 0
              RecruitHeadhunter(@player, headRoleIdM)
              AddCaptainLog("STARBASE: headhunted " + headRoleStrM + " officer")
            Else
              PrintN("Usage: RECRUIT HEAD <HELM|WEAPONS|SHIELDS|ENGINEERING>")
            EndIf
          Else
            Protected recruitIdx.i = ParseIntSafe(recruitArg1, 0) - 1
            If recruitIdx < 0 Or recruitIdx >= gRecruitCount
              PrintN("Usage: RECRUIT <1-3> or RECRUIT HEAD <role>")
            Else
              RecruitCrew(@player, recruitIdx)
              AddCaptainLog("STARBASE: recruited " + gRecruitNames(recruitIdx))
            EndIf
          EndIf
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "jettison"
        If gDocked
          PrintN("Cannot jettison cargo while docked.")
        Else
          Protected jettisonType.s = TrimLower(TokenAt(line, 2))
          If jettisonType = "ore"
            If player\ore <= 0
              PrintN("No ore to jettison.")
            Else
              Protected droppedOre.i = player\ore
              player\ore = 0
              PrintN("Jettisoned " + Str(droppedOre) + " ore into space.")
              LogLine("JETTISON: ore (" + Str(droppedOre) + ")")
              ; Place cargo container in current cell (cardinal neighbor if possible, else here)
              Protected dropX.i = gx, dropY.i = gy
              Protected findX.i, findY.i, dropFound.i = 0
              For findY = -1 To 1
                For findX = -1 To 1
                  If findX = 0 And findY = 0 : Continue : EndIf
                  If gx+findX >= 0 And gx+findX < #MAP_W And gy+findY >= 0 And gy+findY < #MAP_H
                    If gGalaxy(gMapX, gMapY, gx+findX, gy+findY)\entType = #ENT_EMPTY
                      dropX = gx+findX : dropY = gy+findY
                      dropFound = 1
                      Break 2
                    EndIf
                  EndIf
                Next
              Next
              gGalaxy(gMapX, gMapY, dropX, dropY)\entType = #ENT_CARGO
              gGalaxy(gMapX, gMapY, dropX, dropY)\name = "Jettisoned Ore"
              gGalaxy(gMapX, gMapY, dropX, dropY)\ore = droppedOre
              gGalaxy(gMapX, gMapY, dropX, dropY)\spawned = 1
            EndIf
          ElseIf jettisonType = "dilithium"
            If player\dilithium <= 0
              PrintN("No dilithium to jettison.")
            Else
              Protected droppedDil.i = player\dilithium
              player\dilithium = 0
              PrintN("Jettisoned " + Str(droppedDil) + " dilithium into space.")
              LogLine("JETTISON: dilithium (" + Str(droppedDil) + ")")
              ; Place cargo container
              Protected dDropX.i = gx, dDropY.i = gy
              Protected dFindX.i, dFindY.i, dDropFound.i = 0
              For dFindY = -1 To 1
                For dFindX = -1 To 1
                  If dFindX = 0 And dFindY = 0 : Continue : EndIf
                  If gx+dFindX >= 0 And gx+dFindX < #MAP_W And gy+dFindY >= 0 And gy+dFindY < #MAP_H
                    If gGalaxy(gMapX, gMapY, gx+dFindX, gy+dFindY)\entType = #ENT_EMPTY
                      dDropX = gx+dFindX : dDropY = gy+dFindY
                      dDropFound = 1
                      Break 2
                    EndIf
                  EndIf
                Next
              Next
              gGalaxy(gMapX, gMapY, dDropX, dDropY)\entType = #ENT_CARGO
              gGalaxy(gMapX, gMapY, dDropX, dDropY)\name = "Jettisoned Dilithium"
              gGalaxy(gMapX, gMapY, dDropX, dDropY)\dilithium = droppedDil
              gGalaxy(gMapX, gMapY, dDropX, dDropY)\spawned = 1
            EndIf
          Else
            PrintN("Usage: JETTISON <ORE|DILITHIUM>")
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
      ElseIf cmd = "missions"
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
        RedrawGalaxy(@player)

      ElseIf cmd = "computer"
        ; Autopilot to mission destination (best-effort)
        AutopilotToMission(@player, @enemyTemplate, @enemy, @cs)
        RedrawGalaxy(@player)
      ElseIf cmd = "abandon"
        If gMission\active = 0
          PrintN("No active mission to abandon.")
        Else
          PrintN("Abandon mission: " + gMission\title + "?")
          ConsoleColor(#C_YELLOW, #C_BLACK)
          Print("Are you sure? (YES to confirm) > ")
          ResetColor()
          Protected abandonResp.s = Input()
          abandonResp = TrimLower(Trim(ReplaceString(ReplaceString(abandonResp, Chr(13), ""), Chr(10), "")))
          If abandonResp = "yes"
            AbandonMission()
            GenerateMission(@player)
            PrintN("Mission abandoned.")
          Else
            PrintN("Abandon cancelled.")
          EndIf
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "save"
        Protected saveSlot.s = TokenAt(line, 2)
        If saveSlot = "" : saveSlot = "autosave" : EndIf
        SaveGame(@player, saveSlot)
        RedrawGalaxy(@player)
      ElseIf cmd = "load"
        Protected loadSlot.s = TokenAt(line, 2)
        If loadSlot = "" : loadSlot = "autosave" : EndIf
        If LoadGame(@player, loadSlot)
          RedrawGalaxy(@player)
        Else
          RedrawGalaxy(@player)
        EndIf
      ElseIf cmd = "saves"
        SaveGameManager(@player)
        RedrawGalaxy(@player)
      ElseIf cmd = "delete"
        Protected delSlot.s = TokenAt(line, 2)
        If delSlot <> ""
          DeleteSaveGame(delSlot)
        Else
          PrintN("Usage: DELETE <name>")
        EndIf
        RedrawGalaxy(@player)

      ElseIf gCheatsUnlocked = 1 And (cmd = "showmethemoney" Or cmd = "poweroverwhelming" Or cmd = "miner2049er" Or cmd = "spawnyard" Or cmd = "spawnbase" Or cmd = "spawnhq" Or cmd = "spawnrefinery" Or cmd = "spawncluster" Or cmd = "spawnwormhole" Or cmd = "spawnanomaly" Or cmd = "spawnplanetkiller" Or cmd = "removespawn")
        If cmd = "showmethemoney"
        gCredits + 500
        LogLine("CHEAT: showmethemoney (+500 credits)")
        PrintN("Cheat activated: +500 credits!")
        RedrawGalaxy(@player)
      ElseIf cmd = "poweroverwhelming"
        If gPowerBuff = 0
          gPowerBuff = 1
          gPowerBuffTurns = 30
          player\hullMax = player\hullMax * 2
          player\shieldsMax = player\shieldsMax * 2
          player\reactorMax = player\reactorMax * 2
          player\weaponCapMax = player\weaponCapMax * 2
          player\warpMax = player\warpMax * 2.0
          player\impulseMax = player\impulseMax * 2.0
          player\phaserBanks = player\phaserBanks + 1
          player\torpTubes = player\torpTubes + 1
          player\torpMax = player\torpMax * 2
          player\sensorRange = player\sensorRange + 5
          player\fuelMax = player\fuelMax * 2
          player\oreMax = player\oreMax * 2
          player\dilithiumMax = player\dilithiumMax * 2
          player\probesMax = player\probesMax * 2
          player\hull = player\hullMax
          player\shields = player\shieldsMax
          player\weaponCap = player\weaponCapMax
          player\torp = player\torpMax
          player\fuel = player\fuelMax
          player\probes = player\probesMax
          LogLine("CHEAT: poweroverwhelming (buff active)")
          PrintN("Cheat activated: POWER OVERWHELMING! All systems doubled!")
          PrintN("Buff will last for 30 turns or until death.")
        Else
          PrintN("Power Overwhelming is already active! Buff duration refreshed.")
          gPowerBuffTurns = 30
        EndIf
        gLastCmdLine = "" ; Clear the command line so it doesn't re-trigger
        RedrawGalaxy(@player)
      ElseIf cmd = "miner2049er"
        player\ore = player\oreMax
        player\dilithium = player\dilithiumMax
        player\fuel = player\fuelMax
        player\probes = player\probesMax
        LogLine("CHEAT: miner2049er (filled cargo)")
        PrintN("Cheat activated: Cargo hold, fuel, and probes filled!")
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
      ElseIf cmd = "spawnhq"
        ; Scan entire galaxy for an existing HQ entity
        Protected hqFound.i   = 0
        Protected hqFoundMX.i = 0, hqFoundMY.i = 0
        Protected hqFoundX.i  = 0, hqFoundY.i  = 0
        Protected hqScanMX.i, hqScanMY.i, hqScanX2.i, hqScanY2.i
        For hqScanMY = 0 To #GALAXY_H - 1
          For hqScanMX = 0 To #GALAXY_W - 1
            For hqScanY2 = 0 To #MAP_H - 1
              For hqScanX2 = 0 To #MAP_W - 1
                If gGalaxy(hqScanMX, hqScanMY, hqScanX2, hqScanY2)\entType = #ENT_HQ
                  hqFound   = 1
                  hqFoundMX = hqScanMX : hqFoundMY = hqScanMY
                  hqFoundX  = hqScanX2 : hqFoundY  = hqScanY2
                EndIf
              Next
            Next
          Next
        Next
        If hqFound
          PrintN("Starcomm HQ already exists at galaxy sector (" + Str(hqFoundMX) + "," + Str(hqFoundMY) + ") cell (" + Str(hqFoundX) + "," + Str(hqFoundY) + "). SPAWNHQ refused.")
        Else
          If CurCell(gx, gy)\entType <> #ENT_EMPTY
            PrintN("Warning: overwriting existing entity at current cell to place HQ.")
          EndIf
          CurCell(gx, gy)\entType = #ENT_HQ
          CurCell(gx, gy)\name    = "Starcomm HQ"
          gHQMapX = gMapX : gHQMapY = gMapY
          gHQX    = gx    : gHQY    = gy
          LogLine("RECOVERY: SPAWNHQ placed at sector (" + Str(gMapX) + "," + Str(gMapY) + ") cell (" + Str(gx) + "," + Str(gy) + ")")
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("Starcomm HQ placed at your current position. Galaxy map updated.")
          ResetColor()
          PrintN("Move onto the $ cell and type DOCK to enter.")
          RedrawGalaxy(@player)
        EndIf
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
            gGalaxy(gMapX, gMapY, spawnX, spawnY)\enemyLevel = 10
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
        Protected rsxG.i, rsyG.i, rsCountG.i = 0, rsTypeG.i
        For rsyG = 0 To #MAP_H - 1
          For rsxG = 0 To #MAP_W - 1
            If gGalaxy(gMapX, gMapY, rsxG, rsyG)\spawned = 1
              rsTypeG = gGalaxy(gMapX, gMapY, rsxG, rsyG)\entType
              gGalaxy(gMapX, gMapY, rsxG, rsyG)\entType = #ENT_EMPTY
              gGalaxy(gMapX, gMapY, rsxG, rsyG)\name = ""
              gGalaxy(gMapX, gMapY, rsxG, rsyG)\spawned = 0
              rsCountG + 1
              Select rsTypeG
                Case #ENT_BASE
                  PrintN("Spawned starbase removed.")
                Case #ENT_SHIPYARD
                  PrintN("Spawned shipyard removed.")
                Case #ENT_REFINERY
                  PrintN("Spawned refinery removed.")
                Case #ENT_DILITHIUM
                  PrintN("Spawned dilithium cluster removed.")
                Case #ENT_WORMHOLE
                  PrintN("Spawned wormhole removed.")
                Case #ENT_ANOMALY
                  PrintN("Spawned anomaly removed.")
                Case #ENT_PLANETKILLER
                  PrintN("Spawned Planet Killer removed.")
                Default
                  PrintN("Spawned entity removed.")
              EndSelect
              LogLine("CHEAT: removespawn cleared type=" + Str(rsTypeG) + " at " + Str(rsxG) + "," + Str(rsyG))
            EndIf
          Next
        Next
        If rsCountG = 0
          PrintN("No spawned objects in this sector to remove.")
        EndIf
        RedrawGalaxy(@player)
      EndIf
      ElseIf gCheatsUnlocked = 0 And (cmd = "showmethemoney" Or cmd = "poweroverwhelming" Or cmd = "miner2049er" Or cmd = "spawnyard" Or cmd = "spawnbase" Or cmd = "spawnhq" Or cmd = "spawnrefinery" Or cmd = "spawncluster" Or cmd = "spawnwormhole" Or cmd = "spawnanomaly" Or cmd = "spawnplanetkiller" Or cmd = "removespawn")
        If gCheatCode <> ""
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("*** SECRET CODE: " + gCheatCode + " | Type CODE <number> to unlock cheats ***")
          ResetColor()
        Else
          PrintN("No cheat code available yet. Keep exploring!")
        EndIf
      ElseIf cmd = "macro"
        Protected macroSub.s  = TrimLower(TokenAt(line, 2))
        Protected macroName.s = TrimLower(TokenAt(line, 3))
        If macroSub = "create"
          MacroCreate(macroName)
        ElseIf macroSub = "run"
          If macroName = ""
            PrintN("Usage: MACRO RUN <name>")
          Else
            MacroRun(macroName)
          EndIf
        ElseIf macroSub = "edit"
          MacroEdit(macroName)
        ElseIf macroSub = "delete" Or macroSub = "del"
          MacroDelete(macroName)
        ElseIf macroSub = "show" Or macroSub = "view"
          MacroShow(macroName)
        ElseIf macroSub = "list" Or macroSub = ""
          MacroList()
        ElseIf macroSub = "stop"
          If gMacroPlaybackActive
            gMacroPlaybackActive = 0
            gMacroQueueSize      = 0
            gMacroQueuePos       = 0
            ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
            PrintN("[MACRO] Playback stopped.")
            ResetColor()
            gMacroPlaybackName = ""
          Else
            PrintN("No macro is currently running.")
          EndIf
        Else
          PrintN("Usage: MACRO <list|create|run|edit|delete|show|stop> [name]")
        EndIf
        RedrawGalaxy(@player)
      ElseIf cmd = "terminal"
        ShipComputerTerminal(@player)
        RedrawGalaxy(@player)
      ElseIf cmd = "end"
        ; no-op
      Else

        LogLine("Unknown: " + cmd)
        RedrawGalaxy(@player)
      EndIf
    EndIf  ; End of If gMode = #MODE_GALAXY command dispatch

      Protected turnConsumed.i = Bool(gGameTurn <> loopTurnStart Or gStardate <> loopStardateStart)

      ; Handle autoclear and autosave after commands that consume a turn.
      If turnConsumed And gAutoclearInterval > 0
        gAutoclearCounter + 1
        If gAutoclearCounter >= gAutoclearInterval
          ClearLog()
          ClearConsole()
          RedrawGalaxy(@player)
          gAutoclearCounter = 0
        EndIf
      EndIf
      
      If turnConsumed And gAutosaveInterval > 0
        gAutosaveCounter + 1
        If gAutosaveCounter >= gAutosaveInterval
          SaveGame(@player)
          LogLine("AUTOSAVE: saved at turn " + Str(gAutosaveCounter))
          gAutosaveCounter = 0
        EndIf
      EndIf

      ; Mission housekeeping after commands that consume a turn.
      If turnConsumed And gMode = #MODE_GALAXY
        CheckMissionCompletion(@player)
        DefendMissionTick(@player, @enemyTemplate, @enemy, @cs)
        GenerateMission(@player)
        
        ; Refinery price volatility
        If gGameTurn % gRefineryUpdateTurns = 0
          gRefineryPriceMod = 0.5 + (Random(100) / 100.0) ; 0.5 to 1.5
          LogLine("ECONOMY: Refinery market prices updated (mod: " + StrF(gRefineryPriceMod, 2) + ")")
        EndIf
        
        ; Handle power buff expiration
        If gPowerBuff = 1
          gPowerBuffTurns - 1
          If gPowerBuffTurns <= 0
            gPowerBuff = 0
            ; Reverse all stat doublings from poweroverwhelming
            player\hullMax      = player\hullMax      / 2
            player\shieldsMax   = player\shieldsMax   / 2
            player\reactorMax   = player\reactorMax   / 2
            player\weaponCapMax = player\weaponCapMax / 2
            player\warpMax      = player\warpMax      / 2.0
            player\impulseMax   = player\impulseMax   / 2.0
            player\phaserBanks  = player\phaserBanks  - 1
            player\torpTubes    = player\torpTubes    - 1
            player\torpMax      = player\torpMax      / 2
            player\sensorRange  = player\sensorRange  - 5
            player\fuelMax      = player\fuelMax      / 2
            player\oreMax       = player\oreMax       / 2
            player\dilithiumMax = player\dilithiumMax / 2
            player\probesMax    = player\probesMax    / 2
            ; Clamp current values to restored maxes
            If player\hull      > player\hullMax      : player\hull      = player\hullMax      : EndIf
            If player\shields   > player\shieldsMax   : player\shields   = player\shieldsMax   : EndIf
            If player\weaponCap > player\weaponCapMax : player\weaponCap = player\weaponCapMax : EndIf
            If player\torp      > player\torpMax      : player\torp      = player\torpMax      : EndIf
            If player\fuel      > player\fuelMax      : player\fuel      = player\fuelMax      : EndIf
            If player\ore       > player\oreMax       : player\ore       = player\oreMax       : EndIf
            If player\dilithium > player\dilithiumMax : player\dilithium = player\dilithiumMax : EndIf
            If player\probes    > player\probesMax    : player\probes    = player\probesMax    : EndIf
            LogLine("POWERBUFF: expired - stats restored to normal")
            PrintN("The power overwhelming buff has expired. Stats returned to normal.")
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

      ElseIf gMode = #MODE_TACTICAL
        Protected tacticalTurnConsumed.i = 0
        ; Reset fleet combat display bits at the start of every command so stale
        ; bits from the previous turn's enemy fleet attack don't carry into this
        ; turn's player fleet display.
        cs\pFleetAttack = 0
        cs\pFleetHit    = 0
        cs\eFleetAttack = 0
        cs\eFleetHit    = 0
        Select cmd
          Case "help"
            ClearConsole()
            PrintHelpTactical()
            PrintN("")
            PrintN("< Press ENTER >")
            Input()
            PrintStatusTactical(@player, @enemy, @cs)
            Continue
          Case "about"
        ClearConsole()
        PrintAbout()
        PrintN("< Press ENTER >")
        Input()
        PrintStatusTactical(@player, @enemy, @cs)
        Continue
          Case "status"
        PrintStatusTactical(@player, @enemy, @cs)
        Continue
          Case "scan"
        ClearConsole()
        PrintScanTactical(@player, @enemy, @cs)
        PrintN("")
        PrintN("< Press ENTER >")
        Input()
        PrintStatusTactical(@player, @enemy, @cs)
        Continue
          Case "alloc"
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
          Case "move"
        Protected moveDir.s = TokenAt(line, 2)
        Protected moveAmt.i = ParseIntSafe(TokenAt(line, 3), 2)
        PlayerMove(@player, @cs, moveDir, moveAmt)
        tacticalTurnConsumed = 1
        PrintStatusTactical(@player, @enemy, @cs)
          Case "phaser"
        Protected pwr.i = ParseIntSafe(TokenAt(line, 2), 30)
        Protected phaserTarget.s = TokenAt(line, 3)
        If phaserTarget = "fleet" And gEnemyFleetCount > 0
          If (player\sysWeapons & #SYS_DISABLED)
            PrintN("Weapons are disabled.")
          ElseIf player\weaponCap <= 0
            PrintN("Weapon capacitor empty.")
          Else
            Protected maxPerTurnFleet.i = player\phaserBanks * 25
            Protected fleetPwr.i = ClampInt(pwr, 1, player\weaponCap)
            fleetPwr = ClampInt(fleetPwr, 1, maxPerTurnFleet)
            player\weaponCap - fleetPwr
            PlayPhaserSound()
            TacticalFxPhaser(cs\range, 0)
            Protected pfHit.i = Random(gEnemyFleetCount - 1) + 1
            If gEnemyFleet(pfHit)\hull > 0
              Protected pfDmg.i = Random(fleetPwr / 2) + 5
              gEnemyFleet(pfHit)\hull - pfDmg
              If gEnemyFleet(pfHit)\hull < 0 : gEnemyFleet(pfHit)\hull = 0 : EndIf
              cs\eFleetHit = cs\eFleetHit | (1 << (pfHit - 1))
              ConsoleColor(#C_RED, #C_BLACK)
              PrintN("Phasers hit enemy fleet ship " + Str(pfHit) + " for " + Str(pfDmg) + " damage!")
              ResetColor()
              If gEnemyFleet(pfHit)\hull <= 0
                ConsoleColor(#C_RED, #C_BLACK)
                PrintN("Enemy fleet ship " + Str(pfHit) + " destroyed!")
                ResetColor()
                Protected efCompact1.i
                For efCompact1 = pfHit To gEnemyFleetCount - 1
                  CopyStructure(@gEnemyFleet(efCompact1 + 1), @gEnemyFleet(efCompact1), Ship)
                Next
                gEnemyFleetCount - 1
              EndIf
            EndIf
          EndIf
        Else
          PlayerPhaser(@player, @enemy, @cs, pwr)
        EndIf
        tacticalTurnConsumed = 1
        
        PrintStatusTactical(@player, @enemy, @cs)
          Case "torpedo"
        Protected cnt.i = ParseIntSafe(TokenAt(line, 2), 1)
        Protected torpTarget.s = TokenAt(line, 3)
        If torpTarget = "fleet" And gEnemyFleetCount > 0
          If (player\sysWeapons & #SYS_DISABLED)
            PrintN("Weapons are disabled.")
          ElseIf player\torp <= 0
            PrintN("No torpedoes remaining.")
          ElseIf cs\range > 24
            PrintN("Target out of torpedo effective range.")
          Else
            Protected fleetTorpCount.i = ClampInt(cnt, 1, player\torpTubes)
            fleetTorpCount = ClampInt(fleetTorpCount, 1, player\torp)
            Protected tfHit.i = Random(gEnemyFleetCount - 1) + 1
            Protected torpShot.i
            For torpShot = 1 To fleetTorpCount
              player\torp - 1
              PlayTorpedoSound()
              TacticalFxTorpedo(cs\range, 0)
              If gEnemyFleet(tfHit)\hull <= 0 : Break : EndIf
              Protected tfDmg.i = Random(50) + 30
              gEnemyFleet(tfHit)\hull - tfDmg
              If gEnemyFleet(tfHit)\hull < 0 : gEnemyFleet(tfHit)\hull = 0 : EndIf
              cs\eFleetHit = cs\eFleetHit | (1 << (tfHit - 1))
              ConsoleColor(#C_RED, #C_BLACK)
              PrintN("Torpedo hits enemy fleet ship " + Str(tfHit) + " for " + Str(tfDmg) + " damage!")
              ResetColor()
              If gEnemyFleet(tfHit)\hull <= 0
                ConsoleColor(#C_RED, #C_BLACK)
                PrintN("Enemy fleet ship " + Str(tfHit) + " destroyed!")
                ResetColor()
                Protected efCompact2.i
                For efCompact2 = tfHit To gEnemyFleetCount - 1
                  CopyStructure(@gEnemyFleet(efCompact2 + 1), @gEnemyFleet(efCompact2), Ship)
                Next
                gEnemyFleetCount - 1
                Break
              EndIf
            Next
          EndIf
        Else
          PlayerTorpedo(@player, @enemy, @cs, cnt)
        EndIf
        tacticalTurnConsumed = 1
        
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
                  If enemy\hull < 0 : enemy\hull = 0 : EndIf
                EndIf
                cs\pFleetHit = cs\pFleetHit | (1 << (pf - 1))  ; hit enemy - show RED
                ConsoleColor(#C_RED, #C_BLACK)
                PrintN("Fleet ship " + Str(pf) + " fires at enemy! " + Str(pfDmg) + " damage!")
                ResetColor()
              Else
                ConsoleColor(#C_YELLOW, #C_BLACK)
                PrintN("Fleet ship " + Str(pf) + " fires but misses!")
                ResetColor()
              EndIf
            EndIf
          Next
        EndIf

        PrintStatusTactical(@player, @enemy, @cs)
          Case "tractor"
          Protected tractorMode.s = TokenAt(line, 2)
        If tractorMode = ""
          PrintN("Usage: TRACTOR <HOLD|PULL|PUSH>")
          PrintN("  HOLD - lock enemy in place (1 fuel/turn)")
          PrintN("  PULL - pull enemy closer   (1 dilithium or fuel)")
          Continue
        EndIf
        PlayerTractor(@player, @enemy, @cs, tractorMode)
        tacticalTurnConsumed = 1
          Case "transporter"
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
          tacticalTurnConsumed = 1
           
        Else
          PrintN("Unknown transporter command. Use: TRANSPORTER ATTACK")
        EndIf
          Case "shuttle", "launchshuttle"
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
            tacticalTurnConsumed = 1
          EndIf
        ElseIf shutMode = "info"
          PrintN("Shuttle Status:")
          PrintN("  Crew: " + Str(gShuttleCrew) + "/" + Str(gShuttleMaxCrew) + " | Attack Range: " + Str(gShuttleAttackRange))
          PrintN("  Cargo: Ore=" + Str(gShuttleCargoOre) + "/" + Str(gShuttleMaxCargo) + " | Dilithium=" + Str(gShuttleCargoDilithium) + "/" + Str(gShuttleMaxCargo))
        Else
          PrintN("Unknown shuttle command. Use SHUTTLE for help.")
        EndIf
          Case "flee"
        If player\fuel <= 0
          PrintN("Fuel depleted. Cannot flee.")
        ElseIf Random(99) < ClampInt(18 + (cs\range * 2), 15, 65)
          player\fuel - 1
          AdvanceGameTurn(1)
          AdvanceStardate()
          PrintN("You disengage and escape to the galaxy map.")
          LeaveCombat()
          RedrawGalaxy(@player)
          Continue
        Else
          PrintN("Flee attempt fails.")
          tacticalTurnConsumed = 1
        EndIf
        PrintStatusTactical(@player, @enemy, @cs)
          Case "end"
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
                  If enemy\hull < 0 : enemy\hull = 0 : EndIf
                EndIf
                cs\pFleetHit = cs\pFleetHit | (1 << (pf - 1))  ; hit enemy - show RED
                ConsoleColor(#C_RED, #C_BLACK)
                PrintN("Fleet ship " + Str(pf) + " fires at enemy! " + Str(pfDmg) + " damage!")
                ResetColor()
              Else
                ConsoleColor(#C_YELLOW, #C_BLACK)
                PrintN("Fleet ship " + Str(pf) + " fires but misses!")
                ResetColor()
              EndIf
            EndIf
          Next
        EndIf

        PrintStatusTactical(@player, @enemy, @cs)
        tacticalTurnConsumed = 1

        ; no-op
          Case "quit", "exit"
            LeaveCombat()
            Break 2 ; Exit tactical loop AND main game loop to return to menu

          Default
            PrintN("Unknown command. Type HELP.")
            Continue
        EndSelect
      EndIf

      If gMode = #MODE_TACTICAL And IsAlive(@player) And tacticalTurnConsumed
        ; Enemy killed by player's attack this turn (no Goto across block boundaries)
        If enemy\hull <= 0
          PlayExplosionSound()
          PrintDivider()
          PrintN("Enemy destroyed!")
          PrintDivider()
          gMode = #MODE_GALAXY ; Ensure we return to galaxy mode on victory
          
          ; Log victory
          AddCaptainLog("COMBAT: Destroyed " + enemy\name)
          gTotalKills + 1

          ; Mission: bounty progress
          If gMission\active And gMission\type = #MIS_BOUNTY
            gMission\killsDone + 1
            If gMission\killsDone >= gMission\killsRequired
              gCredits + gMission\rewardCredits
              gTotalCreditsEarned + gMission\rewardCredits
              ; ORDERS Tier 2: +5% bonus on all bounty rewards
              If HQOrdersTier() >= 2
                Protected bonusTier2B.i = Int(gMission\rewardCredits * 0.05)
                gCredits + bonusTier2B
                gTotalCreditsEarned + bonusTier2B
                If bonusTier2B > 0
                  PrintN("Standing Orders bonus: +" + Str(bonusTier2B) + " credits (Tier 2).")
                EndIf
              EndIf
              ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
              PrintDivider()
              PrintN("*** MISSION COMPLETE: Bounty claimed! (+" + Str(gMission\rewardCredits) + " credits) ***")
              PrintDivider()
              ResetColor()
              LogLine("MISSION COMPLETE: bounty (+" + Str(gMission\rewardCredits) + " credits)")
              ; Track HQ Priority Bounty completion for Standing Orders
              If gMission\title = "HQ Priority Bounty"
                gHQMissionsCompleted + 1
                LogLine("HQ MISSION: completed #" + Str(gHQMissionsCompleted))
                ; Tier 3 unlock: one-time permanent sensor bonus
                If gHQMissionsCompleted = 6
                  player\sensorRange + 1
                  ConsoleColor(#C_YELLOW, #C_BLACK)
                  PrintN("*** STANDING ORDERS TIER 3 UNLOCKED: Sensor range +1 (permanent)! ***")
                  ResetColor()
                  AddCaptainLog("ORDERS Tier 3 unlocked: sensor +1")
                EndIf
              EndIf
              ClearStructure(@gMission, Mission)
              gMission\type = #MIS_NONE
              gTotalMissions + 1
            Else
              LogLine("BOUNTY: " + Str(gMission\killsDone) + "/" + Str(gMission\killsRequired))
            EndIf
          EndIf

          ; Mission: Planet Killer hunt
          If gMission\active And gMission\type = #MIS_PLANETKILLER
            ; check if it was the Planet Killer
            If enemy\name = "Planet Killer"
              gCredits + gMission\rewardCredits
              gTotalCreditsEarned + gMission\rewardCredits
              ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
              PrintDivider()
              PrintN("*** MISSION COMPLETE: Planet Killer destroyed! (+" + Str(gMission\rewardCredits) + " credits) ***")
              PrintDivider()
              ResetColor()
              LogLine("MISSION COMPLETE: Planet Killer hunt (+" + Str(gMission\rewardCredits) + " credits)")
              ClearStructure(@gMission, Mission)
              gMission\type = #MIS_NONE
              gTotalMissions + 1
            EndIf
          EndIf

          ; Bonus XP for destroying Planet Killer
          If enemy\name = "Planet Killer"
            GainCrewXP(@player, #CREW_WEAPONS, 50)
            PrintN("The crew earned extra experience from defeating the Planet Killer!")
          EndIf

          ; Ensure the cell is cleared upon destruction (redundant but safe)
          If gEnemyMapX >= 0 And gEnemyMapY >= 0 And gEnemyX >= 0 And gEnemyY >= 0
            gGalaxy(gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)\entType = #ENT_EMPTY
            gGalaxy(gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)\name = ""
            gGalaxy(gEnemyMapX, gEnemyMapY, gEnemyX, gEnemyY)\enemyLevel = 0
          EndIf
          If CurCell(gx, gy)\entType = #ENT_ENEMY Or CurCell(gx, gy)\entType = #ENT_PIRATE Or CurCell(gx, gy)\entType = #ENT_PLANETKILLER
            CurCell(gx, gy)\entType = #ENT_EMPTY
            CurCell(gx, gy)\name = ""
            CurCell(gx, gy)\enemyLevel = 0
          EndIf
          player\ore = ClampInt(player\ore + (3 + Random(10)), 0, player\oreMax)
          player\torp = ClampInt(player\torp + (1 + Random(2)), 0, player\torpMax)

          ; Combat rewards: credits and crew XP
          Protected rewardCreditsB.i = 50 + Random(100) + (cs\turn * 5)
          gCredits + rewardCreditsB
          PrintN("You salvage " + Str(rewardCreditsB) + " credits from the wreckage.")

          ; Crew XP for all roles
          Protected xpWeapB.i = 15 + cs\turn
          Protected xpHelmB.i = 12 + cs\turn
          Protected xpEngB.i  = 12 + cs\turn
          Protected xpShldB.i = 12 + cs\turn
          GainCrewXP(@player, #CREW_WEAPONS,     xpWeapB)
          GainCrewXP(@player, #CREW_HELM,        xpHelmB)
          GainCrewXP(@player, #CREW_ENGINEERING, xpEngB)
          GainCrewXP(@player, #CREW_SHIELDS,     xpShldB)
          PrintN("Battle XP earned:")
          ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
          PrintN("  " + player\crew1\name + " (Helm):        +" + Str(xpHelmB) + " XP  [" + Str(player\crew1\xp) + "/" + Str(player\crew1\level * 100) + "]")
          PrintN("  " + player\crew2\name + " (Weapons):     +" + Str(xpWeapB) + " XP  [" + Str(player\crew2\xp) + "/" + Str(player\crew2\level * 100) + "]")
          PrintN("  " + player\crew3\name + " (Shields):     +" + Str(xpShldB) + " XP  [" + Str(player\crew3\xp) + "/" + Str(player\crew3\level * 100) + "]")
          PrintN("  " + player\crew4\name + " (Engineering): +" + Str(xpEngB)  + " XP  [" + Str(player\crew4\xp) + "/" + Str(player\crew4\level * 100) + "]")
          ResetColor()

          LeaveCombat()
          RedrawGalaxy(@player)
          Continue
        EndIf

        ; Reset fleet combat states at start of turn
        cs\pFleetAttack = 0
        cs\pFleetHit = 0
        cs\eFleetAttack = 0
        cs\eFleetHit = 0

        RegenAndRepair(@player, 0)
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
                cs\eFleetHit = cs\eFleetHit | (1 << (ef - 1))  ; hit - show RED
                ; 50% chance to hit player, 50% chance to hit fleet
                If gPlayerFleetCount > 0 And Random(99) < 50
                  Protected pfTarget.i = Random(gPlayerFleetCount - 1) + 1
                  If gPlayerFleet(pfTarget)\hull > 0
                    gPlayerFleet(pfTarget)\hull - efDmg
                    If gPlayerFleet(pfTarget)\hull < 0 : gPlayerFleet(pfTarget)\hull = 0 : EndIf
                    cs\pFleetHit = cs\pFleetHit | (1 << (pfTarget - 1))  ; Mark player fleet ship as hit
                    PlaySoundFX(SoundExplode)  ; Fleet ship hit!
                    ConsoleColor(#C_RED, #C_BLACK)
                    PrintN("Enemy fleet ship " + Str(ef) + " fires at your fleet! " + Str(efDmg) + " damage to fleet " + Str(pfTarget) + "!")
                    ResetColor()
                    If gPlayerFleet(pfTarget)\hull <= 0
                      ConsoleColor(#C_RED, #C_BLACK)
                      PrintN("Your fleet ship " + Str(pfTarget) + " was destroyed!")
                      ResetColor()
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
                    If player\hull < 0 : player\hull = 0 : EndIf
                  EndIf
                  ConsoleColor(#C_RED, #C_BLACK)
                  PrintN("Enemy fleet ship " + Str(ef) + " fires! " + Str(efDmg) + " damage to shields!")
                  ResetColor()
                EndIf
              Else
                ConsoleColor(#C_YELLOW, #C_BLACK)
                PrintN("Enemy fleet ship " + Str(ef) + " fires but misses!")
                ResetColor()
              EndIf
            EndIf
          Next
        EndIf
        
        PrintStatusTactical(@player, @enemy, @cs)
        
        AdvanceGameTurn(1)
        AdvanceStardate()
        cs\turn + 1

        If player\hull <= 0
          ; loop ends
        Else
          ; Turn ended, wait for next command
        EndIf
      EndIf
  Wend

  PrintDivider()
  If player\hull <= 0 And gMode <> #MODE_GALAXY
    ; This part should ideally never be reached now due to the While loop change, 
    ; but we'll leave a failsafe.
    PrintN("Your ship is lost.")
  Else
    PrintN("Session ended.")
  EndIf
  StopEngineLoop()
  If gShuttleLaunched = 1
    player\ore + gShuttleCargoOre
    player\dilithium + gShuttleCargoDilithium
  EndIf
  ForEver ; Loop back to Startup Menu
EndProcedure
