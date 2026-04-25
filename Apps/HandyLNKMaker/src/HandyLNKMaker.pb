; HandyLNKMaker - PB 6.30 beta 5
; - GUI-based Shortcut Wizard
; - Select EXE and choose shortcut type
; - Points shortcuts directly to the selected EXE path
; - Duplicate name protection (auto-increment suffix)

EnableExplicit

; ====== Constants ======

#APP_NAME                 = "HandyLNKMaker"
#APP_VERSION              = "v1.0.1.0 Wizard"
#EMAIL_NAME               = "zonemaster60@gmail.com"
#LOG_FILE_NAME            = "HandyLNKMaker.log"

#CSIDL_DESKTOPDIRECTORY   = $10
#CSIDL_STARTUP            = $07

#ERROR_ALREADY_EXISTS     = 183

#WINDOW_WIDTH             = 450
#WINDOW_HEIGHT            = 280

#SHORTCUT_TARGET_FILTER   = "Executable (*.exe)|*.exe"

#MSG_INVALID_EXE          = "Please select a valid EXE file first."
#MSG_SELECT_LOCATION      = "Please select at least one shortcut location."

Enumeration Windows
  #MainWindow
EndEnumeration

Enumeration ShortcutActions
  #ShortcutAction_Finish
  #ShortcutAction_Exit
EndEnumeration

Enumeration Gadgets
  #Txt_Intro
  #Txt_Path
  #String_Path
  #Btn_Browse
  #Txt_Options
  #Chk_Desktop
  #Chk_Startup
  #Btn_Finish
  #Btn_Exit
EndEnumeration

Global AppVersion.s = #APP_VERSION
Global AppPath.s = GetPathPart(ProgramFilename())
Global LogFilePath.s = AppPath + #LOG_FILE_NAME
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global SingleInstanceMutex.i
Global QuitRequested.b
SingleInstanceMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If SingleInstanceMutex And GetLastError_() = #ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(SingleInstanceMutex)
  End
EndIf

; ====== Logging ======

Procedure LogMessage(Message.s)
  Protected file = OpenFile(#PB_Any, LogFilePath, #PB_File_Append)
  If file
    WriteStringN(file, FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + " - " + Message)
    CloseFile(file)
  EndIf
EndProcedure

Procedure ReleaseSingleInstanceMutex()
  If SingleInstanceMutex
    CloseHandle_(SingleInstanceMutex)
    SingleInstanceMutex = 0
  EndIf
EndProcedure

Procedure.b ConfirmExit()
  Define requestResult = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  ProcedureReturn Bool(requestResult = #PB_MessageRequester_Yes)
EndProcedure

; ====== Modules ======

DeclareModule SpecialFolders
  Declare.s GetSpecialFolder(id.l)
EndDeclareModule

Module SpecialFolders
  Procedure.s GetSpecialFolder(id.l)
    Protected path.s = Space(#MAX_PATH)

    If SHGetFolderPath_(0, id, 0, 0, @path) = #S_OK
      path = PeekS(@path)
      If path <> ""
        If Right(path, 1) <> "\" : path + "\" : EndIf
        ProcedureReturn path
      EndIf
    EndIf

    ProcedureReturn ""
  EndProcedure
EndModule

DeclareModule ShellLink
  Declare.l CreateShellLink(targetPath.s, shortcutPath.s, arguments.s, description.s, workingDirectory.s, iconPath.s, iconIndex.l)
EndDeclareModule

Module ShellLink
  Procedure.l CreateShellLink(targetPath.s, shortcutPath.s, arguments.s, description.s, workingDirectory.s, iconPath.s, iconIndex.l)
    Protected hResult.l, initResult.l, ppf.IPersistFile
    CompilerIf #PB_Compiler_Unicode
      Protected psl.IShellLinkW
    CompilerElse
      Protected psl.IShellLinkA
    CompilerEndIf

    initResult = CoInitialize_(0)
    If initResult < 0
      ProcedureReturn initResult
    EndIf

    hResult = CoCreateInstance_(?CLSID_ShellLink, 0, 1, ?IID_IShellLink, @psl)
    If hResult >= 0 And psl
      hResult = psl\SetPath(targetPath)
      If hResult >= 0
        hResult = psl\SetArguments(arguments)
      EndIf
      If hResult >= 0
        hResult = psl\SetDescription(description)
      EndIf
      If hResult >= 0
        hResult = psl\SetWorkingDirectory(workingDirectory)
      EndIf
      If hResult >= 0
        hResult = psl\SetIconLocation(iconPath, iconIndex)
      EndIf
      If hResult >= 0
        hResult = psl\QueryInterface(?IID_IPersistFile, @ppf)
      EndIf
      If hResult >= 0 And ppf
        hResult = ppf\Save(shortcutPath, #True)
        ppf\Release()
      EndIf
      psl\Release()
    EndIf
    CoUninitialize_()
    DataSection
      CLSID_ShellLink:
      Data.l $00021401 : Data.w $0000,$0000 : Data.b $C0,$00,$00,$00,$00,$00,$00,$46
      IID_IShellLink:
      CompilerIf #PB_Compiler_Unicode
        Data.l $000214F9
      CompilerElse
        Data.l $000214EE
      CompilerEndIf
      Data.w $0000,$0000 : Data.b $C0,$00,$00,$00,$00,$00,$00,$46
      IID_IPersistFile:
      Data.l $0000010B : Data.w $0000,$0000 : Data.b $C0,$00,$00,$00,$00,$00,$00,$46
    EndDataSection
    ProcedureReturn hResult
  EndProcedure
EndModule

; ====== Helpers ======

Procedure.b IsSuccessHResult(Result.l)
  ProcedureReturn Bool(Result >= 0)
EndProcedure

Procedure.s GetHResultMessage(Result.l)
  Protected *buffer
  Protected length.l
  Protected message.s

  length = FormatMessage_(#FORMAT_MESSAGE_ALLOCATE_BUFFER | #FORMAT_MESSAGE_FROM_SYSTEM | #FORMAT_MESSAGE_IGNORE_INSERTS, 0, Result & $FFFFFFFF, 0, @*buffer, 0, 0)
  If length
    message = Trim(PeekS(*buffer))
    LocalFree_(*buffer)
    If message <> ""
      ProcedureReturn message
    EndIf
  EndIf

  ProcedureReturn "No system message available."
EndProcedure

Procedure.b IsValidExecutablePath(FilePath.s)
  Protected normalizedPath.s = Trim(FilePath)

  If normalizedPath = ""
    ProcedureReturn #False
  EndIf

  If FileSize(normalizedPath) < 0
    ProcedureReturn #False
  EndIf

  ProcedureReturn Bool(LCase(GetExtensionPart(normalizedPath)) = "exe")
EndProcedure

Procedure.s GetUniqueShortcutPath(BaseDir.s, AppName.s)
  Protected Counter.l = 0
  Protected FinalPath.s = BaseDir + AppName + ".lnk"
  
  While FileSize(FinalPath) >= 0
    Counter + 1
    FinalPath = BaseDir + AppName + " (" + Str(Counter) + ").lnk"
  Wend
  
  ProcedureReturn FinalPath
EndProcedure

Procedure.s GetSelectedLocationSummary()
  Protected locationSummary.s = ""

  If GetGadgetState(#Chk_Desktop)
    locationSummary = "Desktop"
  EndIf

  If GetGadgetState(#Chk_Startup)
    If locationSummary <> ""
      locationSummary + ", "
    EndIf
    locationSummary + "Startup"
  EndIf

  ProcedureReturn locationSummary
EndProcedure

Procedure UpdateFinishButtonState()
  Protected canFinish.b

  canFinish = Bool(IsValidExecutablePath(GetGadgetText(#String_Path)) And GetSelectedLocationSummary() <> "")
  DisableGadget(#Btn_Finish, Bool(canFinish = #False))
EndProcedure

Procedure.b CreateShortcutInSpecialFolder(FolderId.l, FolderLabel.s, ExePath.s, ShortcutName.s)
  Protected folderPath.s = SpecialFolders::GetSpecialFolder(FolderId)
  Protected linkPath.s
  Protected result.l

  If folderPath = ""
    LogMessage("FAILURE: " + FolderLabel + " shortcut creation failed because the target folder could not be resolved.")
    ProcedureReturn #False
  EndIf

  linkPath = GetUniqueShortcutPath(folderPath, ShortcutName)
  LogMessage("INFO: Creating " + FolderLabel + " shortcut. Target=" + ExePath + " | Link=" + linkPath + " | WorkingDir=" + GetPathPart(ExePath))
  result = ShellLink::CreateShellLink(ExePath, linkPath, "", "Start " + ShortcutName, GetPathPart(ExePath), ExePath, 0)

  If IsSuccessHResult(result)
    LogMessage("SUCCESS: " + FolderLabel + " shortcut created: " + linkPath + " pointing to " + ExePath)
    ProcedureReturn #True
  EndIf

  LogMessage("FAILURE: " + FolderLabel + " shortcut creation failed (HRESULT 0x" + Hex(result) + "): " + GetHResultMessage(result))
  ProcedureReturn #False
EndProcedure

; ====== Main UI ======

Procedure.b OpenWizard()
  If OpenWindow(#MainWindow, 0, 0, #WINDOW_WIDTH, #WINDOW_HEIGHT, #APP_NAME + " " + AppVersion, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    TextGadget(#Txt_Intro, 20, 20, 410, 40, "Welcome to the Shortcut Wizard. Please select your program and choose where you want to create the shortcuts.")
    
    TextGadget(#Txt_Path, 20, 80, 410, 20, "1. Path to Program (EXE):")
    StringGadget(#String_Path, 20, 100, 330, 24, "")
    ButtonGadget(#Btn_Browse, 360, 100, 70, 24, "Browse...")
    
    TextGadget(#Txt_Options, 20, 150, 410, 20, "2. Select Shortcut Locations:")
    CheckBoxGadget(#Chk_Desktop, 40, 175, 150, 20, "Desktop Shortcut")
    CheckBoxGadget(#Chk_Startup, 40, 200, 150, 20, "Startup Shortcut")
    
    ButtonGadget(#Btn_Finish, 115, 230, 100, 30, "Finish")
    ButtonGadget(#Btn_Exit, 235, 230, 100, 30, "Exit")
    
    SetGadgetState(#Chk_Desktop, #True)
    GadgetToolTip(#Btn_Finish, "Create shortcuts for the selected EXE")
    GadgetToolTip(#String_Path, "Enter or browse to an .exe file")
    GadgetToolTip(#Chk_Desktop, "Create a shortcut on the desktop")
    GadgetToolTip(#Chk_Startup, "Create a shortcut in the startup folder")
    AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Return, #ShortcutAction_Finish)
    AddKeyboardShortcut(#MainWindow, #PB_Shortcut_Escape, #ShortcutAction_Exit)
    SetActiveGadget(#String_Path)
    UpdateFinishButtonState()
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure HandleFinish()
  Protected exePath.s = Trim(GetGadgetText(#String_Path))
  Protected lnkName.s = GetFilePart(exePath, #PB_FileSystem_NoExtension)
  Protected selectedLocations.s = GetSelectedLocationSummary()
  Protected createdLocations.s = ""
  Protected failedLocations.s = ""
  Protected success.b = #True
  
  If IsValidExecutablePath(exePath) = #False
    LogMessage("WARNING: Shortcut creation blocked because the selected path is invalid: " + exePath)
    MessageRequester("Error", #MSG_INVALID_EXE, #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  
  If selectedLocations = ""
    LogMessage("WARNING: Shortcut creation blocked because no shortcut locations were selected.")
    MessageRequester("Information", #MSG_SELECT_LOCATION, #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  LogMessage("INFO: Shortcut creation requested for EXE: " + exePath)
  LogMessage("INFO: Selected locations: " + selectedLocations)
  
  ; Create the links pointing directly to the entered path with unique naming protection
  If GetGadgetState(#Chk_Desktop)
    If CreateShortcutInSpecialFolder(#CSIDL_DESKTOPDIRECTORY, "Desktop", exePath, lnkName)
      createdLocations = "Desktop"
    Else
      failedLocations = "Desktop"
      success = #False
    EndIf
  EndIf
  
  If GetGadgetState(#Chk_Startup)
    If CreateShortcutInSpecialFolder(#CSIDL_STARTUP, "Startup", exePath, lnkName)
      If createdLocations <> ""
        createdLocations + #CRLF$
      EndIf
      createdLocations + "Startup"
    Else
      If failedLocations <> ""
        failedLocations + #CRLF$
      EndIf
      failedLocations + "Startup"
      success = #False
    EndIf
  EndIf
  
  If success
    MessageRequester("Success", "Shortcuts created successfully in:" + #CRLF$ + createdLocations, #PB_MessageRequester_Info)
    LogMessage("Wizard finished: Shortcuts created for " + lnkName)
  Else
    Protected failureMessage.s = "Some shortcuts could not be created. Check the log."

    If createdLocations <> ""
      failureMessage + #CRLF$ + #CRLF$ + "Created:" + #CRLF$ + createdLocations
    EndIf

    If failedLocations <> ""
      failureMessage + #CRLF$ + #CRLF$ + "Failed:" + #CRLF$ + failedLocations
    EndIf

    MessageRequester("Partial Failure", failureMessage, #PB_MessageRequester_Error)
    LogMessage("Wizard finished with partial failure for " + lnkName)
  EndIf
EndProcedure

; ====== Event Loop ======

LogMessage("=== Wizard Started ===")
LogMessage("INFO: Application path: " + AppPath)
If OpenWizard() = 0
  LogMessage("FAILURE: Main window could not be created.")
  ReleaseSingleInstanceMutex()
  End
EndIf

Repeat
  Define eventId = WaitWindowEvent()
  Select eventId
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #Btn_Browse
          Define initialDirectory.s = GetPathPart(GetGadgetText(#String_Path))
          If initialDirectory = ""
            initialDirectory = AppPath
          EndIf

          Define selectedFile.s = OpenFileRequester("Select Program EXE", initialDirectory, #SHORTCUT_TARGET_FILTER, 0)
          If selectedFile <> ""
            SetGadgetText(#String_Path, selectedFile)
          EndIf
          UpdateFinishButtonState()
          
        Case #String_Path, #Chk_Desktop, #Chk_Startup
          UpdateFinishButtonState()
          
        Case #Btn_Finish
          HandleFinish()
          
        Case #Btn_Exit
          If ConfirmExit()
            QuitRequested = #True
          EndIf
           
      EndSelect
      
    Case #PB_Event_Menu
      Select EventMenu()
        Case #ShortcutAction_Finish
          HandleFinish()

        Case #ShortcutAction_Exit
          If ConfirmExit()
            QuitRequested = #True
          EndIf
      EndSelect

    Case #PB_Event_CloseWindow
      If ConfirmExit()
        QuitRequested = #True
      EndIf
      
  EndSelect
Until QuitRequested

LogMessage("=== Wizard Closed ===")
ReleaseSingleInstanceMutex()

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 11
; FirstLine = 1
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyLNKMaker.ico
; Executable = ..\HandyLNKMaker.exe
; IncludeVersionInfo
; VersionField0 = 1,0,1,0
; VersionField1 = 1,0,1,0
; VersionField2 = ZoneSoft
; VersionField3 = HandyLNKMaker
; VersionField4 = 1.0.1.0
; VersionField5 = 1.0.1.0
; VersionField6 = HandyLNKMaker - Shortcut Creation Wizard
; VersionField7 = HandyLNKMaker
; VersionField8 = HandyLNKMaker.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60
