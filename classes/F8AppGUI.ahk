class F8AppGUI {
    __New(manager) {
        this.Manager := manager
        this.Visible := false
        this.HwndIndexMap := []
        this.RefreshFn := ObjBindMethod(this, "UpdateDashboard")
        this.QuickPickerAction := ""
        this.VisibleQuickPicker := ""
        this.PendingDeleteZone := ""
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
        fn := this.RefreshFn
        SetTimer, %fn%, Off
    }
    
    Show() {
        global NewX, NewY, NewWidth, NewHeight, NewTransparency
        this.Manager.LoadSnapSettings()
        
        if (!WinExist("F8 Settings")) {
            this.BuildGUI()
        }
        
        ; Grab attributes of currently active window (before GUI takes focus)
        hwnd := WinExist("A")
        if (hwnd && !this.Manager.IsBlockedSystemWindow(hwnd) && hwnd != WinExist("F8 Settings")) {
            state := this.Manager.GetState(hwnd)
            
            ; Default to current window metrics
            WinGetPos, cX, cY, cW, cH, ahk_id %hwnd%
            WinGet, cT, Transparent, ahk_id %hwnd%
            if (cT = "" || cT = 255)
                cT := 255
            zoneName := ""

            ; If window is snapped to a known zone, pull the ACTUAL zone config instead
            if (state.isSnapped && state.currentZone != "" && this.Manager.SnapZones.HasKey(state.currentZone)) {
                zone := this.Manager.SnapZones[state.currentZone]
                cX := zone.x, cY := zone.y, cW := zone.w, cH := zone.h, cT := zone.t
                zoneName := state.currentZone
            }
            
            GuiControl, SettingsGui:, NewX, %cX%
            GuiControl, SettingsGui:, NewY, %cY%
            GuiControl, SettingsGui:, NewWidth, %cW%
            GuiControl, SettingsGui:, NewHeight, %cH%
            GuiControl, SettingsGui:, NewTransparency, %cT%
            GuiControl, SettingsGui:, SelectedZoneName, %zoneName%
        }
        
        this.UpdateDashboard()
        this.UpdateZonesList()
        Gui, SettingsGui:Show, w815 h340
        this.Visible := true
        
        fn := this.RefreshFn
        SetTimer, %fn%, 1500
    }
    
    BuildGUI() {
        global NewX, NewY, NewWidth, NewHeight, NewTransparency
        global NoAppsText, OverflowText
        global AppRowText_1, AppRowText_2, AppRowText_3, AppRowText_4
        global AppRowText_5, AppRowText_6, AppRowText_7, AppRowText_8
        global RevertBtn_1, RevertBtn_2, RevertBtn_3, RevertBtn_4
        global RevertBtn_5, RevertBtn_6, RevertBtn_7, RevertBtn_8
        global TransferBtn_1, TransferBtn_2, TransferBtn_3, TransferBtn_4
        global TransferBtn_5, TransferBtn_6, TransferBtn_7, TransferBtn_8
        global IgnoreBtn_1, IgnoreBtn_2, IgnoreBtn_3, IgnoreBtn_4
        global IgnoreBtn_5, IgnoreBtn_6, IgnoreBtn_7, IgnoreBtn_8
        global ZoneList, SelectedZoneName
        
        Gui, SettingsGui:New, +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndSettingsHwnd, F8 Settings
        global hIconSmall, hIconBig
        if (hIconSmall)
            SendMessage, 0x80, 0, hIconSmall,, ahk_id %SettingsHwnd%
        if (hIconBig)
            SendMessage, 0x80, 1, hIconBig,, ahk_id %SettingsHwnd%
        Gui, SettingsGui:Add, GroupBox, x12 y8 w280 h245, Snap Settings
        
        Gui, SettingsGui:Add, Text, x28 y36 w95 h20, X Position:
        Gui, SettingsGui:Add, Edit, x130 y34 w130 h22 vNewX, % this.Manager.SnapX
        Gui, SettingsGui:Add, Text, x28 y66 w95 h20, Y Position:
        Gui, SettingsGui:Add, Edit, x130 y64 w130 h22 vNewY, % this.Manager.SnapY
        Gui, SettingsGui:Add, Text, x28 y96 w95 h20, Width:
        Gui, SettingsGui:Add, Edit, x130 y94 w130 h22 vNewWidth, % this.Manager.SnapW
        Gui, SettingsGui:Add, Text, x28 y126 w95 h20, Height:
        Gui, SettingsGui:Add, Edit, x130 y124 w130 h22 vNewHeight, % this.Manager.SnapH
        Gui, SettingsGui:Add, Text, x28 y156 w95 h20, Alpha (0-255):
        Gui, SettingsGui:Add, Edit, x130 y154 w130 h22 vNewTransparency, 179
        
        Gui, SettingsGui:Add, Text, x28 y186 w95 h20, Zone Name:
        Gui, SettingsGui:Add, Edit, x130 y184 w130 h22 vSelectedZoneName, 
        
        Gui, SettingsGui:Add, Button, x28 y212 w80 h26 default gGUICb_SaveZone, Save Zone
        Gui, SettingsGui:Add, Button, x112 y212 w80 h26 gGUICb_Capture, Capture
        Gui, SettingsGui:Add, Button, x196 y212 w80 h26 gGUICb_DeleteZone, Delete
        
        Gui, SettingsGui:Add, GroupBox, x12 y258 w280 h70, Saved Snap Zones
        Gui, SettingsGui:Add, ListBox, x20 y275 w264 h45 vZoneList gGUICb_SelectZone, 

        ; Apps Dashboard
        Gui, SettingsGui:Add, GroupBox, x304 y8 w495 h320, Apps Dashboard
        Gui, SettingsGui:Add, Text, x320 y30 w465 h18, Manage application states, transfer displays, or ignore apps.
        Gui, SettingsGui:Add, Text, x320 y56 w280 h20 cGray vNoAppsText hidden, No active apps found.
        Gui, SettingsGui:Add, Text, x320 y280 w280 h18 cGray vOverflowText hidden, 
        ; Refresh button removed as per user request (Auto-refresh enabled)
        
        Loop, 8 {
            rY := 56 + ((A_Index - 1) * 27)
            bY := rY - 2
            Gui, SettingsGui:Add, Text, x320 y%rY% w280 h20 +0x200 vAppRowText_%A_Index% hidden, 
            Gui, SettingsGui:Add, Button, x610 y%bY% w55 h24 gGUICb_Revert vRevertBtn_%A_Index% hidden, Revert
            Gui, SettingsGui:Add, Button, x670 y%bY% w55 h24 gGUICb_Transfer vTransferBtn_%A_Index% hidden, Transfer
            Gui, SettingsGui:Add, Button, x730 y%bY% w55 h24 gGUICb_Ignore vIgnoreBtn_%A_Index% hidden, Ignore
        }
    }
    
    UpdateDashboard() {
        global NoAppsText, OverflowText
        global AppRowText_1, AppRowText_2, AppRowText_3, AppRowText_4
        global AppRowText_5, AppRowText_6, AppRowText_7, AppRowText_8
        global RevertBtn_1, RevertBtn_2, RevertBtn_3, RevertBtn_4
        global RevertBtn_5, RevertBtn_6, RevertBtn_7, RevertBtn_8
        global TransferBtn_1, TransferBtn_2, TransferBtn_3, TransferBtn_4
        global TransferBtn_5, TransferBtn_6, TransferBtn_7, TransferBtn_8
        global IgnoreBtn_1, IgnoreBtn_2, IgnoreBtn_3, IgnoreBtn_4
        global IgnoreBtn_5, IgnoreBtn_6, IgnoreBtn_7, IgnoreBtn_8
        
        this.HwndIndexMap := []
        appDataObjects := []
        
        WinGet, id, List
        Loop, %id%
        {
            this_id := id%A_Index%
            if (this.Manager.IsBlockedSystemWindow(this_id))
                continue
            
            WinGetTitle, this_title, ahk_id %this_id%
            if (this_title = "" || this_title = "F8 Settings" || this_title = "Program Manager" || InStr(this_title, "Quick Snap - ") || InStr(this_title, "Quick Capture - ") || this_title = "Confirm Delete" || this_title = "New Zone")
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
            if (StrLen(renderTitle) > 34)
                renderTitle := SubStr(renderTitle, 1, 31) . "..."
                
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
    
    UpdateZonesList(selectMatch:="") {
        global ZoneList
        ZoneString := ""
        for name in this.Manager.SnapZones {
            ZoneString .= name . "|"
        }
        GuiControl, SettingsGui:, ZoneList, |%ZoneString%
        if (selectMatch != "")
            GuiControl, SettingsGui:ChooseString, ZoneList, %selectMatch%
    }
    
    ShowQuickPicker(action, appName:="") {
        global QuickPickerList
        this.QuickPickerAction := action
        this.VisibleQuickPicker := action
        
        Title := (action = "Capture") ? "Quick Capture - " : "Quick Snap - "
        Title .= (appName != "") ? appName : "Select Slot"
        
        Gui, QuickPicker:New, +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndpickerHwnd, %Title%
        global hIconSmall, hIconBig
        if (hIconSmall)
            SendMessage, 0x80, 0, hIconSmall,, ahk_id %pickerHwnd%
        if (hIconBig)
            SendMessage, 0x80, 1, hIconBig,, ahk_id %pickerHwnd%
        
        ZoneString := ""
        if (action = "Capture")
            ZoneString .= "[Add New Zone]|"
            
        for name in this.Manager.SnapZones {
            ZoneString .= name . "|"
        }
        
        Gui, QuickPicker:Add, ListBox, x10 y10 w200 h120 vQuickPickerList gGUICb_QuickPickerSelect, %ZoneString%
        Gui, QuickPicker:Add, Button, x10 y140 w95 h26 default gGUICb_QuickPickerConfirm, Confirm
        Gui, QuickPicker:Add, Button, x115 y140 w95 h26 gGUICb_QuickPickerCancel, Cancel
        
        ; Position near mouse
        CoordMode, Mouse, Screen
        MouseGetPos, mx, my
        Gui, QuickPicker:Show, x%mx% y%my% w220 h175
    }
    
    HideQuickPicker() {
        Try Gui, QuickPicker:Destroy
        this.VisibleQuickPicker := ""
        if (this.Manager.PendingHwnd && WinExist("ahk_id " . this.Manager.PendingHwnd)) {
            WinActivate, % "ahk_id " . this.Manager.PendingHwnd
        }
    }

    ShowConfirmDelete(zoneName) {
        this.PendingDeleteZone := zoneName
        Gui, ConfirmGui:New, +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndhConfirm, Confirm Delete
        global hIconSmall, hIconBig
        if (hIconSmall)
            SendMessage, 0x80, 0, hIconSmall,, ahk_id %hConfirm%
        if (hIconBig)
            SendMessage, 0x80, 1, hIconBig,, ahk_id %hConfirm%
            
        Gui, ConfirmGui:Font, s10
        Gui, ConfirmGui:Add, Text, x20 y20 w310, Are you sure you want to delete Zone: '%zoneName%'?
        Gui, ConfirmGui:Add, Button, x70 y60 w90 h28 default gGUICb_ConfirmDeleteYes, Yes
        Gui, ConfirmGui:Add, Button, x180 y60 w90 h28 gGUICb_ConfirmDeleteNo, No
        Gui, ConfirmGui:Show, w340 h105
    }

    HideConfirmDelete() {
        Try Gui, ConfirmGui:Destroy
        this.PendingDeleteZone := ""
    }
}
