@echo off
SETLOCAL EnableDelayedExpansion

:: Cleanup
echo Cleaning up previous builds...
if exist "..\artifacts\F8_bundled.ahk" del "..\artifacts\F8_bundled.ahk"
if exist "..\artifacts\F8.exe" del "..\artifacts\F8.exe"
if exist "..\artifacts\F8_Setup.msi" del "..\artifacts\F8_Setup.msi"

:: Bundling
echo Bundling F8.ahk...
powershell -ExecutionPolicy Bypass -File "%~dp0bundle.ps1"

:: Compilation
echo Compiling...
"C:\Program Files\AutoHotkey\Compiler\Ahk2Exe.exe" /in "%~dp0..\artifacts\F8_bundled.ahk" /out "%~dp0..\artifacts\F8.exe" /icon "%~dp0..\..\F8.ico" /bin "C:\Program Files\AutoHotkey\v1.1.37.02\AutoHotkeyU64.exe" /silent

if not exist "%~dp0..\artifacts\F8.exe" (
    echo ERROR: Failed to compile F8.exe
    exit /b 1
)

:: WiX Build
echo Building MSI...
"C:\Program Files\WiX Toolset v6.0\bin\wix.exe" build "setup.wxs" -o "..\artifacts\F8_Setup.msi"

if exist "..\artifacts\F8_Setup.msi" (
    echo Success! MSI generated: build\artifacts\F8_Setup.msi
) else (
    echo ERROR: Failed to build MSI
    exit /b 1
)

:: Cleanup
if exist setup.wixobj del setup.wixobj
if exist setup.wixpdb del setup.wixpdb
