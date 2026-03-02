class WindowManager {
    __New() {
        this.Overlays := {}
        this.WindowStates := {}
        this.ExcludedApps := {}
        
        this.SnapX := ""
        this.SnapY := ""
        this.SnapW := ""
        this.SnapH := ""
        this.SnapT := 179
        
        this.LoadExcludedApps()
        this.LoadSnapSettings()
    }
    
    ; --- File I/O ---
    LoadExcludedApps() {
        IniRead, AppList, settings.ini, ExcludedApps, List, %A_Space%
        if (AppList != "") {
            Loop, Parse, AppList, |
            {
                if (A_LoopField != "")
                    this.ExcludedApps[A_LoopField] := true
            }
        }
    }
    
    SaveExcludedApps() {
        OutList := ""
        for procName, _ in this.ExcludedApps {
            if (OutList = "")
                OutList := procName
            else
                OutList .= "|" . procName
        }
        IniWrite, %OutList%, settings.ini, ExcludedApps, List
    }
    
    LoadSnapSettings() {
        IniRead, x, settings.ini, Settings, NewX, %A_Space%
        IniRead, y, settings.ini, Settings, NewY, %A_Space%
        IniRead, w, settings.ini, Settings, NewWidth, %A_Space%
        IniRead, h, settings.ini, Settings, NewHeight, %A_Space%
        IniRead, t, settings.ini, Settings, NewTransparency, 179
        this.SnapX := x
        this.SnapY := y
        this.SnapW := w
        this.SnapH := h
        this.SnapT := t
    }
    
    SaveSnapSettings() {
        IniWrite, % this.SnapX, settings.ini, Settings, NewX
        IniWrite, % this.SnapY, settings.ini, Settings, NewY
        IniWrite, % this.SnapW, settings.ini, Settings, NewWidth
        IniWrite, % this.SnapH, settings.ini, Settings, NewHeight
        IniWrite, % this.SnapT, settings.ini, Settings, NewTransparency
    }
    
    ; --- Validation / Checking ---
    CanManage(hwnd) {
        if (!hwnd)
            return false
            
        WinGet, procName, ProcessName, ahk_id %hwnd%
        if (this.ExcludedApps.HasKey(procName)) {
            ToolTip, % "This application (" . procName . ") is currently ignored."
            SetTimer, CloseToolTip, -1600
            return false
        }
        
        if (this.IsBlockedSystemWindow(hwnd)) {
            ToolTip, % "Protected system UI cannot be pinned, locked, or snapped."
            SetTimer, CloseToolTip, -1600
            return false
        }
        
        return true
    }
    
    IsBlockedSystemWindow(hwnd) {
        static blockedClasses := {"Shell_TrayWnd":1, "Shell_SecondaryTrayWnd":1, "TaskSwitcherWnd":1, "MultitaskingViewFrame":1, "#32771":1, "XamlExplorerHostIslandWindow":1, "Xaml_WindowedPopupClass":1, "ForegroundStaging":1, "NotifyIconOverflowWindow":1, "WorkerW":1, "Progman":1}
        
        if !WinExist("ahk_id " hwnd)
            return false

        WinGetClass, className, ahk_id %hwnd%
        WinGetTitle, winTitle, ahk_id %hwnd%
        WinGet, procName, ProcessName, ahk_id %hwnd%

        if (blockedClasses.HasKey(className))
            return true

        if (className = "Windows.UI.Core.CoreWindow") {
            if (procName = "explorer.exe" || procName = "SearchHost.exe" || procName = "StartMenuExperienceHost.exe" || procName = "ShellExperienceHost.exe")
                return true
        }

        if (winTitle = "Task Switching" || InStr(winTitle, "Task View"))
            return true

        return false
    }
    
    GetState(hwnd) {
        if (!this.WindowStates.HasKey(hwnd))
            this.WindowStates[hwnd] := {isSnapped: false, lastTrigger: "", OW: "", OH: "", OX: "", OY: ""}
        return this.WindowStates[hwnd]
    }
    
    ; --- Actions ---
    ToggleIgnoreStatus(hwnd) {
        WinGet, procName, ProcessName, ahk_id %hwnd%
        if (this.ExcludedApps.HasKey(procName)) {
            this.ExcludedApps.Delete(procName)
        } else {
            this.RevertWindow(hwnd)
            this.ExcludedApps[procName] := true
        }
        this.SaveExcludedApps()
    }
    
    TransferDisplay(hwnd) {
        WinActivate, ahk_id %hwnd%
        WinWaitActive, ahk_id %hwnd%,, 1
        Send, +#{Right}
    }
    
    TogglePin(hwnd) {
        Winset, Alwaysontop, Toggle, ahk_id %hwnd%
        state := this.GetState(hwnd)
        state.lastTrigger := "pin"
        this.UpdateOverlay(hwnd)
    }
    
    ToggleLock(hwnd) {
        WinGet, exStyle, ExStyle, ahk_id %hwnd%
        if (exStyle & 0x20)
            WinSet, ExStyle, -0x20, ahk_id %hwnd%
        else
            WinSet, ExStyle, +0x20, ahk_id %hwnd%
            
        state := this.GetState(hwnd)
        state.lastTrigger := "lock"
        this.UpdateOverlay(hwnd)
    }
    
    ModifyTransparency(hwnd, dir) {
        DetectHiddenWindows, on
        WinGet, curtrans, Transparent, ahk_id %hwnd%
        if (curtrans = "")
            curtrans := 255
        
        newtrans := curtrans + dir
        if (newtrans > 255)
            newtrans := 255
        else if (newtrans < 1)
            newtrans := 1
            
        WinSet, Transparent, %newtrans%, ahk_id %hwnd%
    }
    
    ToggleSnap(hwnd) {
        this.LoadSnapSettings()
        state := this.GetState(hwnd)
        state.lastTrigger := "snap"
        
        if (state.isSnapped) {
            this.RevertSnapped(hwnd)
            this.UpdateOverlay(hwnd)
        } else {
            WinGetPos, ox, oy, ow, oh, ahk_id %hwnd%
            state.OX := ox
            state.OY := oy
            state.OW := ow
            state.OH := oh
            state.isSnapped := true
            
            TargetX := (this.SnapX = "" ? ox : this.SnapX)
            TargetY := (this.SnapY = "" ? oy : this.SnapY)
            TargetW := (this.SnapW = "" ? ow : this.SnapW)
            TargetH := (this.SnapH = "" ? oh : this.SnapH)
            
            this.EnsureWindowedForMove(hwnd)
            this.MoveWindowReliable(hwnd, TargetX, TargetY, TargetW, TargetH)
            WinSet, Transparent, % this.SnapT, ahk_id %hwnd%
            Winset, Alwaysontop, On, ahk_id %hwnd%
            Winset, exStyle, +0x20, ahk_id %hwnd%
            
            this.UpdateOverlay(hwnd)
        }
    }
    
    ToggleGhost(hwnd) {
        state := this.GetState(hwnd)
        state.lastTrigger := "ghost"
        
        wasFull := this.EnsureWindowedForMove(hwnd)
        if (wasFull) {
            this.LoadSnapSettings()
            WinGetPos, cx, cy, cw, ch, ahk_id %hwnd%
            tx := (this.SnapX = "" ? cx : this.SnapX)
            ty := (this.SnapY = "" ? cy : this.SnapY)
            tw := (this.SnapW = "" ? cw : this.SnapW)
            th := (this.SnapH = "" ? ch : this.SnapH)
            this.MoveWindowReliable(hwnd, tx, ty, tw, th)
        }
        
        WinGet, es, ExStyle, ahk_id %hwnd%
        WinGet, tr, Transparent, ahk_id %hwnd%
        
        isPin := (es & 0x8)
        isLock := (es & 0x20)
        isGhostTrans := (tr >= 170 && tr <= 190)
        
        if (isPin && isLock && isGhostTrans) {
            WinSet, AlwaysOnTop, Off, ahk_id %hwnd%
            WinSet, ExStyle, -0x20, ahk_id %hwnd%
            WinSet, Transparent, 255, ahk_id %hwnd%
        } else {
            WinSet, AlwaysOnTop, On, ahk_id %hwnd%
            WinSet, ExStyle, +0x20, ahk_id %hwnd%
            WinSet, Transparent, 179, ahk_id %hwnd%
        }
        
        this.UpdateOverlay(hwnd)
    }
    
    CaptureSettings() {
        hwnd := WinExist("A")
        WinGetPos, cX, cY, cW, cH, ahk_id %hwnd%
        WinGet, cT, Transparent, ahk_id %hwnd%
        if (cT = "")
            cT := 255
            
        MsgBox, 36, Confirm Capture, Are you sure you want to overwrite snap settings?`n`nPos: %cX%`, %cY%`nSize: %cW%x%cH%`nTrans: %cT%
        IfMsgBox, No
            return
            
        this.SnapX := cX
        this.SnapY := cY
        this.SnapW := cW
        this.SnapH := cH
        this.SnapT := cT
        this.SaveSnapSettings()
        
        ToolTip, Settings Captured!`nPos: %cX%`,%cY%`nSize: %cW%x%cH%`nTrans: %cT%
        SetTimer, CloseToolTip, 2000
        
        global AppGUI
        if (AppGUI.Visible)
            AppGUI.UpdateDashboard()
    }
    
    ShowInfo() {
        hwnd := WinExist("A")
        WinGetTitle, t, ahk_id %hwnd%
        WinGet, tr, Transparent, ahk_id %hwnd%
        WinGetPos, x, y, w, h, ahk_id %hwnd%
        
        TransDisplay := (tr = "" || tr = 255) ? "Opaque" : Round((tr/255)*100) . "%"
        InfoText := "Active Window: " . t . "`nTransparency: " . TransDisplay . "`nPos: " . x . ", " . y . "`nSize: " . w . " x " . h . "`nAttributes: "
        
        WinGet, ex, ExStyle, ahk_id %hwnd%
        if (ex & 0x8)
            InfoText .= "[Pinned] "
        if (ex & 0x20)
            InfoText .= "[Locked]"
            
        ToolTip, %InfoText%
        SetTimer, CloseToolTip, 6000
    }
    
    ; --- Window Restorations ---
    RevertWindow(hwnd) {
        if !WinExist("ahk_id " hwnd)
            return
            
        state := this.GetState(hwnd)
        trigger := state.lastTrigger
        
        if (trigger = "snap" && state.isSnapped) {
            this.RevertSnapped(hwnd)
        } else if (trigger = "ghost") {
            WinGet, es, ExStyle, ahk_id %hwnd%
            WinGet, curTrans, Transparent, ahk_id %hwnd%
            if ((es & 0x8) || (es & 0x20) || (curTrans >= 170 && curTrans <= 190)) {
                WinSet, AlwaysOnTop, Off, ahk_id %hwnd%
                WinSet, ExStyle, -0x20, ahk_id %hwnd%
                WinSet, Transparent, 255, ahk_id %hwnd%
            }
        } else if (trigger = "pin") {
            WinSet, AlwaysOnTop, Off, ahk_id %hwnd%
        } else if (trigger = "lock") {
            WinSet, ExStyle, -0x20, ahk_id %hwnd%
        } else if (state.isSnapped) {
            this.RevertSnapped(hwnd)
        } else {
            WinSet, Transparent, 255, ahk_id %hwnd%
            WinSet, AlwaysOnTop, Off, ahk_id %hwnd%
            WinSet, ExStyle, -0x20, ahk_id %hwnd%
        }
        
        state.lastTrigger := ""
        this.UpdateOverlay(hwnd)
    }
    
    RevertSnapped(hwnd) {
        state := this.GetState(hwnd)
        if (state.isSnapped) {
            WinMove, ahk_id %hwnd%,, state.OX, state.OY, state.OW, state.OH
            WinSet, Transparent, 255, ahk_id %hwnd%
            Winset, Alwaysontop, Off, ahk_id %hwnd%
            Winset, exStyle, -0x20, ahk_id %hwnd%
            state.isSnapped := false
        }
    }
    
    ; --- Utility Native Wrappers ---
    EnsureWindowedForMove(hwnd) {
        wasFullscreen := false
        WinGet, minMaxState, MinMax, ahk_id %hwnd%
        if (minMaxState = 1 || minMaxState = -1) {
            WinRestore, ahk_id %hwnd%
            Sleep, 120
            wasFullscreen := true
        }

        if (this.IsLikelyFullscreen(hwnd)) {
            WinGet, style, Style, ahk_id %hwnd%
            if (style & 0x80000000)
                WinSet, Style, -0x80000000, ahk_id %hwnd%
            if !(style & 0x00C00000)
                WinSet, Style, +0x00C00000, ahk_id %hwnd%
            if !(style & 0x00040000)
                WinSet, Style, +0x00040000, ahk_id %hwnd%
            if !(style & 0x00020000)
                WinSet, Style, +0x00020000, ahk_id %hwnd%
            if !(style & 0x00010000)
                WinSet, Style, +0x00010000, ahk_id %hwnd%

            DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x0027) 
            Sleep, 120
            wasFullscreen := true
        }
        return wasFullscreen
    }
    
    MoveWindowReliable(hwnd, x, y, w, h) {
        WinMove, ahk_id %hwnd%,, %x%, %y%, %w%, %h%
        Sleep, 80
        WinGetPos, curX, curY, curW, curH, ahk_id %hwnd%
        tolerance := 2
        if (Abs(curX - x) > tolerance || Abs(curY - y) > tolerance || Abs(curW - w) > tolerance || Abs(curH - h) > tolerance) {
            DllCall("SetWindowPos", "Ptr", hwnd, "Ptr", 0, "Int", x, "Int", y, "Int", w, "Int", h, "UInt", 0x0044)
        }
    }
    
    IsLikelyFullscreen(hwnd) {
        WinGetPos, wx, wy, ww, wh, ahk_id %hwnd%
        if (ww = "" || wh = "")
            return false

        hMon := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", 2, "Ptr")
        if (!hMon)
            return false

        VarSetCapacity(mi, 40, 0)
        NumPut(40, mi, 0, "UInt")
        if !DllCall("GetMonitorInfo", "Ptr", hMon, "Ptr", &mi)
            return false

        monLeft := NumGet(mi, 4, "Int")
        monTop := NumGet(mi, 8, "Int")
        monRight := NumGet(mi, 12, "Int")
        monBottom := NumGet(mi, 16, "Int")

        monW := monRight - monLeft
        monH := monBottom - monTop
        tolerance := 2

        return (Abs(wx - monLeft) <= tolerance && Abs(wy - monTop) <= tolerance && Abs(ww - monW) <= tolerance && Abs(wh - monH) <= tolerance)
    }
    
    ChangeScreenOrientation(Orientation := 0) {
        CoordMode, Mouse, Screen
        MouseGetPos, mouseX, mouseY
        point := (mouseY << 32) | (mouseX & 0xFFFFFFFF)
        hMon := DllCall("MonitorFromPoint", "Int64", point, "UInt", 2, "Ptr")

        VarSetCapacity(MONITORINFOEX, 104, 0)
        NumPut(104, MONITORINFOEX, 0, "UInt")
        DllCall("GetMonitorInfo", "Ptr", hMon, "Ptr", &MONITORINFOEX)
        deviceName := StrGet(&MONITORINFOEX + 40, 32)

        monLeft := NumGet(MONITORINFOEX, 4, "Int")
        monTop := NumGet(MONITORINFOEX, 8, "Int")
        monRight := NumGet(MONITORINFOEX, 12, "Int")
        monBottom := NumGet(MONITORINFOEX, 16, "Int")

        oldW := monRight - monLeft
        oldH := monBottom - monTop
        if (oldW = 0)
            oldW := 1
        if (oldH = 0)
            oldH := 1

        VarSetCapacity(DEVMODE, 220, 0)
        NumPut(220, DEVMODE, 68, "UShort")
        DllCall("EnumDisplaySettings", "Str", deviceName, "Int", -1, "Ptr", &DEVMODE)
        dmPelsWidth := NumGet(DEVMODE, 172, "UInt")
        dmPelsHeight := NumGet(DEVMODE, 176, "UInt")

        if (Orientation = 90 || Orientation = 270) {
            if (dmPelsWidth > dmPelsHeight) {
                temp := dmPelsWidth, dmPelsWidth := dmPelsHeight, dmPelsHeight := temp
            }
        } else {
            if (dmPelsHeight > dmPelsWidth) {
                temp := dmPelsWidth, dmPelsWidth := dmPelsHeight, dmPelsHeight := temp
            }
        }

        NumPut(Orientation/90, DEVMODE, 84, "UInt")
        NumPut(dmPelsWidth, DEVMODE, 172, "UInt")
        NumPut(dmPelsHeight, DEVMODE, 176, "UInt")

        DllCall("ChangeDisplaySettingsEx", "Str", deviceName, "Ptr", &DEVMODE, "Ptr", 0, "UInt", 0, "Ptr", 0)

        Sleep, 300 
        VarSetCapacity(DEVMODE_NEW, 220, 0)
        NumPut(220, DEVMODE_NEW, 68, "UShort")
        if (DllCall("EnumDisplaySettings", "Str", deviceName, "Int", -1, "Ptr", &DEVMODE_NEW)) {
            newMonLeft := NumGet(DEVMODE_NEW, 76, "Int")
            newMonTop := NumGet(DEVMODE_NEW, 80, "Int")
        } else {
            newMonLeft := monLeft
            newMonTop := monTop
        }

        newX := newMonLeft + (dmPelsWidth // 2)
        newY := newMonTop + (dmPelsHeight // 2)
        MouseMove, %newX%, %newY%, 0
    }
    
    ; --- Overlay Graphics ---
    UpdateOverlay(hwnd) {
        if (!hwnd)
            return
            
        WinGet, procName, ProcessName, ahk_id %hwnd%
        if (this.IsBlockedSystemWindow(hwnd) || this.ExcludedApps.HasKey(procName)) {
            if (this.Overlays.HasKey(hwnd)) {
                this.Overlays[hwnd].Destroy()
                this.Overlays.Delete(hwnd)
            }
            return
        }
        
        WinGet, es, ExStyle, ahk_id %hwnd%
        isPinned := (es & 0x8)
        isLocked := (es & 0x20)
        
        if (!isPinned && !isLocked) {
            if (this.Overlays.HasKey(hwnd)) {
                this.Overlays[hwnd].Destroy()
                this.Overlays.Delete(hwnd)
            }
            return
        }
        
        if (!this.Overlays.HasKey(hwnd))
            this.Overlays[hwnd] := new MarkerOverlay(hwnd)
            
        this.Overlays[hwnd].Update(isPinned, isLocked)
    }
    
    MonitorOverlays() {
        for targetHwnd, overlayObj in this.Overlays {
            if (!this.Overlays.HasKey(targetHwnd))
                continue
                
            if !WinExist("ahk_id " . targetHwnd) {
                overlayObj.Destroy()
                this.Overlays.Delete(targetHwnd)
                this.WindowStates.Delete(targetHwnd)
                continue
            }
            
            WinGet, procName, ProcessName, ahk_id %targetHwnd%
            if (this.IsBlockedSystemWindow(targetHwnd) || this.ExcludedApps.HasKey(procName)) {
                if (!this.ExcludedApps.HasKey(procName)) {
                    WinSet, ExStyle, -0x20, ahk_id %targetHwnd%
                    WinSet, Transparent, 255, ahk_id %targetHwnd%
                }
                overlayObj.Destroy()
                this.Overlays.Delete(targetHwnd)
                this.WindowStates.Delete(targetHwnd)
                continue
            }
            
            WinGet, es, ExStyle, ahk_id %targetHwnd%
            isPinned := (es & 0x8)
            isLocked := (es & 0x20)
            
            if (!isPinned && !isLocked) {
                overlayObj.Destroy()
                this.Overlays.Delete(targetHwnd)
                continue
            }
            
            overlayObj.CheckPosition()
            overlayObj.EnsureZOrder()
        }
    }
}
