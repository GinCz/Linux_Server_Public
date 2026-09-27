# =============================================================================
# Execution Context : PowerShell on the authorized administration workstation
# Target Servers    : DE-222 and RU-109
# Description       : Deploy the shared IP Speed Test and install self-healing guards
# =============================================================================
[CmdletBinding()]
param(
    [ValidateSet('all', 'de', 'ru')]
    [string]$Target = 'all'
)

$ErrorActionPreference = 'Stop'
try {
    Clear-Host
} catch {
    Write-Verbose "Console clear is unavailable in this execution host: $($_.Exception.Message)"
}

function Invoke-NativeWithRetry {
    param(
        [Parameter(Mandatory)]
        [scriptblock]$Operation,

        [Parameter(Mandatory)]
        [string]$Description,

        [int]$Attempts = 3
    )

    for ($attempt = 1; $attempt -le $Attempts; $attempt++) {
        & $Operation
        if ($LASTEXITCODE -eq 0) {
            return
        }

        if ($attempt -lt $Attempts) {
            Write-Warning "$Description failed on attempt $attempt of $Attempts; retrying in 5 seconds."
            Start-Sleep -Seconds 5
        }
    }

    throw "$Description failed after $Attempts attempts."
}

$projectDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$opsDir = Join-Path $projectDir 'ops'
$sourceFile = Join-Path $projectDir 'index.php'
$requiredFiles = @(
    $sourceFile,
    (Join-Path $opsDir 'gin-ip-speedtest-guard.sh'),
    (Join-Path $opsDir 'test-guard.sh'),
    (Join-Path $opsDir 'gin-ip-speedtest-guard.service'),
    (Join-Path $opsDir 'gin-ip-speedtest-guard.timer'),
    (Join-Path $opsDir 'install-guard.sh')
)

foreach ($requiredFile in $requiredFiles) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required project file is missing: $requiredFile"
    }
}

$targets = @(
    [pscustomobject]@{
        Key = 'de'
        Name = 'DE-222'
        Host = '152.53.182.222'
        Domain = 'eco-seo.cz'
        WebRoot = '/var/www/gincz/data/www/eco-seo.cz'
        Owner = 'gincz'
        Group = 'gincz'
        ProxyJump = $null
    },
    [pscustomobject]@{
        Key = 'ru'
        Name = 'RU-109'
        Host = '212.109.223.109'
        Domain = 'prodvig-saita.ru'
        WebRoot = '/var/www/gincz/data/www/prodvig-saita.ru'
        Owner = 'gincz'
        Group = 'gincz'
        ProxyJump = 'root@152.53.182.222'
    }
)

if ($Target -ne 'all') {
    $targets = $targets | Where-Object Key -eq $Target
}

$expectedHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $sourceFile).Hash.ToLowerInvariant()
Write-Host "Canonical SHA-256: $expectedHash"

foreach ($targetItem in $targets) {
    $stageDir = "/tmp/gin-ip-speedtest-deploy-$([DateTimeOffset]::UtcNow.ToUnixTimeSeconds())"
    $remote = "root@$($targetItem.Host)"
    $connectionOptions = @('-o', 'BatchMode=yes', '-o', 'ConnectTimeout=25')
    if ($targetItem.ProxyJump) {
        $connectionOptions += @('-o', "ProxyJump=$($targetItem.ProxyJump)")
    }
    Write-Host "Deploying to $($targetItem.Name) ($($targetItem.Domain))..."

    Invoke-NativeWithRetry -Description "Create staging directory on $($targetItem.Name)" -Operation {
        & ssh @connectionOptions $remote "mkdir -p '$stageDir'"
    }

    Invoke-NativeWithRetry -Description "Upload project files to $($targetItem.Name)" -Operation {
        & scp -q @connectionOptions -- @requiredFiles "${remote}:${stageDir}/"
    }

    $installCommand = "bash '$stageDir/install-guard.sh' '$($targetItem.Domain)' '$($targetItem.WebRoot)' '$($targetItem.Owner)' '$($targetItem.Group)'; rm -rf '$stageDir'"
    Invoke-NativeWithRetry -Description "Install guard on $($targetItem.Name)" -Operation {
        & ssh @connectionOptions $remote $installCommand
    }

    $publicUrl = "https://$($targetItem.Domain)/ip/"
    $httpCode = & curl.exe -sS -L --retry 2 --retry-all-errors --retry-delay 3 --connect-timeout 10 --max-time 30 -o NUL -w '%{http_code}' $publicUrl
    if ($LASTEXITCODE -ne 0 -or $httpCode -ne '200') {
        throw "Public verification failed for $publicUrl with HTTP $httpCode"
    }

    $pingBody = & curl.exe -sS --retry 2 --retry-all-errors --retry-delay 3 --connect-timeout 10 --max-time 20 "${publicUrl}?action=ping"
    if ($LASTEXITCODE -ne 0 -or $pingBody -notmatch '"status":"ok"') {
        throw "Ping API verification failed for $publicUrl"
    }

    Write-Host "OK: $($targetItem.Domain) HTTP 200, ping API OK"
}

Write-Host 'Deployment and guard installation completed successfully.'
