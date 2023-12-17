;develope log routines

Procedure DEV_LISTLOG()
  ;list all listentries 
  Define _ok.l=0
   
  ResetList(wc_menu_object())
  
  _ok.l=CreateFile(#PB_Any,v_base.s+"LOG/LIST_LOG.txt")
  
  If IsFile(_ok.l)
    
    WriteStringN(_ok.l,"DEBUG LOG:   LIST SIZE: "+Str(ListSize(wc_menu_object())))
    WriteStringN(_ok.l,"CREATED: "+FormatDate("%dd.%mm.%yyyy", Date())+"  TIME: "+FormatDate("%hh:%ii:%ss", Date()))
    WriteStringN(_ok.l,"(C) DEUTSCHMANN WALTER  ----   DEUTSCHMANN DEVELOPEMENT")
    WriteStringN(_ok.l,"")
    
    While NextElement(wc_menu_object())
      WriteStringN(_ok.l,"ASSET ID: #"+Str(ListIndex(wc_menu_object())))
      WriteStringN(_ok.l,"GFXPATH")
      WriteStringN(_ok.l,wc_menu_object()\_gfx_path)
       WriteStringN(_ok.l,"AIPATH")
       WriteStringN(_ok.l,wc_menu_object()\_ai_path)
       If wc_menu_object()\_gfx_id<>0
         WriteStringN(_ok.l,"ID: "+Str(wc_menu_object()\_gfx_id))
       Else
          WriteStringN(_ok.l,"ID: ERROR")
       EndIf
       
    WriteStringN(_ok.l,"")
    
  Wend
  
  CloseFile(_ok.l)
  
EndIf

EndProcedure

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 38
; FirstLine = 13
; Folding = -
; EnableXP
; EnableUser