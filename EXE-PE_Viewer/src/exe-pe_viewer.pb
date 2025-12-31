;===========================================================
; Simple EXE/PE Viewer in PureBasic (Windows)
; - Reads DOS header, PE header, Optional header
; - Displays key fields in a GUI
;===========================================================

EnableExplicit

;-----------------------------------------------------------
; PE / COFF structures (simplified)
;-----------------------------------------------------------

#APP_NAME   = "EXE-PE_Viewer"
#EMAIL_NAME = "zonemaster60@gmail.com"
Global version.s = "v1.0.0.2"

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
#Gad_ViewHeaders = 7
#Gad_ViewSections = 8
#Gad_ViewHex     = 9
#Gad_SectionList = 10
#Gad_HexEditor   = 11
#StatusBar_Main = 0


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
  If *FileBuffer
    FreeMemory(*FileBuffer)
    *FileBuffer = 0
    FileBufferSize = 0
  EndIf
EndProcedure

Procedure AddInfo(key.s, value.s)
  AddGadgetItem(#Gad_List, -1, key + Chr(10) + value)
  AddElement(LogLines())
  LogLines() = key + " " + value
EndProcedure

Procedure SaveLog()
  If ListSize(LogLines()) = 0
    SetStatus("Nothing to save.")
    ProcedureReturn
  EndIf

  Protected outFile.s = SaveFileRequester("Save Log", CurrentFile + "_info.log", "Log Files (*.log)|*.log|All Files (*.*)|*.*", 0)
  If outFile = ""
    ProcedureReturn
  EndIf

  Protected fileID = CreateFile(#PB_Any, outFile)
  If fileID = 0
    SetStatus("Failed to create log file!")
    ProcedureReturn
  EndIf

  ; Header
  WriteStringN(fileID, #APP_NAME + " Log")
  WriteStringN(fileID, "Generated: " + FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss]", Date()))
  WriteStringN(fileID, "File: " + CurrentFile)
  WriteStringN(fileID, "----------------------------------------")

  ; Body
  ForEach LogLines()
    WriteStringN(fileID, LogLines())
  Next

  CloseFile(fileID)
  SetStatus("Log saved: " + outFile)
EndProcedure


Procedure ParsePEFile(file.s)
  Protected fileID, fileSize.q
  Protected dosHeader.IMAGE_DOS_HEADER
  Protected peSignature.l
  Protected fileHeader.IMAGE_FILE_HEADER
  Protected optionalMagic.w
  Protected opt32.IMAGE_OPTIONAL_HEADER32
  Protected opt64.IMAGE_OPTIONAL_HEADER64
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
  
  AddInfo("DOS e_magic:", "MZ (" + Hex(dosHeader\e_magic) + ")")
  AddInfo("DOS e_lfanew:", Str(dosHeader\e_lfanew))
  
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
  
  AddInfo("PE Signature:", "PE (0x" + Hex(peSignature) + ")")
  
  ;--- Read file (COFF) header
  ReadData(fileID, @fileHeader, SizeOf(IMAGE_FILE_HEADER))
  
  AddInfo("Machine:", MachineToString(fileHeader\Machine))
  AddInfo("NumberOfSections:", Str(fileHeader\NumberOfSections))
  AddInfo("TimeDateStamp:", TimestampToString(fileHeader\TimeDateStamp) + " (" + Str(fileHeader\TimeDateStamp) + ")")
  AddInfo("SizeOfOptionalHeader:", Str(fileHeader\SizeOfOptionalHeader))
  AddInfo("Characteristics:", CharacteristicsToString(fileHeader\Characteristics) + " (0x" + Hex(fileHeader\Characteristics) + ")")
  
  ;--- Read Optional Header magic
  optionalMagic = ReadWord(fileID)
  AddInfo("OptionalHeader Magic:", OptionalMagicToString(optionalMagic))
  
  ;--- Seek back 2 bytes so we can read full optional header struct
  offset = Loc(fileID) - 2
  FileSeek(fileID, offset)
  
  Select optionalMagic
    Case $10B  ; PE32
      If fileHeader\SizeOfOptionalHeader < SizeOf(IMAGE_OPTIONAL_HEADER32)
        CloseFile(fileID)
        SetStatus("Optional header smaller than expected for PE32!")
        ProcedureReturn
      EndIf
      
      ReadData(fileID, @opt32, SizeOf(IMAGE_OPTIONAL_HEADER32))
      AddInfo("AddressOfEntryPoint:", "0x" + Hex(opt32\AddressOfEntryPoint))
      AddInfo("ImageBase:", "0x" + Hex(opt32\ImageBase))
      AddInfo("SectionAlignment:", Str(opt32\SectionAlignment))
      AddInfo("FileAlignment:", Str(opt32\FileAlignment))
      AddInfo("SizeOfImage:", Str(opt32\SizeOfImage))
      AddInfo("SizeOfHeaders:", Str(opt32\SizeOfHeaders))
      AddInfo("Subsystem:", SubsystemToString(opt32\Subsystem) + " (0x" + Hex(opt32\Subsystem) + ")")
      AddInfo("NumberOfRvaAndSizes:", Str(opt32\NumberOfRvaAndSizes))
      
    Case $20B  ; PE32+
      If fileHeader\SizeOfOptionalHeader < SizeOf(IMAGE_OPTIONAL_HEADER64)
        CloseFile(fileID)
        SetStatus("Optional header smaller than expected for PE32+!")
        ProcedureReturn
      EndIf
      
      ReadData(fileID, @opt64, SizeOf(IMAGE_OPTIONAL_HEADER64))
      AddInfo("AddressOfEntryPoint:", "0x" + Hex(opt64\AddressOfEntryPoint))
      AddInfo("ImageBase:", "0x" + Hex(opt64\ImageBase))
      AddInfo("SectionAlignment:", Str(opt64\SectionAlignment))
      AddInfo("FileAlignment:", Str(opt64\FileAlignment))
      AddInfo("SizeOfImage:", Str(opt64\SizeOfImage))
      AddInfo("SizeOfHeaders:", Str(opt64\SizeOfHeaders))
      AddInfo("Subsystem:", SubsystemToString(opt64\Subsystem) + " (0x" + Hex(opt64\Subsystem) + ")")
      AddInfo("NumberOfRvaAndSizes:", Str(opt64\NumberOfRvaAndSizes))
      
    Default
      ; Unknown magic: just skip detailed optional header parsing
      SetStatus("Unknown optional header magic; basic header info only.")
  EndSelect
  
  ;--- Read section headers
  For i = 0 To fileHeader\NumberOfSections - 1
    AddElement(Sections())
    ReadData(fileID, @Sections(), SizeOf(IMAGE_SECTION_HEADER))
  Next
  
  ;--- Add section data to log
  AddElement(LogLines())
  LogLines() = "----------------------------------------"
  AddElement(LogLines())
  LogLines() = "SECTIONS (" + Str(fileHeader\NumberOfSections) + "):"
  AddElement(LogLines())
  LogLines() = "----------------------------------------"
  
  ForEach Sections()
    Protected secName.s = ""
    Protected j
    For j = 0 To 7
      Protected secByte.a = PeekA(@Sections() + j)
      If secByte = 0 : Break : EndIf
      secName + Chr(secByte)
    Next
    
    Protected secVirtSize.l = PeekL(@Sections() + 8)
    
    AddElement(LogLines())
    LogLines() = "Section: " + secName
    AddElement(LogLines())
    LogLines() = "  VirtualAddress: 0x" + Hex(Sections()\VirtualAddress)
    AddElement(LogLines())
    LogLines() = "  VirtualSize: " + Str(secVirtSize)
    AddElement(LogLines())
    LogLines() = "  SizeOfRawData: " + Str(Sections()\SizeOfRawData)
    AddElement(LogLines())
    LogLines() = "  PointerToRawData: 0x" + Hex(Sections()\PointerToRawData)
    AddElement(LogLines())
    LogLines() = "  Characteristics: " + SectionCharacteristicsToString(Sections()\Characteristics) + " (0x" + Hex(Sections()\Characteristics) + ")"
  Next
  
  ;--- Load entire file into memory for hex viewer
  FileSeek(fileID, 0)
  FileBufferSize = fileSize
  *FileBuffer = AllocateMemory(FileBufferSize)
  If *FileBuffer
    ReadData(fileID, *FileBuffer, FileBufferSize)
  EndIf
  
  CloseFile(fileID)
  SetStatus("Parsed successfully: " + file)
EndProcedure

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
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
    ; Section name is an 8-byte array at the start of the structure
    For i = 0 To 7
      Protected b.a = PeekA(@Sections() + i)
      If b = 0 : Break : EndIf
      name + Chr(b)
    Next
    
    ; Read VirtualSize directly (it's at offset 8 in the structure)
    Protected virtSize.l = PeekL(@Sections() + 8)
    
    Protected info.s = "VirtAddr: 0x" + Hex(Sections()\VirtualAddress) +
                       " | VirtSize: " + Str(virtSize) +
                       " | RawSize: " + Str(Sections()\SizeOfRawData) +
                       " | RawPtr: 0x" + Hex(Sections()\PointerToRawData) + #CRLF$ +
                       SectionCharacteristicsToString(Sections()\Characteristics)
    
    AddGadgetItem(#Gad_List, -1, name + Chr(10) + info)
  Next
  
  SetStatus("Showing " + Str(ListSize(Sections())) + " sections")
EndProcedure

Procedure ShowHexDump()
  Protected *buffer.Ascii
  Protected size.q, offset.q
  Protected line.s, hexPart.s, asciiPart.s
  Protected i, bytesPerLine = 16
  
  ClearGadgetItems(#Gad_List)
  
  If *FileBuffer = 0 Or FileBufferSize = 0
    SetStatus("No file loaded for hex view.")
    ProcedureReturn
  EndIf
  
  *buffer = *FileBuffer
  size = FileBufferSize
  
  ; Limit to first 64KB for performance
  If size > 65536
    size = 65536
    SetStatus("Showing first 64 KB of file (hex view)")
  Else
    SetStatus("Showing complete file (hex view)")
  EndIf
  
  offset = 0
  While offset < size
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
EndProcedure

Procedure SwitchView(view.i)
  CurrentView = view
  
  If CurrentFile = ""
    SetStatus("No file loaded.")
    ProcedureReturn
  EndIf
  
  Select view
    Case 0  ; Headers
      HideGadget(#Gad_List, #False)
      ParsePEFile(CurrentFile)  ; Reload to show headers
      
    Case 1  ; Sections
      HideGadget(#Gad_List, #False)
      ShowSections()
      
    Case 2  ; Hex Viewer
      HideGadget(#Gad_List, #False)
      ShowHexDump()
  EndSelect
EndProcedure

;-----------------------------------------------------------
; GUI creation
;-----------------------------------------------------------

Procedure CreateMainWindow()
  If OpenWindow(#Win_Main, 0, 0, 820, 520, #APP_NAME, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
    
    ButtonGadget(#Gad_Browse, 10, 10, 60, 24, "Browse")
    ButtonGadget(#Gad_SaveLog, 80, 10, 70, 24, "Save Log")
    ButtonGadget(#Gad_About, 160, 10, 60, 24, "About")
    ButtonGadget(#Gad_Exit, 230, 10, 60, 24, "Exit")
    StringGadget(#Gad_File, 300, 10, 510, 24, "", #PB_String_ReadOnly)
    
    ; View selector buttons
    ButtonGadget(#Gad_ViewHeaders, 10, 44, 80, 24, "Headers")
    ButtonGadget(#Gad_ViewSections, 100, 44, 80, 24, "Sections")
    ButtonGadget(#Gad_ViewHex, 190, 44, 80, 24, "Hex View")

    ListIconGadget(#Gad_List, 10, 78, 800, 400, "Field", 220, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(#Gad_List, 1, "Value", 550)
    
    CreateStatusBar(#StatusBar_Main, WindowID(#Win_Main))
    AddStatusBarField(#PB_Ignore)
    SetStatus("Ready.")
    
  EndIf
EndProcedure

;-----------------------------------------------------------
; File open dialog handler
;-----------------------------------------------------------

Procedure BrowseAndOpen()
  Protected file.s
  
  file = OpenFileRequester("Select an EXE or DLL", "", "PE Files (*.exe;*.dll)|*.exe;*.dll|All Files (*.*)|*.*", 0)
  If file <> ""
    CurrentFile = file
    SetGadgetText(#Gad_File, file)
    ParsePEFile(file)
    CurrentView = 0  ; Reset to headers view
  EndIf
EndProcedure

;-----------------------------------------------------------
; Main
;-----------------------------------------------------------

CreateMainWindow()

Define Event, Gadget

Repeat
  Event = WaitWindowEvent()
  
  Select Event
    Case #PB_Event_Gadget
      Gadget = EventGadget()
      
      Select Gadget
        Case #Gad_Browse
          BrowseAndOpen()
          
        Case #Gad_ViewHeaders
          SwitchView(0)
          
        Case #Gad_ViewSections
          SwitchView(1)
          
        Case #Gad_ViewHex
          SwitchView(2)
          
        Case #Gad_SaveLog
          SaveLog()
          
        Case #Gad_About
          ShowAbout()
          
        Case #Gad_Exit
          Exit()
      EndSelect
      
    Case #PB_Event_CloseWindow
      Exit()
  EndSelect
ForEver
; IDE Options = PureBasic 6.30 beta 6 (Windows - x64)
; CursorPosition = 510
; FirstLine = 495
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = exe-pe_viewer.ico
; Executable = ..\EXE-PE_Viewer.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = EXE/PE-Viewer
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = View PE/EXE/DLL files and log info
; VersionField7 = EXE/PE-Viewer
; VersionField8 = EXE/PE-Viewer.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60