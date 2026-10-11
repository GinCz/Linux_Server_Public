# 🎙️ GIN-Voice [v022] — User Manual & Configuration Reference

> **Product:** GIN-Voice by VladiMIR+AI  
> **Platform:** Windows 10 / 11 (64-bit AMD64)  
> **Speech AI Engine:** Whisper Large v3 via Groq Cloud API  

---

## ⚡ 1. Quick Start & Operation

1. **Default Hotkey:** `[ F4 ]`
   * **Press `F4` once:** A soft audio chime plays, and microphone recording begins. The floating head-up display (HUD) appears at the top of the screen showing `RECORDING...`.
   * **Speak naturally:** Supports continuous mixed-language speech (Russian, English, Czech, Spanish, French, German, and 15+ additional languages).
   * **Press `F4` a second time:** A closing chime sounds. The audio is instantly transcribed via Whisper Large v3 and pasted directly at your current text cursor position in any application (IDE, browser, chat, editor).
2. **System Tray Control:**
   * Right-click the microphone icon in the system tray (notification area near the clock) to access settings, language selection, vocabulary management, and manual update checks.

---

## 🎨 2. Floating HUD Typography Customization

In the Settings dialog, you can configure your preferred **HUD Font**:
* **Comfortaa (Default):** Smooth, elegant, rounded, non-bold futuristic typography.
* **Segoe UI Variable / Segoe UI:** Native Windows 11 fluent typography.
* **Bahnschrift:** Clean DIN-style geometric sans-serif.
* **Montserrat:** Modern geometric display font.
* **Consolas:** High-contrast fixed-width monospace font.

---

## 🌐 3. Language & Speech Selection

* **UI Language:** Instant toggle between `🇬🇧 English` and `🇷🇺 Русский` inside Settings. The interface re-renders immediately without restarting.
* **Recognition Languages:** Choose your primary spoken languages from the balanced grid. Multilingual auto-detection seamlessly handles mixed-language dictation.

---

## 📖 4. Custom Vocabulary (`dictionary.json`)

To ensure specialized project names, technical terms, or company brandings are accurately transcribed:
1. Right-click the tray icon and select **Open Dictionary**.
2. Add your custom key-value pairs (e.g., `"джин воис": "GIN-Voice"`, `"оракл": "ORACLE_157"`).
3. GIN-Voice dynamically loads these rules into the transcription post-processor and Whisper context.

---

## 🔄 5. In-App Updates

* **Automatic Check:** Right-click the tray icon and select **Check for Updates**.
* The app queries GitHub, compares version numbers, downloads the latest `GIN-Voice.exe` into a temporary location, cleanly swaps the binary, and relaunches itself—preserving all your settings and API keys.
