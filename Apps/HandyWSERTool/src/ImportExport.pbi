Procedure DoExport()
  Protected choice.i
  Protected scope.i
  Protected scopeLabel.s
  Protected file.s

  choice = MessageRequester("Export", "Export which environment scope?" + #CRLF$ + #CRLF$ +
                                     "Yes = System (HKLM)" + #CRLF$ +
                                     "No  = User (HKCU)" + #CRLF$ +
                                     "Cancel = Both (single file)", #PB_MessageRequester_YesNoCancel)

  If choice = #PB_MessageRequester_Yes
    scope = EnvSys::#ScopeSystem
    scopeLabel = "system"
    file = PromptExportFile(scopeLabel)
    If file = "" : ProcedureReturn : EndIf
    ExportScopeOrLog(scope, scopeLabel, file)

  ElseIf choice = #PB_MessageRequester_No
    scope = EnvSys::#ScopeUser
    scopeLabel = "user"
    file = PromptExportFile(scopeLabel)
    If file = "" : ProcedureReturn : EndIf
    ExportScopeOrLog(scope, scopeLabel, file)

  Else
    file = SaveFileRequester("Export both environments to...", "env_backup_both.txt", "Text|*.txt", 0)
    If file = "" : ProcedureReturn : EndIf

    If EnvSys::BackupBoth(file)
      AppendLog("Export saved to: " + file)
    Else
      AppendLog("Export FAILED: " + file + " (" + LastRegistryErrorText() + ")")
    EndIf
  EndIf
EndProcedure

Procedure DoImport()
  Protected choice.i
  Protected scope.i
  Protected scopeLabel.s
  Protected file.s

  choice = MessageRequester("Import", "Import into which environment scope?" + #CRLF$ + #CRLF$ +
                                     "Yes = System (HKLM)" + #CRLF$ +
                                     "No  = User (HKCU)" + #CRLF$ +
                                     "Cancel = Both (from a single file)", #PB_MessageRequester_YesNoCancel)

  If choice = #PB_MessageRequester_Yes
    scope = EnvSys::#ScopeSystem
    scopeLabel = "system"
    file = PromptImportFile(scopeLabel)
    If file = "" : ProcedureReturn : EndIf
    ImportScopeOrLog(scope, scopeLabel, file)

  ElseIf choice = #PB_MessageRequester_No
    scope = EnvSys::#ScopeUser
    scopeLabel = "user"
    file = PromptImportFile(scopeLabel)
    If file = "" : ProcedureReturn : EndIf
    ImportScopeOrLog(scope, scopeLabel, file)

  Else
    file = OpenFileRequester("Import both environments from...", "", "Text|*.txt", 0)
    If file = "" : ProcedureReturn : EndIf
    ImportBothOrLog(file)
  EndIf
EndProcedure
