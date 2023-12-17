;-Variablen #################################################################

Global playerX.l   
Global playerY.l  
Global playerSpeed.l 
Global playerLife.l    
Global shootDelay.l   
Global enemyDelay.l  
Global enemySetDelay.l 
Global score.l 

Global level.l       ;Neu, unsere beiden Variablen für den Schwierigkeitsgrad
Global levelUP.l     ;


playerX = 0     
playerY = 300    
playerSpeed = 4  
playerLife = 3 

enemySetDelay = 100  






;-Konstanten #################################################################

Enumeration    
  #Sprite_Player   
  #Sprite_Back
  #Sprite_Blaster  
  #Sprite_Enemy   
  
  #Sound_Blaster
  #Sound_Explosion  
  #Sound_Hit       
  #Sound_LevelUP    ;Neu, unser Sound wenn ein neuer Level erreicht wird.
  
  #Module_Mucke    
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

Structure explo   
  x.l           
  y.l
  speedX.l
  speedY.l
  spriteStart.l     
  spriteEnd.l      
  animSpeed.l       
  delay.l          
EndStructure       
NewList explo.explo() 




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

Procedure AddExplo(x, y, speedX, speedY, spriteStart, spriteEnd, animSpeed)
  AddElement(explo())
  explo()\x = x
  explo()\y = y
  explo()\speedX = speedX
  explo()\speedY = speedY
  explo()\spriteStart = spriteStart
  explo()\spriteEnd = spriteEnd
  explo()\animSpeed = animSpeed
  explo()\delay = animSpeed
EndProcedure






;-Grafiken und Sounds #########################################################

LoadSprite(#Sprite_Player,  "..\GFXSND\player.bmp") 
LoadSprite(#Sprite_Blaster, "..\GFXSND\blaster.bmp")    
LoadSprite(#Sprite_Back,    "..\GFXSND\back.bmp")     
LoadSprite(#Sprite_Enemy,   "..\GFXSND\gegner.bmp")   

For i = 100 To 108 : LoadSprite(i,   "..\GFXSND\explo" + Str(i-99) + ".bmp")         : Next
For i = 110 To 113 : LoadSprite(i,   "..\GFXSND\particle" + Str(i-109) + ".bmp")     : Next
For i = 120 To 122 : LoadSprite(i,   "..\GFXSND\antrieba" + Str(i-119) + ".bmp")     : Next
For i = 130 To 132 : LoadSprite(i,   "..\GFXSND\antriebb" + Str(i-129) + ".bmp")     : Next
For i = 140 To 143 : LoadSprite(i,   "..\GFXSND\gegner_split" + Str(i-139) + ".bmp") : Next


LoadSound(#Sound_Blaster,   "..\GFXSND\blaster.wav")     
LoadSound(#Sound_Hit,       "..\GFXSND\hit.wav")           
LoadSound(#Sound_Explosion, "..\GFXSND\explosion.wav")     
LoadSound(#Sound_LevelUP,   "..\GFXSND\levelup.wav")     ;Neu, unser Level-UP-sound

LoadModule(#Module_Mucke,   "..\GFXSND\humatarg.mod")      




; ExecutableFormat=Windows
; EOF