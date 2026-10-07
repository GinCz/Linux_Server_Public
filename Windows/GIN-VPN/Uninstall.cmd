@echo off
:: =============================================================================
:: Execution Context : Windows Batch (Uninstaller Launcher)
:: Application       : GIN-VPN Uninstaller
:: =============================================================================
chcp 65001 >nul
cls

:: Auto-Elevate check
fltmc >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Uninstall.ps1"
exit /b
