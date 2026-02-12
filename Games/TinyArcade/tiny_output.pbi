Procedure T_SOUND_GLOBAL()
  
  If IsSound(tiny_game_logic\tiny_background_song_id)=0
  ProcedureReturn #False ;nothing!  
  EndIf

  PlaySound(tiny_game_logic\tiny_background_song_id,#PB_Sound_Loop|#PB_Sound_MultiChannel,50)
  
EndProcedure


Procedure T_SOUND_PLAYER()
  
  If IsSound(tiny_game_logic\tiny_player_move_sound_id)=0
  ProcedureReturn #False  ;nothing!  
  EndIf
  
  PlaySound(tiny_game_logic\tiny_player_move_sound_id,#PB_Sound_MultiChannel,50)
  
EndProcedure






Procedure T_ARCADE_FRAME()
  
  ;draw the arcade deco frame:

   
  If IsImage(tiny_screen_objects\tiny_arcade_frame_id)=0
  ProcedureReturn #False ;silent  
  EndIf
  
  
  StartDrawing(WindowOutput(tiny_window\window_id))
   DrawingMode(#PB_2DDrawing_AllChannels)
  
  DrawImage(ImageID(tiny_screen_objects\tiny_arcade_frame_id),0,0)
  
  StopDrawing()
  
  
EndProcedure

Procedure T_DISPLAY_OUTPUT()
  ;here we go for the display of our tiny arcade engine
  
  Define i.i=0
  
  
  



 
  If tiny_game_mode.i=#GAME_OWER
    If IsSprite(tiny_screen_objects\tiny_game_over_gfx_id)
   DisplayTransparentSprite(tiny_screen_objects\tiny_game_over_gfx_id,0,0,255,RGB(5,5,5))
 EndIf
ProcedureReturn #False    
EndIf
  
  If IsSprite(tiny_screen_objects\tiny_back_ground_0_id)
  DisplayTransparentSprite(tiny_screen_objects\tiny_back_ground_0_id,0,0,200)  
EndIf

  If IsSprite(tiny_screen_objects\tiny_back_ground_1_id)
  DisplayTransparentSprite(tiny_screen_objects\tiny_back_ground_1_id,0,0,255)  
EndIf

If IsSprite(tiny_screen_objects\tiny_game_logic_gfx_id)
     DisplayTransparentSprite(tiny_screen_objects\tiny_game_logic_gfx_id,0,0,255)
EndIf

If IsSprite(tiny_game_logic\tiny_player_life_gfx_id)
  DisplayTransparentSprite(tiny_game_logic\tiny_player_life_gfx_id,400,8,255,RGB(5,5,5))
  EndIf

If IsSprite(tiny_game_logic\tiny_player_object_id)
DisplayTransparentSprite(tiny_game_logic\tiny_player_object_id,tiny_game_logic\tiny_player_object_pos_x,tiny_game_logic\tiny_player_object_pos_y,255,RGB(5,5,5))  
EndIf

If IsSprite(tiny_game_logic\tiny_object_to_rescue_id)
DisplayTransparentSprite(tiny_game_logic\tiny_object_to_rescue_id,tiny_game_logic\tiny_object_to_rescue_pos_x,tiny_game_logic\tiny_object_to_rescue_pos_y,255,RGB(5,5,5))  
EndIf


For i.i=0 To tiny_game_logic\tiny_obstacle_max
  
  If IsSprite(tiny_game_logic\tiny_obstacle_id[i.i])
    DisplayTransparentSprite(tiny_game_logic\tiny_obstacle_id[i.i],tiny_game_logic\tiny_obstacle_pos_x[i.i],tiny_game_logic\tiny_obstacle_pos_y[i.i],255,RGB(5,5,5))
  EndIf
 
  
Next



If tiny_game_mode=#GAME_PAUSE
  If IsSprite(tiny_screen_objects\tiny_pause_gfx_id)
DisplayTransparentSprite(tiny_screen_objects\tiny_pause_gfx_id,0,0,255,RGB(5,5,5))  
EndIf
EndIf






  
  EndProcedure
  
  
  Procedure T_TEXT()
    ;textoutput 
    StartDrawing(ScreenOutput())
    DrawingMode(#PB_2DDrawing_Transparent )
    DrawText(8,8,"SCORE "+Str(tiny_game_logic\tiny_player_score),RGB(5,5,5),RGB(5,5,5))
    DrawText(200,8,"HIGH "+Str(tiny_game_logic\tiny_player_score_top),RGB(5,5,5),RGB(5,5,5))
    DrawText(416,8,Str(tiny_game_logic\tiny_player_lifes),RGB(5,5,5),RGB(5,5,5))
    StopDrawing()
  EndProcedure
  
  
  
Procedure T_GAME_SCREEN()
  ;refresh and draw!
  
  
  ClearScreen(RGB(180,200,180))
  T_DISPLAY_OUTPUT()
  T_TEXT()
  FlipBuffers()
  
EndProcedure


