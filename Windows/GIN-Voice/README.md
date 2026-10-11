# 🎙️ GIN-Voice [v022] — High-Speed Multilingual AI Voice Typing & Dictation Suite

> **Author / Architect:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI  
> **Repository:** [Linux_Server_Public / Windows / GIN-Voice ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/Windows/GIN-Voice)  
> **Upstream Repository:** [Windows_scripts / GIN-Voice ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Voice)  
> **Version:** `v022`  
> **Platform:** Windows 10 / 11 (64-bit AMD64)  
> **License:** MIT — 100% Free & Open Source  

---

## 🧭 Executive Overview

**GIN-Voice** is an ultra-fast, native, lightweight desktop voice-typing and AI dictation application for Windows 10 and 11. Built from the ground up in Go with direct Win32 API bindings and raw WaveIn PCM audio capture, GIN-Voice records high-fidelity audio, dispatches it to **Whisper Large v3 via Groq Cloud API**, and injects clean, formatted transcriptions directly into whichever input field, editor, browser, or messenger holds user focus.

It operates with sub-second turnaround, near-zero idle CPU consumption, customizable floating head-up display (HUD), intelligent anti-hallucination sanitization, dynamic repetition loop prevention, bilingual English/Russian interface switching, and built-in 1-click self-updating.

---

## ✨ Key Architectural Highlights & Features

### ⚡ 1. Ultra-Low-Latency Audio Engine
* **Event-Driven WaveIn PCM:** Direct hardware capture using Microsoft Win32 `waveInOpen` with `CALLBACK_EVENT`. Zero CPU polling; threads sleep until hardware DMA audio frames arrive.
* **Trailing Speech Buffer Flush (200ms):** Prevents common speech-to-text clipping where trailing words are dropped upon releasing the hotkey.
* **Silent Background Operation:** Consumes less than 15 MB of RAM and 0% CPU while awaiting hotkey activation.

### 🧠 2. Advanced Speech Processing & Whisper Guard
* **Whisper Large v3 Acceleration:** Harnesses ultra-fast LPU inference (Groq API) providing complete transcriptions in 300–700 milliseconds.
* **Repetition Loop Guard:** Advanced regex and n-gram loop detection (`removeRepetitiveLoops()`) automatically strips trailing hallucinated loops and repetitive brand mentions caused by Whisper attention decoder lock-in.
* **Anti-Hallucination Filtering:** Purges common Whisper artifacts such as `(music)`, `(applause)`, `(laughter)`, `(silence)`, and subtitle credits.
* **Dynamic Vocabulary Capping:** Custom vocabulary replacements (`dictionary.json`) and system terms are deduplicated and strictly capped to the top 12 relevant tokens, keeping the prompt focused and hallucination-free.

### 🎨 3. Elegant Floating HUD & Modern User Interface
* **Overlay Status HUD:** Non-intrusive floating pill at the top of the screen displays real-time recording, processing, copying, and update statuses.
* **Customizable HUD Typography:** Supports `Comfortaa` (smooth, non-bold futuristic default), `Segoe UI Variable`, `Bahnschrift`, `Montserrat`, and `Consolas`.
* **Dynamic Dual-State Tray Icon:** System tray microphone changes from cyan idle state to glowing red while recording.
* **Interactive Bilingual Interface Switcher:** Instant toggle between `🇬🇧 English` and `🇷🇺 Русский` inside Settings without requiring application restarts.

### 🛡️ 4. Enterprise-Grade Reliability & Security
* **Zero-Key Leak Architecture:** API keys are never hardcoded in source binaries. Keys are securely read from local working directory (`config.json`) with automated fallback to Windows Registry.
* **Single-Instance Mutex:** Global Windows Mutex (`GIN-Voice-SingleInstance-Mutex`) guarantees only one instance runs per user session.
* **Windows Installed Apps Registration:** Registered in Windows Registry (`HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Voice`) for seamless presence in Windows Settings / Apps & Features.
* **Zero-Data-Loss In-Place Updates:** Application self-updater replaces strictly the executable binary, preserving 100% of user settings, API keys, and custom dictionaries.
* **Clean Uninstaller with Installer Preservation:** Uninstaller cleans program binaries, shortcuts, and registry keys, while strictly preserving installer `.exe` files on Desktop and cloud folders.

---

## 📦 Distribution Packages

| File | Size | Description |
| :--- | :--- | :--- |
| **`GIN-Voice_Setup_v022.exe`** | ~8.68 MB | **All-in-One Single-File Installer & App:** Auto-configures folders, creates shortcuts, and launches setup guide. |
| **`GIN-Voice_v022.exe`** | ~8.68 MB | **Versioned Portable Executable:** Standalone runner with version tag. |
| **`GIN-Voice.exe`** | ~8.68 MB | **Core Binary:** Live production binary targeted by the in-app auto-updater. |
| **`Uninstall.exe`** | ~1.76 MB | **Native Standalone Uninstaller:** 90-character styled ANSI terminal uninstaller. |
| **`setup_guide.html`** | ~16 KB | **Interactive Bilingual Setup Guide:** Quick reference with tabbed English/Russian guides. |
| **`dictionary.json`** | ~2 KB | **Personal Terminology Replacement Dictionary:** Pre-configured project vocabulary. |
| **`version.json`** | 225 B | **Live Update Metadata:** Queried by the in-app updater endpoint. |

---

## 🚀 Quick Start Guide

### 1. Installation
1. Download or copy **`GIN-Voice_Setup_v022.exe`** to your desktop.
2. Double-click the file to launch.
3. The setup automatically configures `%LOCALAPPDATA%\GIN-Voice`, places a Desktop shortcut, and registers in Windows Startup (optional).

### 2. Configure Groq API Key
1. Right-click the microphone icon in the Windows notification area (System Tray).
2. Select **Setup Groq API Key** (or open Settings).
3. Paste your Groq API key (get a free key at [console.groq.com/keys ↗](https://console.groq.com/keys)).
4. Click **Test API Key** to verify connectivity, then click **Save Settings**.

### 3. Voice Typing Workflow
1. Place your text cursor in any application (VS Code, Antigravity, Browser, Telegram, Word).
2. Press **`F4`** once (a gentle chime sounds and the HUD indicates `RECORDING...`).
3. Speak naturally in any language (English, Russian, Czech, German, Spanish, French, Italian, etc.).
4. Press **`F4`** a second time to stop recording.
5. The audio is transcribed via Whisper Large v3 within ~500ms and automatically typed directly into your cursor position!

---

## 🛠️ Building From Source

GIN-Voice is cross-compiled on Linux (or natively on Windows) using Go 1.22+:

```bash
# =============================================================================
# Execution Context : Bash (Ubuntu / Debian / Linux)
# Target Binary     : Windows PE AMD64 (GIN-Voice.exe)
# =============================================================================

# 1. Embed Windows Resources (Manifest & PE Icons)
rsrc -manifest app.manifest -ico app.ico -o rsrc_windows_amd64.syso

# 2. Compile Native Windows GUI Binary (No Console Window)
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w -H=windowsgui" -o GIN-Voice.exe .

# 3. Create Distribution Builds
cp GIN-Voice.exe GIN-Voice_v022.exe
cp GIN-Voice.exe GIN-Voice_Setup_v022.exe
```

---

## 📜 Documentation & Governance

* **[CHANGELOG.md ↗](https://github.com/GinCz/Linux_Server_Public/blob/main/Windows/GIN-Voice/CHANGELOG.md)** — Complete chronological log of versions `v001` through `v022`, bugs solved, and architectural iterations.
* **[RULES.md ↗](https://github.com/GinCz/Linux_Server_Public/blob/main/Windows/GIN-Voice/RULES.md)** — Inviolable architectural standards, dual-target release protocol, and zero-regression policies.
* **[HELP.md ↗](https://github.com/GinCz/Linux_Server_Public/blob/main/Windows/GIN-Voice/HELP.md)** — Detailed user manual, multilingual settings, and customization guidelines.
