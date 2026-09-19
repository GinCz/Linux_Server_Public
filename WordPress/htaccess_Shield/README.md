# đź›ˇď¸Ź WordPress .htaccess Security Shield & Performance Kit

> **Universal, lightweight, production-grade Apache .htaccess hardening rules and performance optimization for WordPress websites.**
> 
> *Repository:* [Linux_Server_Public â†—](https://github.com/GinCz/Linux_Server_Public) | *Author:* [Vladimir Bulantsev (GinCz) â†—](https://github.com/GinCz) & AI Assistant | *Version:* 2026.09.06

[![WordPress](https://img.shields.io/badge/WordPress-6.0%2B%20|%207.x-21759B?logo=wordpress&logoColor=white)](https://wordpress.org)
[![Apache](https://img.shields.io/badge/Apache-2.4%2B-D22128?logo=apache&logoColor=white)](https://httpd.apache.org)
[![Security](https://img.shields.io/badge/Security-Hardened-success)](https://github.com/GinCz/Linux_Server_Public)
[![Performance](https://img.shields.io/badge/Google%20PageSpeed-Optimized-brightgreen)](https://pagespeed.web.dev/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

---

## đź“Ś Overview

This directory provides two production-tested .htaccess configuration templates designed to protect WordPress installations against 95%+ of common web attacks (Brute-force, XML-RPC exploitation, WebShell injection, SQL injection, User Enumeration, and sensitive data leakage) while maximizing Google PageSpeed caching scores.

---

## đź“ File Structure

| File | Target Location | Purpose |
| :--- | :--- | :--- |
| [.htaccess-root](.htaccess-root) | /var/www/USER/data/www/DOMAIN/ (Root) | Main WordPress routing, security headers, anti-bot rules, sensitive file protection & browser cache. |
| [.htaccess-uploads](.htaccess-uploads) | /wp-content/uploads/.htaccess | Anti-WebShell shield: completely disables PHP/CGI/Python/Shell script execution in uploads. |

---

## đź›ˇď¸Ź Protection Features Breakdown

### 1. Root Protection (.htaccess-root)
- **Security Headers (OWASP Recommended):** X-XSS-Protection, X-Content-Type-Options: nosniff, Referrer-Policy, X-Frame-Options: SAMEORIGIN, HSTS.
- **Blocks wp-config.php & XML-RPC:** Completely blocks external access to database configuration and xmlrpc.php.
- **Sensitive File Shield:** Protects .env, .sql, .log, .sh, .bak, .git, .yml.
- **Blocks User Enumeration:** Redirects /?author=N scans.
- **PageSpeed Browser Caching:** Long-term caching headers for WebP, AVIF, SVG, Fonts, CSS, and JS.

### 2. Uploads Shield (.htaccess-uploads)
- Disables script engines inside /wp-content/uploads/ to prevent execution of injected PHP backdoors.
