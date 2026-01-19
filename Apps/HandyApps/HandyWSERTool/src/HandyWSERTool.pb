EnableExplicit

#APP_NAME   = "HandyWSERTool"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.4"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

; Prevent multiple instances (don't rely on window title text)
Global hMutex.i
hMutex = CreateMutex_(0, 1, #APP_NAME + "_mutex")
If hMutex And GetLastError_() = 183 ; ERROR_ALREADY_EXISTS
  MessageRequester("Info", #APP_NAME + " is already running.", #PB_MessageRequester_Info)
  CloseHandle_(hMutex)
  End
EndIf

; ============================================================
;  MODULE: EnvSys
; ============================================================

Procedure Exit()
  Define Req = MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure
        
DeclareModule EnvSys
  #HKLM     = $80000002
  #HKCU     = $80000001

  #ENV_PATH_SYS  = "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
  #ENV_PATH_USER = "Environment"


  Structure VarEntry
    Name.s
    Value.s
    Type.l
  EndStructure

  Enumeration 1
    #ScopeSystem
    #ScopeUser
  EndEnumeration

  Declare.i OpenEnvKey(access.l, *hKey.Integer, scope.i = #ScopeSystem)
  Declare.s ReadVar(name.s, scope.i = #ScopeSystem)
  Declare.i WriteVar(name.s, value.s, type.l, scope.i = #ScopeSystem)
  Declare.i DeleteVar(name.s, scope.i = #ScopeSystem)

  Declare.i LoadAll(List vars.VarEntry(), scope.i = #ScopeSystem)
  Declare.i ApplyAll(List vars.VarEntry(), overwrite.i = #True, strict.i = #False, scope.i = #ScopeSystem)

  Declare.i ExportToFile(filePath.s, scope.i = #ScopeSystem)
  Declare.i Backup(filePath.s, scope.i = #ScopeSystem)
  Declare.i BackupBoth(filePath.s)

  Declare.i ImportFromFile(filePath.s, overwrite.i = #True, scope.i = #ScopeSystem)
  Declare.i ImportBoth(filePath.s, overwrite.i = #True, defaultScope.i = #ScopeSystem)

  Declare.i RestoreExact(filePath.s, strict.i = #True, scope.i = #ScopeSystem)
EndDeclareModule

Module EnvSys

  Procedure.i OpenEnvKey(access.l, *hKey.Integer, scope.i = #ScopeSystem)
    Protected rootKey.i, subKey.s

    If scope = #ScopeUser
      rootKey = #HKCU
      subKey  = #ENV_PATH_USER
    Else
      rootKey = #HKLM
      subKey  = #ENV_PATH_SYS
    EndIf

    If RegOpenKeyEx_(rootKey, subKey, 0, access, *hKey)
      ProcedureReturn #False
    EndIf
    ProcedureReturn #True
  EndProcedure

  Procedure.s ReadVar(name.s, scope.i = #ScopeSystem)
    Protected hKey.i, valueType.l, dataBytes.l, result.l
    Protected buffer.s

    If OpenEnvKey(#KEY_READ, @hKey, scope) = #False
      ProcedureReturn ""
    EndIf

    ; Query required size first (handles long values like PATH)
    result = RegQueryValueEx_(hKey, name, 0, @valueType, 0, @dataBytes)
    If result <> #ERROR_SUCCESS Or dataBytes <= SizeOf(Character)
      RegCloseKey_(hKey)
      ProcedureReturn ""
    EndIf

    Protected bufferChars.l = dataBytes / SizeOf(Character)
    buffer = Space(bufferChars)

    result = RegQueryValueEx_(hKey, name, 0, @valueType, @buffer, @dataBytes)
    RegCloseKey_(hKey)

    If result <> #ERROR_SUCCESS Or dataBytes <= 0
      ProcedureReturn ""
    EndIf

    Protected charsUsed.l = dataBytes / SizeOf(Character)
    If charsUsed > 0
      charsUsed - 1 ; drop trailing null
    EndIf
    If charsUsed < 0
      charsUsed = 0
    EndIf

    ProcedureReturn Left(buffer, charsUsed)
  EndProcedure

  Procedure.i WriteVar(name.s, value.s, type.l, scope.i = #ScopeSystem)
    Protected hKey.i
    Protected *buf = @value

    Protected size.l = StringByteLength(value) + SizeOf(Character)

    If OpenEnvKey(#KEY_WRITE, @hKey, scope) = #False
      ProcedureReturn #False
    EndIf

    If RegSetValueEx_(hKey, name, 0, type, *buf, size) <> #ERROR_SUCCESS
      RegCloseKey_(hKey)
      ProcedureReturn #False
    EndIf

    RegCloseKey_(hKey)
    ProcedureReturn #True
  EndProcedure

  Procedure.i DeleteVar(name.s, scope.i = #ScopeSystem)
    Protected hKey.i

    If OpenEnvKey(#KEY_WRITE, @hKey, scope) = #False
      ProcedureReturn #False
    EndIf

    RegDeleteValue_(hKey, name)
    RegCloseKey_(hKey)
    ProcedureReturn #True
  EndProcedure

  Procedure.i LoadAll(List vars.VarEntry(), scope.i = #ScopeSystem)
    Protected hKey.i, index.l = 0
    Protected nameBuf.s, valueBuf.s
    Protected sizeName.l, dataBytes.l, type.l
    Protected valueChars.l, charsUsed.l, result.l

    ClearList(vars())

    If OpenEnvKey(#KEY_READ, @hKey, scope) = #False
      ProcedureReturn #False
    EndIf

    While #True
      sizeName   = 512 ; chars (in/out)
      valueChars = 4096
      dataBytes  = valueChars * SizeOf(Character) ; bytes (in/out)
      nameBuf    = Space(sizeName)
      valueBuf   = Space(valueChars)

      result = RegEnumValue_(hKey, index, @nameBuf, @sizeName, 0, @type, @valueBuf, @dataBytes)

      ; Grow buffers if needed (e.g. long Path)
      If result = #ERROR_MORE_DATA
        If sizeName < 1 : sizeName = 512 : EndIf
        valueChars = dataBytes / SizeOf(Character)
        If valueChars < 1 : valueChars = 4096 : EndIf

        nameBuf  = Space(sizeName)
        valueBuf = Space(valueChars)
        result = RegEnumValue_(hKey, index, @nameBuf, @sizeName, 0, @type, @valueBuf, @dataBytes)
      EndIf

      If result <> #ERROR_SUCCESS
        Break
      EndIf

      charsUsed = dataBytes / SizeOf(Character)
      If charsUsed > 0
        charsUsed - 1 ; drop trailing null
      EndIf
      If charsUsed < 0
        charsUsed = 0
      EndIf

      AddElement(vars())
      vars()\Name  = Left(nameBuf, sizeName)
      vars()\Value = Left(valueBuf, charsUsed)
      vars()\Type  = type

      index + 1
    Wend

    RegCloseKey_(hKey)
    ProcedureReturn #True
  EndProcedure

  Procedure.i ApplyAll(List vars.VarEntry(), overwrite.i = #True, strict.i = #False, scope.i = #ScopeSystem)

    Protected hKey.i

    If OpenEnvKey(#KEY_READ | #KEY_WRITE, @hKey, scope) = #False
      ProcedureReturn #False
    EndIf

    If strict
      Protected existing.s, sizeName.l, index.l = 0, found.i
      Protected nameBuf.s

      While #True
        Protected result.l

        sizeName = 512
        nameBuf  = Space(sizeName)

        result = RegEnumValue_(hKey, index, @nameBuf, @sizeName, 0, 0, 0, 0)
        If result = #ERROR_MORE_DATA
          nameBuf = Space(sizeName)
          result = RegEnumValue_(hKey, index, @nameBuf, @sizeName, 0, 0, 0, 0)
        EndIf

        If result <> #ERROR_SUCCESS
          Break
        EndIf

        existing = Left(nameBuf, sizeName)
        found = #False


        ForEach vars()
          If LCase(vars()\Name) = LCase(existing)
            found = #True
            Break
          EndIf
        Next

        If found = #False
          RegDeleteValue_(hKey, existing)
        Else
          index + 1
        EndIf
      Wend
    EndIf

    ForEach vars()
      If overwrite Or ReadVar(vars()\Name, scope) = ""
        RegSetValueEx_(hKey, vars()\Name, 0, vars()\Type, @vars()\Value, StringByteLength(vars()\Value) + SizeOf(Character))
      EndIf
    Next

    RegCloseKey_(hKey)
    ProcedureReturn #True
  EndProcedure

  Procedure.i ExportToFile(filePath.s, scope.i = #ScopeSystem)
    Protected NewList vars.VarEntry()

    If LoadAll(vars(), scope) = #False
      ProcedureReturn #False
    EndIf

    If CreateFile(0, filePath) = 0
      ProcedureReturn #False
    EndIf

    ForEach vars()
      WriteStringN(0, vars()\Name + "=" + vars()\Value)
    Next

    CloseFile(0)
    ProcedureReturn #True
  EndProcedure

  Procedure.i Backup(filePath.s, scope.i = #ScopeSystem)
    Protected NewList vars.VarEntry()
    Protected machine.s = GetEnvironmentVariable("COMPUTERNAME")

    If LoadAll(vars(), scope) = #False
      ProcedureReturn #False
    EndIf

    If CreateFile(0, filePath) = 0
      ProcedureReturn #False
    EndIf

    If scope = #ScopeUser
      WriteStringN(0, "; Windows User Environment Repair - Backup")
    Else
      WriteStringN(0, "; Windows System Environment Repair - Backup")
    EndIf
    WriteStringN(0, "; Generated: " + FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()))
    WriteStringN(0, "; Machine: " + machine)
    WriteStringN(0, "; ---------------------------------------------")
    WriteStringN(0, "")

    ForEach vars()
      WriteStringN(0, vars()\Name + "=" + vars()\Value)
    Next

    CloseFile(0)
    ProcedureReturn #True
  EndProcedure

  Procedure.i ImportFromFile(filePath.s, overwrite.i = #True, scope.i = #ScopeSystem)
 
    Protected line.s, pos.l
    Protected NewList vars.VarEntry()
 
    If ReadFile(0, filePath) = 0
      ProcedureReturn #False
    EndIf
  
    While Eof(0) = 0
      line = Trim(ReadString(0))
  
      If line = "" : Continue : EndIf
      If Left(line, 1) = ";" Or Left(line, 1) = "#" : Continue : EndIf
  
      pos = FindString(line, "=", 1)
      If pos > 0
        AddElement(vars())
        vars()\Name  = Trim(Left(line, pos - 1))
        vars()\Value = Trim(Mid(line, pos + 1))
        vars()\Type  = #REG_EXPAND_SZ
      Else
        ; Continuation line support for long values (commonly PATH)
        ; If a line doesn't contain '=', append it to the previous variable.
        If LastElement(vars())
          If vars()\Value <> "" And Right(vars()\Value, 1) <> ";" And Left(line, 1) <> ";"
            vars()\Value + ";"
          EndIf
          vars()\Value + line
        EndIf
      EndIf
    Wend
  
    CloseFile(0)
  
    ProcedureReturn ApplyAll(vars(), overwrite, #False, scope)
  EndProcedure

  Procedure.i BackupBoth(filePath.s)
    Protected NewList vars.VarEntry()
    Protected machine.s = GetEnvironmentVariable("COMPUTERNAME")

    If CreateFile(0, filePath) = 0
      ProcedureReturn #False
    EndIf

    WriteStringN(0, "; HandyWSERTool Environment Backup")
    WriteStringN(0, "; Generated: " + FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()))
    WriteStringN(0, "; Machine: " + machine)
    WriteStringN(0, "; Format: [System] and [User] sections")
    WriteStringN(0, "")

    WriteStringN(0, "[System]")
    If LoadAll(vars(), #ScopeSystem)
      ForEach vars()
        WriteStringN(0, vars()\Name + "=" + vars()\Value)
      Next
    EndIf

    WriteStringN(0, "")
    WriteStringN(0, "[User]")
    If LoadAll(vars(), #ScopeUser)
      ForEach vars()
        WriteStringN(0, vars()\Name + "=" + vars()\Value)
      Next
    EndIf

    CloseFile(0)
    ProcedureReturn #True
  EndProcedure

  Procedure.i ImportBoth(filePath.s, overwrite.i = #True, defaultScope.i = #ScopeSystem)
    Protected line.s, pos.l
    Protected currentScope.i = defaultScope
    Protected NewList sysVars.VarEntry()
    Protected NewList userVars.VarEntry()

    If ReadFile(0, filePath) = 0
      ProcedureReturn #False
    EndIf

    While Eof(0) = 0
      line = Trim(ReadString(0))

      If line = "" : Continue : EndIf
      If Left(line, 1) = ";" Or Left(line, 1) = "#" : Continue : EndIf

      If LCase(line) = "[system]"
        currentScope = #ScopeSystem
        Continue
      ElseIf LCase(line) = "[user]"
        currentScope = #ScopeUser
        Continue
      EndIf

      pos = FindString(line, "=", 1)
      If pos > 0
        If currentScope = #ScopeUser
          AddElement(userVars())
          userVars()\Name  = Trim(Left(line, pos - 1))
          userVars()\Value = Trim(Mid(line, pos + 1))
          userVars()\Type  = #REG_EXPAND_SZ
        Else
          AddElement(sysVars())
          sysVars()\Name  = Trim(Left(line, pos - 1))
          sysVars()\Value = Trim(Mid(line, pos + 1))
          sysVars()\Type  = #REG_EXPAND_SZ
        EndIf
      Else
        ; Continuation support: append to last var in current section.
        If currentScope = #ScopeUser
          If LastElement(userVars())
            If userVars()\Value <> "" And Right(userVars()\Value, 1) <> ";" And Left(line, 1) <> ";"
              userVars()\Value + ";"
            EndIf
            userVars()\Value + line
          EndIf
        Else
          If LastElement(sysVars())
            If sysVars()\Value <> "" And Right(sysVars()\Value, 1) <> ";" And Left(line, 1) <> ";"
              sysVars()\Value + ";"
            EndIf
            sysVars()\Value + line
          EndIf
        EndIf
      EndIf
    Wend

    CloseFile(0)

    Protected okSys.i = #True
    Protected okUser.i = #True

    If ListSize(sysVars()) > 0
      okSys = ApplyAll(sysVars(), overwrite, #False, #ScopeSystem)
    EndIf
    If ListSize(userVars()) > 0
      okUser = ApplyAll(userVars(), overwrite, #False, #ScopeUser)
    EndIf

    ProcedureReturn Bool(okSys And okUser)
  EndProcedure

  Procedure.i RestoreExact(filePath.s, strict.i = #True, scope.i = #ScopeSystem)
 
    Protected NewList vars.VarEntry()
    Protected line.s, pos.l
 
    If ReadFile(0, filePath) = 0
      ProcedureReturn #False
    EndIf
 
    While Eof(0) = 0
      line = Trim(ReadString(0))
 
      If line = "" : Continue : EndIf
      If Left(line, 1) = ";" Or Left(line, 1) = "#" : Continue : EndIf
 
      pos = FindString(line, "=", 1)
      If pos > 0
        AddElement(vars())
        vars()\Name  = Trim(Left(line, pos - 1))
        vars()\Value = Trim(Mid(line, pos + 1))
        vars()\Type  = #REG_EXPAND_SZ
      Else
        ; Continuation line support for long values (commonly PATH)
        ; If a line doesn't contain '=', append it to the previous variable.
        If LastElement(vars())
          If vars()\Value <> "" And Right(vars()\Value, 1) <> ";" And Left(line, 1) <> ";"
            vars()\Value + ";"
          EndIf
          vars()\Value + line
        EndIf
      EndIf
    Wend
 
    CloseFile(0)
 
    ProcedureReturn ApplyAll(vars(), #True, strict, scope)
  EndProcedure

EndModule

UseModule EnvSys

; ============================================================
;  DEFAULTS FOR REPAIR
; ============================================================

Structure EnvDefault
  name.s
  value.s
  typ.l
EndStructure

Global NewList DefaultVars.EnvDefault()

Procedure AddDefault(name.s, value.s, typ.l)
  AddElement(DefaultVars())
  DefaultVars()\name  = name
  DefaultVars()\value = value
  DefaultVars()\typ   = typ
EndProcedure

; Core Windows 11 system defaults
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

Global DefaultSystemPath.s = "C:\Windows\system32;" +
                          "C:\Windows;" +
                          "C:\Windows\System32\Wbem;" +
                          "C:\Windows\System32\WindowsPowerShell\v1.0\;" +
                          "C:\Windows\System32\OpenSSH\"

; ============================================================
;  GUI
; ============================================================

#Win       = 0
#Log       = 1
#BtnScan   = 2
#BtnRepair = 3
#BtnExport = 4
#BtnImport = 5
#BtnAbout  = 6
#BtnExit   = 7

OpenWindow(#Win, 200, 200, 800, 550, #APP_NAME + " - " + version, #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
EditorGadget(#Log, 10, 10, 780, 460, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
ButtonGadget(#BtnScan,   10, 480, 120, 40, "Scan")
ButtonGadget(#BtnRepair, 140, 480, 120, 40, "Repair")
ButtonGadget(#BtnExport, 270, 480, 120, 40, "Export")
ButtonGadget(#BtnImport, 400, 480, 120, 40, "Import")
ButtonGadget(#BtnAbout, 530, 480, 120, 40, "About")
ButtonGadget(#BtnExit, 660, 480, 120, 40, "Exit")

Procedure AppendLog(msg.s)
  AddGadgetItem(#Log, -1, msg)
  SendMessage_(GadgetID(#Log), #EM_LINESCROLL, 0, 65535)
EndProcedure

; ============================================================
;  SCAN
; ============================================================

Procedure ScanEnvironment()
  ClearGadgetItems(#Log)

  Protected current.s

  ; ---- System ----
  AppendLog("Scanning System environment variables...")
  AppendLog("")

  ForEach DefaultVars()
    current = EnvSys::ReadVar(DefaultVars()\name, EnvSys::#ScopeSystem)

    If current = ""
      AppendLog("[MISSING] " + DefaultVars()\name)
    ElseIf CompareMemoryString(@current, @DefaultVars()\value, #PB_String_NoCase) <> 0
      AppendLog("[DIFFERS] " + DefaultVars()\name + " = " + current)
    Else
      AppendLog("[OK] " + DefaultVars()\name)
    EndIf
  Next

  current = EnvSys::ReadVar("Path", EnvSys::#ScopeSystem)
  If current = ""
    AppendLog("[MISSING] Path")
  Else
    AppendLog("[CHECK] Path exists:")
    AppendLog("        " + current)
  EndIf

  ; ---- User ----
  AppendLog("")
  AppendLog("Scanning User environment variables...")
  AppendLog("")

  current = EnvSys::ReadVar("TEMP", EnvSys::#ScopeUser)
  If current = "" : AppendLog("[MISSING] TEMP") : Else : AppendLog("[OK] TEMP") : EndIf

  current = EnvSys::ReadVar("TMP", EnvSys::#ScopeUser)
  If current = "" : AppendLog("[MISSING] TMP") : Else : AppendLog("[OK] TMP") : EndIf

  current = EnvSys::ReadVar("USERPROFILE", EnvSys::#ScopeUser)
  If current = "" : AppendLog("[MISSING] USERPROFILE") : Else : AppendLog("[OK] USERPROFILE") : EndIf

  current = EnvSys::ReadVar("HOMEDRIVE", EnvSys::#ScopeUser)
  If current = "" : AppendLog("[MISSING] HOMEDRIVE") : Else : AppendLog("[OK] HOMEDRIVE") : EndIf

  current = EnvSys::ReadVar("HOMEPATH", EnvSys::#ScopeUser)
  If current = "" : AppendLog("[MISSING] HOMEPATH") : Else : AppendLog("[OK] HOMEPATH") : EndIf

  current = EnvSys::ReadVar("APPDATA", EnvSys::#ScopeUser)
  If current = "" : AppendLog("[MISSING] APPDATA") : Else : AppendLog("[OK] APPDATA") : EndIf

  current = EnvSys::ReadVar("LOCALAPPDATA", EnvSys::#ScopeUser)
  If current = "" : AppendLog("[MISSING] LOCALAPPDATA") : Else : AppendLog("[OK] LOCALAPPDATA") : EndIf

  current = EnvSys::ReadVar("OneDrive", EnvSys::#ScopeUser)
  If current = "" : AppendLog("[MISSING] OneDrive") : Else : AppendLog("[OK] OneDrive") : EndIf

  current = EnvSys::ReadVar("OneDriveConsumer", EnvSys::#ScopeUser)
  If current <> ""
    AppendLog("[OK] OneDriveConsumer")
  Else
    ; Optional: many machines won't have this.
    AppendLog("[INFO] OneDriveConsumer not set")
  EndIf

  current = EnvSys::ReadVar("Path", EnvSys::#ScopeUser)
  If current = ""
    AppendLog("[MISSING] Path")
  Else
    AppendLog("[CHECK] Path exists:")
    AppendLog("        " + current)
  EndIf

  AppendLog("")
  AppendLog("Scan complete.")
EndProcedure

; ============================================================
;  REPAIR
; ============================================================

Procedure RepairEnvironment()
  ClearGadgetItems(#Log)
  AppendLog("Starting repair...")
  AppendLog("Creating backup of System environment first...")

  Protected backupFile.s = GetTemporaryDirectory() + "system_env_backup_" + Str(Date()) + ".txt"

  If EnvSys::Backup(backupFile, EnvSys::#ScopeSystem)
    AppendLog("Backup saved to: " + backupFile)
  Else
    AppendLog("Backup FAILED (no changes made).")
    ProcedureReturn
  EndIf

  AppendLog("")
  AppendLog("Restoring core defaults...")

  ForEach DefaultVars()
    If EnvSys::WriteVar(DefaultVars()\name, DefaultVars()\value, DefaultVars()\typ, EnvSys::#ScopeSystem)
      AppendLog("[RESTORED] " + DefaultVars()\name + " = " + DefaultVars()\value)
    Else
      AppendLog("[FAILED] " + DefaultVars()\name)
    EndIf
  Next

  If EnvSys::WriteVar("Path", DefaultSystemPath, #REG_EXPAND_SZ, EnvSys::#ScopeSystem)
    AppendLog("[RESTORED] Path")
    AppendLog("           " + DefaultSystemPath)
  Else
    AppendLog("[FAILED] Path")
  EndIf

  AppendLog("")
  AppendLog("Repair complete. Log off or reboot is required for changes to fully apply.")
EndProcedure

; ============================================================
;  EXPORT / IMPORT HANDLERS
; ============================================================

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
    file = SaveFileRequester("Export " + scopeLabel + " environment to...", scopeLabel + "_env_backup.txt", "Text|*.txt", 0)
    If file = "" : ProcedureReturn : EndIf

    If EnvSys::Backup(file, scope)
      AppendLog("Export saved to: " + file)
    Else
      AppendLog("Export FAILED: " + file)
    EndIf

  ElseIf choice = #PB_MessageRequester_No
    scope = EnvSys::#ScopeUser
    scopeLabel = "user"
    file = SaveFileRequester("Export " + scopeLabel + " environment to...", scopeLabel + "_env_backup.txt", "Text|*.txt", 0)
    If file = "" : ProcedureReturn : EndIf

    If EnvSys::Backup(file, scope)
      AppendLog("Export saved to: " + file)
    Else
      AppendLog("Export FAILED: " + file)
    EndIf

  Else
    file = SaveFileRequester("Export both environments to...", "env_backup_both.txt", "Text|*.txt", 0)
    If file = "" : ProcedureReturn : EndIf

    If EnvSys::BackupBoth(file)
      AppendLog("Export saved to: " + file)
    Else
      AppendLog("Export FAILED: " + file)
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
    file = OpenFileRequester("Import " + scopeLabel + " environment from...", "", "Text|*.txt", 0)
    If file = "" : ProcedureReturn : EndIf

    AppendLog("Importing " + scopeLabel + " environment from: " + file)
    AppendLog("")

    If EnvSys::ImportFromFile(file, #True, scope)
      AppendLog("Import OK. Log off or reboot is required for changes to fully apply.")
    Else
      AppendLog("Import FAILED.")
    EndIf

  ElseIf choice = #PB_MessageRequester_No
    scope = EnvSys::#ScopeUser
    scopeLabel = "user"
    file = OpenFileRequester("Import " + scopeLabel + " environment from...", "", "Text|*.txt", 0)
    If file = "" : ProcedureReturn : EndIf

    AppendLog("Importing " + scopeLabel + " environment from: " + file)
    AppendLog("")

    If EnvSys::ImportFromFile(file, #True, scope)
      AppendLog("Import OK. Log off or reboot is required for changes to fully apply.")
    Else
      AppendLog("Import FAILED.")
    EndIf

  Else
    file = OpenFileRequester("Import both environments from...", "", "Text|*.txt", 0)
    If file = "" : ProcedureReturn : EndIf

    AppendLog("Importing both environments from: " + file)
    AppendLog("")

    If EnvSys::ImportBoth(file, #True, EnvSys::#ScopeSystem)
      AppendLog("Import OK. Log off or reboot is required for changes to fully apply.")
    Else
      AppendLog("Import FAILED.")
    EndIf
  EndIf
EndProcedure

; ============================================================
;  MAIN LOOP
; ============================================================

Repeat
  Select WaitWindowEvent()
    Case #PB_Event_Gadget
      Select EventGadget()
        Case #BtnScan
          ScanEnvironment()
        Case #BtnRepair
          RepairEnvironment()
        Case #BtnExport
          DoExport()
        Case #BtnImport
          DoImport()
        Case #BtnAbout
          MessageRequester("Info", #APP_NAME + " - " + version + #CRLF$+ 
                                   "Thank you for using this free tool!" + #CRLF$ +
                                   "Contact: " + #EMAIL_NAME + #CRLF$ +
                                   "Website: https://github.com/zonemaster60", #PB_MessageRequester_Info)
        Case #BtnExit
          Exit()
      EndSelect

    Case #PB_Event_CloseWindow
      Exit()
  EndSelect
ForEver

; IDE Options = PureBasic 6.30 beta 5 (Windows - x64)
; EnableAdmin
; DPIAware
; IDE Options = PureBasic 6.30 (Windows - x64)
; CursorPosition = 5
; Folding = ----
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyWSERTool.ico
; Executable = ..\HandyWSERTool.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,4
; VersionField1 = 1,0,0,4
; VersionField2 = ZoneSoft
; VersionField3 = HandyWSERTool
; VersionField4 = 1.0.0.4
; VersionField5 = 1.0.0.4
; VersionField6 = Windows System Environment Repair Tool
; VersionField7 = HandyWSERTool
; VersionField8 = HandyWSERTool.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60