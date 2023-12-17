;display routine
Procedure  WC_SHOW_ENGINE_AREA()  
  
  If wc_engine_screen_area_show.b=#False
  ProcedureReturn #False  
  EndIf
  
  StartDrawing(ScreenOutput())
        DrawingMode(#PB_2DDrawing_Outlined|#PB_2DDrawing_XOr )
        Box(1,1,wc_engine_screen_width.f,wc_engine_screen_height.f,RGB(200,200,200))
  StopDrawing()
  
EndProcedure

Procedure WC_SHOW_LAYER_INFO()
  
 ; If wc_show_layer_id.b=#False  ;not working for now....
  ProcedureReturn #False  
 ; EndIf
  
  StartDrawing(ScreenOutput())
  DrawingMode(#PB_2DDrawing_Outlined)
  DrawText(map_object()\_x+wc_x_offset.i,map_object()\_y+wc_y_offset.i,Str(map_object()\_layer),RGB(200,200,200))
  StopDrawing()
  
EndProcedure
       
       
Procedure WC_CLEAR_SCREEN()
  ClearScreen(RGB(0,0,0))
EndProcedure

Procedure WC_SHOW_TEMPLATE()
   If wc_template\is_valid=#True
  DisplayTransparentSprite(wc_template\id, wc_x_offset,wc_y_offset,wc_template\transparency)
  EndIf
EndProcedure

Procedure WC_SHOW_SCREEN_BUFFER()
 WC_SHOW_ENGINE_AREA()  
    FlipBuffers()
 EndProcedure
 
Procedure  WC_SHOW_MAIN_SCREEN()
  Define  _text.s="WORKLAYER:"+Str(wc_layer.b)+"SHOWLAYER: "+Str(wc_layer_show.b)+" FOVW:"+Str(wc_engine_screen_width.f)+" FOVH:"+Str(wc_engine_screen_height.f)+" QUESTS: "+Str(wc_quest_book.l)+" MAPNAME: "+GetFilePart(wc_global_load_save_path.s)+" MAPUSEQUEST: "+Str(wc_map_use_quest_system.b)+"       Code & Concept (C) Deutschmann Walter"
  
  If ListSize(map_object())<0
  ProcedureReturn #False  
  EndIf
  
  ResetList(map_object())
  WC_CLEAR_SCREEN()
  WC_SHOW_TEMPLATE()  ;here we show teh template 
  ;----------- sort the tiles per layer
  
  SortStructuredList(map_object(),#PB_Sort_Ascending  ,OffsetOf(map_objects\_layer),TypeOf(map_objects\_layer))

  While NextElement(map_object())
    
  ;  WC_IS_IN_SCREEN()
    
;  If map_object()\object_is_in_screen=#True
    ;     
    SpriteQuality(#PB_Sprite_BilinearFiltering)
    
    If IsSprite(map_object()\_gfx_id)
        
    If wc_layer_show.b<>-127
      
      If wc_layer_show.b=map_object()\_layer
        DisplayTransparentSprite(map_object()\_gfx_id,map_object()\_x+wc_x_offset.i,map_object()\_y+wc_y_offset.i,map_object()\_transparency) 
      EndIf
    Else
           
      If map_object()\_full_screen=#False
        
        If map_object()\object_use_shadow=1
          ;16=for developement fixed value for shadow offset
          DisplayTransparentSprite(map_object()\_gfx_id,map_object()\_x+wc_x_offset.i+16,map_object()\_y+wc_y_offset.i+16,map_object()\object_shadow_intense,RGB(0,0,0))
        EndIf
        
        DisplayTransparentSprite(map_object()\_gfx_id,map_object()\_x+wc_x_offset.i,map_object()\_y+wc_y_offset.i,map_object()\_transparency)
      Else
        DisplayTransparentSprite(map_object()\_gfx_id,map_object()\_x,map_object()\_y,map_object()\_transparency)
      EndIf
      
    EndIf
    
    EndIf   
    
      WC_SHOW_LAYER_INFO()
    
 ; EndIf
  
  Wend
  
  ;the actual map tile which is attached to mouse pointer 
  If IsSprite(wc_work_gfx\_gfx_id)
        DisplayTransparentSprite(wc_work_gfx\_gfx_id,WindowMouseX(v_window_parent_id)-SpriteWidth(wc_work_gfx\_gfx_id)/2,WindowMouseY(v_window_parent_id)-SpriteHeight(wc_work_gfx\_gfx_id)/2)  
  EndIf
  
  If IsSprite(wc_delpointer_gfx.l) 
    DisplayTransparentSprite(wc_delpointer_gfx.l,WindowMouseX(v_window_parent_id),WindowMouseY(v_window_parent_id))  
  EndIf
 ; ---------------------------------------------------------------------------------------------------------------------------------------------------------

  WC_SHOW_SCREEN_BUFFER()
    ;show some informations like mouseposition and ammount of tiles used in the map. cache shows the undo/redo map saves.
    SetWindowTitle(v_window_parent_id,"MAP OBJECT ID: "+Str(ListSize(map_object()))+" MOUSEX: "+Str(WindowMouseX(v_window_parent_id)+wc_x_offset.i)+"  MOUSEY: "+Str(WindowMouseY(v_window_parent_id)+wc_y_offset.i)+_text.s+"   "+wc_auto_object.s+"   MAP GLOBAL SOUND:"+wc_full_sound_path.s)
    
  EndProcedure




; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 110
; FirstLine = 88
; Folding = --
; Optimizer
; EnableXP
; EnableUser
; DPIAware
; EnableOnError
; CPU = 1
; SubSystem = DirectX9
; DisableDebugger
; Compiler = PureBasic 6.00 Beta 5 (Windows - x64)
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant