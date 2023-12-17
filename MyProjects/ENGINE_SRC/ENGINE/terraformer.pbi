


;******************************************** VERSION 2.0 *************************************************************
;EMITTERSYSTEM NOW WORKS WITTH DIFFERENT EMITTERTYPE 
; 
;
;
;**********************************************************************************************************************


;here we organize all the world calculating and presentation 
;Declare E_KEYBOARD_BASE()
; 
;  ;----------------------------STANDARD SPRITE BLENDING---------------------
;     SpriteBlendingMode(#PB_Sprite_BlendSourceAlpha, #PB_Sprite_BlendInvertSourceAlpha) 
;  ;------------------------------------------------------------------------


Declare    E_GET_ALTERNATIVE_AI42_OBJECT()
Declare    E_SETUP_BOSS_HEALTH_BAR()
Declare    E_SCREEN_FADE_GRAB(_void.b)
Declare    E_CORRECT_POSITION_IF_TRANSPORTED(_void.b)
Declare    E_SORT_MAP_OBJECTS_BY_Y()





Procedure E_SHOW_HIT_BOX()
  
  ;debug output to show hitboxes
  If e_engine\e_show_debug<>#True Or world_object()\object_collision=#False
  ProcedureReturn #False  
  EndIf
  
  DisplayTransparentSprite(world_object()\object_hit_box_gfx_id,world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_hit_box_x,world_object()\object_y+e_engine\e_world_offset_y+world_object()\object_hit_box_y,100,RGB(255,0,0))
  
  
EndProcedure




Procedure E_ANIM_STOP_AFTER_LAST_FRAME()
  
    If world_object()\object_anim_stop_after_last_frame=#False
    ProcedureReturn #False  
    EndIf
    
    world_object()\object_is_anim=#False
    
    
    
    EndProcedure




Procedure E_REMOVE_AFTER_LAST_ANIM_FRAME()
  
  ;use anim frames for object lifetime, so we can show eg: explosions without using a timer
  
  If world_object()\object_remove_after_last_anim_frame=#False
  ProcedureReturn #False  
  EndIf
  world_object()\object_remove_from_list=#True
  
     
EndProcedure



Procedure E_CHANGE_AFTER_LAST_ANIM_FRAME()
  
  ;use anim frames for object lifetime, so we can show eg: explosions without using a timer
  
  If world_object()\object_remove_after_last_anim_frame=#True
  ProcedureReturn #False  
  EndIf

  
  If world_object()\object_change_on_last_frame=#False
    ProcedureReturn #False
  EndIf
    
     E_GET_ALTERNATIVE_AI42_OBJECT()
  
EndProcedure






Procedure E_PLAYER_SHOW_TORCH_LIGHT()
  
  ;show the torch light if night is present
  
  If   player_statistics\player_use_torch<>#False
    ProcedureReturn #False  
  EndIf
  
  
  If IsSprite(player_statistics\player_torch_light_id)
  ;  E_GFX_BLENDMODE_LIGHT()
    DisplayTransparentSprite(player_statistics\player_torch_light_id,world_object()\object_x+e_engine\e_world_offset_x.f-player_statistics\player_torch_light_width+world_object()\object_w/2,world_object()\object_y+e_engine\e_world_offset_y.f-player_statistics\player_torch_light_height+world_object()\object_h/2,player_statistics\player_torch_light_transparency)
  EndIf  
  ;E_GFX_BLENDMODE_DEFAULT()
  
EndProcedure



Procedure E_SHOW_PLAYER_FIGHT_SYMBOL()
  
  If IsSprite(player_statistics\player_fight_symbol_id)=0
  ProcedureReturn #False  
  EndIf
  
  
  If player_statistics\player_in_fight=#False
    ProcedureReturn #False  
  EndIf
  
       DisplayTransparentSprite(player_statistics\player_fight_symbol_id,world_object()\object_x+e_engine\e_world_offset_x.f-player_statistics\player_fight_symbol_width+world_object()\object_w/2,world_object()\object_y+e_engine\e_world_offset_y.f-player_statistics\player_fight_symbol_height+world_object()\object_h/2,player_statistics\player_fight_symbol_transparency)


  
  
EndProcedure


Procedure E_PLAYER_SHOW_TORCH_LIGHT_BIG()
  
  
  If  e_engine\e_map_use_black_stamp=#False
    ProcedureReturn #False  
  EndIf
  
  
  If IsSprite(player_statistics\player_torch_light_big_id)
      DisplayTransparentSprite(player_statistics\player_torch_light_big_id,world_object()\object_x+e_engine\e_world_offset_x.f-player_statistics\player_torch_light_big_width+world_object()\object_w/2,world_object()\object_y+e_engine\e_world_offset_y.f-player_statistics\player_torch_light_big_height+world_object()\object_h/2,player_statistics\player_torch_light_big_transparency)
  EndIf  

  
EndProcedure





Procedure E_SHOW_ENEMY_FIGHT_SYMBOL()

  If IsSprite(world_object()\object_fight_effect_id)=0
  ProcedureReturn #False  
EndIf

  If world_object()\object_is_in_fight=#False
    ProcedureReturn #False  
  EndIf
  
  If world_object()\object_use_fight_effect=#False
  ProcedureReturn #False  
  EndIf
  
      
       DisplayTransparentSprite(world_object()\object_fight_effect_id,world_object()\object_x+e_engine\e_world_offset_x.f-world_object()\object_fight_effect_w/4,world_object()\object_y+e_engine\e_world_offset_y.f-world_object()\object_fight_effect_h/4,player_statistics\player_fight_symbol_transparency)

EndProcedure



Procedure E_SHOW_DANGER_ENEMY()
  ;if attack level of enemy is > player health + shield we show the player that the enemy is maybe unbeatable
  
  If IsSprite(world_object()\object_danger_gfx_id)=0
  ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_show_boss_bar=#True
     ProcedureReturn #False  
  EndIf
  
  If (player_statistics\player_health_max+player_statistics\player_level_defence_max)<world_object()\object_attack
    
    If world_object()\object_danger_gfx_is_active=#True And IsSprite(world_object()\object_danger_gfx_id)
          DisplayTransparentSprite(world_object()\object_danger_gfx_id,world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y-world_object()\object_danger_gfx_hight)
  EndIf
EndIf

   

  
  
  
EndProcedure









Procedure E_SHOW_BOSS_NAME()
  
  If boss_bar\boss_bar_is_active=#False Or boss_bar\boss_bar_actual_health<1
  ProcedureReturn #False  
  EndIf
  
  
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(#FONT_XP_BAR))
  DrawText(boss_bar\boss_bar_x+boss_bar\boss_bar_boss_name_x_offset,boss_bar\boss_bar_y+boss_bar\boss_bar_boss_name_y_offset,e_engine\e_boss_object_name_to_show,RGB(255,255,255))

  
  
EndProcedure


Procedure E_BOSS_SHOW_HEALTH_BAR(_mode.i)
  
  
  If boss_bar\boss_bar_is_active=#False Or boss_bar\boss_bar_actual_health<1
    ProcedureReturn #False  
  EndIf
  
  Select _mode.i
      
      
    Case #BOSS_BAR_SHOW_COVER
      
      
  If IsSprite(boss_bar\boss_bar_cover_gfx_id)
    DisplayTransparentSprite(boss_bar\boss_bar_cover_gfx_id,boss_bar\boss_bar_x,boss_bar\boss_bar_y,boss_bar\boss_bar_cover_transparency)
  EndIf
  
  Default
  
  E_SETUP_BOSS_HEALTH_BAR()
  
  If IsSprite(boss_bar\boss_bar_back_gfx_id)
    DisplayTransparentSprite(boss_bar\boss_bar_back_gfx_id,boss_bar\boss_bar_x,boss_bar\boss_bar_y,200)
  EndIf
  
  If IsSprite(boss_bar\boss_bar_front_gfx_id)
    DisplayTransparentSprite(boss_bar\boss_bar_front_gfx_id,boss_bar\boss_bar_x,boss_bar\boss_bar_y,200)
  EndIf
  
  If IsSprite(boss_bar\boss_bar_danger_gfx_id)=0
    ProcedureReturn #False  
  EndIf
  
  DisplayTransparentSprite(boss_bar\boss_bar_danger_gfx_id,boss_bar\boss_bar_danger_x,boss_bar\boss_bar_danger_y,255)
  EndSelect
  
  
EndProcedure 


  

Procedure E_ENEMY_SHOW_HEALTH_BAR()
  
  If world_object()\object_show_boss_bar=#True
    ProcedureReturn #False  
  EndIf
  
  If world_object()\object_hp<1 Or world_object()\object_show_hp_bar=#False  
    ProcedureReturn #False  
  EndIf
  If IsSprite(world_object()\object_health_bar_back_id)
    DisplayTransparentSprite(world_object()\object_health_bar_back_id,world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y)  
  EndIf
  If IsSprite(world_object()\object_health_bar_id)
    DisplayTransparentSprite(world_object()\object_health_bar_id,world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y)  
  EndIf
  
EndProcedure
  
 
 
 

Procedure E_RELOAD_WORLD()
  ;we can use this for save/load and other resets
  e_engine\e_next_world=e_engine\e_actuall_world
  e_engine\e_actuall_world=""
  EndProcedure








Procedure  E_CHECK_FOR_SPECIAL_GATE()
  
  ;here we handle some special keys/doors for important player control -most of them are flip flop gates, so player can not miss powerfull loot
  
  Select world_object()\object_internal_name
      
    Case "#LOOT_SWITCH"  ;important to prevent player from leaving areas without important loot
      
      world_object()\object_collision=1-world_object()\object_collision
      e_gate_to_open_name.s="NOGATE"
      
      ProcedureReturn #True
      
    Default 
      
      ProcedureReturn #False  
      
  EndSelect
  
  
EndProcedure

  

Procedure E_PERSPECTIVE_SHADOW()
  
  ;some hardcoded situations for debugging/developement..experimental, shadow system
  

  If IsSprite(world_object()\object_shadow_gfx_id)=0
       ProcedureReturn #False  
  EndIf
  

DisplayTransparentSprite(world_object()\object_shadow_gfx_id,world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_h+world_object()\object_shadow_offset_y,world_object()\object_shadow_intense,world_object()\object_shadow_color)


EndProcedure




Procedure E_ANIM_SPRITE_ID()
  
  ;******************HERE WE HANDLE ALL ANIM RELEATED SITUATIONS FOR PLAYER AND ALL OTHER OBJECTS WITH ANIM FLAG
  ; 
  ;************************************************************************************************************************************
  
  
  
  
  If e_engine_heart_beat\beats_since_start<world_object()\object_anim_timer  ;actual object 
    e_engine\e_do_anim=#False 
  Else
    e_engine\e_do_anim=#True
    world_object()\object_anim_timer=e_engine_heart_beat\beats_since_start+world_object()\object_anim_frame_time  
    
  EndIf
  
    
;perspective shadowsystem is not working... base code is on position
  
  ;------------------ end full screen handling
  
 Define _direction.i=world_object()\object_last_move_direction_x 
 
 

 
  If e_engine\e_do_anim=#True
    

  
    
    
    If world_object()\object_move_direction_x=#NO_DIRECTION
      _direction.i=world_object()\object_last_move_direction_x
    ;world_object()\object_move_direction_x=world_object()\object_last_move_direction_x  
    EndIf
    
    If world_object()\object_move_direction_y=#NO_DIRECTION Or  world_object()\object_last_move_direction_y<>#NO_DIRECTION
      _direction.i=world_object()\object_last_move_direction_x
   ;world_object()\object_move_direction_x=world_object()\object_last_move_direction_x 
    EndIf
 
    
;     If world_object()\object_anim_move_direction_x<>#NO_DIRECTION
;       _direction.i=world_object()\object_anim_move_direction_x
;     EndIf
;     
    If world_object()\object_guarded=#True
      _direction.i=#LOOP 
    EndIf
    
    If world_object()\object_anim_loop=#True
    _direction.i=#LOOP  
    EndIf
    
;     ;attack
;     
;        If  world_object()\object_is_attacking=#True  ;special for attack, because we do not use move direction if attack anim is started
;          
;          
;          
;          If world_object()\object_actual_anim_frame_attack<world_object()\object_last_anim_frame_attack And world_object()\object_is_anim_attack=#True
;           If Random(world_object()\object_random_anim_start)=0
;             world_object()\object_actual_anim_frame_attack+1 
;           EndIf
;           
;           
;         Else
;           world_object()\object_actual_anim_frame_attack=0
;           E_REMOVE_AFTER_LAST_ANIM_FRAME()
;           E_CHANGE_AFTER_LAST_ANIM_FRAME()
;           
;         EndIf
;         
;         If world_object()\object_use_shadow=#True
;           
;           If world_object()\object_shadow_use_perspective=#True
;             If IsSprite(world_object()\object_gfx_id_frame_anim_attack[world_object()\object_actual_anim_frame_attack])
;              E_PERSPECTIVE_SHADOW()
;             EndIf
;           EndIf
;           
;           If world_object()\object_shadow_use_perspective=#False
;             If IsSprite(world_object()\object_gfx_id_frame_anim_attack[world_object()\object_actual_anim_frame_attack])
;               DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_attack[world_object()\object_actual_anim_frame_attack],world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
;             EndIf
;           EndIf
;           
;    
;         
;         EndIf
;       
;       If IsSprite(world_object()\object_gfx_id_frame_anim_attack[world_object()\object_actual_anim_frame_attack])
;         DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_attack[world_object()\object_actual_anim_frame_attack],world_object()\object_x+e_engine\e_world_offset_x.f,world_object()\object_y+e_engine\e_world_offset_y.f,world_object()\object_transparency)
;       EndIf
;       ProcedureReturn #False
;          
;    
;     EndIf
;     
;  ;---------   
    
    ;for the anim offset:
   
    
    
    If  _direction.i=#LOOP
      
     
      
      
      If world_object()\object_actual_anim_frame_default>= world_object()\object_last_anim_frame_default
         world_object()\object_anim_loop_direction=-1
    
         
      EndIf
      
     
      If world_object()\object_actual_anim_frame_default<1
        world_object()\object_anim_loop_direction=1
       EndIf

    
  
    
  
    
     
    If Random(world_object()\object_random_anim_start)=0
        world_object()\object_actual_anim_frame_default+world_object()\object_anim_loop_direction
      EndIf
      
      
      E_REMOVE_AFTER_LAST_ANIM_FRAME()
      E_CHANGE_AFTER_LAST_ANIM_FRAME()
      E_ANIM_STOP_AFTER_LAST_FRAME()
      

  
   
      
      If world_object()\object_use_shadow=#True
        
        If world_object()\object_shadow_use_perspective=#True
          If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
            E_PERSPECTIVE_SHADOW()
          EndIf
        EndIf
        
        If world_object()\object_shadow_use_perspective=#False
          If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default],world_object()\object_x+e_engine\e_world_offset_x+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
          EndIf
        EndIf
        
        
        
      EndIf
      
      If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
        DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default],world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y.f+e_world_shake\world_shake_vertical,world_object()\object_transparency)

      EndIf
      
      ProcedureReturn #False
    EndIf
    
    
    
    
    If  _direction.i=#LEFT
    
     
      
          If world_object()\object_actual_anim_frame_left<world_object()\object_last_anim_frame_left  And world_object()\object_is_anim_left=#True
          If Random(world_object()\object_random_anim_start)=0
            world_object()\object_actual_anim_frame_left+1
          EndIf
        
          
        Else
          
         
       world_object()\object_actual_anim_frame_left=0
                
         
          E_REMOVE_AFTER_LAST_ANIM_FRAME()
          E_CHANGE_AFTER_LAST_ANIM_FRAME()
          E_ANIM_STOP_AFTER_LAST_FRAME()
          
        EndIf
        
        If world_object()\object_use_shadow=#True
          
          If world_object()\object_shadow_use_perspective=#True
            If IsSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left])
             E_PERSPECTIVE_SHADOW()
            EndIf
          EndIf
          
          If world_object()\object_shadow_use_perspective=#False
            If IsSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left],world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
            EndIf
          EndIf
          
   
        
        EndIf
      
      If IsSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left])
        DisplayTransparentSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left],world_object()\object_x+e_engine\e_world_offset_x.f+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y.f+e_world_shake\world_shake_vertical,world_object()\object_transparency)

      EndIf
      
      ProcedureReturn #False
    EndIf
    
    
    

        
       If  _direction.i=#RIGHT
        
        
         
                
        If world_object()\object_actual_anim_frame_right<world_object()\object_last_anim_frame_right And world_object()\object_is_anim_right=#True
          If Random(world_object()\object_random_anim_start)=0
             world_object()\object_actual_anim_frame_right+1  
          EndIf
        Else
          
          world_object()\object_actual_anim_frame_right=0
          E_REMOVE_AFTER_LAST_ANIM_FRAME()
          E_CHANGE_AFTER_LAST_ANIM_FRAME()
          E_ANIM_STOP_AFTER_LAST_FRAME()
          
        EndIf
        
        
        If world_object()\object_use_shadow=#True 
          
             If world_object()\object_shadow_use_perspective=#True
            If IsSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right])
               E_PERSPECTIVE_SHADOW()
              
            EndIf
          EndIf
          ;----
          
               If world_object()\object_shadow_use_perspective=#False
            If IsSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right],world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y,world_object()\object_shadow_intense, world_object()\object_shadow_color)
              
            EndIf
          EndIf
     
          
       EndIf
      
      If IsSprite((world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right]))
        DisplayTransparentSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right],world_object()\object_x+e_engine\e_world_offset_x.f+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y.f+e_world_shake\world_shake_vertical,world_object()\object_transparency)

      EndIf 
     
      ProcedureReturn #False
      
    EndIf
 
If  world_object()\object_move_direction_y=#UP
        
  ProcedureReturn #False ;this routine is not used for this game
               
        If world_object()\object_actual_anim_frame_up<world_object()\object_last_anim_frame_up  And world_object()\object_is_anim_up=#True
          If Random(world_object()\object_random_anim_start)=0
            world_object()\object_actual_anim_frame_up+1 
          EndIf
          
          
        Else
                    world_object()\object_actual_anim_frame_up=0
                    E_REMOVE_AFTER_LAST_ANIM_FRAME()
                    E_CHANGE_AFTER_LAST_ANIM_FRAME()
                    E_ANIM_STOP_AFTER_LAST_FRAME()
        EndIf
        
        If world_object()\object_use_shadow=#True 
          If world_object()\object_shadow_use_perspective=#False
            If IsSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up],world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
                
            EndIf
          EndIf
          
          
          If world_object()\object_shadow_use_perspective=#True
            If IsSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up])
              E_PERSPECTIVE_SHADOW()
            EndIf
          EndIf
          
        EndIf
    
      
      If IsSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up])
        DisplayTransparentSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up],world_object()\object_x+e_engine\e_world_offset_x.f+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y.f+e_world_shake\world_shake_vertical,world_object()\object_transparency)

      EndIf
     
      ProcedureReturn #False 
      
    EndIf
    
      
        If world_object()\object_move_direction_x=#DOWN
        
        
        If world_object()\object_actual_anim_frame_down<world_object()\object_last_anim_frame_down  And world_object()\object_is_anim_down=#True
          If Random(world_object()\object_random_anim_start)=0
            world_object()\object_actual_anim_frame_down+1  
          EndIf
          
                    
        Else
                    world_object()\object_actual_anim_frame_down=0
                    E_REMOVE_AFTER_LAST_ANIM_FRAME()
                    E_CHANGE_AFTER_LAST_ANIM_FRAME()
                    E_ANIM_STOP_AFTER_LAST_FRAME()
          
        EndIf
        
        If world_object()\object_use_shadow=#True 
          If world_object()\object_shadow_use_perspective=#False
            If IsSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down],world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
            EndIf
          EndIf
          
          
            If world_object()\object_shadow_use_perspective=#True
            If IsSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down])
              E_PERSPECTIVE_SHADOW()
         
            EndIf
          EndIf
        EndIf
        
          If  IsSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down])
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down],world_object()\object_x+e_engine\e_world_offset_x.f+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y.f+e_world_shake\world_shake_vertical,world_object()\object_transparency)

          EndIf
          
          ProcedureReturn #False
           
        EndIf
        
     
  
  
        ;---------------------------------------------------------------------------------------------------------------------------------
        

      
        

    
   ; ProcedureReturn  world_object()\object_actual_anim_frame_default  ;used for the terraformer, for defaultanim rotate effects 
    
  EndIf ;if  _doanim = #true
  
  
  ;here we have the overall _doanim=#false
  
  If e_engine\e_do_anim=#False  
    
      
      If world_object()\object_move_direction_x=#NO_DIRECTION
       _direction.i=world_object()\object_last_move_direction_x  
    EndIf
    
    If world_object()\object_move_direction_y=#NO_DIRECTION Or world_object()\object_last_move_direction_y=#NO_DIRECTION
      ;world_object()\object_move_direction_x=world_object()\object_last_move_direction_x 
      _direction.i=world_object()\object_last_move_direction_x  
    EndIf
    
    
    If world_object()\object_anim_loop=#True
    _direction.i=#LOOP  
    EndIf
    
    
    Select world_object()\object_last_move_direction_y
;         
;       Case #UP
;         
;         If world_object()\object_is_anim_up=#True
;           
;           If world_object()\object_use_shadow=#True 
;             If world_object()\object_shadow_use_perspective=#False
;               If IsSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up])
;                 DisplayTransparentSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up],world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
;               EndIf
;             EndIf
;             
;                 If world_object()\object_shadow_use_perspective=#True
;               If IsSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up])
;                 E_PERSPECTIVE_SHADOW()
;                  EndIf
;             EndIf
;             
;           EndIf
;      
;       If IsSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up])
;         DisplayTransparentSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up],world_object()\object_x+e_engine\e_world_offset_x.f,world_object()\object_y+e_engine\e_world_offset_y.f,world_object()\object_transparency)
;       EndIf
;     EndIf
    
;       Case #DOWN
;         
;         If world_object()\object_is_anim_down=#True
;           
;           If world_object()\object_use_shadow=#True 
;             If world_object()\object_shadow_use_perspective=#False
;               If IsSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down])
;                 DisplayTransparentSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down],world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
;               EndIf
;             EndIf
;             
;             If world_object()\object_shadow_use_perspective=#True
;               If IsSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down])
;                 E_PERSPECTIVE_SHADOW()
;               EndIf
;             EndIf
;           EndIf
;       
;       If IsSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down])
;         DisplayTransparentSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down],world_object()\object_x+e_engine\e_world_offset_x.f,world_object()\object_y+e_engine\e_world_offset_y.f,world_object()\object_transparency)
;       EndIf
;     EndIf
    
EndSelect


Select  _direction.i
    
    
    
    
Case #LOOP
    
 
  
        
        If world_object()\object_use_shadow=#True
          
          If world_object()\object_shadow_use_perspective=#True
            If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
             E_PERSPECTIVE_SHADOW()
            EndIf
          EndIf
          
          If world_object()\object_shadow_use_perspective=#False
            If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default],world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
            EndIf
          EndIf
          
   
        
        EndIf
      
      If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
        DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default],world_object()\object_x+e_engine\e_world_offset_x.f+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y.f+e_world_shake\world_shake_vertical,world_object()\object_transparency)

      EndIf

    
      
      Case #LEFT
        
        If world_object()\object_is_anim_left=#True
          
          If world_object()\object_use_shadow=#True
            If world_object()\object_shadow_use_perspective=#False
              If IsSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left ])
                DisplayTransparentSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left ],world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
              EndIf
            EndIf
            
            If world_object()\object_shadow_use_perspective=#True
              If IsSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left ])
                E_PERSPECTIVE_SHADOW()
              EndIf
            EndIf
          EndIf
      
      If IsSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left])
        DisplayTransparentSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left],world_object()\object_x+e_engine\e_world_offset_x.f+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y.f+e_world_shake\world_shake_vertical,world_object()\object_transparency)

 EndIf
      
    EndIf
    
   
    
      
  Case #RIGHT
    
    If world_object()\object_is_anim_right=#True
      
      If world_object()\object_use_shadow=#True 
        If world_object()\object_shadow_use_perspective=#False
          If IsSprite(world_object()\object_gfx_id_frame_right [world_object()\object_actual_anim_frame_right])
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_right [world_object()\object_actual_anim_frame_right],world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
          EndIf
        EndIf
        
        If world_object()\object_shadow_use_perspective=#True
          If IsSprite(world_object()\object_gfx_id_frame_right [world_object()\object_actual_anim_frame_right])
            E_PERSPECTIVE_SHADOW()
          EndIf
        EndIf
        
      EndIf
      
      If IsSprite(world_object()\object_gfx_id_frame_right [world_object()\object_actual_anim_frame_right  ])
        DisplayTransparentSprite(world_object()\object_gfx_id_frame_right [world_object()\object_actual_anim_frame_right  ],world_object()\object_x+e_engine\e_world_offset_x.f+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y.f+e_world_shake\world_shake_vertical,world_object()\object_transparency)

      EndIf
    EndIf
    
      
    Case #NO_DIRECTION
            If world_object()\object_is_anim_default=#True
               
              If world_object()\object_use_shadow=#True 
                If world_object()\object_shadow_use_perspective=#False
                  If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
                 
                    DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default],world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
                  EndIf 
                EndIf
                If world_object()\object_shadow_use_perspective=#True
                  If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
                    E_PERSPECTIVE_SHADOW()
                  
                  EndIf 
                EndIf
              EndIf
            
            If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default],world_object()\object_x+e_engine\e_world_offset_x.f+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y.f+e_world_shake\world_shake_vertical,world_object()\object_transparency)

            EndIf  
          EndIf
          
          
     
            
     EndSelect
    
   EndIf
   
 
EndProcedure

  

  
     Procedure E_OBJECT_BLINK_SHOW()
       
       If world_object()\object_use_blink_timer=#False
       ProcedureReturn #True  ;we show object....
       EndIf
       
       
       If  e_engine_heart_beat\beats_since_start>world_object()\object_blink_start
         
         Select world_object()\object_blink_object_show
             
           Case #True
             world_object()\object_blink_object_show=#False
             
           Case #False
             world_object()\object_blink_object_show=#True  
             
         EndSelect
         
         
         world_object()\object_blink_start=e_engine_heart_beat\beats_since_start+world_object()\object_blink_timer  ;if blink value > 0 we can use this on the fly 
     EndIf
      
      ProcedureReturn world_object()\object_blink_object_show
    
  EndProcedure
 
  
  

  
  
  
  Procedure E_SHADOW_SYSTEM()
    
    ;experimental shadow system
    
    If e_use_dynamic_shadow_effect.b<>#True
     ProcedureReturn #False
    EndIf
    
    
    If e_shadow_dynamic_move_start.f<0
      e_shadow_dynamic_move_step.f=e_shadow_dynamic_move_step.f*-1 
    EndIf
    
    
    If e_shadow_dynamic_move_start.f>e_shadow_dynamic_move_max.f
      e_shadow_dynamic_move_step.f=e_shadow_dynamic_move_step.f*-1 
    EndIf
    
    
    e_shadow_dynamic_move_start.f+e_shadow_dynamic_move_step.f 
    
  EndProcedure
  
  
  
  
  Procedure E_SET_STATIC_SHADOW_PROJECTION()
    ;here we go for the staic shadow object (it is a oval of alphablending dark)
    
    
    ProcedureReturn #False    ; routine not used for this type of game  , comment it if you want to use the shadowsystem
    
    If e_use_shadow_gfx.b=#False Or world_object()\object_transparency<100 Or e_use_dynamic_shadow_effect.b=#True
      ProcedureReturn #False  
    EndIf
    
    If  world_object()\object_transparency<100
      ProcedureReturn #False    
    EndIf
    
    
    If world_object()\object_shadow_offset_x<>0 And world_object()\object_shadow_offset_y<>0
      DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y,world_object()\object_shadow_intense, world_object()\object_shadow_color)
      ProcedureReturn #False  
    EndIf
    
    
    
    If world_object()\object_shadow_offset_x<>0 And world_object()\object_shadow_offset_y=0
      DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y,world_object()\object_shadow_intense, world_object()\object_shadow_color)
      ProcedureReturn #False  
    EndIf
    
    
    If world_object()\object_shadow_offset_x=0 And world_object()\object_shadow_offset_y<>0
      DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y,world_object()\object_shadow_intense, world_object()\object_shadow_color)
      ProcedureReturn #False
    EndIf
    
    
  EndProcedure
  
  
  
    Procedure E_SET_FLASH_PROJECTION(_mode.i)
    ;here we go for the staic shadow object (it is a oval of alphablending dark)
    
      If e_engine_global_effects\global_effect_flash_light_status=#FLASH_LIGHT_OFF
      ProcedureReturn #False  
      EndIf
      
      If world_object()\object_no_flash_interaction=#True
      ProcedureReturn #False  
    EndIf
    
;       If  e_engine_global_effects\global_effect_flash_light_layer<world_object()\object_layer ;now we use layer specific flash light (objects in front of flash light will not get flash light effect)
;       ProcedureReturn  #False  
;       EndIf
    
       If world_object()\object_is_anim=#True ;no support for anim objects for now....
    ProcedureReturn #False   ;  
    EndIf
    
    If world_object()\object_transparency<50  ;do not flashlight objects nearly invisible...
    ProcedureReturn #False   
  EndIf
  
  If IsSprite(world_object()\object_gfx_id_default_frame)=0
  ProcedureReturn #False  
  EndIf
  
    
      Select _mode.i
          
          Case #E_FLASH_MODE_STATIC
      
      DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity, e_engine_global_effects\global_effect_flash_light_color_RGB)
      
      Case #E_FLASH_MODE_DYNAMIC
      DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity_dynamic, e_engine_global_effects\global_effect_flash_light_color_RGB)
      
    Default
            DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity, e_engine_global_effects\global_effect_flash_light_color_RGB)
        EndSelect
        
  EndProcedure
  
  
      Procedure E_SET_FLASH_PROJECTION_ANIM_OBJECT(_mode.i)
    ;here we go for the staic shadow object (it is a oval of alphablending dark)
    
      If e_engine_global_effects\global_effect_flash_light_status=#FLASH_LIGHT_OFF
      ProcedureReturn #False  
      EndIf
      
      If world_object()\object_no_flash_interaction=#True
      ProcedureReturn #False  
    EndIf
    
;       If  e_engine_global_effects\global_effect_flash_light_layer<world_object()\object_layer ;now we use layer specific flash light (objects in front of flash light will not get flash light effect)
;       ProcedureReturn  #False  
;       EndIf
    
       If world_object()\object_is_anim<>#True ;no support for anim objects for now....
    ProcedureReturn #False   ;  
    EndIf
    
    If world_object()\object_transparency<50  ;do not flashlight objects nearly invisible...
    ProcedureReturn #False   
    EndIf
    
      Select _mode.i
          
        Case #E_FLASH_MODE_STATIC
          
          
          If world_object()\object_anim_loop=#True
            If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
          DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity, e_engine_global_effects\global_effect_flash_light_color_RGB)
          EndIf
          ProcedureReturn #False  
        EndIf
          
          Select world_object()\object_last_move_direction_x
              
            Case #RIGHT
              If IsSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity, e_engine_global_effects\global_effect_flash_light_color_RGB)
              EndIf
              
              
            Case #LEFT
              If IsSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity, e_engine_global_effects\global_effect_flash_light_color_RGB)
              EndIf
              
          EndSelect
          
          
                 Select world_object()\object_last_move_direction_y
              
                   Case #UP
                     If IsSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity, e_engine_global_effects\global_effect_flash_light_color_RGB)
            EndIf
            
              
              
          Case #DOWN
            If IsSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity, e_engine_global_effects\global_effect_flash_light_color_RGB)
              
           EndIf   
          EndSelect
          
      
      
        Case #E_FLASH_MODE_DYNAMIC
          
          If world_object()\object_anim_loop=#True
            If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
          DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity_dynamic, e_engine_global_effects\global_effect_flash_light_color_RGB)
          EndIf
          ProcedureReturn #False  
        EndIf
     
          Select world_object()\object_last_move_direction_x
              
            Case #RIGHT
              If IsSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity_dynamic, e_engine_global_effects\global_effect_flash_light_color_RGB)
            EndIf
            
          Case #LEFT
            If IsSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity_dynamic, e_engine_global_effects\global_effect_flash_light_color_RGB)
            EndIf
            
              
          EndSelect
          
          
          
          Select world_object()\object_last_move_direction_y
              
            Case #UP
              If IsSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity_dynamic, e_engine_global_effects\global_effect_flash_light_color_RGB)
            EndIf
            
            Case #DOWN
              If IsSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_flash_light_intensity_dynamic, e_engine_global_effects\global_effect_flash_light_color_RGB)
              EndIf
              
          EndSelect
          
         
          
      
        EndSelect
        
      EndProcedure
      
      
      
      
      
      
      Procedure E_SET_GLOBAL_LIGHT_PROJECTION_ANIM_OBJECT()
        ;here we go for the staic shadow object (it is a oval of alphablending dark)
        
        If e_engine_global_effects\global_effect_global_light_status=#GLOBAL_LIGHT_OFF
          ProcedureReturn #False  
        EndIf
        
        
        
        If world_object()\object_no_global_light_interaction=#True
          ProcedureReturn #False  
        EndIf
        
        If world_object()\object_is_anim<>#True
          ProcedureReturn #False  
        EndIf
        
        
        If world_object()\object_layer>e_engine_global_effects\global_effect_global_light_layer  ;only light objects same or smaller layer than light source
          ProcedureReturn #False   
        EndIf
        
        If world_object()\object_transparency<50  ;do not light objects nearly invisible
          ProcedureReturn #False   
        EndIf
        
        
        If world_object()\object_anim_loop=#True
          If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_global_light_intensity,e_engine_global_effects\global_effect_global_light_color_RGB)
          EndIf     
          ProcedureReturn #False  
        EndIf
        
        Select world_object()\object_last_move_direction_x
            
          Case #RIGHT
            If IsSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_global_light_intensity,e_engine_global_effects\global_effect_global_light_color_RGB)
            EndIf
            
            
          Case #LEFT
            If IsSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_global_light_intensity,e_engine_global_effects\global_effect_global_light_color_RGB)
            EndIf
            
        EndSelect
        
        
        Select world_object()\object_last_move_direction_y
            
          Case #UP
            
            If IsSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_global_light_intensity,e_engine_global_effects\global_effect_global_light_color_RGB)
            EndIf
            
          Case #DOWN
            If IsSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down])
              DisplayTransparentSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down],world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_global_light_intensity,e_engine_global_effects\global_effect_global_light_color_RGB)
            EndIf
            
        EndSelect
        
        
        
        
        
      EndProcedure
      
  
  
  
      Procedure E_SET_GLOBAL_LIGHT_PROJECTION()
    ;here we go for the staic shadow object (it is a oval of alphablending dark)
        
        
        
        
      If e_engine_global_effects\global_effect_global_light_status=#GLOBAL_LIGHT_OFF
      ProcedureReturn #False  
    EndIf
       
    
    If world_object()\object_no_global_light_interaction=#True
    ProcedureReturn #False  
    EndIf
    
      If world_object()\object_layer>e_engine_global_effects\global_effect_global_light_layer  ;only light objects same or smaller layer than light source
  ProcedureReturn #False   
EndIf

    
    If world_object()\object_is_anim=#True 
    ProcedureReturn #False   ;  
    EndIf
        
    If world_object()\object_transparency<50  ;do not light objects nearly invisible
    ProcedureReturn #False   
  EndIf
  
  If IsSprite(world_object()\object_gfx_id_default_frame)=0
  ProcedureReturn #False  
  EndIf
  
    DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,e_engine_global_effects\global_effect_global_light_intensity,e_engine_global_effects\global_effect_global_light_color_RGB)
     
  EndProcedure
  
  
  
  
  Procedure E_OWN_COLOR_SET_UP_FOR_ANIM()
    
    If  world_object()\object_use_own_color=#False
    ProcedureReturn #False  
    EndIf
    
      
      If world_object()\object_own_color_intensity>0
        
        
        If world_object()\object_anim_loop=#True
           If IsSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default])
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default],world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_transparency)
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_anim_default[world_object()\object_actual_anim_frame_default],world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_own_color_intensity,world_object()\object_color_RGB)   
           EndIf
             ProcedureReturn #False
        EndIf
        
        Select world_object()\object_last_move_direction_x
            
          Case #RIGHT
            If IsSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right])
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right],world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_transparency)
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_right[world_object()\object_actual_anim_frame_right],world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_own_color_intensity,world_object()\object_color_RGB) 
            EndIf
          Case #LEFT
            If IsSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left])
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left],world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_transparency)
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_left[world_object()\object_actual_anim_frame_left],world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_own_color_intensity,world_object()\object_color_RGB) 
            EndIf
        EndSelect
        
        
          Select world_object()\object_last_move_direction_y
            
            Case #UP
              If IsSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up])
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up],world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_transparency)
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_up[world_object()\object_actual_anim_frame_up],world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_own_color_intensity,world_object()\object_color_RGB) 
          EndIf
          
          Case #DOWN
            If IsSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down])
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down],world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_transparency)
            DisplayTransparentSprite(world_object()\object_gfx_id_frame_down[world_object()\object_actual_anim_frame_down],world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_own_color_intensity,world_object()\object_color_RGB) 
            EndIf
          
        EndSelect
        
        
        
      EndIf
      

    
    
  EndProcedure
  
  
   Procedure E_GFX_SGFX_FOR_ANIM_OBJECT()
    
    If world_object()\object_is_anim<>#True
    ProcedureReturn #False  
    EndIf
    
  
    ;here we do effect on anim frame....
    E_OWN_COLOR_SET_UP_FOR_ANIM()
    E_SET_GLOBAL_LIGHT_PROJECTION_ANIM_OBJECT()
    E_SET_FLASH_PROJECTION_ANIM_OBJECT(#E_FLASH_MODE_DYNAMIC)

  EndProcedure

  
    
  Procedure E_RESTART_GLOBAL_EFFECTS()
    ;(re)activate global effects?
      If world_object()\object_is_global_light=#True
          e_engine_global_effects\global_effect_global_light_status=#GLOBAL_LIGHT_ON 
  EndIf
    
  EndProcedure
  
  
     Procedure E_DISPLAY_DAY_NIGHT()
    ;we check if static objects have dynamic shadows, and which direction (offst 0 = no dynamic shadow in this direction...
    
    If   IsSprite(world_object()\object_gfx_id_default_frame)=0 Or world_object()\object_use_day_night_change=#False
    ProcedureReturn #False    
    EndIf
    
    
    ;simple for now, no anim objects supported in day night calculation/anim objects do not use light

      
  Select world_object()\object_is_anim
        
      Case #False
        
                DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x.f,world_object()\object_y+e_engine\e_world_offset_y.f,day_night_cycle\light_intensity_actual, day_night_cycle\light_color_RGB)

    EndSelect
    
    
  
  
   EndProcedure
          
   


  
   Procedure E_SET_DYNAMIC_SHADOW()
     ;we check if static objects have dynamic shadows, and which direction (offst 0 = no dynamic shadow in this direction...
     
       
     
     If   IsSprite(world_object()\object_gfx_id_default_frame)=0
       ProcedureReturn #False    
     EndIf
     
     
     
     
     If  world_object()\object_transparency<100 Or world_object()\object_use_shadow=#False
       ProcedureReturn #False    
     EndIf
     
     
     
     Select world_object()\object_is_anim
         
       Case 0
         
         If world_object()\object_shadow_offset_x<>0 And world_object()\object_shadow_offset_y<>0
           DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
           ProcedureReturn #False  
         EndIf
         
         
         
         If world_object()\object_shadow_offset_x<>0 And world_object()\object_shadow_offset_y=0
           DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x+e_shadow_dynamic_move_start.f,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y,world_object()\object_shadow_intense, world_object()\object_shadow_color)
           ProcedureReturn #False  
         EndIf
         
         
         If world_object()\object_shadow_offset_x=0 And world_object()\object_shadow_offset_y<>0
           DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y+e_shadow_dynamic_move_start.f,world_object()\object_shadow_intense, world_object()\object_shadow_color)
           ProcedureReturn #False
         EndIf
         
       Default
         
         ProcedureReturn #False
         
     EndSelect
     
     
     
   EndProcedure
  
  
  
  
   
   Procedure E_SET_LIGHT_SOURCE()
     
     If  world_object()\object_is_light=#False
       ProcedureReturn #False  
     EndIf
     
   
     
     If IsSprite(world_object()\object_gfx_id_default_frame)=0
       ProcedureReturn #False  
     EndIf
     
     If  IsSprite(day_night_cycle\light_mask_id)=0
       ProcedureReturn #False  
     EndIf
     
     day_night_cycle\light_source_RGB=RGB(world_object()\object_light_color_r,world_object()\object_light_color_g,world_object()\object_light_color_b)
     ZoomSprite(day_night_cycle\light_mask_id,SpriteWidth(world_object()\object_gfx_id_default_frame)*world_object()\object_light_size_factor,SpriteHeight(world_object()\object_gfx_id_default_frame)*world_object()\object_light_size_factor)
     DisplayTransparentSprite(day_night_cycle\light_mask_id,world_object()\object_x+e_engine\e_world_offset_x.f+world_object()\object_shadow_offset_x-SpriteWidth(day_night_cycle\light_mask_id)/2,world_object()\object_y+e_engine\e_world_offset_y.f+world_object()\object_shadow_offset_y-SpriteHeight(day_night_cycle\light_mask_id)/2,day_night_cycle\light_intensity_actual/world_object()\object_light_intensity,day_night_cycle\light_source_RGB)
     
     
     
   EndProcedure
 
    
    
    Procedure E_SHOW_PLAYER_ACTION_GFX()
      
      If player_statistics\player_defence_object_show=#True
        If IsSprite(player_statistics\player_defence_object_id)
          DisplayTransparentSprite(player_statistics\player_defence_object_id,player_statistics\player_pos_x,player_statistics\player_pos_y)
        EndIf
        
      EndIf
      
      
    EndProcedure
    
 
    
    

    
    

  
      Procedure E_DAY_NIGHT_SET_OBJECT()
        If world_object()\object_set_day=#True 
     e_engine\e_day_night_overide=#WORLD_STATUS_DAY
     E_OVER_RIDE_DAY_NIGHT()
   EndIf
   
    If world_object()\object_set_night=#True 
     e_engine\e_day_night_overide=#WORLD_STATUS_NIGHT
     E_OVER_RIDE_DAY_NIGHT()
   EndIf
   
      EndProcedure

      
   Procedure E_WORLD_RUMBLE_EFFECT()
    
    If world_object()\object_shake_world=#False
    ProcedureReturn #False  
    EndIf
    e_world_shake\world_shake_horizontal=Random(e_world_shake\world_shake_base_horizontal)
    e_world_shake\world_shake_vertical=Random(e_world_shake\world_shake_base_vertical)
    
  EndProcedure
  

 
 
  Procedure E_SHOW_SCROLL_LAYER()
    
    ;try some background scrolling...... (horizontal only...for now) for full screen loop scroll:
    ;gfx which is not fullscreen will be set to fixed y.pos screen heihgt - gfx height
    
    If world_object()\object_is_scroll_back_ground=#False
    ProcedureReturn #False  
    EndIf
    
    
    If  e_engine\e_scroll_gfx_actual_pos_x1[world_object()\object_scroll_scroll_id]<e_engine\e_scroll_left_border
        e_engine\e_scroll_gfx_actual_pos_x1[world_object()\object_scroll_scroll_id]=e_engine\e_engine_internal_screen_w-e_engine\e_scroll_speed_x[world_object()\object_scroll_scroll_id]
      
    EndIf
      
       If e_engine\e_scroll_gfx_actual_pos_x2[world_object()\object_scroll_scroll_id]<e_engine\e_scroll_left_border
        e_engine\e_scroll_gfx_actual_pos_x2[world_object()\object_scroll_scroll_id]=e_engine\e_engine_internal_screen_w-e_engine\e_scroll_speed_x[world_object()\object_scroll_scroll_id]
     
    EndIf
    

    DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,e_engine\e_scroll_gfx_actual_pos_x1[world_object()\object_scroll_scroll_id],e_engine\e_scroll_gfx_actual_pos_y1[world_object()\object_scroll_scroll_id],world_object()\object_transparency)
    DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,e_engine\e_scroll_gfx_actual_pos_x1[world_object()\object_scroll_scroll_id],e_engine\e_scroll_gfx_actual_pos_y1[world_object()\object_scroll_scroll_id],world_object()\object_own_color_intensity,world_object()\object_color_RGB) ;for color effcts...
    DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,e_engine\e_scroll_gfx_actual_pos_x2[world_object()\object_scroll_scroll_id],e_engine\e_scroll_gfx_actual_pos_y2[world_object()\object_scroll_scroll_id],world_object()\object_transparency)
    DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,e_engine\e_scroll_gfx_actual_pos_x2[world_object()\object_scroll_scroll_id],e_engine\e_scroll_gfx_actual_pos_y2[world_object()\object_scroll_scroll_id],world_object()\object_own_color_intensity,world_object()\object_color_RGB)
          
    
    
  EndProcedure
  
  

 
 
 

      
    Procedure  E_SHOW_WORLD_START()
      


      E_SORT_MAP_OBJECTS_BY_LAYER()
      E_SORT_MAP_OBJECTS_BY_Y()
      
      ResetList(world_object())
        
        If e_engine\e_clear_screen=#True
        ClearScreen(RGB(0,0,0))  ;remove  if use _switch plane 
        EndIf
      
       ;here we need a true/false switch, not used while in testing
       
  
     ; E_FOG_OF_WAR_OVERLAY()
       ;-----------------------------------------------------
       
    
  
  
      
      ;********************  this routine supports  mapstreaming, so loading times are very short and fast ***************** we can build so much bigger maps now *****************
      ;this is the main and key routine for the final GFX output
      ;this routine manipulates all posteffects and GFX and SFX , calls routines for SFX  & GFX
      ;the final display "catch" routine can take this screen and use it for display output
      
      e_engine\e_objects_in_screen=0 ;counter used for debugging a
      e_engine\e_map_use_special_effect=#False 
    
     
     
  
  ForEach world_object()                ;here we will load/hold the sprites for the gfx presentation of the game
    
    If  world_object()\object_is_active=#True
       
      If world_object()\object_is_in_gfx_area=#True 
        E_WORLD_RUMBLE_EFFECT()
      
      If world_object()\object_is_boss=#True
        e_ingame_info_text\x=world_object()\object_x+e_engine\e_world_offset_x
        e_ingame_info_text\y=world_object()\object_y+e_engine\e_world_offset_y
      EndIf
      
      e_engine\e_objects_in_screen+1  ;count the objects in screen (for debugging/developement)
      
      ;------------------------------------------------------------
    E_DAY_NIGHT_SET_OBJECT()
     
      ;E_SET_DYNAMIC_SHADOW()
      ;E_SET_STATIC_SHADOW_PROJECTION()
      E_SET_LIGHT_SOURCE()
      
      ;---- some specials for player object:
      If world_object()\object_is_player<>0
       ; E_SHOW_PLAYER_FIGHT_SYMBOL()  
        E_PLAYER_SHOW_TORCH_LIGHT()
        E_PLAYER_SHOW_TORCH_LIGHT_BIG()
      EndIf
      


     If world_object()\object_is_scroll_back_ground=#False
       
     If world_object()\object_full_screen=#True  
          DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,0,0,world_object()\object_transparency)
          DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,0,0,world_object()\object_own_color_intensity,world_object()\object_color_RGB)
               
     EndIf
        
      Else
        E_SHOW_SCROLL_LAYER()
        
        
      EndIf
      
      
      

      ;---------------------------------      
     If world_object()\object_do_not_show=#False And world_object()\object_is_active=#True   And E_OBJECT_BLINK_SHOW()=#True And world_object()\object_full_screen=#False And  world_object()\object_is_scroll_back_ground=#False
       E_SHOW_GLASS_EFFECT()
       E_GLASS_EFFECT()
        

       
        If world_object()\object_is_anim=#False
          
          If IsSprite(world_object()\object_gfx_id_default_frame) 
            ;E_SHOW_ENEMY_FIGHT_SYMBOL()
            
          
            
            Select world_object()\object_no_shake_interaction
                
              Case #True
                
                DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,world_object()\object_transparency)
                DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x,world_object()\object_y+e_engine\e_world_offset_y,world_object()\object_own_color_intensity,world_object()\object_color_RGB)
             
              Case #False
                     
                DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_transparency)
                DisplayTransparentSprite(world_object()\object_gfx_id_default_frame,world_object()\object_x+e_engine\e_world_offset_x+e_world_shake\world_shake_horizontal,world_object()\object_y+e_engine\e_world_offset_y+e_world_shake\world_shake_vertical,world_object()\object_own_color_intensity,world_object()\object_color_RGB)
          
         
            EndSelect
            
                        
              
          
            

            EndIf
          
          
        Else
       
          ;E_SHOW_ENEMY_FIGHT_SYMBOL()
          
          E_ANIM_SPRITE_ID()  ;we only store the actual default frame from animation<s at this engin version (default frame =idle animation)
          
          
        EndIf
        
        
        
       ;E_ENEMY_SHOW_HEALTH_BAR()
       ;E_SHOW_PLAYER_ACTION_GFX() 
        ;E_SHOW_DANGER_ENEMY()
        E_GFX_SGFX_FOR_ANIM_OBJECT()
        E_SET_GLOBAL_LIGHT_PROJECTION()
        E_DISPLAY_DAY_NIGHT()
        E_SET_FLASH_PROJECTION(#E_FLASH_MODE_DYNAMIC)
      
      EndIf
      
      
      
      
      
     
    EndIf
    
  EndIf
  
E_SHOW_HIT_BOX()
 
Next
  E_SHOW_GRABBED_SCREEN()
  E_TIMER_SOUND_EFFECT()
EndProcedure
  
  
 
; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 34
; FirstLine = 27
; Folding = -----
; EnableThread
; EnableXP
; EnableUser
; EnableOnError
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant