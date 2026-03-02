#Persistent
#NoEnv
#SingleInstance Force
SetWinDelay, -1

; Initialize GDI+
If !pToken := Gdip_Startup()
{
    MsgBox, 48, gdiplus error!, Gdiplus failed to start. Please ensure you have Gdip_All.ahk on your system
    ExitApp
}
OnExit("ExitFunc")

; System Tray Icon
IfExist, F8.ico
    Menu, Tray, Icon, F8.ico
Else
    Menu, Tray, Icon, shell32.dll, 44 

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
    Gdip_Shutdown(pToken)
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

; Toggle Ghost Mode (Alt + 3)
!3::
    hwnd := WinExist("A")
    if (AppManager.CanManage(hwnd))
        AppManager.ToggleGhost(hwnd)
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
    Alt + P: Pin/Mark (Red Dot)
    Alt + L: Lock (Blue Lock)
    Alt + 2: Capture Window Settings
    Alt + 1: Snap/Mark (Apply Settings)
    Alt + UP/DN: Transparency
    Alt + ~: Settings + Revert List
    Alt + I: Info
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

GUICb_Apply:
    Gui, SettingsGui:Submit, NoHide
    global NewX, NewY, NewWidth, NewHeight, NewTransparency
    AppManager.SnapX := NewX
    AppManager.SnapY := NewY
    AppManager.SnapW := NewWidth
    AppManager.SnapH := NewHeight
    AppManager.SnapT := NewTransparency
    AppManager.SaveSnapSettings()
    AppGUI.UpdateDashboard()
return

GUICb_Capture:
    AppGUI.Hide()
    MsgBox, 64, Capture, Switch to the window you want to capture and press Alt+2 instead!
    AppGUI.Show()
return

GUICb_Refresh:
    AppGUI.UpdateDashboard()
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

#Include Gdip_All.ahk
