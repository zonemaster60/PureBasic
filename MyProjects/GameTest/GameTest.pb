
;-Example

CompilerIf #PB_Compiler_IsMainFile
  InitSprite()
  InitKeyboard()
  
  ; player and enemy ships - maybe use sprite?
  Global px.f = Random(1024-50, 50)
  Global py.f = Random(768-50, 50)
  Global pship.s = "=O"
  Global ex.f = Random(1024-50, 50)
  Global ey.f = Random(768-50, 50)
  Global eship.s = "]-"
  
  ; create player window
  OpenWindow(0, 0, 0, 1024, 768, "Game Test", #PB_Window_ScreenCentered)
  OpenWindowedScreen(WindowID(0), 0, 0, 1024, 768, #True, 0, 0)
  
  ; Change parameter to test it out
  ;SetFrameRate(60)
   
  Repeat
  
    ; flush all window events
    Repeat
      Define event.i = WindowEvent()
    Until event = 0
  
    ; handle keyboard input
    ExamineKeyboard()
  
    If KeyboardPushed(#PB_Key_Escape)
      Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
      If Req = #PB_MessageRequester_Yes
        End
      EndIf
    EndIf
    
    ; player move left
    If KeyboardPushed(#PB_Key_Left)
      pship = "O="
      px = px - 0.5
      eship = "]-"
      ex = ex + 0.5
    EndIf  
    ; player move right
    If KeyboardPushed(#PB_Key_Right)
      pship = "=O"
      px = px + 0.5
      eship = "-["
      ex = ex - 0.5
    EndIf 
    ; player move up
    If KeyboardPushed(#PB_Key_Up)
      pship = "^"
      py = py - 0.5
      eship = "v"
      ey = ey + 0.5
    EndIf
    ; player move down
    If KeyboardPushed(#PB_Key_Down)
      pship = "v"
      py = py + 0.5
      eship = "^"
      ey = ey - 0.5
    EndIf
    
    ; draw screen
    ClearScreen(RGB(0,0,0))
    StartDrawing(ScreenOutput()) 
    
    ; draw coordinates
    DrawText(10, 10, Str(px), RGB(0, 255, 0))
    DrawText(50, 10, Str(py), RGB(0, 255, 0))
    ; draw player ship
    DrawText(px, py, pship, RGB(0, 255, 0))
    ; draw coordinates
    DrawText(90,10, Str(ex), RGB(255, 0, 0))
    DrawText(130,10, Str(ey), RGB(255, 0, 0))  
    ; draw enemy ship
    DrawText(ex, ey, eship, RGB(255, 0, 0))
    
    ; enemy ship collision
    If px = ex And py = ey
      MessageRequester("HIT", "You have hit the ENEMY ship!", #PB_MessageRequester_Ok)
      ex = Random(1024-50, 50)
      ey = Random(768-50, 50)
      DrawText(ex, ey, eship, RGB(255,0,0))
      StopDrawing()
    EndIf
    
    ; stop drawing
    StopDrawing()
    FlipBuffers()
  
  ForEver
CompilerEndIf

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 14
; Folding = -
; EnableXP
; DPIAware