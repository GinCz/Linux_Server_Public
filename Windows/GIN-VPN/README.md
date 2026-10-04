# 🛡️ GIN-VPN by VladiMIR+AI__v006 — High-Speed Native Windows Xray VPN Client

[![Platform](https://img.shields.io/badge/Platform-Windows%207%20%7C%208%20%7C%2010%20%7C%2011%20%7C%20Server%202008--2025-blue.svg)](https://microsoft.com/windows)
[![Version](https://img.shields.io/badge/Version-v006%20(Public%20Release)-green.svg)](https://github.com/GinCz/Linux_Server_Public)
[![License](https://img.shields.io/badge/License-MIT%20%7C%20100%25%20Free-brightgreen.svg)](https://opensource.org/licenses/MIT)
[![Type](https://img.shields.io/badge/Type-Standalone%20Win32%20GUI%20%2B%201--Click%20Elevated%20Install-purple.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Speed](https://img.shields.io/badge/Tunnel-VLESS%20Reality%20%2B%20Vision-orange.svg)](https://github.com/GinCz/Linux_Server_Public)
[![Author](https://img.shields.io/badge/Author-VladiMIR%2BAI-yellow.svg)](https://github.com/GinCz)

**GIN-VPN** is an ultra-fast, lightweight, standalone native Windows GUI client for high-speed, censorship-resistant VPN connections based on **Xray Core (VLESS + Reality + Vision)**.

Supports all Windows operating systems and architectures (**Windows 7, 8, 8.1, 10, 11** and **Windows Server 2008, 2012, 2016, 2019, 2022, 2025**). Built directly on pure Win32 API without heavy frameworks (Electron/WPF/.NET), without command-line windows, and with zero external runtime dependencies. **100% Free & Open Source for public use.**

---

## ⚡ Quick Download & Run (100% Free)

- **Latest Release (.exe):** [`GIN-VPN_v006.exe`](https://github.com/GinCz/Linux_Server_Public/raw/main/Windows/GIN-VPN/GIN-VPN_v006.exe)
- **Source Code (.go):** [`main.go`](main.go)
- **Application Icon (.ico):** [`GIN-VPN.ico`](GIN-VPN.ico)
- **Resource File (.syso):** [`rsrc_windows_amd64.syso`](rsrc_windows_amd64.syso)

> **Portable + 1-Click Elevated Install:** Run anywhere as a portable executable or click **`[ 💾 Install App ]`** to install permanently to `C:\Program Files\GIN-VPN\` with Desktop & Start Menu shortcuts.

---

## 🌟 Core Features (v006)

- **📷 Automatic QR Code Image Recognition from Clipboard (`CF_DIB`):**
  When clicking **`[ 📋 Clear & Paste from Buffer ]`**, GIN-VPN automatically checks if the clipboard contains an image (e.g. copied QR-code screenshot or picture). It extracts the raw bitmap, decodes the QR matrix using `gozxing`, and immediately parses the VLESS configuration link.
- **🛡️ Multi-Resolution Master Application Icon (`GIN-VPN.ico`):**
  Embedded native Windows `.ico` resource with 256x256, 128x128, 64x64, 48x48, 32x32, and 16x16 layers for crisp display in Taskbar, Windows Explorer, Tray, Alt+Tab, and Desktop shortcuts.
- **✨ Zero-Flicker Smooth Tray Shutdown:**
  Fixed tray close sequence (`Disconnect && Exit`): eliminates window redraw flashing by hiding UI immediately (`SW_HIDE`), unhooking tray notifications, resetting proxy settings, and cleanly terminating in a fraction of a second.
- **☀️ `[ ☀️ Day ]` & 🌙 `[ 🌙 Night ]` Dual Selector:**
  Both **Day (`#FFFFFF`)** and **Night (`#181B20`)** theme buttons are always visible side-by-side at the top right with vibrant yellow sun/moon icons. Theme preference is preserved permanently in the Windows Registry.
- **⚡ Instant Row-Click Connection & Right-Click Manager:**
  - **Single Click on any Server Row:** Immediately connects to that server node.
  - **Right-Click on any Server Row:** Opens an instant context menu:
    - `▶ Connect to this Server`
    - `★ Make Default (Move to Top)` — sets profile as default and instantly promotes it to index 0 at the top of the list!
    - `✏️ Edit Key in Box` — loads the full link into the wrapped edit box for rapid modification.
    - `🗑️ Delete Server` — removes profile and updates registry.
- **🚨 First-Run / Portable Warning Banner:**
  When running in uninstalled/portable mode, displays a clear warning banner (`🚨 ⚠️ GIN-VPN is not installed! Running portable. Click [ 💾 Install App ] to save permanently to Program Files with Desktop shortcut.`), which turns into `🛡️ System Protected & Installed` once installed.
- **💾 1-Click Elevated Installer (UAC + LocalAppData Fallback):**
  Uses elevated PowerShell UAC permissions to create `C:\Program Files\GIN-VPN\`, grants full read/write rights via `icacls` (`Users:(OI)(CI)F`), and if run without admin rights, cleanly falls back to `%LOCALAPPDATA%\GIN-VPN`, creating **Desktop and Start Menu shortcuts**.
- **🎨 Colorful Accents & Expressive Status Icons:**
  Enriched UI with vivid status badges (`🟢 CONNECTED`, `🟠 CONNECTING...`, `🔴 ERROR`), cyber emojis (`👑`, `⚡`, `🛡️`, `🌍`, `⏱️`, `📊`), and high-contrast indicators.
- **🔒 Secure Windows Registry Encrypted Storage (`HKCU\Software\GinCz\GIN-VPN`):**
  All VPN keys, server profiles, and preferences are securely stored in the user's private Windows Registry hive. No plain text key files or configs are left sitting on the desktop or disk.
- **⚠️ Smart Duplicate Profile Validation on Paste:**
  Validates clipboard VLESS links against existing profiles, flagging a yellow warning (`⚠️ Server '<Name>' is already added`) to prevent duplicate clutter.
- **🛡️ 100% Windows 7 (SP1) & Windows 10/11 Universal Architecture:**
  Compiled with Go 1.19 and pure native Win32 core APIs, with automatic byte synchronization for legacy connection settings (`DefaultConnectionSettings` and `SavedLegacySettings`).

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
x86_64-w64-mingw32-windres --no-preprocessor -i app.rc -O coff -o rsrc_windows_amd64.syso

# Cross-compile for Windows x86_64 (GUI mode, stripped)
GOOS=windows GOARCH=amd64 go build -ldflags="-H windowsgui -s -w" -o GIN-VPN_v006.exe main.go
```

---

## 📜 License & Credits

- **Developer:** [Vladimir Bulantsev (GinCz) ↗](https://github.com/GinCz)
- **Engine:** VladiMIR+AI Autonomous Development Suite
- **License:** [MIT License](https://opensource.org/licenses/MIT) — 100% Free for personal, commercial, and enterprise use.
