# 🛡️ Comprehensive WordPress Incident Analysis, Security Audit & `Shield_VladiMIR+AI` Architecture

> **In-depth guide covering incident investigations, exploit attack vectors, rapid diagnosis commands, and reference multi-tier WordPress hardening architecture.**
> 
> *Repository:* [Linux_Server_Public ↗](https://github.com/GinCz/Linux_Server_Public) | *Author:* VladiMIR (GinCz) & AI Assistant | *Incident Date:* `2026-09-06`

---

## 📌 1. Incident Background & Anatomy

In early September 2026, automated botnet attacks targeted several WordPress installations across server infrastructure (`RU-109` and `DE-222`).
A deep audit discovered **3 compromised sites**:
1. `prodvig-saita.ru` (Server `RU-109`) — 3 unauthorized administrator accounts injected (`vivienluby`, `w2s_1c85939f8e1f`, `w2s_72e62d40d5cb`), master administrator password modified.
2. `study-italy.eu` (Server `RU-109`) — **19 hidden administrators** injected (`root_e14b301`, `sys_4daedfc`, `wp2_b99b37cb`, `wp_service_RxR`, `yun_11`), core file `wp-admin/includes/update-core.php` tampered with.
3. `tatra-ural.ru` (Server `RU-109`) — Unauthorized administrator `bob_f59243e9e9d7` (`bob_f59243e9e9d7@bobresearchlabs.com`) injected.

---

## 🔍 2. How the Exploits Worked (Attack Vectors & Mechanics)

Attackers utilized a coordinated exploit chain executed automatically through distributed botnets:

### Vector #1: User Enumeration
* **Mechanism:** Bots send probes such as `/?author=1`, `/?author=2` or query the REST API endpoint `/wp-json/wp/v2/users`.
* **Outcome:** WordPress reveals the real administrative username (`admin`, `gincz`), lowering the bar for credential stuffing attacks.

### Vector #2: Brute-Force & Credential Stuffing via Open `xmlrpc.php`
* **Mechanism:** `xmlrpc.php` was accessible. The `system.multicall` method allows testing hundreds of username/password combinations in a **single HTTP POST request**, bypassing naive rate limiters on `/wp-login.php`.
* **Outcome:** Rapid password cracking without generating high volumes of web server log entries.

### Vector #3: Vulnerabilities in Outdated Third-Party Plugins
* **Mechanism:** Sites hosted outdated third-party plugins with known **Unauthenticated Privilege Escalation** and **Arbitrary File Upload** flaws.
* **Outcome:** Direct creation of rogue `administrator` accounts via unvalidated AJAX actions and hooks.

### Vector #4: Persistence & Web-Shell Backdoors
* **Mechanism:**
  1. Creation of rogue admins with distinct disposable email domains (`@wp2shell.invalid`, `@service.localhost`, `@bobresearchlabs.com`).
  2. Upload of obfuscated PHP webshells into `/wp-content/uploads/` (where the web server executed PHP scripts by default).
  3. Patching core files (notably `wp-admin/includes/update-core.php`) to restore administrative access even if offending plugins were deleted.

---

## ⚡ 3. Rapid 10-Second Diagnostic Commands

Use these terminal commands to verify any WordPress site instantly:

### 1. Audit All Administrator Accounts:
```bash
wp user list --role=administrator --allow-root --path=/var/www/USER/data/www/DOMAIN --fields=ID,user_login,user_email,user_registered
```
> **Compromise Indicators:** Users with emails on `@wp2shell.invalid`, `@service.localhost`, `@bobresearchlabs.com`, pseudo-random strings (`wp2_*`, `sys_*`, `root_*`, `w2s_*`), or unfamiliar registration timestamps.

### 2. Verify Official WordPress Core File Checksums:
```bash
wp core verify-checksums --allow-root --path=/var/www/USER/data/www/DOMAIN
```
> **Compromise Indicators:** Warnings like `File doesn't verify against checksum` or `File should not exist`.

### 3. Detect Hidden PHP Scripts in Media Uploads:
```bash
find /var/www/USER/data/www/DOMAIN/wp-content/uploads -type f \( -name "*.php*" -o -name "*.phtml" -o -name "*.phar" -o -name "*.ico.php" \)
```
> **Compromise Indicators:** Any `.php` file other than empty dummy `index.php` files.

---

## 🛡️ 4. Standard Multi-Tier Security Architecture (`Shield_VladiMIR+AI`)

To permanently block these attack vectors without sacrificing speed or compatibility, the following defense-in-depth architecture was deployed:

```
                  ┌────────────────────────────────────────────────────────┐
                  │                 Inbound Web Traffic                    │
                  └──────────────────────────┬─────────────────────────────┘
                                             │
                                             ▼
                 [ Tier 1: Root .htaccess: Block XML-RPC, XSS, /?author=N  ]
                                             │
                                             ▼
                  [ Tier 2: /wp-content/uploads/.htaccess: php engine off  ]
                                             │
                                             ▼
                   [ Tier 3: wp-config.php: DISALLOW_FILE_EDIT + chmod 600 ]
                                             │
                                             ▼
                    [ Tier 4: Autonomous Micro-Plugins (VladiMIR+AI)        ]
                                             │
                                             ▼
                     [ Tier 5: Current WordPress Core + Auto-Updates        ]
```

---

### Tier 1: Root `.htaccess-root`
* **Block `xmlrpc.php`:** Completely denies HTTP requests to XML-RPC with a `403 Forbidden` response, closing 95% of automated brute-force attacks.
* **Protect Sensitive Files:** Blocks direct reads of `.env`, `.sql`, `.log`, `.sh`, `.bak`, `.git`, `.yml`.
* **Block Author Enumeration:** Rewrite rules redirect `/?author=N` requests to the homepage with a 301 header.
* **Filter Malicious Injections:** Blocks `eval()`, `base64_decode`, `<script>`, `<iframe>` in URIs and query parameters.
* **OWASP Security Headers:**
  - `X-Frame-Options: SAMEORIGIN` (Clickjacking mitigation)
  - `X-Content-Type-Options: nosniff` (MIME sniffing prevention)
  - `Strict-Transport-Security` (HSTS enforcement)
* **Google PageSpeed Caching:** 1-year browser caching for images (WebP, AVIF, SVG) and fonts (WOFF2); 6-month caching for CSS/JS.

---

### Tier 2: Media Upload Shield (`/wp-content/uploads/.htaccess`)
* **Disable PHP Engine:**
  ```apache
  <IfModule mod_php.c>
      php_flag engine off
  </IfModule>
  ```
* **Forbid Execution of Executable Extensions:**
  ```apache
  <FilesMatch "\.(php|phtml|php3|php4|php5|php7|php8|phps|pht|phar|cgi|pl|py|sh|bash|exe|bat|cmd|jsp|asp|aspx)$">
      Require all denied
  </FilesMatch>
  ```
* **Result:** Even if an attacker uploads a PHP script through a flawed form, the web server **refuses execution** and responds with `403 Forbidden`.

---

### Tier 3: Hardened `wp-config.php`
1. Enforce file editor lock:
   ```php
   define('DISALLOW_FILE_EDIT', true);
   ```
   *Disables built-in file editing inside WordPress admin. Even with administrator credentials, attackers cannot modify theme or plugin files to plant backdoors.*
2. Restrict filesystem permissions: `chmod 600` (readable only by the process owner).

---

### Tier 4: Zero-Bloat `(VladiMIR+AI)` Micro-Plugins
Replace bloated, unmaintained third-party plugins with verified lightweight modules:
1. `404-410-301` — SEO 404/410 status and visitor auto-redirect.
2. `classic-editor-tinymce` — Gutenberg removal and Word-style visual editing toolbar.
3. `clean-head-meta` — Header bloat cleanup, WP version masking, emoji removal.
4. `disable-update-emails` — Suppresses admin update email notifications.
5. `image-resizer` — Auto-downscales massive photo uploads to 1600x1600 px.
6. `translit-cyr-lat` — Fast SEO transliteration for permalinks.
7. `wp-allow-html-cats` — Allows rich HTML tags in taxonomy descriptions.
8. `wp-auto-sku` — Auto-generates 5-digit SKUs with manual edit preservation.
9. `wp-online-counter` — Live visitor and user counter in admin bar.
10. `wp-simple-post-order` — Drag-and-drop ordering for posts, products, and categories.
11. `wp-seo-micro` — Lightweight SEO titles, descriptions, keywords, Open Graph, and XML sitemaps.
12. `wp-test-email-micro` — On-demand diagnostic email tester.

---

### Tier 5: Routine Core & Plugin Maintenance
* All sites maintained on official **WordPress core releases**.
* Managed automated security updates via WP-CLI cron jobs.

---

## 🔗 Useful Links

- 📁 Public Hardening Module: **[GitHub: Linux_Server_Public / htaccess_Shield ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/htaccess_Shield)**
- 📦 Micro-Plugins Suite: **[GitHub: Linux_Server_Public / WordPress ↗](https://github.com/GinCz/Linux_Server_Public/tree/main/WordPress)**
- 🔒 Private Repository: **[GitHub: Secret_Privat ↗](https://github.com/GinCz/Secret_Privat)**