; HandyLNKMaker - PB 6.30 beta 5
; - Creates folders under Program Files and Program Files (x86)
; - Creates Desktop and Startup links for x64 and x86 exes
; - Simple elevation check (admin required for Program Files)
; - Logging

EnableExplicit

; ====== Constants ======

#CSIDL_DESKTOPDIRECTORY   = $10
#CSIDL_WINDOWS            = $24
#CSIDL_PROGRAM_FILES      = $26
#CSIDL_PROGRAM_FILESX86   = $2A
; #CSIDL_ALTSTARTUP is built-in in PB (do NOT redefine)

#LOG_FILE_NAME            = "HandyLNKMaker.log"
#TOKEN_QUERY              = $0008
#TokenElevation           = 20

Structure TOKEN_ELEVATION
  TokenIsElevated.l
EndStructure

; ====== Logging ======

Procedure LogMessage(msg.s)
  Protected file = OpenFile(#PB_Any, #LOG_FILE_NAME, #PB_File_Append)
  If file
    WriteStringN(file, FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss]", Date()) + " - " + msg)
    CloseFile(file)
  EndIf
EndProcedure

; ====== SpecialFolders module ======

DeclareModule SpecialFolders
  Declare.s GetSpecialFolder(id.l)
EndDeclareModule

Module SpecialFolders

  Procedure.s GetSpecialFolder(id.l)
    Protected path.s, *ItemId.ITEMIDLIST

    *ItemId = #Null
    If SHGetSpecialFolderLocation_(0, id, @*ItemId) = #NOERROR
      path = Space(#MAX_PATH)
      If SHGetPathFromIDList_(*ItemId, @path)
        path = Trim(path)
        If path <> ""
          If Right(path, 1) <> "\"
            path + "\"
          EndIf
          ProcedureReturn path
        EndIf
      EndIf
    EndIf

    ProcedureReturn ""
  EndProcedure

EndModule

; ====== ShellLink module ======

DeclareModule ShellLink
  Declare.l CreateShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index.l)
EndDeclareModule

Module ShellLink

  Procedure.l CreateShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index.l)
    Protected hRes.l
    Protected ppf.IPersistFile

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
        ; Unicode build: lnk is already wide
        hRes = ppf\Save(lnk, #True)
        ppf\Release()
      EndIf
      psl\Release()
    EndIf

    CoUninitialize_()

    DataSection
      CLSID_ShellLink:
      Data.l $00021401
      Data.w $0000,$0000
      Data.b $C0,$00,$00,$00,$00,$00,$00,$46

      IID_IShellLink:
      CompilerIf #PB_Compiler_Unicode
        Data.l $000214F9
      CompilerElse
        Data.l $000214EE
      CompilerEndIf
      Data.w $0000,$0000
      Data.b $C0,$00,$00,$00,$00,$00,$00,$46

      IID_IPersistFile:
      Data.l $0000010B
      Data.w $0000,$0000
      Data.b $C0,$00,$00,$00,$00,$00,$00,$46
    EndDataSection

    ProcedureReturn hRes
  EndProcedure

EndModule

; ====== Elevation / Admin check ======
; Uses PB’s built-in imported APIs (no Import block)

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

; ====== Utility: Ensure directory exists ======

Procedure.b EnsureDirectory(path.s)
  Protected res.i = FileSize(path)
  If res = -1
    If CreateDirectory(path)
      LogMessage("Created directory: " + path)
      ProcedureReturn #True
    Else
      LogMessage("Failed to create directory: " + path)
      ProcedureReturn #False
    EndIf
  ElseIf res = -2
    ; path exists and is a directory
    ProcedureReturn #True
  Else
    ; exists as a file, which is bad
    LogMessage("Path exists as file, not directory: " + path)
    ProcedureReturn #False
  EndIf
EndProcedure

; Exit procedure
Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    LogMessage("Program exiting")
    End
  EndIf
EndProcedure

; ====== Main ======

Define.s lnkname, line
Define   format, req, res.l

LogMessage("=== HandyLNKMaker started ===")

If ReadFile(0, "handylnkmaker.ini")
  format = ReadStringFormat(0)
  While Eof(0) = 0
    line = ReadString(0, format)
    If Trim(line) <> ""
      lnkname = Trim(line)
    EndIf
  Wend
  CloseFile(0)
Else
  MessageRequester("Info", "Couldn't open handylnkmaker.ini", #PB_MessageRequester_Info)
  LogMessage("Failed to open handylnkmaker.ini")
  End
EndIf

If lnkname = ""
  MessageRequester("Error", "No program name found in handylnkmaker.ini.", #PB_MessageRequester_Error)
  LogMessage("Empty lnkname from ini.")
  End
EndIf

LogMessage("lnkname = " + lnkname)

; Resolve folders

Define.s ProgramFiles64, ProgramFilesX86, DesktopDir, StartupDir

ProgramFiles64 = SpecialFolders::GetSpecialFolder(#CSIDL_PROGRAM_FILES)
ProgramFilesX86 = SpecialFolders::GetSpecialFolder(#CSIDL_PROGRAM_FILESX86)
DesktopDir     = SpecialFolders::GetSpecialFolder(#CSIDL_DESKTOPDIRECTORY)
StartupDir     = SpecialFolders::GetSpecialFolder(#CSIDL_ALTSTARTUP) ; PB built-in

If ProgramFiles64 = "" Or ProgramFilesX86 = "" Or DesktopDir = "" Or StartupDir = ""
  MessageRequester("Error", "Failed to resolve one or more special folders.", #PB_MessageRequester_Error)
  LogMessage("Failed to resolve special folders.")
  End
EndIf

; Build app paths

Define.s Obj64, Dir64, Obj32, Dir32

Dir64 = ProgramFiles64 + lnkname
Obj64 = Dir64 + "\" + lnkname + ".exe"

Dir32 = ProgramFilesX86 + lnkname
Obj32 = Dir32 + "\" + lnkname + ".exe"

LogMessage("Dir64 = " + Dir64)
LogMessage("Obj64 = " + Obj64)
LogMessage("Dir32 = " + Dir32)
LogMessage("Obj32 = " + Obj32)

; Check elevation

If Not IsProcessElevated()
  MessageRequester("Admin rights needed", 
                   "Creating or modifying folders in Program Files requires administrator rights." + #CRLF$ +
                   "Run this tool as administrator and try again.",
                   #PB_MessageRequester_Ok | #PB_MessageRequester_Warning)
  LogMessage("Process not elevated. Abort.")
  End
EndIf

; ====== Create folders in Program Files and Program Files (x86) ======

req = MessageRequester("Create folders",
                       "Create application folders in:" + #CRLF$ +
                       "- Program Files (x64)" + #CRLF$ +
                       "- Program Files (x86)" + #CRLF$ +
                       "- Startup link (x64)" + #CRLF$ +
                       "- Startup link (x86)" + #CRLF$ +
                       "for '" + lnkname + "' ?",
                       #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)

If req = #PB_MessageRequester_No
  LogMessage("=== HandyLNKMaker finished ===")
  Exit()
EndIf

  If Not EnsureDirectory(Dir64)
    MessageRequester("Error", "Failed to create or use x64 Program Files folder." + #CRLF$ + Dir64, #PB_MessageRequester_Error)
  EndIf

  If Not EnsureDirectory(Dir32)
    MessageRequester("Error", "Failed to create or use x86 Program Files folder." + #CRLF$ + Dir32, #PB_MessageRequester_Error)
  EndIf

; ====== Startup link (x64) ======

req = MessageRequester("Startup link", 
                       "Create a new startup link (x64)?", 
                       #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)

If req = #PB_MessageRequester_Yes
  Define.s StartupLnk64 = StartupDir + lnkname + ".lnk"
  If FileSize(StartupLnk64) = -1
    res = ShellLink::CreateShellLink(Obj64, StartupLnk64, "", "Start " + lnkname + " (x64)", Dir64, Obj64, 0)
    If res = #S_OK
      MessageRequester("Info", "A Startup link (x64) was created.", #PB_MessageRequester_Info)
      LogMessage("Created startup link x64: " + StartupLnk64)
    Else
      MessageRequester("Error", "Failed to create Startup link (x64).", #PB_MessageRequester_Error)
      LogMessage("Failed to create startup link x64. HRESULT = " + Str(res))
    EndIf
  Else
    MessageRequester("Info", "Startup link (x64) already exists.", #PB_MessageRequester_Info)
  EndIf
EndIf

; ====== Desktop link (x64) ======

req = MessageRequester("Desktop link (x64)", 
                       "Create a new desktop link (x64)?", 
                       #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)

If req = #PB_MessageRequester_Yes
  Define.s DesktopLnk64 = DesktopDir + lnkname + ".lnk"
  If FileSize(DesktopLnk64) = -1
    res = ShellLink::CreateShellLink(Obj64, DesktopLnk64, "", "Start " + lnkname + " (x64)", Dir64, Obj64, 0)
    If res = #S_OK
      MessageRequester("Info", "A Desktop link (x64) was created.", #PB_MessageRequester_Info)
      LogMessage("Created desktop link x64: " + DesktopLnk64)
    Else
      MessageRequester("Error", "Failed to create Desktop link (x64).", #PB_MessageRequester_Error)
      LogMessage("Failed to create desktop link x64. HRESULT = " + Str(res))
    EndIf
  Else
    MessageRequester("Info", "Desktop link (x64) already exists.", #PB_MessageRequester_Info)
  EndIf
EndIf

; ====== Startup link (x86) ======

req = MessageRequester("Startup link (x86)", 
                       "Create a new startup link (x86)?", 
                       #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)

If req = #PB_MessageRequester_Yes
  Define.s StartupLnk32 = StartupDir + lnkname + "_x86.lnk"
  If FileSize(StartupLnk32) = -1
    res = ShellLink::CreateShellLink(Obj32, StartupLnk32, "", "Start " + lnkname + " (x86)", Dir32, Obj32, 0)
    If res = #S_OK
      MessageRequester("Info", "A Startup link (x86) was created.", #PB_MessageRequester_Info)
      LogMessage("Created startup link x86: " + StartupLnk32)
    Else
      MessageRequester("Error", "Failed to create Startup link (x86).", #PB_MessageRequester_Error)
      LogMessage("Failed to create startup link x86. HRESULT = " + Str(res))
    EndIf
  Else
    MessageRequester("Info", "Startup link (x86) already exists.", #PB_MessageRequester_Info)
  EndIf
EndIf

; ====== Desktop link (x86) ======

req = MessageRequester("Desktop link (x86)", 
                       "Create a new desktop link (x86)?", 
                       #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)

If req = #PB_MessageRequester_Yes
  Define.s DesktopLnk32 = DesktopDir + lnkname + "_x86.lnk"
  If FileSize(DesktopLnk32) = -1
    res = ShellLink::CreateShellLink(Obj32, DesktopLnk32, "", "Start " + lnkname + " (x86)", Dir32, Obj32, 0)
    If res = #S_OK
      MessageRequester("Info", "A Desktop link (x86) was created.", #PB_MessageRequester_Info)
      LogMessage("Created desktop link x86: " + DesktopLnk32)
    Else
      MessageRequester("Error", "Failed to create Desktop link (x86).", #PB_MessageRequester_Error)
      LogMessage("Failed to create desktop link x86. HRESULT = " + Str(res))
    EndIf
  Else
    MessageRequester("Info", "Desktop link (x86) already exists.", #PB_MessageRequester_Info)
  EndIf
EndIf

LogMessage("=== HandyLNKMaker finished ===")
Exit()
; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; CursorPosition = 360
; FirstLine = 334
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; DllProtection
; UseIcon = HandyLNKMaker.ico
; Executable = ..\HandyLNKMaker.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = HandyLNKMaker
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = Creates x86/x64 startup and program links
; VersionField7 = HandyLNKMaker
; VersionField8 = HandyLNKMaker.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster@yahoo.com
; VersionField14 = https://github.com/zonemaster60