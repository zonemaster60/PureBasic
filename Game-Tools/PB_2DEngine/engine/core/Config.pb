EnableExplicit

DeclareModule Config
  Declare Reset()
  Declare.i Load(path.s)
  Declare.s LastLoadMessage()
  Declare.s Title()
  Declare.i Width()
  Declare.i Height()
  Declare.i TargetFps()
  Declare.s InputBindingsPath()
  Declare.s ScriptPath()
  Declare.s ScenePath()
  Declare.s AudioManifestPath()
EndDeclareModule

Module Config
  Structure Settings
    title.s
    width.i
    height.i
    targetFps.i
    inputBindingsPath.s
    scriptPath.s
    scenePath.s
    audioManifestPath.s
  EndStructure

  Global g_settings.Settings
  Global g_lastLoadMessage.s

  Procedure.i ClampIntMin(value.i, minValue.i)
    If value < minValue
      ProcedureReturn minValue
    EndIf

    ProcedureReturn value
  EndProcedure

  Procedure Reset()
    g_settings\title = "PB_2DEngine"
    g_settings\width = 1280
    g_settings\height = 720
    g_settings\targetFps = 60
    g_settings\inputBindingsPath = "game/input.json"
    g_settings\scriptPath = "game/main.lua"
    g_settings\scenePath = "game/scene.json"
    g_settings\audioManifestPath = "game/audio.json"
    g_lastLoadMessage = ""
  EndProcedure

  Procedure.i ReadIntegerMember(root, name.s, defaultValue.i, minValue.i)
    Protected value = GetJSONMember(root, name)

    If value = 0
      ProcedureReturn defaultValue
    EndIf

    Select JSONType(value)
      Case #PB_JSON_Number
        ProcedureReturn ClampIntMin(GetJSONInteger(value), minValue)
      Case #PB_JSON_String
        ProcedureReturn ClampIntMin(Val(GetJSONString(value)), minValue)
    EndSelect

    ProcedureReturn defaultValue
  EndProcedure

  Procedure.s ReadStringMember(root, name.s, defaultValue.s)
    Protected value = GetJSONMember(root, name)

    If value And JSONType(value) = #PB_JSON_String
      ProcedureReturn GetJSONString(value)
    EndIf

    ProcedureReturn defaultValue
  EndProcedure

  Procedure.i Load(path.s)
    Protected json.i
    Protected root.i

    Reset()

    If FileSize(path) <= 0
      g_lastLoadMessage = "Config file missing or empty: " + path
      ProcedureReturn #False
    EndIf

    json = LoadJSON(#PB_Any, path)
    If json = 0
      g_lastLoadMessage = "Failed to parse config JSON: " + path
      ProcedureReturn #False
    EndIf

    root = JSONValue(json)
    If root = 0 Or JSONType(root) <> #PB_JSON_Object
      FreeJSON(json)
      g_lastLoadMessage = "Config root must be an object: " + path
      ProcedureReturn #False
    EndIf

    g_settings\title = ReadStringMember(root, "title", g_settings\title)
    g_settings\width = ReadIntegerMember(root, "width", g_settings\width, 1)
    g_settings\height = ReadIntegerMember(root, "height", g_settings\height, 1)
    g_settings\targetFps = ReadIntegerMember(root, "targetFps", g_settings\targetFps, 1)
    g_settings\inputBindingsPath = ReadStringMember(root, "inputBindingsPath", g_settings\inputBindingsPath)
    g_settings\scriptPath = ReadStringMember(root, "scriptPath", g_settings\scriptPath)
    g_settings\scenePath = ReadStringMember(root, "scenePath", g_settings\scenePath)
    g_settings\audioManifestPath = ReadStringMember(root, "audioManifestPath", g_settings\audioManifestPath)

    FreeJSON(json)
    ProcedureReturn #True
  EndProcedure

  Procedure.s LastLoadMessage()
    ProcedureReturn g_lastLoadMessage
  EndProcedure

  Procedure.s Title()
    ProcedureReturn g_settings\title
  EndProcedure

  Procedure.i Width()
    ProcedureReturn g_settings\width
  EndProcedure

  Procedure.i Height()
    ProcedureReturn g_settings\height
  EndProcedure

  Procedure.i TargetFps()
    ProcedureReturn g_settings\targetFps
  EndProcedure

  Procedure.s InputBindingsPath()
    ProcedureReturn g_settings\inputBindingsPath
  EndProcedure

  Procedure.s ScriptPath()
    ProcedureReturn g_settings\scriptPath
  EndProcedure

  Procedure.s ScenePath()
    ProcedureReturn g_settings\scenePath
  EndProcedure

  Procedure.s AudioManifestPath()
    ProcedureReturn g_settings\audioManifestPath
  EndProcedure

  Reset()
EndModule
