If InitSound() = 0
  MessageRequester("Error", "Sound system is not available", #PB_MessageRequester_Error)
  End
EndIf

SoundFileName$ = OpenFileRequester("Choose a .wav file", "", "Wave files|*.wav",0)
If SoundFileName$
  If LoadSound(0, SoundFileName$)
    PlaySound(0, #PB_Sound_Loop)
    MessageRequester("PlaySound", "Playing the sound (loop)..."+#LF$+"Click to quit..", 0)
  Else
    MessageRequester("Error", "Can't load the sound.", #PB_MessageRequester_Error)
  EndIf
EndIf
FreeSound(0)
End
; IDE Options = PureBasic 6.03 beta 9 LTS (Windows - x64)
; CursorPosition = 1
; EnableXP
; DPIAware