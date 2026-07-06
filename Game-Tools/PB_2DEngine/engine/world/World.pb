EnableExplicit

XIncludeFile "../core/Log.pb"
XIncludeFile "../gfx/Gfx.pb"
XIncludeFile "Camera.pb"

DeclareModule World
  Declare Init(scenePath.s = "")
  Declare Update(dt.f)
  Declare Render(alpha.f)
  Declare.i EntityCount()
  Declare.i SaveScene(path.s)
  Declare.i SpawnEntity(name.s, x.f, y.f, vx.f, vy.f, size.f, color.i)
  Declare.i SpawnEntitySprite(name.s, x.f, y.f, vx.f, vy.f, size.f, color.i, spritePath.s)
  Declare.i FindEntity(name.s)
  Declare.i PickEntityAt(worldX.f, worldY.f)
  Declare.i SelectEntity(entityId.i)
  Declare.i SelectedEntity()
  Declare.i GetEntityPosition(entityId.i, *outX.Float, *outY.Float)
  Declare.i SetEntityVelocity(entityId.i, vx.f, vy.f)
  Declare.i SetEntityPosition(entityId.i, x.f, y.f)
  Declare.i MoveEntityToward(entityId.i, targetX.f, targetY.f, speed.f)
  Declare.s EntityName(entityId.i)
  Declare Shutdown()
EndDeclareModule

Module World
  Structure Entity
    id.i
    name.s
    x.f
    y.f
    prevX.f
    prevY.f
    vx.f
    vy.f
    size.f
    color.i
    spritePath.s
    spriteId.i
  EndStructure

  Global g_initialized.i = #False
  Global g_timeSeconds.d = 0.0
  Global g_tickCount.i = 0
  Global g_nextEntityId.i = 1
  Global g_scenePath.s
  Global g_playerEntityId.i = 0
  Global g_selectedEntityId.i = 0
  Global g_fallbackSprite.i = 0
  Global g_worldWidth.f = 1280.0
  Global g_worldHeight.f = 720.0
  Global NewList g_entities.Entity()

  Declare.i AddEntity(name.s, x.f, y.f, vx.f, vy.f, size.f, color.i, spritePath.s = "")
  Declare.i FindEntityIndex(entityId.i)
  Declare.f ClampSize(size.f)
  Declare LoadSceneFromFile(scenePath.s)
  Declare.i EnsureEntitySprite(*entity.Entity)

  Procedure.i ParseColorValue(value)
    Protected text.s

    If value = 0
      ProcedureReturn RGB(255, 255, 255)
    EndIf

    Select JSONType(value)
      Case #PB_JSON_Number
        ProcedureReturn GetJSONInteger(value)
      Case #PB_JSON_String
        text = ReplaceString(UCase(GetJSONString(value)), "0X", "")
        ProcedureReturn Val("$" + text)
    EndSelect

    ProcedureReturn RGB(255, 255, 255)
  EndProcedure

  Procedure EnsureFallbackSprite()
    If g_fallbackSprite
      ProcedureReturn
    EndIf

    CompilerIf Not Defined(HEADLESS, #PB_Constant)
      g_fallbackSprite = CreateSprite(#PB_Any, 64, 64)
      If g_fallbackSprite And StartDrawing(SpriteOutput(g_fallbackSprite))
        Box(0, 0, 64, 64, RGBA(255, 255, 255, 0))
        Circle(32, 32, 30, RGB(255, 255, 255))
        StopDrawing()
      EndIf
    CompilerEndIf
  EndProcedure

  Procedure.i EnsureEntitySprite(*entity.Entity)
    If *entity = 0
      ProcedureReturn 0
    EndIf

    If *entity\spriteId
      ProcedureReturn *entity\spriteId
    EndIf

    If *entity\spritePath <> "" And FileSize(*entity\spritePath) > 0
      *entity\spriteId = LoadSprite(#PB_Any, *entity\spritePath)
    EndIf

    ProcedureReturn *entity\spriteId
  EndProcedure

  Procedure LoadSceneFromFile(scenePath.s)
    Protected json.i
    Protected root.i
    Protected entities.i
    Protected entry.i
    Protected index.i

    If FileSize(scenePath) <= 0
      ProcedureReturn
    EndIf

    json = LoadJSON(#PB_Any, scenePath)
    If json = 0
      Log::Warn("Failed to parse scene JSON: " + scenePath)
      ProcedureReturn
    EndIf

    root = JSONValue(json)
    If root And JSONType(root) = #PB_JSON_Object
      Protected worldConfig = GetJSONMember(root, "world")
      If worldConfig And JSONType(worldConfig) = #PB_JSON_Object
        Protected sceneWidthValue = GetJSONMember(worldConfig, "width")
        Protected sceneHeightValue = GetJSONMember(worldConfig, "height")
        Protected cameraConfig = GetJSONMember(worldConfig, "camera")

        If sceneWidthValue And JSONType(sceneWidthValue) = #PB_JSON_Number
          g_worldWidth = GetJSONDouble(sceneWidthValue)
        EndIf
        If sceneHeightValue And JSONType(sceneHeightValue) = #PB_JSON_Number
          g_worldHeight = GetJSONDouble(sceneHeightValue)
        EndIf

        Camera::SetBounds(g_worldWidth, g_worldHeight)

        If cameraConfig And JSONType(cameraConfig) = #PB_JSON_Object
          Protected smoothingValue = GetJSONMember(cameraConfig, "smoothing")
          If smoothingValue And JSONType(smoothingValue) = #PB_JSON_Number
            Camera::SetSmoothing(GetJSONDouble(smoothingValue))
          EndIf
        EndIf
      EndIf

      entities = GetJSONMember(root, "entities")
      If entities And JSONType(entities) = #PB_JSON_Array
        ClearList(g_entities())
        g_nextEntityId = 1
        g_playerEntityId = 0
        g_selectedEntityId = 0

        For index = 0 To JSONArraySize(entities) - 1
          entry = GetJSONElement(entities, index)
          If entry And JSONType(entry) = #PB_JSON_Object
            Protected name.s = "entity_" + Str(g_nextEntityId)
            Protected x.f = 0.0
            Protected y.f = 0.0
            Protected vx.f = 0.0
            Protected vy.f = 0.0
            Protected size.f = 16.0
            Protected color.i = RGB(255, 255, 255)
            Protected spritePath.s = ""

            name = GetJSONString(GetJSONMember(entry, "name"))
            x = GetJSONDouble(GetJSONMember(entry, "x"))
            y = GetJSONDouble(GetJSONMember(entry, "y"))
            vx = GetJSONDouble(GetJSONMember(entry, "vx"))
            vy = GetJSONDouble(GetJSONMember(entry, "vy"))
            size = GetJSONDouble(GetJSONMember(entry, "size"))
            color = ParseColorValue(GetJSONMember(entry, "color"))
            If GetJSONMember(entry, "spritePath") And JSONType(GetJSONMember(entry, "spritePath")) = #PB_JSON_String
              spritePath = GetJSONString(GetJSONMember(entry, "spritePath"))
            EndIf

            If name = ""
              name = "entity_" + Str(g_nextEntityId)
            EndIf

            Protected entityId.i = AddEntity(name, x, y, vx, vy, ClampSize(size), color, spritePath)
            If LCase(name) = "player"
              g_playerEntityId = entityId
            EndIf
          EndIf
        Next
      EndIf
    EndIf

    FreeJSON(json)
  EndProcedure

  Procedure.i AddEntity(name.s, x.f, y.f, vx.f, vy.f, size.f, color.i, spritePath.s = "")
    AddElement(g_entities())
    g_entities()\id = g_nextEntityId
    g_entities()\name = name
    g_entities()\x = x
    g_entities()\y = y
    g_entities()\prevX = x
    g_entities()\prevY = y
    g_entities()\vx = vx
    g_entities()\vy = vy
    g_entities()\size = size
    g_entities()\color = color
    g_entities()\spritePath = spritePath
    g_entities()\spriteId = 0
    g_nextEntityId + 1
    ProcedureReturn g_entities()\id
  EndProcedure

  Procedure.i FindEntityIndex(entityId.i)
    ForEach g_entities()
      If g_entities()\id = entityId
        ProcedureReturn #True
      EndIf
    Next

    ProcedureReturn #False
  EndProcedure

  Procedure.f ClampSize(size.f)
    If size < 4.0
      ProcedureReturn 4.0
    EndIf
    If size > 64.0
      ProcedureReturn 64.0
    EndIf

    ProcedureReturn size
  EndProcedure

  Procedure.f WorldWidth()
    ProcedureReturn g_worldWidth
  EndProcedure

  Procedure.f WorldHeight()
    ProcedureReturn g_worldHeight
  EndProcedure

  Procedure Init(scenePath.s = "")
    If g_initialized
      ProcedureReturn
    EndIf

    g_initialized = #True
    g_timeSeconds = 0.0
    g_tickCount = 0
    g_nextEntityId = 1
    g_scenePath = scenePath
    g_playerEntityId = 0
    g_selectedEntityId = 0
    If Gfx::Width() > 1280
      g_worldWidth = Gfx::Width()
    Else
      g_worldWidth = 1280.0
    EndIf
    If Gfx::Height() > 720
      g_worldHeight = Gfx::Height()
    Else
      g_worldHeight = 720.0
    EndIf
    ClearList(g_entities())

    EnsureFallbackSprite()
    Camera::SetBounds(g_worldWidth, g_worldHeight)
    Camera::SetSmoothing(8.0)

    AddEntity("player", 160.0, 120.0, 150.0, 110.0, 18.0, RGB(80, 180, 255))
    g_playerEntityId = 1
    AddEntity("npc_a", 540.0, 300.0, -120.0, 90.0, 24.0, RGB(255, 180, 80))
    AddEntity("npc_b", 940.0, 180.0, 70.0, 145.0, 14.0, RGB(120, 255, 140))

    If scenePath <> ""
      LoadSceneFromFile(scenePath)
    EndIf

    Log::Info("World initialized with " + Str(ListSize(g_entities())) + " entities")
  EndProcedure

  Procedure Update(dt.f)
    Protected worldWidth.f
    Protected worldHeight.f

    If g_initialized = #False
      ProcedureReturn
    EndIf

    worldWidth = WorldWidth()
    worldHeight = WorldHeight()

    g_timeSeconds + dt
    g_tickCount + 1

    If g_playerEntityId And FindEntityIndex(g_playerEntityId)
      Camera::SetTargetCenter(g_entities()\x, g_entities()\y)
    EndIf

    Camera::Update(dt)

    ForEach g_entities()
      g_entities()\prevX = g_entities()\x
      g_entities()\prevY = g_entities()\y

      g_entities()\x + g_entities()\vx * dt
      g_entities()\y + g_entities()\vy * dt

      If g_entities()\x < g_entities()\size
        g_entities()\x = g_entities()\size
        g_entities()\vx = Abs(g_entities()\vx)
      ElseIf g_entities()\x > worldWidth - g_entities()\size
        g_entities()\x = worldWidth - g_entities()\size
        g_entities()\vx = -Abs(g_entities()\vx)
      EndIf

      If g_entities()\y < g_entities()\size
        g_entities()\y = g_entities()\size
        g_entities()\vy = Abs(g_entities()\vy)
      ElseIf g_entities()\y > worldHeight - g_entities()\size
        g_entities()\y = worldHeight - g_entities()\size
        g_entities()\vy = -Abs(g_entities()\vy)
      EndIf
    Next
  EndProcedure

  Procedure Render(alpha.f)
    Protected drawX.f
    Protected drawY.f

    If g_initialized = #False
      ProcedureReturn
    EndIf

    CompilerIf Not Defined(HEADLESS, #PB_Constant)
      If Gfx::Headless() Or Gfx::Ready() = #False
        ProcedureReturn
      EndIf

        If StartDrawing(ScreenOutput())
          ForEach g_entities()
            drawX = Camera::WorldToScreenX(g_entities()\prevX + ((g_entities()\x - g_entities()\prevX) * alpha))
            drawY = Camera::WorldToScreenY(g_entities()\prevY + ((g_entities()\y - g_entities()\prevY) * alpha))

            Circle(drawX, drawY, g_entities()\size, g_entities()\color)
          Next
          StopDrawing()
        EndIf
    CompilerEndIf
  EndProcedure

  Procedure.i EntityCount()
    ProcedureReturn ListSize(g_entities())
  EndProcedure

  Procedure.i SpawnEntity(name.s, x.f, y.f, vx.f, vy.f, size.f, color.i)
    If g_initialized = #False
      ProcedureReturn 0
    EndIf

    ProcedureReturn AddEntity(name, x, y, vx, vy, ClampSize(size), color)
  EndProcedure

  Procedure.i SpawnEntitySprite(name.s, x.f, y.f, vx.f, vy.f, size.f, color.i, spritePath.s)
    If g_initialized = #False
      ProcedureReturn 0
    EndIf

    ProcedureReturn AddEntity(name, x, y, vx, vy, ClampSize(size), color, spritePath)
  EndProcedure

  Procedure.i SaveScene(path.s)
    Protected json.i = CreateJSON(#PB_Any)
    Protected root.i
    Protected worldObj.i
    Protected cameraObj.i
    Protected entitiesArray.i
    Protected entityObj.i

    If json = 0
      ProcedureReturn #False
    EndIf

    root = SetJSONObject(JSONValue(json))

    worldObj = SetJSONObject(AddJSONMember(root, "world"))
    SetJSONDouble(AddJSONMember(worldObj, "width"), g_worldWidth)
    SetJSONDouble(AddJSONMember(worldObj, "height"), g_worldHeight)
    cameraObj = SetJSONObject(AddJSONMember(worldObj, "camera"))
    SetJSONDouble(AddJSONMember(cameraObj, "smoothing"), 8.0)

    entitiesArray = SetJSONArray(AddJSONMember(root, "entities"))
    ForEach g_entities()
      entityObj = SetJSONObject(AddJSONElement(entitiesArray))
      SetJSONString(AddJSONMember(entityObj, "name"), g_entities()\name)
      SetJSONDouble(AddJSONMember(entityObj, "x"), g_entities()\x)
      SetJSONDouble(AddJSONMember(entityObj, "y"), g_entities()\y)
      SetJSONDouble(AddJSONMember(entityObj, "vx"), g_entities()\vx)
      SetJSONDouble(AddJSONMember(entityObj, "vy"), g_entities()\vy)
      SetJSONDouble(AddJSONMember(entityObj, "size"), g_entities()\size)
      SetJSONString(AddJSONMember(entityObj, "color"), "0x" + RSet(Hex(g_entities()\color), 6, "0"))
      If g_entities()\spritePath <> ""
        SetJSONString(AddJSONMember(entityObj, "spritePath"), g_entities()\spritePath)
      EndIf
    Next

    Protected ok.i = SaveJSON(json, path, #PB_JSON_PrettyPrint)
    FreeJSON(json)
    ProcedureReturn ok
  EndProcedure

  Procedure.i FindEntity(name.s)
    Protected key.s = LCase(Trim(name))

    If key = ""
      ProcedureReturn 0
    EndIf

    ForEach g_entities()
      If LCase(g_entities()\name) = key
        ProcedureReturn g_entities()\id
      EndIf
    Next

    ProcedureReturn 0
  EndProcedure

  Procedure.s EntityName(entityId.i)
    If FindEntityIndex(entityId)
      ProcedureReturn g_entities()\name
    EndIf

    ProcedureReturn ""
  EndProcedure

  Procedure.i PickEntityAt(worldX.f, worldY.f)
    Protected bestEntityId.i = 0
    Protected bestDistance.f = 999999.0
    Protected dx.f
    Protected dy.f
    Protected distance.f

    ForEach g_entities()
      dx = g_entities()\x - worldX
      dy = g_entities()\y - worldY
      distance = Sqr((dx * dx) + (dy * dy))
      If distance <= g_entities()\size And distance < bestDistance
        bestDistance = distance
        bestEntityId = g_entities()\id
      EndIf
    Next

    ProcedureReturn bestEntityId
  EndProcedure

  Procedure.i SelectEntity(entityId.i)
    If entityId = 0
      g_selectedEntityId = 0
      ProcedureReturn #True
    EndIf

    If FindEntityIndex(entityId)
      g_selectedEntityId = entityId
      ProcedureReturn #True
    EndIf

    ProcedureReturn #False
  EndProcedure

  Procedure.i SelectedEntity()
    ProcedureReturn g_selectedEntityId
  EndProcedure

  Procedure.i GetEntityPosition(entityId.i, *outX.Float, *outY.Float)
    If *outX = 0 Or *outY = 0
      ProcedureReturn #False
    EndIf

    If FindEntityIndex(entityId) = #False
      ProcedureReturn #False
    EndIf

    *outX\f = g_entities()\x
    *outY\f = g_entities()\y
    ProcedureReturn #True
  EndProcedure

  Procedure.i SetEntityPosition(entityId.i, x.f, y.f)
    If FindEntityIndex(entityId) = #False
      ProcedureReturn #False
    EndIf

    g_entities()\x = x
    g_entities()\y = y
    g_entities()\prevX = x
    g_entities()\prevY = y
    ProcedureReturn #True
  EndProcedure

  Procedure.i SetEntityVelocity(entityId.i, vx.f, vy.f)
    If FindEntityIndex(entityId) = #False
      ProcedureReturn #False
    EndIf

    g_entities()\vx = vx
    g_entities()\vy = vy
    ProcedureReturn #True
  EndProcedure

  Procedure.i MoveEntityToward(entityId.i, targetX.f, targetY.f, speed.f)
    Protected dx.f
    Protected dy.f
    Protected length.f

    If speed < 0.0
      speed = -speed
    EndIf

    If FindEntityIndex(entityId) = #False
      ProcedureReturn #False
    EndIf

    dx = targetX - g_entities()\x
    dy = targetY - g_entities()\y
    length = Sqr((dx * dx) + (dy * dy))

    If length <= 0.0001 Or speed = 0.0
      g_entities()\vx = 0.0
      g_entities()\vy = 0.0
      ProcedureReturn #True
    EndIf

    g_entities()\vx = (dx / length) * speed
    g_entities()\vy = (dy / length) * speed
    ProcedureReturn #True
  EndProcedure

  Procedure Shutdown()
    If g_initialized = #False
      ProcedureReturn
    EndIf

    Log::Info("World stats: ticks=" + Str(g_tickCount) + ", simulatedSeconds=" + StrD(g_timeSeconds, 3))
    ForEach g_entities()
      If g_entities()\spriteId
        FreeSprite(g_entities()\spriteId)
      EndIf
    Next
    ClearList(g_entities())
    If g_fallbackSprite
      FreeSprite(g_fallbackSprite)
      g_fallbackSprite = 0
    EndIf
    g_initialized = #False
    g_timeSeconds = 0.0
    g_tickCount = 0
    g_nextEntityId = 1
    g_playerEntityId = 0
    g_selectedEntityId = 0
    g_scenePath = ""
    Log::Info("World shut down")
  EndProcedure
EndModule
