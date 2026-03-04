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

#APP_NAME   = "Hash_Tool"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.2"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = #ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

#DefaultChunkSize = 1024 * 1024

Structure HashAlgo
  name.s
  plugin.i
  bits.i
  fp.i
EndStructure

Procedure Exit()
  MessageRequester("Info", #APP_NAME + " - " + version + #CRLF$ + 
                           "Thank you for using this free tool!" + #CRLF$ +
                           "Contact: " + #EMAIL_NAME + #CRLF$ +
                           "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End 1
EndProcedure

Procedure.s QuoteCSV(Field.s)
  ; CSV escaping: escape double quotes by doubling them and wrap in quotes
  Field = ReplaceString(Field, #DQUOTE$, #DQUOTE$ + #DQUOTE$)
  ProcedureReturn #DQUOTE$ + Field + #DQUOTE$
EndProcedure

Procedure.s GetFileName(FilePath.s)
  ProcedureReturn GetFilePart(FilePath)
EndProcedure

Procedure.s DefaultOutputPath(List Files.s(), Format.s)
  Protected suffix.s
  Protected firstFile.s
  
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
  ProcedureReturn firstFile + suffix
EndProcedure

Procedure.i WriteCSV(OutputPath.s, List FilesToHash.s(), List Algos.HashAlgo(), Map AllHashes.s())
  Protected fileId.i
  Protected key.s
  Protected header.s
  Protected values.s
  Protected hashKey.s

  fileId = CreateFile(#PB_Any, OutputPath)
  If fileId = 0
    PrintN("ERROR: Unable to write output: " + OutputPath)
    ProcedureReturn #False
  EndIf

  ; Header
  header = "Filename,Size_Bytes"
  ForEach Algos()
    header + "," + QuoteCSV(Algos()\name)
  Next
  WriteStringN(fileId, header)

  ; Data rows
  ForEach FilesToHash()
    values = QuoteCSV(FilesToHash()) + "," + Str(FileSize(FilesToHash()))
    ForEach Algos()
      hashKey = FilesToHash() + "|" + Algos()\name
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
    PrintN("ERROR: Unable to write output: " + OutputPath)
    ProcedureReturn #False
  EndIf

  ForEach FilesToHash()
    WriteStringN(fileId, "File: " + FilesToHash())
    WriteStringN(fileId, "Size: " + Str(FileSize(FilesToHash())) + " bytes")
    ForEach Algos()
      hashKey = FilesToHash() + "|" + Algos()\name
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
  Protected totalSize.q = FileSize(FilePath)
  Protected currentRead.q = 0
  Protected lastPercent.i = -1
  Protected currentPercent.i

  If totalSize < 0
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
    If bytesRead < 0
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

  ; Finish and collect results.
  ForEach Algos()
    hashKey = FilePath + "|" + Algos()\name
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
  PrintN(" " + ExeName + " <input_file|wildcard> [--out <output_file>] [--format csv|txt] [--chunk-size <bytes>] [--silent]")
  PrintN("")
  PrintN("Options:")
  PrintN(" --out <file>       Specify output path (default: first_input.csv/txt)")
  PrintN(" --format <fmt>     Set output format: csv (default) or txt")
  PrintN(" --chunk-size <n>   Set read buffer size in bytes (default: 1MB)")
  PrintN(" --silent, -s       Suppress all console output except critical errors")
  PrintN(" --help, -h         Show this help message")
  PrintN("")
  PrintN("Notes:")
  PrintN(" - Supports multiple input files and wildcards (*.exe, data\*.bin)")
  PrintN(" - CSV output is row-based (Filename, Size, Hashes...)")
  Exit()
EndProcedure

; -----------------
; Main
; -----------------

If OpenConsole() = 0
  End 1
EndIf

If CountProgramParameters() < 1
  PrintUsage(GetFileName(ProgramFilename()))
  Exit()
EndIf

Define i.i
Define param.s
For i = 0 To CountProgramParameters() - 1
  param = LCase(ProgramParameter(i))
  If param = "--help" Or param = "/?" Or param = "-h"
    PrintUsage(GetFileName(ProgramFilename()))
    Exit()
  EndIf
Next

NewList filesToHash.s()
Define outputPath.s = ""
Define format.s = "csv"
Define chunkSize.i = #DefaultChunkSize
Define silent.i = #False

; First pass: identify input files (supports multiple) and options
For i = 0 To CountProgramParameters() - 1
  param = ProgramParameter(i)
  If Left(param, 1) = "-"
    Select LCase(param)
      Case "--out"
        If i + 1 < CountProgramParameters()
          i + 1
          outputPath = ProgramParameter(i)
        EndIf
      Case "--format"
        If i + 1 < CountProgramParameters()
          i + 1
          format = LCase(ProgramParameter(i))
        EndIf
      Case "--chunk-size"
        If i + 1 < CountProgramParameters()
          i + 1
          chunkSize = Val(ProgramParameter(i))
        EndIf
      Case "--silent", "--quiet", "-s"
        silent = #True
    EndSelect
  Else
    ; Handle wildcards manually if needed, or just add the file
    If FindString(param, "*") Or FindString(param, "?")
      Define dir.s = GetPathPart(param)
      If dir = "" : dir = "." : EndIf
      Define pattern.s = GetFilePart(param)
      Define hDir.i = ExamineDirectory(#PB_Any, dir, pattern)
      If hDir
        While NextDirectoryEntry(hDir)
          If DirectoryEntryType(hDir) = #PB_DirectoryEntry_File
            AddElement(filesToHash())
            filesToHash() = dir + DirectoryEntryName(hDir)
          EndIf
        Wend
        FinishDirectory(hDir)
      EndIf
    Else
      AddElement(filesToHash())
      filesToHash() = param
    EndIf
  EndIf
Next

If ListSize(filesToHash()) = 0
  PrintUsage(GetFileName(ProgramFilename()))
  Exit()
EndIf

If format <> "csv" And format <> "txt"
  If Not silent : PrintN("ERROR: Unsupported format: " + format) : EndIf
  Exit()
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
    If Not silent : PrintN(Chr(13) + "Hashing: " + GetFilePart(filesToHash()) + " ... Done.    ") : EndIf
  Else
    If Not silent : PrintN(Chr(13) + "Hashing: " + GetFilePart(filesToHash()) + " ... FAILED.    ") : EndIf
  EndIf
Next

If MapSize(hashes()) <= 0
  If Not silent : PrintN("ERROR: No hashes generated.") : EndIf
  Exit()
EndIf

Define ok.i
If format = "csv"
  ok = WriteCSV(outputPath, filesToHash(), algos(), hashes())
Else
  ok = WriteTXT(outputPath, filesToHash(), algos(), hashes())
EndIf

If ok = #False
  CloseHandle_(hMutex)
  End 1
EndIf

If Not silent
  PrintN("")
  PrintN("Output saved to: " + outputPath)
  PrintN("Total files: " + Str(ListSize(filesToHash())))
EndIf

Exit()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 17
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = hash_tool.ico
; Executable = ..\hash_tool.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = hash_tool
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = Create hash tables for executable files.
; VersionField7 = hash_tool
; VersionField8 = hash_tool.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60