
;here we go for allloading effects/infos/saving gui in realtime, so the player can see if game saves or loads data


Procedure E_SAVING_SCREEN(_sound.b)
  
  E_ENGINE_BUILD_IN_EFFECT_DISK_DRIVE_SOUND_PLAY()
  
  If e_engine\e_engine_use_load_icon=#False
   ProcedureReturn #False  
  EndIf
  

       If IsSprite(e_engine\e_loading_banner_id)
         DisplayTransparentSprite(e_engine\e_loading_banner_id,e_engine\e_engine_internal_screen_w-SpriteWidth(e_engine\e_loading_banner_id)-16,player_statistics\player_health_bar_pos_y-8,200) 
       EndIf
       
      FlipBuffers()
       
     EndProcedure

Procedure E_LOADING_SCREEN(_sound.b)
  
  ;E_ENGINE_BUILD_IN_EFFECT_DISK_DRIVE_SOUND_PLAY()
  
  If e_engine\e_engine_use_load_icon=#False
    
  ProcedureReturn #False  
  EndIf
  

       If IsSprite(e_engine\e_loading_banner_id)
         DisplayTransparentSprite(e_engine\e_loading_banner_id,e_engine\e_engine_internal_screen_w-SpriteWidth(e_engine\e_loading_banner_id)-16,player_statistics\player_health_bar_pos_y-8,200) 
       EndIf
       
      FlipBuffers()
       
     EndProcedure
; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 14
; Folding = -
; EnableAsm
; EnableThread
; EnableXP
; EnableUser
; DPIAware
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant