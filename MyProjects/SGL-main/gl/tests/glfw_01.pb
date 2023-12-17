; Using gl.pbi + gl.load.pb + glfw.pbi + glfw.load.pb to import and enumerate the OpenGL functions.

IncludeFile "../gl.pbi"
IncludeFile "../gl.load.pb"

UseModule gl

IncludeFile "../../glfw/glfw.config.dynamic.pbi"
IncludeFile "../../glfw/glfw.pbi"
IncludeFile "../../glfw/glfw.load.pb"

UseModule glfw

Global GoodProcsCount, BadProcsCount

ProcedureC CallBack_glfw_error (err, *desc)
 Debug "GLFW error callback = " + PeekS(*desc, -1, #PB_UTF8)
EndProcedure

Procedure CallBack_GetProcAddress (func$)
 ProcedureReturn glfwGetProcAddress(func$) ; we use the appropriate glfw function here
EndProcedure

Procedure CallBack_Enumerate (glver$, func$, *func) 
 Debug Left(glver$ + Space(4), 4) + " -> " + func$ + " ($" + Hex(*func) + ")"
EndProcedure

Procedure Main()
 Protected win
 Protected maj, min
 Protected glfw_ver$
 
 glfwSetErrorCallback(@CallBack_glfw_error())    
   
 If glfwInit()              
    glfwWindowHint(#GLFW_VISIBLE, 0)
    
    ; let's ask for OpenGL 2.1
    glfwWindowHint(#GLFW_CONTEXT_VERSION_MAJOR, 2)
    glfwWindowHint(#GLFW_CONTEXT_VERSION_MINOR, 1)      
    
    win = glfwCreateWindow(640, 480, "glfw", #Null, #Null) ; invisible window             
          
    If win
        glfwMakeContextCurrent(win)
        glfw_ver$ = PeekS(glfwGetVersionString(), -1, #PB_UTF8)
        Debug "GLFW version = " + glfw_ver$

        Debug "GL_VENDOR = " + PeekS(glGetString_(#GL_VENDOR),-1,#PB_Ascii)
        Debug "GL_RENDERER = " + PeekS(glGetString_(#GL_RENDERER),-1,#PB_Ascii)
        Debug "GL_VERSION = " + PeekS(glGetString_(#GL_VERSION),-1,#PB_Ascii)                        
        
        gl_load::GetContextVersion(@Major, @Minor)
                
        Debug "OpenGL context version = " + Str(Major) + "." + Str(Minor)

        If gl_load::Deprecated()
            Debug "Deprecated functions are included."
        Else
            Debug "Deprecated functions are not included."
        EndIf    
        
        gl_load::RegisterCallBack(gl_load::#CallBack_GetProcAddress, @CallBack_GetProcAddress())
        gl_load::RegisterCallBack(gl_load::#CallBack_EnumFuncs, @CallBack_Enumerate())
        
        If gl_load::Load()
            gl_load::GetProcsCount(@GoodProcsCount, @BadProcsCount)   
            Debug Str(GoodProcsCount) + " functions imported, " + Str(BadProcsCount) + " missing."
        EndIf
        glfwDestroyWindow(win)
    EndIf        
 EndIf    
EndProcedure

If glfw_load::Load() = glfw_load::#LOAD_OK
    Main()
    glfw_load::Shutdown()
EndIf

; IDE Options = PureBasic 6.02 LTS (Windows - x86)
; Folding = -
; EnableXP
; EnableUser
; Executable = test.exe
; CPU = 1
; CompileSourceDirectory
; EnableExeConstant