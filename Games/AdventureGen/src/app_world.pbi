Procedure ResetWorld()
  Protected RoomID.i

  For RoomID = 0 To #WORLD_ROOM_LAST_INDEX
    GS\World(RoomID)\Name = ""
    GS\World(RoomID)\Description = ""
    ClearList(GS\World(RoomID)\Items())
    ClearList(GS\World(RoomID)\Entities())
    GS\World(RoomID)\MapExits[#DIR_NORTH] = -1
    GS\World(RoomID)\MapExits[#DIR_SOUTH] = -1
    GS\World(RoomID)\MapExits[#DIR_EAST] = -1
    GS\World(RoomID)\MapExits[#DIR_WEST] = -1
    GS\World(RoomID)\IsDark = #False
  Next
EndProcedure

Procedure SeedStartingInventory(Role.s)
  ClearList(GS\Inventory())

  AddElement(GS\Inventory())
  GS\Inventory()\Name = Role + " kit"
  GS\Inventory()\Description = "A compact bundle of supplies chosen for a " + LCase(Role) + "."
  GS\Inventory()\Type = "starter"
  GS\Inventory()\Value = 1
  GS\Inventory()\IsTakeable = #True

  AddElement(GS\Inventory())
  GS\Inventory()\Name = "Torch"
  GS\Inventory()\Description = "A reliable torch that can push back darkness when used."
  GS\Inventory()\Type = "utility"
  GS\Inventory()\Value = 1
  GS\Inventory()\IsTakeable = #True
EndProcedure

Procedure SeedWorldDetails(Theme.s, Setting.s, Culture.s, Landmark.s)
  AddElement(GS\World(2)\Items())
  GS\World(2)\Items()\Name = "Ancient tonic"
  GS\World(2)\Items()\Description = "A stoppered vial left by earlier travelers. It restores a bit of strength."
  GS\World(2)\Items()\Type = "healing"
  GS\World(2)\Items()\Value = 20
  GS\World(2)\Items()\IsTakeable = #True

  AddElement(GS\World(3)\Items())
  GS\World(3)\Items()\Name = "Survey notes"
  GS\World(3)\Items()\Description = "A bundle of field notes outlining routes through " + Setting + "."
  GS\World(3)\Items()\Type = "clue"
  GS\World(3)\Items()\Value = 5
  GS\World(3)\Items()\IsTakeable = #True

  AddElement(GS\World(4)\Entities())
  GS\World(4)\Entities()\Name = Theme + " sentinel"
  GS\World(4)\Entities()\Description = "A wary figure guarding secrets tied to " + Landmark + " and " + Culture + "."
  GS\World(4)\Entities()\Health = 25
  GS\World(4)\Entities()\MaxHealth = 25
  GS\World(4)\Entities()\Damage = 6
  GS\World(4)\Entities()\IsHostile = #True
EndProcedure

Declare.b TrySelectRoomItem(RoomID.i, Query.s)

Procedure.b RoomContainsItem(RoomID.i, Query.s)
  If TrySelectRoomItem(RoomID, Query)
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.s NormalizeName(Value.s)
  ProcedureReturn LCase(Trim(Value))
EndProcedure

Procedure.s RoomVisibilityBlockedMessage(RoomID.i)
  If IsValidRoomID(RoomID) And GS\World(RoomID)\IsDark And Not GS\TorchLit
    ProcedureReturn "It is too dark to make that out clearly."
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.b PlayerHasItem(Query.s)
  Protected Wanted.s = NormalizeName(Query)

  If Wanted = ""
    ProcedureReturn #False
  EndIf

  If FirstElement(GS\Inventory())
    Repeat
      If NormalizeName(GS\Inventory()\Name) = Wanted
        ProcedureReturn #True
      EndIf
    Until Not NextElement(GS\Inventory())
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.i CalculatePlayerAttack()
  Protected AttackValue.i = GS\PlayerAttack

  If PlayerHasItem("Survey notes")
    AttackValue + 2
  EndIf

  ProcedureReturn AttackValue
EndProcedure

Procedure.b TrySelectInventoryItem(Query.s)
  Protected Wanted.s = NormalizeName(Query)

  If Wanted = ""
    ProcedureReturn #False
  EndIf

  If FirstElement(GS\Inventory())
    Repeat
      If NormalizeName(GS\Inventory()\Name) = Wanted
        ProcedureReturn #True
      EndIf
    Until Not NextElement(GS\Inventory())
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.b TrySelectRoomItem(RoomID.i, Query.s)
  Protected Wanted.s = NormalizeName(Query)

  If Wanted = "" Or Not IsValidRoomID(RoomID)
    ProcedureReturn #False
  EndIf

  If FirstElement(GS\World(RoomID)\Items())
    Repeat
      If NormalizeName(GS\World(RoomID)\Items()\Name) = Wanted
        ProcedureReturn #True
      EndIf
    Until Not NextElement(GS\World(RoomID)\Items())
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.b TrySelectRoomEntity(RoomID.i, Query.s)
  Protected Wanted.s = NormalizeName(Query)

  If Wanted = "" Or Not IsValidRoomID(RoomID)
    ProcedureReturn #False
  EndIf

  If FirstElement(GS\World(RoomID)\Entities())
    Repeat
      If NormalizeName(GS\World(RoomID)\Entities()\Name) = Wanted
        ProcedureReturn #True
      EndIf
    Until Not NextElement(GS\World(RoomID)\Entities())
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.b SelectFirstLivingEntity(RoomID.i)
  If Not IsValidRoomID(RoomID)
    ProcedureReturn #False
  EndIf

  If FirstElement(GS\World(RoomID)\Entities())
    Repeat
      If GS\World(RoomID)\Entities()\Health > 0
        ProcedureReturn #True
      EndIf
    Until Not NextElement(GS\World(RoomID)\Entities())
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.s GetLivingEntitySummary(RoomID.i)
  Protected Summary.s = ""

  If Not IsValidRoomID(RoomID)
    ProcedureReturn ""
  EndIf

  If FirstElement(GS\World(RoomID)\Entities())
    Repeat
      If GS\World(RoomID)\Entities()\Health > 0
        If Summary <> ""
          Summary + ", "
        EndIf
        Summary + GS\World(RoomID)\Entities()\Name + " (" + Str(GS\World(RoomID)\Entities()\Health) + " HP)"
      EndIf
    Until Not NextElement(GS\World(RoomID)\Entities())
  EndIf

  ProcedureReturn Summary
EndProcedure

Procedure PrintInventoryDetails()
  If ListSize(GS\Inventory()) = 0
    PrintN("Inventory: empty")
    ProcedureReturn
  EndIf

  PrintN("Inventory:")
  If FirstElement(GS\Inventory())
    Repeat
      PrintN("- " + GS\Inventory()\Name + ": " + GS\Inventory()\Description)
    Until Not NextElement(GS\Inventory())
  EndIf
EndProcedure

Procedure.s GetRoomItemSummary(RoomID.i)
  Protected Summary.s = ""

  If Not IsValidRoomID(RoomID)
    ProcedureReturn ""
  EndIf

  If FirstElement(GS\World(RoomID)\Items())
    Repeat
      If Summary <> ""
        Summary + ", "
      EndIf
      Summary + GS\World(RoomID)\Items()\Name
    Until Not NextElement(GS\World(RoomID)\Items())
  EndIf

  ProcedureReturn Summary
EndProcedure

Procedure DropVictoryArtifact(RoomID.i)
  Protected ArtifactName.s = CurrentLandmark + " sigil"

  If RoomContainsItem(RoomID, ArtifactName)
    ProcedureReturn
  EndIf

  AddElement(GS\World(RoomID)\Items())
  GS\World(RoomID)\Items()\Name = ArtifactName
  GS\World(RoomID)\Items()\Description = "A key relic seized from the fallen sentinel. It seems meant to be awakened at " + CurrentLandmark + "."
  GS\World(RoomID)\Items()\Type = "artifact"
  GS\World(RoomID)\Items()\Value = 1
  GS\World(RoomID)\Items()\IsTakeable = #True
EndProcedure

Procedure TakeItem(Query.s)
  Protected RoomID.i = GS\CurrentRoomID
  Protected DarknessMessage.s = RoomVisibilityBlockedMessage(RoomID)
  Protected ItemName.s

  If Query = ""
    PrintN("Take what?")
    Print("> ")
    ProcedureReturn
  EndIf

  If DarknessMessage <> ""
    PrintN(DarknessMessage)
    Print("> ")
    ProcedureReturn
  EndIf

  If TrySelectRoomItem(RoomID, Query) = #False
    PrintN("There is no '" + Query + "' here.")
    Print("> ")
    ProcedureReturn
  EndIf

  If GS\World(RoomID)\Items()\IsTakeable = #False
    PrintN("You cannot take that.")
    Print("> ")
    ProcedureReturn
  EndIf

  ItemName = GS\World(RoomID)\Items()\Name
  AddElement(GS\Inventory())
  GS\Inventory() = GS\World(RoomID)\Items()
  DeleteElement(GS\World(RoomID)\Items())

  PrintN("You take the " + ItemName + ".")
  Print("> ")
EndProcedure

Procedure ExamineTarget(Query.s)
  Protected RoomID.i = GS\CurrentRoomID
  Protected DarknessMessage.s = RoomVisibilityBlockedMessage(RoomID)

  If Query = ""
    PrintN("Examine what?")
    Print("> ")
    ProcedureReturn
  EndIf

  If TrySelectInventoryItem(Query)
    PrintN(GS\Inventory()\Name + ": " + GS\Inventory()\Description)
    Print("> ")
    ProcedureReturn
  EndIf

  If DarknessMessage = "" And TrySelectRoomItem(RoomID, Query)
    PrintN(GS\World(RoomID)\Items()\Name + ": " + GS\World(RoomID)\Items()\Description)
    Print("> ")
    ProcedureReturn
  EndIf

  If DarknessMessage = "" And TrySelectRoomEntity(RoomID, Query)
    PrintN(GS\World(RoomID)\Entities()\Name + ": " + GS\World(RoomID)\Entities()\Description)
    If GS\World(RoomID)\Entities()\Health > 0
      PrintN("Health: " + Str(GS\World(RoomID)\Entities()\Health) + "/" + Str(GS\World(RoomID)\Entities()\MaxHealth))
    EndIf
    Print("> ")
    ProcedureReturn
  EndIf

  If DarknessMessage <> ""
    PrintN(DarknessMessage)
  Else
    PrintN("You find nothing noteworthy called '" + Query + "'.")
  EndIf
  Print("> ")
EndProcedure

Procedure UseItem(Query.s)
  Protected HealAmount.i
  Protected ItemName.s

  If Query = ""
    PrintN("Use what?")
    Print("> ")
    ProcedureReturn
  EndIf

  If TrySelectInventoryItem(Query) = #False
    PrintN("You are not carrying '" + Query + "'.")
    Print("> ")
    ProcedureReturn
  EndIf

  ItemName = GS\Inventory()\Name

  Select NormalizeName(GS\Inventory()\Type)
    Case "utility"
      If NormalizeName(GS\Inventory()\Name) = "torch"
        GS\TorchLit ! #True
        If GS\TorchLit
          PrintN("You light the torch. Shadows retreat from the room.")
        Else
          PrintN("You lower the torch and let the darkness creep back in.")
        EndIf
      Else
        PrintN("You ready the " + GS\Inventory()\Name + ", but nothing changes yet.")
      EndIf
    Case "healing"
      HealAmount = GS\Inventory()\Value
      GS\PlayerHealth = GS\PlayerHealth + HealAmount
      If GS\PlayerHealth > GS\PlayerMaxHealth
        GS\PlayerHealth = GS\PlayerMaxHealth
      EndIf
      PrintN("You use the " + ItemName + " and recover " + Str(HealAmount) + " health.")
      DeleteElement(GS\Inventory())
    Case "artifact"
      If GS\CurrentRoomID = 0
        GS\AdventureWon = #True
        PrintN("You raise the " + ItemName + " at " + CurrentLandmark + ". Ancient mechanisms stir, the path clears, and your quest is fulfilled.")
        DeleteElement(GS\Inventory())
      Else
        PrintN("The " + ItemName + " vibrates with power, but it needs to be used at " + CurrentLandmark + ".")
      EndIf
    Default
      PrintN("You inspect the " + ItemName + ", but it has no active use right now.")
  EndSelect

  Print("> ")
EndProcedure

Procedure AttackTarget(Query.s)
  Protected RoomID.i = GS\CurrentRoomID
  Protected Damage.i
  Protected CounterDamage.i
  Protected AttackName.s
  Protected DarknessMessage.s = RoomVisibilityBlockedMessage(RoomID)

  If DarknessMessage <> ""
    PrintN(DarknessMessage)
    Print("> ")
    ProcedureReturn
  EndIf

  If Query = ""
    If SelectFirstLivingEntity(RoomID) = #False
      PrintN("There is nothing here to attack.")
      Print("> ")
      ProcedureReturn
    EndIf
  ElseIf TrySelectRoomEntity(RoomID, Query) = #False
    PrintN("There is no '" + Query + "' here to attack.")
    Print("> ")
    ProcedureReturn
  EndIf

  If GS\World(RoomID)\Entities()\Health <= 0
    PrintN(GS\World(RoomID)\Entities()\Name + " is already defeated.")
    Print("> ")
    ProcedureReturn
  EndIf

  AttackName = GS\World(RoomID)\Entities()\Name
  Damage = CalculatePlayerAttack() + Random(3)
  GS\World(RoomID)\Entities()\Health - Damage
  PrintN("You strike " + AttackName + " for " + Str(Damage) + " damage.")

  If GS\World(RoomID)\Entities()\Health <= 0
    GS\World(RoomID)\Entities()\Health = 0
    GS\PlayerMana + 5
    If GS\PlayerMana > GS\PlayerMaxMana
      GS\PlayerMana = GS\PlayerMaxMana
    EndIf
    DropVictoryArtifact(RoomID)
    PrintN(AttackName + " falls. You reclaim a bit of focus, restore 5 mana, and reveal a hidden relic.")
    Print("> ")
    ProcedureReturn
  EndIf

  If GS\World(RoomID)\Entities()\IsHostile
    CounterDamage = GS\World(RoomID)\Entities()\Damage + Random(2)
    GS\PlayerHealth - CounterDamage
    PrintN(AttackName + " retaliates for " + Str(CounterDamage) + " damage.")
    If GS\PlayerHealth <= 0
      GS\PlayerHealth = 0
      PrintN("You collapse from your wounds. The adventure ends here.")
    EndIf
  EndIf

  Print("> ")
EndProcedure

Procedure.s GetExitSummary(RoomID.i)
  Protected Summary.s = ""

  If Not IsValidRoomID(RoomID)
    ProcedureReturn "none"
  EndIf

  If IsValidRoomID(GS\World(RoomID)\MapExits[#DIR_NORTH])
    Summary + "N"
  EndIf

  If IsValidRoomID(GS\World(RoomID)\MapExits[#DIR_SOUTH])
    If Summary <> ""
      Summary + ", "
    EndIf
    Summary + "S"
  EndIf

  If IsValidRoomID(GS\World(RoomID)\MapExits[#DIR_EAST])
    If Summary <> ""
      Summary + ", "
    EndIf
    Summary + "E"
  EndIf

  If IsValidRoomID(GS\World(RoomID)\MapExits[#DIR_WEST])
    If Summary <> ""
      Summary + ", "
    EndIf
    Summary + "W"
  EndIf

  If Summary = ""
    Summary = "none"
  EndIf

  ProcedureReturn Summary
EndProcedure

Procedure BuildWorld(Theme.s, Setting.s, Culture.s, Landmark.s, Role.s, Goal.s, Twist.s)
  If Theme = ""
    Theme = "Adventure"
  EndIf

  If Setting = ""
    Setting = "Unknown Frontier"
  EndIf

  If Culture = ""
    Culture = "Unknown Culture"
  EndIf

  If Landmark = ""
    Landmark = "Unknown Landmark"
  EndIf

  If Role = ""
    Role = "Wanderer"
  EndIf

  If Goal = ""
    Goal = "survive the unknown"
  EndIf

  If Twist = ""
    Twist = "someone is hiding the truth"
  EndIf

  CurrentTheme = Theme
  CurrentSetting = Setting
  CurrentCulture = Culture
  CurrentLandmark = Landmark
  CurrentGoal = Goal
  CurrentTwist = Twist

  ResetWorld()

  GS\World(0)\Name = Landmark
  GS\World(0)\Description = "You arrive at " + Landmark + ", the heart of a " + Theme + " adventure shaped by " + Culture + ". Your immediate goal is " + Goal + "."
  GS\World(0)\MapExits[#DIR_NORTH] = 1
  GS\World(0)\MapExits[#DIR_SOUTH] = 2
  GS\World(0)\MapExits[#DIR_EAST] = 3
  GS\World(0)\MapExits[#DIR_WEST] = 4

  GS\World(1)\Name = "Northern Watch"
  GS\World(1)\Description = "A high overlook reveals the edges of " + Setting + " and the distant silhouette of " + Landmark + "."
  GS\World(1)\MapExits[#DIR_SOUTH] = 0
  GS\World(1)\MapExits[#DIR_EAST] = 3

  GS\World(2)\Name = "Southern Trail"
  GS\World(2)\Description = "Tracks in the dust hint that " + Culture + " travelers recently passed through this quieter route. Rumors say that " + Twist + "."
  GS\World(2)\MapExits[#DIR_NORTH] = 0
  GS\World(2)\MapExits[#DIR_WEST] = 4

  GS\World(3)\Name = "Eastern Outpost"
  GS\World(3)\Description = "Tools, maps, and rumors gather here as explorers plan for whatever the " + Theme + " frontier hides. Scouts believe your best chance is " + Goal + "."
  GS\World(3)\MapExits[#DIR_WEST] = 0
  GS\World(3)\MapExits[#DIR_SOUTH] = 2

  GS\World(4)\Name = "Western Ruins"
  GS\World(4)\Description = "Broken stone and old fires suggest that " + Landmark + " has drawn desperate seekers here for years. Every carving hints that " + Twist + "."
  GS\World(4)\MapExits[#DIR_EAST] = 0
  GS\World(4)\MapExits[#DIR_NORTH] = 1
  GS\World(4)\IsDark = #True

  GS\CurrentRoomID = 0
  GS\PlayerHealth = 100
  GS\PlayerMana = 50
  GS\PlayerMaxHealth = 100
  GS\PlayerMaxMana = 50
  GS\PlayerAttack = 8
  GS\AdventureWon = #False
  GS\PlayerRole = Role
  GS\TorchLit = #False

  SeedStartingInventory(Role)
  SeedWorldDetails(Theme, Setting, Culture, Landmark)
EndProcedure

Procedure MovePlayer(Direction.i)
  Protected CurrentRoomID.i = GS\CurrentRoomID
  Protected NextRoomID.i

  If Not IsValidRoomID(CurrentRoomID)
    PrintN("The world state is invalid. Rebuild the adventure from the main menu.")
    Print("> ")
    ProcedureReturn
  EndIf

  If Direction < #DIR_NORTH Or Direction > #DIR_WEST
    PrintN("You hesitate, unsure where to go.")
    Print("> ")
    ProcedureReturn
  EndIf

  NextRoomID = GS\World(CurrentRoomID)\MapExits[Direction]
  If Not IsValidRoomID(NextRoomID)
    PrintN("You cannot go that way.")
    Print("> ")
    ProcedureReturn
  EndIf

  GS\CurrentRoomID = NextRoomID
  DescribeRoom()
EndProcedure
