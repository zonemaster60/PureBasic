;PB6.11
;20061127, now works with unicode executables
; HandyLNKMaker

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

Global obj.s, obj2.s, lnk.s, lnk2.s, lnkname.s

If ReadFile(0, "handylnkmaker.ini")        ; if the file could be read, we continue ...
    Format = ReadStringFormat(0)
    While Eof(0) = 0                ; loop as long the 'end of file' isn't reached
      lnkname = ReadString(0, Format)   ; display line by line in the debug window
    Wend
    CloseFile(0)                    ; close the previously opened file
  Else
    MessageRequester("Info", "Couldn't open the file!", #PB_MessageRequester_Info)
EndIf

obj = getSpecialFolder(#CSIDL_PROGRAM_FILES) + lnkname + "\" + lnkname + ".exe"
obj2 = getSpecialFolder(#CSIDL_PROGRAM_FILES) + lnkname
lnk = getSpecialFolder(#CSIDL_ALTSTARTUP)
lnk2 = getSpecialFolder(#CSIDL_DESKTOPDIRECTORY)

Req=MessageRequester("Info", "Create a new startup link?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
If Req = #PB_MessageRequester_Yes 
  ; check for existence of startup link
  If FileSize(lnk + lnkname + ".lnk") = -1
    If createShellLink(obj, lnk + lnkname + ".lnk", "", "Start " + lnkname, obj2, obj, 0) = 0
      MessageRequester("Info", "A Startup link was created.", #PB_MessageRequester_Info)
    EndIf
  EndIf
EndIf

Req=MessageRequester("Info", "Create a new desktop link?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
If Req = #PB_MessageRequester_Yes
  ; check for existence of desktop link
  If FileSize(lnk2 + lnkname + ".lnk") = -1
    If createShellLink(obj, lnk2 + lnkname + ".lnk", "", "Start " + lnkname, obj2, obj, 0) = 0
      MessageRequester("Info", "A Desktop link was created.", #PB_MessageRequester_Info)
    EndIf
  EndIf
EndIf

End

; IDE Options = PureBasic 6.12 LTS (Windows - x64)
; CursorPosition = 92
; FirstLine = 74
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = HandyLNKMaker.ico
; Executable = ..\HandyLNKMaker.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 0,0,0,1
; VersionField2 = ZoneSoft
; VersionField3 = CreateLinks
; VersionField4 = 0.0.0.1
; VersionField5 = 1.0.0.0
; VersionField6 = Creates a desktop and startup link
; VersionField9 = David Scouten
; VersionField13 = zonemaster@yahoo.com