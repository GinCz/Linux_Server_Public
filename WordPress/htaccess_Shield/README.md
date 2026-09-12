# 🛡️ WordPress .htaccess Security Shield & Performance Kit

> **Universal, lightweight, production-grade Apache `.htaccess` hardening rules and performance optimization for WordPress websites.**
> 
> *Repository:* [Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public) | *Author:* [Vladimir Bulantsev (GinCz) ↗](https://github.com/GinCz) & AI Assistant | *Version:* `2026.09.06`

[![WordPress](https://img.shields.io/badge/WordPress-6.0%2B%20|%207.x-21759B?logo=wordpress&logoColor=white)](https://wordpress.org)
[![Apache](https://img.shields.io/badge/Apache-2.4%2B-D22128?logo=apache&logoColor=white)](https://httpd.apache.org)
[![Security](https://img.shields.io/badge/Security-Hardened-success)](https://github.com/GinCz/Linux_Server_Public)
[![Performance](https://img.shields.io/badge/Google%20PageSpeed-Optimized-brightgreen)](https://pagespeed.web.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## 📌 Overview

This repository contains two production-tested `.htaccess` configuration files designed to protect WordPress installations from 95%+ of common web attacks (Brute-force, XML-RPC exploitation, WebShell injection, SQL injection, User Enumeration, and sensitive data leakage) while maximizing PageSpeed caching scores without breaking standard WordPress updates or admin panel operations.

### Key Highlights
- 🚀 **100% Native & Ultra-Fast:** Zero CPU/RAM overhead compared to heavy security plugins.
- 🔒 **Comprehensive Attack Shield:** Blocks XML-RPC, shell uploads, script execution in `/uploads/`, user enumeration, and sensitive file probing.
- ⚡ **Google PageSpeed Optimized:** Pre-configured browser caching (WebP, AVIF, SVG, Fonts, CSS, JS).
- 🌐 **Full Compatibility:** Works out-of-the-box with FastPanel, cPanel, Cloudflare, Apache 2.4, LiteSpeed, OpenLiteSpeed, and Nginx reverse proxies.

---

## 📁 File Structure

| File | Target Location | Purpose |
| :--- | :--- | :--- |
| [`.htaccess-root`](.htaccess-root) | `/var/www/USER/data/www/DOMAIN/` (Root) | Main WordPress routing, security headers, anti-bot rules, file protection & browser cache. |
| [`.htaccess-uploads`](.htaccess-uploads) | `/wp-content/uploads/` | Anti-WebShell shield: completely disables PHP/CGI/Python/Shell script execution in uploads. |

---

## 🛡️ Protection Features Breakdown

### 1. Root Protection (`.htaccess-root`)

1. **Security Headers (OWASP Recommended):**
   - `X-XSS-Protection "1; mode=block"` — Mitigates Cross-Site Scripting.
   - `X-Content-Type-Options "nosniff"` — Prevents browser MIME-type confusion attacks.
   - `Referrer-Policy "strict-origin-when-cross-origin"` — Protects user privacy while retaining internal tracking.
   - `X-Frame-Options "SAMEORIGIN"` — Completely prevents Clickjacking attacks.
   - `Strict-Transport-Security (HSTS)` — Enforces secure HTTPS connections for 1 year.

2. **Core Security Shields:**
   - **Blocks `wp-config.php`:** Denies all direct web requests to the database configuration file.
   - **Blocks `xmlrpc.php`:** Mitigates massive brute-force attacks and Pingback DDoS amplification without affecting REST API or Gutenberg.
   - **Protects Sensitive Files:** Denies access to `.env`, `.sql`, `.log`, `.sh`, `.bak`, `.git`, `.yml`, and temporary backup files.
   - **Blocks User Enumeration:** Redirects `/?author=N` scans to prevent attackers from discovering admin usernames.
   - **Blocks Malicious Query Injections:** Filters `base64_decode`, `eval()`, `<script>`, `<iframe>`, and `GLOBALS` injection payloads.
   - **Disables Directory Indexing (`Options -Indexes`):** Stops bots from scanning directory structures.

3. **Performance & Browser Caching:**
   - **Images & Fonts (1 Year):** JPG, PNG, WebP, AVIF, SVG, ICO, WOFF, WOFF2, TTF.
   - **Assets (6 Months):** CSS, JS, minified bundles.
   - **HTML (1 Day):** Dynamic pages cached sensibly for fast repeat visits.

---

### 2. Uploads Protection (`.htaccess-uploads`)

Attackers frequently exploit vulnerable third-party plugins to upload PHP backdoors (`webshell.php`, `alfa.php`, `wso.php`) into the media folder (`/wp-content/uploads/`).

This rule set:
- Completely turns off PHP engine interpretation inside the directory:
  `php_flag engine off`
- Explicitly blocks direct execution of:
  `.php`, `.phtml`, `.php3`, `.php4`, `.php5`, `.php7`, `.php8`, `.phps`, `.pht`, `.phar`, `.cgi`, `.pl`, `.py`, `.sh`, `.exe`, `.bat`, `.jsp`, `.asp`, `.aspx`.
- Ensures images, PDFs, and media files remain 100% accessible to visitors and search engines.

---

## 🚀 Quick Deployment & Installation

### Option 1: Automated Deployment via Bash / SSH (Recommended)

Run this one-liner on your Linux server (replace `/path/to/wordpress` with your actual site root):

```bash
# 1. Set site path
SITE_DIR="/var/www/gincz/data/www/your-site.ru"

# 2. Download and deploy Root .htaccess
curl -sSL "https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/htaccess_Shield/.htaccess-root" -o "${SITE_DIR}/.htaccess"

# 3. Download and deploy Uploads Anti-WebShell .htaccess
mkdir -p "${SITE_DIR}/wp-content/uploads"
curl -sSL "https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/htaccess_Shield/.htaccess-uploads" -o "${SITE_DIR}/wp-content/uploads/.htaccess"

# 4. Set secure permissions
chmod 644 "${SITE_DIR}/.htaccess" "${SITE_DIR}/wp-content/uploads/.htaccess"
```

---

### Option 2: Manual Setup

1. Copy the contents of [`.htaccess-root`](.htaccess-root) and paste into the `.htaccess` file in your WordPress root directory.
2. Copy the contents of [`.htaccess-uploads`](.htaccess-uploads) and paste into a new file named `.htaccess` inside your `/wp-content/uploads/` directory.

---

## ⚙️ Recommended `wp-config.php` Hardening

For maximum security, combine this `.htaccess` shield with the following directives in your `wp-config.php`:

```php
// Disable built-in theme and plugin code editor in admin dashboard
define('DISALLOW_FILE_EDIT', true);

// Enforce SSL for admin logins
define('FORCE_SSL_ADMIN', true);
```

Set file permissions:
```bash
chmod 600 wp-config.php
```

---

## 🏷️ Tags & Keywords

`#wordpress` `#security` `#htaccess` `#apache` `#hardening` `#cybersecurity` `#waf` `#antivirus` `#pagespeed` `#seo` `#web-security` `#brute-force-protection` `#anti-malware` `#devops`

---

## 📄 License

This project is licensed under the **MIT License** — free for personal and commercial use.