; PureBasic 6.40 x64 - Ogre 3D Chess
; Player 1 is white. Player 2 is a simple AI controlling black.
; Controls: Arrow keys move cursor, Enter/Space selects or moves, Backspace cancels, N restarts, Esc quits.

EnableExplicit

Global version.s = "v1.0.0.0"
#APP_NAME = "PB_3DChess"

#BoardSize = 8
#TileSize = 2.0
#PieceBaseEntity = 100
#SquareBaseEntity = 300
#CursorEntity = 500
#SelectedEntity = 501
#MaxAIMoves = 256
#MaxMoveHistory = 256

Enumeration 1
  #Pawn
  #Knight
  #Bishop
  #Rook
  #Queen
  #King
EndEnumeration

Enumeration
  #MeshTile
  #MeshPawn
  #MeshKnight
  #MeshBishop
  #MeshRook
  #MeshQueen
  #MeshKing
EndEnumeration

Enumeration
  #MatLightSquare
  #MatDarkSquare
  #MatCursorSquare
  #MatSelectedSquare
  #MatWhitePiece
  #MatBlackPiece
EndEnumeration

Enumeration
  #Camera
  #Light
EndEnumeration

Structure Move
  fx.i
  fy.i
  tx.i
  ty.i
  score.i
EndStructure

Global Dim Board.i(7, 7)
Global Dim PieceEntity.i(7, 7)
Global Dim HasMoved.i(7, 7)
Global Dim AIMove.Move(#MaxAIMoves - 1)
Global Dim WhiteMove.s(#MaxMoveHistory - 1)
Global Dim BlackMove.s(#MaxMoveHistory - 1)

Global CursorX.i = 4
Global CursorY.i = 1
Global SelectedX.i = -1
Global SelectedY.i = -1
Global Turn.i = 1
Global GameOver.i = #False
Global QuitRequested.i = #False
Global StatusText.s = "Whites move"
Global InputCooldown.i = 0
Global EnPassantX.i = -1
Global EnPassantY.i = -1
Global MoveCount.i = 0
Global MouseBoardX.i = -1
Global MouseBoardY.i = -1

Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Procedure Shutdown()
  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
  End
EndProcedure

Procedure ExitApp()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    Shutdown()
  EndIf
EndProcedure

Procedure.i InBounds(x.i, y.i)
  If x >= 0 And x < #BoardSize And y >= 0 And y < #BoardSize
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.i PieceColor(piece.i)
  If piece > 0
    ProcedureReturn 1
  ElseIf piece < 0
    ProcedureReturn -1
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure.i PieceType(piece.i)
  If piece < 0
    ProcedureReturn -piece
  EndIf
  ProcedureReturn piece
EndProcedure

Procedure.s PieceName(piece.i)
  Protected name.s

  Select PieceType(piece)
    Case #Pawn
      name = "Pawn"
    Case #Knight
      name = "Knight"
    Case #Bishop
      name = "Bishop"
    Case #Rook
      name = "Rook"
    Case #Queen
      name = "Queen"
    Case #King
      name = "King"
    Default
      ProcedureReturn ""
  EndSelect

  If piece > 0
    ProcedureReturn "White " + name
  ElseIf piece < 0
    ProcedureReturn "Black " + name
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure.s SquareName(x.i, y.i)
  ProcedureReturn Chr(Asc("a") + x) + Str(y + 1)
EndProcedure

Procedure.s MoveNotation(fx.i, fy.i, tx.i, ty.i)
  Protected piece.i = Board(fx, fy)
  Protected capture.i = Board(tx, ty)
  Protected separator.s = "-"

  If PieceType(piece) = #King And Abs(tx - fx) = 2
    If tx > fx
      ProcedureReturn "O-O"
    EndIf
    ProcedureReturn "O-O-O"
  EndIf

  If capture <> 0 Or (PieceType(piece) = #Pawn And tx = EnPassantX And ty = EnPassantY And fx <> tx)
    separator = "x"
  EndIf

  ProcedureReturn SquareName(fx, fy) + separator + SquareName(tx, ty)
EndProcedure

Procedure RecordMove(color.i, notation.s)
  Protected i.i

  If color = 1
    If MoveCount >= #MaxMoveHistory
      For i = 1 To #MaxMoveHistory - 1
        WhiteMove(i - 1) = WhiteMove(i)
        BlackMove(i - 1) = BlackMove(i)
      Next
      MoveCount = #MaxMoveHistory - 1
    EndIf
    WhiteMove(MoveCount) = notation
    BlackMove(MoveCount) = ""
    MoveCount + 1
  ElseIf MoveCount > 0
    BlackMove(MoveCount - 1) = notation
  EndIf
EndProcedure

Procedure.i EntityForPiece(x.i, y.i)
  ProcedureReturn #PieceBaseEntity + y * 8 + x
EndProcedure

Procedure.i EntityForSquare(x.i, y.i)
  ProcedureReturn #SquareBaseEntity + y * 8 + x
EndProcedure

Procedure.i BoardXFromEntity(entity.i)
  If entity >= #PieceBaseEntity And entity < #PieceBaseEntity + 64
    ProcedureReturn (entity - #PieceBaseEntity) % 8
  EndIf
  If entity >= #SquareBaseEntity And entity < #SquareBaseEntity + 64
    ProcedureReturn (entity - #SquareBaseEntity) % 8
  EndIf
  ProcedureReturn -1
EndProcedure

Procedure.i BoardYFromEntity(entity.i)
  If entity >= #PieceBaseEntity And entity < #PieceBaseEntity + 64
    ProcedureReturn (entity - #PieceBaseEntity) / 8
  EndIf
  If entity >= #SquareBaseEntity And entity < #SquareBaseEntity + 64
    ProcedureReturn (entity - #SquareBaseEntity) / 8
  EndIf
  ProcedureReturn -1
EndProcedure

Procedure.f BoardX(x.i)
  ProcedureReturn (x - 3.5) * #TileSize
EndProcedure

Procedure.f BoardZ(y.i)
  ProcedureReturn (y - 3.5) * #TileSize
EndProcedure

Procedure.i Direction(delta.i)
  If delta > 0
    ProcedureReturn 1
  ElseIf delta < 0
    ProcedureReturn -1
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure CreateSolidMaterial(material.i, color.i)
  CreateMaterial(material, 0)
  SetMaterialColor(material, #PB_Material_DiffuseColor, color)
  SetMaterialColor(material, #PB_Material_AmbientColor, color)
EndProcedure

Procedure CreateSceneResources()
  CreateSolidMaterial(#MatLightSquare, RGB(224, 205, 170))
  CreateSolidMaterial(#MatDarkSquare, RGB(114, 80, 48))
  CreateSolidMaterial(#MatCursorSquare, RGB(90, 145, 230))
  CreateSolidMaterial(#MatSelectedSquare, RGB(240, 210, 65))
  CreateSolidMaterial(#MatWhitePiece, RGB(238, 238, 225))
  CreateSolidMaterial(#MatBlackPiece, RGB(28, 30, 34))

  CreateCube(#MeshTile, 1.0)
  CreateCylinder(#MeshPawn, 0.48, 1.05)
  CreateSphere(#MeshKnight, 0.58)
  CreateCylinder(#MeshBishop, 0.43, 1.35)
  CreateCube(#MeshRook, 0.95)
  CreateSphere(#MeshQueen, 0.72)
  CreateCylinder(#MeshKing, 0.52, 1.55)
EndProcedure

Procedure.i MeshForPiece(piece.i)
  Select PieceType(piece)
    Case #Pawn
      ProcedureReturn #MeshPawn
    Case #Knight
      ProcedureReturn #MeshKnight
    Case #Bishop
      ProcedureReturn #MeshBishop
    Case #Rook
      ProcedureReturn #MeshRook
    Case #Queen
      ProcedureReturn #MeshQueen
    Case #King
      ProcedureReturn #MeshKing
  EndSelect
  ProcedureReturn #MeshPawn
EndProcedure

Procedure RefreshSquare(x.i, y.i)
  Protected mat.i = #MatLightSquare
  If (x + y) & 1
    mat = #MatDarkSquare
  EndIf
  If SelectedX = x And SelectedY = y
    mat = #MatSelectedSquare
  ElseIf CursorX = x And CursorY = y
    mat = #MatCursorSquare
  EndIf
  SetEntityMaterial(EntityForSquare(x, y), MaterialID(mat))
EndProcedure

Procedure RefreshSquares()
  Protected x.i, y.i
  For y = 0 To 7
    For x = 0 To 7
      RefreshSquare(x, y)
    Next
  Next
  MoveEntity(#CursorEntity, BoardX(CursorX), 0.035, BoardZ(CursorY), #PB_Absolute)
  If SelectedX >= 0 And SelectedY >= 0
    HideEntity(#SelectedEntity, #False)
    MoveEntity(#SelectedEntity, BoardX(SelectedX), 0.055, BoardZ(SelectedY), #PB_Absolute)
  Else
    HideEntity(#SelectedEntity, #True)
  EndIf
EndProcedure

Procedure CreateBoardEntities()
  Protected x.i, y.i, ent.i, mat.i
  For y = 0 To 7
    For x = 0 To 7
      ent = EntityForSquare(x, y)
      If (x + y) & 1
        mat = #MatDarkSquare
      Else
        mat = #MatLightSquare
      EndIf
      CreateEntity(ent, MeshID(#MeshTile), MaterialID(mat), BoardX(x), -0.09, BoardZ(y))
      ScaleEntity(ent, #TileSize * 0.98, 0.12, #TileSize * 0.98)
    Next
  Next
  CreateEntity(#CursorEntity, MeshID(#MeshTile), MaterialID(#MatCursorSquare), BoardX(CursorX), 0.035, BoardZ(CursorY))
  ScaleEntity(#CursorEntity, #TileSize * 1.08, 0.035, #TileSize * 1.08)
  CreateEntity(#SelectedEntity, MeshID(#MeshTile), MaterialID(#MatSelectedSquare), 0, 0.055, 0)
  ScaleEntity(#SelectedEntity, #TileSize * 1.18, 0.03, #TileSize * 1.18)
  HideEntity(#SelectedEntity, #True)
EndProcedure

Procedure DeletePieceEntity(x.i, y.i)
  Protected ent.i = EntityForPiece(x, y)
  If IsEntity(ent)
    FreeEntity(ent)
  EndIf
  PieceEntity(x, y) = 0
EndProcedure

Procedure CreatePieceEntityAt(x.i, y.i)
  Protected piece.i = Board(x, y)
  Protected ent.i = EntityForPiece(x, y)
  Protected mat.i
  DeletePieceEntity(x, y)
  If piece = 0
    ProcedureReturn
  EndIf

  If piece > 0
    mat = #MatWhitePiece
  Else
    mat = #MatBlackPiece
  EndIf

  CreateEntity(ent, MeshID(MeshForPiece(piece)), MaterialID(mat), BoardX(x), 0.45, BoardZ(y))
  Select PieceType(piece)
    Case #Pawn
      ScaleEntity(ent, 0.85, 1.0, 0.85)
    Case #Knight
      ScaleEntity(ent, 0.8, 1.05, 0.55)
      RotateEntity(ent, 0, 25, 0)
    Case #Bishop
      ScaleEntity(ent, 0.85, 1.25, 0.85)
    Case #Rook
      ScaleEntity(ent, 0.78, 1.0, 0.78)
    Case #Queen
      ScaleEntity(ent, 0.88, 1.35, 0.88)
    Case #King
      ScaleEntity(ent, 0.88, 1.45, 0.88)
  EndSelect
  PieceEntity(x, y) = ent
EndProcedure

Procedure RefreshPieces()
  Protected x.i, y.i
  For y = 0 To 7
    For x = 0 To 7
      CreatePieceEntityAt(x, y)
    Next
  Next
EndProcedure

Procedure SetupBoard()
  Protected x.i, y.i
  For y = 0 To 7
    For x = 0 To 7
      Board(x, y) = 0
      HasMoved(x, y) = #False
      DeletePieceEntity(x, y)
    Next
  Next

  Board(0, 0) = #Rook : Board(1, 0) = #Knight : Board(2, 0) = #Bishop : Board(3, 0) = #Queen
  Board(4, 0) = #King : Board(5, 0) = #Bishop : Board(6, 0) = #Knight : Board(7, 0) = #Rook
  For x = 0 To 7
    Board(x, 1) = #Pawn
    Board(x, 6) = -#Pawn
  Next
  Board(0, 7) = -#Rook : Board(1, 7) = -#Knight : Board(2, 7) = -#Bishop : Board(3, 7) = -#Queen
  Board(4, 7) = -#King : Board(5, 7) = -#Bishop : Board(6, 7) = -#Knight : Board(7, 7) = -#Rook

  CursorX = 4
  CursorY = 1
  SelectedX = -1
  SelectedY = -1
  Turn = 1
  GameOver = #False
  EnPassantX = -1
  EnPassantY = -1
  MoveCount = 0
  For x = 0 To #MaxMoveHistory - 1
    WhiteMove(x) = ""
    BlackMove(x) = ""
  Next
  StatusText = "Whites move"
  RefreshPieces()
  RefreshSquares()
EndProcedure

Procedure.i PathClear(fx.i, fy.i, tx.i, ty.i)
  Protected dx.i = Direction(tx - fx)
  Protected dy.i = Direction(ty - fy)
  Protected x.i = fx + dx
  Protected y.i = fy + dy
  While x <> tx Or y <> ty
    If Board(x, y) <> 0
      ProcedureReturn #False
    EndIf
    x + dx
    y + dy
  Wend
  ProcedureReturn #True
EndProcedure

Procedure.i SquareAttackedBy(x.i, y.i, color.i)
  Protected sx.i, sy.i, piece.i, t.i, dx.i, dy.i
  For sy = 0 To 7
    For sx = 0 To 7
      piece = Board(sx, sy)
      If PieceColor(piece) = color
        t = PieceType(piece)
        dx = x - sx
        dy = y - sy
        Select t
          Case #Pawn
            If dy = color And Abs(dx) = 1
              ProcedureReturn #True
            EndIf
          Case #Knight
            If (Abs(dx) = 1 And Abs(dy) = 2) Or (Abs(dx) = 2 And Abs(dy) = 1)
              ProcedureReturn #True
            EndIf
          Case #Bishop
            If Abs(dx) = Abs(dy) And dx <> 0 And PathClear(sx, sy, x, y)
              ProcedureReturn #True
            EndIf
          Case #Rook
            If ((dx = 0 And dy <> 0) Or (dy = 0 And dx <> 0)) And PathClear(sx, sy, x, y)
              ProcedureReturn #True
            EndIf
          Case #Queen
            If (((Abs(dx) = Abs(dy)) And dx <> 0) Or (dx = 0 And dy <> 0) Or (dy = 0 And dx <> 0)) And PathClear(sx, sy, x, y)
              ProcedureReturn #True
            EndIf
          Case #King
            If Abs(dx) <= 1 And Abs(dy) <= 1 And (dx <> 0 Or dy <> 0)
              ProcedureReturn #True
            EndIf
        EndSelect
      EndIf
    Next
  Next
  ProcedureReturn #False
EndProcedure

Procedure.i KingInCheck(color.i)
  Protected x.i, y.i
  For y = 0 To 7
    For x = 0 To 7
      If Board(x, y) = color * #King
        ProcedureReturn SquareAttackedBy(x, y, -color)
      EndIf
    Next
  Next
  ProcedureReturn #True
EndProcedure

Procedure.i PseudoLegalMove(fx.i, fy.i, tx.i, ty.i)
  Protected piece.i, target.i, color.i, t.i, dx.i, dy.i, adx.i, ady.i, startRank.i
  If Not InBounds(fx, fy) Or Not InBounds(tx, ty)
    ProcedureReturn #False
  EndIf
  If fx = tx And fy = ty
    ProcedureReturn #False
  EndIf
  piece = Board(fx, fy)
  target = Board(tx, ty)
  color = PieceColor(piece)
  If color = 0 Or PieceColor(target) = color
    ProcedureReturn #False
  EndIf

  t = PieceType(piece)
  dx = tx - fx
  dy = ty - fy
  adx = Abs(dx)
  ady = Abs(dy)

  Select t
    Case #Pawn
      If color = 1
        startRank = 1
      Else
        startRank = 6
      EndIf
      If dx = 0 And dy = color And target = 0
        ProcedureReturn #True
      EndIf
      If dx = 0 And dy = color * 2 And fy = startRank And target = 0 And Board(fx, fy + color) = 0
        ProcedureReturn #True
      EndIf
      If adx = 1 And dy = color
        If target <> 0 And PieceColor(target) = -color
          ProcedureReturn #True
        EndIf
        If tx = EnPassantX And ty = EnPassantY
          ProcedureReturn #True
        EndIf
      EndIf
    Case #Knight
      If (adx = 1 And ady = 2) Or (adx = 2 And ady = 1)
        ProcedureReturn #True
      EndIf
    Case #Bishop
      If adx = ady And PathClear(fx, fy, tx, ty)
        ProcedureReturn #True
      EndIf
    Case #Rook
      If (dx = 0 Or dy = 0) And PathClear(fx, fy, tx, ty)
        ProcedureReturn #True
      EndIf
    Case #Queen
      If ((adx = ady) Or dx = 0 Or dy = 0) And PathClear(fx, fy, tx, ty)
        ProcedureReturn #True
      EndIf
    Case #King
      If adx <= 1 And ady <= 1
        ProcedureReturn #True
      EndIf
      If ady = 0 And adx = 2 And HasMoved(fx, fy) = #False And KingInCheck(color) = #False
        If dx = 2 And Board(7, fy) = color * #Rook And HasMoved(7, fy) = #False And Board(5, fy) = 0 And Board(6, fy) = 0
          If SquareAttackedBy(5, fy, -color) = #False And SquareAttackedBy(6, fy, -color) = #False
            ProcedureReturn #True
          EndIf
        ElseIf dx = -2 And Board(0, fy) = color * #Rook And HasMoved(0, fy) = #False And Board(1, fy) = 0 And Board(2, fy) = 0 And Board(3, fy) = 0
          If SquareAttackedBy(3, fy, -color) = #False And SquareAttackedBy(2, fy, -color) = #False
            ProcedureReturn #True
          EndIf
        EndIf
      EndIf
  EndSelect
  ProcedureReturn #False
EndProcedure

Procedure.i LegalMove(fx.i, fy.i, tx.i, ty.i)
  Protected moving.i, captured.i, oldEPX.i, oldEPY.i, oldMovedFrom.i, oldMovedTo.i
  Protected epCaptured.i = 0, epY.i = -1
  Protected rookFrom.i = -1, rookTo.i = -1, rookPiece.i = 0, rookMovedFrom.i, rookMovedTo.i
  Protected color.i

  If Not PseudoLegalMove(fx, fy, tx, ty)
    ProcedureReturn #False
  EndIf

  moving = Board(fx, fy)
  captured = Board(tx, ty)
  color = PieceColor(moving)
  oldEPX = EnPassantX
  oldEPY = EnPassantY
  oldMovedFrom = HasMoved(fx, fy)
  oldMovedTo = HasMoved(tx, ty)

  If PieceType(moving) = #Pawn And tx = EnPassantX And ty = EnPassantY And captured = 0 And fx <> tx
    epY = ty - color
    epCaptured = Board(tx, epY)
    Board(tx, epY) = 0
  EndIf

  If PieceType(moving) = #King And Abs(tx - fx) = 2
    If tx > fx
      rookFrom = 7
      rookTo = 5
    Else
      rookFrom = 0
      rookTo = 3
    EndIf
    rookPiece = Board(rookFrom, fy)
    rookMovedFrom = HasMoved(rookFrom, fy)
    rookMovedTo = HasMoved(rookTo, fy)
    Board(rookTo, fy) = rookPiece
    Board(rookFrom, fy) = 0
    HasMoved(rookTo, fy) = #True
    HasMoved(rookFrom, fy) = #False
  EndIf

  Board(tx, ty) = moving
  Board(fx, fy) = 0
  HasMoved(tx, ty) = #True
  HasMoved(fx, fy) = #False
  If PieceType(Board(tx, ty)) = #Pawn And (ty = 0 Or ty = 7)
    Board(tx, ty) = color * #Queen
  EndIf

  If KingInCheck(color)
    Board(fx, fy) = moving
    Board(tx, ty) = captured
    HasMoved(fx, fy) = oldMovedFrom
    HasMoved(tx, ty) = oldMovedTo
    EnPassantX = oldEPX
    EnPassantY = oldEPY
    If epY >= 0
      Board(tx, epY) = epCaptured
    EndIf
    If rookFrom >= 0
      Board(rookFrom, fy) = rookPiece
      Board(rookTo, fy) = 0
      HasMoved(rookFrom, fy) = rookMovedFrom
      HasMoved(rookTo, fy) = rookMovedTo
    EndIf
    ProcedureReturn #False
  EndIf

  Board(fx, fy) = moving
  Board(tx, ty) = captured
  HasMoved(fx, fy) = oldMovedFrom
  HasMoved(tx, ty) = oldMovedTo
  EnPassantX = oldEPX
  EnPassantY = oldEPY
  If epY >= 0
    Board(tx, epY) = epCaptured
  EndIf
  If rookFrom >= 0
    Board(rookFrom, fy) = rookPiece
    Board(rookTo, fy) = 0
    HasMoved(rookFrom, fy) = rookMovedFrom
    HasMoved(rookTo, fy) = rookMovedTo
  EndIf
  ProcedureReturn #True
EndProcedure

Procedure ApplyMoveNoRender(fx.i, fy.i, tx.i, ty.i)
  Protected moving.i = Board(fx, fy)
  Protected color.i = PieceColor(moving)
  Protected rookFrom.i, rookTo.i

  If PieceType(moving) = #Pawn And tx = EnPassantX And ty = EnPassantY And Board(tx, ty) = 0 And fx <> tx
    Board(tx, ty - color) = 0
  EndIf

  If PieceType(moving) = #King And Abs(tx - fx) = 2
    If tx > fx
      rookFrom = 7
      rookTo = 5
    Else
      rookFrom = 0
      rookTo = 3
    EndIf
    Board(rookTo, fy) = Board(rookFrom, fy)
    Board(rookFrom, fy) = 0
    HasMoved(rookTo, fy) = #True
    HasMoved(rookFrom, fy) = #False
  EndIf

  EnPassantX = -1
  EnPassantY = -1
  If PieceType(moving) = #Pawn And Abs(ty - fy) = 2
    EnPassantX = fx
    EnPassantY = fy + color
  EndIf

  Board(tx, ty) = moving
  Board(fx, fy) = 0
  HasMoved(tx, ty) = #True
  HasMoved(fx, fy) = #False

  If PieceType(Board(tx, ty)) = #Pawn And (ty = 0 Or ty = 7)
    Board(tx, ty) = color * #Queen
  EndIf
EndProcedure

Procedure MakeMove(fx.i, fy.i, tx.i, ty.i)
  ApplyMoveNoRender(fx, fy, tx, ty)
  RefreshPieces()
  RefreshSquares()
EndProcedure

Procedure.i HasAnyLegalMove(color.i)
  Protected fx.i, fy.i, tx.i, ty.i
  For fy = 0 To 7
    For fx = 0 To 7
      If PieceColor(Board(fx, fy)) = color
        For ty = 0 To 7
          For tx = 0 To 7
            If LegalMove(fx, fy, tx, ty)
              ProcedureReturn #True
            EndIf
          Next
        Next
      EndIf
    Next
  Next
  ProcedureReturn #False
EndProcedure

Procedure.i PieceValue(piece.i)
  Select PieceType(piece)
    Case #Pawn
      ProcedureReturn 100
    Case #Knight
      ProcedureReturn 320
    Case #Bishop
      ProcedureReturn 330
    Case #Rook
      ProcedureReturn 500
    Case #Queen
      ProcedureReturn 900
    Case #King
      ProcedureReturn 20000
  EndSelect
  ProcedureReturn 0
EndProcedure

Procedure.i EvaluateForBlack()
  Protected x.i, y.i, score.i, p.i, center.i
  For y = 0 To 7
    For x = 0 To 7
      p = Board(x, y)
      If p <> 0
        center = 6 - Abs(3 - x) - Abs(3 - y)
        If p < 0
          score + PieceValue(p) + center * 4
        Else
          score - PieceValue(p) - center * 4
        EndIf
      EndIf
    Next
  Next
  If KingInCheck(1)
    score + 60
  EndIf
  If KingInCheck(-1)
    score - 80
  EndIf
  ProcedureReturn score
EndProcedure

Procedure.i ScoreMove(fx.i, fy.i, tx.i, ty.i)
  Protected moving.i = Board(fx, fy)
  Protected captured.i = Board(tx, ty)
  Protected oldMovedFrom.i = HasMoved(fx, fy)
  Protected oldMovedTo.i = HasMoved(tx, ty)
  Protected oldEPX.i = EnPassantX
  Protected oldEPY.i = EnPassantY
  Protected epCaptured.i = 0, epY.i = -1
  Protected rookFrom.i = -1, rookTo.i = -1, rookPiece.i = 0, rookMovedFrom.i, rookMovedTo.i
  Protected color.i = PieceColor(moving)
  Protected score.i

  If PieceType(moving) = #Pawn And tx = EnPassantX And ty = EnPassantY And captured = 0 And fx <> tx
    epY = ty - color
    epCaptured = Board(tx, epY)
  EndIf
  If PieceType(moving) = #King And Abs(tx - fx) = 2
    If tx > fx
      rookFrom = 7
      rookTo = 5
    Else
      rookFrom = 0
      rookTo = 3
    EndIf
    rookPiece = Board(rookFrom, fy)
    rookMovedFrom = HasMoved(rookFrom, fy)
    rookMovedTo = HasMoved(rookTo, fy)
  EndIf

  ApplyMoveNoRender(fx, fy, tx, ty)
  score = EvaluateForBlack()
  Board(fx, fy) = moving
  Board(tx, ty) = captured
  HasMoved(fx, fy) = oldMovedFrom
  HasMoved(tx, ty) = oldMovedTo
  EnPassantX = oldEPX
  EnPassantY = oldEPY
  If epY >= 0
    Board(tx, epY) = epCaptured
  EndIf
  If rookFrom >= 0
    Board(rookFrom, fy) = rookPiece
    Board(rookTo, fy) = 0
    HasMoved(rookFrom, fy) = rookMovedFrom
    HasMoved(rookTo, fy) = rookMovedTo
  EndIf
  ProcedureReturn score
EndProcedure

Procedure AIPlay()
  Protected fx.i, fy.i, tx.i, ty.i, count.i = 0, best.i = -999999, pick.i = -1, score.i
  Protected notation.s
  If GameOver
    ProcedureReturn
  EndIf

  For fy = 0 To 7
    For fx = 0 To 7
      If PieceColor(Board(fx, fy)) = -1
        For ty = 0 To 7
          For tx = 0 To 7
            If count < #MaxAIMoves And LegalMove(fx, fy, tx, ty)
              score = ScoreMove(fx, fy, tx, ty) + Random(10)
              AIMove(count)\fx = fx
              AIMove(count)\fy = fy
              AIMove(count)\tx = tx
              AIMove(count)\ty = ty
              AIMove(count)\score = score
              If score > best
                best = score
                pick = count
              EndIf
              count + 1
            EndIf
          Next
        Next
      EndIf
    Next
  Next

  If pick >= 0
    notation = MoveNotation(AIMove(pick)\fx, AIMove(pick)\fy, AIMove(pick)\tx, AIMove(pick)\ty)
    MakeMove(AIMove(pick)\fx, AIMove(pick)\fy, AIMove(pick)\tx, AIMove(pick)\ty)
    RecordMove(-1, notation)
    Turn = 1
    StatusText = "Black: " + notation + ". Whites move."
    If Not HasAnyLegalMove(1)
      GameOver = #True
      If KingInCheck(1)
        StatusText = "Checkmate. Black wins. Press N for a new game."
      Else
        StatusText = "Stalemate. Press N for a new game."
      EndIf
    ElseIf KingInCheck(1)
      StatusText + " Check."
    EndIf
  Else
    GameOver = #True
    StatusText = "Black has no legal moves. Press N for a new game."
  EndIf
  RefreshSquares()
EndProcedure

Procedure TryHumanMove(tx.i, ty.i)
  Protected notation.s
  If SelectedX < 0
    If PieceColor(Board(tx, ty)) = 1
      SelectedX = tx
      SelectedY = ty
      StatusText = "Selected " + SquareName(tx, ty) + ". Choose destination."
    EndIf
  Else
    If SelectedX = tx And SelectedY = ty
      SelectedX = -1
      SelectedY = -1
      StatusText = "Selection cancelled. Whites move."
    ElseIf LegalMove(SelectedX, SelectedY, tx, ty)
      notation = MoveNotation(SelectedX, SelectedY, tx, ty)
      MakeMove(SelectedX, SelectedY, tx, ty)
      RecordMove(1, notation)
      SelectedX = -1
      SelectedY = -1
      If Not HasAnyLegalMove(-1)
        GameOver = #True
        If KingInCheck(-1)
          StatusText = "Checkmate. White wins. Press N for a new game."
        Else
          StatusText = "Stalemate. Press N for a new game."
        EndIf
      Else
        Turn = -1
        StatusText = "AI thinking..."
        RefreshSquares()
        RenderWorld()
        FlipBuffers()
        AIPlay()
      EndIf
    ElseIf PieceColor(Board(tx, ty)) = 1
      SelectedX = tx
      SelectedY = ty
      StatusText = "Selected " + SquareName(tx, ty) + ". Choose destination."
    Else
      StatusText = "Illegal move."
    EndIf
  EndIf
  RefreshSquares()
EndProcedure

Procedure HandleInput()
  If InputCooldown > 0
    InputCooldown - 1
    ProcedureReturn
  EndIf

  If KeyboardPushed(#PB_Key_Left) And CursorX > 0
    CursorX - 1
    InputCooldown = 8
  ElseIf KeyboardPushed(#PB_Key_Right) And CursorX < 7
    CursorX + 1
    InputCooldown = 8
  ElseIf KeyboardPushed(#PB_Key_Up) And CursorY > 0
    CursorY - 1
    InputCooldown = 8
  ElseIf KeyboardPushed(#PB_Key_Down) And CursorY < 7
    CursorY + 1
    InputCooldown = 8
  ElseIf KeyboardPushed(#PB_Key_Return) Or KeyboardPushed(#PB_Key_Space)
    If Turn = 1 And GameOver = #False
      TryHumanMove(CursorX, CursorY)
    EndIf
    InputCooldown = 12
  ElseIf KeyboardPushed(#PB_Key_Back)
    SelectedX = -1
    SelectedY = -1
    StatusText = "Selection cancelled. Whites move."
    InputCooldown = 12
  ElseIf KeyboardPushed(#PB_Key_N)
    SetupBoard()
    InputCooldown = 12
  EndIf
  RefreshSquares()
EndProcedure

Procedure UpdateMouseHover()
  Protected picked.i = MousePick(#Camera, MouseX(), MouseY())
  MouseBoardX = BoardXFromEntity(picked)
  MouseBoardY = BoardYFromEntity(picked)
EndProcedure

Procedure DrawHud()
  Protected text.s, firstMove.i, i.i, y.i, piece.i
  StartDrawing(ScreenOutput())
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawText(12, 10, #APP_NAME + " - Arrow Keys=Move Cursor, Enter/Space=Select, Backspace=Cancel, N=New Game, Esc=Quit", RGB(255, 255, 255))
  DrawText(12, 34, StatusText, RGB(255, 235, 120))
  text = "Cursor@: " + SquareName(CursorX, CursorY)
  If SelectedX >= 0
    text + "   Selected: " + SquareName(SelectedX, SelectedY)
  EndIf
  
  If InBounds(MouseBoardX, MouseBoardY) And Board(MouseBoardX, MouseBoardY) <> 0
    piece = Board(MouseBoardX, MouseBoardY)
    text = "Mouse over: " + SquareName(MouseBoardX, MouseBoardY) + "   " + PieceName(piece)
  ElseIf Board(CursorX, CursorY) <> 0
    piece = Board(CursorX, CursorY)
    text = "Board cursor: " + SquareName(CursorX, CursorY) + "   " + PieceName(piece)
  Else
    text = "Board cursor: " + SquareName(CursorX, CursorY) + "   empty"
  EndIf
  DrawText(12, 58, text, RGB(210, 230, 255))

  DrawText(1130, 10, "Move History", RGB(255, 255, 255))
  DrawText(1130, 34, "No.   White       Black", RGB(210, 230, 255))
  firstMove = MoveCount - 18
  If firstMove < 0
    firstMove = 0
  EndIf
  y = 58
  For i = firstMove To MoveCount - 1
    text = RSet(Str(i + 1), 2, " ") + ".   " + LSet(WhiteMove(i), 10, " ") + "  " + BlackMove(i)
    DrawText(1130, y, text, RGB(235, 235, 220))
    y + 22
  Next
  StopDrawing()
EndProcedure

If InitEngine3D() = 0 Or InitSprite() = 0 Or InitKeyboard() = 0 Or InitMouse() = 0
  MessageRequester(#APP_NAME, "Unable To initialize the 3D engine, sprites, keyboard, Or mouse.")
  End
EndIf

If OpenWindow(0, 0, 0, 1280, 800, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered) = 0
  MessageRequester(#APP_NAME, "Unable To open the game window.")
  End
EndIf

If OpenWindowedScreen(WindowID(0), 0, 0, 1280, 800) = 0
  MessageRequester(#APP_NAME, "Unable To open the game screen.")
  End
EndIf
ReleaseMouse(#True)

CreateSceneResources()
CreateBoardEntities()
CreateCamera(#Camera, 0, 0, 100, 100)
MoveCamera(#Camera, 0, 13, 14, #PB_Absolute)
CameraLookAt(#Camera, 0, 0, 0)
CreateLight(#Light, RGB(255, 250, 235), 0, 12, 8)
AmbientColor(RGB(70, 70, 80))
SetupBoard()

Define Event.i
Repeat
  Repeat
    Event = WindowEvent()
    If Event = #PB_Event_CloseWindow
      ExitApp()
    EndIf
  Until Event = 0
  ExamineKeyboard()
  If KeyboardPushed(#PB_Key_Escape)
    ExitApp()
  EndIf
  If QuitRequested = #False
    ExamineMouse()
    UpdateMouseHover()
    HandleInput()
    RenderWorld()
    DrawHud()
    FlipBuffers()
  EndIf
Until QuitRequested

End

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 1025
; FirstLine = 984
; Folding = --------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_3DChess.ico
; Executable = ..\PB_3DChess.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = PB_3DChess
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = 3D Chess with AI player
; VersionField7 = PB_3DChess
; VersionField8 = PB_3DChess.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60