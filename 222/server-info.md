# 🖥️ Server 222 — DE-NetCup

> **Updated:** 2026-04-05 | = Rooted by VladiMIR | AI =

## 🔧 Hardware
| Parameter | Value |
|---|---|
| **IP** | 152.53.182.222 |
| **Provider** | NetCup.com, Germany |
| **Tariff** | VPS 1000 G12 (2026) |
| **CPU** | 4 vCore AMD EPYC-Genoa |
| **RAM** | 8 GB DDR5 ECC |
| **Disk** | 256 GB NVMe |
| **OS** | Ubuntu 24 LTS |
| **Panel** | FastPanel (PHP 8.3 / 8.4) |
| **Price** | 8.60 EUR/mo |
| **Cloudflare** | YES — all sites behind Cloudflare (orange cloud) |

## 🌐 Network & Security
- **Hostname:** `222-DE-NetCup`
- **Cloudflare:** All .eu / .cz / .uk / .com / .ru domains — ORANGE CLOUD (full proxy)
- **IMPORTANT:** `$binary_remote_addr` in nginx = Cloudflare IP, NOT real visitor IP!
- **Real visitor IP** is available only via `$http_cf_connecting_ip` header
- **CrowdSec:** Active (nginx bouncer + SSH)
- **AmneziaVPN:** Active (Docker container)
- **Fail2ban:** Active
- **Netdata:** Active (free cloud account, 5 servers)

## 🔗 Admin Links
| Service | URL |
|---|---|
| **FastPanel** | https://server.gincz.com:8888 |
| **Semaphore UI** | https://sem.gincz.com |
| **Crypto-Bot Web** | https://crypto.gincz.com |
| **Netdata Cloud** | https://app.netdata.cloud |

---

## 🛡️ Nginx Security — Bot & Crawler Protection

### ⚠️ CRITICAL: Why IP-based rate limiting does NOT work on server 222

All traffic on server 222 passes through **Cloudflare proxy (orange cloud)**.
This means:
- nginx sees `$binary_remote_addr` = one of ~15 Cloudflare IP addresses
- The real visitor/bot IP is hidden inside the `CF-Connecting-IP` HTTP header
- **If you create a `limit_req_zone` by `$binary_remote_addr` — you will rate-limit ALL users at once**, because they all appear to come from the same Cloudflare IPs
- On server 222, rate limiting MUST be done by `$http_user_agent` (User-Agent) using a `map` variable

---

### 🤖 Meta/Facebook Crawler Block (2026-04-05)

#### Problem
Meta crawlers (`meta-externalagent`) were sending ~151,000 requests/hour to **svetaform.eu** (WooCommerce shop), simulating real WooCommerce cart sessions — adding/removing products, generating full PHP-FPM execution for each request. This caused:
- PHP-FPM pool `svetaform.eu` consuming **~46% CPU** (2 workers × ~23% each)
- High server load affecting other 43 WordPress sites
- Root cause: Meta builds a product graph for **Facebook Shop / Instagram Shopping** by crawling WooCommerce cart and checkout pages

#### Why Meta does this
Meta's crawler indexes WooCommerce products for Facebook/Instagram shopping feeds. It aggressively hits `/basket/`, `/cart/`, `/checkout/` with `?remove_item=` and `?add-to-cart=` parameters — this triggers full WooCommerce PHP execution, session creation, and DB queries on every request.

#### Solution chosen
Block Meta crawler from WooCommerce heavy endpoints (cart, checkout, AJAX) entirely. Allow access to static product pages (needed for FB Shop catalog). Rate-limit all PHP requests from Meta at 2 req/s.

**NOT chosen alternatives:**
- Full block of Meta (`deny all`) — would break Facebook/Instagram product indexing and social sharing previews
- IP-based block — impossible on 222 (Cloudflare proxy hides real IPs)
- WordPress plugin approach — too slow, PHP already executes before plugin can block

#### Implementation (2 files on server)

**File 1:** `/etc/nginx/conf.d/meta_crawler_limit.conf`
```nginx
# Meta/Facebook crawler protection | v2026-04-05
# = Rooted by VladiMIR | AI =
# Works correctly behind Cloudflare (no IP-based limiting possible)

map $http_user_agent $meta_limit_key {
    default                 "";
    "~*meta-externalagent"  "meta";
    "~*facebookexternalhit" "meta";
    "~*FacebookBot"         "meta";
}

# Empty key = limit_req does NOT trigger for real users
# "meta" key = all Meta requests share one zone = 2 req/s max
limit_req_zone $meta_limit_key zone=meta_global:10m rate=2r/s;
limit_req_status 429;
```

**File 2:** `/etc/nginx/fastpanel2-includes/meta_crawler_block.conf`
```nginx
# Block Meta crawler from WooCommerce heavy endpoints | v2026-04-05
# = Rooted by VladiMIR | AI =
# Included in ALL vhosts via fastpanel2-includes mechanism

# Hard block Meta from cart/checkout/wp-admin/wp-cron
location ~* ^/(basket|cart|checkout|wp-admin|wp-cron\.php) {
    if ($meta_limit_key = "meta") {
        return 403;
    }
    try_files $uri $uri/ /index.php?$args;
}

# Block Meta from WooCommerce AJAX
location ~* \?wc-ajax= {
    if ($meta_limit_key = "meta") {
        return 403;
    }
    try_files $uri $uri/ /index.php?$args;
}

# Rate limit Meta on all PHP requests
location ~ \.php$ {
    limit_req zone=meta_global burst=5 nodelay;
    include /etc/nginx/fastcgi_params;
    fastcgi_pass unix:/var/run/$server_name.sock;
    fastcgi_param SCRIPT_FILENAME $realpath_root$fastcgi_script_name;
    fastcgi_param DOCUMENT_ROOT $realpath_root;
}
```

#### How it works (mechanism)
1. `map` directive checks every request's User-Agent
2. If UA contains `meta-externalagent` / `facebookexternalhit` / `FacebookBot` → `$meta_limit_key = "meta"`
3. For real users: `$meta_limit_key = ""` → `limit_req_zone` ignores empty keys → **zero impact on real visitors**
4. For Meta: all requests share zone `meta_global` → hard cap 2 req/s with burst=5
5. Cart/checkout/AJAX endpoints return **403** immediately (no PHP execution at all)
6. Product pages are still accessible to Meta at 2 req/s → Facebook Shop catalog still works

#### Result measured
| Metric | Before | After |
|---|---|---|
| svetaform.eu PHP-FPM CPU (worker 1) | ~23% | ~12% |
| svetaform.eu PHP-FPM CPU (worker 2) | ~23% | ~9% |
| **Total svetaform CPU** | **~46%** | **~21%** |
| 429 responses to Meta | 0 | 17+ per minute |
| Server overall load | HIGH | NORMAL |

#### Possible consequences & what to watch
- **Facebook/Instagram product previews** — still work (product pages accessible)
- **Facebook Shop catalog** — still updates (product pages accessible at 2 req/s)
- **If Meta changes User-Agent string** — block stops working. Monitor nginx logs: `grep -i "meta\|facebook\|facebookbot" /var/www/*/data/logs/*.access.log | grep -v "403\|429"`
- **If client uses WooCommerce basket link in Facebook post** — the link `/basket/?add-to-cart=X` will return 403 to Meta crawler but work for real users (they don't match `$meta_limit_key`)
- **WooCommerce cart page must NOT be indexed** — correct, already blocked. Cart URLs are not meaningful for SEO anyway.
- **FastPanel vhost update** — `fastpanel2-available/*.conf` is managed by FastPanel and can be overwritten. The `fastpanel2-includes/` directory is SAFE — FastPanel does not touch it. Always put custom rules in `fastpanel2-includes/`.

#### Reload command
```bash
nginx -t && systemctl reload nginx
```

---

### 🔐 WordPress Rate Limits (wp-login, xmlrpc)

Defined in `/etc/nginx/conf.d/` (files `00-wp-login-limit-zone.conf`, `01-wp-limit-zones.conf`):

| Zone | Rate | Target | Notes |
|---|---|---|---|
| `wp_login_222` | 6 req/min, burst=3 | `wp-login.php` | ~3 quick attempts then throttle |
| `wp_xmlrpc_222` | 1 req/min | `xmlrpc.php` | Very tight, xmlrpc rarely needed |

> ⚠️ These zones use `$binary_remote_addr` — which on 222 = Cloudflare IP. This is acceptable for wp-login because CrowdSec handles the real IP banning via `CF-Connecting-IP`. Nginx rate limit here is a secondary layer, not the primary defense.

**CrowdSec handles:**
- 10-minute IP ban for WordPress scan patterns (`crowdsecurity/http-wordpress-scan`)
- SSH brute force protection
- Automatic reporting to CrowdSec community blocklist

---

## 🐳 Docker Containers

### 1. Crypto-Bot (`crypto-bot`)
- **Location:** `/root/crypto-docker/`
- **Compose:** `/root/crypto-docker/docker-compose.yml`
- **Start:** `bash /root/crypto-docker/scripts/tr_docker.sh` → alias **`bot`**
- **Deploy:** `bash /root/crypto-docker/scripts/deploy.sh`
- **Reset:** `bash /root/crypto-docker/scripts/reset.sh`
- **Web UI:** https://crypto.gincz.com
- **Backup:** `/BACKUP/222/docker/crypto/` (cron 03:00 daily)

| Script | Description |
|---|---|
| `tr_docker.sh` | **Main bot start** — alias `bot` (NOT `tr` — conflicts with system util!) |
| `tr.sh` | Start trading directly (no Docker wrapper) |
| `deploy.sh` | Full container redeploy |
| `reset.sh` | Reset and restart container |
| `start.sh` | Start container |
| `trade.py` | Core trading logic |
| `scanner.py` | Market scanner |
| `trades_report.py` | Full trades report |
| `tr_report.py` | Short report (updated 2026-03-25) |
| `paper_trade.py` | Paper trading (test, no real money) |
| `paper_report.py` | Paper trading report |
| `push_stats.sh` | Push statistics |
| `303-crypto.conf` | Nginx config for bot web UI |

> ⚠️ **Alias `tr` → renamed to `bot`** — `tr` is a system Linux utility (translate chars). Use `bot` only!

---

### 2. Semaphore (`semaphore`)
- **Location:** `/root/semaphore-data/`
- **Compose:** `/root/semaphore-data/docker-compose.yml`
- **Web UI:** https://sem.gincz.com
- **DB:** SQLite (inside container volume)
- **Start:** `cd /root/semaphore-data && docker compose up -d`
- **Stop:** `cd /root/semaphore-data && docker compose down`
- **Backup:** `/BACKUP/222/docker/semaphore/` (cron 03:00 daily, ~300 MB)
- **Used for:** Automated deployment tasks, server scripts via Ansible playbooks

---

### 3. AmneziaVPN (`amnezia`)
- **Location:** `/root/amnezia/`
- **Protocol:** AmneziaWG (modified WireGuard)
- **Start:** `docker compose up -d` in amnezia directory
- **Backup:** `/BACKUP/222/docker/amnezia/` (cron 03:00 daily, ~13 MB)
- **Purpose:** VPN access to server and private tunnels

---

## 📅 Cron Jobs (full list)
```
# System backup + deep cleanup
0 2 * * *   /root/backup_clean.sh >> /var/log/system-backup.log 2>&1

# Docker containers backup (crypto + semaphore + amnezia)
0 3 * * *   /root/docker_backup.sh >> /var/log/docker-backup.log 2>&1

# WordPress cron (44 sites)
0 23 * * *  wp-cron.php (44 sites)

# Disk cleanup (every Sunday)
0 3 * * 0   disk_cleanup.sh
```

## 💾 Backup Strategy
| Script | Time | What | Where | Keep |
|---|---|---|---|---|
| `backup_clean.sh` | 02:00 | `/etc` + `/root` configs (< 30 MB) | `/BACKUP/222/` + remote 109 | 10 |
| `docker_backup.sh` | 03:00 | crypto + semaphore + amnezia | `/BACKUP/222/docker/` + remote 109 | 5 each |

**Restore system:**
```bash
tar -xzf BackUp_222-EU__YYYY-MM-DD_HH-MM.tar.gz -C /
```

**Current backup sizes:**
- System archives: ~130 MB each
- Semaphore: ~300 MB
- Crypto: ~100 MB
- Amnezia: ~13 MB

## 🌍 WordPress Sites (44 total)

| Domain | User | WP Cron |
|---|---|---|
| detailing-alex.eu | alex_detailing | system 23:00 |
| ru-tv.eu | gincz | system 23:00 |
| ekaterinburg-sro.eu | gincz | system 23:00 |
| eco-seo.cz | gincz | system 23:00 |
| eurasia-translog.cz | serg_et | system 23:00 |
| east-vector.cz | serg_et | system 23:00 |
| rail-east.uk | serg_et | system 23:00 |
| vymena-motoroveho-oleje.cz | serg_pimonov | system 23:00 |
| car-chip.eu | serg_pimonov | system 23:00 |
| diamond-odtah.cz | diamond-drivers | system 23:00 |
| sveta-drobot.cz | sveta_drobot | system 23:00 |
| bio-zahrada.eu | tan-adrian | system 23:00 |
| alejandrofashion.cz | alejandrofashion | system 23:00 |
| czechtoday.eu | dmitry-vary | system 23:00 |
| stm-services-group.cz | tatiana_podzolkova | system 23:00 |
| autoservis-praha.eu | arslan | system 23:00 |
| praha-autoservis.eu | bayerhoff | system 23:00 |
| neonella.eu | neonella | system 23:00 |
| megan-consult.cz | igor_kap | system 23:00 |
| abl-metal.com | igor_kap | system 23:00 |
| stopservis-vestec.cz | serg_reno | system 23:00 |
| kadernik-olga.eu | olga_pisareva | system 23:00 |
| kk-med.eu | karina | system 23:00 |
| kadernictvi-salon.eu | viktoria | system 23:00 |
| doska-hun.ru | doski | system 23:00 |
| doska-ua.ru | doski | system 23:00 |
| doska-mld.ru | doski | system 23:00 |
| doska-it.ru | doski | system 23:00 |
| doska-esp.ru | doski | system 23:00 |
| doska-cz.ru | doski | system 23:00 |
| doska-isl.ru | doski | system 23:00 |
| doska-pl.ru | doski | system 23:00 |
| doska-de.ru | doski | system 23:00 |
| doska-gr.ru | doski | system 23:00 |
| doska-fr.ru | doski | system 23:00 |
| balance-b2b.eu | sveta_tuk | system 23:00 |
| car-bus-autoservice.cz | andrey-autoservis | system 23:00 |
| autoservis-rychlik.cz | andrey-autoservis | system 23:00 |
| hulk-jobs.cz | hulk | system 23:00 |
| gadanie-tel.eu | gadanie-tel | system 23:00 |
| lybawa.com | gadanie-tel | system 23:00 |
| wowflow.cz | wowflow | system 23:00 |
| svetaform.eu | spa | system 23:00 |
| tstwist.cz | tstwist | system 23:00 |

## ⌨️ Aliases (quick commands)
```
load       — git pull (update scripts from GitHub)
save       — git add + commit + push
i          — full server info (RAM, CPU, disk, docker, WP)
sos        — emergency status check
fight      — CrowdSec + firewall status
d          — list all domains with SSL status
backup     — run backup_clean.sh manually
antivir    — ClamAV scan
banlog     — show CrowdSec ban log
bot        — start crypto-bot (alias for tr_docker.sh)
m / mc     — Midnight Commander (restores last visited dir)
chname     — change hostname
mailclean  — clean mail queue
wphealth   — check all WP sites health
cleanup    — manual server cleanup
wpcron     — run WP cron for all 44 sites
aw         — AmneziaVPN status
audit      — security audit
00         — clear screen
```

## 📁 Key Files & Paths
```
/root/backup_clean.sh                                      — system backup + cleanup (cron 02:00)
/root/docker_backup.sh                                     — docker backup (cron 03:00)
/root/crypto-docker/                                       — crypto-bot project
/root/semaphore-data/                                      — semaphore project
/root/Linux_Server_Public/                                 — GitHub repo (this repo)
/BACKUP/222/                                               — local system backups
/BACKUP/222/docker/                                        — local docker backups
/var/log/system-backup.log                                 — backup_clean.sh log
/var/log/docker-backup.log                                 — docker_backup.sh log

# Nginx key files:
/etc/nginx/conf.d/meta_crawler_limit.conf                  — Meta crawler map + rate zone
/etc/nginx/conf.d/cloudflare_real_ip.conf                  — Cloudflare real IP restoration
/etc/nginx/fastpanel2-includes/meta_crawler_block.conf     — Meta block locations (all vhosts)
/etc/nginx/fastpanel2-includes/security-wordpress.conf     — WP security rules (all vhosts)
/etc/nginx/fastpanel2-available/                           — FastPanel vhost configs (DO NOT edit manually!)
/etc/nginx/fastpanel2-sites/                               — FastPanel active symlinks
```

## ⚠️ FastPanel Warning
**NEVER edit files in `/etc/nginx/fastpanel2-available/` manually!**
FastPanel will overwrite them when you change site settings via web panel.
Always put custom nginx rules in:
- `/etc/nginx/conf.d/` — global http{} context (maps, zones, geo)
- `/etc/nginx/fastpanel2-includes/` — per-location rules, included in all vhosts automatically
