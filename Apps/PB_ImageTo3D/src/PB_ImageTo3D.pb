EnableExplicit

Enumeration
  #Window
EndEnumeration

Enumeration 1
  #MenuFileOpenImage
  #MenuFileLoadFrontMask
  #MenuFileLoadMidMask
  #MenuFileClearMasks
  #MenuFileExportLayers
  #MenuFileSaveViewport
  #MenuFileLoadProject
  #MenuFileSaveProject
  #MenuFileExit
  #MenuViewReset
  #MenuHelpContents
  #MenuHelpAbout
EndEnumeration

Enumeration 1
  #CameraMain
  #CameraDepth
  #LightMain
  #ImageSource
  #ImageBackLayer
  #ImageMidLayer
  #ImageFrontLayer
  #ImageFrontPreview
  #ImageMidPreview
  #ImageDepthPreview
  #ImageDepthPreviewThumb
  #TextureBack
  #TextureMid
  #TextureFront
  #MaterialBack
  #MaterialMid
  #MaterialFront
  #MeshBack
  #MeshMid
  #MeshFront
  #TextureDepth
  #MaterialDepth
  #MeshDepth
  #EntityBack
  #EntityMid
  #EntityFront
  #EntityDepth
EndEnumeration

Enumeration 1
  #TextTitle
  #TextFileLabel
  #TextFileValue
  #TextFrontMaskLabel
  #TextFrontMaskValue
  #TextMidMaskLabel
  #TextMidMaskValue
  #ButtonOpen
  #ButtonReset
  #ButtonLoadFrontMask
  #ButtonLoadMidMask
  #ButtonClearMasks
  #ButtonSaveProject
  #ButtonLoadProject
  #ButtonExportLayers
  #ScrollViewport
  #CanvasViewport
  #ScrollPanel
  #PanelMode
  #ImagePreviewFront
  #ImagePreviewMid
  #TextDepthLabel
  #TrackDepth
  #TextDepthValue
  #TextSensitivityLabel
  #TrackSensitivity
  #TextSensitivityValue
  #TextSmoothingLabel
  #TrackSmoothing
  #TextSmoothingValue
  #TextZoomLabel
  #TrackZoom
  #TextZoomValue
  #TextFrontThresholdLabel
  #TrackFrontThreshold
  #TextFrontThresholdValue
  #TextMidLowLabel
  #TrackMidLow
  #TextMidLowValue
  #TextMidHighLabel
  #TrackMidHigh
  #TextMidHighValue
  #ImagePreviewDepth
  #TextMeshStrengthLabel
  #TrackMeshStrength
  #TextMeshStrengthValue
  #TextInfo
  #TextFooterInfo
  #TextQualityLabel
  #ComboQuality
  #CheckAutoSaveAssets
  #TextBlurLabel
  #TrackBlur
  #TextBlurValue
  #TextMotionXLabel
  #TrackMotionX
  #TextMotionYLabel
  #TrackMotionY
  #TextFeatherLabel
  #TrackFeather
  #TextTiltLabel
  #TrackTilt
  #TextTiltValue
EndEnumeration

#APP_NAME = "PB_ImageTo3D"
Global version.s = "v1.0.0.0"
Global AppPath.s = GetPathPart(ProgramFilename())
SetCurrentDirectory(AppPath)

#WindowW = 1220
#WindowH = 760
#ViewportX = 12
#ViewportY = 12
#ViewportVisibleW = 730
#ViewportVisibleH = 700
#ViewportW = 1040
#ViewportH = 780
#PanelAreaX = 748
#PanelAreaY = 12
#PanelAreaW = 440
#PanelAreaH = 700
#PanelInnerW = 450
#PanelInnerH = 1140
#PanelX = 10
#PanelY = 10
#PanelW = 408
#MaxTextureDimension = 1400
#BackRotateScale = 0.26
#MidRotateScale = 0.42
#FrontRotateScale = 0.62
#DepthRotateScale = 0.52
#BackMoveXScale = 0.08
#BackMoveYScale = 0.05
#MidMoveXScale = 0.18
#MidMoveYScale = 0.11
#FrontMoveXScale = 0.28
#FrontMoveYScale = 0.17
#DepthMoveXScale = 0.07
#DepthMoveYScale = 0.04
#BackLayerZ = -1.9
#MidLayerZ = 0.0
#FrontLayerZ = 1.9
#DepthCameraMotionScale = 0.10
#DepthCameraDistanceOffset = -0.1
#MaskSmoothPasses = 2
#DepthSmoothPasses = 3
#BackInpaintPasses = 6
#MidInpaintPasses = 4
#FrontColorBleedPasses = 2
#RebuildDebounceMS = 180

Global Quit.i
Global Event.i
Global SceneReady.i
Global PendingImageRebuild.i
Global PendingImageRebuildAt.i
Global LoadedImageFile.s = ""
Global LoadedImageName.s = "No image loaded"
Global FrontMaskFile.s = ""
Global MidMaskFile.s = ""
Global LoadedProjectFile.s = ""

Global ImageW.i
Global ImageH.i
Global PixelCount.i
Global BasePlaneW.f = 12.0
Global BasePlaneH.f

Global InputNX.f
Global InputNY.f
Global TargetYaw.f
Global TargetPitch.f
Global CurrentYaw.f
Global CurrentPitch.f
Global TargetCamX.f
Global TargetCamY.f
Global CurrentCamX.f
Global CurrentCamY.f
Global FramesThisSecond.i
Global LastFPSUpdate.i
Global CurrentFPS.f

Global DepthStrength.f = 1.0
Global MouseSensitivity.f = 1.0
Global SmoothFactor.f = 0.12
Global CameraDistance.f = 18.0
Global TiltIntensity.f = 1.35
Global MeshStrength.f = 0.80
Global MotionXStrength.f = 1.0
Global MotionYStrength.f = 1.0
Global ForegroundFeather.i = 2
Global BackgroundSoftFocus.i = 3
Global ParallaxPreset.i = 1
Global AutoSaveAssetsEnabled.i
Global PresetRotationScale.f = 1.0
Global PresetOffsetScale.f = 1.0
Global PresetCameraScale.f = 1.0
Global PresetMeshScale.f = 1.0
Global PresetSmoothScale.f = 1.0
Global AutoFrontThreshold.i = 168
Global AutoMidLow.i = 78
Global AutoMidHigh.i = 196

Global Dim CombinedDepthValues.a(0)
Global Dim MeshData.MeshVertex(0)

Global Dim SourcePixels.l(0)
Global Dim SourceLuma.a(0)
Global Dim FrontMaskValues.a(0)
Global Dim MidMaskValues.a(0)
Global Dim TempColorValues.l(0)
Global Dim TempColorWork.l(0)
Global Dim TempIntValues.i(0)

Declare.i ActiveViewIsDepthMesh()
Declare.i ActiveViewIsSplit()
Declare RebuildImageWithCurrentMasks()
Declare ApplyParallaxPreset(Preset.i)
Declare SaveGeneratedAnalysisFiles()
Declare UpdateValueLabels()

Procedure.s DisplayName(Path.s, EmptyText.s)
  If Path = ""
    ProcedureReturn EmptyText
  EndIf

  ProcedureReturn GetFilePart(Path)
EndProcedure

Procedure.f ClampFloat(Value.f, Minimum.f, Maximum.f)
  If Value < Minimum
    ProcedureReturn Minimum
  EndIf

  If Value > Maximum
    ProcedureReturn Maximum
  EndIf

  ProcedureReturn Value
EndProcedure

Procedure.i ClampInt(Value.i, Minimum.i, Maximum.i)
  If Value < Minimum
    ProcedureReturn Minimum
  EndIf

  If Value > Maximum
    ProcedureReturn Maximum
  EndIf

  ProcedureReturn Value
EndProcedure

Procedure ResetLoadedImageState()
  LoadedImageFile = ""
  LoadedImageName = "No image loaded"
  SetWindowTitle(#Window, #APP_NAME + " - " + version)
  UpdateValueLabels()
EndProcedure

Procedure.s ResolveProjectPath(Path.s, ProjectFile.s)
  Protected Candidate.s

  If Path = "" Or FileSize(Path) >= 0
    ProcedureReturn Path
  EndIf

  If GetPathPart(Path) = ""
    Candidate = GetPathPart(ProjectFile) + Path
    If FileSize(Candidate) >= 0
      ProcedureReturn Candidate
    EndIf
  EndIf

  ProcedureReturn Path
EndProcedure

Procedure.s StoredProjectPath(Path.s, ProjectFile.s)
  If Path <> "" And LCase(GetPathPart(Path)) = LCase(GetPathPart(ProjectFile))
    ProcedureReturn GetFilePart(Path)
  EndIf

  ProcedureReturn Path
EndProcedure

Procedure.i ArrayPixelIndex(X.i, Y.i)
  ProcedureReturn X + (Y * ImageW)
EndProcedure

Procedure.i MaskValueAt(Array Values.a(1), X.i, Y.i)
  X = ClampInt(X, 0, ImageW - 1)
  Y = ClampInt(Y, 0, ImageH - 1)
  ProcedureReturn Values(ArrayPixelIndex(X, Y))
EndProcedure

Procedure.i ColorValueAt(Array Values.l(1), X.i, Y.i)
  X = ClampInt(X, 0, ImageW - 1)
  Y = ClampInt(Y, 0, ImageH - 1)
  ProcedureReturn Values(ArrayPixelIndex(X, Y))
EndProcedure

Procedure SmoothByteArray(Array Values.a(1), Passes.i)
  Protected PassIndex.i
  Protected x.i
  Protected y.i
  Protected Index.i
  Protected Sum.i

  If PixelCount <= 0 Or Passes <= 0
    ProcedureReturn
  EndIf

  ReDim TempIntValues(PixelCount - 1)

  For PassIndex = 1 To Passes
    For y = 0 To ImageH - 1
      For x = 0 To ImageW - 1
        Index = ArrayPixelIndex(x, y)
        Sum = Values(Index) * 4
        Sum + MaskValueAt(Values(), x - 1, y)
        Sum + MaskValueAt(Values(), x + 1, y)
        Sum + MaskValueAt(Values(), x, y - 1)
        Sum + MaskValueAt(Values(), x, y + 1)
        TempIntValues(Index) = ClampInt(Sum / 8, 0, 255)
      Next x
    Next y

    For Index = 0 To PixelCount - 1
      Values(Index) = TempIntValues(Index)
    Next Index
  Next PassIndex
EndProcedure

Procedure ExpandMaskArray(Array Values.a(1), Passes.i, ExpandBias.i)
  Protected PassIndex.i
  Protected x.i
  Protected y.i
  Protected Index.i
  Protected MaxValue.i
  Protected ExpandedValue.i

  If PixelCount <= 0 Or Passes <= 0
    ProcedureReturn
  EndIf

  ReDim TempIntValues(PixelCount - 1)

  For PassIndex = 1 To Passes
    For y = 0 To ImageH - 1
      For x = 0 To ImageW - 1
        Index = ArrayPixelIndex(x, y)
        MaxValue = Values(Index)
        If MaskValueAt(Values(), x - 1, y) > MaxValue : MaxValue = MaskValueAt(Values(), x - 1, y) : EndIf
        If MaskValueAt(Values(), x + 1, y) > MaxValue : MaxValue = MaskValueAt(Values(), x + 1, y) : EndIf
        If MaskValueAt(Values(), x, y - 1) > MaxValue : MaxValue = MaskValueAt(Values(), x, y - 1) : EndIf
        If MaskValueAt(Values(), x, y + 1) > MaxValue : MaxValue = MaskValueAt(Values(), x, y + 1) : EndIf
        ExpandedValue = MaxValue - ExpandBias
        TempIntValues(Index) = ClampInt((Values(Index) * 2 + ExpandedValue * 3) / 5, 0, 255)
      Next x
    Next y

    For Index = 0 To PixelCount - 1
      Values(Index) = TempIntValues(Index)
    Next Index
  Next PassIndex
EndProcedure

Procedure ApplyEntityTransform(Entity.i, RotateScale.f, MoveXScale.f, MoveYScale.f, DepthZ.f)
  If IsEntity(Entity) = 0
    ProcedureReturn
  EndIf

  RotateEntity(Entity, -90 - (CurrentPitch * RotateScale * TiltIntensity), 0, CurrentYaw * RotateScale * TiltIntensity, #PB_Absolute)
  MoveEntity(Entity, -InputNX * DepthStrength * MoveXScale * PresetOffsetScale, InputNY * DepthStrength * MoveYScale * PresetOffsetScale, DepthZ, #PB_Absolute)
EndProcedure

Procedure ApplyCameraTransform(Camera.i, MotionScale.f, DistanceOffset.f)
  If IsCamera(Camera) = 0
    ProcedureReturn
  EndIf

  MoveCamera(Camera, CurrentCamX * MotionScale, CurrentCamY * MotionScale, CameraDistance + DistanceOffset, #PB_Absolute)
  CameraLookAt(Camera, 0, 0, 0)
EndProcedure

Procedure DrawViewportOverlay()
  Protected QualityName.s
  Protected OverlayY.i = 10

  Select ParallaxPreset
    Case 0
      QualityName = "Gentle"
    Case 2
      QualityName = "Strong"
    Default
      QualityName = "Balanced"
  EndSelect

  If StartDrawing(ScreenOutput()) = 0
    ProcedureReturn
  EndIf
  DrawingMode(#PB_2DDrawing_AlphaBlend)
  Box(10, 10, 300, 86, RGBA(8, 14, 22, 150))
  DrawingMode(#PB_2DDrawing_Transparent)
  DrawText(20, OverlayY, "Preset: " + QualityName + "   FPS: " + StrF(CurrentFPS, 1), RGB(232, 240, 248))
  DrawText(20, OverlayY + 20, "Blur: " + Str(BackgroundSoftFocus) + "   Feather: " + Str(ForegroundFeather), RGB(214, 224, 236))
  DrawText(20, OverlayY + 40, "Motion X: " + StrF(MotionXStrength, 2) + "   Motion Y: " + StrF(MotionYStrength, 2), RGB(214, 224, 236))
  DrawText(20, OverlayY + 60, "Auto-save: " + StringField("Off|On", AutoSaveAssetsEnabled + 1, "|"), RGB(196, 212, 226))
  StopDrawing()
EndProcedure

Procedure BlurImageSoft(ImageNumber.i, Passes.i)
  Protected PassIndex.i
  Protected x.i
  Protected y.i
  Protected Index.i
  Protected SumRed.i
  Protected SumGreen.i
  Protected SumBlue.i
  Protected AlphaValue.i
  Protected Color.i

  If IsImage(ImageNumber) = 0 Or Passes <= 0 Or PixelCount <= 0
    ProcedureReturn
  EndIf

  ReDim TempColorValues(PixelCount - 1)
  ReDim TempColorWork(PixelCount - 1)

  If StartDrawing(ImageOutput(ImageNumber)) = 0
    ProcedureReturn
  EndIf

  For y = 0 To ImageH - 1
    For x = 0 To ImageW - 1
      TempColorValues(ArrayPixelIndex(x, y)) = Point(x, y)
    Next x
  Next y
  StopDrawing()

  For PassIndex = 1 To Passes
    For y = 0 To ImageH - 1
      For x = 0 To ImageW - 1
        Index = ArrayPixelIndex(x, y)
        Color = TempColorValues(Index)
        AlphaValue = Alpha(Color)

        SumRed = Red(Color) * 4
        SumGreen = Green(Color) * 4
        SumBlue = Blue(Color) * 4

        Color = ColorValueAt(TempColorValues(), x - 1, y)
        SumRed + Red(Color)
        SumGreen + Green(Color)
        SumBlue + Blue(Color)

        Color = ColorValueAt(TempColorValues(), x + 1, y)
        SumRed + Red(Color)
        SumGreen + Green(Color)
        SumBlue + Blue(Color)

        Color = ColorValueAt(TempColorValues(), x, y - 1)
        SumRed + Red(Color)
        SumGreen + Green(Color)
        SumBlue + Blue(Color)

        Color = ColorValueAt(TempColorValues(), x, y + 1)
        SumRed + Red(Color)
        SumGreen + Green(Color)
        SumBlue + Blue(Color)

        TempColorWork(Index) = RGBA(ClampInt(SumRed / 8, 0, 255), ClampInt(SumGreen / 8, 0, 255), ClampInt(SumBlue / 8, 0, 255), AlphaValue)
      Next x
    Next y

    For Index = 0 To PixelCount - 1
      TempColorValues(Index) = TempColorWork(Index)
    Next Index
  Next PassIndex

  If StartDrawing(ImageOutput(ImageNumber)) = 0
    ProcedureReturn
  EndIf

  DrawingMode(#PB_2DDrawing_AllChannels)
  For y = 0 To ImageH - 1
    For x = 0 To ImageW - 1
      Plot(x, y, TempColorValues(ArrayPixelIndex(x, y)))
    Next x
  Next y
  StopDrawing()
EndProcedure

Procedure SetParallaxPresetScales(Preset.i)
  Select Preset
    Case 0
      PresetRotationScale = 0.70
      PresetOffsetScale = 0.72
      PresetCameraScale = 0.76
      PresetMeshScale = 0.82
      PresetSmoothScale = 1.16

    Case 2
      PresetRotationScale = 1.35
      PresetOffsetScale = 1.32
      PresetCameraScale = 1.28
      PresetMeshScale = 1.22
      PresetSmoothScale = 0.88

    Default
      PresetRotationScale = 1.0
      PresetOffsetScale = 1.0
      PresetCameraScale = 1.0
      PresetMeshScale = 1.0
      PresetSmoothScale = 1.0
  EndSelect
EndProcedure

Procedure ApplyParallaxPreset(Preset.i)
  ParallaxPreset = ClampInt(Preset, 0, 2)
  SetParallaxPresetScales(ParallaxPreset)
  If IsGadget(#ComboQuality)
    SetGadgetState(#ComboQuality, ParallaxPreset)
  EndIf
EndProcedure

Procedure ResetView()
  TargetYaw = 0.0
  TargetPitch = 0.0
  CurrentYaw = 0.0
  CurrentPitch = 0.0
  TargetCamX = 0.0
  TargetCamY = 0.0
  CurrentCamX = 0.0
  CurrentCamY = 0.0
  InputNX = 0.0
  InputNY = 0.0
EndProcedure

Procedure UpdateSceneVisibility()
  If IsCamera(#CameraMain)
    If ActiveViewIsSplit()
      ResizeCamera(#CameraMain, 0, 0, 50, 100)
      If IsCamera(#CameraDepth) : ResizeCamera(#CameraDepth, 50, 0, 50, 100) : EndIf
    Else
      ResizeCamera(#CameraMain, 0, 0, 100, 100)
      If IsCamera(#CameraDepth) : ResizeCamera(#CameraDepth, 0, 0, 0, 0) : EndIf
    EndIf
  EndIf

  If ActiveViewIsDepthMesh()
    If IsEntity(#EntityBack) : HideEntity(#EntityBack, 1) : EndIf
    If IsEntity(#EntityMid) : HideEntity(#EntityMid, 1) : EndIf
    If IsEntity(#EntityFront) : HideEntity(#EntityFront, 1) : EndIf
    If IsEntity(#EntityDepth) : HideEntity(#EntityDepth, 0) : EndIf
  Else
    If IsEntity(#EntityBack) : HideEntity(#EntityBack, 0) : EndIf
    If IsEntity(#EntityMid) : HideEntity(#EntityMid, 0) : EndIf
    If IsEntity(#EntityFront) : HideEntity(#EntityFront, 0) : EndIf
    If IsEntity(#EntityDepth) : HideEntity(#EntityDepth, Bool(ActiveViewIsSplit() = 0)) : EndIf
  EndIf
EndProcedure

Procedure.i ActiveViewIsDepthMesh()
  ProcedureReturn Bool(GetGadgetState(#PanelMode) = 1)
EndProcedure

Procedure.i ActiveViewIsSplit()
  ProcedureReturn Bool(GetGadgetState(#PanelMode) = 2)
EndProcedure

Procedure UpdatePreviewGadget(Gadget.i, SourceImage.i, PreviewImage.i)
  Protected TargetW.i = 120
  Protected TargetH.i = 120
  Protected Ratio.f
  Protected NewW.i
  Protected NewH.i

  If IsImage(SourceImage) = 0
    SetGadgetState(Gadget, 0)
    ProcedureReturn
  EndIf

  If IsImage(PreviewImage)
    FreeImage(PreviewImage)
  EndIf

  If CopyImage(SourceImage, PreviewImage) = 0
    SetGadgetState(Gadget, ImageID(SourceImage))
    ProcedureReturn
  EndIf

  Ratio = ImageWidth(PreviewImage) / ImageHeight(PreviewImage)
  If Ratio >= 1.0
    NewW = TargetW
    NewH = Int(TargetH / Ratio)
  Else
    NewH = TargetH
    NewW = Int(TargetW * Ratio)
  EndIf

  If NewW < 1 : NewW = 1 : EndIf
  If NewH < 1 : NewH = 1 : EndIf

  ResizeImage(PreviewImage, NewW, NewH, #PB_Image_Smooth)
  SetGadgetState(Gadget, ImageID(PreviewImage))
EndProcedure

Procedure BuildDepthPreviewImage()
  Protected x.i
  Protected y.i
  Protected Index.i
  Protected DepthValue.i

  If PixelCount <= 0
    ProcedureReturn
  EndIf

  If IsImage(#ImageDepthPreview)
    FreeImage(#ImageDepthPreview)
  EndIf

  If CreateImage(#ImageDepthPreview, ImageW, ImageH, 32, #PB_Image_Transparent) = 0
    ProcedureReturn
  EndIf

  If StartDrawing(ImageOutput(#ImageDepthPreview)) = 0
    FreeImage(#ImageDepthPreview)
    ProcedureReturn
  EndIf

  DrawingMode(#PB_2DDrawing_AllChannels)
  For y = 0 To ImageH - 1
    For x = 0 To ImageW - 1
      Index = x + (y * ImageW)
      DepthValue = CombinedDepthValues(Index)
      Plot(x, y, RGBA(DepthValue, DepthValue, DepthValue, 255))
    Next x
  Next y
  StopDrawing()
EndProcedure

Procedure UpdatePreviewImages()
  If IsImage(#ImageFrontLayer)
    UpdatePreviewGadget(#ImagePreviewFront, #ImageFrontLayer, #ImageFrontPreview)
  Else
    SetGadgetState(#ImagePreviewFront, 0)
  EndIf

  If IsImage(#ImageMidLayer)
    UpdatePreviewGadget(#ImagePreviewMid, #ImageMidLayer, #ImageMidPreview)
  Else
    SetGadgetState(#ImagePreviewMid, 0)
  EndIf

  If IsImage(#ImageDepthPreview)
    UpdatePreviewGadget(#ImagePreviewDepth, #ImageDepthPreview, #ImageDepthPreviewThumb)
  Else
    SetGadgetState(#ImagePreviewDepth, 0)
  EndIf
EndProcedure

Procedure UpdateValueLabels()
  SetGadgetText(#TextFileValue, LoadedImageName)
  SetGadgetText(#TextFrontMaskValue, DisplayName(FrontMaskFile, "Auto-generated from image brightness"))
  SetGadgetText(#TextMidMaskValue, DisplayName(MidMaskFile, "Auto-generated from image brightness"))
  SetGadgetText(#TextBlurValue, Str(BackgroundSoftFocus) + " passes")
  SetGadgetText(#TextMotionXLabel, "Horizontal Motion " + StrF(MotionXStrength, 2))
  SetGadgetText(#TextMotionYLabel, "Vertical Motion " + StrF(MotionYStrength, 2))
  SetGadgetText(#TextFeatherLabel, "Foreground Feather " + Str(ForegroundFeather))
  SetGadgetText(#TextDepthValue, StrF(DepthStrength, 2))
  SetGadgetText(#TextSensitivityValue, StrF(MouseSensitivity, 2))
  SetGadgetText(#TextSmoothingValue, StrF(SmoothFactor, 2))
  SetGadgetText(#TextZoomValue, StrF(CameraDistance, 1))
  SetGadgetText(#TextTiltValue, StrF(TiltIntensity, 2))
  SetGadgetText(#TextMeshStrengthValue, StrF(MeshStrength, 2))
  SetGadgetText(#TextFrontThresholdValue, Str(AutoFrontThreshold))
  SetGadgetText(#TextMidLowValue, Str(AutoMidLow))
  SetGadgetText(#TextMidHighValue, Str(AutoMidHigh))
EndProcedure

Procedure ReadControlValues()
  DepthStrength = GetGadgetState(#TrackDepth) / 100.0
  MouseSensitivity = GetGadgetState(#TrackSensitivity) / 100.0
  SmoothFactor = GetGadgetState(#TrackSmoothing) / 100.0
  CameraDistance = GetGadgetState(#TrackZoom) / 10.0
  TiltIntensity = GetGadgetState(#TrackTilt) / 100.0
  MeshStrength = GetGadgetState(#TrackMeshStrength) / 50.0
  MotionXStrength = GetGadgetState(#TrackMotionX) / 100.0
  MotionYStrength = GetGadgetState(#TrackMotionY) / 100.0
  ForegroundFeather = GetGadgetState(#TrackFeather)
  BackgroundSoftFocus = GetGadgetState(#TrackBlur)
  AutoSaveAssetsEnabled = GetGadgetState(#CheckAutoSaveAssets)
  AutoFrontThreshold = GetGadgetState(#TrackFrontThreshold)
  AutoMidLow = GetGadgetState(#TrackMidLow)
  AutoMidHigh = GetGadgetState(#TrackMidHigh)

  If AutoMidLow >= AutoMidHigh
    AutoMidHigh = ClampInt(AutoMidLow + 1, 1, 255)
    SetGadgetState(#TrackMidHigh, AutoMidHigh)
  EndIf

  UpdateValueLabels()
EndProcedure

Procedure ApplyControlValues(Depth.f, Sensitivity.f, Smoothing.f, Zoom.f)
  SetGadgetState(#TrackDepth, ClampInt(Int(Depth * 100.0), 20, 200))
  SetGadgetState(#TrackSensitivity, ClampInt(Int(Sensitivity * 100.0), 20, 200))
  SetGadgetState(#TrackSmoothing, ClampInt(Int(Smoothing * 100.0), 5, 60))
  SetGadgetState(#TrackZoom, ClampInt(Int(Zoom * 10.0), 120, 320))
  SetGadgetState(#TrackTilt, ClampInt(Int(TiltIntensity * 100.0), 40, 300))
  SetGadgetState(#TrackMeshStrength, ClampInt(Int(MeshStrength * 50.0), 20, 250))
  SetGadgetState(#TrackMotionX, ClampInt(Int(MotionXStrength * 100.0), 40, 220))
  SetGadgetState(#TrackMotionY, ClampInt(Int(MotionYStrength * 100.0), 40, 220))
  SetGadgetState(#TrackFeather, ClampInt(ForegroundFeather, 0, 8))
  SetGadgetState(#TrackBlur, ClampInt(BackgroundSoftFocus, 0, 8))
  SetGadgetState(#CheckAutoSaveAssets, AutoSaveAssetsEnabled)
  SetGadgetState(#TrackFrontThreshold, ClampInt(AutoFrontThreshold, 1, 255))
  SetGadgetState(#TrackMidLow, ClampInt(AutoMidLow, 0, 254))
  SetGadgetState(#TrackMidHigh, ClampInt(AutoMidHigh, 1, 255))
  ReadControlValues()
EndProcedure

Procedure FreeSceneResources()
  If IsEntity(#EntityBack) : FreeEntity(#EntityBack) : EndIf
  If IsEntity(#EntityMid) : FreeEntity(#EntityMid) : EndIf
  If IsEntity(#EntityFront) : FreeEntity(#EntityFront) : EndIf
  If IsEntity(#EntityDepth) : FreeEntity(#EntityDepth) : EndIf

  If IsMesh(#MeshBack) : FreeMesh(#MeshBack) : EndIf
  If IsMesh(#MeshMid) : FreeMesh(#MeshMid) : EndIf
  If IsMesh(#MeshFront) : FreeMesh(#MeshFront) : EndIf
  If IsMesh(#MeshDepth) : FreeMesh(#MeshDepth) : EndIf

  If IsMaterial(#MaterialBack) : FreeMaterial(#MaterialBack) : EndIf
  If IsMaterial(#MaterialMid) : FreeMaterial(#MaterialMid) : EndIf
  If IsMaterial(#MaterialFront) : FreeMaterial(#MaterialFront) : EndIf
  If IsMaterial(#MaterialDepth) : FreeMaterial(#MaterialDepth) : EndIf

  If IsTexture(#TextureBack) : FreeTexture(#TextureBack) : EndIf
  If IsTexture(#TextureMid) : FreeTexture(#TextureMid) : EndIf
  If IsTexture(#TextureFront) : FreeTexture(#TextureFront) : EndIf
  If IsTexture(#TextureDepth) : FreeTexture(#TextureDepth) : EndIf

  If IsImage(#ImageBackLayer) : FreeImage(#ImageBackLayer) : EndIf
  If IsImage(#ImageMidLayer) : FreeImage(#ImageMidLayer) : EndIf
  If IsImage(#ImageFrontLayer) : FreeImage(#ImageFrontLayer) : EndIf
  If IsImage(#ImageSource) : FreeImage(#ImageSource) : EndIf
  If IsImage(#ImageFrontPreview) : FreeImage(#ImageFrontPreview) : EndIf
  If IsImage(#ImageMidPreview) : FreeImage(#ImageMidPreview) : EndIf
  If IsImage(#ImageDepthPreview) : FreeImage(#ImageDepthPreview) : EndIf
  If IsImage(#ImageDepthPreviewThumb) : FreeImage(#ImageDepthPreviewThumb) : EndIf

  SceneReady = #False
EndProcedure

Procedure ApplyLayerTransforms()
  If SceneReady = 0
    ApplyCameraTransform(#CameraMain, 0.0, 0.0)
    ProcedureReturn
  EndIf

  If ActiveViewIsSplit()
    ApplyEntityTransform(#EntityBack, #BackRotateScale, #BackMoveXScale, #BackMoveYScale, #BackLayerZ)
    ApplyEntityTransform(#EntityMid, #MidRotateScale, #MidMoveXScale, #MidMoveYScale, #MidLayerZ)
    ApplyEntityTransform(#EntityFront, #FrontRotateScale, #FrontMoveXScale, #FrontMoveYScale, #FrontLayerZ)
    ApplyEntityTransform(#EntityDepth, #DepthRotateScale, #DepthMoveXScale, #DepthMoveYScale, #MidLayerZ)
    ApplyCameraTransform(#CameraMain, 1.0, 0.0)
    ApplyCameraTransform(#CameraDepth, #DepthCameraMotionScale, #DepthCameraDistanceOffset)

    ProcedureReturn
  EndIf

  If ActiveViewIsDepthMesh()
    ApplyEntityTransform(#EntityDepth, #DepthRotateScale, #DepthMoveXScale, #DepthMoveYScale, #MidLayerZ)
    ApplyCameraTransform(#CameraMain, #DepthCameraMotionScale, #DepthCameraDistanceOffset)
    ApplyCameraTransform(#CameraDepth, #DepthCameraMotionScale, #DepthCameraDistanceOffset)

    ProcedureReturn
  EndIf

  ApplyEntityTransform(#EntityBack, #BackRotateScale, #BackMoveXScale, #BackMoveYScale, #BackLayerZ)
  ApplyEntityTransform(#EntityMid, #MidRotateScale, #MidMoveXScale, #MidMoveYScale, #MidLayerZ)
  ApplyEntityTransform(#EntityFront, #FrontRotateScale, #FrontMoveXScale, #FrontMoveYScale, #FrontLayerZ)
  ApplyCameraTransform(#CameraMain, 1.0, 0.0)
  ApplyCameraTransform(#CameraDepth, #DepthCameraMotionScale, #DepthCameraDistanceOffset)
EndProcedure

Procedure.i ResizeLoadedImageIfNeeded()
  Protected NewW.i
  Protected NewH.i
  Protected Scale.f

  ImageW = ImageWidth(#ImageSource)
  ImageH = ImageHeight(#ImageSource)
  If ImageW <= #MaxTextureDimension And ImageH <= #MaxTextureDimension
    ProcedureReturn #True
  EndIf

  If ImageW >= ImageH
    Scale = #MaxTextureDimension / ImageW
  Else
    Scale = #MaxTextureDimension / ImageH
  EndIf

  NewW = Int(ImageW * Scale)
  NewH = Int(ImageH * Scale)
  If NewW < 1 : NewW = 1 : EndIf
  If NewH < 1 : NewH = 1 : EndIf

  If ResizeImage(#ImageSource, NewW, NewH, #PB_Image_Smooth) = 0
    MessageRequester("Resize Error", "The loaded image is too large and could not be resized for the 3D texture pipeline.")
    ProcedureReturn #False
  EndIf

  ImageW = ImageWidth(#ImageSource)
  ImageH = ImageHeight(#ImageSource)
  ProcedureReturn #True
EndProcedure

Procedure.i CaptureSourcePixels()
  Protected x.i
  Protected y.i
  Protected Index.i
  Protected Color.i
  Protected AlphaValue.i
  Protected Luma.i

  PixelCount = ImageW * ImageH
  If PixelCount <= 0
    ProcedureReturn #False
  EndIf

  ReDim SourcePixels(PixelCount - 1)
  ReDim SourceLuma(PixelCount - 1)

  If StartDrawing(ImageOutput(#ImageSource)) = 0
    ProcedureReturn #False
  EndIf

  DrawingMode(#PB_2DDrawing_AllChannels)

  Index = 0
  For y = 0 To ImageH - 1
    For x = 0 To ImageW - 1
      Color = Point(x, y)
      SourcePixels(Index) = Color
      AlphaValue = Alpha(Color)
      Luma = (Red(Color) * 30 + Green(Color) * 59 + Blue(Color) * 11) / 100
      If AlphaValue = 0
        Luma = 0
      ElseIf AlphaValue < 255
        Luma = (Luma * AlphaValue) / 255
      EndIf
      SourceLuma(Index) = ClampInt(Luma, 0, 255)
      Index + 1
    Next x
  Next y

  StopDrawing()
  ProcedureReturn #True
EndProcedure

Procedure.i LoadMaskArrayFromFile(FileName.s, Width.i, Height.i, Array TargetMask.a(1))
  Protected MaskImage.i
  Protected x.i
  Protected y.i
  Protected Index.i
  Protected Color.i
  Protected Value.i

  If FileName = ""
    ProcedureReturn #False
  EndIf

  If FileSize(FileName) < 0
    ProcedureReturn #False
  EndIf

  MaskImage = LoadImage(#PB_Any, FileName)
  If MaskImage = 0
    ProcedureReturn #False
  EndIf

  If ImageWidth(MaskImage) <> Width Or ImageHeight(MaskImage) <> Height
    If ResizeImage(MaskImage, Width, Height, #PB_Image_Smooth) = 0
      FreeImage(MaskImage)
      ProcedureReturn #False
    EndIf
  EndIf

  If StartDrawing(ImageOutput(MaskImage)) = 0
    FreeImage(MaskImage)
    ProcedureReturn #False
  EndIf

  DrawingMode(#PB_2DDrawing_AllChannels)

  Index = 0
  For y = 0 To Height - 1
    For x = 0 To Width - 1
      Color = Point(x, y)
      Value = (Red(Color) * 30 + Green(Color) * 59 + Blue(Color) * 11) / 100
      If Alpha(Color) = 0
        Value = 0
      ElseIf Alpha(Color) < 255
        Value = (Value * Alpha(Color)) / 255
      EndIf
      TargetMask(Index) = ClampInt(Value, 0, 255)
      Index + 1
    Next x
  Next y

  StopDrawing()
  FreeImage(MaskImage)
  ProcedureReturn #True
EndProcedure

Procedure.i SoftBand(Value.i, InnerMin.i, InnerMax.i, Feather.i)
  If Feather <= 0
    ProcedureReturn Bool(Value >= InnerMin And Value <= InnerMax) * 255
  EndIf

  If Value <= InnerMin - Feather Or Value >= InnerMax + Feather
    ProcedureReturn 0
  EndIf

  If Value >= InnerMin And Value <= InnerMax
    ProcedureReturn 255
  EndIf

  If Value < InnerMin
    ProcedureReturn ClampInt((255 * (Value - (InnerMin - Feather))) / Feather, 0, 255)
  EndIf

  ProcedureReturn ClampInt((255 * ((InnerMax + Feather) - Value)) / Feather, 0, 255)
EndProcedure

Procedure.i NeighborhoodContrast(X.i, Y.i)
  Protected Center.i = SourceLuma(ArrayPixelIndex(X, Y))
  Protected Difference.i
  Protected Total.i
  Protected Count.i

  If X > 0
    Difference = Abs(Center - SourceLuma(ArrayPixelIndex(X - 1, Y)))
    Total + Difference
    Count + 1
  EndIf

  If X < ImageW - 1
    Difference = Abs(Center - SourceLuma(ArrayPixelIndex(X + 1, Y)))
    Total + Difference
    Count + 1
  EndIf

  If Y > 0
    Difference = Abs(Center - SourceLuma(ArrayPixelIndex(X, Y - 1)))
    Total + Difference
    Count + 1
  EndIf

  If Y < ImageH - 1
    Difference = Abs(Center - SourceLuma(ArrayPixelIndex(X, Y + 1)))
    Total + Difference
    Count + 1
  EndIf

  If Count = 0
    ProcedureReturn 0
  EndIf

  ProcedureReturn ClampInt((Total * 3) / Count, 0, 255)
EndProcedure

Procedure BalanceMasks()
  Protected Index.i
  Protected FrontAlpha.i
  Protected MidAlpha.i

  For Index = 0 To PixelCount - 1
    FrontAlpha = FrontMaskValues(Index)
    MidAlpha = MidMaskValues(Index)

    MidAlpha = (MidAlpha * (255 - FrontAlpha)) / 255
    FrontAlpha = ClampInt(FrontAlpha + (FrontAlpha * MidAlpha) / 1024, 0, 255)

    FrontMaskValues(Index) = FrontAlpha
    MidMaskValues(Index) = ClampInt(MidAlpha, 0, 255)
  Next Index
EndProcedure

Procedure FeatherMaskEdges(Array Values.a(1), Radius.i)
  Protected PassIndex.i

  If Radius <= 0
    ProcedureReturn
  EndIf

  For PassIndex = 1 To Radius
    SmoothByteArray(Values(), 1)
  Next PassIndex
EndProcedure

Procedure BuildDepthFromMasks()
  Protected Index.i
  Protected FrontAlpha.i
  Protected MidAlpha.i
  Protected BackgroundDepth.i
  Protected MidDepth.i
  Protected FrontDepth.i
  Protected DepthValue.i

  ReDim CombinedDepthValues(PixelCount - 1)

  For Index = 0 To PixelCount - 1
    FrontAlpha = FrontMaskValues(Index)
    MidAlpha = MidMaskValues(Index)
    BackgroundDepth = 48 + (SourceLuma(Index) / 5)
    MidDepth = 118 + (SourceLuma(Index) / 4) + (MidAlpha / 6)
    FrontDepth = 188 + (SourceLuma(Index) / 5) + (FrontAlpha / 7)

    DepthValue = BackgroundDepth
    DepthValue = (DepthValue * (255 - MidAlpha) + MidDepth * MidAlpha) / 255
    DepthValue = (DepthValue * (255 - FrontAlpha) + FrontDepth * FrontAlpha) / 255

    CombinedDepthValues(Index) = ClampInt(DepthValue, 0, 255)
  Next Index

  SmoothByteArray(CombinedDepthValues(), #DepthSmoothPasses)
EndProcedure

Procedure FillTransparentPixels(ImageNumber.i, AlphaThreshold.i, Passes.i, MinNeighborAlpha.i)
  Protected PassIndex.i
  Protected x.i
  Protected y.i
  Protected Index.i
  Protected SampleX.i
  Protected SampleY.i
  Protected Color.i
  Protected NeighborColor.i
  Protected AlphaValue.i
  Protected NeighborAlpha.i
  Protected Count.i
  Protected SumRed.i
  Protected SumGreen.i
  Protected SumBlue.i
  Protected BestColor.i
  Protected BestAlpha.i

  If IsImage(ImageNumber) = 0 Or Passes <= 0
    ProcedureReturn
  EndIf

  ReDim TempColorValues(PixelCount - 1)
  ReDim TempIntValues(PixelCount - 1)

  For PassIndex = 1 To Passes
    If StartDrawing(ImageOutput(ImageNumber)) = 0
      ProcedureReturn
    EndIf

    For y = 0 To ImageH - 1
      For x = 0 To ImageW - 1
        Index = ArrayPixelIndex(x, y)
        Color = Point(x, y)
        TempColorValues(Index) = Color
        TempIntValues(Index) = Alpha(Color)
      Next x
    Next y
    StopDrawing()

    For y = 0 To ImageH - 1
      For x = 0 To ImageW - 1
        Index = ArrayPixelIndex(x, y)
        AlphaValue = TempIntValues(Index)
        If AlphaValue <= AlphaThreshold
          Count = 0
          SumRed = 0
          SumGreen = 0
          SumBlue = 0
          BestColor = TempColorValues(Index)
          BestAlpha = -1

          For SampleY = y - 1 To y + 1
            For SampleX = x - 1 To x + 1
              If (SampleX <> x Or SampleY <> y) And SampleX >= 0 And SampleX < ImageW And SampleY >= 0 And SampleY < ImageH
                NeighborColor = TempColorValues(ArrayPixelIndex(SampleX, SampleY))
                NeighborAlpha = TempIntValues(ArrayPixelIndex(SampleX, SampleY))
                If NeighborAlpha > MinNeighborAlpha
                  SumRed + Red(NeighborColor)
                  SumGreen + Green(NeighborColor)
                  SumBlue + Blue(NeighborColor)
                  Count + 1
                  If NeighborAlpha > BestAlpha
                    BestAlpha = NeighborAlpha
                    BestColor = NeighborColor
                  EndIf
                EndIf
              EndIf
            Next SampleX
          Next SampleY

          If Count > 0
            TempColorValues(Index) = RGBA(SumRed / Count, SumGreen / Count, SumBlue / Count, AlphaValue)
          ElseIf BestAlpha >= 0
            TempColorValues(Index) = RGBA(Red(BestColor), Green(BestColor), Blue(BestColor), AlphaValue)
          EndIf
        EndIf
      Next x
    Next y

    If StartDrawing(ImageOutput(ImageNumber)) = 0
      ProcedureReturn
    EndIf

    DrawingMode(#PB_2DDrawing_AllChannels)
    For y = 0 To ImageH - 1
      For x = 0 To ImageW - 1
        Plot(x, y, TempColorValues(ArrayPixelIndex(x, y)))
      Next x
    Next y
    StopDrawing()
  Next PassIndex
EndProcedure

Procedure BuildAutomaticMasks()
  Protected x.i
  Protected y.i
  Protected Index.i
  Protected Color.i
  Protected Luma.i
  Protected FrontAlpha.i
  Protected MidAlpha.i
  Protected CenterWeight.i
  Protected SubjectScore.i
  Protected MidScore.i
  Protected BackScore.i
  Protected MaxChannel.i
  Protected MinChannel.i
  Protected ColorSpread.i
  Protected Contrast.i
  Protected EdgeBoost.i
  Protected WarmBias.i
  Protected CoolBias.i
  Protected CenterX.i = ImageW / 2
  Protected CenterY.i = ImageH / 2
  Protected NormX.i
  Protected NormY.i

  ReDim FrontMaskValues(PixelCount - 1)
  ReDim MidMaskValues(PixelCount - 1)

  Index = 0
  For y = 0 To ImageH - 1
    For x = 0 To ImageW - 1
      Color = SourcePixels(Index)
      Luma = SourceLuma(Index)

      If CenterX > 0
        NormX = (Abs(x - CenterX) * 100) / CenterX
      Else
        NormX = 0
      EndIf

      If CenterY > 0
        NormY = (Abs(y - CenterY) * 100) / CenterY
      Else
        NormY = 0
      EndIf

      MaxChannel = Red(Color)
      If Green(Color) > MaxChannel : MaxChannel = Green(Color) : EndIf
      If Blue(Color) > MaxChannel : MaxChannel = Blue(Color) : EndIf

      MinChannel = Red(Color)
      If Green(Color) < MinChannel : MinChannel = Green(Color) : EndIf
      If Blue(Color) < MinChannel : MinChannel = Blue(Color) : EndIf

      ColorSpread = MaxChannel - MinChannel
      Contrast = NeighborhoodContrast(x, y)
      CenterWeight = 255 - ClampInt(((NormX + NormY) * 255) / 200, 0, 255)
      EdgeBoost = ClampInt((Contrast * 3) / 2, 0, 255)
      WarmBias = ClampInt((Red(Color) - Blue(Color)) + (Green(Color) / 4), -80, 120)
      CoolBias = ClampInt((Blue(Color) - Red(Color)) / 2, -80, 80)

      SubjectScore = Luma + (CenterWeight * 3 / 5) + (ColorSpread * 2 / 5) + (EdgeBoost / 3) + WarmBias
      MidScore = Luma + (CenterWeight * 2 / 5) + (ColorSpread / 4) + (Contrast / 2) - (WarmBias / 4)
      BackScore = 255 - Luma + CoolBias - (CenterWeight / 4)

      FrontAlpha = SoftBand(SubjectScore, AutoFrontThreshold - 10, 255, 52)
      MidAlpha = SoftBand(MidScore, AutoMidLow, AutoMidHigh + 16, 54)
      FrontAlpha = (FrontAlpha * (148 + CenterWeight + EdgeBoost / 3)) / 488
      MidAlpha = (MidAlpha * (160 + CenterWeight + Contrast / 2)) / 510
      MidAlpha = ClampInt(MidAlpha - (BackScore / 9), 0, 255)

      FrontMaskValues(Index) = ClampInt(FrontAlpha, 0, 255)
      MidMaskValues(Index) = ClampInt(MidAlpha, 0, 255)
      Index + 1
    Next x
  Next y

  ExpandMaskArray(FrontMaskValues(), 1, 18)
  ExpandMaskArray(MidMaskValues(), 1, 24)
  SmoothByteArray(FrontMaskValues(), #MaskSmoothPasses)
  SmoothByteArray(MidMaskValues(), #MaskSmoothPasses)
  FeatherMaskEdges(FrontMaskValues(), ForegroundFeather)
  BalanceMasks()
EndProcedure

Procedure ResolveMaskSources()
  Protected FrontLoaded.i
  Protected MidLoaded.i

  BuildAutomaticMasks()

  FrontLoaded = LoadMaskArrayFromFile(FrontMaskFile, ImageW, ImageH, FrontMaskValues())
  MidLoaded = LoadMaskArrayFromFile(MidMaskFile, ImageW, ImageH, MidMaskValues())

  If FrontMaskFile <> "" And FrontLoaded = 0
    MessageRequester("Mask Warning", "The foreground mask could not be loaded, so the program is using an automatic mask instead.")
    FrontMaskFile = ""
  EndIf

  If MidMaskFile <> "" And MidLoaded = 0
    MessageRequester("Mask Warning", "The middle mask could not be loaded, so the program is using an automatic mask instead.")
    MidMaskFile = ""
  EndIf

  ExpandMaskArray(FrontMaskValues(), 1, 12)
  ExpandMaskArray(MidMaskValues(), 1, 16)
  SmoothByteArray(FrontMaskValues(), 1)
  SmoothByteArray(MidMaskValues(), 1)
  FeatherMaskEdges(FrontMaskValues(), ForegroundFeather)
  BalanceMasks()
EndProcedure

Procedure BuildCombinedDepthMap()
  BuildDepthFromMasks()
  BuildDepthPreviewImage()
EndProcedure

Procedure.i BuildLayerImages()
  Protected x.i
  Protected y.i
  Protected Index.i
  Protected Color.i
  Protected FrontAlpha.i
  Protected MidAlpha.i
  Protected BackAlpha.i
  Protected LayerRed.i
  Protected LayerGreen.i
  Protected LayerBlue.i

  If IsImage(#ImageBackLayer) : FreeImage(#ImageBackLayer) : EndIf
  If IsImage(#ImageMidLayer) : FreeImage(#ImageMidLayer) : EndIf
  If IsImage(#ImageFrontLayer) : FreeImage(#ImageFrontLayer) : EndIf

  If CreateImage(#ImageBackLayer, ImageW, ImageH, 32, #PB_Image_Transparent) = 0
    ProcedureReturn #False
  EndIf

  If CreateImage(#ImageMidLayer, ImageW, ImageH, 32, #PB_Image_Transparent) = 0
    ProcedureReturn #False
  EndIf

  If CreateImage(#ImageFrontLayer, ImageW, ImageH, 32, #PB_Image_Transparent) = 0
    ProcedureReturn #False
  EndIf

  If StartDrawing(ImageOutput(#ImageBackLayer)) = 0
    ProcedureReturn #False
  EndIf
  DrawingMode(#PB_2DDrawing_AllChannels)
  For y = 0 To ImageH - 1
    For x = 0 To ImageW - 1
      Index = x + (y * ImageW)
      Color = SourcePixels(Index)
      FrontAlpha = FrontMaskValues(Index)
      MidAlpha = MidMaskValues(Index)
      BackAlpha = 255 - ClampInt((FrontAlpha * 4) / 10 + (MidAlpha * 3) / 10, 0, 120)
      BackAlpha = ClampInt(BackAlpha, 120, 255)
      LayerRed = ClampInt((Red(Color) * 7 + 18) / 8, 0, 255)
      LayerGreen = ClampInt((Green(Color) * 7 + 18) / 8, 0, 255)
      LayerBlue = ClampInt((Blue(Color) * 7 + 24) / 8, 0, 255)
      Plot(x, y, RGBA(LayerRed, LayerGreen, LayerBlue, BackAlpha))
    Next x
  Next y
  StopDrawing()

  If StartDrawing(ImageOutput(#ImageMidLayer)) = 0
    ProcedureReturn #False
  EndIf
  DrawingMode(#PB_2DDrawing_AllChannels)
  For y = 0 To ImageH - 1
    For x = 0 To ImageW - 1
      Index = x + (y * ImageW)
      Color = SourcePixels(Index)
      MidAlpha = MidMaskValues(Index)
      LayerRed = ClampInt((Red(Color) * 9 + 10) / 10, 0, 255)
      LayerGreen = ClampInt((Green(Color) * 9 + 10) / 10, 0, 255)
      LayerBlue = ClampInt((Blue(Color) * 9 + 14) / 10, 0, 255)
      Plot(x, y, RGBA(LayerRed, LayerGreen, LayerBlue, MidAlpha))
    Next x
  Next y
  StopDrawing()

  If StartDrawing(ImageOutput(#ImageFrontLayer)) = 0
    ProcedureReturn #False
  EndIf
  DrawingMode(#PB_2DDrawing_AllChannels)
  For y = 0 To ImageH - 1
    For x = 0 To ImageW - 1
      Index = x + (y * ImageW)
      Color = SourcePixels(Index)
      FrontAlpha = FrontMaskValues(Index)
      LayerRed = Red(Color)
      LayerGreen = Green(Color)
      LayerBlue = Blue(Color)

      Plot(x, y, RGBA(LayerRed, LayerGreen, LayerBlue, FrontAlpha))
    Next x
  Next y
  StopDrawing()

  FillTransparentPixels(#ImageBackLayer, 210, #BackInpaintPasses, 90)
  FillTransparentPixels(#ImageMidLayer, 180, #MidInpaintPasses, 72)
  FillTransparentPixels(#ImageFrontLayer, 100, #FrontColorBleedPasses, 84)

  If BackgroundSoftFocus > 0
    BlurImageSoft(#ImageBackLayer, BackgroundSoftFocus)
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i CreateLayerTexture(TextureNumber.i, ImageNumber.i)
  If CreateTexture(TextureNumber, ImageW, ImageH) = 0
    ProcedureReturn #False
  EndIf

  If StartDrawing(TextureOutput(TextureNumber)) = 0
    FreeTexture(TextureNumber)
    ProcedureReturn #False
  EndIf

  DrawingMode(#PB_2DDrawing_AllChannels)
  Box(0, 0, ImageW, ImageH, RGBA(0, 0, 0, 0))
  DrawAlphaImage(ImageID(ImageNumber), 0, 0, 255)
  StopDrawing()
  ProcedureReturn #True
EndProcedure

Procedure.i CreateDepthMeshScene()
  Protected SegX.i = 96
  Protected SegY.i = 96
  Protected VertexLastIndex.i
  Protected x.i
  Protected y.i
  Protected PixelX.i
  Protected PixelY.i
  Protected MeshIndex.i
  Protected DepthValue.f

  If CreateLayerTexture(#TextureDepth, #ImageSource) = 0
    MessageRequester("3D Error", "Could not create the depth mesh texture.")
    ProcedureReturn #False
  EndIf

  If CreateMaterial(#MaterialDepth, TextureID(#TextureDepth)) = 0
    MessageRequester("3D Error", "Could not create the depth mesh material.")
    ProcedureReturn #False
  EndIf

  DisableMaterialLighting(#MaterialDepth, 1)
  MaterialCullingMode(#MaterialDepth, #PB_Material_NoCulling)

  If CreatePlane(#MeshDepth, BasePlaneW * 1.05, BasePlaneH * 1.05, SegX, SegY, 1, 1) = 0
    MessageRequester("3D Error", "Could not create the depth mesh.")
    ProcedureReturn #False
  EndIf

  VertexLastIndex = MeshVertexCount(#MeshDepth) - 1
  If VertexLastIndex < 0
    ProcedureReturn #False
  EndIf

  ReDim MeshData(VertexLastIndex)
  GetMeshData(#MeshDepth, 0, MeshData(), #PB_Mesh_Vertex, 0, VertexLastIndex)

  For y = 0 To SegY
    For x = 0 To SegX
      MeshIndex = x + (y * (SegX + 1))
      PixelX = ClampInt(Int((x * (ImageW - 1)) / SegX), 0, ImageW - 1)
      PixelY = ClampInt(Int((y * (ImageH - 1)) / SegY), 0, ImageH - 1)
      DepthValue = (CombinedDepthValues(PixelX + (PixelY * ImageW)) / 255.0) - 0.5

      MeshData(MeshIndex)\y = DepthValue * MeshStrength * PresetMeshScale
    Next x
  Next y

  SetMeshData(#MeshDepth, 0, MeshData(), #PB_Mesh_Vertex, 0, VertexLastIndex)

  If CreateEntity(#EntityDepth, MeshID(#MeshDepth), MaterialID(#MaterialDepth)) = 0
    MessageRequester("3D Error", "Could not create the depth mesh entity.")
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i CreateSceneMaterialsAndEntities()
  BasePlaneH = BasePlaneW * ImageH / ImageW

  If CreateLayerTexture(#TextureBack, #ImageBackLayer) = 0
    MessageRequester("3D Error", "Could not create the background texture.")
    ProcedureReturn #False
  EndIf

  If CreateLayerTexture(#TextureMid, #ImageMidLayer) = 0
    MessageRequester("3D Error", "Could not create the middle texture.")
    ProcedureReturn #False
  EndIf

  If CreateLayerTexture(#TextureFront, #ImageFrontLayer) = 0
    MessageRequester("3D Error", "Could not create the foreground texture.")
    ProcedureReturn #False
  EndIf

  If CreateMaterial(#MaterialBack, TextureID(#TextureBack)) = 0
    MessageRequester("3D Error", "Could not create the background material.")
    ProcedureReturn #False
  EndIf

  If CreateMaterial(#MaterialMid, TextureID(#TextureMid)) = 0
    MessageRequester("3D Error", "Could not create the middle material.")
    ProcedureReturn #False
  EndIf

  If CreateMaterial(#MaterialFront, TextureID(#TextureFront)) = 0
    MessageRequester("3D Error", "Could not create the foreground material.")
    ProcedureReturn #False
  EndIf

  DisableMaterialLighting(#MaterialBack, 1)
  DisableMaterialLighting(#MaterialMid, 1)
  DisableMaterialLighting(#MaterialFront, 1)
  MaterialBlendingMode(#MaterialBack, #PB_Material_AlphaBlend)
  MaterialBlendingMode(#MaterialMid, #PB_Material_AlphaBlend)
  MaterialBlendingMode(#MaterialFront, #PB_Material_AlphaBlend)
  MaterialCullingMode(#MaterialBack, #PB_Material_NoCulling)
  MaterialCullingMode(#MaterialMid, #PB_Material_NoCulling)
  MaterialCullingMode(#MaterialFront, #PB_Material_NoCulling)

  If CreatePlane(#MeshBack, BasePlaneW * 1.24, BasePlaneH * 1.24, 1, 1, 1, 1) = 0
    MessageRequester("3D Error", "Could not create the background plane mesh.")
    ProcedureReturn #False
  EndIf

  If CreatePlane(#MeshMid, BasePlaneW * 1.08, BasePlaneH * 1.08, 1, 1, 1, 1) = 0
    MessageRequester("3D Error", "Could not create the middle plane mesh.")
    ProcedureReturn #False
  EndIf

  If CreatePlane(#MeshFront, BasePlaneW, BasePlaneH, 1, 1, 1, 1) = 0
    MessageRequester("3D Error", "Could not create the foreground plane mesh.")
    ProcedureReturn #False
  EndIf

  If CreateEntity(#EntityBack, MeshID(#MeshBack), MaterialID(#MaterialBack)) = 0
    MessageRequester("3D Error", "Could not create the background entity.")
    ProcedureReturn #False
  EndIf

  If CreateEntity(#EntityMid, MeshID(#MeshMid), MaterialID(#MaterialMid)) = 0
    MessageRequester("3D Error", "Could not create the middle entity.")
    ProcedureReturn #False
  EndIf

  If CreateEntity(#EntityFront, MeshID(#MeshFront), MaterialID(#MaterialFront)) = 0
    MessageRequester("3D Error", "Could not create the foreground entity.")
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure.i SaveGeneratedAssetsToFolder(OutputFolder.s)
  If SceneReady = 0 Or IsImage(#ImageBackLayer) = 0 Or IsImage(#ImageMidLayer) = 0 Or IsImage(#ImageFrontLayer) = 0 Or IsImage(#ImageDepthPreview) = 0
    ProcedureReturn #False
  EndIf

  If Right(OutputFolder, 1) <> "\" And Right(OutputFolder, 1) <> "/"
    OutputFolder + "\"
  EndIf

  UsePNGImageEncoder()

  If SaveImage(#ImageBackLayer, OutputFolder + "ImageTo3D_BackLayer.png", #PB_ImagePlugin_PNG) = 0
    ProcedureReturn #False
  EndIf

  If SaveImage(#ImageMidLayer, OutputFolder + "ImageTo3D_MidLayer.png", #PB_ImagePlugin_PNG) = 0
    ProcedureReturn #False
  EndIf

  If SaveImage(#ImageFrontLayer, OutputFolder + "ImageTo3D_FrontLayer.png", #PB_ImagePlugin_PNG) = 0
    ProcedureReturn #False
  EndIf

  If SaveImage(#ImageDepthPreview, OutputFolder + "ImageTo3D_DepthMap.png", #PB_ImagePlugin_PNG) = 0
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure SaveGeneratedAnalysisFiles()
  Protected AutoSaveFolder.s

  If AutoSaveAssetsEnabled = 0 Or LoadedImageFile = ""
    ProcedureReturn
  EndIf

  AutoSaveFolder = GetPathPart(LoadedImageFile) + "ImageTo3D_Autosave"
  CreateDirectory(AutoSaveFolder)

  If SaveGeneratedAssetsToFolder(AutoSaveFolder) = 0
    MessageRequester("Auto-save Warning", "Generated assets could not be auto-saved to:" + #CRLF$ + AutoSaveFolder)
  EndIf
EndProcedure

Procedure.i RebuildSceneLayers()
  If LoadedImageFile = ""
    UpdateValueLabels()
    ProcedureReturn #False
  EndIf

  If CaptureSourcePixels() = 0
    MessageRequester("Image Error", "Could not access the source image pixels.")
    ProcedureReturn #False
  EndIf

  ResolveMaskSources()
  BuildCombinedDepthMap()

  If BuildLayerImages() = 0
    MessageRequester("Image Error", "Could not build the masked image layers.")
    ProcedureReturn #False
  EndIf

  If CreateSceneMaterialsAndEntities() = 0
    ProcedureReturn #False
  EndIf

  If CreateDepthMeshScene() = 0
    ProcedureReturn #False
  EndIf

  SceneReady = #True
  ResetView()
  UpdatePreviewImages()
  UpdateSceneVisibility()
  ApplyLayerTransforms()
  UpdateValueLabels()
  SaveGeneratedAnalysisFiles()
  SetWindowTitle(#Window, "ImageTo3D - " + LoadedImageName)
  ProcedureReturn #True
EndProcedure

Procedure.i LoadSceneImage(FileName.s)
  FreeSceneResources()

  If LoadImage(#ImageSource, FileName) = 0
    MessageRequester("Load Error", "Could not load the selected image file.")
    ResetLoadedImageState()
    ProcedureReturn #False
  EndIf

  If ResizeLoadedImageIfNeeded() = 0
    FreeSceneResources()
    ResetLoadedImageState()
    ProcedureReturn #False
  EndIf

  LoadedImageFile = FileName
  LoadedImageName = GetFilePart(FileName)

  If RebuildSceneLayers() = 0
    FreeSceneResources()
    ResetLoadedImageState()
    ProcedureReturn #False
  EndIf

  ProcedureReturn #True
EndProcedure

Procedure OpenImageDialog()
  Protected FileName.s

  FileName = OpenFileRequester("Open an image", LoadedImageFile, "Images|*.png;*.jpg;*.jpeg;*.gif;*.bmp;*.tga;*.tif;*.tiff", 0)
  If FileName <> ""
    LoadSceneImage(FileName)
  EndIf
EndProcedure

Procedure LoadFrontMaskDialog()
  Protected FileName.s

  FileName = OpenFileRequester("Open foreground mask", FrontMaskFile, "Images|*.png;*.jpg;*.jpeg;*.bmp;*.tga;*.tif;*.tiff", 0)
  If FileName <> ""
    FrontMaskFile = FileName
    RebuildImageWithCurrentMasks()
  EndIf
EndProcedure

Procedure LoadMidMaskDialog()
  Protected FileName.s

  FileName = OpenFileRequester("Open middle mask", MidMaskFile, "Images|*.png;*.jpg;*.jpeg;*.bmp;*.tga;*.tif;*.tiff", 0)
  If FileName <> ""
    MidMaskFile = FileName
    RebuildImageWithCurrentMasks()
  EndIf
EndProcedure

Procedure ClearMaskFiles()
  FrontMaskFile = ""
  MidMaskFile = ""
  RebuildImageWithCurrentMasks()
EndProcedure

Procedure.s EnsureProjectExtension(FileName.s)
  If LCase(GetExtensionPart(FileName)) <> "prefs"
    ProcedureReturn FileName + ".prefs"
  EndIf

  ProcedureReturn FileName
EndProcedure

Procedure.s EnsurePNGExtension(FileName.s)
  If LCase(GetExtensionPart(FileName)) <> "png"
    ProcedureReturn FileName + ".png"
  EndIf

  ProcedureReturn FileName
EndProcedure

Procedure SaveViewportPNG()
  Protected FileName.s
  Protected DefaultPath.s
  Protected CaptureImage.i

  If StartDrawing(WindowOutput(#Window)) = 0
    MessageRequester("Export Error", "Could not access the window for viewport capture.")
    ProcedureReturn
  EndIf

  CaptureImage = GrabDrawingImage(#PB_Any, #ViewportX, #ViewportY, #ViewportVisibleW, #ViewportVisibleH)
  StopDrawing()

  If CaptureImage = 0
    MessageRequester("Export Error", "Could not capture the current viewport image.")
    ProcedureReturn
  EndIf

  UsePNGImageEncoder()

  If LoadedImageFile <> ""
    DefaultPath = GetPathPart(LoadedImageFile) + GetFilePart(LoadedImageFile, #PB_FileSystem_NoExtension) + "_viewport.png"
  Else
    DefaultPath = "ImageTo3D_viewport.png"
  EndIf

  FileName = SaveFileRequester("Save viewport PNG", DefaultPath, "PNG Image|*.png", 0)
  If FileName = ""
    FreeImage(CaptureImage)
    ProcedureReturn
  EndIf

  FileName = EnsurePNGExtension(FileName)
  If SaveImage(CaptureImage, FileName, #PB_ImagePlugin_PNG) = 0
    FreeImage(CaptureImage)
    MessageRequester("Export Error", "Could not save the viewport PNG.")
    ProcedureReturn
  EndIf

  FreeImage(CaptureImage)
  MessageRequester("Viewport Saved", "Saved viewport PNG to:" + #CRLF$ + FileName)
EndProcedure

Procedure.i SaveProjectFile(FileName.s)
  If LoadedImageFile = ""
    MessageRequester("Project Error", "Load an image before saving a project file.")
    ProcedureReturn #False
  EndIf

  FileName = EnsureProjectExtension(FileName)

  If CreatePreferences(FileName) = 0
    MessageRequester("Project Error", "Could not create the project file.")
    ProcedureReturn #False
  EndIf

  PreferenceComment("ImageTo3D project file")
  PreferenceGroup("Project")
  WritePreferenceString("ImageFile", StoredProjectPath(LoadedImageFile, FileName))
  WritePreferenceString("FrontMaskFile", StoredProjectPath(FrontMaskFile, FileName))
  WritePreferenceString("MidMaskFile", StoredProjectPath(MidMaskFile, FileName))
  WritePreferenceFloat("DepthStrength", DepthStrength)
  WritePreferenceFloat("MouseSensitivity", MouseSensitivity)
  WritePreferenceFloat("SmoothFactor", SmoothFactor)
  WritePreferenceFloat("CameraDistance", CameraDistance)
  WritePreferenceFloat("TiltIntensity", TiltIntensity)
  WritePreferenceFloat("MeshStrength", MeshStrength)
  WritePreferenceFloat("MotionXStrength", MotionXStrength)
  WritePreferenceFloat("MotionYStrength", MotionYStrength)
  WritePreferenceInteger("ParallaxPreset", ParallaxPreset)
  WritePreferenceInteger("ForegroundFeather", ForegroundFeather)
  WritePreferenceInteger("BackgroundSoftFocus", BackgroundSoftFocus)
  WritePreferenceInteger("AutoSaveAssets", AutoSaveAssetsEnabled)
  WritePreferenceInteger("ViewerMode", GetGadgetState(#PanelMode))
  WritePreferenceInteger("AutoFrontThreshold", AutoFrontThreshold)
  WritePreferenceInteger("AutoMidLow", AutoMidLow)
  WritePreferenceInteger("AutoMidHigh", AutoMidHigh)
  FlushPreferenceBuffers()
  ClosePreferences()

  LoadedProjectFile = FileName
  MessageRequester("Project Saved", "Project saved to:" + #CRLF$ + FileName)
  ProcedureReturn #True
EndProcedure

Procedure SaveProjectDialog()
  Protected FileName.s
  Protected DefaultPath.s

  If LoadedProjectFile <> ""
    DefaultPath = LoadedProjectFile
  ElseIf LoadedImageFile <> ""
    DefaultPath = GetPathPart(LoadedImageFile) + GetFilePart(LoadedImageFile, #PB_FileSystem_NoExtension) + ".prefs"
  Else
    DefaultPath = "ImageTo3DProject.prefs"
  EndIf

  FileName = SaveFileRequester("Save project", DefaultPath, "ImageTo3D Project|*.prefs", 0)
  If FileName <> ""
    SaveProjectFile(FileName)
  EndIf
EndProcedure

Procedure ExportGeneratedLayers()
  Protected BaseFolder.s
  Protected OutputFolder.s

  If LoadedImageFile = ""
    MessageRequester("Export Error", "Load an image before exporting generated layers.")
    ProcedureReturn
  EndIf

  If SceneReady = 0 Or IsImage(#ImageBackLayer) = 0 Or IsImage(#ImageMidLayer) = 0 Or IsImage(#ImageFrontLayer) = 0 Or IsImage(#ImageDepthPreview) = 0
    MessageRequester("Export Error", "The generated layers are not ready yet.")
    ProcedureReturn
  EndIf

  UsePNGImageEncoder()

  BaseFolder = GetPathPart(LoadedImageFile)
  OutputFolder = PathRequester("Choose export folder", BaseFolder)
  If OutputFolder = ""
    ProcedureReturn
  EndIf

  If SaveGeneratedAssetsToFolder(OutputFolder) = 0
    MessageRequester("Export Error", "Could not save the generated asset PNG files.")
    ProcedureReturn
  EndIf

  MessageRequester("Layers Exported", "Saved generated PNG files to:" + #CRLF$ + OutputFolder)
EndProcedure

Procedure.i LoadProjectFile(FileName.s)
  Protected ProjectImage.s
  Protected ProjectFrontMask.s
  Protected ProjectMidMask.s
  Protected ProjectDepth.f
  Protected ProjectSensitivity.f
  Protected ProjectSmoothing.f
  Protected ProjectZoom.f
  Protected ProjectTilt.f
  Protected ProjectMeshStrength.f
  Protected ProjectMotionX.f
  Protected ProjectMotionY.f
  Protected ProjectParallaxPreset.i
  Protected ProjectForegroundFeather.i
  Protected ProjectBackgroundBlur.i
  Protected ProjectAutoSaveAssets.i
  Protected ProjectViewerMode.i
  Protected ProjectAutoFront.i
  Protected ProjectAutoMidLow.i
  Protected ProjectAutoMidHigh.i

  If OpenPreferences(FileName) = 0
    MessageRequester("Project Error", "Could not open the selected project file.")
    ProcedureReturn #False
  EndIf

  PreferenceGroup("Project")
  ProjectImage = ReadPreferenceString("ImageFile", "")
  ProjectFrontMask = ReadPreferenceString("FrontMaskFile", "")
  ProjectMidMask = ReadPreferenceString("MidMaskFile", "")
  ProjectDepth = ReadPreferenceFloat("DepthStrength", 1.0)
  ProjectSensitivity = ReadPreferenceFloat("MouseSensitivity", 1.0)
  ProjectSmoothing = ReadPreferenceFloat("SmoothFactor", 0.12)
  ProjectZoom = ReadPreferenceFloat("CameraDistance", 18.0)
  ProjectTilt = ReadPreferenceFloat("TiltIntensity", 1.35)
  ProjectMeshStrength = ReadPreferenceFloat("MeshStrength", 0.80)
  ProjectMotionX = ReadPreferenceFloat("MotionXStrength", 1.0)
  ProjectMotionY = ReadPreferenceFloat("MotionYStrength", 1.0)
  ProjectParallaxPreset = ReadPreferenceInteger("ParallaxPreset", 1)
  ProjectForegroundFeather = ReadPreferenceInteger("ForegroundFeather", 2)
  ProjectBackgroundBlur = ReadPreferenceInteger("BackgroundSoftFocus", 3)
  ProjectAutoSaveAssets = ReadPreferenceInteger("AutoSaveAssets", 0)
  ProjectViewerMode = ReadPreferenceInteger("ViewerMode", 0)
  ProjectAutoFront = ReadPreferenceInteger("AutoFrontThreshold", 168)
  ProjectAutoMidLow = ReadPreferenceInteger("AutoMidLow", 78)
  ProjectAutoMidHigh = ReadPreferenceInteger("AutoMidHigh", 196)
  ClosePreferences()

  ProjectImage = ResolveProjectPath(ProjectImage, FileName)
  ProjectFrontMask = ResolveProjectPath(ProjectFrontMask, FileName)
  ProjectMidMask = ResolveProjectPath(ProjectMidMask, FileName)

  If ProjectImage = "" Or FileSize(ProjectImage) < 0
    MessageRequester("Project Error", "The project file references an image that could not be found.")
    ProcedureReturn #False
  EndIf

  If ProjectFrontMask <> "" And FileSize(ProjectFrontMask) < 0
    ProjectFrontMask = ""
  EndIf

  If ProjectMidMask <> "" And FileSize(ProjectMidMask) < 0
    ProjectMidMask = ""
  EndIf

  FrontMaskFile = ProjectFrontMask
  MidMaskFile = ProjectMidMask
  TiltIntensity = ProjectTilt
  MeshStrength = ProjectMeshStrength
  MotionXStrength = ProjectMotionX
  MotionYStrength = ProjectMotionY
  ForegroundFeather = ClampInt(ProjectForegroundFeather, 0, 8)
  BackgroundSoftFocus = ClampInt(ProjectBackgroundBlur, 0, 8)
  AutoSaveAssetsEnabled = Bool(ProjectAutoSaveAssets)
  AutoFrontThreshold = ProjectAutoFront
  AutoMidLow = ProjectAutoMidLow
  AutoMidHigh = ProjectAutoMidHigh
  ApplyParallaxPreset(ProjectParallaxPreset)
  ApplyControlValues(ProjectDepth, ProjectSensitivity, ProjectSmoothing, ProjectZoom)
  SetGadgetState(#PanelMode, ClampInt(ProjectViewerMode, 0, 2))
  LoadedProjectFile = FileName

  If LoadSceneImage(ProjectImage) = 0
    ProcedureReturn #False
  EndIf

  UpdateSceneVisibility()

  ProcedureReturn #True
EndProcedure

Procedure LoadProjectDialog()
  Protected FileName.s

  FileName = OpenFileRequester("Load project", LoadedProjectFile, "ImageTo3D Project|*.prefs", 0)
  If FileName <> ""
    LoadProjectFile(FileName)
  EndIf
EndProcedure

Procedure ShowAboutDialog()
  MessageRequester("About ImageTo3D", "ImageTo3D" + #CRLF$ + #CRLF$ + "Features:" + #CRLF$ + "- Parallax layer view" + #CRLF$ + "- Depth mesh view" + #CRLF$ + "- Split smoke-test workflow via quick mode switching" + #CRLF$ + "- Mask previews And PNG export" + #CRLF$ + "- Project save/load" + #CRLF$ + #CRLF$ + "Use grayscale masks For the cleanest foreground And midground separation.")
EndProcedure

Procedure OpenHelpFile()
  Protected HelpPath.s
  Protected Opened.i

  HelpPath = GetPathPart(ProgramFilename()) + #APP_NAME+ "_Help.html"
  If FileSize(HelpPath) < 0
    MessageRequester("Help Error", "The help file was not found:" + #CRLF$ + HelpPath)
    ProcedureReturn
  EndIf

  Opened = RunProgram(HelpPath, "", GetPathPart(HelpPath))
  If Opened = 0
    Opened = RunProgram("explorer.exe", Chr(34) + HelpPath + Chr(34), GetPathPart(HelpPath))
  EndIf

  If Opened = 0
    MessageRequester("Help Error", "The HTML help file could not be opened automatically." + #CRLF$ + HelpPath)
  EndIf
EndProcedure

Procedure RebuildImageWithCurrentMasks()
  If LoadedImageFile = ""
    UpdateValueLabels()
    ProcedureReturn
  EndIf

  FreeSceneResources()
  If LoadImage(#ImageSource, LoadedImageFile) And ResizeLoadedImageIfNeeded()
    RebuildSceneLayers()
  Else
    MessageRequester("Load Error", "The current source image could not be reloaded.")
  EndIf
EndProcedure

Procedure ScheduleImageRebuild()
  If LoadedImageFile = ""
    ProcedureReturn
  EndIf

  PendingImageRebuild = #True
  PendingImageRebuildAt = ElapsedMilliseconds() + #RebuildDebounceMS
EndProcedure

If InitEngine3D() = 0
  MessageRequester("Error", "InitEngine3D() failed.")
  End
EndIf

If InitSprite() = 0 Or InitKeyboard() = 0 Or InitMouse() = 0
  MessageRequester("Error", "Sprite / Keyboard / Mouse init failed.")
  End
EndIf

UseJPEGImageDecoder()
UsePNGImageDecoder()
UseGIFImageDecoder()
UseTGAImageDecoder()
UseTIFFImageDecoder()

If OpenWindow(#Window, 0, 0, #WindowW, #WindowH, #APP_NAME+ " - " + version, #PB_Window_SystemMenu | #PB_Window_MaximizeGadget | #PB_Window_ScreenCentered) = 0
  MessageRequester("Error", "Could not open the main window.")
  End
EndIf

If CreateMenu(0, WindowID(#Window))
  MenuTitle("File")
  MenuItem(#MenuFileOpenImage, "Open Image...")
  MenuItem(#MenuFileLoadFrontMask, "Load Foreground Mask...")
  MenuItem(#MenuFileLoadMidMask, "Load Middle Mask...")
  MenuItem(#MenuFileClearMasks, "Clear Masks")
  MenuItem(#MenuFileExportLayers, "Export Generated Layers...")
  MenuItem(#MenuFileSaveViewport, "Save Viewport PNG...")
  MenuBar()
  MenuItem(#MenuFileLoadProject, "Load Project...")
  MenuItem(#MenuFileSaveProject, "Save Project...")
  MenuBar()
  MenuItem(#MenuFileExit, "Exit")
  MenuTitle("View")
  MenuItem(#MenuViewReset, "Reset View")
  MenuTitle("Help")
  MenuItem(#MenuHelpContents, "Help Contents")
  MenuItem(#MenuHelpAbout, "About")
EndIf

ContainerGadget(#ScrollViewport, #ViewportX, #ViewportY, #ViewportVisibleW, #ViewportVisibleH, #PB_Container_Flat)
CloseGadgetList()

ScrollAreaGadget(#ScrollPanel, #PanelAreaX, #PanelAreaY, #PanelAreaW, #PanelAreaH, #PanelInnerW, #PanelInnerH, 12)
TextGadget(#TextTitle, #PanelX, #PanelY, #PanelW, 28, "Image To 3D Controls")
TextGadget(#TextFileLabel, #PanelX, #PanelY + 36, 90, 20, "Image")
TextGadget(#TextFileValue, #PanelX, #PanelY + 56, #PanelW, 36, LoadedImageName)
TextGadget(#TextFrontMaskLabel, #PanelX, #PanelY + 96, 120, 20, "Foreground Mask")
TextGadget(#TextFrontMaskValue, #PanelX, #PanelY + 116, #PanelW, 36, "Auto-generated from image brightness")
TextGadget(#TextMidMaskLabel, #PanelX, #PanelY + 156, 120, 20, "Middle Mask")
TextGadget(#TextMidMaskValue, #PanelX, #PanelY + 176, #PanelW, 36, "Auto-generated from image brightness")
TextGadget(#TextQualityLabel, #PanelX, #PanelY + 214, 120, 20, "Parallax Quality")
ComboBoxGadget(#ComboQuality, #PanelX + 108, #PanelY + 210, 300, 26)
AddGadgetItem(#ComboQuality, -1, "Gentle")
AddGadgetItem(#ComboQuality, -1, "Balanced")
AddGadgetItem(#ComboQuality, -1, "Strong")
TextGadget(#TextMotionXLabel, #PanelX, #PanelY + 242, #PanelW, 18, "Horizontal Motion 1.00")
TrackBarGadget(#TrackMotionX, #PanelX, #PanelY + 260, #PanelW, 20, 40, 220)
TextGadget(#TextMotionYLabel, #PanelX, #PanelY + 282, #PanelW, 18, "Vertical Motion 1.00")
TrackBarGadget(#TrackMotionY, #PanelX, #PanelY + 300, #PanelW, 20, 40, 220)
TextGadget(#TextFeatherLabel, #PanelX, #PanelY + 322, #PanelW, 18, "Foreground Feather 2")
TrackBarGadget(#TrackFeather, #PanelX, #PanelY + 340, #PanelW, 20, 0, 8)

ButtonGadget(#ButtonOpen, #PanelX, #PanelY + 370, 198, 28, "Open Image...")
ButtonGadget(#ButtonReset, #PanelX + 210, #PanelY + 370, 198, 28, "Reset View")
ButtonGadget(#ButtonLoadFrontMask, #PanelX, #PanelY + 408, 198, 28, "Load Foreground Mask")
ButtonGadget(#ButtonLoadMidMask, #PanelX + 210, #PanelY + 408, 198, 28, "Load Middle Mask")
ButtonGadget(#ButtonClearMasks, #PanelX, #PanelY + 446, 198, 28, "Clear Masks")
ButtonGadget(#ButtonSaveProject, #PanelX + 210, #PanelY + 446, 198, 28, "Save Project...")
ButtonGadget(#ButtonLoadProject, #PanelX, #PanelY + 484, #PanelW, 28, "Load Project...")
ButtonGadget(#ButtonExportLayers, #PanelX, #PanelY + 522, #PanelW, 28, "Export Generated Layers...")
CheckBoxGadget(#CheckAutoSaveAssets, #PanelX, #PanelY + 556, #PanelW, 24, "Auto-save generated assets beside the image")

PanelGadget(#PanelMode, #PanelX, #PanelY + 588, #PanelW, 164)
  AddGadgetItem(#PanelMode, -1, "Parallax View")
  ImageGadget(#ImagePreviewFront, 18, 24, 120, 120, 0, #PB_Image_Border)
  ImageGadget(#ImagePreviewMid, 156, 24, 120, 120, 0, #PB_Image_Border)
  TextGadget(#TextDepthLabel, 18, 154, 390, 18, "Depth Strength")
  TrackBarGadget(#TrackDepth, 18, 172, 390, 20, 20, 200)
  TextGadget(#TextDepthValue, 18, 192, 390, 18, "")
  TextGadget(#TextTiltLabel, 18, 210, 188, 18, "Tilt Intensity")
  TrackBarGadget(#TrackTilt, 18, 228, 188, 20, 40, 300)
  TextGadget(#TextTiltValue, 18, 248, 188, 18, "")
  TextGadget(#TextSensitivityLabel, 220, 210, 188, 18, "Mouse Sensitivity")
  TrackBarGadget(#TrackSensitivity, 220, 228, 188, 20, 20, 200)
  TextGadget(#TextSensitivityValue, 220, 248, 188, 18, "")
  TextGadget(#TextFrontThresholdLabel, 18, 266, 188, 18, "Auto Front Threshold")
  TrackBarGadget(#TrackFrontThreshold, 18, 284, 188, 20, 1, 255)
  TextGadget(#TextFrontThresholdValue, 18, 304, 188, 18, "")
  TextGadget(#TextMidLowLabel, 220, 266, 188, 18, "Auto Mid Low")
  TrackBarGadget(#TrackMidLow, 220, 284, 188, 20, 0, 254)
  TextGadget(#TextMidLowValue, 220, 304, 188, 18, "")
  TextGadget(#TextMidHighLabel, 18, 322, 390, 18, "Auto Mid High")
  TrackBarGadget(#TrackMidHigh, 18, 340, 390, 20, 1, 255)
  TextGadget(#TextMidHighValue, 18, 360, 390, 18, "")

  AddGadgetItem(#PanelMode, -1, "Depth Mesh")
  ImageGadget(#ImagePreviewDepth, 18, 24, 120, 120, 0, #PB_Image_Border)
  TextGadget(#TextMeshStrengthLabel, 18, 154, 390, 18, "Mesh Strength")
  TrackBarGadget(#TrackMeshStrength, 18, 172, 390, 20, 20, 250)
  TextGadget(#TextMeshStrengthValue, 18, 192, 390, 18, "")
  TextGadget(#TextSmoothingLabel, 18, 210, 390, 18, "Smoothing")
  TrackBarGadget(#TrackSmoothing, 18, 228, 390, 20, 5, 60)
  TextGadget(#TextSmoothingValue, 18, 248, 390, 18, "")
  TextGadget(#TextBlurLabel, 18, 266, 390, 18, "Background Soft Focus")
  TrackBarGadget(#TrackBlur, 18, 284, 390, 20, 0, 8)
  TextGadget(#TextBlurValue, 18, 304, 390, 18, "")

  AddGadgetItem(#PanelMode, -1, "Smoke Test")
  TextGadget(#TextInfo, 18, 24, 390, 132, "Smoke Test mode lets you flip quickly between Parallax View and Depth Mesh using the same loaded image, masks, and settings." + #CRLF$ + #CRLF$ + "Suggested test: 1) load image, 2) verify mask previews, 3) try Gentle / Balanced / Strong quality, 4) tune X/Y motion and feathering, 5) adjust background soft focus, 6) export layers, 7) switch to Depth Mesh, 8) save and reload a project.")
CloseGadgetList()

TextGadget(#TextZoomLabel, #PanelX, #PanelY + 770, #PanelW, 20, "Camera Distance")
TrackBarGadget(#TrackZoom, #PanelX, #PanelY + 792, #PanelW, 28, 120, 320)
TextGadget(#TextZoomValue, #PanelX, #PanelY + 824, #PanelW, 20, "")

TextGadget(#TextFooterInfo, #PanelX, #PanelY + 850, #PanelW, 56, "Parallax quality scales overall movement. X/Y motion tunes direction feel. Foreground feather softens cut edges. Auto-save writes generated PNG assets into an `ImageTo3D_Autosave` folder beside the source image.")
CloseGadgetList()

ApplyControlValues(1.0, 1.0, 0.12, 18.0)
ApplyParallaxPreset(1)
ResetView()
SetGadgetState(#PanelMode, 0)
LastFPSUpdate = ElapsedMilliseconds()

If OpenWindowedScreen(GadgetID(#ScrollViewport), 0, 0, #ViewportVisibleW, #ViewportVisibleH, 0, 0, 0) = 0
  MessageRequester("Error", "Could not open the 3D viewport.")
  End
EndIf

CreateCamera(#CameraMain, 0, 0, 100, 100)
MoveCamera(#CameraMain, 0, 0, CameraDistance, #PB_Absolute)
CameraLookAt(#CameraMain, 0, 0, 0)
CreateCamera(#CameraDepth, 50, 0, 50, 100)
MoveCamera(#CameraDepth, 0, 0, CameraDistance - 0.7, #PB_Absolute)
CameraLookAt(#CameraDepth, 0, 0, 0)
CreateLight(#LightMain, RGB(255, 255, 255), 100, 80, 180)
AmbientColor(RGB(150, 150, 150))
UpdateValueLabels()
UpdateSceneVisibility()

OpenImageDialog()

Repeat
  Repeat
    Event = WindowEvent()

    Select Event
      Case #PB_Event_CloseWindow
        Quit = #True

      Case #PB_Event_Menu
        Select EventMenu()
          Case #MenuFileOpenImage
            OpenImageDialog()

          Case #MenuFileLoadFrontMask
            LoadFrontMaskDialog()

          Case #MenuFileLoadMidMask
            LoadMidMaskDialog()

          Case #MenuFileClearMasks
            ClearMaskFiles()

          Case #MenuFileExportLayers
            ExportGeneratedLayers()

          Case #MenuFileSaveViewport
            SaveViewportPNG()

          Case #MenuFileLoadProject
            LoadProjectDialog()

          Case #MenuFileSaveProject
            SaveProjectDialog()

          Case #MenuFileExit
            Quit = #True

          Case #MenuViewReset
            ResetView()

          Case #MenuHelpContents
            OpenHelpFile()

          Case #MenuHelpAbout
            ShowAboutDialog()
        EndSelect

      Case #PB_Event_Gadget
        Select EventGadget()
          Case #ComboQuality
            ApplyParallaxPreset(GetGadgetState(#ComboQuality))
            UpdateValueLabels()

          Case #ButtonOpen
            OpenImageDialog()

          Case #ButtonReset
            ResetView()

          Case #ButtonLoadFrontMask
            LoadFrontMaskDialog()

          Case #ButtonLoadMidMask
            LoadMidMaskDialog()

          Case #ButtonClearMasks
            ClearMaskFiles()

          Case #ButtonSaveProject
            SaveProjectDialog()

          Case #ButtonLoadProject
            LoadProjectDialog()

          Case #ButtonExportLayers
            ExportGeneratedLayers()

          Case #PanelMode
            UpdateSceneVisibility()

          Case #CheckAutoSaveAssets
            ReadControlValues()
            If AutoSaveAssetsEnabled And LoadedImageFile <> "" And SceneReady
              SaveGeneratedAnalysisFiles()
            EndIf

          Case #TrackDepth, #TrackTilt, #TrackSensitivity, #TrackSmoothing, #TrackZoom, #TrackMeshStrength, #TrackFrontThreshold, #TrackMidLow, #TrackMidHigh, #TrackBlur, #TrackMotionX, #TrackMotionY, #TrackFeather
            ReadControlValues()
            If LoadedImageFile <> "" And (EventGadget() = #TrackMeshStrength Or EventGadget() = #TrackFrontThreshold Or EventGadget() = #TrackMidLow Or EventGadget() = #TrackMidHigh Or EventGadget() = #TrackBlur Or EventGadget() = #TrackFeather)
              ScheduleImageRebuild()
            EndIf
        EndSelect
    EndSelect
  Until Event = 0

  If PendingImageRebuild And ElapsedMilliseconds() >= PendingImageRebuildAt
    PendingImageRebuild = #False
    RebuildImageWithCurrentMasks()
  EndIf

  ExamineKeyboard()
  If KeyboardPushed(#PB_Key_Escape)
    Quit = #True
  EndIf

  If WindowMouseX(#Window) >= #ViewportX And WindowMouseX(#Window) < (#ViewportX + #ViewportVisibleW) And WindowMouseY(#Window) >= #ViewportY And WindowMouseY(#Window) < (#ViewportY + #ViewportVisibleH)
    InputNX = (WindowMouseX(#Window) - (#ViewportX + (#ViewportVisibleW * 0.5))) / (#ViewportVisibleW * 0.5)
    InputNY = (WindowMouseY(#Window) - (#ViewportY + (#ViewportVisibleH * 0.5))) / (#ViewportVisibleH * 0.5)
  Else
    InputNX = 0.0
    InputNY = 0.0
  EndIf

  InputNX = ClampFloat(InputNX, -1.0, 1.0)
  InputNY = ClampFloat(InputNY, -1.0, 1.0)

  TargetYaw = InputNX * MotionXStrength * 7.0 * MouseSensitivity * PresetRotationScale
  TargetPitch = -InputNY * MotionYStrength * 5.2 * MouseSensitivity * PresetRotationScale
  CurrentYaw = CurrentYaw + (TargetYaw - CurrentYaw) * (SmoothFactor * PresetSmoothScale)
  CurrentPitch = CurrentPitch + (TargetPitch - CurrentPitch) * (SmoothFactor * PresetSmoothScale)

  TargetCamX = -InputNX * MotionXStrength * DepthStrength * 0.14 * MouseSensitivity * PresetCameraScale
  TargetCamY = InputNY * MotionYStrength * DepthStrength * 0.09 * MouseSensitivity * PresetCameraScale
  CurrentCamX = CurrentCamX + (TargetCamX - CurrentCamX) * (SmoothFactor * PresetSmoothScale)
  CurrentCamY = CurrentCamY + (TargetCamY - CurrentCamY) * (SmoothFactor * PresetSmoothScale)

  ApplyLayerTransforms()

  ClearScreen(RGB(16, 22, 34))
  RenderWorld()
  FramesThisSecond + 1
  If ElapsedMilliseconds() - LastFPSUpdate >= 1000
    CurrentFPS = (FramesThisSecond * 1000.0) / (ElapsedMilliseconds() - LastFPSUpdate)
    FramesThisSecond = 0
    LastFPSUpdate = ElapsedMilliseconds()
  EndIf
  DrawViewportOverlay()
  FlipBuffers()
  Delay(1)

Until Quit = #True

FreeSceneResources()

; IDE Options = PureBasic 6.40 (Windows - x64)
; CursorPosition = 7
; Folding = -----------
; Optimizer
; EnableThread
; EnableXP
; EnableAdmin
; DPIAware
; UseIcon = PB_ImageTo3D.ico
; Executable = ..\PB_ImageTo3D.exe
; IncludeVersionInfo
; VersionField0 = 1,0,0,0
; VersionField1 = 1,0,0,0
; VersionField2 = ZoneSoft
; VersionField3 = ImageTo3D
; VersionField4 = 1.0.0.0
; VersionField5 = 1.0.0.0
; VersionField6 = Converts an image to a 3D style image
; VersionField7 = ImageTo3D
; VersionField8 = ImageTo3D.exe
; VersionField9 = David Scouten
; VersionField13 = zonemaster60@gmail.com
; VersionField14 = https://github.com/zonemaster60