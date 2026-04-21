; SaveGame / LoadGame procedures
; Supports multi-slot saving and loading.

Procedure.s SaveFolderPath()
  ProcedureReturn SavePath
EndProcedure

Procedure.i NormalizeSaveSlot(slotName.s, *outSlot.String, allowExtension.i = 0)
  Protected trimmed.s = Trim(slotName)
  If trimmed = "" : ProcedureReturn 0 : EndIf
  If allowExtension
    Protected ext.s = LCase(GetExtensionPart(trimmed))
    If ext = "sav" Or ext = "txt"
      trimmed = GetFilePart(trimmed, #PB_FileSystem_NoExtension)
    EndIf
  EndIf
  If IsSafeFileToken(trimmed) = 0
    ProcedureReturn 0
  EndIf
  *outSlot\s = trimmed
  ProcedureReturn 1
EndProcedure

Procedure.i EnsureSaveFolder()
  Protected path.s = SaveFolderPath()
  If FileSize(path) <> -2
    ProcedureReturn CreateDirectory(path)
  EndIf
  ProcedureReturn 1
EndProcedure

Procedure.s GetSavePath(slotName.s)
  Protected safeSlot.String
  If NormalizeSaveSlot(slotName, @safeSlot, 1) = 0
    ProcedureReturn ""
  EndIf
  If EnsureSaveFolder() = 0
    ProcedureReturn ""
  EndIf
  ProcedureReturn SaveFolderPath() + safeSlot\s + ".sav"
EndProcedure

Procedure.s GetLegacySavePath(slotName.s)
  Protected safeSlot.String
  If NormalizeSaveSlot(slotName, @safeSlot, 1) = 0
    ProcedureReturn ""
  EndIf
  ProcedureReturn SaveFolderPath() + safeSlot\s + ".txt"
EndProcedure

Procedure.i SaveFileLine(f.i, line.s)
  ProcedureReturn Bool(WriteStringN(f, line) > 0)
EndProcedure

Procedure.i SaveShipLine(f.i, prefix.s, idx.i, *s.Ship)
  Protected line.s = prefix + "|" + Str(idx) + "|" + SafeField(*s\name) + "|" + SafeField(*s\class) + "|" +
                     Str(*s\hullMax) + "|" + Str(*s\hull) + "|" +
                     Str(*s\shieldsMax) + "|" + Str(*s\shields) + "|" +
                     Str(*s\reactorMax) + "|" + StrF(*s\warpMax) + "|" + StrF(*s\impulseMax) + "|" +
                     Str(*s\phaserBanks) + "|" + Str(*s\torpTubes) + "|" +
                     Str(*s\torpMax) + "|" + Str(*s\torp) + "|" +
                     Str(*s\sensorRange) + "|" +
                     Str(*s\weaponCapMax) + "|" + Str(*s\weaponCap) + "|" +
                     Str(*s\fuelMax) + "|" + Str(*s\fuel) + "|" +
                     Str(*s\oreMax) + "|" + Str(*s\ore) + "|" +
                     Str(*s\dilithiumMax) + "|" + Str(*s\dilithium) + "|" +
                     Str(*s\probesMax) + "|" + Str(*s\probes) + "|" +
                     Str(*s\allocShields) + "|" + Str(*s\allocWeapons) + "|" + Str(*s\allocEngines) + "|" +
                     Str(*s\sysEngines) + "|" + Str(*s\sysWeapons) + "|" + Str(*s\sysShields) + "|" + Str(*s\sysTractor) + "|" +
                     SafeField(*s\crew1\name) + "|" + Str(*s\crew1\role) + "|" + Str(*s\crew1\rank) + "|" + Str(*s\crew1\xp) + "|" + Str(*s\crew1\level) + "|" +
                     SafeField(*s\crew2\name) + "|" + Str(*s\crew2\role) + "|" + Str(*s\crew2\rank) + "|" + Str(*s\crew2\xp) + "|" + Str(*s\crew2\level) + "|" +
                     SafeField(*s\crew3\name) + "|" + Str(*s\crew3\role) + "|" + Str(*s\crew3\rank) + "|" + Str(*s\crew3\xp) + "|" + Str(*s\crew3\level) + "|" +
                     SafeField(*s\crew4\name) + "|" + Str(*s\crew4\role) + "|" + Str(*s\crew4\rank) + "|" + Str(*s\crew4\xp) + "|" + Str(*s\crew4\level)
  If SaveFileLine(f, line) = 0
    ProcedureReturn 0
  EndIf
  ProcedureReturn 1
EndProcedure

Procedure LoadShipFields(*s.Ship, line.s, startField.i)
  *s\name         = LoadField(StringField(line, startField, "|"))
  *s\class        = LoadField(StringField(line, startField + 1, "|"))
  *s\hullMax      = Val(StringField(line, startField + 2, "|"))
  *s\hull         = Val(StringField(line, startField + 3, "|"))
  *s\shieldsMax   = Val(StringField(line, startField + 4, "|"))
  *s\shields      = Val(StringField(line, startField + 5, "|"))
  *s\reactorMax   = Val(StringField(line, startField + 6, "|"))
  *s\warpMax      = ValF(StringField(line, startField + 7, "|"))
  *s\impulseMax   = ValF(StringField(line, startField + 8, "|"))
  *s\phaserBanks  = Val(StringField(line, startField + 9, "|"))
  *s\torpTubes    = Val(StringField(line, startField + 10, "|"))
  *s\torpMax      = Val(StringField(line, startField + 11, "|"))
  *s\torp         = Val(StringField(line, startField + 12, "|"))
  *s\sensorRange  = Val(StringField(line, startField + 13, "|"))
  *s\weaponCapMax = Val(StringField(line, startField + 14, "|"))
  *s\weaponCap    = Val(StringField(line, startField + 15, "|"))
  *s\fuelMax      = Val(StringField(line, startField + 16, "|"))
  *s\fuel         = Val(StringField(line, startField + 17, "|"))
  *s\oreMax       = Val(StringField(line, startField + 18, "|"))
  *s\ore          = Val(StringField(line, startField + 19, "|"))
  *s\dilithiumMax = Val(StringField(line, startField + 20, "|"))
  *s\dilithium    = Val(StringField(line, startField + 21, "|"))
  *s\probesMax    = Val(StringField(line, startField + 22, "|"))
  *s\probes       = Val(StringField(line, startField + 23, "|"))
  *s\allocShields = Val(StringField(line, startField + 24, "|"))
  *s\allocWeapons = Val(StringField(line, startField + 25, "|"))
  *s\allocEngines = Val(StringField(line, startField + 26, "|"))
  *s\sysEngines   = Val(StringField(line, startField + 27, "|"))
  *s\sysWeapons   = Val(StringField(line, startField + 28, "|"))
  *s\sysShields   = Val(StringField(line, startField + 29, "|"))
  *s\sysTractor   = Val(StringField(line, startField + 30, "|"))
  *s\crew1\name   = LoadField(StringField(line, startField + 31, "|"))
  *s\crew1\role   = Val(StringField(line, startField + 32, "|"))
  *s\crew1\rank   = Val(StringField(line, startField + 33, "|"))
  *s\crew1\xp     = Val(StringField(line, startField + 34, "|"))
  *s\crew1\level  = Val(StringField(line, startField + 35, "|"))
  *s\crew2\name   = LoadField(StringField(line, startField + 36, "|"))
  *s\crew2\role   = Val(StringField(line, startField + 37, "|"))
  *s\crew2\rank   = Val(StringField(line, startField + 38, "|"))
  *s\crew2\xp     = Val(StringField(line, startField + 39, "|"))
  *s\crew2\level  = Val(StringField(line, startField + 40, "|"))
  *s\crew3\name   = LoadField(StringField(line, startField + 41, "|"))
  *s\crew3\role   = Val(StringField(line, startField + 42, "|"))
  *s\crew3\rank   = Val(StringField(line, startField + 43, "|"))
  *s\crew3\xp     = Val(StringField(line, startField + 44, "|"))
  *s\crew3\level  = Val(StringField(line, startField + 45, "|"))
  *s\crew4\name   = LoadField(StringField(line, startField + 46, "|"))
  *s\crew4\role   = Val(StringField(line, startField + 47, "|"))
  *s\crew4\rank   = Val(StringField(line, startField + 48, "|"))
  *s\crew4\xp     = Val(StringField(line, startField + 49, "|"))
  *s\crew4\level  = Val(StringField(line, startField + 50, "|"))
EndProcedure

Procedure.i SaveGame(*p.Ship, slotName.s = "autosave")
  Protected fullPath.s = GetSavePath(slotName)
  If fullPath = ""
    PrintN("Invalid save slot name. Use letters, numbers, . _ or -")
    ProcedureReturn 0
  EndIf
  Protected tmpPath.s = fullPath + ".tmp"
  Protected f.i = CreateFile(#PB_Any, tmpPath)
  If f = 0
    LogLine("SAVE: failed to write " + GetFilePart(fullPath))
    ProcedureReturn 0
  EndIf
  Protected ok.i = 1
  Protected playerExtLine.s

  ok = SaveFileLine(f, "version|3")
  If ok : ok = SaveFileLine(f, "mode|" + Str(gMode)) : EndIf
  If ok : ok = SaveFileLine(f, "pos|" + Str(gMapX) + "|" + Str(gMapY) + "|" + Str(gx) + "|" + Str(gy)) : EndIf
  If ok : ok = SaveFileLine(f, "credits|" + Str(gCredits)) : EndIf
  If ok : ok = SaveFileLine(f, "bank|" + Str(gBankBalance)) : EndIf
  If ok : ok = SaveFileLine(f, "stardate|" + StrF(gStardate) + "|" + Str(gGameDay)) : EndIf
  If ok : ok = SaveFileLine(f, "metals|" + Str(gIron) + "|" + Str(gAluminum) + "|" + Str(gCopper) + "|" + Str(gTin) + "|" + Str(gBronze)) : EndIf
  If ok : ok = SaveFileLine(f, "settings|" + Str(gAutosaveInterval) + "|" + Str(gAutoclearInterval)) : EndIf
  If ok : ok = SaveFileLine(f, "transporter|" + Str(gTransporterPower) + "|" + Str(gTransporterRange) + "|" + Str(gTransporterCrew)) : EndIf
  If ok : ok = SaveFileLine(f, "probesys|" + Str(gProbeRange) + "|" + Str(gProbeAccuracy)) : EndIf
  If ok : ok = SaveFileLine(f, "sound|" + Str(gSoundEnabled)) : EndIf
  If ok : ok = SaveFileLine(f, "dock|" + Str(gDocked)) : EndIf
  If ok : ok = SaveFileLine(f, "shuttle|" + Str(gShuttleLaunched) + "|" + Str(gShuttleCrew) + "|" + Str(gShuttleCargoOre) + "|" + Str(gShuttleCargoDilithium) + "|" + Str(gShuttleMaxCargo) + "|" + Str(gShuttleMaxCrew) + "|" + Str(gShuttleAttackRange)) : EndIf
  If ok : ok = SaveFileLine(f, "upgrades|" + Str(gUpgradeHull) + "|" + Str(gUpgradeShields) + "|" + Str(gUpgradeWeapons) + "|" + Str(gUpgradePropulsion) + "|" + Str(gUpgradePowerCargo) + "|" + Str(gUpgradeProbes) + "|" + Str(gUpgradeShuttle)) : EndIf
  If ok : ok = SaveFileLine(f, "cheats|" + Str(gCheatsUnlocked) + "|" + gCheatCode) : EndIf
  If ok : ok = SaveFileLine(f, "powerbuff|" + Str(gPowerBuff) + "|" + Str(gPowerBuffTurns)) : EndIf
  If ok : ok = SaveFileLine(f, "hq|" + Str(gHQMapX) + "|" + Str(gHQMapY) + "|" + Str(gHQX) + "|" + Str(gHQY)) : EndIf
  If ok : ok = SaveFileLine(f, "hqmissions|" + Str(gHQMissionsCompleted) + "|" + Str(gRecallArmed)) : EndIf
  If ok : ok = SaveFileLine(f, "manifest|" + Str(gTotalKills) + "|" + Str(gTotalMissions) + "|" + Str(gTotalCreditsEarned)) : EndIf
  If ok : ok = SaveFileLine(f, "lastheading|" + Str(gLastHeading)) : EndIf

  ; Save player fleet
  If ok : ok = SaveFileLine(f, "playerfleet|" + Str(gPlayerFleetCount)) : EndIf
  Protected pf.i
  For pf = 1 To gPlayerFleetCount
    If ok : ok = SaveShipLine(f, "pfleet", pf, @gPlayerFleet(pf)) : EndIf
  Next

  If ok : ok = SaveFileLine(f, "player|" + SafeField(*p\name) + "|" + SafeField(*p\class) + "|" +
                  Str(*p\hullMax) + "|" + Str(*p\hull) + "|" +
                  Str(*p\shieldsMax) + "|" + Str(*p\shields) + "|" +
                  Str(*p\reactorMax) + "|" + StrF(*p\warpMax) + "|" + StrF(*p\impulseMax) + "|" +
                  Str(*p\phaserBanks) + "|" + Str(*p\torpTubes) + "|" +
                  Str(*p\torpMax) + "|" + Str(*p\torp) + "|" +
                  Str(*p\sensorRange) + "|" +
                  Str(*p\weaponCapMax) + "|" + Str(*p\weaponCap) + "|" +
                  Str(*p\fuelMax) + "|" + Str(*p\fuel) + "|" +
                  Str(*p\oreMax) + "|" + Str(*p\ore) + "|" +
                  Str(*p\dilithiumMax) + "|" + Str(*p\dilithium) + "|" +
                  Str(*p\probesMax) + "|" + Str(*p\probes) + "|" +
                  Str(*p\allocShields) + "|" + Str(*p\allocWeapons) + "|" + Str(*p\allocEngines) + "|" +
                  Str(*p\sysEngines) + "|" + Str(*p\sysWeapons) + "|" + Str(*p\sysShields)) : EndIf
  If ok
    playerExtLine = "playerext|" + Str(*p\sysTractor)
    ok = SaveFileLine(f, playerExtLine)
  EndIf
  
  If ok : ok = SaveFileLine(f, "crew|0|" + SafeField(*p\crew1\name) + "|" + Str(*p\crew1\role) + "|" + Str(*p\crew1\rank) + "|" + Str(*p\crew1\xp) + "|" + Str(*p\crew1\level)) : EndIf
  If ok : ok = SaveFileLine(f, "crew|1|" + SafeField(*p\crew2\name) + "|" + Str(*p\crew2\role) + "|" + Str(*p\crew2\rank) + "|" + Str(*p\crew2\xp) + "|" + Str(*p\crew2\level)) : EndIf
  If ok : ok = SaveFileLine(f, "crew|2|" + SafeField(*p\crew3\name) + "|" + Str(*p\crew3\role) + "|" + Str(*p\crew3\rank) + "|" + Str(*p\crew3\xp) + "|" + Str(*p\crew3\level)) : EndIf
  If ok : ok = SaveFileLine(f, "crew|3|" + SafeField(*p\crew4\name) + "|" + Str(*p\crew4\role) + "|" + Str(*p\crew4\rank) + "|" + Str(*p\crew4\xp) + "|" + Str(*p\crew4\level)) : EndIf

  ; Save recruits
  If ok : ok = SaveFileLine(f, "recruits|" + Str(gRecruitCount)) : EndIf
  Protected r.i
  For r = 0 To gRecruitCount - 1
    If ok : ok = SaveFileLine(f, "recruit|" + Str(r) + "|" + SafeField(gRecruitNames(r)) + "|" + SafeField(gRecruitRoles(r))) : EndIf
  Next

  If ok : ok = SaveFileLine(f, "mission|" + Str(gMission\active) + "|" + Str(gMission\type) + "|" +
                  SafeField(gMission\title) + "|" + SafeField(gMission\desc) + "|" +
                  Str(gMission\oreRequired) + "|" +
                  Str(gMission\killsRequired) + "|" + Str(gMission\killsDone) + "|" +
                  Str(gMission\destMapX) + "|" + Str(gMission\destMapY) + "|" + Str(gMission\destX) + "|" + Str(gMission\destY) + "|" +
                  Str(gMission\destEntType) + "|" + SafeField(gMission\destName) + "|" +
                  Str(gMission\rewardCredits) + "|" +
                  Str(gMission\turnsLeft) + "|" + Str(gMission\yardHP) + "|" + Str(gMission\threatLevel)) : EndIf

  ; Save captain's log
  If ok : ok = SaveFileLine(f, "caplog|" + Str(gCaptainLogCount)) : EndIf
  Protected c.i
  For c = 0 To gCaptainLogCount - 1
    If ok : ok = SaveFileLine(f, "capentry|" + SafeField(gCaptainLog(c))) : EndIf
  Next

  ; Galaxy cells: store all non-empty cells.
  Protected mx.i, my.i, x.i, y.i
  For my = 0 To #GALAXY_H - 1
    For mx = 0 To #GALAXY_W - 1
      For y = 0 To #MAP_H - 1
        For x = 0 To #MAP_W - 1
          If gGalaxy(mx, my, x, y)\entType <> #ENT_EMPTY
            If ok : ok = SaveFileLine(f, "cell|" + Str(mx) + "|" + Str(my) + "|" + Str(x) + "|" + Str(y) + "|" +
                            Str(gGalaxy(mx, my, x, y)\entType) + "|" +
                            Str(gGalaxy(mx, my, x, y)\richness) + "|" +
                            Str(gGalaxy(mx, my, x, y)\enemyLevel) + "|" +
                            SafeField(gGalaxy(mx, my, x, y)\name) + "|" +
                            Str(gGalaxy(mx, my, x, y)\spawned) + "|" + Str(gGalaxy(mx, my, x, y)\ore) + "|" + Str(gGalaxy(mx, my, x, y)\dilithium)) : EndIf
          EndIf
        Next
      Next
    Next
  Next

  CloseFile(f)
  If ok = 0
    DeleteFile(tmpPath)
    LogLine("SAVE: failed while writing " + GetFilePart(fullPath))
    ProcedureReturn 0
  EndIf
  Protected bakPath.s = fullPath + ".bak"
  If FileSize(bakPath) >= 0
    DeleteFile(bakPath)
  EndIf
  If FileSize(fullPath) >= 0 And RenameFile(fullPath, bakPath) = 0
    DeleteFile(tmpPath)
    LogLine("SAVE: failed to prepare " + GetFilePart(fullPath))
    ProcedureReturn 0
  EndIf
  If RenameFile(tmpPath, fullPath) = 0
    If FileSize(bakPath) >= 0
      RenameFile(bakPath, fullPath)
    EndIf
    DeleteFile(tmpPath)
    LogLine("SAVE: failed to finalize " + GetFilePart(fullPath))
    ProcedureReturn 0
  EndIf
  If FileSize(bakPath) >= 0
    DeleteFile(bakPath)
  EndIf
  LogLine("SAVE: wrote " + GetFilePart(fullPath))
  ProcedureReturn 1
EndProcedure

Procedure.i LoadGame(*p.Ship, slotName.s = "autosave")
  Protected fullPath.s = GetSavePath(slotName)
  If fullPath = ""
    PrintN("Invalid save slot name. Use letters, numbers, . _ or -")
    ProcedureReturn 0
  EndIf
  If FileSize(fullPath) < 0
    Protected legacyPath.s = GetLegacySavePath(slotName)
    If legacyPath <> "" And FileSize(legacyPath) >= 0
      fullPath = legacyPath
    EndIf
  EndIf
  
  Protected f.i = ReadFile(#PB_Any, fullPath)
  If f = 0
    LogLine("LOAD: no save file " + GetFilePart(fullPath))
    ProcedureReturn 0
  EndIf

  StopEngineLoop()
  ResetGameState(*p)

  ; Clear galaxy before applying saved cells
  Protected mx.i, my.i
  For my = 0 To #GALAXY_H - 1
    For mx = 0 To #GALAXY_W - 1
      ClearSectorMap(mx, my)
    Next
  Next

  ClearStructure(@gMission, Mission)
  gMission\type = #MIS_NONE
  gCredits = 0

  Protected line.s, kind.s
  While Eof(f) = 0
    line = ReadString(f)
    line = Trim(line)
    If line = "" : Continue : EndIf
    kind = StringField(line, 1, "|")
    Select kind
      Case "version"
        Protected saveVersion.i = Val(StringField(line, 2, "|"))
        If saveVersion <> 2 And saveVersion <> 3
          CloseFile(f)
          LogLine("LOAD: unsupported save version in " + GetFilePart(fullPath))
          ProcedureReturn 0
        EndIf
      Case "mode"
        ; Always start in galaxy mode when loading - never load into combat
        gMode = #MODE_GALAXY
      Case "pos"
        gMapX = Val(StringField(line, 2, "|"))
        gMapY = Val(StringField(line, 3, "|"))
        gx    = Val(StringField(line, 4, "|"))
        gy    = Val(StringField(line, 5, "|"))
      Case "credits"
        gCredits = Val(StringField(line, 2, "|"))
      Case "bank"
        gBankBalance = Val(StringField(line, 2, "|"))
      Case "stardate"
        gStardate = ValF(StringField(line, 2, "|"))
        gGameDay = Val(StringField(line, 3, "|"))
      Case "metals"
        gIron      = Val(StringField(line, 2, "|"))
        gAluminum  = Val(StringField(line, 3, "|"))
        gCopper    = Val(StringField(line, 4, "|"))
        gTin       = Val(StringField(line, 5, "|"))
        gBronze    = Val(StringField(line, 6, "|"))
      Case "settings"
        gAutosaveInterval  = Val(StringField(line, 2, "|"))
        gAutoclearInterval = Val(StringField(line, 3, "|"))
      Case "sound"
        gSoundEnabled = Val(StringField(line, 2, "|"))
        If gSoundEnabled <> 0 And gSoundEnabled <> 1 : gSoundEnabled = 1 : EndIf
      Case "dock"
        gDocked = Val(StringField(line, 2, "|"))
        If gDocked <> 0 And gDocked <> 1 : gDocked = 0 : EndIf
      Case "transporter"
        gTransporterPower = Val(StringField(line, 2, "|"))
        gTransporterRange = Val(StringField(line, 3, "|"))
        gTransporterCrew = Val(StringField(line, 4, "|"))
        If gTransporterPower <= 0 : gTransporterPower = 50 : EndIf
        If gTransporterRange <= 0 : gTransporterRange = 5 : EndIf
        If gTransporterCrew <= 0 : gTransporterCrew = 2 : EndIf
      Case "probesys"
        gProbeRange = Val(StringField(line, 2, "|"))
        gProbeAccuracy = Val(StringField(line, 3, "|"))
        If gProbeRange <= 0 : gProbeRange = 3 : EndIf
        If gProbeAccuracy <= 0 : gProbeAccuracy = 75 : EndIf
      Case "shuttle"
        gShuttleLaunched = Val(StringField(line, 2, "|"))
        gShuttleCrew = Val(StringField(line, 3, "|"))
        gShuttleCargoOre = Val(StringField(line, 4, "|"))
        gShuttleCargoDilithium = Val(StringField(line, 5, "|"))
        gShuttleMaxCargo = Val(StringField(line, 6, "|"))
        gShuttleMaxCrew = Val(StringField(line, 7, "|"))
        gShuttleAttackRange = Val(StringField(line, 8, "|"))
        If gShuttleMaxCargo <= 0 : gShuttleMaxCargo = 10 : EndIf
        If gShuttleMaxCrew <= 0 : gShuttleMaxCrew = 6 : EndIf
        If gShuttleAttackRange <= 0 : gShuttleAttackRange = 10 : EndIf
      Case "upgrades"
        gUpgradeHull = Val(StringField(line, 2, "|"))
        gUpgradeShields = Val(StringField(line, 3, "|"))
        gUpgradeWeapons = Val(StringField(line, 4, "|"))
        gUpgradePropulsion = Val(StringField(line, 5, "|"))
        gUpgradePowerCargo = Val(StringField(line, 6, "|"))
        gUpgradeProbes = Val(StringField(line, 7, "|"))
        gUpgradeShuttle = Val(StringField(line, 8, "|"))
        If gUpgradeHull < 0 : gUpgradeHull = 0 : EndIf
        If gUpgradeShields < 0 : gUpgradeShields = 0 : EndIf
        If gUpgradeWeapons < 0 : gUpgradeWeapons = 0 : EndIf
        If gUpgradePropulsion < 0 : gUpgradePropulsion = 0 : EndIf
        If gUpgradePowerCargo < 0 : gUpgradePowerCargo = 0 : EndIf
        If gUpgradeProbes < 0 : gUpgradeProbes = 0 : EndIf
        If gUpgradeShuttle < 0 : gUpgradeShuttle = 0 : EndIf
      Case "cheats"
        gCheatsUnlocked = Val(StringField(line, 2, "|"))
        gCheatCode = StringField(line, 3, "|")
      Case "powerbuff"
        gPowerBuff      = Val(StringField(line, 2, "|"))
        gPowerBuffTurns = Val(StringField(line, 3, "|"))
        If gPowerBuff <> 0 And gPowerBuff <> 1 : gPowerBuff = 0 : EndIf
        If gPowerBuffTurns < 0 : gPowerBuffTurns = 0 : EndIf
      Case "hq"
        gHQMapX = Val(StringField(line, 2, "|"))
        gHQMapY = Val(StringField(line, 3, "|"))
        gHQX    = Val(StringField(line, 4, "|"))
        gHQY    = Val(StringField(line, 5, "|"))
        If gHQMapX < 0 Or gHQMapX >= #GALAXY_W : gHQMapX = #GALAXY_W / 2 : EndIf
        If gHQMapY < 0 Or gHQMapY >= #GALAXY_H : gHQMapY = #GALAXY_H / 2 : EndIf
        If gHQX < 0 Or gHQX >= #MAP_W : gHQX = 0 : EndIf
        If gHQY < 0 Or gHQY >= #MAP_H : gHQY = 0 : EndIf
      Case "hqmissions"
        gHQMissionsCompleted = Val(StringField(line, 2, "|"))
        gRecallArmed         = Val(StringField(line, 3, "|"))
        If gHQMissionsCompleted < 0 : gHQMissionsCompleted = 0 : EndIf
        If gRecallArmed <> 0 And gRecallArmed <> 1 : gRecallArmed = 0 : EndIf
      Case "manifest"
        gTotalKills         = Val(StringField(line, 2, "|"))
        gTotalMissions      = Val(StringField(line, 3, "|"))
        gTotalCreditsEarned = Val(StringField(line, 4, "|"))
        If gTotalKills < 0         : gTotalKills = 0         : EndIf
        If gTotalMissions < 0      : gTotalMissions = 0      : EndIf
        If gTotalCreditsEarned < 0 : gTotalCreditsEarned = 0 : EndIf
      Case "lastheading"
        Protected lhVal.i = Val(StringField(line, 2, "|"))
        Select lhVal
          Case -1, 0, 45, 90, 135, 180, 225, 270, 315
            gLastHeading = lhVal
        EndSelect
      Case "playerfleet"
        gPlayerFleetCount = Val(StringField(line, 2, "|"))
        If gPlayerFleetCount < 0 : gPlayerFleetCount = 0 : EndIf
        If gPlayerFleetCount > 5 : gPlayerFleetCount = 5 : EndIf
      Case "pfleet"
        Protected pfLoad.i = Val(StringField(line, 2, "|"))
        If pfLoad >= 1 And pfLoad <= 5
          LoadShipFields(@gPlayerFleet(pfLoad), line, 3)
        EndIf
      Case "player"
        *p\name        = LoadField(StringField(line, 2, "|"))
        *p\class       = LoadField(StringField(line, 3, "|"))
        *p\hullMax     = Val(StringField(line, 4, "|"))
        *p\hull        = Val(StringField(line, 5, "|"))
        *p\shieldsMax  = Val(StringField(line, 6, "|"))
        *p\shields     = Val(StringField(line, 7, "|"))
        *p\reactorMax  = Val(StringField(line, 8, "|"))
        *p\warpMax     = ValF(StringField(line, 9, "|"))
        *p\impulseMax  = ValF(StringField(line, 10, "|"))
        *p\phaserBanks = Val(StringField(line, 11, "|"))
        *p\torpTubes   = Val(StringField(line, 12, "|"))
        *p\torpMax     = Val(StringField(line, 13, "|"))
        *p\torp        = Val(StringField(line, 14, "|"))
        *p\sensorRange = Val(StringField(line, 15, "|"))
        *p\weaponCapMax= Val(StringField(line, 16, "|"))
        *p\weaponCap   = Val(StringField(line, 17, "|"))
        *p\fuelMax     = Val(StringField(line, 18, "|"))
        *p\fuel        = Val(StringField(line, 19, "|"))
        *p\oreMax      = Val(StringField(line, 20, "|"))
        *p\ore         = Val(StringField(line, 21, "|"))
        *p\dilithiumMax = Val(StringField(line, 22, "|"))
        *p\dilithium   = Val(StringField(line, 23, "|"))
        *p\probesMax   = Val(StringField(line, 24, "|"))
        *p\probes      = Val(StringField(line, 25, "|"))
        *p\allocShields= Val(StringField(line, 26, "|"))
        *p\allocWeapons= Val(StringField(line, 27, "|"))
        *p\allocEngines= Val(StringField(line, 28, "|"))
        *p\sysEngines  = Val(StringField(line, 29, "|"))
        *p\sysWeapons  = Val(StringField(line, 30, "|"))
        *p\sysShields  = Val(StringField(line, 31, "|"))
        *p\sysTractor  = 0
        ; Backward compatibility: ensure dilithium fields exist
        If *p\dilithiumMax <= 0 : *p\dilithiumMax = 20 : EndIf
        If *p\dilithium > *p\dilithiumMax : *p\dilithium = *p\dilithiumMax : EndIf
        ; Backward compatibility: ensure probes exist
        If *p\probesMax <= 0 : *p\probesMax = 5 : EndIf
        If *p\probes > *p\probesMax : *p\probes = *p\probesMax : EndIf
      Case "playerext"
        *p\sysTractor = Val(StringField(line, 2, "|"))
      Case "crew"
        Protected crewIdx.i = Val(StringField(line, 2, "|"))
        Select crewIdx
          Case 0
            *p\crew1\name   = LoadField(StringField(line, 3, "|"))
            *p\crew1\role   = Val(StringField(line, 4, "|"))
            *p\crew1\rank   = Val(StringField(line, 5, "|"))
            *p\crew1\xp     = Val(StringField(line, 6, "|"))
            *p\crew1\level  = Val(StringField(line, 7, "|"))
          Case 1
            *p\crew2\name   = LoadField(StringField(line, 3, "|"))
            *p\crew2\role   = Val(StringField(line, 4, "|"))
            *p\crew2\rank   = Val(StringField(line, 5, "|"))
            *p\crew2\xp     = Val(StringField(line, 6, "|"))
            *p\crew2\level  = Val(StringField(line, 7, "|"))
          Case 2
            *p\crew3\name   = LoadField(StringField(line, 3, "|"))
            *p\crew3\role   = Val(StringField(line, 4, "|"))
            *p\crew3\rank   = Val(StringField(line, 5, "|"))
            *p\crew3\xp     = Val(StringField(line, 6, "|"))
            *p\crew3\level  = Val(StringField(line, 7, "|"))
          Case 3
            *p\crew4\name   = LoadField(StringField(line, 3, "|"))
            *p\crew4\role   = Val(StringField(line, 4, "|"))
            *p\crew4\rank   = Val(StringField(line, 5, "|"))
            *p\crew4\xp     = Val(StringField(line, 6, "|"))
            *p\crew4\level  = Val(StringField(line, 7, "|"))
        EndSelect
      Case "recruits"
        gRecruitCount = Val(StringField(line, 2, "|"))
        If gRecruitCount < 0 Or gRecruitCount > 3
          gRecruitCount = 0
        EndIf
      Case "recruit"
        Protected recIdx.i = Val(StringField(line, 2, "|"))
        If recIdx >= 0 And recIdx < 3
          gRecruitNames(recIdx) = LoadField(StringField(line, 3, "|"))
          gRecruitRoles(recIdx) = LoadField(StringField(line, 4, "|"))
        EndIf
      Case "mission", "missions"
        gMission\active        = Val(StringField(line, 2, "|"))
        gMission\type          = Val(StringField(line, 3, "|"))
        gMission\title         = LoadField(StringField(line, 4, "|"))
        gMission\desc          = LoadField(StringField(line, 5, "|"))
        gMission\oreRequired   = Val(StringField(line, 6, "|"))
        gMission\killsRequired = Val(StringField(line, 7, "|"))
        gMission\killsDone     = Val(StringField(line, 8, "|"))
        gMission\destMapX      = Val(StringField(line, 9, "|"))
        gMission\destMapY      = Val(StringField(line, 10, "|"))
        gMission\destX         = Val(StringField(line, 11, "|"))
        gMission\destY         = Val(StringField(line, 12, "|"))
        gMission\destEntType   = Val(StringField(line, 13, "|"))
        gMission\destName      = LoadField(StringField(line, 14, "|"))
        gMission\rewardCredits = Val(StringField(line, 15, "|"))
        gMission\turnsLeft     = Val(StringField(line, 16, "|"))
        gMission\yardHP        = Val(StringField(line, 17, "|"))
        gMission\threatLevel   = Val(StringField(line, 18, "|"))
      Case "caplog"
        gCaptainLogCount = 0
      Case "capentry"
        If gCaptainLogCount >= 0 And gCaptainLogCount < ArraySize(gCaptainLog())
          gCaptainLog(gCaptainLogCount) = LoadField(StringField(line, 2, "|"))
          gCaptainLogCount = gCaptainLogCount + 1
        EndIf
      Case "cell"
        Protected cx.i = Val(StringField(line, 2, "|"))
        Protected cy.i = Val(StringField(line, 3, "|"))
        Protected sx.i = Val(StringField(line, 4, "|"))
        Protected sy.i = Val(StringField(line, 5, "|"))
        If cx >= 0 And cx < #GALAXY_W And cy >= 0 And cy < #GALAXY_H And sx >= 0 And sx < #MAP_W And sy >= 0 And sy < #MAP_H
          gGalaxy(cx, cy, sx, sy)\entType    = Val(StringField(line, 6, "|"))
          gGalaxy(cx, cy, sx, sy)\richness   = Val(StringField(line, 7, "|"))
          gGalaxy(cx, cy, sx, sy)\enemyLevel = Val(StringField(line, 8, "|"))
          gGalaxy(cx, cy, sx, sy)\name       = LoadField(StringField(line, 9, "|"))
          gGalaxy(cx, cy, sx, sy)\spawned    = Val(StringField(line, 10, "|"))
          gGalaxy(cx, cy, sx, sy)\ore        = Val(StringField(line, 11, "|"))
          gGalaxy(cx, cy, sx, sy)\dilithium  = Val(StringField(line, 12, "|"))
        EndIf
    EndSelect
  Wend

  CloseFile(f)

  ; Safety: clamp and reset transient enemy pointers
  gMapX = ClampInt(gMapX, 0, #GALAXY_W - 1)
  gMapY = ClampInt(gMapY, 0, #GALAXY_H - 1)
  gx    = ClampInt(gx, 0, #MAP_W - 1)
  gy    = ClampInt(gy, 0, #MAP_H - 1)
  *p\hullMax = ClampInt(*p\hullMax, 10, 2000)
  *p\hull = ClampInt(*p\hull, 0, *p\hullMax)
  *p\shieldsMax = ClampInt(*p\shieldsMax, 0, 2000)
  *p\shields = ClampInt(*p\shields, 0, *p\shieldsMax)
  *p\reactorMax = ClampInt(*p\reactorMax, 50, 2000)
  *p\warpMax = ClampF(*p\warpMax, 0.0, 30.0)
  *p\impulseMax = ClampF(*p\impulseMax, 0.0, 5.0)
  *p\phaserBanks = ClampInt(*p\phaserBanks, 0, 50)
  *p\torpMax = ClampInt(*p\torpMax, 0, 200)
  *p\torpTubes = ClampInt(*p\torpTubes, 0, 16)
  If *p\torpMax > 0 And *p\torpTubes > *p\torpMax : *p\torpTubes = *p\torpMax : EndIf
  *p\sensorRange = ClampInt(*p\sensorRange, 1, 120)
  *p\weaponCapMax = ClampInt(*p\weaponCapMax, 10, 4000)
  *p\weaponCap = ClampInt(*p\weaponCap, 0, *p\weaponCapMax)
  *p\fuelMax = ClampInt(*p\fuelMax, 10, 2000)
  *p\fuel = ClampInt(*p\fuel, 0, *p\fuelMax)
  *p\oreMax = ClampInt(*p\oreMax, 0, 1000)
  *p\ore = ClampInt(*p\ore, 0, *p\oreMax)
  *p\dilithiumMax = ClampInt(*p\dilithiumMax, 0, 200)
  *p\dilithium = ClampInt(*p\dilithium, 0, *p\dilithiumMax)
  *p\probesMax = ClampInt(*p\probesMax, 0, 100)
  *p\probes = ClampInt(*p\probes, 0, *p\probesMax)
  gEnemyMapX = -1 : gEnemyMapY = -1 : gEnemyX = -1 : gEnemyY = -1

  ; If loaded into tactical mode, fall back to galaxy (no tactical persistence yet)
  If gMode <> #MODE_GALAXY
    gMode = #MODE_GALAXY
  EndIf
  
  ; Start engine loop if undocked
  If gDocked = 0
    StartEngineLoop()
  EndIf
  
  LogLine("LOAD: loaded " + GetFilePart(fullPath))
  ProcedureReturn 1
EndProcedure

Procedure ListSaveGames()
  Protected path.s = SaveFolderPath()
  
  ; First, check for the legacy save file and offer to rename it if it exists
  Protected legacyPath.s = path + "starcomm_save.txt"
  If FileSize(legacyPath) >= 0
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("!!! Legacy save found: starcomm_save.txt")
    PrintN("    To use this file in the new system, rename it to 'autosave.sav'")
    PrintN("    or type 'LOAD starcomm_save.txt' once.")
    ResetColor()
    PrintN("")
  EndIf

  Protected d.i = ExamineDirectory(#PB_Any, path, "*.*")
  If d
    PrintN("AVAILABLE SAVE FILES:")
    While NextDirectoryEntry(d)
      If DirectoryEntryType(d) = #PB_DirectoryEntry_File
        Protected name.s = DirectoryEntryName(d)
        Protected extension.s = LCase(GetExtensionPart(name))
        
        If extension = "sav"
          name = Left(name, Len(name) - 4) ; remove .sav
          Protected size.i = DirectoryEntrySize(d)
          Protected date.i = DirectoryEntryDate(d, #PB_Date_Modified)
          PrintN("  - " + LSet(name, 20) + " (" + Str(size / 1024) + " KB)  Modified: " + FormatDate("%YYYY-%MM-%DD %HH:%II", date))
        ElseIf extension = "txt" And name = "starcomm_save.txt"
          Protected legacyDate.i = DirectoryEntryDate(d, #PB_Date_Modified)
          PrintN("  - " + LSet(name, 20) + " (LEGACY)             Modified: " + FormatDate("%YYYY-%MM-%DD %HH:%II", legacyDate))
        EndIf

      EndIf
    Wend
    FinishDirectory(d)
  Else
    PrintN("No save files found.")
  EndIf
EndProcedure

Procedure DeleteSaveGame(slotName.s)
  Protected fullPath.s = GetSavePath(slotName)
  If fullPath = ""
    PrintN("Invalid save slot name.")
    ProcedureReturn
  EndIf
  If FileSize(fullPath) >= 0
    If DeleteFile(fullPath)
      LogLine("DELETE: removed " + GetFilePart(fullPath))
      PrintN("Save file '" + slotName + "' deleted.")
    Else
      LogLine("DELETE: failed to remove " + GetFilePart(fullPath))
      PrintN("Failed to delete save file '" + slotName + "'.")
    EndIf
  Else
    PrintN("Save file '" + slotName + "' not found.")
  EndIf
EndProcedure

Procedure.i SaveGameManager(*p.Ship)
  Protected cmd.s, slot.s
  Protected gameLoaded.i = #False
  Repeat
    ClearConsole()
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    PrintN("=== STARCOMM SAVE MANAGER ===")
    ConsoleColor(#C_WHITE, #C_BLACK)
    PrintN("")
    ListSaveGames()
    PrintN("")
    ConsoleColor(#C_YELLOW, #C_BLACK)
    PrintN("COMMANDS:")
    ConsoleColor(#C_WHITE, #C_BLACK)
    PrintN("  SAVE <name>    - Save current session to slot")
    PrintN("  LOAD <name>    - Restore session from slot")
    PrintN("  DELETE <name>  - Permanently remove save file")
    PrintN("  RENAME <a b>   - Rename slot 'a' to 'b'")
    PrintN("  BACK           - Return to menu")
    PrintN("")
    ConsoleColor(#C_LIGHTCYAN, #C_BLACK)
    Print("SAVES> ")
    ResetColor()
    Protected line.s = Input()
    line = Trim(line)
    If line = "" : Continue : EndIf
    cmd = TrimLower(StringField(line, 1, " "))
    slot = Trim(StringField(line, 2, " "))
    Protected slot2.s = Trim(StringField(line, 3, " "))
    
    If cmd = "save"
      If slot <> ""
        SaveGame(*p, slot)
      Else
        PrintN("Usage: SAVE <name>")
      EndIf
      PrintN("< Press ENTER >") : Input()
    ElseIf cmd = "load"
      If slot <> ""
        If LoadGame(*p, slot)
          PrintN("Game loaded successfully.")
          gameLoaded = #True
          Break
        EndIf
      Else
        PrintN("Usage: LOAD <name>")
      EndIf
      PrintN("< Press ENTER >") : Input()
    ElseIf cmd = "delete"
      If slot <> ""
        DeleteSaveGame(slot)
      Else
        PrintN("Usage: DELETE <name>")
      EndIf
      PrintN("< Press ENTER >") : Input()
    ElseIf cmd = "rename"
      If slot <> "" And slot2 <> ""
        Protected oldPath.s = GetSavePath(slot)
        Protected newPath.s = GetSavePath(slot2)
        If oldPath = "" Or newPath = ""
          PrintN("Invalid save slot name.")
          PrintN("< Press ENTER >") : Input()
          Continue
        EndIf
        If FileSize(oldPath) < 0
          oldPath = GetLegacySavePath(slot)
        EndIf
        
        If FileSize(oldPath) >= 0
          If RenameFile(oldPath, newPath)
            PrintN("Renamed '" + slot + "' to '" + slot2 + "'.")
          Else
            PrintN("Failed to rename file.")
          EndIf
        Else
          PrintN("Source file '" + slot + "' not found.")
        EndIf
      Else
        PrintN("Usage: RENAME <old> <new>")
      EndIf
      PrintN("< Press ENTER >") : Input()
    ElseIf cmd = "back"
      Break
    EndIf
  Until cmd = "back"
  
  ; Ensure galaxy is updated if we loaded a game
  If gameLoaded
    RedrawGalaxy(*p)
  EndIf
  
  ProcedureReturn gameLoaded
EndProcedure
