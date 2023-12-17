;global variable
Global v_desktop_id.b=ExamineDesktops()
Global v_win_max_width.f=DesktopWidth(0)*DesktopResolutionX();no function because we use fullscreen
Global v_win_max_height.f=DesktopHeight(0)*DesktopResolutionY();/DesktopResolutionY()  ;no function because we use fullscreen
Global v_screen_w.f=1 ;render area NOT screen / display  physical resolution
Global v_screen_h.f=1
Global v_screen_aspect.f=1
Global v_win_x.f=0
Global v_win_y.f=0
Global v_display_id.i=0
Global v_border_type.i=#PB_Window_BorderLess
Global v_display_name.s=""
Global v_screen_id.i=-1
Global v_display_layer.b=0
Global v_display_backdrop_color.i=RGB(20,20,20)
Global v_display_is_screen.b=#False 
