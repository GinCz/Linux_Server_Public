# 🛡️ Gin IT — Ultra-Fast IP & 3x Speed Test Microservice

> **Production Deployments:**
> - 🇩🇪 Europe / Global: [eco-seo.cz/ip/ ↗](https://eco-seo.cz/ip/) — Server **DE-222** (152.53.182.222, NetCup Germany)
> - 🇷🇺 Russia / CIS: [prodvig-saita.ru/ip/ ↗](http://prodvig-saita.ru/ip/) — Server **RU-109** (212.109.223.109, FastVDS Moscow)
>
> **Author:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz))

---

## 📌 Overview

A lightweight, production-ready network diagnostic microservice engineered for speed, privacy, and precision. It provides instant client IP detection, multi-source geographic location resolution, ISP carrier lookup, anti-flood rate limiting, and an interactive 3-cycle stress speed test without any ads, telemetry, trackers, or third-party banners.

`
┌────────────────────────────────────────────────────────┐
│                 YOUR PUBLIC IP ADDRESS                 │
│                     185.100.197.0                      │
│                                                        │
│  Country:             Czechia                          │
│  City / Region:       Prague, Prague                   │
│  ISP / Carrier:       INTERCONNECT s.r.o.              │
├────────────────────────────────────────────────────────┤
│  SPEED TEST ×3              Сервер: Германия (NetCup)  │
│                                            [ Ready ]   │
│  Test        Ping (ms)    Download (Mbps)  Upload (Mbps│
│  #1             14              94.2           28.4    │
│  #2             12              96.1           29.1    │
│  #3             13              95.8           28.9    │
│  Average        13              95.4           28.8    │
│                                                        │
│  [ ⚡ Run Speed Test ×3 ]   [ 📋 Скопировать в буфер ] │
├────────────────────────────────────────────────────────┤
│                     eco-seo.cz ↗                       │
└────────────────────────────────────────────────────────┘
`

---

## 🚀 Key Features

1. **Zero Ads & Ultra-Compact UI (Top 5mm Margin):**
   - 100% clean, distraction-free user interface starting directly with the IP block (header banner eliminated).
   - Ultra-fast initial page load (< 0.03 seconds).
   - Responsive dark cybernetic aesthetic designed with Inter and JetBrains Mono.

2. **Accurate Multi-Source IP & Geo Resolution:**
   - Detects real client IP behind Cloudflare (CF-Connecting-IP), NGINX reverse proxies (X-Real-IP, X-Forwarded-For), or direct connections.
   - Cascading 3-tier geo resolution: ip-api.com -> SypexGeo (specialized RU/CIS) -> ipwho.is with 24-hour JSON caching.
   - Client-side AJAX fallback to ensure continuous geo-resolution even under aggressive external API quotas.

3. **Adaptive Multi-Node Architecture:**
   - Automatically detects active node and domain (eco-seo.cz vs prodvig-saita.ru).
   - Dynamically labels server location:
     - DE-222: **Сервер: 🇩🇪 Германия (NetCup)**
     - RU-109: **Сервер: 🇷🇺 Россия (Москва)**
   - Dynamic footer link leading back to the parent website (eco-seo.cz ↗ or prodvig-saita.ru ↗).

4. **Robust 3x Speed Test (Speed Test ×3):**
   - Runs **3 consecutive cycles** of network testing with real-time per-cycle table logging.
   - Each cycle performs:
     - **Latency (Ping):** 4 real-time HTTP sample measurements.
     - **Download Throughput:** Streams 12 MB binary data over 4–5 seconds.
     - **Upload Throughput:** Sends 3 MB POST payloads over 3–4 seconds.
   - Includes an automatic **3-second inter-cycle cooling pause** with live countdown timer.
   - Computes mathematical average across all 3 cycles.

5. **Rate Limiting & Anti-Flood Protection:**
   - Implements strict 20-second cooldown between speed test runs.
   - Visual countdown timer and button lockout preventing server bandwidth exhaustion.

6. **Instant Clipboard Reporting:**
   - One-click copy for the detected IP address.
   - Formatted test report copying button:
     ``text
     🛡️ Gin IT — Speed Test ×3
     📍 Сервер: 🇩🇪 Германия (NetCup)
     🌐 185.100.197.0 (Чехия, Прага)
     🏢 INTERCONNECT s.r.o.
     ⚡ 13 ms
     ⬇️ 95.4 Mbps
     ⬆️ 28.8 Mbps
     ``

---

## 📁 File Structure

`
/var/www/gincz/data/www/{domain}/ip/
├── index.php         # Monolithic frontend & backend speedtest handler
└── cache/            # 24-hour local JSON cache for IP geo & rate limiting (auto-created)
`

---

## 🛠️ Server Deployment (FastPanel / Ubuntu)

### Deployment to **DE-222** (152.53.182.222 — eco-seo.cz):

`ash
clear
mkdir -p /var/www/gincz/data/www/eco-seo.cz/ip
cp index.php /var/www/gincz/data/www/eco-seo.cz/ip/index.php
chown -R gincz:gincz /var/www/gincz/data/www/eco-seo.cz/ip
chmod -R 755 /var/www/gincz/data/www/eco-seo.cz/ip
`

### Deployment to **RU-109** (212.109.223.109 — prodvig-saita.ru):

`ash
clear
mkdir -p /var/www/gincz/data/www/prodvig-saita.ru/ip
cp index.php /var/www/gincz/data/www/prodvig-saita.ru/ip/index.php
chown -R gincz:gincz /var/www/gincz/data/www/prodvig-saita.ru/ip
chmod -R 755 /var/www/gincz/data/www/prodvig-saita.ru/ip
`

---

## 📄 License & Attribution

Developed by **Vladimir Bulantsev (GinCz)**.  
Distributed under the MIT License as part of the public infrastructure repositories.