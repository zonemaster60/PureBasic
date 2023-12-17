;-Variablen #################################################################

Global playerX.l   
Global playerY.l  
Global playerSpeed.l 
Global shootDelay.l   
Global enemyDelay.l    ;Diese Variable wird benötigt, um die Menge an Gegnern, 
                        ;die auftauchen, zu regulieren 
Global enemySetDelay.l ;Auf diesen Wert wird enemyDelay gesetzt, nachdem ein Gegner eingefügt wurde

playerX = 0     
playerY = 300    
playerSpeed = 4  

enemySetDelay = 100  ;Neu




;-Konstanten #################################################################

Enumeration    
  #Sprite_Player   
  #Sprite_Back
  #Sprite_Blaster  
  #Sprite_Enemy    ;Neue Konstante für das Gegner-Sprite
  
  #Sound_Blaster
EndEnumeration




;-Strukturen und Listen ######################################################

Structure playershot  
  x.l                   
  y.l
  speedX.l
  speedY.l
EndStructure
NewList playershot.playershot()  


;Dies ist die Struktur für die Gegner
Structure enemy    
  x.l          
  y.l
  speedX.l
  speedY.l
  armor.l      ;Die Armor(Rüstung) des Gegners wird mit jedem Treffer reduziert und wenn sie
EndStructure  ;0 oder kleiner ist, dann ist der Gegner zerstört.

;Dies ist die Liste für die Gegner
NewList enemy.enemy()   





;-Prozeduren ##################################################################

;Dies ist die Prozedur für die Gegner
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
LoadSprite(#Sprite_Enemy,   "..\GFXSND\gegner.bmp")   ;laden des Gegner-Sprites    

LoadSound(#Sound_Blaster, "..\GFXSND\blaster.wav")     




; ExecutableFormat=Windows
; EOF