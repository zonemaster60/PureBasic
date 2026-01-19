EnableExplicit

DeclareModule Time
  Declare Init(targetFps.i)
  Declare.d NowSeconds()
  Declare.f FixedDeltaSeconds()
EndDeclareModule

Module Time
  Global g_targetFps.i
  Global g_fixedDelta.f

  Procedure Init(targetFps.i)
    If targetFps <= 0
      targetFps = 60
    EndIf

    g_targetFps = targetFps
    g_fixedDelta = 1.0 / g_targetFps
  EndProcedure

  Procedure.d NowSeconds()
    ProcedureReturn ElapsedMilliseconds() / 1000.0
  EndProcedure

  Procedure.f FixedDeltaSeconds()
    If g_fixedDelta <= 0.0
      ProcedureReturn (1.0 / 60.0)
    EndIf
    ProcedureReturn g_fixedDelta
  EndProcedure
EndModule
