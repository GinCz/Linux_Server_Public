# 🎙️ GIN-Voice [v029]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v029`  
> *Changelog:* [CHANGELOG.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/CHANGELOG.md) | *Rules:* [RULES.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/RULES.md)  

---

## 🎯 What's New in v029
* **Universal Default Hotkey F4:** Replaced legacy combinations with the universally accessible single key **`F4`** across defaults, fallback logic, single-instance dialogs, and user guides.
* **Owner-Drawn True Flag Graphics (BS_OWNERDRAW):** Fixed Windows fallback rendering of emoji flags (`GB EN` / `RU RU`) by implementing full GDI owner-drawn button graphics:
  - **England Flag:** St George's Cross (Crisp white field with authentic red cross) and clear "EN" label.
  - **Russian Flag:** Russian tricolor (White, Blue `#0039A6`, Red `#D52B1E` horizontal stripes) and clear "RU" label.
  - **Active State Border:** Cyan accent frame highlighting the currently active interface language.
* **Guaranteed Embedded PE Installer Icon:** Continuous validation of multi-resolution embedded PE icon resources (`.rsrc`).

---

## 📦 Distribution
* `GIN-Voice_Setup_v029.exe` — Single-File Self-Extracting Installer, Application & Uninstaller (Deployed to MEGA Desktop).
* `setup_guide.html` — Visual HTML guide with bilingual EN/RU tabs.
* `dictionary.json` — Custom vocabulary replacements.
* `version.json` / `version.txt` — Release metadata.
