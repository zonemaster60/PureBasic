;parser for all settings

Procedure WC_SETUP(_key.s,_arg.s)
  
  Select _key.s
      
    Case   "WINDOW_MAIN_W"
      
      v_window_w.f=v_desktop_w.f-ValF(_arg.s)
      
          Case "WINDOW_MAIN_H"
      
      v_window_h.f=v_desktop_h.f-ValF(_arg.s)
      
    Case "SOURCE_WINDOW_H"
      v_window_child_h.f=ValF(_arg.s)
           
    Case "SOURCE_WINDOW_W"
      v_window_child_w.f=ValF(_arg.s)
               
    Case "RESOURCE_FILE_SOUND"
        v_resource_name_sound.s=_arg.s
                
    Case "RESOURCE_FILE"
      v_resource_name.s=_arg.s
      
    Case "RESOURCE_TYP"
      v_resource_type.s=_arg.s
      
    ;Case "TRANSPARENCY"
   ;   WC_GETCOLOR(_arg.s)
      
    Case "DELPOINTER"
      
            wc_delpointer_path.s=v_base.s+_arg.s
            
          Case "ENGINE_SCREEN_W"
            wc_engine_screen_width.f=ValF(_arg.s)
            
          Case "ENGINE_SCREEN_H"
            wc_engine_screen_height.f=ValF(_arg.s)
            
          Case "CACHE"
            v_cache_dir.s=v_base.s+_arg.s
            
            CreateDirectory(v_cache_dir.s)
            
          Case "CLEAN_CACHE"
            v_clean_cache_on_exit.b=Val(_arg.s)
            If v_clean_cache_on_exit.b=1
            v_clean_cache_on_exit.b=#True  
          EndIf
 
   EndSelect
     
  EndProcedure  
  
Procedure WC_GLOBAL(_global_ini_file.s)
  Define _is_file.l=0
  Define _arg.s=""
  Define _key.s=""
     
  _is_file.l=ReadFile(#PB_Any,_global_ini_file.s)  
  
  If IsFile(_is_file.l)
  Else
     WC_ERROR(#WC_ERROR_FILE_NOT_FOUND,_global_ini_file)
   EndIf
  
  While Not Eof(_is_file.l)
  _key.s=ReadString(_is_file.l)
  _arg.s=ReadString(_is_file.l)
  WC_SETUP(_key.s,_arg.s)
  Wend

CloseFile(_is_file.l)
  
EndProcedure

Procedure WC_INI_BASE()
  
  ;basic ini node parser (from here we go to all ini systems)
  
  Define _is_file.l=0
  Define _arg.s=""
  Define _key.s=""
   
  _is_file.l=ReadFile(#PB_Any,v_base.s+"ini.wc")  ;basic node for ini
  
  If IsFile(_is_file.l)
    
    While Not Eof(_is_file.l)
      
      _key.s=ReadString(_is_file.l)
      _arg.s=ReadString(_is_file.l)
      
      Select _key.s
          
        Case "INIFILE"
          v_ini_path.s=v_base.s+_arg.s
          
        Case "WORLD_CREATOR_MENU"
          v_menu_script_path.s=v_base.s+_arg.s
                  
      EndSelect
      
    Wend
    
    CloseFile(_is_file.l)
    
  Else
    WC_ERROR(#WC_ERROR_FILE_NOT_FOUND,v_base.s+"ini.wc")
  EndIf
  
EndProcedure

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 113
; FirstLine = 90
; Folding = -
; Optimizer
; EnableXP
; EnableUser
; CPU = 1
; SubSystem = DirectX9
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant