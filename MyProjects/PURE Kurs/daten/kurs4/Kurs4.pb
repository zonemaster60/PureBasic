IncludeFile "InitSystem.pb"  
IncludeFile "InitGame.pb"  
                        





;MainLoop ######################################

Repeat
ExamineKeyboard() 


DisplaySprite(#Sprite_Back, 0, 0) 
                                  
                                  
                                  
Gosub steuerung 
Gosub playershots
Gosub enemy


StartDrawing(ScreenOutput()) : DrawingMode(1)   
  FrontColor(200,100,0)
  DrawText("ESC-Ende")
  ;Wir zeigen hier zusätzlich die Anzahl aller Gegner und Schüsse an
  Locate(10,100) : DrawText("Anzahl Gegner: " + Str(CountList(enemy()))) 
  Locate(10,120) : DrawText("Anzahl Schüsse: " + Str(CountList(playershot())))  
StopDrawing()


DisplayTransparentSprite(#Sprite_Player, playerX, playerY)

FlipBuffers() 
Until KeyboardReleased(#PB_Key_Escape) : End 

;MainLoop ENDE ##################################











;-Sub Steuerung ####
steuerung:

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

 

If KeyboardPushed(#PB_Key_LeftControl) And shootDelay = 0 
  AddPlayershot(playerX+25, playerY-3, 10, 0)   
  AddPlayershot(playerX+25, playerY+16, 10, 0) 

  shootDelay = 15            
  PlaySound(#Sound_Blaster)                    
EndIf
  

If shootDelay > 0 : shootDelay - 1 : EndIf 

Return










;-Sub Playershots ##########################

playershots:

 

  ForEach(playershot())
    If      playershot()\x > 800   : DeleteElement(playershot())
    ElseIf playershot()\x < 0     : DeleteElement(playershot())
    ElseIf playershot()\y > 600   : DeleteElement(playershot())
    ElseIf playershot()\y < 0     : DeleteElement(playershot())
    EndIf
  Next

  
   
  ForEach(playershot())
    DisplayTransparentSprite(#Sprite_Blaster, playershot()\x, playershot()\y)   
    playershot()\x + playershot()\speedX
    playershot()\y + playershot()\speedY
  Next

Return






;-Sub Enemy #################################

enemy:
 
;Falls enemyDelay = 0 ist, einen Gegner mit Geschwindigkeit -2 und einem Rüstungswert von 100
;erstellen und enemyDelay wieder hochsetzen, ansonsten enemyDelay um 1 verringern
;Die y position wird per Random() zufällig ermittelt.

If enemyDelay = 0
  AddEnemy(800, Random(560), -2, 0, 100) 
  enemyDelay = enemySetDelay
Else
  enemyDelay - 1
EndIf


;Checken ob der Gegner links aus dem Bild geflogen ist, wenn ja dann löschen wir ihn.
ForEach enemy()
  If enemy()\x < 0-SpriteWidth(#Sprite_Enemy) : DeleteElement(enemy()) : EndIf
Next


;Alle Gegner auf den Bildschirm ausgeben und nach links bewegen.
ForEach enemy()
    DisplayTransparentSprite(#Sprite_Enemy, enemy()\x, enemy()\y)
    enemy()\x + enemy()\speedX
Next


;Wir benutzen hier 2 getrennte ForEach Schleifen, da ansonsten immer der
;letzte Gegner kurz flimmert, wenn ein anderer das Bild verlässt.
;
;Das liegt daran, daß nach dem löschen eines Listenelementes, alle anderen nachrücken
;und somit immer 1 Gegner bei der Darstellung ausgelassen würde.

Return







; ExecutableFormat=Windows
; DisableDebugger
; EOF