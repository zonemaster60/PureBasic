
Prototype.i EmptyWorkingSet( hProcess.i)
Prototype.i GetProcessMemoryInfo( hProcess.i, *ppsmemCounters.PROCESS_MEMORY_COUNTERS, cb.i)

Procedure.i GetProcessMemoryUsage(pid)
  Protected Result.i
  Protected PMC.PROCESS_MEMORY_COUNTERS
  Protected GetProcessMemoryInfo.GetProcessMemoryInfo

  Protected lib_psapi = OpenLibrary(#PB_Any, "psapi.dll")
  If lib_psapi
    GetProcessMemoryInfo.GetProcessMemoryInfo = GetFunction(lib_psapi,"GetProcessMemoryInfo")
    If GetProcessMemoryInfo(GetCurrentProcess_(), @PMC, SizeOf(PROCESS_MEMORY_COUNTERS))
      Result = PMC\WorkingSetSize   
    EndIf
    CloseLibrary(lib_psapi)   
  EndIf
   
  ProcedureReturn Result
EndProcedure 

Procedure.i GetCurrentMemoryUsage()
  ProcedureReturn GetProcessMemoryUsage(GetCurrentProcess_())
EndProcedure

;GetCurrentMemoryUsage()
; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; CursorPosition = 25
; Folding = -
; EnableAsm
; EnableThread
; EnableXP
; EnableUser
; EnableOnError
; CPU = 1
; DisableDebugger