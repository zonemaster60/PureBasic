DeclareModule Log
  Declare Init()
  Declare InitFile(path.s)
  Declare Info(msg.s)
  Declare Warn(msg.s)
  Declare Error(msg.s)
  Declare Shutdown()
EndDeclareModule

Module Log
  Global g_logFile.i = 0

  Procedure.s Timestamp()
    ProcedureReturn FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date())
  EndProcedure

  Procedure WriteLine(line.s)
    Protected formatted.s = "[" + Timestamp() + "] " + line
    Debug formatted

    If g_logFile
      WriteStringN(g_logFile, formatted)
      FlushFileBuffers(g_logFile)
    EndIf
  EndProcedure

  Procedure Init()
    WriteLine("[INFO] Log initialized")
  EndProcedure

  Procedure InitFile(path.s)
    If g_logFile
      CloseFile(g_logFile)
      g_logFile = 0
    EndIf

    g_logFile = CreateFile(#PB_Any, path)
    If g_logFile
      WriteLine("[INFO] Log started")
    Else
      Debug "[" + Timestamp() + "] [ERROR] Failed to open log file: " + path
    EndIf
  EndProcedure

  Procedure Info(msg.s)
    WriteLine("[INFO] " + msg)
  EndProcedure

  Procedure Warn(msg.s)
    WriteLine("[WARN] " + msg)
  EndProcedure

  Procedure Error(msg.s)
    WriteLine("[ERROR] " + msg)
  EndProcedure

  Procedure Shutdown()
    If g_logFile
      CloseFile(g_logFile)
      g_logFile = 0
    EndIf
  EndProcedure
EndModule
