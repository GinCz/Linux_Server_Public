# 🛡️ GIN-VPN by VladiMIR+AI__v012 — High-Speed Native Windows Xray VPN Client

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server%202008--2025-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v012%20(Public%20Release)-green.svg)](https://github.com/GinCz/Linux_Server_Public)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Type](https://img.shields.io/badge/Type-Standalone%20Win32%20GUI%20%2B%201--Click%20Elevated%20Install-purple.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Speed](https://img.shields.io/badge/Tunnel-VLESS%20Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, standalone native Windows GUI client for high-speed, censorship-resistant VPN connections based on **Xray Core (VLESS + Reality + Vision)**.

Supports all Windows operating systems and architectures (**Windows 7, 8, 8.1, 10, 11** and **Windows Server 2008, 2012, 2016, 2019, 2022, 2025**). Built directly on pure Win32 API without heavy frameworks (Electron/WPF/.NET), without command-line windows, and with zero external runtime dependencies. **100% Free & Open Source for public use.**

---

## ⚡ Quick Download & Run (100% Free)

- **Latest Release (.exe):** [`GIN-VPN_v012.exe`](https://github.com/GinCz/Linux_Server_Public/raw/main/Windows/GIN-VPN/GIN-VPN_v012.exe)
- **Source Code (.go):** [`main.go`](main.go)
- **Application Icon (.ico):** [`GIN-VPN.ico`](GIN-VPN.ico)
- **Resource File (.syso):** [`rsrc_windows_amd64.syso`](rsrc_windows_amd64.syso)

> **Portable + 1-Click Elevated Install:** Run anywhere as a portable executable or click **`[ 💾 Install App ]`** to install permanently to `C:\Program Files\GIN-VPN\` with Desktop & Start Menu shortcuts.

---

## 🌟 Core Features (v012)

- **🎨 Full Owner-Drawn Vibrant UI Buttons (`BS_OWNERDRAW` + `WM_DRAWITEM`):**
  - High-visibility rounded action buttons with rich, modern color coding:
    - `[ ▶ CONNECT VPN ]`: Dynamic state colors — **Vibrant Royal Blue** (Idle), **Emerald Green** (Connected), **Amber Orange** (Connecting), **Ruby Red** (Error / Disconnect).
    - `[ ☀️ Day ]` & `[ 🌙 Night ]`: Warm Amber Gold and Royal Indigo theme toggles.
    - `[ 📋 Paste Key / 📷 QR Image ]`: High-contrast Indigo / Purple.
    - `[ 💾 Save ]`: Radiant Emerald Green.
    - `[ 💾 Install App ]`: Bold Coral Red (or Emerald Green when Installed).
    - `[ 🌐 Verify IP + Speed Test ]`: Vivid Sky Blue / Teal.
    - `[ 📜 View vpn.log ]`: Rich Purple.
    - `[ 🧹 Clear Log ]`: Modern Cool Slate.
- **🔒 Clean Key Box on Server Selection:**
  - Clicking servers in the list highlights and selects the node name without cluttering the upper key text box with raw connection strings.
- **⚡ Double-Click Connection (Single Click to Select):**
  - **Single Click on Server Row:** Safely selects the profile node name.
  - **Double Click on Server Row:** Initiates connection and minimizes cleanly to the system tray.
  - **Right-Click on Server Row:** Opens full context menu with confirmation dialog on server deletion.
- **🛡️ Embedded PE Native Icon (`GIN-VPN.ico` in `.rsrc`):**
  Embedded directly into the Windows executable binary resource section (`.rsrc`), providing immediate icon rendering across all Windows versions.
- **👑 3D Volumetric Golden & Emerald Tray Icons with Alpha Transparency:**
  - **Idle / Disconnected / Default:** Luxurious **3D Volumetric Gold** shield on 100% transparent background.
  - **Connected (Active):** Radiant **3D Volumetric Emerald Green** shield.
- **💾 Bulletproof Single Desktop Shortcut Installer Engine:**
  - Automatically identifies user profile desktop, Public desktop, and custom synced desktops (`D:\MEGA\DOCS\desktop`).
  - Cleans legacy duplicate shortcuts and creates clean shortcuts with immediate Windows Explorer shell refresh (`SHChangeNotify`).
- **📷 Automatic QR Code Image Recognition from Clipboard (`CF_DIB`):**
  Auto-decodes VLESS keys directly from copied QR code screenshots.

---

## 🛠️ Build from Source

Requirements: Go 1.19+ and MinGW-w64 windres.

```bash
# Clone the repository
git clone https://github.com/GinCz/Linux_Server_Public.git
cd Linux_Server_Public/Windows/GIN-VPN

# Compile resources with embedded icon
x86_64-w64-mingw32-windres --preprocessor=cat -i app.rc -O coff -o rsrc_windows_amd64.syso

# Cross-compile for Windows x86_64 (GUI mode, full package build to embed .syso)
GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui -s -w" -o GIN-VPN_v012.exe .
```

---

## 📜 License & Credits

- **Developer:** [Vladimir Bulantsev (GinCz) ↗](https://github.com/GinCz)
- **Engine:** VladiMIR+AI Autonomous Development Suite
- **License:** [MIT License](https://opensource.org/licenses/MIT) — 100% Free for personal, commercial, and enterprise use.
