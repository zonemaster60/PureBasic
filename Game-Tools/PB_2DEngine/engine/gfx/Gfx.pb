EnableExplicit

DeclareModule Gfx
  Declare.i Init(title.s, width.i, height.i)
  Declare.i InitHeadless(width.i, height.i)
  Declare PumpEvents()
  Declare BeginFrame()
  Declare EndFrame()
  Declare.i WindowClosed()
  Declare.i Ready()
  Declare.i Headless()
  Declare.i Width()
  Declare.i Height()
  Declare Shutdown()
EndDeclareModule

Module Gfx
  Global g_headless.i = #False
  Global g_windowOpen.i = #False
  Global g_screenOpen.i = #False
  Global g_closeRequested.i = #False
  Global g_width.i = 0
  Global g_height.i = 0

  Procedure.i ValidateDimensions(width.i, height.i)
    ProcedureReturn Bool(width > 0 And height > 0)
  EndProcedure

  Procedure.i Init(title.s, width.i, height.i)
    g_headless = #False
    g_windowOpen = #False
    g_screenOpen = #False
    g_closeRequested = #False
    g_width = 0
    g_height = 0

    If ValidateDimensions(width, height) = #False
      ProcedureReturn #False
    EndIf

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
    g_width = width
    g_height = height

    ProcedureReturn #True
  EndProcedure

  Procedure.i InitHeadless(width.i, height.i)
    If ValidateDimensions(width, height) = #False
      ProcedureReturn #False
    EndIf

    g_headless = #True
    g_windowOpen = #False
    g_screenOpen = #False
    g_closeRequested = #False
    g_width = width
    g_height = height
    ProcedureReturn #True
  EndProcedure

  Procedure PumpEvents()
    Protected event.i

    If g_headless Or Not g_windowOpen
      ProcedureReturn
    EndIf

    Repeat
      event = WindowEvent()
      If event = #PB_Event_CloseWindow
        g_closeRequested = #True
      EndIf
    Until event = 0
  EndProcedure

  Procedure BeginFrame()
    If g_screenOpen And Not g_headless
      ClearScreen(RGB(0, 0, 0))
    EndIf
  EndProcedure

  Procedure EndFrame()
    If g_screenOpen And Not g_headless
      FlipBuffers()
    EndIf
  EndProcedure

  Procedure.i WindowClosed()
    If g_headless Or Not g_windowOpen
      ProcedureReturn #False
    EndIf

    PumpEvents()
    ProcedureReturn g_closeRequested
  EndProcedure

  Procedure.i Ready()
    ProcedureReturn Bool(g_headless Or g_screenOpen)
  EndProcedure

  Procedure.i Headless()
    ProcedureReturn g_headless
  EndProcedure

  Procedure.i Width()
    ProcedureReturn g_width
  EndProcedure

  Procedure.i Height()
    ProcedureReturn g_height
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
    g_windowOpen = #False
    g_screenOpen = #False
    g_closeRequested = #False
    g_width = 0
    g_height = 0
  EndProcedure
EndModule
