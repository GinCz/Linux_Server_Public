# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v039)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v039%20(Production%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Engine](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, 100% standalone all-in-one native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Engineered for high-throughput network tunneling, zero background bloat, **Interactive Visual Smart Geo-Split Routing Rules Editor & Custom Domain Manager**, **Live Xray Routing Table Hot-Reloading**, **Multi-Layered Smart Geo-Split Shield Telemetry (4-Line Status Card + Dedicated Rules Button + Context Menu Options + High-Responsiveness Tooltips)**, **Auto-Connect on Startup with Instant Tray Minimization**, **Close-to-Tray Protection (X button minimizes to tray)**, **1080p Screen Height Optimized Layout (<700px)**, **One-Click "Copy All" Event Log Buffer**, **Embedded High-Performance Xray Core Engine** (100% self-contained single executable, zero external dependencies or downloads required), solid connected row highlight (Dark Forest Green + Vivid Yellow bold text), dynamic green system tray indicator, real-time Original ISP & VPN Geo-IP telemetry, volumetric 3D button design, full OLED Dark & Day theme switching, multi-language support (English / Russian), persistent profile management (Registry + local JSON store), and clean 3D wireframe Easter Egg dialog (`VladiMIR+AI`).

---

## ⚡ Download & Direct Execution

- **Standalone Native Binary:** [`GIN-VPN_v039.exe`](GIN-VPN_v039.exe) / [`GIN-VPN.exe`](GIN-VPN.exe)
- **Multi-Resolution Golden Shield Icon:** [`Gin-VPN.ico`](Gin-VPN.ico)
- **Connected Dynamic Tray Icon:** [`Gin-VPN-green.ico`](Gin-VPN-green.ico)

> **Zero installation or external downloads required.** Simply run `GIN-VPN_v039.exe` on any Windows workstation or server (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025). The complete high-speed Xray Core is embedded directly within the application.

---

## 🌟 Key Innovations in v039

1. **Interactive Visual Smart Geo-Split Routing Rules Editor & Custom Domain Manager:**
   - **Dedicated `[ ⚙️ Rules / ⚙️ Правила ]` Button:** Opens a full-featured visual editor allowing users to inspect and customize all domain routing rules.
   - **Direct Bypass Domains List:** Add custom domains that must ALWAYS bypass the VPN and connect directly at full local ISP speed (e.g., local utility payment portals in Moscow, housing websites like `mosenergosbyt.ru`, `mosoblrc.ru`, `kvartplata.info`, municipal portals, local clinic sites, or any `.ru` services).
   - **Always-Proxied Domains List:** Add custom domains that must ALWAYS route through the encrypted VPN tunnel.
   - **Live Hot-Reloading:** When saving new rules, the embedded Xray Core dynamically hot-reloads its routing table in real-time without dropping your active connection.
   - **Persistent Storage:** Rules are stored in `%LOCALAPPDATA%\GIN-VPN\custom_rules.json` and persist across reboots and updates.

2. **Pre-Configured Default Domestic & Global Domain Matrix:**
   - **Default Direct Domains (Domestic/RU Bypass):** `*.ru`, `*.рф`, `*.su`, `gosuslugi.ru`, `mos.ru`, `pgu.mos.ru`, `dom.gosuslugi.ru`, `mosenergosbyt.ru`, `mosoblrc.ru`, `kvartplata.info`, `eirkc.ru`, `sberbank.ru`, `sber.ru`, `tbank.ru`, `tinkoff.ru`, `t-bank.ru`, `vtb.ru`, `alfabank.ru`, `gazprombank.ru`, `cbr.ru`, `nalog.gov.ru`, `vk.com`, `vk.me`, `vkvideo.ru`, `ok.ru`, `yandex.ru`, `ya.ru`, `ozon.ru`, `wildberries.ru`, `wb.ru`, `avito.ru`, `2gis.ru`, `cian.ru`, `domclick.ru`, `kinopoisk.ru`, `rutube.ru`, `rbc.ru`, `ria.ru`, `tass.ru`, `lenta.ru`, `aviasales.ru`, `rzd.ru`, `aeroflot.ru`.
   - **Default Proxied Domains (Global Tunneling):** `youtube.com`, `googlevideo.com`, `ytimg.com`, `youtu.be`, `instagram.com`, `cdninstagram.com`, `facebook.com`, `fbcdn.net`, `twitter.com`, `x.com`, `twimg.com`, `t.co`, `spotify.com`, `scdn.co`, `openai.com`, `chatgpt.com`, `oaistatic.com`, `anthropic.com`, `claude.ai`, `netflix.com`, `telegram.org`, `t.me`, `discord.com`, `discord.gg`, `linkedin.com`, `bbc.com`, `notion.so`, `github.com`.

3. **On-Screen Real-Time Shield Telemetry:**
   - 4th line in the Diagnostics Card displays the active routing status at a glance.
   - Right-click server context menu provides `⚙️ Настройка правил (Сайты прямо / VPN)...` (`⚙️ Configure Rules (Direct / VPN)...`).

4. **100% Standalone All-In-One Architecture:**
   - The entire Xray Core engine payload is embedded directly inside `GIN-VPN_v039.exe`.

---

## 🏛️ System Architecture

```text
┌────────────────────────────────────────────────────────┐
│               GIN-VPN.exe (Single Binary)              │
│  ┌─────────────────────────┐  ┌─────────────────────┐  │
│  │    Win32 GUI Client     │  │ Embedded Xray Core  │  │
│  │ (Dark/Day, Tray, Rules) │  │  (Compressed Gzip)  │  │
│  └────────────┬────────────┘  └──────────┬──────────┘  │
└───────────────┼──────────────────────────┼─────────────┘
                │                          │ (Instant In-Memory Unpack)
                │ IPC Config               ▼
        ┌───────▼───────────────────────────────┐
        │        Local Xray Core Daemon         │
        └───────────────────┬───────────────────┘
                            │ (TLS Reality Tunnel)
        ┌───────────────────▼───────────────────┐
        │  DE-222 / RU-109 / IONOS-38 Gateways  │
        └───────────────────┬───────────────────┘
```

---

## 🔒 Triple-Lock & Repository Mirroring
- **GitHub Repository (Windows Scripts):** [Windows_scripts ↗](https://github.com/GinCz/Windows_scripts)
- **GitHub Repository (Public Linux/Windows):** [Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public)
- **Author:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz))
