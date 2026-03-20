EnableExplicit

; === Constants ===
#BOARD_SIZE = 3
#CELL_SIZE = 100
#CANVAS_WIDTH = 300
#CANVAS_HEIGHT = 300
#WINDOW_WIDTH = 660
#WINDOW_HEIGHT = 585
#MAX_POWERUPS = 3

; === Enumerations ===
Enumeration
  #Window_Main
  #Canvas_Game
  #Gadget_Status
  #Gadget_Reset
  #Gadget_Score
  #Gadget_Difficulty
  #Gadget_GameMode
  #Gadget_PowerupMode
  #Gadget_Player1PowerupList
  #Gadget_Player2PowerupList
  #Gadget_UsePowerup1
  #Gadget_UsePowerup2
  #Gadget_PowerupStatus
  #Gadget_Help
EndEnumeration

Enumeration
  #DIFF_EASY
  #DIFF_MEDIUM
  #DIFF_HARD
EndEnumeration

Enumeration
  #MODE_VS_AI
  #MODE_VS_HUMAN
EndEnumeration

Enumeration
  #POWERUP_NONE
  #POWERUP_DOUBLE_STRIKE
  #POWERUP_CONVERT
  #POWERUP_SHIELD
  #POWERUP_BLOCK_ROW
  #POWERUP_ROTATE_BOARD
  #POWERUP_REWIND
  #POWERUP_STEAL
  #POWERUP_BOMB
EndEnumeration

#APP_NAME = "TicTacToe"
#EMAIL_NAME = "zonemaster60@gmail.com"

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

; === Structures ===
Structure Position
  x.i
  y.i
EndStructure

Structure PowerUp
  type.i
  name.s
  description.s
  used.b
EndStructure

Declare SetPowerupDetails(*powerup.PowerUp, powerupType)
Declare DrawCellSymbol(symbol.s, x, y, color)
Declare.s EvaluateBoard(updateWinningLine = #False)
Declare GetLinePotential(player.s, x1, y1, x2, y2, x3, y3)
Declare EvaluateSymbolPosition(player.s, x, y)
Declare EvaluateEmptyPosition(player.s, x, y)
Declare CanvasPixelWidth()
Declare CanvasPixelHeight()
Declare CanvasCellWidth()
Declare CanvasCellHeight()

; === Global Variables ===
Global Dim Board.s(#BOARD_SIZE-1, #BOARD_SIZE-1)
Global Dim ShieldBoard.b(#BOARD_SIZE-1, #BOARD_SIZE-1)
Global Dim BlockedBoard.b(#BOARD_SIZE-1, #BOARD_SIZE-1)
Global Player1Score, Player2Score, Draws
Global GameOver = #False
Global HoverX = -1, HoverY = -1
Global Difficulty = #DIFF_MEDIUM
Global GameMode = #MODE_VS_AI
Global PowerupMode = #False
Global CurrentPlayer.s = "X"
Global AnimationSpeed = 60
Global Dim WinningLine.Position(2)
Global WinningLineCount = 0
Global DoubleStrikeActive = #False
Global DoubleStrikeCount = 0
Global LastMove.Position
Global LastPlayer.s = ""
Global version.s = "v1.0.0.3"

; Power-up arrays
Global Dim Player1Powerups.PowerUp(#MAX_POWERUPS-1)
Global Dim Player2Powerups.PowerUp(#MAX_POWERUPS-1)

; === Utility Procedures ===
Procedure IsValidPosition(x, y)
  If x >= 0 And x < #BOARD_SIZE And y >= 0 And y < #BOARD_SIZE
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure IsBoardFull()
  Protected x, y
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = "" And Not BlockedBoard(x, y)
        ProcedureReturn #False
      EndIf
    Next
  Next
  ProcedureReturn #True
EndProcedure

Procedure ClearBoard()
  Protected x, y
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      Board(x, y) = ""
      ShieldBoard(x, y) = #False
      BlockedBoard(x, y) = #False
    Next
  Next
EndProcedure

Procedure UpdatePowerupLists()
  Protected i
  
  ; Clear lists
  ClearGadgetItems(#Gadget_Player1PowerupList)
  ClearGadgetItems(#Gadget_Player2PowerupList)
  
  ; Add Player 1 power-ups
  For i = 0 To #MAX_POWERUPS-1
    If Not Player1Powerups(i)\used
      AddGadgetItem(#Gadget_Player1PowerupList, -1, Player1Powerups(i)\name + " - " + Player1Powerups(i)\description)
    Else
      AddGadgetItem(#Gadget_Player1PowerupList, -1, "[USED] " + Player1Powerups(i)\name)
    EndIf
  Next
  
  ; Add Player 2 power-ups
  For i = 0 To #MAX_POWERUPS-1
    If Not Player2Powerups(i)\used
      AddGadgetItem(#Gadget_Player2PowerupList, -1, Player2Powerups(i)\name + " - " + Player2Powerups(i)\description)
    Else
      AddGadgetItem(#Gadget_Player2PowerupList, -1, "[USED] " + Player2Powerups(i)\name)
    EndIf
  Next
EndProcedure

Procedure InitializePowerups()
  Protected Dim powerupTypes(7)
  Protected i, randomType
  
  ; Available power-up types
  powerupTypes(0) = #POWERUP_DOUBLE_STRIKE
  powerupTypes(1) = #POWERUP_CONVERT
  powerupTypes(2) = #POWERUP_SHIELD
  powerupTypes(3) = #POWERUP_BLOCK_ROW
  powerupTypes(4) = #POWERUP_ROTATE_BOARD
  powerupTypes(5) = #POWERUP_REWIND
  powerupTypes(6) = #POWERUP_STEAL
  powerupTypes(7) = #POWERUP_BOMB
  
  ; Initialize Player 1 power-ups
  For i = 0 To #MAX_POWERUPS-1
    randomType = powerupTypes(Random(7))
    SetPowerupDetails(@Player1Powerups(i), randomType)
  Next
  
  ; Initialize Player 2/AI power-ups
  For i = 0 To #MAX_POWERUPS-1
    randomType = powerupTypes(Random(7))
    SetPowerupDetails(@Player2Powerups(i), randomType)
  Next
  
  UpdatePowerupLists()
EndProcedure

; === Drawing Procedures ===
Procedure DrawBoard()
  Protected x, y
  Protected boardWidth = CanvasPixelWidth()
  Protected boardHeight = CanvasPixelHeight()
  Protected cellWidth = CanvasCellWidth()
  Protected cellHeight = CanvasCellHeight()
  
  StartDrawing(CanvasOutput(#Canvas_Game))
  
  ; Clear background
  Box(0, 0, boardWidth, boardHeight, $F8F7F3)
  
  ; Draw grid lines
  For x = 1 To #BOARD_SIZE-1
    Line(x * cellWidth, 0, 2, boardHeight, $8B8378)
  Next
  For y = 1 To #BOARD_SIZE-1
    Line(0, y * cellHeight, boardWidth, 2, $8B8378)
  Next
  
  ; Draw special cell states
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      ; Draw blocked cells
      If BlockedBoard(x, y)
        Box(x * cellWidth + 3, y * cellHeight + 3, cellWidth - 6, cellHeight - 6, $E8A5A0)
      EndIf
      
      ; Draw shielded cells
      If ShieldBoard(x, y)
        Box(x * cellWidth + 3, y * cellHeight + 3, cellWidth - 6, cellHeight - 6, $B9E3C6)
      EndIf
    Next
  Next
  
  ; Draw hover effect
  If Not GameOver And HoverX >= 0 And HoverY >= 0 And IsValidPosition(HoverX, HoverY) And Board(HoverX, HoverY) = "" And Not BlockedBoard(HoverX, HoverY)
    Box(HoverX * cellWidth + 5, HoverY * cellHeight + 5, cellWidth - 10, cellHeight - 10, $E8DCC6)
  EndIf
  
  ; Draw symbols
  DrawingFont(FontID(0))
  DrawingMode(#PB_2DDrawing_Transparent)
  
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = "X"
        DrawCellSymbol("X", x, y, $356AA0)
      ElseIf Board(x, y) = "O"
        DrawCellSymbol("O", x, y, $B45D4C)
      EndIf
    Next
  Next
  
  StopDrawing()
EndProcedure

Procedure CanvasPixelWidth()
  ProcedureReturn #CELL_SIZE * #BOARD_SIZE + 2
EndProcedure

Procedure CanvasPixelHeight()
  ProcedureReturn #CELL_SIZE * #BOARD_SIZE + 2
EndProcedure

Procedure CanvasCellWidth()
  ProcedureReturn (#CELL_SIZE * #BOARD_SIZE) / #BOARD_SIZE
EndProcedure

Procedure CanvasCellHeight()
  ProcedureReturn (#CELL_SIZE * #BOARD_SIZE) / #BOARD_SIZE
EndProcedure

Procedure DrawCellSymbol(symbol.s, x, y, color)
  Protected textX, textY
  Protected cellWidth = CanvasCellWidth()
  Protected cellHeight = CanvasCellHeight()

  textX = x * cellWidth + ((cellWidth - TextWidth(symbol)) / 2)
  textY = y * cellHeight + ((cellHeight - TextHeight(symbol)) / 2) - 4
  DrawText(textX, textY, symbol, color)
EndProcedure

Procedure AnimateSymbol(symbol.s, x, y, color)
  Protected i, alpha
  Protected cellWidth = CanvasCellWidth()
  Protected cellHeight = CanvasCellHeight()
  
  For i = 10 To 0 Step -1
    StartDrawing(CanvasOutput(#Canvas_Game))
    
    ; Clear cell
    DrawingMode(#PB_2DDrawing_Default)
    Box(x * cellWidth + 2, y * cellHeight + 2, cellWidth - 4, cellHeight - 4, $F8F7F3)
    
    ; Draw symbol
    DrawingMode(#PB_2DDrawing_Transparent)
    DrawingFont(FontID(0))
    DrawCellSymbol(symbol, x, y, color)
    
    ; Add fade effect
    If i > 0
      DrawingMode(#PB_2DDrawing_AlphaBlend)
      alpha = RGBA($FF, $FF, $FF, i * 20)
      Box(x * cellWidth + 2, y * cellHeight + 2, cellWidth - 4, cellHeight - 4, alpha)
    EndIf
    
    StopDrawing()
    Delay(AnimationSpeed)
  Next
EndProcedure

Procedure AnimateWinningLine(winner.s)
  Protected i, j, x, y, color
  Protected cellWidth = CanvasCellWidth()
  Protected cellHeight = CanvasCellHeight()
  
  ; Set color based on winner
  If winner = "X"
    color = $6699FF  ; Light Blue for X
  Else
    color = $FF9966  ; Light Red for O
  EndIf
  
  ; Animate the winning line by flashing it
  For i = 1 To 6  ; Flash 6 times
    StartDrawing(CanvasOutput(#Canvas_Game))
    
    ; Draw the winning line with alternating colors
    DrawingMode(#PB_2DDrawing_Default)
    
    For j = 0 To WinningLineCount - 1
      x = WinningLine(j)\x
      y = WinningLine(j)\y
      
      ; Flash between winner color and white
      If i % 2 = 1
        Box(x * cellWidth + 2, y * cellHeight + 2, cellWidth - 4, cellHeight - 4, color)
      Else
        Box(x * cellWidth + 2, y * cellHeight + 2, cellWidth - 4, cellHeight - 4, $F8F7F3)
      EndIf
      
      ; Redraw the symbol in the cell
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawingFont(FontID(0))
      
      If Board(x, y) = "X"
        DrawCellSymbol("X", x, y, $356AA0)
      ElseIf Board(x, y) = "O"
        DrawCellSymbol("O", x, y, $B45D4C)
      EndIf
      
      DrawingMode(#PB_2DDrawing_Default)
    Next
    
    StopDrawing()
    Delay(200)  ; Pause between flashes
  Next
  
  ; Final redraw to show the winning line highlighted
  StartDrawing(CanvasOutput(#Canvas_Game))
  DrawingMode(#PB_2DDrawing_Default)
  
  For j = 0 To WinningLineCount - 1
    x = WinningLine(j)\x
    y = WinningLine(j)\y
    
    ; Highlight the winning cells with a lighter version of the winner's color
    If winner = "X"
      Box(x * cellWidth + 2, y * cellHeight + 2, cellWidth - 4, cellHeight - 4, $86B6E3)
    Else
      Box(x * cellWidth + 2, y * cellHeight + 2, cellWidth - 4, cellHeight - 4, $E8B19E)
    EndIf
    
    ; Redraw the symbol
    DrawingMode(#PB_2DDrawing_Transparent)
    DrawingFont(FontID(0))
    
    If Board(x, y) = "X"
      DrawCellSymbol("X", x, y, $356AA0)
    ElseIf Board(x, y) = "O"
      DrawCellSymbol("O", x, y, $B45D4C)
    EndIf
    
    DrawingMode(#PB_2DDrawing_Default)
  Next
  
  StopDrawing()
EndProcedure

; === Power-up Procedures ===
Procedure RotateBoard()
  Protected Dim newBoard.s(#BOARD_SIZE-1, #BOARD_SIZE-1)
  Protected Dim newShield.b(#BOARD_SIZE-1, #BOARD_SIZE-1)
  Protected Dim newBlocked.b(#BOARD_SIZE-1, #BOARD_SIZE-1)
  Protected x, y
  
  ; Rotate board 90 degrees clockwise
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      newBoard(#BOARD_SIZE-1-y, x) = Board(x, y)
      newShield(#BOARD_SIZE-1-y, x) = ShieldBoard(x, y)
      newBlocked(#BOARD_SIZE-1-y, x) = BlockedBoard(x, y)
    Next
  Next
  
  ; Copy back
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      Board(x, y) = newBoard(x, y)
      ShieldBoard(x, y) = newShield(x, y)
      BlockedBoard(x, y) = newBlocked(x, y)
    Next
  Next
EndProcedure

Procedure SetPowerupDetails(*powerup.PowerUp, powerupType)
  *powerup\type = powerupType
  *powerup\used = #False

  Select powerupType
    Case #POWERUP_DOUBLE_STRIKE
      *powerup\name = "Double Strike"
      *powerup\description = "Place two symbols in one turn"
    Case #POWERUP_CONVERT
      *powerup\name = "Convert"
      *powerup\description = "Convert opponent's symbol to yours"
    Case #POWERUP_SHIELD
      *powerup\name = "Shield"
      *powerup\description = "Protect one of your symbols"
    Case #POWERUP_BLOCK_ROW
      *powerup\name = "Block"
      *powerup\description = "Block one empty cell"
    Case #POWERUP_ROTATE_BOARD
      *powerup\name = "Rotate"
      *powerup\description = "Rotate the entire board 90 deg"
    Case #POWERUP_REWIND
      *powerup\name = "Rewind"
      *powerup\description = "Undo the last move"
    Case #POWERUP_STEAL
      *powerup\name = "Steal"
      *powerup\description = "Use an opponent power-up"
    Case #POWERUP_BOMB
      *powerup\name = "Bomb"
      *powerup\description = "Claim the center cell"
  EndSelect
EndProcedure

Procedure UpdatePowerupControls()
  If PowerupMode
    DisableGadget(#Gadget_Player1PowerupList, #False)
    DisableGadget(#Gadget_UsePowerup1, #False)
  Else
    DisableGadget(#Gadget_Player1PowerupList, #True)
    DisableGadget(#Gadget_UsePowerup1, #True)
  EndIf

  If GameMode = #MODE_VS_AI Or Not PowerupMode
    DisableGadget(#Gadget_Player2PowerupList, #True)
    DisableGadget(#Gadget_UsePowerup2, #True)
  Else
    DisableGadget(#Gadget_Player2PowerupList, #False)
    DisableGadget(#Gadget_UsePowerup2, #False)
  EndIf
EndProcedure

Procedure CleanupAndExit()
  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
  End
EndProcedure

Procedure GetLinePotential(player.s, x1, y1, x2, y2, x3, y3)
  Protected ownCount, emptyCount
  Protected opponent.s

  If player = "X"
    opponent = "O"
  Else
    opponent = "X"
  EndIf

  If Board(x1, y1) = opponent Or Board(x2, y2) = opponent Or Board(x3, y3) = opponent
    ProcedureReturn 0
  EndIf

  If Board(x1, y1) = player : ownCount + 1 : ElseIf Board(x1, y1) = "" And Not BlockedBoard(x1, y1) : emptyCount + 1 : EndIf
  If Board(x2, y2) = player : ownCount + 1 : ElseIf Board(x2, y2) = "" And Not BlockedBoard(x2, y2) : emptyCount + 1 : EndIf
  If Board(x3, y3) = player : ownCount + 1 : ElseIf Board(x3, y3) = "" And Not BlockedBoard(x3, y3) : emptyCount + 1 : EndIf

  If ownCount = 2 And emptyCount = 1
    ProcedureReturn 6
  ElseIf ownCount = 1 And emptyCount = 2
    ProcedureReturn 3
  ElseIf ownCount = 0 And emptyCount = 3
    ProcedureReturn 1
  EndIf

  ProcedureReturn 0
EndProcedure

Procedure EvaluateSymbolPosition(player.s, x, y)
  Protected score = 0

  score + GetLinePotential(player, x, 0, x, 1, x, 2)
  score + GetLinePotential(player, 0, y, 1, y, 2, y)

  If x = y
    score + GetLinePotential(player, 0, 0, 1, 1, 2, 2)
  EndIf

  If x + y = #BOARD_SIZE - 1
    score + GetLinePotential(player, 2, 0, 1, 1, 0, 2)
  EndIf

  If x = 1 And y = 1
    score + 4
  ElseIf (x = 0 Or x = 2) And (y = 0 Or y = 2)
    score + 2
  Else
    score + 1
  EndIf

  ProcedureReturn score
EndProcedure

Procedure EvaluateEmptyPosition(player.s, x, y)
  Protected opponent.s
  Protected score

  If Board(x, y) <> "" Or BlockedBoard(x, y)
    ProcedureReturn -1000
  EndIf

  If player = "X"
    opponent = "O"
  Else
    opponent = "X"
  EndIf

  Board(x, y) = player
  score = EvaluateSymbolPosition(player, x, y)
  If EvaluateBoard() = player
    score + 100
  EndIf
  Board(x, y) = ""

  Board(x, y) = opponent
  If EvaluateBoard() = opponent
    score + 80
  EndIf
  Board(x, y) = ""

  ProcedureReturn score
EndProcedure

Procedure ExecutePowerup(powerupType, player.s)
  Protected x, y, i, bestX = -1, bestY = -1, bestScore = -1000, score
  Protected found = #False, success = #False
  Protected stolenType, stolenName.s
  
  Select powerupType
    Case #POWERUP_DOUBLE_STRIKE
      DoubleStrikeActive = #True
      DoubleStrikeCount = 0
      SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' activated Double Strike! Place two symbols.")
      success = #True
      
    Case #POWERUP_CONVERT
      ; Convert the most valuable opponent symbol that is not shielded
      For y = 0 To #BOARD_SIZE-1
        For x = 0 To #BOARD_SIZE-1
          If (player = "X" And Board(x, y) = "O") Or (player = "O" And Board(x, y) = "X")
            If Not ShieldBoard(x, y)
              found = #True
              score = EvaluateSymbolPosition(Board(x, y), x, y)
              If score > bestScore
                bestScore = score
                bestX = x
                bestY = y
              EndIf
            EndIf
          EndIf
        Next
      Next
      If found
        Board(bestX, bestY) = player
        SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' converted a key symbol!")
        success = #True
      Else
        SetGadgetText(#Gadget_PowerupStatus, "No symbols to convert!")
      EndIf
      
    Case #POWERUP_SHIELD
      ; Shield the most valuable unshielded symbol
      bestScore = -1000
      For y = 0 To #BOARD_SIZE-1
        For x = 0 To #BOARD_SIZE-1
          If Board(x, y) = player And Not ShieldBoard(x, y)
            found = #True
            score = EvaluateSymbolPosition(player, x, y)
            If score > bestScore
              bestScore = score
              bestX = x
              bestY = y
            EndIf
          EndIf
        Next
      Next
      If found
        ShieldBoard(bestX, bestY) = #True
        SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' shielded a key symbol!")
        success = #True
      Else
        SetGadgetText(#Gadget_PowerupStatus, "No symbols to shield!")
      EndIf
      
    Case #POWERUP_BLOCK_ROW
      ; Block the most dangerous empty cell for the opponent
      bestScore = -1000
      For y = 0 To #BOARD_SIZE-1
        For x = 0 To #BOARD_SIZE-1
          If Board(x, y) = "" And Not BlockedBoard(x, y)
            found = #True
            If player = "X"
              score = EvaluateEmptyPosition("O", x, y)
            Else
              score = EvaluateEmptyPosition("X", x, y)
            EndIf

            If score > bestScore
              bestScore = score
              bestX = x
              bestY = y
            EndIf
          EndIf
        Next
      Next
      If found
        BlockedBoard(bestX, bestY) = #True
        SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' blocked a dangerous cell!")
        success = #True
      Else
        SetGadgetText(#Gadget_PowerupStatus, "No cells to block!")
      EndIf
      
    Case #POWERUP_ROTATE_BOARD
      RotateBoard()
      SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' rotated the board!")
      success = #True
      
    Case #POWERUP_REWIND
      If LastPlayer <> ""
        Board(LastMove\x, LastMove\y) = ""
        SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' rewound the last move!")
        LastPlayer = ""
        success = #True
      Else
        SetGadgetText(#Gadget_PowerupStatus, "No move to rewind!")
      EndIf
      
    Case #POWERUP_STEAL
      If player = "X"
        For i = 0 To #MAX_POWERUPS-1
          If Not Player2Powerups(i)\used And Player2Powerups(i)\type <> #POWERUP_STEAL
            stolenType = Player2Powerups(i)\type
            stolenName = Player2Powerups(i)\name
            Player2Powerups(i)\used = #True
            found = #True
            Break
          EndIf
        Next
      Else
        For i = 0 To #MAX_POWERUPS-1
          If Not Player1Powerups(i)\used And Player1Powerups(i)\type <> #POWERUP_STEAL
            stolenType = Player1Powerups(i)\type
            stolenName = Player1Powerups(i)\name
            Player1Powerups(i)\used = #True
            found = #True
            Break
          EndIf
        Next
      EndIf

      If found
        success = ExecutePowerup(stolenType, player)
        If success
          SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' stole " + stolenName + "!")
        Else
          If player = "X"
            Player2Powerups(i)\used = #False
          Else
            Player1Powerups(i)\used = #False
          EndIf
          SetGadgetText(#Gadget_PowerupStatus, "No usable power-up to steal!")
        EndIf
      Else
        SetGadgetText(#Gadget_PowerupStatus, "No usable power-up to steal!")
      EndIf
      
    Case #POWERUP_BOMB
      ; Claim the center only if it is a legal target
      If Not ShieldBoard(1, 1) And Not BlockedBoard(1, 1)
        Board(1, 1) = player
        SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' claimed the center with Bomb!")
        success = #True
      Else
        SetGadgetText(#Gadget_PowerupStatus, "Center is shielded or blocked!")
      EndIf
  EndSelect

  ProcedureReturn success
EndProcedure

; === Game Logic ===
Procedure.s EvaluateBoard(updateWinningLine = #False)
  Protected i

  If updateWinningLine
    WinningLineCount = 0
  EndIf

  For i = 0 To #BOARD_SIZE-1
    If Board(i, 0) <> "" And Board(i, 0) = Board(i, 1) And Board(i, 0) = Board(i, 2)
      If updateWinningLine
        WinningLine(0)\x = i : WinningLine(0)\y = 0
        WinningLine(1)\x = i : WinningLine(1)\y = 1
        WinningLine(2)\x = i : WinningLine(2)\y = 2
        WinningLineCount = 3
      EndIf
      ProcedureReturn Board(i, 0)
    EndIf
  Next

  For i = 0 To #BOARD_SIZE-1
    If Board(0, i) <> "" And Board(0, i) = Board(1, i) And Board(0, i) = Board(2, i)
      If updateWinningLine
        WinningLine(0)\x = 0 : WinningLine(0)\y = i
        WinningLine(1)\x = 1 : WinningLine(1)\y = i
        WinningLine(2)\x = 2 : WinningLine(2)\y = i
        WinningLineCount = 3
      EndIf
      ProcedureReturn Board(0, i)
    EndIf
  Next

  If Board(0, 0) <> "" And Board(0, 0) = Board(1, 1) And Board(0, 0) = Board(2, 2)
    If updateWinningLine
      WinningLine(0)\x = 0 : WinningLine(0)\y = 0
      WinningLine(1)\x = 1 : WinningLine(1)\y = 1
      WinningLine(2)\x = 2 : WinningLine(2)\y = 2
      WinningLineCount = 3
    EndIf
    ProcedureReturn Board(0, 0)
  EndIf

  If Board(2, 0) <> "" And Board(2, 0) = Board(1, 1) And Board(2, 0) = Board(0, 2)
    If updateWinningLine
      WinningLine(0)\x = 2 : WinningLine(0)\y = 0
      WinningLine(1)\x = 1 : WinningLine(1)\y = 1
      WinningLine(2)\x = 0 : WinningLine(2)\y = 2
      WinningLineCount = 3
    EndIf
    ProcedureReturn Board(2, 0)
  EndIf

  If IsBoardFull()
    ProcedureReturn "Draw"
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s CheckWinner()
  ProcedureReturn EvaluateBoard(#True)
EndProcedure

Procedure EvaluateLineScore(a.s, b.s, c.s)
  Protected xCount, oCount, emptyCount

  If a = "X" : xCount + 1 : ElseIf a = "O" : oCount + 1 : Else : emptyCount + 1 : EndIf
  If b = "X" : xCount + 1 : ElseIf b = "O" : oCount + 1 : Else : emptyCount + 1 : EndIf
  If c = "X" : xCount + 1 : ElseIf c = "O" : oCount + 1 : Else : emptyCount + 1 : EndIf

  If oCount > 0 And xCount = 0
    Select oCount
      Case 2
        ProcedureReturn 10
      Case 1
        ProcedureReturn 2
    EndSelect
  ElseIf xCount > 0 And oCount = 0
    Select xCount
      Case 2
        ProcedureReturn -10
      Case 1
        ProcedureReturn -2
    EndSelect
  EndIf

  ProcedureReturn 0
EndProcedure

Procedure EvaluatePositionScore()
  Protected score
  Protected x, y

  score + EvaluateLineScore(Board(0, 0), Board(1, 0), Board(2, 0))
  score + EvaluateLineScore(Board(0, 1), Board(1, 1), Board(2, 1))
  score + EvaluateLineScore(Board(0, 2), Board(1, 2), Board(2, 2))
  score + EvaluateLineScore(Board(0, 0), Board(0, 1), Board(0, 2))
  score + EvaluateLineScore(Board(1, 0), Board(1, 1), Board(1, 2))
  score + EvaluateLineScore(Board(2, 0), Board(2, 1), Board(2, 2))
  score + EvaluateLineScore(Board(0, 0), Board(1, 1), Board(2, 2))
  score + EvaluateLineScore(Board(2, 0), Board(1, 1), Board(0, 2))

  If Board(1, 1) = "O"
    score + 3
  ElseIf Board(1, 1) = "X"
    score - 3
  EndIf

  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If BlockedBoard(x, y)
        If x = 1 And y = 1
          score - 2
        Else
          score - 1
        EndIf
      EndIf
    Next
  Next

  ProcedureReturn score
EndProcedure

Procedure Minimax(depth, isMaximizing, alpha, beta)
  Protected result.s = EvaluateBoard()
  Protected bestScore, score, x, y, symbol.s

  Select result
    Case "O"
      ProcedureReturn 100 - depth
    Case "X"
      ProcedureReturn depth - 100
    Case "Draw"
      ProcedureReturn 0
  EndSelect

  If Difficulty = #DIFF_MEDIUM And depth >= 3
    ProcedureReturn EvaluatePositionScore()
  EndIf

  If isMaximizing
    bestScore = -10000
    symbol = "O"
  Else
    bestScore = 10000
    symbol = "X"
  EndIf

  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = "" And Not BlockedBoard(x, y)
        Board(x, y) = symbol
        score = Minimax(depth + 1, Bool(Not isMaximizing), alpha, beta)
        Board(x, y) = ""

        If isMaximizing
          If score > bestScore
            bestScore = score
          EndIf
          If bestScore > alpha
            alpha = bestScore
          EndIf
        Else
          If score < bestScore
            bestScore = score
          EndIf
          If bestScore < beta
            beta = bestScore
          EndIf
        EndIf

        If beta <= alpha
          ProcedureReturn bestScore
        EndIf
      EndIf
    Next
  Next

  If bestScore = -10000 Or bestScore = 10000
    ProcedureReturn EvaluatePositionScore()
  EndIf

  ProcedureReturn bestScore
EndProcedure

Procedure CountWinningMoves(player.s)
  Protected count = 0, x, y, original.s
  
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = "" And Not BlockedBoard(x, y)
        original = Board(x, y)
        Board(x, y) = player
        If EvaluateBoard() = player
          count + 1
        EndIf
        Board(x, y) = original
      EndIf
    Next
  Next
  
  ProcedureReturn count
EndProcedure

Procedure CountPlayerSymbols(player.s)
  Protected count = 0, x, y
  
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = player
        count + 1
      EndIf
    Next
  Next
  
  ProcedureReturn count
EndProcedure

Procedure CountEmptyCells()
  Protected count = 0, x, y
  
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = "" And Not BlockedBoard(x, y)
        count + 1
      EndIf
    Next
  Next
  
  ProcedureReturn count
EndProcedure

Procedure GetBestMove()
  Protected bestX = -1, bestY = -1, x, y, score, bestScore = -10000
  Protected randomnessThreshold

  Select Difficulty
    Case #DIFF_EASY
      randomnessThreshold = 65
    Case #DIFF_MEDIUM
      randomnessThreshold = 20
    Default
      randomnessThreshold = -1
  EndSelect

  If randomnessThreshold >= 0 And Random(99) < randomnessThreshold
    For y = 0 To #BOARD_SIZE-1
      For x = 0 To #BOARD_SIZE-1
        If Board(x, y) = "" And Not BlockedBoard(x, y)
          ProcedureReturn (y << 16) | x
        EndIf
      Next
    Next
  EndIf

  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = "" And Not BlockedBoard(x, y)
        Board(x, y) = "O"
        score = Minimax(0, #False, -10000, 10000)
        Board(x, y) = ""

        If Difficulty <> #DIFF_EASY And x = 1 And y = 1
          score + 2
        EndIf

        If score > bestScore
          bestScore = score
          bestX = x
          bestY = y
        EndIf
      EndIf
    Next
  Next

  If bestX >= 0
    ProcedureReturn (bestY << 16) | bestX
  EndIf

  ProcedureReturn -1
EndProcedure

Procedure AITurn()
  Protected move, x, y
  
  ; Smart AI power-up usage
  If PowerupMode
    Protected i, bestPowerup = -1, powerupPriority = 0
    Protected playerWinningMoves = CountWinningMoves("X")
    Protected aiWinningMoves = CountWinningMoves("O")
    
    ; Analyze game state and choose best power-up
    For i = 0 To #MAX_POWERUPS-1
      If Not Player2Powerups(i)\used
        Protected currentPriority = 0
        
        Select Player2Powerups(i)\type
          Case #POWERUP_CONVERT
            ; High priority if player has many symbols and we can convert
            If playerWinningMoves > 0
              currentPriority = 90
            ElseIf CountPlayerSymbols("X") >= 2
              currentPriority = 60
            EndIf
            
          Case #POWERUP_BLOCK_ROW
            ; High priority if player is about to win
            If playerWinningMoves > 0
              currentPriority = 95
            EndIf
            
          Case #POWERUP_REWIND
            ; Use if player just made a good move
            If LastPlayer = "X" And playerWinningMoves > aiWinningMoves
              currentPriority = 85
            EndIf
            
          Case #POWERUP_SHIELD
            ; Protect AI symbols if player can swap
            If aiWinningMoves > 0 And CountPlayerSymbols("O") >= 1
              currentPriority = 70
            EndIf
            
          Case #POWERUP_DOUBLE_STRIKE
            ; Use when board is not too full
            If CountEmptyCells() >= 4
              currentPriority = 50
            EndIf
            
          Case #POWERUP_ROTATE_BOARD
            ; Use strategically when behind
            If playerWinningMoves > aiWinningMoves
              currentPriority = 40
            EndIf
            
          Case #POWERUP_BOMB
            ; Use if center is strategic
            If Board(1, 1) = "" And CountEmptyCells() >= 5
              currentPriority = 55
            EndIf
            
          Case #POWERUP_STEAL
            ; Random usage
            currentPriority = 30
        EndSelect
        
        ; Add some randomness but prefer higher priority power-ups
        currentPriority + Random(20)
        
        If currentPriority > powerupPriority
          powerupPriority = currentPriority
          bestPowerup = i
        EndIf
      EndIf
    Next
    
    ; Use power-up if priority is high enough
    If bestPowerup >= 0 And powerupPriority >= 60
      If ExecutePowerup(Player2Powerups(bestPowerup)\type, "O")
        Player2Powerups(bestPowerup)\used = #True
        UpdatePowerupLists()
        DrawBoard()
        Delay(1000)
      EndIf
    EndIf
  EndIf
  
  move = GetBestMove()
  If move >= 0
    x = move & $FFFF
    y = (move >> 16) & $FFFF
    
    ; Store last move for rewind
    LastMove\x = x
    LastMove\y = y
    LastPlayer = "O"
    
    AnimateSymbol("O", x, y, $FF0000)
    Board(x, y) = "O"
    
    If DoubleStrikeActive
      DoubleStrikeCount + 1
      If DoubleStrikeCount < 2
        If CheckWinner() = ""
          SetGadgetText(#Gadget_PowerupStatus, "AI is taking its second strike!")
          DrawBoard()
          Delay(500)
          
          move = GetBestMove()
          If move >= 0
            x = move & $FFFF
            y = (move >> 16) & $FFFF
            LastMove\x = x
            LastMove\y = y
            LastPlayer = "O"
            AnimateSymbol("O", x, y, $FF0000)
            Board(x, y) = "O"
          EndIf
        EndIf
      EndIf
      DoubleStrikeActive = #False
      DoubleStrikeCount = 0
    EndIf
    
    CurrentPlayer = "X"
    
    ; Update status for next turn
    If Not GameOver
      SetGadgetText(#Gadget_Status, "Player 1 move... Good luck!")
    EndIf
  EndIf
EndProcedure

Procedure UpdateScoreDisplay()
  Protected scoreText.s
  
  Select GameMode
    Case #MODE_VS_AI
      scoreText = "Player 1: " + Str(Player1Score) + " | AI Player: " + Str(Player2Score) + " | Draws: " + Str(Draws)
    Case #MODE_VS_HUMAN
      scoreText = "Player 1: " + Str(Player1Score) + " | Player 2: " + Str(Player2Score) + " | Draws: " + Str(Draws)
  EndSelect
  
  SetGadgetText(#Gadget_Score, "Score | " + scoreText)
EndProcedure

Procedure UpdateStatusMessage()
  Protected statusText.s
  
  If GameOver
    ProcedureReturn
  EndIf
  
  Select GameMode
    Case #MODE_VS_AI
      If CurrentPlayer = "X"
        statusText = "Player 1 move... Good luck!"
      Else
        statusText = "AI is thinking..."
      EndIf
    Case #MODE_VS_HUMAN
      If CurrentPlayer = "X"
        statusText = "Player 1's turn (X)"
      Else
        statusText = "Player 2's turn (O)"
      EndIf
  EndSelect
  
  SetGadgetText(#Gadget_Status, statusText)
EndProcedure

Procedure EndGame(result.s)
  GameOver = #True
  HoverX = -1 : HoverY = -1
  
  ; Animate winning line if there's a winner
  If result <> "Draw" And WinningLineCount > 0
    AnimateWinningLine(result)
  EndIf
  
  Select result
    Case "X"
      Player1Score + 1
      Select GameMode
        Case #MODE_VS_AI
          SetGadgetText(#Gadget_Status, "Player 1 won! Great job!")
        Case #MODE_VS_HUMAN
          SetGadgetText(#Gadget_Status, "Player 1 wins! Congratulations!")
      EndSelect
    Case "O"
      Player2Score + 1
      Select GameMode
        Case #MODE_VS_AI
          SetGadgetText(#Gadget_Status, "AI Player won! Maybe next time!")
        Case #MODE_VS_HUMAN
          SetGadgetText(#Gadget_Status, "Player 2 wins! Congratulations!")
      EndSelect
    Case "Draw"
      Draws + 1
      SetGadgetText(#Gadget_Status, "It's a draw! Well played!")
  EndSelect
  
  UpdateScoreDisplay()
EndProcedure

; === Event Handlers ===
Procedure CanvasClick()
  If GameOver : ProcedureReturn : EndIf
  
  Protected mx = GetGadgetAttribute(#Canvas_Game, #PB_Canvas_MouseX)
  Protected my = GetGadgetAttribute(#Canvas_Game, #PB_Canvas_MouseY)
  Protected x = mx / #CELL_SIZE
  Protected y = my / #CELL_SIZE
  Protected result.s
  
  If IsValidPosition(x, y) And Board(x, y) = "" And Not BlockedBoard(x, y)
    ; Store last move for rewind
    LastMove\x = x
    LastMove\y = y
    LastPlayer = CurrentPlayer
    
    ; Place current player's symbol
    If CurrentPlayer = "X"
      AnimateSymbol("X", x, y, $0000FF)
      Board(x, y) = "X"
    Else
      AnimateSymbol("O", x, y, $FF0000)
      Board(x, y) = "O"
    EndIf
    
    ; Check for game end
    result = CheckWinner()
    If result <> ""
      DrawBoard()
      EndGame(result)
      ProcedureReturn
    EndIf
    
    ; Handle double strike
    If DoubleStrikeActive
      DoubleStrikeCount + 1
      If DoubleStrikeCount >= 2
        DoubleStrikeActive = #False
        DoubleStrikeCount = 0
        SetGadgetText(#Gadget_PowerupStatus, "Double Strike completed!")
      Else
        SetGadgetText(#Gadget_PowerupStatus, "Double Strike: Place one more symbol!")
        DrawBoard()
        ProcedureReturn ; Don't switch players yet
      EndIf
    EndIf
    
    ; Handle next turn based on game mode
    Select GameMode
      Case #MODE_VS_AI
        If CurrentPlayer = "X"
          CurrentPlayer = "O"
          UpdateStatusMessage()
          AITurn()
          result = CheckWinner()
          If result <> ""
            DrawBoard()
            EndGame(result)
            ProcedureReturn
          EndIf
        EndIf
        
      Case #MODE_VS_HUMAN
        ; Switch players
        If CurrentPlayer = "X"
          CurrentPlayer = "O"
        Else
          CurrentPlayer = "X"
        EndIf
        UpdateStatusMessage()
    EndSelect
    
    DrawBoard()
  EndIf
EndProcedure

Procedure CanvasMouseMove()
  If GameOver : ProcedureReturn : EndIf
  
  Protected mx = GetGadgetAttribute(#Canvas_Game, #PB_Canvas_MouseX)
  Protected my = GetGadgetAttribute(#Canvas_Game, #PB_Canvas_MouseY)
  Protected newX = mx / #CELL_SIZE
  Protected newY = my / #CELL_SIZE
  
  If Not IsValidPosition(newX, newY)
    newX = -1 : newY = -1
  EndIf
  
  If newX <> HoverX Or newY <> HoverY
    HoverX = newX : HoverY = newY
    DrawBoard()
  EndIf
EndProcedure

Procedure ResetGame()
  ClearBoard()
  HoverX = -1 : HoverY = -1
  GameOver = #False
  CurrentPlayer = "X"
  WinningLineCount = 0
  DoubleStrikeActive = #False
  DoubleStrikeCount = 0
  LastPlayer = ""
  
  ; Reset power-ups if power-up mode is enabled
  If PowerupMode
    InitializePowerups()
  EndIf
  
  SetGadgetText(#Gadget_PowerupStatus, "")
  UpdateStatusMessage()
  DrawBoard()
EndProcedure

Procedure ChangeDifficulty()
  Difficulty = GetGadgetState(#Gadget_Difficulty)
  ResetGame()
EndProcedure

Procedure ChangeGameMode()
  GameMode = GetGadgetState(#Gadget_GameMode)
  
  ; Enable/disable difficulty selector based on game mode
  If GameMode = #MODE_VS_AI
    DisableGadget(#Gadget_Difficulty, #False)
  Else
    DisableGadget(#Gadget_Difficulty, #True)
  EndIf

  UpdatePowerupControls()
  
  ; Reset scores when switching modes
  Player1Score = 0
  Player2Score = 0
  Draws = 0
  
  UpdateScoreDisplay()
  ResetGame()
EndProcedure

Procedure ChangePowerupMode()
  PowerupMode = GetGadgetState(#Gadget_PowerupMode)

  UpdatePowerupControls()
  
  If PowerupMode
    InitializePowerups()
    SetGadgetText(#Gadget_PowerupStatus, "Power-ups enabled! Select and use them wisely.")
  Else
    SetGadgetText(#Gadget_PowerupStatus, "")
    ClearGadgetItems(#Gadget_Player1PowerupList)
    ClearGadgetItems(#Gadget_Player2PowerupList)
  EndIf
  
  ResetGame()
EndProcedure

Procedure UsePowerup1()
  If Not PowerupMode Or GameOver : ProcedureReturn : EndIf
  If CurrentPlayer <> "X" : ProcedureReturn : EndIf
  
  Protected selectedIndex = GetGadgetState(#Gadget_Player1PowerupList)
  If selectedIndex >= 0 And selectedIndex < #MAX_POWERUPS And Not Player1Powerups(selectedIndex)\used
    If ExecutePowerup(Player1Powerups(selectedIndex)\type, "X")
      Player1Powerups(selectedIndex)\used = #True
      UpdatePowerupLists()
      DrawBoard()
    EndIf
  EndIf
EndProcedure

Procedure UsePowerup2()
  If Not PowerupMode Or GameOver : ProcedureReturn : EndIf
  If GameMode = #MODE_VS_AI : ProcedureReturn : EndIf ; AI handles its own power-ups
  If CurrentPlayer <> "O" : ProcedureReturn : EndIf
  
  Protected selectedIndex = GetGadgetState(#Gadget_Player2PowerupList)
  If selectedIndex >= 0 And selectedIndex < #MAX_POWERUPS And Not Player2Powerups(selectedIndex)\used
    If ExecutePowerup(Player2Powerups(selectedIndex)\type, "O")
      Player2Powerups(selectedIndex)\used = #True
      UpdatePowerupLists()
      DrawBoard()
    EndIf
  EndIf
EndProcedure

Procedure OpenHelpFile()
  
  Protected helpPath.s
  
  ; Try to find the help file in the same directory as the executable
  helpPath = GetPathPart(ProgramFilename()) + "files\" + #APP_NAME + "_Help.html"
  
  ; Check if help file exists
  If FileSize(helpPath) > 0
    ; Open the help file in the default browser
    RunProgram(helpPath, "", "", #PB_Program_Open)
  Else
    ; Show message if help file not found
    MessageRequester("Help File Not Found", 
                     "Could not find '" + #APP_NAME + "_Help.html' in the " + #APP_NAME + "\files directory." + Chr(10) + Chr(10) + 
                     "Please make sure the help file is in the 'files' folder.", #PB_MessageRequester_Warning)
  EndIf
EndProcedure

Procedure ExitGame()
  Protected result = MessageRequester("Exit Game", "Are you sure?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If result = #PB_MessageRequester_Yes
    MessageRequester("Info", #APP_NAME +" "+ version + #CRLF$ +
                             "Thank you for playing this free game!" + #CRLF$ +
                             "Contact: " + #EMAIL_NAME, #PB_MessageRequester_Info)
    CleanupAndExit()
  EndIf
EndProcedure

; === Main Program ===
If OpenWindow(#Window_Main, 0, 0, #WINDOW_WIDTH, #WINDOW_HEIGHT, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  
  ; Create game canvas and basic controls
  CanvasGadget(#Canvas_Game, 10, 10, CanvasPixelWidth(), CanvasPixelHeight())
  StringGadget(#Gadget_Status, 10, 320, 300, 24, "Player 1 move... Good luck!", #PB_String_ReadOnly)
  StringGadget(#Gadget_Score, 10, 352, 300, 22, "", #PB_String_ReadOnly)
  ButtonGadget(#Gadget_Reset, 10, 380, 145, 25, "Reset")
  ButtonGadget(#Gadget_Help, 165, 380, 145, 25, "Help")
  
  ; Game mode selector
  TextGadget(#PB_Any, 10, 420, 55, 20, "Player 1")
  ComboBoxGadget(#Gadget_GameMode, 60, 417, 110, 25)
  AddGadgetItem(#Gadget_GameMode, -1, "vs AI Player")
  AddGadgetItem(#Gadget_GameMode, -1, "vs Player 2")
  SetGadgetState(#Gadget_GameMode, #MODE_VS_AI)
  
  ; Difficulty selector
  TextGadget(#PB_Any, 10, 455, 65, 20, "Difficulty:")
  ComboBoxGadget(#Gadget_Difficulty, 80, 452, 90, 25)
  AddGadgetItem(#Gadget_Difficulty, -1, "Easy")
  AddGadgetItem(#Gadget_Difficulty, -1, "Medium")
  AddGadgetItem(#Gadget_Difficulty, -1, "Hard")
  SetGadgetState(#Gadget_Difficulty, #DIFF_MEDIUM)
  
  ; Power-up mode selector
  CheckBoxGadget(#Gadget_PowerupMode, 10, 490, 120, 20, "Enable Power-ups")
  
  ; Power-up status
  TextGadget(#PB_Any, 10, 525, 110, 20, "Power-up Status:")
  StringGadget(#Gadget_PowerupStatus, 10, 545, 640, 24, "", #PB_String_ReadOnly)
  
  ; Power-up panels
  TextGadget(#PB_Any, 330, 20, 140, 20, "Player 1 Power-ups:")
  ListViewGadget(#Gadget_Player1PowerupList, 330, 45, 320, 80)
  ButtonGadget(#Gadget_UsePowerup1, 330, 130, 320, 25, "Use Selected Power-up")
  
  TextGadget(#PB_Any, 330, 170, 140, 20, "Player 2 Power-ups:")
  ListViewGadget(#Gadget_Player2PowerupList, 330, 195, 320, 80)
  ButtonGadget(#Gadget_UsePowerup2, 330, 280, 320, 25, "Use Selected Power-up")
  
  ; Instructions
  TextGadget(#PB_Any, 330, 320, 320, 195, "Power-up Legend:" + Chr(10) + "Green cells = Shielded" + Chr(10) + "Red cells = Blocked" + 
                                          Chr(10) + "Double Strike = Place 2 symbols" + Chr(10) + "Convert = Convert opponent's symbol" +
                                          Chr(10) + "Shield = Protect your symbol" + Chr(10) + "Block = Block one empty cell" +
                                          Chr(10) + "Rotate = Rotate the entire board 90 deg" + Chr(10) + "Rewind = Undo the last move" +
                                          Chr(10) + "Steal = Use an opponent power-up" + Chr(10) + "Bomb = Claim the center cell", #PB_Text_Center)
  
  ; Load fonts
  LoadFont(0, "Segoe UI", 50, #PB_Font_Bold)
  LoadFont(1, "Segoe UI", 10, #PB_Font_Bold)
  LoadFont(2, "Segoe UI", 9, #PB_Font_Bold)
  LoadFont(3, "Segoe UI", 9)
  
  ; Set gadget fonts
  SetGadgetFont(#Gadget_Status, FontID(1))
  SetGadgetFont(#Gadget_Score, FontID(2))
  SetGadgetFont(#Gadget_PowerupStatus, FontID(2))
  SetGadgetFont(#Gadget_Reset, FontID(3))
  SetGadgetFont(#Gadget_Help, FontID(3))
  SetGadgetFont(#Gadget_GameMode, FontID(3))
  SetGadgetFont(#Gadget_Difficulty, FontID(3))
  SetGadgetFont(#Gadget_PowerupMode, FontID(3))
  SetGadgetFont(#Gadget_Player1PowerupList, FontID(3))
  SetGadgetFont(#Gadget_Player2PowerupList, FontID(3))
  SetGadgetFont(#Gadget_UsePowerup1, FontID(3))
  SetGadgetFont(#Gadget_UsePowerup2, FontID(3))
  
  ; Initialize game
  UpdatePowerupControls()
  
  UpdateScoreDisplay()
  UpdateStatusMessage()
  DrawBoard()
  
  ; Main event loop
  Repeat
    Select WaitWindowEvent()
      Case #PB_Event_Gadget
        Select EventGadget()
          Case #Canvas_Game
            Select EventType()
              Case #PB_EventType_LeftButtonDown
                CanvasClick()
              Case #PB_EventType_MouseMove
                CanvasMouseMove()
            EndSelect
            
          Case #Gadget_Reset
            ResetGame()
            
          Case #Gadget_Help
            OpenHelpFile()
            
          Case #Gadget_Difficulty
            ChangeDifficulty()
            
          Case #Gadget_GameMode
            ChangeGameMode()
            
          Case #Gadget_PowerupMode
            ChangePowerupMode()
            
          Case #Gadget_UsePowerup1
            UsePowerup1()
            
          Case #Gadget_UsePowerup2
            UsePowerup2()
              
        EndSelect
        
      Case #PB_Event_CloseWindow
        ExitGame()
    EndSelect
  ForEver
EndIf
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 109
; FirstLine = 87
; Folding = --------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; UseIcon = tictactoe.ico
; Executable = ..\TicTacToe.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,3
; VersionField1 = 1,0,0,3
; VersionField2 = ZoneSoft
; VersionField3 = TicTacToe
; VersionField4 = 1.0.0.3
; VersionField5 = 1.0.0.3
; VersionField6 = A full-featured 2-Player TicTacToe game.
; VersionField7 = TicTacToe
; VersionField8 = TicTacToe.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60