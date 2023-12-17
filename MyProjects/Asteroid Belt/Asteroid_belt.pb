#WINDOW_MAIN=1
UsePNGImageDecoder()
UseOGGSoundDecoder()

If InitSprite() = 0 Or InitKeyboard() = 0
  MessageRequester("Error", "Can't open DirectX 7 or later",#PB_MessageRequester_Error)
  End
EndIf

If InitSound() = 0
  MessageRequester("Error", "Can't open DirectX 7 Or Sound Card is not present",#PB_MessageRequester_Error)
  End
EndIf

If InitJoystick()
  EnableJoystick = 1
EndIf

Structure STAR
    xPos.f
    yPos.f
    yStep.f
    Color.l
EndStructure
  
Global NewList STAR.STAR()
#NUMBER_OF_STARS=150

Global ScrW.l=640 
Global ScrH.l=480
Global GameOver=0
Global Fade.w
Global FadeMode.w
Global VolFx.f = 5 ;30
Global VolMusic.f =2 ;6
Global VolVoice.f = 5;30
Global PlayerXdelta.f

Structure Bullet
  x.w
  y.w
  Width.w
  Height.w
  SpriteId.w
  Image.w
  ImageStart.w
  ImageEnd.w
  ImageDelay.w
  ImageDelayCur.w
  ImageAnim.b
  SpeedX.w
  SpeedY.w
  BulletDamage.w
  BulletDestr.b
  Lenght.w
EndStructure

Global NewList Bullet.Bullet()

Global Score.i, Boss.i, Weapone.w, WeaponeMax.w, BlackHoleCur.w, BlackHoleX.w, BlackHoleY.w

Global Dim LevelScore(5) ; 5 level at all
LevelScore(0)=20000
LevelScore(1)=40000

Global Dim StepEngine(11)
StepEngine(5)=30
StepEngine(4)=33
StepEngine(3)=36
StepEngine(2)=38
StepEngine(1)=38
StepEngine(0)=38
StepEngine(6)=33
StepEngine(7)=36
StepEngine(8)=38
StepEngine(9)=38
StepEngine(10)=38

Global Dim WeaponeDamage.w (5)
  WeaponeDamage(0) = 1
  WeaponeDamage(1) = 3
  WeaponeDamage(2) = 50
  
Global Dim WeaponeDelay.w (5)
  WeaponeDelay(0) = 5
  WeaponeDelay(1) = 8 
  WeaponeDelay(2) = 17
  
Global Dim WeaponeUsedStep.f (5)
  WeaponeUsedStep(0) = 0.45
  WeaponeUsedStep(1) = 0.55
  WeaponeUsedStep(2) = 0.75 
  
Global Dim WeaponeRecoverStep.f (5)
  WeaponeRecoverStep(0) = 0.05
  WeaponeRecoverStep(1) = 0.05
  WeaponeRecoverStep(2) = 0.05
  
  Global Dim BonusStage.l (10)
  ; 1-score , 2-flameweapone, 3- wireweapone ,4 - hart, 5 - mine, 6 - laser
  BonusStage(0) = 0
  BonusStage(1) = 0
  BonusStage(2) = 1000
  BonusStage(3) = 5000
  BonusStage(4) = 1000
  BonusStage(5) = 2000
  BonusStage(6) = 10000
  
  Global Dim BonusE.w (41)
  ; 1-score , 2-flameweapone, 3- wireweapone ,4 - hart, 5 - mine, 6 - laser
  BonusE(0) = 0
  BonusE(1) = 1
  BonusE(2) = 0
  BonusE(3) = 0
  BonusE(4) = 0
  BonusE(5) = 0
  BonusE(6) = 2
  BonusE(7) = 0
  BonusE(8) = 0
  BonusE(9) = 0
  BonusE(10) = 0
  BonusE(11) = 2
  BonusE(12) = 1
  BonusE(13) = 0
  BonusE(14) = 0
  BonusE(15) = 5
  BonusE(16) = 0
  BonusE(17) = 0
  BonusE(18) = 1
  BonusE(19) = 4  
  BonusE(20) = 5
  BonusE(21) = 0  
  BonusE(22) = 0
  BonusE(23) = 0
  BonusE(24) = 3
  BonusE(25) = 1
  BonusE(26) = 0
  BonusE(27) = 0
  BonusE(28) = 0
  BonusE(29) = 1
  BonusE(30) = 0
  BonusE(31) = 0
  BonusE(32) = 2
  BonusE(33) = 0
  BonusE(34) = 0
  BonusE(35) = 6
  BonusE(36) = 0
  BonusE(37) = 3
  BonusE(38) = 0
  BonusE(39) = 1
  BonusE(40) = 4
    
Structure Explosion
  x.w
  y.w
  State.w
  Delay.w  
EndStructure

Global NewList Explosion.Explosion()
Global NewList ExplMine.Explosion()

Structure Bonus
  ItemId.w
  x.w
  y.w
  Width.w
  Height.w
  Speed.w  
  Lenght.w
  StartImage.w
  EndImage.w
  State.w
  Delay.w
  NextDelay.w
  LifeDelay.w
EndStructure

Global NewList Bonus.Bonus()  

Structure Alien
  x.f
  y.f
  Width.w
  Height.w
  SpeedY.f 
  SpeedX.f   
  SpriteId.w
  Lenght.w
  StartImage.w
  EndImage.w
  ImageDelay.w
  NextImageDelay.w
  ActualImage.w
  Armor.w
  Damage.w
  rotate.w
  LimitX.w
  LimitXcur.f
  intense.w
  SoundID.w
EndStructure

Procedure JustExit()
  Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
  If Req = #PB_MessageRequester_Yes
    End
  EndIf
EndProcedure

Global NewList Aliens.Alien()

Procedure InitializeStars()  
  x=0
  While ListSize(STAR())<#NUMBER_OF_STARS    
    AddElement(STAR()) 
    x=x+1
       
        If x<#NUMBER_OF_STARS/3
            STAR()\yStep=(Random(10)/100)+0.2
            STAR()\Color=RGB(40, 40, 40)
        ElseIf x>=#NUMBER_OF_STARS/3 And x<(#NUMBER_OF_STARS/3)*2
            STAR()\yStep=(Random(10)/100)+0.6
            STAR()\Color=RGB(100, 100, 100)
        Else
            STAR()\yStep=(Random(10)/100)+1.2
            STAR()\Color=RGB(255, 255, 255)
        EndIf
        STAR()\xPos=Random(ScrW-1)
        STAR()\yPos=Random(ScrH-STAR()\yStep-1)
    Wend
EndProcedure
  
Procedure MoveStarsY()
    ResetList(STAR())    
     While NextElement(STAR())   
       If STAR()\yPos >= ScrH-STAR()\yStep-1
          STAR()\xPos=Random(ScrW-1)
          STAR()\yPos=Random(ScrH-STAR()\yStep-1)
      Else
        STAR()\yPos+STAR()\yStep        
        Plot(STAR()\xPos, STAR()\yPos, STAR()\Color)         
       EndIf
     Wend    
EndProcedure

Procedure AddBullet(Sprite, x, y, SpeedX, SpeedY,BulletDamage)
  AddElement(Bullet())
  Bullet()\ImageAnim=0
  Bullet()\SpriteId=212
  Bullet()\x      = x
  Bullet()\y      = y
  Bullet()\Width  = 22
  Bullet()\Height = 22
  Bullet()\Image  = Sprite
  Bullet()\SpeedX = SpeedX
  Bullet()\SpeedY = SpeedY
  Bullet()\BulletDamage = BulletDamage
  Bullet()\BulletDestr = 0
EndProcedure
    
Procedure AddBlackHole(Activ,x,y)
  If Activ=0
    BlackHoleX=x
    BlackHoleY=y
    BlackHoleCur=0
    PlaySound(32, 0, VolFx)  
    ProcedureReturn 1
  EndIf
EndProcedure

Procedure GrabSpriteToSrite(SpriteIdSource,SpriteIdTarget,SpriteStart,SpriteEnd,SpriteWidth,SpriteHeight,SpriteLenght)
  For i=SpriteStart To SpriteEnd
    CreateSprite(SpriteIdTarget+i,SpriteWidth,SpriteHeight,#PB_Sprite_AlphaBlending | #PB_Sprite_PixelCollision)
    StartDrawing(SpriteOutput(SpriteIdTarget+i))
    DrawingMode(#PB_2DDrawing_AllChannels )
      DrawImage(ImageID(SpriteIdSource),-((i-(Int(i/SpriteLenght)*SpriteLenght))*SpriteWidth),-(Int(i/SpriteLenght)*SpriteHeight),ImageWidth(SpriteIdSource) ,ImageHeight(SpriteIdSource))
      StopDrawing()      
  Next i
EndProcedure

Path$ = "Data\"
#FLAGS=#PB_Window_SystemMenu | #PB_Window_ScreenCentered

If OpenWindow(#WINDOW_MAIN, 0, 0, ScrW, ScrH, "Asteroid Belt", #FLAGS)
  OpenWindowedScreen(WindowID(#WINDOW_MAIN), 0, 0, ScrW, ScrH, 0, 0, #PB_Screen_WaitSynchronization) 

;//ADD FONT
If(OpenLibrary(0, "GDI32.DLL"))
CallFunction(0, "AddFontMemResourceEx", ?fs, (?fe -?fs), 0, @i +1) : CloseLibrary(0)
Else : MessageRequester("E.R.R.O.R.","font problem...") : End : EndIf
;LoadFont(0,"G7 Silkworm TTF",8)
LoadFont(0,"Counter-Strike",12)
LoadFont(1,"Counter-Strike",36)
  ; Load sprites, sounds..
  ;
CatchImage(0,?_TitlePicture)
CatchImage(1,?_TitlePicture2)

  length = ?_SndDubEnd - ?_SndDubStart  
  CatchSound(0,?_SndDubStart,length) 
  CatchSound(1,?_SndTum) 
  CatchSound(2,?_SndExpl)  
  length = ?End_snda - ?Start_snda
  CatchSound(3, ?Start_snda,length)
  CatchSound(4,?_SndWarnAster)
  CatchSound(5,?_SndShieldDeactiv)
  CatchSound(6,?_SndGunFireball)
  CatchSound(7,?_SndGunflamethrower)
  CatchSound(8,?_SndStoneSwoosh)
  CatchSound(9,?_SndShieldDown)
  CatchSound(10,?_SndLazer)
  CatchSound(11,?_SndFireballshoot)
  CatchSound(12,?_SndLazer)
  ;12-19 shoot
  CatchSound(20,?_SndWood) ;звук попадания в _Alien
  CatchSound(21,?_SndWood2) ;звук попадания в _Alien  
  CatchSound(22,?_SndIron) ;звук попадания в _Alien2
  CatchSound(23,?_SndIron2) ;звук попадания в _Alien2 
  CatchSound(24,?_SndWood) ;звук попадания в _Stone1
  CatchSound(25,?_SndWood2) ;звук попадания в _Stone1
  ;20-29
  CatchSound(30,?_SndExpl2) ; взрыв мины
  CatchSound(31,?_SndGunLaser) 
  CatchSound(32,?_SndBlackHole); звук BlackHole
  
  PlayerWidth  = 90 
  PlayerHeight = 90
  PlayerLenght=6
  PlayerImage=200+5
  ;---------------CATCH SPRITES--------------------------------------
  
  ;200-211
  CatchImage(3, ?_Ship1)
  GrabSpriteToSrite(3,200,0,11,PlayerWidth,PlayerHeight,PlayerLenght)
  FreeImage(3)
  ;212-220
  CatchImage(4, ?_Fire1)
  GrabSpriteToSrite(4,212,0,8,22,22,3)
  FreeImage(4)
  ;221-250
  CatchImage(10, ?_Alien)
  GrabSpriteToSrite(10,221,0,29,64,64,5)
  FreeImage(10)
  ;251-280
  CatchImage(11, ?_Alien2)
  GrabSpriteToSrite(11,251,0,29,80,80,5)
  FreeImage(11)
  ;281-296
  CatchImage(12, ?_Stone1)
  GrabSpriteToSrite(12,281,0,15,64,64,4)
  FreeImage(12)
  ;297-316
  CatchImage(13, ?_BlackHole)
  GrabSpriteToSrite(13,297,0,19,200,200,5)
  FreeImage(13)
  ;317-348
  CatchImage(20, ?_Expl1)
  GrabSpriteToSrite(20,317,0,31,128,128,4)
  FreeImage(20)
  ;349-378
  CatchImage(21, ?_Expl2)
  GrabSpriteToSrite(21,349,0,29,160,160,5)
  FreeImage(21)
  ;379-384
  CatchImage(30, ?_Laser)
  GrabSpriteToSrite(30,379,0,5,128,128,6)
  FreeImage(30)
  ;385-394
  CatchImage(40, ?_Engine)
  GrabSpriteToSrite(40,385,0,9,20,55,5)
  FreeImage(40)
  ;394-465
  CatchImage(50, ?_Bonus)
  GrabSpriteToSrite(50,394,0,71,32,32,12)
  FreeImage(50)
  ;466-485
  CatchImage(51, ?_Shield)
  GrabSpriteToSrite(51,466,0,19,128,128,5)
  FreeImage(51)
  
  CatchSprite(52, ?_ShieldMask, #PB_Sprite_PixelCollision)  
  CatchSprite(56, ?_Pl1,#PB_Sprite_AlphaBlending)
  CatchSprite(57, ?_Pl2,#PB_Sprite_AlphaBlending)
  
  ;100-101 used
  
  SetFrameRate(60)
  CreateSprite(101 ,10,25)
    StartDrawing(SpriteOutput(101))
      
      Box(0,0,10,25,RGB(255,0,0))    ;
      
     StopDrawing()
     TransparentSpriteColor(101, RGB(255,255,255))
     
  CreateSprite(100 ,ScrW,ScrH)
    StartDrawing(SpriteOutput(100))
      
      Box(0,0,ScrW,ScrH,RGB(0,0,0))
        
      StopDrawing()
      TransparentSpriteColor(100, RGB(255,255,255)) ;COVER!! 
      FpsActiv=0
      
  START: 
  Fade =255
  FadeMode =10    
  GameOver =0
  TitleQuit=0
  SoundSetup=0
  SoundSetupY=0
  SoundSetupX=0
  SoundVolume(3,0)
  SoundVolume(0,VolMusic)
      ClearScreen(RGB(0, 0, 0))      
      InitializeStars()      
      x=0
      i=0
      Repeat
        
      x+1
      If i<327
        i+1
      EndIf
        ExamineKeyboard()
         Event = WaitWindowEvent(10)
          
         If Event = #PB_Event_CloseWindow
           JustExit()
         EndIf       
          
          If i=50 Or i=195
            PlaySound(1, 0, VolFx)
          EndIf
          If i>45
            StartDrawing(ScreenOutput())
            DrawImage(ImageID(0),0,0)
            StopDrawing()
            
          EndIf
           StartDrawing(ScreenOutput())
          If i>200           
            DrawAlphaImage(ImageID(1),(ScrW-300)/2,ScrH-150,(i-200)*2)            
          EndIf
          If i=300
            PlaySound(0,#PB_Sound_Loop )
          EndIf
          If i>300              
              DrawingMode(#PB_2DDrawing_Transparent)
              DrawingFont(FontID(0)) 
              DrawText((ScrW-100)/2-40,(ScrH-60), " ARROWS FOR MOVING", RGB(100,100,100)) 
              DrawText((ScrW-100)/2-110,(ScrH-40), " SPACE FOR FIRE, L.SHIFT FOR SHIELD", RGB(100,100,100)) 
              If x>50
                If x>=60
                  x=0
                EndIf
              Else
                DrawText((ScrW-100)/2-107,(ScrH-20), " PRESS SPACE TO DESTROY ENEMY!!", RGB(255,20,20))
              EndIf             
            EndIf
          
          If KeyboardPushed(#PB_Key_Space) And i>250
            FadeMode =-4
            TitleQuit=1
          EndIf
          
          If KeyboardReleased(#PB_Key_Escape) 
            SoundSetup=1-SoundSetup            
          EndIf
          
          If SoundSetup=1
            Gosub SoundSetupSub
          EndIf
        
          StopDrawing()
          If i>45
            
            If (Fade-FadeMode)<=255 And (Fade-FadeMode)>=0
              Fade-FadeMode
              If TitleQuit=0
                DisplayTransparentSprite(100, 0, 0,Fade,RGB(Fade,Fade,Fade))
              Else
                DisplayTransparentSprite(100, 0, 0,Fade)
                SoundVolume(0, VolMusic/255*(255-Fade))
              EndIf
            Else
              If TitleQuit=1
                TitleQuit=2
                ClearScreen(RGB(0, 0, 0))
                StopSound(0)
              EndIf
            EndIf
          EndIf
        FlipBuffers()         
        
      Until TitleQuit=2
      TitleQuit=0
      Fade =255
      FadeMode =4
      Repeat   
          ExamineKeyboard()
          If WindowEvent()  = #PB_Event_CloseWindow
            JustExit()
          EndIf
          ClearScreen(RGB(0, 0, 0))
          StartDrawing(ScreenOutput())
          
          DrawingMode(#PB_2DDrawing_Transparent)
              DrawingFont(FontID(0)) 
              DrawText((ScrW-100)/2,(ScrH/2),       "STAGE 1", RGB(100,100,100))
              DrawText((ScrW-170)/2,(ScrH/2+20), "GET 20K SCORE", RGB(100,100,100))
          StopDrawing()    
              If (Fade-FadeMode)<=255 And (Fade-FadeMode)>=0
                Fade-FadeMode              
                DisplayTransparentSprite(100, 0, 0,Fade)
              Else
                If TitleQuit=1
                  TitleQuit=2
                  ClearScreen(RGB(0, 0, 0))
                EndIf
              EndIf 
              
              If KeyboardPushed(#PB_Key_Space)
                FadeMode =-4
                TitleQuit=1
              EndIf
          
          FlipBuffers()
        Until TitleQuit=2
              
      SoundSetup=0
      Fade =255
      FadeMode =2
      PlaySound(3,#PB_Sound_Loop,0 )     ;Play background music
      
  PlayerSpeedX.f = 0
  PlayerSpeedY.f = 0
  #SpeedStepX =0.2
  #SpeedStepY =0.4
  #MaxSpeed = 4 ;максимальная скорость
  #BackSpeed= 1 ;во сколько раз SpeedStep умножить при остановке  
  BulletSpeed= 10
  #BulletInitMax=100
  #BulletInitMin=5  
  BulletInit.f = #BulletInitMax
  Weapone=0        
  WeaponeMax=1
  delayPlanet=Random(200)+250
  PlanetX = 20+Random(600) 
  PlanetSprite = 56+Random(1)
  PlanetY = - SpriteHeight(PlanetSprite)
  ;----------------------------------------------------------PLAYER
   
  PlayerX = ScrW/2
  PlayerY = ScrH-200
  
  ;----------------------------------------------------------
  
  PlayerLife=3
  DeadDelay = 0
  armour = 1  
  CurImageEngStart=0
  CurImageEngEnd=8
  CurImageEng=CurImageEngStart
  EngDelay=3
  CurEngDelay=0 
  ShieldActiv=0
  Shield.f=200 
  #ShieldMAx=300
  #ShieldDelay=5
  #ShieldSprStart=0
  #ShieldSprEnd=19
  #ShieldWidth=128
  #ShieldHeight=128
  #ShieldLenght=5
  #ShieldUsedStep = 0.1
  #ShieldRecoverStep=0.12
  CurShieldDelay=#ShieldDelay
  CurShieldSpr=#ShieldSprStart
  NextScoreLife=5000
  Score=0
  Boss=0  
  Level=0
  levelComplete=0
  SndStop=0
  FadeColor=0 
  BlackHoleActiv=0
  #BlackHoleSpriteId=13
  #BlackHoleDelay=1
  #BlackHoleStart=0
  #BlackHoleEnd=19
  BlackHoleCurDelay=#BlackHoleDelay
  #BlackHoleWidth=200
  #BlackHoleHeight=200
  #BlackHoleLenght=5
  BlackHoleCur=#BlackHoleStart
  BlackHoleX=0  
  BlackHoleY=0
  BlackHoleAllDelay=0
  BlackHoleDir=0  
  TimeDelay.l=100 
  MasterTimer.l=GetTickCount_()
  FrameRate.f=0
  FpsDelay=50
  
  Repeat
           TimeDelay=GetTickCount_()-MasterTimer 
           MasterTimer=GetTickCount_() 
            FpsDelay-1
            If FpsDelay=0
              FpsDelay=50
              FrameRate=1000/TimeDelay 
            EndIf
          If WindowEvent()  = #PB_Event_CloseWindow
            JustExit()
          EndIf
        
    If IsScreenActive() ; Check if is active or not (ALT+TAB symptom :)
      ExamineKeyboard()
      ClearScreen(RGB(0, 0, 0)) 
      If SoundSetup=0
        db = 1-db
        If df<50
          df+1
        Else
          df=0
        EndIf
        
        If Score>=LevelScore(Level)
          ;level comlete
          levelComplete=1
          GameOver=1
        EndIf
               
     If  delayPlanet >0
       delayPlanet -1
     Else        
       If PlanetY>ScrH
         delayPlanet=Random(400)+250
         PlanetX = 20+Random(ScrW-40)
         PlanetSprite = 56+Random(1)
         PlanetY = - SpriteHeight(PlanetSprite)        
       Else
         PlanetY +1
         DisplayTransparentSprite(PlanetSprite, PlanetX, PlanetY)
       EndIf       
     EndIf
     
     ;-------------------DISPLAY BLACK HOLE------------------
     
     If BlackHoleActiv=1
       ;ClipSprite(#BlackHoleSpriteId,(BlackHoleCur-Int(BlackHoleCur/#BlackHoleLenght)*#BlackHoleLenght)*#BlackHoleWidth,Int(BlackHoleCur/#BlackHoleLenght)*#BlackHoleHeight,#BlackHoleWidth,#BlackHoleHeight)
       If BlackHoleAllDelay <=100
         If BlackHoleDir
           DisplayTransparentSprite(BlackHoleCur+297, BlackHoleX, BlackHoleY,255*BlackHoleAllDelay/100,RGB(255,51,51))
         Else
           DisplayTransparentSprite(BlackHoleCur+297, BlackHoleX, BlackHoleY,255*BlackHoleAllDelay/100)
         EndIf
       Else
         If BlackHoleAllDelay >300
           If BlackHoleDir
             DisplayTransparentSprite(BlackHoleCur+297, BlackHoleX, BlackHoleY,255*(400-BlackHoleAllDelay)/100,RGB(255,51,51))
           Else
             DisplayTransparentSprite(BlackHoleCur+297, BlackHoleX, BlackHoleY,255*(400-BlackHoleAllDelay)/100)
           EndIf
         Else           
           If BlackHoleDir
             DisplayTransparentSprite(BlackHoleCur+297, BlackHoleX, BlackHoleY,255,RGB(255,51,51))
           Else
             DisplayTransparentSprite(BlackHoleCur+297, BlackHoleX, BlackHoleY)
           EndIf
         EndIf
       EndIf 
       
       BlackHoleAllDelay+1
       If BlackHoleAllDelay >=400
         BlackHoleAllDelay=0
         BlackHoleActiv=0
         BlackHoleCur=#BlackHoleStart
         If SoundStatus(32) = #PB_Sound_Playing
           StopSound(32)
         EndIf
         
       EndIf
       If BlackHoleCurDelay=0
           
           PlayerCentrX=PlayerX+PlayerWidth/2
           PlayerCentrY=PlayerY+PlayerHeight/2
           BlackHoleCentrX=BlackHoleX+#BlackHoleWidth/2
           BlackHoleCentrY=BlackHoleY+#BlackHoleHeight/2
           If Sqr((PlayerCentrY-BlackHoleCentrY)*(PlayerCentrY-BlackHoleCentrY)+(PlayerCentrX-BlackHoleCentrX)*(PlayerCentrX-BlackHoleCentrX))<150 And BlackHoleAllDelay>80 And  BlackHoleAllDelay<420
             ;DrawingMode(#PB_2DDrawing_Outlined )
             ;Circle(BlackHoleCentrX, BlackHoleCentrY, 150, RGB(100, 100, 255))
             
             If BlackHoleDir
                 If (PlayerCentrX-BlackHoleCentrX)>6
                   PlayerX + (((150-Abs(PlayerCentrX-BlackHoleCentrX))/150)*8) 
                 EndIf
                 If (PlayerCentrX-BlackHoleCentrX)<-6
                   PlayerX - (((150-Abs(PlayerCentrX-BlackHoleCentrX))/150)*8)  
                 EndIf
    
                 If (PlayerCentrY-BlackHoleCentrY)>6
                   PlayerY + (((150-Abs(PlayerCentrY-BlackHoleCentrY))/150)*10) 
                 EndIf
                 If (PlayerCentrY-BlackHoleCentrY)<-6
                   PlayerY - (((150-Abs(PlayerCentrY-BlackHoleCentrY))/150)*10)  
                 EndIf  
             Else
                 If (PlayerCentrX-BlackHoleCentrX)>6
                   PlayerX - (((Abs(PlayerCentrX-BlackHoleCentrX))/150)*8) 
                 EndIf
                 If (PlayerCentrX-BlackHoleCentrX)<-6
                   PlayerX + (((Abs(PlayerCentrX-BlackHoleCentrX))/150)*8)  
                 EndIf
    
                 If (PlayerCentrY-BlackHoleCentrY)>6
                   PlayerY - (((Abs(PlayerCentrY-BlackHoleCentrY))/150)*10) 
                 EndIf
                 If (PlayerCentrY-BlackHoleCentrY)<-6
                   PlayerY + (((Abs(PlayerCentrY-BlackHoleCentrY))/150)*10)  
                 EndIf
                 
              EndIf
            
           EndIf
            BlackHoleCurDelay = #BlackHoleDelay
              If BlackHoleDir
                If BlackHoleCur>#BlackHoleStart 
                  BlackHoleCur - 1
                Else                  
                  BlackHoleCur=#BlackHoleEnd           
                EndIf
              Else
                If BlackHoleCur<#BlackHoleEnd 
                  BlackHoleCur + 1
                Else                  
                  BlackHoleCur=#BlackHoleStart           
                EndIf
                
              EndIf
                             
       Else
         BlackHoleCurDelay - 1
       EndIf  
       
     EndIf
      StartDrawing(ScreenOutput())
      MoveStarsY()
      StopDrawing()           
            
          Gosub CheckCollisions       
          Gosub MovePlayers      
          Gosub DisplayBullets 
          
          Gosub NewAlienWave         
          Gosub DisplayAliens
          Gosub DisplayBonus
          
          Gosub DisplayExplosions    
          Gosub DisplayExplMine
          ;recovery Shield
          If BulletDelay > 0
            BulletDelay-1
          EndIf
          If Shield<#ShieldMax
            Shield + #ShieldRecoverStep
            If Shield>#ShieldMax
              Shield=#ShieldMax
            EndIf
          EndIf
          
          If ShieldKey>0
            ShieldKey -1
          EndIf          
          StartDrawing(ScreenOutput())
          DrawingFont(FontID(0))       
          DrawingMode(#PB_2DDrawing_Transparent)
          If FpsActiv
            DrawText(560,5, "FPS: "+Str(FrameRate), RGB(200,104,104))  
          EndIf
          DrawText(5,5, "SCORE:", RGB(255,20,20))      
          DrawText(75,5,  Str(Score), RGB(255,255,255))
          DrawText(5,25, "ARMOR:", RGB(255,20,20))      
          DrawText(5,45, "SHIPS:", RGB(255,20,20))
          DrawText(70,45,  Str(PlayerLife), RGB(255,255,255))
          DrawText(5,65, "SHIELD:", RGB(255,20,20))          
          DrawingMode(#PB_2DDrawing_Outlined)
          Box (75,25,100,10,RGB($99,$00,$00))
          If Shield>#ShieldMax*0.1 Or df>15
            Box (75,65,100,10,RGB($FF,$33,$00))
          EndIf          
          DrawingMode(#PB_2DDrawing_Default )
          Box (75,25,100*(BulletInit/#BulletInitMax),10,RGB($99,$00,$00))
          Box (75,65,100*Shield/#ShieldMax,10,RGB($FF,$33,$00))
          StopDrawing()
      Else
        StartDrawing(ScreenOutput())
        Gosub SoundSetupSub 
        StopDrawing() 
      EndIf
          
      If KeyboardReleased(#PB_Key_Escape) 
        SoundSetup=1-SoundSetup
        If SoundSetup=1
          PauseSound(3)
        Else
          SoundVolume(3, VolMusic)
          ResumeSound(3)
        EndIf
      EndIf
        
        TransparentSpriteColor(100, RGB(255,255,255)) ;COVER!!       
        If GameOver=1
          FadeMode = -2
        EndIf
        
        If (Fade-FadeMode)<=255 And (Fade-FadeMode)>=0
          Fade-FadeMode          
                If FadeColor=0
                  DisplayTransparentSprite(100, 0, 0,Fade)
                Else
                  DisplayTransparentSprite(100, 0, 0,Fade,RGB(Fade,Fade,Fade))
                EndIf                     
          SoundVolume(3, VolMusic/255*(255-Fade)) 
        Else
          FadeColor=0           
          If GameOver=1
            GameOver=2
            StopSound(-1)
            ClearScreen(RGB(0, 0, 0))
            ClearList(Aliens())
            ClearList(Bonus())
            ClearList(ExplMine())
            ClearList(Explosion())
            ClearList(Bullet())
            ClearList(STAR())           
          EndIf
        EndIf
                     
      FlipBuffers() ; This should be always in the loop, the events are handle by this functions         
      If SndStop=1
        ResumeSound(3)
        SndStop=0
      EndIf
    Else  
          ; The screen is no more active but our game multitask friendly, so we stop the sounds and
          ; add a delay to not eat the whole CPU. Smart hey ? :)
      If SoundSetup=0    
        PauseSound(3)
        SndStop=1
      EndIf
      Delay(20)
    EndIf
    
  Until GameOver =2
Else
  MessageRequester("Asteroid Belt", "Can't open a 640*480 8 bit screen !", 0)
EndIf
If GameOver =2 And levelComplete=0
  Goto START
Else
  ;---------------NEXT LEVEL--------------------
   TitleQuit=0
      Fade =255
      FadeMode =4
      Repeat   
          ExamineKeyboard()
          If WindowEvent()  = #PB_Event_CloseWindow
            JustExit()
          EndIf
          ClearScreen(RGB(0, 0, 0))
          StartDrawing(ScreenOutput())
          
          DrawingMode(#PB_2DDrawing_Transparent)
              DrawingFont(FontID(0)) 
              DrawText((ScrW-200)/2,(ScrH/2),   "CONGRATULATIONS!", RGB(100,100,100))
              DrawText((ScrW-180)/2,(ScrH/2+20), "MISSION COMLETE", RGB(100,100,100))
          StopDrawing()    
              If (Fade-FadeMode)<=255 And (Fade-FadeMode)>=0
                Fade-FadeMode  
                
                  DisplayTransparentSprite(100, 0, 0,Fade)
               
              Else
               
                If TitleQuit=1
                  TitleQuit=2
                  ClearScreen(RGB(0, 0, 0))
                EndIf
              EndIf 
              
              If KeyboardPushed(#PB_Key_Space)
                FadeMode =-4
                TitleQuit=1
              EndIf
          
          FlipBuffers()
        Until TitleQuit=2
      Goto START
EndIf
End

SoundSetupSub:
DrawingMode(#PB_2DDrawing_Transparent)
            DrawingFont(FontID(1))
            If SoundSetupY=0
              DrawText(ScrW/2-200,(ScrH/2-150), "SOUND:", RGB(255,0,0))
              DrawText(ScrW/2-200,(ScrH/2-120), "MUSIC:", RGB(100,100,100)) 
              DrawingMode(#PB_2DDrawing_Outlined)
              Box (ScrW/2-20,ScrH/2-145,200,20,RGB(255,0,0))                  
              DrawingMode(#PB_2DDrawing_Default )
              Box (ScrW/2-20,ScrH/2-145,2*VolFx,20,RGB(255,0,0))
              
              DrawingMode(#PB_2DDrawing_Outlined)
              Box (ScrW/2-20,ScrH/2-115,200,20,RGB(100,100,100))                  
              DrawingMode(#PB_2DDrawing_Default )
              Box (ScrW/2-20,ScrH/2-115,2*VolMusic,20,RGB(100,100,100))         
                           
            Else
              DrawText(ScrW/2-200,(ScrH/2-150), "SOUND:", RGB(100,100,100))
              DrawText(ScrW/2-200,(ScrH/2-120), "MUSIC:", RGB(255,0,0)) 
              DrawingMode(#PB_2DDrawing_Outlined)
              Box (ScrW/2-20,ScrH/2-145,200,20,RGB(100,100,100))                  
              DrawingMode(#PB_2DDrawing_Default )
              Box (ScrW/2-20,ScrH/2-145,2*VolFx,20,RGB(100,100,100))
              
              DrawingMode(#PB_2DDrawing_Outlined)
              Box (ScrW/2-20,ScrH/2-115,200,20,RGB(255,0,0))                  
              DrawingMode(#PB_2DDrawing_Default )
              Box (ScrW/2-20,ScrH/2-115,2*VolMusic,20,RGB(255,0,0))
            EndIf
            SoundSetupX=0
            If KeyboardPushed( #PB_Key_Up)
              SoundSetupY=0
            EndIf
            If KeyboardPushed( #PB_Key_Down)
              SoundSetupY=1
             EndIf
            If KeyboardPushed( #PB_Key_Left)
              SoundSetupX=-1
            EndIf
            If KeyboardPushed( #PB_Key_Right)
              SoundSetupX=1
            EndIf 
            Select SoundSetupY
            Case 0
              If (VolFx+SoundSetupX)>=0 And (VolFx+SoundSetupX)<=100
                VolFx+SoundSetupX
                VolVoice+SoundSetupX
              EndIf
            Case 1 
              If (VolMusic+SoundSetupX)>=0 And (VolMusic+SoundSetupX)<=100
                VolMusic+SoundSetupX   
                SoundVolume(0, VolMusic)
              EndIf
            EndSelect            
Return
;-----------------Move Player--------------------------------------------

MovePlayers:  
  x=0
  y=0
  If KeyboardPushed(#PB_Key_Left)
    If PlayerSpeedX>0
      PlayerSpeedX - #SpeedStepX
    Else
      If Abs(PlayerSpeedX)<#MaxSpeed
        PlayerSpeedX - #SpeedStepX    
      EndIf
    EndIf
  ;PlayerImage = 2  ; Left moving player image
  x=1    
  EndIf
  
  If KeyboardPushed(#PB_Key_Right)
    If PlayerSpeedX<0
      PlayerSpeedX + #SpeedStepX
    Else
      If Abs(PlayerSpeedX)<#MaxSpeed
        PlayerSpeedX + #SpeedStepX    
      EndIf
    EndIf        
  ;PlayerImage = 0  ; Right moving player image
  x=1    
  EndIf
  
  If KeyboardPushed(#PB_Key_Up)
    If PlayerSpeedY>0
      PlayerSpeedY - #SpeedStepY
    Else
      If Abs(PlayerSpeedY)<#MaxSpeed
        PlayerSpeedY - #SpeedStepY
      EndIf
    EndIf         
    y=1    
  EndIf
  
  If KeyboardPushed(#PB_Key_Down)
    If PlayerSpeedY<0
      PlayerSpeedY + #SpeedStepY
    Else
      If Abs(PlayerSpeedY)<#MaxSpeed
        PlayerSpeedY + #SpeedStepY
      EndIf
    EndIf      
    y=1
  EndIf
  
  If x=0 
    If PlayerSpeedX<0
      PlayerSpeedX + #SpeedStepX*#BackSpeed
      If PlayerSpeedX>0
        PlayerSpeedX = 0
      EndIf
    EndIf
    If PlayerSpeedX>0
      PlayerSpeedX - #SpeedStepX*#BackSpeed
      If PlayerSpeedX<0
        PlayerSpeedX = 0
      EndIf
    EndIf
  EndIf
  
  If y=0 
    If PlayerSpeedY<0
      PlayerSpeedY + #SpeedStepY*#BackSpeed
      If PlayerSpeedY>0
        PlayerSpeedY = 0
      EndIf
    EndIf
    If PlayerSpeedY>0
      PlayerSpeedY - #SpeedStepY*#BackSpeed
      If PlayerSpeedY<0
        PlayerSpeedY = 0
      EndIf
    EndIf
 EndIf
 
 PlayerImage=5-Int(PlayerSpeedX*5/#MaxSpeed) 
 ;ClipSprite(3,(PlayerImage-Int(PlayerImage/PlayerLenght)*PlayerLenght)*PlayerWidth,Int(PlayerImage/PlayerLenght)*PlayerHeight,PlayerWidth,PlayerHeight)
 
  PlayerX + PlayerSpeedX
  PlayerY + PlayerSpeedY
  
  If PlayerX < 0-PlayerWidth/3 : PlayerX = -PlayerWidth/3 : EndIf
  If PlayerY < 0 : PlayerY = 0 : EndIf  
  
  If PlayerX > ScrW-PlayerWidth/1.5  : PlayerX = ScrW-PlayerWidth/1.5 : EndIf
  If PlayerY > ScrH-PlayerHeight : PlayerY = ScrH-PlayerHeight : EndIf   
  
  If Abs(PlayerSpeedY)>#MaxSpeed/2 Or Abs(PlayerSpeedX)>#MaxSpeed/2
    ; full engine
    CurImageEngStart=0
    CurImageEngEnd=8
  Else
    ; weak engine
     CurImageEngStart=0
     CurImageEngEnd=2
   EndIf
   If CurEngDelay>0
     CurEngDelay -1
   Else
     CurEngDelay = EngDelay
     If CurImageEng<CurImageEngEnd
        CurImageEng + 1
     Else
        CurImageEng=CurImageEngStart    
     EndIf
   EndIf  
 
  If Dead = 1
    AddElement(Explosion())
    If PlayerLife>1
      PlayerLife -1
    Else
      GameOver = 1
    EndIf
    Explosion()\x = PlayerX-(128-PlayerWidth)/2
    Explosion()\y = PlayerY-(128-PlayerHeight)/2
    armour = 1 
    BulletInit = #BulletInitMax 
    Dead = 0
    PlayerSpeedY=0
    PlayerSpeedX=0
    Shield=#ShieldMAx-100  
    ShieldActiv=0  
  Else
    ;ClipSprite(40,(CurImageEng-Int(CurImageEng/5)*5)*20,Int(CurImageEng/5)*55,20,55)
    If GameOver=0
      If DeadDelay>0
        DeadDelay-1
        If db=1
          If DeadDelay < 200
            DisplayTransparentSprite(PlayerImage+200, PlayerX, PlayerY) ;flash
            If PlayerSpeedY<0 And PlayerSpeedX=0
                    DisplayTransparentSprite(CurImageEng+385, PlayerX+(PlayerWidth/2)-StepEngine(PlayerImage)-10, PlayerY+72)
                    DisplayTransparentSprite(CurImageEng+385, PlayerX+(PlayerWidth/2)+StepEngine(PlayerImage)-10, PlayerY+72)                            
            EndIf
            If PlayerSpeedY<=0
              If PlayerSpeedX>0                                  
                    DisplayTransparentSprite(CurImageEng+385, PlayerX+(PlayerWidth/2)-StepEngine(PlayerImage)-10, PlayerY+72)             
              EndIf
              If PlayerSpeedX<0                             
                    DisplayTransparentSprite(CurImageEng+385, PlayerX+(PlayerWidth/2)+StepEngine(PlayerImage)-10, PlayerY+72)               
              EndIf
            EndIf
          EndIf
        EndIf
      Else
        DisplayTransparentSprite(PlayerImage+200, PlayerX, PlayerY)                
        If PlayerSpeedY<0 And PlayerSpeedX=0                 
                DisplayTransparentSprite(CurImageEng+385, PlayerX+(PlayerWidth/2)-StepEngine(PlayerImage)-10, PlayerY+72)
                DisplayTransparentSprite(CurImageEng+385, PlayerX+(PlayerWidth/2)+StepEngine(PlayerImage)-10, PlayerY+72)                    
        EndIf
        If PlayerSpeedY<=0
          If PlayerSpeedX>0                              
                DisplayTransparentSprite(CurImageEng+385, PlayerX+(PlayerWidth/2)-StepEngine(PlayerImage)-10, PlayerY+72)         
          EndIf
          If PlayerSpeedX<0                         
                DisplayTransparentSprite(CurImageEng+385, PlayerX+(PlayerWidth/2)+StepEngine(PlayerImage)-10, PlayerY+72)           
          EndIf
        EndIf
        If ShieldActiv = 1
          If CurShieldDelay> 0
            CurShieldDelay -1
          Else
            If CurShieldSpr<#ShieldSprEnd
              CurShieldSpr + 1
            Else
              CurShieldSpr = #ShieldSprStart
            EndIf
            CurShieldDelay=#ShieldDelay
          EndIf
          ;ClipSprite(51,(CurShieldSpr-Int(CurShieldSpr/#ShieldLenght)*#ShieldLenght)*#ShieldWidth,Int(CurShieldSpr/#ShieldLenght)*#ShieldHeight,#ShieldWidth,#ShieldHeight) 
          DisplayTransparentSprite(CurShieldSpr+466, PlayerX+(PlayerWidth-#ShieldWidth)/2, PlayerY+(PlayerHeight-#ShieldHeight)/2)          
        EndIf        
      EndIf
    EndIf
  EndIf
  
  If KeyboardReleased(#PB_Key_Tab)
   FpsActiv=1-FpsActiv
  EndIf

  If KeyboardPushed(#PB_Key_LeftShift) And DeadDelay=0; shield activate/deactivate
    If ShieldKey=0
      ShieldActiv= 1-ShieldActiv
      If ShieldActiv=1 And Shield>#ShieldMax*0.1
        CurShieldDelay=#ShieldDelay
        CurShieldSpr=#ShieldSprStart
      Else
        ShieldActiv=0
      EndIf 
    EndIf
    ShieldKey=50    
  Else
    ShieldKey=0
  EndIf
    
  If KeyboardPushed(#PB_Key_Space) Or Fire
    If BulletDelay = 0 
      If DeadDelay < 100        
          BulletInit - WeaponeUsedStep(Weapone)
          If BulletInit<#BulletInitMin
            BulletInit =#BulletInitMin
          EndIf
          BulletDelay = WeaponeDelay(Weapone)/(BulletInit/#BulletInitMax)
          ;ClipSprite(3,(PlayerImage-Int(PlayerImage/PlayerLenght)*PlayerLenght)*PlayerWidth,Int(PlayerImage/PlayerLenght)*PlayerHeight,PlayerWidth,PlayerHeight)
      Select Weapone
        Case 0
          ; AddBullet() syntax: (#Sprite, x, y, SpeedX, SpeedY,BulletDamage)
          ;
          If armour>=1
            AddBullet(1, PlayerX+PlayerWidth/2-11, PlayerY-22,  0          , -BulletSpeed,WeaponeDamage(Weapone)) ; Front bullet (Double bullet sprite)
          EndIf
          If armour>=2
            AddBullet(6, PlayerX+PlayerWidth/2+36, PlayerY+PlayerHeight/2+11 ,  BulletSpeed, 0,WeaponeDamage(Weapone))            ; Right side bullet
            AddBullet(7, PlayerX+PlayerWidth/2-36-22, PlayerY+PlayerHeight/2+11 , -BulletSpeed, 0,WeaponeDamage(Weapone))            ; Left side bullet
          EndIf
          If armour>=3
            AddBullet(2, PlayerX+PlayerWidth/2+18, PlayerY+PlayerHeight/2-22 ,  BulletSpeed, -BulletSpeed,WeaponeDamage(Weapone)) ; Front-Right bullet
            AddBullet(0, PlayerX+PlayerWidth/2-18-22, PlayerY+PlayerHeight/2-22 , -BulletSpeed, -BulletSpeed,WeaponeDamage(Weapone)) ; Front-Left bullet
            AddBullet(4, PlayerX+PlayerWidth/2-11, PlayerY+PlayerHeight-10,  0          ,  BulletSpeed,WeaponeDamage(Weapone)) ; Rear bullet
          EndIf
        Case 1
          If armour>=1
            AddBullet(8, PlayerX+PlayerWidth/2-11, PlayerY-22,  0          , -BulletSpeed,WeaponeDamage(Weapone)) ; Front bullet (Double bullet sprite)
          EndIf
          If armour>=2
            AddBullet(8, PlayerX+PlayerWidth/2+36, PlayerY+PlayerHeight/2+11 ,  BulletSpeed, 0,WeaponeDamage(Weapone))            ; Right side bullet
            AddBullet(8, PlayerX+PlayerWidth/2-36-22, PlayerY+PlayerHeight/2+11 , -BulletSpeed, 0,WeaponeDamage(Weapone))            ; Left side bullet
          EndIf
          If armour>=3
            AddBullet(8, PlayerX+PlayerWidth/2+18, PlayerY+PlayerHeight/2-22 ,  BulletSpeed, -BulletSpeed,WeaponeDamage(Weapone)) ; Front-Right bullet
            AddBullet(8, PlayerX+PlayerWidth/2-18-22, PlayerY+PlayerHeight/2-22 , -BulletSpeed, -BulletSpeed,WeaponeDamage(Weapone)) ; Front-Left bullet
            AddBullet(8, PlayerX+PlayerWidth/2-11, PlayerY+PlayerHeight-10,  0          ,  BulletSpeed,WeaponeDamage(Weapone)) ; Rear bullet
          EndIf
        Case 2
          If armour=1 Or  armour=3       
            AddElement(Bullet())
            Bullet()\ImageAnim=1
            Bullet()\SpriteId=379
            Bullet()\Width  = 128
            Bullet()\Height = 128 
            Bullet()\x      = PlayerX+PlayerWidth/2-Bullet()\Width/2
            Bullet()\y      = PlayerY-40
            Bullet()\Image  = 0
            Bullet()\ImageStart=5
            Bullet()\ImageEnd=5
            Bullet()\ImageDelay=1
            Bullet()\Lenght=6
            Bullet()\SpeedX = 0
            Bullet()\SpeedY = -BulletSpeed
            Bullet()\BulletDamage = WeaponeDamage(Weapone)                      
          EndIf    
          If armour=2 Or armour=3          
            AddElement(Bullet())
            Bullet()\ImageAnim=1
            Bullet()\SpriteId=379
            Bullet()\Width  = 128
            Bullet()\Height = 128 
            Bullet()\x      = PlayerX+PlayerWidth/2-11-Bullet()\Width/2
            Bullet()\y      = PlayerY-3
            Bullet()\Image  = 0
            Bullet()\ImageStart=5
            Bullet()\ImageEnd=5
            Bullet()\ImageDelay=1
            Bullet()\Lenght=6
            Bullet()\SpeedX = 0
            Bullet()\SpeedY = -BulletSpeed
            Bullet()\BulletDamage = WeaponeDamage(Weapone)            
            AddElement(Bullet())
            Bullet()\ImageAnim=1
            Bullet()\SpriteId=379
            Bullet()\Width  = 128
            Bullet()\Height = 128 
            Bullet()\x      = PlayerX+PlayerWidth/2+11-Bullet()\Width/2
            Bullet()\y      = PlayerY-3
            Bullet()\Image  = 0
            Bullet()\ImageStart=5
            Bullet()\ImageEnd=5
            Bullet()\ImageDelay=1
            Bullet()\Lenght=6
            Bullet()\SpeedX = 0
            Bullet()\SpeedY = -BulletSpeed
            Bullet()\BulletDamage = WeaponeDamage(Weapone)
            ;Bullet()\BulletDestr = 0
          EndIf  
      EndSelect      
        PlaySound(Weapone+10, 0, VolFx)    ; Play weapone shoot sound
      EndIf
    EndIf
  Else
    If BulletInit<#BulletInitMax
      BulletInit + WeaponeRecoverStep(Weapone)
      If BulletInit>#BulletInitMax
        BulletInit =#BulletInitMax
      EndIf
    EndIf
  EndIf

Return

;------------------------DISPLAY BULLETS---------------------------------

DisplayBullets:
ResetList(Bullet())
While NextElement(Bullet())  ; Process all the bullet actually displayed on the screen
      
    If Bullet()\y < 0-Bullet()\Height         ; If a bullet is now out of the screen, simply delete it..
      DeleteElement(Bullet())
    Else
      If Bullet()\x < 0-Bullet()\Width        ; If a bullet is now out of the screen, simply delete it..
        DeleteElement(Bullet())
      Else
        If Bullet()\x > ScrW
          DeleteElement(Bullet())
        Else
          If Bullet()\y > ScrH
            DeleteElement(Bullet())
          Else
              DisplayTransparentSprite(Bullet()\SpriteId+Bullet()\Image, Bullet()\x, Bullet()\y)            
            ;DisplayTransparentSprite(Bullet()\Image, Bullet()\x, Bullet()\y)   ; Display the bullet..
            Bullet()\y + Bullet()\SpeedY
            Bullet()\x + Bullet()\SpeedX
            If Bullet()\ImageAnim=1
              If Bullet()\ImageDelayCur=0
                Bullet()\Image+1
                Bullet()\ImageDelayCur = Bullet()\ImageDelay
                If Bullet()\Image>Bullet()\ImageEnd
                   Bullet()\Image=Bullet()\ImageStart
                EndIf
              Else
                Bullet()\ImageDelayCur-1                   
              EndIf
            EndIf
          EndIf
        EndIf
      EndIf
    EndIf
  Wend
Return

;---------------------------ADD ALIENS---------------------------
NewAlienWave:

  If AlienDelay = 0
    AddElement(Aliens())
    If Boss = 1
      PlaySound(4, 0, Random(1)*VolVoice)
      ran = Random(200)
      If ran<100
        If PlayerX-ran<0
          Aliens()\x=0
        Else
          Aliens()\x = PlayerX-ran
        EndIf      
      Else
        If PlayerX+ran-100>ScrW
          Aliens()\x=ScrW
        Else
          Aliens()\x = PlayerX+ran-100
        EndIf                
      EndIf
      Aliens()\SpriteId = 281 ; ID sprite
      Aliens()\y = -32
      Aliens()\Width  = 64  
      Aliens()\Height = 64
      Aliens()\SpeedY  = 6
      Aliens()\Lenght = 4
      Aliens()\StartImage = 0
      Aliens()\EndImage   = 15
      Aliens()\ImageDelay = 4
      Aliens()\NextImageDelay = Aliens()\ImageDelay
      Aliens()\ActualImage = 0
      Aliens()\Armor = 20
      Aliens()\Damage = 250
      Aliens()\SoundID=24   
      AlienDelay = 20
      Boss = 0
      PlaySound(8, 0, VolFx)      
    Else
      alienRandom = Random(5)
      If Score<12000
        alienRandom =1
      EndIf
      If alienRandom=0
        ; HARD alien-------------------------------
        Aliens()\SpriteId = 251 ; ID sprite
        Aliens()\x = Random(ScrW)-40
        Aliens()\y = -100
        Aliens()\Width  = 80       
        Aliens()\Height = 80
        Aliens()\Lenght = 5
        Aliens()\SpeedY  = 1
        Aliens()\StartImage  = 0 
        Aliens()\EndImage    = 29 
        Aliens()\ImageDelay  =  3
        Aliens()\NextImageDelay = Aliens()\ImageDelay
        Aliens()\ActualImage = 0
        Aliens()\Armor = 5000
        Aliens()\Damage = 500
        Aliens()\SoundID=22
        ; HARD alien with X axis reverse moving-------------------------
        If Score>=16000
          Aliens()\SpeedX  = Random(2)+1
          If Random(1)=1 
            Aliens()\SpeedX*-1
          EndIf 
          Aliens()\LimitX=Random(Int(Score/100))+50           
        EndIf            
      AlienDelay = Random(50)+20
    Else
      Aliens()\intense=Random(30)
      ; simple alien--------------------------------
      Aliens()\rotate=Random(1)
      Aliens()\SpriteId = 221 ; ID sprite
      Aliens()\x = Random(ScrW)-32
      Aliens()\y = -50
      Aliens()\Width  = 64 
      Aliens()\Height = 64
      Aliens()\Lenght = 5
      Aliens()\SpeedY  =Random(1)+2+Int(Score/5000)*0.3  
      ; alien with X axis moving-------------------------
      If Score>10000
        Aliens()\SpeedX  = Random(2)
      EndIf              
      Aliens()\StartImage  = 0 
      Aliens()\EndImage    = 29 
      Aliens()\ImageDelay  =  Random(4)+1
      Aliens()\NextImageDelay = Aliens()\ImageDelay      
      Aliens()\Armor = 5
      Aliens()\Damage = 80
      Aliens()\SoundID=20
      If Aliens()\rotate=1
        temp=Aliens()\StartImage
        Aliens()\StartImage=Aliens()\EndImage
        Aliens()\EndImage = temp
      EndIf
      Aliens()\ActualImage = Aliens()\StartImage
      ; alien with X axis reverse moving-------------------------
      If Random(1)=1 And Score>=10000          
            Aliens()\SpeedX=Aliens()\SpeedY               
            Aliens()\LimitX=Random(Int(Score/100))+50                    
      EndIf
      If Random(1)=1 
         Aliens()\SpeedX*-1
      EndIf
      AlienDelay = Random(45)
      EndIf
    EndIf
  Else
    AlienDelay-1
  EndIf
Return

;-----------------------------DISPLAY ALIENS---------------------

DisplayAliens:
  ResetList(Aliens())
  While NextElement(Aliens())
    State= Aliens()\ActualImage
    ;ClipSprite(Aliens()\SpriteId,(State-Int(State/Aliens()\Lenght)*Aliens()\Lenght)*Aliens()\Width,Int(State/Aliens()\Lenght)*Aliens()\Height,Aliens()\Width,Aliens()\Height)     
      DisplayTransparentSprite(Aliens()\SpriteId+Aliens()\ActualImage, Aliens()\x, Aliens()\y,255-Aliens()\intense)  
      Aliens()\y + Aliens()\SpeedY
      If Aliens()\LimitX>0
          prom=Cos(Radian(Aliens()\LimitXcur*90/Aliens()\LimitX))*Aliens()\SpeedX       
          If Aliens()\x + prom>ScrW-32 Or Aliens()\x + prom<0
            If Aliens()\LimitXcur>0
              Aliens()\LimitXcur=Aliens()\LimitX
            Else
              Aliens()\LimitXcur=-1*Aliens()\LimitX
            EndIf
            Aliens()\SpeedX*-1
            prom=Cos(Radian(Aliens()\LimitXcur*90/Aliens()\LimitX))*Aliens()\SpeedX
          EndIf
          Aliens()\LimitXcur+Aliens()\SpeedX
          If Aliens()\SpeedX>0
            If Aliens()\LimitXcur>=Aliens()\LimitX
              Aliens()\SpeedX*-1              
            EndIf
          Else
            If Aliens()\LimitXcur=<-1*Aliens()\LimitX
              Aliens()\SpeedX*-1              
            EndIf
          EndIf         
          Aliens()\x + prom
      Else
        Aliens()\x + Aliens()\SpeedX
      EndIf             
    If Aliens()\NextImageDelay = 0
      If Aliens()\rotate=1
        Aliens()\ActualImage-1
        If Aliens()\ActualImage < Aliens()\EndImage
          Aliens()\ActualImage = Aliens()\StartImage
        EndIf
      Else
        Aliens()\ActualImage+1
        If Aliens()\ActualImage > Aliens()\EndImage
          Aliens()\ActualImage = Aliens()\StartImage
        EndIf
      EndIf     
      Aliens()\NextImageDelay = Aliens()\ImageDelay
    Else
      Aliens()\NextImageDelay-1
    EndIf
    
      If Aliens()\y > ScrH
        DeleteElement(Aliens()) 
      Else 
        If Aliens()\x > ScrW Or Aliens()\x <0
        DeleteElement(Aliens())
        EndIf
      EndIf          
  Wend
Return

;---------------------------CHECK COLLISIONS-------------------

CheckCollisions:
          ;ClipSprite(3,(PlayerImage-Int(PlayerImage/PlayerLenght)*PlayerLenght)*PlayerWidth,Int(PlayerImage/PlayerLenght)*PlayerHeight,PlayerWidth,PlayerHeight)
          ResetList(Bonus())
          While NextElement(Bonus())
            ;ClipSprite(50,(Bonus()\State-Int(Bonus()\State / Bonus()\Lenght)*Bonus()\Lenght)*Bonus()\Width,Int(Bonus()\State / Bonus()\Lenght)*Bonus()\Height,Bonus()\Width,Bonus()\Height)
            If SpritePixelCollision(PlayerImage+200, PlayerX, PlayerY, 394+Bonus()\State, Bonus()\x, Bonus()\y) And Bonus()\ItemId<>4;mine  
              Select Bonus()\ItemId ; +1
                Case 0 ;S
                  Score +500  
                  
                Case 1 ;Automat weapone
                  Score +15
                  If Weapone = 0
                     If  armour<3
                       armour +1       
                     EndIf
                   Else
                     ;new weapone 
                     PlaySound(7, 0,VolVoice)
                     armour = 1
                     Weapone = 0
                   EndIf
                   
                Case 2 ;wire weapone
                  Score +15
                    If Weapone = 1
                     If  armour<3
                       armour +1       
                     EndIf
                   Else
                     ;new weapone
                     PlaySound(6, 0,VolVoice)
                     armour = 1
                     Weapone = 1
                  EndIf               
                  
                Case 3 ;HART                    
                  PlayerLife +1
                  If BlackHoleActiv=0
                    If Random(3)
                      BlackHoleActiv=AddBlackHole(BlackHoleActiv,PlayerX,PlayerY) 
                      BlackHoleDir=Random(1)
                     EndIf
                   EndIf
                   
                Case 5 ;Laser 
                  Score +15
                  If Weapone = 2
                    If  armour<3
                       armour +1       
                     EndIf
                  Else
                     ;new weapone
                     PlaySound(31, 0,VolVoice)
                     armour = 1
                     Weapone = 2 
                  EndIf
              EndSelect
              DeleteElement(Bonus())
            EndIf
          Wend
  ResetList(Aliens())
  While NextElement(Aliens())
  ;State= Aliens()\ActualImage
  ;ClipSprite(Aliens()\SpriteId,(State-Int(State/Aliens()\Lenght)*Aliens()\Lenght)*Aliens()\Width,Int(State/Aliens()\Lenght)*Aliens()\Height,Aliens()\Width,Aliens()\Height)
    ResetList(Bullet())
    While NextElement(Bullet())               
      If Bullet()\BulletDestr = 0
        If SpritePixelCollision(Bullet()\SpriteId+Bullet()\Image, Bullet()\x, Bullet()\y, Aliens()\SpriteId+Aliens()\ActualImage, Aliens()\x, Aliens()\y)
            Bullet()\BulletDestr +1
            Aliens()\Armor - Bullet()\BulletDamage
            PlaySound(Aliens()\SoundId+Random(1), 0, VolFx)          
          EndIf        
       Else
        Bullet()\BulletDestr +1
        If Bullet()\BulletDestr = 2
          DeleteElement(Bullet())
        EndIf 
      EndIf    
    Wend
    If Aliens()\Armor <= 0
      AddElement(Explosion())
      Explosion()\x = Aliens()\x-(128-Aliens()\Width)/2
      Explosion()\y = Aliens()\y-(128-Aliens()\Height)/2      
      Score+20
       If (Score % 100 ) = 0
          Boss =1
        EndIf
        If Score >=NextScoreLife
          PlayerLife+1
          NextScoreLife+5000
       EndIf      
       DeleteElement(Aliens())
    Else
       ResetList(ExplMine())
      While NextElement(ExplMine())
        ;ClipSprite(21,(ExplMine()\State-Int(ExplMine()\State / 5)*5)*160,Int(ExplMine()\State / 5)*160,160,160)
        If SpritePixelCollision(349+ExplMine()\State, ExplMine()\x, ExplMine()\y, Aliens()\SpriteId+Aliens()\ActualImage, Aliens()\x, Aliens()\y)              
              Aliens()\Armor - 500
        EndIf
      Wend    
      If DeadDelay = 0 ; No more invincible...
        If ShieldActiv = 1
          ;ClipSprite(51,(CurShieldSpr-Int(CurShieldSpr/#ShieldLenght)*#ShieldLenght)*#ShieldWidth,Int(CurShieldSpr/#ShieldLenght)*#ShieldHeight,#ShieldWidth,#ShieldHeight) 
          If SpritePixelCollision(52, PlayerX+(PlayerWidth-#ShieldWidth)/2, PlayerY+(PlayerHeight-#ShieldHeight)/2, Aliens()\SpriteId+Aliens()\ActualImage, Aliens()\x, Aliens()\y)          
              Shield - Aliens()\Damage 
              If Shield<=0
                Shield=0
                ShieldActiv = 0 
                PlaySound(9, 0, VolFx)
              EndIf
              AddElement(Explosion())
              Explosion()\x = Aliens()\x-(128-Aliens()\Width)/2
              Explosion()\y = Aliens()\y-(128-Aliens()\Height)/2     
              DeleteElement(Aliens())
            EndIf
            If Shield>0
              Shield - #ShieldUsedStep
              If Shield<=0
                Shield=0
                ShieldActiv=0
                PlaySound(5, 0, VolVoice)
                PlaySound(9, 0, VolFx)
              EndIf
            EndIf
        Else
           If SpritePixelCollision(PlayerImage+200, PlayerX, PlayerY, Aliens()\SpriteId+Aliens()\ActualImage, Aliens()\x, Aliens()\y)
              Dead = 1
              DeadDelay = 300              
              AddElement(Explosion())
              Explosion()\x = Aliens()\x-(128-Aliens()\Width)/2
              Explosion()\y = Aliens()\y-(128-Aliens()\Height)/2       
              DeleteElement(Aliens())
            EndIf
        EndIf      
      EndIf      
    EndIf    
  Wend
Return

;---------------------------DISPLAY BONUS-----------------------------

DisplayBonus:
  ResetList(Bonus())
  While NextElement(Bonus())   ; Take the explosions objects, one by one.
    ; For each object, display the current explosion image (called state here)
    ;ClipSprite(50,(Bonus()\State-Int(Bonus()\State / Bonus()\Lenght)*Bonus()\Lenght)*Bonus()\Width,Int(Bonus()\State / Bonus()\Lenght)*Bonus()\Height,Bonus()\Width,Bonus()\Height)
    Bonus()\y + Bonus()\Speed
    If Bonus()\LifeDelay>50 Or db =1      
      DisplayTransparentSprite(394+Bonus()\State, Bonus()\x, Bonus()\y)
    EndIf
      If Bonus()\y > ScrH
        DeleteElement(Bonus() )
      Else
        If Bonus()\NextDelay = 0
          If Bonus()\State < Bonus()\EndImage
            Bonus()\State+1
            Bonus()\NextDelay = Bonus()\Delay
          Else
            Bonus()\State= Bonus()\StartImage
          EndIf
        Else
          Bonus()\NextDelay-1
          Bonus()\LifeDelay-1         
          If Bonus()\LifeDelay = 0
            If Bonus()\ItemId = 4 ;mine
              AddElement(ExplMine())
              ExplMine()\x = Bonus()\x-(160-Bonus()\Height)/2
              ExplMine()\y = Bonus()\y-(160-Bonus()\Height)/2
              Fade =255
              FadeMode =10
              FadeColor=1
            EndIf 
            DeleteElement(Bonus())
          EndIf
        EndIf
      EndIf     
  Wend
Return
  
  ;----------------------DISPLAY EXPLOSION MINE--------------
  
  DisplayExplMine:
  ResetList(ExplMine())
  While NextElement(ExplMine())   ; Take the explosions objects, one by one.
    ; For each object, display the current explosion image (called state here)
    ;ClipSprite(21,(ExplMine()\State-Int(ExplMine()\State / 5)*5)*160,Int(ExplMine()\State / 5)*160,160,160)
    DisplayTransparentSprite(349+ExplMine()\State, ExplMine()\x, ExplMine()\y)    
    If ExplMine()\State = 0  ; Play the sound only at the explosion start.
        PlaySound(30, 0, VolFx)
      EndIf     
        If ExplMine()\Delay = 0
          If ExplMine()\State < 29
            ExplMine()\State+1
            ExplMine()\Delay = 1
          Else
            DeleteElement(ExplMine())
          EndIf
        Else
          ExplMine()\Delay-1        
        EndIf    
  Wend
  Return
  
; DisplayExplosion:
; -----------------
;
; Once an explosion has been declared (an aliens has been destroyed or the player...), it will be
; displayed inside this routine. The object remains until the end of the explosion (all the pictures
; have been displayed). Then the object is removed with DeleteElement().
;
  
  ;------------------DISPLAY EXPLOSIONS-----------------------
  
DisplayExplosions:
  ResetList(Explosion())
  While NextElement(Explosion())   ; Take the explosions objects, one by one.
    ; For each object, display the current explosion image (called state here)
    ;ClipSprite(20,(Explosion()\State-Int(Explosion()\State/4)*4)*128,Int(Explosion()\State/4)*128,128,128)
    DisplayTransparentSprite(317+Explosion()\State, Explosion()\x, Explosion()\y)
    ;DisplayTransparentSprite(Explosion()\State+20, Explosion()\x, Explosion()\y)
    If Explosion()\Delay = 0
      If Explosion()\State = 0  ; Play the sound only at the explosion start.
        PlaySound(2, 0, VolFx)
      EndIf
      If Explosion()\State < 31
        Explosion()\State+1
        Explosion()\Delay = 1
      Else   
        If DeadDelay<150
          If Int(Score/750)<21
            RndItem = BonusE(Int(Score/750)+Random(20)) 
          Else
            RndItem = BonusE(20+Random(20))           
          EndIf         
          If RndItem >0 And Score>=BonusStage(RndItem) ; 0 - nothing
              AddElement(Bonus())
              Bonus()\ItemId = RndItem-1
              Bonus()\x = Explosion()\x+48
              If Bonus()\x <0
                Bonus()\x =0
              EndIf
              If Bonus()\x >ScrW
                Bonus()\x =ScrW-32
              EndIf
              Bonus()\y = Explosion()\y+48
              Bonus()\Width  = 32 
              Bonus()\Height = 32
              Bonus()\Lenght = 12
              If RndItem=5 ; mine
                Bonus()\Speed  = 0
              Else
                Bonus()\Speed  = Random(1)+1
              EndIf                
              Bonus()\StartImage  = Bonus()\ItemId*Bonus()\Lenght 
              Bonus()\EndImage    = Bonus()\StartImage+Bonus()\Lenght-1
              Bonus()\Delay  =  3
              Bonus()\NextDelay = Bonus()\Delay
              Bonus()\State = Bonus()\ItemId*Bonus()\Lenght
              Bonus()\LifeDelay = 100
           EndIf
        EndIf      
        DeleteElement(Explosion())
      EndIf
    Else
      Explosion()\Delay-1
    EndIf
  Wend
  Return  
  
  DataSection
   fs: 
   IncludeBinary "Data\strike.TTF"
   fe:
   Start_snda:
   IncludeBinary "Data\Sounds\Auquid.ogg"
   End_snda:
   _SndDubStart:
   IncludeBinary "Data\Sounds\2DUB.ogg"
   _SndDubEnd:
   _SndLazer:
   IncludeBinary "Data\Sounds\Lazer.wav"
   _SndExpl:
   IncludeBinary "Data\Sounds\Explosion.wav"
   _SndExpl2:
   IncludeBinary "Data\Sounds\Expl2.wav"
    _SndWarnAster:
    IncludeBinary "Data\Sounds\warning.wav"
    _SndShieldDeactiv:
    IncludeBinary "Data\Sounds\deactivated_shield.wav"
    _SndGunLaser:
    IncludeBinary "Data\Sounds\GunLaser.wav"
    _SndGunFireball:
    IncludeBinary "Data\Sounds\Fireball.wav"
    _SndGunFlamethrower:
    IncludeBinary "Data\Sounds\Flamethrower.wav"
    _SndStoneSwoosh:
    IncludeBinary "Data\Sounds\swoosh.wav"
    _SndShieldDown:
    IncludeBinary "Data\Sounds\Shield_down.wav"
    _SndFireballshoot:
    IncludeBinary "Data\Sounds\Fireballshoot.wav"
    _SndTum:
    IncludeBinary "Data\Sounds\tum-tum.wav"
    _SndIron:
    IncludeBinary "Data\Sounds\iron18.wav"
    _SndIron2:
    IncludeBinary "Data\Sounds\iron9.wav"
    _SndWood:
    IncludeBinary "Data\Sounds\wood10.wav"
    _SndWood2:
    IncludeBinary "Data\Sounds\wood13.wav"
    _SndBlackHole:
    IncludeBinary "Data\Sounds\BlackHole.wav" 
   _TitlePicture:
   IncludeBinary "Data\sprites\title.bmp"
   _TitlePicture2:
   IncludeBinary "Data\sprites\title_belt.png"   
   _Fire1:
   IncludeBinary "Data\sprites\fire2.png"
    _Laser:
   IncludeBinary "Data\sprites\Laser.png"
   _Ship1:
   IncludeBinary "Data\sprites\main_ship.png"  
   _Pl1:
   IncludeBinary "Data\sprites\Pl_1.bmp"
   _Pl2:
   IncludeBinary "Data\sprites\Pl_2.bmp"
   _Alien:
   IncludeBinary "Data\sprites\ast1.png"   
   _Expl1:
   IncludeBinary "Data\sprites\explosion03_4x9.png"
   _Expl2:
   IncludeBinary "Data\sprites\Expl_mine.png"
   _Stone1:
   IncludeBinary "Data\sprites\stone3.png"
   _Bonus:
   IncludeBinary "Data\sprites\bonus.png"
   _Shield:
   IncludeBinary "Data\sprites\shield_4x3.png" 
    _ShieldMask:
   IncludeBinary "Data\sprites\Shield_mask.png"
   _Engine:
   IncludeBinary "Data\sprites\Engine_5x2.png" 
   _Alien2:
   IncludeBinary "Data\sprites\ast2.png"
   _BlackHole:
   IncludeBinary "Data\sprites\BlackHole2.png"
   EndDataSection
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 1748
; FirstLine = 1793
; Folding = --
; Optimizer
; EnableThread
; EnableXP
; EnableUser
; UseIcon = Data\Back\Back_ico.ico
; Executable = Asteroid Belt (x64).exe
; EnableUnicode