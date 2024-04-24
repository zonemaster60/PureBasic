;PB4.00
;20061127, now works with unicode executables

Declare createShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index)
Declare.s getSpecialFolder(id)

Procedure.s getSpecialFolder(id)
  Protected path.s, *ItemId.ITEMIDLIST
 
  *itemId = #Null
  If SHGetSpecialFolderLocation_(0, id, @*ItemId) = #NOERROR
    path = Space(#MAX_PATH)
    If SHGetPathFromIDList_(*itemId, @path)
      If Right(path, 1) <> "\"
        path + "\"
      EndIf
      ProcedureReturn path
    EndIf
  EndIf
  ProcedureReturn ""
EndProcedure

Procedure createShellLink(obj.s, lnk.s, arg.s, desc.s, dir.s, icon.s, index)
  ;obj - path to the exe that is linked to, lnk - link name, dir - working
  ;directory, icon - path to the icon file, index - icon index in iconfile
  Protected hRes.l, mem.s, ppf.IPersistFile
  CompilerIf #PB_Compiler_Unicode
    Protected psl.IShellLinkW
  CompilerElse
    Protected psl.IShellLinkA
  CompilerEndIf

  ;make shure COM is active
  CoInitialize_(0)
  hRes = CoCreateInstance_(?CLSID_ShellLink, 0, 1, ?IID_IShellLink, @psl)

  If hRes = 0
    psl\SetPath(Obj)
    psl\SetArguments(arg)
    psl\SetDescription(desc)
    psl\SetWorkingDirectory(dir)
    psl\SetIconLocation(icon, index)
    ;query IShellLink for the IPersistFile interface for saving the
    ;link in persistent storage
    hRes = psl\QueryInterface(?IID_IPersistFile, @ppf)

    If hRes = 0
      ;CompilerIf #PB_Compiler_Unicode
        ;save the link
        hRes = ppf\Save(lnk, #True)
;       CompilerElse
;         ;ensure that the string is ansi unicode
;         mem = Space(#MAX_PATH)
;         MultiByteToWideChar_(#CP_ACP, 0, lnk, -1, mem, #MAX_PATH)
;         ;save the link
;         hRes = ppf\Save(mem, #True)
;       CompilerEndIf
      ppf\Release()
    EndIf
    psl\Release()
  EndIf

  ;shut down COM
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
    Data.l $0000010b
    Data.w $0000,$0000
    Data.b $C0,$00,$00,$00,$00,$00,$00,$46
  EndDataSection
  ProcedureReturn hRes
EndProcedure

#CSIDL_WINDOWS = $24
#CSIDL_DESKTOPDIRECTORY = $10

Global obj.s, obj2.s, lnk.s, lnk2.s

obj = getSpecialFolder(#CSIDL_PROGRAM_FILES) + "HandyTXTPad\HandyTXTPad.exe"
obj2 = getSpecialFolder(#CSIDL_PROGRAM_FILES) + "HandyTXTPad"
lnk = getSpecialFolder(#CSIDL_ALTSTARTUP)
lnk2 = getSpecialFolder(#CSIDL_DESKTOPDIRECTORY)

; check for existence of desktop link
If FileSize(lnk2 + "HandyTXTPad.lnk") = -1
  If createShellLink(obj, lnk2 + "HandyTXTPad.lnk", "", "Start HandyTXTPad", obj2, obj, 0) = 0
    MessageRequester("Info", "A Desktop link was created.", #PB_MessageRequester_Info)
  EndIf
EndIf

Global gsFilename.s
XIncludeFile("HandyTXTPad.pbf")
XIncludeFile("HandyTXTPad.pbi")

If FindWindow_(0,"HandyTXTPad")
  MessageRequester("Info", "HandyTXTPad is already running.", #PB_MessageRequester_Info)
  End
EndIf 

OpenDlg1()

Define event.i

Repeat         ;main message loop
event = WaitWindowEvent()
  Dlg1_Events (event)
Until event = #PB_Event_CloseWindow
Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
; IDE Options = PureBasic 6.11 LTS Beta 1 (Windows - x64)
; CursorPosition = 98
; FirstLine = 99
; Folding = -
; Optimizer
; EnableXP
; EnableUser
; DPIAware
; UseIcon = HandyTXTPad.ico
; Executable = HandyTXTPad.exe
; IncludeVersionInfo
; VersionField0 = 0,0,0,1
; VersionField1 = 0,0,0,5
; VersionField2 = ZoneSoft
; VersionField3 = HandyTXTPad.exe
; VersionField4 = v0.0.0.5
; VersionField5 = v0.0.0.1
; VersionField6 = A Handy Little Text Pad Program
; VersionField7 = HandyTXTPad.exe
; VersionField8 = HandyTXTPad.exe
; VersionField9 = David Scouten
; VersionField10 = David Scouten
; VersionField13 = zonemaster@yahoo.com