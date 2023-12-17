;one include for all inputs:
;send all inputs to this routine

Declare E_SET_UP_FOR_INPUT_IDLE()
Declare E_CHECK_INPUT_IDLE()
Declare E_QUIT() 


Procedure E_SET_GUI_ON_OFF()
  
  e_engine\e_map_show_gui=#True -e_engine\e_map_show_gui
  
EndProcedure


Procedure  E_MAP_CHANGE_INTERACTIVE()
  ;switch/change map on conversation
  
  If e_engine\e_switch_map_on_trigger=#False
  ProcedureReturn #False  
  EndIf
  
  
     If npc_text\npc_conversation_switch_map=#True
          
          If npc_text\npc_conversation_switch_map_file>""
      e_engine\e_next_world=npc_text\npc_conversation_switch_map_file
          EndIf
        EndIf
        
        ;after talking we have to reset the values, so not sidefeects are possible
        npc_text\npc_conversation_switch_map=#False
        npc_text\npc_conversation_switch_map_file=""
  
EndProcedure



Procedure E_GLOBAL_INPUT_ACTIONS(_button.i)
  ;here we use all settings for default actions (like cancel, quit...)
  
  Select _button.i
      
    Case #B
      player_statistics\player_show_interface=#False
      
      If  e_engine\e_npc_text_field_show=#True
          e_engine\e_npc_text_field_show=#False  
         E_MAP_CHANGE_INTERACTIVE()
      EndIf
      
 
      If e_map_timer\_map_time>0
        e_map_timer\_map_time_stop=e_engine_heart_beat\beats_since_start  ;jump over timed maps (presentations/intros/...)  
      EndIf
      
  EndSelect
  
    If _button.i=#DEVELOPE
    
    Select e_engine\e_show_debug
        
      Case #True
        e_engine\e_show_debug=#False
        
        
        Case #False
        e_engine\e_show_debug=#True
        
    EndSelect
    
    
  EndIf
  
  
  If _button.i=#SAVE_PROGRESS  ;for develope 
    E_QUICK_SAVE()
  EndIf
  
  
  
  If _button.i=#EMERGENCY_EXIT
    E_CLEAN_UP()
    End
  EndIf
  
  
  If _button.i=#E_DEVELOPE_EDIT_NPC_TEXT
         E_DEVELOPE_NPC_TEXT_EDIT()  

  EndIf
  
  
  If _button.i=#E_DEVELOPE_EDIT_SCROLL_TEXT
    E_DEVELOPE_SCROLL_TEXT_EDIT() 
    ProcedureReturn #False
  EndIf
  
  
    
  If _button.i=#E_DEVELOPE_EDIT_WORLD_NAME_TEXT
    E_DEVELOPE_WORLD_NAME_TEXT_EDIT()
    ProcedureReturn #False
    EndIf
    
    If _button.i=#E_DEVELOPE_EDIT_SILUETTE_SETTING
      E_DEVELOPE_WORLD_SILUETTE_FILE_EDIT()
      ProcedureReturn #False
    EndIf
    
    
     If _button.i=#E_DEVELOPE_EDIT_PERMANENT_TEXT
       E_DEVELOPE_WORLD_PERMANENT_TEXT_EDIT()
       ProcedureReturn #False
    EndIf
    
      Select e_engine\e_engine_mode
      
    Case #PAUSE
      
      ;here we look for some boot/title/endscreen inputs, like start, quit, options...
      If _button.i=#Y
        e_engine\e_engine_mode=#GAME_OVER
      EndIf
      
      If _button.i=#A
        e_engine\e_engine_mode=#ACTIVE
       
        If e_play_music.b=#True
          
          If IsSound(e_engine\e_global_sound_id)
            SoundVolume(e_engine\e_global_sound_id,e_engine\e_sound_global_volume)
            PlaySound(e_engine\e_global_sound_id,#PB_Sound_Loop)
          EndIf
    
        EndIf
        
        
      EndIf
      
  EndSelect
  
  
    
  If _button.i=#RELOAD_MAP
  e_engine\e_actuall_world="DEBUGRELOAD"  ;for develope/debugging
  EndIf
  
  
EndProcedure






Procedure E_ACTION_ON_BUTTON_ALL(_button.i)
  ;here we read default actions 
    
  ;for developement /testing: planned to use this as realtime gfx change for night and day mode....
  

  
  Select _button.i
      
    Case #GAME_MODE_NIGHT
       e_world_time\e_world_time_hour=e_world_time\e_world_time_start_night
      e_world_status.i=#WORLD_STATUS_NIGHT
      
    Case #GAME_MODE_DAY
       e_world_status.i=#WORLD_STATUS_DAY
       e_world_time\e_world_time_hour=e_world_time\e_world_time_start_day
     EndSelect
       If _button.i=#E_SHOW_TEXT_FIELD
         e_engine\e_engine_mode=#E_SHOW_TEXT_FIELD  
     EndIf
     
     
     
     If e_engine\e_show_debug=#True    ;debugmode only!
       If _button.i=#INCREASE_QUEST_STATUS
         player_statistics\player_ready_for_new_world+1  
       EndIf
       
       
       If _button.i=#DECREASE_QUEST_STATUS
         player_statistics\player_ready_for_new_world-1
       EndIf
       
     EndIf
     
     
    
  If _button.i=#CHANGE_COLOR_TO_GRAY
  e_engine\e_show_gray_scale=1-e_engine\e_show_gray_scale
  EndIf
  
EndProcedure




Procedure E_ACTION_ON_BUTTON_A(_button.i)
  
    
    Select e_engine\e_actuall_world
        
      Case "intro.worldmap"
        If e_engine\e_game_status=#CONTINUE
          e_engine\e_next_world=e_continue_game_entry.s
          E_SOUND_BUTTON_SOUND_PLAY()
         
          E_LOAD_WORLD_TIME()
         ;e_engine_fresh_start.b=#True  ;for the inventory spawn system....
         player_statistics\player_show_interface=#True
         e_gold_show.b=#True
         player_statistics\player_gui_timer=e_engine_heart_beat\beats_since_start+5000 ;default for develope (use script for final release)
         
         E_GRAB_SRC_SCREEN()

         
      EndIf
          
    EndSelect
    

  
  EndProcedure
  
  Procedure E_NPC_STOP_TALK_CONTROL()
    
    e_engine\e_npc_text_field_show=#False  ;work around for a logic bug in the npc textsystem (player can stuck in dialog)
        E_NPC_SPEACH_STOP()
        If e_engine\e_engine_mode=#TALK
          e_engine\e_engine_mode=#ACTIVE  
           If npc_text\npc_conversation_activate_map_timer_time>0
            e_map_timer\_map_time=npc_text\npc_conversation_activate_map_timer_time
          EndIf
        EndIf
        
    
  EndProcedure
  
  

Procedure E_ACTION_ON_BUTTON_B(_button.i)
  

  ;if we in the game over screen:
 
   If e_engine\e_next_world=e_resurection_map.s ;dead.worldmap
      e_engine\e_next_world="intro.worldmap"
      e_engine\e_engine_mode=#ACTIVE 
      E_SET_STATUS_AFTER_GAME_OVER()
    ProcedureReturn #False
  EndIf
  
  
  
    
    Select e_engine\e_actuall_world
        
      Case "credit.worldmap","start.worldmap","story.worldmap"
        E_SOUND_BUTTON_SOUND_PLAY()
        e_engine\e_next_world="intro.worldmap"
        e_engine\e_engine_mode=#ACTIVE 
       
        E_CHECK_FOR_XBOX_JOYSTICK()
       E_GRAB_SRC_SCREEN()
      Case "intro.worldmap"
        E_CHECK_FOR_XBOX_JOYSTICK()
        ProcedureReturn #False
        

        
      Default
        
        E_NPC_STOP_TALK_CONTROL()
        E_SOUND_CONTINUE_GLOBAL_SOUND()
        
        E_SWITCH_MAP_ON_CONVERSATION()
        
          
        
    EndSelect

  
  
  EndProcedure
  
  
  
  
  Procedure E_ACTION_ON_BUTTON_M(_button.i)
    
      
  
     Select e_play_music.b
        
      Case #True
        e_play_music.b=#False
        E_SOUND_STOP_GLOBAL_SOUND()
      Case #False
        e_play_music.b=#True
        E_SOUND_PLAY_GLOBAL_SOUND()
    EndSelect

    
  EndProcedure
  
  
    Procedure E_ACTION_ON_BUTTON_W(_button.i)
    
    player_statistics\player_debug_weapon_active=#True
    
  EndProcedure
  
  

  Procedure E_ACTION_ON_BUTTON_X(_button.i)
   
  If e_engine\e_actuall_world="intro.worldmap"
    e_engine\e_next_world="credit.worldmap"
    E_GRAB_SRC_SCREEN()
    ProcedureReturn #False
  EndIf
  
  

  world_object()\object_call_dead_timer_total=e_engine_heart_beat\beats_since_start+world_object()\object_call_dead_timer
  ;this is important, new created weapon object is added to the mpa, so we have to add the object after all map objects are done (prevent from object glitching)
  ;do not activate weapon in realtiome if playerobject is calculated!
  
  If player_statistics\player_weapon_axe>0 Or  e_engine\e_engine_status=  #E_DEVELOPER_MODE
    
   Select player_statistics\player_move_direction_x
     Case #LEFT,#RIGHT
       
        E_STREAM_LOAD_SPRITE(#E_ADD_PLAYER_WEAPON_TO_MAP) 
   EndSelect
 EndIf
 

      
  
EndProcedure

Procedure E_ACTION_ON_BUTTON_Y(_button.i)
  
  

    Select e_engine\e_actuall_world
        
      Case "intro.worldmap"
        E_QUIT() 
        
      Default 
        
    
      
      
    EndSelect
    

  
  EndProcedure
  
  Procedure E_ACTION_ON_BUTTON_CONTROLLER_CONNECT_FORCE(_button.i)
  
  E_XBOX_CONTROLLER_RECONNECT()
       

EndProcedure



Procedure E_SET_UP_FOR_NEW_GAME()
             E_SOUND_BUTTON_SOUND_PLAY()
             E_CLEAN_SNAPSHOT_DIRECTORY()
             E_PLAYER_STATUS_SET_DEFAULT()
             E_SETUP_DEFAULT_START_TIME()
             player_statistics\player_show_interface=#True
             player_statistics\player_health_symbol_show=#True
            ; player_statistics\player_health_symbol_actual_symbol=player_statistics\player_health_symbol_max_symbols
             ;e_gold_show.b=#True
             ; player_statistics\player_gui_timer=ElapsedMilliseconds()+5000  ;default for develope (use script for final release)
             e_clear_inventory.b=#True
             e_engine\e_next_world=e_engine\e_new_game_entry
             DeleteFile(e_engine\e_save_pictogram_path+e_engine\e_save_pictogram_file)
EndProcedure



Procedure E_ACTION_ON_BUTTON_START(_button.i)
  
  Define _msg_button.i
  

       
       Select e_engine\e_actuall_world
           
         Case "intro.worldmap"
           
           If e_engine\e_game_status=#CONTINUE Or e_engine\e_game_status=#NEW
             
             Select e_engine\e_npc_language
               Case #DE
                 
                 _msg_button.i=E_CUSTOM_MSG_REQUESTER("Spiel neu starten?","Es werden alle Fortschritte gelöscht.")
                 
               Case #EN
                 _msg_button.i=E_CUSTOM_MSG_REQUESTER("Start a new game?","All progress will be lost.")
                 
                 
               Default 
                 _msg_button.i=E_CUSTOM_MSG_REQUESTER("Start a new game?","All progress will be lost.")
             EndSelect
             
           EndIf
           
           If  _msg_button.i=#B
             
              If IsSound(e_engine\e_global_sound_id)
            SoundVolume(e_engine\e_global_sound_id,e_engine\e_sound_global_volume,#PB_All)
              
          EndIf
           ProcedureReturn #False  
           EndIf
           
           
           If _msg_button.i=#A  Or e_engine\e_game_status=#NEW
             E_SET_UP_FOR_NEW_GAME()
             ProcedureReturn #False
           EndIf
           
       EndSelect
       

    ;for jumpnrun we can do always a "pause", so the player fight/collision situation will not change the engine situation, for RPG/Adventure in the "adventure engine" this is set, because we can solve quests and pick up keys ....
       
       If  e_engine\e_reaper_on_screen=#True  ;if this special char is on screen, no pause!!!
       ProcedureReturn #False   
       EndIf
       
       
       If  e_map_can_pause_id.b=#True  
      
      If e_engine\e_engine_mode=#ACTIVE
        e_engine\e_engine_mode=#PAUSE
        e_engine\e_gfx_show_pause=#True
        E_SOUND_PAUSE_GLOBAL_SOUND()
        E_SOUND_PAUSE_BOSS_MUSIC()
         
      EndIf
    

    EndIf 
    

     
  
EndProcedure


Procedure E_ACTION_ON_BUTTON_SELECT(_button.i)
  

;code here
  
  
EndProcedure

Procedure E_ACTION_ON_BUTTON_SEND_TO_TASKBAR(_button.i)
  
  If e_engine\e_true_screen=#True
  ProcedureReturn #False  
  EndIf
  
  
  SetWindowState(#ENGINE_WINDOW_ID,#PB_Window_Minimize)
  
  Select e_engine\e_actuall_world
      
    Case "intro.worldmap","dead.worldmap","credit.worldmap","start.worldmap","story.worldmap"
      ProcedureReturn #False
    Default
       e_engine\e_engine_mode=#PAUSE
      
  EndSelect
  
  
  
EndProcedure


Procedure E_ACTION_ON_BUTTON_SEND_TO_FULL_SCREEN(_button.i)
  SetWindowState(#ENGINE_WINDOW_ID,#PB_Window_Maximize)
  SetActiveWindow(#ENGINE_WINDOW_ID)
   e_engine\e_engine_mode=#ACTIVE
EndProcedure



Procedure  E_ACTION_ON_BUTTON_MANAGER(_button.i,_direction.i)
  
  Select _button.i
      
    Case #SEND_TO_TASKBAR
      E_ACTION_ON_BUTTON_SEND_TO_TASKBAR(_button.i)
      
    Case #FULL_SCREEN
      E_ACTION_ON_BUTTON_SEND_TO_FULL_SCREEN(_button.i)
      
      Case #START
      E_ACTION_ON_BUTTON_START(_button.i)
      
    Case #SELECT
      E_ACTION_ON_BUTTON_SELECT(_button.i)
      
    Case #A
      E_ACTION_ON_BUTTON_A(_button.i)
   
      
    Case #B
      E_ACTION_ON_BUTTON_B(_button.i)
      
      
    Case #Y
      E_ACTION_ON_BUTTON_Y(_button.i)
      
    Case #X
      E_ACTION_ON_BUTTON_X(_button.i)
      
    Case #E_CONTROLLER_CONNECT_FORCE
      E_ACTION_ON_BUTTON_CONTROLLER_CONNECT_FORCE(_button.i)
      
    Case #SHOW_FPS
      e_engine\e_show_FPS=1-e_engine\e_show_FPS
      
    Case #M
     
      E_ACTION_ON_BUTTON_M(_button.i)
      
    Case #E_DEBUG_WEAPON_ON
      
      E_ACTION_ON_BUTTON_W(_button.i)
      
      
    Case #E_GUI_ON_OFF
      
      E_SET_GUI_ON_OFF()
      
    Case #E_CRT_ON_OFF
      
      E_CRT_ON_OFF()
 
      
    Default
      
      ;if not defined:
      E_ACTION_ON_BUTTON_ALL(_button.i)
      E_GLOBAL_INPUT_ACTIONS(_button.i)
      
      
  EndSelect
  
  
EndProcedure















Procedure E_SWITCH_LOCALE(_button.i)
  ;we can switch language  on the fly, use it for debugging and interactive text editing in developer mode
  ;supported for now: english and german
  
  Select _button.i
      
    Case #E_SET_LOCALE_DE
      e_engine\e_npc_language=#DE
      e_engine\e_npc_language_file_suffix=".de"
      e_engine\e_world_map_name_language_suffix=".de"
      e_engine\e_locale_suffix="DE_"
      
      Case #E_SET_LOCALE_FR
      e_engine\e_npc_language=#FR
      e_engine\e_npc_language_file_suffix=".fr"
      e_engine\e_world_map_name_language_suffix="" ;map names not supported
      e_engine\e_locale_suffix="" ;gfx not localized to french
      
    Case #E_SET_LOCALE_E
      e_engine\e_npc_language=#EN
      e_engine\e_npc_language_file_suffix=""
      e_engine\e_world_map_name_language_suffix=""
      e_engine\e_locale_suffix=""
      
  EndSelect
  
EndProcedure



Procedure.i E_CUSTOM_MSG_REQUESTER(_head.s,_body.s)

E_CUSTOM_MSG_REQUESTER_DRAW(_head.s,_body.s)
FlipBuffers() ;bring it to the front
  Repeat 
    
    Select e_engine\e_controller_only_mode
        
      Case #True
        
        Select E_XBOX_CONTROLLER_BUTTON_INPUT()  
          Case #A
            ProcedureReturn #A  ;it is valid, we make shure no change after check
          Case #B
            ProcedureReturn #B
        EndSelect
        
        
      Default
        
        
        Select  E_XBOX_CONTROLLER_BUTTON_INPUT()
            
          Case #A
            ProcedureReturn #A
          Case #B
            ProcedureReturn #B
    
        EndSelect
        
        Select  E_KEYBOARD_INPUT_KEYS()
            
          Case #A
            ProcedureReturn #A
          Case #B
            ProcedureReturn #B

            
            
        EndSelect
        
      
        
    EndSelect
    
    
    
    
    E_CATCH_EVENTS()
    
    
  ForEver
  
EndProcedure



Procedure E_MOVE_WINDOW_WINDOW_MODE()
  
   Repeat
;     
   Until WaitWindowEvent()<>#PB_Event_RestoreWindow
;   
EndProcedure

 
 Procedure.i E_GAME_INPUT_MOUSE()
   
   If v_mouse_present.b=#False
   ProcedureReturn #False  
   EndIf
   
   
   Select e_engine\e_actuall_world   ;work around for maps (intro...), only jump and weapon are mousecontrolled
     Case "intro.worldmap","credit.worldmap","story.worldmap"
       ProcedureReturn #False
   EndSelect
   
       
       
   ExamineMouse()
   
   If MouseButton(#PB_MouseButton_Left)
    
     ProcedureReturn #A
   EndIf
   
   If MouseButton(#PB_MouseButton_Right)
      
      ProcedureReturn #X  
   EndIf
   
; 
;    
;    If MouseDeltaX()>0
;    ProcedureReturn #RIGHT  
;    EndIf
;    
;    If MouseDeltaX()<0
;      ProcedureReturn #LEFT
;    EndIf
;    
;    If MouseWheel()>0
;      ProcedureReturn #RIGHT  
;    EndIf
;    
;    If MouseWheel()<0
;      ProcedureReturn #LEFT
;    EndIf
;    
   
   ProcedureReturn #NO_BUTTON
   
 EndProcedure
 
 
 Procedure.i E_KEYBOARD_INPUT_DIRECTION()
   
   
   If v_keyboard_present.b=0
     ProcedureReturn #False  
   EndIf
   
   ExamineKeyboard()
     
   If KeyboardPushed(#PB_Key_Left) 
     ProcedureReturn #LEFT
     
   EndIf
   
   If KeyboardPushed(#PB_Key_Right) 
     ProcedureReturn #RIGHT
     
   EndIf
   If KeyboardPushed(#PB_Key_Up)
     ProcedureReturn #UP
     
   EndIf
   If KeyboardPushed(#PB_Key_Down)
     ProcedureReturn #DOWN
     
   EndIf
   
  If KeyboardPushed(#PB_Key_S)
     ProcedureReturn #LEFT
     
   EndIf
   
     If KeyboardPushed(#PB_Key_D)
     ProcedureReturn #RIGHT
     
   EndIf
   
   ProcedureReturn #NO_DIRECTION
   
   
 EndProcedure
 
 
 
 Procedure.i E_KEYBOARD_INPUT_KEYS()
   ;global routine for keyboared input (keys, no movement)
   
Define _key.i
   
   If v_keyboard_present.b=0
     ProcedureReturn #False  
   EndIf
   
   ExamineKeyboard()
   
  
       
   If KeyboardPushed( #PB_Key_B)
     ProcedureReturn #B
   EndIf
   
   If KeyboardPushed( #PB_Key_A)
     ProcedureReturn #A
   EndIf
   
   If KeyboardPushed( #PB_Key_X) Or KeyboardPushed( #PB_Key_W) 
     world_object()\object_call_dead_timer_total=e_engine_heart_beat\beats_since_start+world_object()\object_call_dead_timer    ;no time for dead 
     ProcedureReturn #X
   EndIf
   
   
   
   If KeyboardPushed( #PB_Key_Y)
     ProcedureReturn #Y
   EndIf
   
   
   If KeyboardPushed(#PB_Key_PageDown)
     ProcedureReturn #SEND_TO_TASKBAR
   EndIf
   
   
   If KeyboardPushed(#PB_Key_PageUp)
     ProcedureReturn #FULL_SCREEN
   EndIf
   
   If KeyboardPushed(#PB_Key_Space)
     ProcedureReturn #START
   EndIf
   
  
   If KeyboardPushed(#PB_Key_C)And KeyboardPushed(#PB_Key_LeftControl)
   ProcedureReturn #E_CONTROLLER_CONNECT_FORCE
 EndIf
 
     If KeyboardPushed(#PB_Key_LeftControl) And KeyboardReleased(#PB_Key_G)
   ProcedureReturn #CHANGE_COLOR_TO_GRAY  
   EndIf
   
   If KeyboardPushed(#PB_Key_LeftControl) And   KeyboardReleased(#PB_Key_F)
   ProcedureReturn #SHOW_FPS  
   EndIf
   
   
   If   KeyboardReleased(#PB_Key_F11) 
   ProcedureReturn #E_CRT_ON_OFF  
   EndIf
   
   ;---here is the extended section for developement
   
  If e_engine\e_engine_status<>#E_DEVELOPER_MODE
  ProcedureReturn #False  
  EndIf
  
  ;-------------------------------------------------------------
  
  If KeyboardReleased(#PB_Key_K) And KeyboardPushed(#PB_Key_LeftControl)
  e_engine\e_engine_boss_object_kill_switch=#True
  EndIf
  
  
   If KeyboardReleased(#PB_Key_Add) And KeyboardPushed(#PB_Key_LeftControl)
     ProcedureReturn #INCREASE_QUEST_STATUS
   EndIf
  
   If KeyboardReleased(#PB_Key_K) And KeyboardReleased(#PB_Key_LeftControl)  ;for debugging, develope
     ProcedureReturn  #E_SHOW_TEXT_FIELD
     
   EndIf
   
   
   If KeyboardReleased(#PB_Key_Subtract) And KeyboardPushed(#PB_Key_LeftControl)
     ProcedureReturn #DECREASE_QUEST_STATUS
   EndIf
   
   
   If  KeyboardReleased(#PB_Key_U) And KeyboardPushed(#PB_Key_LeftControl)
     ProcedureReturn  #E_DEVELOPE_EDIT_WORLD_NAME_TEXT
   EndIf
   
   If KeyboardReleased(#PB_Key_H) And KeyboardPushed(#PB_Key_LeftControl)
   ProcedureReturn #E_DEVELOPE_EDIT_PERMANENT_TEXT  
   EndIf
   
   If KeyboardReleased(#PB_Key_S) And KeyboardPushed(#PB_Key_LeftControl)
      ProcedureReturn #E_DEVELOPE_EDIT_SCROLL_TEXT
   EndIf
   
   
   If KeyboardReleased(#PB_Key_R) And KeyboardPushed(#PB_Key_LeftControl) 
      ProcedureReturn #E_DEVELOPE_EDIT_SILUETTE_SETTING
   EndIf
   
   If KeyboardPushed(#PB_Key_F1) 
     
     ProcedureReturn #E_SET_LOCALE_DE
     
   EndIf
   
   If  KeyboardReleased (#PB_Key_F12)
   ProcedureReturn #E_GUI_ON_OFF  
   EndIf
   
   
   If KeyboardPushed(#PB_Key_F2) 
     
     ProcedureReturn #E_SET_LOCALE_E
     
   EndIf
   
   
   If KeyboardPushed(#PB_Key_F3) 
     
     ProcedureReturn #E_SET_LOCALE_FR
     
   EndIf
   
   If KeyboardPushed(#PB_Key_1)
     
     ProcedureReturn #GAME_MODE_NIGHT
     
   EndIf
   
   If KeyboardPushed(#PB_Key_0)
     
     ProcedureReturn #GAME_MODE_DAY
     
   EndIf
   
   
   If KeyboardPushed(#PB_Key_LeftControl) And KeyboardPushed(#PB_Key_E)
          ProcedureReturn #EMERGENCY_EXIT  ;for develope
   EndIf
   
   If KeyboardPushed(#PB_Key_LeftControl) And KeyboardPushed(#PB_Key_W)
       ProcedureReturn #E_DEBUG_WEAPON_ON  
   EndIf
   
   
   
   If KeyboardPushed(#PB_Key_LeftControl) And KeyboardReleased(#PB_Key_L)
     
     ProcedureReturn #RELOAD_MAP
     
   EndIf
   
   
   
   If KeyboardPushed(#PB_Key_LeftControl)And KeyboardReleased(#PB_Key_N)  ;develope/debugging 
     
     ProcedureReturn #E_DEVELOPE_EDIT_NPC_TEXT
     
   EndIf
   
   If KeyboardPushed(#PB_Key_LeftControl) And KeyboardReleased(#PB_Key_Insert)
     
     ProcedureReturn #DEVELOPE  
     
   EndIf
   

   
ProcedureReturn #NO_BUTTON
   
 
 EndProcedure


Procedure E_GAME_INPUT_LOGIC(_mode.i)
  
  Define _input_L.i=#NO_DIRECTION
  Define _input_R.i=#NO_DIRECTION
  Define _input_DP.i=#NO_DIRECTION
  Define _direction.i=#NO_DIRECTION
  Define _button.i=#NO_BUTTON
  Define _msg_button.i=#NO_BUTTON
  
  ;_input_L.i=result of controller or keyboard input
  
 
  
  Select _mode.i
      
    Case #KEYBOARD
      
      If e_xbox_controller\xbox_joystick_present=#False Or e_engine\e_engine_status=#E_DEVELOPER_MODE
      _button.i=E_KEYBOARD_INPUT_KEYS()
      _direction.i=E_KEYBOARD_INPUT_DIRECTION()
    EndIf
    

      
    Case #XBOX_CONTROLLER
      
     If e_xbox_controller\xbox_joystick_present=#True
     
      _input_L.i=E_XBOX_CONTROLLER_DIRECTION_L_STICK()
      _input_R.i=E_XBOX_CONTROLLER_DIRECTION_R_STICK()
      If _input_L.i=#NO_DIRECTION; And _input_R=#NO_DIRECTION
        _input_DP.i=E_XBOX_CONTROLLER_DIRECTION_DPAD()
      EndIf
      
      _button.i=E_XBOX_CONTROLLER_BUTTON_INPUT()
    EndIf
    
      
    Case #MOUSE
       If e_xbox_controller\xbox_joystick_present=#False
         _button.i=E_GAME_INPUT_MOUSE()
       EndIf
      
      
  EndSelect
  
 
  
  E_ACTION_ON_BUTTON_MANAGER(_button.i,_direction.i)
 
   
  ; in title screen we try to force areconnect for controller if input controller only is set

  E_SWITCH_LOCALE(_button.i)


EndProcedure





; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 132
; FirstLine = 113
; Folding = -
; EnableXP
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant