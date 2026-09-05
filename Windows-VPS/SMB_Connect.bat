@echo off
rem ============================================================
rem  SMB_Connect.bat  |  v2026.06.15b  |  github.com/GinCz
rem  Connect all Samba/SMB shares as Windows drives in parallel
rem  Part of: WinSambaBackup / Linux_Server_Public toolkit
rem  Author: VladiMIR Bulantsev (GinCz) + AI
rem
rem  Keywords: SMB connect bat, Samba Windows drives, net use bat,
rem    parallel SMB connect, Windows drive mapping, SMB_Connect,
rem    Samba bat script, Windows VPS tools, GinCz
rem
rem  Usage: Run as Administrator
rem ============================================================
setlocal enabledelayedexpansion

set "SHARE=storage"
set "TMPDIR=C:\smbtmp"
mkdir "%TMPDIR%\ok" "%TMPDIR%\fail" "%TMPDIR%\skip" 2>nul

set /p "SMB_USER=SMB Username: "
set /p "SMB_PASS=SMB Password: "

cls
echo ============================================================
echo   SMB_Connect  ^|  Samba Drive Mapper  ^|  github.com/GinCz
echo ============================================================
echo.

rem -- Launch all connections in parallel --
for %%S in (
    "K:,AWS_12,18.195.117.12,skip"
    "L:,IONOS_38,82.223.116.38,noping"
    "I:,ILYA_176,146.103.110.176,skip"
    "N:,PILIK_33,195.63.138.33,skip"
    "O:,4TON_237,144.124.228.237,skip"
    "Q:,SO_38,144.124.233.38,skip"
    "T:,TATRA_9,144.124.232.9,skip"
    "V:,SHAHIN_227,144.124.228.227,skip"
    "W:,STOLB_24,144.124.239.24,skip"
    "Y:,ALEX_51,212.34.148.51,skip"
) do (
    for /f "tokens=1-4 delims=," %%A in (%%S) do (
        start /b cmd /c (
            if "%%D"=="noping" (
                net use %%A "\\%%C\%SHARE%" "%SMB_PASS%" /user:%%B /persistent:no >nul 2>&1
                if !errorlevel! equ 0 ( echo %%A > "%TMPDIR%\ok\%%B" ) else ( echo %%A > "%TMPDIR%\fail\%%B" )
            ) else (
                ping -n 1 -w 2000 %%C >nul 2>&1
                if !errorlevel! equ 0 (
                    net use %%A "\\%%C\%SHARE%" "%SMB_PASS%" /user:%%B /persistent:no >nul 2>&1
                    if !errorlevel! equ 0 ( echo %%A > "%TMPDIR%\ok\%%B" ) else ( echo %%A > "%TMPDIR%\fail\%%B" )
                ) else (
                    echo %%A > "%TMPDIR%\skip\%%B"
                )
            )
        )
    )
)

timeout /t 8 /nobreak >nul

for %%S in (
    "K:,AWS_12,18.195.117.12"
    "L:,IONOS_38,82.223.116.38"
    "I:,ILYA_176,146.103.110.176"
    "N:,PILIK_33,195.63.138.33"
    "O:,4TON_237,144.124.228.237"
    "Q:,SO_38,144.124.233.38"
    "T:,TATRA_9,144.124.232.9"
    "V:,SHAHIN_227,144.124.228.227"
    "W:,STOLB_24,144.124.239.24"
    "Y:,ALEX_51,212.34.148.51"
) do (
    for /f "tokens=1-3 delims=," %%A in (%%S) do (
        if exist "%TMPDIR%\ok\%%B"   ( echo [  OK  ]  %%A  %%B  %%C )
        if exist "%TMPDIR%\skip\%%B" ( echo [ SKIP ]  %%A  %%B  %%C )
        if exist "%TMPDIR%\fail\%%B" ( echo [ FAIL ]  %%A  %%B  %%C )
        if not exist "%TMPDIR%\ok\%%B" if not exist "%TMPDIR%\skip\%%B" if not exist "%TMPDIR%\fail\%%B" (
            echo [TIMEOUT]  %%A  %%B  %%C
        )
        reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##%%C#%SHARE%" /v _LabelFromDesktopINI /d "%%B" /f >nul 2>&1
    )
)

rmdir /s /q "%TMPDIR%" 2>nul
set "SMB_PASS="
echo.
echo ============================================================
echo   Done. Press any key to close.
echo ============================================================
pause >nul
