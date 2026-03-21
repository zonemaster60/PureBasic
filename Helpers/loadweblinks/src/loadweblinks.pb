EnableExplicit

#APP_NAME   = "LoadWebLinks"
#EMAIL_NAME = "zonemaster60@gmail.com"
#LINKS_TXT  = "weblinks.txt"

Enumeration
  #Window_Main
EndEnumeration

Enumeration 1
  #Menu_About
  #Menu_EditLinks
  #Menu_ReloadLinks
  #Menu_Exit
EndEnumeration

Enumeration
  #Gadget_ScrollArea
EndEnumeration

Structure LinkData
  gadget.i
  url.s
  tooltip.s
  visited.b
EndStructure

Global version.s = "v1.0.0.3"
Global AppPath.s = GetPathPart(ProgramFilename())
Global hMutex.i
Global quitRequested.i
Global NewList links.LinkData()
Global NewMap linkMap.i()
Global linkHeight.i = 25
Global padding.i = 10
Global VisitedColor.i = RGB(255, 0, 255)
Global DefaultLinkColor.i = RGB(0, 0, 255)

Structure LayoutMetrics
  windowWidth.i
  windowHeight.i
  innerWidth.i
  contentHeight.i
  gadgetWidth.i
  linkSpacing.i
EndStructure

Procedure.s LinksFilePath()
  ProcedureReturn AppPath + #LINKS_TXT
EndProcedure

Procedure.s LogFilePath()
  ProcedureReturn AppPath + "errorlog.txt"
EndProcedure

Procedure LogError(msg.s)
  Protected logFile.i = OpenFile(#PB_Any, LogFilePath(), #PB_File_Append)

  If logFile
    WriteStringN(logFile, FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()) + msg)
    CloseFile(logFile)
  EndIf
EndProcedure

Procedure.b InitializeSingleInstance()
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")

  If hMutex = 0
    MessageRequester("Error", "Unable to create the application mutex.", #PB_MessageRequester_Error)
    LogError("CreateMutex failed with error code " + Str(GetLastError_()))
    ProcedureReturn #False
  EndIf

  If GetLastError_() = #ERROR_ALREADY_EXISTS
    MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
    CloseHandle_(hMutex)
    hMutex = 0
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure Cleanup()
  If IsGadget(#Gadget_ScrollArea)
    FreeGadget(#Gadget_ScrollArea)
  EndIf

  ClearList(links())
  ClearMap(linkMap())

  If hMutex
    CloseHandle_(hMutex)
    hMutex = 0
  EndIf
EndProcedure

Procedure About()
  MessageRequester("Info", #APP_NAME + " - " + version + #CRLF$ +
                           "Thank you for using this free tool!" + #CRLF$ +
                           "Contact: " + #EMAIL_NAME + #CRLF$ +
                           "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
EndProcedure

Procedure.s EnsureProtocol(url.s)
  Protected lowerUrl.s = LCase(url)

  If Left(lowerUrl, 7) <> "http://" And Left(lowerUrl, 8) <> "https://"
    ProcedureReturn "https://" + url
  EndIf

  ProcedureReturn url
EndProcedure

Procedure.b IsValidWebLink(url.s)
  Protected lowerUrl.s = LCase(url)
  Protected hostPart.s
  Protected separatorPos.i
  Protected splitPos.i

  If Left(lowerUrl, 7) <> "http://" And Left(lowerUrl, 8) <> "https://"
    ProcedureReturn #False
  EndIf

  separatorPos = FindString(url, "://")
  If separatorPos = 0
    ProcedureReturn #False
  EndIf

  hostPart = Mid(url, separatorPos + 3)
  hostPart = Trim(hostPart)

  splitPos = FindString(hostPart, "/")
  If splitPos > 0
    hostPart = Left(hostPart, splitPos - 1)
  EndIf

  splitPos = FindString(hostPart, "?")
  If splitPos > 0
    hostPart = Left(hostPart, splitPos - 1)
  EndIf

  splitPos = FindString(hostPart, "#")
  If splitPos > 0
    hostPart = Left(hostPart, splitPos - 1)
  EndIf

  hostPart = Trim(hostPart)

  If hostPart = ""
    ProcedureReturn #False
  EndIf

  If Left(hostPart, 1) = "." Or Left(hostPart, 1) = "-"
    ProcedureReturn #False
  EndIf

  If FindString(hostPart, " ")
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure ClearWebsites()
  ClearMap(linkMap())

  If IsGadget(#Gadget_ScrollArea)
    FreeGadget(#Gadget_ScrollArea)
  EndIf

  ClearList(links())
EndProcedure

Procedure.b IsCommentLine(line.s)
  If Left(line, 1) = ";" Or Left(line, 1) = "#"
    ProcedureReturn #True
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure CalculateLayoutMetrics(*metrics.LayoutMetrics)
  *metrics\windowWidth = WindowWidth(#Window_Main)
  *metrics\windowHeight = WindowHeight(#Window_Main)
  *metrics\linkSpacing = linkHeight + 5
  *metrics\innerWidth = *metrics\windowWidth - 30

  If *metrics\innerWidth < 120
    *metrics\innerWidth = 120
  EndIf

  *metrics\contentHeight = (*metrics\linkSpacing * ListSize(links())) + (padding * 2)
  If *metrics\contentHeight < *metrics\windowHeight
    *metrics\contentHeight = *metrics\windowHeight
  EndIf

  *metrics\gadgetWidth = *metrics\innerWidth - (padding * 2)
  If *metrics\gadgetWidth < 80
    *metrics\gadgetWidth = 80
  EndIf
EndProcedure

Procedure RefreshWebsiteLayout()
  Protected metrics.LayoutMetrics
  Protected y.i

  If IsGadget(#Gadget_ScrollArea) = 0
    ProcedureReturn
  EndIf

  CalculateLayoutMetrics(@metrics)

  ResizeGadget(#Gadget_ScrollArea, 0, 0, metrics\windowWidth, metrics\windowHeight)
  SetGadgetAttribute(#Gadget_ScrollArea, #PB_ScrollArea_InnerWidth, metrics\innerWidth)
  SetGadgetAttribute(#Gadget_ScrollArea, #PB_ScrollArea_InnerHeight, metrics\contentHeight)

  y = padding
  ForEach links()
    If IsGadget(links()\gadget)
      ResizeGadget(links()\gadget, padding, y, metrics\gadgetWidth, linkHeight)
    EndIf
    y + metrics\linkSpacing
  Next
EndProcedure

Procedure BuildWebsiteGadgets()
  Protected metrics.LayoutMetrics
  Protected y.i

  If ListSize(links()) = 0
    ProcedureReturn
  EndIf

  CalculateLayoutMetrics(@metrics)

  ScrollAreaGadget(#Gadget_ScrollArea, 0, 0, metrics\windowWidth, metrics\windowHeight, metrics\innerWidth, metrics\contentHeight, 10)

  y = padding
  ForEach links()
    links()\gadget = HyperLinkGadget(#PB_Any, padding, y, metrics\gadgetWidth, linkHeight, links()\url, DefaultLinkColor, #PB_HyperLink_Underline)
    GadgetToolTip(links()\gadget, links()\tooltip)

    If links()\visited
      SetGadgetColor(links()\gadget, #PB_Gadget_FrontColor, VisitedColor)
    EndIf

    linkMap(Str(links()\gadget)) = @links()
    y + metrics\linkSpacing
  Next

  CloseGadgetList()
EndProcedure

Procedure.i LoadWebsites(fileName.s)
  Protected file.i
  Protected line.s
  Protected url.s
  Protected tip.s
  Protected delimiterPos.i
  Protected validLinkCount.i
  Protected skippedLinkCount.i

  ClearWebsites()

  file = ReadFile(#PB_Any, fileName)
  If file = 0
    MessageRequester("Error", "Could not open the file: " + fileName, #PB_MessageRequester_Error)
    LogError("Could not open links file: " + fileName)
    ProcedureReturn #False
  EndIf

  While Eof(file) = 0
    line = Trim(ReadString(file))

    If line = ""
      Continue
    EndIf

    If IsCommentLine(line)
      Continue
    EndIf

    delimiterPos = FindString(line, "|")
    If delimiterPos > 0
      url = Trim(Left(line, delimiterPos - 1))
      tip = Trim(Mid(line, delimiterPos + 1))
    Else
      url = line
      tip = ""
    EndIf

    If url = ""
      skippedLinkCount + 1
      LogError("Skipped invalid entry with blank URL: " + line)
      Continue
    EndIf

    url = EnsureProtocol(url)
    If IsValidWebLink(url) = 0
      skippedLinkCount + 1
      LogError("Skipped invalid URL: " + url)
      Continue
    EndIf

    If tip = ""
      tip = "Visit: " + url
    EndIf

    AddElement(links())
    links()\gadget = 0
    links()\url = url
    links()\tooltip = tip
    links()\visited = #False
    validLinkCount + 1
  Wend

  CloseFile(file)

  If validLinkCount = 0
    MessageRequester("Info", "No valid links were found in " + #LINKS_TXT, #PB_MessageRequester_Info)
    ProcedureReturn #False
  EndIf

  BuildWebsiteGadgets()

  If skippedLinkCount > 0
    If skippedLinkCount = 1
      MessageRequester("Info", "1 invalid link entry was skipped.", #PB_MessageRequester_Info)
    Else
      MessageRequester("Info", Str(skippedLinkCount) + " invalid link entries were skipped.", #PB_MessageRequester_Info)
    EndIf
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure EditLinksFile()
  Protected fileName.s = LinksFilePath()
  Protected file.i
  Protected parameters.s

  If FileSize(fileName) = -1
    file = CreateFile(#PB_Any, fileName)
    If file
      CloseFile(file)
    Else
      MessageRequester("Error", "Could not create the links file: " + fileName, #PB_MessageRequester_Error)
      LogError("Could not create links file: " + fileName)
      ProcedureReturn
    EndIf
  EndIf

  parameters = Chr(34) + fileName + Chr(34)
  If RunProgram("notepad.exe", parameters, AppPath) = 0
    MessageRequester("Error", "Could not launch Notepad for: " + fileName, #PB_MessageRequester_Error)
    LogError("Could not launch Notepad for: " + fileName)
  EndIf
EndProcedure

Procedure.b ConfirmExit()
  Protected result.i

  result = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  ProcedureReturn Bool(result = #PB_MessageRequester_Yes)
EndProcedure

Procedure HandleEvents()
  Protected event.i
  Protected gadgetID.i

  quitRequested = #False

  Repeat
    event = WaitWindowEvent()

    Select event
      Case #PB_Event_Menu
        Select EventMenu()
          Case #Menu_About
            About()

          Case #Menu_EditLinks
            EditLinksFile()

          Case #Menu_ReloadLinks
            LoadWebsites(LinksFilePath())

          Case #Menu_Exit
            If ConfirmExit()
              quitRequested = #True
            EndIf
        EndSelect

      Case #PB_Event_Gadget
        gadgetID = EventGadget()

        If FindMapElement(linkMap(), Str(gadgetID))
          ChangeCurrentElement(links(), linkMap())

          If RunProgram(links()\url) = 0
            LogError("Failed to open URL: " + links()\url)
            MessageRequester("Error", "Could not open: " + links()\url, #PB_MessageRequester_Error)
          Else
            links()\visited = #True
            SetGadgetColor(gadgetID, #PB_Gadget_FrontColor, VisitedColor)
          EndIf
        EndIf

      Case #PB_Event_SizeWindow
        RefreshWebsiteLayout()

      Case #PB_Event_CloseWindow
        If ConfirmExit()
          quitRequested = #True
        EndIf
    EndSelect
  Until quitRequested
EndProcedure

If InitializeSingleInstance()
  If OpenWindow(#Window_Main, 0, 0, 450, 500, #APP_NAME + " - " + version, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
    If CreateMenu(0, WindowID(#Window_Main))
      MenuTitle("File")
      MenuItem(#Menu_About, "About")
      MenuItem(#Menu_EditLinks, "Edit Links File")
      MenuItem(#Menu_ReloadLinks, "Reload Links")
      MenuBar()
      MenuItem(#Menu_Exit, "Exit")
    EndIf

    LoadWebsites(LinksFilePath())
    HandleEvents()
  EndIf

  Cleanup()
EndIf

; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 28
; Folding = ---
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = loadweblinks.ico
; Executable = ..\loadweblinks.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,3
; VersionField1 = 1,0,0,3
; VersionField2 = ZoneSoft
; VersionField3 = loadweblinks
; VersionField4 = 1.0.0.3
; VersionField5 = 1.0.0.3
; VersionField6 = Loads a list of websites that you edit/enter
; VersionField7 = loadweblinks
; VersionField8 = loadweblinks.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60