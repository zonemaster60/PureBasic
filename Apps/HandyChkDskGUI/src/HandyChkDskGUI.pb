; HandyChkDskGUI - PureBasic 6.30 Beta 4 compatible

EnableExplicit

; -------------------------------
; Constants (IDs)
; -------------------------------

Enumeration
  #Window_Main
EndEnumeration

Enumeration 1
  #Timer_OutputFlush
EndEnumeration

Enumeration
  #Combo_Drive
  #Check_Fix
  #Check_Scan
  #Check_Verbose
  #Check_ForceDismount
  #Check_BadSectors
  #Check_SpotFix
  #Button_Run
  #Button_Cancel
  #Button_SaveLog
  #Button_About
  #Button_Exit
  #Editor_Output
  #StatusBar
EndEnumeration

Structure ChkdskParams
  drive$
  fixFlag.i
  scanFlag.i
  verboseFlag.i
  forceFlag.i
  badFlag.i
  spotfixFlag.i
EndStructure

Global ChkdskThreadID.i
Global ChkdskStop.i
Global ChkdskRunning.i
Global NewList ChkdskProcessList.i()
Global NewList PendingOutputLines.s()
Global OutputMutex.i = CreateMutex()
Global ProcessListMutex.i = CreateMutex()

#APP_NAME   = "HandyChkDskGUI"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.4"
Global AppPath.s        = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; -------------------------------
; Helpers
; -------------------------------

Declare KillOrphanProcesses()
Declare FlushOutputQueue()
Declare CleanupAndExit()

Procedure.i ConfirmExit()
  Protected prompt$ = "Do you want to exit now?"

  If ChkdskRunning
    prompt$ = "CHKDSK is still running." + #CRLF$ + "Do you want to stop it and exit?"
  EndIf

  ProcedureReturn Bool(MessageRequester("Exit", prompt$, #PB_MessageRequester_YesNo | #PB_MessageRequester_Info) = #PB_MessageRequester_Yes)
EndProcedure

Procedure CleanupApplication()
  ChkdskStop = #True

  If ChkdskRunning
    If WaitThread(ChkdskThreadID, 1000) = 0
      KillOrphanProcesses()
    EndIf
  Else
    KillOrphanProcesses()
  EndIf

  FlushOutputQueue()

  If IsWindow(#Window_Main)
    RemoveWindowTimer(#Window_Main, #Timer_OutputFlush)
  EndIf

  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf

EndProcedure

Procedure CleanupAndExit()
  CleanupApplication()
  End
EndProcedure

Procedure AppendOutputLine(line$)
  ; Safe append to EditorGadget text using SendMessage for better performance and less flickering
  If IsGadget(#Editor_Output)
    Protected hGadget = GadgetID(#Editor_Output)
    Protected text$ = line$ + #CRLF$
    SendMessage_(hGadget, #EM_SETSEL, -1, -1)
    SendMessage_(hGadget, #EM_REPLACESEL, 0, @text$)
  EndIf
EndProcedure

Procedure QueueOutputLine(line$)
  If OutputMutex
    LockMutex(OutputMutex)
    AddElement(PendingOutputLines())
    PendingOutputLines() = line$
    UnlockMutex(OutputMutex)
  EndIf
EndProcedure

Procedure FlushOutputQueue()
  Protected outputChunk$

  If IsGadget(#Editor_Output) = 0 Or OutputMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(OutputMutex)
  ForEach PendingOutputLines()
    outputChunk$ + PendingOutputLines() + #CRLF$
  Next
  ClearList(PendingOutputLines())
  UnlockMutex(OutputMutex)

  If outputChunk$ <> ""
    Protected hGadget = GadgetID(#Editor_Output)
    SendMessage_(hGadget, #EM_SETSEL, -1, -1)
    SendMessage_(hGadget, #EM_REPLACESEL, 0, @outputChunk$)
  EndIf
EndProcedure

Procedure.s BuildChkdskCommand(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag)
  Protected cmd$ = "chkdsk " + drive$
  If fixFlag       : cmd$ + " /f" : EndIf   ; Fix - reboot required
  If scanFlag      : cmd$ + " /scan" : EndIf; online Scan
  If verboseFlag   : cmd$ + " /v" : EndIf   ; Verbose output
  If forceFlag     : cmd$ + " /x" : EndIf   ; Force unmount
  If badFlag       : cmd$ + " /r" : EndIf   ; Check bad sectors
  If spotfixFlag   : cmd$ + " /spotfix" : EndIf ; Spotfix
  ProcedureReturn cmd$
EndProcedure

Procedure.i ValidateDrive(drive$)
  Protected driveLetter$

  ; Expect "X:" format
  drive$ = UCase(Trim(drive$))
  driveLetter$ = Left(drive$, 1)
  If Len(drive$) = 2 And Mid(drive$, 2, 1) = ":" And driveLetter$ >= "A" And driveLetter$ <= "Z"
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.i DriveExists(drive$)
  Protected root$

  drive$ = UCase(Trim(drive$))
  If ValidateDrive(drive$) = #False
    ProcedureReturn #False
  EndIf

  root$ = drive$ + "\"
  ProcedureReturn Bool(FileSize(root$) <> -1)
EndProcedure

Procedure.s ValidateChkdskRequest(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag)
  drive$ = UCase(Trim(drive$))

  If ValidateDrive(drive$) = #False
    ProcedureReturn "Invalid drive format! Select a drive like C:."
  EndIf

  If DriveExists(drive$) = #False
    ProcedureReturn "The selected drive is not currently available."
  EndIf

  If scanFlag And spotfixFlag
    ProcedureReturn "Cannot combine /scan with /spotfix."
  EndIf

  If scanFlag And forceFlag
    ProcedureReturn "Cannot combine /scan with /x because /scan keeps the volume online."
  EndIf

  If scanFlag And badFlag
    ProcedureReturn "Cannot combine /scan with /r because /r requires offline disk repair."
  EndIf

  If spotfixFlag And badFlag
    ProcedureReturn "Cannot combine /spotfix with /r."
  EndIf

  ProcedureReturn ""
EndProcedure

Procedure.i RequestCancelChkDsk()
  If ChkdskRunning = #False
    StatusBarText(#StatusBar, 0, "Nothing is running.")
    ProcedureReturn #False
  EndIf

  ChkdskStop = #True
  DisableGadget(#Button_Cancel, #True)
  StatusBarText(#StatusBar, 0, "Cancelling CHKDSK...")
  ProcedureReturn #True
EndProcedure

Procedure.i ScheduleSystemDriveRepair(drive$)
  Protected result.i

  drive$ = UCase(Trim(drive$))
  result = RunProgram("cmd.exe", "/c fsutil dirty set " + drive$, "", #PB_Program_Wait | #PB_Program_Hide)
  If result = 0
    AppendOutputLine("Failed to mark " + drive$ + " dirty for reboot repair.")
    StatusBarText(#StatusBar, 0, "Failed to schedule reboot repair!")
    ProcedureReturn #False
  EndIf

  result = RunProgram("shutdown.exe", "/r /t 15", "", #PB_Program_Wait | #PB_Program_Hide)
  If result = 0
    AppendOutputLine("Failed to schedule the reboot.")
    StatusBarText(#StatusBar, 0, "Failed to schedule reboot!")
    ProcedureReturn #False
  EndIf

  AppendOutputLine("System restart scheduled in 15 seconds for offline CHKDSK.")
  StatusBarText(#StatusBar, 0, "Restart scheduled.")
  ProcedureReturn #True
EndProcedure

Procedure SaveLogToFile(output$)
  Protected logFile$ = #APP_NAME + "-" + FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss]", Date()) + ".log"
  Protected saveFile$ = SaveFileRequester("Save CHKDSK Log", logFile$, "Log Files (*.log)|*.log|Text Files (*.txt)|*.txt", 0)
  
  If saveFile$
    If GetExtensionPart(saveFile$) = ""
      saveFile$ + ".log"
    EndIf
    
    If CreateFile(0, saveFile$)
      WriteString(0, output$, #PB_UTF8)
      CloseFile(0)
      StatusBarText(#StatusBar, 0, "Log file saved: " + GetFilePart(saveFile$))
    Else
      StatusBarText(#StatusBar, 0, "Failed to save log!")
    EndIf
  EndIf
EndProcedure

; -------------------------------------------------------
; Watchdog: Kill orphaned cmd.exe and chkdsk.exe processes
; -------------------------------------------------------

Procedure AddManagedProcess(processHandle.i)
  If processHandle > 0 And ProcessListMutex
    LockMutex(ProcessListMutex)
    AddElement(ChkdskProcessList())
    ChkdskProcessList() = processHandle
    UnlockMutex(ProcessListMutex)
  EndIf
EndProcedure

Procedure RemoveManagedProcess(processHandle.i)
  If processHandle > 0 And ProcessListMutex
    LockMutex(ProcessListMutex)
    ForEach ChkdskProcessList()
      If ChkdskProcessList() = processHandle
        DeleteElement(ChkdskProcessList())
        Break
      EndIf
    Next
    UnlockMutex(ProcessListMutex)
  EndIf
EndProcedure

Procedure KillOrphanProcesses()
  Protected processHandle.i

  ; Only kill processes that we started
  If ProcessListMutex = 0
    ProcedureReturn
  EndIf

  LockMutex(ProcessListMutex)
  ForEach ChkdskProcessList()
    processHandle = ChkdskProcessList()
    If processHandle
      TerminateProcess_(processHandle, 0)
    EndIf
  Next
  ClearList(ChkdskProcessList())
  UnlockMutex(ProcessListMutex)
EndProcedure

; -------------------------------
; Drive enumeration (robust A–Z scan)
; -------------------------------

Procedure PopulateDrives()
  ; Enumerate A-Z, check existence and type; add as "X:"
  Protected i, root$, type.i

  ClearGadgetItems(#Combo_Drive)

  For i = 65 To 90
    root$ = Chr(i) + ":\"
    If FileSize(root$) <> -1
      type = GetDriveType_(@root$)
      Select type
        Case #DRIVE_FIXED, #DRIVE_REMOVABLE, #DRIVE_CDROM, #DRIVE_REMOTE, #DRIVE_RAMDISK
          AddGadgetItem(#Combo_Drive, -1, Left(root$, 2)) ; "X:"
      EndSelect
    EndIf
  Next

  ; Preselect C: if present; otherwise first item
  Protected count = CountGadgetItems(#Combo_Drive), idx
  If count > 0
    For idx = 0 To count - 1
      If GetGadgetItemText(#Combo_Drive, idx) = "C:"
        SetGadgetState(#Combo_Drive, idx)
        Break
      EndIf
    Next
    If GetGadgetState(#Combo_Drive) = -1
      SetGadgetState(#Combo_Drive, 0)
    EndIf
  Else
    AddGadgetItem(#Combo_Drive, -1, "")
    SetGadgetState(#Combo_Drive, 0)
  EndIf
EndProcedure

; -------------------------------
; Core execution
; -------------------------------

Procedure RunChkDskThread(*p.ChkdskParams)
  Protected programID.i
  Protected processHandle.i
  Protected line$
  Protected cmd$
  
  cmd$ = BuildChkdskCommand(*p\drive$, *p\fixFlag, *p\scanFlag, *p\verboseFlag, *p\forceFlag, *p\badFlag, *p\spotfixFlag)
  
  programID = RunProgram("cmd.exe", "/c " + cmd$, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If programID
    processHandle = ProgramID(programID)
    AddManagedProcess(processHandle)
    
    While ProgramRunning(programID)
      If ChkdskStop
        KillProgram(programID)
        Break
      EndIf

      While AvailableProgramOutput(programID)
        line$ = ReadProgramString(programID)
        If line$ <> ""
          QueueOutputLine(line$)
        EndIf
      Wend

      Delay(10)
    Wend

    While AvailableProgramOutput(programID)
      line$ = ReadProgramString(programID)
      If line$ <> ""
        QueueOutputLine(line$)
      EndIf
    Wend
    
    CloseProgram(programID)
    RemoveManagedProcess(processHandle)
    QueueOutputLine("")
    If ChkdskStop
      QueueOutputLine("CHKDSK cancelled.")
    Else
      QueueOutputLine("CHKDSK completed.")
    EndIf
  Else
    QueueOutputLine("Failed to start CHKDSK! Try running as administrator.")
  EndIf

  ChkdskRunning = #False
  PostEvent(#PB_Event_Gadget, #Window_Main, #Button_Run, #PB_EventType_FirstCustomValue) ; Signal completion
  FreeMemory(*p)
EndProcedure

Procedure RunChkDsk(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag)
  Protected *p.ChkdskParams
  Protected validationError$

  drive$ = UCase(Trim(drive$))

  If badFlag
    fixFlag = #True
  EndIf

  validationError$ = ValidateChkdskRequest(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag)
  If validationError$ <> ""
    SetGadgetText(#Editor_Output, validationError$)
    StatusBarText(#StatusBar, 0, "Cannot start CHKDSK.")
    ProcedureReturn
  EndIf

  If ChkdskRunning
    StatusBarText(#StatusBar, 0, "Already running!")
    ProcedureReturn
  EndIf

  *p = AllocateMemory(SizeOf(ChkdskParams))
  If *p = 0
    StatusBarText(#StatusBar, 0, "Failed to allocate memory!")
    AppendOutputLine("Unable to allocate memory for CHKDSK parameters.")
    ProcedureReturn
  EndIf

  *p\drive$ = drive$
  *p\fixFlag = fixFlag
  *p\scanFlag = scanFlag
  *p\verboseFlag = verboseFlag
  *p\forceFlag = forceFlag
  *p\badFlag = badFlag
  *p\spotfixFlag = spotfixFlag

  SetGadgetText(#Editor_Output, "")
  AppendOutputLine("Command: " + BuildChkdskCommand(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag))
  If badFlag
    AppendOutputLine("Note: /r implies /f, so fixes are enabled automatically.")
  EndIf
  AppendOutputLine("")
  
  ChkdskRunning = #True
  ChkdskStop = #False
  ChkdskThreadID = CreateThread(@RunChkDskThread(), *p)
  If ChkdskThreadID = 0
    ChkdskRunning = #False
    FreeMemory(*p)
    StatusBarText(#StatusBar, 0, "Failed to start worker thread!")
    AppendOutputLine("Failed to create the background worker thread.")
    ProcedureReturn
  EndIf

  StatusBarText(#StatusBar, 0, "Running CHKDSK on " + drive$ + "...")
  DisableGadget(#Button_Run, #True)
  DisableGadget(#Button_Cancel, #False)
EndProcedure

; -------------------------------
; UI
; -------------------------------

Procedure ResizeMain()
  Protected leftMargin = 20
  Protected topMargin = 20
  Protected controlGap = 8
  Protected controlHeight = 26
  Protected buttonY = 60
  Protected buttonWidth = 140
  Protected editorTop = 108
  Protected comboWidth = 96
  Protected fixWidth = 82
  Protected scanWidth = 102
  Protected spotFixWidth = 126
  Protected verboseWidth = 98
  Protected forceWidth = 132
  Protected badSectorWidth
  Protected x
  Protected winW = WindowWidth(#Window_Main)
  Protected winH = WindowHeight(#Window_Main)

  x = leftMargin
  ResizeGadget(#Combo_Drive, x, topMargin, comboWidth, controlHeight)
  x + comboWidth + controlGap
  ResizeGadget(#Check_Fix, x, topMargin, fixWidth, controlHeight)
  x + fixWidth + controlGap
  ResizeGadget(#Check_Scan, x, topMargin, scanWidth, controlHeight)
  x + scanWidth + controlGap
  ResizeGadget(#Check_SpotFix, x, topMargin, spotFixWidth, controlHeight)
  x + spotFixWidth + controlGap
  ResizeGadget(#Check_Verbose, x, topMargin, verboseWidth, controlHeight)
  x + verboseWidth + controlGap
  ResizeGadget(#Check_ForceDismount, x, topMargin, forceWidth, controlHeight)
  x + forceWidth + controlGap
  badSectorWidth = winW - x - leftMargin
  If badSectorWidth < 140
    badSectorWidth = 140
  EndIf
  ResizeGadget(#Check_BadSectors, x, topMargin, badSectorWidth, controlHeight)

  ResizeGadget(#Button_Run, leftMargin, buttonY, buttonWidth, 32)
  ResizeGadget(#Button_SaveLog, leftMargin + 150, buttonY, buttonWidth, 32)
  ResizeGadget(#Button_Cancel, leftMargin + 300, buttonY, buttonWidth, 32)
  ResizeGadget(#Button_About, winW - 310, buttonY, buttonWidth, 32)
  ResizeGadget(#Button_Exit, winW - 160, buttonY, buttonWidth, 32)
  ResizeGadget(#Editor_Output, leftMargin, editorTop, winW - (leftMargin * 2), winH - editorTop - 42)
EndProcedure

Procedure OpenMainWindow()
  KillOrphanProcesses()
  If OpenWindow(#Window_Main, 0, 0, 880, 580, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget)
    WindowBounds(#Window_Main, 780, 580, #PB_Ignore, #PB_Ignore)
    ComboBoxGadget(#Combo_Drive,           20,  20,  96, 26)
    CheckBoxGadget(#Check_Fix,            124,  20,  82, 26, "Fix (/f)")
    CheckBoxGadget(#Check_Scan,           214,  20, 102, 26, "Scan (/scan)")
    CheckBoxGadget(#Check_SpotFix,        324,  20, 126, 26, "SpotFix (/spotfix)")
    CheckBoxGadget(#Check_Verbose,        458,  20,  98, 26, "Verbose (/v)")
    CheckBoxGadget(#Check_ForceDismount,  564,  20, 132, 26, "Force unmount (/x)")
    CheckBoxGadget(#Check_BadSectors,     704,  20, 156, 26, "Scan bad sectors (/r)")
    ButtonGadget(#Button_Run,              20,  60, 140, 32, "Run CHKDSK")
    ButtonGadget(#Button_SaveLog,         170,  60, 140, 32, "Save log")
    ButtonGadget(#Button_Cancel,          320,  60, 140, 32, "Cancel")
    ButtonGadget(#Button_About,           470,  60, 140, 32, "About")
    ButtonGadget(#Button_Exit,            620,  60, 140, 32, "Exit")
    EditorGadget(#Editor_Output,           20, 108, 740, 430, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
    CreateStatusBar(#StatusBar, WindowID(#Window_Main))
    AddStatusBarField(760)
    StatusBarText(#StatusBar, 0, "Ready.")
    DisableGadget(#Button_Cancel, #True)
    AddWindowTimer(#Window_Main, #Timer_OutputFlush, 150)
    PopulateDrives()
    ResizeMain()
    
    BindEvent(#PB_Event_SizeWindow, @ResizeMain(), #Window_Main)
  EndIf
EndProcedure

; -------------------------------
; Main
; -------------------------------

Procedure HandleEvents()
  Protected event = WaitWindowEvent()
  
  Select event
    Case #PB_Event_CloseWindow
      If ConfirmExit()
        CleanupAndExit()
      EndIf

    Case #PB_Event_Timer
      If EventTimer() = #Timer_OutputFlush
        FlushOutputQueue()
      EndIf

    Case #PB_Event_Gadget
      Select EventGadget()
        Case #Button_Run
          If EventType() = #PB_EventType_FirstCustomValue
            ; Thread finished signal
            FlushOutputQueue()
            DisableGadget(#Button_Run, #False)
            DisableGadget(#Button_Cancel, #True)
            If ChkdskStop
              StatusBarText(#StatusBar, 0, "Cancelled.")
            Else
              StatusBarText(#StatusBar, 0, "Completed.")
            EndIf
            ProcedureReturn event
          EndIf
          
          If ChkdskRunning
            StatusBarText(#StatusBar, 0, "Already running!")
            ProcedureReturn event
          EndIf

          Define drive$, fixFlag.i, scanFlag.i, verboseFlag.i, forceFlag.i, badFlag.i, spotfixFlag.i, systemDrive$, validationError$

          drive$       = UCase(Trim(GetGadgetText(#Combo_Drive)))
          fixFlag      = GetGadgetState(#Check_Fix)
          scanFlag     = GetGadgetState(#Check_Scan)
          verboseFlag  = GetGadgetState(#Check_Verbose)
          forceFlag    = GetGadgetState(#Check_ForceDismount)
          badFlag      = GetGadgetState(#Check_BadSectors)
          spotfixFlag  = GetGadgetState(#Check_SpotFix)
          validationError$ = ValidateChkdskRequest(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag)
          
          systemDrive$ = UCase(GetEnvironmentVariable("SystemDrive")) ; usually "C:"

          If validationError$ <> ""
            SetGadgetText(#Editor_Output, validationError$)
            StatusBarText(#StatusBar, 0, "Cannot start CHKDSK.")
          Else
            If fixFlag And drive$ = systemDrive$
              If MessageRequester("CHKDSK Warning", 
                                  "CHKDSK /f requires exclusive access to " + drive$ + "." + #CRLF$ +
                                  "On the system drive this means scheduling a reboot." + #CRLF$ +
                                  "Do you want to REBOOT now?", 
                                  #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
                If ScheduleSystemDriveRepair(drive$)
                  CleanupAndExit()
                EndIf
              Else
                StatusBarText(#StatusBar, 0, "Cancelled by user.")
              EndIf
            Else
              RunChkDsk(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag)
            EndIf
          EndIf

        Case #Button_Cancel
          RequestCancelChkDsk()

        Case #Button_SaveLog
          FlushOutputQueue()
          Define currentText$ = GetGadgetText(#Editor_Output)
          If currentText$ <> ""
            SaveLogToFile(currentText$)
          Else
            StatusBarText(#StatusBar, 0, "Nothing to save!")
          EndIf
          
        Case #Button_About
          MessageRequester("About", #APP_NAME + " - " + version + #CRLF$ +
                                    "A GUI for CHKDSK for checking disk integrity" + #CRLF$ +
                                    "----------------------------------------" + #CRLF$ +
                                    "Contact: zonemaster60@gmail.com" + #CRLF$ +
                                    "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
                                    
          
        Case #Button_Exit
          If ConfirmExit()
            CleanupAndExit()
          EndIf
          
      EndSelect
  EndSelect
  ProcedureReturn event
EndProcedure

; -------------------------------
; Main
; -------------------------------

OpenMainWindow()

Repeat
  HandleEvents()
ForEver
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 54
; FirstLine = 33
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyChkDskGUI.ico
; Executable = ..\HandyChkDskGUI.exe
; DisableDebugger
; IncludeVersionInfo
; VersionField0 = 1,0,0,4
; VersionField1 = 1,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = HandyChkDskGUI
; VersionField4 = 1.0.0.4
; VersionField5 = 1.0.0.4
; VersionField6 = A GUI for Microsoft ChkDsk
; VersionField7 = HandyChkDskGUI
; VersionField8 = HandyChkDskGUI.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60