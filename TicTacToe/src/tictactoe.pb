EnableExplicit

; === Constants ===
#BOARD_SIZE = 3
#CELL_SIZE = 100
#CANVAS_WIDTH = 300
#CANVAS_HEIGHT = 300
#WINDOW_WIDTH = 560
#WINDOW_HEIGHT = 505
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
If hMutex And GetLastError_() = #ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
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
Global PendingRewind = #False
Global LastMove.Position
Global LastPlayer.s = ""
Global version.s = "v1.0.0.2"

; Power-up arrays
Global Dim Player1Powerups.PowerUp(#MAX_POWERUPS-1)
Global Dim Player2Powerups.PowerUp(#MAX_POWERUPS-1)
Global Player1PowerupCount = 0
Global Player2PowerupCount = 0
Global SelectedPowerup = #POWERUP_NONE

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
  Protected i, j, randomType
  
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
    Player1Powerups(i)\type = randomType
    Player1Powerups(i)\used = #False
    
    Select randomType
      Case #POWERUP_DOUBLE_STRIKE
        Player1Powerups(i)\name = "Double Strike"
        Player1Powerups(i)\description = "Place two symbols in one turn"
      Case #POWERUP_CONVERT
        Player1Powerups(i)\name = "Convert"
        Player1Powerups(i)\description = "Convert opponent's symbol to yours"
      Case #POWERUP_SHIELD
        Player1Powerups(i)\name = "Shield"
        Player1Powerups(i)\description = "Protect one of your symbols"
      Case #POWERUP_BLOCK_ROW
        Player1Powerups(i)\name = "Block"
        Player1Powerups(i)\description = "Block opponent's next move in a row"
      Case #POWERUP_ROTATE_BOARD
        Player1Powerups(i)\name = "Rotate"
        Player1Powerups(i)\description = "Rotate the entire board 90°"
      Case #POWERUP_REWIND
        Player1Powerups(i)\name = "Rewind"
        Player1Powerups(i)\description = "Undo the last move"
      Case #POWERUP_STEAL
        Player1Powerups(i)\name = "Steal"
        Player1Powerups(i)\description = "Steal opponent's unused power-up"
      Case #POWERUP_BOMB
        Player1Powerups(i)\name = "Bomb"
        Player1Powerups(i)\description = "Clear area and place symbol"
    EndSelect
  Next
  
  ; Initialize Player 2/AI power-ups
  For i = 0 To #MAX_POWERUPS-1
    randomType = powerupTypes(Random(7))
    Player2Powerups(i)\type = randomType
    Player2Powerups(i)\used = #False
    
    Select randomType
      Case #POWERUP_DOUBLE_STRIKE
        Player2Powerups(i)\name = "Double Strike"
        Player2Powerups(i)\description = "Place two symbols in one turn"
      Case #POWERUP_CONVERT
        Player2Powerups(i)\name = "Convert"
        Player2Powerups(i)\description = "Convert opponent's symbol to yours"
      Case #POWERUP_SHIELD
        Player2Powerups(i)\name = "Shield"
        Player2Powerups(i)\description = "Protect one of your symbols"
      Case #POWERUP_BLOCK_ROW
        Player2Powerups(i)\name = "Block"
        Player2Powerups(i)\description = "Block opponent's next move in a row"
      Case #POWERUP_ROTATE_BOARD
        Player2Powerups(i)\name = "Rotate"
        Player2Powerups(i)\description = "Rotate the entire board 90°"
      Case #POWERUP_REWIND
        Player2Powerups(i)\name = "Rewind"
        Player2Powerups(i)\description = "Undo the last move"
      Case #POWERUP_STEAL
        Player2Powerups(i)\name = "Steal"
        Player2Powerups(i)\description = "Steal opponent's unused power-up"
      Case #POWERUP_BOMB
        Player2Powerups(i)\name = "Bomb"
        Player2Powerups(i)\description = "Clear area and place symbol"
    EndSelect
  Next
  
  UpdatePowerupLists()
EndProcedure

; === Drawing Procedures ===
Procedure DrawBoard()
  Protected x, y
  
  StartDrawing(CanvasOutput(#Canvas_Game))
  
  ; Clear background
  Box(0, 0, #CANVAS_WIDTH, #CANVAS_HEIGHT, $FFFFFF)
  
  ; Draw grid lines
  For x = 1 To #BOARD_SIZE-1
    Line(x * #CELL_SIZE, 0, 1, #CANVAS_HEIGHT, $808080)
  Next
  For y = 1 To #BOARD_SIZE-1
    Line(0, y * #CELL_SIZE, #CANVAS_WIDTH, 1, $808080)
  Next
  
  ; Draw special cell states
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      ; Draw blocked cells
      If BlockedBoard(x, y)
        Box(x * #CELL_SIZE + 2, y * #CELL_SIZE + 2, #CELL_SIZE - 4, #CELL_SIZE - 4, $FF0000)
      EndIf
      
      ; Draw shielded cells
      If ShieldBoard(x, y)
        Box(x * #CELL_SIZE + 2, y * #CELL_SIZE + 2, #CELL_SIZE - 4, #CELL_SIZE - 4, $00FF00)
      EndIf
    Next
  Next
  
  ; Draw hover effect
  If Not GameOver And HoverX >= 0 And HoverY >= 0 And IsValidPosition(HoverX, HoverY) And Board(HoverX, HoverY) = "" And Not BlockedBoard(HoverX, HoverY)
    Box(HoverX * #CELL_SIZE + 2, HoverY * #CELL_SIZE + 2, #CELL_SIZE - 4, #CELL_SIZE - 4, $808080)
  EndIf
  
  ; Draw symbols
  DrawingFont(FontID(0))
  DrawingMode(#PB_2DDrawing_Transparent)
  
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = "X"
        DrawText(x * #CELL_SIZE + 20, y * #CELL_SIZE + 5, "X", $0000FF)
      ElseIf Board(x, y) = "O"
        DrawText(x * #CELL_SIZE + 20, y * #CELL_SIZE + 5, "O", $FF0000)
      EndIf
    Next
  Next
  
  StopDrawing()
EndProcedure

Procedure AnimateSymbol(symbol.s, x, y, color)
  Protected i, alpha
  
  For i = 10 To 0 Step -1
    StartDrawing(CanvasOutput(#Canvas_Game))
    
    ; Clear cell
    DrawingMode(#PB_2DDrawing_Default)
    Box(x * #CELL_SIZE + 2, y * #CELL_SIZE + 2, #CELL_SIZE - 4, #CELL_SIZE - 4, $FFFFFF)
    
    ; Draw symbol
    DrawingMode(#PB_2DDrawing_Transparent)
    DrawingFont(FontID(0))
    DrawText(x * #CELL_SIZE + 20, y * #CELL_SIZE + 5, symbol, color)
    
    ; Add fade effect
    If i > 0
      DrawingMode(#PB_2DDrawing_AlphaBlend)
      alpha = RGBA($FF, $FF, $FF, i * 20)
      Box(x * #CELL_SIZE + 2, y * #CELL_SIZE + 2, #CELL_SIZE - 4, #CELL_SIZE - 4, alpha)
    EndIf
    
    StopDrawing()
    Delay(AnimationSpeed)
  Next
EndProcedure

Procedure AnimateWinningLine(winner.s)
  Protected i, j, x, y, color
  
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
        Box(x * #CELL_SIZE + 2, y * #CELL_SIZE + 2, #CELL_SIZE - 4, #CELL_SIZE - 4, color)
      Else
        Box(x * #CELL_SIZE + 2, y * #CELL_SIZE + 2, #CELL_SIZE - 4, #CELL_SIZE - 4, $FFFFFF)
      EndIf
      
      ; Redraw the symbol in the cell
      DrawingMode(#PB_2DDrawing_Transparent)
      DrawingFont(FontID(0))
      
      If Board(x, y) = "X"
        DrawText(x * #CELL_SIZE + 20, y * #CELL_SIZE + 5, "X", $0000FF)
      ElseIf Board(x, y) = "O"
        DrawText(x * #CELL_SIZE + 20, y * #CELL_SIZE + 5, "O", $FF0000)
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
      Box(x * #CELL_SIZE + 2, y * #CELL_SIZE + 2, #CELL_SIZE - 4, #CELL_SIZE - 4, $6699FF)  ; Light blue
    Else
      Box(x * #CELL_SIZE + 2, y * #CELL_SIZE + 2, #CELL_SIZE - 4, #CELL_SIZE - 4, $FF9966)  ; Light red
    EndIf
    
    ; Redraw the symbol
    DrawingMode(#PB_2DDrawing_Transparent)
    DrawingFont(FontID(0))
    
    If Board(x, y) = "X"
      DrawText(x * #CELL_SIZE + 20, y * #CELL_SIZE + 5, "X", $0000FF)
    ElseIf Board(x, y) = "O"
      DrawText(x * #CELL_SIZE + 20, y * #CELL_SIZE + 5, "O", $FF0000)
    EndIf
    
    DrawingMode(#PB_2DDrawing_Default)
  Next
  
  StopDrawing()
EndProcedure

; === Power-up Procedures ===
Procedure RotateBoard()
  Protected Dim newBoard.s(#BOARD_SIZE-1, #BOARD_SIZE-1)
  Protected x, y
  
  ; Rotate board 90 degrees clockwise
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      newBoard(#BOARD_SIZE-1-y, x) = Board(x, y)
    Next
  Next
  
  ; Copy back
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      Board(x, y) = newBoard(x, y)
    Next
  Next
EndProcedure

Procedure ExecutePowerup(powerupType, player.s)
  Protected x, y, found = #False
  Protected swapX, swapY
  
  Select powerupType
    Case #POWERUP_DOUBLE_STRIKE
      DoubleStrikeActive = #True
      DoubleStrikeCount = 0
      SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' activated Double Strike! Place two symbols.")
      
    Case #POWERUP_CONVERT
      ; Find opponent's symbol to swap
      For y = 0 To #BOARD_SIZE-1
        For x = 0 To #BOARD_SIZE-1
          If (player = "X" And Board(x, y) = "O") Or (player = "O" And Board(x, y) = "X")
            If Not ShieldBoard(x, y)
              Board(x, y) = player
              SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' used Convert!")
              found = #True
              Break 2
            EndIf
          EndIf
        Next
      Next
      If Not found
        SetGadgetText(#Gadget_PowerupStatus, "No symbols to convert!")
      EndIf
      
    Case #POWERUP_SHIELD
      ; Shield the first symbol found
      For y = 0 To #BOARD_SIZE-1
        For x = 0 To #BOARD_SIZE-1
          If Board(x, y) = player
            ShieldBoard(x, y) = #True
            SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' shielded a symbol!")
            found = #True
            Break 2
          EndIf
        Next
      Next
      If Not found
        SetGadgetText(#Gadget_PowerupStatus, "No symbols to shield!")
      EndIf
      
    Case #POWERUP_BLOCK_ROW
      ; Block first row with opponent's symbol
      For y = 0 To #BOARD_SIZE-1
        For x = 0 To #BOARD_SIZE-1
          If Board(x, y) = "" And Not BlockedBoard(x, y)
            BlockedBoard(x, y) = #True
            SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' blocked a cell!")
            found = #True
            Break 2
          EndIf
        Next
      Next
      If Not found
        SetGadgetText(#Gadget_PowerupStatus, "No cells to block!")
      EndIf
      
    Case #POWERUP_ROTATE_BOARD
      RotateBoard()
      SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' rotated the board!")
      
    Case #POWERUP_REWIND
      If LastPlayer <> ""
        Board(LastMove\x, LastMove\y) = ""
        SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' rewound the last move!")
        LastPlayer = ""
      Else
        SetGadgetText(#Gadget_PowerupStatus, "No move to rewind!")
      EndIf
      
    Case #POWERUP_STEAL
      ; Simple steal - just show message (implementation would be more complex)
      SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' used Steal power-up!")
      
    Case #POWERUP_BOMB
      ; Clear center and place symbol
      If Board(1, 1) = ""
        Board(1, 1) = player
        SetGadgetText(#Gadget_PowerupStatus, "'" + player + "' used Bomb in center!")
      Else
        SetGadgetText(#Gadget_PowerupStatus, "Center already occupied!")
      EndIf
  EndSelect
EndProcedure

; === Game Logic ===
Procedure.s CheckWinner()
  Protected i, j
  
  ; Clear winning line
  WinningLineCount = 0
  
  ; Check rows
  For i = 0 To #BOARD_SIZE-1
    If Board(i, 0) <> "" And Board(i, 0) = Board(i, 1) And Board(i, 0) = Board(i, 2)
      ; Store winning line positions
      WinningLine(0)\x = i : WinningLine(0)\y = 0
      WinningLine(1)\x = i : WinningLine(1)\y = 1
      WinningLine(2)\x = i : WinningLine(2)\y = 2
      WinningLineCount = 3
      ProcedureReturn Board(i, 0)
    EndIf
  Next
  
  ; Check columns
  For i = 0 To #BOARD_SIZE-1
    If Board(0, i) <> "" And Board(0, i) = Board(1, i) And Board(0, i) = Board(2, i)
      ; Store winning line positions
      WinningLine(0)\x = 0 : WinningLine(0)\y = i
      WinningLine(1)\x = 1 : WinningLine(1)\y = i
      WinningLine(2)\x = 2 : WinningLine(2)\y = i
      WinningLineCount = 3
      ProcedureReturn Board(0, i)
    EndIf
  Next
  
  ; Check diagonals
  If Board(0, 0) <> "" And Board(0, 0) = Board(1, 1) And Board(0, 0) = Board(2, 2)
     ; Store winning line positions
    WinningLine(0)\x = 0 : WinningLine(0)\y = 0
    WinningLine(1)\x = 1 : WinningLine(1)\y = 1
    WinningLine(2)\x = 2 : WinningLine(2)\y = 2
    WinningLineCount = 3
    ProcedureReturn Board(0, 0)
  EndIf
  If Board(2, 0) <> "" And Board(2, 0) = Board(1, 1) And Board(2, 0) = Board(0, 2)
    ; Store winning line positions
    WinningLine(0)\x = 2 : WinningLine(0)\y = 0
    WinningLine(1)\x = 1 : WinningLine(1)\y = 1
    WinningLine(2)\x = 0 : WinningLine(2)\y = 2
    WinningLineCount = 3
    ProcedureReturn Board(2, 0)
  EndIf
  
  ; Check for draw
  If IsBoardFull()
    ProcedureReturn "Draw"
  EndIf
  
  ProcedureReturn ""
EndProcedure

Procedure CountWinningMoves(player.s)
  Protected count = 0, x, y, original.s
  
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = "" And Not BlockedBoard(x, y)
        original = Board(x, y)
        Board(x, y) = player
        If CheckWinner() = player
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
  Protected bestX = -1, bestY = -1, x, y, original.s
  Protected bestScore = -1000, score
  
  ; Try to win
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = "" And Not BlockedBoard(x, y)
        original = Board(x, y)
        Board(x, y) = "O"
        If CheckWinner() = "O"
          Board(x, y) = original
          bestX = x : bestY = y
          ProcedureReturn (bestY << 16) | bestX
        EndIf
        Board(x, y) = original
      EndIf
    Next
  Next
  
  ; Block opponent from winning
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = "" And Not BlockedBoard(x, y)
        original = Board(x, y)
        Board(x, y) = "X"
        If CheckWinner() = "X"
          Board(x, y) = original
          bestX = x : bestY = y
          ProcedureReturn (bestY << 16) | bestX
        EndIf
        Board(x, y) = original
      EndIf
    Next
  Next
  
  ; Strategic moves based on difficulty
  Select Difficulty
    Case #DIFF_HARD
      ; Take center if available
      If Board(1, 1) = "" And Not BlockedBoard(1, 1)
        bestX = 1 : bestY = 1
        ProcedureReturn (bestY << 16) | bestX
      EndIf
      
      ; Take corners
      If Board(0, 0) = "" And Not BlockedBoard(0, 0) : bestX = 0 : bestY = 0 : ProcedureReturn (bestY << 16) | bestX : EndIf
      If Board(2, 0) = "" And Not BlockedBoard(2, 0) : bestX = 2 : bestY = 0 : ProcedureReturn (bestY << 16) | bestX : EndIf
      If Board(0, 2) = "" And Not BlockedBoard(0, 2) : bestX = 0 : bestY = 2 : ProcedureReturn (bestY << 16) | bestX : EndIf
      If Board(2, 2) = "" And Not BlockedBoard(2, 2) : bestX = 2 : bestY = 2 : ProcedureReturn (bestY << 16) | bestX : EndIf
      
    Case #DIFF_MEDIUM
      ; Sometimes take center
      If Board(1, 1) = "" And Not BlockedBoard(1, 1) And Random(1)
        bestX = 1 : bestY = 1
        ProcedureReturn (bestY << 16) | bestX
      EndIf
  EndSelect
  
  ; Take any available move
  For y = 0 To #BOARD_SIZE-1
    For x = 0 To #BOARD_SIZE-1
      If Board(x, y) = "" And Not BlockedBoard(x, y)
        bestX = x : bestY = y
        ProcedureReturn (bestY << 16) | bestX
      EndIf
    Next
  Next
  
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
      ExecutePowerup(Player2Powerups(bestPowerup)\type, "O")
      Player2Powerups(bestPowerup)\used = #True
      UpdatePowerupLists()
      DrawBoard()
      Delay(1000)
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
    
    AnimateSymbol("O", x, y, $808080)
    Board(x, y) = "O"
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
      AnimateSymbol("X", x, y, $808080)
      Board(x, y) = "X"
    Else
      AnimateSymbol("O", x, y, $808080)
      Board(x, y) = "O"
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
    
    ; Check for game end
    result = CheckWinner()
    If result <> ""
      DrawBoard()
      EndGame(result)
      ProcedureReturn
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
  
  ; Reset scores when switching modes
  Player1Score = 0
  Player2Score = 0
  Draws = 0
  
  UpdateScoreDisplay()
  ResetGame()
EndProcedure

Procedure ChangePowerupMode()
  PowerupMode = GetGadgetState(#Gadget_PowerupMode)
  
  ; Enable/disable power-up controls
  DisableGadget(#Gadget_Player1PowerupList, #False)
  DisableGadget(#Gadget_Player2PowerupList, #False)
  DisableGadget(#Gadget_UsePowerup1, #False)
  DisableGadget(#Gadget_UsePowerup2, #False)
  
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
  If CurrentPlayer <> "X" And GameMode = #MODE_VS_AI : ProcedureReturn : EndIf
  
  Protected selectedIndex = GetGadgetState(#Gadget_Player1PowerupList)
  If selectedIndex >= 0 And selectedIndex < #MAX_POWERUPS And Not Player1Powerups(selectedIndex)\used
    ExecutePowerup(Player1Powerups(selectedIndex)\type, "X")
    Player1Powerups(selectedIndex)\used = #True
    UpdatePowerupLists()
    DrawBoard()
  EndIf
EndProcedure

Procedure UsePowerup2()
  If Not PowerupMode Or GameOver : ProcedureReturn : EndIf
  If GameMode = #MODE_VS_AI : ProcedureReturn : EndIf ; AI handles its own power-ups
  If CurrentPlayer <> "O" : ProcedureReturn : EndIf
  
  Protected selectedIndex = GetGadgetState(#Gadget_Player2PowerupList)
  If selectedIndex >= 0 And selectedIndex < #MAX_POWERUPS And Not Player2Powerups(selectedIndex)\used
    ExecutePowerup(Player2Powerups(selectedIndex)\type, "O")
    Player2Powerups(selectedIndex)\used = #True
    UpdatePowerupLists()
    DrawBoard()
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
    End
  EndIf
EndProcedure

; === Main Program ===
If OpenWindow(#Window_Main, 0, 0, #WINDOW_WIDTH, #WINDOW_HEIGHT, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  
  ; Create game canvas and basic controls
  CanvasGadget(#Canvas_Game, 10, 10, #CANVAS_WIDTH-60, #CANVAS_HEIGHT-60)
  StringGadget(#Gadget_Status, 10, 260, 240, 20, "Player 1 move... Good luck!", #PB_String_ReadOnly)
  StringGadget(#Gadget_Score, 10, 290, 240, 20, "", #PB_String_ReadOnly)
  ButtonGadget(#Gadget_Reset, 10, 320, 115, 25, "Reset")
  ButtonGadget(#Gadget_Help, 135, 320, 115, 25, "Help")
  
  ; Game mode selector
  TextGadget(#PB_Any, 10, 358, 50, 20, "Player 1")
  ComboBoxGadget(#Gadget_GameMode, 60, 355, 90, 25)
  AddGadgetItem(#Gadget_GameMode, -1, "vs AI Player")
  AddGadgetItem(#Gadget_GameMode, -1, "vs Player 2")
  SetGadgetState(#Gadget_GameMode, #MODE_VS_AI)
  
  ; Difficulty selector
  TextGadget(#PB_Any, 10, 392, 60, 20, "Difficulty:")
  ComboBoxGadget(#Gadget_Difficulty, 70, 390, 80, 25)
  AddGadgetItem(#Gadget_Difficulty, -1, "Easy")
  AddGadgetItem(#Gadget_Difficulty, -1, "Medium")
  AddGadgetItem(#Gadget_Difficulty, -1, "Hard")
  SetGadgetState(#Gadget_Difficulty, #DIFF_MEDIUM)
  
  ; Power-up mode selector
  CheckBoxGadget(#Gadget_PowerupMode, 10, 425, 120, 20, "Enable Power-ups")
  
  ; Power-up status
  TextGadget(#PB_Any, 10, 450, 100, 20, "Power-up Status:")
  StringGadget(#Gadget_PowerupStatus, 10, 470, 540, 20, "", #PB_String_ReadOnly)
  
  ; Power-up panels
  TextGadget(#PB_Any, 260, 10, 100, 20, "Player 1 Power-ups:")
  ListViewGadget(#Gadget_Player1PowerupList, 260, 30, 290, 80)
  ButtonGadget(#Gadget_UsePowerup1, 260, 115, 290, 25, "Use Selected Power-up")
  
  TextGadget(#PB_Any, 260, 150, 100, 20, "Player 2 Power-ups:")
  ListViewGadget(#Gadget_Player2PowerupList, 260, 170, 290, 80)
  ButtonGadget(#Gadget_UsePowerup2, 260, 255, 290, 25, "Use Selected Power-up")
  
  ; Instructions
  TextGadget(#PB_Any, 260, 285, 290, 180, "Power-up Legend:" + Chr(10) + "Green cells = Shielded" + Chr(10) + "Red cells = Blocked" + 
                                          Chr(10) + "Double Strike = Place 2 symbols" + Chr(10) + "Convert = Convert opponent's symbol" +
                                          Chr(10) + "Shield = Protect your symbol" + Chr(10) + "Block = Block opponent's next move in a row" +
                                          Chr(10) + "Rotate = Rotate the entire board 90°" + Chr(10) + "Rewind = Undo the last move" +
                                          Chr(10) + "Steal = Steal opponent's unused power-up" + Chr(10) + "Bomb = Clear area and place symbol", #PB_Text_Center)
  
  ; Load fonts
  LoadFont(0, "Arial", 50, #PB_Font_Bold)
  LoadFont(1, "Arial", 10, #PB_Font_Bold)
  LoadFont(2, "Arial", 9, #PB_Font_Bold)
  LoadFont(3, "Arial", 8)
  
  ; Set gadget fonts
  SetGadgetFont(#Gadget_Status, FontID(1))
  SetGadgetFont(#Gadget_Score, FontID(2))
  SetGadgetFont(#Gadget_PowerupStatus, FontID(2))
  
  ; Initialize game
  DisableGadget(#Gadget_Player1PowerupList, #True)
  DisableGadget(#Gadget_Player2PowerupList, #True)
  DisableGadget(#Gadget_UsePowerup1, #True)
  DisableGadget(#Gadget_UsePowerup2, #True)
  
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
; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 98
; FirstLine = 84
; Folding = -----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = tictactoe.ico
; Executable = ..\TicTacToe.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = TicTacToe
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = A full-featured 2-Player TicTacToe game.
; VersionField7 = TicTacToe
; VersionField8 = TicTacToe.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60