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

## 📦 Project Structure

| File / Folder | Purpose |
| :--- | :--- |
| **`main.go`** | Complete monolithic Go source code: Win32 message loop, WaveIn PCM audio capture, Whisper client, and UI. |
| **`go.mod`** | Go module definition. |
| **`app.ico` / `app_rec.ico`** | High-resolution application microphone icons (idle and active recording states). |
| **`app.manifest` / `app.rc`** | Windows PE application manifest (DPI-aware, Common Controls v6) and resource script. |
| **`rsrc_windows_amd64.syso`** | Pre-compiled COFF resource containing embedded PE icons and manifest for direct compilation. |
| **`dictionary.json`** | Customizable phonetic terminology dictionary for domain-specific vocabulary replacements. |
| **`setup_guide.html`** | Interactive bilingual setup guide and keyboard shortcut reference. |
| **`version.json` / `version.txt`** | Current release version metadata (`v022`). |
| **`cmd/uninstall/main.go`** | Native standalone uninstaller source code (ANSI styled). |

---

## 🚀 Quick Start & Building

### 1. Compile from Source
GIN-Voice compiles cleanly in a few seconds using standard Go 1.22+ without CGo:

```bash
# Clone the repository
git clone https://github.com/GinCz/Linux_Server_Public.git
cd Linux_Server_Public/Windows/GIN-Voice

# Compile Windows GUI binary (embeds syso resources automatically)
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w -H=windowsgui" -o GIN-Voice.exe .
```

### 2. Configure Groq API Key
1. Right-click the microphone icon in the Windows notification area (System Tray).
2. Select **Setup Groq API Key** (or open Settings).
3. Paste your Groq API key (free keys available at [console.groq.com/keys ↗](https://console.groq.com/keys)).
4. Click **Test API Key** to verify connectivity, then click **Save Settings**.

### 3. Voice Typing Workflow
1. Place your text cursor in any application (VS Code, Antigravity, Browser, Telegram, Word, etc.).
2. Press **`F4`** once (a soft chime plays and the HUD displays `RECORDING...`).
3. Speak naturally in any language (English, Russian, Czech, Spanish, French, German, and 15+ more).
4. Press **`F4`** a second time to stop recording.
5. The audio is transcribed via Whisper Large v3 within ~500ms and automatically typed directly into your active input field!

---

## 🛠️ Building From Source

GIN-Voice can be cross-compiled on Linux for Windows AMD64 or built natively on Windows:

```bash
# 1. Embed Windows Resources (Manifest & PE Icons)
rsrc -manifest app.manifest -ico app.ico -o rsrc_windows_amd64.syso

# 2. Compile Native Windows GUI Binary (No Console Window)
GOOS=windows GOARCH=amd64 go build -ldflags="-s -w -H=windowsgui" -o GIN-Voice.exe .
```

---

## 📜 Documentation & Governance

* **[CHANGELOG.md ↗](https://github.com/GinCz/Linux_Server_Public/blob/main/Windows/GIN-Voice/CHANGELOG.md)** — Complete chronological log of versions `v001` through `v022`, bugs solved, and architectural iterations.
* **[RULES.md ↗](https://github.com/GinCz/Linux_Server_Public/blob/main/Windows/GIN-Voice/RULES.md)** — Inviolable architectural standards, dual-target release protocol, and zero-regression policies.
* **[HELP.md ↗](https://github.com/GinCz/Linux_Server_Public/blob/main/Windows/GIN-Voice/HELP.md)** — Detailed user manual, multilingual settings, and customization guidelines.
