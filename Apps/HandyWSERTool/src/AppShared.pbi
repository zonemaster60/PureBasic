UseModule EnvSys

Structure EnvDefault
  name.s
  value.s
  typ.l
EndStructure

Global NewList DefaultVars.EnvDefault()
Global DefaultSystemPath.s
Global LogDir.s
Global LogFilePath.s

#Win       = 0
#Log       = 1
#BtnScan   = 2
#BtnRepair = 3
#BtnExport = 4
#BtnImport = 5
#BtnAbout  = 6
#BtnExit   = 7
#BtnFixRefs = 8

Declare AppendLog(msg.s)
Declare BroadcastEnvironmentChange()

Procedure AddDefault(name.s, value.s, typ.l)
  AddElement(DefaultVars())
  DefaultVars()\name  = name
  DefaultVars()\value = value
  DefaultVars()\typ   = typ
EndProcedure

AddDefault("ComSpec",      "C:\Windows\System32\cmd.exe",           #REG_SZ)
AddDefault("OS",           "Windows_NT",                            #REG_SZ)
AddDefault("ProgramData",  "C:\ProgramData",                        #REG_SZ)
AddDefault("ProgramFiles", "C:\Program Files",                      #REG_SZ)
AddDefault("ProgramFiles(x86)", "C:\Program Files (x86)",           #REG_SZ)
AddDefault("ProgramW6432", "C:\Program Files",                      #REG_SZ)
AddDefault("SystemDrive",  "C:",                                    #REG_SZ)
AddDefault("SystemRoot",   "C:\Windows",                            #REG_SZ)
AddDefault("windir",       "C:\Windows",                            #REG_SZ)
AddDefault("PATHEXT", ".COM;.EXE;.BAT;.CMD;.VBS;.VBE;.JS;.JSE;.WSF;.WSH;.MSC", #REG_EXPAND_SZ)

DefaultSystemPath = "C:\Windows\system32;" +
                    "C:\Windows;" +
                    "C:\Windows\System32\Wbem;" +
                    "C:\Windows\System32\WindowsPowerShell\v1.0\;" +
                    "C:\Windows\System32\OpenSSH\"

Procedure.s NormalizePathValue(value.s)
  Protected s.s = Trim(value)
  s = ReplaceString(s, "/", "\\")
  While FindString(s, ";;", 1)
    s = ReplaceString(s, ";;", ";")
  Wend
  ProcedureReturn s
EndProcedure

Procedure.s NormalizeDirValue(value.s)
  Protected s.s = NormalizePathValue(value)
  If Len(s) > 3 And Right(s, 1) = "\\"
    s = Left(s, Len(s) - 1)
  EndIf
  ProcedureReturn s
EndProcedure

Procedure.i ValuesEqual(varName.s, a.s, b.s)
  Protected na.s = a
  Protected nb.s = b

  Select LCase(varName)
    Case "path"
      na = NormalizePathValue(na)
      nb = NormalizePathValue(nb)
    Case "comspec", "programdata", "programfiles", "programfiles(x86)", "programw6432", "systemroot", "windir"
      na = NormalizeDirValue(na)
      nb = NormalizeDirValue(nb)
  EndSelect

  ProcedureReturn Bool(CompareMemoryString(@na, @nb, #PB_String_NoCase) = 0)
EndProcedure

Procedure SplitPathList(pathValue.s, List items.s())
  Protected i.l, part.s
  ClearList(items())
  pathValue = NormalizePathValue(pathValue)
  For i = 1 To CountString(pathValue, ";") + 1
    part = Trim(StringField(pathValue, i, ";"))
    If part <> ""
      AddElement(items())
      items() = part
    EndIf
  Next
EndProcedure

Procedure.s JoinPathList(List items.s())
  Protected out.s
  out = ""
  ForEach items()
    If out <> "" : out + ";" : EndIf
    out + items()
  Next
  ProcedureReturn out
EndProcedure

Procedure.s EnsurePathContainsRequired(originalPath.s, requiredPath.s, *addedCount.Integer)
  Protected NewList origItems.s()
  Protected NewList reqItems.s()
  Protected NewList finalItems.s()
  Protected NewMap seen.i()
  Protected normKey.s
  Protected added.l

  SplitPathList(originalPath, origItems())
  SplitPathList(requiredPath, reqItems())

  ForEach origItems()
    normKey = LCase(NormalizeDirValue(origItems()))
    If normKey <> "" And FindMapElement(seen(), normKey) = 0
      AddMapElement(seen(), normKey)
      seen() = 1
      AddElement(finalItems())
      finalItems() = origItems()
    EndIf
  Next

  added = 0
  ForEach reqItems()
    normKey = LCase(NormalizeDirValue(reqItems()))
    If normKey <> "" And FindMapElement(seen(), normKey) = 0
      AddMapElement(seen(), normKey)
      seen() = 1
      AddElement(finalItems())
      finalItems() = reqItems()
      added + 1
    EndIf
  Next

  If *addedCount
    *addedCount\i = added
  EndIf

  ProcedureReturn JoinPathList(finalItems())
EndProcedure

Procedure.l CountPathDuplicates(pathValue.s)
  Protected NewList items.s()
  Protected NewMap seen.i()
  Protected key.s
  Protected dupes.l

  SplitPathList(pathValue, items())
  dupes = 0
  ForEach items()
    key = LCase(NormalizeDirValue(items()))
    If key <> ""
      If FindMapElement(seen(), key)
        dupes + 1
      Else
        AddMapElement(seen(), key)
        seen() = 1
      EndIf
    EndIf
  Next

  ProcedureReturn dupes
EndProcedure

Procedure.s RecommendedUserValue(varName.s)
  Protected n.s = LCase(varName)
  Protected v.s = GetEnvironmentVariable(varName)
  Protected home.s = NormalizeDirValue(GetHomeDirectory())

  If v <> ""
    ProcedureReturn v
  EndIf

  Select n
    Case "userprofile"
      ProcedureReturn home
    Case "homedrive"
      If Len(home) >= 2 And Mid(home, 2, 1) = ":"
        ProcedureReturn Left(home, 2)
      EndIf
    Case "homepath"
      If Len(home) >= 3 And Mid(home, 2, 1) = ":"
        ProcedureReturn Mid(home, 3)
      EndIf
    Case "temp", "tmp"
      ProcedureReturn "%USERPROFILE%\AppData\Local\Temp"
    Case "appdata"
      ProcedureReturn "%USERPROFILE%\AppData\Roaming"
    Case "localappdata"
      ProcedureReturn "%USERPROFILE%\AppData\Local"
  EndSelect

  ProcedureReturn ""
EndProcedure

Procedure.i IsSystemVar(varName.s)
  Select LCase(varName)
    Case "comspec", "os", "programdata", "programfiles", "programfiles(x86)", "programw6432", "systemdrive", "systemroot", "windir", "pathext", "path"
      ProcedureReturn #True
  EndSelect
  ProcedureReturn #False
EndProcedure

Procedure.i IsFixableUserVar(varName.s)
  Select LCase(varName)
    Case "temp", "tmp", "userprofile", "homedrive", "homepath", "appdata", "localappdata", "onedrive", "onedriveconsumer"
      ProcedureReturn #True
  EndSelect
  ProcedureReturn #False
EndProcedure

Procedure.i IsFixableSystemVar(varName.s)
  If LCase(varName) = "path"
    ProcedureReturn #True
  EndIf

  ForEach DefaultVars()
    If LCase(DefaultVars()\name) = LCase(varName)
      ProcedureReturn #True
    EndIf
  Next

  ProcedureReturn #False
EndProcedure

Procedure.s RecommendedSystemValue(varName.s)
  If LCase(varName) = "path"
    ProcedureReturn DefaultSystemPath
  EndIf

  ForEach DefaultVars()
    If LCase(DefaultVars()\name) = LCase(varName)
      ProcedureReturn DefaultVars()\value
    EndIf
  Next

  ProcedureReturn ""
EndProcedure

Procedure.l RecommendedSystemType(varName.s)
  If LCase(varName) = "path"
    ProcedureReturn #REG_EXPAND_SZ
  EndIf

  ForEach DefaultVars()
    If LCase(DefaultVars()\name) = LCase(varName)
      ProcedureReturn DefaultVars()\typ
    EndIf
  Next

  ProcedureReturn #REG_EXPAND_SZ
EndProcedure

Procedure.i MapHasNonEmptyValue(Map m.EnvSys::VarEntry(), key.s)
  If FindMapElement(m(), key)
    If m()\Value <> ""
      ProcedureReturn #True
    EndIf
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure AddReferencedTokens(value.s, Map referenced.i())
  Protected val.s = value
  Protected token.s
  Protected p1.l, p2.l

  p1 = 1
  While p1 > 0
    p1 = FindString(val, "%", p1)
    If p1 = 0 : Break : EndIf
    p2 = FindString(val, "%", p1 + 1)
    If p2 = 0 : Break : EndIf

    token = Mid(val, p1 + 1, p2 - p1 - 1)
    token = Trim(token)
    If token <> "" And FindString(token, " ", 1) = 0
      AddMapElement(referenced(), LCase(token))
      referenced() = 1
    EndIf

    p1 = p2 + 1
  Wend
EndProcedure

Procedure CollectReferencedFromVars(List vars.EnvSys::VarEntry(), Map referenced.i())
  ForEach vars()
    If vars()\Value <> ""
      AddReferencedTokens(vars()\Value, referenced())
    EndIf
  Next
EndProcedure

Procedure.s LastRegistryErrorText()
  ProcedureReturn EnvSys::LastErrorText()
EndProcedure

Procedure.i LoadScopeOrLog(List vars.EnvSys::VarEntry(), scope.i, label.s)
  If EnvSys::LoadAll(vars(), scope) = #False
    AppendLog("[ERROR] Failed to load " + label + " environment (" + LastRegistryErrorText() + ")")
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure BuildVarMapFromList(List vars.EnvSys::VarEntry(), Map varsMap.EnvSys::VarEntry())
  Protected key.s

  ClearMap(varsMap())
  ForEach vars()
    key = LCase(vars()\Name)
    If key <> ""
      AddMapElement(varsMap(), key)
      varsMap() = vars()
    EndIf
  Next
EndProcedure

Procedure.i LoadScopeAndBuildMap(List vars.EnvSys::VarEntry(), Map varsMap.EnvSys::VarEntry(), scope.i, label.s)
  If LoadScopeOrLog(vars(), scope, label) = #False
    ProcedureReturn #False
  EndIf

  BuildVarMapFromList(vars(), varsMap())
  ProcedureReturn #True
EndProcedure

Procedure.i LoadBothScopesAndMaps(List sysVars.EnvSys::VarEntry(), Map sysMap.EnvSys::VarEntry(), List userVars.EnvSys::VarEntry(), Map userMap.EnvSys::VarEntry())
  If LoadScopeAndBuildMap(sysVars(), sysMap(), EnvSys::#ScopeSystem, "System") = #False
    ProcedureReturn #False
  EndIf
  If LoadScopeAndBuildMap(userVars(), userMap(), EnvSys::#ScopeUser, "User") = #False
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.s MakeTempBackupFileName(prefix.s)
  ProcedureReturn GetTemporaryDirectory() + prefix + "_env_backup_" + Str(Date()) + ".txt"
EndProcedure

Procedure.i BackupScopeOrLog(scope.i, label.s, filePath.s, stopOnFailure.i)
  If EnvSys::Backup(filePath, scope)
    AppendLog(label + " backup saved to: " + filePath)
    ProcedureReturn #True
  EndIf

  If stopOnFailure
    AppendLog(label + " backup FAILED (" + LastRegistryErrorText() + ", no changes made).")
  Else
    AppendLog(label + " backup FAILED (" + LastRegistryErrorText() + ", continuing).")
  EndIf

  ProcedureReturn #False
EndProcedure

Procedure.s PromptExportFile(scopeLabel.s)
  ProcedureReturn SaveFileRequester("Export " + scopeLabel + " environment to...", scopeLabel + "_env_backup.txt", "Text|*.txt", 0)
EndProcedure

Procedure.s PromptImportFile(scopeLabel.s)
  ProcedureReturn OpenFileRequester("Import " + scopeLabel + " environment from...", "", "Text|*.txt", 0)
EndProcedure

Procedure.i ExportScopeOrLog(scope.i, scopeLabel.s, filePath.s)
  If EnvSys::Backup(filePath, scope)
    AppendLog("Export saved to: " + filePath)
    ProcedureReturn #True
  EndIf

  AppendLog("Export FAILED: " + filePath + " (" + LastRegistryErrorText() + ")")
  ProcedureReturn #False
EndProcedure

Procedure.i ImportScopeOrLog(scope.i, scopeLabel.s, filePath.s)
  AppendLog("Importing " + scopeLabel + " environment from: " + filePath)
  AppendLog("")

  If EnvSys::ImportFromFile(filePath, #True, scope)
    BroadcastEnvironmentChange()
    AppendLog("Import OK. Log off or reboot is required for changes to fully apply.")
    ProcedureReturn #True
  EndIf

  AppendLog("Import FAILED (" + LastRegistryErrorText() + ").")
  ProcedureReturn #False
EndProcedure

Procedure.i ImportBothOrLog(filePath.s)
  AppendLog("Importing both environments from: " + filePath)
  AppendLog("")

  If EnvSys::ImportBoth(filePath, #True, EnvSys::#ScopeSystem)
    BroadcastEnvironmentChange()
    AppendLog("Import OK. Log off or reboot is required for changes to fully apply.")
    ProcedureReturn #True
  EndIf

  AppendLog("Import FAILED (" + LastRegistryErrorText() + ").")
  ProcedureReturn #False
EndProcedure
