@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo === Android HCI log export ===
echo.
echo Starting export script...
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0export-hci.ps1"
