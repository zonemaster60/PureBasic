; HandyChkDskGUI - PureBasic 6.30 Beta 4 compatible

EnableExplicit

; -------------------------------
; Constants (IDs)
; -------------------------------

Enumeration
  #Window_Main
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

; watchdog timer
Global WatchdogTimer = ElapsedMilliseconds()

#APP_NAME   = "HandyChkDskGUI"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.3"
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

Procedure Exit()
  Define Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
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
  ; Expect "X:" format
  drive$ = Trim(drive$)
  If Len(drive$) = 2 And Mid(drive$, 2, 1) = ":"
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
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

Procedure KillOrphanProcesses()
  ; Only kill processes that we started
  ForEach ChkdskProcessList()
    Protected hProc = OpenProcess_(#PROCESS_TERMINATE, #False, ChkdskProcessList())
    If hProc
      TerminateProcess_(hProc, 0)
      CloseHandle_(hProc)
    EndIf
  Next
  ClearList(ChkdskProcessList())
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
  Protected programID.i, line$, cmd$
  
  cmd$ = BuildChkdskCommand(*p\drive$, *p\fixFlag, *p\scanFlag, *p\verboseFlag, *p\forceFlag, *p\badFlag, *p\spotfixFlag)
  
  programID = RunProgram("cmd.exe", "/c " + cmd$, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If programID
    AddElement(ChkdskProcessList())
    ChkdskProcessList() = ProgramID(programID)
    
    While ProgramRunning(programID)
      If ChkdskStop
        KillProgram(programID)
        Break
      EndIf
      
      line$ = ReadProgramString(programID)
      If line$ <> ""
        AppendOutputLine(line$)
      EndIf
      Delay(10)
    Wend
    
    CloseProgram(programID)
    AppendOutputLine("")
    AppendOutputLine("CHKDSK completed.")
    PostEvent(#PB_Event_Gadget, #Window_Main, #Button_Run, #PB_EventType_FirstCustomValue) ; Signal completion
  Else
    AppendOutputLine("Failed to start CHKDSK! Try running as administrator.")
  EndIf
  
  ChkdskRunning = #False
  FreeMemory(*p)
EndProcedure

Procedure RunChkDsk(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag)
  If ValidateDrive(drive$) = #False
    SetGadgetText(#Editor_Output, "Invalid drive format! Select a drive like C:")
    StatusBarText(#StatusBar, 0, "Invalid drive!")
    ProcedureReturn
  EndIf

  If ChkdskRunning
    StatusBarText(#StatusBar, 0, "Already running!")
    ProcedureReturn
  EndIf

  Protected *p.ChkdskParams = AllocateMemory(SizeOf(ChkdskParams))
  *p\drive$ = drive$
  *p\fixFlag = fixFlag
  *p\scanFlag = scanFlag
  *p\verboseFlag = verboseFlag
  *p\forceFlag = forceFlag
  *p\badFlag = badFlag
  *p\spotfixFlag = spotfixFlag

  SetGadgetText(#Editor_Output, "")
  AppendOutputLine("Command: " + BuildChkdskCommand(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag))
  AppendOutputLine("")
  
  ChkdskRunning = #True
  ChkdskStop = #False
  StatusBarText(#StatusBar, 0, "Running CHKDSK on " + drive$ + "...")
  DisableGadget(#Button_Run, #True)
  
  ChkdskThreadID = CreateThread(@RunChkDskThread(), *p)
EndProcedure

; -------------------------------
; UI
; -------------------------------

Procedure ResizeMain()
  Protected winW = WindowWidth(#Window_Main)
  Protected winH = WindowHeight(#Window_Main)
  
  ResizeGadget(#Editor_Output, 20, 108, winW - 40, winH - 108 - 42)
  ResizeGadget(#Button_Exit, winW - 160, 60, 140, 32)
  ResizeGadget(#Button_About, winW - 310, 60, 140, 32)
EndProcedure

Procedure OpenMainWindow()
  KillOrphanProcesses()
  If OpenWindow(#Window_Main, 0, 0, 780, 580, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget | #PB_Window_SizeGadget)
    ComboBoxGadget(#Combo_Drive,           20,  20, 110, 26)
    CheckBoxGadget(#Check_Fix,            140,  20, 60, 26, "Fix (/f)")
    CheckBoxGadget(#Check_Scan,           205,  20, 80, 26, "Scan (/scan)")
    CheckBoxGadget(#Check_SpotFix,        300,  20, 115, 26, "SpotFix /spotfix")
    CheckBoxGadget(#Check_Verbose,        415,  20, 90, 26, "Verbose (/v)")
    CheckBoxGadget(#Check_ForceDismount,  510,  20, 125, 26, "Force Unmount (/x)")
    CheckBoxGadget(#Check_BadSectors,     640,  20, 145, 26, "Scan bad sectors (/r)")
    ButtonGadget(#Button_Run,              20,  60, 140, 32, "Run CHKDSK")
    ButtonGadget(#Button_SaveLog,         170,  60, 140, 32, "Save log")
    ButtonGadget(#Button_About,           470,  60, 140, 32, "About")
    ButtonGadget(#Button_Exit,            620,  60, 140, 32, "Exit")
    EditorGadget(#Editor_Output,           20, 108, 740, 430, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
    CreateStatusBar(#StatusBar, WindowID(#Window_Main))
    AddStatusBarField(760)
    StatusBarText(#StatusBar, 0, "Ready.")
    PopulateDrives()
    
    BindEvent(#PB_Event_SizeWindow, @ResizeMain(), #Window_Main)
  EndIf
EndProcedure

; -------------------------------
; Main
; -------------------------------

OpenMainWindow()

Procedure HandleEvents()
  Protected event = WaitWindowEvent()
  
  Select event
    Case #PB_Event_CloseWindow
      ChkdskStop = #True
      If ChkdskRunning
        If WaitThread(ChkdskThreadID, 1000) = 0
          KillOrphanProcesses()
        EndIf
      EndIf
      Exit()

    Case #PB_Event_Gadget
      Select EventGadget()
        Case #Button_Run
          If EventType() = #PB_EventType_FirstCustomValue
            ; Thread finished signal
            DisableGadget(#Button_Run, #False)
            StatusBarText(#StatusBar, 0, "Completed.")
            ProcedureReturn event
          EndIf
          
          If ChkdskRunning
            StatusBarText(#StatusBar, 0, "Already running!")
            ProcedureReturn event
          EndIf

          Define drive$, fixFlag.i, scanFlag.i, verboseFlag.i, forceFlag.i, badFlag.i, spotfixFlag.i, systemDrive$

          drive$       = GetGadgetText(#Combo_Drive)
          fixFlag      = GetGadgetState(#Check_Fix)
          scanFlag     = GetGadgetState(#Check_Scan)
          verboseFlag  = GetGadgetState(#Check_Verbose)
          forceFlag    = GetGadgetState(#Check_ForceDismount)
          badFlag      = GetGadgetState(#Check_BadSectors)
          spotfixFlag  = GetGadgetState(#Check_SpotFix)
          
          systemDrive$ = GetEnvironmentVariable("SystemDrive") ; usually "C:"

          If drive$ = ""
            SetGadgetText(#Editor_Output, "Please select a drive (like C:).")
            StatusBarText(#StatusBar, 0, "No drive selected!")
          Else
            If fixFlag And drive$ = systemDrive$
              If MessageRequester("CHKDSK Warning", 
                                  "CHKDSK /f requires exclusive access to " + drive$ + "." + #CRLF$ +
                                  "On the system drive this means scheduling a reboot." + #CRLF$ +
                                  "Do you want to REBOOT now?", 
                                  #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes
                ; use fsutil to set dirty bit on system drive
                RunProgram("cmd.exe", "/c fsutil dirty set " + Drive$, "", #PB_Program_Hide)
                ; Reboot in 15 seconds
                RunProgram("shutdown.exe", "/r /t 15", "", #PB_Program_Hide)
                KillOrphanProcesses()
                End
              Else
                StatusBarText(#StatusBar, 0, "Cancelled by user.")
              EndIf
            Else
              RunChkDsk(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag)
            EndIf
          EndIf

        Case #Button_SaveLog
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
          ChkdskStop = #True
          If ChkdskRunning
            WaitThread(ChkdskThreadID, 1000)
          EndIf
          KillOrphanProcesses()
          Exit()
          
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
; CursorPosition = 49
; FirstLine = 21
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyChkDskGUI.ico
; Executable = ..\HandyChkDskGUI.exe
; DisableDebugger
; IncludeVersionInfo
; VersionField0 = 1,0,0,3
; VersionField1 = 1,0,0,3
; VersionField2 = ZoneSoft
; VersionField3 = HandyChkDskGUI
; VersionField4 = 1.0.0.3
; VersionField5 = 1.0.0.3
; VersionField6 = A GUI for Microsoft ChkDsk
; VersionField7 = HandyChkDskGUI
; VersionField8 = HandyChkDskGUI.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60