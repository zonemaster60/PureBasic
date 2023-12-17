;here we have all sound routines



Procedure E_SOUND_PLAY_ON_RESTORE()
  
  
  If IsSound(world_object()\object_sound_on_restore_id)=0
  ProcedureReturn #False  
  EndIf
  
  
  If  world_object()\object_play_sound_on_restore=#False
    ProcedureReturn #False
    
  EndIf
  
    
  If SoundStatus(world_object()\object_sound_on_restore_id)=#PB_Sound_Playing
  ProcedureReturn #False  
  EndIf
  
  SoundVolume(world_object()\object_sound_on_restore_id,world_object()\object_sound_on_restore_volume)
  PlaySound(world_object()\object_sound_on_restore_id)
 
EndProcedure



Procedure E_SOUND_PLAY_PLAYER_LEVEL_UP()
  
  If IsSound(player_statistics\player_sound_on_level_up_id)=0
  ProcedureReturn #False  
EndIf

  SoundVolume(player_statistics\player_sound_on_level_up_id,e_engine\e_sound_global_volume)
  
  PlaySound(player_statistics\player_sound_on_level_up_id)
  
EndProcedure

Procedure E_SOUND_PLAY_TELEPORT()
  
  If IsSound(player_statistics\player_spawn_teleport_sound_id)=0
  ProcedureReturn #False  
  EndIf
  
  SoundVolume(player_statistics\player_spawn_teleport_sound_id,e_engine\e_sound_global_volume)
  PlaySound(player_statistics\player_spawn_teleport_sound_id)
  
EndProcedure

Procedure E_SOUND_PLAY_JUMP()
  
  If IsSound(world_object()\object_sound_on_jump_id)=0 Or world_object()\object_play_sound_on_jump=#False
  ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
  ProcedureReturn #False 
  EndIf
  
  SoundVolume(world_object()\object_sound_on_jump_id,world_object()\object_sound_on_jump_volume)
  
  PlaySound(world_object()\object_sound_on_jump_id)
  world_object()\object_sound_is_playing=#True
EndProcedure





Procedure E_SOUND_PLAY_GLOBAL_SOUND()
  
   

    
  If IsSound(e_engine\e_global_sound_id)=0
    ProcedureReturn #False  
  EndIf
  
  If e_play_music.b=#False
    ProcedureReturn #False  
    
  EndIf
  
 
  SoundVolume(e_engine\e_global_sound_id,e_engine\e_sound_global_volume)  ;reset from the "pause routine", because streamed souds can not be paused, we set the volume of a streamed sound to zero
  If SoundStatus(e_engine\e_global_sound_id,e_engine\e_global_sound_id)<>#PB_Sound_Playing
    PlaySound(e_engine\e_global_sound_id,#PB_Sound_Loop)
    world_object()\object_sound_is_playing=#True
EndIf

  
  
  
EndProcedure


Procedure E_SOUND_STOP_BOSS_MUSIC()
   

  
  If IsSound(world_object()\object_boss_music_id)
  StopSound(world_object()\object_boss_music_id)  
  
EndIf

If IsSound(e_engine\e_global_sound_id)=0
ProcedureReturn #False  
EndIf


  If  SoundStatus(e_engine\e_global_sound_id)=#PB_Sound_Playing
      SoundVolume(e_engine\e_global_sound_id,e_engine\e_sound_global_volume)  ;used this because we use streaming sounds, so pause does not work
  EndIf
   

EndProcedure


Procedure E_SOUND_CONTINUE_BOSS_MUSIC()
   

  If e_engine\e_pointer_sound_boss=0
    ProcedureReturn #False
  EndIf
  
  If IsSound(e_engine\e_pointer_sound_boss)
  SoundVolume(e_engine\e_pointer_sound_boss,e_engine\e_sound_boss_sound_volume)  ;used this because we use streaming sounds, so pause does not work
EndIf


EndProcedure

Procedure E_SOUND_PAUSE_BOSS_MUSIC()
   
  If e_engine\e_pointer_sound_boss=0
    ProcedureReturn #False
  EndIf
  SoundVolume(e_engine\e_pointer_sound_boss,0)  

EndProcedure


Procedure E_SOUND_PLAY_BOSS_MUSIC()
   

If  world_object()\object_boss_music_is_playing=#True  ;we play already the boss!
  ProcedureReturn #False  
EndIf



If IsSound(world_object()\object_boss_music_id)
  PlaySound(world_object()\object_boss_music_id,#PB_Sound_Loop,world_object()\object_boss_music_volume)  
  world_object()\object_boss_music_is_playing=#True
  e_engine\e_pointer_sound_boss=world_object()\object_boss_music_id
  e_engine\e_sound_boss_sound_volume=world_object()\object_boss_music_volume

EndIf


EndProcedure


Procedure E_SOUND_CONTINUE_GLOBAL_SOUND()
  

  If IsSound(e_engine\e_global_sound_id)=0
  ProcedureReturn #False  
EndIf
  
  If  world_object()\object_boss_music_is_playing=#True  ;we play already the boss!
  ProcedureReturn #False  
EndIf


  SoundVolume(e_engine\e_global_sound_id,e_engine\e_sound_global_volume)

   
EndProcedure


Procedure E_SOUND_PAUSE_GLOBAL_SOUND()
  
;   
;   If e_sound_volume_to_zero.b=#False
;  ProcedureReturn #False  
; EndIf
    
  If IsSound(e_engine\e_global_sound_id)=0
  ProcedureReturn #False  
EndIf
  
  SoundVolume(e_engine\e_global_sound_id,0)  

   
EndProcedure



Procedure E_SOUND_STOP_GLOBAL_SOUND()
  
 If IsSound(e_engine\e_global_sound_id)=0
  ProcedureReturn #False  
EndIf

StopSound(e_engine\e_global_sound_id)

  
  EndProcedure
  
  
  
  Procedure E_SOUND_PLAY_SOUND_ON_FIGHT()
    
    
    
    
    If e_play_music.b=#False
      ProcedureReturn #False  
    EndIf
    
    If player_statistics\player_do_not_play_fight_music=#True
      ProcedureReturn #False  
    EndIf
    
    If player_statistics\player_fight_music_is_playing=#True
      ProcedureReturn #False  
    EndIf
    
    
    If IsSound(player_statistics\player_sound_on_fight_id)=0
      ProcedureReturn #False
    EndIf
    
    
    If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
      ProcedureReturn #False 
    EndIf
    SoundVolume(player_statistics\player_sound_on_fight_id,player_statistics\player_sound_on_fight_volume)
    PlaySound(player_statistics\player_sound_on_fight_id)
    
    player_statistics\player_fight_music_is_playing=#True
    world_object()\object_sound_is_playing=#True
    
  EndProcedure
  
  
  
   Procedure E_SOUND_STOP_SOUND_ON_FIGHT()
     
  If player_statistics\player_fight_music_is_playing=#False
  ProcedureReturn #False  
  EndIf

  If IsSound(player_statistics\player_sound_on_fight_id)=0
      ProcedureReturn #False
  EndIf

StopSound(player_statistics\player_sound_on_fight_id)
 player_statistics\player_fight_music_is_playing=#False

   
 EndProcedure
 
  
  
  


 
 


 Procedure E_SOUND_PLAY_SOUND_ON_COLLISION()
   
   
   If world_object()\object_play_sound_on_collision<>#True
     ProcedureReturn #False  
   EndIf
   
   If IsSound(world_object()\object_sound_on_collision_id)=0
     ProcedureReturn #False
   EndIf
   

   
   If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
     ProcedureReturn #False 
   EndIf
   
   SoundVolume(world_object()\object_sound_on_collision_id,world_object()\object_sound_volume)
   PlaySound(world_object()\object_sound_on_collision_id)
   world_object()\object_sound_is_playing=#True
   
 EndProcedure
 
 
  
  Procedure E_SOUND_PLAY_ON_EMIT()
    
   
    If world_object()\object_play_sound_on_emit=#False
    ProcedureReturn #False  
    EndIf
    
    If IsSound(world_object()\object_emit_sound_id)=0
    ProcedureReturn #False  
  EndIf
  
    If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
  ProcedureReturn #False 
  EndIf
  
  SoundVolume(world_object()\object_emit_sound_id,world_object()\object_sound_on_emit_volume)
  PlaySound(world_object()\object_emit_sound_id)
  world_object()\object_sound_is_playing=#True
  
 EndProcedure
 
 
   Procedure E_SOUND_STOP_ON_EMIT()
   
    If world_object()\object_play_sound_on_emit=#False
    ProcedureReturn #False  
    EndIf
    
    If IsSound(world_object()\object_emit_sound_id)=0
    ProcedureReturn #False  
  EndIf
  
    StopSound(world_object()\object_emit_sound_id)
    
 EndProcedure
 
 
 
 Procedure E_SOUND_STOP_SOUND_ON_ALLERT()
   
If IsSound(world_object()\object_sound_on_allert_id)
    StopSound(world_object()\object_sound_on_allert_id)
  EndIf
  
 EndProcedure
 

 
 Procedure E_SOUND_PLAY_SOUND_ON_ALLERT()
   
   
   If world_object()\object_play_sound_on_allert=#False
   ProcedureReturn #False  
   EndIf


   If IsSound(world_object()\object_sound_on_allert_id)=0
     ProcedureReturn #False  
   EndIf
   
  
   If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
     ProcedureReturn #False 
   EndIf
   
   SoundVolume(world_object()\object_sound_on_allert_id,world_object()\object_sound_on_allert_volume)
     PlaySound(world_object()\object_sound_on_allert_id)
     world_object()\object_sound_is_playing=#True

   
   EndProcedure
   
    Procedure E_SOUND_PLAY_SOUND_ON_CHANGE()
   
   
   If world_object()\object_play_sound_on_change=#False
   ProcedureReturn #False  
   EndIf


   If IsSound(world_object()\object_sound_on_change_id)=0
     ProcedureReturn #False  
   EndIf
   
  
   If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
     ProcedureReturn #False 
   EndIf
   
   SoundVolume(world_object()\object_sound_on_change_id,world_object()\object_sound_on_change_volume)
     PlaySound(world_object()\object_sound_on_change_id)
     world_object()\object_sound_is_playing=#True

   
   EndProcedure
 
 
 Procedure E_SOUND_PLAY_SOUND_ON_ACTIVATE()
   
   
   If world_object()\object_play_sound_on_activate=#False
   ProcedureReturn #False  
   EndIf
   
   If IsSound(world_object()\object_sound_on_activate_id)=0
     ProcedureReturn #False  
   EndIf
   
  
   If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
     ProcedureReturn #False 
   EndIf

SoundVolume(world_object()\object_sound_on_activate_id,world_object()\object_sound_on_activate_volume)
     PlaySound(world_object()\object_sound_on_activate_id)
     world_object()\object_sound_is_playing=#True

   
 EndProcedure



  Procedure E_SOUND_STOP_SOUND_ON_ACTIVATE()
   

If IsSound(world_object()\object_sound_on_activate_id)
    StopSound(world_object()\object_sound_on_activate_id)
  EndIf
  
EndProcedure


 
 Procedure E_SOUND_STOP_SOUND_ON_COLLISION()

  

  If IsSound(world_object()\object_sound_on_collision_id)=0  ;
      ProcedureReturn #False
  EndIf
  
  If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
    ProcedureReturn #False 
  EndIf
  
  
  SoundVolume(world_object()\object_sound_on_collision_id,world_object()\object_sound_on_collision_volume)
  
  PlaySound(world_object()\object_sound_on_collision_id)
  world_object()\object_sound_is_playing=#True 
    



EndProcedure




Procedure E_SOUND_STOP_SOUND_ON_CHILD_CREATION()



  If IsSound(world_object()\object_create_child_sound_id)=0
      ProcedureReturn #False
  EndIf
  
  StopSound(world_object()\object_create_child_sound_id)

EndProcedure


Procedure E_SOUND_PLAY_SOUND_ON_CHILD_CREATION()
  
  If IsSound(world_object()\object_create_child_sound_id)=0
    ProcedureReturn #False
  EndIf
  
  
   
  If world_object()\object_play_sound_on_create_child=#False
    ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
    ProcedureReturn #False 
  EndIf
  
  SoundVolume(world_object()\object_create_child_sound_id,world_object()\object_create_child_sound_volume)
  PlaySound(world_object()\object_create_child_sound_id)
  world_object()\object_sound_is_playing=#True
  
EndProcedure


Procedure E_SOUND_STOP_SOUND_ON_CREATION()

  If IsSound(world_object()\object_sound_on_create_id)=0
      ProcedureReturn #False    
  EndIf

      StopSound(world_object()\object_sound_on_create_id)

EndProcedure


Procedure E_SOUND_PLAY_SOUND_ON_CREATION()
  
  If world_object()\object_play_sound_on_create=#False
  ProcedureReturn #False  
  EndIf
  
 If IsSound(world_object()\object_sound_on_create_id)=0
      ProcedureReturn #False
  EndIf
  

  SoundVolume(world_object()\object_sound_on_create_id,world_object()\object_sound_on_create_volume)
    world_object()\object_play_sound_on_create=#False ;reset to valid state!
    PlaySound(world_object()\object_sound_on_create_id)
    world_object()\object_sound_is_playing=#True
    
    
EndProcedure



Procedure E_SOUND_PLAY_SOUND_ON_TALK()
    
  If world_object()\object_play_sound_on_talk=#False
  ProcedureReturn #False  
  EndIf

  
 If IsSound(world_object()\object_sound_on_talk_id)=0
      ProcedureReturn #False
  EndIf
  

  
  If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
  ProcedureReturn #False 
  EndIf
  SoundVolume(world_object()\object_sound_on_talk_id,world_object()\object_sound_on_talk_volume)
    PlaySound(world_object()\object_sound_on_talk_id)
    world_object()\object_sound_is_playing=#True
    
    
EndProcedure
 

 Procedure E_SOUND_STOP_SOUND_ON_TALK()


  If IsSound(world_object()\object_sound_on_talk_id)=0
      ProcedureReturn #False
  EndIf
  

    StopSound(world_object()\object_sound_on_talk_id)


EndProcedure

 
 Procedure E_SOUND_STOP_SOUND_ON_MOVE()


  If IsSound(world_object()\object_sound_on_move_id)=0
      ProcedureReturn #False
  EndIf
  

    StopSound(world_object()\object_sound_on_move_id)


EndProcedure


Procedure  E_SOUND_STOP_SOUND_ON_RANDOM()
  ;if out of sight:

  ;stopp random sounds (use it because of long sound files, they do not quit after object is out of sight, until the played to the end)
  If IsSound(world_object()\object_sound_on_random_id)=0
  ProcedureReturn #False  
  EndIf

        StopSound(world_object()\object_sound_on_random_id)  

EndProcedure


Procedure E_SOUND_PLAY_SOUND_ON_MOVE()
  

  If world_object()\object_is_player<>0  ;special for player char:
    If player_statistics\player_on_ground=#False
            ProcedureReturn #False
      EndIf
    
  EndIf
  
    
    
  If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
  ProcedureReturn #False 
  EndIf
  
  
  If world_object()\object_play_sound_on_move=#False
  ProcedureReturn #False  
  EndIf
  

  If IsSound(world_object()\object_sound_on_move_id)=0 
      ProcedureReturn #False
  EndIf

  
 If ElapsedMilliseconds()>world_object()\object_sound_on_move_ready_ms Or world_object()\object_first_start=#True
   world_object()\object_sound_on_move_ready_ms=ElapsedMilliseconds()+world_object()\object_sound_on_move_length_ms
   SoundVolume(world_object()\object_sound_on_move_id,world_object()\object_sound_on_move_volume)
PlaySound(world_object()\object_sound_on_move_id)
world_object()\object_first_start=#False

EndIf
 world_object()\object_sound_is_playing=#True

  
  
 EndProcedure
 




Procedure  E_SOUND_PLAY_SOUND_ON_RANDOM()
  
   If IsSound(world_object()\object_sound_on_random_id)=0 Or world_object()\object_play_sound_on_random=#False
    ProcedureReturn #False  
  EndIf
  

   If Random(world_object()\object_sound_play_random)<>1
    ProcedureReturn #False  
  EndIf
  
 
    If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
  ProcedureReturn #False
  EndIf
  
  If ElapsedMilliseconds()>world_object()\object_sound_on_random_ready_ms Or  world_object()\object_first_start=#True
    world_object()\object_sound_on_random_ready_ms=ElapsedMilliseconds()+world_object()\object_sound_on_random_length_ms
    SoundVolume(world_object()\object_sound_on_random_id,world_object()\object_sound_on_random_volume)
    PlaySound(world_object()\object_sound_on_random_id)
    world_object()\object_first_start=#False
    world_object()\object_sound_is_playing=#True
  EndIf
  
  
  
  
EndProcedure




Procedure  E_SOUND_STOP_SOUND_ON_ROTATE()

  
  If IsSound(world_object()\object_sound_on_rotate_id)=0
  ProcedureReturn #False  
  EndIf
  
  StopSound(world_object()\object_sound_on_rotate_id)


  
EndProcedure


Procedure  E_SOUND_PLAY_SOUND_ON_ROTATE()
  
  If world_object()\object_play_sound_on_rotate=#False
  ProcedureReturn #False  
  EndIf
  
  
  If IsSound(world_object()\object_sound_on_rotate_id)=0 
  ProcedureReturn #False  
  EndIf
  
  
  If world_object()\object_sound_is_playing=#True And world_object()\object_play_sound_once=#True
  ProcedureReturn #False 
  EndIf

  If ElapsedMilliseconds()>world_object()\object_sound_on_rotate_ready_ms Or  world_object()\object_first_start=#True
    SoundVolume(world_object()\object_sound_on_rotate_id,world_object()\object_sound_on_rotate_volume)
    PlaySound(world_object()\object_sound_on_rotate_id)
    world_object()\object_first_start=#False
    world_object()\object_sound_is_playing=#True
    world_object()\object_sound_on_rotate_length_ms=SoundLength(world_object()\object_sound_on_rotate_id,#PB_Sound_Millisecond)
    world_object()\object_sound_on_rotate_ready_ms=ElapsedMilliseconds()+world_object()\object_sound_on_rotate_length_ms
  EndIf
  



  
EndProcedure



Procedure  E_SOUND_BUTTON_SOUND_PLAY()
  
  If button_sound\button_sound_active=#False
  ProcedureReturn #False  
  EndIf
  SoundVolume(button_sound\button_sound_id ,e_engine\e_sound_global_volume)
  PlaySound(button_sound\button_sound_id)
  
  EndProcedure
  
  
  

  Procedure E_SOUND_PLAY_SOUND_ON_QUEST_OBJECT()
    ;here we play the special sound if player uses a quest object:
    

    If IsSound(player_statistics\player_sound_on_found_all_quest_objects_id)
      SoundVolume(player_statistics\player_sound_on_found_all_quest_objects_id,e_engine\e_sound_global_volume)
       PlaySound(player_statistics\player_sound_on_found_all_quest_objects_id)
    EndIf

    
  EndProcedure
  
  
    Procedure E_SOUND_PLAY_SOUND_ON_PLAYER_DEAD()
    ;here we play the special sound if player uses a quest object:
    

      If IsSound(player_statistics\player_sound_on_death_id)
        SoundVolume(player_statistics\player_sound_on_death_id,e_engine\e_sound_global_volume)
        PlaySound(player_statistics\player_sound_on_death_id)
          EndIf

    
  EndProcedure




Procedure E_SOUND_CORE_CONTROLLER(_mode.i)
  
  ;here we go for all the object defined sounds, new with 20201227: no value is given, just all new single routines called, handling the action themselfes
  
  If e_show_play_field.b=#False
     ProcedureReturn #False 
  EndIf
  
 If  world_object()\object_is_active=#False
   ProcedureReturn #False
 EndIf
 

;  If world_object()\object_stream_gfx_loaded<>#True  ;changed 12032021
;  ProcedureReturn #False  
;  EndIf
;  

 
 Select _mode.i
     
   Case #ENGINE_PLAY_SOUND_ON_EMIT 
     E_SOUND_PLAY_ON_EMIT()
     
   Case #ENGINE_SOUND_PLAY_ON_ALLERT
     E_SOUND_PLAY_SOUND_ON_ALLERT()
     
   Case #ENGINE_PLAY_SOUND_ON_ACTIVATE
     E_SOUND_PLAY_SOUND_ON_ACTIVATE()
     
     Case #ENGINE_PLAY_SOUND_ON_PLAYER_DEAD
     E_SOUND_PLAY_SOUND_ON_PLAYER_DEAD()
   
   Case  #ENGINE_STOP_SOUND_ON_MOVE
     E_SOUND_STOP_SOUND_ON_MOVE()
     
   Case #ENGINE_PLAY_SOUND_ON_MOVE
     E_SOUND_PLAY_SOUND_ON_MOVE()
     
   Case #ENGINE_PLAY_SOUND_ON_CREATE
     E_SOUND_PLAY_SOUND_ON_CREATION()
     
   Case #ENGINE_PLAY_SOUND_ON_CHILD_CREATE
     E_SOUND_PLAY_SOUND_ON_CHILD_CREATION()
     
   Case #ENGINE_PLAY_SOUND_ON_COLLISION
         E_SOUND_PLAY_SOUND_ON_COLLISION()
     
   Case #ENGINE_PLAY_SOUND_ON_RANDOM
     E_SOUND_PLAY_SOUND_ON_RANDOM()
     
     Case #ENGINE_PLAY_SOUND_ON_ROTATE
     E_SOUND_PLAY_SOUND_ON_ROTATE()
     
   Case #ENGINE_STOP_GLOBAL_SOUND
     E_SOUND_STOP_GLOBAL_SOUND()
     
     Case #ENGINE_PLAY_SOUND_ON_CHANGE
     E_SOUND_PLAY_SOUND_ON_CHANGE()
     
   Case #ENGINE_PLAY_SOUND_ON_TALK
     E_SOUND_PLAY_SOUND_ON_TALK()
     
     
   Case #ENGINE_PLAY_SOUND_GLOBAL
     E_SOUND_PLAY_GLOBAL_SOUND()
     
   Case #ENGINE_STOP_INTERACTIVE_SOUND
     E_SOUND_STOP_SOUND_ON_ROTATE()
     E_SOUND_STOP_SOUND_ON_RANDOM()
     E_SOUND_STOP_SOUND_ON_MOVE()
     E_SOUND_STOP_SOUND_ON_COLLISION()
     E_SOUND_STOP_SOUND_ON_CREATION()
     E_SOUND_STOP_SOUND_ON_CHILD_CREATION()
     E_SOUND_STOP_SOUND_ON_ACTIVATE()
     E_SOUND_STOP_SOUND_ON_ALLERT()
     E_SOUND_STOP_SOUND_ON_TALK()
     E_SOUND_STOP_ON_EMIT()
     
   Case #ENGINE_STOP_ALL_SOUND
     E_SOUND_STOP_SOUND_ON_ROTATE()
     E_SOUND_STOP_SOUND_ON_RANDOM()
     E_SOUND_STOP_SOUND_ON_MOVE()
     E_SOUND_STOP_SOUND_ON_COLLISION()
     E_SOUND_STOP_SOUND_ON_CREATION()
     E_SOUND_STOP_SOUND_ON_CHILD_CREATION()
     E_SOUND_STOP_SOUND_ON_ACTIVATE()
     E_SOUND_STOP_SOUND_ON_ALLERT()
     E_SOUND_STOP_BOSS_MUSIC()
     E_SOUND_STOP_SOUND_ON_TALK()
     E_SOUND_STOP_GLOBAL_SOUND()
     E_SOUND_STOP_ON_EMIT()
     
 EndSelect
 
 
 
 ;here we go
  
EndProcedure

; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 23
; Folding = -
; EnableXP
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant