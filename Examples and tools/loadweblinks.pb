EnableExplicit

Structure LinkData
  gadget.i
  url.s
EndStructure

Global NewList links.LinkData()
Global linkHeight = 25
Global padding = 10
Global VisitedColor = RGB(255, 0, 255) ; Magenta for visited links

Procedure Exit()
  Define Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
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
    WriteStringN(2, FormatDate("[%yyyy-%mm-%dd %hh:%ii:%ss] ", Date()) + msg)
    CloseFile(2)
  EndIf
EndProcedure

Procedure LoadWebsites(FileName.s)
  Protected linkCount = CountLines(FileName)
  If linkCount = 0
    MessageRequester("Info", "No valid links were found.", #PB_MessageRequester_Info)
    End
  EndIf

  Protected winWidth = 420
  Protected linkSpacing = linkHeight + 5
  Protected contentHeight = linkSpacing * linkCount + padding * 2
  Protected viewHeight = 400
  
  If contentHeight < viewHeight
    viewHeight = contentHeight + 20
  EndIf

  OpenWindow(0, 200, 200, winWidth, viewHeight, "Useful Website Links", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
  ScrollAreaGadget(0, 0, 0, winWidth, viewHeight, winWidth - 40, contentHeight + 10, 10)

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

        gID = HyperLinkGadget(#PB_Any, 10, y, winWidth - 60, linkHeight, url, RGB(0, 255, 0), #PB_HyperLink_Underline)
        GadgetToolTip(gID, tip)

        AddElement(links())
        links()\gadget = gID
        links()\url = url

        y + linkSpacing
      EndIf
    Wend
    CloseFile(0)
  Else
    MessageRequester("Error", "Could not open the file: " + FileName, #PB_MessageRequester_Error)
    End
  EndIf

  CloseGadgetList()
EndProcedure

Procedure HandleEvents()
  Protected event
  Repeat
    event = WaitWindowEvent()
    If event = #PB_Event_Gadget
      ForEach links()
        If EventGadget() = links()\gadget
          SetGadgetColor(links()\gadget, #PB_Gadget_FrontColor, VisitedColor)
          If RunProgram(links()\url) = 0
            LogError("Failed to open URL: " + links()\url)
            MessageRequester("Error", "Could not open: " + links()\url, #PB_MessageRequester_Error)
          EndIf
        EndIf
      Next
    EndIf
  Until event = #PB_Event_CloseWindow
  Exit()
EndProcedure

LoadWebsites("weblinks.txt")
HandleEvents()

; IDE Options = PureBasic 6.21 (Windows - x64)
; CursorPosition = 108
; FirstLine = 80
; Folding = -
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; DllProtection
; UseIcon = loadweblinks.ico
; Executable = loadweblinks.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = loadweblinks.exe
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = Loads a list of websites
; VersionField9 = David Scouten
; VersionField13 = zonemaster@yahoo.com
; VersionField14 = https://github.com/zonemaster60/PureBasic