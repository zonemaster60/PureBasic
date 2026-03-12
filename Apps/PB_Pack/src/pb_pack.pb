; pbpack - simple PureBasic-based EXE packer (Windows x64)
; Usage: pbpack.exe [options] <input.exe> <output.exe>

EnableExplicit

#MAGIC = $5042504B ; 'PBPk'
#VERSION = 1

#PBP_FLAG_EXTRACT_LOCAL_ONLY = 1
#PBP_FLAG_EXTRACT_TEMP_ONLY  = 2

Structure PbPkHeader
  magic.l
  version.w
  flags.w
  packedSize.q
  originalSize.q
  entry_rva.i
  imageBase.q
  subsystem.w
  reserved.w
EndStructure

Structure PBP_IMAGE_DOS_HEADER
  e_magic.w
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
  e_lfanew.l
EndStructure

Structure PBP_IMAGE_FILE_HEADER
  Machine.w
  NumberOfSections.w
  TimeDateStamp.l
  PointerToSymbolTable.l
  NumberOfSymbols.l
  SizeOfOptionalHeader.w
  Characteristics.w
EndStructure

Structure PBP_IMAGE_DATA_DIRECTORY
  VirtualAddress.l
  Size.l
EndStructure

Structure PBP_IMAGE_OPTIONAL_HEADER64
  Magic.w
  MajorLinkerVersion.b
  MinorLinkerVersion.b
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
  DataDirectory.PBP_IMAGE_DATA_DIRECTORY[16]
EndStructure

Structure PBP_IMAGE_NT_HEADERS64
  Signature.l
  FileHeader.PBP_IMAGE_FILE_HEADER
  OptionalHeader.PBP_IMAGE_OPTIONAL_HEADER64
EndStructure

Structure PBP_IMAGE_SECTION_HEADER
  Name.a[8]
  VirtualSize.l
  VirtualAddress.l
  SizeOfRawData.l
  PointerToRawData.l
  PointerToRelocations.l
  PointerToLinenumbers.l
  NumberOfRelocations.w
  NumberOfLinenumbers.w
  Characteristics.l
EndStructure

Procedure Die(msg.s)
  If OpenConsole()
    PrintN(msg)
  EndIf
  End 1
EndProcedure

Procedure.s GetSelfDirectory()
  Protected self.s = Space(32768)
  GetModuleFileName_(0, @self, Len(self))
  self = Trim(self)
  If self = ""
    Die("Failed to resolve executable path")
  EndIf
  ProcedureReturn GetPathPart(self)
EndProcedure

Procedure.s FindExternalStubPath()
  Protected dir.s = GetSelfDirectory()
  Protected stubPath.s = dir + "stub.exe"
  If FileSize(stubPath) > 0
    ProcedureReturn stubPath
  EndIf

  stubPath = dir + "src\stub.exe"
  If FileSize(stubPath) > 0
    ProcedureReturn stubPath
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s NormalizePath(p.s)
  ProcedureReturn ReplaceString(p, "\\", "/")
EndProcedure

Procedure.i ReadAllBytes(file.s, *outSize.Quad)
  Protected h = ReadFile(#PB_Any, file)
  If h = 0 : Die("Failed to open: " + file) : EndIf
  Protected sz.q = Lof(h)
  Protected *mem = AllocateMemory(sz)
  If *mem = 0 : CloseFile(h) : Die("Out of memory") : EndIf
  If ReadData(h, *mem, sz) <> sz
    FreeMemory(*mem)
    CloseFile(h)
    Die("Failed reading: " + file)
  EndIf
  CloseFile(h)
  *outSize\q = sz
  ProcedureReturn *mem
EndProcedure

Procedure.i ParseInputExe(*mem, size.q, *hdr.PbPkHeader)
  If size < 4096 : Die("Input too small") : EndIf

  Protected *dos.PBP_IMAGE_DOS_HEADER = *mem
  If *dos\e_magic <> $5A4D : Die("Not MZ") : EndIf
  If *dos\e_lfanew < SizeOf(PBP_IMAGE_DOS_HEADER) Or *dos\e_lfanew > size - SizeOf(PBP_IMAGE_NT_HEADERS64)
    Die("Invalid PE header offset")
  EndIf

  Protected *nt.PBP_IMAGE_NT_HEADERS64 = *mem + *dos\e_lfanew
  If *nt\Signature <> $4550 : Die("Not PE") : EndIf
  If *nt\OptionalHeader\Magic <> $20B : Die("Not PE32+ (x64)") : EndIf
  If *nt\OptionalHeader\SizeOfHeaders > size
    Die("Headers extend past input size")
  EndIf

  *hdr\magic = #MAGIC
  *hdr\version = #VERSION
  *hdr\flags = 0
  *hdr\originalSize = size
  *hdr\entry_rva = *nt\OptionalHeader\AddressOfEntryPoint
  *hdr\imageBase = *nt\OptionalHeader\ImageBase
  *hdr\subsystem = *nt\OptionalHeader\Subsystem

  ProcedureReturn 1
EndProcedure

Procedure PrintHelp()
  PrintN("pbpack (PureBasic packer) - Windows x64")
  PrintN("Packages a PE32+ (x64) EXE by appending an LZMA-compressed overlay")
  PrintN("to a small runtime stub (stub.exe). The resulting output.exe is")
  PrintN("a self-contained executable that unpacks and starts the original.")
  PrintN("")
  PrintN("Default behavior:")
  PrintN("  - Prefer UPX if upx.exe is available")
  PrintN("  - Fall back to stub+overlay mode only when UPX is unavailable")
  PrintN("")
  PrintN("USAGE")
  PrintN("  pb_pack.exe [options] <input.exe> <output.exe>")
  PrintN("")
  PrintN("EXAMPLES")
  PrintN("  pb_pack.exe app.exe packed.exe")
  PrintN("  pb_pack.exe --stub-auto app.exe packed.exe")
  PrintN("  pb_pack.exe --stub app.exe packed.exe")
  PrintN("  pb_pack.exe --stub-local-only app.exe packed.exe")
  PrintN("  pb_pack.exe --no-verify app.exe packed.exe")
  PrintN("  pb_pack.exe --list packed.exe")
  PrintN("  pb_pack.exe --test packed.exe")
  PrintN("  pb_pack.exe --analyze app.exe")
  PrintN("  pb_pack.exe --upx app.exe packed.exe")
  PrintN("")
  PrintN("OPTIONS")
  PrintN("  --help")
  PrintN("      Show this help.")
  PrintN("")
  PrintN("  --list <file>")
  PrintN("      Print pbpack header information from <file>.")
  PrintN("      This expects <file> to end with a pbpack header.")
  PrintN("")
  PrintN("  --test <file>")
  PrintN("      Validate pbpack header + attempt to LZMA-decompress payload.")
  PrintN("      Useful to quickly check an output file is not corrupted.")
  PrintN("")
  PrintN("  --analyze <file>")
  PrintN("      Print PE section info, entropy, and simple packer markers.")
  PrintN("      This does not modify the file.")
  PrintN("")
  PrintN("  --no-verify")
  PrintN("      Skip the EntryRVA sanity check after PE parsing succeeds.")
  PrintN("      Use only if you know the input binary is valid.")
  PrintN("")
  PrintN("  --allow-larger")
  PrintN("      Allow outputs that are >= the original size.")
  PrintN("      Without this, pbpack will fall back to UPX or error.")
  PrintN("")
  PrintN("  --stub <input.exe> <output.exe>")
  PrintN("      Force built-in stub+overlay mode with auto extraction.")
  PrintN("      This mode extracts the payload and runs it as a normal process.")
  PrintN("      It is more compatible than the old in-memory loader, but less")
  PrintN("      self-contained and usually larger than UPX output.")
  PrintN("")
  PrintN("  --stub-auto")
  PrintN("      Alias for --stub.")
  PrintN("")
  PrintN("  --stub-local-only")
  PrintN("      Stub mode only: extract beside the packed EXE.")
  PrintN("      This helps programs that expect nearby files/resources.")
  PrintN("")
  PrintN("  --stub-temp-only")
  PrintN("      Stub mode only: extract only in the temp directory.")
  PrintN("      Use this when local extraction is not allowed.")
  PrintN("")
  PrintN("  --upx <input.exe> <output.exe>")
  PrintN("      Use UPX to compress the whole executable (UPX-like output size).")
  PrintN("      This produces a smaller file than the built-in stub+overlay mode.")
  PrintN("      Requires upx.exe (next to pbpack.exe or on PATH).")
  PrintN("")
  PrintN("  --upx-args <args>")
  PrintN("      Extra arguments passed to upx.exe.")
  PrintN("      Example: --upx-args -9 --lzma")
  PrintN("")
  PrintN("  --upx-inplace <file>")
  PrintN("      Compress <file> in-place using UPX.")
  PrintN("      Useful if you want to pack an already-built output.")
  PrintN("")
  PrintN("NOTES / LIMITATIONS")
  PrintN("  - Only PE32+ (x64) inputs are supported.")
  PrintN("  - Default packing now prefers UPX for compatibility/reliability.")
  PrintN("  - pb_pack prefers stub.exe next to pb_pack.exe (if present).")
  PrintN("  - In this source tree, it also accepts src\stub.exe.")
  PrintN("  - If no external stub is found, it falls back to an embedded stub.exe.")
  PrintN("  - The current runtime stub extracts the payload beside the packed EXE")
  PrintN("    or in the temp directory, launches it as a normal process, then")
  PrintN("    deletes the extracted file when possible.")
  PrintN("  - Programs that depend on their own executable path being stable on")
  PrintN("    disk may still need special handling.")
EndProcedure

Procedure.s DescribeStubExtractFlags(flags.w)
  If flags & #PBP_FLAG_EXTRACT_LOCAL_ONLY
    ProcedureReturn "local-only"
  EndIf
  If flags & #PBP_FLAG_EXTRACT_TEMP_ONLY
    ProcedureReturn "temp-only"
  EndIf
  ProcedureReturn "auto"
EndProcedure

Procedure.i LoadStubBytes(*outSize.Quad)
  ; Preferred: use external stub.exe from the working tree (easy to update).
  ; Fallback: use embedded stub.exe (single-exe distribution).

  Protected stubPath.s = FindExternalStubPath()

  If stubPath <> ""
    ProcedureReturn ReadAllBytes(stubPath, *outSize)
  EndIf

  Protected stubSize.q = ?PBP_STUB_END - ?PBP_STUB_START
  Protected *mem = AllocateMemory(stubSize)
  If *mem = 0 : Die("Out of memory (stub)") : EndIf
  CopyMemory(?PBP_STUB_START, *mem, stubSize)
  *outSize\q = stubSize
  ProcedureReturn *mem
EndProcedure

Procedure.s QuoteArg(a.s)
  ProcedureReturn Chr(34) + ReplaceString(a, Chr(34), "\" + Chr(34)) + Chr(34)
EndProcedure

Procedure.s FindUpxExe()
  ; 1) Prefer upx.exe next to pbpack.exe
  Protected dir.s = GetSelfDirectory()
  Protected local.s = dir + "upx.exe"
  If FileSize(local) > 0
    ProcedureReturn local
  EndIf

  ; 2) Try PATH lookup
  Protected buf.s = Space(32768)
  Protected n = SearchPath_(0, "upx.exe", 0, Len(buf) - 1, @buf, 0)
  If n > 0 And n < Len(buf)
    ProcedureReturn Left(buf, n)
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.i RunUpxInplace(upxExe.s, file.s, extraArgs.s)
  OpenConsole()
  If upxExe = "" : Die("upx.exe not found. Put upx.exe next to pbpack.exe or on PATH.") : EndIf
  If FileSize(file) <= 0 : Die("File not found: " + file) : EndIf

  ; Forward UPX output to our console
  Protected prog = RunProgram(upxExe, extraArgs + " " + QuoteArg(file), GetPathPart(upxExe), #PB_Program_Open | #PB_Program_Read | #PB_Program_Error)
  If prog = 0
    Die("Failed to launch upx.exe")
  EndIf

  While ProgramRunning(prog)
    If AvailableProgramOutput(prog)
      PrintN(ReadProgramString(prog))
    EndIf
    If AvailableProgramOutput(prog)
      PrintN(ReadProgramError(prog))
    EndIf
    Delay(5)
  Wend

  While AvailableProgramOutput(prog)
    PrintN(ReadProgramString(prog))
  Wend
  While AvailableProgramOutput(prog)
    PrintN(ReadProgramError(prog))
  Wend

  Protected exitCode = ProgramExitCode(prog)
  CloseProgram(prog)

  If exitCode <> 0
    Die("upx.exe failed with exit code: " + Str(exitCode))
  EndIf

  ProcedureReturn 1
EndProcedure

Procedure.i RunUpx(upxExe.s, inFile.s, outFile.s, extraArgs.s)
  If upxExe = "" : Die("upx.exe not found. Put upx.exe next to pbpack.exe or on PATH.") : EndIf
  If FileSize(inFile) <= 0 : Die("Input not found: " + inFile) : EndIf

  ; Copy input to requested output path, then let UPX compress in-place
  If CopyFile(inFile, outFile) = 0
    Die("Failed to create output: " + outFile)
  EndIf

  ProcedureReturn RunUpxInplace(upxExe, outFile, extraArgs)
EndProcedure

Procedure.i WritePacked(output.s, *stub, stubSize.q, *packed, packedSize.q, *hdr.PbPkHeader)
  If FileSize(output) > 0
    DeleteFile(output)
  EndIf

  Protected h = CreateFile(#PB_Any, output)
  If h = 0 : Die("Failed to create: " + output) : EndIf

  WriteData(h, *stub, stubSize)
  WriteData(h, *packed, packedSize)
  WriteData(h, *hdr, SizeOf(PbPkHeader))

  CloseFile(h)
  ProcedureReturn 1
EndProcedure

Procedure.i CmdList(file.s)
  Protected size.q
  Protected *mem = ReadAllBytes(file, @size)
  If size < SizeOf(PbPkHeader)
    FreeMemory(*mem)
    Die("Too small")
  EndIf
  Protected *hdr.PbPkHeader = *mem + size - SizeOf(PbPkHeader)
  If *hdr\magic <> #MAGIC
    FreeMemory(*mem)
    Die("Not a pbpack file")
  EndIf

  PrintN("File: " + file)
  PrintN("Version: " + Str(*hdr\version))
  PrintN("OriginalSize: " + Str(*hdr\originalSize))
  PrintN("PackedSize:   " + Str(*hdr\packedSize))
  PrintN("StubMode:     " + DescribeStubExtractFlags(*hdr\flags))
  PrintN("EntryRVA:     0x" + RSet(Hex(*hdr\entry_rva), 8, "0"))
  FreeMemory(*mem)
  ProcedureReturn 1
EndProcedure

Procedure.q CalcEntropyBitsPerByte(*buf, size.q)
  If size <= 0 : ProcedureReturn 0 : EndIf
  Protected Dim freq.l(255)
  Protected i
  For i = 0 To size - 1
    freq(PeekA(*buf + i) & $FF) = freq(PeekA(*buf + i) & $FF) + 1
  Next

  Protected ent.d = 0.0
  Protected p.d
  For i = 0 To 255
    If freq(i) > 0
      p = freq(i) / size
      ent = ent - p * (Log(p) / Log(2.0))
    EndIf
  Next

  ; encode as fixed-point Q24.8-ish (x1000) for easy printing
  ProcedureReturn Round(ent * 1000.0, #PB_Round_Nearest)
EndProcedure

Procedure.i HasMarker(*mem, size.q, marker.s)
  Protected m.s = marker
  Protected mlen = Len(m)
  If mlen = 0 Or size < mlen : ProcedureReturn #False : EndIf

  Protected i
  For i = 0 To size - mlen
    If CompareMemoryString(*mem + i, @m, #PB_Ascii, mlen) = 0
      ProcedureReturn #True
    EndIf
  Next

  ProcedureReturn #False
EndProcedure

Procedure.i AnalyzeExe(file.s)
  Protected size.q
  Protected *mem = ReadAllBytes(file, @size)
  If size < 4096
    FreeMemory(*mem)
    Die("Input too small")
  EndIf

  Protected *dos.PBP_IMAGE_DOS_HEADER = *mem
  If *dos\e_magic <> $5A4D
    FreeMemory(*mem)
    Die("Not MZ")
  EndIf
  If *dos\e_lfanew < SizeOf(PBP_IMAGE_DOS_HEADER) Or *dos\e_lfanew > size - SizeOf(PBP_IMAGE_NT_HEADERS64)
    FreeMemory(*mem)
    Die("Invalid PE header offset")
  EndIf

  Protected *nt.PBP_IMAGE_NT_HEADERS64 = *mem + *dos\e_lfanew
  If *nt\Signature <> $4550
    FreeMemory(*mem)
    Die("Not PE")
  EndIf
  If *nt\OptionalHeader\Magic <> $20B
    FreeMemory(*mem)
    Die("Not PE32+ (x64)")
  EndIf
  If *nt\OptionalHeader\SizeOfHeaders > size
    FreeMemory(*mem)
    Die("Headers extend past input size")
  EndIf

  PrintN("File: " + file)
  PrintN("Size: " + Str(size))
  PrintN("EntryRVA: 0x" + RSet(Hex(*nt\OptionalHeader\AddressOfEntryPoint), 8, "0"))
  PrintN("ImageBase: 0x" + Hex(*nt\OptionalHeader\ImageBase))
  PrintN("Sections: " + Str(*nt\FileHeader\NumberOfSections))

  Protected *sec.PBP_IMAGE_SECTION_HEADER = @*nt\OptionalHeader + *nt\FileHeader\SizeOfOptionalHeader
  Protected maxEnd.q = 0

  PrintN("")
  PrintN("Sections (Name RawSize RawPtr VirtSize VirtRVA Entropy):")
  Protected i
  For i = 0 To *nt\FileHeader\NumberOfSections - 1
    Protected name.s = PeekS(@*sec\Name, 8, #PB_Ascii)
    name = Trim(ReplaceString(name, Chr(0), ""))

    Protected rawEnd.q = *sec\PointerToRawData + *sec\SizeOfRawData
    If rawEnd > maxEnd : maxEnd = rawEnd : EndIf

    Protected entScaled.q = 0
    If *sec\SizeOfRawData > 0 And *sec\PointerToRawData > 0 And rawEnd <= size
      entScaled = CalcEntropyBitsPerByte(*mem + *sec\PointerToRawData, *sec\SizeOfRawData)
    EndIf

    PrintN("  " + LSet(name, 8, " ") +
           "  " + RSet(Str(*sec\SizeOfRawData), 8, " ") +
           "  " + RSet("0x" + Hex(*sec\PointerToRawData), 10, " ") +
           "  " + RSet(Str(*sec\VirtualSize), 8, " ") +
           "  " + RSet("0x" + Hex(*sec\VirtualAddress), 10, " ") +
           "  " + StrD(entScaled / 1000.0, 3))

    *sec + SizeOf(PBP_IMAGE_SECTION_HEADER)
  Next

  PrintN("")
  If maxEnd > 0 And maxEnd < size
    PrintN("Overlay: yes (" + Str(size - maxEnd) + " bytes)")
  Else
    PrintN("Overlay: no")
  EndIf

  ; Known packer markers (simple ASCII)
  Protected markers.s = "UPX!|.UPX0|.UPX1|MPRESS|.MPRESS1|.MPRESS2|ASPack|.aspack|.adata|FSG!|.fsg|petite|PECompact|Themida|VMProtect"
  Protected c = CountString(markers, "|") + 1
  Protected foundAny = #False

  PrintN("Markers:")
  For i = 1 To c
    Protected m.s = StringField(markers, i, "|")
    If HasMarker(*mem, size, m)
      PrintN("  found: " + m)
      foundAny = #True
    EndIf
  Next
  If foundAny = #False
    PrintN("  (none found)")
  EndIf

  ; Heuristic summary
  PrintN("")
  Protected likelyPacked = #False
  If maxEnd > 0 And size - maxEnd > 1024
    likelyPacked = #True
  EndIf
  If foundAny
    likelyPacked = #True
  EndIf

  If likelyPacked
    PrintN("Heuristic: LIKELY packed/contains overlay")
  Else
    PrintN("Heuristic: no obvious packing indicators")
  EndIf

  FreeMemory(*mem)
  ProcedureReturn 1
EndProcedure

Procedure.i CmdTest(file.s)
  Protected size.q
  Protected *mem = ReadAllBytes(file, @size)
  If size < SizeOf(PbPkHeader)
    FreeMemory(*mem)
    Die("Too small")
  EndIf

  Protected *hdr.PbPkHeader = *mem + size - SizeOf(PbPkHeader)
  If *hdr\magic <> #MAGIC
    FreeMemory(*mem)
    Die("Not a pbpack file")
  EndIf

  If *hdr\packedSize = 0 Or *hdr\originalSize = 0
    FreeMemory(*mem)
    Die("Corrupt header")
  EndIf

  Protected payloadPos.q = size - SizeOf(PbPkHeader) - *hdr\packedSize
  If payloadPos < 0
    FreeMemory(*mem)
    Die("Invalid payload offset")
  EndIf

  ; Try unpacking
  Protected *orig = AllocateMemory(*hdr\originalSize)
  If *orig = 0 : FreeMemory(*mem) : Die("OOM") : EndIf

   If UncompressMemory(*mem + payloadPos, *hdr\packedSize, *orig, *hdr\originalSize, #PB_PackerPlugin_Lzma) = 0
     FreeMemory(*orig)
     FreeMemory(*mem)
     Die("Uncompress failed")
   EndIf

  PrintN("OK: header + unpack")
  FreeMemory(*orig)
  FreeMemory(*mem)
  ProcedureReturn 1
EndProcedure

UseLZMAPacker()

Procedure Main()
  ; Ensure help output is visible even when launched from Explorer.
  ; If we had to create our own console, pause on help/errors.
  Protected consoleCreated = #False
  If OpenConsole()
    consoleCreated = #True
  EndIf

  Protected noVerify = #False
  Protected allowLarger = #False
  Protected forceStub = #False
  Protected stubLocalOnly = #False
  Protected stubTempOnly = #False
  Protected upxArgs.s = "-9 --lzma"

  ; No args: show help and exit.
  If ProgramParameter() = ""
    PrintHelp()
    If consoleCreated : Input() : EndIf
    End 0
  EndIf

  ; Read UPX args early so they work even if --upx-args appears after --upx
  Protected scan
  For scan = 0 To CountProgramParameters() - 1
    If ProgramParameter(scan) = "--upx-args"
      If scan + 1 >= CountProgramParameters()
        Die("--upx-args requires a value")
      EndIf
      upxArgs = ProgramParameter(scan + 1)
    EndIf
  Next

  ; Simple option handling
  Protected i, arg.s
  i = 0
  While i < CountProgramParameters()
    arg = ProgramParameter(i)

    Select arg
      Case "--help", "-h", "/?"
        PrintHelp()
        If consoleCreated : Input() : EndIf
        End 0

      Case "--upx"
        ; Usage: --upx <input> <output>
        If i + 2 >= CountProgramParameters() : Die("--upx requires <input.exe> <output.exe>") : EndIf
        Protected upxExe.s = FindUpxExe()
        RunUpx(upxExe, ProgramParameter(i + 1), ProgramParameter(i + 2), upxArgs)
        End 0

      Case "--upx-inplace"
        ; Usage: --upx-inplace <file>
        If i + 1 >= CountProgramParameters() : Die("--upx-inplace requires <file>") : EndIf
        Protected upxExe2.s = FindUpxExe()
        RunUpxInplace(upxExe2, ProgramParameter(i + 1), upxArgs)
        End 0

      Case "--no-verify"
        noVerify = #True
        i + 1
        Continue

      Case "--allow-larger"
        allowLarger = #True
        i + 1
        Continue

      Case "--stub", "--stub-auto"
        forceStub = #True
        i + 1
        Continue

      Case "--stub-local-only"
        forceStub = #True
        stubLocalOnly = #True
        i + 1
        Continue

      Case "--stub-temp-only"
        forceStub = #True
        stubTempOnly = #True
        i + 1
        Continue

      Case "--list"
        If i + 1 >= CountProgramParameters() : Die("--list requires file") : EndIf
        CmdList(ProgramParameter(i + 1))
        End 0

      Case "--test"
        If i + 1 >= CountProgramParameters() : Die("--test requires file") : EndIf
        CmdTest(ProgramParameter(i + 1))
        End 0

      Case "--analyze"
        If i + 1 >= CountProgramParameters() : Die("--analyze requires file") : EndIf
        AnalyzeExe(ProgramParameter(i + 1))
        End 0

      Case "--upx-args"
        ; parsed earlier; skip value
        i + 2
        Continue

      Default
        Break
    EndSelect
  Wend

  ; Remaining args: input output
  Protected remaining = CountProgramParameters() - i
  If remaining <> 2
    PrintHelp()
    Die("Expected <input.exe> <output.exe>")
  EndIf

  Protected inFile.s = ProgramParameter(i)
  Protected outFile.s = ProgramParameter(i + 1)

  If stubLocalOnly And stubTempOnly
    Die("Choose only one of --stub-local-only or --stub-temp-only")
  EndIf

  If forceStub = #False
    Protected upxExeDefault.s = FindUpxExe()
    If upxExeDefault <> ""
      If FileSize(outFile) > 0
        DeleteFile(outFile)
      EndIf

      RunUpx(upxExeDefault, inFile, outFile, upxArgs)
      PrintN("UPX packed: " + inFile + " -> " + outFile)
      PrintN("Original: " + Str(FileSize(inFile)) + " bytes")
      PrintN("Total:    " + Str(FileSize(outFile)) + " bytes")
      End 0
    EndIf

    PrintN("Note: upx.exe not found; using stub mode.")
  EndIf

  Protected inSize.q
  Protected *inMem = ReadAllBytes(inFile, @inSize)

  Protected hdr.PbPkHeader
  ParseInputExe(*inMem, inSize, @hdr)
  If stubLocalOnly
    hdr\flags | #PBP_FLAG_EXTRACT_LOCAL_ONLY
  ElseIf stubTempOnly
    hdr\flags | #PBP_FLAG_EXTRACT_TEMP_ONLY
  EndIf

  If noVerify = #False
    ; Minimal sanity checks (could add TLS detection later)
    If hdr\entry_rva = 0 : Die("EntryRVA is 0") : EndIf
  EndIf

  ; Compress input
  Protected maxPacked.q = inSize + (inSize / 16) + 1024
  Protected *packed = AllocateMemory(maxPacked)
  If *packed = 0 : Die("OOM packed") : EndIf

   Protected packedSize.q = CompressMemory(*inMem, inSize, *packed, maxPacked, #PB_PackerPlugin_Lzma)
   If packedSize = 0 : Die("CompressMemory failed") : EndIf

  hdr\packedSize = packedSize

  ; Load stub
  Protected stubSize.q
  Protected stubSource.s = "embedded stub.exe"
  Protected externalStubPath.s = FindExternalStubPath()
  If externalStubPath <> ""
    stubSource = externalStubPath
  EndIf
  Protected *stub = LoadStubBytes(@stubSize)

  ; If stub+overlay would be >= original, fall back to UPX (if available).
  Protected overlayTotal.q = stubSize + packedSize + SizeOf(PbPkHeader)
  If allowLarger = #False And overlayTotal >= inSize
    Protected upxExe3.s = FindUpxExe()
    If upxExe3 <> ""
      PrintN("Note: stub+overlay output (" + Str(overlayTotal) + " bytes) >= original (" + Str(inSize) + " bytes); falling back to UPX.")

      FreeMemory(*stub)
      FreeMemory(*packed)
      FreeMemory(*inMem)

      ; Avoid CopyFile failure if output already exists.
      If FileSize(outFile) > 0
        DeleteFile(outFile)
      EndIf

      RunUpx(upxExe3, inFile, outFile, upxArgs)
      PrintN("UPX packed: " + inFile + " -> " + outFile)
      PrintN("Original: " + Str(inSize) + " bytes")
      PrintN("Total:    " + Str(FileSize(outFile)) + " bytes")
      End 0
    Else
      FreeMemory(*stub)
      FreeMemory(*packed)
      FreeMemory(*inMem)
      Die("stub+overlay would be >= the original size (" + Str(overlayTotal) + " >= " + Str(inSize) + "). Put upx.exe next to pbpack.exe or pass --allow-larger.")
    EndIf
  EndIf

  ; Write output
  WritePacked(outFile, *stub, stubSize, *packed, packedSize, @hdr)

  PrintN("Packed: " + inFile + " -> " + outFile)
  PrintN("Original: " + Str(inSize) + " bytes")
  PrintN("StubSource: " + stubSource)
  PrintN("StubMode:  " + DescribeStubExtractFlags(hdr\flags))
  PrintN("Stub:     " + Str(stubSize) + " bytes")
  PrintN("Payload:  " + Str(packedSize) + " bytes (LZMA)")
  PrintN("Header:   " + Str(SizeOf(PbPkHeader)) + " bytes")
  PrintN("Total:    " + Str(stubSize + packedSize + SizeOf(PbPkHeader)) + " bytes")

  FreeMemory(*stub)
  FreeMemory(*packed)
  FreeMemory(*inMem)
EndProcedure
DataSection
  PBP_STUB_START:
  IncludeBinary "stub.exe"
  PBP_STUB_END:
EndDataSection

Main()


; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 209
; FirstLine = 187
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; SharedUCRT
; UseIcon = PB_Pack.ico
; Executable = ..\pb_pack.exe
; DisableDebugger