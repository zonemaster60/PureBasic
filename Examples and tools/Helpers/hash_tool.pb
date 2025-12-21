; hash_tool.pb
; PureBasic v6.30 (beta 5)
; Console tool: compute file hashes and write CSV/TXT.
;
; Usage:
;  hash_tool.exe <input_file> [--out <output_file>] [--format csv|txt]
;
; Examples:
;  hash_tool.exe "C:\path\app.exe"
;  hash_tool.exe "C:\path\app.exe" --format txt
;  hash_tool.exe "C:\path\app.exe" --out "C:\tmp\hashes.csv" --format csv

EnableExplicit

#DefaultChunkSize = 1024 * 1024

Structure HashAlgo
  name.s
  plugin.i
  bits.i
  fp.i
EndStructure

Procedure Pause()
  PrintN("")
  PrintN("(Press ENTER to exit...)")
  Input()
EndProcedure  

Procedure.s QuoteCSV(Field.s)
  ; Minimal CSV escaping
  If FindString(Field, "\", 1) Or FindString(Field, ",", 1) Or FindString(Field, #CRLF$, 1)
    Field = ReplaceString(Field, "\", "\")
    ProcedureReturn "\" + Field + "\"
  EndIf
  ProcedureReturn Field
EndProcedure

Procedure.s GetFileName(FilePath.s)
  ProcedureReturn GetFilePart(FilePath)
EndProcedure

Procedure.s DefaultOutputPath(InputPath.s, Format.s)
  Protected suffix.s
  If LCase(Format) = "txt"
    suffix = ".txt"
  Else
    suffix = ".csv"
  EndIf
  ProcedureReturn InputPath + suffix
EndProcedure

Procedure.i WriteCSV(OutputPath.s, InputPath.s, FileSize.q, Map Hashes.s(), Array Keys.s(1))
  Protected fileId.i
  Protected idx.i
  Protected key.s

  fileId = CreateFile(#PB_Any, OutputPath)
  If fileId = 0
    PrintN("ERROR: Unable to write output: " + OutputPath)
    ProcedureReturn #False
  EndIf

  WriteStringN(fileId, "input_file: " + QuoteCSV(InputPath))
  WriteStringN(fileId, "file_size_bytes: " + Str(FileSize))
  WriteStringN(fileId, "")
  WriteStringN(fileId, "algorithm: hash_hex")

  For idx = 0 To ArraySize(Keys())
    key = Keys(idx)
    If FindMapElement(Hashes(), key)
      WriteStringN(fileId, QuoteCSV(key) + ": " + QuoteCSV(Hashes()))
    EndIf
  Next

  CloseFile(fileId)
  ProcedureReturn #True
EndProcedure

Procedure.i WriteTXT(OutputPath.s, InputPath.s, FileSize.q, Map Hashes.s(), Array Keys.s(1))
  Protected fileId.i
  Protected idx.i
  Protected key.s

  fileId = CreateFile(#PB_Any, OutputPath)
  If fileId = 0
    PrintN("ERROR: Unable to write output: " + OutputPath)
    Pause()
    ProcedureReturn #False
  EndIf

  WriteStringN(fileId, "Input: " + InputPath)
  WriteStringN(fileId, "Size: " + Str(FileSize) + " bytes")
  WriteStringN(fileId, "")

  For idx = 0 To ArraySize(Keys())
    key = Keys(idx)
    If FindMapElement(Hashes(), key)
      WriteStringN(fileId, key + ": " + Hashes())
    EndIf
  Next

  CloseFile(fileId)
  ProcedureReturn #True
EndProcedure

Procedure.i ComputeHashesStreaming(FilePath.s, ChunkSize.i, List Algos.HashAlgo(), Map Hashes.s())
  Protected fileId.i
  Protected *buffer
  Protected bytesRead.i

  If FileSize(FilePath) < 0
    ProcedureReturn #False
  EndIf

  If ChunkSize <= 0
    ChunkSize = #DefaultChunkSize
  EndIf

  ; Start all fingerprints first (so we can stream the file once).
  ForEach Algos()
    If Algos()\bits > 0
      Algos()\fp = StartFingerprint(#PB_Any, Algos()\plugin, Algos()\bits)
    Else
      Algos()\fp = StartFingerprint(#PB_Any, Algos()\plugin)
    EndIf

    ; If it fails to start, keep fp=0 and skip later.
    If Algos()\fp = 0
      Continue
    EndIf
  Next

  fileId = ReadFile(#PB_Any, FilePath)
  If fileId = 0
    ; Ensure we free any started fingerprints.
    ForEach Algos()
      If Algos()\fp
        FinishFingerprint(Algos()\fp)
        Algos()\fp = 0
      EndIf
    Next
    ProcedureReturn #False
  EndIf

  *buffer = AllocateMemory(ChunkSize)
  If *buffer = 0
    CloseFile(fileId)
    ForEach Algos()
      If Algos()\fp
        FinishFingerprint(Algos()\fp)
        Algos()\fp = 0
      EndIf
    Next
    ProcedureReturn #False
  EndIf

  While Eof(fileId) = 0
    bytesRead = ReadData(fileId, *buffer, ChunkSize)
    If bytesRead <= 0
      Break
    EndIf

    ForEach Algos()
      If Algos()\fp
        AddFingerprintBuffer(Algos()\fp, *buffer, bytesRead)
      EndIf
    Next
  Wend

  FreeMemory(*buffer)
  CloseFile(fileId)

  ; Finish and collect results.
  ForEach Algos()
    If Algos()\fp
      Hashes(Algos()\name) = LCase(FinishFingerprint(Algos()\fp))
      Algos()\fp = 0
    EndIf
  Next

  ProcedureReturn #True
EndProcedure

Procedure AddAlgo(List Algos.HashAlgo(), Name.s, Plugin.i, Bits.i = 0)
  AddElement(Algos())
  Algos()\name = Name
  Algos()\plugin = Plugin
  Algos()\bits = Bits
EndProcedure

Procedure BuildAlgorithmList(List Algos.HashAlgo())
  ; Important: these plugins must be registered before use.
  UseCRC32Fingerprint()
  UseMD5Fingerprint()
  UseSHA1Fingerprint()
  UseSHA2Fingerprint()

  ; PureBasic's SHA3 plugin may not be present in older builds.
  CompilerIf Defined(UseSHA3Fingerprint, #PB_Procedure)
    UseSHA3Fingerprint()
  CompilerEndIf

  ; Base algorithms.
  AddAlgo(Algos(), "CRC32", #PB_Cipher_CRC32)
  AddAlgo(Algos(), "MD5", #PB_Cipher_MD5)
  AddAlgo(Algos(), "SHA1", #PB_Cipher_SHA1)

  ; SHA-2 variants (supported via Bits parameter).
  AddAlgo(Algos(), "SHA2-224", #PB_Cipher_SHA2, 224)
  AddAlgo(Algos(), "SHA2-256", #PB_Cipher_SHA2, 256)
  AddAlgo(Algos(), "SHA2-384", #PB_Cipher_SHA2, 384)
  AddAlgo(Algos(), "SHA2-512", #PB_Cipher_SHA2, 512)

  ; SHA-3 variants (only if plugin + constant exist).
  AddAlgo(Algos(), "SHA3-224", #PB_Cipher_SHA3, 224)
  AddAlgo(Algos(), "SHA3-256", #PB_Cipher_SHA3, 256)
  AddAlgo(Algos(), "SHA3-384", #PB_Cipher_SHA3, 384)
  AddAlgo(Algos(), "SHA3-512", #PB_Cipher_SHA3, 512)
EndProcedure

Procedure PrintUsage(ExeName.s)
  PrintN("Usage:")
  PrintN(" " + ExeName + " <input_file> [--out <output_file>] [--format csv|txt] [--chunk-size <bytes>]")
  PrintN("")
  PrintN("Notes:")
  PrintN(" - Hashes use PureBasic Cipher fingerprint plugins.")
  PrintN(" - Uses streaming hashing (chunked reads).")
  Pause()
EndProcedure

; -----------------
; Main
; -----------------

If OpenConsole() = 0
  End 1
EndIf

If CountProgramParameters() < 1
  PrintUsage(GetFileName(ProgramFilename()))
  End 1
EndIf

Define inputPath.s = ProgramParameter(0)
Define outputPath.s = ""
Define format.s = "csv"
Define chunkSize.i = #DefaultChunkSize

Define i.i
For i = 1 To CountProgramParameters() - 1
  Select LCase(ProgramParameter(i))
    Case "--out"
      If i + 1 <= CountProgramParameters() - 1
        i + 1
        outputPath = ProgramParameter(i)
      EndIf
    Case "--format"
      If i + 1 <= CountProgramParameters() - 1
        i + 1
        format = LCase(ProgramParameter(i))
      EndIf
    Case "--chunk-size"
      If i + 1 <= CountProgramParameters() - 1
        i + 1
        chunkSize = Val(ProgramParameter(i))
      EndIf
  EndSelect
Next

If format <> "csv" And format <> "txt"
  PrintN("ERROR: Unsupported format: " + format)
  Pause()
  End 1
EndIf

If outputPath = ""
  outputPath = DefaultOutputPath(inputPath, format)
EndIf

Define size.q = FileSize(inputPath)
If size < 0
  PrintN("ERROR: Unable to read input file: " + inputPath)
  Pause()
  End 1
EndIf

NewList algos.HashAlgo()
BuildAlgorithmList(algos())

NewMap hashes.s()
If ComputeHashesStreaming(inputPath, chunkSize, algos(), hashes()) = #False
  PrintN("ERROR: Hashing failed for input file: " + inputPath)
  Pause()
  End 1
EndIf

; Stable output ordering: copy keys to array and sort
Define count.i = MapSize(hashes())
If count <= 0
  PrintN("ERROR: No hashes generated (unsupported algorithms?)")
  Pause()
  End 1
EndIf

Dim keys.s(count - 1)
Define idx.i = 0
ForEach hashes()
  keys(idx) = MapKey(hashes())
  idx + 1
Next
SortArray(keys(), #PB_Sort_Ascending)

Define ok.i
If format = "csv"
  ok = WriteCSV(outputPath, inputPath, size, hashes(), keys())
Else
  ok = WriteTXT(outputPath, inputPath, size, hashes(), keys())
EndIf

If ok = #False
  End 1
EndIf

PrintN("Input:  " + inputPath)
PrintN("Output: " + outputPath)
PrintN("Hashes: " + Str(MapSize(hashes())))

Pause()
End 0

; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 240
; FirstLine = 228
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = hast_tool.ico
; Executable = hash_tool.exe