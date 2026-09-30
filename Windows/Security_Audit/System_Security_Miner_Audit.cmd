<# :
@echo off
setlocal
chcp 65001 >nul
title System Security & Cryptominer Audit - VladiMIR+AI

:: 100% Reliable Auto-Elevation to Administrator
fltmc >nul 2>&1 || (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process cmd -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((Get-Content -LiteralPath '%~f0' -Encoding UTF8) -join [Environment]::NewLine)"
if %errorlevel% neq 0 pause
exit /b %errorlevel%
#>

# =============================================================================
# Execution Context : Windows PowerShell (Administrator)
# Target System     : Local Windows PC / Workstation / Server
# Author / Project  : VladiMIR+AI (https://github.com/GinCz)
# Description       : Windows Advanced Security & Cryptominer Deep Audit
# Color Scheme      : Green / Yellow / Red
# =============================================================================

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding  = [System.Text.Encoding]::UTF8
$OutputEncoding           = [System.Text.Encoding]::UTF8
$Host.UI.RawUI.WindowTitle = "System Security & Cryptominer Deep Audit | VladiMIR+AI"
$ErrorActionPreference    = 'SilentlyContinue'

# Adjust Console Buffer & Window Size safely
try {
    if ($Host.UI.RawUI.WindowSize.Width -lt 100) {
        $Host.UI.RawUI.BufferSize = New-Object System.Management.Automation.Host.Size(100, 300)
        $Host.UI.RawUI.WindowSize = New-Object System.Management.Automation.Host.Size(100, 35)
    }
} catch {}

$TermWidth = 96

function Draw-Banner {
    Clear-Host
    Write-Host ("-" * $TermWidth) -ForegroundColor Green
    Write-Host "   WINDOWS ADVANCED SECURITY & CRYPTOMINER AUDIT" -ForegroundColor Yellow
    Write-Host "   Anti-Gravity 222 Security Suite | VladiMIR+AI" -ForegroundColor Green
    Write-Host ("-" * $TermWidth) -ForegroundColor Green
    Write-Host ""
}

Draw-Banner

Write-Host "   Select interface language / Zvolte jazyk / Выберите язык:" -ForegroundColor Yellow
Write-Host "   [1] English (Default / Press Enter)" -ForegroundColor Green
Write-Host "   [2] Česky" -ForegroundColor Yellow
Write-Host "   [3] Русский" -ForegroundColor Yellow
Write-Host ""

$SelectedLang = Read-Host "   Selection [1/2/3] (Default: 1)"
if ($SelectedLang -notin @('1','2','3')) { $SelectedLang = '1' }
$LangIdx = [int]$SelectedLang - 1

Draw-Banner

$Findings = New-Object System.Collections.ArrayList
$SeenEntries = @{}

function Add-Finding($Category, $Level, $Message) {
    $Key = "$Category|$Level|$Message"
    if (-not $SeenEntries.ContainsKey($Key)) {
        $SeenEntries[$Key] = $true
        [void]$Findings.Add([PSCustomObject]@{
            Category = $Category
            Level    = $Level
            Message  = [string]$Message
        })
    }
}

function Show-Step($StepNum, $TotalSteps, $Text) {
    Write-Host ("   [{0:D2}/{1:D2}] " -f $StepNum, $TotalSteps) -NoNewline -ForegroundColor Yellow
    Write-Host "$Text..." -ForegroundColor Green
}

$SignatureCache = @{}
function Get-FileSignatureStatus($FilePath) {
    if (-not $FilePath -or -not (Test-Path -LiteralPath $FilePath)) { return 'Missing' }
    if (-not $SignatureCache.ContainsKey($FilePath)) {
        $Sig = Get-AuthenticodeSignature -LiteralPath $FilePath
        $Status = [string]$Sig.Status
        if ($Status -ne 'Valid' -and ($FilePath -like "$env:windir\System32\*" -or $FilePath -like "$env:windir\SysWOW64\*")) {
            if ($Sig.SignerCertificate -or ($Sig.StatusMessage -match 'Catalog')) {
                $Status = 'Valid'
            }
        }
        $SignatureCache[$FilePath] = $Status
    }
    return $SignatureCache[$FilePath]
}

function Extract-ExecutablePath($CommandString) {
    if (-not $CommandString) { return $null }
    $Expanded = [Environment]::ExpandEnvironmentVariables($CommandString.Trim()) -replace '^\\\?\?\\',''
    if ($Expanded -match '^"([^"]+)"') { return $Matches[1] }
    if ($Expanded -match '^(.+?\.(exe|dll|sys|bat|cmd|vbs|ps1|lnk))') { return $Matches[1] }
    return ($Expanded -split ' ')[0]
}

function Get-PluralRU($n, $f1, $f2, $f5) {
    $mod10 = $n % 10
    $mod100 = $n % 100
    if ($mod100 -ge 11 -and $mod100 -le 19) { return "$n $f5" }
    if ($mod10 -eq 1) { return "$n $f1" }
    if ($mod10 -ge 2 -and $mod10 -le 4) { return "$n $f2" }
    return "$n $f5"
}

# Dynamic Real Desktop Detection
$DesktopPath = [Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
if (-not $DesktopPath -or -not (Test-Path $DesktopPath)) {
    try {
        $RegDesktop = (Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction SilentlyContinue).Desktop
        if ($RegDesktop) { $DesktopPath = [Environment]::ExpandEnvironmentVariables($RegDesktop) }
    } catch {}
}
if (-not $DesktopPath -or -not (Test-Path $DesktopPath)) {
    $DesktopPath = "$env:USERPROFILE\Desktop"
}
$ReportPath = Join-Path $DesktopPath "Security_Audit_Report.txt"

# Regex definitions
$WritableFolderRegex = '\\(Users|Temp|ProgramData|PerfLogs)\\|\$Recycle\.Bin'
$MinerProcessRegex   = 'xmrig|nicehash|minerd|nbminer|phoenixminer|t-rex|lolminer|ethminer|cgminer|bfgminer|claymore|gminer|teamredminer|srbminer|xmr-stak|cpuminer|wildrig|minergate|nanominer|kawpowminer|bzminer|onezerominer|winring0|kryptex|xmrigcc|silentcrypto'
$MinerCommandRegex   = 'stratum\+|stratum2\+|stratum\+tcp|stratum\+ssl|--donate-level|--coin[= ]|cryptonight|randomx|nanopool|minexmr|supportxmr|moneroocean|2miners|f2pool|ethermine|hashvault|c3pool|unmineable|--cpu-priority|--max-cpu-usage|--background|-B\b'
$MinerPoolRegex      = 'nanopool|minexmr|supportxmr|moneroocean|2miners|f2pool|ethermine|hashvault|c3pool|unmineable|nicehash|minergate|xmrpool|herominers|monerohash|miningpoolhub|antpool|viabtc|flexpool|hiveon|zpool|prohashing|slushpool|stratum|kryptex'
$SuspiciousCmdRegex  = '-enc\b|-encodedcommand|frombase64|downloadstring|downloadfile|invoke-webrequest|\biex\b|invoke-expression|mshta|certutil.*-urlcache|bitsadmin.*\/transfer|regsvr32.*http|\\Temp\\|\\Users\\Public\\'
$RemoteAccessRegex   = 'teamviewer|anydesk|rustdesk|ultravnc|tightvnc|winvnc|tvnserver|ammyy|supremo|logmein|screenconnect|connectwise|splashtop|radmin|dwagent|dwservice|meshagent|remoteutilities|rutserv|parsec|zohoassist|nomachine|atera|action1|simplehelp|netsupport|remotepc|aeroadmin|gotomypc|vncserver'
$TunnelRegex         = 'ngrok|cloudflared|frpc|frps|chisel|ligolo|playit|bore|localxpose|pinggy|pagekite'
$SystemProcessNames  = 'svchost|csrss|lsass|services|winlogon|smss|wininit|taskhostw|dllhost|spoolsv|RuntimeBroker|conhost|explorer|SearchIndexer|fontdrvhost|dwm|ctfmon|sihost|audiodg|WmiPrvSE'
$PrivateIpRegex      = '^(127\.|10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|169\.254\.|::1|fe80|0\.0\.0\.0|::$)'

$StepHeaders = @(
    @("Enumerating active processes", "Skenování aktivních procesů", "Анализ активных процессов"),
    @("Sampling CPU load for silent background miners (5s)", "Měření zatížení CPU (5s)", "Замер фоновой нагрузки CPU (5 сек)"),
    @("Analyzing process integrity and arguments", "Analýza integrity a parametrů procesů", "Проверка целостности и параметров процессов"),
    @("Checking network sockets and miner ports", "Kontrola síťových spojení a portů", "Проверка сетевых соединений и майнинг-портов"),
    @("Inspecting DNS client resolution cache", "Inspekce DNS cache na těžební pooly", "Проверка DNS-кэша на майнинг-пулы"),
    @("Scanning for reverse tunnels & remote tools", "Hledání reverzních tunelů a vzdálené správy", "Поиск скрытых туннелей и удаленного доступа"),
    @("Auditing Task Scheduler triggers", "Audit úloh v Plánovači úloh", "Аудит задач в Планировщике Windows"),
    @("Inspecting Windows Registry startup & Shell keys", "Kontrola registrů a automatického spuštění", "Проверка реестра, автозагрузки и Shell"),
    @("Checking Startup folders for suspicious shortcuts", "Kontrola složek Po spuštění", "Проверка ярлыков в папках Автозагрузки"),
    @("Checking IFEO process hijacking & persistence", "Kontrola zneužití IFEO v registrech", "Проверка перехвата процессов (IFEO)"),
    @("Auditing local administrator accounts", "Audit účtů lokálních administrátorů", "Аудит локальных администраторов"),
    @("Auditing WMI event subscriptions", "Audit WMI odběrů událostí", "Аудит WMI-автозапуска и подписок"),
    @("Checking Windows Defender status & exclusions", "Kontrola stavu a výjimek Windows Defender", "Проверка защиты и исключений Defender"),
    @("Scanning for hardware kernel drivers", "Hledání zranitelných kernel ovladačů", "Поиск низкоуровневых драйверов (WinRing0)"),
    @("Checking Hosts file & proxy redirections", "Kontrola souboru Hosts a proxy", "Проверка файла Hosts и системного прокси"),
    @("Scanning folders for miner JSON configs", "Hledání JSON konfigurací těžařů", "Поиск конфигов майнеров в Temp/AppData")
)

$TotalSteps = 16

# 1. Process Enumeration
Show-Step 1 $TotalSteps $StepHeaders[0][$LangIdx]
$Processes = Get-CimInstance Win32_Process
$ProcessTable = @{}
$Processes | ForEach-Object { $ProcessTable[[int]$_.ProcessId] = $_ }

# 2. CPU Load Sampling
Show-Step 2 $TotalSteps $StepHeaders[1][$LangIdx]
$LogicalCores = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
if (-not $LogicalCores -or $LogicalCores -le 0) { $LogicalCores = 1 }
$CpuSnapshotStart = @{}
Get-Process | ForEach-Object { $CpuSnapshotStart[$_.Id] = $_.CPU }
Start-Sleep -Seconds 5
$TopCpuConsumers = Get-Process | Where-Object { $CpuSnapshotStart.ContainsKey($_.Id) -and $null -ne $_.CPU } | ForEach-Object {
    [PSCustomObject]@{
        Id   = $_.Id
        Name = $_.Name
        Path = $_.Path
        Load = [math]::Round(((($_.CPU - $CpuSnapshotStart[$_.Id]) / 5 / $LogicalCores) * 100), 1)
    }
} | Sort-Object Load -Descending

$TopCpuConsumers | Where-Object { $_.Load -ge 25 } | ForEach-Object {
    Add-Finding 'CPU' 'WARN' "$($_.Name) [PID: $($_.Id)] -> $($_.Load)% CPU ($($_.Path))"
}
$MaxCpuItem = $TopCpuConsumers | Select-Object -First 1

# 3. Process Signatures & Masquerading
Show-Step 3 $TotalSteps $StepHeaders[2][$LangIdx]
foreach ($Proc in $Processes) {
    if ($Proc.ProcessId -eq $PID) { continue }
    $PName = $Proc.Name
    $PPath = $Proc.ExecutablePath
    $PCmd  = [string]$Proc.CommandLine
    if ($PName -match $MinerProcessRegex -or $PPath -match $MinerProcessRegex) {
        Add-Finding 'MINER' 'CRIT' "Miner signature detected: $PName (PID: $($Proc.ProcessId)) -> $PPath"
    }
    if ($PCmd -match $MinerCommandRegex) {
        $TruncatedCmd = $PCmd.Substring(0, [math]::Min(120, $PCmd.Length))
        Add-Finding 'MINER' 'CRIT' "Miner CLI arguments: $PName (PID: $($Proc.ProcessId)): $TruncatedCmd"
    }
    if ($PPath) {
        $SigStatus = Get-FileSignatureStatus $PPath
        if ($SigStatus -eq 'HashMismatch') {
            Add-Finding 'PROC' 'CRIT' "Signature hash mismatch (patched binary): $PPath"
        } elseif ($PName -match "^($SystemProcessNames)\.exe$" -and $PPath -notlike "$env:windir\*") {
            Add-Finding 'PROC' 'CRIT' "Fake system binary outside Windows: $PName -> $PPath"
        } elseif ($PPath -match $WritableFolderRegex -and $SigStatus -notin @('Valid', 'Missing')) {
            Add-Finding 'PROC' 'WARN' "Unsigned binary in writable path ($SigStatus): $PPath"
        }
    }
}

# 4. Network Connections
Show-Step 4 $TotalSteps $StepHeaders[3][$LangIdx]
$MiningPorts = @(3333, 4444, 5555, 6666, 7777, 8888, 9999, 14444, 14433, 45560, 45700, 3357, 10128, 5730, 9980)
Get-NetTCPConnection -State Established | Where-Object { $MiningPorts -contains $_.RemotePort -and $_.RemoteAddress -notmatch $PrivateIpRegex } | ForEach-Object {
    $Owner = $ProcessTable[[int]$_.OwningProcess]
    Add-Finding 'NET' 'WARN' "Connection to mining port: $($Owner.Name) (PID: $($_.OwningProcess)) -> $($_.RemoteAddress):$($_.RemotePort)"
}

# 5. DNS Cache
Show-Step 5 $TotalSteps $StepHeaders[4][$LangIdx]
Get-DnsClientCache | Where-Object { $_.Entry -match $MinerPoolRegex } | ForEach-Object {
    Add-Finding 'DNS' 'WARN' "Mining pool in DNS cache: $($_.Entry)"
}

# 6. Tunnels & Remote Access
Show-Step 6 $TotalSteps $StepHeaders[5][$LangIdx]
Get-Process | Where-Object { $_.Name -match $TunnelRegex } | ForEach-Object {
    Add-Finding 'TUNNEL' 'WARN' "Active reverse tunnel: $($_.Name) (PID: $($_.Id)) -> $($_.Path)"
}

$RemoteProcs = Get-Process | Where-Object { $_.Name -match $RemoteAccessRegex }
$RemoteSummary = @()
if ($RemoteProcs) {
    $Grouped = $RemoteProcs | Group-Object Name
    foreach ($grp in $Grouped) {
        $RemoteSummary += "$($grp.Name) ($($grp.Count))"
        Add-Finding 'REMOTE' 'INFO' "Remote access tool: $($grp.Name) ($($grp.Count) active processes)"
    }
}

# 7. Scheduled Tasks
Show-Step 7 $TotalSteps $StepHeaders[6][$LangIdx]
Get-ScheduledTask | ForEach-Object {
    $Task = $_
    $ActionStr = ($Task.Actions | ForEach-Object { "$($_.Execute) $($_.Arguments)" }) -join ' | '
    $ExecPath  = Extract-ExecutablePath ($Task.Actions | Select-Object -First 1).Execute
    if ($ActionStr -match $SuspiciousCmdRegex) {
        Add-Finding 'TASK' 'CRIT' "Suspicious command in task: $($Task.TaskPath)$($Task.TaskName) -> $ActionStr"
    } elseif ($ExecPath -and $ExecPath -match $WritableFolderRegex -and (Get-FileSignatureStatus $ExecPath) -notin @('Valid','Missing')) {
        Add-Finding 'TASK' 'WARN' "Task runs untrusted file from user folder: $($Task.TaskName) -> $ExecPath"
    }
}

# 8. Registry Startup & Winlogon Shell
Show-Step 8 $TotalSteps $StepHeaders[7][$LangIdx]
$RunKeys = @(
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run',
    'HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce',
    'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
)
foreach ($Key in $RunKeys) {
    if (Test-Path $Key) {
        (Get-ItemProperty $Key).PSObject.Properties | Where-Object { $_.Name -notlike 'PS*' } | ForEach-Object {
            $ValStr = [string]$_.Value
            $TargetPath = Extract-ExecutablePath $ValStr
            if ($ValStr -match $SuspiciousCmdRegex -or $ValStr -match '\\Downloads\\') { 
                Add-Finding 'RUN' 'CRIT' "Suspicious autorun: $($_.Name) = $ValStr"
            } elseif ($TargetPath -and $TargetPath -match $WritableFolderRegex -and (Get-FileSignatureStatus $TargetPath) -notin @('Valid','Missing')) { 
                Add-Finding 'RUN' 'WARN' "Unsigned autorun binary in user folder: $($_.Name) = $ValStr"
            }
        }
    }
}
$Winlogon = Get-ItemProperty 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon' -ErrorAction SilentlyContinue
if ($Winlogon.Shell -and $Winlogon.Shell -ne 'explorer.exe') {
    Add-Finding 'RUN' 'CRIT' "Winlogon Shell hijacked: $($Winlogon.Shell) (Expected: explorer.exe)"
}
if ($Winlogon.Userinit -and $Winlogon.Userinit -notmatch '^C:\\Windows\\system32\\userinit\.exe,?$') {
    Add-Finding 'RUN' 'CRIT' "Winlogon Userinit modified: $($Winlogon.Userinit)"
}

# 9. Startup Folders
Show-Step 9 $TotalSteps $StepHeaders[8][$LangIdx]
$StartupDirs = @(
    "$env:APPDATA\Microsoft\Windows\Start Menu\Programs\Startup",
    "$env:ProgramData\Microsoft\Windows\Start Menu\Programs\Startup"
)
foreach ($sDir in $StartupDirs) {
    if (Test-Path $sDir) {
        Get-ChildItem -LiteralPath $sDir -File | ForEach-Object {
            if ($_.Extension -in @('.bat','.cmd','.vbs','.ps1','.exe','.hta')) {
                Add-Finding 'STARTUP' 'WARN' "Executable script in Startup folder: $($_.FullName)"
            }
        }
    }
}

# 10. IFEO Process Hijacking
Show-Step 10 $TotalSteps $StepHeaders[9][$LangIdx]
$IfeoPath = 'HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Image File Execution Options'
if (Test-Path $IfeoPath) {
    Get-ChildItem $IfeoPath | ForEach-Object {
        $Debugger = (Get-ItemProperty $_.PSPath).Debugger
        if ($Debugger) {
            Add-Finding 'IFEO' 'CRIT' "Process hijacked via IFEO: $($_.PSChildName) -> $Debugger"
        }
    }
}

# 11. Local Administrators
Show-Step 11 $TotalSteps $StepHeaders[10][$LangIdx]
$AdminGroup = Get-CimInstance Win32_Group -Filter "SID = 'S-1-5-32-544'"
$AdminUsersCount = 0
if ($AdminGroup) {
    $AdminMembers = Get-CimAssociatedInstance -InputObject $AdminGroup -ResultClassName Win32_UserAccount
    $AdminUsersCount = @($AdminMembers).Count
    $AdminMembers | Where-Object { $_.Name -match '^(defaultuser|support_|guest|temp)' } | ForEach-Object {
        Add-Finding 'ADMINS' 'WARN' "Suspicious user in local Administrators group: $($_.Name)"
    }
}

# 12. WMI Subscriptions
Show-Step 12 $TotalSteps $StepHeaders[11][$LangIdx]
Get-CimInstance -Namespace root\subscription -ClassName __EventConsumer | Where-Object { $_.Name -ne 'SCM Event Log Consumer' } | ForEach-Object {
    Add-Finding 'WMI' 'CRIT' "WMI Consumer persistence: $($_.__CLASS) $($_.Name)"
}

# 13. Windows Defender
Show-Step 13 $TotalSteps $StepHeaders[12][$LangIdx]
$MpPref = Get-MpPreference
$MpStatus = Get-MpComputerStatus
if ($MpStatus) {
    if (-not $MpStatus.RealTimeProtectionEnabled) {
        Add-Finding 'DEF' 'CRIT' "Defender Real-Time Protection is DISABLED"
    }
    if ($MpStatus.AntivirusSignatureAge -gt 7) {
        Add-Finding 'DEF' 'WARN' "Antivirus definitions outdated ($($MpStatus.AntivirusSignatureAge) days old)"
    }
}
$Exclusions = @($MpPref.ExclusionPath | Where-Object { $_ })
foreach ($Exc in $Exclusions) {
    if ($Exc -match '^[A-Za-z]:\\?$' -or $Exc -match '\\(Temp|Downloads|Users\\Public)\\?$|^C:\\(Users|ProgramData|Windows)\\?$') {
        Add-Finding 'DEF' 'CRIT' "Dangerous Defender exclusion: $Exc"
    } else {
        Add-Finding 'DEF' 'INFO' "Defender exclusion path: $Exc"
    }
}

# 14. Hardware Drivers
Show-Step 14 $TotalSteps $StepHeaders[13][$LangIdx]
Get-CimInstance Win32_SystemDriver | Where-Object { $_.State -eq 'Running' } | ForEach-Object {
    $DriverPath = Extract-ExecutablePath $_.PathName
    if ($_.Name -match 'winring0|inpout|processhacker' -or $DriverPath -match 'winring0|inpout|kprocesshacker') {
        Add-Finding 'DRV' 'WARN' "Direct hardware access driver: $($_.Name) ($DriverPath)"
    }
}

# 15. Hosts & Proxy
Show-Step 15 $TotalSteps $StepHeaders[14][$LangIdx]
$HostsContent = Get-Content "$env:windir\System32\drivers\etc\hosts" | Where-Object { $_ -match '\S' -and $_ -notmatch '^\s*#' }
$SecurityVendors = 'microsoft|windowsupdate|defender|kaspersky|avast|eset|malwarebytes|virustotal'
foreach ($Line in $HostsContent) {
    if ($Line -match $SecurityVendors) { 
        Add-Finding 'HOSTS' 'CRIT' "Security update blocked in Hosts: $($Line.Trim())"
    }
}

# 16. Dropped Miner Configs
Show-Step 16 $TotalSteps $StepHeaders[15][$LangIdx]
$ScanDirs = @($env:LOCALAPPDATA, $env:APPDATA, $env:ProgramData, "$env:windir\Temp")
foreach ($Dir in ($ScanDirs | Where-Object { $_ -and (Test-Path $_) })) {
    Get-ChildItem -LiteralPath $Dir -Depth 3 -Filter "config.json" -File | ForEach-Object {
        if (Select-String -LiteralPath $_.FullName -Pattern '"pools"|donate-level|"randomx"|cryptonight' -Quiet) {
            Add-Finding 'FILES' 'CRIT' "Cryptominer JSON config found: $($_.FullName)"
        }
    }
}

# ----------------- REPORT FILE EXPORT -----------------
$Header = "System Security Audit Report | Author: VladiMIR+AI | Host: $env:COMPUTERNAME | Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | OS: $((Get-CimInstance Win32_OperatingSystem).Caption)"
$ReportLines = @($Header, ('-' * 90))
$ReportLines += $Findings | Sort-Object @{Expression={ switch($_.Level){'CRIT'{0}'WARN'{1}default{2}} }} | ForEach-Object {
    "[{0,-4}] {1,-8} : {2}" -f $_.Level, $_.Category, $_.Message
}
$ReportLines | Out-File -FilePath $ReportPath -Encoding UTF8

# ----------------- LOCALIZED CATEGORIES & RESULTS -----------------
$AuditSections = [ordered]@{
    CPU     = @{ Title = @("CPU Load", "Zatížení procesoru (CPU)", "Нагрузка на процессор (CPU)") }
    MINER   = @{ Title = @("Cryptominer Signatures", "Signatury kryptotěžařů", "Сигнатуры криптомайнеров") }
    PROC    = @{ Title = @("Process Integrity & Spoofing", "Integrita a maskování procesů", "Целостность системных процессов") }
    NET     = @{ Title = @("Mining Pool Connections", "Spojení s těžebními pooly", "Сетевые соединения с пулами") }
    DNS     = @{ Title = @("Mining Pools in DNS Cache", "Těžební pooly v DNS cache", "DNS-кэш майнинг-пулов") }
    TUNNEL  = @{ Title = @("Reverse Tunnels (ngrok/chisel)", "Reverzní tunely (ngrok apod.)", "Скрытые реверс-туннели (ngrok)") }
    REMOTE  = @{ Title = @("Remote Administration Tools", "Užitky vzdálené správy", "Утилиты удаленного доступа") }
    TASK    = @{ Title = @("Task Scheduler Triggers", "Úlohy v Plánovači úloh", "Задачи в Планировщике Windows") }
    RUN     = @{ Title = @("Registry Autorun & Shell", "Automatické spouštění a Shell", "Автозапуск реестра и Winlogon") }
    STARTUP = @{ Title = @("Startup Folders (.lnk / scripts)", "Složky Po spuštění", "Автозагрузка папок (Startup)") }
    IFEO    = @{ Title = @("IFEO Process Hijacking", "Převzetí procesů přes IFEO", "Перехват процессов (IFEO)") }
    ADMINS  = @{ Title = @("Local Administrators Group", "Místní administrátoři", "Локальные администраторы") }
    WMI     = @{ Title = @("WMI Event Persistence", "WMI perzistence", "WMI-подписки персистентности") }
    DEF     = @{ Title = @("Windows Defender Health", "Stav Windows Defender", "Состояние Windows Defender") }
    DRV     = @{ Title = @("Direct Hardware Drivers", "Nízkoúrovňové ovladače", "Низкоуровневые драйверы (Ring0)") }
    HOSTS   = @{ Title = @("Hosts File & Proxy", "Soubor Hosts a Proxy", "Файл Hosts и системный прокси") }
    FILES   = @{ Title = @("Miner Configuration Files", "Konfigurační soubory těžařů", "Конфигурации майнеров (JSON)") }
}

$ReportHeaders = @(
    "SYSTEM SECURITY & CRYPTOMINER AUDIT RESULTS",
    "VÝSLEDKY AUDITU BEZPEČNOSTI A KRYPTOTĚŽAŘŮ",
    "РЕЗУЛЬТАТЫ АУДИТА БЕЗОПАСНОСТИ И КРИПТОМАЙНЕРОВ"
)

# ----------------- DISPLAY RESULTS -----------------
Draw-Banner

Write-Host "   $($ReportHeaders[$LangIdx])" -ForegroundColor Yellow
Write-Host ("   Author: VladiMIR+AI | Host: $env:COMPUTERNAME | Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')") -ForegroundColor Green
Write-Host ("-" * $TermWidth) -ForegroundColor Green

$TotalCrit = 0
$TotalWarn = 0

function Format-ResultLine($NumTag, $Title, $Badge, $BadgeColor, $StatusText, $StatusColor) {
    $TitlePadded = "{0,-36}" -f $Title
    Write-Host "   $NumTag $TitlePadded : " -NoNewline -ForegroundColor Green
    Write-Host "[$Badge] " -NoNewline -ForegroundColor $BadgeColor
    Write-Host "$StatusText" -ForegroundColor $StatusColor
}

$Idx = 1
foreach ($SecKey in $AuditSections.Keys) {
    $NumTag = "[{0:D2}]" -f $Idx
    $SecItems = @($Findings | Where-Object { $_.Category -eq $SecKey })
    $CritItems = @($SecItems | Where-Object { $_.Level -eq 'CRIT' })
    $WarnItems = @($SecItems | Where-Object { $_.Level -eq 'WARN' })
    $TotalCrit += $CritItems.Count
    $TotalWarn += $WarnItems.Count

    $SecTitle = $AuditSections[$SecKey].Title[$LangIdx]
    
    switch ($SecKey) {
        'CPU' {
            if ($CritItems.Count -gt 0 -or $WarnItems.Count -gt 0) {
                $Status = @("High load: $($WarnItems.Count) processes", "Vysoké zatížení: $($WarnItems.Count) procesů", "Высокая нагрузка: $(Get-PluralRU $WarnItems.Count 'процесс' 'процесса' 'процессов')")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' NO ' 'Yellow' $Status 'Yellow'
            } else {
                $TopTxt = if ($MaxCpuItem) { "(Peak: $($MaxCpuItem.Name) $($MaxCpuItem.Load)%)" } else { "" }
                $Status = @("Normal $TopTxt", "V normě $TopTxt", "В норме $TopTxt")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' OK ' 'Green' $Status 'Yellow'
            }
        }
        'REMOTE' {
            if ($RemoteSummary.Count -gt 0) {
                $Status = @("Active tools detected ($($RemoteSummary.Count))", "Aktivní nástroje ($($RemoteSummary.Count))", "Обнаружены активные утилиты ($($RemoteSummary.Count))")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' OK ' 'Green' $Status 'Yellow'
                Write-Host "            ↳ $($RemoteSummary -join ', ')" -ForegroundColor Yellow
            } else {
                $Status = @("0 active tools", "0 aktivních nástrojů", "0 активных утилит")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' OK ' 'Green' $Status 'Yellow'
            }
        }
        'ADMINS' {
            if ($WarnItems.Count -gt 0) {
                $Status = @("Warning: $($WarnItems.Count) suspicious", "Varování: $($WarnItems.Count) podezřelých", "Предупреждение: $(Get-PluralRU $WarnItems.Count 'аккаунт' 'аккаунта' 'аккаунтов')")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' NO ' 'Yellow' $Status 'Yellow'
            } else {
                $Status = @("Verified ($AdminUsersCount accounts)", "Ověřeno ($AdminUsersCount účtů)", "Проверено ($(Get-PluralRU $AdminUsersCount 'аккаунт' 'аккаунта' 'аккаунтов'))")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' OK ' 'Green' $Status 'Yellow'
            }
        }
        'DEF' {
            if ($CritItems.Count -gt 0) {
                $Status = @("Dangerous exclusions or protection disabled!", "Nebezpečné výjimky nebo vypnutá ochrana!", "Опасные исключения или защита отключена!")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' NO ' 'Red' $Status 'Red'
            } elseif ($WarnItems.Count -gt 0) {
                $Status = @("Outdated antivirus definitions", "Zastaralé virové definice", "Устаревшие антивирусные базы")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' NO ' 'Yellow' $Status 'Yellow'
            } else {
                $Status = @("Active, 0 dangerous exclusions", "Aktivní, 0 nebezpečných výjimek", "Активен, опасных исключений: 0")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' OK ' 'Green' $Status 'Yellow'
            }
        }
        default {
            if ($CritItems.Count -gt 0) {
                $Status = @("Threat detected: $($CritItems.Count) matches", "Nalezena hrozba: $($CritItems.Count)", "Критично: $(Get-PluralRU $CritItems.Count 'угроза' 'угрозы' 'угроз')")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' NO ' 'Red' $Status 'Red'
            } elseif ($WarnItems.Count -gt 0) {
                $Status = @("Warning: $($WarnItems.Count) suspicious items", "Varování: $($WarnItems.Count) položek", "Предупреждение: $(Get-PluralRU $WarnItems.Count 'элемент' 'элемента' 'элементов')")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' NO ' 'Yellow' $Status 'Yellow'
            } else {
                $Status = @("0 detected / Clean", "0 nalezeno / Čisté", "0 обнаружено / Чисто")[$LangIdx]
                Format-ResultLine $NumTag $SecTitle ' OK ' 'Green' $Status 'Yellow'
            }
        }
    }

    # Display threat details under NO with clean line-breaks
    $Threats = @($SecItems | Where-Object { $_.Level -in @('CRIT', 'WARN') })
    if ($Threats.Count -gt 0) {
        $Threats | Select-Object -First 4 | ForEach-Object {
            $Msg = $_.Message
            $DetailColor = if ($_.Level -eq 'CRIT') { 'Red' } else { 'Yellow' }
            
            if ($Msg -match '^(.+?:\s*)([A-Za-z]:\\[^;]+|\\\\[^;]+)(.*)$') {
                $Prefix = $Matches[1].Trim()
                $PathVal = $Matches[2].Trim()
                $Suffix = $Matches[3].Trim()
                Write-Host "            • $Prefix" -ForegroundColor $DetailColor
                Write-Host "              ↳ $PathVal $Suffix" -ForegroundColor $DetailColor
            } elseif ($Msg -match '^(.+?->\s*)([A-Za-z]:\\[^;]+)(.*)$') {
                $Prefix = $Matches[1].Trim()
                $PathVal = $Matches[2].Trim()
                $Suffix = $Matches[3].Trim()
                Write-Host "            • $Prefix" -ForegroundColor $DetailColor
                Write-Host "              ↳ $PathVal $Suffix" -ForegroundColor $DetailColor
            } else {
                Write-Host "            • $Msg" -ForegroundColor $DetailColor
            }
        }
    }

    $Idx++
}

Write-Host ("-" * $TermWidth) -ForegroundColor Green

# Summary Message
if ($TotalCrit -gt 0) {
    $SummaryTxt = @("CRITICAL: High-risk threats or active miners identified!", "KRITICKÉ: Nalezeny vážné hrozby nebo aktivní těžaři!", "КРИТИЧНО: Обнаружены активные угрозы или майнеры!")[$LangIdx]
    Write-Host "   [!] $SummaryTxt" -ForegroundColor Red
} elseif ($TotalWarn -gt 0) {
    $SummaryTxt = @("WARNING: Suspicious items found. Review highlighted entries.", "VAROVÁNÍ: Nalezeny podezřelé položky. Zkontrolujte výpis.", "ВНИМАНИЕ: Найдены подозрительные элементы, проверьте список.")[$LangIdx]
    Write-Host "   [*] $SummaryTxt" -ForegroundColor Yellow
} else {
    $SummaryTxt = @("CLEAN: No active cryptominers or threats found.", "ČISTÉ: Žádné známky těžařů ani hrozeb.", "ЧИСТО: Признаков активности майнеров и угроз не найдено.")[$LangIdx]
    Write-Host "   [OK] $SummaryTxt" -ForegroundColor Green
}

$StatsLabel = @("Stats", "Statistika", "Статистика")[$LangIdx]
$ReportLabel = @("Report saved to", "Report uložen do", "Отчет сохранен в")[$LangIdx]
$PressKeyLabel = @("Press any key to close...", "Stiskněte libovolnou klávesu...", "Нажмите любую клавишу для выхода...")[$LangIdx]

Write-Host "   $StatsLabel : " -NoNewline -ForegroundColor Green
if ($TotalCrit -gt 0) {
    Write-Host "Critical: $TotalCrit " -NoNewline -ForegroundColor Red
} else {
    Write-Host "Critical: 0 " -NoNewline -ForegroundColor Green
}
Write-Host "| " -NoNewline -ForegroundColor Green
if ($TotalWarn -gt 0) {
    Write-Host "Warnings: $TotalWarn" -ForegroundColor Yellow
} else {
    Write-Host "Warnings: 0" -ForegroundColor Green
}

Write-Host "   $ReportLabel : " -NoNewline -ForegroundColor Green
Write-Host "$ReportPath" -ForegroundColor Yellow
Write-Host ("-" * $TermWidth) -ForegroundColor Green
Write-Host ""
Write-Host "   $PressKeyLabel" -ForegroundColor Yellow
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
[Environment]::Exit(0)
