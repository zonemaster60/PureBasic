EnableExplicit

DeclareModule Log
  Declare Init()
  Declare InitFile(filePath.s)
  Declare Shutdown()

  Declare Info(message.s)
  Declare Warn(message.s)
  Declare Error(message.s)
EndDeclareModule

Module Log
  Global g_file.i

  Procedure Init()
    ; Default: log to debugger only.
  EndProcedure

  Procedure InitFile(filePath.s)
    If g_file
      CloseFile(g_file)
      g_file = 0
    EndIf

    g_file = CreateFile(#PB_Any, filePath)
    If g_file = 0
      Debug "[WARN] Failed to open log file: " + filePath
    Else
      WriteStringN(g_file, "PB2DEngine log start")
    EndIf
  EndProcedure

  Procedure Shutdown()
    If g_file
      WriteStringN(g_file, "PB2DEngine log end")
      CloseFile(g_file)
      g_file = 0
    EndIf
  EndProcedure

  Procedure WriteLine(prefix.s, message.s)
    Protected line.s = prefix + message
    Debug line
    If g_file
      WriteStringN(g_file, line)
    EndIf
  EndProcedure

  Procedure Info(message.s)
    WriteLine("[INFO] ", message)
  EndProcedure

  Procedure Warn(message.s)
    WriteLine("[WARN] ", message)
  EndProcedure

  Procedure Error(message.s)
    WriteLine("[ERROR] ", message)
  EndProcedure
EndModule
