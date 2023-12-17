If OpenWindow(0, 0, 0, 320, 160, "ProgressBarGadget", #PB_Window_SystemMenu | #PB_Window_ScreenCentered)
    TextGadget       (3,  10, 10, 250,  20, "ProgressBar Standard  (50/100)", #PB_Text_Center)
    ProgressBarGadget(0,  10, 30, 250,  30, 0, 100)
    SetGadgetState   (0, 50)   ;  set 1st progressbar (ID = 0) to 50 of 100
    TextGadget       (4,  10, 70, 250,  20, "ProgressBar Smooth  (50/200)", #PB_Text_Center)
    ProgressBarGadget(1,  10, 90, 250,  30, 0, 200, #PB_ProgressBar_Smooth)
    SetGadgetState   (1, 50)   ;  set 2nd progressbar (ID = 1) to 50 of 200
    TextGadget       (5, 100,135, 200,  20, "ProgressBar Vertical  (100/300)", #PB_Text_Right)
    ProgressBarGadget(2, 270, 10,  30, 120, 0, 300, #PB_ProgressBar_Vertical)
    SetGadgetState   (2, 100)   ; set 3rd progressbar (ID = 2) to 100 of 300
    Repeat : Until WaitWindowEvent()=#PB_Event_CloseWindow
  EndIf

; IDE Options = PureBasic 6.01 LTS (Windows - x64)
; CursorPosition = 12
; EnableXP
; DPIAware