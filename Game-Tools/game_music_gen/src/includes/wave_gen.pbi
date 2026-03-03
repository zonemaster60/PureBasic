; ====================================================================
; Wave File Generation Functions
; ====================================================================

Procedure.i CreateWaveFile(filename.s, *clip.MusicClip)
  Protected file.i
  Protected.WaveHeader header
  Protected.w sample16
  Protected numSamples.i = ListSize(*clip\samples())
  Protected dataSize.i = numSamples * (#BITS_PER_SAMPLE / 8)
  Protected scaled.f

  If numSamples <= 0
    ProcedureReturn #False
  EndIf

  header\chunkID = $46464952 ; RIFF
  header\chunkSize = 36 + dataSize
  header\format = $45564157 ; WAVE
  header\subchunk1ID = $20746D66 ; fmt 
  header\subchunk1Size = 16
  header\audioFormat = 1
  header\numChannels = #CHANNELS
  header\sampleRate = #SAMPLE_RATE
  header\byteRate = #SAMPLE_RATE * #CHANNELS * #BITS_PER_SAMPLE / 8
  header\blockAlign = #CHANNELS * #BITS_PER_SAMPLE / 8
  header\bitsPerSample = #BITS_PER_SAMPLE
  header\subchunk2ID = $61746164 ; data
  header\subchunk2Size = dataSize

  file = CreateFile(#PB_Any, filename)
  If file = 0
    ProcedureReturn #False
  EndIf

  WriteData(file, @header, SizeOf(WaveHeader))

  ForEach *clip\samples()
    scaled = Clamp(*clip\samples(), -1.0, 1.0) * 32767.0
    sample16 = Round(scaled, #PB_Round_Nearest)
    WriteWord(file, sample16)
  Next

  CloseFile(file)
  ProcedureReturn #True
EndProcedure
