EnableExplicit

DeclareModule Camera
  Declare Init(viewWidth.i, viewHeight.i)
  Declare UpdateViewport(viewWidth.i, viewHeight.i)
  Declare SetBounds(worldWidth.f, worldHeight.f)
  Declare SetSmoothing(smoothing.f)
  Declare SetPosition(x.f, y.f)
  Declare CenterOn(worldX.f, worldY.f)
  Declare SetTargetCenter(worldX.f, worldY.f)
  Declare Update(dt.f)
  Declare.f X()
  Declare.f Y()
  Declare.f TargetX()
  Declare.f TargetY()
  Declare.f ViewWidth()
  Declare.f ViewHeight()
  Declare.f WorldToScreenX(worldX.f)
  Declare.f WorldToScreenY(worldY.f)
  Declare.f ScreenToWorldX(screenX.f)
  Declare.f ScreenToWorldY(screenY.f)
EndDeclareModule

Module Camera
  Global g_x.f = 0.0
  Global g_y.f = 0.0
  Global g_targetX.f = 0.0
  Global g_targetY.f = 0.0
  Global g_viewWidth.f = 1280.0
  Global g_viewHeight.f = 720.0
  Global g_worldWidth.f = 1280.0
  Global g_worldHeight.f = 720.0
  Global g_smoothing.f = 8.0

  Procedure.f ClampToRange(value.f, minValue.f, maxValue.f)
    If value < minValue
      ProcedureReturn minValue
    EndIf
    If value > maxValue
      ProcedureReturn maxValue
    EndIf

    ProcedureReturn value
  EndProcedure

  Procedure.f ClampCameraX(x.f)
    Protected maxX.f = g_worldWidth - g_viewWidth
    If maxX < 0.0
      maxX = 0.0
    EndIf

    ProcedureReturn ClampToRange(x, 0.0, maxX)
  EndProcedure

  Procedure.f ClampCameraY(y.f)
    Protected maxY.f = g_worldHeight - g_viewHeight
    If maxY < 0.0
      maxY = 0.0
    EndIf

    ProcedureReturn ClampToRange(y, 0.0, maxY)
  EndProcedure

  Procedure Init(viewWidth.i, viewHeight.i)
    UpdateViewport(viewWidth, viewHeight)
    SetBounds(viewWidth, viewHeight)
    g_x = 0.0
    g_y = 0.0
    g_targetX = 0.0
    g_targetY = 0.0
  EndProcedure

  Procedure UpdateViewport(viewWidth.i, viewHeight.i)
    If viewWidth > 0
      g_viewWidth = viewWidth
    EndIf
    If viewHeight > 0
      g_viewHeight = viewHeight
    EndIf

    g_x = ClampCameraX(g_x)
    g_y = ClampCameraY(g_y)
    g_targetX = ClampCameraX(g_targetX)
    g_targetY = ClampCameraY(g_targetY)
  EndProcedure

  Procedure SetBounds(worldWidth.f, worldHeight.f)
    If worldWidth > 0.0
      g_worldWidth = worldWidth
    Else
      g_worldWidth = g_viewWidth
    EndIf

    If worldHeight > 0.0
      g_worldHeight = worldHeight
    Else
      g_worldHeight = g_viewHeight
    EndIf

    g_x = ClampCameraX(g_x)
    g_y = ClampCameraY(g_y)
    g_targetX = ClampCameraX(g_targetX)
    g_targetY = ClampCameraY(g_targetY)
  EndProcedure

  Procedure SetSmoothing(smoothing.f)
    If smoothing < 0.0
      smoothing = 0.0
    EndIf

    g_smoothing = smoothing
  EndProcedure

  Procedure SetPosition(x.f, y.f)
    g_x = ClampCameraX(x)
    g_y = ClampCameraY(y)
    g_targetX = g_x
    g_targetY = g_y
  EndProcedure

  Procedure CenterOn(worldX.f, worldY.f)
    SetPosition(worldX - (g_viewWidth * 0.5), worldY - (g_viewHeight * 0.5))
  EndProcedure

  Procedure SetTargetCenter(worldX.f, worldY.f)
    g_targetX = ClampCameraX(worldX - (g_viewWidth * 0.5))
    g_targetY = ClampCameraY(worldY - (g_viewHeight * 0.5))
  EndProcedure

  Procedure Update(dt.f)
    Protected factor.f

    If dt <= 0.0
      ProcedureReturn
    EndIf

    If g_smoothing <= 0.0
      g_x = g_targetX
      g_y = g_targetY
      ProcedureReturn
    EndIf

    factor = dt * g_smoothing
    If factor > 1.0
      factor = 1.0
    EndIf

    g_x + (g_targetX - g_x) * factor
    g_y + (g_targetY - g_y) * factor
    g_x = ClampCameraX(g_x)
    g_y = ClampCameraY(g_y)
  EndProcedure

  Procedure.f X()
    ProcedureReturn g_x
  EndProcedure

  Procedure.f Y()
    ProcedureReturn g_y
  EndProcedure

  Procedure.f TargetX()
    ProcedureReturn g_targetX
  EndProcedure

  Procedure.f TargetY()
    ProcedureReturn g_targetY
  EndProcedure

  Procedure.f ViewWidth()
    ProcedureReturn g_viewWidth
  EndProcedure

  Procedure.f ViewHeight()
    ProcedureReturn g_viewHeight
  EndProcedure

  Procedure.f WorldToScreenX(worldX.f)
    ProcedureReturn worldX - g_x
  EndProcedure

  Procedure.f WorldToScreenY(worldY.f)
    ProcedureReturn worldY - g_y
  EndProcedure

  Procedure.f ScreenToWorldX(screenX.f)
    ProcedureReturn screenX + g_x
  EndProcedure

  Procedure.f ScreenToWorldY(screenY.f)
    ProcedureReturn screenY + g_y
  EndProcedure
EndModule
