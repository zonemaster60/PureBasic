; starcomm_shipdata.pbi
; Ship data loading: LoadShipDataFromDat, IniGet*, LoadAllocOverrides, InitShipData, DefaultShipsIniText, PackShipsDatFromIni
; XIncluded from starcomm.pb

Procedure.i LoadShipDataFromDat(path.s)
  gShipDatErr = ""
  Protected f.i = ReadFile(#PB_Any, path)
  If f = 0
    gShipDatErr = "open failed!"
    ProcedureReturn 0
  EndIf
  Protected len.i = Lof(f)
  If len < 8 + 12
    CloseFile(f)
    gShipDatErr = "file too short!"
    ProcedureReturn 0
  EndIf

  Protected *m = AllocateMemory(len)
  If *m = 0
    CloseFile(f)
    gShipDatErr = "alloc failed!"
    ProcedureReturn 0
  EndIf
  ReadData(f, *m, len)
  CloseFile(f)

  Protected magic.s = PeekS(*m, 8, #PB_Ascii)
  If magic <> "SSIMDAT1"
    FreeMemory(*m)
    gShipDatErr = "bad magic!"
    ProcedureReturn 0
  EndIf

  ; PeekL() returns signed 32-bit. On x64 builds, assigning that to .i
  ; sign-extends values with the high bit set (>= $80000000). Mask to 32-bit
  ; so comparisons use the same bit pattern as the written unsigned value.
  Protected seed.i = PeekL(*m + 8) & $FFFFFFFF
  Protected plainLen.i = PeekL(*m + 12) & $FFFFFFFF
  Protected want.i = PeekL(*m + 16) & $FFFFFFFF
  Protected payloadOffset.i = 20

  If plainLen <= 0 Or payloadOffset + plainLen > len
    FreeMemory(*m)
    gShipDatErr = "bad length!"
    ProcedureReturn 0
  EndIf

  Protected *p = *m + payloadOffset
  XorScramble(*p, plainLen, seed)
  Protected got.i = ChecksumFNV32(*p, plainLen) & $FFFFFFFF
  If got <> want
    FreeMemory(*m)
    gShipDatErr = "checksum mismatch!"
    ProcedureReturn 0
  EndIf

  gShipsText = PeekS(*p, plainLen, #PB_UTF8)
  FreeMemory(*m)
  ProcedureReturn Bool(gShipsText <> "")
EndProcedure

Procedure.s IniGet(section.s, key.s, defaultValue.s)
  Protected text.s = gShipsText
  If text = "" : ProcedureReturn defaultValue : EndIf

  text = ReplaceString(text, Chr(13), "")
  Protected n.i = CountString(text, Chr(10)) + 1
  Protected i.i, line.s, curSec.s, pos.i, k.s, v.s
  For i = 1 To n
    line = Trim(StringField(text, i, Chr(10)))
    If line = "" : Continue : EndIf
    If Left(line, 1) = ";" Or Left(line, 1) = "#" : Continue : EndIf

    If Left(line, 1) = "[" And Right(line, 1) = "]"
      curSec = Trim(Mid(line, 2, Len(line) - 2))
      Continue
    EndIf

    If LCase(curSec) <> LCase(section) : Continue : EndIf
    pos = FindString(line, "=", 1)
    If pos <= 0 : Continue : EndIf
    k = Trim(Left(line, pos - 1))
    If LCase(k) <> LCase(key) : Continue : EndIf
    v = Trim(Mid(line, pos + 1))
    ProcedureReturn v
  Next
  ProcedureReturn defaultValue
EndProcedure

Procedure.i IniGetLong(section.s, key.s, defaultValue.i)
  Protected t.s = IniGet(section, key, "")
  If t = "" : ProcedureReturn defaultValue : EndIf
  ProcedureReturn Val(t)
EndProcedure

Procedure.f IniGetFloat(section.s, key.s, defaultValue.f)
  Protected t.s = IniGet(section, key, "")
  If t = "" : ProcedureReturn defaultValue : EndIf
  ProcedureReturn ValF(t)
EndProcedure

Procedure LoadAllocOverrides(section.s, *s.Ship)
  If OpenPreferences(gUserIniPath) = 0
    ProcedureReturn
  EndIf
  PreferenceGroup(section)
  *s\allocShields = ReadPreferenceLong("AllocShields", *s\allocShields)
  *s\allocWeapons = ReadPreferenceLong("AllocWeapons", *s\allocWeapons)
  *s\allocEngines = ReadPreferenceLong("AllocEngines", *s\allocEngines)
  ClosePreferences()
EndProcedure

Procedure.i InitShipData()
  ; Prefer scrambled ships.dat; if missing, fall back to ships.ini.
  gShipsText = ""
  gShipDataDesc = "(embedded defaults)"

  If FileSize(gDatPath) > 0
    If LoadShipDataFromDat(gDatPath)
      gShipDataDesc = gDatPath
      LogLine("SHIPDATA: loaded " + GetFilePart(gDatPath))
      ProcedureReturn 1
    Else
      LogLine("SHIPDATA: invalid " + GetFilePart(gDatPath) + " (" + gShipDatErr + ") - trying " + GetFilePart(gIniPath))
    EndIf
  EndIf

  If FileSize(gIniPath) > 0
    gShipsText = ReadAllText(gIniPath)
    If gShipsText <> ""
      gShipDataDesc = gIniPath
      LogLine("SHIPDATA: loaded " + GetFilePart(gIniPath))
      ProcedureReturn 1
    EndIf
  EndIf

  LogLine("SHIPDATA: no ships data found - using defaults")
  DefaultShipsIniText()
  gShipDataDesc = "defaults"
  ProcedureReturn 1
EndProcedure

Procedure DefaultShipsIniText()
  ; Minimal built-in defaults so the game runs even without ships.dat/ships.ini.
  gShipsText = "[Game]" + Chr(10)
  gShipsText + "PlayerSection=PlayerShip" + Chr(10)
  gShipsText + "EnemySection=EnemyShip" + Chr(10)
  gShipsText + Chr(10)
  gShipsText + "[PlayerShip]" + Chr(10)
  gShipsText + "Name=Player" + Chr(10)
  gShipsText + "Class=Frigate" + Chr(10)
  gShipsText + "HullMax=120" + Chr(10)
  gShipsText + "ShieldsMax=120" + Chr(10)
  gShipsText + "ReactorMax=240" + Chr(10)
  gShipsText + "WarpMax=9.0" + Chr(10)
  gShipsText + "ImpulseMax=1.0" + Chr(10)
  gShipsText + "PhaserBanks=8" + Chr(10)
  gShipsText + "TorpedoTubes=2" + Chr(10)
  gShipsText + "TorpedoesMax=12" + Chr(10)
  gShipsText + "SensorRange=20" + Chr(10)
  gShipsText + "WeaponCapMax=240" + Chr(10)
  gShipsText + "FuelMax=120" + Chr(10)
  gShipsText + "OreMax=60" + Chr(10)
  gShipsText + "DilithiumMax=20" + Chr(10)
  gShipsText + "AllocShields=33" + Chr(10)
  gShipsText + "AllocWeapons=34" + Chr(10)
  gShipsText + "AllocEngines=33" + Chr(10)
  gShipsText + Chr(10)
  gShipsText + "[EnemyShip]" + Chr(10)
  gShipsText + "Name=Raider" + Chr(10)
  gShipsText + "Class=Raider" + Chr(10)
  gShipsText + "HullMax=100" + Chr(10)
  gShipsText + "ShieldsMax=90" + Chr(10)
  gShipsText + "ReactorMax=210" + Chr(10)
  gShipsText + "WarpMax=8.0" + Chr(10)
  gShipsText + "ImpulseMax=1.0" + Chr(10)
  gShipsText + "PhaserBanks=6" + Chr(10)
  gShipsText + "TorpedoTubes=2" + Chr(10)
  gShipsText + "TorpedoesMax=8" + Chr(10)
  gShipsText + "SensorRange=18" + Chr(10)
  gShipsText + "WeaponCapMax=210" + Chr(10)
  gShipsText + "FuelMax=100" + Chr(10)
  gShipsText + "OreMax=0" + Chr(10)
  gShipsText + "AllocShields=33" + Chr(10)
  gShipsText + "AllocWeapons=34" + Chr(10)
  gShipsText + "AllocEngines=33" + Chr(10)
EndProcedure

Procedure.i PackShipsDatFromIni()
  Protected text.s = ReadAllText(gIniPath)
  If text = "" : ProcedureReturn 0 : EndIf

  Protected plainLen.i = StringByteLength(text, #PB_UTF8)
  If plainLen <= 0 : ProcedureReturn 0 : EndIf

  ; StringByteLength() excludes NUL; PokeS(...,-1,UTF8) writes a terminator.
  ; Allocate one extra byte to avoid heap overrun/corruption.
  Protected *p = AllocateMemory(plainLen + 1)
  If *p = 0 : ProcedureReturn 0 : EndIf
  PokeS(*p, text, -1, #PB_UTF8)
  PokeB(*p + plainLen, 0)

  Protected fnv.i = ChecksumFNV32(*p, plainLen)
  Protected seed.i = (Date() & $7FFFFFFF) ! $13579BDF
  XorScramble(*p, plainLen, seed)

  Protected f.i = CreateFile(#PB_Any, gDatPath)
  If f = 0
    FreeMemory(*p)
    ProcedureReturn 0
  EndIf
  WriteString(f, "SSIMDAT1", #PB_Ascii)
  WriteLong(f, seed)
  WriteLong(f, plainLen)
  WriteLong(f, fnv)
  WriteData(f, *p, plainLen)
  CloseFile(f)
  FreeMemory(*p)
  ProcedureReturn 1
EndProcedure
