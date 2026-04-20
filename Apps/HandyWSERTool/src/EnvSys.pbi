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
  Declare.l LastErrorCode()
  Declare.s LastErrorText()
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

  Global lastErrorCode.l

  Procedure SetLastErrorCode(result.l)
    lastErrorCode = result
  EndProcedure

  Procedure.l LastErrorCode()
    ProcedureReturn lastErrorCode
  EndProcedure

  Procedure.s LastErrorText()
    Protected *messageBuffer
    Protected message.s
    Protected flags.l = #FORMAT_MESSAGE_ALLOCATE_BUFFER | #FORMAT_MESSAGE_FROM_SYSTEM | #FORMAT_MESSAGE_IGNORE_INSERTS

    If lastErrorCode = #ERROR_SUCCESS
      ProcedureReturn "Success"
    EndIf

    If FormatMessage_(flags, 0, lastErrorCode, 0, @*messageBuffer, 0, 0) And *messageBuffer
      message = Trim(PeekS(*messageBuffer, -1, #PB_Unicode))
      message = ReplaceString(message, #CRLF$, " ")
      LocalFree_(*messageBuffer)
      If message <> ""
        ProcedureReturn "Win32 error " + Str(lastErrorCode) + ": " + message
      EndIf
    EndIf

    ProcedureReturn "Win32 error " + Str(lastErrorCode)
  EndProcedure

  Procedure.s RegistryTypeName(type.l)
    Select type
      Case #REG_SZ
        ProcedureReturn "REG_SZ"
      Case #REG_EXPAND_SZ
        ProcedureReturn "REG_EXPAND_SZ"
      Case #REG_MULTI_SZ
        ProcedureReturn "REG_MULTI_SZ"
    EndSelect

    ProcedureReturn Str(type)
  EndProcedure

  Procedure.l ParseRegistryType(typeText.s)
    Protected normalized.s = UCase(Trim(typeText))

    Select normalized
      Case "REG_SZ"
        ProcedureReturn #REG_SZ
      Case "REG_EXPAND_SZ"
        ProcedureReturn #REG_EXPAND_SZ
      Case "REG_MULTI_SZ"
        ProcedureReturn #REG_MULTI_SZ
    EndSelect

    If normalized <> ""
      ProcedureReturn Val(normalized)
    EndIf

    ProcedureReturn #REG_EXPAND_SZ
  EndProcedure

  Procedure.s SerializeVar(*var.VarEntry)
    ProcedureReturn *var\Name + "|" + RegistryTypeName(*var\Type) + "=" + *var\Value
  EndProcedure

  Procedure.i ParseVarLine(line.s, *var.VarEntry)
    Protected pos.l = FindString(line, "=", 1)
    Protected meta.s, value.s, typePos.l, typeText.s

    If pos <= 0
      ProcedureReturn #False
    EndIf

    meta = Trim(Left(line, pos - 1))
    value = Mid(line, pos + 1)
    typePos = FindString(meta, "|", 1)

    If typePos > 0
      *var\Name = Trim(Left(meta, typePos - 1))
      typeText = Mid(meta, typePos + 1)
      *var\Type = ParseRegistryType(typeText)
    Else
      *var\Name = meta
      *var\Type = #REG_EXPAND_SZ
    EndIf

    *var\Value = Trim(value)
    If Left(*var\Value, 1) = #DQUOTE$ And Right(*var\Value, 1) = #DQUOTE$ And Len(*var\Value) >= 2
      *var\Value = Mid(*var\Value, 2, Len(*var\Value) - 2)
    EndIf

    ProcedureReturn Bool(*var\Name <> "")
  EndProcedure

  Procedure AppendContinuation(List vars.VarEntry(), line.s)
    If LastElement(vars())
      If vars()\Value <> "" And Right(vars()\Value, 1) <> ";" And Left(line, 1) <> ";"
        vars()\Value + ";"
      EndIf
      vars()\Value + line
    EndIf
  EndProcedure

  Procedure.i ParseFile(filePath.s, List sysVars.VarEntry(), List userVars.VarEntry(), defaultScope.i = #ScopeSystem)
    Protected file.i
    Protected line.s
    Protected currentScope.i = defaultScope
    Protected entry.VarEntry

    ClearList(sysVars())
    ClearList(userVars())

    file = ReadFile(#PB_Any, filePath)
    If file = 0
      SetLastErrorCode(GetLastError_())
      ProcedureReturn #False
    EndIf

    SetLastErrorCode(#ERROR_SUCCESS)

    While Eof(file) = 0
      line = Trim(ReadString(file))

      If line = "" : Continue : EndIf
      If Left(line, 1) = ";" Or Left(line, 1) = "#" : Continue : EndIf

      Select LCase(line)
        Case "[system]"
          currentScope = #ScopeSystem
          Continue
        Case "[user]"
          currentScope = #ScopeUser
          Continue
      EndSelect

      If ParseVarLine(line, @entry)
        If currentScope = #ScopeUser
          AddElement(userVars())
          userVars() = entry
        Else
          AddElement(sysVars())
          sysVars() = entry
        EndIf
      ElseIf currentScope = #ScopeUser
        AppendContinuation(userVars(), line)
      Else
        AppendContinuation(sysVars(), line)
      EndIf
    Wend

    CloseFile(file)
    ProcedureReturn #True
  EndProcedure

  Procedure.i VarExists(name.s, scope.i = #ScopeSystem)
    Protected hKey.i, valueType.l, dataBytes.l, result.l

    If OpenEnvKey(#KEY_READ, @hKey, scope) = #False
      ProcedureReturn #False
    EndIf

    result = RegQueryValueEx_(hKey, name, 0, @valueType, 0, @dataBytes)
    RegCloseKey_(hKey)
    SetLastErrorCode(result)

    ProcedureReturn Bool(result = #ERROR_SUCCESS)
  EndProcedure

  Procedure.i OpenEnvKey(access.l, *hKey.Integer, scope.i = #ScopeSystem)
    Protected rootKey.i, subKey.s

    If scope = #ScopeUser
      rootKey = #HKCU
      subKey  = #ENV_PATH_USER
    Else
      rootKey = #HKLM
      subKey  = #ENV_PATH_SYS
    EndIf

    SetLastErrorCode(RegOpenKeyEx_(rootKey, subKey, 0, access, *hKey))
    If lastErrorCode
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

    result = RegQueryValueEx_(hKey, name, 0, @valueType, 0, @dataBytes)
    If result <> #ERROR_SUCCESS Or dataBytes = 0
      SetLastErrorCode(result)
      RegCloseKey_(hKey)
      ProcedureReturn ""
    EndIf

    Protected bufferChars.l = dataBytes / SizeOf(Character)
    buffer = Space(bufferChars)

    result = RegQueryValueEx_(hKey, name, 0, @valueType, @buffer, @dataBytes)
    RegCloseKey_(hKey)
    SetLastErrorCode(result)

    If result <> #ERROR_SUCCESS
      ProcedureReturn ""
    EndIf

    Protected actualValue.s = PeekS(@buffer, -1, #PB_Unicode)
    ProcedureReturn actualValue
  EndProcedure

  Procedure.i WriteVar(name.s, value.s, type.l, scope.i = #ScopeSystem)
    Protected hKey.i
    Protected *buf = @value
    Protected size.l = StringByteLength(value) + SizeOf(Character)

    If OpenEnvKey(#KEY_WRITE, @hKey, scope) = #False
      ProcedureReturn #False
    EndIf

    SetLastErrorCode(RegSetValueEx_(hKey, name, 0, type, *buf, size))
    If lastErrorCode <> #ERROR_SUCCESS
      RegCloseKey_(hKey)
      ProcedureReturn #False
    EndIf

    RegCloseKey_(hKey)
    SetLastErrorCode(#ERROR_SUCCESS)
    ProcedureReturn #True
  EndProcedure

  Procedure.i DeleteVar(name.s, scope.i = #ScopeSystem)
    Protected hKey.i

    If OpenEnvKey(#KEY_WRITE, @hKey, scope) = #False
      ProcedureReturn #False
    EndIf

    SetLastErrorCode(RegDeleteValue_(hKey, name))
    RegCloseKey_(hKey)
    ProcedureReturn Bool(lastErrorCode = #ERROR_SUCCESS)
  EndProcedure

  Procedure.i LoadAll(List vars.VarEntry(), scope.i = #ScopeSystem)
    Protected hKey.i, index.l = 0
    Protected nameBuf.s, valueBuf.s
    Protected sizeName.l, dataBytes.l, type.l
    Protected result.l
    Protected maxValueNameLen.l, maxValueDataLen.l, valueCount.l
    Protected bufNameChars.l, bufValueBytes.l

    ClearList(vars())

    If OpenEnvKey(#KEY_READ, @hKey, scope) = #False
      ProcedureReturn #False
    EndIf

    If RegQueryInfoKey_(hKey, 0, 0, 0, 0, 0, 0, @valueCount, @maxValueNameLen, @maxValueDataLen, 0, 0) <> #ERROR_SUCCESS
      maxValueNameLen = 512
      maxValueDataLen = 4096 * SizeOf(Character)
    EndIf

    maxValueNameLen + 1
    maxValueDataLen + SizeOf(Character)

    bufNameChars  = maxValueNameLen
    bufValueBytes = maxValueDataLen
    If bufNameChars < 256 : bufNameChars = 256 : EndIf
    If bufValueBytes < (256 * SizeOf(Character)) : bufValueBytes = 256 * SizeOf(Character) : EndIf

    nameBuf = Space(bufNameChars)
    valueBuf = Space(bufValueBytes / SizeOf(Character))

    While #True
      sizeName  = bufNameChars
      dataBytes = bufValueBytes

      result = RegEnumValue_(hKey, index, @nameBuf, @sizeName, 0, @type, @valueBuf, @dataBytes)

      If result = #ERROR_MORE_DATA
        If sizeName >= bufNameChars
          bufNameChars = sizeName + 1
          nameBuf = Space(bufNameChars)
        EndIf

        If dataBytes >= bufValueBytes
          bufValueBytes = dataBytes + SizeOf(Character)
          valueBuf = Space(bufValueBytes / SizeOf(Character))
        EndIf

        sizeName  = bufNameChars
        dataBytes = bufValueBytes
        result = RegEnumValue_(hKey, index, @nameBuf, @sizeName, 0, @type, @valueBuf, @dataBytes)
      EndIf

      If result <> #ERROR_SUCCESS
        SetLastErrorCode(result)
        Break
      EndIf

      AddElement(vars())
      vars()\Name  = Left(nameBuf, sizeName)
      vars()\Value = PeekS(@valueBuf, -1, #PB_Unicode)
      vars()\Type  = type

      index + 1
    Wend

    RegCloseKey_(hKey)
    If result = #ERROR_NO_MORE_ITEMS
      SetLastErrorCode(#ERROR_SUCCESS)
      ProcedureReturn #True
    EndIf

    ProcedureReturn #False
  EndProcedure

  Procedure.i ApplyAll(List vars.VarEntry(), overwrite.i = #True, strict.i = #False, scope.i = #ScopeSystem)
    Protected hKey.i
    Protected result.l
    Protected ok.i = #True

    If OpenEnvKey(#KEY_READ | #KEY_WRITE, @hKey, scope) = #False
      ProcedureReturn #False
    EndIf

    If strict
      Protected existing.s, sizeName.l, index.l = 0, found.i
      Protected nameBuf.s

      While #True
        sizeName = 512
        nameBuf  = Space(sizeName)

        result = RegEnumValue_(hKey, index, @nameBuf, @sizeName, 0, 0, 0, 0)
        If result = #ERROR_MORE_DATA
          nameBuf = Space(sizeName)
          result = RegEnumValue_(hKey, index, @nameBuf, @sizeName, 0, 0, 0, 0)
        EndIf

        If result = #ERROR_NO_MORE_ITEMS
          Break
        EndIf

        If result <> #ERROR_SUCCESS
          SetLastErrorCode(result)
          ok = #False
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
          result = RegDeleteValue_(hKey, existing)
          If result <> #ERROR_SUCCESS
            SetLastErrorCode(result)
            ok = #False
            Break
          EndIf
        Else
          index + 1
        EndIf
      Wend
    EndIf

    If ok
      ForEach vars()
        If overwrite Or VarExists(vars()\Name, scope) = #False
          result = RegSetValueEx_(hKey, vars()\Name, 0, vars()\Type, @vars()\Value, StringByteLength(vars()\Value) + SizeOf(Character))
          If result <> #ERROR_SUCCESS
            SetLastErrorCode(result)
            ok = #False
            Break
          EndIf
        EndIf
      Next
    EndIf

    RegCloseKey_(hKey)
    If ok
      SetLastErrorCode(#ERROR_SUCCESS)
    EndIf
    ProcedureReturn ok
  EndProcedure

  Procedure.i ExportToFile(filePath.s, scope.i = #ScopeSystem)
    Protected NewList vars.VarEntry()
    Protected file.i

    If LoadAll(vars(), scope) = #False
      ProcedureReturn #False
    EndIf

    file = CreateFile(#PB_Any, filePath)
    If file = 0
      SetLastErrorCode(GetLastError_())
      ProcedureReturn #False
    EndIf

    ForEach vars()
      WriteStringN(file, SerializeVar(@vars()))
    Next

    CloseFile(file)
    SetLastErrorCode(#ERROR_SUCCESS)
    ProcedureReturn #True
  EndProcedure

  Procedure.i Backup(filePath.s, scope.i = #ScopeSystem)
    Protected NewList vars.VarEntry()
    Protected machine.s = GetEnvironmentVariable("COMPUTERNAME")
    Protected file.i

    If LoadAll(vars(), scope) = #False
      ProcedureReturn #False
    EndIf

    file = CreateFile(#PB_Any, filePath)
    If file = 0
      SetLastErrorCode(GetLastError_())
      ProcedureReturn #False
    EndIf

    If scope = #ScopeUser
      WriteStringN(file, "; Windows User Environment Repair - Backup")
    Else
      WriteStringN(file, "; Windows System Environment Repair - Backup")
    EndIf
    WriteStringN(file, "; Generated: " + FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()))
    WriteStringN(file, "; Machine: " + machine)
    WriteStringN(file, "; Format: Name|RegistryType=Value")
    WriteStringN(file, "; ---------------------------------------------")
    WriteStringN(file, "")

    ForEach vars()
      WriteStringN(file, SerializeVar(@vars()))
    Next

    CloseFile(file)
    SetLastErrorCode(#ERROR_SUCCESS)
    ProcedureReturn #True
  EndProcedure

  Procedure.i ImportFromFile(filePath.s, overwrite.i = #True, scope.i = #ScopeSystem)
    Protected NewList sysVars.VarEntry()
    Protected NewList userVars.VarEntry()

    If ParseFile(filePath, sysVars(), userVars(), scope) = #False
      ProcedureReturn #False
    EndIf

    If scope = #ScopeUser
      ProcedureReturn ApplyAll(userVars(), overwrite, #False, scope)
    EndIf

    ProcedureReturn ApplyAll(sysVars(), overwrite, #False, scope)
  EndProcedure

  Procedure.i ImportBoth(filePath.s, overwrite.i = #True, defaultScope.i = #ScopeSystem)
    Protected NewList sysVars.VarEntry()
    Protected NewList userVars.VarEntry()
    Protected okSys.i = #True
    Protected okUser.i = #True

    If ParseFile(filePath, sysVars(), userVars(), defaultScope) = #False
      ProcedureReturn #False
    EndIf

    If ListSize(sysVars()) > 0
      okSys = ApplyAll(sysVars(), overwrite, #False, #ScopeSystem)
    EndIf
    If ListSize(userVars()) > 0
      okUser = ApplyAll(userVars(), overwrite, #False, #ScopeUser)
    EndIf

    ProcedureReturn Bool(okSys And okUser)
  EndProcedure

  Procedure.i BackupBoth(filePath.s)
    Protected NewList vars.VarEntry()
    Protected machine.s = GetEnvironmentVariable("COMPUTERNAME")
    Protected file.i

    file = CreateFile(#PB_Any, filePath)
    If file = 0
      SetLastErrorCode(GetLastError_())
      ProcedureReturn #False
    EndIf

    WriteStringN(file, "; HandyWSERTool Environment Backup")
    WriteStringN(file, "; Generated: " + FormatDate("[%yy-%mm-%dd]-[%hh:%ii:%ss] ", Date()))
    WriteStringN(file, "; Machine: " + machine)
    WriteStringN(file, "; Format: [System]/[User] sections with Name|RegistryType=Value")
    WriteStringN(file, "")

    WriteStringN(file, "[System]")
    If LoadAll(vars(), #ScopeSystem) = #False
      If LastErrorCode() = #ERROR_SUCCESS
        SetLastErrorCode(#ERROR_GEN_FAILURE)
      EndIf
      CloseFile(file)
      ProcedureReturn #False
    EndIf
    ForEach vars()
      WriteStringN(file, SerializeVar(@vars()))
    Next

    WriteStringN(file, "")
    WriteStringN(file, "[User]")
    If LoadAll(vars(), #ScopeUser) = #False
      If LastErrorCode() = #ERROR_SUCCESS
        SetLastErrorCode(#ERROR_GEN_FAILURE)
      EndIf
      CloseFile(file)
      ProcedureReturn #False
    EndIf
    ForEach vars()
      WriteStringN(file, SerializeVar(@vars()))
    Next

    CloseFile(file)
    SetLastErrorCode(#ERROR_SUCCESS)
    ProcedureReturn #True
  EndProcedure

  Procedure.i RestoreExact(filePath.s, strict.i = #True, scope.i = #ScopeSystem)
    Protected NewList sysVars.VarEntry()
    Protected NewList userVars.VarEntry()

    If ParseFile(filePath, sysVars(), userVars(), scope) = #False
      ProcedureReturn #False
    EndIf

    If scope = #ScopeUser
      ProcedureReturn ApplyAll(userVars(), #True, strict, scope)
    EndIf

    ProcedureReturn ApplyAll(sysVars(), #True, strict, scope)
  EndProcedure

EndModule
