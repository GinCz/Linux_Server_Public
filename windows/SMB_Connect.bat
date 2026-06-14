@echo off
cls
chcp 65001 >nul
setlocal enabledelayedexpansion

:: ==========================================================================================
:: FILE    : SMB_Connect.bat
:: VERSION : v2026.06.14h
:: AUTHOR  : = Rooted by VladiMIR + AI | github.com/GinCz =
:: DESC    : Подключение 10 SMB-хранилищ параллельно.
::           Пароль запрашивается при запуске (не хранится в скрипте).
::           Результат — по папке (ok/fail/skip).
::           reg add выполняется в основном процессе (кавычки без экранирования).
::           IONOS_38 — без ping (ICMP заблокирован фаерволом, SMB работает).
:: USAGE   : Запускать от имени Администратора
:: ==========================================================================================

set "ESC="
for /F %%A in ('echo prompt $E ^| cmd') do set "ESC=%%A"
set "CY=%ESC%[96m"
set "YE=%ESC%[93m"
set "GR=%ESC%[92m"
set "RE=%ESC%[91m"
set "WH=%ESC%[97m"
set "RS=%ESC%[0m"

echo %CY%==========================================================================================%RS%
echo %YE%           ПОДКЛЮЧЕНИЕ СЕТЕВЫХ ХРАНИЛИЩ  v2026.06.14h%RS%
echo %CY%==========================================================================================%RS%
echo.

:: ── Запрос пароля (символы не отображаются) ───────────────────────────────
set "SMB_PASS="
set /p "SMB_PASS=%YE%  Введите пароль SMB: %RS%"
echo.

if "%SMB_PASS%"=="" (
    echo %RE%  [ERROR] Пароль не введён. Выход.%RS%
    echo.
    pause
    exit /b 1
)

:: ── Подготовка временных папок ────────────────────────────────────────────
set "TD=C:\smbtmp"
rmdir /s /q "%TD%" >nul 2>&1
mkdir "%TD%\ok"   >nul 2>&1
mkdir "%TD%\fail" >nul 2>&1
mkdir "%TD%\skip" >nul 2>&1

echo %YE%[ STATUS ]%RS% Сохранение учётных данных...

cmdkey /add:3.79.14.42       /user:vlad /pass:"%SMB_PASS%" >nul 2>&1
cmdkey /add:82.223.116.38    /user:vlad /pass:"%SMB_PASS%" >nul 2>&1
cmdkey /add:109.234.38.47    /user:vlad /pass:"%SMB_PASS%" >nul 2>&1
cmdkey /add:144.124.228.237  /user:vlad /pass:"%SMB_PASS%" >nul 2>&1
cmdkey /add:144.124.232.9    /user:vlad /pass:"%SMB_PASS%" >nul 2>&1
cmdkey /add:144.124.228.227  /user:vlad /pass:"%SMB_PASS%" >nul 2>&1
cmdkey /add:144.124.239.24   /user:vlad /pass:"%SMB_PASS%" >nul 2>&1
cmdkey /add:91.84.118.178    /user:vlad /pass:"%SMB_PASS%" >nul 2>&1
cmdkey /add:146.103.110.176  /user:vlad /pass:"%SMB_PASS%" >nul 2>&1
cmdkey /add:144.124.233.38   /user:vlad /pass:"%SMB_PASS%" >nul 2>&1

echo %YE%[ STATUS ]%RS% Учётные данные сохранены. Запуск подключения...
echo %CY%------------------------------------------------------------------------------------------%RS%

:: IONOS_38 (82.223.116.38) — без ping, ICMP заблокирован IPGuard, SMB работает напрямую
start /b cmd /c "net use L: /delete /yes >nul 2>&1 & net use L: \\82.223.116.38\soft /persistent:yes >nul 2>&1 && type nul>C:\smbtmp\ok\L.txt || type nul>C:\smbtmp\fail\L.txt"

:: Остальные 9 серверов — с ping-проверкой перед подключением
start /b cmd /c "ping -n 1 -w 1500 3.79.14.42 >nul 2>&1 && (net use K: /delete /yes >nul 2>&1 & net use K: \\3.79.14.42\soft /persistent:yes >nul 2>&1 && type nul>C:\smbtmp\ok\K.txt || type nul>C:\smbtmp\fail\K.txt) || type nul>C:\smbtmp\skip\K.txt"

start /b cmd /c "ping -n 1 -w 1500 146.103.110.176 >nul 2>&1 && (net use I: /delete /yes >nul 2>&1 & net use I: \\146.103.110.176\soft /persistent:yes >nul 2>&1 && type nul>C:\smbtmp\ok\I.txt || type nul>C:\smbtmp\fail\I.txt) || type nul>C:\smbtmp\skip\I.txt"

start /b cmd /c "ping -n 1 -w 1500 91.84.118.178 >nul 2>&1 && (net use N: /delete /yes >nul 2>&1 & net use N: \\91.84.118.178\soft /persistent:yes >nul 2>&1 && type nul>C:\smbtmp\ok\N.txt || type nul>C:\smbtmp\fail\N.txt) || type nul>C:\smbtmp\skip\N.txt"

start /b cmd /c "ping -n 1 -w 1500 144.124.228.237 >nul 2>&1 && (net use O: /delete /yes >nul 2>&1 & net use O: \\144.124.228.237\soft /persistent:yes >nul 2>&1 && type nul>C:\smbtmp\ok\O.txt || type nul>C:\smbtmp\fail\O.txt) || type nul>C:\smbtmp\skip\O.txt"

start /b cmd /c "ping -n 1 -w 1500 144.124.233.38 >nul 2>&1 && (net use Q: /delete /yes >nul 2>&1 & net use Q: \\144.124.233.38\soft /persistent:yes >nul 2>&1 && type nul>C:\smbtmp\ok\Q.txt || type nul>C:\smbtmp\fail\Q.txt) || type nul>C:\smbtmp\skip\Q.txt"

start /b cmd /c "ping -n 1 -w 1500 144.124.232.9 >nul 2>&1 && (net use T: /delete /yes >nul 2>&1 & net use T: \\144.124.232.9\soft /persistent:yes >nul 2>&1 && type nul>C:\smbtmp\ok\T.txt || type nul>C:\smbtmp\fail\T.txt) || type nul>C:\smbtmp\skip\T.txt"

start /b cmd /c "ping -n 1 -w 1500 144.124.228.227 >nul 2>&1 && (net use V: /delete /yes >nul 2>&1 & net use V: \\144.124.228.227\soft /persistent:yes >nul 2>&1 && type nul>C:\smbtmp\ok\V.txt || type nul>C:\smbtmp\fail\V.txt) || type nul>C:\smbtmp\skip\V.txt"

start /b cmd /c "ping -n 1 -w 1500 144.124.239.24 >nul 2>&1 && (net use W: /delete /yes >nul 2>&1 & net use W: \\144.124.239.24\soft /persistent:yes >nul 2>&1 && type nul>C:\smbtmp\ok\W.txt || type nul>C:\smbtmp\fail\W.txt) || type nul>C:\smbtmp\skip\W.txt"

start /b cmd /c "ping -n 1 -w 1500 109.234.38.47 >nul 2>&1 && (net use Y: /delete /yes >nul 2>&1 & net use Y: \\109.234.38.47\soft /persistent:yes >nul 2>&1 && type nul>C:\smbtmp\ok\Y.txt || type nul>C:\smbtmp\fail\Y.txt) || type nul>C:\smbtmp\skip\Y.txt"

timeout /t 8 /nobreak >nul

:: reg add в основном процессе — кавычки работают без экранирования
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##3.79.14.42#soft"       /v _LabelFromReg /t REG_SZ /d "AWS_42"     /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##82.223.116.38#soft"    /v _LabelFromReg /t REG_SZ /d "IONOS_38"   /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##146.103.110.176#soft"  /v _LabelFromReg /t REG_SZ /d "ILYA_176"   /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##91.84.118.178#soft"    /v _LabelFromReg /t REG_SZ /d "PILIK_178"  /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.228.237#soft"  /v _LabelFromReg /t REG_SZ /d "4TON_237"   /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.233.38#soft"   /v _LabelFromReg /t REG_SZ /d "SO_38"      /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.232.9#soft"    /v _LabelFromReg /t REG_SZ /d "TATRA_9"    /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.228.227#soft"  /v _LabelFromReg /t REG_SZ /d "SHAHIN_227" /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##144.124.239.24#soft"   /v _LabelFromReg /t REG_SZ /d "STOLB_24"   /f >nul 2>&1
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\MountPoints2\##109.234.38.47#soft"    /v _LabelFromReg /t REG_SZ /d "ALEX_47"    /f >nul 2>&1

:: Очищаем пароль из памяти
set "SMB_PASS="

echo.
echo %CY%==========================================================================================%RS%
echo %YE%                      РЕЗУЛЬТАТ ПОДКЛЮЧЕНИЯ%RS%
echo %CY%==========================================================================================%RS%
echo.
echo %WH%  Диск   Сервер          IP%RS%
echo %CY%  ----------------------------------------------------------------%RS%

call :ST K  AWS_42       3.79.14.42
call :ST L  IONOS_38     82.223.116.38
call :ST I  ILYA_176     146.103.110.176
call :ST N  PILIK_178    91.84.118.178
call :ST O  4TON_237     144.124.228.237
call :ST Q  SO_38        144.124.233.38
call :ST T  TATRA_9      144.124.232.9
call :ST V  SHAHIN_227   144.124.228.227
call :ST W  STOLB_24     144.124.239.24
call :ST Y  ALEX_47      109.234.38.47

echo.
echo %CY%==========================================================================================%RS%
echo %YE%  = Rooted by VladiMIR + AI ^| v2026.06.14h ^| github.com/GinCz =%RS%
echo %CY%==========================================================================================%RS%
echo.

rmdir /s /q "C:\smbtmp" >nul 2>&1
pause
exit /b

:: ── :ST DRIVE LABEL IP ────────────────────────────────────────────────────
:ST
set "DRV=%~1"
set "LBL=%~2"
set "SIP=%~3"
if exist "C:\smbtmp\ok\%DRV%.txt"        ( echo   %GR%[  OK  ]%RS%  %DRV%:  %LBL%   %SIP%
) else if exist "C:\smbtmp\skip\%DRV%.txt" ( echo   %YE%[ SKIP ]%RS%  %DRV%:  %LBL%   %SIP%   (сервер недоступен)
) else if exist "C:\smbtmp\fail\%DRV%.txt" ( echo   %RE%[ FAIL ]%RS%  %DRV%:  %LBL%   %SIP%   (ping OK, SMB отказал)
) else (                                     echo   %RE%[TIMEOUT]%RS% %DRV%:  %LBL%   %SIP%   (не успел за 8 сек)
)
exit /b
