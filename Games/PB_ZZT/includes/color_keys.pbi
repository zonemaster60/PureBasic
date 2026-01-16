;------------------------------------------------------------------------------
; Colored key helpers (extracted from pbzt.pb)
;------------------------------------------------------------------------------

;------------------------------------------------------------------------------
; AddColorKey
; Purpose: Procedure: Add Color Key.
; Params:
;   KeyChar.s
;   Amount.i
; Returns: None
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure AddColorKey(KeyChar.s, Amount.i)
  Protected k.s = UCase(Left(KeyChar, 1))
  Protected n.i = Amount
  If k = "" Or n = 0 : ProcedureReturn : EndIf

  If FindMapElement(ColorKeys(), k)
    ColorKeys() + n
  Else
    AddMapElement(ColorKeys(), k)
    ColorKeys() = n
  EndIf

  If ColorKeys() < 0 : ColorKeys() = 0 : EndIf
EndProcedure

;------------------------------------------------------------------------------
; GetColorKeyCount
; Purpose: Procedure: Get Color Key Count.
; Params:
;   KeyChar.s
; Returns: Integer
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.i GetColorKeyCount(KeyChar.s)
  Protected k.s = UCase(Left(KeyChar, 1))
  If k = "" : ProcedureReturn 0 : EndIf
  If FindMapElement(ColorKeys(), k)
    ProcedureReturn ColorKeys()
  EndIf
  ProcedureReturn 0
EndProcedure

;------------------------------------------------------------------------------
; FormatColorKeys
; Purpose: Procedure: Format Color Keys.
; Params:
;   MaxLen.i = 40
; Returns: String
; Side effects: May read/write globals; see procedure body.
; Notes: Keep behavior stable when editing.
;------------------------------------------------------------------------------

Procedure.s FormatColorKeys(MaxLen.i = 40)
  Protected out.s = ""
  Protected first.b = #True
  Protected k.s
  Protected part.s
  Protected used.i

  ForEach ColorKeys()
    If ColorKeys() <= 0 : Continue : EndIf
    k = MapKey(ColorKeys())
    part = k + ":" + Str(ColorKeys())

    If first
      out = part
      first = #False
    Else
      If Len(out) + 2 + Len(part) > MaxLen
        out + ",..."
        Break
      EndIf
      out + "," + part
    EndIf
    used + 1
  Next

  If used = 0 : ProcedureReturn "" : EndIf
  ProcedureReturn out
EndProcedure
