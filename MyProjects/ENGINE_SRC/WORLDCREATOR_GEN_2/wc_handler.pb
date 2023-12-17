;handler for all i/o

Declare WC_RESTART()
Declare WC_SHOW_MAIN_SCREEN()
Declare WC_DELETE_MAP_OBJECT()
Declare WC_INFO()
Declare WC_ADD_MAP_OBJECT(_mode.l)
Declare WC_EVENT(v_event.l)
Declare WC_CLEAR_SCREEN()
Declare WC_SHOW_SCREEN_BUFFER()
Declare WC_MAP_USE_RESPAWN_NO()
Declare WC_MAP_USE_RESPAWN_YES()

Procedure E_GET_PACK_GFX_AND_CONVERT_DISTI(_gfx.s)
    ;encode the gfx (single gfx given by engine)
    
EndProcedure

Procedure E_GET_PACK_GFX_AND_REBUILD_DISTI(_gfx.s)
   ;try to rebuild corrupted gfx (some kind of copy protection...)
    
EndProcedure

Procedure WC_TEMPLATE_HIDE()
  If  wc_template\is_valid=#True
    wc_template\transparency=10
     EndIf  
EndProcedure

Procedure WC_MAP_INFO()
  Define _info_text.s=""
  Define _yes_no.s="NO"
  Define _show_info.s="NO"
  
  If wc_map_day_timer.b=#True
    _yes_no.s="YES"
  EndIf
  
  If wc_map_show_version_info=#True
    _show_info.s="YES"
  EndIf 
  
  _info_text.s="OBJECTS: "+Str(ListSize(map_object()) )+Chr(13)+"MAP CAN PAUSE: "+wc_map_can_pause.s+Chr(13)+"MAP USE RESPAWN: "+wc_map_use_respawn.s+Chr(13)+"MAP GLOBAL SONG: "+wc_full_sound_path.s+Chr(13)+"MAP USE QUEST SYSTEM "+Str(wc_map_use_quest_system.b)+Chr(13)
  _info_text.s+"MAP FIGHT:"+wc_map_fight_text.s+Chr(13)+"MAP USE DAYTIMER:"+_yes_no.s+Chr(13)+"MAP IS ARENA: "+wc_map_is_arena_text.s+Chr(13)
  _info_text.s+"MAP SHOW VERSION INFO: "+_show_info.s+Chr(13)+"MAP AUTO SWITCH TIMER: "+Str(wc_map_timer_switch.l)+Chr(13)
  _info_text.s+"SWITCH TO MAP: "+wc_switch_map_name.s+Chr(13)+"SWITCH MAP ON TRIGGER: "+Str(wc_map_switch_on_trigger.b)+Chr(13)
  _info_text.s+"MAP SCROLL: "+wc_scroll_yes_no.s+Chr(13)
  _info_text.s+"MAP GLOBAL EFFECT: "+wc_global_effect_info_text.s+Chr(13)
  _info_text.s+"MAP SOUNDTRACK: "+wc_sound_path.s
  
  ;------------------------------------ WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO 
Define _ok.l=0 ;for first start warning !!!!! to make shure user reads the info
_ok.l=MessageRequester("  WORLDCREATOR BUILD "+Str(#PB_Editor_BuildCount),Chr(13)+_info_text.s,#PB_MessageRequester_Info)
;----------------------------------- WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO  WARNING  INFO  WARNING INFO 

EndProcedure

Procedure WC_MAP_GO_TO_START()
  
  wc_x_offset.i=wc_x_origin.i
  wc_y_offset.i=wc_y_origin.i
  
EndProcedure

Procedure WC_OPEN_ASSET_GFX_RESOURCE()
  
  If RunProgram("explorer.exe", v_resource_path.s, "")
  
  EndIf
    
EndProcedure

Procedure WC_OPEN_ASSET_SOUND_RESOURCE()
  
  If RunProgram("explorer.exe", v_resource_path_sound.s, "")
  
  EndIf
  
EndProcedure

Procedure WC_TEMPLATE_TRANSPARENCY_REMOVE()
  
  If  wc_template\is_valid=#True
    wc_template\transparency+10
    If wc_template\transparency>255
      wc_template\transparency=255
    EndIf
  EndIf
  
EndProcedure

Procedure WC_TEMPLATE_TRANSPARENCY_ADD()
  If  wc_template\is_valid=#True
    wc_template\transparency-10
    If wc_template\transparency<0
      wc_template\transparency=0
    EndIf
  EndIf  
EndProcedure

Procedure WC_LOAD_TEMPLATE_GFX(_path.s)
  
  If IsSprite(wc_template\id)
    FreeSprite(wc_template\id)  
    wc_template\is_valid=#False
  EndIf
  
  wc_template\id=LoadSprite(#PB_Any,_path.s,#PB_Sprite_AlphaBlending)
  If IsSprite(wc_template\id)
    wc_template\is_valid=#True
    wc_template\transparency=255
  Else
    wc_template\is_valid=#False
  EndIf
    
  EndProcedure

Procedure WC_LOAD_TEMPLATE()
  ;here we load the template to help building the map :
  ;you can use gfx as template and 
  Define _ok.l=0
Static _path.s=""
 _path.s= OpenFileRequester("LOAD MAP TEMPLATE",_path.s,"*",0)
  WC_LOAD_TEMPLATE_GFX(_path.s)
  
  EndProcedure

Procedure WC_SET_PROCEDURAL_WORK_GFX()
  
  If SelectElement(wc_menu_object(),ListIndex(wc_menu_object()))
        wc_work_gfx\_gfx_path=wc_menu_object()\_gfx_path
        wc_work_gfx\_ai_path=wc_menu_object()\_ai_path
        If IsSprite(wc_work_gfx\_gfx_id)
        FreeSprite(wc_work_gfx\_gfx_id)  
        EndIf
        
        wc_work_gfx\_gfx_id=LoadSprite(#PB_Any,wc_work_gfx\_gfx_path,#PB_Sprite_AlphaBlending)
        wc_work_with.f=SpriteWidth(wc_work_gfx\_gfx_id)
        wc_work_height.f=SpriteHeight(wc_work_gfx\_gfx_id)
        wc_work_gfx\_full_screen=wc_menu_object()\_full_screen
        wc_work_gfx\_raster_x=wc_work_with.f
        wc_work_gfx\_raster_y=wc_work_height.f
        wc_work_gfx\_transparency=255-wc_menu_object()\_transparency
        wc_work_gfx\_object_auto_layer=wc_menu_object()\_object_auto_layer

        wc_work_gfx\object_shadow_intense=wc_menu_object()\object_shadow_intense
             
      EndIf
  
  EndProcedure

Procedure  WC_CLEAN_CACHE( v_clean_cache_on_exit.b)
  
  If v_clean_cache_on_exit.b=#True
        DeleteDirectory(v_cache_dir.s,"")
  EndIf
  
EndProcedure

Procedure WC_GARBAGE_COLLECTOR()
  ;here we set all to start:
  
  ResetList(map_object())
  
  While NextElement(map_object())
    If IsSprite(map_object()\_gfx_id)
            FreeSprite(map_object()\_gfx_id)  ;we need to free the sprite memory bevore we free the list, because sprite(gfx) data is not released with FreeList()
          EndIf
                  
  DeleteElement(map_object())
  Wend
  
    ResetList(map_object())
  
    WC_CLEAR_SCREEN()
    WC_SHOW_SCREEN_BUFFER()
 
EndProcedure

Procedure WC_GET_MAP_GFX()
  ;this routine is used for gfx load only, it is part of WC_LOAD_MAP_PARSER()  
  
  Define _ok.i=0
  Define _key.s=""
  Define _val.l=0
  Define _dummy.l=0
  Define _find.l=0
  
  Define _file_name.s=""
  Define _file_extension.s=""
  
  Define _count.l=0
    
  If ListSize(map_object())<1
  ProcedureReturn #False  
  EndIf
  
  If IsSprite(map_object()\_gfx_id)
  ProcedureReturn  
  EndIf
  
  ResetList(map_object())
  
  While NextElement(map_object())
   
_dummy.l=WindowEvent()
    ;here we use a simple eventhandling, so we get no  false: no response info,
    map_object()\_transparency=255 
    _ok.i=ReadFile(#PB_Any,v_resource_path+map_object()\_ai_path)
    
    If IsFile(_ok.i)
      
      map_object()\_DO_NOT_SHOW=#False
      
      ;now parse for the gfx:
          
      _file_extension.s=""
      _file_name.s=""
     
      While Not Eof(_ok.i)
        
        _key.s=ReadString(_ok.i)
        
        _find.l=FindString(_key.s,".")
        
        If _find.l>0
        _key.s=Left(_key.s,_find.l-1)  
        EndIf
               
        Select _key.s
            
          Case "object_file#"
            
            _file_name.s=ReadString(_ok.i)
                
          Case "object_type#"
            
            _file_extension.s=ReadString(_ok.i)
              
          Case "object_full_screen"
            
            _val.l=Val(ReadString(_ok.i))
            
            If _val.l=1
              
              map_object()\_full_screen=#True
              If IsSprite(map_object()\_gfx_id)
              ZoomSprite(map_object()\_gfx_id,wc_engine_screen_width,wc_engine_screen_height)
              EndIf
            Else
              
              map_object()\_full_screen=#False
                           
            EndIf
            
          Case "object_transparency"
            map_object()\_transparency=255-Val(ReadString(_ok.i))
            
          Case "object_auto_layer"
            map_object()\_object_auto_layer=Val(ReadString(_ok.i))
            
          Case "DO_NOT_SAVE_THIS_OBJECT" ; ::::: INTERNAL USE ONLY ::::::::: if #true, object will no longer saved as  part of the map, use it if you want to remove a huge ammont of obsolete gfx from the map (to remove object:set value, at the object data in the  AI42Creator)
            map_object()\_DO_NOT_SAVE_THIS_OBJECT=Val(ReadString(_ok.i))

          Case "object_NPC_text_path"
            map_object()\object_NPC_text_path=ReadString(_ok.i)
            
          Case "object_NPC_show_text_on_collision"
            map_object()\object_NPC_show_text_on_collision=Val(ReadString(_ok.i))
            
          Case "object_NPC_internal_name"
            map_object()\object_NPC_internal_name=ReadString(_ok.i)
                      
          Case "object_transparency"
            map_object()\object_transparency=255-Val(ReadString(_ok.i))
            
          Case "object_is_procedural_base"
            map_object()\object_is_procedural_base=Val(ReadString(_ok.i))
            If map_object()\object_is_procedural_base>0
              map_object()\object_procedural_done=#False  
            EndIf
            
          Case "object_procedural_source_name"
            map_object()\object_procedural_source_name=ReadString(_ok.i)
            
          Case "object_procedural_max_objects"
            map_object()\object_procedural_max_objects=Val(ReadString(_ok.i))
            
          Case "object_procedural_x_offset"
            map_object()\object_procedural_x_offset=ValF(ReadString(_ok.i))
          Case "object_procedural_y_offset"
            map_object()\object_procedural_y_offset=ValF(ReadString(_ok.i))
            
          Case "object_procedural_seed"
            map_object()\object_procedural_seed=Val(ReadString(_ok.i)) 
            
          Case "object_use_random_angle"
            map_object()\object_use_random_angle=ValF(ReadString(_ok.i))
            If IsSprite(map_object()\_gfx_id)
            RotateSprite(map_object()\_gfx_id,Random(map_object()\object_use_random_angle),#PB_Absolute)
          EndIf
          
          Case "object_use_shadow"
            map_object()\object_use_shadow=Val(ReadString(_ok.i))
            
          Case "object_shadow_intense"
            map_object()\object_shadow_intense=Val(ReadString(_ok.i))          
            
          Case "object_add_to_quest"
            map_object()\object_add_to_quest=Val(ReadString(_ok.i))
            
            If map_object()\object_add_to_quest<>0
              wc_quest_book.l+1  
            EndIf
                      
          Case "object_gfx_h"
            map_object()\object_gfx_h=ValF(ReadString(_ok.i))
                        
          Case "object_gfx_w"
            map_object()\object_gfx_w=ValF(ReadString(_ok.i))
            
          Case "object_gfx_set_w_h"
            map_object()\object_gfx_set_w_h=Val(ReadString(_ok.i))           
                       
        EndSelect        
       
      Wend
       E_GET_PACK_GFX_AND_REBUILD_DISTI(v_resource_path+_file_name.s+"."+_file_extension.s)
      map_object()\_gfx_id=LoadSprite(#PB_Any,v_resource_path+_file_name.s+"."+_file_extension.s, #PB_Sprite_AlphaBlending ); we have to set a relative path for the file, because we use a resourcefile for source so we can use it.
            E_GET_PACK_GFX_AND_CONVERT_DISTI(v_resource_path+_file_name.s+"."+_file_extension.s)
        If IsSprite(map_object()\_gfx_id)
                    
           If map_object()\object_gfx_set_w_h=#True And map_object()\object_gfx_w>0 And map_object()\object_gfx_h>0
           ZoomSprite(map_object()\_gfx_id,map_object()\object_gfx_w,map_object()\object_gfx_h)  
           EndIf
                     
            Else
              
              map_object()\_DO_NOT_SAVE_THIS_OBJECT=#True
              
              If wc_ignore_map_error.b=#False
                WC_ERROR(#WC_ERROR_CAN_NOT_CREATE_OBJECT,"CAN NOT LOAD GFX, "+v_resource_path+"   "+_key.s) 
                
              EndIf
                          
            EndIf
      
      CloseFile(_ok.i)
      
    Else
      
      map_object()\_DO_NOT_SAVE_THIS_OBJECT=#True  ;if object or AI42 file is not valid, exclude it from save to the map
      
      If wc_ignore_map_error.b=#False
        WC_ERROR(#WC_ERROR_CAN_NOT_CREATE_OBJECT,"CAN ONT LOAD GFX, "+v_resource_path+map_object()\_ai_path)
      EndIf     
      
    EndIf
       
  Wend
  
EndProcedure

Procedure  WC_GET_MAP_VIEW_SIZE(_file_id.i,_key.s)
  ;here we read the map viepoints (w x h)
  
  _key.s=RTrim(_key.s," ")
  
  Select _key.s
    Case "WORLD_VIEW_W"
      wc_engine_screen_width.f=ValF(ReadString(_file_id.i))
      
    Case "WORLD_VIEW_H"
      wc_engine_screen_height.f=ValF(ReadString(_file_id.i))
      
    Case "MAP OBJECTS:"
      wc_objects_in_map.i=Val(ReadString(_file_id.i))
      
  EndSelect
  
EndProcedure

Procedure WC_LOAD_MAP_PARSER(_file_id.i,_file.s)
  
  Define _x.l=0
  Define _y.l=0
  Define _object_path.s=""
  Define _layer.b=0
  Define _key.s=""
              
 ;--------------------------------------------- 
  Repeat  
   
    _key.s=ReadString(_file_id.i)
     WC_GET_MAP_VIEW_SIZE(_file_id.i,_key.s)
      
   Until  Eof(_file_id.i) Or _key.s="WORLD_START:"
     
   If Eof(_file_id.i)
   ProcedureReturn #False  
   EndIf
   
   wc_map_show_gui.b=#True
   wc_global_effect.i=#WC_GLOBAL_EFFECT_NONE
   wc_global_effect_info_text.s=""
   wc_map_use_black_stamp.b=#False
  ;we got it? 
    
     While Not Eof(_file_id.i)
        
        SetWindowTitle(v_window_parent_id,"Loading Map: "+ _file.s +"   ***   Objects: "+Str(wc_objects_in_map.i)+ "  Done: "+Str(ListSize(map_object())))
   
        _key.s=Trim(ReadString(_file_id.i))
       
        Select _key.s
                     
          Case "WORLD_GLOBAL_EFFECT"
            Select ReadString(_file_id.i)
                
              Case "WINTER"
                
                    wc_global_effect.i=#WC_GLOBAL_EFFECT_SNOW
                    SetMenuItemState(v_menu_id.i,#WC_MENU_GLOBAL_EFFECT_SNOW,#True)
                    SetMenuItemState(v_menu_id.i,#WC_MENU_NO_GLOBAL_EFFECT,0)
                    wc_global_effect_info_text.s="WINTER"
                EndSelect
                
              Case "WORLD_SHOW_SCROLL_TEXT"
                If Val(ReadString(_file_id.i))>0
                  wc_map_show_scroll_text.b=#True
                   SetMenuItemState(v_menu_id.i,#WC_MENU_SHOW_SCROLL_TEXT,#True)
                Else
                  wc_map_show_scroll_text.b=#False
                  SetMenuItemState(v_menu_id.i,#WC_MENU_SHOW_SCROLL_TEXT,0)
                EndIf
                            
          Case "SCROLL"
            
            If Val(ReadString(_file_id.i))>0
              wc_scroll_yes_no.s="YES"  
              wc_scroll.b=#True
                 SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_SCROLL,#True)
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_NO_SCROLL,0)
            Else
              wc_scroll_yes_no.s="NO"
              wc_scroll.b=#False
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_SCROLL,0)
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_NO_SCROLL,#True)
            EndIf
                        
          Case "WORLD_GLOBAL_SOUND"
            
            wc_full_sound_path.s=Trim(ReadString(_file_id.i))
            wc_full_sound_path.s=v_resource_path_sound.s+GetFilePart(wc_full_sound_path.s)
         
            If IsSound(wc_sound_id.i)
              wc_sound_ok=#True
            Else
              wc_sound_ok=#False
            EndIf
                       
          Case "SHOW_VERSION_INFO"
            
            Select Val(ReadString(_file_id.i))
                             
              Case 1
                wc_map_show_version_info.b=#True
                
                SetMenuItemState(v_menu_id.i,#WC_SHOW_VERSION_YES,#True)
                SetMenuItemState(v_menu_id.i,#WC_SHOW_VERSION_NO,0)
                
              Default
                wc_map_show_version_info.b=#False
                SetMenuItemState(v_menu_id.i,#WC_SHOW_VERSION_YES,0)
                SetMenuItemState(v_menu_id.i,#WC_SHOW_VERSION_NO,#True)
                
            EndSelect
                       
          Case "MAP_USE_BLACK_STAMP"
            
            Select Val(ReadString(_file_id.i))
              Case #True
                  SetMenuItemState(v_menu_id.i,#WC_MAP_USE_VIEW_STAMP,#True)
                  SetMenuItemState(v_menu_id.i,#WC_MAP_DO_NOT_USE_VIEW_STAMP,0)
                  wc_map_use_black_stamp.b=#True
                  
                Default
                  SetMenuItemState(v_menu_id.i,#WC_MAP_USE_VIEW_STAMP,0)
                  SetMenuItemState(v_menu_id.i,#WC_MAP_DO_NOT_USE_VIEW_STAMP,#True)
                  wc_map_use_black_stamp.b=#False
            EndSelect         
            
          Case "MAP_AUTO_SWITCH_TIMER"
            wc_map_timer_switch.l=Val(ReadString(_file_id.i))
            
   Select wc_map_timer_switch.l
                
     Case 1000
                  
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,#True)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
                
Case 2000
    
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,#True)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
    SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
                
Case 3000
    
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,#True)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
  
Case 5000
    
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,#True)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
  
Case 10000
    
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,#True)
        
Default
                                
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,#True)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
                                
EndSelect
            
          Case "MAP_SHOW_TIMER"
            
            If Val(ReadString(_file_id.i))>0
              wc_show_timer.b=#True
              SetMenuItemState(v_menu_id.i,#WC_MAP_SHOW_TIMER,#True)
              SetMenuItemState(v_menu_id.i,#WC_MAP_SHOW_TIMER_NOT,0)
            Else
              wc_show_timer.b=#False
              SetMenuItemState(v_menu_id.i,#WC_MAP_SHOW_TIMER,0)
              SetMenuItemState(v_menu_id.i,#WC_MAP_SHOW_TIMER_NOT,#False)
            EndIf          
            
           Case "SWITCH_MAP"
            wc_switch_map_name.s=Trim(ReadString(_file_id.i))
            
          Case "SWITCH_MAP_ON_TRIGGER"
            
            If Val(ReadString(_file_id.i))>0
              SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
              SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
              SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
              SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
              SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
              SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
              SetMenuItemState(v_menu_id,#WC_TIMER_SWITCH_MAP_ON_TRIGGER,#True)
              wc_map_switch_on_trigger.b=#True
            EndIf
            
          Case "MAP_IS_ARENA"
                  
            Select  Trim(ReadString(_file_id.i))
                                
              Case "YES"
              wc_map_is_arena_text.s="YES" 
              WC_MAP_USE_RESPAWN_NO()
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_IS_ARENA_YES,#True)
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_IS_ARENA_NO,0)
                
              Default
                wc_map_is_arena_text.s="NO" ;default: (make shure we start with a valid value)
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_IS_ARENA_YES,0)
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_IS_ARENA_NO,#True)
               
            EndSelect          
            
          Case "MAP_FIGHT"
            wc_map_fight_text.s=Trim(ReadString(_file_id.i))
            
            Select wc_map_fight_text.s
                
              Case "YES"
                wc_map_fight.b=#True
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_FIGHT,#True)
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_NO_FIGHT,0)
              Case "NO"
                wc_map_fight.b=#False 
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_FIGHT,0)
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_NO_FIGHT,#True)
                
              Default
                wc_map_fight.b=#True
                wc_map_fight_text.s="YES"
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_FIGHT,#True)
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_NO_FIGHT,0)
                
            EndSelect
                      
          Case "MAP_CAN_PAUSE"
          
            Select Trim(ReadString(_file_id.i))
                
                Case "NO"
              wc_map_can_pause_id.b=#False
              wc_map_can_pause.s="NO"
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_PAUSE_NO,#True)
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_PAUSE_YES,0)
                                   
          Default
            
              wc_map_can_pause_id.b=#True
              wc_map_can_pause.s="YES"
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_PAUSE_NO,0)
              SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_PAUSE_YES,#True)
                                   
          EndSelect
            
          Case "MAP_DAY_TIMER"
               
            If Val(ReadString(_file_id.i))<1
              wc_map_day_timer.b=#False 
              SetMenuItemState(v_menu_id.i,#WC_MENU_DAYTIMER_OFF,#True)
              SetMenuItemState(v_menu_id.i,#WC_MENU_DAYTIMER_ON,0)
    
            EndIf
                 
          Case "MAP_USE_RESPAWN"
                    
            Select Trim(ReadString(_file_id.i))
                
              Case "NO"
                WC_MAP_USE_RESPAWN_NO()
              Case "YES"
                WC_MAP_USE_RESPAWN_YES()
            EndSelect
                    
          Case "MAP_USE_QUEST_SYSTEM"
            
            Select Val(ReadString(_file_id.i))
                
              Case #True
                wc_map_use_quest_system.b=#True
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_QUEST_SYSTEM_NO,0)
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_QUEST_SYSTEM_YES,#True)
                
              Default
                
                  wc_map_use_quest_system.b=#False
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_QUEST_SYSTEM_NO,#True)
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_QUEST_SYSTEM_YES,0)
                             
            EndSelect
                        
          Case "USE_AUTO_LAYER"
            
            If Trim(ReadString(_file_id.i))="YES"
              
              wc_use_auto_layer.b=#True
              wc_auto_object.s="*************    AUTO LAYER   ***********"
            
            Else
              wc_use_auto_layer.b=#False
              wc_auto_object.s="*************NO   AUTO LAYER ***********"
                         
            EndIf
                     
          Case "MAP_SHOW_GUI"
            
            Select Val(ReadString(_file_id.i))
                
              Case #True
                wc_map_show_gui.b=#True
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_OFF,0)
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_ON,#True)
                
              Case #False
                wc_map_show_gui.b=#False
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_OFF,#True)
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_ON,0)
                
              Default
                wc_map_show_gui.b=#True
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_OFF,0)
                SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_ON,#True)
                
            EndSelect
                       
          Case "OFFSETX:"
            wc_x_offset.i=Val(ReadString(_file_id.i))
            
          Case "OFFSETY:"
             wc_y_offset.i=Val(ReadString(_file_id.i))
            
          Case "NEXTELEMENT:"
                       
            If AddElement(map_object())
                          
              _key.s=Trim(ReadString(_file_id.i))
                         
              If _key.s="OBJECTSOURCE:"
                  
                map_object()\_ai_path=Trim(ReadString(_file_id.i))
                                       
              EndIf
           
              _key.s=Trim(ReadString(_file_id.i))
              
             If  _key.s="OBJECT_X:"
              map_object()\_x=ValF(ReadString(_file_id.i))
             EndIf
                                  
              _key.s=Trim(ReadString(_file_id.i))
              
             If  _key.s="OBJECT_Y:"
               map_object()\_y=ValF(ReadString(_file_id.i))
             EndIf
                       
             _key.s=Trim(ReadString(_file_id.i))
             
             If _key.s="OBJECTLAYER:"
               
               map_object()\_layer=Val(ReadString(_file_id.i))
               
             EndIf
             
            Else
              
              WC_ERROR(#WC_ERROR_CAN_NOT_ADD_OBJECT,"CAN NOT ADD ELEMENT, CONTINUE?")
              
            EndIf        
    
        EndSelect
  
      Wend
      
   SetWindowTitle(v_window_parent_id,"Loading Map: "+ _file.s +"   ***   Objects: "+Str(wc_objects_in_map.i)+ "  Done: "+Str(ListSize(map_object()))+"   BUILDING MAP.....")     
   WC_GET_MAP_GFX()
   WC_MAP_INFO()
   wc_x_origin.i=wc_x_offset.i
   wc_y_origin.i=wc_y_offset.i
 EndProcedure

Procedure  WC_GET_MOUSE_DESKTOP()
  ;here we get the mouse position all over the system
  ;so we can handle the mouse pointer and window focus all over the system
  
  v_mouse_desktop_x.f=MouseX()
  v_mouse_desktop_y.f=MouseY()
  
  
  If v_mouse_desktop_x.f<v_window_w.f
    
    If v_mouse_desktop_x.f>v_window_main_x.f
       
  EndIf
  
  If v_mouse_desktop_y.f<v_window_h.f
    
    If v_mouse_desktop_y>v_window_main_y.f
      
      SetActiveWindow(v_window_parent_id)
     
    EndIf
       
  EndIf
  
EndIf

EndProcedure  

Procedure WC_SET_GRID_MOVE()
  
  ;not implemented!!!! does not work!!!
  wc_object_size\height=0
  wc_object_size\width=0
  
  If IsSprite(wc_work_gfx\_gfx_id)=0
  ProcedureReturn #False  
  EndIf
  
  wc_object_size\height=SpriteHeight(wc_work_gfx\_gfx_id)
  wc_object_size\width=SpriteWidth(wc_work_gfx\_gfx_id)
  
EndProcedure

Procedure  WC_SOUND_PLAY(_void.l)
  Define _ok.l=0
    
    Select _void.l  
        
      Case #WC_SOUND_PLAY
               
        wc_full_sound_path.s=v_resource_path_sound.s+GetFilePart(wc_full_sound_path.s)
        If IsSound(wc_sound_id.i)<>0
        StopSound(wc_sound_id.i)
        FreeSound(wc_sound_id.i)  
        EndIf
        
        wc_sound_id.i=LoadSound(#PB_Any,wc_full_sound_path.s)
        
        If IsSound(wc_sound_id.i)=0
          _ok.l=MessageRequester("                                   SOUND                                  ","           **************  NOT FOUND   ************  ",#PB_MessageRequester_Ok)
        ProcedureReturn #False  
        EndIf
      
        PlaySound(wc_sound_id.i)
           
      Case #WC_SOUND_STOP
        
        If IsSound(wc_sound_id.i)
          StopSound(wc_sound_id.i)
        EndIf
              
      Case #WC_REMOVE_SOUND_FROM_MAP
        
        If IsSound(wc_sound_id.i)
          StopSound(wc_sound_id.i)
          FreeSound(wc_sound_id.i)
          wc_full_sound_path.s=""
        EndIf
             
    EndSelect
    
EndProcedure

  Procedure  WC_LOAD_SOUND()
    Define _ok.l=0
    
    wc_full_sound_path.s=OpenFileRequester("ADD GLOBAL SOUND TO MAP:           ",v_resource_path_sound.s,"SOUND: (*snd) |*.ogg",0)
    
    wc_sound_id.i=LoadSound(#PB_Any,wc_full_sound_path.s)
    
    If IsSound(wc_sound_id.i)
       wc_sound_ok.b=#True
      _ok.l=MessageRequester("                                   SOUND                                  ","  VALID  OGG SOUND FOUND    ",#PB_MessageRequester_Ok)
      
    Else
       wc_sound_ok.b=#False
      _ok.l=MessageRequester("                                   SOUND                                  ","           **************  NOT FOUND   ************  ",#PB_MessageRequester_Ok)
      
    EndIf
      
    EndProcedure
    
    Procedure WC_TOUCH_SWITCH_MAP()
  wc_switch_map_name.s=OpenFileRequester("SELECT SWITCH MAP: ",wc_global_load_save_path.s,"WORLDMAP FILES|*.worldmap",0)
  wc_switch_map_name.s=GetFilePart(wc_switch_map_name.s)

EndProcedure

Procedure WC_MAP_OBJECT_INTEGRITY()
  ;here we delete faulty objects (void and not defined)
  
  If ListSize(map_object())<0
    ProcedureReturn #False
  EndIf
  
  ;---------------------------- here we go and check if object file is valid:
  
  ResetList(map_object())
  
  ForEach map_object()
    
    If Len(map_object()\_ai_path)<1
    DeleteElement(map_object())  
    EndIf
    
  Next
  
EndProcedure

Procedure E_INIT_MAP_BASE()
  wc_map_can_pause_id.b=#True
  wc_map_can_pause.s="YES"
  wc_map_use_respawn_id=#True
  wc_map_use_respawn.s="YES"
  wc_map_use_quest_system.b=#False
  wc_map_day_timer.b=#True
  wc_map_show_version_info.b=#False
  wc_map_is_arena_text.s="NO"  ;default / restore default value if  map is loaded
  wc_map_timer_switch.l=0
  wc_quest_book.l=0
  wc_switch_map_name.s=""
  wc_map_switch_on_trigger.b=#False
  wc_show_timer.b=#False
  wc_map_use_black_stamp.b=#False
  wc_scroll.b=#True
  wc_scroll_yes_no.s="YES"
  wc_map_show_scroll_text.b=#False
  
EndProcedure

Procedure WC_LOAD_WORLD(_mode.l)

  Define _ok.i=0
  
;   wc_map_can_pause_id.b=#True
;   wc_map_can_pause.s="YES"
;   wc_map_use_respawn_id=#True
;   wc_map_use_respawn.s="YES"
;   wc_map_use_quest_system.b=#False
;   wc_map_day_timer.b=#True
;   wc_map_show_version_info.b=#False
;   wc_map_is_arena_text.s="NO"  ;default / restore default value if  map is loaded
;   wc_map_timer_switch.l=0
;   wc_quest_book.l=0
;   wc_switch_map_name.s=""
;   wc_map_switch_on_trigger.b=#False
;   wc_show_timer.b=#False
;   wc_map_use_black_stamp.b=#False
;   wc_scroll.b=#True
;   wc_scroll_yes_no.s="YES"
;   wc_map_show_scroll_text.b=#False
 
  If _mode.l<>#USE_CACHE
    wc_global_load_save_path.s=OpenFileRequester("LOAD MAP: ",wc_global_load_save_path.s,"WORLDMAP(*.worldmap)|*.worldmap|PROC_AREA(*.area)|*.area",0)
   
      Else
   wc_global_load_save_path.s=v_cache_dir+Str(v_cache_id)+".cache"
  EndIf
      
  _ok.i=ReadFile(#PB_Any, wc_global_load_save_path.s)
  If IsFile(_ok.i)=0
  ProcedureReturn #False  
  EndIf
     
    If IsSound(wc_sound_id.i)
      StopSound(wc_sound_id.i)
          FreeSound(wc_sound_id.i)
          wc_sound_ok.b=#False
    EndIf
  
    ;now we need the garbage collector, we reset all to zero to load the new data
    WC_GARBAGE_COLLECTOR()
    E_INIT_MAP_BASE()
    WC_SET_DEFAULT_MENU_STATE_ON_START()  
    WC_LOAD_MAP_PARSER(_ok.i, wc_global_load_save_path.s)
    
    CloseFile(_ok.i)
    
    If ListSize(map_object())<1
      ProcedureReturn #False
    EndIf
    
    WC_MAP_OBJECT_INTEGRITY()
    
    ;sort object using the layer information stored in the map -----> from lowest to highest layer (-xxxx..........+xxxxx)
    SortStructuredList(map_object(),#PB_Sort_Ascending  ,OffsetOf(map_objects\_layer),TypeOf(map_objects\_layer))
    
EndProcedure

Procedure WC_SAVE_WORLD(_mode.l)
  ;now we try to save the mess:
  Define  _ok.i=0
  Define _save_path.s=""
  Define _npc_text_file_id.i=0 
  Define _world_map_name_file_id.i=0
  Define _world_global_effect.s=""
  
  Select wc_global_effect.i
      
    Case #WC_GLOBAL_EFFECT_SNOW
      _world_global_effect.s="WINTER"
  EndSelect
  
  wc_global_effect_info_text.s=_world_global_effect.s
  
  wc_quest_book.l=0  ;for start we have no chapters
  
  If _mode.l<>#USE_CACHE
    wc_global_load_save_path.s=SaveFileRequester("SAVE MAP: ", wc_global_load_save_path.s,"WORLDMAP(*.worldmap)|*.worldmap|PROC_AREA(*.area)|*.area",0)
    _save_path.s=wc_global_load_save_path.s
    wc_x_origin.i=wc_x_offset.i
    wc_y_origin.i=wc_y_offset.i
  Else
    _save_path.s=v_cache_dir+Str(v_cache_id)+".cache"
  EndIf
  
  WC_MAP_OBJECT_INTEGRITY()
  
  _ok.i=CreateFile(#PB_Any,_save_path.s)
  
  If  IsFile(_ok.i)
    SortStructuredList(map_object(),#PB_Sort_Ascending  ,OffsetOf(map_objects\_layer),TypeOf(map_objects\_layer))
    ResetList(map_object())
    
    WriteStringN(_ok.i,"*********************************************************************************************************")
    WriteStringN(_ok.i,"WORLD MAP CREATOR FILE : GENERATED BY -WORLDMAP CREATOR- TOOL ")
    WriteStringN(_ok.i,"DEUTSCHMANN WALTER (DEUTSCHMANN DEVELOPEMENT) ALL RIGHTS RESERVED")
    WriteStringN(_ok.i,"DO NOT CHANGE CONTENTS OF FILE, THIS MAY HARM SYSTEM AND APP STABILITY")
    WriteStringN(_ok.i,"MAP OBJECTS: ")
    WriteStringN(_ok.i,Str(ListSize(map_object()) ))
    WriteStringN(_ok.i,"*********************************************************************************************************")
    WriteStringN(_ok.i,"WORLD_VIEW_W")
    WriteStringN(_ok.i,Str(wc_engine_screen_width.f))
    WriteStringN(_ok.i,"WORLD_VIEW_H")
    WriteStringN(_ok.i,Str(wc_engine_screen_height.f))
    WriteStringN(_ok.i,"WORLD_START:"); keyword for io system to read map file startign with next position in skript file
    WriteStringN(_ok.i,"WORLD_GLOBAL_SOUND")
    WriteStringN(_ok.i,wc_full_sound_path.s) ;for mapcreator we use full path of sound
    WriteStringN(_ok.i,"USE_AUTO_LAYER")     ;here we store the autolayer function
    WriteStringN(_ok.i,wc_auto_layer.s)
    WriteStringN(_ok.i,"OFFSETX:")
    WriteStringN(_ok.i,Str(wc_x_offset.i))
    WriteStringN(_ok.i,"OFFSETY:")
    WriteStringN(_ok.i,Str(wc_y_offset.i))
    WriteStringN(_ok.i,"MAP_CAN_PAUSE")
    WriteStringN(_ok.i,wc_map_can_pause.s)
    WriteStringN(_ok.i,"MAP_USE_RESPAWN")
    WriteStringN(_ok.i,wc_map_use_respawn.s)
    WriteStringN(_ok.i,"MAP_USE_QUEST_SYSTEM")
    WriteStringN(_ok.i,Str(wc_map_use_quest_system.b))
    WriteStringN(_ok.i,"MAP_FIGHT")
    WriteStringN(_ok.i,wc_map_fight_text.s)
    WriteStringN(_ok.i,"MAP_DAY_TIMER")
    WriteStringN(_ok.i,Str(wc_map_day_timer.b))
    WriteStringN(_ok.i,"SHOW_VERSION_INFO")
    WriteStringN(_ok.i,Str(wc_map_show_version_info.b))
    WriteStringN(_ok.i,"MAP_IS_ARENA")
    WriteStringN(_ok.i,wc_map_is_arena_text.s)
    WriteStringN(_ok.i,"MAP_AUTO_SWITCH_TIMER")
    WriteStringN(_ok.i,Str(wc_map_timer_switch.l))
    WriteStringN(_ok.i,"SWITCH_MAP")
    WriteStringN(_ok.i,wc_switch_map_name.s)
    WriteStringN(_ok.i,"SWITCH_MAP_ON_TRIGGER")
    WriteStringN(_ok.i,Str(wc_map_switch_on_trigger.b))
    WriteStringN(_ok.i,"MAP_SHOW_TIMER")
    WriteStringN(_ok.i,Str(wc_show_timer.b))
    WriteStringN(_ok.i,"MAP_USE_BLACK_STAMP")
    WriteStringN(_ok.i,Str(wc_map_use_black_stamp.b))
    WriteStringN(_ok.i,"SCROLL")
    WriteStringN(_ok.i,Str(wc_scroll.b))
    WriteStringN(_ok.i,"WORLD_GLOBAL_EFFECT")
    WriteStringN(_ok.i,_world_global_effect.s)
    WriteStringN(_ok.i,"WORLD_SHOW_SCROLL_TEXT")
    WriteStringN(_ok.i,Str(wc_map_show_scroll_text.b))
    WriteStringN(_ok.i,"MAP_SHOW_GUI")
    WriteStringN(_ok.i,Str(wc_map_show_gui.b))  
    
    While NextElement(map_object()) 
          
      If _mode.l=#USE_CACHE
        
        If  map_object()\_DO_NOT_SHOW=#False  ;undo/redo
          
          If map_object()\_DO_NOT_SAVE_THIS_OBJECT<>1 ;here we sort out the global object garbage, we do not save object we will never use/need
            
            WriteStringN(_ok.i,"NEXTELEMENT:")
            WriteStringN(_ok.i,"OBJECTSOURCE:")
            WriteStringN(_ok.i,map_object()\_ai_path)
            WriteStringN(_ok.i,"OBJECT_X:")
            WriteStringN(_ok.i,Str(map_object()\_x))
            WriteStringN(_ok.i,"OBJECT_Y:")
            WriteStringN(_ok.i,Str(map_object()\_y))
            WriteStringN(_ok.i,"OBJECTLAYER:")
            WriteStringN(_ok.i,Str(map_object()\_layer))
            WriteStringN(_ok.i,"OBJECT_W:")
            WriteStringN(_ok.i,Str(SpriteWidth(map_object()\_gfx_id)))
            WriteStringN(_ok.i,"OBJECT_H:")
            WriteStringN(_ok.i,Str(SpriteHeight(map_object()\_gfx_id)))
            If  map_object()\_full_screen<>0
              WriteStringN(_ok.i,"FULLSCREEN:")
              WriteStringN(_ok.i,Str(map_object()\_full_screen))
            EndIf
                    
            If map_object()\object_add_to_quest<>0
              wc_quest_book.l+1
            EndIf           
            
          EndIf        
          
        EndIf  ;undo / redo
        
      EndIf ;use cache ?
      
      If _mode.l<>#USE_CACHE
         
      If map_object()\object_NPC_show_text_on_collision<>0  ;default english version
        _npc_text_file_id.i= OpenFile( #PB_Any,wc_global_load_save_path.s+"."+map_object()\object_NPC_internal_name+"."+map_object()\object_NPC_text_path)  ;if not, create an empty file with valid filename
        If IsFile(_npc_text_file_id.i)
          CloseFile(_npc_text_file_id.i)  
        EndIf
        
      EndIf
      
      If map_object()\object_NPC_show_text_on_collision<>0  ;default german version
        _npc_text_file_id.i=OpenFile( #PB_Any,wc_global_load_save_path.s+"."+map_object()\object_NPC_internal_name+"."+map_object()\object_NPC_text_path+".de")  ;if not, create an empty file with valid filename
        If IsFile(_npc_text_file_id.i)
          CloseFile(_npc_text_file_id.i)  
        EndIf
        
      EndIf
           
        If  map_object()\_DO_NOT_SHOW=#False  ;undo/redo
          
          If map_object()\object_is_procedural_base=0 
            
            If map_object()\_DO_NOT_SAVE_THIS_OBJECT<>1  ;here we sort out the global object garbage, we do not save object we will never use/need
              
              WriteStringN(_ok.i,"NEXTELEMENT:")
              WriteStringN(_ok.i,"OBJECTSOURCE:")
              WriteStringN(_ok.i,map_object()\_ai_path)
              WriteStringN(_ok.i,"OBJECT_X:")
              WriteStringN(_ok.i,Str(map_object()\_x))
              WriteStringN(_ok.i,"OBJECT_Y:")
              WriteStringN(_ok.i,Str(map_object()\_y))
              WriteStringN(_ok.i,"OBJECTLAYER:")
              WriteStringN(_ok.i,Str(map_object()\_layer))
              WriteStringN(_ok.i,"OBJECT_W:")
              WriteStringN(_ok.i,Str(SpriteWidth(map_object()\_gfx_id)))
              WriteStringN(_ok.i,"OBJECT_H:")
              WriteStringN(_ok.i,Str(SpriteHeight(map_object()\_gfx_id)))
              If  map_object()\_full_screen<>0
                WriteStringN(_ok.i,"FULLSCREEN:")
                WriteStringN(_ok.i,Str(map_object()\_full_screen))
              EndIf
                        
              If    map_object()\object_add_to_quest<>0
                wc_quest_book.l+1
              EndIf           
              
            EndIf
            
          EndIf          
          
        EndIf  ;undo / redo
        
      EndIf ;not use cache 
      
    Wend
    
    WriteStringN(_ok.i,"QUESTBOOK_CHAPTERS")
    WriteStringN(_ok.i,Str(wc_quest_book.l))
    
    CloseFile(_ok.i)
    
    If _mode.l=#USE_CACHE
      v_cache_id.l+1  
    EndIf
    v_cache_last_id.l=v_cache_id.l
    
    _world_map_name_file_id.i=ReadFile(#PB_Any,wc_global_load_save_path.s+".name")
           
    If IsFile(_world_map_name_file_id.i)
      CloseFile(_world_map_name_file_id.i)
    Else
      _world_map_name_file_id.i=OpenFile(#PB_Any,wc_global_load_save_path.s+".name")
      
      If IsFile(_world_map_name_file_id.i)
        WriteStringN(_world_map_name_file_id.i,"#NAME#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#R#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#G#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#B#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#X#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#Y#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#END#")
      
      CloseFile(_world_map_name_file_id.i)
        
    EndIf
  EndIf
     
    _world_map_name_file_id.i=ReadFile(#PB_Any,wc_global_load_save_path.s+".head")
           
    If IsFile(_world_map_name_file_id.i)
      CloseFile(_world_map_name_file_id.i)
    Else
      _world_map_name_file_id.i=OpenFile(#PB_Any,wc_global_load_save_path.s+".head")
      
      If IsFile(_world_map_name_file_id.i)
        WriteStringN(_world_map_name_file_id.i,"#HEAD#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#R#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#G#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#B#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#X#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#Y#")
        WriteStringN(_world_map_name_file_id.i,"")
        WriteStringN(_world_map_name_file_id.i,"#END#")
      
      CloseFile(_world_map_name_file_id.i)
        
    EndIf
  EndIf
   
        _world_map_name_file_id.i=ReadFile(#PB_Any,wc_global_load_save_path.s+".scrolltext")
          
        If IsFile(_world_map_name_file_id.i)
          CloseFile(_world_map_name_file_id.i)
        Else
          _world_map_name_file_id.i=OpenFile(#PB_Any,wc_global_load_save_path.s+".scrolltext")
          
          If IsFile(_world_map_name_file_id.i)
            WriteStringN(_world_map_name_file_id.i,"#SCROLLTEXT#")
            WriteStringN(_world_map_name_file_id.i,"")
            WriteStringN(_world_map_name_file_id.i,"#R#")
            WriteStringN(_world_map_name_file_id.i,"")
            WriteStringN(_world_map_name_file_id.i,"#G#")
            WriteStringN(_world_map_name_file_id.i,"")
            WriteStringN(_world_map_name_file_id.i,"#B#")
            WriteStringN(_world_map_name_file_id.i,"")
            WriteStringN(_world_map_name_file_id.i,"#X#")
            WriteStringN(_world_map_name_file_id.i,"")
            WriteStringN(_world_map_name_file_id.i,"#Y#")
            WriteStringN(_world_map_name_file_id.i,"")
            WriteStringN(_world_map_name_file_id.i,"#SCROLLSPEED_UP#")
            WriteStringN(_world_map_name_file_id.i,"")
            WriteStringN(_world_map_name_file_id.i,"#SCROLLSPEED_DOWN#")
            WriteStringN(_world_map_name_file_id.i,"")
            WriteStringN(_world_map_name_file_id.i,"#SCROLLSPEED_LEFT#")
            WriteStringN(_world_map_name_file_id.i,"")
            WriteStringN(_world_map_name_file_id.i,"#SCROLLSPEED_RIGHT#")
            WriteStringN(_world_map_name_file_id.i,"")
            WriteStringN(_world_map_name_file_id.i,"#END#")
            
            CloseFile(_world_map_name_file_id.i)       
            
          EndIf
        EndIf
        
    
    If _mode.l<>#USE_CACHE
      _ok.i=MessageRequester("WORLDCREATOR INFO:", wc_global_load_save_path.s+Chr(13)+" CREATED",#PB_MessageRequester_Info)
    EndIf
    
  EndIf
  
EndProcedure

Procedure WC_MAP_OBJECT_UNDO()
  
  ;here we go for a fast undo (does not support redo....)
  If ListSize(map_object())>0
    SortStructuredList(map_object(),#PB_Sort_Ascending,OffsetOf(map_objects\object_counter_id),TypeOf(map_objects\object_counter_id))
    LastElement(map_object())
    DeleteElement(map_object())
    SortStructuredList(map_object(),#PB_Sort_Ascending  ,OffsetOf(map_objects\_layer),TypeOf(map_objects\_layer))
    
  EndIf
 
EndProcedure

Procedure WC_MAP_OBJECT_REDO()
 
  If v_cache_id.l<v_cache_last_id.l
    v_cache_id.l+1 
    WC_LOAD_WORLD(#USE_CACHE)
  EndIf 

  EndProcedure
  
  Procedure WC_MAP_USE_RESPAWN_YES()
    wc_map_use_respawn_id.b=#True
    wc_map_use_respawn.s="YES"
     SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_RESPAWN_YES,#True)
     SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_RESPAWN_NO,0)
  EndProcedure
  
  Procedure WC_MAP_USE_RESPAWN_NO()
    wc_map_use_respawn_id.b=#False
    wc_map_use_respawn.s="NO"
      SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_RESPAWN_YES,0)
      SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_RESPAWN_NO,#True)
    EndProcedure
  
  Procedure WC_MENU_EVENT()
    
    Define _msg.l=0
    
    Select EventMenu()
        
      Case #WC_MENU_QUIT
        
        _msg.l=MessageRequester("QUIT WORLDCREATOR?","QUIT?",#PB_MessageRequester_YesNo)
        
        If _msg.l=#PB_MessageRequester_Yes
          
          WC_CLEAN_CACHE( v_clean_cache_on_exit.b)
          
          End
        EndIf
        
      Case #WC_MENU_MAP_PAUSE_NO
          ;default
    wc_map_can_pause_id.b=#True
    wc_map_can_pause.s="NO"
    SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_PAUSE_NO,#True)
    SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_PAUSE_YES,0)
        
      Case #WC_MENU_MAP_PAUSE_YES
     wc_map_can_pause_id.b=#True
     wc_map_can_pause.s="YES"
    SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_PAUSE_NO,0)
    SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_PAUSE_YES,#True)
               
      Case #WC_MENU_LOAD_MAP
        WC_LOAD_WORLD(0)
        
      Case #WC_MENU_SAVE_MAP
        WC_SAVE_WORLD(0)
        
      Case #WC_MENU_SET_RESURCE
        WC_SET_RESOURCE()
        
      Case #WC_MENU_SET_RESOURCE_SOUND
        WC_SET_RESOURCE_SOUND()
        
      Case #WC_MENU_UPDATE_ASSETS
        WC_REFRESH_GFX_RESOURCE_DIRECTORY()
        
      Case #WC_MENU_OPEN_ASSET_DRAWER
        WC_OPEN_ASSET_GFX_RESOURCE()
               
      Case #WC_MENU_OPEN_ASSET_SOUND_DRAWER
        WC_OPEN_ASSET_SOUND_RESOURCE()
        
      Case #WC_MENU_UNDO
        WC_MAP_OBJECT_UNDO()
        
      Case #WC_MENU_MOVE_BY_OBJECT_GRID
        WC_SET_GRID_MOVE()
        
      Case #WC_MENU_REDO
        WC_MAP_OBJECT_REDO()
        
      Case #WC_MENU_GO_TO_MAP_START        
        WC_MAP_GO_TO_START()
        
      Case #WC_MENU_NEW
          WC_ERROR(#WC_ERROR_NOT_SAVED_CONTENT_WILL_BE_LOST," NOT SAVED CONTENT WILL BE LOST?")
        
        Case #WC_LAYER_M1
          wc_layer.b=-1
        Case #WC_LAYER_M2
          wc_layer.b=-2
        Case #WC_LAYER_M3
          wc_layer.b=-3
        Case #WC_LAYER_M4
          wc_layer.b=-4
        Case #WC_LAYER_M5
          wc_layer.b=-5
          
        Case #WC_LAYER_M6
          wc_layer.b=-6
        Case #WC_LAYER_M7
          wc_layer.b=-7
        Case #WC_LAYER_M8
          wc_layer.b=-8
        Case #WC_LAYER_M9
          wc_layer.b=-9
        Case #WC_LAYER_M10
          wc_layer.b=-10
        Case #WC_LAYER_M11
          wc_layer.b=-11
        Case #WC_LAYER_M12
          wc_layer.b=-12
        Case #WC_LAYER_M13
          wc_layer.b=-13
        Case #WC_LAYER_M14
          wc_layer.b=-14
        Case #WC_LAYER_M15
          wc_layer.b=-15
          
        Case #WC_LAYER_0
          wc_layer.b=0
        Case #WC_LAYER_1
          wc_layer.b=1
        Case #WC_LAYER_2
        wc_layer.b=2
      Case #WC_LAYER_3
        wc_layer.b=3
      Case #WC_LAYER_4
        wc_layer.b=4
      Case #WC_LAYER_5
        wc_layer.b=5
      Case #WC_LAYER_6
        wc_layer.b=6
      Case #WC_LAYER_7
        wc_layer.b=7
      Case #WC_LAYER_8
        wc_layer.b=8
      Case #WC_LAYER_9
        wc_layer.b=9
      Case #WC_LAYER_10
        wc_layer.b=10
        
      Case #WC_MAP_INFO
        WC_MAP_INFO()
        
      Case #WC_SHOW_ACTUAL_LAYER
        wc_layer_show.b=wc_layer.b
        
      Case #WC_SHOW_ALL_LAYER
        wc_layer_show.b=-127
        
      Case #WC_MENU_SHOW_LAYER_ID
        wc_show_layer_id.b=#True
        
      Case #WC_MENU_DO_NOT_SHOW_LAYER_ID
        wc_show_layer_id.b=#False
        
      Case #WC_MENU_SHOW_ENGINE_AREA
        
        If wc_engine_screen_area_show.b=#True
          wc_engine_screen_area_show.b=#False
        EndIf
        
        If  wc_engine_screen_area_show.b=#False
          wc_engine_screen_area_show.b=#True
        EndIf       
        
      Case #WC_MENU_MOVE_MAP_OBJECT_SIZE
        wc_map_move_per_pixel=#False
               
      Case  #WC_MENU_MOVE_MAP_PER_PIXEL
        wc_map_move_per_pixel=#True
        
      Case #WC_USE_RASTER_NO
        wc_use_object_based_raster.b=0
              
      Case #WC_USE_RASTER_YES
        wc_use_object_based_raster.b=1
        
      Case #WC_USE_AUTO_LAYER
        wc_use_auto_layer.b=#True
        wc_auto_object.s="*AUTO LAYER*"
        wc_auto_layer.s="YES"
        SetMenuItemState(v_menu_id.i,#WC_USE_AUTO_LAYER,#True)
        SetMenuItemState(v_menu_id.i,#WC_DO_NOT_USE_AUTO_LAYER,0)
        
      Case #WC_DO_NOT_USE_AUTO_LAYER
        wc_use_auto_layer.b=#False
        wc_auto_object.s="NO AUTO LAYER"
        wc_auto_layer.s="NO"
         SetMenuItemState(v_menu_id.i,#WC_USE_AUTO_LAYER,0)
        SetMenuItemState(v_menu_id.i,#WC_DO_NOT_USE_AUTO_LAYER,#True)
        
      Case #WC_MENU_INFO
        WC_INFO()
        
      Case #WC_MENU_MAP_USE_QUEST_SYSTEM_NO
        wc_map_use_quest_system.b=#False
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_QUEST_SYSTEM_NO,#True)
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_QUEST_SYSTEM_YES,0)
 
      Case #WC_MENU_MAP_USE_QUEST_SYSTEM_YES
        wc_map_use_quest_system.b=#True
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_QUEST_SYSTEM_NO,0)
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_QUEST_SYSTEM_YES,#True)
        
        Case #WC_MAP_USE_VIEW_STAMP
        wc_map_use_black_stamp.b=#True
        SetMenuItemState(v_menu_id.i,#WC_MAP_USE_VIEW_STAMP,#True)
        SetMenuItemState(v_menu_id.i,#WC_MAP_DO_NOT_USE_VIEW_STAMP,0)
        
        Case #WC_MAP_DO_NOT_USE_VIEW_STAMP
        wc_map_use_black_stamp.b=#False
        SetMenuItemState(v_menu_id.i,#WC_MAP_USE_VIEW_STAMP,0)
        SetMenuItemState(v_menu_id.i,#WC_MAP_DO_NOT_USE_VIEW_STAMP,#True)
        
      Case  #WC_ADD_SOUND_TO_MAP
        WC_LOAD_SOUND()
        
      Case #WC_SOUND_PLAY
        WC_SOUND_PLAY( #WC_SOUND_PLAY)
        
      Case #WC_SOUND_STOP
        WC_SOUND_PLAY(#WC_SOUND_STOP)
        
      Case #WC_REMOVE_SOUND_FROM_MAP
        WC_SOUND_PLAY(#WC_REMOVE_SOUND_FROM_MAP)
        
      Case #WC_MENU_ADD_MAP_TEMPLATE
        WC_LOAD_TEMPLATE()
        
      Case #WC_TEMPLATE_TRANSPARENCY_ADD
          WC_TEMPLATE_TRANSPARENCY_ADD()
        
      Case #WC_TEMPLATE_TRANSPARENCY_REMOVE
        WC_TEMPLATE_TRANSPARENCY_REMOVE()
        
      Case #WC_HIDE_TEMPLATE
        WC_TEMPLATE_HIDE()
        
      Case #WC_MENU_MAP_FIGHT
        wc_map_fight.b=#True
        wc_map_fight_text="YES"
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_FIGHT,#True)
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_NO_FIGHT,0)
             
        Case #WC_MENU_MAP_NO_FIGHT
          wc_map_fight.b=#False 
          wc_map_fight_text.s="NO"
           SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_FIGHT,0)
           SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_NO_FIGHT,#True)
        
      Case #WC_VIEW_800_450
        wc_engine_screen_width.f=800
        wc_engine_screen_height.f=450
        SetMenuItemState(v_menu_id.i,#WC_VIEW_800_450,#True)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1000_564,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1280_720,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1440_1080,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1600_900,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1920_1080,0)
             
      Case #WC_VIEW_1000_564  ;default
        wc_engine_screen_width.f=1000
        wc_engine_screen_height.f=564
        
         SetMenuItemState(v_menu_id.i,#WC_VIEW_800_450,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1000_564,#True)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1280_720,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1440_1080,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1600_900,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1920_1080,0)
        
      Case #WC_VIEW_1280_720
        wc_engine_screen_width.f=1280
        wc_engine_screen_height.f=720
        
        SetMenuItemState(v_menu_id.i,#WC_VIEW_800_450,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1000_564,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1280_720,#True)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1440_1080,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1600_900,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1920_1080,0)
        
      Case #WC_VIEW_1440_1080
        wc_engine_screen_width.f=1440
        wc_engine_screen_height.f=1080  
        
        SetMenuItemState(v_menu_id.i,#WC_VIEW_800_450,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1000_564,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1280_720,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1440_1080,#True)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1600_900,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1920_1080,0)
        
      Case #WC_VIEW_1600_900
        wc_engine_screen_width.f=1600
        wc_engine_screen_height.f=900
        
        SetMenuItemState(v_menu_id.i,#WC_VIEW_800_450,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1000_564,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1280_720,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1440_1080,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1600_900,#True)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1920_1080,0)
        
      Case #WC_VIEW_1920_1080
        wc_engine_screen_width.f=1920
        wc_engine_screen_height.f=1080
        
        SetMenuItemState(v_menu_id.i,#WC_VIEW_800_450,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1000_564,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1280_720,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1440_1080,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1600_900,0)
        SetMenuItemState(v_menu_id.i,#WC_VIEW_1920_1080,#True)
        
      Case #WC_MENU_MAP_USE_RESPAWN_NO
        WC_MAP_USE_RESPAWN_NO()
             
      Case #WC_MENU_MAP_USE_RESPAWN_YES
        WC_MAP_USE_RESPAWN_YES()
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_RESPAWN_YES,#True)
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_RESPAWN_NO,0)
                     
      Case #WC_MENU_DAYTIMER_OFF
        wc_map_day_timer.b=#False
        
        SetMenuItemState(v_menu_id.i,#WC_MENU_DAYTIMER_OFF,#True)
        SetMenuItemState(v_menu_id.i,#WC_MENU_DAYTIMER_ON,0)
        
      Case #WC_MENU_DAYTIMER_ON
        wc_map_day_timer.b=#True
        SetMenuItemState(v_menu_id.i,#WC_MENU_DAYTIMER_OFF,0)
        SetMenuItemState(v_menu_id.i,#WC_MENU_DAYTIMER_ON,#True)
               
      Case #WC_MENU_MAP_IS_ARENA_YES
        wc_map_is_arena_text.s="YES"
        WC_MAP_USE_RESPAWN_NO()
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_IS_ARENA_YES,#True)
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_IS_ARENA_NO,0)
               
      Case  #WC_MENU_MAP_IS_ARENA_NO
        wc_map_is_arena_text.s="NO"
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_IS_ARENA_YES,0)
        SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_IS_ARENA_NO,#True)
              
      Case #WC_SHOW_VERSION_NO
        wc_map_show_version_info.b=#False
        SetMenuItemState(v_menu_id.i,#WC_SHOW_VERSION_NO,#True)
        SetMenuItemState(v_menu_id.i,#WC_SHOW_VERSION_YES,0)
        
      Case #WC_SHOW_VERSION_YES
        wc_map_show_version_info.b=#True
        SetMenuItemState(v_menu_id.i,#WC_SHOW_VERSION_NO,0)
        SetMenuItemState(v_menu_id.i,#WC_SHOW_VERSION_YES,#True)
              
        ;simple solution for now to integrate timer  for maps (auto change map after timer (ms))
        
      Case #WC_TIMER_SWITCH_MAP_0
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,#True)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_ON_TRIGGER,0)
        wc_map_timer_switch.l=0
        wc_map_switch_on_trigger.b=#False
        
      Case #WC_TIMER_SWITCH_MAP_1000
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,#True)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_ON_TRIGGER,0)
        wc_map_timer_switch.l=1000
        wc_map_switch_on_trigger.b=#False
                
      Case #WC_TIMER_SWITCH_MAP_2000
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,#True)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_ON_TRIGGER,0)
        wc_map_timer_switch.l=2000
        wc_map_switch_on_trigger.b=#False
        
      Case #WC_TIMER_SWITCH_MAP_3000
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,#True)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_ON_TRIGGER,0)
        wc_map_timer_switch.l=3000
        wc_map_switch_on_trigger.b=#False
               
      Case #WC_TIMER_SWITCH_MAP_5000
        
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,#True)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_ON_TRIGGER,0)
        wc_map_timer_switch.l=5000
        wc_map_switch_on_trigger.b=#False
        
       Case #WC_TIMER_SWITCH_MAP_10000
        
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,#True)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_ON_TRIGGER,0)
        wc_map_timer_switch.l=10000
        wc_map_switch_on_trigger.b=#False
           
      Case #WC_TIMER_SWITCH_MAP_ON_TRIGGER
        
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
        SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_ON_TRIGGER,#True)
        wc_map_switch_on_trigger.b=#True     
        
      Case #WC_SWITCH_MAP_TOUCH
        WC_TOUCH_SWITCH_MAP()
        
      Case #WC_SWITCH_MAP_TOUCH_DESELECT
        wc_switch_map_name.s=""
        
      Case #WC_MAP_SHOW_TIMER
        wc_show_timer.b=#True
        SetMenuItemState(v_menu_id.i,#WC_MAP_SHOW_TIMER,#True)
        SetMenuItemState(v_menu_id.i,#WC_MAP_SHOW_TIMER_NOT,0)
      Case #WC_MAP_SHOW_TIMER_NOT
        wc_show_timer.b=#False
         SetMenuItemState(v_menu_id.i,#WC_MAP_SHOW_TIMER,0)
         SetMenuItemState(v_menu_id.i,#WC_MAP_SHOW_TIMER_NOT,#True)
                
       Case #WC_MENU_MAP_SCROLL
         wc_scroll.b=#True
         wc_scroll_yes_no.s="YES"
         SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_SCROLL,#True)
         SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_NO_SCROLL,0)
         
         Case #WC_MENU_MAP_NO_SCROLL
           wc_scroll.b=#False
           wc_scroll_yes_no.s="NO"
         SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_SCROLL,0)
         SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_NO_SCROLL,#True)
                
       Case #WC_MENU_GLOBAL_EFFECT_SNOW
         wc_global_effect.i=#WC_GLOBAL_EFFECT_SNOW
         wc_global_effect_info_text.s="WINTER"
         SetMenuItemState(v_menu_id.i,#WC_MENU_NO_GLOBAL_EFFECT,0)
         SetMenuItemState(v_menu_id.i,#WC_MENU_GLOBAL_EFFECT_SNOW,#True)
         
         Case #WC_MENU_NO_GLOBAL_EFFECT
           wc_global_effect.i=#WC_GLOBAL_EFFECT_NONE
           wc_global_effect_info_text.s=""
         SetMenuItemState(v_menu_id.i,#WC_MENU_NO_GLOBAL_EFFECT,#True)
         SetMenuItemState(v_menu_id.i,#WC_MENU_GLOBAL_EFFECT_SNOW,0)
                
       Case #WC_MENU_SHOW_SCROLL_TEXT
         
         Select GetMenuItemState(v_menu_id.i,#WC_MENU_SHOW_SCROLL_TEXT)
                         
           Case #True
             
             SetMenuItemState(v_menu_id.i,#WC_MENU_SHOW_SCROLL_TEXT,0)
             wc_map_show_scroll_text.b=#False
           Default
             
             SetMenuItemState(v_menu_id.i,#WC_MENU_SHOW_SCROLL_TEXT,#True)
             wc_map_show_scroll_text.b=#True
         EndSelect
                 
       Case #WC_MENU_MAP_GUI_ON
         SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_ON,#True)
         SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_OFF,0)
         wc_map_show_gui.b=#True
         
       Case #WC_MENU_MAP_GUI_OFF
           SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_ON,0)
           SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_OFF,#True)
         wc_map_show_gui.b=#False
         
    EndSelect
       
  EndProcedure

Procedure WC_TOOL_WINDOW_EVENT(_event.l)
  ;here we pick the gfxobjects for the worldmaker
  
  Select _event.l
      
    Case    #PB_Event_Gadget
      
      If IsGadget(EventGadget()-1)=0
        ProcedureReturn #False
      EndIf       
      
      If SelectElement(wc_menu_object(),EventGadget()-1)
        wc_work_gfx\_gfx_path=wc_menu_object()\_gfx_path
        wc_work_gfx\_ai_path=wc_menu_object()\_ai_path
        
        If IsSprite(wc_work_gfx\_gfx_id)
        FreeSprite(wc_work_gfx\_gfx_id)  
        EndIf
        E_GET_PACK_GFX_AND_REBUILD_DISTI(wc_work_gfx\_gfx_path)
        wc_work_gfx\_gfx_id=LoadSprite(#PB_Any,wc_work_gfx\_gfx_path,#PB_Sprite_AlphaBlending)
        E_GET_PACK_GFX_AND_CONVERT_DISTI(wc_work_gfx\_gfx_path)
        wc_work_gfx\_full_screen=wc_menu_object()\_full_screen
        
        wc_work_gfx\_transparency=wc_menu_object()\_transparency
        wc_work_gfx\_object_auto_layer=wc_menu_object()\_object_auto_layer

        wc_work_gfx\object_is_scroll_back_ground=wc_menu_object()\object_is_scroll_back_ground
        wc_work_gfx\object_use_random_angle=wc_menu_object()\object_use_random_angle
        wc_work_gfx\object_use_shadow=wc_menu_object()\object_use_shadow
        wc_work_gfx\object_shadow_intense=wc_menu_object()\object_shadow_intense
        wc_work_gfx\object_is_area=wc_menu_object()\object_is_area
        wc_work_gfx\object_area_42_path=wc_menu_object()\object_area_42_path
        wc_work_gfx\object_area_path=wc_menu_object()\object_area_path
        wc_work_gfx\object_add_to_quest=wc_menu_object()\object_add_to_quest
        wc_work_gfx\object_is_screen_text=wc_menu_object()\object_is_screen_text
        wc_work_gfx\object_NPC_show_text_on_collision=wc_menu_object()\object_NPC_show_text_on_collision
        wc_work_gfx\object_NPC_text_path=wc_menu_object()\object_NPC_text_path
        wc_work_gfx\object_NPC_internal_name=wc_menu_object()\object_NPC_internal_name
        wc_work_gfx\object_gfx_w=wc_menu_object()\object_gfx_w
        wc_work_gfx\object_gfx_h=wc_menu_object()\object_gfx_h
        wc_work_gfx\object_gfx_set_w_h=wc_menu_object()\object_gfx_set_w_h
        
        If wc_work_gfx\object_gfx_set_w_h=#True And wc_work_gfx\object_gfx_w>0 And wc_work_gfx\object_gfx_h >0
                    ZoomSprite(wc_work_gfx\_gfx_id,wc_work_gfx\object_gfx_w,wc_work_gfx\object_gfx_h)
        EndIf
        
        wc_work_with.f=SpriteWidth(wc_work_gfx\_gfx_id)
        wc_work_height.f=SpriteHeight(wc_work_gfx\_gfx_id)
        wc_work_gfx\_raster_x=wc_work_with.f
        wc_work_gfx\_raster_y=wc_work_height.f
      EndIf
      
      WC_CHECK_FOR_RESOURCE_CHANGE()
      
    Case #PB_Event_MoveWindow
      
      wc_asset_window\last_pos_x=WindowX(v_window_child_id)
      
      wc_asset_window\last_pos_y=WindowY(v_window_child_id)
    
  EndSelect
      
EndProcedure

Procedure WC_DELETE_MAP_OBJECT()
  Define _find.l=0
  
  If ListSize(map_object())<0
  ProcedureReturn #False   
  EndIf
  
  ResetList(map_object())
  
While NextElement(map_object()) 

    If map_object()\_full_screen=#False
  _find.l=SpriteCollision(wc_delpointer_gfx.l,WindowMouseX(v_window_parent_id),WindowMouseY(v_window_parent_id),map_object()\_gfx_id,map_object()\_x+wc_x_offset.i,map_object()\_y+wc_y_offset.i)
   EndIf

  If map_object()\_full_screen=#True
  _find.l=SpriteCollision(wc_delpointer_gfx.l,WindowMouseX(v_window_parent_id),WindowMouseY(v_window_parent_id),map_object()\_gfx_id,map_object()\_x,map_object()\_y)
   EndIf

  If _find.l And map_object()\_layer=wc_layer.b
    
    If IsSprite(map_object()\_gfx_id)
      FreeSprite(map_object()\_gfx_id)
      DeleteElement(map_object())
      WC_SAVE_WORLD(#USE_CACHE)
    EndIf
    
  EndIf
  
Wend
 
EndProcedure

Procedure WC_ADD_MAP_OBJECT(_mode.l)
  ;mode = default = user input mouse x/y
  ;mode =auto = procedural routine
  Define _max.l=0
  
  ;---------------------------------------- if routine first call listobject is the right source 
  
  If ListSize(map_object())>0
    Define _proc_max.l=map_object()\object_procedural_max_objects
    Define _x.l=map_object()\_x
    Define _y.l=map_object()\_y
    Define _rx.l=map_object()\object_procedural_x_offset
    Define _ry.l=map_object()\object_procedural_y_offset
    ;-------------------------------------------------------------------------------
  EndIf
  
    If _mode.l=#WC_DEFAULT
      
      If AddElement(map_object()) And IsSprite(wc_work_gfx\_gfx_id)<>0
        map_object()\_gfx_id=CopySprite(wc_work_gfx\_gfx_id,#PB_Any)
        If wc_work_gfx\object_gfx_set_w_h=#True
        ZoomSprite(map_object()\_gfx_id,wc_work_gfx\object_gfx_w,wc_work_gfx\object_gfx_h) 
        EndIf
        
        map_object()\_x=WindowMouseX(v_window_parent_id)-wc_x_offset.i-SpriteWidth(wc_work_gfx\_gfx_id)/2
        map_object()\_y=WindowMouseY(v_window_parent_id)-wc_y_offset.i-SpriteHeight(wc_work_gfx\_gfx_id)/2
        map_object()\_ai_path=wc_work_gfx\_ai_path
        map_object()\_layer=wc_layer.b
        map_object()\_full_screen=wc_work_gfx\_full_screen
        map_object()\_transparency=255-wc_work_gfx\_transparency
        map_object()\_object_auto_layer=wc_work_gfx\_object_auto_layer
        map_object()\_DO_NOT_SAVE_THIS_OBJECT=wc_work_gfx\_DO_NOT_SAVE_THIS_OBJECT
        map_object()\_DO_NOT_SHOW=#False
        
        map_object()\object_is_scroll_back_ground=wc_work_gfx\object_is_scroll_back_ground
        map_object()\object_use_random_angle=wc_work_gfx\object_use_random_angle   
        map_object()\object_use_shadow=wc_work_gfx\object_use_shadow
        map_object()\object_shadow_intense=wc_work_gfx\object_shadow_intense
        map_object()\object_add_to_quest=wc_work_gfx\object_add_to_quest
        map_object()\object_is_screen_text=wc_work_gfx\object_is_screen_text
        map_object()\object_NPC_show_text_on_collision=wc_work_gfx\object_NPC_show_text_on_collision
        map_object()\object_NPC_text_path=wc_work_gfx\object_NPC_text_path
        map_object()\object_NPC_internal_name=wc_work_gfx\object_NPC_internal_name
        RotateSprite(map_object()\_gfx_id,Random(wc_work_gfx\object_use_random_angle),#PB_Absolute)
        map_object()\object_counter_id=ElapsedMilliseconds()
        
        ;here we can correct the layer (we use auto layer for building the map):
        If wc_use_auto_layer.b=#True
          map_object()\_layer=wc_work_gfx\_object_auto_layer
        EndIf
                    
        If map_object()\_full_screen=#True
           ZoomSprite(map_object()\_gfx_id,wc_engine_screen_width.f,wc_engine_screen_height.f)
          map_object()\_x=0
          map_object()\_y=0
        EndIf
         
           WC_SAVE_WORLD(#USE_CACHE)
      EndIf
      
      EndIf ;element
      
 ;------------------------------------------ 
  
    If _mode.l=#WC_AUTO_PLACE
      
      map_object()\object_procedural_done=#True
      
    While _max.l<_proc_max.l
      
      If AddElement(map_object())
        
        map_object()\_gfx_id=CopySprite(wc_work_gfx\_gfx_id,#PB_Any)
        map_object()\_x=_x.l+Random(_rx.l)-SpriteWidth(wc_work_gfx\_gfx_id)/2
        map_object()\_y=_y.l+Random(_ry.l)-SpriteHeight(wc_work_gfx\_gfx_id)/2
        map_object()\_ai_path=wc_work_gfx\_ai_path
        map_object()\_layer=wc_work_gfx\_object_auto_layer
        wc_layer.b= map_object()\_layer
        map_object()\_full_screen=wc_work_gfx\_full_screen
        map_object()\_transparency=255-wc_work_gfx\_transparency
        map_object()\_DO_NOT_SAVE_THIS_OBJECT=wc_work_gfx\_DO_NOT_SAVE_THIS_OBJECT
        map_object()\_DO_NOT_SHOW=#False
        
        map_object()\object_use_shadow=wc_work_gfx\object_use_shadow
        map_object()\object_shadow_intense=wc_work_gfx\object_shadow_intense
        map_object()\object_use_random_angle=wc_work_gfx\object_use_random_angle  
        map_object()\object_add_to_quest=wc_work_gfx\object_add_to_quest
        map_object()\object_is_screen_text=wc_work_gfx\object_is_screen_text
        map_object()\object_NPC_show_text_on_collision=wc_work_gfx\object_NPC_show_text_on_collision
        map_object()\object_NPC_text_path=wc_work_gfx\object_NPC_text_path
        map_object()\object_NPC_internal_name=wc_work_gfx\object_NPC_internal_name
        RotateSprite(map_object()\_gfx_id,Random(wc_work_gfx\object_use_random_angle),#PB_Absolute)
        map_object()\object_counter_id=ElapsedMilliseconds()
        
        If map_object()\_full_screen=#True
         ZoomSprite(map_object()\_gfx_id,wc_engine_screen_width.f,wc_engine_screen_height.f)
          map_object()\_x=0
          map_object()\_y=0
        EndIf
        
      EndIf 
    
    _max.l+1
  Wend; add
  
  WC_SAVE_WORLD(#USE_CACHE)
  
EndIf ;mode

EndProcedure

Procedure WC_PARENT_WINDOW_EVENT(_event.l)
  Define _msg.l=0
  
  Select _event.l
      
    Case #PB_Event_CloseWindow
      
        _msg.l=MessageRequester("QUIT WORLDCREATOR?","QUIT?",#PB_MessageRequester_YesNo)
              If _msg.l=#PB_MessageRequester_Yes
                  WC_CLEAN_CACHE( v_clean_cache_on_exit.b)
              End
             EndIf
          
      Case #PB_Event_MaximizeWindow
       WC_SHOW_MAIN_SCREEN()
        
      Case #PB_Event_Menu
        WC_MENU_EVENT() 
    
  Case #PB_Event_LeftClick
        WC_ADD_MAP_OBJECT(#WC_DEFAULT)
    
  Case #PB_Event_RightClick
        WC_DELETE_MAP_OBJECT()  
    
      EndSelect    
  EndProcedure

Procedure WC_EVENT(_event.l)
  
  Select EventWindow()
      
    Case v_window_parent_id
      WC_PARENT_WINDOW_EVENT(_event.l)
      
    Case v_window_child_id
      WC_TOOL_WINDOW_EVENT(_event.l)
      
  EndSelect
  
EndProcedure

Procedure WC_KEYBOARD(_event_window.l)
  
  ExamineKeyboard()
  
  If _event_window.l=v_window_parent_id
    
    If KeyboardReleased(#PB_Key_Add)
    WC_TEMPLATE_TRANSPARENCY_ADD()  
    EndIf
    
        If KeyboardReleased(#PB_Key_Subtract)
        WC_TEMPLATE_TRANSPARENCY_REMOVE()  
    EndIf
      
    If   wc_map_move_per_pixel=#False
      
      If KeyboardReleased(#PB_Key_Left)
        wc_x_offset+wc_work_with.f
      EndIf
      
      If KeyboardReleased(#PB_Key_Right)
        wc_x_offset-wc_work_with.f
      EndIf
          
      If KeyboardReleased(#PB_Key_Up)
        wc_y_offset+wc_work_height.f
      EndIf
      
      If KeyboardReleased(#PB_Key_Down)
        wc_y_offset-wc_work_height.f
      EndIf
      
      If KeyboardReleased(#PB_Key_Return)
                WC_ADD_MAP_OBJECT(#WC_DEFAULT)
      EndIf
           
      If KeyboardReleased(#PB_Key_U)
        WC_MAP_OBJECT_UNDO()  
      EndIf
      
      If KeyboardReleased(#PB_Key_R)
        WC_MAP_OBJECT_REDO()  
      EndIf
      
    EndIf
    
    If KeyboardReleased(#PB_Key_Delete)
    WC_DELETE_MAP_OBJECT()  
    EndIf
      
    ;-----------------------
    
    If   wc_map_move_per_pixel=#True
      
      If KeyboardReleased(#PB_Key_Left)
        wc_x_offset+1
      EndIf
      
      If KeyboardReleased(#PB_Key_Right)
        wc_x_offset-1
      EndIf
          
      If KeyboardReleased(#PB_Key_Up)
        wc_y_offset-1
      EndIf
      
      If KeyboardReleased(#PB_Key_Down)
        wc_y_offset+1
      EndIf
      
      If KeyboardReleased(#PB_Key_Return)
             WC_ADD_MAP_OBJECT(#WC_DEFAULT)
      EndIf
          
      If KeyboardReleased(#PB_Key_U)
        WC_MAP_OBJECT_UNDO()  
      EndIf
      
    EndIf
      
    ;-------------------- if there is no object for map building  
    If wc_work_with.f=<1
      If KeyboardPushed(#PB_Key_Left)
                wc_x_offset+1
      EndIf
      
      If KeyboardPushed(#PB_Key_Right)
        wc_x_offset-1
      EndIf
    EndIf
    
    If wc_work_height.f<1
      
      If KeyboardPushed(#PB_Key_Up)
        wc_y_offset-1
      EndIf
      
      If KeyboardPushed(#PB_Key_Down)
        wc_y_offset+1
      EndIf
           
    EndIf
    ;------------------------------------------------------------------ 
    
  EndIf
  
EndProcedure
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 2136
; FirstLine = 2113
; Folding = -------
; EnableXP
; EnableUser
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant