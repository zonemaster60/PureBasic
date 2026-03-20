Procedure LoadThemes()
  Protected MF.MemoryFile
  Protected Row.i
  Protected Col.i
  Protected Count.i
  Protected Line.s
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

  For Row = 2 To 7
    If Memory_Eof(@MF)
      Break
    EndIf

    Line = Memory_ReadString(@MF)
    ParseCSVLine(Line, Fields())

    For Col = 0 To Count - 1
      If SelectElement(Themes(), Col)
        Select Row
          Case 2
            AddElement(Themes()\Settings())
            Themes()\Settings() = CSVFieldByIndex(Fields(), Col)
          Case 3
            AddElement(Themes()\Cultures())
            Themes()\Cultures() = CSVFieldByIndex(Fields(), Col)
          Case 4
            AddElement(Themes()\Landmarks())
            Themes()\Landmarks() = CSVFieldByIndex(Fields(), Col)
          Case 5
            AddElement(Themes()\Roles())
            Themes()\Roles() = CSVFieldByIndex(Fields(), Col)
          Case 6
            AddElement(Themes()\Goals())
            Themes()\Goals() = CSVFieldByIndex(Fields(), Col)
          Case 7
            AddElement(Themes()\Twists())
            Themes()\Twists() = CSVFieldByIndex(Fields(), Col)
        EndSelect
      EndIf
    Next
  Next
EndProcedure
