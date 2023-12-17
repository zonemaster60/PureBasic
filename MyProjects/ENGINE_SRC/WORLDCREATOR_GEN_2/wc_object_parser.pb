
;object structure 
;used in object pool for creation

Declare WC_OPEN_OBJECT_WINDOW()

Declare E_GET_PACK_GFX_AND_CONVERT_DISTI(_void.s)
Declare E_GET_PACK_GFX_AND_REBUILD_DISTI(_void.s)

Structure wc_work_gfx_s
  _gfx_id.l
  _gfx_path.s
  _ai_path.s
  _full_screen.b
  object_is_scroll_back_ground.b
  _raster_x.l
  _raster_y.l
  _transparency.l
  _object_auto_layer.b ;internal use!
  _DO_NOT_SAVE_THIS_OBJECT.b
   object_internal_name.s
  object_use_random_angle.f
  object_use_shadow.b
  object_shadow_intense.l
  object_is_area.b
  object_area_42_path.s
  object_area_path.s
  object_add_to_quest.b
  object_is_screen_text.b
  object_NPC_show_text_on_collision.b
  object_NPC_text_path.s
  object_NPC_internal_name.s
  object_gfx_w.f
  object_gfx_h.f
  object_gfx_set_w_h.b
   EndStructure 

Structure menu_objects
  _gfx_id.l   ;id for the image
  _gfx_path.s ;path for the gfx file
  _ai_path.s
  _x.l
  _y.l
  _type.s  ;png, tiff,bmb
  _full_screen.b   ; true/false
  object_is_scroll_back_ground.b
  _transparency.l
  _object_auto_layer.b ;internal use!
  _DO_NOT_SAVE_THIS_OBJECT.b
  _alpha_blend.l
  _w.f
  _h.f
  object_is_procedural_base.b ; parentobject like stone, mud, .... is need as base for automatic generated objects
  object_procedural_seed.l    ;random seed (0=nothing) random result of 1= place procedural object (100=chance 1 of 100 to place object)
  object_procedural_source_name.s;holds the name of the sourcefile (its the internal objectname)
  object_procedural_done.b       ;is set to 1 (#true) if object placement is finished, so this object will not generate more foliage.
  object_procedural_x_offset.f   ;for random placement (fill it with a number from 0 to x )
  object_procedural_y_offset.f  
  object_internal_name.s
  object_gadget_id.l
  object_procedural_max_objects.l
  object_use_random_angle.f
  object_use_shadow.b
  object_shadow_intense.l
  object_is_area.b
  object_area_42_path.s
  object_area_path.s
  object_container_type.l  ;used for some gadgetsort (default=0, area=1 )  ;we sort by intensity... 0....1.......2....x
  object_add_to_quest.b
  object_is_screen_text.b
  object_NPC_show_text_on_collision.b
  object_NPC_text_path.s
  object_NPC_internal_name.s
  object_not_in_map_editor.b
  object_gfx_h.f
  object_gfx_w.f
  object_gfx_set_w_h.b
EndStructure
;--------------------------------------------------------------------------------------------------------------------------

;-------------------------THE WORCSPACE FOR MAPCREATION STORES THE COMPLETE MAP

Structure map_objects
  _gfx_id.l
  _ai_path.s
  _x.l
  _y.l
  _layer.b ;up to 128 layers (0....127)
  _full_screen.b
  object_is_scroll_back_ground.b
  _transparency.l
  _object_auto_layer.b ;internal use!
  _DO_NOT_SAVE_THIS_OBJECT.b
  _DO_NOT_SHOW.b  ;redo/undo
  _alpha_blend.l
  object_is_procedural_base.b ; parentobject like stone, mud, .... is need as base for automatic generated objects
  object_procedural_seed.l    ;random seed (0=nothing) random result of 1= place procedural object (100=chance 1 of 100 to place object)
  object_procedural_max_objects.l
  object_procedural_source_name.s;holds the name of the sourcefile (its the internal objectname)
  object_procedural_done.b       ;is set to 1 (#true) if object placement is finished, so this object will not generate more foliage.
  object_procedural_x_offset.f   ;for random placement (fill it with a number from 0 to x )
  object_procedural_y_offset.f  
  object_internal_name.s
  object_use_random_angle.f
  object_use_shadow.b
  object_shadow_intense.l
  object_add_to_quest.b
  object_is_screen_text.b
  object_is_in_screen.b
  object_transparency.l
  object_counter_id.i    ;use this for fast undo function (we sort it by counter_id and kill the last object in the map, and resort it with the layer flag)
  object_NPC_show_text_on_collision.b
  object_NPC_text_path.s
  object_NPC_internal_name.s
  object_gfx_h.f
  object_gfx_w.f
  object_gfx_set_w_h.b
  
EndStructure

Structure template  ;used  for mapbuilding, you can use a gfx/sketch to help you build the map
  x.f
  y.f
  transparency.l
  id.i
  show.b
  is_valid.b
EndStructure

Structure  wc_screen_output  ;here we store the screen gfx 
id.i    
transparency.l
show.b
is_valid.b
x.f
y.f
EndStructure 

Structure wc_resource
  last_size.i
  actual_size.i
EndStructure

Structure wc_asset_window
  last_pos_x.f
  last_pos_y.f
  pos_x.f
  pos_y.f 
EndStructure

;---------------------------------------------------------------------------------

Global  wc_template.template
Global NewList wc_menu_object.menu_objects()
Global NewList map_object.map_objects()
Global wc_work_gfx.wc_work_gfx_s
Global wc_screen_output.wc_screen_output
Global wc_resource.wc_resource
Global wc_asset_window.wc_asset_window
 
 Procedure WC_GETDEL_POINTER()
   
   wc_delpointer_gfx.l=LoadSprite(#PB_Any,wc_delpointer_path.s)
   
   If IsSprite(wc_delpointer_gfx.l)
     
   Else
     
     WC_ERROR(#WC_ERROR_DELPOINTER_MISSING,"CAN NOT LOAD: "+wc_delpointer_path.s) 
   EndIf
       
 EndProcedure

 Procedure WC_LOAD_OBJECT_GFX()
   
   Define _ok.l
   Define _posx.l=0
   Define _posy.l=0
   Define _pos_x_total.l=0
   Define _scroller.l=0
   
   UseGadgetList(WindowID(v_window_child_id))
   ;here we set the controlgadget
   ;ButtonGadget(#GAD_UP,1,1,62,32,"UP")
   ;ButtonGadget(#GAD_DOWN,64,1,62,32,"DOWN")
   ;-------------------------------------------------------
   
   ;ScrollAreaGadget(#GAD_CONTAINER,1,1,(wc_menu_image_size.l+1)*16,(wc_menu_image_size.l+1)*32,wc_menu_image_size.l*128,wc_menu_image_size.l*128)
   ;If IsGadget(#GAD_CONTAINER)=0
        
  If  ScrollAreaGadget(#GAD_CONTAINER,1,1,WindowWidth(v_window_child_id),WindowHeight(v_window_child_id),1,1)
      SetGadgetColor(#GAD_CONTAINER,#PB_Gadget_BackColor,GetWindowColor(v_window_child_id))
    Else
      
      
        WC_ERROR(#WC_CAN_ON_NOT_CREATE_ASSET_WINDOW,"Can not create ASSET WINDOW")
         
EndIf

;EndIf
 
   ResetList(wc_menu_object())
   While NextElement(wc_menu_object())
     E_GET_PACK_GFX_AND_REBUILD_DISTI(wc_menu_object()\_gfx_path)
     wc_menu_object()\_gfx_id=LoadImage(#PB_Any,wc_menu_object()\_gfx_path,0)
     E_GET_PACK_GFX_AND_CONVERT_DISTI(wc_menu_object()\_gfx_path)
     If  IsImage(wc_menu_object()\_gfx_id)
       ResizeImage (wc_menu_object()\_gfx_id,wc_menu_image_size.l*DesktopResolutionX(),wc_menu_image_size.l*DesktopResolutionY())
       wc_menu_object()\_x=_posx.l*(wc_menu_image_size.l)
       wc_menu_object()\_y=_posy.l*(wc_menu_image_size.l)
       wc_menu_object()\_w=wc_menu_image_size.l
       wc_menu_object()\_h=wc_menu_image_size.l
       
       If ImageGadget(ListIndex(wc_menu_object())+1,wc_menu_object()\_x,wc_menu_object()\_y,wc_menu_image_size.l,wc_menu_image_size.l,ImageID(wc_menu_object()\_gfx_id),#PB_Image_Raised)
         GadgetToolTip(ListIndex(wc_menu_object())+1,wc_menu_object()\_gfx_path+" AI:"+wc_menu_object()\_ai_path)
         
          SetWindowTitle(v_window_child_id,"Loading Assets...."+wc_menu_object()\_gfx_path)  
          
              _posx.l+1
     
     If _posx.l>(WindowWidth(v_window_child_id.i)/(wc_menu_image_size.l+1)) 
       _pos_x_total.l=_posx.l
       _posx.l=0
       _posy.l+1
       _scroller.l+wc_menu_image_size.l
     EndIf
   EndIf
 Else 
   
   WC_ERROR(#WC_CAN_NOT_LOAD_ASSET_OBJECT,"ASSET NR: "+Str(ListIndex(wc_menu_object()))+" NOT FOUND: "+wc_menu_object()\_gfx_path+Chr(13)+" PLEASE CHECK AI42 FILE:   "+wc_menu_object()\_ai_path)
     
   EndIf
       
   Wend
   
   If _posy.l<1
   _posy.l=1  
   EndIf
   
   _scroller.l=_scroller.l-WindowHeight(v_window_child_id)+wc_menu_image_size.l
   
   If _scroller.l<0
   _scroller.l=0  
   EndIf
      
    SetGadgetAttribute(#GAD_CONTAINER,#PB_ScrollArea_InnerWidth,WindowWidth(v_window_child_id))
    SetGadgetAttribute(#GAD_CONTAINER,#PB_ScrollArea_InnerHeight,WindowHeight(v_window_child_id)+_scroller.l)
    SetWindowTitle(v_window_child_id,"Assets Loaded: "+ListSize(wc_menu_object()))
    
 EndProcedure

Procedure WC_SORT_GADGET_GFX()
  ;here we sort the gfx so we have "blocks of same type"
     SortStructuredList(wc_menu_object(),#PB_Sort_Ascending  ,OffsetOf(menu_objects\object_container_type),TypeOf(menu_objects\object_container_type))
  EndProcedure

  Procedure  WC_OBJECT_PARSER()
    Define _key.s=""
    Define _arg.s=""
    Define _ok.l=0
    Define _find.l=0
    Define _file_name.s=""
    Define _file_type.s=""
    
    _ok.l=ReadFile(#PB_Any,v_resource_path+wc_menu_object()\_ai_path) ;open the ai42 script file
    
    If IsFile(_ok.l)
      
      wc_menu_object()\object_not_in_map_editor=#False
      wc_menu_object()\object_gfx_set_w_h=#False
      
      While Not Eof(_ok.l)
        
        _key.s=ReadString(_ok.l)
        _arg.s=ReadString(_ok.l)
        
        _find.l=FindString(_key.s,".")
        
        If _find.l>0
        _key.s=Left(_key.s,_find.l-1)
       EndIf
      
      _key.s=Trim(_key.s," ") ;remove all "  " so we get valid keywords, if something went wrong at production
               
        Select _key.s
            
          Case "object_source#"  ;here we reset the source file path, so we can use it (path is reconstructed for executing system)
                                 ;not used anymore , we use single keyword combination
            
          Case "object_file#"
            
            _file_name.s=_arg.s
            
          Case "object_type#"
            _file_type.s=_arg.s           
            
          Case "object_full_screen"
            wc_menu_object()\_full_screen=Val(_arg.s)
            If wc_menu_object()\_full_screen>0
              wc_menu_object()\_full_screen=#True
              
            Else
              wc_menu_object()\_full_screen=#False
              
            EndIf
            
          Case "object_is_scroll_back_ground"
            
            wc_menu_object()\object_is_scroll_back_ground=Val(_arg.s)
            If wc_menu_object()\object_is_scroll_back_ground>0
              wc_menu_object()\object_is_scroll_back_ground=#True
              
            Else
              wc_menu_object()\object_is_scroll_back_ground=#False
              
            EndIf
            
          Case "object_NPC_show_text_on_collision"
            wc_menu_object()\object_NPC_show_text_on_collision=Val(_arg.s)
          
          Case "object_NPC_text_path"
            wc_menu_object()\object_NPC_text_path=_arg.s
            
          Case "object_NPC_internal_name"
            wc_menu_object()\object_NPC_internal_name=_arg.s
            
          Case "object_transparency"
            wc_menu_object()\_transparency=255-Val(_arg.s)
            
          Case "object_auto_layer"
            wc_menu_object()\_object_auto_layer=Val(_arg.s)
                    
          Case "object_procedural_source_name"
            wc_menu_object()\object_procedural_source_name=_arg.s
                       
          Case "object_procedural_seed"
            wc_menu_object()\object_procedural_seed=Val(_arg.s)
            
          Case "object_is_procedural_base"
            wc_menu_object()\object_is_procedural_base=Val(_arg.s)
            
            If wc_menu_object()\object_is_procedural_base>0
              wc_menu_object()\object_procedural_done=#False    
            EndIf
                        
          Case "object_container_type"
            wc_menu_object()\object_container_type=Val(_arg.s)
            
          Case "object_procedural_x_offset"
            wc_menu_object()\object_procedural_x_offset=ValF(_arg.s)
                    
          Case "object_procedural_y_offset"
            wc_menu_object()\object_procedural_y_offset=ValF(_arg.s)
            
          Case "object_internal_name"
            wc_menu_object()\object_internal_name=_arg.s    
            
          Case "object_procedural_max_objects"
            wc_menu_object()\object_procedural_max_objects=Val(_arg.s)
                      
          Case "object_use_random_angle"
            wc_menu_object()\object_use_random_angle=ValF(_arg.s)  ;use it for placement with different angles (bushes/trees ....)
            
          Case "object_use_shadow"
            wc_menu_object()\object_use_shadow=Val(_arg.s)
            
          Case "object_shadow_intense"
            wc_menu_object()\object_shadow_intense=Val(_arg.s)
                      
          Case "object_add_to_quest"
            wc_menu_object()\object_add_to_quest=Val(_arg.s)
            
            ;areas    
            
          Case "object_is_area"
            wc_menu_object()\object_is_area=Val(_arg.s)
            
          Case "object_area_ai42_path"
            wc_menu_object()\object_area_42_path=_arg.s
            
          Case "object_area_path"
            wc_menu_object()\object_area_path=_arg.s
            
          Case "object_not_in_map_editor"
            If Val(_arg.s)>0
            wc_menu_object()\object_not_in_map_editor=#True  
            EndIf
            
          Case "object_gfx_set_w_h"
            If Val(_arg.s)>0
             
              wc_menu_object()\object_gfx_set_w_h=#True
            EndIf
            
          Case "object_gfx_h"
            wc_menu_object()\object_gfx_h=ValF(_arg.s)
            
            Case "object_gfx_w"
              wc_menu_object()\object_gfx_w=ValF(_arg.s)
              
        EndSelect
        
      Wend
      
      If wc_menu_object()\object_not_in_map_editor=#True
        If ListSize(wc_menu_object())>0
          DeleteElement(wc_menu_object())
          EndIf
      Else
        wc_menu_object()\_gfx_path=v_resource_path+_file_name.s+"."+_file_type.s
      EndIf
        
      CloseFile(_ok.l)
      
    Else
      
      WC_ERROR(#WC_CAN_NOT_LOAD_ASSET_OBJECT,v_resource_path+wc_menu_object()\_ai_path)

    EndIf
    
  EndProcedure

Procedure WC_OBJECT_FILE_MERGER()
  
  ResetList(wc_menu_object()) ;start with the first entry
  
  ;here we read the AI42 file for some information we need in the worldcreator for objectpositioning and display
  
  While NextElement(wc_menu_object())
    WC_OBJECT_PARSER()
  Wend
  
WC_SORT_GADGET_GFX()
EndProcedure

Procedure WC_SET_RESOURCE()
  Define _path.s=""
  Define _ok.l=0
  
  _path.s=PathRequester("SET RESOURCE PATH",v_resource_path.s)
  
  If _path.s>""
    
    _ok.l=CreateFile(#PB_Any,v_base.s+v_resource_name.s)
    WriteString(_ok.l,_path.s)
      CloseFile(_ok.l)
    _ok.l=MessageRequester("WORLD CREATOR: GFX RESOURCE FILES:",_path.s+Chr(13)+"WORLDCREATOR MUST QUIT AND RESTART",#PB_MessageRequester_Ok)
   
    End
   
  Else
    
    _ok.l=MessageRequester("WORLD CREATOR: GFX RESOURCE FILES:","NOT DEFINED/NOT CHANGED"+Chr(13)+"******IGNORE NEXT ERROR*****",#PB_MessageRequester_Ok)
     wc_ignore_map_error.b=#True
    
  EndIf
 
  EndProcedure
  
  Procedure WC_SET_RESOURCE_SOUND()
  Define _path.s=""
  Define _ok.l=0
  
  _path.s=PathRequester("SET RESOURCE SOUND PATH",v_resource_path_sound.s)
  
  If _path.s>""
    
    _ok.l=CreateFile(#PB_Any,v_base.s+v_resource_name_sound.s)
    WriteString(_ok.l,_path.s)
      CloseFile(_ok.l)
    _ok.l=MessageRequester("WORLD CREATOR: RESOURCE PATH SOUND FILES:",_path.s,#PB_MessageRequester_Ok)
    
    v_resource_path_sound.s=_path.s
      
  Else
    
    _ok.l=MessageRequester("WORLD CREATOR: PATH RESOURCE SOUND FILES:","NOT DEFINED/NOT CHANGED",#PB_MessageRequester_Ok)
     wc_ignore_map_error.b=#True
    
  EndIf
 
  EndProcedure

  Procedure WC_CHECK_RESOURCE_SOUND()
  
  Define _ok.l=0
  
  _ok.l=ReadFile(#PB_Any,v_resource_name_sound.s)
  
  If IsFile(_ok.l)
    v_resource_path_sound.s=ReadString(_ok.l) ;is stored in the first line (only line) of resource file
       ;hardcoded for now, just a workaround for fast fixing the problem     
  Else
    
    If wc_ignore_map_error.b=#False
   WC_ERROR(#WC_ERROR_NEED_SOURCE,"WARNING! NO SOUND RESOURCE")
   WC_SET_RESOURCE_SOUND()
 EndIf
 
  EndIf
    
  CloseFile(_ok.l)
     
  EndProcedure
  
Procedure WC_CHECK_RESOURCE()
  
  Define _ok.i=0
  
  _ok.i=ReadFile(#PB_Any,v_resource_name.s)
  
  If IsFile(_ok.i)
    v_resource_path.s=ReadString(_ok.i) ;is stored in the first line (only line) of resource file
    v_resource_path_sound.s=v_resource_path.s+"SOUND\"    ;hardcoded for now, just a workaround for fast fixing the problem     
  Else
    
    If wc_ignore_map_error.b=#False
   WC_ERROR(#WC_ERROR_NEED_SOURCE,"WARNING! NO GFX / OBJECT SOURCE")
   WC_SET_RESOURCE()
 EndIf
 
   
  EndIf
    
  CloseFile(_ok.i)
     
  EndProcedure
  
  Procedure WC_LIST_RESOURCE_DIRECTORY()
    Define _file.l=0
    Define _dir.l=0
        
    ClearList(wc_menu_object())
    ResetList(wc_menu_object())
    
    _dir.l=ExamineDirectory(#PB_Any,v_resource_path,v_resource_type)
    
    If IsDirectory(_dir.l)=0
    ProcedureReturn #False ;silent escape...  
    EndIf
    
    wc_resource\actual_size=0
    wc_resource\last_size=0
    
    While NextDirectoryEntry(_dir.l)
        
      If DirectoryEntryType(_dir.l)=#PB_DirectoryEntry_File 
   
        
        If AddElement(wc_menu_object())
            wc_menu_object()\_ai_path  = DirectoryEntryName(_dir.l)
                    
             wc_resource\actual_size+1        
      EndIf
  EndIf
     
Wend
FinishDirectory(_dir.l)

wc_resource\last_size=wc_resource\actual_size
    
  EndProcedure
    
  Procedure WC_REFRESH_GFX_RESOURCE_DIRECTORY()
    ;try this if we just added new gfx/game object to diretory, so we do not have to quit and restart mapcreator
    
    If ListSize(wc_menu_object())<1
    ProcedureReturn #False  
    EndIf
    
    ResetList(wc_menu_object())
    
    ForEach wc_menu_object()
      
      If IsImage(wc_menu_object()\_gfx_id)
        FreeImage(wc_menu_object()\_gfx_id) 
        
      EndIf
      
      If IsGadget(ListIndex(wc_menu_object()))
      FreeGadget(ListIndex(wc_menu_object()))
      EndIf   
    
    Next
    
    If IsGadget(#GAD_CONTAINER)
    FreeGadget(#GAD_CONTAINER)  
    EndIf
     
    If IsWindow(v_window_child_id)
    CloseWindow(v_window_child_id)  
    EndIf
    
WC_OPEN_OBJECT_WINDOW()
WC_CHECK_RESOURCE()
WC_CHECK_RESOURCE_SOUND()
WC_LIST_RESOURCE_DIRECTORY()
WC_OBJECT_FILE_MERGER()
WC_SORT_GADGET_GFX()
WC_LOAD_OBJECT_GFX()
    
  EndProcedure  
  
  Procedure WC_CHECK_FOR_RESOURCE_CHANGE()
  ;can we check the resourcedirectory if anything changed?
   
  Define _file.l=0
  Define _dir.l=0
    
  wc_resource\actual_size=0
     
    _dir.l=ExamineDirectory(#PB_Any,v_resource_path,v_resource_type)
    
    If _dir.l=0
    ProcedureReturn #False  ;silent return for now...  
    EndIf
       
    While NextDirectoryEntry(_dir.l)
          
      If DirectoryEntryType(_dir.l)=#PB_DirectoryEntry_File 
     wc_resource\actual_size+1  ;just count files in resource directory not the size of the files!
   
    EndIf
     
Wend
FinishDirectory(_dir.l)

 If wc_resource\last_size=wc_resource\actual_size
    ProcedureReturn #False
 EndIf
 
 WC_ERROR(#WC_ERROR_ASK_UPDATE_ASSET_DIRECTORY,"Asset Files Changed, Must Update Assetdirectory")
 ;you MUST update!
 WC_REFRESH_GFX_RESOURCE_DIRECTORY()
wc_resource\last_size=wc_resource\actual_size
  
EndProcedure

  
  
  
; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 634
; FirstLine = 616
; Folding = ---
; Optimizer
; EnableXP
; EnableUser
; Executable = worldcreator.exe
; CPU = 1
; SubSystem = DirectX9
; DisableDebugger
; EnableCompileCount = 0
; EnableBuildCount = 0
; EnableExeConstant