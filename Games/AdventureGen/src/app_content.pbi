Procedure LoadThemes()
  Protected MF.MemoryFile
  Protected Row.i = 2
  Protected Col.i
  Protected Count.i
  Protected Line.s
  Protected Value.s
  Protected NewList Fields.s()

  ClearList(Themes())
  MF\Address = ?ThemesStart
  MF\Size = ?ThemesEnd - ?ThemesStart
  MF\Offset = 0

  If MF\Size = 0
    ProcedureReturn
  EndIf

  Repeat
    If Memory_Eof(@MF)
      ProcedureReturn
    EndIf
    Line = Memory_ReadString(@MF)
  Until Trim(Line) <> ""

  ParseCSVLine(Line, Fields())
  Count = ListSize(Fields())
  If Count = 0
    ProcedureReturn
  EndIf

  For Col = 0 To Count - 1
    AddElement(Themes())
    Themes()\Name = CSVFieldByIndex(Fields(), Col)
  Next

  While Row <= 7 And Not Memory_Eof(@MF)
    Line = Memory_ReadString(@MF)
    If Trim(Line) <> ""
      ParseCSVLine(Line, Fields())

      For Col = 0 To Count - 1
        If SelectElement(Themes(), Col)
          Value = CSVFieldByIndex(Fields(), Col)
          If Value <> ""
            Select Row
              Case 2
                AddElement(Themes()\Settings())
                Themes()\Settings() = Value
              Case 3
                AddElement(Themes()\Cultures())
                Themes()\Cultures() = Value
              Case 4
                AddElement(Themes()\Landmarks())
                Themes()\Landmarks() = Value
              Case 5
                AddElement(Themes()\Roles())
                Themes()\Roles() = Value
              Case 6
                AddElement(Themes()\Goals())
                Themes()\Goals() = Value
              Case 7
                AddElement(Themes()\Twists())
                Themes()\Twists() = Value
            EndSelect
          EndIf
        EndIf
      Next

      Row + 1
    EndIf
  Wend
EndProcedure
