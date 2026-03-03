; starcomm_docking.pbi
; Docking and mining: GenerateOneNPCShip, GenerateDockedShips, RefreshDockedShips, PrintDockedShips, DockAtBase, MinePlanet, PrintProbeScan, TransporterBeam, ShuttleMine, DockAtShipyard, DockAtRefinery
; XIncluded from starcomm.pb

Procedure GenerateOneNPCShip(*ds.DockedShip, status.s, stationType.i)
  Protected classRoll.i
  Protected prefixRoll.i
  Protected prefix.s
  Protected nameRoll.i
  Protected shipName.s
  Protected baseHull.i, baseShield.i

  If stationType = 1  ; Refinery - cargo and industrial traffic
    classRoll = Random(4)
    Select classRoll
      Case 0 : *ds\class = "Freighter"
      Case 1 : *ds\class = "Transport"
      Case 2 : *ds\class = "Mining Vessel"
      Case 3 : *ds\class = "Tanker"
      Default : *ds\class = "Bulk Carrier"
    EndSelect
    prefixRoll = Random(4)
    Select prefixRoll
      Case 0 : prefix = "MV "
      Case 1 : prefix = "SS "
      Case 2 : prefix = "GFT "
      Case 3 : prefix = "CF "
      Default : prefix = "TK "
    EndSelect
    nameRoll = Random(19)
    Select nameRoll
      Case 0  : shipName = "Abundance"
      Case 1  : shipName = "Providence"
      Case 2  : shipName = "Industry"
      Case 3  : shipName = "Bounty"
      Case 4  : shipName = "Harvest"
      Case 5  : shipName = "Merchant"
      Case 6  : shipName = "Commerce"
      Case 7  : shipName = "Tradewind"
      Case 8  : shipName = "Prospector"
      Case 9  : shipName = "Payload"
      Case 10 : shipName = "Mule"
      Case 11 : shipName = "Consignment"
      Case 12 : shipName = "Stockpile"
      Case 13 : shipName = "Laden"
      Case 14 : shipName = "Fullerton"
      Case 15 : shipName = "Granger"
      Case 16 : shipName = "Yorke"
      Case 17 : shipName = "Sagan"
      Case 18 : shipName = "Halcyon"
      Default : shipName = "Meridian"
    EndSelect

  ElseIf stationType = 2  ; Shipyard - military and patrol traffic
    classRoll = Random(5)
    Select classRoll
      Case 0 : *ds\class = "Patrol Vessel"
      Case 1 : *ds\class = "Corvette"
      Case 2 : *ds\class = "Frigate"
      Case 3 : *ds\class = "Destroyer"
      Case 4 : *ds\class = "Cruiser"
      Default : *ds\class = "Warship"
    EndSelect
    prefixRoll = Random(4)
    Select prefixRoll
      Case 0 : prefix = "UES "
      Case 1 : prefix = "FSS "
      Case 2 : prefix = "HMS "
      Case 3 : prefix = "WCS "
      Default : prefix = "ISS "
    EndSelect
    nameRoll = Random(19)
    Select nameRoll
      Case 0  : shipName = "Indomitable"
      Case 1  : shipName = "Dauntless"
      Case 2  : shipName = "Relentless"
      Case 3  : shipName = "Formidable"
      Case 4  : shipName = "Thunderbolt"
      Case 5  : shipName = "Sovereign"
      Case 6  : shipName = "Invincible"
      Case 7  : shipName = "Vigilant"
      Case 8  : shipName = "Stalwart"
      Case 9  : shipName = "Valiant"
      Case 10 : shipName = "Resolute"
      Case 11 : shipName = "Intrepid"
      Case 12 : shipName = "Defiant"
      Case 13 : shipName = "Tempest"
      Case 14 : shipName = "Vanguard"
      Case 15 : shipName = "Sentinel"
      Case 16 : shipName = "Ranger"
      Case 17 : shipName = "Guardian"
      Case 18 : shipName = "Protector"
      Default : shipName = "Reliant"
    EndSelect

  Else  ; Starbase - mixed civilian and military traffic
    classRoll = Random(6)
    Select classRoll
      Case 0 : *ds\class = "Freighter"
      Case 1 : *ds\class = "Scout"
      Case 2 : *ds\class = "Transport"
      Case 3 : *ds\class = "Patrol Vessel"
      Case 4 : *ds\class = "Corvette"
      Case 5 : *ds\class = "Frigate"
      Default : *ds\class = "Cruiser"
    EndSelect
    prefixRoll = Random(4)
    Select prefixRoll
      Case 0 : prefix = "ISS "
      Case 1 : prefix = "CSS "
      Case 2 : prefix = "RSS "
      Case 3 : prefix = "MV "
      Default : prefix = "SS "
    EndSelect
    nameRoll = Random(21)
    Select nameRoll
      Case 0  : shipName = "Aurora"
      Case 1  : shipName = "Endeavour"
      Case 2  : shipName = "Pioneer"
      Case 3  : shipName = "Ranger"
      Case 4  : shipName = "Sentinel"
      Case 5  : shipName = "Vanguard"
      Case 6  : shipName = "Resolute"
      Case 7  : shipName = "Horizon"
      Case 8  : shipName = "Tempest"
      Case 9  : shipName = "Valiant"
      Case 10 : shipName = "Stalwart"
      Case 11 : shipName = "Orion"
      Case 12 : shipName = "Cygnus"
      Case 13 : shipName = "Pegasus"
      Case 14 : shipName = "Atlas"
      Case 15 : shipName = "Falcon"
      Case 16 : shipName = "Raptor"
      Case 17 : shipName = "Hawk"
      Case 18 : shipName = "Eagle"
      Case 19 : shipName = "Intrepid"
      Case 20 : shipName = "Defiant"
      Default : shipName = "Reliant"
    EndSelect
  EndIf
  *ds\name = prefix + shipName

  Select *ds\class
    Case "Freighter"     : baseHull = 180 + Random(60) : baseShield = 60  + Random(40)
    Case "Scout"         : baseHull = 80  + Random(40) : baseShield = 80  + Random(40)
    Case "Transport"     : baseHull = 160 + Random(60) : baseShield = 50  + Random(30)
    Case "Mining Vessel" : baseHull = 140 + Random(50) : baseShield = 40  + Random(30)
    Case "Tanker"        : baseHull = 200 + Random(80) : baseShield = 50  + Random(30)
    Case "Bulk Carrier"  : baseHull = 220 + Random(80) : baseShield = 40  + Random(20)
    Case "Patrol Vessel" : baseHull = 100 + Random(40) : baseShield = 100 + Random(40)
    Case "Corvette"      : baseHull = 120 + Random(50) : baseShield = 90  + Random(40)
    Case "Frigate"       : baseHull = 140 + Random(50) : baseShield = 110 + Random(50)
    Case "Destroyer"     : baseHull = 160 + Random(60) : baseShield = 130 + Random(60)
    Case "Cruiser"       : baseHull = 180 + Random(70) : baseShield = 140 + Random(60)
    Case "Warship"       : baseHull = 200 + Random(80) : baseShield = 160 + Random(70)
    Default              : baseHull = 150 + Random(80) : baseShield = 100 + Random(60)
  EndSelect
  *ds\hullMax    = baseHull
  *ds\hull       = ClampInt(baseHull   * (70 + Random(30)) / 100, 1, baseHull)
  *ds\shieldsMax = baseShield
  *ds\shields    = ClampInt(baseShield * (60 + Random(40)) / 100, 1, baseShield)
  *ds\status     = status
EndProcedure

;==============================================================================
; GenerateDockedShips(stationType.i)
; Populates the docked ship list with 1-4 random NPC ships on arrival.
; stationType is stored in gStationType for use by RefreshDockedShips.
;==============================================================================
Procedure GenerateDockedShips(stationType.i)
  gStationType = stationType
  Protected cdi.i
  For cdi = 0 To 11
    ClearStructure(@gDockedShips(cdi), DockedShip)
  Next
  gDockedShipCount = 0
  Protected isHQ.i = Bool(CurCell(gx, gy)\entType = #ENT_HQ)
  Protected maxDockedCap.i = 12
  If isHQ = 0 : maxDockedCap = 8 : EndIf
  Protected numShips.i = 1 + Random(3)
  If isHQ : numShips = 4 + Random(4) : EndIf   ; HQ starts with 4-7 ships
  Protected gdi.i
  For gdi = 1 To numShips
    If gDockedShipCount >= maxDockedCap : Break : EndIf
    GenerateOneNPCShip(@gDockedShips(gDockedShipCount), "Docked", stationType)
    gDockedShipCount + 1
  Next
EndProcedure

;==============================================================================
; RefreshDockedShips()
; Simulates station activity each command turn: ships depart and new ones arrive.
;==============================================================================
Procedure RefreshDockedShips()
  Protected rdi.i

  ; Advance status: Docking -> Docked, Undocking -> remove
  rdi = 0
  While rdi < gDockedShipCount
    If gDockedShips(rdi)\status = "Docking..."
      gDockedShips(rdi)\status = "Docked"
    ElseIf gDockedShips(rdi)\status = "Undocking..."
      Protected rdi2.i
      For rdi2 = rdi To gDockedShipCount - 2
        CopyStructure(@gDockedShips(rdi2 + 1), @gDockedShips(rdi2), DockedShip)
      Next
      ClearStructure(@gDockedShips(gDockedShipCount - 1), DockedShip)
      gDockedShipCount - 1
      Continue  ; don't increment rdi
    EndIf
    rdi + 1
  Wend

  ; Chance a docked ship departs
  If gDockedShipCount > 0 And Random(99) < 35
    Protected leaveIdx.i = Random(gDockedShipCount - 1)
    If gDockedShips(leaveIdx)\status = "Docked"
      gDockedShips(leaveIdx)\status = "Undocking..."
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      PrintN("  [COMMS] " + gDockedShips(leaveIdx)\name + " is departing the station.")
      ResetColor()
    EndIf
  EndIf

  ; Chance a new ship arrives
  Protected arrivalCap.i  = 8
  Protected arrivalRate.i = 30
  If CurCell(gx, gy)\entType = #ENT_HQ
    arrivalCap  = 12
    arrivalRate = 50
  EndIf
  If gDockedShipCount < arrivalCap And Random(99) < arrivalRate
    GenerateOneNPCShip(@gDockedShips(gDockedShipCount), "Docking...", gStationType)
    ConsoleColor(#C_DARKGRAY, #C_BLACK)
    PrintN("  [COMMS] " + gDockedShips(gDockedShipCount)\name + " is requesting docking clearance.")
    ResetColor()
    gDockedShipCount + 1
  EndIf
EndProcedure

;==============================================================================
; PrintDockedShips(*p.Ship)
; Displays all ships currently at the station: player, fleet, and NPC ships.
;==============================================================================
Procedure PrintDockedShips(*p.Ship)
  PrintDivider()
  PrintN("Ships at this station:")

  ; Player's own ship
  ConsoleColor(#C_WHITE, #C_BLACK)
  Print("  [YOU]      " + LSet(*p\name + " [" + *p\class + "]", 28))
  ResetColor()
  Print(" Hull: ")
  SetColorForPercent(Int(100.0 * *p\hull / ClampInt(*p\hullMax, 1, 999999)))
  Print(RSet(Str(*p\hull), 3) + "/" + LSet(Str(*p\hullMax), 3))
  ResetColor()
  Print("  Shields: ")
  ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
  PrintN(RSet(Str(*p\shields), 3) + "/" + LSet(Str(*p\shieldsMax), 3))
  ResetColor()

  ; Player fleet ships
  If gPlayerFleetCount > 0
    Protected pfdi.i
    For pfdi = 1 To gPlayerFleetCount
      ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
      Print("  [FLEET " + Str(pfdi) + "]   " + LSet(gPlayerFleet(pfdi)\name + " [" + gPlayerFleet(pfdi)\class + "]", 28))
      ResetColor()
      Print(" Hull: ")
      SetColorForPercent(Int(100.0 * gPlayerFleet(pfdi)\hull / ClampInt(gPlayerFleet(pfdi)\hullMax, 1, 999999)))
      Print(RSet(Str(gPlayerFleet(pfdi)\hull), 3) + "/" + LSet(Str(gPlayerFleet(pfdi)\hullMax), 3))
      ResetColor()
      Print("  Shields: ")
      ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
      PrintN(RSet(Str(gPlayerFleet(pfdi)\shields), 3) + "/" + LSet(Str(gPlayerFleet(pfdi)\shieldsMax), 3))
      ResetColor()
    Next
  EndIf

  ; NPC ships
  Protected ndsi.i
  For ndsi = 0 To gDockedShipCount - 1
    ConsoleColor(#C_DARKGRAY, #C_BLACK)
    Print("  " + LSet(gDockedShips(ndsi)\name + " [" + gDockedShips(ndsi)\class + "]", 34))
    ResetColor()
    Print(" Hull: ")
    SetColorForPercent(Int(100.0 * gDockedShips(ndsi)\hull / ClampInt(gDockedShips(ndsi)\hullMax, 1, 999999)))
    Print(RSet(Str(gDockedShips(ndsi)\hull), 3) + "/" + LSet(Str(gDockedShips(ndsi)\hullMax), 3))
    ResetColor()
    Print("  Shields: ")
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    Print(RSet(Str(gDockedShips(ndsi)\shields), 3) + "/" + LSet(Str(gDockedShips(ndsi)\shieldsMax), 3))
    ResetColor()
    Select gDockedShips(ndsi)\status
      Case "Docked"       : ConsoleColor(#C_WHITE, #C_BLACK)
      Case "Docking..."   : ConsoleColor(#C_YELLOW, #C_BLACK)
      Case "Undocking..." : ConsoleColor(#C_LIGHTRED, #C_BLACK)
    EndSelect
    PrintN("  [" + gDockedShips(ndsi)\status + "]")
    ResetColor()
  Next
  PrintDivider()
EndProcedure

Procedure DockAtBase(*p.Ship)
  If CurCell(gx, gy)\entType <> #ENT_BASE And CurCell(gx, gy)\entType <> #ENT_HQ
    PrintN("No starbase in this sector.")
    ProcedureReturn
  EndIf
  
  If gDocked
    PrintN("You are already docked.")
    ProcedureReturn
  EndIf
  
  gDocked = 1
  StopEngineLoop()
  If CurCell(gx, gy)\entType = #ENT_HQ
    PrintN("")
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("=== STARCOMM HEADQUARTERS ===")
    PrintN("Welcome home, Commander. All standard starbase services are available.")
    PrintN("HQ Priority Mission Board is now open.")
    ResetColor()
    PrintN("")
    GenerateHQMission(*p)
  EndIf
  
  Protected dockCmd.s = TrimLower(TokenAt(gLastCmdLine, 1))
  If dockCmd = "poweroverwhelming"
    If gPowerBuff = 0
      gPowerBuff = 1
      gPowerBuffTurns = 30
      *p\hullMax = *p\hullMax * 2
      *p\shieldsMax = *p\shieldsMax * 2
      *p\reactorMax = *p\reactorMax * 2
      *p\weaponCapMax = *p\weaponCapMax * 2
      *p\warpMax = *p\warpMax * 2.0
      *p\impulseMax = *p\impulseMax * 2.0
      *p\phaserBanks = *p\phaserBanks + 1
      *p\torpTubes = *p\torpTubes + 1
      *p\torpMax = *p\torpMax * 2
      *p\sensorRange = *p\sensorRange + 5
        *p\fuelMax = *p\fuelMax * 2
        *p\oreMax = *p\oreMax * 2
        *p\dilithiumMax = *p\dilithiumMax * 2
        *p\probesMax = *p\probesMax * 2
        *p\hull = *p\hullMax
        *p\shields = *p\shieldsMax
        *p\weaponCap = *p\weaponCapMax
        *p\torp = *p\torpMax
        *p\fuel = *p\fuelMax
        *p\probes = *p\probesMax
        LogLine("CHEAT: poweroverwhelming (buff active)")
      PrintN("Cheat activated: POWER OVERWHELMING! All systems doubled!")
      PrintN("Buff will last for 30 turns or until death.")
    Else
      PrintN("Power Overwhelming is already active! Buff duration refreshed.")
      gPowerBuffTurns = 30
    EndIf
    gLastCmdLine = "" ; Clear the command line
    ProcedureReturn
  EndIf
  PrintN("Starbase services: hull repaired, shields restored,")
  PrintN("weapons rearmed, fuel & probes refilled.")
  PlayDockingSound()
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
  PrintN("Headhunting: RECRUIT HEAD <role> (500 cr fee, Level 3 officer)")
  PrintN("Commands: RECRUIT <1-3> to hire | DISMISS <HELM|WEAPONS|SHIELDS|ENGINEERING> to fire")
  PrintN("")
  
  *p\hull = *p\hullMax
  *p\shields = *p\shieldsMax
  *p\weaponCap = *p\weaponCapMax
  *p\torp = *p\torpMax
  *p\fuel = *p\fuelMax
  *p\probes = *p\probesMax
  ; ORDERS Tier 1: +1 torpedo per dock (any base)
  If HQOrdersTier() >= 1
    *p\torp + 1
  EndIf
  ; ORDERS Tier 3: +1 probe per dock (any base)
  If HQOrdersTier() >= 3
    *p\probes + 1
  EndIf
  *p\sysEngines = #SYS_OK
  *p\sysWeapons = #SYS_OK
  *p\sysShields = #SYS_OK
  *p\sysTractor = *p\sysTractor & ~#SYS_TRACTOR  ; release any active tractor lock
  If gPlayerFleetCount > 0
    Protected repairIdx.i
    For repairIdx = 1 To gPlayerFleetCount
      gPlayerFleet(repairIdx)\hull    = gPlayerFleet(repairIdx)\hullMax
      gPlayerFleet(repairIdx)\shields = gPlayerFleet(repairIdx)\shieldsMax
    Next
    PrintN("Fleet ships repaired and shields restored.")
  EndIf
  LogLine("DOCK: refueled, rearmed, repaired, probes restocked")

  ; Mission delivery happens at starbases
  DeliverMission(*p)

  ; Generate NPC ships docked at this starbase (mixed traffic)
  GenerateDockedShips(0)

  ; Interactive command loop for starbase
  Protected isHQ.i = Bool(CurCell(gx, gy)\entType = #ENT_HQ)
  While gDocked
    RefreshDockedShips()
    PrintDockedShips(*p)
    PrintDivider()
    PrintN("STARBASE: " + CurCell(gx, gy)\name)
    PrintN("Credits: " + Str(gCredits))
    PrintN("Fleet Rank: " + Str(FleetRank(*p)) + "/5  (can command " + Str(FleetRank(*p)) + " fleet ships)")
    PrintN("")
    PrintN("FLEET COMMANDS:")
    PrintN("  FLEET ADD       - Clone your ship into a fleet drone (Free)")
    PrintN("  BUY HEADHUNTER <role> - Hire a specialized mercenary ship (500 cr)")
    PrintN("    (Roles: HELM/WEAPONS/SHIELDS/ENGINEERING have custom power levels)")
    PrintN("  FLEET REMOVE    - Remove last fleet ship")
    PrintN("  FLEET           - Show fleet status")
    PrintN("CREW COMMANDS:")
    PrintN("  RECRUIT <1-3>   - Hire basic Level 1 replacement crew (75 cr fee)")
    PrintN("  DISMISS <role>  - Fire a crew member to make room")
    PrintN("OTHER COMMANDS:")
    PrintN("  SELL ORE/DILITHIUM | CODE <number> | UNDOCK")
    PrintN("  MANIFEST (HQ only) | RECALL (HQ only) | ORDERS (HQ only)")
    If isHQ
      PrintN("HQ only:  INTEL | ORDERS | MANIFEST | RECALL | BANK")
    EndIf
    If gCheatsUnlocked = 1
      PrintN("Cheats: poweroverwhelming | showmethemoney | miner2049er")
      PrintN("        spawnyard | spawnbase | spawnhq | spawnrefinery | spawncluster")
      PrintN("        spawnwormhole | spawnanomaly | spawnplanetkiller | removespawn")
    EndIf
    PrintN("")
    Print("BASE> ")
    ConsoleColor(#C_WHITE, #C_BLACK)
    Protected cmd.s = TrimLower(Input())
    ResetColor()
    
    If cmd = "help"
      PrintN("STARBASE COMMANDS:")
      PrintN("  FLEET ADD/REMOVE/BUY HEADHUNTER")
      PrintN("  RECRUIT <1-3> | DISMISS <role>")
      PrintN("  SELL ORE/DILITHIUM | UNDOCK")
      If isHQ
        PrintN("  BANK         - Securely store credits at HQ")
        PrintN("  INTEL        - Galaxy threat assessment")
        PrintN("  ORDERS       - Starcomm command objectives")
        PrintN("  MANIFEST     - Commander's lifetime record")
        PrintN("  RECALL       - Arm home-sector emergency beacon")
      EndIf
      Continue
    EndIf
    
    ; Handle BUY HEADHUNTER command
    If StringField(cmd, 1, " ") = "buy" And StringField(cmd, 2, " ") = "headhunter"
      Protected headRoleStr.s = TrimLower(StringField(cmd, 3, " "))
      Protected headRoleId.i = 0
      If headRoleStr = "helm" : headRoleId = #CREW_HELM : EndIf
      If headRoleStr = "weapons" : headRoleId = #CREW_WEAPONS : EndIf
      If headRoleStr = "shields" : headRoleId = #CREW_SHIELDS : EndIf
      If headRoleStr = "engineering" : headRoleId = #CREW_ENGINEERING : EndIf
      
      If headRoleId > 0
        RecruitHeadhunter(*p, headRoleId)
      Else
        PrintN("Usage: BUY HEADHUNTER <HELM|WEAPONS|SHIELDS|ENGINEERING>")
      EndIf
      Continue
    EndIf
    
    ; Handle RECRUIT command
    If StringField(cmd, 1, " ") = "recruit"
      Protected recruitArg1.s = TrimLower(StringField(cmd, 2, " "))
      Protected recruitIdx.i = ParseIntSafe(recruitArg1, 0) - 1
      If recruitIdx >= 0 And recruitIdx < gRecruitCount
        RecruitCrew(*p, recruitIdx)
        AddCaptainLog("STARBASE: recruited " + gRecruitNames(recruitIdx))
      Else
        PrintN("Usage: RECRUIT <1-3>")
      EndIf
      Continue
    EndIf
    
    ; SELL commands at Starbase
    If StringField(cmd, 1, " ") = "sell"
      Protected baseSellTarget.s = TrimLower(StringField(cmd, 2, " "))
      If baseSellTarget = "ore"
        If *p\ore <= 0
          PrintN("No ore to sell.")
        Else
          Protected baseOreQty.i = *p\ore
          Protected baseOrePrice.i = 2
          *p\ore = 0
          gCredits + (baseOreQty * baseOrePrice)
          PrintN("Sold " + Str(baseOreQty) + " ore for " + Str(baseOreQty * baseOrePrice) + " credits.")
          LogLine("SELL: " + Str(baseOreQty) + " ore at base")
        EndIf
        Continue
      ElseIf baseSellTarget = "dilithium"
        If *p\dilithium <= 0
          PrintN("No dilithium to sell.")
        Else
          Protected baseDilQty.i = *p\dilithium
          Protected baseDilPrice.i = 15
          *p\dilithium = 0
          gCredits + (baseDilQty * baseDilPrice)
          PrintN("Sold " + Str(baseDilQty) + " dilithium for " + Str(baseDilQty * baseDilPrice) + " credits.")
          LogLine("SELL: " + Str(baseDilQty) + " dilithium at base")
        EndIf
        Continue
      EndIf
    EndIf

    ; HQ-exclusive commands
    If isHQ And cmd = "bank"
      ; --- BANK: Deposit and Withdraw Credits ---
      PrintN("")
      ConsoleColor(#C_YELLOW, #C_BLACK)
      PrintN("=== STARCOMM HQ BANKING SERVICES ===")
      ResetColor()
      PrintN("Current Balance: " + Str(gBankBalance) + " credits")
      PrintN("Liquid Assets:   " + Str(gCredits) + " credits")
      PrintN("")
      PrintN("Commands: DEPOSIT <qty> | WITHDRAW <qty> | ALL | BACK | HELP")
      PrintN("")
      Protected bankActive.i = 1
      While bankActive
        ConsoleColor(#C_YELLOW, #C_BLACK)
        Print("BANK [Bal: " + Str(gBankBalance) + " | Credits: " + Str(gCredits) + "]> ")
        ResetColor()
        Protected bLine.s = TrimLower(Input())
        Protected bCmd.s  = StringField(bLine, 1, " ")
        Protected bQty.s  = StringField(bLine, 2, " ")
        Protected bAmt.i  = 0
        
        If bCmd = "help"
          PrintN("  BANK HELP:")
          PrintN("    DEPOSIT <n>  - Move <n> credits from ship to bank")
          PrintN("    WITHDRAW <n> - Move <n> credits from bank to ship")
          PrintN("    DEPOSIT ALL  - Deposit all liquid credits")
          PrintN("    WITHDRAW ALL - Withdraw your entire bank balance")
          PrintN("    BACK         - Return to Starbase HQ menu")
          PrintN("")
          Continue
        EndIf
        
        If bCmd = "back" Or bCmd = "exit" Or bCmd = "undock"
          bankActive = 0
          Continue
        ElseIf bCmd = "deposit"
          If bQty = "all"
            bAmt = gCredits
          Else
            bAmt = Val(bQty)
          EndIf
          If bAmt <= 0
            PrintN("Invalid amount.")
          ElseIf gCredits < bAmt
            PrintN("Insufficient liquid credits.")
          Else
            gCredits - bAmt
            gBankBalance + bAmt
            PrintN("Deposited " + Str(bAmt) + " credits. New balance: " + Str(gBankBalance))
            LogLine("BANK: deposited " + Str(bAmt))
          EndIf
        ElseIf bCmd = "withdraw"
          If bQty = "all"
            bAmt = gBankBalance
          Else
            bAmt = Val(bQty)
          EndIf
          If bAmt <= 0
            PrintN("Invalid amount.")
          ElseIf gBankBalance < bAmt
            PrintN("Insufficient bank balance.")
          Else
            gBankBalance - bAmt
            gCredits + bAmt
            PrintN("Withdrew " + Str(bAmt) + " credits. Liquid assets: " + Str(gCredits))
            LogLine("BANK: withdrew " + Str(bAmt))
          EndIf
        Else
          PrintN("Unknown command. DEPOSIT <qty> | WITHDRAW <qty> | BACK")
        EndIf
      Wend
      Continue
    EndIf

    If isHQ And cmd = "intel"

      ; --- INTEL: Galaxy Threat Report ---
      Protected intelEnemies.i = 0, intelPirates.i = 0, intelPKActive.i = 0
      Protected intelPKSectorX.i = -1, intelPKSectorY.i = -1
      Protected Dim intelSectorCount.i(#GALAXY_W - 1, #GALAXY_H - 1)
      Protected intelMX.i, intelMY.i, intelIX.i, intelIY.i
      For intelMY = 0 To #GALAXY_H - 1
        For intelMX = 0 To #GALAXY_W - 1
          For intelIY = 0 To #MAP_H - 1
            For intelIX = 0 To #MAP_W - 1
              Protected intelEnt.i = gGalaxy(intelMX, intelMY, intelIX, intelIY)\entType
              If intelEnt = #ENT_ENEMY
                intelEnemies + 1
                intelSectorCount(intelMX, intelMY) + 1
              ElseIf intelEnt = #ENT_PIRATE
                intelPirates + 1
                intelSectorCount(intelMX, intelMY) + 1
              ElseIf intelEnt = #ENT_PLANETKILLER
                intelPKActive = 1
                intelPKSectorX = intelMX : intelPKSectorY = intelMY
              EndIf
            Next
          Next
        Next
      Next
      ; Find top 3 hostile sectors
      Protected Dim intelTop.i(2)
      Protected Dim intelTopX.i(2)
      Protected Dim intelTopY.i(2)
      Protected intelTi.i, intelTj.i
      For intelTi = 0 To 2 : intelTop(intelTi) = -1 : Next
      For intelMY = 0 To #GALAXY_H - 1
        For intelMX = 0 To #GALAXY_W - 1
          If intelSectorCount(intelMX, intelMY) > 0
            For intelTi = 0 To 2
              If intelSectorCount(intelMX, intelMY) > intelTop(intelTi)
                For intelTj = 2 To intelTi + 1 Step -1
                  intelTop(intelTj)  = intelTop(intelTj - 1)
                  intelTopX(intelTj) = intelTopX(intelTj - 1)
                  intelTopY(intelTj) = intelTopY(intelTj - 1)
                Next
                intelTop(intelTi)  = intelSectorCount(intelMX, intelMY)
                intelTopX(intelTi) = intelMX
                intelTopY(intelTi) = intelMY
                Break
              EndIf
            Next
          EndIf
        Next
      Next
      PrintN("")
      ConsoleColor(#C_YELLOW, #C_BLACK)
      PrintN("=== STARCOMM INTELLIGENCE REPORT ===")
      ResetColor()
      PrintN("Hostile vessels detected: " + Str(intelEnemies) + " enemy  |  " + Str(intelPirates) + " pirate")
      If intelPKActive
        ConsoleColor(#C_LIGHTRED, #C_BLACK)
        PrintN("PLANET KILLER ACTIVE at galaxy sector (" + Str(intelPKSectorX) + "," + Str(intelPKSectorY) + ") !!!")
        ResetColor()
      Else
        PrintN("Planet Killer: no current signature detected.")
      EndIf
      PrintN("Most hostile sectors:")
      For intelTi = 0 To 2
        If intelTop(intelTi) > 0
          PrintN("  [" + Str(intelTi + 1) + "] Sector (" + Str(intelTopX(intelTi)) + "," + Str(intelTopY(intelTi)) + ")  - " + Str(intelTop(intelTi)) + " hostile contact(s)")
        EndIf
      Next
      If gMission\active
        PrintN("Active mission destination: galaxy sector (" + Str(gMission\destMapX) + "," + Str(gMission\destMapY) + ")")
      EndIf
      PrintN("")
      Continue
    EndIf

    If isHQ And cmd = "orders"
      ; --- ORDERS: Standing Orders display ---
      Protected ordTier.i = HQOrdersTier()
      PrintN("")
      ConsoleColor(#C_YELLOW, #C_BLACK)
      PrintN("=== STANDING ORDERS ===")
      ResetColor()
      PrintN("HQ missions completed: " + Str(gHQMissionsCompleted))
      PrintN("Current tier: " + Str(ordTier) + "/3")
      PrintN("")
      If ordTier >= 1
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("  [Tier 1 ACTIVE] +1 torpedo on every dock")
      Else
        PrintN("  [Tier 1]  Complete 1 HQ mission  - +1 torpedo per dock")
      EndIf
      ResetColor()
      If ordTier >= 2
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("  [Tier 2 ACTIVE] +5% bonus credits on all bounty rewards")
      Else
        PrintN("  [Tier 2]  Complete 3 HQ missions - +5% bounty credits")
      EndIf
      ResetColor()
      If ordTier >= 3
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("  [Tier 3 ACTIVE] +1 probe per dock  |  sensor range already boosted")
      Else
        PrintN("  [Tier 3]  Complete 6 HQ missions - +1 probe/dock + permanent sensor +1")
      EndIf
      ResetColor()
      PrintN("")
      Continue
    EndIf

    If isHQ And cmd = "manifest"
      ; --- MANIFEST: Lifetime combat record ---
      Protected manRating.i = (gTotalKills * 10) + (gTotalMissions * 100) + (gTotalCreditsEarned / 10)
      PrintN("")
      ConsoleColor(#C_YELLOW, #C_BLACK)
      PrintN("=== COMMANDER'S RECORD ===")
      ResetColor()
      PrintN("Enemies destroyed:    " + Str(gTotalKills))
      PrintN("Missions completed:   " + Str(gTotalMissions))
      PrintN("Credits earned:       " + Str(gTotalCreditsEarned))
      PrintN("HQ missions done:     " + Str(gHQMissionsCompleted) + "  (Orders Tier " + Str(HQOrdersTier()) + " active)")
      ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
      PrintN("Starcomm Rating:      " + Str(manRating))
      ResetColor()
      PrintN("")
      Continue
    EndIf

    If isHQ And cmd = "recall"
      ; --- RECALL: Arm the emergency jump beacon ---
      If gRecallArmed
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("Recall beacon is already armed. Leave HQ and type RECALL to jump home.")
        ResetColor()
      Else
        gRecallArmed = 1
        ConsoleColor(#C_YELLOW, #C_BLACK)
        PrintN("Recall beacon armed. From anywhere outside HQ sector, type RECALL to emergency jump home.")
        PrintN("Cost: all remaining fuel. One use per arming.")
        ResetColor()
        LogLine("RECALL: beacon armed at HQ")
        AddCaptainLog("RECALL: beacon armed")
      EndIf
      Continue
    EndIf

    If cmd = "0" Or cmd = "undock" Or cmd = "leave" Or cmd = "exit"
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
      PrintN("Undocking...")
      StartEngineLoop()
      Continue
    EndIf
    
    ; Code command to unlock cheats
    Protected codeCmd.s = StringField(cmd, 1, " ")
    Protected codeArg.s = Trim(StringField(cmd, 2, " "))
    If codeCmd = "code"
      If gCheatsUnlocked = 1
        PrintN("Cheats are already unlocked!")
      ElseIf codeArg = ""
        PrintN("Usage: CODE <4-digit-number>")
        PrintN("A secret code appears every 10 turns. Watch for it!")
      ElseIf CheckCheatCode(codeArg)
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("*** CHEATS UNLOCKED! ***")
        PrintN("You now have access to all cheat commands!")
        ResetColor()
      Else
        ConsoleColor(#C_LIGHTRED, #C_BLACK)
        PrintN("Invalid code. The code changes every 10 turns.")
        ResetColor()
      EndIf
      Continue
    EndIf
    
    ; Fleet commands (available while docked)
    Protected baseFleetWord.s = TrimLower(TokenAt(cmd, 1))
    Protected baseFleetSub.s  = TrimLower(TokenAt(cmd, 2))
    If baseFleetWord = "fleet"
      If baseFleetSub = "add"
        Protected dockFleetRankCap.i = FleetRank(*p)
        If gPlayerFleetCount >= dockFleetRankCap
          PrintN("Fleet is full (Fleet Rank " + Str(dockFleetRankCap) + " allows " + Str(dockFleetRankCap) + " ships). Level up all crew to expand.")
        Else
          Protected baseFleetIdx.i = gPlayerFleetCount + 1
          CopyStructure(*p, @gPlayerFleet(baseFleetIdx), Ship)
          ; If Power Overwhelming is active, new fleet ships should not inherit the doubled stats permanently
          If gPowerBuff = 1
            gPlayerFleet(baseFleetIdx)\hullMax      = gPlayerFleet(baseFleetIdx)\hullMax      / 2
            gPlayerFleet(baseFleetIdx)\shieldsMax   = gPlayerFleet(baseFleetIdx)\shieldsMax   / 2
            gPlayerFleet(baseFleetIdx)\reactorMax   = gPlayerFleet(baseFleetIdx)\reactorMax   / 2
            gPlayerFleet(baseFleetIdx)\weaponCapMax = gPlayerFleet(baseFleetIdx)\weaponCapMax / 2
            gPlayerFleet(baseFleetIdx)\warpMax      = gPlayerFleet(baseFleetIdx)\warpMax      / 2.0
            gPlayerFleet(baseFleetIdx)\impulseMax   = gPlayerFleet(baseFleetIdx)\impulseMax   / 2.0
            gPlayerFleet(baseFleetIdx)\phaserBanks  = gPlayerFleet(baseFleetIdx)\phaserBanks  - 1
            gPlayerFleet(baseFleetIdx)\torpTubes    = gPlayerFleet(baseFleetIdx)\torpTubes    - 1
            gPlayerFleet(baseFleetIdx)\torpMax      = gPlayerFleet(baseFleetIdx)\torpMax      / 2
            gPlayerFleet(baseFleetIdx)\sensorRange  = gPlayerFleet(baseFleetIdx)\sensorRange  - 5
            gPlayerFleet(baseFleetIdx)\fuelMax      = gPlayerFleet(baseFleetIdx)\fuelMax      / 2
            gPlayerFleet(baseFleetIdx)\oreMax       = gPlayerFleet(baseFleetIdx)\oreMax       / 2
            gPlayerFleet(baseFleetIdx)\dilithiumMax = gPlayerFleet(baseFleetIdx)\dilithiumMax / 2
            gPlayerFleet(baseFleetIdx)\probesMax    = gPlayerFleet(baseFleetIdx)\probesMax    / 2
          EndIf
          gPlayerFleet(baseFleetIdx)\name = "Fleet Ship " + Str(baseFleetIdx)
          gPlayerFleet(baseFleetIdx)\hull = gPlayerFleet(baseFleetIdx)\hullMax
          gPlayerFleet(baseFleetIdx)\shields = gPlayerFleet(baseFleetIdx)\shieldsMax
          gPlayerFleetCount = baseFleetIdx
          PrintN("Added " + gPlayerFleet(baseFleetIdx)\name + " to fleet.")
          LogLine("FLEET: added ship " + Str(baseFleetIdx) + " at base")
          AddCaptainLog("STARBASE: fleet ship added")
        EndIf
      ElseIf baseFleetSub = "remove"
        If gPlayerFleetCount = 0
          PrintN("No fleet ships to remove.")
        Else
          gPlayerFleetCount - 1
          PrintN("Removed last fleet ship. Fleet size: " + Str(gPlayerFleetCount) + "/5")
          LogLine("FLEET: removed ship at base")
          AddCaptainLog("STARBASE: fleet ship removed")
        EndIf
      Else
        PrintN("=== YOUR FLEET ===")
        PrintN("Player ship: " + *p\name + " (" + *p\class + ")")
        If gPlayerFleetCount > 0
          Protected baseFleetF.i
          For baseFleetF = 1 To gPlayerFleetCount
            PrintN("  Fleet " + Str(baseFleetF) + ": " + gPlayerFleet(baseFleetF)\name + " (" + gPlayerFleet(baseFleetF)\class + ") - Hull: " + Str(gPlayerFleet(baseFleetF)\hull) + "/" + Str(gPlayerFleet(baseFleetF)\hullMax))
          Next
        Else
          PrintN("  No fleet ships.")
        EndIf
        PrintN("Total: " + Str(gPlayerFleetCount) + "/5  |  FLEET ADD to add, FLEET REMOVE to remove")
      EndIf
      Continue
    EndIf

    ; Only allow cheats if unlocked
    If gCheatsUnlocked = 0
      PrintN("Unknown command. Type UNDOCK to leave, or CODE <number> to unlock cheats.")
      Continue
    EndIf

    If cmd = "showmethemoney"
      gCredits + 500
      LogLine("CHEAT: showmethemoney (+500 credits)")
      PrintN("Cheat activated: +500 credits!")
      Continue
    EndIf
    
    If cmd = "poweroverwhelming"
      If gPowerBuff = 0
        gPowerBuff = 1
        gPowerBuffTurns = 30
        *p\hullMax = *p\hullMax * 2
        *p\shieldsMax = *p\shieldsMax * 2
        *p\reactorMax = *p\reactorMax * 2
        *p\weaponCapMax = *p\weaponCapMax * 2
        *p\warpMax = *p\warpMax * 2.0
        *p\impulseMax = *p\impulseMax * 2.0
        *p\phaserBanks = *p\phaserBanks + 1
        *p\torpTubes = *p\torpTubes + 1
        *p\torpMax = *p\torpMax * 2
        *p\sensorRange = *p\sensorRange + 5
        *p\fuelMax = *p\fuelMax * 2
        *p\oreMax = *p\oreMax * 2
        *p\dilithiumMax = *p\dilithiumMax * 2
        *p\probesMax = *p\probesMax * 2
        *p\hull = *p\hullMax
        *p\shields = *p\shieldsMax
        *p\weaponCap = *p\weaponCapMax
        *p\torp = *p\torpMax
        *p\fuel = *p\fuelMax
        *p\probes = *p\probesMax
        LogLine("CHEAT: poweroverwhelming (buff active)")
        PrintN("Cheat activated: POWER OVERWHELMING! All systems doubled!")
        PrintN("Buff will last for 30 turns or until death.")
      Else
        PrintN("Power Overwhelming is already active! Buff duration refreshed.")
        gPowerBuffTurns = 30
      EndIf
      gLastCmdLine = "" ; Clear the command line
      Continue
    EndIf

    If cmd = "poweroverwhelming"
      If gPowerBuff = 0
        gPowerBuff = 1
        gPowerBuffTurns = 30
        *p\hullMax = *p\hullMax * 2
        *p\shieldsMax = *p\shieldsMax * 2
        *p\reactorMax = *p\reactorMax * 2
        *p\weaponCapMax = *p\weaponCapMax * 2
        *p\warpMax = *p\warpMax * 2.0
        *p\impulseMax = *p\impulseMax * 2.0
        *p\phaserBanks = *p\phaserBanks + 1
        *p\torpTubes = *p\torpTubes + 1
        *p\torpMax = *p\torpMax * 2
        *p\sensorRange = *p\sensorRange + 5
        *p\fuelMax = *p\fuelMax * 2
        *p\oreMax = *p\oreMax * 2
        *p\dilithiumMax = *p\dilithiumMax * 2
        *p\probesMax = *p\probesMax * 2
        *p\hull = *p\hullMax
        *p\shields = *p\shieldsMax
        *p\weaponCap = *p\weaponCapMax
        *p\torp = *p\torpMax
        *p\fuel = *p\fuelMax
        *p\probes = *p\probesMax
        LogLine("CHEAT: poweroverwhelming (buff active)")
        PrintN("Cheat activated: POWER OVERWHELMING! All systems doubled!")
        PrintN("Buff will last for 30 turns or until death.")
      Else
        PrintN("Power Overwhelming is already active! Buff duration refreshed.")
        gPowerBuffTurns = 30
      EndIf
      gLastCmdLine = "" ; Clear the command line
      Continue
    EndIf
    If cmd = "miner2049er"
      *p\ore = *p\oreMax
      *p\dilithium = *p\dilithiumMax
      *p\fuel = *p\fuelMax
      *p\probes = *p\probesMax
      LogLine("CHEAT: miner2049er (filled cargo)")
      PrintN("Cheat activated: Cargo hold, fuel, and probes filled!")
      Continue
    EndIf
    
    ; Spawn cheats
    Protected spawnX.i = -1, spawnY.i = 0
    Protected attempts.i = 0
    
    If cmd = "spawnyard"
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
      Continue
    EndIf
    
    If cmd = "spawnbase"
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
      Continue
    EndIf
    
    If cmd = "spawnhq"
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
        ; Place HQ at current player cell
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
        PrintN("You can now DOCK here.")
      EndIf
      Continue
    EndIf

    If cmd = "spawnrefinery"
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
      Continue
    EndIf
    
    If cmd = "spawncluster"
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
      Continue
    EndIf
    
    If cmd = "spawnwormhole"
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
      Continue
    EndIf
    
    If cmd = "spawnanomaly"
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
          PrintN("Cheat activated: Spatial Anomaly spawned at sector (" + Str(spawnX) + "," + Str(spawnY) + ")!")
        Else
          spawnX = -1
        EndIf
        attempts + 1
      Wend
      If spawnX = -1
        PrintN("No empty space in sector!")
      EndIf
      Continue
    EndIf
    
    If cmd = "spawnplanetkiller"
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
      Continue
    EndIf
    
    If cmd = "removespawn"
      Protected rsxD.i, rsyD.i, rsCountD.i = 0
      For rsyD = 0 To #MAP_H - 1
        For rsxD = 0 To #MAP_W - 1
          If gGalaxy(gMapX, gMapY, rsxD, rsyD)\spawned = 1
            gGalaxy(gMapX, gMapY, rsxD, rsyD)\entType = #ENT_EMPTY
            gGalaxy(gMapX, gMapY, rsxD, rsyD)\name = ""
            gGalaxy(gMapX, gMapY, rsxD, rsyD)\spawned = 0
            rsCountD + 1
          EndIf
        Next
      Next
      If rsCountD > 0
        LogLine("CHEAT: removespawn cleared " + Str(rsCountD) + " spawned object(s) from sector")
        PrintN("Cheat activated: " + Str(rsCountD) + " spawned object(s) removed from sector!")
      Else
        PrintN("No spawned entities in this sector to remove.")
      EndIf
      Continue
    EndIf
    
    PrintN("Unknown command. Type UNDOCK to leave.")
  Wend
EndProcedure

Procedure MinePlanet(*p.Ship)
  If CurCell(gx, gy)\entType = #ENT_PLANET
    If *p\fuel < 2
      PrintN("Insufficient fuel for mining operations.")
      ProcedureReturn
    EndIf
    Protected rmax.i = CurCell(gx, gy)\richness
    If rmax < 0 : rmax = 0 : EndIf
    Protected pull.i = 1 + Random(rmax)
    pull = ClampInt(pull, 1, 20)
    CurCell(gx, gy)\ore + pull
    *p\fuel - 2
    PlayMiningSound()
    LogLine("MINE: +" + Str(pull) + " ore")
    PrintN("Mined " + Str(pull) + " ore onto planet surface. Use TRANSPORTER ALL to beam to ship.")
    
    ; Crew XP for mining operations
    GainCrewXP(*p, #CREW_ENGINEERING, 4)
    GainCrewXP(*p, #CREW_SHIELDS, 2)
    
    gGameTurn = gGameTurn + 1

    GenerateCheatCode()
  ElseIf CurCell(gx, gy)\entType = #ENT_DILITHIUM
    If *p\fuel < 2
      PrintN("Insufficient fuel for mining operations.")
      ProcedureReturn
    EndIf
    Protected drmax.i = CurCell(gx, gy)\richness
    If drmax < 0 : drmax = 0 : EndIf
    Protected dpull.i = 1 + Random(drmax)
    dpull = ClampInt(dpull, 1, 8)
    CurCell(gx, gy)\dilithium + dpull
    *p\fuel - 2
    PlayMiningSound()
    LogLine("MINE: +" + Str(dpull) + " dilithium")
    PrintN("Mined " + Str(dpull) + " dilithium crystals onto surface. Use TRANSPORTER ALL to beam to ship.")
    
    ; Crew XP for dilithium extraction
    GainCrewXP(*p, #CREW_ENGINEERING, 6)
    GainCrewXP(*p, #CREW_SHIELDS, 3)
    
    gGameTurn = gGameTurn + 1

    GenerateCheatCode()
  Else
    PrintN("No mineable resource in this sector (need Planet O or Dilithium D).")
  EndIf
EndProcedure

Procedure PrintProbeScan(mapX.i, mapY.i)
  PrintN("")
  PrintN("=== PROBE SCAN: Galaxy (" + Str(mapX) + "," + Str(mapY) + ") ===")
  Protected x.i, y.i
  Protected hasContent.i = 0
  
  For y = 0 To #MAP_H - 1
    Protected line.s = "  "
    For x = 0 To #MAP_W - 1
      Protected ent.i = gGalaxy(mapX, mapY, x, y)\entType
      Select ent
        Case #ENT_EMPTY
          line + ". "
        Case #ENT_PLANET
          line + "O "
        Case #ENT_STAR
          line + "* "
        Case #ENT_BASE
          line + "% "
        Case #ENT_SHIPYARD
          line + "+ "
        Case #ENT_ENEMY
          line + "E "
        Case #ENT_WORMHOLE
          line + "# "
        Case #ENT_BLACKHOLE
          line + "? "
        Case #ENT_SUN
          line + "S "
        Case #ENT_DILITHIUM
          line + "D "
        Case #ENT_ANOMALY
          line + "A "
        Case #ENT_PLANETKILLER
          line + "< "
        Case #ENT_REFINERY
          line + "R "
        Default
          line + ". "
      EndSelect
    Next
    PrintN(line)
  Next
  
  PrintN("Legend: @=YourShip")
  PrintN("        .=EmptySector O=Planet *=Star (blocked) %=Starbase +=Shipyard")
  PrintN("        E=EnemyShip P=PirateShip #=Wormhole ?=Blackhole S=Sun (blocked)")
  PrintN("        D=Dilithium A=Anomaly <=Planet Killer R=Refinery")
  PrintN("")
EndProcedure

Procedure TransporterBeam(*p.Ship, mode.s)
  If CurCell(gx, gy)\entType <> #ENT_PLANET And CurCell(gx, gy)\entType <> #ENT_DILITHIUM And CurCell(gx, gy)\entType <> #ENT_CARGO
    PrintN("No planet, dilithium cluster, or cargo container in this sector.")
    ProcedureReturn
  EndIf
  
  Protected oreToTrans.i = 0
  Protected dilToTrans.i = 0
  
  If mode = "ore" Or mode = "all"
    oreToTrans = CurCell(gx, gy)\ore
    If oreToTrans > 0
      Protected oreSpace.i = *p\oreMax - *p\ore
      If oreToTrans > oreSpace : oreToTrans = oreSpace : EndIf
      *p\ore + oreToTrans
      CurCell(gx, gy)\ore - oreToTrans
      PrintN("Transporter: +" + Str(oreToTrans) + " ore beamed to cargo.")
      LogLine("TRANSPORTER: +" + Str(oreToTrans) + " ore")
    ElseIf CurCell(gx, gy)\entType = #ENT_CARGO
      PrintN("No ore in this cargo container.")
    Else
      PrintN("No ore remaining on this planet.")
    EndIf
  EndIf
  
  If mode = "dilithium" Or mode = "all"
    dilToTrans = CurCell(gx, gy)\dilithium
    If dilToTrans > 0
      Protected dilSpace.i = *p\dilithiumMax - *p\dilithium
      If dilToTrans > dilSpace : dilToTrans = dilSpace : EndIf
      *p\dilithium + dilToTrans
      CurCell(gx, gy)\dilithium - dilToTrans
      PrintN("Transporter: +" + Str(dilToTrans) + " dilithium beamed to cargo.")
      LogLine("TRANSPORTER: +" + Str(dilToTrans) + " dilithium")
    ElseIf CurCell(gx, gy)\entType = #ENT_CARGO
      PrintN("No dilithium in this cargo container.")
    Else
      PrintN("No dilithium remaining on this cluster.")
    EndIf
  EndIf
  
  ; If it was a cargo container and it's now empty, remove it
  If CurCell(gx, gy)\entType = #ENT_CARGO
    If CurCell(gx, gy)\ore = 0 And CurCell(gx, gy)\dilithium = 0
      CurCell(gx, gy)\entType = #ENT_EMPTY
      CurCell(gx, gy)\name = ""
      PrintN("Cargo container depleted and removed.")
    EndIf
  EndIf
  
  If oreToTrans = 0 And dilToTrans = 0
    PrintN("No resources to beam up.")
  EndIf
EndProcedure

Procedure ShuttleMine()
  If gShuttleLaunched = 0
    PrintN("Shuttle is not launched.")
    ProcedureReturn
  EndIf
  
  If CurCell(gx, gy)\entType <> #ENT_PLANET And CurCell(gx, gy)\entType <> #ENT_DILITHIUM
    PrintN("No planet or dilithium cluster in this sector.")
    ProcedureReturn
  EndIf
  
  Protected shuttleSpace.i = gShuttleMaxCargo - (gShuttleCargoOre + gShuttleCargoDilithium)
  If shuttleSpace <= 0
    PrintN("Shuttle cargo full!")
    ProcedureReturn
  EndIf
  
  Protected oreCollect.i = 0
  Protected dilCollect.i = 0
  
  If CurCell(gx, gy)\entType = #ENT_PLANET
    oreCollect = CurCell(gx, gy)\ore
    If oreCollect > shuttleSpace
      oreCollect = shuttleSpace
    EndIf
    If oreCollect > 0
      gShuttleCargoOre + oreCollect
      CurCell(gx, gy)\ore - oreCollect
      PrintN("Shuttle collected " + Str(oreCollect) + " ore!")
    Else
      PrintN("No ore on this planet.")
    EndIf
  EndIf
  
  If CurCell(gx, gy)\entType = #ENT_DILITHIUM
    shuttleSpace = gShuttleMaxCargo - (gShuttleCargoOre + gShuttleCargoDilithium)
    dilCollect = CurCell(gx, gy)\dilithium
    If dilCollect > shuttleSpace
      dilCollect = shuttleSpace
    EndIf
    If dilCollect > 0
      gShuttleCargoDilithium + dilCollect
      CurCell(gx, gy)\dilithium - dilCollect
      PrintN("Shuttle collected " + Str(dilCollect) + " dilithium!")
    Else
      PrintN("No dilithium in this cluster.")
    EndIf
  EndIf
  
  If oreCollect = 0 And dilCollect = 0
    PrintN("No resources collected.")
  Else
    AddCaptainLog("SHUTTLE: collected " + Str(oreCollect) + " ore, " + Str(dilCollect) + " dilithium")
  EndIf
EndProcedure

;==============================================================================
; DockAtShipyard(*p.Ship, *base.Ship)
; Docks player ship at a shipyard for upgrades and repairs.
; 
; Shipyard services:
;   - Repair hull: 1 credit per 2 hull points
;   - Upgrade hull: +10-50 max hull (costs credits based on amount)
;   - Upgrade shields: +10-40 max shields
;   - Upgrade weapons: +20-50 max weapon capacity
;   - Upgrade propulsion: +fuel efficiency
;   - Upgrade power/cargo: +cargo capacity
;   - Upgrade probes: +probe capacity and range
;   - Build/upgrade shuttle: Enable or improve shuttle
;
; Each upgrade has a base cost and is tracked in gUpgrade* variables.
;==============================================================================
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
  *p\sysTractor = *p\sysTractor & ~#SYS_TRACTOR  ; release any active tractor lock
  If gPlayerFleetCount > 0
    Protected repairFleetIdx.i
    For repairFleetIdx = 1 To gPlayerFleetCount
      gPlayerFleet(repairFleetIdx)\hull    = gPlayerFleet(repairFleetIdx)\hullMax
      gPlayerFleet(repairFleetIdx)\shields = gPlayerFleet(repairFleetIdx)\shieldsMax
    Next
    PrintN("Fleet ships repaired and shields restored.")
  EndIf
  LogLine("DOCK: shipyard services")

  ; Generate NPC ships docked at this shipyard (military/patrol traffic)
  GenerateDockedShips(2)

  ; Upgrade menu
  While #True
    ; Total upgrades count for Tier 2 unlock (21 standard upgrades)
    ; Standard upgrades: Hull(2), Shields(2), Weapons(4), Prop(3), Power(3), Probes(3), Shuttle(4) = 21
    Protected totalUpgrades.i = ClampInt(gUpgradeHull, 0, 2) + ClampInt(gUpgradeShields, 0, 2) + 
                                ClampInt(gUpgradeWeapons, 0, 4) + ClampInt(gUpgradePropulsion, 0, 3) + 
                                ClampInt(gUpgradePowerCargo, 0, 3) + ClampInt(gUpgradeProbes, 0, 3) + 
                                ClampInt(gUpgradeShuttle, 0, 4)
    
    ; Total installed count (includes T2)
    Protected installedCount.i = gUpgradeHull + gUpgradeShields + gUpgradeWeapons + gUpgradePropulsion + gUpgradePowerCargo + gUpgradeProbes + gUpgradeShuttle
    
    RefreshDockedShips()
    PrintDockedShips(*p)
    PrintDivider()
    PrintN("Shipyard: " + CurCell(gx, gy)\name)
    PrintN("Credits: " + Str(gCredits))
    PrintN("Standard Upgrades: " + Str(totalUpgrades) + "/21")
    PrintN("Total Installed:    " + Str(installedCount))
    PrintN("")
    
    If totalUpgrades < 21
      PrintN("--- TIER 1 STANDARD UPGRADES ---")
      PrintN("HULL & STRUCTURE:")
      If gUpgradeHull < 1 : PrintN("1) Reinforced Hull  (+20 HullMax)     cost 120") : Else : PrintN("1) [INSTALLED] Reinforced Hull") : EndIf
      If gUpgradeHull < 2 : PrintN("2) Ablative Armor   (+15 HullMax)     cost 100") : Else : PrintN("2) [INSTALLED] Ablative Armor") : EndIf
      PrintN("")
      PrintN("SHIELDS:")
      If gUpgradeShields < 1 : PrintN("3) Shield Grid      (+20 ShieldsMax)  cost 140") : Else : PrintN("3) [INSTALLED] Shield Grid") : EndIf
      If gUpgradeShields < 2 : PrintN("4) Shield Emitters  (+15 ShieldsMax)  cost 110") : Else : PrintN("4) [INSTALLED] Shield Emitters") : EndIf
      PrintN("")
      PrintN("WEAPONS:")
      If gUpgradeWeapons < 1 : PrintN("5) Phaser Banks     (+1 PhaserBanks)  cost 160") : Else : PrintN("5) [INSTALLED] Phaser Banks") : EndIf
      If gUpgradeWeapons < 2 : PrintN("6) Torpedo Racks    (+4 TorpMax)      cost 110") : Else : PrintN("6) [INSTALLED] Torpedo Racks") : EndIf
      If gUpgradeWeapons < 3 : PrintN("7) Torpedo Tubes    (+1 TorpTubes)    cost 200") : Else : PrintN("7) [INSTALLED] Torpedo Tubes") : EndIf
      If gUpgradeWeapons < 4 : PrintN("8) Targeting Matrix (+5 SensorRange)  cost 130") : Else : PrintN("8) [INSTALLED] Targeting Matrix") : EndIf
      PrintN("")
      PrintN("PROPULSION:")
      If gUpgradePropulsion < 1 : PrintN("9) Warp Core        (+1.0 WarpMax)    cost 250") : Else : PrintN("9) [INSTALLED] Warp Core") : EndIf
      If gUpgradePropulsion < 2 : PrintN("A) Impulse Engines  (+0.3 ImpulseMax) cost 150") : Else : PrintN("A) [INSTALLED] Impulse Engines") : EndIf
      If gUpgradePropulsion < 3 : PrintN("B) Fuel Tanks       (+25 FuelMax)     cost 100") : Else : PrintN("B) [INSTALLED] Fuel Tanks") : EndIf
      PrintN("")
      PrintN("POWER & CARGO:")
      If gUpgradePowerCargo < 1 : PrintN("C) Reactor Upgrade (+30 ReactorMax)   cost 180") : Else : PrintN("C) [INSTALLED] Reactor Upgrade") : EndIf
      If gUpgradePowerCargo < 2 : PrintN("D) Dilithium Bay   (+10 Di-lithiumMax) cost 90") : Else : PrintN("D) [INSTALLED] Dilithium Bay") : EndIf
      If gUpgradePowerCargo < 3 : PrintN("E) Cargo Hold      (+20 OreMax)        cost 80") : Else : PrintN("E) [INSTALLED] Cargo Hold") : EndIf
      PrintN("")
      PrintN("PROBES:")
      If gUpgradeProbes < 1 : PrintN("F) Probe Bay        (+2 ProbesMax)      cost 60") : Else : PrintN("F) [INSTALLED] Probe Bay") : EndIf
      If gUpgradeProbes < 2 : PrintN("G) Probe Scanner    (+1 Probe Range)    cost 100") : Else : PrintN("G) [INSTALLED] Probe Scanner") : EndIf
      If gUpgradeProbes < 3 : PrintN("H) Probe Targeting  (5% Probe Accuracy) cost 120") : Else : PrintN("H) [INSTALLED] Probe Targeting") : EndIf
      PrintN("")
      PrintN("SHUTTLE:")
      If gUpgradeShuttle < 1 : PrintN("I) Shuttle Bay      (+10 Cargo Max)     cost 120") : Else : PrintN("I) [INSTALLED] Shuttle Bay") : EndIf
      If gUpgradeShuttle < 2 : PrintN("J) Shuttle Crew 1    (+2 Crew Max)      cost 150") : Else : PrintN("J) [INSTALLED] Shuttle Crew 1") : EndIf
      If gUpgradeShuttle < 3 : PrintN("K) Shuttle Crew 2    (+2 Crew Max)      cost 300") : Else : PrintN("K) [INSTALLED] Shuttle Crew 2") : EndIf
      If gUpgradeShuttle < 4 : PrintN("L) Shuttle Attack   (+1 Attack Range)   cost 200") : Else : PrintN("L) [INSTALLED] Shuttle Attack") : EndIf
    Else
      ConsoleColor(#C_YELLOW, #C_BLACK)
      PrintN("--- TIER 2 ADVANCED PROTOTYPES UNLOCKED ---")
      ResetColor()
      If gUpgradeHull < 3 : PrintN("M) Neutronium Hull (+50 HullMax)     cost 500") : Else : PrintN("M) [INSTALLED] Neutronium Hull") : EndIf
      If gUpgradeShields < 3 : PrintN("N) Regenerative Shields (+40 Max)    cost 600") : Else : PrintN("N) [INSTALLED] Regenerative Shields") : EndIf
      If gUpgradeWeapons < 5 : PrintN("P) Quantum Torp Tubes (+2 Tubes)      cost 800") : Else : PrintN("P) [INSTALLED] Quantum Torp Tubes") : EndIf
      If gUpgradePropulsion < 4 : PrintN("Q) Slipstream Drive (+2.0 WarpMax)    cost 1000") : Else : PrintN("Q) [INSTALLED] Slipstream Drive") : EndIf
    EndIf

    PrintN("")
    PrintN("0) Leave")
    If gCheatsUnlocked = 0
      PrintN("     (Type CODE <number> to unlock cheats)")
    EndIf
    PrintN("")
    If gCheatsUnlocked = 1
      PrintN("CHEATS (type number/letter or word):")
      PrintN("  showmethemoney = +500 credits")
      PrintN("  poweroverwhelming = all stats x2 for 30 turns")
      PrintN("  miner2049er = fill cargo, fuel, probes")
      PrintN("  spawnyard | spawnbase | spawnrefinery | spawncluster")
      PrintN("  spawnwormhole | spawnanomaly | spawnplanetkiller | removespawn")
    EndIf
    Print("")
    Print("YARD> ")
    ConsoleColor(#C_WHITE, #C_BLACK)
    Protected choice.s = TrimLower(Input())
    ResetColor()
    
    ; Check for code unlock
    Protected yardCodeCmd.s = StringField(choice, 1, " ")
    Protected yardCodeArg.s = Trim(StringField(choice, 2, " "))
    If yardCodeCmd = "code"
      If gCheatsUnlocked = 1
        PrintN("Cheats are already unlocked!")
      ElseIf yardCodeArg = ""
        PrintN("Usage: CODE <4-digit-number>")
        PrintN("A secret code appears every 10 turns. Watch for it!")
      ElseIf CheckCheatCode(yardCodeArg)
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("*** CHEATS UNLOCKED! ***")
        PrintN("You now have access to all cheat commands!")
        ResetColor()
      Else
        ConsoleColor(#C_LIGHTRED, #C_BLACK)
        PrintN("Invalid code. The code changes every 10 turns.")
        ResetColor()
      EndIf
      Continue
    EndIf
    
    ; Hide cheats unless unlocked
    If gCheatsUnlocked = 0
      Protected isCheatCmd.i = 0
      If choice = "showmethemoney" Or choice = "poweroverwhelming" Or choice = "miner2049er"
        isCheatCmd = 1
      EndIf
      If choice = "spawnyard" Or choice = "spawnbase" Or choice = "spawnrefinery"
        isCheatCmd = 1
      EndIf
      If choice = "spawncluster" Or choice = "spawnwormhole" Or choice = "spawnanomaly"
        isCheatCmd = 1
      EndIf
      If choice = "spawnplanetkiller" Or choice = "removespawn"
        isCheatCmd = 1
      EndIf
      If isCheatCmd = 1
        If gCheatCode <> ""
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("*** SECRET CODE: " + gCheatCode + " | Type CODE <number> to unlock cheats ***")
          ResetColor()
        Else
          PrintN("No cheat code available yet. Keep exploring!")
        EndIf
        Continue
      EndIf
    EndIf
    
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
      StartEngineLoop()
      Break
    EndIf
    If choice = "showmethemoney"
      gCredits + 500
      LogLine("CHEAT: showmethemoney (+500 credits)")
      PrintN("Cheat activated: +500 credits!")
      Continue
    EndIf
    If choice = "poweroverwhelming"
      If gPowerBuff = 0
        gPowerBuff = 1
        gPowerBuffTurns = 30
        *p\hullMax = *p\hullMax * 2
        *p\shieldsMax = *p\shieldsMax * 2
        *p\reactorMax = *p\reactorMax * 2
        *p\weaponCapMax = *p\weaponCapMax * 2
        *p\warpMax = *p\warpMax * 2.0
        *p\impulseMax = *p\impulseMax * 2.0
        *p\phaserBanks = *p\phaserBanks + 1
        *p\torpTubes = *p\torpTubes + 1
        *p\torpMax = *p\torpMax * 2
        *p\sensorRange = *p\sensorRange + 5
        *p\fuelMax = *p\fuelMax * 2
        *p\oreMax = *p\oreMax * 2
        *p\dilithiumMax = *p\dilithiumMax * 2
        *p\probesMax = *p\probesMax * 2
        *p\hull = *p\hullMax
        *p\shields = *p\shieldsMax
        *p\weaponCap = *p\weaponCapMax
        *p\torp = *p\torpMax
        *p\fuel = *p\fuelMax
        *p\probes = *p\probesMax
        LogLine("CHEAT: poweroverwhelming (buff active)")
        PrintN("Cheat activated: POWER OVERWHELMING! All systems doubled!")
        PrintN("Buff will last for 30 turns or until death.")
      Else
        PrintN("Power Overwhelming is already active! Buff duration refreshed.")
        gPowerBuffTurns = 30
      EndIf
      gLastCmdLine = "" ; Clear the command line
      Continue
    EndIf
    If choice = "miner2049er"
      *p\ore = *p\oreMax
      *p\dilithium = *p\dilithiumMax
      *p\fuel = *p\fuelMax
      *p\probes = *p\probesMax
      LogLine("CHEAT: miner2049er (filled cargo)")
      PrintN("Cheat activated: Cargo hold, fuel, and probes filled!")
      Continue
    EndIf

    Protected cost.i = 0
    Select choice
      Case "1"
        If gUpgradeHull >= 1 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 120
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\hullMax = ClampInt(*p\hullMax + 20, 10, 800)
        *p\hull = *p\hullMax
        gUpgradeHull + 1
        LogLine("UPGRADE: hull +20 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: hull upgrade +20")
        PrintN("Upgrade installed.")
      Case "2"
        If gUpgradeHull >= 2 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 100
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\hullMax = ClampInt(*p\hullMax + 15, 10, 800)
        *p\hull = *p\hullMax
        gUpgradeHull + 1
        LogLine("UPGRADE: armor +15 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: armor upgrade +15")
        PrintN("Upgrade installed.")
      Case "3"
        If gUpgradeShields >= 1 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 140
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\shieldsMax = ClampInt(*p\shieldsMax + 20, 0, 800)
        *p\shields = *p\shieldsMax
        gUpgradeShields + 1
        LogLine("UPGRADE: shields +20 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: shields upgrade +20")
      Case "4"
        If gUpgradeShields >= 2 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 110
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\shieldsMax = ClampInt(*p\shieldsMax + 15, 0, 800)
        *p\shields = *p\shieldsMax
        gUpgradeShields + 1
        LogLine("UPGRADE: emitters +15 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: emitters upgrade +15")
      Case "5"
        If gUpgradeWeapons >= 1 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 160
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\phaserBanks = ClampInt(*p\phaserBanks + 1, 0, 30)
        gUpgradeWeapons + 1
        LogLine("UPGRADE: phasers +1 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: phaser banks +1")
      Case "6"
        If gUpgradeWeapons >= 2 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 110
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\torpMax = ClampInt(*p\torpMax + 4, 0, 80)
        *p\torp = ClampInt(*p\torp + 4, 0, *p\torpMax)
        gUpgradeWeapons + 1
        LogLine("UPGRADE: torpMax +4 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: torpedo capacity +4")
      Case "7"
        If gUpgradeWeapons >= 3 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 200
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\torpTubes = ClampInt(*p\torpTubes + 1, 1, 6)
        If *p\torpTubes > *p\torpMax : *p\torpTubes = *p\torpMax : EndIf
        gUpgradeWeapons + 1
        LogLine("UPGRADE: tubes +1 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: torpedo tubes +1")
      Case "8"
        If gUpgradeWeapons >= 4 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 130
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\sensorRange = ClampInt(*p\sensorRange + 5, 1, 60)
        gUpgradeWeapons + 1
        LogLine("UPGRADE: sensors +5 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: sensor range +5")
      Case "9"
        If gUpgradePropulsion >= 1 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 250
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\warpMax = ClampF(*p\warpMax + 1.0, 0.0, 12.0)
        gUpgradePropulsion + 1
        LogLine("UPGRADE: warp +1.0 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: warp drive +1")
      Case "a"
        If gUpgradePropulsion >= 2 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 150
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\impulseMax = ClampF(*p\impulseMax + 0.3, 0.0, 2.5)
        gUpgradePropulsion + 1
        LogLine("UPGRADE: impulse +0.3 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: impulse engines +0.3")
      Case "b"
        If gUpgradePropulsion >= 3 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 100
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\fuelMax = ClampInt(*p\fuelMax + 50, 10, 800)
        *p\fuel = *p\fuelMax
        gUpgradePropulsion + 1
        LogLine("UPGRADE: fuel +50 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: fuel tanks +50")
      Case "c"
        If gUpgradePowerCargo >= 1 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 180
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\reactorMax = ClampInt(*p\reactorMax + 30, 50, 900)
        *p\weaponCapMax = ClampInt(*p\weaponCapMax + 30, 10, 1400)
        *p\weaponCap = ClampInt(*p\weaponCap, 0, *p\weaponCapMax)
        gUpgradePowerCargo + 1
        LogLine("UPGRADE: reactor +30 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: reactor +30")
      Case "d"
        If gUpgradePowerCargo >= 2 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 90
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\dilithiumMax = ClampInt(*p\dilithiumMax + 10, 0, 50)
        gUpgradePowerCargo + 1
        LogLine("UPGRADE: di-lithium +10 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: dilithium storage +10")
      Case "e"
        If gUpgradePowerCargo >= 3 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 80
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\oreMax = ClampInt(*p\oreMax + 20, 0, 250)
        gUpgradePowerCargo + 1
        LogLine("UPGRADE: cargo +20 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: cargo hold +20")
      Case "f"
        If gUpgradeProbes >= 1 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 60
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\probesMax = ClampInt(*p\probesMax + 2, 0, 40)
        *p\probes = *p\probesMax
        gUpgradeProbes + 1
        LogLine("UPGRADE: probes +2 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: probe bay +2")
      Case "g"
        If gUpgradeProbes >= 2 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 100
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gProbeRange = ClampInt(gProbeRange + 1, 1, 10)
        gUpgradeProbes + 1
        LogLine("UPGRADE: probe range +1 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: probe scanner +1")
      Case "h"
        If gUpgradeProbes >= 3 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 120
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gProbeAccuracy = ClampInt(gProbeAccuracy + 5, 50, 100)
        gUpgradeProbes + 1
        LogLine("UPGRADE: probe accuracy +5% (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: probe targeting +5%")
      Case "i"
        If gUpgradeShuttle >= 1 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 120
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gShuttleMaxCargo = ClampInt(gShuttleMaxCargo + 10, 10, 50)
        gUpgradeShuttle + 1
        LogLine("UPGRADE: shuttle cargo +10 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: shuttle cargo +10")
      Case "j"
        If gUpgradeShuttle >= 2 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 150
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gShuttleMaxCrew = ClampInt(gShuttleMaxCrew + 2, 2, 10)
        gUpgradeShuttle + 1
        LogLine("UPGRADE: shuttle crew +2 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: shuttle crew +2")
      Case "k"
        If gUpgradeShuttle >= 3 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 300
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gShuttleMaxCrew = ClampInt(gShuttleMaxCrew + 2, 2, 10)
        gUpgradeShuttle + 1
        LogLine("UPGRADE: shuttle crew +2 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: shuttle crew +2")
      Case "l"
        If gUpgradeShuttle >= 4 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 200
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        gShuttleAttackRange = ClampInt(gShuttleAttackRange + 1, 10, 20)
        gUpgradeShuttle + 1
        LogLine("UPGRADE: shuttle attack range +1 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: shuttle attack +1")
        PrintN("Upgrade installed. Shuttle attack range: " + Str(gShuttleAttackRange))
      ; TIER 2 UPGRADES
      Case "m"
        If totalUpgrades < 21 : PrintN("Unknown selection.") : Continue : EndIf
        If gUpgradeHull >= 3 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 500
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\hullMax = ClampInt(*p\hullMax + 50, 10, 1000)
        *p\hull = *p\hullMax
        gUpgradeHull + 1
        LogLine("UPGRADE T2: neutronium hull +50 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: neutronium hull +50")
        PrintN("Tier 2 Upgrade installed.")
      Case "n"
        If totalUpgrades < 21 : PrintN("Unknown selection.") : Continue : EndIf
        If gUpgradeShields >= 3 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 600
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\shieldsMax = ClampInt(*p\shieldsMax + 40, 0, 1000)
        *p\shields = *p\shieldsMax
        gUpgradeShields + 1
        LogLine("UPGRADE T2: regen shields +40 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: regenerative shields +40")
        PrintN("Tier 2 Upgrade installed.")
      Case "p"
        If totalUpgrades < 21 : PrintN("Unknown selection.") : Continue : EndIf
        If gUpgradeWeapons >= 5 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 800
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\torpTubes = ClampInt(*p\torpTubes + 2, 1, 8)
        gUpgradeWeapons + 1
        LogLine("UPGRADE T2: quantum tubes +2 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: quantum torpedo tubes +2")
        PrintN("Tier 2 Upgrade installed.")
      Case "q"
        If totalUpgrades < 21 : PrintN("Unknown selection.") : Continue : EndIf
        If gUpgradePropulsion >= 4 : PrintN("Upgrade already installed.") : Continue : EndIf
        cost = 1000
        If gCredits < cost : PrintN("Insufficient credits.") : Continue : EndIf
        gCredits - cost
        *p\warpMax = ClampF(*p\warpMax + 2.0, 0.0, 15.0)
        gUpgradePropulsion + 1
        LogLine("UPGRADE T2: slipstream warp +2.0 (-" + Str(cost) + ")")
        AddCaptainLog("SHIPYARD: slipstream drive +2.0")
        PrintN("Tier 2 Upgrade installed.")
      Default
        PrintN("Unknown selection.")
    EndSelect
  Wend
EndProcedure

;==============================================================================
; DockAtRefinery(*p.Ship)
; Docks player ship at a dilithium refinery to process ore and trade.
; 
; Refinery functions:
;   - REFINE: Convert raw ore to dilithium crystals (costs fuel)
;   - SELL: Sell dilithium for credits (price varies randomly)
;   - BUY: Buy dilithium to transport (price varies randomly)
;   - CARGO: Show current cargo hold
;   - STATUS: Show refinery status and prices
; 
; The refinery acts as a marketplace for dilithium with fluctuating prices.
; High dilithium cargo attracts pirates when leaving!
;==============================================================================
Procedure DockAtRefinery(*p.Ship)
  If CurCell(gx, gy)\entType <> #ENT_REFINERY
    PrintN("No refinery in this sector.")
    ProcedureReturn
  EndIf
  
  If gDocked
    PrintN("You are already docked.")
    ProcedureReturn
  EndIf
  
  gDocked = 1

  ; Generate NPC ships docked at this refinery (cargo/freighter traffic)
  GenerateDockedShips(1)

  While #True
    RefreshDockedShips()
    PrintDockedShips(*p)
    ; Randomize prices for fluctuating economy (scaled by gRefineryPriceMod)
    Protected basePrice.i = 2
    Protected ironPrice.i = Int((5 + Random(4)) * gRefineryPriceMod)
    Protected alumPrice.i = Int((8 + Random(5)) * gRefineryPriceMod)
    Protected copperPrice.i = Int((12 + Random(6)) * gRefineryPriceMod)
    Protected tinPrice.i = Int((15 + Random(8)) * gRefineryPriceMod)
    Protected bronzePrice.i = Int((25 + Random(10)) * gRefineryPriceMod)
    Protected dilithiumPrice.i = Int((15 + Random(15)) * gRefineryPriceMod)  ; Rebalanced: 15-30 cr base

    ; Ensure prices don't drop to 0
    If ironPrice < 1 : ironPrice = 1 : EndIf
    If alumPrice < 2 : alumPrice = 2 : EndIf
    If copperPrice < 3 : copperPrice = 3 : EndIf
    If tinPrice < 4 : tinPrice = 4 : EndIf
    If bronzePrice < 5 : bronzePrice = 5 : EndIf
    If dilithiumPrice < 8 : dilithiumPrice = 8 : EndIf

    PrintDivider()
    PrintN("Refinery: " + CurCell(gx, gy)\name)
    PrintN("Credits: " + Str(gCredits))
    PrintN("")
    PrintN("SHIP CARGO:")
    PrintN("  Ore in cargo: " + Str(*p\ore) + "/" + Str(*p\oreMax))
    PrintN("  Dilithium: " + Str(*p\dilithium) + "/" + Str(*p\dilithiumMax) + " crystals")
    PrintN("")
    PrintN("CARGO HOLD (refined metals):")
    PrintN("  Iron: " + Str(gIron))
    PrintN("  Aluminum: " + Str(gAluminum))
    PrintN("  Copper: " + Str(gCopper))
    PrintN("  Tin: " + Str(gTin))
    PrintN("  Bronze: " + Str(gBronze))
    PrintN("")
    ; Buy prices are 2x the sell price (market markup)
    Protected buyIronPrice.i      = ironPrice      * 2
    Protected buyAlumPrice.i      = alumPrice      * 2
    Protected buyCopperPrice.i    = copperPrice    * 2
    Protected buyTinPrice.i       = tinPrice       * 2
    Protected buyBronzePrice.i    = bronzePrice    * 2
    Protected buyDilithiumPrice.i = dilithiumPrice * 2

    PrintN("MARKET PRICES (sell / buy):")
    PrintN("  Ore:       " + LSet(Str(basePrice), 4) + " /  n/a")
    PrintN("  Iron:      " + LSet(Str(ironPrice), 4) + " / " + Str(buyIronPrice))
    PrintN("  Aluminum:  " + LSet(Str(alumPrice), 4) + " / " + Str(buyAlumPrice))
    PrintN("  Copper:    " + LSet(Str(copperPrice), 4) + " / " + Str(buyCopperPrice))
    PrintN("  Tin:       " + LSet(Str(tinPrice), 4) + " / " + Str(buyTinPrice))
    PrintN("  Bronze:    " + LSet(Str(bronzePrice), 4) + " / " + Str(buyBronzePrice))
    PrintN("  Dilithium: " + LSet(Str(dilithiumPrice), 4) + " / " + Str(buyDilithiumPrice) + " (volatile!)")
    PrintN("")
    PrintN("COMMANDS:")
    PrintN("  REFINE             - Convert 1 ore to random refined metal (free)")
    PrintN("  REFINE ALL         - Convert all ore to refined metals")
    PrintN("  REFINE DILITHIUM   - Convert 1 dilithium crystal to 5 ore")
    PrintN("  SELL ORE           - Sell all ore (" + Str(basePrice) + " cr ea)")
    PrintN("  SELL IRON/ALUMINUM/COPPER/TIN/BRONZE/DILITHIUM/ALL - Sell cargo")
    PrintN("  BUY IRON <qty>     - Buy refined iron (" + Str(buyIronPrice) + " cr ea)")
    PrintN("  BUY ALUMINUM <qty> - Buy aluminum (" + Str(buyAlumPrice) + " cr ea)")
    PrintN("  BUY COPPER <qty>   - Buy copper (" + Str(buyCopperPrice) + " cr ea)")
    PrintN("  BUY TIN <qty>      - Buy tin (" + Str(buyTinPrice) + " cr ea)")
    PrintN("  BUY BRONZE <qty>   - Buy bronze (" + Str(buyBronzePrice) + " cr ea)")
    PrintN("  BUY DILITHIUM <qty>- Buy dilithium (" + Str(buyDilithiumPrice) + " cr ea)")
    PrintN("  UNDOCK             - Leave the refinery")
    If gCheatsUnlocked = 0
      PrintN("  CODE <number>     - Enter secret code to unlock cheats")
    EndIf
    If gCheatsUnlocked = 1
      PrintN("CHEATS:")
      PrintN("  showmethemoney | poweroverwhelming | miner2049er")
      PrintN("  spawnyard | spawnbase | spawnrefinery | spawncluster")
      PrintN("  spawnwormhole | spawnanomaly | spawnplanetkiller | removespawn")
    EndIf
    Print("")
    ConsoleColor(#C_WHITE, #C_BLACK)
    Print("REFINERY> ")
    Protected cmd.s = TrimLower(Input())
    ResetColor()
    
    ; Check for code unlock
    Protected refCodeCmd.s = StringField(cmd, 1, " ")
    Protected refCodeArg.s = Trim(StringField(cmd, 2, " "))
    If refCodeCmd = "code"
      If gCheatsUnlocked = 1
        PrintN("Cheats are already unlocked!")
      ElseIf refCodeArg = ""
        PrintN("Usage: CODE <4-digit-number>")
        PrintN("A secret code appears every 10 turns. Watch for it!")
      ElseIf CheckCheatCode(refCodeArg)
        ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
        PrintN("*** CHEATS UNLOCKED! ***")
        PrintN("You now have access to all cheat commands!")
        ResetColor()
      Else
        ConsoleColor(#C_LIGHTRED, #C_BLACK)
        PrintN("Invalid code. The code changes every 10 turns.")
        ResetColor()
      EndIf
      Continue
    EndIf
    
    ; Hide cheats unless unlocked
    If gCheatsUnlocked = 0
      Protected isCheat.i = 0
      If cmd = "showmethemoney" Or cmd = "poweroverwhelming" Or cmd = "miner2049er"
        isCheat = 1
      EndIf
      If cmd = "spawnyard" Or cmd = "spawnbase" Or cmd = "spawnrefinery"
        isCheat = 1
      EndIf
      If cmd = "spawncluster" Or cmd = "spawnwormhole" Or cmd = "spawnanomaly"
        isCheat = 1
      EndIf
      If cmd = "spawnplanetkiller" Or cmd = "removespawn"
        isCheat = 1
      EndIf
      If isCheat = 1
        If gCheatCode <> ""
          ConsoleColor(#C_YELLOW, #C_BLACK)
          PrintN("*** SECRET CODE: " + gCheatCode + " | Type CODE <number> to unlock cheats ***")
          ResetColor()
        Else
          PrintN("No cheat code available yet. Keep exploring!")
        EndIf
        Continue
      EndIf
    EndIf
    
    If cmd = "showmethemoney"
      gCredits + 500
      LogLine("CHEAT: showmethemoney (+500 credits)")
      PrintN("Cheat activated: +500 credits!")
      Continue
    EndIf
    If cmd = "poweroverwhelming"
      If gPowerBuff = 0
        gPowerBuff = 1
        gPowerBuffTurns = 30
        *p\hullMax = *p\hullMax * 2
        *p\shieldsMax = *p\shieldsMax * 2
        *p\reactorMax = *p\reactorMax * 2
        *p\weaponCapMax = *p\weaponCapMax * 2
        *p\warpMax = *p\warpMax * 2.0
        *p\impulseMax = *p\impulseMax * 2.0
        *p\phaserBanks = *p\phaserBanks + 1
        *p\torpTubes = *p\torpTubes + 1
        *p\torpMax = *p\torpMax * 2
        *p\sensorRange = *p\sensorRange + 5
        *p\fuelMax = *p\fuelMax * 2
        *p\oreMax = *p\oreMax * 2
        *p\dilithiumMax = *p\dilithiumMax * 2
        *p\hull = *p\hullMax
        *p\shields = *p\shieldsMax
        *p\weaponCap = *p\weaponCapMax
        *p\torp = *p\torpMax
        *p\fuel = *p\fuelMax
        LogLine("CHEAT: poweroverwhelming (buff active)")
        PrintN("Cheat activated: POWER OVERWHELMING! All systems doubled!")
        PrintN("Buff will last for 30 turns or until death.")
      Else
        PrintN("Power Overwhelming is already active! Buff duration refreshed.")
        gPowerBuffTurns = 30
      EndIf
      gLastCmdLine = "" ; Clear the command line
      Continue
    EndIf
    If cmd = "miner2049er"
      *p\ore = *p\oreMax
      *p\dilithium = *p\dilithiumMax
      *p\fuel = *p\fuelMax
      *p\probes = *p\probesMax
      LogLine("CHEAT: miner2049er (filled cargo)")
      PrintN("Cheat activated: Cargo hold, fuel, and probes filled!")
      Continue
    EndIf

    If cmd = "undock" Or cmd = "leave" Or cmd = "exit" Or cmd = "0"
      gDocked = 0
      Protected refFoundEmpty.i = 0
      Protected refDx.i, refDy.i
      For refDy = -1 To 1
        For refDx = -1 To 1
          If refDx = 0 And refDy = 0 : Continue : EndIf
          Protected rnx.i = gx + refDx
          Protected rny.i = gy + refDy
          If rnx >= 0 And rnx < #MAP_W And rny >= 0 And rny < #MAP_H
            If gGalaxy(gMapX, gMapY, rnx, rny)\entType = #ENT_EMPTY
              gx = rnx
              gy = rny
              refFoundEmpty = 1
              Break 2
            EndIf
          EndIf
        Next
      Next
      PrintN("Undocking...")
      StartEngineLoop()
      Break
    EndIf
    
    If cmd = "refine"
      If *p\ore <= 0
        PrintN("No ore to refine.")
        Continue
      EndIf
      *p\ore - 1
      Protected metalType.i = Random(4)
      Select metalType
        Case 0
          gIron + 1
          PrintN("Refined 1 ore -> 1 Iron")
        Case 1
          gAluminum + 1
          PrintN("Refined 1 ore -> 1 Aluminum")
        Case 2
          gCopper + 1
          PrintN("Refined 1 ore -> 1 Copper")
        Case 3
          gTin + 1
          PrintN("Refined 1 ore -> 1 Tin")
        Case 4
          gBronze + 1
          PrintN("Refined 1 ore -> 1 Bronze")
      EndSelect
      LogLine("REFINE: ore -> metal type " + Str(metalType))
      AddCaptainLog("REFINERY: refined 1 ore")
      Continue
    ElseIf cmd = "refine all"
      If *p\ore <= 0
        PrintN("No ore to refine.")
        Continue
      EndIf
      Protected refinedCount.i = 0
      While *p\ore > 0
        *p\ore - 1
        metalType = Random(4)
        Select metalType
          Case 0
            gIron + 1
          Case 1
            gAluminum + 1
          Case 2
            gCopper + 1
          Case 3
            gTin + 1
          Case 4
            gBronze + 1
        EndSelect
        refinedCount + 1
      Wend
      PrintN("Refined " + Str(refinedCount) + " ore into refined metals.")
      LogLine("REFINE ALL: " + Str(refinedCount) + " ore refined")
      AddCaptainLog("REFINERY: refined all ore (" + Str(refinedCount) + ")")
      Continue
    ElseIf cmd = "refine dilithium"
      If *p\dilithium <= 0
        PrintN("No dilithium crystals to refine.")
        Continue
      EndIf
      *p\dilithium - 1
      Protected oreGain.i = 5
      *p\ore + oreGain
      If *p\ore > *p\oreMax
        *p\ore = *p\oreMax
      EndIf
      PrintN("Refined 1 dilithium crystal -> " + Str(oreGain) + " ore")
      LogLine("REFINE DILITHIUM: 1 crystal -> " + Str(oreGain) + " ore")
      AddCaptainLog("REFINERY: refined 1 dilithium crystal")
      Continue
    EndIf
    
    Protected sellCmd.s = StringField(cmd, 1, " ")
    Protected sellQty.i = 0
    Protected sellPrice.i = 0
    
    If sellCmd = "sell"
      Protected sellTarget.s = TrimLower(StringField(cmd, 2, " "))
      
      If sellTarget = "ore"
        If *p\ore <= 0
          PrintN("No ore to sell.")
          Continue
        EndIf
        sellQty = *p\ore
        sellPrice = basePrice
        *p\ore = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " ore for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " ore for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " ore")
        Continue
      ElseIf sellTarget = "iron"
        If gIron <= 0
          PrintN("No iron to sell.")
          Continue
        EndIf
        sellQty = gIron
        sellPrice = ironPrice
        gIron = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " iron for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " iron for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " iron")
        Continue
      ElseIf sellTarget = "aluminum"
        If gAluminum <= 0
          PrintN("No aluminum to sell.")
          Continue
        EndIf
        sellQty = gAluminum
        sellPrice = alumPrice
        gAluminum = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " aluminum for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " aluminum for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " aluminum")
        Continue
      ElseIf sellTarget = "copper"
        If gCopper <= 0
          PrintN("No copper to sell.")
          Continue
        EndIf
        sellQty = gCopper
        sellPrice = copperPrice
        gCopper = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " copper for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " copper for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " copper")
        Continue
      ElseIf sellTarget = "tin"
        If gTin <= 0
          PrintN("No tin to sell.")
          Continue
        EndIf
        sellQty = gTin
        sellPrice = tinPrice
        gTin = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " tin for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " tin for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " tin")
        Continue
      ElseIf sellTarget = "bronze"
        If gBronze <= 0
          PrintN("No bronze to sell.")
          Continue
        EndIf
        sellQty = gBronze
        sellPrice = bronzePrice
        gBronze = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " bronze for " + Str(sellQty * sellPrice) + " credits.")
        LogLine("SELL: " + Str(sellQty) + " bronze for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " bronze")
        Continue
      ElseIf sellTarget = "dilithium"
        If *p\dilithium <= 0
          PrintN("No dilithium to sell.")
          Continue
        EndIf
        sellQty = *p\dilithium
        sellPrice = dilithiumPrice
        *p\dilithium = 0
        gCredits + (sellQty * sellPrice)
        PrintN("Sold " + Str(sellQty) + " dilithium for " + Str(sellQty * sellPrice) + " credits!")
        PrintN("WARNING: High-value cargo will attract pirates!")
        LogLine("SELL: " + Str(sellQty) + " dilithium for " + Str(sellQty * sellPrice))
        AddCaptainLog("REFINERY: sold " + Str(sellQty) + " dilithium")
      ElseIf sellTarget = "all"
        Protected totalCredits.i = 0
        If *p\ore > 0
          totalCredits + (*p\ore * basePrice)
          *p\ore = 0
        EndIf
        If *p\dilithium > 0
          totalCredits + (*p\dilithium * dilithiumPrice)
          *p\dilithium = 0
        EndIf
        If gIron > 0
          totalCredits + (gIron * ironPrice)
          gIron = 0
        EndIf
        If gAluminum > 0
          totalCredits + (gAluminum * alumPrice)
          gAluminum = 0
        EndIf
        If gCopper > 0
          totalCredits + (gCopper * copperPrice)
          gCopper = 0
        EndIf
        If gTin > 0
          totalCredits + (gTin * tinPrice)
          gTin = 0
        EndIf
        If gBronze > 0
          totalCredits + (gBronze * bronzePrice)
          gBronze = 0
        EndIf
        gCredits + totalCredits
        PrintN("Sold all cargo for " + Str(totalCredits) + " credits.")
        LogLine("SELL ALL: " + Str(totalCredits) + " credits")
        AddCaptainLog("REFINERY: sold all cargo for " + Str(totalCredits) + " credits")
      Else
        PrintN("Unknown sell target. Use: ORE, IRON, ALUMINUM, COPPER, TIN, BRONZE, or ALL")
      EndIf
      Continue
    EndIf

    ; ---- BUY command --------------------------------------------------------
    If sellCmd = "buy"
      Protected buyTarget.s = TrimLower(StringField(cmd, 2, " "))
      Protected buyQty.i    = ParseIntSafe(StringField(cmd, 3, " "), 0)
      If buyQty <= 0
        PrintN("Usage: BUY <item> <quantity>  (e.g. BUY IRON 10)")
        Continue
      EndIf
      Protected buyUnitPrice.i = 0
      Protected buyItemName.s  = ""
      Select buyTarget
        Case "iron"
          buyUnitPrice = buyIronPrice : buyItemName = "iron"
        Case "aluminum"
          buyUnitPrice = buyAlumPrice : buyItemName = "aluminum"
        Case "copper"
          buyUnitPrice = buyCopperPrice : buyItemName = "copper"
        Case "tin"
          buyUnitPrice = buyTinPrice : buyItemName = "tin"
        Case "bronze"
          buyUnitPrice = buyBronzePrice : buyItemName = "bronze"
        Case "dilithium"
          buyUnitPrice = buyDilithiumPrice : buyItemName = "dilithium"
        Default
          PrintN("Unknown item. Buy: IRON, ALUMINUM, COPPER, TIN, BRONZE, DILITHIUM")
          Continue
      EndSelect
      Protected buyTotal.i = buyQty * buyUnitPrice
      If gCredits < buyTotal
        Protected canAfford.i = gCredits / buyUnitPrice
        ConsoleColor(#C_LIGHTRED, #C_BLACK)
        PrintN("Not enough credits! Need " + Str(buyTotal) + ", have " + Str(gCredits) + ".")
        If canAfford > 0
          PrintN("You can afford " + Str(canAfford) + " unit(s) at this price.")
        EndIf
        ResetColor()
        Continue
      EndIf
      gCredits - buyTotal
      Select buyTarget
        Case "iron"      : gIron      + buyQty
        Case "aluminum"  : gAluminum  + buyQty
        Case "copper"    : gCopper    + buyQty
        Case "tin"       : gTin       + buyQty
        Case "bronze"    : gBronze    + buyQty
        Case "dilithium" : *p\dilithium + buyQty
      EndSelect
      ConsoleColor(#C_LIGHTGREEN, #C_BLACK)
      PrintN("Purchased " + Str(buyQty) + " " + buyItemName + " for " + Str(buyTotal) + " credits.")
      ResetColor()
      LogLine("BUY: " + Str(buyQty) + " " + buyItemName + " for " + Str(buyTotal))
      AddCaptainLog("REFINERY: bought " + Str(buyQty) + " " + buyItemName)
      Continue
    EndIf

    PrintN("Unknown command. Type UNDOCK to leave.")
  Wend
EndProcedure
