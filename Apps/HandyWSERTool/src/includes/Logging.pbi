Procedure.s LogTimestamp()
  ProcedureReturn FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
EndProcedure

Procedure.i AppendLogToFile(msg.s)
  Protected file.i

  If LogFilePath = ""
    ProcedureReturn #False
  EndIf

  file = OpenFile(#PB_Any, LogFilePath)
  If file = 0
    file = CreateFile(#PB_Any, LogFilePath)
    If file = 0
      ProcedureReturn #False
    EndIf
  Else
    FileSeek(file, Lof(file))
  EndIf

  WriteStringN(file, "[" + LogTimestamp() + "] " + msg)
  CloseFile(file)
  ProcedureReturn #True
EndProcedure

Procedure InitializeLogging()
  LogDir = AppPath + "Logs\\"
  If FileSize(LogDir) <> -2
    CreateDirectory(LogDir)
  EndIf

  LogFilePath = LogDir + #APP_NAME + "_" + FormatDate("%yyyy-%mm-%dd_%hh-%ii-%ss", Date()) + ".log"
  AppendLogToFile(#APP_NAME + " started (version " + version + ")")
EndProcedure

Procedure BroadcastEnvironmentChange()
  #HWND_BROADCAST = $FFFF
  #WM_SETTINGCHANGE = $001A
  #SMTO_ABORTIFHUNG = $0002

  Protected result.i
  Protected msg.s = "Environment"
  SendMessageTimeout_(#HWND_BROADCAST, #WM_SETTINGCHANGE, 0, @msg, #SMTO_ABORTIFHUNG, 2000, @result)
EndProcedure

Procedure AppendLog(msg.s)
  AppendLogToFile(msg)
  AddGadgetItem(#Log, -1, msg)
  SendMessage_(GadgetID(#Log), #EM_LINESCROLL, 0, 65535)
EndProcedure
