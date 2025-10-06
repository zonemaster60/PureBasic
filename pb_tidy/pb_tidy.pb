;- TOP
; AZJIO

EnableExplicit

Define UserIntLang
; Define ForceLangSel

CompilerSelect #PB_Compiler_OS
	CompilerCase #PB_OS_Windows
		Global *Lang
		If OpenLibrary(0, "kernel32.dll")
			*Lang = GetFunction(0, "GetUserDefaultUILanguage")
			If *Lang And CallFunctionFast(*Lang) = 1049 ; ru
				UserIntLang = 1
			EndIf
			CloseLibrary(0)
		EndIf
	CompilerCase #PB_OS_Linux
		If ExamineEnvironmentVariables()
			While NextEnvironmentVariable()
				If Left(EnvironmentVariableName(), 4) = "LANG" And Left(EnvironmentVariableValue(), 2) = "ru"
					; LANG=ru_RU.UTF-8
					; LANGUAGE=ru
					UserIntLang = 1
					Break
				EndIf
			Wend
		EndIf
CompilerEndSelect


Global Dim Lng.s(11)
Lng(1) = "Error"
Lng(2) = "Error opening source file"
Lng(3) = "Error creating file"
Lng(4) = "Overwrite the file?"
Lng(5) = "Overwrite the current file? (otherwise to the clipboard and a file with the _tidy suffix)"
Lng(6) = "Success (time="
Lng(7) = " ms)"
Lng(8) = "Checking the correctness of files by removing spaces has been completed."
Lng(9) = "Error. The file is broken. (time="
Lng(10) = "Checking the correctness of the resulting file by removing spaces revealed a discrepancy with the original."
Lng(11) = "Failed to update file"

If UserIntLang
	Lng(1) = "Ошибка"
	Lng(2) = "Ошибка открытия исходника файла"
	Lng(3) = "Ошибка создания файла"
	Lng(4) = "Перезаписать файл?"
	Lng(5) = "Перезаписать текущий файл? (иначе в буфер обмена и файл с суффиксом _tidy)"
	Lng(6) = "Удачно. (выполнено за "
	Lng(7) = " мсек)"
	Lng(8) = "Проверка корректности удалением пробелов пройдена."
	Lng(9) = "Ошибка. Файл поврежден. (выполнено за "
	Lng(10) = "Проверка корректности результирующего файла методом удаления пробелов выявила несоответствие оригиналу."
	Lng(11) = "Не удалось обновить файл"
EndIf


#Char2 = SizeOf(Character)

; EnumerationBinary
; 	#Space
; 	#Operator
; 	#Comma
; 	#Equals
; EndEnumeration

; AZJIO (вариант из AutoIt3, а по ссылке есть упрощённые варианты)
; https://www.purebasic.fr/english/viewtopic.php?t=80994
Procedure.s TmpFile(DirName$ = "", Prefix$ = "~", Ext$ = ".tmp", RandomLength = 7)
    Protected TmpName$

    If RandomLength < 4 Or RandomLength > 130
        RandomLength = 7
    EndIf
    If Not Asc(DirName$) Or FileSize(DirName$) = -1
        DirName$ = GetTemporaryDirectory()
    EndIf

    If Not CheckFilename(Prefix$)
        Prefix$ = "~"
    EndIf
    If Not CheckFilename(Ext$)
        Ext$ = ".tmp"
    EndIf

    If Right(DirName$, 1) <> #PS$
        DirName$ + #PS$
    EndIf
    If Asc(Ext$) And Left(Ext$, 1) <> "."
        Ext$ = "." + Ext$
    EndIf

    Repeat
        TmpName$ = ""
        While Len(TmpName$) < RandomLength
            TmpName$ + Chr(Random(122, 97))
        Wend
        TmpName$ = DirName$ + Prefix$ + TmpName$ + Ext$
    Until FileSize(TmpName$) = -1

    ProcedureReturn TmpName$
EndProcedure


; https://www.purebasic.fr/english/viewtopic.php?t=79183
Procedure.s RTrimChar(String$, TrimChar$ = #CRLF$ + #TAB$ + #FF$ + #VT$ + " ")
    Protected Len2, Blen, i
    Protected *jc0, *c.Character, *jc.Character

    Len2 = Len(String$)
    Blen = StringByteLength(String$)

    If Not Asc(String$)
        ProcedureReturn ""
    EndIf

    *c = @String$ + Blen - #Char2
    *jc0 = @TrimChar$

    For i = Len2 To 1 Step - 1
        *jc = *jc0

        While *jc\c
            If *c\c = *jc\c
                *c\c = 0
                Break
            EndIf
            *jc + #Char2
        Wend

        If *c\c
            Break
        EndIf
        *c - #Char2
    Next

    ProcedureReturn String$
EndProcedure


Procedure.s ReadFileToVar(Path$)
	Protected id_file, Format, Text$

	id_file = ReadFile(#PB_Any, Path$)
	If id_file
		Format = ReadStringFormat(id_file)
		Text$ = ReadString(id_file, Format | #PB_File_IgnoreEOL)
		; Text$ = ReadString(id_file, #PB_UTF8 | #PB_File_IgnoreEOL)
		CloseFile(id_file)
	EndIf

	ProcedureReturn Text$
EndProcedure


Procedure CodeParser(InputFile$, OutputFile$)
	Protected flgOpnQt, c, tilda
	Protected id_file, id_file2, Format, Text$, *c.Character
	Protected indentNot, CountSpace, *c0, LengthFile.q, *m.Character, *mb.Character, *m0, RequiredNotSp, RequiredSp, RequiredNotSp2
	; MessageRequester("", InputFile$)

	id_file = ReadFile(#PB_Any, InputFile$)
	If Not IsFile(id_file)
		MessageRequester(Lng(1), Lng(2) + #CRLF$ + #CRLF$ + InputFile$)
		ProcedureReturn
	EndIf

	id_file2 = CreateFile(#PB_Any, OutputFile$)
	If Not IsFile(id_file2)
		CloseFile(id_file)
		MessageRequester(Lng(1), Lng(3) + #CRLF$ + #CRLF$ + OutputFile$)
		ProcedureReturn
	EndIf

; 	Case "            Строка в кавычках
; 	Case ;            Строка для игнора коментов
; 	Case ~           Строка в кавычках после тильды
; 		Case \            Экранирование кавычек в тильде
	LengthFile = Lof(id_file)
	*m0 = AllocateMemory(LengthFile + 2, #PB_Memory_NoClear) ; буфер выделяется по длине файла, так как код может написан в одну строку
	*m = *m0

	; цикл взят из удаления комментариев, поэтому в нём нет захвата строки и запоминание указателей.
	; Мод1 = Вместо удаления комментария цикл пробежки до конца строки
	If id_file And id_file2
		Format = ReadStringFormat(id_file)
		WriteStringFormat(id_file2, #PB_UTF8)
		While Not Eof(id_file)
			Text$ = ReadString(id_file, Format) ; читаем построчно, так легче анализировать
			indentNot = 0
; 			StartSpace = 1
			CountSpace = 0
			RequiredNotSp = 0
; 			Debug "|" + Text$ + "|" ; проверили, что строка читается без #CRLF$
; Debug Text$
			Text$ = RTrimChar(Text$, #TAB$ + " ") ; удаляем пустоты в конце строки
			*c = @Text$
			*c0 = *c
			*m = *m0
			; flgSemicolon = 0 ; сбросили флаг
			While *c\c
				Select *c\c
;- !
					Case '!' ; если ASM код, то тупо пропускаем эту строку (строки в кавычках в ASM в виде псевдокода)
						CountSpace = 0
							 ; 						ReadSource = 1
						If indentNot ; если логический знак "Исключающее ИЛИ"
							*m\c = *c\c ; пишем
						Else ; если в начале строки
							Repeat
								*m\c = *c\c ; пишем
								*m + #Char2
								*c + #Char2
							Until *c\c = 0 ; идём до конца строки
							*m\c = 0
; 							PokeS(*m0, Text$)
							Break
						EndIf
						
;- '
					Case 39 ; ' ' апостроф
						indentNot = 1
						CountSpace = 0
						*m\c = *c\c ; пишем апостроф
						*c + #Char2
						*m + #Char2
						If *c\c = 0
							*m\c = 0
							Break
						ElseIf *c\c = 39
							*m\c = *c\c ; пишем
							*m + #Char2
							*c + #Char2
							Continue
						EndIf
						Repeat
							*m\c = *c\c ; пишем
							*m + #Char2
							*c + #Char2
						Until *c\c = 0 Or *c\c = 39 ; идём до конца строки или до заканчивающегося апострофа
						If *c\c = 0
							*m\c = 0
							Break	; выпрыг, если конец строки или апостроф в ненадлежащем месте.
						EndIf
						*m\c = *c\c ; пишем
						
;- " "
					Case '"'
						indentNot = 1
						CountSpace = 0
						; Попалась кавычка, бежим до закрывающей кавычки
						Repeat ; прокручиваем до конца строки
							*m\c = *c\c ; пишем
							*m + #Char2
							*c + #Char2
						Until *c\c = 0 Or *c\c = '"' ; бежим либо до конца строки (код в это случае сломан), либо до закрывающей кавычки
						If *c\c = 0 ; обязательная защита от предотвращения захода за пределы строки, если код невалидный
							*m\c = 0
							Break
						EndIf
						*m\c = *c\c ; пишем
;-;
					Case ';'		; комент
; 						тут вместо цикла можно было бы применить PeekS - PokeS, но по сути они сделают тоже самое
						Repeat ; прокручиваем до конца строки
							*m\c = *c\c ; пишем
							*m + #Char2
							*c + #Char2
						Until *c\c = 0
						*m\c = 0
						Break
; 						indentNot = 1
; 						CountSpace = 0
; 						тут можно сделать алгоритм работы с комментариями, например проверять, что после точки с запятой один пробел,
; 						но это может "испортить" закомментированный код
;- ~
					Case '~'
						indentNot = 1
						CountSpace = 0
						tilda = 1 ; включаем флаг запуска/открытия тильды
						*m\c = *c\c ; пишем
						*m + #Char2
						*c + #Char2
						If *c\c <> '"'
							Continue ; случай если тильда используется как инвертирование числа, а не начало экранированной строки
						EndIf
						While *c\c
							Select *c\c
								Case '"'
									Select tilda
										Case 1, 3
											tilda = 2
; 											*m\c = *c\c ; пишем
; 											*m + #Char2
; 											*c + #Char2
; 											Continue
										Case 2
											; пришли к завершающей кавычке и срабатывает ниже условие flgOpnQt, так как нет Continue по тексту
											; tilda = 0
											*m\c = *c\c ; пишем закрывающую кавычку
											Break ; выпрыгиваем, чтобы не делать лишний сдвиг, мы прошли до закрывющей кавычки, сброс тильды не обязателен
									EndSelect
								Case '\'
									; этот механизм чисто для проверки экранированных кавычек после тильды
									; двойная проверка флагов изменяет поведение при дублировании кавычки
									Select tilda
										Case 2
											tilda = 3
										Case 3
											tilda = 2
									EndSelect
							EndSelect
							*m\c = *c\c ; пишем
							*m + #Char2
							*c + #Char2
						Wend
;- Space, #TAB
					Case ' ', #TAB ; проверяем повтор пробела или таба не являющегося отступом и на удаление
						If indentNot
							CountSpace + 1
							If RequiredNotSp
								RequiredNotSp = 0
								CountSpace + 1
							EndIf
						Else
							*m\c = *c\c ; если отступ то пишем этот пробел
						EndIf
						If CountSpace < 2
							*m\c = *c\c ; пишем пробел если он первый
						Else
							Repeat
								*c + #Char2
							Until *c\c = 0 Or *c\c <> 32 ; идём до конца строки или до заканчивающегося апострофа
							If *c\c = 0 ; обязательная защита от предотвращения захода за пределы строки, если код невалидный
								*m\c = 0
								Break
							EndIf
; 							*m\c = *c\c ; пишем
							*m - #Char2
							*c - #Char2
						EndIf
;- ,
					Case ',' ; проверяем символ вперёд и символ назад перед запятой и на исправление
						indentNot = 1
						If CountSpace ; если предыдущий был пробелом, то делаем буферу шаг назад
							CountSpace = 0
							*m - #Char2
						EndIf
						*m\c = *c\c ; пишем запятую
						*c + #Char2
						If *c\c And *c\c <> ' '; проверяем пробел вперёд, если его нет, то добавляем и возвращаем позицию назад
							*m + #Char2
							*m\c = ' '
						EndIf
						*c - #Char2
; 						Else
; ; 							Если кконец строки, то буфер тоже завершаем
; 							*m + #Char2
; 							*m\c = 0
; 							Break
						
; 					Case 'a' To 'z', 'A' To 'Z', '0' To '9', '_'
; 						indentNot = 1
; 						CountSpace = 0
; 						*c + #Char2
; 						While *c\c
; 							Select *c\c
; 								Case 'a' To 'z', 'A' To 'Z', '0' To '9', '_'
; 									*c + #Char2
; 								Default
; 									*c - #Char2
; 									Break
; 							EndSelect
; 						Wend
;- (
					Case '('
						indentNot = 1
						If CountSpace ; если предыдущий был пробелом, то делаем буферу шаг назад
							*m - #Char2
						EndIf
; 						*mb = *c - 5 * #Char2
						
						
						
; 						Проверка предшествующего "+ And Not Or"
						*mb = *c
						While *mb > *c0
							*mb - #Char2
							If *mb\c = ' '
								Continue
							EndIf
							If *mb\c = '+' Or *mb\c = '-' Or *mb\c = '/' Or *mb\c = '*'
								If CountSpace = 0
									*m - #Char2
									If *m\c <> ' '
										*m + #Char2
									EndIf
								EndIf
								If RequiredNotSp2
									RequiredNotSp2 = 0
								Else
									*m\c = ' '
									*m + #Char2
								EndIf
							ElseIf *mb\c = 'd'
								*mb - #Char2
								If *mb\c = 'n'
									*mb - #Char2
									If *mb\c = 'A'
										*mb - #Char2
										If *mb\c = ' '
											*m + #Char2
											*m\c = ' '
										EndIf
									EndIf
								EndIf
							ElseIf *mb\c = 't'
								*mb - #Char2
								If *mb\c = 'o'
									*mb - #Char2
									If *mb\c = 'N'
										*mb - #Char2
										If *mb\c = ' '
											*m + #Char2
											*m\c = ' '
										EndIf
									EndIf
								EndIf
							ElseIf *mb\c = 'r'
								*mb - #Char2
								If *mb\c = 'O'
									*mb - #Char2
									If *mb\c = ' '
										*m + #Char2
										*m\c = ' '
									EndIf
								EndIf
							EndIf
							Break
						Wend
						
						
						CountSpace = 0
						*m\c = *c\c ; пишем скобку
						*c + #Char2
						If *c\c = ' '
							RequiredNotSp = 1
						EndIf
						*c - #Char2
;- )
					Case ')'
						indentNot = 1
						If CountSpace ; если предыдущий был пробелом, то делаем буферу шаг назад
							CountSpace = 0
							*m - #Char2
						EndIf
						*m\c = *c\c ; пишем скобку
						
;- *
					Case '*'
						indentNot = 1
; 						If Not CountSpace And *m\c <> ' ' ; если предыдущий не пробел, то добавляем пробел буферу
; 							*m\c = ' '
; 							*m + #Char2
; 						EndIf
						CountSpace = 0
						
						If *c > *c0 ; предотвращаем выход за пределы памяти
							*c - #Char2
							*mb = *m - #Char2
							If *c\c <> '(' And *c\c <> ' ' And *c\c <> #TAB And *c\c <> '*' And *c\c <> '@' And *c\c <> '-' And *mb\c <> ' ' ; если перед "*" не разделитель "(" то добавляем пробел
								*m\c = ' '
								*m + #Char2
							EndIf
; 							Если предшествует закрывающая скобка, то нужен пробел после "*", так как указатель не может быть прилеплен к закрывающей скобке без оператора между ними
							If *c\c = ')'
								RequiredSp = 1
							ElseIf *c\c = ' '
								*c - #Char2
								If *c\c = ')'
									RequiredSp = 1
								EndIf
								*c + #Char2
							EndIf
							*c + #Char2
						EndIf
						
						
						
						*m\c = *c\c ; пишем *
						If RequiredSp
							RequiredSp = 0
							*m + #Char2
							*m\c = ' '
							CountSpace = 1
						Else
							*c + #Char2
							If *c\c And Not ((*c\c >= 'A' And *c\c <= 'Z') Or (*c\c >= 'a' And *c\c <= 'z') Or *c\c = ' ') ; проверяем что после запятой не буква, что было бы указателем
								*m + #Char2
								*m\c = ' '
								CountSpace = 1
							EndIf
							*c - #Char2
						EndIf
						
;- + / |
					Case '+', '/', '|'
						indentNot = 1
						If Not CountSpace And *m\c <> ' ' ; если предыдущий не пробел, то добавляем пробел буферу
							*m\c = ' '
							*m + #Char2
							RequiredSp = 1
						EndIf
						CountSpace = 0
						
; 						Перестраховка... Если предыдущий код добавил пробел, то этот пропускаем
						If Not RequiredSp
							If *c > *c0 ; предотвращаем выход за пределы памяти
								*c - #Char2
								*mb = *m - #Char2
								If  *c\c <> ' ' And *c\c <> #TAB And *mb\c <> ' ' ; если перед "*" не разделитель "(" то добавляем пробел
									*m\c = ' '
									*m + #Char2
; 									CountSpace = 1
								EndIf
								*c + #Char2
							EndIf
						EndIf
						RequiredSp = 0
						
						*m\c = *c\c ; пишем + |
						*c + #Char2
						If *c\c And *c\c <> ' ' ; проверяем пробел вперёд, если его нет, то добавляем и возвращаем позицию назад
							*m + #Char2
							*m\c = ' '
						EndIf
						*c - #Char2
						
;- = < >
					Case '=', '<', '>'
						indentNot = 1
						CountSpace = 0
; 						If Not CountSpace ; если предыдущий не пробел, то добавляем пробел буферу
							If *c > *c0 ; предотвращаем выход за пределы памяти
								*c - #Char2
								*mb = *m - #Char2
								If *c\c <> '<' And *c\c <> '>' And *c\c <> '=' And *c\c <> ' ' And *mb\c <> ' ' ; если перед = нет операторов сравнения <= или >= то добавляем пробел
									*m\c = ' '
									*m + #Char2
; 									CountSpace = 1
								EndIf
								*c + #Char2
							EndIf
; 						EndIf
						*m\c = *c\c ; пишем '=', '<', '>'
						*c + #Char2
						If *c\c And *c\c <> ' ' And *c\c <> '<' And *c\c <> '>' And *c\c <> '=' ; проверяем пробел вперёд, если его нет, то добавляем и возвращаем позицию назад
							*m + #Char2
							*m\c = ' '
						EndIf
						*c - #Char2
						
;- -
					Case '-'
						indentNot = 1
						CountSpace = 0
; 						If Not CountSpace ; если предыдущий не пробел, то добавляем пробел буферу
							If *c > *c0 ; предотвращаем выход за пределы памяти
								*c - #Char2
								*mb = *m - #Char2
								If *c\c <> ' ' And *mb\c <> ' ' ; если не пробел
									*m\c = ' '
									*m + #Char2
									CountSpace = 1
								EndIf
								*c + #Char2
							EndIf
; 						EndIf
						*m\c = *c\c ; пишем -
						
; 						Проверка предшествующего "="
						*mb = *c
						While *mb > *c0
							*mb - #Char2
							If *mb\c = ' '
								Continue
							EndIf
							*c + #Char2
							If *mb\c = '=' Or *mb\c = ','
								; Добавляем пробел после минуса "-" только если нет приравнивания "="
								If *c\c = ' ' ; проверяем пробел вперёд, если он есть, то ставим флаг на удаление и возвращаем позицию назад
									RequiredNotSp = 1
								ElseIf *c\c = '('
									RequiredNotSp2 = 1
								EndIf
							Else
								; Добавляем пробел после минуса "-" только если нет приравнивания "="
								If *c\c And *c\c <> ' ' ; проверяем пробел вперёд, если его нет, то добавляем и возвращаем позицию назад
									; здесь в цикле возвращаемся назад пока после пробела не встретим символ, если символ "=", то пробел не вставляем после "-"
									*m + #Char2
									*m\c = ' '
								EndIf
							EndIf
							*c - #Char2
							Break
						Wend
						
;- Default
					; Case '-'
					Default
; 						Если любой другой символ (ключевое слово и т.д.), то просто сохраняем в буфер как есть
						indentNot = 1
						CountSpace = 0
						*m\c = *c\c ; пишем
						; If Not flgOpnQt
						; EndIf
				EndSelect
				*c + #Char2
				*m + #Char2
			Wend
			*m\c = 0 ; завершаем строку нулём
; 			Debug *m
; 			Debug *m0
; 			Debug Text$
; 			WriteStringN(id_file2, Text$)
			WriteStringN(id_file2, PeekS(*m0))
		Wend
		CloseFile(id_file)
		CloseFile(id_file2)
	EndIf
;- End CodeParser

; 	If IsFile(id_file)
		; CloseFile(id_file)
; 	EndIf
; 	If IsFile(id_file2)
		; CloseFile(id_file2)
; 	EndIf
	
	FreeMemory(*m0)
EndProcedure

;- Global
Global Start, InputFile$, OutputFile$, Rewrite, NotSuccess
Define s1$, s2$, flgCompare = 1, StartTime


; 	Добавляем параметоры ком строки чтобы использовать как инструмент
If CountProgramParameters()
	InputFile$ = ProgramParameter(0)
	If Not (Asc(InputFile$) And FileSize(InputFile$) > 3 And Left(GetExtensionPart(InputFile$), 2) = "pb")
		InputFile$ = ""
	EndIf
EndIf

If Not Asc(InputFile$)
	InputFile$ = OpenFileRequester("Select PB File", "", "*.pb*|*.pb*|All Files|*.*", 0)
EndIf

If Asc(InputFile$)
; 	If MessageRequester("Перезаписать?", "Перезаписать текущий файл? (иначе в буфер обмена и файл с суффиксом _tidy)",
	If MessageRequester(Lng(4), Lng(5),
	                    #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
		OutputFile$ = TmpFile()
		Rewrite = 1
	Else
		Start = 1
		OutputFile$ = GetPathPart(InputFile$) + GetFilePart(InputFile$, #PB_FileSystem_NoExtension) + "_tidy." + GetExtensionPart(InputFile$)
	EndIf
	
	StartTime = ElapsedMilliseconds()
	CodeParser(InputFile$, OutputFile$)
	StartTime = ElapsedMilliseconds() - StartTime
	
	; 		сравнение методом удаления всех пробелов и табуляции, при этом файлы должны быть точной копией.
	; 		если проверка не пройдена то файл гарантированно сломан.
	; 		Возможно это в будущем не потребуется
	If flgCompare
		s1$ = ReadFileToVar(InputFile$)
		s2$ = ReadFileToVar(OutputFile$)
		s1$ = ReplaceString(s1$, " ", "")
		s1$ = ReplaceString(s1$, "	", "")
		s1$ = ReplaceString(s1$, #CRLF$, #LF$) ; для совместимости исходников Linux и Windows, ввиду разных переносов строк
		; 			s1$ = ReplaceString(s1$, #CR$, "")
		; 			s1$ = ReplaceString(s1$, #LF$, "")
; 		s1$ = RTrimChar(s1$, #CRLF$)
		s1$ = RTrim(s1$, #LF$) ; а потому что WriteStringN() добавляет лишний перенос строки
		
		s2$ = ReplaceString(s2$, " ", "")
		s2$ = ReplaceString(s2$, "	", "")
		s2$ = ReplaceString(s2$, #CRLF$, #LF$) ; для совместимости исходников Linux и Windows, ввиду разных переносов строк
		; 			s2$ = ReplaceString(s2$, #CR$, "")
		; 			s2$ = ReplaceString(s2$, #LF$, "")
; 		s2$ = RTrimChar(s2$, #CRLF$)
		s2$ = RTrim(s2$, #LF$) ; а потому что WriteStringN() добавляет лишний перенос строки
		
		
; Сравнение файлов в случае поиска проблем
; #File = 0
; If CreateFile(#File, "/tmp/1111.pb")
; 	WriteStringFormat(#File, #PB_UTF8)
; 	WriteString(#File, s1$, #PB_UTF8)
; 	CloseFile(#File)
; EndIf
; If CreateFile(#File, "/tmp/2222.pb")
; 	WriteStringFormat(#File, #PB_UTF8)
; 	WriteString(#File, s2$, #PB_UTF8)
; 	CloseFile(#File)
; EndIf

		
		If CompareMemoryString(@s1$, @s2$) = #PB_String_Equal
			CompilerIf #PB_Compiler_OS = #PB_OS_Windows
				MessageRequester(Lng(6) + Str(StartTime) + Lng(7), Lng(8), 4096) ; поверх всех окон
			CompilerElse
				MessageRequester(Lng(6) + Str(StartTime) + Lng(7), Lng(8))
			CompilerEndIf
		Else
			CompilerIf #PB_Compiler_OS = #PB_OS_Windows
				MessageRequester(Lng(9) + Str(StartTime) + Lng(7), Lng(10), 4096) ; поверх всех окон
			CompilerElse
				MessageRequester(Lng(9) + Str(StartTime) + Lng(7), Lng(10))
			CompilerEndIf
		EndIf
	EndIf

	If Start
		CompilerIf #PB_Compiler_OS = #PB_OS_Windows
			RunProgram(OutputFile$)
		CompilerElse
			RunProgram("xdg-open", OutputFile$, GetPathPart(OutputFile$)) 
		CompilerEndIf
	Else
		If DeleteFile(InputFile$)
			If Not RenameFile(OutputFile$, InputFile$)
				NotSuccess = 1
			EndIf
		EndIf
		If NotSuccess
			MessageRequester("", Lng(11))
		EndIf
	EndIf

; 	If Rewrite
		; CopyFile(OutputFile$, InputFile$)
; 	EndIf
; 	If Start
		; RunProgram(OutputFile$)
; 	EndIf

EndIf
; IDE Options = PureBasic 6.11 LTS Beta 1 (Windows - x64)
; CursorPosition = 753
; FirstLine = 729
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = pb_tidy.ico
; Executable = PB_Tidy.exe