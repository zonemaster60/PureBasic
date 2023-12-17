Procedure IsHex(*text)
	Protected flag = 1, *c.Character = *text
	
	If *c\c = 0
		ProcedureReturn 0
	EndIf
	
	Repeat
		If Not ((*c\c >= '0' And *c\c <= '9') Or (*c\c >= 'a' And *c\c <= 'f') Or (*c\c >= 'A' And *c\c <= 'F'))
			flag = 0
			Break
		EndIf
		*c + SizeOf(Character)	
	Until Not *c\c
	
; 	Debug flag
	ProcedureReturn flag
EndProcedure

Procedure RGBtoBGR(c)
	ProcedureReturn RGB(Blue(c), Green(c), Red(c))
EndProcedure

; вычисление цвета
Procedure ColorValidate(Color$)
	Protected tmp$, tmp2$, i, def
; 	Debug Color$
	If IsHex(@Color$) 
		Select Len(Color$)
			Case 6
				def = Val("$" + Color$)
				def = RGBtoBGR(def)
			Case 1
				def = Val("$" + LSet(Color$, 6, Color$))
			Case 2
				Color$ + Color$ + Color$
				def = Val("$" + Color$)
			Case 3
				For i = 1 To 3
					tmp$ = Mid(Color$, i, 1)
					tmp2$ + tmp$ + tmp$
				Next
				def = Val("$" + tmp2$)
				def = RGBtoBGR(def)
		EndSelect
	EndIf
; 	Debug Hex(def)
	ProcedureReturn def
EndProcedure


Procedure SplitL(String.s, List StringList.s(), Separator.s = " ")
  
  Protected S.String, *S.Integer = @S
  Protected.i p, slen
  slen = Len(Separator)
  ClearList(StringList())
  
  *S\i = @String
  Repeat
    AddElement(StringList())
    p = FindString(S\s, Separator)
    StringList() = PeekS(*S\i, p - 1)
    *S\i + (p + slen - 1) << #PB_Compiler_Unicode
  Until p = 0
  *S\i = 0
  
EndProcedure

Procedure.s RepeatCharN(a.c, n)
    Protected *mem, Text$
    If a = 0 Or n = 0
        ProcedureReturn ""
    EndIf
    *mem = AllocateMemory((n + 1) * 2)
    If *mem
        FillMemory(*mem , n * 2, a, #PB_Unicode)
        Text$ = PeekS(*mem)
        FreeMemory(*mem)
    EndIf
    ProcedureReturn Text$
EndProcedure


CompilerIf #PB_Compiler_OS = #PB_OS_Windows
	


; Активировать окно
Procedure SetForegroundWindow(hWnd)
	Protected foregroundThreadID, ourThreadID
	If GetWindowLong_(hWnd, #GWL_STYLE) & #WS_MINIMIZE
		ShowWindow_(hWnd, #SW_MAXIMIZE)
		UpdateWindow_(hWnd)
	EndIf
	foregroundThreadID = GetWindowThreadProcessId_(GetForegroundWindow_(), 0)
	ourThreadID = GetCurrentThreadId_()

	If (foregroundThreadID <> ourThreadID)
		AttachThreadInput_(foregroundThreadID, ourThreadID, #True);
	EndIf

	SetForegroundWindow_(hWnd)

	If (foregroundThreadID <> ourThreadID)
		AttachThreadInput_(foregroundThreadID, ourThreadID, #False)
	EndIf

	InvalidateRect_(hWnd, #Null, #True)
EndProcedure

Structure ResStr
	r.s
	hwnd.l
EndStructure

Procedure.l enumChildren(hwnd.l, *s.ResStr)
	If hwnd
		GetClassName_(hwnd, @*s\r, 256)
		If *s\r = "WindowClass_0"
			GetWindowText_(hwnd, @*s\r, 256)
			If *s\r = "My_Notepad_Sci"
				*s\hwnd = hwnd
				ProcedureReturn 0
			EndIf
		EndIf
		ProcedureReturn 1
	EndIf
	ProcedureReturn 0
EndProcedure

Procedure.l WinGetHandle()
	Protected s.ResStr, hwnd
	s\r = Space(256)
	EnumChildWindows_(hwnd, @enumChildren(), @s)
	ProcedureReturn s\hwnd
EndProcedure




#CharSize = SizeOf(Character)
; taken from PureBasic IDE, but could do without it. But it's great to pass letters as one number
Macro AsciiConst(a, b, c, d)
  ((a) << 24 | (b) << 16 | (c) << 8 | (d))
EndMacro
#pble = AsciiConst('P', 'B', 'L', 'E') ; для определения типа данных. Вычисляется при компиляции
CompilerEndIf
; IDE Options = PureBasic 6.01 LTS (Windows - x64)
; CursorPosition = 81
; FirstLine = 47
; Folding = --
; EnableAsm
; EnableXP