IncludeFile "InitSystem.pb"  ;Dieser Befehl wird beim Starten durch den 
                        ;Inhalt der Datei "Init.pb" ersetzt



Global playerX.l   ;Variablen zur Steuerung des Raumschiffs
Global playerY.l   ;für die X u. Y Position
Global playerSpeed.l   ;und die Geschwindigkeit, mit der sich das Schiff bewegt




playerX = 0      ;Startposition setzen: linker Bildschirmrand
playerY = 300    ;in der Mitte 
playerSpeed = 4  ;Geschwindigkeit auf 4 Pixel/Programmdurchlauf setzen




Enumeration     ;Enumeration wird benutzt, damit man nicht jede Konstante
  #Sprite_Player   ;von Hand deklarieren muss
  #Sprite_Back
EndEnumeration



LoadSprite(#Sprite_Player, "..\GFXSND\player.bmp")  ;Das Raumschiff laden
LoadSprite(#Sprite_Back, "..\GFXSND\back.bmp")      ;Hintergrund laden






;MainLoop ######################################

Repeat
ExamineKeyboard() ;Damit das Programm auf Tastaturabfragen reagieren kann


DisplaySprite(#Sprite_Back, 0, 0) ;Das Hintergrundsprite immer am Anfang des MainLoops setzen,
                                  ;um alle alten Grafiken zu übermalen
                                  
                                  
Gosub steuerung  ;Das Programm "Springt" zum Sub "steuerung" und führt dessen Inhalt aus


StartDrawing(ScreenOutput()) : DrawingMode(1)   ;;Drawing für Textausgabe
  FrontColor(200,0,0)
  DrawText("ESC-Ende") 
StopDrawing()


DisplayTransparentSprite(#Sprite_Player, playerX, playerY) ;Das Raumschiff anzeigen

FlipBuffers() ; Damit alle Grafiken auch angezeigt werden
Until KeyboardReleased(#PB_Key_Escape) : End ;MainLoop so lange abarbeiten, bis ESC gedrückt wird

;MainLoop ENDE ##################################











;-Subs

;-Steuerung ####
steuerung:

;Hier werden die vier Cursortasten abgefragt und bei deren Betätigung
;die Variablen des Raumschiffs entsprechend verändert

;Außerdem wird jeweils abgefragt, ob das Raumschiff bereits am Rand des
;Bildschirms ist..in diesem Falle wird es nicht bewegt.

If KeyboardPushed(#PB_Key_Left) And playerX > 0 
  playerX - playerSpeed
EndIf

If KeyboardPushed(#PB_Key_Right) And playerX < 800 - SpriteWidth(#Sprite_Player)
  playerX + playerSpeed
EndIf

If KeyboardPushed(#PB_Key_Up) And playerY > 0
  playerY - playerSpeed
EndIf

If KeyboardPushed(#PB_Key_Down) And playerY < 600 -SpriteHeight(#Sprite_Player)
  playerY + playerSpeed
EndIf
  

Return

; ExecutableFormat=Windows
; EOF