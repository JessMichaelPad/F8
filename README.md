# F8

A lightweight Windows window management utility built with AutoHotkey. F8 lets you pin, lock, snap, transfer, and adjust transparency of any window using keyboard shortcuts — ideal for keeping video calls, references, or media visible while you work.

## Features

- **Pin (Always On Top)** — Keep any window above all others
- **Lock (Click-Through)** — Make a window non-interactable so clicks pass through to whatever is behind it
- **Snap Zones** — Save and recall window positions, sizes, and transparency presets
- **Borderless Windowed** — Strip window borders and fill the monitor (useful for games and media)
- **Transfer Display** — Move the active window to the next monitor
- **Transparency** — Adjust any window's opacity on the fly
- **Screen Rotation** — Rotate any display orientation via hotkey
- **Per-App Hotkey Control** — Disable specific hotkeys for individual applications
- **Visual Overlays** — Small GDI+ indicators show which windows are pinned or locked

## Keyboard Shortcuts

| Shortcut | Action |
|---|---|
| `Alt + P` | Toggle Pin (Always On Top) |
| `Alt + L` | Toggle Lock (Click-Through) |
| `Alt + B` | Toggle Borderless Windowed Mode |
| `Alt + 1` | Snap Menu — select a saved zone |
| `Alt + 2` | Capture Menu — save current window position as a zone |
| `Alt + 3` | Transfer window to next display |
| `Alt + ↑/↓` | Increase / Decrease transparency |
| `Alt + ~` | Toggle Settings Dashboard |
| `Alt + I` | Show window information tooltip |
| `Alt + H` | Show help tooltip |
| `Ctrl + Alt + Arrows` | Rotate screen orientation |

### Quick Picker Navigation (during Snap/Capture menus)

| Key | Action |
|---|---|
| `W / S` | Move selection up / down |
| `A / D` | Switch between Confirm / Cancel |
| `Space` | Confirm selection |

## Settings Dashboard

Open with `Alt + ~` or double-click the system tray icon. The dashboard has two panels:

### Snap Settings (Left)
- Create, edit, and delete named snap zones
- Each zone stores: X, Y, Width, Height, and Transparency (alpha 0–255)
- **Capture** grabs the active window's current position and size
- Zones are persisted to `settings.ini`

### Apps Dashboard (Right)
- Lists up to 8 active windows with their current state (`[Pin]`, `[Lock]`, `[Snap]`)
- **Revert** — undo the last F8 action on a window
- **Transfer** — move a window to the next monitor
- **Alt 1/2**, **Alt 3**, **Alt+\`** — toggle specific hotkeys on/off per application
- Auto-refreshes every 1.5 seconds

## System Tray

- **Open Menu** (default double-click) — opens the Settings Dashboard
- **Pause** — pauses all F8 hotkeys
- **Exit** — shuts down F8

## Project Structure

```
F8/
├── F8.ahk                  # Main entry point, hotkeys, GUI callbacks
├── F8.ico                  # Application icon
├── Gdip_All.ahk            # GDI+ library (overlay rendering)
├── settings.ini            # User settings and saved snap zones
├── classes/
│   ├── WindowManager.ahk   # Core logic: window actions, state tracking, monitoring
│   ├── F8AppGUI.ahk        # Settings dashboard and quick picker UI
│   └── MarkerOverlay.ahk   # GDI+ pin/lock indicator overlays
└── build/
    ├── build_setup/
    │   ├── build.bat        # Full build pipeline (bundle → compile → MSI)
    │   ├── bundle.ps1       # Bundles #Include files into a single .ahk
    │   └── setup.wxs        # WiX installer definition
    └── artifacts/           # Build outputs (F8.exe, F8_Setup.msi)
```

## Requirements

- **Runtime:** [AutoHotkey v1.1](https://www.autohotkey.com/) (Unicode 64-bit)
- **Build (optional):**
  - AutoHotkey Compiler (`Ahk2Exe.exe`)
  - [WiX Toolset v6.0](https://wixtoolset.org/) (for MSI installer)

## Running from Source

No compilation needed — just run the script directly:

```
"C:\Program Files\AutoHotkey\AutoHotkey.exe" F8.ahk
```

## Building

From the `build/build_setup/` directory:

```
build.bat
```

This will:
1. Clean previous build artifacts
2. Bundle all `#Include` files into a single script
3. Compile to `F8.exe`
4. Package into `F8_Setup.msi`

Outputs are placed in `build/artifacts/`.

## Configuration

Settings are stored in `%APPDATA%\F8\settings.ini` at runtime. The repo's `settings.ini` is a development reference. Logs are written to `%APPDATA%\F8\f8.log`.

## License

Private project.
