;--
;- PanelEx
;--

;--===============
;- **** declarations
;--===============
Declare updatePanelExPageScrollbars(*panelexpage)
Declare handlePanelExPageAutoScroll(*panelexpage)
Declare PanelExPageCallback(Window, message, wParam, lParam)
DeclareDLL FreePanelEx(id.i)
DeclareDLL RefreshPanelEx(Panel.i, *updateRect.RECT = #Null, flags.l = #Null)
DeclareDLL SetPanelExPageAlpha(Panel.i, Page.i, Alpha.c, noRefresh.b)
Declare getRootPanelExPageHwnd(hwnd, *trackWin = #Null)
Declare getRootPanelExHwnd(hwnd, *trackWin = #Null)
DeclareDLL GetPanelExDC(Panel.i)
DeclareDLL ShowPanelExPage(Panel, index)
DeclareDLL PanelExID(Panel, index)
Declare updatePanelexChildren(*panelex)
Declare updatePanelexChildren2(*panelex, dc)
Declare drawPanelPage(*panelexpage, dc, Window, divertedWindow, inAlpha)
Declare updateTrackWinRootPanelEx(*trackWin, *rootTrackWin = #Null, *parentPanelEx = #Null)

;- PanelEx Structures
;-
Structure panelexpages
    
    Handle.i          ; page hwnd
    containerHandle.i ; parent container window (panelex hwnd)
    *panelex          ; address of parent panelex container
    
    background.i
    backgroundImg.i
    width.l
    height.l
    imageX.l
    imageY.l
    imageWidth.l
    imageHeight.l
    style.l
    
    cursor.i ; pointer to mouse cursor for page
    
    ; Scrolling
    hScrollBar.i          ; handle to horizontal scrollbar window
    *hScrollBarTrackWin   ; pointer to horizontal scrollbar trackWin
    hScrollVisible.l      ; true or false
    vScrollBar.i          ; handle to vertical scroll bar window
    *vScrollbarTrackWin   ; pointer to vertical scrollbar trackWin
    vScrollVisible.l      ; true or false
    scrollBarBox.i        ; handle to scrollbarBox window - empty space inbetween 2 scrollbars
    *scrollBarBoxTrackWin ; pointer to scrollBarBox trackwin
    autoScroll.l          ; auto scrolling enabled, true or false
    noHorizontal.l        ; no autoscroll horizontal bar, true or false
    noVertical.l          ; no autoscroll vertical bar, true or false
    scrollbarsOutside.l   ; makes so content is squeezed inside scrollbars, true or false
    autoScrollPosMode.l   ; used for positioning new child windows, can be actual pos or virtual pos
    lastHscrollPos.l      ; used for keeping track of horizontal scroll position
    lastVscrollPos.l      ; used for keeping track of vertical scroll position
    lastHscrollMax.l      ; used for keeping track of horizontal scroll max value
    lastVscrollMax.l      ; used for keeping track of vertical scroll max value
    hScrollLineAmount.l   ; value used to scroll a single line horizontally in pixels
    vScrollLineAmount.l   ; value used to scroll a single line vertically in pixels
    area.RECT             ; stores the minimum bounding rect of all child windows, i.e the virtual canvas size
    lastAreaPos.RECT      ; stores the last virtual canvas position and size
    lastHScrollRect.RECT  ; stores last client rect since horizontal scollbar was positioned
    lastVScrollRect.RECT  ; stores last client rect since horizontal scollbar was positioned
    renderScrollbars.b    ; flagged to true if scrollbars need rendering
    
    calcArea.b ; flagged to true if page area needs re-calculating
    
    ; Overlay Background
    background2.i
    backgroundImg2.i
    imageX2.l
    imageY2.l
    imageWidth2.l
    imageHeight2.l
    style2.l
    
    ; border
    borderHandle.i
    
    ; page alpha transparency, 0 - 255
    alpha.c
    
    dontdraw.b  ; used for drawing a panelex inside a panelex
    
    *trackWin ; stores pointer to window trackWin structure
    
EndStructure

Structure invalidateChild
    
    hwnd.i
    rc.RECT
    mode.b ; mode = 0: invalidate, mode = 1: redraw invalidate, all children
    
EndStructure

Structure panelexs
    
    id.l
    Handle.i
    width.l
    height.l
    displayedPage.i
    usercallback.i
    
    ;background buffer
    backgroundDC.i
    backgroundBitmap.i
    backgroundWidth.l
    backgroundHeight.l
    
    ;alpha buffer
    alphaDC.i
    alphaBitmap.i
    alphaWidth.l
    alphaHeight.l
    
    *trackWin ; stores pointer to window trackWin structure
    
    lastClientRc.RECT ; stores the last panelex client rect dimensions
    
    setRedrawFalse.b  ; flagged to true if a WM_SETREDAW false message has been passed to panelex or SetPanelExRedraw = false, disables rendering
    animRedrawFalse.b ; flagged to true if animation is currently playing and frame isn't ready for rendering, disables refresh (will be batched until next frame)
    
    updateRgn.i          ; stores handle to current root panelex update region
    updateCount.i        ; root PanelEx increments (max 1) each time a RefreshPanelEx call is made outside of render thread while animating, decrements each time frame is rendered, when zero update region is discarded and new created on next call to RefreshPanelEx. This is so the current update region is kept alive for refeshes outside of rendered frame.
    List updateRc.RECT() ; stores list of current root panelex update region rects
    List updateChild.invalidateChild() ; keeps list of all root panelex none progui controls that need invalidating/redrawing
    rendering.b
    updating.b
    
    destroying.b ; flagged to true if received WM_DESTROY
    
    insideRefresh.b ; flagged to true in root panelex while inside RefreshPanelEx, stops RefreshPanelEx from executing if already in middle of RefreshPanelEx with same root
    
    List page.panelexpages()
    
EndStructure

;- PanelEx Globals
;-
Global panelExContainerClass.s
Global panelExPageClass.s
Global panelExPBCallback.i
Global panelExPageInsert.l  ; used for flaging whether an addPanelExPage should add or insert new page, panelExPageInsert being a handle to the panelexpage element to insert before

Global scrollbarBoxClass.s ; class for empty space inbetween 2 scrollbars

Global scrollbarsHook
Global scrollbarsHwnd

#CSCROLLBAR_nIDEvent = 53475

EnumerationBinary
    #CSCROLLBAR_VTRACK      ; private
    #CSCROLLBAR_HTRACK      ; private
    #CSCROLLBAR_UP          ; private
    #CSCROLLBAR_DOWN        ; private
    #CSCROLLBAR_LEFT        ; private
    #CSCROLLBAR_RIGHT       ; private
    #CSCROLLBAR_PAGEUP      ; private
    #CSCROLLBAR_PAGEDOWN    ; private
    #CSCROLLBAR_PAGELEFT    ; private
    #CSCROLLBAR_PAGERIGHT   ; private
    #CSCROLLBAR_PRESSED     ; private
EndEnumeration

;- init panelex themes/borders/masks
Procedure initPanelexThemes()
    Static createdPanelExThemes
    
    If createdPanelExThemes = #False And ThemesEnabled = #True
        
        ;/ initialize panelex default theme background border masks
        themeButtonBorderImage = CreateImage(#PB_Any, 100, 100, 32)
        ; system button normal state border background mask
        hdc = StartDrawing(ImageOutput(themeButtonBorderImage))
        DrawingMode(#PB_2DDrawing_AllChannels)
        Box(0, 0, 100, 100, RGBA(255, 255, 255, 0))
        rc.RECT
        rc\right = 100
        rc\bottom = 100
        If ThemesEnabled = #True
            CallFunctionFast(*DrawThemeBackground, hThemeButton, hdc, 1, 0, @rc, 0)
        EndIf
        StopDrawing()
        Global themeButtonBorder = createBorder()
        setBorder(themeButtonBorder, ImageID(themeButtonBorderImage), -2, 0, 0)
        FreeImage(themeButtonBorderImage)
        
        ; system button hot state border background mask
        themeButtonBorderHotImage = CreateImage(#PB_Any, 100, 100, 32)
        hdc = StartDrawing(ImageOutput(themeButtonBorderHotImage))
        DrawingMode(#PB_2DDrawing_AllChannels)
        Box(0, 0, 100, 100, RGBA(255, 255, 255, 0))
        rc.RECT
        rc\right = 100
        rc\bottom = 100
        If ThemesEnabled = #True
            CallFunctionFast(*DrawThemeBackground, hThemeButton, hdc, 1, 2, @rc, 0)
        EndIf
        StopDrawing()
        Global themeButtonHotBorder = createBorder()
        setBorder(themeButtonHotBorder, ImageID(themeButtonBorderHotImage), -2, 0, 0)
        FreeImage(themeButtonBorderHotImage)
        
        ; system button pressed state border background mask
        themeButtonBorderPressedImage = CreateImage(#PB_Any, 100, 100, 32)
        hdc = StartDrawing(ImageOutput(themeButtonBorderPressedImage))
        DrawingMode(#PB_2DDrawing_AllChannels)
        Box(0, 0, 100, 100, RGBA(255, 255, 255, 0))
        rc.RECT
        rc\right = 100
        rc\bottom = 100
        If ThemesEnabled = #True
            CallFunctionFast(*DrawThemeBackground, hThemeButton, hdc, 1, 3, @rc, 0)
        EndIf
        StopDrawing()
        Global themeButtonPressedBorder = createBorder()
        setBorder(themeButtonPressedBorder, ImageID(themeButtonBorderPressedImage), -2, 0, 0)
        FreeImage(themeButtonBorderPressedImage)
        
        ; system button disabled state border background mask
        themeButtonBorderDisabledImage = CreateImage(#PB_Any, 100, 100, 32)
        hdc = StartDrawing(ImageOutput(themeButtonBorderDisabledImage))
        DrawingMode(#PB_2DDrawing_AllChannels)
        Box(0, 0, 100, 100, RGBA(255, 255, 255, 0))
        rc.RECT
        rc\right = 100
        rc\bottom = 100
        If ThemesEnabled = #True
            CallFunctionFast(*DrawThemeBackground, hThemeButton, hdc, 1, 1, @rc, 0)
        EndIf
        StopDrawing()
        Global themeButtonDisabledBorder = createBorder()
        setBorder(themeButtonDisabledBorder, ImageID(themeButtonBorderDisabledImage), -2, 0, 0)
        FreeImage(themeButtonBorderDisabledImage)
        
        ; system tab theme border background mask
        themeTabBorderImage = CreateImage(#PB_Any, 100, 100, 32)
        hdc = StartDrawing(ImageOutput(themeTabBorderImage))
        DrawingMode(#PB_2DDrawing_AllChannels)
        Box(0, 0, 100, 100, RGBA(255, 255, 255, 0))
        rc.RECT
        rc\right = 100
        rc\bottom = 100
        If ThemesEnabled = #True
            CallFunctionFast(*DrawThemeBackground, hThemeTab, hdc, 9, 0, @rc, 0)
        EndIf
        StopDrawing()
        Global themeTabBorder = createBorder()
        rc\left = 1
        rc\top = 1
        rc\right - 3
        rc\bottom - 2
        setBorder(themeTabBorder, ImageID(themeTabBorderImage), 0, rc, 0)
        FreeImage(themeTabBorderImage)
        
        createdPanelExThemes = #True
    EndIf
    
EndProcedure

Procedure addPanelExUpdateChild(*panelex.panelexs, hwnd.i, *rc.RECT, mode.b)
    
    ;LockMutex(panelExMutex)
    *child.invalidateChild = #Null
    ForEach *panelex\updateChild()
        If *panelex\updateChild()\hwnd = hwnd
            *child.invalidateChild = *panelex\updateChild()
            Break
        EndIf
    Next
    
    If *child = #Null
        *child.invalidateChild = AddElement(*panelex\updateChild())
    EndIf
    
    *child\hwnd = hwnd
    *child\mode = mode
    CopyStructure(*rc, *child\rc, RECT)
    *panelexpage.panelexpages = *panelex\displayedPage
    MapWindowPoints_(*panelexpage\handle, hwnd, *child\rc, 2)
    
    ;UnlockMutex(panelExMutex)
    
EndProcedure

Procedure updatePanelexChildren(*panelex.panelexs)
    
    ;LockMutex(updateMutex)
    
    ForEach *panelex\updateChild()
        
        Select *panelex\updateChild()\mode
                
            Case 0 ; invalidate
                
                ;GetWindowRect_(*panelex\updateChild()\hwnd, trc.RECT)
                ;debuglog(Str(*panelex\updateChild()\hwnd) + " " + Str(trc\left))
                
                ;InvalidateRect_(*panelex\updateChild()\hwnd, *panelex\updateChild()\rc, 0)
                
                RedrawWindow_(*panelex\updateChild()\hwnd, *panelex\updateChild()\rc, 0, #RDW_NOERASE|#RDW_UPDATENOW|#RDW_INVALIDATE)
                
;                 dc = GetDC_(WindowID(0))
;                 brush = CreateSolidBrush_(RGB(Random(255),0,0))
;                 GetWindowRect_(*panelex\updateChild()\hwnd, rc.RECT)
;                 MapWindowPoints_(0, WindowID(0), rc, 2)
;                 FillRect_(dc, *panelex\updateChild()\rc, brush)
;                 DeleteObject_(brush)
;                 ReleaseDC_(WindowID(0), dc)
                
            Case 1 ; redraw invalidate, all children
                
                ;RedrawWindow_(*panelex\updateChild()\hwnd, *panelex\updateChild()\rc, 0, #RDW_FRAME|#RDW_INVALIDATE|#RDW_ERASE|#RDW_ALLCHILDREN)
                RedrawWindow_(*panelex\updateChild()\hwnd, *panelex\updateChild()\rc, 0, #RDW_FRAME|#RDW_INVALIDATE|#RDW_ERASE|#RDW_ALLCHILDREN|#RDW_UPDATENOW)
                
            Case 2
                
                InvalidateRect_(*panelex\updateChild()\hwnd, *panelex\updateChild()\rc, 0)
                
        EndSelect
        
    Next
    
    ;UnlockMutex(updateMutex)
 
EndProcedure

Procedure addPanelExUpdateRect(*panelex.panelexs, *rc.RECT)
    
    If *panelex\animRedrawFalse = #True
        
        If *panelex\updateCount < 1
            If GetCurrentThreadId_() <> renderThreadID
                *panelex\updateCount + 1
            EndIf
        EndIf
        
        *newrc.RECT = AddElement(*panelex\updateRc())
        CopyStructure(*rc, *newrc, RECT)
        
    EndIf
    
EndProcedure

Procedure rectInPanelExUpdateRect(*panelex.panelexs, *rc.RECT)
    
    LockMutex(updateMutex)
    
    If ListSize(*panelex\updateRc()) = 0
        UnlockMutex(updateMutex)
        ProcedureReturn #True
    EndIf
    
    ;Debug("ListSize(*panelex\updateRc()): "+Str(ListSize(*panelex\updateRc())))
    ;ForEach *panelex\updateRc()
    ;    *updateRc.RECT = *panelex\updateRc()
    ;    ;Debug(Str(*updaterc\left) + " " + Str(*updaterc\top) + " " + Str(*updaterc\right) + " " + Str(*updaterc\bottom))
    ;Next
    ForEach *panelex\updateRc()
        *updateRc.RECT = *panelex\updateRc()
        If IntersectRect(*updateRc, *rc)
            UnlockMutex(updateMutex)
            ProcedureReturn #True
        EndIf
    Next
    
    UnlockMutex(updateMutex)
    
    ProcedureReturn #False
    
EndProcedure

Procedure calcPanelExPageArea(*panelexpage.panelexpages)
    
    chwnd = GetWindow_(*panelexpage\handle, #GW_CHILD)
    While chwnd <> #Null
        
        *trackWin.trackWindows = GetProp_(chwnd, trackwinAtom)
        If *trackWin <> #Null And *trackWin\visible = #True
            
            GetWindowRect_(chwnd, rc.RECT)
            MapWindowPoints_(0, *panelexpage\handle, rc, 2)
            ;debuglog(Str(hwnd)+"  left: "+Str(rc\left)+" top: "+Str(rc\top)+" right: "+Str(rc\right)+" bottom: "+Str(rc\bottom))
            
            If rc\right > areaWidth
                areaWidth = rc\right
            EndIf
            If rc\bottom > areaHeight
                areaHeight = rc\bottom
            EndIf
            
        EndIf
            
        chwnd = GetWindow_(chwnd, #GW_HWNDNEXT)
        
    Wend
    
    *panelexpage\area\right = areaWidth-1
    *panelexpage\area\bottom = areaHeight-1
    
    *panelexpage\calcArea = #False
    *panelexpage\renderScrollbars = #True
    ;debuglog("calcAreaWidth: " + Str(areaWidth-1))
    
EndProcedure

Procedure updatePanelExPageScrolling(*panelexpage.panelexpages, x, y)
    
    areaWidth = *panelexpage\area\right-*panelexpage\area\left
    areaHeight = *panelexpage\area\bottom-*panelexpage\area\top
    GetClientRect_(*panelexpage\handle, prc.RECT)
    MapWindowPoints_(*panelexpage\handle, *panelexpage\containerHandle, prc, 2)
    GetClientRect_(*panelexpage\containerHandle, crc.RECT)
    
    If areaWidth < crc\right
        areaWidth = crc\right
    EndIf
    If areaHeight < crc\bottom
        areaHeight = crc\bottom
    EndIf
    areaWidth + 1
    areaHeight + 1
    
    If *panelexpage\vScrollVisible
        GetClientRect_(*panelexpage\vScrollBar, @trc.RECT)
        scrollbarWidth = trc\right-trc\left
        areaWidth+scrollbarWidth
    EndIf
    If *panelexpage\hScrollVisible
        GetClientRect_(*panelexpage\hScrollBar, @trc.RECT)
        scrollbarHeight = trc\bottom-trc\top
        areaHeight+scrollbarHeight
    EndIf
    
    *rc.RECT = *panelexpage\lastAreaPos
    If *rc\left <> prc\left+x Or *rc\top <> prc\top+y Or *rc\right-*rc\left <> areaWidth Or *rc\bottom-*rc\top <> areaHeight
        SetWindowPos_(*panelexpage\handle, 0, prc\left+x, prc\top+y, areaWidth, areaHeight, #SWP_NOACTIVATE|#SWP_NOOWNERZORDER|#SWP_NOZORDER|#SWP_NOCOPYBITS|#SWP_NOREDRAW)
        *rc\left = prc\left + x
        *rc\top = prc\top + y
        *rc\right = *rc\left + areaWidth
        *rc\bottom = *rc\top + areaHeight
    EndIf
    
EndProcedure

Procedure handlePanelExPageAutoScroll(*panelexpage.panelexpages)
    
    If *panelexpage\autoScroll = #False
        ProcedureReturn #False
    EndIf
    
    areaWidth = *panelexpage\area\right - *panelexpage\area\left
    areaHeight = *panelexpage\area\bottom - *panelexpage\area\top
    
    ;debuglog("areaWidth: "+Str(areaWidth))
    ;debuglog("areaHeight: "+Str(areaHeight))
    
    GetClientRect_(*panelexpage\containerHandle, @rc.RECT)
    
    If areaWidth >= rc\right Or (*panelexpage\vScrollVisible = #True And areaWidth >= rc\right-iHThumb)
        If *panelexpage\hScrollVisible = #False
            If *panelexpage\noHorizontal = #False
                ShowWindow_(*panelexpage\hScrollBar, #SW_SHOW)
                *panelexpage\hScrollVisible = #True
            EndIf
        EndIf
    Else
        If *panelexpage\hScrollVisible = #True
            
            scinfo.SCROLLINFO
            scinfo\cbSize = SizeOf(SCROLLINFO)
            scinfo\fMask = #SIF_POS
            scinfo\nPos = 0
            SetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo, #False)
            
            ; scroll by x offset
            updatePanelExPageScrolling(*panelexpage, *panelexpage\lastHscrollPos, 0)
            
            *panelexpage\lastHscrollPos = 0
            *panelexpage\lastHscrollMax = 0
            *panelexpage\lastHScrollRect\left = -1
            
            ShowWindow_(*panelexpage\hScrollBar, #SW_HIDE)
            *panelexpage\hScrollVisible = #False
            
        EndIf
    EndIf
    
    
    If areaHeight >= rc\bottom Or (*panelexpage\hScrollVisible = #True And areaHeight >= rc\bottom-iVThumb)
        If *panelexpage\vScrollVisible = #False
            If *panelexpage\noVertical = #False
                ShowWindow_(*panelexpage\vScrollBar, #SW_SHOW)
                *panelexpage\vScrollVisible = #True
            EndIf
        EndIf
    Else
        If *panelexpage\vScrollVisible = #True
            
            scinfo.SCROLLINFO
            scinfo\cbSize = SizeOf(SCROLLINFO)
            scinfo\fMask = #SIF_POS
            scinfo\nPos = 0
            SetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo, #False)
            
            ; scroll by y offset
            updatePanelExPageScrolling(*panelexpage, 0, *panelexpage\lastVscrollPos)
            
            *panelexpage\lastVscrollPos = 0
            *panelexpage\lastVscrollMax = 0
            *panelexpage\lastVScrollRect\left = -1
            
            ShowWindow_(*panelexpage\vScrollBar, #SW_HIDE)
            *panelexpage\vScrollVisible = #False
            
        EndIf
    EndIf
    
    ;/ calculate whether we need to display horizontal/vertical scrollbars and update ranges
    ; horizontal scrollbar
    If *panelexpage\hScrollVisible = #True
        
        If *panelexpage\vScrollVisible = #True
            hThumb = iHThumb
        EndIf
        
        scinfo.SCROLLINFO
        scinfo\cbSize = SizeOf(SCROLLINFO)
        scinfo\fMask = #SIF_PAGE|#SIF_RANGE
        scinfo\nMin = 0
        scinfo\nMax = areaWidth
        scinfo\nPage = rc\right-hThumb
        SetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo, #False)
        
        scinfo\fMask = #SIF_POS
        GetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo)
        pos = scinfo\nPos
        max = scinfo\nMax
        
        ; scroll by x offset
        If *panelexpage\lastHscrollPos <> pos
            updatePanelExPageScrolling(*panelexpage, *panelexpage\lastHscrollPos - pos, 0)
            *panelexpage\lastHscrollPos = pos
            *panelexpage\renderScrollbars = #True
        EndIf
        If *panelexpage\lastHscrollMax <> max
            *panelexpage\renderScrollbars = #True
            *panelexpage\lastHscrollMax = max
        EndIf
    EndIf
    
    ; vertical scrollbar
    If *panelexpage\vScrollVisible = #True
        
        If *panelexpage\hScrollVisible = #True
            vThumb = iVThumb
        EndIf
        
        scinfo.SCROLLINFO
        scinfo\cbSize = SizeOf(SCROLLINFO)
        scinfo\fMask = #SIF_PAGE|#SIF_RANGE
        scinfo\nMin = 0
        scinfo\nMax = areaHeight
        scinfo\nPage = rc\bottom-vThumb
        SetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo, #False)
        
        scinfo\fMask = #SIF_POS
        GetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo)
        pos = scinfo\nPos
        max = scinfo\nMax
        
        ; scroll by y offset
        If *panelexpage\lastVscrollPos <> pos
            updatePanelExPageScrolling(*panelexpage, 0, *panelexpage\lastVscrollPos - pos)
            *panelexpage\lastVscrollPos = pos
            *panelexpage\renderScrollbars = #True
        EndIf
        If *panelexpage\lastVscrollMax <> max
            *panelexpage\renderScrollbars = #True
            *panelexpage\lastVscrollMax = max
        EndIf
    EndIf
    
EndProcedure

Procedure updatePanelExPageScrollbars(*panelexpage.panelexpages)

    If *panelexpage\hScrollVisible = #True And *panelexpage\vScrollVisible = #False
        
        If *panelexpage\scrollBarBox <> #Null
            *sbtrackWin.trackWindows = *panelexpage\scrollBarBoxTrackWin
            If *sbtrackWin <> #Null And *sbtrackWin\visible = #True
                *panelexpage\lastHScrollRect\left = -1
            EndIf
        EndIf
        
        GetClientRect_(*panelexpage\containerHandle, rc.RECT)
        If EqualRect_(rc, *panelexpage\lastHScrollRect) = #False
            SetWindowPos_(*panelexpage\hScrollBar, #HWND_TOP, 0, rc\bottom-iVThumb, rc\right, iVThumb, #SWP_NOREDRAW)
            CopyStructure(rc, *panelexpage\lastHScrollRect, RECT)
            *panelexpage\renderScrollbars = #True
        EndIf
        
        If *panelexpage\scrollBarBox <> #Null
            *sbtrackWin.trackWindows = *panelexpage\scrollBarBoxTrackWin
            If *sbtrackWin <> #Null And *sbtrackWin\visible = #True
                ShowWindow_(*panelexpage\scrollBarBox, #SW_HIDE)
            EndIf
        EndIf
        
    ElseIf *panelexpage\hScrollVisible = #False And *panelexpage\vScrollVisible = #True
        
        If *panelexpage\scrollBarBox <> #Null
            *sbtrackWin.trackWindows = *panelexpage\scrollBarBoxTrackWin
            If *sbtrackWin <> #Null And *sbtrackWin\visible = #True
                *panelexpage\lastVScrollRect\left = -1
            EndIf
        EndIf
        
        GetClientRect_(*panelexpage\containerHandle, rc.RECT)
        If EqualRect_(rc, *panelexpage\lastVScrollRect) = #False
            SetWindowPos_(*panelexpage\vScrollBar, #HWND_TOP, rc\right-iHThumb, 0, iHThumb, rc\bottom, #SWP_NOREDRAW)
            CopyStructure(rc, *panelexpage\lastVScrollRect, RECT)
            *panelexpage\renderScrollbars = #True
        EndIf
        
        If *panelexpage\scrollBarBox <> #Null
            *sbtrackWin.trackWindows = *panelexpage\scrollBarBoxTrackWin
            If *sbtrackWin <> #Null And *sbtrackWin\visible = #True
                ShowWindow_(*panelexpage\scrollBarBox, #SW_HIDE)
            EndIf
        EndIf
        
    ElseIf *panelexpage\hScrollVisible = #True And *panelexpage\vScrollVisible = #True
        
        GetClientRect_(*panelexpage\containerHandle, rc.RECT)
        If EqualRect_(rc, *panelexpage\lastHScrollRect) = #False Or EqualRect_(rc, *panelexpage\lastVScrollRect) = #False
            
            hdwp = BeginDeferWindowPos_(3)
            hdwp = DeferWindowPos_(hdwp, *panelexpage\hScrollBar, #HWND_TOP, 0, rc\bottom-iVThumb, rc\right-iHThumb, iVThumb, #SWP_NOREDRAW)
            hdwp = DeferWindowPos_(hdwp, *panelexpage\vScrollBar, #HWND_TOP, rc\right-iHThumb, 0, iHThumb, rc\bottom-iVThumb, #SWP_NOREDRAW)
            If *panelexpage\scrollBarBox <> #Null
                hdwp = DeferWindowPos_(hdwp, *panelexpage\scrollBarBox, #HWND_TOP, rc\right-iHThumb, rc\bottom-iVThumb, iHThumb, iVThumb, #SWP_NOREDRAW)
            EndIf
            EndDeferWindowPos_(hdwp)
            
            CopyStructure(rc, *panelexpage\lastHScrollRect, RECT)
            CopyStructure(rc, *panelexpage\lastVScrollRect, RECT)
            *panelexpage\renderScrollbars = #True
            
        EndIf
        
    Else
        
        If *panelexpage\scrollBarBox <> #Null
            *sbtrackWin.trackWindows = *panelexpage\scrollBarBoxTrackWin
            If *sbtrackWin <> #Null And *sbtrackWin\visible = #True
                ShowWindow_(*panelexpage\scrollBarBox, #SW_HIDE)
            EndIf
        EndIf
        
    EndIf
    
EndProcedure

; returns root panelex *trackWin from child *trackWin
Procedure getRootPanelExTrackWin(*trackWin.trackWindows)
    
    While *trackWin <> #Null
        
        If *trackWin\windowType = #WINDOWTYPE_PANELEX
            
            *rootTrackWin = *trackWin
            
        EndIf
        
        *trackWin.trackWindows = *trackWin\parentTrackWin
        
    Wend
    
    ProcedureReturn *rootTrackWin
    
EndProcedure

; sets rect that doesn't clip any parent panelex windows
Procedure setPanelExPageClippedRect(*rc.RECT, *trackWin.trackWindows, noExcludeScrollbars = #False)
    
    If *trackWin <> #Null
        root = *trackWin\rootPanelexPageHwnd
        GetClientRect_(*trackWin\hwnd, *rc)
        MapWindowPoints_(*trackWin\hwnd, root, *rc, 2)
    EndIf
    
    While *trackWin <> #Null
        
        If *trackWin\windowType = #WINDOWTYPE_PANELEX
            GetClientRect_(*trackWin\hwnd, prc.RECT)
            
            If noExcludeScrollbars = #False
                *panelex.panelexs = *trackWin\panelex
                *panelexpage.panelexpages = *panelex\displayedPage
                If *panelexpage <> #Null
                    If *panelexpage\vScrollVisible
                        GetClientRect_(*panelexpage\vScrollBar, trc.RECT)
                        prc\right - trc\right
                    EndIf
                    If *panelexpage\hScrollVisible
                        GetClientRect_(*panelexpage\hScrollBar, trc.RECT)
                        prc\bottom - trc\bottom
                    EndIf
                EndIf
            EndIf
            
            MapWindowPoints_(*trackWin\hwnd, root, prc, 2)
            IntersectRect_(*rc, *rc, prc)
            ;debuglog(Str(*rc\left) + " " + Str(*rc\top) + " " + Str(*rc\right) + " " + Str(*rc\bottom))
        EndIf
        
        If *trackWin\hwnd = *trackWin\rootPanelexHwnd
            ProcedureReturn
        EndIf
        
        *trackWin.trackWindows = *trackWin\parentTrackWin
        
    Wend
    
EndProcedure

Procedure updateTrackWinRootPanelEx(*trackWin.trackWindows, *rootTrackWin.trackWindows = #Null, *parentPanelEx = #Null)
    
    If *rootTrackWin = #Null
        
        ;class.s = Space(255)
        ;GetClassName_(*trackWin\hwnd, @class, 255)
        ;debuglog("updateTrackWinRootPanelEx: " + class)
        
        *rootTrackWin.trackWindows = getRootPanelExTrackWin(*trackWin)
        If *rootTrackWin <> #Null
            *rootTrackWin\containsChildCntrl = #False
            *trackWin = *rootTrackWin
            *parentPanelEx = *rootTrackWin\panelex
            *rpanelex.panelexs = *rootTrackWin\panelex
            If *rpanelex <> #Null
                *rpanelexpage.panelexpages = *rpanelex\displayedPage
                If *rpanelexpage <> #Null
                    *rootPageTrackWin.trackWindows = *rpanelexpage\trackWin
                    If *rootPageTrackWin <> #Null
                        *rootPageTrackWin\containsChildCntrl = #False
                    EndIf
                EndIf
            EndIf
        EndIf
        
    EndIf
    
    If *rootTrackWin <> #Null
        *rpanelex.panelexs = *rootTrackWin\panelex
        If *rpanelex <> #Null
            *rpanelexpage.panelexpages = *rpanelex\displayedPage
            If *rpanelexpage <> #Null
                *rootPageTrackWin.trackWindows = *rpanelexpage\trackWin
            EndIf
        EndIf
    EndIf
    
    ;class.s = Space(255)
    ;GetClassName_(*trackWin\hwnd, @class, 255)
    ;debuglog("update: " + class)
    
    If *rootTrackWin <> #Null And *rootPageTrackWin <> #Null And *trackWin <> #Null
        
        *trackWin\rootPanelexHwnd = *rootTrackWin\hwnd
        *trackWin\rootPanelexPageHwnd = *rootPageTrackWin\hwnd
        *trackWin\rootPanelex = *rpanelex
        *trackWin\rootPanelexPage = *rpanelexpage
        *trackWin\parentPanelex = *parentPanelEx
        
        containsChildCntrl = #False
        
        chwnd = GetWindow_(*trackWin\hwnd, #GW_CHILD)
        While chwnd <> #Null
            ;class.s = Space(255)
            ;GetClassName_(chwnd, @class, 255)
            ;debuglog("Control: " + Str(chwnd) + " " + class)
            *ctrackWin.trackWindows = GetProp_(chwnd, trackwinAtom)
            
            If *ctrackWin <> #Null
                
                
                ;If *ctrackWin\visible = #True
                    
                    *ctrackWin\rootPanelexHwnd = *rootTrackWin\hwnd
                    *ctrackWin\rootPanelexPageHwnd = *rootPageTrackWin\hwnd
                    *ctrackWin\rootPanelex = *rpanelex
                    *ctrackWin\rootPanelexPage = *rpanelexpage
                    *ctrackWin\parentPanelex = *parentPanelEx
                    
                    *currentRoot = *rootTrackWin
                    *currentParentPanelEx = *parentPanelEx
                    
                    If *ctrackWin\windowType = #WINDOWTYPE_PANELEX
                        *currentParentPanelEx = *ctrackWin\panelex
                    EndIf
                    
                    If *ctrackWin\windowType = #WINDOWTYPE_PANELEX Or *ctrackWin\windowType = #WINDOWTYPE_PANELEXPAGE
                        *ctrackWin\containsChildCntrl = #False
                    EndIf
                    
                    ; if parent is PanelEx or PanelExPage
                    If *trackWin\windowType = #WINDOWTYPE_PANELEX Or *trackWin\windowType = #WINDOWTYPE_PANELEXPAGE
                        
                        ; if child is not PanelEx or PanelExPage then flag as containing none ProGUI child controls
                        If *ctrackWin\windowType <> #WINDOWTYPE_PANELEX And *ctrackWin\windowType <> #WINDOWTYPE_PANELEXPAGE
                            ;class.s = Space(255)
                            ;GetClassName_(*ctrackWin\hwnd, @class, 255)
                            ;debuglog("Control: " + Str(*ctrackWin\hwnd) + " " + class)
                            containsChildCntrl = #True
                        EndIf
                    
                    EndIf
                    
                    class.s = Space(255)
                    GetClassName_(*ctrackWin\hwnd, @class, 255)
                    debuglog("Control: " + Str(*ctrackWin\hwnd) + " " + class)
                    
                    updateTrackWinRootPanelEx(*ctrackWin, *currentRoot, *currentParentPanelEx)
                    
                ;EndIf
            
            EndIf
                
            chwnd = GetWindow_(chwnd, #GW_HWNDNEXT)
            
        Wend
        
        If containsChildCntrl = #True
            
            While *trackWin <> #Null
                
                If *trackWin\windowType = #WINDOWTYPE_PANELEX Or *trackWin\windowType = #WINDOWTYPE_PANELEXPAGE
                    *trackWin\containsChildCntrl = #True
                EndIf
                
                If *trackWin = *rootTrackWin
                    Break
                EndIf
                
                *trackWin.trackWindows = *trackWin\parentTrackWin
                
            Wend
            
        EndIf
        
    ElseIf *rootTrackWin = #Null And *trackWin <> #Null
        
        *trackWin\rootPanelexHwnd = #Null
        *trackWin\rootPanelexPageHwnd = #Null
        *trackWin\rootPanelex = #Null
        *trackWin\rootPanelexPage = #Null
        *trackWin\parentPanelex = #Null
        
        chwnd = GetWindow_(*trackWin\hwnd, #GW_CHILD)
        While chwnd <> #Null
            ;class.s = Space(255)
            ;GetClassName_(chwnd, @class, 255)
            ;debuglog("Control: " + Str(chwnd) + " " + class)
            *ctrackWin.trackWindows = GetProp_(chwnd, trackwinAtom)
            
            If *ctrackWin <> #Null
                
                updateTrackWinRootPanelEx(*ctrackWin, *currentRoot, *currentParentPanelEx)
               
            EndIf
                
            chwnd = GetWindow_(chwnd, #GW_HWNDNEXT)
            
        Wend
        
    EndIf
    
EndProcedure

Procedure validatePanelexPageChildren(*trackWin.trackWindows, rgn, *clipRc.RECT = #Null)
    
    root = *trackWin\rootPanelexPageHwnd
    *rpanelex.panelexs = *trackWin\rootPanelex
    
    If *clipRc = #Null
        
        setPanelExPageClippedRect(clipRc.RECT, *trackWin)
        *clipRc = clipRc
      
    Else
        
        If *trackWin\windowType = #WINDOWTYPE_PANELEX
            
            GetClientRect_(*trackWin\hwnd, rc.RECT)
            MapWindowPoints_(*trackWin\hwnd, root, rc, 2)
            
            *panelex.panelexs = *trackWin\panelex
            *panelexpage.panelexpages = *panelex\displayedPage
            If *panelexpage <> #Null
                If *panelexpage\vScrollVisible
                    GetClientRect_(*panelexpage\vScrollBar, trc.RECT)
                    rc\right - trc\right
                EndIf
                If *panelexpage\hScrollVisible
                    GetClientRect_(*panelexpage\hScrollBar, trc.RECT)
                    rc\bottom - trc\bottom
                EndIf
            EndIf
            
            IntersectRect_(clipRc.RECT, rc, *clipRc)
            
        Else
            CopyRect_(clipRc.RECT, *clipRc)
        EndIf
        
        *clipRc = clipRc
        
    EndIf
    
    chwnd = GetWindow_(*trackWin\hwnd, #GW_CHILD)
    While chwnd <> #Null
        
        *ctrackWin.trackWindows = GetProp_(chwnd, trackwinAtom)
        If *ctrackWin <> #Null
            
            If *ctrackWin\visible = #True
                
                GetWindowRect_(chwnd, rc.RECT)
                MapWindowPoints_(0, root, rc, 2)
                
                If IntersectRect(*clipRc, rc)
                
                    Select *ctrackWin\windowType
                        
                        Case #WINDOWTYPE_STATIC, #WINDOWTYPE_SYSSCROLLBAR, #WINDOWTYPE_SCROLLBARBOX, #WINDOWTYPE_PBCONTAINER, #WINDOWTYPE_SYSPROGRESSBAR, #WINDOWTYPE_SYSBUTTON, #WINDOWTYPE_EDIT
                            
;                             GetWindowRect_(chwnd, rc.RECT)
;                             MapWindowPoints_(0, root, rc, 2)
;                             IntersectRect_(rc, rc, *clipRc)
;                             trgn = CreateRectRgnIndirect_(rc)
;                             CombineRgn_(rgn, rgn, trgn, #RGN_DIFF) ; validate, exclude from update
;                             addPanelExUpdateChild(*rpanelex, chwnd, rc, 2)
                            
                            ;InvalidateRect_(chwnd, 0, 0)
                            ;RedrawWindow_(chwnd, 0, 0, #RDW_INTERNALPAINT|#RDW_UPDATENOW|#RDW_NOERASE) 
                            
;                         Case #WINDOWTYPE_SYSBUTTON
;                            
;                             ;InvalidateRect_(chwnd, 0, 0)
;                             ;addPanelExUpdateChild(*rpanelex, chwnd, 0, 0)
;                             GetWindowRect_(chwnd, rc.RECT)
;                             MapWindowPoints_(0, root, rc, 2)
;                             IntersectRect_(rc, rc, *clipRc)
;                             trgn = CreateRectRgnIndirect_(rc)
;                             CombineRgn_(rgn, rgn, trgn, #RGN_DIFF) ; validate, exclude from update
;                             DeleteObject_(trgn)
;                             
;                             addPanelExUpdateChild(*rpanelex, chwnd, rc, 0)
;                             
                        Case #WINDOWTYPE_PANELEX, #WINDOWTYPE_PANELEXPAGE
                            
                            If *ctrackWin\containsChildCntrl = #True
                               
                                validatePanelexPageChildren(*ctrackWin, rgn, *clipRc)
                                
                            EndIf
                            
                        Default
                            
                            ; set to clipsiblings, clipchildren and redraw
                            If *ctrackWin\windowType <> #WINDOWTYPE_SYSTAB
                                gwlStyle = GetWindowLongPtr_(chwnd, #GWL_STYLE)
                                If Not gwlStyle & #WS_CLIPSIBLINGS Or Not gwlStyle & #WS_CLIPCHILDREN
                                    SetWindowLongPtr_(chwnd, #GWL_STYLE, gwlStyle | #WS_CLIPSIBLINGS | #WS_CLIPCHILDREN)
                                EndIf
                            EndIf
                            
                            ;addPanelExUpdateChild(*rpanelex, chwnd, 0, 1)
                            ;RedrawWindow_(chwnd, 0, 0, #RDW_FRAME|#RDW_INVALIDATE|#RDW_ERASE|#RDW_ALLCHILDREN)
                            
                            GetWindowRect_(chwnd, rc.RECT)
                            MapWindowPoints_(0, root, rc, 2)
                            IntersectRect_(rc, rc, *clipRc)
                            trgn = CreateRectRgnIndirect_(rc)
                            CombineRgn_(rgn, rgn, trgn, #RGN_DIFF) ; validate, exclude from update
                            DeleteObject_(trgn)
                            
                            addPanelExUpdateChild(*rpanelex, chwnd, rc, 1)
                            
                    EndSelect
                    
                EndIf
                    
            EndIf
        
        EndIf
            
        chwnd = GetWindow_(chwnd, #GW_HWNDNEXT)
        
    Wend
    
EndProcedure

Procedure renderPBFrame(chwnd, divertedWindow, thisdc, inAlpha)
    Static dc, bitmap, dcWidth, dcHeight
    
    *trackWin.trackWindows = GetProp_(chwnd, trackwinAtom)
    If *trackWin <> #Null And *trackWin\windowType = #WINDOWTYPE_PBFRAME
        
        GetWindowRect_(chwnd, rec.RECT)
        MapWindowPoints_(0, divertedWindow, rec, 2)
        
        style = GetWindowLongPtr_(chwnd, #GWL_STYLE)
        If style & #WS_VISIBLE
            SetWindowLongPtr_(chwnd, #GWL_STYLE, style &~ #WS_VISIBLE)
        EndIf
        
        If dc = 0 Or rec\right-rec\left > dcWidth Or rec\bottom-rec\top > dcHeight
            
            If rec\right-rec\left > dcWidth
                dcWidth = rec\right-rec\left
            EndIf
            
            If rec\bottom-rec\top > dcHeight
                dcHeight = rec\bottom-rec\top
            EndIf
            
            If dc <> 0
                DeleteDC_(dc)
                DeleteObject_(bitmap)
            EndIf
            
            dc = CreateCompatibleDC_(thisdc)
            bitmap = CreateCompatibleBitmap_(thisdc, dcWidth, dcHeight)
            SelectObject_(dc, bitmap)
            
        EndIf
        
        BitBlt_(dc, 0, 0, rec\right-rec\left, rec\bottom-rec\top, thisdc, rec\left, rec\top, #SRCCOPY)
        CallWindowProc_(*trackWin\callbackProc, chwnd, #WM_PRINT, dc, #PRF_CLIENT|#PRF_NONCLIENT)
        If inAlpha
            fillAlphaChannel(dc, bitmap, 255) ; fills in any zero alpha areas, bloody windows destroying alpha when text drawn grrr! not perfect but the best work-around
        EndIf  
        BitBlt_(thisdc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, dc, 0, 0, #SRCCOPY)
        
    EndIf
    
EndProcedure

Procedure renderPanelexPageChildren_(*trackWin.trackWindows, divertedWindow, dc, *clipRc.RECT = #Null)
    
    root = *trackWin\rootPanelexPageHwnd
    *rpanelex.panelexs = *trackWin\rootPanelex
    
    If *clipRc = #Null
        GetClipBox_(dc, clipRc.RECT)
        *clipRc = clipRc
    EndIf
    
    chwnd = GetWindow_(*trackWin\hwnd, #GW_CHILD)
    While chwnd <> #Null
        
        *ctrackWin.trackWindows = GetProp_(chwnd, trackwinAtom)
        If *ctrackWin <> #Null
            
            If poo = 0;*ctrackWin\visible = #True
                
                GetWindowRect_(chwnd, rc.RECT)
                MapWindowPoints_(0, root, rc, 2)
                
                If IntersectRect(*clipRc, rc) And RectVisible_(dc, rc) And rectInPanelExUpdateRect(*rpanelex, rc)
                    
                    ; check if control has a #WM_CTLCOLORSTATIC background hbrush that needs rendering
                    If *ctrackWin\hBrush <> #Null
                       
                        GetWindowRect_(chwnd, crc.RECT)
                        MapWindowPoints_(0, root, crc, 2)
                        IntersectRect_(crc, crc, *clipRc)
                        MapWindowPoints_(root, chwnd, crc, 2)
                        
                        GetClientRect_(chwnd, rc.RECT)
                        
                        width = rc\right-rc\left
                        height = rc\bottom-rc\top
                        MapWindowPoints_(chwnd, divertedWindow, rc, 2)
                        
                        hdc = CreateCompatibleDC_(wParam)
                        bitmap = CreateCompatibleBitmap_(dc, width, height)
                        SelectObject_(hdc, bitmap)
                        
                        If Not (crc\left = 0 And crc\top = 0 And crc\right = width And crc\bottom = height)
                            SelectObject_(hdc, *ctrackWin\hBrush)
                            PatBlt_(hdc, 0, 0, width, height, #PATCOPY)
                        EndIf
                        DeleteObject_(*ctrackWin\hBrush)
                        
                        BitBlt_(hdc, crc\left, crc\top, crc\right-crc\left, crc\bottom-crc\top, dc, rc\left+crc\left, rc\top+crc\top, #SRCCOPY)
                        
                        *ctrackWin\hBrush = CreatePatternBrush_(bitmap)
                        
                        DeleteObject_(bitmap)
                        DeleteDC_(hdc)
                       
                    EndIf
                    
                    Select *ctrackWin\windowType
                            
                        Case #WINDOWTYPE_PBFRAME
                            
                            renderPBFrame(chwnd, divertedWindow, dc, 0)
                            
                        Case #WINDOWTYPE_PANELEX
                            
                            If *trackWin\windowType <> #WINDOWTYPE_PANELEXPAGE
                                
                                *cpanelex.panelexs = *ctrackWin\panelex
                                *cpanelexpage.panelexpages = *cpanelex\displayedPage
                                
                                If *cpanelexpage <> #Null
                                    
                                    *cpanelexpage\dontdraw = 2
                                
                                    GetClientRect_(*cpanelex\Handle, rc.RECT)
                                    MapWindowPoints_(*cpanelex\Handle, divertedWindow, rc, 2)
                                    
                                    sdc = SaveDC_(dc)
                                    IntersectClipRect_(dc, rc\left, rc\top, rc\right, rc\bottom)
                                    drawPanelPage(*cpanelexpage, dc, *cpanelexpage\Handle, divertedWindow, 0)
                                    RestoreDC_(dc, sdc)
                                    
                                    *cpanelexpage\dontdraw = #True
                                    
                                EndIf
                                
                            EndIf
                            
                        Case #WINDOWTYPE_STATIC
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, *clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                            
                            ;If *ctrackWin\divertedRefresh = #False
                            
                                *ctrackWin\divertedRedraw = #True
                                RedrawWindow_(chwnd, crc, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE|#RDW_NOCHILDREN)
                                *ctrackWin\divertedRedraw = #False
                                
                            ;Else
                            ;    *ctrackWin\divertedRefresh = #False
                            ;EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetWindowRect_(chwnd, rc.RECT)
                                MapWindowPoints_(0, divertedWindow, rc, 2)
                                
                                ;SelectObject_(*ctrackWin\divertedDC, ImageID(*ctrackWin\divertedBuffer))
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 1)
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left, crc\top, #SRCCOPY)
                                
;                                 brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                                 trc.RECT
;                                 trc\left = rc\left
;                                 trc\top = rc\top
;                                 trc\right = rc\right
;                                 trc\bottom = rc\bottom
;                                 FillRect_(dc, trc, brush)
;                                 DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                
                            EndIf
                            
;                             savedDC = SaveDC_(dc)
;                             GetWindowOrgEx_(dc, pnt.POINT)
;                             GetWindowRect_(chwnd, rc.RECT)
;                             MapWindowPoints_(0, divertedWindow, rc, 2)
;                             SetWindowOrgEx_(dc, pnt\x-rc\left, pnt\y-rc\top, 0)
;                             *ctrackWin\panelexDC = dc
;                             RedrawWindow_(chwnd, 0, 0, #RDW_INTERNALPAINT|#RDW_UPDATENOW)
;                             *ctrackWin\panelexDC = 0
;                             RestoreDC_(dc, savedDC)
                            
                            
;                             GetWindowOrgEx_(dc, pnt.POINT)
;                             GetWindowRect_(chwnd, rc.RECT)
;                             MapWindowPoints_(0, divertedWindow, rc, 2)
;                             SetWindowOrgEx_(dc, pnt\x-rc\left, pnt\y-rc\top, 0)
;                             
;                             brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                             trc.RECT
;                             trc\left = 0
;                             trc\top = 0
;                             trc\right = rc\right-rc\left
;                             trc\bottom = rc\bottom-rc\top
;                             FillRect_(dc, trc, brush)
;                             DeleteObject_(brush)
;                             
;                             
;                             CallWindowProc_(*ctrackWin\callbackProc, chwnd, #WM_PRINT, dc, #PRF_CLIENT|#PRF_OWNED|#PRF_CHILDREN|#PRF_NONCLIENT)
;                             ;CallWindowProc_(*ctrackWin\callbackProc, chwnd, #WM_PAINT, dc, 0)
;                             
;                             
;                             SetWindowOrgEx_(dc, pnt\x, pnt\y, 0)

                        Case #WINDOWTYPE_PBCONTAINER
                            
                            ; calculate window frame offsets
                            GetWindowRect_(chwnd, wrc.RECT)
                            MapWindowPoints_(0, chwnd, wrc, 2)
                            frameXOffset = 0
                            If wrc\left < 0
                               frameXOffset = -wrc\left
                            EndIf
                            frameYOffset = 0
                            If wrc\top < 0
                               frameYOffset = -wrc\top
                            EndIf
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, *clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                            
                            crc\left + frameXOffset
                            crc\top + frameYOffset
                            crc\right + frameXOffset
                            crc\bottom + frameYOffset
                            
                            redraw = #False
                            If *ctrackWin\divertedClipRgn <> #Null
                                GetRgnBox_(*ctrackWin\divertedClipRgn, drc.RECT)
                                IntersectRect_(trc.RECT, crc, drc)
                                If Not (trc\left = crc\left And trc\top = crc\top And trc\right = crc\right And trc\bottom = crc\bottom)
                                    redraw = #True
                                EndIf
                            Else
                                redraw = #True
                            EndIf
                            
                            If *ctrackWin\divertedRefresh = #False
                                
                                If redraw = #True
                                    *ctrackWin\divertedRedraw = #True
                                    RedrawWindow_(chwnd, 0, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_ERASE|#RDW_FRAME|#RDW_NOCHILDREN)
                                    *ctrackWin\divertedRedraw = #False
                                EndIf
                                
                            Else
                                *ctrackWin\divertedRefresh = #False
                            EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetWindowRect_(chwnd, rc.RECT)
                                MapWindowPoints_(0, divertedWindow, rc, 2)
                                
                                ;SelectObject_(*ctrackWin\divertedDC, ImageID(*ctrackWin\divertedBuffer))
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 1)
                                GetWindowOrgEx_(*ctrackWin\divertedDC, pt.POINT)
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left+pt\x, crc\top+pt\y, #SRCCOPY)
                                
;                                 brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                                 trc.RECT
;                                 trc\left = rc\left
;                                 trc\top = rc\top
;                                 trc\right = rc\right
;                                 trc\bottom = rc\bottom
;                                 FillRect_(dc, trc, brush)
;                                 DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                
                            EndIf
                            
                        Case #WINDOWTYPE_SYSPROGRESSBAR
                            
                            ; calculate window frame offsets
                            GetWindowRect_(chwnd, wrc.RECT)
                            MapWindowPoints_(0, chwnd, wrc, 2)
                            frameXOffset = 0
                            If wrc\left < 0
                               frameXOffset = -wrc\left
                            EndIf
                            frameYOffset = 0
                            If wrc\top < 0
                               frameYOffset = -wrc\top
                            EndIf
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, *clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                            
                            crc\left + frameXOffset
                            crc\top + frameYOffset
                            crc\right + frameXOffset
                            crc\bottom + frameYOffset
                            
                            redraw = #False
                            If *ctrackWin\divertedClipRgn <> #Null
                                GetRgnBox_(*ctrackWin\divertedClipRgn, drc.RECT)
                                IntersectRect_(trc.RECT, crc, drc)
                                If Not (trc\left = crc\left And trc\top = crc\top And trc\right = crc\right And trc\bottom = crc\bottom)
                                    redraw = #True
                                EndIf
                            Else
                                redraw = #True
                            EndIf
                            
                            If *ctrackWin\divertedRefresh = #False
                                
                                If redraw = #True
                                    *ctrackWin\divertedRedraw = #True
                                    RedrawWindow_(chwnd, 0, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE|#RDW_NOCHILDREN)
                                    *ctrackWin\divertedRedraw = #False
                                EndIf
                                
                            Else
                                *ctrackWin\divertedRefresh = #False
                            EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetWindowRect_(chwnd, rc.RECT)
                                MapWindowPoints_(0, divertedWindow, rc, 2)
                                
                                ;SelectObject_(*ctrackWin\divertedDC, ImageID(*ctrackWin\divertedBuffer))
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 1)
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left, crc\top, #SRCCOPY)
                                
;                                 brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                                 trc.RECT
;                                 trc\left = rc\left
;                                 trc\top = rc\top
;                                 trc\right = rc\right
;                                 trc\bottom = rc\bottom
;                                 FillRect_(dc, trc, brush)
;                                 DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                
                            EndIf
                            
                        Case #WINDOWTYPE_SYSBUTTON
                            
                            ; calculate window frame offsets
                            GetWindowRect_(chwnd, wrc.RECT)
                            MapWindowPoints_(0, chwnd, wrc, 2)
                            frameXOffset = 0
                            If wrc\left < 0
                               frameXOffset = -wrc\left
                            EndIf
                            frameYOffset = 0
                            If wrc\top < 0
                               frameYOffset = -wrc\top
                            EndIf
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, *clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                            
                            crc\left + frameXOffset
                            crc\top + frameYOffset
                            crc\right + frameXOffset
                            crc\bottom + frameYOffset
                            
                            redraw = #False
                            If *ctrackWin\divertedClipRgn <> #Null
                                GetRgnBox_(*ctrackWin\divertedClipRgn, drc.RECT)
                                IntersectRect_(trc.RECT, crc, drc)
                                If Not (trc\left = crc\left And trc\top = crc\top And trc\right = crc\right And trc\bottom = crc\bottom)
                                    redraw = #True
                                EndIf
                            Else
                                redraw = #True
                            EndIf
                            
                            If *ctrackWin\divertedRefresh = #False
                                
                                If redraw = #True
                                    *ctrackWin\divertedRedraw = #True
                                    RedrawWindow_(chwnd, 0, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE|#RDW_NOCHILDREN)
                                    *ctrackWin\divertedRedraw = #False
                                EndIf
                                
                            Else
                                *ctrackWin\divertedRefresh = #False
                            EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetWindowRect_(chwnd, rc.RECT)
                                MapWindowPoints_(0, divertedWindow, rc, 2)
                                
                                ;SelectObject_(*ctrackWin\divertedDC, ImageID(*ctrackWin\divertedBuffer))
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 1)
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left, crc\top, #SRCCOPY)
                                
;                                 brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                                 trc.RECT
;                                 trc\left = rc\left
;                                 trc\top = rc\top
;                                 trc\right = rc\right
;                                 trc\bottom = rc\bottom
;                                 FillRect_(dc, trc, brush)
;                                 DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                
                            EndIf
                            
                        Case #WINDOWTYPE_EDIT, #WINDOWTYPE_RICHEDIT
                            
                            ; calculate window frame offsets
                            GetWindowRect_(chwnd, wrc.RECT)
                            MapWindowPoints_(0, chwnd, wrc, 2)
                            frameXOffset = 0
                            If wrc\left < 0
                               frameXOffset = -wrc\left
                            EndIf
                            frameYOffset = 0
                            If wrc\top < 0
                               frameYOffset = -wrc\top
                            EndIf
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, *clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                            
                            *lrc.RECT = *trackWin\divertedLastRc
                            
                            redraw = #False
                            If Not (*lrc\left = crc\left And *lrc\top = crc\top And *lrc\right = crc\right And *lrc\bottom = crc\bottom)
                                redraw = #True
                                ;debuglog("last rect not same")
                            Else
                                ;debuglog("last rect equal")
                            EndIf
                            
                            If *ctrackWin\divertedRefresh = #False
                                
                                If redraw = #True
                                    *ctrackWin\divertedRedraw = #True
                                    debuglog("redraw " + Str(Random(255)))
                                    
                                    ValidateRect_(chwnd, 0)
                                    RedrawWindow_(chwnd, 0, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE|#RDW_NOCHILDREN|#RDW_FRAME|#RDW_NOINTERNALPAINT)
                                    
                                    *ctrackWin\divertedRedraw = #False
                                    CopyStructure(crc, *lrc, RECT)
                                EndIf
                                
                            Else
                                *ctrackWin\divertedRefresh = #False
                            EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetClientRect_(chwnd, rc.RECT)
                                MapWindowPoints_(chwnd, divertedWindow, rc, 2)
                                
                                ;SelectObject_(*ctrackWin\divertedDC, ImageID(*ctrackWin\divertedBuffer))
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 1, 1)
                                
                                ;debuglog("x: " + Str(pt\x) + " y: " + Str(pt\y))
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left, crc\top, #SRCCOPY)
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, pt\x, pt\y, #SRCCOPY)
                                
                                If *ctrackWin\divertedWinBuffer <> #Null
                                
                                    crc\left + frameXOffset
                                    crc\top + frameYOffset
                                    crc\right + frameXOffset
                                    crc\bottom + frameYOffset
                                    GetWindowRect_(chwnd, rc.RECT)
                                    MapWindowPoints_(0, divertedWindow, rc, 2)
                                    sdc = SaveDC_(dc)
                                    GetClientRect_(chwnd, clrc.RECT)
                                    crc\right + 1
                                    MapWindowPoints_(chwnd, divertedWindow, clrc, 2)
                                    crgn = CreateRectRgnIndirect_(clrc)
                                    crc\right - 1
                                    GetWindowOrgEx_(dc, pt.POINT)
                                    OffsetRgn_(crgn, -pt\x, -pt\y)
                                    ExtSelectClipRgn_(dc, crgn, #RGN_XOR)
                                    BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedWinDC, crc\left, crc\top, #SRCCOPY)
                                    RestoreDC_(dc, sdc)
                                    DeleteObject_(crgn)
                                    
                                EndIf
                                    
;                                 brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                                 trc.RECT
;                                 trc\left = rc\left
;                                 trc\top = rc\top
;                                 trc\right = rc\right
;                                 trc\bottom = rc\bottom
;                                 FillRect_(dc, trc, brush)
;                                 DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                
                            EndIf
                            
                        Case #WINDOWTYPE_SYSSCROLLBAR    
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                            
                            redraw = #False
                            If *ctrackWin\divertedClipRgn <> #Null
                                GetRgnBox_(*ctrackWin\divertedClipRgn, drc.RECT)
                                IntersectRect_(trc.RECT, crc, drc)
                                If Not (trc\left = crc\left And trc\top = crc\top And trc\right = crc\right And trc\bottom = crc\bottom)
                                    redraw = #True
                                EndIf
                            Else
                                redraw = #True
                            EndIf
                            
                            If *ctrackWin\divertedRefresh = #False
                                
                                If redraw = #True
                                    *ctrackWin\divertedRedraw = #True
                                    RedrawWindow_(chwnd, crc, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE)
                                    *ctrackWin\divertedRedraw = #False
                                EndIf
                                
                            Else
                                *ctrackWin\divertedRefresh = #False
                            EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetWindowRect_(chwnd, rc.RECT)
                                MapWindowPoints_(0, divertedWindow, rc, 2)
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 1)
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left, crc\top, #SRCCOPY)
                                
                                ;brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
                                ;trc.RECT
                                ;trc\left = rc\left
                                ;trc\top = rc\top
                                ;trc\right = rc\right
                                ;trc\bottom = rc\bottom
                                ;FillRect_(dc, trc, brush)
                                ;DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                
                            EndIf
                            
                        Case #WINDOWTYPE_LISTBOX, #WINDOWTYPE_LISTVIEW, #WINDOWTYPE_SYSHEADER
                            
                            ; calculate window frame offsets
                            GetWindowRect_(chwnd, wrc.RECT)
                            MapWindowPoints_(0, chwnd, wrc, 2)
                            frameXOffset = 0
                            If wrc\left < 0
                               frameXOffset = -wrc\left
                            EndIf
                            frameYOffset = 0
                            If wrc\top < 0
                               frameYOffset = -wrc\top
                            EndIf
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, *clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                            
                            crc\left + frameXOffset
                            crc\top + frameYOffset
                            crc\right + frameXOffset
                            crc\bottom + frameYOffset
                            
                            redraw = #False
                            If *ctrackWin\divertedClipRgn <> #Null
                                GetRgnBox_(*ctrackWin\divertedClipRgn, drc.RECT)
                                IntersectRect_(trc.RECT, crc, drc)
                                If Not (trc\left = crc\left And trc\top = crc\top And trc\right = crc\right And trc\bottom = crc\bottom)
                                    redraw = #True
                                EndIf
                            Else
                                redraw = #True
                            EndIf
                            
                            If *ctrackWin\divertedRefresh = #False
                                
                                If redraw = #True
;                                     *ctrackWin\divertedRedraw = #True
;                                     RedrawWindow_(chwnd, 0, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE|#RDW_NOCHILDREN|#RDW_FRAME)
;                                     *ctrackWin\divertedRedraw = #False
                                    
                                    *ctrackWin\divertedRedraw = #True
                                    RedrawWindow_(chwnd, 0, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE|#RDW_NOCHILDREN|#RDW_FRAME)
                                    ;InvalidateRect_(chwnd, 0, 0)
                                    ;RedrawWindow_(chwnd, #Null, #Null, #RDW_INVALIDATE|#RDW_NOCHILDREN|#RDW_FRAME|#RDW_NOERASE)
                                    ;RedrawWindow_(chwnd, #Null, #Null, #RDW_INVALIDATE|#RDW_NOCHILDREN|#RDW_NOFRAME|#RDW_NOERASE)
                                    ;*callback = GetWindowLongPtr_(chwnd, #GWL_WNDPROC)
                                    ;CallWindowProc_(*callback, chwnd, #WM_PAINT, 0, 0)
                                    ;CallWindowProc_(*callback, chwnd, #WM_NCPAINT, *trackWin\divertedClipRgn, 0)
                                    ;ValidateRect_(chwnd, 0)
                                    ;RedrawWindow_(chwnd, #Null, #Null, #RDW_VALIDATE|#RDW_ALLCHILDREN)
                                    *ctrackWin\divertedRedraw = #False
                                EndIf
                                
                            Else
                                *ctrackWin\divertedRefresh = #False
                            EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetWindowRect_(chwnd, rc.RECT)
                                MapWindowPoints_(0, divertedWindow, rc, 2)
                                
                                ;SelectObject_(*ctrackWin\divertedDC, ImageID(*ctrackWin\divertedBuffer))
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 1, 1)
                                
                                GetWindowOrgEx_(*ctrackWin\divertedDC, pt.POINT)
                                ;debuglog("x: " + Str(pt\x) + " y: " + Str(pt\y))
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left+pt\x, crc\top+pt\y, #SRCCOPY)
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, pt\x, pt\y, #SRCCOPY)
                                
;                                 brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                                 trc.RECT
;                                 trc\left = rc\left
;                                 trc\top = rc\top
;                                 trc\right = rc\right
;                                 trc\bottom = rc\bottom
;                                 GetClipBox_(*ctrackWin\divertedDC, trc.RECT)
;                                 MapWindowPoints_(*ctrackWin\hwnd, divertedWindow, trc, 2)
;                                 FillRect_(dc, trc, brush)
;                                 DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                
                            EndIf
                            
                    EndSelect
                    
                    ; render caret if set
                    If caret\hwnd = *ctrackWin\hwnd And caret\show = #True And caret\render = #True
                        CopyStructure(caret\pos, pt.POINT, POINT)
                        MapWindowPoints_(caret\hwnd, divertedWindow, pt, 1)
                        sdc = SaveDC_(dc)
                        brush = GetStockObject_(#BLACK_BRUSH)
                        SelectObject_(dc, brush)
                        PatBlt_(dc, pt\x, pt\y, caret\width, caret\height, #DSTINVERT)
                        RestoreDC_(dc, sdc)
                    EndIf
                    
                    If *ctrackWin\windowType <> #WINDOWTYPE_PANELEX And *ctrackWin\windowType <> #WINDOWTYPE_PANELEXPAGE
                        GetClientRect_(*ctrackWin\hwnd, rc.RECT)
                        MapWindowPoints_(*ctrackWin\hwnd, divertedWindow, rc, 2)
                        CopyStructure(*clipRc, newclipRc.RECT, RECT)
                        IntersectRect_(newclipRc, rc, newclipRc)
                        sdc = SaveDC_(dc)
                        IntersectClipRect_(dc, newclipRc\left, newclipRc\top, newclipRc\right, newclipRc\bottom)
                        renderPanelexPageChildren_(*ctrackWin, divertedWindow, dc, newclipRc)
                        RestoreDC_(dc, sdc)
                    EndIf
                    
                EndIf
                    
            EndIf
        
        EndIf
            
        chwnd = GetWindow_(chwnd, #GW_HWNDNEXT)
        
    Wend
    
EndProcedure

Procedure renderPanelexPageChildren(*trackWin.trackWindows, divertedWindow, dc, *clipRc.RECT = #Null)
    
    root = *trackWin\rootPanelexPageHwnd
    *rpanelex.panelexs = *trackWin\rootPanelex
    
    If *clipRc = #Null
        GetClipBox_(dc, clipRc.RECT)
        *clipRc = clipRc
        
        ; if root panelex and scrollbars then add scrollbar size back onto cliprc
        *panelexpage.panelexpages = GetProp_(*trackWin\hwnd, panelexpageAtom)
        If *panelexpage <> #Null And *rpanelex\page() = *panelexpage
            If *panelexpage\hScrollVisible = #True
                GetClientRect_(*panelexpage\hScrollBar, src.RECT)
                *clipRc\bottom + src\bottom
            EndIf
            If *panelexpage\vScrollVisible = #True
                GetClientRect_(*panelexpage\vScrollBar, src.RECT)
                *clipRc\right + src\right
            EndIf
        EndIf
    EndIf
    
    chwnd = GetWindow_(*trackWin\hwnd, #GW_CHILD)
    While chwnd <> #Null
        
        *ctrackWin.trackWindows = GetProp_(chwnd, trackwinAtom)
        If *ctrackWin <> #Null
            
            If GetWindowLongPtr_(chwnd, #GWL_STYLE) & #WS_VISIBLE Or *ctrackWin\windowType = #WINDOWTYPE_PBFRAME;poo = 0;*ctrackWin\visible = #True
                
                GetWindowRect_(chwnd, rc.RECT)
                MapWindowPoints_(0, root, rc, 2)
                
                If IntersectRect(*clipRc, rc) And RectVisible_(dc, rc) And rectInPanelExUpdateRect(*rpanelex, rc)
                    
                    ; check if control has a #WM_CTLCOLORSTATIC background hbrush that needs rendering
                    If *ctrackWin\hBrush <> #Null
                        
                        GetWindowRect_(chwnd, crc.RECT)
                        MapWindowPoints_(0, root, crc, 2)
                        IntersectRect_(crc, crc, *clipRc)
                        MapWindowPoints_(root, chwnd, crc, 2)
                        
                        GetClientRect_(chwnd, rc.RECT)
                        
                        width = rc\right-rc\left
                        height = rc\bottom-rc\top
                        MapWindowPoints_(chwnd, divertedWindow, rc, 2)
                        
                        hdc = CreateCompatibleDC_(wParam)
                        bitmap = CreateCompatibleBitmap_(dc, width, height)
                        SelectObject_(hdc, bitmap)
                        
                        If Not (crc\left = 0 And crc\top = 0 And crc\right = width And crc\bottom = height)
                            SelectObject_(hdc, *ctrackWin\hBrush)
                            PatBlt_(hdc, 0, 0, width, height, #PATCOPY)
                        EndIf
                        DeleteObject_(*ctrackWin\hBrush)
                        
                        BitBlt_(hdc, crc\left, crc\top, crc\right-crc\left, crc\bottom-crc\top, dc, rc\left+crc\left, rc\top+crc\top, #SRCCOPY)
                        
                        ;brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
                        ;trc.RECT
                        ;trc\left = 0;crc\left
                        ;trc\top = 0;crc\top
                        ;trc\right = width;crc\right
                        ;trc\bottom = height;crc\bottom
                        ;FillRect_(hdc, trc, brush)
                        ;DeleteObject_(brush)
                        
                        *ctrackWin\hBrush = CreatePatternBrush_(bitmap)
                        
                        DeleteObject_(bitmap)
                        DeleteDC_(hdc)

                    EndIf
                    
                    Select *ctrackWin\windowType
                            
                        Case #WINDOWTYPE_PBFRAME
                            
                            renderPBFrame(chwnd, divertedWindow, dc, 0)
                            
                        Case #WINDOWTYPE_PANELEX
                            
                            If *trackWin\windowType <> #WINDOWTYPE_PANELEXPAGE
                                
                                *cpanelex.panelexs = *ctrackWin\panelex
                                *cpanelexpage.panelexpages = *cpanelex\displayedPage
                                
                                If *cpanelexpage <> #Null
                                    
                                    *cpanelexpage\dontdraw = 2
                                
                                    GetClientRect_(*cpanelex\Handle, rc.RECT)
                                    MapWindowPoints_(*cpanelex\Handle, divertedWindow, rc, 2)
                                    
                                    sdc = SaveDC_(dc)
                                    IntersectClipRect_(dc, rc\left, rc\top, rc\right, rc\bottom)
                                    drawPanelPage(*cpanelexpage, dc, *cpanelexpage\Handle, divertedWindow, 0)
                                    RestoreDC_(dc, sdc)
                                    
                                    *cpanelexpage\dontdraw = #True
                                    
                                EndIf
                                
                            EndIf
                        
                        Case #WINDOWTYPE_STATIC
                            
;                             GetWindowRect_(chwnd, crc.RECT)
;                             MapWindowPoints_(0, root, crc, 2)
;                             IntersectRect_(crc, crc, *clipRc)
;                             MapWindowPoints_(root, chwnd, crc, 2)
;                             
;                             If *ctrackWin\divertedRefresh = #False
;                             
;                                 *ctrackWin\divertedRedraw = #True
;                                 RedrawWindow_(chwnd, crc, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE|#RDW_NOCHILDREN)
;                                 *ctrackWin\divertedRedraw = #False
;                                 
;                             Else
;                                 *ctrackWin\divertedRefresh = #False
;                             EndIf
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, *clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                            
;                             *lrc.RECT = *ctrackWin\divertedLastRc
;                             redraw = #False
;                             If Not (*lrc\left = crc\left And *lrc\top = crc\top And *lrc\right = crc\right And *lrc\bottom = crc\bottom)
;                                 redraw = #True
;                                 ;debuglog("last rect not same")
;                             Else
;                                 ;debuglog("last rect equal")
;                             EndIf
;                             
                            
                            
                            RedrawWindow_(chwnd, 0, 0, #RDW_VALIDATE|#RDW_ALLCHILDREN)
                            If *ctrackWin\divertedRefresh = #False
                                
                                If *trackWin\divertedRedraw = #False
                                    *ctrackWin\divertedRedraw = #True
                                    ;debuglog("redraw " + Str(Random(255)))
                                    
                                    ;ValidateRect_(chwnd, 0)
                                    If *trackWin\windowType <> #WINDOWTYPE_SYSTAB
                                        
                                        ;brush = CreateSolidBrush_(RGB(230, 230, 230))
                                        ;FillRect_(*ctrackWin\divertedDC, crc, brush)
                                        ;DeleteObject_(brush)
                                        
                                        RedrawWindow_(chwnd, crc, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE|#RDW_NOCHILDREN|#RDW_NOFRAME|#RDW_NOINTERNALPAINT)
                                    EndIf
                                    ;CopyStructure(crc, *lrc, RECT)
                                    
                                    ;*ctrackWin\divertedRedraw = #False
                               EndIf
                                
                            Else
                                *ctrackWin\divertedRefresh = #False
                            EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetWindowRect_(chwnd, rc.RECT)
                                MapWindowPoints_(0, divertedWindow, rc, 2)
                                
                                ;SelectObject_(*ctrackWin\divertedDC, ImageID(*ctrackWin\divertedBuffer))
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 1)
                                If *ctrackWin\noblit = #False
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left, crc\top, #SRCCOPY)
                                EndIf
;                                 brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                                 trc.RECT
;                                 trc\left = rc\left
;                                 trc\top = rc\top
;                                 trc\right = rc\right
;                                 trc\bottom = rc\bottom
;                                 FillRect_(dc, trc, brush)
;                                 DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                ;debugbuffer(*ctrackWin\divertedBuffer)
                            EndIf
                            
;                             savedDC = SaveDC_(dc)
;                             GetWindowOrgEx_(dc, pnt.POINT)
;                             GetWindowRect_(chwnd, rc.RECT)
;                             MapWindowPoints_(0, divertedWindow, rc, 2)
;                             SetWindowOrgEx_(dc, pnt\x-rc\left, pnt\y-rc\top, 0)
;                             *ctrackWin\panelexDC = dc
;                             RedrawWindow_(chwnd, 0, 0, #RDW_INTERNALPAINT|#RDW_UPDATENOW)
;                             *ctrackWin\panelexDC = 0
;                             RestoreDC_(dc, savedDC)
                            
                            
;                             GetWindowOrgEx_(dc, pnt.POINT)
;                             GetWindowRect_(chwnd, rc.RECT)
;                             MapWindowPoints_(0, divertedWindow, rc, 2)
;                             SetWindowOrgEx_(dc, pnt\x-rc\left, pnt\y-rc\top, 0)
;                             
;                             brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                             trc.RECT
;                             trc\left = 0
;                             trc\top = 0
;                             trc\right = rc\right-rc\left
;                             trc\bottom = rc\bottom-rc\top
;                             FillRect_(dc, trc, brush)
;                             DeleteObject_(brush)
;                             
;                             
;                             CallWindowProc_(*ctrackWin\callbackProc, chwnd, #WM_PRINT, dc, #PRF_CLIENT|#PRF_OWNED|#PRF_CHILDREN|#PRF_NONCLIENT)
;                             ;CallWindowProc_(*ctrackWin\callbackProc, chwnd, #WM_PAINT, dc, 0)
;                             
;                             
;                             SetWindowOrgEx_(dc, pnt\x, pnt\y, 0)
                            
                        Case #WINDOWTYPE_TOOLBAREX
                            
                            ; use trackwin's windowdc for storing contents of panelex underneath and then later in the toolbar custom draw code blit as background
                            backdc = getDivertedBuffer(*ctrackWin, 0, -1) ; setup or retrieve dc used for window frame, instead use for storing panelex background
                            GetClientRect_(chwnd, crc.RECT)
                            MapWindowPoints_(chwnd, *ctrackWin\rootPanelexPageHwnd, crc, 2)
                            BitBlt_(backdc, 0, 0, crc\right-crc\left, crc\bottom-crc\top, *rpanelex\backgroundDC, crc\left, crc\top, #SRCCOPY)
                            ;debugbuffer(*ctrackWin\divertedWinBuffer, 0, 1)
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, *clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                                
                            If *ctrackWin\noblit = #False    
                                RedrawWindow_(chwnd, 0, 0, #RDW_VALIDATE|#RDW_ALLCHILDREN)
                                If *ctrackWin\divertedRefresh = #False
                                    
                                    If *trackWin\divertedRedraw = #False
                                        *ctrackWin\divertedRedraw = #True
                                        ;debuglog("redraw " + Str(Random(255)))
                                        
                                        ;ValidateRect_(chwnd, 0)
                                        If *trackWin\windowType <> #WINDOWTYPE_SYSTAB
                                            
                                            ;brush = CreateSolidBrush_(RGB(230, 230, 230))
                                            ;FillRect_(*ctrackWin\divertedDC, crc, brush)
                                            ;DeleteObject_(brush)
                                            
                                            RedrawWindow_(chwnd, crc, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE|#RDW_NOCHILDREN|#RDW_NOFRAME|#RDW_NOINTERNALPAINT)
                                        EndIf
                                        ;CopyStructure(crc, *lrc, RECT)
                                        
                                        ;*ctrackWin\divertedRedraw = #False
                                    EndIf
                                    
                                Else
                                    *ctrackWin\divertedRefresh = #False
                                EndIf
                            EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetClientRect_(chwnd, rc.RECT)
                                MapWindowPoints_(chwnd, divertedWindow, rc, 2)
                                
                                ;SelectObject_(*ctrackWin\divertedDC, ImageID(*ctrackWin\divertedBuffer))
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 0, 1)
                                
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left, crc\top, #SRCCOPY)
                                
;                                 brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                                 trc.RECT
;                                 trc\left = rc\left
;                                 trc\top = rc\top
;                                 trc\right = rc\right
;                                 trc\bottom = rc\bottom
;                                 FillRect_(dc, trc, brush)
;                                 DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                ;debugbuffer(*ctrackWin\divertedBuffer)
                            EndIf
                            
                        Case #WINDOWTYPE_TRACKBAR
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, *clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                            
                            RedrawWindow_(chwnd, 0, 0, #RDW_VALIDATE|#RDW_ALLCHILDREN)
                            If *ctrackWin\divertedRefresh = #False
                                
                                If *trackWin\divertedRedraw = #False
                                    *ctrackWin\divertedRedraw = #True
                                    ;debuglog("redraw " + Str(Random(255)))
                                    
                                    SendMessage_(chwnd,#WM_SETFOCUS,0,0) ; hack to force the trackbar to redraw fully, buggy fucking windows...
                                    RedrawWindow_(chwnd, crc, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE|#RDW_NOCHILDREN|#RDW_NOFRAME|#RDW_NOINTERNALPAINT)
                                    
                                    ;debugbuffer(*ctrackWin\divertedBuffer, 0, 1)
                                    
                                    ;CopyStructure(crc, *lrc, RECT)
                                    
                                    ;*ctrackWin\divertedRedraw = #False
                               EndIf
                                
                            Else
                                *ctrackWin\divertedRefresh = #False
                            EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetWindowRect_(chwnd, rc.RECT)
                                MapWindowPoints_(0, divertedWindow, rc, 2)
                                
                                ;SelectObject_(*ctrackWin\divertedDC, ImageID(*ctrackWin\divertedBuffer))
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 1)
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left, crc\top, #SRCCOPY)
                                
;                                 brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                                 trc.RECT
;                                 trc\left = rc\left
;                                 trc\top = rc\top
;                                 trc\right = rc\right
;                                 trc\bottom = rc\bottom
;                                 FillRect_(dc, trc, brush)
;                                 DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                ;debugbuffer(*ctrackWin\divertedBuffer)
                            EndIf
                            
                        Default
                            
                            ; calculate window frame offsets
                            GetWindowRect_(chwnd, wrc.RECT)
                            MapWindowPoints_(0, chwnd, wrc, 2)
                            frameXOffset = 0
                            If wrc\left < 0
                               frameXOffset = -wrc\left
                            EndIf
                            frameYOffset = 0
                            If wrc\top < 0
                               frameYOffset = -wrc\top
                            EndIf
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, *clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                            
                            If *ctrackWin\divertedRefresh = #False
                                
                                *lrc.RECT = *ctrackWin\divertedLastRc
                                redraw = #False
                                If Not (*lrc\left = wrc\left And *lrc\top = wrc\top And *lrc\right = wrc\right And *lrc\bottom = wrc\bottom)
                                    redraw = #True
                                    ;If *ctrackWin\windowType = #WINDOWTYPE_UPDOWN
                                    ;debuglog("last rect not same")
                                    ;class.s = Space(255)
                                    ;GetClassName_(chwnd, @class, 255)
                                    ;debuglog(class)
                                    ;debuglog(Str(*lrc\left)+" "+Str(*lrc\top)+" "+Str(*lrc\right)+" "+Str(*lrc\bottom))
                                    ;debuglog(Str(wrc\left)+" "+Str(wrc\top)+" "+Str(wrc\right)+" "+Str(wrc\bottom))
                                    ;debuglog("--------")
                                    ;EndIf
                                Else
                                    ;If *ctrackWin\windowType = #WINDOWTYPE_UPDOWN
                                    ;debuglog("last rect equal")
                                    ;class.s = Space(255)
                                    ;GetClassName_(chwnd, @class, 255)
                                    ;debuglog(class)
                                    ;debuglog("lrc\left: " + Str(*lrc\left) + " wrc\left: " + Str(wrc\left))
                                    ;debuglog("--------")
                                    ;EndIf
                                    
                                    clprgn = CreateRectRgnIndirect_(crc)
                                    crgn = CreateRectRgn_(0, 0, 0, 0)
                                    GetClipRgn_(*ctrackWin\divertedDC, crgn)
                                    OffsetRgn_(crgn, frameXOffset, frameYOffset)
                                    frgn = CreateRectRgn_(0, 0, 0, 0)
                                    GetClipRgn_(*ctrackWin\divertedWinDC, frgn)
                                    rgn = CreateRectRgn_(0, 0, 0, 0)
                                    CombineRgn_(rgn, crgn, frgn, #RGN_OR)
                                    OffsetRgn_(rgn, -frameXOffset, -frameYOffset)
                                    redraw = #False
                                    retval = CombineRgn_(rgn, clprgn, rgn, #RGN_DIFF)
                                    
                                    If retval <> #NULLREGION
                                        redraw = #True
                                        ;class.s = Space(255)
                                        ;GetClassName_(chwnd, @class, 255)
                                        ;debuglog(class + " :")
                                        ;debuglog("rgn different")
                                    Else
                                        ;debuglog("rgn hasn't changed")
                                    EndIf
                                    
                                EndIf
                                CopyStructure(wrc, *lrc, RECT)
                                
                                setupBuffer = #False
                                If *ctrackWin\divertedBuffer = #Null
                                    setupBuffer = #True
                                EndIf
                                
                                If redraw = #True Or setupBuffer = #True
                                    *ctrackWin\divertedRedraw = #True
                                    ;debuglog("redraw " + Str(Random(255)))
                                    
                                    ;ValidateRect_(chwnd, 0)
                                    RedrawWindow_(chwnd, 0, rgn, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_ERASE|#RDW_NOCHILDREN|#RDW_FRAME|#RDW_NOINTERNALPAINT)
                                    
                                    ;RedrawWindow_(chwnd, 0, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_ERASE|#RDW_NOCHILDREN|#RDW_FRAME|#RDW_INTERNALPAINT)
                                    ;If GetWindow_(*ctrackWin\hwnd, #GW_CHILD) <> #Null And setupBuffer = #False
                                    ;    ValidateRect_(chwnd, 0)
                                    ;EndIf
                                    If *ctrackWin\windowType = #WINDOWTYPE_SYSTAB And setupBuffer = #False
                                        RedrawWindow_(chwnd, 0, 0, #RDW_VALIDATE|#RDW_ALLCHILDREN)
                                    EndIf
                                    ;CopyStructure(wrc, *lrc, RECT)
                                    
                                    ;*ctrackWin\divertedRedraw = #False
                                EndIf
                                
                                ;brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
                                ;GetWindowRect_(chwnd, clrc.RECT)
                                ;MapWindowPoints_(0, divertedWindow, clrc, 2)
                                ;OffsetRgn_(rgn, clrc\left+frameXOffset, clrc\top+frameYOffset)
                                ;FillRgn_(dc, rgn, brush)
                                ;DeleteObject_(brush)
                                
                                If clprgn <> #Null
                                    DeleteObject_(clprgn)
                                    clprgn = #Null
                                EndIf
                                If crgn <> #Null
                                    DeleteObject_(crgn)
                                    crgn = #Null
                                EndIf
                                If frgn <> #Null
                                    DeleteObject_(frgn)
                                    frgn = #Null
                                EndIf
                                If rgn <> #Null
                                    DeleteObject_(rgn)
                                    rgn = #Null
                                EndIf
                                
                            Else
                                *ctrackWin\divertedRefresh = #False
                            EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetClientRect_(chwnd, rc.RECT)
                                MapWindowPoints_(chwnd, divertedWindow, rc, 2)
                                
                                ;SelectObject_(*ctrackWin\divertedDC, ImageID(*ctrackWin\divertedBuffer))
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 1, 1)
                                If *ctrackWin\windowType = #WINDOWTYPE_TOOLBAREX
                                    ;debugbuffer(*ctrackWin\divertedBuffer, 1, 1)
                                EndIf
                                
                                ;debuglog("x: " + Str(pt\x) + " y: " + Str(pt\y))
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left, crc\top, #SRCCOPY)
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, crc\left, crc\top, #SRCCOPY)
                                
                                If *ctrackWin\divertedWinBuffer <> #Null
                                    ;debugbuffer(*ctrackWin\divertedWinBuffer, 1, 1)
                                    If *ctrackWin\windowType = #WINDOWTYPE_TREEVIEW
                                        ;debugbuffer(*ctrackWin\divertedWinBuffer, 1, 1)
                                    EndIf
                                    
                                    crc\left + frameXOffset
                                    crc\top + frameYOffset
                                    crc\right + frameXOffset
                                    crc\bottom + frameYOffset
                                    GetWindowRect_(chwnd, rc.RECT)
                                    MapWindowPoints_(0, divertedWindow, rc, 2)
                                    sdc = SaveDC_(dc)
                                    GetClientRect_(chwnd, clrc.RECT)
                                    crc\right + 1
                                    MapWindowPoints_(chwnd, divertedWindow, clrc, 2)
                                    crgn = CreateRectRgnIndirect_(clrc)
                                    crc\right - 1
                                    GetWindowOrgEx_(dc, pt.POINT)
                                    OffsetRgn_(crgn, -pt\x, -pt\y)
                                    ExtSelectClipRgn_(dc, crgn, #RGN_XOR)
                                    BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedWinDC, crc\left, crc\top, #SRCCOPY)
                                    RestoreDC_(dc, sdc)
                                    DeleteObject_(crgn)
                                    crgn = #Null
                                    
                                EndIf
                                
;                                 brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                                 trc.RECT
;                                 trc\left = rc\left
;                                 trc\top = rc\top
;                                 trc\right = rc\right
;                                 trc\bottom = rc\bottom
;                                 FillRect_(dc, trc, brush)
;                                 DeleteObject_(brush)
                                
;                                 brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
;                                 trc.RECT
;                                 trc\left = crc\left
;                                 trc\top = crc\top
;                                 trc\right = crc\right
;                                 trc\bottom = crc\bottom
;                                 FillRect_(*ctrackWin\divertedDC, trc, brush)
;                                 DeleteObject_(brush)
                                
                                ;brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
                                ;CopyStructure(*clipRc, trc.RECT, RECT)
                                ;GetClipBox_(dc, trc.RECT)
                                ;FillRect_(dc, trc, brush)
                                ;DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                
                            EndIf
                            
                    EndSelect
                    
                    ; render caret if set
                    If caret\hwnd = *ctrackWin\hwnd And caret\show = #True And caret\render = #True
                        CopyStructure(caret\pos, pt.POINT, POINT)
                        MapWindowPoints_(caret\hwnd, divertedWindow, pt, 1)
                        sdc = SaveDC_(dc)
                        brush = GetStockObject_(#BLACK_BRUSH)
                        SelectObject_(dc, brush)
                        PatBlt_(dc, pt\x, pt\y, caret\width, caret\height, #DSTINVERT)
                        RestoreDC_(dc, sdc)
                    EndIf
                    
                    If *ctrackWin\windowType <> #WINDOWTYPE_PANELEX And *ctrackWin\windowType <> #WINDOWTYPE_PANELEXPAGE And *ctrackWin\divertedRefresh = #False
                        GetClientRect_(*ctrackWin\hwnd, rc.RECT)
                        MapWindowPoints_(*ctrackWin\hwnd, divertedWindow, rc, 2)
                        CopyStructure(*clipRc, newclipRc.RECT, RECT)
                        IntersectRect_(newclipRc, rc, newclipRc)
                        sdc = SaveDC_(dc)
                        IntersectClipRect_(dc, newclipRc\left, newclipRc\top, newclipRc\right, newclipRc\bottom)
                        renderPanelexPageChildren(*ctrackWin, divertedWindow, dc, newclipRc)
                        RestoreDC_(dc, sdc)
                    EndIf
                    
                    *ctrackWin\divertedRedraw = #False
                    
                EndIf
                    
            EndIf
        
        EndIf
            
        chwnd = GetWindow_(chwnd, #GW_HWNDNEXT)
        
    Wend
    
EndProcedure

Procedure renderPanelexScrollbars(*trackWin.trackWindows, *panelexpage.panelexpages, divertedWindow, dc)
    
    root = *trackWin\rootPanelexPageHwnd
    *rpanelex.panelexs = *trackWin\rootPanelex
    
    GetClipBox_(dc, clipRc.RECT)
    
    chwnd = GetWindow_(*trackWin\hwnd, #GW_CHILD)
    While chwnd <> #Null
        
        *ctrackWin.trackWindows = GetProp_(chwnd, trackwinAtom)
        If *ctrackWin <> #Null
            
            If *ctrackWin\visible = #True
                
                GetWindowRect_(chwnd, rc.RECT)
                MapWindowPoints_(0, root, rc, 2)
                
                If IntersectRect(clipRc, rc) And RectVisible_(dc, rc) And rectInPanelExUpdateRect(*rpanelex, rc)
                
                    Select *ctrackWin\windowType
                            
                        Case #WINDOWTYPE_SYSSCROLLBAR    
                            
                            GetWindowRect_(chwnd, crc.RECT)
                            MapWindowPoints_(0, root, crc, 2)
                            IntersectRect_(crc, crc, clipRc)
                            MapWindowPoints_(root, chwnd, crc, 2)
                            
                            redraw = #False
                            If *ctrackWin\divertedClipRgn <> #Null
                                GetRgnBox_(*ctrackWin\divertedClipRgn, drc.RECT)
                                IntersectRect_(trc.RECT, crc, drc)
                                If Not (trc\left = crc\left And trc\top = crc\top And trc\right = crc\right And trc\bottom = crc\bottom)
                                    redraw = #True
                                EndIf
                            Else
                                redraw = #True
                            EndIf
                            
                            If *ctrackWin\divertedRefresh = #False
                                
                                If redraw = #True Or *panelexpage\renderScrollbars = #True
                                    
                                    ;debuglog("redraw "+Str(Random(255)))
    
                                    *ctrackWin\divertedRedraw = #True
                                    RedrawWindow_(chwnd, crc, 0, #RDW_UPDATENOW|#RDW_INVALIDATE|#RDW_NOERASE)
                                    *ctrackWin\divertedRedraw = #False
    
                                    rendered = #True
                                    
                                EndIf
                                
                            Else
                                *ctrackWin\divertedRefresh = #False
                            EndIf
                            
                            If *ctrackWin\divertedBuffer <> #Null
                                
                                GetWindowRect_(chwnd, rc.RECT)
                                MapWindowPoints_(0, divertedWindow, rc, 2)
                                
                                ;fillAlphaChannel(*ctrackWin\divertedDC, *ctrackWin\divertedBuffer, 255)
                                
                                blend = $1000000 | 255<<16
                                ;GdiAlphaBlend_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, rc\right-rc\left, rc\bottom-rc\top, blend) ; $ 1FF0000
                                ;debugbuffer(*ctrackWin\divertedBuffer, 1, 1)
                                BitBlt_(dc, rc\left+crc\left, rc\top+crc\top, crc\right-crc\left, crc\bottom-crc\top, *ctrackWin\divertedDC, crc\left, crc\top, #SRCCOPY)
                                
                                ;brush = CreateSolidBrush_(RGB(100+Random(155), 0, 0))
                                ;trc.RECT
                                ;trc\left = rc\left
                                ;trc\top = rc\top
                                ;trc\right = rc\right
                                ;trc\bottom = rc\bottom
                                ;FillRect_(dc, trc, brush)
                                ;DeleteObject_(brush)
                                
                                ;BitBlt_(dc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *ctrackWin\divertedDC, 0, 0, #SRCCOPY)
                                
                            EndIf
                       
                    EndSelect
                    
                EndIf
                    
            EndIf
        
        EndIf
            
        chwnd = GetWindow_(chwnd, #GW_HWNDNEXT)
        
    Wend
    
    ; render scrollbar box if both horizontal and vertical scrollbars are visible
    If *panelexpage\hScrollVisible = #True And *panelexpage\vScrollVisible = #True
        GetClientRect_(*panelexpage\containerHandle, prc.RECT)
        rc.RECT
        rc\left = prc\right - iHThumb
        rc\top = prc\bottom - iVThumb
        rc\right = prc\right
        rc\bottom = prc\bottom
        MapWindowPoints_(*panelexpage\containerHandle, divertedWindow, rc, 2)
        If IntersectRect(clipRc, rc) And RectVisible_(dc, rc) And rectInPanelExUpdateRect(*rpanelex, rc)
            IntersectRect_(rc, rc, clipRc)
            FillRect_(dc, rc, GetSysColorBrush_(#COLOR_3DFACE))
        EndIf
    EndIf
    
    If rendered = #True
        *panelexpage\renderScrollbars = #False
    EndIf
    
EndProcedure

Procedure PanelExCallback(hwnd, message, wParam, lParam)
    
    ; get associated panel structure pointer from hwnd
    *panelex.panelexs = GetProp_(hwnd, panelexAtom)
    If *panelex = #Null
        ProcedureReturn DefWindowProc_(hwnd, message, wParam, lParam)
    EndIf
    
    *panelexpage.panelexpages = *panelex\displayedPage
    If *panelexpage = #Null And message <> #WM_NCDESTROY And message <> #WM_DESTROY And message <> #WM_NCCREATE And message <> #WM_CREATE
        ProcedureReturn DefWindowProc_(hwnd, message, wParam, lParam)
    EndIf
    
    Select message
        
        Case #WM_NCCREATE, #WM_CREATE
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, hwnd, message, wParam, lParam)
            EndIf
            
        Case #WM_DESTROY
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, hwnd, message, wParam, lParam)
            EndIf
            
            *panelex\destroying = #True
            
        Case #WM_NCDESTROY
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, hwnd, message, wParam, lParam)
            EndIf
            
            RemoveProp_(hwnd, panelexAtom)
            
            If *panelex\backgroundBitmap <> #Null And IsImage(*panelex\backgroundBitmap)
                FreeImage(*panelex\backgroundBitmap)
                DeleteDC_(*panelex\backgroundDC)
            EndIf
            
            If *panelex\alphaBitmap <> #Null And IsImage(*panelex\alphaBitmap)
                FreeImage(*panelex\alphaBitmap)
                DeleteDC_(*panelex\alphaDC)
            EndIf
            
            If *panelex\updateRgn <> #Null
                DeleteObject_(*panelex\updateRgn)
            EndIf
            
            freeUniqueID(*panelex\id)
            
            FreeStructure(*panelex)
        
        Case #WM_REFRESHPANELEX
            
            debuglog("#WM_REFRESHPANELEX")
            RefreshPanelEx(hwnd)
            
        Case #WM_ANIMATEREDRAW
            
            ;RedrawWindow_(*panelexpage\Handle, 0, *panelex\updateRgn, #RDW_UPDATENOW|#RDW_NOERASE|#RDW_INVALIDATE)
            ;RedrawWindow_(*panelexpage\Handle, 0, *panelex\updateRgn, #RDW_NOERASE|#RDW_INVALIDATE)
            ;debuglog("#WM_ANIMATEREDRAW")
            ;LockMutex(updateMutex)
            updatePanelexChildren(*panelex)
            dc = GetDC_(*panelexpage\Handle)
            SelectClipRgn_(dc, *panelex\updateRgn)
            drawPanelPage(*panelexpage, dc, *panelexpage\Handle, 0, 0)
            ReleaseDC_(*panelexpage\Handle, dc)
            ;updatePanelexChildren(*panelex)
            
            If *panelex\updateCount > 0
                *panelex\updateCount - 1
            Else
                If *panelex\updateRgn <> #Null
                    oldUpdateRgn = *panelex\updateRgn
                    *panelex\updateRgn = CreateRectRgn_(0, 0, 0, 0)
                    DeleteObject_(oldUpdateRgn)
                    ClearList(*panelex\updateRc())
                    ClearList(*panelex\updateChild())
                EndIf
            EndIf
            
            ;UnlockMutex(updateMutex)
            
        Case #WM_THEMECHANGED
            
            If XPthemeActive <> #Null
                
                CallFunctionFast(*CloseThemeData, hThemeExplorerbar)
                CallFunctionFast(*CloseThemeData, hThemeRebar)
                CallFunctionFast(*CloseThemeData, hThemeTab)
                CallFunctionFast(*CloseThemeData, hThemeToolbar)
                CallFunctionFast(*CloseThemeData, hThemeMenu)
                CallFunctionFast(*CloseThemeData, hThemeButton)
                hwnd = GetForegroundWindow_()
                hThemeExplorerbar = OpenThemeData(hwnd, "explorerbar")
                If hThemeExplorerbar <> #Null
                    hThemeRebar = OpenThemeData(hwnd, "rebar")
                    hThemeTab = OpenThemeData(hwnd, "tab")
                    hThemeToolbar = OpenThemeData(hwnd, "toolbar")
                    hThemeMenu = OpenThemeData(hwnd, "menu")
                    hThemeButton = OpenThemeData(hwnd, "button")
                    ThemesEnabled = #True
                Else
                    ThemesEnabled = #False
                EndIf
                
            Else
                hThemeExplorerbar = #Null
                hThemeRebar = #Null
                hThemeTab = #Null
                hThemeToolbar = #Null
                hThemeMenu = #Null
                hThemeButton = #Null
                ThemesEnabled = #False
                InitXPtheme()
            EndIf
            
            UpdateSkins(0)
            
            *trackWin.trackWindows = *panelexpage\trackWin
            If *trackWin <> #Null
                If *panelex = *trackWin\rootPanelex
                    RefreshPanelEx(*panelex\Handle, 0, #PNLX_ERASEALLCHILDREN | #PNLX_UPDATESCROLLING)
                EndIf
            EndIf
            
        Case #WM_SETREDRAW
            
            *trackWin.trackWindows = *panelexpage\trackWin
            If *trackWin <> #Null
                *rpanelex.panelexs = *trackWin\rootPanelex
                If *rpanelex <> #Null
                    If wParam = #False
                        *rpanelex\setRedrawFalse = #True
                    Else
                        *rpanelex\setRedrawFalse = #False
                    EndIf
                EndIf
            EndIf
            
        Case #WM_PAINT
            
            BeginPaint_(hwnd, @ps.PAINTSTRUCT)
            EndPaint_(hwnd, @ps)
            
            ProcedureReturn 0
            
        Case #WM_ERASEBKGND
            
            ProcedureReturn 1
         
        Case #WM_SIZE
            
            *trackWin.trackWindows = *panelexpage\trackWin
            If *trackWin <> #Null
            
                ; resize panelex page window
                If *panelexpage\autoScroll = #False
                    GetClientRect_(hwnd, rc.RECT)
                    If *panelex\lastClientRc\right <> rc\right Or *panelex\lastClientRc\bottom <> rc\bottom
                        SetWindowPos_(*panelexpage\handle, 0, 0, 0, rc\right, rc\bottom, #SWP_NOACTIVATE|#SWP_NOOWNERZORDER|#SWP_NOZORDER|#SWP_NOCOPYBITS|#SWP_NOREDRAW|#SWP_NOMOVE)
                        *panelex\lastClientRc\right = rc\right
                        *panelex\lastClientRc\bottom = rc\bottom
                    EndIf
                Else
                    updatePanelExPageScrolling(*panelexpage, 0, 0)
                EndIf
                
                If *panelex\usercallback <> #Null
                    CallWindowProc_(*panelex\usercallback, hwnd, message, wParam, lParam)
                EndIf
                
                If *panelexpage\autoScroll = #True
                    RefreshPanelEx(*panelex\Handle, 0, #PNLX_NOREDRAW|#PNLX_UPDATESCROLLING) ; only update scrolling
                EndIf
                
                If *trackWin\rootPanelexPageHwnd = *panelexpage\Handle
                    
                    RefreshPanelEx(*panelex\Handle) ; only validate and redraw
                    
                EndIf
                
            EndIf
            
        Case #WM_WINDOWPOSCHANGING
            
            If *panelex\usercallback <> #Null
                RET = CallWindowProc_(*panelex\usercallback, hwnd, message, wParam, lParam)
                If RET <> 0
                    ProcedureReturn RET
                EndIf
            EndIf
            
        Case #WM_NOTIFY
            
            Result = SendMessage_(GetParent_(hwnd),message,wParam,lParam)
            
        Case #WM_NCHITTEST
            
            Result = #HTTRANSPARENT
            
        Case #WM_HSCROLL
            
            If lParam = *panelexpage\hScrollBar And *panelexpage\autoScroll = #True
                
                ;/ scroll bar thumb moved
                If LOWORD(wParam) = #SB_THUMBPOSITION Or LOWORD(wParam) = #SB_THUMBTRACK
                    
                    pos = HIWORD(wParam)  ; get position of thumb in scrollbar
                    
                    ; scroll page by x offset
                    updatePanelExPageScrolling(*panelexpage, *panelexpage\lastHscrollPos - pos, 0)
                    
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos = pos
                    
                    If LOWORD(wParam) = #SB_THUMBPOSITION
                        SetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, scinfo, #False)
                    Else
                        SetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, scinfo, #True)
                    EndIf
                    
                    *panelexpage\lastHscrollPos = pos
                    
                ;/ left scrollbar arrow button pressed
                ElseIf LOWORD(wParam) = #SB_LINELEFT
                    
                    If *panelexpage\hScrollLineAmount = 0
                        amount = #HSCROLL_LINEAMOUNT
                    Else
                        amount = *panelexpage\hScrollLineAmount
                    EndIf
                    
                    ; make sure amount doesn't negative passed min scrollbar range
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS|#SIF_RANGE
                    GetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo)
                    pos = scinfo\nPos
                    
                    If pos-amount < scinfo\nMin
                        amount - Abs(scinfo\nPos-amount)
                    EndIf
                    
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos - amount
                    SetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo, #True)
                    
                    If amount > 0
                        
                        ; scroll page by x offset
                        updatePanelExPageScrolling(*panelexpage, amount, 0)
                        *panelexpage\lastHscrollPos - amount
                        
                    EndIf
                    
                ;/ right scrollbar arrow button pressed
                ElseIf LOWORD(wParam) = #SB_LINERIGHT
                    
                    If *panelexpage\hScrollLineAmount = 0
                        amount = #HSCROLL_LINEAMOUNT
                    Else
                        amount = *panelexpage\hScrollLineAmount
                    EndIf
                    
                    ; make sure amount doesn't go passed scrollbar max range
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS|#SIF_RANGE
                    GetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo)
                    pos = scinfo\nPos
                    
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos = pos + amount
                    SetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo, #True)
                    GetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo)
                    amount = scinfo\nPos-pos
                    
                    If amount > 0
                        
                        ; scroll page by x offset
                        updatePanelExPageScrolling(*panelexpage, -amount, 0)
                        *panelexpage\lastHscrollPos + amount
                        
                    EndIf
                    
                ;/ scroll to left edge
                ElseIf LOWORD(wParam) = #SB_LEFT
                    
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_RANGE
                    GetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo)
                    
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos = scinfo\nMin
                    SetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo, #True)
                    amount = *panelexpage\lastHscrollPos-scinfo\nMin
                    
                    If amount > 0
                        
                        ; scroll page by x offset
                        updatePanelExPageScrolling(*panelexpage, amount, 0)
                        
                        *panelexpage\lastHscrollPos = scinfo\nMin
                        
                    EndIf
                    
                ;/ scroll to right edge
                ElseIf LOWORD(wParam) = #SB_RIGHT
                    
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS|#SIF_RANGE
                    GetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo)
                    pos = scinfo\nPos
                    
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos = scinfo\nMax
                    SetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo, #True)
                    GetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo)
                    amount = scinfo\nPos-pos
                    
                    If amount > 0
                        
                        ; scroll page by x offset
                        updatePanelExPageScrolling(*panelexpage, -amount, 0)
                        
                        *panelexpage\lastHscrollPos = scinfo\nPos
                        
                    EndIf
                    
                ;/ scroll page left
                ElseIf LOWORD(wParam) = #SB_PAGELEFT
                    
                    ; make sure amount doesn't negative passed min scrollbar range
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS|#SIF_RANGE|#SIF_PAGE
                    GetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo)
                    amount = scinfo\nPage
                    If scinfo\nPos-amount < scinfo\nMin
                        amount = amount - Abs(scinfo\nPos-amount)
                    EndIf
                    
                    If amount > 0
                        
                        ; scroll page by x offset
                        updatePanelExPageScrolling(*panelexpage, amount, 0)
                        
                        *panelexpage\lastHscrollPos = *panelexpage\lastHscrollPos - amount
                        scinfo\fMask = #SIF_POS
                        scinfo\nPos = *panelexpage\lastHscrollPos
                        SetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo, #True)
                        
                    EndIf
                    
                ;/ scroll page right
                ElseIf LOWORD(wParam) = #SB_PAGERIGHT
                    
                    ; make sure amount doesn't go passed scrollbar max range
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS|#SIF_RANGE|#SIF_PAGE
                    GetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo)
                    pos = scinfo\nPos
                    amount = scinfo\nPage
                    
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos = pos + amount
                    SetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo, #True)
                    GetScrollInfo_(*panelexpage\hScrollBar, #SB_CTL, @scinfo)
                    amount = scinfo\nPos-pos
                    
                    If amount > 0
                        
                        ; scroll page by x offset
                        updatePanelExPageScrolling(*panelexpage, -amount, 0)
                        
                        *panelexpage\lastHscrollPos = *panelexpage\lastHscrollPos + amount
                        
                    EndIf
                    
                EndIf
                
                RefreshPanelEx(*panelex\handle)
                
            EndIf
            
        Case #WM_VSCROLL
            
            If lParam = *panelexpage\vScrollBar And *panelexpage\autoScroll = #True
                
                ;/ scroll bar thumb moved
                If LOWORD(wParam) = #SB_THUMBPOSITION Or LOWORD(wParam) = #SB_THUMBTRACK
                    
                    pos = HIWORD(wParam)  ; get position of thumb in scrollbar
                    
                    ; scroll page by y offset
                    updatePanelExPageScrolling(*panelexpage, 0, *panelexpage\lastVscrollPos - pos)
                    
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos = pos
                    
                    If LOWORD(wParam) = #SB_THUMBPOSITION
                        SetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, scinfo, #False)
                    Else
                        SetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, scinfo, #True)
                    EndIf
                    
                    *panelexpage\lastVscrollPos = pos
                    
                ;/ top scrollbar arrow button pressed
                ElseIf LOWORD(wParam) = #SB_LINEUP
                    
                    If *panelexpage\vScrollLineAmount = 0
                        amount = #VSCROLL_LINEAMOUNT
                    Else
                        amount = *panelexpage\vScrollLineAmount
                    EndIf
                    
                    ; make sure amount doesn't negative passed min scrollbar range
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS|#SIF_RANGE
                    GetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo)
                    
                    If scinfo\nPos-amount < scinfo\nMin
                        amount - Abs(scinfo\nPos-amount)
                    EndIf
                    
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos - amount
                    SetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo, #True)
                    
                    If amount > 0
                        
                        ; scroll page by y offset
                        updatePanelExPageScrolling(*panelexpage, 0, amount)
                        *panelexpage\lastVscrollPos - amount
                        
                    EndIf
                    
                ;/ bottom scrollbar arrow button pressed
                ElseIf LOWORD(wParam) = #SB_LINEDOWN
                    
                    If *panelexpage\vScrollLineAmount = 0
                        amount = #VSCROLL_LINEAMOUNT
                    Else
                        amount = *panelexpage\vScrollLineAmount
                    EndIf
                    
                    ; make sure amount doesn't go passed scrollbar max range
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS|#SIF_RANGE
                    GetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo)
                    pos = scinfo\nPos
                    
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos = pos + amount
                    SetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo, #True)
                    GetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo)
                    amount = scinfo\nPos-pos
                    
                    If amount > 0
                        
                        ; scroll page by y offset
                        updatePanelExPageScrolling(*panelexpage, 0, -amount)
                        *panelexpage\lastVscrollPos + amount
                        
                    EndIf
                    
                ;/ scroll to top edge
                ElseIf LOWORD(wParam) = #SB_TOP
                    
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_RANGE
                    GetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo)
                    
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos = scinfo\nMin
                    SetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo, #True)
                    amount = *panelexpage\lastVscrollPos-scinfo\nMin
                    
                    If amount > 0
                        
                        ; scroll page by y offset
                        updatePanelExPageScrolling(*panelexpage, 0, amount)
                        
                        *panelexpage\lastVscrollPos = scinfo\nMin
                        
                    EndIf
                    
                ;/ scroll to bottom edge
                ElseIf LOWORD(wParam) = #SB_BOTTOM
                    
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS|#SIF_RANGE
                    GetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo)
                    pos = scinfo\nPos
                    
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos = scinfo\nMax
                    SetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo, #True)
                    GetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo)
                    amount = scinfo\nPos-pos
                    
                    If amount > 0
                        
                        ; scroll page by y offset
                        updatePanelExPageScrolling(*panelexpage, 0, -amount)
                        
                        *panelexpage\lastVscrollPos = scinfo\nPos
                        
                    EndIf
                    
                ;/ scroll page up
                ElseIf LOWORD(wParam) = #SB_PAGEUP
                    
                    ; make sure amount doesn't negative passed min scrollbar range
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS|#SIF_RANGE|#SIF_PAGE
                    GetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo)
                    amount = scinfo\nPage
                    If scinfo\nPos-amount < scinfo\nMin
                        amount = amount - Abs(scinfo\nPos-amount)
                    EndIf
                    
                    If amount > 0
                        
                        ; scroll page by y offset
                        updatePanelExPageScrolling(*panelexpage, 0, amount)
                        
                        *panelexpage\lastVscrollPos = *panelexpage\lastVscrollPos - amount
                        scinfo\fMask = #SIF_POS
                        scinfo\nPos = *panelexpage\lastVscrollPos
                        SetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo, #True)
                        
                    EndIf
                    
                ;/ scroll page down
                ElseIf LOWORD(wParam) = #SB_PAGEDOWN
                    
                    ; make sure amount doesn't go passed scrollbar max range
                    scinfo.SCROLLINFO
                    scinfo\cbSize = SizeOf(SCROLLINFO)
                    scinfo\fMask = #SIF_POS|#SIF_RANGE|#SIF_PAGE
                    GetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo)
                    pos = scinfo\nPos
                    amount = scinfo\nPage
                    
                    scinfo\fMask = #SIF_POS
                    scinfo\nPos = pos + amount
                    SetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo, #True)
                    GetScrollInfo_(*panelexpage\vScrollBar, #SB_CTL, @scinfo)
                    amount = scinfo\nPos-pos
                    
                    If amount > 0
                        
                        ; scroll page by y offset
                        updatePanelExPageScrolling(*panelexpage, 0, -amount)
                        
                        *panelexpage\lastVscrollPos = *panelexpage\lastVscrollPos + amount
                        
                    EndIf
                    
                EndIf
                
                RefreshPanelEx(*panelex\handle)
                
            EndIf
            
        Default
            
            Result = DefWindowProc_(hwnd, message, wParam, lParam)
            
    EndSelect
    
    ProcedureReturn Result
    
EndProcedure

#PixelFormat32bppARGB = $26200A ; private
#PixelFormat32bppPARGB = 925707 ; private
Procedure.i gBufferImage(*ImageID)
    Protected *bitmap, bmp.BITMAP, pixelformat
    
    If InitGDIPlus() <> 0
        
        If IsImage(*ImageID) : *ImageID = ImageID(*ImageID) : EndIf
        If GetObject_(*ImageID,SizeOf(BITMAP),@bmp)
            
            If bmp\bmBitsPixel = 32
                CallFunctionFast(*GdipCreateBitmapFromScan0, bmp\bmWidth, bmp\bmHeight, 4*bmp\bmWidth, #PixelFormat32bppARGB, bmp\bmBits, @*bitmap)
            Else
                CallFunctionFast(*GdipCreateBitmapFromHBITMAP, *ImageID, 0, @*bitmap)
            EndIf
            
            If *bitmap
                CallFunctionFast(*GdipImageRotateFlip,*bitmap,6)
                
                ProcedureReturn *bitmap
                
            EndIf
        EndIf
        
    EndIf
    
EndProcedure

Procedure Get32BitColors(pBitmap) 
    
    GetObject_(pBitmap, SizeOf(BITMAP), @bmp.BITMAP) 
    *bmi.BITMAPINFO = AllocateMemory(SizeOf(BITMAPINFO)+SizeOf(RGBQUAD)*255)
    With *bmi\bmiHeader
        \biSize         = SizeOf(BITMAPINFOHEADER) 
        \biWidth        = bmp\bmWidth 
        \biHeight       = -bmp\bmHeight 
        \biPlanes       = 1 
        \biBitCount     = 32 
    EndWith 
    hDC = GetWindowDC_(#Null) 
    GetDIBits_(hDC, pBitmap, 0, bmp\bmHeight, #Null, *bmi, #DIB_RGB_COLORS)
    *pPixels = AllocateMemory(*bmi\bmiHeader\biSizeImage)
    iRes = GetDIBits_(hDC, pBitmap, 0, bmp\bmHeight, *pPixels, *bmi, #DIB_RGB_COLORS) 
    ReleaseDC_(#Null, hDC) 
    FreeMemory(*bmi)
    ProcedureReturn *pPixels 
    
EndProcedure 

Procedure fillAlphaChannel(hdc, bitmap, Alpha.a)
    
    GetObject_(bitmap, SizeOf(BITMAP), @BM.BITMAP)
    width = BM\bmWidth
    height = BM\bmHeight
    
    If width > 0 And height > 0
        
        bitcount = BM\bmBitsPixel
        extrabytesperrow = (4 - (width * bitcount / 8) % 4) % 4
        sizeheaders = SizeOf(BITMAPFILEHEADER) + SizeOf(BITMAPINFOHEADER)
        sizeimage = (width * bitcount / 8 + extrabytesperrow) * height
        *bitmap = AllocateMemory(sizeheaders + sizeimage)
        
        *bitmapfile.BITMAPFILEHEADER = *bitmap
        *bitmapfile\bfType = Asc("B") + Asc("M") << 8
        *bitmapfile\bfSize = sizeheaders +sizeimage
        *bitmapfile\bfOffBits = sizeheaders
        *bitmapinfo.BITMAPINFOHEADER = *bitmap + SizeOf(BITMAPFILEHEADER)
        *bitmapinfo\biSize = SizeOf(BITMAPINFOHEADER)
        *bitmapinfo\biWidth = width
        *bitmapinfo\biHeight = height
        *bitmapinfo\biPlanes = 1
        *bitmapinfo\biBitCount = bitcount
        *bitmapinfo\biCompression = 0
        *bitmapinfo\biSizeImage = sizeimage
        
        *bitmapdata = *bitmap + sizeheaders
        
        *bitmapdatapos = *bitmapdata
        
        GetDIBits_(hdc, bitmap, 0, height, *bitmap+sizeheaders, *bitmapinfo, #DIB_RGB_COLORS)
        
        For y = 0 To height - 1
            For x = 0 To width - 1
                
                a.a = PeekB(*bitmapdatapos + 3)
                If a = 0
                    PokeB(*bitmapdatapos + 3, Alpha)
                EndIf
                
                *bitmapdatapos + bitcount / 8
            Next
            *bitmapdatapos + extrabytesperrow
        Next
        
        SetDIBits_(hdc, bitmap, 0, height, *bitmap+sizeheaders, *bitmapinfo, #DIB_RGB_COLORS)
        
        FreeMemory(*bitmap)
        
    EndIf
    
EndProcedure

Structure debugBuffer
    window.i
    x.i
    y.i
EndStructure

Procedure debugBuffer(buffer, multiWin = 0, noAlpha = 0)
    Static NewMap dbg.debugBuffer()
    Static window
    
    If buffer = #Null
        ProcedureReturn #False
    EndIf
    
    If multiWin = #True
        *dbg.debugBuffer = FindMapElement(dbg(), Str(buffer))
        If *dbg = #Null
            *dbg = AddMapElement(dbg(), Str(buffer))
            window = #Null
        Else
            window = *dbg\window
        EndIf
    EndIf
    
    width = ImageWidth(buffer)
    height = ImageHeight(buffer)
    
    If window = #Null
        window = OpenWindow(#PB_Any, 0, 0, width, height, "Debug buffer")
    Else
        ResizeWindow(window, #PB_Ignore, #PB_Ignore, width, height)
    EndIf
    
    If noAlpha = #True
        timg = CreateImage(#PB_Any, width, height, 32)
        StartDrawing(ImageOutput(timg))
        DrawingMode(#PB_2DDrawing_AllChannels)
        DrawImage(ImageID(buffer), 0, 0)
        DrawingMode(#PB_2DDrawing_AlphaChannel)
        Box(0, 0, width, height, RGBA(0, 0, 0, 255))
        StopDrawing()
    EndIf
    
    StartDrawing(WindowOutput(window))
    DrawingMode(#PB_2DDrawing_AllChannels)
    Box(0, 0, width, height, RGBA(0, 0, 0, 255))
    If noAlpha = #False
        DrawAlphaImage(ImageID(buffer), 0, 0)
    Else
        DrawAlphaImage(ImageID(timg), 0, 0)
        FreeImage(timg)
    EndIf
    StopDrawing()
    
    If *dbg <> #Null
        *dbg\window = window
    EndIf
    
EndProcedure

Procedure upper_power_of_two(v)
  v-1
  v | v >> 1
  v | v >> 2
  v | v >> 4
  v | v >> 8
  v | v >> 16
  v+1
  ProcedureReturn v
EndProcedure

;-
Procedure drawPanelPage(*panelexpage.panelexpages, dc, Window, divertedWindow, inAlpha)
    
    *panelex.panelexs = *panelexpage\panelex
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ; if dontdraw is set to false then check that were not in a panelex
    ; and set to true if so and exit - dont want to set up un-needed buffers and extra drawing
    If *panelexpage\dontdraw = 0
        
        *trackWin.trackWindows = *panelex\trackWin
        If *panelex <> *trackWin\rootPanelex
        
            debuglog("dontdraw false and in panelex")
            
            ; check if any buffers have already been allocated and free if so (don't need them if in nested panelex)
            ; this might happen if a panelex is moved into a panelex!
            If *panelex\backgroundBitmap <> #Null
                debuglog("free un-used buffers! panelex: "+Str(*panelex\Handle))
                FreeImage(*panelex\backgroundBitmap)
                DeleteDC_(*panelex\backgroundDC)
                *panelex\backgroundDC = #Null
                *panelex\backgroundBitmap = #Null
            EndIf
            
            If *panelex\updateRgn <> #Null
                DeleteObject_(*panelex\updateRgn)
                *panelex\updateRgn = #Null
            EndIf
            
            *panelexpage\dontdraw = #True
            
            ProcedureReturn #False
            
        EndIf
    
    EndIf
    
    ;debuglog("page: " + Str(*panelexpage\Handle))
    
    ; if we don't need to divert drawing then set divertedWindow to this window
    If divertedWindow = 0
        
        topPanelEx = #True ; this is the top most PanelEx
        divertedWindow = Window
       
    EndIf
    
    originaldc = dc
    thisdc = dc
    
    ; set the window to the panelex container window to use container rect coords/dimensions
    containerHwnd = *panelexpage\containerHandle
    GetClientRect_(containerHwnd, @rec.RECT)
    
    If topPanelEx = #True
        MapWindowPoints_(containerHwnd, Window, @rec, 2)
    EndIf
    Window = containerHwnd
    
    If *panelexpage\dontdraw = 0
        
        ; setup background buffer
        If *panelex\backgroundBitmap = #Null Or (rec\right-rec\left) > *panelex\backgroundWidth Or (rec\bottom-rec\top) > *panelex\backgroundHeight
            
            debuglog("setting up panelex buffer in : "+Str(*panelex\handle))
            
            If *panelex\backgroundBitmap <> #Null
                FreeImage(*panelex\backgroundBitmap)
                DeleteDC_(*panelex\backgroundDC)
            EndIf
            
            If (rec\right-rec\left) > *panelex\backgroundWidth
                *panelex\backgroundWidth = upper_power_of_two(rec\right-rec\left)
                If *panelex\backgroundWidth > iCXMaxTrack And (rec\right-rec\left) <= iCXMaxTrack
                    *panelex\backgroundWidth = iCXMaxTrack
                EndIf
            EndIf
            
            If (rec\bottom-rec\top) > *panelex\backgroundHeight
                *panelex\backgroundHeight = upper_power_of_two(rec\bottom-rec\top)
                If *panelex\backgroundHeight > iCYMaxTrack And (rec\bottom-rec\top) <= iCYMaxTrack
                    *panelex\backgroundHeight = iCYMaxTrack
                EndIf
            EndIf
            
            *panelex\backgroundBitmap = CreateImage(#PB_Any, *panelex\backgroundWidth, *panelex\backgroundHeight, 32)
            *panelex\backgroundDC = CreateCompatibleDC_(dc)
            SelectObject_(*panelex\backgroundDC, ImageID(*panelex\backgroundBitmap))
            
            debuglog("width: "+Str(*panelex\backgroundWidth)+" height: "+Str(*panelex\backgroundHeight))
            
        EndIf
        
        dc = *panelex\backgroundDC
        
    ElseIf *panelexpage\dontdraw = 2
        
        MapWindowPoints_(Window, divertedWindow, @rec, 2)
        
    EndIf
    
    ; subtract scrollbars from rect if visible
    If *panelexpage\vScrollVisible
        GetClientRect_(*panelexpage\vScrollBar, @trc.RECT)
        rec\right - trc\right
    EndIf
    If *panelexpage\hScrollVisible
        GetClientRect_(*panelexpage\hScrollBar, @trc.RECT)
        rec\bottom - trc\bottom
    EndIf
    
    ; if this is the top-most PanelEx then offset the buffer dc origin to the page scroll offset
    If topPanelEx = #True
        SetWindowOrgEx_(dc, rec\left, rec\top, 0)
        GetClipBox_(originaldc, clprc.RECT)
        CopyStructure(clprc, oclprc.RECT, RECT)
        IntersectRect_(clprc, clprc, rec)
        sscrolldc = SaveDC_(dc)
        IntersectClipRect_(dc, clprc\left, clprc\top, clprc\right, clprc\bottom)
    EndIf
    
    pageWidth = rec\right-rec\left
    pageHeight = rec\bottom-rec\top
    
    ; if page has alpha value then setup
    If *panelexpage\alpha < 255
        
        argn = CreateRectRgn_(0, 0, 0, 0)
        GetClipRgn_(dc, argn)
        
        GetWindowOrgEx_(dc, pnt.POINT)
        
        GetClipBox_(dc, clprc.RECT)
        clprc\left - rec\left
        clprc\top - rec\top
        clprc\right - rec\left
        clprc\bottom - rec\top
        
        alphaWidth = clprc\right-clprc\left
        alphaHeight = clprc\bottom-clprc\top
        
        If alphaWidth <= 0
            alphaWidth = 1
        EndIf
        
        If alphaHeight <= 0
            alphaHeight = 1
        EndIf
        
        ; setup alpha buffer
        If *panelex\alphaBitmap = #Null Or alphaWidth > *panelex\alphaWidth Or alphaHeight > *panelex\alphaHeight
            
            debuglog("setting up panelex alpha buffer in : "+Str(*panelex\handle))
            
            If *panelex\alphaBitmap <> #Null
                FreeImage(*panelex\alphaBitmap)
                DeleteDC_(*panelex\alphaDC)
            EndIf
            
            If alphaWidth > *panelex\alphaWidth
                *panelex\alphaWidth = upper_power_of_two(alphaWidth)
                If *panelex\alphaWidth > iCXMaxTrack And alphaWidth <= iCXMaxTrack
                    *panelex\alphaWidth = iCXMaxTrack
                EndIf
            EndIf
            
            If alphaHeight > *panelex\alphaHeight
                *panelex\alphaHeight = upper_power_of_two(alphaHeight)
                If *panelex\alphaHeight > iCYMaxTrack And alphaHeight <= iCYMaxTrack
                    *panelex\alphaHeight = iCYMaxTrack
                EndIf
            EndIf
            
            *panelex\alphaBitmap = CreateImage(#PB_Any, *panelex\alphaWidth, *panelex\alphaHeight, 32, #PB_Image_Transparent)
            *panelex\alphaDC = CreateCompatibleDC_(dc)
            SelectObject_(*panelex\alphaDC, ImageID(*panelex\alphaBitmap))
            
            debuglog("width: "+Str(*panelex\alphaWidth)+" height: "+Str(*panelex\alphaHeight))
            
        EndIf
        
        dc = *panelex\alphaDC

        ;StartDrawing(ImageOutput(*panelex\alphaBitmap))
        ;DrawingMode(#PB_2DDrawing_AllChannels)
        ;Box(0, 0, clprc\right-clprc\left, clprc\bottom-clprc\top, RGBA(255, 0, 0, 255))
        ;StopDrawing()
        
        SetWindowOrgEx_(dc, clprc\left, clprc\top, 0)
        SelectClipRgn_(dc, argn)
        OffsetClipRgn_(dc, pnt\x-rec\left-clprc\left, pnt\y-rec\top-clprc\top)
        
        divertedWindow = Window
        
        thisAlpha = #True
        inAlpha = #True
        ax = rec\left
        ay = rec\top
        rec\left = 0
        rec\top = 0
        rec\right = pageWidth
        rec\bottom = pageHeight
        
    EndIf
    
    ; check if background is a gradient
    If *panelexpage\background < -1 Or *panelexpage\background > 11
        
        *Gradient.gradients = *panelexpage\background
        alphaGradient = *Gradient\isAlpha
        foundGradient = #True
            
    EndIf
    
    ; draw parent window background if top PanelEx and in certain situation i.e background is '-1' or has semi-transparency
    If topPanelEx = #True And ((*panelexpage\background = -1) Or (*panelexpage\background >= 8 And *panelexpage\background <= 11) Or *panelexpage\background = 4 Or *panelexpage\background = 6 Or alphaGradient = #True Or *panelexpage\alpha < 255)
        tdc = dc
        If *panelexpage\alpha < 255
            dc = *panelex\backgroundDC
        EndIf
        GetClientRect_(GetParent_(*panelex\handle), @trc.RECT)
        MapWindowPoints_(GetParent_(*panelex\handle), *panelexpage\Handle, @trc, 2)
        brush = GetClassLongPtr_(GetParent_(*panelex\handle), -10); #GCLP_HBRBACKGROUND
        SetBrushOrgEx_(dc, trc\left, trc\top, @pt.POINT)
        FillRect_(dc, trc, brush)
        SetBrushOrgEx_(dc, pt\x, pt\y, @pt.POINT)
        If *DrawThemeParentBackground <> 0
            CallFunctionFast(*DrawThemeParentBackground, GetParent_(*panelex\Handle), dc, 0)
        EndIf
        dc = tdc
    EndIf
    
    If ThemesEnabled = #True
        If *panelexpage\background = 8 ; system button normal state
            CallFunctionFast(*DrawThemeBackground, hThemeButton, dc, 1, 0, @rec, 0)
        ElseIf *panelexpage\background = 9 ; system button hot state
            CallFunctionFast(*DrawThemeBackground, hThemeButton, dc, 1, 2, @rec, 0)
        ElseIf *panelexpage\background = 10 ; system button pressed state
            CallFunctionFast(*DrawThemeBackground, hThemeButton, dc, 1, 3, @rec, 0)
        ElseIf *panelexpage\background = 11 ; system button disabled state
            CallFunctionFast(*DrawThemeBackground, hThemeButton, dc, 1, 4, @rec, 0)
        ElseIf *panelexpage\background = 0
            CallFunctionFast(*DrawThemeBackground, hThemeTab, dc, 9, 0, @rec, 0)
        EndIf
    EndIf
    
    ; if border active then setup offscreen buffer for composition
    hMask = getBorderRgn(*panelexpage\borderHandle, rec)
    If ThemesEnabled = #True
        If hMask = 0 And *panelexpage\background = 8
            hMask = getBorderRgn(themeButtonBorder, rec)
        ElseIf hMask = 0 And *panelexpage\background = 9
            hMask = getBorderRgn(themeButtonHotBorder, rec)
        ElseIf hMask = 0 And *panelexpage\background = 10
            hMask = getBorderRgn(themeButtonPressedBorder, rec)
        ElseIf hMask = 0 And *panelexpage\background = 11
            hMask = getBorderRgn(themeButtonDisabledBorder, rec)
        ElseIf hMask = 0 And *panelexpage\background = 0
            hMask = getBorderRgn(themeTabBorder, rec)
        EndIf
    EndIf
    If hMask <> #Null
        
        If thisAlpha = #False
            
            GetClientRect_(containerHwnd, @rrc.RECT)
            rgn = CreateRectRgn_(rrc\left,rrc\top,rrc\right,rrc\bottom)
            GetClipRgn_(dc, rgn)

            If inAlpha = #False
                
                MapWindowPoints_(containerHwnd, GetParent_(divertedWindow), @rrc, 2)
                OffsetRgn_(hMask, rrc\left, rrc\top)
                ExtSelectClipRgn_(dc, hMask, #RGN_AND)
                OffsetRgn_(hMask, -rrc\left, -rrc\top)
                
            Else
                
                MapWindowPoints_(containerHwnd, divertedWindow, @rrc, 2)
                GetWindowOrgEx_(dc, pnt.POINT)
                OffsetClipRgn_(dc, pnt\x, pnt\y)
                OffsetRgn_(hMask, rrc\left, rrc\top)
                ExtSelectClipRgn_(dc, hMask, #RGN_AND)
                OffsetRgn_(hMask, -rrc\left, -rrc\top)
                OffsetClipRgn_(dc, -pnt\x, -pnt\y)
                
            EndIf
            
        Else
            
            GetClientRect_(Window, @rrc.RECT)
            rgn = CreateRectRgn_(rrc\left, rrc\top, rrc\right, rrc\bottom)
            GetClipRgn_(dc, rgn)
            OffsetRgn_(hMask, -clprc\left, -clprc\top)
            ExtSelectClipRgn_(dc, hMask, #RGN_AND)
            OffsetRgn_(hMask, clprc\left, clprc\top)
            
        EndIf
        
    Else
        originaldc = dc
    EndIf
    
    If *panelexpage\background <> -1
        
        If foundGradient = #True
            
            DrawGradient(dc, *Gradient, rec)
            
        Else
            If ThemesEnabled = #True
                If *panelexpage\background = 1 ; explorer bar background
                    
                    If osVersion > #PB_OS_Windows_XP
                        CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 0, 0, @rec, 0)
                    Else
                        ; add missing alpha channel to explorerbar background if running on xp
                        If rec\right-rec\left > 0 And rec\bottom-rec\top > 0
                            timage = CreateImage(#PB_Any, rec\right-rec\left, rec\bottom-rec\top, 32)
                            tdc = StartDrawing(ImageOutput(timage))
                            trc.RECT
                            trc\left = 0
                            trc\top = 0
                            trc\right = rec\right-rec\left
                            trc\bottom = rec\bottom-rec\top
                            CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, tdc, 0, 0, @trc, 0)
                            DrawingMode(#PB_2DDrawing_AlphaChannel)
                            Box(0, 0, rec\right-rec\left, rec\bottom-rec\top, RGBA(0, 0, 0, 255))
                            BitBlt_(dc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, tdc, 0, 0, #SRCCOPY)
                            StopDrawing()
                            FreeImage(timage)
                        EndIf
                    EndIf
                    
                ElseIf *panelexpage\background = 2
                    CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 1, 0, @rec, 0)
                ElseIf *panelexpage\background = 3 ; explorer bar group background
                    
                    If osVersion > #PB_OS_Windows_XP
                        CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 5, 0, @rec, 0)
                    Else
                        ; add missing alpha channel to explorerbar group background if running on xp
                        If rec\right-rec\left > 0 And rec\bottom-rec\top > 0
                            timage = CreateImage(#PB_Any, rec\right-rec\left, rec\bottom-rec\top, 32)
                            tdc = StartDrawing(ImageOutput(timage))
                            trc.RECT
                            trc\left = 0
                            trc\top = 0
                            trc\right = rec\right-rec\left
                            trc\bottom = rec\bottom-rec\top
                            CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, tdc, 5, 0, @trc, 0)
                            DrawingMode(#PB_2DDrawing_AlphaChannel)
                            Box(0, 0, rec\right-rec\left, rec\bottom-rec\top, RGBA(0, 0, 0, 255))
                            BitBlt_(dc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, tdc, 0, 0, #SRCCOPY)
                            StopDrawing()
                            FreeImage(timage)
                        EndIf
                    EndIf
                    
                ElseIf *panelexpage\background = 4 ; explorer bar group header
                    
                    If osVersion > #PB_OS_Windows_XP
                        CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 8, 0, @rec, 0)
                    Else
                        ; add missing alpha channel to explorerbar group header if running on xp
                        backupHDCAlpha(divertedWindow, dc, rec)
                        CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 8, 0, @rec, 0)
                        backupHDCAlpha(divertedWindow, dc, rec)
                    EndIf
                    
                ElseIf *panelexpage\background = 5
                    CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 9, 0, @rec, 0)
                ElseIf *panelexpage\background = 6
                    CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 12, 0, @rec, 0)
                ElseIf *panelexpage\background = 7
                    CallFunctionFast(*DrawThemeBackground, hThemeRebar, dc, 0, 0, @rec, 0)
                ElseIf *panelexpage\background = 8
                    ; do nothing, drawn earlier before mask
                ElseIf *panelexpage\background = 9
                    ; do nothing, drawn earlier before mask
                ElseIf *panelexpage\background = 10
                    ; do nothing, drawn earlier before mask
                ElseIf *panelexpage\background = 11
                    ; do nothing, drawn earlier before mask
                EndIf
                ; render system classic styles in place of missing themes
            Else
                
                If *panelexpage\background = 4 ; explorer bar group header
                    
                    If rec\right-rec\left > 0 And rec\bottom-rec\top > 0
                        timage = CreateImage(#PB_Any, rec\right-rec\left, rec\bottom-rec\top, 32)
                        tdc = StartDrawing(ImageOutput(timage))
                        DrawingMode(#PB_2DDrawing_AllChannels)
                        col = GetSysColor_(#COLOR_BTNFACE)
                        Box(0, 0, rec\right-rec\left, rec\bottom-rec\top, RGBA(Red(col), Green(col), Blue(col), 255))
                        BitBlt_(dc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, tdc, 0, 0, #SRCCOPY)
                        StopDrawing()
                        FreeImage(timage)
                    EndIf
                    
                ElseIf *panelexpage\background = 1 ; explorer bar background
                    
                    If rec\right-rec\left > 0 And rec\bottom-rec\top > 0
                        timage = CreateImage(#PB_Any, rec\right-rec\left, rec\bottom-rec\top, 32)
                        tdc = StartDrawing(ImageOutput(timage))
                        DrawingMode(#PB_2DDrawing_AllChannels)
                        col = GetSysColor_(#COLOR_HIGHLIGHTTEXT)
                        Box(0, 0, rec\right-rec\left, rec\bottom-rec\top, RGBA(Red(col), Green(col), Blue(col), 255))
                        BitBlt_(dc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, tdc, 0, 0, #SRCCOPY)
                        StopDrawing()
                        FreeImage(timage)
                    EndIf
                    
                ElseIf *panelexpage\background = 3 ; explorer bar group background
                    
                    If rec\right-rec\left > 0 And rec\bottom-rec\top > 0
                        timage = CreateImage(#PB_Any, rec\right-rec\left, rec\bottom-rec\top, 32)
                        tdc = StartDrawing(ImageOutput(timage))
                        DrawingMode(#PB_2DDrawing_AllChannels)
                        col = GetSysColor_(#COLOR_BTNFACE)
                        Box(0, 0, rec\right-rec\left, rec\bottom-rec\top, RGBA(Red(col), Green(col), Blue(col), 255))
                        col = GetSysColor_(#COLOR_HIGHLIGHTTEXT)
                        Box(1, 0, rec\right-rec\left-2, rec\bottom-rec\top-1, RGBA(Red(col), Green(col), Blue(col), 255))
                        BitBlt_(dc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, tdc, 0, 0, #SRCCOPY)
                        StopDrawing()
                        FreeImage(timage)
                    EndIf
                        
                ElseIf *panelexpage\background = 8 ; system button normal state
                    
                    If rec\right-rec\left > 0 And rec\bottom-rec\top > 0
                        timage = CreateImage(#PB_Any, rec\right-rec\left, rec\bottom-rec\top, 32)
                        tdc = StartDrawing(ImageOutput(timage))
                        trc.RECT
                        trc\left = 0
                        trc\top = 0
                        trc\right = rec\right-rec\left
                        trc\bottom = rec\bottom-rec\top
                        DrawFrameControl_(tdc, trc, #DFC_BUTTON, #DFCS_BUTTONPUSH)
                        DrawingMode(#PB_2DDrawing_AlphaChannel)
                        Box(0, 0, rec\right-rec\left, rec\bottom-rec\top, RGBA(0, 0, 0, 255))
                        BitBlt_(dc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, tdc, 0, 0, #SRCCOPY)
                        StopDrawing()
                        FreeImage(timage)
                    EndIf
                    
                ElseIf *panelexpage\background = 9 ; system button hot state
                    
                    If rec\right-rec\left > 0 And rec\bottom-rec\top > 0
                        timage = CreateImage(#PB_Any, rec\right-rec\left, rec\bottom-rec\top, 32)
                        tdc = StartDrawing(ImageOutput(timage))
                        trc.RECT
                        trc\left = 0
                        trc\top = 0
                        trc\right = rec\right-rec\left
                        trc\bottom = rec\bottom-rec\top
                        DrawFrameControl_(tdc, trc, #DFC_BUTTON, #DFCS_BUTTONPUSH)
                        DrawingMode(#PB_2DDrawing_AlphaChannel)
                        Box(0, 0, rec\right-rec\left, rec\bottom-rec\top, RGBA(0, 0, 0, 255))
                        BitBlt_(dc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, tdc, 0, 0, #SRCCOPY)
                        StopDrawing()
                        FreeImage(timage)
                    EndIf
                    
                ElseIf *panelexpage\background = 10 ; system button pressed state
                    
                    If rec\right-rec\left > 0 And rec\bottom-rec\top > 0
                        timage = CreateImage(#PB_Any, rec\right-rec\left, rec\bottom-rec\top, 32)
                        tdc = StartDrawing(ImageOutput(timage))
                        trc.RECT
                        trc\left = 0
                        trc\top = 0
                        trc\right = rec\right-rec\left
                        trc\bottom = rec\bottom-rec\top
                        DrawFrameControl_(tdc, trc, #DFC_BUTTON, #DFCS_BUTTONPUSH|#DFCS_PUSHED)
                        DrawingMode(#PB_2DDrawing_AlphaChannel)
                        Box(0, 0, rec\right-rec\left, rec\bottom-rec\top, RGBA(0, 0, 0, 255))
                        BitBlt_(dc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, tdc, 0, 0, #SRCCOPY)
                        StopDrawing()
                        FreeImage(timage)
                    EndIf
                        
                ElseIf *panelexpage\background = 11 ; system button disabled state
                    
                    If rec\right-rec\left > 0 And rec\bottom-rec\top > 0
                        timage = CreateImage(#PB_Any, rec\right-rec\left, rec\bottom-rec\top, 32)
                        tdc = StartDrawing(ImageOutput(timage))
                        trc.RECT
                        trc\left = 0
                        trc\top = 0
                        trc\right = rec\right-rec\left
                        trc\bottom = rec\bottom-rec\top
                        DrawFrameControl_(tdc, trc, #DFC_BUTTON, #DFCS_BUTTONPUSH|#DFCS_INACTIVE)
                        DrawingMode(#PB_2DDrawing_AlphaChannel)
                        Box(0, 0, rec\right-rec\left, rec\bottom-rec\top, RGBA(0, 0, 0, 255))
                        BitBlt_(dc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, tdc, 0, 0, #SRCCOPY)
                        StopDrawing()
                        FreeImage(timage)
                    EndIf
                    
                Else
                    hBrush = GetSysColorBrush_(#COLOR_3DFACE)
                    FillRect_(dc, @rec, hBrush)
                EndIf
            EndIf
        EndIf
    ElseIf *panelexpage\background = -1
        ; do nothing
    EndIf
    
    If *panelexpage\backgroundImg <> #Null
        
        imageX = *panelexpage\imageX
        imageY = *panelexpage\imageY
        
        If *panelexpage\style & #PNLX_HPERCENT
            imageX = (((rec\right-rec\left)/100.0)**panelexpage\imageX)-(*panelexpage\imageWidth/2)
        EndIf
        If *panelexpage\style & #PNLX_VPERCENT
            imageY = (((rec\bottom-rec\top)/100.0)**panelexpage\imageY)-(*panelexpage\imageHeight/2)
        EndIf
        
        If *panelexpage\style & #PNLX_RIGHT
            imageX = ((rec\right-rec\left)-*panelexpage\imageWidth)-imageX
        EndIf
        If *panelexpage\style & #PNLX_BOTTOM
            imageY = ((rec\bottom-rec\top)-*panelexpage\imageHeight)-imageY
        EndIf
        
        If *panelexpage\style & #PNLX_CENTRE
            imageX = ((rec\right-rec\left)/2)-(*panelexpage\imageWidth/2)
        EndIf
        If *panelexpage\style & #PNLX_VCENTRE
            imageY = ((rec\bottom-rec\top)/2)-(*panelexpage\imageHeight/2)
        EndIf
        
        If *panelexpage\style & #PNLX_STRETCH
            
            ImageList_GetImageInfo_(*panelexpage\backgroundImg, 0, imgInfo.IMAGEINFO)
            CallFunctionFast(*GdipCreateFromHDC, dc, @GraphicObject)
            CallFunctionFast(*GdipSetCompositingMode, GraphicObject, 0)
            CallFunctionFast(*GdipSetCompositingQuality, GraphicObject, 1) ; CompositingQualityHighSpeed
            CallFunctionFast(*GdipSetPixelOffsetMode, GraphicObject, 3)    ; PixelOffsetModeNone
            CallFunctionFast(*GdipSetSmoothingMode, GraphicObject, 3)      ; SmoothingModeNone
            
            gbitmap = gBufferImage(imgInfo\hbmImage)
            
            ; destination coords and dimensions first
            CallFunctionFast(*GdipDrawImageRectRectI, GraphicObject, gbitmap, rec\left, rec\top, rec\right-rec\left,rec\bottom-rec\top, 0, 0, imgInfo\rcImage\right, imgInfo\rcImage\bottom, #UnitPixel, 0, #Null, #Null)
            
            CallFunctionFast(*GdipDeleteGraphics,GraphicObject)
            CallFunctionFast(*GdipDisposeImage, gbitmap)
            
        ElseIf *panelexpage\style & #PNLX_HREPEAT And *panelexpage\style & #PNLX_VREPEAT
            y = rec\top
            Repeat
                x = rec\left
                Repeat
                    ImageList_DrawEx_(*panelexpage\backgroundImg, 0, dc, x, y, *panelexpage\imageWidth, *panelexpage\imageHeight, #CLR_NONE, #CLR_NONE, #ILD_NORMAL)
                    x = x + *panelexpage\imageWidth
                Until x >= rec\right
                y = y + *panelexpage\imageHeight
            Until y >= rec\bottom And x >= rec\right
        ElseIf *panelexpage\style & #PNLX_HREPEAT
            x = rec\left
            Repeat
                ImageList_DrawEx_(*panelexpage\backgroundImg, 0, dc, x, rec\top+imageY, *panelexpage\imageWidth, *panelexpage\imageHeight, #CLR_NONE, #CLR_NONE, #ILD_NORMAL)
                x = x + *panelexpage\imageWidth
            Until x >= rec\right
        ElseIf *panelexpage\style & #PNLX_VREPEAT
            y = rec\top
            Repeat
                ImageList_DrawEx_(*panelexpage\backgroundImg, 0, dc, rec\left+imageX, y, *panelexpage\imageWidth, *panelexpage\imageHeight, #CLR_NONE, #CLR_NONE, #ILD_NORMAL)
                y = y + *panelexpage\imageHeight
            Until y >= rec\bottom
        Else
            
            ImageList_DrawEx_(*panelexpage\backgroundImg, 0, dc, rec\left+imageX, rec\top+imageY, *panelexpage\imageWidth, *panelexpage\imageHeight, #CLR_NONE, #CLR_NONE, #ILD_NORMAL)
            
        EndIf
        
    EndIf
    
    ;/ Overlay background
    If *panelexpage\background2 <> -1
        
        ; check if background is a gradient
        foundGradient = #False
        If *panelexpage\background2 < -1 Or *panelexpage\background2 > 11
            foundGradient = #True
            *Gradient.gradients = *panelexpage\background2
        EndIf
        
        If foundGradient = #True
            
            DrawGradient(dc, *Gradient, rec)
            
        ElseIf foundGradient = #False And hThemeTab <> #Null
            If *panelexpage\background2 = 1
                CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 0, 0, @rec, 0)
            ElseIf *panelexpage\background2 = 2
                CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 1, 0, @rec, 0)
            ElseIf *panelexpage\background2 = 3
                CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 5, 0, @rec, 0)
            ElseIf *panelexpage\background2 = 4
                CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 8, 0, @rec, 0)
            ElseIf *panelexpage\background2 = 5
                CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 9, 0, @rec, 0)
            ElseIf *panelexpage\background2 = 6
                CallFunctionFast(*DrawThemeBackground, hThemeExplorerbar, dc, 12, 0, @rec, 0)
            ElseIf *panelexpage\background2 = 7
                CallFunctionFast(*DrawThemeBackground, hThemeRebar, dc, 0, 0, @rec, 0)
            ElseIf *panelexpage\background2 = 8
                ; do nothing, drawn earlier before mask
            ElseIf *panelexpage\background2 = 9
                ; do nothing, drawn earlier before mask
            ElseIf *panelexpage\background2 = 10
                ; do nothing, drawn earlier before mask
            ElseIf *panelexpage\background2 = 11
                ; do nothing, drawn earlier before mask
            Else
                CallFunctionFast(*DrawThemeBackground, hThemeTab, dc, 9, 0, @rec, 0)
            EndIf
        EndIf
        
    EndIf
    
    ;/ overlay background image
    If *panelexpage\backgroundImg2 <> 0
        
        imageX = *panelexpage\imageX2
        imageY = *panelexpage\imageY2
        
        If *panelexpage\style2 & #PNLX_HPERCENT
            imageX = (((rec\right-rec\left)/100.0)**panelexpage\imageX2)-(*panelexpage\imageWidth2/2)
        EndIf
        If *panelexpage\style2 & #PNLX_VPERCENT
            imageY = (((rec\bottom-rec\top)/100.0)**panelexpage\imageY2)-(*panelexpage\imageHeight2/2)
        EndIf
        
        If *panelexpage\style2 & #PNLX_RIGHT
            imageX = ((rec\right-rec\left)-*panelexpage\imageWidth2)-imageX
        EndIf
        If *panelexpage\style2 & #PNLX_BOTTOM
            imageY = ((rec\bottom-rec\top)-*panelexpage\imageHeight2)-imageY
        EndIf
        
        If *panelexpage\style2 & #PNLX_CENTRE
            imageX = ((rec\right-rec\left)/2)-(*panelexpage\imageWidth2/2)
        EndIf
        If *panelexpage\style2 & #PNLX_VCENTRE
            imageY = ((rec\bottom-rec\top)/2)-(*panelexpage\imageHeight2/2)
        EndIf
        
        If *panelexpage\style2 & #PNLX_STRETCH
            ImageList_DrawEx_(*panelexpage\backgroundImg2, 0, dc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, #CLR_NONE, #CLR_NONE, #ILD_NORMAL) ; x,y width,height
        ElseIf *panelexpage\style2 & #PNLX_HREPEAT And *panelexpage\style2 & #PNLX_VREPEAT
            y = rec\top
            Repeat
                x = rec\left
                Repeat
                    ImageList_DrawEx_(*panelexpage\backgroundImg2, 0, dc, x, y, *panelexpage\imageWidth2, *panelexpage\imageHeight2, #CLR_NONE, #CLR_NONE, #ILD_NORMAL)
                    x = x + *panelexpage\imageWidth2
                Until x >= rec\right
                y = y + *panelexpage\imageHeight2
            Until y >= rec\bottom And x >= rec\right
        ElseIf *panelexpage\style2 & #PNLX_HREPEAT
            x = rec\left
            Repeat
                ImageList_DrawEx_(*panelexpage\backgroundImg2, 0, dc, x, rec\top+imageY, *panelexpage\imageWidth2, *panelexpage\imageHeight2, #CLR_NONE, #CLR_NONE, #ILD_NORMAL)
                x = x + *panelexpage\imageWidth2
            Until x >= rec\right
        ElseIf *panelexpage\style2 & #PNLX_VREPEAT
            y = rec\top
            Repeat
                ImageList_DrawEx_(*panelexpage\backgroundImg2, 0, dc, rec\left+imageX, y, *panelexpage\imageWidth2, *panelexpage\imageHeight2, #CLR_NONE, #CLR_NONE, #ILD_NORMAL)
                y = y + *panelexpage\imageHeight2
            Until y >= rec\bottom
        Else
            ImageList_DrawEx_(*panelexpage\backgroundImg2, 0, dc, rec\left+imageX, rec\top+imageY, *panelexpage\imageWidth2, *panelexpage\imageHeight2, #CLR_NONE, #CLR_NONE, #ILD_NORMAL)
        EndIf
        
    EndIf
    
    ; allow user callback to draw background if set
    If *panelex\usercallback <> #Null
        
        OffsetWindowOrgEx_(dc, -rec\left, -rec\top, 0)
        CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, #WM_ERASEBKGND, dc, *panelex\handle)
        OffsetWindowOrgEx_(dc, rec\left, rec\top, 0)
        
    EndIf
    
    *trackWin.trackWindows = *panelexpage\trackWin
    If *trackWin\containsChildCntrl = #True
        renderPanelexPageChildren(*panelexpage\trackWin, divertedWindow, dc)
    EndIf
    
    ; check if any visible panelexs in this page and divert rendering to panelex buffer
    chwnd = GetWindow_(*panelexpage\handle, #GW_CHILD)
    If chwnd <> #Null
        chwnd = GetWindow_(chwnd, #GW_HWNDLAST)
        While chwnd <> #Null
            
            *cpanelex.panelexs = GetProp_(chwnd, panelexAtom)
            If *cpanelex <> #Null
                
                *ctrackWin.trackWindows = *cpanelex\trackWin
                If *ctrackWin <> #Null And *ctrackWin\visible = #True
                
                    *cpanelexpage.panelexpages = *cpanelex\displayedPage
                    If *cpanelexpage <> #Null
                        
                        ; make sure the panelex is visible inside this page
                        GetClientRect_(*cpanelex\Handle, rc.RECT)
                        MapWindowPoints_(*cpanelex\Handle, divertedWindow, rc, 2)
                        
                        *rpanelex.panelexs = *ctrackWin\rootPanelex
                        *rpanelexpage.panelexpages = *rpanelex\displayedPage
                        GetClientRect_(*cpanelex\Handle, trc.RECT)
                        MapWindowPoints_(*cpanelex\Handle, *rpanelexpage\handle, trc, 2)
                        
                        If *panelexpage\Alpha > 0 And RectVisible_(dc, rc) = #True And rectInPanelExUpdateRect(*rpanelex, trc) = #True
                            ;If *panelexpage\alpha < 255
                                ;Debug GetButtonExText(*cpanelex\Handle)
                            ;EndIf
                        
                            *cpanelexpage\dontdraw = 2
                            
                            GetClientRect_(*cpanelex\Handle, @rc.RECT)
                            MapWindowPoints_(*cpanelex\Handle, divertedWindow, @rc, 2)
                            
                            sdc = SaveDC_(dc) ; so as not to fuck up any nested clipping
                            
                            If Not *cpanelexpage\style & #PNLX_NOCLIP
                                IntersectClipRect_(dc, rc\left, rc\top, rc\right, rc\bottom)
                            EndIf
                            drawPanelPage(*cpanelexpage, dc, *cpanelexpage\Handle, divertedWindow, inAlpha)
                            
                            RestoreDC_(dc, sdc) ; previous dc states restored, e.g. clipping
                            
                            *cpanelexpage\dontdraw = #True
                            
                        EndIf
                           
                    EndIf
                    
                EndIf
                
            EndIf
            
            chwnd = GetWindow_(chwnd, #GW_HWNDPREV)
            
        Wend
    EndIf
    
    If hMask <> #Null
        SelectClipRgn_(dc, rgn)
    EndIf
    
    If thisAlpha = #False
        drawBorder(originaldc, *panelexpage\borderHandle, rec)
    Else
        drawBorder(dc, *panelexpage\borderHandle, rec)
    EndIf
    
    ; allow user callback to draw foreground if set
    If *panelex\usercallback <> #Null
        OffsetWindowOrgEx_(dc, -rec\left, -rec\top, 0)
        CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, #WM_PAINT, dc, *panelex\handle)
        OffsetWindowOrgEx_(dc, rec\left, rec\top, 0)
    EndIf
    
    
    *trackWin.trackWindows = *panelex\trackWin
    If *trackWin\containsChildCntrl = #True
        If topPanelEx = #True
            RestoreDC_(dc, sscrolldc)
            CopyStructure(oclprc, clprc, RECT)
        EndIf
        renderPanelexScrollbars(*panelex\trackWin, *panelexpage, divertedWindow, dc)
    EndIf
    
    If *panelexpage\dontdraw = 0
        
        If *panelexpage\alpha = 255
            ;debugbuffer(*panelex\backgroundBitmap)
            BitBlt_(thisdc, clprc\left, clprc\top, clprc\right-clprc\left, clprc\bottom-clprc\top, *panelex\backgroundDC, clprc\left, clprc\top, #SRCCOPY)
            ;brush = CreateSolidBrush_(RGB(0,Random(255),0))
            ;FillRect_(thisdc, clprc, brush)
            ;DeleteObject_(brush)
            ;debugbuffer(*panelex\backgroundBitmap)
            
        EndIf
        
    EndIf
    
    If *panelexpage\alpha < 255 And *panelexpage\alpha <> 0
        
        If topPanelEx = #False
            rdc = thisdc
        Else
            rdc = *panelex\backgroundDC
        EndIf
        
        ;debugbuffer(*panelex\alphaBitmap)
        
        
        blend = $1000000 | *panelexpage\alpha<<16
        ;GdiAlphaBlend_(rdc, rec\left, rec\top, rec\right-rec\left, rec\bottom-rec\top, *panelex\alphaDC, rec\left-ax, rec\top-ay, rec\right-rec\left, rec\bottom-rec\top, blend); $ 1FF0000
        ;GdiAlphaBlend_(rdc, ax, ay, rec\right-rec\left, rec\bottom-rec\top, *panelex\alphaDC, 0, 0, rec\right-rec\left, rec\bottom-rec\top, blend); $ 1FF0000
        
        SetWindowOrgEx_(dc, 0, 0, 0)
        GdiAlphaBlend_(rdc, ax+clprc\left, ay+clprc\top, clprc\right-clprc\left, clprc\bottom-clprc\top, *panelex\alphaDC, 0, 0, clprc\right-clprc\left, clprc\bottom-clprc\top, blend) ; $ 1FF0000
        
        
        ; clear buffer alpha, ready for next refresh
        StartDrawing(ImageOutput(*panelex\alphaBitmap))
        DrawingMode(#PB_2DDrawing_AllChannels)
        Box(0, 0, clprc\right-clprc\left, clprc\bottom-clprc\top, RGBA(0, 0, 0, 0))
        StopDrawing()
        
        If topPanelEx = #True
            GetClipBox_(thisdc, @rc.RECT)  
            BitBlt_(thisdc, rc\left, rc\top, rc\right-rc\left, rc\bottom-rc\top, *panelex\backgroundDC, rc\left, rc\top, #SRCCOPY)
        EndIf
        
        SelectClipRgn_(rdc, 0)
        
    EndIf
    
    SelectClipRgn_(dc, 0)
    
    If rgn <> #Null
        DeleteObject_(rgn)
    EndIf
    
    If argn <> #Null
        DeleteObject_(argn)
    EndIf
    
EndProcedure

Procedure ScrollbarBoxCallback(Window, message, wParam, lParam)
    
;     If message = #WM_PAINT
;         dc = BeginPaint_(Window, ps.PAINTSTRUCT)
;         GetClientRect_(Window, rc.RECT)
;         FillRect_(dc, rc, GetSysColorBrush_(#COLOR_3DFACE))
;         EndPaint_(Window, ps)
;         ProcedureReturn 0
;     EndIf
    
    ProcedureReturn DefWindowProc_(Window, message, wParam, lParam)
    
EndProcedure

ProcedureDLL createScrollbarBox(Window.i, x.l, y.l, visible.l)
    
    If visible <> #False
        visible = #WS_VISIBLE
    EndIf
    
    If scrollbarBoxClass = ""
        scrollbarBoxClass = #AppName+"_ScrollbarBox"
        wc.WNDCLASSEX
        wc\cbSize  = SizeOf(WNDCLASSEX)
        wc\style = #CS_PARENTDC
        wc\lpfnWndProc  = @ScrollbarBoxCallback()
        wc\hCursor  = LoadCursor_(0, #IDC_ARROW)
        wc\lpszClassName  = @scrollbarBoxClass
        RegisterClassEx_(@wc)
    EndIf
    
    hwnd = CreateWindowEx_(#WS_EX_TRANSPARENT, scrollbarBoxClass, #Null, #WS_CHILD | visible | #WS_CLIPSIBLINGS | #WS_CLIPCHILDREN, x, y, iHThumb, iVThumb, Window, #Null,  GetModuleHandle_(0), #Null)
    
    ProcedureReturn hwnd
EndProcedure

Procedure PanelExPageCallback(Window, message, wParam, lParam)
    
    ; get associated panelex page structure pointer from hwnd
    *panelexpage.panelexpages = GetProp_(Window, panelexpageAtom)
    If *panelexpage = #Null
        ProcedureReturn DefWindowProc_(Window, message, wParam, lParam)
    EndIf
    *panelex.panelexs = *panelexpage\panelex ; get page's panelex
    If *panelex = #Null
        ProcedureReturn DefWindowProc_(Window, message, wParam, lParam)
    EndIf
    
    Select message
            
        Case #WM_NCDESTROY
            
            RemoveProp_(Window, panelexpageAtom)
            
            *new.panelexpages = #Null
            If *panelex\displayedPage = *panelexpage
                ChangeCurrentElement(*panelex\page(), *panelexpage)
                *new.panelexpages = NextElement(*panelex\page())
                If *new = #Null
                    *new.panelexpages = PreviousElement(*panelex\page())
                EndIf
                *panelex\displayedPage = *new
            EndIf
            
            If *panelexpage\backgroundImg <> #Null
                ImageList_Destroy_(*panelexpage\backgroundImg)
            EndIf
            If *panelexpage\backgroundImg2 <> #Null
                ImageList_Destroy_(*panelexpage\backgroundImg2)
            EndIf
            
            freeBorder(*panelexpage\borderHandle)
            
            ChangeCurrentElement(*panelex\page(), *panelexpage)
            DeleteElement(*panelex\page(), 1)
            
            If *panelex\destroying = #False
                If *new <> #Null
                    ShowPanelExPage(*panelex\handle, *new\Handle)
                EndIf
            EndIf
            
        Case #WM_UPDATESKIN
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelex\Handle, message, wParam, lParam)
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            
        Case #WM_CTLCOLORSTATIC
            
            If *panelex\setRedrawFalse = #False
                
                If *panelex\usercallback <> #Null
                    Result = CallWindowProc_(*panelex\usercallback, *panelex\Handle, message, wParam, lParam)
                EndIf
                
                If Result = 0
                    
                    *ctrackWin.trackWindows = GetProp_(lParam, trackwinAtom)
                    If *ctrackWin <> #Null
                        
                        *trackWin.trackWindows = *panelexpage\trackWin
                        If *trackWin <> #Null And *ctrackWin\hBrush = #Null
                            
                            root = *trackWin\rootPanelexPageHwnd
                            *rootpanelexpage.panelexpages = *trackWin\rootPanelexPage
                            If *rootpanelexpage <> #Null
                                
                                *rootpanelex.panelexs = *rootpanelexpage\panelex
                                
                                ; if dc is not initialised yet then draw panel page
                                If *rootpanelex\backgroundDC = 0
                                    drawPanelPage(*rootpanelexpage, wparam, Window, 0, 0)
                                EndIf
                                
                                dc = *rootpanelex\backgroundDC
                                
                                If *panelexpage\alpha < 255
                                    root = window
                                    dc = *panelex\alphaDC
                                EndIf
                                
                                GetClientRect_(lParam, @rc.RECT)
                                
                                width = rc\right-rc\left
                                height = rc\bottom-rc\top
                                MapWindowPoints_(lParam, root, @rc, 2)
                                
                                hdc = CreateCompatibleDC_(wParam)
                                bitmap = CreateCompatibleBitmap_(wParam, width, height)
                                SelectObject_(hdc, bitmap)
                                BitBlt_(hdc, 0 , 0, width, height, dc, rc\left, rc\top, #SRCCOPY)
                                
                                *ctrackWin\hBrush = CreatePatternBrush_(bitmap)
                                ;*ctrackWin\hBrush = CreateSolidBrush_(RGB(255,0,0))
                                
                                DeleteObject_(bitmap)
                                DeleteDC_(hdc)
                                
                            EndIf
                            
                        EndIf
                        
                        SetBkMode_(wParam, #TRANSPARENT)
                        
                        
                        Result = *ctrackWin\hBrush
                        ;result = GetStockObject_(#HOLLOW_BRUSH)
                        
                    EndIf
                    
                EndIf
                
            EndIf
                
        Case #WM_PAINT
            
            *trackWin.trackWindows = *panelex\trackWin
            *rpanelex.panelexs = *trackWin\rootPanelex
            If *rpanelex = *panelex
                LockMutex(updateMutex)
            EndIf
            
            dc = BeginPaint_(Window, ps.PAINTSTRUCT)
            
            If *panelexpage\dontdraw <> #True And *panelex\setRedrawFalse = #False
                
                If ps\rcPaint\left <> 0 Or ps\rcPaint\top <> 0 Or ps\rcPaint\right <> 0 Or ps\rcPaint\bottom <> 0
                    
                    drawPanelPage(*panelexpage, dc, Window, lParam, 0)
                    ;updatePanelexChildren(*rpanelex)
                    
                EndIf
               
            EndIf
            
            EndPaint_(Window, ps)
            
            If *rpanelex = *panelex
                If *rpanelex\updateCount > 0
                    *rpanelex\updateCount - 1
                Else
                    If *rpanelex\updateRgn <> #Null
                        oldUpdateRgn = *rpanelex\updateRgn
                        *rpanelex\updateRgn = CreateRectRgn_(0, 0, 0, 0)
                        DeleteObject_(oldUpdateRgn)
                        ClearList(*rpanelex\updateRc())
                        ClearList(*rpanelex\updateChild())
                    EndIf
                EndIf
                UnlockMutex(updateMutex)
            EndIf
            
            ProcedureReturn 0
            
        Case #WM_ERASEBKGND
            
            ProcedureReturn 1
            
        Case #WM_COMMAND
            
            If *panelex\usercallback <> #Null
                Result = CallWindowProc_(*panelex\usercallback, *panelex\Handle, message, wParam, lParam)
            EndIf
            If Result = 0
                Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam)
            EndIf
            
        Case #WM_MOUSEMOVE
            
            pt.POINT
            GetCursorPos_(@pt)
            hwnd = WindowFromPoint_(PeekQ(pt))
            If hwnd = window
                If *panelexpage\cursor > 0
                    SetCursor_(*panelexpage\cursor)
                ElseIf *panelexpage\cursor = 0
                    SetCursor_(normalMousePointer)
                EndIf
            EndIf
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
           
            Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam)
            
        Case #WM_MOUSELEAVE
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam)
            
        Case #WM_LBUTTONUP
            
            pt.POINT
            GetCursorPos_(@pt)
            hwnd = WindowFromPoint_(PeekQ(pt))
            If hwnd = window
                If *panelexpage\cursor > 0
                    SetCursor_(*panelexpage\cursor)
                ElseIf *panelexpage\cursor = 0
                    SetCursor_(normalMousePointer)
                EndIf
            EndIf
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam)
            
        Case #WM_LBUTTONDOWN
            
            pt.POINT
            GetCursorPos_(@pt)
            hwnd = WindowFromPoint_(PeekQ(pt))
            If hwnd = window
                If *panelexpage\cursor > 0
                    SetCursor_(*panelexpage\cursor)
                ElseIf *panelexpage\cursor = 0
                    SetCursor_(normalMousePointer)
                EndIf
            EndIf
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam)
            
        Case #WM_LBUTTONDBLCLK
            
            pt.POINT
            GetCursorPos_(@pt)
            hwnd = WindowFromPoint_(PeekQ(pt))
            If hwnd = window
                If *panelexpage\cursor > 0
                    SetCursor_(*panelexpage\cursor)
                ElseIf *panelexpage\cursor = 0
                    SetCursor_(normalMousePointer)
                EndIf
            EndIf
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam)
            
        Case #WM_RBUTTONUP
            
            pt.POINT
            GetCursorPos_(@pt)
            hwnd = WindowFromPoint_(PeekQ(pt))
            If hwnd = window
                If *panelexpage\cursor > 0
                    SetCursor_(*panelexpage\cursor)
                ElseIf *panelexpage\cursor = 0
                    SetCursor_(normalMousePointer)
                EndIf
            EndIf
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam)
            
        Case #WM_RBUTTONDOWN
            
            pt.POINT
            GetCursorPos_(@pt)
            hwnd = WindowFromPoint_(PeekQ(pt))
            If hwnd = window
                If *panelexpage\cursor > 0
                    SetCursor_(*panelexpage\cursor)
                ElseIf *panelexpage\cursor = 0
                    SetCursor_(normalMousePointer)
                EndIf
            EndIf
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam)
            
        Case #WM_RBUTTONDBLCLK
            
            pt.POINT
            GetCursorPos_(@pt)
            hwnd = WindowFromPoint_(PeekQ(pt))
            If hwnd = window
                If *panelexpage\cursor > 0
                    SetCursor_(*panelexpage\cursor)
                ElseIf *panelexpage\cursor = 0
                    SetCursor_(normalMousePointer)
                EndIf
            EndIf
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam)
            
        Case #WM_NOTIFY
            
            If *panelex\usercallback <> #Null
                Result = CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            
            ; don't forward message if for a toolbarex as custom drawing is handled by maincallback attached to this callback
            *nm.NMHDR = lParam
            found = 0
            ForEach toolbarex()
                If toolbarex()\Handle = *nm\hwndFrom
                    found = #True
                    Break
                EndIf
            Next
            If found = #False
                Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam)
            EndIf
            
        Case #REBAR_UPDATED
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam)
            
        Case #TCX_LINK_HOVER
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam) 
            
        Case #TCX_LINK_CLICK
            
            If *panelex\usercallback <> #Null
                CallWindowProc_(*panelex\usercallback, *panelexpage\Handle, message, wParam, lParam)
            EndIf
            Result = SendMessage_(GetParent_(GetParent_(Window)),message,wParam,lParam) 
            
        Case #WM_SIZE
            
            ForEach rebarGadget()
                
                If rebarGadget()\WindowID = Window
                    If rebarGadget()\dbtoggle = 0
                        If rebarGadget()\doublebuffer = -1
                            SetWindowLongPtr_(rebarGadget()\Handle, #GWL_EXSTYLE, #WS_EX_TOOLWINDOW|#WS_EX_COMPOSITED)
                        EndIf
                        rebarGadget()\dbtoggle = -1
                    EndIf
                    
                    height = SendMessage_(rebarGadget()\Handle, #RB_GETBARHEIGHT, 0,0)
                    
                    GetClientRect_(Window, @rc.RECT)
                    SendMessage_(rebarGadget()\Handle, #WM_SETREDRAW, #False, 0)
                    MoveWindow_(rebarGadget()\Handle, 0, 0, rc\right-rc\left, height, #False)
                    
                    updateRebar(Window)
                    SendMessage_(rebarGadget()\Handle, #WM_SETREDRAW, #True, 0)
                    
                    If rebarGadget()\doublebuffer = 0
                        
                        RedrawWindow_(rebarGadget()\Handle,0,0,#RDW_INVALIDATE|#RDW_ERASE|#RDW_UPDATENOW)
                        
                    EndIf
                    
                EndIf
                
            Next
            
        Case #WM_NCHITTEST
            
            If *panelexpage\style & #PNLX_TRANSPARENT
                
                Result = #HTTRANSPARENT
                
            Else
                
                Result = DefWindowProc_(Window, message, wParam, lParam)
                
            EndIf
            
        Default
            
            If *panelex\usercallback <> #Null
                Result = CallWindowProc_(*panelex\usercallback, *panelexpage\handle, message, wParam, lParam)
            EndIf
            
            If Result = 0 
                Result  = DefWindowProc_(Window, message, wParam, lParam)
            EndIf
           
    EndSelect
    
    ProcedureReturn Result
    
EndProcedure

ProcedureDLL CreatePanelEx(PanelID.l, parent.i, x.l, y.l, width.l, height.l, usercallback.i)
    
    macro_protectCommand()
    
    If IsWindow_(parent) = #False
        ProcedureReturn #False
    EndIf
    
    ; make sure panelex control doesn't already exist
    *ID.IDHwndLookup = generateUniqueID(PanelID)
    If *ID = #Null
        ProcedureReturn #False
    EndIf
    
    If panelExContainerClass = ""
        panelExContainerClass = #AppName+"_PanelEx"
        wc.WNDCLASSEX
        wc\cbSize  = SizeOf(WNDCLASSEX)
        wc\style = 0;#CS_PARENTDC
        wc\lpfnWndProc  = @PanelExCallback()
        wc\lpszClassName  = @panelExContainerClass
        RegisterClassEx_(@wc)
    EndIf
    
    hwnd = CreateWindowEx_(0, panelExContainerClass, #Null, #WS_CHILD, x, y, width, height, parent, #Null,  GetModuleHandle_(0), #Null)
    
    If hwnd <> #Null
        
        initPanelexThemes()
        
        *panelex.panelexs = AllocateStructure(panelexs)
        *panelex\id = *ID\ID : *ID\hwnd = hwnd
        *panelex\Handle = hwnd
        *panelex\width = width
        *panelex\height = height
        *panelex\usercallback = usercallback
        
        SetProp_(hwnd, panelexAtom, *panelex)
        
        *trackWin.trackWindows = GetProp_(hwnd, trackwinAtom)
        If *trackWin <> #Null
            *trackWin\panelex = *panelex
            *panelex\trackWin = *trackWin
        EndIf
        
        If PanelID = #ProGUI_Any
            ProcedureReturn *ID\ID
        Else
            ProcedureReturn hwnd
        EndIf
        
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL AddPanelExPage(panel.i, background.i)
    
    macro_protectCommand()
    
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    If panelExPageClass = ""
        panelExPageClass = #AppName+"_PanelExPage"
        wc.WNDCLASSEX
        wc\cbSize  = SizeOf(WNDCLASSEX)
        wc\style = #CS_PARENTDC
        wc\lpfnWndProc  = @PanelExPageCallback()
        wc\lpszClassName  = @panelExPageClass
        RegisterClassEx_(@wc)
    EndIf
    
    If *panelex\displayedPage = #Null
        visible = #True
    EndIf
    
    hwnd = CreateWindowEx_(#WS_EX_TRANSPARENT, panelExPageClass, #Null, #WS_CHILD | #WS_CLIPSIBLINGS| #WS_CLIPCHILDREN, 0, 0, *panelex\width, *panelex\height, *panelex\Handle, #Null,  GetModuleHandle_(0), #Null)
    
    If hwnd <> #Null
        
        If panelExPageInsert = #False
            LastElement(*panelex\page())
            *panelexpage.panelexpages = AddElement(*panelex\page())
        Else
            ChangeCurrentElement(*panelex\page(), panelExPageInsert)
            *panelexpage.panelexpages = InsertElement(*panelex\page())
        EndIf
        
        *panelexpage\Handle = hwnd
        *panelexpage\containerHandle = *panelex\Handle
        *panelexpage\panelex = *panelex
        *panelexpage\background = background
        *panelexpage\background2 = -1
        *panelexpage\borderHandle = createBorder()
        *panelexpage\width = *panelex\width
        *panelexpage\height = *panelex\height
        *panelexpage\alpha = 255
        
        If *panelex\displayedPage = #Null
            *panelex\displayedPage = *panelexpage
        EndIf
        
        SetProp_(hwnd, panelexpageAtom, *panelexpage)
        
        *trackWin.trackWindows = GetProp_(hwnd, trackwinAtom)
        If *trackWin <> #Null
            *trackWin\panelexpage = *panelexpage
            *panelexpage\trackWin = *trackWin
        EndIf
        
        UseGadgetList(hwnd)
        
        If visible = #True
            ShowWindow_(hwnd, #SW_SHOW)
            ShowWindow_(*panelexpage\containerHandle, #SW_SHOW)
        EndIf
            
        ProcedureReturn hwnd
        
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL AddPanelExImagePage(panel.i, background.i, backgroundImg.i, imageX.l, imageY.l, imageWidth.l, imageHeight.l, style.l)
    
    macro_protectCommand()
    
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    If panelExPageClass = ""
        panelExPageClass = #AppName+"_PanelExPage"
        wc.WNDCLASSEX
        wc\cbSize  = SizeOf(WNDCLASSEX)
        wc\style = #CS_PARENTDC
        wc\lpfnWndProc  = @PanelExPageCallback()
        wc\lpszClassName  = @panelExPageClass
        RegisterClassEx_(@wc)
    EndIf
    
    If *panelex\displayedPage = #Null
        visible = #True
    EndIf
    
    hwnd = CreateWindowEx_(#WS_EX_TRANSPARENT, panelExPageClass, #Null, #WS_CHILD | #WS_CLIPSIBLINGS| #WS_CLIPCHILDREN, 0, 0, *panelex\width, *panelex\height, *panelex\Handle, #Null,  GetModuleHandle_(0), #Null)
    
    If hwnd <> 0
        
        If panelExPageInsert = #False
            LastElement(*panelex\page())
            *panelexpage.panelexpages = AddElement(*panelex\page())
        Else
            ChangeCurrentElement(*panelex\page(), panelExPageInsert)
            *panelexpage.panelexpages = InsertElement(*panelex\page())
        EndIf
        
        *panelexpage\Handle = hwnd
        *panelexpage\containerHandle = *panelex\Handle
        *panelexpage\panelex = *panelex
        *panelexpage\background = background
        *panelexpage\background2 = -1
        *panelexpage\borderHandle = createBorder()
        *panelexpage\width = *panelex\width
        *panelexpage\height = *panelex\height
        *panelexpage\alpha = 255
        *panelexpage\style = style
        
        If backgroundImg <> 0
            
            GetImageDimensions(backgroundImg, @bmWidth, @bmHeight)
            
            If imageWidth = 0
                imageWidth = bmWidth
            EndIf
            If imageHeight = 0
                imageHeight = bmHeight
            EndIf
            
            *panelexpage\backgroundImg = ImageList_Create_(imageWidth, imageHeight, #ILC_MASK | #ILC_COLOR32, 0, 0)
            If *panelexpage\backgroundImg <> 0
                RET.l = ImageList_ReplaceIcon_(*panelexpage\backgroundImg, -1, backgroundImg)
                If RET = -1
                    
                    If style & #PNLX_MASKED
                        ImageList_AddMasked_(*panelexpage\backgroundImg, backgroundImg, RGB(255,255,255))
                    Else
                        ImageList_Add_(*panelexpage\backgroundImg, backgroundImg, 0)
                    EndIf
                    
                EndIf
                
                *panelexpage\imageWidth = imageWidth
                *panelexpage\imageHeight = imageHeight
                *panelexpage\imageX = imageX
                *panelexpage\imageY = imageY
                
            EndIf
        EndIf
        
        If *panelex\displayedPage = #Null
            *panelex\displayedPage = *panelexpage
        EndIf
        
        SetProp_(hwnd, panelexpageAtom, *panelexpage)
        
        *trackWin.trackWindows = GetProp_(hwnd, trackwinAtom)
        If *trackWin <> #Null
            *trackWin\panelexpage = *panelexpage
            *panelexpage\trackWin = *trackWin
        EndIf
        
        If Not style & #PNLX_NOGADGETLIST
            UseGadgetList(hwnd)
        EndIf
        
        If visible = #True
            ShowWindow_(hwnd, #SW_SHOW)
            ShowWindow_(*panelexpage\containerHandle, #SW_SHOW)
        EndIf
        
        ProcedureReturn hwnd
        
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL InsertPanelExPage(Panel.i, page.i, background.i) ; Inserts a PanelEx page into a PanelEx.
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ; find panel page index
    If page <> -1
        ForEach *panelex\page()
            If ListIndex(*panelex\page()) = page Or *panelex\page()\Handle = page
                found = #True
                Break
            EndIf
        Next
    EndIf
    
    If found = #True Or page = -1
        
        If page <> -1
            panelExPageInsert = *panelex\page()
        EndIf
        
        RET = AddPanelExPage(Panel, background)
        
        panelExPageInsert = #False
        
        ProcedureReturn RET
        
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL InsertPanelExImagePage(Panel.i, page.i, background.i, backgroundImg.i, imageX.l, imageY.l, imageWidth.l, imageHeight.l, style.l) ; Inserts a PanelEx image page into a PanelEx.
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ; find panel page index
    If page <> -1
        ForEach *panelex\page()
            If ListIndex(*panelex\page()) = page Or *panelex\page()\Handle = page
                found = #True
                Break
            EndIf
        Next
    EndIf
        
    If found = #True Or page = -1
        
        If page <> -1
            panelExPageInsert = *panelex\page()
        EndIf
        
        RET = AddPanelExImagePage(Panel, background, backgroundImg, imageX, imageY, imageWidth, imageHeight, style)
        
        panelExPageInsert = #False
        
        ProcedureReturn RET
        
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL SetPanelExRedraw(Panel.i, state.b) ; Sets a PanelEx's redraw state, false = disable redraw, true = enable redraw.
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    *panelexpage.panelexpages = *panelex\displayedPage
    If *panelexpage <> #Null
        *trackWin.trackWindows = *panelexpage\trackWin
        If *trackWin <> #Null
            *rpanelex.panelexs = *trackWin\rootPanelex
            If *rpanelex <> #Null
                If state = #False
                    *rpanelex\setRedrawFalse = #True
                Else
                    *rpanelex\setRedrawFalse = #False
                EndIf
                ProcedureReturn #True
            EndIf
        EndIf
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL SetPanelExPageBorder(Panel.i, index.i, BorderImage.i, BorderMask.i, *BorderRect.RECT, *BorderAutoStretch.RECT, noRefresh.b) ; Sets a PanelEx's page border.
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ; find panel page index
    ForEach *panelex\page()
        If ListIndex(*panelex\page()) = index Or *panelex\page()\handle = index
            
            setBorder(*panelex\page()\borderHandle, BorderImage, BorderMask, *BorderRect, *BorderAutoStretch)
            
            If noRefresh = #False
                If *panelex\displayedPage = *panelex\page()
                    RefreshPanelEx(*panelex\Handle)
                EndIf
            EndIf
            
            ProcedureReturn #True
        EndIf
    Next
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL SetPanelExPageBackground(Panel.i, page.i, background.i, backgroundImg.i, imageX.l, imageY.l, imageWidth.l, imageHeight.l, style.l, noRefresh.b) ; Sets a PanelEx's page background.
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ; find panel page index
    ForEach *panelex\page()
        If ListIndex(*panelex\page()) = page Or *panelex\page()\Handle = page
            *panelexpage.panelexpages = *panelex\page()
            Break
        EndIf
    Next
    
    If *panelexpage <> #Null
        
        If background <> #PNLX_IGNORE
            If Not style & #PNLX_OVERLAY
                *panelexpage\background = background
            Else
                *panelexpage\background2 = background
            EndIf
        EndIf
        If imageX <> #PNLX_IGNORE
            If Not style & #PNLX_OVERLAY
                *panelexpage\imageX = imageX
            Else
                *panelexpage\imageX2 = imageX
            EndIf
        EndIf
        If imageY <> #PNLX_IGNORE
            If Not style & #PNLX_OVERLAY
                *panelexpage\imageY = imageY
            Else
                *panelexpage\imageY2 = imageY
            EndIf
        EndIf
        If style <> #PNLX_IGNORE
            If Not style & #PNLX_OVERLAY
                *panelexpage\style = style
            Else
                *panelexpage\style2 = style
            EndIf
        EndIf
        
        If backgroundImg <> #PNLX_IGNORE And backgroundImg <> 0
            
            GetImageDimensions(backgroundImg, @bmWidth, @bmHeight)
            
            If imageWidth = 0 Or imageWidth = #PNLX_IGNORE
                imageWidth = bmWidth
            EndIf
            If imageHeight = 0 Or imageHeight = #PNLX_IGNORE
                imageHeight = bmHeight
            EndIf
            
            ; delete existing imagelist if already created
            If Not style & #PNLX_OVERLAY
                If *panelexpage\backgroundImg <> #Null
                    ImageList_Destroy_(*panelexpage\backgroundImg)
                EndIf
            Else
                If *panelexpage\backgroundImg2 <> #Null
                    ImageList_Destroy_(*panelexpage\backgroundImg2)
                EndIf
            EndIf
            
            new = ImageList_Create_(imageWidth, imageHeight, #ILC_MASK | #ILC_COLOR32, 0, 0)
            If new <> 0
                
                RET.l = ImageList_ReplaceIcon_(new, -1, backgroundImg)
                If RET = -1
                    
                    If style & #PNLX_MASKED
                        ; why the fuck does ImageList_AddMasked_ change the original image's masked colour to black?? fucking retards @ microsoft
                        ; so now we need to create a temp copy of the original image due to the genius behind said command - more memory bloat and cpu
                        ; but wait, theres no API to copy a bitmap, well done MS! ;) - rant over :)
                        tbitmap = ImgBlend(backgroundImg, 255, 0, 0, 0, 0, 0)
                        ImageList_AddMasked_(new, tbitmap, RGB(255,255,255))
                        DeleteObject_(tbitmap)
                    Else
                        ImageList_Add_(new, backgroundImg, 0)
                    EndIf
                    
                EndIf
                
                If Not style & #PNLX_OVERLAY
                    *panelexpage\backgroundImg = new
                    *panelexpage\imageWidth = imageWidth
                    *panelexpage\imageHeight = imageHeight
                Else
                    *panelexpage\backgroundImg2 = new
                    *panelexpage\imageWidth2 = imageWidth
                    *panelexpage\imageHeight2 = imageHeight
                EndIf
                
            EndIf
            
        ; width or height changed but no new image
        ElseIf backgroundImg = #PNLX_IGNORE And (imageWidth <> 0 Or imageHeight <> 0)
            
            If imageWidth = #PNLX_IGNORE
                If Not style & #PNLX_OVERLAY
                    imageWidth = *panelexpage\imageWidth
                Else
                    imageWidth = *panelexpage\imageWidth2
                EndIf
            EndIf
            
            If imageHeight = #PNLX_IGNORE
                If Not style & #PNLX_OVERLAY
                    imageHeight = *panelexpage\imageHeight
                Else
                    imageHeight = *panelexpage\imageHeight2
                EndIf
            EndIf
            
            If Not style & #PNLX_OVERLAY
                *panelexpage\imageWidth = imageWidth
                *panelexpage\imageHeight = imageHeight
            Else
                *panelexpage\imageWidth2 = imageWidth
                *panelexpage\imageHeight2 = imageHeight
            EndIf
            
        EndIf
        
        If noRefresh = #False
            If *panelex\displayedPage = *panelexpage
                RefreshPanelEx(*panelex\Handle)
            EndIf
        EndIf
        
        ProcedureReturn #True
        
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL SetPanelExPageAlpha(Panel.i, Page.i, Alpha.c, noRefresh.b) ; Sets a PanelEx page's alpha transparency, 0 = fully transparent, 255 = opaque.
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ; find panel page index
    ForEach *panelex\page()
        If ListIndex(*panelex\page()) = page Or *panelex\page()\Handle = page
            *panelexpage.panelexpages = *panelex\page()
            Break
        EndIf
    Next
    
    If *panelexpage <> #Null
        
        *panelexpage\alpha = Alpha
        
        If noRefresh = #False
            If *panelex\displayedPage = *panelexpage
                RefreshPanelEx(*panelex\Handle)
            EndIf
        EndIf
        
        ProcedureReturn #True
        
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL SetPanelExUserCallback(Panel.i, *UserCallback) ; Sets a PanelEx's usercallback.
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    *panelex\usercallback = *UserCallback
    
    ProcedureReturn #True
    
EndProcedure

ProcedureDLL GetPanelExUserCallback(Panel.i) ; Gets a PanelEx's usercallback procedure address.
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ProcedureReturn *panelex\usercallback
    
EndProcedure

ProcedureDLL GetPanelExBitmap(Panel.i) ; Gets a PanelEx's image buffer.
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ProcedureReturn *panelex\backgroundBitmap
    
EndProcedure

ProcedureDLL GetPanelExDC(Panel.i) ; Gets a PanelEx's image buffer device context.
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ProcedureReturn *panelex\backgroundDC
    
EndProcedure

ProcedureDLL RefreshPanelEx(Panel.i, *updateRect.RECT = #Null, flags.l = #Null)
    ;debuglog("wtf "+Str(Random(255)))
    ;debuglog("Thread ID: " + Str(GetCurrentThreadId_()))
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    *panelexpage.panelexpages = *panelex\displayedPage
    If *panelexpage <> #Null
        
        *trackWin.trackWindows = *panelexpage\trackWin
        If *trackWin\rootPanelexHwnd <> #Null And *trackWin\rootPanelexPageHwnd <> #Null
        
            If *panelexpage\autoScroll = #True
                If *panelexpage\calcArea = #True
                    calcPanelExPageArea(*panelexpage)
                EndIf
                If flags & #PNLX_UPDATESCROLLING Or *panelexpage\renderScrollbars = #True
                    updatePanelExPageScrolling(*panelexpage, 0, 0)
                    handlePanelExPageAutoScroll(*panelexpage)
                    updatePanelExPageScrollbars(*panelexpage)
                EndIf
            EndIf
            
            *rpanelex.panelexs = *trackWin\rootPanelex
            *rpanelexpage.panelexpages = *rpanelex\displayedPage
            If *rpanelex = #Null
                ProcedureReturn #False
            EndIf
            
            ; make sure not already in the middle of RefreshPanelEx for same root panelex, return if so
            If *rpanelex\insideRefresh = #True
                ProcedureReturn #False
            EndIf
            *rpanelex\insideRefresh = #True
            
            If Not flags & #PNLX_NOREDRAW And *panelex\setRedrawFalse = #False; And *panelex\animRedrawFalse = #False
                
                ; don't redraw if root panelex set WM_SETREDRAW to false
                If *rpanelex\setRedrawFalse = #True
                ;If *rpanelex\setRedrawFalse = #True Or *rpanelex\animRedrawFalse = #True
                    *rpanelex\insideRefresh = #False
                    ProcedureReturn #False
                EndIf
                
                GetClientRect_(*panelexpage\containerHandle, rc.RECT)
                MapWindowPoints_(*panelexpage\containerHandle, *trackWin\rootPanelexPageHwnd, rc, 2)
                
                setPanelExPageClippedRect(clipRc.RECT, *trackWin, #True)
                If clipRc\left = 0 And clipRc\top = 0 And clipRc\right = 0 And clipRc\bottom = 0
                    *rpanelex\insideRefresh = #False
                    ProcedureReturn #False
                EndIf
                
                ;LockMutex(updateMutex)
                
                *rpanelex.panelexs = *trackWin\rootPanelex
                If *rpanelex\updateRgn = #Null
                    rgn = CreateRectRgn_(0, 0, 0, 0)
                    *rpanelex\updateRgn = rgn
                Else
                    rgn = *rpanelex\updateRgn
                EndIf
                
                If *updateRect <> #Null
                    ;debuglog("update rect set!")
                    ;debuglog(Str(*updateRect\left) + " " + Str(*updateRect\top) + " " + Str(*updateRect\right) + " " + Str(*updateRect\bottom))
                    
                    ;*updateRect\left = 0
                    ;*updateRect\top = 0
                    ;*updateRect\right = 50
                    ;*updateRect\bottom = 50
                    ;dc = GetDC_(0)
                    ;brush = CreateSolidBrush_(RGB(255, 0, 0))
                    ;MapWindowPoints_(*trackWin\rootPanelexPageHwnd, 0, *updateRect, 2)
                    ;FillRect_(dc, *updateRect, brush)
                    ;ReleaseDC_(WindowID(0), dc)
                    
                    ;CopyStructure(*updateRect, clipRc, RECT)
                    
                    MapWindowPoints_(*panelexpage\Handle, *rpanelexpage\Handle, *updateRect, 2)
                    IntersectRect_(clipRc, clipRc, *updateRect)
                    
                EndIf
                
                IntersectRect_(rc, rc, clipRc)
                trgn = CreateRectRgnIndirect_(rc)
                CombineRgn_(rgn, trgn, rgn, #RGN_OR) ; invalidate, include in update
                DeleteObject_(trgn)
                addPanelExUpdateRect(*rpanelex, rc)
                
                *ptrackWin.trackWindows = *trackWin\parentTrackWin
                If *ptrackWin <> #Null And *ptrackWin\containsChildCntrl = #True
                    ;validatePanelexPageChildren(*trackWin, rgn)
                EndIf
                
                ;UnlockMutex(updateMutex)
                
                page = *trackWin\rootPanelexPageHwnd
                
                If *rpanelex\animRedrawFalse = #False
                    
                    ;debuglog("---------------")
                    
                    If Not flags & #PNLX_ERASEALLCHILDREN
                        RedrawWindow_(page, 0, rgn, #RDW_UPDATENOW|#RDW_NOERASE|#RDW_NOCHILDREN|#RDW_INVALIDATE|#RDW_NOFRAME)
                        
                        ;RedrawWindow_(page, 0, rgn, #RDW_UPDATENOW|#RDW_NOERASE|#RDW_INVALIDATE|#RDW_NOFRAME)
                        
;                         ;LockMutex(updateMutex)
;                         updatePanelexChildren(*rpanelex)
;                         dc = GetDC_(*rpanelexpage\Handle)
;                         SelectClipRgn_(dc, *rpanelex\updateRgn)
;                         drawPanelPage(*rpanelexpage, dc, *rpanelexpage\Handle, 0, 0)
;                         ReleaseDC_(*rpanelexpage\Handle, dc)
;                         ;updatePanelexChildren(*panelex)
;                         
;                         If *rpanelex\updateCount > 0
;                             *rpanelex\updateCount - 1
;                         Else
;                             If *rpanelex\updateRgn <> #Null
;                                 oldUpdateRgn = *rpanelex\updateRgn
;                                 *rpanelex\updateRgn = CreateRectRgn_(0, 0, 0, 0)
;                                 DeleteObject_(oldUpdateRgn)
;                                 ClearList(*rpanelex\updateRc())
;                                 ClearList(*rpanelex\updateChild())
;                             EndIf
;                         EndIf
;                         ;UnlockMutex(updateMutex)
                            
                    Else
                        RedrawWindow_(page, 0, rgn, #RDW_ERASE|#RDW_ALLCHILDREN|#RDW_INVALIDATE)
                    EndIf
                    
                EndIf
                
            EndIf
                
            *rpanelex\insideRefresh = #False
            ProcedureReturn #True
            
        EndIf
        
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL SetPanelExPageScrolling(Panel.i, index.i, flags.l, Value.l) ; Sets a PanelEx's page scrolling properties
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ; find panel page index
    ForEach *panelex\page()
        If ListIndex(*panelex\page()) = index Or *panelex\page()\Handle = index
            *panelexpage.panelexpages = *panelex\page()
            Break
        EndIf
    Next
    
    If *panelexpage <> #Null
        
        ;/ check flags for valid constants
        
        If flags & #PNLX_HSCROLL And Value = #True
            debuglog("hscroll true")
            hscroll = #True
            visible = #WS_VISIBLE
        ElseIf flags & #PNLX_HSCROLL And Value = #False
            debuglog("hscroll false")
            hscroll = -1
        EndIf
        
        If flags & #PNLX_VSCROLL And Value = #True
            debuglog("vscroll true")
            vscroll = #True
            visible = #WS_VISIBLE
        ElseIf flags & #PNLX_VSCROLL And Value = #False
            debuglog("vscroll false")
            vscroll = -1
        EndIf
        
        If flags & #PNLX_AUTOSCROLL_NOHORIZONTAL And Value = #True
            debuglog("AUTOSCROLL_NOHORIZONTAL true")
            *panelexpage\noHorizontal = #True
        ElseIf flags & #PNLX_AUTOSCROLL_NOHORIZONTAL And Value = #False
            debuglog("AUTOSCROLL_NOHORIZONTAL false")
            *panelexpage\noHorizontal = #False
        EndIf
        
        If flags & #PNLX_AUTOSCROLL_NOVERTICAL And Value = #True
            debuglog("AUTOSCROLL_NOVERTICAL true")
            *panelexpage\noVertical = #True
        ElseIf flags & #PNLX_AUTOSCROLL_NOVERTICAL And Value = #False
            debuglog("AUTOSCROLL_NOVERTICAL false")
            *panelexpage\noVertical = #False
        EndIf
        
        If flags & #PNLX_AUTOSCROLL And Value = #True
            debuglog("autoscroll true")
            hscroll = #True
            vscroll = #True
            *panelexpage\autoScroll = #True
            
            ; create hook to handle keyboard navigation
            If KeyboardHook = 0
                threadId = GetWindowThreadProcessId_(*panelexpage\Handle, 0)
                KeyboardHook = SetWindowsHookEx_(#WH_KEYBOARD, @KeyboardHook(), 0, threadId)
            EndIf
            
        ElseIf flags & #PNLX_AUTOSCROLL And Value = #False
            debuglog("autoscroll false")
            *panelexpage\autoScroll = #False
        EndIf
        
        If flags & #PNLX_SCROLLBARS_OUTSIDE And Value = #True
            debuglog("scroll bars outside of content true")
            *panelexpage\scrollbarsOutside = #True
        ElseIf flags & #PNLX_SCROLLBARS_OUTSIDE And Value = #False
            debuglog("scroll bars outside of content false")
            *panelexpage\scrollbarsOutside = #False
        EndIf
        
        If *panelex\displayedPage <> *panelexpage
            visible = #False
        EndIf
        
        ;/ create horizontal/vertical scrollbar/s if not already created
        If hscroll = #True And *panelexpage\hScrollBar = #Null And vscroll = #True And *panelexpage\vScrollBar = #Null
            
            GetClientRect_(*panelexpage\Handle, @rc.RECT)
            
            *panelexpage\hScrollBar = CreateWindowEx_(#WS_EX_TRANSPARENT, "SCROLLBAR", 0, #WS_CHILD | #SBS_HORZ | visible | #SBS_BOTTOMALIGN | #WS_CLIPSIBLINGS | #WS_CLIPCHILDREN, 0, 0, rc\right-iHThumb, rc\bottom, *panelexpage\containerHandle, 0, GetModuleHandle_(0),0)
            *panelexpage\vScrollBar = CreateWindowEx_(#WS_EX_TRANSPARENT, "SCROLLBAR", 0, #WS_CHILD | #SBS_VERT | visible | #SBS_RIGHTALIGN | #WS_CLIPSIBLINGS | #WS_CLIPCHILDREN, 0, 0, rc\right, rc\bottom-iVThumb, *panelexpage\containerHandle, 0, GetModuleHandle_(0),0)
            
            ; create scrollbar box
            *panelexpage\scrollBarBox = createScrollbarBox(*panelexpage\containerHandle, rc\right-iHThumb, rc\bottom-iVThumb, visible)
            
            *panelexpage\hScrollBarTrackWin = GetProp_(*panelexpage\hScrollBar, trackwinAtom)
            *panelexpage\vScrollBarTrackWin = GetProp_(*panelexpage\vScrollBar, trackwinAtom)
            *panelexpage\scrollBarBoxTrackWin = GetProp_(*panelexpage\scrollBarBox, trackwinAtom)
            
            debuglog("created both")
            
            calcPanelExPageArea(*panelexpage)
            handlePanelExPageAutoScroll(*panelexpage)
            updatePanelExPageScrolling(*panelexpage, 0, 0)
            updatePanelExPageScrollbars(*panelexpage)
            
        ElseIf hscroll = #True And *panelexpage\hScrollBar = #Null
            
            GetClientRect_(*panelexpage\Handle, @rc.RECT)
            
            ; create scrollbar box
            If *panelexpage\scrollBarBox = #Null
                *panelexpage\scrollBarBox = createScrollbarBox(*panelexpage\Handle, rc\right-iHThumb, rc\bottom-iVThumb, #False)
                *panelexpage\scrollBarBoxTrackWin = GetProp_(*panelexpage\scrollBarBox, trackwinAtom)
            EndIf
            
            *panelexpage\hScrollBar = CreateWindowEx_(#WS_EX_TRANSPARENT, "SCROLLBAR", 0, #WS_CHILD | #SBS_HORZ | visible | #SBS_BOTTOMALIGN, 0, 0, rc\right, rc\bottom, *panelexpage\containerHandle, 0, GetModuleHandle_(0),0)
            *panelexpage\hScrollBarTrackWin = GetProp_(*panelexpage\hScrollBar, trackwinAtom)
            
            *panelexpage\hScrollVisible = #True
            
            debuglog("created h")
            
        ElseIf vscroll = #True And *panelexpage\vScrollBar = #Null
            
            GetClientRect_(*panelexpage\Handle, @rc.RECT)
            
            ; create scrollbar box
            If *panelexpage\scrollBarBox = #Null
                *panelexpage\scrollBarBox = createScrollbarBox(*panelexpage\Handle, rc\right-iHThumb, rc\bottom-iVThumb, #False)
                *panelexpage\scrollBarBoxTrackWin = GetProp_(*panelexpage\scrollBarBox, trackwinAtom)
            EndIf
            
            *panelexpage\vScrollBar = CreateWindowEx_(#WS_EX_TRANSPARENT, "SCROLLBAR", 0, #WS_CHILD | #SBS_VERT | visible | #SBS_RIGHTALIGN, 0, 0, rc\right, rc\bottom, *panelexpage\containerHandle, 0, GetModuleHandle_(0),0)
            *panelexpage\vScrollBarTrackWin = GetProp_(*panelexpage\vScrollBar, trackwinAtom)
            
            *panelexpage\vScrollVisible = #True
            
            debuglog("created v")
            
        ;/ if scrollbars already created
        Else  
            
            ; show horizontal scrollbar if already created
            If hscroll = #True And *panelexpage\hScrollBar <> #Null
                
                ShowWindow_(*panelexpage\hScrollBar, #SW_SHOWNA) ; show scrollbar window
                *panelexpage\hScrollVisible = #True
                debuglog("show h")
                
                ; hide horizontal scrollbar if already created
            ElseIf hscroll = -1 And *panelexpage\hScrollBar <> #Null
                
                ShowWindow_(*panelexpage\hScrollBar, #SW_HIDE) ; hide scrollbar window
                *panelexpage\hScrollVisible = #False
                
            EndIf
            
            ; show vertical scrollbar if already created
            If vscroll = #True And *panelexpage\vScrollBar <> #Null
                
                ShowWindow_(*panelexpage\vScrollBar, #SW_SHOWNA) ; show scrollbar window
                *panelexpage\vScrollVisible = #True
                debuglog("show v")
                
                ; hide vertical scroll bar if already created
            ElseIf vscroll = -1 And *panelexpage\vScrollBar <> #Null
                
                ShowWindow_(*panelexpage\vScrollBar, #SW_HIDE) ; hide scrollbar window
                *panelexpage\vScrollVisible = #False
                
            EndIf
            
            If *panelexpage\scrollBarBox <> #Null And *panelexpage\hScrollVisible = #False And *panelexpage\vScrollVisible = #False
                ShowWindow_(*panelexpage\scrollBarBox, #SW_HIDE)
            EndIf
            
        EndIf
        
        updatePanelExPageScrollbars(*panelexpage)

        ProcedureReturn #True
        
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL GetPanelExPageScrolling(Panel.i, index.i, flag.l) ; Returns a PanelEx page's scrolling property value specified by flag.
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ; find panel page index
    ForEach *panelex\page()
        If ListIndex(*panelex\page()) = index Or *panelex\page()\Handle = index
            *panelexpage.panelexpages = *panelex\page()
            Break
        EndIf
    Next
    
    If *panelexpage <> #Null
        
        ;/ check flags for valid constants
        
        Select flag
            Case #PNLX_HSCROLL
                retval = *panelexpage\hScrollVisible
            Case #PNLX_VSCROLL
                retval = *panelexpage\vScrollVisible
            Case #PNLX_HSCROLLHANDLE
                retval = *panelexpage\hScrollBar
            Case #PNLX_VSCROLLHANDLE
                retval = *panelexpage\vScrollBar
            Case #PNLX_AUTOSCROLL
                retval = *panelexpage\autoScroll 
        EndSelect
        
    EndIf
    
    ProcedureReturn retval
    
EndProcedure

ProcedureDLL SetPanelExPageCursor(Panel.i, index.i, *Cursor) ; Sets a PanelEx page's mouse cursor
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ; find panel page index
    ForEach *panelex\page()
        If ListIndex(*panelex\page()) = index Or *panelex\page()\Handle = index
            *panelexpage.panelexpages = *panelex\page()
            Break
        EndIf
    Next
    
    If *panelexpage <> #Null
        
        ; if system cursor constant passed then load system cursor
        If *Cursor >= #IDC_ARROW And *Cursor <= #IDC_HELP
            *Cursor = LoadCursor_(0, *Cursor)
        EndIf
        *panelexpage\cursor = *Cursor
        
        pt.POINT
        GetCursorPos_(@pt)
        hwnd = WindowFromPoint_(PeekQ(pt))
        If hwnd = *panelexpage\Handle
            If *panelexpage\cursor > 0
                SetCursor_(*panelexpage\cursor)
            ElseIf *panelexpage\cursor = 0
                SetCursor_(normalMousePointer)
            EndIf
        EndIf
        
        ProcedureReturn *Cursor
        
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL ShowPanelExPage(Panel, index)
    
    macro_protectCommand()
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    ; find panel page index
    ForEach *panelex\page()
        If ListIndex(*panelex\page()) = index Or *panelex\page()\Handle = index
            *panelexpage.panelexpages = *panelex\page()
            Break
        EndIf
    Next
    
    If *panelexpage <> #Null
        
        *new = *panelexpage
        
        *panelexpage.panelexpages = *panelex\displayedPage
        ShowWindow_(*panelexpage\Handle, #SW_HIDE)
        
        ; hide scrollbars if any
        If GetWindowLongPtr_(*panelexpage\hScrollBar, #GWL_STYLE) & #WS_VISIBLE
            ShowWindow_(*panelexpage\hScrollBar, #SW_HIDE)
        EndIf
        If GetWindowLongPtr_(*panelexpage\vScrollBar, #GWL_STYLE) & #WS_VISIBLE
            ShowWindow_(*panelexpage\vScrollBar, #SW_HIDE)
        EndIf
        If *panelexpage\scrollBarBox <> #Null And GetWindowLongPtr_(*panelexpage\scrollBarBox, #GWL_STYLE) & #WS_VISIBLE
            ShowWindow_(*panelexpage\scrollBarBox, #SW_HIDE)
        EndIf
        
        *panelex\displayedPage = *new
        *panelexpage.panelexpages = *new
        
        If *panelexpage\autoScroll = #False
            GetClientRect_(*panelexpage\containerHandle, @rc.RECT)
            MoveWindow_(*panelexpage\Handle, 0, 0, rc\right-rc\left, rc\bottom-rc\top, #False)
        EndIf
        
        GetClientRect_(*panelexpage\Handle, @rc.RECT)
        SendMessage_(*panelexpage\Handle, #WM_SETREDRAW, #False, 0)
        ShowWindow_(*panelexpage\Handle, #SW_SHOW)
        SendMessage_(*panelexpage\Handle, #WM_SETREDRAW, #True, 0)
        
        ; show scrollbars if any
        If *panelexpage\hScrollVisible = #True
            ShowWindow_(*panelexpage\hScrollBar, #SW_SHOW)
        EndIf
        If *panelexpage\vScrollVisible = #True
            ShowWindow_(*panelexpage\vScrollBar, #SW_SHOW)
        EndIf
        
        RefreshPanelEx(*panelex\Handle, 0, #PNLX_UPDATESCROLLING)
        
        ProcedureReturn #True
        
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL PanelExID(Panel, index) ; returns the HWND of a PanelEx Page or if index = -1, the PanelEx HWND
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    If index < 0
        ProcedureReturn *panelex\handle
    EndIf
    
    ; find panel page index
    ForEach *panelex\page()
        If ListIndex(*panelex\page()) = index
            ProcedureReturn *panelex\page()\handle
        EndIf
    Next
    
    ProcedureReturn #False
    
EndProcedure


ProcedureDLL PanelExPageIndex(Panel)
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    Else
        If *panelex\displayedPage <> #Null
            ChangeCurrentElement(*panelex\page(), *panelex\displayedPage)
            ProcedureReturn ListIndex(*panelex\page())
        EndIf
    EndIf
    
    ProcedureReturn -1
    
EndProcedure

ProcedureDLL FreePanelEx(id.i)  ; Frees a PanelEx from memory.
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(id)
    If hwnd <> #Null
        id = hwnd
    EndIf
    *panelex.panelexs = GetProp_(id, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    If *panelex\destroying = #False
        DestroyWindow_(*panelex\Handle)
    EndIf
        
    ProcedureReturn #True
    
EndProcedure

ProcedureDLL FreePanelExPage(id.i, index.l) ; Removes a PanelExPage from PanelEx.
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(id)
    If hwnd <> #Null
        id = hwnd
    EndIf
    *panelex.panelexs = GetProp_(id, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    EndIf
    
    If index = -1
        *panelex\displayedPage = #Null
    EndIf
    
    ForEach *panelex\page()
        If ListIndex(*panelex\page()) = index Or index = -1
            
            DestroyWindow_(*panelex\page()\Handle)
            
            If index <> -1
                found = #True
                Break
            EndIf
        EndIf
    Next
    
    If index = -1 Or found = #True
        ProcedureReturn #True
    EndIf
    
    ProcedureReturn #False
    
EndProcedure

ProcedureDLL PanelExWidth(Panel) ; Returns width of PanelEx in pixels
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    Else
        GetWindowRect_(*panelex\Handle, rc.RECT)
        ProcedureReturn rc\right-rc\left
    EndIf
    
    ProcedureReturn -1
    
EndProcedure

ProcedureDLL PanelExHeight(Panel) ; Returns height of PanelEx in pixels
    
    ; find panel by id or handle
    hwnd = getHwndFromUniqueID(panel)
    If hwnd <> #Null
        panel = hwnd
    EndIf
    *panelex.panelexs = GetProp_(panel, panelexAtom)
    If *panelex = #Null
        ProcedureReturn #False
    Else
        GetWindowRect_(*panelex\Handle, rc.RECT)
        ProcedureReturn rc\bottom-rc\top
    EndIf
    
    ProcedureReturn -1
    
EndProcedure
; IDE Options = PureBasic 5.72 (Windows - x64)
; CursorPosition = 265
; FirstLine = 217
; Folding = ---------
; EnableXP