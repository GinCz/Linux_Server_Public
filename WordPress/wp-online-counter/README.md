# WP Online Active Users (VladiMIR+AI)

**Version:** 2026.09.12  
**Author:** VladiMIR (GinCz)  
**License:** GPL-2.0-or-later  
**Replaces:** Online Active Users, WP Online Counter, User Activity Tracking plugins  

## Purpose

Provides a clean, ultra-lightweight online activity monitor directly in the WordPress Admin Bar. Before performing site updates, database migrations, or theme edits, administrators can verify in real-time whether administrators, shop managers, editors, or customers are currently active on the website.

## Key Features

1. **Admin Bar Overview:** Displays live visitor counts in the top toolbar:
   - 👥 Total Online (Logged-in users + Guest visitors)
   - 🔴 Administrators (`administrator`)
   - 📋 Editors (`editor`)
   - 🛒 Shop Managers (`shop_manager`)
2. **Direct Navigation:** Clicking the top toolbar badge opens the full Users list (`users.php`). The submenu dropdown provides instant direct links to filtered role views.
3. **User List Status Column:** Adds a `🟢 Online` status column in `wp-admin/users.php` showing whether the user is currently online (within 5 minutes) or when they were last active (e.g. `2 minutes ago`), with full column sorting support.
4. **Zero Bloat & Safe Uninstall:** Creates no custom MySQL tables. DB activity timestamps are throttled to once per minute to preserve server performance. Uninstallation via WordPress Admin completely purges all user meta and transients.
5. **Multilingual (EN / RU / CS):** Native translations for English, Russian, and Czech in WordPress Admin and plugin listings.

## Installation

### Option A: Upload ZIP (Recommended)
1. Download `wp-online-counter.zip` from `_ZIP_INSTALLERS/`.
2. In WordPress Admin, go to **Plugins** → **Add New** → **Upload Plugin**.
3. Select `wp-online-counter.zip` and click **Install Now** → **Activate**.

### Option B: Manual Directory Copy
1. Copy the `wp-online-counter` folder into `wp-content/plugins/`.
2. Navigate to **Plugins** in WordPress Admin and click **Activate**.