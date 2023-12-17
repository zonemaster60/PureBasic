;here we see all routines for IO
  
Procedure E_GET_KEY(_value.s,_file_id.i)
  
  Select _value.s
      
    Case "WINDOW_POSITION_x"
      creator_window\window_x=ValF(ReadString(_file_id.i))
      
    Case "WINDOW_POSITION_Y"
      creator_window\window_y=ValF(ReadString(_file_id.i))
      
    Case "WINDOW_WIDTH"
      creator_window\window_widht=ValF(ReadString(_file_id.i))
      
    Case "WINDOW_HEIGHT"
      creator_window\window_height=ValF(ReadString(_file_id.i))

    Case "WINDOW_TITLE"
      creator_window\window_title=ReadString(_file_id.i)
      
    Case "GADGET_SIZE_W"
      creator\creator_text_gadget_w=ValF(ReadString(_file_id.i))
      
    Case "GADGET_SIZE_H"
      creator\creator_text_gadget_h=ValF(ReadString(_file_id.i))
      
    Case "GADGET_MAX_GADGET"
      creator\creator_max_text_gadget=Val(ReadString(_file_id.i))
      
    Case "DEFAULT_OBJECT"
      creator\creator_default_object_file=Trim(ReadString(_file_id.i))
      
    Case "DNA_SUFFIX"
      creator\creator_dna_file_suffix=Trim(ReadString(_file_id.i))
      
    Case "MENU_INI_FILE"
      creator\creator_menu_ini_file=Trim(ReadString(_file_id.i))
      
    Case "OBJECT_KEY_WORD"
      creator\creator_object_key_word=Trim(ReadString(_file_id.i))
      
    Case "MAX_ROW"
      creator\creator_max_row=Val(ReadString(_file_id.i))
          
    Case "SEARCH_STRING_SIZE"
      creator\creator_search_size=Val(ReadString(_file_id.i))
      
    Case "CREATOR_CACHE"
      creator\creator_dummy=Trim(ReadString(_file_id.i))
      
  EndSelect
  
EndProcedure

Procedure E_PARSE_CREATOR_INI_FILE(_ini_file.s)
  Define _file_id.i=0
  Define _key_word.s=""
  Define _value.s=""
  
  _file_id.i=ReadFile(#PB_Any,_ini_file.s)
  
  If IsFile(_file_id.i)=0
    E_ERROR(#ERROR_INI_FILE) 
    ProcedureReturn #False
  EndIf
  
  ;read the keywords, line by line:
  While Not (Eof(_file_id.i))
   E_GET_KEY(UCase(Trim(ReadString(_file_id.i))),_file_id.i)
      
  Wend
  
  CloseFile(_file_id.i)
  
  ;some default settings without script:
  creator\creator_text_gadget_offset_x=1
  creator\creator_text_gadget_offset_y=1
  creator\creator_dummy=creator\creator_dummy+"."+creator\creator_dna_file_suffix
  
EndProcedure

Procedure E_SET_MENU(_key.s,_file_id.i)
  
  Select _key.s
      
    Case "MENUE_TITLE"
      MenuTitle(ReadString(_file_id.i))
      
    Case "#E_MENU_LOAD_DEFAULT"
      
      MenuItem(#E_MENU_LOAD_DEFAULT,ReadString(_file_id.i))
         
    Case "#E_MENU_SAVE_DEFAULT"
      MenuItem(#E_MENU_SAVE_DEFAULT,ReadString(_file_id.i))
         
    Case "#E_MENU_LOAD_FILE"
      MenuItem(#E_MENU_LOAD_FILE,ReadString(_file_id.i))
         
    Case "#E_MENU_SAVE_AS"
      MenuItem(#E_MENU_SAVE_AS,ReadString(_file_id.i))
         
     Case "#E_MENU_SET_GFX_OBJECT"
      MenuItem(#E_MENU_SET_GFX_OBJECT,ReadString(_file_id.i))
         
    Case "#E_MENU_ABOUT"
      MenuItem(#E_MENU_ABOUT,ReadString(_file_id.i))
         
    Case "#E_MENU_QUIT"
      MenuItem(#E_MENU_QUIT,ReadString(_file_id.i))
      
    Case "#E_MENU_SAVE"
      MenuItem(#E_MENU_SAVE,ReadString(_file_id.i))
              
    Case "#E_MENU_GFX_TO_FRONT"
      MenuItem(#E_MENU_GFX_TO_FRONT,ReadString(_file_id.i))
                
    Case "#E_MENU_ACTIVATE_NOT_ACTIVATED"
      MenuItem(#E_MENU_ACTIVATE_NOT_ACTIVATED,ReadString(_file_id.i))
                 
    Case "#E_MENU_SHOW_ASSET_FOLDER"
      MenuItem(#E_MENU_SHOW_ASSET_FOLDER,ReadString(_file_id.i))

    Case "#E_MENU_Ai42_REBUILD"
      MenuItem(#E_MENU_Ai42_REBUILD,ReadString(_file_id.i))
      
EndSelect
  
EndProcedure

Procedure E_PARSE_MENU(_file_id.i)
  
  Define _key.s
  Define _value.s
  
  
  While Not Eof(_file_id.i)
    
    _key.s=ReadString(_file_id.i)
    E_SET_MENU(_key.s,_file_id.i)
    
  Wend
  
EndProcedure

Procedure E_ADD_MENU()
   
  Define _file_id.i=0
  
  _file_id.i=ReadFile(#PB_Any,creator\creator_menu_ini_file)
  
  If IsFile(_file_id.i)=0
    E_ERROR(#ERROR_MENU_INI_FILE)
  ProcedureReturn #False  
  EndIf
  
  creator_window\window_menu_id=1
  CreateMenu(creator_window\window_menu_id,WindowID(creator_window\window_id))
  E_PARSE_MENU(_file_id.i)
  CloseFile(_file_id.i)
   
EndProcedure


; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 160
; FirstLine = 138
; Folding = -
; Optimizer
; EnableXP
; EnableUser
; DPIAware
; EnableOnError
; CPU = 1
; SubSystem = DirectX9
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0