;
; Handy Media Player - Constants & Structures
;

#WindowWidth = 365
#WindowHeight = 70
#APP_NAME = "HandyMPlayer"
#EMAIL_NAME = "zonemaster60@gmail.com"

#Window_Main = 0
#Window_Video = 1
#Window_Lyrics = 2
#Window_ArtworkPreview = 3
#Window_Help = 4
#Window_Playlist = 5

#Gadget_Progress = 0
#Gadget_Artwork = 1
#Gadget_LyricsEditor = 2
#Gadget_MetadataPrimary = 3
#Gadget_MetadataSecondary = 4
#Gadget_ArtworkScroll = 5
#Gadget_ArtworkPreviewImage = 6
#Gadget_LibraryTree = 7
#Gadget_Playlist = 8
#Gadget_LibraryPlay = 9
#Gadget_LibraryAdd = 10
#Gadget_LibraryTitle = 11
#Gadget_PlaylistTitle = 12
#Gadget_LibrarySearch = 13
#Gadget_PlaylistUp = 14
#Gadget_PlaylistDown = 15
#Gadget_PlaylistRemove = 16
#Gadget_PlaylistClear = 17
#Gadget_SidebarSplitter = 18
#Gadget_PlaylistTabs = 19
#Gadget_PlaylistNew = 20
#Gadget_PlaylistRename = 21
#Gadget_PlaylistDelete = 22
#Gadget_QueueTitle = 23
#Gadget_QueueList = 24
#Gadget_QueueAdd = 25
#Gadget_QueueClear = 26
#Gadget_QueueUp = 27
#Gadget_QueueDown = 28
#Gadget_QueueRemove = 29
#Gadget_HelpEditor = 30
#Gadget_PlaylistPlay = 31
#Gadget_PlaylistPause = 32
#Gadget_PlaylistStop = 33
#Gadget_PlaylistShuffle = 34
#Gadget_PlaylistProgress = 35
#Gadget_PlaylistNowPlaying = 36

Enumeration
  #MovieState_Ready
  #MovieState_Playing
  #MovieState_Paused
  #MovieState_Stopped
EndEnumeration

Enumeration
  #Command_Load
  #Command_LoadFolder
  #Command_Exit
  #Command_PlayPause
  #Command_Stop
  #Command_Pause
  #Command_LoadPlaylist
  #Command_SavePlaylist
  #Command_ContextPlay
  #Command_ContextAdd
  #Command_ContextReveal
  #Command_PlayPrevious
  #Command_PlayNext
  #Command_PlaybackContinuous
  #Command_PlaybackShuffle
  #Command_PlaybackRepeat
  #Command_PlaylistRemove
  #Command_PlaylistClear
  #Command_PlaylistMoveUp
  #Command_PlaylistMoveDown
  #Command_VolumeFull
  #Command_VolumeHalf
  #Command_VolumeMute
  #Command_BalanceCenter
  #Command_BalanceLeft
  #Command_BalanceRight
  #Command_Help
  #Command_SizeDefault
  #Command_SizeX1
  #Command_SizeX2
  #Command_ShowPlaylist
  #Command_ShowLyrics
  #Command_ShowArtwork
  #Command_About
EndEnumeration

#LayoutPadding = 5
#ProgressBarHeight = 15
#ProgressBarLeft = 10
#ProgressBarRightMargin = 10

#ProgressScaleMax = 10000
#DefaultArtworkSize = 280
#MetadataPanelHeight = 36
#SidebarWidth = 300
#SidebarMinWidth = 220
#SidebarMaxWidth = 520
#SidebarSplitterWidth = 6
#SidebarButtonHeight = 28
#SidebarMinHeight = 620
#LyricsWindowWidth = 700
#LyricsWindowHeight = 560
#ArtworkPreviewWindowWidth = 900
#ArtworkPreviewWindowHeight = 700
#HelpWindowWidth = 860
#HelpWindowHeight = 700
#PlaylistWindowWidth = 420
#PlaylistWindowHeight = 520

#DownloadFolder = "downloads\"
#AlbumArtFolder = #DownloadFolder + "album-art\"
#LyricsFolder = #DownloadFolder + "lyrics\"
#CacheFolder = #DownloadFolder + "cache\"
#PlaylistStoreFolder = "playlists\"
#QueueStoreFile = #PlaylistStoreFolder + "_queue.m3u"
#HTTPUserAgent = "HandyMPlayer/1.0 (+https://github.com/zonemaster60)"

Structure TrackMetadata
  artist.s
  title.s
  query.s
  safeBaseName.s
EndStructure

Structure TrackLookup
  artist.s
  title.s
  artworkUrl.s
EndStructure

Structure EmbeddedMediaInfo
  artist.s
  title.s
  lyrics.s
  artworkFile.s
EndStructure

; WinAPI Constants (if not already defined in PB)
#GWL_STYLE = -16
#WS_CHILD = $40000000
#WS_CLIPCHILDREN = $02000000
#WS_CLIPSIBLINGS = $04000000
#SWP_NOMOVE = $0002
#SWP_NOSIZE = $0001
#SWP_NOZORDER = $0004
#SWP_FRAMECHANGED = $0020
#HWND_TOP = 0
#HWND_BOTTOM = 1
#SWP_NOACTIVATE = $0010

Structure WinPOINT
  x.l
  y.l
EndStructure

Structure WinRECT
  left.l
  top.l
  right.l
  bottom.l
EndStructure
