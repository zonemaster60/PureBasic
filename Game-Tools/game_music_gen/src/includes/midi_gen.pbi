; ====================================================================
; MIDI Generation Functions
; ====================================================================

Procedure AddMidiEvent(List out.a(), delta.i, status.a, d1.a, d2.a)
  ; VLQ delta
  Protected tmp.l
  Protected b.a

  tmp = delta & $0FFFFFFF

  ; Write into a small stack then flush reversed
  Dim bytes.a(4)
  Protected count.i = 0

  Repeat
    bytes(count) = tmp & $7F
    tmp >> 7
    count + 1
  Until tmp = 0 Or count = 4

  Protected i.i
  For i = count - 1 To 0 Step -1
    b = bytes(i)
    If i <> 0
      b | $80
    EndIf
    AddElement(out())
    out() = b
  Next

  AddElement(out()) : out() = status
  AddElement(out()) : out() = d1
  AddElement(out()) : out() = d2
EndProcedure

Procedure.i CreateMidiFile(filename.s, *clip.MusicClip)
  ; Type 0 MIDI file, 1 track, ticksPerQuarter=480
  Protected file.i
  Protected ticksPerQuarter.i = 480
  Protected tempoBpm.i = ClampI(*clip\tempo, 30, 300)
  Protected usPerQuarter.l = 60000000 / tempoBpm

  Protected stepLenTicks.i

  If *clip\tempo <= 0 Or ListSize(*clip\events()) = 0
    ProcedureReturn #False
  EndIf

  ; We store events in "steps" where 1 step is a 16th note.
  stepLenTicks = ticksPerQuarter / 4

  NewList track.a()

  ; Tempo meta event at time 0
  AddElement(track()) : track() = 0 ; delta 0
  AddElement(track()) : track() = $FF
  AddElement(track()) : track() = $51
  AddElement(track()) : track() = 3
  AddElement(track()) : track() = (usPerQuarter >> 16) & $FF
  AddElement(track()) : track() = (usPerQuarter >> 8) & $FF
  AddElement(track()) : track() = usPerQuarter & $FF

  ; Collect note on/off as step-based events, then sort by tick.
  Structure MidiMsg
    tick.i
    status.a
    d1.a
    d2.a
  EndStructure

  NewList msgs.MidiMsg()

  Protected e.NoteEvent
  ForEach *clip\events()
    e = *clip\events()

    AddElement(msgs())
    msgs()\tick = e\startStep * stepLenTicks
    msgs()\status = $90 | (e\channel & $0F)
    msgs()\d1 = e\midiNote & $7F
    msgs()\d2 = e\velocity & $7F

    AddElement(msgs())
    msgs()\tick = (e\startStep + e\lengthSteps) * stepLenTicks
    msgs()\status = $80 | (e\channel & $0F)
    msgs()\d1 = e\midiNote & $7F
    msgs()\d2 = 0
  Next

  SortStructuredList(msgs(), #PB_Sort_Ascending, OffsetOf(MidiMsg\tick), TypeOf(MidiMsg\tick))

  Protected lastTick.i = 0
  ForEach msgs()
    AddMidiEvent(track(), msgs()\tick - lastTick, msgs()\status, msgs()\d1, msgs()\d2)
    lastTick = msgs()\tick
  Next

  ; End of track
  AddElement(track()) : track() = 0
  AddElement(track()) : track() = $FF
  AddElement(track()) : track() = $2F
  AddElement(track()) : track() = 0

  file = CreateFile(#PB_Any, filename)
  If file = 0
    ProcedureReturn #False
  EndIf

  ; Header chunk
  WriteString(file, "MThd", #PB_Ascii)
  WriteLong(file, 6)
  WriteWord(file, 0) ; format 0
  WriteWord(file, 1) ; one track
  WriteWord(file, ticksPerQuarter)

  ; Track chunk
  WriteString(file, "MTrk", #PB_Ascii)
  WriteLong(file, ListSize(track()))
  ForEach track()
    WriteByte(file, track())
  Next

  CloseFile(file)
  ProcedureReturn #True
EndProcedure
