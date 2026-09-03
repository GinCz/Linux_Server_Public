<?php
// Gin IT - IP & 3x Speed Test
header('Content-Type: text/html; charset=utf-8');

$action = $_GET['action'] ?? '';
if ($action === 'ping') {
    header('Content-Type: application/json');
    echo json_encode(['status' => 'ok']);
    exit;
}
if ($action === 'download') {
    header('Content-Type: application/octet-stream');
    header('Cache-Control: no-cache, no-store, must-revalidate');
    // Generate ~12 MB stream for robust 5-8 second download test
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
$cacheFile = $cacheDir . '/' . md5($clientIP) . '.json';
$geo = null;

if (file_exists($cacheFile) && (time() - filemtime($cacheFile) < 86400)) {
    $geo = json_decode(file_get_contents($cacheFile), true);
}

if (!$geo) {
    $ctx = stream_context_create(['http' => ['timeout' => 2, 'header' => "User-Agent: Mozilla/5.0\r\n"]]);
    $raw = @file_get_contents("http://ip-api.com/json/{$clientIP}?fields=status,country,countryCode,regionName,city,isp,org,as", false, $ctx);
    if ($raw) {
        $d = json_decode($raw, true);
        if (($d['status'] ?? '') === 'success') {
            $geo = [
                'country' => $d['country'] ?? 'Resolving...',
                'countryCode' => $d['countryCode'] ?? '',
                'city' => $d['city'] ?? 'Unknown',
                'region' => $d['regionName'] ?? '',
                'isp' => $d['isp'] ?? ($d['org'] ?? 'Internet Service Provider')
            ];
            @file_put_contents($cacheFile, json_encode($geo));
        }
    }
}
if (!$geo) {
    $geo = ['country' => 'Resolving...', 'countryCode' => '', 'city' => 'Resolving...', 'region' => '', 'isp' => 'Resolving...'];
}

function codeToFlag($code) {
    if (empty($code) || strlen($code) !== 2) return '🌐';
    $code = strtoupper($code);
    $f = 127397 + ord($code[0]);
    $s = 127397 + ord($code[1]);
    return mb_convert_encoding('&#' . $f . ';', 'UTF-8', 'HTML-ENTITIES') . mb_convert_encoding('&#' . $s . ';', 'UTF-8', 'HTML-ENTITIES');
}
$flag = codeToFlag($geo['countryCode'] ?? '');
?>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Gin IT — IP & Speed Test</title>
    <link href="https://fonts.googleapis.com/css2?family=JetBrains+Mono:wght@500;700;800&family=Inter:wght@400;600;700;800&display=swap" rel="stylesheet">
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: 'Inter', sans-serif; background: #090d13; color: #f0f6fc; min-height: 100vh; display: flex; align-items: center; justify-content: center; padding: 20px; }
        .card { max-width: 580px; width: 100%; background: #131923; border: 1px solid #232d3d; border-radius: 20px; box-shadow: 0 20px 50px rgba(0,0,0,0.6); overflow: hidden; }
        .header { padding: 20px 26px; border-bottom: 1px solid #232d3d; display: flex; justify-content: center; align-items: center; font-weight: 800; font-size: 1.3rem; }
        .brand { display: flex; align-items: center; gap: 10px; }
        .hero { padding: 36px 20px 28px; text-align: center; background: radial-gradient(circle, rgba(56,139,253,0.12) 0%, transparent 70%); }
        .hero-lbl { font-size: 0.9rem; text-transform: uppercase; color: #8b9bb0; letter-spacing: 1.5px; font-weight: 700; margin-bottom: 12px; }
        .ip-box { font-family: 'JetBrains Mono', monospace; font-size: 2.9rem; font-weight: 800; color: #58a6ff; cursor: pointer; display: inline-flex; align-items: center; gap: 14px; padding: 10px 24px; border-radius: 14px; background: rgba(56,139,253,0.08); border: 1px dashed rgba(56,139,253,0.4); transition: 0.2s; }
        .ip-box:hover { background: rgba(56,139,253,0.18); border-color: #388bfd; transform: scale(1.02); }
        .rows { padding: 8px 26px 20px; }
        .row { display: flex; justify-content: space-between; align-items: center; padding: 16px 0; border-bottom: 1px solid rgba(35,45,61,0.8); }
        .row:last-child { border-bottom: none; }
        .r-lbl { color: #8b9bb0; font-size: 1.05rem; font-weight: 500; }
        .r-val { font-weight: 700; font-size: 1.15rem; text-align: right; max-width: 65%; color: #fff; }
        
        /* 3x Speed Box */
        .speed-box { margin: 0 26px 24px; padding: 20px; background: rgba(9,13,19,0.7); border: 1px solid #232d3d; border-radius: 16px; text-align: center; }
        .speed-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 16px; }
        .speed-title-main { font-size: 0.95rem; font-weight: 800; text-transform: uppercase; letter-spacing: 1px; color: #58a6ff; }
        .cycle-badge { background: rgba(56,139,253,0.15); color: #58a6ff; border: 1px solid rgba(56,139,253,0.3); padding: 4px 12px; border-radius: 20px; font-size: 0.8rem; font-weight: 700; }
        .speed-grid { display: grid; grid-template-columns: 1fr 1fr 1fr; gap: 10px; margin-bottom: 16px; }
        .speed-cell { background: #131923; padding: 14px 6px; border-radius: 12px; border: 1px solid #232d3d; }
        .speed-title { font-size: 0.8rem; text-transform: uppercase; color: #8b9bb0; font-weight: 600; margin-bottom: 4px; }
        .speed-num { font-family: 'JetBrains Mono', monospace; font-size: 1.6rem; font-weight: 800; color: #fff; }
        .speed-unit { font-size: 0.75rem; color: #8b9bb0; }
        
        .progress-text { font-size: 0.9rem; color: #3fb950; font-weight: 600; min-height: 22px; margin-bottom: 14px; }
        .btn-speed { background: linear-gradient(135deg, #1f6feb, #238636); color: #fff; border: none; padding: 13px 32px; font-size: 1.05rem; font-weight: 700; border-radius: 25px; cursor: pointer; transition: 0.2s; box-shadow: 0 4px 15px rgba(31,111,235,0.3); }
        .btn-speed:hover { opacity: 0.95; transform: scale(1.03); }
        .btn-speed:disabled { background: #232d3d; color: #6e7681; cursor: not-allowed; transform: none; box-shadow: none; }
        
        .footer { padding: 16px 26px; background: rgba(9,13,19,0.8); border-top: 1px solid #232d3d; text-align: center; font-size: 1rem; }
        .footer a { color: #58a6ff; text-decoration: none; font-weight: 700; font-size: 1.05rem; }
        .footer a:hover { text-decoration: underline; }
        
        .toast { position: fixed; bottom: 30px; background: #238636; color: #fff; padding: 12px 24px; border-radius: 10px; font-weight: 700; box-shadow: 0 6px 20px rgba(0,0,0,0.5); opacity: 0; transition: 0.2s; pointer-events: none; }
        .toast.show { opacity: 1; }
    </style>
</head>
<body>
<div class="card">
    <div class="header">
        <div class="brand">
            <span style="font-size: 1.5rem;">🛡️</span>
            <span>Gin IT</span>
        </div>
    </div>
    
    <div class="hero">
        <div class="hero-lbl">YOUR PUBLIC IP ADDRESS</div>
        <div class="ip-box" onclick="copyIP()" title="Click to copy">
            <span id="ipVal"><?= htmlspecialchars($clientIP) ?></span> <span style="font-size:1.3rem;opacity:0.7">📋</span>
        </div>
    </div>
    
    <div class="rows">
        <div class="row"><div class="r-lbl">📍 Country</div><div class="r-val" id="countryVal"><?= $flag ?> <?= htmlspecialchars($geo['country']) ?></div></div>
        <div class="row"><div class="r-lbl">🏙️ City / Region</div><div class="r-val" id="cityVal"><?= htmlspecialchars($geo['city']) ?><?= !empty($geo['region']) && $geo['region'] !== $geo['city'] ? ', ' . htmlspecialchars($geo['region']) : '' ?></div></div>
        <div class="row"><div class="r-lbl">🏢 ISP / Carrier</div><div class="r-val" id="ispVal" style="font-family:'JetBrains Mono',monospace;font-size:0.95rem;"><?= htmlspecialchars($geo['isp']) ?></div></div>
    </div>
    
    <!-- 3x Robust Speed Test -->
    <div class="speed-box">
        <div class="speed-header">
            <div class="speed-title-main">Speed Test ×3</div>
            <div class="cycle-badge" id="cycleBadge">Ready</div>
        </div>
        
        <div class="speed-grid">
            <div class="speed-cell"><div class="speed-title">Ping</div><div class="speed-num" id="pingNum">--</div><div class="speed-unit">ms</div></div>
            <div class="speed-cell"><div class="speed-title">Download</div><div class="speed-num" id="downNum" style="color:#3fb950;">--</div><div class="speed-unit">Mbps</div></div>
            <div class="speed-cell"><div class="speed-title">Upload</div><div class="speed-num" id="upNum" style="color:#bc8cff;">--</div><div class="speed-unit">Mbps</div></div>
        </div>
        
        <div class="progress-text" id="progText">Click below to start 3x comprehensive test</div>
        <button class="btn-speed" id="btnTest" onclick="start3xSpeedTest()">⚡ Run Speed Test ×3</button>
    </div>
    
    <div class="footer">
        <a href="http://prodvig-saita.ru/">prodvig-saita.ru ↗</a>
    </div>
</div>

<div class="toast" id="toast">IP copied to clipboard!</div>

<script>
function copyIP(){
    navigator.clipboard.writeText(document.getElementById('ipVal').innerText).then(()=>{
        const t=document.getElementById('toast');
        t.classList.add('show');
        setTimeout(()=>t.classList.remove('show'),2000);
    });
}

(function fallbackGeo(){
    const c=document.getElementById('countryVal').innerText;
    if(c.includes('Resolving') || c.includes('Unknown') || c.includes('Определяется')){
        fetch('https://ipapi.co/json/').then(r=>r.json()).then(d=>{
            if(d.country_name) document.getElementById('countryVal').innerText=(d.country_code?'['+d.country_code+'] ':'')+d.country_name;
            if(d.city) document.getElementById('cityVal').innerText=d.city+(d.region?', '+d.region:'');
            if(d.org) document.getElementById('ispVal').innerText=d.org;
        }).catch(()=>{
            fetch('https://api.ipwho.is/').then(r=>r.json()).then(d=>{
                if(d.country) document.getElementById('countryVal').innerText=d.country;
                if(d.city) document.getElementById('cityVal').innerText=d.city;
                if(d.connection&&d.connection.isp) document.getElementById('ispVal').innerText=d.connection.isp;
            }).catch(()=>{});
        });
    }
})();

function sleep(ms) { return new Promise(resolve => setTimeout(resolve, ms)); }

async function runSingleCycle(cycleNum) {
    const prog = document.getElementById('progText');
    const pingEl = document.getElementById('pingNum');
    const downEl = document.getElementById('downNum');
    const upEl = document.getElementById('upNum');
    
    // 1. Ping (4 samples)
    prog.innerText = `[Cycle ${cycleNum}/3] Measuring latency...`;
    let pings = [];
    for (let i = 0; i < 4; i++) {
        const t0 = performance.now();
        await fetch('?action=ping&nc=' + Math.random());
        pings.push(performance.now() - t0);
    }
    const cyclePing = Math.round(pings.reduce((a, b) => a + b, 0) / pings.length);
    pingEl.innerText = cyclePing;
    
    // 2. Download (12 MB stream, ~4-5s)
    prog.innerText = `[Cycle ${cycleNum}/3] Testing Download (12 MB)...`;
    const tDown0 = performance.now();
    const resp = await fetch('?action=download&nc=' + Math.random());
    const blob = await resp.blob();
    const durDown = (performance.now() - tDown0) / 1000;
    const cycleDown = parseFloat(((blob.size * 8) / (durDown * 1000000)).toFixed(1));
    downEl.innerText = cycleDown;
    
    // 3. Upload (3 MB payload, ~3-4s)
    prog.innerText = `[Cycle ${cycleNum}/3] Testing Upload (3 MB)...`;
    const upData = new Uint8Array(3 * 1024 * 1024);
    const tUp0 = performance.now();
    await fetch('?action=upload&nc=' + Math.random(), { method: 'POST', body: upData });
    const durUp = (performance.now() - tUp0) / 1000;
    const cycleUp = parseFloat(((upData.length * 8) / (durUp * 1000000)).toFixed(1));
    upEl.innerText = cycleUp;
    
    return { ping: cyclePing, download: cycleDown, upload: cycleUp };
}

async function start3xSpeedTest() {
    const btn = document.getElementById('btnTest');
    const badge = document.getElementById('cycleBadge');
    const prog = document.getElementById('progText');
    const pingEl = document.getElementById('pingNum');
    const downEl = document.getElementById('downNum');
    const upEl = document.getElementById('upNum');
    
    btn.disabled = true;
    let results = [];
    
    for (let c = 1; c <= 3; c++) {
        badge.innerText = `Cycle ${c} of 3`;
        const res = await runSingleCycle(c);
        results.push(res);
        
        if (c < 3) {
            badge.innerText = `Pause 3s`;
            for (let s = 3; s > 0; s--) {
                prog.innerText = `Cycle ${c} finished! Next test in ${s}s...`;
                await sleep(1000);
            }
        }
    }
    
    // Calculate Final Average across all 3 cycles
    const avgPing = Math.round(results.reduce((a, b) => a + b.ping, 0) / 3);
    const avgDown = (results.reduce((a, b) => a + b.download, 0) / 3).toFixed(1);
    const avgUp = (results.reduce((a, b) => a + b.upload, 0) / 3).toFixed(1);
    
    pingEl.innerText = avgPing;
    downEl.innerText = avgDown;
    upEl.innerText = avgUp;
    
    badge.innerText = `Completed (Avg)`;
    prog.innerText = `✅ 3x Verification Complete! Result: ${avgDown} Mbps down / ${avgUp} Mbps up`;
    btn.innerText = "⚡ Test Again (3x)";
    btn.disabled = false;
}
</script>
</body>
</html>
