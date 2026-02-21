EnableExplicit

#APP_NAME   = "HandyWSERTool"
#EMAIL_NAME = "zonemaster60@gmail.com"

Global version.s = "v1.0.0.5"
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
    Protected maxValueNameLen.l, maxValueDataLen.l, valueCount.l
    Protected bufNameChars.l, bufValueBytes.l

    ClearList(vars())

    If OpenEnvKey(#KEY_READ, @hKey, scope) = #False
      ProcedureReturn #False
    EndIf

    ; Pre-size buffers using key metadata (faster than per-iteration allocations)
    maxValueNameLen = 512
    maxValueDataLen = 4096 * SizeOf(Character)
    If RegQueryInfoKey_(hKey, 0, 0, 0, 0, 0, 0, @valueCount, @maxValueNameLen, @maxValueDataLen, 0, 0) = #ERROR_SUCCESS
      maxValueNameLen + 1 ; include null terminator
      maxValueDataLen + SizeOf(Character)
    Else
      maxValueNameLen = 512
      maxValueDataLen = 4096 * SizeOf(Character)
    EndIf

    bufNameChars  = maxValueNameLen
    bufValueBytes = maxValueDataLen
    If bufNameChars < 2 : bufNameChars = 512 : EndIf
    If bufValueBytes < (2 * SizeOf(Character)) : bufValueBytes = 4096 * SizeOf(Character) : EndIf

    nameBuf = Space(bufNameChars)
    valueChars = bufValueBytes / SizeOf(Character)
    valueBuf = Space(valueChars)

    While #True
      sizeName  = bufNameChars
      dataBytes = bufValueBytes

      result = RegEnumValue_(hKey, index, @nameBuf, @sizeName, 0, @type, @valueBuf, @dataBytes)

      ; Grow buffers if needed (e.g. long Path)
      If result = #ERROR_MORE_DATA
        If sizeName >= 1 And sizeName + 1 > bufNameChars
          bufNameChars = sizeName + 1
          nameBuf = Space(bufNameChars)
        EndIf

        If dataBytes > bufValueBytes
          bufValueBytes = dataBytes + SizeOf(Character)
          valueChars = bufValueBytes / SizeOf(Character)
          If valueChars < 2 : valueChars = 4096 : EndIf
          valueBuf = Space(valueChars)
        EndIf

        sizeName  = bufNameChars
        dataBytes = bufValueBytes
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
;  HELPERS
; ============================================================

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

  ; Keep original ordering but de-dupe
  ForEach origItems()
    normKey = LCase(NormalizeDirValue(origItems()))
    If normKey <> "" And FindMapElement(seen(), normKey) = 0
      AddMapElement(seen(), normKey)
      seen() = 1
      AddElement(finalItems())
      finalItems() = origItems()
    EndIf
  Next

  ; Append missing required entries
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

  If v <> ""
    ProcedureReturn v
  EndIf

  Select n
    Case "temp", "tmp"
      ProcedureReturn "%USERPROFILE%\\AppData\\Local\\Temp"
    Case "appdata"
      ProcedureReturn "%USERPROFILE%\\AppData\\Roaming"
    Case "localappdata"
      ProcedureReturn "%USERPROFILE%\\AppData\\Local"
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
  ; Fixable == we have a deterministic recommended value
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

Procedure BroadcastEnvironmentChange()
  ; Notify other apps that environment changed
  ; WM_SETTINGCHANGE / lParam = "Environment"
  #HWND_BROADCAST = $FFFF
  #WM_SETTINGCHANGE = $001A
  #SMTO_ABORTIFHUNG = $0002

  Protected result.i
  Protected msg.s = "Environment"
  SendMessageTimeout_(#HWND_BROADCAST, #WM_SETTINGCHANGE, 0, @msg, #SMTO_ABORTIFHUNG, 2000, @result)
EndProcedure

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
#BtnFixRefs = 8

OpenWindow(#Win, 200, 200, 800, 550, #APP_NAME + " - " + version, #PB_Window_ScreenCentered | #PB_Window_MinimizeGadget)
EditorGadget(#Log, 10, 10, 780, 460, #PB_Editor_ReadOnly | #PB_Editor_WordWrap)
ButtonGadget(#BtnScan,   10, 480, 120, 40, "Scan")
ButtonGadget(#BtnRepair, 140, 480, 120, 40, "Repair")
ButtonGadget(#BtnExport, 270, 480, 120, 40, "Export")
ButtonGadget(#BtnImport, 400, 480, 120, 40, "Import")
ButtonGadget(#BtnAbout, 530, 480, 120, 40, "About")
ButtonGadget(#BtnFixRefs, 660, 480, 120, 40, "Fix %Vars%")
ButtonGadget(#BtnExit, 660, 525, 120, 20, "Exit")

Procedure AppendLog(msg.s)
  AddGadgetItem(#Log, -1, msg)
  SendMessage_(GadgetID(#Log), #EM_LINESCROLL, 0, 65535)
EndProcedure

; ============================================================
;  SCAN
; ============================================================

Procedure ScanEnvironment()
  ClearGadgetItems(#Log)

  Protected current.s, expected.s, key.s
  Protected NewList sysVars.EnvSys::VarEntry()
  Protected NewList userVars.EnvSys::VarEntry()
  Protected NewMap sysMap.EnvSys::VarEntry()
  Protected NewMap userMap.EnvSys::VarEntry()
  Protected missingSys.l, emptySys.l, differsSys.l
  Protected missingUser.l, emptyUser.l

  ; Load once per scope (faster + enables richer analysis)
  EnvSys::LoadAll(sysVars(), EnvSys::#ScopeSystem)
  EnvSys::LoadAll(userVars(), EnvSys::#ScopeUser)

  ForEach sysVars()
    key = LCase(sysVars()\Name)
    If key <> ""
      AddMapElement(sysMap(), key)
      sysMap() = sysVars()
    EndIf
  Next

  ForEach userVars()
    key = LCase(userVars()\Name)
    If key <> ""
      AddMapElement(userMap(), key)
      userMap() = userVars()
    EndIf
  Next

  ; Quick heuristics: variables referenced via %NAME% but not defined in either scope
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

  ; ---- System ----
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

  ; System PATH: detect missing core entries + duplicates
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

  ; ---- User ----
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
  UserCheck("OneDrive", #False)
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

  ; Also backup User environment (best-effort)
  Protected backupUserFile.s = GetTemporaryDirectory() + "user_env_backup_" + Str(Date()) + ".txt"
  If EnvSys::Backup(backupUserFile, EnvSys::#ScopeUser)
    AppendLog("User backup saved to: " + backupUserFile)
  Else
    AppendLog("User backup FAILED (continuing).")
  EndIf

  AppendLog("")
  AppendLog("Fixing missing/empty variables (non-destructive)...")

  ; Load current scopes once
  Protected NewList sysVars.EnvSys::VarEntry()
  Protected NewList userVars.EnvSys::VarEntry()
  Protected NewMap sysMap.EnvSys::VarEntry()
  Protected NewMap userMap.EnvSys::VarEntry()
  Protected key.s, current.s

  EnvSys::LoadAll(sysVars(), EnvSys::#ScopeSystem)
  ForEach sysVars()
    key = LCase(sysVars()\Name)
    If key <> ""
      AddMapElement(sysMap(), key)
      sysMap() = sysVars()
    EndIf
  Next

  EnvSys::LoadAll(userVars(), EnvSys::#ScopeUser)
  ForEach userVars()
    key = LCase(userVars()\Name)
    If key <> ""
      AddMapElement(userMap(), key)
      userMap() = userVars()
    EndIf
  Next

  ; System defaults: only fix missing/empty
  ForEach DefaultVars()
    key = LCase(DefaultVars()\name)
    If FindMapElement(sysMap(), key) = 0 Or sysMap()\Value = ""
      If EnvSys::WriteVar(DefaultVars()\name, DefaultVars()\value, DefaultVars()\typ, EnvSys::#ScopeSystem)
        AppendLog("[FIXED] " + DefaultVars()\name + " = " + DefaultVars()\value)
      Else
        AppendLog("[FAILED] " + DefaultVars()\name)
      EndIf
    Else
      AppendLog("[SKIP] " + DefaultVars()\name + " already set")
    EndIf
  Next

  ; System PATH: ensure core entries exist, keep custom entries
  Protected addedCount.Integer
  If FindMapElement(sysMap(), "path") = 0 Or sysMap()\Value = ""
    If EnvSys::WriteVar("Path", DefaultSystemPath, #REG_EXPAND_SZ, EnvSys::#ScopeSystem)
      AppendLog("[FIXED] Path set to core defaults")
    Else
      AppendLog("[FAILED] Path")
    EndIf
  Else
    Protected newPath.s = EnsurePathContainsRequired(sysMap()\Value, DefaultSystemPath, @addedCount)
    If ValuesEqual("Path", newPath, sysMap()\Value) = #False
      If EnvSys::WriteVar("Path", newPath, #REG_EXPAND_SZ, EnvSys::#ScopeSystem)
        AppendLog("[FIXED] Path updated (added core entries: " + Str(addedCount\i) + ")")
      Else
        AppendLog("[FAILED] Path")
      EndIf
    Else
      AppendLog("[OK] Path already contains core entries")
    EndIf
  EndIf

  ; User variables: fix missing/empty using recommended values
  AppendLog("")
  AppendLog("Fixing missing/empty User variables...")

  Protected rec.s
  Macro FixUser(name)
    key = LCase(name)
    current = ""
    If FindMapElement(userMap(), key)
      current = userMap()\Value
    EndIf
    rec.s = RecommendedUserValue(name)
    If rec <> "" And (FindMapElement(userMap(), key) = 0 Or current = "")
      If EnvSys::WriteVar(name, rec, #REG_EXPAND_SZ, EnvSys::#ScopeUser)
        AppendLog("[FIXED] " + name + " = " + rec)
      Else
        AppendLog("[FAILED] " + name)
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

; ============================================================
;  FIX ONLY REFERENCED MISSING %VARS%
; ============================================================

Procedure FixReferencedMissingVars()
  ClearGadgetItems(#Log)
  AppendLog("Fixing referenced-but-missing %VARS% only...")

  Protected backupSysFile.s = GetTemporaryDirectory() + "system_env_backup_" + Str(Date()) + ".txt"
  Protected backupUserFile.s = GetTemporaryDirectory() + "user_env_backup_" + Str(Date()) + ".txt"

  If EnvSys::Backup(backupSysFile, EnvSys::#ScopeSystem)
    AppendLog("System backup saved to: " + backupSysFile)
  Else
    AppendLog("System backup FAILED (no changes made).")
    ProcedureReturn
  EndIf

  If EnvSys::Backup(backupUserFile, EnvSys::#ScopeUser)
    AppendLog("User backup saved to: " + backupUserFile)
  Else
    AppendLog("User backup FAILED (continuing).")
  EndIf

  Protected NewList sysVars.EnvSys::VarEntry()
  Protected NewList userVars.EnvSys::VarEntry()
  Protected NewMap sysMap.EnvSys::VarEntry()
  Protected NewMap userMap.EnvSys::VarEntry()
  Protected NewMap referenced.i()
  Protected key.s, token.s

  EnvSys::LoadAll(sysVars(), EnvSys::#ScopeSystem)
  EnvSys::LoadAll(userVars(), EnvSys::#ScopeUser)

  ForEach sysVars()
    key = LCase(sysVars()\Name)
    If key <> ""
      AddMapElement(sysMap(), key)
      sysMap() = sysVars()
    EndIf
  Next
  ForEach userVars()
    key = LCase(userVars()\Name)
    If key <> ""
      AddMapElement(userMap(), key)
      userMap() = userVars()
    EndIf
  Next

  CollectReferencedFromVars(sysVars(), referenced())
  CollectReferencedFromVars(userVars(), referenced())

  Protected fixed.l = 0
  Protected skipped.l = 0
  Protected failed.l = 0
  Protected recSys.s, recUser.s

  ForEach referenced()
    token = MapKey(referenced())

    ; already exists in either scope
    If MapHasNonEmptyValue(sysMap(), token) Or MapHasNonEmptyValue(userMap(), token)
      Continue
    EndIf

    ; Prefer System for known system vars, otherwise User for known user vars
    If IsSystemVar(token) Or IsFixableSystemVar(token)
      If IsFixableSystemVar(token)
        recSys.s = RecommendedSystemValue(token)
        If token = "path" And FindMapElement(sysMap(), "path")
          ; For PATH we repair by appending missing core entries
          Protected addedCount.Integer
          recSys = EnsurePathContainsRequired(sysMap()\Value, DefaultSystemPath, @addedCount)
        EndIf

        If recSys <> ""
          If EnvSys::WriteVar(token, recSys, RecommendedSystemType(token), EnvSys::#ScopeSystem)
            AppendLog("[FIXED] %" + token + "% -> System")
            fixed + 1
          Else
            AppendLog("[FAILED] %" + token + "% -> System")
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
        recUser.s = RecommendedUserValue(token)
        If recUser <> ""
          If EnvSys::WriteVar(token, recUser, #REG_EXPAND_SZ, EnvSys::#ScopeUser)
            AppendLog("[FIXED] %" + token + "% -> User")
            fixed + 1
          Else
            AppendLog("[FAILED] %" + token + "% -> User")
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
    Case #BtnFixRefs
      FixReferencedMissingVars()
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
; Folding = -------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = HandyWSERTool.ico
; Executable = ..\HandyWSERTool.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,5
; VersionField1 = 1,0,0,5
; VersionField2 = ZoneSoft
; VersionField3 = HandyWSERTool
; VersionField4 = 1.0.0.5
; VersionField5 = 1.0.0.5
; VersionField6 = Windows System Environment Repair Tool
; VersionField7 = HandyWSERTool
; VersionField8 = HandyWSERTool.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60