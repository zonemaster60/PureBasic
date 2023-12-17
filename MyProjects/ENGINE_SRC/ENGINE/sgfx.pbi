;sgxf routines:


Procedure E_INIT_CRT()
  

  e_engine\e_crt_gfx_id_source=e_engine\e_graphic_source+e_engine\e_crt_gfx_id_source
  

  
EndProcedure



Procedure E_LOAD_CRT_EFFECT()
  
  
 
   e_engine\e_crt_gfx_id=LoadSprite(#PB_Any, e_engine\e_crt_gfx_id_source,#PB_Sprite_AlphaBlending)
  
EndProcedure


Procedure E_SHOW_CRT_EFFECT()
  ;some very simple try...
   If e_engine\e_crt_show=#False
  ProcedureReturn #False  
  EndIf

  If IsSprite(e_engine\e_crt_gfx_id)=0
    ProcedureReturn #False  
  EndIf
 
 
  SpriteBlendingMode(#PB_Sprite_BlendSourceColor, #PB_Sprite_BlendInvertSourceAlpha)
  ;SpriteBlendingMode(#PB_Sprite_BlendSourceColor, #PB_Sprite_BlendInvertDestinationColor)
  DisplayTransparentSprite(e_engine\e_crt_gfx_id,0,e_engine\e_crt_scan_line_rnd,e_engine\e_crt_effect_level+e_engine\e_crt_effect_noise_rnd)  
  SpriteBlendingMode(#PB_Sprite_BlendSourceAlpha, #PB_Sprite_BlendInvertSourceAlpha)
   
EndProcedure


Procedure E_CRT_ON_OFF()
  
  e_engine\e_crt_show=#True-e_engine\e_crt_show

  
  
EndProcedure



Procedure E_SHOW_GLASS_EFFECT()
  

  
  If world_object()\object_use_glass_effect<>#True
  ProcedureReturn #False  
  EndIf
  
  If IsSprite(world_object()\object_glass_effect_gfx_id)=0
  ProcedureReturn #False  
  EndIf
  
  DisplayTransparentSprite(world_object()\object_glass_effect_gfx_id,world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_glass_effect_offset_x,world_object()\object_y+e_engine\e_world_offset_y+world_object()\object_glass_effect_offset_y,world_object()\object_glass_effect_intensity)

EndProcedure



Procedure E_GLASS_EFFECT()
  ;try some effects like glass/ice
  
   If e_engine_build_in_effect\e_sgfx_effect_do=#False
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_use_glass_effect=#False
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_glass_effect_grab_size<1
  ProcedureReturn #False  
  EndIf
  
  
  
  If IsSprite(world_object()\object_glass_effect_gfx_id)
     FreeSprite(world_object()\object_glass_effect_gfx_id)  
  EndIf
  
  
  world_object()\object_glass_effect_gfx_id=GrabSprite(#PB_Any,world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_glass_effect_grab_x,world_object()\object_y+e_engine\e_world_offset_y+world_object()\object_glass_effect_grab_y,world_object()\object_glass_effect_grab_size,world_object()\object_glass_effect_grab_size,#PB_Sprite_AlphaBlending)
  
  
If IsSprite(world_object()\object_glass_effect_gfx_id)=0
  ProcedureReturn #False  
EndIf


ZoomSprite(world_object()\object_glass_effect_gfx_id,world_object()\object_w-world_object()\object_glass_effect_offset_x-world_object()\object_glass_effect_offset_x,world_object()\object_h-world_object()\object_glass_effect_offset_y-world_object()\object_glass_effect_offset_y)
  
   
EndProcedure


Procedure E_STAMP_OVERLAY_SHOW()
  
  If e_engine\e_map_use_black_stamp=#False
  ProcedureReturn #False  
  EndIf
  
  
  If IsSprite(e_engine\e_stamp_over_lay_id)=0
  ProcedureReturn #False  
  EndIf
  ;TransparentSpriteColor(e_engine\e_stamp_over_lay_id,stamp_mask_buffer\stamp_buffer_cut_out_color)
  ;SpriteBlendingMode(#PB_Sprite_BlendSourceColor, #PB_Sprite_BlendDestinationAlpha)  ;not perfect....hot sun !!!
  SpriteBlendingMode(#PB_Sprite_BlendSourceColor, #PB_Sprite_BlendInvertSourceAlpha)
  DisplayTransparentSprite(e_engine\e_stamp_over_lay_id,0,0,200);stamp_mask_buffer\stamp_buffer_transparency) 
  SpriteBlendingMode(#PB_Sprite_BlendSourceAlpha, #PB_Sprite_BlendInvertSourceAlpha)
  EndProcedure



Procedure E_STAMP_OVERLAY()
  
  
  ;init for a new frame:
  
  If e_engine_build_in_effect\e_sgfx_effect_do=#False
  ProcedureReturn #False  
  EndIf
  
  
  If  e_engine\e_map_use_black_stamp=#False
  ProcedureReturn #False  
  EndIf
  

      
  If IsSprite(stamp_mask_buffer\back_buffer_id)=0
  e_engine\e_map_use_black_stamp=#False
  ProcedureReturn #False  
  EndIf
  
  
    
  If IsSprite(e_engine\e_stamp_over_lay_id)
  FreeSprite(e_engine\e_stamp_over_lay_id)  
  EndIf
  
  
   DisplayTransparentSprite(stamp_mask_buffer\back_buffer_id,0,0,100)
;   DisplayTransparentSprite(stamp_mask_buffer\stamp_buffer_id,player_statistics\player_pos_x-stamp_mask_buffer\stamp_buffer_size_x/2,player_statistics\player_pos_y-stamp_mask_buffer\stamp_buffer_size_y/2,255) ;player stamp
  
  
  ;here we go for the world objects in view:
;   
  ResetList(world_object())
  ForEach world_object()
    
    If world_object()\object_is_in_gfx_area 
      
           
      If world_object()\object_is_active
        
        If world_object()\object_use_stamp=#True
          If IsSprite(world_object()\object_stamp_gfx_id)
          DisplayTransparentSprite(world_object()\object_stamp_gfx_id,world_object()\object_x+e_engine\e_world_offset_x-world_object()\object_stamp_gfx_width,world_object()\object_y+e_engine\e_world_offset_y-world_object()\object_stamp_gfx_height,world_object()\object_stamp_transparency)
          EndIf
        EndIf
        
        
        
      EndIf
      
      
      
      
    EndIf
    
    
    
  Next

  
  e_engine\e_stamp_over_lay_id=GrabSprite(#PB_Any,0,0,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,#PB_Sprite_AlphaBlending)
  

EndProcedure

Procedure E_SGFX_CRT_EFFECT()
  
  If e_engine\e_crt_show=#False
  ProcedureReturn #False  
  EndIf
  
  e_engine\e_crt_effect_noise_rnd=Random(e_engine\e_crt_effect_noise)
  e_engine\e_crt_scan_line_rnd=Random(e_engine\e_crt_scan_line)
  
EndProcedure


Procedure E_SGFX_INTENSITY(_mode.i)
  
 ;this controls all sgfx attached or attach to engine-timer 
  
  E_SGFX_CRT_EFFECT()
  
  
 
     
  Select e_engine_build_in_effect\e_sgfx_effect_mode
      
      Case #SGFX_DEFAULT
  
  If e_engine_build_in_effect\e_sgfx_effect_time>e_engine_heart_beat\beats_since_start
    e_engine_build_in_effect\e_sgfx_effect_do=#False
    ProcedureReturn #False
  EndIf
  e_engine_build_in_effect\e_sgfx_effect_do=#True
  e_engine_build_in_effect\e_sgfx_effect_time=e_engine_heart_beat\beats_since_start+e_engine_build_in_effect\e_sgfx_effect_timer
  
  
Case #SGFX_DYNAMIC
  
  
  
  If e_engine_build_in_effect\e_sgfx_effect_time>e_engine_heart_beat\beats_since_start
    e_engine_build_in_effect\e_sgfx_effect_do=#False
    ProcedureReturn #False
  EndIf
  e_engine_build_in_effect\e_sgfx_effect_do=#True
  
  e_engine_build_in_effect\e_sgfx_effect_dynamic_timer=e_engine_build_in_effect\e_sgfx_object_counter*e_engine_build_in_effect\e_frame_rate
  
  e_engine_build_in_effect\e_sgfx_effect_time=e_engine_heart_beat\beats_since_start+e_engine_build_in_effect\e_sgfx_effect_dynamic_timer
  
Default
  
  If e_engine_build_in_effect\e_sgfx_effect_time>e_engine_heart_beat\beats_since_start
    e_engine_build_in_effect\e_sgfx_effect_do=#False
    ProcedureReturn #False
  EndIf
  e_engine_build_in_effect\e_sgfx_effect_do=#True
  e_engine_build_in_effect\e_sgfx_effect_time=e_engine_heart_beat\beats_since_start+e_engine_build_in_effect\e_sgfx_effect_timer
  
  EndSelect
  
  
  
EndProcedure
