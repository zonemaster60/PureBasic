; HandyDISMGUI - PureBasic 6.30 Beta 4 compatible

EnableExplicit

; -------------------------------
; Constants (IDs)
; -------------------------------

Enumeration
  #Window_Main
EndEnumeration

Enumeration
  #Check_Analyze
  #Check_Scan
  #Check_Check
  #Check_Cleanup
  #Check_Resetbase
  #Check_Restore
  #Button_Run
  #Button_SaveLog
  #Button_About
  #Button_Exit
  #Editor_Output
  #StatusBar
EndEnumeration

; watchdog timer
Global WatchdogTimer = ElapsedMilliseconds()

#APP_NAME   = "HandyDismGUI"
#EMAIL_NAME = "zonemaster60@gmail.com"

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
  ; Safe append to EditorGadget text
  If IsGadget(#Editor_Output)
    Protected current$ = GetGadgetText(#Editor_Output)
    If current$ = ""
      SetGadgetText(#Editor_Output, line$)
    Else
      SetGadgetText(#Editor_Output, current$ + #CRLF$ + line$)
    EndIf
  EndIf
EndProcedure

Procedure.s BuildDISMCommand(analyzeFlag, scanFlag, checkFlag, cleanupFlag, resetbaseFlag, restoreFlag)
  Protected cmd$ = "dism"
  If analyzeFlag       : cmd$ + " /online /cleanup-image /analyzecomponentstore" : EndIf
  If scanFlag          : cmd$ + " /online /cleanup-image /scanhealth" : EndIf
  If checkFlag         : cmd$ + " /online /cleanup-image /checkhealth" : EndIf
  If cleanupFlag       : cmd$ + " /online /cleanup-image /startcomponentcleanup" : EndIf
  If resetbaseFlag     : cmd$ + " /online /cleanup-image /startcomponentcleanup /resetbase" : EndIf
  If restoreFlag       : cmd$ + " /online /cleanup-image /restorehealth" : EndIf
  ProcedureReturn cmd$
EndProcedure

Procedure SaveLogToFile(output$)
  Protected logFile$ = #APP_NAME + "-" + FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + ".log"
  If CreateFile(0, logFile$)
    WriteString(0, output$)
    CloseFile(0)
    StatusBarText(#StatusBar, 0, "Log file saved: " + logFile$)
  Else
    StatusBarText(#StatusBar, 0, "Failed to save log!")
  EndIf
EndProcedure

; ------------------------------------------------------
; Watchdog: Kill orphaned cmd.exe and dism.exe processes
; ------------------------------------------------------

Procedure KillOrphanProcesses()
  Protected hSnap, pe.PROCESSENTRY32, hProc

  hSnap = CreateToolhelp32Snapshot_(#TH32CS_SNAPPROCESS, 0)
  If hSnap <> #INVALID_HANDLE_VALUE
    pe\dwSize = SizeOf(PROCESSENTRY32)

    If Process32First_(hSnap, @pe)
      Repeat
        Protected exe$ = LCase(PeekS(@pe\szExeFile))

        If exe$ = "cmd.exe" Or exe$ = "dism.exe"
          hProc = OpenProcess_(#PROCESS_TERMINATE, #False, pe\th32ProcessID)
          If hProc
            TerminateProcess_(hProc, 0)
            CloseHandle_(hProc)
          EndIf
        EndIf

      Until Process32Next_(hSnap, @pe) = 0
    EndIf

    CloseHandle_(hSnap)
  EndIf
EndProcedure

; -------------------------------
; Core execution
; -------------------------------

Procedure RunDISM(analyzeFlag, scanFlag, checkFlag, cleanupFlag, resetbaseFlag, restoreFlag)
  Protected programID.i, line$, cmd$, log$

  cmd$ = BuildDISMCommand(analyzeFlag, scanFlag, checkFlag, cleanupFlag, resetbaseFlag, restoreFlag)
  StatusBarText(#StatusBar, 0, "Running: " + cmd$)

  SetGadgetText(#Editor_Output, "")
  AppendOutputLine("Command: " + cmd$)
  AppendOutputLine("")

  programID = RunProgram("cmd.exe", "/c " + cmd$, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If programID
    While ProgramRunning(programID)
      line$ = ReadProgramString(programID)
      If line$ <> ""
        AppendOutputLine(line$)   ; update immediately
        log$ + line$ + #CRLF$     ; keep a copy for saving
      EndIf
      WindowEvent()               ; let GUI refresh
    Wend
    CloseProgram(programID)
    AppendOutputLine("")
    AppendOutputLine("DISM completed.")
    StatusBarText(#StatusBar, 0, "Completed.")
  Else
    SetGadgetText(#Editor_Output, "Failed to start DISM! Try running as administrator.")
    StatusBarText(#StatusBar, 0, "Failed to start!")
  EndIf
EndProcedure

; -------------------------------
; UI
; -------------------------------

Procedure OpenMainWindow()
  KillOrphanProcesses()
  If OpenWindow(#Window_Main, 0, 0, 780, 580, #APP_NAME+ " - v1.0.0.1", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget)
    CheckBoxGadget(#Check_Analyze,        20,   20, 150, 26, "AnalyzeComponentStore")
    CheckBoxGadget(#Check_Scan,           180,  20, 80, 26,  "ScanHealth")
    CheckBoxGadget(#Check_Check,          270,  20, 85, 26,  "CheckHealth")
    CheckBoxGadget(#Check_Cleanup,        365,  20, 150, 26, "StartComponentCleanup")
    CheckBoxGadget(#Check_Resetbase,      525,  20, 140, 26, "StartResetBaseCleanup")
    CheckBoxGadget(#Check_Restore,        670,  20, 95, 26,  "RestoreHealth")
    ButtonGadget(#Button_Run,              20,  60, 140, 32, "Run DISM")
    ButtonGadget(#Button_SaveLog,         170,  60, 140, 32, "Save log")
    ButtonGadget(#Button_About,           470,  60, 140, 32, "About")
    ButtonGadget(#Button_Exit,            620,  60, 140, 32, "Exit")
    EditorGadget(#Editor_Output,           20, 108, 740, 430, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
    CreateStatusBar(#StatusBar, WindowID(#Window_Main))
    AddStatusBarField(760)
    StatusBarText(#StatusBar, 0, "Ready.")
  EndIf
EndProcedure

; -------------------------------
; Main
; -------------------------------

OpenMainWindow()

Repeat
  
  ; inside your main loop:
  If ElapsedMilliseconds() - WatchdogTimer > 1000
    WatchdogTimer = ElapsedMilliseconds()
    KillOrphanProcesses()
  EndIf

  Select WaitWindowEvent()
    Case #PB_Event_CloseWindow
      KillOrphanProcesses()
      Exit()

    Case #PB_Event_Gadget
      Select EventGadget()
        Case #Button_Run
            Define analyzeFlag.i, scanFlag.i, checkFlag.i, cleanupFlag.i, resetbaseFlag.i, restoreFlag.i

            analyzeFlag  = GetGadgetState(#Check_Analyze)
            scanFlag     = GetGadgetState(#Check_Scan)
            checkFlag    = GetGadgetState(#Check_Check)
            cleanupFlag  = GetGadgetState(#Check_Cleanup)
            resetbaseFlag      = GetGadgetState(#Check_Resetbase)
            restoreFlag  = GetGadgetState(#Check_Restore)
            
            RunDISM(analyzeFlag, scanFlag, checkFlag, cleanupFlag, resetbaseFlag, restoreFlag)
            KillOrphanProcesses()
        
        Case #Button_SaveLog
          Define currentText$ = GetGadgetText(#Editor_Output)
          If currentText$ <> ""
            SaveLogToFile(currentText$)
          Else
            StatusBarText(#StatusBar, 0, "Nothing to save!")
          EndIf
          
        Case #Button_About
          MessageRequester("About", #APP_NAME + " - v1.0.0.1" + #CRLF$ +
                                    "A tool for scanning/repairing the System Image" + #CRLF$ +
                                    "------------------------------------------" + #CRLF$ +
                                    "Contact: " + #EMAIL_NAME + #CRLF$ +
                                    "Website: https://github.com/zonemaster60" + #CRLF$ +
                                    "DISM is a product of the Microsoft Corp.", #PB_MessageRequester_Info)
          
        Case #Button_Exit
          KillOrphanProcesses()
          Exit()
          
      EndSelect
  EndSelect
ForEver
; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 45
; FirstLine = 27
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyDISMGUI.ico
; Executable = ..\HandyDismGUI.exe
; DisableDebugger
; IncludeVersionInfo
; VersionField0 = 1,0,0,1
; VersionField1 = 1,0,0,1
; VersionField2 = ZoneSoft
; VersionField3 = HandyDismGUI
; VersionField4 = 1.0.0.1
; VersionField5 = 1.0.0.1
; VersionField6 = A GUI for Microsoft Dism (repairs)
; VersionField7 = HandyDismGUI
; VersionField8 = HandyDismGUI.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60