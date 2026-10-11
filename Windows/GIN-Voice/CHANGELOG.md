# 📜 GIN-Voice: Complete Release Changelog & Evolution (v001 - v022)

> **Project:** GIN-Voice by VladiMIR+AI  
> **Repository:** [Linux_Server_Public / Windows / GIN-Voice ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/Windows/GIN-Voice)  
> **Upstream:** [Windows_scripts / GIN-Voice ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Voice)  
> **Author:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI  
> **Purpose:** Permanent historical record of all releases, bugs solved, and architectural decisions to prevent regression.

---

## 🎯 Summary Release Table

| Version | Release Date | Key Features & Problem Resolutions |
| :--- | :--- | :--- |
| **v022** | 2026-10-11 | Full version history audit, codified 7 Iron Rules, Zero-Desync GitHub auto-update pipeline |
| **v021** | 2026-10-11 | Whisper Repetition Loop Guard, prompt vocabulary cap (12 terms max), auto-update endpoint verification |
| **v020** | 2026-10-10 | Desktop installer preservation during uninstallation, complete `%LOCALAPPDATA%\GIN-Voice` purge |
| **v019** | 2026-10-10 | Multi-tier process termination (`taskkill`, PowerShell, `wmic`), embedded uninstaller rebuild |
| **v018** | 2026-10-10 | Strict Version Increment Rule: every code/documentation edit increases version number |
| **v017** | 2026-10-10 | Real-time bilingual EN/RU GUI switcher, 200ms audio buffer flush for trailing speech, Windows Installed Apps registration |
| **v016** | 2026-10-10 | "Check for Updates" context menu item, tray menu freeze prevention, working directory cleanup |
| **v015** | 2026-10-10 | All-in-one single binary installer, English-first default, auto-opening HTML setup guide |
| **v014** | 2026-10-10 | Slate Gray Cyberpunk theme, standalone native uninstaller `Uninstall.exe` with 90-char ANSI styling |
| **v013** | 2026-10-10 | 1-click in-app auto-updater with 100% preservation of user API keys and custom dictionary |
| **v012** | 2026-10-10 | Anti-hallucination filter (`(music)`, `(applause)`, etc.), silence threshold calibration |
| **v011** | 2026-10-10 | Gentle audio chimes for start/stop, default `F4` hotkey, 18-language balanced grid, `D:\AI\BASE` path |
| **v010** | 2026-10-10 | High-contrast white checkbox styling in dark theme, multi-language dynamic transcription |
| **v009** | 2026-10-10 | Zero-Key architecture (no hardcoded keys), direct MEGA cloud desktop sync, embedded PE icon |
| **v008** | 2026-10-10 | Recognition priority languages (EN/CS/RU), streamlined context menu |
| **v007** | 2026-10-10 | Event-Driven WaveIn PCM audio capture (`CALLBACK_EVENT`), non-blocking keyboard listener, 32bpp DIB icons |
| **v006** | 2026-10-10 | Russian transcription character encoding fix, floating HUD status overlay, larger typography |
| **v005** | 10.10.2026 | Direct WaveIn PCM without third-party dependencies, `SHBrowseForFolderW` directory picker |
| **v004** | 2026-10-10 | `GetAsyncKeyState` hardware listener, plain-text key storage, suppressed Windows balloon notifications |
| **v003** | 2026-10-10 | Signature microphone icon, dynamic red recording state, API key test button |
| **v002** | 2026-10-10 | Low-level keyboard hook, Win32 Settings dialog, folder chooser, 20 icons showcase |
| **v001** | 2026-10-10 | Initial release: native Windows speech-to-text client powered by Groq Whisper API |

---

## 🔬 In-Depth Analysis of Problems & Hard-Learned Solutions

### 🔴 Release v022 (2026-10-11)
* **Problem:** Release desynchronization between MEGA Cloud Desktop and GitHub `main` branch. The user had the latest setup executable on Desktop, but right-clicking the tray icon and selecting "Check for Updates" resulted in "You have the latest version".
* **Root Cause:** The compiled binary was uploaded to MEGA Desktop, but git commit and `git push` of `version.json` and `GIN-Voice.exe` were not executed. The in-app updater queries the GitHub raw endpoint, which still reported the previous version.
* **Solution:**
  1. Established the **Zero-Desync Pipeline**: uploading to MEGA is strictly forbidden until `git push origin main` succeeds and `curl` verifies `raw.githubusercontent.com`.
  2. Created this complete English `CHANGELOG.md`.
  3. Codified 7 Iron Rules in `RULES.md` to prevent regressions.

---

### 🔴 Release v021 (2026-10-11)
* **Problem 1 (Whisper Attention Loop):** On longer phrases or natural pauses, Whisper Large v3 occasionally entered an attention decoder loop, repeatedly generating words from the system context prompt (such as `GIN-Voice, GIN-Cinema...`) or looping the final spoken phrase.
* **Solution 1:** Added `removeRepetitiveLoops()` to `cleanHallucinations()`. The function uses regular expressions and n-gram analysis to strip trailing spam bursts and repeated phrase patterns (1–4 words repeated $\ge 2$ times).
* **Problem 2 (Context Overload):** A large list of dictionary terms in the `prompt` parameter degraded transcription accuracy.
* **Solution 2:** Case-insensitive deduplication and strict capping of vocabulary terms to a maximum of 12 terms.

---

### 🔴 Release v020 (2026-10-10)
* **Problem:** Running `Uninstall.exe` deleted the setup `.exe` file from the user's Desktop, leaving them unable to reinstall without re-downloading.
* **Solution:** Refactored the uninstaller to strictly target shortcuts (`.lnk`), leaving all setup executables on Desktop and cloud folders untouched.
* **Problem 2 (File Lock on Exit):** Windows reported access denied when attempting to delete the application folder immediately upon termination.
* **Solution 2:** Implemented a detached batch script (`del_after.bat`) that waits 1000ms for parent process exit before completely deleting `%LOCALAPPDATA%\GIN-Voice`.

---

### 🔴 Release v019 (2026-10-10)
* **Problem:** A standard `taskkill` invocation sometimes left audio threads or background goroutines lingering.
* **Solution:** Developed a robust 4-tier process termination pipeline:
  1. `taskkill /F /IM GIN-Voice.exe /T`
  2. `taskkill /F /FI "IMAGENAME eq GIN-Voice*"`
  3. PowerShell `Get-Process -Name 'GIN-Voice*' | Stop-Process -Force`
  4. WMIC fallback `wmic process where name like 'GIN-Voice%' call terminate`.

---

### 🔴 Release v018 (2026-10-10)
* **Problem:** Minor code and documentation adjustments were pushed without updating version constants, causing caching issues and confusion over deployed binaries.
* **Solution:** Instituted the Strict Version Increment Rule: every change, however small, increments the version number across all project files.

---

### 🔴 Release v017 (2026-10-10)
* **Problem 1 (Dropped Trailing Words):** Releasing the hotkey quickly after speaking sometimes caused the last spoken word to be clipped.
* **Root Cause:** Aggressive silence trimming in the audio capture pipeline discarded the final 150–200ms.
* **Solution 1:** Added a mandatory 200ms audio buffer flush before stopping recording, ensuring complete word capture.
* **Problem 2 (Dynamic Language Switching):** Switching between English and Russian required restarting the application.
* **Solution 2:** Implemented in-memory dynamic Win32 control re-rendering, allowing instant UI language changes with immediate persistent storage in `config.json`.
* **Problem 3 (Windows Integration):** The app did not show up in the Windows 10/11 "Installed Apps" list.
* **Solution 3:** Added full registry registration under `HKCU\Software\Microsoft\Windows\CurrentVersion\Uninstall\GIN-Voice`.

---

### 🔴 Release v016 (2026-10-10)
* **Problem:** System tray popup menu occasionally became unresponsive or remained visible after clicking outside.
* **Solution:** Implemented Microsoft Win32 best practices for notification icons: calling `SetForegroundWindow(hwndMain)` prior to `TrackPopupMenuEx` and posting `WM_NULL` immediately following menu dismissal.

---

### 🔴 Release v013 (2026-10-10)
* **Problem:** In-app updates risked overwriting existing user configurations and custom terminology dictionaries.
* **Solution:** Engineered the Zero-Data-Loss In-Place Update pattern. The updater exclusively downloads and overwrites `GIN-Voice.exe`, preserving `config.json` and `dictionary.json` completely.

---

### 🔴 Release v007 (2026-10-10)
* **Problem:** Polling audio buffers generated unnecessary CPU usage.
* **Solution:** Switched to event-driven audio capture via `waveInOpen` with `CALLBACK_EVENT`. Background threads remain suspended until the hardware triggers a completion event.
