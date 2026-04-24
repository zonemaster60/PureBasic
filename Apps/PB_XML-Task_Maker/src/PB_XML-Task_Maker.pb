; TaskXmlMaker.pb — PureBasic 6.30 beta 5
; Creates Task Scheduler XML and registers it via schtasks.exe
; Corrected version with EnableExplicit

EnableExplicit

;-----------------------------
; Constants
;-----------------------------

#TaskXmlNamespace = "http://schemas.microsoft.com/windows/2004/02/mit/task"
#TaskSchemaVersion = "1.6"

#APP_NAME = "PB_XML-Task_Maker"
#EMAIL_NAME = "zonemaster60@gmail.com"

#LogFileDefault = "PB_XML-Task_Maker.log"
#DefaultTaskName = "MyDailyTask"
#DefaultExe       = "C:\Tools\MyApp.exe"
#DefaultArgs      = "--quiet"
#DefaultWorkingDir= "C:\Tools"
#DefaultStartISO  = "2025-12-20T09:30:00"

Global LogBuffer.s = ""
Global LogFile.s = #LogFileDefault

Global version.s = "v1.0.0.5"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

;-----------------------------
; Structures
;-----------------------------

Structure TaskOptions
  taskName.s
  author.s
  description.s
  exePath.s
  arguments.s
  workingDir.s
  startBoundaryISO.s
  daily.i
  repeatISO.s
  runLevelHighest.i
  logonType.s
  strictPathValidation.i
  allowDemandStart.i
  allowHardTerminate.i
  runOnlyIfNetworkAvailable.i
  stopOnBattery.i
  disallowStartOnBattery.i
  multipleInstancesPolicy.s
EndStructure

;-----------------------------
; Logging
;-----------------------------

Procedure LogLine(text.s)
  Protected line.s = FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + " | " + text

  ; Add to memory buffer
  LogBuffer + line + #CRLF$

  ; Still show in debugger
  Debug line
EndProcedure

Procedure FlushLog()
  If LogFile = ""
    ProcedureReturn
  EndIf

  If LogBuffer = ""
    ProcedureReturn
  EndIf

  Protected file
  If FileSize(LogFile) = -1
    file = CreateFile(#PB_Any, LogFile)
  Else
    file = OpenFile(#PB_Any, LogFile, #PB_File_SharedRead)
  EndIf

  If file
    FileSeek(file, Lof(file))
    WriteString(file, LogBuffer)
    CloseFile(file)
    LogBuffer = "" ; Clear buffer after flush
  EndIf
EndProcedure

Procedure CleanupAndExit()
  FlushLog()

  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf

  End
EndProcedure

Procedure FatalError(userMessage.s, logMessage.s = "")
  If logMessage <> ""
    LogLine(logMessage)
  EndIf

  MessageRequester(#APP_NAME, userMessage, #PB_MessageRequester_Error)
  CleanupAndExit()
EndProcedure

;-----------------------------
; Command-line helpers
;-----------------------------

Procedure.s GetArg(flag.s, Default1.s)
  Protected i, c = CountProgramParameters()
  For i = 0 To c-1
    If LCase(ProgramParameter(i)) = LCase(flag)
      If i+1 < c
        ProcedureReturn ProgramParameter(i+1)
      EndIf
      ProcedureReturn Default1
    EndIf
  Next
  ProcedureReturn Default1
EndProcedure

;-----------------------------
; XML builder
;-----------------------------

Procedure.s EscapeXml(text.s)
  text = ReplaceString(text, "&", "&amp;")
  text = ReplaceString(text, "<", "&lt;")
  text = ReplaceString(text, ">", "&gt;")
  text = ReplaceString(text, Chr(34), "&quot;")
  text = ReplaceString(text, "'", "&apos;")
  ProcedureReturn text
EndProcedure

Procedure.s TaskBool(val.i)
  If val : ProcedureReturn "true" : Else : ProcedureReturn "false" : EndIf
EndProcedure

Procedure.i IsAllowedValue(value.s, allowedValues.s)
  Protected i, itemCount = CountString(allowedValues, "|") + 1

  For i = 1 To itemCount
    If LCase(StringField(allowedValues, i, "|")) = LCase(value)
      ProcedureReturn #True
    EndIf
  Next

  ProcedureReturn #False
EndProcedure

Procedure.i IsValidIsoDateTime(value.s)
  Protected i
  Protected year.i, month.i, day.i, hour.i, minute.i, second.i
  Protected maxDay.i

  If Len(value) <> 19
    ProcedureReturn #False
  EndIf

  If Mid(value, 5, 1) <> "-" Or Mid(value, 8, 1) <> "-" Or Mid(value, 11, 1) <> "T" Or Mid(value, 14, 1) <> ":" Or Mid(value, 17, 1) <> ":"
    ProcedureReturn #False
  EndIf

  For i = 1 To Len(value)
    Select i
      Case 5, 8, 11, 14, 17
      Default
        If FindString("0123456789", Mid(value, i, 1)) = 0
          ProcedureReturn #False
        EndIf
    EndSelect
  Next

  year = Val(Mid(value, 1, 4))
  month = Val(Mid(value, 6, 2))
  day = Val(Mid(value, 9, 2))
  hour = Val(Mid(value, 12, 2))
  minute = Val(Mid(value, 15, 2))
  second = Val(Mid(value, 18, 2))

  If year < 1601 Or month < 1 Or month > 12 Or hour > 23 Or minute > 59 Or second > 59
    ProcedureReturn #False
  EndIf

  Select month
    Case 4, 6, 9, 11
      maxDay = 30
    Case 2
      maxDay = 28
      If (year % 400 = 0) Or ((year % 4 = 0) And (year % 100 <> 0))
        maxDay = 29
      EndIf
    Default
      maxDay = 31
  EndSelect

  If day < 1 Or day > maxDay
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i IsValidIsoDuration(value.s)
  Protected upperValue.s = UCase(Trim(value))
  Protected pos.i
  Protected hasDesignator.i
  Protected inTimeSection.i
  Protected currentNumber.s = ""
  Protected currentChar.s

  If upperValue = ""
    ProcedureReturn #True
  EndIf

  If Left(upperValue, 1) <> "P"
    ProcedureReturn #False
  EndIf

  If FindString(upperValue, " ")
    ProcedureReturn #False
  EndIf

  If upperValue = "P"
    ProcedureReturn #False
  EndIf

  For pos = 2 To Len(upperValue)
    currentChar = Mid(upperValue, pos, 1)

    Select currentChar
      Case "T"
        If inTimeSection Or pos = Len(upperValue)
          ProcedureReturn #False
        EndIf
        inTimeSection = #True
        currentNumber = ""

      Case "Y", "M", "W", "D", "H", "S"
        If currentNumber = ""
          ProcedureReturn #False
        EndIf

        Select currentChar
          Case "Y", "W", "D"
            If inTimeSection
              ProcedureReturn #False
            EndIf
          Case "H", "S"
            If inTimeSection = #False
              ProcedureReturn #False
            EndIf
          Case "M"
            ; Months are only valid before T, minutes only after T.
        EndSelect

        currentNumber = ""
        hasDesignator = #True

      Default
        If FindString("0123456789", currentChar) = 0
          ProcedureReturn #False
        EndIf
        currentNumber + currentChar
    EndSelect
  Next

  If currentNumber <> "" Or hasDesignator = #False
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i IsReservedTaskName(value.s)
  Protected upperValue.s = UCase(Trim(value))

  Select upperValue
    Case "CON", "PRN", "AUX", "NUL", "COM1", "COM2", "COM3", "COM4", "COM5", "COM6", "COM7", "COM8", "COM9", "LPT1", "LPT2", "LPT3", "LPT4", "LPT5", "LPT6", "LPT7", "LPT8", "LPT9"
      ProcedureReturn #True
  EndSelect

  ProcedureReturn #False
EndProcedure

Procedure NormalizeTaskOptions(*opt.TaskOptions)
  *opt\taskName = Trim(*opt\taskName)
  *opt\author = Trim(*opt\author)
  *opt\description = Trim(*opt\description)
  *opt\exePath = Trim(*opt\exePath)
  *opt\arguments = Trim(*opt\arguments)
  *opt\workingDir = Trim(*opt\workingDir)
  *opt\startBoundaryISO = Trim(*opt\startBoundaryISO)
  *opt\repeatISO = UCase(Trim(*opt\repeatISO))
  *opt\logonType = Trim(*opt\logonType)
  *opt\multipleInstancesPolicy = Trim(*opt\multipleInstancesPolicy)

  If *opt\workingDir = "" And *opt\exePath <> ""
    *opt\workingDir = GetPathPart(*opt\exePath)
  EndIf
EndProcedure

Procedure.s SanitizeFileComponent(value.s)
  Protected result.s = Trim(value)

  result = ReplaceString(result, "\", "_")
  result = ReplaceString(result, "/", "_")
  result = ReplaceString(result, ":", "_")
  result = ReplaceString(result, "*", "_")
  result = ReplaceString(result, "?", "_")
  result = ReplaceString(result, Chr(34), "_")
  result = ReplaceString(result, "<", "_")
  result = ReplaceString(result, ">", "_")
  result = ReplaceString(result, "|", "_")

  If result = ""
    result = "task"
  EndIf

  ProcedureReturn result
EndProcedure

Procedure.s BuildTaskXml(*opt.TaskOptions)
  Protected xml.s
  
  ; Escape user inputs
  Protected author.s = EscapeXml(*opt\author)
  Protected desc.s = EscapeXml(*opt\description)
  Protected exe.s = EscapeXml(*opt\exePath)
  Protected args.s = EscapeXml(*opt\arguments)
  Protected wdir.s = EscapeXml(*opt\workingDir)
  Protected startBoundary.s = EscapeXml(*opt\startBoundaryISO)
  Protected logonType.s = EscapeXml(*opt\logonType)
  Protected multipleInstancesPolicy.s = EscapeXml(*opt\multipleInstancesPolicy)
  Protected repeatISO.s = EscapeXml(*opt\repeatISO)

  ; RegistrationInfo
  Protected regBlock.s = "    <RegistrationInfo>" + #CRLF$ +
                         "      <Author>" + author + "</Author>" + #CRLF$ +
                         "      <Description>" + desc + "</Description>" + #CRLF$ +
                         "    </RegistrationInfo>" + #CRLF$

  ; Principals
  Protected runLevelTag.s = ""
  If *opt\runLevelHighest
    runLevelTag = #CRLF$ + "        <RunLevel>HighestAvailable</RunLevel>"
  EndIf

  Protected principalsBlock.s = "    <Principals>" + #CRLF$ +
                                "      <Principal id="+Chr(34)+"Author"+Chr(34)+">" + #CRLF$ +
                                "        <UserId>S-1-5-18</UserId>" + #CRLF$ +
                                "        <LogonType>" + logonType + "</LogonType>" +
                                         runLevelTag + #CRLF$ +
                                "      </Principal>" + #CRLF$ +
                                "    </Principals>" + #CRLF$
  
  ; Settings
  Protected settingsBlock.s = "    <Settings>" + #CRLF$ +
                              "      <MultipleInstancesPolicy>" + multipleInstancesPolicy + "</MultipleInstancesPolicy>" + #CRLF$ +
                              "      <AllowStartOnDemand>" + TaskBool(*opt\allowDemandStart) + "</AllowStartOnDemand>" + #CRLF$ +
                              "      <AllowHardTerminate>" + TaskBool(*opt\allowHardTerminate) + "</AllowHardTerminate>" + #CRLF$ +
                              "      <RunOnlyIfNetworkAvailable>" + TaskBool(*opt\runOnlyIfNetworkAvailable) + "</RunOnlyIfNetworkAvailable>" + #CRLF$ +
                              "      <DisallowStartIfOnBatteries>" + TaskBool(*opt\disallowStartOnBattery) + "</DisallowStartIfOnBatteries>" + #CRLF$ +
                              "      <StopIfGoingOnBatteries>" + TaskBool(*opt\stopOnBattery) + "</StopIfGoingOnBatteries>" + #CRLF$ +
                              "      <Enabled>true</Enabled>" + #CRLF$ +
                              "    </Settings>" + #CRLF$

  ; Trigger
  Protected triggerBlock.s
  Protected repetitionBlock.s = ""
  If repeatISO <> ""
    repetitionBlock = "        <Repetition>" + #CRLF$ +
                      "          <Interval>" + repeatISO + "</Interval>" + #CRLF$ +
                      "        </Repetition>" + #CRLF$
  EndIf

  If *opt\daily
    triggerBlock = "    <Triggers>" + #CRLF$ +
                   "      <CalendarTrigger>" + #CRLF$ +
                   "        <StartBoundary>" + startBoundary + "</StartBoundary>" + #CRLF$ +
                   repetitionBlock +
                   "        <ScheduleByDay><DaysInterval>1</DaysInterval></ScheduleByDay>" + #CRLF$ +
                   "      </CalendarTrigger>" + #CRLF$ +
                   "    </Triggers>" + #CRLF$
  Else
    triggerBlock = "    <Triggers>" + #CRLF$ +
                   "      <TimeTrigger>" + #CRLF$ +
                   "        <StartBoundary>" + startBoundary + "</StartBoundary>" + #CRLF$ +
                   repetitionBlock +
                   "      </TimeTrigger>" + #CRLF$ +
                   "    </Triggers>" + #CRLF$
  EndIf

  ; Actions
  Protected actionsBlock.s = "    <Actions Context="+Chr(34)+"Author"+Chr(34)+">" + #CRLF$ +
                             "      <Exec>" + #CRLF$ +
                             "        <Command>" + exe + "</Command>" + #CRLF$
  If args <> ""
    actionsBlock + "        <Arguments>" + args + "</Arguments>" + #CRLF$
  EndIf
  If wdir <> ""
    actionsBlock + "        <WorkingDirectory>" + wdir + "</WorkingDirectory>" + #CRLF$
  EndIf
  actionsBlock + "      </Exec>" + #CRLF$ +
                 "    </Actions>" + #CRLF$

  ; Final XML
  xml = "<?xml version="+Chr(34)+"1.0"+Chr(34)+" encoding="+Chr(34)+"UTF-16"+Chr(34)+"?>" + #CRLF$ +
        "<Task version="+Chr(34)+ #TaskSchemaVersion + Chr(34)+" xmlns="+Chr(34)+ #TaskXmlNamespace +Chr(34)+">" + #CRLF$ +
        regBlock + principalsBlock + settingsBlock + triggerBlock + actionsBlock +
        "</Task>" + #CRLF$

  ProcedureReturn xml
EndProcedure

;-----------------------------
; Save XML
;-----------------------------

Procedure.s SaveXmlToTemp(xml.s, baseName.s)
  Protected tmpDir.s = GetTemporaryDirectory()
  Protected sanitizedBaseName.s = SanitizeFileComponent(baseName)
  Protected filePath.s
  Protected file

  If IsReservedTaskName(sanitizedBaseName)
    sanitizedBaseName = sanitizedBaseName + "_task"
  EndIf

  filePath = tmpDir + sanitizedBaseName + ".xml"
  file = CreateFile(#PB_Any, filePath)

  If file
    WriteStringFormat(file, #PB_Unicode)
    WriteString(file, xml)
    CloseFile(file)
    LogLine("XML saved: " + filePath)

    If CopyFile(filePath, AppPath + #APP_NAME + ".xml") = #False
      LogLine("WARNING: Unable to copy XML beside executable.")
    EndIf

    ProcedureReturn filePath
  EndIf

  LogLine("ERROR: Unable to create XML file at " + filePath)
  ProcedureReturn ""
EndProcedure

;-----------------------------
; Register task via schtasks.exe
;-----------------------------

Procedure.i RegisterTaskFromXml(xmlPath.s, taskName.s)
  Protected cmd.s = "cmd.exe"
  ; Use cmd /C so stderr is redirected to stdout for consistent logging.
  Protected taskCommand.s = "schtasks.exe /Create /F /TN " + Chr(34) + taskName + Chr(34) + " /XML " + Chr(34) + xmlPath + Chr(34) + " 2>&1"
  Protected args.s = "/C " + taskCommand

  LogLine("Executing: " + cmd + " " + args)

  Protected prog = RunProgram(cmd, args, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If prog
    Protected out.s
    While ProgramRunning(prog)
      If AvailableProgramOutput(prog)
        out = ReadProgramString(prog)
        If out <> ""
          LogLine("SCHTASKS: " + out)
        EndIf
      Else
        Delay(10)
      EndIf
    Wend
    
    ; Drain any remaining output
    While AvailableProgramOutput(prog)
      out = ReadProgramString(prog)
      If out <> ""
        LogLine("SCHTASKS: " + out)
      EndIf
    Wend
    
    Protected exitCode = ProgramExitCode(prog)
    CloseProgram(prog)
    LogLine("cmd.exe finished with exit code: " + Str(exitCode))
    
    If exitCode = 0
      ProcedureReturn #True
    Else
      LogLine("ERROR: schtasks returned non-zero exit code.")
    EndIf
  Else
    LogLine("ERROR: Failed to start cmd.exe for schtasks execution.")
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.i LoadTaskOptions(*opt.TaskOptions, iniFile.s)
  If OpenPreferences(iniFile)
    PreferenceGroup("Task")
    *opt\taskName                 = ReadPreferenceString("Name", #DefaultTaskName)
    *opt\author                   = ReadPreferenceString("Author", "David Scouten")
    *opt\description              = ReadPreferenceString("Description", "Generated by PB_XML-Task_Maker")
    *opt\exePath                  = ReadPreferenceString("ExePath", #DefaultExe)
    *opt\arguments                = ReadPreferenceString("Arguments", #DefaultArgs)
    *opt\workingDir               = ReadPreferenceString("WorkingDir", #DefaultWorkingDir)
    *opt\startBoundaryISO         = ReadPreferenceString("StartBoundaryISO", #DefaultStartISO)
    *opt\daily                    = ReadPreferenceInteger("Daily", 0)
    *opt\repeatISO                = ReadPreferenceString("RepeatISO", "")
    *opt\runLevelHighest          = ReadPreferenceInteger("RunLevelHighest", 0)
    *opt\logonType                = ReadPreferenceString("LogonType", "ServiceAccount")
    *opt\strictPathValidation     = ReadPreferenceInteger("StrictPathValidation", 0)
    *opt\allowDemandStart         = ReadPreferenceInteger("AllowDemandStart", 1)
    *opt\allowHardTerminate       = ReadPreferenceInteger("AllowHardTerminate", 1)
    *opt\runOnlyIfNetworkAvailable= ReadPreferenceInteger("RunOnlyIfNetworkAvailable", 0)
    *opt\stopOnBattery            = ReadPreferenceInteger("StopOnBattery", 0)
    *opt\disallowStartOnBattery   = ReadPreferenceInteger("DisallowStartOnBattery", 0)
    *opt\multipleInstancesPolicy  = ReadPreferenceString("MultipleInstancesPolicy", "IgnoreNew")
    ClosePreferences()

    NormalizeTaskOptions(*opt)

    ; Basic Validation
    If *opt\taskName = ""
      LogLine("ERROR: Task name cannot be empty.")
      ProcedureReturn #False
    EndIf
    If FindString(*opt\taskName, Chr(34)) Or FindString(*opt\taskName, #CR$) Or FindString(*opt\taskName, #LF$)
      LogLine("ERROR: Task name contains invalid characters.")
      ProcedureReturn #False
    EndIf
    If *opt\exePath = ""
      LogLine("ERROR: Executable path cannot be empty.")
      ProcedureReturn #False
    EndIf
    If FileSize(*opt\exePath) < 0
      If *opt\strictPathValidation
        LogLine("ERROR: Executable path not found: " + *opt\exePath)
        ProcedureReturn #False
      Else
        LogLine("WARNING: Executable path not found at load time: " + *opt\exePath)
      EndIf
    EndIf
    If *opt\workingDir <> "" And FileSize(*opt\workingDir) <> -2
      If *opt\strictPathValidation
        LogLine("ERROR: Working directory not found: " + *opt\workingDir)
        ProcedureReturn #False
      Else
        LogLine("WARNING: Working directory not found at load time: " + *opt\workingDir)
      EndIf
    EndIf
    If IsValidIsoDateTime(*opt\startBoundaryISO) = #False
      LogLine("ERROR: StartBoundaryISO must use yyyy-mm-ddThh:ii:ss format.")
      ProcedureReturn #False
    EndIf
    If IsValidIsoDuration(*opt\repeatISO) = #False
      LogLine("ERROR: RepeatISO must be an ISO-8601 duration such as PT15M.")
      ProcedureReturn #False
    EndIf
    If IsAllowedValue(*opt\multipleInstancesPolicy, "Parallel|Queue|IgnoreNew|StopExisting") = #False
      LogLine("WARNING: Invalid MultipleInstancesPolicy. Falling back to IgnoreNew.")
      *opt\multipleInstancesPolicy = "IgnoreNew"
    EndIf
    If IsAllowedValue(*opt\logonType, "None|Password|S4U|InteractiveToken|Group|ServiceAccount|InteractiveTokenOrPassword") = #False
      LogLine("WARNING: Invalid LogonType. Falling back to ServiceAccount.")
      *opt\logonType = "ServiceAccount"
    EndIf
    If LCase(*opt\logonType) <> "serviceaccount"
      LogLine("WARNING: SYSTEM tasks require ServiceAccount logon type. Falling back to ServiceAccount.")
      *opt\logonType = "ServiceAccount"
    EndIf

    ProcedureReturn #True
  EndIf

  LogLine("ERROR: Unable to open preferences file: " + iniFile)
  ProcedureReturn #False
EndProcedure

;-----------------------------
; Main
;-----------------------------

LogFile = GetArg("--log", #LogFileDefault)
LogLine("Starting " + #APP_NAME)

Define opts.TaskOptions
If LoadTaskOptions(@opts, AppPath + #APP_NAME + ".ini") = #False
  FatalError("Failed to load " + AppPath + #APP_NAME + ".ini")
EndIf

; Build XML
Define xml.s = BuildTaskXml(@opts)
If xml = ""
  FatalError("XML build failed.", "ERROR: XML build failed.")
EndIf

Define xmlPath.s = SaveXmlToTemp(xml, ReplaceString(opts\taskName, " ", "_"))
If xmlPath = ""
  FatalError("Failed to write XML to temp.")
EndIf

; Registration via schtasks
Define registrationOk.i = RegisterTaskFromXml(xmlPath, opts\taskName)

If registrationOk
  LogLine("SUCCESS: Task registered: " + opts\taskName)
  If DeleteFile(xmlPath) = #False
    LogLine("WARNING: Unable to delete temp XML: " + xmlPath)
  EndIf
Else
  LogLine("ERROR: Task registration failed.")
EndIf

LogLine("Done.")
FlushLog()

If registrationOk
  MessageRequester("Info", #APP_NAME + " - " + version + #CRLF$ +
                           "Task registered successfully: " + opts\taskName + #CRLF$ +
                           "-----------------------------------" + #CRLF$ +
                           "Contact: " + #EMAIL_NAME + #CRLF$ +
                           "Website: https://github.com/zonemaster60" + #CRLF$ +
                           "Task: schtasks /run /tn " + Chr(34) + opts\taskName + Chr(34), #PB_MessageRequester_Info)
Else
  MessageRequester(#APP_NAME, "Task registration failed. See log: " + LogFile, #PB_MessageRequester_Error)
EndIf

CleanupAndExit()
; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 468
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_XML-Task_Maker.ico
; Executable = ..\PB_XML-Task_Maker.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,5
; VersionField1 = 1,0,0,5
; VersionField2 = ZoneSoft
; VersionField3 = PB_XML-Task_Maker
; VersionField4 = 1.0.0.5
; VersionField5 = 1.0.0.5
; VersionField6 = Creates Tasks for use with Task Scheduler
; VersionField7 = PB_XML-Task_Maker
; VersionField8 = PB_XML-Task_Maker.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
