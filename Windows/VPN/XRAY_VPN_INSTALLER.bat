@echo off
chcp 65001 >nul
cls
echo ====================================================================
echo        XRAY_VPN AUTOMATED INSTALLER FOR WINDOWS 7 / 10 / 11
echo        GitHub: https://github.com/GinCz/Windows_scripts
echo        Folder: Windows/VPN
echo ====================================================================
echo.

:: ── Проверка прав администратора ──────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath cmd.exe -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs -Wait"
    exit /b
)
echo [+] Running with Administrator privileges!
echo.

:: ── Сброс прокси (важно для Windows 7) ───────────────────────────────
netsh winhttp reset proxy >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Internet Settings" /v ProxyEnable /t REG_DWORD /d 0 /f >nul 2>&1
echo [+] Proxy settings cleared.

:: ── Основная установка VPN ────────────────────────────────────────────
echo [*] Downloading and running VPN installer...
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object Net.WebClient).DownloadString('http://prodvig-saita.ru/vpn/install.ps1'))"

:: ── Скачиваем tray_tooltip_helper.ps1 с GitHub ───────────────────────
:: ВАЖНО: файл должен лежать в публичном репо GinCz/Windows_scripts
:: по пути: Windows/VPN/tray_tooltip_helper.ps1
echo.
echo [*] Downloading tray tooltip helper from GitHub...
set "TRAY_DIR=%ProgramFiles%\XrayVPN"
set "TRAY_PS1=%TRAY_DIR%\tray_tooltip_helper.ps1"
set "GITHUB_RAW=https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/VPN/tray_tooltip_helper.ps1"

if not exist "%TRAY_DIR%" mkdir "%TRAY_DIR%"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "(New-Object Net.WebClient).DownloadFile('%GITHUB_RAW%', '%TRAY_PS1%')"

if exist "%TRAY_PS1%" (
    echo [+] Tray helper downloaded: %TRAY_PS1%
) else (
    echo [!] GitHub download failed - writing fallback tray helper locally...
    :: Если GitHub недоступен — записываем базовую версию локально
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "$code = @'" & echo. & echo "'@; Set-Content '%TRAY_PS1%' $code"
    goto :write_fallback
)
goto :create_shortcut

:write_fallback
:: Fallback: записываем минимальный скрипт через PowerShell heredoc
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0write_tray.ps1" 2>nul
if not exist "%TRAY_PS1%" (
    echo [ERROR] Could not create tray helper. Install VPN manually.
)

:create_shortcut
:: ── Ярлык автозапуска при старте Windows (Common Startup) ─────────────
echo [*] Creating autostart shortcut...
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$s = New-Object -ComObject WScript.Shell; $lnk = $s.CreateShortcut([Environment]::GetFolderPath('CommonStartup') + '\XrayVPN_Tray.lnk'); $lnk.TargetPath = 'powershell.exe'; $lnk.Arguments = '-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \""%TRAY_PS1%\"\"'; $lnk.WorkingDirectory = '%TRAY_DIR%'; $lnk.Description = 'Xray VPN System Tray - github.com/GinCz/Windows_scripts'; $lnk.Save()"

echo [+] Autostart shortcut created (Common Startup).

:: ── Запускаем трей прямо сейчас (без перезагрузки) ───────────────────
echo [*] Starting tray icon now (no reboot needed)...
start "" powershell -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%TRAY_PS1%"

echo.
echo ====================================================================
echo  Installation complete!
echo.
echo  Tray icon:
echo    GREEN  = VPN connected (IP changed)
echo    ORANGE = Process running but IP not yet changed
echo    GREY   = VPN stopped
echo    RED    = Connection ERROR (balloon notification shown)
echo.
echo  Hover mouse over tray icon to see:
echo    - VPN IP (current IP through tunnel)
echo    - Original IP (your real IP before VPN)
echo    - Username
echo.
echo  Next step: paste your VLESS key into Notepad, save, run Start_VPN
echo.
echo  GitHub: https://github.com/GinCz/Windows_scripts/tree/main/Windows/VPN
echo ====================================================================
pause
