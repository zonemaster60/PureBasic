Enumeration TileTypes
  #Floor
  #Wall
  #Exit
EndEnumeration
Prototype StepOnTileProc(*Tile, *Monster)
Structure TTile
  x.w
  y.w
  Sprite.u
  Passable.a
  TileType.a
  *Monster.TMonster
  StepOn.StepOnTileProc
  HasTreasure.a
  EffectCounter.b
  SpriteEffect.a
EndStructure
Enumeration MonsterTypes
  #Player
  #Bird
  #Snake
  #Tank
  #Eater
  #Jester
EndEnumeration
Prototype DoStuffProc(*Monster)
Prototype UpdateMonsterProc(*Monster)
Prototype SpellProc(*Caster)
Structure TMonster
  *Tile.TTile
  Sprite.u
  Hp.f
  MonsterType.a
  Dead.a
  DoStuff.DoStuffProc
  AttackedThisTurn.a
  Stunned.a
  Update.UpdateMonsterProc
  TeleportCounter.b
  OffsetX.f
  OffsetY.f
  List Spells.b()
  Array LastMove.b(1)
  BonusAttack.a
  Shield.b
EndStructure
Enumeration SpellTypes
  #SpellWoop
  #SpellQuake
  #SpellMaelstrom
  #SpellMulligan
  #SpellAura
  #SpellDash
  #SpellDig
  #SpellKingMaker
  #SpellAlchemy
  #SpellPower
  #SpellBubble
  #SpellBravery
  #SpellBolt
  #SpellCross
  #SpellEx
  #SpellVampire
  #SpellTeleport
EndEnumeration
Enumeration GameResources
  #SpriteSheet
  #TitleBackground
  #Bitmap_Font_Sprite
  #SoundHit1
  #SoundHit2
  #SoundTreasure
  #SoundNewLevel
  #SoundSpell
EndEnumeration
Enumeration GameSprites
  #SpritePlayer
  #SpritePlayerDeath
  #SpriteFloor
  #SpriteWall
  #SpriteBird
  #SpriteSnake
  #SpriteTank
  #SpriteEater
  #SpriteJester
  #SpriteHp
  #SpriteTeleport
  #SpriteExit
  #SpriteTreasure
  #SpriteHeal
  #SpriteExplosion
  #SpriteBolt
EndEnumeration
Structure TScore
  Score.u
  Run.u
  TotalScore.l
  Active.a
EndStructure
Prototype.a CallBackProc();our callback prototype
Global NumPlayerSpells.a, MaxSpellIndex.a, LevelStarted.a = #False
#No_Spell = -1
Global TileSize.a = 64, NumTiles.a = 9, UIWidth.u = 4, GameWidth.u = TileSize * (NumTiles + UIWidth), GameHeight.u = TileSize * NumTiles,ExitGame.a = #False, SoundMuted.a = #False
Global BasePath.s = "data" + #PS$, ElapsedTimneInS.f, LastTimeInMs.q, SoundInitiated.i = #False
Global Dim Tiles.TTile(NumTiles - 1, NumTiles - 1), *RandomPassableTile.TTile, MaxSpells.a = 17, Dim Spells.i(MaxSpells - 1), NewMap SpellNames.s()
Global Level.a, Player.TMonster, NewList Monsters.TMonster(), MaxHp.a = 6, GameState.s = "loading", StartingHp.a = 3, NumLevels.a = 6
Global SpawnCounter.w, SpawnRate.w, Score.a, NewList Scores.TScore(), ShakeAmount.a = 0, ShakeX.f = 0.0, ShakeY.f = 0.0
Declare PlaySoundEffect(Sound.a)
Declare.i SpawnMonster()
Declare GenerateMonsters()
Declare ReplaceTile(NewTileType.a, x.w, y.w)
Declare InitMonster(*Monster.TMonster, *Tile.TTile, Sprite.u, Hp.b, MonsterType.a,
                            DoStuff.DoStuffProc, UpdateMonster.UpdateMonsterProc, TeleportCounter.b)
Declare.a GetTileDistance(*TileA.TTile, *TileB.TTile)
Declare.a TryMonsterMove(*Monster.TMonster, Dx.w, Dy.w)
Declare RenderFrame()
Declare UpdateMonster(*Monster.TMonster)
Declare DoEaterSuff(*Eater.TMonster)
Declare DoJesterStuff(*Jester.TMonster)
Declare AddMonsterSpell(*Monster.TMonster)
Procedure GetScores(List ReturnedScores.TScore())
  ClearList(ReturnedScores())
  CopyList(Scores(), ReturnedScores())
EndProcedure
Procedure AddScore(Score.a, Won.a)
  NewList TheScores.TScore()
  GetScores(TheScores())
  NewScore.TScore\Score = Score
  NewScore\Run = 1
  NewScore\TotalScore = Score
  NewScore\Active = Won
  IsEmpty.a = Bool(Not LastElement(TheScores()))
  If Not IsEmpty
    LastScore.TScore = TheScores()
    DeleteElement(TheScores(), #True)
    If LastScore\Active
      NewScore\Run = LastScore\Run + 1
      NewScore\TotalScore + LastScore\TotalScore
    Else
      AddElement(TheScores())
      TheScores() = LastScore
    EndIf
  EndIf
  AddElement(TheScores())
  TheScores() = NewScore
  ClearList(Scores())
  CopyList(TheScores(), Scores())
EndProcedure
Procedure LoadSprites()
  SpriteQuality(#PB_Sprite_NoFiltering)
  LoadSprite(#SpriteSheet, BasePath + "graphics" + #PS$ + "spritesheet.png", #PB_Sprite_AlphaBlending)
  LoadSprite(#TitleBackground, BasePath + "graphics" + #PS$ + "title-background.png", #PB_Sprite_AlphaBlending)
  LoadSprite(#Bitmap_Font_Sprite, BasePath + "graphics" + #PS$ + "font.png", #PB_Sprite_AlphaBlending)
EndProcedure
Procedure DrawSprite(SpriteIndex.u, x.f, y.f, Intensity.a = 255)
  ClipSprite(#SpriteSheet, SpriteIndex * 16, 0, 16, 16)
  ZoomSprite(#SpriteSheet, TileSize, TileSize)
  DisplayTransparentSprite(#SpriteSheet, x * TileSize + ShakeX, y * TileSize + ShakeY, Intensity)
EndProcedure
Procedure DrawBitmapText(x.f, y.f, Text.s, CharWidthPx.a = 16, CharHeightPx.a = 24);draw text is too slow on linux, let's try to use bitmap fonts
  ClipSprite(#Bitmap_Font_Sprite, #PB_Default, #PB_Default, #PB_Default, #PB_Default)
  ZoomSprite(#Bitmap_Font_Sprite, #PB_Default, #PB_Default) : LenText = Len(Text)
  For i.i = 1 To LenText;loop the string Text char by char
    AsciiValue.a = Asc(Mid(Text, i, 1))
    ClipSprite(#Bitmap_Font_Sprite, (AsciiValue - 32) % 16 * 8, (AsciiValue - 32) / 16 * 12, 8, 12)
    ZoomSprite(#Bitmap_Font_Sprite, CharWidthPx, CharHeightPx)
    DisplayTransparentSprite(#Bitmap_Font_Sprite, x + (i - 1) * CharWidthPx, y)
  Next
EndProcedure
Procedure.s RightPad(TextList.s)
  FinalText.s = ""
  QtdTexts.a = CountString(TextList, "|") + 1
  For j = 1 To QtdTexts
    Text.s = StringField(TextList, j, "|")
    For i = Len(Text) To 10 - 1
      Text = Text + " "
    Next i
    FinalText = FinalText + Text
  Next
  ProcedureReturn FinalText
EndProcedure
Procedure SortScores(List Scores.TScore())
  Define i.w, j.w, ScoresSize.w = ListSize(Scores())
  For i = 0 To ScoresSize - 2
    For j = 0 To ScoresSize - i  - 2
      *First.TScore = SelectElement(Scores(), j)
      *Second.TScore = SelectElement(Scores(), j + 1)
      If *First\TotalScore < *Second\TotalScore
        SwapElements(Scores(), *First, *Second)
      EndIf
    Next j
  Next i
EndProcedure
Procedure DrawScores()
  NewList TheScores.TScore()
  GetScores(TheScores())
  If ListSize(TheScores()) > 0
    Header.s = RightPad("Run:|Score:|Total:")
    DrawBitmapText((GameWidth - Len(Header) * 16) / 2, GameHeight / 2 + 30, Header)
    LastElement(TheScores())
    NewestScore.TScore = TheScores()
    DeleteElement(TheScores(), #True)
    SortScores(TheScores())
    ResetList(TheScores())
    AddElement(TheScores())
    i.u = 0
    TheScores()\Active = NewestScore\Active
    TheScores()\Run = NewestScore\Run
    TheScores()\Score = NewestScore\Score
    TheScores()\TotalScore = NewestScore\TotalScore
    ForEach TheScores()
      ScoreText.s = RightPad(Str(TheScores()\Run) + "|" + Str(TheScores()\Score) + "|" + Str(TheScores()\TotalScore))
      DrawBitmapText((GameWidth - Len(ScoreText) * 16) / 2, GameHeight / 2 + 64 + i * 24, ScoreText)
      i + 1
    Next
  EndIf
EndProcedure
Procedure ShowTitle()
  DisplayTransparentSprite(#TitleBackground, 0, 0)
  GameState = "title"
  TitleX.f = (GameWidth - Len("RogueLike") * 32) / 2
  TitleY.f = (GameHeight / 2 - 110)
  DrawBitmapText(TitleX, TitleY, "RogueLike", 32, 48)
  TitleX = (GameWidth - Len("Like") * 48) / 2
  TitleY = (GameHeight / 2 - 50)
  DrawBitmapText(TitleX + 10, TitleY, "Like", 48, 72)
  DrawBitmapText(TitleX - 80, TitleY + 310, "Press Any Key to Start", 16, 24)
  DrawScores()
EndProcedure
Procedure.a InBounds(x.w, y.w)
  ProcedureReturn Bool(x > 0 And y > 0 And x < NumTiles - 1 And y < NumTiles - 1)
EndProcedure
Procedure StepOnFloor(*Tile.TTile, *Monster.TMonster)
  If *Monster\MonsterType = #Player And *Tile\HasTreasure
    Score + 1
    If (Score % 3) = 0 And NumPlayerSpells < 9
      NumPlayerSpells + 1
      AddMonsterSpell(@Player)
    EndIf
    PlaySoundEffect(#SoundTreasure)
    *Tile\HasTreasure = #False
    SpawnMonster()
  EndIf
EndProcedure
Procedure.u GenerateTiles()
  NumPassableTiles.u = 0
  For i.a = 0 To NumTiles - 1
    For j.a = 0 To NumTiles - 1
      If (Random(100, 0) / 100.0 < 0.3) Or (Not InBounds(i, j))
        Tiles(i, j)\x = i
        Tiles(i, j)\y = j
        Tiles(i, j)\Sprite = #SpriteWall
        Tiles(i, j)\Passable = #False
        Tiles(i, j)\TileType = #Wall
        Tiles(i, j)\StepOn = #Null
      Else
        Tiles(i, j)\x = i
        Tiles(i, j)\y = j
        Tiles(i, j)\Sprite = #SpriteFloor
        Tiles(i, j)\Passable = #True
        Tiles(i, j)\TileType = #Floor
        Tiles(i, j)\StepOn = @StepOnFloor()
        NumPassableTiles + 1
      EndIf
      Tiles(i, j)\Monster = #Null
      Tiles(i, j)\HasTreasure = #False
      Tiles(i, j)\EffectCounter = 0
    Next j
  Next i
  ProcedureReturn NumPassableTiles
EndProcedure
Procedure.i GetTile(x.w, y.w)
  If (x < 0 Or x > NumTiles - 1) Or (y < 0 Or y > NumTiles -1)
    ProcedureReturn #Null
  EndIf
  ProcedureReturn @Tiles(x, y)
EndProcedure
Procedure GetRandomPassableTile()
  x.w = Random(NumTiles - 1, 0)
  y = Random(NumTiles - 1, 0)
  *RandomPassableTile = GetTile(x, y)
  ProcedureReturn Bool(*RandomPassableTile\Passable And Not *RandomPassableTile\Monster)
EndProcedure
Procedure TryTo(Description.s, Callback.CallbackProc)
  For i.u = 1000 To 1 Step -1
    If Callback()
      ProcedureReturn
    EndIf
  Next i
EndProcedure
Procedure.i RandomPassableTile()
  TryTo("get random passable tile", @GetRandomPassableTile())
  ProcedureReturn *RandomPassableTile
EndProcedure
Procedure.i GetTileNeighbor(*Tile.TTile, Dx.w, Dy.w)
  ProcedureReturn GetTile(*Tile\x + Dx, *Tile\y + Dy)
EndProcedure
Procedure GetTileAdjacentNeighbors(*Tile.TTile, List AdjacentNeighbors.i())
  ClearList(AdjacentNeighbors())
  AddElement(AdjacentNeighbors())
  AdjacentNeighbors() = GetTileNeighbor(*Tile, 0, -1)
  AddElement(AdjacentNeighbors())
  AdjacentNeighbors() = GetTileNeighbor(*Tile, 0, 1)
  AddElement(AdjacentNeighbors())
  AdjacentNeighbors() = GetTileNeighbor(*Tile, -1, 0)
  AddElement(AdjacentNeighbors())
  AdjacentNeighbors() = GetTileNeighbor(*Tile, 1, 0)
EndProcedure
Procedure GetTileAdjacentPassableNeighbors(*Tile.TTile, List AdjacentPassableNeighbors.i())
  Define NewList AdjacentNeighbors.i() : ClearList(AdjacentPassableNeighbors())
  GetTileAdjacentNeighbors(*Tile, AdjacentNeighbors())
  ForEach AdjacentNeighbors()
    *AdjacentNeighbor.TTile = AdjacentNeighbors()
    If *AdjacentNeighbor = #Null
      Continue
    EndIf
    If *AdjacentNeighbor\Passable
      AddElement(AdjacentPassableNeighbors())
      AdjacentPassableNeighbors() = *AdjacentNeighbor
    EndIf
  Next
EndProcedure
Procedure GetTileConnectedTiles(*Tile.TTile, List ConnectedTiles.i())
  ClearList(ConnectedTiles())
  AddElement(ConnectedTiles())
  ConnectedTiles() = *Tile
  NewList TilesToCheck.i()
  AddElement(TilesToCheck())
  TilesToCheck() = *Tile
  ResetList(TilesToCheck())
  While(NextElement(TilesToCheck()))
    *CurrentTile.TTile = TilesToCheck()
    FirstElement(TilesToCheck())
    DeleteElement(TilesToCheck())
    NewList PassableNeighbors.i()
    GetTileAdjacentPassableNeighbors(*CurrentTile, PassableNeighbors())
    ForEach ConnectedTiles()
      ForEach PassableNeighbors()
        If PassableNeighbors() = ConnectedTiles()
          DeleteElement(PassableNeighbors())
        EndIf
      Next
    Next
    NewList CopyPassableNeighBors()
    CopyList(PassableNeighbors(), CopyPassableNeighBors())
    MergeLists(PassableNeighbors(), ConnectedTiles())
    MergeLists(CopyPassableNeighBors(), TilesToCheck())
    ResetList(TilesToCheck())
  Wend
EndProcedure
Procedure GenerateMap()
  PassableTiles.u = GenerateTiles()
  *RandomPassableTile = RandomPassableTile()
  NewList ConnectedTiles.i()
  GetTileConnectedTiles(*RandomPassableTile, ConnectedTiles())
  ProcedureReturn Bool(PassableTiles = ListSize(ConnectedTiles()))
EndProcedure
Procedure GenerateLevel()
  TryTo("generate map", @GenerateMap())
  GenerateMonsters()
  For i.a = 1 To 3
    *Tile.TTile = RandomPassableTile()
    *Tile\HasTreasure = #True
  Next
EndProcedure
Procedure.a GetRandomSpell()
  ProcedureReturn Random(MaxSpellIndex, #SpellWoop)
EndProcedure
Procedure UpdatePlayer(*Player.TMonster)
  If *Player\Shield > 0
    *Player\Shield - 1
  EndIf
EndProcedure
Procedure InitPlayer(*Player.TMonster, *Tile.TTile, Sprite.u, Hp.b)
  InitMonster(*Player, *Tile, Sprite, Hp, #Player, #Null, @UpdatePlayer(), 0)
  For i.a = 1 To NumPlayerSpells;initializing the player's spells list
    AddElement(*Player\Spells())
    *Player\Spells() = GetRandomSpell()
  Next
EndProcedure
Procedure AddMonsterSpell(*Monster.TMonster)
  AddElement(*Monster\Spells())
  *Monster\Spells() = GetRandomSpell()
EndProcedure
Procedure StartLevel(StartingHp.a, KeepPlayerSpells.a = #False)
  SpawnRate = 15
  SpawnCounter = SpawnRate
  GenerateLevel()
  LevelStarted = #True
  *RandomPassableTile.TTile = RandomPassableTile()
  If Not KeepPlayerSpells
    InitPlayer(@Player, *RandomPassableTile, #SpritePlayer, StartingHp)
  Else
    NewList PlayerSpells.a()
    CopyList(Player\Spells(), PlayerSpells())
    InitPlayer(@Player, *RandomPassableTile, #SpritePlayer, StartingHp)
    ClearList(Player\Spells())
    CopyList(PlayerSpells(), Player\Spells())
  EndIf
  *RandomPassableTile = RandomPassableTile()
  ReplaceTile(#Exit, *RandomPassableTile\x, *RandomPassableTile\y)
EndProcedure
Procedure StepOnExit(*Tile.TTile, *Monster.TMonster)
  If *Monster\MonsterType = #Player
    PlaySoundEffect(#SoundNewLevel)
    If Level = NumLevels
      AddScore(Score, #True)
      ShowTitle()
    Else
      Player\Hp + 1
      If Player\Hp > MaxHp
        Player\Hp = MaxHp
      EndIf
      Level + 1
      StartLevel(Player\Hp)
    EndIf
  EndIf
EndProcedure
Procedure ReplaceTile(NewTileType.a, x.w, y.w)
  If NewTileType = #Floor
    Tiles(x, y)\Sprite = #SpriteFloor
    Tiles(x, y)\Passable = #True
    Tiles(x, y)\TileType = #Floor
    Tiles(x, y)\StepOn = @StepOnFloor()
  ElseIf NewTileType = #Wall
    Tiles(x, y)\Sprite = #SpriteWall
    Tiles(x, y)\Passable = #False
    Tiles(x, y)\TileType = #Wall
  ElseIf NewTileType = #Exit
    Tiles(x, y)\Sprite = #SpriteExit
    Tiles(x, y)\Passable = #True
    Tiles(x, y)\TileType = #Exit
    Tiles(x, y)\StepOn = @StepOnExit()
  EndIf
EndProcedure
Procedure MoveMonster(*Monster.TMonster, *NewTile.TTile)
  If *Monster\Tile <> #Null
    *Monster\Tile\Monster = #Null
    *Monster\OffsetX = *Monster\Tile\x - *NewTile\x
    *Monster\OffsetY = *Monster\Tile\y - *NewTile\y
  EndIf
  *Monster\Tile = *NewTile
  *NewTile\Monster = *Monster
  If *NewTile\StepOn <> #Null
  *NewTile\StepOn(*NewTile, *Monster) : EndIf
EndProcedure
Procedure InitMonster(*Monster.TMonster, *Tile.TTile, Sprite.u, Hp.b, MonsterType.a,
    DoStuff.DoStuffProc, UpdateMonsterProc.UpdateMonsterProc, TeleportCounter.b)
  *Monster\Sprite = Sprite
  *Monster\Hp = Hp
  *Monster\MonsterType = MonsterType
  *Monster\Dead = #False
  *Monster\DoStuff = DoStuff
  *Monster\AttackedThisTurn = #False
  *Monster\Stunned = #False
  *Monster\Update = UpdateMonsterProc
  *Monster\TeleportCounter = TeleportCounter
  *Monster\OffsetX = 0.0
  *Monster\OffsetY = 0.0
  *Monster\Tile = #Null
  ClearList(*Monster\Spells())
  MoveMonster(*Monster, *Tile)
  *Monster\LastMove(0) = -1
  *Monster\LastMove(1) = 0
  *Monster\BonusAttack = 0
  *Monster\Shield = 0
EndProcedure
Procedure DoMonsterStuff(*Monster.TMonster)
  NewList AdjacentPassableNeighbors.i()
  GetTileAdjacentPassableNeighbors(*Monster\Tile, AdjacentPassableNeighbors())
  ForEach AdjacentPassableNeighbors()
    *CurrentTile.TTile = AdjacentPassableNeighbors()
    If *CurrentTile\Monster = #Null Or *CurrentTile\Monster\MonsterType = #Player
      Continue
    Else
      DeleteElement(AdjacentPassableNeighbors())
    EndIf
  Next
  ResetList(AdjacentPassableNeighbors())
  If ListSize(AdjacentPassableNeighbors()) > 0
    SmallestDistance.w = NumTiles * NumTiles
    *ClosestPassableTile.TTile = #Null
    ForEach AdjacentPassableNeighbors()
      *CurrentTile.TTile = AdjacentPassableNeighbors()
      Distance.a = GetTileDistance(*CurrentTile, Player\Tile)
      If Distance < SmallestDistance
        *ClosestPassableTile = *CurrentTile
        SmallestDistance = Distance
      EndIf
    Next
    TryMonsterMove(*Monster, *ClosestPassableTile\x - *Monster\Tile\x, *ClosestPassableTile\y - *Monster\Tile\y)
  EndIf
EndProcedure
Procedure DoSnakeStuff(*Snake.TMonster)
  *Snake\AttackedThisTurn = #False
  DoMonsterStuff(*Snake)
  If Not *Snake\AttackedThisTurn
    DoMonsterStuff(*Snake)
  EndIf
EndProcedure
Procedure UpdateTankMonster(*Monster.TMonster)
  StartStunned.a = *Monster\Stunned
  UpdateMonster(*Monster)
  If Not StartStunned
    *Monster\Stunned = #True
  EndIf
EndProcedure
Procedure.i InitAMonster(*Tile.TTile, MonsterType.a)
  AddElement(Monsters())
  Select MonsterType
    Case #Bird
      InitMonster(@Monsters(), *Tile, #SpriteBird, 3, #Bird, @DoMonsterStuff(), @UpdateMonster(), 2)
    Case #Snake
      InitMonster(@Monsters(), *Tile, #SpriteSnake, 1, #Snake, @DoSnakeStuff(), @UpdateMonster(), 2)
    Case #Tank
      InitMonster(@Monsters(), *Tile, #SpriteTank, 2, #Tank, @DoMonsterStuff(), @UpdateTankMonster(), 2)
    Case #Eater
      InitMonster(@Monsters(), *Tile, #SpriteEater, 1, #Eater, @DoEaterSuff(), @UpdateMonster(), 2)
    Case #Jester
      InitMonster(@Monsters(), *Tile, #SpriteJester, 2, #Jester, @DoJesterStuff(), @UpdateMonster(), 2)
  EndSelect
  ProcedureReturn @Monsters()
EndProcedure
Procedure.i SpawnMonster()
  ProcedureReturn InitAMonster(RandomPassableTile(), Random(#Jester, #Bird))
EndProcedure
Procedure GenerateMonsters()
  ClearList(Monsters())
  NumMonsters.u = Level + 1
  For i.u = 1 To NumMonsters
    SpawnMonster()
  Next i
EndProcedure
Procedure.a GetTileDistance(*TileA.TTile, *TileB.TTile)
  ProcedureReturn Abs(*TileA\x - *TileB\x) + Abs(*TileA\y - *TileB\y)
EndProcedure
Procedure DieMonster(*Monster.TMonster)
  *Monster\Dead = #True
  *Monster\Tile\Monster = #Null
  *Monster\Sprite = #SpritePlayerDeath
EndProcedure
Procedure HitMonster(*Monster.TMonster, Damage.a)
  If *Monster\Shield > 0
    ProcedureReturn
  EndIf
  *Monster\hp - Damage
  If *Monster\hp <= 0
    DieMonster(*Monster)
  EndIf
  If *Monster\MonsterType = #Player
    PlaySoundEffect(#SoundHit1)
  Else
    PlaySoundEffect(#SoundHit2)
  EndIf
EndProcedure
Procedure.a TryMonsterMove(*Monster.TMonster, Dx.w, Dy.w)
  *NewTile.TTile = GetTileNeighbor(*Monster\Tile, Dx, Dy)
  If *NewTile <> #Null And *NewTile\Passable
    *Monster\LastMove(0) = Dx
    *Monster\LastMove(1) = Dy
    If *NewTile\Monster = #Null
      MoveMonster(*Monster, *NewTile)
    Else
      If *Monster\MonsterType = #Player Or *NewTile\Monster\MonsterType = #Player
        *Monster\AttackedThisTurn = #True
        *NewTile\Monster\Stunned = #True
        HitMonster(*NewTile\Monster, 1 + *Monster\BonusAttack)
        *Monster\BonusAttack = 0
        *Monster\OffsetX = (*NewTile\x - *Monster\Tile\x) / 2
        *Monster\OffsetY = (*NewTile\y - *Monster\Tile\y) / 2
        ShakeAmount = 5
      EndIf
    EndIf
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure
Procedure HealMonsterEater(*Eater.TMonster, Damage.f)
  *Eater\Hp + Damage
  If *Eater\Hp > MaxHp
    *Eater\Hp = MaxHp
  EndIf
EndProcedure
Procedure DoEaterSuff(*Eater.TMonster)
  NewList AdjacentNeighbors.i()
  GetTileAdjacentNeighbors(*Eater\Tile, AdjacentNeighbors())
  ForEach AdjacentNeighbors()
    *CurrentTile.TTile = AdjacentNeighbors()
    If Not *CurrentTile\Passable And InBounds(*CurrentTile\x, *CurrentTile\y)
      Continue
    Else
      DeleteElement(AdjacentNeighbors())
    EndIf
  Next
  If ListSize(AdjacentNeighbors()) > 0
    FirstElement(AdjacentNeighbors())
    *Tile.TTile = AdjacentNeighbors()
    ReplaceTile(#Floor, *Tile\x, *Tile\y)
    HealMonsterEater(*Eater.TMonster, 0.5)
  Else
    DoMonsterStuff(*Eater)
  EndIf
EndProcedure
Procedure UpdateMonster(*Monster.TMonster)
  If *Monster\TeleportCounter > 0
    *Monster\TeleportCounter - 1
  EndIf
  If *Monster\Stunned Or *Monster\TeleportCounter > 0
    *Monster\Stunned = #False
    ProcedureReturn
  EndIf
  If *Monster\DoStuff <> #Null
    *Monster\DoStuff(*Monster)
  EndIf
EndProcedure
Procedure DoJesterStuff(*Jester.TMonster)
  NewList Neighbors.i()
  GetTileAdjacentPassableNeighbors(*Jester\Tile, Neighbors())
  If ListSize(Neighbors()) > 0
    RandomizeList(Neighbors())
    FirstElement(Neighbors())
    *NewTile.TTile = Neighbors()
    TryMonsterMove(*Jester, *NewTile\x - *Jester\Tile\x, *NewTile\y - *Jester\Tile\y)
  EndIf
EndProcedure
Procedure Tick()
  ForEach Monsters()
    If Monsters()\hp > 0 And GameState = "running"
      Monsters()\Update(@Monsters())
    Else
      DeleteElement(Monsters())
    EndIf
  Next
  Player\Update(@Player)
  If Player\Dead
    AddScore(Score, #False)
    GameState = "dead"
    ShowTitle()
  EndIf
  SpawnCounter - 1
  If SpawnCounter <= 0
    SpawnMonster()
    SpawnCounter = SpawnRate
    SpawnRate - 1
  EndIf
EndProcedure
Procedure.a TryPlayerMonsterMove(*Player.TMonster, Dx.w, Dy.w)
  If TryMonsterMove(*Player, Dx, Dy)
    Tick()
  EndIf
EndProcedure
Procedure SetTileEffect(*Tile.TTile, SpriteEffect.a)
  *Tile\SpriteEffect = SpriteEffect
  *Tile\EffectCounter = 30
EndProcedure
Procedure BoltTravel(*Caster.TMonster, Array Direction.b(1), Effect.a, Damage.a)
  *NewTile.TTile = *Caster\Tile
  While #True
    *TestTile.TTile = GetTileNeighbor(*NewTile, Direction(0), Direction(1))
    If *TestTile\Passable
      *NewTile = *TestTile
      If *NewTile\Monster <> #Null
        HitMonster(*NewTile\Monster, Damage)
      EndIf
      SetTileEffect(*NewTile, Effect)
    Else
      Break
    EndIf
  Wend
EndProcedure
Procedure WoopSpell(*Caster.TMonster)
  MoveMonster(*Caster, RandomPassableTile())
EndProcedure
Procedure QuakeSpell(*Caster.TMonster)
  For i.a = 0 To NumTiles - 1
    For j.a = 0 To NumTiles - 1
      *Tile.TTile = GetTile(i, j)
      If *Tile\Monster <> #Null
        NewList AdjacentPassableNeighbors.i()
        GetTileAdjacentPassableNeighbors(*Tile, AdjacentPassableNeighbors())
        NumWalls.a = 4 - ListSize(AdjacentPassableNeighbors())
        HitMonster(*Tile\Monster, NumWalls * 2)
      EndIf
    Next j
  Next i
  ShakeAmount = 20
EndProcedure
Procedure MaelStromSpell(*Caster.TMonster)
  ForEach Monsters()
    MoveMonster(@Monsters(), RandomPassableTile())
    Monsters()\TeleportCounter = 2
  Next
EndProcedure
Procedure MulliganSpell(*Caster.TMonster)
  StartLevel(1, #True)
EndProcedure
Procedure AuraSpell(*Caster.TMonster)
  NewList AdjacentNeighbors.i()
  GetTileAdjacentNeighbors(*Caster\Tile, AdjacentNeighbors())
  ForEach AdjacentNeighbors()
    *AdjacentTile.TTile = AdjacentNeighbors()
    SetTileEffect(*AdjacentTile, #SpriteHeal)
    If *AdjacentTile\Monster <> #Null
      HealMonsterEater(*AdjacentTile\Monster, 1)
    EndIf
  Next
  SetTileEffect(*Caster\Tile, #SpriteHeal)
  HealMonsterEater(*Caster, 1)
EndProcedure
Procedure DashSpell(*Caster.TMonster)
  *NewTile.TTile = *Caster\Tile
  While #True
    *TestTile.TTile = GetTileNeighbor(*NewTile, Player\LastMove(0), Player\LastMove(1))
    If *TestTile\Passable And *TestTile\Monster = #Null
      *NewTile = *TestTile
    Else
      Break
    EndIf
  Wend
  If *Caster\Tile <> *NewTile
    MoveMonster(*Caster, *NewTile)
    NewList AdjacentNeighbors.i()
    GetTileAdjacentNeighbors(*NewTile, AdjacentNeighbors())
    ForEach AdjacentNeighbors()
      *NeighborTile.TTile = AdjacentNeighbors()
      If *NeighborTile\Monster <> #Null
        SetTileEffect(*NeighborTile, #SpriteExplosion)
        *NeighborTile\Monster\Stunned = #True
        HitMonster(*NeighborTile\Monster, 1)
      EndIf
    Next
  EndIf
EndProcedure
Procedure DigSpell(*Caster.TMonster)
  For i.a = 1 To NumTiles - 2
    For j.a = 1 To NumTiles - 2
      If Not Tiles(i, j)\Passable
        ReplaceTile(#Floor, i, j)
      EndIf
    Next j
  Next i
  SetTileEffect(*Caster\Tile, #SpriteHeal)
  HealMonsterEater(*Caster, 2)
EndProcedure
Procedure KingMakerSpell(*Caster.TMonster)
  ForEach Monsters()
    HealMonsterEater(@Monsters(), 1)
    Monsters()\Tile\HasTreasure = #True
  Next
EndProcedure
Procedure AlchemySpell(*Caster.TMonster)
  NewList AdjacentNeighbors.i()
  GetTileAdjacentNeighbors(*Caster\Tile, AdjacentNeighbors())
  ForEach AdjacentNeighbors()
    *CurrentTile.TTile = AdjacentNeighbors()
    If Not *CurrentTile\Passable And InBounds(*CurrentTile\x, *CurrentTile\y)
      ReplaceTile(#Floor, *CurrentTile\x, *CurrentTile\y)
      *CurrentTile\HasTreasure = #True
    EndIf
  Next
EndProcedure
Procedure PowerSpell(*Caster.TMonster)
  *Caster\BonusAttack = 5
EndProcedure
Procedure BubbleSpell(*Caster.TMonster)
  For i.a = ListSize(*Caster\Spells()) - 1 To 1 Step -1
    If SelectElement(*Caster\Spells(), i) And *Caster\Spells() = #No_Spell
      *CurrentSpell.Byte = @*Caster\Spells()
      SelectElement(*Caster\Spells(), i - 1)
      *CurrentSpell\b = *Caster\Spells()
      ChangeCurrentElement(*Caster\Spells(), *CurrentSpell)
    EndIf
  Next
EndProcedure
Procedure BraverySpell(*Caster.TMonster)
  *Caster\Shield = 2
  ForEach Monsters()
    Monsters()\Stunned = #True
  Next
EndProcedure
Procedure BoltSpell(*Caster.TMonster)
  BoltTravel(*Caster, *Caster\LastMove(), Int(#SpriteBolt + Abs(*Caster\LastMove(1))), 4)
EndProcedure
Procedure CrossSpell(*Caster.TMonster)
  Directions.s = "0,-1,0,1,-1,0,1,0"
  NumDirections.a = CountString(Directions, ",") + 1
  For i.a = 0 To (NumDirections / 2) - 1
    Dim Direction.b(1)
    Direction(0) = Val(StringField(Directions, i * 2 + 1, ","))
    Direction(1) = Val(StringField(Directions, i * 2 + 1 + 1, ","))
    BoltTravel(*Caster, Direction(), Int(#SpriteBolt) + Abs(Direction(1)), 2)
  Next
EndProcedure
Procedure ExSpell(*Caster.TMonster)
  Directions.s = "-1,-1,-1,1,1,-1,1,1"
  NumDirections.a = CountString(Directions, ",") + 1
  For i.a = 0 To (NumDirections / 2) - 1
    Dim Direction.b(1)
    Direction(0) = Val(StringField(Directions, i * 2 + 1, ","))
    Direction(1) = Val(StringField(Directions, i * 2 + 1 + 1, ","))
    BoltTravel(*Caster, Direction(), #SpriteExplosion, 3)
  Next
EndProcedure
Procedure VampireSpell(*Caster.TMonster)
  NewList AdjacentNeighbors.i()
  GetTileAdjacentNeighbors(*Caster\Tile, AdjacentNeighbors())
  ForEach AdjacentNeighbors()
    *CurrrentTile.TTile = AdjacentNeighbors()
    If *CurrrentTile\Monster <> #Null
      *CurrrentTile\Monster\Stunned = #True
      HitMonster(*CurrrentTile\Monster, 1)
      HealMonsterEater(*Caster, 1)
      SetTileEffect(*CurrrentTile, #SpriteExplosion)
    EndIf
  Next
  SetTileEffect(*Caster\Tile, #SpriteHeal)
EndProcedure
Procedure TeleportSpell(*Caster.TMonster)
  NumMonsters.a = ListSize(Monsters())
  If NumMonsters < 1
    ProcedureReturn
  EndIf
  RandomMonsterNum.a = Random(NumMonsters - 1, 0)
  *Monster.TMonster = SelectElement(Monsters(), RandomMonsterNum)
  HitMonster(*Monster, *Monster\Hp)
  SetTileEffect(*Monster\Tile, #SpriteExplosion)
  MoveMonster(*Caster, *Monster\Tile)
EndProcedure
Procedure InitSpells()
  Spells(#SpellWoop) = @WoopSpell()
  SpellNames(Str(#SpellWoop)) = "Woop"
  Spells(#SpellQuake) = @QuakeSpell()
  SpellNames(Str(#SpellQuake)) = "Quake"
  Spells(#SpellMaelstrom) = @MaelstromSpell()
  SpellNames(Str(#SpellMaelstrom)) = "Maelstrom"
  Spells(#SpellMulligan) = @MulliganSpell()
  SpellNames(Str(#SpellMulligan)) = "Mulligan"
  Spells(#SpellAura) = @AuraSpell()
  SpellNames(Str(#SpellAura)) = "Aura"
  Spells(#SpellDash) = @DashSpell()
  SpellNames(Str(#SpellDash)) = "Dash"
  Spells(#SpellDig) = @DigSpell()
  SpellNames(Str(#SpellDig)) = "Dig"
  Spells(#SpellKingMaker) = @KingMakerSpell()
  SpellNames(Str(#SpellKingMaker)) = "Kingmaker"
  Spells(#SpellAlchemy) = @AlchemySpell()
  SpellNames(Str(#SpellAlchemy)) = "Alchemy"
  Spells(#SpellPower) = @PowerSpell()
  SpellNames(Str(#SpellPower)) = "Power"
  Spells(#SpellBubble) = @BubbleSpell()
  SpellNames(Str(#SpellBubble)) = "Bubble"
  Spells(#SpellBravery) = @BraverySpell()
  SpellNames(Str(#SpellBravery)) = "Bravery"
  Spells(#SpellBolt) = @BoltSpell()
  SpellNames(Str(#SpellBolt)) = "Bolt"
  Spells(#SpellCross) = @CrossSpell()
  SpellNames(Str(#SpellCross)) = "Cross"
  Spells(#SpellEx) = @ExSpell()
  SpellNames(Str(#SpellEx)) = "Ex"
  Spells(#SpellVampire) = @VampireSpell()
  SpellNames(Str(#SpellVampire)) = "Vampire"
  Spells(#SpellTeleport) = @TeleportSpell()
  SpellNames(Str(#SpellTeleport)) = "Teleport"
  MaxSpellIndex = #SpellTeleport
EndProcedure
Procedure CastMonsterSpell(*Monster.TMonster, Index.a);call this procedure to cast a spell
  If SelectElement(*Monster\Spells(), Index) And *Monster\Spells() <> #No_Spell
    SpellNum.b = *Monster\Spells()
    *Monster\Spells() = #No_Spell
    SpellProcedure.SpellProc = Spells(SpellNum)
    SpellProcedure(*Monster)
    PlaySoundEffect(#SoundSpell)
    Tick()
  EndIf
EndProcedure
Procedure DrawTile(*Tile.TTile)
  DrawSprite(*Tile\Sprite, *Tile\x, *Tile\y)
  If *Tile\HasTreasure
    DrawSprite(#SpriteTreasure, *Tile\x, *Tile\y)
  EndIf
  If *Tile\EffectCounter
    *Tile\EffectCounter - 1
    DrawSprite(*Tile\SpriteEffect, *Tile\x, *Tile\y, *Tile\EffectCounter / 30.0 * 255)
  EndIf
EndProcedure
Procedure PlaySoundEffect(Sound.a)
  If SoundInitiated
    PlaySound(Sound)
  EndIf
EndProcedure
Procedure LoadSounds()
  If SoundInitiated
    SoundPath.s = BasePath + "sounds" + #PS$
    LoadSound(#SoundHit1, SoundPath + "hit1.wav")
    LoadSound(#SoundHit2, SoundPath + "hit2.wav")
    LoadSound(#SoundTreasure, SoundPath + "treasure.wav")
    LoadSound(#SoundNewLevel, SoundPath + "newLevel.wav")
    LoadSound(#SoundSpell, SoundPath + "spell.wav")
  EndIf
EndProcedure
Procedure StartGame()
  Level = 1
  Score = 0
  NumPlayerSpells = 1
  StartLevel(StartingHp)
  GameState = "running"
EndProcedure
Procedure UpdateKeyBoard()
  If (GameState = "title" Or GameState = "dead") And (KeyboardReleased(#PB_Key_Space) Or KeyboardReleased(#PB_Key_All))
    If GameState = "title"
      StartGame()
    ElseIf GameState = "dead"
      ShowTitle()
    EndIf
  EndIf
  If GameState = "running"
    If KeyboardReleased(#PB_Key_W) Or KeyboardReleased(#PB_Key_Up)
      TryPlayerMonsterMove(@Player, 0, -1)
    EndIf
    If KeyboardReleased(#PB_Key_S) Or KeyboardReleased(#PB_Key_Down)
      TryPlayerMonsterMove(@Player, 0, 1)
    EndIf
    If KeyboardReleased(#PB_Key_A) Or KeyboardReleased(#PB_Key_Left)
      TryPlayerMonsterMove(@Player, -1, 0)
    EndIf
    If KeyboardReleased(#PB_Key_D) Or KeyboardReleased(#PB_Key_Right)
      TryPlayerMonsterMove(@Player, 1, 0)
    EndIf
    If KeyboardReleased(#PB_Key_1)
      CastMonsterSpell(@Player, 0)  
    ElseIf KeyboardReleased(#PB_Key_2)
      CastMonsterSpell(@Player, 1)  
    ElseIf KeyboardReleased(#PB_Key_3)
      CastMonsterSpell(@Player, 2)  
    ElseIf KeyboardReleased(#PB_Key_4)
      CastMonsterSpell(@Player, 3)  
    ElseIf KeyboardReleased(#PB_Key_5)
      CastMonsterSpell(@Player, 4)  
    ElseIf KeyboardReleased(#PB_Key_6)
      CastMonsterSpell(@Player, 5)  
    ElseIf KeyboardReleased(#PB_Key_7)
      CastMonsterSpell(@Player, 6)  
    ElseIf KeyboardReleased(#PB_Key_8)
      CastMonsterSpell(@Player, 7)  
    ElseIf KeyboardReleased(#PB_Key_9)
      CastMonsterSpell(@Player, 8)
    EndIf
  EndIf
EndProcedure
If InitSprite() = 0 Or InitKeyboard() = 0
  CompilerIf #PB_Compiler_Processor = #PB_Processor_JavaScript
    MessageRequester("Error", "Sprite system Or keyboard system can't be initialized", #PB_MessageRequester_Error)
  CompilerElse
    MessageRequester("Error", "Sprite system or keyboard system can't be initialized", #PB_MessageRequester_Error)
  CompilerEndIf
  End
EndIf
Procedure Loading()
  Static LoadedElements.a
  LoadedElements + 1
  If LoadedElements = 8
    ShowTitle()
    FlipBuffers()
  EndIf
EndProcedure
Procedure LoadingError(Type, Filename$)
  Debug Filename$ + ": loading error"
EndProcedure
CompilerIf #PB_Compiler_Processor <> #PB_Processor_JavaScript
  UsePNGImageDecoder()
CompilerEndIf
SoundInitiated = InitSound()
CompilerIf #PB_Compiler_Processor = #PB_Processor_JavaScript
  BindEvent(#PB_Event_Loading, @Loading())
  BindEvent(#PB_Event_LoadingError, @LoadingError())
  BindEvent(#PB_Event_RenderFrame, @RenderFrame())
CompilerEndIf
Procedure.f GetMonsterDisplayXY(*Monster.TMonster, IsItX.a)
  If IsItX
    ProcedureReturn *Monster\Tile\x + *Monster\OffsetX
  Else
    ProcedureReturn *Monster\Tile\y + *Monster\OffsetY
  EndIf
EndProcedure
Procedure DrawMonster(*Monster.TMonster)
  If *Monster\TeleportCounter > 0
    DrawSprite(#SpriteTeleport, GetMonsterDisplayXY(*Monster, #True), GetMonsterDisplayXY(*Monster, #False))
  Else
    DrawSprite(*Monster\Sprite, GetMonsterDisplayXY(*Monster, #True), GetMonsterDisplayXY(*Monster, #False))
    For i.b = 0 To *Monster\Hp - 1;draw hp
      ii.b = (i % 3)
      Hpx.f = GetMonsterDisplayXY(*Monster, #True) + (ii) * (5 / 16)
      DrawSprite(#SpriteHp, Hpx, GetMonsterDisplayXY(*Monster, #False) - Round( i / 3, #PB_Round_Down) * (5 /16))
    Next
  EndIf
  *Monster\OffsetX - Sign(*Monster\OffsetX) * (1 / 8)
  *Monster\OffsetY - Sign(*Monster\OffsetY) * (1 / 8)
EndProcedure
Procedure ScreenShake()
  If ShakeAmount
    ShakeAmount - 1
  EndIf
  ShakeAngle = Random(999, 0) / 1000.0 * #PI * 2
  ShakeX = Round(Cos(ShakeAngle) * ShakeAmount, #PB_Round_Nearest)
  ShakeY = Round(Sin(ShakeAngle) * ShakeAmount, #PB_Round_Nearest)
EndProcedure
Procedure Draw()
  If LevelStarted
    ClearScreen(RGB(0,0,0))
    ScreenShake()
    For i.b = 0 To NumTiles - 1
      For j.b = 0 To NumTiles - 1
        If GetTile(i, j) = #Null
          Continue;the tile is out of the visible screen
        Else
          DrawTile(GetTile(i, j))
        EndIf
      Next j
    Next i
    ForEach Monsters()
      DrawMonster(@Monsters())
    Next
    DrawMonster(@Player)
    DrawBitmapText(GameWidth - UIWidth * TileSize + 25, 40, "Level: " + Str(Level))
    DrawBitmapText(GameWidth - UIWidth * TileSize + 25, 70, "Score: " + Str(Score))
    For i = 0 To NumPlayerSpells - 1
      SpellName.s = ""
      If SelectElement(Player\Spells(), i)
        SpellName = SpellNames(Str(Player\Spells()))
      EndIf
      SpellText.s = Str(i + 1) + ")" + SpellName
      DrawBitmapText(GameWidth - UIWidth * TileSize + 25, 110 + i * 40, SpellText)
    Next
  EndIf
  If GameState = "title"
    ShowTitle()
  EndIf
EndProcedure
Procedure RenderFrame()
  ElapsedTimeInS = (ElapsedMilliseconds() - LastTimeInMs) / 1000.0
  If ElapsedTimeInS >= 0.05;never let the elapsed time be higher than 20 fps
    ElapsedTimeInS = 0.05
  EndIf
  CompilerIf #PB_Compiler_Processor <> #PB_Processor_JavaScript
    Repeat; Always process all the events to flush the queue at every frame
      Event = WindowEvent()
      Select Event
        Case #PB_Event_CloseWindow
          ExitGame = #True
      EndSelect
    Until Event = 0 ; Quit the event loop only when no more events are available
  CompilerEndIf
  ExamineKeyboard()
  UpdateKeyBoard()
  Draw()
  LastTimeInMs = ElapsedMilliseconds()
  FlipBuffers()
EndProcedure
If OpenWindow(0, 0, 0, GameWidth, GameHeight, "RogueLikeLike", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  If OpenWindowedScreen(WindowID(0), 0, 0, GameWidth, GameHeight, 0, 0, 0)
    LoadSprites()
    LoadSounds()
    InitSpells()
    CompilerIf #PB_Compiler_Processor <> #PB_Processor_JavaScript
      ShowTitle()
    CompilerEndIf   
    LastTimeInMs = ElapsedMilliseconds()
    CompilerIf #PB_Compiler_Processor <> #PB_Processor_JavaScript
      Repeat
        RenderFrame()
      Until ExitGame
      Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
      If Req = #PB_MessageRequester_Yes
        End
      EndIf
    CompilerEndIf
  EndIf
EndIf
; IDE Options = PureBasic 6.04 LTS (Windows - x64)
; CursorPosition = 223
; FirstLine = 486
; Folding = ---------------
; Markers = 108,1006
; Optimizer
; EnableThread
; EnableXP
; EnableUser
; UseIcon = RogueLiteLike.ico
; Executable = RoguelikeLike.exe
; CompileSourceDirectory
; WebAppName = RoguelikeLike
; HtmlFilename = index.html
; JavaScriptFilename = RoguelikeLike.js
; JavaScriptPath = spiderbasic
; ResourceDirectory = data\
; CopyJavaScriptLibrary
; iOSAppOrientation = 0
; AndroidAppOrientation = 0