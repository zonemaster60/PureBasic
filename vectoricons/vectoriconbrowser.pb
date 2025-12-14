; PB 5.40+, cross-platform
; by Little John, 2018-07-15
; http://www.purebasic.fr/english/viewtopic.php?f=12&t=65091
;
; Displays the icons and allows to save them as PNG files
; (and on Linux as SVG files, too).

EnableExplicit

XIncludeFile "vectoricons.pbi"

UseModule VectorIcons
UsePNGImageEncoder()

; For PB versions < 5.70, we need to define this ourselves:
CompilerIf #PB_Compiler_OS = #PB_OS_Windows
   #PS$ = "\"
CompilerElse
   #PS$ = "/"
CompilerEndIf

Structure IconsetStruc
   name$
   *label
   *procAddr
   firstIcon.i
   numIcons.i   ; number of icons in the set (not counting the "disabled" versions)
EndStructure

Prototype.i protoCreateIcons (size.i, start.i, createSVG.i=#False)

NewList s_FileName$()


Procedure RestoreDataPtr (*address)
   ; -- set PB data pointer by variable
   ; [https://www.purebasic.fr/english/viewtopic.php?p=439630#p439630]

   CompilerIf #PB_Compiler_Processor = #PB_Processor_x86
      ! mov eax, [p.p_address]
      ! mov [PB_DataPointer], eax
   CompilerElse
      ! mov rax, [p.p_address]
      ! mov [PB_DataPointer], rax
   CompilerEndIf
EndProcedure


Macro NewIcon (_proc_)
   file$ = ""

   CompilerIf #PB_Compiler_OS = #PB_OS_Linux
      If createSVG
         file$ = s_FileName$() + ".svg"
         NextElement(s_FileName$())
      EndIf
   CompilerEndIf

   _proc_
   img + 1
EndMacro


;{ Names of icons in set #1
DataSection
   IconNames01:
   Data.s "Transparent", "Add", "Refresh", "SelectAll", "Checked", "Sub", "Delete", "Find",
          "FindNext", "Question1", "Question2", "FivePointedStar", "Wizard", "Diskette",
          "Alarm1", "Alarm2", "Quit", "HotDrink/Pause", "Watch", "Night", "UpArrow",
          "DownArrow", "LeftArrow", "RightArrow", "ReSize", "Stop1", "Stop2", "Warning1",
          "Warning2", "On", "Off", "Info1", "Info2", "Collapse", "Expand", "Success", "Home",
          "AlignLeft", "AlignCentre", "AlignRight", "AlignJustify", "Compile", "CompileRun",
          "Settings", "Options", "Toggle1", "Toggle2", "Save1", "ZoomIn", "ZoomOut",
          "Great/OK", "Download1", "Upload1", "LineWrapOn", "LineWrapOff", "Donate1",
          "Donate2", "Filter", "Bookmark", "Database", "Tools", "Sort", "Randomise",
          "IsProtected", "UnProtected1", "UnProtected2", "Network", "Music", "Microphone",
          "Picture", "Bug", "Debug", "Crop", "ReSize2", "Rating", "Orange Fruit",
          "Lemon Fruit", "Lime Fruit", "Action", "Move", "Lock" , "Unlock", "Fill", "Message",
          "Colours", "Navigation 1", "Navigation 2", "Volume", "Secure", "Book", "Library",
          "USB", "Chess_WhitePawn", "Chess_BlackPawn", "Chess_WhiteRook", "Chess_BlackRook",
          "Chess_WhiteKnight", "Chess_BlackKnight", "Chess_WhiteBishop", "Chess_BlackBishop",
          "Chess_WhiteKing", "Chess_BlackKing", "Chess_WhiteQueen", "Chess_BlackQueen",
          "History", "Danger", "The Sun", "Good Luck", "Telephone", "BlueTooth", "Broadcast",
          "Speaker", "Mute", "Battery Charging", "Snowflake", "A2M", "N2Z", "Rain Cloud",
          "Cloud Storage", "MediaPlay", "MediaStop", "MediaBegin", "MediaEnd", "MediaForward",
          "MediaFastForward", "MediaBack", "MediaFastBack", "FirstAid", "NoEntry", "Stop3",
          "Download2", "FirstAidSpatial", "NoEntrySpatial", "Stop3Spatial", "Download2Spatial",
          "ToClipboard", "FromClipboard", "Copy", "Paste", "Cut", "Undo", "Redo", "Open1",
          "Open2", "Open3", "Save2", "SaveAs2", "Printer1", "PrinterError1", "NewDocument",
          "EditDocument", "ClearDocument", "ImportDocument", "ExportDocument", "CloseDocument",
          "SortAscending", "SortDescending", "SortBlockAsc", "SortBlockDesc", "ChartLine",
          "ChartDot", "ChartLineDot", "ChartPrice", "ChartBarVert", "ChartCylVert",
          "ChartBarHor", "ChartCylHor", "ChartBarVertStacked", "ChartBarHorStacked",
          "ChartCylVertStacked", "ChartCylHorStacked", "ChartArea", "ChartAreaPerc",
          "ChartPie", "ChartRing", "Notes", "NotesSpatial", "UnfoldDown", "UnfoldUp/Eject",
          "UnfoldLeft", "UnfoldRight", "FoldDown", "FoldUp", "FoldLeft", "FoldRight",
          "ArrowBowTop2Right", "ArrowBowRight2Bottom", "ArrowBowBottom2Left",
          "ArrowBowLeft2Top", "ArrowBowBottom2Right", "ArrowBowRight2Top", "ArrowBowTop2Left",
          "ArrowBowLeft2Bottom", "BracketRoundOpen", "BracketRoundClose", "BracketSquareOpen",
          "BracketSquareClose", "BracketAngleOpen", "BracketAngleClose", "BracketCurlyOpen",
          "BracketCurlyClose", "BracketHtml", "Site", "Compare", "Attach", "Mail", "Currency",
          "CurrencyEuro", "CurrencyDollar", "CurrencyPound", "CurrencyYen"
EndDataSection
;}


Procedure.i CreateIcons01 (size.i, start.i, createSVG.i=#False)
   ; in : size     : width and height (number of pixels) of each icon
   ;      start    : number of first image created by this procedure
   ;      createSVG: #True / #False
   ; out: return value: number of different icons (not counting the "disabled" versions)
   Shared s_FileName$()
   Protected file$, img.i=start

   ;--- Create coloured ("enabled") icons
   NewIcon(Transparent(file$, img, size))
   NewIcon(Add(file$, img, size, #CSS_ForestGreen))
   NewIcon(Refresh(file$, img, size, #CSS_ForestGreen))
   NewIcon(SelectAll(file$, img, size, #CSS_ForestGreen))
   NewIcon(Checked(file$, img, size, #CSS_ForestGreen))
   NewIcon(Sub(file$, img, size, #VI_GuardsmanRed))
   NewIcon(Delete(file$, img, size, #VI_GuardsmanRed))
   NewIcon(Find(file$, img, size, #CSS_Black))
   NewIcon(FindNext(file$, img, size, #CSS_Black, #CSS_ForestGreen))
   NewIcon(Question(file$, img, size, #CSS_Yellow))
   NewIcon(Question(file$, img, size, #CSS_White, #CSS_Navy))
   NewIcon(FivePointedStar(file$, img, size, #CSS_Gold))
   NewIcon(Wizard(file$, img, size, #CSS_Black, #CSS_Gold))
   NewIcon(Diskette(file$, img, size, #CSS_Navy, #VI_GuardsmanRed, #CSS_White))
   NewIcon(Alarm(file$, img, size, #CSS_Black))
   NewIcon(Alarm(file$, img, size, #CSS_White, #CSS_Black))
   NewIcon(Quit(file$, img, size, #VI_GuardsmanRed))
   NewIcon(HotDrink(file$, img, size, #CSS_Black))
   NewIcon(Watch(file$, img, size, #CSS_RoyalBlue, #CSS_Black, #CSS_White))
   NewIcon(Night(file$, img, size, #CSS_Gold, #CSS_MidnightBlue))

   NewIcon(Arrow(file$, img, size, #CSS_DimGrey))
   NewIcon(Arrow(file$, img, size, #CSS_DimGrey, 180))
   NewIcon(Arrow(file$, img, size, #CSS_DimGrey, -90))
   NewIcon(Arrow(file$, img, size, #CSS_DimGrey, 90))

   NewIcon(ReSize(file$, img, size, #CSS_ForestGreen))
   NewIcon(Stop(file$, img, size, #VI_GuardsmanRed))
   NewIcon(Stop(file$, img, size, #VI_GuardsmanRed, #CSS_White))
   NewIcon(Warning(file$, img, size, #VI_GuardsmanRed))
   NewIcon(Warning(file$, img, size, #CSS_Black, #CSS_Yellow))
   NewIcon(OnOff(file$, img,  size, #CSS_White, #CSS_ForestGreen))
   NewIcon(OnOff(file$, img, size, #CSS_White, #VI_GuardsmanRed))
   NewIcon(Info(file$, img, size, #CSS_Yellow))
   NewIcon(Info(file$, img, size, #CSS_White, #CSS_Navy))
   NewIcon(Collapse(file$, img, size, #CSS_Black))
   NewIcon(Expand(file$, img, size, #CSS_Black))
   NewIcon(Success(file$, img, size, #CSS_ForestGreen))
   NewIcon(Home(file$, img, size, #CSS_Black))
   NewIcon(AlignLeft(file$, img, size, #CSS_Black))
   NewIcon(AlignCentre(file$, img, size, #CSS_Black))
   NewIcon(AlignRight(file$, img, size, #CSS_Black))
   NewIcon(AlignJustify(file$, img, size, #CSS_Black))
   NewIcon(Compile(file$, img, size, #CSS_Navy))
   NewIcon(CompileRun(file$, img, size, #CSS_Navy))
   NewIcon(Settings(file$, img, size, #CSS_Navy))
   NewIcon(Options(file$, img, size, #CSS_Navy))
   NewIcon(Toggle1(file$, img, size, #VI_GuardsmanRed, #CSS_ForestGreen, #CSS_Silver))
   NewIcon(Toggle2(file$, img, size, #CSS_Silver, #CSS_ForestGreen, #VI_GuardsmanRed))
   NewIcon(Save1(file$, img, size, #CSS_Navy))
   NewIcon(ZoomIn(file$, img, size, #CSS_Black))
   NewIcon(ZoomOut(file$, img, size, #CSS_Black))
   NewIcon(Great(file$, img, size, #CSS_Navy))
   NewIcon(DownLoad1(file$, img, size, #CSS_White, #CSS_ForestGreen))
   NewIcon(UpLoad1(file$, img, size, #CSS_White, #CSS_ForestGreen))
   NewIcon(LineWrapOn(file$, img, size, #CSS_Navy, #VI_GuardsmanRed))
   NewIcon(LineWrapOff(file$, img, size, #CSS_Navy, #VI_GuardsmanRed))
   NewIcon(Donate1(file$, img, size, #VI_GuardsmanRed))
   NewIcon(Donate2(file$, img, size, #VI_GuardsmanRed))
   NewIcon(Filter(file$, img, size, #VI_GuardsmanRed))
   NewIcon(Bookmark(file$, img, size, #CSS_Navy, #CSS_ForestGreen))
   NewIcon(Database(file$, img, size, #CSS_SteelBlue, #CSS_White))
   NewIcon(Tools(file$, img, size, #CSS_DimGrey))
   NewIcon(Sort(file$, img, size, #CSS_FireBrick))
   NewIcon(Randomise(file$, img, size, #CSS_Navy))
   NewIcon(IsProtected(file$, img, size, #CSS_ForestGreen, #CSS_DarkGreen, #CSS_White))
   NewIcon(UnProtected1(file$, img, size, #CSS_Red, #VI_GuardsmanRed, #CSS_Black))
   NewIcon(UnProtected2(file$, img, size, #CSS_Red, #VI_GuardsmanRed, #CSS_Black))
   NewIcon(Network(file$, img, size, #CSS_Navy))
   NewIcon(Music(file$, img, size, #CSS_Navy))
   NewIcon(Microphone(file$, img, size, #CSS_Navy))
   NewIcon(Picture(file$, img, size, #CSS_LightBlue, #CSS_LawnGreen, #CSS_Yellow, #CSS_Sienna,
                   #CSS_White, #CSS_DarkGreen))
   NewIcon(Bug(file$, img, size, #CSS_Orange, #CSS_Black))
   NewIcon(DBug(file$, img, size, #CSS_Orange, #CSS_Black, #CSS_Red))
   NewIcon(Crop(file$, img, size, #CSS_Navy))
   NewIcon(ReSize2(file$, img, size, #CSS_Navy, #CSS_Blue))
   NewIcon(Rating(file$, img, size, #CSS_Orange, #CSS_WhiteSmoke))
   NewIcon(CitrusFruits(file$, img, size, #CSS_Orange, #CSS_WhiteSmoke))
   NewIcon(CitrusFruits(file$, img, size, #CSS_Khaki, #CSS_WhiteSmoke))
   NewIcon(CitrusFruits(file$, img, size, #CSS_LimeGreen, #CSS_WhiteSmoke))
   NewIcon(Action(file$, img, size, #CSS_Red, #CSS_LightGreen, #CSS_Blue))
   NewIcon(Move(file$, img, size, #CSS_Black))
   NewIcon(Lock(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Unlock(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Fill(file$, img, size, #CSS_Black, #CSS_OrangeRed))
   NewIcon(Message(file$, img, size, #CSS_RoyalBlue, #CSS_WhiteSmoke))
   NewIcon(Colours(file$, img, size, #CSS_Red, #CSS_Green, #CSS_Blue, #CSS_Magenta,
                   #CSS_Yellow, #CSS_Cyan))
   NewIcon(Navigation1(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Navigation2(file$, img, size, #CSS_Black, #CSS_RoyalBlue, #CSS_Gold))
   NewIcon(Volume(file$, img, size, #CSS_Black, #CSS_LightSteelBlue))
   NewIcon(Secure(file$, img, size, #CSS_Black))
   NewIcon(Book(file$, img, size, #CSS_Black, #CSS_LightGrey, #CSS_LightGoldenRodYellow))
   NewIcon(Library(file$, img, size, #CSS_SaddleBrown, #CSS_BurlyWood, #CSS_DarkGoldenRod,
                   #CSS_Gold))
   NewIcon(USB(file$, img, size, #CSS_Black))

   NewIcon(Chess_WhitePawn(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackPawn(file$, img, size, #CSS_Black))
   NewIcon(Chess_WhiteRook(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackRook(file$, img, size, #CSS_Black, #CSS_Silver))
   NewIcon(Chess_WhiteKnight(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackKnight(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Chess_WhiteBishop(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackBishop(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Chess_WhiteKing(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackKing(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Chess_WhiteQueen(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackQueen(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))

   NewIcon(History(file$, img, size, #CSS_Black, #CSS_SteelBlue, #CSS_OrangeRed, #CSS_WhiteSmoke))
   NewIcon(Danger(file$, img, size, #CSS_Black, #CSS_WhiteSmoke))
   NewIcon(TheSun(file$, img, size, #CSS_LightSkyBlue, #CSS_Gold))
   NewIcon(GoodLuck(file$, img, size, #CSS_LimeGreen, #CSS_DarkGreen))
   NewIcon(Telephone(file$, img, size, #CSS_Black, #CSS_BurlyWood))
   NewIcon(BlueTooth(file$, img, size, #CSS_Black))
   NewIcon(Broadcast(file$, img, size, #CSS_Black))
   NewIcon(Speaker(file$, img, size, #CSS_Black))
   NewIcon(Mute(file$, img, size, #CSS_Black, #CSS_Red))
   NewIcon(BatteryCharging(file$, img, size, #CSS_Grey, #CSS_Black, #CSS_Yellow))
   NewIcon(Snowflake(file$, img, size, #CSS_Black))
   NewIcon(A2M(file$, img, size, #CSS_Blue))
   NewIcon(N2Z(file$, img, size, #CSS_Blue))
   NewIcon(RainCloud(file$, img, size, #CSS_AliceBlue, #CSS_Silver))
   NewIcon(CloudStorage(file$, img, size, #CSS_AliceBlue, #CSS_Blue))

   NewIcon(MediaPlay(file$, img, size, #CSS_Navy))
   NewIcon(MediaStop(file$, img, size, #CSS_Navy))
   NewIcon(MediaBegin(file$, img, size, #CSS_Navy))
   NewIcon(MediaEnd(file$, img, size, #CSS_Navy))
   NewIcon(MediaForward(file$, img, size, #CSS_Navy))
   NewIcon(MediaFastForward(file$, img, size, #CSS_Navy))
   NewIcon(MediaBack(file$, img, size, #CSS_Navy))
   NewIcon(MediaFastBack(file$, img, size, #CSS_Navy))

   NewIcon(FirstAid(file$, img, size, #CSS_White, #VI_GuardsmanRed))
   NewIcon(NoEntry(file$, img, size, #CSS_White, #VI_GuardsmanRed))
   NewIcon(Stop3(file$, img, size, #CSS_White, #VI_GuardsmanRed))
   NewIcon(Download2(file$, img, size, #CSS_White, #CSS_ForestGreen))
   NewIcon(FirstAid_Spatial(file$, img, size, #CSS_White, #CSS_OrangeRed))
   NewIcon(NoEntry_Spatial(file$, img, size, #CSS_White, #CSS_OrangeRed))
   NewIcon(Stop3_Spatial(file$, img, size, #CSS_White, #CSS_OrangeRed))
   NewIcon(Download2_Spatial(file$, img, size, #CSS_White, #CSS_LimeGreen))
   NewIcon(ToClipboard(file$, img, size, #CSS_Navy, #CSS_Black))
   NewIcon(FromClipboard(file$, img, size, #CSS_Navy, #CSS_Black))
   NewIcon(Copy(file$, img, size, #CSS_Navy, #CSS_White))
   NewIcon(Paste(file$, img, size, #CSS_Navy, #CSS_White))
   NewIcon(Cut(file$, img, size, #CSS_Navy))
   NewIcon(Undo(file$, img, size, #CSS_ForestGreen))
   NewIcon(Redo(file$, img, size, #CSS_ForestGreen))
   NewIcon(Open1(file$, img, size, #CSS_GoldenRod))
   NewIcon(Open2(file$, img, size, #CSS_GoldenRod, #CSS_Navy, #CSS_White))
   NewIcon(Open3(file$, img, size, #CSS_GoldenRod, #CSS_Chocolate))
   NewIcon(Save2(file$, img, size, #CSS_Navy, #CSS_White))
   NewIcon(SaveAs2(file$, img, size, #CSS_Navy, #CSS_White))
   NewIcon(Printer1(file$, img, size, #CSS_DimGrey, #CSS_White))
   NewIcon(PrinterError1(file$, img, size, #CSS_DimGrey, #CSS_White, #CSS_Red))
   NewIcon(NewDocument(file$, img, size, #CSS_White, #CSS_Navy, #CSS_Black))
   NewIcon(EditDocument(file$, img, size, #CSS_White, #CSS_Navy, #CSS_Black))
   NewIcon(ClearDocument(file$, img, size, #CSS_White, #CSS_Navy, #CSS_Black))
   NewIcon(ImportDocument(file$, img, size, #CSS_White, #CSS_Navy, #CSS_Black))
   NewIcon(ExportDocument(file$, img, size, #CSS_White, #CSS_Navy, #CSS_Black))
   NewIcon(CloseDocument(file$, img, size, #CSS_White, #CSS_Navy, #CSS_Red))
   NewIcon(SortAscending(file$, img, size, #CSS_White, #CSS_Navy, #CSS_Black))
   NewIcon(SortDescending(file$, img, size, #CSS_White, #CSS_Navy, #CSS_Black))
   NewIcon(SortBlockAscending(file$, img, size, #CSS_White, #CSS_Navy))
   NewIcon(SortBlockDescending(file$, img, size, #CSS_White, #CSS_Navy))
   NewIcon(ChartLine(file$, img, size, #CSS_Black, #CSS_Green, #CSS_Blue))
   NewIcon(ChartDot(file$, img, size, #CSS_Black, #CSS_Blue))
   NewIcon(ChartLineDot(file$, img, size, #CSS_Black, #CSS_DarkOrange, #CSS_Blue, #CSS_White))
   NewIcon(ChartPrice(file$, img, size, #CSS_Black, #CSS_Blue, #CSS_White))
   NewIcon(ChartBarVert(file$, img, size, #CSS_Black, #CSS_DarkOrange, #CSS_Yellow,
                        #CSS_LightSkyBlue, #CSS_White))
   NewIcon(ChartCylVert(file$, img, size, #CSS_Black, #CSS_Lime, #CSS_Yellow,
                        #CSS_LightSkyBlue, #CSS_White))
   NewIcon(ChartBarHor(file$, img, size, #CSS_Black, #CSS_DarkOrange, #CSS_Yellow,
                       #CSS_LightSkyBlue, #CSS_White))
   NewIcon(ChartCylHor(file$, img, size, #CSS_Black, #CSS_Lime, #CSS_Yellow,
                       #CSS_LightSkyBlue, #CSS_White))
   NewIcon(ChartBarVertStacked(file$, img, size, #CSS_Black, #CSS_LimeGreen, #CSS_DarkOrange,
                               #CSS_RoyalBlue, #CSS_White))
   NewIcon(ChartBarHorStacked(file$, img, size, #CSS_Black, #CSS_LimeGreen, #CSS_DarkOrange,
                              #CSS_RoyalBlue, #CSS_White))
   NewIcon(ChartCylVertStacked(file$, img, size, #CSS_Black, #CSS_Lime, #CSS_Yellow,
                               #CSS_LightSkyBlue, #CSS_White))
   NewIcon(ChartCylHorStacked(file$, img, size, #CSS_Black, #CSS_Lime, #CSS_Yellow,
                              #CSS_LightSkyBlue, #CSS_White))
   NewIcon(ChartArea(file$, img, size, #CSS_Black, #CSS_Yellow, #CSS_DodgerBlue))
   NewIcon(ChartAreaPerc(file$, img, size, #CSS_Black, #CSS_DodgerBlue, #CSS_Yellow, #CSS_DarkOrange))
   NewIcon(ChartPie(file$, img, size, #CSS_Black, #CSS_DarkOrange, #CSS_Yellow, #CSS_CornflowerBlue,
                    #CSS_White))
   NewIcon(ChartRing(file$, img, size, #CSS_DarkGray, #CSS_DarkOrange, #CSS_Yellow, #CSS_CornflowerBlue,
                     #CSS_White))
   NewIcon(Notes(file$, img, size, #CSS_Gold, #CSS_DarkGray, #CSS_Black, #CSS_White, #CSS_White))
   NewIcon(Notes_Spatial(file$, img, size, #CSS_Yellow, #CSS_DarkGray, #CSS_Tan, #CSS3_LightGoldenrod,
                         #CSS_OrangeRed, #CSS_BurlyWood, #CSS_DimGray))

   NewIcon(Unfold(file$, img, size, #CSS_ForestGreen, #CSS_White, 0.0, #False))
   NewIcon(Unfold(file$, img, size, #CSS_ForestGreen, #CSS_White, 180.0, #False))
   NewIcon(Unfold(file$, img, size, #CSS_ForestGreen, #CSS_White, 90.0, #False))
   NewIcon(Unfold(file$, img, size, #CSS_ForestGreen, #CSS_White, 270.0, #False))
   NewIcon(Fold(file$, img, size, #CSS_FireBrick, #CSS_White, 0.0, #False))
   NewIcon(Fold(file$, img, size, #CSS_FireBrick, #CSS_White, 180.0, #False))
   NewIcon(Fold(file$, img, size, #CSS_FireBrick, #CSS_White, 90.0, #False))
   NewIcon(Fold(file$, img, size, #CSS_FireBrick, #CSS_White, 270.0, #False))

   NewIcon(ArrowBowLeft(file$, img, size, #CSS_DimGrey))
   NewIcon(ArrowBowLeft(file$, img, size, #CSS_DimGrey,  90.0))
   NewIcon(ArrowBowLeft(file$, img, size, #CSS_DimGrey, 180.0))
   NewIcon(ArrowBowLeft(file$, img, size, #CSS_DimGrey, 270.0))
   NewIcon(ArrowBowRight(file$, img, size, #CSS_ForestGreen))
   NewIcon(ArrowBowRight(file$, img, size, #CSS_ForestGreen,  90.0))
   NewIcon(ArrowBowRight(file$, img, size, #CSS_ForestGreen, 180.0))
   NewIcon(ArrowBowRight(file$, img, size, #CSS_ForestGreen, 270.0))

   NewIcon(BracketRound(file$, img, size, #CSS_Black, #True))
   NewIcon(BracketRound(file$, img, size, #CSS_Black))
   NewIcon(BracketSquare(file$, img, size, #CSS_Black, #True))
   NewIcon(BracketSquare(file$, img, size, #CSS_Black))
   NewIcon(BracketAngle(file$, img, size, #CSS_Black, #True))
   NewIcon(BracketAngle(file$, img, size, #CSS_Black))
   NewIcon(BracketCurly(file$, img, size, #CSS_Black, #True))
   NewIcon(BracketCurly(file$, img, size, #CSS_Black))
   NewIcon(BracketHtml(file$, img, size, #CSS_Black))

   NewIcon(Site(file$, img, size, #CSS_DarkOrange, #CSS_White))
   NewIcon(Compare(file$, img, size, #CSS_SteelBlue, #CSS_Black))
   NewIcon(Attach(file$, img, size, #CSS_SteelBlue))
   NewIcon(Mail_Symbol(file$, img, size, #CSS_SteelBlue))

   NewIcon(Currency_Symbol(file$, img, size, #CSS_SteelBlue, "¤"))
   NewIcon(Currency_Symbol(file$, img, size, #CSS_SteelBlue, "€"))
   NewIcon(Currency_Symbol(file$, img, size, #CSS_SteelBlue, "$"))
   NewIcon(Currency_Symbol(file$, img, size, #CSS_SteelBlue, "£"))
   NewIcon(Currency_Symbol(file$, img, size, #CSS_SteelBlue, "¥"))


   ;--- Create gray ("disabled") icons
   NewIcon(Transparent(file$, img, size))
   NewIcon(Add(file$, img, size, #CSS_Silver))
   NewIcon(Refresh(file$, img, size, #CSS_Silver))
   NewIcon(SelectAll(file$, img, size, #CSS_Silver))
   NewIcon(Checked(file$, img, size, #CSS_Silver))
   NewIcon(Sub(file$, img, size, #CSS_Silver))
   NewIcon(Delete(file$, img, size, #CSS_Silver))
   NewIcon(Find(file$, img, size, #CSS_Silver))
   NewIcon(FindNext(file$, img, size, #CSS_Silver, #CSS_Silver))
   NewIcon(Question(file$, img, size, #CSS_Silver))
   NewIcon(Question(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(FivePointedStar(file$, img, size, #CSS_Silver))
   NewIcon(Wizard(file$, img, size, #CSS_Silver, #CSS_Silver))
   NewIcon(Diskette(file$, img, size, #CSS_Silver, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Alarm(file$, img, size, #CSS_Silver))
   NewIcon(Alarm(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(Quit(file$, img, size, #CSS_Silver))
   NewIcon(HotDrink(file$, img, size, #CSS_Silver))
   NewIcon(Watch(file$, img, size, #CSS_Silver, #CSS_DimGrey, #CSS_WhiteSmoke))
   NewIcon(Night(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))

   NewIcon(Arrow(file$, img, size, #CSS_Silver))
   NewIcon(Arrow(file$, img, size, #CSS_Silver, 180))
   NewIcon(Arrow(file$, img, size, #CSS_Silver, -90))
   NewIcon(Arrow(file$, img, size, #CSS_Silver, 90))

   NewIcon(ReSize(file$, img, size, #CSS_Silver))
   NewIcon(Stop(file$, img, size, #CSS_Silver))
   NewIcon(Stop(file$, img, size, #CSS_Silver))
   NewIcon(Warning(file$, img, size, #CSS_Silver))
   NewIcon(Warning(file$, img, size, #CSS_Silver))
   NewIcon(OnOff(file$, img , size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(OnOff(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(Info(file$, img, size, #CSS_Silver))
   NewIcon(Info(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(Collapse(file$, img, size, #CSS_Silver))
   NewIcon(Expand(file$, img, size, #CSS_Silver))
   NewIcon(Success(file$, img, size, #CSS_Silver))
   NewIcon(Home(file$, img, size, #CSS_Silver))
   NewIcon(AlignLeft(file$, img, size, #CSS_Silver))
   NewIcon(AlignCentre(file$, img, size, #CSS_Silver))
   NewIcon(AlignRight(file$, img, size, #CSS_Silver))
   NewIcon(AlignJustify(file$, img, size, #CSS_Silver))
   NewIcon(Compile(file$, img, size, #CSS_Silver))
   NewIcon(CompileRun(file$, img, size, #CSS_Silver))
   NewIcon(Settings(file$, img, size, #CSS_Silver))
   NewIcon(Options(file$, img, size, #CSS_Silver))
   NewIcon(Toggle1(file$, img, size, #CSS_Silver, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Toggle2(file$, img, size, #CSS_Silver, #CSS_DimGrey, #CSS_DimGrey))
   NewIcon(Save1(file$, img, size, #CSS_Silver))
   NewIcon(ZoomIn(file$, img, size, #CSS_Silver))
   NewIcon(ZoomOut(file$, img, size, #CSS_Silver))
   NewIcon(Great(file$, img, size, #CSS_Silver))
   NewIcon(DownLoad1(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(UpLoad1(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(LineWrapOn(file$, img, size, #CSS_DimGrey, #CSS_Silver))
   NewIcon(LineWrapOff(file$, img, size, #CSS_DimGrey, #CSS_Silver))
   NewIcon(Donate1(file$, img, size, #CSS_Silver))
   NewIcon(Donate2(file$, img, size, #CSS_Silver))
   NewIcon(Filter(file$, img, size, #CSS_Silver))
   NewIcon(Bookmark(file$, img, size, #CSS_Silver, #CSS_DimGrey))
   NewIcon(Database(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Tools(file$, img, size, #CSS_Silver))
   NewIcon(Sort(file$, img, size, #CSS_Silver))
   NewIcon(Randomise(file$, img, size, #CSS_Silver))
   NewIcon(IsProtected(file$, img, size, #CSS_Silver, #CSS_DimGrey, #CSS_WhiteSmoke))
   NewIcon(UnProtected1(file$, img, size, #CSS_Silver, #CSS_DimGrey, #CSS_WhiteSmoke))
   NewIcon(UnProtected2(file$, img, size, #CSS_Silver, #CSS_DimGrey, #CSS_WhiteSmoke))
   NewIcon(Network(file$, img, size, #CSS_Silver))
   NewIcon(Music(file$, img, size, #CSS_Silver))
   NewIcon(Microphone(file$, img, size, #CSS_Silver))
   NewIcon(Picture(file$, img, size, #CSS_LightGrey, #CSS_Silver, #CSS_DarkGrey, #CSS_DimGrey,
                   #CSS_WhiteSmoke, #CSS_DimGrey))
   NewIcon(Bug(file$, img, size,  #CSS_Silver, #CSS_DimGrey))
   NewIcon(DBug(file$, img, size,  #CSS_Silver, #CSS_DimGrey, #CSS_WhiteSmoke))
   NewIcon(Crop(file$, img, size, #CSS_Silver))
   NewIcon(ReSize2(file$, img, size, #CSS_Silver, #CSS_Silver))
   NewIcon(Rating(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(CitrusFruits(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(CitrusFruits(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(CitrusFruits(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Action(file$, img, size, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(Move(file$, img, size, #CSS_Silver))
   NewIcon(Lock(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Unlock(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Fill(file$, img, size, #CSS_Silver, #CSS_Silver))
   NewIcon(Message(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Colours(file$, img, size, #CSS_DarkGrey, #CSS_Grey, #CSS_Silver, #CSS_DarkGrey,
                   #CSS_Grey, #CSS_Silver))
   NewIcon(Navigation1(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Navigation2(file$, img, size, #CSS_DarkGrey, #CSS_Grey, #CSS_Silver))
   NewIcon(Volume(file$, img, size, #CSS_Grey, #CSS_Silver))
   NewIcon(Secure(file$, img, size, #CSS_Silver))
   NewIcon(Book(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke, #CSS_WhiteSmoke))
   NewIcon(Library(file$, img, size, #CSS_Silver, #CSS_Silver, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(USB(file$, img, size, #CSS_Silver))

   NewIcon(Chess_WhitePawn(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackPawn(file$, img, size, #CSS_Silver))
   NewIcon(Chess_WhiteRook(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackRook(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Chess_WhiteKnight(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackKnight(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Chess_WhiteBishop(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackBishop(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Chess_WhiteKing(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackKing(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Chess_WhiteQueen(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Chess_BlackQueen(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))

   NewIcon(History(file$, img, size, #CSS_DarkGrey, #CSS_Grey, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Danger(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(TheSun(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(GoodLuck(file$, img, size, #CSS_DarkGrey, #CSS_Silver))
   NewIcon(Telephone(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(BlueTooth(file$, img, size, #CSS_Silver))
   NewIcon(Broadcast(file$, img, size, #CSS_Silver))
   NewIcon(Speaker(file$, img, size, #CSS_Silver))
   NewIcon(Mute(file$, img, size, #CSS_Silver, #CSS_Silver))
   NewIcon(BatteryCharging(file$, img, size, #CSS_Grey, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Snowflake(file$, img, size, #CSS_Silver))
   NewIcon(A2M(file$, img, size, #CSS_Silver))
   NewIcon(N2Z(file$, img, size, #CSS_Silver))
   NewIcon(RainCloud(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(CloudStorage(file$, img, size, #CSS_Silver, #CSS_DarkGrey))

   NewIcon(MediaPlay(file$, img, size, #CSS_Silver))
   NewIcon(MediaStop(file$, img, size, #CSS_Silver))
   NewIcon(MediaBegin(file$, img, size, #CSS_Silver))
   NewIcon(MediaEnd(file$, img, size, #CSS_Silver))
   NewIcon(MediaForward(file$, img, size, #CSS_Silver))
   NewIcon(MediaFastForward(file$, img, size, #CSS_Silver))
   NewIcon(MediaBack(file$, img, size, #CSS_Silver))
   NewIcon(MediaFastBack(file$, img, size, #CSS_Silver))

   NewIcon(FirstAid(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(NoEntry(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(Stop3(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(Download2(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(FirstAid_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(NoEntry_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(Stop3_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(Download2_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(ToClipboard(file$, img, size, #CSS_Silver, #CSS_Silver))
   NewIcon(FromClipboard(file$, img, size, #CSS_Silver, #CSS_Silver))
   NewIcon(Copy(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Paste(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Cut(file$, img, size, #CSS_Silver))
   NewIcon(Undo(file$, img, size, #CSS_Silver))
   NewIcon(Redo(file$, img, size, #CSS_Silver))
   NewIcon(Open1(file$, img, size, #CSS_Silver))
   NewIcon(Open2(file$, img, size, #CSS_Silver, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Open3(file$, img, size, #CSS_Silver, #CSS_DarkGrey))
   NewIcon(Save2(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(SaveAs2(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Printer1(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(PrinterError1(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke, #CSS_Silver,
                         #CSS_WhiteSmoke))
   NewIcon(NewDocument(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver))
   NewIcon(EditDocument(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver))
   NewIcon(ClearDocument(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver))
   NewIcon(ImportDocument(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver))
   NewIcon(ExportDocument(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver))
   NewIcon(CloseDocument(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver,
                         #CSS_WhiteSmoke))
   NewIcon(SortAscending(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver))
   NewIcon(SortDescending(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver))
   NewIcon(SortBlockAscending(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(SortBlockDescending(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))
   NewIcon(ChartLine(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartDot(file$, img, size, #CSS_DimGrey, #CSS_Silver))
   NewIcon(ChartLineDot(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartPrice(file$, img, size, #CSS_DimGrey, #CSS_DarkGrey))
   NewIcon(ChartBarVert(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartCylVert(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartBarHor(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartCylHor(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartBarVertStacked(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartBarHorStacked(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartCylVertStacked(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartCylHorStacked(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartArea(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartAreaPerc(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartPie(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(ChartRing(file$, img, size, #CSS_DimGrey, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(Notes(file$, img, size, #CSS_Silver, #CSS_DimGrey, #CSS_DimGrey, #CSS_Silver,
                 #CSS_Silver))
   NewIcon(Notes_Spatial(file$, img, size, #CSS_Silver, #CSS_DimGrey, #CSS_LightGray,
                         #CSS_WhiteSmoke, #CSS_Gray, #CSS_LightGray, #CSS_Gray))

   NewIcon(Unfold(file$, img, size, #CSS_DarkGray, #CSS_LightGray, 0.0, #False))
   NewIcon(Unfold(file$, img, size, #CSS_DarkGray, #CSS_LightGray, 180.0, #False))
   NewIcon(Unfold(file$, img, size, #CSS_DarkGray, #CSS_LightGray, 90.0, #False))
   NewIcon(Unfold(file$, img, size, #CSS_DarkGray, #CSS_LightGray, 270.0, #False))
   NewIcon(Fold(file$, img, size, #CSS_DarkGray, #CSS_LightGray, 0.0, #False))
   NewIcon(Fold(file$, img, size, #CSS_DarkGray, #CSS_LightGray, 180.0, #False))
   NewIcon(Fold(file$, img, size, #CSS_DarkGray, #CSS_LightGray, 90.0, #False))
   NewIcon(Fold(file$, img, size, #CSS_DarkGray, #CSS_LightGray, 270.0, #False))

   NewIcon(ArrowBowLeft(file$, img, size, #CSS_Silver))
   NewIcon(ArrowBowLeft(file$, img, size, #CSS_Silver,  90.0))
   NewIcon(ArrowBowLeft(file$, img, size, #CSS_Silver, 180.0))
   NewIcon(ArrowBowLeft(file$, img, size, #CSS_Silver, 270.0))
   NewIcon(ArrowBowRight(file$, img, size, #CSS_Silver))
   NewIcon(ArrowBowRight(file$, img, size, #CSS_Silver,  90.0))
   NewIcon(ArrowBowRight(file$, img, size, #CSS_Silver, 180.0))
   NewIcon(ArrowBowRight(file$, img, size, #CSS_Silver, 270.0))

   NewIcon(BracketRound(file$, img, size, #CSS_Silver, #True))
   NewIcon(BracketRound(file$, img, size, #CSS_Silver))
   NewIcon(BracketSquare(file$, img, size, #CSS_Silver, #True))
   NewIcon(BracketSquare(file$, img, size, #CSS_Silver))
   NewIcon(BracketAngle(file$, img, size, #CSS_Silver, #True))
   NewIcon(BracketAngle(file$, img, size, #CSS_Silver))
   NewIcon(BracketCurly(file$, img, size, #CSS_Silver, #True))
   NewIcon(BracketCurly(file$, img, size, #CSS_Silver))
   NewIcon(BracketHtml(file$, img, size, #CSS_Silver))

   NewIcon(Site(file$, img, size, #CSS_LightGray, #CSS_WhiteSmoke))
   NewIcon(Compare(file$, img, size, #CSS_DarkGray, #CSS_DarkGray))
   NewIcon(Attach(file$, img, size, #CSS_Silver))
   NewIcon(Mail_Symbol(file$, img, size, #CSS_Silver))

   NewIcon(Currency_Symbol(file$, img, size, #CSS_Silver, "¤"))
   NewIcon(Currency_Symbol(file$, img, size, #CSS_Silver, "€"))
   NewIcon(Currency_Symbol(file$, img, size, #CSS_Silver, "$"))
   NewIcon(Currency_Symbol(file$, img, size, #CSS_Silver, "£"))
   NewIcon(Currency_Symbol(file$, img, size, #CSS_Silver, "￥"))

   ProcedureReturn (img - start) / 2
EndProcedure


;{ Names of icons in set #2
DataSection
   IconNames02:
   Data.s "FindAndReplace", "Open1Spatial", "Open2Spatial", "Open3Spatial", "FindFileSpatial",
          "FindFile", "RotateDownSpatial", "RotateUpSpatial", "RotateVerticalSpatial",
          "RotateLeftSpatial", "RotateRightSpatial", "RotateHorizontalSpatial",
          "RotateCounterClockwiseSpatial", "RotateClockwiseSpatial", "WritingPad",
          "WritingPadSpatial", "CalculateSpatial", "CalendarSpatial", "RulerSpatial",
          "RulerTriangleSpatial", "CartonSpatial", "BookKeepingSpatial", "PenSpatial",
          "PenFlat", "BrushSpatial", "BrushFlat", "PipetteSpatial", "PipetteFlat",
          "FillSpatial", "FillFlat", "SpraySpatial", "SprayFlat", "EraserSpatial",
          "EraserFlat", "ColorPaletteSpatial", "ColorPaletteFlat", "PaintSpatial", "PaintFlat",
          "DrawVText", "DrawVLine", "DrawVBox", "DrawVRoundedBox", "DrawVPolygonBox",
          "DrawVCircle", "DrawVCircleSegment", "DrawVEllipse", "DrawVEllipseSegment",
          "DrawVCurve(Spline)", "DrawVArc", "DrawVLinePath", "SetVSelectRange",
          "SetVLineStyle", "SetVLineWidth", "SetVLineCap", "SetVLineJoin", "SetVColorSelect",
          "SetVColorBoardSelect", "SetVFlipX", "SetVFlipY", "SetVRotate", "SetVMove",
          "SetVCopy", "SetVScale", "SetVTrimSegment", "SetVExtendSegment", "SetVCatchGrid",
          "SetVLinearGradient", "SetVCircularGradient", "SetVChangeCoord", "SetVDelete",
          "SetVFill", "SetVLayer", "ToClipboardSpatial", "FromClipboardSpatial", "CopySpatial",
          "PasteSpatial", "CutSpatial", "FindSpatial", "FindNextSpatial",
          "FindAndReplaceSpatial", "ZoomInSpatial", "ZoomOutSpatial", "NewDocument1Spatial",
          "EditDocument1Spatial", "ClearDocument1Spatial", "ImportDocument1Spatial",
          "ExportDocument1Spatial", "SaveDocument1Spatial", "CloseDocument1Spatial",
          "SortAscending1Spatial", "SortDescending1Spatial", "SortBlockAscending1Spatial",
          "SortBlockDescending1Spatial", "NewDocument2Spatial", "EditDocument2Spatial",
          "ClearDocument2Spatial", "ImportDocument2Spatial", "ExportDocument2Spatial",
          "SaveDocument2Spatial", "CloseDocument2Spatial", "SortAscending2Spatial",
          "SortDescending2Spatial", "SortBlockAscending2Spatial",
          "SortBlockDescending2Spatial", "SiteSpatial", "CompareSpatial"
EndDataSection
;}


Procedure.i CreateIcons02 (size.i, start.i, createSVG.i=#False)
   ; in : size     : width and height (number of pixels) of each icon
   ;      start    : number of first image created by this procedure
   ;      createSVG: #True / #False
   ; out: return value: number of different icons (not counting the "disabled" versions)
   Shared s_FileName$()
   Protected file$, img.i=start

   ;--- Create coloured ("enabled") icons
   NewIcon(FindAndReplace(file$, img, size, #CSS_Black, #CSS_Black, #CSS_WhiteSmoke,
                          #CSS3_Red3, #CSS_BurlyWood, #CSS_Black))
   NewIcon(Open1_Spatial(file$, img, size, #CSS_Gold, #CSS_LightYellow))
   NewIcon(Open2_Spatial(file$, img, size, #CSS_Gold, #CSS_LightYellow, #CSS_Blue, #CSS_White))
   NewIcon(Open3_Spatial(file$, img, size, #CSS_Gold, #CSS_LightYellow))
   NewIcon(FindFile_Spatial(file$, img, size, #CSS_Gold, #CSS_LightYellow, #CSS_Black))
   NewIcon(FindFile(file$, img, size, #CSS_GoldenRod, #CSS_Black))

   NewIcon(RotateDown_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_DarkGray, #CSS_Gold))
   NewIcon(RotateUp_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_DarkGray, #CSS_Gold))
   NewIcon(RotateVert_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_Gold))
   NewIcon(RotateLeft_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_DarkGray, #CSS_Gold))
   NewIcon(RotateRight_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_DarkGray, #CSS_Gold))
   NewIcon(RotateHor_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_Gold))
   NewIcon(RotateCCw_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_Gold))
   NewIcon(RotateCw_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_Gold))

   NewIcon(Writingpad(file$, img, size, #CSS_White, #CSS_Gray, #CSS_Black, #CSS_Black,
                      #CSS_WhiteSmoke, #CSS3_Red3, #CSS_BurlyWood, #CSS_Black))
   NewIcon(Writingpad_Spatial(file$, img, size, #CSS_White, #CSS_DimGray, #CSS_Black, #CSS_Tan,
                              #CSS3_LightGoldenrod, #CSS_OrangeRed, #CSS_BurlyWood, #CSS_DimGray))
   NewIcon(Calculate_Spatial(file$, img, size, #CSS_DeepSkyBlue, #CSS_Black, #CSS_Yellow,
                             #CSS_Beige))   ; #CSS_Yellow
   NewIcon(Calendar_Spatial(file$, img, size, #CSS_White, #CSS_Silver, #CSS_Black,
                            #CSS_OrangeRed, #CSS_Gray))

   NewIcon(Ruler_Spatial(file$, img, size, #CSS_AliceBlue, #CSS_Black))
   NewIcon(RulerTriangle_Spatial(file$, img, size, #CSS_AliceBlue, #CSS_Black))

   NewIcon(Carton_Spatial(file$, img, size, #CSS_SandyBrown, #CSS_PapayaWhip, #CSS_Black,
                          "tar.gz", 0.22))
   NewIcon(BookKeeping_Spatial(file$, img, size, #CSS3_Gray50, #CSS_MediumPurple, #CSS_DimGray,
                               #CSS_Black, #CSS_White))
   NewIcon(Pen_Spatial(file$, img, size, #CSS_Tan, #CSS3_LightGoldenrod, #CSS_OrangeRed,
                       #CSS_BurlyWood, #CSS_DimGray))
   NewIcon(Pen_Flat(file$, img, size, #CSS_Brown, #CSS_WhiteSmoke, #CSS3_Red3, #CSS_BurlyWood, #CSS_Black))
   NewIcon(Brush_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_WhiteSmoke, #CSS_DimGray))
   NewIcon(Brush_Flat(file$, img, size, #CSS3_Red3, #CSS_LightGray, #CSS_Black))
   NewIcon(Pipette_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_HoneyDew))
   NewIcon(Pipette_Flat(file$, img, size, #CSS3_Red3, #CSS_LightBlue, #CSS_DeepSkyBlue))
   NewIcon(Fill_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_White, #CSS_Orange))
   NewIcon(Fill_Flat(file$, img, size, #CSS3_Red3, #CSS_Orange))
   NewIcon(Spray_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_HoneyDew, #CSS_White, #CSS_OrangeRed))
   NewIcon(Spray_Flat(file$, img, size, #CSS3_Red3, #CSS_LightGray, #CSS3_Red3, #CSS_OrangeRed))
   NewIcon(Eraser_Spatial(file$, img, size, #CSS_OrangeRed, #CSS_HoneyDew))
   NewIcon(Eraser_Flat(file$, img, size, #CSS3_Red3, #CSS_LightGray))
   NewIcon(ColorPalette_Spatial (file$, img, size, #CSS_Wheat, #CSS_Red, #CSS_RoyalBlue,
                                 #CSS_Lime, #CSS_Yellow, #CSS_Magenta, #CSS_White))
   NewIcon(ColorPalette_Flat (file$, img, size, #CSS_Wheat, #CSS_Red, #CSS_RoyalBlue,
                              #CSS_Lime, #CSS_Yellow, #CSS_Magenta, #CSS_White))
   NewIcon(Paint_Spatial (file$, img, size, #CSS_Tan, #CSS_Brown, #CSS_Ivory, #CSS_Orange,
                          #CSS_Blue, #CSS_Green, #CSS_Red))
   NewIcon(Paint_Flat (file$, img, size, #CSS_Brown, #CSS_Brown, #CSS_HoneyDew, #CSS_Orange,
                       #CSS_Blue, #CSS_Green, #CSS_Red))

   NewIcon(DrawVText(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))
   NewIcon(DrawVLine(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))
   NewIcon(DrawVBox(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))
   NewIcon(DrawVRoundedBox(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))
   NewIcon(DrawVPolygonBox(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))
   NewIcon(DrawVCircle(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))
   NewIcon(DrawVCircleSegment(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))
   NewIcon(DrawVEllipse(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))
   NewIcon(DrawVEllipseSegment(file$, img, size, #CSS_Red, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))
   NewIcon(DrawVCurve(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))
   NewIcon(DrawVArc(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))
   NewIcon(DrawVLinePath(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_MintCream))

   NewIcon(SetVSelectionRange(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))  ; #CSS_Cornsilk
   NewIcon(SetVLineStyle(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVLineWidth(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVLineCap(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVLineJoin(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVColorSelect(file$, img, size, #CSS_Red, #CSS_Lime, #CSS_Blue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVColorBoardSelect(file$, img, size, #CSS_WhiteSmoke, #CSS_Ivory, #CSS_Wheat, #CSS_Red,
                                #CSS_RoyalBlue, #CSS_Lime, #CSS_Yellow, #CSS_Magenta, #CSS_White))
   NewIcon(SetVFlipX(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVFlipY(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVRotate(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVMove(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVCopy(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVScale(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVTrimSegment(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVExtendSegment(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVCatchGrid(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVLinearGradient(file$, img, size, #CSS_GhostWhite, #CSS_Ivory))
   NewIcon(SetVCircularGradient(file$, img, size, #CSS_GhostWhite, #CSS_Ivory))
   NewIcon(SetVChangeCoord(file$, img, size, #CSS_Black, #CSS_CornflowerBlue, #CSS_Black, #CSS_White,
                           #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVDelete(file$, img, size, #CSS_Black, #CSS_Red, #CSS_Black, #CSS_White, #CSS_Silver, #CSS_Ivory))
   NewIcon(SetVFill(file$, img, size, #CSS_Black, #CSS_DodgerBlue, #CSS_Gold, #CSS_White, #CSS_LightGray,
                    #CSS_Ivory))
   NewIcon(SetVLayer(file$, img, size, #CSS_LightSeaGreen, #CSS_Orange, #CSS_RoyalBlue, #CSS_LightGray,
                     #CSS_Ivory))

   NewIcon(ToClipboard_Spatial(file$, img, size, #CSS_SandyBrown, #CSS_DarkSlateBlue, #CSS_Black, #CSS_White))
   NewIcon(FromClipboard_Spatial(file$, img, size, #CSS_SandyBrown, #CSS_DarkSlateBlue, #CSS_Black, #CSS_White))
   NewIcon(Copy_Spatial(file$, img, size, #CSS_DodgerBlue, #CSS_DarkGrey, #CSS_White))
   NewIcon(Paste_Spatial(file$, img, size, #CSS_DodgerBlue, #CSS_DarkGrey, #CSS_White, #CSS_SandyBrown,
                         #CSS_Black, #CSS_White))
   NewIcon(Cut_Spatial (file$, img.i, size.i, #VI_GrayBlue1, #CSS_White, #VI_GrayBlue2, #CSS_DarkGray,
                        #CSS_White, #CSS_Gray))
   NewIcon(Find_Spatial(file$, img, size, #CSS_DarkGray, #CSS_AliceBlue, #CSS_White, #CSS_PowderBlue, #False))
   NewIcon(FindNext_Spatial(file$, img, size, #CSS_DarkGray, #VI_WhiteBlue1, #CSS_White, #CSS_PowderBlue,
                            #CSS_ForestGreen, #False))
   NewIcon(FindAndReplace_Spatial(file$, img, size, #CSS_DarkGray, #VI_WhiteBlue1, #CSS_White,
                                  #CSS_PowderBlue, #CSS_Tan, #CSS3_LightGoldenrod, #CSS_OrangeRed,
                                  #CSS_BurlyWood, #CSS_DimGray, #True))
   NewIcon(ZoomIn_Spatial(file$, img, size, #CSS_DarkGray, #VI_WhiteBlue1, #CSS_White, #CSS_PowderBlue,
                          #CSS_CornflowerBlue, #False))
   NewIcon(ZoomOut_Spatial(file$, img, size, #CSS_DarkGray, #VI_WhiteBlue1, #CSS_White, #CSS_PowderBlue,
                           #CSS_CornflowerBlue, #False))

   NewIcon(NewDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey, #CSS_DodgerBlue))
   NewIcon(EditDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey, #CSS_Tan,
                                #CSS3_LightGoldenrod, #CSS_OrangeRed, #CSS_BurlyWood, #CSS_DimGray))
   NewIcon(ClearDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey, #CSS_DodgerBlue))
   NewIcon(ImportDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey, #CSS_DodgerBlue))
   NewIcon(ExportDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey, #CSS_DodgerBlue))
   NewIcon(SaveDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey, #CSS_DodgerBlue))
   NewIcon(CloseDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey, #CSS_OrangeRed))
   NewIcon(SortAscending_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey))
   NewIcon(SortDescending_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey))
   NewIcon(SortBlockAscending_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey))
   NewIcon(SortBlockDescending_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey))

   NewIcon(NewDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey,
                               #CSS_DodgerBlue, #True))
   NewIcon(EditDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey,
                                #CSS_Tan, #CSS3_LightGoldenrod,
                                #CSS_OrangeRed, #CSS_BurlyWood, #CSS_DimGray, #True))
   NewIcon(ClearDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey,
                                 #CSS_DodgerBlue, #True))
   NewIcon(ImportDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey,
                                  #CSS_DodgerBlue, #True))
   NewIcon(ExportDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey,
                                  #CSS_DodgerBlue, #True))
   NewIcon(SaveDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey,
                                #CSS_DodgerBlue, #True))
   NewIcon(CloseDocument_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey,
                                 #CSS_OrangeRed, #True))
   NewIcon(SortAscending_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey, #True))
   NewIcon(SortDescending_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey, #True))
   NewIcon(SortBlockAscending_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey, #True))
   NewIcon(SortBlockDescending_Spatial(file$, img, size, #CSS_White, #CSS_DodgerBlue, #CSS_DarkGrey, #True))

   NewIcon(Site_Spatial(file$, img, size, #CSS_Orange, #CSS_White))
   NewIcon(Compare_Spatial(file$, img, size, #CSS_Gold, #CSS_Black))


   ;--- Create gray ("disabled") icons
   NewIcon(FindAndReplace(file$, img, size, #CSS_DimGray, #CSS_Gray, #CSS_WhiteSmoke,
                          #CSS_Gray, #CSS_LightGray, #CSS_Gray))
   NewIcon(Open1_Spatial(file$, img, size, #CSS_Gainsboro, #CSS_WhiteSmoke))
   NewIcon(Open2_Spatial(file$, img, size, #CSS_Gainsboro, #CSS_WhiteSmoke, #CSS_Silver,
                         #CSS_WhiteSmoke))
   NewIcon(Open3_Spatial(file$, img, size, #CSS_Gainsboro, #CSS_WhiteSmoke))
   NewIcon(FindFile_Spatial(file$, img, size, #CSS_LightGray, #CSS_WhiteSmoke, #CSS_DimGray))
   NewIcon(FindFile(file$, img, size, #CSS_Silver, #CSS_DimGray))

   NewIcon(RotateDown_Spatial(file$, img, size, #CSS_DarkGray, #CSS_Gainsboro, #CSS_Silver))
   NewIcon(RotateUp_Spatial(file$, img, size, #CSS_DarkGray, #CSS_Gainsboro, #CSS_Silver))
   NewIcon(RotateVert_Spatial(file$, img, size, #CSS_DarkGray, #CSS_Silver))
   NewIcon(RotateLeft_Spatial(file$, img, size, #CSS_DarkGray, #CSS_Gainsboro, #CSS_Silver))
   NewIcon(RotateRight_Spatial(file$, img, size, #CSS_DarkGray, #CSS_Gainsboro, #CSS_Silver))
   NewIcon(RotateHor_Spatial(file$, img, size, #CSS_DarkGray, #CSS_Silver))
   NewIcon(RotateCCw_Spatial(file$, img, size, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(RotateCw_Spatial(file$, img, size, #CSS_LightGray, #CSS_DarkGray))

   NewIcon(Writingpad(file$, img, size, #CSS_WhiteSmoke, #CSS_Gray, #CSS_Black, #CSS_LightGray,
                      #CSS_WhiteSmoke, #CSS_Gray, #CSS_LightGray, #CSS_Gray))
   NewIcon(Writingpad_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Gray, #CSS_Black, #CSS_LightGray,
                              #CSS_WhiteSmoke, #CSS_DarkGray, #CSS_LightGray, #CSS_Gray))
   NewIcon(Calculate_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_DimGray, #CSS_WhiteSmoke, #CSS_LightGray))
   NewIcon(Calendar_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Black, #CSS_LightGray,
                            #CSS_DimGray))

   NewIcon(Ruler_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_DimGray))
   NewIcon(RulerTriangle_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_DimGray))

   NewIcon(Carton_Spatial(file$, img, size, #CSS_LightGray, #CSS_WhiteSmoke))
   NewIcon(BookKeeping_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_WhiteSmoke,
                               #CSS_LightGray, #CSS_DimGray, #CSS_WhiteSmoke))
   NewIcon(Pen_Spatial(file$, img, size, #CSS_LightGray, #CSS_WhiteSmoke, #CSS_DarkGray,
                       #CSS_LightGray, #CSS_Gray))
   NewIcon(Pen_Flat(file$, img, size, #CSS_LightGray, #CSS_WhiteSmoke, #CSS_DarkGray, #CSS_LightGray, #CSS_Gray))
   NewIcon(Brush_Spatial(file$, img, size, #CSS_LightGray, #CSS_WhiteSmoke, #CSS_Gray))
   NewIcon(Brush_Flat(file$, img, size, #CSS_LightGray, #CSS_WhiteSmoke, #CSS_DarkGray))
   NewIcon(Pipette_Spatial(file$, img, size, #CSS_Silver, #CSS_LightGray))
   NewIcon(Pipette_Flat(file$, img, size, #CSS_Gray, #CSS_LightGray, #CSS_Gray))
   NewIcon(Fill_Spatial(file$, img, size, #CSS_DarkGray, #CSS_LightGray, #CSS_LightGray))
   NewIcon(Fill_Flat(file$, img, size, #CSS_Silver, #CSS_LightGray))
   NewIcon(Spray_Spatial(file$, img, size, #CSS_Silver, #CSS_LightGray, #CSS_White, #CSS_Gray))
   NewIcon(Spray_Flat(file$, img, size, #CSS_DarkGray, #CSS_LightGray, #CSS_Gray, #CSS_Gray))
   NewIcon(Eraser_Spatial(file$, img, size, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(Eraser_Flat(file$, img, size, #CSS_DarkGray, #CSS_Gainsboro))
   NewIcon(ColorPalette_Spatial (file$, img, size, #CSS_LightGray, #CSS_Silver, #CSS_Silver,
                                 #CSS_Silver, #CSS_Silver, #CSS_Silver, #CSS_Silver))
   NewIcon(ColorPalette_Flat (file$, img, size, #CSS_LightGray, #CSS_DarkGray, #CSS_DarkGray,
                              #CSS_DarkGray, #CSS_DarkGray, #CSS_DarkGray, #CSS_DarkGray))
   NewIcon(Paint_Spatial (file$, img, size, #CSS_LightGray, #CSS_Silver, #CSS_LightGray,
                          #CSS_Gray, #CSS_Gray, #CSS_Gray, #CSS_Gray))
   NewIcon(Paint_Flat (file$, img, size, #CSS_Gray, #CSS_Silver, #CSS_LightGray, #CSS_Gray,
                       #CSS_Gray, #CSS_Gray, #CSS_Gray))

   NewIcon(DrawVText(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(DrawVLine(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(DrawVBox(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(DrawVRoundedBox(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(DrawVPolygonBox(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(DrawVCircle(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(DrawVCircleSegment(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(DrawVEllipse(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(DrawVEllipseSegment(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(DrawVCurve(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(DrawVArc(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(DrawVLinePath(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))

   NewIcon(SetVSelectionRange(file$, img, size, #CSS_Gray, #CSS_LightGray, #CSS_LightGray))
   NewIcon(SetVLineStyle(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVLineWidth(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVLineCap(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVLineJoin(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVColorSelect(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVColorBoardSelect(file$, img, size, #CSS_White, 0, #CSS_LightGray,
                                #CSS_LightGray, #CSS_Silver, #CSS_Silver, #CSS_Silver,
                                #CSS_Silver, #CSS_Silver))
   NewIcon(SetVFlipX(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVFlipY(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVRotate(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVMove(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVCopy(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVScale(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVTrimSegment(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVExtendSegment(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVCatchGrid(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray))
   NewIcon(SetVLinearGradient(file$, img, size, #CSS_White))
   NewIcon(SetVCircularGradient(file$, img, size, #CSS_White))
   NewIcon(SetVChangeCoord(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_Gray, #CSS_Gainsboro,
                           #CSS_LightGray))
   NewIcon(SetVDelete(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_Gray, #CSS_Gainsboro,
                      #CSS_LightGray))
   NewIcon(SetVFill(file$, img, size, #CSS_Gray, #CSS_Gray, #CSS_LightGray, #CSS_White,
                    #CSS_White))
   NewIcon(SetVLayer(file$, img, size, #CSS_DarkGray, #CSS_LightGray, #CSS_LightGray,
                     #CSS_LightGray))

   NewIcon(ToClipboard_Spatial(file$, img, size, #CSS_LightGrey, #CSS_Gray, #CSS_Gray, #CSS_White))
   NewIcon(FromClipboard_Spatial(file$, img, size, #CSS_LightGrey, #CSS_Gray, #CSS_Gray, #CSS_White))
   NewIcon(Copy_Spatial(file$, img, size, #CSS_Silver, #CSS_Gainsboro, #CSS_WhiteSmoke))
   NewIcon(Paste_Spatial(file$, img, size, #CSS_Silver, #CSS_Gainsboro, #CSS_WhiteSmoke,
                         #CSS_LightGrey, #CSS_Gray, #CSS_White))
   NewIcon(Cut_Spatial (file$, img.i, size.i, #CSS_Gainsboro, #CSS_White, #CSS_Gainsboro, #CSS_LightGrey,
                        #CSS_White, #CSS_Silver))
   NewIcon(Find_Spatial(file$, img, size, #CSS_White, #CSS_WhiteSmoke, #CSS_White, #CSS_White, #False))
   NewIcon(FindNext_Spatial(file$, img, size, #CSS_White, #CSS_WhiteSmoke, #CSS_White, #CSS_White,
                            #CSS_Silver, #False))
   NewIcon(FindAndReplace_Spatial(file$, img, size, #CSS_White, #CSS_WhiteSmoke, #CSS_White,
                                  #CSS_White, #CSS_LightGray, #CSS_WhiteSmoke, #CSS_DarkGray,
                                  #CSS_LightGray, #CSS_Gray, #True))
   NewIcon(ZoomIn_Spatial(file$, img, size, #CSS_White, #CSS_WhiteSmoke, #CSS_White,
                          #CSS_White, #CSS_Silver, #False))
   NewIcon(ZoomOut_Spatial(file$, img, size, #CSS_White, #CSS_WhiteSmoke, #CSS_White,
                           #CSS_White, #CSS_Silver, #False))

   NewIcon(NewDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #CSS_DarkGray))
   NewIcon(EditDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #CSS_LightGray,
                                #CSS_WhiteSmoke, #CSS_DarkGray, #CSS_LightGray, #CSS_Gray))
   NewIcon(ClearDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #CSS_DarkGray))
   NewIcon(ImportDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(ExportDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(SaveDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(CloseDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #CSS_WhiteSmoke))
   NewIcon(SortAscending_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver))
   NewIcon(SortDescending_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver))
   NewIcon(SortBlockAscending_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver))
   NewIcon(SortBlockDescending_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver))

   NewIcon(NewDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #CSS_DarkGray,
                               #True))
   NewIcon(EditDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #CSS_LightGray,
                                #CSS_WhiteSmoke, #CSS_DarkGray, #CSS_LightGray, #CSS_Gray, #True))
   NewIcon(ClearDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver,
                                 #CSS_DarkGray, #True))
   NewIcon(ImportDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver,
                                  #CSS_WhiteSmoke, #True))
   NewIcon(ExportDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver,
                                  #CSS_WhiteSmoke, #True))
   NewIcon(SaveDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver,
                                #CSS_WhiteSmoke, #True))
   NewIcon(CloseDocument_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver,
                                 #CSS_WhiteSmoke, #True))
   NewIcon(SortAscending_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #True))
   NewIcon(SortDescending_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #True))
   NewIcon(SortBlockAscending_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #True))
   NewIcon(SortBlockDescending_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver, #CSS_Silver, #True))

   NewIcon(Site_Spatial(file$, img, size, #CSS_Gainsboro, #CSS_White))
   NewIcon(Compare_Spatial(file$, img, size, #CSS_WhiteSmoke, #CSS_Silver))

   ProcedureReturn (img - start) / 2
EndProcedure


;{ Names of icons in set #3
DataSection
   FlagNames:
   Data.s "Flag_Australia", "Flag_Austria", "Flag_Bangladesh", "Flag_Belgium", "Flag_Brazil",
          "Flag_Bulgaria", "Flag_Canada", "Flag_China", "Flag_Czech", "Flag_Denmark",
          "Flag_Estonia", "Flag_Europe", "Flag_Finland", "Flag_France", "Flag_Germany",
          "Flag_GreatBritain", "Flag_Greece", "Flag_Hungary", "Flag_Ireland", "Flag_Island",
          "Flag_Italy", "Flag_Japan", "Flag_SouthKorea", "Flag_Luxembourg", "Flag_Netherlands",
          "Flag_NewZealand", "Flag_Norway", "Flag_Poland", "Flag_Romania", "Flag_Russia",
          "Flag_Spain", "Flag_Sweden", "Flag_Switzerland", "Flag_Ukraine", "Flag_USA"
EndDataSection
;}


Procedure.i CreateIcons03 (size.i, start.i, createSVG.i=#False)
   ; in : size     : width and height (number of pixels) of each icon
   ;      start    : number of first image created by this procedure
   ;      createSVG: #True / #False
   ; out: return value: number of different icons (not counting the "disabled" versions)
   Shared s_FileName$()
   Protected file$, img.i=start

   ;--- Create coloured ("enabled") icons
   NewIcon(Flag_Australia(file$, img, size, #CSS_DarkBlue, #CSS_WhiteSmoke, #CSS_Red))
   NewIcon(Flag_Austria(file$, img, size, #CSS_White, #Pantone_Red_032_C))
   NewIcon(Flag_Bangladesh (file$, img, size))
   NewIcon(Flag_Belgium(file$, img, size, #CSS_Black, #Pantone_114C, #Pantone_Red_032_C))
   NewIcon(Flag_Brazil(file$, img, size, #CSS_Green, #CSS_Yellow, #CSS_Blue))
   NewIcon(Flag_Bulgaria(file$, img, size, #CSS_Snow, #Pantone_17_5633, #Pantone_485C))
   NewIcon(Flag_Canada(file$, img, size, #CSS_White, #CSS_Red))
   NewIcon(Flag_China(file$, img, size, #Pantone_485C, #Pantone_YellowC))
   NewIcon(Flag_Czech(file$, img, size, #CSS_WhiteSmoke, #CSS3_Firebrick3, #Pantone_18_4434))
   NewIcon(Flag_Denmark(file$, img, size, #Pantone_186C, #CSS_WhiteSmoke))
   NewIcon(Flag_Estonia(file$, img, size))
   NewIcon(Flag_Europe(file$, img, size))
   NewIcon(Flag_Finland(file$, img, size, #CSS_Snow, #Pantone_294C))
   NewIcon(Flag_France(file$, img, size, #Pantone_ReflexBlueC, #CSS_WhiteSmoke, #Pantone_Red_032_C))
   NewIcon(Flag_Germany(file$, img, size, #CSS_Black, #CSS3_Red3, #Pantone_109C))
   NewIcon(Flag_GreatBritain(file$, img, size, #Pantone_280C, #CSS_WhiteSmoke, #Pantone_186C))
   NewIcon(Flag_Greece(file$, img, size, #CSS_Snow, #Pantone_18_4148))
   NewIcon(Flag_Hungary(file$, img, size, #Pantone_18_1660, #CSS_WhiteSmoke, #Pantone_18_6320))
   NewIcon(Flag_Ireland(file$, img, size, #Pantone_347C, #CSS_Snow, #Pantone_151C))
   NewIcon(Flag_Island(file$, img, size, #Pantone_661C, #CSS_WhiteSmoke, #Pantone_485C))
   NewIcon(Flag_Italy(file$, img, size, #CSS3_Springgreen4, #CSS_White, #Pantone_18_1662))
   NewIcon(Flag_Japan(file$, img, size, #CSS_WhiteSmoke, #Pantone_186C))
   NewIcon(Flag_KoreaSouth(file$, img, size, #CSS_WhiteSmoke, #Pantone_294C, #Pantone_186C,
                           #CSS_Black))
   NewIcon(Flag_Luxembourg(file$, img, size, #Pantone_Red_032_C, #CSS_Snow, #Pantone_299C))
   NewIcon(Flag_Netherlands(file$, img, size, #CSS_FireBrick, #CSS_WhiteSmoke, #CSS3_Royalblue4))
   NewIcon(Flag_NewZealand(file$, img, size, #Pantone_280C, #CSS_WhiteSmoke, #Pantone_186C))
   NewIcon(Flag_Norway(file$, img, size, #CSS3_Firebrick2, #CSS_WhiteSmoke, #CSS_RoyalBlue))
   NewIcon(Flag_Poland(file$, img, size, #CSS_Snow, #CSS_Crimson))
   NewIcon(Flag_Romania(file$, img, size, #Pantone_280C, #Pantone_116C, #Pantone_186C))
   NewIcon(Flag_Russia(file$, img, size, #CSS_WhiteSmoke, #Pantone_286C, #Pantone_485C))
   NewIcon(Flag_Spain (file$, img.i, size))
   NewIcon(Flag_Sweden(file$, img, size, #Pantone_3015C, #Pantone_116C))
   NewIcon(Flag_Switzerland(file$, img, size, #CSS_Red, #CSS_WhiteSmoke))
   NewIcon(Flag_Ukraine(file$, img, size, #Pantone_2935C, #Pantone_YellowC))
   NewIcon(Flag_USA(file$, img, size, #CSS_WhiteSmoke, #Pantone_1805C, #Pantone_19_3832))


   ;--- Create gray ("disabled") icons
   NewIcon(Flag_Australia(file$, img, size, #CSS_DimGray, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Austria(file$, img, size, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Bangladesh (file$, img, size, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Belgium(file$, img, size, #CSS_Gray, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Brazil(file$, img, size, #CSS_DarkGray, #CSS_LightGray, #CSS_DimGrey))
   NewIcon(Flag_Bulgaria(file$, img, size, #CSS_LightGray, #CSS_Gray, #CSS_DarkGray))
   NewIcon(Flag_Canada(file$, img, size, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_China(file$, img, size, #CSS_DarkGray, #CSS_LightGray))
   NewIcon(Flag_Czech(file$, img, size, #CSS_LightGray, #CSS_DarkGray, #CSS_Gray))
   NewIcon(Flag_Denmark(file$, img, size, #CSS_DarkGray, #CSS_LightGray))
   NewIcon(Flag_Estonia(file$, img, size, #CSS_DarkGray, #CSS_DimGray, #CSS_LightGray))
   NewIcon(Flag_Europe(file$, img, size, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Finland(file$, img, size, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_France(file$, img, size, #CSS_Gray, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Germany(file$, img, size, #CSS_DimGray, #CSS_DarkGray, #CSS_LightGray))
   NewIcon(Flag_GreatBritain(file$, img, size, #CSS_DimGray, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Greece(file$, img, size, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Hungary(file$, img, size, #CSS_DarkGray, #CSS_LightGray, #CSS_Gray))
   NewIcon(Flag_Ireland(file$, img, size, #CSS_Gray, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Island(file$, img, size, #CSS_Gray, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Italy(file$, img, size, #CSS_Gray, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Japan(file$, img, size, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_KoreaSouth(file$, img, size, #CSS_LightGray, #CSS_Gray, #CSS_DarkGray,
                           #CSS_Gray))
   NewIcon(Flag_Luxembourg(file$, img, size, #CSS_DarkGray, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Netherlands(file$, img, size, #CSS_DarkGray, #CSS_LightGray, #CSS_Gray))
   NewIcon(Flag_NewZealand(file$, img, size, #CSS_DimGray, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Norway(file$, img, size, #CSS_DarkGray, #CSS_LightGray, #CSS_Gray))
   NewIcon(Flag_Poland(file$, img, size, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Romania(file$, img, size, #CSS_Gray, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Russia(file$, img, size, #CSS_LightGray, #CSS_Gray, #CSS_DarkGray))
   NewIcon(Flag_Spain (file$, img.i, size, #CSS_LightGray, #CSS_DarkGray))
   NewIcon(Flag_Sweden(file$, img, size, #CSS_DarkGray, #CSS_LightGray))
   NewIcon(Flag_Switzerland(file$, img, size, #CSS_DarkGray, #CSS_LightGray))
   NewIcon(Flag_Ukraine(file$, img, size, #CSS_DarkGray, #CSS_LightGray))
   NewIcon(Flag_USA(file$, img, size, #CSS_LightGray, #CSS_DarkGray, #CSS_Gray))

   ProcedureReturn (img - start) / 2
EndProcedure


Procedure.s ChoosePath (path$, targetDir$)
   ; in : path$     : initial path to use when the PathRequester is opened
   ;      targetDir$: name of target directory in the choosen path
   ; out: return value: chosen path$ + targetDir$,
   ;                    or "" on error

   path$ = PathRequester("Choose path where to create directory '" + targetDir$ + "'.",
                         path$)
   If path$ <> ""
      path$ + targetDir$

      If FileSize(path$) = -2
         If MessageRequester("Warning", ~"Directory already exists:\n" +
                                        path$ + ~"\n\n" +
                                        "Proceed anyway?",
                             #PB_MessageRequester_YesNo) = #PB_MessageRequester_No
            path$ = ""
         EndIf
      ElseIf CreateDirectory(path$) = 0
         MessageRequester("Error", ~"Can't create directory\n" +
                                   path$)
         path$ = ""
      EndIf
   EndIf

   ProcedureReturn path$
EndProcedure


Procedure.i SaveAllSVG (path$, size.i, *iconSet.IconsetStruc)
   ; -- save all icons of the given set to individual SVG files
   ;    (in the size in that they are currently displayed)
   ; in : path$   : path where to create a directory for the current icon set
   ;      size    : width and height (number of pixels) of each icon
   ;      *iconSet: properties of the current icon set
   ;      s_FileName$(): list of basic file names for all icons
   ; out: return value: number of saved SVG files
   Shared s_FileName$()
   Protected dir$, *name, CreateIcons.protoCreateIcons

   dir$ = path$ + #PS$ + *iconSet\name$
   CreateDirectory    (dir$)
   SetCurrentDirectory(dir$)

   *name = GetGadgetData(*iconSet\firstIcon)
   ChangeCurrentElement(s_FileName$(), *name)
   CreateIcons = *iconSet\procAddr
   CreateIcons(size, 0, #True)

   ProcedureReturn 2 * *iconSet\numIcons
EndProcedure


Procedure.i SaveAllPNG (path$, *iconSet.IconsetStruc)
   ; -- save all icons of the given set to individual PNG files
   ;    (in the size in that they are currently displayed)
   ; in : path$        : path where to create a directory for the current icon set
   ;      *iconSet     : properties of the current icon set
   ;      s_FileName$(): list of basic file names for all icons
   ; out: return value: number of saved PNG files
   Shared s_FileName$()
   Protected dir$, *name, lastIcon.i, img.i, notSaved.i=0

   dir$ = path$ + #PS$ + *iconSet\name$
   CreateDirectory    (dir$)
   SetCurrentDirectory(dir$)

   *name = GetGadgetData(*iconSet\firstIcon)
   ChangeCurrentElement(s_FileName$(), *name)
   lastIcon = *iconSet\firstIcon + 2 * *iconSet\numIcons - 1

   For img = *iconSet\firstIcon To lastIcon
      If SaveImage(img, s_FileName$() + ".png", #PB_ImagePlugin_PNG) = 0
         notSaved + 1
         Debug "Can't save image '" + s_FileName$() + ".png'"
      EndIf
      NextElement(s_FileName$())
   Next

   ProcedureReturn 2 * *iconSet\numIcons - notSaved
EndProcedure


Procedure.s SaveOnePNG (path$, img.i, size.i)
   ; -- save one icon to a PNG file
   ; in : path$        : initial path to use when the SaveFileRequester is opened
   ;      img          : number of image that is to be saved
   ;      size         : width and height (number of pixels) of the icon
   ;      s_FileName$(): list of basic file names for all icons
   ; out: return value: old or new path$
   Shared s_FileName$()
   Protected *name, file$

   *name = GetGadgetData(img)
   If *name
      ChangeCurrentElement(s_FileName$(), *name)
      file$ = SaveFileRequester("", path$ + s_FileName$() + "_" + size + ".png",
                                "PNG files (*.png)|*.png|All files (*.*)|*.*", 0)
      If file$ <> ""
         If SaveImage(img, file$, #PB_ImagePlugin_PNG) = 0
            Debug "Can't save image '" + file$ + "'"
         EndIf
         path$ = GetPathPart(file$)
      EndIf
   EndIf

   ProcedureReturn path$
EndProcedure


Macro CalcCol (_no_, _first_, _columns_)
   ((_no_ - _first_) % _columns_)
EndMacro

Macro CalcRow (_no_, _first_, _columns_)
   (2 * Int((_no_ - _first_) / _columns_))
EndMacro


Macro PosX (_c_, _size_)
   ((_c_) * (_size_ + 20) + 10)
EndMacro

Macro PosY (_r_, _size_)
   ((_r_) * (_size_ + 20) + 10)
EndMacro


Procedure.i SaveOneTab (path$, size.i, columns.i, *iconSet.IconsetStruc)
   ; -- create *one* PNG file that shows all icons of the given set
   ;    (e.g. For uploading to the PureBasic forum)
   ; in : path$   : path where to save the PNG file
   ;      size    : width and height (number of pixels) of each icon
   ;      columns : number of icons per row
   ;      *iconSet: properties of the current icon set
   ; out: return value: 1 on success, 0 on error
   Protected.i img, img_d, row, col, x, y, lastIcon, rows, pic, ret
   Protected file$

   rows = 2 * Round(*iconSet\numIcons / columns, #PB_Round_Up)
   pic = CreateImage(#PB_Any, columns * (size+20), rows * (size+20), 32, $F0F0F0)

   If pic = 0
      MessageRequester("Error", "Can't create image.")
      ProcedureReturn 0
   EndIf

   If StartDrawing(ImageOutput(pic)) = 0
      MessageRequester("Error", "Can't start drawing.")
      FreeImage(pic)
      ProcedureReturn 0
   EndIf

   lastIcon = *iconSet\firstIcon + *iconSet\numIcons - 1

   DrawingMode(#PB_2DDrawing_AlphaBlend)
   For img = *iconSet\firstIcon To lastIcon
      col = CalcCol(img, *iconSet\firstIcon, columns)
      row = CalcRow(img, *iconSet\firstIcon, columns)
      x = PosX(col, size)

      ; "enabled"
      If IsImage(img)
         y = PosY(row, size)
         DrawImage(ImageID(img), x, y)
      EndIf

      ; "disabled"
      img_d = img + *iconSet\numIcons
      If IsImage(img_d)
         y = PosY(row + 1, size)
         DrawImage(ImageID(img_d), x, y)
      EndIf
   Next
   StopDrawing()

   file$ = path$ + #PS$ + *iconSet\name$ + ".png"
   ret = SaveImage(pic, file$, #PB_ImagePlugin_PNG)
   FreeImage(pic)

   ProcedureReturn Bool(ret <> 0)
EndProcedure


Procedure ResizeIcons (scrollArea.i, size.i, columns.i, *iconSet.IconsetStruc)
   ; -- resize all icons of one iconset
   ; in : scrollArea: number of the ScrollAreaGadget that contains the icons
   ;      size      : new width and height (number of pixels) of each icon
   ;      columns   : number of icons per row
   ;      *iconSet  : properties of the current icon set
   Protected.i img, img_d, row, col, x, y, lastIcon, lastIcon_d, rows
   Protected CreateIcons.protoCreateIcons

   lastIcon   = *iconSet\firstIcon + *iconSet\numIcons - 1
   lastIcon_d = lastIcon + *iconSet\numIcons

   For img = *iconSet\firstIcon To lastIcon_d
      FreeImage(img)
   Next

   CreateIcons = *iconSet\procAddr
   CreateIcons(size, *iconSet\firstIcon)

   For img = *iconSet\firstIcon To lastIcon
      col = CalcCol(img, *iconSet\firstIcon, columns)
      row = CalcRow(img, *iconSet\firstIcon, columns)
      x = PosX(col, size)

      ; "enabled"
      y = PosY(row, size)
      ResizeGadget(img, x, y, size, size)
      SetGadgetState(img, ImageID(img))

      ; "disabled"
      img_d = img + *iconSet\numIcons
      y = PosY(row + 1, size)
      ResizeGadget(img_d, x, y, size, size)
      SetGadgetState(img_d, ImageID(img_d))
   Next

   rows = 2 * Round(*iconSet\numIcons / columns, #PB_Round_Up)
   SetGadgetAttribute(scrollArea, #PB_ScrollArea_InnerWidth,  columns * (size+20))
   SetGadgetAttribute(scrollArea, #PB_ScrollArea_InnerHeight, rows    * (size+20))
EndProcedure


Macro AttachFilename (_img_, _name_, _list_, _tail_="")
   SetGadgetData(_img_, AddElement(_list_))
   _list_ = LCase(_name_) + _tail_
   ReplaceString(_list_, "/", "_", #PB_String_InPlace)
EndMacro

Procedure.i DrawIcons (scrollArea.i, size.i, columns.i, *iconSet.IconsetStruc)
   ; -- create and display one iconset (with tooltips)
   ; in : scrollArea: number of the ScrollAreaGadget that contains the icons
   ;      size      : width and height (number of pixels) of each icon
   ;      columns   : number of icons per row
   ;      *iconSet  : properties of the current icon set
   ; out: *iconSet     : updated properties of the current icon set
   ;      s_FileName$(): list of basic file names for all icons
   ;      return value : number of last icon in this set
   Shared s_FileName$()
   Protected.i img, row, col, x, y, lastIcon, lastIcon_d, rows
   Protected name$, CreateIcons.protoCreateIcons

   CreateIcons = *iconSet\procAddr
   *iconSet\numIcons = CreateIcons(size, *iconSet\firstIcon)
   lastIcon = *iconSet\firstIcon + *iconSet\numIcons - 1

   OpenGadgetList(scrollArea)

   ; "enabled" icons
   RestoreDataPtr(*iconSet\label)
   For img = *iconSet\firstIcon To lastIcon
      Read.s name$

      If IsImage(img)
         col = CalcCol(img, *iconSet\firstIcon, columns)
         row = CalcRow(img, *iconSet\firstIcon, columns)
         x = PosX(col, size)
         y = PosY(row, size)

         ImageGadget(img, x, y, size, size, ImageID(img))
         GadgetToolTip(img, name$)
         AttachFilename(img, name$, s_FileName$())
      Else
         Debug "Can't create coloured icon #" + img + "."
      EndIf
   Next

   ; "disabled" icons
   lastIcon_d = lastIcon + *iconSet\numIcons
   RestoreDataPtr(*iconSet\label)
   For img = lastIcon + 1 To lastIcon_d
      Read.s name$

      If IsImage(img)
         col = CalcCol(img - *iconSet\numIcons, *iconSet\firstIcon, columns)
         row = CalcRow(img - *iconSet\numIcons, *iconSet\firstIcon, columns)
         x = PosX(col, size)
         y = PosY(row + 1, size)

         ImageGadget(img, x, y, size, size, ImageID(img))
         GadgetToolTip(img, name$)
         AttachFilename(img, name$, s_FileName$(), "_d")
      Else
         Debug "Can't create gray icon #" + img + "."
      EndIf
   Next

   CloseGadgetList()

   rows = 2 * Round(*iconSet\numIcons / columns, #PB_Round_Up)
   SetGadgetAttribute(scrollArea, #PB_ScrollArea_InnerWidth,  columns * (size+20))
   SetGadgetAttribute(scrollArea, #PB_ScrollArea_InnerHeight, rows    * (size+20))

   ProcedureReturn lastIcon_d
EndProcedure


; * Named constants for this program *

CompilerIf #PB_Compiler_Unicode
   #XmlEncoding = #PB_Unicode
CompilerElse
   #XmlEncoding = #PB_Ascii
CompilerEndIf

#WinMain = 0
#XML = 0
#Dialog = 0
#ToolbarIconSize = 24

; Toolbar images
Enumeration
   #Img_ZoomOut
   #Img_ZoomOut_d
   #Img_ZoomIn
EndEnumeration
#Img_Next = #PB_Compiler_EnumerationValue

; Gadget numbers for use with OpenXMLDialog()
Runtime Enumeration
   #Gad_ZoomOut
   #Gad_ZoomIn
   #Gad_Scroll0
   #Gad_Scroll1
   #Gad_Scroll2
   #Btn_SaveAllSVG
   #Btn_SaveAllPNG
   #Btn_SaveTabs
   #Btn_Exit
EndEnumeration
#Gad_Next = #PB_Compiler_EnumerationValue

CompilerIf #Img_Next > #Gad_Next
   #Icon_EnumerationStart = #Img_Next
CompilerElse
   #Icon_EnumerationStart = #Gad_Next
CompilerEndIf


Procedure ProcessEvents (size.i, columns.i, Array iconSet.IconsetStruc(1))
   ; in: size     : width and height (number of pixels) of each icon
   ;     columns  : number of icons per row in the preview window
   ;     iconSet(): array with properties of all icon sets
   Protected path$, p$, evGadget.i, zoomOutDisabled.i=#False
   Protected.i count0, count1, count2, tabs

   If size <= 16
      size = 16
      zoomOutDisabled = #True
      SetGadgetState(#Gad_ZoomOut, ImageID(#Img_ZoomOut_d))
   EndIf

   path$ = GetUserDirectory(#PB_Directory_Desktop)
   If Right(path$, 1) <> #PS$   ; e.g. PB 5.62 (x64) on Linux Mint 18.3
      path$ + #PS$
   EndIf

   Repeat
      Select WaitWindowEvent()
         Case #PB_Event_Gadget
            evGadget = EventGadget()

            Select evGadget
               Case #Gad_ZoomIn, #Gad_ZoomOut
                  If EventType() = #PB_EventType_LeftClick
                     If evGadget = #Gad_ZoomIn
                        If size = 16
                           zoomOutDisabled = #False
                           SetGadgetState(#Gad_ZoomOut, ImageID(#Img_ZoomOut))
                        EndIf
                        size + 8
                     ElseIf zoomOutDisabled = #False
                        size - 8
                        If size <= 16
                           size = 16
                           zoomOutDisabled = #True
                           SetGadgetState(#Gad_ZoomOut, ImageID(#Img_ZoomOut_d))
                        EndIf
                     Else
                        Continue
                     EndIf

                     HideGadget(#Gad_Scroll0, #True)
                     HideGadget(#Gad_Scroll1, #True)
                     HideGadget(#Gad_Scroll2, #True)

                     ResizeIcons(#Gad_Scroll0, size, columns, iconSet(0))
                     ResizeIcons(#Gad_Scroll1, size, columns, iconSet(1))
                     ResizeIcons(#Gad_Scroll2, size, columns, iconSet(2))

                     HideGadget(#Gad_Scroll0, #False)
                     HideGadget(#Gad_Scroll1, #False)
                     HideGadget(#Gad_Scroll2, #False)

                     RefreshDialog(#Dialog)
                     SetWindowTitle(#WinMain, "VectorIcons (" + size + "x" + size + ")")
                  EndIf

               CompilerIf #PB_Compiler_OS = #PB_OS_Linux
               Case #Btn_SaveAllSVG
                  ; -- save all icons from all sets to individual SVG files
                  p$ = ChoosePath(path$, "vectoricons_svg")
                  If p$ <> ""
                     count0 = SaveAllSVG(p$, size, iconSet(0))
                     count1 = SaveAllSVG(p$, size, iconSet(1))
                     count2 = SaveAllSVG(p$, size, iconSet(2))

                     MessageRequester("Done", Str(count0) + "+" + count1 + "+" + count2 +
                                              " = " + Str(count0 + count1 + count2) +
                                              ~" SVG images saved to directory\n" +
                                              p$)
                     path$ = GetPathPart(p$)
                  EndIf
               CompilerEndIf

               Case #Btn_SaveAllPNG
                  ; -- save all icons from all sets to individual PNG files
                  p$ = ChoosePath(path$, "vectoricons_png_" + size)
                  If p$ <> ""
                     count0 = SaveAllPNG(p$, iconSet(0))
                     count1 = SaveAllPNG(p$, iconSet(1))
                     count2 = SaveAllPNG(p$, iconSet(2))

                     MessageRequester("Done", Str(count0) + "+" + count1 + "+" + count2 +
                                              " = " + Str(count0 + count1 + count2) +
                                              ~" PNG images saved to directory\n" +
                                              p$)
                     path$ = GetPathPart(p$)
                  EndIf

               Case #Btn_SaveTabs
                  ; -- for each set, save an overview picture with all its icons
                  p$ = ChoosePath(path$, "vectoricons_tabs_" + size)
                  If p$ <> ""
                     tabs = SaveOneTab(p$, size, columns, iconSet(0))
                     tabs + SaveOneTab(p$, size, columns, iconSet(1))
                     tabs + SaveOneTab(p$, size, columns, iconSet(2))

                     MessageRequester("Done", Str(tabs) + " overview pictures " +
                                              ~"saved to directory\n" + p$)
                     path$ = GetPathPart(p$)
                  EndIf

               Case #Btn_Exit
                  Break

               Default
                  If evGadget >= #Icon_EnumerationStart And EventType() = #PB_EventType_RightClick
                     path$ = SaveOnePNG(path$, evGadget, size)
                  EndIf
            EndSelect

         Case #PB_Event_CloseWindow
            Break
      EndSelect
   ForEver
EndProcedure


Procedure BrowseIcons (size.i, columns.i=15, minWidth.i=720, minHeight.i=640)
   ; * Main procedure *
   ; in: size     : width and height (number of pixels) of each icon
   ;     columns  : number of icons per row in the preview window
   ;     minWidth : minimal width  of the preview window
   ;     minHeight: minimal height of the preview window
   Protected xml$, lastIcon.i
   Protected Dim iconSet.IconsetStruc(2)

   ; Basic properties of the icon sets
   iconSet(0)\name$ = "IconSet_1"
   iconSet(0)\label = ?IconNames01
   iconSet(0)\procAddr = @ CreateIcons01()

   iconSet(1)\name$ = "IconSet_2"
   iconSet(1)\label = ?IconNames02
   iconSet(1)\procAddr = @ CreateIcons02()

   iconSet(2)\name$ = "Flags"
   iconSet(2)\label = ?FlagNames
   iconSet(2)\procAddr = @ CreateIcons03()

   xml$ = "<window id='" + #WinMain + "' text='VectorIcons (" + size + "x" + size + ")' " +
          "minwidth='" + minWidth + "' minheight='" + minHeight + "' " +
          "flags='#PB_Window_ScreenCentered|#PB_Window_SizeGadget|" +
          "#PB_Window_MaximizeGadget|#PB_Window_MinimizeGadget'>" +
          "   <vbox expand='item:2'>" +
          "      <hbox height='" + Str(#ToolbarIconSize+10) + "' spacing='10' expand='no'>" +
          "         <image id='#Gad_ZoomOut' width='" + #ToolbarIconSize + "'/>" +
          "         <image id='#Gad_ZoomIn'  width='" + #ToolbarIconSize + "'/>" +
          "      </hbox>"

   xml$ + "      <panel>" +
          "         <tab text='" + iconSet(0)\name$ + "' margin='0'>" +
          "            <scrollarea id='#Gad_Scroll0'>" +
          "            </scrollarea>" +
          "         </tab>" +
          "         <tab text='" + iconSet(1)\name$ + "' margin='0'>" +
          "            <scrollarea id='#Gad_Scroll1'>" +
          "            </scrollarea>" +
          "         </tab>" +
          "         <tab text='" + iconSet(2)\name$ + "' margin='0'>" +
          "            <scrollarea id='#Gad_Scroll2'>" +
          "            </scrollarea>" +
          "         </tab>" +
          "      </panel>"

   xml$ + "      <hbox spacing='10' expand='item:2'>" +
          "         <text text='Right click at an icon to save it.'/>" +
          "         <empty/>" +
          "         <button id='#Btn_SaveAllSVG' text='Save all to SVG'/>" +
          "         <button id='#Btn_SaveAllPNG' text='Save all to PNG'/>" +
          "         <button id='#Btn_SaveTabs'   text='Save overview pictures'/>" +
          "         <button id='#Btn_Exit'       text='Exit' width='60'/>" +
          "      </hbox>" +
          "   </vbox>" +
          "</window>"

   If CatchXML(#Xml, @ xml$, StringByteLength(xml$), 0, #XmlEncoding) = 0 Or
      XMLStatus(#Xml) <> #PB_XML_Success
      MessageRequester("Fatal error", XMLError(#XML))
      End
   EndIf

   If CreateDialog(#Dialog) = 0 Or OpenXMLDialog(#Dialog, #XML, "") = 0
      MessageRequester("Fatal error", DialogError(#Dialog))
      End
   EndIf

   ; Toolbar images
   ZoomOut("", #Img_ZoomOut,   #ToolbarIconSize, #CSS_Black)
   ZoomOut("", #Img_ZoomOut_d, #ToolbarIconSize, #CSS_Silver)
   ZoomIn ("", #Img_ZoomIn,    #ToolbarIconSize, #CSS_Black)

   SetGadgetState(#Gad_ZoomOut, ImageID(#Img_ZoomOut))
   SetGadgetState(#Gad_ZoomIn , ImageID(#Img_ZoomIn))

   ; Gadget tooltips
   GadgetToolTip(#Gad_ZoomOut, "Zoom out")
   GadgetToolTip(#Gad_ZoomIn,  "Zoom in")

   CompilerIf #PB_Compiler_OS = #PB_OS_Linux
      GadgetToolTip(#Btn_SaveAllSVG, "Save all icons to individual SVG files")
   CompilerElse
      HideGadget(#Btn_SaveAllSVG, #True)
   CompilerEndIf

   GadgetToolTip(#Btn_SaveAllPNG, "Save all icons to individual PNG files")
   GadgetToolTip(#Btn_SaveTabs, "Save the content of each tab to a PNG file")

   ; Icons
   HideGadget(#Gad_Scroll0, #True)

   iconSet(0)\firstIcon = #Icon_EnumerationStart
   lastIcon = DrawIcons(#Gad_Scroll0, size, columns, iconSet(0))

   iconSet(1)\firstIcon = lastIcon + 1
   lastIcon = DrawIcons(#Gad_Scroll1, size, columns, iconSet(1))

   iconSet(2)\firstIcon = lastIcon + 1
   lastIcon = DrawIcons(#Gad_Scroll2, size, columns, iconSet(2))

   HideGadget(#Gad_Scroll0, #False)

   ProcessEvents(size, columns, iconSet())
EndProcedure


CompilerIf #PB_Compiler_IsMainFile

   BrowseIcons(24)    ; For parameters 'columns', 'minWidth', and 'minHeight',
                      ; the default values are used.

   ; If you want to use your own parameters, and don't want to edit this file each
   ; time it is updated, create your own main file say named "myvectoriconbrowser.pb".
   ; The contents of that file could be for instance:
   ;
   ; XIncludeFile "vectoriconbrowser.pb"
   ; BrowseIcons(48, 10, 740, 600)
CompilerEndIf

; IDE Options = PureBasic 6.10 beta 3 (Windows - x64)
; Folding = -----
; Optimizer
; EnableThread
; EnableXP
; DllProtection
; Executable = vectoriconbrowser.exe
; EnableExeConstant
; EnableUnicode