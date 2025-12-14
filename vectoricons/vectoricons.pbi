; PB 5.40+, cross-platform
; Established and maintained by Little John, last updated on 2019-04-10
; http://www.purebasic.fr/english/viewtopic.php?f=12&t=65091


; TABLE OF CONTENTS OF THIS FILE
;===============================
; A) Utility module "VDraw"
;    - Procedure Color_Darken():
;      Darken a given RGBA color (the alpha channel is not changed)
;
;    - Procedure Color_Transparency():
;      Change the transparency of a given RGBA color
;
;    - Procedure StartNewVectorImage():
;      Wrapper for simplifying the usage of StartVectorDrawing() in
;      combination with CreateImage()
;
;  +----------------------------------------------------------------+
;  | CompilerIf #PB_Compiler_Version <= 542                         |
;  |    Macro AddPathArc():                                         |
;  |    Replacement for the built-in command AddPathArc(), which is |
;  |    buggy at least in PB 5.42 on Windows and Linux.             |
;  | CompilerEndIf                                                  |
;  +----------------------------------------------------------------+
;
; B) Main module "VectorIcons"
;    1) Public part
;       - CSS color definitions
;       - Own definitions of colors used in this module
;       * Declarations of public icon procedures
;
;    2) Private part
;       - Private constants
;       - Auxiliary procedures
;       - Private macros/procedures of basic movable and resizable shapes
;         that can be used by any icon procedure.
;       * Procedures which generate the icons, sometimes with optional
;         parameters e.g. for flipping or rotating the respective icon.



DeclareModule VDraw
   ; * General (vector) drawing tools *

   Declare.i Color_Darken (Color.i, Fact.d)
   Declare.i Color_Transparency (Color.i, Fact.d)
   Declare.i StartNewVectorImage (img.i, width.i, height.i, depth.i=24, backColor.i=0, unit.i=#PB_Unit_Pixel)

   CompilerIf #PB_Compiler_Version <= 542
      Declare AddPathRoundedCorner (x1.d, y1.d, x2.d, y2.d, radius.d, flags.i=#PB_Path_Default)
      ; Do not call AddPathRoundedCorner() directly. Always use the macro AddPathArc().

      Macro AddPathArc (_x1_, _y1_, _x2_, _y2_, _radius_, _flags_=#PB_Path_Default)
         VDraw::AddPathRoundedCorner(_x1_, _y1_, _x2_, _y2_, _radius_, _flags_)
      EndMacro
   CompilerEndIf
EndDeclareModule


Module VDraw
   EnableExplicit


   Procedure.i Color_Darken (Color.i, Fact.d)
      ; [by Oma, 2016-04-21]
      Protected.i Red, Green, Blue, Alpha

      If Fact > 1.0 : Fact = 1.0 : EndIf
      Alpha = Alpha(Color)
      Red   = Red(Color)   * Fact
      Green = Green(Color) * Fact
      Blue  = Blue(Color)  * Fact

      ProcedureReturn RGBA(Red, Green, Blue, Alpha)
   EndProcedure


   Procedure.i Color_Transparency (Color.i, Fact.d)
      ; [by Oma, 2016-05-10]
      Protected.i Red, Green, Blue, Alpha

      If Fact > 1.0 : Fact = 1.0 : EndIf
      Alpha = Alpha(Color) * Fact
      Red   = Red(Color)
      Green = Green(Color)
      Blue  = Blue(Color)

      ProcedureReturn RGBA(Red, Green, Blue, Alpha)
   EndProcedure


   Procedure.i StartNewVectorImage (img.i, width.i, height.i, depth.i=24, backColor.i=0, unit.i=#PB_Unit_Pixel)
      ; Meaning of the parameters: same as for CreateImage() and ImageVectorOutput().
      ; Return value: if img = #Pb_Any --> number of the created image,
      ;               on error --> 0
      Protected ret.i

      ret = CreateImage(img, width, height, depth, backColor)
      If ret
         If img = #PB_Any
            img = ret
         EndIf
         If StartVectorDrawing(ImageVectorOutput(img, unit)) = 0
            FreeImage(img)
            ret = 0
         EndIf
      EndIf

      ProcedureReturn ret
   EndProcedure


   CompilerIf #PB_Compiler_Version <= 542
      ; Replacement of AddPathArc() command, which is buggy at least in PB 5.42 on Windows and Linux
      ; (see <http://www.purebasic.fr/english/viewtopic.php?f=4&t=63582>)
      ;
      ; [by Little John;
      ;  slightly modified after
      ;  <http://stackoverflow.com/questions/24771828/algorithm-for-creating-rounded-corners-in-a-polygon>, 2016-03-28]

      Macro GetLength (_a_, _b_)
         Sqr((_a_) * (_a_) + (_b_) * (_b_))
      EndMacro

      Macro GetProportionPointX (_px_, _segment_, _length_, _dx_)
         ((_px_) - (_dx_) * (_segment_) / (_length_))
      EndMacro

      Macro GetProportionPointY (_py_, _segment_, _length_, _dy_)
         ((_py_) - (_dy_) * (_segment_) / (_length_))
      EndMacro


      Procedure AddPathRoundedCorner (x1.d, y1.d, x2.d, y2.d, radius.d, flags.i=#PB_Path_Default)
         ; Meaning of the parameters: same as for the built-in command AddPathArc()
         Protected.d dx1, dy1, dx2, dy2, angle, tan, segment, length1, length2, length, c2x, c2y, dx, dy, L, po
         Protected.d c1x, c1y, circlePointX, circlePointY, startangle, endangle, sweepAngle
         Protected.i circleFlags

         If flags & #PB_Path_Relative
            x1 + PathCursorX()
            y1 + PathCursorY()
            x2 + PathCursorX()
            y2 + PathCursorY()
         EndIf

         ; Vector 1
         dx1 = x1 - PathCursorX()
         dy1 = y1 - PathCursorY()

         ; Vector 2
         dx2 = x1 - x2
         dy2 = y1 - y2

         ; Angle between vector 1 and vector 2 divided by 2
         angle = (ATan2(dx1, dy1) - ATan2(dx2, dy2)) / 2

         ; The length of segment between the angular point and the
         ; points of intersection with the circle of a given radius
         tan = Abs(Tan(angle))
         segment = radius / tan

         ; Check the segment
         length1 = GetLength(dx1, dy1)
         length2 = GetLength(dx2, dy2)
         length = length1
         If length > length2
            length = length2
         EndIf

         If segment > length
            segment = length
            radius = length * tan
         EndIf

         ; Points of intersection are calculated by the proportion between
         ; the coordinates of the vector, length of vector and the length of the segment.
         c1x = GetProportionPointX(x1, segment, length1, dx1)
         c1y = GetProportionPointY(y1, segment, length1, dy1)
         c2x = GetProportionPointX(x1, segment, length2, dx2)
         c2y = GetProportionPointY(y1, segment, length2, dy2)

         ; Calculation of the coordinates of the circle center
         ; by the addition of angular vectors
         dx = x1 * 2 - c1x - c2x
         dy = y1 * 2 - c1y - c2y

         L = GetLength(dx, dy)
         po = GetLength(segment, radius)

         circlePointX = GetProportionPointX(x1, po, L, dx)
         circlePointY = GetProportionPointY(y1, po, L, dy)

         ; StartAngle and EndAngle of arc
         startangle = ATan2(c1x - circlePointX, c1y - circlePointY)
         endangle   = ATan2(c2x - circlePointX, c2y - circlePointY)

         ; Additional checks
         sweepAngle = endAngle - startAngle
         circleFlags = #PB_Path_Connected
         If (-#PI < sweepAngle And sweepAngle < 0) Or sweepAngle > #PI
            circleFlags | #PB_Path_CounterClockwise
         EndIf

         ; Draw result
         AddPathLine(c1x, c1y)
         AddPathCircle(circlePointX, circlePointY, radius, Degree(startAngle), Degree(endAngle), circleFlags)
      EndProcedure
   CompilerEndIf
EndModule


DeclareModule VectorIcons
   ; * Main module *

   ;--------[ Color definitions in RGBA format (32 bit) ]---------
   ;{
   ; -- CSS colors (thanks to Oma)
   ; see e.g. table at <http://www.w3schools.com/colors/colors_names.asp>

   #CSS_AliceBlue            = $FFFFF8F0
   #CSS_AntiqueWhite         = $FFD7EBFA
   #CSS_Aqua                 = $FFFFFF00
   #CSS_Aquamarine           = $FFD4FF7F
   #CSS_Azure                = $FFFFFFF0
   #CSS_Beige                = $FFDCF5F5
   #CSS_Bisque               = $FFC4E4FF
   #CSS_Black                = $FF000000
   #CSS_BlanchedAlmond       = $FFCDEBFF
   #CSS_Blue                 = $FFFF0000
   #CSS_BlueViolet           = $FFE22B8A
   #CSS_Brown                = $FF2A2AA5
   #CSS_BurlyWood            = $FF87B8DE
   #CSS_CadetBlue            = $FFA09E5F
   #CSS_Chartreuse           = $FF00FF7F
   #CSS_Chocolate            = $FF1E69D2
   #CSS_Coral                = $FF507FFF
   #CSS_CornflowerBlue       = $FFED9564
   #CSS_Cornsilk             = $FFDCF8FF
   #CSS_Crimson              = $FF3C14DC
   #CSS_Cyan                 = $FFFFFF00
   #CSS_DarkBlue             = $FF8B0000
   #CSS_DarkCyan             = $FF8B8B00
   #CSS_DarkGoldenRod        = $FF0B86B8
   #CSS_DarkGray             = $FFA9A9A9
   #CSS_DarkGreen            = $FF006400
   #CSS_DarkGrey             = $FFA9A9A9
   #CSS_DarkKhaki            = $FF6BB7BD
   #CSS_DarkMagenta          = $FF8B008B
   #CSS_DarkOliveGreen       = $FF2F6B55
   #CSS_DarkOrange           = $FF008CFF
   #CSS_DarkOrchid           = $FFCC3299
   #CSS_DarkRed              = $FF00008B
   #CSS_DarkSalmon           = $FF7A96E9
   #CSS_DarkSeaGreen         = $FF8FBC8F
   #CSS_DarkSlateBlue        = $FF8B3D48
   #CSS_DarkSlateGray        = $FF4F4F2F
   #CSS_DarkSlateGrey        = $FF4F4F2F
   #CSS_DarkTurquoise        = $FFD1CE00
   #CSS_DarkViolet           = $FFD30094
   #CSS_DeepPink             = $FF9314FF
   #CSS_DeepSkyBlue          = $FFFFBF00
   #CSS_DimGray              = $FF696969
   #CSS_DimGrey              = $FF696969
   #CSS_DodgerBlue           = $FFFF901E
   #CSS_FireBrick            = $FF2222B2
   #CSS_FloralWhite          = $FFF0FAFF
   #CSS_ForestGreen          = $FF228B22
   #CSS_Fuchsia              = $FFFF00FF
   #CSS_Gainsboro            = $FFDCDCDC
   #CSS_GhostWhite           = $FFFFF8F8
   #CSS_Gold                 = $FF00D7FF
   #CSS_GoldenRod            = $FF20A5DA
   #CSS_Gray                 = $FF808080
   #CSS_Green                = $FF008000
   #CSS_GreenYellow          = $FF2FFFAD
   #CSS_Grey                 = $FF808080
   #CSS_HoneyDew             = $FFF0FFF0
   #CSS_HotPink              = $FFB469FF
   #CSS_IndianRed            = $FF5C5CCD
   #CSS_Indigo               = $FF82004B
   #CSS_Ivory                = $FFF0FFFF
   #CSS_Khaki                = $FF8CE6F0
   #CSS_Lavender             = $FFFAE6E6
   #CSS_LavenderBlush        = $FFF5F0FF
   #CSS_LawnGreen            = $FF00FC7C
   #CSS_LemonChiffon         = $FFCDFAFF
   #CSS_LightBlue            = $FFE6D8AD
   #CSS_LightCoral           = $FF8080F0
   #CSS_LightCyan            = $FFFFFFE0
   #CSS_LightGoldenRodYellow = $FFD2FAFA
   #CSS_LightGray            = $FFD3D3D3
   #CSS_LightGreen           = $FF90EE90
   #CSS_LightGrey            = $FFD3D3D3
   #CSS_LightPink            = $FFC1B6FF
   #CSS_LightSalmon          = $FF7AA0FF
   #CSS_LightSeaGreen        = $FFAAB220
   #CSS_LightSkyBlue         = $FFFACE87
   #CSS_LightSlateGray       = $FF998877
   #CSS_LightSlateGrey       = $FF998877
   #CSS_LightSteelBlue       = $FFDEC4B0
   #CSS_LightYellow          = $FFE0FFFF
   #CSS_Lime                 = $FF00FF00
   #CSS_LimeGreen            = $FF32CD32
   #CSS_Linen                = $FFE6F0FA
   #CSS_Magenta              = $FFFF00FF
   #CSS_Maroon               = $FF000080
   #CSS_MediumAquaMarine     = $FFAACD66
   #CSS_MediumBlue           = $FFCD0000
   #CSS_MediumOrchid         = $FFD355BA
   #CSS_MediumPurple         = $FFDB7093
   #CSS_MediumSeaGreen       = $FF71B33C
   #CSS_MediumSlateBlue      = $FFEE687B
   #CSS_MediumSpringGreen    = $FF9AFA00
   #CSS_MediumTurquoise      = $FFCCD148
   #CSS_MediumVioletRed      = $FF8515C7
   #CSS_MidnightBlue         = $FF701919
   #CSS_MintCream            = $FFFAFFF5
   #CSS_MistyRose            = $FFE1E4FF
   #CSS_Moccasin             = $FFB5E4FF
   #CSS_NavajoWhite          = $FFADDEFF
   #CSS_Navy                 = $FF800000
   #CSS_OldLace              = $FFE6F5FD
   #CSS_Olive                = $FF008080
   #CSS_OliveDrab            = $FF238E6B
   #CSS_Orange               = $FF00A5FF
   #CSS_OrangeRed            = $FF0045FF
   #CSS_Orchid               = $FFD670DA
   #CSS_PaleGoldenRod        = $FFAAE8EE
   #CSS_PaleGreen            = $FF98FB98
   #CSS_PaleTurquoise        = $FFEEEEAF
   #CSS_PaleVioletRed        = $FF9370DB
   #CSS_PapayaWhip           = $FFD5EFFF
   #CSS_PeachPuff            = $FFB9DAFF
   #CSS_Peru                 = $FF3F85CD
   #CSS_Pink                 = $FFCBC0FF
   #CSS_Plum                 = $FFDDA0DD
   #CSS_PowderBlue           = $FFE6E0B0
   #CSS_Purple               = $FF800080
   #CSS_RebeccaPurple        = $FF993366
   #CSS_Red                  = $FF0000FF
   #CSS_RosyBrown            = $FF8F8FBC
   #CSS_RoyalBlue            = $FFE16941
   #CSS_SaddleBrown          = $FF13458B
   #CSS_Salmon               = $FF7280FA
   #CSS_SandyBrown           = $FF60A4F4
   #CSS_SeaGreen             = $FF578B2E
   #CSS_SeaShell             = $FFEEF5FF
   #CSS_Sienna               = $FF2D52A0
   #CSS_Silver               = $FFC0C0C0
   #CSS_SkyBlue              = $FFEBCE87
   #CSS_SlateBlue            = $FFCD5A6A
   #CSS_SlateGray            = $FF908070
   #CSS_SlateGrey            = $FF908070
   #CSS_Snow                 = $FFFAFAFF
   #CSS_SpringGreen          = $FF7FFF00
   #CSS_SteelBlue            = $FFB48246
   #CSS_Tan                  = $FF8CB4D2
   #CSS_Teal                 = $FF808000
   #CSS_Thistle              = $FFD8BFD8
   #CSS_Tomato               = $FF4763FF
   #CSS_Turquoise            = $FFD0E040
   #CSS_Violet               = $FFEE82EE
   #CSS_Wheat                = $FFB3DEF5
   #CSS_White                = $FFFFFFFF
   #CSS_WhiteSmoke           = $FFF5F5F5
   #CSS_Yellow               = $FF00FFFF
   #CSS_YellowGreen          = $FF32CD9A

   ; -- Other colors used in this module

   ; Some extended CSS3 colors
   #CSS3_Firebrick2     = $FF2C2CEE
   #CSS3_Firebrick3     = $FF2626CD
   #CSS3_Gray50         = $FF7F7F7F
   #CSS3_LightGoldenrod = $FF8BECFF
   #CSS3_Red2           = $FF0000EE
   #CSS3_Red3           = $FF0000CD
   #CSS3_Royalblue3     = $FFCD5F3A
   #CSS3_Royalblue4     = $FF8B4027
   #CSS3_Springgreen4   = $FF458B00

   ; Some Pantone color constants
   #Pantone_109C        = $FF00D1FE
   #Pantone_114C        = $FF42DEF9
   #Pantone_116C        = $FF00CBFE
   #Pantone_151C        = $FF0079FF
   #Pantone_17_5633     = $FF769500
   #Pantone_18_1660     = $FF3E2ACD
   #Pantone_18_1662     = $FF372BCE
   #Pantone_18_4148     = $FFA45D15
   #Pantone_18_4434     = $FF7B3E0B
   #Pantone_18_6320     = $FF4D6F43
   #Pantone_1805C       = $FF2F27AA
   #Pantone_186C        = $FF300CC6  ; (1) TODO: same hexadecimal value as (2) below ??
   #Pantone_19_3832     = $FF71403E
   #Pantone_280C        = $FF762700
   #Pantone_285C        = $FFCE7200
   #Pantone_286C        = $FFA63900
   #Pantone_2935C       = $FFBB5B00
   #Pantone_294C        = $FF783400
   #Pantone_299C        = $FFDEA100
   #Pantone_300C        = $FFBD6500
   #Pantone_3015C       = $FFA16600
   #Pantone_347C        = $FF489B00
   #Pantone_485C        = $FF1E2BD5
   #Pantone_661C        = $FF913500
   #Pantone_GreenC      = $FF83AD00
   #Pantone_Red_032_C   = $FF300CC6  ; (2) TODO: same hexadecimal value as (1) above ??
   #Pantone_ReflexBlue  = $FF993300
   #Pantone_ReflexBlueC = $FF952300
   #Pantone_Yellow      = $FF00CCFF
   #Pantone_YellowC     = $FF00DFFE

   #VI_FlagRed      = $FF1B15AA
   #VI_FlagYellow   = $FF00BFF1
   #VI_GrayBlue1    = $FFC8B8B0
   #VI_GrayBlue2    = $FFC0B0B0
   #VI_GuardsmanRed = $FF0000C0      ; <http://www.colorcombos.com/colors/C00000>, 2016-03-30
   #VI_WhiteBlue1   = $FFFFEEEE

   ;}

   ;--------[ Declarations of public procedures ]--------
   ;{

   ;- * * *  Icon set #1  * * *

   Declare.i Transparent (file$, img.i, size.i)
   Declare.i Add (file$, img.i, size.i, color.i)
   Declare.i Refresh (file$, img.i, size.i, color.i)
   Declare.i SelectAll (file$, img.i, size.i, color.i)
   Declare.i Checked (file$, img.i, size.i, color.i)
   Declare.i Sub (file$, img.i, size.i, color.i)
   Declare.i Delete (file$, img.i, size.i, color.i)
   Declare.i Find (file$, img.i, size.i, color.i, flipHorizontally.i=#False)
   Declare.i FindNext (file$, img.i, size.i, color1.i, color2.i, flipHorizontally.i=#False)
   Declare.i Question (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i FivePointedStar (file$, img.i, size.i, color.i)
   Declare.i Wizard (file$, img.i, size.i, color1.i, color2.i, flipHorizontally.i=#False)
   Declare.i Diskette (file$, img.i, size.i, color1.i, color2.i, color3.i=0)
   Declare.i Alarm (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i Quit (file$, img.i, size.i, color.i)
   Declare.i HotDrink (file$, img.i, size.i, color.i)
   Declare.i Watch (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Night (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i Arrow (file$, img.i, size.i, color.i, rotation.d=0.0)

   Declare.i ReSize (file$, img.i, size.i, color.i)
   Declare.i Stop (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i Warning (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i OnOff (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Info (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i Collapse (file$, img.i, size.i, color.i)
   Declare.i Expand (file$, img.i, size.i, color.i)
   Declare.i Success (file$, img.i, size.i, color.i)
   Declare.i Home (file$, img.i, size.i, color.i)
   Declare.i AlignLeft (file$, img.i, size.i, color.i)
   Declare.i AlignCentre (file$, img.i, size.i, color.i)
   Declare.i AlignRight (file$, img.i, size.i, color.i)
   Declare.i AlignJustify (file$, img.i, size.i, color.i)
   Declare.i Compile (file$, img.i, size.i, color.i)
   Declare.i CompileRun (file$, img.i, size.i, color.i)
   Declare.i Settings (file$, img.i, size.i, color.i)
   Declare.i Options (file$, img.i, size.i, color.i)
   Declare.i Toggle1 (file$, img.i, size.i, color1.i, color2.i=0, color3.i=0)
   Declare.i Toggle2 (file$, img.i, size.i, color1.i, color2.i=0, color3.i=0)
   Declare.i Save1 (file$, img.i, size.i, color.i)
   Declare.i ZoomIn (file$, img.i, size.i, color.i, flipHorizontally.i=#False)
   Declare.i ZoomOut (file$, img.i, size.i, color.i, flipHorizontally.i=#False)
   Declare.i Great (file$, img.i, size.i, color.i, flipHorizontally.i=#False)
   Declare.i DownLoad1 (file$, img.i, size.i, color1.i, color2.i)
   Declare.i UpLoad1 (file$, img.i, size.i, color1.i, color2.i)
   Declare.i LineWrapOn (file$, img.i, size.i, color1.i, color2.i)
   Declare.i LineWrapOff (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Donate1 (file$, img.i, size.i, color.i)
   Declare.i Donate2 (file$, img.i, size.i, color.i)
   Declare.i Filter (file$, img.i, size.i, color.i, fill.i=#True)
   Declare.i Bookmark (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Database (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Tools (file$, img.i, size.i, color.i)
   Declare.i Sort (file$, img.i, size.i, color.i)
   Declare.i Randomise (file$, img.i, size.i, color.i)
   Declare.i IsProtected (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i UnProtected1 (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i UnProtected2 (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Network (file$, img.i, size.i, color.i)
   Declare.i Music (file$, img.i, size.i, color.i)
   Declare.i Microphone (file$, img.i, size.i, color.i)
   Declare.i Picture (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i)
   Declare.i Bug (file$, img.i, size.i, color1.i, color2.i)
   Declare.i DBug (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Crop (file$, img.i, size.i, color1.i)
   Declare.i ReSize2 (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Rating (file$, img.i, size.i, color1.i, color2.i)
   Declare.i CitrusFruits (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Action (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Move (file$, img.i, size.i, color.i)
   Declare.i Lock (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Unlock (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Fill (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Message (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Colours (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i)
   Declare.i Navigation1 (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Navigation2 (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Volume (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Secure (file$, img.i, size.i, color.i)
   Declare.i Book (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Library (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
   Declare.i USB (file$, img.i, size.i, color.i)

   Declare.i Chess_WhitePawn (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Chess_BlackPawn (file$, img.i, size.i, color.i)
   Declare.i Chess_WhiteRook (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Chess_BlackRook (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Chess_WhiteKnight (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Chess_BlackKnight (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Chess_WhiteBishop (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Chess_BlackBishop (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Chess_WhiteKing (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Chess_BlackKing (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Chess_WhiteQueen (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Chess_BlackQueen (file$, img.i, size.i, color1.i, color2.i)

   Declare.i History (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
   Declare.i Danger (file$, img.i, size.i, color1.i, color2.i)
   Declare.i TheSun (file$, img.i, size.i, color.i, color2.i)
   Declare.i GoodLuck (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Telephone (file$, img.i, size.i, color1.i, color2.i)
   Declare.i BlueTooth (file$, img.i, size.i, color.i)
   Declare.i Broadcast (file$, img.i, size.i, color.i)
   Declare.i Speaker (file$, img.i, size.i, color.i)
   Declare.i Mute (file$, img.i, size.i, color1.i, color2.i)
   Declare.i BatteryCharging (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Snowflake (file$, img.i, size.i, color.i)
   Declare.i A2M (file$, img.i, size.i, color.i)
   Declare.i N2Z (file$, img.i, size.i, color.i)
   Declare.i RainCloud (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i CloudStorage (file$, img.i, size.i, color1.i, color2.i=0)

   Declare.i MediaPlay (file$, img.i, size.i, color.i)
   Declare.i MediaStop (file$, img.i, size.i, color.i)
   Declare.i MediaBegin (file$, img.i, size.i, color.i)
   Declare.i MediaEnd (file$, img.i, size.i, color.i)
   Declare.i MediaForward (file$, img.i, size.i, color.i)
   Declare.i MediaFastForward (file$, img.i, size.i, color.i)
   Declare.i MediaBack (file$, img.i, size.i, color.i)
   Declare.i MediaFastBack (file$, img.i, size.i, color.i)

   Declare.i FirstAid (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i NoEntry (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i Stop3 (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i Download2 (file$, img.i, size.i, color.i, color2.i=0)
   Declare.i FirstAid_Spatial (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i NoEntry_Spatial (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i Stop3_Spatial (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i Download2_Spatial (file$, img.i, size.i, color.i, color2.i=0)
   Declare.i ToClipboard (file$, img.i, size.i, color1.i, color2.i)
   Declare.i FromClipboard (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Copy (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Paste (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Cut (file$, img.i, size.i, color.i)
   Declare.i Undo (file$, img.i, size.i, color.i, flipVertically.i=#False)
   Declare.i Redo (file$, img.i, size.i, color.i)
   Declare.i Open1 (file$, img.i, size.i, color.i)
   Declare.i Open2 (file$, img.i, size.i, color.i, color2.i, color3.i)
   Declare.i Open3 (file$, img.i, size.i, color.i, color2.i=0)
   Declare.i Save2 (file$, img.i, size.i, color.i, color2.i=0)
   Declare.i SaveAs2 (file$, img.i, size.i, color.i, color2.i=0)
   Declare.i Printer1 (file$, img.i, size.i, color1.i, color2.i)
   Declare.i PrinterError1 (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i NewDocument (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i EditDocument (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i ClearDocument (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i ImportDocument (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i ExportDocument (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i CloseDocument (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
   Declare.i SortAscending (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i SortDescending (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i SortBlockAscending (file$, img.i, size.i, color1.i, color2.i)
   Declare.i SortBlockDescending (file$, img.i, size.i, color1.i, color2.i)
   Declare.i ChartLine (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
   Declare.i ChartDot (file$, img.i, size.i, color1.i, color2.i, color3.i=0)
   Declare.i ChartLineDot (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
   Declare.i ChartPrice (file$, img.i, size.i, color1.i, color2.i, color3.i=0)
   Declare.i ChartBarVert (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
   Declare.i ChartCylVert (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
   Declare.i ChartBarHor (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
   Declare.i ChartCylHor (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
   Declare.i ChartBarVertStacked (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
   Declare.i ChartBarHorStacked (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
   Declare.i ChartCylVertStacked (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
   Declare.i ChartCylHorStacked (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
   Declare.i ChartArea (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
   Declare.i ChartAreaPerc (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
   Declare.i ChartPie (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
   Declare.i ChartRing (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
   Declare.i Notes (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i)
   Declare.i Notes_Spatial (file$, img.i, size.i, color1.i, color2.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i)

   Declare.i UnFold (file$, img.i, size.i, color1.i, color2.i, rotation.d=0, spatial.i=0)
   Declare.i Fold (file$, img.i, size.i, color1.i, color2.i, rotation.d=0, spatial.i=0)

   Declare.i ArrowBowLeft (file$, img.i, size.i, color.i, rotation.d=0)
   Declare.i ArrowBowRight (file$, img.i, size.i, color.i, rotation.d=0)

   Declare.i BracketRound (file$, img.i, size.i, color1.i, Open=#False)
   Declare.i BracketSquare (file$, img.i, size.i, color1.i, Open=#False)
   Declare.i BracketAngle (file$, img.i, size.i, color1.i, Open=#False)
   Declare.i BracketCurly (file$, img.i, size.i, color1.i, Open=#False)
   Declare.i BracketHtml (file$, img.i, size.i, color1.i, Open=#False)

   Declare.i Compare (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Site (file$, img.i, size.i, color1.i, color2.i)

   Declare.i Attach(file$, img.i, size.i, color1.i)
   Declare.i Mail_Symbol(file$, img.i, size.i, color1.i)
   Declare.i Currency_Symbol(file$, img.i, size.i, color1.i, char.s)


   ;- * * *  Icon set #2  * * *

   Declare.i FindAndReplace(file$, img.i, size.i, color1.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i)
   Declare.i Open1_Spatial (file$, img.i, size.i, color.i, color2.i)
   Declare.i Open2_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
   Declare.i Open3_Spatial (file$, img.i, size.i, color.i, color2.i)
   Declare.i FindFile_Spatial(file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i FindFile(file$, img.i, size.i, color1.i, color2.i)

   Declare.i RotateDown_Spatial(file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
   Declare.i RotateUp_Spatial(file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
   Declare.i RotateVert_Spatial(file$, img.i, size.i, color1.i, color2.i, color3.i=0)
   Declare.i RotateLeft_Spatial(file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
   Declare.i RotateRight_Spatial(file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
   Declare.i RotateHor_Spatial(file$, img.i, size.i, color1.i, color2.i, color3.i=0)
   Declare.i RotateCcw_Spatial(file$, img.i, size.i, color1.i, color2.i, color3.i=0)
   Declare.i RotateCw_Spatial(file$, img.i, size.i, color1.i, color2.i, color3.i=0)

   Declare.i Writingpad (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i, color7.i, color8.i)
   Declare.i Writingpad_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i, color7.i, color8.i)
   Declare.i Calculate_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
   Declare.i Calendar_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i)

   Declare.i Ruler_Spatial (file$, img.i, size.i, color1.i, color2.i)
   Declare.i RulerTriangle_Spatial (file$, img.i, size.i, color1.i, color2.i)

   Declare.i Carton_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i=0, text1.s="", tsize.d=0.5)
   Declare.i BookKeeping_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i)
   Declare.i Pen_Spatial (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i)
   Declare.i Pen_Flat (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i)
   Declare.i Brush_Spatial (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i)
   Declare.i Brush_Flat (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i)
   Declare.i Pipette_Spatial (file$, img.i, size.i, colorM1.i, colorM2.i)
   Declare.i Pipette_Flat (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i)
   Declare.i Fill_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Fill_Flat (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Spray_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
   Declare.i Spray_Flat (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
   Declare.i Eraser_Spatial (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Eraser_Flat (file$, img.i, size.i, color1.i, color2.i)
   Declare.i ColorPalette_Spatial (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i, colorM6.i, colorM7.i)
   Declare.i ColorPalette_Flat (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i, colorM6.i, colorM7.i)
   Declare.i Paint_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i, color7.i)
   Declare.i Paint_Flat (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i, color7.i)

   Declare.i DrawVText (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i DrawVLine (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i DrawVBox (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i DrawVRoundedBox (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i DrawVPolygonBox (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i DrawVCircle (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i DrawVCircleSegment (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i DrawVEllipse (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i DrawVEllipseSegment (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i DrawVCurve (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i DrawVArc (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i DrawVLinePath (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)

   Declare.i SetVSelectionRange (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVLineStyle (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVLineWidth (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVLineCap (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVLineJoin (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVColorSelect (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0, color5.i=0)
   Declare.i SetVColorBoardSelect (file$, img.i, size.i, color1.i, color2.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i, colorM6.i, colorM7.i)
   Declare.i SetVFlipX (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVFlipY (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVRotate (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVMove (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVCopy (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVScale (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVTrimSegment (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVExtendSegment (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVCatchGrid (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
   Declare.i SetVLinearGradient (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i SetVCircularGradient (file$, img.i, size.i, color1.i, color2.i=0)
   Declare.i SetVChangeCoord (file$, img.i, size.i, color1.i, color2.i, colorM1.i, colorM2.i, color3.i=0, color4.i=0)
   Declare.i SetVDelete (file$, img.i, size.i, color1.i, color2.i, colorM1.i, colorM2.i, color3.i=0, color4.i=0)
   Declare.i SetVFill (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0, color6.i=0)
   Declare.i SetVLayer (file$, img.i, size.i, color1.i, color2.i, color3.i, color5.i=0, color6.i=0)

   Declare.i ToClipboard_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
   Declare.i FromClipboard_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
   Declare.i Copy_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Paste_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i)

   Declare.i Cut_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i)
   Declare.i Find_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, flipHorizontally.i=#False)
   Declare.i FindNext_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, flipHorizontally.i=#False)
   Declare.i ZoomIn_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, flipHorizontally.i=#False)
   Declare.i ZoomOut_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, flipHorizontally.i=#False)
   Declare.i FindAndReplace_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i, flipHorizontally.i=#False)

   Declare.i NewDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
   Declare.i EditDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, colorM1.i, colorM2.i, colorM3.i,
                                   colorM4.i, colorM5.i, dogEar.i=#False)
   Declare.i ClearDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
   Declare.i ImportDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
   Declare.i ExportDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
   Declare.i SaveDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
   Declare.i CloseDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
   Declare.i SortAscending_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, dogEar.i=#False)
   Declare.i SortDescending_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, dogEar.i=#False)
   Declare.i SortBlockAscending_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, dogEar.i=#False)
   Declare.i SortBlockDescending_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, dogEar.i=#False)

   Declare.i Compare_Spatial (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Site_Spatial(file$, img.i, size.i, color1.i, color2.i)


   ;- * * *  Icon set #3 (Flags)  * * *

   Declare.i Flag_Australia (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Austria (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Flag_Bangladesh (file$, img.i, size.i, color1.i=$FF412AF4, color2.i=$FF4E6A00)
   Declare.i Flag_Belgium (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Brazil (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Bulgaria (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Canada (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Flag_China (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Flag_Czech (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Denmark (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Flag_Estonia (file$, img.i, size.i, color1.i=#Pantone_285C, color2.i=#CSS_Black, color3.i=#CSS_White)
   Declare.i Flag_Europe (file$, img.i, size.i, color1.i=#Pantone_Yellow, color2.i=#Pantone_ReflexBlue)
   Declare.i Flag_Finland (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Flag_France (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Germany (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_GreatBritain (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Greece (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Flag_Hungary (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Ireland (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Island (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Italy (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Japan (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Flag_KoreaSouth (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
   Declare.i Flag_Luxembourg (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Netherlands (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_NewZealand (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Norway (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Poland (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Flag_Romania (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Russia (file$, img.i, size.i, color1.i, color2.i, color3.i)
   Declare.i Flag_Spain (file$, img.i, size.i, color1.i=#VI_FlagYellow, color2.i=#VI_FlagRed)
   Declare.i Flag_Sweden (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Flag_Switzerland (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Flag_Ukraine (file$, img.i, size.i, color1.i, color2.i)
   Declare.i Flag_USA (file$, img.i, size.i, color1.i, color2.i, color3.i)

   ;}
EndDeclareModule


Module VectorIcons
   EnableExplicit
   UseModule VDraw


   ;--------[ Private constants ]--------

   #Background = #PB_Image_Transparent
   ; #Background = $00FFFF              ; Use this (yellow) or any other RGB color for debugging,
                                        ; so that you can see the borders of your icon.


   ;--------[ Auxiliary procedures ]--------

   Procedure.i StartVectorIconOutput (file$, img.i, size.i)
      Protected ret.i

      CompilerIf #PB_Compiler_OS = #PB_OS_Linux
         If file$ = ""
            ret = StartNewVectorImage(img, size, size, 32, #Background)
         Else
            ret = StartVectorDrawing(SvgVectorOutput(file$, size, size))
         EndIf

      CompilerElse
         ret = StartNewVectorImage(img, size, size, 32, #Background)
      CompilerEndIf

      ProcedureReturn ret
   EndProcedure


   ;--------[ Private macros/procedures of basic movable and resizable shapes that can be used by any icon procedure ]--------

   Macro DrawPlus (_x_, _y_, _half_, _w_)
      ; _x_, _y_: coordinates of the center of the plus sign
      ; _half_  : half of size (width and height) of the plus sign
      ; _w_     : width of the line used for drawing the plus sign
      ; [by Little John]

      MovePathCursor(_x_-_half_, _y_)
      AddPathLine   (_x_+_half_, _y_)
      MovePathCursor(_x_, _y_-_half_)
      AddPathLine   (_x_, _y_+_half_)
      StrokePath(_w_)
   EndMacro


   Macro DrawMinus (_x_, _y_, _half_, _w_)
      ; _x_, _y_: coordinates of the center of the minus sign
      ; _half_  : half of width of the minus sign
      ; _w_     : width of the line used for drawing the minus sign
      ; [by Little John]

      MovePathCursor(_x_-_half_, _y_)
      AddPathLine   (_x_+_half_, _y_)
      StrokePath(_w_)
   EndMacro


   Macro DrawTick (_x_, _y_, _half_, _hw_)
      ; _x_, _y_: Coordinates of the centre of box containing the tick
      ; _half_  : Half of size (width and height) of containing box
      ; _hw_    : Half of width of the line used for drawing the tick
      ; [by Little John]

      MovePathCursor(_x_-_half_+_hw_, _y_)
      AddPathLine   (_x_            , _y_+_half_-2*_hw_)
      AddPathLine   (_x_+_half_-_hw_, _y_-_half_+_hw_)
      StrokePath(2*_hw_)
   EndMacro


   Macro DrawMagnifyingGlass (_x_, _y_, _size_, _reflection_=#False)
      ; _x_, _y_    : coordinates of the upper left corner
      ; _size_      : width and height
      ; _reflection_: #True / #False
      ; [by Little John]

      MovePathCursor(_x_+0.39*_size_, _y_+0.61*_size_)
      AddPathLine   (_x_+0.08*_size_, _y_+0.92*_size_)
      StrokePath(0.12857 * _size_)

      AddPathCircle(_x_+0.65*_size_, _y_+0.35*_size_, 0.29*_size_)
      StrokePath(0.07 * _size_)

      If _reflection_
         AddPathCircle(_x_+0.65*_size_, _y_+0.35*_size_, 0.17*_size_, -90.0, 0.0)
         StrokePath(0.057 * _size_)
      EndIf
   EndMacro


   Macro DrawStar (_x_, _y_, _rc_, _points_=5, _rotation_=0.0, _q_=0.38)
      ; _x_, _y_  : coordinates of the center
      ; _rc_      : radius of circumscribed circle
      ; _points_  : number of points
      ; _rotation_: rotation angle of the star (in degrees)
      ; _q_       : (radius of inscribed circle) / _rc_
      ; [by Little John]

      SaveVectorState()
      RotateCoordinates(_x_, _y_, _rotation_)
      MovePathCursor(_x_, _y_-_rc_)
      For k = 1 To 2*(_points_)-1
         RotateCoordinates(_x_, _y_, 180.0/(_points_))
         If k & 1 = 1
            AddPathLine(_x_, _y_-(_q_)*(_rc_))
         Else
            AddPathLine(_x_, _y_-_rc_)
         EndIf
      Next
      ClosePath()
      RestoreVectorState()
   EndMacro


   Macro DrawMoon (_x_, _y_, _size_, _rotation_=-30)
      ; _x_, _y_  : coordinates of the center of the outer circle
      ; _size_    : diameter of the circles
      ; _rotation_: rotation angle of the moon (in degrees)
      ; [by Little John]

      SaveVectorState()
      RotateCoordinates(_x_, _y_, _rotation_)
      AddPathCircle(_x_, _y_, _size_/2, 287, 73, #PB_Path_CounterClockwise)
      AddPathCircle(_x_+0.3*_size_, _y_, _size_/2, 108, 252, #PB_Path_Connected)
      RestoreVectorState()
      FillPath()
   EndMacro


   Macro DrawPen (_x_, _y_, _size_, _color1_, _color2_)
      ; _x_, _y_: coordinates of the tip of the pen
      ; _size_  : width and height
      ; [original code by Oma, transmogrified into a macro by Little John]

      VectorSourceColor(_color1_)

      MovePathCursor(_x_ +  4/64*_size_, _y_ - 10/64*_size_)
      AddPathLine   (_x_ +  1/64*_size_, _y_ -  1/64*_size_)
      AddPathLine   (_x_ + 10/64*_size_, _y_ -  4/64*_size_)
      ClosePath()
      FillPath()

      MovePathCursor(_x_ + 43/64*_size_, _y_ - 43/64*_size_)
      AddPathLine   (_x_ + 10/64*_size_, _y_ - 10/64*_size_)
      StrokePath    (12/64*_size_)

      VectorSourceColor(_color2_)
      MovePathCursor(_x_ + 46/64*_size_, _y_ - 46/64*_size_)
      AddPathLine   (_x_ + 43/64*_size_, _y_ - 43/64*_size_)
      StrokePath    (12/64*_size_)

      VectorSourceColor(_color1_)
      MovePathCursor(_x_ + 58/64*_size_, _y_ - 58/64*_size_)
      AddPathLine   (_x_ + 46/64*_size_, _y_ - 46/64*_size_)
      StrokePath    (12/64*_size_)
   EndMacro


   Macro DrawRoundBox (_x_, _y_, _width_, _height_, _radius_)
      ; _x_, _y_         : coordinates of the upper left corner
      ; _width_, _height_: size of the box
      ; _radius_         : radius of the rounded corners
      ; [original by diskay - modified as Macro by davido
      ;  http://www.purebasic.fr/english/viewtopic.php?p=473535#p473535]

      MovePathCursor(_x_ + _width_, _y_ + 0.5* _height_)
      AddPathArc(_x_ + _width_, _y_ + _height_, _x_, _y_ + _height_, _radius_)
      AddPathArc(_x_, _y_ + _height_, _x_, _y_, _radius_)
      AddPathArc(_x_, _y_, _x_ + _width_, _y_, _radius_)
      AddPathArc(_x_ + _width_, _y_, _x_ + _width_, _y_ + _height_, _radius_)
      ClosePath()
   EndMacro


   Macro DrawFlash (_x_, _y_, _size_)
      ; [by davido]
      MovePathCursor(_x_ + 0.09375*_size_, _y_-0.4375*_size_)
      AddPathLine(_x_-0.21875*_size_, _y_ +0.0625*_size_)
      AddPathLine(_x_-0.0625*_size_, _y_+0.0625*_size_)
      AddPathLine(_x_-0.0625*_size_, _y_+0.4375*_size_)
      AddPathLine(_x_+0.25*_size_, _y_-0.0625*_size_)
      AddPathLine(_x_ + 0.09375*_size_, _y_-0.0625*_size_)
      ClosePath()
      FillPath()
   EndMacro


   Macro DrawCloud (_x_, _y_, _size_, _outline_=#False)
      ; [by davido]
      MovePathCursor(_x_ + 0.375 * _size_, _y_ + 0.375 * _size_)
      AddPathLine(_x_ - 0.375 * _size_, _y_ + 0.375 * _size_)
      AddPathCircle(_x_ - 0.21825 * _size_, _y_ + 0.21825 * _size_, 0.221875 * _size_, 138, 225.25)
      AddPathCircle(_x_ - 0.15625 * _size_, _y_, 0.21875 * _size_, 166, 270, #PB_Path_Connected)
      AddPathCircle(_x_ + 0.03125 * _size_, _y_ - 0.125 * _size_, 0.20625 * _size_, 207, 15, #PB_Path_Connected)
      AddPathCircle(_x_ + 0.1875 * _size_, _y_ + 0.1953125 * _size_, 0.2625 * _size_, 280, 42, #PB_Path_Connected)
      ClosePath()
      If _outline_ = #False
         FillPath(#PB_Path_Preserve)
      EndIf
      StrokePath(p, #PB_Path_RoundEnd)
   EndMacro


   Macro DrawBalloon (_x_, _y_, _size_, _rotation_=0)
      ; [by davido]
      SaveVectorState()
      RotateCoordinates(size * 0.5, size * 0.5, _rotation_)
      MovePathCursor(_x_, _y_ + _size_ * 0.4375)
      AddPathCurve(_x_ - _size_ * 1.125, _y_ - _size_ *0.71875, _x_ + _size_ * 1.125, _y_ - _size_ *0.71875, _x_, _y_ + _size_ * 0.4375)
      StrokePath(_size_ / 32, #PB_Path_RoundEnd | #PB_Path_RoundCorner | #PB_Path_Preserve)
      FillPath()
      RestoreVectorState()
   EndMacro


   ;--------[ Icons ]--------

   ;- * * *  Icon set #1  * * *

   Procedure.i Transparent (file$, img.i, size.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John, after an idea by Blue]
      Protected ret.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Add (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, w.i, half.d

      w = Int(size / 3.0) - (size % 3)
      half = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         DrawPlus(half, half, half, w)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Macro RefreshArrow()
      MovePathCursor(hw, half-hw)
      AddPathCurve(third, hw, size-third, hw, size-1.75*hw, half-2.0*hw)
      StrokePath(2.0 * hw)

      MovePathCursor(         size, half-hw)
      AddPathLine   (size-hw-third, half-0.5*hw)
      AddPathLine   (  size-1.5*hw, 0)
      ClosePath()
      FillPath()
   EndMacro

   Procedure.i Refresh (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, hw.d, half.d, third.d

      hw = size / 12.0
      half = size / 2.0
      third = size / 3.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         RefreshArrow()      ; upper arrow
         RotateCoordinates(half, half, 180.0)
         RefreshArrow()      ; lower arrow
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SelectAll (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, hw.d
      Protected Dim dash.d(1)

      hw = size / 16.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor(      0, hw)      : AddPathLine(size, hw)
         MovePathCursor(size-hw, 0)       : AddPathLine(size-hw, size)
         MovePathCursor(      0, size-hw) : AddPathLine(size, size-hw)
         MovePathCursor(     hw, 0)       : AddPathLine(hw, size)
         dash(1) = size / 11.0
         dash(0) = 2.0 * dash(1)
         CustomDashPath(2.0 * hw, dash())

         AddPathBox(5.0*hw, 5.0*hw, 6.0*hw, 6.0*hw)
         StrokePath(2.0 * hw)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Checked (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, hw.d, half.d

      hw = size / 10.0
      half = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         DrawTick(half, half, half, hw)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Sub (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [simplified after Starbootics]
      Protected ret.i, w.i, half.d

      w = Int(size / 3.0) - (size % 3)
      half = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         DrawMinus(half, half, half, w)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Delete (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, hw.d, d.d

      hw = size / 14.0
      d = size / 10.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         MovePathCursor(     hw, hw+d)
         AddPathLine   (size-hw, size-hw)
         AddPathLine   (   hw+d, hw)
         ClosePath()

         MovePathCursor(3.0*hw  , size-hw-d)
         AddPathLine   ( size-hw, 3.0*hw)
         AddPathLine   (3.0*hw+d, size-hw)
         ClosePath()

         VectorSourceColor(color)
         StrokePath(2.0 * hw, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Find (file$, img.i, size.i, color.i, flipHorizontally.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img             : number of the image which is to be created, or #PB_Any
      ;      size            : width and height (number of pixels)
      ;      color           : foreground color
      ;      flipHorizontally: #True / #False
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If flipHorizontally
            FlipCoordinatesX(size/2)
         EndIf

         VectorSourceColor(color)
         DrawMagnifyingGlass(0, 0, size, #True)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i FindNext (file$, img.i, size.i, color1.i, color2.i, flipHorizontally.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img             : number of the image which is to be created, or #PB_Any
      ;      size            : width and height (number of pixels)
      ;      color1          : foreground color #1
      ;      color2          : foreground color #2
      ;      flipHorizontally: #True / #False
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, fx1.d, fx2.d, fy.d

      fx1 = 0.60
      fx2 = 0.82
      fy  = 0.83

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If flipHorizontally
            FlipCoordinatesX(size/2)
         EndIf

         VectorSourceColor(color1)
         DrawMagnifyingGlass(0, 0, size, #True)

         ; Arrow
         VectorSourceColor(color2)

         MovePathCursor( fx1      *size, fy*size)
         AddPathLine   ((fx2+0.01)*size, fy*size)
         StrokePath(0.085 * size)

         MovePathCursor( fx2      *size, (fy-0.14)*size)
         AddPathLine   ((fx2+0.15)*size,  fy      *size)
         AddPathLine   ( fx2      *size, (fy+0.14)*size)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Question (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, half.d, w.d

      half = size / 2.0
      w = size / 6.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; If Alpha(color2) = 0, then this part is invisible.
         VectorSourceColor(color2)
         AddPathCircle(half, half, half)
         FillPath()

         VectorSourceColor(color1)

         AddPathCircle(half, 0.66*half, 0.4*half, 180.0, 10.0)
         StrokePath(w)

         MovePathCursor(1.4*half, 0.66*half)
         AddPathCurve(1.4*half, half, 0.96*half, 0.9*half, half, 1.33*half)
         StrokePath(w)

         AddPathCircle(half, 1.64*half, 0.2*half)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i FivePointedStar (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, k.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         DrawStar(0.5*size, 0.53*size, 0.5*size)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Wizard (file$, img.i, size.i, color1.i, color2.i, flipHorizontally.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img             : number of the image which is to be created, or #PB_Any
      ;      size            : width and height (number of pixels)
      ;      color1          : foreground color #1
      ;      color2          : foreground color #2
      ;      flipHorizontally: #True / #False
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, k.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If flipHorizontally
            FlipCoordinatesX(size/2)
         EndIf

         VectorSourceColor(color1)
         MovePathCursor(0.56*size, 0.44*size)
         AddPathLine   (0.08*size, 0.92*size)
         StrokePath(0.1*size)

         VectorSourceColor(color2)
         DrawStar(0.65*size, 0.35*size, 0.35*size, 5, 45.0)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Diskette (file$, img.i, size.i, color1.i, color2.i, color3.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, d.d, r.d

      d = 0.22 * size
      r = 0.03 * size

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Slider
         VectorSourceColor(color3)
         AddPathBox(0.25*size, 0, 0.52*size, 0.33*size)
         FillPath()

         VectorSourceColor(color1)

         ; Hole in the slider
         AddPathBox(0.55*size, 0.04*size, 0.12*size, 0.24*size)

         ; Jacket
         MovePathCursor(0.25*size,    0)
         AddPathArc    (0        ,    0     ,    0, size     , r)   ; upper left corner
         AddPathArc    (0        , size     , size, size     , r)   ; lower left corner
         AddPathArc    (size     , size     , size, 0.07*size, r)   ; lower right corner
         AddPathLine   (size     , 0.07*size)
         AddPathLine   (0.93*size, 0)
         AddPathLine   (0.77*size, 0)
         AddPathLine   (0.77*size, 0.33*size)
         AddPathLine   (0.25*size, 0.33*size)
         ClosePath()

         ; Label
         If color3 <> 0
            FillPath()
            VectorSourceColor(color3)
         EndIf
         AddPathBox(0.14*size, 0.40*size, 0.73*size, 0.50*size)
         FillPath()

         ; Lines on the label
         VectorSourceColor(color2)
         MovePathCursor(     d, 0.52*size)
         AddPathLine   (size-d, 0.52*size)
         MovePathCursor(     d, 0.65*size)
         AddPathLine   (size-d, 0.65*size)
         MovePathCursor(     d, 0.78*size)
         AddPathLine   (size-d, 0.78*size)

         StrokePath(size / 64)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Macro HalfBell()
      ; Body
      MovePathCursor(half      , 0.24*size)
      AddPathLine   (0.475*size, 0.24*size)
      AddPathLine   (0.48 *size, 0.27*size)
      AddPathCurve  (0.33 *size, 0.27*size, 0.40*size, 0.54*size, 0.31*size, 0.57*size)
      AddPathLine   (half      , 0.57*size)

      ; Clapper
      AddPathCircle(half, 0.585*size, 0.05*size, 90, 180)
      AddPathLine  (half, 0.585*size)

      FillPath()

      ; Sound waves
      AddPathCircle(half, half, 0.265*size, 130, 230)
      AddPathCircle(half, half, 0.365*size, 130, 230)
      StrokePath(0.05*size)
   EndMacro

   Procedure.i Alarm (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, half.d

      half = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color2)
         AddPathCircle(half, half, half)
         FillPath()

         VectorSourceColor(color1)
         HalfBell()
         FlipCoordinatesX(half)
         HalfBell()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Quit (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, half.d, hw.d

      half = size / 2.0
      hw = size / 12.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         AddPathCircle(half, half, half-hw, -50.0, 230.0)
         StrokePath(2.0*hw)

         MovePathCursor(half, 0)
         AddPathLine(half, half)
         StrokePath(2*hw)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Macro VerticalWavyLine (_x_, _y_)
      MovePathCursor(_x_*size, _y_*size)
      AddPathCurve((_x_+0.17)*size, (_y_+0.14)*size, (_x_-0.13)*size, (_y_+0.16)*size, (_x_+0.03)*size, (_y_+0.29)*size)
   EndMacro

   Procedure.i HotDrink (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         ; steam
         VerticalWavyLine(0.350, 0)
         VerticalWavyLine(0.495, 0)
         VerticalWavyLine(0.637, 0)
         StrokePath(0.035*size)

         ; cup
         MovePathCursor(0.16*size, 0.35*size)
         AddPathCurve  (0.18*size, 0.52*size, 0.18*size, 0.72*size, 0.28*size, 0.86*size)
         AddPathLine   (0.71*size, 0.86*size)
         AddPathCurve  (0.82*size, 0.72*size, 0.82*size, 0.52*size, 0.84*size, 0.35*size)
         ClosePath()
         FillPath()

         ; handle
         AddPathCircle(0.81*size, 0.55*size, 0.15*size, -82.0, 100.0)
         StrokePath(0.08*size)

         ; saucer
         MovePathCursor(0,         0.89*size)
         AddPathCurve  (0.03*size, 0.95*size, 0.09*size, 0.97*size, 0.15*size, size)
         AddPathLine   (0.85*size, size)
         AddPathCurve  (0.91*size, 0.97*size, 0.97*size, 0.95*size, size, 0.89*size)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Watch (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sclera
         AddPathCircle(0.5*size, 0.22*size, 0.54*size,   30.2, 148.7)
         AddPathCircle(0.5*size, 0.78*size, 0.54*size, -148.7, -30.2, #PB_Path_Connected)
         VectorSourceColor(color3)
         FillPath()

         ; iris
         AddPathCircle(0.5*size, 0.5*size, 0.27*size)
         VectorSourceColor(color1)
         FillPath()

         ; pupil
         AddPathCircle(0.5*size, 0.5*size, 0.125*size)
         VectorSourceColor(color2)
         FillPath()

         ; reflection
         VectorSourceColor(color3)
         AddPathCircle(0.55*size, 0.45*size, 0.05*size)
         FillPath()

         ; eyelids
         AddPathCircle(0.5*size, 0.22*size, 0.54*size,   30.2, 148.7)
         AddPathCircle(0.5*size, 0.78*size, 0.54*size, -148.7, -30.2, #PB_Path_Connected)
         VectorSourceColor(color2)
         StrokePath(0.04*size)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Night (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John]
      Protected ret.i, k.i, half.d

      half = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color2)
         AddPathBox(0, 0, size, size)
         FillPath()

         VectorSourceColor(color1)
         DrawMoon(half, half, 0.95*size)

         DrawStar(0.6*size, 0.2*size, 0.15*size, 4)
         DrawStar(0.8*size, 0.4*size, 0.10*size, 4)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Arrow (file$, img.i, size.i, color.i, rotation.d=0.0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img     : number of the image which is to be created, or #PB_Any
      ;      size    : width and height (number of pixels)
      ;      color   : foreground color
      ;      rotation: angle (in degrees)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [modified after Starbootics]
      Protected ret.i, w.i, half.d, x1.d, x2.d, y.d

      w = Int(size / 3.0) - (size % 3)
      half = size / 2.0
      x1 = 0.1   * size
      x2 = 0.9   * size
      y  = 0.875 * half

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         RotateCoordinates(half, half, rotation)
         VectorSourceColor(color)

         MovePathCursor(half, 0)
         AddPathLine   (x1,   y)
         AddPathLine   (x2,   y)
         ClosePath()
         FillPath()

         MovePathCursor(half, y)
         AddPathLine   (half, size)
         StrokePath(w)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ReSize (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, hw.d

      hw = size / 16.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         AddPathBox(hw, hw, size - 2 * hw, size - 2 * hw)
         DashPath(1, 3)
         AddPathBox(hw, size - 7 * hw, 6 * hw, 6 * hw)

         MovePathCursor(size - 7 * hw, 4 * hw)
         AddPathLine(size - hw, hw)
         AddPathLine(size - 4 * hw, 6.5 * hw)
         FillPath()

         MovePathCursor(3 * hw, size - 3 * hw)
         AddPathLine(size - 3 * hw, 3 * hw)
         StrokePath(hw/2)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Stop (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [extended after davido]
      Protected ret.i, hw.d

      hw = size / 12.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; If Alpha(color2) = 0, then this part is invisible.
         VectorSourceColor(color2)
         AddPathCircle(size/2, size/2, size/2.4)
         FillPath()

         VectorSourceColor(color1)

         AddPathCircle(size/2, size/2, size/2.4)
         StrokePath(2*hw)

         MovePathCursor(size - 3*hw, 3*hw)
         AddPathLine(3*hw, size - 3*hw)
         StrokePath(2*hw)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Warning (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [extended after davido]
      Protected ret.i, hw.d, p.d

      hw = size / 12.0
      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; If Alpha(color2) = 0, then this part is invisible.
         VectorSourceColor(color2)
         MovePathCursor(hw, size-hw)
         AddPathLine(size/2, hw)
         AddPathLine(size-hw, size-hw)
         ClosePath()
         FillPath()

         VectorSourceColor(color1)

         MovePathCursor(hw, size-hw)
         AddPathLine(size/2, hw)
         AddPathLine(size-hw, size-hw)
         ClosePath()
         StrokePath(hw, #PB_Path_RoundCorner)

         MovePathCursor(14 * p, 13 * p)
         AddPathLine(16 * p, 23 * p)
         AddPathLine(18 * p, 13 * p)
         ClosePath()
         FillPath()
         AddPathCircle(16 * p, 13 * p, 2 * p)

         AddPathCircle(16 * p, 25 * p, 1.5 * p)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i OnOff (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [slightly modified after davido]
      Protected ret.i, p.d

      p = size / 32.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color2)
         AddPathCircle(size/2, size/2, size/2.4)
         FillPath()

         VectorSourceColor(color1)
         AddPathCircle(size/2, size/2, size/5)

         MovePathCursor(size/2, p*6)
         AddPathLine(size/2, p*15)
         StrokePath(p*2)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Info (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [slightly modified after davido]
      Protected ret.i, p.d

      p = size / 32.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; If Alpha(color2) = 0, then this part is invisible.
         VectorSourceColor(color2)
         AddPathCircle(size/2, size/2, size/2.4)
         FillPath()

         VectorSourceColor(color1)
         AddPathCircle(size/2, size/4, p*2)
         FillPath()
         MovePathCursor(size/2, p*13)
         AddPathLine(size/2, p*23)
         AddPathLine(p*18, p*23)
         StrokePath(p*4, #PB_Path_RoundCorner | #PB_Path_RoundEnd)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Collapse (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, w.d, p.d

      w = size / 8
      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         AddPathCircle(w,   w, 2.5*p)
         AddPathCircle(w, 4*w, 2.5*p)
         AddPathCircle(w, 7*w, 2.5*p)
         FillPath()

         MovePathCursor(  w, w)
         AddPathLine   (  w, size-w)
         MovePathCursor(  w, w)
         AddPathLine   (5*w, w)
         MovePathCursor(  w, 4*w)
         AddPathLine   (5*w, 4*w)
         MovePathCursor(  w, 7*w)
         AddPathLine   (5*w, 7*w)
         StrokePath(p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Expand (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, w.d, p.d

      w = size / 8
      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         AddPathCircle(w,     w, 2.5*p)
         AddPathCircle(5*w, 4*w, 2.5*p)
         AddPathCircle(5*w, 7*w, 2.5*p)
         FillPath()

         MovePathCursor(w, w)
         AddPathLine(w, size-w)
         MovePathCursor(w, w)
         AddPathLine(5*w, w)
         MovePathCursor(w, 4*w)
         AddPathLine(8*w, 4*w)
         MovePathCursor(5*w, 4*w)
         AddPathLine(5*w, 7*w)
         MovePathCursor(5*w, 7*w)
         AddPathLine(8*w, 7*w)
         StrokePath(p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Success (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, w.d

      w = size / 8.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         AddPathCircle(size/2, size/2, size/2.4)
         ClosePath()
         StrokePath(w, #PB_Path_RoundCorner)

         MovePathCursor(3*w, 4*w)
         AddPathLine(4*w, 5*w)
         AddPathLine(5.5*w, 3*w)
         StrokePath(0.75*w, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Home (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, w.d, p.d

      w = size / 8
      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor(4*w,     2*p)
         AddPathLine   (  w, 4*w + 2*p)
         AddPathLine   (2*w, 4*w + 2*p)
         AddPathLine   (2*w, 7*w + 2*p)
         AddPathLine   (6*w, 7*w + 2*p)
         AddPathLine   (6*w, 4*w + 2*p)
         AddPathLine   (7*w, 4*w + 2*p)
         ClosePath()

         MovePathCursor(3*w, 4*w)
         AddPathLine   (3*w, 6*w)
         MovePathCursor(3*w, 5*w)
         AddPathLine   (5*w, 5*w)
         MovePathCursor(5*w, 4*w)
         AddPathLine   (5*w, 6*w)
         StrokePath(p*2)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i AlignLeft (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor( 4*p,  2*p)
         AddPathLine   (24*p,  2*p)
         MovePathCursor( 4*p,  9*p)
         AddPathLine   (12*p,  9*p)
         MovePathCursor( 4*p, 16*p)
         AddPathLine   (16*p, 16*p)
         MovePathCursor( 4*p, 23*p)
         AddPathLine   (12*p, 23*p)
         MovePathCursor( 4*p, 30*p)
         AddPathLine   (24*p, 30*p)
         StrokePath(2*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i AlignCentre (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor( 6*p,  2*p)
         AddPathLine   (26*p,  2*p)
         MovePathCursor(12*p,  9*p)
         AddPathLine   (20*p,  9*p)
         MovePathCursor(10*p, 16*p)
         AddPathLine   (22*p, 16*p)
         MovePathCursor(12*p, 23*p)
         AddPathLine   (20*p, 23*p)
         MovePathCursor( 6*p, 30*p)
         AddPathLine   (26*p, 30*p)
         StrokePath(2*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i AlignRight (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor( 8*p,  2*p)
         AddPathLine   (28*p,  2*p)
         MovePathCursor(20*p,  9*p)
         AddPathLine   (28*p,  9*p)
         MovePathCursor(16*p, 16*p)
         AddPathLine   (28*p, 16*p)
         MovePathCursor(20*p, 23*p)
         AddPathLine   (28*p, 23*p)
         MovePathCursor( 8*p, 30*p)
         AddPathLine   (28*p, 30*p)
         StrokePath(2*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i AlignJustify (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor( 4*p,  2*p)
         AddPathLine   (28*p,  2*p)
         MovePathCursor( 4*p,  9*p)
         AddPathLine   (28*p,  9*p)
         MovePathCursor( 4*p, 16*p)
         AddPathLine   (28*p, 16*p)
         MovePathCursor( 4*p, 23*p)
         AddPathLine   (28*p, 23*p)
         MovePathCursor( 4*p, 30*p)
         AddPathLine   (28*p, 30*p)
         StrokePath(2*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Macro Cog()
      MovePathCursor(px-3*p, py+p)
      AddPathLine   (px-2*p, py)
      AddPathLine   (px - p, py-3*p)
      AddPathLine   (px + p, py-3*p)
      AddPathLine   (px+2*p, py)
      AddPathLine   (px+3*p, py+p)
   EndMacro

   Procedure.i Compile (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, d.d, p.d, h.d, M.i, px.d, py.d

      h = size / 2
      p = size / 32
      d = 11*p
      px = h
      py = h - d

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         AddPathCircle(h, h,   d, 30, 330)
         AddPathCircle(h, h, 5*p, 30, 330)
         ResetCoordinates()
         Cog()
         For M = 1 To 7
            RotateCoordinates(h, h, 45)
            If M <> 2
               Cog()
            EndIf
         Next M
         StrokePath(3*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i CompileRun (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, d.d, p.d, h.d, M.i, px.d, py.d

      h = size / 2
      p = size / 32
      d = 11*p
      px = h
      py = h - d

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         AddPathCircle(h, h, d, 30, 330)
         MovePathCursor(10*p, 16*p)
         AddPathLine(28*p, 16*p)
         MovePathCursor(20*p, 13*p)
         AddPathLine(20*p, 19*p)
         AddPathLine(31*p, 16*p)
         ClosePath()
         Cog()
         For M = 1 To 7
            RotateCoordinates(h, h, 45)
            If M <> 2
               Cog()
            EndIf
         Next M
         StrokePath(3*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Settings (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, d.d, p.d, h.d, M.i, px.d, py.d

      h = size / 2
      p = size / 32
      d = 11*p
      px = h
      py = h - d

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         AddPathCircle(h, h, d)
         ResetCoordinates()
         Cog()
         For M = 1 To 7
            RotateCoordinates(h, h, 45)
            Cog()
         Next M
         StrokePath(3*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Options (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, h.d

      h = size / 2
      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         AddPathBox(5*p, p, 5*p, 5*p)
         FillPath()
         MovePathCursor(12*p, 4*p)
         AddPathLine(25*p, 4*p)
         StrokePath(p)
         AddPathBox(5*p, 13*p, 5*p, 5*p)
         FillPath()
         MovePathCursor(12*p, 16*p)
         AddPathLine(25*p, 16*p)
         StrokePath(p)
         AddPathBox(5*p, 25*p, 5*p, 5*p)
         FillPath()
         MovePathCursor(12*p, 27*p)
         AddPathLine(25*p, 27*p)
         StrokePath(p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Toggle1 (file$, img.i, size.i, color1.i, color2.i=0, color3.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         AddPathBox(2*p, 2*p, 30*p, 12*p)
         FillPath()
         VectorSourceColor(color3)
         AddPathCircle(8*p, 8*p, 4*p)
         FillPath()
         VectorSourceColor(color2)
         AddPathBox(2*p, 18*p, 30*p, 12*p)
         FillPath()
         VectorSourceColor(color3)
         AddPathCircle(24*p, 24*p, 4*p)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Toggle2 (file$, img.i, size.i, color1.i, color2.i=0, color3.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)

         AddPathBox(2*p, 2*p, 30*p, 12*p)
         AddPathBox(2*p, 18*p, 30*p, 12*p)
         FillPath()
         VectorSourceColor(color2)
         AddPathCircle(8*p, 8*p, 4*p)
         FillPath()
         VectorSourceColor(color3)
         AddPathCircle(24*p, 24*p, 4*p)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Save1 (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Add shield
         VectorSourceColor(color)
         MovePathCursor(8*p, 2*p)
         AddPathLine(20*p, 2*p)
         AddPathLine(20*p, 12*p)
         AddPathLine(8*p, 12*p)
         ClosePath()
         FillPath()
         ; Add outer box
         MovePathCursor(25*p, 2*p)   ; Covers gap at joint
         AddPathLine(30*p, 12*p)
         AddPathLine(30*p, 30*p)
         AddPathLine(2*p, 30*p)
         AddPathLine(2*p, 2*p)
         AddPathLine(24*p, 2*p)
         StrokePath(4*p, #PB_Path_RoundCorner | #PB_Path_RoundEnd)
         ; Add text
         MovePathCursor(8*p, 18*p)
         AddPathLine(24*p, 18*p)
         MovePathCursor(8*p, 22*p)
         AddPathLine(24*p, 22*p)
         StrokePath(p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ZoomIn (file$, img.i, size.i, color.i, flipHorizontally.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img             : number of the image which is to be created, or #PB_Any
      ;      size            : width and height (number of pixels)
      ;      color           : foreground color
      ;      flipHorizontally: #True / #False
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido - Modification of 'Find' icon by Little John]
      Protected ret.i, xm.d, ym.d

      xm = 0.65 * size
      ym = 0.35 * size

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If flipHorizontally
            FlipCoordinatesX(size/2)
         EndIf

         VectorSourceColor(color)
         DrawMagnifyingGlass(0, 0, size)

         ; Insert the 'plus' sign
         MovePathCursor(xm - size/5, ym)
         AddPathLine   (xm + size/5, ym)
         MovePathCursor(xm, ym - size/5)
         AddPathLine   (xm, ym + size/5)
         StrokePath(0.057 * size)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ZoomOut (file$, img.i, size.i, color.i, flipHorizontally.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img             : number of the image which is to be created, or #PB_Any
      ;      size            : width and height (number of pixels)
      ;      color           : foreground color
      ;      flipHorizontally: #True / #False
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido - Modification of 'Find' icon by Little John]
      Protected ret.i, xm.d, ym.d

      xm = 0.65 * size
      ym = 0.35 * size

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If flipHorizontally
            FlipCoordinatesX(size/2)
         EndIf

         VectorSourceColor(color)
         DrawMagnifyingGlass(0, 0, size)

         ; Insert the 'minus' sign
         MovePathCursor(xm - size/5, ym)
         AddPathLine   (xm + size/5, ym)
         StrokePath(0.057 * size)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Great (file$, img.i, size.i, color.i, flipHorizontally.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img             : number of the image which is to be created, or #PB_Any
      ;      size            : width and height (number of pixels)
      ;      color           : foreground color
      ;      flipHorizontally: #True / #False
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If flipHorizontally
            FlipCoordinatesX(size/2)
         EndIf

         VectorSourceColor(color)

         MovePathCursor(p, 14*p)
         AddPathLine   (p, 30*p)
         AddPathLine(20*p, 30*p)
         MovePathCursor(16*p, 26*p)
         AddPathLine(22*p, 26*p)
         AddPathCircle(20*p, 28*p, 2*p, 270, 90)
         MovePathCursor(16*p, 22*p)
         AddPathLine(26*p, 22*p)
         AddPathCircle(22*p, 24*p, 2*p, 270, 90)
         MovePathCursor(16*p, 18*p)
         AddPathLine(26*p, 18*p)
         AddPathCircle(26*p, 20*p, 2*p, 270, 90)
         MovePathCursor(p, 14*p)
         AddPathLine(22*p, 14*p)
         AddPathCircle(22*p, 16*p, 2*p, 270, 90)
         AddPathCircle(2*p, p, 13*p, 10, 85)
         MovePathCursor(14.7*p, 3*p)
         AddPathLine(13.7*p, 3*p)
         AddPathLine(2*p, 14*p)
         StrokePath(2*p, #PB_Path_RoundCorner | #PB_Path_RoundEnd)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DownLoad1 (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Background
         VectorSourceColor(color2)
         AddPathCircle(16*p, 16*p, 15*p)
         FillPath()

         VectorSourceColor(color1)
         ; Tray
         MovePathCursor(8*p, 16*p)
         AddPathLine(8*p, 22*p)
         AddPathLine(24*p, 22*p)
         AddPathLine(24*p, 16*p)
         ; Shaft
         MovePathCursor(16*p, 6*p)
         AddPathLine(16*p, 16*p)
         StrokePath(2*p)
         ; Arrowhead
         MovePathCursor(12*p, 14*p)
         AddPathLine(20*p, 14*p)
         AddPathLine(16*p, 18*p)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i UpLoad1 (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Background
         VectorSourceColor(color2)
         AddPathCircle(16*p, 16*p, 15*p)
         FillPath()

         VectorSourceColor(color1)
         ; Tray
         MovePathCursor(8*p, 16*p)
         AddPathLine(8*p, 22*p)
         AddPathLine(24*p, 22*p)
         AddPathLine(24*p, 16*p)
         ; Shaft
         MovePathCursor(16*p, 18*p)
         AddPathLine(16*p, 10*p)
         StrokePath(2*p)
         ; Arrowhead
         MovePathCursor(12*p, 10*p)
         AddPathLine(20*p, 10*p)
         AddPathLine(16*p, 6*p)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i LineWrapOn (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, M.i

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         ; Page
         AddPathBox(2*p, 2*p, 28*p, 28*p)
         ; Lines on page
         MovePathCursor(4*p, 5*p)
         AddPathLine(28*p, 5*p)
         MovePathCursor(4*p, 8*p)
         AddPathLine(28*p, 8*p)
         For M = 11 To 26 Step 3
            MovePathCursor(4*p, M*p)
            AddPathLine(10*p, M*p)
         Next M
         StrokePath(p, #PB_Path_RoundCorner)
         ; Arrow shaft
         VectorSourceColor(color2)
         MovePathCursor(24*p, 10*p)
         AddPathLine(24*p, 20*p)
         AddPathLine(16*p, 20*p)
         StrokePath(p)
         ; Arrow head
         MovePathCursor(16*p, 16*p)
         AddPathLine(16*p, 24*p)
         AddPathLine(12*p, 20*p)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i LineWrapOff (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, M.i

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         ; Page
         AddPathBox(2*p, 2*p, 28*p, 28*p)
         ; Lines on page
         MovePathCursor(4*p, 5*p)
         AddPathLine(28*p, 5*p)
         MovePathCursor(4*p, 8*p)
         AddPathLine(28*p, 8*p)
         For M = 11 To 26 Step 3
            MovePathCursor(4*p, M*p)
            AddPathLine(10*p, M*p)
         Next M
         StrokePath(p, #PB_Path_RoundCorner)
         ; Arrow shaft
         VectorSourceColor(color2)
         MovePathCursor(22*p, 14*p)
         AddPathLine(22*p, 24*p)
         AddPathLine(13*p, 24*p)
         StrokePath(p)
         ; Arrow head
         MovePathCursor(18*p, 14*p)
         AddPathLine(26*p, 14*p)
         AddPathLine(22*p, 10*p)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Donate1 (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         AddPathCircle( 9*p, 10*p, 7*p, 180, 0)
         AddPathCircle(23*p, 10*p, 7*p, 180, 0)

         AddPathLine(16*p, 30.5*p)
         AddPathLine( 2*p, 10*p)
         ClosePath()
         FillPath()

         AddPathCircle(24*p, 10*p, 22*p, 110, 180)
         FillPath()

         AddPathCircle(8*p, 10*p, 22*p, 0, 70)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Donate2 (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         AddPathCircle( 9*p, 10*p, 7*p, 180, 0)
         AddPathCircle(23*p, 10*p, 7*p, 180, 0)

         MovePathCursor(30*p, 10*p)
         AddPathLine(16*p, 30*p)
         AddPathLine(2*p, 10*p)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Filter (file$, img.i, size.i, color.i, fill.i=#True)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ;      fill : #True / #False
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [created by davido, optional parameter 'fill' added by Little John]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor(p, p)
         AddPathLine(31*p, p)
         AddPathLine(19*p, 18*p)
         AddPathLine(19*p, 26*p)
         AddPathLine(13*p, 31*p)
         AddPathLine(13*p, 18*p)
         ClosePath()
         If fill
            FillPath()
         Else
             StrokePath(2*p)
         EndIf
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Bookmark (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, M.i, L.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         ; Page
         AddPathBox(2*p, 2*p, 28*p, 28*p)
         For M = 5 To 26 Step 3
            L = 10 + Random(18)
            MovePathCursor(4*p, M*p)
            AddPathLine(L*p, M*p)
         Next M
         StrokePath(p, #PB_Path_RoundCorner)

         ; Ribbon
         VectorSourceColor(color2)
         MovePathCursor(20*p, p)
         AddPathLine(20*p, 28*p)
         AddPathLine(24*p, 20*p)
         AddPathLine(28*p, 28*p)
         AddPathLine(28*p, p)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Database (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         ; Place top and base elipses
         AddPathEllipse(16*p,  6*p, 12*p, 2.5*p)
         AddPathEllipse(16*p, 26*p, 12*p, 2.5*p)
         FillPath()
         ; Add the sides - Needs the full box to fill
         AddPathBox(4*p, 6*p, 24.5*p, 20*p)
         FillPath()

         ; Add in the cylinders
         VectorSourceColor(color2)
         AddPathEllipse(16*p,  6*p, 12*p, 2.5*p, 0, 180)
         AddPathEllipse(16*p, 11*p, 12*p, 2.5*p, 0, 180)
         AddPathEllipse(16*p, 16*p, 12*p, 2.5*p, 0, 180)
         AddPathEllipse(16*p, 21*p, 12*p, 2.5*p, 0, 180)
         StrokePath(1.5*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Macro Spanner()
      AddPathEllipse(16*p, 7*p, 3.5*p, 5*p, 20, 160)
      MovePathCursor(12.7*p, 4*p)
      AddPathLine(12.7*p, 9*p)
      MovePathCursor(19.3*p, 4*p)
      AddPathLine(19.3*p, 9*p)
      StrokePath(3*p)
      MovePathCursor(16*p, 13*p)
      AddPathLine(16*p, 26*p)
      StrokePath(4*p, #PB_Path_RoundEnd)
   EndMacro

   Macro Hammer()
      MovePathCursor(13.5*p, 28*p)
      AddPathLine(18.5*p, 28*p)
      AddPathLine(17.5*p, 11*p)
      AddPathLine(13.5*p, 11*p)
      ClosePath()
      FillPath()
      MovePathCursor(9*p, 7*p)
      AddPathLine(9*p, 11*p)
      MovePathCursor(9*p, 10*p)
      AddPathLine(10*p, 10*p)
      AddPathLine(10*p, 11*p)
      AddPathLine(21*p, 11*p)
      AddPathLine(21*p, 10*p)
      AddPathLine(23*p, 10*p)
      AddPathLine(23*p, 11*p)
      AddPathLine(26*p, 11*p)
      AddPathLine(26*p, 7*p)
      AddPathLine(23*p, 7*p)
      AddPathLine(23*p, 8*p)
      AddPathLine(21*p, 8*p)
      AddPathLine(21*p, 7*p)
      AddPathLine(10*p, 7*p)
      AddPathLine(10*p, 8*p)
      AddPathLine(9*p, 8*p)
      FillPath()
      AddPathEllipse(9*p, 9*p, 4*p, 2*p, 90, 270)
      FillPath()
   EndMacro

   Procedure.i Tools (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, half.d

      p = size / 32
      half = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Spanner tool
         VectorSourceColor(color)
         Spanner()

         ; Hammer tool
         RotateCoordinates(16*p, 16*p, -104)
         Hammer()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Sort (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         ; A
         MovePathCursor(4*p, 14*p)
         AddPathLine( 8*p, 2*p)
         AddPathLine(12*p, 14*p)
         MovePathCursor(6*p, 10*p)
         AddPathLine(10*p, 10*p)
         ; Z
         MovePathCursor(2*p, 18*p)
         AddPathLine(13*p, 18*p)
         AddPathLine( 3*p, 30*p)
         AddPathLine(14*p, 30*p)
         ;Double arrows
         MovePathCursor(26*p, 4*p)
         AddPathLine(26*p, 28*p)
         StrokePath(2*p)
         MovePathCursor(21*p, 8*p)
         AddPathLine(26*p, 2*p)
         AddPathLine(31*p, 8*p)
         ClosePath()
         FillPath()
         MovePathCursor(21*p, 24*p)
         AddPathLine(26*p, 30*p)
         AddPathLine(31*p, 24*p)
         ClosePath()
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Randomise (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         MovePathCursor(2*p, 9*p)
         AddPathLine(12*p, 9*p)
         AddPathLine(20*p, 24*p)
         AddPathLine(26*p, 24*p)
         MovePathCursor(2*p, 24*p)
         AddPathLine(12*p, 24*p)
         AddPathLine(20*p, 9*p)
         AddPathLine(26*p, 9*p)
         StrokePath(2*p)
         MovePathCursor(26*p, 5*p)
         AddPathLine(26*p, 13*p)
         AddPathLine(31*p, 9*p)
         ClosePath()
         FillPath()
         MovePathCursor(26*p, 20*p)
         AddPathLine(26*p, 28*p)
         AddPathLine(31*p, 24*p)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i IsProtected (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, x.d, y.d, half.d, hw.d

      p = size / 32
      x = size / 2
      y = size / 2
      half = size / 6
      hw = size / 30

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Left-hand side of shield
         VectorSourceColor(color1)
         AddPathEllipse(16*p, 16*p, 10*p, 12*p, 90, 270)
         ClosePath()
         FillPath()
         MovePathCursor(6*p, 16*p)
         AddPathLine( 6*p,  6*p)
         AddPathLine(16*p,  2*p)
         AddPathLine(16*p, 16*p)
         ClosePath()
         FillPath()

         ; Right-hand side of shield
         VectorSourceColor(color2)
         AddPathEllipse(16*p, 16*p, 10*p, 12*p, 270, 90)
         ClosePath()
         FillPath()
         MovePathCursor(26*p, 16*p)
         AddPathLine(26*p,  6*p)
         AddPathLine(16*p,  2*p)
         AddPathLine(16*p, 16*p)
         ClosePath()
         FillPath()

         ; Central tick
         VectorSourceColor(color3)
         DrawTick(x, y, half, hw)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i UnProtected1 (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Left-hand side of shield
         VectorSourceColor(color1)
         AddPathEllipse(16*p, 16*p, 10*p, 12*p, 90, 270)
         ClosePath()
         FillPath()
         MovePathCursor(6*p, 16*p)
         AddPathLine( 6*p,  6*p)
         AddPathLine(16*p,  2*p)
         AddPathLine(16*p, 16*p)
         ClosePath()
         FillPath()

         ; Right-hand side of shield
         VectorSourceColor(color2)
         AddPathEllipse(16*p, 16*p, 10*p, 12*p, 270, 90)
         ClosePath()
         FillPath()
         MovePathCursor(26*p, 16*p)
         AddPathLine(26*p,  6*p)
         AddPathLine(16*p,  2*p)
         AddPathLine(16*p, 16*p)
         ClosePath()
         FillPath()

         ; Central exclamation mark
         VectorSourceColor(color3)
         MovePathCursor(14 * p, 10 * p)
         AddPathLine(16 * p, 20 * p)
         AddPathLine(18 * p, 10 * p)
         ClosePath()
         FillPath()
         AddPathCircle(16 * p, 10 * p, 2 * p)

         AddPathCircle(16 * p, 22 * p, 1.5 * p)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i UnProtected2 (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Left-hand side of shield
         VectorSourceColor(color1)
         AddPathEllipse(16*p, 16*p, 10*p, 12*p, 90, 270)
         ClosePath()
         FillPath()
         MovePathCursor(6*p, 16*p)
         AddPathLine( 6*p,  6*p)
         AddPathLine(16*p,  2*p)
         AddPathLine(16*p, 16*p)
         ClosePath()
         FillPath()

         ; Right-hand side of shield
         VectorSourceColor(color2)
         AddPathEllipse(16*p, 16*p, 10*p, 12*p, 270, 90)
         ClosePath()
         FillPath()
         MovePathCursor(26*p, 16*p)
         AddPathLine(26*p,  6*p)
         AddPathLine(16*p,  2*p)
         AddPathLine(16*p, 16*p)
         ClosePath()
         FillPath()

         ; Draw central X
         VectorSourceColor(color3)
         RotateCoordinates(0.5*size, 0.5*size, 45)
         DrawPlus(0.5*size, 0.5*size, 0.2*size, size/20)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Network (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         AddPathBox(13*p,  3*p, 6*p, 5*p)
         AddPathBox(   p, 20*p, 6*p, 5*p)
         AddPathBox(13*p, 20*p, 6*p, 5*p)
         AddPathBox(25*p, 20*p, 6*p, 5*p)
         FillPath()
         MovePathCursor( 4*p, 20*p)
         AddPathLine(    4*p, 13*p)
         AddPathLine(   28*p, 13*p)
         AddPathLine(   28*p, 20*p)
         MovePathCursor(16*p,  6*p)
         AddPathLine(   16*p, 20*p)
         StrokePath(1.5*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Music (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         AddPathEllipse( 8*p, 26*p, 6*p, 4*p)
         AddPathEllipse(24*p, 22*p, 6*p, 4*p)
         FillPath()
         MovePathCursor(12.5*p, 26*p)
         AddPathLine(   12.5*p,  6*p)
         AddPathLine(   28.5*p,  2*p)
         AddPathLine(   28.5*p, 22*p)
         StrokePath(3*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Microphone (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         ; Cradle
         AddPathEllipse(16*p, 12*p, 9*p, 12*p, 0, 180)

         ; Upright
         MovePathCursor(16*p, 23*p)
         AddPathLine(16*p, 30*p)

         ; Base
         MovePathCursor(6*p, 30*p)
         AddPathLine(26*p, 30*p)

         ; Top of cradle
         MovePathCursor(7*p, 7*p)
         AddPathLine(7*p, 14*p)
         MovePathCursor(25*p, 7*p)
         AddPathLine(25*p, 14*p)
         StrokePath(3*p)

         ; Microphone
         MovePathCursor(16*p, 15*p)
         AddPathLine(16*p, 5*p)
         StrokePath(10*p, #PB_Path_RoundEnd)

         ; Joints on cradle
         AddPathBox(3*p, 9*p, 8*p, 3*p)
         AddPathBox(20*p, 9*p, 8*p, 3*p)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Picture (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img      : number of the image which is to be created, or #PB_Any
      ;      size     : width and height (number of pixels)
      ;      color 1-6: foreground colors
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, M.i

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Frame
         VectorSourceColor(color5)
         AddPathBox(0, 0, size, size)
         FillPath()

         ; Sky
         VectorSourceColor(color1)
         AddPathBox(2*p, 2*p, size-4*p, size-4*p)
         FillPath()

         ; Grass
         VectorSourceColor(color2)
         AddPathBox(2*p, 16*p, size-4*p, size-18*p)
         FillPath()

         ; Leaves
         For M = 1 To 8
            VectorSourceColor(color3)
            If M <> 5
               AddPathEllipse(16*p, 9*p, 3*p, 6*p)
            EndIf
            RotateCoordinates(16*p, 15*p, 45)
            FillPath()
         Next M

         ; Stalk
         VectorSourceColor(color6)
         MovePathCursor(16*p, 15*p)
         AddPathLine(16*p, 30*p)
         StrokePath(2*p)

         ; Center of the flower
         VectorSourceColor(color4)
         AddPathCircle(16*p, 15*p, 4*p)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Bug (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Body of bug
         SaveVectorState()
         RotateCoordinates(16*p, 16*p, -45)
         VectorSourceColor(color1)
         AddPathEllipse(9*p, 16*p, 12*p, 8*p)
         FillPath()

         ; Head of bug
         RestoreVectorState()
         RotateCoordinates(16*p, 16*p, -45)
         VectorSourceColor(color2)
         AddPathEllipse(23*p, 16*p, 4*p, 5*p)
         FillPath()

         ; Antenae
         ResetCoordinates()
         MovePathCursor(19*p, 12*p)
         AddPathLine(19*p, 1.5*p)
         MovePathCursor(19*p, 12*p)
         AddPathLine(30*p, 12*p)
         StrokePath(0.3*p)
         AddPathCircle(30*p, 12*p, p)
         AddPathCircle(19*p, 2*p, p)
         FillPath()

         ; Spots
         AddPathCircle(16*p, 19*p, 2*p)
         AddPathCircle(11*p, 16*p, 2*p)
         AddPathCircle(5*p, 20*p, 2*p)
         AddPathCircle(14*p, 25*p, 2*p)
         AddPathCircle(7*p, 28*p, 2*p)
         FillPath()

         ; Between wings
         MovePathCursor(22.5*p, 9*p)
         AddPathLine(2.5*p, 29.25*p)
         StrokePath(0.25*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DBug (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Body of bug
         SaveVectorState()
         RotateCoordinates(16*p, 16*p, -45)
         VectorSourceColor(color1)
         AddPathEllipse(9*p, 16*p, 12*p, 8*p)
         FillPath()

         ; Head of bug
         RestoreVectorState()
         RotateCoordinates(16*p, 16*p, -45)
         VectorSourceColor(color2)
         AddPathEllipse(23*p, 16*p, 4*p, 5*p)
         FillPath()

         ; Antenae
         ResetCoordinates()
         MovePathCursor(19*p, 12*p)
         AddPathLine(19*p, 1.5*p)
         MovePathCursor(19*p, 12*p)
         AddPathLine(30*p, 12*p)
         StrokePath(0.3*p)
         AddPathCircle(30*p, 12*p, p)
         AddPathCircle(19*p,  2*p, p)
         FillPath()

         ; Spots
         AddPathCircle(16*p, 19*p, 2*p)
         AddPathCircle(11*p, 16*p, 2*p)
         AddPathCircle( 5*p, 20*p, 2*p)
         AddPathCircle(11*p, 27*p, 2*p)
         AddPathCircle(3.5*p, 25*p, 2*p)
         FillPath()

         ; Between wings
         MovePathCursor(22.5*p, 9*p)
         AddPathLine(2.5*p, 29.25*p)
         StrokePath(0.25*p)

         ; Red cross
         VectorSourceColor(color3)
         RotateCoordinates(16*p, 16*p, 45)
         DrawPlus(16*p, 16*p, 0.5*size, 3*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Crop (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         MovePathCursor(8*p, 2*p)
         AddPathLine(8*p, 24.5*p)
         AddPathLine(30.5*p, 24.5*p)
         MovePathCursor(24.5*p, 30.5*p)
         AddPathLine(24.5*p, 8*p)
         AddPathLine(2*p, 8*p)
         StrokePath(2*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ReSize2 (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, k.i

      p = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         MovePathCursor(16*p, 26*p)
         AddPathLine( 2*p, 26*p)
         AddPathLine( 2*p, 2*p)
         AddPathLine(26*p, 2*p)
         AddPathLine(26*p, 16*p)
         AddPathBox(16.5*p, 16.5*p, 15*p, 15*p)
         StrokePath(p)
         VectorSourceColor(color2)
         DrawStar(12*p, 12*p, 6*p, 6)
         StrokePath(p)
         DrawStar(22*p, 22*p, 3.25*p, 6)
         StrokePath(0.6*p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Rating (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, k.i

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32
      If ret
         VectorSourceColor(color1)
         DrawStar( 6*p,  6*p, 5*p)
         DrawStar( 6*p, 16*p, 5*p)
         DrawStar(16*p, 16*p, 5*p)
         DrawStar( 6*p, 26*p, 5*p)
         DrawStar(16*p, 26*p, 5*p)
         DrawStar(26*p, 26*p, 5*p)
         FillPath()
         VectorSourceColor(color2)
         DrawStar(16*p,  6*p, 5*p)
         DrawStar(26*p,  6*p, 5*p)
         DrawStar(26*p, 16*p, 5*p)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i CitrusFruits (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         AddPathCircle(0.5*size, 0.5*size, 0.45*size)
         StrokePath(0.03125*size)

         VectorSourceColor(color2)
         AddPathCircle(0.5*size, 0.5*size, 0.45*size)
         FillPath()

         VectorSourceColor(color1)
         AddPathCircle(0.5*size, 0.5*size, 0.40*size)
         FillPath()

         VectorSourceColor(color2)
         MovePathCursor(0.49*size, 0.5*size)
         AddPathLine(0.48*size, 0.1*size)
         AddPathLine(0.52*size, 0.1*size)
         AddPathLine(0.51*size, 0.5*size)
         ClosePath()
         RotateCoordinates(0.5*size, 0.5*size, 50)
         MovePathCursor(0.49*size, 0.5*size)
         AddPathLine(0.48*size, 0.1*size)
         AddPathLine(0.52*size, 0.1*size)
         AddPathLine(0.51*size, 0.5*size)
         ClosePath()
         RotateCoordinates(0.5*size, 0.5*size, 75)
         MovePathCursor(0.49*size, 0.5*size)
         AddPathLine(0.48*size, 0.1*size)
         AddPathLine(0.52*size, 0.1*size)
         AddPathLine(0.51*size, 0.5*size)
         ClosePath()
         RotateCoordinates(0.5*size, 0.5*size, 45)
         MovePathCursor(0.49*size, 0.5*size)
         AddPathLine(0.48*size, 0.1*size)
         AddPathLine(0.52*size, 0.1*size)
         AddPathLine(0.51*size, 0.5*size)
         ClosePath()
         RotateCoordinates(0.5*size, 0.5*size, 65)
         MovePathCursor(0.49*size, 0.5*size)
         AddPathLine(0.48*size, 0.1*size)
         AddPathLine(0.52*size, 0.1*size)
         AddPathLine(0.51*size, 0.5*size)
         ClosePath()
         RotateCoordinates(0.5*size, 0.5*size, 55)
         MovePathCursor(0.49*size, 0.5*size)
         AddPathLine(0.48*size, 0.1*size)
         AddPathLine(0.52*size, 0.1*size)
         AddPathLine(0.51*size, 0.5*size)
         ClosePath()
         FillPath()
         AddPathCircle(0.5*size, 0.5*size, 0.0625*size)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Action (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         AddPathEllipse(0.5*size, 0.5*size, 0.46875*size, 0.1875*size)
         StrokePath(0.0625*size)
         RotateCoordinates(0.5*size, 0.5*size, 60)
         VectorSourceColor(color2)
         AddPathEllipse(0.5*size, 0.5*size, 0.46875*size, 0.1875*size)
         StrokePath(0.0625*size)
         RotateCoordinates(0.5*size, 0.5*size, 60)
         VectorSourceColor(color3)
         AddPathEllipse(0.5*size, 0.5*size, 0.46875*size, 0.1875*size)
         StrokePath(0.0625*size)
         VectorSourceColor(color3)
         AddPathCircle(0.5*size, 0.5*size, 0.09375*size)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Move (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         MovePathCursor(0.3125 * size, 0.21875 * size)
         AddPathLine(0.5     * size, 0.03125 * size)
         AddPathLine(0.6875  * size, 0.21875 * size)
         AddPathLine(0.53125 * size, 0.21875 * size)
         AddPathLine(0.53125 * size, 0.46875 * size)
         AddPathLine(0.78125 * size, 0.46875 * size)
         AddPathLine(0.78125 * size, 0.3125  * size)
         AddPathLine(0.96875 * size, 0.5     * size)
         AddPathLine(0.78125 * size, 0.6875  * size)
         AddPathLine(0.78125 * size, 0.53125 * size)
         AddPathLine(0.53125 * size, 0.53125 * size)
         AddPathLine(0.53125 * size, 0.78125 * size)
         AddPathLine(0.6875  * size, 0.78125 * size)
         AddPathLine(0.5     * size, 0.96875 * size)
         AddPathLine(0.3125  * size, 0.78125 * size)
         AddPathLine(0.46875 * size, 0.78125 * size)
         AddPathLine(0.46875 * size, 0.53125 * size)
         AddPathLine(0.21875 * size, 0.53125 * size)
         AddPathLine(0.21875 * size, 0.6875  * size)
         AddPathLine(0.03125 * size, 0.5     * size)
         AddPathLine(0.21875 * size, 0.3125  * size)
         AddPathLine(0.21875 * size, 0.46875 * size)
         AddPathLine(0.46875 * size, 0.46875 * size)
         AddPathLine(0.46875 * size, 0.21875 * size)
         AddPathLine(0.3125  * size, 0.21875 * size)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Lock (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         ; Body of lock
         DrawRoundBox(0.25 * size, 0.5 * size, 0.5 * size, 0.4375 * size, 0.09375 * size)
         FillPath()
         ; Shank - semi circle top
         AddPathCircle(0.5 * size, 0.28125 * size, 0.15625 * size, 180, 0)
         ; Shank - right arm
         AddPathLine(0.65625 * size, 0.5 * size)
         ; Shank - left arm
         MovePathCursor(0.34375 * size, 0.28125 * size)
         AddPathLine(0.34375 * size, 0.5 * size)
         StrokePath(0.0625 * size)
         ; Keyhole
         VectorSourceColor(color2)
         AddPathCircle(0.5 * size, 0.6875 * size, 0.0625 * size)
         FillPath()
         MovePathCursor(0.5 * size, 0.6875 * size)
         AddPathLine(0.5625 * size, 0.875 * size)
         AddPathLine(0.4375 * size, 0.875 * size)
         ClosePath()
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Unlock (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         ; Body of lock
         DrawRoundBox(0.25 * size, 0.5 * size, 0.5 * size, 0.4375 * size, 0.09375 * size)
         FillPath()
         ; Shank - semi circle top
         AddPathCircle(0.5 * size, 0.1875 * size, 0.15625 * size, 180, 0)
         ; Shank - right arm
         AddPathLine(0.65625 * size, 0.5 * size)
         ; Shank - left arm
         MovePathCursor(0.34375 * size, 0.1875 * size)
         AddPathLine(0.34375 * size, 0.4375 * size)
         StrokePath(0.0625 * size)
         VectorSourceColor(color2)
         ; Hasp slot
         MovePathCursor(0.375 * size, 0.34375 * size)
         AddPathLine(0.34375 * size, 0.34375 * size)
         StrokePath(0.0625 * size)
         ; Keyhole
         AddPathCircle(0.5 * size, 0.6875 * size, 0.0625 * size)
         FillPath()
         MovePathCursor(0.5 * size, 0.6875 * size)
         AddPathLine(0.5625 * size, 0.875 * size)
         AddPathLine(0.4375 * size, 0.875 * size)
         ClosePath()
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Fill (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32
      If ret
         ; Drips
         VectorSourceColor(color2)
         AddPathCircle(26.5*p, 26*p, 2.5*p, 0, 180)
         FillPath()
         AddPathCircle(26.5*p, 23*p, 0.99*p, 180, 0)
         FillPath()

         MovePathCursor(25.5*p, 23*p)
         AddPathLine(24*p, 26*p)
         AddPathLine(29*p, 26*p)
         AddPathLine(27.5*p, 23*p)
         ClosePath()
         FillPath()

         AddPathCircle(25.5*p, 19.5*p, 1.5*p, 330, 60)
         StrokePath(p)
         VectorSourceColor(color1)
         SaveVectorState()
         RotateCoordinates(16*p, 16*p, 45)
         DrawRoundBox(8*p, 10*p, 16*p, 15*p, 2*p)
         FillPath()

         MovePathCursor(20*p, 11.5*p)
         AddPathLine(25*p, 11.5*p)
         AddPathLine(20*p, 15*p)
         ClosePath()
         StrokePath(3*p, #PB_Path_RoundCorner)
         RestoreVectorState()
         AddPathEllipse(12*p, 8*p, 3*p, 6*p)
         StrokePath(p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Message (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32
      If ret
         VectorSourceColor(color1)
         DrawRoundBox(2*p, 2*p, 28*p, 28*p, 5*p)
         FillPath()
         VectorSourceColor(color2)
         AddPathEllipse(16*p, 16*p, 11*p, 9*p)
         FillPath()
         MovePathCursor(13*p, 24*p)
         AddPathLine(7*p, 27*p)
         AddPathLine(10*p, 22*p)
         ClosePath()
         FillPath()
         StrokePath(p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Macro ColourSegments()
      AddPathCircle(16*p, 9*p, 3.9*p, 180, 0)
      MovePathCursor(12.1*p, 9*p)
      AddPathLine(16*p, 15.8*p)
      AddPathLine(19.9*p, 9*p)
      ClosePath()
      FillPath()
   EndMacro

   Procedure.i Colours (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ;      color4: foreground color #4
      ;      color5: foreground color #5
      ;      color6: foreground color #6
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32
      If ret
         VectorSourceColor(color1)
         ColourSegments()
         VectorSourceColor(color2)
         RotateCoordinates(16*p, 16*p, 60)
         ColourSegments()
         VectorSourceColor(color3)
         RotateCoordinates(16*p, 16*p, 60)
         ColourSegments()
         VectorSourceColor(color4)
         RotateCoordinates(16*p, 16*p, 60)
         ColourSegments()
         VectorSourceColor(color5)
         RotateCoordinates(16*p, 16*p, 60)
         ColourSegments()
         VectorSourceColor(color6)
         RotateCoordinates(16*p, 16*p, 60)
         ColourSegments()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Navigation1 (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32
      If ret
         VectorSourceColor(color1)
         AddPathCircle(16*p, 16*p, 13*p)
         StrokePath(2*p)
         RotateCoordinates(16*p, 16*p, 45)
         MovePathCursor(16*p, 5*p)
         AddPathLine(12*p, 16*p)
         AddPathLine(16*p, 26*p)
         AddPathLine(20*p, 16*p)
         ClosePath()
         FillPath()
         VectorSourceColor(color2)
         AddPathCircle(16*p, 16*p, 2*p)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Navigation2 (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32
      If ret
         ; Outer circle
         VectorSourceColor(color1)
         AddPathCircle(16*p, 16*p, 8*p)
         StrokePath(3.5*p)
         AddPathCircle(16*p, 16*p, 3*p)
         StrokePath(2*p)
         ; NESW
         VectorSourceColor(color2)
         MovePathCursor(14*p, 13*p)
         AddPathLine(16*p, p)
         AddPathLine(18*p, 13*p)
         RotateCoordinates(16*p, 16*p, 90)
         MovePathCursor(14*p, 13*p)
         AddPathLine(16*p, p)
         AddPathLine(18*p, 13*p)
         RotateCoordinates(16*p, 16*p, 90)
         MovePathCursor(14*p, 13*p)
         AddPathLine(16*p, p)
         AddPathLine(18*p, 13*p)
         RotateCoordinates(16*p, 16*p, 90)
         MovePathCursor(14*p, 13*p)
         AddPathLine(16*p, p)
         AddPathLine(18*p, 13*p)
         ClosePath()
         FillPath()
         ; NwSwSeNe
         VectorSourceColor(color3)
         RotateCoordinates(16*p, 16*p, 45)
         MovePathCursor(14.5*p, 13*p)
         AddPathLine(16*p, 4*p)
         AddPathLine(17.5*p, 13*p)
         RotateCoordinates(16*p, 16*p, 90)
         MovePathCursor(14.5*p, 13*p)
         AddPathLine(16*p, 4*p)
         AddPathLine(17.5*p, 13*p)
         RotateCoordinates(16*p, 16*p, 90)
         MovePathCursor(14.5*p, 13*p)
         AddPathLine(16*p, 4*p)
         AddPathLine(17.5*p, 13*p)
         RotateCoordinates(16*p, 16*p, 90)
         MovePathCursor(14.5*p, 13*p)
         AddPathLine(16*p, 4*p)
         AddPathLine(17.5*p, 13*p)
         ClosePath()
         FillPath()

         ; Inner circle
         VectorSourceColor(color1)
         AddPathCircle(16*p, 16*p, 3*p)
         StrokePath(2*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Volume (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32
      If ret
         VectorSourceColor(color2)
         DrawRoundBox(5*p, 0, 22*p, size, 5*p)
         FillPath()
         VectorSourceColor(color1)
         DrawPlus(16*p, 5*p, 4*p, 1.5*p)
         MovePathCursor(8*p, 20*p)
         AddPathLine(24*p, 20*p)
         AddPathLine(24*p, 12*p)
         ClosePath()
         FillPath()
         DrawMinus(16*p, 27*p, 4*p, 1.5*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Secure (file$, img.i, size.i, color.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color)
         AddPathCircle(16*p, 18*p, 11*p, 0, 180)
         StrokePath(4*p)
         AddPathCircle(16*p, 4.5*p, 2.5*p)
         StrokePath(2*p)
         MovePathCursor(14.5*p, 7.5*p)
         AddPathLine(13*p, 27*p)
         AddPathLine(19*p, 27*p)
         AddPathLine(17.5*p, 7.5*p)
         ClosePath()
         FillPath()
         MovePathCursor(0.75*p, 20*p)
         AddPathLine(5*p, 16*p)
         AddPathLine(9.5*p, 20*p)
         ClosePath()
         FillPath()
         MovePathCursor(22.75*p, 20*p)
         AddPathLine(27*p, 16*p)
         AddPathLine(31*p, 20*p)
         ClosePath()
         FillPath()
         MovePathCursor(11*p, 13*p)
         AddPathLine(21*p, 13*p)
         StrokePath(3*p, #PB_Path_RoundEnd)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Book (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         ;Lower edge
         VectorSourceColor(color2)
         MovePathCursor(2*p, 14.5*p)
         AddPathLine(2*p, 20.5*p)
         AddPathLine(14*p, 30.5*p)
         AddPathLine(14*p, 24.5*p)
         ClosePath()
         FillPath()
         ;Front edge
         VectorSourceColor(color3)
         MovePathCursor(14*p, 24.5*p)
         AddPathLine(14*p, 30.5*p)
         AddPathLine(30.5*p, 16*p)
         AddPathLine(30.5*p, 10*p)
         ClosePath()
         FillPath()
         ;Front Cover
         VectorSourceColor(color1)
         MovePathCursor(14*p, 24.5*p)
         AddPathLine(31*p, 10*p)
         AddPathLine(18*p, p)
         AddPathLine(1.6*p, 14*p)
         ClosePath()
         FillPath()
         ;Back cover edges
         MovePathCursor(2*p, 14*p)
         AddPathLine(2*p, 20.5*p)
         AddPathLine(14*p, 30.5*p)
         AddPathLine(31*p, 16*p)
         StrokePath(p)
         VectorSourceColor(color2)
         MovePathCursor(15*p, 7.1*p)
         AddPathLine(23*p, 13.2*p)
         StrokePath(2.0*p, #PB_Path_RoundEnd)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Library (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ;      color4: foreground color #4
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         ; Bookcase
         VectorSourceColor(color1)
         MovePathCursor(p, 12*p)
         AddPathLine(p, 31*p)
         AddPathLine(31*p, 31*p)
         AddPathLine(31*p, 12*p)
         StrokePath(2*p)

         ; Book1
         VectorSourceColor(color2)
         AddPathBox(3.5*p, 8*p, 5*p, 21.9*p)
         FillPath()

         ; Book2
         AddPathBox(10*p, 7*p, 5*p, 22.9*p)
         FillPath()
         SaveVectorState()

         ; Book3
         RotateCoordinates(18.5*p, 16*p, -23.5)
         AddPathBox(18.5*p, 7.3*p, 5*p, 24*p)
         FillPath()
         RestoreVectorState()

         ; Spine/cover 'hinge' book1
         VectorSourceColor(color3)
         MovePathCursor(4*p, 8*p)
         AddPathLine(4*p, 29.9*p)
         MovePathCursor(8*p, 8*p)
         AddPathLine(8*p, 29.9*p)

         ; Spine/cover 'hinge' book2
         MovePathCursor(10.5*p, 7*p)
         AddPathLine(10.5*p, 29.9*p)
         MovePathCursor(14.5*p, 7*p)
         AddPathLine(14.5*p, 29.9*p)

         ; Spine/cover 'hinge' book3
         SaveVectorState()
         RotateCoordinates(18.5*p, 16*p, -23.5)
         MovePathCursor(19*p, 7.3*p)
         AddPathLine(19*p, 31.2*p)
         MovePathCursor(23*p, 7.3*p)
         AddPathLine(23*p, 31.2*p)
         StrokePath(0.25*p)
         RestoreVectorState()

         ; Add labels
         VectorSourceColor(color4)
         MovePathCursor(6*p, 12*p)
         AddPathLine(6*p, 18*p)
         MovePathCursor(12.5*p, 12*p)
         AddPathLine(12.5*p, 18*p)
         RotateCoordinates(18.5*p, 16*p, -23.5)
         MovePathCursor(21*p, 12*p)
         AddPathLine(21*p, 18*p)
         StrokePath(p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i USB (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color)
         AddPathCircle(4*p, 16*p, 3*p)
         AddPathCircle(20*p, 11*p, 2*p)
         AddPathBox(23*p, 20*p, 4*p, 4*p)
         ;Triangle
         MovePathCursor(27*p, 13*p)
         AddPathLine(31*p, 16*p)
         AddPathLine(27*p, 19*p)
         ClosePath()
         FillPath()
         MovePathCursor(6*p, 16*p)
         AddPathLine(29*p, 16*p)
         MovePathCursor(10*p, 16*p)
         AddPathLine(14*p, 11*p)
         AddPathLine(19*p, 11*p)
         MovePathCursor(14*p, 16*p)
         AddPathLine(19*p, 22*p)
         AddPathLine(23*p, 22*p)
         StrokePath(p, #PB_Path_RoundCorner)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_WhitePawn (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         MovePathCursor(4*p, 31*p)
         AddPathLine(28*p, 31*p)
         AddPathLine(28*p, 22*p)
         AddPathCircle(16*p, 31*p, 15*p, 217, 251)
         AddPathCircle(16*p, 31*p, 15*p, 289, 323)
         MovePathCursor(4*p, 22*p)
         AddPathLine(4*p, 31*p)
         AddPathLine(6*p, 31*p)
         AddPathCircle(16*p, 13*p, 6*p, 142, 233)
         AddPathCircle(16*p, 13*p, 6*p, 305, 39)
         AddPathCircle(16*p, 6*p, 4*p, 150, 30)
         StrokePath(p, #PB_Path_RoundCorner | #PB_Path_RoundEnd)
         ; Fill in white
         VectorSourceColor(color2)
         AddPathBox(4*p, 21.9*p, 24*p, 9*p)
         FillPath()
         AddPathCircle(16*p, 31*p, 15*p, 217, 323)
         ClosePath()
         FillPath()
         AddPathCircle(16*p, 13*p, 6*p)
         FillPath()
         AddPathCircle(16*p, 6*p, 4*p)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_BlackPawn (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color #1
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color)
         MovePathCursor(4*p, 31*p)
         AddPathLine(28*p, 31*p)
         AddPathLine(28*p, 22*p)
         AddPathCircle(16*p, 31*p, 15*p, 217, 323)
         MovePathCursor(4*p, 22*p)
         AddPathLine(4*p, 31*p)
         AddPathLine(6*p, 31*p)
         AddPathCircle(16*p, 13*p, 6*p)
         AddPathCircle(16*p, 6*p, 4*p)
         StrokePath(0.5*p, #PB_Path_RoundCorner | #PB_Path_RoundEnd)
         ; Fill in black
         AddPathBox(4*p, 21.9*p, 24*p, 9*p)
         FillPath()
         AddPathCircle(16*p, 31*p, 15*p, 217, 323)
         ClosePath()
         FillPath()
         AddPathCircle(16*p, 13*p, 6*p)
         FillPath()
         AddPathCircle(16*p, 6*p, 4*p)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_WhiteRook (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         AddPathBox(11*p, 10*p, 10*p, 10*p)
         AddPathBox(5*p, 28*p, 22*p, 3*p)
         MovePathCursor(11*p, 20*p)
         AddPathLine(8*p, 24*p)
         AddPathLine(8*p, 28*p)
         MovePathCursor(21*p, 20*p)
         AddPathLine(24*p, 24*p)
         AddPathLine(24*p, 28*p)
         MovePathCursor(8*p, 24*p)
         AddPathLine(24*p, 24*p)
         ;Add in the castellations
         MovePathCursor(11*p, 10*p)
         AddPathLine(7*p, 7*p)
         AddPathLine(7*p, 2*p)
         AddPathLine(11*p, 2*p)
         AddPathLine(11*p, 4*p)
         AddPathLine(14*p, 4*p)
         AddPathLine(14*p, 2*p)
         AddPathLine(18*p, 2*p)
         AddPathLine(18*p, 4*p)
         AddPathLine(21*p, 4*p)
         AddPathLine(21*p, 2*p)
         AddPathLine(25*p, 2*p)
         AddPathLine(25*p, 7*p)
         AddPathLine(21*p, 10*p)
         MovePathCursor(7*p, 7*p)
         AddPathLine(25*p, 7*p)
         StrokePath(p)

         StrokePath(0.5*p)
         ;Fill in with white
         VectorSourceColor(color2)
         AddPathBox(11*p, 10*p, 10*p, 10*p)
         AddPathBox(5*p, 28*p, 22*p, 3*p)
         AddPathBox(8*p, 24*p, 16*p, 4*p)
         MovePathCursor(8*p, 24*p)
         AddPathLine(11*p, 20*p)
         AddPathLine(21*p, 20*p)
         AddPathLine(24*p, 24*p)
         ClosePath()
         MovePathCursor(11*p, 10*p)
         AddPathLine(7*p, 7*p)
         AddPathLine(7*p, 2*p)
         AddPathLine(11*p, 2*p)
         AddPathLine(11*p, 4*p)
         AddPathLine(14*p, 4*p)
         AddPathLine(14*p, 2*p)
         AddPathLine(18*p, 2*p)
         AddPathLine(18*p, 4*p)
         AddPathLine(21*p, 4*p)
         AddPathLine(21*p, 2*p)
         AddPathLine(25*p, 2*p)
         AddPathLine(25*p, 7*p)
         AddPathLine(21*p, 10*p)
         FillPath()
         ;Add Lines to add 3d look
         VectorSourceColor(color1)
         MovePathCursor(8*p, 27.5*p)
         AddPathLine(24*p, 27.5*p)
         MovePathCursor(8.25*p, 23.5*p)
         AddPathLine(23.75*p, 23.5*p)
         MovePathCursor(11*p, 19.5*p)
         AddPathLine(21*p, 19.5*p)
         MovePathCursor(11*p, 10.5*p)
         AddPathLine(21*p, 10.5*p)
         MovePathCursor(7*p, 7*p)
         AddPathLine(25*p, 7*p)
         StrokePath(0.5*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_BlackRook (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         AddPathBox(11*p, 10*p, 10*p, 10*p)
         AddPathBox(5*p, 28*p, 22*p, 3*p)
         MovePathCursor(11*p, 20*p)
         AddPathLine(8*p, 24*p)
         AddPathLine(8*p, 28*p)
         MovePathCursor(21*p, 20*p)
         AddPathLine(24*p, 24*p)
         AddPathLine(24*p, 28*p)
         MovePathCursor(8*p, 24*p)
         AddPathLine(24*p, 24*p)
         ; Add in the castellations
         MovePathCursor(11*p, 10*p)
         AddPathLine(7*p, 7*p)
         AddPathLine(7*p, 2*p)
         AddPathLine(11*p, 2*p)
         AddPathLine(11*p, 4*p)
         AddPathLine(14*p, 4*p)
         AddPathLine(14*p, 2*p)
         AddPathLine(18*p, 2*p)
         AddPathLine(18*p, 4*p)
         AddPathLine(21*p, 4*p)
         AddPathLine(21*p, 2*p)
         AddPathLine(25*p, 2*p)
         AddPathLine(25*p, 7*p)
         AddPathLine(21*p, 10*p)
         StrokePath(0.5*p)
         ; Fill in with black
         AddPathBox(11*p, 10*p, 10*p, 10*p)
         AddPathBox(5*p, 28*p, 22*p, 3*p)
         AddPathBox(8*p, 24*p, 16*p, 4*p)
         MovePathCursor(8*p, 24*p)
         AddPathLine(11*p, 20*p)
         AddPathLine(21*p, 20*p)
         AddPathLine(24*p, 24*p)
         ClosePath()
         MovePathCursor(11*p, 10*p)
         AddPathLine(7*p, 7*p)
         AddPathLine(7*p, 2*p)
         AddPathLine(11*p, 2*p)
         AddPathLine(11*p, 4*p)
         AddPathLine(14*p, 4*p)
         AddPathLine(14*p, 2*p)
         AddPathLine(18*p, 2*p)
         AddPathLine(18*p, 4*p)
         AddPathLine(21*p, 4*p)
         AddPathLine(21*p, 2*p)
         AddPathLine(25*p, 2*p)
         AddPathLine(25*p, 7*p)
         AddPathLine(21*p, 10*p)
         FillPath()
         ; Add Lines to add 3d look
         VectorSourceColor(color2)
         MovePathCursor(8*p, 27.5*p)
         AddPathLine(24*p, 27.5*p)
         MovePathCursor(8.25*p, 23.5*p)
         AddPathLine(23.75*p, 23.5*p)
         MovePathCursor(11*p, 19.5*p)
         AddPathLine(21*p, 19.5*p)
         MovePathCursor(11*p, 10.5*p)
         AddPathLine(21*p, 10.5*p)
         MovePathCursor(7*p, 7*p)
         AddPathLine(25*p, 7*p)
         StrokePath(p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_WhiteKnight (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         ;Draw the body
         VectorSourceColor(color1)
         AddPathCircle(32*p, 32*p, 21.75*p, 183, 222)
         AddPathLine(PathCursorX(), 13*p)
         AddPathLine(12*p, 18*p)
         AddPathLine(6.7*p, 23*p)
         AddPathLine(6.7*p, 20*p)
         AddPathCircle(4.5*p, 19*p, 2.5*p, 25, 235, #PB_Path_Connected)
         AddPathLine(7*p, 12*p)
         AddPathLine(7*p, 8*p)
         AddPathLine(9*p, 7*p)
         AddPathLine(9*p, 3*p)
         AddPathLine(12*p, 5.7*p)
         AddPathLine(14*p, 2*p)
         AddPathLine(16*p, 5.7*p)
         AddPathCircle(p, 31*p, 29.5*p, 301.5, 0, #PB_Path_Connected)
         AddPathLine(10.25*p, PathCursorY())
         StrokePath(p, #PB_Path_RoundCorner | #PB_Path_RoundEnd)

         ; Fill in body
         VectorSourceColor(color2)
         AddPathCircle(32*p, 32*p, 21.75*p, 183, 222)
         AddPathLine(PathCursorX(), 13*p)
         AddPathLine(12*p, 18*p)
         AddPathLine(6.7*p, 23*p)
         AddPathLine(6.7*p, 20*p)
         AddPathCircle(4.5*p, 19*p, 2.5*p, 25, 235, #PB_Path_Connected)
         AddPathLine( 7*p, 12*p)
         AddPathLine( 7*p, 8*p)
         AddPathLine( 9*p, 7*p)
         AddPathLine( 9*p, 3*p)
         AddPathLine(12*p, 5.7*p)
         AddPathLine(14*p, 2*p)
         AddPathLine(16*p, 5.7*p)
         AddPathCircle(p, 31*p, 29.5*p, 301.5, 0, #PB_Path_Connected)
         AddPathLine(10.25*p, PathCursorY())
         FillPath()
         ;Add in 'Mane'
         VectorSourceColor(color1)
         AddPathCircle(p, 31*p, 27.5*p, 320, 350)
         DashPath(0.5*p, p, #PB_Path_RoundEnd)
         ;Add in Eye and Nostril
         MovePathCursor(4*p, 19*p)
         AddPathLine(4*p, 19.5*p)
         StrokePath(1.5*p, #PB_Path_RoundCorner | #PB_Path_RoundEnd)
         AddPathEllipse(9*p, 11*p, p, p)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_BlackKnight (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         ;Draw the body
         VectorSourceColor(color1)
         AddPathCircle(32*p, 32*p, 21.75*p, 183, 222)
         AddPathLine(PathCursorX(), 13*p)
         AddPathLine(12*p, 18*p)
         AddPathLine(6.7*p, 23*p)
         AddPathLine(6.7*p, 20*p)
         AddPathCircle(4.5*p, 19*p, 2.5*p, 25, 235, #PB_Path_Connected)
         AddPathLine(7*p, 12*p)
         AddPathLine(7*p, 8*p)
         AddPathLine(9*p, 7*p)
         AddPathLine(9*p, 3*p)
         AddPathLine(12*p, 5.7*p)
         AddPathLine(14*p, 2*p)
         AddPathLine(16*p, 5.7*p)
         AddPathCircle(p, 31*p, 29.5*p, 301.5, 0, #PB_Path_Connected)
         AddPathLine(10.25*p, PathCursorY())
         StrokePath(p, #PB_Path_RoundCorner | #PB_Path_RoundEnd)

         ;Fill in body
         AddPathCircle(32*p, 32*p, 21.75*p, 183, 222)
         AddPathLine(PathCursorX(), 13*p)
         AddPathLine(12*p, 18*p)
         AddPathLine(6.7*p, 23*p)
         AddPathLine(6.7*p, 20*p)
         AddPathCircle(4.5*p, 19*p, 2.5*p, 25, 235, #PB_Path_Connected)
         AddPathLine(7*p, 12*p)
         AddPathLine(7*p, 8*p)
         AddPathLine(9*p, 7*p)
         AddPathLine(9*p, 3*p)
         AddPathLine(12*p, 5.7*p)
         AddPathLine(14*p, 2*p)
         AddPathLine(16*p, 5.7*p)
         AddPathCircle(p, 31*p, 29.5*p, 301.5, 0, #PB_Path_Connected)
         AddPathLine(10.25*p, PathCursorY())
         FillPath()
         ;Add in 'Mane'
         VectorSourceColor(color2)
         AddPathCircle(p, 31*p, 27.5*p, 320, 350)
         DashPath(0.5*p, p, #PB_Path_RoundEnd)
         ;Add in Eye and Nostril
         MovePathCursor(4*p, 19*p)
         AddPathLine(4*p, 19.5*p)
         StrokePath(1.5*p, #PB_Path_RoundCorner | #PB_Path_RoundEnd)
         AddPathEllipse(9*p, 11*p, p, p)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_WhiteBishop (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         ;Feet
         VectorSourceColor(color1)
         AddPathCircle(10*p, 25*p, 5.5*p, 360, 150)
         AddPathLine(2*p, 27.8*p)
         MovePathCursor(30*p, 27.8*p)
         AddPathLine(27*p, 27.8*p)
         AddPathCircle(22*p, 25*p, 5.5*p, 30, 180)
         StrokePath(2.5*p, #PB_Path_RoundCorner | #PB_Path_RoundEnd)
         VectorSourceColor(color2)
         AddPathCircle(10*p, 25*p, 5.5*p, 350, 150)
         AddPathLine(2*p, 27.8*p)
         MovePathCursor(30*p, 27.8*p)
         AddPathLine(27*p, 27.8*p)
         AddPathCircle(22*p, 25*p, 5.5*p, 30, 190)
         StrokePath(1.5*p, #PB_Path_RoundCorner | #PB_Path_RoundEnd)
         ;Base
         VectorSourceColor(color1)
         AddPathCircle(16*p, 24*p, 6*p, 180, 360)
         ClosePath()
         StrokePath(p)
         VectorSourceColor(color2)
         AddPathCircle(16*p, 24*p, 6*p, 180, 360)
         ClosePath()
         FillPath()
         ;body
         VectorSourceColor(color1)
         AddPathCircle(16*p, 13*p, 7*p, 120, 60)
         StrokePath(p)
         VectorSourceColor(color2)
         AddPathCircle(16*p, 13*p, 7*p, 120, 60)
         FillPath()
         VectorSourceColor(color1)
         AddPathEllipse(16*p, 3.5*p, 2*p, 2.5*p)
         StrokePath(p)
         VectorSourceColor(color2)
         AddPathEllipse(16*p, 3.5*p, 2*p, 2.5*p)
         FillPath()
         VectorSourceColor(color1)
         DrawPlus(16*p, 12.5*p, 3*p, 1.3*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_BlackBishop (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         ;Feet
         VectorSourceColor(color1)
         AddPathCircle(10*p, 25*p, 5.5*p, 360, 150)
         AddPathLine(2*p, 27.8*p)
         MovePathCursor(30*p, 27.8*p)
         AddPathLine(27*p, 27.8*p)
         AddPathCircle(22*p, 25*p, 5.5*p, 30, 180)
         StrokePath(2.5*p, #PB_Path_RoundCorner | #PB_Path_RoundEnd)
         ;Base
         VectorSourceColor(color1)
         AddPathCircle(16*p, 24.5*p, 6.5*p, 180, 360)
         ClosePath()
         FillPath()
         ;body
         AddPathCircle(16*p, 13*p, 7*p, 120, 60)
         AddPathEllipse(16*p, 3.5*p, 2*p, 2.5*p)
         FillPath()

         VectorSourceColor(color2)
         DrawPlus(16*p, 12.5*p, 3*p, 2*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_WhiteKing (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         ;Body - right side
         VectorSourceColor(color1)
         SaveVectorState()
         RotateCoordinates(16*p, 25*p, 45)
         AddPathEllipse(16*p, 16*p, 5*p, 8*p)
         StrokePath(0.5*p)
         VectorSourceColor(color2)
         AddPathEllipse(16*p, 16*p, 5*p, 8*p)
         FillPath()
         VectorSourceColor(color1)
         AddPathEllipse(16*p, 16*p, 3*p, 6*p)
         StrokePath(0.5*p)
         ;Body - left side
         VectorSourceColor(color1)
         RotateCoordinates(16*p, 25*p, -90)
         AddPathEllipse(16*p, 16*p, 5*p, 8*p)
         StrokePath(0.5*p)
         VectorSourceColor(color2)
         AddPathEllipse(16*p, 16*p, 5*p, 8*p)
         FillPath()
         VectorSourceColor(color1)
         AddPathEllipse(16*p, 16*p, 3*p, 6*p)
         StrokePath(0.5*p)
         RestoreVectorState()
         VectorSourceColor(color2)
         AddPathBox(14.75*p, 19*p, 2*p, 3*p)
         FillPath()

         ;Base
         VectorSourceColor(color1)
         AddPathBox(6*p, 22*p, 20*p, 8*p)
         StrokePath(0.5*p)
         VectorSourceColor(color2)
         AddPathBox(6*p, 22*p, 20*p, 8*p)
         FillPath()
         ;Base decoration
         VectorSourceColor(color1)
         DrawPlus(10*p, 25*p, 1.5*p, p)
         DrawPlus(16*p, 25*p, 1.5*p, p)
         DrawPlus(22*p, 25*p, 1.5*p, p)
         MovePathCursor(7*p, 28.5*p)
         AddPathLine(25*p, 28.5*p)
         StrokePath(0.5*p)
         ;Top
         VectorSourceColor(color1)
         AddPathCircle(16*p, 11.5*p, 4.5*P)
         FillPath()
         VectorSourceColor(color2)
         AddPathCircle(16*p, 11.5*p, 4*P)
         FillPath()
         VectorSourceColor(color1)
         AddPathCircle(16*p, 11.5*p, 2.5*P)
         StrokePath(0.5*p)
         DrawPlus(16*p, 5*p, 2.5*p, 1.5*p)
         VectorSourceColor(color2)
         DrawPlus(16*p, 5*p, 2.0*p, 0.5*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_BlackKing (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         SaveVectorState()
         RotateCoordinates(16*p, 25*p, 45)
         AddPathEllipse(16*p, 16*p, 5*p, 8*p)
         FillPath()
         VectorSourceColor(color2)
         AddPathEllipse(16*p, 16*p, 3*p, 6*p)
         StrokePath(p)
         VectorSourceColor(color1)
         RotateCoordinates(16*p, 25*p, -90)
         AddPathEllipse(16*p, 16*p, 5*p, 8*p)
         FillPath()
         VectorSourceColor(color2)
         AddPathEllipse(16*p, 16*p, 3*p, 6*p)
         StrokePath(p)

         ;Base
         RestoreVectorState()
         VectorSourceColor(color1)
         AddPathBox(6*p, 22*p, 20*p, 8*p)
         FillPath()
         VectorSourceColor(color1)
         AddPathBox(6*p, 22*p, 20*p, 8*p)
         StrokePath(p)
         ;Base decoration
         VectorSourceColor(color2)
         DrawPlus(10*p, 25*p, 2*p, p)
         DrawPlus(16*p, 25*p, 2*p, p)
         DrawPlus(22*p, 25*p, 2*p, p)

         MovePathCursor(7*p, 28.5*p)
         AddPathLine(25*p, 28.5*p)
         StrokePath(p)
         ;Top
         VectorSourceColor(color1)
         AddPathCircle(16*p, 11.5*p, 4.75*P)
         FillPath()
         VectorSourceColor(color2)
         AddPathCircle(16*p, 11.5*p, 2.5*P)
         StrokePath(0.5*p)
         VectorSourceColor(color1)
         DrawPlus(16*p, 5*p, 2.5*p, 1.5*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_WhiteQueen (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         ;Base
         VectorSourceColor(color1)
         AddPathBox(7*p, 22*p, 18*p, 8*p)
         MovePathCursor(7*p, 28*p)
         AddPathLine(25*p, 28*p)
         StrokePath(p)
         ;Body of crown
         VectorSourceColor(color1)
         MovePathCursor(7.2*p, 22.3*p)
         AddPathLine(3.5*p, 8.75*p)
         AddPathLine(8*p, 17*p)
         AddPathLine(9*p, 6.5*p)
         AddPathLine(13*p, 16*p)
         AddPathLine(16*p, 6*p)
         AddPathLine(19*p, 16*p)
         AddPathLine(22.5*p, 7*p)
         AddPathLine(24*p, 17*p)
         AddPathLine(28*p, 9*p)
         AddPathLine(25*p, 22*p)
         StrokePath(p)
         VectorSourceColor(color2)
         MovePathCursor(7.2*p, 22.3*p)
         AddPathLine(3.5*p, 8.75*p)
         AddPathLine(8*p, 17*p)
         AddPathLine(9*p, 6.5*p)
         AddPathLine(13*p, 16*p)
         AddPathLine(16*p, 6*p)
         AddPathLine(19*p, 16*p)
         AddPathLine(22.5*p, 7*p)
         AddPathLine(24*p, 17*p)
         AddPathLine(28*p, 9*p)
         AddPathLine(25*p, 22*p)
         FillPath()
         ;Tips of crown
         VectorSourceColor(color1)
         AddPathCircle( 3*p, 7*p, 2*p)
         AddPathCircle( 9*p, 5*p, 2*p)
         AddPathCircle(16*p, 4*p, 2*p)
         AddPathCircle(23*p, 5*p, 2*p)
         AddPathCircle(29*p, 7*p, 2*p)
         StrokePath(p)
         VectorSourceColor(color2)
         AddPathCircle( 3*p, 7*p, 2*p)
         AddPathCircle( 9*p, 5*p, 2*p)
         AddPathCircle(16*p, 4*p, 2*p)
         AddPathCircle(23*p, 5*p, 2*p)
         AddPathCircle(29*p, 7*p, 2*p)
         FillPath()
         ;Base decoration
         VectorSourceColor(color1)
         MovePathCursor(7*p, 20*p)
         AddPathLine(25*p, 20*p)
         StrokePath(p)

         MovePathCursor(16*p, 24*p)
         AddPathLine(18*p, 25*p)
         AddPathLine(16*p, 26*p)
         AddPathLine(14*p, 25*p)
         ClosePath()

         MovePathCursor(10*p, 24*p)
         AddPathLine(12*p, 25*p)
         AddPathLine(10*p, 26*p)
         AddPathLine(8*p, 25*p)
         ClosePath()

         MovePathCursor(22*p, 24*p)
         AddPathLine(24*p, 25*p)
         AddPathLine(22*p, 26*p)
         AddPathLine(20*p, 25*p)
         ClosePath()
         FillPath()
         StopVectorDrawing()

      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Chess_BlackQueen (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         AddPathBox(6.5*p, 21.5*p, 19*p, 9*p)
         FillPath()
         ;Tips of crown
         VectorSourceColor(color1)
         AddPathCircle( 3*p, 7*p, 2.5*p)
         AddPathCircle( 9*p, 5*p, 2.5*p)
         AddPathCircle(16*p, 4*p, 2.5*p)
         AddPathCircle(23*p, 5*p, 2.5*p)
         AddPathCircle(29*p, 7*p, 2.5*p)
         FillPath()
         ;Body of crown
         VectorSourceColor(color1)
         MovePathCursor(7.2*p, 22.3*p)
         AddPathLine(3.5*p, 8.75*p)
         AddPathLine(8*p, 17*p)
         AddPathLine(9*p, 6.5*p)
         AddPathLine(13*p, 16*p)
         AddPathLine(16*p, 6*p)
         AddPathLine(19*p, 16*p)
         AddPathLine(22.5*p, 7*p)
         AddPathLine(24*p, 17*p)
         AddPathLine(28*p, 9*p)
         AddPathLine(25*p, 22*p)
         StrokePath(p)
         MovePathCursor(7.2*p, 22.3*p)
         AddPathLine(3.5*p, 8.75*p)
         AddPathLine( 8*p, 17*p)
         AddPathLine( 9*p, 6.5*p)
         AddPathLine(13*p, 16*p)
         AddPathLine(16*p, 6*p)
         AddPathLine(19*p, 16*p)
         AddPathLine(22.5*p, 7*p)
         AddPathLine(24*p, 17*p)
         AddPathLine(28*p, 9*p)
         AddPathLine(25*p, 22*p)
         FillPath()
         ;Base decoration
         VectorSourceColor(color2)
         MovePathCursor(7*p, 20*p)
         AddPathLine(25*p, 20*p)
         MovePathCursor(7*p, 29*p)
         AddPathLine(25*p, 29*p)
         StrokePath(1.3*p)
         MovePathCursor(16*p, 24*p)
         AddPathLine(18*p, 25*p)
         AddPathLine(16*p, 26*p)
         AddPathLine(14*p, 25*p)
         ClosePath()

         MovePathCursor(10*p, 24*p)
         AddPathLine(12*p, 25*p)
         AddPathLine(10*p, 26*p)
         AddPathLine(8*p, 25*p)
         ClosePath()

         MovePathCursor(22*p, 24*p)
         AddPathLine(24*p, 25*p)
         AddPathLine(22*p, 26*p)
         AddPathLine(20*p, 25*p)
         ClosePath()
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i History (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ;      color4: foreground color #4
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         ;White centre
         VectorSourceColor(color4)
         AddPathCircle(16*p, 16*p, 13*p)
         FillPath()
         VectorSourceColor(color2)
         AddPathCircle(16*p, 16*p, 13*p, 270, 150)
         StrokePath(3*p)
         ;Minutehand
         MovePathCursor(13*p, 17*p)
         AddPathLine(19*p, 17*p)
         AddPathLine(16*p, 6*p)
         ClosePath()
         FillPath()
         ;Hourhand
         MovePathCursor(13.5*p, 13.5*p)
         AddPathLine(13.5*p, 18.5*p)
         AddPathLine(24*p, 16*p)
         ClosePath()
         FillPath()
         AddPathCircle(16*p, 16*p, 3.5*p)
         FillPath()
         VectorSourceColor(color3)
         AddPathCircle(16*p, 16*p, 13*p, 150, 270)
         StrokePath(3*p)
         MovePathCursor(7.5*p, 22*p)
         AddPathLine(2.75*p, 23.5*p)
         AddPathLine(6.25*p, 24.55*p)
         ClosePath()
         FillPath()
         MovePathCursor(7.5*p, 21.25 *p)
         AddPathLine(2.5*p, 23.5*p)
         AddPathLine(6.25*p, 24.25*p)
         ClosePath()
         StrokePath(1.2*p)
         VectorSourceColor(color1)
         AddPathCircle(16*p, 16*p, 1.5*p)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Danger (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         AddPathCircle(16*p, 8*p, 7*p, 200, 340)
         AddPathLine(PathCursorX(), 12*p)
         AddPathLine(20*p, 15*p)
         AddPathLine(19*p, 17*p)
         AddPathLine(13*p, 17*p)
         AddPathLine(12*p, 15*p)
         AddPathLine(9.5*p, 12*p)
         AddPathLine(9.5*p, 5*p)
         StrokePath(2*p, #PB_Path_RoundCorner)
         AddPathCircle(16*p, 8*p, 7*p, 200, 340)
         AddPathLine(PathCursorX(), 12*p)
         AddPathLine(20*p, 15*p)
         AddPathLine(19*p, 17*p)
         AddPathLine(13*p, 17*p)
         AddPathLine(12*p, 15*p)
         AddPathLine(9.5*p, 12*p)
         AddPathLine(9.5*p, 5*p)
         FillPath()
         ;Eyes and Nose
         VectorSourceColor(color2)
         AddPathEllipse(12.5*p, 9*p, 2.5*p, 1.5*p)
         AddPathEllipse(20*p, 9*p, 2.5*p, 1.5*p)
         AddPathEllipse(16*p, 14*p, 1.2*p, 2*p)
         FillPath()
         ;Crossed bones
         VectorSourceColor(color1)
         RotateCoordinates(16*p, 22*p, 25)
         MovePathCursor(4*p, 22*p)
         AddPathLine(29*p, 22*p)
         StrokePath(3*p)
         AddPathCircle(4*p, 20.5*p, 1.5*p)
         AddPathCircle(29*p, 20.5*p, 1.5*p)
         FillPath()
         AddPathCircle(4*p, 23.5*p, 2*p)
         AddPathCircle(29*p, 23.5*p, 2*p)
         FillPath()
         RotateCoordinates(16*p, 22*p, -50)
         MovePathCursor(4*p, 22*p)
         AddPathLine(29*p, 22*p)
         StrokePath(3*p)
         AddPathCircle(4*p, 20.5*p, 1.5*p)
         AddPathCircle(29*p, 20.5*p, 1.5*p)
         FillPath()
         AddPathCircle(4*p, 23.5*p, 2*p)
         AddPathCircle(29*p, 23.5*p, 2*p)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i TheSun (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, M.i

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         FillVectorOutput()
         VectorSourceColor(color2)
         AddPathCircle(16*p, 16*p, 7*p)
         FillPath()
         For M = 1 To 10
            MovePathCursor(16*p, 3*p)
            AddPathLine(16*p, 8*p)
            RotateCoordinates(16*p, 16*p, 36)
         Next M
         StrokePath(2*p, #PB_Path_RoundEnd)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i GoodLuck (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, M.i

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         VectorSourceColor(color2)
         MovePathCursor(14*p, 16*p)
         AddPathLine(17*p, 31*p)
         StrokePath(2*p)
         VectorSourceColor(color1)
         For M = 1 To 12
            RotateCoordinates(16*p, 16*p, 30)
            If M % 3 <> 0
               AddPathEllipse(16*p, 8.5*p, 4.5*p, 7.5*p)
               FillPath()
            EndIf
         Next M
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Telephone (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         ; Receiver
         MovePathCursor(4*p, 5*p)
         AddPathLine(28*p, 5*p)
         AddPathLine(28*p, 8*p)
         AddPathLine(26*p, 8*p)
         AddPathLine(26*p, 5*p)
         AddPathLine(7*p, 5*p)
         AddPathLine(7*p, 8*p)
         AddPathLine(4*p, 8*p)
         ClosePath()

         ; Body
         MovePathCursor(12*p, 16*p)
         AddPathLine(4*p, 25*p)
         AddPathLine(4*p, 28*p)
         AddPathLine(28*p, 28*p)
         AddPathLine(28*p, 25*p)
         AddPathLine(20*p, 16*p)
         ClosePath()
         FillPath(#PB_Path_Preserve)
         StrokePath(7*p, #PB_Path_RoundCorner)
         MovePathCursor(12.5*p, 11*p)
         AddPathLine(12.5*p, 16*p)
         SaveVectorState()
         FlipCoordinatesX(15.75*p)
         MovePathCursor(12*p, 11*p)
         AddPathLine(12*p, 16.5*p)
         StrokePath(3*p, #PB_Path_RoundEnd)
         ; Keys
         RestoreVectorState()
         VectorSourceColor(color2)
         AddPathBox(9*p, 16.5*p, 2.5*p, 1.25*p)
         AddPathBox(14.5*p, 16.5*p, 2.5*p, 1.25*p)
         AddPathBox(20*p, 16.5*p, 2.5*p, 1.25*p)
         AddPathBox(9*p, 21.5*p, 2.5*p, 1.25*p)
         AddPathBox(14.5*p, 21.5*p, 2.5*p, 1.25*p)
         AddPathBox(20*p, 21.5*p, 2.5*p, 1.25*p)
         AddPathBox(9*p, 26.5*p, 2.5*p, 1.25*p)
         AddPathBox(14.5*p, 26.5*p, 2.5*p, 1.25*p)
         AddPathBox(20*p, 26.5*p, 2.5*p, 1.25*p)
         FillPath(#PB_Path_Preserve)
         StrokePath(2*p, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i BlueTooth (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color)
         MovePathCursor(7*p, 23*p)
         AddPathLine(25*p, 9*p)
         AddPathLine(16*p, 2*p)
         AddPathLine(16*p, 30*p)
         AddPathLine(25*p, 23*p)
         AddPathLine(7*p, 9*p)
         StrokePath(2*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Broadcast (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color)
         MovePathCursor(9*p, 29*p)
         AddPathLine(23*p, 29*p)
         StrokePath(3*p, #PB_Path_RoundEnd)
         MovePathCursor(16*p, 8*p)
         AddPathLine(13*p, 29*P)
         AddPathLine(19*p, 29*p)
         ClosePath()
         FillPath()
         StrokePath(3*p, #PB_Path_RoundEnd)
         AddPathCircle(16*p, 8*p, 3*p)
         FillPath()
         AddPathCircle(16*p, 8*p, 6*p, 330, 30)
         AddPathCircle(16*p, 8*p, 10*p, 330, 30)
         AddPathCircle(16*p, 8*p, 14*p, 330, 30)
         FlipCoordinatesX(16*p)
         AddPathCircle(16*p, 8*p, 6*p, 330, 30)
         AddPathCircle(16*p, 8*p, 10*p, 330, 30)
         AddPathCircle(16*p, 8*p, 14*p, 330, 30)
         StrokePath(2*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Speaker (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color)
         MovePathCursor(p, 12*p)
         AddPathLine(p, 21*p)
         AddPathLine(8*p, 21*p)
         AddPathLine(14*p, 26*p)
         AddPathLine(14*p, 7*p)
         AddPathLine(8*p, 12*p)
         ClosePath()
         FillPath()
         AddPathCircle(8*p, 16*p, 13*p, 320, 40)
         AddPathCircle(8*p, 16*p, 18*p, 320, 40)
         AddPathCircle(8*p, 16*p, 23*p, 320, 40)
         StrokePath(2*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Mute (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         MovePathCursor(p, 12*p)
         AddPathLine(p, 21*p)
         AddPathLine(8*p, 21*p)
         AddPathLine(14*p, 26*p)
         AddPathLine(14*p, 7*p)
         AddPathLine(8*p, 12*p)
         ClosePath()
         FillPath()
         VectorSourceColor(color2)
         RotateCoordinates(23*p, 16*p, 45)
         DrawPlus(23*p, 16*p, 8*p, 2*p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i BatteryCharging (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         DrawRoundBox(14*p, 4*p, 4*p, 3*p, p)
         FillPath()
         VectorSourceColor(color2)
         DrawRoundBox(9*p, 6*p, 14*p, 24*p, 2*p)
         FillPath()
         VectorSourceColor(color3)
         DrawFlash(16*p, 18*p, 18*p)
         FillPath()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Snowflake (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, M.i

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color)
         For M = 1 To 6
            MovePathCursor(16*p, 16*p)
            AddPathLine(16*p, 2*p)
            MovePathCursor(20*p, 3*p)
            AddPathLine(16*p, 8*p)
            AddPathLine(12*p, 3*p)
            RotateCoordinates(16*p, 16*p, 60)
            StrokePath(2*p, #PB_Path_RoundEnd)
         Next M
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Macro UcaseFont(_x_, _y_, _size_, _Char_, _rotation_=0)
      hh = _size_ *0.3125
      SaveVectorState()
      RotateCoordinates(size * 0.5, size * 0.5, _rotation_)
      Select _Char_
         Case Asc("A")
            hw = hh * 0.9
            MovePathCursor(_x_ - hw, _y_ + hh)
            AddPathLine(_x_, _y_ - hh)
            AddPathLine(_x_ + hw, _y_ + hh)
            MovePathCursor(_x_ - hw/1.8, _y_ + hh/3)
            AddPathLine(_x_ + hw/1.8, _y_ + hh/3)

         Case Asc("B")
            hw = hh * 0.81
            MovePathCursor(_x_ + hw * 0.08, _y_ - hh)
            AddPathLine(_x_ - hw , _y_ - hh)
            AddPathLine(_x_ - hw, _y_ + hh)
            MovePathCursor(_x_ - hw + hh, _y_)
            AddPathLine(_x_ - hw, _y_)
            AddPathCircle(_x_ + hw * 0.08, _y_ - hh/2, hh/2, 270, 90)
            MovePathCursor(_x_ - hw + hh, _y_ + hh)
            AddPathLine(_x_ - hw, _y_ + hh)
            AddPathCircle(_x_ - hw + hh, _y_ + hh/2, hh/2, 270, 90)

         Case Asc("C")
            hw = hh * 0.9
            AddPathCircle(_x_, _y_ + hw - hh, hw, 200, 340)
            AddPathCircle(_x_, _y_ - hw + hh, hw, 20, 160)
            MovePathCursor(_x_ - hw * 0.95, _y_ - hh/2.75)
            AddPathLine(_x_ - hw * 0.95, _y_ + hh/2.75)

         Case Asc("D")
            hw = hh * 0.81
            MovePathCursor(_x_ - hw/2.5, _y_ - hh)
            AddPathLine(_x_ - hw , _y_ - hh)
            AddPathLine(_x_ - hw, _y_ + hh)
            MovePathCursor(_x_ - hw/2.5, _y_ + hh)
            AddPathLine(_x_ - hw, _y_ + hh)
            AddPathCircle(_x_ - hw/2.5, _y_ , hh, 270, 90)

         Case Asc("E")
            hw = hh * 0.81
            MovePathCursor(_x_ + hw, _y_ - hh)
            AddPathLine(_x_ - hw , _y_ - hh)
            AddPathLine(_x_ - hw, _y_ + hh)
            AddPathLine(_x_ + hw, _y_ + hh)
            MovePathCursor(_x_ - hw, _y_)
            AddPathLine(_x_ + hw * 0.8, _y_)

         Case Asc("F")
            hw = hh * 0.81
            MovePathCursor(_x_ + hw, _y_ - hh)
            AddPathLine(_x_ - hw , _y_ - hh)
            AddPathLine(_x_ - hw, _y_ + hh)
            MovePathCursor(_x_ - hw, _y_)
            AddPathLine(_x_ + hw * 0.8, _y_)

         Case Asc("G")
            hw = hh * 0.9
            AddPathCircle(_x_, _y_ + hw - hh, hw, 200, 340)
            AddPathCircle(_x_, _y_ - hw + hh, hw, 20, 160)
            MovePathCursor(_x_ - hw * 0.95, _y_ - hh/2.75)
            AddPathLine(_x_ - hw * 0.95, _y_ + hh/2.75)
            MovePathCursor(_x_  + hw/5, _y_  + hh/5)
            AddPathLine(_x_ + hw * 0.95, _y_  + hh/5)
            AddPathLine(_x_ + hw * 0.95, _y_ + hh/2.75)

         Case Asc("H")
            hw = hh * 0.81
            MovePathCursor(_x_ - hw, _y_ - hh)
            AddPathLine(_x_ - hw , _y_ + hh)
            MovePathCursor(_x_ + hw, _y_ - hh)
            AddPathLine(_x_ + hw , _y_ + hh)
            MovePathCursor(_x_ - hw, _y_)
            AddPathLine(_x_ + hw , _y_)

         Case Asc("I")
            hw = hh * 0.81
            MovePathCursor(_x_ , _y_ - hh)
            AddPathLine(_x_ , _y_ + hh)

         Case Asc("J")
            hw = hh * 0.81
            MovePathCursor(_x_ , _y_ - hh)
            AddPathLine(_x_ , _y_ + hh * 0.55)
            AddPathCircle(_x_ - hh/2, _y_ + hh/2, hh/2, 0, 180)

         Case Asc("K")
            hw = hh * 0.6
            MovePathCursor(_x_ - hw, _y_ - hh)
            AddPathLine(_x_ - hw, _y_ + hh)
            MovePathCursor(_x_ - hw, _y_ + hh/3)
            AddPathLine(_x_ + hw, _y_ - hh)
            MovePathCursor(_x_ - hw/8, _y_ - hh/10)
            AddPathLine(_x_ + hw, _y_ + hh)

         Case Asc("L")
            hw = hh * 0.45
            MovePathCursor(_x_ - hw, _y_ - hh)
            AddPathLine(_x_ - hw , _y_ + hh)
            AddPathLine(_x_ + hw, _y_ + hh)

         Case Asc("M")
            hw = hh * 0.9
            MovePathCursor(_x_ - hw, _y_ + hh)
            AddPathLine(_x_ - hw, _y_ - hh)
            AddPathLine(_x_, _y_ + hh * 0.05)
            AddPathLine(_x_ + hw, _y_ - hh)
            AddPathLine(_x_ + hw, _y_ + hh)

         Case Asc("N")
            hw = hh * 0.81
            MovePathCursor(_x_ - hw, _y_ + hh)
            AddPathLine(_x_ - hw , _y_ - hh)
            AddPathLine(_x_ + hw , _y_ + hh)
            AddPathLine(_x_ + hw , _y_ -hh)

         Case Asc("O")
            hw = hh * 0.9
            AddPathCircle(_x_, _y_ + hw - hh, hw, 200, 340)
            AddPathCircle(_x_, _y_ - hw + hh, hw, 20, 160)
            MovePathCursor(_x_ - hw * 0.95, _y_ - hh/2.75)
            AddPathLine(_x_ - hw * 0.95, _y_ + hh/2.75)
            MovePathCursor(_x_ + hw * 0.95, _y_ - hh/2.75)
            AddPathLine(_x_ + hw * 0.95, _y_ + hh/2.75)

         Case Asc("P")
            hw = hh * 0.81
            MovePathCursor(_x_ - hw + hh, _y_ - hh)
            AddPathLine(_x_ - hw , _y_ - hh)
            AddPathLine(_x_ - hw, _y_ + hh)
            MovePathCursor(_x_ - hw + hh, _y_)
            AddPathLine(_x_ - hw, _y_)
            AddPathCircle(_x_ - hw + hh, _y_ - hh/2, hh/2, 270, 90)

         Case Asc("Q")
            hw = hh * 0.9
            AddPathCircle(_x_, _y_ + hw - hh, hw, 200, 340)
            AddPathCircle(_x_, _y_ - hw + hh, hw, 20, 160)
            MovePathCursor(_x_ - hw * 0.95, _y_ - hh/2.75)
            AddPathLine(_x_ - hw * 0.95, _y_ + hh/2.75)
            MovePathCursor(_x_ + hw * 0.95, _y_ - hh/2.75)
            AddPathLine(_x_ + hw * 0.95, _y_ + hh/2.75)
            MovePathCursor(_x_ + hw/4, _y_ + hh/4)
            AddPathLine(_x_ + hw * 1.1, _y_ + hh * 1.1)

         Case Asc("R")
            hw = hh * 0.81
            MovePathCursor(_x_ - hw + hh, _y_ - hh)
            AddPathLine(_x_ - hw , _y_ - hh)
            AddPathLine(_x_ - hw, _y_ + hh)
            MovePathCursor(_x_ - hw + hh, _y_)
            AddPathLine(_x_ - hw, _y_)
            AddPathCircle(_x_ - hw + hh, _y_ - hh/2, hh/2, 270, 90)
            MovePathCursor(PathCursorX() - hw/6, PathCursorY())
            AddPathLine(_x_ + hw * 0.7, _y_ + hh)

         Case Asc("S")
            hw = hh * 0.9
            AddPathCircle(_x_ + 0.0125 * _size_, _y_ - 0.0125 * _size_, 0.315625 * _size_, 240, 320)
            AddPathCircle(_x_ - 0.09375 * _size_, _y_ - 0.15625 * _size_, 0.140625 * _size_, 250, 95, #PB_Path_CounterClockwise)
            AddPathLine(_x_ + 0.125 * _size_, _y_ + 0.046875 * _size_)
            AddPathCircle(_x_ + 0.125 * _size_, _y_ + 0.1875 * _size_, 0.140625 * _size_, 275, 70)
            AddPathCircle(_x_ + 0.01875 * _size_, _y_ + 0.04375 * _size_, 0.315625 * _size_, 60, 140)

         Case Asc("T")
            hw = hh * 0.81
            MovePathCursor(_x_ - hw, _y_ - hh)
            AddPathLine(_x_ + hw , _y_ - hh)
            MovePathCursor(_x_, _y_ - hh)
            AddPathLine(_x_, _y_ + hh)

         Case Asc("U")
            hw = hh * 0.81
            AddPathCircle(_x_, _y_ - hw + hh, hw, 20, 160)
            MovePathCursor(_x_ - hw * 0.95, _y_ - hh)
            AddPathLine(_x_ - hw * 0.95, _y_ + hh/2.3)
            MovePathCursor(_x_ + hw * 0.95, _y_ - hh)
            AddPathLine(_x_ + hw * 0.95, _y_ + hh/2.3)

         Case Asc("V")
            hw = hh * 0.9
            MovePathCursor(_x_ - hw, _y_ - hh)
            AddPathLine(_x_ , _y_ + hh)
            AddPathLine(_x_ + hw, _y_ - hh)

         Case Asc("W")
            hw = hh * 1.5
            MovePathCursor(_x_ - hw, _y_ - hh)
            AddPathLine(_x_ - hw * 0.5, _y_ + hh)
            AddPathLine(_x_, _y_ - hh * 0.5)
            AddPathLine(_x_ + hw * 0.5, _y_ + hh)
            AddPathLine(_x_ + hw, _y_ - hh)

         Case Asc("X")
            hw = hh * 0.81
            MovePathCursor(_x_ - hw, _y_ - hh)
            AddPathLine(_x_ + hw , _y_ + hh)
            MovePathCursor(_x_ + hw, _y_ - hh)
            AddPathLine(_x_ - hw, _y_ + hh)

         Case Asc("Y")
            hw = hh * 0.9
            MovePathCursor(_x_ - hw, _y_ - hh)
            AddPathLine(_x_ , _y_)
            AddPathLine(_x_ + hw, _y_ - hh)
            MovePathCursor(_x_, _y_)
            AddPathLine(_x_, _y_ + hh)

         Case Asc("Z")
            hw = hh * 0.81
            MovePathCursor(_x_ - hw, _y_ - hh)
            AddPathLine(_x_ + hw , _y_ - hh)
            AddPathLine(_x_ - hw, _y_ + hh)
            AddPathLine(_x_ + hw, _y_ + hh)

      EndSelect
      StrokePath(_size_ / 16, #PB_Path_RoundEnd | #PB_Path_RoundCorner)
      RestoreVectorState()
   EndMacro


   Procedure.i A2M (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, hh.d, hw.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color)
         UcaseFont(size * 0.125, size * 0.125, size * 0.25, Asc("A"))
         UcaseFont(size * 0.375, size * 0.125, size * 0.25, Asc("B"))
         UcaseFont(size * 0.625, size * 0.125, size * 0.25, Asc("C"))
         UcaseFont(size * 0.875, size * 0.125, size * 0.25, Asc("D"))
         UcaseFont(size * 0.125, size * 0.375, size * 0.25, Asc("E"))
         UcaseFont(size * 0.375, size * 0.375, size * 0.25, Asc("F"))
         UcaseFont(size * 0.625, size * 0.375, size * 0.25, Asc("G"))
         UcaseFont(size * 0.875, size * 0.375, size * 0.25, Asc("H"))
         UcaseFont(size * 0.125, size * 0.625, size * 0.25, Asc("I"))
         UcaseFont(size * 0.375, size * 0.625, size * 0.25, Asc("J"))
         UcaseFont(size * 0.625, size * 0.625, size * 0.25, Asc("K"))
         UcaseFont(size * 0.875, size * 0.625, size * 0.25, Asc("L"))
         UcaseFont(size * 0.125, size * 0.875, size * 0.25, Asc("M"))
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i N2Z (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d, hh.d, hw.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color)
         UcaseFont(size * 0.125, size * 0.125, size * 0.25, Asc("N"))
         UcaseFont(size * 0.375, size * 0.125, size * 0.25, Asc("O"))
         UcaseFont(size * 0.625, size * 0.125, size * 0.25, Asc("P"))
         UcaseFont(size * 0.875, size * 0.125, size * 0.25, Asc("Q"))
         UcaseFont(size * 0.125, size * 0.375, size * 0.25, Asc("R"))
         UcaseFont(size * 0.375, size * 0.375, size * 0.25, Asc("S"))
         UcaseFont(size * 0.625, size * 0.375, size * 0.25, Asc("T"))
         UcaseFont(size * 0.875, size * 0.375, size * 0.25, Asc("U"))
         UcaseFont(size * 0.125, size * 0.625, size * 0.25, Asc("V"))
         UcaseFont(size * 0.375, size * 0.625, size * 0.25, Asc("W"))
         UcaseFont(size * 0.625, size * 0.625, size * 0.25, Asc("X"))
         UcaseFont(size * 0.875, size * 0.625, size * 0.25, Asc("Y"))
         UcaseFont(size * 0.125, size * 0.875, size * 0.25, Asc("Z"))
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i RainCloud (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         DrawCloud(16*p, 12*p, size/1.25, #True)
         VectorSourceColor(color2)
         DrawBalloon(24*p, 4*p, size/8, 180)
         DrawBalloon(20*p, 8*p, size/9, 180)
         DrawBalloon(16*p, 4*p, size/8, 180)
         DrawBalloon(12*p, 8*p, size/9, 180)
         DrawBalloon( 8*p, 4*p, size/8, 180)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i CloudStorage (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by davido]
      Protected ret.i, p.d

      ret = StartVectorIconOutput(file$, img, size)

      p = size / 32.0

      If ret
         VectorSourceColor(color1)
         DrawCloud(16*p, 12*p, size)
         VectorSourceColor(color2)
         MovePathCursor(6*p, 13*p)
         AddPathLine(6*p, 19*p)
         AddPathEllipse(11*p, 16*p, 2*p, 2.5*p)
         MovePathCursor(16*p, 13*p)
         AddPathLine(16*p, 19*p)
         AddPathEllipse(21*p, 16*p, 2*p, 2.5*p)
         MovePathCursor(26*p, 13*p)
         AddPathLine(26*p, 19*p)
         StrokePath(p)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure

   ;---------------------------------------------------------------

   Procedure.i MediaPlay (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by infratec]
      Protected ret.i, w.d

      w = size / 8.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor(2*w,   w)
         AddPathLine   (2*w, 7*w)
         AddPathLine   (6*w, 4*w)
         AddPathLine   (2*w,   w)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i MediaStop (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by infratec]
      Protected ret.i, w.d

      w = size / 8.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor(2*w,   w)
         AddPathLine   (2*w, 7*w)

         MovePathCursor(5*w,   w)
         AddPathLine   (5*w, 7*w)
         StrokePath    (1.5*w, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i MediaBegin (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by infratec]
      Protected ret.i, w.d

      w = size / 8.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor(6*w,   w)
         AddPathLine   (6*w, 7*w)
         AddPathLine   (2*w, 4*w)
         AddPathLine   (6*w,   w)
         FillPath()

         MovePathCursor(2*w,   w)
         AddPathLine   (2*w, 7*w)
         StrokePath(1.5*w, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i MediaEnd (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by infratec]
      Protected ret.i, w.d

      w = size / 8.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor(3*w,   w)
         AddPathLine   (3*w, 7*w)
         AddPathLine   (7*w, 4*w)
         AddPathLine   (3*w,   w)
         FillPath()

         MovePathCursor(7*w,   w)
         AddPathLine   (7*w, 7*w)
         StrokePath(1.5*w, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i MediaForward (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by infratec]
      Protected ret.i, w.d

      w = size / 8.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor(2*w, w)
         AddPathLine(5*w, 4*w)
         AddPathLine(2*w, 7*w)

         StrokePath(1.5*w, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i MediaFastForward (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by infratec]
      Protected ret.i, w.d

      w = size / 8.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor(w, w)
         AddPathLine(4*w, 4*w)
         AddPathLine(w, 7*w)
         StrokePath(1.5*w, #PB_Path_RoundCorner)

         MovePathCursor(4*w, w)
         AddPathLine(7*w, 4*w)
         AddPathLine(4*w, 7*w)
         StrokePath(1.5*w, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i MediaBack (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by infratec]
      Protected ret.i, w.d

      w = size / 8.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor(5*w, w)
         AddPathLine(2*w, 4*w)
         AddPathLine(5*w, 7*w)
         StrokePath(1.5*w, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i MediaFastBack (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by infratec]
      Protected ret.i, w.d

      w = size / 8.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         MovePathCursor(4*w, w)
         AddPathLine(w, 4*w)
         AddPathLine(4*w, 7*w)
         StrokePath(1.5*w, #PB_Path_RoundCorner)

         MovePathCursor(7*w, w)
         AddPathLine(4*w, 4*w)
         AddPathLine(7*w, 7*w)
         StrokePath(1.5*w, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure

   ;---------------------------------------------------------------
   ; Macros by Oma which are used in several of his icon procedures.

   Macro DocuSheet()
      ; frame
      MovePathCursor(p8,              p16)
      AddPathLine   (size - p4 - p16, p16)
      AddPathLine   (size - p8,       p4)
      AddPathLine   (size - p8,       size - p16)
      AddPathLine   (p8,              size - p16)
      ClosePath     ()
      VectorSourceColor(color1)
      FillPath(#PB_Path_Preserve)
      VectorSourceColor(color2)
      StrokePath    (p16)
      ; dog-ear
      MovePathCursor(size - p4 - p16, p16)
      AddPathLine   (size - p4 - p16, p4)
      AddPathLine   (size - p8,       p4)
      StrokePath    (p)
   EndMacro

   Macro ChartScale()
      VectorSourceColor(color1)
      For i = 0 To 270 Step 270
         RotateCoordinates(p2, p2, i)
         ; axes
         MovePathCursor(0,   0)
         AddPathLine   (0,   size)
         ; scale
         MovePathCursor(0,   0)
         AddPathLine   (p16, 0)
         MovePathCursor(0,   p4)
         AddPathLine   (p16, p4)
         MovePathCursor(0,   p2)
         AddPathLine   (p16, p2)
         MovePathCursor(0,   p2 + p4)
         AddPathLine   (p16, p2 + p4)
         MovePathCursor(0,   size)
         AddPathLine   (p16, size)
         StrokePath    (1)
      Next i
      ResetCoordinates()
   EndMacro

   Macro ChartBars(_angle_)
      RotateCoordinates(p2 + p,  p2 - p, _angle_)
      VectorSourceColor(color4)
      AddPathBox       (p4,      p4,     p4 - p16 - p, size - p4 - p8)
      FillPath         (#PB_Path_Preserve)
      VectorSourceColor(Color_Darken(color4, 0.75))
      StrokePath       (1)

      VectorSourceColor(color3)
      AddPathBox       (p2,      p8,     p4 - p16 - p, size - p8 - p8)
      FillPath         (#PB_Path_Preserve)
      VectorSourceColor(Color_Darken(color3, 0.75))
      StrokePath       (1)

      VectorSourceColor(color2)
      AddPathBox       (p4 + p2, p2,     p4 - p16 - p, size - p2 - p8)
      FillPath         (#PB_Path_Preserve)
      VectorSourceColor(Color_Darken(color2, 0.75))
      StrokePath       (1)
      RotateCoordinates(p2,      p2,     0)
   EndMacro

   Macro ChartBarsStacked(_angle_)
      RotateCoordinates(p2 + p,  p2 - p,  _angle_)
      VectorSourceColor(color4)
      AddPathBox       (p4,      p2,      p4 - p16 - p, p4 + p8)
      FillPath         ()
      VectorSourceColor(color2)
      AddPathBox       (p4,      p4,      p4 - p16 - p, p4 - 1)
      FillPath         ()
      VectorSourceColor(color4)
      AddPathBox       (p4,      p4,      p4 - p16 - p, p2 + p8)
      StrokePath       (0.5)

      VectorSourceColor(color4)
      AddPathBox       (p2,      p2 + p8, p4 - p16 - p, p4)
      FillPath         ()
      VectorSourceColor(color2)
      AddPathBox       (p2,      p4 + p8, p4 - p16 - p, p4 - 1)
      FillPath         ()
      VectorSourceColor(color3)
      AddPathBox       (p2,      p8,      p4 - p16 - p, p4 - 1)
      FillPath         ()
      VectorSourceColor(color4)
      AddPathBox       (p2,      p8,      p4 - p16 - p, p2 + p4)
      StrokePath       (0.5)

      VectorSourceColor(color4)
      AddPathBox       (p4 + p2, p2 + p4, p4 - p16 - p, p8)
      FillPath         ()
      VectorSourceColor(color3)
      AddPathBox       (p4 + p2, p4 + p8, p4 - p16 - p, p2 - p8 - 1)
      FillPath         ()
      VectorSourceColor(color4)
      AddPathBox       (p4 + p2, p4 + p8, p4 - p16 - p, p2)
      StrokePath       (0.5)

      RotateCoordinates(p2,      p2,      0)
   EndMacro

   Macro ChartCylBars(_angle_)
      RotateCoordinates         (p2 + p,  p2 - p, _angle_)
      VectorSourceLinearGradient(p4,      0,  p2 - p16 + 1,       0)
      VectorSourceGradientColor (color1,  0.0)
      VectorSourceGradientColor (color4,  0.5)
      VectorSourceGradientColor (color1,  1.0)
      AddPathBox                (p4,      p4, p4- p16,            size - p4 - p16 - p)
      FillPath                  ()

      VectorSourceLinearGradient(p2,      0,  p2 + p4 - p16 + 1, 0)
      VectorSourceGradientColor (color1,  0.0)
      VectorSourceGradientColor (color3,  0.5)
      VectorSourceGradientColor (color1,  1.0)
      AddPathBox                (p2,      p8, p4- p16,           size - p8 - p16 - p)
      FillPath                  ()

      VectorSourceLinearGradient(p4 + p2, 0,  size - p16 + 1,   0)
      VectorSourceGradientColor (color1,  0.0)
      VectorSourceGradientColor (color2,  0.5)
      VectorSourceGradientColor (color1,  1.0)
      AddPathBox                (p4 + p2, p2, p4- p16,          size - p2 - p16 - p)
      FillPath                  ()
      RotateCoordinates         (p2, p2,  0)
   EndMacro

   Macro ChartCylBarsStacked(_angle_)
      RotateCoordinates         (p2 + p,  p2 - p, _angle_)
      VectorSourceLinearGradient(p4,      0,  p2 - p16 + 1, 0)
      VectorSourceGradientColor (color1,  0.0)
      VectorSourceGradientColor (color4,  0.5)
      VectorSourceGradientColor (color1,  1.0)
      AddPathBox                (p4,      p2, p4 - p16 - p, p4 + p8 + p)
      FillPath                  ()
      VectorSourceLinearGradient(p4,      0,  p2 - p16+1, 0)
      VectorSourceGradientColor (color1,  0.0)
      VectorSourceGradientColor (color3,  0.5)
      VectorSourceGradientColor (color1,  1.0)
      AddPathBox                (p4,      p4, p4 - p16 - p, p4 - 1)
      FillPath                  ()

      VectorSourceLinearGradient(p2, 0,   p4 + p2 - p16 + 1, 0)
      VectorSourceGradientColor (color1,  0.0)
      VectorSourceGradientColor (color3,  0.5)
      VectorSourceGradientColor (color1,  1.0)
      AddPathBox                (p2,      p2 + p8, p4 - p16 - p, p4 + p)
      FillPath                  ()
      VectorSourceLinearGradient(p2, 0,   p4 + p2 - p16+1, 0)
      VectorSourceGradientColor (color1,  0.0)
      VectorSourceGradientColor (color2,  0.5)
      VectorSourceGradientColor (color1,  1.0)
      AddPathBox                (p2,      p4 + p8, p4 - p16 - p, p4 - 1)
      FillPath                  ()
      VectorSourceLinearGradient(p2, 0,   p4 + p2 - p16+1, 0)
      VectorSourceGradientColor (color1,  0.0)
      VectorSourceGradientColor (color4,  0.5)
      VectorSourceGradientColor (color1,  1.0)
      AddPathBox                (p2,      p8,      p4 - p16 - p, p4 - 1)
      FillPath                  ()

      VectorSourceLinearGradient(p4 + p2, 0, size - p16 + 1, 0)
      VectorSourceGradientColor (color1,  0.0)
      VectorSourceGradientColor (color4,  0.5)
      VectorSourceGradientColor (color1,  1.0)
      AddPathBox                (p4 + p2, p2 + p4, p4 - p16 - p, p8 + p)
      FillPath                  ()
      VectorSourceLinearGradient(p4 + p2, 0, size - p16+1, 0)
      VectorSourceGradientColor (color1,  0.0)
      VectorSourceGradientColor (color3,  0.5)
      VectorSourceGradientColor (color1,  1.0)
      AddPathBox                (p4 + p2, p4 + p8, p4 - p16 - p, p2 - p8 - 1)
      FillPath                  ()

      RotateCoordinates(p2, p2, 0)
   EndMacro

   ; general macro to create a convex & round / rectangular / rounded corner background area
   Macro Convex_Area (_colorbright_, _darken_)
      ; for 'x_Convex()'-icons
      ; The brighter the _colorbright_ & lower the _darken_-factor (0.0 ... 1.0), the stronger is the effect.
      VectorSourceLinearGradient(0, 0, size, size)
      VectorSourceGradientColor(_colorbright_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorbright_, _darken_), 1.0)
   EndMacro

   Macro GradientFullsize_AxisVhi(_colorbright_, _darken_); vertical, axis w. high color value
                                                          ;The brighter the _colorbright_ & lower the _darken_-factor (0.0 ... 1.0), the stronger is the effect.
      VectorSourceLinearGradient(0, 0, size, 0)
      VectorSourceGradientColor(Color_Darken(_colorbright_, _darken_), 0.0)
      VectorSourceGradientColor(_colorbright_, 0.55)
      VectorSourceGradientColor(Color_Darken(_colorbright_, _darken_), 1.0)
   EndMacro


   Macro GradientFullsize_LT2RB(_colorbright_, _darken_)
      ;left top to right bottom
      ;The brighter the _colorbright_ & lower the _darken_-factor (0.0 ... 1.0), the stronger is the effect.
      VectorSourceLinearGradient(0, 0, size, size)
      VectorSourceGradientColor(_colorbright_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorbright_, _darken_), 1.0)
   EndMacro

   Macro GradientFullsize_L2R(_colorbright_, _darken_)
      ;left to right
      ;The brighter the _colorbright_ & lower the _darken_-factor (0.0 ... 1.0), the stronger is the effect.
      VectorSourceLinearGradient(0, 0, size, 0)
      VectorSourceGradientColor(_colorbright_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorbright_, _darken_), 1.0)
   EndMacro

   Macro GradientFullsize_T2B(_colorbright_, _darken_)
      ;top to bottom
      ;The brighter the _colorbright_ & lower the _darken_-factor (0.0 ... 1.0), the stronger is the effect.
      VectorSourceLinearGradient(0, 0, 0, size)
      VectorSourceGradientColor(_colorbright_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorbright_, _darken_), 1.0)
   EndMacro

   Macro DrawPen_Spatial(_colorM1_, _colorM2_, _colorM3_, _colorM4_, _colorM5_)
      ;eraser
      VectorSourceLinearGradient(p * 14, 0, p * 18, 0)
      VectorSourceGradientColor(_colorM1_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM1_, 0.5), 1.0)
      MovePathCursor(p2,      p * 2)
      AddPathLine   (0,       p * 1.5, #PB_Path_Relative)
      StrokePath    (p * 4.5,          #PB_Path_RoundEnd)
      ;sleeve
      VectorSourceLinearGradient(p * 14, 0, p * 18, 0)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.9), 0.0)
      VectorSourceGradientColor(_colorM2_, 0.25)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.5), 1.0)
      MovePathCursor(p2,    p * 3.5)
      AddPathLine   (0,     p * 4.5, #PB_Path_Relative)
      StrokePath    (p * 5)
      ;lines
      VectorSourceLinearGradient(p * 14, 0, p * 18, 0)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.6), 0.0)
      VectorSourceGradientColor(_colorM2_, 0.1)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.3), 1.0)
      MovePathCursor(p * 13.5, p * 4.5)
      AddPathLine   (p * 18.5, p * 4.5)
      MovePathCursor(p * 13.5, p * 7.0)
      AddPathLine   (p * 18.5, p * 7.0)
      StrokePath    (p * 0.5)
      ;body...
      VectorSourceLinearGradient(p * 14, 0, p * 18, 0)
      VectorSourceGradientColor(_colorM3_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM3_, 0.5), 1.0)
      MovePathCursor(p2,     p * 8)
      AddPathLine   (0,      p * 18, #PB_Path_Relative)
      StrokePath    (p * 5)
      ;tip wood
      VectorSourceLinearGradient(p * 14, 0, p * 18, 0)
      VectorSourceGradientColor(_colorM4_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM4_, 0.7), 1.0)
      MovePathCursor(p * 13.5, p * 26)
      AddPathLine   (p2,       p * 32)
      AddPathLine   (p * 18.5, p * 26)
      ClosePath     ()
      FillPath      ()
      ;tip graphite
      VectorSourceLinearGradient(p * 15, 0, p * 17, 0)
      VectorSourceGradientColor(_colorM5_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM5_, 0.0), 1.0)
      MovePathCursor(p * 15, p * 29.5)
      AddPathLine   (p2,     p * 32)
      AddPathLine   (p * 17, p * 29.5)
      ClosePath     ()
      FillPath      ()
   EndMacro

   Macro DrawPen_Flat(_colorM1_, _colorM2_, _colorM3_, _colorM4_, _colorM5_)
      ;eraser
      VectorSourceColor(_colorM1_)
      MovePathCursor(p2,      p * 2)
      AddPathLine   (0,       p * 4.5, #PB_Path_Relative)
      StrokePath    (p * 4.5,          #PB_Path_RoundEnd)
      ;sleeve
      VectorSourceColor(_colorM2_)
      MovePathCursor(p2,    p * 5.5)
      AddPathLine   (0,     p * 1.5, #PB_Path_Relative)
      StrokePath    (p * 5)
      ;body...
      VectorSourceColor(_colorM3_)
      MovePathCursor(p2,     p * 7)
      AddPathLine   (0,      p * 19, #PB_Path_Relative)
      StrokePath    (p * 5)
      ;tip wood
      VectorSourceColor(_colorM4_)
      MovePathCursor(p * 13.5, p * 26)
      AddPathLine   (p2,       p * 32)
      AddPathLine   (p * 18.5, p * 26)
      ClosePath     ()
      FillPath      ()
      ;tip graphite
      VectorSourceColor(_colorM5_)
      MovePathCursor(p * 14.7, p * 28.7)
      AddPathLine   (p2,       p * 32)
      AddPathLine   (p * 17.3, p * 28.7)
      ClosePath     ()
      FillPath      ()
   EndMacro

   Macro DrawBrush_Spatial(_colorM1_, _colorM2_, _colorM3_)
      VectorSourceLinearGradient(p * 14, 0, p * 18, 0)
      VectorSourceGradientColor(_colorM1_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM1_, 0.6), 1.0);OrangeRed
      MovePathCursor(p * 15.5, p)
      AddPathCurve  (p * 14.0, p * 11, p * 13.5, p * 18, p * 14,   p * 19)
      AddPathLine   (p * 4,    0,      #PB_Path_Relative)
      AddPathCurve  (p * 18.5, p * 18, p * 18.0, p * 11, p * 16.5, p)
      ClosePath     ()
      FillPath      (#PB_Path_Preserve)
      StrokePath    (p, #PB_Path_RoundCorner)

      ;sleeve
      VectorSourceLinearGradient(p * 14, 0, p * 18, 0)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.9), 0.0)
      VectorSourceGradientColor(_colorM2_, 0.20)
      VectorSourceGradientColor(_colorM2_, 0.40)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.5), 1.0)
      MovePathCursor(p2,    p * 19)
      AddPathLine   (0,     p * 4, #PB_Path_Relative)
      StrokePath    (p * 5)

      ;hair
      VectorSourceLinearGradient(p * 12, 0, p * 19, 0)
      VectorSourceGradientColor(Color_Darken(_colorM3_, 0.3), 0.0)
      VectorSourceGradientColor(_colorM3_, 0.3)
      VectorSourceGradientColor(Color_Darken(_colorM3_, 0.0), 1.0)
      MovePathCursor(p * 13.5,  p * 23)
      AddPathCurve  (p * 12.5,    p * 26, p * 15.0, p * 29, p * 10.5, p * 32)
      AddPathCurve  (p * 18,    p * 30, p * 19.0, p * 25, p * 18.5, p * 23)
      ClosePath     ()
      FillPath      (#PB_Path_Preserve)
      StrokePath    (p * 0.5, #PB_Path_RoundCorner)
   EndMacro

   Macro DrawBrush_Flat(_colorM1_, _colorM2_, _colorM3_)
      VectorSourceColor(_colorM1_)
      MovePathCursor(p * 15.5, p)
      AddPathCurve  (p * 14.0, p * 11, p * 13.5, p * 18, p * 14,   p * 19)
      AddPathLine   (p * 4,    0,      #PB_Path_Relative)
      AddPathCurve  (p * 18.5, p * 18, p * 18.0, p * 11, p * 16.5, p)
      ClosePath     ()
      FillPath      (#PB_Path_Preserve)
      StrokePath    (p, #PB_Path_RoundCorner)

      ;sleeve
      VectorSourceColor(_colorM2_)
      MovePathCursor(p2,    p * 19)
      AddPathLine   (0,     p * 4, #PB_Path_Relative)
      StrokePath    (p * 5)

      ;tip
      VectorSourceColor(_colorM3_)
      MovePathCursor(p * 13.5,  p * 23)
      AddPathCurve  (p * 12.5,    p * 26, p * 15.0, p * 29, p * 10.5, p * 32)
      AddPathCurve  (p * 18,    p * 30, p * 19.0, p * 25, p * 18.5, p * 23)
      ClosePath     ()
      FillPath      (#PB_Path_Preserve)
      StrokePath    (p * 0.5, #PB_Path_RoundCorner)
   EndMacro

   Macro DrawPipette_Spatial(_colorM1_, _colorM2_)
      ;bubble...
      VectorSourceLinearGradient(p * 12, 0, p * 24, p16)
      VectorSourceGradientColor(Color_Darken(_colorM1_, 0.9), 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM1_, 0.9), 0.3)
      VectorSourceGradientColor(Color_Darken(_colorM1_, 0.4), 1.0)
      AddPathCircle (p2,      p * 5, p * 5)
      FillPath      ()
      ;bubble collar...
      VectorSourceLinearGradient(p * 14, 0, p * 18, 0)
      VectorSourceGradientColor(Color_Darken(_colorM1_, 0.8), 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM1_, 0.3), 1.0)
      MovePathCursor(p2,     p *  9)
      AddPathLine   (0,      p * 2, #PB_Path_Relative)
      StrokePath    (p * 6)
      ;body...
      VectorSourceLinearGradient(p * 13, 0, p * 18, 0)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.7), 0.0)
      VectorSourceGradientColor(_colorM2_, 0.4)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.5), 1.0)
      MovePathCursor(p2,     p * 11)
      AddPathLine   (0,      p * 15, #PB_Path_Relative)
      StrokePath    (p * 5)

      ;tip
      VectorSourceLinearGradient(p * 13, 0, p * 18, 0)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.6), 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.8), 0.4)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.5), 1.0)
      MovePathCursor(p * 13.5, p * 26)
      AddPathLine   (p2,       p * 32)
      AddPathLine   (p * 18.5, p * 26)
      ClosePath     ()
      FillPath      ()
      ;tip top
      VectorSourceLinearGradient(p * 15, 0, p * 17, 0)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.8), 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.5), 1.0)
      MovePathCursor(p * 15,   p * 29.5)
      AddPathLine   (p * 15.5, p * 32)
      AddPathLine   (p * 16.5, p * 32)
      AddPathLine   (p * 17,   p * 29.5)
      ClosePath     ()
      FillPath      ()
   EndMacro

   Macro DrawPipette_Flat(_colorM1_, _colorM2_, _colorM3_)
      ;bubble...
      VectorSourceColor(_colorM1_)
      AddPathCircle (p2, p * 5, p * 5)
      FillPath      ()
      ;body frame...
      VectorSourceColor(_colorM3_)
      AddPathBox    (p * 13.5, p * 11, p * 5, p * 14.5)
      StrokePath    (p)
      ;bubble collar...
      VectorSourceColor(_colorM1_)
      MovePathCursor(p2,     p *  9)
      AddPathLine   (0,      p * 2, #PB_Path_Relative)
      StrokePath    (p * 6)
      ;body...
      VectorSourceColor(_colorM2_)
      MovePathCursor(p2,     p * 11)
      AddPathLine   (0,      p * 15, #PB_Path_Relative)
      StrokePath    (p * 5)

      ;tip
      VectorSourceColor(_colorM3_)
      MovePathCursor(p * 13.5, p * 26)
      AddPathLine   (p2,       p * 32)
      AddPathLine   (p * 18.5, p * 26)
      ClosePath     ()
      FillPath      ()
      ;tip top
      MovePathCursor(p * 15,   p * 29.5)
      AddPathLine   (p * 15.5, p * 32)
      AddPathLine   (p * 16.5, p * 32)
      AddPathLine   (p * 17,   p * 29.5)
      ClosePath     ()
      FillPath      ()
   EndMacro

   Macro RotateStickDirection_Spatial()
      ;Arrow end ...
      VectorSourceColor(color2)
      MovePathCursor(p * 18,  0)
      AddPathCurve  (p * 20,  0,      p * 24,  p * 10, p * 24, p * 18)
      AddPathLine   (p * 32,  p * 18)
      AddPathCurve  (p * 32,  p * 10, p * 32,  p * 4,  p * 26, 0)
      ClosePath     ()
      FillPath      ()
      ;Stick ...
      VectorSourceLinearGradient(0, p * 10,  0, p * 17)
      VectorSourceGradientColor (Color_Darken(color3, 0.6), 0.0)
      VectorSourceGradientColor (color3,  0.5)
      VectorSourceGradientColor (Color_Darken(color3, 0.6),  1.0)
      AddPathEllipse(p * 2,  p * 14,  p * 1.2, p * 4)
      FillPath      ()
      AddPathBox    (p * 2,  p * 10,  p * 28,  p * 8)
      FillPath      ()
      VectorSourceColor(Color_Darken(color3, 0.6))
      AddPathEllipse(p * 30,  p * 14, p * 1.2, p * 4)
      FillPath      ()

      ;Arrow front ...
      GradientFullsize_L2R(color1, 0.5); gradient, or
                                       ;VectorSourceColor(color1);        flat?, deactivate the line aboove and use a carker color
      MovePathCursor(p * 18, 0)
      AddPathCurve  (p * 6,  0,      p * 6,  p * 10, p * 6,  p * 20)
      AddPathLine   (p * 18, p * 20)
      AddPathCurve  (p * 18, p * 10, p * 18, 0,      p * 26, 0)
      ClosePath     ()
      FillPath      ()
      ;Arrow tip ...
      MovePathCursor( 0,      p * 20)
      AddPathLine   ( p * 12, p * 32)
      AddPathLine   ( p * 24, p * 20)
      ClosePath     ()
      FillPath      ()
   EndMacro

   Macro RotateStickDimension_Spatial()
      ;Stick ...
      VectorSourceLinearGradient(0, p * 12,  0, p * 19)
      VectorSourceGradientColor (Color_Darken(color2, 0.6), 0.0)
      VectorSourceGradientColor (color2,  0.5)
      VectorSourceGradientColor (Color_Darken(color2, 0.6),  1.0)
      AddPathEllipse(p * 2,  p * 16, p,      p * 4)
      FillPath      ()
      AddPathBox    (p * 2,  p * 12, p * 28, p * 8)
      FillPath      ()
      VectorSourceColor(Color_Darken(color2, 0.6))
      AddPathEllipse(p * 30,  p * 16, p,     p * 4)
      FillPath      ()
      ;Arrow front ...
      VectorSourceLinearGradient(p * 6, 0, p2 + p4, 0)
      VectorSourceGradientColor(color1, 0.0)
      VectorSourceGradientColor(Color_Darken(color1, 0.5), 1.0)
      ;VectorSourceColor(color1);        flat?, deactivate the line aboove and use a carker color
      AddPathBox    (p * 10,   p * 22, p * 10,  -p * 12)
      FillPath      ()
      ;Arrow tips ...
      For i = 1 To 2
         MovePathCursor( p * 5,  p * 22)
         AddPathLine   ( p * 15, p * 32)
         AddPathLine   ( p * 25, p * 22)
         ClosePath     ()
         FillPath      ()
         FlipCoordinatesY(p2)
      Next i
   EndMacro

   Macro RotateStickCw_Spatial()
      VectorSourceLinearGradient(0, 0, size, 0)
      VectorSourceGradientColor(color1, 0.0)
      VectorSourceGradientColor(Color_Darken(color1, 0.65), 1.0)

      AddPathCircle (p * 18, p * 15, p * 10, 179.0, 0.0)
      AddPathLine   (p * 28, p * 20)

      MovePathCursor(p * 8,  p * 15)
      AddPathLine   (p * 8,  p * 22)
      StrokePath    (p * 8)

      VectorSourceCircularGradient(p * 18, p * 16,  p * 4)
      VectorSourceGradientColor(color2, 0.0)
      VectorSourceGradientColor(Color_Darken(color2, 0.65), 1.0)
      AddPathCircle (p * 18, p * 16,  p * 4)
      FillPath      ()

      VectorSourceLinearGradient(0, 0, size, 0)
      VectorSourceGradientColor(color1, 0.0)
      VectorSourceGradientColor(Color_Darken(color1, 0.65), 1.0)
      MovePathCursor(0,      p * 22)
      AddPathLine   (p * 8,  size)
      AddPathLine   (p * 16, p * 22)
      ClosePath     ()
      FillPath      ()
   EndMacro

   Macro CartonEmpty_Spatial()
      ;lid
      VectorSourceLinearGradient(0, 0, 0, p4)
      VectorSourceGradientColor(color1, 0.0)
      VectorSourceGradientColor(Color_Darken(color1, 0.6), 1.0)

      MovePathCursor(p * 7, p)
      AddPathLine   (size - p * 7, p)
      AddPathLine   (size - p * 2, p * 7.5)
      AddPathLine   (p * 2,        p * 7.5)
      ClosePath     ()
      FillPath      (#PB_Path_Preserve)
      MovePathCursor(p2, p)
      AddPathLine   (p2, p * 7.5)
      StrokePath    (p, #PB_Path_RoundCorner)
      ;tape
      VectorSourceLinearGradient(0, 0, 0, p4)
      VectorSourceGradientColor(color2, 0.0)
      VectorSourceGradientColor(Color_Darken(color2, 0.6), 1.0)
      MovePathCursor(p * 14.5, p)
      AddPathLine   (size - p * 14.5, p)
      AddPathLine   (size - p * 13,   p * 7.5)
      AddPathLine   (p * 13,          p * 7.5)
      ClosePath     ()
      FillPath      (#PB_Path_Preserve)
      StrokePath    (p, #PB_Path_RoundCorner)
      ;box
      GradientFullsize_T2B(color1, 0.6)
      AddPathBox    (p16,  p4, size - p8, p2 + p * 6)
      FillPath      (#PB_Path_Preserve)
      StrokePath    (p, #PB_Path_RoundCorner)
      ;tape box
      GradientFullsize_T2B(color2, 0.6)
      AddPathBox    (p * 12.5, p * 7.5, p * 7, p4)
      FillPath      ()
   EndMacro

   Macro RingBinder(_spinecolor_)
      ;spine
      AddPathBox      (p * 12, p16,   size - p * 24, size - p8)
      StrokePath      (p * 1.5, #PB_Path_RoundCorner)
      GradientFullsize_T2B(_spinecolor_, 0.4)
      AddPathBox      (p * 12, p * 2, size - p * 24, size - p * 4)
      FillPath()
      ;ring
      VectorSourceColor(color4)
      AddPathCircle    (p2, p * 24, p * 2.2)
      FillPath         (#PB_Path_Preserve)
      VectorSourceColor(color5)
      StrokePath       (p * 0.5)
      ;frame
      MovePathCursor   (p * 12,        p * 1.5)
      AddPathLine      (size - p * 12, p * 1.5)
      StrokePath       (p * 0.5)
      ;label
      AddPathBox       (p * 13, p * 4, size - p * 26, p * 12)
      FillPath         (#PB_Path_Preserve)
      StrokePath       (p, #PB_Path_RoundCorner)
      ;label lines
      VectorSourceColor(color4)
      For i = 7 To 13 Step 3
         MovePathCursor(p * 14,        p * i)
         AddPathLine   (size - p * 14, p * i)
      Next i
      StrokePath      (p * 0.5)
   EndMacro

   Macro ColorBoard_Spatial(_colorM1_, _colorM2_, _colorM3_, _colorM4_, _colorM5_, _colorM6_, _colorM7_)
      ;thumbring
      VectorSourceLinearGradient(p * 6, p * 26.8, p * 14.2, p * 30.6)
      VectorSourceGradientColor (_colorM1_, 1.0)
      VectorSourceGradientColor (Color_Darken(_colorM1_, 0.5), 0.0)
      AddPathEllipse            (p * 10.1, p * 26.53, p * 4.06, p * 2.9)
      StrokePath                (p * 1.5, #PB_Path_Preserve)
      ;board shape ...
      VectorSourceLinearGradient(0, 0, size, size)
      VectorSourceGradientColor(Color_Darken(_colorM1_, 0.95), 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM1_, 0.75), 1.0)
      RotateCoordinates(p * 9.43,  p * 26.83, 25)
      MovePathCursor   (p * 4.35,  p * 28.28)
      AddPathCurve     (p * 1.45,  p * 22.48, p * 21.75, p * 19.58, p * 7.25,  p * 16.68)
      AddPathCurve     (p * 0,     p * 15.23, p * -1.45, p * 7.98,  p * 4.35,  p * 3.63)
      AddPathCurve     (p * 11.6,  p * -1.45, p * 31.18, p * -0.73, p * 30.45, p * 16.68)
      AddPathCurve     (p * 30.45, p * 31.18, p * 6.53,  p * 34,    p * 4.35,  p * 28.28)
      FillPath         (#PB_Path_Preserve)
      ;board border ...
      VectorSourceLinearGradient(p * 2, p, size, size)
      VectorSourceGradientColor(_colorM1_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM1_, 0.5), 1.0)
      StrokePath               (p * 0.5)

      ;blob red
      VectorSourceLinearGradient(p * 3.92, p * 5.37, p * 9.14, p * 10.6)
      VectorSourceGradientColor(_colorM2_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM2_, 0.7), 1.0)
      AddPathCircle(p * 6.53, p * 8, p * 2.6)
      FillPath     ()
      ;blob blue
      VectorSourceLinearGradient(p * 12.3, p * 2.9, p * 18.13, p * 8.7)
      VectorSourceGradientColor(_colorM3_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM3_, 0.7), 1.0)
      AddPathCircle(p * 15.23, p * 5.8, p * 2.9)
      FillPath()
      ;blob green
      VectorSourceLinearGradient(p * 20.85, p * 7.1, p * 25.5, p * 11.75)
      VectorSourceGradientColor(_colorM4_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM4_, 0.7), 1.0)
      AddPathCircle(p * 23.2, p * 9.43, p * 2.3)
      FillPath()
      ;blob yellow
      VectorSourceLinearGradient(p * 22.7, p * 14.8, p * 31.3, p * 20)
      VectorSourceGradientColor(_colorM5_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM5_, 0.7), 1.0)
      AddPathCircle(p * 25.38, p * 17.4, p * 2.6)
      FillPath()
      ;blob magenta
      VectorSourceLinearGradient(p * 13.9, p * 13.2, p * 18, p * 17.3)
      VectorSourceGradientColor(_colorM6_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM6_, 0.7), 1.0)
      AddPathCircle(p * 16, p * 15.2, p * 2)
      FillPath()
      ;blob white
      VectorSourceLinearGradient(p * 16.8, p * 20.4, p * 23.7, p * 27.41)
      VectorSourceGradientColor(_colorM7_, 0.0)
      VectorSourceGradientColor(Color_Darken(_colorM7_, 0.8), 1.0)
      AddPathCircle(p * 20.3, p * 23.93, p * 3.5)
      FillPath()
   EndMacro

   Macro ColorBoard_Flat(_colorM1_, _colorM2_, _colorM3_, _colorM4_, _colorM5_, _colorM6_, _colorM7_)
      ;thumbring
      VectorSourceColor(Color_Darken(_colorM1_, 0.7))
      AddPathEllipse            (p * 10.1, p * 26.53, p * 4.06, p * 2.9)
      StrokePath                (p * 1.5, #PB_Path_Preserve)

      ;board shape ...
      VectorSourceColor(Color_Darken(_colorM1_, 0.85))
      RotateCoordinates(p * 9.43,  p * 26.83, 25)
      MovePathCursor   (p * 4.35,  p * 28.28)
      AddPathCurve     (p * 1.45,  p * 22.48, p * 21.75, p * 19.58, p * 7.25,  p * 16.68)
      AddPathCurve     (p * 0,     p * 15.23, p * -1.45, p * 7.98,  p * 4.35,  p * 3.63)
      AddPathCurve     (p * 11.6,  p * -1.45, p * 31.18, p * -0.73, p * 30.45, p * 16.68)
      AddPathCurve     (p * 30.45, p * 31.18, p * 6.53,  p * 34,    p * 4.35,  p * 28.28)
      FillPath         (#PB_Path_Preserve)
      ;board border ...
      VectorSourceColor(_colorM1_)
      StrokePath               (p * 0.5)

      ;blob red
      VectorSourceColor(_colorM2_)
      AddPathCircle(p * 6.53, p * 8, p * 2.6)
      FillPath     ()
      ;blob blue
      VectorSourceColor(_colorM3_)
      AddPathCircle(p * 15.23, p * 5.8, p * 2.9)
      FillPath()
      ;blob green
      VectorSourceColor(_colorM4_)
      AddPathCircle(p * 23.2, p * 9.43, p * 2.3)
      FillPath()
      ;blob yellow
      VectorSourceColor(_colorM5_)
      AddPathCircle(p * 25.38, p * 17.4, p * 2.6)
      FillPath()
      ;blob magenta
      VectorSourceColor(_colorM6_)
      AddPathCircle(p * 16, p * 15.2, p * 2)
      FillPath()
      ;blob white
      VectorSourceColor(_colorM7_)
      AddPathCircle(p * 20.3, p * 23.93, p * 3.5)
      FillPath()
   EndMacro

   Macro MousePointer(_frame_, _filling_)
      VectorSourceColor (_filling_)
      MovePathCursor    ( 0, 0)
      AddPathLine       ( p * 9,       p *  9,  #PB_Path_Relative)
      AddPathLine       (-p * 3.75,    0,       #PB_Path_Relative)
      AddPathLine       ( p * 2.1,     p * 4.5, #PB_Path_Relative)
      AddPathLine       (-p * 2.1,     p * 1.2, #PB_Path_Relative)
      AddPathLine       (-p * 2.1,    -p * 4.5, #PB_Path_Relative)
      AddPathLine       (-p * 2.25,    p * 3,   #PB_Path_Relative)
      ClosePath         ()
      FillPath          (#PB_Path_Preserve)
      VectorSourceColor (_frame_)
      StrokePath        ( p )
   EndMacro

   ;---------------------------------------------------------------

   Procedure.i FirstAid (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p8.d = size / 8.0
      Protected p2.d = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color2)
         ; panel: round corners
         AddPathBox    (p8, p8, size - 2 * p8, size - 2 * p8)
         FillPath      ()
         AddPathBox    (p8, p8, size - 2 * p8, size - 2 * p8)
         StrokePath    (p8 * 2, #PB_Path_RoundCorner)

         VectorSourceColor(color1)
         ; hor. bar
         MovePathCursor(p8, p2)
         AddPathLine   (size - 2 * p8, 0, #PB_Path_Relative)
         ; vert. bar
         MovePathCursor(p2, p8)
         AddPathLine   (0, size - 2 * p8, #PB_Path_Relative)
         StrokePath    (size / 5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i NoEntry (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p8.d = size / 8.0
      Protected p2.d = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; panel
         VectorSourceColor(color2)

         AddPathCircle    (p2, p2, p2)
         FillPath()

         ; bar
         VectorSourceColor(color1)
         MovePathCursor   (p8, p2)
         AddPathLine      (size - 2 * p8, 0, #PB_Path_Relative)
         StrokePath       (size/5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Stop3 (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected hw.d = size / 3.5
      Protected half.d = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color2)
         ; panel
         AddPathCircle    (half, half, half)
         FillPath()

         VectorSourceColor(color1)
         ; cross
         MovePathCursor   (hw, hw)
         AddPathLine      (size - hw, size - hw)
         MovePathCursor   (hw, size - hw)
         AddPathLine      (size - hw, hw)
         StrokePath       (size / 10)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Download2 (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p8.d = size / 8
      Protected p4.d = size / 4
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color2)

         ; panel: round corners
         AddPathBox(p8, p8, size - p4, size - p4)
         FillPath()
         AddPathBox(p8, p8, size - p4, size - p4)
         StrokePath(p4, #PB_Path_RoundCorner)

         ; arrow
         VectorSourceColor(color1)
         MovePathCursor(p2, p8)
         AddPathLine   (p2, size - p4)
         StrokePath    (size/5)
         MovePathCursor(p2 - p4, size - p2 + p8)
         AddPathLine   (p2 + p4, size - p2 + p8)
         AddPathLine   (p2, size - p8)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i FirstAid_Spatial (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p8.d = size / 8.0
      Protected p2.d = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; panel: round corners
         Convex_Area(color2, 0.4)
         AddPathBox    (p8, p8, size - 2 * p8, size - 2 * p8)
         FillPath      ()
         AddPathBox    (p8, p8, size - 2 * p8, size - 2 * p8)
         StrokePath    (p8 * 2, #PB_Path_RoundCorner)

         VectorSourceColor(color1)
         ; hor. bar
         MovePathCursor(p8, p2)
         AddPathLine   (size - 2 * p8, 0, #PB_Path_Relative)
         ; vert. bar
         MovePathCursor(p2, p8)
         AddPathLine   (0, size - 2 * p8, #PB_Path_Relative)
         StrokePath    (size / 5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i NoEntry_Spatial (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p8.d = size / 8.0
      Protected p2.d = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; panel
         Convex_Area(color2, 0.4)
         AddPathCircle    (p2, p2, p2)
         FillPath()

         ; bar
         VectorSourceColor(color1)
         MovePathCursor   (p8, p2)
         AddPathLine      (size - 2 * p8, 0, #PB_Path_Relative)
         StrokePath       (size/5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Stop3_Spatial (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected hw.d = size / 3.5
      Protected half.d = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; panel
         Convex_Area(color2, 0.4)
         AddPathCircle    (half, half, half)
         FillPath()

         VectorSourceColor(color1)
         ; cross
         MovePathCursor   (hw, hw)
         AddPathLine      (size - hw, size - hw)
         MovePathCursor   (hw, size - hw)
         AddPathLine      (size - hw, hw)
         StrokePath       (size / 10)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Download2_Spatial (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p8.d = size / 8
      Protected p4.d = size / 4
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Convex_Area(color2, 0.4)
         ; panel: round corners
         AddPathBox(p8, p8, size - p4, size - p4)
         FillPath()
         AddPathBox(p8, p8, size - p4, size - p4)
         StrokePath(p4, #PB_Path_RoundCorner)

         ; arrow
         VectorSourceColor(color1)
         MovePathCursor(p2, p8)
         AddPathLine   (p2, size - p4)
         StrokePath    (size/5)
         MovePathCursor(p2 - p4, size - p2 + p8)
         AddPathLine   (p2 + p4, size - p2 + p8)
         AddPathLine   (p2, size - p8)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ToClipboard (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma, mod. 14.04.2016]
      Protected ret.i
      Protected hw.d = Round(size / 10.0, #PB_Round_Up)
      Protected p2.d = size / 2
      Protected p4.d = size / 4
      Protected p8.d = size / 8
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         ; box
         AddPathBox    (hw, hw, size - 2 * hw, size - hw - size / 32)
         StrokePath    (size / 16, #PB_Path_DiagonalCorner)
         ; ring
         AddPathCircle (p2, hw+1, hw, 180, 0)
         StrokePath    (size / 32)
         ; clamb
         AddPathCircle (p2 + hw, 3*hw, hw-1, 180, 0)
         FillPath()
         AddPathCircle (p2 - hw, 3*hw, hw-1, 180, 0)
         FillPath      ()
         StrokePath    (size / 16)

         MovePathCursor(p2 - hw, 2 * hw)
         AddPathLine   (2 * hw, 0, #PB_Path_Relative)
         StrokePath    (2 * hw, #PB_Path_RoundCorner)

         VectorSourceColor(color2)
         MovePathCursor(p2 + p4, p2 - p16)
         AddPathLine   (p2,      p2 + p8)
         AddPathLine   (p2 + p4, p2 + p4 + p16)
         ClosePath     ()
         FillPath      ()
         MovePathCursor(p2 + p4, p2 + p8)
         AddPathLine   (size,    p2 + p8)
         StrokePath    (p8)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i FromClipboard (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma, mod. 14.04.2016]
      Protected ret.i
      Protected hw.d = Round(size / 10.0, #PB_Round_Up)
      Protected p2.d = size / 2
      Protected p4.d = size / 4
      Protected p8.d = size / 8
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         ; box
         AddPathBox    (hw, hw, size - 2 * hw, size - hw - size / 32)
         StrokePath    (size / 16, #PB_Path_DiagonalCorner)
         ; ring
         AddPathCircle (p2, hw + 1, hw, 180, 0)
         StrokePath    (size / 32 + 0.1)
         ; clamb
         AddPathCircle (p2 + hw, 3*hw, hw-1, 180, 0)
         FillPath      ()
         StrokePath    (size / 16)
         AddPathCircle (p2 - hw, 3*hw, hw-1, 180, 0)
         FillPath      ()
         StrokePath    (size / 16)

         MovePathCursor(p2 - hw, 2 * hw)
         AddPathLine   (2 * hw, 0, #PB_Path_Relative)
         StrokePath    (2 * hw, #PB_Path_RoundCorner)

         ; arrow
         VectorSourceColor(color2)
         MovePathCursor(size - p4, p2 - p16)
         AddPathLine   (size,      p2 + p8)
         AddPathLine   (size - p4, p2 + p4 + p16)
         ClosePath     ()
         FillPath      ()
         MovePathCursor(p2, p2 + p8)
         AddPathLine   (size - p4, p2 + p8)
         StrokePath    (p8)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Copy (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected y.d = p * 4
      Protected w.d = p * 20
      Protected h.d = p * 24

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         ; page 1
         AddPathBox    (p, p, w - 3 * p, h - y)
         StrokePath    (2 * p, #PB_Path_RoundCorner)
         VectorSourceColor(color2)
         AddPathBox    (p, p, w - 3 * p, h - y)
         FillPath      ()
         StrokePath    (p)
         ; lines 1
         VectorSourceColor(color1)
         MovePathCursor( 3 * p,  6 * p)
         AddPathLine   (14 * p,  6 * p)
         MovePathCursor( 3 * p,  9 * p)
         AddPathLine   ( 6 * p,  9 * p)
         MovePathCursor( 3 * p, 12 * p)
         AddPathLine   (12 * p, 12 * p)
         MovePathCursor( 3 * p, 15 * p)
         AddPathLine   (10 * p, 15 * p)
         StrokePath    (p)

         ; page 2
         AddPathBox    (14 * p, -p + 3 * y, w - 3 * p, h - y)
         StrokePath    (2 * p, #PB_Path_RoundCorner)
         VectorSourceColor(color2)
         AddPathBox    (14 * p, -p + 3 * y, w - 3 * p, h - y)
         FillPath      ()
         StrokePath    (p)
         ; lines 2
         VectorSourceColor(color1)
         MovePathCursor(17 * p, 16 * p)
         AddPathLine   (28 * p, 16 * p)
         MovePathCursor(17 * p, 19 * p)
         AddPathLine   (20 * p, 19 * p)
         MovePathCursor(17 * p, 22 * p)
         AddPathLine   (26 * p, 22 * p)
         MovePathCursor(17 * p, 25 * p)
         AddPathLine   (24 * p, 25 * p)
         StrokePath(p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Paste (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d     = size / 32
      Protected y.d     = p * 4
      Protected w.d     = p * 20
      Protected h.d     = p * 24
      Protected whalf.d = w / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         ; boardframe
         AddPathBox     (p, y, w, h)
         StrokePath     (p * 1.5, #PB_Path_DiagonalCorner)
         ; ring
         AddPathCircle  (p + w / 2, y, 2 * p, 180, 0)
         StrokePath     (1)
         ; clamb
         MovePathCursor (p + whalf + whalf / 3, y)
         AddPathLine    (p + whalf + whalf / 3, y + 2 * p)
         AddPathLine    (3 * p + whalf + whalf / 3, y + 4 * p)
         AddPathLine    (-p + whalf - whalf / 3, y + 4 * p)
         AddPathLine    (p + whalf - whalf / 3, y + 2 * p)
         AddPathLine    (p + whalf - whalf / 3, y)
         ClosePath      ()
         FillPath       ()
         ; paper
         AddPathBox     (14 * p, -p + 3 * y, w - 3 * p, h - y)
         StrokePath     (2 * p, #PB_Path_RoundCorner)
         VectorSourceColor(color2)
         AddPathBox     (14 * p, -p + 3 * y, w - 3 * p, h - y)
         FillPath       ()
         StrokePath     (p)
         ; lines
         VectorSourceColor(color1)
         MovePathCursor(17 * p, 16 * p)
         AddPathLine   (28 * p, 16 * p)
         MovePathCursor(17 * p, 19 * p)
         AddPathLine   (20 * p, 19 * p)
         MovePathCursor(17 * p, 22 * p)
         AddPathLine   (26 * p, 22 * p)
         MovePathCursor(17 * p, 25 * p)
         AddPathLine   (24 * p, 25 * p)
         StrokePath    (p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Cut (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d    = size / 32
      Protected x.d    = p * 4,    x2.d = p * 6
      Protected half.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         ; grips
         AddPathEllipse   (half, 26 * p, 2.5 * p, 4 * p)
         StrokePath       (p * 2.5)
         RotateCoordinates(half, half + p, 45)
         AddPathEllipse   (half + p, 26 * p, 2.5 * p, 4 * p)
         StrokePath       (p * 2.5)
         ; blade diag.
         MovePathCursor   (half, 22 * p)
         AddPathLine      (half, x)
         AddPathLine      (half + 2 * p, x2)
         AddPathLine      (half + 2 * p, 22 * p)
         StrokePath       (p * 1.2)
         ; blade vert.
         RotateCoordinates(half, half + p, -45)
         MovePathCursor   (half - p, 22 * p)
         AddPathLine      (half - p, x2)
         AddPathLine      (half + p,  x)
         AddPathLine      (half + p, 22 * p)
         StrokePath       (p * 1.2)

         ; screw
         VectorSourceColor(#Background)
         AddPathCircle    (half, half + 2 * p, p)
         FillPath         ()
         ClosePath        ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Macro UnRedo()
      MovePathCursor(p4 - p, p4 + p)
      AddPathArc    (size - p8, p4+p, size - p8, size - p4 - p, p4 - p)
      AddPathArc    (size - p8, size - p4 - p, p8, size - p4 - p, p4 - p)
      AddPathLine   (p4, size - p4 - p)
      StrokePath    (p8 * 1.5)
      MovePathCursor(p8, size - p4 - p)
      AddPathLine   (p8 * 3, size - 2 * p4 - p)
      AddPathLine   (p8 * 3, size - p)
      ClosePath()
      FillPath()
   EndMacro

   Procedure.i Undo (file$, img.i, size.i, color.i, flipVertically.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img           : number of the image which is to be created, or #PB_Any
      ;      size          : width and height (number of pixels)
      ;      color         : foreground color
      ;      flipVertically: #True / #False
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma, extended by Little John]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p8.d = size / 8
      Protected p4.d = size / 4

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If flipVertically
            FlipCoordinatesY(size/2)
         EndIf

         VectorSourceColor(color)
         UnRedo()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Redo (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p8.d = size / 8
      Protected p4.d = size / 4

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)
         RotateCoordinates(size / 2, size / 2, 180)
         UnRedo()
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Open1 (file$, img.i, size.i, color.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color)

         ; box: round corners
         AddPathBox    (p16, p4 + p8, size - p8, size - p2 - p)
         StrokePath    (p8, #PB_Path_RoundCorner)
         AddPathBox    (p16, p4 + p8, size - p8, size - p2 - p)
         FillPath      ()

         ; card
         MovePathCursor(p16,        p2)
         AddPathArc    (p16,        p8,     p4 + p8,    p8,     p16)
         AddPathArc    (p4 + p8,    p8,     p4 + p8,    p4 - p, p16)
         StrokePath(p16, #PB_Path_Preserve)
         AddPathArc    (p4 + p8,    p4 - p, size - p16, p4 - p, p16)
         AddPathArc    (size - p16, p4 - p, size - p16, p2,     p16)
         AddPathLine   (size - p16, p2)
         StrokePath    (p16)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Open2 (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)

         ; card
         MovePathCursor(p16,      p2)
         AddPathArc    (p16,      p4,           p4 + p16,        p4,           p16)
         AddPathArc    (p4 + p16, p4,           p4 + p16,        p4 + p16 + p, p16)
         AddPathArc    (p4 + p16, p4 + p16 + p, size - p8 - p16, p4 + p16 + p, p16)
         StrokePath    (p16)

         ; sheet
         VectorSourceColor(color3)
         MovePathCursor(p4 + p8,   p2 + p4)
         AddPathLine   (p4 + p8,   p)
         AddPathLine   (size - p4, p)
         AddPathLine   (size - p,  p4)
         AddPathLine   (size - p,  p2 + p4)
         ClosePath()
         FillPath()

         ; frame
         VectorSourceColor(color2)
         MovePathCursor(p4 + p8,   p2 + p4)
         AddPathLine   (p4 + p8,   p)
         AddPathLine   (size - p4, p)
         AddPathLine   (size - p,  p4)
         AddPathLine   (size - p,  p2 + p4)
         ClosePath()

         ; dog-ear
         MovePathCursor(size - p4, p)
         AddPathLine   (size - p4, p4)
         AddPathLine   (size - p,  p4)
         StrokePath    (p)

         ; lines
         MovePathCursor(15 * p,  6 * p)
         AddPathLine   (19 * p,  6 * p)
         MovePathCursor(15 * p,  9 * p)
         AddPathLine   (24 * p,  9 * p)
         MovePathCursor(15 * p, 12 * p)
         AddPathLine   (22 * p, 12 * p)
         StrokePath    (p)

         ; box: round corners
         VectorSourceColor(color1)
         AddPathBox    (p16, p2, size - p4, size - p2 - p16)
         StrokePath    (p8, #PB_Path_RoundCorner)
         AddPathBox    (p16, p2, size - p4, size - p2 - p16)
         FillPath      ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Open3 (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)

         ;card
         MovePathCursor(p16,       p2)
         AddPathArc    (p16,       p4,           p4 + p16,  p4,           p16)
         AddPathArc    (p4 + p16,  p4,           p4 + p16,  p4 + p16 + p, p16)
         AddPathArc    (p4 + p16,  p4 + p16 + p, size - p4, p4 + p16 + p, p16)
         AddPathArc    (size - p4, p4 + p16 + p, size - p4, p2,           p16)
         AddPathLine   (size - p4, p2)
         StrokePath    (p16)

         ;box: round corners
         VectorSourceColor(color1)
         AddPathBox    (p16, p2, size - p4 - p16, size - p2 - p16)
         StrokePath    (p8, #PB_Path_RoundCorner)
         AddPathBox    (p16, p2, size - p4 - p16, size - p2 - p16)
         FillPath      ()

         VectorSourceColor(color2)
         MovePathCursor((p + p4) / 2, (size - p16 + p2 + p4) / 2)
         AddPathArc    (p4,         p2 + p4,    size - p16,   p2 + p4,                    p/2)
         AddPathArc    (size - p16, p2 + p4,    size - p4 ,   size - p16,                 p/2)
         AddPathArc    (size - p4,  size - p16, p,            size - p16,                 p/2)
         AddPathArc    (p,          size - p16, (p + p4) / 2, (size - p16 + p2 + p4) / 2, p/2)
         ClosePath     ()
         StrokePath    (p8)

         MovePathCursor((p + p4) / 2, (size - p16 + p2 + p4) / 2)
         AddPathArc    (p4,           p2 + p4,    size - p16,   p2 + p4,                    p/2)
         AddPathArc    (size - p16,   p2 + p4,    size - p4 ,   size - p16,                 p/2)
         AddPathArc    (size - p4,    size - p16, p,            size - p16,                 p/2)
         AddPathArc    (p,            size - p16, (p + p4) / 2, (size - p16 + p2 + p4) / 2, p/2)
         ClosePath     ()
         FillPath      ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Save2 (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)

         ; box: round corners
         AddPathBox(p8, p16, size - 2 * p8, size - p8)
         StrokePath(p8, #PB_Path_RoundCorner)
         VectorSourceColor(color2)
         AddPathBox(p8, p16, size - 2 * p8, size - p8)
         FillPath()
         ; arrow
         VectorSourceColor(color1)
         MovePathCursor(p2, p4)
         AddPathLine   (p2, p2)
         StrokePath    (p4)
         MovePathCursor(p2 - p4, p2)
         AddPathLine   (p2 + p4, p2)
         AddPathLine   (p2, size - p4)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SaveAs2 (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2 (default = 0: 100% transparent)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)

         ;box: round corners
         AddPathBox(p16, p, p2, p4 - p * 2)
         FillPath()
         AddPathBox(p16, p, size - p8, p4 - p * 2)
         StrokePath(p16)
         AddPathBox(p8, p4, size - p4, size - p4 - p16)
         StrokePath(p8, #PB_Path_RoundCorner)
         VectorSourceColor(color2)
         AddPathBox(p8, p4, size - p4, size - p4 - p16)
         FillPath()
         ;arrow
         VectorSourceColor(color1)
         MovePathCursor(p2, p2 - p8)
         AddPathLine   (p2, p2 + p8)
         StrokePath    (p4)
         MovePathCursor(p2 - p4, p2 + p8)
         AddPathLine   (p2 + p4, p2 + p8)
         AddPathLine   (p2, size - p8)
         ClosePath()
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Printer1 (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2
      Protected w.d   = p * 20
      Protected h.d   = p * 24

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; printer
         VectorSourceColor(color1)
         AddPathBox    (p16, p2, size - p8, p4)
         StrokePath    (p8, #PB_Path_RoundCorner)
         AddPathBox    (p, p2, size - p16, p4 + p8)
         FillPath      ()
         StrokePath    (p)

         ; sheet top
         AddPathBox    (p8 + p16, p, w, p2)
         StrokePath    (2 * p, #PB_Path_RoundCorner)
         VectorSourceColor(color2)
         AddPathBox    (p8 + p16, p, w, p2)
         FillPath      ()
         StrokePath    (p)
         ; lines
         VectorSourceColor(color1)
         MovePathCursor( 8 * p,  4 * p)
         AddPathLine   (17 * p,  4 * p)
         MovePathCursor( 8 * p,  7 * p)
         AddPathLine   (19 * p,  7 * p)
         MovePathCursor( 8 * p, 10 * p)
         AddPathLine   (12 * p, 10 * p)
         StrokePath    (p)

         ; sheet bottom
         AddPathBox    (p8, size - p4 + p, h, p8 + p16)
         StrokePath    (2 * p, #PB_Path_RoundCorner)
         VectorSourceColor(color2)
         AddPathBox    (p8, size - p4 + p, h, p8 + p16)
         FillPath      ()
         StrokePath    (p)

         ; added
         VectorSourceColor(color1)
         MovePathCursor(p16,         size - p4)
         AddPathLine   (size - p16,  size - p4)
         StrokePath    (p16)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i PrinterError1 (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ;      color4: foreground color #4
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2
      Protected w.d   = p * 20
      Protected h.d   = p * 24

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; printer
         VectorSourceColor(color1)
         AddPathBox    (p16, p2, size - p8, p4)
         StrokePath    (p8, #PB_Path_RoundCorner)
         AddPathBox    (p, p2, size - p16, p4 + p8)
         FillPath      ()
         StrokePath    (p)

         ; sheet top
         AddPathBox    (p8 + p16, p, w, p2)
         StrokePath    (2 * p, #PB_Path_RoundCorner)
         VectorSourceColor(color2)
         AddPathBox    (p8 + p16, p, w, p2)
         FillPath      ()
         StrokePath    (p)
         ;lines
         VectorSourceColor(color1)
         MovePathCursor( 8 * p,  4 * p)
         AddPathLine   (17 * p,  4 * p)
         MovePathCursor( 8 * p,  7 * p)
         AddPathLine   (19 * p,  7 * p)
         MovePathCursor( 8 * p, 10 * p)
         AddPathLine   (12 * p, 10 * p)
         StrokePath    (p)

         ; sheet bottom
         VectorSourceColor(color1)
         AddPathBox    (p8, size - p4 + p, h, p8 + p16)
         StrokePath    (2 * p, #PB_Path_RoundCorner)
         VectorSourceColor(color2)
         AddPathBox    (p8, size - p4 + p, h, p8 + p16)
         FillPath      ()
         StrokePath    (p)

         ; added later
         VectorSourceColor(color1)
         MovePathCursor(p16,         size - p4)
         AddPathLine   (size - p16,  size - p4)
         StrokePath    (p16)

         ; panel
         VectorSourceColor(color3)
         AddPathCircle    (size - p4, size - p4, p4)
         FillPath()
         VectorSourceColor(color4)
         AddPathCircle    (size - p4, size - p4, p4-p)
         StrokePath       (p)
         ; bar
         VectorSourceColor(color2)
         MovePathCursor   (size - 7 * p16, size - p4)
         AddPathLine      (6 * p16, 0, #PB_Path_Relative)
         StrokePath       (size/10)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i NewDocument (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         DocuSheet()
         ; lines
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (19 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (24 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (16 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (13 * p, 21 * p)
         MovePathCursor( 7 * p, 25 * p)
         AddPathLine   (14 * p, 25 * p)
         StrokePath    (p)
         ; +
         VectorSourceColor(color3)
         MovePathCursor(p2 + p8 + p,     p2 + p16)
         AddPathLine   (p2 + p8 + p,     size - p8)
         MovePathCursor(p2,              p2 + p4 - p)
         AddPathLine   (size - p8 - p16, p2 + p4 - p)
         StrokePath    (p16)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i EditDocument (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         DocuSheet()
         ; lines
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (19 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (20 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (15 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (10 * p, 21 * p)
         MovePathCursor( 7 * p, 25 * p)
         AddPathLine   ( 9 * p, 25 * p)
         StrokePath    (p)
         ; pen ...
         ScaleCoordinates    (0.9, 0.9)
         RotateCoordinates   (p2,   p2,  45.0)
         TranslateCoordinates(p * 8, -p)
         DrawPen_Flat(color3, color1, color3, color1, color3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ClearDocument (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         DocuSheet()
         ; clear
         VectorSourceColor(color3)
         MovePathCursor( 7 * p,  19 * p)
         AddPathLine   (13 * p,  13 * p)
         AddPathLine   (25 * p,  13 * p)
         AddPathLine   (25 * p,  25 * p)
         AddPathLine   (13 * p,  25 * p)
         ClosePath     ()
         FillPath      ()
         VectorSourceColor(color1)
         MovePathCursor(15 * p,  15 * p)
         AddPathLine   (23 * p,  23 * p)
         MovePathCursor(23 * p,  15 * p)
         AddPathLine   (15 * p,  23 * p)
         StrokePath    (p * 3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ImportDocument (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         DocuSheet()
         ; arrow
         VectorSourceColor(color3)
         MovePathCursor(p2 + p4, p2 - p16)
         AddPathLine   (p2,      p2 + p8)
         AddPathLine   (p2 + p4, p2 + p4 + p16)
         ClosePath     ()
         FillPath      ()
         MovePathCursor(p2 + p4, p2 + p8)
         AddPathLine   (size,    p2 + p8)
         StrokePath    (p8)

         VectorSourceColor(color1)
         MovePathCursor(p2 + p4,        p2 + p)
         AddPathLine   (size - p16 - p, p2 + p)
         MovePathCursor(p2 + p4,        p2 + p4 - p)
         AddPathLine   (size - p16 - p, p2 + p4 - p)
         StrokePath    (p16)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ExportDocument (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         DocuSheet()
         ; lines
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (19 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (24 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (12 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (11 * p, 21 * p)
         MovePathCursor( 7 * p, 25 * p)
         AddPathLine   (18 * p, 25 * p)
         StrokePath    (p)
         ; arrow
         VectorSourceColor(color3)
         MovePathCursor(size - p4, p2 - p16)
         AddPathLine   (size,      p2 + p8)
         AddPathLine   (size - p4, p2 + p4 + p16)
         ClosePath     ()
         FillPath      ()
         MovePathCursor(p2,        p2 + p8)
         AddPathLine   (size - p4, p2 + p8)
         StrokePath    (p8)
         ; clean frame - still 'dirty'
         VectorSourceColor(color1)
         MovePathCursor(p2 + p4 + p/4,    p / 2 * 25)
         AddPathLine   (size - p16 - p/2, p2 + p )
         MovePathCursor(p2 + p4 + p/4,    p / 2 * 55)
         AddPathLine   (size - p16 - p/2, p2 + p4 - p)
         StrokePath    (p16)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i CloseDocument (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ;      color4: foreground color #4
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         DocuSheet()
         ; lines
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (19 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (24 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (16 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (13 * p, 21 * p)
         MovePathCursor( 7 * p, 25 * p)
         AddPathLine   (14 * p, 25 * p)
         StrokePath    (p)
         ; panel
         VectorSourceColor(color3)
         AddPathCircle    (size - p4,      size - p4, p4)
         FillPath         ()
         VectorSourceColor(color4)
         AddPathCircle    (size - p4,      size - p4, p4 - p)
         StrokePath       (p)
         ; bar
         VectorSourceColor(color1)
         MovePathCursor   (size - 7 * p16, size - p4)
         AddPathLine      (6 * p16, 0, #PB_Path_Relative)
         StrokePath       (size / 10)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SortAscending (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         DocuSheet()
         ; lines
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (12 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (12 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (12 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (12 * p, 21 * p)
         MovePathCursor( 7 * p, 25 * p)
         AddPathLine   (12 * p, 25 * p)
         StrokePath    (p)
         ; arrow
         VectorSourceColor(color3)
         MovePathCursor   (p2 + p8,       p * 10)
         AddPathLine      (p2 + p8,       p2 + p16)
         StrokePath       (p8)
         MovePathCursor   (p2 - p16,      p2 + p16)
         AddPathLine      (p2 + p8,       size - p16 * 3)
         AddPathLine      (p2 + p4 + p16, p2 + p16)
         ClosePath        ()
         FillPath         ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SortDescending (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         DocuSheet()
         ; lines
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (12 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (12 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (12 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (12 * p, 21 * p)
         MovePathCursor( 7 * p, 25 * p)
         AddPathLine   (12 * p, 25 * p)
         StrokePath    (p)
         ; arrow
         VectorSourceColor(color3)
         MovePathCursor   (p2 + p8,       p2 + p16)
         AddPathLine      (p2 + p8,       size - p16 * 3)
         StrokePath       (p8)
         MovePathCursor   (p2 - p16,      p2 + p16)
         AddPathLine      (p2 + p8,       p16 * 5)
         AddPathLine      (p2 + p4 + p16, p2 + p16)
         ClosePath        ()
         FillPath         ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SortBlockAscending (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         DocuSheet()
         ; block
         AddPathBox    (6 * p, 9 * p, p2 + p8, p2)
         FillPath()
         ; lines
         MovePathCursor( 7 * p,  6 * p)
         AddPathLine   (12 * p,  6 * p)
         StrokePath    (p16)
         VectorSourceColor(color1)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (12 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (12 * p, 21 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (12 * p, 13 * p)
         StrokePath    (p16)
         ; arrow
         VectorSourceColor(color1)
         MovePathCursor   (p2 + p8,       p * 11)
         AddPathLine      (p2 + p8,       p2 + p16)
         StrokePath       (p8)
         MovePathCursor   (p2 - p16,      p2 + p)
         AddPathLine      (p2 + p8,       size - p4)
         AddPathLine      (p2 + p4 + p16, p2 + p)
         ClosePath        ()
         FillPath         ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SortBlockDescending (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         DocuSheet()
         ; block
         AddPathBox    (6 * p, 9 * p, p2 + p8, p2)
         FillPath      ()
         ; lines
         MovePathCursor( 7 * p,  6 * p)
         AddPathLine   (12 * p,  6 * p)
         StrokePath    (p16)
         VectorSourceColor(color1)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (12 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (12 * p, 21 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (12 * p, 13 * p)
         StrokePath    (p16)
         ; arrow
         VectorSourceColor(color1)
         MovePathCursor   (p2 + p8,       p2)
         AddPathLine      (p2 + p8,       size - p4 -p)
         StrokePath       (p8)
         MovePathCursor   (p2 - p16,      p2 + p)
         AddPathLine      (p2 + p8,       p * 10)
         AddPathLine      (p2 + p4 + p16, p2 + p)
         ClosePath        ()
         FillPath         ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartLine (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ;      color4: foreground color #4
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color4
            VectorSourceColor(color4)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;lines
         VectorSourceColor(color2)
         MovePathCursor(p8,      p2)
         AddPathLine   (p4,      p * 7)
         AddPathLine   (p2,      p * 15)
         AddPathLine   (p2 + p4, p * 8)
         AddPathLine   (size,    p * 22)
         StrokePath    (Round(p, #PB_Round_Up))
         VectorSourceColor(color3)
         MovePathCursor(p8,      p * 18)
         AddPathLine   (p4,      p * 22)
         AddPathLine   (p2,      p * 19)
         AddPathLine   (p2 + p4, p * 24)
         AddPathLine   (size,    p * 12)
         StrokePath    (Round(p, #PB_Round_Up))

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartDot (file$, img.i, size.i, color1.i, color2.i, color3.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color3
            VectorSourceColor(color3)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;dots
         VectorSourceColor(color2)
         AddPathCircle (p8,         p2,     p16)
         AddPathCircle (p4,         p * 7,  p16)
         AddPathCircle (p2,         p * 15, p16)
         AddPathCircle (p2 + p4,    p * 8,  p16)
         AddPathCircle (size - p16, p * 22, p16)
         FillPath         ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartLineDot (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ;      color4: foreground color #4
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color4
            VectorSourceColor(color4)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;lines
         VectorSourceColor(color2)
         MovePathCursor(p8,         p2)
         AddPathLine   (p4,         p * 7)
         AddPathLine   (p2,         p * 15)
         AddPathLine   (p2 + p4,    p * 8)
         AddPathLine   (size - p16, p * 22)
         StrokePath    (Round(p,    #PB_Round_Up))
         AddPathCircle (p8,         p2,     p16)
         AddPathCircle (p4,         p * 7,  p16)
         AddPathCircle (p2,         p * 15, p16)
         AddPathCircle (p2 + p4,    p * 8,  p16)
         AddPathCircle (size - p16, p * 22, p16)
         FillPath      ()

         VectorSourceColor(color3)
         MovePathCursor(p8,         p2 + p4)
         AddPathLine   (p4,         p * 19)
         AddPathLine   (p2,         p * 20)
         AddPathLine   (p2 + p4,    p * 24)
         AddPathLine   (size - p16, p * 12)
         StrokePath    (Round(p,    #PB_Round_Up))
         AddPathCircle (p8,         p2 + p4, p16)
         AddPathCircle (p4,         p * 19,  p16)
         AddPathCircle (p2,         p * 20,  p16)
         AddPathCircle (p2 + p4,    p * 24,  p16)
         AddPathCircle (size - p16, p * 12,  p16)
         FillPath      ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartPrice (file$, img.i, size.i, color1.i, color2.i, color3.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p12 = p * 6
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color3
            VectorSourceColor(color3)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;dots
         VectorSourceColor(color2)
         MovePathCursor   (p4,           p2 - p12)
         AddPathLine      (p4,           p2 + p12)
         MovePathCursor   (p4,           p2)
         AddPathLine      (p4 + p8,      p2)
         StrokePath       (1)

         VectorSourceColor(color2)
         MovePathCursor   (p2,           p * 22 - p8)
         AddPathLine      (p2,           p * 22 + p8)
         MovePathCursor   (p2,           p * 22)
         AddPathLine      (p2 + p8,      p * 22)
         StrokePath       (1)

         VectorSourceColor(color2)
         MovePathCursor   (p2 + p4,      p * 12 - p12)
         AddPathLine      (p2 + p4,      p * 12 + p12)
         MovePathCursor   (p2 + p4,      p * 12)
         AddPathLine      (p2 + p4 + p8, p * 12)
         StrokePath       (1)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartBarVert (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ;      color4: foreground color #4
      ;      color5: foreground color #5
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color5
            VectorSourceColor(color5)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;bars
         ChartBars(0.0)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartCylVert (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ;      color4: foreground color #4
      ;      color5: foreground color #5
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color5
            VectorSourceColor(color5)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;cylinders
         ChartCylBars(0.0)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartBarHor (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color5
            VectorSourceColor(color5)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;bars
         ChartBars(90.0)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartCylHor (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color5
            VectorSourceColor(color5)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;cylinders
         ChartCylBars(90.0)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartBarVertStacked (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color5
            VectorSourceColor(color5)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;bars
         ChartBarsStacked(0.0)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartBarHorStacked (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color5
            VectorSourceColor(color5)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;bars
         ChartBarsStacked(90.0)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartCylVertStacked (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color5
            VectorSourceColor(color5)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;cylinders
         ChartCylBarsStacked(0.0)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartCylHorStacked (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color5
            VectorSourceColor(color5)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;cylinders
         ChartCylBarsStacked(90.0)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartArea (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color4
            VectorSourceColor(color4)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;lines
         VectorSourceColor(color2)
         MovePathCursor(p8,      p * 18)
         AddPathLine   (p4,      p * 22)
         AddPathLine   (p2,      p * 19)
         AddPathLine   (p2 + p4, p * 24)
         AddPathLine   (size,    p * 22)
         AddPathLine   (size,    size - p16 - p)
         AddPathLine   (p8,      size - p16 - p)
         ClosePath     ()
         FillPath      (#PB_Path_Preserve)
         VectorSourceColor(Color_Darken(color2, 0.5))
         StrokePath    (1)

         VectorSourceColor(color3)
         MovePathCursor(p8,      p2)
         AddPathLine   (p4,      p * 7)
         AddPathLine   (p2,      p * 15)
         AddPathLine   (p2 + p4, p * 8)
         AddPathLine   (size,    p * 12)
         AddPathLine   (size,    p * 22)
         AddPathLine   (p2 + p4, p * 24)
         AddPathLine   (p2,      p * 19)
         AddPathLine   (p4,      p * 22)
         AddPathLine   (p8,      p * 18);
         ClosePath     ()
         FillPath      (#PB_Path_Preserve)
         VectorSourceColor(Color_Darken(color3, 0.5))
         StrokePath    (1)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartAreaPerc (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color5
            VectorSourceColor(color5)
            AddPathBox(1, 0, size - 1, size - 1)
            FillPath()
         EndIf
         ;scale
         ChartScale()
         ;lines
         VectorSourceColor(color2)
         MovePathCursor(p8,      p * 18)
         AddPathLine   (p4,      p * 22)
         AddPathLine   (p2,      p * 19)
         AddPathLine   (p2 + p4, p * 24)
         AddPathLine   (size,    p * 22)
         AddPathLine   (size,    size - p16 - p)
         AddPathLine   (p8,      size - p16 - p)
         ClosePath     ()
         FillPath      (#PB_Path_Preserve)
         VectorSourceColor(Color_Darken(color2, 0.5))
         StrokePath    (1)

         VectorSourceColor(color3)
         MovePathCursor(p8,      p2)
         AddPathLine   (p4,      p * 7)
         AddPathLine   (p2,      p * 15)
         AddPathLine   (p2 + p4, p * 8)
         AddPathLine   (size,    p * 12)
         AddPathLine   (size,    p * 22)
         AddPathLine   (p2 + p4, p * 24)
         AddPathLine   (p2,      p * 19)
         AddPathLine   (p4,      p * 22)
         AddPathLine   (p8,      p * 18)
         ClosePath     ()
         FillPath      (#PB_Path_Preserve)
         VectorSourceColor(Color_Darken(color3, 0.5))
         StrokePath    (1)

         VectorSourceColor(color4)
         MovePathCursor(p8,      p16)
         AddPathLine   (size,    p16)
         AddPathLine   (size,    p * 12)
         AddPathLine   (p2 + p4, p * 8)
         AddPathLine   (p2,      p * 15)
         AddPathLine   (p4,      p * 7)
         AddPathLine   (p8,      p2)
         ClosePath     ()
         FillPath      (#PB_Path_Preserve)

         VectorSourceColor(Color_Darken(color4, 0.5))
         StrokePath    (1)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartPie (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #3
      ;      color4: foreground color #4
      ;      color5: foreground color #5
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; border
         If color5
            VectorSourceColor(color5)
            AddPathBox(0, 0, size, size)
            FillPath()
         EndIf

         TranslateCoordinates(0, -p16)
         ; bottom right
         MovePathCursor   (size - p16, p2)
         AddPathEllipse   (p2, p2 + p8, p2 - p16, p2 - p4, 0, 90, #PB_Path_Connected)
         AddPathLine      (p2, p2 + p4)
         ClosePath()
         VectorSourceColor(Color_Darken(color3, 0.8))
         FillPath(#PB_Path_Preserve)
         VectorSourceColor(color1)
         StrokePath       (p)

         ; bottom left
         MovePathCursor   (p2,  p2 + p4)
         AddPathEllipse   (p2,  p2 + p8, p2 - p16, p2 - p4, 90, 180, #PB_Path_Connected)
         AddPathLine      (p16, p2)
         ClosePath()
         VectorSourceColor(Color_Darken(color4, 0.8))
         FillPath(#PB_Path_Preserve)
         VectorSourceColor(color1)
         StrokePath       (p)

         ; pieces
         MovePathCursor   (p2, p2)
         AddPathEllipse   (p2, p2, p2 - p16, p2 - p4, 210, 330, #PB_Path_Connected)
         VectorSourceColor(color2)
         ClosePath        ()
         FillPath(#PB_Path_Preserve)
         VectorSourceColor(color1)
         StrokePath       (p)

         CompilerIf #PB_Compiler_OS = #PB_OS_Windows
            ; Workaround for bug in PB 5.42 on Windows, see
            ; <http://www.purebasic.fr/english/viewtopic.php?f=4&t=65540>
            Protected.d x1, y1, x2, y2

            x1 = p2 + 0.69*p2 * Cos(Radian(330))
            y1 = p2 + 0.69*p2 * Sin(Radian(330))
            x2 = p2 + 0.53*p2 * Cos(Radian( 90))
            y2 = p2 + 0.53*p2 * Sin(Radian( 90))

            MovePathCursor(x1, y1)
            AddPathLine(x2, y2-0.03*p2)
            VectorSourceColor(color3)
            StrokePath       (p)

            AddPathEllipse   (p2, p2, p2 - p16, p2 - p4, 330, 90)
            MovePathCursor   (x1, y1)
            AddPathLine      (p2, p2)
            AddPathLine      (x2, y2)
            FillPath(#PB_Path_Preserve)
            VectorSourceColor(color1)
            StrokePath       (p)

         CompilerElse
            MovePathCursor   (p2, p2)
            AddPathEllipse   (p2, p2, p2 - p16, p2 - p4, 330, 90, #PB_Path_Connected)
            VectorSourceColor(color3)
            ClosePath        ()
            FillPath(#PB_Path_Preserve)
            VectorSourceColor(color1)
            StrokePath       (p)
         CompilerEndIf

         MovePathCursor   (p2, p2)
         AddPathEllipse   (p2, p2, p2 - p16, p2 - p4, 90, 210, #PB_Path_Connected)
         VectorSourceColor(color4)
         ClosePath        ()
         FillPath         (#PB_Path_Preserve)
         VectorSourceColor(color1)
         StrokePath       (p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ChartRing (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ;      color3: foreground color #1
      ;      color4: foreground color #2
      ;      color5: foreground color #1
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2
      Protected angle1.d, angle2.d, angle3.d

      CompilerIf #PB_Compiler_OS = #PB_OS_Windows
         angle1 = 196
         angle2 = 344
         angle3 = 90
      CompilerElse
         angle1 = 210
         angle2 = 330
         angle3 = 90
      CompilerEndIf

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;border
         If color5
            VectorSourceColor(color5)
            AddPathBox(0, 0, size, size)
            FillPath()
         EndIf

         TranslateCoordinates(0, -p)
         ;rand
         MovePathCursor   (size - p16 + p / 3, p2 + p)
         AddPathEllipse   (p2,                 p2 + p8, p2 - p16, p2 - p4 + p, 0, 90, #PB_Path_Connected)
         AddPathLine      (p2,                 p2 + p4)
         ClosePath()
         VectorSourceColor(Color_Darken(color3, 0.6))
         FillPath(#PB_Path_Preserve)
         StrokePath       (p)

         CompilerIf #PB_Compiler_OS = #PB_OS_Windows
            MovePathCursor   (p2 - p / 2, p2 + p8)
            AddPathLine      (p2 - p / 2, p2 + p4)
            AddPathEllipse   (p2,         p2 + p8, p2 - p16, p2 - p4 + p, 92, 180)
            AddPathLine      (p * 1.5,    p2 )
            AddPathLine      (p2 - p / 2, p2 + p8)
            ClosePath()
            VectorSourceColor(Color_Darken(color4, 0.6))
            FillPath(#PB_Path_Preserve)
            StrokePath       (p)
         CompilerElse
            MovePathCursor   (p2 - p / 2, p2 + p4)
            AddPathEllipse   (p2,         p2 + p8, p2 - p16, p2 - p4 + p, 92, 180, #PB_Path_Connected)
            AddPathLine      (p16 - p/3,  p2 + p)
            ClosePath()
            VectorSourceColor(Color_Darken(color4, 0.6))
            FillPath(#PB_Path_Preserve)
            StrokePath       (p)
         CompilerEndIf

         MovePathCursor   (p2 - p * 9, p2 - p4)
         AddPathEllipse   (p2,         p2 + p4 - p, p2 - p16, p2 - p4 + p, 230, 310, #PB_Path_Connected)
         AddPathLine      (p2 + p * 9, p2 - p4)
         ClosePath()
         VectorSourceColor(Color_Darken(color2, 0.6))
         FillPath(#PB_Path_Preserve)
         StrokePath       (p)

         ;pieces
         AddPathEllipse   (p2, p2 - p, p2 - p8, p4 - p, angle1, angle2)
         VectorSourceColor(color2)
         StrokePath       (p8+p16)

         AddPathEllipse   (p2, p2 - p, p2 - p8, p4 - p, angle2, angle3)
         VectorSourceColor(color3)
         StrokePath       (p8+p16)

         AddPathEllipse   (p2, p2 - p, p2 - p8, p4 - p, angle3, angle1)
         VectorSourceColor(color4)
         StrokePath       (p8+p16)
         ;lines
         VectorSourceColor(Color_Darken(color1, 0.6))
         MovePathCursor   (size - p * 3, p2 - p * 6)
         AddPathLine      (size - p * 8, p2 - p * 3)
         AddPathLine      (0,            p * 3,      #PB_Path_Relative)
         StrokePath       (p)

         MovePathCursor   (p * 3,        p2 - p * 6)
         AddPathLine      (p * 8,        p2 - p * 3)
         AddPathLine      (0,            p * 3,      #PB_Path_Relative)
         StrokePath       (p)

         MovePathCursor   (p2,           p2 + p * 3 )
         AddPathLine      (p2,           p2 + p / 2 * 26)
         StrokePath       (p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Notes (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      colorn: foreground color #n
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;border
         VectorSourceColor(color2)
         MovePathCursor(p16,        p4)
         AddPathLine   (size - p4,  p)
         AddPathLine   (size - p16, size - p4)
         AddPathLine   (p4,         size - p)
         ClosePath     ()
         FillPath      ()

         TranslateCoordinates(-p, -p)
         VectorSourceColor(color1)
         MovePathCursor   (p16,        p4)
         AddPathLine      (size - p4,  p)
         AddPathLine      (size - p16, size - p4)
         AddPathLine      (p4,         size - p)
         ClosePath        ()
         FillPath         ()

         ; pen ...
         ScaleCoordinates    (0.9, 0.9)
         RotateCoordinates   (p2,   p2,  45.0)
         TranslateCoordinates(p * 6, -p * 2)
         DrawPen_Flat(color3, color4, color3, color5, color3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Notes_Spatial (file$, img.i, size.i, color1.i, color2.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      colorn: foreground color #n
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; note ...
         VectorSourceColor(color2)
         MovePathCursor(p16,        p4)
         AddPathLine   (size - p4,  p)
         AddPathLine   (size - p16, size - p4)
         AddPathLine   (p4,         size - p)
         ClosePath     ()
         FillPath      ()

         TranslateCoordinates(-p, -p)
         GradientFullsize_AxisVhi(color1, 0.75)
         MovePathCursor(p16,        p4)
         AddPathLine   (size - p4,  p)
         AddPathLine   (size - p16, size - p4)
         AddPathLine   (p4,         size - p)
         ClosePath     ()
         FillPath      ()

         ; pen ...
         ScaleCoordinates    (0.9, 0.9)
         RotateCoordinates   (p2,   p2,  45.0)
         TranslateCoordinates(p * 6, -p16)
         DrawPen_Spatial(colorM1, colorM2, colorM3, colorM4, colorM5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure



   Macro FoldOpen(_rotation_)
      TranslateCoordinates(1, 1)
      If _rotation_
         RotateCoordinates(p2, p2, _rotation_)
      EndIf
      VectorSourceColor(color2)

      For i = 0 To 1
         ;Arrow front ...
         MovePathCursor(p16,          p * 5)
         AddPathLine   (size - p16 * 2, 0, #PB_Path_Relative)
         StrokePath    (p * 4)
         ;Arrow tips ...
         MovePathCursor(p * 3,  p * 11)
         AddPathLine   (p * 13, p * 19.5, #PB_Path_Relative)
         AddPathLine   (p * 13,-p * 19.5, #PB_Path_Relative)
         ClosePath     ()
         FillPath      ()
         If _rotation_ : RotateCoordinates(p2, p2, -_rotation_) : EndIf
         TranslateCoordinates(-1, -1)
         If _rotation_ : RotateCoordinates(p2, p2, _rotation_) : EndIf
         If spatial
            VectorSourceLinearGradient(0, 0, size, 0)
            VectorSourceGradientColor(Color_Darken(color1, 0.5), 0.0)
            VectorSourceGradientColor(color1, 0.5)
            VectorSourceGradientColor(Color_Darken(color1, 0.5), 1.0)
         Else
            VectorSourceColor(color1)
         EndIf
      Next i
   EndMacro

   Macro FoldClose(_rotation_)
      TranslateCoordinates(1, 1)
      If _rotation_
         RotateCoordinates(p2, p2, _rotation_)
      EndIf
      VectorSourceColor(color2)

      For i = 0 To 1
         ;Arrow front ...
         MovePathCursor(p16,        p * 5)
         AddPathLine   (size - p16 * 2, 0, #PB_Path_Relative)
         StrokePath    (p * 4)
         ;Arrow tips ...
         MovePathCursor(p * 3,  p * 29)
         AddPathLine   (p * 13,-p * 19.5, #PB_Path_Relative)
         AddPathLine   (p * 13, p * 19.5, #PB_Path_Relative)
         ClosePath     ()
         FillPath      ()
         If _rotation_ : RotateCoordinates(p2, p2, -_rotation_) : EndIf
         TranslateCoordinates(-1, -1)
         If _rotation_ : RotateCoordinates(p2, p2, _rotation_) : EndIf
         If spatial
            VectorSourceLinearGradient(0, 0, size, 0)
            VectorSourceGradientColor(Color_Darken(color1, 0.5), 0.0)
            VectorSourceGradientColor(color1, 0.5)
            VectorSourceGradientColor(Color_Darken(color1, 0.5), 1.0)
         Else
            VectorSourceColor(color1)
         EndIf
      Next i
   EndMacro

   Macro ArrowBow (_color_, _rotation_, _flip_)
      If _flip_     : FlipCoordinatesY(p2)                : EndIf
      If _rotation_ : RotateCoordinates(p2, p2, _rotation_) : EndIf
      VectorSourceColor(#CSS_White)

      For i = 1 To 2
         MovePathCursor(p * 19, p * 7)
         AddPathLine   (p * 31, p * 19)
         AddPathLine   (p * 19, p * 31)
         ClosePath     ()
         FillPath      ()

         MovePathCursor(p4,     p)
         AddPathArc    (p4,     p * 19, p * 21, p * 19, p * 11)
         AddPathLine   (p * 24, p * 19)
         StrokePath    (p * 10)
         RotateCoordinates(p2, p2, -_rotation_)
         If flip
            TranslateCoordinates(-1, 1)
         Else
            TranslateCoordinates(-1, -1)
         EndIf
         RotateCoordinates(p2, p2, _rotation_)
         VectorSourceColor(_color_)
      Next i
   EndMacro


   Procedure.i Unfold (file$, img.i, size.i, color1.i, color2.i, rotation.d= 0, spatial.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img    : number of the image which is to be created, or #PB_Any
      ;      size   : width and height (number of pixels)
      ;      color1 : Arrow color
      ;      color2 : Arrow tail color
      ;      spatial: gradient on (= #True)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         FoldOpen(rotation)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Fold (file$, img.i, size.i, color1.i, color2.i, rotation.d= 0, spatial.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1 : Arrow color
      ;      color2 : Arrow tail color
      ;      spatial: gradient on (= #True)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         FoldClose(rotation)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ArrowBowLeft (file$, img.i, size.i, color.i, rotation.d= 0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img     : number of the image which is to be created, or #PB_Any
      ;      size    : width and height (number of pixels)
      ;      color   : foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [Oma]
      Protected ret.i, i.i
      Protected p.d    = size / 32
      Protected p2.d   = size / 2
      Protected p4.d   = size / 4
      Protected flip.i = #False

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ArrowBow(color, rotation, flip)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ArrowBowRight (file$, img.i, size.i, color.i, rotation.d= 0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img     : number of the image which is to be created, or #PB_Any
      ;      size    : width and height (number of pixels)
      ;      color   : foreground color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [Oma]
      Protected ret.i, i.i
      Protected p.d    = size / 32
      Protected p2.d   = size / 2
      Protected p4.d   = size / 4
      Protected flip.i = #True

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ArrowBow(color, rotation, flip)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i BracketRound (file$, img.i, size.i, color.i, Open=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ;      open : the open (left) bracket
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If Open
            FlipCoordinatesX(p2)
         EndIf

         VectorSourceColor(color)
         For i = 1 To 2
            MovePathCursor(p * 12, p * 2.5)
            AddPathCurve  (p * 20, p *  6, p * 20, p * 13, p * 20, p * 16.5)
            AddPathCurve  (p * 20, p * 20, p * 20, p * 27, p * 12, p * 30.5)
            StrokePath    (p * 3, #PB_Path_RoundEnd)
            TranslateCoordinates(Pow(-1, Bool(Open ! 1)), -1)
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i BracketSquare (file$, img.i, size.i, color.i, Open=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ;      open : the open (left) bracket
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If Open
            FlipCoordinatesX(p2)
         EndIf

         VectorSourceColor(color)
         For i = 1 To 2
            MovePathCursor( p * 12, p * 2.5)
            AddPathLine   ( p * 8,  0,      #PB_Path_Relative)
            AddPathLine   ( 0    ,  p * 28, #PB_Path_Relative)
            AddPathLine   (-p * 8,  0,      #PB_Path_Relative)
            StrokePath    ( p * 3, #PB_Path_RoundEnd)
            TranslateCoordinates(Pow(-1, Bool(Open ! 1)), -1)
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i BracketAngle (file$, img.i, size.i, color.i, Open=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ;      open : the open (left) bracket
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If Open
            FlipCoordinatesX(p2)
         EndIf

         VectorSourceColor(color)
         For i = 1 To 2
            MovePathCursor( p * 12, p * 2.5)
            AddPathLine   ( p * 8,  p * 14,  #PB_Path_Relative)
            AddPathLine   (-p * 8,  p * 14,  #PB_Path_Relative)
            StrokePath    ( p * 3, #PB_Path_RoundEnd)
            TranslateCoordinates(Pow(-1, Bool(Open ! 1)), -1)
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i BracketCurly (file$, img.i, size.i, color.i, Open=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ;      open : the open (left) bracket
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If Open
            FlipCoordinatesX(p2)
         EndIf

         VectorSourceColor(color)
         For i = 1 To 2
            MovePathCursor(p * 11, p * 2.5)
            AddPathCurve  (p * 21, p *  6, p * 11, p * 12.5, p * 21, p * 16.5)
            AddPathCurve  (p * 11, p * 20.5, p * 21, p * 27, p * 11, p * 30.5)
            StrokePath    (p * 3, #PB_Path_RoundEnd)
            TranslateCoordinates(Pow(-1, Bool(Open ! 1)), -1)
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i BracketHtml (file$, img.i, size.i, color.i, Open=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ;      color: foreground color
      ;      open : the open (left) bracket
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If Open
            FlipCoordinatesX(p2)
         EndIf

         VectorSourceColor(color)
         For i = 1 To 2
            MovePathCursor( p *  8,  p * 11)
            AddPathLine   (-p *  5,  p * 5,   #PB_Path_Relative)
            AddPathLine   ( p *  5,  p * 5,   #PB_Path_Relative)
            MovePathCursor( p * 25,  p * 11)
            AddPathLine   ( p *  5,  p * 5,   #PB_Path_Relative)
            AddPathLine   (-p *  5,  p * 5,   #PB_Path_Relative)
            StrokePath    ( p *  3,  #PB_Path_RoundEnd)
            MovePathCursor( p * 11,  p * 29.5)
            AddPathLine   ( p * 10, -p * 26,  #PB_Path_Relative)
            TranslateCoordinates(Pow(-1, Bool(Open ! 1)), -1)
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Compare (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1 : dish color
      ;      color2 : wire & arms color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;weighbridge
         ; socket
         VectorSourceColor(color1)
         AddPathCircle (p2, size * 1.6, size * 0.72, 245, 295)
         ClosePath     ()
         StrokePath    (p16, #PB_Path_RoundCorner | #PB_Path_Preserve)
         FillPath      ()
         ; rod
         MovePathCursor(p * 16, p * 27.5)
         AddPathLine   (0,     -p * 19, #PB_Path_Relative)
         StrokePath    (p * 3)
         VectorSourceColor(Color_Darken(color1, 0.7))
         ; axis
         AddPathCircle (p2,     p *  6, p * 2)
         FillPath      ()
         ; hub
         VectorSourceColor(color2)
         AddPathCircle (p2,     p *  6, p * 3)
         StrokePath    (p)

         For i = 1 To 2
            ; arms
            VectorSourceColor(color2)
            MovePathCursor(p * 13,  p *  6)
            AddPathLine   (-p * 6,  0,      #PB_Path_Relative)
            AddPathLine   (-p * 5,  p * 15, #PB_Path_Relative)
            AddPathLine   ( p * 10, 0,      #PB_Path_Relative)
            AddPathLine   (-p * 5, -p * 15, #PB_Path_Relative)
            MovePathCursor(p * 19,  p *  6)
            AddPathLine   (p * 6,  0, #PB_Path_Relative)
            StrokePath    (p)
            ; dishes
            VectorSourceColor(color1)
            AddPathCircle (p * 7, p * 16, p * 8, 35, 145)
            ClosePath     ()
            FillPath      ()
            FlipCoordinatesX(p2)
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Site (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: cone & socket
      ;      color2: stripes
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; socket
         VectorSourceColor(color_darken(color1, 0.95))
         MovePathCursor   (p *  3, p * 30)
         AddPathLine      (p * 26, 0, #PB_Path_Relative)
         StrokePath       (p * 3, #PB_Path_RoundEnd)
         ; cone
         VectorSourceColor(color1)
         MovePathCursor( p * 17.5, p * 2)
         AddPathLine   ( p *  8, p * 26.5, #PB_Path_Relative)
         AddPathLine   (-p * 19, 0,        #PB_Path_Relative)
         AddPathLine   ( p *  8,-p * 26.5, #PB_Path_Relative)
         ClosePath     ()
         ClipPath      (#PB_Path_Preserve)
         FillPath      ()
         ; stripes
         VectorSourceColor(color2)
         MovePathCursor(p *  8, p * 22)
         AddPathLine   (p * 24, 0,       #PB_Path_Relative)
         MovePathCursor(p *  8, p * 16)
         AddPathLine   (p * 24, 0,       #PB_Path_Relative)
         MovePathCursor(p *  8, p * 10)
         AddPathLine   (p * 24, 0,       #PB_Path_Relative)
         StrokePath(p * 3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   ;- * * *  Icon set #2  * * *

   Procedure.i FindAndReplace (file$, img.i, size.i, color1.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: magnifier
      ;      color2: pen shaft
      ;      color3: pen rubber & tip
      ;      color4: pen tip wood
      ;      color5: pen rubber sleeve
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         RotateCoordinates(p2, p2, -90.0)
         VectorSourceColor(color1)
         DrawMagnifyingGlass (p * 5, p * 3, size / 1.3, #True)
         RotateCoordinates(p2, p2, 90.0)

         ; pen ...
         ScaleCoordinates    (0.85, 0.85)
         RotateCoordinates   (p2,   p2,  45.0)
         TranslateCoordinates(p * 12, p *1.5)
         DrawPen_Flat(colorM1, colorM2, colorM3, colorM4, colorM5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Open1_Spatial (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: map
      ;      color2: card
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; card
         VectorSourceLinearGradient(0, 0, size, 0)
         VectorSourceGradientColor(Color_Darken(color2, 0.85), 0.0)
         VectorSourceGradientColor(Color_Darken(color2, 0.7), 1.0)
         MovePathCursor(p16,        p2)
         AddPathArc    (p16,        p8,     p4 + p8,    p8,     p16)
         AddPathArc    (p4 + p8,    p8,     p4 + p8,    p4 - p, p16)
         StrokePath    (p16, #PB_Path_Preserve)
         AddPathArc    (p4 + p8,    p4 - p, size - p16, p4 - p, p16)
         AddPathArc    (size - p16, p4 - p, size - p16, p2,     p16)
         AddPathLine   (size - p16, p2)
         ClosePath     ()
         FillPath      (#PB_Path_Preserve)
         StrokePath    (p16)
         ; box: round corners
         GradientFullsize_LT2RB(color1, 0.5)
         AddPathBox    (p16, p4 + p8, size - p8, size - p2 - p)
         StrokePath    (p8, #PB_Path_RoundCorner)
         AddPathBox    (p16, p4 + p8, size - p8, size - p2 - p)
         FillPath      ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Open2_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: map
      ;      color2: card
      ;      color3: sheet frame
      ;      color4: sheet
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; card
         VectorSourceLinearGradient(0, 0, size, 0)
         VectorSourceGradientColor(Color_Darken(color2, 0.85), 0.0)
         VectorSourceGradientColor(Color_Darken(color2, 0.7), 1.0)
         MovePathCursor(p16,      p2)
         AddPathArc    (p16,      p4,           p4 + p16,        p4,           p16)
         AddPathArc    (p4 + p16, p4,           p4 + p16,        p4 + p16 + p, p16)
         AddPathArc    (p4 + p16, p4 + p16 + p, size - p8 - p16, p4 + p16 + p, p16)
         AddPathLine   (size - p8 - p16, p2)
         ClosePath     ()
         FillPath      (#PB_Path_Preserve)
         StrokePath    (p16)

         ; sheet
         GradientFullsize_LT2RB(color4, 0.8)
         MovePathCursor(p4 + p8,   p2 + p4)
         AddPathLine   (p4 + p8,   p)
         AddPathLine   (size - p4, p)
         AddPathLine   (size - p,  p4)
         AddPathLine   (size - p,  p2 + p4)
         ClosePath()
         FillPath()
         ; frame
         GradientFullsize_LT2RB(color3, 0.5)
         MovePathCursor(p4 + p8,   p2 + p4)
         AddPathLine   (p4 + p8,   p)
         AddPathLine   (size - p4, p)
         AddPathLine   (size - p,  p4)
         AddPathLine   (size - p,  p2 + p4)
         ClosePath()
         ; dog-ear
         MovePathCursor(size - p4, p)
         AddPathLine   (size - p4, p4)
         AddPathLine   (size - p,  p4)
         StrokePath    (p)
         ; lines
         MovePathCursor(15 * p,  6 * p)
         AddPathLine   (19 * p,  6 * p)
         MovePathCursor(15 * p,  9 * p)
         AddPathLine   (24 * p,  9 * p)
         MovePathCursor(15 * p, 12 * p)
         AddPathLine   (22 * p, 12 * p)
         StrokePath    (p)

         ; box: round corners
         GradientFullsize_LT2RB(color1, 0.5)
         AddPathBox    (p16, p * 15, size - p4, p * 15)
         StrokePath    (p8, #PB_Path_RoundCorner)
         AddPathBox    (p16, p * 15, size - p4, p * 15)
         FillPath      ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Open3_Spatial (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: map + darkend @ flap
      ;      color2: card
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;card
         VectorSourceLinearGradient(0, 0, size, 0)
         VectorSourceGradientColor(Color_Darken(color2, 0.85), 0.0)
         VectorSourceGradientColor(Color_Darken(color2, 0.7), 1.0)
         MovePathCursor(p16,       p2)
         AddPathArc    (p16,       p4,           p4 + p16,  p4,           p16)
         AddPathArc    (p4 + p16,  p4,           p4 + p16,  p4 + p16 + p, p16)
         AddPathArc    (p4 + p16,  p4 + p16 + p, size - p4, p4 + p16 + p, p16)
         AddPathArc    (size - p4, p4 + p16 + p, size - p4, p2,           p16)
         AddPathLine   (size - p4, p2)
         ClosePath     ()
         FillPath      (#PB_Path_Preserve)
         StrokePath    (p16)

         ;box: round corners
         GradientFullsize_LT2RB(color1, 0.5)
         AddPathBox    (p16, p * 15, size - p4 - p16, p * 15)
         StrokePath    (p8, #PB_Path_RoundCorner)
         AddPathBox    (p16, p * 15, size - p4 - p16, p * 15)
         FillPath      ()

         VectorSourceLinearGradient(0, p2, size, size)
         VectorSourceGradientColor(Color_Darken(color1, 0.95), 0.0)
         VectorSourceGradientColor(Color_Darken(color1, 0.5), 1.0)
         MovePathCursor((p + p4) / 2, (size - p16 + p2 + p4) / 2)
         AddPathArc    (p4,         p2 + p4,    size - p16,   p2 + p4,                    p/2)
         AddPathArc    (size - p16, p2 + p4,    size - p4 ,   size - p16,                 p/2)
         AddPathArc    (size - p4,  size - p16, p,            size - p16,                 p/2)
         AddPathArc    (p,          size - p16, (p + p4) / 2, (size - p16 + p2 + p4) / 2, p/2)
         ClosePath     ()
         StrokePath    (p8)

         MovePathCursor((p + p4) / 2, (size - p16 + p2 + p4) / 2)
         AddPathArc    (p4,           p2 + p4,    size - p16,   p2 + p4,                    p/2)
         AddPathArc    (size - p16,   p2 + p4,    size - p4 ,   size - p16,                 p/2)
         AddPathArc    (size - p4,    size - p16, p,            size - p16,                 p/2)
         AddPathArc    (p,            size - p16, (p + p4) / 2, (size - p16 + p2 + p4) / 2, p/2)
         ClosePath     ()
         FillPath      ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i FindFile_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: card
      ;      color2: folder
      ;      color2: magnifying glass
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         TranslateCoordinates(0, -p * 6)
         ;card
         VectorSourceLinearGradient(0, 0, size, 0)
         VectorSourceGradientColor(Color_Darken(color2, 0.85), 0.0)
         VectorSourceGradientColor(Color_Darken(color2, 0.7), 1.0)
         MovePathCursor(p16,       p2)
         AddPathArc    (p16,       p4,           p4 + p16,  p4,           p16)
         AddPathArc    (p4 + p16,  p4,           p4 + p16,  p4 + p16 + p, p16)
         AddPathArc    (p4 + p16,  p4 + p16 + p, size - p4, p4 + p16 + p, p16)
         AddPathArc    (size - p4, p4 + p16 + p, size - p4, p2,           p16)
         AddPathLine   (size - p4, p2)
         ClosePath     ()
         FillPath      (#PB_Path_Preserve)
         StrokePath    (p16)

         ;box: round corners
         GradientFullsize_LT2RB(color1, 0.5)
         AddPathBox    (p16, p * 15, size - p4 - p16, p * 15)
         StrokePath    (p8, #PB_Path_RoundCorner)
         AddPathBox    (p16, p * 15, size - p4 - p16, p * 15)
         FillPath      ()
         TranslateCoordinates(0, p * 6)
         ;
         ;magnifying glass
         RotateCoordinates(p2, p2, -90.0)
         VectorSourceColor(color3)
         DrawMagnifyingGlass (0, p * 5, size / 1.4, #True)
         RotateCoordinates(p2, p2, 90.0)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i FindFile (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: folder
      ;      color2: magnifying glass
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         TranslateCoordinates(0, -p * 6)
         ;box: round corners
         AddPathBox    (p16, p2, size - p4 - p16, size - p2 - p16)
         StrokePath    (p8, #PB_Path_RoundCorner)
         AddPathBox    (p16, p2, size - p4 - p16, size - p2 - p16)
         FillPath      ()

         ;card
         MovePathCursor(p16,       p2)
         AddPathArc    (p16,       p4,           p4 + p16,  p4,           p16)
         AddPathArc    (p4 + p16,  p4,           p4 + p16,  p4 + p16 + p, p16)
         AddPathArc    (p4 + p16,  p4 + p16 + p, size - p4, p4 + p16 + p, p16)
         AddPathArc    (size - p4, p4 + p16 + p, size - p4, p2,           p16)
         AddPathLine   (size - p4, p2)
         StrokePath    (p16)
         TranslateCoordinates(0, p * 6)

         RotateCoordinates(p2, p2, -90.0)
         VectorSourceColor(color2)
         DrawMagnifyingGlass (0, p * 5, size / 1.4, #True)
         RotateCoordinates(p2, p2, 90.0)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i RotateDown_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: Arrow color
      ;      color2: Arrow tail color
      ;      color3: Stick bright color
      ;      color4: background color, optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color4
            VectorSourceColor(color4)
            AddPathBox(0, 0, size, size)
            FillPath()
         EndIf

         RotateStickDirection_Spatial()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i RotateUp_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: Arrow color
      ;      color2: Arrow tail color
      ;      color3: Stick bright color
      ;      color4: background color, optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color4
            VectorSourceColor(color4)
            AddPathBox(0, 0, size, size)
            FillPath()
         EndIf

         FlipCoordinatesY(p2)
         RotateStickDirection_Spatial()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i RotateVert_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: Arrow, bright color
      ;      color2: Stick, bright color
      ;      color3: background color, optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d  = size / 32
      Protected p4.d = size / 4
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color3
            VectorSourceColor(color3)
            AddPathBox(0, 0, size, size)
            FillPath()
         EndIf

         RotateStickDimension_Spatial()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i RotateLeft_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: Arrow color
      ;      color2: Arrow tail color
      ;      color3: Stick bright color
      ;      color4: background color, optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color4
            VectorSourceColor(color4)
            AddPathBox(0, 0, size, size)
            FillPath()
         EndIf

         RotateCoordinates(p2, p2, 90.0)
         RotateStickDirection_Spatial()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i RotateRight_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: Arrow color
      ;      color2: Arrow tail color
      ;      color3: Stick bright color
      ;      color4: background color, optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color4
            VectorSourceColor(color4)
            AddPathBox(0, 0, size, size)
            FillPath()
         EndIf

         RotateCoordinates(p2, p2, 90.0)
         FlipCoordinatesY(p2)
         RotateStickDirection_Spatial()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i RotateHor_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: Arrow, bright color
      ;      color2: Stick, bright color
      ;      color3: background color, optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d  = size / 32
      Protected p4.d = size / 4
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color3
            VectorSourceColor(color3)
            AddPathBox(0, 0, size, size)
            FillPath()
         EndIf

         RotateCoordinates(p2, p2, 90.0)
         RotateStickDimension_Spatial()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i RotateCcw_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: arrow foreground color
      ;      color2: axis foreground color
      ;      color3: background color, optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color3
            VectorSourceColor(color3)
            AddPathBox(0, 0, size, size)
            FillPath()
         EndIf

         RotateCoordinates(p2, p2, 90.0)
         RotateStickCw_Spatial()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i RotateCw_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: arrow foreground color
      ;      color2: axis foreground color
      ;      color3: background color, optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If color3
            VectorSourceColor(color3)
            AddPathBox(0, 0, size, size)
            FillPath()
         EndIf

         RotateCoordinates(p2, p2, 90.0)
         FlipCoordinatesY(p2)
         RotateStickCw_Spatial()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Writingpad (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i, color7.i, color8.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet, spiral part (bright)
      ;      color2: sheet shadow
      ;      color3: spiral part (dark)
      ;      color4: pen rubber
      ;      color5: pen sleeve
      ;      color6: pen body
      ;      color7: pen tip wood
      ;      color8: pen tip
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;sheet shadow
         VectorSourceColor(color2)
         AddPathBox       (p8 + p, p * 6, p2 + p4, size - p * 6)
         FillPath         ()
         ;sheet
         VectorSourceColor(color1)
         AddPathBox       (p8,     p8,    p2 + p4, size - p * 5)
         FillPath         ()
         ;frame
         VectorSourceColor(color2)
         MovePathCursor   (p8,        p8)
         AddPathLine      (p8,        size - p)
         MovePathCursor   (p8,        p8)
         AddPathLine      (size - p8, p8)
         StrokePath       (p * 0.25)

         ;spiral ...
         For i = 7 To 25 Step 6
            VectorSourceColor(color2)
            AddPathCircle    (p * i,           p * 7, p16)
            FillPath         ()
            VectorSourceColor(color3)
            MovePathCursor   (p * i - p / 2,   p * 7.5)
            AddPathLine      (p * i + p / 2,   p * 2)
            StrokePath       (p)
            VectorSourceColor(color1)
            MovePathCursor   (p * i + p / 2,   p * 7.5)
            AddPathLine      (p * i + p * 1.5, p * 2)
            StrokePath       (p)
         Next i
         ;lines ...
         VectorSourceColor(color2)
         For i = 12 To 28 Step 4
            VectorSourceColor(color2)
            MovePathCursor   (p * 7,  p * i)
            AddPathLine      (p * 26, p * i)
            StrokePath       (p / 2)
         Next i

         ; pen ...
         ScaleCoordinates    (0.9, 0.9)
         RotateCoordinates   (p2,   p2,  45.0)
         TranslateCoordinates(p * 8, -p)
         DrawPen_Flat(color4, color5, color6, color7, color8)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Writingpad_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i, color7.i, color8.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet, spiral part (bright)
      ;      color2: sheet shadow
      ;      color3: spiral part (dark)
      ;      color4: pen rubber
      ;      color5: pen sleeve
      ;      color6: pen body
      ;      color7: pen tip wood
      ;      color8: pen tip
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         SaveVectorState     ()
         RotateCoordinates   (p2,  p2, -15.0)
         TranslateCoordinates(0,  -p)
         ScaleCoordinates    (0.95, 0.95)

         ;sheet shadow
         VectorSourceColor(color2)
         AddPathBox       (p8 + p, p * 6, p2 + p4, size - p * 6)
         FillPath         ()
         ;sheet
         GradientFullsize_AxisVhi(color1, 0.85)
         AddPathBox       (p8,     p8,    p2 + p4, size - p * 5)
         FillPath         ()
         ;frame
         VectorSourceColor(color2)
         MovePathCursor   (p8,        p8)
         AddPathLine      (p8,        size - p)
         MovePathCursor   (p8,        p8)
         AddPathLine      (size - p8, p8)
         StrokePath       (p * 0.25)

         ;spiral
         For i = 7 To 25 Step 6
            VectorSourceColor(color2)
            AddPathCircle    (p * i,           p * 7, p16)
            FillPath         ()
            VectorSourceColor(color3)
            MovePathCursor   (p * i - p / 2,   p * 7.5)
            AddPathLine      (p * i + p / 2,   p * 2)
            StrokePath       (p)
            VectorSourceColor(color1)
            MovePathCursor   (p * i + p / 2,   p * 7.5)
            AddPathLine      (p * i + p * 1.5, p * 2)
            StrokePath       (p)
         Next i
         ;lines
         VectorSourceColor(color2)
         For i = 12 To 28 Step 4
            VectorSourceColor(color2)
            MovePathCursor   (p * 7,  p * i)
            AddPathLine      (p * 26, p * i)
            StrokePath       (p / 2)
         Next i

         ; pen ...
         RestoreVectorState()
         ScaleCoordinates    (0.9, 0.9)
         RotateCoordinates   (p2,   p2,  45.0)
         TranslateCoordinates(p * 6, -p16)
         DrawPen_Spatial(color4, color5, color6, color7, color8)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Calculate_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: body & border
      ;      color2: display back
      ;      color3: display numbers
      ;      color4: buttons
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, O.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;border
         GradientFullsize_LT2RB(color1, 0.4)
         AddPathBox(p8, p16, size - p4, size - p8)
         StrokePath(p8, #PB_Path_RoundCorner)
         ;body
         VectorSourceColor(Color_Darken(color1, 0.7))
         AddPathBox(p8, p * 2, size - p4, size - p * 4)
         FillPath()
         ;display
         VectorSourceColor(color2)
         AddPathBox(p * 5, p * 3, p * 22, p * 8)
         FillPath()
         ;0
         VectorSourceColor(color3)
         AddPathBox(p * 22, p * 4, p * 3, p * 6)
         StrokePath(p)
         ;keys
         VectorSourceColor(color4)
         For O = 0 To 2
            For i = 1 To 4
               AddPathBox((p * 6) * i, p * 14 + (p * 6) * O, p16, p16)
               FillPath(#PB_Path_Preserve)
               StrokePath(p16, #PB_Path_RoundCorner)
            Next i
         Next O

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Calendar_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet, wire part
      ;      color2: spiral hole
      ;      color3: grid, leftframe, wire part
      ;      color4: bar
      ;      color5: shadow
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;sheet shadow
         VectorSourceColor(color5)
         AddPathBox(p, p * 8, size - p, size - p * 8)
         FillPath  ()
         ;sheet
         ;GradientFullsize_AxisVhi(color1, 0.85)
         VectorSourceColor(color1)
         AddPathBox(0, p * 7, size - p, size - p * 8)
         FillPath  ()
         ;left frame
         VectorSourceColor(color3)
         MovePathCursor(0, p4)
         AddPathLine(0, size - p)
         StrokePath (p * 0.5)
         ;bar
         VectorSourceLinearGradient(0, p8, 0, p * 10)
         VectorSourceGradientColor(color4, 0.0)
         VectorSourceGradientColor(Color_Darken(color4, 0.5), 1.0)
         AddPathBox(0, p8, size, p * 6)
         FillPath  ()

         ;spiral
         For i = 7 To 25 Step 18
            VectorSourceColor(color2)
            AddPathCircle (p * i, p * 7, p16)
            FillPath      ()
            VectorSourceColor(color3)
            MovePathCursor(p * i - p/2, p * 7.5)
            AddPathLine   (p * i - p/2, p * 2)
            StrokePath    (p)
            VectorSourceColor(color1)
            MovePathCursor(p * i + p/2, p * 7.5)
            AddPathLine   (p * i + p/2, p * 2)
            StrokePath    (p)
         Next i
         ;headline
         VectorSourceColor(color2)
         AddPathBox      (p * 2, p * 12, size - p8, p * 3)
         FillPath        ()
         ;grid
         VectorSourceColor(color3)
         For i = 12 To 30 Step 3
            MovePathCursor(p * 2, p * i)
            AddPathLine   (p * 30, p * i)
            StrokePath    (p / 4)
         Next i
         For i = 2 To 30 Step 4
            MovePathCursor(p * i, p * 12)
            AddPathLine   (p * i, p * 30)
            StrokePath    (p / 4)
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   ;-- painting, drawing
   Procedure.i Ruler_Spatial (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: body
      ;      color2: scale
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         GradientFullsize_LT2RB(color1, 0.7)
         MovePathCursor(size - p16, p * 5)
         AddPathLine   (p * 5,      size - p * 2)
         StrokePath    (p * 6)

         GradientFullsize_LT2RB(color1, 0.5)
         MovePathCursor(size - p * 4, p * 4)
         AddPathLine   (p * 4,        size - p * 4)
         StrokePath    (p16)

         VectorSourceColor(Color_Darken(color1, 0.65))
         MovePathCursor(size - 4 * p, p * 3)
         AddPathLine   (size,         p * 7)
         AddPathLine   (p * 7,        size)
         AddPathLine   (p * 3,        size - p * 4)
         StrokePath    (p * 0.25)

         VectorSourceColor(color2)
         RotateCoordinates(p2, p2 + p4, 135.0)
         For i = -6 To 28 Step 4
            MovePathCursor(i * p, size - p * 1.3)
            AddPathLine   (i * p, size - p * 3.3)
         Next i
         StrokePath      (p * 0.25)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i RulerTriangle_Spatial (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: body
      ;      color2: scale
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         GradientFullsize_LT2RB(color1, 0.7)
         MovePathCursor(size - p8, size - p16)
         AddPathLine   (size - p8, p * 6)
         AddPathLine   (p * 6,     size - p * 4)
         AddPathLine   (size - p,  size - p8)
         StrokePath    (p * 6)

         GradientFullsize_LT2RB(color1, 0.6)
         MovePathCursor(size - p16, size - p)
         AddPathLine   (size - p16, p * 2)
         AddPathLine   (p16,        size - p16)
         AddPathLine   (size - p,   size - p16)
         StrokePath    (p16)

         VectorSourceColor(Color_Darken(color1, 0.65))
         MovePathCursor   (size - p * 7, size - p * 7)
         AddPathLine      (size - p * 7, p * 13)
         AddPathLine      (p * 13,       size - p * 7)
         AddPathLine      (size - p * 7, size - p * 7)
         StrokePath       (p * 0.25)

         VectorSourceColor(color2)
         For i = 2 To 30 Step 4
            MovePathCursor (i * p, size - p)
            AddPathLine    (i * p, size - p * 3)
         Next i
         StrokePath       (p * 0.25)
         RotateCoordinates(p2,    p2, -90.0)
         For i = 2 To 30 Step 4
            MovePathCursor (i * p, size - p)
            AddPathLine    (i * p, size - p * 3)
         Next i
         StrokePath       (p * 0.25)
         RotateCoordinates(p2,    p2 + p4, 225.0)
         For i = 2 To 42 Step 4
            MovePathCursor (i * p, size - p)
            AddPathLine    (i * p, size - p * 3)
         Next i
         StrokePath       (p * 0.25)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Carton_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i=0, text1.s="", tsize.d=0.5)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: color lid & box
      ;      color2: color tape
      ;      color3: color text (optional)
      ;      text1 : text       (optional)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected.i ret
      Protected   p.d   = size / 32
      Protected   p16.d = size / 16
      Protected   p8.d  = size / 8
      Protected   p4.d  = size / 4
      Protected   p2.d  = size / 2
      Protected.d tW, tH

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         CartonEmpty_Spatial()
         ;/* add a plus ... */
         ;     VectorSourceColor(#CSS_Lime)
         ;     DrawPlus (p2 + p4, p2 + p4, p8, p16)
         ;/* add a minus ... */
         ;     VectorSourceColor(#CSS_Orange)
         ;     DrawMinus (p2 + p4, p2 + p4, p8, p16)

         ;add text ...
         If text1 > ""
            If Not IsFont(0)
               LoadFont(0, "Stencil Cargo Army", 10)
            EndIf
            VectorFont(FontID(0), size * tsize)
            VectorSourceColor(color3)
            tW = VectorTextWidth(text1)
            tH = VectorTextHeight(text1)
            MovePathCursor(p2 - tW / 2, p2 + p4 - tH / 2)
            DrawVectorText(text1)
         EndIf

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i BookKeeping_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: spine folder 1
      ;      color2: spine folder 2
      ;      color3: spine frame
      ;      color4: ring
      ;      color5: hole
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8
      Protected p4.d  = size / 4
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; 1. Folder
         TranslateCoordinates(-p4, 0)
         GradientFullsize_LT2RB(color3, 0.0)
         RingBinder(color1)

         ; 2. Folder
         TranslateCoordinates(p * 14, -p * 0.5)
         RotateCoordinates   (p2, p2, -20.0)
         GradientFullsize_LT2RB(color3, 0.0)
         RingBinder(color2)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Pen_Spatial (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      colorM1: rubber
      ;      colorM2: sleeve
      ;      colorM3: body
      ;      colorM4: wood
      ;      colorM5: tip
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;RotateCoordinates(p2, p2, 45.0)

         DrawPen_Spatial(colorM1, colorM2, colorM3, colorM4, colorM5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Pen_Flat (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      colorM1: rubber
      ;      colorM2: sleeve
      ;      colorM3: body
      ;      colorM4: wood
      ;      colorM5: tip
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;RotateCoordinates(p2, p2, 45.0)

         DrawPen_Flat(colorM1, colorM2, colorM3, colorM4, colorM5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Brush_Spatial (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: body
      ;      color2: sleeve
      ;      color3: hairs
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;RotateCoordinates(p2, p2, 45.0)

         DrawBrush_Spatial(colorM1, colorM2, colorM3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Brush_Flat (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: body
      ;      color2: sleeve
      ;      color3: hairs
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;RotateCoordinates(p2, p2, 45.0)

         DrawBrush_Flat(colorM1, colorM2, colorM3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Pipette_Spatial (file$, img.i, size.i, colorM1.i, colorM2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: rubber
      ;      color2: sleeve
      ;      color3: body
      ;      color4: wood
      ;      color5: tip
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         DrawPipette_Spatial(colorM1, colorM2)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Pipette_Flat (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: rubber
      ;      color2: sleeve
      ;      color3: body
      ;      color4: wood
      ;      color5: tip
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         DrawPipette_Flat(colorM1, colorM2, colorM3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Fill_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: rubber
      ;      color2: sleeve
      ;      color3: body
      ;      color4: wood
      ;      color5: tip
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by davico, mod. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         FlipCoordinatesX(p2)

         ; Drips
         VectorSourceLinearGradient(p * 22, 0, p * 29, 0)
         VectorSourceGradientColor(Color_Darken(color3, 0.4), 0.0)
         VectorSourceGradientColor(Color_Darken(color3, 0.9), 0.8)
         VectorSourceGradientColor(Color_Darken(color3, 0.7), 1.0)
         AddPathCircle(26.5 * p, 26 * p, 2.5 * p,  0,   180)
         FillPath     ()
         AddPathCircle(26.5 * p, 23 * p, 0.99 * p, 180, 0)
         FillPath     ()
         ; -
         MovePathCursor(25.5 * p, 23 * p)
         AddPathLine   (24 *   p, 26 * p)
         AddPathLine   (29 *   p, 26 * p)
         AddPathLine   (27.5 * p, 23 * p)
         ClosePath     ()
         FillPath      ()

         RotateCoordinates(p2, p2, 45.0)
         ;spout
         VectorSourceColor (Color_Darken(color1, 0.6))
         MovePathCursor(20 * p, 11.5 * p)
         AddPathLine   (25 * p, 11.5 * p)
         AddPathLine   (20 * p, 15 * p)
         ClosePath     ()
         StrokePath    (3 * p, #PB_Path_RoundCorner)
         ;jug
         VectorSourceLinearGradient(p * 8, 0,    p * 25, 0)
         VectorSourceGradientColor (Color_Darken(color1, 0.8), 0.0)
         VectorSourceGradientColor (Color_Darken(color1, 1.0), 0.3)
         VectorSourceGradientColor (Color_Darken(color1, 0.6), 1.0)
         DrawRoundBox              (8 * p, 10 * p, 16 * p, 15 * p, 2 * p)
         FillPath                  ()
         ;handle
         AddPathEllipse            (7 * p, 17 * p,  3 * p,  5 * p)
         StrokePath                (p * 1.5)
         ;ring
         VectorSourceLinearGradient(p * 10, 0, p * 22, 0)
         VectorSourceGradientColor (Color_Darken(color2, 0.6), 0.0)
         VectorSourceGradientColor (color2, 0.3)
         VectorSourceGradientColor (Color_Darken(color2, 0.5), 1.0)
         MovePathCursor            (7.5 * p, 10.5 * p)
         AddPathLine               (18 * p, 0,     #PB_Path_Relative)
         StrokePath                (p * 1.5)
         ;color @ spout
         RotateCoordinates(p2, p2, -45.0)
         VectorSourceColor (Color_Darken(color3, 0.6))
         AddPathCircle(25.5 * p, 19.5 * p, 1.5 * p, 330, 60)
         StrokePath   (p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Fill_Flat (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: rubber
      ;      color2: sleeve
      ;      color3: body
      ;      color4: wood
      ;      color5: tip
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by davico, mod. by Oma]
      Protected ret.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         FlipCoordinatesX(p2)

         ;Drips
         VectorSourceColor(color2)
         AddPathCircle(26.5 * p, 26 * p, 2.5 * p,  0,   180)
         FillPath     ()
         AddPathCircle(26.5 * p, 23 * p, 0.99 * p, 180, 0)
         FillPath     ()
         ; -
         MovePathCursor(25.5 * p, 23 * p)
         AddPathLine   (24 *   p, 26 * p)
         AddPathLine   (29 *   p, 26 * p)
         AddPathLine   (27.5 * p, 23 * p)
         ClosePath     ()
         FillPath      ()
         ; -
         AddPathCircle(25.5 * p, 19.5 * p, 1.5 * p, 330, 60)
         StrokePath   (p)

         RotateCoordinates (p2, p2, 45.0)
         ;spout
         VectorSourceColor(color1)
         MovePathCursor(20 * p, 11.5 * p)
         AddPathLine   (25 * p, 11.5 * p)
         AddPathLine   (20 * p, 15 * p)
         ClosePath     ()
         StrokePath    (3 * p, #PB_Path_RoundCorner)
         ;jug
         DrawRoundBox  (8 * p,   10*p, 16 * p, 15 * p, 2 * p)
         FillPath      ()
         MovePathCursor(7.5 * p, 10.5 * p)
         AddPathLine   (17 * p,  0,     #PB_Path_Relative)
         StrokePath    (p * 1.5)
         ;handle
         AddPathEllipse(7 * p, 17 * p, 3 * p, 5 * p)
         StrokePath    (p * 1.5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Spray_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: body
      ;      color2: pusher and darkend conical top
      ;      color3: rings
      ;      color4: graffity
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected   ret.i, i.i
      Protected   p.d = size / 32
      Protected.d x, y, r

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; conical top
         VectorSourceLinearGradient(p * 12, 0, p * 20, 0)
         VectorSourceGradientColor (Color_Darken(color2, 0.7), 0.0)
         VectorSourceGradientColor (Color_Darken(color2, 0.95), 0.3)
         VectorSourceGradientColor (Color_Darken(color2, 0.5), 1.0)
         DrawRoundBox              (12 * p, 6 * p, 8 * p, 8 * p, 3.5 * p)
         FillPath                  ()

         ; body
         VectorSourceLinearGradient(p * 11, 0, p * 21, 0)
         VectorSourceGradientColor (Color_Darken(color1, 0.70), 0.0)
         VectorSourceGradientColor (Color_Darken(color1, 1.0),  0.35)
         VectorSourceGradientColor (Color_Darken(color1, 0.50), 1.0)
         DrawRoundBox              (11 * p, 9 * p, 10 * p, 20 * p, 2.5 * p)
         FillPath                  ()

         ; rings
         VectorSourceLinearGradient(p * 11, 0, p * 21, 0)
         VectorSourceGradientColor (Color_Darken(color3, 0.7), 0.0)
         VectorSourceGradientColor (Color_Darken(color3, 0.9), 0.4)
         VectorSourceGradientColor (Color_Darken(color3, 0.5), 1.0)
         MovePathCursor            (11 * p, 9.5 * p)
         AddPathLine               (10 * p, 0,     #PB_Path_Relative)
         MovePathCursor            (11 * p, 28.5 * p)
         AddPathLine               (10 * p, 0,     #PB_Path_Relative)
         StrokePath                ( p )

         ; label
         MovePathCursor            (12 * p, 15 * p)
         AddPathLine               (8 * p, 0,      #PB_Path_Relative)
         StrokePath                (p * 3.0)

         ; pusher
         VectorSourceLinearGradient(p * 14.5, 0, p * 17.5, 0)
         VectorSourceGradientColor (Color_Darken(color1, 0.7), 0.0)
         VectorSourceGradientColor (Color_Darken(color1, 1.0), 0.4)
         VectorSourceGradientColor (Color_Darken(color1, 0.5), 1.0)
         AddPathBox                (14.5 * p, 2 * p, 3 * p, 3 * p)
         AddPathBox                (14   * p, 5 * p, 4 * p,     p)
         FillPath()

         ; graffity
         VectorSourceColor(color4)
         MovePathCursor(13 * p, 4.0 * p)
         AddPathCircle(6.5 * p, 4.5 * p, 4.0 * p, 90, 270, #PB_Path_Connected)
         ClosePath()
         ClipPath()
         For i = 1 To 200
            x = Random(26, 4) / 2
            y = Random(17, 1) / 2
            r = Random(3, 2) / 9
            AddPathCircle(x * p, y * p, r * p)
            FillPath()
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Spray_Flat (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: body
      ;      color2: pusher and darkend conical top
      ;      color3: rings
      ;      color4: graffity
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected   ret.i, i.i
      Protected   p.d = size / 32
      Protected.d x, y, r

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; conical top
         VectorSourceColor(Color_Darken(color2, 0.9))
         DrawRoundBox              (12 * p, 6 * p, 8 * p, 8 * p, 3.5 * p)
         FillPath                  ()

         ; body
         VectorSourceColor(color1)
         DrawRoundBox              (11 * p, 9 * p, 10 * p, 20 * p, 2.0 * p)
         FillPath                  ()

         ; rings
         VectorSourceColor(color2)
         MovePathCursor            (11 * p, 9.5 * p)
         AddPathLine               (10 * p, 0,     #PB_Path_Relative)
         MovePathCursor            (11 * p, 28.5 * p)
         AddPathLine               (10 * p, 0,     #PB_Path_Relative)
         StrokePath                ( p )

         ; label
         MovePathCursor            (12 * p, 15 * p)
         AddPathLine               (8 * p, 0,      #PB_Path_Relative)
         StrokePath                (p * 3.0)

         ; pusher
         VectorSourceColor(color3)
         AddPathBox                (14.5 * p, 2 * p, 3 * p, 3 * p)
         FillPath()
         VectorSourceColor(Color_Darken(color3, 0.8))
         AddPathBox                (14   * p, 5 * p, 4 * p, p)
         FillPath()

         ; graffity
         VectorSourceColor(color4)
         MovePathCursor(13 * p, 4.0 * p)
         AddPathCircle(6.5 * p, 4.5 * p, 4.0 * p, 90, 270, #PB_Path_Connected)
         ClosePath()
         ClipPath()
         For i = 1 To 200
            x = Random(26, 4) / 2
            y = Random(17, 1) / 2
            r = Random(3, 2) / 9
            AddPathCircle(x * p, y * p, r * p)
            FillPath()
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Eraser_Spatial (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: cover
      ;      color2: rubber
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;RotateCoordinates(p2, p2, 45.0)
         ;cover lines vert ...
         VectorSourceColor(Color_Darken(color1, 0.8))
         MovePathCursor(p * 6.25,  p * 17)
         AddPathLine   (p * 0.5,   p * 5,  #PB_Path_Relative)
         MovePathCursor(p * 25.75, p * 17)
         AddPathLine   (p * -0.5,  p * 5,  #PB_Path_Relative)
         StrokePath    (p, #PB_Path_RoundEnd)

         ;eraser side...
         VectorSourceLinearGradient(p * 6, 0, p * 26, 0)
         VectorSourceGradientColor(Color_Darken(color2, 0.8), 0.0)
         VectorSourceGradientColor(color2, 0.2)
         VectorSourceGradientColor(Color_Darken(color2, 0.65), 1.0)
         MovePathCursor(p * 7.5, p * 18)
         AddPathLine   (-p,      p * 7, #PB_Path_Relative)
         AddPathLine   (p * 19,  0,     #PB_Path_Relative)
         AddPathLine   (-p,     -p * 7, #PB_Path_Relative)
         ClosePath()
         StrokePath(p16, #PB_Path_Preserve | #PB_Path_RoundCorner)
         FillPath()
         ;eraser top...
         VectorSourceLinearGradient(p * 6, 0, p * 26, 0)
         VectorSourceGradientColor(Color_Darken(color2, 0.7), 0.0)
         VectorSourceGradientColor(Color_Darken(color2, 0.9), 0.2)
         VectorSourceGradientColor(Color_Darken(color2, 0.55), 1.0)
         MovePathCursor(p * 6.5,  p * 26)
         AddPathLine   (p * 1.2,  p * 3,  #PB_Path_Relative)
         AddPathLine   (p * 16.6, 0,      #PB_Path_Relative)
         AddPathLine   (p * 1.2, -p * 3,  #PB_Path_Relative)
         ClosePath()
         StrokePath(p16, #PB_Path_Preserve | #PB_Path_RoundCorner)
         FillPath()
         ;rubber edge
         VectorSourceLinearGradient(p * 6, 0, p * 26, 0)
         VectorSourceGradientColor(Color_Darken(color2, 0.9), 0.0)
         VectorSourceGradientColor(color2, 0.2)
         VectorSourceGradientColor(Color_Darken(color2, 0.8), 1.0)
         MovePathCursor(p * 6.5, p * 25.5)
         AddPathLine   (p * 19,  0,  #PB_Path_Relative)
         StrokePath    (p,           #PB_Path_RoundEnd)

         ;cover...
         VectorSourceLinearGradient(p * 6, 0, p * 27, p16)
         VectorSourceGradientColor(Color_Darken(color1, 0.9), 0.0)
         VectorSourceGradientColor(color1, 0.3)
         VectorSourceGradientColor(Color_Darken(color1, 0.7), 1.0)
         MovePathCursor(p * 8.5, p * 2)
         AddPathLine   (-p * 2,  p * 15,  #PB_Path_Relative)
         AddPathLine   (p * 19,  0 ,      #PB_Path_Relative)
         AddPathLine   (-p * 2, -p * 15,  #PB_Path_Relative)
         ClosePath()
         StrokePath(p * 1.5, #PB_Path_Preserve | #PB_Path_RoundCorner)
         FillPath()
         ;shadow
         VectorSourceColor(Color_Darken(color1, 0.7))
         MovePathCursor(p * 6,  p * 17)
         AddPathLine   (p * 19, 0 , #PB_Path_Relative)
         StrokePath(p , #PB_Path_RoundCorner)
         VectorSourceLinearGradient(p * 6, 0, p * 24, p16)
         VectorSourceGradientColor(Color_Darken(color1, 0.7), 0.0)
         VectorSourceGradientColor(color1, 0.3)
         VectorSourceGradientColor(Color_Darken(color1, 0.6), 1.0)
         MovePathCursor(p * 10,  p * 6)
         AddPathLine   (p * 12,  0 , #PB_Path_Relative)
         MovePathCursor(p * 9.5, p * 9)
         AddPathLine   (p * 13,  0 , #PB_Path_Relative)
         MovePathCursor(p * 9.0, p * 12)
         AddPathLine   (p * 14,  0 , #PB_Path_Relative)
         StrokePath(p, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Eraser_Flat (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: cover
      ;      color2: rubber
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;RotateCoordinates(p2, p2, 45.0)
         ;cover lines vert ...
         VectorSourceColor(Color_Darken(color1, 0.8))
         MovePathCursor(p * 6.25,  p * 17)
         AddPathLine   (p * 0.5,   p * 5,  #PB_Path_Relative)
         MovePathCursor(p * 25.75, p * 17)
         AddPathLine   (p * -0.5,  p * 5,  #PB_Path_Relative)
         StrokePath    (p, #PB_Path_RoundEnd)

         ;eraser side...
         VectorSourceColor(color2)
         MovePathCursor(p * 7.5, p * 18)
         AddPathLine   (- p,     p * 7,  #PB_Path_Relative)
         AddPathLine   (p * 19,  0 ,     #PB_Path_Relative)
         AddPathLine   (- p,    -p * 7,  #PB_Path_Relative)
         ClosePath()
         StrokePath(p16, #PB_Path_Preserve | #PB_Path_RoundCorner)
         FillPath()
         ;eraser top...
         VectorSourceColor(Color_Darken(color2, 0.8))
         MovePathCursor(p * 6.5,  p * 26)
         AddPathLine   (p * 1.2,  p * 3,  #PB_Path_Relative)
         AddPathLine   (p * 16.6, 0,      #PB_Path_Relative)
         AddPathLine   (p * 1.2, -p * 3,  #PB_Path_Relative)
         ClosePath()
         StrokePath(p16, #PB_Path_Preserve | #PB_Path_RoundCorner)
         FillPath()
         ;rubber edge
         MovePathCursor(p * 6.5, p * 25.5)
         AddPathLine   (p * 19,  0,  #PB_Path_Relative)
         StrokePath    (p,           #PB_Path_RoundEnd)

         ;cover...
         VectorSourceColor(color1)
         MovePathCursor(p * 8.5, p * 2)
         AddPathLine   (-p * 2,  p * 15,  #PB_Path_Relative)
         AddPathLine   (p * 19,  0 ,      #PB_Path_Relative)
         AddPathLine   (-p * 2, -p * 15,  #PB_Path_Relative)
         ClosePath()
         StrokePath(p * 1.5, #PB_Path_Preserve | #PB_Path_RoundCorner)
         FillPath()
         ;shadow
         VectorSourceColor(Color_Darken(color1, 0.7))
         MovePathCursor(p * 6,  p * 17)
         AddPathLine   (p * 19, 0 , #PB_Path_Relative)
         StrokePath(p , #PB_Path_RoundCorner)
         VectorSourceColor(color1)
         MovePathCursor(p * 10,  p * 6)
         AddPathLine   (p * 12,  0 , #PB_Path_Relative)
         MovePathCursor(p * 9.5, p * 9)
         AddPathLine   (p * 13,  0 , #PB_Path_Relative)
         MovePathCursor(p * 9.0, p * 12)
         AddPathLine   (p * 14,  0,  #PB_Path_Relative)
         StrokePath(p, #PB_Path_RoundCorner)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ColorPalette_Spatial (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i, colorM6.i, colorM7.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      colorM1: blob 1
      ;      colorM2: blob 2
      ;      colorMn: blob n
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         RotateCoordinates(p * 9.43, p * 26.83, -25)
         ColorBoard_Spatial(colorM1, colorM2, colorM3, colorM4, colorM5, colorM6, colorM7)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ColorPalette_Flat (file$, img.i, size.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i, colorM6.i, colorM7.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      colorM1: blob 1
      ;      colorM2: blob 2
      ;      colorMn: blob n
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         RotateCoordinates(p * 9.43, p * 26.83, -25)
         ColorBoard_Flat(colorM1, colorM2, colorM3, colorM4, colorM5, colorM6, colorM7)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Paint_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i, color7.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: easel vertically
      ;      color2: easel horizontally
      ;      color3: canvas
      ;      colorn: painting figure n
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;easel
         SkewCoordinates(-15, 0)
         VectorSourceLinearGradient(0, 0, 0, size)
         VectorSourceGradientColor (Color_Darken(color1, 0.8), 0.0)
         VectorSourceGradientColor (Color_Darken(color1, 0.4), 1.0)
         MovePathCursor(p * 14, 0)
         AddPathLine   (0, size, #PB_Path_Relative)
         StrokePath    (p16)

         SkewCoordinates(30, 0)
         MovePathCursor(p * 18, 0)
         AddPathLine   (0, size, #PB_Path_Relative)
         StrokePath    (p16)

         ResetCoordinates()
         MovePathCursor(p * 16, 0)
         AddPathLine   (0, p * 28, #PB_Path_Relative)
         StrokePath    (p16)

         VectorSourceColor(color2);
         MovePathCursor(p16, p * 22.5)
         AddPathLine   (size - p8, 0, #PB_Path_Relative)
         StrokePath    (p)
         ;canvas
         VectorSourceLinearGradient(p * 7, p, p * 30, p * 24)
         VectorSourceGradientColor (color3, 0.0)
         VectorSourceGradientColor (Color_Darken(color3, 0.85), 1.0)
         MovePathCursor(p * 4,  p16)
         AddPathLine   (-p * 3, p * 20, #PB_Path_Relative)
         AddPathLine   (p * 30, 0, #PB_Path_Relative)
         AddPathLine   (-p * 3, -p * 20, #PB_Path_Relative)
         ClosePath     ()
         FillPath      (#PB_Path_Preserve)
         VectorSourceLinearGradient(p, p16, p * 30, p * 24)
         VectorSourceGradientColor (Color_Darken(color3, 0.7), 0.0)
         VectorSourceGradientColor (Color_Darken(color3, 0.2), 1.0)
         StrokePath    (p  * 0.5)
         ;painting
         SkewCoordinates(-30, 0)
         VectorSourceColor(color4)
         AddPathCircle  (p * 28, p * 13, p * 4)
         StrokePath     (p * 1.5)

         SkewCoordinates(30, 0)
         VectorSourceColor(color5)
         MovePathCursor (p * 7,  p * 16)
         AddPathLine    (p * 18, -p * 3, #PB_Path_Relative)
         StrokePath     (p * 1.5, #PB_Path_RoundEnd)

         VectorSourceColor(color6)
         MovePathCursor(p * 13, p * 5)
         AddPathLine   (-p * 3, p * 13, #PB_Path_Relative)
         StrokePath    (p, #PB_Path_RoundEnd)

         VectorSourceColor(color7)
         MovePathCursor(p * 8,  p * 6)
         AddPathLine   (p * 13, p * 4, #PB_Path_Relative)
         StrokePath    (p16, #PB_Path_RoundEnd)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Paint_Flat (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i, color7.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: easel vertically
      ;      color2: easel horizontally
      ;      color3: canvas
      ;      colorn: painting figure n
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;easel
         SkewCoordinates(-15, 0)
         VectorSourceColor(color1)
         MovePathCursor(p * 14, 0)
         AddPathLine   (0, size, #PB_Path_Relative)
         StrokePath    (p16)

         SkewCoordinates(30, 0)
         MovePathCursor(p * 18, 0)
         AddPathLine   (0, size, #PB_Path_Relative)
         StrokePath    (p16)

         ResetCoordinates()
         MovePathCursor(p * 16, 0)
         AddPathLine   (0, p * 28, #PB_Path_Relative)
         StrokePath    (p16)

         VectorSourceColor(color2);
         MovePathCursor(p16, p * 22.5)
         AddPathLine   (size - p8, 0, #PB_Path_Relative)
         StrokePath    (p)
         ;canvas
         VectorSourceColor(color3)
         MovePathCursor(p * 4,  p16)
         AddPathLine   (-p * 3, p * 20, #PB_Path_Relative)
         AddPathLine   (p * 30, 0, #PB_Path_Relative)
         AddPathLine   (-p * 3, -p * 20, #PB_Path_Relative)
         ClosePath     ()
         FillPath(#PB_Path_Preserve)
         VectorSourceColor(color_darken(color3, 0.7))
         StrokePath    (p * 0.5)
         ;painting
         SkewCoordinates(-30, 0)
         VectorSourceColor(color4)
         AddPathCircle  (p * 28, p * 13, p * 4)
         StrokePath     (p * 1.5)

         SkewCoordinates(30, 0)
         VectorSourceColor(color5)
         MovePathCursor (p * 7,  p * 16)
         AddPathLine    (p * 18, -p * 3, #PB_Path_Relative)
         StrokePath     (p * 1.5, #PB_Path_RoundEnd)

         VectorSourceColor(color6)
         MovePathCursor (p * 13, p * 5)
         AddPathLine    (-p * 3, p * 13, #PB_Path_Relative)
         StrokePath     (p, #PB_Path_RoundEnd)

         VectorSourceColor(color7)
         MovePathCursor (p * 8,  p * 6)
         AddPathLine    (p * 13, p * 4, #PB_Path_Relative)
         StrokePath     (p16, #PB_Path_RoundEnd)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   ;-- vector: drawing
   Procedure.i DrawVText (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: char & cursor
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 6.5 - offs,  p * 27 - offs)
            AddPathLine   (p * 7,          -p * 19, #PB_Path_Relative)
            AddPathLine   (p * 7,           p * 19, #PB_Path_Relative)
            StrokePath    (p * 3, #PB_Path_RoundEnd | #PB_Path_RoundCorner)
            MovePathCursor(p * 9 - offs,    p * 21 - offs)
            AddPathLine   (p * 9,           0,      #PB_Path_Relative)
            StrokePath    (p * 3, #PB_Path_RoundEnd | #PB_Path_RoundCorner)

            AddPathCircle (p * 24 - offs, p * 10 - offs, p * 3, 270.0, 0.0)
            AddPathLine   (0,             p * 17, #PB_Path_Relative)
            AddPathCircle (p * 24 - offs, p * 26 - offs, p * 3, 0.0,   90.0)
            AddPathCircle (p * 30 - offs, p * 10 - offs, p * 3, 180.0, 270.0)
            AddPathCircle (p * 30 - offs, p * 26 - offs, p * 3, 90.0,  180.0)
            StrokePath    (p * 0.5)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DrawVLine (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p *  8 - offs, p * 20 - offs, p16, p16)
            AddPathBox    (p * 26 - offs, p * 15 - offs, p16, p16)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            MovePathCursor(p *  9 - offs,  p * 21 - offs)
            AddPathLine   (p * 18,        -p * 5, #PB_Path_Relative)
            StrokePath    (p16)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DrawVBox (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p *  8 - offs, p * 10 - offs, p16,    p16)
            AddPathBox    (p * 26 - offs, p * 25 - offs, p16,    p16)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            AddPathBox    (p *  9 - offs, p * 11 - offs, p * 18, p * 15)
            StrokePath    (p16)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DrawVRoundedBox (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p *  8 - offs, p * 10 - offs, p16,    p16)
            AddPathBox    (p * 26 - offs, p * 25 - offs, p16,    p16)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            DrawRoundBox  (p *  9 - offs, p * 11 - offs, p * 18, p * 15, p * 5)
            StrokePath    (p16)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DrawVPolygonBox (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p *  6 - offs, p * 18 - offs, p16, p16)
            AddPathBox    (p * 14 - offs, p * 28 - offs, p16, p16)
            AddPathBox    (p * 24 - offs, p * 27 - offs, p16, p16)
            AddPathBox    (p * 28 - offs, p * 13 - offs, p16, p16)
            AddPathBox    (p * 16 - offs, p *  8 - offs, p16, p16)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            MovePathCursor(p *  7 - offs, p * 19 - offs)
            AddPathLine   (p *  8,        p * 10, #PB_Path_Relative)
            AddPathLine   (p * 10,       -p *  1, #PB_Path_Relative)
            AddPathLine   (p *  4,       -p * 14, #PB_Path_Relative)
            AddPathLine   (-p* 12,       -p *  5, #PB_Path_Relative)
            ClosePath()
            StrokePath    (p16, #PB_Path_DiagonalCorner)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DrawVCircle (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p * 17 - offs, p * 17 - offs, p16, p16)
            AddPathBox    (p * 27 - offs, p * 17 - offs, p16, p16)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            AddPathCircle (p * 18 - offs, p * 18 - offs, p * 10)
            StrokePath    (p16)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DrawVCircleSegment (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p * 17 - offs, p * 17 - offs, p16, p16)
            AddPathBox    (p * 27 - offs, p * 17 - offs, p16, p16)
            AddPathBox   ((p * 17 - offs) - (p * 10) / Sqr(2), p * 17 - offs - (p * 10) / Sqr(2), p16, p16)
            AddPathBox   ((p * 17 - offs) + (p * 10) / Sqr(2), p * 17 - offs - (p * 10) / Sqr(2), p16, p16)
            StrokePath   (p16)
            VectorSourceColor (colorTemp1)
            AddPathCircle (p * 18 - offs, p * 18 - offs, p * 10, 315, 225)
            StrokePath    (p16)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DrawVEllipse (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p * 17 - offs, p * 17 - offs, p16, p16)
            AddPathBox    (p * 27 - offs, p * 17 - offs, p16, p16)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            AddPathEllipse(p * 18 - offs, p * 18 - offs, p * 10, p * 7)
            StrokePath    (p16)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DrawVEllipseSegment (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0,      #PB_Path_Relative)
            AddPathLine   (0,     -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox     (p * 17 - offs, p * 17 - offs, p16, p16)
            AddPathBox     (p * 27 - offs, p * 17 - offs, p16, p16)
            AddPathBox    ((p * 17 - offs) - (p * 10) / Sqr(2), p * 17 - offs - (p * 10) / 2, p16, p16)  ; fix it on PB5.43: Win = Mac/Lin
            AddPathBox    ((p * 17 - offs) + (p * 10) / Sqr(2), p * 17 - offs - (p * 10) / 2, p16, p16)  ; fix it on PB5.43: Win = Mac/Lin
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            AddPathEllipse (p * 18 - offs, p * 18 - offs, p * 10, p * 7, 315, 225)   ; Has to be recalced after 5.43 update.
            StrokePath     (p16)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DrawVCurve (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p *  8 - offs, p * 16 - offs, p16, p16)
            AddPathBox    (p * 14 - offs, p *  5 - offs, p16, p16)
            AddPathBox    (p * 20 - offs, p * 27 - offs, p16, p16)
            AddPathBox    (p * 26 - offs, p * 16 - offs, p16, p16)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            MovePathCursor(p *  9 - offs, p * 17 - offs)
            AddPathCurve  (p * 15 - offs, p *  5 - offs, p * 21 - offs, p * 29 - offs, p * 27 - offs, p * 17 - offs)
            StrokePath    (p16)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DrawVArc (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p4.d  = size / 4

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,     -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p * 11 - offs, p *  9 - offs, p16, p16)
            AddPathBox    (p * 11 - offs, p * 23 - offs, p16, p16)
            AddPathBox    (p * 25 - offs, p * 23 - offs, p16, p16)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 12 - offs, p * 10 - offs)
            AddPathArc    (p * 12 - offs, p * 24 - offs, p * 26 - offs, p * 24 - offs, p4)
            AddPathLine   (p * 26 - offs, p * 24 - offs)
            StrokePath    (p16)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i DrawVLinePath (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p *   8 - offs, p * 19 - offs, p16, p16)
            AddPathBox    (p *  13 - offs, p * 11 - offs, p16, p16)
            AddPathBox    (p *  18 - offs, p * 26 - offs, p16, p16)
            AddPathBox    (p *  28 - offs, p * 28 - offs, p16, p16)
            AddPathBox    (p *  23 - offs, p * 14 - offs, p16, p16)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 9 - offs,  p * 20 - offs)
            AddPathLine   (p * 5,        -p * 8,  #PB_Path_Relative)
            AddPathLine   (p * 5,         p * 15, #PB_Path_Relative)
            AddPathLine   (p * 10,        p * 2,  #PB_Path_Relative)
            AddPathLine   (-p * 5,       -p * 14, #PB_Path_Relative)
            StrokePath    (p16, #PB_Path_DiagonalCorner)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   ;-- vector-draw: settings
   Procedure.i SetVSelectionRange (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p *  7 - offs, p *  7 - offs, p8, p8)
            AddPathBox    (p * 25 - offs, p *  7 - offs, p8, p8)
            AddPathBox    (p *  7 - offs, p * 25 - offs, p8, p8)
            AddPathBox    (p * 25 - offs, p * 25 - offs, p8, p8)
            StrokePath    (p16)

            VectorSourceColor (Color_Darken(colorTemp2, 0.8))
            AddPathBox        (p * 9 - offs,  p * 9 - offs,  p * 18, p * 18)
            FillPath(#PB_Path_Preserve)
            VectorSourceColor (colorTemp1)
            DashPath          (p * 1.5, p16)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVLineStyle (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 9 - offs, p * 12 - offs)
            AddPathLine   (p * 20,        0, #PB_Path_Relative)
            DotPath       (p16, p8)
            MovePathCursor(p * 9 - offs, p * 19 - offs)
            AddPathLine   (p * 20,        0, #PB_Path_Relative)
            DashPath      (p16, p8)
            MovePathCursor(p * 9 - offs, p * 26 - offs)
            AddPathLine   (p * 20,        0, #PB_Path_Relative)
            DashPath      (p16, p * 6)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVLineWidth (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 9 - offs, p * 10 - offs)
            AddPathLine   (p * 20,       0, #PB_Path_Relative)
            StrokePath    (p)
            MovePathCursor(p * 9 - offs, p * 17 - offs)
            AddPathLine   (p * 20,       0, #PB_Path_Relative)
            StrokePath    (p * 3)
            MovePathCursor(p * 9 - offs, p * 26 - offs)
            AddPathLine   (p * 20,       0, #PB_Path_Relative)
            StrokePath    (p * 6)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVLineCap (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 8 - offs, p * 10 - offs)
            AddPathLine   (p * 20,       0, #PB_Path_Relative)
            StrokePath    (p * 6, #PB_Path_Preserve)
            VectorSourceColor (#CSS_White)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 8 - offs, p * 18 - offs)
            AddPathLine   (p * 20,       0, #PB_Path_Relative)
            StrokePath    (p * 6, #PB_Path_SquareEnd | #PB_Path_Preserve)
            VectorSourceColor (#CSS_White)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 8 - offs, p * 26 - offs)
            AddPathLine   (p * 20,       0, #PB_Path_Relative)
            StrokePath    (p * 6, #PB_Path_RoundEnd | #PB_Path_Preserve)
            VectorSourceColor (#CSS_White)
            StrokePath    (p16)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVLineJoin (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points (unused)
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d  = size / 32
      Protected p8.d = size / 8

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 14 - offs, p * 13 - offs)
            AddPathLine   (p * 5,       -p * 5, #PB_Path_Relative)
            AddPathLine   (p * 5,        p * 5, #PB_Path_Relative)
            StrokePath    (p8)
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 14 - offs, p * 21 - offs)
            AddPathLine   (p * 5,       -p * 5, #PB_Path_Relative)
            AddPathLine   (p * 5,        p * 5, #PB_Path_Relative)
            StrokePath    (p8, #PB_Path_DiagonalCorner)
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 14 - offs, p * 29 - offs)
            AddPathLine   (p * 5,       -p * 5, #PB_Path_Relative)
            AddPathLine   (p * 5,        p * 5, #PB_Path_Relative)
            StrokePath    (p8, #PB_Path_RoundCorner)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVColorSelect (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i=0, color5.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: colorbar 1
      ;      color2: colorbar 2
      ;      color3: colorbar 3
      ;      color4: shadow optional
      ;      color5: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, y.d, colorTemp1.i, colorTemp2.i, colorTemp3.i, colorTemp4.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color5
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color5, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color5, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color5, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color5, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color4
         colorTemp2 = color4
         colorTemp3 = color4
         colorTemp4 = color4
         If Not color4 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            AddPathBox (p * 6 - offs,  p * 8 - offs, p * 4.5, p * 21)
            FillPath   ()
            VectorSourceColor (colorTemp2)
            AddPathBox (p * 12 - offs, p * 8 - offs, p * 4.5, p * 21)
            FillPath   ()
            VectorSourceColor (colorTemp3)
            AddPathBox (p * 18 - offs, p * 8 - offs, p * 4.5, p * 21)
            FillPath   ()

            VectorSourceColor (colorTemp4)
            y = 8.0
            Repeat
               AddPathBox (p * 24    - offs, p * Y          - offs, p * 2.25, p * 2.25)
               AddPathBox (p * 26.25 - offs, p * (Y + 2.25) - offs, p * 2.25, p * 2.25)
               y + 4.5
            Until y > 24
            AddPathBox (p * 24    - offs, p * Y          - offs, p * 2.25, p * 2.25)
            AddPathBox (p * 26.25 - offs, p * (Y + 2.25) - offs, p * 2.25, p)
            FillPath   ()
            colorTemp1 = color1
            colorTemp2 = color2
            colorTemp3 = color3
            colorTemp4 = #CSS_Gray
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVColorBoardSelect (file$, img.i, size.i, color1.i, color2.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i, colorM6.i, colorM7.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: shadow
      ;      color2: canvas
      ;      colorM1: colors ColorBoard
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color2
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color2, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color2, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color2, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color2, 0.8), 1.0)
            StrokePath(p)
         EndIf
         ;shadow
         RotateCoordinates(p * 9.43, p * 26.83, -25)
         ScaleCoordinates(0.8, 0.8)
         TranslateCoordinates(p * 7, p * 7)
         ColorBoard_Spatial(color1, color1, color1, color1, color1, color1, color1)
         ;colored & moved twice
         ResetCoordinates(); neccessary!
         RotateCoordinates(p * 9.43, p * 26.83, -25)
         ScaleCoordinates(0.8, 0.8)
         TranslateCoordinates(p * 4, p * 4)
         ColorBoard_Spatial(colorM1, colorM2, colorM3, colorM4, colorM5, colorM6, colorM7)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVFlipX (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: shadow
      ;      color3: points
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor(colorTemp1)
            MovePathCursor(p * 18 - offs, p *  6 - offs)
            AddPathLine   (0,             p * 25, #PB_Path_Relative)
            StrokePath    (p * 0.5)

            MovePathCursor(p * 14 - offs, p * 25 - offs)
            AddPathLine   (0,            -p * 12, #PB_Path_Relative)
            AddPathLine   (-p * 6,        p *  6,  #PB_Path_Relative)
            ClosePath     ()
            DotPath       (p, p16)

            MovePathCursor(p * 22 - offs, p * 25 - offs)
            AddPathLine   (0,            -p * 12, #PB_Path_Relative)
            AddPathLine   (p *  6,        p *  6,  #PB_Path_Relative)
            ClosePath     ()
            StrokePath    (p16)

            MovePathCursor(p * 26 - offs, p *  5 - offs)
            AddPathLine   (0,             p *  8, #PB_Path_Relative)
            AddPathLine   (p *  4,       -p *  4, #PB_Path_Relative)
            ClosePath     ()
            FillPath      ()

            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVFlipY (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: shadow
      ;      color3: points
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf
         TranslateCoordinates(p * 6, 0)
         RotateCoordinates(p2, p2, 90.0)

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 18 - offs, p *  6 - offs)
            AddPathLine   (0,             p * 25, #PB_Path_Relative)
            StrokePath    (p * 0.5)

            MovePathCursor(p * 14 - offs, p * 25 - offs)
            AddPathLine   (0,            -p * 12,  #PB_Path_Relative)
            AddPathLine   (-p * 6,        p *  6,  #PB_Path_Relative)
            ClosePath     ()
            DotPath       (p, p16)

            MovePathCursor(p * 22 - offs, p * 25 - offs)
            AddPathLine   (0,            -p * 12, #PB_Path_Relative)
            AddPathLine   (p * 6,         p *  6, #PB_Path_Relative)
            ClosePath     ()
            StrokePath    (p16)

            MovePathCursor(p * 26 - offs, p * 25 - offs)
            AddPathLine   (0,             p *  8, #PB_Path_Relative)
            AddPathLine   (p * 4,        -p *  4, #PB_Path_Relative)
            ClosePath     ()
            FillPath      ()
            colorTemp1 = color1
            colorTemp2 = color2
            TranslateCoordinates(0, p * 6)
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVRotate (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: shadow
      ;      color3: points
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p4.d  = size / 4

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            AddPathBox    (p * 14.0 - offs, p * 14 - offs, p4, p4)
            StrokePath    (p16)
            AddPathCircle (p * 18.0 - offs, p * 18 - offs, p * 11, 337.5, 315)
            StrokePath    (p)
            MovePathCursor(p * 27.5 - offs, p *  6 - offs)
            AddPathLine   (0,               p * 6, #PB_Path_Relative)
            AddPathLine   (-p * 6,          0,     #PB_Path_Relative)
            ClosePath     ()
            FillPath()
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVMove (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: shadow
      ;      color3: points
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            AddPathBox    (p *  8 - offs, p *  8 - offs, p2, p2)
            DotPath       (p, p16)
            AddPathBox    (p * 13 - offs, p * 13 - offs, p2, p2)
            StrokePath    (p16)

            MovePathCursor(p * 22 - offs, p * 16 - offs)
            AddPathLine   (0,             p *  6, #PB_Path_Relative)
            AddPathLine   (-p * 6,        0,      #PB_Path_Relative)
            ClosePath     ()
            FillPath()
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVCopy (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: shadow
      ;      color3: points
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            AddPathBox    (p *  8 - offs, p *  8 - offs, p2, p2)
            StrokePath    (p)
            AddPathBox    (p * 13 - offs, p * 13 - offs, p2, p2)
            StrokePath    (p16)

            MovePathCursor(p * 22 - offs, p * 16 - offs)
            AddPathLine   (0,             p *  6, #PB_Path_Relative)
            AddPathLine   (-p * 6,        0,      #PB_Path_Relative)
            ClosePath     ()
            FillPath()
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVScale (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: shadow
      ;      color3: points
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p4.d  = size / 4

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            AddPathBox    (p * 14 - offs, p * 14 - offs, p4,     p4)
            DotPath       (p, p16)
            AddPathBox    (p *  8 - offs, p *  8 - offs, p * 20, p * 20)
            StrokePath    (p16)

            MovePathCursor(p * 26 - offs, p * 20 - offs)
            AddPathLine   (0,             p *  6, #PB_Path_Relative)
            AddPathLine   (-p * 6,        0,      #PB_Path_Relative)
            ClosePath     ()
            FillPath()
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVTrimSegment (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: shadow
      ;      color3: points
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 19 - offs, p * 6 - offs)
            AddPathLine   (-p * 2,        p * 23, #PB_Path_Relative)
            StrokePath    (p * 0.5)
            MovePathCursor(p *  6 - offs, p * 17 - offs)
            AddPathLine   (p * 10,        0, #PB_Path_Relative)
            StrokePath    (p16)
            MovePathCursor(p * 21 - offs, p * 17 - offs)
            AddPathLine   (p *  9,        0, #PB_Path_Relative)
            DotPath       (p16, p8)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVExtendSegment (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: shadow
      ;      color3: points
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p8.d  = size / 8

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            MovePathCursor(p * 29 - offs, p *  6 - offs)
            AddPathLine   (-p * 2,        p * 23, #PB_Path_Relative)
            StrokePath    (p * 0.5)
            MovePathCursor(p *  6 - offs, p * 17 - offs)
            AddPathLine   (p *  9,        0, #PB_Path_Relative)
            StrokePath    (p16)
            MovePathCursor(p * 18 - offs, p * 17 - offs)
            AddPathLine   (p *  8,          0, #PB_Path_Relative)
            DotPath       (p16, p8)
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVCatchGrid (file$, img.i, size.i, color1.i, color2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: shadow
      ;      color3: points
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, X.i, Y.i, colorTemp1.i, colorTemp2.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            For Y = 9 To 27 Step 6
               For X = 9 To  27 Step 6
                  AddPathBox(p * X - offs, p * Y - offs, p, p)
                  StrokePath(p * 0.5)
               Next X
            Next Y

            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVLinearGradient (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: body (no shadow)
      ;      color2: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color2
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color2, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color2, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30,  #PB_Path_Relative)
            AddPathLine   (p * 30, 0,       #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color2, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color2, 0.8), 1.0)
            StrokePath(p)
         EndIf

         VectorSourceLinearGradient(p * 4, p * 4, size - p * 4, size - p * 4)
         VectorSourceGradientColor (Color_Darken(color1, 1), 0.0)
         VectorSourceGradientColor (Color_Darken(color1, 0.2), 1.0)
         AddPathBox(p * 4, p * 4, size - p * 9, size - p * 9)
         FillPath(#PB_Path_Preserve)
         VectorSourceColor(Color_Darken(color1, 0.0))
         StrokePath(0.25)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVCircularGradient (file$, img.i, size.i, color1.i, color2.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: body (no shadow)
      ;      color2: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color2
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color2, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color2, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color2, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color2, 0.8), 1.0)
            StrokePath(p)
         EndIf

         VectorSourceCircularGradient(p * 16, p * 16, p * 13)
         VectorSourceGradientColor (Color_Darken(color1, 1), 0.0)
         VectorSourceGradientColor (Color_Darken(color1, 0.3), 1.0)
         AddPathCircle(p * 16, p * 16, p * 13)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVChangeCoord (file$, img.i, size.i, color1.i, color2.i, colorM1.i, colorM2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            AddPathBox    (p *  16 - offs, p * 11 - offs, p * 6,  p * 6)
            StrokePath    (p16)
            VectorSourceColor (colorTemp1)
            MovePathCursor(p *  7 - offs,  p * 14 - offs)
            AddPathLine   (p * 24,         0, #PB_Path_Relative)
            StrokePath    (p16)
            If i = 3
               ;pointer
               TranslateCoordinates(p * 16, p * 11)
               MousePointer(colorM1, colorM2)
            EndIf
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVDelete (file$, img.i, size.i, color1.i, color2.i, colorM1.i, colorM2.i, color3.i=0, color4.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color4
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color4, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color4, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color3
         colorTemp2 = color3
         If Not color3 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp2)
            MovePathCursor(p * 15 - offs, p * 10 - offs)
            AddPathLine   (p *  8,        p *  8,   #PB_Path_Relative)
            MovePathCursor(p * 23 - offs, p * 10 - offs)
            AddPathLine   (-p * 8,        p *  8,  #PB_Path_Relative)
            StrokePath    (p16)

            VectorSourceColor (colorTemp1)
            MovePathCursor(p *  7 - offs,  p * 14 - offs)
            AddPathLine   (p * 24,         0, #PB_Path_Relative)
            StrokePath    (p16)
            If i = 3
               ;pointer
               TranslateCoordinates(p * 16, p * 11)
               MousePointer(colorM1, colorM2)
            EndIf
            colorTemp1 = color1
            colorTemp2 = color2
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVFill (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i=0, color6.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: lines
      ;      color2: points
      ;      color3: shadow optional
      ;      color4: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i, colorTemp3.i, colorTemp4.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color6
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color6, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color6, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color6, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color6, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color5
         colorTemp2 = color5
         colorTemp3 = color5
         colorTemp4 = color5
         If Not color5 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceLinearGradient(0, p * 8 - offs, 0, p * 28 - offs)
            VectorSourceGradientColor (Color_Darken(colorTemp3, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(colorTemp3, 0.7), 1.0)
            AddPathBox    (p *  8 - offs, p *  8 - offs, p * 20, p * 20)
            FillPath      (#PB_Path_Preserve)
            VectorSourceColor (colorTemp1)
            StrokePath    (p)

            If i = 3
               FlipCoordinatesX  (p2)
               ScaleCoordinates  (0.8, 0.8)
               RotateCoordinates (p * 14, p2, 45.0)
               ;spout
               VectorSourceColor(Color_Darken(colorTemp2, 0.6))
               MovePathCursor(20 * p, 11.5 * p)
               AddPathLine   (25 * p, 11.5 * p)
               AddPathLine   (20 * p, 15 * p)
               ClosePath     ()
               StrokePath    (3 * p, #PB_Path_RoundCorner)
               ;color @ spout
               RotateCoordinates(p2, p2, -45.0)
               VectorSourceColor (Color_Darken(color3, 0.6))
               AddPathCircle(25.5 * p, 19.5 * p, 1.5 * p, 330, 60)
               StrokePath   (p)
               RotateCoordinates(p2, p2, 45.0)
               ;jug
               VectorSourceLinearGradient(p * 8, 0,    p * 25, 0)
               VectorSourceGradientColor (Color_Darken(colorTemp2, 0.8), 0.0)
               VectorSourceGradientColor (Color_Darken(colorTemp2, 1.0), 0.3)
               VectorSourceGradientColor (Color_Darken(colorTemp2, 0.6), 1.0)
               DrawRoundBox              (8 * p,  10*p, 16 * p, 15 * p, 2 * p)
               FillPath                  ()
               ;handle
               AddPathEllipse(7 * p, 17 * p, 3 * p, 5 * p)
               StrokePath    (p * 1.5)
               ;ring
               VectorSourceLinearGradient(p * 7.0, 0,    p * 25.5, 0)
               VectorSourceGradientColor (Color_Darken(colorTemp4, 0.6), 0.0)
               VectorSourceGradientColor (colorTemp4, 0.3)
               VectorSourceGradientColor (Color_Darken(colorTemp4, 0.5), 1.0)
               MovePathCursor            (7.5 * p, 10.5 * p)
               AddPathLine               (18 * p, 0, #PB_Path_Relative)
               StrokePath                (p * 1.5)
            EndIf
            colorTemp1 = color1
            colorTemp2 = color2
            colorTemp3 = color3
            colorTemp4 = color4
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SetVLayer (file$, img.i, size.i, color1.i, color2.i, color3.i, color5.i=0, color6.i=0)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: bottom layer
      ;      color2: mid layer
      ;      color3: top layer
      ;      color4: shadow optional
      ;      color5: canvas optional
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i, offs.d, colorTemp1.i, colorTemp2.i, colorTemp3.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;canvas
         If color6
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color6, 0.95), 0.0)
            VectorSourceGradientColor (Color_Darken(color6, 0.85), 1.0)
            MovePathCursor(p,      p)
            AddPathLine   (0,      p * 30, #PB_Path_Relative)
            AddPathLine   (p * 30, 0, #PB_Path_Relative)
            AddPathLine   (0,      -p * 30, #PB_Path_Relative)
            ClosePath()
            FillPath(#PB_Path_Preserve)
            VectorSourceLinearGradient(0, 0, size, size)
            VectorSourceGradientColor (Color_Darken(color6, 1), 0.0)
            VectorSourceGradientColor (Color_Darken(color6, 0.8), 1.0)
            StrokePath(p)
         EndIf

         colorTemp1 = color5
         colorTemp2 = color5
         colorTemp3 = color5
         If Not color5 : TranslateCoordinates(p, p) : EndIf
         For i = 0 To 3 Step 3
            offs = p * i
            VectorSourceColor (colorTemp1)
            MovePathCursor(p *  6 -offs, p * 22 -offs)
            AddPathLine   (p * 12,      -p * 8, #PB_Path_Relative)
            AddPathLine   (p * 12,       p * 8, #PB_Path_Relative)
            AddPathLine   (-p * 12,      p * 8, #PB_Path_Relative)
            ClosePath     ()
            FillPath      (#PB_Path_Preserve)
            If i = 3 : VectorSourceColor (Color_Darken(colorTemp1, 0.95)) : EndIf
            StrokePath    (p)

            VectorSourceColor (colorTemp2)
            MovePathCursor(p *  6 -offs, p * 18 -offs)
            AddPathLine   (p * 12,      -p * 8, #PB_Path_Relative)
            AddPathLine   (p * 12,       p * 8, #PB_Path_Relative)
            AddPathLine   (-p * 12,      p * 8, #PB_Path_Relative)
            ClosePath     ()
            FillPath      (#PB_Path_Preserve)
            If i = 3 : VectorSourceColor (Color_Darken(colorTemp2, 0.95)) : EndIf
            StrokePath    (p)

            VectorSourceColor (colorTemp3)
            MovePathCursor(p *  6 -offs, p * 14 -offs)
            AddPathLine   (p * 12,      -p * 8, #PB_Path_Relative)
            AddPathLine   (p * 12,       p * 8, #PB_Path_Relative)
            AddPathLine   (-p * 12,      p * 8, #PB_Path_Relative)
            ClosePath     ()
            FillPath      (#PB_Path_Preserve)
            If i = 3 : VectorSourceColor (Color_Darken(colorTemp3, 0.95)) : EndIf
            StrokePath    (p)
            colorTemp1 = color1
            colorTemp2 = color2
            colorTemp3 = color3
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure



   Macro DrawMagnifyingGlass_Spatial (_x_, _y_, _size_, _reflection_=#False)
      ; _x_, _y_    : coordinates of the upper left corner
      ; _size_      : width and height
      ; _reflection_: #True / #False
      ; [by Little John, spatialized by Oma]

      ; grip
      VectorSourceLinearGradient(_x_+0.14*_size_, _y_+0.70*_size_, _x_+0.30*_size_, _y_+0.86*_size_)
      VectorSourceGradientColor(Color_Darken(color1, 0.1), 0.0)
      VectorSourceGradientColor(Color_Darken(color1, 0.25), 0.25)
      VectorSourceGradientColor(color1, 0.4)
      VectorSourceGradientColor(Color_Darken(color1, 0.4), 0.55)
      VectorSourceGradientColor(Color_Darken(color1, 0.1), 1.0)
      MovePathCursor(_x_+0.37*_size_, _y_+0.63*_size_)
      AddPathLine   (_x_+0.11*_size_, _y_+0.89*_size_)
      StrokePath    (0.16 * _size_, #PB_Path_SquareEnd)

      ; frame
      VectorSourceLinearGradient(_x_+0.36*_size_, _y_+0.06*_size_, _x_+0.94*_size_, _y_+0.64*_size_)
      VectorSourceGradientColor(Color_Darken(color2, 0.4), 0.0)
      VectorSourceGradientColor(color2, 0.45)
      VectorSourceGradientColor(Color_Darken(color2, 0.2), 1.0)
      AddPathCircle(_x_+0.65*_size_, _y_+0.35*_size_, 0.29*_size_)
      StrokePath   (0.04 * _size_)

      If _reflection_
         If flipHorizontally : FlipCoordinatesX(_x_+0.65*_size_) : EndIf
         VectorSourceColor(color3)
         AddPathCircle(_x_+0.65*_size_, _y_+0.35*_size_, 0.17*_size_, -180.0, -90.0)
         StrokePath(0.1 * _size_)
         If flipHorizontally : FlipCoordinatesX(_x_+0.65*_size_) : EndIf
      EndIf
      ; glass
      VectorSourceLinearGradient(_x_+0.40*_size_, _y_+0.1*_size_, _x_+0.90*_size_, _y_+0.60*_size_)
      VectorSourceGradientColor(Color_Transparency (color4, 0.35), 0.0)
      VectorSourceGradientColor(Color_Darken(Color_Transparency (color4, 0.35), 0.6), 1.0)
      AddPathCircle    (_x_+0.65*_size_, _y_+0.35*_size_, 0.25*_size_)
      FillPath()
   EndMacro


   ;- 2 macros for diff. designs of Document_Spatial-Icons ...
   Macro DocuSheet_Spatial_DogEar()   ; round corners
                                      ; shadow
      TranslateCoordinates (p * 1.5, p * 1.5)
      VectorSourceColor    (color_darken(color1, 0.75))
      MovePathCursor       (p2,              p16)
      AddPathLine          (size - p4 - p16, p16)
      AddPathLine          (size - p8,       p4)
      AddPathArc           (size - p8,       size - p16, p8, size - p16, p * 3)
      AddPathArc           (p8,              size - p16, p8, p16,        p * 3)
      AddPathArc           (p8,              p16,        p2, p16,        p * 3)
      ClosePath            ()
      FillPath             ()
      ; sheet
      TranslateCoordinates      (-p * 1.5, -p * 1.5)
      VectorSourceLinearGradient(0, p16, 0, size - p16)
      VectorSourceGradientColor (color_darken(color1, 1.0), 0.0)
      VectorSourceGradientColor (color_darken(color1, 0.85), 1.0)
      MovePathCursor       (p2,              p16)
      AddPathLine          (size - p4 - p16, p16)
      AddPathLine          (size - p8,       p4)
      AddPathArc           (size - p8,       size - p16, p8, size - p16, p16)
      AddPathArc           (p8,              size - p16, p8, p16,        p16)
      AddPathArc           (p8,              p16,        p2, p16,        p16)
      ClosePath            ()
      ; frame
      FillPath(#PB_Path_Preserve)
      VectorSourceLinearGradient(p8, p16, size - p8, size - p16)
      VectorSourceGradientColor (color_darken(color2, 1.0), 0.0)
      VectorSourceGradientColor (color_darken(color2, 0.4), 1.0)
      StrokePath    (p, #PB_Path_DiagonalCorner)
      ; dog-ear
      MovePathCursor(size - p4 - p16, p16)
      AddPathLine   (size - p4 - p16, p4)
      AddPathLine   (size - p8,       p4)
      StrokePath    (p, #PB_Path_DiagonalCorner)
   EndMacro


   Macro DocuSheet_Spatial()   ; writingpad-like
                               ; sheet shadow
      VectorSourceColor(Color_Darken(color1, 0.5))
      AddPathBox       (p * 5, p * 5, p2 + p4, size - p * 5)
      FillPath         ()
      ;sheet
      GradientFullsize_AxisVhi(color1, 0.85)
      AddPathBox       (p8,    p8,    p2 + p4, size - p * 5)
      FillPath         (#PB_Path_Preserve)
      ;frame
      VectorSourceLinearGradient(p8, p8, p * 28, p * 31)
      VectorSourceGradientColor (color2, 0.0)
      VectorSourceGradientColor (color_darken(color2, 0.3), 1.0)
      StrokePath       (1)
   EndMacro


   Procedure.i ToClipboard_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: board
      ;      color2: arrow
      ;      color3: clamb
      ;      color4: shadow
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected hw.d = Round(size / 10.0, #PB_Round_Up)
      Protected p.d = size / 32
      Protected p2.d = size / 2
      Protected p4.d = size / 4
      Protected p8.d = size / 8
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; box
         VectorSourceLinearGradient(p16, p16, size - hw, size - p)
         VectorSourceGradientColor (color_darken(color1, 0.9), 0.0)
         VectorSourceGradientColor (color_darken(color1, 0.8), 1.0)
         ; box
         AddPathBox    (hw, hw, size - 2 * hw, size - hw - size / 32)
         FillPath(#PB_Path_Preserve)
         VectorSourceLinearGradient(p16, p16, size - hw, size - p)
         VectorSourceGradientColor (color1, 0.0)
         VectorSourceGradientColor (color_darken(color1, 0.6), 1.0)
         StrokePath    (p, #PB_Path_DiagonalCorner)

         TranslateCoordinates(1, 1)
         VectorSourceColor(color4)
         For i = 1 To 2
            ; ring
            AddPathCircle (p2, hw + p, hw - p / 2, 190, 350)
            StrokePath    (p)
            ; clamb
            MovePathCursor(p2 - hw, hw * 2)
            AddPathLine   (2 * hw,  0, #PB_Path_Relative)
            StrokePath    (2 * hw,  #PB_Path_RoundCorner)
            If i = 2
               VectorSourceLinearGradient(0, hw * 2 + 1, 0, hw * 3)
               VectorSourceGradientColor (color_darken(color4, 0.3), 0.0)
               VectorSourceGradientColor (color_darken(color4, 0.8), 0.6)
               VectorSourceGradientColor (color_darken(color4, 0.0), 1.0)
            EndIf
            AddPathCircle (p2 - hw,     hw * 3,    hw - 1, 180, 270)
            AddPathLine   (p2 + hw - 1, hw * 2 + 1)
            AddPathCircle (p2 + hw,     hw * 3,    hw - 1, 270,   0, #PB_Path_Connected)
            ClosePath     ()
            FillPath      ()

            TranslateCoordinates(-1, -1)
            VectorSourceColor(color3)
         Next i

         VectorSourceColor(color4)
         For i = 1 To 2
            MovePathCursor(p2 - p4, p2 - p16)
            AddPathLine   (p2,      p2 + p8)
            AddPathLine   (p2 - p4, p2 + p4 + p16)
            ClosePath     ()
            FillPath      ()
            MovePathCursor(p2 - p4, p2 + p8)
            AddPathLine   (0,       p2 + p8)
            StrokePath    (p * 5)
            TranslateCoordinates(-1, -1)
            VectorSourceColor(color2)
         Next i
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i FromClipboard_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: board
      ;      color2: arrow
      ;      color3: clamb
      ;      color4: shadow
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.i
      Protected hw.d = Round(size / 10.0, #PB_Round_Up)
      Protected p.d = size / 32
      Protected p2.d = size / 2
      Protected p4.d = size / 4
      Protected p8.d = size / 8
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; box
         VectorSourceLinearGradient(p16, p16, size - hw, size - p)
         VectorSourceGradientColor (color_darken(color1, 0.9), 0.0)
         VectorSourceGradientColor (color_darken(color1, 0.8), 1.0)
         ; box
         AddPathBox    (hw, hw, size - hw * 2, size - hw - size / 32)
         FillPath(#PB_Path_Preserve)
         VectorSourceLinearGradient(p16, p16, size - hw, size - p)
         VectorSourceGradientColor (color1, 0.0)
         VectorSourceGradientColor (color_darken(color1, 0.6), 1.0)
         StrokePath    (p, #PB_Path_DiagonalCorner)

         TranslateCoordinates(1, 1)
         VectorSourceColor(color4)
         For i = 1 To 2
            ; ring
            AddPathCircle (p2, hw + p, hw - p / 2, 190, 350)
            StrokePath    (p)
            ; clamb
            MovePathCursor(p2 - hw, hw * 2)
            AddPathLine   (2 * hw,  0, #PB_Path_Relative)
            StrokePath    (2 * hw,  #PB_Path_RoundCorner)
            If i = 2
               VectorSourceLinearGradient(0, hw * 2 + 1, 0, hw * 3)
               VectorSourceGradientColor (color_darken(color4, 0.3), 0.0)
               VectorSourceGradientColor (color_darken(color4, 0.8), 0.6)
               VectorSourceGradientColor (color_darken(color4, 0.0), 1.0)
            EndIf
            AddPathCircle (p2 - hw,     hw * 3,    hw - 1, 180, 270)
            AddPathLine   (p2 + hw - 1, hw * 2 + 1)
            AddPathCircle (p2 + hw,     hw * 3,    hw - 1, 270,   0, #PB_Path_Connected)
            ClosePath     ()
            FillPath      ()

            TranslateCoordinates(-1, -1)
            VectorSourceColor(color3)
         Next i

         ResetCoordinates()
         VectorSourceColor(color4)
         For i = 1 To 2
            MovePathCursor(p2 + p4, p2 - p16)
            AddPathLine   (size,    p2 + p8)
            AddPathLine   (p2 + p4, p2 + p4 + p16)
            ClosePath     ()
            FillPath      ()
            MovePathCursor(p2 + p4, p2 + p8)
            AddPathLine   (p2,      p2 + p8)
            StrokePath    (p * 5)
            TranslateCoordinates(-1, -1)
            VectorSourceColor(color2)
         Next i
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Copy_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         For i = 1 To 2
            ; page
            VectorSourceLinearGradient(p, p, p * 20, p * 23)
            VectorSourceGradientColor (color_darken(color1, 1.0), 0.0)
            VectorSourceGradientColor (color_darken(color1, 0.6), 1.0)
            ; AddPathBox    (p * 1.5, p* 1.5, p * 18, p *21);              angular
            DrawRoundBox  (p * 1.5, p* 1.5, p * 18, p *21, p * 1.5);       round corners
            StrokePath    (p * 2, #PB_Path_RoundCorner | #PB_Path_Preserve)
            ; fill
            VectorSourceLinearGradient(p, p, p * 20, p * 23)
            VectorSourceGradientColor (color_darken(color3, 1.0), 0.0)
            VectorSourceGradientColor (color_darken(color3, 0.85), 1.0)
            FillPath      ()
            ; lines
            VectorSourceLinearGradient(p, p, p * 18, p *21)
            VectorSourceGradientColor (color_darken(color2, 1.0), 0.0)
            VectorSourceGradientColor (color_darken(color2, 0.6), 1.0)
            MovePathCursor( 3 * p,  6 * p)
            AddPathLine   (17 * p,  6 * p)
            MovePathCursor( 3 * p, 10 * p)
            AddPathLine   ( 6 * p, 10 * p)
            MovePathCursor( 3 * p, 14 * p)
            AddPathLine   (14 * p, 14 * p)
            MovePathCursor( 3 * p, 18 * p)
            AddPathLine   (12 * p, 18 * p)
            StrokePath    (p)
            TranslateCoordinates(p * 11, p * 8)
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Paste_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: foreground color #1
      ;      color2: foreground color #2
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected i.i, ret.i
      Protected hw.d = Round(size / 10.0, #PB_Round_Up)
      Protected p.d = size / 32
      Protected p2.d = size / 2
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ScaleCoordinates(0.9, 0.9)
         ; box
         VectorSourceLinearGradient(p16, p16, size - hw, size - p)
         VectorSourceGradientColor (color_darken(color4, 0.9), 0.0)
         VectorSourceGradientColor (color_darken(color4, 0.8), 1.0)
         AddPathBox    (hw, hw, size - 2 * hw, size - hw - size / 32)
         FillPath(#PB_Path_Preserve)
         VectorSourceLinearGradient(p16, p16, size - hw, size - p)
         VectorSourceGradientColor (color4, 0.0)
         VectorSourceGradientColor (color_darken(color4, 0.6), 1.0)
         StrokePath    (p * 1.5, #PB_Path_DiagonalCorner)

         TranslateCoordinates(1, 1)
         VectorSourceColor(color6)
         For i = 1 To 2
            ; ring
            AddPathCircle (p2, hw + p, hw - p / 2, 190, 350)
            StrokePath    (p)
            ; clamb
            MovePathCursor(p2 - hw, hw * 2)
            AddPathLine   (2 * hw,  0, #PB_Path_Relative)
            StrokePath    (2 * hw,  #PB_Path_RoundCorner)
            If i = 2
               VectorSourceLinearGradient(0, hw * 2 + 1, 0, hw * 3)
               VectorSourceGradientColor (color_darken(color6, 0.3), 0.0)
               VectorSourceGradientColor (color_darken(color6, 0.8), 0.6)
               VectorSourceGradientColor (color_darken(color6, 0.0), 1.0)
            EndIf
            AddPathCircle (p2 - hw,     hw * 3,    hw - 1, 180, 270)
            AddPathLine   (p2 + hw - 1, hw * 2 + 1)
            AddPathCircle (p2 + hw,     hw * 3,    hw - 1, 270,   0, #PB_Path_Connected)
            ClosePath     ()
            FillPath      ()

            TranslateCoordinates(-1, -1)
            VectorSourceColor(color5)
         Next i

         ResetCoordinates()
         ScaleCoordinates(0.9, 0.9)
         TranslateCoordinates(p * 14, p * 11)
         ; page
         VectorSourceLinearGradient(p, p, p * 20, p * 23)
         VectorSourceGradientColor (color_darken(color1, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color1, 0.6), 1.0)
         ; AddPathBox    (p * 1.5, p* 1.5, p * 18, p *21);              angular
         DrawRoundBox  (p * 1.5, p* 1.5, p * 18, p *21, p * 1.5);       round corners
         StrokePath    (p * 2, #PB_Path_RoundCorner | #PB_Path_Preserve)
         ; fill
         VectorSourceLinearGradient(p, p, p * 20, p * 23)
         VectorSourceGradientColor (color_darken(color3, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color3, 0.9), 1.0)
         FillPath      ()
         ; lines
         VectorSourceLinearGradient(p, p, p * 18, p *21)
         VectorSourceGradientColor (color_darken(color2, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color2, 0.6), 1.0)
         MovePathCursor( 3 * p,  6 * p)
         AddPathLine   (17 * p,  6 * p)
         MovePathCursor( 3 * p, 10 * p)
         AddPathLine   ( 6 * p, 10 * p)
         MovePathCursor( 3 * p, 14 * p)
         AddPathLine   (14 * p, 14 * p)
         MovePathCursor( 3 * p, 18 * p)
         AddPathLine   (12 * p, 18 * p)
         StrokePath    (p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Cut_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, color6.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: blade vert.
      ;      color2: blade diag.
      ;      color3: edge of blade diag.
      ;      color4: grips
      ;      color5: screw
      ;      color6: slit
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p2.d = size / 2
      Protected p16.d = size / 16

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; blade vert.
         VectorSourceLinearGradient(p * 12.5, p * 1.5, p * 15.5, p * 22)
         VectorSourceGradientColor(color1, 0.0)
         VectorSourceGradientColor(Color_Darken(color1, 0.80), 1.0)
         MovePathCursor   (p * 15.5, p * 22)
         AddPathLine      (0,       -p * 20, #PB_Path_Relative)
         AddPathLine      (-p * 1.5, p16,    #PB_Path_Relative)
         AddPathLine      (-p * 1.5, p * 12, #PB_Path_Relative)
         AddPathLine      (0,        p * 9,  #PB_Path_Relative)
         ClosePath        ()
         FillPath         ()

         ; blade diag.
         VectorSourceLinearGradient(p * 17.5, p * 2, p * 20.5, p * 23)
         VectorSourceGradientColor(color2, 0.0)
         VectorSourceGradientColor(Color_Darken(color2, 0.85), 1.0)
         RotateCoordinates(p * 16,   p * 12, 45)
         MovePathCursor   (p * 17.5, p * 22)
         AddPathLine      (0,       -p * 20,  #PB_Path_Relative)
         AddPathLine      (p * 1.5,  p16,     #PB_Path_Relative)
         AddPathLine      (p * 1.5,  p * 12,  #PB_Path_Relative)
         AddPathLine      (0,        p * 8.5, #PB_Path_Relative)
         ClosePath        ()
         FillPath         ()
         ;edge
         VectorSourceColor(color3)
         MovePathCursor   (p * 17.4, p * 18.5)
         AddPathLine      (0,       -p * 16.0, #PB_Path_Relative)
         StrokePath       (p * 0.8)

         ResetCoordinates()
         ; grips
         VectorSourceLinearGradient(p * 14.5, p * 23.5, p * 17.5, p * 29.5)
         VectorSourceGradientColor(Color_Darken(color4, 0.1), 0.0)
         VectorSourceGradientColor(color4, 0.45)
         VectorSourceGradientColor(Color_Darken(color4, 0.1), 1.0)
         RotateCoordinates(p2, p * 26.5, 15)
         AddPathEllipse   (p2, p * 26.5, p * 2.8, p * 4.2)
         StrokePath       (p * 1.6)

         ResetCoordinates()
         VectorSourceLinearGradient(p * 4.5, p * 20.5, p * 8.5, p * 24.5)
         VectorSourceGradientColor(Color_Darken(color4, 0.1), 0.0)
         VectorSourceGradientColor(color4, 0.45)
         VectorSourceGradientColor(Color_Darken(color4, 0.1), 1.0)
         RotateCoordinates(p * 16, p * 12.5, 40)
         AddPathEllipse   (p * 15.2, p * 26.5, p * 2.9, p * 4.6)
         StrokePath       (p * 1.7)
         ResetCoordinates()

         ; screw
         VectorSourceLinearGradient(p * 12.5, p * 16.3, p * 15.5, p * 19.3)
         VectorSourceGradientColor(color5, 0.0)
         VectorSourceGradientColor(Color_Darken(color5, 0.5), 1.0)
         AddPathCircle    (p * 14.0, p * 17.8, p * 1.5)
         FillPath         ()
         ClosePath        ()
         ; slit
         VectorSourceColor(color6)
         MovePathCursor   (p * 13.3, p * 17.1)
         AddPathLine      (p * 1.4,  p * 1.4, #PB_Path_Relative)
         StrokePath       (p * 0.7)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Find_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, flipHorizontally.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: grip
      ;      color2: glass
      ;      color3: reflection
      ;      color4: frame
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John, spatialized by Oma]
      Protected ret.i

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If flipHorizontally
            FlipCoordinatesX(size/2)
         EndIf

         DrawMagnifyingGlass_Spatial(0, 0, size, #True)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i FindNext_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, flipHorizontally.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: grip
      ;      color2: glass
      ;      color3: reflection
      ;      color4: frame
      ;      color5: arrow
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John, spatialized by Oma]
      Protected i.i, ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; Arrow
         VectorSourceColor(#CSS_White)
         For i = 1 To 2
            MovePathCursor(p * 22, p * 26 - flipHorizontally * p * 20)
            AddPathLine   (p *  6, 0, #PB_Path_Relative)
            StrokePath    (p *  5)

            MovePathCursor( p * 26, p * 20 - flipHorizontally * p * 20)
            AddPathLine   ( p *  6, p *  6, #PB_Path_Relative)
            AddPathLine   (-p *  6, p *  6, #PB_Path_Relative)
            ClosePath()
            FillPath()
            VectorSourceColor(color5)
            TranslateCoordinates(-1, -1)
         Next i

         ResetCoordinates()
         If flipHorizontally
            FlipCoordinatesX(size/2)
         EndIf

         DrawMagnifyingGlass_Spatial(0, 0, size, #True)

         ResetCoordinates()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ZoomIn_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, flipHorizontally.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: grip
      ;      color2: glass
      ;      color3: reflection
      ;      color4: frame
      ;      color5: +
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John, spatialized by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If flipHorizontally
            FlipCoordinatesX(size/2)
         EndIf

         VectorSourceLinearGradient(p * 15.75, p * 6.25, p * 26, p * 16.5)
         VectorSourceGradientColor (color_darken(color5, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color5, 0.4), 1.0)
         MovePathCursor(p * 20.75,  p * 6.25)
         AddPathLine   (0,          p * 10, #PB_Path_Relative)
         MovePathCursor(p * 15.75,  p * 11.25)
         AddPathLine   (p * 10,     0,      #PB_Path_Relative)
         StrokePath    (p * 3)

         DrawMagnifyingGlass_Spatial(0, 0, size, #False)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ZoomOut_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, color5.i, flipHorizontally.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: grip
      ;      color2: glass
      ;      color3: reflection
      ;      color4: frame
      ;      color5: -
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John, spatialized by Oma]
      Protected ret.i
      Protected p.d = size / 32


      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If flipHorizontally
            FlipCoordinatesX(size/2)
         EndIf

         VectorSourceLinearGradient(p * 15.75, p * 6.25, p * 26, p * 16.5)
         VectorSourceGradientColor (color_darken(color5, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color5, 0.4), 1.0)
         MovePathCursor(p * 15.75,  p * 11.25)
         AddPathLine   (p * 10,     0, #PB_Path_Relative)
         StrokePath    (p * 3)

         DrawMagnifyingGlass_Spatial(0, 0, size, #False)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i FindAndReplace_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, colorM1.i, colorM2.i, colorM3.i, colorM4.i, colorM5.i, flipHorizontally.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: grip
      ;      color2: glass
      ;      color3: reflection
      ;      color4: frame
      ;      colorM1 - colorM5: DrawPen_Spatial-Macro
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John, spatialized by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If flipHorizontally
            FlipCoordinatesX(size/2)
         EndIf

         ;     VectorSourceColor(color1)
         DrawMagnifyingGlass_Spatial(0, 0, size, #True)
         ResetCoordinates()

         ; pen ...
         TranslateCoordinates(p  , p * 3)
         ScaleCoordinates    (0.9, 0.9)
         RotateCoordinates   (p2,  p2,  45.0)
         TranslateCoordinates(p * 8, -p)
         DrawPen_Spatial(colorM1, colorM2, colorM3, colorM4, colorM5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i NewDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet
      ;      color2: frame
      ;      color3: lines
      ;      color4: +
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         If dogEar
            DocuSheet_Spatial_DogEar()
         Else
            DocuSheet_Spatial()
         EndIf

         ; lines
         VectorSourceLinearGradient(p8, p16, size - p8, size - p16)
         VectorSourceGradientColor (color_darken(color3, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color3, 0.5), 1.0)
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (19 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (24 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (16 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (13 * p, 21 * p)
         MovePathCursor( 7 * p, 25 * p)
         AddPathLine   (14 * p, 25 * p)
         StrokePath    (p)
         ; +
         VectorSourceLinearGradient(p2, p * 18, p * 26, p * 28)
         VectorSourceGradientColor (color_darken(color4, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color4, 0.5), 1.0)
         MovePathCursor(p2 + p8 + p,     p2 + p16)
         AddPathLine   (p2 + p8 + p,     size - p8)
         MovePathCursor(p2,              p2 + p4 - p)
         AddPathLine   (size - p8 - p16, p2 + p4 - p)
         StrokePath    (p * 3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i EditDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, colorM1.i, colorM2.i, colorM3.i,
                                     colorM4.i, colorM5.i, dogEar.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet
      ;      color2: frame
      ;      color3: lines
      ;      colorM1 - colorM5: DrawPen_Spatial-Macro
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         If dogEar
            DocuSheet_Spatial_DogEar()
         Else
            DocuSheet_Spatial()
         EndIf

         ; lines
         VectorSourceLinearGradient(p8, p16, size - p8, size - p16)
         VectorSourceGradientColor (color_darken(color3, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color3, 0.5), 1.0)
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (17 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (20 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (14 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (11 * p, 21 * p)
         StrokePath    (p)
         ; pen ...
         ScaleCoordinates    (0.9, 0.9)
         RotateCoordinates   (p2,   p2,  45.0)
         TranslateCoordinates(p * 8, -p)
         DrawPen_Spatial(colorM1, colorM2, colorM3, colorM4, colorM5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ClearDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet + cross
      ;      color2: frame
      ;      color3: lines
      ;      color4: clear
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         If dogEar
            DocuSheet_Spatial_DogEar()
         Else
            DocuSheet_Spatial()
         EndIf

         ; clear
         ;     VectorSourceColor(color1)
         VectorSourceLinearGradient(p * 7, p * 13, p * 25, p * 27)
         VectorSourceGradientColor (color4, 0.0)
         VectorSourceGradientColor (color_darken(color4, 0.4), 1.0)
         MovePathCursor( 7 * p,  19 * p)
         AddPathLine   (13 * p,  13 * p)
         AddPathLine   (25 * p,  13 * p)
         AddPathLine   (25 * p,  25 * p)
         AddPathLine   (13 * p,  25 * p)
         ClosePath     ()
         FillPath      ()
         VectorSourceColor(color1)
         MovePathCursor(15 * p,  15 * p)
         AddPathLine   (23 * p,  23 * p)
         MovePathCursor(23 * p,  15 * p)
         AddPathLine   (15 * p,  23 * p)
         StrokePath    (p * 3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ImportDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet
      ;      color2: frame
      ;      color3: lines
      ;      color4: arrow
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         If dogEar
            DocuSheet_Spatial_DogEar()
         Else
            DocuSheet_Spatial()
         EndIf

         ; arrow
         VectorSourceLinearGradient(p * 23, p * 15, p * 32, p * 27)
         VectorSourceGradientColor (color4, 0.0)
         VectorSourceGradientColor (color_darken(color4, 0.4), 1.0)
         MovePathCursor( p * 24, p * 14)
         AddPathLine   (-p * 8,  p * 6, #PB_Path_Relative)
         AddPathLine   ( p * 8,  p * 6, #PB_Path_Relative)
         ClosePath     ()
         FillPath      ()
         MovePathCursor( p * 24,  p * 20)
         AddPathLine   ( size,    p * 20)
         StrokePath    ( p8)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i ExportDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet
      ;      color2: frame
      ;      color3: lines
      ;      color4: arrow
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         If dogEar
            DocuSheet_Spatial_DogEar()
         Else
            DocuSheet_Spatial()
         EndIf

         ; lines
         VectorSourceLinearGradient(p8, p16, size - p8, size - p16)
         VectorSourceGradientColor (color_darken(color3, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color3, 0.5), 1.0)
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (19 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (24 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (14 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (13 * p, 21 * p)
         MovePathCursor( 7 * p, 25 * p)
         AddPathLine   (16 * p, 25 * p)
         StrokePath    (p)

         ; arrow
         VectorSourceLinearGradient(p * 22, p * 14, p * 31, p * 27)
         VectorSourceGradientColor (color4, 0.0)
         VectorSourceGradientColor (color_darken(color4, 0.4), 1.0)
         MovePathCursor( p * 24, p * 14)
         AddPathLine   ( p * 8,  p * 6, #PB_Path_Relative)
         AddPathLine   (-p * 8,  p * 6, #PB_Path_Relative)
         ClosePath     ()
         FillPath      ()
         MovePathCursor( p * 16,  p * 20)
         AddPathLine   ( p *  8,  0,     #PB_Path_Relative)
         StrokePath    ( p8)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SaveDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet
      ;      color2: frame
      ;      color3: lines
      ;      color4: arrow
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         If dogEar
            DocuSheet_Spatial_DogEar()
         Else
            DocuSheet_Spatial()
         EndIf

         ; arrow
         VectorSourceLinearGradient(p * 8, p * 9, p * 16, p * 26)
         VectorSourceGradientColor (color4, 0.0)
         VectorSourceGradientColor (color_darken(color4, 0.4), 1.0)
         MovePathCursor( p * 8, p * 18)
         AddPathLine   ( p * 8, p *  8, #PB_Path_Relative)
         AddPathLine   ( p * 8, p * -8, #PB_Path_Relative)
         ClosePath     ()
         FillPath      ()
         MovePathCursor( p * 16,  p * 9)
         AddPathLine   ( p * 16,  p * 18)
         StrokePath    ( p * 6)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i CloseDocument_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i, dogEar.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet
      ;      color2: frame
      ;      color3: lines
      ;      color4: button
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         If dogEar
            DocuSheet_Spatial_DogEar()
         Else
            DocuSheet_Spatial()
         EndIf

         ; lines
         VectorSourceLinearGradient(p8, p16, size - p8, size - p16)
         VectorSourceGradientColor (color_darken(color3, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color3, 0.5), 1.0)
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (19 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (24 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (14 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (13 * p, 21 * p)
         MovePathCursor( 7 * p, 25 * p)
         AddPathLine   (16 * p, 25 * p)
         StrokePath    (p)

         ; button
         VectorSourceLinearGradient(p * 16, p * 16, p * 32, p * 32)
         VectorSourceGradientColor (color_darken(color4, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color4, 0.5), 1.0)
         AddPathCircle    (p * 24, p * 24, p * 8)
         FillPath         ()
         ; bar
         VectorSourceColor(color1)
         MovePathCursor   (size - 7 * p16, size - p4)
         AddPathLine      (6 * p16, 0, #PB_Path_Relative)
         StrokePath       (size / 10)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SortAscending_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, dogEar.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet
      ;      color2: frame
      ;      color3: lines
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         If dogEar
            DocuSheet_Spatial_DogEar()
         Else
            DocuSheet_Spatial()
         EndIf

         ; lines
         VectorSourceLinearGradient(p8, p16, size - p8, size - p16)
         VectorSourceGradientColor (color_darken(color3, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color3, 0.5), 1.0)
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (12 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (12 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (12 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (12 * p, 21 * p)
         MovePathCursor( 7 * p, 25 * p)
         AddPathLine   (12 * p, 25 * p)
         StrokePath    (p)
         ; arrow
         VectorSourceLinearGradient(p * 15, p * 10, p * 27, p * 27)
         VectorSourceGradientColor (color2, 0.0)
         VectorSourceGradientColor (color_darken(color2, 0.5), 1.0)
         MovePathCursor(p * 15, p * 19)
         AddPathLine   (p * 6,  p * 8, #PB_Path_Relative)
         AddPathLine   (p * 6, -p * 8, #PB_Path_Relative)
         ClosePath     ()
         FillPath      ()
         MovePathCursor(p * 21, p * 10)
         AddPathLine   (0,      p * 10, #PB_Path_Relative)
         StrokePath    (p8)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SortDescending_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, dogEar.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet
      ;      color2: frame
      ;      color3: lines
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         If dogEar
            DocuSheet_Spatial_DogEar()
         Else
            DocuSheet_Spatial()
         EndIf

         ; lines
         VectorSourceLinearGradient(p8, p16, size - p8, size - p16)
         VectorSourceGradientColor (color_darken(color3, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color3, 0.5), 1.0)
         MovePathCursor( 7 * p,  9 * p)
         AddPathLine   (12 * p,  9 * p)
         MovePathCursor( 7 * p, 13 * p)
         AddPathLine   (12 * p, 13 * p)
         MovePathCursor( 7 * p, 17 * p)
         AddPathLine   (12 * p, 17 * p)
         MovePathCursor( 7 * p, 21 * p)
         AddPathLine   (12 * p, 21 * p)
         MovePathCursor( 7 * p, 25 * p)
         AddPathLine   (12 * p, 25 * p)
         StrokePath    (p)
         ; arrow
         VectorSourceLinearGradient(p * 15, p * 10, p * 27, p * 27)
         VectorSourceGradientColor (color2, 0.0)
         VectorSourceGradientColor (color_darken(color2, 0.5), 1.0)
         MovePathCursor(p * 15, p * 18)
         AddPathLine   (p * 6, -p * 8, #PB_Path_Relative)
         AddPathLine   (p * 6,  p * 8, #PB_Path_Relative)
         ClosePath     ()
         FillPath      ()
         MovePathCursor(p * 21, p * 18)
         AddPathLine   (0,      p * 8, #PB_Path_Relative)
         StrokePath    (p8)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SortBlockAscending_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, dogEar.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet
      ;      color2: frame
      ;      color3: lines
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         If dogEar
            DocuSheet_Spatial_DogEar()
         Else
            DocuSheet_Spatial()
         EndIf

         ; select block
         VectorSourceLinearGradient(p * 6, p * 11, p * 26, p * 27)
         VectorSourceGradientColor (color_darken(color2, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color2, 0.5), 1.0)
         AddPathBox    (p * 6, p * 11, p2 + p8, p2)
         FillPath()
         ; lines
         VectorSourceColor(color_darken(color3, 0.7))
         MovePathCursor( 8 * p,  9 * p)
         AddPathLine   (13 * p,  9 * p)
         StrokePath    (p * 2)
         VectorSourceLinearGradient(p * 7, p * 13.5, p * 13, p * 25)
         VectorSourceGradientColor (color_darken(color1, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color1, 0.7), 1.0)
         MovePathCursor( 8 * p, 14 * p)
         AddPathLine   (13 * p, 14 * p)
         MovePathCursor( 8 * p, 19 * p)
         AddPathLine   (13 * p, 19 * p)
         MovePathCursor( 8 * p, 24 * p)
         AddPathLine   (13 * p, 24 * p)
         StrokePath    (p * 2)
         ; arrow
         VectorSourceLinearGradient(p * 15, p * 13, p * 25, p * 26)
         VectorSourceGradientColor (color1, 0.0)
         VectorSourceGradientColor (color_darken(color1, 0.7), 1.0)
         MovePathCursor(p * 15, p * 19)
         AddPathLine   (p * 5,  p * 7, #PB_Path_Relative)
         AddPathLine   (p * 5, -p * 7, #PB_Path_Relative)
         ClosePath     ()
         FillPath      ()
         MovePathCursor(p * 20, p * 13)
         AddPathLine   (0,      p *  6, #PB_Path_Relative)
         StrokePath    (p8)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i SortBlockDescending_Spatial (file$, img.i, size.i, color1.i, color2.i, color3.i, dogEar.i=#False)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: sheet
      ;      color2: frame
      ;      color3: lines
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32
      Protected p16 = size / 16
      Protected p8  = size / 8
      Protected p4  = size / 4
      Protected p2  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; sheet
         If dogEar
            DocuSheet_Spatial_DogEar()
         Else
            DocuSheet_Spatial()
         EndIf

         ; select block
         VectorSourceLinearGradient(p * 6, p * 11, p * 26, p * 27)
         VectorSourceGradientColor (color_darken(color2, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color2, 0.5), 1.0)
         AddPathBox    (p * 6, p * 11, p2 + p8, p2)
         FillPath()
         ; lines
         VectorSourceColor(color_darken(color3, 0.7))
         MovePathCursor( 8 * p,  9 * p)
         AddPathLine   (13 * p,  9 * p)
         StrokePath    (p * 2)
         VectorSourceLinearGradient(p * 7, p * 13.5, p * 13, p * 25)
         VectorSourceGradientColor (color_darken(color1, 1.0), 0.0)
         VectorSourceGradientColor (color_darken(color1, 0.7), 1.0)
         MovePathCursor( 8 * p, 14 * p)
         AddPathLine   (13 * p, 14 * p)
         MovePathCursor( 8 * p, 19 * p)
         AddPathLine   (13 * p, 19 * p)
         MovePathCursor( 8 * p, 24 * p)
         AddPathLine   (13 * p, 24 * p)
         StrokePath    (p * 2)
         ; arrow
         VectorSourceLinearGradient(p * 15, p * 12, p * 25, p * 25)
         VectorSourceGradientColor (color1, 0.0)
         VectorSourceGradientColor (color_darken(color1, 0.7), 1.0)
         MovePathCursor(p * 15, p * 19)
         AddPathLine   (p * 5, -p * 7, #PB_Path_Relative)
         AddPathLine   (p * 5,  p * 7, #PB_Path_Relative)
         ClosePath     ()
         FillPath      ()
         MovePathCursor(p * 20, p * 19)
         AddPathLine   (0,      p *  6, #PB_Path_Relative)
         StrokePath    (p8)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Compare_Spatial (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: metal
      ;      color2: string
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Oma]
      Protected i.i, ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ;weighbridge
         ; socket
         VectorSourceLinearGradient(0, p * 27.0, 0, p * 31)
         VectorSourceGradientColor(Color_Darken(color1, 0.5), 0.0)
         VectorSourceGradientColor(color1, 0.35);0.0
         VectorSourceGradientColor(Color_Darken(color1, 0.2), 1.0);1.0
         AddPathCircle (p2, size * 1.5, size * 0.63, 245, 295)    ;250, 290
         ClosePath     ()
         StrokePath    (p * 1.5, #PB_Path_RoundCorner | #PB_Path_Preserve)
         FillPath      ()
         ; rod
         VectorSourceLinearGradient(p * 15, 0, p * 17, 0)
         VectorSourceGradientColor(Color_Darken(color1, 0.1), 0.0)
         VectorSourceGradientColor(color1, 0.45)
         VectorSourceGradientColor(Color_Darken(color1, 0.1), 1.0)
         MovePathCursor(p * 16, p * 27)
         AddPathLine   (0,     -p * 19, #PB_Path_Relative)
         StrokePath    (p16)

         For i = 1 To 2
            VectorSourceColor(Color_Darken(color1, 0.9))
            MovePathCursor  (p2,     p *  4)
            CompilerIf #PB_Compiler_OS = #PB_OS_Windows
               AddPathCurve    (p * 12, p * 4, p * 8, p * 8.5, p * 7, p * 7.5)
               StrokePath      (p *  1,            #PB_Path_Preserve)
               AddPathCurve    (p *  8.5, p * 9.5, p * 5, p * 7, p2,    p * 8)
            CompilerElse
               AddPathCurve    (p * 12, p * 4, p * 8, p * 9, p * 5, p * 5.5)
               StrokePath      (p *  1,            #PB_Path_Preserve)
               AddPathCurve    (p *  9, p * 9, p * 5, p * 6, p2,    p * 8)
            CompilerEndIf
            StrokePath      (p *  1,            #PB_Path_Preserve)
            ClosePath       ()
            VectorSourceColor(Color_Darken(color1, 0.7));0.8
            FillPath        ()

            VectorSourceColor(color2)
            MovePathCursor( p * 7.5, p *  6)
            AddPathLine   (-p * 4,   p * 15, #PB_Path_Relative)
            AddPathLine   ( p * 8,   0,      #PB_Path_Relative)
            AddPathLine   (-p * 4,  -p * 15, #PB_Path_Relative)
            StrokePath    ( p * 0.15)

            VectorSourceLinearGradient(0, p * 20, 0, p * 24)
            VectorSourceGradientColor(color1, 0.0)
            VectorSourceGradientColor(Color_Darken(color1, 0.3), 1.0)
            AddPathCircle (p * 7.5, p * 16.5, p * 7, 35, 145)
            ClosePath     ()
            FillPath      ()
            FlipCoordinatesX(p2)
         Next i

         ; axis
         VectorSourceColor(color1)
         AddPathCircle (p2,     p *  6, p * 1.5)
         FillPath      ()
         ; hub
         VectorSourceColor(Color_Darken(color1, 0.6))
         AddPathCircle (p2,     p *  6, p * 2)
         StrokePath    (p)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Site_Spatial (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: cone & socket
      ;      color2: stripes
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d   = size / 32
      Protected p16.d = size / 16
      Protected p2.d  = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; socket
         VectorSourceLinearGradient(p, p * 19, p * 32, p * 31)
         VectorSourceGradientColor (color1, 0.0)
         VectorSourceGradientColor (color_darken(color1, 0.8), 1.0)
         MovePathCursor       (p * 16, p * 20)
         AddPathArc           (p * 26, p * 20, p * 28.5, p * 25, p16)
         AddPathArc           (p * 31, p * 30, p * 16,   p * 30, p16)
         AddPathArc           (p     , p * 30, p *  3.5, p * 25, p16)
         AddPathArc           (p *  6, p * 20, p * 16,   p * 20, p16)
         ClosePath()
         StrokePath           (p16, #PB_Path_Preserve)
         VectorSourceLinearGradient(0, p * 19, 0, p * 31)
         VectorSourceGradientColor (color1, 0.0)
         VectorSourceGradientColor (color_darken(color1, 0.85), 1.0)
         FillPath()
         ; cone
         VectorSourceLinearGradient(p * 9.25, p * 13.0, p * 30.0, p * 17.0)
         VectorSourceGradientColor (color_darken(color1, 0.8), 0.0)
         VectorSourceGradientColor (color1, 0.2)
         VectorSourceGradientColor (color_darken(color1, 0.8), 0.4)
         VectorSourceGradientColor (color_darken(color1, 0.5), 1.0)
         MovePathCursor(p * 18, p * 2)
         AddPathLine   (p * 25, p * 24.5)
         AddPathEllipse(p2,     p * 24.5, p * 9, p * 3, 0, 180, #PB_Path_Connected)
         AddPathLine   (p * 14, p * 2)
         AddPathEllipse(p2,     p * 2, p * 2, p *0.75, 180, 360)
         ClosePath     ()
         ClipPath      (#PB_Path_Preserve)
         FillPath      ()
         ; hole
         VectorSourceColor(color_darken(color1, 0.7))
         AddPathEllipse(p2,     p * 2, p * 1.5, p *0.5)
         FillPath      ()
         ; stripes
         VectorSourceLinearGradient(p * 9.25, p * 13.0, p * 30.0, p * 17.0)
         VectorSourceGradientColor (color_darken(color2, 0.8), 0.0)
         VectorSourceGradientColor (color2, 0.2)
         VectorSourceGradientColor (color_darken(color2, 0.8), 0.4)
         VectorSourceGradientColor (color_darken(color2, 0.5), 1.0)
         MovePathCursor(p * 25, p * 20)
         AddPathEllipse(p2,     p * 7, p * 6, p * 3, 0, 180)
         AddPathEllipse(p2,     p * 13, p * 7, p * 3, 0, 180)
         AddPathEllipse(p2,     p * 19, p * 8, p * 3, 0, 180)
         StrokePath(p * 3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure

   Macro vText(_x_, _y_, _text_, _color_)
      VectorSourceColor(_color_)
      MovePathCursor(_x_ , _y_)
      DrawVectorText(_text_)
   EndMacro


   Procedure.i Attach (file$, img.i, size.i, color1.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma,
      ;  LJ: removed unused parameter 'color2']
      Protected ret.i, i.i
      Protected p.d  = size / 32
      Protected p2.d = size / 2

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(#CSS_White)
         RotateCoordinates(p2, p2, 45)
         For i = 1 To 2
            MovePathCursor(p * 10,   p * 26)
            AddPathCircle (p2,       p * 7,  p * 6.0, 180,   0, #PB_Path_Connected)
            AddPathCircle (p * 17.5, p * 25, p * 4.5,   0, 180, #PB_Path_Connected)
            AddPathCircle (p * 16,   p * 12, p * 3.0, 180,   0, #PB_Path_Connected)
            AddPathLine   (0,        p * 13, #PB_Path_Relative)
            StrokePath    (p * 2)

            VectorSourceColor(color1)
            TranslateCoordinates(1, 1)
         Next i

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Mail_Symbol (file$, img.i, size.i, color1.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p2.d = size / 2
      Protected.d tW, tH

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If Not IsFont(1)
            LoadFont(1, "Sans bold", 10)
         EndIf
         VectorFont(FontID(1), size * 0.8)
         tW = VectorTextWidth("@")
         tH = VectorTextHeight("@")

         vText(p2 - tW / 2,     p2 - tH / 2, "@", #CSS_White)
         vText(p2 - tW / 2 + 1, p2 - tH / 2 + 1, "@", color1)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Currency_Symbol (file$, img.i, size.i, color1.i, char.s)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: color
      ;      char  : currency sign
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p2.d = size / 2
      Protected.d tW, tH

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         If Not IsFont(1)
            LoadFont(1, "Sans bold", 10)
         EndIf
         VectorFont(FontID(1), size * 0.8)
         tW = VectorTextWidth(char)
         tH = VectorTextHeight(char)

         vText(p2 - tW / 2,     p2 - tH / 2, char, #CSS_White)
         vText(p2 - tW / 2 + 1, p2 - tH / 2 + 1, char, color1)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   ;- * * *  Icon set #3 (Flags)  * * *

   Macro Flag_2HBars (_color1_, _color2_)
      VectorSourceColor(#CSS_White)
      MovePathCursor(0,       p * 16 - 1)
      AddPathLine   (size-1, p * 16 - 1)
      StrokePath    (p * 18)

      VectorSourceColor(_color1_)
      MovePathCursor(1,    p * 11.5)
      AddPathLine   (size, p * 11.5)
      StrokePath    (p * 9)

      VectorSourceColor(_color2_)
      MovePathCursor(1,    p * 20.5)
      AddPathLine   (size, p * 20.5)
      StrokePath    (p * 9)
   EndMacro

   Macro Flag_3HBars (_color1_, _color2_, _color3_)
      VectorSourceColor(#CSS_White)
      MovePathCursor(0,       p * 16 - 1)
      AddPathLine   (size-1, p * 16 - 1)
      StrokePath    (p * 18)

      VectorSourceColor(_color1_)
      MovePathCursor(1,    p * 10)
      AddPathLine   (size, p * 10)
      StrokePath    (p * 6)

      VectorSourceColor(_color2_)
      MovePathCursor(1,    p * 16)
      AddPathLine   (size, p * 16)
      StrokePath    (p * 6)

      VectorSourceColor(_color3_)
      MovePathCursor(1,    p * 22)
      AddPathLine   (size, p * 22)
      StrokePath    (p * 6)
   EndMacro

   Macro Flag_3VBars(_color1_, _color2_, _color3_)
      VectorSourceColor(#CSS_White)
      MovePathCursor(0,       p * 16 - 1)
      AddPathLine   (size-1, p * 16 - 1)
      StrokePath    (p * 18)

      VectorSourceColor(_color1_)
      MovePathCursor(1 + (size-1) / 6,  p * 7)
      AddPathLine   (1 + (size-1) / 6,  p * 25)
      StrokePath    ((size-1) / 3)

      VectorSourceColor(_color2_)
      MovePathCursor(1 + (size-1) / 2,  p * 7)
      AddPathLine   (1 + (size-1) / 2,  p * 25)
      StrokePath    ((size-1) / 3)

      VectorSourceColor(_color3_)
      MovePathCursor(1 + (size-1) / 1.2,  p * 7)
      AddPathLine   (1 + (size-1) / 1.2,  p * 25)
      StrokePath    ((size-1) / 3)
   EndMacro


   Procedure.i Flag_Australia (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, k.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(#CSS_White)
         MovePathCursor(0,        p * 16 - 1)
         AddPathLine   (size - 1, p * 16 - 1)
         StrokePath    (p * 18)

         VectorSourceColor(color1)
         MovePathCursor(1,    p * 16)
         AddPathLine   (size, p * 16)
         StrokePath    (p * 18)

         SaveVectorState()

         ScaleCoordinates(0.5, 0.5)
         TranslateCoordinates(p * 0.5, p * 7)
         AddPathBox(1, p * 7, size - 1, p * 18)
         ClipPath()

         VectorSourceColor(color2)
         MovePathCursor(1,      p *  7)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p *  7)
         AddPathLine   (p * 17, p * 16)
         MovePathCursor(1,      p * 25)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p * 25)
         AddPathLine   (p * 17, p * 16)
         StrokePath    (p *  4)

         VectorSourceColor(color3)
         MovePathCursor(1,      p *  7)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p *  7)
         AddPathLine   (p * 17, p * 16)
         MovePathCursor(1,      p * 25)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p * 25)
         AddPathLine   (p * 17, p * 16)
         StrokePath    (p * 1.5)

         VectorSourceColor(color2)
         MovePathCursor(p * 16, p *  7)
         AddPathLine   (p * 16, p * 25)
         MovePathCursor(1,      p * 16)
         AddPathLine   (size,   p * 16)
         StrokePath    (p * 5)

         VectorSourceColor(color3)
         MovePathCursor(p * 16, p *  7)
         AddPathLine   (p * 16, p * 25)
         MovePathCursor(1,      p * 16)
         AddPathLine   (size,   p * 16)
         StrokePath    (p * 2.5)

         RestoreVectorState()

         VectorSourceColor(color2)
         DrawStar(0.25*size, 0.63*size, 0.085*size, 7)
         DrawStar(0.75*size, 0.33*size, 0.05 *size, 7)
         DrawStar(0.75*size, 0.67*size, 0.05 *size, 7)
         DrawStar(0.63*size, 0.47*size, 0.05 *size, 7)
         DrawStar(0.87*size, 0.43*size, 0.05 *size, 7)
         DrawStar(0.80*size, 0.53*size, 0.035*size, 7)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Austria (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: middle horizontal bar
      ;      color2: upper and lower horizontal bar
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      ; Note by LJ: Correct proportions of this flag are 2:3 [according to Wikipedia].
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3HBars(color2, color1, color2)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Bangladesh (file$, img.i, size.i, color1.i=$FF412AF4, color2.i=$FF4E6A00)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: filled circle
      ;      color2: background
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John, according to
      ;  <https://de.wikipedia.org/wiki/Flagge_Bangladeschs>, 2018-07-14]
      Protected.i ret
      Protected.d p, half

      p    = size / 5.0
      half = size / 2.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; background
         AddPathBox(0, p, size, 3*p)
         VectorSourceColor(color2)
         FillPath()

         ; filled circle
         AddPathCircle(size*9.0/20.0, half, p)
         VectorSourceColor(color1)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Belgium (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3VBars(color1, color2, color3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Brazil (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: background
      ;      color2: rhombus
      ;      color3: circle
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [original by holzhacker]
      Protected ret.i
      Protected p.d = size / 32.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         MovePathCursor(0,    p * 16 - 1)
         AddPathLine   (size, p * 16 - 1)
         StrokePath    (p * 20)

         VectorSourceColor(color2)
         MovePathCursor(p * 3, p * 16)
         AddPathLine   (p * 16,            p *  7)
         AddPathLine   ((p * 14.500)*2, p * 16)
         AddPathLine   (p * 16,         p * 25)
         ClosePath()
         FillPath()

         VectorSourceColor(color3)
         AddPathCircle(p * 16, p * 16, p * 6)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Bulgaria (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      ; Note by LJ: Correct proportions of this flag are 3:5 [according to Wikipedia].
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3HBars(color1, color2, color3)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Canada (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         MovePathCursor(0,        p * 16 - 1)
         AddPathLine   (size - 1, p * 16 - 1)
         StrokePath    (p * 18)

         VectorSourceColor(color2)
         MovePathCursor(1 + p *  3.875, p *  7)
         AddPathLine   (1 + p *  3.875, p * 25)
         StrokePath    (p *  7.75)
         VectorSourceColor(color2)
         MovePathCursor(p * 28.125, p *  7)
         AddPathLine   (p * 28.125, p * 25)
         StrokePath    (p *  7.75)

         MovePathCursor(p * 16.0,   p * 19.584)
         AddPathLine   (p * 12.608, p * 19.968)
         AddPathLine   (p * 12.928, p * 18.912)
         AddPathLine   (p *  9.696, p * 16.288)
         AddPathLine   (p * 10.624, p * 15.872)
         AddPathLine   (p * 10.016, p * 13.696)
         AddPathLine   (p * 11.968, p * 14.112)
         AddPathLine   (p * 12.288, p * 13.12)
         AddPathLine   (p * 14.208, p * 15.008)
         AddPathLine   (p * 13.536, p * 11.2)
         AddPathLine   (p * 14.72,  p * 11.808)
         AddPathLine   (p * 16.0,   p *  9.504)
         AddPathLine   (p * 17.28,  p * 11.808)
         AddPathLine   (p * 18.464, p * 11.2)
         AddPathLine   (p * 17.792, p * 15.008)
         AddPathLine   (p * 19.712, p * 13.12)
         AddPathLine   (p * 20.032, p * 14.112)
         AddPathLine   (p * 21.984, p * 13.696)
         AddPathLine   (p * 21.376, p * 15.872)
         AddPathLine   (p * 22.304, p * 16.288)
         AddPathLine   (p * 19.072, p * 18.912)
         AddPathLine   (p * 19.392, p * 19.968)

         ClosePath     ()
         FillPath()

         MovePathCursor(p * 16.0, p * 23)
         AddPathLine   (p * 16.0, p * 18)
         StrokePath    ( p )

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_China (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: background
      ;      color2: stars
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, k.i
      Protected p.d = size / 32.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         MovePathCursor(0,    p * 16 - 1)
         AddPathLine   (size, p * 16 - 1)
         StrokePath    (p * 20)

         VectorSourceColor(color2)
         DrawStar(0.22*size, 0.37*size, 0.13*size, 5,   0.0)
         DrawStar(0.43*size, 0.26*size, 0.04*size, 5, 315.0)
         DrawStar(0.48*size, 0.32*size, 0.04*size, 5, 345.0)
         DrawStar(0.48*size, 0.41*size, 0.04*size, 5,  15.0)
         DrawStar(0.43*size, 0.47*size, 0.04*size, 5,  45.0)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Czech (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_2HBars(color1, color2)

         VectorSourceColor(color3)
         MovePathCursor(1,            p *  7)
         AddPathLine   (0.5 + p * 16, p * 16)
         AddPathLine   (1,            p * 25)
         ClosePath()
         FillPath      ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Denmark (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: background
      ;      color2: cross
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         MovePathCursor(0,    p * 16 - 1)
         AddPathLine   (size, p * 16 - 1)
         StrokePath    (p * 20)

         VectorSourceColor(color2)
         MovePathCursor(0,      p * 16)
         AddPathLine   (size,   p * 16)
         MovePathCursor(p * 13, p *  6)
         AddPathLine   (p * 13, p * 26)
         StrokePath    (p * 4)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Estonia (file$, img.i, size.i, color1.i=#Pantone_285C, color2.i=#CSS_Black, color3.i=#CSS_White)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: upper  horizontal bar
      ;      color2: middle horizontal bar
      ;      color3: lower  horizontal bar
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John, according to
      ;  <https://en.wikipedia.org/wiki/Flag_of_Estonia>, 2018-07-14]
      Protected.i ret
      Protected.d p, s

      p = size * 2.0/11.0
      s = size * 7.0/33.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; upper horizontal bar
         AddPathBox(0, p, size, s)
         VectorSourceColor(color1)
         FillPath()

         ; middle horizontal bar
         AddPathBox(0, p+s, size, s)
         VectorSourceColor(color2)
         FillPath()

         ; lower horizontal bar
         AddPathBox(0, p+2*s, size, s)
         VectorSourceColor(color3)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Europe (file$, img.i, size.i, color1.i=#Pantone_Yellow, color2.i=#Pantone_ReflexBlue)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: color of the stars
      ;      color2: background color
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John, according to the official geometrical description on
      ;  <http://publications.europa.eu/code/en/en-5000100.htm>, 2018-07-09]
      Protected.i k, i, rotateStar, ret
      Protected.d p, half, r, rs

      p    = size /  6.0
      half = size /  2.0
      r    = size /  4.5    ; radius of the circle
      rs   = size / 27.0    ; outer radius of the stars

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; background
         AddPathBox(0, p, size, 4*p)
         VectorSourceColor(color2)
         FillPath()

         ; circle of 12 stars
         rotateStar = 0
         For i = 1 To 12
            DrawStar(half, half-r, rs, 5, rotateStar)
            RotateCoordinates(half, half, 30)          ; rotate coordinate system clockwise
            rotateStar - 30                            ; rotate next star counter-clockwise
         Next
         VectorSourceColor(color1)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Finland (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: background
      ;      color2: cross
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         MovePathCursor(0,    p * 16 - 1)
         AddPathLine   (size, p * 16 - 1)
         StrokePath    (p * 20)

         VectorSourceColor(color2)
         MovePathCursor(0,      p * 16)
         AddPathLine   (size,   p * 16)
         MovePathCursor(p * 12, p *  6)
         AddPathLine   (p * 12, p * 26)
         StrokePath    (p * 5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_France (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3VBars(color1, color2, color3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Germany (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      ; Note by LJ: Correct proportions of this flag are 3:5 [according to Wikipedia].
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3HBars(color1, color2, color3)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_GreatBritain (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(#CSS_White)
         MovePathCursor(0,        p * 16 - 1)
         AddPathLine   (size - 1, p * 16 - 1)
         StrokePath    (p * 18)

         AddPathBox(1, p * 7, size - 1, p * 18)
         ClipPath()

         VectorSourceColor(color1)
         MovePathCursor(1,    p * 16)
         AddPathLine   (size, p * 16)
         StrokePath    (p * 18)

         VectorSourceColor(color2)
         MovePathCursor(1,      p *  7)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p *  7)
         AddPathLine   (p * 17, p * 16)
         MovePathCursor(1,      p * 25)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p * 25)
         AddPathLine   (p * 17, p * 16)
         StrokePath    (p *  4)

         VectorSourceColor(color3)
         MovePathCursor(1,      p *  7)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p *  7)
         AddPathLine   (p * 17, p * 16)
         MovePathCursor(1,      p * 25)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p * 25)
         AddPathLine   (p * 17, p * 16)
         StrokePath    (p * 1.5)

         VectorSourceColor(color2)
         MovePathCursor(p * 16, p *  7)
         AddPathLine   (p * 16, p * 25)
         MovePathCursor(1,      p * 16)
         AddPathLine   (size,   p * 16)
         StrokePath    (p * 5)

         VectorSourceColor(color3)
         MovePathCursor(p * 16, p *  7)
         AddPathLine   (p * 16, p * 25)
         MovePathCursor(1,      p * 16)
         AddPathLine   (size,   p * 16)
         StrokePath    (p * 2.5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Greece (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.d
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(#CSS_White)
         MovePathCursor(0,        p*16 - 1)
         AddPathLine   (size - 1, p*16 - 1)
         StrokePath    (p * 18)

         VectorSourceColor(color1)
         MovePathCursor(1,    p * 16)
         AddPathLine   (size, p * 16)
         StrokePath    (p * 18)

         VectorSourceColor(color2)
         i = 8
         While i < 26
            MovePathCursor(1,    p * i)
            AddPathLine   (size, p * i)
            StrokePath    (p * 2)
            i + 4
         Wend

         VectorSourceColor(color2)
         AddPathBox(1, p * 7, p * 10, p * 10)
         FillPath  ()

         VectorSourceColor(color1)
         MovePathCursor(1 + p * 5,  p *  7)
         AddPathLine   (1 + p * 5,  p * 17)
         MovePathCursor(1,          p * 12)
         AddPathLine   (1 + p * 10, p * 12)
         StrokePath    (p * 2)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Hungary (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      ; Note by LJ: Correct proportions of this flag are 1:2 [according to Wikipedia].
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3HBars(color1, color2, color3)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Ireland (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3VBars(color1, color2, color3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Island (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(#CSS_White)
         MovePathCursor(0,        p*16 - 1)
         AddPathLine   (size - 1, p*16 - 1)
         StrokePath    (p * 20)

         VectorSourceColor(color1)
         MovePathCursor(1,    p * 16)
         AddPathLine   (size, p * 16)
         StrokePath    (p * 20)
         VectorSourceColor(color2)
         MovePathCursor(1,      p * 16)
         AddPathLine   (size,   p * 16)
         MovePathCursor(p * 13, p *  6)
         AddPathLine   (p * 13, p * 26)
         StrokePath    (p * 5)

         VectorSourceColor(color3)
         MovePathCursor(1,      p * 16)
         AddPathLine   (size,   p * 16)
         MovePathCursor(p * 13, p *  6)
         AddPathLine   (p * 13, p * 26)
         StrokePath    (p *  2.5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Italy (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3VBars(color1, color2, color3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Japan (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(#CSS_White)
         MovePathCursor(0,        p*16 - 1)
         AddPathLine   (size - 1, p*16 - 1)
         StrokePath    (p * 20)

         VectorSourceColor(color1)
         MovePathCursor(1,    p * 16)
         AddPathLine   (size, p * 16)
         StrokePath    (p * 20)
         VectorSourceColor(color2)
         AddPathCircle (p * 16, p * 16, p * 6)
         FillPath      ()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_KoreaSouth (file$, img.i, size.i, color1.i, color2.i, color3.i, color4.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(#CSS_White)
         MovePathCursor(0,        p*16 - 1)
         AddPathLine   (size - 1, p*16 - 1)
         StrokePath    (p * 20)

         VectorSourceColor(color1)
         MovePathCursor(1,    p * 16)
         AddPathLine   (size, p * 16)
         StrokePath    (p * 20)

         VectorSourceColor(color2)
         AddPathCircle (p * 16, p * 16, p * 6)
         FillPath      ()

         VectorSourceColor(color3)
         AddPathCircle (p * 16, p * 16, p * 6, 20, 200, #PB_Path_CounterClockwise)
         AddPathCircle (p * 13.4, p * 14.5, p * 3, 210, 30, #PB_Path_CounterClockwise | #PB_Path_Connected)
         ClosePath()
         FillPath ()

         VectorSourceColor(color2)
         AddPathCircle (p * 18.6, p * 17.5, p * 3)
         FillPath      ()

         VectorSourceColor(color4)
         RotateCoordinates(p * 16, p * 16, -55)
         MovePathCursor(p * 13.5,  p * 4.5)
         AddPathLine   (p * 18.5,  p * 4.5)
         MovePathCursor(p * 13.5,  p * 6)
         AddPathLine   (p * 18.5,  p * 6)
         MovePathCursor(p * 13.5,  p * 7.5)
         AddPathLine   (p * 18.5,  p * 7.5)
         StrokePath    (p * 0.75)
         ResetCoordinates()

         RotateCoordinates(p * 16, p * 16, -125)
         MovePathCursor(p * 13.5,  p * 4.5)
         AddPathLine   (p * 18.5,  p * 4.5)
         MovePathCursor(p * 13.5,  p * 7.5)
         AddPathLine   (p * 18.5,  p * 7.5)
         StrokePath    (p * 0.75)
         MovePathCursor(p * 13.5,  p * 6)
         AddPathLine   (p * 18.5,  p * 6)
         DashPath      (p * 0.75,  p * 1.67)
         ResetCoordinates()

         RotateCoordinates(p * 16, p * 16, -235)
         MovePathCursor(p * 13.5,  p * 4.5)
         AddPathLine   (p * 18.5,  p * 4.5)
         MovePathCursor(p * 13.5,  p * 6)
         AddPathLine   (p * 18.5,  p * 6)
         MovePathCursor(p * 13.5,  p * 7.5)
         AddPathLine   (p * 18.5,  p * 7.5)
         DashPath      (p * 0.75,  p * 1.67)
         ResetCoordinates()

         RotateCoordinates(p * 16, p * 16, -305)
         MovePathCursor(p * 13.5,  p * 4.5)
         AddPathLine   (p * 18.5,  p * 4.5)
         MovePathCursor(p * 13.5,  p * 7.5)
         AddPathLine   (p * 18.5,  p * 7.5)
         DashPath      (p * 0.75,  p * 1.67)
         MovePathCursor(p * 13.5,  p * 6)
         AddPathLine   (p * 18.5,  p * 6)
         StrokePath    (p * 0.75)
         ResetCoordinates()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Luxembourg (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      ; Note by LJ: Correct proportions of this flag are 3:5 [according to Wikipedia].
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3HBars(color1, color2, color3)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Netherlands (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      ; Note by LJ: Correct proportions of this flag are 2:3 [according to Wikipedia].
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3HBars(color1, color2, color3)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_NewZealand (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, k.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(#CSS_White)
         MovePathCursor(0,        p * 16 - 1)
         AddPathLine   (size - 1, p * 16 - 1)
         StrokePath    (p * 18)

         VectorSourceColor(color1)
         MovePathCursor(1,    p * 16)
         AddPathLine   (size, p * 16)
         StrokePath    (p * 18)

         SaveVectorState()

         ScaleCoordinates(0.5, 0.5)
         TranslateCoordinates(p * 0.5, p * 7)
         AddPathBox(1, p * 7, size - 1, p * 18)
         ClipPath()

         VectorSourceColor(color2)
         MovePathCursor(1,      p *  7)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p *  7)
         AddPathLine   (p * 17, p * 16)
         MovePathCursor(1,      p * 25)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p * 25)
         AddPathLine   (p * 17, p * 16)
         StrokePath    (p *  4)

         VectorSourceColor(color3)
         MovePathCursor(1,      p *  7)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p *  7)
         AddPathLine   (p * 17, p * 16)
         MovePathCursor(1,      p * 25)
         AddPathLine   (p * 15, p * 16)
         MovePathCursor(size,   p * 25)
         AddPathLine   (p * 17, p * 16)
         StrokePath    (p * 1.5)

         VectorSourceColor(color2)
         MovePathCursor(p * 16, p *  7)
         AddPathLine   (p * 16, p * 25)
         MovePathCursor(1,      p * 16)
         AddPathLine   (size,   p * 16)
         StrokePath    (p * 5)

         VectorSourceColor(color3)
         MovePathCursor(p * 16, p *  7)
         AddPathLine   (p * 16, p * 25)
         MovePathCursor(1,      p * 16)
         AddPathLine   (size,   p * 16)
         StrokePath    (p * 2.5)

         RestoreVectorState()

         VectorSourceColor(color2)
         DrawStar(0.75*size, 0.33*size, 0.06*size)
         DrawStar(0.75*size, 0.67*size, 0.06*size)
         DrawStar(0.63*size, 0.47*size, 0.06*size)
         DrawStar(0.87*size, 0.43*size, 0.06*size)
         FillPath()
         VectorSourceColor(color3)
         DrawStar(0.75*size, 0.33*size, 0.03*size)
         DrawStar(0.75*size, 0.67*size, 0.03*size)
         DrawStar(0.63*size, 0.47*size, 0.03*size)
         DrawStar(0.87*size, 0.43*size, 0.03*size)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Norway (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(#CSS_White)
         MovePathCursor(0,        p*16 - 1)
         AddPathLine   (size - 1, p*16 - 1)
         StrokePath    (p * 20)

         VectorSourceColor(color1)
         MovePathCursor(1,    p * 16)
         AddPathLine   (size, p * 16)
         StrokePath    (p * 20)
         VectorSourceColor(color2)
         MovePathCursor(1,      p * 16)
         AddPathLine   (size,   p * 16)
         MovePathCursor(p * 13, p *  6)
         AddPathLine   (p * 13, p * 26)
         StrokePath    (p * 5)

         VectorSourceColor(color3)
         MovePathCursor(1,      p * 16)
         AddPathLine   (size,   p * 16)
         MovePathCursor(p * 13, p *  6)
         AddPathLine   (p * 13, p * 26)
         StrokePath    (p *  2.5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Poland (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_2HBars(color1, color2)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Romania (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3VBars(color1, color2, color3)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Russia (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      ; Note by LJ: Correct proportions of this flag are 2:3 [according to Wikipedia].
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_3HBars(color1, color2, color3)
         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Spain (file$, img.i, size.i, color1.i=#VI_FlagYellow, color2.i=#VI_FlagRed)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: middle horizontal bar
      ;      color2: upper and lower horizontal bar
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [by Little John, according to
      ;  <https://en.wikipedia.org/wiki/Flag_of_Spain>, 2018-07-14]
      Protected.i ret
      Protected.d p = size / 6.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         ; upper and lower horizontal bar as "background"
         AddPathBox(0, p, size, 4*p)
         VectorSourceColor(color2)
         FillPath()

         ; middle horizontal bar as "foreground"
         AddPathBox(0, 2*p, size, 2*p)
         VectorSourceColor(color1)
         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Sweden (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$ : name of SVG file which is to be created (only supported on Linux),
      ;              or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ;      color1: background
      ;      color2: cross
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(color1)
         MovePathCursor(0,    p * 16 - 1)
         AddPathLine   (size, p * 16 - 1)
         StrokePath    (p * 20)

         VectorSourceColor(color2)
         MovePathCursor(0,      p * 16)
         AddPathLine   (size,   p * 16)
         MovePathCursor(p * 13, p *  6)
         AddPathLine   (p * 13, p * 26)
         StrokePath    (p *  4)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Switzerland (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(#CSS_White)
         MovePathCursor(p *  6 - 1, p * 16 - 1)
         AddPathLine   (p * 26 - 1, p * 16 - 1)
         StrokePath    (p * 20)

         VectorSourceColor(color1)
         MovePathCursor(p * 6,  p * 16)
         AddPathLine   (p * 26, p * 16)
         StrokePath    (p * 20)
         VectorSourceColor(color2)
         MovePathCursor(p * 10, p * 16)
         AddPathLine   (p * 22, p * 16)
         MovePathCursor(p * 16, p * 10)
         AddPathLine   (p * 16, p * 22)
         StrokePath    (p *  3.5)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_Ukraine (file$, img.i, size.i, color1.i, color2.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img   : number of the image which is to be created, or #PB_Any
      ;      size  : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i
      Protected p.d = size / 32

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         Flag_2HBars(color1, color2)

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure


   Procedure.i Flag_USA (file$, img.i, size.i, color1.i, color2.i, color3.i)
      ; in : file$: name of SVG file which is to be created (only supported on Linux),
      ;             or "" for creating an image in memory
      ;      img  : number of the image which is to be created, or #PB_Any
      ;      size : width and height (number of pixels)
      ; out: return value: if img = #Pb_Any --> number of the created image,
      ;                    on error --> 0
      ; [org. by Oma]
      Protected ret.i, i.d
      Protected p.d = size / 32.0

      ret = StartVectorIconOutput(file$, img, size)

      If ret
         VectorSourceColor(#CSS_White)
         MovePathCursor(0,        p * 16 - 1)
         AddPathLine   (size - 1, p * 16 - 1)
         StrokePath    (p * 18)

         VectorSourceColor(color1)
         MovePathCursor(1,     p * 16)
         AddPathLine   (size,  p * 16)
         StrokePath    (p * 18)

         VectorSourceColor(color2)
         i = 7.7
         While i < 26
            MovePathCursor(1,    p * i)
            AddPathLine   (size, p * i)
            StrokePath    (p * 1.4)
            i + 2.8
         Wend

         VectorSourceColor(color3)
         AddPathBox(1, p * 7, p * 15, p * 10)
         FillPath  ()

         VectorSourceColor(color1)
         i = 0.75
         While i < 14 : AddPathCircle (p + p * i, p *  8, p * 0.5) : i + 2 : Wend : i = 0.75
         While i < 14 : AddPathCircle (p + p * i, p * 10, p * 0.5) : i + 2 : Wend : i = 0.75
         While i < 14 : AddPathCircle (p + p * i, p * 12, p * 0.5) : i + 2 : Wend : i = 0.75
         While i < 14 : AddPathCircle (p + p * i, p * 14, p * 0.5) : i + 2 : Wend : i = 0.75
         While i < 14 : AddPathCircle (p + p * i, p * 16, p * 0.5) : i + 2 : Wend : i = 1.75

         While i < 13 : AddPathCircle (p + p * i, p *  9, p * 0.5) : i + 2 : Wend : i = 1.75
         While i < 13 : AddPathCircle (p + p * i, p * 11, p * 0.5) : i + 2 : Wend : i = 1.75
         While i < 13 : AddPathCircle (p + p * i, p * 13, p * 0.5) : i + 2 : Wend : i = 1.75
         While i < 13 : AddPathCircle (p + p * i, p * 15, p * 0.5) : i + 2 : Wend

         FillPath()

         StopVectorDrawing()
      EndIf

      ProcedureReturn ret
   EndProcedure
EndModule

; IDE Options = PureBasic 5.70 LTS (Windows - x64)
; Folding = -----------------------------------------------------------------
; EnableXP
; EnableUser
; EnableExeConstant
; EnableUnicode