
Declare  T_RESPAWN_ENEMY(_void.i)
;check some collisions
Procedure T_COLLISION_PLAYER()
  ;check the player object:
  
  If SpriteCollision(tiny_game_logic\tiny_player_object_id,tiny_game_logic\tiny_player_object_pos_x,tiny_game_logic\tiny_player_object_pos_y,tiny_game_logic\tiny_object_to_rescue_id,tiny_game_logic\tiny_object_to_rescue_pos_x,tiny_game_logic\tiny_object_to_rescue_pos_y)=0
    ProcedureReturn #False  
  EndIf
  
  ;collision:
  tiny_game_logic\tiny_object_to_rescue_bound_to_player=#True
  
  
EndProcedure

Procedure T_COLLISION_FOE()
  ;check if there is player foe collision:
  
  Define i.i=0
  
  For i.i=0 To tiny_game_logic\tiny_obstacle_max
    
    If SpriteCollision(tiny_game_logic\tiny_player_object_id,tiny_game_logic\tiny_player_object_pos_x,tiny_game_logic\tiny_player_object_pos_y,tiny_game_logic\tiny_obstacle_id[i.i],tiny_game_logic\tiny_obstacle_pos_x[i.i],tiny_game_logic\tiny_obstacle_pos_y[i.i])
      tiny_game_logic\tiny_player_lifes-1
       If IsSound(tiny_game_logic\tiny_object_to_rescue_dead_sound_id)
    
    PlaySound(tiny_game_logic\tiny_object_to_rescue_dead_sound_id,#PB_Sound_MultiChannel,50)  
  EndIf
  If tiny_game_logic\tiny_object_to_rescue_bound_to_player=#True
  tiny_game_logic\tiny_object_to_rescue_pos_x=Random(ScreenWidth()-64)+32
  tiny_game_logic\tiny_object_to_rescue_bound_to_player=#False  
  tiny_game_logic\tiny_object_to_rescue_pos_y=tiny_game_logic\tiny_object_to_rescue_default_pos_y
EndIf

      T_RESPAWN_ENEMY(i.i)
    EndIf
  Next
  
  
EndProcedure

