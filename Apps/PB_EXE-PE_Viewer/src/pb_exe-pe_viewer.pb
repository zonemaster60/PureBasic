;===========================================================
; Simple EXE/PE Viewer in PureBasic (Windows)
; - Reads DOS header, PE header, Optional header
; - Displays key fields in a GUI
;===========================================================

EnableExplicit

;-----------------------------------------------------------
; PE / COFF structures (simplified)
;-----------------------------------------------------------

;-----------------------------------------------------------
; PE / COFF structures (missing in some PB versions)
; Use 'My_' prefix to avoid collisions with resident files
;-----------------------------------------------------------

Structure My_IMAGE_IMPORT_DESCRIPTOR
  StructureUnion
    Characteristics.l
    OriginalFirstThunk.l
  EndStructureUnion
  TimeDateStamp.l
  ForwarderChain.l
  Name.l
  FirstThunk.l
EndStructure

Structure My_IMAGE_EXPORT_DIRECTORY
  Characteristics.l
  TimeDateStamp.l
  MajorVersion.w
  MinorVersion.w
  Name.l
  Base.l
  NumberOfFunctions.l
  NumberOfNames.l
  AddressOfFunctions.l
  AddressOfNames.l
  AddressOfNameOrdinals.l
EndStructure

Structure My_IMAGE_RESOURCE_DIRECTORY
  Characteristics.l
  TimeDateStamp.l
  MajorVersion.w
  MinorVersion.w
  NumberOfNamedEntries.w
  NumberOfIdEntries.w
EndStructure

Structure My_IMAGE_RESOURCE_DIRECTORY_ENTRY
  StructureUnion
    Name.l
    Id.w
  EndStructureUnion
  StructureUnion
    OffsetToData.l
    OffsetToDirectory.l
  EndStructureUnion
EndStructure

Structure My_IMAGE_RESOURCE_DATA_ENTRY
  OffsetToData.l
  Size.l
  CodePage.l
  Reserved.l
EndStructure

#APP_NAME   = "PB_EXE-PE_Viewer"
#EMAIL_NAME = "zonemaster60@gmail.com"
Global version.s = "v1.0.0.5"

Global CurrentFile.s
Global NewList LogLines.s()
Global NewList WarningRows.s()
Global AppPath.s        = GetPathPart(ProgramFilename())
Global CurrentView.i = 0
Global NewList Sections.IMAGE_SECTION_HEADER()
Global NewList DataDirs.IMAGE_DATA_DIRECTORY()
Global NewList ImportRows.s()
Global NewList ExportRows.s()
Global NewList ResourceRows.s()
Global *FileBuffer
Global FileBufferSize.q
Global ImageHeadersSize.q
Global CurrentHexOffset.q
Global Gad_Search.i
Global Gad_GoAddr.i
Global Gad_GoBtn.i
Global ImportCacheReady.b
Global ExportCacheReady.b
Global ResourceCacheReady.b
Global ImportStatus.s
Global ExportStatus.s
Global ResourceStatus.s

#MaxDataDirectories   = 16
#MaxSectionHeaders    = 96
#MaxImportDescriptors = 500
#MaxImportEntries     = 4096
#MaxExportEntries     = 16384
#MaxResourceEntries   = 4096

#PE32_DataDirectoryOffset = 96
#PE64_DataDirectoryOffset = 112

SetCurrentDirectory(AppPath)

; Prevent multiple instances
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; Note: Using built-in PureBasic structures for PE headers
; IMAGE_DOS_HEADER, IMAGE_FILE_HEADER, IMAGE_OPTIONAL_HEADER32, IMAGE_OPTIONAL_HEADER64
; are already defined in resident files

;-----------------------------------------------------------
; Utility: map machine / magic constants to text
;-----------------------------------------------------------

Procedure.s MachineToString(machine.w)
  Select machine
    Case $014C : ProcedureReturn "Intel 386 (x86)"
    Case $0200 : ProcedureReturn "Intel Itanium"
    Case $8664 : ProcedureReturn "x64 (AMD64)"
    Default    : ProcedureReturn "Unknown (0x" + RSet(Hex(machine & $FFFF), 4, "0") + ")"
  EndSelect
EndProcedure

Procedure.s OptionalMagicToString(magic.w)
  Select magic
    Case $10B  : ProcedureReturn "PE32 (32-bit)"
    Case $20B  : ProcedureReturn "PE32+ (64-bit)"
    Default    : ProcedureReturn "Unknown (0x" + RSet(Hex(magic & $FFFF), 4, "0") + ")"
  EndSelect
EndProcedure

Procedure.s SubsystemToString(subsystem.w)
  Select subsystem
    Case 1  : ProcedureReturn "Native"
    Case 2  : ProcedureReturn "Windows GUI"
    Case 3  : ProcedureReturn "Windows CUI (Console)"
    Case 5  : ProcedureReturn "OS/2 CUI"
    Case 7  : ProcedureReturn "POSIX CUI"
    Case 9  : ProcedureReturn "Windows CE GUI"
    Case 10 : ProcedureReturn "EFI Application"
    Case 11 : ProcedureReturn "EFI Boot Service Driver"
    Case 12 : ProcedureReturn "EFI Runtime Driver"
    Case 13 : ProcedureReturn "EFI ROM"
    Case 14 : ProcedureReturn "Xbox"
    Case 16 : ProcedureReturn "Windows Boot Application"
    Default : ProcedureReturn "Unknown (" + Str(subsystem) + ")"
  EndSelect
EndProcedure

Procedure.s CharacteristicsToString(chars.w)
  Protected result.s = ""
  
  If chars & $0001 : result + "RELOCS_STRIPPED " : EndIf
  If chars & $0002 : result + "EXECUTABLE " : EndIf
  If chars & $0004 : result + "LINE_NUMS_STRIPPED " : EndIf
  If chars & $0008 : result + "LOCAL_SYMS_STRIPPED " : EndIf
  If chars & $0010 : result + "AGGRESSIVE_WS_TRIM " : EndIf
  If chars & $0020 : result + "LARGE_ADDRESS_AWARE " : EndIf
  If chars & $0080 : result + "BYTES_REVERSED_LO " : EndIf
  If chars & $0100 : result + "32BIT_MACHINE " : EndIf
  If chars & $0200 : result + "DEBUG_STRIPPED " : EndIf
  If chars & $0400 : result + "REMOVABLE_RUN_FROM_SWAP " : EndIf
  If chars & $0800 : result + "NET_RUN_FROM_SWAP " : EndIf
  If chars & $1000 : result + "SYSTEM " : EndIf
  If chars & $2000 : result + "DLL " : EndIf
  If chars & $4000 : result + "UP_SYSTEM_ONLY " : EndIf
  If chars & $8000 : result + "BYTES_REVERSED_HI " : EndIf
  
  If result = ""
    ProcedureReturn "None"
  Else
    ProcedureReturn RTrim(result)
  EndIf
EndProcedure

Procedure.s TimestampToString(timestamp.l)
  Protected value.q = timestamp & $FFFFFFFF

  If value = 0
    ProcedureReturn "N/A"
  EndIf

  ProcedureReturn FormatDate("[%yyyy-%mm-%dd] [%hh:%ii:%ss]", value)
EndProcedure

Procedure.q UnsignedLong(value.l)
  ProcedureReturn value & $FFFFFFFF
EndProcedure

Procedure.s Hex32(value.l)
  ProcedureReturn RSet(Hex(UnsignedLong(value)), 8, "0")
EndProcedure

Procedure.s FormatTimestampValue(timestamp.l)
  Protected value.q = UnsignedLong(timestamp)
  ProcedureReturn TimestampToString(timestamp) + " (" + Str(value) + " / 0x" + Hex32(timestamp) + ")"
EndProcedure

Procedure.s SectionCharacteristicsToString(chars.l)
  Protected result.s = ""
  
  If chars & $00000020 : result + "CODE " : EndIf
  If chars & $00000040 : result + "INITIALIZED_DATA " : EndIf
  If chars & $00000080 : result + "UNINITIALIZED_DATA " : EndIf
  If chars & $02000000 : result + "DISCARDABLE " : EndIf
  If chars & $04000000 : result + "NOT_CACHED " : EndIf
  If chars & $08000000 : result + "NOT_PAGED " : EndIf
  If chars & $10000000 : result + "SHARED " : EndIf
  If chars & $20000000 : result + "EXECUTE " : EndIf
  If chars & $40000000 : result + "READ " : EndIf
  If chars & $80000000 : result + "WRITE " : EndIf
  
  If result = ""
    ProcedureReturn "None"
  Else
    ProcedureReturn RTrim(result)
  EndIf
EndProcedure

Procedure.q MaxQ(a.q, b.q)
  If a > b
    ProcedureReturn a
  EndIf
  ProcedureReturn b
EndProcedure

Procedure.q AlignUpQ(value.q, alignment.q)
  If alignment <= 0
    ProcedureReturn value
  EndIf

  ProcedureReturn ((value + alignment - 1) / alignment) * alignment
EndProcedure

Procedure.s GetSectionName(*section.IMAGE_SECTION_HEADER)
  Protected name.s = ""
  Protected i.i, value.a

  If *section = 0
    ProcedureReturn ""
  EndIf

  For i = 0 To 7
    value = PeekA(*section + i)
    If value = 0
      Break
    EndIf
    name + Chr(value)
  Next

  ProcedureReturn name
EndProcedure

Procedure.b IsFileRangeValid(offset.q, size.q)
  If *FileBuffer = 0 Or FileBufferSize <= 0
    ProcedureReturn #False
  EndIf

  If offset < 0 Or size < 0
    ProcedureReturn #False
  EndIf

  If offset > FileBufferSize
    ProcedureReturn #False
  EndIf

  If size > FileBufferSize - offset
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.b IsDiskRangeValid(fileSize.q, offset.q, size.q)
  If fileSize <= 0 Or offset < 0 Or size < 0
    ProcedureReturn #False
  EndIf

  If offset > fileSize
    ProcedureReturn #False
  EndIf

  If size > fileSize - offset
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.b ReadExact(fileID.i, *buffer, size.q)
  If size < 0
    ProcedureReturn #False
  EndIf

  If size = 0
    ProcedureReturn #True
  EndIf

  If ReadData(fileID, *buffer, size) <> size
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.s PeekAsciiZ(offset.q)
  Protected length.q = 0

  If Not IsFileRangeValid(offset, 1)
    ProcedureReturn ""
  EndIf

  While offset + length < FileBufferSize
    If PeekA(*FileBuffer + offset + length) = 0
      Break
    EndIf
    length + 1
  Wend

  ProcedureReturn PeekS(*FileBuffer + offset, length, #PB_Ascii)
EndProcedure

Procedure.q ReadThunkValue(*thunk, is64.b)
  If is64
    ProcedureReturn PeekQ(*thunk)
  EndIf

  ProcedureReturn PeekL(*thunk) & $FFFFFFFF
EndProcedure

Procedure.i GetThunkEntrySize(is64.b)
  If is64
    ProcedureReturn 8
  EndIf

  ProcedureReturn 4
EndProcedure

Procedure.s EscapeJson(value.s)
  value = ReplaceString(value, Chr(92), Chr(92) + Chr(92))
  value = ReplaceString(value, #DQUOTE$, Chr(92) + #DQUOTE$)
  value = ReplaceString(value, #CRLF$, "\\r\\n")
  value = ReplaceString(value, Chr(13), "\\r")
  value = ReplaceString(value, Chr(10), "\\n")
  value = ReplaceString(value, Chr(9), "\\t")
  ProcedureReturn value
EndProcedure

Procedure.s NormalizeHexAddress(value.s)
  value = RemoveString(Trim(value), " ")

  If Left(LCase(value), 2) = "0x"
    value = Mid(value, 3)
  EndIf

  If Left(value, 1) = "$"
    value = Mid(value, 2)
  EndIf

  ProcedureReturn value
EndProcedure

Procedure.b IsHexAddress(value.s)
  Protected i.i, charCode.i

  value = NormalizeHexAddress(value)
  If value = ""
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(value)
    charCode = Asc(Mid(value, i, 1))
    Select charCode
      Case '0' To '9', 'A' To 'F', 'a' To 'f'
      Default
        ProcedureReturn #False
    EndSelect
  Next

  ProcedureReturn #True
EndProcedure

Procedure.s EscapeCsv(value.s)
  value = ReplaceString(value, #DQUOTE$, #DQUOTE$ + #DQUOTE$)
  ProcedureReturn #DQUOTE$ + value + #DQUOTE$
EndProcedure

Procedure LoadDataDirectoriesFromHeader(*optionalHeader, optionalMagic.w, headerSize.i, numDataDirs.i)
  Protected *dataDir.IMAGE_DATA_DIRECTORY
  Protected dataDirOffset.i
  Protected i.i

  If *optionalHeader = 0
    ProcedureReturn
  EndIf

  Select optionalMagic
    Case $10B
      dataDirOffset = #PE32_DataDirectoryOffset
    Case $20B
      dataDirOffset = #PE64_DataDirectoryOffset
    Default
      ProcedureReturn
  EndSelect

  If numDataDirs > #MaxDataDirectories
    numDataDirs = #MaxDataDirectories
  EndIf

  If numDataDirs <= 0
    ProcedureReturn
  EndIf

  If headerSize < dataDirOffset + (numDataDirs * SizeOf(IMAGE_DATA_DIRECTORY))
    ProcedureReturn
  EndIf

  *dataDir = *optionalHeader + dataDirOffset

  For i = 0 To numDataDirs - 1
    AddElement(DataDirs())
    CopyMemory(*dataDir + (i * SizeOf(IMAGE_DATA_DIRECTORY)), @DataDirs(), SizeOf(IMAGE_DATA_DIRECTORY))
  Next
EndProcedure

;-----------------------------------------------------------
; GUI globals
;-----------------------------------------------------------

#Win_Main       = 0
#Gad_Browse     = 1
#Gad_File       = 2
#Gad_List       = 3
#Gad_SaveLog    = 4
#Gad_About      = 5
#Gad_Exit       = 6
#Gad_Tabs       = 7
#Gad_Export     = 13
#StatusBar_Main = 0

#View_Headers    = 0
#View_Sections   = 1
#View_DataDirs   = 2
#View_Imports    = 3
#View_Exports    = 4
#View_Resources  = 5
#View_Hex        = 6

Procedure BeginListUpdate()
  SendMessage_(GadgetID(#Gad_List), #WM_SETREDRAW, #False, 0)
EndProcedure

Procedure EndListUpdate()
  SendMessage_(GadgetID(#Gad_List), #WM_SETREDRAW, #True, 0)
  UpdateWindow_(GadgetID(#Gad_List))
EndProcedure

;-----------------------------------------------------------
; Entropy calculation (Shannon Entropy)
;-----------------------------------------------------------

Procedure.f CalculateEntropy(*ptr, size.q)
  If size <= 0 Or *ptr = 0 : ProcedureReturn 0 : EndIf
  
  Protected Dim counts.q(255)
  Protected i.q, byte.i
  Protected entropy.f = 0
  Protected p.f
  
  For i = 0 To size - 1
    byte = PeekA(*ptr + i) & $FF
    counts(byte) + 1
  Next
  
  For i = 0 To 255
    If counts(i) > 0
      p = counts(i) / size
      entropy - (p * Log(p) / Log(2))
    EndIf
  Next
  
  ProcedureReturn entropy
EndProcedure

;-----------------------------------------------------------
; RVA to File Offset
;-----------------------------------------------------------

Procedure.q RvaToOffset(rva.l)
  Protected span.q

  If rva >= 0 And rva < ImageHeadersSize
    ProcedureReturn rva
  EndIf

  ForEach Sections()
    span = MaxQ(Sections()\VirtualSize, Sections()\SizeOfRawData)
    If span > 0 And rva >= Sections()\VirtualAddress And rva < Sections()\VirtualAddress + span
      ProcedureReturn Sections()\PointerToRawData + (rva - Sections()\VirtualAddress)
    EndIf
  Next
  ProcedureReturn -1
EndProcedure

;-----------------------------------------------------------
; Directory mapping
;-----------------------------------------------------------

Procedure.s DirectoryIndexToName(index.i)
  Select index
    Case 0 : ProcedureReturn "Export Table"
    Case 1 : ProcedureReturn "Import Table"
    Case 2 : ProcedureReturn "Resource Table"
    Case 3 : ProcedureReturn "Exception Table"
    Case 4 : ProcedureReturn "Certificate Table"
    Case 5 : ProcedureReturn "Base Relocation Table"
    Case 6 : ProcedureReturn "Debug Directory"
    Case 7 : ProcedureReturn "Architecture Specific Data"
    Case 8 : ProcedureReturn "Global Pointer Register"
    Case 9 : ProcedureReturn "TLS Table"
    Case 10: ProcedureReturn "Load Config Directory"
    Case 11: ProcedureReturn "Bound Import Table"
    Case 12: ProcedureReturn "Import Address Table (IAT)"
    Case 13: ProcedureReturn "Delay Import Descriptor"
    Case 14: ProcedureReturn "CLR Runtime Header"
    Default: ProcedureReturn "Reserved"
  EndSelect
EndProcedure

;-----------------------------------------------------------
; Helper: set status bar text
;-----------------------------------------------------------

Procedure SetStatus(msg.s)
  StatusBarText(#StatusBar_Main, 0, msg)
EndProcedure

Procedure ShowListMessage(title.s, detail.s)
  BeginListUpdate()
  ClearGadgetItems(#Gad_List)
  AddGadgetItem(#Gad_List, -1, title + Chr(10) + detail)
  EndListUpdate()
EndProcedure

Procedure AddCachedRow(List rows.s(), title.s, detail.s)
  AddElement(rows())
  rows() = title + Chr(10) + detail
EndProcedure

Procedure RenderCachedRows(List rows.s())
  BeginListUpdate()
  ClearGadgetItems(#Gad_List)
  ForEach rows()
    AddGadgetItem(#Gad_List, -1, rows())
  Next
  EndListUpdate()
EndProcedure

Procedure InvalidateDerivedCaches()
  ClearList(ImportRows())
  ClearList(ExportRows())
  ClearList(ResourceRows())
  ImportCacheReady = #False
  ExportCacheReady = #False
  ResourceCacheReady = #False
  ImportStatus = ""
  ExportStatus = ""
  ResourceStatus = ""
EndProcedure

;-----------------------------------------------------------
; Core: parse PE file and populate list
;-----------------------------------------------------------

Procedure ClearInfo()
  ClearGadgetItems(#Gad_List)
  ClearList(LogLines())
  ClearList(WarningRows())
  ClearList(Sections())
  ClearList(DataDirs())
  InvalidateDerivedCaches()
  If *FileBuffer
    FreeMemory(*FileBuffer)
    *FileBuffer = 0
  EndIf
  FileBufferSize = 0
  ImageHeadersSize = 0
  CurrentHexOffset = 0
EndProcedure

Global is64Bit.b = #False

Procedure AddInfo(key.s, value.s)
  AddElement(LogLines())
  LogLines() = key + " " + value
EndProcedure

Procedure AddWarning(message.s)
  AddElement(WarningRows())
  WarningRows() = message
EndProcedure

Procedure AppendWarningsToLog()
  If ListSize(WarningRows()) = 0
    AddInfo("Warnings:", "None detected")
    ProcedureReturn
  EndIf

  AddInfo("Warnings:", Str(ListSize(WarningRows())) + " issue(s) flagged")
  ForEach WarningRows()
    AddInfo("Warning:", WarningRows())
  Next
EndProcedure

Procedure AnalyzePEWarnings(fileSize.q, entryPointRVA.q, fileAlignment.q, sectionAlignment.q, sizeOfHeaders.q, sizeOfImage.q, importRVA.q, importSize.q, sectionHeadersOffset.q, sectionHeadersSize.q)
  Protected firstSectionRaw.q = -1
  Protected previousRawStart.q = -1
  Protected previousRawEnd.q = -1
  Protected previousRvaStart.q = -1
  Protected previousRvaEnd.q = -1
  Protected expectedImageEnd.q = sizeOfHeaders
  Protected epSectionName.s = ""
  Protected foundEntryPoint.b = #False
  Protected entryPointExecutable.b = #False
  Protected i.i = 0

  ClearList(WarningRows())

  If fileAlignment <= 0
    AddWarning("FileAlignment is zero or invalid")
  EndIf

  If sectionAlignment <= 0
    AddWarning("SectionAlignment is zero or invalid")
  EndIf

  If fileAlignment > 0 And sectionAlignment > 0 And sectionAlignment < fileAlignment
    AddWarning("SectionAlignment is smaller than FileAlignment")
  EndIf

  If sizeOfHeaders > 0 And sizeOfHeaders > fileSize
    AddWarning("SizeOfHeaders extends beyond the end of file")
  EndIf

  If sectionHeadersSize > 0 And sizeOfHeaders > 0 And sectionHeadersOffset + sectionHeadersSize > sizeOfHeaders
    AddWarning("Section header table extends beyond SizeOfHeaders")
  EndIf

  ForEach Sections()
    Protected sectionName.s = GetSectionName(@Sections())
    Protected rawStart.q = UnsignedLong(Sections()\PointerToRawData)
    Protected rawSize.q = UnsignedLong(Sections()\SizeOfRawData)
    Protected rvaStart.q = UnsignedLong(Sections()\VirtualAddress)
    Protected virtualSize.q = UnsignedLong(Sections()\VirtualSize)
    Protected rvaSpan.q = MaxQ(virtualSize, rawSize)

    If sectionName = ""
      sectionName = "<unnamed>"
    EndIf

    If rawSize > 0
      If firstSectionRaw = -1 Or rawStart < firstSectionRaw
        firstSectionRaw = rawStart
      EndIf

      If Not IsDiskRangeValid(fileSize, rawStart, rawSize)
        AddWarning("Section " + sectionName + " raw data extends beyond file bounds")
      EndIf

      If previousRawStart <> -1 And rawStart < previousRawStart
        AddWarning("Section " + sectionName + " raw data begins before the previous section")
      EndIf

      If previousRawEnd <> -1 And rawStart < previousRawEnd
        AddWarning("Section " + sectionName + " raw data overlaps a previous section")
      EndIf

      previousRawStart = rawStart
      previousRawEnd = rawStart + rawSize

      If fileAlignment > 0 And rawStart > 0 And (rawStart % fileAlignment) <> 0
        AddWarning("Section " + sectionName + " raw pointer is not aligned to FileAlignment")
      EndIf
    EndIf

    If rvaSpan > 0
      If previousRvaStart <> -1 And rvaStart < previousRvaStart
        AddWarning("Section " + sectionName + " RVA begins before the previous section")
      EndIf

      If previousRvaEnd <> -1 And rvaStart < previousRvaEnd
        AddWarning("Section " + sectionName + " RVA range overlaps a previous section")
      EndIf

      previousRvaStart = rvaStart
      previousRvaEnd = rvaStart + rvaSpan
      expectedImageEnd = MaxQ(expectedImageEnd, AlignUpQ(rvaStart + rvaSpan, sectionAlignment))

      If sectionAlignment > 0 And (rvaStart % sectionAlignment) <> 0
        AddWarning("Section " + sectionName + " RVA is not aligned to SectionAlignment")
      EndIf

      If entryPointRVA > 0 And entryPointRVA >= rvaStart And entryPointRVA < rvaStart + rvaSpan
        foundEntryPoint = #True
        epSectionName = sectionName
        If Sections()\Characteristics & $20000000
          entryPointExecutable = #True
        EndIf
      EndIf
    EndIf

    If (Sections()\Characteristics & $20000000) And (Sections()\Characteristics & $80000000)
      AddWarning("Section " + sectionName + " is both executable and writable")
    EndIf

    If *FileBuffer And rawSize >= 256 And rawStart > 0 And IsDiskRangeValid(fileSize, rawStart, rawSize)
      Protected entropy.f = CalculateEntropy(*FileBuffer + rawStart, rawSize)
      If entropy >= 7.2 And (Sections()\Characteristics & $20000000)
        AddWarning("Section " + sectionName + " is executable and has very high entropy (" + StrF(entropy, 2) + ")")
      EndIf
    EndIf

    i + 1
  Next

  If firstSectionRaw <> -1 And sizeOfHeaders > 0 And sizeOfHeaders > firstSectionRaw
    AddWarning("SizeOfHeaders overlaps the first section raw data")
  EndIf

  If sizeOfImage > 0 And sectionAlignment > 0 And sizeOfImage <> AlignUpQ(sizeOfImage, sectionAlignment)
    AddWarning("SizeOfImage is not aligned to SectionAlignment")
  EndIf

  If sizeOfImage > 0 And expectedImageEnd > sizeOfImage
    AddWarning("SizeOfImage is smaller than the section layout requires")
  EndIf

  If entryPointRVA > 0
    If RvaToOffset(entryPointRVA) = -1
      AddWarning("Entry point RVA 0x" + Hex(entryPointRVA) + " does not map to file data")
    ElseIf Not foundEntryPoint
      AddWarning("Entry point RVA 0x" + Hex(entryPointRVA) + " is outside all sections")
    ElseIf Not entryPointExecutable
      AddWarning("Entry point lies in non-executable section " + epSectionName)
    EndIf
  EndIf

  i = 0
  ForEach DataDirs()
    If DataDirs()\VirtualAddress > 0 And RvaToOffset(DataDirs()\VirtualAddress) = -1
      AddWarning("Data directory " + DirectoryIndexToName(i) + " does not map to file data")
    EndIf
    i + 1
  Next

  If entryPointRVA > 0 And importRVA = 0 And importSize = 0
    AddWarning("No import table is present; packed or statically linked image is possible")
  EndIf

  AppendWarningsToLog()
EndProcedure

Procedure ShowHeaders()
  BeginListUpdate()
  ClearGadgetItems(#Gad_List)
  ForEach LogLines()
    Protected line.s = LogLines()
    Protected pos = FindString(line, " ")
    If pos
      AddGadgetItem(#Gad_List, -1, Left(line, pos-1) + Chr(10) + Mid(line, pos+1))
    EndIf
  Next
  EndListUpdate()
EndProcedure

Procedure ShowDataDirs()
  BeginListUpdate()
  ClearGadgetItems(#Gad_List)
  Protected i = 0
  ForEach DataDirs()
    Protected name.s = DirectoryIndexToName(i)
    Protected dirRva.q = UnsignedLong(DataDirs()\VirtualAddress)
    Protected dirSize.q = UnsignedLong(DataDirs()\Size)
    Protected info.s = "RVA: 0x" + Hex32(DataDirs()\VirtualAddress) + " | Size: " + Str(dirSize)
    
    If dirRva > 0
      Protected offset.q = RvaToOffset(dirRva)
      If offset <> -1
        info + " (File Offset: 0x" + Hex(offset) + ")"
      Else
        info + " (Offset: N/A - Outside Sections)"
      EndIf
    EndIf
    
    AddGadgetItem(#Gad_List, -1, name + Chr(10) + info)
    i + 1
  Next
  EndListUpdate()
  SetStatus("Showing " + Str(ListSize(DataDirs())) + " data directories")
EndProcedure

Procedure ExportData()
  If CurrentFile = "" : SetStatus("No file loaded.") : ProcedureReturn : EndIf
  
  Protected outFile.s = SaveFileRequester("Export Data", CurrentFile + "_export.json", "JSON (*.json)|*.json|CSV (*.csv)|*.csv|All Files (*.*)|*.*", 0)
  If outFile = "" : ProcedureReturn : EndIf
  
  Protected fileID = CreateFile(#PB_Any, outFile)
  If fileID = 0 : SetStatus("Failed to create file!") : ProcedureReturn : EndIf
  
  Protected ext.s = LCase(GetExtensionPart(outFile))
  Protected headerLine.s, csvLine.s, name.s
  Protected pos.i, i.i
  Protected isFirstJsonHeader.b = #True
  Protected isFirstJsonWarning.b = #True
  Protected isFirstJsonDir.b = #True
  Protected isFirstJsonSection.b = #True
  
  If ext = "json"
    WriteStringN(fileID, "{")
    WriteStringN(fileID, "  " + #DQUOTE$ + "filename" + #DQUOTE$ + ": " + #DQUOTE$ + EscapeJson(CurrentFile) + #DQUOTE$ + ",")
    WriteStringN(fileID, "  " + #DQUOTE$ + "headers" + #DQUOTE$ + ": [")
    ForEach LogLines()
      headerLine = LogLines()
      pos = FindString(headerLine, " ")
      If pos
        If Not isFirstJsonHeader
          WriteStringN(fileID, ",")
        EndIf
        WriteString(fileID, "    {" + #DQUOTE$ + "key" + #DQUOTE$ + ": " + #DQUOTE$ + EscapeJson(Left(headerLine, pos-1)) + #DQUOTE$ + ", " + #DQUOTE$ + "value" + #DQUOTE$ + ": " + #DQUOTE$ + EscapeJson(Mid(headerLine, pos+1)) + #DQUOTE$ + "}")
        isFirstJsonHeader = #False
      EndIf
    Next
    If Not isFirstJsonHeader
      WriteStringN(fileID, "")
    EndIf
    WriteStringN(fileID, "  ],")

    WriteStringN(fileID, "  " + #DQUOTE$ + "warnings" + #DQUOTE$ + ": [")
    ForEach WarningRows()
      If Not isFirstJsonWarning
        WriteStringN(fileID, ",")
      EndIf
      WriteString(fileID, "    " + #DQUOTE$ + EscapeJson(WarningRows()) + #DQUOTE$)
      isFirstJsonWarning = #False
    Next
    If Not isFirstJsonWarning
      WriteStringN(fileID, "")
    EndIf
    WriteStringN(fileID, "  ],")

    WriteStringN(fileID, "  " + #DQUOTE$ + "data_directories" + #DQUOTE$ + ": [")
    i = 0
    ForEach DataDirs()
      If Not isFirstJsonDir
        WriteStringN(fileID, ",")
      EndIf
      WriteString(fileID, "    {" + #DQUOTE$ + "index" + #DQUOTE$ + ": " + Str(i) + ", " + #DQUOTE$ + "name" + #DQUOTE$ + ": " + #DQUOTE$ + EscapeJson(DirectoryIndexToName(i)) + #DQUOTE$ + ", " + #DQUOTE$ + "rva" + #DQUOTE$ + ": " + #DQUOTE$ + "0x" + Hex32(DataDirs()\VirtualAddress) + #DQUOTE$ + ", " + #DQUOTE$ + "size" + #DQUOTE$ + ": " + Str(UnsignedLong(DataDirs()\Size)) + "}")
      isFirstJsonDir = #False
      i + 1
    Next
    If Not isFirstJsonDir
      WriteStringN(fileID, "")
    EndIf
    WriteStringN(fileID, "  ],")
    
    WriteStringN(fileID, "  " + #DQUOTE$ + "sections" + #DQUOTE$ + ": [")
    ForEach Sections()
      name = GetSectionName(@Sections())
      If Not isFirstJsonSection
        WriteStringN(fileID, ",")
      EndIf
      WriteString(fileID, "    {" + #DQUOTE$ + "name" + #DQUOTE$ + ": " + #DQUOTE$ + EscapeJson(name) + #DQUOTE$ + ", " + #DQUOTE$ + "virtual_address" + #DQUOTE$ + ": " + #DQUOTE$ + "0x" + Hex32(Sections()\VirtualAddress) + #DQUOTE$ + ", " + #DQUOTE$ + "virtual_size" + #DQUOTE$ + ": " + Str(UnsignedLong(Sections()\VirtualSize)) + ", " + #DQUOTE$ + "raw_size" + #DQUOTE$ + ": " + Str(UnsignedLong(Sections()\SizeOfRawData)) + ", " + #DQUOTE$ + "raw_ptr" + #DQUOTE$ + ": " + #DQUOTE$ + "0x" + Hex32(Sections()\PointerToRawData) + #DQUOTE$ + "}")
      isFirstJsonSection = #False
    Next
    If Not isFirstJsonSection
      WriteStringN(fileID, "")
    EndIf
    WriteStringN(fileID, "  ]")
    WriteStringN(fileID, "}")
  Else ; CSV
    WriteStringN(fileID, "Category,Key,Value")
    ForEach LogLines()
      csvLine = LogLines()
      pos = FindString(csvLine, " ")
      If pos
        WriteStringN(fileID, EscapeCsv("Header") + "," + EscapeCsv(Left(csvLine, pos-1)) + "," + EscapeCsv(Mid(csvLine, pos+1)))
      EndIf
    Next

    ForEach WarningRows()
      WriteStringN(fileID, EscapeCsv("Warning") + "," + EscapeCsv("Message") + "," + EscapeCsv(WarningRows()))
    Next

    i = 0
    ForEach DataDirs()
      WriteStringN(fileID, EscapeCsv("DataDirectory") + "," + EscapeCsv(DirectoryIndexToName(i)) + "," + EscapeCsv("RVA=0x" + Hex32(DataDirs()\VirtualAddress) + " Size=" + Str(UnsignedLong(DataDirs()\Size))))
      i + 1
    Next

    ForEach Sections()
      name = GetSectionName(@Sections())
      WriteStringN(fileID, EscapeCsv("Section") + "," + EscapeCsv(name) + "," + EscapeCsv("VA=0x" + Hex32(Sections()\VirtualAddress) + " VS=" + Str(UnsignedLong(Sections()\VirtualSize)) + " RS=" + Str(UnsignedLong(Sections()\SizeOfRawData)) + " RP=0x" + Hex32(Sections()\PointerToRawData)))
    Next
  EndIf
  
  CloseFile(fileID)
  SetStatus("Exported to: " + outFile)
EndProcedure

Procedure.b ParsePEFile(file.s)
  Protected fileID, fileSize.q
  Protected dosHeader.IMAGE_DOS_HEADER
  Protected peSignature.l
  Protected fileHeader.IMAGE_FILE_HEADER
  Protected optionalMagic.w
  Protected opt32.IMAGE_OPTIONAL_HEADER32
  Protected opt64.IMAGE_OPTIONAL_HEADER64
  Protected numDataDirs.l
  Protected offset.q, sectionHeadersOffset.q, sectionHeadersSize.q
  Protected entryPointRVA.q = 0
  Protected fileAlignment.q = 0
  Protected sectionAlignment.q = 0
  Protected sizeOfHeaders.q = 0
  Protected sizeOfImage.q = 0
  Protected importRVA.q = 0
  Protected importSize.q = 0
  Protected i
  
  ClearInfo()
  SetStatus("Opening file...")

  fileID = ReadFile(#PB_Any, file)
  If fileID = 0
    SetStatus("Failed to open file!")
    ProcedureReturn #False
  EndIf
  
  fileSize = Lof(fileID)
  If fileSize < SizeOf(IMAGE_DOS_HEADER)
    CloseFile(fileID)
    SetStatus("File too small to be a valid PE!")
    ProcedureReturn #False
  EndIf
  
  ;--- Read DOS header
  If Not ReadExact(fileID, @dosHeader, SizeOf(IMAGE_DOS_HEADER))
    CloseFile(fileID)
    SetStatus("Failed to read DOS header!")
    ProcedureReturn #False
  EndIf
  
  If dosHeader\e_magic <> $5A4D ; "MZ"
    CloseFile(fileID)
    SetStatus("Not a valid MZ (DOS) header!")
    ProcedureReturn #False
  EndIf
  
  AddInfo("DOS_e_magic:", "MZ (0x" + RSet(Hex(dosHeader\e_magic & $FFFF), 4, "0") + ")")
  AddInfo("DOS_e_lfanew:", "0x" + Hex32(dosHeader\e_lfanew))
  
  ; Check PE header offset
  If dosHeader\e_lfanew <= 0 Or Not IsDiskRangeValid(fileSize, dosHeader\e_lfanew, 4 + SizeOf(IMAGE_FILE_HEADER) + 2)
    CloseFile(fileID)
    SetStatus("Invalid e_lfanew, PE header out of range!")
    ProcedureReturn #False
  EndIf
  
    ;--- Seek to PE signature
  FileSeek(fileID, dosHeader\e_lfanew)
  If Not ReadExact(fileID, @peSignature, SizeOf(Long))
    CloseFile(fileID)
    SetStatus("Failed to read PE signature!")
    ProcedureReturn #False
  EndIf
  If peSignature <> $00004550 ; "PE\0\0"
    CloseFile(fileID)
    SetStatus("No valid PE signature found!")
    ProcedureReturn #False
  EndIf
  
  AddInfo("PE_Signature:", "PE (0x" + Hex32(peSignature) + ")")
  
  ;--- Read file (COFF) header
  If Not ReadExact(fileID, @fileHeader, SizeOf(IMAGE_FILE_HEADER))
    CloseFile(fileID)
    SetStatus("Failed to read PE file header!")
    ProcedureReturn #False
  EndIf
  
  AddInfo("Machine:", MachineToString(fileHeader\Machine))
  AddInfo("NumberOfSections:", Str(fileHeader\NumberOfSections))
  AddInfo("TimeDateStamp:", FormatTimestampValue(fileHeader\TimeDateStamp))
  AddInfo("SizeOfOptionalHeader:", Str(fileHeader\SizeOfOptionalHeader))
  AddInfo("Characteristics:", CharacteristicsToString(fileHeader\Characteristics) + " (0x" + RSet(Hex(fileHeader\Characteristics & $FFFF), 4, "0") + ")")

  If fileHeader\NumberOfSections = 0 Or fileHeader\NumberOfSections > #MaxSectionHeaders
    CloseFile(fileID)
    SetStatus("Unsupported or invalid section count!")
    ProcedureReturn #False
  EndIf
  
  ;--- Read Optional Header magic
  If fileHeader\SizeOfOptionalHeader > 0 And Not IsDiskRangeValid(fileSize, Loc(fileID), fileHeader\SizeOfOptionalHeader)
    CloseFile(fileID)
    SetStatus("Optional header is out of range!")
    ProcedureReturn #False
  EndIf

  If Not ReadExact(fileID, @optionalMagic, SizeOf(Word))
    CloseFile(fileID)
    SetStatus("Failed to read optional header magic!")
    ProcedureReturn #False
  EndIf
  AddInfo("OptionalHeader_Magic:", OptionalMagicToString(optionalMagic))
  
  ;--- Seek back 2 bytes so we can read full optional header struct
  offset = Loc(fileID) - 2
  FileSeek(fileID, offset)
  
  Select optionalMagic
    Case $10B  ; PE32
      is64Bit = #False
      If fileHeader\SizeOfOptionalHeader < SizeOf(IMAGE_OPTIONAL_HEADER32)
        CloseFile(fileID)
        SetStatus("Optional header smaller than expected for PE32!")
        ProcedureReturn #False
      Else
        If Not ReadExact(fileID, @opt32, SizeOf(IMAGE_OPTIONAL_HEADER32))
          CloseFile(fileID)
          SetStatus("Failed to read PE32 optional header!")
          ProcedureReturn #False
        EndIf
        AddInfo("AddressOfEntryPoint:", "0x" + Hex32(opt32\AddressOfEntryPoint))
        AddInfo("ImageBase:", "0x" + Hex(opt32\ImageBase))
        AddInfo("SectionAlignment:", Str(UnsignedLong(opt32\SectionAlignment)))
        AddInfo("FileAlignment:", Str(UnsignedLong(opt32\FileAlignment)))
        AddInfo("SizeOfImage:", Str(UnsignedLong(opt32\SizeOfImage)))
        AddInfo("SizeOfHeaders:", Str(UnsignedLong(opt32\SizeOfHeaders)))
        AddInfo("Subsystem:", SubsystemToString(opt32\Subsystem) + " (0x" + RSet(Hex(opt32\Subsystem & $FFFF), 4, "0") + ")")
        AddInfo("NumberOfRvaAndSizes:", Str(UnsignedLong(opt32\NumberOfRvaAndSizes)))
        entryPointRVA = UnsignedLong(opt32\AddressOfEntryPoint)
        sectionAlignment = UnsignedLong(opt32\SectionAlignment)
        fileAlignment = UnsignedLong(opt32\FileAlignment)
        sizeOfImage = UnsignedLong(opt32\SizeOfImage)
        sizeOfHeaders = UnsignedLong(opt32\SizeOfHeaders)
        ImageHeadersSize = sizeOfHeaders
        numDataDirs = opt32\NumberOfRvaAndSizes
        LoadDataDirectoriesFromHeader(@opt32, optionalMagic, SizeOf(IMAGE_OPTIONAL_HEADER32), numDataDirs)
      EndIf
        
    Case $20B  ; PE32+
      is64Bit = #True
      If fileHeader\SizeOfOptionalHeader < SizeOf(IMAGE_OPTIONAL_HEADER64)
        CloseFile(fileID)
        SetStatus("Optional header smaller than expected for PE32+!")
        ProcedureReturn #False
      Else
        If Not ReadExact(fileID, @opt64, SizeOf(IMAGE_OPTIONAL_HEADER64))
          CloseFile(fileID)
          SetStatus("Failed to read PE32+ optional header!")
          ProcedureReturn #False
        EndIf
        AddInfo("AddressOfEntryPoint:", "0x" + Hex32(opt64\AddressOfEntryPoint))
        AddInfo("ImageBase:", "0x" + Hex(opt64\ImageBase))
        AddInfo("SectionAlignment:", Str(UnsignedLong(opt64\SectionAlignment)))
        AddInfo("FileAlignment:", Str(UnsignedLong(opt64\FileAlignment)))
        AddInfo("SizeOfImage:", Str(UnsignedLong(opt64\SizeOfImage)))
        AddInfo("SizeOfHeaders:", Str(UnsignedLong(opt64\SizeOfHeaders)))
        AddInfo("Subsystem:", SubsystemToString(opt64\Subsystem) + " (0x" + RSet(Hex(opt64\Subsystem & $FFFF), 4, "0") + ")")
        AddInfo("NumberOfRvaAndSizes:", Str(UnsignedLong(opt64\NumberOfRvaAndSizes)))
        entryPointRVA = UnsignedLong(opt64\AddressOfEntryPoint)
        sectionAlignment = UnsignedLong(opt64\SectionAlignment)
        fileAlignment = UnsignedLong(opt64\FileAlignment)
        sizeOfImage = UnsignedLong(opt64\SizeOfImage)
        sizeOfHeaders = UnsignedLong(opt64\SizeOfHeaders)
        ImageHeadersSize = sizeOfHeaders
        numDataDirs = opt64\NumberOfRvaAndSizes
        LoadDataDirectoriesFromHeader(@opt64, optionalMagic, SizeOf(IMAGE_OPTIONAL_HEADER64), numDataDirs)
      EndIf
      
    Default
      is64Bit = #False
      SetStatus("Unknown optional header magic; basic header info only.")
  EndSelect
  
  ;--- Read section headers
  sectionHeadersOffset = dosHeader\e_lfanew + 4 + SizeOf(IMAGE_FILE_HEADER) + fileHeader\SizeOfOptionalHeader
  sectionHeadersSize = fileHeader\NumberOfSections * SizeOf(IMAGE_SECTION_HEADER)
  If sectionHeadersOffset < 0 Or sectionHeadersOffset > fileSize Or sectionHeadersSize > fileSize - sectionHeadersOffset
    CloseFile(fileID)
    SetStatus("Section headers are out of range!")
    ProcedureReturn #False
  EndIf

  FileSeek(fileID, sectionHeadersOffset)

  For i = 0 To fileHeader\NumberOfSections - 1
    AddElement(Sections())
    If Not ReadExact(fileID, @Sections(), SizeOf(IMAGE_SECTION_HEADER))
      CloseFile(fileID)
      SetStatus("Failed to read section headers!")
      ProcedureReturn #False
    EndIf
  Next
  
  ;--- Add section summary to log (not the ListIcon yet)
  AddElement(LogLines())
  LogLines() = "----------------------------------------"
  AddElement(LogLines())
  LogLines() = "SECTIONS (" + Str(fileHeader\NumberOfSections) + "):"
  
  ForEach Sections()
    Protected secName.s = GetSectionName(@Sections())
    
    AddElement(LogLines())
    LogLines() = "Section: " + secName + 
                 " VA:0x" + Hex32(Sections()\VirtualAddress) + 
                 " VS:" + Str(UnsignedLong(Sections()\VirtualSize)) + 
                 " RS:" + Str(UnsignedLong(Sections()\SizeOfRawData)) + 
                 " RP:0x" + Hex32(Sections()\PointerToRawData) + 
                 " Chars:0x" + Hex32(Sections()\Characteristics)
  Next
  
  ;--- Load entire file into memory for hex viewer & entropy
  FileSeek(fileID, 0)
  FileBufferSize = fileSize
  *FileBuffer = AllocateMemory(FileBufferSize)
  If *FileBuffer = 0
    CloseFile(fileID)
    SetStatus("Failed to allocate memory for file buffer!")
    ProcedureReturn #False
  EndIf

  If Not ReadExact(fileID, *FileBuffer, FileBufferSize)
    CloseFile(fileID)
    ClearInfo()
    SetStatus("Failed to read the full file into memory!")
    ProcedureReturn #False
  EndIf

  If ListSize(DataDirs()) > 1 And SelectElement(DataDirs(), 1)
    importRVA = UnsignedLong(DataDirs()\VirtualAddress)
    importSize = UnsignedLong(DataDirs()\Size)
  EndIf

  AnalyzePEWarnings(fileSize, entryPointRVA, fileAlignment, sectionAlignment, sizeOfHeaders, sizeOfImage, importRVA, importSize, sectionHeadersOffset, sectionHeadersSize)
  
  CloseFile(fileID)
  SetStatus("Parsed successfully: " + GetFilePart(file))
  ProcedureReturn #True
EndProcedure

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    ClearInfo()
    If hMutex
      CloseHandle_(hMutex)
      hMutex = 0
    EndIf
    End
  EndIf
EndProcedure

Procedure SaveLog()
  If CurrentFile = "" : SetStatus("No file loaded.") : ProcedureReturn : EndIf
  
  Protected outFile.s = SaveFileRequester("Save Log", CurrentFile + "_log.txt", "Text (*.txt)|*.txt|All Files (*.*)|*.*", 0)
  If outFile = "" : ProcedureReturn : EndIf
  
  Protected fileID = CreateFile(#PB_Any, outFile)
  If fileID = 0 : SetStatus("Failed to create file!") : ProcedureReturn : EndIf
  
  ForEach LogLines()
    WriteStringN(fileID, LogLines())
  Next
  
  CloseFile(fileID)
  SetStatus("Log saved to: " + outFile)
EndProcedure

Procedure ShowAbout()
  Protected msg.s
  msg = #APP_NAME + " - " + version + #CRLF$ +
        "For viewing info in .EXE and DLL files." + #CRLF$ +
        "---------------------------------------" + #CRLF$ +
        "Contact: " + #EMAIL_NAME + #CRLF$ +
        "Website: https://github.com/zonemaster60"

  MessageRequester("About " + #APP_NAME, msg, #PB_MessageRequester_Info)
EndProcedure

Procedure ShowSections()
  BeginListUpdate()
  ClearGadgetItems(#Gad_List)
  
  If ListSize(Sections()) = 0
    EndListUpdate()
    SetStatus("No sections available.")
    ProcedureReturn
  EndIf
  
  ForEach Sections()
    Protected name.s = GetSectionName(@Sections())
    
    ; Calculate Entropy
    Protected entropy.f = 0
    Protected rawPtr.q = UnsignedLong(Sections()\PointerToRawData)
    Protected rawSize.q = UnsignedLong(Sections()\SizeOfRawData)
    Protected virtAddr.q = UnsignedLong(Sections()\VirtualAddress)
    Protected virtSize.q = UnsignedLong(Sections()\VirtualSize)
    If *FileBuffer And rawPtr > 0 And rawSize > 0
      If rawPtr + rawSize <= FileBufferSize
        entropy = CalculateEntropy(*FileBuffer + rawPtr, rawSize)
      EndIf
    EndIf
    
    Protected entropyStr.s = StrF(entropy, 2)
    If entropy > 7.0 : entropyStr + " (Packed?)" : EndIf
    
    Protected info.s = "VirtAddr: 0x" + Hex32(Sections()\VirtualAddress) +
                       " | VirtSize: " + Str(virtSize) +
                       " | RawSize: " + Str(rawSize) +
                       " | RawPtr: 0x" + Hex32(Sections()\PointerToRawData) + #CRLF$ +
                       "Entropy: " + entropyStr + " | Chars: " + SectionCharacteristicsToString(Sections()\Characteristics)
    
    AddGadgetItem(#Gad_List, -1, name + Chr(10) + info)
  Next
  
  EndListUpdate()
  SetStatus("Showing " + Str(ListSize(Sections())) + " sections")
EndProcedure

Procedure ShowHexDump(startOffset.q = 0)
  Protected *buffer.Ascii
  Protected size.q, offset.q, endOffset.q
  Protected line.s, hexPart.s, asciiPart.s
  Protected i, bytesPerLine = 16
  
  ; We use a chunking approach to avoid GUI lag with very large files
  ; Each "page" is 64KB, but we can now jump to any offset.
  Protected chunkSize.q = 65536 
  
  ClearGadgetItems(#Gad_List)
  
  If *FileBuffer = 0 Or FileBufferSize = 0
    SetStatus("No file loaded for hex view.")
    ProcedureReturn
  EndIf
  
  *buffer = *FileBuffer
  size = FileBufferSize
  
  ; Ensure startOffset is aligned to 16 bytes
  offset = (startOffset / 16) * 16
  If offset < 0 : offset = 0 : EndIf
  If offset >= size : offset = ((size - 1) / 16) * 16 : EndIf
  CurrentHexOffset = offset
  
  endOffset = offset + chunkSize
  If endOffset > size : endOffset = size : EndIf
  
  SetStatus("Showing hex: 0x" + Hex(offset) + " to 0x" + Hex(endOffset) + " (Total: " + Str(size) + " bytes)")
  
  BeginListUpdate()
  
  While offset < endOffset
    hexPart = ""
    asciiPart = ""
    
    For i = 0 To bytesPerLine - 1
      If offset + i < size
        Protected byte.i = PeekA(*buffer + offset + i) & $FF
        hexPart + RSet(Hex(byte), 2, "0") + " "
        
        If byte >= 32 And byte <= 126
          asciiPart + Chr(byte)
        Else
          asciiPart + "."
        EndIf
      Else
        hexPart + "   "
        asciiPart + " "
      EndIf
    Next
    
    line = RSet(Hex(offset), 8, "0") + ": " + hexPart + " | " + asciiPart
    AddGadgetItem(#Gad_List, -1, line)
    
    offset + bytesPerLine
  Wend
  
  EndListUpdate()
EndProcedure

Procedure GoToAddress(hexAddr.s)
  Protected addr.q
  Protected i, count, lineAddr.q

  If *FileBuffer = 0 Or FileBufferSize <= 0
    SetStatus("No file loaded for hex view.")
    ProcedureReturn
  EndIf

  If Not IsHexAddress(hexAddr)
    SetStatus("Enter a valid hexadecimal address.")
    ProcedureReturn
  EndIf

  addr = Val("$" + NormalizeHexAddress(hexAddr))
  
  If CurrentView <> #View_Hex
    SetStatus("Go to Address only works in Hex View.")
    ProcedureReturn
  EndIf
  
  If addr < 0 : addr = 0 : EndIf
  If addr >= FileBufferSize : addr = FileBufferSize - 1 : EndIf
  
  ; If address is outside current visible 64KB chunk, reload the chunk
  ; We check the first and last item in the list
  count = CountGadgetItems(#Gad_List)
  If count > 0
    Protected first.q = Val("$" + Left(GetGadgetItemText(#Gad_List, 0, 0), 8))
    Protected last.q  = Val("$" + Left(GetGadgetItemText(#Gad_List, count-1, 0), 8)) + 15
    
    If addr < first Or addr > last
      ShowHexDump(addr)
      count = CountGadgetItems(#Gad_List)
    EndIf
  Else
    ShowHexDump(addr)
    count = CountGadgetItems(#Gad_List)
  EndIf
  
  ; Now find and select the line
  For i = 0 To count - 1
    lineAddr = Val("$" + Left(GetGadgetItemText(#Gad_List, i, 0), 8))
    If addr >= lineAddr And addr < lineAddr + 16
      SetGadgetState(#Gad_List, i)
      SendMessage_(GadgetID(#Gad_List), #LVM_ENSUREVISIBLE, i, #False)
      SetStatus("Jumped to address: 0x" + Hex(addr))
      ProcedureReturn
    EndIf
  Next
EndProcedure

Procedure ShowImports()
  Protected importCount.i = 0
  Protected descriptorCount.i = 0
  Protected dllCount.i = 0
  Protected invalidNameCount.i = 0
  Protected invalidThunkCount.i = 0
  Protected thunkLimitHit.b = #False

  If ImportCacheReady
    RenderCachedRows(ImportRows())
    SetStatus(ImportStatus)
    ProcedureReturn
  EndIf

  ShowListMessage("Loading imports...", "Scanning import descriptors and thunk tables")
  SetStatus("Loading imports...")
  ClearList(ImportRows())
  
  If ListSize(DataDirs()) < 2
    AddCachedRow(ImportRows(), "No imports", "Import directory entry is not available")
    ImportCacheReady = #True
    ImportStatus = "No data directories found."
    RenderCachedRows(ImportRows())
    SetStatus(ImportStatus)
    ProcedureReturn
  EndIf
  
  SelectElement(DataDirs(), 1) ; Import Table is index 1
  Protected importRVA.q = UnsignedLong(DataDirs()\VirtualAddress)
  Protected importSize.q = UnsignedLong(DataDirs()\Size)
  
  If importRVA = 0 Or importSize = 0
    AddCachedRow(ImportRows(), "No imports", "This file does not contain an import table")
    ImportCacheReady = #True
    ImportStatus = "No Import Table found in this file."
    RenderCachedRows(ImportRows())
    SetStatus(ImportStatus)
    ProcedureReturn
  EndIf
  
  Protected offset.q = RvaToOffset(importRVA)
  If offset = -1 Or *FileBuffer = 0 Or Not IsFileRangeValid(offset, SizeOf(My_IMAGE_IMPORT_DESCRIPTOR))
    AddCachedRow(ImportRows(), "Invalid import table", "The import directory RVA does not map to readable file data")
    AddCachedRow(ImportRows(), "Directory", "RVA: 0x" + Hex(importRVA) + " | Size: " + Str(importSize))
    ImportCacheReady = #True
    ImportStatus = "Import Table offset out of range."
    RenderCachedRows(ImportRows())
    SetStatus(ImportStatus)
    ProcedureReturn
  EndIf
  
  Protected descriptorOffset.q = offset
  Protected importEndOffset.q = offset + importSize
  Protected dllName.s, funcName.s
  Protected thunkOffset.q, thunkTableOffset.q, currentThunkRVA.q, nameOffset.q, nameDataOffset.q
  Protected thunkValue.q, ordinalMask.q
  Protected thunkEntrySize.i
  Protected is64.b = is64Bit
  
  While descriptorOffset + SizeOf(My_IMAGE_IMPORT_DESCRIPTOR) <= importEndOffset And IsFileRangeValid(descriptorOffset, SizeOf(My_IMAGE_IMPORT_DESCRIPTOR))
    Protected *importDesc.My_IMAGE_IMPORT_DESCRIPTOR = *FileBuffer + descriptorOffset

    If *importDesc\OriginalFirstThunk = 0 And *importDesc\Name = 0 And *importDesc\FirstThunk = 0
      Break
    EndIf

    nameOffset = RvaToOffset(UnsignedLong(*importDesc\Name))
    If nameOffset <> -1 And nameOffset < FileBufferSize
      dllName = PeekAsciiZ(nameOffset)
      If dllName = ""
        dllName = "<Unnamed DLL>"
        invalidNameCount + 1
      EndIf
      AddCachedRow(ImportRows(), dllName, "Descriptor Offset: 0x" + Hex(descriptorOffset) + " | Name RVA: 0x" + Hex32(*importDesc\Name))
      dllCount + 1
      
      ; OriginalFirstThunk (ILT) is preferred, fallback to FirstThunk (IAT)
      Protected thunkRVA.q = UnsignedLong(*importDesc\OriginalFirstThunk)
      If thunkRVA = 0 : thunkRVA = UnsignedLong(*importDesc\FirstThunk) : EndIf

      If thunkRVA > 0
        thunkOffset = RvaToOffset(thunkRVA)
      Else
        thunkOffset = -1
      EndIf

      If thunkOffset <> -1
        thunkTableOffset = thunkOffset
        thunkEntrySize = GetThunkEntrySize(is64)
        ; Import thunks often live outside the import directory blob itself.
        ; Walk until the terminating zero thunk or unreadable file data.
        While IsFileRangeValid(thunkOffset, thunkEntrySize)
          thunkValue = ReadThunkValue(*FileBuffer + thunkOffset, is64)
          If thunkValue = 0
            Break
          EndIf

          If importCount >= #MaxImportEntries
            thunkLimitHit = #True
            Break
          EndIf
          
          ; Check for Import by Ordinal
          ordinalMask = $80000000
          If is64 : ordinalMask = $8000000000000000 : EndIf
          
          If thunkValue & ordinalMask
            funcName = "Ordinal: " + Str(thunkValue & $FFFF)
            nameDataOffset = -1
          Else
            If is64
              nameDataOffset = RvaToOffset(thunkValue & $7FFFFFFFFFFFFFFF)
            Else
              nameDataOffset = RvaToOffset(thunkValue & $7FFFFFFF)
            EndIf
            
            If nameDataOffset <> -1 And IsFileRangeValid(nameDataOffset, 3)
              funcName = PeekAsciiZ(nameDataOffset + 2)
              If funcName = ""
                funcName = "<Unnamed Import>"
                invalidNameCount + 1
              EndIf
            Else
              funcName = "<Unknown>"
              invalidThunkCount + 1
            EndIf
          EndIf

          currentThunkRVA = thunkRVA + (thunkOffset - thunkTableOffset)
          Protected thunkInfo.s = "Thunk RVA: 0x" + Hex(currentThunkRVA) + " | File Offset: 0x" + Hex(thunkOffset)
          If nameDataOffset <> -1
            thunkInfo + " | Name Offset: 0x" + Hex(nameDataOffset)
          EndIf
          AddCachedRow(ImportRows(), "  " + funcName, thunkInfo)
          importCount + 1
          thunkOffset + thunkEntrySize
        Wend
      Else
        invalidThunkCount + 1
      EndIf
    Else
      invalidNameCount + 1
      AddCachedRow(ImportRows(), "<Invalid DLL Name RVA>", "Descriptor Offset: 0x" + Hex(descriptorOffset) + " | Name RVA: 0x" + Hex32(*importDesc\Name))
    EndIf

    If thunkLimitHit
      Break
    EndIf
    
    descriptorOffset + SizeOf(My_IMAGE_IMPORT_DESCRIPTOR)
    descriptorCount + 1
    If descriptorCount > #MaxImportDescriptors : Break : EndIf
  Wend

  If dllCount = 0 And importCount = 0
    AddCachedRow(ImportRows(), "No imports", "No readable import descriptors were found")
  Else
    AddCachedRow(ImportRows(), "Summary", "DLLs: " + Str(dllCount) + " | Descriptors: " + Str(descriptorCount) + " | Imports: " + Str(importCount) + " | Name issues: " + Str(invalidNameCount) + " | Thunk issues: " + Str(invalidThunkCount))
    If thunkLimitHit
      AddCachedRow(ImportRows(), "Notice", "Import display was capped to keep the UI responsive")
    EndIf
  EndIf

  ImportCacheReady = #True
  ImportStatus = "Imports: " + Str(dllCount) + " DLLs, " + Str(importCount) + " entries"
  RenderCachedRows(ImportRows())
  SetStatus(ImportStatus)
EndProcedure

Procedure ShowExports()
  Protected exportNamesShown.i = 0
  Protected invalidExportNameCount.i = 0
  Protected invalidExportOrdinalCount.i = 0
  Protected forwarderCount.i = 0
  Protected exportLimitHit.b = #False
  Protected exportTableIssueCount.i = 0
  Protected exportName.s
  Protected exportNameOffset.q

  If ExportCacheReady
    RenderCachedRows(ExportRows())
    SetStatus(ExportStatus)
    ProcedureReturn
  EndIf

  ShowListMessage("Loading exports...", "Scanning export directory and named exports")
  SetStatus("Loading exports...")
  ClearList(ExportRows())
  
  If ListSize(DataDirs()) = 0
    AddCachedRow(ExportRows(), "No exports", "Export directory entry is not available")
    ExportCacheReady = #True
    ExportStatus = "No data directories found."
    RenderCachedRows(ExportRows())
    SetStatus(ExportStatus)
    ProcedureReturn
  EndIf
  
  SelectElement(DataDirs(), 0) ; Export Table is index 0
  Protected exportRVA.q = UnsignedLong(DataDirs()\VirtualAddress)
  Protected exportSize.q = UnsignedLong(DataDirs()\Size)
  Protected declaredNames.q
  Protected declaredFunctions.q
  
  If exportRVA = 0 Or exportSize = 0
    AddCachedRow(ExportRows(), "No exports", "This file does not contain an export table")
    ExportCacheReady = #True
    ExportStatus = "No Export Table found in this file."
    RenderCachedRows(ExportRows())
    SetStatus(ExportStatus)
    ProcedureReturn
  EndIf
  
  Protected offset.q = RvaToOffset(exportRVA)
  If offset = -1 Or *FileBuffer = 0 Or Not IsFileRangeValid(offset, SizeOf(My_IMAGE_EXPORT_DIRECTORY))
    AddCachedRow(ExportRows(), "Invalid export table", "The export directory RVA does not map to readable file data")
    AddCachedRow(ExportRows(), "Directory", "RVA: 0x" + Hex(exportRVA) + " | Size: " + Str(exportSize))
    ExportCacheReady = #True
    ExportStatus = "Export Table offset out of range."
    RenderCachedRows(ExportRows())
    SetStatus(ExportStatus)
    ProcedureReturn
  EndIf
  
  Protected *exportDir.My_IMAGE_EXPORT_DIRECTORY = *FileBuffer + offset
  Protected i
  Protected nameOffset.q, funcOffset.q, ordOffset.q
  Protected nameBytes.q, ordinalBytes.q, functionBytes.q
  
  ; Get names and ordinals
  Protected *names.Long = 0
  Protected *ordinals.Word = 0
  Protected *functions.Long = 0
  declaredNames = UnsignedLong(*exportDir\NumberOfNames)
  declaredFunctions = UnsignedLong(*exportDir\NumberOfFunctions)
  
  nameBytes = declaredNames * 4
  ordinalBytes = declaredNames * 2
  functionBytes = declaredFunctions * 4
  
  If declaredNames > #MaxExportEntries
    exportLimitHit = #True
  EndIf
  
  If UnsignedLong(*exportDir\AddressOfNames) > 0
    nameOffset = RvaToOffset(UnsignedLong(*exportDir\AddressOfNames))
    If nameOffset <> -1 And IsFileRangeValid(nameOffset, nameBytes)
      *names = *FileBuffer + nameOffset
    ElseIf declaredNames > 0
      exportTableIssueCount + 1
    EndIf
  ElseIf declaredNames > 0
    exportTableIssueCount + 1
  EndIf
  
  If UnsignedLong(*exportDir\AddressOfNameOrdinals) > 0
    ordOffset = RvaToOffset(UnsignedLong(*exportDir\AddressOfNameOrdinals))
    If ordOffset <> -1 And IsFileRangeValid(ordOffset, ordinalBytes)
      *ordinals = *FileBuffer + ordOffset
    ElseIf declaredNames > 0
      exportTableIssueCount + 1
    EndIf
  ElseIf declaredNames > 0
    exportTableIssueCount + 1
  EndIf
  
  If declaredFunctions > 0 And UnsignedLong(*exportDir\AddressOfFunctions) > 0
    funcOffset = RvaToOffset(UnsignedLong(*exportDir\AddressOfFunctions))
    If funcOffset <> -1 And IsFileRangeValid(funcOffset, functionBytes)
      *functions = *FileBuffer + funcOffset
    Else
      exportTableIssueCount + 1
    EndIf
  ElseIf declaredFunctions > 0
    exportTableIssueCount + 1
  EndIf
  
  exportNameOffset = RvaToOffset(UnsignedLong(*exportDir\Name))
  If exportNameOffset <> -1 And IsFileRangeValid(exportNameOffset, 1)
    exportName = PeekAsciiZ(exportNameOffset)
  Else
    exportName = "<Unnamed Export DLL>"
  EndIf

  AddCachedRow(ExportRows(), "Export Directory", "Name: " + exportName + " | RVA: 0x" + Hex(exportRVA) + " | File Offset: 0x" + Hex(offset))
  
  If *names And *ordinals
    For i = 0 To declaredNames - 1
      If exportNamesShown >= #MaxExportEntries
        exportLimitHit = #True
        Break
      EndIf

      Protected nRVA.l = PeekL(*names + (i * 4))
      Protected nOffset.q = RvaToOffset(UnsignedLong(nRVA))
      If nOffset <> -1 And IsFileRangeValid(nOffset, 1)
        Protected expName.s = PeekAsciiZ(nOffset)
        Protected ordinal.i = PeekW(*ordinals + (i * 2)) & $FFFF
        Protected funcRVA.q = 0
        Protected exportDetail.s
        If *functions And ordinal < declaredFunctions
          funcRVA = UnsignedLong(PeekL(*functions + (ordinal * 4)))
        Else
          invalidExportOrdinalCount + 1
        EndIf
        If expName = ""
          expName = "<Unnamed Export>"
          invalidExportNameCount + 1
        EndIf

        exportDetail = "Ordinal: " + Str(ordinal + UnsignedLong(*exportDir\Base))
        If funcRVA >= exportRVA And funcRVA < exportRVA + exportSize
          Protected forwarderOffset.q = RvaToOffset(funcRVA)
          Protected forwarderName.s = "<Invalid Forwarder>"
          If forwarderOffset <> -1 And IsFileRangeValid(forwarderOffset, 1)
            forwarderName = PeekAsciiZ(forwarderOffset)
            If forwarderName = ""
              forwarderName = "<Empty Forwarder>"
            EndIf
          EndIf
          exportDetail + " | Forwarder -> " + forwarderName + " | Name Offset: 0x" + Hex(nOffset)
          forwarderCount + 1
        Else
          exportDetail + " | RVA: 0x" + Hex(funcRVA) + " | Name Offset: 0x" + Hex(nOffset)
        EndIf

        AddCachedRow(ExportRows(), expName, exportDetail)
        exportNamesShown + 1
      Else
        invalidExportNameCount + 1
      EndIf
    Next
  ElseIf declaredFunctions > 0
    AddCachedRow(ExportRows(), "Ordinal-only exports", "Named export tables are missing or unreadable; ordinal exports may still exist")
  Else
    AddCachedRow(ExportRows(), "Unnamed exports", "Export table exists but has no readable named export list")
  EndIf

  If declaredNames > declaredFunctions
    AddCachedRow(ExportRows(), "Warning", "Export table declares more names than functions")
  EndIf
  If exportTableIssueCount > 0
    AddCachedRow(ExportRows(), "Warning", "One or more export address/name tables are missing or unreadable")
  EndIf

  AddCachedRow(ExportRows(), "Summary", "Named exports shown: " + Str(exportNamesShown) + " | Declared names: " + Str(declaredNames) + " | Functions: " + Str(declaredFunctions) + " | Forwarders: " + Str(forwarderCount) + " | Name issues: " + Str(invalidExportNameCount) + " | Ordinal issues: " + Str(invalidExportOrdinalCount) + " | Table issues: " + Str(exportTableIssueCount))
  If exportLimitHit
    AddCachedRow(ExportRows(), "Notice", "Export display was capped to keep the UI responsive")
  EndIf

  ExportCacheReady = #True
  ExportStatus = "Exports: " + Str(exportNamesShown) + " shown, " + Str(declaredNames) + " declared"
  RenderCachedRows(ExportRows())
  SetStatus(ExportStatus)
EndProcedure

Procedure.s ResourceIdToString(id.l)
  Select id
    Case 1 : ProcedureReturn "Cursor"
    Case 2 : ProcedureReturn "Bitmap"
    Case 3 : ProcedureReturn "Icon"
    Case 4 : ProcedureReturn "Menu"
    Case 5 : ProcedureReturn "Dialog"
    Case 6 : ProcedureReturn "String"
    Case 7 : ProcedureReturn "FontDir"
    Case 8 : ProcedureReturn "Font"
    Case 9 : ProcedureReturn "Accelerator"
    Case 10 : ProcedureReturn "RCData"
    Case 11 : ProcedureReturn "MessageTable"
    Case 12 : ProcedureReturn "Group Cursor"
    Case 14 : ProcedureReturn "Group Icon"
    Case 16 : ProcedureReturn "Version"
    Case 17 : ProcedureReturn "DlgInclude"
    Case 19 : ProcedureReturn "PlugPlay"
    Case 20 : ProcedureReturn "Vxd"
    Case 21 : ProcedureReturn "AniCursor"
    Case 22 : ProcedureReturn "AniIcon"
    Case 23 : ProcedureReturn "HTML"
    Case 24 : ProcedureReturn "Manifest"
    Default : ProcedureReturn "Type " + Str(id)
  EndSelect
EndProcedure

Procedure.b ResourceNameIsString(nameField.l)
  ProcedureReturn Bool(nameField & $80000000)
EndProcedure

Procedure.b ResourceEntryIsDirectory(offsetField.l)
  ProcedureReturn Bool(offsetField & $80000000)
EndProcedure

Procedure.q ResourceEntryOffset(value.l)
  ProcedureReturn value & $7FFFFFFF
EndProcedure

Procedure.b IsResourceRelativeOffsetValid(resBaseOffset.q, resSize.q, relativeOffset.q, bytesNeeded.q)
  If relativeOffset < 0 Or bytesNeeded < 0
    ProcedureReturn #False
  EndIf

  If relativeOffset > resSize
    ProcedureReturn #False
  EndIf

  If bytesNeeded > resSize - relativeOffset
    ProcedureReturn #False
  EndIf

  ProcedureReturn IsFileRangeValid(resBaseOffset + relativeOffset, bytesNeeded)
EndProcedure

Procedure.s ReadResourceDirString(resBaseOffset.q, resSize.q, nameField.l)
  Protected stringOffset.q = ResourceEntryOffset(nameField)
  Protected charCount.q

  If Not IsResourceRelativeOffsetValid(resBaseOffset, resSize, stringOffset, SizeOf(Word))
    ProcedureReturn "<Invalid Name>"
  EndIf

  charCount = PeekW(*FileBuffer + resBaseOffset + stringOffset) & $FFFF
  If charCount = 0
    ProcedureReturn "<Empty Name>"
  EndIf

  If Not IsResourceRelativeOffsetValid(resBaseOffset, resSize, stringOffset + SizeOf(Word), charCount * SizeOf(Word))
    ProcedureReturn "<Invalid Name>"
  EndIf

  ProcedureReturn PeekS(*FileBuffer + resBaseOffset + stringOffset + SizeOf(Word), charCount, #PB_Unicode)
EndProcedure

Procedure.s PrimaryLangName(primary.w)
  Select primary
    Case 0  : ProcedureReturn "Neutral"
    Case 1  : ProcedureReturn "Arabic"
    Case 4  : ProcedureReturn "Chinese"
    Case 7  : ProcedureReturn "German"
    Case 9  : ProcedureReturn "English"
    Case 10 : ProcedureReturn "Spanish"
    Case 12 : ProcedureReturn "French"
    Case 16 : ProcedureReturn "Italian"
    Case 17 : ProcedureReturn "Japanese"
    Case 18 : ProcedureReturn "Korean"
    Case 19 : ProcedureReturn "Dutch"
    Case 21 : ProcedureReturn "Polish"
    Case 22 : ProcedureReturn "Portuguese"
    Case 25 : ProcedureReturn "Russian"
    Case 29 : ProcedureReturn "Swedish"
    Case 31 : ProcedureReturn "Turkish"
    Case 34 : ProcedureReturn "Ukrainian"
    Default : ProcedureReturn "Unknown"
  EndSelect
EndProcedure

Procedure.s LangIdToString(langId.w)
  Protected langValue.i = langId & $FFFF
  Protected primary.i = langValue & $03FF
  Protected sublang.i = (langValue >> 10) & $003F

  ProcedureReturn "0x" + RSet(Hex(langValue), 4, "0") + " (" + PrimaryLangName(primary) + ", sub " + Str(sublang) + ")"
EndProcedure

Procedure.s ResourceEntryNameToString(*entry.My_IMAGE_RESOURCE_DIRECTORY_ENTRY, resBaseOffset.q, resSize.q, isTypeLevel.b)
  Protected idValue.i

  If *entry = 0
    ProcedureReturn "<Invalid Entry>"
  EndIf

  If ResourceNameIsString(*entry\Name)
    ProcedureReturn ReadResourceDirString(resBaseOffset, resSize, *entry\Name)
  EndIf

  idValue = *entry\Name & $FFFF
  If isTypeLevel
    ProcedureReturn ResourceIdToString(idValue)
  EndIf

  ProcedureReturn "ID " + Str(idValue)
EndProcedure

Procedure ShowResources()
  Protected resourceCount.i = 0
  Protected namedTypeCount.i = 0
  Protected namedEntryCount.i = 0
  Protected invalidResourceDirCount.i = 0
  Protected invalidResourceDataCount.i = 0

  If ResourceCacheReady
    RenderCachedRows(ResourceRows())
    SetStatus(ResourceStatus)
    ProcedureReturn
  EndIf

  ShowListMessage("Loading resources...", "Scanning resource directory entries")
  SetStatus("Loading resources...")
  ClearList(ResourceRows())
  
  If ListSize(DataDirs()) < 3
    AddCachedRow(ResourceRows(), "No resources", "Resource directory entry is not available")
    ResourceCacheReady = #True
    ResourceStatus = "No data directories found."
    RenderCachedRows(ResourceRows())
    SetStatus(ResourceStatus)
    ProcedureReturn
  EndIf
  
  SelectElement(DataDirs(), 2) ; Resource Table is index 2
  Protected resRVA.q = UnsignedLong(DataDirs()\VirtualAddress)
  Protected resSize.q = UnsignedLong(DataDirs()\Size)
  
  If resRVA = 0 Or resSize = 0
    AddCachedRow(ResourceRows(), "No resources", "This file does not contain a resource table")
    ResourceCacheReady = #True
    ResourceStatus = "No Resource Table found."
    RenderCachedRows(ResourceRows())
    SetStatus(ResourceStatus)
    ProcedureReturn
  EndIf
  
  Protected offset.q = RvaToOffset(resRVA)
  If offset = -1 Or *FileBuffer = 0 Or Not IsFileRangeValid(offset, SizeOf(My_IMAGE_RESOURCE_DIRECTORY))
    AddCachedRow(ResourceRows(), "Invalid resource table", "The resource directory RVA does not map to readable file data")
    AddCachedRow(ResourceRows(), "Directory", "RVA: 0x" + Hex(resRVA) + " | Size: " + Str(resSize))
    ResourceCacheReady = #True
    ResourceStatus = "Resource Table offset out of range."
    RenderCachedRows(ResourceRows())
    SetStatus(ResourceStatus)
    ProcedureReturn
  EndIf
  
  Protected *root.My_IMAGE_RESOURCE_DIRECTORY = *FileBuffer + offset
  Protected i, j, k
  Protected rootEntries.i = *root\NumberOfNamedEntries + *root\NumberOfIdEntries
  If rootEntries > #MaxResourceEntries : rootEntries = #MaxResourceEntries : EndIf
  
  AddCachedRow(ResourceRows(), "Resource Directory", "RVA: 0x" + Hex(resRVA) + " | File Offset: 0x" + Hex(offset) + " | Size: " + Str(resSize))
  
  ; Root level: Types
  Protected *typeEntry.My_IMAGE_RESOURCE_DIRECTORY_ENTRY = *root + SizeOf(My_IMAGE_RESOURCE_DIRECTORY)
  For i = 0 To rootEntries - 1
    If Not IsResourceRelativeOffsetValid(offset, resSize, SizeOf(My_IMAGE_RESOURCE_DIRECTORY) + (i * SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY)), SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY))
      Break
    EndIf

    Protected typeName.s = ResourceEntryNameToString(*typeEntry, offset, resSize, #True)
    If ResourceNameIsString(*typeEntry\Name)
      namedTypeCount + 1
    EndIf
    
    If ResourceEntryIsDirectory(*typeEntry\OffsetToDirectory)
      Protected nameDirRel.q = ResourceEntryOffset(*typeEntry\OffsetToDirectory)
      Protected nameDirOffset.q = offset + nameDirRel
      If IsResourceRelativeOffsetValid(offset, resSize, nameDirRel, SizeOf(My_IMAGE_RESOURCE_DIRECTORY))
        Protected *nameDir.My_IMAGE_RESOURCE_DIRECTORY = *FileBuffer + nameDirOffset
        Protected *nameEntry.My_IMAGE_RESOURCE_DIRECTORY_ENTRY = *nameDir + SizeOf(My_IMAGE_RESOURCE_DIRECTORY)
        Protected nameEntries.i = *nameDir\NumberOfNamedEntries + *nameDir\NumberOfIdEntries
        If nameEntries > #MaxResourceEntries : nameEntries = #MaxResourceEntries : EndIf
        
        For j = 0 To nameEntries - 1
          If Not IsResourceRelativeOffsetValid(offset, resSize, nameDirRel + SizeOf(My_IMAGE_RESOURCE_DIRECTORY) + (j * SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY)), SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY))
            Break
          EndIf

          Protected resourceName.s = ResourceEntryNameToString(*nameEntry, offset, resSize, #False)
          If ResourceNameIsString(*nameEntry\Name)
            namedEntryCount + 1
          EndIf

          If ResourceEntryIsDirectory(*nameEntry\OffsetToDirectory)
            Protected langDirRel.q = ResourceEntryOffset(*nameEntry\OffsetToDirectory)
            Protected langDirOffset.q = offset + langDirRel
            If IsResourceRelativeOffsetValid(offset, resSize, langDirRel, SizeOf(My_IMAGE_RESOURCE_DIRECTORY))
              Protected *langDir.My_IMAGE_RESOURCE_DIRECTORY = *FileBuffer + langDirOffset
              Protected *langEntry.My_IMAGE_RESOURCE_DIRECTORY_ENTRY = *langDir + SizeOf(My_IMAGE_RESOURCE_DIRECTORY)
              Protected langEntries.i = *langDir\NumberOfNamedEntries + *langDir\NumberOfIdEntries
              If langEntries > #MaxResourceEntries : langEntries = #MaxResourceEntries : EndIf
              
              For k = 0 To langEntries - 1
                If Not IsResourceRelativeOffsetValid(offset, resSize, langDirRel + SizeOf(My_IMAGE_RESOURCE_DIRECTORY) + (k * SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY)), SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY))
                  Break
                EndIf

                If Not ResourceEntryIsDirectory(*langEntry\OffsetToData)
                  Protected dataEntryRel.q = ResourceEntryOffset(*langEntry\OffsetToData)
                  Protected dataEntryOffset.q = offset + dataEntryRel
                  Protected langName.s = "ID " + Str(*langEntry\Name & $FFFF)

                  If Not ResourceNameIsString(*langEntry\Name)
                    langName = LangIdToString(*langEntry\Name & $FFFF)
                  EndIf

                  If IsResourceRelativeOffsetValid(offset, resSize, dataEntryRel, SizeOf(My_IMAGE_RESOURCE_DATA_ENTRY))
                    Protected *dataEntry.My_IMAGE_RESOURCE_DATA_ENTRY = *FileBuffer + dataEntryOffset
                    Protected dataRva.q = UnsignedLong(*dataEntry\OffsetToData)
                    Protected dataFileOffset.q = RvaToOffset(dataRva)
                    Protected detail.s = "Name: " + resourceName + " | Lang: " + langName + " | RVA: 0x" + Hex32(*dataEntry\OffsetToData)
                    If dataFileOffset <> -1
                      detail + " | File Offset: 0x" + Hex(dataFileOffset)
                    Else
                      detail + " | File Offset: N/A"
                      invalidResourceDataCount + 1
                    EndIf
                    detail + " | Size: " + Str(UnsignedLong(*dataEntry\Size))
                    AddCachedRow(ResourceRows(), typeName, detail)
                    resourceCount + 1
                  Else
                    invalidResourceDataCount + 1
                  EndIf
                EndIf
                *langEntry + SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY)
              Next
            Else
              invalidResourceDirCount + 1
            EndIf
          EndIf
          *nameEntry + SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY)
        Next
      Else
        invalidResourceDirCount + 1
      EndIf
    EndIf
    *typeEntry + SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY)
  Next

  If resourceCount = 0
    AddCachedRow(ResourceRows(), "No resources", "No readable resource data entries were found")
  Else
    AddCachedRow(ResourceRows(), "Summary", "Readable resource entries: " + Str(resourceCount) + " | Named types: " + Str(namedTypeCount) + " | Named entries: " + Str(namedEntryCount) + " | Dir issues: " + Str(invalidResourceDirCount) + " | Data issues: " + Str(invalidResourceDataCount))
  EndIf

  ResourceCacheReady = #True
  ResourceStatus = "Resources: " + Str(resourceCount) + " entries"
  RenderCachedRows(ResourceRows())
  SetStatus(ResourceStatus)
EndProcedure

Procedure SwitchView(view.i)
  CurrentView = view
  
  If CurrentFile = "" And ListSize(LogLines()) = 0 And ListSize(Sections()) = 0 And FileBufferSize = 0
    SetStatus("No file loaded.")
    ProcedureReturn
  EndIf
  
  Select view
    Case #View_Headers
      ShowHeaders()
      
    Case #View_Sections
      ShowSections()
      
    Case #View_DataDirs
      ShowDataDirs()
      
    Case #View_Imports
      ShowImports()
      
    Case #View_Exports
      ShowExports()
      
    Case #View_Resources
      ShowResources()
      
    Case #View_Hex
      ShowHexDump(CurrentHexOffset)
  EndSelect
EndProcedure

Procedure FilterList(pattern.s)
  Protected i, text.s
  pattern = LCase(pattern)
  
  ; We can't easily "hide" GadgetItems in a ListIcon, 
  ; so we refresh from the correct source based on CurrentView
  Select CurrentView
    Case #View_Headers : ShowHeaders()
    Case #View_Sections : ShowSections()
    Case #View_DataDirs : ShowDataDirs()
    Case #View_Imports : ShowImports()
    Case #View_Exports : ShowExports()
    Case #View_Resources : ShowResources()
    Case #View_Hex : ShowHexDump(CurrentHexOffset)
  EndSelect

  
  If pattern = "" : ProcedureReturn : EndIf
  
  ; Filter the items that were just added
  For i = CountGadgetItems(#Gad_List) - 1 To 0 Step -1
    text = LCase(GetGadgetItemText(#Gad_List, i, 0) + " " + GetGadgetItemText(#Gad_List, i, 1))
    If FindString(text, pattern) = 0
      RemoveGadgetItem(#Gad_List, i)
    EndIf
  Next
EndProcedure

;-----------------------------------------------------------
; GUI creation
;-----------------------------------------------------------

Procedure CreateMainWindow()
  If OpenWindow(#Win_Main, 0, 0, 820, 520, #APP_NAME, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
    
    ButtonGadget(#Gad_Browse, 10, 10, 60, 24, "Browse")
    ButtonGadget(#Gad_SaveLog, 80, 10, 70, 24, "Save Log")
    ButtonGadget(#Gad_Export, 160, 10, 60, 24, "Export")
    ButtonGadget(#Gad_About, 230, 10, 60, 24, "About")
    ButtonGadget(#Gad_Exit, 300, 10, 60, 24, "Exit")
    StringGadget(#Gad_File, 370, 10, 440, 24, "", #PB_String_ReadOnly)
    
    ; Use the panel only as a tab selector and keep the shared list below it.
    ; Placing the ListIcon inside the panel area can cause repaint/z-order issues.
    PanelGadget(#Gad_Tabs, 10, 44, 800, 32)
      AddGadgetItem(#Gad_Tabs, -1, "Headers")
      AddGadgetItem(#Gad_Tabs, -1, "Sections")
      AddGadgetItem(#Gad_Tabs, -1, "Data Dirs")
      AddGadgetItem(#Gad_Tabs, -1, "Imports")
      AddGadgetItem(#Gad_Tabs, -1, "Exports")
      AddGadgetItem(#Gad_Tabs, -1, "Resources")
      AddGadgetItem(#Gad_Tabs, -1, "Hex View")
    CloseGadgetList()

    ListIconGadget(#Gad_List, 10, 82, 800, 370, "Field", 220, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(#Gad_List, 1, "Value", 555)
    
    ; Add a search field and Go to Address for the hex view
    TextGadget(#PB_Any, 10, 465, 45, 20, "Search:")
    Gad_Search = StringGadget(#PB_Any, 58, 462, 140, 22, "")
    
    TextGadget(#PB_Any, 215, 465, 75, 20, "Go to (Hex):")
    Gad_GoAddr = StringGadget(#PB_Any, 290, 462, 100, 22, "")
    Gad_GoBtn = ButtonGadget(#PB_Any, 400, 462, 40, 22, "Go")
    
    ; Enable Drag and Drop
    EnableWindowDrop(#Win_Main, #PB_Drop_Files, #PB_Drag_Copy)
    
    CreateStatusBar(#StatusBar_Main, WindowID(#Win_Main))
    AddStatusBarField(#PB_Ignore)
    SetStatus("Ready. Drag & Drop a file here.")
    
  EndIf
EndProcedure

;-----------------------------------------------------------
; File open dialog handler
;-----------------------------------------------------------

Procedure BrowseAndOpen(file.s = "")
  If file = ""
    file = OpenFileRequester("Select an EXE or DLL", "", "PE Files (*.exe;*.dll)|*.exe;*.dll|All Files (*.*)|*.*", 0)
  EndIf
  
  If file <> ""
    CurrentFile = file
    SetGadgetText(#Gad_File, file)

    If ParsePEFile(file)
      SetGadgetState(#Gad_Tabs, 0)
      SwitchView(#View_Headers)
    Else
      CurrentFile = ""
      SetGadgetText(#Gad_File, "")
    EndIf
  EndIf
EndProcedure

; Main
;-----------------------------------------------------------

CreateMainWindow()

Define Event, Gadget, EventType, droppedFiles.s, droppedFile.s

Repeat
  Event = WaitWindowEvent()
  
  Select Event
    Case #PB_Event_WindowDrop
      If EventDropType() = #PB_Drop_Files
        droppedFiles = EventDropFiles()
        droppedFile = StringField(droppedFiles, 1, Chr(10))
        BrowseAndOpen(droppedFile)
      EndIf
      
    Case #PB_Event_Gadget
      Gadget = EventGadget()
      EventType = EventType()
      
      Select Gadget
        Case Gad_Search
          If EventType = #PB_EventType_Change
            FilterList(GetGadgetText(Gad_Search))
          EndIf
          
        Case Gad_GoBtn
          GoToAddress(GetGadgetText(Gad_GoAddr))
          
        Case #Gad_Tabs
          If EventType = #PB_EventType_LeftClick Or EventType = #PB_EventType_Change
            SwitchView(GetGadgetState(#Gad_Tabs))
          EndIf
          
        Case #Gad_Browse
          BrowseAndOpen()
          
        Case #Gad_SaveLog
          SaveLog()
          
        Case #Gad_Export
          ExportData()
          
        Case #Gad_About
          ShowAbout()
          
        Case #Gad_Exit
          Exit()
      EndSelect
      
    Case #PB_Event_CloseWindow
      Exit()
  EndSelect
ForEver
; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 71
; FirstLine = 51
; Folding = -----------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = pb_exe-pe_viewer.ico
; Executable = ..\PB_EXE-PE_Viewer.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,5
; VersionField1 = 1,0,0,5
; VersionField2 = ZoneSoft
; VersionField3 = PB_EXE-PE_Viewer
; VersionField4 = 1.0.0.5
; VersionField5 = 1.0.0.5
; VersionField6 = View PE/EXE/DLL files and log info
; VersionField7 = PB_EXE-PE_Viewer
; VersionField8 = PB_EXE-PE_Viewer.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60