# 🛡️ GIN-VPN by VladiMIR+AI — High-Speed Native Windows Xray Client (v044)

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v044%20(Production%20Release)-green.svg)](https://github.com/GinCz/Windows_scripts)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Engine](https://img.shields.io/badge/Engine-Xray%20Core%20VLESS--Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Windows_scripts)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, 100% standalone all-in-one native Windows GUI client for **Xray Core (VLESS + Reality + Vision)**. Engineered for high-throughput network tunneling, zero background bloat, **Persistent User Settings Preservation (Language RU/EN & OLED Night/Day Theme saved across restarts)**, **Full Windows Uninstaller & Clean Removal Support (`--uninstall`)**, **One-Click Server Profiles Full Backup Export (`GIN-VPN_BackUp__YYYY-MM-DD__HH-mm.txt`)**, **Bulletproof Desktop & Start Menu Shortcut Installation with Golden Shield Icons**, **Automatic Profile & Settings Migration into Installed Application Directory (`settings.json`, `profiles.json`, `custom_rules.json`)**, **Privacy-First Clean Initial Profiles on New Workstations (Zero Private Servers Bundled)**, **Pixel-Perfect Rectangular Solid Button Rendering (Zero White Corner Artifacts in OLED Night Mode)**, **Single Country Code Display**, **2-Column Dedicated Rules Info Modal & Custom Direct Domain Manager**, **Live Xray Routing Table Hot-Reloading**, **Clean Compact 2-Line Diagnostics Card**, **Auto-Connect on Startup with Instant Tray Minimization**, **Close-to-Tray Protection (X button minimizes to tray)**, **1080p Screen Height Optimized Layout (<700px)**, **One-Click "Copy All" Event Log Buffer**, **Embedded High-Performance Xray Core Engine** (100% self-contained single executable, zero external dependencies or downloads required), solid connected row highlight (Dark Forest Green + Vivid Yellow bold text), dynamic green system tray indicator, real-time Original ISP & VPN Geo-IP telemetry, volumetric 3D button design, full OLED Dark & Day theme switching, multi-language support (English / Russian), persistent profile management (Registry + local JSON store), and clean 3D wireframe Easter Egg dialog (`VladiMIR+AI`).

---

## ⚡ Download & Direct Execution

- **Standalone Native Binary:** [`GIN-VPN_v044.exe`](GIN-VPN_v044.exe) / [`GIN-VPN.exe`](GIN-VPN.exe)
- **Multi-Resolution Golden Shield Icon:** [`Gin-VPN.ico`](Gin-VPN.ico)
- **Connected Dynamic Tray Icon:** [`Gin-VPN-green.ico`](Gin-VPN-green.ico)

> **Zero installation or external downloads required.** Simply run `GIN-VPN_v044.exe` on any Windows workstation or server (Windows 7 SP1, 8.1, 10, 11, Server 2008–2025). The complete high-speed Xray Core is embedded directly within the application.

---

## 🌟 Key Innovations in v044

1. **Persistent Language & Theme Settings Storage (RU / EN & Night / Day):**
   - User language selection (Russian / English) and Theme mode (Light Day / OLED Night) are now saved immediately to Windows Registry (`HKCU\Software\VladiMIR\GIN-VPN`) and local configuration storage (`settings.json`).
   - When restarting or rebooting the computer, GIN-VPN automatically restores your preferred language and theme from the very first frame without reverting to English defaults.
   - During installer execution (`📑 Install App`), `settings.json` is automatically migrated into `C:\Program Files\GIN-VPN\` alongside `profiles.json` and `custom_rules.json`.

2. **Official Windows Uninstaller (`uninstall.exe` in `C:\Program Files\GIN-VPN` / Settings / Control Panel):**
   - Installs directly into `C:\Program Files\GIN-VPN\` containing both `GIN-VPN.exe` and `uninstall.exe`.
   - Registered in Windows `Uninstall` registry with clean string format `"C:\Program Files\GIN-VPN\uninstall.exe"`.
   - Safely resets Windows System Proxy, terminates Xray Core daemon, removes Desktop/Start Menu shortcuts, removes registry keys, and purges installation files.

3. **One-Click Server Backup Export & Import (Full Context Menu on Empty List):**
   - **Export (`GIN-VPN_BackUp__YYYY-MM-DD__HH-mm.txt`):** Right-click any server profile to export all configured servers into a structured backup file containing summaries, raw VLESS keys (1 per line for rapid bulk import), and full JSON data. Automatically saves to Desktop, copies the path to clipboard, and highlights the file in Windows File Explorer.
   - **Import (`📥 Import Profiles from Backup`):** Right-click anywhere in the list (even when empty with 0 servers!) to import servers from any backup `.txt` or `.json` file, or bulk VLESS key lists with smart deduplication.
   - **Empty State Context Menu:** When the server list is completely empty or when clicking blank areas, right-click opens the dedicated action menu to import backups, paste clipboard keys, or configure routing rules.

4. **Single-Instance Mutex Protection (`GIN_VPN_SINGLE_INSTANCE_MUTEX_V044`):**
   - Automatically prevents launching duplicate copies of GIN-VPN.
   - If a second instance is launched, it automatically finds the existing running window, restores it from minimized/tray state, brings it to the foreground, and cleanly exits.

5. **Bulletproof Installation & Desktop Shortcut Generation:**
   - Guaranteed atomic binary copying with verification before shortcut generation.
   - Creates valid shortcuts on both Desktop and Start Menu with embedded golden shield icon.
   - Automatically migrates all active profiles (`profiles.json`), custom rules (`custom_rules.json`), and user settings (`settings.json`) directly into the target program directory.

6. **Clean Privacy-First Profiles on New Installations:**
   - When launching on a clean PC without pre-existing registry data, the profile list starts completely **empty (0 servers)**, protecting your private server credentials from leaking to third parties.
   - For existing installations, all profiles are preserved and read safely from Windows Registry (`HKCU\Software\VladiMIR\GIN-VPN`) and `%LOCALAPPDATA%\GIN-VPN\profiles.json`.

7. **Solid Monolithic Rectangular Rendering (Zero White Corners in Dark Mode):**
   - Replaced rounded polygon GDI drawing with precise `procRectangle` rendering for all buttons and panels, completely eliminating white corner artifacts in Dark/Night OLED mode.

8. **Dedicated 2-Column Rules Modal & Custom Direct Domain Manager:**
   - Inspect standard Russian domains (Direct) vs. Global services (VPN) in 2 parallel columns, with an editable box for custom local domains (utility portals, housing portals, local municipal services).
   - Real-time live hot-reloading of Xray Core routing tables without session drop.

9. **100% Standalone All-In-One Architecture:**
   - Embedded Xray Core payload directly inside `GIN-VPN_v044.exe`.

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
