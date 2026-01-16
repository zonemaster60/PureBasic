;------------------------------------------------------------------------------
; Editor procedures (extracted from pbzt.pb)
;------------------------------------------------------------------------------

; StartEditor
Procedure StartEditor()
  EditMode = #True
  CursorX = PlayerX
  CursorY = PlayerY
  If BrushList = ""
  BrushList = " .#~+$1234EABCFDdLo^*@PtThw="
    BrushIndex = 2
 
    BrushChar = Asc(Mid(BrushList, BrushIndex + 1, 1))
    BrushColor = Palette(BrushChar)
  EndIf
  SetStatus("Editor mode.")
EndProcedure

; StopEditor
Procedure StopEditor()
  EditMode = #False
  SetStatus("Play mode.")
EndProcedure

; CycleBrush
Procedure CycleBrush()
  BrushIndex + 1
  If BrushIndex >= Len(BrushList)
    BrushIndex = 0
  EndIf
  BrushChar = Asc(Mid(BrushList, BrushIndex + 1, 1))
  BrushColor = Palette(BrushChar)
EndProcedure

; PaintAtCursor
Procedure PaintAtCursor()
  Protected b.i = CurBoard()

  If BrushChar = Asc("@")
    PlayerX = CursorX
    PlayerY = CursorY
    If b >= 0 And b < BoardCount
      Boards(b)\StartX = PlayerX
      Boards(b)\StartY = PlayerY
    EndIf
  Else
    If BrushChar = Asc("E")
      ; Place an enemy object without altering the underlying map tile.
      If b >= 0 And b < BoardCount
        AddEnemy(b, CursorX, CursorY)
      EndIf
    ElseIf BrushChar = Asc("w")
      ; Place a water object without altering the underlying map tile.
      If b >= 0 And b < BoardCount
        AddWater(b, CursorX, CursorY)
      EndIf
    ElseIf BrushChar = Asc("=")
      ; Place a bridge object without altering the underlying map tile.
      If b >= 0 And b < BoardCount
        AddBridge(b, CursorX, CursorY)
      EndIf
    Else
      SetCell(CursorX, CursorY, BrushChar)
      SetCellColor(CursorX, CursorY, BrushColor)
    EndIf
  EndIf
EndProcedure

; EditorPrevBoard
Procedure EditorPrevBoard()
  If BoardCount <= 0 : ProcedureReturn : EndIf
  SwitchBoard((CurBoard() - 1 + BoardCount) % BoardCount, "")
  CursorX = PlayerX
  CursorY = PlayerY
EndProcedure

; EditorNextBoard
Procedure EditorNextBoard()
  If BoardCount <= 0 : ProcedureReturn : EndIf
  SwitchBoard((CurBoard() + 1) % BoardCount, "")
  CursorX = PlayerX
  CursorY = PlayerY
EndProcedure

; EditorNewBoard
Procedure EditorNewBoard()
  Protected newIdx.i

  newIdx = BoardCount
  EnsureWorldBoards(BoardCount + 1)
  InitBlankBoard(newIdx)
  Boards(newIdx)\Name = "Board " + Str(newIdx)

  SwitchBoard(newIdx, "")
  CursorX = PlayerX
  CursorY = PlayerY
  SetStatus("Added board " + Str(newIdx) + ".")
EndProcedure
