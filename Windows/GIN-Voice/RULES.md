# 🪐 Inviolable Architectural Rules & Release Protocol: GIN-Voice

> **Project:** GIN-Voice by VladiMIR+AI  
> **Repository:** [Linux_Server_Public / Windows / GIN-Voice ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/Windows/GIN-Voice)  
> **Upstream:** [Windows_scripts / GIN-Voice ↗](https://github.com/GinCz/Windows_scripts/tree/main/Windows/GIN-Voice)  
> **Owner:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Anti-Gravity AI  
> **Status:** Strictly Mandatory for All Modifications and Builds  

---

## ⚡ 1. Strict Version Increment Rule
1. **Every single modification bumps the version:**
   - Any code change, bug fix, UI tweak, optimization, configuration update, or documentation edit **MUST increment the version number** (e.g., `v021` -> `v022`).
2. **Synchronized version updates across all files:**
   - The version string must be updated in tandem across:
     - `AppVersion` and `AppTitle` constants in `main.go`;
     - `version.json` and `version.txt`;
     - `CHANGELOG.md`, `README.md`, `HELP.md`, and `setup_guide.html`.

---

## 🌐 2. Dual-Target Release & GitHub Synchronization Protocol (Mandatory GitHub Recording)
1. **Synchronous GitHub Commitment:**
   - **EVERY NEW VERSION MUST BE RECORDED ON GITHUB IN ADDITION TO THE USER'S DESKTOP.**
   - Deploying exclusively to Vladimir's Desktop via MEGA while skipping GitHub push is **STRICTLY FORBIDDEN**.
   - Both target repositories must be kept in lockstep:
     - Primary repository: `Windows_scripts` (`Windows/GIN-Voice/`)
     - Public suite repository: `Linux_Server_Public` (`Windows/GIN-Voice/`)
2. **In-App Auto-Updater Integrity (Zero-Desync):**
   - The application tray menu **"Check for Updates"** queries:  
     `https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice/version.json`
   - And downloads the updated binary from:  
     `https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice/GIN-Voice.exe`
   - If a binary is deployed to MEGA without first being pushed to GitHub, the running app queries GitHub, detects the old version string, and falsely claims *"You have the latest version"*.
3. **Strict Order of Release Operations (Release Pipeline):**
   1. Compile production binaries (`GIN-Voice.exe`, `GIN-Voice_Setup_vXXX.exe`, `GIN-Voice_vXXX.exe`).
   2. Synchronously update `version.json`, `version.txt`, and documentation files.
   3. **Execute `git commit` and `git push origin main` on GitHub**.
   4. **Verify raw endpoint with `curl`**:  
      `curl -s https://raw.githubusercontent.com/GinCz/Windows_scripts/main/Windows/GIN-Voice/version.json` returns `vXXX`.
   5. Clean previous versions and upload the new installer to MEGA Desktop (`/MEGA/DOCS/desktop/`).
   6. Desktop Purity Verification: exactly ONE versioned installer (`GIN-Voice_Setup_vXXX.exe`) is allowed on Desktop. Uploading icons (.ico), configs, scripts, portable copies, or build artifacts to Desktop is strictly prohibited. The icon is already embedded in the .exe binary. All build files and configuration templates are hosted exclusively on GitHub.
4. **Clean Public Repository Policy (No Binary Bloat):**
   - The public repository (`Linux_Server_Public/Windows/GIN-Voice/`) hosts **EXCLUSIVELY clean source code, resources, manifests, and documentation**.
   - **NO compiled `.exe` files, no unversioned binaries, no portable duplicates, and no standalone uninstaller `.exe` files** are stored in the public repository.
   - The compiled all-in-one setup executable is distributed directly to the user's Desktop via MEGA Cloud Sync.

---

## 🛑 3. Desktop Installer Preservation (Zero-Loss Uninstallation)
1. When running the uninstaller (`Uninstall.exe` or uninstall scripts), it is **CATEGORICALLY FORBIDDEN** to delete setup executables (`*.exe`) from the user's Desktop or cloud directories.
2. The uninstaller removes **ONLY shortcuts** (`GIN-Voice.lnk`), ensuring the user retains the installer to reinstall at any time with a single click.

---

## 🧹 4. Multi-Tier Process Termination & Guaranteed Clean Purge
1. Pre-uninstall termination must execute all 4 fallback methods:
   - `taskkill /F /IM GIN-Voice.exe /T`
   - `taskkill /F /FI "IMAGENAME eq GIN-Voice*"`
   - PowerShell `Get-Process -Name 'GIN-Voice*' | Stop-Process -Force`
   - WMIC `wmic process where name like 'GIN-Voice%' call terminate`.
2. Directory cleanup of `%LOCALAPPDATA%\GIN-Voice` must use a detached background script (`del_after.bat`) that waits 1000ms after parent exit to avoid Windows `Access Denied` locking errors.

---

## 🎙️ 5. Trailing Speech Buffer Protection
1. Aggressive silence trimming that cuts off the ends of spoken sentences is strictly prohibited.
2. A mandatory 200ms audio buffer flush is preserved before closing the `waveIn` stream, ensuring no trailing syllables or words are lost.

---

## 🧠 6. Whisper Attention Loop Guard & Prompt Sanitization
1. Context prompt vocabulary is **strictly capped at a maximum of 12 unique terms**. Prompt overloading causes decoder attention lock and hallucination loops.
2. The `cleanHallucinations()` pipeline must include `removeRepetitiveLoops()` to strip trailing brand bursts and repeated phrase patterns.

---

## 💾 7. User Data & Configuration Preservation (Zero-Data-Loss In-Place Update)
1. Any update—whether via the tray menu self-updater or by re-running `Setup_vXXX.exe`—must preserve `config.json` and `dictionary.json` 100%.
2. User API keys, hotkeys, HUD font selections, and custom vocabulary words are never overwritten.

---

## 🏷️ 8. Session & Topic Naming Convention
- Chat and session titles must always strictly follow: `GIN-Voice - <Short Task Description>`.
