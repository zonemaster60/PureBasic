;here we do all window handling

Procedure  WC_SET_DEFAULT_MENU_STATE_ON_START()
  
  ;set default menu state (check) on start
  
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_0,#True)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_1000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_2000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_3000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_5000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_10000,0)
  SetMenuItemState(v_menu_id.i,#WC_TIMER_SWITCH_MAP_ON_TRIGGER,0)
  
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_IS_ARENA_YES,0)
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_IS_ARENA_NO,#True)
  
  SetMenuItemState(v_menu_id.i,#WC_MENU_DAYTIMER_OFF,0)
  SetMenuItemState(v_menu_id.i,#WC_MENU_DAYTIMER_ON,#True)
  
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_RESPAWN_YES,#True)
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_RESPAWN_NO,0)
  
  SetMenuItemState(v_menu_id.i,#WC_VIEW_800_450,0)
  SetMenuItemState(v_menu_id.i,#WC_VIEW_1000_564,0)
  SetMenuItemState(v_menu_id.i,#WC_VIEW_1280_720,#True)
  SetMenuItemState(v_menu_id.i,#WC_VIEW_1440_1080,0)
  SetMenuItemState(v_menu_id.i,#WC_VIEW_1600_900,0)
  SetMenuItemState(v_menu_id.i,#WC_VIEW_1920_1080,0)
  
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_FIGHT,#True)
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_NO_FIGHT,0)
  
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_QUEST_SYSTEM_NO,#True)
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_USE_QUEST_SYSTEM_YES,0)
  
  SetMenuItemState(v_menu_id.i,#WC_SHOW_VERSION_NO,#True)
  SetMenuItemState(v_menu_id.i,#WC_SHOW_VERSION_YES,0)
  
  SetMenuItemState(v_menu_id.i,#WC_USE_AUTO_LAYER,0)
  SetMenuItemState(v_menu_id.i,#WC_DO_NOT_USE_AUTO_LAYER,#True)
  
  SetMenuItemState(v_menu_id.i,#WC_MAP_USE_VIEW_STAMP,0)
  SetMenuItemState(v_menu_id.i,#WC_MAP_DO_NOT_USE_VIEW_STAMP,#True)
  
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_PAUSE_NO,0)
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_PAUSE_YES,#True)
  
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_SCROLL,#True)
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_NO_SCROLL,0)
  
  SetMenuItemState(v_menu_id.i,#WC_MENU_NO_GLOBAL_EFFECT,#True)
  SetMenuItemState(v_menu_id.i,#WC_GLOBAL_EFFECT_SNOW,0)
  
  SetMenuItemState(v_menu_id.i,#WC_MENU_SHOW_SCROLL_TEXT,0)
   
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_ON,#True)
  SetMenuItemState(v_menu_id.i,#WC_MENU_MAP_GUI_OFF,0)
  
EndProcedure

Procedure WC_WIN_MENU_PARSER(_arg.s,_key.s)
  
  Select _key.s
      
    Case "#WC_MENU_TITLE"
      MenuTitle(_arg.s)
      
    Case "#WC_MENU_LOAD_MAP"
      MenuItem(#WC_MENU_LOAD_MAP,_arg.s)
      
    Case "#WC_MENU_SAVE_MAP"
      MenuItem(#WC_MENU_SAVE_MAP,_arg.s)
      
    Case "#WC_MENU_QUIT"
      MenuItem(#WC_MENU_QUIT,_arg.s)
            
    Case "#WC_MENU_GO_TO_MAP_START"
      MenuItem(#WC_MENU_GO_TO_MAP_START,_arg.s)
      
    Case "#WC_MENU_OPEN_ASSET_DRAWER"
      MenuItem(#WC_MENU_OPEN_ASSET_DRAWER,_arg.s)
      
    Case "#WC_MENU_SET_RESURCE"
      
      MenuItem(#WC_MENU_SET_RESURCE,_arg.s)
      
    Case "#WC_MENU_SET_RESOURCE_SOUND"
      MenuItem(#WC_MENU_SET_RESOURCE_SOUND,_arg.s)
      
    Case "#WC_MENU_OPEN_ASSET_SOUND_DRAWER"
      MenuItem(#WC_MENU_OPEN_ASSET_SOUND_DRAWER,_arg.s)
      
    Case "#WC_MENU_UPDATE_ASSETS"
      MenuItem(#WC_MENU_UPDATE_ASSETS,_arg.s)
      
    Case "#WC_MENU_RESTART_SYSTEM"
      
      MenuItem(#WC_MENU_RESTART_SYSTEM,_arg.s)
      
    Case "#WC_MENU_REDO"
      MenuItem(#WC_MENU_REDO,_arg.s)
      
    Case "#WC_MENU_UNDO"
      MenuItem(#WC_MENU_UNDO,_arg.s)
      
    Case "#WC_MENU_NEW"
      MenuItem(#WC_MENU_NEW,_arg.s)
      
    Case "#WC_LAYER_M1"
      MenuItem(#WC_LAYER_M1,_arg.s)
      
      Case "#WC_LAYER_M2"
        MenuItem(#WC_LAYER_M2,_arg.s)
        
        Case "#WC_LAYER_M3"
          MenuItem(#WC_LAYER_M3,_arg.s)
          
          Case "#WC_LAYER_M4"
            MenuItem(#WC_LAYER_M4,_arg.s)
            
            Case "#WC_LAYER_M5"
              MenuItem(#WC_LAYER_M5,_arg.s)
                           
               Case "#WC_LAYER_M6"
                MenuItem(#WC_LAYER_M6,_arg.s)
        
        Case "#WC_LAYER_M7"
          MenuItem(#WC_LAYER_M7,_arg.s)
          
          Case "#WC_LAYER_M8"
            MenuItem(#WC_LAYER_M8,_arg.s)
            
            Case "#WC_LAYER_M9"
              MenuItem(#WC_LAYER_M9,_arg.s)
                                     
                Case "#WC_LAYER_M10"
                  MenuItem(#WC_LAYER_M10,_arg.s)
                  
                    Case "#WC_LAYER_M11"
                      MenuItem(#WC_LAYER_M11,_arg.s)
                      
                        Case "#WC_LAYER_M12"
                          MenuItem(#WC_LAYER_M12,_arg.s)
                          
                          Case "#WC_LAYER_M13"
                              MenuItem(#WC_LAYER_M13,_arg.s)
                              
                              Case "#WC_LAYER_M14"
                                  MenuItem(#WC_LAYER_M14,_arg.s)
                                  
                                Case "#WC_LAYER_M15"
                                  MenuItem(#WC_LAYER_M15,_arg.s)
                                                
            Case "#WC_MENU_MOVE_BY_OBJECT_GRID"
              MenuItem(#WC_MENU_MOVE_BY_OBJECT_GRID,_arg.s)
      
    Case "#WC_LAYER_0"
      MenuItem(#WC_LAYER_0,_arg.s)
          
       Case "#WC_LAYER_1"
         MenuItem(#WC_LAYER_1,_arg.s)
       
          Case "#WC_LAYER_2"
            MenuItem(#WC_LAYER_2,_arg.s)
           
             Case "#WC_LAYER_3"
               MenuItem(#WC_LAYER_3,_arg.s)
                
                Case "#WC_LAYER_4"
                  MenuItem(#WC_LAYER_4,_arg.s)

                   Case "#WC_LAYER_5"
                     MenuItem(#WC_LAYER_5,_arg.s)
                     
                      Case "#WC_LAYER_6"
                        MenuItem(#WC_LAYER_6,_arg.s)
                        
                         Case "#WC_LAYER_7"
                           MenuItem(#WC_LAYER_7,_arg.s)
                           
                            Case "#WC_LAYER_8"
                              MenuItem(#WC_LAYER_8,_arg.s)
                              
                               Case "#WC_LAYER_9"
                                 MenuItem(#WC_LAYER_9,_arg.s)
                                 
                                  Case "#WC_LAYER_10"
                                    MenuItem(#WC_LAYER_10,_arg.s)
                        
                      Case "#WC_SHOW_ALL_LAYER"  
                        MenuItem(#WC_SHOW_ALL_LAYER,_arg.s)
                        
                      Case "#WC_SHOW_ACTUAL_LAYER"
                        MenuItem(#WC_SHOW_ACTUAL_LAYER,_arg.s)
                        
                      Case "#WC_MENU_SHOW_LAYER_ID"
                        MenuItem(#WC_MENU_SHOW_LAYER_ID,_arg.s)
                        
                      Case "#WC_MENU_DO_NOT_SHOW_LAYER_ID"
                        MenuItem(#WC_MENU_DO_NOT_SHOW_LAYER_ID,_arg.s)
                                            
                      Case "#WC_MENU_SHOW_ENGINE_AREA"
                        MenuItem(#WC_MENU_SHOW_ENGINE_AREA,_arg.s)
                        
                      Case "#WC_MENU_MOVE_MAP_PER_PIXEL"
                        MenuItem(#WC_MENU_MOVE_MAP_PER_PIXEL,_arg.s)
                        
                      Case "#WC_MENU_INFO"
                        MenuItem(#WC_MENU_INFO,_arg.s)
                        
                      Case "#WC_MENU_BLANK"
                        MenuItem(#WC_MENU_BLANK,_arg.s)
                                             
                      Case "#WC_MENU_MOVE_MAP_OBJECT_SIZE"
                        MenuItem(#WC_MENU_MOVE_MAP_OBJECT_SIZE,_arg.s)
                        
                      Case "#WC_USE_RASTER_YES"
                        MenuItem(#WC_USE_RASTER_YES,_arg.s)
                        
                         Case "#WC_USE_RASTER_NO"
                           MenuItem(#WC_USE_RASTER_NO,_arg.s)
                           
                         Case "#WC_DO_NOT_USE_AUTO_LAYER"
                           MenuItem(#WC_DO_NOT_USE_AUTO_LAYER,_arg.s)
                           
                         Case "#WC_USE_AUTO_LAYER"
                           MenuItem(#WC_USE_AUTO_LAYER,_arg.s)
                           
                         Case "#WC_MENU_START_PROCEDURAL"
                           MenuItem(#WC_MENU_START_PROCEDURAL,_arg.s)
                           
                         Case "#WC_ADD_SOUND_TO_MAP"
                           If wc_sound_system_valid.b=#True
                             MenuItem(#WC_ADD_SOUND_TO_MAP,_arg.s)
                           EndIf
                                                   
                         Case "#WC_REMOVE_SOUND_FROM_MAP"
                                                  
                            If wc_sound_system_valid.b=#True
                              MenuItem(#WC_REMOVE_SOUND_FROM_MAP,_arg.s)
                            Else
                               MenuItem(#WC_REMOVE_SOUND_FROM_MAP,"NO SOUND HARDWARE FOUND")
                            EndIf                        
                           
                          Case "#WC_SOUND_PLAY"
                             If wc_sound_system_valid.b=#True
                               MenuItem(#WC_SOUND_PLAY,_arg.s)
                             Else
                                MenuItem(#WC_SOUND_PLAY,"NO SOUND HARDWARE FOUND")
                             EndIf
                                                      
                           Case "#WC_SOUND_STOP"
                              If wc_sound_system_valid.b=#True
                                MenuItem(#WC_SOUND_STOP,_arg.s)
                              Else
                                 MenuItem(#WC_SOUND_PLAY,"NO SOUND HARDWARE FOUND")
                              EndIf
                              
                            Case "#WC_MENU_MAP_USE_QUEST_SYSTEM_YES"
                              MenuItem(#WC_MENU_MAP_USE_QUEST_SYSTEM_YES,_arg.s)
                              
                              Case "#WC_MENU_MAP_USE_QUEST_SYSTEM_NO"
                              MenuItem(#WC_MENU_MAP_USE_QUEST_SYSTEM_NO,_arg.s)
                              
                            Case "#WC_MENU_MAP_PAUSE_NO"
                              MenuItem(#WC_MENU_MAP_PAUSE_NO,_arg.s)
                              
                            Case "#WC_MENU_MAP_USE_RESPAWN_NO"
                              MenuItem(#WC_MENU_MAP_USE_RESPAWN_NO,_arg.s)
                              
                            Case "#WC_MENU_MAP_USE_RESPAWN_YES"
                              MenuItem(#WC_MENU_MAP_USE_RESPAWN_YES,_arg.s)
                              
                            Case "#WC_MENU_MAP_PAUSE_YES"
                              MenuItem(#WC_MENU_MAP_PAUSE_YES,_arg.s)
                              
                            Case "#WC_MENU_MAP_FIGHT"
                              MenuItem(#WC_MENU_MAP_FIGHT,_arg.s)
                              
                            Case "#WC_MENU_MAP_NO_FIGHT"
                              MenuItem(#WC_MENU_MAP_NO_FIGHT,_arg.s)
                              
                            Case "#WC_MENU_MAP_IS_ARENA_YES"
                              MenuItem(#WC_MENU_MAP_IS_ARENA_YES,_arg.s)
                              
                            Case "#WC_MENU_MAP_IS_ARENA_NO"
                              MenuItem(#WC_MENU_MAP_IS_ARENA_NO,_arg.s)
                                                           
                                Case "#WC_MENU_DAYTIMER_ON"
                                   MenuItem(#WC_MENU_DAYTIMER_ON,_arg.s)
                                   
                                 Case "#WC_MENU_DAYTIMER_OFF"
                                   MenuItem(#WC_MENU_DAYTIMER_OFF,_arg.s)
                                                          
                            Case "#WC_MENU_ADD_MAP_TEMPLATE"
                              MenuItem(#WC_MENU_ADD_MAP_TEMPLATE,_arg.s)
                                                 
                            Case "#WC_MENU_TEMPLATE_SHOW"
                              MenuItem(#WC_MENU_TEMPLATE_SHOW,_arg.s)
                              
                            Case "#WC_MAP_INFO"
                              MenuItem(#WC_MAP_INFO,_arg.s)
                              
                           Case "#WC_SELECT_ARENA_GFX"
                             MenuItem(#WC_SELECT_ARENA_GFX,_arg.s)
                              
                           Case "#WC_HIDE_TEMPLATE"
                             MenuItem(#WC_HIDE_TEMPLATE,_arg.s)
                              
                           Case "#WC_TEMPLATE_TRANSPARENCY_ADD"
                             MenuItem(#WC_TEMPLATE_TRANSPARENCY_ADD,_arg.s)
                              
                           Case "#WC_TEMPLATE_TRANSPARENCY_REMOVE"
                             MenuItem(#WC_TEMPLATE_TRANSPARENCY_REMOVE,_arg.s)
                             
                           Case "#WC_VIEW_800_450"
                             MenuItem(#WC_VIEW_800_450,_arg.s)
                             
                           Case  "#WC_VIEW_1000_564"
                             MenuItem(#WC_VIEW_1000_564,_arg.s)
                             
                           Case  "#WC_VIEW_1280_720"
                               MenuItem(#WC_VIEW_1280_720,_arg.s)
                             
                             Case "#WC_VIEW_1440_1080"
                                 MenuItem(#WC_VIEW_1440_1080,_arg.s)
                             
                               Case  "#WC_VIEW_1600_900"
                                   MenuItem(#WC_VIEW_1600_900,_arg.s)
                             
                                 Case "#WC_VIEW_1920_1080"
                                   MenuItem(#WC_VIEW_1920_1080,_arg.s)
                                   
                                 Case "#WC_SHOW_VERSION_YES"
                                   MenuItem(#WC_SHOW_VERSION_YES,_arg.s)
                                                                  
                                 Case "#WC_SHOW_VERSION_NO"
                                   MenuItem(#WC_SHOW_VERSION_NO,_arg.s)
                                   
                                 Case "#WC_TIMER_SWITCH_MAP_1000"
                                   MenuItem(#WC_TIMER_SWITCH_MAP_1000,_arg.s)
                                   
                                 Case "#WC_TIMER_SWITCH_MAP_2000"
                                    MenuItem(#WC_TIMER_SWITCH_MAP_2000,_arg.s)
                                   
                                  Case "#WC_TIMER_SWITCH_MAP_3000"
                                     MenuItem(#WC_TIMER_SWITCH_MAP_3000,_arg.s)
                                     
                                   Case "#WC_TIMER_SWITCH_MAP_0"
                                     MenuItem(#WC_TIMER_SWITCH_MAP_0,_arg.s)
                               
                                   Case "#WC_SWITCH_MAP_TOUCH"
                                     MenuItem(#WC_SWITCH_MAP_TOUCH,_arg.s)
                                     
                                   Case "#WC_SWITCH_MAP_TOUCH_DESELECT"
                                     MenuItem(#WC_SWITCH_MAP_TOUCH_DESELECT,_arg.s)
                                     
                                   Case "#WC_TIMER_SWITCH_MAP_5000"
                                     MenuItem(#WC_TIMER_SWITCH_MAP_5000,_arg.s)
                                     
                                   Case "#WC_TIMER_SWITCH_MAP_10000"
                                     MenuItem(#WC_TIMER_SWITCH_MAP_10000,_arg.s)
                                     
                                   Case "#WC_TIMER_SWITCH_MAP_ON_TRIGGER"
                                     MenuItem(#WC_TIMER_SWITCH_MAP_ON_TRIGGER,_arg.s)
                             
                                   Case "#WC_MAP_SHOW_TIMER"
                                     MenuItem(#WC_MAP_SHOW_TIMER,_arg.s)
                                     
                                   Case "#WC_MAP_SHOW_TIMER_NOT"
                                     MenuItem(#WC_MAP_SHOW_TIMER_NOT,_arg.s)
                                     
                                   Case "#WC_MAP_DO_NOT_USE_BLACK_STAMP"
                                     MenuItem(#WC_MAP_DO_NOT_USE_VIEW_STAMP,_arg.s)
                                     
                                   Case "#WC_MAP_USE_BLACK_STAMP"
                                     MenuItem(#WC_MAP_USE_VIEW_STAMP,_arg.s)
                                     
                                   Case "#WC_MENU_MAP_NO_SCROLL"
                                     MenuItem(#WC_MENU_MAP_NO_SCROLL,_arg.s)
                                     
                                   Case "#WC_MENU_MAP_SCROLL"
                                     MenuItem(#WC_MENU_MAP_SCROLL,_arg.s)
                                     
                                   Case "#WC_MENU_NO_GLOBAL_EFFECT"
                                     MenuItem(#WC_MENU_NO_GLOBAL_EFFECT,_arg.s)
                                     
                                   Case "#WC_MENU_GLOBAL_EFFECT_SNOW"
                                     MenuItem(#WC_MENU_GLOBAL_EFFECT_SNOW,_arg.s)
                                     
                                   Case "#WC_MENU_SHOW_SCROLL_TEXT"
                                     MenuItem(#WC_MENU_SHOW_SCROLL_TEXT,_arg.s)

                                   Case "#WC_MENU_MAP_GUI_ON"
                                     MenuItem(#WC_MENU_MAP_GUI_ON,_arg.s)
                                     
                                   Case "#WC_MENU_MAP_GUI_OFF"
                                     MenuItem(#WC_MENU_MAP_GUI_Off,_arg.s)
                                     
                                                          
    EndSelect

EndProcedure

Procedure WC_SET_WINDOW_MENU(v_menu_script_path.s, v_window_parent_id.l)
  ;now stick the menue to the window
  Define _is_file.l
  Define _arg.s=""
  Define _key.s=""
  
  _is_file.l=ReadFile(#PB_Any,v_menu_script_path.s)
 
  If IsFile(_is_file.l)
         
   While Not Eof(_is_file.l)
        
      _key.s=ReadString(_is_file.l)
      _arg.s=ReadString(_is_file.l)
            WC_WIN_MENU_PARSER(_arg.s,_key.s)
          Wend
         
    CloseFile(_is_file.l)
        Else
      
      WC_ERROR(#WC_ERROR_FILE_NOT_FOUND,v_menu_script_path.s)
        EndIf
    
EndProcedure

Procedure WC_OPEN_OBJECT_WINDOW()
  ;open our tile window
  
  If v_window_child_w.f<1
  v_window_child_w.f=DesktopWidth(0)*0.90  
  EndIf
  
  v_window_child_id=OpenWindow(#PB_Any,wc_asset_window\last_pos_x,wc_asset_window\last_pos_y,v_window_child_w.f/DesktopResolutionX(),v_window_child_h.f/DesktopResolutionY(),"",#PB_Window_TitleBar|#PB_Window_MinimizeGadget)
  SetWindowColor(v_window_child_id,RGB(50,50,50))
    EndProcedure

Procedure WC_OPEN_WINDOW()
    v_window_parent_id=OpenWindow(#PB_Any,v_window_main_x.f,v_window_main_y.f,v_window_w.f/DesktopResolutionX()/2,v_window_h.f/DesktopResolutionX()/2,"WORLDCREATOR MAIN WINDOW",#PB_Window_SystemMenu|#PB_Window_TitleBar|#PB_Window_MinimizeGadget|#PB_Window_SizeGadget)
    v_menu_id.i= CreateMenu(#PB_Any,WindowID(v_window_parent_id))
        
    If v_menu_id.i=0
      WC_ERROR(#WC_ERROR_CAN_NOT_CREATE_MENU,"CAN NOT CREATE MENU")
    EndIf

    v_window_screen_id=OpenWindowedScreen(WindowID(v_window_parent_id),1,1,v_window_w.f,v_window_h.f)
    
    wc_asset_window\last_pos_y=v_window_main_y+v_window_h.f/DesktopResolutionX()/2+48
    wc_asset_window\last_pos_x=v_window_main_x
  EndProcedure


; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 403
; Folding = -
; EnableXP
; EnableUser
; DPIAware
; CPU = 1
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant