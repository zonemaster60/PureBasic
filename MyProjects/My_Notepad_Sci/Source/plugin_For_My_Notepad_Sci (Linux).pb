; Все плаги сейчас в юникоде, поэтому этот исходник в юникоде
EnableExplicit

Structure NppData Align #PB_Structure_AlignC
	*_nppHandle
	*_scintillaMainHandle
	*_scintillaSecondHandle
	*_scintillaDirectP
	*_scintillaDirectF
EndStructure

Structure ShortcutKey Align #PB_Structure_AlignC
	_isCtrl.b
	_isAlt.b
	_isShift.b
	_key.b
EndStructure

Structure FuncItem Align #PB_Structure_AlignC
	_itemName.s{64}
	*_pFunc
	_cmdID.l ; тут я поменял i на l, иначе в x64 не работает
	_init2Check.b
	*_pShortcutKey.ShortcutKey
EndStructure

; ==================================
; 2 Обязательные процедуры DLL (AttachProcess, DetachProcess)
; ==================================
Declare item1()
Declare item2()
Declare item3()
Declare item4()
Declare itemError()
Declare ScintillaMsg(*point, msg, param1 = 0, param2 = 0)

; глобальные константы

PrototypeC ScintillaDirect(sciptr, msg, param1 = 0, param2 = 0)
Global Scintilla.ScintillaDirect = 0
Global NppData.NppData ; создаём структуру NppData (3 дескриптора, NPP, Scintilla1, Scintilla2)

; Начало блока: фатальная ошибка
; Это чтобы при фатальных ошибках выводить осмысленное сообщение с указанием строки, файла, типа ошибки
; Добавилось 4 Кб к DLL (зависит от числа команд/строк в исходнике), по крайней мере на время теста полезно.
Procedure FatalError()
	Protected Result.s
	
	Result = "Ошибка программы"
	; 	Result = "Program error"
	
	CompilerIf #PB_Compiler_LineNumbering
		Result + " в строке " + ErrorLine() + ", файла: " + GetFilePart(ErrorFile())
		; 		Result + " in line " + ErrorLine() + ", of file: " + GetFilePart(ErrorFile())
	CompilerElse
		CompilerError "Включите в настройках компилятора поддержку OnError"
		; 		CompilerError "Turn on compiler support OnError"
	CompilerEndIf
	
	; 	Result + Chr(10) + Chr(10) + "Ошибка типа: " + Chr(34) + ErrorMessage() + Chr(34)
EndProcedure
; Конец блока: фатальная ошибка

ProcedureDLL AttachProcess(Instance)
	
	; << Когда задействовал этот плагин при запуске >>
	; Ваш код инициализации здесь
	
	OnErrorCall(@FatalError()) ; вызывает процедуру FatalError(), если произойдёт ошибка. Отсюда начинаем использовать её.
	
	; 		OutputDebugString_("2")
	
	; 	If Scintilla
	Global Dim FuncsArray.FuncItem(4)   ; массив FuncsArray по структуре FuncItem, являющейся пунктами меню
	With FuncsArray(0)					; 1) пункт меню с быстрой клавишой
		\_itemName="Удалить дубликаты строк"			; пункт в меню плагинов
		\_pFunc=@Item1()				; имя функции вызываемой пунктом меню
		\_pShortcutKey=AllocateStructure(ShortcutKey)
		\_pShortcutKey\_isCtrl=#False
		\_pShortcutKey\_isShift=#False
		\_pShortcutKey\_isAlt=#False
		; 		\_pShortcutKey\_key=#VK_NEXT ; PAGE DOWN
		\_pShortcutKey\_key=0
		; 		https://docs.microsoft.com/en-us/windows/win32/inputdev/virtual-key-codes
	EndWith    ;2) разделитель в меню
	With FuncsArray(1)
		\_itemName="Удалить дубликаты с подсчётом уникальных"
		\_pFunc=@Item2()
	EndWith
	With FuncsArray(2)
		\_itemName="Сортировка по алфавиту"
		\_pFunc=@Item3()
	EndWith
	With FuncsArray(3)
		\_itemName="Сортировка в обратном порядке"
		\_pFunc=@Item4()
	EndWith
	; 	With FuncsArray(2) ; Пункт-разделитель, учитывайте индексы
	; 		\_itemName = ""
	; 	EndWith
	; Пунктов можно делать сколько угодно, просто добавляем индекс к item, к элементу массива, и к размеру создаваемого массива (Dim)
	; 	Else ; если не получили функцию Scintilla, то добавляем один пункт в виде сообщения об ошибке
	; 		Global Dim FuncsArray.FuncItem(1)
	; 		With FuncsArray(0)
	; 			\_itemName = "Error"
	; 			\_pFunc = @itemError()
	; 		EndWith
	; 	EndIf
EndProcedure

ProcedureDLL DetachProcess(Instance)
	
	; << Когда удаляет этот плагин >>
	; Ваш код очистки здесь
	
	Protected i
	For i = 0 To ArraySize(FuncsArray())
		FreeStructure(FuncsArray(i)\_pShortcutKey)
	Next
	FreeArray(FuncsArray())
EndProcedure

; ==================================
; 5 Обязательные процедуры
; ==================================


; NPP спрашивает имя плагина
ProcedureCDLL.i getName()
	; 		OutputDebugString_("3")
	; 	ProcedureReturn PluginName
	ProcedureReturn @"Обработка текста"
EndProcedure

; NPP спрашивает, элементы меню, чтобы встроить их в меню "Плагины"
ProcedureCDLL.i getFuncsArray(*FuncsArraySize.Integer)
	; 		OutputDebugString_("4")
	*FuncsArraySize\i = ArraySize(FuncsArray()) ; Возвращаем ему размер массива структур пунктов меню
	ProcedureReturn @FuncsArray()				; Возвращаем указатель на массив структур пунктов меню
EndProcedure

; Компиляция взависимости от x86 или x64
; setInfo выполняется при запуске программы и передаёт плагинам дескрипторы NPP, Scintilla1, Scintilla2
CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
	
	ProcedureCDLL setInfo(*NppHandle, *ScintillaMainHandle, *ScintillaSecondHandle, *_scintillaDirectP, *_scintillaDirectF)
		; 		OutputDebugString_("5")
		; Здесь мы заполняем элементы нашей структуры NppData, то есть получаем от NPP дескприторы NPP, Scintilla1, Scintilla2
		NppData\_nppHandle = *NppHandle
		NppData\_scintillaMainHandle = *ScintillaMainHandle
		NppData\_scintillaSecondHandle = *ScintillaSecondHandle
		NppData\_scintillaDirectP = *_scintillaDirectP
		NppData\_scintillaDirectF = *_scintillaDirectF
		
		; получаем указатель на функцию Scintilla_DirectFunction
		Scintilla = NppData\_scintillaDirectF
		; << Когда инфа  изменилась >>
		; Ваш код здесь
		
	EndProcedure
	
CompilerElse ; иначе для x64
	
	ProcedureCDLL setInfo(*Npp.NppData)
		
		CopyStructure(*Npp, NppData, NppData) ; копируем структуру переданную из NPP в нашу
		
		Scintilla = NppData\_scintillaDirectF
		; << Когда инфа изменилась >>
		; Ваш код здесь
	EndProcedure
	
CompilerEndIf

; ==================================
; Ещё несколько системных процедур
; ==================================

; Это оболочка функции Scintilla, полученной из SciLexer.dll, 
; проверяет, что существует указатель функции и указатель экземляра
; А также передаёт по умолчанию последние два параметра если пользователь их не задал явно.
; !!! Если заранее сделать проверку Scintilla на запуске и учёт обязательных 4-х параметров, то от оболочки можно избавиться !!!
Procedure ScintillaMsg(*point, msg, param1 = 0, param2 = 0)
	; 		OutputDebugString_("6")
	If Scintilla And *point
		ProcedureReturn Scintilla(*point, msg, param1, param2) ; Scintilla - прототип функции Scintilla_DirectFunction
	Else
		ProcedureReturn 0
	EndIf
EndProcedure

; ==================================
; Ваши процедуры плагина
; ==================================


XIncludeFile "Procedure_TextA1.pb"

Procedure Text_Processing(p, dsort = #PB_Sort_Ascending)
	Protected txtLen, *mem, text$, Length, Flag, CRLF$, *text
	; Событие
	; хендл окна scintilla
	
	; 	ScintillaMsg(NppData\_scintillaDirectP, #SCI_STYLESETCHARACTERSET, #SCE_C_STRING, #SC_CHARSET_RUSSIAN) ; Задаёт кодировку на русском
	
	; 	дескрипторы получены надёжно
	
	; 	Определяет кодировку текста
	Select ScintillaMsg(NppData\_scintillaDirectP, #SCI_GETCODEPAGE)
		Case 0
			Flag = #PB_Ascii
		Case #SC_CP_UTF8
			Flag = #PB_UTF8
	EndSelect
	Select ScintillaMsg(NppData\_scintillaDirectP, #SCI_GETEOLMODE)
		Case #SC_EOL_CRLF
			CRLF$ = #CRLF$
		Case #SC_EOL_CR
			CRLF$ = #CR$
		Case #SC_EOL_LF
			CRLF$ = #LF$
		Default
			CRLF$ = #CRLF$
	EndSelect
	
	Length = ScintillaMsg(NppData\_scintillaDirectP, #SCI_GETSELTEXT, 0, 0)							  ; получает длину выделенного текста
	If Length > 1																					  ; Если текст выделен, то работаем с участком
		*mem = AllocateMemory(Length+2)																  ; Выделяем память на длину текста и 1 символ на Null
		If *mem																						  ; Если указатель получен, то
			ScintillaMsg(NppData\_scintillaDirectP, #SCI_GETSELTEXT, 0, *mem)						  ; получает выделенный текст
			text$ = PeekS(*mem, -1, Flag)															  ; Считываем значение из области памяти
			FreeMemory(*mem)
		EndIf
		Select p
			Case 1
				text$ = StringUnique(text$, CRLF$, CRLF$) ; уникальные строки
			Case 2
				text$ = CountingStringUnique(text$, CRLF$, CRLF$) ; уникальные строки с подсчётом
																  ; 			Case 3
																  ; 				text$ = Unique_Lines_Text2(GetClipboardText(), text$, CRLF$, CRLF$) ; уникальные строки с подсчётом
																  ; 			Case 4
																  ; 				text$ = Merge_Lines_Text2(GetClipboardText(), text$, CRLF$, CRLF$) ; Вставить справа список из буфера
			Case 5
				text$ = Sort(text$, CRLF$, CRLF$, dsort) ; Сортировка
		EndSelect
		Select Flag
			Case #PB_Ascii
				*text = Ascii(text$)
				ScintillaMsg(NppData\_scintillaDirectP, #SCI_REPLACESEL, 0, *text) ; вставляет текст обратно в Scintilla
				FreeMemory(*text)
			Case #PB_UTF8
				*text = UTF8(text$)
				ScintillaMsg(NppData\_scintillaDirectP, #SCI_REPLACESEL, 0, *text) ; вставляет текст обратно в Scintilla
				FreeMemory(*text)
			Default
				ScintillaMsg(NppData\_scintillaDirectP, #SCI_REPLACESEL, 0, @text$)
		EndSelect
	Else
		txtLen = ScintillaMsg(NppData\_scintillaDirectP, #SCI_GETLENGTH)								  ; получает длину текста в байтах
		*mem = AllocateMemory(txtLen+2)																	  ; Выделяем память на длину текста и 1 символ на Null
		If *mem																							  ; Если указатель получен, то
			ScintillaMsg(NppData\_scintillaDirectP, #SCI_GETTEXT, txtLen+1, *mem)						  ; получает длину текста
			text$ = PeekS(*mem, -1, Flag)																  ; Считываем значение из области памяти
			FreeMemory(*mem)
		EndIf
		Select p
			Case 1
				text$ = StringUnique(text$, CRLF$, CRLF$) ; возвращает как есть пока текст не распознаётся, то есть одной строкой
			Case 2
				text$ = CountingStringUnique(text$, CRLF$, CRLF$) ; уникальные строки с подсчётом
																  ; 			Case 3
																  ; 				text$ = Unique_Lines_Text2(GetClipboardText(), text$, CRLF$, CRLF$) ; уникальные строки с подсчётом
																  ; 			Case 4
																  ; 				text$ = Merge_Lines_Text2(GetClipboardText(), text$, CRLF$, CRLF$) ; Вставить справа список из буфера
			Case 5
				text$ = Sort(text$, CRLF$, CRLF$, dsort) ; Сортировка
		EndSelect
		Select Flag
			Case #PB_Ascii
				*text = Ascii(text$)
				ScintillaMsg(NppData\_scintillaDirectP, #SCI_SETTEXT, 0, *text) ; вставляет текст обратно в Scintilla
				FreeMemory(*text)
			Case #PB_UTF8
				*text = UTF8(text$)
				ScintillaMsg(NppData\_scintillaDirectP, #SCI_SETTEXT, 0, *text) ; вставляет текст обратно в Scintilla
				FreeMemory(*text)
			Default
				ScintillaMsg(NppData\_scintillaDirectP, #SCI_SETTEXT, 0, @text$)
		EndSelect
	EndIf
EndProcedure


Procedure Item1()
	Text_Processing(1)
EndProcedure

Procedure Item2()
	Text_Processing(2)
EndProcedure

Procedure Item3()
	Text_Processing(5, #PB_Sort_Ascending)
EndProcedure

Procedure Item4()
	Text_Processing(5, #PB_Sort_Descending)
EndProcedure

; Procedure item2()
; 	ScintillaMsg(NppData\_scintillaDirectP, #SCI_GOTOPOS, 1)
; EndProcedure
; IDE Options = PureBasic 6.02 LTS (Linux - x64)
; ExecutableFormat = Shared .so
; CursorPosition = 32
; FirstLine = 1
; Folding = ---
; EnableXP
; EnableOnError
; Executable = Plugins/Template/TextA.so