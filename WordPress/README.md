# ⚡ WordPress Ultra-Light Plugins Suite (VladiMIR+AI)

A collection of ultra-lightweight, secure, and high-performance micro-plugins for **WordPress**, engineered by **VladiMIR (GinCz)** and **Antigravity AI**.

These plugins were built to replace bloated third-party plugins from WordPress.org that clutter MySQL databases, generate noisy bot logs, ship vulnerable React/JS dashboards, or display annoying "Go Pro" upgrade banners.

---

## 📜 Author & Project Attribution Rules

- **Primary Author:** `VladiMIR (GinCz)` *(Always write as VladiMIR without last name)*
- **AI Co-Developer:** `Antigravity AI`
- **Version Format:** `YYYY.MM.DD` (Release Date)
- **Branding Tag:** `(VladiMIR+AI)`

---

## 📦 Plugins Catalog (10 Modules)

| # | Module / Directory | Source | Replaces | Key Features |
| :-: | :--- | :--- | :--- | :--- |
| **1** | [**404-410-301**](./404-410-301/) | PHP + README | *404 to 301, Redirection* | Returns a true HTTP 404 for SEO and presents a visitor-facing homepage redirect after 5 seconds. |
| **2** | [**wp-redirect-404-to-homepage**](./wp-redirect-404-to-homepage/) | PHP + README | *All 404 Redirect to Homepage* | Instant direct 301 server redirect of any 404 URL directly to homepage without countdown. |
| **3** | [**classic-editor**](./classic-editor/) | PHP + README | *Classic Editor, Advanced Editor Tools* | Disables Gutenberg and adds native formatting, paste-as-text, and table controls. |
| **4** | [**clean-head-meta**](./clean-head-meta/) | PHP + README | *Head Meta Data, WP Hide* | Cleans `<head>` clutter, hides WP version, removes pingbacks/emojis, adds `VladiMIR` author. |
| **5** | [**disable-update-emails**](./disable-update-emails/) | PHP + README | *Manage Notification E-mails* | Completely blocks automatic core, plugin, and theme update notification email spam. |
| **6** | [**image-resizer**](./image-resizer/) | PHP + README | *Imsanity, Resize Images* | Automatically scales large uploads down to 1600×1600 px with crisp 95% JPEG quality. |
| **7** | [**translit-cyr-lat**](./translit-cyr-lat/) | PHP + README | *Cyr-To-Lat, RusToLat* | Fast SEO transliteration of Russian, Ukrainian, and Czech/Slovak letters into clean Latin slugs. |
| **8** | [**wp-test-email-micro**](./wp-test-email-micro/) | PHP + README | *WP Test Email* | Administrator-only on-demand email delivery test; no database logging or global mail interception. |
| **9** | [**wp-allow-html-cats**](./wp-allow-html-cats/) | PHP + README | *Allow HTML in Category Descriptions* | Allows safe formatting HTML in taxonomy descriptions without disabling XSS filtering. |
| **10** | [**wp-auto-sku**](./wp-auto-sku/) | PHP + README | *Easy Auto SKU Generator* | **WP WooCommerce Auto SKU-5 Digits** assigns five-digit product SKUs and provides an intentional full-store regeneration tool. |


---

## 🚀 Core Advantages

1. **Zero Database Bloat:** None of these plugins create extra MySQL tables or pollute `wp_options`.
2. **Sub-millisecond Execution:** Average execution overhead is under **0.5 ms**.
3. **Multilingual (EN / RU / CS):** Built-in seamless translation for English, Russian (`ru_RU`), and Czech (`cs_CZ`) in WordPress Admin, descriptions, and UI tools.
4. **Zero Configuration Needed:** Smart default behavior out of the box.
5. **AdBlock Safe:** Free of external scripts, trackers, or React mount containers that break in ad blockers.

---

## 🛠️ Installation Instructions

### Option A: Upload Ready .ZIP Archive via WordPress Admin (Recommended)
1. Grab the pre-built `.zip` installer from [`_ZIP_INSTALLERS/`](./_ZIP_INSTALLERS/).
2. In WordPress Admin, navigate to **Plugins** → **Add New** → **Upload Plugin**.
3. Choose the `.zip` file (e.g. `image-resizer.zip`, `classic-editor.zip`, etc.) and click **Install Now** → **Activate Plugin**.

### Option B: Direct Copy to Plugins Folder
1. Copy the required plugin directory into `/wp-content/plugins/`.
2. In WordPress Admin, navigate to **Plugins** and click **Activate**.
3. Each directory contains its own README with function, limits, security model, and verification steps.

