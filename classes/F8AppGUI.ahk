class F8AppGUI {
    __New(manager) {
        this.Manager := manager
        this.Visible := false
        this.HwndIndexMap := []
    }
    
    Toggle() {
        if (this.Visible)
            this.Hide()
        else
            this.Show()
    }
    
    Hide() {
        Try Gui, SettingsGui:Hide
        this.Visible := false
    }
    
    Show() {
        this.Manager.LoadSnapSettings()
        
        if (!WinExist("F8 Settings")) {
            this.BuildGUI()
        } else {
            GuiControl, SettingsGui:, NewX, % this.Manager.SnapX
            GuiControl, SettingsGui:, NewY, % this.Manager.SnapY
            GuiControl, SettingsGui:, NewWidth, % this.Manager.SnapW
            GuiControl, SettingsGui:, NewHeight, % this.Manager.SnapH
            GuiControl, SettingsGui:, NewTransparency, % this.Manager.SnapT
        }
        
        this.UpdateDashboard()
        Gui, SettingsGui:Show, w910 h340
        this.Visible := true
    }
    
    BuildGUI() {
        Gui, SettingsGui:New, +AlwaysOnTop -MaximizeBox -MinimizeBox, F8 Settings
        Gui, SettingsGui:Add, GroupBox, x12 y8 w280 h215, Snap Settings
        
        Gui, SettingsGui:Add, Text, x28 y36 w95 h20, X Position:
        Gui, SettingsGui:Add, Edit, x130 y34 w130 h22 vNewX, % this.Manager.SnapX
        Gui, SettingsGui:Add, Text, x28 y66 w95 h20, Y Position:
        Gui, SettingsGui:Add, Edit, x130 y64 w130 h22 vNewY, % this.Manager.SnapY
        Gui, SettingsGui:Add, Text, x28 y96 w95 h20, Width:
        Gui, SettingsGui:Add, Edit, x130 y94 w130 h22 vNewWidth, % this.Manager.SnapW
        Gui, SettingsGui:Add, Text, x28 y126 w95 h20, Height:
        Gui, SettingsGui:Add, Edit, x130 y124 w130 h22 vNewHeight, % this.Manager.SnapH
        Gui, SettingsGui:Add, Text, x28 y156 w95 h20, Transparency:
        Gui, SettingsGui:Add, Edit, x130 y154 w130 h22 vNewTransparency, % this.Manager.SnapT
        
        Gui, SettingsGui:Add, Button, x28 y186 w112 h30 default gGUICb_Apply, Apply Changes
        Gui, SettingsGui:Add, Button, x148 y186 w112 h30 gGUICb_Capture, Capture Active

        ; Apps Dashboard
        Gui, SettingsGui:Add, GroupBox, x304 y8 w590 h320, Apps Dashboard
        Gui, SettingsGui:Add, Text, x320 y30 w560 h18, Manage application states, transfer displays, or ignore apps.
        Gui, SettingsGui:Add, Text, x320 y56 w370 h20 cGray vNoAppsText hidden, No active apps found.
        Gui, SettingsGui:Add, Text, x320 y280 w360 h18 cGray vOverflowText hidden, 
        Gui, SettingsGui:Add, Button, x320 y298 w98 h24 gGUICb_Refresh, Refresh
        
        Loop, 8 {
            rY := 56 + ((A_Index - 1) * 27)
            bY := rY - 2
            Gui, SettingsGui:Add, Text, x320 y%rY% w300 h20 +0x200 vAppRowText_%A_Index% hidden, 
            Gui, SettingsGui:Add, Button, x650 y%bY% w55 h24 gGUICb_Revert vRevertBtn_%A_Index% hidden, Revert
            Gui, SettingsGui:Add, Button, x710 y%bY% w55 h24 gGUICb_Transfer vTransferBtn_%A_Index% hidden, Transfer
            Gui, SettingsGui:Add, Button, x770 y%bY% w55 h24 gGUICb_Ignore vIgnoreBtn_%A_Index% hidden, Ignore
        }
    }
    
    UpdateDashboard() {
        this.HwndIndexMap := []
        appDataObjects := []
        
        WinGet, id, List
        Loop, %id%
        {
            this_id := id%A_Index%
            if (this.Manager.IsBlockedSystemWindow(this_id))
                continue
            
            WinGetTitle, this_title, ahk_id %this_id%
            if (this_title = "" || this_title = "F8 Settings" || this_title = "Program Manager")
                continue
                
            WinGet, style, Style, ahk_id %this_id%
            if !(style & 0x10000000) 
                continue
                
            WinGet, exStyle, ExStyle, ahk_id %this_id%
            if (exStyle & 0x80)
                continue
                
            WinGet, proc, ProcessName, ahk_id %this_id%
            isExcluded := this.Manager.ExcludedApps.HasKey(proc)
            
            WinGet, es, ExStyle, ahk_id %this_id%
            isPinned := (es & 0x8)
            isLocked := (es & 0x20)
            isSnapped := (this.Manager.WindowStates.HasKey(this_id) && this.Manager.WindowStates[this_id].isSnapped)
            
            prefix := ""
            if (isExcluded)
                prefix .= "[Ignored] "
            else {
                if (isPinned)
                    prefix .= "[Pin] "
                if (isLocked)
                    prefix .= "[Lock] "
                if (isSnapped)
                    prefix .= "[Snap] "
            }
                
            renderTitle := prefix . this_title
            if (StrLen(renderTitle) > 36)
                renderTitle := SubStr(renderTitle, 1, 33) . "..."
                
            obj := {hwnd: this_id, titleLower: Format("{:L}", this_title), renderTitle: renderTitle, isExcluded: isExcluded, isPinned: isPinned, isLocked: isLocked, isSnapped: isSnapped}
            appDataObjects.Push(obj)
        }
        
        n := appDataObjects.Length()
        Loop % n - 1 {
            i := A_Index
            Loop % n - i {
                j := A_Index
                jPlus := j + 1
                if (appDataObjects[j].titleLower > appDataObjects[jPlus].titleLower) {
                    temp := appDataObjects[j]
                    appDataObjects[j] := appDataObjects[jPlus]
                    appDataObjects[jPlus] := temp
                }
            }
        }
        
        displayed := 0
        for index, appObj in appDataObjects {
            if (displayed >= 8)
                break
            displayed += 1
            
            GuiControl, SettingsGui:, AppRowText_%displayed%, % appObj.renderTitle
            GuiControl, SettingsGui:Show, AppRowText_%displayed%
            GuiControl, SettingsGui:Show, TransferBtn_%displayed%
            
            this.HwndIndexMap[displayed] := appObj.hwnd
            
            if (!appObj.isExcluded && (appObj.isPinned || appObj.isLocked || appObj.isSnapped))
                GuiControl, SettingsGui:Show, RevertBtn_%displayed%
            else
                GuiControl, SettingsGui:Hide, RevertBtn_%displayed%
                
            BtnText := appObj.isExcluded ? "Unignore" : "Ignore"
            GuiControl, SettingsGui:, IgnoreBtn_%displayed%, %BtnText%
            GuiControl, SettingsGui:Show, IgnoreBtn_%displayed%
        }
        
        loopIdx := displayed + 1
        while (loopIdx <= 8) {
            GuiControl, SettingsGui:Hide, AppRowText_%loopIdx%
            GuiControl, SettingsGui:Hide, RevertBtn_%loopIdx%
            GuiControl, SettingsGui:Hide, TransferBtn_%loopIdx%
            GuiControl, SettingsGui:Hide, IgnoreBtn_%loopIdx%
            loopIdx++
        }
        
        if (displayed = 0) {
            GuiControl, SettingsGui:Show, NoAppsText
            GuiControl, SettingsGui:Hide, OverflowText
        } else {
            GuiControl, SettingsGui:Hide, NoAppsText
            if (appDataObjects.Length() > displayed) {
                overflowText := "Showing first " . displayed . " of " . appDataObjects.Length() . " active apps."
                GuiControl, SettingsGui:, OverflowText, %overflowText%
                GuiControl, SettingsGui:Show, OverflowText
            } else {
                GuiControl, SettingsGui:Hide, OverflowText
            }
        }
    }
}
