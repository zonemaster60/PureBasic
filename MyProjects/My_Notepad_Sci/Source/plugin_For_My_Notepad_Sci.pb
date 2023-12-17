; Все плаги сейчас в юникоде, поэтому этот исходник в юникоде
EnableExplicit

Structure NppData Align #PB_Structure_AlignC
	*_nppHandle
	*_scintillaMainHandle
	*_scintillaSecondHandle
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
Declare itemError()
Declare NppMenuCommand(command)
Declare GetCurrentScintilla()
Declare ScintillaMsg(*point, msg, param1 = 0, param2 = 0)

; Константы NPP для вызовов функций
; Описание команд и уведомлений NPP http://docs.notepad-plus-plus.org/index.php/Messages_And_Notifications
; числовые значения констант NPP https://github.com/editorconfig/editorconfig-notepad-plus-plus/blob/master/src/Notepad_plus_msgs.hpp
; числовые значения констант Scintilla https://github.com/notepad-plus-plus/notepad-plus-plus/blob/master/scintilla/include/Scintilla.h

XIncludeFile "NNP_Const.pb"
;{
; Константы для получения экземпляра Scintilla
; #WM_USER = 1024
; #NPPMSG = #WM_USER + 1000
; #NPPM_GETCURRENTSCINTILLA = #NPPMSG + 4 ; для получения экземпляра Scintilla в режиме отображения сразу двух документов
; #NPPM_SETMENUITEMCHECK = #NPPMSG + 40 ; для установки / снятия галки с пункта меню

; Константы вызова меню
; #NPPM_MENUCOMMAND = 2024 + 48
; #IDM = 40000
; #IDM_SEARCH = (#IDM + 3000)
; #IDM_SEARCH_TOGGLE_BOOKMARK = (#IDM_SEARCH + 5) ; Переключить закладку в строке
; #IDM_SEARCH_REPLACE = (#IDM_SEARCH + 3)		  ; показать окно поиска изамены

; Константы чтобы получить имя файла
; #FILE_NAME = 3
; #RUNCOMMAND_USER = (#WM_USER + 3000)
; #NPPM_GETFILENAME = #RUNCOMMAND_USER + #FILE_NAME

; Константы уведомления
; #NPPN_FIRST = 1000
; #NPPN_BUFFERACTIVATED = (#NPPN_FIRST + 10) ; пполезное уведомление при смене вкладки
; #NPPN_READY = (#NPPN_FIRST + 1)			   ; уведомление что NPP и плагины загружены и можно обрабатывать уведомления
;}

; глобальные константы
Global *sciptr, post_processing = 1
; *sciptr - указатель Scintilla текущего документа
Global NppData.NppData ; создаём структуру NppData (3 дескриптора, NPP, Scintilla1, Scintilla2)
; Global PluginName.s = "Plugin name" ; Имя плагина, отображается в меню плагинов, см. getName() ниже

PrototypeC ScintillaDirect(sciptr, msg, param1 = 0, param2 = 0)
Global Scintilla.ScintillaDirect = 0

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

	Result + Chr(10) + Chr(10) + "Ошибка типа: " + Chr(34) + ErrorMessage() + Chr(34)
; 	Result + Chr(10) + Chr(10) + "Type Error: " + Chr(34) + ErrorMessage() + Chr(34)
	MessageRequester("Ошибка программы!", Result, #MB_OK | #MB_ICONERROR)
; 	MessageRequester("Program error!", Result, #MB_OK | #MB_ICONERROR)
EndProcedure
; Конец блока: фатальная ошибка

ProcedureDLL AttachProcess(Instance)

	; << Когда Notepad++ задействовал этот плагин при запуске Notepad++ >>
	; Ваш код инициализации здесь

	OnErrorCall(@FatalError()) ; вызывает процедуру FatalError(), если произойдёт ошибка. Отсюда начинаем использовать её.

; 		OutputDebugString_("2")

; 	If Scintilla
		Global Dim FuncsArray.FuncItem(2)   ; массив FuncsArray по структуре FuncItem, являющейся пунктами меню
		With FuncsArray(0)					; 1) задаём элементы структуры, это будет пункт меню с горячей клавишей (которая не работает)
			\_itemName = "item 1"			; Задаём имя пункта, отображается в меню плагина, дочерний к "Plugin name"
			\_pFunc = @item1()				; Задаём имя процедуры item1, которая будет выполнятся при клике на пункте
			\_pShortcutKey = AllocateStructure(ShortcutKey) ; выделяем память для структуры горячей клавиши
			\_pShortcutKey\_isCtrl = #True				  ; Будет ли нажат Ctrl (#True / #False)
			\_pShortcutKey\_isShift = #True				  ; Будет ли нажат Shift (#True / #False)
			\_pShortcutKey\_isAlt = #True					  ; Будет ли нажат Alt (#True / #False)
			\_pShortcutKey\_key = #VK_NEXT				  ; Собственно клавиша
		EndWith
		; Делаем аналог предыдущего пункта
		With FuncsArray(1)
			\_itemName = "item 2" ; Задаём имя 2-го пункта
			\_pFunc = @item2()	  ; Задаём имя процедуры item2 для 2-го пункта
	; 		\_init2Check = #True ; Здесь задаём будет ли элемент отмечен галкой,
	; 		\_init2Check = #False ; но это не значит, что изменение этого поля структуры будет влиять, см. ниже NPPM_SETMENUITEMCHECK
	; клавиши создаём, они теперь работают
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

	; << Когда Notepad++ удаляет этот плагин >>
	; Ваш код очистки здесь

	Protected i
	For i = 0 To ArraySize(FuncsArray())
		FreeStructure(FuncsArray(i)\_pShortcutKey)
	Next
EndProcedure

; ==================================
; 5 Обязательные процедуры Notepad++
; ==================================

; NPP спрашивает, является ли плагин в юникоде, возвращаем "ДА"
ProcedureCDLL.i isUnicode()
	ProcedureReturn #PB_Compiler_Unicode
EndProcedure

; NPP спрашивает имя плагина
ProcedureCDLL.s getName()
; 		OutputDebugString_("3")
; 	ProcedureReturn PluginName
	ProcedureReturn "Template"
EndProcedure

; NPP спрашивает, элементы меню, чтобы встроить их в меню "Плагины"
ProcedureCDLL.i getFuncsArray(*FuncsArraySize.Integer)
; 		OutputDebugString_("4")
	*FuncsArraySize\i = ArraySize(FuncsArray()) ; Возвращаем ему размер массива структур пунктов меню
	ProcedureReturn @FuncsArray()			  ; Возвращаем указатель на массив структур пунктов меню
EndProcedure

; Компиляция взависимости от x86 или x64
; setInfo выполняется при запуске программы и передаёт плагинам дескрипторы NPP, Scintilla1, Scintilla2
CompilerIf #PB_Compiler_Processor = #PB_Processor_x86

	ProcedureCDLL setInfo(*NppHandle, *ScintillaMainHandle, *ScintillaSecondHandle)
; 		OutputDebugString_("5")
		; Здесь мы заполняем элементы нашей структуры NppData, то есть получаем от NPP дескприторы NPP, Scintilla1, Scintilla2
		NppData\_nppHandle = *NppHandle
		NppData\_scintillaMainHandle = *ScintillaMainHandle
		NppData\_scintillaSecondHandle = *ScintillaSecondHandle

		; получаем указатель на функцию Scintilla_DirectFunction
		Scintilla = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTFUNCTION, 0, 0)
		; << Когда инфа Notepad++ изменилась >>
		; Ваш код здесь

	EndProcedure

CompilerElse ; иначе для x64

	ProcedureCDLL setInfo(*Npp.NppData)

		CopyStructure(*Npp, NppData, NppData) ; копируем структуру переданную из NPP в нашу
		
		Scintilla = SendMessage_(NppData\_scintillaMainHandle, #SCI_GETDIRECTFUNCTION, 0, 0)
		; << Когда инфа Notepad++ изменилась >>
		; Ваш код здесь
	EndProcedure

CompilerEndIf


; УВЕДОМЛЕНИЯ, что мы получаем в структуре SCNotification
; Переписываем данные из структуры в переменные
; code=             *SCNotification.SCNotification\nmhdr\code
; pos=              *SCNotification.SCNotification\Position
; ch=               *SCNotification.SCNotification\ch
; modificationType= *SCNotification.SCNotification\modifiers
; text=             *SCNotification.SCNotification\text
; Length=           *SCNotification.SCNotification\length
; linesAdded=       *SCNotification.SCNotification\linesAdded
; message=          *SCNotification.SCNotification\message
; wParam=           *SCNotification.SCNotification\wParam
; lParam=           *SCNotification.SCNotification\lParam
; line=             *SCNotification.SCNotification\line
; foldLevelNow=     *SCNotification.SCNotification\foldLevelNow
; foldLevelPrev=    *SCNotification.SCNotification\foldLevelPrev
; margin=           *SCNotification.SCNotification\margin
; listType=         *SCNotification.SCNotification\listType
; x=                *SCNotification.SCNotification\x
; y=                *SCNotification.SCNotification\y

ProcedureCDLL beNotified(*SCNotification.SCNotification)
	Protected i
	; Если вы не используете уведомления, а только пункты меню, просто удалите конструкцию от "With *SCNotification" до "EndWith"
	; << Когда было получено уведомление scintilla Notepad++ >>
	; Ваш код здесь

	With *SCNotification
		Select \nmhdr\code
; 			Case #NPPN_READY ; Notepad++ загружен, теперь можно обрабатывать уведомления
; 				post_processing = 0 ; флаг полезен если используются уведомления, чтобы они не работали когда NPP в процессе запуска
			Case #NPPN_BUFFERACTIVATED ; реагируем на смену вкладки
				*sciptr = SendMessage_(GetCurrentScintilla(), #SCI_GETDIRECTPOINTER, 0, 0) ; дескриптор текущего экземпляра scintilla
; 				мы можем получать *sciptr при выполнении пункта меню, а не запрашивать его при смене вкладки, это зависит как часто происходит запрос
; 			Case #SCN_SAVEPOINTLEFT ; точка сохранения оставлена, файл требует сохранения
; 				flag_not_save = 1
; 			Case #SCN_SAVEPOINTREACHED ; произошло сохранение документа
; 				flag_not_save = 0
; 			Case #SCN_MODIFIED ; реакция на модификацию документа (плаг пометки изменений)
; 				Select #True
; 					Case Bool(\modificationType & 1) ; если в типе модификации есть флаг вставки SC_MOD_INSERTTEXT, то (ввод символа или Ctrl+V)
; 						If post_processing ; пример запрета уведомления на запуске
; 							ProcedureReturn
; 						EndIf
; 					Case Bool(\modificationType & 2) ; если в типе модификации есть флаг удаления SC_MOD_DELETETEXT, то (удаление символа или выделенного)
; 						If post_processing ; пример запрета уведомления на запуске
; 							ProcedureReturn
; 						EndIf
; 				EndSelect
; 			Case #NPPN_LANGCHANGED ; изменить синтаксис документа, например с AutoIt3 на PureBasic
; 				SetWindowTitle(#Window_0, GetExt())
; 			Case #SCN_CHARADDED ; реакция на ввод символа (плаг автозавершение)
; 				Select \ch
; 					Case 'a' To 'z',  'A' To 'Z', '0' To '9', '_'
; 						SetWindowTitle(#Window_0 , Chr(\ch))
; 					Default
; 						SetWindowTitle(#Window_0 , Chr(\ch))
; 				EndSelect
		EndSelect
		; Придумать вывод в консоль

; 	Что мы можем получить в уведомлении
; 	LineStart = ScintillaMsg(*sciptr, #SCI_LINEFROMPOSITION, \position)			  ; Получаем номер строки начала вставки
; 	LineEnd = ScintillaMsg(*sciptr, #SCI_LINEFROMPOSITION, \position + \Length)	  ; Получаем номер строки конец вставки
; 	LengthDoc = ScintillaMsg(*sciptr, #SCI_GETLENGTH) ; длина текста
; 	CountLine = ScintillaMsg(*sciptr, #SCI_GETLINECOUNT) ; возвращает количество строк
; 	For i = 0 To CountLine
; 		выполнить пошаговые операции со строками
; 	Next

	EndWith
EndProcedure


ProcedureCDLL.i messageProc(Message, wParam, lParam)

	; << Когда было получено windows-сообщение Notepad++ >>
	; Ваш код здесь

	ProcedureReturn #True
EndProcedure

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

; Процедура для определения текущего окна Scintilla, одного из двух
Procedure GetCurrentScintilla()
	Protected instance_sci
; 		OutputDebugString_("7")
	SendMessage_(NppData\_nppHandle, 2028, 0, @instance_sci) ; #NPPM_GETCURRENTSCINTILLA = 2028
	If instance_sci
		ProcedureReturn NppData\_scintillaSecondHandle
	Else
		ProcedureReturn NppData\_scintillaMainHandle
	EndIf
EndProcedure

; любой пункт меню можно выполнить используя константы #IDM_...
Procedure NppMenuCommand(IDM_COMMAND)
	SendMessage_(NppData\_nppHandle, #NPPM_MENUCOMMAND, 0, IDM_COMMAND)
EndProcedure

; ==================================
; Ваши процедуры плагина
; ==================================

Procedure item1()
	*sciptr = SendMessage_(GetCurrentScintilla(), #SCI_GETDIRECTPOINTER, 0, 0) ; дескриптор текущего экземпляра scintilla
	MessageRequester("", Hex(NppData\_nppHandle, #PB_Long) + #CRLF$ + Hex(GetCurrentScintilla(), #PB_Long) + 
	                     #CRLF$ + Hex(*sciptr, #PB_Long) + #CRLF$ + Hex(Scintilla, #PB_Long))
; 	ScintillaMsg(*sciptr, #SCI_GOTOLINE, 1)
EndProcedure

Procedure item2()
	*sciptr = SendMessage_(GetCurrentScintilla(), #SCI_GETDIRECTPOINTER, 0, 0) ; дескриптор текущего экземпляра scintilla
	ScintillaMsg(*sciptr, #SCI_GOTOPOS, 1)
EndProcedure
; IDE Options = PureBasic 6.02 LTS (Windows - x86)
; ExecutableFormat = Shared dll
; CursorPosition = 177
; FirstLine = 167
; Folding = -f--
; EnableXP
; EnableOnError
; Executable = Template.dll