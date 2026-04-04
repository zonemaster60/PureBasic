; Settings persistence, remembered peers, and settings UI state.

Procedure AddHistory(Status$, Direction$, Item$, Details$)
  Protected Line$ = FormatDate("%hh:%ii:%ss", Date()) + Chr(10) + Status$ + Chr(10) + Direction$ + Chr(10) + Item$ + Chr(10) + Details$

  AddGadgetItem(#GadgetHistory, -1, Line$)
  If CountGadgetItems(#GadgetHistory) > 300
    RemoveGadgetItem(#GadgetHistory, 0)
  EndIf
EndProcedure

Procedure.s LegacySettingsPath()
  ProcedureReturn AppPath + "files\" + #SettingsFile
EndProcedure

Procedure.s SettingsPath()
  ProcedureReturn TrimTrailingSlash(GetHomeDirectory() + "AppData\Local\PB_LanShare") + "\" + #SettingsFile
EndProcedure

Procedure LoadSettings()
  Protected PeerValue$
  Protected PeerHost$
  Protected PeerPort.i
  Protected PeerName$
  Protected PeerLastSeen.q
  Protected PrefPath$

  PrefPath$ = SettingsPath()
  If FileSize(PrefPath$) = -1 And FileSize(LegacySettingsPath()) <> -1
    PrefPath$ = LegacySettingsPath()
  EndIf

  If OpenPreferences(PrefPath$)
    PreferenceGroup("LanShare")
    DownloadPath$ = TrimTrailingSlash(ReadPreferenceString("DownloadPath", ReadPreferenceString("SharePath", DownloadPath$)))
    PreferenceGroup("RememberedPeers")
    ExaminePreferenceKeys()
    While NextPreferenceKey()
      PeerHost$ = Trim(PreferenceKeyName())
      PeerValue$ = PreferenceKeyValue()
      PeerPort = Val(StringField(PeerValue$, 1, "|"))
      PeerName$ = StringField(PeerValue$, 2, "|")
      PeerLastSeen = Val(StringField(PeerValue$, 3, "|"))
      If IsValidRememberedPeer(PeerHost$, PeerPort, PeerLastSeen)
        AddMapElement(Discovery(), PeerHost$)
        Discovery()\Host = PeerHost$
        Discovery()\Port = PeerPort
        Discovery()\Name = PeerName$
        Discovery()\LastSeen = PeerLastSeen
        Discovery()\DeviceType = "Ready to receive"
        Discovery()\IsLanShare = #True
        Discovery()\State = "(remembered)"
      EndIf
    Wend
    ClosePreferences()
  EndIf
EndProcedure

Procedure SaveSettings()
  Protected PeerValue$
  Protected PeerLastSeen.q
  Protected PrefPath$

  PrefPath$ = SettingsPath()
  If EnsureDirectoryExists(GetPathPart(PrefPath$)) And CreatePreferences(PrefPath$)
    PreferenceGroup("LanShare")
    WritePreferenceString("SharePath", DownloadPath$)
    WritePreferenceString("DownloadPath", DownloadPath$)
    WritePreferenceString("Port", GetGadgetText(#GadgetPort))
    WritePreferenceString("RemoteHost", GetGadgetText(#GadgetRemoteHost))
    WritePreferenceLong("OverwriteMode", GetGadgetState(#GadgetOverwrite))

    PreferenceGroup("RememberedPeers")
    ForEach Discovery()
      PeerLastSeen = Discovery()\LastSeen
      If Discovery()\IsLanShare And IsValidRememberedPeer(Discovery()\Host, Discovery()\Port, PeerLastSeen)
        PeerValue$ = Str(Discovery()\Port) + "|" + Discovery()\Name + "|" + Str(PeerLastSeen)
        WritePreferenceString(Discovery()\Host, PeerValue$)
      EndIf
    Next
    ClosePreferences()
  EndIf
EndProcedure

Procedure ApplyLoadedSettingsToUI()
  Protected SavedPort$
  Protected PrefPath$

  PrefPath$ = SettingsPath()
  If FileSize(PrefPath$) = -1 And FileSize(LegacySettingsPath()) <> -1
    PrefPath$ = LegacySettingsPath()
  EndIf

  If OpenPreferences(PrefPath$)
    PreferenceGroup("LanShare")
    SavedPort$ = ReadPreferenceString("Port", Str(#DefaultPort))
    SetGadgetText(#GadgetSharePath, DownloadPath$)
    SetGadgetText(#GadgetDownloadPath, DownloadPath$)
    SetGadgetText(#GadgetPort, SavedPort$)
    SetGadgetText(#GadgetRemoteHost, ReadPreferenceString("RemoteHost", ""))
    SetGadgetState(#GadgetOverwrite, ReadPreferenceLong("OverwriteMode", #OverwriteKeepBoth))
    ClosePreferences()
  Else
    SetGadgetText(#GadgetSharePath, DownloadPath$)
    SetGadgetText(#GadgetDownloadPath, DownloadPath$)
    SetGadgetText(#GadgetPort, Str(#DefaultPort))
  EndIf

  EnsureUsablePort(#False)
  SetGadgetState(#GadgetDiscoveryPeersOnly, #PB_Checkbox_Unchecked)
  DiscoveryFilterPeersOnly = #False
  RefreshDiscoveryList()
  UpdateDiscoveryDetails()
EndProcedure
