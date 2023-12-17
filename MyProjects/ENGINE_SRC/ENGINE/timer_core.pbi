;here I try to set all time(r) related routines...


Declare E_CHECK_IF_PLAYER_DEAD()




Procedure E_OBJECT_MOVE_TIMER()
  ;does object move on timer basis?
  
  If world_object()\object_use_make_move_timer=#False
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_move_time>e_engine_heart_beat\beats_since_start
  ProcedureReturn #True  ;we do not move
  EndIf
  
  world_object()\object_move_time=e_engine_heart_beat\beats_since_start+world_object()\object_make_move_timer
  ProcedureReturn #False  ;we move on
  
  
EndProcedure




Procedure E_OVER_RIDE_DAY_NIGHT()
  ;use this if your map uses fixed day or night mode
  ;you can control this with objects set to object_set_night, object_set_day #True/#False
  
  If e_engine\e_day_night_overide=#WORLD_DAY_NIGHT_NOT_DEFINED
  ProcedureReturn #False  
  EndIf
  
      
    If e_engine\e_day_night_overide=#WORLD_STATUS_DAY
      e_game_mode.i=#GAME_MODE_DAY
      e_world_status.i=#WORLD_STATUS_DAY
        day_night_cycle\light_intensity_actual=world_object()\object_set_day_intensity
player_statistics\player_use_torch=#False
    EndIf
    
    
      If e_engine\e_day_night_overide=#WORLD_STATUS_NIGHT
        e_game_mode.i=#GAME_MODE_NIGHT
        e_world_status.i=#WORLD_STATUS_NIGHT
        day_night_cycle\light_intensity_actual=world_object()\object_set_night_intensity
        player_statistics\player_use_torch=#True
  
    EndIf
    
 
  
  
EndProcedure





  Procedure E_SET_NIGHT_EFFECT()
    
    If e_map_use_daytimer.b=#False 
      ProcedureReturn #False  
    EndIf
    
    
      If e_engine\e_day_night_overide<>#WORLD_DAY_NIGHT_NOT_DEFINED
      ProcedureReturn #False 
  EndIf
     
    
  If e_game_mode.i=#GAME_MODE_DAY
    If IsSound(e_sound_song_of_the_night_id.i)
      SoundVolume(e_sound_song_of_the_night_id.i,e_engine\e_sound_global_volume)
      PlaySound(e_sound_song_of_the_night_id.i)  
   EndIf
    EndIf
    

     e_game_mode.i=#GAME_MODE_NIGHT
     e_world_status.i=#WORLD_STATUS_NIGHT
     e_ai42_suffix.s=e_night_suffix.s
     e_day_night_changed.b=#True
     
     day_night_cycle\ticks=day_night_cycle\light_intensity_max/60
     
   EndProcedure






Procedure E_SET_DAY_EFFECT()
  
  If e_map_use_daytimer.b=#False 
    ProcedureReturn #False  
  EndIf
  
  
  If e_engine\e_day_night_overide<>#WORLD_DAY_NIGHT_NOT_DEFINED
      ProcedureReturn #False 
  EndIf


  If e_game_mode.i=#GAME_MODE_NIGHT
  
      
    If IsSound(e_sound_song_of_the_day_id.i)
      SoundVolume(e_sound_song_of_the_day_id.i,e_engine\e_sound_global_volume)
    PlaySound(e_sound_song_of_the_day_id.i)  
  EndIf
  EndIf
  

  e_game_mode.i=#GAME_MODE_DAY
  e_world_status.i=#WORLD_STATUS_DAY
  e_ai42_suffix.s=""
  e_day_night_changed.b=#True
  

  day_night_cycle\ticks=day_night_cycle\light_intensity_max/60
  
  

EndProcedure





   Procedure E_CHECK_DAY_NIGHT_CHANGE()
     
          
;      Select e_engine\e_actuall_world
;          
;        Case "intro.worldmap","credit.worldmap","start.worldmap","story.worldmap"
;         ProcedureReturn #False
;         EndSelect
;      
   
     
     If  e_world_time\e_world_time_hour=e_world_time\e_world_time_start_day
       
       If e_world_status.i=#WORLD_STATUS_NIGHT 
         E_SET_DAY_EFFECT()
         ;E_REFRESH_WORLD()
       
       EndIf
       
     EndIf  
     
     
     If  e_world_time\e_world_time_hour=e_world_time\e_world_time_start_night  
       If e_world_status.i=#WORLD_STATUS_DAY 
         E_SET_NIGHT_EFFECT()
         ;E_REFRESH_WORLD()
    
       EndIf
       
     EndIf 
     
     
   EndProcedure

    
   Procedure E_SET_DAY_NIGHT_AFTER_LOAD()
     
     
     
     If e_map_use_daytimer=#True
     day_night_cycle\light_intensity_actual=global_day_night_cycle\light_intensity_actual  
     EndIf
     
  
  Select e_world_status.i
      
    Case #WORLD_STATUS_DAY
         E_SET_DAY_EFFECT()
     
      
      
    Case #WORLD_STATUS_NIGHT
          E_SET_NIGHT_EFFECT()
    
    EndSelect

 ; e_day_night_clock_position.f=e_world_time\e_world_time_hour*e_day_night_clock_segment_angle.f
  
EndProcedure

Procedure E_DAY_LIGHT_MANAGER_GLOBAL(_ticks.i)
  
  
      Select e_game_mode.i
        
      Case #GAME_MODE_DAY  

  
        If global_day_night_cycle\light_intensity_actual-_ticks.i>=global_day_night_cycle\light_intensity_min
           global_day_night_cycle\light_intensity_actual-_ticks.i
        EndIf
        
    
    
  Case #GAME_MODE_NIGHT

    
      If global_day_night_cycle\light_intensity_actual+_ticks.i<=global_day_night_cycle\light_intensity_max
         global_day_night_cycle\light_intensity_actual+_ticks.i
     EndIf
        

    
    EndSelect
  
  
EndProcedure

    

  Procedure  E_DAY_LIGHT_MANAGER(_ticks.i)
    
    
    
    
    If e_map_use_daytimer=#False
      E_DAY_LIGHT_MANAGER_GLOBAL(_ticks.i)
        ProcedureReturn #False
    EndIf
    
    

    
    Select e_game_mode.i
        
      Case #GAME_MODE_DAY  

  
        If day_night_cycle\light_intensity_actual-_ticks.i>=day_night_cycle\light_intensity_min
          day_night_cycle\light_intensity_actual-_ticks.i
       
        EndIf
        
    
    
  Case #GAME_MODE_NIGHT

    
      If day_night_cycle\light_intensity_actual+_ticks.i<=day_night_cycle\light_intensity_max
        day_night_cycle\light_intensity_actual+_ticks.i
 
     EndIf
        

    
    EndSelect
    
     day_night_cycle\light_color_RGB=RGB(day_night_cycle\light_color_actual_r,day_night_cycle\light_color_actual_g,day_night_cycle\light_color_actual_b)
  EndProcedure
  
  





   
   
   
   
   
    Procedure  E_WORLD_SYSTEM_TIME_BASE()
     ;here we handle the timer  for the world time (24h format)
     
     If e_engine_heart_beat\beats_since_start>e_world_time\e_world_time_actual_ticker
       e_world_time\e_world_time_actual_ticker=e_engine_heart_beat\beats_since_start+e_world_time\e_world_time_tick
       ; e_world_time\e_world_time_second+1
       e_world_time\e_world_time_minute+1  ;we need a shorter day night cycle
       E_DAY_LIGHT_MANAGER(day_night_cycle\ticks) 
       E_DAY_LIGHT_MANAGER_GLOBAL(day_night_cycle\ticks)

     EndIf
     
     
     ;simple world system:
     
     If e_world_time\e_world_time_second>58
       e_world_time\e_world_time_minute+1
       e_world_time\e_world_time_second=0
     EndIf
     
     If e_world_time\e_world_time_minute>58
       e_world_time\e_world_time_minute=0  
       e_world_time\e_world_time_hour+1
       
     EndIf
     
     If e_world_time\e_world_time_hour>23
       e_world_time\e_world_time_hour=0  
       e_world_time\e_world_time_days_player_in_game+1
       e_world_time\e_world_time_days_in_game+1
       
     EndIf
     
     If e_world_time\e_world_time_hour=e_world_time\e_world_time_start_day
       E_SET_DAY_EFFECT()  
     EndIf
     
     If e_world_time\e_world_time_hour=e_world_time\e_world_time_start_night
       E_SET_NIGHT_EFFECT()
     EndIf
     
     
   EndProcedure
   
   
   
   
   
   
   Procedure E_INIT_DAY_NIGHT_SYSTEM()
  
  ;some defaults, maybe we use script for change ?
  
     day_night_cycle\light_color_b=0
     day_night_cycle\light_color_g=0
     day_night_cycle\light_color_r=10
     day_night_cycle\light_color_actual_b=0
     day_night_cycle\light_color_actual_g=0
     day_night_cycle\light_color_actual_r=10
     day_night_cycle\light_intensity_actual=150
     day_night_cycle\light_intensity_max=150
     day_night_cycle\light_intensity_min=0
     day_night_cycle\ticks=5 ;default..
     
     day_night_cycle\light_source_r=255
     day_night_cycle\light_source_g=255
     day_night_cycle\light_source_b=255  ;default the light is white
     
     
     global_day_night_cycle\light_intensity_actual=150
     global_day_night_cycle\light_intensity_max=150
     global_day_night_cycle\light_intensity_min=0
     
     
     day_night_cycle\light_color_RGB=RGB(day_night_cycle\light_color_actual_r,day_night_cycle\light_color_actual_g,day_night_cycle\light_color_actual_b)
     day_night_cycle\light_source_RGB=RGB(day_night_cycle\light_source_r,day_night_cycle\light_source_g,day_night_cycle\light_source_b)
     player_statistics\player_use_torch=#False ; with button "Y" we use torch
  
   EndProcedure
   
   
   
   
   Procedure E_LOAD_WORLD_TIME()
     Define _ok.i=0
     
     
     _ok.i=ReadFile(#PB_Any,e_engine\e_save_path+e_world_time\e_world_time_save_path)
     
     If IsFile(_ok.i)
       
       e_world_time\e_world_time_second=Val(ReadString(_ok.i))
       e_world_time \e_world_time_minute=Val(ReadString(_ok.i))
       e_world_time\e_world_time_hour=Val(ReadString(_ok.i))
       e_world_time\e_world_time_days_in_game=Val(ReadString(_ok.i))
       global_day_night_cycle\light_intensity_actual=ValF(ReadString(_ok.i))
       e_world_status.i=Val(ReadString(_ok.i))
       
       CloseFile(_ok.i)
       E_SET_DAY_NIGHT_AFTER_LOAD()
       
     EndIf
     
     
     
   EndProcedure

   
   
   Procedure E_SAVE_WORLD_TIME()
     ;here we save the actual time and world stats
     Define _ok.i=0
     
     _ok.i=OpenFile(#PB_Any,e_engine\e_save_path+e_world_time\e_world_time_save_path)
     
     If IsFile(_ok.i)
       
       WriteStringN(_ok.i,Str(e_world_time\e_world_time_second))
       WriteStringN(_ok.i,Str(e_world_time\e_world_time_minute))
       WriteStringN(_ok.i,Str(e_world_time\e_world_time_hour))
       WriteStringN(_ok.i,Str(e_world_time\e_world_time_days_in_game)) ;this is the ingame day, 
       WriteStringN(_ok.i,StrF(global_day_night_cycle\light_intensity_actual))
       WriteStringN(_ok.i,Str(e_world_status.i))
       CloseFile(_ok.i)
       
     EndIf
     
     
     
     
   EndProcedure
   
   
   
   Procedure E_TIMER_SOUND_EFFECT()
  ;we show the timer object
  ;used for maps which use timer for player action
  ;show the player the time remaining
  ;code here:
  
  If e_engine\e_world_show_timer<>#True
    ProcedureReturn #False  
  EndIf

  
  If e_engine\e_timer_full_size>e_engine_heart_beat\beats_since_start
  ProcedureReturn #False  
  EndIf
  
  
  ;timer object code here:
  
  If IsSound(e_engine\e_timer_sound_id)=0
  ProcedureReturn #False  
  EndIf
  If ((e_map_timer\_map_time_stop-e_engine_heart_beat\beats_since_start)/1000)<10  
    SoundVolume(e_engine\e_timer_sound_id,e_engine\e_timer_sound_volume)
  PlaySound(e_engine\e_timer_sound_id)
EndIf

e_engine\e_timer_full_size=e_engine\e_timer_speed+e_engine_heart_beat\beats_since_start


EndProcedure
   
   
   
   
   
   Procedure E_SHOW_TIMER_OBJECT()
  ;we show the timer object
  ;used for maps which use timer for player action
  ;show the player the time remaining
  ;code here:
  
  If e_engine\e_world_show_timer<>#True
    ProcedureReturn #False  
  EndIf
  
  ;timer object code here:
  
  ;dummy code for developement/debug#
  ;replace this with GUI presentation
  
  ;for now simple text output on screen
  

  DrawingMode(#PB_2DDrawing_Transparent)
  DrawingFont(FontID(#FONT_TIMER))
  
  If IsImage(e_map_timer\_map_timer_symbol_gfx_id)
  DrawAlphaImage(ImageID(e_map_timer\_map_timer_symbol_gfx_id),e_map_timer\_map_time_gfx_pos_x,e_map_timer\_map_time_gfx_pos_y)
  EndIf
  
  If ((e_map_timer\_map_time_stop-e_engine_heart_beat\beats_since_start)/1000)>9
    If e_map_timer\_map_timer_font_size_dynamic=#True
      DrawingFont(FontID(#FONT_TIMER_SMALL))
      If (e_map_timer\_map_time_stop-e_engine_heart_beat\beats_since_start)>999
     
    DrawText(e_map_timer\_map_time_text_position_font_small_x,e_map_timer\_map_time_text_position_font_small_y,Str(Int(e_map_timer\_map_time_stop-e_engine_heart_beat\beats_since_start)/1000),RGB(200,200,200),RGB(0,0,0))
  Else
    DrawText(e_map_timer\_map_time_text_position_font_small_x,e_map_timer\_map_time_text_position_font_small_y,"0",RGB(Random(200),200,200),RGB(0,0,0))
  EndIf
  
      
    Else
      
      If (e_map_timer\_map_time_stop-e_engine_heart_beat\beats_since_start)>999
      
    DrawText(e_map_timer\_map_time_text_pos_x,e_map_timer\_map_time_text_pos_y,Str(Int(e_map_timer\_map_time_stop-e_engine_heart_beat\beats_since_start)/1000),RGB(200,200,200),RGB(0,0,0))
  Else
    DrawText(e_map_timer\_map_time_text_pos_x,e_map_timer\_map_time_text_pos_y,"0",RGB(Random(200),200,200),RGB(0,0,0))
  EndIf
  
      
    EndIf
    
  Else
     If (e_map_timer\_map_time_stop-e_engine_heart_beat\beats_since_start)>999
    DrawText(e_map_timer\_map_time_text_pos_x,e_map_timer\_map_time_text_pos_y,Str(Int(e_map_timer\_map_time_stop-e_engine_heart_beat\beats_since_start)/1000),RGB(200,200,200),RGB(0,0,0))
  Else
    DrawText(e_map_timer\_map_time_text_pos_x,e_map_timer\_map_time_text_pos_y,"0",RGB(Random(200),Random(200),200),RGB(0,0,0))
  EndIf
  
    
  EndIf
  
 E_TIMER_SOUND_EFFECT()

EndProcedure







Procedure E_MAP_CHANGE_ON_INTERACTIVE_TIMER()
  
  If e_engine\e_switch_map_on_trigger=#False
  ProcedureReturn #False  
  EndIf
  
  If npc_text\npc_conversation_activate_map_timer_time<1
    ProcedureReturn #False
  EndIf
  
  e_map_timer\_map_time_stop=e_engine_heart_beat\beats_since_start+npc_text\npc_conversation_activate_map_timer_time
  e_map_timer\_next_map=npc_text\npc_conversation_switch_map_file
  
  
EndProcedure


Procedure E_IN_AIR_TIMER_KILL(_mode.i)
  ;suported for player object only for now...
  
  
  If  e_engine\e_engine_mode=#TALK Or player_statistics\player_on_ground=#True
   player_statistics\player_in_air_timer=e_engine_heart_beat\beats_since_start+player_statistics\player_in_air_time_kill
  ProcedureReturn #False  
  EndIf
  
  If world_object()\object_use_air_time_kill=#False  ;for now this is the player object only which is supported...
  ProcedureReturn #False  
  EndIf
  
  
  Select _mode.i
      
    Case #RESET
      
      player_statistics\player_in_air_timer=e_engine_heart_beat\beats_since_start+player_statistics\player_in_air_time_kill
      
    Default
      
      If player_statistics\player_in_air_timer<e_engine_heart_beat\beats_since_start
                E_CHECK_IF_PLAYER_DEAD()
      EndIf
      
      
  EndSelect
  
  
  
  
EndProcedure


