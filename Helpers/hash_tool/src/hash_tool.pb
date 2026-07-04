; hash_tool.pb
; PureBasic v6.40
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

#APP_NAME = "Hash_Tool"

Global version.s = "v1.0.0.4"

#DefaultChunkSize = 1024 * 1024
#MinChunkSize = 4096
#MaxChunkSize = 64 * 1024 * 1024

Structure HashAlgo
  name.s
  plugin.i
  bits.i
  fp.i
EndStructure

Procedure CleanupAndExit(ExitCode.i = 0)
  End ExitCode
EndProcedure

Procedure PrintError(Message.s)
  PrintN("ERROR: " + Message)
EndProcedure

Procedure PrintWarning(Message.s, Silent.i = #False)
  If Not Silent
    PrintN("WARNING: " + Message)
  EndIf
EndProcedure

Procedure.s QuoteCSV(Field.s)
  ; CSV escaping: escape double quotes by doubling them and wrap in quotes
  Field = ReplaceString(Field, #DQUOTE$, #DQUOTE$ + #DQUOTE$)
  ProcedureReturn #DQUOTE$ + Field + #DQUOTE$
EndProcedure

Procedure.s GetFileName(FilePath.s)
  ProcedureReturn GetFilePart(FilePath)
EndProcedure

Procedure.i IsAbsolutePath(FilePath.s)
  If Mid(FilePath, 2, 2) = ":\" Or Left(FilePath, 2) = "\\"
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.s NormalizePath(FilePath.s)
  Protected path.s = FilePath

  If path = ""
    ProcedureReturn path
  EndIf

  path = ReplaceString(path, "/", "\")

  While Left(path, 2) = ".\"
    path = Mid(path, 3)
  Wend

  If IsAbsolutePath(path)
    ProcedureReturn path
  EndIf

  ProcedureReturn GetCurrentDirectory() + path
EndProcedure

Procedure.s HashKey(FilePath.s, AlgoName.s)
  ProcedureReturn FilePath + Chr(31) + AlgoName
EndProcedure

Procedure.s JoinPath(Dir.s, FileName.s)
  If Dir = "" Or Dir = "."
    ProcedureReturn FileName
  EndIf

  If Right(Dir, 1) = "\\" Or Right(Dir, 1) = "/"
    ProcedureReturn Dir + FileName
  EndIf

  ProcedureReturn Dir + "\\" + FileName
EndProcedure

Procedure ResetFingerprints(List Algos.HashAlgo())
  ForEach Algos()
    If Algos()\fp
      FinishFingerprint(Algos()\fp)
      Algos()\fp = 0
    EndIf
  Next
EndProcedure

Procedure AddUniqueFile(List FilesToHash.s(), Map SeenFiles.i(), FilePath.s)
  Protected normalizedPath.s = NormalizePath(FilePath)
  Protected key.s = LCase(normalizedPath)

  If FindMapElement(SeenFiles(), key) = 0
    SeenFiles(key) = #True
    AddElement(FilesToHash())
    FilesToHash() = normalizedPath
  EndIf
EndProcedure

Procedure.s DefaultOutputPath(List Files.s(), Format.s)
  Protected suffix.s
  Protected firstFile.s
  Protected outputBase.s
  
  If FirstElement(Files())
    firstFile = Files()
  Else
    firstFile = "hashes"
  EndIf
  
  If LCase(Format) = "txt"
    suffix = ".txt"
  Else
    suffix = ".csv"
  EndIf

  outputBase = GetPathPart(firstFile) + GetFilePart(firstFile, #PB_FileSystem_NoExtension)
  If outputBase = ""
    outputBase = "hashes"
  EndIf

  ProcedureReturn outputBase + ".hashes" + suffix
EndProcedure

Procedure.i WriteCSV(OutputPath.s, List FilesToHash.s(), List Algos.HashAlgo(), Map AllHashes.s())
  Protected fileId.i
  Protected header.s
  Protected values.s
  Protected hashKey.s

  fileId = CreateFile(#PB_Any, OutputPath)
  If fileId = 0
    PrintError("Unable to write output: " + OutputPath)
    ProcedureReturn #False
  EndIf

  ; Header
  header = "File_Path,Size_Bytes"
  ForEach Algos()
    header + "," + QuoteCSV(Algos()\name)
  Next
  WriteStringN(fileId, header)

  ; Data rows
  ForEach FilesToHash()
    values = QuoteCSV(FilesToHash()) + "," + Str(FileSize(FilesToHash()))
    ForEach Algos()
      hashKey = HashKey(FilesToHash(), Algos()\name)
      If FindMapElement(AllHashes(), hashKey)
        values + "," + QuoteCSV(AllHashes())
      Else
        values + ","
      EndIf
    Next
    WriteStringN(fileId, values)
  Next

  CloseFile(fileId)
  ProcedureReturn #True
EndProcedure

Procedure.i WriteTXT(OutputPath.s, List FilesToHash.s(), List Algos.HashAlgo(), Map AllHashes.s())
  Protected fileId.i
  Protected hashKey.s

  fileId = CreateFile(#PB_Any, OutputPath)
  If fileId = 0
    PrintError("Unable to write output: " + OutputPath)
    ProcedureReturn #False
  EndIf

  ForEach FilesToHash()
    WriteStringN(fileId, "File: " + FilesToHash())
    WriteStringN(fileId, "Size: " + Str(FileSize(FilesToHash())) + " bytes")
    ForEach Algos()
      hashKey = HashKey(FilesToHash(), Algos()\name)
      If FindMapElement(AllHashes(), hashKey)
        WriteStringN(fileId, "  " + Algos()\name + ": " + AllHashes())
      EndIf
    Next
    WriteStringN(fileId, "")
  Next

  CloseFile(fileId)
  ProcedureReturn #True
EndProcedure

Procedure.i ComputeHashesStreaming(FilePath.s, ChunkSize.i, List Algos.HashAlgo(), Map Hashes.s(), Silent.i = #False)
  Protected fileId.i
  Protected *buffer
  Protected bytesRead.i
  Protected hashKey.s
  Protected readError.i = #False
  Protected totalSize.q = FileSize(FilePath)
  Protected currentRead.q = 0
  Protected lastPercent.i = -1
  Protected currentPercent.i
  Protected startedCount.i = 0

  If totalSize < 0
    PrintError("Input file does not exist or is not readable: " + FilePath)
    ProcedureReturn #False
  EndIf

  If ChunkSize < #MinChunkSize Or ChunkSize > #MaxChunkSize
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
    startedCount + 1
  Next

  If startedCount = 0
    PrintError("No fingerprint algorithms could be initialized.")
    ProcedureReturn #False
  EndIf

  fileId = ReadFile(#PB_Any, FilePath)
  If fileId = 0
    ResetFingerprints(Algos())
    PrintError("Unable to open input file: " + FilePath)
    ProcedureReturn #False
  EndIf

  *buffer = AllocateMemory(ChunkSize)
  If *buffer = 0
    CloseFile(fileId)
    ResetFingerprints(Algos())
    PrintError("Unable to allocate read buffer (" + Str(ChunkSize) + " bytes).")
    ProcedureReturn #False
  EndIf

  While Eof(fileId) = 0
    bytesRead = ReadData(fileId, *buffer, ChunkSize)
    If bytesRead < 0
      readError = #True
      Break
    EndIf
    If bytesRead = 0
      Continue
    EndIf

    currentRead + bytesRead
    
    If Not Silent And totalSize > 0
      currentPercent = (currentRead * 100) / totalSize
      If currentPercent <> lastPercent
        Print(Chr(13) + "Hashing: " + GetFilePart(FilePath) + " [" + Str(currentPercent) + "%]    ")
        lastPercent = currentPercent
      EndIf
    EndIf

    ForEach Algos()
      If Algos()\fp
        AddFingerprintBuffer(Algos()\fp, *buffer, bytesRead)
      EndIf
    Next
  Wend

  FreeMemory(*buffer)
  CloseFile(fileId)

  If readError
    ResetFingerprints(Algos())
    PrintError("Error while reading input file: " + FilePath)
    ProcedureReturn #False
  EndIf

  ; Finish and collect results.
  ForEach Algos()
    hashKey = HashKey(FilePath, Algos()\name)
    If Algos()\fp
      Hashes(hashKey) = LCase(FinishFingerprint(Algos()\fp))
      Algos()\fp = 0
    Else
      ; Explicitly note failed/skipped algorithms
      Hashes(hashKey) = "ERR"
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

  ; Base algorithms.
  AddAlgo(Algos(), "CRC32", #PB_Cipher_CRC32)
  AddAlgo(Algos(), "MD5", #PB_Cipher_MD5)
  AddAlgo(Algos(), "SHA1", #PB_Cipher_SHA1)

  ; SHA-2 variants (supported via Bits parameter).
  AddAlgo(Algos(), "SHA2-224", #PB_Cipher_SHA2, 224)
  AddAlgo(Algos(), "SHA2-256", #PB_Cipher_SHA2, 256)
  AddAlgo(Algos(), "SHA2-384", #PB_Cipher_SHA2, 384)
  AddAlgo(Algos(), "SHA2-512", #PB_Cipher_SHA2, 512)

  ; SHA-3 variants are only available in newer PureBasic builds.
  CompilerIf Defined(UseSHA3Fingerprint, #PB_Procedure)
    CompilerIf Defined(#PB_Cipher_SHA3, #PB_Constant)
      UseSHA3Fingerprint()
      AddAlgo(Algos(), "SHA3-224", #PB_Cipher_SHA3, 224)
      AddAlgo(Algos(), "SHA3-256", #PB_Cipher_SHA3, 256)
      AddAlgo(Algos(), "SHA3-384", #PB_Cipher_SHA3, 384)
      AddAlgo(Algos(), "SHA3-512", #PB_Cipher_SHA3, 512)
    CompilerEndIf
  CompilerEndIf
EndProcedure

Procedure PrintUsage(ExeName.s)
  PrintN(#APP_NAME + " " + version)
  PrintN("")
  PrintN("Usage:")
  PrintN(" " + ExeName + " <input_file|wildcard> [--out <output_file>] [--format csv|txt] [--chunk-size <bytes>] [--silent]")
  PrintN("")
  PrintN("Options:")
  PrintN(" --out <file>       Specify output path (default: first_input.csv/txt)")
  PrintN(" --format <fmt>     Set output format: csv (default) or txt")
  PrintN(" --chunk-size <n>   Set read buffer size in bytes (4KB to 64MB; default: 1MB)")
  PrintN(" --silent, -s       Suppress all console output except critical errors")
  PrintN(" --help, -h         Show this help message")
  PrintN("")
  PrintN("Notes:")
  PrintN(" - Supports multiple input files and wildcards (*.exe, data\*.bin)")
  PrintN(" - CSV output is row-based (File_Path, Size, Hashes...)")
EndProcedure

; -----------------
; Main
; -----------------

If OpenConsole() = 0
  End 1
EndIf

If CountProgramParameters() < 1
  PrintUsage(GetFileName(ProgramFilename()))
  CleanupAndExit(1)
EndIf

Define i.i
Define param.s
For i = 0 To CountProgramParameters() - 1
  param = LCase(ProgramParameter(i))
  If param = "--help" Or param = "/?" Or param = "-h"
    PrintUsage(GetFileName(ProgramFilename()))
    CleanupAndExit(0)
  EndIf
Next

NewList filesToHash.s()
NewList successfulFiles.s()
NewMap seenFiles.i()
Define outputPath.s = ""
Define format.s = "csv"
Define chunkSize.i = #DefaultChunkSize
Define silent.i = #False
Define failedCount.i = 0
Define parseError.s = ""
Define wildcardMisses.i = 0
Define matchedWildcard.i

; First pass: identify input files (supports multiple) and options
For i = 0 To CountProgramParameters() - 1
  param = ProgramParameter(i)
  If Left(param, 1) = "-"
    Select LCase(param)
      Case "--out"
        If i + 1 < CountProgramParameters()
          i + 1
          outputPath = ProgramParameter(i)
        Else
          parseError = "Missing value for --out"
          Break
        EndIf
      Case "--format"
        If i + 1 < CountProgramParameters()
          i + 1
          format = LCase(ProgramParameter(i))
        Else
          parseError = "Missing value for --format"
          Break
        EndIf
      Case "--chunk-size"
        If i + 1 < CountProgramParameters()
          i + 1
          chunkSize = Val(ProgramParameter(i))
          If chunkSize < #MinChunkSize Or chunkSize > #MaxChunkSize
            parseError = "--chunk-size must be between " + Str(#MinChunkSize) + " and " + Str(#MaxChunkSize) + " bytes"
            Break
          EndIf
        Else
          parseError = "Missing value for --chunk-size"
          Break
        EndIf
      Case "--silent", "--quiet", "-s"
        silent = #True
      Default
        parseError = "Unknown option: " + param
        Break
    EndSelect
  Else
    ; Handle wildcards manually if needed, or just add the file
    If FindString(param, "*") Or FindString(param, "?")
      Define dir.s = GetPathPart(param)
      If dir = "" : dir = "." : EndIf
      Define pattern.s = GetFilePart(param)
      Define hDir.i = ExamineDirectory(#PB_Any, dir, pattern)
      matchedWildcard = #False
      If hDir
        While NextDirectoryEntry(hDir)
          If DirectoryEntryType(hDir) = #PB_DirectoryEntry_File
            AddUniqueFile(filesToHash(), seenFiles(), JoinPath(dir, DirectoryEntryName(hDir)))
            matchedWildcard = #True
          EndIf
        Wend
        FinishDirectory(hDir)
      EndIf
      If matchedWildcard = #False
        wildcardMisses + 1
        PrintWarning("No files matched wildcard: " + param, silent)
      EndIf
    Else
      AddUniqueFile(filesToHash(), seenFiles(), param)
    EndIf
  EndIf
Next

If parseError <> ""
  PrintError(parseError)
  CleanupAndExit(1)
EndIf

If ListSize(filesToHash()) = 0
  If wildcardMisses = 0
    PrintUsage(GetFileName(ProgramFilename()))
  Else
    PrintError("No input files matched.")
  EndIf
  CleanupAndExit(1)
EndIf

If format <> "csv" And format <> "txt"
  PrintError("Unsupported format: " + format)
  CleanupAndExit(1)
EndIf

If outputPath = ""
  outputPath = DefaultOutputPath(filesToHash(), format)
EndIf

NewList algos.HashAlgo()
BuildAlgorithmList(algos())

NewMap hashes.s()
ForEach filesToHash()
  If Not silent : Print("Hashing: " + GetFilePart(filesToHash()) + "... ") : EndIf
  If ComputeHashesStreaming(filesToHash(), chunkSize, algos(), hashes(), silent)
    AddElement(successfulFiles())
    successfulFiles() = filesToHash()
    If Not silent : PrintN(Chr(13) + "Hashing: " + GetFilePart(filesToHash()) + " ... Done.    ") : EndIf
  Else
    failedCount + 1
    If Not silent : PrintN(Chr(13) + "Hashing: " + GetFilePart(filesToHash()) + " ... FAILED.    ") : EndIf
  EndIf
Next

If ListSize(successfulFiles()) = 0 Or MapSize(hashes()) <= 0
  PrintError("No hashes generated.")
  CleanupAndExit(1)
EndIf

Define ok.i
If format = "csv"
  ok = WriteCSV(outputPath, successfulFiles(), algos(), hashes())
Else
  ok = WriteTXT(outputPath, successfulFiles(), algos(), hashes())
EndIf

If ok = #False
  CleanupAndExit(1)
EndIf

If Not silent
  PrintN("")
  PrintN("Output saved to: " + outputPath)
  PrintN("Hashed files: " + Str(ListSize(successfulFiles())))
  PrintN("Failed files: " + Str(failedCount))
EndIf

CleanupAndExit(0)

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 1
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; UseIcon = hash_tool.ico
; Executable = ..\hash_tool.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,4
; VersionField1 = 1,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = hash_tool
; VersionField4 = 1.0.0.4
; VersionField5 = 1.0.0.4
; VersionField6 = Create hash tables for executable files.
; VersionField7 = hash_tool
; VersionField8 = hash_tool.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60