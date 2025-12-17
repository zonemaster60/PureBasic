;===========================================================
; Simple EXE/PE Viewer in PureBasic (Windows)
; - Reads DOS header, PE header, Optional header
; - Displays key fields in a GUI
;===========================================================

EnableExplicit

;-----------------------------------------------------------
; PE / COFF structures (simplified)
;-----------------------------------------------------------

Structure IMAGE_DOS_HEADER2
  e_magic.w      ; Magic number "MZ"
  e_cblp.w
  e_cp.w
  e_crlc.w
  e_cparhdr.w
  e_minalloc.w
  e_maxalloc.w
  e_ss.w
  e_sp.w
  e_csum.w
  e_ip.w
  e_cs.w
  e_lfarlc.w
  e_ovno.w
  e_res.w[4]
  e_oemid.w
  e_oeminfo.w
  e_res2.w[10]
  e_lfanew.l     ; File offset to PE header
EndStructure

Structure IMAGE_FILE_HEADER2
  Machine.w
  NumberOfSections.w
  TimeDateStamp.l
  PointerToSymbolTable.l
  NumberOfSymbols.l
  SizeOfOptionalHeader.w
  Characteristics.w
EndStructure

Structure IMAGE_OPTIONAL_HEADER322
  Magic.w
  MajorLinkerVersion.a
  MinorLinkerVersion.a
  SizeOfCode.l
  SizeOfInitializedData.l
  SizeOfUninitializedData.l
  AddressOfEntryPoint.l
  BaseOfCode.l
  BaseOfData.l
  ImageBase.l
  SectionAlignment.l
  FileAlignment.l
  MajorOperatingSystemVersion.w
  MinorOperatingSystemVersion.w
  MajorImageVersion.w
  MinorImageVersion.w
  MajorSubsystemVersion.w
  MinorSubsystemVersion.w
  Win32VersionValue.l
  SizeOfImage.l
  SizeOfHeaders.l
  CheckSum.l
  Subsystem.w
  DllCharacteristics.w
  SizeOfStackReserve.l
  SizeOfStackCommit.l
  SizeOfHeapReserve.l
  SizeOfHeapCommit.l
  LoaderFlags.l
  NumberOfRvaAndSizes.l
  ; DataDirectory entries follow, but we don't need them here
EndStructure

Structure IMAGE_OPTIONAL_HEADER642
  Magic.w
  MajorLinkerVersion.a
  MinorLinkerVersion.a
  SizeOfCode.l
  SizeOfInitializedData.l
  SizeOfUninitializedData.l
  AddressOfEntryPoint.l
  BaseOfCode.l
  ImageBase.q
  SectionAlignment.l
  FileAlignment.l
  MajorOperatingSystemVersion.w
  MinorOperatingSystemVersion.w
  MajorImageVersion.w
  MinorImageVersion.w
  MajorSubsystemVersion.w
  MinorSubsystemVersion.w
  Win32VersionValue.l
  SizeOfImage.l
  SizeOfHeaders.l
  CheckSum.l
  Subsystem.w
  DllCharacteristics.w
  SizeOfStackReserve.q
  SizeOfStackCommit.q
  SizeOfHeapReserve.q
  SizeOfHeapCommit.q
  LoaderFlags.l
  NumberOfRvaAndSizes.l
  ; DataDirectory entries follow, but we don't need them here
EndStructure

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
#StatusBar_Main = 0

#APP_NAME   = "EXE-PE_Viewer"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global CurrentFile.s
Global NewList LogLines.s()
Global AppPath.s        = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

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
  AddInfo("TimeDateStamp (raw):", Str(fileHeader\TimeDateStamp))
  AddInfo("SizeOfOptionalHeader:", Str(fileHeader\SizeOfOptionalHeader))
  AddInfo("Characteristics:", "0x" + Hex(fileHeader\Characteristics))
  
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
      AddInfo("Subsystem:", "0x" + Hex(opt32\Subsystem))
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
      AddInfo("Subsystem:", "0x" + Hex(opt64\Subsystem))
      AddInfo("NumberOfRvaAndSizes:", Str(opt64\NumberOfRvaAndSizes))
      
    Default
      ; Unknown magic: just skip detailed optional header parsing
      SetStatus("Unknown optional header magic; basic header info only.")
  EndSelect
  
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
  msg = #APP_NAME + " - v1.0.0.0" + #CRLF$ +
        "For viewing info in .EXE and DLL files." + #CRLF$ +
        "Contact: David Scouten (" + #EMAIL_NAME + ")" + #CRLF$ +
        "Website: https://github.com/zonemaster60"

  MessageRequester("About " + #APP_NAME, msg, #PB_MessageRequester_Info)
EndProcedure

;-----------------------------------------------------------
; GUI creation
;-----------------------------------------------------------

; Check for running instance
If FindWindow_(0, #APP_NAME)
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  End
EndIf  

Procedure CreateMainWindow()
  If OpenWindow(#Win_Main, 0, 0, 720, 480, #APP_NAME, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    
    ButtonGadget(#Gad_Browse, 10, 10, 60, 24, "Browse")
    ButtonGadget(#Gad_SaveLog, 80, 10, 70, 24, "Save Log")
    ButtonGadget(#Gad_About, 160, 10, 60, 24, "About")
    ButtonGadget(#Gad_Exit, 230, 10, 60, 24, "Exit")
    StringGadget(#Gad_File, 300, 10, 410, 24, "", #PB_String_ReadOnly)

    ListIconGadget(#Gad_List, 10, 44, 700, 400, "Field", 220, #PB_ListIcon_AlwaysShowSelection | #PB_ListIcon_FullRowSelect)
    AddGadgetColumn(#Gad_List, 1, "Value", 450)
    
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
; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 340
; FirstLine = 319
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; DllProtection
; UseIcon = exe-pe_viewer.ico
; Executable = ..\EXE-PE_Viewer.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = EXE/PE-Viwer
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = View PE/EXE/DLL files
; VersionField7 = EXE/PE-Viewer
; VersionField8 = EXE/PE-Viewer.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster@yahoo.com
; VersionField14 = https://github.com/zonemaster60