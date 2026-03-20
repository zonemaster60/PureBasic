Procedure PrintGameHelp()
  If IsBuilderMode()
    PrintN("Commands: N, S, E, W, LOOK, INV, TAKE, USE, EXAMINE, ATTACK, HELP, BUILD, EXIT")
  Else
    PrintN("Commands: N, S, E, W, LOOK, INV, TAKE, USE, EXAMINE, ATTACK, HELP, EXIT")
  EndIf
EndProcedure

Procedure ShowStatus()
  PrintN("Role: " + GS\PlayerRole)
  PrintN("Theme: " + CurrentTheme + " | Setting: " + CurrentSetting)
  PrintN("Goal: " + CurrentGoal)
  PrintN("Twist: " + CurrentTwist)
  If GS\AdventureWon
    PrintN("Objective: complete")
  ElseIf PlayerHasItem(CurrentLandmark + " sigil")
    PrintN("Objective: return to " + CurrentLandmark + " and use the sigil")
  Else
    PrintN("Objective: defeat the guardian and recover the sigil")
  EndIf
  PrintN("Health: " + Str(GS\PlayerHealth) + "/" + Str(GS\PlayerMaxHealth) + " | Mana: " + Str(GS\PlayerMana) + "/" + Str(GS\PlayerMaxMana))
  PrintN("Attack: " + Str(CalculatePlayerAttack()))
  PrintInventoryDetails()
  Print("> ")
EndProcedure

Procedure DescribeRoom()
  Protected RoomID.i = GS\CurrentRoomID
  Protected ItemSummary.s
  Protected EntitySummary.s

  If Not IsValidRoomID(RoomID)
    PrintN(#CRLF$ + "[UNKNOWN LOCATION]")
    PrintN("The adventure data is incomplete.")
    Print("> ")
    ProcedureReturn
  EndIf

  PrintN(#CRLF$ + "[" + UCase(GS\World(RoomID)\Name) + "]")
  If GS\World(RoomID)\IsDark And Not GS\TorchLit
    PrintN("Darkness surrounds the ruins. You can still feel the nearby exits.")
  Else
    PrintN(GS\World(RoomID)\Description)

    ItemSummary = GetRoomItemSummary(RoomID)
    If ItemSummary <> ""
      PrintN("Items: " + ItemSummary)
    EndIf

    EntitySummary = GetLivingEntitySummary(RoomID)
    If EntitySummary <> ""
      PrintN("Presence: " + EntitySummary)
    EndIf
  EndIf

  PrintN("Exits: " + GetExitSummary(RoomID))
  PrintN("Role: " + GS\PlayerRole + " | Health: " + Str(GS\PlayerHealth) + "/" + Str(GS\PlayerMaxHealth) + " | Mana: " + Str(GS\PlayerMana) + "/" + Str(GS\PlayerMaxMana))
  Print("> ")
EndProcedure

Procedure ShowHelpScreen()
  Protected MF.MemoryFile

  ClearConsole()
  MF\Address = ?HelpStart
  MF\Size = ?HelpEnd - ?HelpStart
  MF\Offset = 0

  While Not Memory_Eof(@MF)
    PrintN(Memory_ReadString(@MF))
  Wend

  Input()
EndProcedure

Procedure GameLoop()
  Protected InputLine.s
  Protected Cmd.s
  Protected Arg.s

  ClearConsole()
  PrintGameHelp()
  DescribeRoom()

  Repeat
    InputLine = LCase(Trim(Input()))
    Cmd = StringField(InputLine, 1, " ")
    Arg = Trim(Mid(InputLine, Len(Cmd) + 1))

    Select Cmd
      Case "n", "north"
        MovePlayer(#DIR_NORTH)
      Case "s", "south"
        MovePlayer(#DIR_SOUTH)
      Case "e", "east"
        MovePlayer(#DIR_EAST)
      Case "w", "west"
        MovePlayer(#DIR_WEST)
      Case "look", "l"
        DescribeRoom()
      Case "inv", "status"
        ShowStatus()
      Case "take", "get"
        TakeItem(Arg)
      Case "use"
        UseItem(Arg)
      Case "examine", "x"
        ExamineTarget(Arg)
      Case "attack", "fight"
        AttackTarget(Arg)
      Case "help", "?"
        PrintGameHelp()
        Print("> ")
      Case "build"
        If IsBuilderMode()
          ExportStandalone()
        Else
          PrintN("Unknown command.")
          Print("> ")
        EndIf
      Case "exit"
        Break
      Case ""
        Print("> ")
      Default
        PrintN("Unknown command.")
        Print("> ")
    EndSelect

    If GS\PlayerHealth <= 0
      Input()
      Break
    EndIf

    If GS\AdventureWon
      PrintN("Victory! Press Enter to return to the main menu.")
      Input()
      Break
    EndIf
  Until Cmd = "exit"
EndProcedure

Procedure Main()
  Protected Choice.s
  Protected ThemeIndex.i
  Protected SelectedSetting.s
  Protected SelectedCulture.s
  Protected SelectedLandmark.s
  Protected SelectedRole.s
  Protected SelectedGoal.s
  Protected SelectedTwist.s

  OpenConsole(GetConsoleTitle())
  RandomSeed(ElapsedMilliseconds())
  LoadThemes()

  If Not IsBuilderMode() And ConstantTheme <> ""
    BuildWorld(ConstantTheme, ConstantSetting, ConstantCulture, ConstantLandmark, ConstantRole, ConstantGoal, ConstantTwist)
    GameLoop()
    CloseConsole()
    ProcedureReturn
  EndIf

  Repeat
    ClearConsole()
    PrintN(#APP_NAME + " " + version + " [Standalone Creator]")
    PrintN("")
    PrintN("[R]andom Adventure")
    PrintN("[W]izard")
    PrintN("[H]elp")
    PrintN("[E]xit")
    Choice = UCase(Input())

    Select Choice
      Case "H"
        ShowHelpScreen()
      Case "R"
        If ListSize(Themes()) > 0
          SelectElement(Themes(), Random(ListSize(Themes()) - 1))
          BuildWorld(Themes()\Name,
                     RandomListValue(Themes()\Settings(), "Unknown Frontier"),
                     RandomListValue(Themes()\Cultures(), "Unknown Culture"),
                     RandomListValue(Themes()\Landmarks(), "Unknown Landmark"),
                     RandomListValue(Themes()\Roles(), "Wanderer"),
                     RandomListValue(Themes()\Goals(), "survive the unknown"),
                     RandomListValue(Themes()\Twists(), "someone is hiding the truth"))
          GameLoop()
        Else
          PrintN("No themes were loaded.")
          Input()
        EndIf
      Case "W", "A"
        If ListSize(Themes()) > 0
          ClearConsole()
          ThemeIndex = PromptForThemeChoice()
          If ThemeIndex >= 0 And SelectElement(Themes(), ThemeIndex)
            SelectedSetting = PromptForListChoice("Choose a setting:", Themes()\Settings())
            SelectedCulture = PromptForListChoice("Choose a culture:", Themes()\Cultures())
            SelectedLandmark = PromptForListChoice("Choose a landmark:", Themes()\Landmarks())
            SelectedRole = PromptForListChoice("Choose a role:", Themes()\Roles())
            SelectedGoal = PromptForListChoice("Choose a goal:", Themes()\Goals())
            SelectedTwist = PromptForListChoice("Choose a twist:", Themes()\Twists())

            If SelectedSetting <> "" And SelectedCulture <> "" And SelectedLandmark <> "" And SelectedRole <> "" And SelectedGoal <> "" And SelectedTwist <> ""
              BuildWorld(Themes()\Name, SelectedSetting, SelectedCulture, SelectedLandmark, SelectedRole, SelectedGoal, SelectedTwist)
              GameLoop()
            EndIf
          EndIf
        Else
          PrintN("No themes were loaded.")
          Input()
        EndIf
    EndSelect
  Until Choice = "E"

  CloseConsole()
EndProcedure
