; Memory Scanner - PureBasic CheatEngine Alternative
; Compatible with PureBasic 6.30 (Latest Version)
; Educational tool for memory analysis and debugging
; NEW: Added detailed process information viewer with descriptions and company info

EnableExplicit

#APP_NAME   = "HandyMEMScan"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.3"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = #ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  End
EndIf

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure

#FreezeTimerID = 101 ; Timer ID for memory freezing

; Global variables
Global SelectedProcess.l = -1

; Windows API Constants

#PROCESS_ALL_ACCESS = $1F0FFF
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

  Declare.s FormatAddress(Address.i)
  Declare UpdateResultsUI()
  Declare UpdateCheatListUI()
  Declare.q ParseHex(Text.s)
  Declare.i ValueSizeFromType(ValueType.l)
  Declare.s FormatValueFromBits(Bits.q, ValueType.l)

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
    RefreshModuleList()
    If OpenWindow(#ModulesWindow, 0, 0, 800, 400, "Loaded Modules - " + Str(SelectedProcess), #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
      ListViewGadget(#ModulesListGadget, 10, 10, 780, 380)
      ForEach ModuleList()
        AddGadgetItem(#ModulesListGadget, -1, FormatAddress(ModuleList()\BaseAddress) + " - " + ModuleList()\Name + " (" + Str(ModuleList()\Size) + " bytes)")
      Next
      Repeat
        Protected Event = WaitWindowEvent()
      Until Event = #PB_Event_CloseWindow And EventWindow() = #ModulesWindow
      CloseWindow(#ModulesWindow)
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

; PumpScanUI() is defined later (after gadget IDs).

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
  AOBPattern.s ; For string/AOB displays
EndStructure


; Structure for frozen values (Cheat List)
Structure CheatEntry
  Address.i
  ValueBits.q
  ValueType.l
  Description.s
  Enabled.i
EndStructure

; Global variables
Global NewList ProcessList.PROCESSENTRY32()
Global NewList ProcessInfoList.ProcessInfo()
Global NewList ScanResults.ScanResult()
Global NewList CheatList.CheatEntry()
Global NewList MemoryRegions.MemoryRegion()
Global ProcessCount.l
Global ProcessHandle.i
Global PreviousScanInitialized.i
Global ScanSessionValueType.l
Global MaxDisplayResults.i = 5000
Global ScanCancelRequested.i
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
  #FreezeTimerID = 101 ; Timer ID for memory freezing
EndEnumeration

; Function declarations
Declare RefreshProcessList()
Declare AttachToProcess()
Declare ScanMemoryThread(*Params.ScanParams)
Declare ScanMemory()
Declare ResetScan()
Declare TogglePauseScan()
Declare UpdateMaxResults()
Declare.i PumpScanUI()
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

; Helper: Parse hexadecimal string (e.g., "90 90 90" or "0x1234")
Procedure.q ParseHex(Text.s)
  Protected s.s = Trim(Text)
  If Left(s, 2) = "0x" Or Left(s, 2) = "0X"
    s = Mid(s, 3)
  EndIf
  ProcedureReturn Val("$" + ReplaceString(s, " ", ""))
EndProcedure

Procedure UpdateCheatListUI()
  LockMutex(CheatMutex)
  BeginListBatch(#CheatListView)
  ClearGadgetItems(#CheatListView)
  
  ForEach CheatList()
    Protected Status.s = " "
    If CheatList()\Enabled : Status = "[X] " : EndIf
    AddGadgetItem(#CheatListView, -1, Status + FormatAddress(CheatList()\Address) + " = " + FormatValueFromBits(CheatList()\ValueBits, CheatList()\ValueType) + " (" + CheatList()\Description + ")")
  Next
  
  EndListBatch(#CheatListView)
  UnlockMutex(CheatMutex)
EndProcedure

Procedure HandleFreezeTimer()
  Protected BytesWritten.i
  LockMutex(CheatMutex)
  If ProcessHandle
    ForEach CheatList()
      If CheatList()\Enabled
        WriteProcessMemory_(ProcessHandle, CheatList()\Address, @CheatList()\ValueBits, ValueSizeFromType(CheatList()\ValueType), @BytesWritten)
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
      If ScanResults()\ValueType = #ValType_String Or ScanResults()\ValueType = #ValType_Unicode Or ScanResults()\ValueType = #ValType_AOB
        itemText = FormatAddress(ScanResults()\Address) + " = " + ScanResults()\AOBPattern
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
  Protected *buffer = AllocateMemory(bufferSize)
  Protected i.i, stepSize.i = ValueSizeFromType(valueType)
  Protected iterStep.i = 1
  Protected resultCount.i = 0
  
  ; For String/AOB
  Protected searchLen.i = 0
  If valueType = #ValType_String
    searchLen = Len(searchString)
    stepSize = searchLen
  ElseIf valueType = #ValType_Unicode
    searchLen = Len(searchString) * 2
    stepSize = searchLen
  ElseIf valueType = #ValType_AOB
    ; AOB pattern parsing: "8B 45 ?? 50" -> 8B 45 ?? 50
    ; Simplified for this logic: count spaces/2 or just length if compressed
    ; Let's assume patterns like "8B 45 ?? 50" (spaces between hex bytes)
    Protected count.i = CountString(aobPattern, " ") + 1
    If count = 0 : count = Len(aobPattern)/2 : EndIf
    searchLen = count
    stepSize = searchLen
  EndIf

  If aligned And valueType < #ValType_String ; No alignment for strings/AOB by default
    iterStep = ValueSizeFromType(valueType)
  EndIf

  If PreviousScanInitialized = #False
    LockMutex(ScanMutex)
    ClearList(ScanResults())
    UnlockMutex(ScanMutex)
    
    Protected totalRegions.i = ListSize(MemoryRegions())
    Protected regionIndex.i = 0
    
    ForEach MemoryRegions()
      ; Protection filtering
      Protected protect.i = MemoryRegions()\Protection & ~$FF00
      If *Params\SkipReadOnly And protect = #PAGE_READONLY
        Continue
      EndIf
      If *Params\SkipExecutable And (protect = #PAGE_EXECUTE Or protect = #PAGE_EXECUTE_READ Or protect = #PAGE_EXECUTE_READWRITE Or protect = #PAGE_EXECUTE_WRITECOPY)
        Continue
      EndIf

      regionIndex + 1
      PostEvent(#PB_Event_Gadget, #MainWindow, #ScanProgress, #PB_EventType_Change, (regionIndex * 100) / totalRegions)
      
      While ScanCancelRequested
        Delay(50)
      Wend

      Protected base.i = MemoryRegions()\BaseAddress
      Protected endAddr.i = base + MemoryRegions()\Size
      Protected addr.i = base

      While addr < endAddr
        Protected readSize.i = bufferSize
        If addr + readSize > endAddr
          readSize = endAddr - addr
        EndIf

        If ReadProcessMemory_(ProcessHandle, addr, *buffer, readSize, @bytesRead) And bytesRead > 0
          Protected limit.i = bytesRead - stepSize
          If limit >= 0
            i = 0
            While i <= limit
              Protected match.i = #False
              
              If valueType = #ValType_String
                ; Case sensitive string search (ASCII)
                If PeekS(*buffer + i, searchLen, #PB_Ascii) = searchString
                  match = #True
                EndIf
              ElseIf valueType = #ValType_Unicode
                ; Case sensitive string search (Unicode / UTF-16)
                If PeekS(*buffer + i, Len(searchString), #PB_Unicode) = searchString
                  match = #True
                EndIf
              ElseIf valueType = #ValType_AOB
                ; Byte pattern search with wildcards
                match = #True
                Protected p.i
                For p = 0 To searchLen - 1
                  Protected pat.s = StringField(aobPattern, p + 1, " ")
                  If pat <> "??" And pat <> "?"
                    If PeekA(*buffer + i + p) <> Val("$" + pat)
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
                ScanResults()\Address = addr + i
                If valueType < #ValType_String
                  ScanResults()\ValueBits = BitsFromBuffer(*buffer, i, valueType)
                ElseIf valueType = #ValType_String
                  ScanResults()\AOBPattern = PeekS(*buffer + i, searchLen, #PB_Ascii)
                ElseIf valueType = #ValType_Unicode
                  ScanResults()\AOBPattern = PeekS(*buffer + i, Len(searchString), #PB_Unicode)
                Else
                  ; Hex display for AOB
                  Protected h.i, hs.s = ""
                  For h = 0 To searchLen - 1
                    hs + RSet(Hex(PeekA(*buffer + i + h)), 2, "0") + " "
                  Next
                  ScanResults()\AOBPattern = Trim(hs)
                EndIf
                ScanResults()\ValueType = valueType
                UnlockMutex(ScanMutex)
                resultCount + 1
              EndIf
              i + iterStep
            Wend
          EndIf
        EndIf

        If bytesRead <= 0 : Break : EndIf
        addr + bytesRead
      Wend
    Next
    PreviousScanInitialized = #True
    ScanSessionValueType = valueType
  Else
    ; NEXT SCAN (Filter existing results)
    Protected totalHitsNext.i = ListSize(ScanResults())
    Protected hitIndexNext.i = 0

    LockMutex(ScanMutex)
    ResetList(ScanResults())
    While NextElement(ScanResults())
      hitIndexNext + 1
      UnlockMutex(ScanMutex)
      
      PostEvent(#PB_Event_Gadget, #MainWindow, #ScanProgress, #PB_EventType_Change, (hitIndexNext * 100) / totalHitsNext)

      While ScanCancelRequested
        Delay(50)
      Wend
      
      LockMutex(ScanMutex)
      Protected aNext.i = ScanResults()\Address
      UnlockMutex(ScanMutex)

      If ReadProcessMemory_(ProcessHandle, aNext, *buffer, stepSize, @bytesRead) And bytesRead = stepSize
        Protected matchNext.i = #False
        
        If valueType = #ValType_String
          If PeekS(*buffer, searchLen, #PB_Ascii) = searchString
            matchNext = #True
          EndIf
        ElseIf valueType = #ValType_Unicode
          If PeekS(*buffer, Len(searchString), #PB_Unicode) = searchString
            matchNext = #True
          EndIf
        ElseIf valueType = #ValType_AOB
          matchNext = #True
          Protected pNext.i
          For pNext = 0 To searchLen - 1
            Protected patNext.s = StringField(aobPattern, pNext + 1, " ")
            If patNext <> "??" And patNext <> "?"
              If PeekA(*buffer + pNext) <> Val("$" + patNext)
                matchNext = #False
                Break
              EndIf
            EndIf
          Next
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

  PostEvent(#PB_Event_Gadget, #MainWindow, #ScanButton, #PB_EventType_FirstCustomValue) ; Signal completion
EndProcedure

; Scan memory for specific value / next scan
Procedure ScanMemory()
  Protected mode.l = GetGadgetState(#ScanModeCombo)
  Protected typeIndex.i = GetGadgetState(#ScanTypeCombo)
  Protected valueType.l
  
  If IsThread(ScanThread)
    MessageRequester("Info", "Scan is already running!", #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  If Not ProcessHandle
    MessageRequester("Error", "No process attached!", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  Select typeIndex
    Case 0 : valueType = #ValType_Byte
    Case 1 : valueType = #ValType_Word
    Case 2 : valueType = #ValType_Long
    Case 3 : valueType = #ValType_Quad
    Case 4 : valueType = #ValType_Float
    Case 5 : valueType = #ValType_Double
    Case 6 : valueType = #ValType_String
    Case 7 : valueType = #ValType_Unicode
    Case 8 : valueType = #ValType_AOB
    Default : valueType = #ValType_Long
  EndSelect

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

  CurrentScanParams\Mode = mode
  CurrentScanParams\ValueType = valueType
  CurrentScanParams\Aligned = GetGadgetState(#AlignedCheck)
  CurrentScanParams\SkipReadOnly = GetGadgetState(#SkipReadOnlyCheck)
  CurrentScanParams\SkipExecutable = GetGadgetState(#SkipExecCheck)
  
  If mode = #ScanMode_Exact
    Protected searchNumberText.s = Trim(GetGadgetText(#ScanValueText))
    If searchNumberText = ""
      MessageRequester("Error", "Please enter a value for Exact scan.", #PB_MessageRequester_Error)
      ProcedureReturn
    EndIf

    If GetGadgetState(#HexCheck) = #PB_Checkbox_Checked
      CurrentScanParams\SearchInt = ParseHex(searchNumberText)
  ElseIf valueType = #ValType_String Or valueType = #ValType_AOB
    If valueType = #ValType_String
      CurrentScanParams\SearchString = searchNumberText
    Else
      CurrentScanParams\AOBPattern = searchNumberText
    EndIf
  Else

      CurrentScanParams\SearchInt = ParseNumber(searchNumberText)

      ; Range checks
      Select valueType
        Case #ValType_Byte
          If CurrentScanParams\SearchInt < -128 Or CurrentScanParams\SearchInt > 255
            MessageRequester("Error", "Byte range is -128..255", #PB_MessageRequester_Error)
            ProcedureReturn
          EndIf
        Case #ValType_Word
          If CurrentScanParams\SearchInt < -32768 Or CurrentScanParams\SearchInt > 65535
            MessageRequester("Error", "Word range is -32768..65535", #PB_MessageRequester_Error)
            ProcedureReturn
          EndIf
        Case #ValType_Long
          If CurrentScanParams\SearchInt < -2147483648 Or CurrentScanParams\SearchInt > 4294967295
            MessageRequester("Error", "Long range is -2147483648..4294967295", #PB_MessageRequester_Error)
            ProcedureReturn
          EndIf
      EndSelect
    EndIf
  EndIf

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
  
  Selection = GetGadgetState(#ProcessListView)
  If Selection >= 0 And Selection < ProcessCount
    ; Get selected process from list
    SelectElement(ProcessList(), Selection)
    *Process = @ProcessList()
    
    ; Close previous handle if exists
    If ProcessHandle
      CloseHandle_(ProcessHandle)
    EndIf
    
    ; Open process with required access rights
    ProcessHandle = OpenProcess_(#PROCESS_ALL_ACCESS, 0, *Process\th32ProcessID)
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
      Protected isReadOnly.i = Bool(protect = #PAGE_READONLY)
      Protected isExecutable.i = Bool(protect = #PAGE_EXECUTE Or protect = #PAGE_EXECUTE_READ Or protect = #PAGE_EXECUTE_READWRITE Or protect = #PAGE_EXECUTE_WRITECOPY)
      
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
  PreviousScanInitialized = #False
  ScanSessionValueType = 0
  ScanCancelRequested = #False
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
EndProcedure

Procedure TogglePauseScan()
  ScanCancelRequested ! 1
  If ScanCancelRequested
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
  Protected AddressText.s, ValueText.s
  Protected WriteSize.i
  
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
  
  Address = ParseNumber(AddressText)
  Value = ParseNumber(ValueText)
  
  ; Determine write size based on scan type
  Select GetGadgetState(#ScanTypeCombo)
    Case 0: WriteSize = 1
    Case 1: WriteSize = 2
    Case 2: WriteSize = 4
    Case 3: WriteSize = 8
    Case 4: WriteSize = 4
    Case 5: WriteSize = 8
    Default: WriteSize = 4
  EndSelect

  ; NOTE: For Float/Double, use ValueText directly.
  If GetGadgetState(#ScanTypeCombo) = 4
    Protected f.f = ParseDouble(ValueText)
    If WriteProcessMemory_(ProcessHandle, Address, @f, WriteSize, @BytesWritten)
      StatusBarText(#StatusBar, 0, "Successfully wrote value " + StrF(f) + " to address " + FormatAddress(Address))
      ProcedureReturn
    EndIf
  ElseIf GetGadgetState(#ScanTypeCombo) = 5
    Protected d.d = ParseDouble(ValueText)
    If WriteProcessMemory_(ProcessHandle, Address, @d, WriteSize, @BytesWritten)
      StatusBarText(#StatusBar, 0, "Successfully wrote value " + StrD(d) + " to address " + FormatAddress(Address))
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
  
  If Not ProcessHandle
    MessageRequester("Error", "No process attached!", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  
  AddressStr = GetGadgetText(#AddressText)
  If AddressStr = ""
    MessageRequester("Error", "Please enter an address first!", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  
  Address = ParseNumber(AddressStr)
  
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
      
      ; Show in a resizable message window - use OpenWindow for better display
      Protected MemoryWindow = 100
      If OpenWindow(MemoryWindow, 0, 0, 800, 600, #APP_NAME + " - Address 0x" + Hex(Address), #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
        EditorGadget(200, 10, 10, 780, 580, #PB_Editor_ReadOnly)
        SetGadgetText(200, HexDisplay)
        SetGadgetFont(200, LoadFont(#PB_Any, "Courier New", 10))
        
        Repeat
          Protected Event = WaitWindowEvent()
          If Event = #PB_Event_CloseWindow And EventWindow() = MemoryWindow
            Break
          EndIf
        ForEver
        CloseWindow(MemoryWindow)
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
    If OpenWindow(#ProcessInfoWindow, 0, 0, 900, 700, "Process Information - " + Info\ProcessName, #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
      EditorGadget(#ProcessInfoText, 10, 10, 880, 680, #PB_Editor_ReadOnly)
      SetGadgetText(#ProcessInfoText, InfoText)
      SetGadgetFont(#ProcessInfoText, LoadFont(#PB_Any, "Consolas", 10))
      
      Repeat
        Protected Event = WaitWindowEvent()
        If Event = #PB_Event_CloseWindow And EventWindow() = #ProcessInfoWindow
          Break
        EndIf
      ForEver
      CloseWindow(#ProcessInfoWindow)
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
AddGadgetItem(#ScanTypeCombo, -1, "Byte (1)")
AddGadgetItem(#ScanTypeCombo, -1, "Word (2)")
AddGadgetItem(#ScanTypeCombo, -1, "Long (4)")
CompilerIf #PB_Compiler_Processor = #PB_Processor_x64
  AddGadgetItem(#ScanTypeCombo, -1, "Quad (8)")
CompilerEndIf
AddGadgetItem(#ScanTypeCombo, -1, "Float (4)")
AddGadgetItem(#ScanTypeCombo, -1, "Double (8)")
AddGadgetItem(#ScanTypeCombo, -1, "String (ASCII)")
AddGadgetItem(#ScanTypeCombo, -1, "String (Unicode)")
AddGadgetItem(#ScanTypeCombo, -1, "AOB (Wildcards ??)")
SetGadgetState(#ScanTypeCombo, 2) ; Default to Long (4)


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
Repeat
  Event = WaitWindowEvent()
  
  Select Event
    Case #PB_Event_Timer
      If EventTimer() = #FreezeTimerID
        HandleFreezeTimer()
      EndIf

    Case #PB_Event_CloseWindow

      Exit()
      
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

        Case #PauseScanButton
          TogglePauseScan()

        Case #ModulesButton
          ShowModuleWindow()

        Case #AddCheatButton
          Selection = GetGadgetState(#ResultsList)
          If Selection >= 0
            LockMutex(ScanMutex)
            SelectElement(ScanResults(), Selection)
            LockMutex(CheatMutex)
            AddElement(CheatList())
            CheatList()\Address = ScanResults()\Address
            CheatList()\ValueBits = ScanResults()\ValueBits
            CheatList()\ValueType = ScanResults()\ValueType
            CheatList()\Enabled = #True
            CheatList()\Description = "Cheat " + Str(ListSize(CheatList()))
            UnlockMutex(CheatMutex)
            UnlockMutex(ScanMutex)
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
             Selection.l = GetGadgetState(#ResultsList)
             If Selection >= 0 And SelectElement(ScanResults(), Selection)
              ; Auto-fill address and value fields when double-clicking a result
              SetGadgetText(#AddressText, FormatAddress(ScanResults()\Address))

              ; Select the last used value type for this address
              Select ScanResults()\ValueType
                Case #ValType_Byte   : SetGadgetState(#ScanTypeCombo, 0)
                Case #ValType_Word   : SetGadgetState(#ScanTypeCombo, 1)
                Case #ValType_Long   : SetGadgetState(#ScanTypeCombo, 2)
                Case #ValType_Quad   : SetGadgetState(#ScanTypeCombo, 3)
                Case #ValType_Float  : SetGadgetState(#ScanTypeCombo, 4)
                Case #ValType_Double : SetGadgetState(#ScanTypeCombo, 5)
              EndSelect

              ; Fill value in correct format
              SetGadgetText(#ValueText, FormatValueFromBits(ScanResults()\ValueBits, ScanResults()\ValueType))
            EndIf
          EndIf
      EndSelect
  EndSelect
ForEver

; Cleanup
If ProcessHandle
  CloseHandle_(ProcessHandle)
EndIf
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 10
; Folding = -------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyMEMScan.ico
; Executable = ..\HandyMEMScan.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,3
; VersionField1 = 1,0,0,3
; VersionField2 = ZoneSoft
; VersionField3 = HandyMEMScan
; VersionField4 = 1.0.0.3
; VersionField5 = 1.0.0.3
; VersionField6 = Memory scanner similar to cheat engine
; VersionField7 = HandyMEMScan
; VersionField8 = HandyMEMScan.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60