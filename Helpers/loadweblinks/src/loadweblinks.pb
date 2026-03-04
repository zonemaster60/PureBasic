EnableExplicit

#APP_NAME   = "LoadWebLinks"
#EMAIL_NAME = "zonemaster60@gmail.com"
#LINKS_TXT = "weblinks.txt"

Global version.s = "v1.0.0.2"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Improved Mutex handling
Global hMutex.i = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex = 0 Or GetLastError_() = #ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  If hMutex : CloseHandle_(hMutex) : EndIf
  End
EndIf

Structure LinkData
  gadget.i
  url.s
  visited.b
EndStructure

Global NewList links.LinkData()
Global NewMap linkMap.i() ; For fast lookup in event loop
Global linkHeight = 25
Global padding = 10
Global VisitedColor = RGB(255, 0, 255) ; Magenta for visited links

Procedure Exit()
  Protected Req.i
  Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    If hMutex : CloseHandle_(hMutex) : EndIf
    FreeList(links())
    FreeMap(linkMap())
    End
  EndIf
EndProcedure

Procedure About()
  MessageRequester("Info", #APP_NAME + " - " + version + #CRLF$ + 
                           "Thank you for using this free tool!" + #CRLF$ +
                           "Contact: " + #EMAIL_NAME + #CRLF$ +
                           "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
EndProcedure

Procedure.s EnsureProtocol(url.s)
  If Left(LCase(url), 7) <> "http://" And Left(LCase(url), 8) <> "https://"
    ProcedureReturn "https://" + url
  EndIf
  ProcedureReturn url
EndProcedure

Procedure.i CountLines(FileName.s)
  Protected count = 0
  If ReadFile(1, FileName)
    While Not Eof(1)
      If Trim(ReadString(1)) <> ""
        count + 1
      EndIf
    Wend
    CloseFile(1)
  EndIf
  ProcedureReturn count
EndProcedure

Procedure LogError(msg.s)
  Protected logfile.s = "errorlog.txt"
  If OpenFile(2, logfile, #PB_File_Append)
    WriteStringN(2, FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + msg)
    CloseFile(2)
  EndIf
EndProcedure

Procedure ClearWebsites()
  ClearList(links())
  ClearMap(linkMap())
  If IsGadget(0)
    FreeGadget(0)
  EndIf
EndProcedure

Procedure LoadWebsites(FileName.s)
  Protected linkCount = CountLines(FileName)
  If linkCount = 0
    MessageRequester("Info", "No valid links were found in " + #LINKS_TXT, #PB_MessageRequester_Info)
    ProcedureReturn
  EndIf

  Protected winWidth = WindowWidth(0)
  Protected winHeight = WindowHeight(0)
  Protected linkSpacing = linkHeight + 5
  Protected contentHeight = linkSpacing * linkCount + padding * 2
  
  ScrollAreaGadget(0, 0, 0, winWidth, winHeight, winWidth - 30, contentHeight + 10, 10)

  Protected y = padding, gID
  If ReadFile(0, FileName)
    While Not Eof(0)
      Protected line.s = Trim(ReadString(0))
      If line <> ""
        Protected url.s, tip.s
        If FindString(line, "|")
          url = Trim(StringField(line, 1, "|"))
          tip = Trim(StringField(line, 2, "|"))
        Else
          url = line
          tip = "Visit: " + url
        EndIf
        
        url = EnsureProtocol(url)

        gID = HyperLinkGadget(#PB_Any, 10, y, winWidth - 60, linkHeight, url, RGB(0, 0, 255), #PB_HyperLink_Underline)
        GadgetToolTip(gID, tip)

        AddElement(links())
        links()\gadget = gID
        links()\url = url
        linkMap(Str(gID)) = @links() ; Store pointer for fast access

        y + linkSpacing
      EndIf
    Wend
    CloseFile(0)
  Else
    MessageRequester("Error", "Could not open the file: " + FileName, #PB_MessageRequester_Error)
  EndIf

  CloseGadgetList()
EndProcedure

Procedure HandleEvents()
  Protected event, gID
  Repeat
    event = WaitWindowEvent()
    
    Select event
      Case #PB_Event_Menu
        Select EventMenu()
          Case 1 : About()
          Case 2 : RunProgram(AppPath + #LINKS_TXT)
          Case 3 : 
            ClearWebsites()
            LoadWebsites(AppPath + #LINKS_TXT)
          Case 4 : Exit()
        EndSelect
        
      Case #PB_Event_Gadget
        gID = EventGadget()
        If FindMapElement(linkMap(), Str(gID))
          ChangeCurrentElement(links(), linkMap())
          SetGadgetColor(gID, #PB_Gadget_FrontColor, VisitedColor)
          If RunProgram(links()\url) = 0
            LogError("Failed to open URL: " + links()\url)
            MessageRequester("Error", "Could not open: " + links()\url, #PB_MessageRequester_Error)
          EndIf
        EndIf
        
      Case #PB_Event_SizeWindow
        If IsGadget(0)
          ResizeGadget(0, #PB_Ignore, #PB_Ignore, WindowWidth(0), WindowHeight(0))
        EndIf

      Case #PB_Event_CloseWindow
        Exit()
    EndSelect
  Until #False
EndProcedure

; Initial Window Setup
If OpenWindow(0, 0, 0, 450, 500, #APP_NAME + " - " + version , #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
  If CreateMenu(0, WindowID(0))
    MenuTitle("File")
    MenuItem(1, "About")
    MenuItem(2, "Edit Links File")
    MenuItem(3, "Reload Links")
    MenuBar()
    MenuItem(4, "Exit")
  EndIf
  LoadWebsites(AppPath + #LINKS_TXT)
  HandleEvents()
EndIf


; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 6
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = loadweblinks.ico
; Executable = ..\loadweblinks.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,2
; VersionField1 = 1,0,0,2
; VersionField2 = ZoneSoft
; VersionField3 = loadweblinks
; VersionField4 = 1.0.0.2
; VersionField5 = 1.0.0.2
; VersionField6 = Loads a list of websites
; VersionField7 = loadweblinks
; VersionField8 = loadweblinks.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60