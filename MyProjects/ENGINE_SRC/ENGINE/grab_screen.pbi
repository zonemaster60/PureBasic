;here we have some routines to grab screen ...






Procedure E_GRAB_SRC_SCREEN()
  ;we grab the screen of the map we walk out
  
  If grab_screen\screen_is_active=#True
  ProcedureReturn #False  
  EndIf
  

  If IsSprite(grab_screen\screen_src_id)  ;start with clean memory
  FreeSprite(grab_screen\screen_src_id)  
  EndIf
  
  grab_screen\screen_src_id=GrabSprite(#PB_Any,0,0,e_engine\e_engine_internal_screen_w,e_engine\e_engine_internal_screen_h,#PB_Sprite_AlphaBlending)
  grab_screen\screen_src_transparency=255
 
  
  
EndProcedure



Procedure E_SHOW_GRABBED_SCREEN()
  
  
   If IsSprite(grab_screen\screen_src_id)
     DisplayTransparentSprite(grab_screen\screen_src_id,0,0,grab_screen\screen_src_transparency)
     grab_screen\screen_is_active=#True
  EndIf
  
  
  grab_screen\screen_src_transparency-grab_screen\screen_transparency_change_speed
  If grab_screen\screen_src_transparency<1
    grab_screen\screen_src_transparency=0  ;valid value  
    grab_screen\screen_is_active=#False

  EndIf
  
 
  ProcedureReturn grab_screen\screen_src_transparency
  
  
EndProcedure






