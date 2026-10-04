@echo off
:: =============================================================================
:: Execution Context : Windows Batch (Auto-Elevation to Administrator)
:: Application       : GIN-VPN by VladiMIR+AI — High-Speed Native Xray Client
:: Version           : v24
:: =============================================================================
chcp 65001 >nul
cls

:: Auto-Elevation check
fltmc >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -Command "Start-Process cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"
title GIN-VPN by VladiMIR+AI [v24]

:: Launch PowerShell Windows Forms GUI with clean unblocked bypass
start "" powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0GIN-VPN.ps1"
exit /b
