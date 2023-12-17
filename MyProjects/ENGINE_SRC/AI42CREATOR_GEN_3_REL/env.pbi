
;here we set all variables and structures for the new ai42 creator

InitSprite()
UsePNGImageDecoder()
UseTIFFImageDecoder()
UseGIFImageDecoder()
UseTGAImageDecoder()

Structure creator
  creator_directory.s
  creator_ini_file.s
  creator_text_gadget_w.f
  creator_text_gadget_h.f
  creator_text_gadget_offset_x.f
  creator_text_gadget_offset_y.f
  creator_max_text_gadget.i
  creator_signal.b  ;some program controls...
  creator_default_object_file.s
  creator_gfx_file_name.s
  creator_dna_file_suffix.s
  creator_dna_file_part.s
  creator_menu_ini_file.s
  creator_object_key_word.s
  creator_max_row.i
  creator_last_file.s
  creator_color_object_key.i
  creator_color_object_key_text.i
  creator_color_object_value.i
  creator_color_object_value_text.i
  creator_objects_in_dna.i
  creator_gfx_suffix.s
  creator_gfx_id.i
  creator_screen_id.i
  creator_gfx_file_part.s
  creator_gfx_file_path.s
  creator_search_size.i  
  creator_dummy.s
  creator_cache_memory_page_size.i
  *creator_cache_memory_page_adress
EndStructure

Structure creator_window
  window_id.i
  window_x.f
  window_y.f
  window_widht.f
  window_height.f
  window_event.i
  window_title.s
  window_menu_id.i
  window_child_id.i
  window_child_image_gadget_id.i 
EndStructure

Structure global_gadget
  w.f
  h.f
  pos_x.f
  pos_y.f
  color.i
  id.i
  base_id.i
  add_color_value_key.i
  add_color_value_value.i   
EndStructure

Structure object_gadget  ;this will be a list!
  id.i
  w.f
  h.f
  offset_x.f
  offset_y.f
  color.i
  pos_x.f
  pos_y.f
  key.s
  val.s
  type.b  ;holds if it is a key or a value!  (0=key,1=value!)  
EndStructure

Structure dna_fundament ;this stores the default dna and is used to check the gadgets if they are valid, only infos stored in the default will be read!/saved!
  dna_string.s
EndStructure

Structure show_hit_box
  hit_box_w.f
  hit_box_h.f
  hit_box_x.f
  hit_box_y.f
  hit_box_drawe_mode.i  
EndStructure

Global NewList object_gadget.object_gadget()
Global creator.creator
Global creator_window.creator_window
Global global_gadget.global_gadget
Global show_hit_box.show_hit_box
Global NewList dna_fundament.dna_fundament()

creator\creator_directory=GetCurrentDirectory()
creator\creator_ini_file="ini.ini"
creator\creator_cache_memory_page_size=20000  ;default, use script to change this value!
creator\creator_cache_memory_page_adress=AllocateMemory(creator\creator_cache_memory_page_size)

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 104
; FirstLine = 80
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