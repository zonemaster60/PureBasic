; HandyLNKMaker - PB 6.30 beta 5
; - GUI-based Shortcut Wizard
; - Select EXE, check existence, and choose shortcut type/platform
; - Handles elevation for Program Files folder creation

EnableExplicit

; ====== Constants ======

#APP_NAME                 = "HandyLNKMaker"
#EMAIL_NAME               = "zonemaster60@gmail.com"
#LOG_FILE_NAME            = "HandyLNKMaker.log"

#CSIDL_DESKTOPDIRECTORY   = $10
#CSIDL_PROGRAM_FILES      = $26
#CSIDL_PROGRAM_FILESX86   = $2A

#TOKEN_QUERY              = $0008
#TokenElevation           = 20

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
  #Frame_Platform
  #Opt_x64
  #Opt_x86
  #Btn_Finish
  #Btn_Exit
EndEnumeration

Global version.s = "v1.0.0.5 Wizard"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

Structure TOKEN_ELEVATION
  TokenIsElevated.l
EndStructure

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; ====== Logging ======

Procedure LogMessage(msg.s)
  Protected file = OpenFile(#PB_Any, #LOG_FILE_NAME, #PB_File_Append)
  If file
    WriteStringN(file, FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + " - " + msg)
    CloseFile(file)
  EndIf
EndProcedure

Procedure Exit()
  Define Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure

; ====== Modules ======

DeclareModule SpecialFolders
  Declare.s GetSpecialFolder(id.l)
EndDeclareModule

Module SpecialFolders
  Procedure.s GetSpecialFolder(id.l)
    Protected path.s, *ItemId.ITEMIDLIST
    If SHGetSpecialFolderLocation_(0, id, @*ItemId) = #NOERROR
      path = Space(#MAX_PATH)
      If SHGetPathFromIDList_(*ItemId, @path)
        path = Trim(path)
        If path <> ""
          If Right(path, 1) <> "\" : path + "\" : EndIf
          ProcedureReturn path
        EndIf
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

Procedure.b IsProcessElevated()
  Protected hToken.i, elevation.TOKEN_ELEVATION, size.l
  If OpenProcessToken_(GetCurrentProcess_(), #TOKEN_QUERY, @hToken)
    If GetTokenInformation_(hToken, #TokenElevation, @elevation, SizeOf(TOKEN_ELEVATION), @size)
      CloseHandle_(hToken)
      ProcedureReturn Bool(elevation\TokenIsElevated)
    EndIf
    CloseHandle_(hToken)
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure.b EnsureDirectory(path.s)
  Protected res.i = FileSize(path)
  If res = -1
    If CreateDirectory(path)
      LogMessage("CREATED DIRECTORY: " + path)
      ProcedureReturn #True
    Else
      Protected err.l = GetLastError_()
      LogMessage("FAILED TO CREATE DIRECTORY: " + path + " - ERROR: " + GetSystemErrorMessage(err))
      ProcedureReturn #False
    EndIf
  ElseIf res = -2
    LogMessage("DIRECTORY ALREADY EXISTS: " + path)
    ProcedureReturn #True
  Else
    LogMessage("FILE CONFLICT: Path exists as a file, not a directory: " + path)
    ProcedureReturn #False
  EndIf
EndProcedure

; ====== Main UI ======

Procedure OpenWizard()
  If OpenWindow(#MainWindow, 0, 0, 450, 350, #APP_NAME + " " + version, #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    TextGadget(#Txt_Intro, 20, 20, 410, 40, "Welcome to the Shortcut Wizard. Please select your program and choose where you want to create the shortcuts.")
    
    TextGadget(#Txt_Path, 20, 80, 410, 20, "1. Path to Program (EXE):")
    StringGadget(#String_Path, 20, 100, 330, 24, "")
    ButtonGadget(#Btn_Browse, 360, 100, 70, 24, "Browse...")
    
    TextGadget(#Txt_Options, 20, 150, 410, 20, "2. Select Shortcut Locations:")
    CheckBoxGadget(#Chk_Desktop, 40, 175, 150, 20, "Desktop Shortcut")
    CheckBoxGadget(#Chk_Startup, 40, 200, 150, 20, "Startup Shortcut")
    
    FrameGadget(#Frame_Platform, 240, 150, 180, 80, " Platform ")
    OptionGadget(#Opt_x64, 260, 175, 140, 20, "64-bit (Program Files)")
    OptionGadget(#Opt_x86, 260, 200, 140, 20, "32-bit (x86)")
    SetGadgetState(#Opt_x64, 1)
    
    ButtonGadget(#Btn_Finish, 115, 290, 100, 30, "Finish")
    ButtonGadget(#Btn_Exit, 235, 290, 100, 30, "Exit")
    
    GadgetToolTip(#Btn_Finish, "Create the selected shortcuts")
  EndIf
EndProcedure

Procedure HandleFinish()
  Protected exePath.s = GetGadgetText(#String_Path)
  Protected lnkName.s = GetFilePart(exePath, #PB_FileSystem_NoExtension)
  Protected targetDir.s, specialDir.s, desktopDir.s, startupDir.s
  Protected res.l, success.b = #True
  
  If exePath = "" Or FileSize(exePath) < 0
    MessageRequester("Error", "Please select a valid EXE file first.", #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  
  If GetGadgetState(#Chk_Desktop) = 0 And GetGadgetState(#Chk_Startup) = 0
    MessageRequester("Information", "Please select at least one shortcut location.", #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf
  
  ; Resolve base folders
  If GetGadgetState(#Opt_x64)
    specialDir = SpecialFolders::GetSpecialFolder(#CSIDL_PROGRAM_FILES)
  Else
    specialDir = SpecialFolders::GetSpecialFolder(#CSIDL_PROGRAM_FILESX86)
  EndIf
  
  desktopDir = SpecialFolders::GetSpecialFolder(#CSIDL_DESKTOPDIRECTORY)
  startupDir = SpecialFolders::GetSpecialFolder(#CSIDL_ALTSTARTUP)
  
  targetDir = specialDir + lnkName
  
  ; Elevation Check
  If Not IsProcessElevated()
    MessageRequester("Admin Required", "Administrator rights are needed to create folders in Program Files.", #PB_MessageRequester_Warning)
    ProcedureReturn
  EndIf
  
  If Not EnsureDirectory(targetDir)
    MessageRequester("Error", "Could not create target directory:" + #CRLF$ + targetDir, #PB_MessageRequester_Error)
    ProcedureReturn
  EndIf
  
  ; Create the links
  If GetGadgetState(#Chk_Desktop)
    Protected deskLnk.s = desktopDir + lnkName + ".lnk"
    res = ShellLink::CreateShellLink(exePath, deskLnk, "", "Start " + lnkName, GetPathPart(exePath), exePath, 0)
    If res = #S_OK
      LogMessage("SUCCESS: Desktop shortcut created: " + deskLnk)
    Else
      LogMessage("FAILURE: Desktop shortcut creation failed (0x" + Hex(res) + "): " + GetSystemErrorMessage(res))
      success = #False
    EndIf
  EndIf
  
  If GetGadgetState(#Chk_Startup)
    Protected startLnk.s = startupDir + lnkName + ".lnk"
    res = ShellLink::CreateShellLink(exePath, startLnk, "", "Start " + lnkName, GetPathPart(exePath), exePath, 0)
    If res = #S_OK
      LogMessage("SUCCESS: Startup shortcut created: " + startLnk)
    Else
      LogMessage("FAILURE: Startup shortcut creation failed (0x" + Hex(res) + "): " + GetSystemErrorMessage(res))
      success = #False
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
OpenWizard()

Repeat
  Define Event = WaitWindowEvent()
  Select Event
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #Btn_Browse
          Define File.s = OpenFileRequester("Select Program EXE", "", "Executable (*.exe)|*.exe", 0)
          If File <> ""
            SetGadgetText(#String_Path, File)
          EndIf
          
        Case #Btn_Finish
          HandleFinish()
          
        Case #Btn_Exit
          Exit()
          
      EndSelect
      
    Case #PB_Event_CloseWindow
      Exit()
      
  EndSelect
Until Event = #PB_Event_CloseWindow

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 309
; FirstLine = 279
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyLNKMaker.ico
; Executable = ..\HandyLNKMaker.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,5
; VersionField1 = 1,0,0,5
; VersionField2 = ZoneSoft
; VersionField3 = HandyLNKMaker
; VersionField4 = 1.0.0.5
; VersionField5 = 1.0.0.5
; VersionField6 = HandyLNKMaker - Shortcut Creation Wizard
; VersionField7 = HandyLNKMaker
; VersionField8 = HandyLNKMaker.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60