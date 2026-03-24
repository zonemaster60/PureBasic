;EXAMPLE 6

#StringGadget = 0
#Button1 = 1
#Button2 = 2
#MyWindow = 0

;Now we will have 2 buttons

Procedure Button1_Click()
  DisableGadget(#Button2, 0) ;we enable the button 2
    For i = 0 To 50
      Beep_(100 * i, 20) ; Make a Beep with a different frequency each time!
                        ; its an API call and not a PureBasic command
      SetGadgetText(#StringGadget, Str(i))
      WindowEvent(); This is usefull for letting the window proc ess an event inside the for
    Next i
EndProcedure

Procedure Button2_Click()
  DisableGadget(#Button2, 1) ;we disable the button 2 again
    For i = 0 To 50
      Beep_(100 * (50 - i), 20)
      SetGadgetText(#StringGadget, Str(50 - i))
      WindowEvent()
    Next i
EndProcedure

If OpenWindow(#MyWindow, 100, 150, 450, 200, "", #PB_Window_SystemMenu)
  StringGadget(#StringGadget, 30, 50, 370, 20, "")
  ButtonGadget(#Button1, 180, 100, 70, 25, "Button 1")
  ButtonGadget(#Button2, 180, 130, 70, 25, "Button 2")
  DisableGadget(#Button2, 1) ;we disable the button 2
  Repeat
    EventID = WaitWindowEvent()

    Select EventID

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #Button1
            Button1_Click()
          Case #Button2
            Button2_Click()
        EndSelect

    EndSelect

  Until EventID = #PB_Event_CloseWindow
EndIf
End

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; Folding = -
; EnableXP
; DPIAware
