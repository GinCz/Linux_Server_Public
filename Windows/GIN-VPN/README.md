# 🛡️ GIN-VPN by VladiMIR+AI__v010 — High-Speed Native Windows Xray VPN Client

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server%202008--2025-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v010%20(Public%20Release)-green.svg)](https://github.com/GinCz/Linux_Server_Public)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Type](https://img.shields.io/badge/Type-Standalone%20Win32%20GUI%20%2B%201--Click%20Elevated%20Install-purple.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Speed](https://img.shields.io/badge/Tunnel-VLESS%20Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, standalone native Windows GUI client for high-speed, censorship-resistant VPN connections based on **Xray Core (VLESS + Reality + Vision)**.

Supports all Windows operating systems and architectures (**Windows 7, 8, 8.1, 10, 11** and **Windows Server 2008, 2012, 2016, 2019, 2022, 2025**). Built directly on pure Win32 API without heavy frameworks (Electron/WPF/.NET), without command-line windows, and with zero external runtime dependencies. **100% Free & Open Source for public use.**

---

## ⚡ Quick Download & Run (100% Free)

- **Latest Release (.exe):** [`GIN-VPN_v010.exe`](https://github.com/GinCz/Linux_Server_Public/raw/main/Windows/GIN-VPN/GIN-VPN_v010.exe)
- **Source Code (.go):** [`main.go`](main.go)
- **Application Icon (.ico):** [`GIN-VPN.ico`](GIN-VPN.ico)
- **Resource File (.syso):** [`rsrc_windows_amd64.syso`](rsrc_windows_amd64.syso)

> **Portable + 1-Click Elevated Install:** Run anywhere as a portable executable or click **`[ 💾 Install App ]`** to install permanently to `C:\Program Files\GIN-VPN\` with Desktop & Start Menu shortcuts.

---

## 🌟 Core Features (v010)

- **🔒 Clean Key Box on Server Selection:**
  - Clicking servers in the list highlights and selects the node name without cluttering the upper key text box with raw connection strings.
  - The key box remains clean for manual entry (`Ctrl+V`), button pasting (`[ 📋 Paste Key / 📷 QR Image ]`), or explicit right-click edit mode (`Edit Key in Box`).
- **⚡ Double-Click Connection (Single Click to Select):**
  - **Single Click on Server Row:** Safely selects the profile node name.
  - **Double Click on Server Row:** Initiates connection and minimizes cleanly to the system tray.
  - **Right-Click on Server Row:** Opens full context menu to Connect, Make Default (Move to Top), Edit, or Delete.
- **🛡️ Embedded PE Native Icon (`GIN-VPN.ico` in `.rsrc`):**
  Embedded directly into the Windows executable binary resource section (`.rsrc`), providing immediate icon rendering in the Window Titlebar (top-left), Windows Explorer, Taskbar, and Desktop Shortcuts across Windows 7, 8, 10, and 11.
- **👑 3D Volumetric Golden & Emerald Tray Icons with Alpha Transparency:**
  - **Idle / Disconnected / Default:** Luxurious **3D Volumetric Gold** shield with specular reflections and emerald core on 100% transparent background, framed with a crisp black 1px outline.
  - **Connected (Active):** Radiant **3D Volumetric Emerald Green** shield with specular reflections and gold core on 100% transparent background, framed with a crisp black 1px outline.
  - **Connecting:** Vibrant 3D Amber/Orange shield with crisp black outline.
  - **Error:** Vivid 3D Ruby/Coral Red shield with crisp black outline.
- **🎨 Custom Styled Theme Buttons (`☀️ Day` / `🌙 Night`):**
  - **`[ ☀️ Day ]`**: Pure white button with golden-yellow sun icon and dark text.
  - **`[ 🌙 Night ]`**: Deep pitch-black button with bright yellow crescent moon and crisp white text.
- **🔵 Deep Royal Navy & Sky Blue Section Headers:**
  All section titles and category labels are rendered in elegant **Deep Royal Navy Blue (`#10388A`)** in Day mode and **Bright Sky Blue (`#63B3ED`)** in Night mode.
- **💾 Automated 1-Click Elevated Installer with Auto-Close & Custom Icon Shortcuts:**
  - Placed conveniently as the first action button `[ 💾 Install App ]`.
  - Installs to `C:\Program Files\GIN-VPN\` (or `%LOCALAPPDATA%\GIN-VPN`), creates Desktop and Start Menu `.lnk` shortcuts explicitly linked to the master 3D icon.
  - Displays confirmation dialog and automatically closes the portable instance.
- **📷 Automatic QR Code Image Recognition from Clipboard (`CF_DIB`):**
  When clicking **`[ 📋 Paste Key / 📷 QR Image ]`**, GIN-VPN automatically checks if the clipboard contains an image (e.g. copied QR-code screenshot or picture). It extracts the raw bitmap, decodes the QR matrix using `gozxing`, and immediately parses the VLESS configuration link.
- **✨ Zero-Flicker Smooth Tray Shutdown:**
  Clean tray shutdown sequence eliminates window redraw flashing by hiding UI immediately (`SW_HIDE`), unhooking tray notifications, resetting proxy settings, and terminating cleanly.
- **🔒 Secure Windows Registry Encrypted Storage (`HKCU\Software\GinCz\GIN-VPN`):**
  All VPN keys, server profiles, and preferences are securely stored in the user's private Windows Registry hive.

---

## 🖱️ System Tray Context Menu

Right-click the shield icon in the notification area for instant controls:

```text
┌──────────────────────────────────────┐
│  VPN: 195.63.138.33 (NL)             │  (Live Status Badge)
├──────────────────────────────────────┤
│  📂 Open GIN-VPN Dashboard           │  (Restore Main Window)
│  ⏹ Disconnect VPN                   │  (Instant Proxy Toggle)
│  🌐 Verify IP + Speed Test           │  (Opens IP Verification & Speedtest)
│  📋 View vpn.log                     │  (Diagnostic Log Viewer)
├──────────────────────────────────────┤
│  ❌ Disconnect && Exit               │  (Clean Shutdown & Proxy Reset)
└──────────────────────────────────────┘
```

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
GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui -s -w" -o GIN-VPN_v010.exe .
```

---

## 📜 License & Credits

- **Developer:** [Vladimir Bulantsev (GinCz) ↗](https://github.com/GinCz)
- **Engine:** VladiMIR+AI Autonomous Development Suite
- **License:** [MIT License](https://opensource.org/licenses/MIT) — 100% Free for personal, commercial, and enterprise use.
