; Startup integration, crash logging, and OS/file-system helpers

Procedure.s StartupTaskName()
  ProcedureReturn #APP_NAME
EndProcedure

Procedure.s CurrentUserSam()
  Protected user.s = Trim(GetEnvironmentVariable("USERNAME"))
  Protected domain.s = Trim(GetEnvironmentVariable("USERDOMAIN"))

  If user = ""
    ProcedureReturn ""
  EndIf

  If domain <> ""
    ProcedureReturn domain + "\\" + user
  EndIf

  ProcedureReturn user
EndProcedure

Procedure RemoveLegacyStartupRegistryEntry()
  ; Older versions may have used HKCU\...\Run. Best-effort cleanup.
  Protected cmd.s = "reg delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v " + #APP_NAME + " /f"
  RunProgram("cmd.exe", "/c " + cmd, "", #PB_Program_Hide)
EndProcedure

Procedure.i RunAndCapture(exe.s, args.s)
  Protected program.i
  Protected exitCode.i = -1

  LogLine("Run: " + exe + " " + args)
  program = RunProgram(exe, args, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)

  If program = 0
    gLastExecExitCode = -1
    LogLine("Failed to start: " + exe)
    ProcedureReturn -1
  EndIf

  While ProgramRunning(program)
    While AvailableProgramOutput(program)
      ReadProgramString(program)
    Wend
    Delay(5)
  Wend

  While AvailableProgramOutput(program)
    ReadProgramString(program)
  Wend

  exitCode = ProgramExitCode(program)
  gLastExecExitCode = exitCode
  CloseProgram(program)
  LogLine("Exit code: " + Str(exitCode) + " | " + exe)
  ProcedureReturn exitCode
EndProcedure

Procedure.i OpenCrashLogFile(filePath.s)
  Protected f.i

  If filePath = ""
    ProcedureReturn 0
  EndIf

  If FileSize(filePath) >= 0
    f = OpenFile(#PB_Any, filePath)
    If f
      FileSeek(f, Lof(f))
    EndIf
  Else
    f = CreateFile(#PB_Any, filePath)
  EndIf

  ProcedureReturn f
EndProcedure

Procedure.s EnsureCrashLogFolder(baseFolder.s)
  Protected folder.s = baseFolder

  If folder = ""
    ProcedureReturn ""
  EndIf

  If Right(folder, 1) <> "\"
    folder + "\"
  EndIf

  folder + "Logs\"

  If FileSize(folder) <> -2
    CreateDirectory(folder)
  EndIf

  If FileSize(folder) = -2
    ProcedureReturn folder
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.s ChooseCrashLogPath()
  Protected candidate.s
  Protected appData.s
  Protected folder.s
  Protected f.i

  ; Prefer a Logs folder next to the EXE if writable.
  folder = EnsureCrashLogFolder(AppPath)
  If folder <> ""
    candidate = folder + #APP_NAME + ".log"
    f = OpenCrashLogFile(candidate)
    If f
      CloseFile(f)
      ProcedureReturn candidate
    EndIf
  EndIf

  ; Fall back to %APPDATA%\HandySearch\Logs\...
  appData = GetEnvironmentVariable("APPDATA")
  If appData <> "" And Right(appData, 1) <> "\"
    appData + "\"
  EndIf

  folder = EnsureCrashLogFolder(appData + #APP_NAME)
  If folder <> ""
    candidate = folder + #APP_NAME + ".log"
    f = OpenCrashLogFile(candidate)
    If f
      CloseFile(f)
      ProcedureReturn candidate
    EndIf
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure LogLine(msg.s)
  Protected f.i
  Protected line.s

  If CrashLogPath = ""
    CrashLogPath = ChooseCrashLogPath()
  EndIf

  f = OpenCrashLogFile(CrashLogPath)
  If f = 0
    ProcedureReturn
  EndIf

  line = FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()) + " | " + msg
  WriteStringN(f, line, #PB_UTF8)
  CloseFile(f)
EndProcedure

Procedure CrashErrorHandler()
  ; Called by PB runtime on unhandled errors/exceptions.
  If CrashLogInHandler
    End
  EndIf
  CrashLogInHandler = 1

  LogLine("CRASH")
  LogLine("ErrorMessage: " + ErrorMessage())
  LogLine("ErrorCode: " + Str(ErrorCode()))
  LogLine("ErrorAddress: " + Str(ErrorAddress()))
  LogLine("ErrorLine: " + Str(ErrorLine()))
  LogLine("ErrorFile: " + ErrorFile())
  LogLine("DB path: " + ResolveDbPath(IndexDbPath))

  MessageRequester(#APP_NAME, "The application encountered an unexpected error and must close." + #CRLF$ +
                            "Crash log (Logs folder): " + CrashLogPath, #PB_MessageRequester_Error)
  End
EndProcedure

Procedure InitCrashLogging()
  ; Best-effort: write a run header and install error handler.
  CrashLogPath = ChooseCrashLogPath()
  If CrashLogPath <> ""
    LogLine("=== START " + #APP_NAME + " " + version + " ===")
    LogLine("Exe: " + ProgramFilename())
    LogLine("Cwd: " + GetCurrentDirectory())
  EndIf

  OnErrorCall(@CrashErrorHandler())
EndProcedure

Procedure.b IsProcessElevated()
  ; TokenElevation (20)
  #TokenElevation = 20

  Protected hToken.i
  If OpenProcessToken_(GetCurrentProcess_(), $0008, @hToken) = 0
    ProcedureReturn #False
  EndIf

  Protected elevation.l
  Protected cbSize.l
  Protected ok = GetTokenInformation_(hToken, #TokenElevation, @elevation, SizeOf(Long), @cbSize)
  CloseHandle_(hToken)

  If ok = 0
    ProcedureReturn #False
  EndIf

  ProcedureReturn Bool(elevation <> 0)
EndProcedure

Procedure RelaunchSelfElevated(args.s)
  Protected exe$ = ProgramFilename()
  ShellExecute_(0, "runas", exe$, args, AppPath, 1)
EndProcedure

Procedure.i AddToStartup()
  RemoveLegacyStartupRegistryEntry()

  Protected taskName.s = StartupTaskName()
  Protected exePath.s = ProgramFilename()
  Protected workDir.s = GetPathPart(exePath)
  Protected userSam.s = CurrentUserSam()
  Protected psCmd.s
  Protected args.s

  LogLine("Enabling run at startup")
  psCmd = "Register-ScheduledTask -TaskName '" + ReplaceString(taskName, "'", "''") + "' " +
          "-Action (New-ScheduledTaskAction -Execute '" + ReplaceString(exePath, "'", "''") + "' -WorkingDirectory '" + ReplaceString(workDir, "'", "''") + "') " +
          "-Trigger (New-ScheduledTaskTrigger -AtLogOn -User '" + ReplaceString(userSam, "'", "''") + "') " +
          "-Settings (New-ScheduledTaskSettingsSet -StartWhenAvailable -MultipleInstances IgnoreNew -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries) " +
          "-Principal (New-ScheduledTaskPrincipal -UserId '" + ReplaceString(userSam, "'", "''") + "' -LogonType Interactive -RunLevel Highest) -Force"

  args = "-NoProfile -ExecutionPolicy Bypass -Command " + #DQUOTE$ + psCmd + #DQUOTE$
  ProcedureReturn Bool(RunAndCapture("powershell.exe", args) = 0)
EndProcedure

Procedure.i RemoveFromStartup()
  RemoveLegacyStartupRegistryEntry()

  Protected delArgs.s = "/Delete /F /TN " + #DQUOTE$ + StartupTaskName() + #DQUOTE$

  LogLine("Disabling run at startup")
  ProcedureReturn Bool(RunAndCapture("schtasks.exe", delArgs) = 0)
EndProcedure

Procedure.i IsInStartup()
  Protected args.s = "/Query /TN " + #DQUOTE$ + StartupTaskName() + #DQUOTE$
  ProcedureReturn Bool(RunAndCapture("schtasks.exe", args) = 0)
EndProcedure

Procedure.s NormalizePath(path.s)
  Protected p.s = Trim(path)
  Protected prefix.s = ""
  Protected back.s = Chr(92)
  Protected dbl.s = back + back

  ; Collapse repeated backslashes, but preserve UNC prefix (\\Server\Share).
  If Left(p, 2) = dbl
    prefix = dbl
    p = Mid(p, 3)
    While Left(p, 1) = back
      p = Mid(p, 2)
    Wend
  EndIf

  While FindString(p, dbl, 1)
    p = ReplaceString(p, dbl, back)
  Wend

  ProcedureReturn prefix + p
EndProcedure

Procedure.i EnsureDirectoryTree(dirPath.s)
  Protected path.s = NormalizePath(Trim(dirPath))
  Protected root.s
  Protected tail.s
  Protected current.s
  Protected part.s
  Protected i.i
  Protected slashPos.i

  If path = ""
    ProcedureReturn #False
  EndIf

  If Right(path, 1) = "\" And Len(path) > 3
    path = Left(path, Len(path) - 1)
  EndIf

  If FileSize(path) = -2
    ProcedureReturn #True
  EndIf

  If Left(path, 2) = "\\"
    slashPos = FindString(path, "\", 3)
    If slashPos = 0
      ProcedureReturn #False
    EndIf
    slashPos = FindString(path, "\", slashPos + 1)
    If slashPos = 0
      ProcedureReturn Bool(FileSize(path) = -2)
    EndIf
    root = Left(path, slashPos)
    tail = Mid(path, slashPos + 1)
  ElseIf Len(path) >= 3 And Mid(path, 2, 2) = ":\"
    root = Left(path, 3)
    tail = Mid(path, 4)
  Else
    tail = path
  EndIf

  current = root
  For i = 1 To CountString(tail, "\") + 1
    part = Trim(StringField(tail, i, "\"))
    If part = ""
      Continue
    EndIf

    If current <> "" And Right(current, 1) <> "\"
      current + "\"
    EndIf
    current + part

    If FileSize(current) = -1
      CreateDirectory(current)
    EndIf

    If FileSize(current) <> -2
      ProcedureReturn #False
    EndIf
  Next

  ProcedureReturn Bool(FileSize(path) = -2)
EndProcedure

Procedure.i EnsureParentDirectoryForFile(filePath.s)
  Protected folder.s = GetPathPart(Trim(filePath))

  If folder = ""
    ProcedureReturn #True
  EndIf

  ProcedureReturn EnsureDirectoryTree(folder)
EndProcedure

Procedure.s GetWritableAppDataFolder()
  Protected appData.s = GetEnvironmentVariable("APPDATA")
  Protected folder.s

  If appData <> ""
    If Right(appData, 1) <> "\"
      appData + "\"
    EndIf

    folder = appData + #APP_NAME + "\"
    If EnsureDirectoryTree(folder)
      ProcedureReturn folder
    EndIf
  EndIf

  ProcedureReturn AppPath
EndProcedure
