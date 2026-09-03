# 🛡️ Gin IT — Ultra-Fast IP & 3x Speed Test Microservice

> **Production Deployment:** [prodvig-saita.ru/ip/ ↗](https://prodvig-saita.ru/ip/)  
> **Author:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz))  
> **Target Server:** RU-109 (`212.109.223.109`, FastVDS Ubuntu 24 / FASTPANEL)

---

## 📌 Overview

A lightweight, production-ready network diagnostic microservice engineered for speed, privacy, and precision. It provides instant client IP detection, geographic location resolution, ISP carrier lookup, and a robust 3-cycle stress speed test without any ads, telemetry, trackers, or third-party banners.

```
┌────────────────────────────────────────────────────────┐
│                        🛡️ Gin IT                       │
├────────────────────────────────────────────────────────┤
│                 YOUR PUBLIC IP ADDRESS                 │
│                     185.100.197.0                      │
│                                                        │
│  📍 Country:          [CZ] Czechia                     │
│  🏙️ City / Region:    Prague, Prague                   │
│  🏢 ISP / Carrier:     INTERCONNECT s.r.o.             │
├────────────────────────────────────────────────────────┤
│                     SPEED TEST ×3                      │
│  PING: 68 ms  │  DOWNLOAD: 86.0 Mbps  │  UPLOAD: 10.5  │
│                                                        │
│             [ ⚡ Run Speed Test ×3 ]                   │
├────────────────────────────────────────────────────────┤
│                  prodvig-saita.ru                      │
└────────────────────────────────────────────────────────┘
```

---

## 🚀 Key Features

1. **Zero Ads & Zero Bloat:**
   - 100% clean, distraction-free user interface.
   - Ultra-fast initial page load (< 0.03 seconds).
   - Responsive dark cybernetic aesthetic designed with `Inter` and `JetBrains Mono`.

2. **Accurate IP & Geo Resolution:**
   - Detects real client IP behind Cloudflare (`CF-Connecting-IP`), NGINX reverse proxies (`X-Real-IP`, `X-Forwarded-For`), or direct connections.
   - Dual-tier resolution: Server-side cURL lookup with 24-hour file caching + automatic client-side JavaScript fallback (`ipapi.co` / `ipwho.is`).
   - Generates standard Unicode regional country flag emojis.

3. **Robust 3x Speed Test (`Speed Test ×3`):**
   - Runs **3 consecutive cycles** of network testing.
   - Each cycle performs:
     - **Latency (Ping):** 4 real-time HTTP sample measurements.
     - **Download Throughput:** Streams 12 MB of pseudo-random binary data over 4–5 seconds.
     - **Upload Throughput:** Sends 3 MB POST payloads over 3–4 seconds.
   - Includes an automatic **3-second inter-cycle cooling pause** with live countdown timer.
   - Computes and displays the true mathematical average across all 3 cycles.

4. **One-Click Clipboard Copy:**
   - Clicking the IP address instantly copies it to the system clipboard with an animated confirmation toast.

---

## 📁 File Structure

```
/var/www/gincz/data/www/prodvig-saita.ru/ip/
├── index.php         # Monolithic frontend & backend speedtest handler
└── cache/            # 24-hour local JSON cache for IP geo queries (auto-created)
```

---

## 🛠️ Server Deployment (FastPanel / Ubuntu)

To deploy or update on server **RU-109** (`212.109.223.109`):

```bash
clear
mkdir -p /var/www/gincz/data/www/prodvig-saita.ru/ip
cp index.php /var/www/gincz/data/www/prodvig-saita.ru/ip/index.php
chown -R gincz:gincz /var/www/gincz/data/www/prodvig-saita.ru/ip
chmod -R 755 /var/www/gincz/data/www/prodvig-saita.ru/ip
```

---

## 📄 License & Attribution

Developed by **Vladimir Bulantsev (GinCz)**.  
Distributed under the MIT License as part of the public infrastructure repositories.
