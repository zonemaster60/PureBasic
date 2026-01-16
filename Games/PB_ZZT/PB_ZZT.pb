; PBZT - tiny ZZT-ish ASCII adventure + editor (multi-board worlds + OOP scripting)
; PureBasic 6.30 beta 5
;
; World format supports multiple boards + scripted objects.
; Existing single-board PBZT files still load as 1-board worlds.
;
; Controls (Game):
;   Arrows move, Shift+arrows run,
;   F5 quicksave (slot 1..5), F9 quickload (slot 1..5),
;   Ctrl+F5 next quicksave slot, Ctrl+F9 previous quicksave slot,
;   Shift+F5 save game..., Shift+F9 load game...,
;   R restart world, PgUp/PgDn change world file, F2 editor, Esc quit
;
; Controls (Editor):
;   Arrows move cursor, Tab cycle brush, Space/Enter paint, Del erase,
;   F3 edit object, F4 delete object, F5 save world, F9 load world,
;   F6/F7 prev/next board, F8 new board, F2 back to game
;
; OOP scripting (very small ZZT-style subset):
;   Objects have scripts with labels (":LABEL") and commands ("#COMMAND").
;   Supported commands:
;     #SAY text
;     #SCROLL text            ; message box
;     #GOTO label
;     #END
;     #WAIT n
;     #SETFUEL TORCH|LANTERN n
;     #IFFUEL TORCH|LANTERN n label
;     #GIVECKEY 1|2|3|4 n
;     #TAKECKEY 1|2|3|4 n
;     #IFCKEY 1|2|3|4 n label
;     #IFTOUCH label        ; player adjacent
;     #IFCONTACT label      ; player on same tile
;     #IFRAND pct label
;     #IFSCORE n label       ; Score >= n
;     #IFKEYS n label        ; Keys >= n
;     #IFHEALTH n label      ; Health >= n
;     #SETFLAG name
;     #CLEARFLAG name
;     #TOGGLEFLAG name
;     #IFFLAG name label
;     #IFNOTFLAG name label
;     #GIVEITEM name [count]
;     #TAKEITEM name [count]
;     #IFITEM name [count] label
;     #GIVE SCORE|KEYS|HEALTH n
;     #TAKE SCORE|KEYS|HEALTH n
;     #SET x y char
;     #SETCOLOR x y color
;     #CHAR char
;     #COLOR color
;     #SOLID 0|1
;     #BOARD n              ; switch to board n
;     #WALK N|S|E|W
;     #EXITN/#EXITS/#EXITW/#EXITE n  ; set edge exits for current board
;
; Touching (bumping) an object triggers its :TOUCH label (if present).

EnableExplicit

; Record the directory of the main source file for includes to use.
Global MainSourceDir.s
MainSourceDir = GetPathPart(#PB_Compiler_File)

#APP_NAME = "PB_ZZT"
#EMAIL_NAME = "zonemaster60@gmail.com"

#MAP_W = 80
#MAP_H = 25
#UI_ROWS = 5

#TORCH_MAX_STEPS = 75
#LANTERN_MAX_STEPS = 150

#HEALTH_PICKUP_CHAR = 'h'
#ENEMY_DROP_HEALTH_PCT = 20

#DARK_NO_LIGHT_RADIUS = 2
#TORCH_RADIUS = 4
#LANTERN_RADIUS = 8

#WIN_FLAGS = #PB_Window_SystemMenu | #PB_Window_TitleBar

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

Enumeration
  #Gad_BoardName
  #Gad_BoardStartX
  #Gad_BoardStartY
  #Gad_BoardDark
  #Gad_BoardExitN
  #Gad_BoardExitS
  #Gad_BoardExitW
  #Gad_BoardExitE
  #Gad_BoardMusic
  #Gad_BoardOk
  #Gad_BoardCancel
EndEnumeration

Enumeration 100
  #Win_Object
  #Win_World
  #Win_Board
  #Win_Help
  #Win_Passage
  #Win_Sound
EndEnumeration

Enumeration 200
  #Gad_ObjName
  #Gad_ObjChar
  #Gad_ObjColor
  #Gad_ObjSolid
  #Gad_ObjScript
  #Gad_ObjOk
  #Gad_ObjCancel
EndEnumeration

Enumeration 300
  #Gad_WorldName
  #Gad_WorldStartBoard
  #Gad_WorldBangOneShot
  #Gad_WorldRespawnAtWorldStart
  #Gad_WorldDeathLoseScore
  #Gad_WorldDeathLoseKeys
  #Gad_WorldDeathRespawnDelayMS
  #Gad_WorldDeathFadeMS
  #Gad_WorldOk
  #Gad_WorldCancel
EndEnumeration

Enumeration 350
  #Gad_SoundMasterVol
  #Gad_SoundMasterVolVal
  #Gad_SoundMusicVol
  #Gad_SoundMusicVolVal
  #Gad_SoundPitch
  #Gad_SoundPitchVal
  #Gad_SoundNoise
  #Gad_SoundNoiseVal
  #Gad_SoundVib
  #Gad_SoundVibVal
  #Gad_SoundPreview
  #Gad_SoundPreviewStep
  #Gad_SoundPreviewCoin
  #Gad_SoundPreviewDoor
  #Gad_SoundPreviewHurt
  #Gad_SoundReset
  #Gad_SoundClose
EndEnumeration

Enumeration 500
  #Gad_HelpText
  #Gad_HelpClose
EndEnumeration

Enumeration 600
  #Gad_PassageDestBoard
  #Gad_PassageDestX
  #Gad_PassageDestY
  #Gad_PassageUseBoardStart
  #Gad_PassageClear
  #Gad_PassageOk
  #Gad_PassageCancel
EndEnumeration

Structure TBoard
  Name.s
  ExitN.i
  ExitS.i
  ExitW.i
  ExitE.i
  StartX.i
  StartY.i
  Dark.b
  Music.s
  Map.a[#MAP_W * #MAP_H]
  Color.a[#MAP_W * #MAP_H]
EndStructure

Structure TWorld
  FilePath.s
  Name.s
  StartBoard.i
  CurrentBoard.i
  BangOneShot.b

  RespawnAtWorldStart.b   ; 1=world start board, 0=current board
  DeathLoseScore.i        ; score to lose on death (0=none)
  DeathLoseKeys.i         ; keys to lose on death (0=none)
  DeathRespawnDelayMS.i   ; delay before respawn (ms)
  DeathFadeMS.i           ; fade duration (ms)
EndStructure

Structure TObject
  Id.i
  Alive.b
  Board.i
  X.i
  Y.i
  Char.a
  Color.a
  Solid.b
  Name.s
  Script.s
  IP.i        ; next line index
  Wait.i
EndStructure

Structure TPassage
  Board.i
  X.i
  Y.i
  DestBoard.i
  DestX.i
  DestY.i
  UseBoardStart.b
EndStructure

Global World.TWorld
Global Dim Boards.TBoard(0)
Global BoardCount.i

Global NewList Objects.TObject()
Global NextObjectId.i = 1

Global NewList Passages.TPassage()

Global Dim Palette.a(255)
Global Dim Solid.b(255)

Global PlayerX.i, PlayerY.i
Global CursorX.i, CursorY.i
Global BrushList.s, BrushIndex.i
Global BrushChar.a
Global BrushColor.i = 7

Global Score.i, Keys.i, Health.i

; Simple lighting pickups (play mode only)
Global TorchStepsLeft.i
Global LanternStepsLeft.i

; Colored keys: digit '1'..'4' -> count
Global NewMap ColorKeys.i()

Global DeathPending.b
Global DeathAtMS.i
Global DeathFadeUntilMS.i

; Script flags (for quests/puzzles): name -> 0/1
Global NewMap ScriptFlags.b()

; Script inventory items: name -> count
Global NewMap ScriptItems.i()

Global TileW.i, TileH.i
Global WinW.i, WinH.i
Global FontId.i

Global EditMode.b
Global WorldIndex.i
Global NewLineStatus.s
Global StatusExpireMS.i
Global LevelsDir.s
Global DebugOverlay.b
Global DebugWindowSizing.b

; App-level preferences (INI)
Global PrefPath.s
Global PrefLastWorldPath.s
Global PrefLevelsDir.s
Global PrefWinX.i
Global PrefWinY.i
Global PrefWinW.i
Global PrefWinH.i
Global PrefSaveDir.s
Global PrefQuickSaveSlot.i

; Startup self-test reporting (shown in debug overlay)
Global SelfTestSummary.s
Global SelfTestDetails.s


Global Dim ObjOverlayChar.a(#MAP_W * #MAP_H - 1)
Global Dim ObjOverlayColor.a(#MAP_W * #MAP_H - 1)
Global Dim ObjOverlaySolid.b(#MAP_W * #MAP_H - 1)
Global Dim ObjOverlayId.i(#MAP_W * #MAP_H - 1)

Global Dim ColorRGB.l(255)

Global Dim keyLatch.b(4095)
Global Dim keyRepeatNext.i(4095)

; Exit procedure
Procedure.b ConfirmExit()
  Protected req.i
  req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  ProcedureReturn Bool(req = #PB_MessageRequester_Yes)
EndProcedure

;------------------------------------------------------------------------------
; Utility helpers (procedures in includes/util.pbi)
;------------------------------------------------------------------------------
XIncludeFile "includes/util.pbi"

;------------------------------------------------------------------------------
; Colored key helpers (procedures in includes/color_keys.pbi)
;------------------------------------------------------------------------------
XIncludeFile "includes/color_keys.pbi"

;------------------------------------------------------------------------------
; SetStatus
; Purpose: Set the bottom status line and timeout.
; Params:
;   Text.s
;   DurationMS.i = 2000
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure SetStatus(Text.s, DurationMS.i = 2000)
  NewLineStatus = Text
  StatusExpireMS = ElapsedMilliseconds() + DurationMS
EndProcedure

;------------------------------------------------------------------------------
; FitTextToCols
; Purpose: Fit a string to a fixed column width.
; Params:
;   Text.s
;   MaxCols.i
; Returns: String
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.s FitTextToCols(Text.s, MaxCols.i)
  Protected s.s = Text

  If MaxCols <= 0
    ProcedureReturn ""
  EndIf

  If Len(s) <= MaxCols
    ProcedureReturn s
  EndIf

  If MaxCols <= 3
    ProcedureReturn Left(s, MaxCols)
  EndIf

  ProcedureReturn Left(s, MaxCols - 3) + "..."
EndProcedure

;------------------------------------------------------------------------------
; WrapTextToCols
; Purpose: Word-wrap a string to a fixed column width.
; Params:
;   Text.s
;   MaxCols.i
; Returns: String with #LF$ breaks
; Notes: Prefers breaking on spaces when possible.
;------------------------------------------------------------------------------

Procedure.s WrapTextToCols(Text.s, MaxCols.i)
  Protected s.s = ReplaceString(Text, #CRLF$, #LF$)
  s = ReplaceString(s, #CR$, #LF$)

  If MaxCols <= 0
    ProcedureReturn ""
  EndIf

  Protected out.s
  Protected curLine.s
  Protected i.i, ch.s
  Protected word.s
  Protected flushLine.b

  For i = 1 To Len(s)
    ch = Mid(s, i, 1)

    If ch = #LF$
      If out <> "" : out + #LF$ : EndIf
      out + curLine
      curLine = ""
      word = ""
      Continue
    EndIf

    If ch = " "
      ; finalize word + one space
      If word <> ""
        If curLine = ""
          curLine = word
        ElseIf Len(curLine) + 1 + Len(word) <= MaxCols
          curLine + " " + word
        Else
          If out <> "" : out + #LF$ : EndIf
          out + curLine
          curLine = word
        EndIf
        word = ""
      EndIf
      Continue
    EndIf

    word + ch

    ; Hard-break extremely long words.
    While Len(word) > MaxCols
      If curLine <> ""
        If out <> "" : out + #LF$ : EndIf
        out + curLine
        curLine = ""
      EndIf

      If out <> "" : out + #LF$ : EndIf
      out + Left(word, MaxCols)
      word = Mid(word, MaxCols + 1)
    Wend
  Next

  ; flush remaining word
  If word <> ""
    If curLine = ""
      curLine = word
    ElseIf Len(curLine) + 1 + Len(word) <= MaxCols
      curLine + " " + word
    Else
      If out <> "" : out + #LF$ : EndIf
      out + curLine
      curLine = word
    EndIf
  EndIf

  ; flush last line
  If curLine <> "" Or out = ""
    If out <> "" : out + #LF$ : EndIf
    out + curLine
  EndIf

  ProcedureReturn out
EndProcedure

;------------------------------------------------------------------------------
; FormatScriptItems
; Purpose: Procedure: Format Script Items.
; Params:
;   MaxLen.i = 120
; Returns: String
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.s FormatScriptItems(MaxLen.i = 120)
  Protected s.s
  Protected part.s
  Protected first.b = #True

  If MapSize(ScriptItems()) <= 0
    ProcedureReturn ""
  EndIf

  s = "Items:"
  ForEach ScriptItems()
    If ScriptItems() > 0
      If first
        part = MapKey(ScriptItems()) + "=" + Str(ScriptItems())
        first = #False
      Else
        part = "," + MapKey(ScriptItems()) + "=" + Str(ScriptItems())
      EndIf

      If Len(s) + Len(part) > MaxLen
        s + ",..."
        Break
      EndIf

      s + part
    EndIf
  Next

  If first
    ProcedureReturn ""
  EndIf

  ProcedureReturn s
EndProcedure

;------------------------------------------------------------------------------
; VGAColor
; Purpose: Procedure: V G A Color.
; Params:
;   Index.i
; Returns: Integer
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i VGAColor(Index.i)
  Index = Clamp(Index, 0, 255)
  ProcedureReturn ColorRGB(Index)
EndProcedure


;------------------------------------------------------------------------------
; HasScriptItem
; Purpose: Procedure: Has Script Item.
; Params:
;   ItemName.s
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b HasScriptItem(ItemName.s)
  ItemName = UCase(Trim(ItemName))
  If ItemName = "" : ProcedureReturn #False : EndIf
  If FindMapElement(ScriptItems(), ItemName)
    ProcedureReturn Bool(ScriptItems() > 0)
  EndIf
  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; InitVGAPalette
; Purpose: Initialize RGB values for the 16-color VGA palette.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure InitVGAPalette()
  ; 256-color indexed palette.
  ; Keep entries 0..15 as the classic DOS/VGA colors for compatibility.
  ColorRGB(0)  = RGB(0, 0, 0)
  ColorRGB(1)  = RGB(0, 0, 170)
  ColorRGB(2)  = RGB(0, 170, 0)
  ColorRGB(3)  = RGB(0, 170, 170)
  ColorRGB(4)  = RGB(170, 0, 0)
  ColorRGB(5)  = RGB(170, 0, 170)
  ColorRGB(6)  = RGB(170, 85, 0)
  ColorRGB(7)  = RGB(170, 170, 170)
  ColorRGB(8)  = RGB(85, 85, 85)
  ColorRGB(9)  = RGB(85, 85, 255)
  ColorRGB(10) = RGB(85, 255, 85)
  ColorRGB(11) = RGB(85, 255, 255)
  ColorRGB(12) = RGB(255, 85, 85)
  ColorRGB(13) = RGB(255, 85, 255)
  ColorRGB(14) = RGB(255, 255, 85)
  ColorRGB(15) = RGB(255, 255, 255)

  ; Fill the remaining entries with a deterministic RGB cube + grayscale ramp.
  Protected i.i
  For i = 16 To 255
    Protected r.i, g.i, b.i

    ; Use 216-color 6x6x6 cube (steps of 51), then a grayscale tail.
    Protected k.i = i - 16
    If k < 216
      r = (k / 36) * 51
      g = Mod((k / 6), 6) * 51
      b = Mod(k, 6) * 51
    Else
      Protected gray.i = Clamp((k - 216) * 255 / 39, 0, 255)
      r = gray : g = gray : b = gray
    EndIf

    ColorRGB(i) = RGB(r, g, b)
  Next
EndProcedure

;------------------------------------------------------------------------------
; DoorColorToKeyChar
; Purpose: Procedure: Door Color To Key Char.
; Params:
;   DoorCh.a
; Returns: String
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.s DoorColorToKeyChar(DoorCh.a)
  ; Doors A-C + F correspond to keys 1-4. (D is reserved for the normal key door.)
  Select DoorCh
    Case Asc("A") : ProcedureReturn "1"
    Case Asc("B") : ProcedureReturn "2"
    Case Asc("C") : ProcedureReturn "3"
    Case Asc("F") : ProcedureReturn "4"
  EndSelect
  ProcedureReturn ""
EndProcedure

;------------------------------------------------------------------------------
; KeyTileToCountIndex
; Purpose: Procedure: Key Tile To Count Index.
; Params:
;   KeyCh.a
; Returns: Integer
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i KeyTileToCountIndex(KeyCh.a)
  ; Key tiles are '1'..'4'. Returns 1..4, or 0 if not a colored key.
  If KeyCh >= Asc("1") And KeyCh <= Asc("4")
    ProcedureReturn KeyCh - Asc("0")
  EndIf
  ProcedureReturn 0
EndProcedure

;------------------------------------------------------------------------------
; Sound / SFX system (procedures in includes/sound.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/sound.pbi"

;------------------------------------------------------------------------------
; KeyHit
; Purpose: Procedure: Key Hit.
; Params:
;   KeyCode.i
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b KeyHit(KeyCode.i)
  Protected maxKey.i = ArraySize(keyLatch())

  If KeyCode < 0 Or KeyCode > maxKey
    ProcedureReturn Bool(KeyboardPushed(KeyCode) <> 0)
  EndIf

  If KeyboardPushed(KeyCode)
    If keyLatch(KeyCode) = 0
      keyLatch(KeyCode) = 1
      ProcedureReturn #True
    EndIf
  Else
    keyLatch(KeyCode) = 0
  EndIf

  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; KeyRepeat
; Purpose: Procedure: Key Repeat.
; Params:
;   KeyCode.i
;   InitialDelayMS.i = 250
;   RepeatMS.i = 85
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b KeyRepeat(KeyCode.i, InitialDelayMS.i = 250, RepeatMS.i = 85)
  Protected now.i = ElapsedMilliseconds()
  Protected maxKey.i = ArraySize(keyRepeatNext())
 
  If KeyCode < 0 Or KeyCode > maxKey
    ProcedureReturn #False
  EndIf
 
  If KeyboardPushed(KeyCode) = 0
    keyRepeatNext(KeyCode) = 0
    ProcedureReturn #False
  EndIf
 
  ; First press: immediate action, then schedule next repeat
  If keyRepeatNext(KeyCode) = 0
    keyRepeatNext(KeyCode) = now + InitialDelayMS
    ProcedureReturn #True
  EndIf
 
  If now >= keyRepeatNext(KeyCode)
    keyRepeatNext(KeyCode) = now + RepeatMS
    ProcedureReturn #True
  EndIf
 
  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; ResetKeyLatches
; Purpose: Procedure: Reset Key Latches.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure ResetKeyLatches()
  Protected i.i
  For i = 0 To ArraySize(keyLatch())
    keyLatch(i) = 0
  Next

  For i = 0 To ArraySize(keyRepeatNext())
    keyRepeatNext(i) = 0
  Next
EndProcedure

;------------------------------------------------------------------------------
; RefocusMainWindow
; Purpose: Procedure: Refocus Main Window.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure RefocusMainWindow()
  ; After modal dialogs, ensure the main window regains focus and
  ; key latch doesn't think F1 is still held.
  DisableWindow(0, 0)
  ResetKeyLatches()
  ExamineKeyboard()
EndProcedure

;------------------------------------------------------------------------------
; OpenScrollDialog
; Purpose: Show a ZZT-ish scroll message box.
; Params:
;   Text.s
;   Title.s = ""
; Returns: None
; Side effects: Modal dialog; resets key latches.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure OpenScrollDialog(Text.s, Title.s = "")
  Protected ev.i, gid.i
  Protected win.i
  Protected wTitle.s
  Protected gText.i, gClose.i

  wTitle = Title
  If wTitle = "" : wTitle = #APP_NAME + " Message" : EndIf
  If Text = "" : Text = "(blank)" : EndIf

  DisableWindow(0, 1)
  ResetKeyLatches()

  ; Use #PB_Any so we don't collide with other dialogs.
  win = OpenWindow(#PB_Any, 0, 0, 520, 280, wTitle, #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_TitleBar, WindowID(0))
  If win = 0
    DisableWindow(0, 0)
    MessageRequester(#APP_NAME, "Failed to open message window.")
    ProcedureReturn
  EndIf
  SetActiveWindow(win)

  gText = EditorGadget(#PB_Any, 10, 10, 500, 220)
  If gText
    SetGadgetText(gText, Text)
    SetGadgetAttribute(gText, #PB_Editor_ReadOnly, 1)
  EndIf

  gClose = ButtonGadget(#PB_Any, 420, 240, 90, 30, "Close")

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_CloseWindow
        Break

      Case #PB_Event_Gadget
        gid = EventGadget()
        If gid = gClose
          Break
        EndIf
    EndSelect
  ForEver

  CloseWindow(win)
  RefocusMainWindow()
EndProcedure

;------------------------------------------------------------------------------
; Preferences (INI) (procedures in includes/prefs.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/prefs.pbi"

;------------------------------------------------------------------------------
; ResetRules
; Purpose: Procedure: Reset Rules.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

  Procedure ResetRules()
  Protected i.i
 
  ClearMap(ScriptFlags())
  ClearMap(ScriptItems())
  ClearMap(ColorKeys())
 
  TorchStepsLeft = 0
  LanternStepsLeft = 0
 
  DeathPending = #False
  DeathAtMS = 0
  DeathFadeUntilMS = 0
 
  World\RespawnAtWorldStart = 1
  World\DeathLoseScore = 0
  World\DeathLoseKeys = 0
  World\DeathRespawnDelayMS = 1200
  World\DeathFadeMS = 700
 
  For i = 0 To 255
    Palette(i) = 7
    Solid(i) = 0
  Next
 
  Palette(Asc(" ")) = 7
  Palette(Asc(".")) = 7
  Palette(Asc("#")) = 8
  Palette(Asc("@")) = 15
  Palette(Asc("$")) = 14
  Palette(Asc("+")) = 10
  Palette(Asc("1")) = 12
  Palette(Asc("2")) = 10
  Palette(Asc("3")) = 9
  Palette(Asc("4")) = 14
  Palette(Asc("E")) = 12
  Palette(Asc("D")) = 11
  Palette(Asc("t")) = 14
  Palette(Asc("T")) = 14
  Palette(Asc("A")) = 12
  Palette(Asc("B")) = 10
  Palette(Asc("C")) = 9
  Palette(Asc("F")) = 14
  Palette(Asc("d")) = 11
  Palette(Asc("L")) = 14
  Palette(Asc("o")) = 7
  Palette(Asc("~")) = 9
  Palette(Asc("^")) = 13
  Palette(Asc("*")) = 12
  Palette(Asc("w")) = 9
  Palette(Asc("=")) = 6
  Palette(Asc(Chr(#HEALTH_PICKUP_CHAR))) = 12
 
  Solid(Asc("#")) = 1
  Solid(Asc("D")) = 1
  Solid(Asc("A")) = 1
  Solid(Asc("B")) = 1
  Solid(Asc("C")) = 1
  Solid(Asc("F")) = 1
  Solid(Asc("d")) = 1
  Solid(Asc("$")) = 1
  Solid(Asc("t")) = 0
  Solid(Asc("T")) = 0
  Solid(Asc("o")) = 0
  Solid(Asc("L")) = 0
EndProcedure

;------------------------------------------------------------------------------
; CurBoard
; Purpose: Procedure: Cur Board.
; Params: None
; Returns: Integer
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i CurBoard()
  ProcedureReturn World\CurrentBoard
EndProcedure

;------------------------------------------------------------------------------
; EnsureWorldBoards
; Purpose: Procedure: Ensure World Boards.
; Params:
;   DesiredCount.i
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure EnsureWorldBoards(DesiredCount.i)
  If DesiredCount < 1 : DesiredCount = 1 : EndIf

  If ArraySize(Boards()) + 1 <> DesiredCount
    ReDim Boards(DesiredCount - 1)
  EndIf

  BoardCount = DesiredCount

  World\StartBoard = Clamp(World\StartBoard, 0, BoardCount - 1)
  World\CurrentBoard = Clamp(World\CurrentBoard, 0, BoardCount - 1)
EndProcedure

;------------------------------------------------------------------------------
; InitBlankBoard
; Purpose: Procedure: Init Blank Board.
; Params:
;   BoardIdx.i
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure InitBlankBoard(BoardIdx.i)
  Protected x.i, y.i, idx.i

  If BoardIdx < 0 Or BoardIdx >= BoardCount : ProcedureReturn : EndIf

  Boards(BoardIdx)\Name = "Board " + Str(BoardIdx)
  Boards(BoardIdx)\Music = ""
  Boards(BoardIdx)\ExitN = -1
  Boards(BoardIdx)\ExitS = -1
  Boards(BoardIdx)\ExitW = -1
  Boards(BoardIdx)\ExitE = -1
  Boards(BoardIdx)\StartX = 1
  Boards(BoardIdx)\StartY = 1
  Boards(BoardIdx)\Dark = 0

  For y = 0 To #MAP_H - 1
    For x = 0 To #MAP_W - 1
      idx = x + y * #MAP_W
      Boards(BoardIdx)\Map[idx] = Asc(".")
      Boards(BoardIdx)\Color[idx] = Palette(Asc("."))
    Next
  Next

  ; border walls
  For x = 0 To #MAP_W - 1
    Boards(BoardIdx)\Map[x] = Asc("#")
    Boards(BoardIdx)\Color[x] = Palette(Asc("#"))

    Boards(BoardIdx)\Map[x + (#MAP_H - 1) * #MAP_W] = Asc("#")
    Boards(BoardIdx)\Color[x + (#MAP_H - 1) * #MAP_W] = Palette(Asc("#"))
  Next

  For y = 0 To #MAP_H - 1
    Boards(BoardIdx)\Map[0 + y * #MAP_W] = Asc("#")
    Boards(BoardIdx)\Color[0 + y * #MAP_W] = Palette(Asc("#"))

    Boards(BoardIdx)\Map[(#MAP_W - 1) + y * #MAP_W] = Asc("#")
    Boards(BoardIdx)\Color[(#MAP_W - 1) + y * #MAP_W] = Palette(Asc("#"))
  Next
EndProcedure

;------------------------------------------------------------------------------
; SanitizeBoard
; Purpose: Procedure: Sanitize Board.
; Params:
;   BoardIdx.i
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure SanitizeBoard(BoardIdx.i)
  Protected x.i, y.i, idx.i
  Protected b.i = BoardIdx
  
  If b < 0 Or b >= BoardCount : ProcedureReturn : EndIf
  
  Boards(b)\StartX = Clamp(Boards(b)\StartX, 0, #MAP_W - 1)
  Boards(b)\StartY = Clamp(Boards(b)\StartY, 0, #MAP_H - 1)
  
  For y = 0 To #MAP_H - 1
    For x = 0 To #MAP_W - 1
      idx = x + y * #MAP_W
      If Boards(b)\Color[idx] = 0 And Boards(b)\Map[idx] = 0
        Boards(b)\Map[idx] = Asc(" ")
        Boards(b)\Color[idx] = Palette(Asc(" "))
      EndIf
    Next
  Next
  
  ; enforce border walls (keeps edge exits usable via bump-to-exit)
  For x = 0 To #MAP_W - 1
    Boards(b)\Map[x] = Asc("#")
    Boards(b)\Color[x] = Palette(Asc("#"))
    
    Boards(b)\Map[x + (#MAP_H - 1) * #MAP_W] = Asc("#")
    Boards(b)\Color[x + (#MAP_H - 1) * #MAP_W] = Palette(Asc("#"))
  Next
  
  For y = 0 To #MAP_H - 1
    Boards(b)\Map[0 + y * #MAP_W] = Asc("#")
    Boards(b)\Color[0 + y * #MAP_W] = Palette(Asc("#"))
    
    Boards(b)\Map[(#MAP_W - 1) + y * #MAP_W] = Asc("#")
    Boards(b)\Color[(#MAP_W - 1) + y * #MAP_W] = Palette(Asc("#"))
  Next
  
  If Solid(Boards(b)\Map[Boards(b)\StartX + Boards(b)\StartY * #MAP_W])
    Boards(b)\Map[Boards(b)\StartX + Boards(b)\StartY * #MAP_W] = Asc(".")
    Boards(b)\Color[Boards(b)\StartX + Boards(b)\StartY * #MAP_W] = Palette(Asc("."))
  EndIf
EndProcedure

Declare SwitchBoard(NewBoard.i, EntrySide.s = "")

;------------------------------------------------------------------------------
; ResetPlayerToBoardStart
; Purpose: Procedure: Reset Player To Board Start.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure ResetPlayerToBoardStart()
  Protected b.i = CurBoard()
  If b < 0 Or b >= BoardCount : ProcedureReturn : EndIf

  PlayerX = Boards(b)\StartX
  PlayerY = Boards(b)\StartY
EndProcedure

;------------------------------------------------------------------------------
; KillPlayer
; Purpose: Procedure: Kill Player.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure KillPlayer()
  If DeathPending
    ProcedureReturn
  EndIf

  ; Apply death penalties.
  If World\DeathLoseScore > 0
    Score = Clamp(Score - World\DeathLoseScore, 0, 999999999)
  EndIf

  If World\DeathLoseKeys > 0
    Keys = Clamp(Keys - World\DeathLoseKeys, 0, 9999)
  EndIf

  ; For now: death penalty applies only to the normal key counter.
  ; Colored keys can be taken via scripts (#TAKEITEM) if desired.

  Health = 0
  DeathPending = #True
  DeathAtMS = ElapsedMilliseconds()
  DeathFadeUntilMS = DeathAtMS + Clamp(World\DeathFadeMS, 0, 60000)
  SetStatus("You died! Respawning...", 2500)
  PlaySfx(#Sfx_Hurt)
EndProcedure

;------------------------------------------------------------------------------
; RespawnPlayer
; Purpose: Procedure: Respawn Player.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure RespawnPlayer()
  DeathPending = #False
  DeathAtMS = 0
  DeathFadeUntilMS = 0

  If World\RespawnAtWorldStart
    SwitchBoard(World\StartBoard, "")
  Else
    SwitchBoard(CurBoard(), "")
  EndIf

  Health = 5
  SetStatus("Respawned!", 2500)
EndProcedure

;------------------------------------------------------------------------------
; SwitchBoard
; Purpose: Procedure: Switch Board.
; Params:
;   NewBoard.i
;   EntrySide.s = ""
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure SwitchBoard(NewBoard.i, EntrySide.s = "")
  If NewBoard < 0 Or NewBoard >= BoardCount
    ProcedureReturn
  EndIf

  World\CurrentBoard = NewBoard

  Select UCase(EntrySide)
    Case "N" : PlayerY = #MAP_H - 2
    Case "S" : PlayerY = 1
    Case "W" : PlayerX = #MAP_W - 2
    Case "E" : PlayerX = 1
    Default
      ResetPlayerToBoardStart()
      PlayerX = Boards(NewBoard)\StartX
      PlayerY = Boards(NewBoard)\StartY
  EndSelect

  PlayerX = Clamp(PlayerX, 0, #MAP_W - 1)
  PlayerY = Clamp(PlayerY, 0, #MAP_H - 1)

  PlaySfx(#Sfx_Board)
  SetStatus("Board: " + Boards(NewBoard)\Name)

  If Boards(NewBoard)\Music <> ""
    StartBoardMusic("WORLD:" + World\FilePath + ":BOARD:" + Str(NewBoard), Boards(NewBoard)\Music)
  Else
    StopBoardMusic()
  EndIf
EndProcedure

;------------------------------------------------------------------------------
; SetCell
; Purpose: Procedure: Set Cell.
; Params:
;   x.i
;   y.i
;   ch.a
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure SetCell(x.i, y.i, ch.a)
  Protected idx.i
  Protected b.i = CurBoard()
  If x < 0 Or y < 0 Or x >= #MAP_W Or y >= #MAP_H : ProcedureReturn : EndIf
  If b < 0 Or b >= BoardCount : ProcedureReturn : EndIf

  idx = x + y * #MAP_W
  Boards(b)\Map[idx] = ch
  Boards(b)\Color[idx] = Palette(ch)
EndProcedure

;------------------------------------------------------------------------------
; SetCellColor
; Purpose: Procedure: Set Cell Color.
; Params:
;   x.i
;   y.i
;   ColorIndex.i
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure SetCellColor(x.i, y.i, ColorIndex.i)
  Protected idx.i
  Protected b.i = CurBoard()
  If x < 0 Or y < 0 Or x >= #MAP_W Or y >= #MAP_H : ProcedureReturn : EndIf
  If b < 0 Or b >= BoardCount : ProcedureReturn : EndIf

  idx = x + y * #MAP_W
  Boards(b)\Color[idx] = Clamp(ColorIndex, 0, 255)

EndProcedure

;------------------------------------------------------------------------------
; GetCell
; Purpose: Procedure: Get Cell.
; Params:
;   x.i
;   y.i
; Returns: Byte
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.a GetCell(x.i, y.i)
  Protected b.i = CurBoard()
  If b < 0 Or b >= BoardCount : ProcedureReturn Asc("#") : EndIf
  If x < 0 Or y < 0 Or x >= #MAP_W Or y >= #MAP_H : ProcedureReturn Asc("#") : EndIf
  ProcedureReturn Boards(b)\Map[x + y * #MAP_W]
EndProcedure

;------------------------------------------------------------------------------
; GetBangMarkerText
; Purpose: Procedure: Get Bang Marker Text.
; Params:
;   x.i
;   y.i
; Returns: String
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.s GetBangMarkerText(x.i, y.i)
  ; Reads a short hint message stored on the map immediately after '!'.
  ; Example: "!Forest ->...." will display "Forest ->".
  Protected b.i = CurBoard()
  Protected s.s
  Protected cx.i
  Protected ch.a

  If b < 0 Or b >= BoardCount : ProcedureReturn "" : EndIf
  If x < 0 Or y < 0 Or x >= #MAP_W Or y >= #MAP_H : ProcedureReturn "" : EndIf

  ; If the tile isn't a marker, nothing to do.
  If Boards(b)\Map[x + y * #MAP_W] <> Asc("!")
    ProcedureReturn ""
  EndIf

  s = ""
  cx = x + 1
  While cx < #MAP_W
    ch = Boards(b)\Map[cx + y * #MAP_W]

    ; Stop at normal floor/filler or at walls.
    If ch = Asc("#") Or ch = Asc(".")
      Break
    EndIf

    s + Chr(ch)
    cx + 1
  Wend

  ProcedureReturn Trim(s)
EndProcedure

;------------------------------------------------------------------------------
; SelectPassageAt
; Purpose: Procedure: Select Passage At.
; Params:
;   BoardIdx.i
;   x.i
;   y.i
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b SelectPassageAt(BoardIdx.i, x.i, y.i)
  ForEach Passages()
    If Passages()\Board = BoardIdx And Passages()\X = x And Passages()\Y = y
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; UpsertPassage
; Purpose: Procedure: Upsert Passage.
; Params:
;   BoardIdx.i
;   x.i
;   y.i
;   DestBoard.i
;   DestX.i
;   DestY.i
;   UseBoardStart.b
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure UpsertPassage(BoardIdx.i, x.i, y.i, DestBoard.i, DestX.i, DestY.i, UseBoardStart.b)
  If SelectPassageAt(BoardIdx, x, y)
    Passages()\DestBoard = DestBoard
    Passages()\DestX = DestX
    Passages()\DestY = DestY
    Passages()\UseBoardStart = Bool(UseBoardStart <> 0)
    ProcedureReturn
  EndIf

  AddElement(Passages())
  Passages()\Board = BoardIdx
  Passages()\X = x
  Passages()\Y = y
  Passages()\DestBoard = DestBoard
  Passages()\DestX = DestX
  Passages()\DestY = DestY
  Passages()\UseBoardStart = Bool(UseBoardStart <> 0)
EndProcedure

;------------------------------------------------------------------------------
; RemovePassageAt
; Purpose: Procedure: Remove Passage At.
; Params:
;   BoardIdx.i
;   x.i
;   y.i
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b RemovePassageAt(BoardIdx.i, x.i, y.i)
  ForEach Passages()
    If Passages()\Board = BoardIdx And Passages()\X = x And Passages()\Y = y
      DeleteElement(Passages())
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; GetObjectIdAt
; Purpose: Procedure: Get Object Id At.
; Params:
;   BoardIdx.i
;   x.i
;   y.i
; Returns: Integer
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i GetObjectIdAt(BoardIdx.i, x.i, y.i)
  ForEach Objects()
    If Objects()\Alive And Objects()\Board = BoardIdx And Objects()\X = x And Objects()\Y = y
      ProcedureReturn Objects()\Id
    EndIf
  Next
  ProcedureReturn 0
EndProcedure

;------------------------------------------------------------------------------
; SelectObjectById
; Purpose: Procedure: Select Object By Id.
; Params:
;   Id.i
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b SelectObjectById(Id.i)
  ForEach Objects()
    If Objects()\Id = Id
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; AddObject
; Purpose: Procedure: Add Object.
; Params:
;   BoardIdx.i
;   x.i
;   y.i
; Returns: Integer
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i AddObject(BoardIdx.i, x.i, y.i)
  AddElement(Objects())
  Objects()\Id = NextObjectId : NextObjectId + 1
  Objects()\Alive = #True
  Objects()\Board = BoardIdx
  Objects()\X = x
  Objects()\Y = y
  Objects()\Char = Asc("O")
  Objects()\Color = 14
  Objects()\Solid = 1
  Objects()\Name = "Object" + Str(Objects()\Id)
  Objects()\Script = ":TOUCH" + #LF$ + "#SAY Hello from " + Objects()\Name + #LF$ + "#END" + #LF$
  Objects()\IP = 0
  Objects()\Wait = 0
  ProcedureReturn Objects()\Id
EndProcedure

Procedure SyncNextObjectIdFromObjects()
  Protected maxId.i = 0

  ForEach Objects()
    If Objects()\Id > maxId
      maxId = Objects()\Id
    EndIf
  Next

  NextObjectId = maxId + 1
  If NextObjectId < 1 : NextObjectId = 1 : EndIf
EndProcedure

;------------------------------------------------------------------------------
; RemoveObjectById
; Purpose: Procedure: Remove Object By Id.
; Params:
;   Id.i
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b RemoveObjectById(Id.i)
  ForEach Objects()
    If Objects()\Id = Id
      DeleteElement(Objects())
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; AddEnemy
; Purpose: Procedure: Add Enemy.
; Params:
;   BoardIdx.i
;   x.i
;   y.i
; Returns: Integer
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i AddEnemy(BoardIdx.i, x.i, y.i)
  Protected id.i
 
  id = AddObject(BoardIdx, x, y)
  If SelectObjectById(id)
    Objects()\Name = "Enemy" + Str(id)
    Objects()\Char = Asc("E")
    Objects()\Color = Palette(Asc("E"))
    Objects()\Solid = 1
    Objects()\Script = ""
    Objects()\IP = 0
    Objects()\Wait = 0
  EndIf
  ProcedureReturn id
EndProcedure

;------------------------------------------------------------------------------
; AddWater
; Purpose: Place a water object (pond/stream tile).
; Params:
;   BoardIdx.i
;   x.i
;   y.i
; Returns: Integer
; Notes: Water is a solid object; bumping into it triggers :TOUCH.
;------------------------------------------------------------------------------

Procedure.i AddWater(BoardIdx.i, x.i, y.i)
  Protected id.i

  id = AddObject(BoardIdx, x, y)
  If SelectObjectById(id)
    Objects()\Name = "Water" + Str(id)
    Objects()\Char = Asc("w")
    Objects()\Color = Palette(Asc("w"))
    Objects()\Solid = 1
    Objects()\Script = ":TOUCH" + #LF$ +
                     "#SAY Splash! (Water)" + #LF$ +
                     "#END" + #LF$
    Objects()\IP = 0
    Objects()\Wait = 0
  EndIf
  ProcedureReturn id
EndProcedure

;------------------------------------------------------------------------------
; AddBridge
; Purpose: Place a bridge you can walk on.
;------------------------------------------------------------------------------

Procedure.i AddBridge(BoardIdx.i, x.i, y.i)
  Protected id.i

  id = AddObject(BoardIdx, x, y)
  If SelectObjectById(id)
    Objects()\Name = "Bridge" + Str(id)
    Objects()\Char = Asc("=")
    Objects()\Color = Palette(Asc("="))
    Objects()\Solid = 0
    Objects()\Script = ""
    Objects()\IP = 0
    Objects()\Wait = 0
  EndIf
  ProcedureReturn id
EndProcedure

;------------------------------------------------------------------------------
; IsAlphaNumChar
; Purpose: Procedure: Is Alpha Num Char.
; Params:
;   ch.a
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b IsAlphaNumChar(ch.a)
  If (ch >= '0' And ch <= '9') Or (ch >= 'A' And ch <= 'Z') Or (ch >= 'a' And ch <= 'z')
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; ConvertEnemyTilesToObjects
; Purpose: Procedure: Convert Enemy Tiles To Objects.
; Params:
;   BoardIdx.i
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure ConvertEnemyTilesToObjects(BoardIdx.i)
  Protected idx.i, x.i, y.i
  Protected leftCh.a, rightCh.a, upCh.a, downCh.a
 
  If BoardIdx < 0 Or BoardIdx >= BoardCount : ProcedureReturn : EndIf
 
  For idx = 0 To #MAP_W * #MAP_H - 1
    If Boards(BoardIdx)\Map[idx] = Asc("E")
      x = idx % #MAP_W
      y = idx / #MAP_W
 
      ; Heuristic: don't convert the letter 'E' when it's part of map text.
      leftCh  = Boards(BoardIdx)\Map[Clamp(x - 1, 0, #MAP_W - 1) + y * #MAP_W]
      rightCh = Boards(BoardIdx)\Map[Clamp(x + 1, 0, #MAP_W - 1) + y * #MAP_W]
      upCh    = Boards(BoardIdx)\Map[x + Clamp(y - 1, 0, #MAP_H - 1) * #MAP_W]
      downCh  = Boards(BoardIdx)\Map[x + Clamp(y + 1, 0, #MAP_H - 1) * #MAP_W]
 
      If (IsAlphaNumChar(leftCh) And leftCh <> Asc("E")) Or (IsAlphaNumChar(rightCh) And rightCh <> Asc("E")) Or IsAlphaNumChar(upCh) Or IsAlphaNumChar(downCh)
        Continue
      EndIf
 
      If GetObjectIdAt(BoardIdx, x, y) = 0
        AddEnemy(BoardIdx, x, y)
      EndIf
      Boards(BoardIdx)\Map[idx] = Asc(".")
      Boards(BoardIdx)\Color[idx] = Palette(Asc("."))
    EndIf
  Next
EndProcedure

Procedure ConvertWaterTilesToObjects(BoardIdx.i)
  Protected idx.i, x.i, y.i
  Protected leftCh.a, rightCh.a, upCh.a, downCh.a
 
  If BoardIdx < 0 Or BoardIdx >= BoardCount : ProcedureReturn : EndIf
 
  For idx = 0 To #MAP_W * #MAP_H - 1
    If Boards(BoardIdx)\Map[idx] = Asc("w")
      x = idx % #MAP_W
      y = idx / #MAP_W
 
      ; Heuristic: don't convert the letter 'w' when it's part of map text.
      leftCh  = Boards(BoardIdx)\Map[Clamp(x - 1, 0, #MAP_W - 1) + y * #MAP_W]
      rightCh = Boards(BoardIdx)\Map[Clamp(x + 1, 0, #MAP_W - 1) + y * #MAP_W]
      upCh    = Boards(BoardIdx)\Map[x + Clamp(y - 1, 0, #MAP_H - 1) * #MAP_W]
      downCh  = Boards(BoardIdx)\Map[x + Clamp(y + 1, 0, #MAP_H - 1) * #MAP_W]
 
      If (IsAlphaNumChar(leftCh) And leftCh <> Asc("w")) Or (IsAlphaNumChar(rightCh) And rightCh <> Asc("w")) Or IsAlphaNumChar(upCh) Or IsAlphaNumChar(downCh)
        Continue
      EndIf
 
      If GetObjectIdAt(BoardIdx, x, y) = 0
        AddWater(BoardIdx, x, y)
      EndIf
      Boards(BoardIdx)\Map[idx] = Asc(".")
      Boards(BoardIdx)\Color[idx] = Palette(Asc("."))
    EndIf
  Next
EndProcedure

;------------------------------------------------------------------------------
; DeleteObjectAt
; Purpose: Procedure: Delete Object At.
; Params:
;   BoardIdx.i
;   x.i
;   y.i
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b DeleteObjectAt(BoardIdx.i, x.i, y.i)
  ForEach Objects()
    If Objects()\Alive And Objects()\Board = BoardIdx And Objects()\X = x And Objects()\Y = y
      DeleteElement(Objects())
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; RebuildObjectOverlay
; Purpose: Procedure: Rebuild Object Overlay.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure RebuildObjectOverlay()
  Protected i.i
  Protected b.i = CurBoard()
  Protected idx.i

  For i = 0 To #MAP_W * #MAP_H - 1
    ObjOverlayChar(i) = 0
    ObjOverlayColor(i) = 0
    ObjOverlaySolid(i) = 0
    ObjOverlayId(i) = 0
  Next

  ForEach Objects()
    If Objects()\Alive And Objects()\Board = b
      If Objects()\X >= 0 And Objects()\Y >= 0 And Objects()\X < #MAP_W And Objects()\Y < #MAP_H
        idx = Objects()\X + Objects()\Y * #MAP_W
        ObjOverlayChar(idx) = Objects()\Char
        ObjOverlayColor(idx) = Clamp(Objects()\Color, 0, 255)

        ObjOverlaySolid(idx) = Objects()\Solid
        ObjOverlayId(idx) = Objects()\Id
      EndIf
    EndIf
  Next
EndProcedure

;------------------------------------------------------------------------------
; Scripting engine (procedures in includes/scripting.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/scripting.pbi"

;------------------------------------------------------------------------------
; AttemptBoardEdgeExit
; Purpose: Procedure: Attempt Board Edge Exit.
; Params:
;   dx.i
;   dy.i
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b AttemptBoardEdgeExit(dx.i, dy.i)
  Protected b.i = CurBoard()
  Protected target.i = -1

  If b < 0 Or b >= BoardCount
    ProcedureReturn #False
  EndIf

  If dx < 0
    target = Boards(b)\ExitW
    If target >= 0
      SwitchBoard(target, "W")
      PlayerY = Clamp(PlayerY, 1, #MAP_H - 2)
      ProcedureReturn #True
    EndIf
  ElseIf dx > 0
    target = Boards(b)\ExitE
    If target >= 0
      SwitchBoard(target, "E")
      PlayerY = Clamp(PlayerY, 1, #MAP_H - 2)
      ProcedureReturn #True
    EndIf
  ElseIf dy < 0
    target = Boards(b)\ExitN
    If target >= 0
      SwitchBoard(target, "N")
      PlayerX = Clamp(PlayerX, 1, #MAP_W - 2)
      ProcedureReturn #True
    EndIf
  ElseIf dy > 0
    target = Boards(b)\ExitS
    If target >= 0
      SwitchBoard(target, "S")
      PlayerX = Clamp(PlayerX, 1, #MAP_W - 2)
      ProcedureReturn #True
    EndIf
  EndIf

  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; CellIsSolidForPlayer
; Purpose: Procedure: Cell Is Solid For Player.
; Params:
;   nx.i
;   ny.i
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b CellIsSolidForPlayer(nx.i, ny.i)
  Protected ch.a
  Protected b.i = CurBoard()
  Protected idx.i
  Protected objId.i

  If nx < 0 Or ny < 0 Or nx >= #MAP_W Or ny >= #MAP_H
    ProcedureReturn #True
  EndIf

  idx = nx + ny * #MAP_W
  If b >= 0 And b < BoardCount
    objId = ObjOverlayId(idx)
    If objId <> 0 And ObjOverlaySolid(idx)
      ; Treat enemies as bump-attack targets, not walls.
      If ObjOverlayChar(idx) <> Asc("E")
        ProcedureReturn #True
      EndIf
    EndIf
  EndIf

  ch = GetCell(nx, ny)

  If ch = Asc("D")
    If Keys > 0
      ProcedureReturn #False
    Else
      ProcedureReturn #True
    EndIf
  EndIf

  If (ch >= Asc("A") And ch <= Asc("C")) Or ch = Asc("F")
    Protected neededKey.s
    neededKey = DoorColorToKeyChar(ch)
    If neededKey <> "" And GetColorKeyCount(neededKey) > 0
      ProcedureReturn #False
    Else
      ProcedureReturn #True
    EndIf
  EndIf

  ProcedureReturn Bool(Solid(ch) <> 0)
EndProcedure

;------------------------------------------------------------------------------
; Movement/enemies (procedures in includes/movement.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/movement.pbi"

;------------------------------------------------------------------------------
; Rendering (procedures in includes/render.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/render.pbi"

;------------------------------------------------------------------------------
; Editor (procedures in includes/editor.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/editor.pbi"

;------------------------------------------------------------------------------
; NormalizeScriptText
; Purpose: Procedure: Normalize Script Text.
; Params:
;   Text.s
; Returns: String
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.s NormalizeScriptText(Text.s)
  Text = ReplaceString(Text, #CRLF$, #LF$)
  Text = ReplaceString(Text, #CR$, #LF$)
  If Text <> "" And Right(Text, 1) <> #LF$
    Text + #LF$
  EndIf
  ProcedureReturn Text
EndProcedure

Procedure.s NormalizeMusicText(Text.s)
  Text = ReplaceString(Text, #CRLF$, #LF$)
  Text = ReplaceString(Text, #CR$, #LF$)
  If Text <> "" And Right(Text, 1) <> #LF$
    Text + #LF$
  EndIf
  ProcedureReturn Text
EndProcedure

;------------------------------------------------------------------------------
; OpenPassageDialog
; Purpose: Procedure: Open Passage Dialog.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure OpenPassageDialog()
  Protected b.i = CurBoard()
  Protected ev.i, gid.i
  Protected ok.b
  Protected maxBoard.i
  Protected useStart.b

  If b < 0 Or b >= BoardCount
    ProcedureReturn
  EndIf

  Protected mapCh.a
  Protected objIdHere.i

  mapCh = Boards(b)\Map[CursorX + CursorY * #MAP_W]
  If mapCh <> Asc("P")
    objIdHere = GetObjectIdAt(b, CursorX, CursorY)
    If objIdHere <> 0 And SelectObjectById(objIdHere)
      If Objects()\Char = Asc("P")
        SetStatus("This is a 'P' object, not a P tile (use F4 or move it).")
      Else
        SetStatus("Cursor isn't on a P tile (object here: " + Chr(Objects()\Char) + ").")
      EndIf
    Else
      SetStatus("Cursor isn't on a P tile (map has '" + Chr(mapCh) + "').")
    EndIf
    ProcedureReturn
  EndIf

  maxBoard = BoardCount - 1
  If maxBoard < 0 : maxBoard = 0 : EndIf

  DisableWindow(0, 1)
  ResetKeyLatches()

  OpenWindow(#Win_Passage, 0, 0, 520, 230, "Passage Properties", #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_TitleBar, WindowID(0))

  TextGadget(#PB_Any, 10, 12, 120, 20, "Dest board")
  SpinGadget(#Gad_PassageDestBoard, 140, 10, 90, 24, 0, maxBoard, #PB_Spin_Numeric)

  TextGadget(#PB_Any, 10, 46, 120, 20, "Dest X")
  SpinGadget(#Gad_PassageDestX, 140, 44, 90, 24, 0, #MAP_W - 1, #PB_Spin_Numeric)

  TextGadget(#PB_Any, 10, 80, 120, 20, "Dest Y")
  SpinGadget(#Gad_PassageDestY, 140, 78, 90, 24, 0, #MAP_H - 1, #PB_Spin_Numeric)

  CheckBoxGadget(#Gad_PassageUseBoardStart, 250, 12, 250, 22, "Use destination board's StartX/StartY")

  ButtonGadget(#Gad_PassageClear, 250, 78, 250, 28, "Clear mapping (keep tile)")

  ButtonGadget(#Gad_PassageOk, 320, 170, 90, 30, "OK")
  ButtonGadget(#Gad_PassageCancel, 410, 170, 90, 30, "Cancel")

  ; preload from existing mapping, otherwise default to current board start
  If SelectPassageAt(b, CursorX, CursorY)
    SetGadgetState(#Gad_PassageDestBoard, Clamp(Passages()\DestBoard, 0, maxBoard))
    SetGadgetState(#Gad_PassageDestX, Clamp(Passages()\DestX, 0, #MAP_W - 1))
    SetGadgetState(#Gad_PassageDestY, Clamp(Passages()\DestY, 0, #MAP_H - 1))
    SetGadgetState(#Gad_PassageUseBoardStart, Bool(Passages()\UseBoardStart <> 0))
  Else
    SetGadgetState(#Gad_PassageDestBoard, Clamp(World\CurrentBoard, 0, maxBoard))
    SetGadgetState(#Gad_PassageDestX, Clamp(Boards(b)\StartX, 0, #MAP_W - 1))
    SetGadgetState(#Gad_PassageDestY, Clamp(Boards(b)\StartY, 0, #MAP_H - 1))
    SetGadgetState(#Gad_PassageUseBoardStart, 1)
  EndIf

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_CloseWindow
        ok = #False
        Break

      Case #PB_Event_Gadget
        gid = EventGadget()
        Select gid
          Case #Gad_PassageOk
            ok = #True
            Break

          Case #Gad_PassageCancel
            ok = #False
            Break

          Case #Gad_PassageClear
            RemovePassageAt(b, CursorX, CursorY)
            SetStatus("Cleared passage mapping.")
            ok = #False
            Break

          Case #Gad_PassageDestBoard
            ; Keep X/Y spinners legal when switching dest board.
            ; (Still clamped on apply as well.)
        EndSelect
    EndSelect
  ForEver

  If ok
    useStart = Bool(GetGadgetState(#Gad_PassageUseBoardStart) <> 0)
    UpsertPassage(b,
                  CursorX,
                  CursorY,
                  Clamp(GetGadgetState(#Gad_PassageDestBoard), 0, maxBoard),
                  Clamp(GetGadgetState(#Gad_PassageDestX), 0, #MAP_W - 1),
                  Clamp(GetGadgetState(#Gad_PassageDestY), 0, #MAP_H - 1),
                  useStart)

    SetStatus("Updated passage.")
  EndIf

  CloseWindow(#Win_Passage)
  RefocusMainWindow()
EndProcedure

;------------------------------------------------------------------------------
; OpenObjectDialog
; Purpose: Procedure: Open Object Dialog.
; Params:
;   ObjectId.i
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure OpenObjectDialog(ObjectId.i)
  Protected b.i = CurBoard()
  Protected ev.i, gid.i
  Protected ok.b
  Protected t.s

  If ObjectId = 0
    ObjectId = AddObject(b, CursorX, CursorY)
  EndIf

  If SelectObjectById(ObjectId) = 0
    ProcedureReturn
  EndIf

  DisableWindow(0, 1)
  ResetKeyLatches()

  OpenWindow(#Win_Object, 0, 0, 760, 560, "Object / OOP Script", #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_TitleBar, WindowID(0))

  TextGadget(#PB_Any, 10, 10, 60, 20, "Name")
  StringGadget(#Gad_ObjName, 70, 8, 300, 24, Objects()\Name)

  TextGadget(#PB_Any, 390, 10, 40, 20, "Char")
  StringGadget(#Gad_ObjChar, 430, 8, 40, 24, Chr(Objects()\Char))

  TextGadget(#PB_Any, 485, 10, 40, 20, "Color")
  SpinGadget(#Gad_ObjColor, 525, 8, 60, 24, 0, 255, #PB_Spin_Numeric)
  SetGadgetState(#Gad_ObjColor, Clamp(Objects()\Color, 0, 255))


  CheckBoxGadget(#Gad_ObjSolid, 610, 10, 120, 20, "Solid")
  SetGadgetState(#Gad_ObjSolid, Objects()\Solid)

  EditorGadget(#Gad_ObjScript, 10, 40, 740, 470)
  SetGadgetText(#Gad_ObjScript, Objects()\Script)

  ButtonGadget(#Gad_ObjOk, 560, 520, 90, 28, "OK")
  ButtonGadget(#Gad_ObjCancel, 660, 520, 90, 28, "Cancel")

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_CloseWindow
        ok = #False
        Break

      Case #PB_Event_Gadget
        gid = EventGadget()
        Select gid
          Case #Gad_ObjOk
            ok = #True
            Break
          Case #Gad_ObjCancel
            ok = #False
            Break
        EndSelect
    EndSelect
  ForEver

  If ok
    If SelectObjectById(ObjectId)
      Objects()\Name = GetGadgetText(#Gad_ObjName)

      t = GetGadgetText(#Gad_ObjChar)
      If t <> ""
        Objects()\Char = Asc(Left(t, 1))
      EndIf

      Objects()\Color = Clamp(GetGadgetState(#Gad_ObjColor), 0, 255)

      Objects()\Solid = Bool(GetGadgetState(#Gad_ObjSolid) <> 0)

      Objects()\Script = NormalizeScriptText(GetGadgetText(#Gad_ObjScript))
      Objects()\IP = 0
      Objects()\Wait = 0

      SetStatus("Updated object " + Objects()\Name)
    EndIf
  EndIf

  CloseWindow(#Win_Object)
  RefocusMainWindow()
EndProcedure

;------------------------------------------------------------------------------
; OpenBoardDialog
; Purpose: Procedure: Open Board Dialog.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Declare OpenBoardMusicDialog(BoardIdx.i)
Declare.b SaveWorld(FilePath.s)
Declare.s ComposeSong(Mode.i, Tempo.i, Root.i, Steps.i, Seed.i)

Procedure OpenBoardDialog()
  Protected ev.i, gid.i
  Protected ok.b
  Protected b.i = CurBoard()
  Protected maxBoard.i

  If b < 0 Or b >= BoardCount
    ProcedureReturn
  EndIf

  maxBoard = BoardCount - 1
  If maxBoard < 0 : maxBoard = 0 : EndIf

  DisableWindow(0, 1)
  ResetKeyLatches()
 
  OpenWindow(#Win_Board, 0, 0, 520, 280, "Board Settings", #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_TitleBar, WindowID(0))

  TextGadget(#PB_Any, 10, 12, 80, 20, "Name")
  StringGadget(#Gad_BoardName, 90, 10, 410, 24, Boards(b)\Name)

  TextGadget(#PB_Any, 10, 46, 80, 20, "Start X")
  SpinGadget(#Gad_BoardStartX, 90, 44, 70, 24, 0, #MAP_W - 1, #PB_Spin_Numeric)
  SetGadgetState(#Gad_BoardStartX, Clamp(Boards(b)\StartX, 0, #MAP_W - 1))

  TextGadget(#PB_Any, 180, 46, 80, 20, "Start Y")
  SpinGadget(#Gad_BoardStartY, 250, 44, 70, 24, 0, #MAP_H - 1, #PB_Spin_Numeric)
  SetGadgetState(#Gad_BoardStartY, Clamp(Boards(b)\StartY, 0, #MAP_H - 1))

  CheckBoxGadget(#Gad_BoardDark, 10, 86, 240, 22, "Dark room (needs torch)")
  SetGadgetState(#Gad_BoardDark, Bool(Boards(b)\Dark <> 0))

  TextGadget(#PB_Any, 10, 112, 200, 22, "Edge exits (board index, -1 = none)")
 
  TextGadget(#PB_Any, 10, 140, 60, 20, "North")
  SpinGadget(#Gad_BoardExitN, 90, 112, 70, 24, -1, maxBoard, #PB_Spin_Numeric)
  SetGadgetState(#Gad_BoardExitN, Boards(b)\ExitN)

  TextGadget(#PB_Any, 180, 140, 60, 20, "South")
  SpinGadget(#Gad_BoardExitS, 250, 138, 70, 24, -1, maxBoard, #PB_Spin_Numeric)
  SetGadgetState(#Gad_BoardExitS, Boards(b)\ExitS)

  TextGadget(#PB_Any, 10, 174, 60, 20, "West")
  SpinGadget(#Gad_BoardExitW, 90, 172, 70, 24, -1, maxBoard, #PB_Spin_Numeric)
  SetGadgetState(#Gad_BoardExitW, Boards(b)\ExitW)

  TextGadget(#PB_Any, 180, 174, 60, 20, "East")
  SpinGadget(#Gad_BoardExitE, 250, 172, 70, 24, -1, maxBoard, #PB_Spin_Numeric)
  SetGadgetState(#Gad_BoardExitE, Boards(b)\ExitE)

  ButtonGadget(#Gad_BoardMusic, 10, 210, 110, 30, "Music...")
  ButtonGadget(#Gad_BoardOk, 320, 210, 90, 30, "OK")
  ButtonGadget(#Gad_BoardCancel, 410, 210, 90, 30, "Cancel")

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_CloseWindow
        ok = #False
        Break

      Case #PB_Event_Gadget
        gid = EventGadget()
        Select gid
          Case #Gad_BoardMusic
            OpenBoardMusicDialog(b)

          Case #Gad_BoardOk
            ok = #True
            Break
          Case #Gad_BoardCancel
            ok = #False
            Break
        EndSelect
    EndSelect
  ForEver

  If ok
    Boards(b)\Name = GetGadgetText(#Gad_BoardName)
    Boards(b)\StartX = Clamp(GetGadgetState(#Gad_BoardStartX), 0, #MAP_W - 1)
    Boards(b)\StartY = Clamp(GetGadgetState(#Gad_BoardStartY), 0, #MAP_H - 1)
    Boards(b)\Dark = Bool(GetGadgetState(#Gad_BoardDark) <> 0)

    Boards(b)\ExitN = Clamp(GetGadgetState(#Gad_BoardExitN), -1, BoardCount - 1)
    Boards(b)\ExitS = Clamp(GetGadgetState(#Gad_BoardExitS), -1, BoardCount - 1)
    Boards(b)\ExitW = Clamp(GetGadgetState(#Gad_BoardExitW), -1, BoardCount - 1)
    Boards(b)\ExitE = Clamp(GetGadgetState(#Gad_BoardExitE), -1, BoardCount - 1)

    SanitizeBoard(b)
    PlayerX = Boards(b)\StartX
    PlayerY = Boards(b)\StartY
    CursorX = PlayerX
    CursorY = PlayerY

    SetStatus("Updated board settings.")
  EndIf

  CloseWindow(#Win_Board)
  RefocusMainWindow()
EndProcedure

Structure TMusicPreset
  Name.s
  Song.s
  ItemIndex.i
EndStructure

Procedure.b BoardNameHas(BoardIdx.i, Needle.s)
  If BoardIdx < 0 Or BoardIdx >= BoardCount
    ProcedureReturn #False
  EndIf
  If Needle = "" : ProcedureReturn #False : EndIf
  ProcedureReturn Bool(FindString(LCase(Boards(BoardIdx)\Name), LCase(Needle), 1) > 0)
EndProcedure

Procedure.i CountBoardChar(BoardIdx.i, ch.a)
  Protected i.i
  Protected cnt.i

  If BoardIdx < 0 Or BoardIdx >= BoardCount
    ProcedureReturn 0
  EndIf

  For i = 0 To (#MAP_W * #MAP_H) - 1
    If Boards(BoardIdx)\Map[i] = ch
      cnt + 1
    EndIf
  Next

  ProcedureReturn cnt
EndProcedure

Procedure AddMusicPreset(List presets.TMusicPreset(), Name.s, Song.s)
  If Name = "" : ProcedureReturn : EndIf

  AddElement(presets())
  presets()\Name = Name
  presets()\Song = NormalizeMusicText(Song)
  presets()\ItemIndex = -1
EndProcedure

Procedure LoadMusicPresetsFromLevels(List presets.TMusicPreset())
  Protected levelsDir.s = MainSourceDir + "levels\\"
  Protected dir.i

  dir = ExamineDirectory(#PB_Any, levelsDir, "*.txt")
  If dir = 0
    ProcedureReturn
  EndIf

  While NextDirectoryEntry(dir)
    If DirectoryEntryType(dir) = #PB_DirectoryEntry_File
      Protected filePath.s = levelsDir + DirectoryEntryName(dir)
      Protected f.i = ReadFile(#PB_Any, filePath)
      If f
        Protected section.s = ""
        Protected boardName.s = ""
        Protected boardNumInFile.i = -1
        Protected inMusic.b = #False
        Protected buf.s = ""

        While Eof(f) = 0
          Protected line.s = ReplaceString(ReadString(f), #CR$, "")
          line = ReplaceString(line, #CRLF$, "")

          If Left(LTrim(line), 2) = "# "
            Continue
          EndIf

          Protected t.s = Trim(line)
          If Left(t, 1) = "[" And FindString(t, "]", 1)
            section = UCase(Mid(t, 2, FindString(t, "]", 1) - 2))
            If section = "BOARD"
              boardNumInFile + 1
              boardName = ""
            EndIf
            Continue
          EndIf

          If section = "BOARD"
            Protected eq.i = FindString(t, "=", 1)
            If eq > 0
              Protected k.s = UCase(Trim(Left(t, eq - 1)))
              Protected v.s = Trim(Mid(t, eq + 1))
              If k = "NAME"
                boardName = v
              EndIf
            EndIf
          EndIf

          If t = "MusicBegin"
            inMusic = #True
            buf = ""
            Continue
          EndIf

          If t = "MusicEnd"
            inMusic = #False
            If Trim(buf) <> ""
              Protected disp.s
              If boardName <> ""
                disp = "levels/" + GetFilePart(filePath) + ": " + boardName
              Else
                disp = "levels/" + GetFilePart(filePath) + ": Board " + Str(boardNumInFile)
              EndIf
              AddMusicPreset(presets(), disp, buf)
            EndIf
            buf = ""
            Continue
          EndIf

          If inMusic
            buf + line + #LF$
          EndIf
        Wend

        CloseFile(f)
      EndIf
    EndIf
  Wend

  FinishDirectory(dir)
EndProcedure

Procedure.i FillMusicPresetCombo(gPreset.i, BoardIdx.i, List presets.TMusicPreset())
  ClearGadgetItems(gPreset)
  ClearList(presets())

  AddMusicPreset(presets(), "(none)", "")

  If BoardIdx >= 0 And BoardIdx < BoardCount
    If Trim(Boards(BoardIdx)\Music) <> ""
      AddMusicPreset(presets(), "Current board: " + Boards(BoardIdx)\Name, Boards(BoardIdx)\Music)
    EndIf
  EndIf

  ; Current loaded world boards.
  Protected b.i
  For b = 0 To BoardCount - 1
    If Trim(Boards(b)\Music) <> ""
      AddMusicPreset(presets(), "World board " + Str(b) + ": " + Boards(b)\Name, Boards(b)\Music)
    EndIf
  Next

  ; Shipped/other .txt worlds under levels/.
  LoadMusicPresetsFromLevels(presets())

  ForEach presets()
    presets()\ItemIndex = AddGadgetItem(gPreset, -1, presets()\Name)
  Next

  SetGadgetState(gPreset, 0)
  ProcedureReturn CountGadgetItems(gPreset)
EndProcedure

Procedure.s ComposeSongForBoard(BoardIdx.i, Tempo.i, Root.i, Steps.i, Seed.i)
  ; Uses (Tempo,Root,Steps,Seed) as a base, then nudges mode/tempo based on board.
  Protected mode.i = 0
  Protected tempoAdj.i = 0

  If BoardIdx < 0 Or BoardIdx >= BoardCount
    ProcedureReturn ComposeSong(0, Tempo, Root, Steps, Seed)
  EndIf

  If BoardNameHas(BoardIdx, "cave") Or BoardNameHas(BoardIdx, "dungeon") Or BoardNameHas(BoardIdx, "crypt")
    mode = 1
    tempoAdj - 20
  ElseIf BoardNameHas(BoardIdx, "forest") Or BoardNameHas(BoardIdx, "woods")
    mode = 2
    tempoAdj - 5
  ElseIf BoardNameHas(BoardIdx, "town") Or BoardNameHas(BoardIdx, "village")
    mode = 0
    tempoAdj + 10
  ElseIf BoardNameHas(BoardIdx, "water") Or BoardNameHas(BoardIdx, "lake")
    mode = 2
    tempoAdj - 10
  EndIf

  If Boards(BoardIdx)\Dark
    mode = 1
    tempoAdj - 10
  EndIf

  ; Map-based hinting (very cheap heuristics).
  Protected waterCt.i = CountBoardChar(BoardIdx, Asc("W")) + CountBoardChar(BoardIdx, Asc("~"))
  Protected treeCt.i = CountBoardChar(BoardIdx, Asc("T"))
  Protected treasureCt.i = CountBoardChar(BoardIdx, Asc("$"))
  Protected enemyCt.i = CountBoardChar(BoardIdx, Asc("E"))

  If waterCt > 60 : tempoAdj - 8 : EndIf
  If treeCt > 80 : tempoAdj - 2 : EndIf
  If treasureCt > 6 : tempoAdj + 6 : EndIf
  If enemyCt > 4 : tempoAdj - 4 : EndIf

  Tempo = Clamp(Tempo + tempoAdj, 40, 400)

  ; Nudge root if it clashes with flat-only presets (keep it simple).
  Root = Clamp(Root, 0, 11)

  ProcedureReturn ComposeSong(mode, Tempo, Root, Steps, Seed)

EndProcedure

Procedure.s ComposeSong(Mode.i, Tempo.i, Root.i, Steps.i, Seed.i)
  ; Mode: 0=Major, 1=Minor, 2=Dorian-ish
  Protected stepIdx.i

  Protected scaleMajor.s = "0 2 4 5 7 9 11"
  Protected scaleMinor.s = "0 2 3 5 7 8 10"
  Protected scaleDorian.s = "0 2 3 5 7 9 10"

  Protected scale.s
  Protected chanceLeadEven.i = 55
  Protected chanceLeadRand.i = 18
  Protected chanceDrumOff.i = 35

  Select Mode
    Case 1
      scale = scaleMinor
      chanceLeadEven = 40
      chanceLeadRand = 10
      chanceDrumOff = 22
    Case 2
      scale = scaleDorian
      chanceLeadEven = 48
      chanceLeadRand = 14
      chanceDrumOff = 28
    Default
      scale = scaleMajor
  EndSelect


  If Tempo <= 0 : Tempo = 120 : EndIf
  Tempo = Clamp(Tempo, 40, 400)
  If Steps < 16 : Steps = 16 : EndIf
  If Steps > 256 : Steps = 256 : EndIf

  ; Root is a MIDI-ish semitone offset where C=0. Default to C.
  Root = Clamp(Root, 0, 11)

  If Seed <= 0
    Seed = ElapsedMilliseconds()
  EndIf
  RandomSeed(Seed)

  Protected out.s = "T=" + Str(Tempo) + #LF$
  Protected lead.s = "SQ  "
  Protected bass.s = "SQ2 "
  Protected dr.s = "DR  "
 
  For stepIdx = 0 To Steps - 1

    ; lead rhythm: mostly notes on 8ths/16ths with rests.
    Protected playLead.b = #False
    If Mod(stepIdx, 4) = 0
      playLead = #True
    ElseIf Mod(stepIdx, 2) = 0 And Random(100) < chanceLeadEven
      playLead = #True
    ElseIf Random(100) < chanceLeadRand
      playLead = #True

    EndIf

    If playLead
      Protected deg.i = Random(6) ; 0..6
      Protected semi.i = Val(StringField(scale, deg + 1, " "))
      Protected octave.i = 5
      If Random(100) < 20 : octave = 4 : EndIf
      If Random(100) < 10 : octave = 6 : EndIf

      ; Convert to note name using sharps only.
      Protected noteSemi.i = Mod(Root + semi, 12)
      Protected noteName.s
      Select noteSemi
        Case 0 : noteName = "C"
        Case 1 : noteName = "C#"
        Case 2 : noteName = "D"
        Case 3 : noteName = "D#"
        Case 4 : noteName = "E"
        Case 5 : noteName = "F"
        Case 6 : noteName = "F#"
        Case 7 : noteName = "G"
        Case 8 : noteName = "G#"
        Case 9 : noteName = "A"
        Case 10 : noteName = "A#"
        Case 11 : noteName = "B"
      EndSelect
      lead + noteName + Str(octave)
    Else
      lead + "-"
    EndIf
    lead + " "

    ; bass: root -> fifth-ish. Hits on quarters.
    If Mod(stepIdx, 4) = 0
      Protected bassChoice.i = Random(100)
      Protected bassSemi.i
      If bassChoice < 70
        bassSemi = Root
      Else
        bassSemi = Mod(Root + 7, 12)
      EndIf

      Protected bassName.s
      Select bassSemi
        Case 0 : bassName = "C"
        Case 1 : bassName = "C#"
        Case 2 : bassName = "D"
        Case 3 : bassName = "D#"
        Case 4 : bassName = "E"
        Case 5 : bassName = "F"
        Case 6 : bassName = "F#"
        Case 7 : bassName = "G"
        Case 8 : bassName = "G#"
        Case 9 : bassName = "A"
        Case 10 : bassName = "A#"
        Case 11 : bassName = "B"
      EndSelect
      bass + bassName + "3"
    Else
      bass + "-"
    EndIf
    bass + " "

    ; drums: kickoff on beats, plus occasional off-beats.
    If Mod(stepIdx, 4) = 0
      dr + "x"
    ElseIf Mod(stepIdx, 2) = 0 And Random(100) < chanceDrumOff
      dr + "x"

    Else
      dr + "-"
    EndIf
    dr + " "

    ; Visual bar every 16 steps.
    If Mod(stepIdx + 1, 16) = 0 And stepIdx < Steps - 1
      lead + "| "
      bass + "| "
      dr + "| "
    EndIf
  Next

  out + Trim(lead) + #LF$
  out + Trim(bass) + #LF$
  out + Trim(dr) + #LF$
  ProcedureReturn out
EndProcedure

Procedure.b OpenSongComposerDialog(BoardIdx.i, *outSong.String)
  Protected win.i, ev.i, gid.i
  Protected ok.b = #False
  Protected gStyle.i, gTempo.i, gRoot.i, gLen.i, gSeed.i
  Protected gPreview.i, gApply.i, gCancel.i
  Protected gPlay.i, gStop.i

  If *outSong = 0 : ProcedureReturn #False : EndIf

  win = OpenWindow(#PB_Any, 0, 0, 520, 420, "Song Composer", #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_TitleBar, WindowID(0))
  If win = 0 : ProcedureReturn #False : EndIf
  SetActiveWindow(win)

  TextGadget(#PB_Any, 10, 10, 500, 34, "Generates a simple loop for the current board music. Output uses T=/SQ/SQ2/DR with valid note tokens.")

  TextGadget(#PB_Any, 10, 52, 80, 20, "Style")
  gStyle = ComboBoxGadget(#PB_Any, 90, 48, 140, 24)
  AddGadgetItem(gStyle, -1, "Smart (board)")
  AddGadgetItem(gStyle, -1, "Major")
  AddGadgetItem(gStyle, -1, "Minor")
  AddGadgetItem(gStyle, -1, "Dorian")
  SetGadgetState(gStyle, 0)

  TextGadget(#PB_Any, 250, 52, 60, 20, "Tempo")
  gTempo = SpinGadget(#PB_Any, 310, 48, 70, 24, 40, 400, #PB_Spin_Numeric)
  SetGadgetState(gTempo, 120)

  TextGadget(#PB_Any, 10, 84, 80, 20, "Preset")
  Protected gPreset.i
  gPreset = ComboBoxGadget(#PB_Any, 90, 80, 420, 24)
  Protected NewList presets.TMusicPreset()
  FillMusicPresetCombo(gPreset, BoardIdx, presets())

  TextGadget(#PB_Any, 10, 116, 80, 20, "Root")
  gRoot = ComboBoxGadget(#PB_Any, 90, 112, 140, 24)
  AddGadgetItem(gRoot, -1, "C")
  AddGadgetItem(gRoot, -1, "C#")
  AddGadgetItem(gRoot, -1, "D")
  AddGadgetItem(gRoot, -1, "D#")
  AddGadgetItem(gRoot, -1, "E")
  AddGadgetItem(gRoot, -1, "F")
  AddGadgetItem(gRoot, -1, "F#")
  AddGadgetItem(gRoot, -1, "G")
  AddGadgetItem(gRoot, -1, "G#")
  AddGadgetItem(gRoot, -1, "A")
  AddGadgetItem(gRoot, -1, "A#")
  AddGadgetItem(gRoot, -1, "B")
  SetGadgetState(gRoot, 0)

  TextGadget(#PB_Any, 250, 116, 60, 20, "Steps")
  gLen = SpinGadget(#PB_Any, 310, 112, 70, 24, 16, 256, #PB_Spin_Numeric)
  SetGadgetState(gLen, 64)

  TextGadget(#PB_Any, 10, 148, 80, 20, "Seed")
  gSeed = StringGadget(#PB_Any, 90, 144, 140, 24, "")
  TextGadget(#PB_Any, 250, 148, 260, 20, "(blank = random each time)")

  gPreview = ButtonGadget(#PB_Any, 10, 176, 110, 28, "Generate")
  gPlay = ButtonGadget(#PB_Any, 130, 176, 70, 28, "Play")
  gStop = ButtonGadget(#PB_Any, 210, 176, 70, 28, "Stop")

  Protected gText.i
  gText = EditorGadget(#PB_Any, 10, 212, 500, 150)

  gApply = ButtonGadget(#PB_Any, 320, 372, 90, 30, "Apply")
  gCancel = ButtonGadget(#PB_Any, 420, 372, 90, 30, "Cancel")

  ; Default preview: try smart board-based generation.
  SetGadgetText(gText, NormalizeMusicText(ComposeSongForBoard(BoardIdx, 120, 0, 64, 0)))

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_CloseWindow
        ok = #False
        Break

        Case #PB_Event_Gadget
          gid = EventGadget()
          Select gid
            Case gPreset
              Protected presetIdx.i = GetGadgetState(gPreset)
              If presetIdx >= 0 And presetIdx < ListSize(presets())
                SelectElement(presets(), presetIdx)
                If presets()\Song <> ""
                  SetGadgetText(gText, presets()\Song)
                EndIf
              EndIf

            Case gPreview
              Protected mode.i = GetGadgetState(gStyle)
              Protected tempo.i = GetGadgetState(gTempo)
              Protected root.i = GetGadgetState(gRoot)
              Protected steps.i = GetGadgetState(gLen)
              Protected seedText.s = Trim(GetGadgetText(gSeed))
              Protected seed.i = 0
              If seedText <> "" : seed = Val(seedText) : EndIf

              If mode = 0
                SetGadgetText(gText, NormalizeMusicText(ComposeSongForBoard(BoardIdx, tempo, root, steps, seed)))
              Else
                SetGadgetText(gText, NormalizeMusicText(ComposeSong(mode - 1, tempo, root, steps, seed)))
              EndIf


          Case gPlay
            StartBoardMusic("COMPOSE:BOARD:" + Str(BoardIdx), NormalizeMusicText(GetGadgetText(gText)))

          Case gStop
            StopBoardMusic()

          Case gApply
            *outSong\s = NormalizeMusicText(GetGadgetText(gText))
            ok = #True
            Break

          Case gCancel
            ok = #False
            Break
        EndSelect
    EndSelect
  ForEver

  CloseWindow(win)
  RefocusMainWindow()
  ProcedureReturn ok
EndProcedure

Procedure OpenBoardMusicDialog(BoardIdx.i)
  Protected ev.i, gid.i
  Protected ok.b
  Protected win.i
  Protected gEdit.i
  Protected gPlay.i
  Protected gStop.i
  Protected gClear.i
  Protected gCompose.i
  Protected gApplyNow.i
  Protected gOk.i
  Protected gCancel.i

  If BoardIdx < 0 Or BoardIdx >= BoardCount
    ProcedureReturn
  EndIf

  DisableWindow(0, 1)
  ResetKeyLatches()

  win = OpenWindow(#PB_Any, 0, 0, 720, 520, "Board Music (Board " + Str(BoardIdx) + ")", #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_TitleBar, WindowID(0))
  If win = 0
    DisableWindow(0, 0)
    MessageRequester(#APP_NAME, "Failed to open music editor window.")
    ProcedureReturn
  EndIf
  SetActiveWindow(win)

  TextGadget(#PB_Any, 10, 10, 680, 34, "Format: optional 'T=120' then lines like 'SQ ...', 'SQ2 ...', 'DR ...' (16th-note steps).  Use '-' for rests and '|' for visual bars.")

  gEdit = EditorGadget(#PB_Any, 10, 50, 700, 390)
  SetGadgetText(gEdit, Boards(BoardIdx)\Music)

  gPlay = ButtonGadget(#PB_Any, 10, 450, 90, 30, "Play")
  gStop = ButtonGadget(#PB_Any, 110, 450, 90, 30, "Stop")
  gClear = ButtonGadget(#PB_Any, 210, 450, 90, 30, "Clear")
  gCompose = ButtonGadget(#PB_Any, 310, 450, 90, 30, "Compose")
  gApplyNow = ButtonGadget(#PB_Any, 410, 450, 90, 30, "Apply+Save")
 
  gOk = ButtonGadget(#PB_Any, 530, 450, 90, 30, "OK")
  gCancel = ButtonGadget(#PB_Any, 620, 450, 90, 30, "Cancel")

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_CloseWindow
        ok = #False
        Break

      Case #PB_Event_Gadget
        gid = EventGadget()
        Select gid
          Case gPlay
            StartBoardMusic("EDITOR:BOARD:" + Str(BoardIdx), NormalizeMusicText(GetGadgetText(gEdit)))

          Case gStop
            StopBoardMusic()

          Case gClear
            SetGadgetText(gEdit, "")

          Case gCompose
            Protected composed.String
            composed\s = ""
            If OpenSongComposerDialog(BoardIdx, @composed)
              If composed\s <> ""
                SetGadgetText(gEdit, composed\s)
              EndIf
            EndIf

          Case gApplyNow
            ; Apply to the board and attempt to save directly to the current world.
            Boards(BoardIdx)\Music = NormalizeMusicText(GetGadgetText(gEdit))
            If BoardIdx = CurBoard()
              If Boards(BoardIdx)\Music <> ""
                StartBoardMusic("WORLD:" + World\FilePath + ":BOARD:" + Str(BoardIdx), Boards(BoardIdx)\Music)
              Else
                StopBoardMusic()
              EndIf
            EndIf

            If EditMode And World\FilePath <> "" And FileSize(World\FilePath) <> -1
              If SaveWorld(World\FilePath)
                SetStatus("Saved world: " + GetFilePart(World\FilePath), 2500)
              Else
                SetStatus("Save failed.", 2500)
              EndIf
            Else
              SetStatus("Applied music (world not saved: no World\\FilePath)", 3500)
            EndIf

          Case gOk
            ok = #True
            Break

          Case gCancel
            ok = #False
            Break
        EndSelect
    EndSelect
  ForEver

  If ok
    Boards(BoardIdx)\Music = NormalizeMusicText(GetGadgetText(gEdit))

    ; If editing current board, restart music.
    If BoardIdx = CurBoard()
      If Boards(BoardIdx)\Music <> ""
        StartBoardMusic("WORLD:" + World\FilePath + ":BOARD:" + Str(BoardIdx), Boards(BoardIdx)\Music)
      Else
        StopBoardMusic()
      EndIf
    EndIf

    SetStatus("Updated board music.")
  EndIf

  CloseWindow(win)
  RefocusMainWindow()
EndProcedure
 
 ;------------------------------------------------------------------------------
 ; Help (procedures in includes/help.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/help.pbi"

;------------------------------------------------------------------------------
; Sound Settings (procedures in includes/sound_dialog.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/sound_dialog.pbi"

;------------------------------------------------------------------------------
; OpenWorldDialog
; Purpose: Procedure: Open World Dialog.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure OpenWorldDialog()
  Protected ev.i, gid.i
  Protected ok.b
  Protected maxBoard.i

  maxBoard = BoardCount - 1
  If maxBoard < 0 : maxBoard = 0 : EndIf

  DisableWindow(0, 1)
  ResetKeyLatches()

  OpenWindow(#Win_World, 0, 0, 520, 320, "World Settings", #PB_Window_ScreenCentered | #PB_Window_SystemMenu | #PB_Window_TitleBar, WindowID(0))
 
  TextGadget(#PB_Any, 10, 12, 80, 20, "Name")
  StringGadget(#Gad_WorldName, 90, 10, 410, 24, World\Name)
 
  TextGadget(#PB_Any, 10, 46, 80, 20, "Start board")
  SpinGadget(#Gad_WorldStartBoard, 90, 44, 90, 24, 0, maxBoard, #PB_Spin_Numeric)
  SetGadgetState(#Gad_WorldStartBoard, Clamp(World\StartBoard, 0, maxBoard))
 
  CheckBoxGadget(#Gad_WorldBangOneShot, 90, 78, 260, 22, "! markers: one-shot (otherwise repeat)")
  SetGadgetState(#Gad_WorldBangOneShot, Bool(World\BangOneShot <> 0))
 
  CheckBoxGadget(#Gad_WorldRespawnAtWorldStart, 90, 106, 360, 22, "Respawn at world start (otherwise current board)")
  SetGadgetState(#Gad_WorldRespawnAtWorldStart, Bool(World\RespawnAtWorldStart <> 0))
 
  TextGadget(#PB_Any, 10, 140, 160, 20, "Death: lose score")
  SpinGadget(#Gad_WorldDeathLoseScore, 180, 138, 110, 24, 0, 999999, #PB_Spin_Numeric)
  SetGadgetState(#Gad_WorldDeathLoseScore, Clamp(World\DeathLoseScore, 0, 999999))
 
  TextGadget(#PB_Any, 10, 174, 160, 20, "Death: lose keys")
  SpinGadget(#Gad_WorldDeathLoseKeys, 180, 172, 110, 24, 0, 9999, #PB_Spin_Numeric)
  SetGadgetState(#Gad_WorldDeathLoseKeys, Clamp(World\DeathLoseKeys, 0, 9999))
 
  TextGadget(#PB_Any, 10, 208, 160, 20, "Respawn delay (ms)")
  SpinGadget(#Gad_WorldDeathRespawnDelayMS, 180, 206, 110, 24, 0, 60000, #PB_Spin_Numeric)
  SetGadgetState(#Gad_WorldDeathRespawnDelayMS, Clamp(World\DeathRespawnDelayMS, 0, 60000))
 
  TextGadget(#PB_Any, 10, 242, 160, 20, "Death fade (ms)")
  SpinGadget(#Gad_WorldDeathFadeMS, 180, 240, 110, 24, 0, 60000, #PB_Spin_Numeric)
  SetGadgetState(#Gad_WorldDeathFadeMS, Clamp(World\DeathFadeMS, 0, 60000))
 
  ButtonGadget(#Gad_WorldOk, 320, 260, 90, 30, "OK")
  ButtonGadget(#Gad_WorldCancel, 410, 260, 90, 30, "Cancel")

  Repeat
    ev = WaitWindowEvent()
    Select ev
      Case #PB_Event_CloseWindow
        ok = #False
        Break

      Case #PB_Event_Gadget
        gid = EventGadget()
        Select gid
          Case #Gad_WorldOk
            ok = #True
            Break
          Case #Gad_WorldCancel
            ok = #False
            Break
        EndSelect
    EndSelect
  ForEver

  If ok
    World\Name = GetGadgetText(#Gad_WorldName)
    World\StartBoard = Clamp(GetGadgetState(#Gad_WorldStartBoard), 0, maxBoard)
    World\BangOneShot = Bool(GetGadgetState(#Gad_WorldBangOneShot) <> 0)
 
    World\RespawnAtWorldStart = Bool(GetGadgetState(#Gad_WorldRespawnAtWorldStart) <> 0)
    World\DeathLoseScore = Clamp(GetGadgetState(#Gad_WorldDeathLoseScore), 0, 999999)
    World\DeathLoseKeys = Clamp(GetGadgetState(#Gad_WorldDeathLoseKeys), 0, 9999)
    World\DeathRespawnDelayMS = Clamp(GetGadgetState(#Gad_WorldDeathRespawnDelayMS), 0, 60000)
    World\DeathFadeMS = Clamp(GetGadgetState(#Gad_WorldDeathFadeMS), 0, 60000)
 
    ; Keep current board legal; don't force a board switch.
    World\StartBoard = Clamp(World\StartBoard, 0, BoardCount - 1)
    World\CurrentBoard = Clamp(World\CurrentBoard, 0, BoardCount - 1)
 
    SetStatus("Updated world settings.")
  EndIf

  SavePrefs()

  CloseWindow(#Win_World)
  RefocusMainWindow()
EndProcedure

;------------------------------------------------------------------------------
; World loading/saving (procedures in includes/world_io.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/world_io.pbi"

;------------------------------------------------------------------------------
; BuildWorldList
; Purpose: Procedure: Build World List.
; Params:
;   List Files.s()
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure BuildWorldList(List Files.s())
  Protected dir.i
  ClearList(Files())

  If LevelsDir = "" : ProcedureReturn : EndIf

  dir = ExamineDirectory(#PB_Any, LevelsDir, "*.txt")
  If dir
    While NextDirectoryEntry(dir)
      If DirectoryEntryType(dir) = #PB_DirectoryEntry_File
        AddElement(Files())
        Files() = LevelsDir + DirectoryEntryName(dir)
      EndIf
    Wend
    FinishDirectory(dir)
  EndIf
EndProcedure

;------------------------------------------------------------------------------
; LoadWorldByIndex
; Purpose: Procedure: Load World By Index.
; Params:
;   Index.i
;   List Files.s()
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i FindWorldFileIndex(List Files.s(), PreferredBaseName.s)
  Protected idx.i = 0
  Protected want.s = UCase(Trim(PreferredBaseName))

  If want = "" : ProcedureReturn -1 : EndIf

  ForEach Files()
    If UCase(GetFilePart(Files())) = want
      ProcedureReturn idx
    EndIf
    idx + 1
  Next

  ProcedureReturn -1
EndProcedure

Procedure LoadWorldByIndex(Index.i, List Files.s())
  Protected count.i = ListSize(Files())
  Protected ok.b
  Protected path.s

  If count = 0
    LoadWorld("")
    WorldIndex = 0
    SetStatus("No world files found.", 4000)
    ProcedureReturn
  EndIf

  WorldIndex = (Index % count + count) % count
  SelectElement(Files(), WorldIndex)
  path = Files()
  ok = LoadWorld(path)

   Score = 0
   Keys = 0
   ClearMap(ColorKeys())
   Health = 5
   TorchStepsLeft = 0
   LanternStepsLeft = 0
   DeathPending = #False
   DeathAtMS = 0
   DeathFadeUntilMS = 0

If ok
    PrefLastWorldPath = path
    SavePrefs()
    SetStatus("World: " + World\Name + " (" + Str(BoardCount) + " boards, " + Str(ListSize(Objects())) + " objects)  File:" + GetFilePart(path) + "  Size:" + Str(FileSize(path)), 5000)
  Else
    SetStatus("Failed to load: " + path + "  Size:" + Str(FileSize(path)), 5000)
  EndIf
EndProcedure

; ----------------- main -----------------

;------------------------------------------------------------------------------
; Core init (procedures in includes/init_app.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/init_app.pbi"

InitAppCore()

;------------------------------------------------------------------------------
; Bootstrap + shutdown (procedures in includes/bootstrap.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/bootstrap.pbi"

NewList WorldFiles.s()
InitDisplayAndLoadWorld(WorldFiles())

;------------------------------------------------------------------------------
; Main loop (procedures in includes/game_loop.pbi)
;------------------------------------------------------------------------------

XIncludeFile "includes/game_loop.pbi"

MainLoop(WorldFiles())

ShutdownApp()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 2957
; FirstLine = 2935
; Folding = -----------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_ZZT.ico
; Executable = PB_ZZT.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = PB_ZZT
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = A ZZT clone
; VersionField7 = PB_ZZT
; VersionField8 = PB_ZZT.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60