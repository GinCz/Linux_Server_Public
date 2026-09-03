<?php
// Gin IT - IP & 3x Speed Test v8 (Ultra-Compact, Top 5mm, Multi-Source Geo, Clean Report)
header('Content-Type: text/html; charset=utf-8');

function getClientIP() {
    $keys = ['HTTP_CF_CONNECTING_IP', 'HTTP_X_REAL_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR'];
    foreach ($keys as $k) {
        if (!empty($_SERVER[$k])) {
            $p = explode(',', $_SERVER[$k]);
            $ip = trim($p[0]);
            if (filter_var($ip, FILTER_VALIDATE_IP)) return $ip;
        }
    }
    return $_SERVER['REMOTE_ADDR'] ?? '127.0.0.1';
}
$clientIP = getClientIP();

$cacheDir = __DIR__ . '/cache';
if (!is_dir($cacheDir)) @mkdir($cacheDir, 0755, true);

// 20-Second Rate Limiting for Speed Test
$COOLDOWN_SECONDS = 20;
$rateFile = $cacheDir . '/rate_' . md5($clientIP) . '.json';
$rateData = ['last_complete' => 0, 'count' => 0, 'window_start' => 0];
if (file_exists($rateFile)) {
    $r = @json_decode(file_get_contents($rateFile), true);
    if (is_array($r)) $rateData = array_merge($rateData, $r);
}

$now = time();
$cooldownRemaining = max(0, $COOLDOWN_SECONDS - ($now - ($rateData['last_complete'] ?? 0)));

$host = $_SERVER['HTTP_HOST'] ?? 'eco-seo.cz';
$isEcoSeo = (stripos($host, 'eco-seo') !== false);
$serverName = $isEcoSeo ? '🇩🇪 Германия (NetCup)' : '🇷🇺 Россия (Москва)';
$siteUrl = ($isEcoSeo ? 'https://' : 'http://') . ($host ?: 'eco-seo.cz') . '/';
$hostDisplay = $host ?: ($isEcoSeo ? 'eco-seo.cz' : 'prodvig-saita.ru');

$action = $_GET['action'] ?? '';

if ($action === 'ping') {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'ok']);
    exit;
}

if ($action === 'check_cooldown') {
    header('Content-Type: application/json');
    echo json_encode(['cooldown' => $cooldownRemaining]);
    exit;
}

if ($action === 'complete') {
    header('Content-Type: application/json');
    $rateData['last_complete'] = $now;
    $rateData['count'] = 0;
    @file_put_contents($rateFile, json_encode($rateData));
    echo json_encode(['status' => 'ok', 'cooldown' => $COOLDOWN_SECONDS]);
    exit;
}

if ($action === 'download' || $action === 'upload') {
    if ($cooldownRemaining > 0) {
        http_response_code(429);
        header('Content-Type: application/json');
        header('Retry-After: ' . $cooldownRemaining);
        echo json_encode(['error' => 'Rate limit exceeded. Cooldown: ' . $cooldownRemaining . 's']);
        exit;
    }
    
    if ($now - $rateData['window_start'] > 60) {
        $rateData['window_start'] = $now;
        $rateData['count'] = 1;
    } else {
        $rateData['count']++;
        if ($rateData['count'] > 8) {
            $rateData['last_complete'] = $now;
            @file_put_contents($rateFile, json_encode($rateData));
            http_response_code(429);
            header('Content-Type: application/json');
            header('Retry-After: ' . $COOLDOWN_SECONDS);
            echo json_encode(['error' => 'Rate limit exceeded. Cooldown started.']);
            exit;
        }
    }
    @file_put_contents($rateFile, json_encode($rateData));
}

if ($action === 'download') {
    header('Content-Type: application/octet-stream');
    header('Cache-Control: no-cache, no-store, must-revalidate');
    $chunk = str_repeat("0123456789abcdef", 4096); // 64 KB
    for ($i = 0; $i < 192; $i++) {
        echo $chunk;
        if (connection_status() != 0) break;
    }
    exit;
}

if ($action === 'upload') {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'ok', 'size' => strlen(file_get_contents('php://input'))]);
    exit;
}

// Robust Multi-Source Geo Resolver
function fetchGeoMultiSource($ip) {
    if (empty($ip) || $ip === '127.0.0.1') return null;
    
    // 1. ip-api.com
    if (function_exists('curl_init')) {
        $ch = curl_init("http://ip-api.com/json/{$ip}?fields=status,country,countryCode,regionName,city,isp,org,as&lang=ru");
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 3,
            CURLOPT_USERAGENT => 'Mozilla/5.0'
        ]);
        $raw = curl_exec($ch);
        curl_close($ch);
        if ($raw) {
            $d = json_decode($raw, true);
            if (($d['status'] ?? '') === 'success' && !empty($d['country'])) {
                return [
                    'country' => $d['country'],
                    'countryCode' => $d['countryCode'] ?? '',
                    'city' => $d['city'] ?? '',
                    'region' => $d['regionName'] ?? '',
                    'isp' => $d['isp'] ?? ($d['org'] ?? 'Провайдер сети')
                ];
            }
        }
    }
    
    // 2. SypexGeo (High reliability for RU / Moscow / CIS)
    if (function_exists('curl_init')) {
        $ch = curl_init("http://api.sypexgeo.net/json/{$ip}");
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 3,
            CURLOPT_USERAGENT => 'Mozilla/5.0'
        ]);
        $raw = curl_exec($ch);
        curl_close($ch);
        if ($raw) {
            $d = json_decode($raw, true);
            if (!empty($d['country']['name_ru'])) {
                return [
                    'country' => $d['country']['name_ru'],
                    'countryCode' => $d['country']['iso'] ?? 'RU',
                    'city' => $d['city']['name_ru'] ?? ($d['city']['name_en'] ?? ''),
                    'region' => $d['region']['name_ru'] ?? '',
                    'isp' => 'Интернет-провайдер'
                ];
            }
        }
    }
    
    // 3. ipwho.is
    if (function_exists('curl_init')) {
        $ch = curl_init("https://ipwho.is/{$ip}?lang=ru");
        curl_setopt_array($ch, [
            CURLOPT_RETURNTRANSFER => true,
            CURLOPT_TIMEOUT => 3,
            CURLOPT_USERAGENT => 'Mozilla/5.0'
        ]);
        $raw = curl_exec($ch);
        curl_close($ch);
        if ($raw) {
            $d = json_decode($raw, true);
            if (!empty($d['success']) && !empty($d['country'])) {
                return [
                    'country' => $d['country'],
                    'countryCode' => $d['country_code'] ?? '',
                    'city' => $d['city'] ?? '',
                    'region' => $d['region'] ?? '',
                    'isp' => $d['connection']['isp'] ?? ($d['connection']['org'] ?? 'Провайдер сети')
                ];
            }
        }
    }
    
    return null;
}

$cacheFile = $cacheDir . '/' . md5($clientIP) . '.json';
$geo = null;

if (file_exists($cacheFile) && (time() - filemtime($cacheFile) < 86400)) {
    $geo = json_decode(file_get_contents($cacheFile), true);
    if (empty($geo['country']) || $geo['country'] === 'Resolving...') {
        $geo = null; // Invalidate broken cache
    }
}

if (!$geo) {
    $geo = fetchGeoMultiSource($clientIP);
    if ($geo) {
        @file_put_contents($cacheFile, json_encode($geo));
    }
}

if (!$geo) {
    $geo = ['country' => 'Resolving...', 'countryCode' => '', 'city' => 'Resolving...', 'region' => '', 'isp' => 'Resolving...'];
}

if ($action === 'geo') {
    header('Content-Type: application/json');
    echo json_encode($geo);
    exit;
}
?>
<!DOCTYPE html>
<html lang="ru">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gin IT — IP & Speed Test</title>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@500;600;700;800&family=Inter:wght@400;500;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: 'Inter', -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
            background: #090d13;
            color: #f0f6fc;
            min-height: 100vh;
            display: flex;
            align-items: flex-start;
            justify-content: center;
            padding: 8px 10px 14px; /* Ровно 5 мм (~1 строчка) сверху! */
        }
        .card {
            max-width: 520px;
            width: 100%;
            background: #131923;
            border: 1px solid #232d3d;
            border-radius: 14px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.6);
            overflow: hidden;
        }
        
        /* Начало карточки прямо с блока IP (шапка полностью удалена) */
        .hero {
            padding: 12px 16px 8px;
            text-align: center;
            background: radial-gradient(circle, rgba(56,139,253,0.1) 0%, transparent 70%);
        }
        .hero-lbl {
            font-size: 0.72rem;
            text-transform: uppercase;
            color: #8b9bb0;
            letter-spacing: 1.2px;
            font-weight: 700;
            margin-bottom: 5px;
        }
        .ip-box {
            font-family: 'JetBrains Mono', monospace;
            font-size: clamp(1.4rem, 4vw, 1.95rem);
            font-weight: 800;
            color: #58a6ff;
            cursor: pointer;
            display: inline-flex;
            align-items: center;
            gap: 8px;
            padding: 4px 14px;
            border-radius: 10px;
            background: rgba(56,139,253,0.08);
            border: 1px dashed rgba(56,139,253,0.4);
            transition: 0.2s;
            max-width: 95%;
            word-break: break-all;
        }
        .ip-box.is-ipv6 {
            font-size: clamp(0.85rem, 2.5vw, 1.15rem);
            letter-spacing: -0.5px;
        }
        .ip-box:hover {
            background: rgba(56,139,253,0.18);
            border-color: #388bfd;
            transform: scale(1.01);
        }
        
        .rows { padding: 4px 18px 6px; }
        .row {
            display: flex;
            justify-content: space-between;
            align-items: center;
            padding: 5px 0;
            border-bottom: 1px solid rgba(35,45,61,0.7);
        }
        .row:last-child { border-bottom: none; }
        .r-lbl { color: #8b9bb0; font-size: 0.88rem; font-weight: 500; }
        .r-val { font-weight: 700; font-size: 0.92rem; text-align: right; max-width: 65%; color: #fff; }
        
        /* 3x Speed Box - Компактная высота */
        .speed-box {
            margin: 0 14px 8px;
            padding: 10px 14px 10px;
            background: rgba(9,13,19,0.7);
            border: 1px solid #232d3d;
            border-radius: 12px;
            text-align: center;
        }
        .speed-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 6px;
        }
        .speed-title-col { text-align: left; }
        .speed-title-main {
            font-size: 0.82rem;
            font-weight: 800;
            text-transform: uppercase;
            letter-spacing: 0.8px;
            color: #58a6ff;
            line-height: 1.1;
        }
        .server-info {
            font-size: 0.72rem;
            color: #8b9bb0;
            font-weight: 600;
            margin-top: 2px;
        }
        
        .cycle-badge {
            background: rgba(56,139,253,0.15);
            color: #58a6ff;
            border: 1px solid rgba(56,139,253,0.3);
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 0.72rem;
            font-weight: 700;
            transition: 0.3s;
        }
        .cycle-badge.badge-cooldown {
            background: rgba(210,153,34,0.15);
            color: #d29922;
            border-color: rgba(210,153,34,0.4);
        }
        
        .speed-table {
            width: 100%;
            border-collapse: collapse;
            font-size: 0.86rem;
            margin-bottom: 6px;
        }
        .speed-table th {
            font-size: 0.68rem;
            text-transform: uppercase;
            letter-spacing: 0.6px;
            color: #8b9bb0;
            font-weight: 700;
            padding: 4px 6px;
            border-bottom: 1px solid #232d3d;
        }
        .speed-table th:first-child { text-align: left; padding-left: 6px; }
        .speed-table th:nth-child(2) { text-align: center; }
        .speed-table th:nth-child(3), .speed-table th:nth-child(4) { text-align: right; padding-right: 6px; }
        .th-unit { font-size: 0.62rem; color: #58697f; font-weight: 600; }
        
        .speed-table td {
            padding: 4px 6px;
            font-family: 'JetBrains Mono', monospace;
            border-bottom: 1px solid rgba(35,45,61,0.5);
            transition: background 0.2s;
        }
        .speed-table td:first-child { text-align: left; font-family: 'Inter', sans-serif; font-weight: 700; padding-left: 6px; font-size: 0.8rem; }
        .speed-table td:nth-child(2) { text-align: center; }
        .speed-table td:nth-child(3), .speed-table td:nth-child(4) { text-align: right; padding-right: 6px; font-weight: 700; }
        
        .c-cycle { color: #8b9bb0; }
        .c-down { color: #3fb950; }
        .c-up { color: #bc8cff; }
        
        .row-active {
            background: rgba(56,139,253,0.12) !important;
        }
        .row-active .c-cycle {
            color: #58a6ff !important;
            font-weight: 800;
        }
        
        .row-avg {
            background: rgba(22,27,34,0.8);
            border-top: 1px solid #303e54;
        }
        .row-avg td {
            padding: 5px 6px;
            border-bottom: none;
            font-size: 0.9rem;
        }
        .c-avg-lbl {
            color: #58a6ff !important;
            font-size: 0.8rem !important;
            letter-spacing: 0.5px;
            text-transform: uppercase;
        }
        
        .progress-text {
            font-size: 0.76rem;
            color: #3fb950;
            font-weight: 600;
            min-height: 16px;
            margin-bottom: 6px;
        }
        
        .speed-actions {
            display: flex;
            gap: 8px;
            justify-content: center;
            align-items: center;
            flex-wrap: wrap;
        }
        .btn-speed {
            background: linear-gradient(135deg, #1f6feb, #238636);
            color: #fff;
            border: none;
            padding: 7px 20px;
            font-size: 0.86rem;
            font-weight: 700;
            border-radius: 16px;
            cursor: pointer;
            transition: 0.2s;
            box-shadow: 0 3px 10px rgba(31,111,235,0.3);
        }
        .btn-speed:hover { opacity: 0.95; transform: scale(1.02); }
        .btn-speed:disabled {
            background: #1c2433;
            color: #6e7681;
            cursor: not-allowed;
            transform: none;
            box-shadow: none;
            border: 1px solid #2d3848;
        }
        
        .btn-copy {
            background: #21262d;
            color: #58a6ff;
            border: 1px solid #30363d;
            padding: 7px 16px;
            font-size: 0.86rem;
            font-weight: 700;
            border-radius: 16px;
            cursor: pointer;
            transition: 0.2s;
            box-shadow: 0 3px 10px rgba(0,0,0,0.3);
            display: inline-flex;
            align-items: center;
            gap: 5px;
        }
        .btn-copy:hover {
            background: #30363d;
            color: #fff;
            border-color: #58a6ff;
            transform: scale(1.02);
        }
        
        .footer {
            padding: 8px 16px;
            background: rgba(9,13,19,0.8);
            border-top: 1px solid #232d3d;
            text-align: center;
            font-size: 0.88rem;
        }
        .footer a { color: #58a6ff; text-decoration: none; font-weight: 700; }
        .footer a:hover { text-decoration: underline; }
        
        .toast {
            position: fixed;
            bottom: 20px;
            background: #238636;
            color: #fff;
            padding: 9px 18px;
            border-radius: 8px;
            font-weight: 700;
            box-shadow: 0 6px 20px rgba(0,0,0,0.5);
            opacity: 0;
            transition: 0.2s;
            pointer-events: none;
            font-size: 0.86rem;
            z-index: 999;
        }
        .toast.show { opacity: 1; }
    </style>
</head>
<body>
<div class="card">
    <div class="hero">
        <div class="hero-lbl">YOUR PUBLIC IP ADDRESS</div>
        <div class="ip-box <?= strpos($clientIP, ':') !== false ? 'is-ipv6' : '' ?>" id="ipValBox" onclick="copyIP()" title="Click to copy">
            <span id="ipVal"><?= htmlspecialchars($clientIP) ?></span> <span style="font-size:1rem;opacity:0.7">📋</span>
        </div>
    </div>
    
    <div class="rows">
        <div class="row" id="ipv6Row" style="display: none;"><div class="r-lbl">IPv6</div><div class="r-val" id="ipv6Val" style="font-family:'JetBrains Mono',monospace;font-size:0.78rem;word-break:break-all;"></div></div>
        <div class="row"><div class="r-lbl">Country</div><div class="r-val" id="countryVal"><?= htmlspecialchars($geo['country']) ?></div></div>
        <div class="row"><div class="r-lbl">City / Region</div><div class="r-val" id="cityVal"><?= htmlspecialchars($geo['city']) ?><?= !empty($geo['region']) && $geo['region'] !== $geo['city'] ? ', ' . htmlspecialchars($geo['region']) : '' ?></div></div>
        <div class="row"><div class="r-lbl">ISP / Carrier</div><div class="r-val" id="ispVal" style="font-family:'JetBrains Mono',monospace;font-size:0.86rem;"><?= htmlspecialchars($geo['isp']) ?></div></div>
    </div>
    
    <!-- 3x Speed Test Table -->
    <div class="speed-box">
        <div class="speed-header">
            <div class="speed-title-col">
                <div class="speed-title-main">Speed Test ×3</div>
                <div class="server-info">Сервер: <?= htmlspecialchars($serverName) ?></div>
            </div>
            <div class="cycle-badge" id="cycleBadge">Ready</div>
        </div>
        
        <table class="speed-table">
            <thead>
                <tr>
                    <th>Test</th>
                    <th>Ping <span class="th-unit">ms</span></th>
                    <th>Download <span class="th-unit">Mbps</span></th>
                    <th>Upload <span class="th-unit">Mbps</span></th>
                </tr>
            </thead>
            <tbody>
                <tr id="row1">
                    <td class="c-cycle" id="cycleName1">#1 Test</td>
                    <td id="ping1">--</td>
                    <td class="c-down" id="down1">--</td>
                    <td class="c-up" id="up1">--</td>
                </tr>
                <tr id="row2">
                    <td class="c-cycle" id="cycleName2">#2 Test</td>
                    <td id="ping2">--</td>
                    <td class="c-down" id="down2">--</td>
                    <td class="c-up" id="up2">--</td>
                </tr>
                <tr id="row3">
                    <td class="c-cycle" id="cycleName3">#3 Test</td>
                    <td id="ping3">--</td>
                    <td class="c-down" id="down3">--</td>
                    <td class="c-up" id="up3">--</td>
                </tr>
                <tr id="rowAvg" class="row-avg">
                    <td class="c-avg-lbl">Avg ★</td>
                    <td id="pingAvg" style="font-weight:700;">--</td>
                    <td class="c-down" id="downAvg">--</td>
                    <td class="c-up" id="upAvg">--</td>
                </tr>
            </tbody>
        </table>
        
        <div class="progress-text" id="progText">Click below to start 3x comprehensive test</div>
        
        <div class="speed-actions">
            <button class="btn-speed" id="btnTest" onclick="start3xSpeedTest()">⚡ Run Speed Test ×3</button>
            <button class="btn-copy" id="btnCopy" onclick="copyResults()" style="display: none;">📋 Скопировать в буфер</button>
        </div>
    </div>
    
    <div class="footer">
        <a href="<?= htmlspecialchars($siteUrl) ?>"><?= htmlspecialchars($hostDisplay) ?> ↗</a>
    </div>
</div>

<div class="toast" id="toast">IP copied to clipboard!</div>

<script>
let serverCooldown = <?= (int)$cooldownRemaining ?>;
let lastResults = null;
const SERVER_NAME = <?= json_encode($serverName) ?>;

function showToast(msg) {
    const t = document.getElementById('toast');
    t.innerText = msg;
    t.classList.add('show');
    setTimeout(() => {
        t.classList.remove('show');
    }, 2200);
}

function copyIP(){
    navigator.clipboard.writeText(document.getElementById('ipVal').innerText.trim()).then(()=>{
        showToast('IP copied to clipboard!');
    });
}

function copyResults(){
    if (!lastResults) return;
    const ip = document.getElementById('ipVal').innerText.trim();
    const country = document.getElementById('countryVal').innerText.trim();
    const city = document.getElementById('cityVal').innerText.trim();
    const isp = document.getElementById('ispVal').innerText.trim();
    
    let locStr = country;
    if (city && !city.includes('Resolving') && !country.includes(city)) {
        locStr = `${country}, ${city}`;
    }
    
    const text = 
`🛡️ Gin IT — Speed Test ×3
📍 Сервер: ${SERVER_NAME}
🌐 ${ip} (${locStr})
🏢 ${isp}
⚡ ${lastResults.avgPing} ms
⬇️ ${lastResults.avgDown} Mbps
⬆️ ${lastResults.avgUp} Mbps`;

    navigator.clipboard.writeText(text).then(()=>{
        showToast('📋 Отчёт скопирован в буфер!');
    });
}

// Multi-Source Client-Side Geo Fallback via backend endpoint
(function ensureGeoResolved(){
    const ipEl = document.getElementById('ipVal');
    const ipVal = ipEl ? ipEl.innerText.trim() : '';
    
    // If connected via IPv6, automatically resolve and prioritize IPv4
    if (ipVal.includes(':')) {
        fetch('https://api4.ipify.org?format=json')
            .then(r => r.json())
            .then(d => {
                if (d && d.ip && !d.ip.includes(':')) {
                    const ipv6Original = ipEl.innerText.trim();
                    ipEl.innerText = d.ip;
                    const box = document.getElementById('ipValBox');
                    if (box) box.classList.remove('is-ipv6');
                    const row = document.getElementById('ipv6Row');
                    const val = document.getElementById('ipv6Val');
                    if (row && val) {
                        val.innerText = ipv6Original;
                        row.style.display = 'flex';
                    }
                }
            }).catch(()=>{});
    }

    const c = document.getElementById('countryVal').innerText;
    if (!c || c.includes('Resolving') || c.includes('Unknown') || c.includes('Определяется')) {
        fetch('?action=geo&nc=' + Math.random())
            .then(r => r.json())
            .then(d => {
                if (d && d.country && !d.country.includes('Resolving')) {
                    document.getElementById('countryVal').innerText = d.country;
                    document.getElementById('cityVal').innerText = d.city + (d.region && d.region !== d.city ? ', ' + d.region : '');
                    document.getElementById('ispVal').innerText = d.isp || 'Интернет-провайдер';
                }
            }).catch(()=>{});
    }
})();

function sleep(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }

async function startCooldownTimer(seconds) {
    const btn = document.getElementById('btnTest');
    const badge = document.getElementById('cycleBadge');
    const prog = document.getElementById('progText');
    
    btn.disabled = true;
    badge.classList.add('badge-cooldown');
    
    for (let s = seconds; s > 0; s--) {
        badge.innerText = `Cooldown ${s}s`;
        btn.innerText = `⏳ Cooldown (${s}s)`;
        prog.innerText = `🛡️ Anti-flood cooldown: wait ${s}s before next test...`;
        prog.style.color = '#d29922';
        await sleep(1000);
    }
    
    badge.classList.remove('badge-cooldown');
    badge.innerText = 'Ready';
    prog.innerText = '✅ Ready for next test run.';
    prog.style.color = '#3fb950';
    btn.innerText = '⚡ Test Again (3x)';
    btn.disabled = false;
}

if (serverCooldown > 0) {
    startCooldownTimer(serverCooldown);
}

async function runSingleCycle(cycleNum) {
    const prog = document.getElementById('progText');
    const pingEl = document.getElementById('ping' + cycleNum);
    const downEl = document.getElementById('down' + cycleNum);
    const upEl = document.getElementById('up' + cycleNum);
    const rowEl = document.getElementById('row' + cycleNum);
    
    rowEl.classList.add('row-active');
    
    // 1. Ping
    prog.innerText = `[Cycle ${cycleNum}/3] Measuring latency...`;
    let pings = [];
    for (let i = 0; i < 4; i++) {
        const t0 = performance.now();
        const r = await fetch('?action=ping&nc=' + Math.random());
        if (r.status === 429) throw new Error('Rate limit');
        pings.push(performance.now() - t0);
    }
    const cyclePing = Math.round(pings.reduce((a, b) => a + b, 0) / pings.length);
    pingEl.innerText = cyclePing;
    
    // 2. Download (12 MB stream, ~4-5s)
    prog.innerText = `[Cycle ${cycleNum}/3] Testing Download (12 MB)...`;
    const tDown0 = performance.now();
    const resp = await fetch('?action=download&nc=' + Math.random());
    if (resp.status === 429) throw new Error('Rate limit');
    const blob = await resp.blob();
    const durDown = (performance.now() - tDown0) / 1000;
    const cycleDown = parseFloat(((blob.size * 8) / (durDown * 1000000)).toFixed(1));
    downEl.innerText = cycleDown;
    
    // 3. Upload (3 MB payload, ~3-4s)
    prog.innerText = `[Cycle ${cycleNum}/3] Testing Upload (3 MB)...`;
    const upData = new Uint8Array(3 * 1024 * 1024);
    const tUp0 = performance.now();
    const respUp = await fetch('?action=upload&nc=' + Math.random(), { method: 'POST', body: upData });
    if (respUp.status === 429) throw new Error('Rate limit');
    const durUp = (performance.now() - tUp0) / 1000;
    const cycleUp = parseFloat(((upData.length * 8) / (durUp * 1000000)).toFixed(1));
    upEl.innerText = cycleUp;
    
    rowEl.classList.remove('row-active');
    
    return { ping: cyclePing, download: cycleDown, upload: cycleUp };
}

async function start3xSpeedTest() {
    const btn = document.getElementById('btnTest');
    const btnCopy = document.getElementById('btnCopy');
    const badge = document.getElementById('cycleBadge');
    const prog = document.getElementById('progText');
    
    try {
        const chk = await fetch('?action=check_cooldown&nc=' + Math.random());
        const chkData = await chk.json();
        if (chkData.cooldown > 0) {
            startCooldownTimer(chkData.cooldown);
            return;
        }
    } catch(e){}
    
    btn.disabled = true;
    prog.style.color = '#3fb950';
    
    // Reset table
    for (let i = 1; i <= 3; i++) {
        document.getElementById('ping' + i).innerText = '--';
        document.getElementById('down' + i).innerText = '--';
        document.getElementById('up' + i).innerText = '--';
        document.getElementById('row' + i).classList.remove('row-active');
    }
    document.getElementById('pingAvg').innerText = '--';
    document.getElementById('downAvg').innerText = '--';
    document.getElementById('upAvg').innerText = '--';
    
    let results = [];
    
    try {
        for (let c = 1; c <= 3; c++) {
            badge.innerText = `Cycle ${c} of 3`;
            const res = await runSingleCycle(c);
            results.push(res);
            
            if (c < 3) {
                badge.innerText = `Pause 3s`;
                for (let s = 3; s > 0; s--) {
                    prog.innerText = `Test #${c} saved! Next test in ${s}s...`;
                    await sleep(1000);
                }
            }
        }
        
        // Final Average
        const avgPing = Math.round(results.reduce((a, b) => a + b.ping, 0) / 3);
        const avgDown = (results.reduce((a, b) => a + b.download, 0) / 3).toFixed(1);
        const avgUp = (results.reduce((a, b) => a + b.upload, 0) / 3).toFixed(1);
        
        document.getElementById('pingAvg').innerText = avgPing;
        document.getElementById('downAvg').innerText = avgDown;
        document.getElementById('upAvg').innerText = avgUp;
        
        // Save results & enable Copy button immediately
        lastResults = {
            avgPing: avgPing,
            avgDown: avgDown,
            avgUp: avgUp,
            results: results
        };
        btnCopy.style.display = 'inline-flex';
        
        // Notify server test finished and start 20s cooldown
        await fetch('?action=complete&nc=' + Math.random());
        await startCooldownTimer(20);
        
    } catch(err) {
        prog.innerText = '⚠️ Test rate limit reached. Please wait.';
        prog.style.color = '#d29922';
        startCooldownTimer(20);
    }
}
</script>
</body>
</html>
