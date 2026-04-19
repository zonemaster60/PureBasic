Procedure.b WriteGeneratedConfig(ConfigFile.s)
  Protected FileID.i = CreateFile(#PB_Any, ConfigFile)

  If FileID = 0
    ProcedureReturn #False
  EndIf

  WriteStringN(FileID, "Global ConstantTheme.s = " + Chr(34) + EscapePBString(CurrentTheme) + Chr(34))
  WriteStringN(FileID, "Global ConstantSetting.s = " + Chr(34) + EscapePBString(CurrentSetting) + Chr(34))
  WriteStringN(FileID, "Global ConstantCulture.s = " + Chr(34) + EscapePBString(CurrentCulture) + Chr(34))
  WriteStringN(FileID, "Global ConstantLandmark.s = " + Chr(34) + EscapePBString(CurrentLandmark) + Chr(34))
  WriteStringN(FileID, "Global ConstantRole.s = " + Chr(34) + EscapePBString(GS\PlayerRole) + Chr(34))
  WriteStringN(FileID, "Global ConstantGoal.s = " + Chr(34) + EscapePBString(CurrentGoal) + Chr(34))
  WriteStringN(FileID, "Global ConstantTwist.s = " + Chr(34) + EscapePBString(CurrentTwist) + Chr(34))
  CloseFile(FileID)
  ProcedureReturn #True
EndProcedure

Procedure.b WriteStandaloneBuildSource(SourceFile.s, OutputSourceFile.s, ConfigIncludeName.s)
  Protected InputFile.i
  Protected OutputFile.i
  Protected Line.s
  Protected VersionString.s = RemoveString(version, "v")
  Protected VersionTuple.s = GetVersionInfoTuple()
  Protected IncludeLine.s = "XIncludeFile " + Chr(34) + "config_defaults.pbi" + Chr(34)
  Protected ReplacementLine.s = "XIncludeFile " + Chr(34) + ConfigIncludeName + Chr(34)

  InputFile = ReadFile(#PB_Any, SourceFile)
  If InputFile = 0
    ProcedureReturn #False
  EndIf

  OutputFile = CreateFile(#PB_Any, OutputSourceFile)
  If OutputFile = 0
    CloseFile(InputFile)
    ProcedureReturn #False
  EndIf

  While Eof(InputFile) = 0
    Line = ReadString(InputFile)
    If Left(Line, 13) = "; IDE Options"
      Break
    EndIf

    If Trim(Line) = IncludeLine
      WriteStringN(OutputFile, ReplacementLine)
    Else
      WriteStringN(OutputFile, Line)
    EndIf
  Wend

  WriteStringN(OutputFile, "")
  WriteStringN(OutputFile, "; IDE Options = PureBasic 6.30 (Windows - x64)")
  WriteStringN(OutputFile, "; Optimizer")
  WriteStringN(OutputFile, "; EnableThread")
  WriteStringN(OutputFile, "; EnableXP")
  WriteStringN(OutputFile, "; EnableAdmin")
  WriteStringN(OutputFile, "; DPIAware")
  WriteStringN(OutputFile, "; UseIcon = main.ico")
  WriteStringN(OutputFile, "; Executable = ..\\" + #BUILD_OUTPUT_FILE)
  WriteStringN(OutputFile, "; IncludeVersionInfo")
  WriteStringN(OutputFile, "; VersionField0 = " + VersionTuple)
  WriteStringN(OutputFile, "; VersionField1 = " + VersionTuple)
  WriteStringN(OutputFile, "; VersionField2 = ZoneSoft")
  WriteStringN(OutputFile, "; VersionField3 = " + GetGeneratedProductName())
  WriteStringN(OutputFile, "; VersionField4 = " + VersionString)
  WriteStringN(OutputFile, "; VersionField5 = " + VersionString)
  WriteStringN(OutputFile, "; VersionField6 = " + #GENERATED_FILE_DESCRIPTION)
  WriteStringN(OutputFile, "; VersionField7 = " + GetGeneratedProductName())
  WriteStringN(OutputFile, "; VersionField8 = " + #BUILD_OUTPUT_FILE)
  WriteStringN(OutputFile, "; VersionField9 = David Scouten")
  WriteStringN(OutputFile, "; VersionField13 = zonemaster60@gmail.com")
  WriteStringN(OutputFile, "; VersionField14 = https://github.com/zonemaster60")

  CloseFile(OutputFile)
  CloseFile(InputFile)
  ProcedureReturn #True
EndProcedure

Procedure ExportStandalone()
  Protected SourceFile.s = ResolveSourceFile()
  Protected SourceDirectory.s
  Protected OutputFile.s
  Protected IconFile.s
  Protected CompilerArgs.s
  Protected BuildSourceFile.s
  Protected BuildConfigFile.s
  Protected Compiler.i
  Protected ExitCode.i

  If SourceFile = ""
    PrintN("ERROR: Could not locate main.pb for export.")
    Print("> ")
    ProcedureReturn
  EndIf

  SourceDirectory = GetPathPart(SourceFile)
  OutputFile = JoinPath(GetCurrentDirectory(), #BUILD_OUTPUT_FILE)
  IconFile = JoinPath(SourceDirectory, "main.ico")
  BuildSourceFile = JoinPath(SourceDirectory, "generated_build_main.pb")
  BuildConfigFile = JoinPath(SourceDirectory, "generated_build_config.pbi")

  PrintN("Preparing standalone build...")
  If WriteGeneratedConfig(BuildConfigFile) = #False
    PrintN("ERROR: Could not write " + BuildConfigFile + ".")
    Print("> ")
    ProcedureReturn
  EndIf

  If WriteStandaloneBuildSource(SourceFile, BuildSourceFile, GetFilePart(BuildConfigFile)) = #False
    If FileSize(BuildConfigFile) >= 0
      DeleteFile(BuildConfigFile)
    EndIf
    PrintN("ERROR: Could not write " + BuildSourceFile + ".")
    Print("> ")
    ProcedureReturn
  EndIf

  PrintN("Invoking PureBasic Compiler...")
  CompilerArgs = Chr(34) + BuildSourceFile + Chr(34) + " /EXE " + Chr(34) + OutputFile + Chr(34) + " /CONSOLE"
  If FileSize(IconFile) >= 0
    CompilerArgs + " /ICON " + Chr(34) + IconFile + Chr(34)
  EndIf

  Compiler = RunProgram("pbcompiler", CompilerArgs, SourceDirectory, #PB_Program_Open | #PB_Program_Read | #PB_Program_Error)
  If Compiler
    While ProgramRunning(Compiler)
      While AvailableProgramOutput(Compiler)
        PrintN(ReadProgramString(Compiler))
      Wend
      Delay(10)
    Wend

    While AvailableProgramOutput(Compiler)
      PrintN(ReadProgramString(Compiler))
    Wend

    ExitCode = ProgramExitCode(Compiler)
    CloseProgram(Compiler)

    If ExitCode = 0
      PrintN("SUCCESS: Standalone build created at " + OutputFile)
    Else
      PrintN("ERROR: Compiler exited with code " + Str(ExitCode) + ".")
    EndIf
  Else
    PrintN("ERROR: pbcompiler.exe not found in PATH.")
  EndIf

  If FileSize(BuildSourceFile) >= 0
    DeleteFile(BuildSourceFile)
  EndIf
  If FileSize(BuildConfigFile) >= 0
    DeleteFile(BuildConfigFile)
  EndIf

  Print("> ")
EndProcedure
