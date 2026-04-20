If OpenWindow(#Win, 200, 200, 800, 550, #APP_NAME + " - " + version, #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget) = 0
  MessageRequester("Error", "Failed to create the main window.", #PB_MessageRequester_Error)
  CloseAppMutex()
  End
EndIf
EditorGadget(#Log, 10, 10, 780, 460, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
ButtonGadget(#BtnScan,   10, 480, 120, 40, "Scan")
ButtonGadget(#BtnRepair, 140, 480, 120, 40, "Repair")
ButtonGadget(#BtnExport, 270, 480, 120, 40, "Export")
ButtonGadget(#BtnImport, 400, 480, 120, 40, "Import")
ButtonGadget(#BtnAbout, 530, 480, 120, 40, "About")
ButtonGadget(#BtnFixRefs, 660, 480, 120, 40, "Fix %Vars%")
ButtonGadget(#BtnExit, 660, 525, 120, 20, "Exit")

InitializeLogging()
AppendLog("Log file: " + LogFilePath)
