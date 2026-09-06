# Xray VPN Tray Tooltip Helper
# Repo: https://github.com/GinCz/Windows_scripts/tree/main/Windows/VPN
# Compatible: Windows 7 / 10 / 11 (PowerShell 2.0+)
# Author: GinCz (gin@volny.cz)

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ── Цвета иконки ──────────────────────────────────────────────────────
$COLOR_CONNECTED  = [System.Drawing.Color]::FromArgb(0, 200, 0)     # Зеленый
$COLOR_CONNECTING = [System.Drawing.Color]::FromArgb(255, 165, 0)   # Оранжевый
$COLOR_ERROR      = [System.Drawing.Color]::FromArgb(220, 0, 0)     # Красный
$COLOR_IDLE       = [System.Drawing.Color]::FromArgb(120, 120, 120) # Серый

# ── Создание иконки 16x16 нужного цвета ───────────────────────────────
function New-ColorIcon {
    param([System.Drawing.Color]$color)
    $bmp = New-Object System.Drawing.Bitmap 16, 16
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $brush = New-Object System.Drawing.SolidBrush $color
    # Рисуем круг (щит VPN)
    $g.FillEllipse($brush, 2, 2, 12, 12)
    # Белая буква V внутри
    $pen = New-Object System.Drawing.Pen([System.Drawing.Color]::White, 1.5)
    $g.DrawLine($pen, 4, 5, 8, 11)
    $g.DrawLine($pen, 12, 5, 8, 11)
    $g.Dispose()
    return [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
}

# ── Запоминаем Original IP при старте (до поднятия туннеля) ───────────
$script:originalIp = "Unknown"
try {
    $wc = New-Object Net.WebClient
    $wc.Headers.Add("User-Agent", "Mozilla/5.0")
    $script:originalIp = $wc.DownloadString('https://api.ipify.org').Trim()
} catch {
    try {
        $script:originalIp = (Invoke-WebRequest 'https://ifconfig.me/ip' -UseBasicParsing).Content.Trim()
    } catch {}
}

# ── Имя пользователя ──────────────────────────────────────────────────
$script:userName = $env:USERNAME

# ── Получение текущего IP (VPN или реального) ─────────────────────────
function Get-CurrentIp {
    try {
        $wc = New-Object Net.WebClient
        $wc.Headers.Add("User-Agent", "Mozilla/5.0")
        return $wc.DownloadString('https://api.ipify.org').Trim()
    } catch {
        return "Unavailable"
    }
}

# ── Проверка: запущен ли процесс Xray/V2Ray ───────────────────────────
function Test-VpnRunning {
    $proc = Get-Process -Name "xray","v2ray","wintun","xray-core" -ErrorAction SilentlyContinue
    return ($null -ne $proc)
}

# ── Формирование текста тултипа ───────────────────────────────────────
# Windows ограничивает NotifyIcon.Text до 63 символов!
# Используем BalloonTip для полной информации при клике
$script:lastFullTooltip = ""

function Get-TooltipText {
    $vpnRunning = Test-VpnRunning
    if ($vpnRunning) {
        $vpnIp = Get-CurrentIp
        $script:lastFullTooltip = "Xray VPN: Connected`nVPN IP:      $vpnIp`nOriginal IP: $($script:originalIp)`nUser:        $($script:userName)"
    } else {
        $vpnIp = "—"
        $script:lastFullTooltip = "Xray VPN: Disconnected`nOriginal IP: $($script:originalIp)`nUser:        $($script:userName)"
    }
    # Обрезаем до 63 символов для свойства Text
    $short = $script:lastFullTooltip -replace "`n"," | "
    if ($short.Length -gt 63) { return $short.Substring(0, 60) + "..." }
    return $short
}

# ── Создаём трей-иконку ────────────────────────────────────────────────
$notifyIcon = New-Object System.Windows.Forms.NotifyIcon
$notifyIcon.Visible = $true
$notifyIcon.Icon = New-ColorIcon $COLOR_IDLE
$notifyIcon.Text = "Xray VPN: Initializing..."

# ── Показываем полный тултип через BalloonTip при наведении ───────────
# (MouseMove на NotifyIcon не поддерживается, используем MouseClick)
$notifyIcon.add_MouseMove({
    # Обновляем Text при каждом движении мыши над иконкой
    $notifyIcon.Text = Get-TooltipText
})

# ── Двойной клик = показать полный balloon с IP-инфо ──────────────────
$notifyIcon.add_DoubleClick({
    $notifyIcon.BalloonTipTitle = "Xray VPN Status"
    $notifyIcon.BalloonTipText  = $script:lastFullTooltip
    $notifyIcon.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Info
    $notifyIcon.ShowBalloonTip(4000)
})

# ── Контекстное меню ──────────────────────────────────────────────────
$menu = New-Object System.Windows.Forms.ContextMenu

$menuStart = New-Object System.Windows.Forms.MenuItem "🟢  Green Start (Connect)"
$menuStart.add_Click({
    $startBat = "$env:ProgramFiles\XrayVPN\Start_VPN.bat"
    if (Test-Path $startBat) {
        Start-Process "cmd.exe" -ArgumentList "/c `"$startBat`"" -Verb RunAs
    } else {
        [System.Windows.Forms.MessageBox]::Show("Start_VPN.bat not found!", "Xray VPN")
    }
})

$menuStop = New-Object System.Windows.Forms.MenuItem "🔴  Red Stop (Disconnect)"
$menuStop.add_Click({
    Stop-Process -Name "xray","v2ray","wintun" -Force -ErrorAction SilentlyContinue
    $notifyIcon.Icon = New-ColorIcon $COLOR_IDLE
    $notifyIcon.BalloonTipTitle = "Xray VPN"
    $notifyIcon.BalloonTipText  = "VPN disconnected."
    $notifyIcon.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Info
    $notifyIcon.ShowBalloonTip(2000)
})

$menuSep1 = New-Object System.Windows.Forms.MenuItem "-"

$menuGit = New-Object System.Windows.Forms.MenuItem "📂  GitHub: Windows_scripts / VPN"
$menuGit.add_Click({
    Start-Process "https://github.com/GinCz/Windows_scripts/tree/main/Windows/VPN"
})

$menuSep2 = New-Object System.Windows.Forms.MenuItem "-"

$menuExit = New-Object System.Windows.Forms.MenuItem "✖  Exit Tray"
$menuExit.add_Click({
    $notifyIcon.Visible = $false
    $notifyIcon.Dispose()
    [System.Windows.Forms.Application]::Exit()
})

$menu.MenuItems.Add($menuStart) | Out-Null
$menu.MenuItems.Add($menuStop)  | Out-Null
$menu.MenuItems.Add($menuSep1)  | Out-Null
$menu.MenuItems.Add($menuGit)   | Out-Null
$menu.MenuItems.Add($menuSep2)  | Out-Null
$menu.MenuItems.Add($menuExit)  | Out-Null
$notifyIcon.ContextMenu = $menu

# ── Таймер обновления статуса каждые 5 секунд ─────────────────────────
$script:lastVpnIp = ""
$timer = New-Object System.Windows.Forms.Timer
$timer.Interval = 5000
$timer.add_Tick({
    $vpnOk = Test-VpnRunning
    $txt = Get-TooltipText
    $notifyIcon.Text = $txt

    if ($vpnOk) {
        $curIp = Get-CurrentIp
        if ($curIp -ne $script:originalIp -and $curIp -ne "Unavailable") {
            # IP сменился — VPN работает полноценно
            $notifyIcon.Icon = New-ColorIcon $COLOR_CONNECTED
            # Balloon при первом успешном подключении
            if ($script:lastVpnIp -ne $curIp) {
                $script:lastVpnIp = $curIp
                $notifyIcon.BalloonTipTitle = "Xray VPN: Connected"
                $notifyIcon.BalloonTipText  = "VPN IP:      $curIp`nOriginal IP: $($script:originalIp)`nUser:        $($script:userName)"
                $notifyIcon.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Info
                $notifyIcon.ShowBalloonTip(4000)
            }
        } else {
            # Процесс есть, но IP ещё не сменился (коннектится)
            $notifyIcon.Icon = New-ColorIcon $COLOR_CONNECTING
        }
    } else {
        $notifyIcon.Icon = New-ColorIcon $COLOR_IDLE
        $script:lastVpnIp = ""
    }
})
$timer.Start()

# ── Мониторинг файла-флага для balloon при ошибке ─────────────────────
# Start_VPN.bat должен писать "ERROR: описание" в этот файл при ошибке
$flagFile = "$env:TEMP\xrayvpn_status.txt"
$flagTimer = New-Object System.Windows.Forms.Timer
$flagTimer.Interval = 2000
$flagTimer.add_Tick({
    if (Test-Path $flagFile) {
        $statusContent = (Get-Content $flagFile -Raw).Trim()
        Remove-Item $flagFile -Force -ErrorAction SilentlyContinue
        if ($statusContent -match "ERROR") {
            $notifyIcon.Icon = New-ColorIcon $COLOR_ERROR
            $notifyIcon.BalloonTipTitle = "Xray VPN - Connection Error!"
            $notifyIcon.BalloonTipText  = $statusContent
            $notifyIcon.BalloonTipIcon  = [System.Windows.Forms.ToolTipIcon]::Error
            $notifyIcon.ShowBalloonTip(6000)
        }
    }
})
$flagTimer.Start()

# ── Запуск UI-цикла (блокирующий) ─────────────────────────────────────
[System.Windows.Forms.Application]::Run()
$timer.Stop()
$flagTimer.Stop()
$notifyIcon.Dispose()
