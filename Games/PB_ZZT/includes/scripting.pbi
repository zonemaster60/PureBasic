;------------------------------------------------------------------------------
; Scripting engine (extracted from pbzt.pb)
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; GetScriptLineCount
; Purpose: Procedure: Get Script Line Count.
; Params:
;   Script.s
; Returns: Integer
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i GetScriptLineCount(Script.s)
  Protected cnt.i
  If Script = "" : ProcedureReturn 0 : EndIf

  cnt = CountString(Script, #LF$)
  If Right(Script, 1) <> #LF$ : cnt + 1 : EndIf
  ProcedureReturn cnt
EndProcedure

;------------------------------------------------------------------------------
; GetScriptLine
; Purpose: Procedure: Get Script Line.
; Params:
;   Script.s
;   LineIndex.i
; Returns: String
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.s GetScriptLine(Script.s, LineIndex.i)
  Protected i.i, start.i, pos.i

  If LineIndex < 0 : ProcedureReturn "" : EndIf

  start = 1
  For i = 0 To LineIndex - 1
    pos = FindString(Script, #LF$, start)
    If pos = 0 : ProcedureReturn "" : EndIf
    start = pos + 1
  Next

  pos = FindString(Script, #LF$, start)
  If pos = 0
    ProcedureReturn Mid(Script, start)
  EndIf

  ProcedureReturn Mid(Script, start, pos - start)
EndProcedure

;------------------------------------------------------------------------------
; FindLabelLine
; Purpose: Procedure: Find Label Line.
; Params:
;   Script.s
;   Label.s
; Returns: Integer
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i FindLabelLine(Script.s, Label.s)
  Protected i.i, cnt.i
  Protected line.s

  Label = UCase(Trim(Label))
  If Left(Label, 1) = ":" : Label = Mid(Label, 2) : EndIf

  cnt = GetScriptLineCount(Script)
  For i = 0 To cnt - 1
    line = Trim(GetScriptLine(Script, i))
    If Left(line, 1) = ":"
      If UCase(Trim(Mid(line, 2))) = Label
        ProcedureReturn i
      EndIf
    EndIf
  Next

  ProcedureReturn -1
EndProcedure

;------------------------------------------------------------------------------
; TriggerObjectLabel
; Purpose: Procedure: Trigger Object Label.
; Params:
;   ObjectId.i
;   Label.s
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b TriggerObjectLabel(ObjectId.i, Label.s)
  Protected lineIdx.i

  If SelectObjectById(ObjectId) = 0 : ProcedureReturn #False : EndIf

  lineIdx = FindLabelLine(Objects()\Script, Label)
  If lineIdx >= 0
    Objects()\IP = lineIdx + 1
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; PlayerAdjacentTo
; Purpose: Procedure: Player Adjacent To.
; Params:
;   x.i
;   y.i
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b PlayerAdjacentTo(x.i, y.i)
  If Abs(PlayerX - x) + Abs(PlayerY - y) = 1
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

;------------------------------------------------------------------------------
; ExecuteObjectCommand
; Purpose: Procedure: Execute Object Command.
; Params:
;   ObjectId.i
;   CmdLine.s
; Returns: Boolean
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.b ExecuteObjectCommand(ObjectId.i, CmdLine.s)
  Protected cmd.s, arg1.s, arg2.s, arg3.s
  Protected parts.i
  Protected n.i, x.i, y.i
  Protected flagName.s
  Protected itemName.s

  If SelectObjectById(ObjectId) = 0 : ProcedureReturn #False : EndIf

  CmdLine = Trim(CmdLine)
  If CmdLine = "" : ProcedureReturn #True : EndIf

  If Left(CmdLine, 1) <> "#"
    ; treat as say
    PlaySfx(#Sfx_Beep)
    SetStatus(CmdLine)
    ProcedureReturn #True
  EndIf

  CmdLine = Mid(CmdLine, 2)
  cmd = UCase(StringField(CmdLine, 1, " "))
  parts = CountString(CmdLine, " ") + 1

  Select cmd
    Case "SAY"
      PlaySfx(#Sfx_Beep)
      SetStatus(Trim(Mid(CmdLine, Len("SAY") + 2)), 3000)

    Case "SCROLL"
      ; ZZT-ish message box.
      OpenScrollDialog(Trim(Mid(CmdLine, Len("SCROLL") + 2)), Objects()\Name)

    Case "SETFUEL"
      ; #SETFUEL TORCH|LANTERN n
      arg1 = UCase(Trim(StringField(CmdLine, 2, " ")))
      n = Clamp(Val(Trim(StringField(CmdLine, 3, " "))), 0, 99999)
      Select arg1
        Case "TORCH"
          TorchStepsLeft = Clamp(n, 0, #TORCH_MAX_STEPS)
          ScriptItems("TORCH") = Bool(TorchStepsLeft > 0)
        Case "LANTERN"
          LanternStepsLeft = Clamp(n, 0, #LANTERN_MAX_STEPS)
          ScriptItems("LANTERN") = Bool(LanternStepsLeft > 0)
      EndSelect
      RebuildObjectOverlay()

    Case "IFFUEL"
      ; #IFFUEL TORCH|LANTERN n label
      arg1 = UCase(Trim(StringField(CmdLine, 2, " ")))
      arg2 = Trim(StringField(CmdLine, 3, " "))
      arg3 = Trim(StringField(CmdLine, 4, " "))
      n = Val(arg2)
      If n < 0 : n = 0 : EndIf
      If arg3 = "" : ProcedureReturn #True : EndIf
      Select arg1
        Case "TORCH"
          If TorchStepsLeft >= n : TriggerObjectLabel(ObjectId, arg3) : EndIf
        Case "LANTERN"
          If LanternStepsLeft >= n : TriggerObjectLabel(ObjectId, arg3) : EndIf
      EndSelect

    Case "GIVECKEY"
      ; #GIVECKEY 1|2|3|4 n
      ; NOTE: Colored key doors A/B/C/F correspond to key counts 1/2/3/4.
      arg1 = Trim(StringField(CmdLine, 2, " "))
      n = Val(Trim(StringField(CmdLine, 3, " ")))
      If n <= 0 : n = 1 : EndIf
      If arg1 <> ""
        AddColorKey(Left(arg1, 1), n)
      EndIf

    Case "TAKECKEY"
      ; #TAKECKEY 1|2|3|4 n
      arg1 = Trim(StringField(CmdLine, 2, " "))
      n = Val(Trim(StringField(CmdLine, 3, " ")))
      If n <= 0 : n = 1 : EndIf
      If arg1 <> ""
        AddColorKey(Left(arg1, 1), -n)
      EndIf

    Case "IFCKEY"
      ; #IFCKEY 1|2|3|4 n label
      arg1 = Trim(StringField(CmdLine, 2, " "))
      arg2 = Trim(StringField(CmdLine, 3, " "))
      arg3 = Trim(StringField(CmdLine, 4, " "))
      n = Val(arg2)
      If n < 0 : n = 0 : EndIf
      If arg1 <> "" And arg3 <> ""
        If GetColorKeyCount(Left(arg1, 1)) >= n
          TriggerObjectLabel(ObjectId, arg3)
        EndIf
      EndIf

    Case "GOTO"
      arg1 = Trim(StringField(CmdLine, 2, " "))
      If arg1 <> ""
        TriggerObjectLabel(ObjectId, arg1)
      EndIf

    Case "END"
      Objects()\IP = GetScriptLineCount(Objects()\Script)

    Case "WAIT"
      n = Val(Trim(StringField(CmdLine, 2, " ")))
      Objects()\Wait = Clamp(n, 0, 9999)

    Case "IFTOUCH"
      arg1 = Trim(StringField(CmdLine, 2, " "))
      If PlayerAdjacentTo(Objects()\X, Objects()\Y)
        TriggerObjectLabel(ObjectId, arg1)
      EndIf

    Case "IFCONTACT"
      arg1 = Trim(StringField(CmdLine, 2, " "))
      If PlayerX = Objects()\X And PlayerY = Objects()\Y
        TriggerObjectLabel(ObjectId, arg1)
      EndIf

    Case "IFRAND"
      arg1 = Trim(StringField(CmdLine, 2, " "))
      arg2 = Trim(StringField(CmdLine, 3, " "))
      n = Clamp(Val(arg1), 0, 100)
      If Random(99) < n
        TriggerObjectLabel(ObjectId, arg2)
      EndIf

    Case "IFFLAG", "IFNOTFLAG"
      ; #IFFLAG name label     (branches if flag name is ON)
      ; #IFNOTFLAG name label  (branches if flag name is OFF / missing)
      arg1 = Trim(StringField(CmdLine, 2, " "))
      arg2 = Trim(StringField(CmdLine, 3, " "))
      flagName = UCase(arg1)
      If flagName <> ""
        If FindMapElement(ScriptFlags(), flagName)
          n = Bool(ScriptFlags() <> 0)
        Else
          n = 0
        EndIf

        If cmd = "IFFLAG"
          If n <> 0 : TriggerObjectLabel(ObjectId, arg2) : EndIf
        Else
          If n = 0 : TriggerObjectLabel(ObjectId, arg2) : EndIf
        EndIf
      EndIf

    Case "SETFLAG", "CLEARFLAG", "TOGGLEFLAG"
      ; #SETFLAG name    (sets flag name to 1)
      ; #CLEARFLAG name  (sets flag name to 0)
      ; #TOGGLEFLAG name (flips 0<->1; missing becomes 1)
      arg1 = Trim(StringField(CmdLine, 2, " "))
      flagName = UCase(arg1)
      If flagName <> ""
        Select cmd
          Case "SETFLAG"
            ScriptFlags(flagName) = 1

          Case "CLEARFLAG"
            ScriptFlags(flagName) = 0

          Case "TOGGLEFLAG"
            If FindMapElement(ScriptFlags(), flagName)
              ScriptFlags() = Bool(ScriptFlags() = 0)
            Else
              ScriptFlags(flagName) = 1
            EndIf
        EndSelect
      EndIf

    Case "GIVEITEM"
      ; #GIVEITEM name [count]
      arg1 = Trim(StringField(CmdLine, 2, " "))
      arg2 = Trim(StringField(CmdLine, 3, " "))
      itemName = UCase(arg1)
      If itemName <> ""
        n = Val(arg2)
        If n <= 0 : n = 1 : EndIf
        ScriptItems(itemName) + n
      EndIf

    Case "TAKEITEM"
      ; #TAKEITEM name [count]
      arg1 = Trim(StringField(CmdLine, 2, " "))
      arg2 = Trim(StringField(CmdLine, 3, " "))
      itemName = UCase(arg1)
      If itemName <> ""
        n = Val(arg2)
        If n <= 0 : n = 1 : EndIf
        If FindMapElement(ScriptItems(), itemName)
          ScriptItems() - n
          If ScriptItems() < 0 : ScriptItems() = 0 : EndIf
        EndIf
      EndIf

    Case "IFITEM"
      ; #IFITEM name [count] label
      ; With 2 args:  #IFITEM name label        (count defaults to 1)
      ; With 3 args:  #IFITEM name count label
      arg1 = Trim(StringField(CmdLine, 2, " "))
      arg2 = Trim(StringField(CmdLine, 3, " "))
      arg3 = Trim(StringField(CmdLine, 4, " "))
      itemName = UCase(arg1)
      If itemName <> ""
        If arg3 = ""
          ; treat arg2 as label
          n = 1
          If FindMapElement(ScriptItems(), itemName)
            If ScriptItems() >= n
              TriggerObjectLabel(ObjectId, arg2)
            EndIf
          EndIf
        Else
          n = Val(arg2)
          If n <= 0 : n = 1 : EndIf
          If FindMapElement(ScriptItems(), itemName)
            If ScriptItems() >= n
              TriggerObjectLabel(ObjectId, arg3)
            EndIf
          EndIf
        EndIf
      EndIf

    Case "IFSCORE", "IFKEYS", "IFHEALTH"
      ; #IFSCORE n label  (branches if Score >= n)
      ; #IFKEYS  n label  (branches if Keys  >= n)
      ; #IFHEALTH n label (branches if Health >= n)
      arg1 = Trim(StringField(CmdLine, 2, " "))
      arg2 = Trim(StringField(CmdLine, 3, " "))
      n = Val(arg1)
      Select cmd
        Case "IFSCORE"  : If Score >= n  : TriggerObjectLabel(ObjectId, arg2) : EndIf
        Case "IFKEYS"   : If Keys >= n   : TriggerObjectLabel(ObjectId, arg2) : EndIf
        Case "IFHEALTH" : If Health >= n : TriggerObjectLabel(ObjectId, arg2) : EndIf
      EndSelect

    Case "GIVE"
      arg1 = UCase(Trim(StringField(CmdLine, 2, " ")))
      n = Val(Trim(StringField(CmdLine, 3, " ")))
      Select arg1
        Case "SCORE"  : Score + n
        Case "KEYS"   : Keys + n
        Case "HEALTH" : Health + n
      EndSelect

    Case "TAKE"
      arg1 = UCase(Trim(StringField(CmdLine, 2, " ")))
      n = Val(Trim(StringField(CmdLine, 3, " ")))
      Select arg1
        Case "SCORE"  : Score - n
        Case "KEYS"   : Keys - n
        Case "HEALTH" : Health - n
      EndSelect
      If Score < 0 : Score = 0 : EndIf
      If Keys < 0 : Keys = 0 : EndIf
      If Health < 0 : Health = 0 : EndIf

    Case "SET"
      x = Val(Trim(StringField(CmdLine, 2, " ")))
      y = Val(Trim(StringField(CmdLine, 3, " ")))
      arg3 = Trim(StringField(CmdLine, 4, " "))
      If arg3 <> ""
        SetCell(x, y, Asc(Left(arg3, 1)))
      EndIf

    Case "SETCOLOR"
      x = Val(Trim(StringField(CmdLine, 2, " ")))
      y = Val(Trim(StringField(CmdLine, 3, " ")))
      n = Val(Trim(StringField(CmdLine, 4, " ")))
      SetCellColor(x, y, n)

    Case "CHAR"
      arg1 = Trim(StringField(CmdLine, 2, " "))
      If arg1 <> ""
        Objects()\Char = Asc(Left(arg1, 1))
      EndIf

    Case "COLOR"
      n = Val(Trim(StringField(CmdLine, 2, " ")))
      Objects()\Color = Clamp(n, 0, 255)

    Case "SOLID"
      n = Val(Trim(StringField(CmdLine, 2, " ")))
      Objects()\Solid = Bool(n <> 0)

    Case "BOARD"
      n = Val(Trim(StringField(CmdLine, 2, " ")))
      If n >= 0 And n < BoardCount
        SwitchBoard(n, "")
      EndIf

    Case "WALK"
      arg1 = UCase(Trim(StringField(CmdLine, 2, " ")))
      x = Objects()\X
      y = Objects()\Y
      Select arg1
        Case "N" : y - 1
        Case "S" : y + 1
        Case "W" : x - 1
        Case "E" : x + 1
      EndSelect

      ; keep objects inside bounds
      If x >= 0 And y >= 0 And x < #MAP_W And y < #MAP_H
        If x <> PlayerX Or y <> PlayerY
          If Solid(GetCell(x, y)) = 0 And GetObjectIdAt(Objects()\Board, x, y) = 0
            Objects()\X = x
            Objects()\Y = y
          EndIf
        EndIf
      EndIf

    Case "EXITN", "EXITS", "EXITW", "EXITE"
      n = Val(Trim(StringField(CmdLine, 2, " ")))
      Select cmd
        Case "EXITN" : Boards(Objects()\Board)\ExitN = n
        Case "EXITS" : Boards(Objects()\Board)\ExitS = n
        Case "EXITW" : Boards(Objects()\Board)\ExitW = n
        Case "EXITE" : Boards(Objects()\Board)\ExitE = n
      EndSelect

    Default
      ; unknown cmd
      PlaySfx(#Sfx_Beep)
  EndSelect

  ProcedureReturn #True
EndProcedure

;------------------------------------------------------------------------------
; StepObject
; Purpose: Procedure: Step Object.
; Params:
;   ObjectId.i
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure StepObject(ObjectId.i)
  Protected steps.i
  Protected line.s
  Protected cnt.i

  If SelectObjectById(ObjectId) = 0 : ProcedureReturn : EndIf
  If Objects()\Alive = 0 : ProcedureReturn : EndIf

  If Objects()\Wait > 0
    Objects()\Wait - 1
    ProcedureReturn
  EndIf

  cnt = GetScriptLineCount(Objects()\Script)
  If cnt <= 0 : ProcedureReturn : EndIf

  ; guard: max commands per tick
  For steps = 1 To 6
    If Objects()\IP < 0 : Objects()\IP = 0 : EndIf
    If Objects()\IP >= cnt : ProcedureReturn : EndIf

    line = Trim(GetScriptLine(Objects()\Script, Objects()\IP))
    Objects()\IP + 1

    If line = "" : Continue : EndIf
    If Left(line, 1) = "'" : Continue : EndIf ; comment
    If Left(line, 1) = ":" : Continue : EndIf ; label line

    ExecuteObjectCommand(ObjectId, line)

    ; allow WAIT to yield
    If SelectObjectById(ObjectId)
      If Objects()\Wait > 0
        Break
      EndIf
    EndIf
  Next
EndProcedure

;------------------------------------------------------------------------------
; UpdateObjects
; Purpose: Procedure: Update Objects.
; Params: None
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure UpdateObjects()
  Protected b.i = CurBoard()

  ForEach Objects()
    If Objects()\Alive And Objects()\Board = b
      StepObject(Objects()\Id)
    EndIf
  Next
EndProcedure
