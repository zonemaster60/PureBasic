IncludeFile "InitSystem.pb"  
IncludeFile "InitGame.pb"  
                        

PlayModule(#Module_Mucke)  



;MainLoop ######################################

Repeat
ExamineKeyboard() 

DisplaySprite(#Sprite_Back, 0, 0) 

If GetModulePosition() = 41 : SetModulePosition(5) : EndIf   

If playerLife < 0
  CloseScreen()
  MessageRequester("Du bist tot..", "Schade! Deine erreichten Punkte: " + Str(score), 0)
  End
EndIf
                                                                  
         
Gosub steuerung 
Gosub playershots
Gosub enemy
Gosub collisions
Gosub explosions   ;Neu, springt zum Sub Explosions  
Gosub drawing     


;Dies erzeugt den Antrieb für den Player
;Die Antriebe für die Gegner werden im Sub "Enemy" erzeugt.
AddExplo(playerX-10, 6+playerY+Random(6)-3, Random(3)-3, 0, 120, 122, 2) 


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

  If KeyboardPushed(#PB_Key_Down) And playerY < 565 -SpriteHeight(#Sprite_Player) 
    playerY + playerSpeed                                                         
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
    AddEnemy(800, Random(560), -2-Random(1), 0, 100)   ;Neu, die Geschwindigkeit wird zufällig verändert 
    enemyDelay = enemySetDelay
  Else
    enemyDelay - 1
  EndIf


  ForEach enemy()
    If enemy()\x < 0-SpriteWidth(#Sprite_Enemy) : DeleteElement(enemy()) : EndIf
 
    If enemy()\armor < 1
      
;Neu, wenn ein Gegner zerstört wurde, erfolgen Explosionen und Partikel
      For i = 1 To 4   
        AddExplo(enemy()\x+15, enemy()\y, Random(6)-3, Random(6)-3, 100, 108, 2)  
        AddExplo(enemy()\x+15, enemy()\y, Random(10)-5, Random(10)-5, 110, 113, 5) 
      Next
;Zusätlich lassen wir noch einige Splitter wegspritzen      
      AddExplo(enemy()\x+15, enemy()\y, Random(10)-5, Random(10)-5, 140, 140, 25) 
      AddExplo(enemy()\x+15, enemy()\y, Random(10)-5, Random(10)-5, 141, 141, 25) 
      AddExplo(enemy()\x+15, enemy()\y, Random(10)-5, Random(10)-5, 142, 142, 25)  
      AddExplo(enemy()\x+15, enemy()\y, Random(10)-5, Random(10)-5, 143, 143, 25)  

      DeleteElement(enemy())
      PlaySound(#Sound_Explosion)
      score + 150
    EndIf
  Next


  ForEach enemy()
    ;Hier werden jetzt zusätzlich die Antriebe für die Gegner erzeugt
    AddExplo(enemy()\x+SpriteWidth(#Sprite_Enemy), enemy()\y+7+Random(6)-3, Random(3)+1, 0, 130, 132, 3) 
    
    DisplayTransparentSprite(#Sprite_Enemy, enemy()\x, enemy()\y)
    enemy()\x + enemy()\speedX
  Next

Return






;-Sub Collisions ###########################

collisions:

ForEach enemy()

  ForEach playershot()
    If SpriteCollision(#Sprite_Blaster, playershot()\x, playershot()\y, #Sprite_Enemy, enemy()\x, enemy()\y)
      PlaySound(#Sound_Hit)
      enemy()\armor - 20
      DeleteElement(playershot())
    EndIf
  Next
 
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
  FrontColor(0,0,0) : Box(0, 570, 800, 30)     

  FrontColor (200,200,200) 
  Locate(360, 575) : DrawText(Str(playerLife))
  Locate(100, 575) : DrawText(Str(score))

  FrontColor(200,100,0) 
  Locate(300, 575) : DrawText("Lives:")
  Locate(10, 575) : DrawText("SCORE:")
  
 
  ;Neu, Der Text für die Anzahl Gegner und Schüsse ist entfernt (Schönheitsmaßnahme)
  
  
StopDrawing()

Return





;-Sub Explosions ###########################

explosions:

;Hier werden also all unsere Explosionen und Partikel für die Antriebe
;verarbeitet und angezeigt.

;Die ForEach Schleife arbeitet alle Listenelemente durch, setzt oder löscht
;sie und "handelt" die Animation.

;So kann an beliebiger Stelle im Spiel einfach der Befehl AddExplo() benutzt
;werden, ohne daß man sich jedesmal um den genauen Ablauf kümmern muss.


  ForEach(explo())
    
    DisplayTransparentSprite(explo()\spriteStart, explo()\x, explo()\y)
    explo()\x + explo()\speedX : explo()\y + explo()\speedY

    If explo()\spriteStart = explo()\spriteEnd And explo()\delay = 1 
      DeleteElement(explo()) 
    ElseIf explo()\delay > 0 
      explo()\delay - 1
    Else
      explo()\delay = explo()\animSpeed
      explo()\spriteStart+1
    EndIf
    
  Next
  
Return






; ExecutableFormat=Windows
; Executable=C:\Dokumente und Einstellungen\Udo\Desktop\PURE Kurs\Kurs 6\Kurs6.exe
; DisableDebugger
; EOF