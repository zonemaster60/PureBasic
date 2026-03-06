; +-------------------------------------------------------------------------+
; | PB_RestorePointManager.pb                                               |
; | Reliable System Restore Point Manager for PureBasic v6.30 (x64)         |
; | Features: Create, List, and Delete Individual Restore Points            |
; | Requirement: Must be compiled with 'Request Administrator Mode'         |
; +-------------------------------------------------------------------------+

EnableExplicit

#APP_NAME = "PB_RestorePointManager"
Global version.s = "v1.0.0.0"

Global AppPath.s = GetFilePart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; --- API Structures ---
Structure RESTOREPOINTINFO
  dwEventType.l        ; 100 = BEGIN_SYSTEM_CHANGE, 101 = END_SYSTEM_CHANGE
  dwRestorePointType.l ; 0 = APPLICATION_INSTALL, 1 = APPLICATION_UNINSTALL, 12 = MODIFY_SETTINGS, 13 = CANCELLED_OPERATION
  llSequenceNumber.q
  szDescription.u[256] ; Using u[256] for fixed-size Unicode array
EndStructure

Structure STATEMGRSTATUS
  nStatus.l
  llSequenceNumber.q
EndStructure

Structure RestorePointEntry
  SequenceNumber.l
  Description.s
  CreationTime.s
EndStructure

; --- Prototypes ---
Prototype.l SRSetRestorePointW_Proto(*pRestorePtSpec, *pStatus)

Global NewList RPList.RestorePointEntry()

; --- Constants for GUI ---
Enumeration Windows
  #MainWin
EndEnumeration

Enumeration Gadgets
  #ListRP
  #BtnCreate
  #BtnDelete
  #BtnRefresh
  #BtnExit
  #TxtDesc
EndEnumeration

; --- Core Procedures ---


; Returns #True if the current process has Administrative privileges
Procedure.b IsUserAdmin()
  ; If we have "Request Administrator" enabled, we should be able to connect 
  ; to the Service Control Manager. This is a very reliable elevation check.
  Protected hSCM = OpenSCManager_(#Null, #Null, #SC_MANAGER_CONNECT)
  If hSCM
    CloseServiceHandle_(hSCM)
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure

; Creates a new system restore point
Procedure.b CreateRestorePoint(Description.s)
  Protected Lib = OpenLibrary(#PB_Any, "srclient.dll")
  If Not Lib : ProcedureReturn #False : EndIf
  
  Protected CreateRP.SRSetRestorePointW_Proto = GetFunction(Lib, "SRSetRestorePointW")
  Protected RP.RESTOREPOINTINFO
  Protected Status.STATEMGRSTATUS
  Protected Result.b = #False
  
  ; Setup "Begin" event
  RP\dwEventType = 100 ; BEGIN_SYSTEM_CHANGE
  RP\dwRestorePointType = 12 ; MODIFY_SETTINGS
  RP\llSequenceNumber = 0
  
  ; Safety: Truncate description to fit fixed buffer (255 chars + null)
  Description = Left(Description, 255)
  PokeS(@RP\szDescription, Description, -1, #PB_Unicode)
  
  If CreateRP(@RP, @Status)
    ; Successfully started, now finalize
    RP\dwEventType = 101 ; END_SYSTEM_CHANGE
    RP\llSequenceNumber = Status\llSequenceNumber
    If CreateRP(@RP, @Status)
      Result = #True
    EndIf
  EndIf
  
  CloseLibrary(Lib)
  ProcedureReturn Result
EndProcedure

; Lists all restore points into the RPList() linked list
Procedure.i ListRestorePoints()
  ClearList(RPList())
  
  ; Use a simpler string concatenation to avoid PowerShell -f operator issues
  Protected Command.s = "Get-ComputerRestorePoint | ForEach-Object { $_.SequenceNumber.ToString() + '|' + $_.Description + '|' + $_.CreationTime.ToString() }"
  Protected PS = RunProgram("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -Command " + Chr(34) + Command + Chr(34), "", #PB_Program_Open | #PB_Program_Read | #PB_Program_Hide)
  
  If PS
    While ProgramRunning(PS)
      While AvailableProgramOutput(PS)
        Protected Line.s = ReadProgramString(PS)
        If CountString(Line, "|") >= 2
          AddElement(RPList())
          RPList()\SequenceNumber = Val(StringField(Line, 1, "|"))
          RPList()\Description    = StringField(Line, 2, "|")
          RPList()\CreationTime   = StringField(Line, 3, "|")
        EndIf
      Wend
      Delay(1)
    Wend
    CloseProgram(PS)
    ProcedureReturn ListSize(RPList())
  EndIf
  ProcedureReturn 0
EndProcedure

Procedure Exit()
  Define Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    ClearList(RPList())
    CloseHandle_(hMutex)
    End
  EndIf
EndProcedure

; Deletes a specific restore point by its sequence number via WMI
Procedure.b DeleteRestorePoint(SeqNum.l)
  ; Command targets the SystemRestore WMI class and specifically checks success
  Protected Command.s = "$rp = Get-WmiObject -Namespace root\default -Class SystemRestore | Where-Object {$_.SequenceNumber -eq " + Str(SeqNum) + "}; " +
                        "if ($rp) { $res = $rp.Delete(); exit $res.ReturnValue } else { exit 1 }"
  
  Protected PS = RunProgram("powershell.exe", "-NoProfile -ExecutionPolicy Bypass -Command " + Chr(34) + Command + Chr(34), "", #PB_Program_Open | #PB_Program_Hide | #PB_Program_Wait)
  
  If PS
    Protected ExitCode = ProgramExitCode(PS)
    CloseProgram(PS)
    ; ReturnValue 0 indicates success in WMI
    ProcedureReturn Bool(ExitCode = 0)
  EndIf
  ProcedureReturn #False
EndProcedure

; --- GUI Procedures ---

Procedure RefreshGUIList()
  ClearGadgetItems(#ListRP)
  If ListRestorePoints() > 0
    ForEach RPList()
      AddGadgetItem(#ListRP, -1, Str(RPList()\SequenceNumber) + Chr(10) + RPList()\Description + Chr(10) + RPList()\CreationTime)
    Next
  EndIf
EndProcedure

Procedure OpenMainWindow()
  If OpenWindow(#MainWin, 0, 0, 600, 480, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    ListIconGadget(#ListRP, 10, 10, 580, 300, "ID", 60, #PB_ListIcon_FullRowSelect | #PB_ListIcon_AlwaysShowSelection)
    AddGadgetColumn(#ListRP, 1, "Description", 300)
    AddGadgetColumn(#ListRP, 2, "Creation Time", 200)
    
    TextGadget(#PB_Any, 10, 325, 100, 20, "New Point Name:")
    StringGadget(#TxtDesc, 110, 320, 380, 25, "Manual Restore Point")
    ButtonGadget(#BtnCreate, 500, 320, 90, 25, "Create")
    
    ButtonGadget(#BtnRefresh, 10, 380, 120, 40, "Refresh List")
    ButtonGadget(#BtnDelete, 140, 380, 120, 40, "Delete Selected")
    ButtonGadget(#BtnExit, 470, 380, 120, 40, "Exit")
    
    ProcedureReturn #True
  EndIf
  ProcedureReturn #False
EndProcedure


; --- Main Entry ---

If Not IsUserAdmin()
  MessageRequester("Error", "This application must be run as Administrator.", #PB_MessageRequester_Error)
  End
EndIf

If OpenMainWindow()
  RefreshGUIList()
  
  Repeat
    Define Event = WaitWindowEvent()
    
    Select Event
      Case #PB_Event_Gadget
        Select EventGadget()
          Case #BtnRefresh
            RefreshGUIList()
            
          Case #BtnCreate
            Define NewDesc.s = GetGadgetText(#TxtDesc)
            If NewDesc <> ""
              DisableGadget(#BtnCreate, 1) ; Disable during creation
              If CreateRestorePoint(NewDesc)
                MessageRequester("Success", "Restore Point Created.")
                RefreshGUIList()
              Else
                MessageRequester("Error", "Failed to create point (Frequency limit or disabled).")
              EndIf
              DisableGadget(#BtnCreate, 0)
            EndIf
            
          Case #BtnDelete
            Define Selected = GetGadgetState(#ListRP)
            If Selected <> -1
              Define ID.l = Val(GetGadgetItemText(#ListRP, Selected, 0))
              If MessageRequester("Confirm", "Delete restore point " + Str(ID) + "?", #PB_MessageRequester_YesNo) = #PB_MessageRequester_Yes
                If DeleteRestorePoint(ID)
                  MessageRequester("Success", "Restore Point Deleted.")
                  RefreshGUIList()
                Else
                  MessageRequester("Error", "Failed to delete point.")
                EndIf
              EndIf
            EndIf
            
          Case #BtnExit
            Exit()
            
        EndSelect
        
      Case #PB_Event_CloseWindow
        Exit()
    EndSelect
  Until Event = #PB_Event_CloseWindow
EndIf
End

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 174
; FirstLine = 150
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_RestorePointManager.ico
; Executable = ..\PB_RestorePointManager.exe