:: Execution Context : CMD / Batch (Windows 10 / 11)
:: Target Server     : Local Windows Desktop PC
:: Description       : 1-Click Launcher for GIN-Voice [v001] PowerShell Installer

@echo off
cls
title GIN-Voice [v001] Installer Launcher
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0GIN-Voice_Setup_v001.ps1"
if errorlevel 1 (
    echo.
    echo [ERROR] Installation failed or was cancelled.
    pause
)
exit /b 0
