; ------------------------------------------------------------
;
;   modified after
;   ToolBar example that ships with PureBasic;
;   tested with PB 5.60
;
; ------------------------------------------------------------

CompilerIf #PB_Compiler_Version < 560
   MessageRequester("Error", "This example only works with PureBasic version 5.60 or newer.")
   
CompilerElse
   
   EnableExplicit
   
   XIncludeFile "../vectoricons.pbi"
   
   Enumeration
      #New
      #Open
      #Save
      #Find
   EndEnumeration
   
   Dim name$(#PB_Compiler_EnumerationValue-1)
   name$(#New)  = "New"
   name$(#Open) = "Open"
   name$(#Save) = "Save"
   name$(#Find) = "Find"
   
   Define.i event, tbIconSize=24, Req
   
   If OpenWindow(0, 100, 200, 300, 250, "Vectoricons toolbar example (PB 5.60+)", #PB_Window_SystemMenu | #PB_Window_SizeGadget) = 0
      MessageRequester("Fatal error", "Can't open main window.")
      End   
   EndIf
   
   If CreateToolBar(0, WindowID(0), #PB_ToolBar_Large|#PB_ToolBar_Text)
      ToolBarImageButton(#New, ImageID(VectorIcons::NewDocument("", #PB_Any, tbIconSize, VectorIcons::#CSS_White, VectorIcons::#CSS_Navy, VectorIcons::#CSS_Black)),
                         #PB_ToolBar_Normal, name$(#New))
      
      ToolBarImageButton(#Open, ImageID(VectorIcons::Open2("", #PB_Any, tbIconSize, VectorIcons::#CSS_GoldenRod, VectorIcons::#CSS_Navy, VectorIcons::#CSS_White)),
                         #PB_ToolBar_Normal, name$(#Open))
      
      ToolBarImageButton(#Save, ImageID(VectorIcons::Diskette("", #PB_Any, tbIconSize, VectorIcons::#CSS_Navy, VectorIcons::#VI_GuardsmanRed, VectorIcons::#CSS_White)),
                         #PB_ToolBar_Normal, name$(#Save))
      
      ToolBarSeparator()
      
      ToolBarImageButton(#Find, ImageID(VectorIcons::Find("", #PB_Any, tbIconSize, VectorIcons::#CSS_Black)),
                         #PB_ToolBar_Normal, name$(#Find))
   EndIf
   
   If CreateMenu(0, WindowID(0))
      MenuTitle("Project")
      MenuItem(#New, name$(#New))
      MenuItem(#Open, name$(#Open))
      MenuItem(#Save, name$(#Save))
      
      MenuBar()
      
      MenuItem(#Find, name$(#Find))
   EndIf
   
   Repeat
      event = WaitWindowEvent()
      
      Select event
         Case #PB_Event_Menu
            MessageRequester("Information", "ToolBar or Menu ID: " + Str(EventMenu()))
      EndSelect
   Until event = #PB_Event_CloseWindow    ; If the user has clicked on the close button
   Req=MessageRequester("Exit", "Do you want to exit now?", #PB_MessageRequester_YesNo | #PB_MessageRequester_Info)
    If Req = #PB_MessageRequester_Yes
      End
    EndIf
CompilerEndIf

; IDE Options = PureBasic 6.03 beta 4 LTS (Windows - x64)
; CursorPosition = 30
; FirstLine = 11
; Folding = -
; EnableXP
; EnableUser
; EnableExeConstant
; EnableUnicode