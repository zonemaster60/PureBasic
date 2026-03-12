; Runtime stub for pbpack
; Builds as Windows x64 console program.
; Reads compressed payload from appended overlay, unpacks to a temp EXE,
; launches it normally, waits for it to exit, then cleans up.

EnableExplicit

UseLZMAPacker()

#MAGIC = $5042504B ; 'PBPk'

#PBP_FLAG_EXTRACT_LOCAL_ONLY = 1
#PBP_FLAG_EXTRACT_TEMP_ONLY  = 2

; Compile-time options
#PBP_STUB_VERBOSE = #False

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

Procedure Die(msg.s)
  If OpenConsole()
    PrintN("pbpack stub: " + msg)
    If #PBP_STUB_VERBOSE
      PrintN("")
      PrintN("This stub extracts the original EXE to a temp file and runs it.")
      PrintN("Common causes:")
      PrintN("  - The packed file is truncated or corrupted.")
      PrintN("  - Temporary file creation or launch failed.")
    EndIf
  EndIf
  End 1
EndProcedure

Procedure.s GetSelfPath()
  Protected buf.s = Space(32768)
  Protected len = GetModuleFileName_(0, @buf, Len(buf))
  If len <= 0
    ProcedureReturn ""
  EndIf
  ProcedureReturn Left(buf, len)
EndProcedure

Procedure.s QuoteArg(arg.s)
  ProcedureReturn Chr(34) + ReplaceString(arg, Chr(34), "\" + Chr(34)) + Chr(34)
EndProcedure

Procedure.s GetSelfBaseName()
  Protected name.s = GetFilePart(GetSelfPath(), #PB_FileSystem_NoExtension)
  If name = ""
    name = "pbpack"
  EndIf
  ProcedureReturn name
EndProcedure

Procedure.s GetSelfDirectory()
  Protected selfPath.s = GetSelfPath()
  If selfPath = ""
    ProcedureReturn GetCurrentDirectory()
  EndIf
  ProcedureReturn GetPathPart(selfPath)
EndProcedure

Procedure.s ParentDirectory(path.s)
  Protected trimmed.s = path
  If trimmed = ""
    ProcedureReturn ""
  EndIf
  If Right(trimmed, 1) = "\"
    trimmed = Left(trimmed, Len(trimmed) - 1)
  EndIf
  ProcedureReturn GetPathPart(trimmed)
EndProcedure

Procedure.s GetPreferredExtractBaseName()
  Protected name.s = GetSelfBaseName()
  Protected lower.s = LCase(name)

  If Right(lower, 7) = "_packed"
    name = Left(name, Len(name) - 7)
  ElseIf Right(lower, 7) = "-packed"
    name = Left(name, Len(name) - 7)
  ElseIf Right(lower, 7) = ".packed"
    name = Left(name, Len(name) - 7)
  EndIf

  If name = ""
    name = "pbpack"
  EndIf

  ProcedureReturn name
EndProcedure

Procedure.s EnsureTrailingSlash(path.s)
  If path = ""
    ProcedureReturn ""
  EndIf
  If Right(path, 1) <> "\"
    path + "\"
  EndIf
  ProcedureReturn path
EndProcedure

Procedure.s BuildChildCommandLine(exePath.s)
  Protected cmd.s = QuoteArg(exePath)
  Protected i

  For i = 0 To CountProgramParameters() - 1
    cmd + " " + QuoteArg(ProgramParameter(i))
  Next

  ProcedureReturn cmd
EndProcedure

Procedure.s BuildChildParameters()
  Protected params.s = ""
  Protected i

  For i = 0 To CountProgramParameters() - 1
    If params <> ""
      params + " "
    EndIf
    params + QuoteArg(ProgramParameter(i))
  Next

  ProcedureReturn params
EndProcedure

Procedure.i LoadOverlayPayload(*hdr.PbPkHeader, *packedOut.Integer)
  Protected self.s = GetSelfPath()
  Protected h = ReadFile(#PB_Any, self)
  If h = 0 : Die("Failed to open packed executable") : EndIf

  Protected fsize.q = Lof(h)
  If fsize < SizeOf(PbPkHeader) : CloseFile(h) : Die("Invalid packed file") : EndIf

  FileSeek(h, fsize - SizeOf(PbPkHeader))
  If ReadData(h, *hdr, SizeOf(PbPkHeader)) <> SizeOf(PbPkHeader)
    CloseFile(h)
    Die("Failed reading header")
  EndIf

  If *hdr\magic <> #MAGIC
    CloseFile(h)
    Die("Not a pbpack file")
  EndIf

  If *hdr\packedSize = 0 Or *hdr\originalSize = 0
    CloseFile(h)
    Die("Corrupt header")
  EndIf

  Protected payloadPos.q = fsize - SizeOf(PbPkHeader) - *hdr\packedSize
  If payloadPos < 0
    CloseFile(h)
    Die("Corrupt payload position")
  EndIf

  Protected *packed = AllocateMemory(*hdr\packedSize)
  If *packed = 0
    CloseFile(h)
    Die("Out of memory (packed)")
  EndIf

  FileSeek(h, payloadPos)
  If ReadData(h, *packed, *hdr\packedSize) <> *hdr\packedSize
    FreeMemory(*packed)
    CloseFile(h)
    Die("Failed reading packed payload")
  EndIf

  CloseFile(h)
  *packedOut\i = *packed
  ProcedureReturn 1
EndProcedure

Procedure.s MakeExtractDirectory(baseDir.s)
  If baseDir = ""
    baseDir = GetCurrentDirectory()
  EndIf

  baseDir = EnsureTrailingSlash(baseDir)

  Protected ticks.q = ElapsedMilliseconds()
  Protected pid.l = GetCurrentProcessId_()
  Protected dirPath.s = baseDir + ".pbpack_runtime_" + Str(pid) + "_" + Str(ticks)
  Protected attempt

  For attempt = 0 To 999
    If FileSize(dirPath) < 0
      If CreateDirectory(dirPath)
        ProcedureReturn EnsureTrailingSlash(dirPath)
      EndIf
    EndIf
    dirPath = baseDir + ".pbpack_runtime_" + Str(pid) + "_" + Str(ticks) + "_" + Str(attempt)
  Next

  Die("Failed to create runtime extraction directory")
EndProcedure

Procedure CleanupStaleRuntimeDirs(baseDir.s)
  If baseDir = ""
    ProcedureReturn
  EndIf

  Protected search = ExamineDirectory(#PB_Any, baseDir, ".pbpack_runtime_*")
  If search = 0
    ProcedureReturn
  EndIf

  While NextDirectoryEntry(search)
    If DirectoryEntryType(search) = #PB_DirectoryEntry_Directory
      DeleteDirectory(EnsureTrailingSlash(baseDir) + DirectoryEntryName(search), "", #PB_FileSystem_Force)
    EndIf
  Wend

  FinishDirectory(search)
EndProcedure

Procedure CleanupChildArtifacts(extractDir.s)
  Protected parentDir.s = ParentDirectory(extractDir)
  If parentDir <> ""
    CleanupStaleRuntimeDirs(parentDir)
  EndIf
EndProcedure

Procedure LaunchCleanupHelper(extractDir.s, filePath.s)
  Protected command.s = "/c ping 127.0.0.1 -n 4 >nul && del /f /q " + QuoteArg(filePath) + " >nul 2>nul && rmdir /s /q " + QuoteArg(ParentDirectory(filePath)) + " >nul 2>nul"
  RunProgram("cmd.exe", command, "", #PB_Program_Hide)
EndProcedure

Procedure.i ChooseExtractBaseDir(*hdr.PbPkHeader)
  If *hdr\flags & #PBP_FLAG_EXTRACT_LOCAL_ONLY
    ProcedureReturn 1
  EndIf
  If *hdr\flags & #PBP_FLAG_EXTRACT_TEMP_ONLY
    ProcedureReturn 2
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure CleanupTempExe(filePath.s)
  Protected attempt

  For attempt = 0 To 19
    If FileSize(filePath) < 0
      ProcedureReturn
    EndIf

    If DeleteFile(filePath)
      ProcedureReturn
    EndIf

    Delay(50)
  Next

  If OpenConsole() And #PBP_STUB_VERBOSE
    PrintN("pbpack stub: warning: failed to delete temp file: " + filePath)
  EndIf
EndProcedure

Procedure CleanupExtractDirectory(dirPath.s)
  Protected attempt

  dirPath = EnsureTrailingSlash(dirPath)

  For attempt = 0 To 19
    If FileSize(dirPath) < 0
      ProcedureReturn
    EndIf

    If DeleteDirectory(dirPath, "", #PB_FileSystem_Force)
      ProcedureReturn
    EndIf

    Delay(50)
  Next

  If OpenConsole() And #PBP_STUB_VERBOSE
    PrintN("pbpack stub: warning: failed to delete runtime directory: " + dirPath)
  EndIf
EndProcedure

Procedure.i WriteExtractedExe(filePath.s, *data, dataSize.q)
  Protected h = CreateFile(#PB_Any, filePath)
  If h = 0 : ProcedureReturn 0 : EndIf

  If WriteData(h, *data, dataSize) <> dataSize
    CloseFile(h)
    DeleteFile(filePath)
    ProcedureReturn 0
  EndIf

  CloseFile(h)
  ProcedureReturn 1
EndProcedure

Procedure.i RunExtractedExe(filePath.s)
  Protected params.s = BuildChildParameters()
  Protected sei.SHELLEXECUTEINFO
  Protected workDir.s = GetSelfDirectory()
  Protected verb.s = "open"

  sei\cbSize = SizeOf(SHELLEXECUTEINFO)
  sei\fMask = $00000040 ; SEE_MASK_NOCLOSEPROCESS
  sei\lpVerb = @verb
  sei\lpFile = @filePath
  If params <> ""
    sei\lpParameters = @params
  EndIf
  sei\lpDirectory = @workDir
  sei\nShow = 1 ; SW_SHOWNORMAL

  If ShellExecuteEx_(@sei)
    WaitForSingleObject_(sei\hProcess, #INFINITE)

    Protected exitCode.l = 0
    If GetExitCodeProcess_(sei\hProcess, @exitCode) = 0
      CloseHandle_(sei\hProcess)
      Die("GetExitCodeProcess failed")
    EndIf

    CloseHandle_(sei\hProcess)
    ProcedureReturn exitCode
  EndIf

  Protected si.STARTUPINFO
  Protected pi.PROCESS_INFORMATION
  Protected cmd.s = BuildChildCommandLine(filePath)
  Protected mutableCmd.s = cmd

  si\cb = SizeOf(STARTUPINFO)

  If CreateProcess_(filePath, @mutableCmd, 0, 0, #False, 0, 0, GetSelfDirectory(), si, pi) = 0
    Die("CreateProcess failed for extracted EXE")
  EndIf

  WaitForSingleObject_(pi\hProcess, #INFINITE)

  exitCode = 0
  If GetExitCodeProcess_(pi\hProcess, @exitCode) = 0
    CloseHandle_(pi\hThread)
    CloseHandle_(pi\hProcess)
    Die("GetExitCodeProcess failed")
  EndIf

  CloseHandle_(pi\hThread)
  CloseHandle_(pi\hProcess)
  ProcedureReturn exitCode
EndProcedure

Procedure Main()
  If #PBP_STUB_VERBOSE
    If OpenConsole()
      Protected argCount = CountProgramParameters()
      If argCount > 0
        Protected a0.s = ProgramParameter(0)
        If a0 = "--help" Or a0 = "-h" Or a0 = "/?"
          PrintN("pbpack stub (extract-and-run) - Windows x64")
          PrintN("")
          PrintN("This executable extracts the packed payload beside the packed")
          PrintN("EXE or in the temp directory, launches it normally, waits for")
          PrintN("it to finish, then deletes the extracted files when possible.")
          End 0
        EndIf
      EndIf
    EndIf
  EndIf

  CleanupStaleRuntimeDirs(GetSelfDirectory())
  CleanupStaleRuntimeDirs(GetTemporaryDirectory())

  Protected hdr.PbPkHeader
  Protected packedPtr.Integer

  If LoadOverlayPayload(@hdr, @packedPtr) = 0
    Die("Failed loading payload")
  EndIf

  Protected *orig = AllocateMemory(hdr\originalSize)
  If *orig = 0
    FreeMemory(packedPtr\i)
    Die("Out of memory (orig)")
  EndIf

  If UncompressMemory(packedPtr\i, hdr\packedSize, *orig, hdr\originalSize, #PB_PackerPlugin_Lzma) = 0
    FreeMemory(*orig)
    FreeMemory(packedPtr\i)
    Die("UncompressMemory failed")
  EndIf

  Protected extractMode = ChooseExtractBaseDir(@hdr)
  Protected extractDir.s
  Protected tempExe.s

  If extractMode <> 2
    extractDir = MakeExtractDirectory(GetSelfDirectory())
    tempExe = extractDir + GetPreferredExtractBaseName() + ".exe"
    If WriteExtractedExe(tempExe, *orig, hdr\originalSize) = 0
      CleanupExtractDirectory(extractDir)
      extractDir = ""
      tempExe = ""
      If extractMode = 1
        FreeMemory(*orig)
        FreeMemory(packedPtr\i)
        Die("Failed to create extracted EXE beside packed executable")
      EndIf
    EndIf
  EndIf

  If tempExe = ""
    extractDir = MakeExtractDirectory(GetTemporaryDirectory())
    tempExe = extractDir + GetPreferredExtractBaseName() + ".exe"
    If WriteExtractedExe(tempExe, *orig, hdr\originalSize) = 0
      FreeMemory(*orig)
      FreeMemory(packedPtr\i)
      Die("Failed to create extracted EXE in selected runtime directory")
    EndIf
  EndIf

  FreeMemory(*orig)
  FreeMemory(packedPtr\i)

  Protected exitCode = RunExtractedExe(tempExe)
  CleanupTempExe(tempExe)
  CleanupExtractDirectory(extractDir)
  CleanupChildArtifacts(extractDir)
  If FileSize(tempExe) >= 0 Or FileSize(extractDir) >= 0
    LaunchCleanupHelper(extractDir, tempExe)
  EndIf
  End exitCode
EndProcedure

Main()

; IDE Options = PureBasic 6.30 (Windows - x64)
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; SharedUCRT
; UseIcon = Stub.ico
; Executable = stub.exe
; DisableDebugger