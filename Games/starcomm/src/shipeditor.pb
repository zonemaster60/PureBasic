EnableExplicit

#APP_NAME1 = "shipeditor"
#APP_NAME2 = "starcomm"

Global version.s = "v1.0.0.1"
Global AppPath.s = GetFilePart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Console color constants (Windows console palette)
#C_BLACK      = 0
#C_DARKBLUE   = 1
#C_DARKGREEN  = 2
#C_DARKCYAN   = 3
#C_DARKRED    = 4
#C_PURPLE     = 5
#C_DARKYELLOW = 6
#C_LIGHTGRAY  = 7
#C_DARKGRAY   = 8
#C_BLUE       = 9
#C_GREEN      = 10
#C_CYAN       = 11
#C_RED        = 12
#C_LIGHTRED   = 12
#C_PINK       = 13
#C_YELLOW     = 14
#C_WHITE      = 15
#C_LIGHTGREEN = 10

Procedure ResetColor()
  ConsoleColor(#C_LIGHTGRAY, #C_BLACK)
EndProcedure

#MAX_SHIPS = 20

Global gIniPath.s
Global gActivePlayer.s
Global gActiveEnemy.s

Structure ShipEntry
  section.s
  shipName.s
  shipClass.s
  hullMax.i
  shieldsMax.i
  reactorMax.i
  warpMax.f
  impulseMax.f
  phaserBanks.i
  torpTubes.i
  torpMax.i
  sensorRange.i
  weaponCapMax.i
  fuelMax.i
  oreMax.i
  dilithiumMax.i
  probesMax.i
  allocShields.i
  allocWeapons.i
  allocEngines.i
  isDefault.i   ; 1 if bare default (PlayerShip or EnemyShip), cannot be deleted
EndStructure

Global Dim gPlayerShips.ShipEntry(#MAX_SHIPS)
Global gPlayerCount.i = 0
Global Dim gEnemyShips.ShipEntry(#MAX_SHIPS)
Global gEnemyCount.i = 0

Declare.i ShowEditScreen(*e.ShipEntry)
Declare.i SaveShipToIni(*e.ShipEntry)
Declare AddShip(shipType.i)
Declare DuplicateShip(shipType.i, sourceIdx.i)
Declare DeleteShip(shipType.i, idx.i)
Declare SetActiveShip(shipType.i, idx.i)

;==============================================================================
; ReadShipEntry reads one section from the open preferences into *e
; Call AFTER OpenPreferences(). Does NOT open or close preferences.
;==============================================================================
Procedure ReadShipEntry(section.s, *e.ShipEntry)
  PreferenceGroup(section)
  *e\section      = section
  *e\shipName     = ReadPreferenceString("Name",        "")
  *e\shipClass    = ReadPreferenceString("Class",       "")
  *e\hullMax      = ReadPreferenceLong("HullMax",       100)
  *e\shieldsMax   = ReadPreferenceLong("ShieldsMax",    100)
  *e\reactorMax   = ReadPreferenceLong("ReactorMax",    200)
  *e\warpMax      = ReadPreferenceFloat("WarpMax",      9.0)
  *e\impulseMax   = ReadPreferenceFloat("ImpulseMax",   1.0)
  *e\phaserBanks  = ReadPreferenceLong("PhaserBanks",   4)
  *e\torpTubes    = ReadPreferenceLong("TorpedoTubes",  2)
  *e\torpMax      = ReadPreferenceLong("TorpedoesMax",  10)
  *e\sensorRange  = ReadPreferenceLong("SensorRange",   20)
  *e\weaponCapMax = ReadPreferenceLong("WeaponCapMax",  200)
  *e\fuelMax      = ReadPreferenceLong("FuelMax",       100)
  *e\oreMax       = ReadPreferenceLong("OreMax",        50)
  *e\dilithiumMax = ReadPreferenceLong("DilithiumMax",  20)
  *e\probesMax    = ReadPreferenceLong("ProbesMax",     5)
  *e\allocShields = ReadPreferenceLong("AllocShields",  33)
  *e\allocWeapons = ReadPreferenceLong("AllocWeapons",  34)
  *e\allocEngines = ReadPreferenceLong("AllocEngines",  33)
  *e\isDefault    = Bool(section = "PlayerShip" Or section = "EnemyShip")
EndProcedure

;==============================================================================
; LoadAllShips discovers and loads all ship sections from the INI.
; Also reads active PlayerSection / EnemySection from [Game].
; Returns 1 on success, 0 on failure.
;==============================================================================
Procedure.i LoadAllShips()
  Protected grp.s

  If OpenPreferences(gIniPath) = 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("ERROR: Cannot open " + gIniPath)
    ResetColor()
    ProcedureReturn 0
  EndIf

  ; Read active sections from [Game]
  PreferenceGroup("Game")
  gActivePlayer = ReadPreferenceString("PlayerSection", "PlayerShip")
  gActiveEnemy  = ReadPreferenceString("EnemySection",  "EnemyShip")

  ; Discover ship sections
  gPlayerCount = 0
  gEnemyCount  = 0

  If ExaminePreferenceGroups() = 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("ERROR: Cannot enumerate INI groups.")
    ResetColor()
    ClosePreferences()
    ProcedureReturn 0
  EndIf

  While NextPreferenceGroup()
    grp = PreferenceGroupName()
    If grp = "PlayerShip" Or Left(grp, 11) = "PlayerShip_"
      If gPlayerCount < #MAX_SHIPS
        gPlayerCount + 1
        ReadShipEntry(grp, @gPlayerShips(gPlayerCount))
      EndIf
    ElseIf grp = "EnemyShip" Or Left(grp, 10) = "EnemyShip_"
      If gEnemyCount < #MAX_SHIPS
        gEnemyCount + 1
        ReadShipEntry(grp, @gEnemyShips(gEnemyCount))
      EndIf
    EndIf
  Wend

  ClosePreferences()
  ProcedureReturn 1
EndProcedure

Procedure PrintDivider()
  PrintN("------------------------------------------------------------")
EndProcedure

;==============================================================================
; ShowMainMenu prints the main menu. Returns "p", "e", or "q".
;==============================================================================
Procedure.s ShowMainMenu()
  Protected input.s
  Repeat
    ConsoleColor(#C_CYAN, #C_BLACK)
    PrintN("=== STARCOMM SHIP EDITOR " + version + " ===")
    ResetColor()
    PrintDivider()
    Print("Active Player: ")
    ConsoleColor(#C_YELLOW, #C_BLACK)
    Print(gActivePlayer)
    ResetColor()
    PrintN("")
    Print("Active Enemy:  ")
    ConsoleColor(#C_YELLOW, #C_BLACK)
    Print(gActiveEnemy)
    ResetColor()
    PrintN("")
    PrintDivider()
    PrintN("[P] Player Ships  [E] Enemy Ships  [Q] Quit")
    Print("> ")
    input = LCase(Trim(Input()))
  Until input = "p" Or input = "e" Or input = "q"
  ProcedureReturn input
EndProcedure

;==============================================================================
; PrintShipList prints numbered list of player or enemy ships.
; shipType: 0 = player, 1 = enemy
;==============================================================================
Procedure PrintShipList(shipType.i)
  Protected i.i
  Protected count.i
  Protected active.s
  Protected section.s
  Protected name.s

  If shipType = 0
    count  = gPlayerCount
    active = gActivePlayer
    ConsoleColor(#C_CYAN, #C_BLACK)
    PrintN("=== PLAYER SHIPS ===")
  Else
    count  = gEnemyCount
    active = gActiveEnemy
    ConsoleColor(#C_CYAN, #C_BLACK)
    PrintN("=== ENEMY SHIPS ===")
  EndIf
  ResetColor()
  PrintDivider()

  For i = 1 To count
    If shipType = 0
      section = gPlayerShips(i)\section
      name    = gPlayerShips(i)\shipName
    Else
      section = gEnemyShips(i)\section
      name    = gEnemyShips(i)\shipName
    EndIf

    Print("  " + RSet(Str(i), 2) + ". ")
    ConsoleColor(#C_WHITE, #C_BLACK)
    Print(LSet(name, 22))
    ResetColor()
    Print("[" + section + "]")

    If section = active
      ConsoleColor(#C_YELLOW, #C_BLACK)
      Print("  * ACTIVE *")
      ResetColor()
    EndIf

    If shipType = 0 And gPlayerShips(i)\isDefault
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      Print("  [protected]")
      ResetColor()
    ElseIf shipType = 1 And gEnemyShips(i)\isDefault
      ConsoleColor(#C_DARKGRAY, #C_BLACK)
      Print("  [protected]")
      ResetColor()
    EndIf
    PrintN("")
  Next
  PrintDivider()
  PrintN("[1-" + Str(count) + "]-Edit  [A]dd  [D]up  [X] Del  [S]et Active  [B]ack")
EndProcedure

;==============================================================================
; ShowShipList ship list screen for player (0) or enemy (1) ships.
; Loops until user presses B to go back.
;==============================================================================
Procedure ShowShipList(shipType.i)
  Protected input.s
  Protected cmd.s
  Protected arg.i
  Protected count.i
  Protected editEntry.ShipEntry

  Repeat
    If shipType = 0 : count = gPlayerCount : Else : count = gEnemyCount : EndIf

    PrintShipList(shipType)
    Print("> ")
    input = LCase(Trim(Input()))

    ; Parse "cmd" or "cmd #" (e.g. "d 2", "x 3", "s 1")
    If Len(input) >= 3 And Mid(input, 2, 1) = " "
      cmd = Left(input, 1)
      arg = Val(Mid(input, 3))
    ElseIf Val(input) > 0
      cmd = "edit"
      arg = Val(input)
    Else
      cmd = input
      arg = 0
    EndIf

    Select cmd
      Case "edit"
        If arg >= 1 And arg <= count
          If shipType = 0
            CopyStructure(@gPlayerShips(arg), @editEntry, ShipEntry)
          Else
            CopyStructure(@gEnemyShips(arg), @editEntry, ShipEntry)
          EndIf
          If ShowEditScreen(@editEntry)
            If SaveShipToIni(@editEntry)
              ConsoleColor(#C_GREEN, #C_BLACK)
              PrintN("Saved.")
              ResetColor()
              LoadAllShips()
            EndIf
          EndIf
        Else
          PrintN("Invalid number.")
        EndIf
      Case "a"
        AddShip(shipType)
      Case "d"
        If arg >= 1 And arg <= count
          DuplicateShip(shipType, arg)
        Else
          PrintN("Usage: D <number>")
        EndIf
      Case "x"
        If arg >= 1 And arg <= count
          DeleteShip(shipType, arg)
        Else
          PrintN("Usage: X <number>")
        EndIf
      Case "s"
        If arg >= 1 And arg <= count
          SetActiveShip(shipType, arg)
        Else
          PrintN("Usage: S <number>")
        EndIf
      Case "b"
        ; fall through Repeat condition handles exit
      Default
        If cmd <> ""
          PrintN("Unknown command. Use a number to edit, or A/D/X/S/B.")
        EndIf
    EndSelect

  Until cmd = "b"
EndProcedure

;==============================================================================
; PrintEditScreen prints all 19 editable fields for a ship entry.
;==============================================================================
Procedure PrintEditScreen(*e.ShipEntry)
  Protected allocSum.i = *e\allocShields + *e\allocWeapons + *e\allocEngines

  ConsoleColor(#C_CYAN, #C_BLACK)
  PrintN("=== EDIT: " + *e\shipName + " [" + *e\section + "] ===")
  ResetColor()
  PrintDivider()

  PrintN("   1. Name:          " + *e\shipName)
  PrintN("   2. Class:         " + *e\shipClass)
  PrintN("   3. HullMax:       " + Str(*e\hullMax)      + "  (10-600)")
  PrintN("   4. ShieldsMax:    " + Str(*e\shieldsMax)   + "  (0-600)")
  PrintN("   5. ReactorMax:    " + Str(*e\reactorMax)   + "  (50-600)")
  PrintN("   6. WarpMax:       " + StrF(*e\warpMax, 1)  + "  (0.0-12.0)")
  PrintN("   7. ImpulseMax:    " + StrF(*e\impulseMax, 1) + "  (0.0-2.5)")
  PrintN("   8. PhaserBanks:   " + Str(*e\phaserBanks)  + "  (0-20)")
  PrintN("   9. TorpTubes:     " + Str(*e\torpTubes)    + "  (0-6)")
  PrintN("  10. TorpMax:       " + Str(*e\torpMax)      + "  (0-50)")
  PrintN("  11. SensorRange:   " + Str(*e\sensorRange)  + "  (1-60)")
  PrintN("  12. WeaponCapMax:  " + Str(*e\weaponCapMax) + "  (10-1200)")
  PrintN("  13. FuelMax:       " + Str(*e\fuelMax)      + "  (10-600)")
  PrintN("  14. OreMax:        " + Str(*e\oreMax)       + "  (0-250)")
  PrintN("  15. DilithiumMax:  " + Str(*e\dilithiumMax) + "  (0-50)")
  PrintN("  16. ProbesMax:     " + Str(*e\probesMax)    + "  (0-20)")

  PrintN("  17. AllocShields:  " + Str(*e\allocShields) + "  (0-100)")
  PrintN("  18. AllocWeapons:  " + Str(*e\allocWeapons) + "  (0-100)")
  PrintN("  19. AllocEngines:  " + Str(*e\allocEngines) + "  (0-100)")
  If allocSum = 100
    ConsoleColor(#C_GREEN, #C_BLACK)
    PrintN("      Alloc sum: " + Str(allocSum) + " (OK)")
  Else
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("      Alloc sum: " + Str(allocSum) + " (must equal 100!)")
  EndIf
  ResetColor()

  PrintDivider()
  PrintN("[1-19] Edit field  [S]ave  [B]ack (discard)")
EndProcedure

Procedure.i ClampInt(v.i, mn.i, mx.i)
  If v < mn : ProcedureReturn mn : EndIf
  If v > mx : ProcedureReturn mx : EndIf
  ProcedureReturn v
EndProcedure

Procedure.f ClampF(v.f, mn.f, mx.f)
  If v < mn : ProcedureReturn mn : EndIf
  If v > mx : ProcedureReturn mx : EndIf
  ProcedureReturn v
EndProcedure

;==============================================================================
; SaveShipToIni writes one ShipEntry to the INI file.
; Opens and closes preferences internally.
; Returns 1 on success, 0 on failure.
;==============================================================================
Procedure.i SaveShipToIni(*e.ShipEntry)
  If OpenPreferences(gIniPath) = 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("ERROR: Cannot open INI for writing.")
    ResetColor()
    ProcedureReturn 0
  EndIf

  PreferenceGroup(*e\section)
  WritePreferenceString("Name",         *e\shipName)
  WritePreferenceString("Class",        *e\shipClass)
  WritePreferenceLong("HullMax",        *e\hullMax)
  WritePreferenceLong("ShieldsMax",     *e\shieldsMax)
  WritePreferenceLong("ReactorMax",     *e\reactorMax)
  WritePreferenceFloat("WarpMax",       *e\warpMax)
  WritePreferenceFloat("ImpulseMax",    *e\impulseMax)
  WritePreferenceLong("PhaserBanks",    *e\phaserBanks)
  WritePreferenceLong("TorpedoTubes",   *e\torpTubes)
  WritePreferenceLong("TorpedoesMax",   *e\torpMax)
  WritePreferenceLong("SensorRange",    *e\sensorRange)
  WritePreferenceLong("WeaponCapMax",   *e\weaponCapMax)
  WritePreferenceLong("FuelMax",        *e\fuelMax)
  WritePreferenceLong("OreMax",         *e\oreMax)
  WritePreferenceLong("DilithiumMax",   *e\dilithiumMax)
  WritePreferenceLong("ProbesMax",      *e\probesMax)
  WritePreferenceLong("AllocShields",   *e\allocShields)
  WritePreferenceLong("AllocWeapons",   *e\allocWeapons)
  WritePreferenceLong("AllocEngines",   *e\allocEngines)

  ClosePreferences()
  ProcedureReturn 1
EndProcedure

;==============================================================================
; PromptSuffix asks user for a new section suffix.
; prefix: "PlayerShip" or "EnemyShip"
; Returns the full section name on success, or "" if cancelled.
;==============================================================================
Procedure.s PromptSuffix(prefix.s)
  Protected suffix.s
  Protected candidate.s
  Protected i.i
  Protected taken.i

  Repeat
    Print("Enter suffix for new variant (e.g. Carrier) or B to cancel: ")
    suffix = Trim(Input())
    If LCase(suffix) = "b" : ProcedureReturn "" : EndIf
    If suffix = "" : PrintN("Suffix cannot be empty.") : Continue : EndIf
    If FindString(suffix, " ") Or FindString(suffix, "|")
      PrintN("Suffix cannot contain spaces or '|'.")
      Continue
    EndIf

    candidate = prefix + "_" + suffix

    ; Check uniqueness
    taken = 0
    For i = 1 To gPlayerCount
      If gPlayerShips(i)\section = candidate : taken = 1 : Break : EndIf
    Next
    If taken = 0
      For i = 1 To gEnemyCount
        If gEnemyShips(i)\section = candidate : taken = 1 : Break : EndIf
      Next
    EndIf

    If taken
      PrintN("Section '" + candidate + "' already exists. Choose a different suffix.")
    Else
      ProcedureReturn candidate
    EndIf
  ForEver
EndProcedure

;==============================================================================
; AddShip prompts for a suffix, prefills from default, opens edit screen.
; shipType: 0 = player, 1 = enemy
;==============================================================================
Procedure AddShip(shipType.i)
  Protected prefix.s
  Protected newSection.s
  Protected newEntry.ShipEntry

  If shipType = 0 : prefix = "PlayerShip" : Else : prefix = "EnemyShip" : EndIf

  newSection = PromptSuffix(prefix)
  If newSection = "" : ProcedureReturn : EndIf

  ; Prefill from the default ship (index 1, always the bare default)
  If shipType = 0 And gPlayerCount >= 1
    CopyStructure(@gPlayerShips(1), @newEntry, ShipEntry)
  ElseIf shipType = 1 And gEnemyCount >= 1
    CopyStructure(@gEnemyShips(1), @newEntry, ShipEntry)
  EndIf
  newEntry\section   = newSection
  newEntry\shipName  = "New Ship"
  newEntry\isDefault = 0

  If ShowEditScreen(@newEntry)
    If SaveShipToIni(@newEntry)
      ConsoleColor(#C_GREEN, #C_BLACK)
      PrintN("New variant '" + newSection + "' saved.")
      ResetColor()
      LoadAllShips()
    EndIf
  EndIf
EndProcedure

;==============================================================================
; DuplicateShip copies an existing variant, prompts for new suffix.
;==============================================================================
Procedure DuplicateShip(shipType.i, sourceIdx.i)
  Protected prefix.s
  Protected newSection.s
  Protected newEntry.ShipEntry

  If shipType = 0 : prefix = "PlayerShip" : Else : prefix = "EnemyShip" : EndIf

  newSection = PromptSuffix(prefix)
  If newSection = "" : ProcedureReturn : EndIf

  If shipType = 0
    CopyStructure(@gPlayerShips(sourceIdx), @newEntry, ShipEntry)
  Else
    CopyStructure(@gEnemyShips(sourceIdx), @newEntry, ShipEntry)
  EndIf
  newEntry\section   = newSection
  newEntry\isDefault = 0

  If ShowEditScreen(@newEntry)
    If SaveShipToIni(@newEntry)
      ConsoleColor(#C_GREEN, #C_BLACK)
      PrintN("Duplicate '" + newSection + "' saved.")
      ResetColor()
      LoadAllShips()
    EndIf
  EndIf
EndProcedure

;==============================================================================
; DeleteShip removes a non-default variant from the INI.
; Protected defaults (isDefault = 1) are rejected with a message.
;==============================================================================
Procedure DeleteShip(shipType.i, idx.i)
  Protected section.s
  Protected name.s
  Protected confirm.s
  Protected isDefaultShip.i

  If shipType = 0
    section        = gPlayerShips(idx)\section
    name           = gPlayerShips(idx)\shipName
    isDefaultShip  = gPlayerShips(idx)\isDefault
  Else
    section        = gEnemyShips(idx)\section
    name           = gEnemyShips(idx)\shipName
    isDefaultShip  = gEnemyShips(idx)\isDefault
  EndIf

  If isDefaultShip
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("Cannot delete '" + section + "' it is a protected default.")
    ResetColor()
    ProcedureReturn
  EndIf

  ; Warn if it is the active variant
  If (shipType = 0 And section = gActivePlayer) Or (shipType = 1 And section = gActiveEnemy)
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("Warning: '" + section + "' is currently the active ship.")
    ResetColor()
  EndIf

  Print("Delete " + section + " (" + name + ")? [Y/N]: ")
  confirm = LCase(Trim(Input()))
  If confirm <> "y" : PrintN("Cancelled.") : ProcedureReturn : EndIf

  If OpenPreferences(gIniPath) = 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("ERROR: Cannot open INI for writing.")
    ResetColor()
    ProcedureReturn
  EndIf

  RemovePreferenceGroup(section)
  ClosePreferences()

  ConsoleColor(#C_GREEN, #C_BLACK)
  PrintN("Deleted '" + section + "'.")
  ResetColor()
  LoadAllShips()
EndProcedure

;==============================================================================
; SetActiveShip updates PlayerSection or EnemySection in [Game].
;==============================================================================
Procedure SetActiveShip(shipType.i, idx.i)
  Protected section.s
  Protected name.s

  If shipType = 0
    section = gPlayerShips(idx)\section
    name    = gPlayerShips(idx)\shipName
  Else
    section = gEnemyShips(idx)\section
    name    = gEnemyShips(idx)\shipName
  EndIf

  If OpenPreferences(gIniPath) = 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("ERROR: Cannot open INI for writing.")
    ResetColor()
    ProcedureReturn
  EndIf

  PreferenceGroup("Game")
  If shipType = 0
    WritePreferenceString("PlayerSection", section)
  Else
    WritePreferenceString("EnemySection", section)
  EndIf
  ClosePreferences()

  ConsoleColor(#C_GREEN, #C_BLACK)
  If shipType = 0
    PrintN("Active player ship set to: " + section + " (" + name + ")")
  Else
    PrintN("Active enemy ship set to: " + section + " (" + name + ")")
  EndIf
  ResetColor()
  LoadAllShips()
EndProcedure

;==============================================================================
; ShowEditScreen edit loop for a ship. Returns 1 if saved, 0 if discarded.
; *e is a COPY of the ship entry; caller updates the array after save.
;==============================================================================
Procedure.i ShowEditScreen(*e.ShipEntry)
  Protected input.s
  Protected fieldNum.i
  Protected newStr.s
  Protected newInt.i
  Protected newFloat.f

  Repeat
    PrintEditScreen(*e)
    Print("> ")
    input = LCase(Trim(Input()))

    fieldNum = Val(input)

    If fieldNum >= 1 And fieldNum <= 19
      Select fieldNum
        Case 1
          Print("New Name: ")
          newStr = Trim(Input())
          If newStr <> "" : *e\shipName = newStr : EndIf
        Case 2
          Print("New Class: ")
          newStr = Trim(Input())
          If newStr <> "" : *e\shipClass = newStr : EndIf
        Case 3
          Print("New HullMax (10-600): ")
          newInt = ClampInt(Val(Trim(Input())), 10, 600)
          *e\hullMax = newInt
        Case 4
          Print("New ShieldsMax (0-600): ")
          newInt = ClampInt(Val(Trim(Input())), 0, 600)
          *e\shieldsMax = newInt
        Case 5
          Print("New ReactorMax (50-600): ")
          newInt = ClampInt(Val(Trim(Input())), 50, 600)
          *e\reactorMax = newInt
        Case 6
          Print("New WarpMax (0.0-12.0): ")
          newFloat = ClampF(ValF(Trim(Input())), 0.0, 12.0)
          *e\warpMax = newFloat
        Case 7
          Print("New ImpulseMax (0.0-2.5): ")
          newFloat = ClampF(ValF(Trim(Input())), 0.0, 2.5)
          *e\impulseMax = newFloat
        Case 8
          Print("New PhaserBanks (0-20): ")
          newInt = ClampInt(Val(Trim(Input())), 0, 20)
          *e\phaserBanks = newInt
        Case 9
          Print("New TorpTubes (0-6): ")
          newInt = ClampInt(Val(Trim(Input())), 0, 6)
          *e\torpTubes = newInt
        Case 10
          Print("New TorpMax (0-50): ")
          newInt = ClampInt(Val(Trim(Input())), 0, 50)
          *e\torpMax = newInt
        Case 11
          Print("New SensorRange (1-60): ")
          newInt = ClampInt(Val(Trim(Input())), 1, 60)
          *e\sensorRange = newInt
        Case 12
          Print("New WeaponCapMax (10-1200): ")
          newInt = ClampInt(Val(Trim(Input())), 10, 1200)
          *e\weaponCapMax = newInt
        Case 13
          Print("New FuelMax (10-600): ")
          newInt = ClampInt(Val(Trim(Input())), 10, 600)
          *e\fuelMax = newInt
        Case 14
          Print("New OreMax (0-250): ")
          newInt = ClampInt(Val(Trim(Input())), 0, 250)
          *e\oreMax = newInt
        Case 15
          Print("New DilithiumMax (0-50): ")
          newInt = ClampInt(Val(Trim(Input())), 0, 50)
          *e\dilithiumMax = newInt
        Case 16
          Print("New ProbesMax (0-20): ")
          newInt = ClampInt(Val(Trim(Input())), 0, 20)
          *e\probesMax = newInt
        Case 17
          Print("New AllocShields (0-100): ")
          *e\allocShields = ClampInt(Val(Trim(Input())), 0, 100)
        Case 18
          Print("New AllocWeapons (0-100): ")
          *e\allocWeapons = ClampInt(Val(Trim(Input())), 0, 100)
        Case 19
          Print("New AllocEngines (0-100): ")
          *e\allocEngines = ClampInt(Val(Trim(Input())), 0, 100)
      EndSelect

    ElseIf input = "s"
      ; Validate alloc sum before saving
      If *e\allocShields + *e\allocWeapons + *e\allocEngines <> 100
        ConsoleColor(#C_LIGHTRED, #C_BLACK)
        PrintN("Cannot save: AllocShields + AllocWeapons + AllocEngines must equal 100.")
        ResetColor()
        input = ""  ; sentinel: clears "s" so Until condition keeps the loop running
      EndIf
    EndIf

  Until input = "s" Or input = "b"
  ProcedureReturn Bool(input = "s")
EndProcedure

;==============================================================================
; Locate starcomm_ships.ini relative to this executable
;==============================================================================
Procedure.i ResolveIniPath()
  gIniPath = GetPathPart(ProgramFilename()) + "data\" + #APP_NAME2 + "_ships.ini"
  If FileSize(gIniPath) < 0
    ; Fallback for IDE runs
    gIniPath = GetCurrentDirectory() + "data\" + #APP_NAME2 + "_ships.ini"
  EndIf
  If FileSize(gIniPath) < 0
    ConsoleColor(#C_LIGHTRED, #C_BLACK)
    PrintN("ERROR: Cannot find " + #APP_NAME2 + "_ships.ini")
    ResetColor()
    PrintN("Tried: " + gIniPath)
    PrintN("Run shipeditor from the starcomm root directory.")
    PrintN("Press ENTER to exit.")
    Input()
    ProcedureReturn 0
  EndIf
  ProcedureReturn 1
EndProcedure

;==============================================================================
; Entry point
;==============================================================================
If OpenConsole("Starcomm Ship Editor " + version)
  ConsoleColor(#C_WHITE, #C_BLACK)
  If ResolveIniPath() = 0 : End : EndIf
  If LoadAllShips() = 0   : End : EndIf

  Define mainCmd.s
  Repeat
    mainCmd = ShowMainMenu()
    Select mainCmd
      Case "p"
        ShowShipList(0)
      Case "e"
        ShowShipList(1)
    EndSelect
  Until mainCmd = "q"

  CloseConsole()
EndIf

; IDE Options = PureBasic 6.30 (Windows - x64)
; ExecutableFormat = Console
; CursorPosition = 5
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; UseIcon = shipeditor.ico
; Executable = ..\shipeditor.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,1
; VersionField1 = 1,0,0,1
; VersionField2 = ZoneSoft
; VersionField3 = shipeditor
; VersionField4 = 1.0.0.1
; VersionField5 = 1.0.0.1
; VersionField6 = A ship editor for the game starcomm
; VersionField7 = shipeditor
; VersionField8 = shipeditor.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60