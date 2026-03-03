; starcomm_terminal.pbi
; Ship computer terminal: ShipComputerTerminal
; XIncluded from starcomm.pb

Procedure ShipComputerTerminal(*p.Ship)
  ; All variables declared at the top (EnableExplicit + Select/Case safe)
  Protected termCmd.s
  Protected termLine.s
  Protected termRunning.i = 1
  Protected dbTopic.s
  Protected hullPct.i
  Protected shieldPct.i
  Protected fuelPct.i
  Protected hullAlert.i
  Protected shieldAlert.i
  Protected fuelAlert.i
  Protected totalCargo.i
  Protected threatFound.i
  Protected tx.i, ty.i
  Protected cellName.s
  Protected threatType.s
  Protected histStart.i
  Protected hi.i
  Protected termLogArg.s

  ClearConsole()
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintDivider()
  PrintN("  SHIP COMPUTER TERMINAL  |  Stardate: " + FormatStardate() + "  |  Position: (" + Str(gMapX) + "," + Str(gMapY) + ")-(" + Str(gx) + "," + Str(gy) + ")")
  PrintDivider()
  ResetColor()
  PrintN("  Type HELP for commands. Type EXIT to close the terminal.")
  PrintN("")

  While termRunning = 1
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    Print("[COMPUTER] > ")
    ResetColor()
    termLine = Trim(Input())
    termLine = ReplaceString(ReplaceString(termLine, Chr(13), ""), Chr(10), "")
    termCmd  = TrimLower(TokenAt(termLine, 1))

    Select termCmd

      Case "help", ""
        ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
        PrintN("  Ship Computer Terminal Commands:")
        ResetColor()
        PrintN("  STATUS   - System status (hull, shields, fuel, systems)")
        PrintN("  DIAG     - Full diagnostics with repair recommendations")
        PrintN("  DB       - Entity database")
        PrintN("             DB ENEMY | DB PLANET | DB BASE | DB HAZARD | DB ALL")
        PrintN("  THREAT   - Scan current sector for hostile contacts")
        PrintN("  CARGO    - Detailed cargo manifest")
        PrintN("  HISTORY  - Captain's log quick view (last 20 entries)")
        PrintN("  LOG      - Captain's log full access")
        PrintN("             LOG <search> | LOG ARCHIVES | LOG ARCHIVE <n> | LOG PURGE YES")
        PrintN("  ALERTS   - Colour-coded ship alert status")
        PrintN("  EXIT     - Close the computer terminal")
        PrintN("")

      Case "status"
        ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
        PrintN("  -- SYSTEM STATUS REPORT --")
        ResetColor()
        hullPct   = (*p\hull    * 100) / *p\hullMax
        shieldPct = (*p\shields * 100) / *p\shieldsMax
        fuelPct   = (*p\fuel    * 100) / *p\fuelMax
        Print("  Hull:      ") : SetColorForPercent(hullPct)   : PrintN(Str(*p\hull)    + "/" + Str(*p\hullMax)    + "  (" + Str(hullPct)   + "%)") : ResetColor()
        Print("  Shields:   ") : SetColorForPercent(shieldPct) : PrintN(Str(*p\shields) + "/" + Str(*p\shieldsMax) + "  (" + Str(shieldPct) + "%)") : ResetColor()
        Print("  Fuel:      ") : SetColorForPercent(fuelPct)   : PrintN(Str(*p\fuel)    + "/" + Str(*p\fuelMax)    + "  (" + Str(fuelPct)   + "%)") : ResetColor()
        PrintN("  Torpedoes: " + Str(*p\torp)   + "/" + Str(*p\torpMax))
        PrintN("  Probes:    " + Str(*p\probes) + "/" + Str(*p\probesMax))
        PrintN("  Credits:   " + Str(gCredits))
        PrintN("")
        
        ; Display Tier 2 Upgrade Status
        If gUpgradeHull >= 3 Or gUpgradeShields >= 3 Or gUpgradeWeapons >= 5 Or gUpgradePropulsion >= 4
          ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
          PrintN("  -- ADVANCED PROTOTYPES (TIER 2) --")
          ResetColor()
          If gUpgradeHull >= 3       : PrintN("  [ACTIVE] Neutronium Hull (+50 HullMax)") : EndIf
          If gUpgradeShields >= 3    : PrintN("  [ACTIVE] Regenerative Shields (+40 ShieldsMax)") : EndIf
          If gUpgradeWeapons >= 5     : PrintN("  [ACTIVE] Quantum Torpedo Tubes (+2 Tubes)") : EndIf
          If gUpgradePropulsion >= 4 : PrintN("  [ACTIVE] Slipstream Warp Drive (+2.0 WarpMax)") : EndIf
          PrintN("")
        EndIf

        Print("  Engines:  ")
        If *p\sysEngines & #SYS_DISABLED    : ConsoleColor(#C_LIGHTRED,   #C_BLACK) : PrintN("OFFLINE") : ResetColor()
        ElseIf *p\sysEngines & #SYS_DAMAGED : ConsoleColor(#C_YELLOW,     #C_BLACK) : PrintN("DAMAGED") : ResetColor()
        Else                                : ConsoleColor(#C_LIGHTGREEN, #C_BLACK) : PrintN("ONLINE")  : ResetColor()
        EndIf
        Print("  Weapons:  ")
        If *p\sysWeapons & #SYS_DISABLED    : ConsoleColor(#C_LIGHTRED,   #C_BLACK) : PrintN("OFFLINE") : ResetColor()
        ElseIf *p\sysWeapons & #SYS_DAMAGED : ConsoleColor(#C_YELLOW,     #C_BLACK) : PrintN("DAMAGED") : ResetColor()
        Else                                : ConsoleColor(#C_LIGHTGREEN, #C_BLACK) : PrintN("ONLINE")  : ResetColor()
        EndIf
        Print("  Shields:  ")
        If *p\sysShields & #SYS_DISABLED    : ConsoleColor(#C_LIGHTRED,   #C_BLACK) : PrintN("OFFLINE") : ResetColor()
        ElseIf *p\sysShields & #SYS_DAMAGED : ConsoleColor(#C_YELLOW,     #C_BLACK) : PrintN("DAMAGED") : ResetColor()
        Else                                : ConsoleColor(#C_LIGHTGREEN, #C_BLACK) : PrintN("ONLINE")  : ResetColor()
        EndIf
        PrintN("")

      Case "diag"
        ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
        PrintN("  -- FULL DIAGNOSTIC REPORT --")
        ResetColor()
        hullPct   = (*p\hull    * 100) / *p\hullMax
        shieldPct = (*p\shields * 100) / *p\shieldsMax
        fuelPct   = (*p\fuel    * 100) / *p\fuelMax
        Print("  Hull:     ") : SetColorForPercent(hullPct)   : PrintN(Str(*p\hull)    + "/" + Str(*p\hullMax)    + "  (" + Str(hullPct)   + "%)") : ResetColor()
        Print("  Shields:  ") : SetColorForPercent(shieldPct) : PrintN(Str(*p\shields) + "/" + Str(*p\shieldsMax) + "  (" + Str(shieldPct) + "%)") : ResetColor()
        Print("  Fuel:     ") : SetColorForPercent(fuelPct)   : PrintN(Str(*p\fuel)    + "/" + Str(*p\fuelMax)    + "  (" + Str(fuelPct)   + "%)") : ResetColor()
        PrintN("")
        ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
        PrintN("  -- RECOMMENDATIONS --")
        ResetColor()
        If hullPct < 30
          ConsoleColor(#C_LIGHTRED, #C_BLACK)
          PrintN("  [!] CRITICAL: Hull integrity below 30%. Seek repairs immediately.")
          ResetColor()
        ElseIf hullPct < 60
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("  [!] WARNING: Hull integrity below 60%. Consider docking for repairs.")
          ResetColor()
        Else
          ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
          PrintN("  [*] Hull integrity nominal.")
          ResetColor()
        EndIf
        If fuelPct < 20
          ConsoleColor(#C_LIGHTRED, #C_BLACK)
          PrintN("  [!] CRITICAL: Fuel below 20%. Locate a starbase or refuel now.")
          ResetColor()
        ElseIf fuelPct < 40
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("  [!] WARNING: Fuel below 40%. Plan refuelling soon.")
          ResetColor()
        Else
          ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
          PrintN("  [*] Fuel levels nominal.")
          ResetColor()
        EndIf
        If *p\torp = 0
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("  [!] WARNING: Torpedo reserves depleted. Rearm at a starbase.")
          ResetColor()
        Else
          ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
          PrintN("  [*] Torpedoes: " + Str(*p\torp) + "/" + Str(*p\torpMax))
          ResetColor()
        EndIf
        If *p\probes = 0
          ConsoleColor(#C_LIGHTGRAY, #C_BLACK)
          PrintN("  [*] NOTE: Probe reserves depleted.")
          ResetColor()
        EndIf
        If gIonStormTurns > 0
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("  [!] Ion storm active: " + Str(gIonStormTurns) + " turn(s) remaining.")
          ResetColor()
        EndIf
        If gRadiationTurns > 0
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("  [!] Radiation field active: " + Str(gRadiationTurns) + " turn(s) remaining.")
          ResetColor()
        EndIf
        PrintN("")

      Case "db"
        dbTopic = TrimLower(TokenAt(termLine, 2))
        Select dbTopic

          Case "enemy", "enemies"
            ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
            PrintN("  -- ENEMY DATABASE --")
            ResetColor()
            ConsoleColor(#C_LIGHTRED, #C_BLACK) : Print("  [E] ") : ResetColor()
            PrintN("Enemy Warship   - Hostile military vessel. Phasers and torpedoes.")
            PrintN("                  Tactics: aggressive flanking. Weak to sustained phaser fire.")
            PrintN("")
            ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK) : Print("  [P] ") : ResetColor()
            PrintN("Pirate Raider   - Opportunistic raider targeting dilithium cargo.")
            PrintN("                  Tactics: hit-and-run. Limit dilithium carried to deter.")
            PrintN("")
            ConsoleColor(#C_LIGHTRED, #C_BLACK) : Print("  [K] ") : ResetColor()
            PrintN("Planet Killer   - Massive doomsday machine. Extreme hull and shield values.")
            PrintN("                  Requires torpedoes + max phaser power. Very dangerous.")
            PrintN("")

          Case "planet", "planets"
            ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
            PrintN("  -- PLANET DATABASE --")
            ResetColor()
            ConsoleColor(#C_LIGHTGREEN, #C_BLACK) : Print("  [O] ") : ResetColor()
            PrintN("Ore Planet       - Surface ore deposits. Use MINE then TRANSPORTER.")
            PrintN("")
            ConsoleColor(#C_CYAN, #C_BLACK) : Print("  [D] ") : ResetColor()
            PrintN("Dilithium Cluster - High-value crystals. Attracts pirates when carried in bulk.")
            PrintN("")
            ConsoleColor(#C_YELLOW, #C_BLACK) : Print("  [*] ") : ResetColor()
            PrintN("Sun              - Stellar body. Gravity well do not enter.")
            PrintN("                  Causes hull and fuel damage if pulled in.")
            PrintN("")

          Case "base", "bases", "station", "stations"
            ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
            PrintN("  -- STATION DATABASE --")
            ResetColor()
            ConsoleColor(#C_LIGHTBLUE, #C_BLACK) : Print("  [%] ") : ResetColor()
            PrintN("Starbase  - DOCK: repair hull, refuel, rearm, recruit crew, get missions.")
            PrintN("")
            ConsoleColor(#C_LIGHTMAGENTA, #C_BLACK) : Print("  [+] ") : ResetColor()
            PrintN("Shipyard  - DOCK: purchase ship upgrades (hull, shields, weapons, etc.).")
            PrintN("")
            ConsoleColor(#C_LIGHTGREEN, #C_BLACK) : Print("  [R] ") : ResetColor()
            PrintN("Refinery  - DOCK: REFINE ore into metals, SELL cargo, BUY materials.")
            PrintN("")

          Case "hazard", "hazards", "anomaly", "anomalies"
            ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
            PrintN("  -- HAZARD DATABASE --")
            ResetColor()
            ConsoleColor(#C_LIGHTRED, #C_BLACK) : Print("  [@] ") : ResetColor()
            PrintN("Black Hole  - Strong gravity pull. Severe damage or destruction on entry.")
            PrintN("              Use UNDO to recover if you are pulled in.")
            PrintN("")
            ConsoleColor(#C_LIGHTBLUE, #C_BLACK) : Print("  [W] ") : ResetColor()
            PrintN("Wormhole    - Teleports ship to random galaxy location. Costs 1 fuel.")
            PrintN("")
            ConsoleColor(#C_YELLOW, #C_BLACK) : Print("  [?] ") : ResetColor()
            PrintN("Anomaly     - Energy phenomena. May trigger ion storms or radiation fields.")
            PrintN("              Ion storms reduce shields. Radiation fields reduce crew XP.")
            PrintN("")

          Case "all"
            ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
            PrintN("  === ENTITY DATABASE SUMMARY ===")
            ResetColor()
            PrintN("  ENEMIES: [E] Warship  [P] Pirate  [K] Planet Killer")
            PrintN("  PLANETS: [O] Ore Planet  [D] Dilithium Cluster  [*] Sun")
            PrintN("  BASES:   [%] Starbase  [+] Shipyard  [R] Refinery")
            PrintN("  HAZARDS: [@] Black Hole  [W] Wormhole  [?] Anomaly")
            PrintN("  Use  DB ENEMY | DB PLANET | DB BASE | DB HAZARD  for full details.")
            PrintN("")

          Default
            PrintN("  Usage: DB <topic>")
            PrintN("  Topics: ENEMY  PLANET  BASE  HAZARD  ALL")
            PrintN("")

        EndSelect

      Case "threat"
        ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
        PrintN("  -- THREAT ANALYSIS: Sector (" + Str(gMapX) + "," + Str(gMapY) + ") --")
        ResetColor()
        threatFound = 0
        For tx = 0 To #MAP_W - 1
          For ty = 0 To #MAP_H - 1
            If CurCell(tx, ty)\entType = #ENT_ENEMY Or CurCell(tx, ty)\entType = #ENT_PIRATE Or CurCell(tx, ty)\entType = #ENT_PLANETKILLER
              cellName    = CurCell(tx, ty)\name
              threatType  = ""
              Select CurCell(tx, ty)\entType
                Case #ENT_ENEMY        : threatType = "Enemy Warship"
                Case #ENT_PIRATE       : threatType = "Pirate Raider"
                Case #ENT_PLANETKILLER : threatType = "PLANET KILLER"
                Default                : threatType = "Unknown Contact"
              EndSelect
              ConsoleColor(#C_LIGHTRED, #C_BLACK)
              Print("  [THREAT] ")
              ResetColor()
              If cellName <> ""
                PrintN(threatType + " at (" + Str(tx) + "," + Str(ty) + ") - " + cellName)
              Else
                PrintN(threatType + " at (" + Str(tx) + "," + Str(ty) + ")")
              EndIf
              threatFound = 1
            EndIf
          Next ty
        Next tx
        If threatFound = 0
          ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
          PrintN("  No hostile contacts detected in current sector.")
          ResetColor()
        EndIf
        If gIonStormTurns > 0
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("  [ALERT] Ion storm active: " + Str(gIonStormTurns) + " turn(s) remaining.")
          ResetColor()
        EndIf
        If gRadiationTurns > 0
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("  [ALERT] Radiation field: " + Str(gRadiationTurns) + " turn(s) remaining.")
          ResetColor()
        EndIf
        PrintN("")

      Case "cargo"
        ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
        PrintN("  -- CARGO MANIFEST --")
        ResetColor()
        PrintN("  Raw Materials:")
        PrintN("    Ore:       " + Str(*p\ore)       + " / " + Str(*p\oreMax)       + " units")
        PrintN("    Dilithium: " + Str(*p\dilithium)  + " / " + Str(*p\dilithiumMax) + " crystals")
        PrintN("")
        PrintN("  Refined Metals:")
        PrintN("    Iron:      " + Str(gIron))
        PrintN("    Aluminum:  " + Str(gAluminum))
        PrintN("    Copper:    " + Str(gCopper))
        PrintN("    Tin:       " + Str(gTin))
        PrintN("    Bronze:    " + Str(gBronze))
        PrintN("")
        totalCargo = *p\ore + *p\dilithium + gIron + gAluminum + gCopper + gTin + gBronze
        PrintN("  Total cargo units: " + Str(totalCargo))
        PrintN("  Credits:           " + Str(gCredits))
        If *p\dilithium >= 10
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("  [ALERT] Large dilithium load may attract pirate attention!")
          ResetColor()
        EndIf
        PrintN("")

      Case "history"
        PrintCaptainLog("")
        PrintN("  Tip: Use LOG for search, archives and purge.")
        PrintN("< Press ENTER >")
        Input()

      Case "log"
        termLogArg = Trim(Mid(termLine, Len(termCmd) + 2))
        PrintCaptainLog(termLogArg)
        PrintN("< Press ENTER >")
        Input()

      Case "alerts"
        ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
        PrintN("  -- SHIP ALERT STATUS --")
        ResetColor()
        hullAlert   = (*p\hull    * 100) / *p\hullMax
        shieldAlert = (*p\shields * 100) / *p\shieldsMax
        fuelAlert   = (*p\fuel    * 100) / *p\fuelMax
        If hullAlert < 25
          ConsoleColor(#C_LIGHTRED, #C_BLACK) : PrintN("  [RED   ] Hull at "    + Str(hullAlert)   + "% - CRITICAL DAMAGE")  : ResetColor()
        ElseIf hullAlert < 50
          ConsoleColor(#C_YELLOW,   #C_BLACK) : PrintN("  [YELLOW] Hull at "    + Str(hullAlert)   + "% - Moderate damage") : ResetColor()
        Else
          ConsoleColor(#C_LIGHTGREEN, #C_BLACK) : PrintN("  [GREEN ] Hull at "  + Str(hullAlert)   + "% - Nominal")          : ResetColor()
        EndIf
        If shieldAlert < 25
          ConsoleColor(#C_LIGHTRED, #C_BLACK) : PrintN("  [RED   ] Shields at " + Str(shieldAlert) + "% - CRITICAL")         : ResetColor()
        ElseIf shieldAlert < 50
          ConsoleColor(#C_YELLOW,   #C_BLACK) : PrintN("  [YELLOW] Shields at " + Str(shieldAlert) + "% - Low")              : ResetColor()
        Else
          ConsoleColor(#C_LIGHTGREEN, #C_BLACK) : PrintN("  [GREEN ] Shields at "+ Str(shieldAlert) + "% - Nominal")          : ResetColor()
        EndIf
        If fuelAlert < 20
          ConsoleColor(#C_LIGHTRED, #C_BLACK) : PrintN("  [RED   ] Fuel at "    + Str(fuelAlert)   + "% - CRITICAL LOW FUEL"): ResetColor()
        ElseIf fuelAlert < 40
          ConsoleColor(#C_YELLOW,   #C_BLACK) : PrintN("  [YELLOW] Fuel at "    + Str(fuelAlert)   + "% - Running low")      : ResetColor()
        Else
          ConsoleColor(#C_LIGHTGREEN, #C_BLACK) : PrintN("  [GREEN ] Fuel at "  + Str(fuelAlert)   + "% - Nominal")          : ResetColor()
        EndIf
        If *p\torp = 0
          ConsoleColor(#C_YELLOW, #C_BLACK) : PrintN("  [YELLOW] Torpedoes depleted - rearm at a starbase") : ResetColor()
        Else
          ConsoleColor(#C_LIGHTGREEN, #C_BLACK) : PrintN("  [GREEN ] Torpedoes: " + Str(*p\torp) + "/" + Str(*p\torpMax))     : ResetColor()
        EndIf
        If gWarpCooldown > 0
          ConsoleColor(#C_YELLOW, #C_BLACK) : PrintN("  [YELLOW] Warp engines recharging: " + Str(gWarpCooldown) + " turn(s)") : ResetColor()
        ElseIf *p\dilithium < 5
          ConsoleColor(#C_LIGHTRED, #C_BLACK) : PrintN("  [RED   ] Warp engines OFFLINE - need 5 dilithium") : ResetColor()
        Else
          ConsoleColor(#C_LIGHTGREEN, #C_BLACK) : PrintN("  [GREEN ] Warp engines ready")                                     : ResetColor()
        EndIf
        If gIonStormTurns > 0
          ConsoleColor(#C_LIGHTRED, #C_BLACK) : PrintN("  [RED   ] Ion storm: "    + Str(gIonStormTurns)  + " turn(s) remaining") : ResetColor()
        EndIf
        If gRadiationTurns > 0
          ConsoleColor(#C_LIGHTRED, #C_BLACK) : PrintN("  [RED   ] Radiation field: "+ Str(gRadiationTurns) + " turn(s) remaining") : ResetColor()
        EndIf
        PrintN("")

      Case "exit", "quit", "q"
        termRunning = 0

      Default
        PrintN("  Unknown command: '" + termCmd + "'. Type HELP for available commands.")
        PrintN("")

    EndSelect

    PlayComputerBeep()
  Wend

  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN("  [COMPUTER TERMINAL CLOSED]")
  PrintDivider()
  ResetColor()
EndProcedure
