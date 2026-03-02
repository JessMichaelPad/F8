class MarkerOverlay {
    __New(target) {
        this.TargetHwnd := target
        Gui, New, -Caption +E0x80000 +E0x20 +LastFound +AlwaysOnTop +ToolWindow +OwnDialogs +HwndoverlayId
        this.OverlayHwnd := overlayId
        
        this.Height := 24
        this.LastW := 0
        this.LastPin := false
        this.LastLock := false
    }
    
    Destroy() {
        hwnd := this.OverlayHwnd
        Try Gui, %hwnd%:Destroy
    }
    
    EnsureZOrder() {
        hwnd := this.OverlayHwnd
        WinSet, AlwaysOnTop, On, ahk_id %hwnd%
    }
    
    Update(hasPin, hasLock) {
        this.LastPin := hasPin
        this.LastLock := hasLock
        TotalWidth := (hasPin && hasLock) ? 52 : 24
        
        WinGetPos, x, y, w, h, % "ahk_id " . this.TargetHwnd
        NewX := x + w - TotalWidth - 10 
        NewY := y + 8
        
        if (TotalWidth != this.LastW) {
            hwnd := this.OverlayHwnd
            Gui, %hwnd%:Show, NA x%NewX% y%NewY% w%TotalWidth% h24
            this.LastW := TotalWidth
        } else {
            WinMove, % "ahk_id " . this.OverlayHwnd,, %NewX%, %NewY%
        }
        
        this.Draw(TotalWidth)
    }
    
    CheckPosition() {
        TotalWidth := this.LastW
        WinGetPos, x, y, w, h, % "ahk_id " . this.TargetHwnd
        NewX := x + w - TotalWidth - 10
        NewY := y + 8
        WinMove, % "ahk_id " . this.OverlayHwnd,, %NewX%, %NewY%
    }
    
    Draw(w) {
        hbm := CreateDIBSection(w, this.Height)
        hdc := CreateCompatibleDC()
        obm := SelectObject(hdc, hbm)
        G := Gdip_GraphicsFromHDC(hdc)
        Gdip_SetSmoothingMode(G, 4) 
        
        Gdip_GraphicsClear(G)
        CurrentX := 2
        
        if (this.LastPin) {
            pBrush := Gdip_BrushCreateSolid(0xD0E04F5F) 
            Gdip_FillEllipse(G, pBrush, CurrentX, 2, 20, 20)
            Gdip_DeleteBrush(pBrush)
            
            pPen := Gdip_CreatePen(0xFFFFFFFF, 2)
            Gdip_DrawEllipse(G, pPen, CurrentX, 2, 20, 20)
            Gdip_DeletePen(pPen)
            CurrentX += 28 
        }
        
        if (this.LastLock) {
            pBrush := Gdip_BrushCreateSolid(0xD04FAFE0) 
            Gdip_FillEllipse(G, pBrush, CurrentX, 2, 20, 20)
            Gdip_DeleteBrush(pBrush)
             
            pPen := Gdip_CreatePen(0xFFFFFFFF, 2)
            Gdip_DrawEllipse(G, pPen, CurrentX, 2, 20, 20)
            
            Gdip_FillRectangle(G, pBrush := Gdip_BrushCreateSolid(0xFFFFFFFF), CurrentX + 6, 11, 8, 6)
            Gdip_DeleteBrush(pBrush)
            
            pPenLock := Gdip_CreatePen(0xFFFFFFFF, 2)
            Gdip_DrawLine(G, pPenLock, CurrentX + 7, 11, CurrentX + 7, 7)
            Gdip_DrawArc(G, pPenLock, CurrentX + 7, 5, 6, 5, 180, 180) 
            Gdip_DrawLine(G, pPenLock, CurrentX + 13, 7, CurrentX + 13, 11)
            Gdip_DeletePen(pPenLock)
            Gdip_DeletePen(pPen)
        }
        
        UpdateLayeredWindow(this.OverlayHwnd, hdc, "", "", w, this.Height)
        SelectObject(hdc, obm)
        DeleteObject(hbm)
        DeleteDC(hdc)
        Gdip_DeleteGraphics(G)
    }
}
