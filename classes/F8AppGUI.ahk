class F8AppGUI {
    __New(manager) {
        this.Manager := manager
        this.Visible := false
        this.HwndIndexMap := []
        this.RefreshFn := ObjBindMethod(this, "UpdateDashboard")
        this.SelectedZoneOriginalName := ""
        this.QuickPickerAction := ""
        this.VisibleQuickPicker := ""
        this.PendingDeleteZone := ""
        this.QuickPickerHwnd := ""
        this.QuickPickerItems := []
        this.QuickPickerSelectionIndex := 0
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
        this.SelectedZoneOriginalName := ""
        
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
            this.SelectedZoneOriginalName := zoneName
        }
        
        this.UpdateDashboard()
        this.UpdateZonesList()
        Gui, SettingsGui:Show, w815 h430
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
        
        Gui, SettingsGui:Add, GroupBox, x12 y258 w280 h160, Saved Snap Zones
        Gui, SettingsGui:Add, ListBox, x20 y275 w264 h135 vZoneList gGUICb_SelectZone, 

        ; Apps Dashboard
        Gui, SettingsGui:Add, GroupBox, x304 y8 w495 h410, Apps Dashboard
        Gui, SettingsGui:Add, Text, x320 y30 w465 h18, Manage application states, transfer displays, or ignore apps.
        Gui, SettingsGui:Add, Text, x320 y56 w280 h20 cGray vNoAppsText hidden, No active apps found.
        Gui, SettingsGui:Add, Text, x320 y370 w280 h18 cGray vOverflowText hidden, 
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
        if (selectMatch != "") {
            GuiControl, SettingsGui:ChooseString, ZoneList, %selectMatch%
            this.SelectedZoneOriginalName := selectMatch
        }
    }

    ClearZoneSelection() {
        this.SelectedZoneOriginalName := ""
        GuiControl, SettingsGui:Choose, ZoneList, 0
    }
    
    ShowQuickPicker(action, appName:="") {
        global QuickPickerList, QuickPickerIsActive
        QuickPickerIsActive := true
        this.QuickPickerAction := action
        this.VisibleQuickPicker := action
        this.BuildQuickPickerItems(action)
        
        Title := (action = "Capture") ? "Quick Capture - " : "Quick Snap - "
        Title .= (appName != "") ? appName : "Select Slot"
        
        Gui, QuickPicker:New, +AlwaysOnTop -MaximizeBox -MinimizeBox +HwndpickerHwnd, %Title%
        this.QuickPickerHwnd := pickerHwnd
        global hIconSmall, hIconBig
        if (hIconSmall)
            SendMessage, 0x80, 0, hIconSmall,, ahk_id %pickerHwnd%
        if (hIconBig)
            SendMessage, 0x80, 1, hIconBig,, ahk_id %pickerHwnd%
        
        ZoneString := this.BuildQuickPickerListString()
        
        Gui, QuickPicker:Add, ListBox, x10 y10 w200 h120 vQuickPickerList gGUICb_QuickPickerSelect, %ZoneString%
        Gui, QuickPicker:Add, Button, x10 y140 w95 h26 gGUICb_QuickPickerConfirm, Confirm
        Gui, QuickPicker:Add, Button, x115 y140 w95 h26 gGUICb_QuickPickerCancel, Cancel
        
        Gui, QuickPicker:Show, Hide AutoSize
        WinGetPos, , , pickerW, pickerH, ahk_id %pickerHwnd%
        if (pickerW = "" || pickerH = "") {
            pickerW := 236
            pickerH := 214
        }

        pos := this.GetQuickPickerShowPosition(pickerW, pickerH)
        showX := pos.x
        showY := pos.y
        Gui, QuickPicker:Show, x%showX% y%showY% AutoSize

        WinGetPos, , , actualW, actualH, ahk_id %pickerHwnd%
        if (actualW != "" && actualH != "") {
            finalPos := this.GetQuickPickerShowPosition(actualW, actualH)
            finalX := finalPos.x
            finalY := finalPos.y
            WinMove, ahk_id %pickerHwnd%,, %finalX%, %finalY%
        }
        this.SetQuickPickerSelection(this.GetInitialQuickPickerIndex())
        ControlFocus, ListBox1, ahk_id %pickerHwnd%
        ; Flush any lingering logical Alt modifier state so a/s/w/d fire as plain keys immediately
        SendInput {Alt Up}
    }
    
    HideQuickPicker() {
        global QuickPickerIsActive
        QuickPickerIsActive := false
        Try Gui, QuickPicker:Destroy
        this.VisibleQuickPicker := ""
        this.QuickPickerHwnd := ""
        this.QuickPickerItems := []
        this.QuickPickerSelectionIndex := 0
        if (this.Manager.PendingHwnd && WinExist("ahk_id " . this.Manager.PendingHwnd)) {
            WinActivate, % "ahk_id " . this.Manager.PendingHwnd
        }
    }

    IsQuickPickerActive() {
        hwnd := this.QuickPickerHwnd
        return (this.VisibleQuickPicker != "" && hwnd && WinActive("ahk_id " . hwnd))
    }

    SendQuickPickerKey(key) {
        hwnd := this.QuickPickerHwnd
        if (!hwnd || !WinExist("ahk_id " . hwnd))
            return

        ; Check which control is focused — Button2 = Cancel, everything else = Confirm
        ControlGetFocus, focusedControl, ahk_id %hwnd%
        if (focusedControl = "Button2")
            Gosub, GUICb_QuickPickerCancel
        else
            Gosub, GUICb_QuickPickerConfirm
    }

    NavigateQuickPickerHorizontal(direction) {
        hwnd := this.QuickPickerHwnd
        if (!hwnd || !WinExist("ahk_id " . hwnd))
            return

        ; a (Left) = focus Confirm, d (Right) = focus Cancel — visual selection only, Space executes
        targetControl := (direction = "Left") ? "Button1" : "Button2"
        ControlFocus, %targetControl%, ahk_id %hwnd%
    }

    NavigateQuickPickerVertical(direction) {
        hwnd := this.QuickPickerHwnd
        if (!hwnd || !WinExist("ahk_id " . hwnd))
            return

        ; Directly manipulate the selection index — no focus dependency
        currentIndex := this.GetQuickPickerSelectionIndex()
        if (currentIndex = 0)
            return

        total := this.QuickPickerItems.Length()
        if (direction = "Up") {
            newIndex := (currentIndex > 1) ? currentIndex - 1 : 1
        } else {
            newIndex := (currentIndex < total) ? currentIndex + 1 : total
        }

        if (newIndex != currentIndex)
            this.SetQuickPickerSelection(newIndex)
    }

    GetQuickPickerShowPosition(pickerW, pickerH) {
        hwnd := this.Manager.PendingHwnd
        if (hwnd && WinExist("ahk_id " . hwnd)) {
            hMon := DllCall("MonitorFromWindow", "Ptr", hwnd, "UInt", 2, "Ptr")
            if (hMon) {
                VarSetCapacity(mi, 40, 0)
                NumPut(40, mi, 0, "UInt")
                if (DllCall("GetMonitorInfo", "Ptr", hMon, "Ptr", &mi)) {
                    workLeft := NumGet(mi, 20, "Int")
                    workTop := NumGet(mi, 24, "Int")
                    workRight := NumGet(mi, 28, "Int")
                    workBottom := NumGet(mi, 32, "Int")
                    return {x: workLeft + ((workRight - workLeft - pickerW) // 2), y: workTop + ((workBottom - workTop - pickerH) // 2)}
                }
            }
        }

        CoordMode, Mouse, Screen
        MouseGetPos, mouseX, mouseY
        x := mouseX - (pickerW // 2)
        y := mouseY - (pickerH // 2)
        return {x: x, y: y}
    }

    BuildQuickPickerItems(action) {
        items := []
        if (action = "Capture")
            items.Push({name: "[Add New Zone]", isSpecial: true})

        for name, zone in this.Manager.SnapZones {
            centerX := zone.x + (zone.w / 2)
            centerY := zone.y + (zone.h / 2)
            items.Push({name: name, x: zone.x, y: zone.y, w: zone.w, h: zone.h, centerX: centerX, centerY: centerY, isSpecial: false})
        }

        this.QuickPickerItems := items
    }

    BuildQuickPickerListString() {
        list := ""
        for _, item in this.QuickPickerItems
            list .= item.name . "|"
        return list
    }

    GetInitialQuickPickerIndex() {
        items := this.QuickPickerItems
        if (items.Length() = 0)
            return 0

        if (this.QuickPickerAction = "Capture" && items[1].isSpecial)
            return (items.Length() >= 2) ? 2 : 1
        return 1
    }

    SetQuickPickerSelection(index) {
        items := this.QuickPickerItems
        if (index < 1 || index > items.Length())
            return

        this.QuickPickerSelectionIndex := index
        GuiControl, QuickPicker:Choose, QuickPickerList, %index%
    }

    GetQuickPickerSelectionIndex() {
        Gui, QuickPicker:Submit, NoHide
        global QuickPickerList

        if (this.QuickPickerItems.Length() = 0)
            return 0

        if (QuickPickerList != "") {
            for idx, item in this.QuickPickerItems {
                if (item.name = QuickPickerList) {
                    this.QuickPickerSelectionIndex := idx
                    return idx
                }
            }
        }

        if (this.QuickPickerSelectionIndex >= 1 && this.QuickPickerSelectionIndex <= this.QuickPickerItems.Length())
            return this.QuickPickerSelectionIndex

        idx := this.GetInitialQuickPickerIndex()
        this.SetQuickPickerSelection(idx)
        return idx
    }

    SelectQuickPickerDirection(direction) {
        currentIndex := this.GetQuickPickerSelectionIndex()
        if (currentIndex = 0)
            return

        currentItem := this.QuickPickerItems[currentIndex]
        refPoint := this.GetQuickPickerReferencePoint(currentItem)
        bestIndex := this.FindDirectionalQuickPickerIndex(refPoint.x, refPoint.y, direction)
        if (bestIndex)
            this.SetQuickPickerSelection(bestIndex)
    }

    GetQuickPickerReferencePoint(currentItem) {
        if (!currentItem.isSpecial)
            return {x: currentItem.centerX, y: currentItem.centerY}

        hwnd := this.Manager.PendingHwnd
        if (hwnd && WinExist("ahk_id " . hwnd)) {
            WinGetPos, x, y, w, h, ahk_id %hwnd%
            return {x: x + (w / 2), y: y + (h / 2)}
        }

        return {x: 0, y: 0}
    }

    FindDirectionalQuickPickerIndex(refX, refY, direction) {
        bestIndex := 0
        bestScore := ""

        for idx, item in this.QuickPickerItems {
            if (item.isSpecial)
                continue

            dx := item.centerX - refX
            dy := item.centerY - refY

            if (direction = "Left") {
                if (dx >= 0)
                    continue
                primary := Abs(dx), secondary := Abs(dy)
            } else if (direction = "Right") {
                if (dx <= 0)
                    continue
                primary := Abs(dx), secondary := Abs(dy)
            } else if (direction = "Up") {
                if (dy >= 0)
                    continue
                primary := Abs(dy), secondary := Abs(dx)
            } else if (direction = "Down") {
                if (dy <= 0)
                    continue
                primary := Abs(dy), secondary := Abs(dx)
            } else {
                continue
            }

            score := (primary * 10000) + secondary
            if (bestScore = "" || score < bestScore) {
                bestScore := score
                bestIndex := idx
            }
        }

        return bestIndex
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
