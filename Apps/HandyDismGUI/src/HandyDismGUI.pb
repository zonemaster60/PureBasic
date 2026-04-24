; HandyDISMGUI - PureBasic 6.30 Beta 4 compatible
; Enhanced Version with Full DISM Functionality

EnableExplicit

; -------------------------------
; Constants (IDs)
; -------------------------------

Enumeration
  #Window_Main
EndEnumeration

Enumeration 1
  #Refresh_None
  #Refresh_Packages
  #Refresh_Features
  #Refresh_Drivers
  #Refresh_Appx
EndEnumeration

Enumeration 1
  #Timer_CommandPump
EndEnumeration

Structure CommandQueueItem
  description.s
  args.s
  refreshMode.i
  destructive.i
EndStructure

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
  #Text_QueueStatus
  #Button_SaveLog
  #Button_ClearQueue
  #Button_CancelCommand
  #Button_About
  #Button_Exit
  #StatusBar
EndEnumeration

; -------------------------------
; Global Variables
; -------------------------------

#APP_NAME   = "HandyDismGUI"
#EMAIL_NAME = "zonemaster60@gmail.com"
Global Version.s = "v1.0.0.4"
Global AppPath.s = GetPathPart(ProgramFilename())
Global CurrentProgramID.i
Global CurrentCommandArgs.s
Global CurrentCommandDescription.s
Global CurrentCommandRefresh.i
Global CurrentCommandDestructive.i
Global CurrentCommandRunning.i
Global CurrentCommandOutput.s
Global OutputLog.s
Global NewList CommandQueue.CommandQueueItem()
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

Declare StopCurrentCommand(forceTerminate.i = #False, startNext.i = #True)
Declare RefreshListByMode(refreshMode.i)
Declare PopulateListFromOutput(refreshMode.i, output$)
Declare.i GetRefreshListGadget(refreshMode.i)
Declare.s GetRefreshListLabel(refreshMode.i)
Declare UpdateCompletionStatus(exitCode.i, refreshMode.i)
Declare QueueCommand(description$, args$, refreshMode.i = #Refresh_None, destructive.i = #False)
Declare QueueCheckedCleanupCommand(gadget.i, description$, args$, destructive.i = #False)
Declare QueueCommandAndRefresh(description$, args$, refreshMode.i = #Refresh_None, destructive.i = #False)
Declare QueueSelectedListCommand(gadget.i, descriptionPrefix$, argsPrefix$, refreshMode.i, emptyStatus$, confirmTitle$, confirmMessagePrefix$, confirmMessageSuffix$, cancelStatus$)
Declare.s GetSelectedListItem(gadget)
Declare.s NormalizeFieldName(value$)
Declare.s ExtractNamedValue(line$, fieldNames$)
Declare StartNextCommand()
Declare PumpCurrentCommand()
Declare UpdateUiState()
Declare ClearCommandQueue()
Declare ResetCurrentCommandState()
Declare SetGadgetDisabledIfPresent(gadget.i, disabled.i)

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    ClearCommandQueue()
    StopCurrentCommand(#True, #False)
    If hMutex
      CloseHandle_(hMutex)
    EndIf
    End
  EndIf
EndProcedure

Procedure.s QuoteArgument(value$)
  ProcedureReturn Chr(34) + value$ + Chr(34)
EndProcedure

Procedure.i ConfirmAction(title$, message$)
  ProcedureReturn Bool(MessageRequester(title$, message$, #PB_MessageRequester_YesNo | #PB_MessageRequester_Warning) = #PB_MessageRequester_Yes)
EndProcedure

Procedure AppendOutputLine(line$)
  If OutputLog
    OutputLog + #CRLF$
  EndIf
  OutputLog + line$

  If IsGadget(#Editor_Output)
    AddGadgetItem(#Editor_Output, -1, line$)
    ; Scroll to bottom
    SendMessage_(GadgetID(#Editor_Output), #EM_SETSEL, -1, -1)
    SendMessage_(GadgetID(#Editor_Output), #EM_SCROLLCARET, 0, 0)
  EndIf
EndProcedure

Procedure SetGadgetDisabledIfPresent(gadget.i, disabled.i)
  If IsGadget(gadget)
    DisableGadget(gadget, disabled.i)
  EndIf
EndProcedure

Procedure UpdateUiState()
  Protected queueCount.i = ListSize(CommandQueue())
  Protected hasWork.i = Bool(CurrentCommandRunning Or queueCount > 0)
  Protected queueText$

  If CurrentCommandRunning
    queueText$ = "Running: " + CurrentCommandDescription
    If queueCount > 0
      queueText$ + " | Queued: " + Str(queueCount)
    EndIf
  ElseIf queueCount > 0
    queueText$ = "Queued: " + Str(queueCount)
  Else
    queueText$ = "Queue idle"
  EndIf

  If IsGadget(#Text_QueueStatus)
    SetGadgetText(#Text_QueueStatus, queueText$)
  EndIf

  SetGadgetDisabledIfPresent(#Button_ClearQueue, Bool(queueCount = 0))
  SetGadgetDisabledIfPresent(#Button_CancelCommand, Bool(Not hasWork))

  SetGadgetDisabledIfPresent(#Button_RunCleanup, hasWork)
  SetGadgetDisabledIfPresent(#Button_GetPackages, hasWork)
  SetGadgetDisabledIfPresent(#Button_AddPackage, hasWork)
  SetGadgetDisabledIfPresent(#Button_RemovePackage, hasWork)
  SetGadgetDisabledIfPresent(#Button_GetFeatures, hasWork)
  SetGadgetDisabledIfPresent(#Button_EnableFeature, hasWork)
  SetGadgetDisabledIfPresent(#Button_DisableFeature, hasWork)
  SetGadgetDisabledIfPresent(#Button_GetDrivers, hasWork)
  SetGadgetDisabledIfPresent(#Button_ExportDrivers, hasWork)
  SetGadgetDisabledIfPresent(#Button_GetAppx, hasWork)
  SetGadgetDisabledIfPresent(#Button_RemoveAppx, hasWork)
EndProcedure

Procedure UpdateStatusBar()
  Protected queueCount.i = ListSize(CommandQueue())

  If CurrentCommandRunning
    StatusBarText(#StatusBar, 0, "Running: " + CurrentCommandDescription)
  ElseIf queueCount > 0
    StatusBarText(#StatusBar, 0, "Queued commands: " + Str(queueCount))
  Else
    StatusBarText(#StatusBar, 0, "Ready.")
  EndIf

  UpdateUiState()
EndProcedure

Procedure ResetCurrentCommandState()
  CurrentProgramID = 0
  CurrentCommandArgs = ""
  CurrentCommandDescription = ""
  CurrentCommandRefresh = #Refresh_None
  CurrentCommandDestructive = #False
  CurrentCommandRunning = #False
  CurrentCommandOutput = ""
EndProcedure

Procedure StopCurrentCommand(forceTerminate.i = #False, startNext.i = #True)
  Protected wasRunning.i = CurrentCommandRunning

  If CurrentProgramID And IsProgram(CurrentProgramID)
    If forceTerminate And ProgramRunning(CurrentProgramID)
      KillProgram(CurrentProgramID)
      AppendOutputLine("Command cancelled.")
    EndIf

    If Not ProgramRunning(CurrentProgramID)
      CloseProgram(CurrentProgramID)
    ElseIf forceTerminate
      CloseProgram(CurrentProgramID)
    EndIf
  EndIf

  ResetCurrentCommandState()

  If wasRunning And startNext
    UpdateStatusBar()
    StartNextCommand()
  Else
    UpdateStatusBar()
  EndIf
EndProcedure

Procedure ClearCommandQueue()
  ClearList(CommandQueue())
  UpdateStatusBar()
EndProcedure

Procedure QueueCommand(description$, args$, refreshMode.i = #Refresh_None, destructive.i = #False)
  AddElement(CommandQueue())
  CommandQueue()\description = description$
  CommandQueue()\args = args$
  CommandQueue()\refreshMode = refreshMode
  CommandQueue()\destructive = destructive.i
  AppendOutputLine("[queued] " + description$)
  StartNextCommand()
  UpdateStatusBar()
EndProcedure

Procedure QueueCheckedCleanupCommand(gadget.i, description$, args$, destructive.i = #False)
  If GetGadgetState(gadget)
    QueueCommand(description$, args$, #Refresh_None, destructive.i)
    SetGadgetState(gadget, #False)
  EndIf
EndProcedure

Procedure QueueCommandAndRefresh(description$, args$, refreshMode.i = #Refresh_None, destructive.i = #False)
  ; Queue the mutation first so the refresh reads the post-change state.
  QueueCommand(description$, args$, #Refresh_None, destructive.i)
  If refreshMode <> #Refresh_None
    RefreshListByMode(refreshMode)
  EndIf
EndProcedure

Procedure QueueSelectedListCommand(gadget.i, descriptionPrefix$, argsPrefix$, refreshMode.i, emptyStatus$, confirmTitle$, confirmMessagePrefix$, confirmMessageSuffix$, cancelStatus$)
  Protected selectedItem$

  selectedItem$ = GetSelectedListItem(gadget)
  If selectedItem$ = ""
    StatusBarText(#StatusBar, 0, emptyStatus$)
    ProcedureReturn
  EndIf

  If ConfirmAction(confirmTitle$, confirmMessagePrefix$ + "`" + selectedItem$ + "`" + confirmMessageSuffix$)
    QueueCommandAndRefresh(descriptionPrefix$ + selectedItem$, argsPrefix$ + selectedItem$, refreshMode, #True)
  Else
    StatusBarText(#StatusBar, 0, cancelStatus$)
  EndIf
EndProcedure

Procedure StartNextCommand()
  If CurrentCommandRunning Or ListSize(CommandQueue()) = 0
    ProcedureReturn
  EndIf

  FirstElement(CommandQueue())
  CurrentCommandDescription = CommandQueue()\description
  CurrentCommandArgs = CommandQueue()\args
  CurrentCommandRefresh = CommandQueue()\refreshMode
  CurrentCommandDestructive = CommandQueue()\destructive
  CurrentCommandOutput = ""
  ; Remove the queue head before launch so cancellation cannot replay it.
  DeleteElement(CommandQueue())

  CurrentProgramID = RunProgram("dism.exe", CurrentCommandArgs, "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  If CurrentProgramID
    CurrentCommandRunning = #True
    AppendOutputLine("> " + CurrentCommandDescription)
  Else
    AppendOutputLine("Error: Could not execute command: " + CurrentCommandDescription)
    ResetCurrentCommandState()
  EndIf

  UpdateStatusBar()

  If Not CurrentCommandRunning
    StartNextCommand()
  EndIf
EndProcedure

Procedure PumpCurrentCommand()
  Protected exitCode.i
  Protected line$

  If Not CurrentCommandRunning Or Not IsProgram(CurrentProgramID)
    StartNextCommand()
    ProcedureReturn
  EndIf

  While AvailableProgramOutput(CurrentProgramID)
    line$ = ReadProgramString(CurrentProgramID)
    If line$ <> ""
      AppendOutputLine(line$)
      CurrentCommandOutput + line$ + #CRLF$
    EndIf
  Wend

  If Not ProgramRunning(CurrentProgramID)
    While AvailableProgramOutput(CurrentProgramID)
      line$ = ReadProgramString(CurrentProgramID)
      If line$ <> ""
        AppendOutputLine(line$)
        CurrentCommandOutput + line$ + #CRLF$
      EndIf
    Wend

    exitCode = ProgramExitCode(CurrentProgramID)
    CloseProgram(CurrentProgramID)
    CurrentProgramID = 0
    CurrentCommandRunning = #False

    If exitCode = 0
      PopulateListFromOutput(CurrentCommandRefresh, CurrentCommandOutput)
    Else
      AppendOutputLine("Command exited with code " + Str(exitCode) + ".")
    EndIf

    UpdateCompletionStatus(exitCode, CurrentCommandRefresh)
    ResetCurrentCommandState()
    StartNextCommand()
    If CurrentCommandRunning Or ListSize(CommandQueue()) > 0
      UpdateStatusBar()
    Else
      UpdateUiState()
    EndIf
  EndIf
EndProcedure

Procedure SaveLogToFile()
  Protected defaultName$
  Protected logFile$

  If OutputLog = ""
    StatusBarText(#StatusBar, 0, "Nothing to save!")
    ProcedureReturn
  EndIf
  
  defaultName$ = #APP_NAME + "-" + FormatDate("[%yy-%mm-%dd]-[%hh-%ii-%ss]", Date()) + ".log"
  logFile$ = SaveFileRequester("Save Log", AppPath + defaultName$, "Log files (*.log)|*.log|Text files (*.txt)|*.txt|All files (*.*)|*.*", 0)
  If logFile$ = ""
    StatusBarText(#StatusBar, 0, "Save cancelled.")
    ProcedureReturn
  EndIf

  If CreateFile(0, logFile$)
    WriteString(0, OutputLog)
    CloseFile(0)
    StatusBarText(#StatusBar, 0, "Log saved to: " + logFile$)
  Else
    StatusBarText(#StatusBar, 0, "Failed to save log!")
  EndIf
EndProcedure

; -------------------------------
; DISM Logic
; -------------------------------

Procedure.s ExtractTableValue(line$)
  Protected value$

  line$ = Trim(RemoveString(line$, #CR$))
  If line$ = "" Or FindString(line$, "|") = 0
    ProcedureReturn ""
  EndIf

  value$ = Trim(StringField(line$, 1, "|"))
  If value$ = "" Or FindString(value$, "---")
    ProcedureReturn ""
  EndIf

  ProcedureReturn value$
EndProcedure

Procedure.s NormalizeFieldName(value$)
  value$ = LCase(Trim(value$))
  value$ = RemoveString(value$, " ")
  value$ = RemoveString(value$, #TAB$)
  ProcedureReturn value$
EndProcedure

Procedure.s ExtractNamedValue(line$, fieldNames$)
  Protected colonPos.i
  Protected fieldName$
  Protected i.i
  Protected expectedField$

  line$ = Trim(RemoveString(line$, #CR$))
  colonPos = FindString(line$, ":")
  If colonPos = 0
    ProcedureReturn ""
  EndIf

  fieldName$ = NormalizeFieldName(Left(line$, colonPos - 1))
  For i = 1 To CountString(fieldNames$, "|") + 1
    expectedField$ = NormalizeFieldName(StringField(fieldNames$, i, "|"))
    If expectedField$ <> "" And fieldName$ = expectedField$
      ProcedureReturn Trim(Mid(line$, colonPos + 1))
    EndIf
  Next

  ProcedureReturn ""
EndProcedure

Procedure UpdateListFromOutput(gadget, output$, prefix$ = "", fieldNames$ = "")
  Protected i.i, count.i, value$, comparePrefix$, line$, tableStarted.i

  ClearGadgetItems(gadget)

  count = CountString(output$, #LF$)
  comparePrefix$ = LCase(prefix$)

  For i = 1 To count + 1
    line$ = Trim(RemoveString(StringField(output$, i, #LF$), #CR$))
    If line$ = ""
      Continue
    EndIf

    If Not tableStarted
      If FindString(line$, "---")
        tableStarted = #True
      EndIf
    EndIf

    value$ = ""
    If tableStarted And FindString(line$, "|")
      value$ = ExtractTableValue(line$)
    EndIf

    If value$ = "" And fieldNames$ <> ""
      value$ = ExtractNamedValue(line$, fieldNames$)
    EndIf

    If value$ <> ""
      If comparePrefix$ = "" Or Left(LCase(value$), Len(comparePrefix$)) = comparePrefix$
        If CountGadgetItems(gadget) = 0 Or GetGadgetItemText(gadget, CountGadgetItems(gadget) - 1) <> value$
          AddGadgetItem(gadget, -1, value$)
        EndIf
      EndIf
    EndIf
  Next
EndProcedure

Procedure.s GetSelectedListItem(gadget)
  Protected itemIndex.i

  itemIndex = GetGadgetState(gadget)
  If itemIndex < 0
    ProcedureReturn ""
  EndIf

  ProcedureReturn Trim(GetGadgetItemText(gadget, itemIndex, 0))
EndProcedure

Procedure.i GetRefreshListGadget(refreshMode.i)
  Select refreshMode
    Case #Refresh_Packages
      ProcedureReturn #List_Packages
    Case #Refresh_Features
      ProcedureReturn #List_Features
    Case #Refresh_Drivers
      ProcedureReturn #List_Drivers
    Case #Refresh_Appx
      ProcedureReturn #List_Appx
  EndSelect

  ProcedureReturn -1
EndProcedure

Procedure.s GetRefreshListLabel(refreshMode.i)
  Select refreshMode
    Case #Refresh_Packages
      ProcedureReturn "packages"
    Case #Refresh_Features
      ProcedureReturn "features"
    Case #Refresh_Drivers
      ProcedureReturn "drivers"
    Case #Refresh_Appx
      ProcedureReturn "Appx packages"
  EndSelect

  ProcedureReturn "items"
EndProcedure

Procedure PopulateListFromOutput(refreshMode.i, output$)
  Protected gadget.i = GetRefreshListGadget(refreshMode.i)
  Protected label$
  Protected itemCount.i

  Select refreshMode
    Case #Refresh_Packages
      UpdateListFromOutput(#List_Packages, output$, "package_", "Package Identity")
    Case #Refresh_Features
      UpdateListFromOutput(#List_Features, output$, "", "Feature Name")
    Case #Refresh_Drivers
      UpdateListFromOutput(#List_Drivers, output$, "oem", "Published Name")
    Case #Refresh_Appx
      UpdateListFromOutput(#List_Appx, output$, "", "PackageName|Package Name")
  EndSelect

  If gadget >= 0
    itemCount = CountGadgetItems(gadget)
    label$ = GetRefreshListLabel(refreshMode.i)
    If itemCount > 0
      StatusBarText(#StatusBar, 0, "Loaded " + Str(itemCount) + " " + label$ + ".")
    Else
      StatusBarText(#StatusBar, 0, "Refresh completed, but no " + label$ + " were parsed. Check the output log.")
      AppendOutputLine("Warning: Refresh completed but no " + label$ + " were parsed from DISM output.")
    EndIf
  EndIf
EndProcedure

Procedure UpdateCompletionStatus(exitCode.i, refreshMode.i)
  If exitCode <> 0
    StatusBarText(#StatusBar, 0, "Command exited with code " + Str(exitCode) + ".")
  ElseIf refreshMode = #Refresh_None
    StatusBarText(#StatusBar, 0, "Command completed successfully.")
  EndIf
EndProcedure

Procedure RefreshListByMode(refreshMode.i)
  Select refreshMode
    Case #Refresh_Packages
      QueueCommand("Refresh package list", "/online /english /get-packages", #Refresh_Packages)
    Case #Refresh_Features
      QueueCommand("Refresh feature list", "/online /english /get-features", #Refresh_Features)
    Case #Refresh_Drivers
      QueueCommand("Refresh driver list", "/online /english /get-drivers", #Refresh_Drivers)
    Case #Refresh_Appx
      QueueCommand("Refresh Appx package list", "/online /english /get-provisionedappxpackages", #Refresh_Appx)
  EndSelect
EndProcedure

Procedure RefreshPackages()
  RefreshListByMode(#Refresh_Packages)
EndProcedure

Procedure RefreshFeatures()
  RefreshListByMode(#Refresh_Features)
EndProcedure

Procedure RefreshDrivers()
  RefreshListByMode(#Refresh_Drivers)
EndProcedure

Procedure RefreshAppx()
  RefreshListByMode(#Refresh_Appx)
EndProcedure

; -------------------------------
; UI
; -------------------------------

Procedure.i OpenMainWindow()
  If OpenWindow(#Window_Main, 0, 0, 900, 700, #APP_NAME + " " + Version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
    
    PanelGadget(#Panel_Main, 10, 10, 880, 300)
    
    ; TAB 1: Cleanup & Repair
    AddGadgetItem(#Panel_Main, -1, "Cleanup & Repair")
      CheckBoxGadget(#Check_Analyze,   20, 20, 200, 25, "Analyze Component Store")
      CheckBoxGadget(#Check_Scan,      20, 50, 200, 25, "Scan Health")
      CheckBoxGadget(#Check_Check,     20, 80, 200, 25, "Check Health")
      CheckBoxGadget(#Check_Cleanup,   250, 20, 200, 25, "Start Component Cleanup")
      CheckBoxGadget(#Check_Resetbase, 250, 50, 200, 25, "Reset Base")
      CheckBoxGadget(#Check_Restore,   250, 80, 200, 25, "Restore Health")
      ButtonGadget(#Button_RunCleanup, 20, 120, 150, 30, "Queue Selected")
      
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
    
    TextGadget(#Text_QueueStatus, 10, 320, 340, 20, "Queue idle")
    ButtonGadget(#Button_ClearQueue, 360, 315, 120, 30, "Clear Queue")
    ButtonGadget(#Button_CancelCommand, 490, 315, 120, 30, "Cancel Current")

    ; Common Output Area
    EditorGadget(#Editor_Output, 10, 350, 880, 270, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)

    ; Bottom Buttons
    ButtonGadget(#Button_SaveLog, 10, 630, 120, 30, "Save Log")
    ButtonGadget(#Button_About,   620, 630, 120, 30, "About")
    ButtonGadget(#Button_Exit,    770, 630, 120, 30, "Exit")
    
    CreateStatusBar(#StatusBar, WindowID(#Window_Main))
    AddStatusBarField(880)
    StatusBarText(#StatusBar, 0, "Ready.")
    AddWindowTimer(#Window_Main, #Timer_CommandPump, 100)
    UpdateUiState()
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

; -------------------------------
; Main Loop
; -------------------------------

If Not OpenMainWindow()
  MessageRequester("Error", "Could not open the main window.", #PB_MessageRequester_Error)
  If hMutex
    CloseHandle_(hMutex)
  EndIf
  End
EndIf

Define Event.i
Define.s pkgPath$
Define.s destDir$

Repeat
  Event = WaitWindowEvent()

  Select Event
    Case #PB_Event_CloseWindow
      Exit()

    Case #PB_Event_Timer
      If EventTimer() = #Timer_CommandPump
        PumpCurrentCommand()
      EndIf
      
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #Button_RunCleanup
          QueueCheckedCleanupCommand(#Check_Analyze, "Analyze component store", "/online /cleanup-image /analyzecomponentstore")
          QueueCheckedCleanupCommand(#Check_Scan, "Scan image health", "/online /cleanup-image /scanhealth")
          QueueCheckedCleanupCommand(#Check_Check, "Check image health", "/online /cleanup-image /checkhealth")
          QueueCheckedCleanupCommand(#Check_Cleanup, "Start component cleanup", "/online /cleanup-image /startcomponentcleanup")
          QueueCheckedCleanupCommand(#Check_Resetbase, "Reset component base", "/online /cleanup-image /startcomponentcleanup /resetbase", #True)
          QueueCheckedCleanupCommand(#Check_Restore, "Restore image health", "/online /cleanup-image /restorehealth", #True)

        Case #Button_GetPackages
          RefreshPackages()
          
        Case #Button_AddPackage
          pkgPath$ = OpenFileRequester("Select Package", "", "CAB files (*.cab)|*.cab|MSU files (*.msu)|*.msu|All files (*.*)|*.*", 0)
          If pkgPath$
            QueueCommandAndRefresh("Add package", "/online /add-package /packagepath:" + QuoteArgument(pkgPath$) + " /norestart", #Refresh_Packages, #True)
          EndIf
          
        Case #Button_RemovePackage
          QueueSelectedListCommand(#List_Packages, "Remove package ", "/online /remove-package /packagename:", #Refresh_Packages, "Select a package first.", "Remove Package", "Remove package ", "? This changes the current Windows image.", "Package removal cancelled.")

        Case #Button_GetFeatures
          RefreshFeatures()
          
        Case #Button_EnableFeature
          QueueSelectedListCommand(#List_Features, "Enable feature ", "/online /enable-feature /featurename:", #Refresh_Features, "Select a feature first.", "Enable Feature", "Enable feature ", "?", "Feature enable cancelled.")
          
        Case #Button_DisableFeature
          QueueSelectedListCommand(#List_Features, "Disable feature ", "/online /disable-feature /featurename:", #Refresh_Features, "Select a feature first.", "Disable Feature", "Disable feature ", "? This may affect Windows components.", "Feature disable cancelled.")

        Case #Button_GetDrivers
          RefreshDrivers()

        Case #Button_ExportDrivers
          destDir$ = PathRequester("Select Destination Folder", "")
          If destDir$
            QueueCommand("Export drivers", "/online /export-driver /destination:" + QuoteArgument(destDir$), #Refresh_None, #True)
          EndIf

        Case #Button_GetAppx
          RefreshAppx()
          
        Case #Button_RemoveAppx
          QueueSelectedListCommand(#List_Appx, "Remove Appx package ", "/online /remove-provisionedappxpackage /packagename:", #Refresh_Appx, "Select an Appx package first.", "Remove Appx Package", "Remove provisioned Appx package ", " for new users?", "Appx removal cancelled.")

        Case #Button_SaveLog
          SaveLogToFile()

        Case #Button_ClearQueue
          ClearCommandQueue()

        Case #Button_CancelCommand
          ClearCommandQueue()
          StopCurrentCommand(#True, #False)
          StatusBarText(#StatusBar, 0, "Command queue cleared.")
          
        Case #Button_About
          MessageRequester("About", #APP_NAME + " " + Version + #CRLF$ + "Queued DISM management interface" + #CRLF$ + "Contact: " + #EMAIL_NAME)
          
        Case #Button_Exit
          Exit()
          
      EndSelect
  EndSelect
ForEver

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 83
; FirstLine = 66
; Folding = ------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyDISMGUI.ico
; Executable = ..\HandyDismGUI.exe
; DisableDebugger
; IncludeVersionInfo
; VersionField0 = 1,0,0,4
; VersionField1 = 1,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = HandyDismGUI
; VersionField4 = 1.0.0.4
; VersionField5 = 1.0.0.4
; VersionField6 = A GUI for DISM from Microsoft
; VersionField7 = HandyDismGUI
; VersionField8 = HandyDismGUI.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
