; example of dynamic linking from DLL file

IncludeFile "../../glfw/glfw.config.dynamic.pbi"
IncludeFile "../../glfw/glfw.pbi"
IncludeFile "../../glfw/glfw.load.pb"

UseModule glfw
 
If glfw_load::Load() = glfw_load::#LOAD_OK 
    If glfwInit()
        Debug "OK"
        Debug PeekS(glfwGetVersionString(), -1, #PB_UTF8)        
    EndIf
    glfw_load::Shutdown()
EndIf
 
; IDE Options = PureBasic 6.02 LTS (Windows - x86)
; CursorPosition = 4
; EnableXP
; EnableUser
; Executable = test
; CPU = 1
; CompileSourceDirectory
; EnablePurifier
; EnableExeConstant
; EnableUnicode