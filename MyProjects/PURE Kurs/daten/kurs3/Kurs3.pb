IncludeFile "InitSystem.pb"  
                        



Global playerX.l   
Global playerY.l  
Global playerSpeed.l  


Global shootDelay.l    ;Diese Variable wird dazu eingesetzt, die Schussfolge des Raumschiffs
                        ;zu kontrollieren.Umso größer sie nach jedem Schuss gesetzt 
                        ;wird (im Sub "steuerung"), desto langsamer schießt das Schiff.



playerX = 0     
playerY = 300    
playerSpeed = 4  




Structure playershot   ;Unsere erste Struktur. Sie ist nötig um alle erforderlichen
  x.l                   ;informationen über die Blasterschüsse zu speichern
  y.l
  speedX.l
  speedY.l
EndStructure




NewList playershot.playershot()  ;Die Liste "playershot" erbt die Eigenschaften der 
                                  ;Struktur "playershot"




Procedure AddPlayershot(x, y, speedX, speedY)  ;Eine Prozedur zur Vereinfung der Weiteren Arbeit
  AddElement(playershot())        ;Hier wird ein neues Listenelement erzeugt und im folgenden die
  playershot()\x = x              ;einzelnen Variablen deklariert.
  playershot()\y = y      
  playershot()\speedX = speedX
  playershot()\speedY = speedY
EndProcedure

;Mit Procedure haben wir im Prinzip einen eigenen Befehl erstellt, dem wir 4 Variablen
;übergeben müssen. Die Syntax lautet hier: 
; AddPlayershot(Xposition, Yposition, Xgeschwindigkeit, Ygeschwindigkeit)





Enumeration    
  #Sprite_Player   
  #Sprite_Back
  #Sprite_Blaster  

  #Sound_Blaster
EndEnumeration



LoadSprite(#Sprite_Player,  "..\GFXSND\player.bmp") 
LoadSprite(#Sprite_Blaster, "..\GFXSND\blaster.bmp")     ;Laden der Schussgrafik
LoadSprite(#Sprite_Back,    "..\GFXSND\back.bmp")     

LoadSound(#Sound_Blaster,   "..\GFXSND\blaster.wav")       ;Laden des Blastersounds






;MainLoop ######################################

Repeat
ExamineKeyboard() 


DisplaySprite(#Sprite_Back, 0, 0) 
                                  
                                  
                                  
Gosub steuerung 
Gosub playershots


StartDrawing(ScreenOutput()) : DrawingMode(1)   
  FrontColor(200,0,0)
  DrawText("ESC-Ende") 
StopDrawing()


DisplayTransparentSprite(#Sprite_Player, playerX, playerY)

FlipBuffers() 
Until KeyboardReleased(#PB_Key_Escape) : End 

;MainLoop ENDE ##################################












;-Subs

;-Steuerung ####
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


  ;Hier wird die linke STRG taste abgefragt und kontrolliert, ob die Variable
  ;shootDelay schon 0 ist. Falls sie 0 ist, wird ein neuer Schuss abgegeben
  ;und schootDelay wieder auf z.B. 15 gesetzt

If KeyboardPushed(#PB_Key_LeftControl) And shootDelay = 0 
  AddPlayershot(playerX+25, playerY-3, 10, 0)   ;Mit diesem Befehl wird unsere oben erzeugte Prozedur
  AddPlayershot(playerX+25, playerY+16, 10, 0)  ;aufgerufen und die übergebenen Variablen zugewiesen.

  shootDelay = 15            
  PlaySound(#Sound_Blaster)                      ;Blastersound 1 mal abspielen
EndIf
  

If shootDelay > 0 : shootDelay - 1 : EndIf ;Falls schootDelay größer als 0 ist, wird sie um 1 reduziert.


Return










;-Playershots #####

playershots:

  ;Alle schüsse checken ob sie den Bildschirm verlassen haben, wenn dem so ist,
  ;löschen wir ihn einfach (bzw. Seine Liste)

  ForEach(playershot())
    If      playershot()\x > 800   : DeleteElement(playershot())
    ElseIf playershot()\x < 0     : DeleteElement(playershot())
    ElseIf playershot()\y > 600   : DeleteElement(playershot())
    ElseIf playershot()\y < 0     : DeleteElement(playershot())
    EndIf
  Next


  ;Alle Schüsse die noch auf dem Bildschirm sind, werden nun angezeigt und
  ;um den Wert der in speedX u. speedY gespeichert ist, versetzt.
  
   
  ForEach(playershot())
    DisplayTransparentSprite(#Sprite_Blaster, playershot()\x, playershot()\y)   
    playershot()\x + playershot()\speedX
    playershot()\y + playershot()\speedY
  Next



Return


; ExecutableFormat=Windows
; DisableDebugger
; EOF