# 🎙️ GIN-Voice [v027]

> **High-Speed Multilingual Voice-to-Text Desktop Tool for Windows 10/11**  
> *Author:* VladiMIR+AI (Vladimir Bulantsev - [GinCz ↗](https://github.com/GinCz))  
> *Version:* `v027`  
> *Changelog:* [CHANGELOG.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/CHANGELOG.md) | *Rules:* [RULES.md ↗](https://github.com/GinCz/Windows_scripts/blob/main/Windows/GIN-Voice/RULES.md)  

---

## 🎯 What's New in v027
* **Owner-Drawn Font Dropdown (WYSIWYG Font Selector):** Replaced manual font text input with an interactive Win32 combobox (`CBS_DROPDOWNLIST | CBS_OWNERDRAWFIXED | CBS_HASSTRINGS`). It dynamically enumerates all installed system fonts (`EnumFontFamiliesExW`) alongside curated popular typography (Comfortaa, Segoe UI, Bahnschrift, Cascadia Code, Consolas, Arial, Impact, Georgia, etc.).
* **Live Font Preview in Dropdown:** Every single font name in the dropdown list is rendered directly using its own typeface and style with GDI font caching. Selecting any font instantly reflects on the active on-screen HUD in real time.
* **Streamlined Language Switcher:** Settings window header now features clean, compact, flag-branded language switch buttons: `🇬🇧 EN` and `🇷🇺 RU`.
* **Guaranteed Embedded PE Installer Icon:** Verified `.rsrc` section embedding (370 KB) containing multi-resolution DIB icon resources for all installer and runtime executables (`GIN-Voice.exe`, `GIN-Voice_Setup_v027.exe`).

---

## 📦 Distribution
* `GIN-Voice_Setup_v027.exe` — Single-File Self-Extracting Installer, Application & Uninstaller (Deployed to MEGA Desktop).
* `setup_guide.html` — Visual HTML guide with bilingual EN/RU tabs.
* `dictionary.json` — Custom vocabulary replacements.
* `version.json` / `version.txt` — Release metadata.
