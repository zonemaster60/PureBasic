; ====================================
; 3D Yahtzee Game - Player vs AI/Network
; ====================================

EnableExplicit

#APP_NAME = "Yahtzee_3D"

Global version.s = "v1.0.0.0"
Global AppPath.s        = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; Constants
#WINDOW_WIDTH = 1920
#WINDOW_HEIGHT = 1080
#NUM_DICE = 5
#MAX_ROLLS = 3
#NUM_CATEGORIES = 13
#FULLSCREEN = #False ; Set to #False for windowed mode
#DEBUG_TESTS = #False ; Set True to run self-tests at startup
#NETWORK_PORT = 7331

; AI Difficulty levels
Enumeration
  #AI_EASY
  #AI_MEDIUM
  #AI_HARD
EndEnumeration

; Network packet types
Enumeration
  #PKT_CONNECT
  #PKT_ROLL_DICE
  #PKT_HOLD_DICE
  #PKT_SCORE
  #PKT_TURN_END
  #PKT_GAME_STATE
  #PKT_CHAT
EndEnumeration

; Game modes
Enumeration
  #MODE_VS_AI
  #MODE_HOST
  #MODE_JOIN
EndEnumeration

; Structures
Structure DiceType
  value.i
  mesh.i
  entity.i
  rolling.i
  held.i
  targetRotX.f
  targetRotY.f
  targetRotZ.f
  currentRotX.f
  currentRotY.f
  currentRotZ.f
  x.f
  y.f
  z.f
EndStructure

Structure ScoreCategoryType
  name.s
  playerScore.i
  aiScore.i
  playerUsed.i
  aiUsed.i
EndStructure

Structure GameStateType
  currentPlayer.i ; 0 = Player, 1 = AI/Opponent
  rollsLeft.i
  diceValues.i[#NUM_DICE]
  diceHeld.i[#NUM_DICE]
  playerTotalScore.i
  aiTotalScore.i
  round.i
  gameOver.i
  message.s
  showingDiceRoll.i
  rollAnimTime.f
  aiDifficulty.i ; #AI_EASY, #AI_MEDIUM, or #AI_HARD
  inMenu.i       ; Menu state
  menuSelection.i ; 0=Start, 1=Multiplayer, 2=Difficulty, 3=Fullscreen, 4=Exit
  gameMode.i     ; #MODE_VS_AI, #MODE_HOST, #MODE_JOIN
  networkActive.i
  opponentName.s
EndStructure

Structure NetworkStateType
  serverID.i
  clientID.i
  isHost.i
  connected.i
  opponentConnected.i
EndStructure

; Global Variables
Global Dim Dice.DiceType(#NUM_DICE - 1)
Global Dim Categories.ScoreCategoryType(#NUM_CATEGORIES - 1)
Global GameState.GameStateType
Global NetworkState.NetworkStateType
Global Camera, Light
Global Font1, Font2, Font3, Font4
Global Dim KeyPressed.i(5)  ; Track key states to prevent bouncing
Global KeyDPressed.i = 0     ; Track D key state
Global KeyEnterPressed.i = 0 ; Track Enter key state
Global KeyUpPressed.i = 0    ; Track Up arrow key state
Global KeyDownPressed.i = 0  ; Track Down arrow key state
Global KeySpacePressed.i = 0 ; Track Spacebar state

; Edge detection (robust against repeat/delay)
Global PrevSpaceDown.i
Global PrevEnterDown.i
Global PrevDDown.i
Global PrevUpDown.i
Global PrevDownDown.i
Global PrevLeftDown.i
Global PrevRightDown.i
Global Dim PrevDigitDown.i(9)  ; 0..9 (also reused for 1..5 controls)
Global PrevPeriodDown.i

; LAN scan state (menu submenu)
Global Dim LanHostList.s(0)
Global LanHostCount.i
Global LanScanActive.i
Global LanScanPrefix.s
Global LanScanIndex.i
Global PrevHDown.i
Global PrevJDown.i
Global PrevSDown.i
Global PrevEscDown.i
Global IsFullscreen.i = #FULLSCREEN
Global PlayerName.s = "Player1"
Global ServerIP.s = "127.0.0.1"
Global HostIP.s = ""
Global LastJoinedIP.s = ""


; Category names
Procedure StartLanScan(prefix.s)
  LanScanPrefix = prefix
  LanScanIndex = 1
  LanScanActive = 1
  LanHostCount = 0
  ReDim LanHostList.s(0)
EndProcedure

Procedure ContinueLanScanStep()
  If LanScanActive = 0 : ProcedureReturn : EndIf

  Protected ip.s = LanScanPrefix + Str(LanScanIndex)
  Protected conn.i = OpenNetworkConnection(ip, #NETWORK_PORT, 80)

  If conn
    CloseNetworkConnection(conn)
    LanHostCount + 1
    ReDim LanHostList.s(LanHostCount)
    LanHostList(LanHostCount) = ip
  EndIf

  LanScanIndex + 1
  If LanScanIndex > 254
    LanScanActive = 0
  EndIf
EndProcedure

Procedure InitializeCategories()
  Categories(0)\name = "Ones"
  Categories(1)\name = "Twos"
  Categories(2)\name = "Threes"
  Categories(3)\name = "Fours"
  Categories(4)\name = "Fives"
  Categories(5)\name = "Sixes"
  Categories(6)\name = "Three of a Kind"
  Categories(7)\name = "Four of a Kind"
  Categories(8)\name = "Full House"
  Categories(9)\name = "Small Straight"
  Categories(10)\name = "Large Straight"
  Categories(11)\name = "Yahtzee"
  Categories(12)\name = "Chance"
EndProcedure

; Network: Send packet
Procedure SendPacket(packetType.i, dataStr.s = "")
  Protected *buffer, bufferSize.i

  ; Simple packet = 1 byte type + UTF-8 string (null-terminated)
  bufferSize = 1 + StringByteLength(dataStr, #PB_UTF8) + 1
  *buffer = AllocateMemory(bufferSize)

  If *buffer
    PokeA(*buffer, packetType)
    If dataStr <> ""
      PokeS(*buffer + 1, dataStr, -1, #PB_UTF8)
    Else
      PokeA(*buffer + 1, 0)
    EndIf

    If NetworkState\isHost And NetworkState\clientID
      SendNetworkData(NetworkState\clientID, *buffer, bufferSize)
    ElseIf Not NetworkState\isHost And NetworkState\serverID
      SendNetworkData(NetworkState\serverID, *buffer, bufferSize)
    EndIf

    FreeMemory(*buffer)
  EndIf
EndProcedure

; Network: Receive and process packets
Procedure ProcessNetworkPackets()
  Protected event.i, clientID.i
  Protected *buffer, bytes.i
  Protected packetType.a, dataStr.s

  If NetworkState\isHost And NetworkState\serverID
    event = NetworkServerEvent(NetworkState\serverID)

    Select event
      Case #PB_NetworkEvent_Connect
        clientID = EventClient()
        If Not NetworkState\opponentConnected
          NetworkState\clientID = clientID
          NetworkState\opponentConnected = 1
          GameState\message = "Opponent connected! Game starting..."

          ; Send our name to opponent
          SendPacket(#PKT_CONNECT, PlayerName)

          ; Reset game state for multiplayer start
          GameState\currentPlayer = 0  ; Host starts first
          GameState\round = 1
          GameState\rollsLeft = #MAX_ROLLS
          GameState\gameOver = 0
        Else
          CloseNetworkConnection(clientID) ; Only allow one opponent
        EndIf

      Case #PB_NetworkEvent_Data
        clientID = EventClient()

        ; Read up to a fixed buffer (simple protocol: 1 byte + optional UTF-8 string)
        ; Note: This still assumes one packet per Receive call; for robust networking,
        ; add length framing and an accumulator buffer.
        *buffer = AllocateMemory(4096)
        If *buffer
          bytes = ReceiveNetworkData(clientID, *buffer, 4096)
          If bytes > 0
            packetType = PeekA(*buffer)

            Select packetType
              Case #PKT_CONNECT
                GameState\opponentName = PeekS(*buffer + 1, -1, #PB_UTF8)

              Case #PKT_ROLL_DICE
                ; Opponent rolled - update their dice (not implemented)

              Case #PKT_SCORE
                ; Opponent scored - update their scorecard
                dataStr = PeekS(*buffer + 1, -1, #PB_UTF8)
                Protected catPos = FindString(dataStr, ",", 1)
                If catPos
                  Protected cat = Val(Left(dataStr, catPos - 1))
                  Protected scr = Val(Mid(dataStr, catPos + 1))
                  If cat >= 0 And cat < #NUM_CATEGORIES
                    Categories(cat)\aiScore = scr
                    Categories(cat)\aiUsed = 1
                    GameState\message = "Opponent scored " + Str(scr) + " in " + Categories(cat)\name
                  EndIf
                EndIf

              Case #PKT_TURN_END
                ; Opponent (client) finished turn, switch to host's turn (me)
                GameState\currentPlayer = 0
                GameState\rollsLeft = #MAX_ROLLS

                ; When client ends its turn, host advances to next round.
                GameState\round = GameState\round + 1
                If GameState\round > 13
                  GameState\gameOver = 1
                EndIf


            EndSelect
          EndIf

          FreeMemory(*buffer)
        EndIf

      Case #PB_NetworkEvent_Disconnect
        NetworkState\opponentConnected = 0
        GameState\message = "Opponent disconnected!"
    EndSelect

  ElseIf Not NetworkState\isHost And NetworkState\serverID
    event = NetworkClientEvent(NetworkState\serverID)

    Select event
      Case #PB_NetworkEvent_Data
        *buffer = AllocateMemory(4096)
        If *buffer
          bytes = ReceiveNetworkData(NetworkState\serverID, *buffer, 4096)
          If bytes > 0
            packetType = PeekA(*buffer)

            Select packetType
            Case #PKT_CONNECT
              GameState\opponentName = PeekS(*buffer + 1, -1, #PB_UTF8)
              NetworkState\connected = 1

              ; Request a state snapshot so we can join mid-game
              ; Client initializes game state when receiving connection confirm
              GameState\currentPlayer = 0  ; Host goes first
              GameState\round = 1
              GameState\rollsLeft = #MAX_ROLLS
              GameState\gameOver = 0
              GameState\message = "Connected! Waiting for host to start..."

              Case #PKT_ROLL_DICE
                ; Host rolled (not implemented)

              Case #PKT_SCORE
                ; Host scored
                dataStr = PeekS(*buffer + 1, -1, #PB_UTF8)
                Protected catPos2 = FindString(dataStr, ",", 1)
                If catPos2
                  Protected cat2 = Val(Left(dataStr, catPos2 - 1))
                  Protected scr2 = Val(Mid(dataStr, catPos2 + 1))
                  If cat2 >= 0 And cat2 < #NUM_CATEGORIES
                    Categories(cat2)\aiScore = scr2
                    Categories(cat2)\aiUsed = 1
                    GameState\message = "Opponent scored " + Str(scr2) + " in " + Categories(cat2)\name
                  EndIf
                EndIf

              Case #PKT_TURN_END
                ; Opponent (host) finished turn, switch to client's turn (me)
                GameState\currentPlayer = 1
                GameState\rollsLeft = #MAX_ROLLS

                ; Client receives round number from host
                dataStr = PeekS(*buffer + 1, -1, #PB_UTF8)
                If dataStr <> ""
                  GameState\round = Val(dataStr)
                  If GameState\round > 13
                    GameState\gameOver = 1
                  EndIf
                EndIf


            EndSelect
          EndIf

          FreeMemory(*buffer)
        EndIf

      Case #PB_NetworkEvent_Disconnect
        NetworkState\connected = 0
        GameState\message = "Disconnected from host!"
    EndSelect
  EndIf
EndProcedure

Procedure.s GetPrivateIPv4FromIPConfigLine(line.s)
  Protected pos = FindString(line, ":", 1)
  Protected ip.s

  If pos = 0 : ProcedureReturn "" : EndIf
  ip = Trim(Mid(line, pos + 1))

  ; Filter obvious non-LAN values
  If Left(ip, 8) = "169.254." : ProcedureReturn "" : EndIf
  If ip = "0.0.0.0" : ProcedureReturn "" : EndIf

  ; Prefer private ranges
  If Left(ip, 8) = "192.168." Or Left(ip, 4) = "10." Or Left(ip, 4) = "172."
    ProcedureReturn ip
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s GetLocalIPAddress()
  Protected tempFile.s = GetTemporaryDirectory() + "ip.txt"
  Protected ip.s = ""

  RunProgram("cmd.exe", "/c ipconfig | findstr /i " + Chr(34) + "IPv4" + Chr(34) + " > " + Chr(34) + tempFile + Chr(34), "", #PB_Program_Wait | #PB_Program_Hide)

  If ReadFile(0, tempFile)
    While Eof(0) = 0
      Protected line.s = ReadString(0)
      Protected candidate.s = GetPrivateIPv4FromIPConfigLine(line)
      If candidate <> ""
        ip = candidate
        Break
      EndIf
    Wend
    CloseFile(0)
  EndIf

  DeleteFile(tempFile)
  ProcedureReturn ip
EndProcedure

; Network: Host game
Procedure HostGame()
  NetworkState\serverID = CreateNetworkServer(#PB_Any, #NETWORK_PORT)
  
  If NetworkState\serverID
    NetworkState\isHost = 1
    GameState\networkActive = 1
    GameState\gameMode = #MODE_HOST
    
    HostIP = GetLocalIPAddress()
    If HostIP = ""
      HostIP = "127.0.0.1 (Check your IP manually)"
    EndIf
    
    GameState\message = "Hosting on " + HostIP + ":" + Str(#NETWORK_PORT) + " - Waiting for opponent"
    ProcedureReturn #True
  Else
    GameState\message = "Failed to host server!"
    ProcedureReturn #False
  EndIf
EndProcedure

; Network: Join game
Procedure JoinGame(ip.s)
  NetworkState\serverID = OpenNetworkConnection(ip, #NETWORK_PORT)
  
  If NetworkState\serverID
    NetworkState\isHost = 0
    NetworkState\connected = 1
    GameState\networkActive = 1
    GameState\gameMode = #MODE_JOIN
    SendPacket(#PKT_CONNECT, PlayerName)
    GameState\message = "Connected to " + ip
    ProcedureReturn #True
  Else
    GameState\message = "Failed to connect to " + ip
    ProcedureReturn #False
  EndIf
EndProcedure

; Network: Disconnect
Procedure DisconnectNetwork()
  If NetworkState\isHost
    ; Host: close client connection and server
    If NetworkState\clientID
      CloseNetworkConnection(NetworkState\clientID)
      NetworkState\clientID = 0
    EndIf
    If NetworkState\serverID
      CloseNetworkServer(NetworkState\serverID)
      NetworkState\serverID = 0
    EndIf
  Else
    ; Client: close connection to server
    If NetworkState\serverID
      CloseNetworkConnection(NetworkState\serverID)
      NetworkState\serverID = 0
    EndIf
  EndIf
  
  NetworkState\connected = 0
  NetworkState\opponentConnected = 0
  NetworkState\isHost = 0
  GameState\networkActive = 0
EndProcedure

; Calculate score for a category
Procedure CalculateScore(category.i, Array diceValues.i(1))
  Protected i, j, count, sum, score
  ; Ensure locals start at 0 (PB locals are typically 0, but be explicit)
  sum = 0
  score = 0
  Protected Dim counts(6)
  
  ; Count each value
  For i = 0 To #NUM_DICE - 1
    If diceValues(i) >= 1 And diceValues(i) <= 6
      counts(diceValues(i)) = counts(diceValues(i)) + 1
    EndIf
  Next
  
  ; Calculate sum
  For i = 0 To #NUM_DICE - 1
    sum = sum + diceValues(i)
  Next
  
  Select category
    Case 0 To 5 ; Ones through Sixes
      score = counts(category + 1) * (category + 1)
      
    Case 6 ; Three of a Kind
      For i = 1 To 6
        If counts(i) >= 3
          score = sum
          Break
        EndIf
      Next
      
    Case 7 ; Four of a Kind
      For i = 1 To 6
        If counts(i) >= 4
          score = sum
          Break
        EndIf
      Next
      
    Case 8 ; Full House
      Protected hasThree = #False, hasTwo = #False
      For i = 1 To 6
        If counts(i) = 3 : hasThree = #True : EndIf
        If counts(i) = 2 : hasTwo = #True : EndIf
      Next
      If hasThree And hasTwo : score = 25 : EndIf
      
    Case 9 ; Small Straight
      If (counts(1) >= 1 And counts(2) >= 1 And counts(3) >= 1 And counts(4) >= 1) Or
         (counts(2) >= 1 And counts(3) >= 1 And counts(4) >= 1 And counts(5) >= 1) Or
         (counts(3) >= 1 And counts(4) >= 1 And counts(5) >= 1 And counts(6) >= 1)
        score = 30
      EndIf
      
    Case 10 ; Large Straight
      If (counts(1) = 1 And counts(2) = 1 And counts(3) = 1 And counts(4) = 1 And counts(5) = 1) Or
         (counts(2) = 1 And counts(3) = 1 And counts(4) = 1 And counts(5) = 1 And counts(6) = 1)
        score = 40
      EndIf
      
    Case 11 ; Yahtzee
      For i = 1 To 6
        If counts(i) = 5
          score = 50
          Break
        EndIf
      Next
      
    Case 12 ; Chance
      score = sum
  EndSelect
  
  ProcedureReturn score
EndProcedure

Procedure RunScoreSelfTest()
  Protected Dim t.i(#NUM_DICE - 1)
  Protected ok.i = 1
  Protected got

  ; Yahtzee (12)
  t(0)=6:t(1)=6:t(2)=6:t(3)=6:t(4)=6
  got = CalculateScore(11, t()) : If got <> 50 : Debug "ScoreTest FAIL Yahtzee expected 50 got " + Str(got) : ok = 0 : EndIf

  ; Large straight 1-5
  t(0)=1:t(1)=2:t(2)=3:t(3)=4:t(4)=5
  got = CalculateScore(10, t()) : If got <> 40 : Debug "ScoreTest FAIL LargeStraight expected 40 got " + Str(got) : ok = 0 : EndIf

  ; Small straight 2-5
  t(0)=2:t(1)=3:t(2)=4:t(3)=5:t(4)=5
  got = CalculateScore(9, t()) : If got <> 30 : Debug "ScoreTest FAIL SmallStraight expected 30 got " + Str(got) : ok = 0 : EndIf

  ; Full house 3+2
  t(0)=2:t(1)=2:t(2)=3:t(3)=3:t(4)=3
  got = CalculateScore(8, t()) : If got <> 25 : Debug "ScoreTest FAIL FullHouse expected 25 got " + Str(got) : ok = 0 : EndIf

  ; Three of a kind -> sum
  t(0)=4:t(1)=4:t(2)=4:t(3)=1:t(4)=6
  got = CalculateScore(6, t()) : If got <> 19 : Debug "ScoreTest FAIL ThreeKind expected 19 got " + Str(got) : ok = 0 : EndIf

  ; Four of a kind -> sum
  t(0)=1:t(1)=5:t(2)=5:t(3)=5:t(4)=5
  got = CalculateScore(7, t()) : If got <> 21 : Debug "ScoreTest FAIL FourKind expected 21 got " + Str(got) : ok = 0 : EndIf

  ; Chance -> sum
  t(0)=1:t(1)=2:t(2)=3:t(3)=4:t(4)=6
  got = CalculateScore(12, t()) : If got <> 16 : Debug "ScoreTest FAIL Chance expected 16 got " + Str(got) : ok = 0 : EndIf

  If ok : Debug "ScoreTest OK" : EndIf
EndProcedure

Procedure RunRandomDistributionTest(iterations.i = 50000)
  Protected Dim counts.i(6)
  Protected i, face, total
  Protected start.q = ElapsedMilliseconds()

  If iterations < 1 : ProcedureReturn : EndIf

  For i = 1 To iterations
    face = Random(5) + 1
    counts(face) + 1
  Next

  total = iterations
  Debug "RNGTest rolls=" + Str(iterations) + " (" + Str(ElapsedMilliseconds() - start) + "ms)"
  For face = 1 To 6
    Debug "  " + Str(face) + ": " + Str(counts(face)) + " (" + StrF((counts(face) * 100.0) / total, 2) + "%)"
  Next
EndProcedure


; AI selects best category based on difficulty
Procedure AISelectCategory()
  Protected i, bestCategory, bestScore, score, upperScore
  Protected Dim tempDice.i(#NUM_DICE - 1)
  Protected Dim categoryScores.i(#NUM_CATEGORIES - 1)
  Protected upperTotal = 0
  
  bestCategory = -1
  bestScore = -1
  
  For i = 0 To #NUM_DICE - 1
    tempDice(i) = GameState\diceValues[i]
  Next
  
  ; Calculate scores for all available categories
  For i = 0 To #NUM_CATEGORIES - 1
    If Categories(i)\aiUsed = 0
      categoryScores(i) = CalculateScore(i, tempDice())
    Else
      categoryScores(i) = -1
    EndIf
  Next
  
  ; Check current upper section total
  For i = 0 To 5
    If Categories(i)\aiUsed
      upperTotal = upperTotal + Categories(i)\aiScore
    EndIf
  Next
  
  Select GameState\aiDifficulty
    Case #AI_EASY
      ; Easy: Random available category
      Protected Dim available.i(#NUM_CATEGORIES - 1)
      Protected count = 0
      For i = 0 To #NUM_CATEGORIES - 1
        If Categories(i)\aiUsed = 0
          available(count) = i
          count = count + 1
        EndIf
      Next
      If count > 0
        bestCategory = available(Random(count - 1))
      EndIf
      
    Case #AI_MEDIUM
      ; Medium: Pick highest scoring category, 30% chance of mistake
      If Random(100) < 30
        ; Make a mistake - pick random
        Protected Dim available2.i(#NUM_CATEGORIES - 1)
        Protected count2 = 0
        For i = 0 To #NUM_CATEGORIES - 1
          If Categories(i)\aiUsed = 0
            available2(count2) = i
            count2 = count2 + 1
          EndIf
        Next
        If count2 > 0
          bestCategory = available2(Random(count2 - 1))
        EndIf
      Else
        ; Pick best score
        For i = 0 To #NUM_CATEGORIES - 1
          If categoryScores(i) >= 0
            If categoryScores(i) > bestScore Or bestCategory = -1
              bestScore = categoryScores(i)
              bestCategory = i
            EndIf
          EndIf
        Next
      EndIf
      
    Case #AI_HARD
      ; Hard: Strategic play with bonus consideration
      Protected bonusValue = 0
      
      ; Prioritize upper section if close to bonus
      If upperTotal >= 45 And upperTotal < 63
        For i = 0 To 5
          If categoryScores(i) >= 0
            ; Weight upper section categories higher when close to bonus
            bonusValue = categoryScores(i) + 10
            If bonusValue > bestScore Or bestCategory = -1
              bestScore = bonusValue
              bestCategory = i
            EndIf
          EndIf
        Next
      EndIf
      
      ; If no upper section priority, pick absolute best
      If bestCategory = -1
        For i = 0 To #NUM_CATEGORIES - 1
          If categoryScores(i) >= 0
            ; Bonus special categories
            Protected adjustedScore = categoryScores(i)
            If i = 11 And categoryScores(i) = 50 ; Yahtzee
              adjustedScore = 60
            ElseIf i >= 9 And i <= 10 ; Straights
              adjustedScore = adjustedScore + 5
            EndIf
            
            If adjustedScore > bestScore Or bestCategory = -1
              bestScore = adjustedScore
              bestCategory = i
            EndIf
          EndIf
        Next
      EndIf
  EndSelect
  
  ProcedureReturn bestCategory
EndProcedure

; AI decides which dice to hold based on difficulty
Procedure AIMakeDiceDecision()
  Protected i, j
  Protected Dim counts(6)
  Protected maxCount = 0, maxValue = 0
  Protected hasYahtzee = #False, hasFourKind = #False, hasThreeKind = #False
  Protected hasPair = 0, straightLength = 0
  
  ; Count each value
  For i = 0 To #NUM_DICE - 1
    If GameState\diceValues[i] >= 1 And GameState\diceValues[i] <= 6
      counts(GameState\diceValues[i]) = counts(GameState\diceValues[i]) + 1
    EndIf
  Next
  
  ; Detect patterns
  For i = 1 To 6
    If counts(i) = 5 : hasYahtzee = #True : EndIf
    If counts(i) = 4 : hasFourKind = #True : EndIf
    If counts(i) = 3 : hasThreeKind = #True : EndIf
    If counts(i) = 2 : hasPair = hasPair + 1 : EndIf
    If counts(i) > maxCount
      maxCount = counts(i)
      maxValue = i
    EndIf
  Next
  
  Select GameState\aiDifficulty
    Case #AI_EASY
      ; Easy: Just hold the most common value
      For i = 0 To #NUM_DICE - 1
        If GameState\diceValues[i] = maxValue
          GameState\diceHeld[i] = 1
          Dice(i)\held = 1
        Else
          GameState\diceHeld[i] = 0
          Dice(i)\held = 0
        EndIf
      Next
      
    Case #AI_MEDIUM
      ; Medium: Hold best patterns with some randomness
      If Random(100) < 20
        ; 20% chance to make a mistake - hold random dice
        For i = 0 To #NUM_DICE - 1
          If Random(100) < 40
            GameState\diceHeld[i] = 1
            Dice(i)\held = 1
          Else
            GameState\diceHeld[i] = 0
            Dice(i)\held = 0
          EndIf
        Next
      Else
        ; Hold most common value
        For i = 0 To #NUM_DICE - 1
          If GameState\diceValues[i] = maxValue
            GameState\diceHeld[i] = 1
            Dice(i)\held = 1
          Else
            GameState\diceHeld[i] = 0
            Dice(i)\held = 0
          EndIf
        Next
      EndIf
      
    Case #AI_HARD
      ; Hard: Strategic holding based on patterns
      If hasYahtzee Or hasFourKind
        ; Hold all matching
        For i = 0 To #NUM_DICE - 1
          If GameState\diceValues[i] = maxValue
            GameState\diceHeld[i] = 1
            Dice(i)\held = 1
          Else
            GameState\diceHeld[i] = 0
            Dice(i)\held = 0
          EndIf
        Next
      ElseIf hasThreeKind
        ; Hold three of a kind, reroll others
        For i = 0 To #NUM_DICE - 1
          If GameState\diceValues[i] = maxValue
            GameState\diceHeld[i] = 1
            Dice(i)\held = 1
          Else
            GameState\diceHeld[i] = 0
            Dice(i)\held = 0
          EndIf
        Next
      ElseIf hasPair >= 2
        ; Full house potential - hold pairs
        For i = 0 To #NUM_DICE - 1
          If counts(GameState\diceValues[i]) >= 2
            GameState\diceHeld[i] = 1
            Dice(i)\held = 1
          Else
            GameState\diceHeld[i] = 0
            Dice(i)\held = 0
          EndIf
        Next
      Else
        ; Check for straight potential
        Protected hasSequence = #False
        If (counts(1) >= 1 And counts(2) >= 1 And counts(3) >= 1) Or
           (counts(2) >= 1 And counts(3) >= 1 And counts(4) >= 1) Or
           (counts(3) >= 1 And counts(4) >= 1 And counts(5) >= 1) Or
           (counts(4) >= 1 And counts(5) >= 1 And counts(6) >= 1)
          hasSequence = #True
        EndIf
        
        If hasSequence
          ; Hold dice that form sequence
          For i = 0 To #NUM_DICE - 1
            Protected val = GameState\diceValues[i]
            ; Hold if part of a sequence
            If (val >= 1 And val <= 4 And counts(val+1) >= 1) Or
               (val >= 2 And val <= 5 And counts(val-1) >= 1) Or
               (val = 3 Or val = 4) ; Middle values good for straights
              GameState\diceHeld[i] = 1
              Dice(i)\held = 1
            Else
              GameState\diceHeld[i] = 0
              Dice(i)\held = 0
            EndIf
          Next
        Else
          ; Default: hold highest value dice (5s and 6s)
          For i = 0 To #NUM_DICE - 1
            If GameState\diceValues[i] >= 5
              GameState\diceHeld[i] = 1
              Dice(i)\held = 1
            Else
              GameState\diceHeld[i] = 0
              Dice(i)\held = 0
            EndIf
          Next
        EndIf
      EndIf
  EndSelect
EndProcedure

; Roll the dice
Procedure RollDice()
  Protected i
  Static lastRollFrame.q
  Protected nowFrame.q = ElapsedMilliseconds()
  
  ; Hard guard: prevent accidental double-roll in same frame/tick
  If nowFrame = lastRollFrame
    ProcedureReturn
  EndIf
  lastRollFrame = nowFrame
  
  Debug "RollDice() called @" + Str(nowFrame) + " - rollsLeft before: " + Str(GameState\rollsLeft)
  
  For i = 0 To #NUM_DICE - 1
    If Dice(i)\held = 0
      Dice(i)\value = Random(5) + 1
      GameState\diceValues[i] = Dice(i)\value
      Dice(i)\rolling = 1
      Dice(i)\targetRotX = Random(360) * 10
      Dice(i)\targetRotY = Random(360) * 10
      Dice(i)\targetRotZ = Random(360) * 10
    EndIf
  Next
  
  GameState\rollsLeft = GameState\rollsLeft - 1
  GameState\showingDiceRoll = 1
  GameState\rollAnimTime = 0.0
  
  Debug "RollDice() finished - rollsLeft after: " + Str(GameState\rollsLeft)
EndProcedure



; Initialize 3D scene
Procedure Initialize3D()
  Protected i, mat, screenW, screenH
  
  InitEngine3D()
  InitSprite()
  InitKeyboard()
  InitMouse()
  
  ; Get desktop resolution or use defaults
  CompilerIf #FULLSCREEN
    ExamineDesktops()
    screenW = DesktopWidth(0)
    screenH = DesktopHeight(0)
    
    OpenWindow(0, 0, 0, screenW, screenH, "3D Yahtzee - Player vs AI", #PB_Window_BorderLess)
    OpenScreen(screenW, screenH, 32, "3D Yahtzee - Player vs AI")
  CompilerElse
    screenW = #WINDOW_WIDTH
    screenH = #WINDOW_HEIGHT
    
    OpenWindow(0, 0, 0, screenW, screenH, "3D Yahtzee - Player vs AI", #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_MinimizeGadget)
    OpenWindowedScreen(WindowID(0), 0, 0, screenW, screenH, 0, 0, 0)
  CompilerEndIf
  
  ; Create camera for background
  Camera = CreateCamera(#PB_Any, 0, 0, 100, 100)
  MoveCamera(Camera, 0, 4, 12)
  CameraLookAt(Camera, 0, 0, 0)
  CameraBackColor(Camera, RGB(30, 50, 80))
  
  ; Create light
  Light = CreateLight(#PB_Any, RGB(255, 255, 255), 0, 8, 8)
  AmbientColor(RGB(80, 80, 80))
  
  ; Load fonts
  Font1 = LoadFont(#PB_Any, "Arial", 12, #PB_Font_Bold)
  Font2 = LoadFont(#PB_Any, "Arial", 14, #PB_Font_Bold)
  Font3 = LoadFont(#PB_Any, "Courier New", 11)
  Font4 = LoadFont(#PB_Any, "Arial", 48, #PB_Font_Bold)
  
  ; Show mouse cursor
  ShowCursor_(1)
  
  ; Initialize dice data (no 3D objects needed)
  For i = 0 To #NUM_DICE - 1
    Dice(i)\value = 1
    Dice(i)\x = -5 + i * 2.5
    Dice(i)\y = 0
    Dice(i)\z = 0
    Dice(i)\held = 0
    Dice(i)\rolling = 0
    Dice(i)\currentRotX = 0
    Dice(i)\currentRotY = 0
    Dice(i)\currentRotZ = 0
  Next
EndProcedure

; Update dice positions and rotations
Procedure UpdateDice(deltaTime.f)
  Protected i
  Protected lerpSpeed.f = 5.0
  
  For i = 0 To #NUM_DICE - 1
    If Dice(i)\rolling
      ; Animate rotation values for visual effect
      Dice(i)\currentRotX = Dice(i)\currentRotX + deltaTime * 500
      Dice(i)\currentRotY = Dice(i)\currentRotY + deltaTime * 700
      Dice(i)\currentRotZ = Dice(i)\currentRotZ + deltaTime * 300
      
      If GameState\rollAnimTime > 1.0
        Dice(i)\rolling = 0
        ; Reset rotation
        Dice(i)\currentRotX = 0
        Dice(i)\currentRotY = 0
        Dice(i)\currentRotZ = 0
      EndIf
    EndIf
  Next
EndProcedure

; Draw dice dots on 2D overlay - main display
Procedure DrawDiceValues()
  Protected i, screenW, screenH, dieX, dieY, dieSize, dotSize, spacing
  Protected centerX, centerY
  Protected angle.f, wobbleX.f, wobbleY.f
  Protected totalWidth, startX
  
  CompilerIf #FULLSCREEN
    ExamineDesktops()
    screenW = DesktopWidth(0)
    screenH = DesktopHeight(0)
  CompilerElse
    screenW = #WINDOW_WIDTH
    screenH = #WINDOW_HEIGHT
  CompilerEndIf
  
  DrawingMode(#PB_2DDrawing_Transparent)
  
  ; Configure dice size and spacing
  dieSize = 140
  dotSize = 15
  spacing = 35
  
  ; Calculate total width needed and starting position to center dice
  totalWidth = (#NUM_DICE * dieSize) + ((#NUM_DICE - 1) * dieSize)  ; dice + gaps (one die width between each)
  startX = (screenW - totalWidth) / 2
  
  ; Position dice in a centered row with proper spacing
  For i = 0 To #NUM_DICE - 1
    dieX = startX + (i * (dieSize + dieSize))  ; Each die plus one die width gap
    dieY = (screenH / 2) - (dieSize / 2) - 30  ; Center vertically, slightly above center
    
    ; Add wobble effect when rolling
    If Dice(i)\rolling
      angle = Dice(i)\currentRotX / 100.0
      wobbleX = Sin(angle) * 5
      wobbleY = Cos(angle) * 5
      dieX = dieX + wobbleX
      dieY = dieY + wobbleY
    EndIf
    
    ; Draw die face with shadow and border
    DrawingMode(#PB_2DDrawing_AlphaBlend)
    
    ; Shadow
    Box(dieX + 8, dieY + 8, dieSize, dieSize, RGBA(0, 0, 0, 100))
    
    ; Border and background based on state
    If Dice(i)\held
      Box(dieX, dieY, dieSize, dieSize, RGBA(50, 200, 50, 255))
      Box(dieX + 8, dieY + 8, dieSize - 16, dieSize - 16, RGBA(255, 255, 255, 255))
    ElseIf Dice(i)\rolling
      Box(dieX, dieY, dieSize, dieSize, RGBA(220, 80, 80, 255))
      Box(dieX + 8, dieY + 8, dieSize - 16, dieSize - 16, RGBA(255, 255, 255, 255))
    Else
      Box(dieX, dieY, dieSize, dieSize, RGBA(60, 60, 60, 255))
      Box(dieX + 8, dieY + 8, dieSize - 16, dieSize - 16, RGBA(255, 255, 255, 255))
    EndIf
    
    ; Draw dots based on dice value
    centerX = dieX + dieSize / 2
    centerY = dieY + dieSize / 2
    
    DrawingMode(#PB_2DDrawing_AlphaBlend)
    
    Select Dice(i)\value
      Case 1
        ; Center dot
        Circle(centerX, centerY, dotSize, RGBA(20, 20, 20, 255))
        
      Case 2
        ; Top-left and bottom-right
        Circle(centerX - spacing, centerY - spacing, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX + spacing, centerY + spacing, dotSize, RGBA(20, 20, 20, 255))
        
      Case 3
        ; Diagonal: top-left, center, bottom-right
        Circle(centerX - spacing, centerY - spacing, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX, centerY, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX + spacing, centerY + spacing, dotSize, RGBA(20, 20, 20, 255))
        
      Case 4
        ; Four corners
        Circle(centerX - spacing, centerY - spacing, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX + spacing, centerY - spacing, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX - spacing, centerY + spacing, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX + spacing, centerY + spacing, dotSize, RGBA(20, 20, 20, 255))
        
      Case 5
        ; Four corners + center
        Circle(centerX - spacing, centerY - spacing, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX + spacing, centerY - spacing, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX, centerY, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX - spacing, centerY + spacing, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX + spacing, centerY + spacing, dotSize, RGBA(20, 20, 20, 255))
        
      Case 6
        ; Two columns of three
        Circle(centerX - spacing, centerY - spacing, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX - spacing, centerY, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX - spacing, centerY + spacing, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX + spacing, centerY - spacing, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX + spacing, centerY, dotSize, RGBA(20, 20, 20, 255))
        Circle(centerX + spacing, centerY + spacing, dotSize, RGBA(20, 20, 20, 255))
    EndSelect
    
    ; Draw die number label and held status
    DrawingMode(#PB_2DDrawing_Transparent)
    DrawingFont(FontID(Font2))
    
    If Dice(i)\held
      FrontColor(RGB(50, 200, 50))
      DrawText(dieX + 20, dieY + dieSize + 8, "#" + Str(i + 1) + " HELD")
    Else
      FrontColor(RGB(200, 200, 200))
      DrawText(dieX + 30, dieY + dieSize + 8, "Die #" + Str(i + 1))
    EndIf
  Next
EndProcedure

; Draw menu screen
Procedure DrawMenu()
  Protected screenW, screenH, centerX, centerY, menuY, i
  Protected diffText.s, fsText.s
  
  CompilerIf #FULLSCREEN
    ExamineDesktops()
    screenW = DesktopWidth(0)
    screenH = DesktopHeight(0)
  CompilerElse
    screenW = #WINDOW_WIDTH
    screenH = #WINDOW_HEIGHT
  CompilerEndIf
  
  centerX = screenW / 2
  centerY = screenH / 2
  
  StartDrawing(ScreenOutput())
  
  ; Title
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(Font4))
  FrontColor(RGB(255, 255, 100))
  Protected titleWidth = TextWidth("YAHTZEE 3D")
  DrawText(centerX - titleWidth/2, 100, "YAHTZEE 3D")
  
  ; Subtitle
  DrawingFont(FontID(Font2))
  FrontColor(RGB(180, 180, 180))
  Protected subtitleWidth = TextWidth("Dice Game - Player vs AI/Network")
  DrawText(centerX - subtitleWidth/2, 180, "Dice Game - Player vs AI/Network")
  
  ; Menu options - sequential layout
  DrawingFont(FontID(Font2))
  menuY = 280
  
  ; === OPTION 0: START GAME ===
  If GameState\menuSelection = 0
    DrawingMode(#PB_2DDrawing_AlphaBlend)
    Box(centerX - 220, menuY - 10, 440, 50, RGBA(100, 200, 100, 200))
    DrawingMode(#PB_2DDrawing_Transparent)
    FrontColor(RGB(255, 255, 255))
  Else
    FrontColor(RGB(180, 180, 180))
  EndIf
  Protected textWidth = TextWidth("START GAME")
  DrawText(centerX - textWidth/2, menuY, "START GAME")
  
  ; === OPTION 1: MULTIPLAYER ===
  menuY = menuY + 70
  If GameState\menuSelection = 1
    DrawingMode(#PB_2DDrawing_AlphaBlend)
    Box(centerX - 220, menuY - 10, 440, 50, RGBA(100, 150, 200, 200))
    DrawingMode(#PB_2DDrawing_Transparent)
    FrontColor(RGB(255, 255, 255))
  Else
    FrontColor(RGB(180, 180, 180))
  EndIf
  textWidth = TextWidth("MULTIPLAYER (LAN/NET)")
  DrawText(centerX - textWidth/2, menuY, "MULTIPLAYER (LAN/NET)")
  
  ; === OPTION 2: AI DIFFICULTY ===
  menuY = menuY + 70
  Select GameState\aiDifficulty
    Case #AI_EASY : diffText = "EASY"
    Case #AI_MEDIUM : diffText = "MEDIUM"
    Case #AI_HARD : diffText = "HARD"
  EndSelect
  
  If GameState\menuSelection = 2
    DrawingMode(#PB_2DDrawing_AlphaBlend)
    Box(centerX - 220, menuY - 10, 440, 50, RGBA(200, 150, 100, 200))
    DrawingMode(#PB_2DDrawing_Transparent)
    FrontColor(RGB(255, 255, 255))
  Else
    FrontColor(RGB(180, 180, 180))
  EndIf
  Protected diffMenuText.s = "AI DIFFICULTY: " + diffText
  textWidth = TextWidth(diffMenuText)
  DrawText(centerX - textWidth/2, menuY, diffMenuText)
  
  ; === OPTION 3: FULLSCREEN ===
  menuY = menuY + 70
  If IsFullscreen
    fsText = "ON"
  Else
    fsText = "OFF"
  EndIf
  
  If GameState\menuSelection = 3
    DrawingMode(#PB_2DDrawing_AlphaBlend)
    Box(centerX - 220, menuY - 10, 440, 50, RGBA(150, 100, 200, 200))
    DrawingMode(#PB_2DDrawing_Transparent)
    FrontColor(RGB(255, 255, 255))
  Else
    FrontColor(RGB(180, 180, 180))
  EndIf
  Protected fsMenuText.s = "FULLSCREEN: " + fsText
  textWidth = TextWidth(fsMenuText)
  DrawText(centerX - textWidth/2, menuY, fsMenuText)
  FrontColor(RGB(255, 100, 100))
  DrawingFont(FontID(Font1))
  textWidth = TextWidth("(Requires Restart)")
  DrawText(centerX - textWidth/2, menuY + 20, "(Requires Restart)")
  DrawingFont(FontID(Font2))
  
  ; === OPTION 4: EXIT ===
  menuY = menuY + 85
  If GameState\menuSelection = 4
    DrawingMode(#PB_2DDrawing_AlphaBlend)
    Box(centerX - 220, menuY - 10, 440, 50, RGBA(200, 100, 100, 200))
    DrawingMode(#PB_2DDrawing_Transparent)
    FrontColor(RGB(255, 255, 255))
  Else
    FrontColor(RGB(180, 180, 180))
  EndIf
  textWidth = TextWidth("EXIT GAME")
  DrawText(centerX - textWidth/2, menuY, "EXIT GAME")
  
  ; Instructions at bottom
  DrawingFont(FontID(Font1))
  FrontColor(RGB(200, 200, 200))
  Protected instructText.s = "↑↓ Navigate  |  ←→ Change Options  |  Enter Select"
  textWidth = TextWidth(instructText)
  DrawText(centerX - textWidth/2, screenH - 100, instructText)
  
  StopDrawing()
EndProcedure

; Draw 2D UI
Procedure DrawUI()
  Protected i, y = 10, playerTotal = 0, aiTotal = 0, upperPlayerTotal = 0, upperAITotal = 0
  Protected bonus.s, screenW, screenH
  Protected isMyTurn.i = #False
  
  ; Determine if it's my turn for display purposes
  If GameState\networkActive
    If NetworkState\isHost
      If GameState\currentPlayer = 0
        isMyTurn = #True
      EndIf
    Else
      If GameState\currentPlayer = 1
        isMyTurn = #True
      EndIf
    EndIf
  Else
    If GameState\currentPlayer = 0
      isMyTurn = #True
    EndIf
  EndIf
  
  ; Get current screen dimensions
  CompilerIf #FULLSCREEN
    ExamineDesktops()
    screenW = DesktopWidth(0)
    screenH = DesktopHeight(0)
  CompilerElse
    screenW = #WINDOW_WIDTH
    screenH = #WINDOW_HEIGHT
  CompilerEndIf
  
  StartDrawing(ScreenOutput())
  
  ; Background for UI
  DrawingMode(#PB_2DDrawing_AlphaBlend)
  Box(10, 10, 350, screenH - 20, RGBA(0, 0, 0, 200))
  Box(screenW - 360, 10, 350, screenH - 20, RGBA(0, 0, 0, 200))
  
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(Font1))
  
  ; Player Scorecard
  FrontColor(RGB(255, 255, 0))
  If GameState\networkActive
    If NetworkState\isHost
      DrawText(20, y, "PLAYER 1 SCORECARD (You)")
    Else
      DrawText(20, y, "PLAYER 2 SCORECARD (You)")
    EndIf
  Else
    DrawText(20, y, "PLAYER SCORECARD")
  EndIf
  y = y + 25
  
  DrawingFont(FontID(Font3))
  FrontColor(RGB(255, 255, 255))
  For i = 0 To #NUM_CATEGORIES - 1
    ; In multiplayer as client, show opponent (host) scores on left
    If GameState\networkActive And Not NetworkState\isHost
      If Categories(i)\aiUsed
        FrontColor(RGB(150, 255, 150))
        DrawText(20, y, LSet(Categories(i)\name, 18) + ": " + RSet(Str(Categories(i)\aiScore), 3))
        playerTotal = playerTotal + Categories(i)\aiScore
        If i <= 5
          upperPlayerTotal = upperPlayerTotal + Categories(i)\aiScore
        EndIf
      Else
        FrontColor(RGB(200, 200, 200))
        DrawText(20, y, LSet(Categories(i)\name, 18) + ": -")
      EndIf
    Else
      ; Host or single player - show own scores on left
      If Categories(i)\playerUsed
        FrontColor(RGB(150, 255, 150))
        DrawText(20, y, LSet(Categories(i)\name, 18) + ": " + RSet(Str(Categories(i)\playerScore), 3))
        playerTotal = playerTotal + Categories(i)\playerScore
        If i <= 5
          upperPlayerTotal = upperPlayerTotal + Categories(i)\playerScore
        EndIf
      Else
        FrontColor(RGB(200, 200, 200))
        DrawText(20, y, LSet(Categories(i)\name, 18) + ": -")
      EndIf
    EndIf
    y = y + 20
  Next
  
  DrawingFont(FontID(Font1))
  
  ; Player bonus
  y = y + 10
  If upperPlayerTotal >= 63
    FrontColor(RGB(255, 215, 0))
    DrawText(20, y, "Upper Bonus: +35")
    playerTotal = playerTotal + 35
  Else
    FrontColor(RGB(200, 200, 200))
    DrawText(20, y, "Upper Bonus: " + Str(upperPlayerTotal) + "/63")
  EndIf
  
  y = y + 30
  FrontColor(RGB(255, 255, 0))
  DrawText(20, y, "TOTAL: " + Str(playerTotal))
  GameState\playerTotalScore = playerTotal
  
  ; AI Scorecard - change label if network multiplayer
  y = 10
  If GameState\networkActive
    FrontColor(RGB(100, 150, 255))
    If NetworkState\isHost
      DrawText(screenW - 340, y, "PLAYER 2 SCORECARD")
    Else
      DrawText(screenW - 340, y, "PLAYER 1 SCORECARD")
    EndIf
  Else
    FrontColor(RGB(255, 100, 100))
    DrawText(screenW - 340, y, "AI SCORECARD")
  EndIf
  y = y + 25
  
  DrawingFont(FontID(Font3))
  For i = 0 To #NUM_CATEGORIES - 1
    ; In multiplayer as client, show own scores on right
    If GameState\networkActive And Not NetworkState\isHost
      If Categories(i)\playerUsed
        FrontColor(RGB(255, 150, 150))
        DrawText(screenW - 340, y, LSet(Categories(i)\name, 18) + ": " + RSet(Str(Categories(i)\playerScore), 3))
        aiTotal = aiTotal + Categories(i)\playerScore
        If i <= 5
          upperAITotal = upperAITotal + Categories(i)\playerScore
        EndIf
      Else
        FrontColor(RGB(200, 200, 200))
        DrawText(screenW - 340, y, LSet(Categories(i)\name, 18) + ": -")
      EndIf
    Else
      ; Host or single player - show opponent/AI scores on right
      If Categories(i)\aiUsed
        FrontColor(RGB(255, 150, 150))
        DrawText(screenW - 340, y, LSet(Categories(i)\name, 18) + ": " + RSet(Str(Categories(i)\aiScore), 3))
        aiTotal = aiTotal + Categories(i)\aiScore
        If i <= 5
          upperAITotal = upperAITotal + Categories(i)\aiScore
        EndIf
      Else
        FrontColor(RGB(200, 200, 200))
        DrawText(screenW - 340, y, LSet(Categories(i)\name, 18) + ": -")
      EndIf
    EndIf
    y = y + 20
  Next
  
  DrawingFont(FontID(Font1))
  
  ; AI bonus
  y = y + 10
  If upperAITotal >= 63
    FrontColor(RGB(255, 215, 0))
    DrawText(screenW - 340, y, "Upper Bonus: +35")
    aiTotal = aiTotal + 35
  Else
    FrontColor(RGB(200, 200, 200))
    DrawText(screenW - 340, y, "Upper Bonus: " + Str(upperAITotal) + "/63")
  EndIf
  
  y = y + 30
  FrontColor(RGB(255, 100, 100))
  DrawText(screenW - 340, y, "TOTAL: " + Str(aiTotal))
  GameState\aiTotalScore = aiTotal
  
  ; Game status - centered bottom
  Protected boxX = (screenW - 800) / 2
  Protected boxY = screenH - 160
  Protected textX = boxX + 20
  Protected textY = boxY + 20
  
  DrawingMode(#PB_2DDrawing_AlphaBlend)
  Box(boxX, boxY, 800, 150, RGBA(0, 0, 0, 200))
  
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(Font2))
  
  If GameState\gameOver
    FrontColor(RGB(255, 255, 0))
    If GameState\playerTotalScore > GameState\aiTotalScore
      DrawText(textX, textY, "GAME OVER - PLAYER WINS! " + Str(GameState\playerTotalScore) + " - " + Str(GameState\aiTotalScore))
    ElseIf GameState\aiTotalScore > GameState\playerTotalScore
      DrawText(textX, textY, "GAME OVER - AI WINS! " + Str(GameState\aiTotalScore) + " - " + Str(GameState\playerTotalScore))
    Else
      DrawText(textX, textY, "GAME OVER - TIE! " + Str(GameState\playerTotalScore) + " - " + Str(GameState\aiTotalScore))
    EndIf
    DrawText(textX, textY + 40, "Press SPACE to play again or ESC to quit")
  Else
    If GameState\currentPlayer = 0
      FrontColor(RGB(255, 255, 100))
      If GameState\networkActive
        DrawText(textX, textY, "PLAYER 1'S TURN - Round " + Str(GameState\round) + "/13")
      Else
        DrawText(textX, textY, "PLAYER'S TURN - Round " + Str(GameState\round) + "/13")
      EndIf
    Else
      FrontColor(RGB(255, 150, 150))
      If GameState\networkActive
        DrawText(textX, textY, "PLAYER 2'S TURN - Round " + Str(GameState\round) + "/13")
      Else
        DrawText(textX, textY, "AI'S TURN - Round " + Str(GameState\round) + "/13")
      EndIf
    EndIf
    
    FrontColor(RGB(200, 200, 255))
    DrawText(textX, textY + 35, "Rolls Left: " + Str(GameState\rollsLeft))
    DrawText(textX, textY + 60, GameState\message)
    
    ; Show AI difficulty or network status
    If GameState\networkActive
      If NetworkState\isHost
        FrontColor(RGB(100, 200, 255))
        If NetworkState\opponentConnected
          DrawText(textX + 480, textY + 35, "HOST - Connected")
        Else
          DrawText(textX + 480, textY + 35, "HOST - Waiting...")
        EndIf
        ; Display host IP for others to join
        FrontColor(RGB(255, 255, 100))
        DrawingFont(FontID(Font1))
        DrawText(textX, textY + 105, "Your IP: " + HostIP + ":" + Str(#NETWORK_PORT))
        DrawingFont(FontID(Font2))
      Else
        FrontColor(RGB(100, 255, 200))
        DrawText(textX + 480, textY + 35, "CLIENT - Connected")
      EndIf
    Else
      Protected diffText.s
      Select GameState\aiDifficulty
        Case #AI_EASY : diffText = "EASY"
        Case #AI_MEDIUM : diffText = "MEDIUM"
        Case #AI_HARD : diffText = "HARD"
      EndSelect
      FrontColor(RGB(255, 200, 100))
      DrawText(textX + 500, textY + 35, "AI: " + diffText)
    EndIf
    
    FrontColor(RGB(200, 200, 255))
    If GameState\currentPlayer = 0 Or (GameState\networkActive And isMyTurn)
      ; Keyboard control instructions
      If GameState\rollsLeft = #MAX_ROLLS
        If GameState\gameMode = #MODE_VS_AI
          DrawText(textX, textY + 85, "SPACE: Roll | 1-5: Hold/Unhold | Enter: Score | D: Change Difficulty")
        Else
          DrawText(textX, textY + 85, "SPACE: Roll | 1-5: Hold/Unhold | Enter: Score | ESC: Disconnect")
        EndIf
      Else
        If GameState\gameMode = #MODE_VS_AI
          DrawText(textX, textY + 85, "SPACE: Roll | 1-5: Hold/Unhold | Enter: Score | D: Change Difficulty")
        Else
          DrawText(textX, textY + 85, "SPACE: Roll | 1-5: Hold/Unhold | Enter: Score | ESC: Disconnect")
        EndIf
      EndIf
    EndIf
  EndIf
  
  ; Draw dice values overlay
  DrawDiceValues()
  
  StopDrawing()
EndProcedure

; New game
Procedure NewGame()
  Protected i
  
  For i = 0 To #NUM_CATEGORIES - 1
    Categories(i)\playerScore = 0
    Categories(i)\aiScore = 0
    Categories(i)\playerUsed = 0
    Categories(i)\aiUsed = 0
  Next
  
  GameState\currentPlayer = 0
  GameState\round = 1
  GameState\rollsLeft = #MAX_ROLLS
  GameState\playerTotalScore = 0
  GameState\aiTotalScore = 0
  GameState\gameOver = 0
  GameState\message = "Press SPACE to roll the dice!"
  GameState\showingDiceRoll = 0
  GameState\inMenu = 1  ; Start in menu
  GameState\menuSelection = 0
  GameState\opponentName = ""
  If GameState\aiDifficulty = 0
    GameState\aiDifficulty = #AI_MEDIUM ; Default difficulty only if not set
  EndIf
  
  For i = 0 To #NUM_DICE - 1
    Dice(i)\held = 0
    Dice(i)\rolling = 0
    GameState\diceHeld[i] = 0
    GameState\diceValues[i] = 1
    Dice(i)\value = 1
  Next
EndProcedure

; AI Turn
Procedure AITakeTurn(deltaTime.f)
  Protected category, score, i
  Static aiState.i = 0
  Static aiTimer.f = 0.0
  
  ; Safety: never let AI act outside VS AI mode or outside AI turn
  If GameState\gameMode <> #MODE_VS_AI Or GameState\currentPlayer <> 1
    aiState = 0
    aiTimer = 0.0
    ProcedureReturn
  EndIf

  If aiState = 0
    ; First roll
    Debug "AITakeTurn: first roll"
    RollDice()
    GameState\message = "AI is rolling..."
    aiState = 1
    aiTimer = 0.0
  ElseIf aiState = 1
    aiTimer + deltaTime
    If aiTimer > 2.0 And GameState\showingDiceRoll = 0
      If GameState\rollsLeft > 0
        AIMakeDiceDecision()
        GameState\message = "AI is deciding..."
        aiState = 2
        aiTimer = 0.0
      Else
        aiState = 3
      EndIf
    EndIf
  ElseIf aiState = 2
    aiTimer + deltaTime
    If aiTimer > 1.0
      If GameState\rollsLeft > 0
        Debug "AITakeTurn: rolling again"
        RollDice()
        GameState\message = "AI is rolling again..."
        aiState = 1
        aiTimer = 0.0
      Else
        aiState = 3
      EndIf
    EndIf
  ElseIf aiState = 3
    ; Select category
    category = AISelectCategory()
    If category >= 0
      Protected Dim tempDice.i(#NUM_DICE - 1)
      For i = 0 To #NUM_DICE - 1
        tempDice(i) = GameState\diceValues[i]
      Next
      score = CalculateScore(category, tempDice())
      Categories(category)\aiScore = score
      Categories(category)\aiUsed = 1
      GameState\message = "AI scored " + Str(score) + " in " + Categories(category)\name
    EndIf
    
    ; Reset for next turn
    For i = 0 To #NUM_DICE - 1
      Dice(i)\held = 0
      GameState\diceHeld[i] = 0
    Next
    
    GameState\currentPlayer = 0
    GameState\rollsLeft = #MAX_ROLLS
    GameState\round = GameState\round + 1
    aiState = 0
    
    If GameState\round > 13
      GameState\gameOver = 1
    EndIf
  EndIf
EndProcedure

; Main program
; Seed RNG once to avoid repeatable sequences
RandomSeed(ElapsedMilliseconds())
InitializeCategories()
Initialize3D()
CompilerIf #DEBUG_TESTS
  RunScoreSelfTest()
  RunRandomDistributionTest(50000)
CompilerEndIf
NewGame()

Define lastTime.q = ElapsedMilliseconds()
Define deltaTime.f
Define currentTime.q

Repeat
  ; Calculate delta time
  currentTime = ElapsedMilliseconds()
  deltaTime = (currentTime - lastTime) / 1000.0
  lastTime = currentTime
  
  ; Handle animation timer
  If GameState\showingDiceRoll
    GameState\rollAnimTime + deltaTime
    If GameState\rollAnimTime > 1.5
      GameState\showingDiceRoll = 0
      If GameState\currentPlayer = 0
        GameState\message = "Press SPACE to roll or ENTER to score"
      EndIf
    EndIf
  EndIf
  
  ; Handle input
  ExamineKeyboard()

  Define spaceDown.i = Bool(KeyboardPushed(#PB_Key_Space))
  Define enterDown.i = Bool(KeyboardPushed(#PB_Key_Return))
  Define dDown.i = Bool(KeyboardPushed(#PB_Key_D))
  Define upDown.i = Bool(KeyboardPushed(#PB_Key_Up))
  Define downDown.i = Bool(KeyboardPushed(#PB_Key_Down))
  Define leftDown.i = Bool(KeyboardPushed(#PB_Key_Left))
  Define rightDown.i = Bool(KeyboardPushed(#PB_Key_Right))
  Define hDown.i = Bool(KeyboardPushed(#PB_Key_H))
  Define jDown.i = Bool(KeyboardPushed(#PB_Key_J))
  Define escDown.i = Bool(KeyboardPushed(#PB_Key_Escape))

  Define spacePressed.i = Bool(spaceDown And Not PrevSpaceDown)
  Define enterPressed.i = Bool(enterDown And Not PrevEnterDown)
  Define dPressed.i = Bool(dDown And Not PrevDDown)
  Define upPressed.i = Bool(upDown And Not PrevUpDown)
  Define downPressed.i = Bool(downDown And Not PrevDownDown)
  Define leftPressed.i = Bool(leftDown And Not PrevLeftDown)
  Define rightPressed.i = Bool(rightDown And Not PrevRightDown)
  Define hPressed.i = Bool(hDown And Not PrevHDown)
  Define jPressed.i = Bool(jDown And Not PrevJDown)
  Define escPressed.i = Bool(escDown And Not PrevEscDown)

  If GameState\inMenu
    ; Menu navigation (edge detection)
    If upPressed
      GameState\menuSelection = GameState\menuSelection - 1
      If GameState\menuSelection < 0
        GameState\menuSelection = 4
      EndIf
    EndIf

    If downPressed
      GameState\menuSelection = GameState\menuSelection + 1
      If GameState\menuSelection > 4
        GameState\menuSelection = 0
      EndIf
    EndIf

    ; Left/Right for difficulty (no Delay blocking)
    If GameState\menuSelection = 2
      If leftPressed
        GameState\aiDifficulty = GameState\aiDifficulty - 1
        If GameState\aiDifficulty < #AI_EASY
          GameState\aiDifficulty = #AI_HARD
        EndIf
      EndIf

      If rightPressed
        GameState\aiDifficulty = GameState\aiDifficulty + 1
        If GameState\aiDifficulty > #AI_HARD
          GameState\aiDifficulty = #AI_EASY
        EndIf
      EndIf
    EndIf

    ; Left/Right for fullscreen
    If GameState\menuSelection = 3
      If leftPressed Or rightPressed
        IsFullscreen = 1 - IsFullscreen
      EndIf
    EndIf

    ; Enter to select
    If enterPressed
      Select GameState\menuSelection
        Case 0 ; Start Game (VS AI)
          GameState\inMenu = 0
          GameState\gameMode = #MODE_VS_AI

        Case 1 ; Multiplayer
          ; Show multiplayer submenu on screen (avoid freeze by rendering)
          Define mpWaiting = #True
          Define mpTimer = 0
          Define mpMsgBoxX, mpMsgBoxY, mpCenterX, mpCenterY, mpScreenW, mpScreenH
          
          CompilerIf #FULLSCREEN
            ExamineDesktops()
            mpScreenW = DesktopWidth(0)
            mpScreenH = DesktopHeight(0)
          CompilerElse
            mpScreenW = #WINDOW_WIDTH
            mpScreenH = #WINDOW_HEIGHT
          CompilerEndIf
          
          mpCenterX = mpScreenW / 2
          mpCenterY = mpScreenH / 2
           mpMsgBoxX = mpCenterX - 350
           mpMsgBoxY = mpCenterY - 80
          
           ; Reset submenu edge-tracking so first press registers cleanly
           PrevHDown = 0
           PrevJDown = 0
           PrevEscDown = 0
           PrevUpDown = 0
           PrevDownDown = 0
           PrevEnterDown = 0
           PrevSDown = 0
           
           Define mpSelectedHost.i = 1
           Define mpAutoJoinAttempt.i = 0
           
           While mpWaiting
            ; Keep rendering so game doesn't freeze
            RenderWorld()
            
            StartDrawing(ScreenOutput())
            DrawingMode(#PB_2DDrawing_Transparent)
            DrawingFont(FontID(Font2))
            FrontColor(RGB(255, 255, 100))
            
            ; Draw message box (auto-sized so submenu doesn't overlap)
            Define mpBoxW = 700
            Define mpBoxPadding = 10
            Define mpLineH1 = 24
            Define mpLineH2 = 20
            Define mpListLineH = 18
            Define mpHeaderLines = 5      ; title + commands lines
            Define mpInfoLines = 3        ; (optional) IP + found hosts + subnet/scan
            Define mpListMax = 10
            Define mpBoxH = mpBoxPadding*2 + mpHeaderLines*mpLineH1 + mpInfoLines*mpLineH2 + mpListMax*mpListLineH + 40
            
            DrawingMode(#PB_2DDrawing_AlphaBlend)
            Box(mpMsgBoxX - mpBoxPadding, mpMsgBoxY - mpBoxPadding, mpBoxW + mpBoxPadding*2, mpBoxH, RGBA(0, 0, 0, 220))
            DrawingMode(#PB_2DDrawing_Transparent)
            
            Define mpLeft = mpMsgBoxX
            Define mpTop = mpMsgBoxY
            Define mpY = mpTop

            FrontColor(RGB(255, 255, 100))
            DrawText(mpLeft, mpY, "MULTIPLAYER MODE")
            mpY + mpLineH1

            FrontColor(RGB(200, 200, 200))
            DrawingFont(FontID(Font1))
            DrawText(mpLeft, mpY, "H: Host game")
            mpY + mpLineH1
            DrawText(mpLeft, mpY, "J: Join by IP")
            mpY + mpLineH1
            DrawText(mpLeft, mpY, "S: Scan LAN for hosts")
            mpY + mpLineH1
            DrawText(mpLeft, mpY, "Enter: Join selected / auto-join")
            mpY + mpLineH1
            DrawText(mpLeft, mpY, "ESC: Return to menu")
            mpY + mpLineH1

            If HostIP <> ""
              FrontColor(RGB(255, 255, 0))
              DrawText(mpLeft, mpY, "Your IP: " + HostIP + ":" + Str(#NETWORK_PORT))
              mpY + mpLineH2
            EndIf

            ; Show scan results
            FrontColor(RGB(180, 180, 255))
            DrawText(mpLeft, mpY, "Found Hosts: " + Str(LanHostCount) + " (↑↓ select, Enter join)")
            mpY + mpLineH2
            If LanHostCount = 0
              FrontColor(RGB(200, 200, 200))
              DrawText(mpLeft, mpY, "No hosts found yet (press S to scan)")
              mpY + mpLineH2
            EndIf
            If LanScanPrefix <> ""
              FrontColor(RGB(200, 200, 220))
              DrawText(mpLeft, mpY, "Scan subnet: " + LanScanPrefix + "0/24")
              mpY + mpLineH2
            EndIf
            If LanScanActive
              FrontColor(RGB(200, 200, 200))
              Define pct = Int((LanScanIndex / 254.0) * 100)
              DrawText(mpLeft, mpY, "Scanning " + LanScanPrefix + Str(LanScanIndex) + "... (" + Str(pct) + "%)")
              mpY + mpLineH2
            EndIf

            DrawingFont(FontID(Font3))
            FrontColor(RGB(220, 220, 220))
            Define listY = mpY
            Define idx
              Define listShown = 0
              Define listMax = mpListMax
              For idx = 1 To LanHostCount
                If listShown >= listMax : Break : EndIf
                If idx = mpSelectedHost
                  FrontColor(RGB(255, 255, 100))
                  DrawText(mpLeft, listY, "> " + Str(idx) + ") " + LanHostList(idx) + ":" + Str(#NETWORK_PORT))
                  FrontColor(RGB(220, 220, 220))
                Else
                  DrawText(mpLeft, listY, "  " + Str(idx) + ") " + LanHostList(idx) + ":" + Str(#NETWORK_PORT))
                EndIf
                listY + mpListLineH
                listShown + 1
              Next
              DrawingFont(FontID(Font1))
            
            StopDrawing()
            FlipBuffers()
            
             ; Check for input (edge detection)
             ExamineKeyboard()
             hDown = Bool(KeyboardPushed(#PB_Key_H))
             jDown = Bool(KeyboardPushed(#PB_Key_J))
             Define sDown = Bool(KeyboardPushed(#PB_Key_S))
             Define upDown = Bool(KeyboardPushed(#PB_Key_Up))
             Define downDown = Bool(KeyboardPushed(#PB_Key_Down))
             Define enterDown = Bool(KeyboardPushed(#PB_Key_Return))
             escDown = Bool(KeyboardPushed(#PB_Key_Escape))
             
             hPressed = Bool(hDown And Not PrevHDown)
             jPressed = Bool(jDown And Not PrevJDown)
             Define sPressed = Bool(sDown And Not PrevSDown)
             Define upPressed = Bool(upDown And Not PrevUpDown)
             Define downPressed = Bool(downDown And Not PrevDownDown)
             Define enterPressed2 = Bool(enterDown And Not PrevEnterDown)
             escPressed = Bool(escDown And Not PrevEscDown)
             
             ; Continue incremental scan if active
             If LanScanActive
               ContinueLanScanStep()
               If mpSelectedHost > LanHostCount
                 mpSelectedHost = LanHostCount
               EndIf
               If mpSelectedHost < 1
                 mpSelectedHost = 1
               EndIf
             EndIf
             
             If sPressed
               ; Derive a reasonable LAN prefix from HostIP if possible
               Define baseIP.s = HostIP
               If baseIP = "" Or FindString(baseIP, " ", 1)
                 baseIP = GetLocalIPAddress()
               EndIf
               Define dotPos = FindString(baseIP, ".", 1)
               dotPos = FindString(baseIP, ".", dotPos + 1)
               dotPos = FindString(baseIP, ".", dotPos + 1)
               If dotPos
                 StartLanScan(Left(baseIP, dotPos))
               Else
                 StartLanScan("192.168.1.")
               EndIf
             EndIf
             
             If upPressed And LanHostCount > 0
               mpSelectedHost - 1
               If mpSelectedHost < 1 : mpSelectedHost = 1 : EndIf
             ElseIf downPressed And LanHostCount > 0
               mpSelectedHost + 1
               If mpSelectedHost > LanHostCount : mpSelectedHost = LanHostCount : EndIf
             EndIf
             
               If enterPressed2
                 If LanHostCount > 0
                   ServerIP = LanHostList(mpSelectedHost)
                 Else
                   ; Auto-join guesses (cycle each Enter)
                   Define basePrefix.s = LanScanPrefix
                   If basePrefix = ""
                     Define baseIP2.s = HostIP
                     If baseIP2 = "" Or FindString(baseIP2, " ", 1)
                       baseIP2 = GetLocalIPAddress()
                     EndIf
                     Define dp = FindString(baseIP2, ".", 1)
                     dp = FindString(baseIP2, ".", dp + 1)
                     dp = FindString(baseIP2, ".", dp + 1)
                     If dp
                       basePrefix = Left(baseIP2, dp)
                     EndIf
                   EndIf
 
                   mpAutoJoinAttempt + 1
                   If mpAutoJoinAttempt > 6 : mpAutoJoinAttempt = 1 : EndIf
 
                   Select mpAutoJoinAttempt
                     Case 1
                       If LastJoinedIP <> ""
                         ServerIP = LastJoinedIP
                       ElseIf basePrefix <> ""
                         ServerIP = basePrefix + "1"
                       Else
                         ServerIP = "127.0.0.1"
                       EndIf
                     Case 2
                       If basePrefix <> "" : ServerIP = basePrefix + "1" : Else : ServerIP = "127.0.0.1" : EndIf
                     Case 3
                       If basePrefix <> "" : ServerIP = basePrefix + "2" : Else : ServerIP = "127.0.0.1" : EndIf
                     Case 4
                       If basePrefix <> "" : ServerIP = basePrefix + "100" : Else : ServerIP = "127.0.0.1" : EndIf
                     Case 5
                       If basePrefix <> "" : ServerIP = basePrefix + "101" : Else : ServerIP = "127.0.0.1" : EndIf
                     Case 6
                       ServerIP = "127.0.0.1"
                   EndSelect
 
                   GameState\message = "Auto-join trying " + ServerIP + ":" + Str(#NETWORK_PORT)
                 EndIf
                 If JoinGame(ServerIP)
                   LastJoinedIP = ServerIP
                   GameState\inMenu = 0
                   mpWaiting = #False
                 EndIf
              ElseIf hPressed
              If HostGame()
                GameState\inMenu = 0
              EndIf
              mpWaiting = #False
            ElseIf jPressed
              ; IP input mode
              Define ipInputActive = #True
              Define inputIP.s = "127.0.0.1"
              Define cursorPos = Len(inputIP)
              Define ipTimer = 0
              
              ; Edge reset for input loop
              PrevEnterDown = 0
              PrevEscDown = 0
              PrevLeftDown = 0
              PrevRightDown = 0
              PrevPeriodDown = 0
              PrevDigitDown(0) = 0 : PrevDigitDown(1) = 0 : PrevDigitDown(2) = 0 : PrevDigitDown(3) = 0 : PrevDigitDown(4) = 0
              PrevDigitDown(5) = 0 : PrevDigitDown(6) = 0 : PrevDigitDown(7) = 0 : PrevDigitDown(8) = 0 : PrevDigitDown(9) = 0
              
              While ipInputActive
                ; Keep rendering
                RenderWorld()
                
                StartDrawing(ScreenOutput())
                DrawingMode(#PB_2DDrawing_Transparent)
                DrawingFont(FontID(Font2))
                
                ; Draw IP input box
                DrawingMode(#PB_2DDrawing_AlphaBlend)
                Box(mpMsgBoxX - 10, mpMsgBoxY + 120, 620, 120, RGBA(20, 20, 60, 240))
                DrawingMode(#PB_2DDrawing_Transparent)
                
                FrontColor(RGB(100, 255, 100))
                DrawText(mpMsgBoxX, mpMsgBoxY + 130, "ENTER SERVER IP ADDRESS:")
                
                ; Draw input field
                DrawingMode(#PB_2DDrawing_AlphaBlend)
                Box(mpMsgBoxX, mpMsgBoxY + 160, 500, 35, RGBA(255, 255, 255, 255))
                DrawingMode(#PB_2DDrawing_Transparent)
                FrontColor(RGB(0, 0, 0))
                DrawText(mpMsgBoxX + 5, mpMsgBoxY + 165, inputIP)
                
                ; Draw cursor (blinking)
                If (ipTimer / 30) % 2 = 0
                  Define cursorX = mpMsgBoxX + 5 + TextWidth(Left(inputIP, cursorPos))
                  Line(cursorX, mpMsgBoxY + 165, 2, 20, RGB(0, 0, 0))
                EndIf
                
                FrontColor(RGB(200, 200, 200))
                DrawingFont(FontID(Font1))
                DrawText(mpMsgBoxX, mpMsgBoxY + 205, "Type IP and press ENTER to connect, or ESC to cancel")
                
                StopDrawing()
                FlipBuffers()
                
                ; Process keyboard input
                ExamineKeyboard()
                
                ; Digit keys / period (edge)
                Define kDown.i, kPressed.i
                
                kDown = Bool(KeyboardPushed(#PB_Key_0))
                kPressed = Bool(kDown And Not PrevDigitDown(0))
                If kPressed : inputIP = Left(inputIP, cursorPos) + "0" + Right(inputIP, Len(inputIP) - cursorPos) : cursorPos + 1 : EndIf
                PrevDigitDown(0) = kDown
                
                kDown = Bool(KeyboardPushed(#PB_Key_1))
                kPressed = Bool(kDown And Not PrevDigitDown(1))
                If kPressed : inputIP = Left(inputIP, cursorPos) + "1" + Right(inputIP, Len(inputIP) - cursorPos) : cursorPos + 1 : EndIf
                PrevDigitDown(1) = kDown
                
                kDown = Bool(KeyboardPushed(#PB_Key_2))
                kPressed = Bool(kDown And Not PrevDigitDown(2))
                If kPressed : inputIP = Left(inputIP, cursorPos) + "2" + Right(inputIP, Len(inputIP) - cursorPos) : cursorPos + 1 : EndIf
                PrevDigitDown(2) = kDown
                
                kDown = Bool(KeyboardPushed(#PB_Key_3))
                kPressed = Bool(kDown And Not PrevDigitDown(3))
                If kPressed : inputIP = Left(inputIP, cursorPos) + "3" + Right(inputIP, Len(inputIP) - cursorPos) : cursorPos + 1 : EndIf
                PrevDigitDown(3) = kDown
                
                kDown = Bool(KeyboardPushed(#PB_Key_4))
                kPressed = Bool(kDown And Not PrevDigitDown(4))
                If kPressed : inputIP = Left(inputIP, cursorPos) + "4" + Right(inputIP, Len(inputIP) - cursorPos) : cursorPos + 1 : EndIf
                PrevDigitDown(4) = kDown
                
                kDown = Bool(KeyboardPushed(#PB_Key_5))
                If kDown And Not PrevDigitDown(5)
                  inputIP = Left(inputIP, cursorPos) + "5" + Right(inputIP, Len(inputIP) - cursorPos)
                  cursorPos + 1
                EndIf
                PrevDigitDown(5) = kDown
                
                kDown = Bool(KeyboardPushed(#PB_Key_6))
                kPressed = Bool(kDown And Not PrevDigitDown(6))
                If kPressed : inputIP = Left(inputIP, cursorPos) + "6" + Right(inputIP, Len(inputIP) - cursorPos) : cursorPos + 1 : EndIf
                PrevDigitDown(6) = kDown
                
                kDown = Bool(KeyboardPushed(#PB_Key_7))
                kPressed = Bool(kDown And Not PrevDigitDown(7))
                If kPressed : inputIP = Left(inputIP, cursorPos) + "7" + Right(inputIP, Len(inputIP) - cursorPos) : cursorPos + 1 : EndIf
                PrevDigitDown(7) = kDown
                
                kDown = Bool(KeyboardPushed(#PB_Key_8))
                kPressed = Bool(kDown And Not PrevDigitDown(8))
                If kPressed : inputIP = Left(inputIP, cursorPos) + "8" + Right(inputIP, Len(inputIP) - cursorPos) : cursorPos + 1 : EndIf
                PrevDigitDown(8) = kDown
                
                kDown = Bool(KeyboardPushed(#PB_Key_9))
                kPressed = Bool(kDown And Not PrevDigitDown(9))
                If kPressed : inputIP = Left(inputIP, cursorPos) + "9" + Right(inputIP, Len(inputIP) - cursorPos) : cursorPos + 1 : EndIf
                PrevDigitDown(9) = kDown
                
                kDown = Bool(KeyboardPushed(#PB_Key_Period))
                kPressed = Bool(kDown And Not PrevPeriodDown)
                If kPressed : inputIP = Left(inputIP, cursorPos) + "." + Right(inputIP, Len(inputIP) - cursorPos) : cursorPos + 1 : EndIf
                PrevPeriodDown = kDown
                
                ; Backspace
                If KeyboardPushed(#PB_Key_Back) And cursorPos > 0
                  inputIP = Left(inputIP, cursorPos - 1) + Right(inputIP, Len(inputIP) - cursorPos)
                  cursorPos - 1
                EndIf
                
                ; Delete
                If KeyboardPushed(#PB_Key_Delete) And cursorPos < Len(inputIP)
                  inputIP = Left(inputIP, cursorPos) + Right(inputIP, Len(inputIP) - cursorPos - 1)
                EndIf
                
                ; Arrow keys
                leftDown = Bool(KeyboardPushed(#PB_Key_Left))
                rightDown = Bool(KeyboardPushed(#PB_Key_Right))
                leftPressed = Bool(leftDown And Not PrevLeftDown)
                rightPressed = Bool(rightDown And Not PrevRightDown)
                
                If leftPressed And cursorPos > 0
                  cursorPos - 1
                EndIf
                If rightPressed And cursorPos < Len(inputIP)
                  cursorPos + 1
                EndIf
                
                PrevLeftDown = leftDown
                PrevRightDown = rightDown
                
                ; Home/End
                If KeyboardPushed(#PB_Key_Home)
                  cursorPos = 0
                EndIf
                If KeyboardPushed(#PB_Key_End)
                  cursorPos = Len(inputIP)
                EndIf
                
                ; Enter to connect
                enterDown = Bool(KeyboardPushed(#PB_Key_Return))
                enterPressed = Bool(enterDown And Not PrevEnterDown)
                If enterPressed
                  If Trim(inputIP) <> ""
                    ServerIP = Trim(inputIP)
                    If JoinGame(ServerIP)
                      GameState\inMenu = 0
                      mpWaiting = #False
                    EndIf
                  EndIf
                  ipInputActive = #False
                EndIf
                PrevEnterDown = enterDown
                
                ; ESC to cancel
                escDown = Bool(KeyboardPushed(#PB_Key_Escape))
                escPressed = Bool(escDown And Not PrevEscDown)
                If escPressed
                  ipInputActive = #False
                EndIf
                PrevEscDown = escDown
                
                ipTimer + 1
              Wend
              
            ElseIf escPressed
              mpWaiting = #False
              GameState\message = ""
            EndIf
            
             PrevHDown = hDown
             PrevJDown = jDown
             PrevSDown = sDown
             PrevUpDown = upDown
             PrevDownDown = downDown
             PrevEnterDown = enterDown
             PrevEscDown = escDown
            
            ; Prevent infinite loop
            mpTimer = mpTimer + 1
            If mpTimer > 10000
              mpWaiting = #False
            EndIf
          Wend

        Case 2 ; AI Difficulty (already handled by left/right arrows)

        Case 3 ; Toggle fullscreen (note about restart)
          IsFullscreen = 1 - IsFullscreen

        Case 4 ; Exit
          Break
      EndSelect
    EndIf
    
  ElseIf Not GameState\gameOver
    ; Determine if it's the local player's turn
    Define isMyTurn.i = #False
    
    If GameState\networkActive
      ; In multiplayer: Host is player 0, Client is player 1
      If NetworkState\isHost
        If GameState\currentPlayer = 0
          isMyTurn = #True
        EndIf
      Else
        If GameState\currentPlayer = 1
          isMyTurn = #True
        EndIf
      EndIf
    Else
      ; In single player: Player is always 0
      If GameState\currentPlayer = 0
        isMyTurn = #True
      EndIf
    EndIf
    
    If isMyTurn And GameState\showingDiceRoll = 0
      ; Check if host is waiting for opponent
      If GameState\networkActive And NetworkState\isHost And Not NetworkState\opponentConnected
        ; Host waiting for opponent - don't allow gameplay
        GameState\message = "Waiting for opponent to connect..."
      Else
        ; Player turn - Keyboard controls (edge detection)
        If spacePressed And GameState\rollsLeft > 0 And GameState\showingDiceRoll = 0
          Debug "PlayerInput: Space pressed -> RollDice"
          RollDice()
          GameState\message = "Rolling dice..."
          ; Send roll to network opponent if multiplayer
          If GameState\networkActive
            SendPacket(#PKT_ROLL_DICE, "")
          EndIf
        EndIf
        
        ; Hold/unhold dice (only if at least one roll has been made)
        If GameState\rollsLeft < #MAX_ROLLS
          Define iKey.i, digitDown.i, digitPressed.i

          For iKey = 1 To 5
            digitDown = Bool(KeyboardPushed(#PB_Key_1 + (iKey - 1)))
            digitPressed = Bool(digitDown And Not PrevDigitDown(iKey))

            If digitPressed
              Dice(iKey - 1)\held = 1 - Dice(iKey - 1)\held
              GameState\diceHeld[iKey - 1] = Dice(iKey - 1)\held
            EndIf

            PrevDigitDown(iKey) = digitDown
          Next
        EndIf
        
        ; Change AI difficulty (only in VS AI mode)
        If GameState\gameMode = #MODE_VS_AI
          If dPressed
            GameState\aiDifficulty = GameState\aiDifficulty + 1
            If GameState\aiDifficulty > #AI_HARD
              GameState\aiDifficulty = #AI_EASY
            EndIf
            Select GameState\aiDifficulty
              Case #AI_EASY : GameState\message = "AI Difficulty: EASY"
              Case #AI_MEDIUM : GameState\message = "AI Difficulty: MEDIUM"
              Case #AI_HARD : GameState\message = "AI Difficulty: HARD"
            EndSelect
          EndIf
        EndIf
        
        ; Score selection (only after at least one roll)
        If enterPressed And GameState\rollsLeft < #MAX_ROLLS
        Define i, category = -1, bestScore = -1
        Define Dim tempDice.i(#NUM_DICE - 1)
        Define score
        
        ; Find best available category for player
        For i = 0 To #NUM_DICE - 1
          tempDice(i) = GameState\diceValues[i]
        Next
        
        For i = 0 To #NUM_CATEGORIES - 1
          If Categories(i)\playerUsed = 0
            score = CalculateScore(i, tempDice())
            If score > bestScore Or category = -1
              bestScore = score
              category = i
            EndIf
          EndIf
        Next
        
        If category >= 0
          score = CalculateScore(category, tempDice())
          Categories(category)\playerScore = score
          Categories(category)\playerUsed = 1
          
          ; Send score to network opponent
          If GameState\networkActive
            Define scoreData.s = Str(category) + "," + Str(score)
            SendPacket(#PKT_SCORE, scoreData)
          EndIf
          
          ; Reset for next turn
          For i = 0 To #NUM_DICE - 1
            Dice(i)\held = 0
            GameState\diceHeld[i] = 0
          Next
          
          ; Switch turns based on mode
          If GameState\networkActive
            ; In multiplayer, switch between 0 (host) and 1 (client)
            If NetworkState\isHost
              GameState\currentPlayer = 1  ; Switch to client
            Else
              GameState\currentPlayer = 0  ; Switch to host
            EndIf
          Else
            ; In single player, switch to AI
            GameState\currentPlayer = 1
          EndIf
          
          GameState\rollsLeft = #MAX_ROLLS
          GameState\message = "You scored " + Str(score) + " in " + Categories(category)\name
          
          ; Send turn end packet with round number (host only)
          If GameState\networkActive
            If NetworkState\isHost
              SendPacket(#PKT_TURN_END, Str(GameState\round))
            Else
              SendPacket(#PKT_TURN_END, "")
            EndIf
          EndIf
        EndIf
        EndIf  ; End of waiting for opponent check
      EndIf
    Else
      ; Not my turn - wait for opponent
      If GameState\gameMode = #MODE_VS_AI
        AITakeTurn(deltaTime)
      ElseIf GameState\networkActive
        ; Network opponent - just wait for their packets
        ProcessNetworkPackets()
      EndIf
    EndIf
  Else
    ; Game over
    If KeyboardPushed(#PB_Key_Space)
      DisconnectNetwork()
      NewGame()
    EndIf
  EndIf
  
  ; ESC key handling - only disconnect/return to menu, never exit
  If escPressed
    If Not GameState\inMenu
      ; In-game: disconnect and return to menu
      DisconnectNetwork()
      GameState\inMenu = 1
      GameState\message = ""
    EndIf
    ; In menu: do nothing (must use Exit Game option)
  EndIf
  
  ; Process network packets if active
  If GameState\networkActive
    ProcessNetworkPackets()
  EndIf

   ; Update edge states (end of frame)
   ; Force-release Space when we consume a press, to prevent double-triggers
   If spacePressed
     PrevSpaceDown = 1
   Else
     PrevSpaceDown = spaceDown
   EndIf
  PrevEnterDown = enterDown
  PrevDDown = dDown
  PrevUpDown = upDown
  PrevDownDown = downDown
  PrevLeftDown = leftDown
  PrevRightDown = rightDown
  PrevHDown = hDown
  PrevJDown = jDown
  PrevEscDown = escDown
  
  ; Update and render
  UpdateDice(deltaTime)
  
  RenderWorld()
  
   If GameState\inMenu
     DrawMenu()
   Else
     DrawUI()
   EndIf
  
  FlipBuffers()
  
Until WindowEvent() = #PB_Event_CloseWindow
End


; IDE Options = PureBasic 6.30 beta 7 (Windows - x64)
; CursorPosition = 21
; FirstLine = 9
; Folding = -----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = Yahtzee_3D.ico
; Executable = ..\yahtzee_3d.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = Yahtzee_3D
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = Yahtzee game for 2 players with instructions
; VersionField7 = Yahtzee_3D
; VersionField8 = Yahtzee_3D.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60