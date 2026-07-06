EnableExplicit

XIncludeFile "Log.pb"

DeclareModule AssetBootstrap
  Declare EnsureGameAssets()
EndDeclareModule

Module AssetBootstrap
  Procedure EnsureDirectory(path.s)
    If FileSize(path) <> -2
      CreateDirectory(path)
    EndIf
  EndProcedure

  Procedure WriteFourCC(file.i, text.s)
    Protected i.i
    For i = 1 To Len(text)
      WriteByte(file, Asc(Mid(text, i, 1)))
    Next
  EndProcedure

  Procedure CreateBmp(path.s, fillColor.i, accentColor.i)
    Protected width.i = 64
    Protected height.i = 64
    Protected fileSize.i = 54 + (width * height * 4)
    Protected file.i
    Protected x.i
    Protected y.i
    Protected dx.f
    Protected dy.f
    Protected dist.f
    Protected color.i
    Protected radiusOuter.f = 30.0
    Protected radiusInner.f = 18.0

    If FileSize(path) > 0
      ProcedureReturn
    EndIf

    file = CreateFile(#PB_Any, path)
    If file = 0
      Log::Warn("Failed to create placeholder sprite: " + path)
      ProcedureReturn
    EndIf

    WriteByte(file, Asc("B"))
    WriteByte(file, Asc("M"))
    WriteLong(file, fileSize)
    WriteLong(file, 0)
    WriteLong(file, 54)

    WriteLong(file, 40)
    WriteLong(file, width)
    WriteLong(file, -height)
    WriteWord(file, 1)
    WriteWord(file, 32)
    WriteLong(file, 0)
    WriteLong(file, width * height * 4)
    WriteLong(file, 2835)
    WriteLong(file, 2835)
    WriteLong(file, 0)
    WriteLong(file, 0)

    For y = 0 To height - 1
      For x = 0 To width - 1
        dx = x - 31.5
        dy = y - 31.5
        dist = Sqr((dx * dx) + (dy * dy))

        If dist <= radiusInner
          color = fillColor
        ElseIf dist <= radiusOuter
          color = accentColor
        Else
          color = RGBA(0, 0, 0, 0)
        EndIf

        WriteByte(file, Blue(color))
        WriteByte(file, Green(color))
        WriteByte(file, Red(color))
        WriteByte(file, Alpha(color))
      Next
    Next

    CloseFile(file)
  EndProcedure

  Procedure CreateWave(path.s, frequency.f, durationMs.i, amplitude.i)
    Protected sampleRate.i = 22050
    Protected channels.i = 1
    Protected bitsPerSample.i = 16
    Protected sampleCount.i = (sampleRate * durationMs) / 1000
    Protected dataSize.i = sampleCount * channels * (bitsPerSample / 8)
    Protected file.i
    Protected i.i
    Protected sample.i
    Protected t.d

    If FileSize(path) > 0
      ProcedureReturn
    EndIf

    file = CreateFile(#PB_Any, path)
    If file = 0
      Log::Warn("Failed to create placeholder audio: " + path)
      ProcedureReturn
    EndIf

    WriteFourCC(file, "RIFF")
    WriteLong(file, 36 + dataSize)
    WriteFourCC(file, "WAVE")
    WriteFourCC(file, "fmt ")
    WriteLong(file, 16)
    WriteWord(file, 1)
    WriteWord(file, channels)
    WriteLong(file, sampleRate)
    WriteLong(file, sampleRate * channels * (bitsPerSample / 8))
    WriteWord(file, channels * (bitsPerSample / 8))
    WriteWord(file, bitsPerSample)
    WriteFourCC(file, "data")
    WriteLong(file, dataSize)

    For i = 0 To sampleCount - 1
      t = i / sampleRate
      sample = Sin(2 * #PI * frequency * t) * amplitude
      WriteWord(file, sample)
    Next

    CloseFile(file)
  EndProcedure

  Procedure EnsureGameAssets()
    EnsureDirectory("game")
    EnsureDirectory("game/assets")

    CreateBmp("game/assets/player.bmp", RGBA(80, 180, 255, 255), RGBA(255, 255, 255, 255))
    CreateBmp("game/assets/npc_a.bmp", RGBA(255, 180, 80, 255), RGBA(255, 255, 255, 255))
    CreateBmp("game/assets/npc_b.bmp", RGBA(120, 255, 140, 255), RGBA(255, 255, 255, 255))
    CreateBmp("game/assets/spawn.bmp", RGBA(255, 120, 220, 255), RGBA(255, 255, 255, 255))

    CreateWave("game/assets/startup.wav", 440.0, 160, 9000)
    CreateWave("game/assets/ui_click.wav", 880.0, 70, 7000)
    CreateWave("game/assets/spawn.wav", 660.0, 110, 8000)
  EndProcedure
EndModule
