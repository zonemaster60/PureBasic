
EnableExplicit

; wilbert
; https://www.purebasic.fr/english/viewtopic.php?p=486382#p486382
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

Procedure.s LTrimChar(String$, TrimChar$ = #CRLF$ + #TAB$ + #FF$ + #VT$ + " ")
    Protected Len1, Len2, Blen, i, j
    Protected *memChar, *c.Character, *jc.Character

    Len1 = Len(TrimChar$)
    Len2 = Len(String$)
    Blen = StringByteLength(String$)

    If Not Asc(String$)
        ProcedureReturn ""
    EndIf

    *c.Character = @String$
    *memChar = @TrimChar$

    For i = 1 To Len2
        *jc.Character = *memChar

        For j = 1 To Len1
            If *c\c = *jc\c
                *c\c = 0
                Break
            EndIf
            *jc + SizeOf(Character)
        Next

        If *c\c
            String$ = PeekS(*c)
            Break
        EndIf
        *c + SizeOf(Character)
    Next

    ProcedureReturn String$
EndProcedure

Procedure.s RTrimChar(String$, TrimChar$ = #CRLF$ + #TAB$ + #FF$ + #VT$ + " ")
    Protected Len1, Len2, Blen, i, j
    Protected *memChar, *c.Character, *jc.Character

    Len1 = Len(TrimChar$)
    Len2 = Len(String$)
    Blen = StringByteLength(String$)

    If Not Asc(String$)
        ProcedureReturn ""
    EndIf

    *c.Character = @String$ + Blen - SizeOf(Character)
    *memChar = @TrimChar$

    For i = Len2 To 1 Step -1
        *jc.Character = *memChar

        For j = 1 To Len1
            If *c\c = *jc\c
                *c\c = 0
                Break
            EndIf
            *jc + SizeOf(Character)
        Next

        If *c\c
            Break
        EndIf
        *c - SizeOf(Character)
    Next

    ProcedureReturn String$
EndProcedure

Structure L2
  s1.s
  s2.s
EndStructure



; Возвращает одинаковые строки одного файла. С учётом регистра.
Procedure.s Sort(sText1$, sep$ = #CRLF$, sep2$ = #CRLF$, dsort = #PB_Sort_Ascending)
	Protected NewList L2.L2()
	Protected Res$, i, CountSep, tmp$, start$, ends, NewList StrList.s()
	If Left(sText1$, Len(sep2$)) = sep2$ ; Если в захваченном тексте есть перенос строки, то восстанавливаем его
		start$ = sep2$
	EndIf
	If Right(sText1$, Len(sep2$)) <> sep2$ ; Если в захваченном тексте нет переноса строки, то включаем флаг для его обрезки
		ends = 1
	EndIf

	
	If Not Asc(sText1$)
		ProcedureReturn sText1$
	EndIf
	SplitL(sText1$, StrList(), sep$)
	
	If ListSize(StrList()) = 1
		ProcedureReturn sText1$
	EndIf
	
	Res$ = ""
	ForEach StrList()
		AddElement(L2())
		L2()\s1 = StrList()
		L2()\s2 = LCase(StrList())
	Next
	SortStructuredList(L2(), dsort , OffsetOf(L2\s2) , TypeOf(L2\s2))
	ForEach L2()
		Res$ + L2()\s1 + sep2$
	Next
	Res$ = LTrimChar(Res$, #CRLF$)
	Res$ = RTrimChar(Res$, #CRLF$) + sep2$

	If ends
		Res$ = Left(Res$, Len(Res$) - Len(sep2$))
	EndIf
	
	; 	extended = k
	ProcedureReturn start$+Res$
EndProcedure


; Возвращает одинаковые строки одного файла. С учётом регистра.
Procedure.s Sort2(sText1$, sep$ = #CRLF$, sep2$ = #CRLF$, dsort = #PB_Sort_Ascending)
	Protected Res$, i, CountSep, tmp$, start$, ends, NewList StrList.s()
	If Left(sText1$, Len(sep2$)) = sep2$ ; Если в захваченном тексте есть перенос строки, то восстанавливаем его
		start$ = sep2$
	EndIf
	If Right(sText1$, Len(sep2$)) <> sep2$ ; Если в захваченном тексте нет переноса строки, то включаем флаг для его обрезки
		ends = 1
	EndIf

	
	If Not Asc(sText1$)
		ProcedureReturn sText1$
	EndIf
	SplitL(sText1$, StrList(), sep$)
	
	If ListSize(StrList()) = 1
		ProcedureReturn sText1$
	EndIf
	
	Res$ = ""
	SortList(StrList(), dsort | #PB_Sort_NoCase)
	ForEach StrList()
		Res$ + StrList() + sep2$
	Next
	Res$ = LTrimChar(Res$, #CRLF$)
	Res$ = RTrimChar(Res$, #CRLF$) + sep2$

	If ends
		Res$ = Left(Res$, Len(Res$) - Len(sep2$))
	EndIf
	
	; 	extended = k
	ProcedureReturn start$+Res$
EndProcedure


; Возвращает одинаковые строки одного файла. С учётом регистра.
Procedure.s StringUnique(sText1$, sep$ = #CRLF$, sep2$ = #CRLF$)
	Protected Res$, i, CountSep, tmp$, start$, ends, NewMap StrMap(), NewList StrList.s()
	If Left(sText1$, Len(sep2$)) = sep2$ ; Если в захваченном тексте есть перенос строки, то восстанавливаем его
		start$ = sep2$
	EndIf
	If Right(sText1$, Len(sep2$)) <> sep2$ ; Если в захваченном тексте нет переноса строки, то включаем флаг для его обрезки
		ends = 1
	EndIf
	
	AddMapElement(StrMap() , "") ; против пустых строк
								 ; Создаём ключи файла
								 ; 	k = 0
	
	If Not Asc(sText1$)
		ProcedureReturn sText1$
	EndIf
	SplitL(sText1$, StrList(), sep$)
	
	If ListSize(StrList()) = 1
		ProcedureReturn sText1$
	EndIf
	
	Res$ = ""
	ForEach StrList()
		If Not FindMapElement(StrMap() , StrList()) ; если не существует ключ, то
			AddMapElement(StrMap() , StrList(), #PB_Map_NoElementCheck) ; Добавляем без проверки
			Res$ + StrList() + sep2$
		EndIf
	Next

	If ends
		Res$ = Left(Res$, Len(Res$) - Len(sep2$))
	EndIf
	
	; 	extended = k
	ProcedureReturn start$+Res$
EndProcedure

; Возвращает одинаковые строки одного файла с подсчётом количества. С учётом регистра.
Procedure.s CountingStringUnique(sText1$, sep$ = #CRLF$, sep2$ = #CRLF$)
	Protected Res$, i, CountSep, tmp$, start$, ends, NewMap StrMap(), NewList StrList.s()
	
	If Left(sText1$, Len(sep2$)) = sep2$ ; Если в захваченном тексте есть перенос строки, то восстанавливаем его
		start$ = sep2$
	EndIf
	If Right(sText1$, Len(sep2$)) <> sep2$ ; Если в захваченном тексте нет переноса строки, то включаем флаг для его обрезки
		ends = 1
	EndIf
	
	If Not Asc(sText1$)
		ProcedureReturn sText1$
	EndIf
	SplitL(sText1$, StrList(), sep$)
	
	If ListSize(StrList()) = 1
		ProcedureReturn "1" + #TAB$ + sText1$
	Else
		ForEach StrList()
			StrMap(StrList()) + 1
		Next
	EndIf
	
	; 	k = 0
	; 	MapSize() вместо подсчёта k + 1
	Res$ = ""
	ForEach StrMap()
		Res$ + Str(StrMap()) +  #TAB$ + MapKey(StrMap()) +sep2$
		; 		k + 1
	Next
	If ends
		Res$ = Left(Res$, Len(Res$) - Len(sep2$))
	EndIf
	
	; 	extended = k
	ProcedureReturn start$+Res$
EndProcedure

; Возвращает уникальные строки 2-го файла, которых нет в первом. С учётом регистра.
Procedure.s Unique_Lines_Text2(sText1$, sText2$, sep$ = #CRLF$, sep2$ = #CRLF$)
	Protected Pos1, Pos2, i, CountSep, tmp$, start$, ends, NewMap StrMap(), NewList StrList.s(), NewList StrList2.s()
	
	If Left(sText2$, Len(sep2$)) = sep2$ ; Если в захваченном тексте есть перенос строки, то восстанавливаем его
		start$ = sep2$
	EndIf
	If Right(sText2$, Len(sep2$)) <> sep2$ ; Если в захваченном тексте нет переноса строки, то включаем флаг для его обрезки
		ends = 1
	EndIf
	
; 	Это генерирует пустые строки, но они в итоговом всё равно игнорируются как элементы.
	Select sep$
		Case #LF$
			ReplaceString(sText1$, #CR$, #LF$, #PB_String_InPlace) ; приводим к одному разделителю
		Case #CR$
			ReplaceString(sText1$, #LF$, #CR$, #PB_String_InPlace) ; приводим к одному разделителю
		Case #CRLF$
			Pos1 = CountString(sText1$ , #CR$)
			Pos2 = CountString(sText1$ , #LF$)
			If (Not Pos1 Or Not Pos2) And (Pos1 + Pos2) <> 0 ; Если хоть один из них равен 0, но оба не равны 0, то приводим к общему
				If Pos1
					sText1$ = ReplaceString(sText1$, #CR$, #CRLF$) ; приводим к одному разделителю, то есть если #CR$ есть, а #LF$ нет, то делаем #CRLF$ из #CR$
				Else
					sText1$ = ReplaceString(sText1$, #LF$, #CRLF$) ; приводим к одному разделителю
				EndIf
			ElseIf Pos1 And Pos2 And Pos1 <> Pos2 ; Смешанный вариант, то заменяем оба на перенос страницы, потом все на #CRLF$
				ReplaceString(sText1$, #LF$, Chr(12), #PB_String_InPlace)
				ReplaceString(sText1$, #CR$, Chr(12), #PB_String_InPlace)
				sText1$ = ReplaceString(sText1$, Chr(12), #CRLF$) ; приводим к одному разделителю
			EndIf
	EndSelect

	
	StrMap("") = 2 ; против пустых строк

	SplitL(sText1$, StrList(), sep$)
	
; 	If ListSize(StrList()) = 1
; 		StrMap(sText1$) = 2
; 	Else
; 		ForEach StrList()
; 			StrMap(StrList()) = 2
; 		Next
; 	EndIf
	ForEach StrList()
		StrMap(StrList()) = 2
	Next

; 	k = 0
	sText1$ = ""
	SplitL(sText2$, StrList2(), sep$)

; 	If ListSize(StrList2()) = 1
; 		StrMap(sText2$) + 1 ; если попадается первое совпадение, то 1, иначе 2 и более
; 		If StrMap(sText2$) = 1
; 			sText1$ + sText2$ + sep2$
; ; 			k + 1
; 		EndIf
; 	Else
; 		ForEach StrList2()
; 			StrMap(StrList2()) + 1 ; если попадается первое совпадение, то 1, иначе 2 и более
; 			If StrMap(StrList2()) = 1
; 				sText1$ + StrList2() + sep2$
; ; 				k + 1
; 			EndIf
; 		Next
; 	EndIf
	
	ForEach StrList2()
		StrMap(StrList2()) + 1 ; если попадается первое совпадение, то 1, иначе 2 и более
		If StrMap(StrList2()) = 1
			sText1$ + StrList2() + sep2$
; 			k + 1
		EndIf
	Next

	If ends
		sText1$ = Left(sText1$, Len(sText1$) - Len(sep2$))
	EndIf
	
	; 	extended = k
	ProcedureReturn start$+sText1$
EndProcedure

Procedure.s TrimLeft(String$, n)
	ProcedureReturn Right(String$, Len(String$) - n)
EndProcedure

; Вставить справа список из буфера
Procedure.s Merge_Lines_Text2(sText1$, sText2$, sep$ = #CRLF$, sep2$ = #CRLF$)
	Protected Pos1, Pos2, i, CountSep1, CountSep2, tmp$, sText3$, NewList StrList.s(), NewList StrList2.s()
	

	
; 	Это генерирует пустые строки, но они в итоговом всё равно игнорируются как элементы.
	Select sep$
		Case #LF$
			ReplaceString(sText1$, #CR$, #LF$, #PB_String_InPlace) ; приводим к одному разделителю
		Case #CR$
			ReplaceString(sText1$, #LF$, #CR$, #PB_String_InPlace) ; приводим к одному разделителю
		Case #CRLF$
			Pos1 = CountString(sText1$ , #CR$)
			Pos2 = CountString(sText1$ , #LF$)
			If (Not Pos1 Or Not Pos2) And (Pos1 + Pos2) <> 0 ; Если хоть один из них равен 0, но оба не равны 0, то приводим к общему
				If Pos1
					sText1$ = ReplaceString(sText1$, #CR$, #CRLF$) ; приводим к одному разделителю, то есть если #CR$ есть, а #LF$ нет, то делаем #CRLF$ из #CR$
				Else
					sText1$ = ReplaceString(sText1$, #LF$, #CRLF$) ; приводим к одному разделителю
				EndIf
			ElseIf Pos1 And Pos2 And Pos1 <> Pos2 ; Смешанный вариант, то заменяем оба на перенос страницы, потом все на #CRLF$
				ReplaceString(sText1$, #LF$, Chr(12), #PB_String_InPlace)
				ReplaceString(sText1$, #CR$, Chr(12), #PB_String_InPlace)
				sText1$ = ReplaceString(sText1$, Chr(12), #CRLF$) ; приводим к одному разделителю
			EndIf
	EndSelect

	SplitL(sText1$, StrList(), sep$)
	SplitL(sText2$, StrList2(), sep$)
	CountSep1 = ListSize(StrList())
	CountSep2 = ListSize(StrList2())
; 	If CountSep1 = 1 Or CountSep2 = 1
; 		ProcedureReturn "" ; на самом деле надо проверить на идентичность строк
; 	EndIf
	If CountSep1 = CountSep2
		ResetList(StrList2())
		ForEach StrList()
			NextElement(StrList2())
			sText3$ + StrList2() + StrList() + sep2$
		Next
	ElseIf CountSep1 > CountSep2
		ResetList(StrList2())
		ForEach StrList()
			If NextElement(StrList2())
				sText3$ + StrList2()
			EndIf
			sText3$ + StrList() + sep2$
		Next
	ElseIf CountSep1 < CountSep2
		ResetList(StrList())
		ForEach StrList2()
			sText3$ + StrList2()
			If NextElement(StrList())
				sText3$ + StrList() + sep2$
			Else
				sText3$ + sep2$
			EndIf
		Next
	EndIf
	
	; 	extended = k
	ProcedureReturn Left(sText3$, Len(sText3$) - Len(sep2$))
EndProcedure

; IDE Options = PureBasic 6.02 LTS (Linux - x64)
; CursorPosition = 190
; FirstLine = 86
; Folding = 5-
; EnableAsm
; EnableXP
; DPIAware