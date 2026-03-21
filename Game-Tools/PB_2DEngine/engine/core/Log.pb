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

  Procedure Init()
    Debug "LOG: Init"
  EndProcedure

  Procedure InitFile(path.s)
    If g_logFile
      CloseFile(g_logFile)
      g_logFile = 0
    EndIf

    g_logFile = CreateFile(#PB_Any, path)
    If g_logFile
      WriteStringN(g_logFile, "LOG: Started at " + FormatDate("%yyyy-%mm-%dd %hh:%ii:%ss", Date()))
    EndIf
  EndProcedure

  Procedure Info(msg.s)
    Protected t.s = "[INFO] " + msg
    Debug t
    If g_logFile : WriteStringN(g_logFile, t) : FlushFileBuffers(g_logFile) : EndIf
  EndProcedure

  Procedure Warn(msg.s)
    Protected t.s = "[WARN] " + msg
    Debug t
    If g_logFile : WriteStringN(g_logFile, t) : FlushFileBuffers(g_logFile) : EndIf
  EndProcedure

  Procedure Error(msg.s)
    Protected t.s = "[ERROR] " + msg
    Debug t
    If g_logFile : WriteStringN(g_logFile, t) : FlushFileBuffers(g_logFile) : EndIf
  EndProcedure

  Procedure Shutdown()
    If g_logFile
      CloseFile(g_logFile)
      g_logFile = 0
    EndIf
  EndProcedure
EndModule
