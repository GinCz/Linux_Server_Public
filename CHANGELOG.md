# 📋 CHANGELOG — Linux_Server_Public

All notable changes to this repository are documented here.  
Format: `YYYY-MM-DD | [server] | description`

---

## 2026-04-12 | 222 | CrowdSec hub full restore — parsers + collections

### Context
After `cscli hub update`, all hub-managed parsers and scenarios showed `WARNING: no such file or directory` in `/etc/crowdsec/hub/`. Only 2 local parsers (whitelists) were active. Root cause: hub directory was empty/corrupted — `.index.json` downloaded but actual YAML files missing.

### Problem
- `cscli parsers list` showed only `crowdsecurity/whitelists` (local) and `my_whitelist` (local)
- ALL hub parsers missing: `nginx-logs`, `sshd-logs`, `geoip-enrich`, `dateparse-enrich`, `http-logs`, etc.
- CrowdSec was running but **not parsing any logs** → scenarios not triggering
- 40+ WARNING messages on every `cscli` command

### Fix applied
1. Stopped CrowdSec: `systemctl stop crowdsec`
2. Cleared broken hub cache: `rm -rf /etc/crowdsec/hub/ && mkdir -p /etc/crowdsec/hub/`
3. Re-downloaded index: `cscli hub update`
4. Reinstalled all collections:
   - `crowdsecurity/linux` — syslog, sshd base
   - `crowdsecurity/nginx` — nginx-logs parser
   - `crowdsecurity/sshd` — SSH brute force scenarios
   - `crowdsecurity/wordpress` — WP-specific scenarios
   - `crowdsecurity/base-http-scenarios` — HTTP probing/scanning
   - `crowdsecurity/http-cve` — 31 CVE scenarios
   - `crowdsecurity/whitelist-good-actors` — CDN, SEO bots whitelist
   - `crowdsecurity/mysql` + `crowdsecurity/mariadb`
5. Started CrowdSec: `systemctl start crowdsec`
6. Applied config: `systemctl reload crowdsec`

### Result after fix
- All parsers active: `nginx-logs` (v2.0), `sshd-logs` (v3.1), `geoip-enrich` (v0.5), `dateparse-enrich` (v0.2), `http-logs` (v1.3), `syslog-logs` (v1.0), `public-dns-allowlist` (v0.1)
- All postoverflows active: `cdn-whitelist`, `seo-bots-whitelist`, `rdns`
- 31 CVE scenarios active
- SSH scenarios: `ssh-bf`, `ssh-slow-bf`, `ssh-time-based-bf`, `ssh-cve-2024-6387`, `ssh-refused-conn`, `ssh-generic-test`
- CrowdSec reading and parsing logs from all sites ✅
- 48 active bans within minutes after restore ✅
- `crowdsec` → `active` ✅ | `nginx` → `active` ✅

### Acquisition metrics (after reload)
- `auth.log`: 81 read / 28 parsed / 102 poured to buckets
- `arslan/autoservis-praha.eu`: 143+147 lines → 273+105 to buckets (highest activity)
- All 20+ site logs: 100% parse rate ✅
- CDN/Cloudflare IPs: correctly whitelisted ✅

### Active bans sample (14:23 CEST)
| IP | Country | AS | Reason | Events |
|---|---|---|---|---|
| `183.110.116.87` | KR | Korea Telecom | ssh-slow-bf | 37 |
| `117.50.70.125` | CN | China Unicom | ssh-slow-bf | 14 |
| `52.243.57.116` | JP | Microsoft Azure | http-crawl-non_statics | 14 |
| `212.56.33.224` | DE | Contabo | ssh-slow-bf | 12 |

### ⛔ IMPORTANT — SSH port decision
**SSH port 22 must NOT be changed.**  
A previous attempt to move SSH to port 2222 broke multiple dependent services and configurations. Port 22 stays as-is. CrowdSec handles SSH brute-force protection instead.

### Script
`222/fix_crowdsec_hub_v2026-04-12.sh`

---

## 2026-04-12 | 222 | PHP memory + OPcache tuning + server config philosophy

### Context
Morning SOS report showed: Load 1.38, RAM only 301MB free, Swap 1.3GB used, 18 active PHP-FPM pools.  
`svetaform.eu` was crashing 3× with `PHP Fatal error: Allowed memory size of 134217728 bytes exhausted` on `/wp-json/oembed/` endpoint (triggered by external bots scanning oEmbed).  
OPcache had only 2 lines configured (extension + jit=off) — all other parameters were PHP defaults, insufficient for 20+ WordPress sites.

### Changes made:

#### 💾 PHP memory_limit — global increase
- **File:** `/etc/php/8.3/fpm/php.ini`
- **Change:** `memory_limit = 128M` → `memory_limit = 256M`
- **Why:** 128MB is insufficient for modern WordPress with WooCommerce, REST API, and multiple plugins. All sites on the server get the same limit — no per-site exceptions.
- **Result:** `svetaform.eu` OOM errors stopped immediately after reload. Zero new OOM errors after 11:05.
- **Repo file:** `222/php.ini`

#### ⚡ OPcache — full configuration
- **File:** `/etc/php/8.3/fpm/conf.d/10-opcache.ini`
- **Previous state:** Only `zend_extension=opcache.so` and `opcache.jit=off` — all other values were PHP defaults (memory=128MB, max_files=10000)
- **New settings:**
  - `opcache.memory_consumption=256` — 256MB shared cache for all sites
  - `opcache.interned_strings_buffer=32` — for WordPress string-heavy workloads
  - `opcache.max_accelerated_files=20000` — covers all PHP files across 20+ sites
  - `opcache.revalidate_freq=60` — check file changes every 60 seconds
  - `opcache.validate_timestamps=1` — detect file changes after WP updates
  - `opcache.max_wasted_percentage=10` — auto-restart cache when 10% is wasted
  - `opcache.save_comments=1` — required by some WP plugins
  - `opcache.jit=off` — JIT disabled (unstable with some WP plugins on PHP 8.3)
- **Why:** Without proper OPcache config, PHP recompiles every file on every request. With 20+ sites this wastes significant CPU and RAM.
- **Result:** PHP execution faster, CPU load reduced from 1.38 → 0.50 (combined with memory fix)
- **Repo file:** `222/10-opcache.ini`

#### 📚 README — server configuration philosophy added
- **File:** `README.md` (root)
- **Added:** Section `### 6. ⚙️ Server Configuration Philosophy (CRITICAL)`
- **Rule:** All server configuration must be done at the **server level** — never per-account or per-domain.
  - PHP settings → global `php.ini`
  - Nginx settings → global `nginx.conf`
  - MariaDB → global `my.cnf`
  - PHP-FPM pools → global template applied equally to all
- **When a site misbehaves:** Do NOT edit its config. Instead: log into WP Admin, update all plugins/themes/core, verify CAPTCHA is installed and active.
- **AI obligation:** Must notify VladiMIR which domain needs attention with exact message format.

### Verification after changes:
- `svetaform.eu` WP Admin checked: all plugins updated, WP core 6.9.4 (latest), Cloudflare Turnstile active ✅
- `wp core verify-checksums` → `Success: WordPress installation verifies against checksums` ✅
- No suspicious PHP files in `wp-content/uploads` ✅
- No new OOM errors after 11:05 ✅
- Load Average: 1.38 → **0.41** ✅
- RAM free: 301MB → **1.1GB** ✅
- PHP-FPM active pools: 18 → **9** (idle pools released after reload) ✅

### Server state after session (13:22):
| Metric | Value |
|---|---|
| Load Average | 0.41 / 0.50 / 0.48 |
| RAM used | 3.6GB / 7.7GB |
| RAM free | 1.1GB |
| Swap used | 1.1GB / 4.0GB |
| Disk used | 53GB / 247GB (22%) |
| PHP memory_limit | 256MB (global) |
| OPcache memory | 256MB |
| CrowdSec bans | 49 active |
| All services | active ✅ |

---

## 2026-04-12 | 109 | wp_update_all.sh language support

- Added language update support to `wp_update_all.sh`
- WordPress language files now updated automatically during the update cycle
- Script version: `v2026-04-12`

---

## 2026-04-10 | VPN + ALL | Full documentation pass + backup system launch

### What was done:

#### 🔐 SSH Key Setup (VPN nodes)
- Generated `ed25519` SSH key pair for VPN node access from server 222
- Added public key to all VPN nodes `~/.ssh/authorized_keys`
- Tested passwordless SSH from 222 → all VPN nodes ✅

#### 💾 VPN Docker Backup System (`vpn_docker_backup.sh`)
- **First successful run:** 2026-04-10 at ~13:00 CEST (manual test)
- Backed up AWG Docker volumes from all active nodes
- Archives uploaded to AWS S3 successfully
- **Settings confirmed:**
  - `KEEP=7` — keeps last 7 daily backups per node
  - Cron scheduled: **03:30 daily** → `/var/log/vpn_backup.log`
- Log location: `/var/log/vpn_backup.log`

#### 📖 Documentation created/updated:
- `VPN/BACKUP.md` — full backup system docs, restore procedure, real run output
- `VPN/README.md` — full file index, node table, quick-start guide, backup reference
- `README.md` (root) — SSH key management, backup system, coding standards, naming convention

---

## 2026-04-08 | 222 + 109 | PHP-FPM per-site limits system

- Created `set_php_fpm_limits_v2026-04-07.sh` for both servers
- Added systemd cgroup: `CPUQuota=320%`, `MemoryMax=6.8G` per PHP-FPM service
- Set `pm.max_children=8`, `pm.max_requests=500` per pool
- Created `php_fpm_limits_info.md` with full parameter explanation

---

## 2026-04-07 | 222 | PHP-FPM watchdog + Telegram alerts

- Deployed `php_fpm_watchdog.sh` on server 222
- Watchdog checks CPU usage per pool every 5 minutes
- Auto-restarts pool if CPU > 90% for > 15 minutes
- Sends Telegram alert with pool name and CPU% on restart
- Cron: `*/5 * * * * /root/php_fpm_watchdog.sh`

---

## 2026-04-05 | 222 | CrowdSec + Nginx bouncer fix

- Fixed CrowdSec engine INACTIVE state after hub corruption
- Script: `fix_nginx_crowdsec_222_v2026-04-05.sh`
- Rebuilt hub: `cscli hub update && cscli hub upgrade`
- Verified Nginx bouncer active and blocking ✅

---

## 2026-03-16 | ALL | Initial public repository setup

- Created `Linux_Server_Public` repository
- Added folder structure: `222/`, `109/`, `VPN/`, `scripts/`
- Added coding standards to root `README.md`
- Imported existing scripts from both servers
- Set up `save` alias for quick git push on all servers

---

*= Rooted by VladiMIR | AI =*
