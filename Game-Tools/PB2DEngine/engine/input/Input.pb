EnableExplicit

DeclareModule Input
  Enumeration Action
    #Action_Quit
    #Action_Left
    #Action_Right
    #Action_Up
    #Action_Down
  EndEnumeration

  Declare.i Init()
  Declare Poll()

  ; Configurable binding loader (v0.3)
  Declare.i LoadBindings(jsonFile.s)

  ; Low-level enum actions
  Declare.i ActionDown(action.i)
  Declare.i ActionPressed(action.i)
  Declare.i ActionReleased(action.i)

  ; UI helper
  Declare.s KeyName(key.i)

  ; Lua-facing string actions
  Declare.i DownName(actionName.s)
  Declare.i PressedName(actionName.s)
  Declare.i ReleasedName(actionName.s)

  ; UI helper
  Declare GetBindingDisplay(actionName.s, *outText)
EndDeclareModule

Module Input
  Structure Binding
    name.s
    keyPrimary.i
    keySecondary.i
  EndStructure

  Global NewMap g_bindings.Binding() ; name => binding

  ; Per-action state (for JSON-defined bindings too)
  Global NewMap g_downByName.i()
  Global NewMap g_prevByName.i()
  Global NewMap g_pressedByName.i()
  Global NewMap g_releasedByName.i()

  Global Dim g_actionDown.i(#Action_Down)
  Global Dim g_actionPrev.i(#Action_Down)
  Global Dim g_actionPressed.i(#Action_Down)
  Global Dim g_actionReleased.i(#Action_Down)

  Procedure AddBinding(name.s, keyPrimary.i, keySecondary.i)
    Protected key.s = LCase(name)

    g_bindings(key)\name = name
    g_bindings()\keyPrimary = keyPrimary
    g_bindings()\keySecondary = keySecondary

    ; Ensure state maps contain this name
    If FindMapElement(g_downByName(), key) = 0
      g_downByName(key) = #False
    EndIf
    If FindMapElement(g_prevByName(), key) = 0
      g_prevByName(key) = #False
    EndIf
    If FindMapElement(g_pressedByName(), key) = 0
      g_pressedByName(key) = #False
    EndIf
    If FindMapElement(g_releasedByName(), key) = 0
      g_releasedByName(key) = #False
    EndIf
  EndProcedure

  Procedure ResetDefaultBindings()
    ClearMap(g_bindings())
    ClearMap(g_downByName())
    ClearMap(g_prevByName())
    ClearMap(g_pressedByName())
    ClearMap(g_releasedByName())

    AddBinding("quit", #PB_Key_Escape, 0)
    AddBinding("left", #PB_Key_A, #PB_Key_Left)
    AddBinding("right", #PB_Key_D, #PB_Key_Right)
    AddBinding("up", #PB_Key_W, #PB_Key_Up)
    AddBinding("down", #PB_Key_S, #PB_Key_Down)
  EndProcedure

  Procedure.i Init()
    ; keyboard/mouse init handled in Gfx::Init
    ResetDefaultBindings()
    ProcedureReturn #True
  EndProcedure

  Procedure Poll()
    Protected i

    For i = 0 To #Action_Down
      g_actionPrev(i) = g_actionDown(i)
    Next

    ; Snapshot previous state for all named bindings
    ResetMap(g_downByName())
    While NextMapElement(g_downByName())
      g_prevByName(MapKey(g_downByName())) = g_downByName()
    Wend

    CompilerIf Defined(HEADLESS, #PB_Constant)
      FillMemory(@g_actionDown(), (ArraySize(g_actionDown()) + 1) * SizeOf(Integer), 0)

      ; In headless mode, treat all named bindings as up
      ResetMap(g_downByName())
      While NextMapElement(g_downByName())
        g_downByName() = #False
      Wend
    CompilerElse
      ExamineKeyboard()

      g_actionDown(#Action_Quit) = Bool(KeyboardPushed(#PB_Key_Escape))
      g_actionDown(#Action_Left) = Bool(KeyboardPushed(#PB_Key_A) Or KeyboardPushed(#PB_Key_Left))
      g_actionDown(#Action_Right) = Bool(KeyboardPushed(#PB_Key_D) Or KeyboardPushed(#PB_Key_Right))
      g_actionDown(#Action_Up) = Bool(KeyboardPushed(#PB_Key_W) Or KeyboardPushed(#PB_Key_Up))
      g_actionDown(#Action_Down) = Bool(KeyboardPushed(#PB_Key_S) Or KeyboardPushed(#PB_Key_Down))

      ; Compute down-state for all named bindings
      ResetMap(g_bindings())
      While NextMapElement(g_bindings())
        g_downByName(MapKey(g_bindings())) = Bool(KeyboardPushed(g_bindings()\keyPrimary) Or KeyboardPushed(g_bindings()\keySecondary))
      Wend
    CompilerEndIf

    For i = 0 To #Action_Down
      g_actionPressed(i) = Bool(g_actionDown(i) And Not g_actionPrev(i))
      g_actionReleased(i) = Bool((Not g_actionDown(i)) And g_actionPrev(i))
    Next

    ; Compute pressed/released for all named bindings
    ResetMap(g_downByName())
    While NextMapElement(g_downByName())
      Protected key.s = MapKey(g_downByName())
      g_pressedByName(key) = Bool(g_downByName() And Not g_prevByName(key))
      g_releasedByName(key) = Bool((Not g_downByName()) And g_prevByName(key))
    Wend
  EndProcedure

  Procedure.i ParseKeyString(s.s)
    Protected t.s = Trim(s)

    If t = ""
      ProcedureReturn 0
    EndIf

     ; Numeric keycode ("65")
     If FindString(t, "#", 1) = 0
       If Val(t) > 0
         ProcedureReturn Val(t)
       EndIf
     EndIf

    t = UCase(t)

    ; Supports a small subset of "#PB_Key_*" names.
    Select t
      Case "#PB_KEY_LEFT"
        ProcedureReturn #PB_Key_Left
      Case "#PB_KEY_RIGHT"
        ProcedureReturn #PB_Key_Right
      Case "#PB_KEY_UP"
        ProcedureReturn #PB_Key_Up
      Case "#PB_KEY_DOWN"
        ProcedureReturn #PB_Key_Down

      Case "#PB_KEY_ESCAPE"
        ProcedureReturn #PB_Key_Escape
      Case "#PB_KEY_SPACE"
        ProcedureReturn #PB_Key_Space
      Case "#PB_KEY_RETURN", "#PB_KEY_ENTER"
        ProcedureReturn #PB_Key_Return
      Case "#PB_KEY_TAB"
        ProcedureReturn #PB_Key_Tab

      Case "#PB_KEY_LEFTSHIFT"
        ProcedureReturn #PB_Key_LeftShift
      Case "#PB_KEY_RIGHTSHIFT"
        ProcedureReturn #PB_Key_RightShift

      Case "#PB_KEY_LEFTCONTROL"
        ProcedureReturn #PB_Key_LeftControl
      Case "#PB_KEY_RIGHTCONTROL"
        ProcedureReturn #PB_Key_RightControl

      Case "#PB_KEY_A"
        ProcedureReturn #PB_Key_A
      Case "#PB_KEY_B"
        ProcedureReturn #PB_Key_B
      Case "#PB_KEY_C"
        ProcedureReturn #PB_Key_C
      Case "#PB_KEY_D"
        ProcedureReturn #PB_Key_D
      Case "#PB_KEY_E"
        ProcedureReturn #PB_Key_E
      Case "#PB_KEY_F"
        ProcedureReturn #PB_Key_F
      Case "#PB_KEY_G"
        ProcedureReturn #PB_Key_G
      Case "#PB_KEY_H"
        ProcedureReturn #PB_Key_H
      Case "#PB_KEY_I"
        ProcedureReturn #PB_Key_I
      Case "#PB_KEY_J"
        ProcedureReturn #PB_Key_J
      Case "#PB_KEY_K"
        ProcedureReturn #PB_Key_K
      Case "#PB_KEY_L"
        ProcedureReturn #PB_Key_L
      Case "#PB_KEY_M"
        ProcedureReturn #PB_Key_M
      Case "#PB_KEY_N"
        ProcedureReturn #PB_Key_N
      Case "#PB_KEY_O"
        ProcedureReturn #PB_Key_O
      Case "#PB_KEY_P"
        ProcedureReturn #PB_Key_P
      Case "#PB_KEY_Q"
        ProcedureReturn #PB_Key_Q
      Case "#PB_KEY_R"
        ProcedureReturn #PB_Key_R
      Case "#PB_KEY_S"
        ProcedureReturn #PB_Key_S
      Case "#PB_KEY_T"
        ProcedureReturn #PB_Key_T
      Case "#PB_KEY_U"
        ProcedureReturn #PB_Key_U
      Case "#PB_KEY_V"
        ProcedureReturn #PB_Key_V
      Case "#PB_KEY_W"
        ProcedureReturn #PB_Key_W
      Case "#PB_KEY_X"
        ProcedureReturn #PB_Key_X
      Case "#PB_KEY_Y"
        ProcedureReturn #PB_Key_Y
      Case "#PB_KEY_Z"
        ProcedureReturn #PB_Key_Z

      Case "#PB_KEY_0"
        ProcedureReturn #PB_Key_0
      Case "#PB_KEY_1"
        ProcedureReturn #PB_Key_1
      Case "#PB_KEY_2"
        ProcedureReturn #PB_Key_2
      Case "#PB_KEY_3"
        ProcedureReturn #PB_Key_3
      Case "#PB_KEY_4"
        ProcedureReturn #PB_Key_4
      Case "#PB_KEY_5"
        ProcedureReturn #PB_Key_5
      Case "#PB_KEY_6"
        ProcedureReturn #PB_Key_6
      Case "#PB_KEY_7"
        ProcedureReturn #PB_Key_7
      Case "#PB_KEY_8"
        ProcedureReturn #PB_Key_8
      Case "#PB_KEY_9"
        ProcedureReturn #PB_Key_9
    EndSelect

    ; Letter key (e.g. "#PB_KEY_K")
    If Left(t, 8) = "#PB_KEY_" And Len(t) = 9
      Protected ch.s = Mid(t, 9, 1)
      If ch >= "A" And ch <= "Z"
        ProcedureReturn ParseKeyString("#PB_KEY_" + ch)
      EndIf
      If ch >= "0" And ch <= "9"
        ProcedureReturn ParseKeyString("#PB_KEY_" + ch)
      EndIf
    EndIf

    ProcedureReturn 0
  EndProcedure

  Procedure.i LoadBindings(jsonFile.s)
    If FileSize(jsonFile) <= 0
      ProcedureReturn #False
    EndIf

    Protected json = LoadJSON(#PB_Any, jsonFile)
    If json = 0
      ProcedureReturn #False
    EndIf

    Protected root = JSONValue(json)
    If root = 0
      FreeJSON(json)
      ProcedureReturn #False
    EndIf

    ; Expected format:
    ; {
    ;   "actions": {
    ;     "left":  {"keys": ["#PB_Key_A", "#PB_Key_Left"]},
    ;     "jump":  {"keys": ["#PB_Key_Space"]}
    ;   }
    ; }

    Protected actions = GetJSONMember(root, "actions")
    If actions = 0 Or JSONType(actions) <> #PB_JSON_Object
      FreeJSON(json)
      ProcedureReturn #False
    EndIf

    ClearMap(g_bindings())
    ClearMap(g_downByName())
    ClearMap(g_prevByName())
    ClearMap(g_pressedByName())
    ClearMap(g_releasedByName())
 
    ; PureBasic doesn't expose direct member enumeration for JSON objects,

    ; so we use ExamineJSONMembers().
    If ExamineJSONMembers(actions)
      While NextJSONMember(actions)
        Protected name.s = JSONMemberKey(actions)
        Protected actionObj = JSONMemberValue(actions)
        If actionObj And JSONType(actionObj) = #PB_JSON_Object
          Protected keysVal = GetJSONMember(actionObj, "keys")
          Protected k1.i = 0
          Protected k2.i = 0

          If keysVal And JSONType(keysVal) = #PB_JSON_Array
            If JSONArraySize(keysVal) > 0
              Protected s1.s = GetJSONString(GetJSONElement(keysVal, 0))
              k1 = ParseKeyString(s1)
            EndIf
            If JSONArraySize(keysVal) > 1
              Protected s2.s = GetJSONString(GetJSONElement(keysVal, 1))
              k2 = ParseKeyString(s2)
            EndIf
          EndIf

          AddBinding(name, k1, k2)
        EndIf
      Wend
    EndIf

    FreeJSON(json)
    ProcedureReturn #True
  EndProcedure

  Procedure.i ActionDown(action.i)
    If action < 0 Or action > #Action_Down
      ProcedureReturn #False
    EndIf
    ProcedureReturn g_actionDown(action)
  EndProcedure

  Procedure.i ActionPressed(action.i)
    If action < 0 Or action > #Action_Down
      ProcedureReturn #False
    EndIf
    ProcedureReturn g_actionPressed(action)
  EndProcedure

  Procedure.i ActionReleased(action.i)
    If action < 0 Or action > #Action_Down
      ProcedureReturn #False
    EndIf
    ProcedureReturn g_actionReleased(action)
  EndProcedure

  Procedure.i IsKeyDown(key.i)
    If key = 0
      ProcedureReturn #False
    EndIf
    ProcedureReturn Bool(KeyboardPushed(key))
  EndProcedure

  Procedure.s KeyName(key.i)
    Select key
      Case 0
        ProcedureReturn ""

      Case #PB_Key_Left
        ProcedureReturn "Left"
      Case #PB_Key_Right
        ProcedureReturn "Right"
      Case #PB_Key_Up
        ProcedureReturn "Up"
      Case #PB_Key_Down
        ProcedureReturn "Down"

      Case #PB_Key_Escape
        ProcedureReturn "Esc"
      Case #PB_Key_Space
        ProcedureReturn "Space"
      Case #PB_Key_LeftShift, #PB_Key_RightShift
        ProcedureReturn "Shift"
       Case #PB_Key_LeftControl, #PB_Key_RightControl, 17
         ProcedureReturn "Ctrl"

      Case #PB_Key_Return
        ProcedureReturn "Enter"
      Case #PB_Key_Tab
        ProcedureReturn "Tab"

      Case #PB_Key_A To #PB_Key_Z
        ProcedureReturn Chr(Asc("A") + (key - #PB_Key_A))
      Case #PB_Key_0 To #PB_Key_9
        ProcedureReturn Chr(Asc("0") + (key - #PB_Key_0))
    EndSelect

    If key >= 32 And key <= 126
      ProcedureReturn Chr(key)
    EndIf

    ProcedureReturn "Key" + Str(key)
  EndProcedure

  Procedure.i DownName(actionName.s)
    Protected key.s = LCase(actionName)

    If FindMapElement(g_downByName(), key) = 0
      ProcedureReturn #False
    EndIf

    ProcedureReturn g_downByName()
  EndProcedure

  Procedure.i PressedName(actionName.s)
    Protected key.s = LCase(actionName)

    If FindMapElement(g_pressedByName(), key) = 0
      ProcedureReturn #False
    EndIf

    ProcedureReturn g_pressedByName()
  EndProcedure

  Procedure.i ReleasedName(actionName.s)
    Protected key.s = LCase(actionName)

    If FindMapElement(g_releasedByName(), key) = 0
      ProcedureReturn #False
    EndIf

    ProcedureReturn g_releasedByName()
  EndProcedure

  Procedure GetBindingDisplay(actionName.s, *outText)
    If *outText = 0
      ProcedureReturn
    EndIf

    Protected key.s = LCase(actionName)
    If FindMapElement(g_bindings(), key) = 0
      PokeS(*outText, "", -1, #PB_Unicode)
      ProcedureReturn
    EndIf

    Protected k1.s = KeyName(g_bindings()\keyPrimary)
    Protected k2.s = KeyName(g_bindings()\keySecondary)

    Protected t.s
    If k1 <> "" And k2 <> ""
      t = g_bindings()\name + ": " + k1 + " / " + k2
    ElseIf k1 <> ""
      t = g_bindings()\name + ": " + k1
    ElseIf k2 <> ""
      t = g_bindings()\name + ": " + k2
    Else
      t = g_bindings()\name + ": (unbound)"
    EndIf

    PokeS(*outText, t, -1, #PB_Unicode)
  EndProcedure
EndModule

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 159
; FirstLine = 451
; Folding = ----
; EnableXP
; DPIAware