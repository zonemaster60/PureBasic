;here we have gameplay relevant actions:

Declare   E_SAVE_RESPAWN_WORLD(str.s) 
Declare   E_CHECK_FOR_RESPAWN_AREA()

Declare   E_CLEAN_UP_SINGLE_INVENTORY_OBJECT()
Declare   E_QUICK_SAVE()
Declare   E_STREAM_LOAD_SPRITE(_void.i)
Declare   E_GRAB_SRC_SCREEN()
Declare   E_LEVEL_UP_EFFECT()






         


Procedure E_SOUND_PLAYER_ACTION(_value.i)

  
  Select  _value.i
      
    Case #PLAYER_ALL_GEMS
      
      If IsSound(player_statistics\player_sound_on_found_all_quest_objects_id)
        PlaySound(player_statistics\player_sound_on_found_all_quest_objects_id ,#PB_Sound_MultiChannel ,100)  ; actual the volume is hardcoded, need to update scriptfile for script based volume
      EndIf
      
    Case #PLAYER_DEATH
      
    Case #PLAYER_LEVEL_UP
      
       If IsSound( player_statistics\player_sound_on_level_up_id)
        PlaySound( player_statistics\player_sound_on_level_up_id ,#PB_Sound_MultiChannel ,100)  ; actual the volume is hardcoded, need to update scriptfile for script based volume
      EndIf
      
    Case #PLAYER_WINS
     
      If  IsSound(e_engine\e_global_sound_id)
           StopSound(e_engine\e_global_sound_id)  
      EndIf
      
      If IsSound(player_statistics\player_sound_on_win_id)
          PlaySound(player_statistics\player_sound_on_win_id,#PB_Sound_MultiChannel ,100)  
      EndIf
      
      
    Case #PLAYER_PICK_UP_ITEM
      
      If IsSound(player_statistics\player_sound_on_item_pic_up_id)
          PlaySound(player_statistics\player_sound_on_item_pic_up_id,#PB_Sound_MultiChannel,100)  
      EndIf
      
    Case #PLAYER_SHIELD_UP
     ;sound only in fight, so we have acustic info of shield status
       If IsSound(player_statistics\player_sound_on_shield_power_up_id)
          PlaySound(player_statistics\player_sound_on_shield_power_up_id,#PB_Sound_MultiChannel,100)
        EndIf
        
      
      
    Default
      
      
  EndSelect
  
EndProcedure





Procedure E_SET_NEW_AXE_SPEED_MAX()
;   ;set max axe speed +1 every 10 level steps. 
;   
;   If player_statistics\player_level<1
;   ProcedureReturn #False  
;   EndIf
;   
;   
;   If (Int(player_statistics\player_level/10)-(player_statistics\player_level/10))<>0
;     ProcedureReturn #False
;   EndIf
;   
;   player_statistics\player_axe_speed_max+1
  
EndProcedure 
















; IDE Options = PureBasic 5.73 LTS (Windows - x64)
; CursorPosition = 98
; FirstLine = 82
; Folding = ---
; EnableXP
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant