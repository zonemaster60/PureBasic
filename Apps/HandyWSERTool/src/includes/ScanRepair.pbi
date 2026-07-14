Procedure ScanEnvironment()
  ClearGadgetItems(#Log)

  Protected current.s, expected.s, key.s
  Protected NewList sysVars.EnvSys::VarEntry()
  Protected NewList userVars.EnvSys::VarEntry()
  Protected NewMap sysMap.EnvSys::VarEntry()
  Protected NewMap userMap.EnvSys::VarEntry()
  Protected missingSys.l, emptySys.l, differsSys.l
  Protected missingUser.l, emptyUser.l

  If LoadBothScopesAndMaps(sysVars(), sysMap(), userVars(), userMap()) = #False
    ProcedureReturn
  EndIf

  AppendLog("")
  AppendLog("Scanning for referenced-but-missing %VARS%...")

  Protected NewMap referenced.i()
  Protected token.s

  CollectReferencedFromVars(sysVars(), referenced())
  CollectReferencedFromVars(userVars(), referenced())

  Protected missingRefs.l = 0
  ForEach referenced()
    token = MapKey(referenced())
    If FindMapElement(sysMap(), token) = 0 And FindMapElement(userMap(), token) = 0
      missingRefs + 1
      AppendLog("[REF MISSING] %" + token + "%")
    EndIf
  Next

  If missingRefs = 0
    AppendLog("[OK] No missing referenced variables detected")
  EndIf

  AppendLog("Scanning System environment variables...")
  AppendLog("")

  ForEach DefaultVars()
    key = LCase(DefaultVars()\name)
    expected = DefaultVars()\value

    If FindMapElement(sysMap(), key) = 0
      missingSys + 1
      AppendLog("[MISSING] " + DefaultVars()\name + " (recommended: " + expected + ")")
    Else
      current = sysMap()\Value
      If current = ""
        emptySys + 1
        AppendLog("[EMPTY] " + DefaultVars()\name + " (recommended: " + expected + ")")
      ElseIf ValuesEqual(DefaultVars()\name, current, expected) = #False
        differsSys + 1
        AppendLog("[DIFFERS] " + DefaultVars()\name + " = " + current)
      Else
        AppendLog("[OK] " + DefaultVars()\name)
      EndIf
    EndIf
  Next

  If FindMapElement(sysMap(), "path") = 0
    missingSys + 1
    AppendLog("[MISSING] Path (recommended includes core Windows folders)")
  Else
    current = sysMap()\Value
    If current = ""
      emptySys + 1
      AppendLog("[EMPTY] Path (recommended includes core Windows folders)")
    Else
      Protected NewList reqItems.s()
      Protected NewList curItems.s()
      Protected NewMap curSeen.i()
      Protected missingReq.l
      Protected dupes.l

      SplitPathList(DefaultSystemPath, reqItems())
      SplitPathList(current, curItems())
      dupes = CountPathDuplicates(current)

      ForEach curItems()
        key = LCase(NormalizeDirValue(curItems()))
        If key <> "" And FindMapElement(curSeen(), key) = 0
          AddMapElement(curSeen(), key)
          curSeen() = 1
        EndIf
      Next

      missingReq = 0
      ForEach reqItems()
        key = LCase(NormalizeDirValue(reqItems()))
        If key <> "" And FindMapElement(curSeen(), key) = 0
          missingReq + 1
          AppendLog("[PATH MISSING] " + reqItems())
        EndIf
      Next

      If missingReq = 0
        AppendLog("[PATH OK] Core entries present")
      EndIf
      If dupes > 0
        AppendLog("[PATH INFO] Duplicate entries detected: " + Str(dupes))
      EndIf
    EndIf
  EndIf

  AppendLog("")
  AppendLog("Scanning User environment variables...")
  AppendLog("")

  Macro UserCheck(name, optional)
    key = LCase(name)
    expected = RecommendedUserValue(name)
    If FindMapElement(userMap(), key) = 0
      If optional
        AppendLog("[INFO] " + name + " not set")
      Else
        missingUser + 1
        If expected <> ""
          AppendLog("[MISSING] " + name + " (recommended: " + expected + ")")
        Else
          AppendLog("[MISSING] " + name)
        EndIf
      EndIf
    Else
      current = userMap()\Value
      If current = ""
        If optional
          AppendLog("[INFO] " + name + " is empty")
        Else
          emptyUser + 1
          If expected <> ""
            AppendLog("[EMPTY] " + name + " (recommended: " + expected + ")")
          Else
            AppendLog("[EMPTY] " + name)
          EndIf
        EndIf
      Else
        AppendLog("[OK] " + name)
      EndIf
    EndIf
  EndMacro

  UserCheck("TEMP", #False)
  UserCheck("TMP", #False)
  UserCheck("USERPROFILE", #False)
  UserCheck("HOMEDRIVE", #False)
  UserCheck("HOMEPATH", #False)
  UserCheck("APPDATA", #False)
  UserCheck("LOCALAPPDATA", #False)
  UserCheck("OneDrive", #True)
  UserCheck("OneDriveConsumer", #True)

  If FindMapElement(userMap(), "path") = 0
    AppendLog("[INFO] User Path not set")
  Else
    current = userMap()\Value
    If current = ""
      AppendLog("[INFO] User Path is empty")
    Else
      AppendLog("[OK] User Path exists")
    EndIf
  EndIf

  AppendLog("")
  AppendLog("Scan complete.")
  AppendLog("System: missing=" + Str(missingSys) + ", empty=" + Str(emptySys) + ", differs=" + Str(differsSys))
  AppendLog("User: missing=" + Str(missingUser) + ", empty=" + Str(emptyUser))
EndProcedure

Procedure RepairEnvironment()
  ClearGadgetItems(#Log)
  AppendLog("Starting repair...")
  AppendLog("Creating backup of System environment first...")

  Protected backupFile.s = MakeTempBackupFileName("system")

  If BackupScopeOrLog(EnvSys::#ScopeSystem, "System", backupFile, #True) = #False
    ProcedureReturn
  EndIf

  Protected backupUserFile.s = MakeTempBackupFileName("user")
  BackupScopeOrLog(EnvSys::#ScopeUser, "User", backupUserFile, #False)

  AppendLog("")
  AppendLog("Fixing missing/empty variables (non-destructive)...")

  Protected NewList sysVars.EnvSys::VarEntry()
  Protected NewList userVars.EnvSys::VarEntry()
  Protected NewMap sysMap.EnvSys::VarEntry()
  Protected NewMap userMap.EnvSys::VarEntry()
  Protected key.s, current.s

  If LoadScopeAndBuildMap(sysVars(), sysMap(), EnvSys::#ScopeSystem, "System") = #False
    AppendLog("Repair aborted.")
    ProcedureReturn
  EndIf

  If LoadScopeAndBuildMap(userVars(), userMap(), EnvSys::#ScopeUser, "User") = #False
    AppendLog("Repair aborted.")
    ProcedureReturn
  EndIf

  ForEach DefaultVars()
    key = LCase(DefaultVars()\name)
    If FindMapElement(sysMap(), key) = 0 Or sysMap()\Value = ""
      If EnvSys::WriteVar(DefaultVars()\name, DefaultVars()\value, DefaultVars()\typ, EnvSys::#ScopeSystem)
        AppendLog("[FIXED] " + DefaultVars()\name + " = " + DefaultVars()\value)
      Else
        AppendLog("[FAILED] " + DefaultVars()\name + " (" + LastRegistryErrorText() + ")")
      EndIf
    Else
      AppendLog("[SKIP] " + DefaultVars()\name + " already set")
    EndIf
  Next

  Protected addedCount.Integer
  If FindMapElement(sysMap(), "path") = 0 Or sysMap()\Value = ""
    If EnvSys::WriteVar("Path", DefaultSystemPath, #REG_EXPAND_SZ, EnvSys::#ScopeSystem)
      AppendLog("[FIXED] Path set to core defaults")
    Else
      AppendLog("[FAILED] Path (" + LastRegistryErrorText() + ")")
    EndIf
  Else
    Protected newPath.s = EnsurePathContainsRequired(sysMap()\Value, DefaultSystemPath, @addedCount)
    If ValuesEqual("Path", newPath, sysMap()\Value) = #False
      If EnvSys::WriteVar("Path", newPath, #REG_EXPAND_SZ, EnvSys::#ScopeSystem)
        AppendLog("[FIXED] Path updated (added core entries: " + Str(addedCount\i) + ")")
      Else
        AppendLog("[FAILED] Path (" + LastRegistryErrorText() + ")")
      EndIf
    Else
      AppendLog("[OK] Path already contains core entries")
    EndIf
  EndIf

  AppendLog("")
  AppendLog("Fixing missing/empty User variables...")

  Protected rec.s
  Macro FixUser(name)
    key = LCase(name)
    current = ""
    If FindMapElement(userMap(), key)
      current = userMap()\Value
    EndIf
    rec = RecommendedUserValue(name)
    If rec <> "" And (FindMapElement(userMap(), key) = 0 Or current = "")
      If EnvSys::WriteVar(name, rec, #REG_EXPAND_SZ, EnvSys::#ScopeUser)
        AppendLog("[FIXED] " + name + " = " + rec)
      Else
        AppendLog("[FAILED] " + name + " (" + LastRegistryErrorText() + ")")
      EndIf
    Else
      AppendLog("[SKIP] " + name + " already set")
    EndIf
  EndMacro

  FixUser("USERPROFILE")
  FixUser("HOMEDRIVE")
  FixUser("HOMEPATH")
  FixUser("APPDATA")
  FixUser("LOCALAPPDATA")
  FixUser("TEMP")
  FixUser("TMP")
  FixUser("OneDrive")

  BroadcastEnvironmentChange()

  AppendLog("")
  AppendLog("Repair complete. New processes will see updates; log off/reboot may still be required for some apps.")
EndProcedure

Procedure FixReferencedMissingVars()
  ClearGadgetItems(#Log)
  AppendLog("Fixing referenced-but-missing %VARS% only...")

  Protected backupSysFile.s = MakeTempBackupFileName("system")
  Protected backupUserFile.s = MakeTempBackupFileName("user")

  If BackupScopeOrLog(EnvSys::#ScopeSystem, "System", backupSysFile, #True) = #False
    ProcedureReturn
  EndIf

  BackupScopeOrLog(EnvSys::#ScopeUser, "User", backupUserFile, #False)

  Protected NewList sysVars.EnvSys::VarEntry()
  Protected NewList userVars.EnvSys::VarEntry()
  Protected NewMap sysMap.EnvSys::VarEntry()
  Protected NewMap userMap.EnvSys::VarEntry()
  Protected NewMap referenced.i()
  Protected key.s, token.s

  If LoadBothScopesAndMaps(sysVars(), sysMap(), userVars(), userMap()) = #False
    AppendLog("Fix %Vars% aborted.")
    ProcedureReturn
  EndIf

  CollectReferencedFromVars(sysVars(), referenced())
  CollectReferencedFromVars(userVars(), referenced())

  Protected fixed.l = 0
  Protected skipped.l = 0
  Protected failed.l = 0
  Protected recSys.s, recUser.s

  ForEach referenced()
    token = MapKey(referenced())

    If MapHasNonEmptyValue(sysMap(), token) Or MapHasNonEmptyValue(userMap(), token)
      Continue
    EndIf

    If IsSystemVar(token) Or IsFixableSystemVar(token)
      If IsFixableSystemVar(token)
        recSys = RecommendedSystemValue(token)
        If token = "path" And FindMapElement(sysMap(), "path")
          Protected addedCount.Integer
          recSys = EnsurePathContainsRequired(sysMap()\Value, DefaultSystemPath, @addedCount)
        EndIf

        If recSys <> ""
          If EnvSys::WriteVar(token, recSys, RecommendedSystemType(token), EnvSys::#ScopeSystem)
            AppendLog("[FIXED] %" + token + "% -> System")
            fixed + 1
          Else
            AppendLog("[FAILED] %" + token + "% -> System (" + LastRegistryErrorText() + ")")
            failed + 1
          EndIf
        Else
          AppendLog("[SKIP] %" + token + "% (no system recommendation)")
          skipped + 1
        EndIf
      Else
        AppendLog("[SKIP] %" + token + "% (not a fixable system var)")
        skipped + 1
      EndIf
    Else
      If IsFixableUserVar(token)
        recUser = RecommendedUserValue(token)
        If recUser <> ""
          If EnvSys::WriteVar(token, recUser, #REG_EXPAND_SZ, EnvSys::#ScopeUser)
            AppendLog("[FIXED] %" + token + "% -> User")
            fixed + 1
          Else
            AppendLog("[FAILED] %" + token + "% -> User (" + LastRegistryErrorText() + ")")
            failed + 1
          EndIf
        Else
          AppendLog("[SKIP] %" + token + "% (no user recommendation)")
          skipped + 1
        EndIf
      Else
        AppendLog("[SKIP] %" + token + "% (unknown/unfixable)")
        skipped + 1
      EndIf
    EndIf
  Next

  BroadcastEnvironmentChange()

  AppendLog("")
  AppendLog("Fix %Vars% complete. fixed=" + Str(fixed) + ", skipped=" + Str(skipped) + ", failed=" + Str(failed))
  AppendLog("New processes will see updates; log off/reboot may still be required for some apps.")
EndProcedure
