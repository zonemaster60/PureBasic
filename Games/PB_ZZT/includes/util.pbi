;------------------------------------------------------------------------------
; Utility helpers (extracted from pbzt.pb)
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; Clamp
; Purpose: Clamp an integer to a min/max range.
; Params:
;   Value.i
;   Min.i
;   Max.i
; Returns: Integer
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i Clamp(Value.i, Min.i, Max.i)
  If Value < Min : ProcedureReturn Min : EndIf
  If Value > Max : ProcedureReturn Max : EndIf
  ProcedureReturn Value
EndProcedure

;------------------------------------------------------------------------------
; SignI
; Purpose: Return the sign of an integer (-1/0/1).
; Params:
;   Value.i
; Returns: Integer
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i SignI(Value.i)
  If Value < 0 : ProcedureReturn -1 : EndIf
  If Value > 0 : ProcedureReturn 1 : EndIf
  ProcedureReturn 0
EndProcedure

Structure TWinRect
  left.l
  top.l
  right.l
  bottom.l
EndStructure

;------------------------------------------------------------------------------
; ResizeWindowClient
; Purpose: Resize a window to match a target client area.
; Params:
;   WindowNum.i
;   ClientW.i
;   ClientH.i
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure ResizeWindowClient(WindowNum.i, ClientW.i, ClientH.i)
  Protected outerW.i, outerH.i
  Protected innerW.i, innerH.i
  Protected dw.i, dh.i
  Protected i.i

  ; Adjust outer size so the drawable client area matches.
  ; On Windows with DPI scaling, PureBasic window sizes can be in scaled units while
  ; the client rect from WinAPI is in physical pixels. We compensate by computing a
  ; scale factor and doing ResizeWindow() in PB's units.

  For i = 0 To 3
    CompilerIf #PB_Compiler_OS = #PB_OS_Windows
      Protected hwnd.i = WindowID(WindowNum)
      Protected cr.TWinRect
      Protected apiInnerW.i, apiInnerH.i
      Protected pbOuterW.i, pbOuterH.i
      Protected pbInnerW.i, pbInnerH.i
      Protected scaleX.f, scaleY.f
      Protected wantInnerW.i, wantInnerH.i

      GetClientRect_(hwnd, @cr)
      apiInnerW = cr\right - cr\left
      apiInnerH = cr\bottom - cr\top

      pbOuterW = WindowWidth(WindowNum)
      pbOuterH = WindowHeight(WindowNum)
      pbInnerW = WindowWidth(WindowNum, #PB_Window_InnerCoordinate)
      pbInnerH = WindowHeight(WindowNum, #PB_Window_InnerCoordinate)

      scaleX = 1.0 : scaleY = 1.0
      If pbInnerW > 0 And apiInnerW > 0 : scaleX = apiInnerW / pbInnerW : EndIf
      If pbInnerH > 0 And apiInnerH > 0 : scaleY = apiInnerH / pbInnerH : EndIf

      wantInnerW = Int(ClientW / scaleX)
      wantInnerH = Int(ClientH / scaleY)

      dw = wantInnerW - pbInnerW
      dh = wantInnerH - pbInnerH
      If dw = 0 And dh = 0
        Break
      EndIf

      ResizeWindow(WindowNum, #PB_Ignore, #PB_Ignore, pbOuterW + dw, pbOuterH + dh)
    CompilerElse
      outerW = WindowWidth(WindowNum)
      outerH = WindowHeight(WindowNum)
      innerW = WindowWidth(WindowNum, #PB_Window_InnerCoordinate)
      innerH = WindowHeight(WindowNum, #PB_Window_InnerCoordinate)

      dw = ClientW - innerW
      dh = ClientH - innerH
      If dw = 0 And dh = 0
        Break
      EndIf

      ResizeWindow(WindowNum, #PB_Ignore, #PB_Ignore, outerW + dw, outerH + dh)
    CompilerEndIf
  Next
EndProcedure

;------------------------------------------------------------------------------
; ReadKeyValueLine
; Purpose: Parse one KEY=VALUE line.
;------------------------------------------------------------------------------

Procedure ReadKeyValueLine(Line.s, *OutKey.String, *OutVal.String)
  Protected eq.i

  If *OutKey = 0 Or *OutVal = 0 : ProcedureReturn : EndIf

  *OutKey\s = ""
  *OutVal\s = ""

  Line = Trim(Line)
  If Line = "" : ProcedureReturn : EndIf

  eq = FindString(Line, "=", 1)
  If eq <= 0 : ProcedureReturn : EndIf

  *OutKey\s = UCase(Trim(Left(Line, eq - 1)))
  *OutVal\s = Trim(Mid(Line, eq + 1))
EndProcedure

;------------------------------------------------------------------------------
; ReadHexNibbleChar
; Purpose: Parse one hex digit ('0'..'9','A'..'F') to 0..15.
;------------------------------------------------------------------------------

Procedure.a ReadHexNibbleChar(Ch.s)
  If Ch = "" : ProcedureReturn 0 : EndIf

  Protected c.i = Asc(UCase(Left(Ch, 1)))
  If c >= Asc("0") And c <= Asc("9")
    ProcedureReturn c - Asc("0")
  EndIf
  If c >= Asc("A") And c <= Asc("F")
    ProcedureReturn 10 + (c - Asc("A"))
  EndIf

  ProcedureReturn 0
EndProcedure
