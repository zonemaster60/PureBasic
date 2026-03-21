DeclareModule Time
  Declare Init(targetFps.i = 60)
  Declare.d NowSeconds()
  Declare.f FixedDeltaSeconds()
EndDeclareModule

Module Time
  Global g_targetFps.i = 60
  Global g_fixedDelta.f = 1.0 / 60.0
  Global g_startTime.q = 0
  Global g_freq.q = 0

  Procedure Init(targetFps.i = 60)
    If targetFps <= 0
      targetFps = 60
    EndIf

    g_targetFps = targetFps
    g_fixedDelta = 1.0 / targetFps
    QueryPerformanceFrequency_(@g_freq)
    QueryPerformanceCounter_(@g_startTime)
  EndProcedure

  Procedure.d NowSeconds()
    Protected now.q
    If g_freq = 0
      ProcedureReturn 0.0
    EndIf
    QueryPerformanceCounter_(@now)
    ProcedureReturn (now - g_startTime) / g_freq
  EndProcedure

  Procedure.f FixedDeltaSeconds()
    ProcedureReturn g_fixedDelta
  EndProcedure
EndModule
