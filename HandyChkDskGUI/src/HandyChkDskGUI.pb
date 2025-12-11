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

; watchdog timer
Global WatchdogTimer = ElapsedMilliseconds()

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
  Protected logFile$ = "HandyChkDskGUI-" + FormatDate("%yy%mm%dd-%hh%ii%ss", Date()) + ".log"
  If CreateFile(0, logFile$)
    WriteString(0, output$)
    CloseFile(0)
    StatusBarText(#StatusBar, 0, "Log file saved: " + logFile$)
  Else
    StatusBarText(#StatusBar, 0, "Failed to save log!")
  EndIf
EndProcedure

; -------------------------------------------------------
; Watchdog: Kill orphaned cmd.exe and chkdsk.exe processes
; -------------------------------------------------------

Procedure KillOrphanProcesses()
  Protected hSnap, pe.PROCESSENTRY32, hProc

  hSnap = CreateToolhelp32Snapshot_(#TH32CS_SNAPPROCESS, 0)
  If hSnap <> #INVALID_HANDLE_VALUE
    pe\dwSize = SizeOf(PROCESSENTRY32)

    If Process32First_(hSnap, @pe)
      Repeat
        Protected exe$ = LCase(PeekS(@pe\szExeFile))

        If exe$ = "cmd.exe" Or exe$ = "chkdsk.exe"
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

Procedure RunChkDsk(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag)
  Protected programID.i, line$, cmd$, log$

  If ValidateDrive(drive$) = #False
    SetGadgetText(#Editor_Output, "Invalid drive format! Select a drive like C:")
    StatusBarText(#StatusBar, 0, "Invalid drive!")
    ProcedureReturn
  EndIf

  cmd$ = BuildChkdskCommand(drive$, fixFlag, scanFlag, verboseFlag, forceFlag, badFlag, spotfixFlag)
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
    AppendOutputLine("CHKDSK completed.")
    StatusBarText(#StatusBar, 0, "Completed.")
  Else
    SetGadgetText(#Editor_Output, "Failed to start CHKDSK! Try running as administrator.")
    StatusBarText(#StatusBar, 0, "Failed to start!")
  EndIf
EndProcedure

; -------------------------------
; UI
; -------------------------------

Procedure OpenMainWindow()
  KillOrphanProcesses()
  If OpenWindow(#Window_Main, 0, 0, 780, 580, "HandyChkDskGUI (v1.00)", #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget | #PB_Window_MaximizeGadget)
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
              KillOrphanProcesses()
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
          MessageRequester("About", "HandyChkDskGUI v1.0.0.0" + #CRLF$ +
                                    "David Scouten (zonemaster@yahoo.com)" + #CRLF$ +
                                    "----------------------------------------" + #CRLF$ +
                                    "https://www.facebook.com/DavesPCPortal" + #CRLF$ +
                                    "https://github.com/zonemaster60" + #CRLF$ +
                                    "CHKDSK is a product of the Microsoft Corp.", #PB_MessageRequester_Info)
          
        Case #Button_Exit
          KillOrphanProcesses()
          Exit()
          
      EndSelect
  EndSelect
ForEver
; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 237
; FirstLine = 223
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; DllProtection
; UseIcon = HandyChkDskGUI.ico
; Executable = ..\HandyChkDskGUI.exe
; DisableDebugger
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = HandyChkDskGUI
; VersionField4 = v1.0.0.0
; VersionField5 = v1.0.0.0
; VersionField6 = A GUI for Microsoft ChkDsk
; VersionField7 = HandyChkDskGUI
; VersionField8 = HandyChkDskGUI.exe
; VersionField13 = zonemaster@yahoo.com
; VersionField14 = https://github.com/zonemaster60