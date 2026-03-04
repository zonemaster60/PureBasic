; HandyDISMGUI - PureBasic 6.30 Beta 4 compatible
; Enhanced Version with Full DISM Functionality

EnableExplicit

; -------------------------------
; Constants (IDs)
; -------------------------------

Enumeration
  #Window_Main
EndEnumeration

Enumeration
  #Panel_Main
  
  ; Tab: Cleanup & Repair
  #Check_Analyze
  #Check_Scan
  #Check_Check
  #Check_Cleanup
  #Check_Resetbase
  #Check_Restore
  #Button_RunCleanup
  
  ; Tab: Packages
  #List_Packages
  #Button_GetPackages
  #Button_AddPackage
  #Button_RemovePackage
  
  ; Tab: Features
  #List_Features
  #Button_GetFeatures
  #Button_EnableFeature
  #Button_DisableFeature
  
  ; Tab: Drivers
  #List_Drivers
  #Button_GetDrivers
  #Button_ExportDrivers
  
  ; Tab: Appx
  #List_Appx
  #Button_GetAppx
  #Button_RemoveAppx
  
  ; Common
  #Editor_Output
  #Button_SaveLog
  #Button_About
  #Button_Exit
  #StatusBar
EndEnumeration

; -------------------------------
; Global Variables
; -------------------------------

Global WatchdogTimer = ElapsedMilliseconds()
#APP_NAME   = "HandyDismGUI"
#EMAIL_NAME = "zonemaster60@gmail.com"
Global version.s = "v1.0.0.2"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; -------------------------------
; Helpers
; -------------------------------

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    CloseHandle_(hMutex)
    End
  EndIf
EndProcedure

Procedure AppendOutputLine(line$)
  If IsGadget(#Editor_Output)
    AddGadgetItem(#Editor_Output, -1, line$)
    ; Scroll to bottom
    SendMessage_(GadgetID(#Editor_Output), #EM_SETSEL, -1, -1)
    SendMessage_(GadgetID(#Editor_Output), #EM_SCROLLCARET, 0, 0)
  EndIf
EndProcedure

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

Procedure.s RunCommand(cmd$)
  Protected programID.i, line$, fullOutput$
  
  StatusBarText(#StatusBar, 0, "Running: " + cmd$)
  AppendOutputLine("> " + cmd$)
  
  programID = RunProgram("cmd.exe", "/c " + cmd$, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If programID
    While ProgramRunning(programID)
      line$ = ReadProgramString(programID)
      If line$ <> ""
        AppendOutputLine(line$)
        fullOutput$ + line$ + #CRLF$
      EndIf
      WindowEvent()
    Wend
    CloseProgram(programID)
    StatusBarText(#StatusBar, 0, "Ready.")
  Else
    AppendOutputLine("Error: Could not execute command.")
    StatusBarText(#StatusBar, 0, "Error.")
  EndIf
  ProcedureReturn fullOutput$
EndProcedure

Procedure SaveLogToFile()
  Protected output$ = GetGadgetText(#Editor_Output)
  If output$ = ""
    StatusBarText(#StatusBar, 0, "Nothing to save!")
    ProcedureReturn
  EndIf
  
  Protected logFile$ = #APP_NAME + "-" + FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss]", Date()) + ".log"
  If CreateFile(0, logFile$)
    WriteString(0, output$)
    CloseFile(0)
    StatusBarText(#StatusBar, 0, "Log saved to: " + logFile$)
  Else
    StatusBarText(#StatusBar, 0, "Failed to save log!")
  EndIf
EndProcedure

; -------------------------------
; DISM Logic
; -------------------------------

Procedure UpdateListFromOutput(gadget, output$, pattern$)
  ClearGadgetItems(gadget)
  Protected i, count = CountString(output$, #LF$)
  For i = 1 To count + 1
    Protected line$ = Trim(StringField(output$, i, #LF$))
    line$ = RemoveString(line$, #CR$)
    If line$ <> ""
      If pattern$ = "" Or FindString(line$, pattern$, 1, #PB_String_NoCase)
        ; Skip headers and separators
        If Not FindString(line$, "----") And Not FindString(line$, "Package Identity") And Not FindString(line$, "Feature Name") And Not FindString(line$, "Driver")
          AddGadgetItem(gadget, -1, line$)
        EndIf
      EndIf
    EndIf
  Next
EndProcedure

; -------------------------------
; UI
; -------------------------------

Procedure OpenMainWindow()
  If OpenWindow(#Window_Main, 0, 0, 900, 700, #APP_NAME + " " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
    
    PanelGadget(#Panel_Main, 10, 10, 880, 300)
    
    ; TAB 1: Cleanup & Repair
    AddGadgetItem(#Panel_Main, -1, "Cleanup & Repair")
      CheckBoxGadget(#Check_Analyze,   20, 20, 200, 25, "Analyze Component Store")
      CheckBoxGadget(#Check_Scan,      20, 50, 200, 25, "Scan Health")
      CheckBoxGadget(#Check_Check,     20, 80, 200, 25, "Check Health")
      CheckBoxGadget(#Check_Cleanup,   250, 20, 200, 25, "Start Component Cleanup")
      CheckBoxGadget(#Check_Resetbase, 250, 50, 200, 25, "Reset Base")
      CheckBoxGadget(#Check_Restore,   250, 80, 200, 25, "Restore Health")
      ButtonGadget(#Button_RunCleanup, 20, 120, 120, 30, "Run Selected")
      
    ; TAB 2: Packages
    AddGadgetItem(#Panel_Main, -1, "Packages")
      ListIconGadget(#List_Packages, 10, 10, 700, 220, "Package Identity", 500, #PB_ListIcon_FullRowSelect)
      ButtonGadget(#Button_GetPackages, 720, 10, 140, 30, "List Packages")
      ButtonGadget(#Button_AddPackage,  720, 50, 140, 30, "Add Package...")
      ButtonGadget(#Button_RemovePackage, 720, 90, 140, 30, "Remove Selected")
      
    ; TAB 3: Features
    AddGadgetItem(#Panel_Main, -1, "Features")
      ListIconGadget(#List_Features, 10, 10, 700, 220, "Feature Name", 500, #PB_ListIcon_FullRowSelect)
      ButtonGadget(#Button_GetFeatures, 720, 10, 140, 30, "List Features")
      ButtonGadget(#Button_EnableFeature, 720, 50, 140, 30, "Enable Selected")
      ButtonGadget(#Button_DisableFeature, 720, 90, 140, 30, "Disable Selected")

    ; TAB 4: Drivers
    AddGadgetItem(#Panel_Main, -1, "Drivers")
      ListIconGadget(#List_Drivers, 10, 10, 700, 220, "Driver", 680, #PB_ListIcon_FullRowSelect)
      ButtonGadget(#Button_GetDrivers, 720, 10, 140, 30, "List Drivers")
      ButtonGadget(#Button_ExportDrivers, 720, 50, 140, 30, "Export Drivers...")

    ; TAB 5: Appx Packages
    AddGadgetItem(#Panel_Main, -1, "Appx")
      ListIconGadget(#List_Appx, 10, 10, 700, 220, "Package Name", 680, #PB_ListIcon_FullRowSelect)
      ButtonGadget(#Button_GetAppx, 720, 10, 140, 30, "List Appx")
      ButtonGadget(#Button_RemoveAppx, 720, 50, 140, 30, "Remove Selected")

    CloseGadgetList()
    
    ; Common Output Area
    EditorGadget(#Editor_Output, 10, 320, 880, 300, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
    
    ; Bottom Buttons
    ButtonGadget(#Button_SaveLog, 10, 630, 120, 30, "Save Log")
    ButtonGadget(#Button_About,   650, 630, 120, 30, "About")
    ButtonGadget(#Button_Exit,    770, 630, 120, 30, "Exit")
    
    CreateStatusBar(#StatusBar, WindowID(#Window_Main))
    AddStatusBarField(880)
    StatusBarText(#StatusBar, 0, "Ready.")
    
  EndIf
EndProcedure

; -------------------------------
; Main Loop
; -------------------------------

OpenMainWindow()

Repeat
  Define Event = WaitWindowEvent()
  
  ; Watchdog for orphaned processes
  If ElapsedMilliseconds() - WatchdogTimer > 5000
    WatchdogTimer = ElapsedMilliseconds()
    ; KillOrphanProcesses() ; Disabled by default during active use to avoid killing currently running DISM
  EndIf
  
  Select Event
    Case #PB_Event_CloseWindow
      Exit()
      
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #Button_RunCleanup
          If GetGadgetState(#Check_Analyze)   : RunCommand("dism /online /cleanup-image /analyzecomponentstore") : EndIf
          If GetGadgetState(#Check_Scan)      : RunCommand("dism /online /cleanup-image /scanhealth") : EndIf
          If GetGadgetState(#Check_Check)     : RunCommand("dism /online /cleanup-image /checkhealth") : EndIf
          If GetGadgetState(#Check_Cleanup)   : RunCommand("dism /online /cleanup-image /startcomponentcleanup") : EndIf
          If GetGadgetState(#Check_Resetbase) : RunCommand("dism /online /cleanup-image /startcomponentcleanup /resetbase") : EndIf
          If GetGadgetState(#Check_Restore)   : RunCommand("dism /online /cleanup-image /restorehealth") : EndIf

        Case #Button_GetPackages
          Define out$ = RunCommand("dism /online /get-packages /format:table")
          UpdateListFromOutput(#List_Packages, out$, "Package_")
          
        Case #Button_AddPackage
          Define pkgPath$ = OpenFileRequester("Select Package", "", "CAB files (*.cab)|*.cab|MSU files (*.msu)|*.msu|All files (*.*)|*.*", 0)
          If pkgPath$
            RunCommand("dism /online /add-package /packagepath:" + Chr(34) + pkgPath$ + Chr(34) + " /norestart")
          EndIf
          
        Case #Button_RemovePackage
          Define pkgIdx = GetGadgetState(#List_Packages)
          If pkgIdx <> -1
            Define pkgName$ = StringField(GetGadgetItemText(#List_Packages, pkgIdx, 0), 1, " ")
            If pkgName$
              RunCommand("dism /online /remove-package /packagename:" + pkgName$ + " /norestart")
            EndIf
          EndIf

        Case #Button_GetFeatures
          Define out$ = RunCommand("dism /online /get-features /format:table")
          UpdateListFromOutput(#List_Features, out$, "") ; Could refine pattern
          
        Case #Button_EnableFeature
          Define featIdx = GetGadgetState(#List_Features)
          If featIdx <> -1
            Define featName$ = StringField(GetGadgetItemText(#List_Features, featIdx, 0), 1, " ")
            RunCommand("dism /online /enable-feature /featurename:" + featName$ + " /all /norestart")
          EndIf
          
        Case #Button_DisableFeature
          Define featIdx = GetGadgetState(#List_Features)
          If featIdx <> -1
            Define featName$ = StringField(GetGadgetItemText(#List_Features, featIdx, 0), 1, " ")
            RunCommand("dism /online /disable-feature /featurename:" + featName$ + " /norestart")
          EndIf

        Case #Button_GetDrivers
          Define out$ = RunCommand("dism /online /get-drivers /format:table")
          UpdateListFromOutput(#List_Drivers, out$, "oem")

        Case #Button_ExportDrivers
          Define destDir$ = PathRequester("Select Destination Folder", "")
          If destDir$
            RunCommand("dism /online /export-driver /destination:" + Chr(34) + destDir$ + Chr(34))
          EndIf

        Case #Button_GetAppx
          Define out$ = RunCommand("dism /online /get-provisionedappxpackages /format:table")
          UpdateListFromOutput(#List_Appx, out$, "")
          
        Case #Button_RemoveAppx
          Define appIdx = GetGadgetState(#List_Appx)
          If appIdx <> -1
            Define appName$ = StringField(GetGadgetItemText(#List_Appx, appIdx, 0), 1, " ")
            If appName$
              RunCommand("dism /online /remove-provisionedappxpackage /packagename:" + appName$)
              ; Refresh after removal
              Define out$ = RunCommand("dism /online /get-provisionedappxpackages /format:table")
              UpdateListFromOutput(#List_Appx, out$, "")
            EndIf
          EndIf

        Case #Button_SaveLog
          SaveLogToFile()
          
        Case #Button_About
          MessageRequester("About", #APP_NAME + " " + version + #CRLF$ + "Full DISM GUI Implementation" + #CRLF$ + "Contact: " + #EMAIL_NAME)
          
        Case #Button_Exit
          Exit()
          
      EndSelect
  EndSelect
ForEver

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 261
; FirstLine = 246
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
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = HandyDismGUI
; VersionField4 = HandyDismGUI
; VersionField5 = 1.0.0.2
; VersionField6 = 1.0.0.2
; VersionField7 = HandyDismGUI
; VersionField8 = HandyDismGUI.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60