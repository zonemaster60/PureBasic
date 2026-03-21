; HandyLNKMaker - PB 6.30 beta 5
; - GUI-based Shortcut Wizard
; - Select EXE and choose shortcut type
; - Points shortcuts directly to the selected EXE path
; - Duplicate name protection (auto-increment suffix)

EnableExplicit

; ====== Constants ======

#APP_NAME                 = "HandyLNKMaker"
#EMAIL_NAME               = "zonemaster60@gmail.com"
#LOG_FILE_NAME            = "HandyLNKMaker.log"

#CSIDL_DESKTOPDIRECTORY   = $10
#CSIDL_STARTUP            = $07

Enumeration Windows
  #MainWindow
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

Global version.s = "v1.0.0.9 Wizard"
Global AppPath.s = GetPathPart(ProgramFilename())
Global LogFilePath.s = AppPath + #LOG_FILE_NAME
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
Global QuitRequested.b
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; ====== Logging ======

Procedure LogMessage(msg.s)
  Protected file = OpenFile(#PB_Any, LogFilePath, #PB_File_Append)
  If file
    WriteStringN(file, FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + " - " + msg)
    CloseFile(file)
  EndIf
EndProcedure

Procedure ReleaseSingleInstanceMutex()
  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
EndProcedure

Procedure.b ConfirmExit()
  Define Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  ProcedureReturn Bool(Req = #PB_MessageRequester_Yes)
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
  Declare.l CreateShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index.l)
EndDeclareModule

Module ShellLink
  Procedure.l CreateShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index.l)
    Protected hRes.l, ppf.IPersistFile
    CompilerIf #PB_Compiler_Unicode
      Protected psl.IShellLinkW
    CompilerElse
      Protected psl.IShellLinkA
    CompilerEndIf
    CoInitialize_(0)
    hRes = CoCreateInstance_(?CLSID_ShellLink, 0, 1, ?IID_IShellLink, @psl)
    If hRes = #S_OK And psl
      psl\SetPath(obj)
      psl\SetArguments(arg)
      psl\SetDescription(desc)
      psl\SetWorkingDirectory(dir)
      psl\SetIconLocation(icon, index)
      hRes = psl\QueryInterface(?IID_IPersistFile, @ppf)
      If hRes = #S_OK And ppf
        hRes = ppf\Save(lnk, #True)
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
    ProcedureReturn hRes
  EndProcedure
EndModule

; ====== Helpers ======

Procedure.s GetSystemErrorMessage(ErrorCode.l)
  Protected *Buffer, Length.l, Message.s
  Length = FormatMessage_(#FORMAT_MESSAGE_ALLOCATE_BUFFER | #FORMAT_MESSAGE_FROM_SYSTEM | #FORMAT_MESSAGE_IGNORE_INSERTS, 0, ErrorCode, 0, @*Buffer, 0, 0)
  If Length
    Message = PeekS(*Buffer)
    LocalFree_(*Buffer)
    ProcedureReturn Trim(Message)
  Else
    ProcedureReturn "Unknown Error (0x" + Hex(ErrorCode) + ")"
  EndIf
EndProcedure

Procedure.b IsSuccessHResult(Result.l)
  ProcedureReturn Bool(Result >= 0)
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

; ====== Main UI ======

Procedure.b OpenWizard()
  If OpenWindow(#MainWindow, 0, 0, 450, 280, #APP_NAME + " " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    TextGadget(#Txt_Intro, 20, 20, 410, 40, "Welcome to the Shortcut Wizard. Please select your program and choose where you want to create the shortcuts.")
    
    TextGadget(#Txt_Path, 20, 80, 410, 20, "1. Path to Program (EXE):")
    StringGadget(#String_Path, 20, 100, 330, 24, "")
    ButtonGadget(#Btn_Browse, 360, 100, 70, 24, "Browse...")
    
    TextGadget(#Txt_Options, 20, 150, 410, 20, "2. Select Shortcut Locations:")
    CheckBoxGadget(#Chk_Desktop, 40, 175, 150, 20, "Desktop Shortcut")
    CheckBoxGadget(#Chk_Startup, 40, 200, 150, 20, "Startup Shortcut")
    
    ButtonGadget(#Btn_Finish, 115, 230, 100, 30, "Finish")
    ButtonGadget(#Btn_Exit, 235, 230, 100, 30, "Exit")
    
    GadgetToolTip(#Btn_Finish, "Create shortcuts for the selected EXE")
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure HandleFinish()
  Protected exePath.s = Trim(GetGadgetText(#String_Path))
  Protected lnkName.s = GetFilePart(exePath, #PB_FileSystem_NoExtension)
  Protected desktopDir.s, startupDir.s
  Protected res.l, success.b = #True
  
  If exePath = "" Or FileSize(exePath) < 0
    MessageRequester("Error", "Please select a valid EXE file first.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf

  If LCase(GetExtensionPart(exePath)) <> "exe"
    MessageRequester("Error", "Please select a valid EXE file first.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  
  If GetGadgetState(#Chk_Desktop) = 0 And GetGadgetState(#Chk_Startup) = 0
    MessageRequester("Information", "Please select at least one shortcut location.", #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  ; Create the links pointing directly to the entered path with unique naming protection
  If GetGadgetState(#Chk_Desktop)
    desktopDir = SpecialFolders::GetSpecialFolder(#CSIDL_DESKTOPDIRECTORY)
    If desktopDir = ""
      LogMessage("FAILURE: Desktop shortcut creation failed because the desktop folder could not be resolved.")
      success = #False
    Else
      Protected deskLnk.s = GetUniqueShortcutPath(desktopDir, lnkName)
      res = ShellLink::CreateShellLink(exePath, deskLnk, "", "Start " + lnkName, GetPathPart(exePath), exePath, 0)
      If IsSuccessHResult(res)
        LogMessage("SUCCESS: Desktop shortcut created: " + deskLnk + " pointing to " + exePath)
      Else
        LogMessage("FAILURE: Desktop shortcut creation failed (0x" + Hex(res) + "): " + GetSystemErrorMessage(res))
        success = #False
      EndIf
    EndIf
  EndIf
  
  If GetGadgetState(#Chk_Startup)
    startupDir = SpecialFolders::GetSpecialFolder(#CSIDL_STARTUP)
    If startupDir = ""
      LogMessage("FAILURE: Startup shortcut creation failed because the startup folder could not be resolved.")
      success = #False
    Else
      Protected startLnk.s = GetUniqueShortcutPath(startupDir, lnkName)
      res = ShellLink::CreateShellLink(exePath, startLnk, "", "Start " + lnkName, GetPathPart(exePath), exePath, 0)
      If IsSuccessHResult(res)
        LogMessage("SUCCESS: Startup shortcut created: " + startLnk + " pointing to " + exePath)
      Else
        LogMessage("FAILURE: Startup shortcut creation failed (0x" + Hex(res) + "): " + GetSystemErrorMessage(res))
        success = #False
      EndIf
    EndIf
  EndIf
  
  If success
    MessageRequester("Success", "Shortcuts created successfully!", #PB_MessageRequester_Info)
    LogMessage("Wizard finished: Shortcuts created for " + lnkName)
  Else
    MessageRequester("Partial Failure", "Some shortcuts could not be created. Check the log.", #PB_MessageRequester_Error)
  EndIf
EndProcedure

; ====== Event Loop ======

LogMessage("=== Wizard Started ===")
If OpenWizard() = 0
  LogMessage("FAILURE: Main window could not be created.")
  ReleaseSingleInstanceMutex()
  End
EndIf

Repeat
  Define Event = WaitWindowEvent()
  Select Event
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #Btn_Browse
          Define InitialDirectory.s = GetPathPart(GetGadgetText(#String_Path))
          If InitialDirectory = ""
            InitialDirectory = AppPath
          EndIf

          Define File.s = OpenFileRequester("Select Program EXE", InitialDirectory, "Executable (*.exe)|*.exe", 0)
          If File <> ""
            SetGadgetText(#String_Path, File)
          EndIf
          
        Case #Btn_Finish
          HandleFinish()
          
        Case #Btn_Exit
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

ReleaseSingleInstanceMutex()

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 33
; FirstLine = 1
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyLNKMaker.ico
; Executable = ..\HandyLNKMaker.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,9
; VersionField1 = 1,0,0,9
; VersionField2 = ZoneSoft
; VersionField3 = HandyLNKMaker
; VersionField4 = 1.0.0.9
; VersionField5 = 1.0.0.9
; VersionField6 = HandyLNKMaker - Shortcut Creation Wizard
; VersionField7 = HandyLNKMaker
; VersionField8 = HandyLNKMaker.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60