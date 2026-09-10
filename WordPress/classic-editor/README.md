# Classic Editor Ultra-Light (VladiMIR+AI)

**Version:** 2026.09.11
**Author:** VladiMIR (GinCz)  
**License:** GPL-2.0-or-later  

---

### 📋 Description
Restores the familiar WordPress Classic Editor interface with Visual and Code (Text) tabs. It disables Gutenberg and adds a compact second row of native TinyMCE controls: format selector, clear formatting, paste as text, tables, horizontal line, quote, special character, undo, and redo.

### 🌐 Multilingual UI Support
This plugin includes dynamic native UI translation for:
- 🇬🇧 **English (en_US / en_GB)**: Default
- 🇨🇿 **Czech (cs_CZ)**: Auto-detected from user locale
- 🇷🇺 **Russian (ru_RU)**: Auto-detected from user locale

### 🔄 Replaces
Replaces **Classic Editor** and the narrow toolbar use case of **Advanced Editor Tools**. It deliberately does not allow arbitrary HTML attributes or add a settings dashboard.

### ⚙️ How It Works & Advantages
Completely disables Gutenberg block editor across all post types, restores classic widgets, and unloads heavy block CSS styles from frontend page loads.

### 🚀 Installation
1. Copy the `classic-editor` directory to `wp-content/plugins/`.
2. In WordPress Admin, open **Plugins** and activate **Classic Editor Ultra-Light**.
3. Deactivate the external **Classic Editor** and **Advanced Editor Tools** only after checking the editor on a staging page.
