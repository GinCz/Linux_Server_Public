# 🔄 WordPress Auto-Update Automation System (Audit & Hardening Report)
> **Date:** 2026-09-25 | **Author:** Vladimir Bulantsev ([GinCz ↗](https://github.com/GinCz)) & Antigravity AI
> **Nodes:** DE-222 (NetCup, Germany) & RU-109 (FirstVDS, Russia)

---

## 📌 Executive Summary
A comprehensive audit and hardening of the automated WordPress maintenance infrastructure across all web servers (**62 websites total: 40 on DE-222, 22 on RU-109**) was completed on 2026-09-25.

Two key issues were identified and resolved:
1. **Telegram Notification Silence on Success:** Alerts were previously configured to trigger *only on errors* (`$FAIL > 0`). When all sites updated successfully, no Telegram message was sent, giving the false impression that updates were not executing. Additionally, Russian node RU-109 suffered from direct `api.telegram.org` timeout due to ISP filtering.
2. **Permission Conflicts:** Specific plugin folders (e.g. on `news-port.ru`) had root-owned permissions, preventing `sudo -u <site_user> wp plugin update` from replacing updated files.

---

## 🛠 Fixes & System Improvements Implemented

### 1. Updated `/usr/local/bin/wp_update_all.sh` (v2026-09-25)
* **Comprehensive Execution Reports:** The script now sends a full Telegram summary to `@My_WWW_bot` on **EVERY run** (both for 100% Success and for Alerts).
* **Detailed Metrics Included:**
  * Total sites processed, successful sites, failed sites.
  * Exact count of updated plugins (🔌), WordPress Core engines (⚙️), and themes (🎨).
  * Domain-by-domain breakdown of updated packages.
* **Resilient Dual-Channel Telegram Bridge (`tg()` function):**
  * Tries direct HTTPS POST to `https://api.telegram.org` first (8s timeout).
  * Automatically falls back to an SSH Python bridge via Master Node DE-222 if the host is in a restricted network (e.g., RU-109).

### 2. Ownership & Permissions Hardening
* Performed recursive ownership alignment across `/var/www/*/data/www/*`:
  `chown -R $SITE_USER:$SITE_USER /var/www/$SITE_USER/data/www/$DOMAIN`
* Refined WP-CLI error handling: non-critical warnings such as `version higher than expected` (for custom plugins like `woocommerce-products-filter`) are parsed gracefully and no longer trigger false failure flags.

### 3. Verification Run Results (2026-09-25 Live Execution)
* **DE-222 (40 sites):** 40/40 Success | **128 plugins updated** | Telegram notification sent ✅
* **RU-109 (22 sites):** 22/22 Success | **44 plugins updated** | Telegram notification sent ✅

---

## ⏰ Cron Schedule Verification
* Location: `/etc/cron.d/wp_update_all`
* Schedule: `0 2 * * 3,6 root /usr/local/bin/wp_update_all.sh >> /var/log/wp_update_all.log 2>&1`
* Execution Frequency: Twice a week (Wednesday and Saturday at 02:00 UTC/MSK).

---

## 🚀 Optimization & Refinement (v2026-10-03)
* **Concise 4-Line Success Telegram Format:**
  * Cleaned up the successful notification template — completely eliminated the verbose 25+ site listing (`📦 Обновленные сайты:`), keeping only the clean, compact 4-line summary:
    ```text
    ✅ WP Update Complete — <HOST> (<IP>)
    📅 YYYY-MM-DD HH:MM
    📊 Сайтов: X | Успешно: X | Ошибок: 0
    🔄 Обновлено: 🔌 Плагинов: P | ⚙️ WP Core: C | 🎨 Тем: T
    ```
* **Detailed Per-Site Failure Breakdown:**
  * When errors occur (`$FAIL > 0`), the 4-line summary is sent alongside a detailed domain-by-domain list of exact errors (`❌ Ошибки обновления:`) detailing plugin/core/theme failure messages.
* **Nodes Synchronized:** DE-222 (`152.53.182.222`) & RU-109 (`212.109.223.109`).

