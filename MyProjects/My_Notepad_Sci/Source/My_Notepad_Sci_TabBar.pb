; AZJIO 2023

EnableExplicit

CompilerIf #PB_Compiler_OS = #PB_OS_Linux
	UseGIFImageDecoder()
CompilerEndIf

If Not InitScintilla()
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows
		MessageRequester("", "Не инициализирован Scintilla.dll")
	CompilerEndIf
	End
EndIf

XIncludeFile "AutoDetectTextEncoding_Trim.pbi"
XIncludeFile "For_My_Notepad_Sci.pb"
XIncludeFile "Const.pb"
XIncludeFile "Shortcuts.pbi"
XIncludeFile "TabBarGadget.pbi"



#q$ = Chr(34)
#Window = 0
#WinFind = 1
; #Editor = 0
#Menu = 0
#PopupMenu = 1
#STYLE_0 = 32
#indic = 4
#MarkSel = 5
#frm866 = 987667

;- Enumeration
Enumeration Menu
	#mHighlightTab
	#mpOpenFolder
	#mpName
	#mpNoExt
	#mpPath
	#mpReName
	#mNew
	#mOpen
	#mSave
	#mSaveAs
	#mStartFile
	#mCloseDoc
	#mCloseProg
	#mUNDO
	#mREDO
	#mANSI
	#mUTF8
	#mUTF8nb
	#mUTF16LE
	#m866
	#mtoUTF8
	#mtoANSI
	#mCP_RUSSIAN
	CompilerSelect #PB_Compiler_OS
		CompilerCase #PB_OS_Windows
			#mCP_ARABIC
			#mCP_BALTIC
			#mCP_CHINESEBIG5
			#mCP_EASTEUROPE
			#mCP_GB2312
			#mCP_GREEK
			#mCP_HANGUL
			#mCP_HEBREW
			#mCP_JOHAB
			#mCP_MAC
			#mCP_OEM
			#mCP_SHIFTJIS
			#mCP_SYMBOL
			#mCP_THAI
			#mCP_TURKISH
			#mCP_VIETNAMESE
		CompilerCase #PB_OS_Linux
			#mCP_EASTEUROPE
			#mCP_GB2312
			#mCP_HANGUL
			#mCP_SHIFTJIS
			#mCP_OEM866
			#mCP_CYRILLIC
			#mCP_8859_15
		CompilerCase #PB_OS_MacOS
			#mCP_ARABIC
			#mCP_BALTIC
			#mCP_CHINESEBIG5
			#mCP_EASTEUROPE
			#mCP_GB2312
			#mCP_GREEK
			#mCP_HANGUL
			#mCP_HEBREW
			#mCP_JOHAB
			#mCP_MAC
			#mCP_OEM
			#mCP_SHIFTJIS
			#mCP_SYMBOL
			#mCP_THAI
			#mCP_TURKISH
			#mCP_VIETNAMESE
			#mCP_CYRILLIC
			#mCP_8859_15
	CompilerEndSelect
	#mCP_DEFAULT
; 	#mto866
	#mtoUTF16LE
	#mFind
	#mSelAll
	#mCut
	#mCopy
	#mPaste
	#mGotoLine
	#mDelCRLF
	#mInsDate
	#mSetFont
	#mSetBG
	#LastItem
EndEnumeration

Enumeration Gadget
	#Gadget_TabBar
	#txt1
	#txt2
	#txt3
	#strg1
	#strg2
	#btnSearch
	#btnReplace
	#btnReplaceAll
	#btnCount
	#btnColor
	#btnClrClr
	#chCase
	#chRegExp
	#chSel
	#chWholeWord
	#chWordStart
	#LastGadget
EndEnumeration


CompilerIf #PB_Compiler_OS = #PB_OS_Windows
	Import "user32.lib"
		OemToCharBuffA(*Buff,*Buff1,SizeBuff)
		CharToOemBuffA(*Buff,*Buff1,SizeBuff)
	EndImport
CompilerEndIf

; Structure
Structure SciRegExp
	re.s
	color.i
	id.i
	len.i
	*mem
EndStructure

Structure Docum
; 	Size.l
	hwnd.l
	id.i
	format.i ; формат документа
	fs.i ; формат при сохранении
	notbom.i; метка BOM для UTF-8
	syntax.i ; для переключения галки синтаксиса в меню, содержит индекс пункта меню
	cp.i ; для переключения галки кодировки в меню
; 	datavalue.i
; 	idxtab.l
	hlight.i ; номер группы в ini-файле, он же ссылка на массив
	acomplete.i
	path.s
	ext.s
	eol.i
	hicon.i
CompilerIf #PB_Compiler_OS = #PB_OS_Linux
	DirectP.i
	DirectF.i
CompilerEndIf
; 	List regex.SciRegExp()
EndStructure

Structure AutoComplete
	autocompletepath.s
	autocompleteflg.i
	*CanceledByChar
	*autocompList
	autocompText.s
	ext.s
; 	List ext.s() ; это нужно для поиска расширения в списке, чтобы выбрать индекс этого элемента
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
	_cmdID.l
	_init2Check.b
	*_pShortcutKey.ShortcutKey
EndStructure

Structure LibPlugin
	fname.s
	path.s
	pname.s{64}
	id.i
	FuncsArraySize.i
	*FuncsArray
	Array FuncsArray1.FuncItem(0)
EndStructure

Structure Start
	exe.s
	arg.s
	hotkey.s
; 	id.i
EndStructure

;- Global
Global NewList Docum.Docum()
Global *SelectElement.Docum
Global CountTab
Global flgHSel
Global Container_id
; Global isPortable
; Global g_SendFiles$ ; список файлов при запуске экземпляра программы

; Структура - элемент массива для определённого типа файла, точнее языка программирования
; При открытии одинакового типа файлов создаётся структура 1 раз и на него создаётся ссылка в документе.
Structure ListRE
	; 	сюда же список автозавершений для комплекта расширений определяющий язык, который явно не указан
	section.s
	List ext.s() ; это нужно для поиска расширения в списке, чтобы выбрать индекс этого элемента
	List regex.SciRegExp()
EndStructure

Global Dim AComplete.AutoComplete(0)
Global Dim HLightRegex.ListRE(0)
; Global NewList regex.SciRegExp()
Global Dim CP(#mCP_DEFAULT)

Global NewList LDirName.LibPlugin()

; Structure LPlagItem
; 	item.i
; 	*func
; EndStructure

; Global Dim g_MenuItemFunc.LPlagItem(0)
Global Dim g_MenuItemFunc(0)
Global Dim g_MenuItemStart.Start(0)


Structure NppData Align #PB_Structure_AlignC
	*_nppHandle
	*_scintillaMainHandle
	*_scintillaSecondHandle
CompilerIf #PB_Compiler_OS = #PB_OS_Linux
	*_scintillaDirectP
	*_scintillaDirectF
CompilerEndIf
EndStructure
Global NppData.NppData ; создаём структуру NppData (3 дескриптора, NPP, Scintilla1, Scintilla2)


CP(#mCP_RUSSIAN) = #SC_CHARSET_RUSSIAN
CompilerSelect #PB_Compiler_OS
	CompilerCase #PB_OS_Windows
		CP(#mCP_ARABIC) = #SC_CHARSET_ARABIC
		CP(#mCP_BALTIC) = #SC_CHARSET_BALTIC
		CP(#mCP_CHINESEBIG5) = #SC_CHARSET_CHINESEBIG5
		CP(#mCP_EASTEUROPE) = #SC_CHARSET_EASTEUROPE
		CP(#mCP_GB2312) = #SC_CHARSET_GB2312
		CP(#mCP_GREEK) = #SC_CHARSET_GREEK
		CP(#mCP_HANGUL) = #SC_CHARSET_HANGUL
		CP(#mCP_HEBREW) = #SC_CHARSET_HEBREW
		CP(#mCP_JOHAB) = #SC_CHARSET_JOHAB
		CP(#mCP_MAC) = #SC_CHARSET_MAC
		CP(#mCP_OEM) = #SC_CHARSET_OEM
		CP(#mCP_SHIFTJIS) = #SC_CHARSET_SHIFTJIS
		CP(#mCP_SYMBOL) = #SC_CHARSET_SYMBOL
		CP(#mCP_THAI) = #SC_CHARSET_THAI
		CP(#mCP_TURKISH) = #SC_CHARSET_TURKISH
		CP(#mCP_VIETNAMESE) = #SC_CHARSET_VIETNAMESE
	CompilerCase #PB_OS_Linux
		CP(#mCP_EASTEUROPE) = #SC_CHARSET_EASTEUROPE
		CP(#mCP_GB2312) = #SC_CHARSET_GB2312
		CP(#mCP_HANGUL) = #SC_CHARSET_HANGUL
		CP(#mCP_SHIFTJIS) = #SC_CHARSET_SHIFTJIS
		CP(#mCP_OEM866) = #SC_CHARSET_OEM866
		CP(#mCP_CYRILLIC) = #SC_CHARSET_CYRILLIC
		CP(#mCP_8859_15) = #SC_CHARSET_8859_15
	CompilerCase #PB_OS_MacOS
		CP(#mCP_ARABIC) = #SC_CHARSET_ARABIC
		CP(#mCP_BALTIC) = #SC_CHARSET_BALTIC
		CP(#mCP_CHINESEBIG5) = #SC_CHARSET_CHINESEBIG5
		CP(#mCP_EASTEUROPE) = #SC_CHARSET_EASTEUROPE
		CP(#mCP_GB2312) = #SC_CHARSET_GB2312
		CP(#mCP_GREEK) = #SC_CHARSET_GREEK
		CP(#mCP_HANGUL) = #SC_CHARSET_HANGUL
		CP(#mCP_HEBREW) = #SC_CHARSET_HEBREW
		CP(#mCP_JOHAB) = #SC_CHARSET_JOHAB
		CP(#mCP_MAC) = #SC_CHARSET_MAC
		CP(#mCP_OEM) = #SC_CHARSET_OEM
		CP(#mCP_SHIFTJIS) = #SC_CHARSET_SHIFTJIS
		CP(#mCP_SYMBOL) = #SC_CHARSET_SYMBOL
		CP(#mCP_THAI) = #SC_CHARSET_THAI
		CP(#mCP_TURKISH) = #SC_CHARSET_TURKISH
		CP(#mCP_VIETNAMESE) = #SC_CHARSET_VIETNAMESE
		CP(#mCP_CYRILLIC) = #SC_CHARSET_CYRILLIC
		CP(#mCP_8859_15) = #SC_CHARSET_8859_15
CompilerEndSelect
CP(#mCP_DEFAULT) = #SC_CHARSET_DEFAULT



Global pos, LastItem1, LastItem2, egm, WWE, MarkColor, tmp, IsOpenFile
Global ww, hw, tmp$, tmp2$
Global PathConfig$, ini$, isINI, inicolor$, *buffer
Global SciGadget, PnTabHeight, MnHeight
Global CurSyntax, CurCP
Global LastItem3Plug, LastItem4Plug
Global LastItem5Start, LastItem6Start

Define i

;- Declare
DeclareDLL SciNotification(Gadget, *scinotify.SCNotification)
Declare.s GetScintillaGadgetText()
Declare OpenFileToSci(FilePath$)
Declare SaveFile(FilePath$)
Declare SaveAs()
Declare StartFile()
Declare ExitProg()
Declare ColorSet(Ext$)
Declare ToFormat(format)
Declare mANSI()
Declare mUTF8nb()
Declare mUTF8()
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
Declare m866()
CompilerEndIf
Declare mUTF16LE()
Declare btnSearch(mode = 0)
; Declare btnReplace()
Declare btnReplaceAll(mode = 0)
Declare btnCount()
Declare DelCRLF()
Declare SetFont(style)
Declare SetBG()
Declare SetProgParam()
Declare ReColor()
Declare DropFiles(StringFiles$)
Declare Color(List regex.SciRegExp(), posStart, posEnd)
Declare.s GetSelText()
Declare AddDocum(Path$)
Declare GetTypeFile()
Declare HighlightSelection()
Declare GetPlugin(LastItem)
Declare Start(LastItem)
Declare StartExecute(id)
Declare GetCodeHotkey(HotkeyString$)
Declare.s GetWord()


; Prototype.i getFuncsArray(*FuncsArraySize.Integer)
; Global getFuncsArray.getFuncsArray

CompilerIf #PB_Compiler_OS = #PB_OS_Windows
	; Если копия программы уже запущена, то закрываем программу передав файлы
; 	I saw this in PureBasic IDE but did it a little differently. It was hard to understand, so I made it simple.
Procedure RunOnce_Startup()
	Protected Result, files$, TargetWnd, Mutex$, Count, i, copydata.COPYDATASTRUCT ; , RunOnceMutex
	Result = #False ; не выходить из редактора
	; 	мы можем создать мьютекс с путём к программе, это быстрее
	Mutex$ = ReplaceString(ProgramFilename(), "\", "|")

; 	RunOnceMutex = CreateMutex_(0, 0, Mutex$)
	CreateMutex_(0, 0, Mutex$)

; 	если мьютекс существует, то... то отправляем данные существующей программе
	If GetLastError_() = #ERROR_ALREADY_EXISTS
		Result = #True ; закрыть редактор после этого
		Count = CountProgramParameters()
		If Count
			; временное окно до открытия окон, которое тут же будет закрыто, поэтому его id не важен
			If OpenWindow(0, 0, 0, 0, 0, "", #PB_Window_Invisible)

				For i = 0 To Count - 1
					files$ + ProgramParameter(i) + Chr(10)
				Next
				files$ = RTrim(files$, Chr(10))

				copydata\dwData = #pble
				copydata\cbData = (Len(files$) + 1) * #CharSize	 ; include null
				copydata\lpData = @files$
				TargetWnd = WinGetHandle()
				SendMessage_(TargetWnd, #WM_COPYDATA, WindowID(0), @copydata)
				CloseWindow(0)
				SetForegroundWindow(TargetWnd)

			EndIf
		EndIf
	EndIf

	ProcedureReturn Result
EndProcedure


If RunOnce_Startup()
; 	MessageRequester("", "Application ends")
	End
EndIf

Procedure MyWindowCallback(WindowID, Message, WParam, lParam)
	Protected Result, *copydata.COPYDATASTRUCT
	Result = #PB_ProcessPureBasicEvents

	If Message = 2028
; 		Debug 1
		; NppData\_nppHandle = WindowID(#Window)
		NppData\_scintillaMainHandle = GadgetID(SciGadget)
; 		NppData\_scintillaMainHandle = ScintillaSendMessage(SciGadget, #SCI_GETDIRECTPOINTER, 0, 0)
		NppData\_scintillaSecondHandle = NppData\_scintillaMainHandle
		ForEach LDirName()
			CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
				CallCFunction(LDirName()\id, "setInfo", NppData\_nppHandle, NppData\_scintillaMainHandle, NppData\_scintillaSecondHandle)
			CompilerElse ; 64
				CallCFunction(LDirName()\id, "setInfo", @NppData)
			CompilerEndIf
		Next
	EndIf
	; событие WM_COPYDATA - произошла передача данных
	If Message = #WM_COPYDATA
		*copydata.COPYDATASTRUCT = lParam
		If *copydata\dwData = #pble And *copydata\cbData > 0
			; 			g_SendFiles$ =
; 			MessageRequester("", PeekS(*copydata\lpData, *copydata\cbData / #CharSize))
			DropFiles(PeekS(*copydata\lpData, *copydata\cbData / #CharSize))
			Result = #True
		EndIf
	EndIf
	ProcedureReturn Result
EndProcedure
CompilerEndIf


;- ini
PathConfig$ = GetPathPart(ProgramFilename())
If FileSize(PathConfig$ + "My_Notepad_Sci.ini") = -1
	CompilerSelect #PB_Compiler_OS
		CompilerCase #PB_OS_Windows
			PathConfig$ = GetHomeDirectory() + "AppData\Roaming\My_Notepad_Sci\"
		CompilerCase #PB_OS_Linux
			PathConfig$ = GetHomeDirectory() + ".config/My_Notepad_Sci/"
			; 		CompilerCase #PB_OS_MacOS
			; 			PathConfig$ = GetHomeDirectory() + "Library/Application Support/My_Notepad_Sci/"
	CompilerEndSelect
; Else
; 	isPortable = 1
EndIf
ini$ = PathConfig$ + "My_Notepad_Sci.ini"
inicolor$ = PathConfig$ + "My_Notepad_Sci_Color.ini"

ww = 800
hw = 600


Global ColorType

Global fontsize = 11
; BGR
Global background = $3f3f3f
Global color_default = $aaaaaa
Global select_bg = $ffffff
Global select_fnt = $a0a0a0
Global caret = $ffffff
Global caretline = 0
Global ini_fnt$ = "Arial"
Global selttransp = 50
Global indic = $0000FF
Global MarkSel = $FF00FF
Global linenumf = $aaaaaa
Global linenumb = $222222
Global numfield
Global auto866
Global flgAutoComplete = 1
; Define re_Repeat = $71AE71
; Define re_SqBrackets = $FF8000
; Define re_RndBrackets = $8080FF
; Define re_AnyText = $DE97D9
; Define re_Meta = $72C0C4
; Define re_Borders = $FF66F6
; Define re_ChrH = $DE97D9
; Define StyleColor$ = "style1"
; Define typeBF = 0
; Define ColorGui = 0
; Define ColorGadget = 0
; Define ColorGadgetFont = 0

If FileSize(ini$) > -1 And OpenPreferences(ini$)
	isINI = 1

; 	сделать ограничения для параметров, проверку валидности.
	PreferenceGroup("Set")
	ww = ReadPreferenceInteger("width", ww)
	hw = ReadPreferenceInteger("height", hw)
	fontsize = ReadPreferenceInteger("fontsize", fontsize)
	selttransp = ReadPreferenceInteger("selttransp", selttransp)
	ini_fnt$ = ReadPreferenceString("font", ini_fnt$)
	numfield = ReadPreferenceInteger("numfield", numfield)
	auto866 = ReadPreferenceInteger("auto866", auto866)
	flgAutoComplete = ReadPreferenceInteger("AutoComplete", flgAutoComplete)
	PreferenceGroup("Color")
	background = ColorValidate(ReadPreferenceString("bg", "3f3f3f"))
	color_default = ColorValidate(ReadPreferenceString("color", "aaaaaa"))
	select_fnt = ColorValidate(ReadPreferenceString("sel", "a0a0a0"))
	caret = ColorValidate(ReadPreferenceString("caret", "ffffff"))
	caretline = ColorValidate(ReadPreferenceString("caretline", "0"))
	indic = ColorValidate(ReadPreferenceString("indic", "f00"))
	MarkSel = ColorValidate(ReadPreferenceString("marksel", "f0f"))
	If numfield
		linenumf = ColorValidate(ReadPreferenceString("linenumf", "aaaaaa"))
		linenumb = ColorValidate(ReadPreferenceString("linenumb", "2"))
	EndIf

	ClosePreferences()
EndIf

Procedure SizeWindowHandler()
; 	ww = WindowWidth(#Window)
; 	hw = WindowHeight(#Window)
; 	ResizeGadget(SciGadget, #PB_Ignore, #PB_Ignore, ww - 10, hw - MnHeight - 10)
; 	ResizeGadget(SciGadget, #PB_Ignore, #PB_Ignore, WindowWidth(#Window) - 10, WindowHeight(#Window) - MnHeight - 10)
	
	
; 	ResizeGadget(#Gadget_Container, 0, GadgetHeight(#Gadget_TabBar), WindowWidth(#Window), WindowHeight(#Window)-GadgetHeight(#Gadget_TabBar))
	
	Protected i, w = WindowWidth(#Window)
	Protected h = WindowHeight(#Window)
; 	ResizeGadget(#Gadget_TabBar, #PB_Ignore, #PB_Ignore, w, h)
	ResizeGadget(#Gadget_TabBar, 0, 0, w, #PB_Ignore)
	UpdateTabBarGadget(#Gadget_TabBar)
	ResizeGadget(Container_id, 0, GadgetHeight(#Gadget_TabBar), w, h - GadgetHeight(#Gadget_TabBar) - MnHeight)
	ForEach Docum()
		CompilerSelect #PB_Compiler_OS
			CompilerCase #PB_OS_Windows
				ResizeGadget(Docum()\id, #PB_Ignore, #PB_Ignore, GadgetWidth(Container_id), GadgetHeight(Container_id))
			CompilerCase #PB_OS_Linux
				ResizeGadget(Docum()\id, #PB_Ignore, #PB_Ignore, GadgetWidth(Container_id) - 4, GadgetHeight(Container_id) - 4)
		CompilerEndSelect
	Next
EndProcedure

;--> Data Иконки
DataSection
	CompilerIf #PB_Compiler_OS = #PB_OS_Linux
		IconTitle:
		IncludeBinary "images" + #PS$ + "icon.gif"
		IconTitleend:
	CompilerEndIf
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows
		unknown:
		IncludeBinary "images\unknown.ico"
		unknownend:
		not1:
		IncludeBinary "images\not1.ico"
		not1end:
	CompilerEndIf
EndDataSection

CompilerIf #PB_Compiler_OS = #PB_OS_Linux
	CatchImage(0, ?IconTitle)
CompilerEndIf
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
	CatchImage(1, ?unknown)
	CatchImage(2, ?not1)
CompilerEndIf


;- GUI
If OpenWindow(#Window, 0, 0, ww, hw, "My_Notepad_Sci", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_SizeGadget | #PB_Window_MaximizeGadget | #PB_Window_MinimizeGadget)

	CompilerSelect #PB_Compiler_OS
		CompilerCase #PB_OS_Windows
			SetWindowCallback(@MyWindowCallback())
		CompilerCase #PB_OS_Linux
			gtk_window_set_icon_(WindowID(#Window), ImageID(0)) ; назначаем иконку в заголовке
	CompilerEndSelect

	WindowBounds(#Window, 250, 100, #PB_Ignore, #PB_Ignore)

	; 	мульти
; 	PanelGadget(#Gadget_TabBar, 0, 0, ww, hw)
	TabBarGadget(#Gadget_TabBar, 0, 0, ww, 26, #TabBarGadget_None, #Window)
; 	Debug #TabBarGadget_DefaultHeight
	SetTabBarGadgetAttribute(#Gadget_TabBar, #TabBarGadget_MultiLine, 1)
	SetTabBarGadgetAttribute(#Gadget_TabBar, #TabBarGadget_CloseButton, 1)
	SetTabBarGadgetAttribute(#Gadget_TabBar, #TabBarGadget_BottomLine, 1)
; 	SetTabBarGadgetAttribute(#Gadget_TabBar, #TabBarGadget_NewTab, 1)
	PnTabHeight = GadgetHeight(#Gadget_TabBar) ;  предварительный оценочный размер
; 	PnTabHeight = GetGadgetAttribute(#Gadget_TabBar, #PB_Panel_TabHeight)
	MnHeight = MenuHeight()
											   ; 	Debug PnTabHeight
; 	Container_id = ContainerGadget(#PB_Any, 0, PnTabHeight + MnHeight, ww - 3, hw - PnTabHeight - MnHeight - 4, #PB_Container_Flat)
	Container_id = ContainerGadget(#PB_Any, 0, PnTabHeight, ww, hw - PnTabHeight - MnHeight, #PB_Container_Flat)
	SetGadgetColor(Container_id, #PB_Gadget_BackColor, $3f3f3f)
; 	ResizeGadget(Container_id, 0, GadgetHeight(#Gadget_TabBar), ww, hw - GadgetHeight(#Gadget_TabBar) - MnHeight)
	AddDocum("")
; 	CloseGadgetList()

; 	For i = 0 To CountTabs - 1
; 		AddTabBarGadgetItem(#Gadget_TabBar, i, "Tab " +  Str(i))
; 		j = i+1
; 		ScintillaGadget(j, 0, 0, 700 - 4, 500 - 29, 0)
; 	Next
; 	CloseGadgetList()
	RemoveKeyboardShortcut(0, #PB_Shortcut_Tab)


	;- 	Menu Popup
	If CreatePopupMenu(#PopupMenu)

		MenuItem(#mHighlightTab, "Подсветить вкладку")
		MenuItem(#mpOpenFolder, "Открыть папку документа")
		MenuItem(#mpReName, "Переименовать файл")
		OpenSubMenu("Копировать путь")
			MenuItem(#mpPath, "Путь")
			MenuItem(#mpName, "Имя файла")
			MenuItem(#mpNoExt, "Имя файла без расширения")
		CloseSubMenu()
	EndIf


	;- 	Menu
	If CreateMenu(#Menu , WindowID(#Window))
		MenuTitle("Файл")
		MenuItem(#mNew, "Новый" + Chr(9) + "Ctrl+N")
		MenuItem(#mOpen, "Открыть" + Chr(9) + "Ctrl+O")
		MenuItem(#mSave, "Сохранить" + Chr(9) + "Ctrl+S")
		MenuItem(#mSaveAs, "Сохранить как ..." + Chr(9) + "Ctrl+Shift+S")
		MenuItem(#mStartFile, "Запуск файла" + Chr(9) + "F5")
		MenuItem(#mCloseDoc, "Закрыть документ" + Chr(9) + "Ctrl+E")
		MenuItem(#mCloseProg, "Выход")
		MenuTitle("Правка")
		MenuItem(#mUNDO, "Отменить" + Chr(9) + "Ctrl+Z")
		MenuItem(#mREDO, "Повторить" + Chr(9) + "Ctrl+Y")
		MenuBar()
		MenuItem(#mSelAll, "Выделить всё" + Chr(9) + "Ctrl+A")
		MenuItem(#mCut, "Вырезать" + Chr(9) + "Ctrl+X")
		MenuItem(#mCopy, "Копировать" + Chr(9) + "Ctrl+C")
		MenuItem(#mPaste, "Вставить" + Chr(9) + "Ctrl+V")
		MenuItem(#mGotoLine, "Перейти к строке" + Chr(9) + "Ctrl+G")
		MenuBar()
		MenuItem(#mFind, "Найти/Заменить" + Chr(9) + "Ctrl+F")
		MenuItem(#mDelCRLF, "Удалить пробелы в конце строк" + Chr(9) + "Alt+BS")
		MenuItem(#mInsDate, "Вставить дату" + Chr(9) + "Ctrl+Shift+D")
		MenuTitle("Настройка")
		MenuItem(#mSetFont, "Шрифт")
		MenuItem(#mSetBG, "Фон")
		MenuTitle("Кодировка")
		MenuItem(#mANSI, "ANSI")
		MenuItem(#mUTF8, "UTF-8")
		SetMenuItemState(#Menu, #mUTF8, 1)
		MenuItem(#mUTF8nb, "UTF-8 без BOM")
		MenuItem(#mUTF16LE, "UTF-16LE")

		CompilerIf #PB_Compiler_OS = #PB_OS_Windows
			MenuItem(#m866, "866")
		CompilerEndIf
		OpenSubMenu("Кодировки")
			MenuItem(#mCP_RUSSIAN, "Русский")
		CompilerSelect #PB_Compiler_OS
			CompilerCase #PB_OS_Windows
				MenuItem(#mCP_ARABIC, "Арабский")
				MenuItem(#mCP_BALTIC, "Прибалтика")
				MenuItem(#mCP_CHINESEBIG5, "Китайский большой 5")
				MenuItem(#mCP_EASTEUROPE, "Восточная Европа")
				MenuItem(#mCP_GB2312, "Китайский GB2312")
				MenuItem(#mCP_GREEK, "Греция")
				MenuItem(#mCP_HANGUL, "Корейская (хангыль)")
				MenuItem(#mCP_HEBREW, "Иврит")
				MenuItem(#mCP_JOHAB, "Корейская")
				MenuItem(#mCP_MAC, "Mac")
				MenuItem(#mCP_OEM, "OEM")
				MenuItem(#mCP_SHIFTJIS, "Японский")
				MenuItem(#mCP_SYMBOL, "Symbol")
				MenuItem(#mCP_THAI, "Тайский")
				MenuItem(#mCP_TURKISH, "Турецкий")
				MenuItem(#mCP_VIETNAMESE, "Вьетнамский")
			CompilerCase #PB_OS_Linux
				MenuItem(#mCP_EASTEUROPE, "Восточная Европа")
				MenuItem(#mCP_GB2312, "Китайский GB2312")
				MenuItem(#mCP_HANGUL, "Корейская (хангыль)")
				MenuItem(#mCP_SHIFTJIS, "Японский")
				MenuItem(#mCP_OEM866, "OEM866")
				MenuItem(#mCP_CYRILLIC, "Кириллица")
				MenuItem(#mCP_8859_15, "8859_15")
			CompilerCase #PB_OS_MacOS
				MenuItem(#mCP_ARABIC, "Арабский")
				MenuItem(#mCP_BALTIC, "Прибалтика")
				MenuItem(#mCP_CHINESEBIG5, "Китайский большой 5")
				MenuItem(#mCP_EASTEUROPE, "Восточная Европа")
				MenuItem(#mCP_GB2312, "Китайский GB2312")
				MenuItem(#mCP_GREEK, "Греция")
				MenuItem(#mCP_HANGUL, "Корейская (хангыль)")
				MenuItem(#mCP_HEBREW, "Иврит")
				MenuItem(#mCP_JOHAB, "Корейская")
				MenuItem(#mCP_MAC, "Mac")
				MenuItem(#mCP_OEM, "OEM")
				MenuItem(#mCP_SHIFTJIS, "Японский")
				MenuItem(#mCP_SYMBOL, "Symbol")
				MenuItem(#mCP_THAI, "Тайский")
				MenuItem(#mCP_TURKISH, "Турецкий")
				MenuItem(#mCP_VIETNAMESE, "Вьетнамский")
				MenuItem(#mCP_CYRILLIC, "Кириллица")
				MenuItem(#mCP_8859_15, "8859_15")
		CompilerEndSelect
			MenuItem(#mCP_DEFAULT, "По умолчанию")
		CloseSubMenu()
		MenuBar()
		MenuItem(#mtoANSI, "Преобразовать в ANSI")
		MenuItem(#mtoUTF8, "Преобразовать в UTF-8")
; 		CompilerIf #PB_Compiler_OS = #PB_OS_Linux
; 			MenuItem(#mto866, "Преобразовать из 866 в Win1251")
; 		CompilerEndIf
		MenuItem(#mtoUTF16LE, "Преобразовать в UTF-16LE")

		MenuTitle("Синтаксис")

		LastItem1 = #LastItem
		LastItem2 = #LastItem - 1
		If OpenPreferences(inicolor$)
			ExaminePreferenceGroups()
			While NextPreferenceGroup()
				LastItem2 + 1
				MenuItem(LastItem2, PreferenceGroupName())
			Wend
			ClosePreferences()
		EndIf

		Define mAbout
		Define mCloseFile
		MenuTitle("Справка")
		mAbout = LastItem2 + 1
		MenuItem(mAbout, "О программе")


		NppData\_nppHandle = WindowID(#Window)
		NppData\_scintillaMainHandle = GadgetID(SciGadget)
		NppData\_scintillaSecondHandle = NppData\_scintillaMainHandle
		GetPlugin(mAbout)
		LastItem3Plug = mAbout + 1
		LastItem4Plug = mAbout + ArraySize(g_MenuItemFunc())
		Start(LastItem4Plug)
		LastItem5Start = LastItem4Plug + 1
		LastItem6Start = LastItem4Plug + ArraySize(g_MenuItemStart())

; 		MenuTitle("x")

		AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_N, #mNew)
		AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_O, #mOpen)
		AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_S, #mSave)
		AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_S, #mSaveAs)
		AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_Y, #mREDO)
		AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_Z, #mUNDO)
		AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_F, #mFind)
		AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_H, #mFind)
		AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_G, #mGotoLine)
		AddKeyboardShortcut(#Window, #PB_Shortcut_Alt | #PB_Shortcut_Back, #mDelCRLF)
		AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_Shift | #PB_Shortcut_D, #mInsDate)
		AddKeyboardShortcut(#Window, #PB_Shortcut_Control | #PB_Shortcut_E, #mCloseDoc)
		AddKeyboardShortcut(#Window, #PB_Shortcut_F5, #mStartFile)
	EndIf

	PnTabHeight = GetGadgetAttribute(#Gadget_TabBar, #PB_Panel_TabHeight)
	MnHeight = MenuHeight()
	ResizeGadget(SciGadget, #PB_Ignore, #PB_Ignore, #PB_Ignore, WindowHeight(#Window) - PnTabHeight - MnHeight - 4)




;- 	GUI Search
	If OpenWindow(#WinFind, 0, 0, 475, 195, "Найти и заменить", #PB_Window_SystemMenu | #PB_Window_Tool | #PB_Window_Invisible | #PB_Window_ScreenCentered, WindowID(#Window))

		TextGadget(#txt1, 5, 8, 59, 17, "Найти")
		TextGadget(#txt2, 5, 42, 59, 17, "Замена")
		StringGadget(#strg1, 65, 5, 280, 27, "")
		StringGadget(#strg2, 65, 40, 280, 27, "")
		ButtonGadget(#btnSearch, 355, 4, 110, 29, "Найти")
		ButtonGadget(#btnReplace, 355, 39, 110, 29, "Заменить")
		ButtonGadget(#btnReplaceAll, 355, 74, 110, 29, "Заменить всё")
		ButtonGadget(#btnCount, 355, 109, 109, 29, "Подсчитать")
		ButtonGadget(#btnColor, 355, 144, 109, 29, "Подсветить")
		ButtonGadget(#btnClrClr, 240, 144, 109, 29, "Очистить")
		CheckBoxGadget(#chCase, 5, 73, 185, 20, "Учитывать регистр")
		CheckBoxGadget(#chRegExp, 5, 93, 185, 20, "Регулярное выражение")
		CheckBoxGadget(#chSel, 205, 73, 140, 20, "В выделенном")
		CheckBoxGadget(#chWholeWord, 205, 93, 145, 20, "Целое слово")
		CheckBoxGadget(#chWordStart, 205, 113, 145, 20, "С начала слова")
		TextGadget(#txt3, 5, 195 - 20, 475 - 10, 20, "Строка состояния")
	EndIf

	SetActiveGadget(SciGadget)

	GetTypeFile()
	SetProgParam()

	BindEvent(#PB_Event_SizeWindow, @SizeWindowHandler())


	;- 	Loop
	Repeat
		WWE = WaitWindowEvent()
		Select EventWindow()
			Case #Window
				Select WWE
					Case #PB_Event_Gadget
						Select EventGadget()
							Case SciGadget
								If EventType() = #PB_EventType_RightClick
									DisplayPopupMenu(#PopupMenu, WindowID(#Window))
								EndIf
							Case #Gadget_TabBar
								Select EventType()
; 									Case #PB_EventType_LeftDoubleClick, #PB_EventType_RightDoubleClick, #PB_EventType_RightClick
									Case #TabBarGadget_EventType_RightDown
										If Asc(Docum()\path)
											DisplayPopupMenu(#PopupMenu, WindowID(#Window))
										EndIf
									Case #TabBarGadget_EventType_Resize
										SizeWindowHandler() ; так как есть BindEvent, то надо это событие только если изменяется высота, т.е. 2-й ряд вкладок.
									Case #TabBarGadget_EventType_CloseItem
										
										CountTab = CountTabBarGadgetItems(#Gadget_TabBar)
										If CountTab = 1
											; 											удаляем текущий, добавляя пустой
											If ScintillaSendMessage(SciGadget, #SCI_GETLENGTH) = 0 And ScintillaSendMessage(SciGadget, #SCI_CANUNDO) = 0 And ScintillaSendMessage(SciGadget, #SCI_CANREDO) = 0
												; 												ничего не делаем если документ и так пустой
												; 												Continue
											Else
												tmp = GetTabBarGadgetState(#Gadget_TabBar)
												If tmp <> -1
													tmp$ = GetTabBarGadgetItemText(#Gadget_TabBar, tmp)
													If Asc(tmp$) = '*'
														Select MessageRequester("Сохранить?", "Сохранить файл?" + #LF$ + #LF$ + GetFilePart(Docum()\path), #PB_MessageRequester_YesNoCancel)
															Case #PB_MessageRequester_Cancel
																Continue
															Case #PB_MessageRequester_Yes
																If FileSize(Docum()\path) > -1
																	SaveFile(Docum()\path)
																Else
																	SaveAs()
																EndIf
														EndSelect
													EndIf
												EndIf
												AddDocum("")
												SelectElement(Docum(), 0)
												FreeGadget(Docum()\id)
												CompilerIf #PB_Compiler_OS = #PB_OS_Windows
													DestroyIcon_(Docum()\hicon)
												CompilerEndIf
												RemoveTabBarGadgetItem(#Gadget_TabBar, 0)
												DeleteElement(Docum()) ; а может переназначить текущий вместо удаления?
												SelectElement(Docum(), 0) ; снова выбираем
												SciGadget = Docum()\id
												SetActiveGadget(SciGadget)
											EndIf
										Else
											tmp = GetTabBarGadgetItemPosition(#Gadget_TabBar, #TabBarGadgetItem_Event)
											If tmp <> -1
												tmp$ = GetTabBarGadgetItemText(#Gadget_TabBar, tmp)
												If Asc(tmp$) = '*'
													SetTabBarGadgetItemState(#Gadget_TabBar, tmp, #TabBarGadget_Selected, #TabBarGadget_Selected)
													*SelectElement = GetTabBarGadgetItemData(#Gadget_TabBar, tmp)
													If *SelectElement
														ChangeCurrentElement(Docum(), *SelectElement)
														If SciGadget <> Docum()\id
															HideGadget(SciGadget, #True)
															HideGadget(Docum()\id, #False)
															SetActiveGadget(Docum()\id)
														EndIf
													EndIf
													Select MessageRequester("Сохранить?", "Сохранить файл?" + #LF$ + #LF$ + GetFilePart(Docum()\path), #PB_MessageRequester_YesNoCancel)
														Case #PB_MessageRequester_Cancel
															; Если хотет вернуться к прошлой активной вкладке, но надо ещё использовать #TabBarGadget_Selected
															; тут ещё надо отработать #TabBarGadget_EventType_Change, а то плаг не получит указатель
															
; 															If SciGadget <> Docum()\id
; 																HideGadget(Docum()\id, #True)
; 																HideGadget(SciGadget, #False)
; 																SetActiveGadget(SciGadget)
; 															EndIf
															Continue
														Case #PB_MessageRequester_Yes
															If FileSize(Docum()\path) > -1
																SaveFile(Docum()\path)
															Else
																SaveAs()
															EndIf
													EndSelect
												EndIf
												
												
; 												If CountTab
; 													OpenGadgetList(Container_id)
; 												EndIf
; 												
; здесь проблема, закрыта может быть неактивная, не выбранная вкладка, надо получить её структуру
												*SelectElement = GetTabBarGadgetItemData(#Gadget_TabBar, tmp)
												If *SelectElement
													ChangeCurrentElement(Docum(), *SelectElement)
													FreeGadget(Docum()\id)
													CompilerIf #PB_Compiler_OS = #PB_OS_Windows
														DestroyIcon_(Docum()\hicon)
													CompilerEndIf
													RemoveTabBarGadgetItem(#Gadget_TabBar, tmp)
													DeleteElement(Docum())
												EndIf
; 												If CountTab
; 													CloseGadgetList()
; 												EndIf
												
												; добавлена функция чтобы выбрать последний после удаления
												SetTabBarGadgetState(#Gadget_TabBar, CountTabBarGadgetItems(#Gadget_TabBar) - 1)
												tmp = GetTabBarGadgetState(#Gadget_TabBar)
												; 	Debug tmp
												*SelectElement = GetTabBarGadgetItemData(#Gadget_TabBar, tmp)
												If *SelectElement
													ChangeCurrentElement(Docum(), *SelectElement)
													; Debug ListSize(Docum())
													SciGadget = Docum()\id
													If SciGadget
														
; 														после удаления вкладки нужно передать плагу другой документ
														CompilerIf #PB_Compiler_OS = #PB_OS_Linux
				; 											каждому плагу высылаем новые данные в Linux
															NppData\_scintillaDirectP = Docum()\DirectP
															NppData\_scintillaDirectF = Docum()\DirectF
															ForEach LDirName()
																CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
																	CallCFunction(LDirName()\id, "setInfo", NppData\_nppHandle, NppData\_scintillaMainHandle, NppData\_scintillaSecondHandle, NppData\_scintillaDirectP, NppData\_scintillaDirectF)
																CompilerElse ; иначе для x64
																	CallCFunction(LDirName()\id, "setInfo", @NppData)
																CompilerEndIf
															Next
														CompilerEndIf
														
														HideGadget(SciGadget, #False)
														; Debug SciGadget
														SetActiveGadget(SciGadget)
													EndIf
												EndIf
											EndIf
										EndIf
								
								
								
								
							Case #TabBarGadget_EventType_Change
										tmp = GetTabBarGadgetItemPosition(#Gadget_TabBar, #TabBarGadgetItem_Event)
; 										Debug tmp
										If tmp <> -1
											HideGadget(SciGadget, #True)
											*SelectElement = GetTabBarGadgetItemData(#Gadget_TabBar, tmp) 
											ChangeCurrentElement(Docum(), *SelectElement)
											SciGadget = Docum()\id
											HideGadget(SciGadget, #False)
											SetActiveGadget(SciGadget)
; 											SetTabBarGadgetItemState(#Gadget_TabBar, CountTab, #True, #TabBarGadget_Selected)


											SetMenuItemState(#Menu, CurSyntax, 0)
											CurSyntax = Docum()\syntax
											SetMenuItemState(#Menu, Docum()\syntax, 1)

											SetMenuItemState(#Menu, CurCP, 0)
											CurCP = Docum()\cp
											SetMenuItemState(#Menu, Docum()\cp, 1)

										CompilerIf #PB_Compiler_OS = #PB_OS_Linux
; 											каждому плагу высылаем новые данные в Linux
											NppData\_scintillaDirectP = Docum()\DirectP
											NppData\_scintillaDirectF = Docum()\DirectF
											ForEach LDirName()
												CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
													CallCFunction(LDirName()\id, "setInfo", NppData\_nppHandle, NppData\_scintillaMainHandle, NppData\_scintillaSecondHandle, NppData\_scintillaDirectP, NppData\_scintillaDirectF)
												CompilerElse ; иначе для x64
													CallCFunction(LDirName()\id, "setInfo", @NppData)
												CompilerEndIf
											Next
										CompilerEndIf


; 											Debug Docum()\fs
	; 										tmp = GetGadgetItemData(#Gadget_TabBar, tmp)
	; 										ForEach Docum()
	; 											If Docum()\id = tmp
	; 												SciGadget = Docum()\id
	; 												SetActiveGadget(Docum()\id)
	; ; 												SelectElement(
	; 												Break
	; 											EndIf
	; 										Next
										EndIf
								EndSelect
						EndSelect



					Case #PB_Event_GadgetDrop ; событие перетаскивания
						Select EventGadget()
							Case SciGadget
								DropFiles(EventDropFiles())
						EndSelect
; 					Case #PB_Event_SizeWindow
; 						ww = WindowWidth(#Window)
; 						hw = WindowHeight(#Window)
; 						ResizeGadget(SciGadget, #PB_Ignore, #PB_Ignore, ww - 10, hw - MnHeight - 10)
;- 	Loop Menu
					Case #PB_Event_Menu
						egm = EventGadget()
						Select egm
							Case #mNew
								AddDocum("")
; 								ScintillaSendMessage(SciGadget, #SCI_CLEARALL)
; 								SetWindowTitle(#Window, "My_Notepad")
							Case #mOpen
								tmp$ = OpenFileRequester("Открыть файл", GetCurrentDirectory(), "Все (*.*)|*.*", 0)
								If Asc(tmp$)
									AddDocum(tmp$)
									OpenFileToSci(tmp$)
								EndIf
							Case #mCP_RUSSIAN To #mCP_DEFAULT
; 								CP(#mCP_RUSSIAN) = #SC_CHARSET_RUSSIAN
								ScintillaSendMessage(SciGadget, #SCI_STYLESETCHARACTERSET, 0, CP(egm))
							Case LastItem3Plug To LastItem4Plug
								CallFunctionFast(g_MenuItemFunc(egm - LastItem3Plug + 1))
							Case LastItem5Start To LastItem6Start
								tmp = egm - LastItem5Start + 1
								StartExecute(tmp)
							Case LastItem1 To LastItem2
								SetMenuItemState(#Menu, CurSyntax, 0)
								; оба варианта сброса стилей не исправляют проблему. Если ini файл открыть как txt, а потом переключить в ini, то
								; каким то образом предыдущий стиль инвертируется и применяется к тем элементам, которых не затрагивает новый покарс
								; чтобы избавиться от проблемы надо в начало секции в ini-файле добавить строку "aaaaaa|2=.+" без кавычек, которая
								; сначала всё покрасит в дефолтный цвет "aaaaaa" и поверх покрасит новыми цветами. Тогда старое влиять не будет.
; 								ScintillaSendMessage(SciGadget, #SCI_STYLERESETDEFAULT)        ; сброс стилей до момента инициализации
; 								ScintillaSendMessage(SciGadget, #SCI_STYLECLEARALL)        ; общий стиль для всех - не, это очистить стили
								tmp$ = GetMenuItemText(#Menu, egm)
								tmp$ = StringField(tmp$, 1, ",")
								ColorSet(tmp$)
								ReColor()
; 								надо ли тут это
; 								ScintillaSendMessage(SciGadget, #SCI_STARTSTYLING, 2147483646, 0) ; позиция больше документа
; 								ScintillaSendMessage(SciGadget, #SCI_SETSTYLING, 0, 0)     ; ширина и номер стиля
								For i = LastItem1 To LastItem2
									If GetMenuItemState(#Menu, i) = 1
										SetMenuItemState(#Menu, i, 0)
										Break
									EndIf
								Next
								CurSyntax = egm
								Docum()\syntax = CurSyntax
								SetMenuItemState(#Menu, egm, 1)
							Case #mSave
								If FileSize(Docum()\path) > -1
									SaveFile(Docum()\path)
								Else
									SaveAs()
								EndIf
							Case #mSaveAs
								SaveAs()
							Case #mStartFile
								StartFile()
							Case #mCloseProg
								ExitProg()


								;- 	Loop Edit
							Case #mUNDO
								ScintillaSendMessage(SciGadget, #SCI_UNDO)
							Case #mREDO
								ScintillaSendMessage(SciGadget, #SCI_REDO)
							Case #mSelAll
								ScintillaSendMessage(SciGadget, #SCI_SELECTALL)
							Case #mGotoLine
								tmp$ = InputRequester("Перейти к строке", "Номер строки", "")
								If Asc(tmp$)
									ScintillaSendMessage(SciGadget, #SCI_GOTOLINE, Val(tmp$))
								EndIf
							Case #mCopy
								ScintillaSendMessage(SciGadget, #SCI_COPY)
							Case #mPaste
								ScintillaSendMessage(SciGadget, #SCI_PASTE)
							Case #mCut
								ScintillaSendMessage(SciGadget, #SCI_CUT)
							Case #mFind
								HideWindow(#WinFind, #False)
								SetGadgetText(#strg1, GetSelText())
								SetActiveGadget(#strg1)
							Case #mDelCRLF
								DelCRLF()
							Case #mInsDate
								*buffer = UTF8(FormatDate("%dd.%mm.%yyyy", Date()))
								ScintillaSendMessage(SciGadget, #SCI_REPLACESEL, 0, *buffer)
								MemorySize(*buffer)

								; 								Настройки
							Case #mSetFont
								SetFont(#STYLE_DEFAULT)
							Case #mSetBG
								SetBG()


								; 								Кодировки
							Case #mANSI
								mANSI()

								; 						GetScintillaGadgetText()
								; 						tmp$ = InputRequester("Кодировка", "Кодировка", "")
								; 						If Asc(tmp$)
								; 							ScintillaSendMessage(SciGadget, #SCI_STYLESETCHARACTERSET, 0, Val(tmp$))
								; 						EndIf
							Case #mUTF16LE
								mUTF16LE()
							Case #mUTF8nb
								mUTF8nb()
							Case #mUTF8
								mUTF8()
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
							Case #m866
								m866()
CompilerEndIf

							Case #mtoUTF16LE
								ToFormat(3)
								ReColor()
							Case #mtoUTF8
								ToFormat(1)
								ReColor()
								; 				        If Docum()\format = #PB_Ascii
								; 				            tmp$ = GetScintillaGadgetText()
								; 				        EndIf
								; 				        ScintillaSendMessage(SciGadget, #SCI_TARGETASUTF8, 0, @tmp$)
								; 				        ScintillaSendMessage(SciGadget, #SCI_SETTEXT, 0, @tmp$)
								; 						ScintillaSendMessage(SciGadget, #SCI_SETCODEPAGE, #SC_CP_UTF8)

							Case #mtoANSI
								ToFormat(0)
								ReColor()
								; 				        If Docum()\format = #PB_UTF8
								; 				            tmp$ = GetScintillaGadgetText()
								; 				        EndIf
								; 				        ScintillaSendMessage(SciGadget, #SCI_ENCODEDFROMUTF8, @tmp$, @tmp$)
; 							Case #mto866
; 								ToFormat(2)
; 								ReColor()

							Case mAbout
								MessageRequester("", "Автор AZJIO" + #LF$ + "27.06.2023")


							Case #mCloseDoc
								tmp = GetTabBarGadgetState(#Gadget_TabBar)
								If tmp <> -1
									PostEvent(#PB_Event_Gadget, #Window, #Gadget_TabBar, #TabBarGadget_EventType_CloseItem, tmp)
								EndIf

	;- 	Loop Menu Popup
							Case #mpReName
								If Asc(Docum()\path)
									tmp$ = InputRequester("Переименовать файл", "", GetFilePart(Docum()\path))
									If Asc(tmp$) And CheckFilename(tmp$)
										If RenameFile(Docum()\path , GetPathPart(Docum()\path) + tmp$)
											Docum()\path = GetPathPart(Docum()\path) + tmp$
											tmp = GetTabBarGadgetState(#Gadget_TabBar)
											If tmp <> -1
												tmp2$ = GetTabBarGadgetItemText(#Gadget_TabBar, tmp)
												If Asc(tmp2$) = '*'
													SetTabBarGadgetItemText(#Gadget_TabBar, tmp, "*" + tmp$)
												Else
													SetTabBarGadgetItemText(#Gadget_TabBar, tmp, tmp$)
												EndIf
											EndIf
; 											tmp2$ = ""
										EndIf
									EndIf

								EndIf
							Case #mHighlightTab
								i = GetTabBarGadgetState(#Gadget_TabBar)
								tmp = GetTabBarGadgetItemColor(#Gadget_TabBar, i, #PB_Gadget_BackColor)
								tmp = ColorRequester(tmp)
								If tmp > -1
									SetTabBarGadgetItemColor(#Gadget_TabBar, i, #PB_Gadget_BackColor, tmp)
								EndIf
							Case #mpOpenFolder
								If Asc(Docum()\path)
									CompilerSelect #PB_Compiler_OS
										CompilerCase #PB_OS_Windows
; 											RunProgram(GetPathPart(Docum()\path))
											RunProgram("explorer.exe", "/select," + #q$ + Docum()\path + #q$, "")
										CompilerCase #PB_OS_Linux
											RunProgram("xdg-open", #q$ + GetPathPart(Docum()\path) + #q$, "")
									CompilerEndSelect
								EndIf
							Case #mpPath
								SetClipboardText(Docum()\path)
							Case #mpName
								SetClipboardText(GetFilePart(Docum()\path))
							Case #mpNoExt
								SetClipboardText(GetFilePart(Docum()\path, #PB_FileSystem_NoExtension))


						EndSelect
					Case #PB_Event_CloseWindow
						ExitProg()
				EndSelect
;- 	Loop Find
			Case #WinFind
				Select WWE
					Case #PB_Event_Gadget
						Select EventGadget()

								; 	#strg1
								; 	#strg2
								; 	#chCase
								; 	#chRegExp
								; 	#chSel
							Case #btnSearch
								btnSearch()
							Case #btnReplace
								; 								btnReplace()
								btnSearch(1)
							Case #btnReplaceAll
								btnReplaceAll()
							Case #btnCount
								btnReplaceAll(1)
							Case #btnColor
								ScintillaSendMessage(SciGadget, #SCI_SETINDICATORCURRENT, #indic) ; делает индикатор под номером 4 текущим
								MarkColor = 1
								btnReplaceAll()
								ScintillaSendMessage(SciGadget, #SCI_SETINDICATORCURRENT, #MarkSel) ; делает индикатор под номером 5 текущим
							Case #btnClrClr
								ScintillaSendMessage(SciGadget, #SCI_SETINDICATORCURRENT, #indic) ; делает индикатор под номером 4 текущим
								; 								ScintillaSendMessage(SciGadget, #SCI_SETINDICATORCURRENT, #indic)	   ; делает индикатор под номером #indic текущим
								; до конца по длине текста, очистить всё
								ScintillaSendMessage(SciGadget, #SCI_INDICATORCLEARRANGE, 0, ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH))
								ScintillaSendMessage(SciGadget, #SCI_SETINDICATORCURRENT, #MarkSel) ; делает индикатор под номером 5 текущим
						EndSelect
					Case #PB_Event_CloseWindow
						HideWindow(#WinFind, #True)

; 						SetActiveWindow(#Window)
; 						SetActiveGadget(SciGadget)
				EndSelect
		EndSelect
	ForEver
EndIf





Procedure.s GetWord()
	Protected word$, *pos
	Protected length, Cursor, Anchor

	Cursor = ScintillaSendMessage(SciGadget, #SCI_GETCURRENTPOS)
	Anchor = ScintillaSendMessage(SciGadget, #SCI_GETANCHOR)
	If Cursor <> Anchor
		; Anchor = ScintillaSendMessage(SciGadget, #SCI_GETANCHOR)
		Anchor = ScintillaSendMessage(SciGadget, #SCI_GETSELECTIONSTART)
		Cursor = ScintillaSendMessage(SciGadget, #SCI_GETSELECTIONEND)
		length = ScintillaSendMessage(SciGadget, #SCI_COUNTCHARACTERS, Anchor, Cursor)
		word$ = Space(length)
		ScintillaSendMessage(SciGadget, #SCI_GETSELTEXT, 0, @word$)
		word$ = PeekS(@word$, -1, #PB_UTF8)
		; 			If Anchor < Cursor
		; 				Swap Cursor, Anchor
		; 			EndIf
		; 			Debug "length"
		; 			Debug length
	Else
		Anchor = ScintillaSendMessage(SciGadget, #SCI_WORDSTARTPOSITION, Cursor, 1)
		Cursor = ScintillaSendMessage(SciGadget, #SCI_WORDENDPOSITION, Cursor, 1)
		If Cursor <> Anchor
			*pos = ScintillaSendMessage(SciGadget, #SCI_GETCHARACTERPOINTER)
			word$ = PeekS(*pos + Anchor, Cursor - Anchor, #PB_UTF8)
		EndIf
	EndIf
	ProcedureReturn word$
EndProcedure


Procedure StartExecute(id)
	Protected exe$, arg$, word$, pos, posexe, posarg
; 	Static ProgDir$ = RTrim(GetPathPart(ProgramFilename()), #PS$) ; не может быть строкой, придётся делать глобальной переменной.
	exe$ = g_MenuItemStart(id)\exe
	arg$ = g_MenuItemStart(id)\arg

; 	Поддержка относительных путей
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
	If Left(exe$, 1) = "\" And FileSize(RTrim(PathConfig$, "\") + exe$) > -1
		exe$ = RTrim(PathConfig$, "\") + exe$
	EndIf
CompilerEndIf

; 	FindString() позволяет не запрашивать переменные, в которых отсутствует необходимость. Например ${Word} требует вычисления.
; позиции posexe и posarg оптимизируют поиск начиная следующие всегда от найденного, а не от начала.

	posexe = FindString(exe$, "${")
	If posexe
		pos = FindString(exe$, "${ProgDir}", posexe, #PB_String_NoCase)
		If pos
			exe$ = ReplaceString(exe$, "${ProgDir}", RTrim(GetPathPart(ProgramFilename()), #PS$), #PB_String_NoCase, pos)
		EndIf
		pos = FindString(exe$, "${Word}", posexe, #PB_String_NoCase)
		If pos
			word$ = GetWord()
			; 		Debug "word$ = |" + word$ + "|"
			exe$ = ReplaceString(exe$, "${Word}", word$, #PB_String_NoCase, pos)
		EndIf
	EndIf

	posarg = FindString(arg$, "${")
	If posarg
		pos = FindString(arg$, "${ProgDir}", posarg, #PB_String_NoCase)
		If pos
			arg$ = ReplaceString(arg$, "${ProgDir}", RTrim(GetPathPart(ProgramFilename()), #PS$), #PB_String_NoCase, pos)
		EndIf
		pos = FindString(arg$, "${Ext}", posarg, #PB_String_NoCase)
		If pos
			; 		arg$ = ReplaceString(arg$, "${Ext}", GetExtensionPart(), #PB_String_NoCase, pos)
			arg$ = ReplaceString(arg$, "${Ext}", Docum()\ext, #PB_String_NoCase, pos)
		EndIf

		pos = FindString(arg$, "${Path}", posarg, #PB_String_NoCase)
		If pos
			arg$ = ReplaceString(arg$, "${Path}", Docum()\path, #PB_String_NoCase, pos)
		EndIf

		pos = FindString(arg$, "${Name}", posarg, #PB_String_NoCase)
		If pos
			arg$ = ReplaceString(arg$, "${Name}", GetFilePart(Docum()\path, #PB_FileSystem_NoExtension), #PB_String_NoCase, pos)
		EndIf
; 		дескриптор Scintilla, чтобы не искать его через окна, особенно упрощает в Linux
		pos = FindString(arg$, "${hSci}", posarg, #PB_String_NoCase)
		If pos
			arg$ = ReplaceString(arg$, "${hSci}", Str(Docum()\hwnd), #PB_String_NoCase, pos)
		EndIf
		pos = FindString(arg$, "${Word}", posarg, #PB_String_NoCase)
		If pos
			If Not Asc(word$)
				word$ = GetWord()
			EndIf
			; 		Debug "word$ = |" + word$ + "|"
			arg$ = ReplaceString(arg$, "${Word}", word$, #PB_String_NoCase, pos)
		EndIf
	EndIf

; 	Debug exe$ + " " + arg$

	RunProgram(exe$, arg$, GetPathPart(exe$))
EndProcedure

; Procedure GetCodeHotkey(HotkeyString$)
; 	Protected pos, hotkey
; 	pos = FindString(HotkeyString$, "Ctrl", 1, #PB_String_NoCase)
; 	If pos
; 		HotkeyString$ = ReplaceString(HotkeyString$, "Ctrl", "", #PB_String_NoCase, pos)
; 		hotkey | #PB_Shortcut_Control
; 	EndIf
; 	pos = FindString(HotkeyString$, "Shift", 1, #PB_String_NoCase)
; 	If pos
; 		HotkeyString$ = ReplaceString(HotkeyString$, "Shift", "", #PB_String_NoCase, pos)
; 		hotkey | #PB_Shortcut_Shift
; 	EndIf
; 	pos = FindString(HotkeyString$, "Alt", 1, #PB_String_NoCase)
; 	If pos
; 		HotkeyString$ = ReplaceString(HotkeyString$, "Alt", "", #PB_String_NoCase, pos)
; 		hotkey | #PB_Shortcut_Alt
; 	EndIf
; 	HotkeyString$ = ReplaceString(HotkeyString$, " ", "")
; 	HotkeyString$ = ReplaceString(HotkeyString$, "+", "")
; 	If Len(HotkeyString$) = 1 And Asc(HotkeyString$) > 64 And Asc(HotkeyString$) < 91
; 		hotkey | (Asc(UCase(HotkeyString$)))
; 		Debug hotkey
; 		ProcedureReturn hotkey
; 	Else
; 		ProcedureReturn 0
; 	EndIf
; EndProcedure


Procedure Start(LastItem)
	Protected tmp$, flgExists = 1
	Protected iniStart$, name$
	Protected n, tmp


	iniStart$ = PathConfig$ + "Start.ini"
	If FileSize(iniStart$) > -1 And OpenPreferences(iniStart$)
		ExaminePreferenceGroups()
		While NextPreferenceGroup()
; 			Group$ = PreferenceGroupName()
			If PreferenceGroup(PreferenceGroupName())


				name$ = ReadPreferenceString("name", "")
				If Asc(name$)
					If flgExists
						flgExists = 0
						MenuTitle("Запуск")
					EndIf
					tmp$ = ReadPreferenceString("exe", "")
					If Asc(tmp$)
						n + 1
						ReDim g_MenuItemStart(n)
						g_MenuItemStart(n)\exe = tmp$
						g_MenuItemStart(n)\arg = ReadPreferenceString("arg", "")
						g_MenuItemStart(n)\hotkey = ReadPreferenceString("hotkey", "")
						If Asc(g_MenuItemStart(n)\hotkey)
							tmp = ParseShortcut(g_MenuItemStart(n)\hotkey)
							If tmp
								MenuItem(LastItem + n, name$ + #TAB$ + g_MenuItemStart(n)\hotkey)
								AddKeyboardShortcut(#Window, tmp, LastItem + n)
							Else
								MenuItem(LastItem + n, name$)
							EndIf
						Else
							MenuItem(LastItem + n, name$)
						EndIf
					EndIf
				EndIf

			EndIf
		Wend

		ClosePreferences()
	EndIf
EndProcedure

Procedure GetPlugin(LastItem)
	Protected i, tmp$, flgExists = 1, flgExists2
	Protected *FuncsArraySize.Integer
	Protected *FArray
	Protected *pname
	Protected *FuncItem0.FuncItem
	Protected n
	If ExamineDirectory(0, PathConfig$ + "Plugins" + #PS$, "*")
		While NextDirectoryEntry(0)
			If DirectoryEntryType(0) = #PB_DirectoryEntry_Directory
				If DirectoryEntryName(0) = "." Or DirectoryEntryName(0) = ".."
					Continue
				EndIf
				CompilerSelect #PB_Compiler_OS
					CompilerCase #PB_OS_Windows
						tmp$ = PathConfig$ + "Plugins" + #PS$ + DirectoryEntryName(0) + #PS$ + DirectoryEntryName(0) + ".dll"
					CompilerCase #PB_OS_Linux
						tmp$ = PathConfig$ + "Plugins" + #PS$ + DirectoryEntryName(0) + #PS$ + DirectoryEntryName(0) + ".so"
				CompilerEndSelect

				If FileSize(tmp$) And AddElement(LDirName())
					LDirName()\fname = DirectoryEntryName(0)
					LDirName()\path = tmp$
				EndIf
			EndIf
		Wend
		FinishDirectory(0)
	EndIf
	If ListSize(LDirName())

		ForEach LDirName()
			LDirName()\id = OpenLibrary(#PB_Any, LDirName()\path)
			If Not LDirName()\id
				Continue
			EndIf
; 			*pname = CallCFunction(LDirName()\id, "AttachProcess2")
; 			If Not *pname
; 				Continue
; 			EndIf
			*pname = CallCFunction(LDirName()\id, "getName")
			If Not *pname
				Continue
			EndIf
			LDirName()\pname = PeekS(*pname)
			*FArray = CallCFunction(LDirName()\id, "getFuncsArray", @*FuncsArraySize)
; 			getFuncsArray.getFuncsArray = GetFunction(LDirName()\id, "getFuncsArray")
; 			*FArray = getFuncsArray(@*FuncsArraySize)
			If Not *FArray
; 				Debug *FArray
				Continue
			EndIf
			If Not *FuncsArraySize
				Continue
			EndIf






; 			для каждой dll вызываем "setInfo", чтобы передать функции указатель на дескриптора окна и Scintilla
			; здесь мы пытемся передать плагу указатели на дескрипторы, чтобы плаг мог работать со Scintilla


			CompilerIf #PB_Compiler_OS = #PB_OS_Linux
				NppData\_scintillaDirectP = Docum()\DirectP
				NppData\_scintillaDirectF = Docum()\DirectF
			CompilerEndIf


			CompilerIf #PB_Compiler_Processor = #PB_Processor_x86

				CompilerSelect #PB_Compiler_OS
					CompilerCase #PB_OS_Windows
						CallCFunction(LDirName()\id, "setInfo", NppData\_nppHandle, NppData\_scintillaMainHandle, NppData\_scintillaSecondHandle)
					CompilerCase #PB_OS_Linux
						CallCFunction(LDirName()\id, "setInfo", NppData\_nppHandle, NppData\_scintillaMainHandle, NppData\_scintillaSecondHandle, NppData\_scintillaDirectP, NppData\_scintillaDirectF)
				CompilerEndSelect

			CompilerElse ; иначе для x64
				CallCFunction(LDirName()\id, "setInfo", @NppData)
			CompilerEndIf



			LDirName()\FuncsArraySize = *FuncsArraySize - 1
			ReDim LDirName()\FuncsArray1(LDirName()\FuncsArraySize)
			For i = 0 To LDirName()\FuncsArraySize
				*FuncItem0 = *FArray + i * SizeOf(FuncItem)
				CopyStructure(*FuncItem0, LDirName()\FuncsArray1(i), FuncItem)
			Next
			; 		LDirName()\FuncsArray1(0) = *FArray
			flgExists2 = 1
			For i = 0 To LDirName()\FuncsArraySize
				If Asc(LDirName()\FuncsArray1(i)\_itemName)
					If flgExists2
						If flgExists
							flgExists = 0
							MenuTitle("Плагины")
						EndIf
						flgExists2 = 0
						OpenSubMenu(LDirName()\pname)
					EndIf
					n + 1
					MenuItem(LastItem + n, LDirName()\FuncsArray1(i)\_itemName)
					ReDim g_MenuItemFunc(n)
					g_MenuItemFunc(n) = LDirName()\FuncsArray1(i)\_pFunc
; 					Debug LDirName()\FuncsArray1(i)\_itemName
				EndIf
			Next
			If Not flgExists2
				flgExists2 = 0
				CloseSubMenu()
			EndIf
		Next
	EndIf
EndProcedure



CompilerIf #PB_Compiler_OS = #PB_OS_Windows
#ASSOCSTR_DEFAULTICON = 15
; #ASSOCSTR_PROGID = 20 ; получить ProgID файла
#ASSOCF_NONE = 0

Procedure.i GetExtensionIcon(FileName.s, LargeIcon = 0)
	Protected hIcon, Path$ ; , path.String
	Protected LenStr = #MAX_PATH
	Protected AssIcon$ = Space(LenStr)
; 	path\s = Space(#MAX_PATH)
	
	FileName = "." + FileName
	If AssocQueryString_(#ASSOCF_NONE, #ASSOCSTR_DEFAULTICON, @FileName , 0, @AssIcon$, @LenStr) = #S_OK
		Path$ = StringField(AssIcon$, 1, ",")
		Path$ = Trim(Path$, #q$)
; 		PokeS(@path\s, Path$)
		ExtractIconEx_(@Path$, Val(StringField(AssIcon$, 2, ",")), 0, @hIcon, 1)
		If Not hIcon
			hIcon = ImageID(1)
		EndIf
	Else
		hIcon = ImageID(2)
	EndIf
	ProcedureReturn hIcon
EndProcedure
CompilerEndIf

Procedure AddDocum(Path$)
	Protected ind, *Element, *buffer;, flgFile0 = 1
	Protected tmp$, i, file_id, bytes, length, flgAFileExists
; 	Protected flgPath, CountTab
	CountTab = CountTabBarGadgetItems(#Gadget_TabBar)
	*Element = AddElement(Docum())
	If *Element
; 		LastGadget = #LastGadget
; 		SciGadget = LastGadget
; 		Docum()\id = SciGadget
		If Asc(Path$)
; 			flgPath = 1
			If CountTab
				OpenGadgetList(Container_id)
			EndIf
			Docum()\path = Path$
			Docum()\ext = GetExtensionPart(Path$)
			
			CompilerSelect #PB_Compiler_OS
				CompilerCase #PB_OS_Windows
					Docum()\hicon = GetExtensionIcon(Docum()\ext)
					AddTabBarGadgetItem(#Gadget_TabBar, CountTab, GetFilePart(Path$), Docum()\hicon)
				CompilerCase #PB_OS_Linux
					AddTabBarGadgetItem(#Gadget_TabBar, CountTab, GetFilePart(Path$))
			CompilerEndSelect
			
; 			Если была одна пустая вкладка без отмен, то открываем файл в ней
			If CountTab = 1 And ScintillaSendMessage(SciGadget, #SCI_GETLENGTH) = 0 And ScintillaSendMessage(SciGadget, #SCI_CANUNDO) = 0 And ScintillaSendMessage(SciGadget, #SCI_CANREDO) = 0
				FreeGadget(SciGadget)
				RemoveTabBarGadgetItem(#Gadget_TabBar, 0)
				CountTab = 0
				SelectElement(Docum(), 0)
				DeleteElement(Docum()) ; а может переназначить текущий вместо удаления?
				SelectElement(Docum(), 0)
; 				flgFile0 = 0
; 				CountTab = 0
; 				SetGadgetItemText(#Gadget_TabBar, CountTab, GetFilePart(Path$))
; 			Else
; 				AddTabBarGadgetItem(#Gadget_TabBar, CountTab, GetFilePart(Path$))
			EndIf
		Else
			If CountTab
				OpenGadgetList(Container_id)
			EndIf
			
			AddTabBarGadgetItem(#Gadget_TabBar, CountTab, "New" + Str(CountTab))
			Docum()\fs = #PB_UTF8
		EndIf
; 		If flgFile0
		ww = WindowWidth(#Window)
		hw = WindowHeight(#Window)
		If CountTab
			HideGadget(SciGadget, #True)
; 			DisableGadget(SciGadget , #True)
; 			ResizeGadget(SciGadget, ww, hw, #PB_Ignore, #PB_Ignore)
		EndIf
		
		CompilerSelect #PB_Compiler_OS
			CompilerCase #PB_OS_Windows
				Docum()\id = ScintillaGadget(#PB_Any, 0, 0, GadgetWidth(Container_id), GadgetHeight(Container_id), @SciNotification())
			CompilerCase #PB_OS_Linux
				Docum()\id = ScintillaGadget(#PB_Any, 0, 0, GadgetWidth(Container_id) - 4, GadgetHeight(Container_id) - 4, @SciNotification())
		CompilerEndSelect
; 		HideGadget(Docum()\id, #False)
; 		Debug Docum()\id
; 		Debug GadgetHeight(#Gadget_TabBar)
; 		Debug GadgetHeight(Docum()\id)
; 		Debug GadgetWidth(Docum()\id)
		CompilerIf #PB_Compiler_OS = #PB_OS_Linux
			Docum()\DirectF = ScintillaSendMessage(Docum()\id, #SCI_GETDIRECTFUNCTION, 0, 0)
			Docum()\DirectP = ScintillaSendMessage(Docum()\id, #SCI_GETDIRECTPOINTER, 0, 0)


			If CountTab <> 0
				NppData\_scintillaDirectP = Docum()\DirectP
				NppData\_scintillaDirectF = Docum()\DirectF
				ForEach LDirName()
					CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
						CallCFunction(LDirName()\id, "setInfo", NppData\_nppHandle, NppData\_scintillaMainHandle, NppData\_scintillaSecondHandle, NppData\_scintillaDirectP, NppData\_scintillaDirectF)
					CompilerElse ; иначе для x64
						CallCFunction(LDirName()\id, "setInfo", @NppData)
					CompilerEndIf
				Next
			EndIf

		CompilerEndIf

; 		EndIf
		If CountTab
			CloseGadgetList()
		EndIf
		EnableGadgetDrop(Docum()\id, #PB_Drop_Files, #PB_Drag_Copy)
; 		ind = GetGadgetState(#Gadget_TabBar)
; 		SetGadgetState(#Gadget_TabBar, CountTab)
		SetTabBarGadgetItemState(#Gadget_TabBar, CountTab, #TabBarGadget_Selected, #TabBarGadget_Selected)
		SetTabBarGadgetItemData(#Gadget_TabBar, CountTab, *Element) 
		SciGadget = Docum()\id
		SetActiveGadget(SciGadget)
		Docum()\hwnd = GadgetID(Docum()\id)
		CompilerIf #PB_Compiler_OS = #PB_OS_Windows
			; 	SetWindowLongPtr_(Docum()\hwnd, #GWL_STYLE, GetWindowLongPtr_(Docum()\hwnd, #GWL_STYLE) | #WS_BORDER)
			SetWindowLongPtr_(Docum()\hwnd, #GWL_EXSTYLE, GetWindowLongPtr_(Docum()\hwnd, #GWL_EXSTYLE) ! #WS_EX_CLIENTEDGE)
			; 	SetWindowLongPtr_(Docum()\hwnd, #GWL_EXSTYLE, GetWindowLongPtr_(Docum()\hwnd, #GWL_EXSTYLE) | #WS_EX_STATICEDGE)
			SetWindowLongPtr_(Docum()\hwnd, #GWL_EXSTYLE, GetWindowLongPtr_(Docum()\hwnd, #GWL_EXSTYLE) | #WS_EX_WINDOWEDGE)
			SetWindowLongPtr_(Docum()\hwnd, #GWL_STYLE, GetWindowLongPtr_(Docum()\hwnd, #GWL_STYLE) | #WS_BORDER)
		CompilerEndIf

		; Устанавливает режим текста

		ScintillaSendMessage(SciGadget, #SCI_SETWRAPMODE, #SC_WRAP_WORD) ; с переносами строк
		ScintillaSendMessage(SciGadget, #SCI_SETTABWIDTH, 4) ; ширина табуляции 4
		; ScintillaSendMessage(SciGadget, #SCI_SETWRAPSTARTINDENT, #SC_WRAPVISUALFLAG_START) ; начальный отступ
		; такой же отступ, если строка не умещается в окно и переносится на следующую. Это не тоже самое что отступ по нажатию Enter
; 		ScintillaSendMessage(SciGadget, #SCI_SETWRAPINDENTMODE, #SC_WRAPINDENT_SAME)

		ScintillaSendMessage(SciGadget, #SCI_STYLESETSIZE, #STYLE_DEFAULT, fontsize) ; размер шрифта
		ScintillaSendMessage(SciGadget, #SCI_STYLECLEARALL)        ; общий стиль для всех - не, это очистить стили
	  ; ScintillaSendMessage(SciGadget, #SCI_STYLESETSIZEFRACTIONAL, #SCI_STYLECLEARALL, 1100) ; размер шрифта
		ScintillaSendMessage(SciGadget, #SCI_SETCODEPAGE, #SC_CP_UTF8)      ; в кодировке UTF-8
		ScintillaSendMessage(SciGadget, #SCI_SETCARETSTICKY, 1)       ; делает всегда видимым (?)
		ScintillaSendMessage(SciGadget, #SCI_SETCARETWIDTH, 1)        ; толщина текстовго курсора
		ScintillaSendMessage(SciGadget, #SCI_SETCARETFORE, caret)       ; цвет текстовго курсора
		ScintillaSendMessage(SciGadget, #SCI_SETSELBACK, 1, select_bg)      ; цвет фона выделения
	;	ScintillaSendMessage(SciGadget, #SCI_SETSELFORE, 1, select_fnt); цвет текста выделения
		ScintillaSendMessage(SciGadget, #SCI_SETSELALPHA, selttransp)        ; прозрачность выделения
		ScintillaSendMessage(SciGadget, #SCI_SETMULTIPLESELECTION, 0)      ; мультивыделение
		ScintillaSendMessage(SciGadget, #SCI_STYLESETBACK, #STYLE_DEFAULT, background)    ; цвет фона
		ScintillaSendMessage(SciGadget, #SCI_STYLESETFORE, #STYLE_DEFAULT, color_default) ; цвет текста
		ScintillaSendMessage(SciGadget, #SCI_STYLECLEARALL) ; второй раз применение
; 		Docum()\eol = ScintillaSendMessage(SciGadget, #SCI_GETEOLMODE) ; CRLF?
; 		ScintillaSendMessage(SciGadget, #SCI_SETEOLMODE, 0) ; 0=CRLF

		; После раскоментирования этих строк проблема с ANSI, русские буквы становятся в 1252 кодировке вроде.
		; Выяснил причину - #SCI_STYLECLEARALL сбрасыват стиль и приводит к проблеме причём
		; с проблемным шрифтом (NanumGothic, Leelawadee и ещё некоторые шрифты Linux на Windows).
		*buffer = UTF8(ini_fnt$)
		ScintillaSendMessage(SciGadget, #SCI_STYLESETFONT, #STYLE_DEFAULT, *buffer)
		FreeMemory(*buffer)

		ScintillaSendMessage(SciGadget, #SCI_SETCARETLINEVISIBLE, #True)
		ScintillaSendMessage(SciGadget, #SCI_SETCARETLINEBACK, caretline) ; цвет подсвеченной строки
		ScintillaSendMessage(SciGadget, #SCI_SETCONTROLCHARSYMBOL, 1) ; символы менее 32
		; ScintillaSendMessage(SciGadget, #SCI_SETHSCROLLBAR, 0)      ; не показывать горизонтальную прокрутку
		; ScintillaSendMessage(SciGadget, #SCI_SETVSCROLLBAR, 0)      ; не показывать вертикальную прокрутку
		If numfield
; 			*buffer = UTF8("_999")
; 			Debug ScintillaSendMessage(SciGadget, #SCI_TEXTWIDTH, #STYLE_LINENUMBER, *buffer)
; 			FreeMemory(*buffer)
; 			Debug ScintillaSendMessage(SciGadget, #SCI_TEXTWIDTH, #STYLE_LINENUMBER, @"-999")	  ; Определить ширину текста в пикселях
			ScintillaSendMessage(SciGadget, #SCI_SETMARGINWIDTHN, 0, numfield * fontsize * 0.87)	  ; Устанавливает ширину поля 0 (номеров строк)
; 			ScintillaSendMessage(SciGadget, #SCI_SETFOLDMARGINCOLOUR, 0, $222222)  ; цвет?
			ScintillaSendMessage(SciGadget, #SCI_STYLESETBACK, #STYLE_LINENUMBER, linenumb)
			ScintillaSendMessage(SciGadget, #SCI_STYLESETFORE, #STYLE_LINENUMBER, linenumf)
			ScintillaSendMessage(SciGadget, #SCI_SETMARGINWIDTHN, 1, 0)		  ; Устанавливает ширину поля 1 (свёртки)
		Else
			ScintillaSendMessage(SciGadget, #SCI_SETMARGINWIDTHN, 0, 0)   ; Устанавливает ширину поля 0 (номеров строк)
			ScintillaSendMessage(SciGadget, #SCI_SETMARGINWIDTHN, 1, 0)	  ; Устанавливает ширину поля 1 (свёртки)
		EndIf
		; ScintillaSendMessage(SciGadget, #SCI_SETIDLESTYLING, #SC_IDLESTYLING_AFTERVISIBLE)	; сначала подсветить видимый и до вижимого, остальное фоном, работает вероятно только для встроенных лексеров.
		ScintillaSendMessage(SciGadget, #SCI_SETIDLESTYLING, #SC_IDLESTYLING_ALL) ; подсвечивает только видимый, остальное фоном, работает вероятно только для встроенных лексеров.
		; ScintillaSendMessage(SciGadget, #SCI_SETIDLESTYLING, #SC_IDLESTYLING_TOVISIBLE) ; подсвечивает только видимый, остальное фоном, работает вероятно только для встроенных лексеров.
		ScintillaSendMessage(SciGadget, #SCI_SETCARETLINEVISIBLEALWAYS, 1) ; каретка всегда видна
		; ScintillaSendMessage(SciGadget, #SCI_SETLEXER, #SCLEX_CONTAINER)
		ScintillaSendMessage(SciGadget, #SCI_SETSCROLLWIDTHTRACKING, 1, 1)	; Добавляет прокрутку по ширине текущих строк

		ScintillaSendMessage(SciGadget, #SCI_SETENDATLASTLINE, 0)    ; Прокрутка ниже последней строки

		; индикатор для пометки
		ScintillaSendMessage(SciGadget, #SCI_INDICSETSTYLE, #indic, #INDIC_STRAIGHTBOX)
		ScintillaSendMessage(SciGadget, #SCI_INDICSETFORE, #indic, indic)
		ScintillaSendMessage(SciGadget, #SCI_INDICSETALPHA, #indic, 105)
		ScintillaSendMessage(SciGadget, #SCI_INDICSETUNDER, #indic, 1)


		ScintillaSendMessage(SciGadget, #SCI_INDICSETSTYLE, #MarkSel, #INDIC_STRAIGHTBOX)
		ScintillaSendMessage(SciGadget, #SCI_INDICSETFORE, #MarkSel, MarkSel)
		ScintillaSendMessage(SciGadget, #SCI_INDICSETALPHA, #MarkSel, 105)
		ScintillaSendMessage(SciGadget, #SCI_INDICSETUNDER, #MarkSel, 1)
		ScintillaSendMessage(SciGadget, #SCI_SETINDICATORCURRENT, #MarkSel) ; делает индикатор под номером 4 текущим

; 		Debug ScintillaSendMessage(SciGadget, #SCI_GETDIRECTFUNCTION, 0, 0)
; 		Debug ScintillaSendMessage(SciGadget, #SCI_GETDIRECTPOINTER, 0, 0)
; 		Debug SendMessage_(GadgetID(SciGadget), #SCI_GETDIRECTPOINTER, 0, 0)


; 		*buffer=UTF8(Hex(SciGadget))
; 		ScintillaSendMessage(SciGadget, #SCI_SETTEXT, 0, *buffer)
; 		FreeMemory(*buffer)


		If flgAutoComplete And Asc(Docum()\ext)
			flgAFileExists = 0
			; можно сделать отдельной функцией
			; найти существует ли уже элемент

			For i = 0 To ArraySize(AComplete())
				If Docum()\ext = AComplete(i)\ext
					Docum()\acomplete = i
					flgAFileExists = 1
; 					Debug Docum()\acomplete
					Break
				EndIf
			Next
; 			ForEach AComplete(i)\ext()
; 				; Debug AComplete(i)\ext()
; 				; двойной поиск одного в другом, чтобы исключить частичное совпадение, при этом без учёта регистра
; 				; если использовать CompareMemoryString(), то требуется получать указатели с массив\список AComplete(i)\ext()
; 				; *Result = SelectElement(AComplete(i)\ext(), ListIndex(AComplete(i)\ext()))
; 				If CompareMemoryString(PeekI(SelectElement(AComplete(i)\ext(), ListIndex(AComplete(i)\ext()))), @Ext$, #PB_String_NoCase) = #PB_String_Equal
; 				EndIf
; 			Next


; 			если ещё не открыт нужный AutoComplete, то проверяем есть ли конфиг AutoComplete для текущего расширения файла
			If Not Docum()\acomplete
				tmp$ = PathConfig$ + "AutoComplete" + #PS$ + Docum()\ext + ".txt"
; 				если файл автозавершения существует то добавить элемент
				If FileSize(tmp$) > 0
					i = ArraySize(AComplete()) + 1
					ReDim AComplete(i)
					Docum()\acomplete = i
; 					Debug Docum()\acomplete
					AComplete(i)\autocompletepath = tmp$
					AComplete(i)\ext = Docum()\ext
					AComplete(i)\autocompleteflg = 1
					AComplete(i)\CanceledByChar = UTF8(";,' .") ; это символ, на котором обрывается набор слова

					file_id = ReadFile(#PB_Any, AComplete(i)\autocompletepath, #PB_UTF8)
					If file_id
						length = Lof(file_id)
						If length
							AComplete(i)\autocompList = AllocateMemory(length)
							If AComplete(i)\autocompList
								bytes = ReadData(file_id, AComplete(i)\autocompList, length)
								AComplete(i)\autocompText = PeekS(AComplete(i)\autocompList, -1, #PB_UTF8)
								flgAFileExists = 1
							EndIf
						EndIf
						CloseFile(file_id)
					EndIf
					AComplete(i)\autocompletepath = Left(AComplete(i)\autocompletepath, Len(AComplete(i)\autocompletepath) - 4) + #PS$

				EndIf
			EndIf


			If flgAFileExists ; настроки автозавершения для документа если он существует в массиве AComplete(), т.е. найден по расширению или открыт.
				; установить настройки CHARACTER (автодополнение, выбор и другие функции используют эти настройки)
				; Задать набор символов, которые являются элементами слов
				; Исправить значения дополнительных символов @# должны быть добавлены индивидуально для языка, в AutoIt3 - да, в PureBasic - нет.
				*buffer=UTF8("@#abcdefghijklmnopqrstuvwxyz_ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
				ScintillaSendMessage(SciGadget, #SCI_SETWORDCHARS, 0, *buffer)
				FreeMemory(*buffer)
				;ScintillaSendMessage(SciGadget, #SCI_SETWHITESPACECHARS, 0, MakeUTF8Text(" " + #TAB$ + #CR$ + #LF$))  ;<= Uncomment this line if you want change default values
				;ScintillaSendMessage(SciGadget, #SCI_SETPUNCTUATIONCHARS, 0, MakeUTF8Text("(){}[];:,'"+#DQUOTE$))     ;<= Uncomment this line if you want change default values

				; AComplete(i)\SelectedByChar =  UTF8("|({")
				; Global *autocompAutoCanceledByCharacters = UTF8(";,' .")
				; Global *autocompAutoSelectedByCharacters = UTF8("|({")

				ScintillaSendMessage(SciGadget, #SCI_AUTOCSETMAXHEIGHT, 30)
				ScintillaSendMessage(SciGadget, #SCI_AUTOCSETMAXWIDTH, 400)
				ScintillaSendMessage(SciGadget, #SCI_AUTOCSETAUTOHIDE, #True)    ;True => автоматически скрыть, если нет совпадения
				ScintillaSendMessage(SciGadget, #SCI_AUTOCSETCHOOSESINGLE, #False) ;True => автоматический выбор, если только одно совпадение
				ScintillaSendMessage(SciGadget, #SCI_AUTOCSETIGNORECASE, #True)	   ;True => выполнить безрегистровый поиск ('a' = 'A')
				ScintillaSendMessage(SciGadget, #SCI_AUTOCSTOPS, 0, AComplete(i)\CanceledByChar)
				; ScintillaSendMessage(SciGadget, #SCI_AUTOCSETFILLUPS, 0, AComplete(i)\SelectedByChar)
				ScintillaSendMessage(SciGadget, #SCI_AUTOCSETSEPARATOR, #LF)
				ScintillaSendMessage(SciGadget, #SCI_AUTOCSETTYPESEPARATOR, ':')
				; ScintillaSendMessage(SciGadget, #SCI_AUTOCSETORDER, #SC_ORDER_PERFORMSORT) ;<= потому что мой список автодополнения неупорядочен
				ScintillaSendMessage(SciGadget, #SCI_AUTOCSETORDER, #SC_ORDER_PRESORTED) ;<= список отсортирован
			EndIf



		EndIf
	EndIf
EndProcedure

Procedure.s GetTextFile(Path$)
	Protected Result$, *buffer, file_id, length, bytes
; 	Debug Path$
	file_id = ReadFile(#PB_Any, Path$, #PB_UTF8)
	If file_id
	; 	Format = ReadStringFormat(file_id)
	; 	If Format = #PB_UTF8
			length = Lof(file_id)
			If length
				*buffer = AllocateMemory(length)
				If *buffer
					bytes = ReadData(file_id, *buffer, length)
					Result$ = PeekS(*buffer, bytes, #PB_UTF8)
					FreeMemory(*buffer)
				EndIf
			EndIf
	; 	EndIf
		CloseFile(file_id)
	Else
		Result$ = GetFilePart(Path$, #PB_FileSystem_NoExtension)
	EndIf
    ProcedureReturn Result$
EndProcedure

Procedure DropFiles(StringFiles$)
	Protected CountTab, i, tmp
	Protected NewList Files.s()
	SplitL(StringFiles$, Files(), Chr(10))

	ForEach Files()
		; поиск документа в открытых
		tmp = 1
		CountTab = CountTabBarGadgetItems(#Gadget_TabBar)
		For i = 0 To CountTab - 1
			*SelectElement = GetTabBarGadgetItemData(#Gadget_TabBar, i)
			If *SelectElement And *SelectElement\path = Files()
				SetTabBarGadgetItemState(#Gadget_TabBar, i, #TabBarGadget_Selected, #TabBarGadget_Selected)
				ChangeCurrentElement(Docum(), *SelectElement)
				HideGadget(SciGadget, #True)
				HideGadget(Docum()\id, #False)
				SciGadget = Docum()\id
				SetActiveGadget(SciGadget)
				tmp = 0
				Break ; сделали его текущим
					  ; 										Continue
			EndIf
		Next
		If tmp
			AddDocum(Files())
			OpenFileToSci(Files())
		EndIf
	Next
EndProcedure


Procedure SetFont(style)
	Protected FontSize, FontName$, color, *Font, Ext$, i
	color = ScintillaSendMessage(SciGadget, #SCI_STYLEGETFORE, style)
	FontName$ = Space(32)
; 	*buffer = AllocateMemory(33)
	ScintillaSendMessage(SciGadget, #SCI_STYLEGETFONT, style, @FontName$)
	FontSize = ScintillaSendMessage(SciGadget, #SCI_STYLEGETSIZE, style)
	FontName$ = PeekS(@FontName$, -1, #PB_UTF8) ; если не считать как UTF8, то будет как UTF16, т.е. неверно
	If FontRequester(FontName$, FontSize, #PB_FontRequester_Effects, color)
		FontName$ = SelectedFontName()
		FontSize = SelectedFontSize()
		color = SelectedFontColor()
		If SelectedFontStyle() & #PB_Font_Bold
			ScintillaSendMessage(SciGadget, #SCI_STYLESETBOLD, style, 1)
		Else
			ScintillaSendMessage(SciGadget, #SCI_STYLESETBOLD, style, 0)
		EndIf
; 		If SelectedFontStyle() & #PB_Font_StrikeOut
; 			ScintillaSendMessage(SciGadget, #SCI_STYLESET..., style, 1)
; 		EndIf
; 		If SelectedFontStyle() & #PB_Font_Underline
; 			ScintillaSendMessage(SciGadget, #SCI_STYLESET..., style, 1)
; 		EndIf
		*Font = UTF8(FontName$)
		ScintillaSendMessage(SciGadget, #SCI_STYLESETFONT, style, *Font)
		ScintillaSendMessage(SciGadget, #SCI_STYLESETSIZE, style, FontSize) ; размер шрифта
		ScintillaSendMessage(SciGadget, #SCI_STYLESETFORE, style, color)
		ScintillaSendMessage(SciGadget, #SCI_STYLECLEARALL)        ; общий стиль для всех


		If numfield
; 			*Buffer = UTF8("_999")
; 			Debug ScintillaSendMessage(SciGadget, #SCI_TEXTWIDTH, #STYLE_LINENUMBER, *Buffer)
; 			FreeMemory(*Buffer)
; 			Debug ScintillaSendMessage(SciGadget, #SCI_TEXTWIDTH, #STYLE_LINENUMBER, @"-999")	  ; Определить ширину текста в пикселях
			ScintillaSendMessage(SciGadget, #SCI_SETMARGINWIDTHN, 0, numfield * FontSize * 0.87)	  ; Устанавливает ширину поля 0 (номеров строк)
; 			ScintillaSendMessage(SciGadget, #SCI_SETFOLDMARGINCOLOUR, 0, $222222)  ; цвет?
			ScintillaSendMessage(SciGadget, #SCI_STYLESETBACK, #STYLE_LINENUMBER, $222222)
			ScintillaSendMessage(SciGadget, #SCI_STYLESETFORE, #STYLE_LINENUMBER, $aaaaaa)
		Else
			ScintillaSendMessage(SciGadget, #SCI_SETMARGINWIDTHN, 0, 0)   ; Устанавливает ширину поля 0 (номеров строк)
		EndIf


		For i = LastItem1 To LastItem2
			If GetMenuItemState(#Menu, i) = 1
				Ext$ = GetMenuItemText(#Menu, i)
				Break
			EndIf
		Next
		If Asc(Ext$)
			ColorSet(Ext$)
			ReColor()
		EndIf
; 		ForEach regex()
; 			ScintillaSendMessage(SciGadget, #SCI_STYLESETFONT, regex()\id, *Font)
; 			ScintillaSendMessage(SciGadget, #SCI_STYLESETFORE, regex()\id, color)		   ; цвет фона
; 			ScintillaSendMessage(SciGadget, #SCI_STYLESETSIZE, regex()\id, FontSize) ; размер шрифта
; 		Next
		FreeMemory(*Font)

	EndIf

EndProcedure


Procedure SetBG()
	Protected background
	background = ColorRequester()
	If background > -1
		ScintillaSendMessage(SciGadget, #SCI_STYLESETBACK, #STYLE_DEFAULT, background)    ; цвет фона
		ScintillaSendMessage(SciGadget, #SCI_STYLESETBACK, #STYLE_0, background)     ; цвет фона
		ForEach HLightRegex(Docum()\hlight)\regex()
			ScintillaSendMessage(SciGadget, #SCI_STYLESETBACK, HLightRegex(Docum()\hlight)\regex()\id, background)		   ; цвет фона
		Next
		ScintillaSendMessage(SciGadget, #SCI_STYLESETBACK, 0, background)		   ; цвет фона
; 		Protected i
; 		For i = 0 To 32
; 			ScintillaSendMessage(SciGadget, #SCI_STYLESETBACK, i, background)		   ; цвет фона
; 		Next
	EndIf
EndProcedure


Procedure DelCRLF()
	Protected length, firstMatchPos, SearchTxt$, *Search, ReplaceTxt$, *Replace, Count, lengthStr, inEnd
	SearchTxt$ = "[ 	]+$"
	ReplaceTxt$ = ""
	ScintillaSendMessage(SciGadget, #SCI_SETSEARCHFLAGS, #SCFIND_REGEXP | #SCFIND_POSIX)
	lengthStr = Len(SearchTxt$)
	*Search = Ascii(SearchTxt$)
	*Replace = Ascii(ReplaceTxt$)
	length = StringByteLength(SearchTxt$, #PB_Ascii)
	ScintillaSendMessage(SciGadget, #SCI_BEGINUNDOACTION)
	firstMatchPos = 0
	Repeat
		; Устанавливает целевой диапазон поиска
		inEnd = ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH) ; получает длину текста после замены
		ScintillaSendMessage(SciGadget, #SCI_SETTARGETSTART, firstMatchPos)    ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
		ScintillaSendMessage(SciGadget, #SCI_SETTARGETEND, inEnd)    ; до конца по длине текста
																				; 		нашли
		firstMatchPos = ScintillaSendMessage(SciGadget, #SCI_SEARCHINTARGET, length, *Search)
		If firstMatchPos = -1
			; 			выпрыг если не найдено
			Break
		EndIf
		Count + 1
		; заменили
		ScintillaSendMessage(SciGadget, #SCI_REPLACETARGETRE, -1, *Replace)
	ForEver
	FreeMemory(*Search)
	FreeMemory(*Replace)
	ScintillaSendMessage(SciGadget, #SCI_ENDUNDOACTION)
	; 	SetGadgetText(#txt4 , "Удалено: " + Str(Count))
EndProcedure


Procedure GetFlag(flag)
	If GetGadgetState(#chCase) & #PB_Checkbox_Checked
		flag | #SCFIND_MATCHCASE
	EndIf
	If GetGadgetState(#chRegExp) & #PB_Checkbox_Checked
		flag | #SCFIND_REGEXP | #SCFIND_POSIX
	EndIf
	If GetGadgetState(#chWholeWord) & #PB_Checkbox_Checked
		flag | #SCFIND_WHOLEWORD
	EndIf
	If GetGadgetState(#chWordStart) & #PB_Checkbox_Checked
		flag | #SCFIND_WORDSTART
	EndIf
	ProcedureReturn flag
EndProcedure





Procedure btnReplaceAll(mode = 0)
	Protected length, length2, StartPos, EndPos, firstMatchPos, flag, SearchTxt$, *Search, ReplaceTxt$, format, *Replace, Count, chSel, lengthStr
	Protected inSrt, inEnd
	SearchTxt$ = GetGadgetText(#strg1)
	If Not Asc(SearchTxt$)
		ProcedureReturn
	EndIf
	ReplaceTxt$ = GetGadgetText(#strg2)
	If SearchTxt$ = ReplaceTxt$
		ProcedureReturn
	EndIf
	chSel = GetGadgetState(#chSel) & #PB_Checkbox_Checked
	; Устанавливает целевой диапазон поиска
	If chSel
		inSrt = ScintillaSendMessage(SciGadget, #SCI_GETCURRENTPOS)
		inEnd = inSrt + ScintillaSendMessage(SciGadget, #SCI_GETSELTEXT, 0, 0)
	Else
		inSrt = 0
		inEnd = ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH) ; получает длину текста
	EndIf
	ScintillaSendMessage(SciGadget, #SCI_SETTARGETSTART, inSrt)    ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
	ScintillaSendMessage(SciGadget, #SCI_SETTARGETEND, inEnd)  ; до конца по длине текста
																	; 	ScintillaSendMessage(SciGadget, #SCI_SETTARGETRANGE, inSrt, inEnd) ; задать диапазон
																	; 	Debug ScintillaSendMessage(SciGadget, #SCI_GETTARGETSTART)
																	; 	Debug ScintillaSendMessage(SciGadget, #SCI_GETTARGETEND)
																	; 	Debug inSrt
																	; 	Debug inEnd
	flag = GetFlag(0)
	ScintillaSendMessage(SciGadget, #SCI_SETSEARCHFLAGS, flag)
	lengthStr = Len(SearchTxt$)
	length2 = Len(ReplaceTxt$)
	format = ScintillaSendMessage(SciGadget, #SCI_GETCODEPAGE)
	Select format
		Case 0
			*Search = Ascii(SearchTxt$)
			*Replace = Ascii(ReplaceTxt$)
			length = StringByteLength(SearchTxt$, #PB_Ascii)
		Case #SC_CP_UTF8
			*Search = UTF8(SearchTxt$)
			*Replace = UTF8(ReplaceTxt$)
			length = StringByteLength(SearchTxt$, #PB_UTF8)
		Default
			*Search = @SearchTxt$
			*Replace = @tmp$
			length = StringByteLength(SearchTxt$, #PB_Unicode)
	EndSelect
	ScintillaSendMessage(SciGadget, #SCI_BEGINUNDOACTION)
	Repeat
		; 		нашли
		firstMatchPos = ScintillaSendMessage(SciGadget, #SCI_SEARCHINTARGET, length, *Search)
		; 		Debug firstMatchPos
		If firstMatchPos = -1
			; 			выпрыг если не найдено
			Break
		EndIf
		If chSel And (firstMatchPos + length >= inEnd)
			Break
		EndIf
		Count + 1
		If mode
			ScintillaSendMessage(SciGadget, #SCI_SETTARGETSTART, firstMatchPos + lengthStr)
			ScintillaSendMessage(SciGadget, #SCI_SETTARGETEND, inEnd)
		Else
			If MarkColor
				; 				ScintillaSendMessage(SciGadget, #SCI_INDICATORFILLRANGE, firstMatchPos, firstMatchPos + lengthStr)  ; выделяет текст используя текущий индикатор
				StartPos = ScintillaSendMessage(SciGadget, #SCI_GETTARGETSTART)        ; получает позицию начала найденного
				EndPos = ScintillaSendMessage(SciGadget, #SCI_GETTARGETEND)   ; получает позицию конца найденного
				length2 = EndPos - StartPos
				ScintillaSendMessage(SciGadget, #SCI_INDICATORFILLRANGE, StartPos, length2)  ; выделяет текст используя текущий индикатор
			Else
				; 		выделили
				ScintillaSendMessage(SciGadget, #SCI_SETTARGETRANGE, firstMatchPos + lengthStr, firstMatchPos) ; задать диапазон для замены
																												; 		заменили
				If flag & #SCFIND_REGEXP
					length2 = ScintillaSendMessage(SciGadget, #SCI_REPLACETARGETRE, -1, *Replace)
				Else
					length2 = ScintillaSendMessage(SciGadget, #SCI_REPLACETARGET, -1, *Replace)
				EndIf
			EndIf
			inSrt = firstMatchPos + length2 ; задать диапазон поиска
											; 			inSrt = ScintillaSendMessage(SciGadget, #SCI_GETTARGETEND) ; задать диапазон поиска
			If chSel
				; 				Проблема с началом выделенного диапазона
				inEnd = inEnd + length2 - lengthStr
			Else
				; Устанавливает целевой диапазон поиска
				inEnd = ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH) ; получает длину текста
			EndIf
			; 			ScintillaSendMessage(SciGadget, #SCI_SETTARGETRANGE, inSrt, inEnd) ; задать диапазон поиска
			ScintillaSendMessage(SciGadget, #SCI_SETTARGETSTART, inSrt)    ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
			ScintillaSendMessage(SciGadget, #SCI_SETTARGETEND, inEnd)  ; до конца по длине текста
		EndIf
	ForEver
	If format = 0 Or format = #SC_CP_UTF8
		FreeMemory(*Search)
		FreeMemory(*Replace)
	EndIf
	ScintillaSendMessage(SciGadget, #SCI_ENDUNDOACTION)
	If mode
		SetGadgetText(#txt3 , "Найдено: " + Str(Count))
	Else
		If MarkColor
			SetGadgetText(#txt3 , "Подсвечено: " + Str(Count))
		Else
			SetGadgetText(#txt3 , "Замен: " + Str(Count))
		EndIf
	EndIf
	MarkColor = 0
EndProcedure


Procedure btnSearch(mode = 0)
	Protected length, StartPos, EndPos, firstMatchPos, flag, SearchTxt$, inSrt, inEnd, *Search, ReplaceTxt$, format, *Replace, lengthStr, chSel, length2
	Protected findStart, findEnd
	SearchTxt$ = GetGadgetText(#strg1)
	If Not Asc(SearchTxt$)
		ProcedureReturn
	EndIf
	inSrt = ScintillaSendMessage(SciGadget, #SCI_GETCURRENTPOS)
	chSel = GetGadgetState(#chSel) & #PB_Checkbox_Checked
	; Устанавливает целевой диапазон поиска
	If chSel
		inEnd = inSrt + ScintillaSendMessage(SciGadget, #SCI_GETSELTEXT, 0, 0)
	Else
		; 		inSrt = 0
		inEnd = ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH) ; получает длину текста
	EndIf
	ScintillaSendMessage(SciGadget, #SCI_SETTARGETSTART, inSrt)    ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
	ScintillaSendMessage(SciGadget, #SCI_SETTARGETEND, inEnd)  ; до конца по длине текста
	flag = GetFlag(0)
	ScintillaSendMessage(SciGadget, #SCI_SETSEARCHFLAGS, flag)
	lengthStr = Len(SearchTxt$)
	format = ScintillaSendMessage(SciGadget, #SCI_GETCODEPAGE)
	Select format
		Case 0
			*Search = Ascii(SearchTxt$)
			length = StringByteLength(SearchTxt$, #PB_Ascii)
		Case #SC_CP_UTF8
			*Search = UTF8(SearchTxt$)
			length = StringByteLength(SearchTxt$, #PB_UTF8)
		Default
			*Search = @SearchTxt$
			length = StringByteLength(SearchTxt$, #PB_Unicode)
	EndSelect
	firstMatchPos = ScintillaSendMessage(SciGadget, #SCI_SEARCHINTARGET, length, *Search)
	If format = 0 Or format = #SC_CP_UTF8
		FreeMemory(*Search)
	EndIf
	If firstMatchPos = -1
		If MessageRequester("С начала?", "Поиск закончен, с начала?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
			ScintillaSendMessage(SciGadget, #SCI_GOTOPOS, 0)
			ProcedureReturn
			; 			а как же вариант с выделенным? А как же автозапуск поиска, без повторного нажатия?
		Else
			ProcedureReturn
		EndIf
	EndIf
	If firstMatchPos + length >= inEnd
		ProcedureReturn
	EndIf

	; 	ScintillaSendMessage(SciGadget, #SCI_SEARCHNEXT)
	; 	Debug firstMatchPos
	; 	Debug firstMatchPos + length
	findStart = ScintillaSendMessage(SciGadget, #SCI_GETTARGETSTART)
	findEnd = ScintillaSendMessage(SciGadget, #SCI_GETTARGETEND)
	; 	tmp$ = Space(255)
	; 	ScintillaSendMessage(SciGadget, #SCI_GETTARGETTEXT, 0, @tmp$)
	; 	Debug tmp$

	ScintillaSendMessage(SciGadget, #SCI_GOTOPOS, firstMatchPos)
	ScintillaSendMessage(SciGadget, #SCI_SETSELECTION, findEnd, findStart)
	; 	ScintillaSendMessage(SciGadget, #SCI_SETSELECTION, firstMatchPos + lengthStr, firstMatchPos)
	; 	ScintillaSendMessage(SciGadget, #SCI_SETSELECTION, firstMatchPos, firstMatchPos + length)
	If mode
		ReplaceTxt$ = GetGadgetText(#strg2)
		If SearchTxt$ = ReplaceTxt$
			ProcedureReturn
		EndIf
		Select format
			Case 0
				*Replace = Ascii(ReplaceTxt$)
			Case #SC_CP_UTF8
				*Replace = UTF8(ReplaceTxt$)
			Default
				*Replace = @tmp$ ; исключить FreeMemory
		EndSelect

		; 		выделили
		ScintillaSendMessage(SciGadget, #SCI_SETTARGETRANGE, firstMatchPos + lengthStr, firstMatchPos) ; задать диапазон для замены
																										; 		заменили
		If flag & #SCFIND_REGEXP
			length2 = ScintillaSendMessage(SciGadget, #SCI_REPLACETARGETRE, -1, *Replace)
		Else
			ScintillaSendMessage(SciGadget, #SCI_REPLACETARGET, -1, *Replace)
		EndIf


		If chSel
			; 			Проблема с началом выделенного диапазона
			inEnd = inEnd + length2 - lengthStr
		Else
			; Устанавливает целевой диапазон поиска
			inEnd = ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH) ; получает длину текста
		EndIf
		ScintillaSendMessage(SciGadget, #SCI_SETTARGETSTART, inSrt)    ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
		ScintillaSendMessage(SciGadget, #SCI_SETTARGETEND, inEnd)  ; до конца по длине текста

		; 		ScintillaSendMessage(SciGadget, #SCI_REPLACESEL, 0, *Replace) ; в каком формате замена?
		If format = 0 Or format = #SC_CP_UTF8
			FreeMemory(*Replace)
		EndIf
		length = Len(ReplaceTxt$)
		ScintillaSendMessage(SciGadget, #SCI_SETSELECTION, firstMatchPos + length2, firstMatchPos)
	EndIf

EndProcedure

Procedure mANSI()
	Protected txtLen, *buffer
	ScintillaSendMessage(SciGadget, #SCI_SETCODEPAGE, #SC_CHARSET_ANSI)

	CompilerIf #PB_Compiler_OS = #PB_OS_Windows
		If Docum()\format = #frm866
			txtLen = ScintillaSendMessage(SciGadget, #SCI_GETLENGTH)          ; получает длину текста в байтах
			*buffer = AllocateMemory(txtLen + 2)								  ; Выделяем память на длину текста и 1 символ на Null
			If *buffer															  ; Если указатель получен, то
				ScintillaSendMessage(SciGadget, #SCI_GETTEXT, txtLen + 1, *buffer)        ; получает текста
				CharToOemBuffA(*buffer, *buffer, txtLen)
				ScintillaSendMessage(SciGadget, #SCI_SETTEXT, 0, *buffer)
				FreeMemory(*buffer)
			EndIf
		EndIf
	CompilerEndIf

; 	 сделать меню для переключения кодовой страницы, иначе это хорошо только для русскоязычных
	CompilerSelect #PB_Compiler_OS
		CompilerCase #PB_OS_Windows
			ScintillaSendMessage(SciGadget, #SCI_STYLESETCHARACTERSET, 0, #SC_CHARSET_RUSSIAN)
		CompilerCase #PB_OS_Linux
			ScintillaSendMessage(SciGadget, #SCI_STYLESETCHARACTERSET, 0, #SC_CHARSET_CYRILLIC)
		CompilerCase #PB_OS_MacOS
			ScintillaSendMessage(SciGadget, #SCI_STYLESETCHARACTERSET, 0, #SC_CHARSET_RUSSIAN)
	CompilerEndSelect

	SetMenuItemState(#Menu, #mANSI, 1)
	SetMenuItemState(#Menu, #mUTF8, 0)
	SetMenuItemState(#Menu, #mUTF16LE, 0)
	SetMenuItemState(#Menu, #m866, 0)
	Docum()\format = #PB_Ascii
	Docum()\fs = #PB_Ascii
EndProcedure


Procedure mUTF8nb()
	ScintillaSendMessage(SciGadget, #SCI_SETCODEPAGE, #SC_CP_UTF8)
	SetMenuItemState(#Menu, #mUTF8nb, 1)
	SetMenuItemState(#Menu, #mUTF8, 0)
	SetMenuItemState(#Menu, #mUTF16LE, 0)
	SetMenuItemState(#Menu, #mANSI, 0)
	SetMenuItemState(#Menu, #m866, 0)
	Docum()\format = #PB_UTF8
	Docum()\fs = #PB_UTF8
	Docum()\notbom = 1
EndProcedure


Procedure mUTF8()
	ScintillaSendMessage(SciGadget, #SCI_SETCODEPAGE, #SC_CP_UTF8)
	SetMenuItemState(#Menu, #mUTF8, 1)
	SetMenuItemState(#Menu, #mUTF16LE, 0)
	SetMenuItemState(#Menu, #mANSI, 0)
	SetMenuItemState(#Menu, #m866, 0)
	Docum()\format = #PB_UTF8
	Docum()\fs = #PB_UTF8
EndProcedure




CompilerIf #PB_Compiler_OS = #PB_OS_Windows
Procedure m866()
	Protected txtLen, *buffer;, *Buffer
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows
	; 	ScintillaSendMessage(SciGadget, #SCI_STYLESETCHARACTERSET, 0, #SC_CHARSET_OEM866)
	If Docum()\format = #frm866
		ProcedureReturn
	EndIf

	txtLen = ScintillaSendMessage(SciGadget, #SCI_GETLENGTH)          ; получает длину текста в байтах
	*buffer = AllocateMemory(txtLen + 2)           ; Выделяем память на длину текста и 1 символ на Null
	If *buffer                  ; Если указатель получен, то
		ScintillaSendMessage(SciGadget, #SCI_GETTEXT, txtLen + 1, *buffer)        ; получает текста

		If Docum()\fs = #PB_Ascii And Docum()\format = #PB_Ascii
			OemToCharBuffA(*buffer, *buffer, txtLen)
		EndIf
	EndIf

	ScintillaSendMessage(SciGadget, #SCI_SETTEXT, 0, *buffer)
	FreeMemory(*buffer)

	SetMenuItemState(#Menu, #m866, 1)
	SetMenuItemState(#Menu, #mANSI, 0)
	SetMenuItemState(#Menu, #mUTF8, 0)
	SetMenuItemState(#Menu, #mUTF8nb, 0)
	SetMenuItemState(#Menu, #mUTF16LE, 0)
	Docum()\format = #frm866
	Docum()\fs = #PB_Ascii
	ScintillaSendMessage(SciGadget, #SCI_SETCODEPAGE, #SC_CHARSET_ANSI)
	CompilerEndIf
EndProcedure
CompilerEndIf


Procedure mUTF16LE()
	ScintillaSendMessage(SciGadget, #SCI_SETCODEPAGE, #SC_CP_UTF8)
	SetMenuItemState(#Menu, #mUTF16LE, 1)
	SetMenuItemState(#Menu, #mUTF8, 0)
	SetMenuItemState(#Menu, #mANSI, 0)
	SetMenuItemState(#Menu, #m866, 0)
	Docum()\format = #PB_UTF8
	Docum()\fs = #PB_Unicode
EndProcedure


; Подсвечивание через стиль
Procedure ReColor()
	Protected tmp
	; красим всё в дефолтный стиль 0
	tmp = ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH)
	ScintillaSendMessage(SciGadget, #SCI_STARTSTYLING, 0, 0)        ; позиция начала (с 50-го)
	ScintillaSendMessage(SciGadget, #SCI_SETSTYLING, tmp, 0)     ; ширина и номер стиля
	; красим согласно новому синтаксису
	Color(HLightRegex(Docum()\hlight)\regex(), 0, tmp)
EndProcedure

; Подсвечивание через стиль
; Procedure Color(*regex, regexLength, style_id, posStart, posEnd)
; 	Protected txtLen, StartPos, EndPos, firstMatchPos
;
;
; 	EndPos = posStart
; 	Repeat
; 		ScintillaSendMessage(SciGadget, #SCI_SETTARGETSTART, EndPos)    ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
; 		ScintillaSendMessage(SciGadget, #SCI_SETTARGETEND, posEnd)   ; до конца по длине текста
; 		firstMatchPos = ScintillaSendMessage(SciGadget, #SCI_SEARCHINTARGET, regexLength, *regex) ; возвращает позицию первого найденного. В параметрах длина искомого и указатель
; 																								   ; 		Debug firstMatchPos
; 		If firstMatchPos > -1                    ; если больше -1, то есть найдено, то
; 			StartPos = ScintillaSendMessage(SciGadget, #SCI_GETTARGETSTART)        ; получает позицию начала найденного
; 			EndPos = ScintillaSendMessage(SciGadget, #SCI_GETTARGETEND)         ; получает позицию конца найденного
; 			ScintillaSendMessage(SciGadget, #SCI_STARTSTYLING, StartPos, $1F)        ; позиция начала (с 50-го)
; 			ScintillaSendMessage(SciGadget, #SCI_SETSTYLING, EndPos - StartPos, style_id)     ; ширина и номер стиля
; 		Else
; 			Break
; 		EndIf
; 	ForEver
; EndProcedure

Procedure Color(List regex.SciRegExp(), posStart, posEnd)
    Protected StartPos, EndPos, firstMatchPos

    ForEach regex()
    	EndPos = posStart
        Repeat
            ScintillaSendMessage(SciGadget, #SCI_SETTARGETSTART, EndPos) ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
            ScintillaSendMessage(SciGadget, #SCI_SETTARGETEND, posEnd) ; до конца по длине текста
            firstMatchPos = ScintillaSendMessage(SciGadget, #SCI_SEARCHINTARGET, regex()\len, regex()\mem) ; возвращает позицию первого найденного. В параметрах длина искомого и указатель
                                                                                                     ;         Debug firstMatchPos
            If firstMatchPos > -1 ; если больше -1, то есть найдено, то
                StartPos = ScintillaSendMessage(SciGadget, #SCI_GETTARGETSTART) ; получает позицию начала найденного
                EndPos = ScintillaSendMessage(SciGadget, #SCI_GETTARGETEND) ; получает позицию конца найденного
                ScintillaSendMessage(SciGadget, #SCI_STARTSTYLING, StartPos) ; позиция начала (с 50-го)
                ScintillaSendMessage(SciGadget, #SCI_SETSTYLING, EndPos - StartPos, regex()\id) ; ширина и номер стиля
    ;             Debug Str(StartPos) + " " + Str(EndPos) + " " + Str(EndPos - StartPos) + " " + Str(regex()\id)
            Else
                Break
            EndIf
        ForEver
    Next
EndProcedure


; Уведомления
ProcedureDLL SciNotification(SciGadget, *scinotify.SCNotification)
	Protected posEnd, posStart, line , regex$, *buffer, pos2, i
; 	исправить: переменная sep$ = #LF$ должна быть глобавльной, в структуре AComplete() так как это её текстовый вариант
	Protected tmp$, Pos, word$, WordStart, *DestinationMemoryID, sep$ = #LF$, *pos, autocompSearchLength, PosFind, tmp, PosFind2, length;, WordEnd
	; 	Select Gadget
	; 		Case 0 ; уведомление гаджету 0 (Scintilla)
	With *scinotify
		Select \nmhdr\code


; 			Case #SCN_USERLISTSELECTION
; 				Debug \listType
; 			Case #SCN_CHARADDED ; реакция на ввод символа, самый экономичный, можно добавить проверку ввода пробела или переноса строки
; 					pos = ScintillaSendMessage(SciGadget, #SCI_GETCURRENTPOS) ; позиция курсора чтобы получить номер строки
; 					line = ScintillaSendMessage(SciGadget, #SCI_LINEFROMPOSITION, pos) ; номер строки из позиции (в которой расположен курсор)
; 					pos2 = ScintillaSendMessage(SciGadget, #SCI_GETLINEENDPOSITION, line) ; позиция конца строки указанного номера строки
; 					pos = ScintillaSendMessage(SciGadget, #SCI_POSITIONFROMLINE, line) ; позиция начала начала указанного номера строки
; 					ForEach regex()
; 						; неправильно, так как надо выяснить диапазон подсветки, на данный момент весь текст
; 						Color(regex()\mem, regex()\len, regex()\id, pos, pos2) ; подсветка только строки, в которой курсор
; 					Next
; 					Debug pos
; 					Debug pos2
; 			Case #SCN_MODIFIED ; реакция на модификацию документа (плаг пометки изменений)
; 				If \modificationType & #SC_MOD_INSERTTEXT
; 					; если в типе модификации есть флаг вставки SC_MOD_INSERTTEXT, то (ввод символа или Ctrl+V)
; 					ForEach regex()
; 						; подсветка вставленного текста
; 						Color(regex()\mem, regex()\len, regex()\id, \Position, \Position + \length)
; 					Next
; 				EndIf
			Case #SCN_STYLENEEDED ; нужна стилизация, подсветка текста
				If Docum()\hlight
					; Debug 1
					; вынес из функции Color() то что запрашивается в данный момент 1 раз

					; Устанавливает целевой диапазон поиска
					; 				posEnd = ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH) ; получает длину текста
					posStart = ScintillaSendMessage(SciGadget, #SCI_GETENDSTYLED)
; 					Debug posStart
					; 				Debug posEnd
					posEnd = *scinotify.SCNotification\Position
					line = ScintillaSendMessage(SciGadget, #SCI_LINEFROMPOSITION, posStart) ; номер строки из позиции (в которой расположен курсор)
					posStart = ScintillaSendMessage(SciGadget, #SCI_POSITIONFROMLINE, line)	; позиция начала начала указанного номера строки
																							; 				Debug Str(posStart) + "  -  " + Str(posEnd)


					; Устанавливает режим поиска (REGEX + POSIX фигурные скобки)
					ScintillaSendMessage(SciGadget, #SCI_SETSEARCHFLAGS, #SCFIND_REGEXP | #SCFIND_POSIX)
					; ScintillaSendMessage(SciGadget, #SCI_SETSEARCHFLAGS, #SCFIND_REGEXP | #SCFIND_CXX11REGEX)

					If IsOpenFile
						Protected before1, before2, After1, After2
						before1 = 0
						before2 = posStart
						After1 = posEnd
						After2 = ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH) ; получает длину текста
					EndIf

					Color(HLightRegex(Docum()\hlight)\regex(), posStart, posEnd)
					; 				Debug Docum()\hlight

					If IsOpenFile
						; если открыт файл то подсвечиваем до и после видимой части кода
						If before1 <> before2


							Color(HLightRegex(Docum()\hlight)\regex(), before1, before2)
						EndIf
						If After1 <> After2
							Color(HLightRegex(Docum()\hlight)\regex(), After1, After2)
						EndIf
						IsOpenFile = 0
					EndIf
				Else
; 					Debug 19
				EndIf
				; подкраска, чтобы прекратить досить подсветкой каждую секунду
				ScintillaSendMessage(SciGadget, #SCI_STARTSTYLING, 2147483646, 0) ; позиция больше документа
				ScintillaSendMessage(SciGadget, #SCI_SETSTYLING, 0, 0)			  ; ширина и номер стиля





			Case #SCN_CHARADDED
				If \ch = 10
					line = ScintillaSendMessage(SciGadget, #SCI_LINEFROMPOSITION, ScintillaSendMessage(SciGadget, #SCI_GETCURRENTPOS, 0, 0), 0)
					tmp = ScintillaSendMessage(SciGadget, #SCI_GETLINEINDENTATION, line - 1)
					If tmp
; 						ScintillaSendMessage(SciGadget, #SCI_BEGINUNDOACTION)
						ScintillaSendMessage(SciGadget, #SCI_SETLINEINDENTATION, line, tmp)
						ScintillaSendMessage(SciGadget, #SCI_GOTOPOS, ScintillaSendMessage(SciGadget, #SCI_GETLINEENDPOSITION, line))
; 						ScintillaSendMessage(SciGadget, #SCI_ENDUNDOACTION)
					EndIf
; 				EndIf
				ElseIf Docum()\acomplete
					Select \ch
						Case 'a' To 'z', 'A' To 'Z', '_', '@', '#';, '0' To '9'
							Pos = ScintillaSendMessage(SciGadget, #SCI_GETCURRENTPOS) ; возвращает текущую позицию.
							WordStart = ScintillaSendMessage(SciGadget, #SCI_WORDSTARTPOSITION, Pos, 1) ; сообщения возвращают начало слова
							autocompSearchLength = Pos - WordStart

							*pos = ScintillaSendMessage(SciGadget, #SCI_GETCHARACTERPOINTER) ; прямой доступ
							word$ = PeekS(*pos + WordStart, autocompSearchLength, #PB_UTF8)	 ; #PB_ByteLength
							word$ = sep$ + word$
							PosFind = FindString(AComplete(Docum()\acomplete)\autocompText, word$, 1, #PB_String_NoCase)
							If PosFind
								Repeat
									tmp = PosFind2
									PosFind2 =FindString(AComplete(Docum()\acomplete)\autocompText, word$, PosFind2 + 1, #PB_String_NoCase)
								Until PosFind2 = 0
								If tmp
									PosFind2 = FindString(AComplete(Docum()\acomplete)\autocompText, sep$, tmp + 1)
									If PosFind2
										; 								Debug word$
										; 								Debug Str(PosFind) + " " + Str(PosFind2) + " " + Str(PosFind2 - PosFind)
										; 								если позиции не изменяются надо не перерисовывать список
										*DestinationMemoryID = AllocateMemory(PosFind2 - PosFind - 1)
										CopyMemory(AComplete(Docum()\acomplete)\autocompList + PosFind, *DestinationMemoryID , PosFind2 - PosFind - 1)
										ScintillaSendMessage(SciGadget, #SCI_AUTOCSHOW, autocompSearchLength, *DestinationMemoryID)
										FreeMemory(*DestinationMemoryID)
									EndIf
								EndIf
								; 					Else
								; 						ScintillaSendMessage(SciGadget, #SCI_AUTOCCANCEL)
							EndIf
					EndSelect
				EndIf




			Case #SCN_AUTOCSELECTION ; удалите сообщение если нужно вставить ключевое слово без фрагмента
				If Docum()\acomplete
					ScintillaSendMessage(SciGadget, #SCI_AUTOCCANCEL) ; отмена вставки
					tmp$ = PeekS(\text, -1, #PB_UTF8)
; 					tmp = Len(tmp$)
					; 			Debug PeekS(\text, -1, #PB_UTF8)
					tmp$ = GetTextFile(AComplete(Docum()\acomplete)\autocompletepath + tmp$ + "." + AComplete(Docum()\acomplete)\ext)

					Pos = ScintillaSendMessage(SciGadget, #SCI_GETCURRENTPOS) ; возвращает текущую позицию.
					line = ScintillaSendMessage(SciGadget, #SCI_LINEFROMPOSITION, Pos, 0)
					tmp = ScintillaSendMessage(SciGadget, #SCI_GETLINEINDENTATION, line) ; отступ на текущей строке
					If tmp
; 						тут учесть что отступ может быть пробелы, а если и табуляция, то не обязательно размером 4
						tmp / 4
						tmp$ = ReplaceString(tmp$, Chr(10), Chr(10) + RepeatCharN(#TAB, tmp))
					EndIf



					If Docum()\format = #PB_Ascii
						length = Len(tmp$)
					Else
						length = StringByteLength(tmp$, #PB_UTF8)
					EndIf
					*DestinationMemoryID = UTF8(tmp$)



; 					PosFind2 = Pos ; используем переменную как буфер для запоминания позиции
; 					Debug Pos
					WordStart = ScintillaSendMessage(SciGadget, #SCI_WORDSTARTPOSITION, Pos, 1) ; сообщения возвращают начало слова
					PosFind2 = Pos - WordStart
; 					Debug Pos
; 					Debug WordStart
					ScintillaSendMessage(SciGadget, #SCI_BEGINUNDOACTION)
					ScintillaSendMessage(SciGadget, #SCI_DELETERANGE, WordStart, Pos - WordStart) ; удалить введённое слово
; 					ScintillaSendMessage(SciGadget, #SCI_GOTOPOS, WordStart)
					 ; вставка фрагментов из одноимённого файла. Вместо вставки слова прочитать одноимённый файл и вставить его содержимое.
					ScintillaSendMessage(SciGadget, #SCI_INSERTTEXT, -1, *DestinationMemoryID)
					FreeMemory(*DestinationMemoryID)
; 					If length = tmp
; 						Pos + length - PosFind2
; 					Else
; 						Pos + length - PosFind2
; 					EndIf
					Pos + length - PosFind2
					ScintillaSendMessage(SciGadget, #SCI_GOTOPOS, Pos)

; 					Первое слово не подсвечено, потому что позиция #SCI_GETENDSTYLED чуть больше чем начало вставки
; 					WordEnd = ScintillaSendMessage(SciGadget, #SCI_WORDENDPOSITION, WordStart + 1, 1) ; сообщения возвращают начало слова
; 					ScintillaSendMessage(SciGadget, #SCI_STARTSTYLING, WordStart, 0)        ; позиция начала (с 50-го)
; 					ScintillaSendMessage(SciGadget, #SCI_SETSTYLING, length, 0)     ; ширина и номер стиля
; 					Color(HLightRegex(Docum()\hlight)\regex(), WordStart - 6, WordStart + length + 6)

; 					tmp = ScintillaSendMessage(SciGadget, #SCI_GETLINEINDENTATION, line - 1)
; 					If tmp
; 						Pos = CountString(tmp$, Chr(10))
; 						For i = 0 To Pos
; 							ScintillaSendMessage(SciGadget, #SCI_SETLINEINDENTATION, line + i, tmp) ; вставка такого отступа обнуляет отступы в файле
; 						Next
; 						ScintillaSendMessage(SciGadget, #SCI_GOTOPOS, ScintillaSendMessage(SciGadget, #SCI_GETLINEENDPOSITION, line + i - 1))
; 					EndIf
; 					ScintillaSendMessage(SciGadget, #SCI_ENDUNDOACTION)
				EndIf

; 			Case #SCN_MODIFIED ; если удалить символ, то обновить список
; 				If \modificationType & #SC_MOD_DELETETEXT


			Case #SCN_AUTOCCHARDELETED ; если удалить символ, то обновить список
				If Docum()\acomplete
					Pos = ScintillaSendMessage(SciGadget, #SCI_GETCURRENTPOS) ; возвращает текущую позицию.
					WordStart = ScintillaSendMessage(SciGadget, #SCI_WORDSTARTPOSITION, Pos, 1) ; сообщения возвращают начало слова
					autocompSearchLength = Pos - WordStart

					*pos = ScintillaSendMessage(SciGadget, #SCI_GETCHARACTERPOINTER) ; прямой доступ
					word$ = PeekS(*pos + WordStart, autocompSearchLength, #PB_UTF8)	 ; #PB_ByteLength
					word$ = sep$ + word$
					PosFind = FindString(AComplete(Docum()\acomplete)\autocompText, word$, 1, #PB_String_NoCase)
					If PosFind
						Repeat
							tmp = PosFind2
							PosFind2 =FindString(AComplete(Docum()\acomplete)\autocompText, word$, PosFind2 + 1, #PB_String_NoCase)
						Until PosFind2 = 0
						If tmp
							PosFind2 = FindString(AComplete(Docum()\acomplete)\autocompText, sep$, tmp + 1)
							If PosFind2
								; 								Debug word$
								; 								Debug Str(PosFind) + " " + Str(PosFind2) + " " + Str(PosFind2 - PosFind)
								; 								если позиции не изменяются надо не перерисовывать список
								*DestinationMemoryID = AllocateMemory(PosFind2 - PosFind - 1)
								CopyMemory(AComplete(Docum()\acomplete)\autocompList + PosFind, *DestinationMemoryID , PosFind2 - PosFind - 1)
								ScintillaSendMessage(SciGadget, #SCI_AUTOCSHOW, autocompSearchLength, *DestinationMemoryID)
								FreeMemory(*DestinationMemoryID)
							EndIf
						EndIf
						; 					Else
						; 						ScintillaSendMessage(SciGadget, #SCI_AUTOCCANCEL)
					EndIf
				EndIf

			Case #SCN_SAVEPOINTREACHED ; сохранено
				tmp = GetTabBarGadgetState(#Gadget_TabBar)
				
				tmp$ = GetTabBarGadgetItemText(#Gadget_TabBar, tmp)
				If tmp <> -1 And Asc(tmp$) = '*'
					If Asc(Docum()\path)
						SetTabBarGadgetItemText(#Gadget_TabBar , tmp , GetFilePart(Docum()\path))
					Else
						SetTabBarGadgetItemText(#Gadget_TabBar , tmp , Mid(tmp$, 2))
					EndIf
; 					Debug "REACHED"
				EndIf
			Case #SCN_SAVEPOINTLEFT	   ; требует сохраненения
				tmp = GetTabBarGadgetState(#Gadget_TabBar)
				If tmp <> -1
					If  Asc(Docum()\path)
						SetTabBarGadgetItemText(#Gadget_TabBar , tmp , "*" + GetFilePart(Docum()\path))
						; 					Debug "LEFT"
					Else
						SetTabBarGadgetItemText(#Gadget_TabBar , tmp , "*" + GetTabBarGadgetItemText(#Gadget_TabBar , tmp))
					EndIf
				EndIf


			Case #SCN_UPDATEUI
				If \updated & 2 ; если происходит выделение текста и перемещение текстового курсора
					If ScintillaSendMessage(SciGadget, #SCI_GETSELECTIONEMPTY) ; Если 0, то выделен 1 и более символов, если 1 то ничего не выделено
						If flgHSel
							ScintillaSendMessage(SciGadget, #SCI_INDICATORCLEARRANGE, 0, ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH))
						EndIf
					Else
						HighlightSelection()
					EndIf
				EndIf

; 			Case #SCN_USERLISTSELECTION
; 				Debug 2
; ; 			Case #SCN_STYLENEEDED
; ; 				Debug 3
; 			Case #SCN_CHARADDED
; 				Debug 4
; 			Case #SCN_SAVEPOINTREACHED
; 				Debug 5
; 			Case #SCN_SAVEPOINTLEFT
; 				Debug 6
; 			Case #SCN_MODIFYATTEMPTRO
; 				Debug 7
; 			Case #SCN_KEY
; 				Debug 8
; 			Case #SCN_DOUBLECLICK
; 				Debug 9
; 			Case #SCN_UPDATEUI
; 				Debug 10
; 			Case #SCN_MODIFIED
; 				Debug 11
; 			Case #SCN_MACRORECORD
; 				Debug 12
; 			Case #SCN_MARGINCLICK
; 				Debug 13
; 			Case #SCN_NEEDSHOWN
; 				Debug 14
; 			Case #SCN_PAINTED
; 				Debug 15
; 			Case #SCN_USERLISTSELECTION
; 				Debug 16
; 			Case #SCN_URIDROPPED
; 				Debug 17
; 			Case #SCN_DWELLSTART
; 				Debug 18
; 			Case #SCN_DWELLEND
; 				Debug 19
; 			Case #SCN_ZOOM
; 				Debug 20
; 			Case #SCN_HOTSPOTCLICK
; 				Debug 21
; 			Case #SCN_HOTSPOTDOUBLECLICK
; 				Debug 22
; 			Case #SCN_HOTSPOTRELEASECLICK
; 				Debug 23
; 			Case #SCN_INDICATORCLICK
; 				Debug 24
; 			Case #SCN_INDICATORRELEASE
; 				Debug 25
; 			Case #SCN_CALLTIPCLICK
; 				Debug 26
; 			Case #SCN_AUTOCSELECTION
; 				Debug 27
; 			Case #SCN_AUTOCCANCELLED
; 				Debug 28
; 			Case #SCN_AUTOCCHARDELETED
; 				Debug 29
; 			Case #SCN_FOCUSIN
; 				Debug 30
; 			Case #SCN_FOCUSOUT
; 				Debug 31
; 			Case #SCN_AUTOCCOMPLETED
; 				Debug 32
; 			Case #SCN_MARGINRIGHTCLICK
; 				Debug 33
; 			Case #SCN_AUTOCSELECTIONCHANGE
; 				Debug 34

		EndSelect
	EndWith
	; 	EndSelect
EndProcedure



; Procedure HighlightSelection2(SearchTxt$)
Procedure HighlightSelection2(*Search, length)
EndProcedure


Procedure HighlightSelection()
	Protected length, Cursor, Anchor, *pos ; , Selected$
	Protected length2, StartPos, EndPos, firstMatchPos, *Search
	Protected inSrt, inEnd
	Cursor = ScintillaSendMessage(SciGadget, #SCI_GETCURRENTPOS)
	Anchor = ScintillaSendMessage(SciGadget, #SCI_GETANCHOR)
	If Anchor < Cursor
		Swap Cursor, Anchor
	EndIf
	length = Anchor - Cursor
	If Cursor <> ScintillaSendMessage(SciGadget, #SCI_WORDSTARTPOSITION, Cursor, 1) Or Anchor <> ScintillaSendMessage(SciGadget, #SCI_WORDENDPOSITION, Anchor, 1)
		ProcedureReturn
	EndIf


	*pos = ScintillaSendMessage(SciGadget, #SCI_GETCHARACTERPOINTER) ; прямой доступ
; 	Selected$ = PeekS(*pos + Cursor, length, #PB_UTF8 | #PB_ByteLength)




	*Search = *pos + Cursor
	ScintillaSendMessage(SciGadget, #SCI_INDICATORCLEARRANGE, 0, ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH))
	; Устанавливает целевой диапазон поиска
	inSrt = 0
	inEnd = ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH) ; получает длину текста
	ScintillaSendMessage(SciGadget, #SCI_SETTARGETSTART, inSrt)    ; от начала (задаём область поиска) используя позицию конца предыдущего поиска
	ScintillaSendMessage(SciGadget, #SCI_SETTARGETEND, inEnd)	   ; до конца по длине текста

	ScintillaSendMessage(SciGadget, #SCI_SETSEARCHFLAGS, #SCFIND_MATCHCASE)
; 	lengthStr = Len(SearchTxt$)

	ScintillaSendMessage(SciGadget, #SCI_BEGINUNDOACTION)
	Repeat
		; 		нашли
		firstMatchPos = ScintillaSendMessage(SciGadget, #SCI_SEARCHINTARGET, length, *Search)
		; 		Debug firstMatchPos
		If firstMatchPos = -1
			; выпрыг если не найдено
			Break
		EndIf

		flgHSel = 1
		StartPos = ScintillaSendMessage(SciGadget, #SCI_GETTARGETSTART)        ; получает позицию начала найденного
		EndPos = ScintillaSendMessage(SciGadget, #SCI_GETTARGETEND)			   ; получает позицию конца найденного
		length2 = EndPos - StartPos
; 		чтобы не подсвечивать само выделяемое слово
		If StartPos <> Cursor
; 			Count + 1 ; здесь можно осуществить подсчёт выделенных не затрачивая особых ресурсов
; 			Continue
			ScintillaSendMessage(SciGadget, #SCI_INDICATORFILLRANGE, StartPos, length2)  ; выделяет текст используя текущий индикатор
		EndIf

		inSrt = firstMatchPos + length2 ; задать диапазон поиска
										; Устанавливает целевой диапазон поиска
		inEnd = ScintillaSendMessage(SciGadget, #SCI_GETTEXTLENGTH) ; получает длину текста
																	; 	ScintillaSendMessage(SciGadget, #SCI_SETTARGETRANGE, inSrt, inEnd) ; задать диапазон поиска
		ScintillaSendMessage(SciGadget, #SCI_SETTARGETSTART, inSrt)	; от начала (задаём область поиска) используя позицию конца предыдущего поиска
		ScintillaSendMessage(SciGadget, #SCI_SETTARGETEND, inEnd)	; до конца по длине текста

	ForEver
EndProcedure


; структура
; 	re.s
; 	id.i
; 	len.i
; 	*buffer
; Чтение ini-файла цвета и создание цветовых идентификаторов
Procedure ColorSet(Ext$)
	Protected tmp$, colorRGB, type, id, ig, i
	Protected ColorType
	; 	Debug Ext$


	ColorType = #SCI_STYLESETFORE

	If OpenPreferences(inicolor$)

; 		ForEach regex()
; 			FreeMemory(regex()\mem)
; 		Next
; 		ClearList(regex())
		id = 1

; 		Сбрасываем чекбоксы "Синтаксис"
		ig = -1
		For i = LastItem1 To LastItem2
			If GetMenuItemState(#Menu, i) = 1
				SetMenuItemState(#Menu, i, 0)
				Break
			EndIf
		Next


; 	List regex.SciRegExp()
; Global Dim HLightRegex.ListRE(0)

		For i = 1 To ArraySize(HLightRegex())
			ig + 1
			ForEach HLightRegex(i)\ext()
				; Debug HLightRegex(i)\ext()
				; двойной поиск одного в другом, чтобы исключить частичное совпадение, при этом без учёта регистра
				; если использовать CompareMemoryString(), то требуется получать указатели с массив\список HLightRegex(i)\ext()
				; *Result = SelectElement(HLightRegex(i)\ext(), ListIndex(HLightRegex(i)\ext()))
				If CompareMemoryString(PeekI(SelectElement(HLightRegex(i)\ext(), ListIndex(HLightRegex(i)\ext()))), @Ext$, #PB_String_NoCase) = #PB_String_Equal
; 				If FindString(Ext$, HLightRegex(i)\ext(), 1, #PB_String_NoCase) And FindString(HLightRegex(i)\ext(), Ext$, 1, #PB_String_NoCase)
					PreferenceGroup(HLightRegex(i)\section)
					CurSyntax = ig + LastItem1
					Docum()\syntax = CurSyntax
					SetMenuItemState(#Menu, CurSyntax, 1) ; ставим чекбокс
					Docum()\hlight = i
					; если список пуст, тогда загружаем регвыры и устанавливаем в документ
					If ListSize(HLightRegex(i)\regex()) = 0
						If ExaminePreferenceKeys()
							While NextPreferenceKey()
								If AddElement(HLightRegex(i)\regex())
									tmp$ = PreferenceKeyName()
									HLightRegex(i)\regex()\color = ColorValidate(StringField(tmp$, 1, "|"))
									; type = StringField(tmp$, 2, "|")
									HLightRegex(i)\regex()\re = PreferenceKeyValue()
									HLightRegex(i)\regex()\id = id
; 									Debug Str(HLightRegex(i)\regex()\color) + " " + Str(HLightRegex(i)\regex()\id) + " " + HLightRegex(i)\regex()\re
									ScintillaSendMessage(SciGadget, ColorType, id, HLightRegex(i)\regex()\color)
									id + 1
								EndIf
							Wend

							ForEach HLightRegex(i)\regex()
								HLightRegex(i)\regex()\len = Len(HLightRegex(i)\regex()\re)
								HLightRegex(i)\regex()\mem = UTF8(HLightRegex(i)\regex()\re)
							Next
						EndIf
					Else
						; иначе только устанавливаем в документ
						ForEach HLightRegex(i)\regex()
							ScintillaSendMessage(SciGadget, ColorType, HLightRegex(i)\regex()\id, HLightRegex(i)\regex()\color)
						Next
					EndIf
					Break
				EndIf
			Next
		Next

; 		Восстановление флага поиска после использования окна поиска с изменением флагов на не REGEXP
		ScintillaSendMessage(SciGadget, #SCI_SETSEARCHFLAGS, #SCFIND_REGEXP | #SCFIND_POSIX)
		ClosePreferences()
	EndIf
EndProcedure


; Чтение файла в гаджет
Procedure OpenFileToSci(FilePath$)
	Protected length, oFile, bytes, *MemFile, *Buffer, Ext$;, Format
	oFile = ReadFile(#PB_Any, FilePath$)
	If oFile
		Docum()\format = ReadStringFormat(oFile)
		length = Lof(oFile)
		*MemFile = AllocateMemory(length + 2)
		If *MemFile
			bytes = ReadData(oFile, *MemFile, length)
			; закрыл тут так как если открыть конфиг My_Notepad_Sci_Color.ini самого My_Notepad_Sci, то
			; он не мог подсветится так как открытый файл не давал доступа для его чтения, чтобы назначить цвет.
			CloseFile(oFile)
			If bytes
				Select Docum()\format
					Case #PB_Ascii
						Docum()\format = dte::detectTextEncodingInBuffer(*MemFile, bytes, 0)
	; 					MessageRequester("", Str(Docum()\format))
						If Docum()\format = #PB_Ascii
							Docum()\fs = #PB_Ascii
							ScintillaSendMessage(SciGadget, #SCI_SETCODEPAGE, #SC_CHARSET_ANSI)
							ScintillaSendMessage(SciGadget, #SCI_STYLESETCHARACTERSET, 0, #SC_CHARSET_CYRILLIC)
							SetMenuItemState(#Menu, #mANSI, 1)
							SetMenuItemState(#Menu, #mUTF8, 0)
							CompilerIf #PB_Compiler_OS = #PB_OS_Windows
								SetMenuItemState(#Menu, #m866, 0)
							CompilerEndIf
							SetMenuItemState(#Menu, #mUTF16LE, 0)
							Docum()\cp = #mANSI
	; 						Debug "ANSI"
						Else
							Docum()\notbom = 1
							Docum()\format = #PB_UTF8
							Docum()\fs = #PB_UTF8
							ScintillaSendMessage(SciGadget, #SCI_SETCODEPAGE, #SC_CP_UTF8)
							SetMenuItemState(#Menu, #mUTF8, 1)
							SetMenuItemState(#Menu, #mANSI, 0)
							CompilerIf #PB_Compiler_OS = #PB_OS_Windows
								SetMenuItemState(#Menu, #m866, 0)
							CompilerEndIf
							SetMenuItemState(#Menu, #mUTF16LE, 0)
							Docum()\cp = #mUTF8
	; 						Debug "ANSI as UTF8"
						EndIf
					Case #PB_UTF8
						Docum()\fs = #PB_UTF8
						ScintillaSendMessage(SciGadget, #SCI_SETCODEPAGE, #SC_CP_UTF8)
						SetMenuItemState(#Menu, #mUTF8, 1)
						SetMenuItemState(#Menu, #mANSI, 0)
						CompilerIf #PB_Compiler_OS = #PB_OS_Windows
							SetMenuItemState(#Menu, #m866, 0)
						CompilerEndIf
						SetMenuItemState(#Menu, #mUTF16LE, 0)
						Docum()\cp = #mUTF8
; 						Debug "UTF8"
					Case #PB_Unicode
						Docum()\fs = dte::detectTextEncodingInBuffer(*MemFile, bytes, 0)
						Docum()\format = #PB_UTF8
						*Buffer = UTF8(PeekS(*MemFile, -1, #PB_Unicode))
						FreeMemory(*MemFile)
						*MemFile = *Buffer
						ScintillaSendMessage(SciGadget, #SCI_SETCODEPAGE, #SC_CP_UTF8)
						SetMenuItemState(#Menu, #mUTF16LE, 1)
						SetMenuItemState(#Menu, #mUTF8, 0)
						SetMenuItemState(#Menu, #mANSI, 0)
						CompilerIf #PB_Compiler_OS = #PB_OS_Windows
							SetMenuItemState(#Menu, #m866, 0)
						CompilerEndIf
						Docum()\cp = #mUTF16LE
; 						Debug "UTF8"
				EndSelect
				CurCP = Docum()\cp

				; 				Debug GetExtensionPart(FilePath$)
				IsOpenFile = 1
				Ext$ = GetExtensionPart(FilePath$)
				ColorSet(Ext$)
				ScintillaSendMessage(SciGadget, #SCI_SETTEXT, 0, *MemFile) ; добавил к выделенной памяти +2, так как SCI_SETTEXT требует нуль-терминированую строку
; 				ScintillaSendMessage(SciGadget, #SCI_APPENDTEXT, bytes, *MemFile)
				ScintillaSendMessage(SciGadget, #SCI_EMPTYUNDOBUFFER) ; сброс отмены
				ScintillaSendMessage(SciGadget, #SCI_SETSAVEPOINT) ; документ сохранён
				FreeMemory(*MemFile)
; 				SetWindowTitle(#Window, "My_Notepad" + " - " + GetFilePart(FilePath$))
				; 				ScintillaSendMessage(SciGadget, #SCI_SETLEXER, #SCLEX_CONTAINER)
				; 				ScintillaSendMessage(SciGadget, #SCI_SETLEXER, #SCLEX_PUREBASIC, 0)
				; 				ScintillaSendMessage(SciGadget, #SCI_SETLEXER, 3, 0)
				; 				Debug ScintillaSendMessage(SciGadget, #SCI_GETLEXER)
				; 				ScintillaSendMessage(SciGadget, #SCI_SETLEXER, #SCLEX_CPP, 0)
				; 				Debug ScintillaSendMessage(SciGadget, #SCI_GETLEXER)

				CompilerIf #PB_Compiler_OS = #PB_OS_Windows
					If auto866 And (Ext$ = "cmd" Or Ext$ = "bat")
						m866()
					EndIf
				CompilerEndIf
			EndIf
		EndIf
		If IsFile(oFile)
			CloseFile(oFile)
		EndIf
	EndIf
EndProcedure


; Сохранение файла из гаджета
Procedure SaveFile(FilePath$)
	Protected oFile, txtLen, *buffer, text$
	oFile = CreateFile(#PB_Any, FilePath$)
	If oFile
		txtLen = ScintillaSendMessage(SciGadget, #SCI_GETLENGTH)          ; получает длину текста в байтах
		*buffer = AllocateMemory(txtLen + 2)           ; Выделяем память без Null
		If *buffer                  ; Если указатель получен, то
			ScintillaSendMessage(SciGadget, #SCI_GETTEXT, txtLen + 1, *buffer)        ; получает текста
			If Docum()\fs ; защита от проблемы если формат файла не определён, то программа не упадёт

				CompilerIf #PB_Compiler_OS = #PB_OS_Windows
					If Docum()\format = #frm866 ; Если кодировка 866
						CharToOemBuffA(*buffer, *buffer, txtLen)
					EndIf
				CompilerEndIf

				If Not Docum()\notbom
					WriteStringFormat(oFile, Docum()\fs)
				EndIf
			EndIf

; 			Добавить с BOM или без BOM для UTF8
			If Docum()\fs = #PB_Unicode
				text$ = PeekS(*buffer, -1, #PB_UTF8)
				WriteString(oFile, text$, #PB_Unicode)
			Else
				WriteData(oFile, *buffer, txtLen)
			EndIf
			FreeMemory(*buffer)
			ScintillaSendMessage(SciGadget, #SCI_SETSAVEPOINT) ; документ сохранён
		EndIf
		CloseFile(oFile)
	EndIf
EndProcedure


; Сохранение файла из гаджета
Procedure SaveAs()
	If Asc(Docum()\path)
		tmp$ = Docum()\path
		If FileSize(tmp$) < 0
			tmp$ = GetCurrentDirectory()
		EndIf
	Else
		tmp$ = GetCurrentDirectory()
	EndIf
	tmp$ = SaveFileRequester("Сохранить файл", tmp$, "Все (*.*)|*.*", 0)
	If Asc(tmp$)
		CompilerIf #PB_Compiler_OS = #PB_OS_Windows
			If Not FindString(tmp$, ".") ; случай если вы забыли ввести расширение файла, чтобы он был ассоциированный
				tmp$ + ".txt"
			EndIf
		CompilerEndIf
		SaveFile(tmp$)
	EndIf
EndProcedure


; Запуск файла в ассоциированной программе
Procedure StartFile()
	If Asc(Docum()\path)
		CompilerSelect #PB_Compiler_OS
			CompilerCase #PB_OS_Windows
				RunProgram(Docum()\path)
			CompilerCase #PB_OS_Linux
; 				RunProgram("xdg-open", #q$ + Docum()\path + #q$, "")
				RunProgram("xdg-open", #q$ + Docum()\path + #q$, #q$ + GetPathPart(Docum()\path) + #q$)
		CompilerEndSelect
	EndIf
EndProcedure



; Получить текст из Scintilla
Procedure.s GetScintillaGadgetText()
	Protected txtLen, *buffer, text$
	txtLen = ScintillaSendMessage(SciGadget, #SCI_GETLENGTH)          ; получает длину текста в байтах
	*buffer = AllocateMemory(txtLen + 2)           ; Выделяем память на длину текста и 1 символ на Null
	If *buffer                  ; Если указатель получен, то
		ScintillaSendMessage(SciGadget, #SCI_GETTEXT, txtLen + 1, *buffer)        ; получает текста
																				; Считываем значение из области памяти
		If Docum()\format = #PB_Ascii
			text$ = PeekS(*buffer, -1, #PB_Ascii)
		Else
			text$ = PeekS(*buffer, -1, #PB_UTF8)
		EndIf
		; 		MessageRequester("", text$)
		FreeMemory(*buffer)
		ProcedureReturn text$
	EndIf
	ProcedureReturn ""
EndProcedure

; Получить выделенный текст из Scintilla
Procedure.s GetSelText()
	Protected txtLen, *buffer, text$
	txtLen = ScintillaSendMessage(SciGadget, #SCI_GETSELTEXT, 0, 0) ; получает длину текста в байтах
	*buffer = AllocateMemory(txtLen + 2)         ; Выделяем память на длину текста и 1 символ на Null
	If *buffer                ; Если указатель получен, то
																	 ; получает текста
		ScintillaSendMessage(SciGadget, #SCI_GETSELTEXT, txtLen + 1, *buffer)        ; получает текста
																				   ; Считываем значение из области памяти
		If Docum()\format = #PB_Ascii
			text$ = PeekS(*buffer, -1, #PB_Ascii)
		Else
			text$ = PeekS(*buffer, -1, #PB_UTF8)
		EndIf
		; 		MessageRequester("", text$)
		FreeMemory(*buffer)
		ProcedureReturn text$
	EndIf
	ProcedureReturn ""
EndProcedure

; Получить текст из Scintilla
Procedure ToFormat(format)
	Protected txtLen, *SciBuffer, *Buffer
	txtLen = ScintillaSendMessage(SciGadget, #SCI_GETLENGTH)          ; получает длину текста в байтах
	*SciBuffer = AllocateMemory(txtLen + 2)           ; Выделяем память на длину текста и 1 символ на Null
	If *SciBuffer                  ; Если указатель получен, то
		ScintillaSendMessage(SciGadget, #SCI_GETTEXT, txtLen + 1, *SciBuffer)        ; получает текста
		; Считываем значение из области памяти

; 0 toANSI
; 1 toUTF8
; 2 to866
; 3 toUTF16LE
		Select format
			Case 1 ; toUTF8
				If Docum()\format = #PB_Ascii
					*Buffer = UTF8(PeekS(*SciBuffer, -1, #PB_Ascii))
				EndIf
				mUTF8()
			Case 0 ; toANSI
				Docum()\fs = #PB_Ascii
				*Buffer = Ascii(PeekS(*SciBuffer, -1, #PB_UTF8))
				mANSI()
			Case 3 ; toUTF16LE
				If Docum()\format = #PB_Ascii ; Ascii или 866
					*Buffer = UTF8(PeekS(*SciBuffer, -1, #PB_Ascii))
				EndIf
				mUTF16LE()
; 			Case 2 ; to866
; 				CompilerIf #PB_Compiler_OS = #PB_OS_Windows
; 					If Docum()\format = #PB_Ascii
; 						*Buffer = AllocateMemory(txtLen + 1)
; 						OemToCharBuffA(*SciBuffer, *Buffer, txtLen)
; 					Else
; 						*Buffer = Ascii(PeekS(*SciBuffer, -1, #PB_UTF8))
; 						OemToCharBuffA(*Buffer, *Buffer, txtLen)
; 					EndIf
; 					Docum()\format = #frm866
; 				CompilerEndIf
		EndSelect

; 		If format
; 			*Buffer = UTF8(PeekS(*SciBuffer, -1, #PB_Ascii))
; 			mUTF8()
; 		Else
; 			*Buffer = Ascii(PeekS(*SciBuffer, -1, #PB_UTF8))
; 			mANSI()
; 		EndIf
		ScintillaSendMessage(SciGadget, #SCI_SETTEXT, 0, *Buffer)
		FreeMemory(*Buffer)
		If *Buffer <> *SciBuffer
			FreeMemory(*SciBuffer)
		EndIf
	EndIf
EndProcedure

Procedure SetProgParam()
	Protected tmp$, i
	If CountProgramParameters()
		tmp$ = ProgramParameter(0)
		If FileSize(tmp$) > -1
			; поиск документа в открытых
			tmp = 1
			CountTab = CountTabBarGadgetItems(#Gadget_TabBar)
			
			For i = 0 To CountTab - 1
				*SelectElement = GetGadgetItemData(#Gadget_TabBar, i)
				If *SelectElement And *SelectElement\path = tmp$
; 					SetTabBarGadgetState(#Gadget_TabBar, i)
					SetTabBarGadgetItemState(#Gadget_TabBar, i, #TabBarGadget_Selected, #TabBarGadget_Selected)
					ChangeCurrentElement(Docum(), *SelectElement)
					HideGadget(SciGadget, #True)
					HideGadget(Docum()\id, #False)
					SciGadget = Docum()\id
					SetActiveGadget(SciGadget)
					tmp = 0
					Break ; сделали его текущим
; 										Continue
				EndIf
			Next
			If tmp
				AddDocum(tmp$)
				OpenFileToSci(tmp$)
			EndIf
		EndIf
	EndIf
EndProcedure


Procedure ExitProg()
	Protected i, FilesToSave$
	; 	FreeRegularExpression(#PB_All)
	CountTab = CountTabBarGadgetItems(#Gadget_TabBar)
	For i = 0 To CountTab - 1
		tmp$ = GetTabBarGadgetItemText(#Gadget_TabBar, i)
		If Asc(tmp$) = '*'
			FilesToSave$ + Mid(tmp$, 2) + #LF$
		EndIf
	Next
	If Asc(FilesToSave$)
		Select MessageRequester("Сохранить?", "Есть файлы требующие сохранения:" + #LF$ + #LF$ + FilesToSave$ + #LF$ + "Сохранить?", #PB_MessageRequester_YesNoCancel)
			Case #PB_MessageRequester_Cancel
				ProcedureReturn
			Case #PB_MessageRequester_Yes
				CountTab = CountTabBarGadgetItems(#Gadget_TabBar)
				For i = CountTab - 1 To 0 Step -1
					tmp$ = GetTabBarGadgetItemText(#Gadget_TabBar, i)
					If Asc(tmp$) = '*'
						*SelectElement = GetTabBarGadgetItemData(#Gadget_TabBar, i)
						If *SelectElement
							; 							SetTabBarGadgetState(#Gadget_TabBar, i)
							; 							надо ли при закрытии всех вкладок делать выбор, если вкладки всё равно будут закрыты?
							; 							скорее всего менять только выбранный элемент структуры
							
							SetTabBarGadgetItemState(#Gadget_TabBar, i, #TabBarGadget_Selected, #TabBarGadget_Selected)
							ChangeCurrentElement(Docum(), *SelectElement)
							HideGadget(SciGadget, #True)
							HideGadget(Docum()\id, #False)
							SciGadget = Docum()\id
							SetActiveGadget(SciGadget)
							If FileSize(Docum()\path) > -1
								SaveFile(Docum()\path)
							Else
								SaveAs()
							EndIf
						EndIf
					EndIf
				Next
			Case #PB_MessageRequester_No

		EndSelect
	EndIf
	
	CompilerIf #PB_Compiler_OS = #PB_OS_Windows
		ForEach Docum()
			DestroyIcon_(Docum()\hicon)
		Next
	CompilerEndIf

	For i = 1 To ArraySize(HLightRegex())
		ForEach HLightRegex(i)\regex()
			FreeMemory(HLightRegex(i)\regex()\mem)
		Next
	Next
	For i = 1 To ArraySize(AComplete())
		FreeMemory(AComplete(i)\CanceledByChar)
		FreeMemory(AComplete(i)\autocompList)
	Next

	; 	If isINI And OpenPreferences(ini$, #PB_Preference_GroupSeparator | #PB_Preference_NoSpace)
	;
	; 		If PreferenceGroup("Set")
	; 			WritePreferenceString("last", GetGadgetText(#btnLib))
	; 			i = GetGadgetState(#Ch_OnTop) & #PB_Checkbox_Checked
	; 			If topmost <> i
	; 				WritePreferenceInteger("topmost", i)
	; 			EndIf
	; 			If (w3 <> w Or h3 <> h)
	; 				WritePreferenceInteger("height", h)
	; 				WritePreferenceInteger("width", w)
	; 			EndIf
	; 		EndIf
	; 		ClosePreferences()
	; 	EndIf
	If IsMenu(#Menu)
		FreeMenu(#Menu)
	EndIf
	If IsMenu(#PopupMenu)
		FreeMenu(#PopupMenu)
	EndIf
; 	Debug 3 ; тут началась проблема

; 	ForEach LDirName()
; 		If IsLibrary(LDirName()\id)
; 			CallCFunction(LDirName()\id, "DetachProcess2", 0)
; 		EndIf
; 	Next
	CloseLibrary(#PB_All)
; 	ForEach LDirName()
; 		If IsLibrary(LDirName()\id)
; 			CloseLibrary(LDirName()\id)
; 		EndIf
; 	Next
; 	Debug 4 ; тут началась проблема
	CloseWindow(#WinFind)
	CloseWindow(#Window)
	End
EndProcedure

; проверить скорость с SplitL вместо StringField
Procedure GetTypeFile()
	Protected tmp$, n, i

	If OpenPreferences(inicolor$)
		If ExaminePreferenceGroups()
			While NextPreferenceGroup()
				i + 1
				ReDim HLightRegex(i)
				HLightRegex(i)\section = PreferenceGroupName()
				n = 0
				Repeat
					n + 1
					tmp$ = StringField(HLightRegex(i)\section, n, ",")
					If Asc(tmp$)
						AddElement(HLightRegex(i)\ext())
						HLightRegex(i)\ext() = tmp$
					Else
						Break
					EndIf
				ForEver
			Wend
		EndIf
		ClosePreferences()
	EndIf
EndProcedure
; IDE Options = PureBasic 6.02 LTS (Windows - x86)
; CursorPosition = 1212
; FirstLine = 1199
; Folding = -----4-------
; Markers = 1091,1475,2622,3004
; EnableAsm
; EnableXP
; DPIAware
; UseIcon = icon.ico
; Executable = тест вкладок\Windows_x32\My_Notepad_Sci.exe
; CompileSourceDirectory
; DisableCompileCount = 4
; EnableBuildCount = 0
; EnableExeConstant
; IncludeVersionInfo
; VersionField0 = 0.3.6.%BUILDCOUNT
; VersionField2 = AZJIO
; VersionField3 = My_Notepad_Sci
; VersionField4 = 0.3.6
; VersionField6 = My_Notepad_Sci
; VersionField9 = AZJIO