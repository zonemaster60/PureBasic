; Using OpenGLGadget() with gl.pbi + gl.load.pb to import and enumerate the available OpenGL functions.

IncludeFile "../gl.pbi"
IncludeFile "../gl.load.pb"

UseModule gl

EnableExplicit

Procedure CallBack_GetProcAddress (func$)
 ProcedureReturn wglGetProcAddress_(func$) ; use the appropriate API here, or the applicable function from a framework like glfw
EndProcedure

Procedure CallBack_EnumFuncs (glver$, func$, *func) 
 Debug Left(glver$ + Space(4), 4) + " -> " + func$ + " ($" + Hex(*func) + ")"
EndProcedure

Global GoodProcsCount, BadProcsCount
Global major, minor

If OpenWindow(0, 100, 100, 640, 480, "GL TEST", #PB_Window_SystemMenu | #PB_Window_Invisible)

    If OpenGLGadget(0, 0, 0, 640, 480) ; PB will always request the highest possible COMPATIBLE context or a LEGACY one
   
        Debug "#GL_VENDOR = " + PeekS(glGetString_(#GL_VENDOR), -1, #PB_Ascii)
        Debug "#GL_RENDERER = " + PeekS(glGetString_(#GL_RENDERER), -1, #PB_Ascii)
        Debug "#GL_VERSION = " + PeekS(glGetString_(#GL_VERSION), -1, #PB_Ascii)
        
        gl_load::GetContextVersion(@major, @minor)
               
        Debug "OpenGL context version = " + Str(major) + "." + Str(minor)
        
        If gl_load::Deprecated()
            Debug "Deprecated functions are included."
        Else
            Debug "Deprecated functions are not included."
        EndIf    
        
        gl_load::RegisterCallBack(gl_load::#CallBack_GetProcAddress, @CallBack_GetProcAddress())    

        gl_load::RegisterCallBack(gl_load::#CallBack_EnumFuncs, @CallBack_EnumFuncs())
                                
        If gl_load::Load ()
            Debug "You can use the imported OpenGL functions now."                      
        Else                
            Debug "gl_load() error: " + gl_load::GetErrString()
        EndIf

        gl_load::GetProcsCount(@GoodProcsCount, @BadProcsCount)
                                    
        Debug Str(GoodProcsCount) + " functions imported, " + Str(BadProcsCount) + " missing."            
                
        CloseWindow(0)
    EndIf            
EndIf

; IDE Options = PureBasic 6.02 LTS (Windows - x86)
; Folding = -
; EnableXP
; EnableUser
; Executable = test.exe
; CPU = 1
; CompileSourceDirectory
; EnablePurifier
; EnableExeConstant