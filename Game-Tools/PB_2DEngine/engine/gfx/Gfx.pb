DeclareModule Gfx
  Declare.i Init(title.s, width.i, height.i)
  Declare.i InitHeadless(width.i, height.i)
  Declare BeginFrame()
  Declare EndFrame()
  Declare.i WindowClosed()
  Declare Shutdown()
EndDeclareModule

Module Gfx
  Global g_headless.i = #False
  Global g_windowOpen.i = #False
  Global g_screenOpen.i = #False

  Procedure.i Init(title.s, width.i, height.i)
    g_headless = #False
    g_windowOpen = #False
    g_screenOpen = #False

    If InitSprite() = 0 Or InitKeyboard() = 0
      ProcedureReturn #False
    EndIf

    If OpenWindow(0, 0, 0, width, height, title, #PB_Window_SystemMenu | #PB_Window_ScreenCentered) = 0
      ProcedureReturn #False
    EndIf
    g_windowOpen = #True

    If OpenWindowedScreen(WindowID(0), 0, 0, width, height) = 0
      CloseWindow(0)
      g_windowOpen = #False
      ProcedureReturn #False
    EndIf
    g_screenOpen = #True

    ProcedureReturn #True
  EndProcedure

  Procedure.i InitHeadless(width.i, height.i)
    g_headless = #True
    g_windowOpen = #False
    g_screenOpen = #False
    ProcedureReturn #True
  EndProcedure

  Procedure BeginFrame()
    If Not g_headless
      ClearScreen(RGB(0, 0, 0))
    EndIf
  EndProcedure

  Procedure EndFrame()
    If Not g_headless
      FlipBuffers()
    EndIf
  EndProcedure

  Procedure.i WindowClosed()
    Protected event.i

    If g_headless Or Not g_windowOpen
      ProcedureReturn #False
    EndIf

    Repeat
      event = WindowEvent()
      If event = #PB_Event_CloseWindow
        ProcedureReturn #True
      EndIf
    Until event = 0

    ProcedureReturn #False
  EndProcedure

  Procedure Shutdown()
    If g_screenOpen
      CloseScreen()
      g_screenOpen = #False
    EndIf

    If g_windowOpen
      CloseWindow(0)
      g_windowOpen = #False
    EndIf

    g_headless = #False
  EndProcedure
EndModule
