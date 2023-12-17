IncludeFile "InitSystem.pb"  
IncludeFile "InitGame.pb"  
                        

PlayModule(#Module_Mucke)   ;Dieser Befehl lässt unsere Musik ablaufen



;MainLoop ######################################

Repeat
ExamineKeyboard() 

DisplaySprite(#Sprite_Back, 0, 0) 


;Falls unser Lied zu Ende ist, lassen wir es einfach wieder an
;einer passenden Stelle am Anfang einsteigen.
If GetModulePosition() = 41 : SetModulePosition(5) : EndIf   

;Wenn der Spieler keine Leben mehr hat, wird das
;Programm einfach beendet und eine Messagebox ausgegeben.
If playerLife < 0
  CloseScreen()
  MessageRequester("Du bist tot..", "Schade! Deine erreichten Punkte: " + Str(score), 0)
  End
EndIf
                                                                  
                                 
Gosub steuerung 
Gosub playershots
Gosub enemy
Gosub collisions   ;Neu, hier werden alle Kollisionsabfragen von statten gehen
Gosub drawing      ;Neu, die Drawingbefehle sind in einem Sub verschwunden

DisplayTransparentSprite(#Sprite_Player, playerX, playerY)

FlipBuffers() 
Until KeyboardReleased(#PB_Key_Escape) : End 

;MainLoop ENDE ##################################











;-Sub Steuerung ##################################
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

  If KeyboardPushed(#PB_Key_Down) And playerY < 565 -SpriteHeight(#Sprite_Player) ;Neu angepasst wegen
    playerY + playerSpeed                                                          ;schwarzer Box
  EndIf

 

  If KeyboardPushed(#PB_Key_LeftControl) And shootDelay = 0 
    AddPlayershot(playerX+25, playerY-3, 10, 0)   
    AddPlayershot(playerX+25, playerY+16, 10, 0) 
    PlaySound(#Sound_Blaster) : shootDelay = 15                             
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

  If enemyDelay = 0
    AddEnemy(800, Random(560), -2, 0, 100) 
    enemyDelay = enemySetDelay
  Else
    enemyDelay - 1
  EndIf


  ForEach enemy()
    If enemy()\x < 0-SpriteWidth(#Sprite_Enemy) : DeleteElement(enemy()) : EndIf
    ;Neu, wenn die Rüstung des Gegners kleiner als 0 ist, wird selbiger zerstört,
    ;ein explosionssound abgespielt und 150 Punkte addiert.
    If enemy()\armor < 1
      DeleteElement(enemy())
      PlaySound(#Sound_Explosion)
      score + 150
    EndIf
  Next


  ForEach enemy()
    DisplayTransparentSprite(#Sprite_Enemy, enemy()\x, enemy()\y)
    enemy()\x + enemy()\speedX
  Next


Return




;-Sub Collisions ###########################

collisions:

;Diese 2 verschachtelten ForEach Schleifen testen Jeden einzelnen
;Gegner mit jedem einzelnen Schuss und dem Player auf Kollisionen.

ForEach enemy()

  ForEach playershot()
    ;Falls eine Kollision stattgefunden hat, den treffersound abspielen,
    ;20 Punkte von der Rüstung des Gegners abziehen und zu guter letzt
    ;den Schuss löschen.
    If SpriteCollision(#Sprite_Blaster, playershot()\x, playershot()\y, #Sprite_Enemy, enemy()\x, enemy()\y)
      PlaySound(#Sound_Hit)
      enemy()\armor - 20
      DeleteElement(playershot())
    EndIf
  Next
 
  ;Bei einer Kollision des Spielers mit dem Gegner, ziehen wir letzterem 100 Rüstungspunkte und 
  ;dem Spieler ein Leben ab  
  If SpriteCollision(#Sprite_Player, playerX, playerY, #Sprite_Enemy, enemy()\x, enemy()\y)
    PlaySound(#Sound_Explosion)
    enemy()\armor - 100 
    playerLife - 1           
  EndIf

Next


   
 

Return





;-Sub Drawing ###########################

drawing:

StartDrawing(ScreenOutput()) : DrawingMode(1)   
;Neu, am unteren Rand eine schwarze platzhalter-box malen
;um Punkte und ähnliches anzeigen zu können

  FrontColor(0,0,0) : Box(0, 570, 800, 30)     

  FrontColor (200,200,200) 
  Locate(360, 575) : DrawText(Str(playerLife))
  Locate(100, 575) : DrawText(Str(score))

  FrontColor(200,100,0) 
  Locate(300, 575) : DrawText("Lives:")
  Locate(10, 575) : DrawText("SCORE:")
  
  Locate(0, 0)   : DrawText("ESC-Ende")
  Locate(10,100) : DrawText("Anzahl Gegner: " + Str(CountList(enemy()))) 
  Locate(10,120) : DrawText("Anzahl Schüsse: " + Str(CountList(playershot())))  
StopDrawing()

Return








; ExecutableFormat=Windows
; DisableDebugger
; EOF