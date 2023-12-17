;-Initialisation--------------------------------------

If InitSprite() = 0 
  MessageRequester("Fehler", "Kann Grafik nicht Initialisieren..(DirectX7 oder höher notwendig!)", 0)
  End
EndIf

If InitKeyboard() = 0 
  MessageRequester("Fehler", "Kann Keyboard nicht Initialisieren..(DirectX7 oder höher notwendig!)", 0)
  End
EndIf

If InitSound() = 0 
  MessageRequester("Fehler", "Kann Sound nicht Initialisieren..(DirectX7 oder höher notwendig, Soundkarte notwendig!)", 0)
  End
EndIf

If InitMouse() = 0
  MessageRequester("Fehler", "Kann Maus nicht Initialisieren..", 0)
  End
EndIf

If InitModule() = 0
  MessageRequester("Fehler", "Kann die Module-Umgebung nicht Initialisieren..",  0) 
  End
EndIf
; Ende der Umgebungs-Initialisierung



OpenScreen(800,600,16,"Ballerkurs")  ; Vollbildmodus, 800*600 Pixel, 16bit Farbtiefe


; ExecutableFormat=Windows
; EOF