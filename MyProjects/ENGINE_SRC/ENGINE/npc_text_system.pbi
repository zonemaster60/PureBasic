Declare E_SET_UP_FOR_INPUT_IDLE()
Declare E_GAME_INPUT_LOGIC(_mode.i)
Declare E_KEYBOARD_INPUT_DIRECTION()
Declare E_KEYBOARD_INPUT_KEYS()
Declare E_SET_UP_FOR_INPUT_IDLE()
Declare E_NPC_STOP_TALK_CONTROL()


Procedure E_NPC_GET_TEXT_BUTTON()
  ;here we go for the immage gfx for some buttons displayed in the text box
  
  If  IsImage(npc_text\npc_button_B)
    ProcedureReturn #False ;we got all  
  EndIf
  
  npc_text\npc_button_B=LoadImage(#PB_Any,npc_text\npc_button_B_path,0)
  
 
EndProcedure

  



Procedure E_NPC_SHOW_CORE_INFO_SYSTEM()
  ;use this for debugging and developement reasons, set value to #true (script) to activate
  If e_npc_show_core_info.b<>#True
  ProcedureReturn #False
  EndIf
    npc_text\text_text[0]=e_npc_debugging_dummy_text_var.s;for debugging and developement reasons only, remove this line, we show the filename of the npc text
    ProcedureReturn 1;for debugging and develope only, remove this line 
 EndProcedure
  

Procedure E_GET_NPC_PIC()
  ;if NPC uses conterfy we can grab it here:
  If  e_engine\e_npc_text_field_show<>#True
    ProcedureReturn #False  
  EndIf
  
  
  If IsImage(npc_confy\confy_id)
    FreeImage(npc_confy\confy_id)  
  EndIf
  
  If npc_confy\confy_h<1
    npc_confy\confy_h=64  
  EndIf
  
  If npc_confy\confy_w<1
    npc_confy\confy_w=64 ;default  
  EndIf
  
  npc_confy\confy_show=#False
  

  
  npc_confy\confy_id=LoadImage(#PB_Any,player_statistics\player_core_path+npc_confy\confy_path,0)
  If IsImage(npc_confy\confy_id)
    ;ResizeImage(npc_confy\confy_id,npc_confy\confy_w,npc_confy\confy_h)
    npc_confy\confy_show=#True 
    
  EndIf
  
  
  
EndProcedure





Procedure E_NPC_SHOW_PIC(_text_field_offset_if_outside_y.f)
  ;here we try to show the NPC pic:
  
  E_GET_NPC_PIC()
  If  npc_confy\confy_show=#True  And  e_engine\e_npc_text_field_show=#True And IsImage(npc_confy\confy_id)
     DrawAlphaImage(ImageID(npc_confy\confy_id),e_engine\e_npc_text_field_x,e_engine\e_npc_text_field_y+_text_field_offset_if_outside_y.f,255) 
  EndIf
  
   
  EndProcedure
  
  

  


Procedure.f E_NPC_MOVE_TEXT()
  
  Define _button.i=#NO_BUTTON
  Define _direction.i=#NO_DIRECTION

  
  If e_engine\e_controller_only_mode=#True
    _direction.i=E_XBOX_CONTROLLER_DIRECTION_R_STICK()
    _button.i=E_XBOX_CONTROLLER_BUTTON_INPUT()
  EndIf
  
  
  If e_engine\e_controller_only_mode=#False
    
    If _direction.i=#NO_DIRECTION And _button.i=#NO_BUTTON
    
    If e_xbox_controller\xbox_joystick_present=#True
      _direction.i=E_XBOX_CONTROLLER_DIRECTION_R_STICK()
      _button.i=E_XBOX_CONTROLLER_BUTTON_INPUT()
    EndIf
    
    If _direction.i=#NO_DIRECTION
      _direction.i=E_KEYBOARD_INPUT_DIRECTION()
    EndIf
    
    
    If _button.i=#NO_BUTTON
       _button.i=E_KEYBOARD_INPUT_KEYS()
     EndIf
     
   EndIf
   
    
  EndIf
  

  
  Select  _direction.i
     
    Case #UP
     
       ProcedureReturn 1  ;line up
   Case #DOWN
    
      ProcedureReturn -1  ;line down
     
  EndSelect




EndProcedure 


Procedure E_SOUND_ON_NPC_TEXT_START()
;   If IsSound(e_npc_text_field_sound_id.i)
;     PlaySound(e_npc_text_field_sound_id.i, #PB_Sound_MultiChannel) 
;   EndIf
  
  If IsSound(npc_text\npc_text_pop_up_sound_id)
    SoundVolume(npc_text\npc_text_pop_up_sound_id,npc_text\npc_text_pop_up_sound_volume)
     PlaySound(npc_text\npc_text_pop_up_sound_id)  
   EndIf
  
EndProcedure





Procedure E_NPC_TEXT_OUTPUT()
  
  ;here we have the main text routine, for NPC and other text interactions
  Define _dummy_text.s=e_engine\e_npc_dummy_text_for_debugging+"    THIS IS DUMMY NPC TEXT -- TO CLOSE  PRESS [B] "
  Define _line_counter.b=0
  Static _actual_line.b=0  ;startline....
  Static _last_line.b=0
  Define _line_position.b=0
  Static _play_sound.b=#False
  Define _start_line.b=0
  Define _text_field_height.f=0
  Define _text_field_offset_if_outside_y.f=0
  
  If e_engine\e_npc_text_field_show<>#True
    _play_sound.b=#True
     npc_text\text_offset_y=0
     ProcedureReturn #False
  EndIf
  
  
  If _play_sound.b=#True
    
    E_SOUND_ON_NPC_TEXT_START()
   ; e_engine\e_engine_mode=#TALK
    _play_sound.b=#False
    
  EndIf
  
  e_engine\e_engine_mode=#TALK
  ;e_npc_text_field_x=v_screen_w/3
   e_engine\e_npc_text_field_x=player_statistics\player_pos_x/2
  
  If IsImage(e_engine\e_npc_text_field_texture_id)
    ;e_engine\e_npc_text_field_h=ImageHeight(e_npc_text_field_texture_id)
    e_engine\e_npc_text_field_h=100
    e_engine\e_npc_text_field_y=player_statistics\player_pos_y-200
    
  Else
    e_engine\e_npc_text_field_h=100
    e_engine\e_npc_text_field_y=player_statistics\player_pos_y-200
  EndIf
  
  
  If e_engine\e_npc_text_field_y<32
  _text_field_offset_if_outside_y.f=e_engine\e_engine_internal_screen_h/2  
  EndIf
  
  
 If IsImage(e_engine\e_npc_text_field_texture_id)<>0
    DrawAlphaImage(ImageID(e_engine\e_npc_text_field_texture_id),e_engine\e_npc_text_field_x,e_engine\e_npc_text_field_y+_text_field_offset_if_outside_y.f,e_TEXT_FIELD_INTENSY.i) 
 EndIf
 
    E_NPC_SHOW_PIC(_text_field_offset_if_outside_y.f)
 

  DrawingFont(FontID(#NPC_FONT_ID))
  DrawingMode( #PB_2DDrawing_Transparent )
  
  If IsImage(e_engine\e_npc_text_field_texture_id)=0
  Box(e_engine\e_npc_text_field_x,e_engine\e_npc_text_field_y+_text_field_offset_if_outside_y.f,e_engine\e_npc_text_field_w,e_engine\e_npc_text_field_h,RGB(0,50,100))  
  EndIf
  
  
  If e_engine\e_show_debug=#True
   DrawText(e_engine\e_npc_text_field_x+10,e_engine\e_npc_text_field_y+_text_field_offset_if_outside_y.f,GetFilePart(e_engine\e_npc_dummy_text_for_debugging),e_engine\e_COLOR_BLACK)   ;debug output for NPC name/filename of NPC (it depends on map name!)
 EndIf
  
  If npc_text\text_last_line>4
    
    npc_text\text_show_line=(npc_text\text_last_line)*e_GUI_font\e_GUI_npc_font_size+(e_engine\e_npc_text_field_y+_text_field_offset_if_outside_y.f+e_engine\e_npc_text_field_h)
    
    If E_NPC_MOVE_TEXT()>0 And npc_text\text_pos_y<(npc_text\text_show_line-e_engine\e_npc_text_field_h)
      npc_text\text_offset_y+E_NPC_MOVE_TEXT() 
    EndIf
    
    If E_NPC_MOVE_TEXT()<0 And npc_text\text_pos_y>(e_engine\e_npc_text_field_y+_text_field_offset_if_outside_y.f)
      npc_text\text_offset_y+E_NPC_MOVE_TEXT() 
    EndIf
    
  EndIf
  

  
  While _start_line.b<= npc_text\text_last_line
    
   
   npc_text\text_pos_y=(e_engine\e_npc_text_field_y+_text_field_offset_if_outside_y.f)+_start_line.b*e_GUI_font\e_GUI_npc_font_size+npc_text\text_offset_y ;24=text height ,hardcoded at teh moment
   If npc_text\text_pos_y>=(e_engine\e_npc_text_field_y+_text_field_offset_if_outside_y.f) And npc_text\text_pos_y<(e_engine\e_npc_text_field_y+e_engine\e_npc_text_field_h+_text_field_offset_if_outside_y.f)
    ; DrawText(e_engine\e_npc_text_field_x+12+64,npc_text\text_pos_y+16,npc_text\text_text[_start_line.b],e_COLOR_GRAY) ;use back shadow for better contrast
     DrawText(e_engine\e_npc_text_field_x+10+64,npc_text\text_pos_y+e_GUI_font\e_GUI_npc_font_size,npc_text\text_text[_start_line.b],e_engine\e_COLOR_BLACK)
     
     
   EndIf
   _start_line.b+1

 Wend
 
 
 

EndProcedure



Procedure.i E_GET_NPC_TEXT_RANDOM()
  ;german random default conversation textoutput, make the npcs a bit more  different
  
  Define _file.i=0
  Define _count.b=0
  Define _text_random_id.b=0
  Define _text_random_id_string.s=""
   
  While npc_text\text_last_text_id=_text_random_id.b And _count.b<=e_NPC_maximum_text_alternative.b
  _text_random_id.b=Random(e_NPC_maximum_text_alternative.b)
  _text_random_id_string.s=Str(_text_random_id.b)
  _count.b+1  ;important, so we exit anyway
  Wend
  
  npc_text\text_last_text_id=_text_random_id.b
 
  e_npc_debugging_dummy_text_var.s=v_engine_base.s+world_object()\object_NPC_text_path+_text_random_id_string.s+e_engine\e_npc_language_file_suffix.s
  e_engine\e_npc_dummy_text_for_debugging=v_engine_base.s+world_object()\object_NPC_text_path
  _file.i=ReadFile(#PB_Any,e_npc_debugging_dummy_text_var.s)
  ProcedureReturn _file.i
 EndProcedure
 
 
 Procedure E_NPC_SPEACH_STOP()
   
   If IsSound(npc_text\npc_speach_output_id)=0
   ProcedureReturn #False  
 EndIf
 
  StopSound(npc_text\npc_speach_output_id)
  
   If IsSound(e_engine\e_global_sound_id)
   SoundVolume(e_engine\e_global_sound_id,e_engine\e_sound_global_volume)  
 EndIf
 
   
 EndProcedure
 
 
 
 Procedure E_NPC_SPEACH_OUTPUT()
   
 If IsSound(npc_text\npc_speach_output_id)=0
   ProcedureReturn #False  ; bullet proof :)   check
 EndIf
 
 If npc_text\npc_speach_set_global_volume>=0 
   
   If  npc_text\npc_speach_set_global_volume>100
     npc_text\npc_speach_set_global_volume=100
   EndIf

 If IsSound(e_engine\e_global_sound_id)
   SoundVolume(e_engine\e_global_sound_id,npc_text\npc_speach_set_global_volume)  
 EndIf
 
EndIf

 PlaySound(npc_text\npc_speach_output_id)
   
   
 EndProcedure
 
 

 Procedure E_NPC_GET_SPEACH_FILE()
   ;try to get the speach file!
   
   If IsSound(npc_text\npc_speach_output_id)  ;clean it up!
   FreeSound(npc_text\npc_speach_output_id)    
   EndIf
   
   
   npc_text\npc_speach_file_path=v_engine_base.s+world_object()\object_NPC_text_path+npc_text\npc_speach_output_file_type
   npc_text\npc_speach_output_id=LoadSound(#PB_Any,npc_text\npc_speach_file_path,#PB_Sound_Streaming)
   
   If IsSound(npc_text\npc_speach_output_id)
     ProcedureReturn #True
   EndIf
   
  ProcedureReturn #False
   
 EndProcedure
 
 
 Procedure.i E_NPC_TEXT_SPLIT(_text_full.s,_text_line.i)
   ;here we check for "," to split text into lines
   
  Define _found.i=0
  Define _text_part_left.s=""
  Define _text_part_right.s=""
  
  
  _found.i=FindString(_text_full.s,",")
  
  If _found.i<1
  ProcedureReturn _text_line.i +1
  EndIf
  

  _text_part_left.s=Left(_text_full.s,_found.i)
  _text_part_right.s=Mid(_text_full.s,_found.i+1)
  
  npc_text\text_text[_text_line.i]=_text_part_left.s
  _text_line.i+1
  npc_text\text_text[_text_line.i]=Trim(_text_part_right.s)
  _text_line.i+1


ProcedureReturn _text_line.i
   
 EndProcedure
 


Procedure E_GET_NPC_TEXT(_mode.i)
  
  ;_mode.l=randomm language yes /no 
  
  Define _file.i=0
  Define _count.i=0
  
  
  ;If 
    ChangeCurrentElement(world_object(),brain\e_object_system_id2)
  ;ProcedureReturn #False  
  ;EndIf
  
  
  Select e_engine\e_npc_language
    Case #DE
      e_engine\e_npc_language_file_suffix=".de"
    Case #EN
      e_engine\e_npc_language_file_suffix=""
    Case #FR
      e_engine\e_npc_language_file_suffix=".fr"
    Default 
     e_engine\e_npc_language_file_suffix=""
      
  EndSelect
  


  
    _count.i=E_NPC_SHOW_CORE_INFO_SYSTEM()
  
  
    If _mode.i=#NPC_USE_RANDOM_TEXT
      _file.i= E_GET_NPC_TEXT_RANDOM()
      If IsFile(_file.i)=0  ;no random conversation : get default file
     e_engine\e_npc_dummy_text_for_debugging=v_engine_base.s+world_object()\object_NPC_text_path
     e_npc_debugging_dummy_text_var.s=v_engine_base.s+world_object()\object_NPC_text_path+e_engine\e_npc_language_file_suffix
    _file.i=ReadFile(#PB_Any,  e_npc_debugging_dummy_text_var.s,#PB_File_SharedRead) 
      EndIf
      
    EndIf
    
    
    
    E_NPC_GET_SPEACH_FILE()
    E_NPC_SPEACH_OUTPUT()
  
 
  If IsFile(_file.i)<>0
    
    While Not Eof(_file.i)
      
      npc_text\text_text[_count.i]=ReadString(_file.i)
      If Len(npc_text\text_text[_count.i])>0  ;no empty lines (workaround for old text files, which used emty lines as buffer for lines displayed)
        npc_text\text_text[_count.i]= E_INTERPRETER_GET_KEYWORD(npc_text\text_text[_count.i]) 
        
        _count.i=E_NPC_TEXT_SPLIT(npc_text\text_text[_count.i],_count.i)
       
        

        
      EndIf
      
    Wend
    
   
    
    CloseFile(_file.i)
    
     npc_text\text_text[_count.i]="[B]"
     npc_text\text_last_line=_count.i
    
  Else
    
    ;no german/alternative language pack found? we try To use english version
    _file.i=ReadFile(#PB_Any,v_engine_base.s+world_object()\object_NPC_text_path,#PB_File_SharedRead)
    
   
    If IsFile(_file.i)
      
      While Not Eof(_file.i)
        npc_text\text_text[_count.i]=ReadString(_file.i)
        
        If Len(npc_text\text_text[_count.i])>0  ;no empty lines (workaround for old text files, which used emty lines as buffer for lines displayed)
         npc_text\text_text[_count.i]= E_INTERPRETER_GET_KEYWORD(npc_text\text_text[_count.i])  ;here we inject some dynamic text, if a keyword is given
         
         _count.i=E_NPC_TEXT_SPLIT(npc_text\text_text[_count.i],_count.i)
         
         
         
         
      EndIf
        
      Wend
      CloseFile(_file.i)
        npc_text\text_text[_count.i]="[B]"
        npc_text\text_last_line=_count.i
      
    EndIf
    
  EndIf

EndProcedure

Procedure E_SWITCH_MAP_ON_CONVERSATION()
  ;if NPC talk sitches to next / another map:
  If npc_text\npc_conversation_switch_map=#False
  ProcedureReturn #False  
  EndIf
  
  e_engine\e_next_world=npc_text\npc_conversation_switch_map_file
  E_GRAB_SRC_SCREEN()  
  
EndProcedure






Procedure E_NPC_CONTROL()
  e_engine\e_npc_text_field_show=#True
  npc_confy\confy_path=world_object()\object_NPC_text_pic_path
  npc_text\npc_conversation_switch_map=world_object()\object_NPC_switch_map_on_talk
  npc_text\npc_conversation_switch_map_file=world_object()\object_NPC_switch_map_on_talk_file
  npc_text\npc_conversation_activate_map_timer_time=world_object()\object_NPC_map_timer_active_on_talk
  npc_text\npc_remove_after_talk=world_object()\object_NPC_remove_after_talk
  e_npc_debugging_dummy_text_var.s=world_object()\object_NPC_text_path
  E_GET_NPC_TEXT(#NPC_USE_RANDOM_TEXT) 
  
  If world_object()\object_NPC_remove_after_talk=#True
    world_object()\object_is_active=#False  
    world_object()\object_remove_from_list=#True
  EndIf
  
  
EndProcedure
  
  
  
  Procedure E_COLLISION_NPC()
    
    If world_object()\object_NPC_show_text_on_collision=#True
     E_NPC_CONTROL()
    EndIf
       
       E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_TALK)
    
  EndProcedure 

  
  Procedure E_TALK_AREA_NPC()
    
    ;does not work, do not use this object setting!
    Define _x_dist.f=0
    Define _y_dist.f=0
    
    
    If world_object()\object_NPC_use_talk_area=#False
    ProcedureReturn #False  
    EndIf
    

        
        
        _x_dist.f=player_statistics\player_pos_x-e_engine\e_world_offset_x-world_object()\object_x
        _x_dist.f=Abs(_x_dist.f)
        
        _y_dist.f=player_statistics\player_pos_y-e_engine\e_world_offset_y-world_object()\object_y
        _y_dist.f=Abs(_y_dist.f)
    

      
        If _x_dist.f<world_object()\object_NPC_talk_area_w And _y_dist.f<world_object()\object_NPC_talk_area_h 
          
          If world_object()\object_NPC_is_talking=#False
            world_object()\object_NPC_is_talking=#True
            E_NPC_CONTROL()
            E_SOUND_CORE_CONTROLLER(#ENGINE_PLAY_SOUND_ON_TALK)
          EndIf
          
        Else
          world_object()\object_NPC_is_talking=#False
          E_NPC_STOP_TALK_CONTROL()
        EndIf
     
    
  EndProcedure 

  

  
  
Procedure E_GET_INFO_NPC_TEXT()
  
  ;_mode.l=randomm language yes /no 
  
  Define _file.i=0
  Define _count.b=0
  E_NPC_GET_TEXT_BUTTON()
  
  
  Select e_engine\e_npc_language
    Case #DE
      e_engine\e_npc_language_file_suffix=".de"
    Case #EN
      e_engine\e_npc_language_file_suffix=""
  EndSelect
  

  _file.i=ReadFile(#PB_Any,world_object()\object_NPC_text_path+e_engine\e_npc_language_file_suffix.s,#PB_File_SharedRead)
  
  If IsFile(_file.i)
    
    While Not Eof(_file.i) And _count.b<80
      npc_text\text_text[_count.b]=ReadString(_file.i)
      
      If Len(npc_text\text_text[_count.b])>0  ;no empty lines (workaround for old text files, which used emty lines as buffer for lines displayed)
        _count.b+1
      EndIf
    Wend
    
    CloseFile(_file.i)
    
    npc_text\text_text[_count.b]="[B]"
    npc_text\text_last_line=_count.b
    
  Else
    
    ;no german/alternative language pack found? we try To use english version as default
    _file.i=ReadFile(#PB_Any,world_object()\object_NPC_text_path,#PB_File_SharedRead)
    
    
    If IsFile(_file.i)
      
      While Not Eof(_file.i)  And _count.b<80
        npc_text\text_text[_count.b]=ReadString(_file.i)
         If Len(npc_text\text_text[_count.b])>0  ;no empty lines (workaround for old text files, which used emty lines as buffer for lines displayed)
        _count.b+1
      EndIf
      Wend
      CloseFile(_file.i)
      
    EndIf
    
  EndIf
  npc_text\text_text[_count.b]="[B]"
  npc_text\text_last_line=_count.b


EndProcedure



; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 26
; FirstLine = 16
; Folding = ---
; EnableXP
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant