; TaskXmlMaker.pb — PureBasic 6.30 beta 5
; Creates Task Scheduler XML and registers it via schtasks.exe
; Corrected version with EnableExplicit

EnableExplicit

;-----------------------------
; Constants
;-----------------------------

#SECURITY_MAX_SID_SIZE = 68
#TOKEN_QUERY = $0008
#TaskXmlNamespace = "http://schemas.microsoft.com/windows/2004/02/mit/task"
#TaskSchemaVersion = "1.6"

#APP_NAME = "XML-Task_Maker"
#EMAIL_NAME = "zonemaster60@gmail.com"

#LogFileDefault = "XML-Task_Maker.log"
#DefaultTaskName = "MyDailyTask"
#DefaultExe       = "C:\Tools\MyApp.exe"
#DefaultArgs      = "--quiet"
#DefaultWorkingDir= "C:\Tools"
#DefaultStartISO  = "2025-12-20T09:30:00"

Global LogBuffer.s = ""
Global LogFile.s = #LogFileDefault

Global version.s = "v1.0.0.3"
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
; Imports (must be global)
;-----------------------------

Import "Advapi32.lib"
  AllocateAndInitializeSid(*pIdentifierAuthority, nSubAuthorityCount.l, n0.l, n1.l, n2.l, n3.l, n4.l, n5.l, n6.l, n7.l, *pSid)
  FreeSid(*Sid)
  CheckTokenMembership(TokenHandle.i, Sid.i, *IsMember)
  OpenProcessToken(hProcess.i, DesiredAccess.i, *TokenHandle)
EndImport

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

  Protected file = OpenFile(#PB_Any, LogFile, #PB_File_SharedRead | #PB_File_NoBuffering)
  If file
    FileSeek(file, Lof(file))
    WriteString(file, LogBuffer)
    CloseFile(file)
    LogBuffer = "" ; Clear buffer after flush
  EndIf
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

Procedure.i HasSwitch(flag.s)
  Protected i, c = CountProgramParameters()
  For i = 0 To c-1
    If LCase(ProgramParameter(i)) = LCase(flag)
      ProcedureReturn #True
    EndIf
  Next
  ProcedureReturn #False
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

Procedure.s BuildTaskXml(*opt.TaskOptions)
  Protected xml.s
  
  ; Escape user inputs
  Protected author.s = EscapeXml(*opt\author)
  Protected desc.s = EscapeXml(*opt\description)
  Protected exe.s = EscapeXml(*opt\exePath)
  Protected args.s = EscapeXml(*opt\arguments)
  Protected wdir.s = EscapeXml(*opt\workingDir)

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
                                "        <LogonType>" + *opt\logonType + "</LogonType>" +
                                         runLevelTag + #CRLF$ +
                                "      </Principal>" + #CRLF$ +
                                "    </Principals>" + #CRLF$
  
  ; Settings
  Protected settingsBlock.s = "    <Settings>" + #CRLF$ +
                              "      <MultipleInstancesPolicy>" + *opt\multipleInstancesPolicy + "</MultipleInstancesPolicy>" + #CRLF$ +
                              "      <AllowStartOnDemand>" + TaskBool(*opt\allowDemandStart) + "</AllowStartOnDemand>" + #CRLF$ +
                              "      <AllowHardTerminate>" + TaskBool(*opt\allowHardTerminate) + "</AllowHardTerminate>" + #CRLF$ +
                              "      <RunOnlyIfNetworkAvailable>" + TaskBool(*opt\runOnlyIfNetworkAvailable) + "</RunOnlyIfNetworkAvailable>" + #CRLF$ +
                              "      <DisallowStartIfOnBatteries>" + TaskBool(*opt\disallowStartOnBattery) + "</DisallowStartIfOnBatteries>" + #CRLF$ +
                              "      <StopIfGoingOnBatteries>" + TaskBool(*opt\stopOnBattery) + "</StopIfGoingOnBatteries>" + #CRLF$ +
                              "      <Enabled>true</Enabled>" + #CRLF$ +
                              "    </Settings>" + #CRLF$

  ; Trigger
  Protected triggerBlock.s
  If *opt\daily
    triggerBlock = "    <Triggers>" + #CRLF$ +
                   "      <CalendarTrigger>" + #CRLF$ +
                   "        <StartBoundary>" + *opt\startBoundaryISO + "</StartBoundary>" + #CRLF$ +
                   "        <ScheduleByDay><DaysInterval>1</DaysInterval></ScheduleByDay>" + #CRLF$ +
                   "      </CalendarTrigger>" + #CRLF$ +
                   "    </Triggers>" + #CRLF$
  Else
    triggerBlock = "    <Triggers>" + #CRLF$ +
                   "      <TimeTrigger>" + #CRLF$ +
                   "        <StartBoundary>" + *opt\startBoundaryISO + "</StartBoundary>" + #CRLF$ +
                   "      </TimeTrigger>" + #CRLF$ +
                   "    </Triggers>" + #CRLF$
  EndIf

  ; Actions
  Protected actionsBlock.s = "    <Actions Context="+Chr(34)+"Author"+Chr(34)+">" + #CRLF$ +
                             "      <Exec>" + #CRLF$ +
                             "        <Command>" + exe + "</Command>" + #CRLF$
  If args <> "" : actionsBlock + "        <Arguments>" + args + "</Arguments>" + #CRLF$ : EndIf
  If wdir <> "" : actionsBlock + "        <WorkingDirectory>" + wdir + "</WorkingDirectory>" + #CRLF$ : EndIf
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
  Protected filePath.s = tmpDir + baseName + ".xml"
  If CreateFile(1, filePath)
    WriteString(1, xml)
    CloseFile(1)
    LogLine("XML saved: " + filePath)
    CopyFile(filePath, AppPath + #APP_NAME + ".xml")
    ProcedureReturn filePath
  EndIf
    LogLine("ERROR: Unable to create XML file at " + filePath)
  ProcedureReturn ""
EndProcedure

;-----------------------------
; Register task via schtasks.exe
;-----------------------------

Procedure.i RegisterTaskFromXml(xmlPath.s, taskName.s)
  Protected cmd.s = "schtasks.exe"
  ; Added /F to force creation if it already exists
  Protected args.s = "/Create /F /TN " + Chr(34) + taskName + Chr(34) + " /XML " + Chr(34) + xmlPath + Chr(34)

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
    LogLine("schtasks.exe finished with exit code: " + Str(exitCode))
    
    If exitCode = 0
      ProcedureReturn #True
    Else
      LogLine("ERROR: schtasks returned non-zero exit code.")
    EndIf
  Else
    LogLine("ERROR: Failed to start schtasks.exe")
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure LoadTaskOptions(*opt.TaskOptions, iniFile.s)
  If OpenPreferences(iniFile)
    PreferenceGroup("Task")
    *opt\taskName                 = ReadPreferenceString("Name", #DefaultTaskName)
    *opt\author                   = ReadPreferenceString("Author", "David Scouten")
    *opt\description              = ReadPreferenceString("Description", "Generated by PureBasic TaskXmlMaker")
    *opt\exePath                  = ReadPreferenceString("ExePath", #DefaultExe)
    *opt\arguments                = ReadPreferenceString("Arguments", #DefaultArgs)
    *opt\workingDir               = ReadPreferenceString("WorkingDir", #DefaultWorkingDir)
    *opt\startBoundaryISO         = ReadPreferenceString("StartBoundaryISO", #DefaultStartISO)
    *opt\daily                    = ReadPreferenceInteger("Daily", 0)
    *opt\repeatISO                = ReadPreferenceString("RepeatISO", "")
    *opt\runLevelHighest          = ReadPreferenceInteger("RunLevelHighest", 0)
    *opt\logonType                = ReadPreferenceString("LogonType", "InteractiveToken")
    *opt\allowDemandStart         = ReadPreferenceInteger("AllowDemandStart", 1)
    *opt\allowHardTerminate       = ReadPreferenceInteger("AllowHardTerminate", 1)
    *opt\runOnlyIfNetworkAvailable= ReadPreferenceInteger("RunOnlyIfNetworkAvailable", 0)
    *opt\stopOnBattery            = ReadPreferenceInteger("StopOnBattery", 0)
    *opt\disallowStartOnBattery   = ReadPreferenceInteger("DisallowStartOnBattery", 0)
    *opt\multipleInstancesPolicy  = ReadPreferenceString("MultipleInstancesPolicy", "IgnoreNew")
    ClosePreferences()

    ; Basic Validation
    If *opt\taskName = ""
      LogLine("ERROR: Task name cannot be empty.")
      ProcedureReturn #False
    EndIf
    If *opt\exePath = ""
      LogLine("ERROR: Executable path cannot be empty.")
      ProcedureReturn #False
    EndIf

    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

;-----------------------------
; Main
;-----------------------------

LogFile = GetArg("--log", #LogFileDefault)
LogLine("Starting " + #APP_NAME)

Define opts.TaskOptions
If LoadTaskOptions(@opts, AppPath + #APP_NAME + ".ini") = #False
  MessageRequester(#APP_NAME, "Failed To load " + AppPath + #APP_NAME + ".ini", #PB_MessageRequester_Error)
  CloseHandle_(hMutex)
  End
EndIf

; Build XML
Define xml.s = BuildTaskXml(@opts)
If xml = ""
  LogLine("ERROR: XML build failed.")
  MessageRequester(#APP_NAME, "XML build failed.", #PB_MessageRequester_Error)
  CloseHandle_(hMutex)
  End
EndIf

Define xmlPath.s = SaveXmlToTemp(xml, ReplaceString(opts\taskName, " ", "_"))
If xmlPath = ""
  MessageRequester(#APP_NAME, "Failed To write XML To temp.", #PB_MessageRequester_Error)
  CloseHandle_(hMutex)
  End
EndIf

; Registration via schtasks
If RegisterTaskFromXml(xmlPath, opts\taskName)
  LogLine("SUCCESS: Task registered: " + opts\taskName)
  FlushLog() ; Flush before final message
  MessageRequester(#APP_NAME, "Task registered successfully: " + opts\taskName, #PB_MessageRequester_Info)
Else
  LogLine("ERROR: Task registration failed.")
  FlushLog()
  MessageRequester(#APP_NAME, "Task registration failed. See log: " + LogFile, #PB_MessageRequester_Error)
EndIf

LogLine("Done.")
FlushLog()
MessageRequester("Info", #APP_NAME + " - " + version + #CRLF$ +
                         "Thank you for using this free tool!" + #CRLF$ +
                         "-----------------------------------" + #CRLF$ +
                         "Contact: " + #EMAIL_NAME + #CRLF$ +
                         "Website: https://github.com/zonemaster60" + #CRLF$ +
                         "Task: schtasks /run /tn " + Chr(34) + opts\taskName + Chr(34), #PB_MessageRequester_Info)
CloseHandle_(hMutex)
End
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 28
; FirstLine = 9
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = XML-Task_Maker.ico
; Executable = ..\XML-Task_Maker.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,3
; VersionField1 = 1,0,0,3
; VersionField2 = ZoneSoft
; VersionField3 = XML-Task_Maker
; VersionField4 = 1.0.0.3
; VersionField5 = 1.0.0.3
; VersionField6 = Creates Tasks for use with Task Scheduler
; VersionField7 = XML-Task_Maker
; VersionField8 = XML-Task_Maker.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60