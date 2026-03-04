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

#APP_NAME   = "EXE-PE_Viewer"
#EMAIL_NAME = "zonemaster60@gmail.com"
Global version.s = "v1.0.0.3"

Global CurrentFile.s
Global NewList LogLines.s()
Global AppPath.s        = GetPathPart(ProgramFilename())
Global CurrentView.i = 0  ; 0=Headers, 1=Sections, 2=Hex Viewer
Global NewList Sections.IMAGE_SECTION_HEADER()
Global *FileBuffer
Global FileBufferSize.q
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
    Default    : ProcedureReturn "Unknown (" + Hex(machine, #PB_Unicode) + ")"
  EndSelect
EndProcedure

Procedure.s OptionalMagicToString(magic.w)
  Select magic
    Case $10B  : ProcedureReturn "PE32 (32-bit)"
    Case $20B  : ProcedureReturn "PE32+ (64-bit)"
    Default    : ProcedureReturn "Unknown (" + Hex(magic, #PB_Unicode) + ")"
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
  If timestamp <= 0
    ProcedureReturn "N/A"
  EndIf
  ProcedureReturn FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", timestamp)
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
#Gad_List       = 3
#Gad_SaveLog    = 4
#Gad_About      = 5
#Gad_Export      = 13
#Gad_Browse     = 1
#Gad_File       = 2
#Gad_SectionList = 10
#Gad_HexEditor   = 11
#StatusBar_Main = 0

Global NewList DataDirs.IMAGE_DATA_DIRECTORY()

;-----------------------------------------------------------
; Entropy calculation (Shannon Entropy)
;-----------------------------------------------------------

Procedure.f CalculateEntropy(*ptr, size.q)
  If size <= 0 Or *ptr = 0 : ProcedureReturn 0 : EndIf
  
  Protected Dim counts.q(255)
  Protected i.q, byte.a
  Protected entropy.f = 0
  Protected p.f
  
  For i = 0 To size - 1
    byte = PeekA(*ptr + i)
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
  ForEach Sections()
    If rva >= Sections()\VirtualAddress And rva < Sections()\VirtualAddress + Sections()\VirtualSize
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

;-----------------------------------------------------------
; Core: parse PE file and populate list
;-----------------------------------------------------------

Procedure ClearInfo()
  ClearGadgetItems(#Gad_List)
  ClearList(LogLines())
  ClearList(Sections())
  ClearList(DataDirs())
  If *FileBuffer
    FreeMemory(*FileBuffer)
    *FileBuffer = 0
  EndIf
  FileBufferSize = 0
EndProcedure

Global is64Bit.b = #False

Procedure AddInfo(key.s, value.s)
  AddGadgetItem(#Gad_List, -1, key + Chr(10) + value)
  AddElement(LogLines())
  LogLines() = key + " " + value
EndProcedure

Procedure ShowHeaders()
  ClearGadgetItems(#Gad_List)
  ForEach LogLines()
    Protected line.s = LogLines()
    Protected pos = FindString(line, " ")
    If pos
      AddGadgetItem(#Gad_List, -1, Left(line, pos-1) + Chr(10) + Mid(line, pos+1))
    EndIf
  Next
EndProcedure

Procedure ShowDataDirs()
  ClearGadgetItems(#Gad_List)
  Protected i = 0
  ForEach DataDirs()
    Protected name.s = DirectoryIndexToName(i)
    Protected info.s = "RVA: 0x" + Hex(DataDirs()\VirtualAddress) + " | Size: " + Str(DataDirs()\Size)
    
    If DataDirs()\VirtualAddress > 0
      Protected offset.q = RvaToOffset(DataDirs()\VirtualAddress)
      If offset <> -1
        info + " (File Offset: 0x" + Hex(offset) + ")"
      Else
        info + " (Offset: N/A - Outside Sections)"
      EndIf
    EndIf
    
    AddGadgetItem(#Gad_List, -1, name + Chr(10) + info)
    i + 1
  Next
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
  Protected pos, i, b.a
  
  If ext = "json"
    WriteStringN(fileID, "{")
    WriteStringN(fileID, "  " + #DQUOTE$ + "filename" + #DQUOTE$ + ": " + #DQUOTE$ + EscapeString(CurrentFile) + #DQUOTE$ + ",")
    WriteStringN(fileID, "  " + #DQUOTE$ + "headers" + #DQUOTE$ + ": [")
    ForEach LogLines()
      headerLine = LogLines()
      pos = FindString(headerLine, " ")
      If pos
        WriteString(fileID, "    {" + #DQUOTE$ + "key" + #DQUOTE$ + ": " + #DQUOTE$ + Left(headerLine, pos-1) + #DQUOTE$ + ", " + #DQUOTE$ + "value" + #DQUOTE$ + ": " + #DQUOTE$ + EscapeString(Mid(headerLine, pos+1)) + #DQUOTE$ + "}")
        If NextElement(LogLines()) : WriteStringN(fileID, ",") : Else : WriteStringN(fileID, "") : EndIf
        PushListPosition(LogLines())
      EndIf
    Next
    WriteStringN(fileID, "  ],")
    
    WriteStringN(fileID, "  " + #DQUOTE$ + "sections" + #DQUOTE$ + ": [")
    ForEach Sections()
      name = ""
      For i = 0 To 7
        b = PeekA(@Sections() + i)
        If b = 0 : Break : EndIf
        name + Chr(b)
      Next
      WriteString(fileID, "    {" + #DQUOTE$ + "name" + #DQUOTE$ + ": " + #DQUOTE$ + name + #DQUOTE$ + ", " + #DQUOTE$ + "raw_size" + #DQUOTE$ + ": " + Str(Sections()\SizeOfRawData) + "}")
      If NextElement(Sections()) : WriteStringN(fileID, ",") : Else : WriteStringN(fileID, "") : EndIf
      PushListPosition(Sections())
    Next
    WriteStringN(fileID, "  ]")
    WriteStringN(fileID, "}")
  Else ; CSV
    WriteStringN(fileID, "Key,Value")
    ForEach LogLines()
      csvLine = LogLines()
      pos = FindString(csvLine, " ")
      If pos
        WriteStringN(fileID, #DQUOTE$ + Left(csvLine, pos-1) + #DQUOTE$ + "," + #DQUOTE$ + Mid(csvLine, pos+1) + #DQUOTE$)
      EndIf
    Next
  EndIf
  
  CloseFile(fileID)
  SetStatus("Exported to: " + outFile)
EndProcedure

Procedure ParsePEFile(file.s)
  Protected fileID, fileSize.q
  Protected dosHeader.IMAGE_DOS_HEADER
  Protected peSignature.l
  Protected fileHeader.IMAGE_FILE_HEADER
  Protected optionalMagic.w
  Protected opt32.IMAGE_OPTIONAL_HEADER32
  Protected opt64.IMAGE_OPTIONAL_HEADER64
  Protected numDataDirs.l
  Protected offset.q
  Protected i
  
  ClearInfo()
  SetStatus("Opening file...")

  fileID = ReadFile(#PB_Any, file)
  If fileID = 0
    SetStatus("Failed to open file!")
    ProcedureReturn
  EndIf
  
  fileSize = Lof(fileID)
  If fileSize < SizeOf(IMAGE_DOS_HEADER)
    CloseFile(fileID)
    SetStatus("File too small to be a valid PE!")
    ProcedureReturn
  EndIf
  
  ;--- Read DOS header
  ReadData(fileID, @dosHeader, SizeOf(IMAGE_DOS_HEADER))
  
  If dosHeader\e_magic <> $5A4D ; "MZ"
    CloseFile(fileID)
    SetStatus("Not a valid MZ (DOS) header!")
    ProcedureReturn
  EndIf
  
  AddInfo("DOS_e_magic:", "MZ (0x" + Hex(dosHeader\e_magic) + ")")
  AddInfo("DOS_e_lfanew:", "0x" + Hex(dosHeader\e_lfanew))
  
  ; Check PE header offset
  If dosHeader\e_lfanew <= 0 Or dosHeader\e_lfanew > fileSize - 256
    CloseFile(fileID)
    SetStatus("Invalid e_lfanew, PE header out of range!")
    ProcedureReturn
  EndIf
  
    ;--- Seek to PE signature
  FileSeek(fileID, dosHeader\e_lfanew)
  peSignature = ReadLong(fileID)
  If peSignature <> $00004550 ; "PE\0\0"
    CloseFile(fileID)
    SetStatus("No valid PE signature found!")
    ProcedureReturn
  EndIf
  
  AddInfo("PE_Signature:", "PE (0x" + Hex(peSignature) + ")")
  
  ;--- Read file (COFF) header
  ReadData(fileID, @fileHeader, SizeOf(IMAGE_FILE_HEADER))
  
  AddInfo("Machine:", MachineToString(fileHeader\Machine))
  AddInfo("NumberOfSections:", Str(fileHeader\NumberOfSections))
  AddInfo("TimeDateStamp:", TimestampToString(fileHeader\TimeDateStamp) + " (" + Str(fileHeader\TimeDateStamp) + ")")
  AddInfo("SizeOfOptionalHeader:", Str(fileHeader\SizeOfOptionalHeader))
  AddInfo("Characteristics:", CharacteristicsToString(fileHeader\Characteristics) + " (0x" + Hex(fileHeader\Characteristics) + ")")
  
  ;--- Read Optional Header magic
  optionalMagic = ReadWord(fileID)
  AddInfo("OptionalHeader_Magic:", OptionalMagicToString(optionalMagic))
  
  ;--- Seek back 2 bytes so we can read full optional header struct
  offset = Loc(fileID) - 2
  FileSeek(fileID, offset)
  
  Select optionalMagic
    Case $10B  ; PE32
      is64Bit = #False
      If fileHeader\SizeOfOptionalHeader < SizeOf(IMAGE_OPTIONAL_HEADER32)
        SetStatus("Optional header smaller than expected for PE32!")
      Else
        ReadData(fileID, @opt32, SizeOf(IMAGE_OPTIONAL_HEADER32))
        AddInfo("AddressOfEntryPoint:", "0x" + Hex(opt32\AddressOfEntryPoint))
        AddInfo("ImageBase:", "0x" + Hex(opt32\ImageBase))
        AddInfo("SectionAlignment:", Str(opt32\SectionAlignment))
        AddInfo("FileAlignment:", Str(opt32\FileAlignment))
        AddInfo("SizeOfImage:", Str(opt32\SizeOfImage))
        AddInfo("SizeOfHeaders:", Str(opt32\SizeOfHeaders))
        AddInfo("Subsystem:", SubsystemToString(opt32\Subsystem) + " (0x" + Hex(opt32\Subsystem) + ")")
        AddInfo("NumberOfRvaAndSizes:", Str(opt32\NumberOfRvaAndSizes))
        numDataDirs = opt32\NumberOfRvaAndSizes
      EndIf
        
    Case $20B  ; PE32+
      is64Bit = #True
      If fileHeader\SizeOfOptionalHeader < SizeOf(IMAGE_OPTIONAL_HEADER64)
        SetStatus("Optional header smaller than expected for PE32+!")
      Else
        ReadData(fileID, @opt64, SizeOf(IMAGE_OPTIONAL_HEADER64))
        AddInfo("AddressOfEntryPoint:", "0x" + Hex(opt64\AddressOfEntryPoint))
        AddInfo("ImageBase:", "0x" + Hex(opt64\ImageBase))
        AddInfo("SectionAlignment:", Str(opt64\SectionAlignment))
        AddInfo("FileAlignment:", Str(opt64\FileAlignment))
        AddInfo("SizeOfImage:", Str(opt64\SizeOfImage))
        AddInfo("SizeOfHeaders:", Str(opt64\SizeOfHeaders))
        AddInfo("Subsystem:", SubsystemToString(opt64\Subsystem) + " (0x" + Hex(opt64\Subsystem) + ")")
        AddInfo("NumberOfRvaAndSizes:", Str(opt64\NumberOfRvaAndSizes))
        numDataDirs = opt64\NumberOfRvaAndSizes
      EndIf
      
    Default
      is64Bit = #False
      SetStatus("Unknown optional header magic; basic header info only.")
  EndSelect
  
  ;--- Read Data Directories
  If numDataDirs > 16 : numDataDirs = 16 : EndIf ; Sanity limit
  For i = 0 To numDataDirs - 1
    AddElement(DataDirs())
    ReadData(fileID, @DataDirs(), SizeOf(IMAGE_DATA_DIRECTORY))
  Next
  
  ;--- Read section headers
  FileSeek(fileID, dosHeader\e_lfanew + 4 + SizeOf(IMAGE_FILE_HEADER) + fileHeader\SizeOfOptionalHeader)

  For i = 0 To fileHeader\NumberOfSections - 1
    AddElement(Sections())
    ReadData(fileID, @Sections(), SizeOf(IMAGE_SECTION_HEADER))
  Next
  
  ;--- Add section summary to log (not the ListIcon yet)
  AddElement(LogLines())
  LogLines() = "----------------------------------------"
  AddElement(LogLines())
  LogLines() = "SECTIONS (" + Str(fileHeader\NumberOfSections) + "):"
  
  ForEach Sections()
    Protected secName.s = ""
    Protected j
    For j = 0 To 7
      Protected secByte.a = PeekA(@Sections() + j)
      If secByte = 0 : Break : EndIf
      secName + Chr(secByte)
    Next
    
    AddElement(LogLines())
    LogLines() = "Section: " + secName + 
                 " VA:0x" + Hex(Sections()\VirtualAddress) + 
                 " VS:" + Str(Sections()\VirtualSize) + 
                 " RS:" + Str(Sections()\SizeOfRawData) + 
                 " RP:0x" + Hex(Sections()\PointerToRawData) + 
                 " Chars:0x" + Hex(Sections()\Characteristics)
  Next
  
  ;--- Load entire file into memory for hex viewer & entropy
  FileSeek(fileID, 0)
  FileBufferSize = fileSize
  *FileBuffer = AllocateMemory(FileBufferSize)
  If *FileBuffer
    ReadData(fileID, *FileBuffer, FileBufferSize)
  EndIf
  
  CloseFile(fileID)
  SetStatus("Parsed successfully: " + GetFilePart(file))
EndProcedure

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseHandle_(hMutex)
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
  ClearGadgetItems(#Gad_List)
  
  If ListSize(Sections()) = 0
    SetStatus("No sections available.")
    ProcedureReturn
  EndIf
  
  ForEach Sections()
    Protected name.s = ""
    Protected i
    For i = 0 To 7
      Protected b.a = PeekA(@Sections() + i)
      If b = 0 : Break : EndIf
      name + Chr(b)
    Next
    
    ; Calculate Entropy
    Protected entropy.f = 0
    If *FileBuffer And Sections()\PointerToRawData > 0 And Sections()\SizeOfRawData > 0
      If Sections()\PointerToRawData + Sections()\SizeOfRawData <= FileBufferSize
        entropy = CalculateEntropy(*FileBuffer + Sections()\PointerToRawData, Sections()\SizeOfRawData)
      EndIf
    EndIf
    
    Protected entropyStr.s = StrF(entropy, 2)
    If entropy > 7.0 : entropyStr + " (Packed?)" : EndIf
    
    Protected info.s = "VirtAddr: 0x" + Hex(Sections()\VirtualAddress) +
                       " | VirtSize: " + Str(Sections()\VirtualSize) +
                       " | RawSize: " + Str(Sections()\SizeOfRawData) +
                       " | RawPtr: 0x" + Hex(Sections()\PointerToRawData) + #CRLF$ +
                       "Entropy: " + entropyStr + " | Chars: " + SectionCharacteristicsToString(Sections()\Characteristics)
    
    AddGadgetItem(#Gad_List, -1, name + Chr(10) + info)
  Next
  
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
  If offset >= size : offset = (size / 16) * 16 : EndIf
  
  endOffset = offset + chunkSize
  If endOffset > size : endOffset = size : EndIf
  
  SetStatus("Showing hex: 0x" + Hex(offset) + " to 0x" + Hex(endOffset) + " (Total: " + Str(size) + " bytes)")
  
  SendMessage_(GadgetID(#Gad_List), #WM_SETREDRAW, #False, 0) ; Disable redraw for speed
  
  While offset < endOffset
    hexPart = ""
    asciiPart = ""
    
    For i = 0 To bytesPerLine - 1
      If offset + i < size
        Protected byte.a = PeekA(*buffer + offset + i)
        hexPart + RSet(Hex(byte, #PB_Ascii), 2, "0") + " "
        
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
    
    line = RSet(Hex(offset, #PB_Ascii), 8, "0") + ": " + hexPart + " | " + asciiPart
    AddGadgetItem(#Gad_List, -1, line)
    
    offset + bytesPerLine
  Wend
  
  SendMessage_(GadgetID(#Gad_List), #WM_SETREDRAW, #True, 0) ; Re-enable redraw
  UpdateWindow_(GadgetID(#Gad_List))
EndProcedure

Procedure GoToAddress(hexAddr.s)
  Protected addr.q = Val("$" + hexAddr)
  Protected i, count, lineAddr.q
  
  If CurrentView <> 6 ; Hex View is now index 6
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
  ClearGadgetItems(#Gad_List)
  
  If ListSize(DataDirs()) < 2
    SetStatus("No data directories found.")
    ProcedureReturn
  EndIf
  
  SelectElement(DataDirs(), 1) ; Import Table is index 1
  Protected importRVA = DataDirs()\VirtualAddress
  Protected importSize = DataDirs()\Size
  
  If importRVA = 0 Or importSize = 0
    SetStatus("No Import Table found in this file.")
    ProcedureReturn
  EndIf
  
  Protected offset.q = RvaToOffset(importRVA)
  If offset = -1 Or *FileBuffer = 0
    SetStatus("Import Table offset out of range.")
    ProcedureReturn
  EndIf
  
  Protected *importDesc.My_IMAGE_IMPORT_DESCRIPTOR = *FileBuffer + offset
  Protected dllName.s, funcName.s
  Protected *thunk.Integer
  Protected importCount = 0
  
  SendMessage_(GadgetID(#Gad_List), #WM_SETREDRAW, #False, 0)
  
  While *importDesc\Name <> 0
    Protected nameOffset.q = RvaToOffset(*importDesc\Name)
    If nameOffset <> -1 And nameOffset < FileBufferSize
      dllName = PeekS(*FileBuffer + nameOffset, -1, #PB_Ascii)
      AddGadgetItem(#Gad_List, -1, dllName + Chr(10) + "--- DLL IMPORT ---")
      
      ; OriginalFirstThunk (ILT) is preferred, fallback to FirstThunk (IAT)
      Protected thunkRVA = *importDesc\OriginalFirstThunk
      If thunkRVA = 0 : thunkRVA = *importDesc\FirstThunk : EndIf
      
      Protected thunkOffset.q = RvaToOffset(thunkRVA)
      If thunkOffset <> -1
        *thunk = *FileBuffer + thunkOffset
        
        ; Check if it's 64-bit based on global flag
        Protected is64 = is64Bit
        
        While PeekI(*thunk) <> 0
          Protected val.q = PeekI(*thunk)
          
          ; Check for Import by Ordinal
          Protected ordinalMask.q = $80000000
          If is64 : ordinalMask = $8000000000000000 : EndIf
          
          If val & ordinalMask
            funcName = "Ordinal: " + Str(val & $FFFF)
          Else
            Protected nameDataOffset.q = RvaToOffset(val & $7FFFFFFF) ; Mask out bit 31
            If is64 : nameDataOffset = RvaToOffset(val & $7FFFFFFFFFFFFFFF) : EndIf
            
            If nameDataOffset <> -1 And nameDataOffset + 2 < FileBufferSize
              funcName = PeekS(*FileBuffer + nameDataOffset + 2, -1, #PB_Ascii)
            Else
              funcName = "<Unknown>"
            EndIf
          EndIf
          
          AddGadgetItem(#Gad_List, -1, "  " + funcName)
          *thunk + SizeOf(Integer)
        Wend
      EndIf
    EndIf
    
    *importDesc + SizeOf(My_IMAGE_IMPORT_DESCRIPTOR)
    importCount + 1
    If importCount > 500 : Break : EndIf ; Sanity break
  Wend
  
  SendMessage_(GadgetID(#Gad_List), #WM_SETREDRAW, #True, 0)
  UpdateWindow_(GadgetID(#Gad_List))
  SetStatus("Finished parsing Import Table.")
EndProcedure

Procedure ShowExports()
  ClearGadgetItems(#Gad_List)
  
  If ListSize(DataDirs()) = 0
    SetStatus("No data directories found.")
    ProcedureReturn
  EndIf
  
  SelectElement(DataDirs(), 0) ; Export Table is index 0
  Protected exportRVA = DataDirs()\VirtualAddress
  Protected exportSize = DataDirs()\Size
  
  If exportRVA = 0 Or exportSize = 0
    SetStatus("No Export Table found in this file.")
    ProcedureReturn
  EndIf
  
  Protected offset.q = RvaToOffset(exportRVA)
  If offset = -1 Or *FileBuffer = 0
    SetStatus("Export Table offset out of range.")
    ProcedureReturn
  EndIf
  
  Protected *exportDir.My_IMAGE_EXPORT_DIRECTORY = *FileBuffer + offset
  Protected i
  Protected nameOffset.q, funcOffset.q, ordOffset.q
  
  ; Get names and ordinals
  Protected *names.Long = 0
  Protected *ordinals.Word = 0
  Protected *functions.Long = 0
  
  If *exportDir\AddressOfNames > 0
    nameOffset = RvaToOffset(*exportDir\AddressOfNames)
    If nameOffset <> -1 : *names = *FileBuffer + nameOffset : EndIf
  EndIf
  
  If *exportDir\AddressOfNameOrdinals > 0
    ordOffset = RvaToOffset(*exportDir\AddressOfNameOrdinals)
    If ordOffset <> -1 : *ordinals = *FileBuffer + ordOffset : EndIf
  EndIf
  
  If *exportDir\AddressOfFunctions > 0
    funcOffset = RvaToOffset(*exportDir\AddressOfFunctions)
    If funcOffset <> -1 : *functions = *FileBuffer + funcOffset : EndIf
  EndIf
  
  SendMessage_(GadgetID(#Gad_List), #WM_SETREDRAW, #False, 0)
  
  If *names And *ordinals
    For i = 0 To *exportDir\NumberOfNames - 1
      Protected nRVA = PeekL(*names + (i * 4))
      Protected nOffset.q = RvaToOffset(nRVA)
      If nOffset <> -1
        Protected expName.s = PeekS(*FileBuffer + nOffset, -1, #PB_Ascii)
        Protected ordinal = PeekW(*ordinals + (i * 2))
        Protected funcRVA = 0
        If *functions
          funcRVA = PeekL(*functions + (ordinal * 4))
        EndIf
        AddGadgetItem(#Gad_List, -1, expName + Chr(10) + "Ordinal: " + Str(ordinal + *exportDir\Base) + " | RVA: 0x" + Hex(funcRVA))
      EndIf
    Next
  Else
    SetStatus("Export Table has no names.")
  EndIf
  
  SendMessage_(GadgetID(#Gad_List), #WM_SETREDRAW, #True, 0)
  UpdateWindow_(GadgetID(#Gad_List))
  SetStatus("Finished parsing Export Table (" + Str(*exportDir\NumberOfNames) + " names).")
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

Procedure ShowResources()
  ClearGadgetItems(#Gad_List)
  
  If ListSize(DataDirs()) < 3
    SetStatus("No data directories found.")
    ProcedureReturn
  EndIf
  
  SelectElement(DataDirs(), 2) ; Resource Table is index 2
  Protected resRVA = DataDirs()\VirtualAddress
  Protected resSize = DataDirs()\Size
  
  If resRVA = 0 Or resSize = 0
    SetStatus("No Resource Table found.")
    ProcedureReturn
  EndIf
  
  Protected offset.q = RvaToOffset(resRVA)
  If offset = -1 Or *FileBuffer = 0
    SetStatus("Resource Table offset out of range.")
    ProcedureReturn
  EndIf
  
  Protected *root.My_IMAGE_RESOURCE_DIRECTORY = *FileBuffer + offset
  Protected i, j, k
  
  SendMessage_(GadgetID(#Gad_List), #WM_SETREDRAW, #False, 0)
  
  ; Root level: Types
  Protected *typeEntry.My_IMAGE_RESOURCE_DIRECTORY_ENTRY = *root + SizeOf(My_IMAGE_RESOURCE_DIRECTORY)
  For i = 0 To *root\NumberOfNamedEntries + *root\NumberOfIdEntries - 1
    Protected typeName.s = ""
    ; Check high bit of Name (NameIsString)
    If *typeEntry\Name & $80000000
      ; String name...
    Else
      typeName = ResourceIdToString(*typeEntry\Id)
    EndIf
    
    ; Check high bit of Offset (DataIsDirectory)
    If *typeEntry\OffsetToDirectory & $80000000
      Protected *nameDir.My_IMAGE_RESOURCE_DIRECTORY = *FileBuffer + offset + (*typeEntry\OffsetToDirectory & $7FFFFFFF)
      Protected *nameEntry.My_IMAGE_RESOURCE_DIRECTORY_ENTRY = *nameDir + SizeOf(My_IMAGE_RESOURCE_DIRECTORY)
      
      For j = 0 To *nameDir\NumberOfNamedEntries + *nameDir\NumberOfIdEntries - 1
        ; Level 2: Names/IDs
        If *nameEntry\OffsetToDirectory & $80000000
          Protected *langDir.My_IMAGE_RESOURCE_DIRECTORY = *FileBuffer + offset + (*nameEntry\OffsetToDirectory & $7FFFFFFF)
          Protected *langEntry.My_IMAGE_RESOURCE_DIRECTORY_ENTRY = *langDir + SizeOf(My_IMAGE_RESOURCE_DIRECTORY)
          
          For k = 0 To *langDir\NumberOfNamedEntries + *langDir\NumberOfIdEntries - 1
            ; Level 3: Languages
            If Not (*langEntry\OffsetToDirectory & $80000000)
              Protected *dataEntry.My_IMAGE_RESOURCE_DATA_ENTRY = *FileBuffer + offset + *langEntry\OffsetToData
              AddGadgetItem(#Gad_List, -1, typeName + Chr(10) + "RVA: 0x" + Hex(*dataEntry\OffsetToData) + " | Size: " + Str(*dataEntry\Size))
            EndIf
            *langEntry + SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY)
          Next
        EndIf
        *nameEntry + SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY)
      Next
    EndIf
    *typeEntry + SizeOf(My_IMAGE_RESOURCE_DIRECTORY_ENTRY)
  Next
  
  SendMessage_(GadgetID(#Gad_List), #WM_SETREDRAW, #True, 0)
  UpdateWindow_(GadgetID(#Gad_List))
  SetStatus("Finished parsing Resource Table.")
EndProcedure

Procedure SwitchView(view.i)
  CurrentView = view
  
  If CurrentFile = ""
    SetStatus("No file loaded.")
    ProcedureReturn
  EndIf
  
  Select view
    Case 0  ; Headers
      ShowHeaders()
      
    Case 1  ; Sections
      ShowSections()
      
    Case 2  ; Data Dirs
      ShowDataDirs()
      
    Case 3  ; Imports
      ShowImports()
      
    Case 4  ; Exports
      ShowExports()
      
    Case 5  ; Resources
      ShowResources()
      
    Case 6  ; Hex Viewer
      ShowHexDump()
  EndSelect
EndProcedure

Procedure FilterList(pattern.s)
  Protected i, text.s
  pattern = LCase(pattern)
  
  ; We can't easily "hide" GadgetItems in a ListIcon, 
  ; so we refresh from the correct source based on CurrentView
  Select CurrentView
    Case 0 : ShowHeaders()
    Case 1 : ShowSections()
    Case 2 : ShowDataDirs()
    Case 3 : ShowImports()
    Case 4 : ShowExports()
    Case 5 : ShowResources()
    Case 6 : ShowHexDump()
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
    
    ; Tabs instead of buttons
    PanelGadget(#Gad_Tabs, 10, 44, 800, 415)
      AddGadgetItem(#Gad_Tabs, -1, "Headers")
      AddGadgetItem(#Gad_Tabs, -1, "Sections")
      AddGadgetItem(#Gad_Tabs, -1, "Data Dirs")
      AddGadgetItem(#Gad_Tabs, -1, "Imports")
      AddGadgetItem(#Gad_Tabs, -1, "Exports")
      AddGadgetItem(#Gad_Tabs, -1, "Resources")
      AddGadgetItem(#Gad_Tabs, -1, "Hex View")
    CloseGadgetList()

    ListIconGadget(#Gad_List, 15, 75, 790, 375, "Field", 220, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(#Gad_List, 1, "Value", 550)
    
    ; Re-parent the ListIcon inside the Panel if needed, but it's easier to keep it global
    ; and just refresh it when the tab changes. 
    ; PureBasic note: Gadgets added after CloseGadgetList() are relative to the Window.
    ; To make the ListIcon appear "over" the panel, we need to place it carefully.
    
    ; Actually, a better PureBasic pattern is to put the ListIcon INSIDE the panel, 
    ; but since we share one ListIcon for all views, we will place it on top or 
    ; handle the z-order. Alternatively, we move it to the window and adjust coordinates.
    
    ; Let's adjust coordinates to sit exactly inside the panel's client area
    ResizeGadget(#Gad_List, 15, 75, 790, 378)
    
    ; Add a search field and Go to Address for the hex view/headers
    TextGadget(#PB_Any, 10, 465, 45, 20, "Search:")
    Global Gad_Search = StringGadget(#PB_Any, 58, 462, 140, 22, "")
    
    TextGadget(#PB_Any, 215, 465, 75, 20, "Go to (Hex):")
    Global Gad_GoAddr = StringGadget(#PB_Any, 290, 462, 100, 22, "")
    Global Gad_GoBtn = ButtonGadget(#PB_Any, 400, 462, 40, 22, "Go")
    
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
    ParsePEFile(file)
    SetGadgetState(#Gad_Tabs, 0)
    CurrentView = 0  ; Reset to headers view
    ShowHeaders()
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
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 71
; FirstLine = 51
; Folding = ------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = EXE-PE_Viewer.ico
; Executable = ..\EXE-PE_Viewer.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,3
; VersionField1 = 1,0,0,3
; VersionField2 = ZoneSoft
; VersionField3 = EXE/PE-Viewer
; VersionField4 = 1.0.0.3
; VersionField5 = 1.0.0.3
; VersionField6 = View PE/EXE/DLL files and log info
; VersionField7 = EXE/PE-Viewer
; VersionField8 = EXE/PE-Viewer.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60