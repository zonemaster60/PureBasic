; Drawing with fragment shaders

EnableExplicit

IncludeFile "../../sgl.config.pbi"
IncludeFile "../../sgl.pbi"
IncludeFile "../../sgl.pb"

IncludeFile "../../extras/RenderText/RenderText.pb"

UseModule gl

#TITLE$ = "Drawing with fragment shaders 3.30"
#WIN_WIDTH = 1024
#WIN_HEIGHT = 768
#VSYNC = 1

Global gWin
Global gVSync = #VSYNC
Global gShader
Global gFon
Global gTimer
Global gVao

Declare   CallBack_WindowRefresh (win)
Declare   CallBack_Error (source$, desc$)
Declare   SetupData()
Declare   SetupContext()
Declare   ShutDown()
Declare   Render()
Declare   MainLoop()
Declare   Main()
 
Procedure CallBack_WindowRefresh (win)
 Render()
EndProcedure 

Procedure CallBack_Error (source$, desc$)
 Debug "[" + source$ + "] " + desc$
EndProcedure

Procedure SetupData()

 Protected *vertex = sgl::StartData() ; One single QUAD
  ; 2 * vertex_pos + 2 * tex_coord  
  Data.f  0.0, 0.0,  0.0, 0.0  
  Data.f  1.0, 0.0,  1.0, 0.0  
  Data.f  1.0, 1.0,  1.0, 1.0  
  Data.f  0.0, 1.0,  0.0, 1.0                  
 sgl::StopData()
    
 ; indices for the QUAD
 Protected *indices = sgl::StartData()
  Data.l  0,  1,  2,  2,  3,  0
 sgl::StopData()
 
 Protected vbo, ibo
 
 ; vertex array
 glGenVertexArrays_(1, @gVao)
 glBindVertexArray_(gVao)
  
 ; vertex buffer
 glGenBuffers_(1, @vbo)
 glBindBuffer_(#GL_ARRAY_BUFFER, vbo)
 
 ; 4 vertices made by 4 floats each
 glBufferData_(#GL_ARRAY_BUFFER, 4 * 4 * SizeOf(Float), *vertex, #GL_STATIC_DRAW)

 ; Attributes
 glEnableVertexAttribArray_(0) ; point coords
 glVertexAttribPointer_(0, 2, #GL_FLOAT, #GL_FALSE, 4 * SizeOf(Float), 0)
 
 glEnableVertexAttribArray_(1) ; texture coord
 glVertexAttribPointer_(1, 2, #GL_FLOAT, #GL_FALSE, 4 * SizeOf(Float), 2 * SizeOf(Float))

 ; index buffer
 glGenBuffers_(1, @ibo)
 glBindBuffer_(#GL_ELEMENT_ARRAY_BUFFER, ibo)
 
 ; 6 indices made by 1 long each
 glBufferData_(#GL_ELEMENT_ARRAY_BUFFER, 6  * SizeOf(Long), *indices, #GL_STATIC_DRAW)
 
 ; Shaders 
 Protected objects.sgl::ShaderObjects
 Protected vs, fs
 
 vs = sgl::CompileShaderFromFile("vert.vs", #GL_VERTEX_SHADER) 
 sgl::AddShaderObject(@objects, vs) 
 ASSERT(vs)
 
 fs = sgl::CompileShaderFromFile("frag.fs", #GL_FRAGMENT_SHADER) 
 sgl::AddShaderObject(@objects, fs) 
 ASSERT(fs)
 
 gShader = sgl::BuildShaderProgram(@objects) ; link and build the program using the specified shader objects 
 ASSERT(gShader)
 
 ; Timers
 
 gTimer = sgl::CreateTimer()
 
 ; Fonts
 
 Dim ranges.sgl::BitmapFontRange(0)
 
 ; Latin (ascii)
 ranges(0)\firstChar  = 32
 ranges(0)\lastChar   = 128
 
 gFon = RenderText::CreateBitmapFont("Arial", 10, #Null, ranges())
 ASSERT(gFon)
 
EndProcedure

Procedure SetupContext() 
 sgl::RegisterErrorCallBack(@CallBack_Error())
 
 If sgl::Init()
     sgl::SetWindowHint(sgl::#HINT_WIN_OPENGL_MAJOR, 3)
     sgl::SetWindowHint(sgl::#HINT_WIN_OPENGL_MINOR, 3)
     sgl::SetWindowHint(sgl::#HINT_WIN_OPENGL_PROFILE, sgl::#PROFILE_CORE)     
     sgl::SetWindowHint(sgl::#HINT_WIN_OPENGL_DEBUG, 1)
           
     gWin = sgl::CreateWindow(#WIN_WIDTH, #WIN_HEIGHT, #TITLE$)
     
     If gWin
        sgl::MakeContextCurrent(gWin)
        
        sgl::RegisterWindowCallBack(gWin, sgl::#CALLBACK_WINDOW_REFRESH, @CallBack_WindowRefresh())     
     
        If glLoad::Load() = 0
            Debug glLoad::GetErrString()
        EndIf
     
        sgl::LoadExtensionsStrings()
         
        If sgl::IsDebugContext() = 0 Or sgl::EnableDebugOutput()  = 0 
            Debug "OpenGL debug output is not available !"
        EndIf   
             
        sgl::EnableVSYNC(#VSYNC)
        
        ProcedureReturn 
    EndIf
 EndIf
  
 sgl::Shutdown()
 
 End 
EndProcedure

Procedure ShutDown()
 sgl::DestroyTimer(gTimer)
 sgl::Shutdown()
EndProcedure

Procedure Render()
 Protected w, h
 Protected delta.d
 Protected.m4x4::m4x4 projection
 Protected u_projection
 
 delta = sgl::GetDeltaTime(gTimer)
  
 glClearColor_(0.0, 0.0, 0.0, 1.0)
 glEnable_(#GL_DEPTH_TEST) 
 glClear_(#GL_COLOR_BUFFER_BIT | #GL_DEPTH_BUFFER_BIT)
  
 sgl::GetWindowFrameBufferSize (gWin, @w, @h)
 glViewport_(0, 0, w, h)
 
 m4x4::Identity(projection)
 m4x4::Ortho(projection, 0.0, 1.0, 0.0, 1.0, 0.0, 100.0)
 
 sgl::BindShaderProgram(gShader)
 
 u_projection = sgl::GetUniformLocation(gShader, "u_projection")
 sgl::SetUniformMatrix4x4(u_projection, @projection)

 glBindVertexArray_(gVao) 
 glDrawElements_(#GL_TRIANGLES, 6, #GL_UNSIGNED_INT, 0) 

 ; text info
 
 Protected x, y 
 Protected.vec3::vec3 color 
 
 vec3::Set(color, 1.0, 1.0, 1.0)

 ; top
 x = 1 : y = 0
 If sgl::GetFPS()    
    RenderText::Render(gWin, gFon, "FPS: " + sgl::GetFPS(), x, y, color)
 EndIf
 
 ; bottom
 x = 1 : y = h - RenderText::GetFontHeight(gFon)  
 RenderText::Render(gWin, gFon, sgl::GetRenderer(), x, y, color)

 sgl::SwapBuffers(gWin)
EndProcedure

Procedure MainLoop()
 While sgl::WindowShouldClose(gWin) = 0
 
    If sgl::GetKeyPress(sgl::#Key_ESCAPE)
        sgl::SetWindowShouldClose(gWin, 1)
    EndIf

    If sgl::GetKeyPress(sgl::#Key_V)
        gVSync ! 1
        sgl::EnableVSync(gVSync)
    EndIf
    
    Render()
    
    sgl::PollEvents()
    
    sgl::TrackFPS()    
 Wend
EndProcedure

Procedure Main()
 SetupContext()
 SetupData()
 MainLoop()    
 ShutDown()
EndProcedure : Main()

; IDE Options = PureBasic 6.02 LTS (Windows - x86)
; CursorPosition = 174
; FirstLine = 157
; Folding = --
; EnableXP
; EnableUser
; Executable = ..\014\001\001.exe
; CPU = 1
; CompileSourceDirectory