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

## 📦 Plugins Catalog (7 Modules)

| # | Module / Directory | Archive (.zip) | Replaces | Key Features |
| :-: | :--- | :--- | :--- | :--- |
| **1** | [**404-301**](./404-301/) | `404-301-(VladiMIR+AI).zip` | *404 to 301, Redirection* | Permanent 301 redirect from 404 pages to homepage. 0 database tables, 0 log clutter. |
| **2** | [**classic-editor**](./classic-editor/) | `classic-editor-(VladiMIR+AI).zip` | *Classic Editor* | Familiar Classic Editor interface with Visual and Code tabs. Disables Gutenberg. |
| **3** | [**clean-head-meta**](./clean-head-meta/) | `clean-head-meta-(VladiMIR+AI).zip` | *Head Meta Data, WP Hide* | Cleans `<head>` clutter, hides WP version, removes pingbacks/emojis, adds `VladiMIR` author. |
| **4** | [**disable-update-emails**](./disable-update-emails/) | `disable-update-emails-(VladiMIR+AI).zip` | *Manage Notification E-mails* | Completely blocks automatic core, plugin, and theme update notification email spam. |
| **5** | [**image-resizer**](./image-resizer/) | `image-resizer-(VladiMIR+AI).zip` | *Imsanity, Resize Images* | Automatically scales large uploads down to 1600×1600 px with crisp 95% JPEG quality. |
| **6** | [**translit-cyr-lat**](./translit-cyr-lat/) | `translit-cyr-lat-(VladiMIR+AI).zip` | *Cyr-To-Lat, RusToLat* | Fast SEO transliteration of Russian, Ukrainian, and Czech/Slovak letters into clean Latin slugs. |
| **7** | [**mu-redirect-404**](./mu-redirect-404/) | `wp-redirect-404-to-homepage-(VladiMIR+AI).zip` | *Must-Use 404 Redirect* | Must-Use version for automatic background deployment in `wp-content/mu-plugins/`. |

---

## 🚀 Core Advantages

1. **Zero Database Bloat:** None of these plugins create extra MySQL tables or pollute `wp_options`.
2. **Sub-millisecond Execution:** Average execution overhead is under **0.5 ms**.
3. **Zero Configuration Needed:** Smart default behavior out of the box.
4. **AdBlock Safe:** Free of external scripts, trackers, or React mount containers that break in ad blockers.

---

## 🛠️ Installation Instructions

### Option A: Standard Installation via WordPress Admin
1. Open the plugin folder above and download the corresponding `.zip` file.
2. In WordPress Admin, navigate to: **Plugins ➔ Add New ➔ Upload Plugin**.
3. Upload the `.zip` archive and click **Install Now**, then **Activate Plugin**.

### Option B: Must-Use Mode (Automatic)
Copy the `.php` file directly into `/wp-content/mu-plugins/` on your server. The plugin runs automatically in the background without appearing in the standard plugins list.
