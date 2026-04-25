; Memory Scanner - PureBasic CheatEngine Alternative
; Compatible with PureBasic 6.30 (Latest Version)
; Educational tool for memory analysis and debugging
; NEW: Added detailed process information viewer with descriptions and company info

EnableExplicit

#APP_NAME   = "HandyMEMScan"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.5"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
Global MemoryViewFont.i
Global ProcessInfoFont.i
Global ProcessHandle.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = #ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; Exit procedure
Global AppExitRequested.i

Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    AppExitRequested = #True
  EndIf
EndProcedure

#FreezeTimerID = 101 ; Timer ID for memory freezing

; Global variables
Global SelectedProcess.l = -1

; Windows API Constants

#PROCESS_QUERY_INFORMATION = $0400
#PROCESS_VM_READ = $0010
#PROCESS_VM_WRITE = $0020
#PROCESS_VM_OPERATION = $0008
#PROCESS_QUERY_LIMITED_INFORMATION = $1000
#WM_SETREDRAW = $000B
#RDW_INVALIDATE = $0001
#RDW_UPDATENOW = $0100

; Memory protection
#PAGE_NOACCESS          = $01
#PAGE_READONLY          = $02
#PAGE_READWRITE         = $04
#PAGE_WRITECOPY         = $08
#PAGE_EXECUTE           = $10
#PAGE_EXECUTE_READ      = $20
#PAGE_EXECUTE_READWRITE = $40
#PAGE_EXECUTE_WRITECOPY = $80
#PAGE_GUARD             = $100
#PAGE_NOCACHE           = $200
#PAGE_WRITECOMBINE      = $400

  #MAX_PATH = 260
  #TH32CS_SNAPPROCESS = $00000002
  #TH32CS_SNAPMODULE = $00000008
  #TH32CS_SNAPMODULE32 = $00000010

  ; Windows Module structure (needed for PB since not all versions define MODULEENTRY32)
  Structure MODULEENTRY32_PB
    dwSize.l
    th32ModuleID.l
    th32ProcessID.l
    GlblcntUsage.l
    ProccntUsage.l
    modBaseAddr.i
    modBaseSize.l
    hModule.i
    szModule.b[256]
    szExePath.b[#MAX_PATH]
  EndStructure

  ; Module info structure for our internal list
  Structure AppModuleInfo
    BaseAddress.i
    Size.l
    Name.s
    Path.s
  EndStructure

  Global NewList ModuleList.AppModuleInfo()

  #ModulesButton = 1001
  #ModulesWindow = 1002
  #ModulesListGadget = 1003
  #MemoryViewWindow = 1004
  #MemoryViewEditor = 1005

  Declare.s FormatAddress(Address.i)
  Declare UpdateResultsUI()
  Declare UpdateCheatListUI()
  Declare.q ParseHex(Text.s)
  Declare.i IsValidIntegerInput(Text.s)
  Declare.i IsValidHexInput(Text.s)
  Declare.i IsValidFloatInput(Text.s)
  Declare.s TryParseAddress(Text.s, *Address)
  Declare.s TryParseTypedInteger(Text.s, ValueType.l, HexMode.i, *Value)
  Declare.s TryParseFloatingValue(Text.s, *Value)
  Declare.i ValueSizeFromType(ValueType.l)
  Declare.s FormatValueFromBits(Bits.q, ValueType.l)
  Declare AddScanTypeItem(Gadget.i, Label.s, ValueType.l)
  Declare.l GetSelectedScanValueType()
  Declare SetScanTypeSelection(ValueType.l)
  Declare.i WriteTextMemoryValue(hProcess.i, Address.i, ValueText.s, ValueType.l, *BytesWritten)
  Declare.i IsTextValueType(ValueType.l)
  Declare.i IsIntegerValueType(ValueType.l)
  Declare.i IsExecutableProtection(Protection.i)
  Declare.q NormalizeIntegerSearch(Value.q, ValueType.l)
  Declare.s NormalizeAOBPattern(Text.s)
  Declare.i IsValidAOBPattern(Text.s)
  Declare.i AOBPatternHasWildcard(Text.s)

  Procedure RefreshModuleList()

    Protected hSnapshot.i, me32.MODULEENTRY32_PB, Result.l
    ClearList(ModuleList())
    
    If Not SelectedProcess Or SelectedProcess = -1 : ProcedureReturn : EndIf
    
    hSnapshot = CreateToolhelp32Snapshot_(#TH32CS_SNAPMODULE | #TH32CS_SNAPMODULE32, SelectedProcess)
    If hSnapshot = -1 : ProcedureReturn : EndIf
    
    me32\dwSize = SizeOf(MODULEENTRY32_PB)
    Result = Module32First_(hSnapshot, @me32)
    If Result
      Repeat
        AddElement(ModuleList())
        ModuleList()\BaseAddress = me32\modBaseAddr
        ModuleList()\Size = me32\modBaseSize
        ModuleList()\Name = PeekS(@me32\szModule, -1, #PB_Ascii)
        ModuleList()\Path = PeekS(@me32\szExePath, -1, #PB_Ascii)
        Result = Module32Next_(hSnapshot, @me32)
      Until Result = 0
    EndIf
    CloseHandle_(hSnapshot)
  EndProcedure

Procedure ShowModuleWindow()
  If Not ProcessHandle Or SelectedProcess <= 0
    MessageRequester("Error", "Attach to a process before viewing modules.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  RefreshModuleList()
  If IsWindow(#ModulesWindow)
    CloseWindow(#ModulesWindow)
  EndIf

  If OpenWindow(#ModulesWindow, 0, 0, 800, 400, "Loaded Modules - " + Str(SelectedProcess), #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ListViewGadget(#ModulesListGadget, 10, 10, 780, 380)
    ForEach ModuleList()
      AddGadgetItem(#ModulesListGadget, -1, FormatAddress(ModuleList()\BaseAddress) + " - " + ModuleList()\Name + " (" + Str(ModuleList()\Size) + " bytes)")
    Next
  EndIf
EndProcedure


; Use PureBasic's built-in PROCESSENTRY32 (correct for Win11 x64/Unicode).
Procedure.s ExeNameFromEntry(*pe32.PROCESSENTRY32)
  ProcedureReturn PeekS(@*pe32\szExeFile)
EndProcedure

Procedure.s FormatAddress(Address.i)
  ProcedureReturn "0x" + RSet(Hex(Address), SizeOf(Integer) * 2, "0")
EndProcedure

Procedure.s GetProcessImagePath(ProcessID.l)
  Protected hProc.i, hKernel.i, hPsapi.i
  Protected path.s, size.l
  Protected buffer$
  Protected *QueryFullProcessImageName, *GetModuleFileNameEx

  ; Open process with the least rights that typically works.
  hProc = OpenProcess_(#PROCESS_QUERY_LIMITED_INFORMATION, 0, ProcessID)
  If hProc = 0
    hProc = OpenProcess_(#PROCESS_QUERY_INFORMATION | #PROCESS_VM_READ, 0, ProcessID)
  EndIf
  If hProc = 0
    ProcedureReturn ""
  EndIf

  size = 32768
  buffer$ = Space(size)

  ; 1) Try kernel32!QueryFullProcessImageNameW/A (not automatically imported by PB)
  hKernel = GetModuleHandle_("kernel32.dll")
  If hKernel
    CompilerIf #PB_Compiler_Unicode
      *QueryFullProcessImageName = GetProcAddress_(hKernel, "QueryFullProcessImageNameW")
    CompilerElse
      *QueryFullProcessImageName = GetProcAddress_(hKernel, "QueryFullProcessImageNameA")
    CompilerEndIf

    If *QueryFullProcessImageName
      If CallFunctionFast(*QueryFullProcessImageName, hProc, 0, @buffer$, @size)
        path = Left(buffer$, size)
      EndIf
    EndIf
  EndIf

  ; 2) Fallback: psapi!GetModuleFileNameExW/A
  If path = ""
    hPsapi = OpenLibrary(#PB_Any, "psapi.dll")
    If hPsapi
      CompilerIf #PB_Compiler_Unicode
        *GetModuleFileNameEx = GetFunction(hPsapi, "GetModuleFileNameExW")
      CompilerElse
        *GetModuleFileNameEx = GetFunction(hPsapi, "GetModuleFileNameExA")
      CompilerEndIf

      If *GetModuleFileNameEx
        size = Len(buffer$)
        If CallFunctionFast(*GetModuleFileNameEx, hProc, 0, @buffer$, size)
          path = buffer$
        EndIf
      EndIf

      CloseLibrary(hPsapi)
    EndIf
  EndIf

  CloseHandle_(hProc)
  ProcedureReturn path
EndProcedure

Enumeration ScanValueType
  #ValType_Byte = 1
  #ValType_Word = 2
  #ValType_Long = 4
  #ValType_Quad = 8
  #ValType_Float = 32
  #ValType_Double = 64
  #ValType_String = 128
  #ValType_Unicode = 129
  #ValType_AOB = 256
EndEnumeration


Enumeration ScanMode
  #ScanMode_Exact
  #ScanMode_Unknown
  #ScanMode_Changed
  #ScanMode_Unchanged
  #ScanMode_Increased
  #ScanMode_Decreased
EndEnumeration

Procedure.i IsTextValueType(ValueType.l)
  ProcedureReturn Bool(ValueType = #ValType_String Or ValueType = #ValType_Unicode Or ValueType = #ValType_AOB)
EndProcedure

Procedure.i IsIntegerValueType(ValueType.l)
  ProcedureReturn Bool(ValueType = #ValType_Byte Or ValueType = #ValType_Word Or ValueType = #ValType_Long Or ValueType = #ValType_Quad)
EndProcedure

Procedure.i IsExecutableProtection(Protection.i)
  Protected baseProtect.i = Protection & ~$FF00
  ProcedureReturn Bool(baseProtect = #PAGE_EXECUTE Or baseProtect = #PAGE_EXECUTE_READ Or baseProtect = #PAGE_EXECUTE_READWRITE Or baseProtect = #PAGE_EXECUTE_WRITECOPY)
EndProcedure

Procedure.q NormalizeIntegerSearch(Value.q, ValueType.l)
  Select ValueType
    Case #ValType_Byte
      ProcedureReturn Value & $FF
    Case #ValType_Word
      ProcedureReturn Value & $FFFF
    Case #ValType_Long
      ProcedureReturn Value & $FFFFFFFF
    Default
      ProcedureReturn Value
  EndSelect
EndProcedure

Procedure.s NormalizeAOBPattern(Text.s)
  Protected result.s
  Protected token.s
  Protected i.i

  For i = 1 To CountString(Trim(Text), " ") + 1
    token = UCase(Trim(StringField(Text, i, " ")))
    If token <> ""
      If result <> ""
        result + " "
      EndIf
      If token = "?"
        token = "??"
      EndIf
      result + token
    EndIf
  Next

  ProcedureReturn result
EndProcedure

Procedure.i IsValidAOBPattern(Text.s)
  Protected token.s
  Protected i.i
  Protected normalized.s = NormalizeAOBPattern(Text)

  If normalized = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To CountString(normalized, " ") + 1
    token = StringField(normalized, i, " ")
    If token <> "??"
      If Len(token) <> 2 Or token <> RSet(UCase(Hex(Val("$" + token) & $FF)), 2, "0")
        ProcedureReturn #False
      EndIf
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.i AOBPatternHasWildcard(Text.s)
  ProcedureReturn Bool(FindString(Text, "??", 1) > 0)
EndProcedure

Procedure.q ParseNumber(Text.s)
  Protected s.s = Trim(Text)
  If Left(s, 2) = "0x" Or Left(s, 2) = "0X"
    s = "$" + Mid(s, 3)
  EndIf
  ProcedureReturn Val(s)
EndProcedure

Procedure.d ParseDouble(Text.s)
  Protected s.s = Trim(Text)
  ProcedureReturn ValD(s)
EndProcedure

Procedure.i IsValidIntegerInput(Text.s)
  Protected s.s = Trim(Text)
  Protected isHex.i
  Protected i.i
  Protected ch.s

  If s = ""
    ProcedureReturn #False
  EndIf

  If Left(s, 1) = "+" Or Left(s, 1) = "-"
    s = Mid(s, 2)
  EndIf

  If s = ""
    ProcedureReturn #False
  EndIf

  If Left(s, 2) = "0x" Or Left(s, 2) = "0X"
    s = Mid(s, 3)
    isHex = #True
  ElseIf Left(s, 1) = "$"
    s = Mid(s, 2)
    isHex = #True
  EndIf

  If s = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(s)
    ch = Mid(s, i, 1)
    If isHex
      If FindString("0123456789ABCDEFabcdef", ch, 1) = 0
        ProcedureReturn #False
      EndIf
    ElseIf ch < "0" Or ch > "9"
      ProcedureReturn #False
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.i IsValidHexInput(Text.s)
  Protected s.s = ReplaceString(Trim(Text), " ", "")
  Protected i.i
  Protected ch.s

  If Left(s, 2) = "0x" Or Left(s, 2) = "0X"
    s = Mid(s, 3)
  ElseIf Left(s, 1) = "$"
    s = Mid(s, 2)
  EndIf

  If s = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(s)
    ch = Mid(s, i, 1)
    If FindString("0123456789ABCDEFabcdef", ch, 1) = 0
      ProcedureReturn #False
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure.i IsValidFloatInput(Text.s)
  Protected s.s = Trim(Text)
  Protected i.i
  Protected ch.s
  Protected hasDigit.i
  Protected hasExponent.i
  Protected hasDecimalPoint.i
  Protected allowSign.i = #True
  Protected requireDigitAfterExponent.i

  If s = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(s)
    ch = Mid(s, i, 1)

    If FindString("0123456789", ch, 1)
      hasDigit = #True
      allowSign = #False
      If requireDigitAfterExponent
        requireDigitAfterExponent = #False
      EndIf
    ElseIf ch = "." And Not hasDecimalPoint And Not hasExponent
      hasDecimalPoint = #True
      allowSign = #False
    ElseIf (ch = "e" Or ch = "E") And hasDigit And Not hasExponent
      hasExponent = #True
      allowSign = #True
      requireDigitAfterExponent = #True
    ElseIf (ch = "+" Or ch = "-") And allowSign
      allowSign = #False
    Else
      ProcedureReturn #False
    EndIf
  Next

  ProcedureReturn Bool(hasDigit And Not requireDigitAfterExponent)
EndProcedure

Procedure.s TryParseAddress(Text.s, *Address)
  If Not IsValidIntegerInput(Text)
    ProcedureReturn "Please enter a valid address."
  EndIf

  PokeI(*Address, ParseNumber(Text))
  ProcedureReturn ""
EndProcedure

Procedure.s TryParseTypedInteger(Text.s, ValueType.l, HexMode.i, *Value)
  Protected parsedNumber.q

  If HexMode
    If Not IsValidHexInput(Text)
      ProcedureReturn "Enter a valid hexadecimal value."
    EndIf
    parsedNumber = ParseHex(Text)
  Else
    If Not IsValidIntegerInput(Text)
      ProcedureReturn "Enter a valid integer value."
    EndIf
    parsedNumber = ParseNumber(Text)

    If valueType = #ValType_Byte And (parsedNumber < -128 Or parsedNumber > 255)
      ProcedureReturn "Byte range is -128..255"
    ElseIf valueType = #ValType_Word And (parsedNumber < -32768 Or parsedNumber > 65535)
      ProcedureReturn "Word range is -32768..65535"
    ElseIf valueType = #ValType_Long And (parsedNumber < -2147483648 Or parsedNumber > 4294967295)
      ProcedureReturn "Long range is -2147483648..4294967295"
    EndIf
  EndIf

  PokeQ(*Value, NormalizeIntegerSearch(parsedNumber, ValueType))
  ProcedureReturn ""
EndProcedure

Procedure.s TryParseFloatingValue(Text.s, *Value)
  If Not IsValidFloatInput(Text)
    ProcedureReturn "Enter a valid floating-point value."
  EndIf

  PokeD(*Value, ParseDouble(Text))
  ProcedureReturn ""
EndProcedure

Procedure.i ValueSizeFromType(ValueType.l)
  Select ValueType
    Case #ValType_Byte   : ProcedureReturn 1
    Case #ValType_Word   : ProcedureReturn 2
    Case #ValType_Long   : ProcedureReturn 4
    Case #ValType_Quad   : ProcedureReturn 8
    Case #ValType_Float  : ProcedureReturn 4
    Case #ValType_Double : ProcedureReturn 8
    Case #ValType_String : ProcedureReturn 1 ; min 1
    Case #ValType_Unicode : ProcedureReturn 2 ; min 2
    Case #ValType_AOB    : ProcedureReturn 1 ; min 1
  EndSelect

  ProcedureReturn 4
EndProcedure

Procedure.q BitsFromBuffer(*Buffer, Offset.i, ValueType.l)
  Protected b.q
  Select ValueType
    Case #ValType_Byte
      b = PeekA(*Buffer + Offset) & $FF
    Case #ValType_Word
      b = PeekW(*Buffer + Offset) & $FFFF
    Case #ValType_Long
      b = PeekL(*Buffer + Offset) & $FFFFFFFF
    Case #ValType_Quad
      b = PeekQ(*Buffer + Offset)
    Case #ValType_Float
      CopyMemory(*Buffer + Offset, @b, 4)
    Case #ValType_Double
      CopyMemory(*Buffer + Offset, @b, 8)
  EndSelect
  ProcedureReturn b
EndProcedure

Procedure.d DoubleFromBits(Bits.q, ValueType.l)
  Protected f.f, d.d
  Select ValueType
    Case #ValType_Float
      CopyMemory(@Bits, @f, 4)
      ProcedureReturn f
    Case #ValType_Double
      CopyMemory(@Bits, @d, 8)
      ProcedureReturn d
    Default
      ProcedureReturn Bits
  EndSelect
EndProcedure

Procedure.s FormatValueFromBits(Bits.q, ValueType.l)
  Select ValueType
    Case #ValType_Float, #ValType_Double
      ProcedureReturn StrD(DoubleFromBits(Bits, ValueType), 6)
    Case #ValType_String
      ProcedureReturn "String Data"
    Case #ValType_Unicode
      ProcedureReturn "Unicode Data"
    Case #ValType_AOB
      ProcedureReturn "AOB Pattern"
    Default
      ProcedureReturn Str(Bits)
  EndSelect
EndProcedure


Procedure.i CompareBits(Current.q, Previous.q, Mode.l, ValueType.l, SearchNumber.q, SearchFloat.d)
  Protected curD.d, prevD.d

  Select ValueType
    Case #ValType_Float, #ValType_Double
      curD = DoubleFromBits(Current, ValueType)
      prevD = DoubleFromBits(Previous, ValueType)

      Select Mode
        Case #ScanMode_Exact
          ProcedureReturn Bool(curD = SearchFloat)
        Case #ScanMode_Unknown
          ProcedureReturn #True
        Case #ScanMode_Changed
          ProcedureReturn Bool(curD <> prevD)
        Case #ScanMode_Unchanged
          ProcedureReturn Bool(curD = prevD)
        Case #ScanMode_Increased
          ProcedureReturn Bool(curD > prevD)
        Case #ScanMode_Decreased
          ProcedureReturn Bool(curD < prevD)
      EndSelect

    Default
      Select Mode
        Case #ScanMode_Exact
          ProcedureReturn Bool(Current = SearchNumber)
        Case #ScanMode_Unknown
          ProcedureReturn #True
        Case #ScanMode_Changed
          ProcedureReturn Bool(Current <> Previous)
        Case #ScanMode_Unchanged
          ProcedureReturn Bool(Current = Previous)
        Case #ScanMode_Increased
          ProcedureReturn Bool(Current > Previous)
        Case #ScanMode_Decreased
          ProcedureReturn Bool(Current < Previous)
      EndSelect
  EndSelect

  ProcedureReturn #False
EndProcedure

Procedure BeginListBatch(Gadget.i)
  If IsGadget(Gadget)
    SendMessage_(GadgetID(Gadget), #WM_SETREDRAW, 0, 0)
  EndIf
EndProcedure

Procedure EndListBatch(Gadget.i)
  If IsGadget(Gadget)
    SendMessage_(GadgetID(Gadget), #WM_SETREDRAW, 1, 0)
    RedrawWindow_(GadgetID(Gadget), 0, 0, #RDW_INVALIDATE | #RDW_UPDATENOW)
  EndIf
EndProcedure

; Structure for memory regions
Structure MemoryRegion
  BaseAddress.i
  Size.i
  Protection.l
EndStructure

; Structure for process information
Structure ProcessInfo
  ProcessID.l
  ParentProcessID.l
  ProcessName.s
  FullPath.s
  Description.s
  Company.s
  Version.s
  MemoryUsage.q
  ThreadCount.l
EndStructure

; Structure for scan results
Structure ScanResult
  Address.i
  ValueBits.q ; stores raw bits (int/float/double)
  ValueType.l
  DisplayValue.s
EndStructure


; Structure for frozen values (Cheat List)
Structure CheatEntry
  Address.i
  ValueBits.q
  ValueType.l
  Description.s
  DisplayValue.s
  Enabled.i
EndStructure

; Global variables
Global NewList ProcessList.PROCESSENTRY32()
Global NewList ScanResults.ScanResult()
Global NewList CheatList.CheatEntry()
Global NewList MemoryRegions.MemoryRegion()
Global ProcessCount.l
Global PreviousScanInitialized.i
Global ScanSessionValueType.l
Global MaxDisplayResults.i = 5000
Global ScanPauseRequested.i
Global ScanStopRequested.i
Global ScanThread.i
Global ScanMutex.i = CreateMutex()
Global CheatMutex.i = CreateMutex() ; Mutex for Cheat List
Global FreezeTimer.i = 0
Global FreezeInterval.i = 500 ; 500ms rewrite interval




; Structure for thread params
Structure ScanParams
  Mode.l
  ValueType.l
  SearchInt.q
  SearchFloat.d
  SearchString.s
  AOBPattern.s
  Aligned.i
  SkipReadOnly.i
  SkipExecutable.i
EndStructure


Global CurrentScanParams.ScanParams

; GUI Controls
Enumeration
  #MainWindow
  #ProcessListView
  #RefreshButton
  #AttachButton
  #ScanValueText
  #ScanButton
  #ScanTypeCombo
  #ScanModeCombo
  #FirstScanButton
  #NextScanButton
  #ResetScanButton
  #PauseScanButton
  #MaxResultsText
  #ApplyMaxResultsButton
  #ScanProgress
  #ResultsList
  #AddressText
  #ValueText
  #WriteButton
  #StatusBar
  #MemoryViewButton
  #ProcessFilterText
  #ProcessInfoButton
  #ProcessInfoWindow
  #ProcessInfoText
  #ButtonAbout
  #ButtonExit
  #AlignedCheck ; New: Alignment checkbox
  #HexCheck ; New: Hexadecimal search checkbox
  #SkipReadOnlyCheck ; New: Skip Read-Only
  #SkipExecCheck ; New: Skip Executable
  #CheatListView ; New: List of saved/frozen addresses

  #AddCheatButton ; New: Add to cheat list button
  #RemoveCheatButton ; New: Remove from cheat list button
EndEnumeration

; Function declarations
Declare RefreshProcessList()
Declare AttachToProcess()
Declare ScanMemoryThread(*Params.ScanParams)
Declare ScanMemory()
Declare ResetScan()
Declare TogglePauseScan()
Declare UpdateMaxResults()
Declare WriteMemoryValue()
Declare GetMemoryRegions()
Declare ViewMemoryAtAddress()
Declare ShowProcessInfo()
Declare GetProcessInformation(ProcessID.l, *Info.ProcessInfo)
Declare.s GetFileDescription(FilePath.s)
Declare.s GetFileCompany(FilePath.s)
Declare.s GetFileVersion(FilePath.s)
Declare UpdateResultsUI() ; New: Update UI from thread results
Declare UpdateCheatListUI() ; New: Update the saved cheat list
Declare HandleFreezeTimer() ; New: Periodically re-write frozen values
Declare AddScanTypeItem(Gadget.i, Label.s, ValueType.l)
Declare.l GetSelectedScanValueType()
Declare SetScanTypeSelection(ValueType.l)
Declare.i TryGetScanResultByIndex(Index.i, *Result.ScanResult)

; Helper: Parse hexadecimal string (e.g., "90 90 90" or "0x1234")
Procedure.q ParseHex(Text.s)
  Protected s.s = Trim(Text)
  If Left(s, 2) = "0x" Or Left(s, 2) = "0X"
    s = Mid(s, 3)
  EndIf
  ProcedureReturn Val("$" + ReplaceString(s, " ", ""))
EndProcedure

Procedure AddScanTypeItem(Gadget.i, Label.s, ValueType.l)
  AddGadgetItem(Gadget, -1, Label)
  SetGadgetItemData(Gadget, CountGadgetItems(Gadget) - 1, ValueType)
EndProcedure

Procedure.l GetSelectedScanValueType()
  Protected index.i = GetGadgetState(#ScanTypeCombo)
  If index >= 0
    ProcedureReturn GetGadgetItemData(#ScanTypeCombo, index)
  EndIf

  ProcedureReturn #ValType_Long
EndProcedure

Procedure SetScanTypeSelection(ValueType.l)
  Protected i.i
  For i = 0 To CountGadgetItems(#ScanTypeCombo) - 1
    If GetGadgetItemData(#ScanTypeCombo, i) = ValueType
      SetGadgetState(#ScanTypeCombo, i)
      Break
    EndIf
  Next
EndProcedure

Procedure.i TryGetScanResultByIndex(Index.i, *Result.ScanResult)
  Protected found.i = #False

  LockMutex(ScanMutex)
  If Index >= 0 And SelectElement(ScanResults(), Index)
    *Result\Address = ScanResults()\Address
    *Result\ValueBits = ScanResults()\ValueBits
    *Result\ValueType = ScanResults()\ValueType
    *Result\DisplayValue = ScanResults()\DisplayValue
    found = #True
  EndIf
  UnlockMutex(ScanMutex)

  ProcedureReturn found
EndProcedure

Procedure.i WriteTextMemoryValue(hProcess.i, Address.i, ValueText.s, ValueType.l, *BytesWritten)
  Protected textLen.i
  Protected *textBuffer
  Protected i.i

  Select ValueType
    Case #ValType_String
      textLen = Len(ValueText)
      If textLen > 0
        ProcedureReturn WriteProcessMemory_(hProcess, Address, @ValueText, textLen, *BytesWritten)
      EndIf

    Case #ValType_Unicode
      textLen = Len(ValueText) * SizeOf(Character)
      If textLen > 0
        ProcedureReturn WriteProcessMemory_(hProcess, Address, @ValueText, textLen, *BytesWritten)
      EndIf

    Case #ValType_AOB
      ValueText = NormalizeAOBPattern(ValueText)
      If Not IsValidAOBPattern(ValueText) Or AOBPatternHasWildcard(ValueText)
        ProcedureReturn #False
      EndIf

      textLen = CountString(ValueText, " ") + 1
      If textLen > 0
        *textBuffer = AllocateMemory(textLen)
        If *textBuffer
          For i = 0 To textLen - 1
            PokeA(*textBuffer + i, Val("$" + StringField(ValueText, i + 1, " ")) & $FF)
          Next
          i = WriteProcessMemory_(hProcess, Address, *textBuffer, textLen, *BytesWritten)
          FreeMemory(*textBuffer)
          ProcedureReturn i
        EndIf
      EndIf
  EndSelect

  ProcedureReturn #False
EndProcedure

Procedure UpdateCheatListUI()
  LockMutex(CheatMutex)
  BeginListBatch(#CheatListView)
  ClearGadgetItems(#CheatListView)
  
  ForEach CheatList()
    Protected Status.s = " "
    If CheatList()\Enabled : Status = "[X] " : EndIf
    If IsTextValueType(CheatList()\ValueType)
      AddGadgetItem(#CheatListView, -1, Status + FormatAddress(CheatList()\Address) + " = " + CheatList()\DisplayValue + " (" + CheatList()\Description + ")")
    Else
      AddGadgetItem(#CheatListView, -1, Status + FormatAddress(CheatList()\Address) + " = " + FormatValueFromBits(CheatList()\ValueBits, CheatList()\ValueType) + " (" + CheatList()\Description + ")")
    EndIf
  Next
  
  EndListBatch(#CheatListView)
  UnlockMutex(CheatMutex)
EndProcedure

Procedure StopScanThread(WaitForThread.i)
  If IsThread(ScanThread)
    ScanStopRequested = #True
    ScanPauseRequested = #False
    If WaitForThread
      WaitThread(ScanThread)
      ScanThread = 0
    EndIf
  Else
    ScanThread = 0
  EndIf
EndProcedure

Procedure CleanupAndQuit()
  StopScanThread(#True)
  RemoveWindowTimer(#MainWindow, #FreezeTimerID)
  If MemoryViewFont
    FreeFont(MemoryViewFont)
    MemoryViewFont = 0
  EndIf
  If ProcessInfoFont
    FreeFont(ProcessInfoFont)
    ProcessInfoFont = 0
  EndIf
  If ProcessHandle
    CloseHandle_(ProcessHandle)
    ProcessHandle = 0
  EndIf
  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
  If ScanMutex
    FreeMutex(ScanMutex)
    ScanMutex = 0
  EndIf
  If CheatMutex
    FreeMutex(CheatMutex)
    CheatMutex = 0
  EndIf
EndProcedure

Procedure HandleFreezeTimer()
  Protected BytesWritten.i
  LockMutex(CheatMutex)
  If ProcessHandle
    ForEach CheatList()
      If CheatList()\Enabled
        If IsTextValueType(CheatList()\ValueType)
          WriteTextMemoryValue(ProcessHandle, CheatList()\Address, CheatList()\DisplayValue, CheatList()\ValueType, @BytesWritten)
        Else
          WriteProcessMemory_(ProcessHandle, CheatList()\Address, @CheatList()\ValueBits, ValueSizeFromType(CheatList()\ValueType), @BytesWritten)
        EndIf
      EndIf
    Next
  EndIf
  UnlockMutex(CheatMutex)
EndProcedure

Procedure UpdateResultsUI()
  Protected resultCount.i = 0
  Protected itemText.s
  
  LockMutex(ScanMutex)
  BeginListBatch(#ResultsList)
  ClearGadgetItems(#ResultsList)
  
  ForEach ScanResults()
    If resultCount < MaxDisplayResults
      If IsTextValueType(ScanResults()\ValueType)
        itemText = FormatAddress(ScanResults()\Address) + " = " + ScanResults()\DisplayValue
      Else
        itemText = FormatAddress(ScanResults()\Address) + " = " + FormatValueFromBits(ScanResults()\ValueBits, ScanResults()\ValueType)
      EndIf
      AddGadgetItem(#ResultsList, -1, itemText)
    EndIf
    resultCount + 1
  Next

  
  EndListBatch(#ResultsList)
  
  If resultCount > MaxDisplayResults
    StatusBarText(#StatusBar, 0, "Scan complete. Matches: " + Str(resultCount) + " (showing first " + Str(MaxDisplayResults) + ")")
  Else
    StatusBarText(#StatusBar, 0, "Scan complete. Matches: " + Str(resultCount))
  EndIf
  UnlockMutex(ScanMutex)
EndProcedure

; Scan memory implementation (Threaded)
Procedure ScanMemoryThread(*Params.ScanParams)
  Protected mode.l = *Params\Mode
  Protected valueType.l = *Params\ValueType
  Protected searchInt.q = *Params\SearchInt
  Protected searchFloat.d = *Params\SearchFloat
  Protected searchString.s = *Params\SearchString
  Protected aobPattern.s = *Params\AOBPattern
  Protected aligned.i = *Params\Aligned
  Protected bytesRead.i
  Protected bufferSize.i = 65536
  Protected minReadSize.i
  Protected *buffer
  Protected i.i, stepSize.i = ValueSizeFromType(valueType)
  Protected iterStep.i = 1
  Protected resultCount.i = 0
  Protected overlapSize.i = 0
  Protected carryBytes.i = 0
  Protected rawValue.s
  Protected bufferBaseAddr.i
  Protected totalRegions.i
  Protected regionIndex.i
  Protected totalHitsNext.i
  Protected hitIndexNext.i
  Protected pat.s
  Protected tokenCount.i
  Protected *aobBytes
  Protected *aobMask
  Protected p.i
  
  ; For String/AOB
  Protected searchLen.i = 0
  If valueType = #ValType_String
    searchLen = Len(searchString)
    stepSize = searchLen
  ElseIf valueType = #ValType_Unicode
    searchLen = Len(searchString) * 2
    stepSize = searchLen
  ElseIf valueType = #ValType_AOB
    tokenCount = CountString(aobPattern, " ") + 1
    searchLen = tokenCount
    stepSize = searchLen
    *aobBytes = AllocateMemory(searchLen)
    *aobMask = AllocateMemory(searchLen)
    If *aobBytes = 0 Or *aobMask = 0
      If *aobBytes : FreeMemory(*aobBytes) : EndIf
      If *aobMask : FreeMemory(*aobMask) : EndIf
      PostEvent(#PB_Event_Gadget, #MainWindow, #ScanButton, #PB_EventType_FirstCustomValue)
      ProcedureReturn
    EndIf
    FillMemory(*aobBytes, searchLen, 0)
    FillMemory(*aobMask, searchLen, 0)
    For p = 0 To searchLen - 1
      pat = StringField(aobPattern, p + 1, " ")
      If pat <> "??" And pat <> "?"
        PokeA(*aobBytes + p, Val("$" + pat) & $FF)
        PokeA(*aobMask + p, 1)
      EndIf
    Next
  EndIf

  If searchLen > 0
    overlapSize = searchLen - 1
  ElseIf stepSize > 1
    overlapSize = stepSize - 1
  EndIf

  minReadSize = bufferSize + overlapSize
  *buffer = AllocateMemory(minReadSize)
  If *buffer = 0
    If *aobBytes : FreeMemory(*aobBytes) : EndIf
    If *aobMask : FreeMemory(*aobMask) : EndIf
    PostEvent(#PB_Event_Gadget, #MainWindow, #ScanButton, #PB_EventType_FirstCustomValue)
    ProcedureReturn
  EndIf

  If aligned And valueType < #ValType_String ; No alignment for strings/AOB by default
    iterStep = ValueSizeFromType(valueType)
  EndIf

  If PreviousScanInitialized = #False
    LockMutex(ScanMutex)
    ClearList(ScanResults())
    UnlockMutex(ScanMutex)
    
    totalRegions = ListSize(MemoryRegions())
    regionIndex = 0
    
    ForEach MemoryRegions()
      If ScanStopRequested
        Break
      EndIf

      ; Protection filtering
      Protected protect.i = MemoryRegions()\Protection & ~$FF00
      If *Params\SkipReadOnly And protect = #PAGE_READONLY
        Continue
      EndIf
      If *Params\SkipExecutable And IsExecutableProtection(MemoryRegions()\Protection)
        Continue
      EndIf

      regionIndex + 1
      If totalRegions > 0
        PostEvent(#PB_Event_Gadget, #MainWindow, #ScanProgress, #PB_EventType_Change, (regionIndex * 100) / totalRegions)
      EndIf
      
      While ScanPauseRequested And Not ScanStopRequested
        Delay(50)
      Wend
      If ScanStopRequested
        Break
      EndIf

      Protected base.i = MemoryRegions()\BaseAddress
      Protected endAddr.i = base + MemoryRegions()\Size
      Protected addr.i = base
      carryBytes = 0

      While addr < endAddr
        Protected readSize.i = bufferSize
        If addr + readSize > endAddr
          readSize = endAddr - addr
        EndIf

        If ReadProcessMemory_(ProcessHandle, addr, *buffer + carryBytes, readSize, @bytesRead) And bytesRead > 0
          bufferBaseAddr = addr - carryBytes
          bytesRead + carryBytes
          Protected limit.i = bytesRead - stepSize
          If limit >= 0
            i = 0
            While i <= limit
              Protected match.i = #False
              
              If valueType = #ValType_String
                If PeekS(*buffer + i, searchLen, #PB_Ascii) = searchString
                  match = #True
                EndIf
              ElseIf valueType = #ValType_Unicode
                If PeekS(*buffer + i, Len(searchString), #PB_Unicode) = searchString
                  match = #True
                EndIf
              ElseIf valueType = #ValType_AOB
                match = #True
                For p = 0 To searchLen - 1
                  If PeekA(*aobMask + p)
                    If (PeekA(*buffer + i + p) & $FF) <> (PeekA(*aobBytes + p) & $FF)
                      match = #False
                      Break
                    EndIf
                  EndIf
                Next
              Else
                Protected curBits.q = BitsFromBuffer(*buffer, i, valueType)
                match = CompareBits(curBits, 0, mode, valueType, searchInt, searchFloat)
              EndIf

              If match
                LockMutex(ScanMutex)
                AddElement(ScanResults())
                ScanResults()\Address = bufferBaseAddr + i
                If valueType < #ValType_String
                  ScanResults()\ValueBits = BitsFromBuffer(*buffer, i, valueType)
                ElseIf valueType = #ValType_String
                  ScanResults()\DisplayValue = PeekS(*buffer + i, searchLen, #PB_Ascii)
                ElseIf valueType = #ValType_Unicode
                  ScanResults()\DisplayValue = PeekS(*buffer + i, Len(searchString), #PB_Unicode)
                Else
                  Protected h.i, hs.s = ""
                  For h = 0 To searchLen - 1
                    hs + RSet(Hex(PeekA(*buffer + i + h) & $FF), 2, "0") + " "
                  Next
                  ScanResults()\DisplayValue = Trim(hs)
                EndIf
                ScanResults()\ValueType = valueType
                UnlockMutex(ScanMutex)
                resultCount + 1
              EndIf
              i + iterStep
            Wend
          EndIf
        EndIf

        If bytesRead <= carryBytes
          Break
        EndIf

        If overlapSize > 0
          carryBytes = overlapSize
          If carryBytes > bytesRead
            carryBytes = bytesRead
          EndIf
          MoveMemory(*buffer + bytesRead - carryBytes, *buffer, carryBytes)
        Else
          carryBytes = 0
        EndIf

        addr + (bytesRead - carryBytes)

        While ScanPauseRequested And Not ScanStopRequested
          Delay(50)
        Wend
        If ScanStopRequested
          Break
        EndIf
      Wend
    Next
    If Not ScanStopRequested
      PreviousScanInitialized = #True
      ScanSessionValueType = valueType
    EndIf
  Else
    ; NEXT SCAN (Filter existing results)
    totalHitsNext = ListSize(ScanResults())
    hitIndexNext = 0

    LockMutex(ScanMutex)
    ResetList(ScanResults())
    While NextElement(ScanResults())
      If ScanStopRequested
        Break
      EndIf

      hitIndexNext + 1
      UnlockMutex(ScanMutex)
      
      If totalHitsNext > 0
        PostEvent(#PB_Event_Gadget, #MainWindow, #ScanProgress, #PB_EventType_Change, (hitIndexNext * 100) / totalHitsNext)
      EndIf

      While ScanPauseRequested And Not ScanStopRequested
        Delay(50)
      Wend
      If ScanStopRequested
        LockMutex(ScanMutex)
        Break
      EndIf
      
      LockMutex(ScanMutex)
      Protected aNext.i = ScanResults()\Address
      Protected oldTextValue.s = ScanResults()\DisplayValue
      UnlockMutex(ScanMutex)

      If ReadProcessMemory_(ProcessHandle, aNext, *buffer, stepSize, @bytesRead) And bytesRead = stepSize
        Protected matchNext.i = #False
        
        If valueType = #ValType_String
          rawValue = PeekS(*buffer, searchLen, #PB_Ascii)
        ElseIf valueType = #ValType_Unicode
          rawValue = PeekS(*buffer, Len(searchString), #PB_Unicode)
        ElseIf valueType = #ValType_AOB
          matchNext = #True
          rawValue = ""
          For p = 0 To searchLen - 1
            rawValue + RSet(Hex(PeekA(*buffer + p) & $FF), 2, "0")
            If p < searchLen - 1
              rawValue + " "
            EndIf
            If PeekA(*aobMask + p)
              If (PeekA(*buffer + p) & $FF) <> (PeekA(*aobBytes + p) & $FF)
                matchNext = #False
                Break
              EndIf
            EndIf
          Next
        EndIf

        If IsTextValueType(valueType)
          Select mode
            Case #ScanMode_Exact
              If valueType = #ValType_AOB
                matchNext = Bool(matchNext)
              Else
                matchNext = Bool(rawValue = searchString)
              EndIf
            Case #ScanMode_Unknown
              matchNext = #True
            Case #ScanMode_Changed
              matchNext = Bool(rawValue <> oldTextValue)
            Case #ScanMode_Unchanged
              matchNext = Bool(rawValue = oldTextValue)
            Default
              matchNext = #False
          EndSelect

          If matchNext
            LockMutex(ScanMutex)
            ScanResults()\DisplayValue = rawValue
            UnlockMutex(ScanMutex)
          EndIf
        Else
          Protected newBitsNext.q = BitsFromBuffer(*buffer, 0, valueType)
          LockMutex(ScanMutex)
          Protected oldBitsNext.q = ScanResults()\ValueBits
          matchNext = CompareBits(newBitsNext, oldBitsNext, mode, valueType, searchInt, searchFloat)
          If matchNext
            ScanResults()\ValueBits = newBitsNext
          EndIf
          UnlockMutex(ScanMutex)
        EndIf

        If Not matchNext
          LockMutex(ScanMutex)
          DeleteElement(ScanResults())
          UnlockMutex(ScanMutex)
        Else
          resultCount + 1
        EndIf
      Else
        LockMutex(ScanMutex)
        DeleteElement(ScanResults())
        UnlockMutex(ScanMutex)
      EndIf
      LockMutex(ScanMutex)
    Wend
    UnlockMutex(ScanMutex)
  EndIf

  FreeMemory(*buffer)
  If *aobBytes : FreeMemory(*aobBytes) : EndIf
  If *aobMask : FreeMemory(*aobMask) : EndIf
  If ScanStopRequested
    ScanStopRequested = #False
  EndIf
  ScanPauseRequested = #False
  ScanThread = 0

  PostEvent(#PB_Event_Gadget, #MainWindow, #ScanButton, #PB_EventType_FirstCustomValue) ; Signal completion
EndProcedure

; Scan memory for specific value / next scan
Procedure ScanMemory()
  Protected mode.l = GetGadgetState(#ScanModeCombo)
  Protected valueType.l = GetSelectedScanValueType()
  Protected searchNumberText.s
  Protected parseError.s
  
  If IsThread(ScanThread)
    MessageRequester("Info", "Scan is already running!", #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  If Not ProcessHandle
    MessageRequester("Error", "No process attached!", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  searchNumberText = Trim(GetGadgetText(#ScanValueText))

  ; Validate scan mode vs scan state
  If mode <> #ScanMode_Exact And mode <> #ScanMode_Unknown And PreviousScanInitialized = #False
    MessageRequester("Error", "Run a First Scan (Exact/Unknown) before Next Scan filters.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  ; Enforce consistent value type across Next Scans
  If PreviousScanInitialized And mode <> #ScanMode_Exact And mode <> #ScanMode_Unknown
    If ScanSessionValueType <> 0 And valueType <> ScanSessionValueType
      MessageRequester("Error", "Data type changed since First Scan. Reset scan first.", #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
  EndIf

  If IsTextValueType(valueType) And mode <> #ScanMode_Exact And mode <> #ScanMode_Unknown And mode <> #ScanMode_Changed And mode <> #ScanMode_Unchanged
    MessageRequester("Error", "String, Unicode, and AOB scans support Exact, Unknown, Changed, and Unchanged modes only.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  If IsTextValueType(valueType) And mode = #ScanMode_Unknown
    MessageRequester("Error", "Unknown scans are not supported for String, Unicode, or AOB types. Start with an Exact scan instead.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  CurrentScanParams\Mode = mode
  CurrentScanParams\ValueType = valueType
  CurrentScanParams\Aligned = GetGadgetState(#AlignedCheck)
  CurrentScanParams\SkipReadOnly = GetGadgetState(#SkipReadOnlyCheck)
  CurrentScanParams\SkipExecutable = GetGadgetState(#SkipExecCheck)
  CurrentScanParams\SearchInt = 0
  CurrentScanParams\SearchFloat = 0
  CurrentScanParams\SearchString = ""
  CurrentScanParams\AOBPattern = ""
  
  If mode = #ScanMode_Exact
    If searchNumberText = ""
      MessageRequester("Error", "Please enter a value for Exact scan.", #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf

    If valueType = #ValType_String Or valueType = #ValType_Unicode
      CurrentScanParams\SearchString = searchNumberText
    ElseIf valueType = #ValType_AOB
      CurrentScanParams\AOBPattern = NormalizeAOBPattern(searchNumberText)
      If Not IsValidAOBPattern(CurrentScanParams\AOBPattern)
        MessageRequester("Error", "Enter an AOB pattern like '8B 45 ?? 50'.", #PB_MessageRequester_Error)
        ProcedureReturn
      EndIf
    ElseIf valueType = #ValType_Float Or valueType = #ValType_Double
      parseError = TryParseFloatingValue(searchNumberText, @CurrentScanParams\SearchFloat)
      If parseError <> ""
        MessageRequester("Error", parseError, #PB_MessageRequester_Error)
        ProcedureReturn
      EndIf
    ElseIf GetGadgetState(#HexCheck) = #PB_Checkbox_Checked
      parseError = TryParseTypedInteger(searchNumberText, valueType, #True, @CurrentScanParams\SearchInt)
      If parseError <> ""
        MessageRequester("Error", parseError, #PB_MessageRequester_Error)
        ProcedureReturn
      EndIf
    Else
      parseError = TryParseTypedInteger(searchNumberText, valueType, #False, @CurrentScanParams\SearchInt)
      If parseError <> ""
        MessageRequester("Error", parseError, #PB_MessageRequester_Error)
        ProcedureReturn
      EndIf
    EndIf
  EndIf

  ScanPauseRequested = #False
  ScanStopRequested = #False
  StatusBarText(#StatusBar, 0, "Scanning (Threaded)...")
  ScanThread = CreateThread(@ScanMemoryThread(), @CurrentScanParams)
EndProcedure


; Refresh process list using ToolHelp32
Procedure RefreshProcessList()
  Protected hSnapshot.i, pe32.PROCESSENTRY32, Result.l
  Protected ProcessName.s
  Protected FilterText.s
  
  ; Get filter text
  FilterText = UCase(GetGadgetText(#ProcessFilterText))
  
  ; Clear existing process list
  ClearList(ProcessList())
  ClearGadgetItems(#ProcessListView)
  ProcessCount = 0
  
  ; Create snapshot of all running processes
  hSnapshot = CreateToolhelp32Snapshot_(#TH32CS_SNAPPROCESS, 0)
  If hSnapshot = -1
    MessageRequester("Error", "Failed to create process snapshot!", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  
  ; Set up PROCESSENTRY32 structure
  pe32\dwSize = SizeOf(PROCESSENTRY32)
  
  ; Get first process
  Result = Process32First_(hSnapshot, @pe32)
  If Result
    Repeat
      ; Extract process name
      ProcessName = ExeNameFromEntry(@pe32)
      
      ; Skip system processes and ourselves
      If ProcessName <> "" And pe32\th32ProcessID > 4
        ; Apply filter if specified
          If FilterText = "" Or FindString(UCase(ProcessName), FilterText)
            AddElement(ProcessList())
            ProcessList() = pe32
            
            ; Add to GUI list
            AddGadgetItem(#ProcessListView, -1, ProcessName + " (PID: " + Str(pe32\th32ProcessID) + ")")
            ProcessCount + 1
          EndIf
      EndIf
      
      ; Get next process
      Result = Process32Next_(hSnapshot, @pe32)
    Until Result = 0
  EndIf
  
  CloseHandle_(hSnapshot)
  StatusBarText(#StatusBar, 0, "Found " + Str(ProcessCount) + " processes")
EndProcedure

; Attach to selected process
Procedure AttachToProcess()
Protected Selection.l, *Process.PROCESSENTRY32
  Protected accessMask.i
  
  Selection = GetGadgetState(#ProcessListView)
  If Selection >= 0 And Selection < ProcessCount
    ; Get selected process from list
    SelectElement(ProcessList(), Selection)
    *Process = @ProcessList()
    
    ; Close previous handle if exists
    If ProcessHandle
      CloseHandle_(ProcessHandle)
      ProcessHandle = 0
    EndIf
    SelectedProcess = -1
    ClearList(MemoryRegions())
    ResetScan()
    
    ; Open process with required access rights
    accessMask = #PROCESS_QUERY_INFORMATION | #PROCESS_QUERY_LIMITED_INFORMATION | #PROCESS_VM_READ | #PROCESS_VM_WRITE | #PROCESS_VM_OPERATION
    ProcessHandle = OpenProcess_(accessMask, 0, *Process\th32ProcessID)
    If ProcessHandle
      SelectedProcess = *Process\th32ProcessID
      StatusBarText(#StatusBar, 0, "Attached to: " + ExeNameFromEntry(*Process) + " (PID: " + Str(*Process\th32ProcessID) + ")")
      ResetScan()
      GetMemoryRegions()
    Else
      MessageRequester("Error", "Failed to attach to process. Try running as administrator." + Chr(10) + "Error: " + Str(GetLastError_()))
    EndIf
  Else
    MessageRequester("Error", "Please select a process first!", #PB_MessageRequester_Error)
  EndIf
EndProcedure

; Get readable/writable memory regions
Procedure GetMemoryRegions()
  Protected mbi.MEMORY_BASIC_INFORMATION, Address.i, *NewRegion.MemoryRegion
  Protected RegionCount.l, MaxAddress.i
  Protected protect.i

  If Not ProcessHandle
    ProcedureReturn
  EndIf

  ClearList(MemoryRegions())
  Address = 0
  RegionCount = 0

  ; Set reasonable upper limit to prevent infinite loops
  CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
    MaxAddress = $7FFFFFFF0000
  CompilerElse
    MaxAddress = $7FFFFFFF
  CompilerEndIf

  While Address < MaxAddress
    If VirtualQueryEx_(ProcessHandle, Address, @mbi, SizeOf(MEMORY_BASIC_INFORMATION)) = 0
      Break
    EndIf

    protect = mbi\Protect & ~$FF00 ; strip out modifier flags like PAGE_GUARD

    ; Include readable regions (not just RW), but exclude guard/noaccess.
    If mbi\State = #MEM_COMMIT And (mbi\Protect & #PAGE_GUARD) = 0 And protect <> #PAGE_NOACCESS
      If protect = #PAGE_READONLY Or protect = #PAGE_READWRITE Or protect = #PAGE_WRITECOPY Or protect = #PAGE_EXECUTE_READ Or protect = #PAGE_EXECUTE_READWRITE Or protect = #PAGE_EXECUTE_WRITECOPY
        *NewRegion = AddElement(MemoryRegions())
        *NewRegion\BaseAddress = mbi\BaseAddress
        *NewRegion\Size = mbi\RegionSize
        *NewRegion\Protection = mbi\Protect
        RegionCount + 1
      EndIf
    EndIf


    ; Move to next region
    Address = mbi\BaseAddress + mbi\RegionSize

    ; Safety check to prevent infinite loop
    If Address <= mbi\BaseAddress
      Break
    EndIf
  Wend

  StatusBarText(#StatusBar, 0, "Found " + Str(RegionCount) + " memory regions for scanning")
EndProcedure

Procedure ResetScan()
  StopScanThread(#True)
  PreviousScanInitialized = #False
  ScanSessionValueType = 0
  ScanPauseRequested = #False
  ScanStopRequested = #False
  If IsGadget(#PauseScanButton)
    SetGadgetText(#PauseScanButton, "Pause")
  EndIf
  ClearList(ScanResults())
  BeginListBatch(#ResultsList)
  ClearGadgetItems(#ResultsList)
  EndListBatch(#ResultsList)
  If IsGadget(#ScanProgress)
    SetGadgetState(#ScanProgress, 0)
  EndIf
  StatusBarText(#StatusBar, 0, "Scan reset.")
EndProcedure

Procedure UpdateMaxResults()
  Protected v.i = Val(Trim(GetGadgetText(#MaxResultsText)))
  If v <= 0
    v = 5000
  EndIf
  MaxDisplayResults = v
  SetGadgetText(#MaxResultsText, Str(MaxDisplayResults))
  If Not IsThread(ScanThread)
    UpdateResultsUI()
  EndIf
EndProcedure

Procedure TogglePauseScan()
  If Not IsThread(ScanThread)
    ProcedureReturn
  EndIf

  ScanPauseRequested ! 1
  If ScanPauseRequested
    SetGadgetText(#PauseScanButton, "Resume")
    StatusBarText(#StatusBar, 0, "Paused.")
  Else
    SetGadgetText(#PauseScanButton, "Pause")
    StatusBarText(#StatusBar, 0, "Resumed.")
  EndIf
EndProcedure

; Write value to memory address

Procedure WriteMemoryValue()
  Protected Address.i, BytesWritten.i
  Protected Value.q
  Protected FloatValue.d
  Protected AddressText.s, ValueText.s
  Protected parseError.s
  Protected WriteSize.i
  Protected valueType.l = GetSelectedScanValueType()
  
  If Not ProcessHandle
    MessageRequester("Error", "No process attached!", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  
  AddressText = GetGadgetText(#AddressText)
  ValueText = GetGadgetText(#ValueText)
  
  If AddressText = "" Or ValueText = ""
    MessageRequester("Error", "Please enter both address and value!", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  parseError = TryParseAddress(AddressText, @Address)
  If parseError <> ""
    MessageRequester("Error", parseError, #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  If valueType = #ValType_Float Or valueType = #ValType_Double
    parseError = TryParseFloatingValue(ValueText, @FloatValue)
    If parseError <> ""
      MessageRequester("Error", parseError, #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
  ElseIf valueType = #ValType_AOB
    ValueText = NormalizeAOBPattern(ValueText)
    If Not IsValidAOBPattern(ValueText)
      MessageRequester("Error", "Enter an AOB pattern like '8B 45 ?? 50'.", #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
    If AOBPatternHasWildcard(ValueText)
      MessageRequester("Error", "AOB writes require concrete bytes; wildcards are only supported for scans.", #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
  ElseIf Not IsTextValueType(valueType)
    parseError = TryParseTypedInteger(ValueText, valueType, #False, @Value)
    If parseError <> ""
      MessageRequester("Error", parseError, #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf
  EndIf
  
  ; Determine write size based on scan type
  Select valueType
    Case #ValType_Byte: WriteSize = 1
    Case #ValType_Word: WriteSize = 2
    Case #ValType_Long, #ValType_Float: WriteSize = 4
    Case #ValType_Quad, #ValType_Double: WriteSize = 8
    Default: WriteSize = 4
  EndSelect

  ; NOTE: Float/Double/String/AOB writes use ValueText directly.
  If valueType = #ValType_Float
    Protected f.f = FloatValue
    If WriteProcessMemory_(ProcessHandle, Address, @f, WriteSize, @BytesWritten)
      StatusBarText(#StatusBar, 0, "Successfully wrote value " + StrF(f) + " to address " + FormatAddress(Address))
      ProcedureReturn
    EndIf
  ElseIf valueType = #ValType_Double
    Protected d.d = FloatValue
    If WriteProcessMemory_(ProcessHandle, Address, @d, WriteSize, @BytesWritten)
      StatusBarText(#StatusBar, 0, "Successfully wrote value " + StrD(d) + " to address " + FormatAddress(Address))
      ProcedureReturn
    EndIf
  ElseIf valueType = #ValType_String
    If WriteTextMemoryValue(ProcessHandle, Address, ValueText, valueType, @BytesWritten)
      StatusBarText(#StatusBar, 0, "Successfully wrote string to address " + FormatAddress(Address))
      ProcedureReturn
    EndIf
  ElseIf valueType = #ValType_Unicode
    If WriteTextMemoryValue(ProcessHandle, Address, ValueText, valueType, @BytesWritten)
      StatusBarText(#StatusBar, 0, "Successfully wrote Unicode string to address " + FormatAddress(Address))
      ProcedureReturn
    EndIf
  ElseIf valueType = #ValType_AOB
    If WriteTextMemoryValue(ProcessHandle, Address, ValueText, valueType, @BytesWritten)
      StatusBarText(#StatusBar, 0, "Successfully wrote AOB to address " + FormatAddress(Address))
      ProcedureReturn
    EndIf
  EndIf

  If WriteProcessMemory_(ProcessHandle, Address, @Value, WriteSize, @BytesWritten)
    StatusBarText(#StatusBar, 0, "Successfully wrote value " + Str(Value) + " to address " + FormatAddress(Address))
  Else
    MessageRequester("Error", "Failed to write memory at address " + FormatAddress(Address) + Chr(10) + "Error: " + Str(GetLastError_()))
  EndIf
EndProcedure

; View memory at specific address
Procedure ViewMemoryAtAddress()
  Protected Address.i, ViewSize.i = 256, *ViewBuffer, ViewBytesRead.i
  Protected HexDisplay.s, AsciiDisplay.s, i.i, ByteVal.a
  Protected AddressStr.s
  Protected parseError.s
  
  If Not ProcessHandle
    MessageRequester("Error", "No process attached!", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  
  AddressStr = GetGadgetText(#AddressText)
  If AddressStr = ""
    MessageRequester("Error", "Please enter an address first!", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  parseError = TryParseAddress(AddressStr, @Address)
  If parseError <> ""
    MessageRequester("Error", parseError, #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  
  *ViewBuffer = AllocateMemory(ViewSize)
  If *ViewBuffer
    If ReadProcessMemory_(ProcessHandle, Address, *ViewBuffer, ViewSize, @ViewBytesRead) And ViewBytesRead > 0
      HexDisplay = "Memory Hex View at " + FormatAddress(Address) + " (" + Str(ViewBytesRead) + " bytes):" + Chr(10) + Chr(10)
      
      For i = 0 To ViewBytesRead - 1
        If i % 16 = 0
          If i > 0
            HexDisplay + "  " + AsciiDisplay + Chr(10)
            AsciiDisplay = ""
          EndIf
          HexDisplay + FormatAddress(Address + i) + ": "
        EndIf
        
        ByteVal = PeekA(*ViewBuffer + i)
        HexDisplay + RSet(Hex(ByteVal & $FF), 2, "0") + " "
        
        ; Build ASCII representation
        If ByteVal >= 32 And ByteVal <= 126
          AsciiDisplay + Chr(ByteVal)
        Else
          AsciiDisplay + "."
        EndIf
        
        If i % 8 = 7 And i % 16 <> 15
          HexDisplay + " "
        EndIf
      Next
      
      ; Add final ASCII column if needed
      If ViewBytesRead % 16 <> 0
        Protected Padding.l = (16 - (ViewBytesRead % 16)) * 3
        If ViewBytesRead % 16 <= 8
          Padding + 1
        EndIf
        HexDisplay + Space(Padding) + "  " + AsciiDisplay
      Else
        HexDisplay + "  " + AsciiDisplay
      EndIf
      
      If IsWindow(#MemoryViewWindow)
        CloseWindow(#MemoryViewWindow)
      EndIf

      If OpenWindow(#MemoryViewWindow, 0, 0, 800, 600, #APP_NAME + " - Address " + FormatAddress(Address), #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
        EditorGadget(#MemoryViewEditor, 10, 10, 780, 580, #PB_Editor_ReadOnly)
        SetGadgetText(#MemoryViewEditor, HexDisplay)
        If MemoryViewFont = 0
          MemoryViewFont = LoadFont(#PB_Any, "Courier New", 10)
        EndIf
        If MemoryViewFont
          SetGadgetFont(#MemoryViewEditor, FontID(MemoryViewFont))
        EndIf
      EndIf
    Else
      MessageRequester("Error", "Failed to read memory at address " + FormatAddress(Address) + Chr(10) + "Error: " + Str(GetLastError_()))
    EndIf
    FreeMemory(*ViewBuffer)
  EndIf
EndProcedure

Procedure.s GetFileDescription(FilePath.s)
  Protected Size.l, *Buffer, *Description
  Protected Description.s = ""
  
  Size = GetFileVersionInfoSize_(FilePath, 0)
  If Size > 0
    *Buffer = AllocateMemory(Size)
    If *Buffer
      If GetFileVersionInfo_(FilePath, 0, Size, *Buffer)
        If VerQueryValue_(*Buffer, "\StringFileInfo\040904B0\FileDescription", @*Description, @Size)
          If *Description
            Description = PeekS(*Description)
          EndIf
        EndIf
      EndIf
      FreeMemory(*Buffer)
    EndIf
  EndIf
  
  ProcedureReturn Description
EndProcedure

; Get file company information
Procedure.s GetFileCompany(FilePath.s)
  Protected Size.l, *Buffer, *Company
  Protected Company.s = ""
  
  Size = GetFileVersionInfoSize_(FilePath, 0)
  If Size > 0
    *Buffer = AllocateMemory(Size)
    If *Buffer
      If GetFileVersionInfo_(FilePath, 0, Size, *Buffer)
        If VerQueryValue_(*Buffer, "\StringFileInfo\040904B0\CompanyName", @*Company, @Size)
          If *Company
            Company = PeekS(*Company)
          EndIf
        EndIf
      EndIf
      FreeMemory(*Buffer)
    EndIf
  EndIf
  
  ProcedureReturn Company
EndProcedure

; Get file version information
Procedure.s GetFileVersion(FilePath.s)
  Protected Size.l, *Buffer, *Version
  Protected Version.s = ""
  
  Size = GetFileVersionInfoSize_(FilePath, 0)
  If Size > 0
    *Buffer = AllocateMemory(Size)
    If *Buffer
      If GetFileVersionInfo_(FilePath, 0, Size, *Buffer)
        If VerQueryValue_(*Buffer, "\StringFileInfo\040904B0\FileVersion", @*Version, @Size)
          If *Version
            Version = PeekS(*Version)
          EndIf
        EndIf
      EndIf
      FreeMemory(*Buffer)
    EndIf
  EndIf
  
  ProcedureReturn Version
EndProcedure

; Get detailed process information (using only available data)
Procedure GetProcessInformation(ProcessID.l, *Info.ProcessInfo)
  Protected *Process.PROCESSENTRY32
  
  *Info\ProcessID = ProcessID
  *Info\ProcessName = ""
  *Info\FullPath = ""
  *Info\Description = ""
  *Info\Company = ""
  *Info\Version = ""
  *Info\MemoryUsage = 0
  *Info\ThreadCount = 0
  
  ; Find the process in our list
  ForEach ProcessList()
    If ProcessList()\th32ProcessID = ProcessID
      *Process = @ProcessList()
      
      ; Extract process name from the szExeFile field
      *Info\ProcessName = ExeNameFromEntry(*Process)
      *Info\FullPath = GetProcessImagePath(ProcessID)
      If *Info\FullPath = ""
        *Info\FullPath = "(Path unavailable - try running as admin)"
      EndIf
      *Info\ThreadCount = *Process\cntThreads
      *Info\ParentProcessID = *Process\th32ParentProcessID
      
      ; Get file information based on full path when possible
      If Left(*Info\FullPath, 1) <> "("
        *Info\Description = GetFileDescription(*Info\FullPath)
        *Info\Company = GetFileCompany(*Info\FullPath)
        *Info\Version = GetFileVersion(*Info\FullPath)
      EndIf
      
      Break
    EndIf
  Next
EndProcedure

; Show detailed process information
Procedure ShowProcessInfo()
  Protected Selection.l, *Process.PROCESSENTRY32, Info.ProcessInfo
  Protected InfoText.s
  
  Selection = GetGadgetState(#ProcessListView)
  If Selection >= 0 And Selection < ProcessCount
    ; Get selected process from list
    SelectElement(ProcessList(), Selection)
    *Process = @ProcessList()
    
    ; Get detailed process information
    GetProcessInformation(*Process\th32ProcessID, @Info)
    
    ; Build information text
    InfoText = "Process Information" + Chr(10)
    InfoText + "===========================================================" + Chr(10)
    InfoText + "Process Name: " + Info\ProcessName + Chr(10)
    InfoText + "Process ID: " + Str(Info\ProcessID) + Chr(10)
    InfoText + "Parent Process ID: " + Str(Info\ParentProcessID) + Chr(10)
    InfoText + "Thread Count: " + Str(Info\ThreadCount) + Chr(10)
    InfoText + Chr(10)
    
    InfoText + "File Information:" + Chr(10)
    InfoText + "===========================================================" + Chr(10)
    InfoText + "Full Path: " + Info\FullPath + Chr(10)
    InfoText + "Description: " + Info\Description + Chr(10)
    InfoText + "Company: " + Info\Company + Chr(10)
    InfoText + Chr(10)
    
    InfoText + "What is this process?" + Chr(10)
    InfoText + "===========================================================" + Chr(10)
    
    ; Add process identification based on common process names
    Protected ProcessNameLower.s = LCase(Info\ProcessName)
    Select ProcessNameLower
      Case "explorer.exe"
        InfoText + "Windows File Explorer - The main Windows shell and desktop environment." + Chr(10)
        InfoText + "This is a critical Windows system process." + Chr(10)
      Case "winlogon.exe"
        InfoText + "Windows Logon Process - Handles user authentication and login." + Chr(10)
        InfoText + "Critical system process - do not terminate." + Chr(10)
      Case "csrss.exe"
        InfoText + "Client Server Runtime Process - Core Windows system process." + Chr(10)
        InfoText + "Manages console windows and creates/deletes threads." + Chr(10)
      Case "smss.exe"
        InfoText + "Session Manager Subsystem - Windows session management." + Chr(10)
        InfoText + "Critical system process that starts user sessions." + Chr(10)
      Case "lsass.exe"
        InfoText + "Local Security Authority Subsystem - Handles Windows security." + Chr(10)
        InfoText + "Manages user logins, password changes, and security policies." + Chr(10)
      Case "svchost.exe"
        InfoText + "Service Host Process - Hosts Windows services." + Chr(10)
        InfoText + "Multiple instances run different Windows services." + Chr(10)
      Case "dwm.exe"
        InfoText + "Desktop Window Manager - Handles Windows visual effects." + Chr(10)
        InfoText + "Manages Aero glass effects and window composition." + Chr(10)
      Case "notepad.exe"
        InfoText + "Windows Notepad - Simple text editor." + Chr(10)
        InfoText + "Safe to analyze - basic text editing application." + Chr(10)
      Case "calc.exe", "calculator.exe"
        InfoText + "Windows Calculator - Built-in calculator application." + Chr(10)
        InfoText + "Safe to analyze - standard Windows utility." + Chr(10)
      Case "taskmgr.exe"
        InfoText + "Windows Task Manager - System monitoring and process management." + Chr(10)
        InfoText + "Shows running processes and system performance." + Chr(10)
      Case "chrome.exe"
        InfoText + "Google Chrome - Web browser." + Chr(10)
        InfoText + "May have multiple processes for tabs and extensions." + Chr(10)
      Case "firefox.exe"
        InfoText + "Mozilla Firefox - Web browser." + Chr(10)
        InfoText + "Safe to analyze - third-party web browser." + Chr(10)
      Case "msedge.exe"
        InfoText + "Microsoft Edge - Web browser." + Chr(10)
        InfoText + "Microsoft's modern web browser." + Chr(10)
      Case "code.exe"
        InfoText + "Visual Studio Code - Code editor and IDE." + Chr(10)
        InfoText + "Popular development environment." + Chr(10)
      Case "steam.exe"
        InfoText + "Steam - Gaming platform and game launcher." + Chr(10)
        InfoText + "Valve's digital game distribution platform." + Chr(10)
      Case "discord.exe"
        InfoText + "Discord - Communication and gaming chat application." + Chr(10)
        InfoText + "Voice and text chat platform for gamers." + Chr(10)
      Case "spotify.exe"
        InfoText + "Spotify - Music streaming application." + Chr(10)
        InfoText + "Digital music streaming service." + Chr(10)
      Case "vlc.exe"
        InfoText + "VLC Media Player - Multimedia player." + Chr(10)
        InfoText + "Open-source media player that plays most formats." + Chr(10)
      Case "winrar.exe"
        InfoText + "WinRAR - File compression and archiving tool." + Chr(10)
        InfoText + "Commercial file archiver and compressor." + Chr(10)
      Case "purebasic.exe"
        InfoText + "PureBasic IDE - Programming environment for PureBasic." + Chr(10)
        InfoText + "The IDE you're currently using!" + Chr(10)
      Default
        If Info\Description <> ""
          InfoText + Info\Description + Chr(10)
        Else
          InfoText + "Unknown process - Check the company and process name for more information." + Chr(10)
        EndIf
        InfoText + "Use caution when analyzing unknown processes." + Chr(10)
    EndSelect
    
    If Info\Company <> "" And Info\Company <> "Unknown"
      InfoText + Chr(10) + "Publisher: " + Info\Company + Chr(10)
    EndIf
    
    InfoText + Chr(10) + "Safety Tips:" + Chr(10)
    InfoText + "===========================================================" + Chr(10)
    InfoText + "System processes (csrss, lsass, winlogon) should NOT be modified" + Chr(10)
    InfoText + "Always verify the process purpose before memory scanning" + Chr(10)
    InfoText + "User applications (games, browsers) are generally safe to analyze" + Chr(10)
    InfoText + "Unknown processes may be malware - investigate carefully" + Chr(10)
    
    ; Show in a dedicated window
    If IsWindow(#ProcessInfoWindow)
      CloseWindow(#ProcessInfoWindow)
    EndIf

    If OpenWindow(#ProcessInfoWindow, 0, 0, 900, 700, "Process Information - " + Info\ProcessName, #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
      EditorGadget(#ProcessInfoText, 10, 10, 880, 680, #PB_Editor_ReadOnly)
      SetGadgetText(#ProcessInfoText, InfoText)
      If ProcessInfoFont = 0
        ProcessInfoFont = LoadFont(#PB_Any, "Consolas", 10)
      EndIf
      If ProcessInfoFont
        SetGadgetFont(#ProcessInfoText, FontID(ProcessInfoFont))
      EndIf
    EndIf
  Else
    MessageRequester("Error", "Please select a process first!", #PB_MessageRequester_Error)
  EndIf
EndProcedure

; Create main window and GUI
OpenWindow(#MainWindow, 0, 0, 1000, 655, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_SizeGadget)

; Process selection section
TextGadget(-1, 10, 10, 100, 20, "Process Filter:")
StringGadget(#ProcessFilterText, 110, 10, 200, 25, "")
ButtonGadget(#RefreshButton, 320, 10, 80, 25, "Refresh")
ButtonGadget(#ButtonAbout, 810, 10, 80, 25, "About")
ButtonGadget(#ButtonExit, 900, 10, 80, 25, "Exit") 

TextGadget(-1, 10, 45, 100, 20, "Running Processes:")
ListViewGadget(#ProcessListView, 10, 65, 400, 200)
ButtonGadget(#AttachButton, 420, 65, 80, 30, "Attach")
ButtonGadget(#ProcessInfoButton, 420, 105, 80, 30, "Process Info")

; Memory scanning section
TextGadget(-1, 10, 280, 150, 20, "Memory Scanner:")
TextGadget(-1, 10, 305, 80, 20, "Value to find:")
StringGadget(#ScanValueText, 90, 300, 120, 25, "100")
TextGadget(-1, 220, 305, 60, 20, "Data type:")
ComboBoxGadget(#ScanTypeCombo, 280, 300, 120, 25)
AddScanTypeItem(#ScanTypeCombo, "Byte (1)", #ValType_Byte)
AddScanTypeItem(#ScanTypeCombo, "Word (2)", #ValType_Word)
AddScanTypeItem(#ScanTypeCombo, "Long (4)", #ValType_Long)
CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
  AddScanTypeItem(#ScanTypeCombo, "Quad (8)", #ValType_Quad)
CompilerEndIf
AddScanTypeItem(#ScanTypeCombo, "Float (4)", #ValType_Float)
AddScanTypeItem(#ScanTypeCombo, "Double (8)", #ValType_Double)
AddScanTypeItem(#ScanTypeCombo, "String (ASCII)", #ValType_String)
AddScanTypeItem(#ScanTypeCombo, "String (Unicode)", #ValType_Unicode)
AddScanTypeItem(#ScanTypeCombo, "AOB (Wildcards ??)", #ValType_AOB)
SetScanTypeSelection(#ValType_Long)


TextGadget(-1, 410, 305, 45, 20, "Mode:")
ComboBoxGadget(#ScanModeCombo, 460, 300, 200, 25)
AddGadgetItem(#ScanModeCombo, -1, "Exact")
AddGadgetItem(#ScanModeCombo, -1, "Unknown (First Scan)")
AddGadgetItem(#ScanModeCombo, -1, "Changed")
AddGadgetItem(#ScanModeCombo, -1, "Unchanged")
AddGadgetItem(#ScanModeCombo, -1, "Increased")
AddGadgetItem(#ScanModeCombo, -1, "Decreased")
SetGadgetState(#ScanModeCombo, 0)

ButtonGadget(#FirstScanButton, 680, 295, 90, 28, "First Scan")
ButtonGadget(#NextScanButton, 780, 295, 90, 28, "Next Scan")
ButtonGadget(#ResetScanButton, 880, 295, 90, 28, "Reset")
ButtonGadget(#PauseScanButton, 880, 330, 90, 25, "Pause")

TextGadget(-1, 460, 335, 90, 20, "Max shown:")
StringGadget(#MaxResultsText, 540, 330, 60, 25, Str(MaxDisplayResults))
ButtonGadget(#ApplyMaxResultsButton, 605, 330, 55, 25, "Apply")
CheckBoxGadget(#AlignedCheck, 680, 330, 70, 25, "Aligned")
SetGadgetState(#AlignedCheck, #PB_Checkbox_Checked)
CheckBoxGadget(#HexCheck, 755, 330, 50, 25, "Hex")
CheckBoxGadget(#SkipReadOnlyCheck, 810, 330, 75, 25, "No R-O")
CheckBoxGadget(#SkipExecCheck, 890, 330, 75, 25, "No Exec")
ButtonGadget(#ModulesButton, 830, 265, 80, 25, "Modules")


ProgressBarGadget(#ScanProgress, 10, 360, 980, 18, 0, 100)

; Results and Cheat List section
TextGadget(-1, 10, 385, 150, 20, "Scan Results:")
ListViewGadget(#ResultsList, 10, 405, 485, 170)
TextGadget(-1, 505, 385, 150, 20, "Saved Addresses (Cheat List):")
ListViewGadget(#CheatListView, 505, 405, 485, 170)

ButtonGadget(#AddCheatButton, 420, 382, 80, 20, "Add ->")
ButtonGadget(#RemoveCheatButton, 910, 382, 80, 20, "Remove")


; Memory editing section (below results)
TextGadget(-1, 10, 585, 100, 20, "Memory Editor:")
TextGadget(-1, 110, 585, 60, 20, "Address:")
StringGadget(#AddressText, 170, 585, 160, 25, "0x")
TextGadget(-1, 340, 585, 70, 20, "New Value:")
StringGadget(#ValueText, 410, 585, 160, 25, "")
ButtonGadget(#WriteButton, 580, 585, 80, 25, "Write")
ButtonGadget(#MemoryViewButton, 670, 585, 110, 25, "View Memory")

; Status bar
CreateStatusBar(#StatusBar, WindowID(#MainWindow))
AddStatusBarField(800)
;StatusBarText(#StatusBar, 0, "Ready - Click Refresh to load processes | Right-click or use 'Process Info' for details | PureBasic " + Str(#PB_Compiler_Version) + " (Compatible with 6.21) | Backend: " + CompilerSelect(#PB_Compiler_Backend, #PB_Backend_C, "C", #PB_Backend_Asm, "ASM", "Unknown"))

; Load initial process list
RefreshProcessList()
AddWindowTimer(#MainWindow, #FreezeTimerID, FreezeInterval)

; Main event loop
Define Event.i
Define Selection.l
Define SelectedResult.ScanResult
Repeat
  Event = WaitWindowEvent()
  
  Select Event
    Case #PB_Event_Timer
      If EventTimer() = #FreezeTimerID
        HandleFreezeTimer()
      EndIf

    Case #PB_Event_CloseWindow
      Select EventWindow()
        Case #MainWindow
          Exit()
        Default
          CloseWindow(EventWindow())
      EndSelect
      
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #ProcessFilterText
          If EventType() = #PB_EventType_Change
            RefreshProcessList()
          EndIf
          
        Case #ProcessInfoButton
          ShowProcessInfo()
          
        Case #ProcessListView
          If EventType() = #PB_EventType_RightClick
            ShowProcessInfo()
          EndIf
          
        Case #RefreshButton
          RefreshProcessList()
          
        Case #AttachButton
          AttachToProcess()
          
        Case #ScanButton
          If EventType() = #PB_EventType_FirstCustomValue
            UpdateResultsUI()
          EndIf
          
        Case #FirstScanButton

          ; First scan: force Exact/Unknown only
          If GetGadgetState(#ScanModeCombo) > #ScanMode_Unknown
            SetGadgetState(#ScanModeCombo, #ScanMode_Exact)
          EndIf
          ScanMemory()

        Case #NextScanButton
          ; Next scan: requires an initialized first scan
          If PreviousScanInitialized = #False
            MessageRequester("Error", "Run a First Scan first.", #PB_MessageRequester_Error)
          Else
            ; "Unknown" is intended for first scan only.
            If GetGadgetState(#ScanModeCombo) = #ScanMode_Unknown
              SetGadgetState(#ScanModeCombo, #ScanMode_Changed)
            EndIf
            ScanMemory()
          EndIf

        Case #ResetScanButton
          ResetScan()

        Case #ApplyMaxResultsButton
          UpdateMaxResults()

        Case #PauseScanButton
          TogglePauseScan()

        Case #ModulesButton
          ShowModuleWindow()

        Case #AddCheatButton
          Selection = GetGadgetState(#ResultsList)
          If Selection >= 0
            If TryGetScanResultByIndex(Selection, @SelectedResult)
              LockMutex(CheatMutex)
              AddElement(CheatList())
              CheatList()\Address = SelectedResult\Address
              CheatList()\ValueBits = SelectedResult\ValueBits
              CheatList()\ValueType = SelectedResult\ValueType
              CheatList()\DisplayValue = SelectedResult\DisplayValue
              CheatList()\Enabled = #True
              CheatList()\Description = "Cheat " + Str(ListSize(CheatList()))
              UnlockMutex(CheatMutex)
            EndIf
            UpdateCheatListUI()
          EndIf

        Case #RemoveCheatButton
          Selection = GetGadgetState(#CheatListView)
          If Selection >= 0
            LockMutex(CheatMutex)
            SelectElement(CheatList(), Selection)
            DeleteElement(CheatList())
            UnlockMutex(CheatMutex)
            UpdateCheatListUI()
          EndIf

        Case #CheatListView
          If EventType() = #PB_EventType_LeftDoubleClick
            Selection = GetGadgetState(#CheatListView)
            If Selection >= 0
              LockMutex(CheatMutex)
              SelectElement(CheatList(), Selection)
              CheatList()\Enabled ! 1 ; Toggle freeze
              UnlockMutex(CheatMutex)
              UpdateCheatListUI()
            EndIf
          EndIf

        Case #ScanProgress

          SetGadgetState(#ScanProgress, EventData())

        Case #WriteButton
          WriteMemoryValue()
          
        Case #MemoryViewButton
          ViewMemoryAtAddress()
          
        Case #ButtonAbout
          MessageRequester("About", #APP_NAME + " - " + version + #CRLF$ +
                                     "David Scouten (" + #EMAIL_NAME + ")" + #CRLF$ +
                                     "----------------------------------------" + #CRLF$ +
                                     "Contact: zonemaster60@gmail.com" + #CRLF$ +
                                     "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
        Case #ButtonExit
          Exit()
                                     
        Case #ResultsList
          If EventType() = #PB_EventType_LeftDoubleClick
              Selection = GetGadgetState(#ResultsList)
              If Selection >= 0
                If TryGetScanResultByIndex(Selection, @SelectedResult)
                  ; Auto-fill address and value fields when double-clicking a result
                  SetGadgetText(#AddressText, FormatAddress(SelectedResult\Address))

                  ; Select the last used value type for this address
                  SetScanTypeSelection(SelectedResult\ValueType)

                  ; Fill value in correct format
                  If IsTextValueType(SelectedResult\ValueType)
                    SetGadgetText(#ValueText, SelectedResult\DisplayValue)
                  Else
                    SetGadgetText(#ValueText, FormatValueFromBits(SelectedResult\ValueBits, SelectedResult\ValueType))
                  EndIf
                EndIf
              EndIf
            EndIf
      EndSelect
  EndSelect
Until AppExitRequested

; Cleanup
CleanupAndQuit()
; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 10
; Folding = ----------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; DllProtection
; UseIcon = HandyMEMScan.ico
; Executable = ..\HandyMEMScan.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,5
; VersionField1 = 1,0,0,5
; VersionField2 = ZoneSoft
; VersionField3 = HandyMEMScan
; VersionField4 = 1.0.0.5
; VersionField5 = 1.0.0.5
; VersionField6 = Memory scanner similar to cheat engine
; VersionField7 = HandyMEMScan
; VersionField8 = HandyMEMScan.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60