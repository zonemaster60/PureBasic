EnableExplicit

DeclareModule Audio
  Declare.i Init()
  Declare.i Ready()
  Declare.i LoadManifest(path.s)
  Declare.s LastLoadMessage()
  Declare.i Play(name.s, loop.i = #False)
  Declare SetGroupVolume(groupName.s, volume.i)
  Declare.i GroupVolume(groupName.s)
  Declare Shutdown()
EndDeclareModule

Module Audio
  Structure Clip
    name.s
    filePath.s
    soundId.i
    groupName.s
  EndStructure

  Structure GroupState
    volume.i
  EndStructure

  Global g_ready.i = #False
  Global g_lastLoadMessage.s
  Global NewMap g_clips.Clip()
  Global NewMap g_groups.GroupState()

  Procedure.i Init()
    If g_ready
      ProcedureReturn #True
    EndIf

    If InitSound() = 0
      ProcedureReturn #False
    EndIf

    g_ready = #True
    ProcedureReturn #True
  EndProcedure

  Procedure.i Ready()
    ProcedureReturn g_ready
  EndProcedure

  Procedure LoadClip(name.s, filePath.s)
    Protected key.s = LCase(Trim(name))

    If key = "" Or filePath = ""
      ProcedureReturn
    EndIf

    g_clips(key)\name = name
    g_clips()\filePath = filePath
    g_clips()\soundId = 0
    If g_clips()\groupName = ""
      g_clips()\groupName = "master"
    EndIf

    If FileSize(filePath) > 0
      g_clips()\soundId = LoadSound(#PB_Any, filePath)
    EndIf
  EndProcedure

  Procedure.i LoadManifest(path.s)
    Protected json.i
    Protected root.i
    Protected groups.i
    Protected clips.i

    g_lastLoadMessage = ""
    ClearMap(g_clips())
    ClearMap(g_groups())
    g_groups("master")\volume = 100

    If Ready() = #False
      g_lastLoadMessage = "Audio system is not ready"
      ProcedureReturn #False
    EndIf

    If FileSize(path) <= 0
      g_lastLoadMessage = "Audio manifest missing or empty: " + path
      ProcedureReturn #False
    EndIf

    json = LoadJSON(#PB_Any, path)
    If json = 0
      g_lastLoadMessage = "Failed to parse audio manifest: " + path
      ProcedureReturn #False
    EndIf

    root = JSONValue(json)
    If root = 0 Or JSONType(root) <> #PB_JSON_Object
      FreeJSON(json)
      g_lastLoadMessage = "Audio manifest root must be an object: " + path
      ProcedureReturn #False
    EndIf

    groups = GetJSONMember(root, "groups")
    If groups And JSONType(groups) = #PB_JSON_Object And ExamineJSONMembers(groups)
      While NextJSONMember(groups)
        If JSONType(JSONMemberValue(groups)) = #PB_JSON_Number
          SetGroupVolume(JSONMemberKey(groups), GetJSONInteger(JSONMemberValue(groups)))
        EndIf
      Wend
    EndIf

    clips = GetJSONMember(root, "clips")
    If clips And JSONType(clips) = #PB_JSON_Object And ExamineJSONMembers(clips)
      While NextJSONMember(clips)
        If JSONType(JSONMemberValue(clips)) = #PB_JSON_String
          LoadClip(JSONMemberKey(clips), GetJSONString(JSONMemberValue(clips)))
        ElseIf JSONType(JSONMemberValue(clips)) = #PB_JSON_Object
          Protected clipObj = JSONMemberValue(clips)
          Protected pathValue = GetJSONMember(clipObj, "path")
          Protected groupValue = GetJSONMember(clipObj, "group")

          If pathValue And JSONType(pathValue) = #PB_JSON_String
            LoadClip(JSONMemberKey(clips), GetJSONString(pathValue))
            If groupValue And JSONType(groupValue) = #PB_JSON_String
              g_clips(LCase(JSONMemberKey(clips)))\groupName = LCase(GetJSONString(groupValue))
            EndIf
          EndIf
        EndIf
      Wend
    EndIf

    FreeJSON(json)
    ProcedureReturn #True
  EndProcedure

  Procedure.s LastLoadMessage()
    ProcedureReturn g_lastLoadMessage
  EndProcedure

  Procedure.i Play(name.s, loop.i = #False)
    Protected key.s = LCase(Trim(name))
    Protected groupVolume.i = 100

    If key = "" Or FindMapElement(g_clips(), key) = 0
      ProcedureReturn #False
    EndIf

    If g_clips()\soundId = 0
      ProcedureReturn #False
    EndIf

    If FindMapElement(g_groups(), g_clips()\groupName)
      groupVolume = g_groups()\volume
    EndIf

    SoundVolume(g_clips()\soundId, groupVolume)

    ProcedureReturn Bool(PlaySound(g_clips()\soundId, Bool(loop) * #PB_Sound_Loop))
  EndProcedure

  Procedure SetGroupVolume(groupName.s, volume.i)
    Protected key.s = LCase(Trim(groupName))

    If key = ""
      key = "master"
    EndIf

    If volume < 0
      volume = 0
    ElseIf volume > 100
      volume = 100
    EndIf

    g_groups(key)\volume = volume
  EndProcedure

  Procedure.i GroupVolume(groupName.s)
    Protected key.s = LCase(Trim(groupName))

    If key = ""
      key = "master"
    EndIf

    If FindMapElement(g_groups(), key)
      ProcedureReturn g_groups()\volume
    EndIf

    ProcedureReturn 100
  EndProcedure

  Procedure Shutdown()
    ResetMap(g_clips())
    While NextMapElement(g_clips())
      If g_clips()\soundId
        FreeSound(g_clips()\soundId)
      EndIf
    Wend
    ClearMap(g_clips())
    ClearMap(g_groups())
    g_lastLoadMessage = ""
    g_ready = #False
  EndProcedure
EndModule
