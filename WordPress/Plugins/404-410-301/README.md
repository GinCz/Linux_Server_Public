# 🛡️ 404-410-301 (SEO 404/410 + Auto-Redirect & Maintenance Mode) (VladiMIR+AI✅)

> **Part of the VladiMIR+AI WordPress Plugin Suite**  
> *Repository:* [GinCz/plugins ↗](https://github.com/GinCz/plugins) • [Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public)  
> *Author:* **VladiMIR (GinCz) + AI**  
> *License:* GPL-2.0-or-later  
> *Version:* `2026-10__1.33`  
> *Tags:* 404, 410, 503, 200, 301, 302, seo, maintenance-mode, under-construction, redirect, countdown, zero-bloat, vladimir-ai

---

## 📋 Overview

**404-410-301** is an ultra-lightweight, zero-bloat dual-engine solution for WordPress designed for high-performance production sites. It provides:
1. **SEO-Compliant 404/410 Error Handler:** Delivers authentic HTTP 404 (Not Found) or 410 (Gone) headers to search engine crawlers (Google, Yandex, Bing, Seznam) while smoothly redirecting human visitors to the homepage or custom URL via a sleek live countdown card.
2. **Flexible Maintenance / Under Construction Engine:** Allows site administrators to take the site offline with a single click, serving customizable HTTP status codes (**503 Service Unavailable**, **404 Not Found**, **410 Gone**, **200 OK**, or **302 Found**). It supports multi-language messaging (**Russian**, **English**, **Czech**, or **Auto-Detect**), optional custom messages (*"Сайт в разработке. Зайдите, пожалуйста, позже."* / *"Site under maintenance. Please check back later."*), and optional smooth countdown auto-redirection to a partner/external domain (e.g. `https://4ton-96.ru/`). Authenticated administrators retain full unrestricted access to the WordPress frontend and backend.

---

## ⚡ Key Features

### 🔀 1. Intelligent 404 / 410 Error Management
* **True HTTP Status Codes:** Eliminates dangerous "Soft 404" indexing penalties by immediately serving authentic `404 Not Found` or `410 Gone` HTTP headers along with `noindex, nofollow` robot directives.
* **Smooth Visitor Redirection:** Human visitors see a clean, responsive glassmorphic countdown interface (default 5s) that automatically redirects them to the homepage or a designated fallback URL.
* **Instant Direct Action:** Includes a one-click "Go Now" button and an optional "Stay on Page" button to pause the countdown timer.

### 🛠️ 2. Integrated Maintenance & Under Construction Engine
* **Single-Click Activation:** Enable or disable maintenance mode directly from the WordPress admin panel without needing heavy external maintenance plugins.
* **Selectable HTTP Status Codes:** Choose between:
  - `503 Service Unavailable` *(Recommended for SEO during temporary maintenance — includes `Retry-After: 600` header)*
  - `404 Not Found` *(Standard page removal)*
  - `410 Gone` *(Permanent removal)*
  - `200 OK` *(Standard page display)*
  - `302 Found` *(Temporary Redirect)*
* **Multilingual Messaging & Language Selection:**
  - 🌐 **Auto-Detect:** Automatically adapts to visitor browser / WordPress locale.
  - 🇷🇺 **Russian (RU):** *"Сайт в разработке. Зайдите, пожалуйста, позже."*
  - 🇬🇧 **English (EN):** *"Site under maintenance. Please check back later."*
  - 🇨🇿 **Czech (CS):** *"Web je ve výstavbě. Navštivte nás prosím později."*
  - ✏️ **Custom Message Field:** Override with your own custom announcement.
* **Optional Redirect or Static Splash Card:**
  - If a redirect URL is specified: Visitors see a countdown timer and are smoothly routed to the target URL (e.g. `https://4ton-96.ru/`).
  - If redirect URL is empty: Visitors see a clean, static informative maintenance card without auto-redirection.
* **Admin Whitelist Bypass:** Administrators and users with `manage_options` permissions bypass the maintenance screen completely and can browse, test, and edit pages in real time.
* **Cron & API Safe:** Automatic bypass for WordPress Cron (`wp-cron.php`), WP-CLI commands, and standard login endpoints (`wp-login.php`).

### 💎 3. Performance & Architecture
* **Zero Database Tables:** Uses WordPress native options API (`_vladimir_404_settings`) — creates no extra SQL tables and generates zero overhead.
* **Zero Logging Bloat:** Does not pollute MySQL or disk logs with bot request tables.
* **Zero External Dependencies:** Built with pure inline CSS and vanilla JavaScript. No jQuery, no external fonts, no external CDN tracking scripts.
* **Dark / Glassmorphic UI:** Modern responsive design with glassmorphism backdrop effects, crisp typography, and smooth CSS transitions.

---

## ⚙️ Configuration Options

Navigate to **WordPress Admin → Settings → 🔀 404-410-301**:

### Section 1: Maintenance Mode (Сайт в разработке)
| Setting | Description | Default |
| :--- | :--- | :--- |
| **Enable Maintenance Mode** | Master toggle to activate public under-construction screen | `Disabled (0)` |
| **HTTP Status Code** | Response code (`503 Service Unavailable`, `404`, `410`, `200 OK`, `302`) | `503` |
| **Display Language** | Choose fixed language (`RU`, `EN`, `CS`) or `Auto-Detect` | `Auto-Detect` |
| **Custom Maintenance Message** | Custom announcement text (leave empty for default) | `Empty (Standard)` |
| **Maintenance Redirect URL** | Target URL where visitors will be routed (e.g. `https://4ton-96.ru/`) | `Empty (No redirect)` |
| **Countdown Duration** | Delay in seconds (0 for static splash page without timer, 1–60s with live timer) | `5 seconds` |
| **Allow Cancel** | Display "Stay on Page" button next to countdown | `Enabled` |

### Section 2: Non-Existent Pages (404 / 410 Error Pages)
| Setting | Description | Default |
| :--- | :--- | :--- |
| **HTTP Status Code** | `404 Not Found` (temporary removal) or `410 Gone` (permanent removal) | `404 Not Found` |
| **Countdown Duration** | Delay before auto-redirecting broken URLs (0–60s) | `5 seconds` |
| **404 Redirect Target URL** | Custom target URL for broken links (leave empty for site homepage) | `Empty (Homepage)` |
| **Allow Cancel** | Display "Stay on Page" button next to countdown | `Enabled` |

---

## 🔄 Replaces Bloated Plugins
This lightweight module replaces and outperforms:
* `Under Construction Page` / `WP Maintenance Mode` / `Coming Soon Page`
* `404 to 301 - Redirect, Log and Notify 404 Errors`
* `All 404 Redirect to Homepage`
* `Redirection` (for 404 management)

---

## 📦 Automated Suite Updates

Updates are managed via the built-in `vladimir-ai-updater.php` client linked to the central repository manifest (`https://raw.githubusercontent.com/GinCz/plugins/main/updates.json`). Every release is cryptographically validated and delivered directly through standard WordPress update mechanisms.
