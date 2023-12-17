;-Variablen #################################################################

Global playerX.l   
Global playerY.l  
Global playerSpeed.l 
Global playerLife.l    ;Neu, um die Leben des Spielers zu speichern
Global shootDelay.l   
Global enemyDelay.l  
Global enemySetDelay.l 
Global score.l         ;Neu, um die erreichten Punkte zu speichern


playerX = 0     
playerY = 300    
playerSpeed = 4  
playerLife = 3          ;Neu, Der Spieler hat am Anfang 3 Leben

enemySetDelay = 100  





;-Konstanten #################################################################

Enumeration    
  #Sprite_Player   
  #Sprite_Back
  #Sprite_Blaster  
  #Sprite_Enemy   
  
  #Sound_Blaster
  #Sound_Explosion  ;Neu, für den Explosionssound
  #Sound_Hit        ;Neu, für den Sound, wenn man einen Gegner getroffen hat
  
  #Module_Mucke     ;Neu, für die Hintergrundmusik
EndEnumeration





;-Strukturen und Listen ######################################################

Structure playershot  
  x.l                   
  y.l
  speedX.l
  speedY.l
EndStructure
NewList playershot.playershot()  

Structure enemy    
  x.l          
  y.l
  speedX.l
  speedY.l
  armor.l      
EndStructure 
NewList enemy.enemy()   





;-Prozeduren ##################################################################

Procedure AddEnemy(x, y, speedX, speedY, armor)
  AddElement(enemy())  
  enemy()\x = x
  enemy()\y = y
  enemy()\speedX = speedX
  enemy()\speedY = speedY
  enemy()\armor = armor 
EndProcedure

Procedure AddPlayershot(x, y, speedX, speedY)  
  AddElement(playershot())       
  playershot()\x = x             
  playershot()\y = y      
  playershot()\speedX = speedX
  playershot()\speedY = speedY
EndProcedure





;-Grafiken und Sounds #########################################################

LoadSprite(#Sprite_Player,  "..\GFXSND\player.bmp") 
LoadSprite(#Sprite_Blaster, "..\GFXSND\blaster.bmp")    
LoadSprite(#Sprite_Back,    "..\GFXSND\back.bmp")     
LoadSprite(#Sprite_Enemy,   "..\GFXSND\gegner.bmp")   

LoadSound(#Sound_Blaster,   "..\GFXSND\blaster.wav")     
LoadSound(#Sound_Hit,       "..\GFXSND\hit.wav")            ;2 Neue Sounds für treffer
LoadSound(#Sound_Explosion, "..\GFXSND\explosion.wav")      ;und Zerstörung der Gegner

LoadModule(#Module_Mucke,   "..\GFXSND\humatarg.mod")       ;Lädt unsere Musik




; ExecutableFormat=Windows
; EOF