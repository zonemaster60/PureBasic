EnableExplicit

#APP_NAME   = "LoadWebLinks"
#EMAIL_NAME = "zonemaster60@gmail.com"
#LINKS_TXT  = "weblinks.txt"
#LOG_FOLDER = "logs"
#LOG_TXT    = "errorlog.txt"
#MIN_INNER_WIDTH  = 120
#MIN_GADGET_WIDTH = 80

Enumeration
  #Window_Main
  #Window_Help
EndEnumeration

Enumeration 1
  #Menu_About
  #Menu_Help
  #Menu_EditLinks
  #Menu_ChooseLinks
  #Menu_ReloadLinks
  #Menu_Exit
EndEnumeration

Enumeration
  #Gadget_ScrollArea
  #Gadget_HelpEditor
EndEnumeration

Structure LinkData
  gadget.i
  url.s
  tooltip.s
  visited.b
EndStructure

Global Version.s = "v1.0.0.4"
Global AppPath.s = GetPathPart(ProgramFilename())
Global CurrentLinksFile.s = AppPath + #LINKS_TXT
Global hMutex.i
Global quitRequested.b
Global NewList links.LinkData()
Global NewMap linkMap.i()
Global LinkHeight.i = 25
Global Padding.i = 10
Global LinkColorVisited.i = RGB(255, 0, 255)
Global LinkColorDefault.i = RGB(0, 0, 255)

Structure LayoutMetrics
  windowWidth.i
  windowHeight.i
  innerWidth.i
  contentHeight.i
  gadgetWidth.i
  linkSpacing.i
EndStructure

Procedure.s LinksFilePath()
  ProcedureReturn CurrentLinksFile
EndProcedure

Procedure.s LogFilePath()
  Protected logPath.s = AppPath + #LOG_FOLDER

  If FileSize(logPath) <> -2
    If CreateDirectory(logPath) = 0
      ProcedureReturn AppPath + #LOG_TXT
    EndIf
  EndIf

  ProcedureReturn logPath + #PS$ + #LOG_TXT
EndProcedure

Procedure LogMessage(level.s, msg.s)
  Protected logPath.s = LogFilePath()
  Protected logFile.i = OpenFile(#PB_Any, logPath, #PB_File_Append)
  Protected timestamp.s = FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date())

  If logFile
    WriteStringN(logFile, timestamp + "[" + level + "] " + msg)
    CloseFile(logFile)
  ElseIf logPath <> AppPath + #LOG_TXT
    logFile = OpenFile(#PB_Any, AppPath + #LOG_TXT, #PB_File_Append)
    If logFile
      WriteStringN(logFile, timestamp + "[ERROR] Could not write to log file: " + logPath)
      WriteStringN(logFile, timestamp + "[" + level + "] " + msg)
      CloseFile(logFile)
    EndIf
  EndIf
EndProcedure

Procedure LogError(msg.s)
  LogMessage("ERROR", msg)
EndProcedure

Procedure LogInfo(msg.s)
  LogMessage("INFO", msg)
EndProcedure

Procedure.b CreateDefaultLinksFile(fileName.s)
  Protected file.i = CreateFile(#PB_Any, fileName)

  If file = 0
    LogError("Could not create default links file: " + fileName)
    ProcedureReturn #False
  EndIf

  WriteStringN(file, "https://github.com/zonemaster60", #PB_UTF8)
  CloseFile(file)
  LogInfo("Created default links file: " + fileName)
  ProcedureReturn #True
EndProcedure

Procedure.s HelpText()
  Protected text.s

  text + "LoadWebLinks Help" + #CRLF$
  text + "=============" + #CRLF$ + #CRLF$
  text + "LoadWebLinks displays a list of website links from a text file. Click a link to open it in your default web browser." + #CRLF$ + #CRLF$
  text + "Links File Format" + #CRLF$
  text + "------------------" + #CRLF$
  text + "Each non-empty line in the links file is treated as one link." + #CRLF$ + #CRLF$
  text + "Basic link:" + #CRLF$
  text + "https://www.google.com" + #CRLF$ + #CRLF$
  text + "Link with tooltip text:" + #CRLF$
  text + "https://www.google.com | Search with Google" + #CRLF$ + #CRLF$
  text + "If a link does not start with http:// or https://, LoadWebLinks adds https:// automatically." + #CRLF$
  text + "Blank lines are ignored." + #CRLF$
  text + "Comment lines are ignored when they begin with either ; or #." + #CRLF$ + #CRLF$
  text + "Menu Options" + #CRLF$
  text + "---------------" + #CRLF$
  text + "File > Edit Links File: Opens the current links file in Notepad." + #CRLF$
  text + "File > Choose Links File...: Lets you choose a different text file." + #CRLF$
  text + "File > Reload Links: Reloads the current links file." + #CRLF$
  text + "File > Exit: Closes the application after confirmation." + #CRLF$
  text + "Help > Help: Opens this help window." + #CRLF$
  text + "Help > About: Shows version and contact information." + #CRLF$ + #CRLF$
  text + "Default Files" + #CRLF$
  text + "-------------" + #CRLF$
  text + "If weblinks.txt is missing at startup, LoadWebLinks creates it with https://github.com/zonemaster60" + #CRLF$ + #CRLF$
  text + "Logging" + #CRLF$
  text + "---------" + #CRLF$
  text + "Errors and application events are written to logs\\errorlog.txt." + #CRLF$
  text + "If the logs folder cannot be used, LoadWebLinks falls back to errorlog.txt beside the executable." + #CRLF$ + #CRLF$
  text + "Troubleshooting" + #CRLF$
  text + "-----------------" + #CRLF$
  text + "If links do not appear, check that the links file contains valid non-comment lines." + #CRLF$
  text + "If a link does not open, verify that Windows has a default browser configured." + #CRLF$
  text + "If a selected links file cannot be loaded, check logs\\errorlog.txt for details." + #CRLF$

  ProcedureReturn text
EndProcedure

Procedure.b InitializeSingleInstance()
  hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")

  If hMutex = 0
    MessageRequester("Error", "Unable to create the application mutex.", #PB_MessageRequester_Error)
    LogError("CreateMutex failed with error code " + Str(GetLastError_()))
    ProcedureReturn #False
  EndIf

  If GetLastError_() = #ERROR_ALREADY_EXISTS
    LogInfo("Application startup blocked because another instance is already running.")
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
  MessageRequester("About", #APP_NAME + " - " + Version + #CRLF$ +
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
  *metrics\linkSpacing = LinkHeight + 5
  *metrics\innerWidth = *metrics\windowWidth - 30

  If *metrics\innerWidth < #MIN_INNER_WIDTH
    *metrics\innerWidth = #MIN_INNER_WIDTH
  EndIf

  *metrics\contentHeight = (*metrics\linkSpacing * ListSize(links())) + (Padding * 2)
  If *metrics\contentHeight < *metrics\windowHeight
    *metrics\contentHeight = *metrics\windowHeight
  EndIf

  *metrics\gadgetWidth = *metrics\innerWidth - (Padding * 2)
  If *metrics\gadgetWidth < #MIN_GADGET_WIDTH
    *metrics\gadgetWidth = #MIN_GADGET_WIDTH
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

  y = Padding
  ForEach links()
    If IsGadget(links()\gadget)
      ResizeGadget(links()\gadget, Padding, y, metrics\gadgetWidth, LinkHeight)
    EndIf
    y + metrics\linkSpacing
  Next
EndProcedure

Procedure.b BuildWebsiteGadgets()
  Protected metrics.LayoutMetrics
  Protected y.i
  Protected createdGadgetCount.i

  If ListSize(links()) = 0
    ProcedureReturn #False
  EndIf

  CalculateLayoutMetrics(@metrics)

  If ScrollAreaGadget(#Gadget_ScrollArea, 0, 0, metrics\windowWidth, metrics\windowHeight, metrics\innerWidth, metrics\contentHeight, 10) = 0
    LogError("Could not create the scroll area gadget.")
    ProcedureReturn #False
  EndIf

  y = Padding
  ForEach links()
    links()\gadget = HyperLinkGadget(#PB_Any, Padding, y, metrics\gadgetWidth, LinkHeight, links()\url, LinkColorDefault, #PB_HyperLink_Underline)
    If links()\gadget = 0
      LogError("Could not create hyperlink gadget for URL: " + links()\url)
    Else
      GadgetToolTip(links()\gadget, links()\tooltip)

      If links()\visited
        SetGadgetColor(links()\gadget, #PB_Gadget_FrontColor, LinkColorVisited)
      EndIf

      linkMap(Str(links()\gadget)) = @links()
      createdGadgetCount + 1
    EndIf

    y + metrics\linkSpacing
  Next

  CloseGadgetList()
  ProcedureReturn Bool(createdGadgetCount > 0)
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

  If FileSize(fileName) = -1
    If CreateDefaultLinksFile(fileName) = 0
      MessageRequester("Error", "Could not create the default links file: " + fileName, #PB_MessageRequester_Error)
      ProcedureReturn #False
    EndIf
  ElseIf FileSize(fileName) = -2
    MessageRequester("Error", "The links file path is a folder: " + fileName, #PB_MessageRequester_Error)
    LogError("Links file path is a folder: " + fileName)
    ProcedureReturn #False
  EndIf

  file = ReadFile(#PB_Any, fileName)
  If file = 0
    MessageRequester("Error", "Could not open the file: " + fileName, #PB_MessageRequester_Error)
    LogError("Could not open links file: " + fileName)
    ProcedureReturn #False
  EndIf

  While Eof(file) = 0
    line = Trim(ReadString(file, #PB_UTF8))

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
      LogError("Skipped entry with blank URL: " + line)
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
    LogError("No valid links were found in: " + fileName)
    ProcedureReturn #False
  EndIf

  If BuildWebsiteGadgets() = 0
    MessageRequester("Error", "The links were loaded, but the link list could not be displayed.", #PB_MessageRequester_Error)
    ProcedureReturn #False
  EndIf

  If skippedLinkCount > 0
    LogError(Str(skippedLinkCount) + " invalid link entries were skipped while loading: " + fileName)

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

  Select FileSize(fileName)
    Case -2
      MessageRequester("Error", "The links file path is a folder: " + fileName, #PB_MessageRequester_Error)
      LogError("Links file path is a folder: " + fileName)
      ProcedureReturn

    Case -1
      file = CreateFile(#PB_Any, fileName)
      If file
        CloseFile(file)
      Else
        MessageRequester("Error", "Could not create the links file: " + fileName, #PB_MessageRequester_Error)
        LogError("Could not create links file: " + fileName)
        ProcedureReturn
      EndIf
  EndSelect

  parameters = Chr(34) + fileName + Chr(34)
  If RunProgram("notepad.exe", parameters, AppPath) = 0
    MessageRequester("Error", "Could not launch Notepad for: " + fileName, #PB_MessageRequester_Error)
    LogError("Could not launch Notepad for: " + fileName)
  EndIf
EndProcedure

Procedure ChooseLinksFile()
  Protected fileName.s

  fileName = OpenFileRequester("Choose Links File", LinksFilePath(), "Text files (*.txt)|*.txt|All files (*.*)|*.*", 0)
  If fileName = ""
    LogInfo("Choose links file cancelled by user.")
    ProcedureReturn
  EndIf

  If LoadWebsites(fileName)
    CurrentLinksFile = fileName
    SetWindowTitle(#Window_Main, #APP_NAME + " - " + Version + " - " + GetFilePart(fileName))
    LogInfo("Changed links file to: " + fileName)
  Else
    LogError("Could not load selected links file: " + fileName)
  EndIf
EndProcedure

Procedure OpenHelpFile()
  Protected helpText.s = HelpText()

  If IsWindow(#Window_Help)
    SetGadgetText(#Gadget_HelpEditor, helpText)
    SetActiveWindow(#Window_Help)
    LogInfo("Focused help window.")
    ProcedureReturn
  EndIf

  If OpenWindow(#Window_Help, 0, 0, 650, 520, #APP_NAME + " Help", #PB_Window_SystemMenu | #PB_Window_SizeGadget | #PB_Window_ScreenCentered, WindowID(#Window_Main))
    EditorGadget(#Gadget_HelpEditor, 10, 10, WindowWidth(#Window_Help) - 20, WindowHeight(#Window_Help) - 20, #PB_Editor_ReadOnly)
    SetGadgetText(#Gadget_HelpEditor, helpText)
    LogInfo("Opened help window.")
  Else
    MessageRequester("Error", "Could not open the help window.", #PB_MessageRequester_Error)
    LogError("Could not open help window.")
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

          Case #Menu_Help
            OpenHelpFile()

          Case #Menu_EditLinks
            EditLinksFile()

          Case #Menu_ChooseLinks
            ChooseLinksFile()

          Case #Menu_ReloadLinks
            If LoadWebsites(LinksFilePath()) = 0
              LogError("Reload failed for links file: " + LinksFilePath())
            EndIf

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
            SetGadgetColor(gadgetID, #PB_Gadget_FrontColor, LinkColorVisited)
          EndIf
        EndIf

      Case #PB_Event_SizeWindow
        Select EventWindow()
          Case #Window_Main
            RefreshWebsiteLayout()

          Case #Window_Help
            If IsGadget(#Gadget_HelpEditor)
              ResizeGadget(#Gadget_HelpEditor, 10, 10, WindowWidth(#Window_Help) - 20, WindowHeight(#Window_Help) - 20)
            EndIf
        EndSelect

      Case #PB_Event_CloseWindow
        Select EventWindow()
          Case #Window_Main
            If ConfirmExit()
              quitRequested = #True
            EndIf

          Case #Window_Help
            CloseWindow(#Window_Help)
        EndSelect
    EndSelect
  Until quitRequested
EndProcedure

If InitializeSingleInstance()
  If OpenWindow(#Window_Main, 0, 0, 450, 500, #APP_NAME + " - " + Version, #PB_Window_SystemMenu | #PB_Window_MinimizeGadget | #PB_Window_SizeGadget | #PB_Window_ScreenCentered)
    If CreateMenu(0, WindowID(#Window_Main))
      MenuTitle("File")
      MenuItem(#Menu_EditLinks, "Edit Links File")
      MenuItem(#Menu_ChooseLinks, "Choose Links File...")
      MenuItem(#Menu_ReloadLinks, "Reload Links")
      MenuBar()
      MenuItem(#Menu_Exit, "Exit")
      MenuTitle("Help")
      MenuItem(#Menu_Help, "Help")
      MenuBar()
      MenuItem(#Menu_About, "About")
    Else
      LogError("Could not create the application menu.")
    EndIf

    LogInfo("Application started. Links file: " + LinksFilePath())
    If LoadWebsites(LinksFilePath()) = 0
      LogError("Initial links load failed: " + LinksFilePath())
    EndIf
    HandleEvents()
  Else
    LogError("Could not open the main application window.")
  EndIf

  LogInfo("Application exiting.")
  Cleanup()
EndIf

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 107
; FirstLine = 135
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; DPIAware
; UseIcon = loadweblinks.ico
; Executable = ..\loadweblinks.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,4
; VersionField1 = 1,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = loadweblinks
; VersionField4 = 1.0.0.4
; VersionField5 = 1.0.0.4
; VersionField6 = Loads a list of websites that you edit/enter
; VersionField7 = loadweblinks
; VersionField8 = loadweblinks.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60