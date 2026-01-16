;------------------------------------------------------------------------------
; Rendering (extracted from pbzt.pb)
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; DrawWorld
; Purpose: Render the current board and UI.
;------------------------------------------------------------------------------

Procedure DrawWorld()
  Protected x.i, y.i, idx.i
  Protected px.i, py.i
  Protected ch.a, col.i
  Protected underlineH.i
  Protected uiY.i = #MAP_H * TileH
  Protected status.s
  Protected fuelInfo.s
  Protected b.i = CurBoard()
  Protected enemyCount.i
  Protected fadeNow.i, fadeT.i, fadeSteps.i, fadeStep.i, fadeH.i

  If b < 0 Or b >= BoardCount
    ProcedureReturn
  EndIf

  RebuildObjectOverlay()

  If StartDrawing(ScreenOutput()) = 0
    ProcedureReturn
  EndIf

  DrawingFont(FontID(FontId))
  DrawingMode(#PB_2DDrawing_Default)

  Box(0, 0, WinW, WinH, RGB(0, 0, 0))
  BackColor(RGB(0, 0, 0))

  For y = 0 To #MAP_H - 1
    py = y * TileH
    For x = 0 To #MAP_W - 1
      px = x * TileW
      idx = x + y * #MAP_W

      ch = Boards(b)\Map[idx]
      col = Boards(b)\Color[idx]

      If ObjOverlayId(idx) <> 0
        ch = ObjOverlayChar(idx)
        col = ObjOverlayColor(idx)
      EndIf

      If x = PlayerX And y = PlayerY
        ch = Asc("@")
        col = Palette(Asc("@"))
      EndIf

      If EditMode And x = CursorX And y = CursorY
        ; Draw cell normally, then overlay a visible cursor.
        FrontColor(VGAColor(col))
        DrawText(px, py, Chr(ch))

        ; White underline cursor for visibility.
        underlineH = 2
        If TileH >= 18 : underlineH = 3 : EndIf
        Box(px, py + TileH - underlineH, TileW, underlineH, RGB(255, 255, 255))
      Else
        FrontColor(VGAColor(col))
        DrawText(px, py, Chr(ch))
      EndIf
    Next
  Next

  ; Lighting overlay: in dark boards, fade to black outside radius.
  If EditMode = 0 And Boards(b)\Dark
    Protected radius.i
    Protected dim1.i, dim2.i
    Protected d.i

    If HasScriptItem("LANTERN")
      radius = #LANTERN_RADIUS
    ElseIf HasScriptItem("TORCH")
      radius = #TORCH_RADIUS
    Else
      radius = #DARK_NO_LIGHT_RADIUS
    EndIf

    ; two soft fade rings outside the bright radius
    dim1 = radius + 2
    dim2 = radius + 4

    DrawingMode(#PB_2DDrawing_AlphaBlend)

    Protected a.i
    For y = 0 To #MAP_H - 1
      py = y * TileH
      For x = 0 To #MAP_W - 1
        d = Abs(x - PlayerX) + Abs(y - PlayerY)

        a = 0
        If d > dim2
          a = 255
        ElseIf d > dim1
          a = 200
        ElseIf d > radius
          a = 120
        EndIf

        If a > 0
          Box(x * TileW, py, TileW, TileH, RGBA(0, 0, 0, a))
        EndIf
      Next
    Next

    ; Keep player visible even at low radius
    DrawingMode(#PB_2DDrawing_Default)
    FrontColor(VGAColor(Palette(Asc("@"))))
    DrawText(PlayerX * TileW, PlayerY * TileH, "@")

  EndIf

  If ElapsedMilliseconds() > StatusExpireMS
    status = ""
  Else
    status = NewLineStatus
  EndIf

  fuelInfo = ""
  If EditMode = 0
    If Boards(b)\Dark
      fuelInfo = "  Dark"

      If LanternStepsLeft > 0 And HasScriptItem("LANTERN")
        fuelInfo + "  Light:T(r=" + Str(#LANTERN_RADIUS) + ")"
      ElseIf TorchStepsLeft > 0 And HasScriptItem("TORCH")
        fuelInfo + "  Light:t(r=" + Str(#TORCH_RADIUS) + ")"
      Else
        fuelInfo + "  Light:None(r=" + Str(#DARK_NO_LIGHT_RADIUS) + ")"
      EndIf

      If LanternStepsLeft > 0
        fuelInfo + "  T:" + Str(LanternStepsLeft)
      EndIf
      If TorchStepsLeft > 0
        fuelInfo + "  t:" + Str(TorchStepsLeft)
      EndIf
    Else
      If TorchStepsLeft > 0 Or LanternStepsLeft > 0
        fuelInfo = "  Fuel"
        If TorchStepsLeft > 0 : fuelInfo + "  t:" + Str(TorchStepsLeft) : EndIf
        If LanternStepsLeft > 0 : fuelInfo + "  T:" + Str(LanternStepsLeft) : EndIf
      EndIf
    EndIf
  EndIf

  FrontColor(RGB(255, 255, 255))
  Box(0, uiY, WinW, TileH * #UI_ROWS, RGB(0, 0, 0))

  Protected hudLine.s
  Protected msgLine.s
  Protected debugLine.s

  If DebugOverlay
    enemyCount = 0
    ForEach Objects()
      If Objects()\Alive And Objects()\Board = b And Objects()\Char = Asc("E")
        enemyCount + 1
      EndIf
    Next

      debugLine = "DBG  File:" + GetFilePart(World\FilePath) + "  Board:" + Str(b) + "/" + Str(BoardCount - 1) + "  Obj:" + Str(ListSize(Objects())) + "  Enemies:" + Str(enemyCount) + "  P:" + Str(PlayerX) + "," + Str(PlayerY) + "  Edit:" + Str(EditMode) + "  ST:" + SelfTestSummary

    If DebugWindowSizing
      ; Keep this short so it fits in 80 columns.
      Protected dbgInnerW.i, dbgInnerH.i
      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
        Protected crr.TWinRect
        GetClientRect_(WindowID(0), @crr)
        dbgInnerW = crr\right - crr\left
        dbgInnerH = crr\bottom - crr\top
      CompilerElse
        dbgInnerW = WindowWidth(0, #PB_Window_InnerCoordinate)
        dbgInnerH = WindowHeight(0, #PB_Window_InnerCoordinate)
      CompilerEndIf

      Protected scaleX.f = 1.0
      Protected scaleY.f = 1.0
      Protected pbInnerW.i = WindowWidth(0, #PB_Window_InnerCoordinate)
      Protected pbInnerH.i = WindowHeight(0, #PB_Window_InnerCoordinate)
      If pbInnerW > 0 And dbgInnerW > 0 : scaleX = dbgInnerW / pbInnerW : EndIf
      If pbInnerH > 0 And dbgInnerH > 0 : scaleY = dbgInnerH / pbInnerH : EndIf

      debugLine = "DBG Cli " + Str(dbgInnerW) + "x" + Str(dbgInnerH) + " Want " + Str(WinW) + "x" + Str(WinH) + " s " + StrF(scaleX, 2) + "," + StrF(scaleY, 2)
    Else
      Protected inv.s
      inv = FormatScriptItems(120)
      If inv <> ""
        debugLine + "  " + inv
      EndIf

      If SelfTestDetails <> ""
        debugLine + "  " + ReplaceString(SelfTestDetails, #LF$, " | ")
      EndIf
    EndIf
  EndIf

   If EditMode
      hudLine = "EDITOR  Board:" + Str(b) + "/" + Str(BoardCount - 1) + "  Brush:" + Chr(BrushChar) + "  Col:" + Str(BrushColor) + "  ([ ] change, C pick)  (F1 help, Shift+F1 board, F3 obj, Shift+F3 passage, F4 del, F6/F7 board, F8 new, F10 sound, Shift+F10 world, F11 !mode)"
      If DebugOverlay
        msgLine = debugLine
      Else
         If World\BangOneShot
           msgLine = "World:" + World\Name + "  ! markers: one-shot  " + status + fuelInfo
         Else
           msgLine = "World:" + World\Name + "  ! markers: repeat  " + status + fuelInfo
         EndIf
       EndIf
    Else

     Protected ck.s
     ck = FormatColorKeys(30)
     If ck <> "" : ck = "  CKeys:" + ck : EndIf
     hudLine = "PLAY  Board:" + Str(b) + "/" + Str(BoardCount - 1) + "  Score:" + Str(Score) + "  Keys:" + Str(Keys) + ck + "  HP:" + Str(Health) + "  (Shift run, F1 help, F2 edit, PgUp/PgDn world, R restart)"
    If DebugOverlay
      msgLine = debugLine
    Else
      msgLine = "World:" + World\Name + "  " + status + fuelInfo
    EndIf
  EndIf

  ; Draw wrapped UI area (up to #UI_ROWS lines total).
  Protected wrappedHud.s
  Protected wrappedMsg.s
  Protected uiText.s
  Protected uiLine.s
  Protected uiLineIndex.i
  Protected uiRow.i

  wrappedHud = WrapTextToCols(hudLine, #MAP_W)
  wrappedMsg = WrapTextToCols(msgLine, #MAP_W)

  ; Compose: HUD lines first, then message/debug lines.
  uiText = wrappedHud
  If wrappedMsg <> ""
    If uiText <> "" : uiText + #LF$ : EndIf
    uiText + wrappedMsg
  EndIf

  uiLineIndex = 1
  For uiRow = 0 To #UI_ROWS - 1
    uiLine = StringField(uiText, uiLineIndex, #LF$)
    If uiLine = "" And uiLineIndex > CountString(uiText, #LF$) + 1
      Break
    EndIf

    DrawText(0, uiY + uiRow * TileH, FitTextToCols(uiLine, #MAP_W))
    uiLineIndex + 1
  Next

  ; Death fade overlay (simple black step fade).
  If DeathPending And DeathFadeUntilMS > 0 And World\DeathFadeMS > 0
    fadeNow = ElapsedMilliseconds()
    If fadeNow < DeathFadeUntilMS
      fadeT = Clamp(DeathFadeUntilMS - fadeNow, 0, World\DeathFadeMS)
      fadeSteps = 12
      fadeStep = Clamp(fadeSteps - (fadeT * fadeSteps) / World\DeathFadeMS, 0, fadeSteps)
      If fadeStep > 0
        DrawingMode(#PB_2DDrawing_Default)
        fadeH = (WinH * fadeStep) / fadeSteps
        Box(0, 0, WinW, fadeH, RGB(0, 0, 0))
      EndIf
    EndIf
  EndIf

  StopDrawing()
  FlipBuffers()
EndProcedure

; IDE Options = PureBasic 6.30 beta 6 (Windows - x64)
; CursorPosition = 257
; FirstLine = 249
; Folding = -
; EnableXP
; DPIAware