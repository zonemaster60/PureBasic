; AdventureGen: The Arcane Edition (Standalone Build System)
; ==========================================================
; PureBasic v6.30 (x64) - Supports dynamic story generation and EXE export

EnableExplicit
XIncludeFile "current_config.pbi"

; --- Constants & Enums ---
#APP_NAME = "AdventureGen"
#MAX_ROOMS = 20
#DIR_NORTH = 0 : #DIR_SOUTH = 1 : #DIR_EAST = 2 : #DIR_WEST = 3
#BUILD_OUTPUT_FILE = "GeneratedAdventure.exe"

; --- Structures ---
Structure Item
  Name.s : Description.s : Type.s : Value.i : IsTakeable.b
EndStructure

Structure Entity
  Name.s : Description.s : Health.i : MaxHealth.i : Damage.i : IsHostile.b
EndStructure

Structure Room
  Name.s : Description.s : MapExits.i[4]
  List Items.Item() : List Entities.Entity()
  IsDark.b
EndStructure

Structure ThemeSet
  Name.s
  List Settings.s() : List Cultures.s() : List Landmarks.s() : List Roles.s() : List Goals.s() : List Twists.s()
EndStructure

Structure GameState
  CurrentRoomID.i : PlayerHealth.i : PlayerMana.i : PlayerRole.s : TorchLit.b
  List Inventory.Item()
  Array World.Room(#MAX_ROOMS)
EndStructure

Structure MemoryFile
  *Address : Size.i : Offset.i
EndStructure

; --- Globals ---
Global GS.GameState
Global NewList Themes.ThemeSet()
Global CurrentTheme.s, CurrentSetting.s, CurrentCulture.s, CurrentLandmark.s
Global version.s = "v1.0.0.0"

Declare DescribeRoom()

; --- Memory-Based File Reader ---
Procedure.s Memory_ReadString(*MF.MemoryFile)
  If *MF\Offset >= *MF\Size : ProcedureReturn "" : EndIf
  Protected *Start = *MF\Address + *MF\Offset
  Protected Length.i = 0
  While *MF\Offset < *MF\Size
    Protected Byte.b = PeekB(*MF\Address + *MF\Offset)
    If Byte = 10 Or Byte = 13
      If Byte = 13 And *MF\Offset + 1 < *MF\Size And PeekB(*MF\Address + *MF\Offset + 1) = 10 : *MF\Offset + 2 : Else : *MF\Offset + 1 : EndIf
      Break
    EndIf
    *MF\Offset + 1 : Length + 1
  Wend
  If Length > 0 : ProcedureReturn PeekS(*Start, Length, #PB_UTF8) : EndIf
  ProcedureReturn ""
EndProcedure

Procedure.b Memory_Eof(*MF.MemoryFile)
  ProcedureReturn Bool(*MF\Offset >= *MF\Size)
EndProcedure

; --- Robust CSV Parser ---
Procedure.s GetCSVField(Line.s, Index.i)
  Protected i, Char.s, Result.s = "", InQuotes.b = #False, FieldCount = 1
  For i = 1 To Len(Line)
    Char = Mid(Line, i, 1)
    If Char = #DQUOTE$
      If InQuotes = #True : InQuotes = #False : Else : InQuotes = #True : EndIf
    ElseIf Char = "," And InQuotes = #False
      FieldCount + 1
      If FieldCount > Index : Break : EndIf
    ElseIf FieldCount = Index
      Result + Char
    EndIf
  Next
  ProcedureReturn Trim(Result)
EndProcedure

; --- Theme Loading ---
Procedure LoadThemes()
  Protected MF.MemoryFile
  ClearList(Themes())
  MF\Address = ?ThemesStart : MF\Size = ?ThemesEnd - ?ThemesStart : MF\Offset = 0
  If MF\Size = 0 : ProcedureReturn : EndIf
  Protected Row.i, Col.i, Line.s, Count.i
  Line = Memory_ReadString(@MF)
  If Trim(Line) = "" : ProcedureReturn : EndIf
  Count = CountString(Line, ",") + 1
  For Col = 1 To Count
    AddElement(Themes())
    Themes()\Name = GetCSVField(Line, Col)
  Next
  For Row = 2 To 7
    If Memory_Eof(@MF) : Break : EndIf
    Line = Memory_ReadString(@MF)
    For Col = 1 To Count
      If SelectElement(Themes(), Col - 1)
        Select Row
          Case 2 : AddElement(Themes()\Settings())  : Themes()\Settings()  = GetCSVField(Line, Col)
          Case 3 : AddElement(Themes()\Cultures())  : Themes()\Cultures()  = GetCSVField(Line, Col)
          Case 4 : AddElement(Themes()\Landmarks()) : Themes()\Landmarks() = GetCSVField(Line, Col)
          Case 5 : AddElement(Themes()\Roles())     : Themes()\Roles()     = GetCSVField(Line, Col)
          Case 6 : AddElement(Themes()\Goals())     : Themes()\Goals()     = GetCSVField(Line, Col)
          Case 7 : AddElement(Themes()\Twists())    : Themes()\Twists()    = GetCSVField(Line, Col)
        EndSelect
      EndIf
    Next
  Next
EndProcedure

; --- Helpers ---
Procedure ResetWorld()
  Protected i.i
  For i = 0 To #MAX_ROOMS
    GS\World(i)\Name = ""
    GS\World(i)\Description = ""
    ClearList(GS\World(i)\Items())
    ClearList(GS\World(i)\Entities())
    GS\World(i)\MapExits[#DIR_NORTH] = -1
    GS\World(i)\MapExits[#DIR_SOUTH] = -1
    GS\World(i)\MapExits[#DIR_EAST] = -1
    GS\World(i)\MapExits[#DIR_WEST] = -1
    GS\World(i)\IsDark = #False
  Next
EndProcedure

Procedure.s RandomListValue(List Values.s(), Fallback.s)
  Protected Count.i = ListSize(Values())
  If Count = 0
    ProcedureReturn Fallback
  EndIf
  SelectElement(Values(), Random(Count - 1))
  ProcedureReturn Values()
EndProcedure

Procedure.i PromptForChoice(Prompt.s, Minimum.i, Maximum.i)
  Protected ChoiceText.s, Choice.i
  Repeat
    Print(Prompt + " ")
    ChoiceText = Trim(Input())
    Choice = Val(ChoiceText)
    If Choice >= Minimum And Choice <= Maximum
      ProcedureReturn Choice
    EndIf
    PrintN("Please enter a number from " + Str(Minimum) + " to " + Str(Maximum) + ".")
  ForEver
EndProcedure

Procedure.i PromptForThemeChoice()
  Protected Count.i = ListSize(Themes())
  Protected Index.i
  If Count = 0
    ProcedureReturn -1
  EndIf

  PrintN("Choose a theme:")
  If FirstElement(Themes())
    Index = 1
    Repeat
      PrintN("[" + Str(Index) + "] " + Themes()\Name)
      Index + 1
    Until Not NextElement(Themes())
  EndIf

  ProcedureReturn PromptForChoice("Select theme (1-" + Str(Count) + "):", 1, Count) - 1
EndProcedure

Procedure.s JoinPath(Directory.s, Leaf.s)
  If Right(Directory, 1) = "\" Or Right(Directory, 1) = "/"
    ProcedureReturn Directory + Leaf
  EndIf
  ProcedureReturn Directory + "\" + Leaf
EndProcedure

Procedure.s PromptForListChoice(Title.s, List Values.s())
  Protected Count.i = ListSize(Values())
  Protected Index.i, Choice.i
  If Count = 0
    ProcedureReturn ""
  EndIf

  PrintN("")
  PrintN(Title)
  If FirstElement(Values())
    Index = 1
    Repeat
      PrintN("[" + Str(Index) + "] " + Values())
      Index + 1
    Until Not NextElement(Values())
  EndIf

  Choice = PromptForChoice("Select option (1-" + Str(Count) + "):", 1, Count)
  SelectElement(Values(), Choice - 1)
  ProcedureReturn Values()
EndProcedure

Procedure.s GetExitSummary(*R.Room)
  Protected Summary.s = ""
  If *R\MapExits[#DIR_NORTH] <> -1 And GS\World(*R\MapExits[#DIR_NORTH])\Name <> "" : Summary + "N" : EndIf
  If *R\MapExits[#DIR_SOUTH] <> -1 And GS\World(*R\MapExits[#DIR_SOUTH])\Name <> "" : If Summary <> "" : Summary + ", " : EndIf : Summary + "S" : EndIf
  If *R\MapExits[#DIR_EAST] <> -1 And GS\World(*R\MapExits[#DIR_EAST])\Name <> "" : If Summary <> "" : Summary + ", " : EndIf : Summary + "E" : EndIf
  If *R\MapExits[#DIR_WEST] <> -1 And GS\World(*R\MapExits[#DIR_WEST])\Name <> "" : If Summary <> "" : Summary + ", " : EndIf : Summary + "W" : EndIf
  If Summary = "" : Summary = "none" : EndIf
  ProcedureReturn Summary
EndProcedure

Procedure PrintGameHelp()
  PrintN("Commands: N, S, E, W, LOOK, INV, HELP, BUILD, EXIT")
EndProcedure

Procedure ShowStatus()
  PrintN("Role: " + GS\PlayerRole)
  PrintN("Theme: " + CurrentTheme + " | Setting: " + CurrentSetting)
  PrintN("Health: " + Str(GS\PlayerHealth) + " | Mana: " + Str(GS\PlayerMana))
  If ListSize(GS\Inventory()) = 0
    PrintN("Inventory: empty")
  Else
    PrintN("Inventory items: " + Str(ListSize(GS\Inventory())))
  EndIf
  Print("> ")
EndProcedure

Procedure MovePlayer(Direction.i)
  Protected NextRoomID.i = GS\World(GS\CurrentRoomID)\MapExits[Direction]
  If NextRoomID = -1 Or GS\World(NextRoomID)\Name = ""
    PrintN("You cannot go that way.")
    Print("> ")
    ProcedureReturn
  EndIf
  GS\CurrentRoomID = NextRoomID
  DescribeRoom()
EndProcedure

Procedure.s EscapePBString(Value.s)
  ProcedureReturn ReplaceString(Value, Chr(34), Chr(34) + Chr(34))
EndProcedure

Procedure.s ResolveSourceFile()
  Protected Candidate.s = JoinPath(GetCurrentDirectory(), "main.pb")
  If FileSize(Candidate) >= 0
    ProcedureReturn Candidate
  EndIf

  Candidate = JoinPath(GetCurrentDirectory(), "src\main.pb")
  If FileSize(Candidate) >= 0
    ProcedureReturn Candidate
  EndIf

  ProcedureReturn ""
EndProcedure

; --- World Construction ---
Procedure BuildWorld(Theme.s, Setting.s, Culture.s, Landmark.s, Role.s)
  CurrentTheme = Theme : CurrentSetting = Setting : CurrentCulture = Culture : CurrentLandmark = Landmark

  ResetWorld()

  GS\World(0)\Name = Landmark
  GS\World(0)\Description = "You arrive at " + Landmark + ", the heart of a " + Theme + " adventure shaped by " + Culture + "."
  GS\World(0)\MapExits[#DIR_NORTH] = 1
  GS\World(0)\MapExits[#DIR_SOUTH] = 2
  GS\World(0)\MapExits[#DIR_EAST] = 3
  GS\World(0)\MapExits[#DIR_WEST] = 4

  GS\World(1)\Name = "Northern Watch"
  GS\World(1)\Description = "A high overlook reveals the edges of " + Setting + " and the distant silhouette of " + Landmark + "."
  GS\World(1)\MapExits[#DIR_SOUTH] = 0
  GS\World(1)\MapExits[#DIR_EAST] = 3

  GS\World(2)\Name = "Southern Trail"
  GS\World(2)\Description = "Tracks in the dust hint that " + Culture + " travelers recently passed through this quieter route."
  GS\World(2)\MapExits[#DIR_NORTH] = 0
  GS\World(2)\MapExits[#DIR_WEST] = 4

  GS\World(3)\Name = "Eastern Outpost"
  GS\World(3)\Description = "Tools, maps, and rumors gather here as explorers plan for whatever the " + Theme + " frontier hides."
  GS\World(3)\MapExits[#DIR_WEST] = 0
  GS\World(3)\MapExits[#DIR_SOUTH] = 2

  GS\World(4)\Name = "Western Ruins"
  GS\World(4)\Description = "Broken stone and old fires suggest that " + Landmark + " has drawn desperate seekers here for years."
  GS\World(4)\MapExits[#DIR_EAST] = 0
  GS\World(4)\MapExits[#DIR_NORTH] = 1
  GS\World(4)\IsDark = #True

  GS\CurrentRoomID = 0
  GS\PlayerHealth = 100
  GS\PlayerMana = 50
  GS\PlayerRole = Role
  GS\TorchLit = #False
  ClearList(GS\Inventory())
EndProcedure

; --- Compiler Exporter ---
Procedure ExportStandalone()
  Protected SourceFile.s = ResolveSourceFile()
  Protected SourceDirectory.s, ConfigFile.s, OutputFile.s
  Protected FileID.i, Compiler.i, ExitCode.i

  If SourceFile = ""
    PrintN("ERROR: Could not locate main.pb for export.")
    Print("> ")
    ProcedureReturn
  EndIf

  SourceDirectory = GetPathPart(SourceFile)
  ConfigFile = JoinPath(SourceDirectory, "current_config.pbi")
  OutputFile = JoinPath(GetCurrentDirectory(), #BUILD_OUTPUT_FILE)

  PrintN("Preparing standalone build...")
  FileID = CreateFile(#PB_Any, ConfigFile)
  If FileID = 0
    PrintN("ERROR: Could not write " + ConfigFile + ".")
    Print("> ")
    ProcedureReturn
  EndIf

  WriteStringN(FileID, "Global ConstantTheme.s = " + Chr(34) + EscapePBString(CurrentTheme) + Chr(34))
  WriteStringN(FileID, "Global ConstantSetting.s = " + Chr(34) + EscapePBString(CurrentSetting) + Chr(34))
  WriteStringN(FileID, "Global ConstantCulture.s = " + Chr(34) + EscapePBString(CurrentCulture) + Chr(34))
  WriteStringN(FileID, "Global ConstantLandmark.s = " + Chr(34) + EscapePBString(CurrentLandmark) + Chr(34))
  WriteStringN(FileID, "Global ConstantRole.s = " + Chr(34) + EscapePBString(GS\PlayerRole) + Chr(34))
  CloseFile(FileID)

  PrintN("Invoking PureBasic Compiler...")
  Compiler = RunProgram("pbcompiler", Chr(34) + SourceFile + Chr(34) + " /EXE " + Chr(34) + OutputFile + Chr(34) + " /CONSOLE", SourceDirectory, #PB_Program_Open | #PB_Program_Read | #PB_Program_Error)
  If Compiler
    While ProgramRunning(Compiler)
      While AvailableProgramOutput(Compiler)
        PrintN(ReadProgramString(Compiler))
      Wend
      Delay(10)
    Wend

    While AvailableProgramOutput(Compiler)
      PrintN(ReadProgramString(Compiler))
    Wend

    ExitCode = ProgramExitCode(Compiler)
    CloseProgram(Compiler)

    If ExitCode = 0
      PrintN("SUCCESS: Standalone build created at " + OutputFile)
    Else
      PrintN("ERROR: Compiler exited with code " + Str(ExitCode) + ".")
    EndIf
  Else
    PrintN("ERROR: pbcompiler.exe not found in PATH.")
  EndIf

  Print("> ")
EndProcedure

Procedure DescribeRoom()
  Protected *R.Room = @GS\World(GS\CurrentRoomID)
  PrintN(#CRLF$ + "[" + UCase(*R\Name) + "]")
  If *R\IsDark And Not GS\TorchLit
    PrintN("Darkness surrounds the ruins. You can still feel the nearby exits.")
  Else
    PrintN(*R\Description)
  EndIf
  PrintN("Exits: " + GetExitSummary(*R))
  PrintN("Role: " + GS\PlayerRole + " | Health: " + Str(GS\PlayerHealth) + " | Mana: " + Str(GS\PlayerMana))
  Print("> ")
EndProcedure

Procedure GameLoop()
  Protected InputLine.s, Cmd.s
  ClearConsole()
  PrintGameHelp()
  DescribeRoom()
  Repeat
    InputLine = LCase(Trim(Input()))
    Cmd = StringField(InputLine, 1, " ")
    Select Cmd
      Case "n", "north" : MovePlayer(#DIR_NORTH)
      Case "s", "south" : MovePlayer(#DIR_SOUTH)
      Case "e", "east"  : MovePlayer(#DIR_EAST)
      Case "w", "west"  : MovePlayer(#DIR_WEST)
      Case "look", "l"  : DescribeRoom()
      Case "inv", "status" : ShowStatus()
      Case "help", "?" : PrintGameHelp() : Print("> ")
      Case "build" : ExportStandalone()
      Case "exit" : Break
      Case "" : Print("> ")
      Default : PrintN("Unknown command.") : Print("> ")
    EndSelect
  Until Cmd = "exit"
EndProcedure

Procedure Main()
  Define Choice.s
  Define ThemeIndex.i
  Define SelectedSetting.s, SelectedCulture.s, SelectedLandmark.s, SelectedRole.s

  OpenConsole(#APP_NAME + " Build System")
  RandomSeed(ElapsedMilliseconds())
  LoadThemes()

  If ConstantTheme <> ""
    BuildWorld(ConstantTheme, ConstantSetting, ConstantCulture, ConstantLandmark, ConstantRole)
    GameLoop()
    CloseConsole()
    ProcedureReturn
  EndIf

  Repeat
    ClearConsole()
    PrintN(#APP_NAME + " " + version + " [Standalone Creator]")
    PrintN("")
    PrintN("[R]andom Adventure")
    PrintN("[A]dventure Wizard")
    PrintN("[H]elp")
    PrintN("[E]xit")
    Choice = UCase(Input())
    Select Choice
      Case "H"
        ClearConsole()
        Protected MF.MemoryFile
        MF\Address = ?HelpStart : MF\Size = ?HelpEnd - ?HelpStart : MF\Offset = 0
        While Not Memory_Eof(@MF)
          PrintN(Memory_ReadString(@MF))
        Wend
        Input()
      Case "R"
        If ListSize(Themes()) > 0
          SelectElement(Themes(), Random(ListSize(Themes()) - 1))
          BuildWorld(Themes()\Name, RandomListValue(Themes()\Settings(), "Unknown Frontier"), RandomListValue(Themes()\Cultures(), "Unknown Culture"), RandomListValue(Themes()\Landmarks(), "Unknown Landmark"), RandomListValue(Themes()\Roles(), "Wanderer"))
          GameLoop()
        Else
          PrintN("No themes were loaded.")
          Input()
        EndIf
      Case "A"
        If ListSize(Themes()) > 0
          ClearConsole()
          ThemeIndex = PromptForThemeChoice()
          If ThemeIndex >= 0 And SelectElement(Themes(), ThemeIndex)
            SelectedSetting = PromptForListChoice("Choose a setting:", Themes()\Settings())
            SelectedCulture = PromptForListChoice("Choose a culture:", Themes()\Cultures())
            SelectedLandmark = PromptForListChoice("Choose a landmark:", Themes()\Landmarks())
            SelectedRole = PromptForListChoice("Choose a role:", Themes()\Roles())

            If SelectedSetting <> "" And SelectedCulture <> "" And SelectedLandmark <> "" And SelectedRole <> ""
              BuildWorld(Themes()\Name, SelectedSetting, SelectedCulture, SelectedLandmark, SelectedRole)
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

Main()

DataSection
  ThemesStart: : IncludeBinary "data/themes.csv" : ThemesEnd:
  HelpStart: : IncludeBinary "HELP.md" : HelpEnd:
EndDataSection

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 420
; FirstLine = 403
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = main.ico
; Executable = ..\AdventureGen.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = AdventureGen
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = An automated text adventure creator with themes
; VersionField7 = AdventureGen
; VersionField8 = AdventureGen.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60