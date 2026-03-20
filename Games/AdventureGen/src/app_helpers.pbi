Procedure.b IsBuilderMode()
  ProcedureReturn Bool(LCase(GetFilePart(ProgramFilename())) <> LCase(#BUILD_OUTPUT_FILE))
EndProcedure

Procedure.s GetGeneratedBaseName()
  Protected Name.s = GetFilePart(#BUILD_OUTPUT_FILE)
  Protected Extension.s = GetExtensionPart(Name)

  If Extension <> ""
    Name = Left(Name, Len(Name) - Len(Extension) - 1)
  EndIf

  ProcedureReturn Name
EndProcedure

Procedure.s GetGeneratedProductName()
  ProcedureReturn ReplaceString(GetGeneratedBaseName(), "_", " ")
EndProcedure

Procedure.s GetConsoleTitle()
  If IsBuilderMode()
    ProcedureReturn #APP_NAME + " - " + version + " Build System"
  EndIf

  ProcedureReturn GetGeneratedProductName()
EndProcedure

Procedure.s JoinPath(Directory.s, Leaf.s)
  If Right(Directory, 1) = "\" Or Right(Directory, 1) = "/"
    ProcedureReturn Directory + Leaf
  EndIf

  ProcedureReturn Directory + "\" + Leaf
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

Procedure.b IsValidRoomID(RoomID.i)
  If RoomID < 0 Or RoomID > #WORLD_ROOM_LAST_INDEX
    ProcedureReturn #False
  EndIf

  ProcedureReturn Bool(GS\World(RoomID)\Name <> "")
EndProcedure

Procedure.s Memory_ReadString(*MF.MemoryFile)
  Protected *Start
  Protected Length.i
  Protected Byte.b

  If *MF\Offset >= *MF\Size
    ProcedureReturn ""
  EndIf

  *Start = *MF\Address + *MF\Offset
  While *MF\Offset < *MF\Size
    Byte = PeekB(*MF\Address + *MF\Offset)
    If Byte = 10 Or Byte = 13
      If Byte = 13 And *MF\Offset + 1 < *MF\Size And PeekB(*MF\Address + *MF\Offset + 1) = 10
        *MF\Offset + 2
      Else
        *MF\Offset + 1
      EndIf
      Break
    EndIf

    *MF\Offset + 1
    Length + 1
  Wend

  If Length > 0
    ProcedureReturn PeekS(*Start, Length, #PB_UTF8)
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.b Memory_Eof(*MF.MemoryFile)
  ProcedureReturn Bool(*MF\Offset >= *MF\Size)
EndProcedure

Procedure ParseCSVLine(Line.s, List Fields.s())
  Protected Index.i = 1
  Protected Length.i = Len(Line)
  Protected InQuotes.b = #False
  Protected Field.s = ""
  Protected CurrentChar.s
  Protected NextChar.s

  ClearList(Fields())

  While Index <= Length
    CurrentChar = Mid(Line, Index, 1)

    If Index < Length
      NextChar = Mid(Line, Index + 1, 1)
    Else
      NextChar = ""
    EndIf

    If CurrentChar = #DQUOTE$
      If InQuotes And NextChar = #DQUOTE$
        Field + #DQUOTE$
        Index + 1
      Else
        InQuotes ! #True
      EndIf
    ElseIf CurrentChar = "," And Not InQuotes
      AddElement(Fields())
      Fields() = Trim(Field)
      Field = ""
    Else
      Field + CurrentChar
    EndIf

    Index + 1
  Wend

  AddElement(Fields())
  Fields() = Trim(Field)
EndProcedure

Procedure.s CSVFieldByIndex(List Fields.s(), Index.i)
  If SelectElement(Fields(), Index)
    ProcedureReturn Fields()
  EndIf

  ProcedureReturn ""
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
  Protected ChoiceText.s
  Protected Choice.i

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

Procedure.s PromptForListChoice(Title.s, List Values.s())
  Protected Count.i = ListSize(Values())
  Protected Index.i
  Protected Choice.i

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
