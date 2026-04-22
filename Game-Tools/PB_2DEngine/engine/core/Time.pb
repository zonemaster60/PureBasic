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
  Global g_fallbackStartMs.i = 0

  Procedure Init(targetFps.i = 60)
    If targetFps <= 0
      targetFps = 60
    EndIf

    g_targetFps = targetFps
    g_fixedDelta = 1.0 / targetFps

    If QueryPerformanceFrequency_(@g_freq) And QueryPerformanceCounter_(@g_startTime)
      g_fallbackStartMs = 0
    Else
      g_freq = 0
      g_startTime = 0
      g_fallbackStartMs = ElapsedMilliseconds()
    EndIf
  EndProcedure

  Procedure.d NowSeconds()
    Protected now.q

    If g_freq = 0
      If g_fallbackStartMs = 0
        ProcedureReturn 0.0
      EndIf

      ProcedureReturn (ElapsedMilliseconds() - g_fallbackStartMs) / 1000.0
    EndIf

    QueryPerformanceCounter_(@now)
    ProcedureReturn (now - g_startTime) / g_freq
  EndProcedure

  Procedure.f FixedDeltaSeconds()
    If g_fixedDelta <= 0.0
      ProcedureReturn 1.0 / 60.0
    EndIf

    ProcedureReturn g_fixedDelta
  EndProcedure
EndModule
