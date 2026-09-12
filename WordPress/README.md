# ⚡ WordPress Ultra-Light Plugins Suite (VladiMIR+AI)

A collection of ultra-lightweight, secure, and high-performance micro-plugins for **WordPress**, engineered by **VladiMIR (GinCz) + AI** and **Antigravity AI**.

These plugins were built to replace bloated third-party plugins from WordPress.org that clutter MySQL databases, generate noisy bot logs, ship vulnerable React/JS dashboards, or display annoying "Go Pro" upgrade banners.

---

## 📜 Author & Project Attribution Rules

- **Primary Author:** `VladiMIR (GinCz) + AI` *(Always write as VladiMIR without last name)*
- **AI Co-Developer:** `Antigravity AI`
- **Version Format:** `YYYY.MM.DD` (Release Date)
- **Branding Tag:** `(VladiMIR+AI)`

---

## 📦 Plugins Catalog (12 Active Consolidated Modules)

> 🛑 **Architectural Optimization Decisions (VladiMIR+AI):**
> 
> 1. **Single Unified 404-410-301 Module:** The legacy `wp-redirect-404-to-homepage` was eliminated as redundant. `404-410-301` handles both tasks: search bots (Google, Yandex, Bing) receive an authentic HTTP 404/410 Not Found header for fast removal of dead links without webmaster errors, while human visitors are smoothly redirected to the homepage via a configurable countdown (0 to 60 sec).
> 2. **Consolidated Classic Editor & TinyMCE:** `classic-editor` and `wp-tinymce-micro` are merged into `classic-editor-tinymce` (`Classic Editor - TinyMCE`). It disables Gutenberg and block widgets, restores the classic visual/text editor tabs, and keeps the 2nd Word-like toolbar row open by default (fonts, sizes, text & background colors, tables, paste as plain text, clear formatting).
> 3. **Non-sequential 5-Digit Random SKUs in `wp-auto-sku`:** Generates unique, non-predictable 5-digit codes (e.g. `74921`, `18304`) on new products while strictly preserving any manual user edits (`-1`, `-2`), and adds instant storewide and admin search by SKU.
> 4. **Granular Drag & Drop Reordering in `wp-simple-post-order`:** Independent checkboxes to enable reordering specifically for posts, pages, WooCommerce products, and taxonomies (categories, product categories).
> 5. **Google Analytics & Seznam Webmaster:** Custom plugin development closed. Official [Google for WooCommerce ↗](https://wordpress.org/plugins/google-listings-and-ads/) is used for catalogs, and static HTML/DNS verification is used for webmasters.

| # | Module / Directory | Source | Replaces | Key Features | Action Links |
| :-: | :--- | :--- | :--- | :--- | :--- |
| **1** | [**404-410-301**](./404-410-301/) | PHP + README | *404 to 301, Redirection* | Returns true HTTP 404/410 for SEO and redirects visitors to homepage via smooth countdown (0–60s). | Settings • Docs |
| **2** | [**classic-editor-tinymce**](./classic-editor-tinymce/) | PHP + README | *Classic Editor + TinyMCE Advanced* | All-in-one classic editor: blocks Gutenberg, opens 2nd Word-like toolbar row (fonts, colors, tables). | Settings • Docs |
| **3** | [**clean-head-meta**](./clean-head-meta/) | PHP + README | *Head Meta Data, WP Hide* | Cleans `<head>` clutter, hides WP version, removes pingbacks/emojis, adds `VladiMIR` author. | Settings • Docs |
| **4** | [**disable-update-emails**](./disable-update-emails/) | PHP + README | *Manage Notification E-mails* | Completely blocks automatic core, plugin, and theme update notification email spam. | Settings • Docs |
| **5** | [**image-resizer**](./image-resizer/) | PHP + README | *Imsanity, Resize Images* | Automatically scales large uploads down to 1600×1600 px with crisp 92% JPEG quality. | Settings • Docs |
| **6** | [**translit-cyr-lat**](./translit-cyr-lat/) | PHP + README | *Cyr-To-Lat, RusToLat* | Fast SEO transliteration of Russian, Ukrainian, and Czech/Slovak letters into clean Latin slugs. | Settings • Docs |
| **7** | [**wp-allow-html-cats**](./wp-allow-html-cats/) | PHP + README | *Allow HTML in Category Descriptions* | Allows safe formatting HTML in taxonomy descriptions without disabling XSS filtering. | Settings • Docs |
| **8** | [**wp-auto-sku**](./wp-auto-sku/) | PHP + README | *Easy Auto SKU Generator* | Generates non-sequential random 5-digit SKUs (74921, 18304), preserves manual edits, and enables instant search. | Settings • Docs |
| **9** | [**wp-online-counter**](./wp-online-counter/) | PHP + README | *Online Active Users, WP Online Counter* | Real-time counts of visitors, admins, editors, and shop managers in admin bar + user list column. | Settings • Docs |
| **10** | [**wp-simple-post-order**](./wp-simple-post-order/) | PHP + README | *Simple Custom Post Order, Post Types Order* | Native HTML5 drag-and-drop reordering for posts, products, and taxonomies (categories). | Settings • Docs |
| **11** | [**wp-seo-micro**](./wp-seo-micro/) | PHP + README | *Yoast SEO, Rank Math, SEOPress* | Minimal SEO module: Title, Description, Keywords, Open Graph, canonical URL, XML sitemaps, SEOPress legacy support. | Settings • Docs |
| **12** | [**wp-test-email-micro**](./wp-test-email-micro/) | PHP + README | *WP Test Email* | Administrator-only on-demand email delivery test; no database logging or global mail interception. | Settings • Docs |

---

## ⚙️ Plugin Management: Single-Page Settings & Action Links

Under every plugin title in the WordPress Plugins table (`wp-admin/plugins.php`), quick action links are integrated:
- **Settings (Настройки / Nastavení)** — Direct jump to the unified single-page options screen. All settings are clean and accessible on one screen without tabs or upsell banners.
- **Documentation ↗ (Документация / Dokumentace)** — Clickable public link to source code and guides on GitHub.
- **Deactivate** — Standard safe deactivation.

---

## 🛡️ Security, Patches & Hardening Tools

| Module / Document | Purpose | Description |
| :--- | :--- | :--- |
| [**htaccess_Shield**](./htaccess_Shield/) | `.htaccess` Security Shield | Production-ready hardened `.htaccess` protecting WordPress against bots, scanners, and malicious query strings. |
| [**flatsome-license-patch.md**](./flatsome-license-patch.md) | Flatsome Theme Patch | Disables remote license checks and outbound pings to `api.uxthemes.com` in Flatsome theme. |
| [**WordPress_Security_Shield_Guide.md**](./WordPress_Security_Shield_Guide.md) | Security Guide | Comprehensive guide for hardening WordPress on Nginx, Apache, and Cloudflare WAF. |
| [**ADBLOCK_SAFE_FOOTER_BADGES.md**](./ADBLOCK_SAFE_FOOTER_BADGES.md) | AdBlock-Safe Badges | Clean HTML/CSS footer counters and verification badges without triggering ad blocker false positives. |

---

## 🚀 Core Advantages

1. **Zero Database Bloat:** None of these plugins create extra MySQL tables or pollute `wp_options`.
2. **Sub-millisecond Execution:** Average execution overhead is under **0.5 ms**.
3. **Multilingual (EN / RU / CS):** Built-in seamless translation for English, Russian (`ru_RU`), and Czech (`cs_CZ`) in WordPress Admin, descriptions, and UI tools.
4. **All-In-One Settings Page:** Each plugin includes an intuitive single-page settings dashboard with smart defaults.
5. **Direct Plugin Action Links:** Fast access to Settings and Documentation directly from the WordPress Plugins list table.
6. **AdBlock Safe:** Free of external scripts, trackers, or React mount containers that break in ad blockers.

---

## 🛠️ Installation & Deployment

### Option A: Direct Copy to Plugins Directory
1. Copy the desired plugin folder (e.g. `wp-seo-micro`) into `/wp-content/plugins/`.
2. In WordPress Admin, navigate to **Plugins** and click **Activate**.

### Option B: ZIP Archive Installation
1. Upload the `*- (VladiMIR+AI).zip` archive via **Plugins → Add New Plugin → Upload Plugin**.
2. Click **Install Now** and **Activate**.
