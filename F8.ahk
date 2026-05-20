#Persistent
#NoEnv
#SingleInstance Force
#MaxHotkeysPerInterval 200
#WinActivateForce

;@Ahk2Exe-SetDescription F8
;@Ahk2Exe-SetName F8

SetWorkingDir %A_ScriptDir%
SetWinDelay, -1

; --- Global Data Paths ---
global AppDataDir := A_AppData . "\F8"
global SettingsPath := AppDataDir . "\settings.ini"
global LogPath := AppDataDir . "\f8.log"

if (!FileExist(AppDataDir))
    FileCreateDir, %AppDataDir%

; --- Startup Logging ---
LogMsg("--- F8 Startup ---")
LogMsg("Version: 1.0.0")
LogMsg("ScriptDir: " . A_ScriptDir)
LogMsg("WorkingDir: " . A_WorkingDir)

; Initialize GDI+
If !pToken := Gdip_Startup()
{
    LogMsg("ERROR: GDI+ failed to start.")
    MsgBox, 48, gdiplus error!, Gdiplus failed to start.
    ExitApp
}
OnExit("ExitFunc")

; System Tray Icon
iconPath := A_ScriptDir . "\F8.ico"
IfExist, %iconPath%
    Menu, Tray, Icon, %iconPath%
Else
    Menu, Tray, Icon, shell32.dll, 44

; Load icon handle for GUI windows
global hIconSmall := DllCall("LoadImage", "UInt", 0, "Str", iconPath, "UInt", 1, "Int", 16, "Int", 16, "UInt", 0x10)
global hIconBig := DllCall("LoadImage", "UInt", 0, "Str", iconPath, "UInt", 1, "Int", 32, "Int", 32, "UInt", 0x10)

; --- 1. Global Instances ---
global AppManager := new WindowManager()
global AppGUI := new F8AppGUI(AppManager)

; --- 2. Central Monitoring Loop ---
SetTimer, WatchOverlays, 30

WatchOverlays:
    AppManager.MonitorOverlays()
return

ExitFunc() {
    global pToken
    LogMsg("--- F8 Shutdown ---")
    Gdip_Shutdown(pToken)
}

LogMsg(msg) {
    global LogPath
    FormatTime, ts,, yyyy-MM-dd HH:mm:ss
    FileAppend, [%ts%] %msg%`n, %LogPath%
}

; -------------------------------------------------------------------------
; --- HOTKEYS ---
; -------------------------------------------------------------------------

; Toggle GUI visibility (Alt + `)
!`::AppGUI.Toggle()

; Increase transparency (Alt + UP)
!UP::
    hwnd := WinExist("A")
    if (AppManager.CanManage(hwnd))
        AppManager.ModifyTransparency(hwnd, 8)
return

; Decrease transparency (Alt + DOWN)
!DOWN::
    hwnd := WinExist("A")
    if (AppManager.CanManage(hwnd))
        AppManager.ModifyTransparency(hwnd, -8)
return

; Toggle window interactability / Lock (Alt + L)
!l::
    hwnd := WinExist("A")
    if (AppManager.CanManage(hwnd))
        AppManager.ToggleLock(hwnd)
return

; Toggle window Always On Top / Pin (Alt + P)
!p::
    hwnd := WinExist("A")
    if (AppManager.CanManage(hwnd))
        AppManager.TogglePin(hwnd)
return

; Capture Settings (Alt + 2)
!2::
    AppManager.CaptureSettings()
return

; Toggle snap properties (Alt + 1)
!1::
    hwnd := WinExist("A")
    if (AppManager.CanManage(hwnd))
        AppManager.ToggleSnap(hwnd)
return

; Transfer Display (Alt + 3)
!3::
    hwnd := WinExist("A")
    if (AppManager.CanManage(hwnd))
        AppManager.TransferDisplay(hwnd)
return

; Information Display (Alt + I)
!i::
    AppManager.ShowInfo()
return

; Help Display (Alt + H)
!h::
    HelpText = 
    (
    Command Shortcuts:
    Alt + H: Help
    Alt + P: Pin / Always On Top (Red Dot)
    Alt + L: Lock Window (Blue Lock)
    Alt + 1: Snap Menu (Select Zone)
    Quick Snap: W/A/S/D move, Space confirms
    Alt + 2: Capture Menu (Save Current)
    Alt + 3: Transfer to Next Display
    Alt + UP/DN: Adjust Transparency
    Alt + ~: Settings Dashboard
    Alt + I: Window Information
    Ctrl + Alt + Arrows: Rotate Display
    )
    ToolTip, %HelpText%
    SetTimer, CloseToolTip, 6000
return

CloseToolTip:
    ToolTip
return

#IfWinExist ahk_class tooltips_class32
    ~LButton::ToolTip
#IfWinExist

#If (IsObject(AppGUI) && AppGUI.VisibleQuickPicker != "")
a::
    AppGUI.SendQuickPickerKey("{Left}")
return

d::
    AppGUI.SendQuickPickerKey("{Right}")
return

w::
    AppGUI.SendQuickPickerKey("{Up}")
return

s::
    AppGUI.SendQuickPickerKey("{Down}")
return

Space::
    AppGUI.SendQuickPickerKey("{Enter}")
return
#If

; Screen Orientation
^!Down::AppManager.ChangeScreenOrientation(0)
^!Right::AppManager.ChangeScreenOrientation(90)
^!Up::AppManager.ChangeScreenOrientation(180)
^!Left::AppManager.ChangeScreenOrientation(270)


#Include classes\WindowManager.ahk
#Include classes\MarkerOverlay.ahk
#Include classes\F8AppGUI.ahk
; -------------------------------------------------------------------------
; --- GUI CALLBACK TRUNKS ---
; -------------------------------------------------------------------------

SettingsGuiClose:
SettingsGuiEscape:
    AppGUI.Hide()
return

GUICb_SaveZone:
    Gui, SettingsGui:Submit, NoHide
    global NewX, NewY, NewWidth, NewHeight, NewTransparency, SelectedZoneName
    SelectedZoneName := Trim(SelectedZoneName)
    if (SelectedZoneName = "") {
        ToolTip, Please enter a Name for this Zone first!
        SetTimer, CloseToolTip, -2000
        return
    }
    AppManager.SnapZones[SelectedZoneName] := {x: NewX, y: NewY, w: NewWidth, h: NewHeight, t: NewTransparency}
    AppManager.SaveSnapSettings()
    AppGUI.UpdateZonesList(SelectedZoneName)
    ToolTip, Zone '%SelectedZoneName%' Saved!
    SetTimer, CloseToolTip, -2000
return

GUICb_DeleteZone:
    Gui, SettingsGui:Submit, NoHide
    global SelectedZoneName
    if (SelectedZoneName = "")
        return
    AppGUI.ShowConfirmDelete(SelectedZoneName)
return

GUICb_SelectZone:
    Gui, SettingsGui:Submit, NoHide
    global ZoneList
    if (AppManager.SnapZones.HasKey(ZoneList)) {
        zone := AppManager.SnapZones[ZoneList]
        GuiControl, SettingsGui:, SelectedZoneName, %ZoneList%
        GuiControl, SettingsGui:, NewX, % zone.x
        GuiControl, SettingsGui:, NewY, % zone.y
        GuiControl, SettingsGui:, NewWidth, % zone.w
        GuiControl, SettingsGui:, NewHeight, % zone.h
        GuiControl, SettingsGui:, NewTransparency, % zone.t
    }
return

GUICb_Capture:
    AppGUI.Hide()
    AppManager.CaptureSettings()
    AppGUI.Show()
return
 
GUICb_Revert:
    if RegExMatch(A_GuiControl, "^RevertBtn_(\d+)$", m) {
        idx := m1 + 0
        if (AppGUI.HwndIndexMap.HasKey(idx)) {
            AppManager.RevertWindow(AppGUI.HwndIndexMap[idx])
            AppGUI.UpdateDashboard()
        }
    }
return

GUICb_Transfer:
    if RegExMatch(A_GuiControl, "^TransferBtn_(\d+)$", m) {
        idx := m1 + 0
        if (AppGUI.HwndIndexMap.HasKey(idx)) {
            AppManager.TransferDisplay(AppGUI.HwndIndexMap[idx])
            AppGUI.UpdateDashboard()
        }
    }
return

GUICb_Ignore:
    if RegExMatch(A_GuiControl, "^IgnoreBtn_(\d+)$", m) {
        idx := m1 + 0
        if (AppGUI.HwndIndexMap.HasKey(idx)) {
            AppManager.ToggleIgnoreStatus(AppGUI.HwndIndexMap[idx])
            AppGUI.UpdateDashboard()
        }
    }
return

; --- Quick Picker Callbacks ---
GUICb_QuickPickerSelect:
    if (A_GuiEvent = "DoubleClick")
        Gosub, GUICb_QuickPickerConfirm
return

GUICb_QuickPickerConfirm:
    Gui, QuickPicker:Submit
    global QuickPickerList
    choice := QuickPickerList
    action := AppGUI.QuickPickerAction
    
    if (action = "Snap") {
        if (!AppManager.SnapZones.HasKey(choice)) {
            ToolTip, Zone not found!
            SetTimer, CloseToolTip, -2000
            return
        }
        zone := AppManager.SnapZones[choice]
        hwnd := AppManager.PendingHwnd
        state := AppManager.GetState(hwnd)
        
        WinGetPos, ox, oy, ow, oh, ahk_id %hwnd%
        state.OX := ox, state.OY := oy, state.OW := ow, state.OH := oh
        state.isSnapped := true
        state.currentZone := choice
        
        AppManager.EnsureWindowedForMove(hwnd)
        AppManager.MoveWindowReliable(hwnd, zone.x, zone.y, zone.w, zone.h)
        WinSet, Transparent, % zone.t, ahk_id %hwnd%
        Winset, Alwaysontop, On, ahk_id %hwnd%
        Winset, exStyle, +0x20, ahk_id %hwnd%
        AppManager.UpdateOverlay(hwnd)
        
    } else if (action = "Capture") {
        finalName := choice
        if (choice = "[Add New Zone]") {
            Gui, QuickPicker:+OwnDialogs
            InputBox, newName, New Zone, Enter a name for your new snap zone:,, 250, 130
            if (ErrorLevel || newName = "") {
                Gui, QuickPicker:Destroy
                return
            }
            finalName := newName
        }
        
        cap := AppManager.PendingCapture
        AppManager.SnapZones[finalName] := {x: cap.x, y: cap.y, w: cap.w, h: cap.h, t: cap.t}
        AppManager.SaveSnapSettings()
        AppGUI.UpdateZonesList()
        ToolTip, Zone '%finalName%' Saved!
        SetTimer, CloseToolTip, -2000
    }
    
    AppGUI.HideQuickPicker()
return

GUICb_QuickPickerCancel:
QuickPickerGuiClose:
QuickPickerGuiEscape:
    AppGUI.HideQuickPicker()
return

GUICb_ConfirmDeleteYes:
    zone := AppGUI.PendingDeleteZone
    AppManager.DeleteZone(zone)
    AppGUI.UpdateZonesList()
    GuiControl, SettingsGui:, SelectedZoneName, 
    AppGUI.HideConfirmDelete()
return

GUICb_ConfirmDeleteNo:
ConfirmGuiClose:
ConfirmGuiEscape:
    AppGUI.HideConfirmDelete()
return

#Include Gdip_All.ahk
