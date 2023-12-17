#EncoderValueCompressionLZW = 2
#EncoderValueCompressionCCITT3 = 3
#EncoderValueCompressionCCITT4 = 4
#EncoderValueCompressionRle = 5
#EncoderValueCompressionNone = 6
 
Structure ErrorCode
  section.l
  value.l
EndStructure

CompilerIf Defined(POINTF, #PB_Structure) = #False
Structure POINTF ; single precision point
  x.f
  y.f
EndStructure
CompilerEndIf

#WindowsError = 0
#ImageViewerError = 1
#GdiError = 2

Procedure Error(message.s, *code.ErrorCode, fatal.b)
  Select *code\section
    Case #ImageViewerError
      CodeMessage$ = "ImageViewer error: unknown"
    Case #GdiError
      Select *code\value
        Case 0
          ErrorBuffer$ = Space(1024)
          FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM, 0, GetLastError_(), 0, ErrorBuffer$, Len(ErrorBuffer$), 0)
          CodeMessage$ = ErrorBuffer$
        Case 1
          CodeMessage$ = "Generic error"
        Case 2
          CodeMessage$ = "Invalid parameter"
        Case 3
          CodeMessage$ = "Out of memory"
        Case 4
          CodeMessage$ = "Object busy"
        Case 5
          CodeMessage$ = "Insufficient buffer"
        Case 6
          CodeMessage$ = "Not implemented"
        Case 7
          ErrorBuffer$ = Space(1024)
          FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM, 0, GetLastError_(), 0, ErrorBuffer$, Len(ErrorBuffer$), 0)
          CodeMessage$ = "Win32 Error: "+ErrorBuffer$
        Case 8
          CodeMessage$ = "Wrong state"
        Case 9
          CodeMessage$ = "Aborted"
        Case 10
          CodeMessage$ = "File not found"
        Case 11
          CodeMessage$ = "Value overflow"
        Case 12
          CodeMessage$ = "Access denied"
        Case 13
          CodeMessage$ = "Unknown image format"
        Case 14
          CodeMessage$ = "Font family not found"
        Case 15
          CodeMessage$ = "Font style not found"
        Case 16
          CodeMessage$ = "Not TrueType font"
        Case 17
          CodeMessage$ = "Unsupported Gdiplus version"
        Case 18
          CodeMessage$ = "Gdiplus not initialized"
        Case 19
          CodeMessage$ = "Property not found"
        Case 20
          CodeMessage$ = "Property not supported"
      EndSelect
    Default
      ErrorBuffer$ = Space(1024)
      FormatMessage_(#FORMAT_MESSAGE_FROM_SYSTEM, 0, GetLastError_(), 0, ErrorBuffer$, Len(ErrorBuffer$), 0)
      CodeMessage$ = ErrorBuffer$
  EndSelect
  ;MessageRequester("Error", message+Chr(10)+Chr(10)+CodeMessage$, 0)
  ;setStatusMsg("Error: "+message+" "+CodeMessage$)
  If fatal
    End
  EndIf
EndProcedure

Structure GdiplusStartupInput
  GdiplusVersion.l
  DebugEventCallback.l
  SuppressBackgroundThread.l
  SuppressExternalCodecs.l
EndStructure

; Structure CLSID
;   Data1.l
;   Data2.w[2]
;   Data3.b[8]
; EndStructure

Structure MyGUID
  Data1.l
  Data2.w[2]
  Data3.b[8]
EndStructure

Structure ImageCodecInfo
  Clsid.CLSID         ; Codec identifier.
  FormatID.MyGUID     ; File format identifier. GUIDs that identify various file formats (ImageFormatBMP, ImageFormatEMF, And the like) are defined in Gdiplusimaging.h.
  CodecName.s         ; WCHAR * Pointer To a null-terminated string that contains the codec name.
  DllName.s           ; WCHAR * Pointer To a null-terminated string that contains the path name of the DLL in which the codec resides. If the codec is not in a DLL, this pointer is NULL.
  FormatDescription.s ; WCHAR * Pointer To a null-terminated string that contains the name of the file format used by the codec.
  FilenameExtension.s ; WCHAR * Pointer To a null-terminated string that contains all file-name extensions associated with the codec. The extensions are separated by semicolons.
  MimeType.s          ; WCHAR * Pointer To a null-terminated string that contains the mime type of the codec.
  Flags.l             ; DWORD  Combination of flags from the ImageCodecFlags enumeration.
  Version.l           ; DWORD  Integer that indicates the version of the codec.
  SigCount.l          ; DWORD  Integer that indicates the number of signatures used by the file format associated with the codec.
  SigSize.l           ; DWORD  Integer that indicates the number of bytes in each signature.
  SigPattern.l        ; BYTE * Pointer To an array of bytes that contains the pattern For each signature.
  SigMask.l           ; BYTE * Pointer To an array of bytes that contains the mask For each signature.
EndStructure

#EncoderParameterValueTypeLong = 4

#EncoderValueCompressionLZW = 2
#EncoderValueCompressionCCITT3 = 3
#EncoderValueCompressionCCITT4 = 4
#EncoderValueCompressionRle = 5
#EncoderValueCompressionNone = 6

Structure EncoderParameter
  Guid.MyGUID
  NumberOfValues.l
  Type.l
  Value.l
EndStructure

Structure EncoderParameters
  Count.l
  Parameter1.EncoderParameter
;  Parameter2.EncoderParameter
EndStructure

Structure RECTF
  left.f
  top.f
  right.f
  bottom.f
EndStructure

Global Gdiplus, gdiplusToken, hbmReturn, encoderClsid
Global *GdiplusStartup, *GdiplusShutdown, *GdipSaveImageToFile, *GdipGetImageEncodersSize
Global *GdipGetImageEncoders, *GdipCreateBitmapFromHBITMAP, *GdipDisposeImage

Global *GdipCreateFromHDC
Global *GdipCreateFromHWND
Global *GdipCreateLineBrushI
Global *GdipCreateSolidFill
Global *GdipFillRectangleI
Global *GdipFillEllipseI
Global *GdipDeleteGraphics
Global *GdipDeleteBrush
Global *GdipCreatePathGradientI
Global *GdipSetPathGradientCenterColor
Global *GdipSetPathGradientCenterPointI
Global *GdipDrawLine
Global *GdipCreatePen1
Global *GdipDeletePen
Global *GdipDrawImage
Global *GdipDrawImageI
Global *GdipDrawImageRectI
Global *GdipDrawImageRectRect
Global *GdipDrawImageRectRectI
Global *GdipCreateImageAttributes
Global *GdipSetImageAttributesColorMatrix
Global *GdipDisposeImageAttributes
Global *GdipDisposeImage
Global *GdipCreateBitmapFromHBITMAP
Global *GdipCreateBitmapFromScan0
Global *GdipCreateBitmapFromGraphics
Global *GdipCreateBitmapFromGdiDib
Global *GdipBitmapSetPixel
Global *GdipBitmapLockBits
Global *GdipBitmapUnLockBits
Global *GdipImageRotateFlip
Global *GdipSetCompositingMode
Global *GdipSetCompositingQuality
Global *GdipSetPixelOffsetMode
Global *GdipSetSmoothingMode
Global *GdipSetLinePresetBlend
Global *GdipCreatePath
Global *GdipCreatePathGradientFromPath
Global *GdipAddPathEllipseI
Global *GdipDeletePath
Global *GdipSetPathGradientCenterPoint

Prototype GdipCreatePen1(ARGB.l, width.f, unit.l, *pen)
Prototype GdipSetPenStartCap(*pen, startCap.l)
Prototype GdipSetPenEndCap(*pen, endCap.l)
Prototype GdipCreateSolidFill(ARGB.l, *brush)
Prototype GdipDeleteBrush(*brush)
Prototype GdipDrawLines(*graphics, *pen, *points, count.l)
Prototype GdipCreateFontFromDC(hdc, *font)
Prototype GdipDeleteFont(*font)
Prototype GdipDrawString(*graphics, *string, length.i, *font, *layoutRect.RECTF, *stringFormat, *brush)
Prototype GdipMeasureString(*graphics, *string, length.i, *font, *layoutRect.RECTF, *stringFormat, *boundingBox.RECTF, *codepointsFitted.integer, *linesFilled.integer)
Prototype GdipRotateWorldTransform(*graphics, angle.f, mode)
Prototype GdipResetWorldTransform(*graphics)
Prototype GdipTranslateWorldTransform(*graphics, wmidf.f, hmidf.f, mode)
Prototype GdipAddPathArc(*path, x.f, y.f, width.f, height.f, startAngle.f, sweepAngle.f)
Prototype GdipCreatePath(brushmode.l, *path)
Prototype GdipClosePathFigure(*path)
Prototype GdipDeletePath(*path)
Prototype GdipDrawPath(*graphics, *pen, *path)
Prototype GdipFillPath(*graphics, *brush, *path)
Prototype GdipDrawRectangle(*graphics, *pen, x.f, y.f, width.f, height.f)
Prototype GdipFillRectangle(*graphics, *brush, x.f, y.f, width.f, height.f)
Prototype GdipSetPenDashStyle(*pen, dashstyle.i)
Prototype GdipCreateLineBrush(*p1, *p2, colour1.i, colour2.i , wrapMode.i, *brush)
Prototype GdipDrawEllipse(*graphics, *pen, x.f, y.f, width.f, height.f)
Prototype GdipFillEllipse(*graphics, *brush, x.f, y.f, width.f, height.f)
Prototype GdipAddPathLine(*path, x1.f, y1.f, x2.f, y2.f)
Prototype GdipAddPathLine2(*path, *points, count.i)
Prototype GdipAddPathPolygon(*path, *points, count.i)
Prototype GdipWidenPath(*path, *pen, *matrix, flatness.f)
Prototype GdipSetClipHrgn(*graphics, hRgn.i, combineMode.l)
Prototype GdipSetClipRect(*graphics, x.f, y.f, width.f, height.f, combinemode.l)
Prototype GdipSetClipPath(*graphics, *path, combineMode.l)
Prototype GdipSetPenMode(*pen, penMode.l)

Procedure GdiStart()
  Gdiplus = OpenLibrary(0, "GDIPLUS.DLL")
  If Gdiplus
    CoInitialize_(#Null)
    *GdiplusStartup = GetFunction(0, "GdiplusStartup")
    If *GdiplusStartup
      gdpsi.GdiplusStartupInput
      gdpsi\GdiplusVersion = 1
      gdpsi\DebugEventCallback = 0
      gdpsi\SuppressBackgroundThread = 0
      gdpsi\SuppressExternalCodecs = 0
      CallFunctionFast(*GdiplusStartup, @gdiplusToken, gdpsi, #Null)
      If gdiplusToken
        *GdipGetImageEncodersSize = GetFunction(0, "GdipGetImageEncodersSize")
        *GdipGetImageEncoders = GetFunction(0, "GdipGetImageEncoders")
        *GdipCreateBitmapFromHBITMAP = GetFunction(0, "GdipCreateBitmapFromHBITMAP")
        *GdipSaveImageToFile = GetFunction(0, "GdipSaveImageToFile")
        *GdipDisposeImage = GetFunction(0, "GdipDisposeImage")
        *GdiplusShutdown = GetFunction(0, "GdiplusShutdown")
        
        *GdipCreateFromHDC = GetFunction(0,"GdipCreateFromHDC")
        *GdipCreateFromHWND = GetFunction(0,"GdipCreateFromHWND")
        *GdipCreateLineBrushI = GetFunction(0,"GdipCreateLineBrushI")
        *GdipCreateSolidFill = GetFunction(0,"GdipCreateSolidFill")
        *GdipFillRectangleI = GetFunction(0,"GdipFillRectangleI")
        *GdipFillEllipseI = GetFunction(0,"GdipFillEllipseI")
        *GdipDeleteGraphics = GetFunction(0,"GdipDeleteGraphics")
        *GdipDeleteBrush = GetFunction(0,"GdipDeleteBrush")
        *GdipCreatePathGradientI = GetFunction(0,"GdipCreatePathGradientI")
        *GdipSetPathGradientCenterColor = GetFunction(0,"GdipSetPathGradientCenterColor")
        *GdipSetPathGradientCenterPointI = GetFunction(0,"GdipSetPathGradientCenterPointI")
        *GdipDrawLine = GetFunction(0,"GdipDrawLineI")
        *GdipCreatePen1 = GetFunction(0,"GdipCreatePen1")
        
        Global GdipCreatePen1.GdipCreatePen1 = GetFunction(0, "GdipCreatePen1")
        Global GdipCreateSolidFill.GdipCreateSolidFill = GetFunction(0, "GdipCreateSolidFill")
        Global GdipDeleteBrush.GdipDeleteBrush = GetFunction(0, "GdipDeleteBrush")
        Global GdipDrawLines.GdipDrawLines = GetFunction(0, "GdipDrawLines")
        Global GdipSetPenStartCap.GdipSetPenStartCap = GetFunction(0, "GdipSetPenStartCap")
        Global GdipSetPenEndCap.GdipSetPenEndCap = GetFunction(0, "GdipSetPenEndCap")
        Global GdipCreateFontFromDC.GdipCreateFontFromDC = GetFunction(0, "GdipCreateFontFromDC")
        Global GdipDeleteFont.GdipDeleteFont = GetFunction(0, "GdipDeleteFont")
        Global GdipDrawString.GdipDrawString = GetFunction(0, "GdipDrawString")
        Global GdipMeasureString.GdipMeasureString = GetFunction(0, "GdipMeasureString")
        Global GdipRotateWorldTransform.GdipRotateWorldTransform = GetFunction(0, "GdipRotateWorldTransform")     
        Global GdipTranslateWorldTransform.GdipTranslateWorldTransform = GetFunction(0, "GdipTranslateWorldTransform")     
        Global GdipResetWorldTransform.GdipResetWorldTransform = GetFunction(0, "GdipResetWorldTransform") 
        Global GdipAddPathArc.GdipAddPathArc = GetFunction(0, "GdipAddPathArc")
        Global GdipCreatePath.GdipCreatePath = GetFunction(0, "GdipCreatePath")
        Global GdipClosePathFigure.GdipClosePathFigure = GetFunction(0, "GdipClosePathFigure")
        Global GdipDeletePath.GdipDeletePath = GetFunction(0, "GdipClosePathFigure")
        Global GdipDrawPath.GdipDrawPath = GetFunction(0, "GdipDrawPath")
        Global GdipFillPath.GdipFillPath = GetFunction(0, "GdipFillPath")
        Global GdipFillRectangle.GdipFillRectangle = GetFunction(0, "GdipFillRectangle")
        Global GdipDrawRectangle.GdipDrawRectangle = GetFunction(0, "GdipDrawRectangle")
        Global GdipSetPenDashStyle.GdipSetPenDashStyle = GetFunction(0, "GdipSetPenDashStyle")
        Global GdipCreateLineBrush.GdipCreateLineBrush = GetFunction(0, "GdipCreateLineBrush")
        Global GdipDrawEllipse.GdipDrawEllipse = GetFunction(0, "GdipDrawEllipse")
        Global GdipFillEllipse.GdipFillEllipse = GetFunction(0, "GdipFillEllipse")
        Global GdipAddPathLine.GdipAddPathLine = GetFunction(0, "GdipAddPathLine")
        Global GdipAddPathLine2.GdipAddPathLine2 = GetFunction(0, "GdipAddPathLine2")
        Global GdipAddPathPolygon.GdipAddPathPolygon = GetFunction(0, "GdipAddPathPolygon")
        Global GdipWidenPath.GdipWidenPath = GetFunction(0, "GdipWidenPath")
        Global GdipSetClipHrgn.GdipSetClipHrgn = GetFunction(0, "GdipSetClipHrgn")
        Global GdipSetClipRect.GdipSetClipRect = GetFunction(0, "GdipSetClipRect")
        Global GdipSetClipPath.GdipSetClipPath = GetFunction(0, "GdipSetClipPath")
        Global GdipSetPenMode.GdipSetPenMode = GetFunction(0, "GdipSetPenMode")
        
        *GdipDeletePen = GetFunction(0,"GdipDeletePen")
        *GdipDrawImage = GetFunction(0,"GdipDrawImage")
        *GdipDrawImageI = GetFunction(0,"GdipDrawImageI")
        *GdipDrawImageRectI = GetFunction(0,"GdipDrawImageRectI")
        *GdipDrawImageRectRect = GetFunction(0,"GdipDrawImageRectRect")
        *GdipDrawImageRectRectI = GetFunction(0,"GdipDrawImageRectRectI")
        *GdipCreateImageAttributes = GetFunction(0,"GdipCreateImageAttributes")
        *GdipSetImageAttributesColorMatrix = GetFunction(0,"GdipSetImageAttributesColorMatrix")
        *GdipDisposeImageAttributes = GetFunction(0,"GdipDisposeImageAttributes")
        *GdipDisposeImage = GetFunction(0,"GdipDisposeImage")
        *GdipCreateBitmapFromHBITMAP = GetFunction(0, "GdipCreateBitmapFromHBITMAP")
        *GdipCreateBitmapFromScan0 = GetFunction(0, "GdipCreateBitmapFromScan0")
        *GdipCreateBitmapFromGraphics = GetFunction(0, "GdipCreateBitmapFromGraphics")
        *GdipCreateBitmapFromGdiDib = GetFunction(0, "GdipCreateBitmapFromGdiDib")
        *GdipBitmapSetPixel = GetFunction(0, "GdipBitmapSetPixel")
        *GdipBitmapLockBits = GetFunction(0, "GdipBitmapLockBits")
        *GdipBitmapUnLockBits = GetFunction(0, "GdipBitmapUnlockBits")
        *GdipImageRotateFlip = GetFunction(0, "GdipImageRotateFlip")
        *GdipSetCompositingMode = GetFunction(0, "GdipSetCompositingMode")
        *GdipSetCompositingQuality = GetFunction(0, "GdipSetCompositingQuality")
        *GdipSetPixelOffsetMode = GetFunction(0, "GdipSetPixelOffsetMode")
        *GdipSetSmoothingMode = GetFunction(0, "GdipSetSmoothingMode")
        *GdipSetLinePresetBlend = GetFunction(0, "GdipSetLinePresetBlend")
        *GdipCreatePath = GetFunction(0, "GdipCreatePath")
        *GdipCreatePathGradientFromPath = GetFunction(0, "GdipCreatePathGradientFromPath")
        *GdipAddPathEllipseI = GetFunction(0, "GdipAddPathEllipseI")
        *GdipDeletePath = GetFunction(0, "GdipDeletePath")
        *GdipSetPathGradientCenterPoint = GetFunction(0, "GdipSetPathGradientCenterPoint")
        
        
        If (*GdipGetImageEncodersSize And *GdipGetImageEncoders And *GdipCreateBitmapFromHBITMAP And *GdipSaveImageToFile And *GdiplusShutdown)=0
          Gdiplus = 0
        EndIf
      Else
        Gdiplus = 0
      EndIf
    Else
      Gdiplus = 0
    EndIf
  Else
    Gdiplus = 0
  EndIf
  ProcedureReturn Gdiplus
EndProcedure

Procedure GdiEnd()
  If Gdiplus
    CallFunctionFast(*GdiplusShutdown, gdiplusToken)
    CoUninitialize_()
  EndIf
EndProcedure

Procedure GetEncoderClsid(Format$, *Clsid)
  Gerror.ErrorCode
  result = 0
  num = 0
  size = 0
  FormatWSize = (Len(Format$)*2)+2
  *FormatW = CoTaskMemAlloc_(FormatWSize)
  If *FormatW
    If MultiByteToWideChar_(#CP_ACP, 0, @Format$, -1, *FormatW, Len(Format$)+1)
      CallFunctionFast(*GdipGetImageEncodersSize, @num, @size)
      If size
        *ImageCodecInfoArray = CoTaskMemAlloc_(size)
        If *ImageCodecInfoArray
          result = CallFunctionFast(*GdipGetImageEncoders, num, size, *ImageCodecInfoArray)
          If result=#S_OK
            For j=0 To num-1
              *pImageCodecInfo.ImageCodecInfo = *ImageCodecInfoArray+(SizeOf(ImageCodecInfo)*j);*ImageCodecInfoArray+((size/num)*j)
              If CompareMemory(@*pImageCodecInfo\MimeType, *FormatW, FormatWSize)
                PokeL(*Clsid, *pImageCodecInfo\Clsid)
                result = j
              EndIf
            Next j
          Else
            ErrorMessage$ = "GdipGetImageEncoders() failed."
          EndIf
          CoTaskMemFree_(*ImageCodecInfoArray)
        Else
          Gerror\section = #WindowsError
          Error("CoTaskMemAlloc_() failed.", Gerror, 0)
        EndIf
      Else
        ErrorMessage$ = "GdipGetImageEncodersSize() failed."
      EndIf
    Else
      Gerror\section = #WindowsError
      Error("MultiByteToWideChar_() failed.", Gerror, 0)
    EndIf
    CoTaskMemFree_(*FormatW)
  Else
    Gerror\section = #WindowsError
    Error("CoTaskMemAlloc_() failed.", Gerror, 0)
  EndIf
  If ErrorMessage$
    Gerror\section = #GdiError
    Gerror\value = result
    Error(ErrorMessage$, Gerror, 0)
    result = 0
  EndIf
  ProcedureReturn result
EndProcedure

Procedure GdiSave(File$, hbm, compression)
  Gerror.ErrorCode
  If GetEncoderClsid("image/tiff", @encoderClsid)
    FileWSize = (Len(File$)*2)+2
    *FileW = CoTaskMemAlloc_(FileWSize)
    If *FileW
      If MultiByteToWideChar_(#CP_ACP, 0, File$, -1, *FileW, Len(File$)+1)
        If hbm
          eP.encoderParameters
          encoderParams = eP
          eP\Count = 1 ; 2
          CopyMemory(?EncoderCompression, eP\Parameter1\Guid, SizeOf(MyGUID))
          eP\Parameter1\Type = #EncoderParameterValueTypeLong
          eP\Parameter1\NumberOfValues = 1
          eP\Parameter1\Value = @compression
          bitmap = 0
          result = CallFunctionFast(*GdipCreateBitmapFromHBITMAP, hbm, 0, @bitmap)
          If result=#S_OK And bitmap
            If FileSize(File$)
              DeleteFile(File$)
            EndIf
            result = CallFunctionFast(*GdipSaveImageToFile, bitmap, *FileW, encoderClsid, encoderParams)
            If result<>#S_OK
              ErrorMessage$ = "GdipSaveImageToFile() failed."
            EndIf
            result = CallFunctionFast(*GdipDisposeImage, bitmap)
          Else
            ErrorMessage$ = "GdipCreateBitmapFromHBITMAP() failed."
          EndIf
        EndIf
      Else
        Gerror\section = #WindowsError
        Error("MultiByteToWideChar_() failed.", Gerror, 0)
      EndIf
      CoTaskMemFree_(*FileW)
    Else
      Gerror\section = #WindowsError
      Error("CoTaskMemAlloc_() failed.", Gerror, 0)
    EndIf
  Else
    Gerror\section = #ImageViewerError
    Error("GetEncoderCLSID() procedure failed.", Gerror, 0)
  EndIf
  If ErrorMessage$
    Gerror\section = #GdiError
    Gerror\value = result
    Error(ErrorMessage$, Gerror, 0)
    result = 0
  Else
    result = 1
  EndIf
  ProcedureReturn result
EndProcedure

Structure Seeker
  StructureUnion
    b.b
    w.w
    l.l
  EndStructureUnion
EndStructure

Procedure Rev16(value.w)
  ProcedureReturn ((value&$FF00)>>8)|((value&$FF)<<8)
EndProcedure

Procedure Rev32(value)
  EnableASM
  ;MOV eax, value
  ;BSWAP eax
  ProcedureReturn
  DisableASM
EndProcedure

Procedure SetTIFFResolution(file$, dpi)
  Gerror.ErrorCode
  hFile = OpenFile(#PB_Any, file$)
  If hFile
    TIFFSize = Lof(hFile)
    If TIFFSize>$9A
      *TIFF = AllocateMemory(Lof(hFile))
      ReadData(hFile, *TIFF, TIFFSize)
      *TIFFSeek.Seeker = *TIFF
      Select *TIFFSeek\w
        Case 'MM'
          dpi = Rev32(dpi)
          *TIFFSeek+4
          IFDOffset = Rev32(*TIFFSeek\l)
          inch = Rev16(2)
          den = Rev32(1)
          rv = 1
        Case 'II'
          *TIFFSeek+4
          IFDOffset = *TIFFSeek\l
          inch = 2
          den = 1
          rv = 0
        Default
          Gerror\section = #ImageViewerError
          Error("Not a TIFF file.", Gerror, 0)
          CloseFile(hFile)
          ProcedureReturn #False
      EndSelect
      *TIFFSeek = *TIFF+IFDOffset
      If TIFFSize>IFDOffset+2
        If rv:FieldCount = Rev16(*TIFFSeek\w):Else:FieldCount = *TIFFSeek\w:EndIf
        If FieldCount
          *TIFFSeek+2
          For i=0 To FieldCount-1
            If *TIFFSeek<*TIFF+TIFFSize-2
              If rv:Tag = Rev16(*TIFFSeek\w):Else:Tag = *TIFFSeek\w:EndIf
              Select Tag
                Case 282 ; XResolution
                  *TagSeek.Seeker = *TIFFSeek+8
                  If rv:ValueOffset = Rev32(*TagSeek\l):Else:ValueOffset = *TagSeek\l:EndIf
                  If ValueOffset<=TIFFSize-8
                    PokeL(*TIFF+ValueOffset, dpi)
                    PokeL(*TIFF+ValueOffset+4, den)
                    xrelDone = 1
                  EndIf
                Case 283 ; YResolution
                  *TagSeek = *TIFFSeek+8
                  If rv:ValueOffset = Rev32(*TagSeek\l):Else:ValueOffset = *TagSeek\l:EndIf
                  If ValueOffset<=TIFFSize-8
                    PokeL(*TIFF+ValueOffset, dpi)
                    PokeL(*TIFF+ValueOffset+4, den)
                    yrelDone = 1
                  EndIf
                Case 296 ; ResolutionUnit
                  PokeW(*TIFFSeek+8, inch)
                  ruDone = 1
              EndSelect
              *TIFFSeek+12
            EndIf
          Next i
        Else
          Gerror\section = #ImageViewerError
          Error("Field count not found.", Gerror, 0)
        EndIf
        If ruDone&yrelDone&xrelDone
          FileSeek(hfile, 0)
          WriteData(hFile,*TIFF, TIFFSize)
          result = #True
        Else
          Gerror\section = #ImageViewerError
          Error("Resolution fields not found.", Gerror, 0)
        EndIf
      Else
        Gerror\section = #ImageViewerError
        Error("Offset past end of file.", Gerror, 0)
      EndIf
      
      FreeMemory(*TIFF)
      
    Else
      Gerror\section = #ImageViewerError
      Error("IFDOffset past end of file.", Gerror, 0)
    EndIf
    CloseFile(hFile)
    ProcedureReturn result
  Else
    Gerror\section = #WindowsError
    Error("Can't open file.", Gerror, 0)
  EndIf
  ProcedureReturn #False
EndProcedure

Procedure SaveTIFF(ImageID, file$, compression, dpi)
  If GDISave(file$, ImageID, compression)
    result = SetTIFFResolution(file$, dpi)
  EndIf
  ProcedureReturn result
EndProcedure

Procedure gradientFill(dc, *rec.RECTF, colour1, colour2, vertical = #False)
  
  If vertical = #False
    p1.POINTF
    p1\x = *rec\left
    p1\y = *rec\top
    p2.POINTF
    p2\x = *rec\right
    p2\y = *rec\top
  Else
    p1.POINTF
    p1\x = *rec\left
    p1\y = *rec\top
    p2.POINTF
    p2\x = *rec\left
    p2\y = *rec\bottom
  EndIf
  
  CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
  ;CallFunctionFast(*GdipSetCompositingMode, GraphicObject, 0)
  ;CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 1) ; CompositingQualityHighSpeed
  ;CallFunctionFast(*GdipSetPixelOffsetMode, GraphicObject, 3) ; PixelOffsetModeNone
  ;CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 3) ; SmoothingModeNone
  
  ;CallFunctionFast(*GdipCreateLineBrushI,p1,p2,colour1,colour1,1,@BrushObject)
  GdipCreateLineBrush(p1, p2, colour1, colour1, 1, @BrushObject)
  Dim cols.l(3)
  Dim cpos.f(3)
  cols(0) = colour1
  cpos(0) = 0
  cols(1) = colour2
  cpos(1) = 0.5
  cols(2) = colour1
  cpos(2) = 1
  CallFunctionFast(*GdipSetLinePresetBlend, BrushObject, cols(), cpos(), 3)
  
;   extraColours = ListSize(Gradient()\colours())
;   If extraColours > 0
;     Dim cols.l(extraColours+3)
;     Dim cpos.f(extraColours+3)
;     cols(0) = Gradient()\colour1
;     cpos(0) = 0
;     n = 1
;     ForEach Gradient()\colours()
;       cols(n) = Gradient()\colours()\colour
;       cpos(n) = Gradient()\colours()\pos
;       n = n + 1
;     Next
;     cols(n) = Gradient()\colour2
;     cpos(n) = 1
;     CallFunctionFast(*GdipSetLinePresetBlend, BrushObject, cols(), cpos(), extraColours+2)
;   EndIf

  GdipFillRectangle(GraphicObject,BrushObject,*rec\left,*rec\top,*rec\right-*rec\left,*rec\bottom-*rec\top)
  ;CallFunctionFast(*GdipFillRectangleI,GraphicObject,BrushObject,*rec\left,*rec\top,*rec\right-*rec\left,*rec\bottom-*rec\top) ; x,y width,height
  
  CallFunctionFast(*GdipDeleteGraphics,GraphicObject)
  CallFunctionFast(*GdipDeleteBrush,BrushObject) 
  
EndProcedure

; ImageFile$ = OpenFileRequester("Open image file", "", "Bitmap file (*.bmp)|*.bmp", 0)
; If ImageFile$
;   hImage = LoadImage(0, ImageFile$)
;   TIFFFile$ = SaveFileRequester("Save TIFF file", Left(ImageFile$, Len(ImageFile$)-Len(GetExtensionPart(ImageFile$))-1)+".tiff", "TIFF image file (*.tiff;*.tif)|*.tiff;*.tif", 0)
;   If TIFFFile$
;     If GdiStart()
;       compression = #EncoderValueCompressionLZW
; ;        compression = #EncoderValueCompressionCCITT3
; ;        compression = #EncoderValueCompressionCCITT4
; ;        compression = #EncoderValueCompressionRle
; ;        compression = #EncoderValueCompressionNone
;       dpi = 150
;       Debug SaveTIFF(hImage, TIFFFile$, compression, dpi)
;       GdiEnd()
;     EndIf
;   EndIf
; EndIf

DataSection
EncoderCompression:
Data.l $e09d739d
Data.w $ccd4, $44ee
Data.b $8e, $ba, $3f, $bf, $8b, $e4, $fc, $58
EndDataSection 
; IDE Options = PureBasic 5.71 LTS (Windows - x64)
; CursorPosition = 470
; FirstLine = 442
; Folding = --
; EnableXP