# 🖥️ 222-DE-NetCup — Server Reference

> `= Rooted by VladiMIR | AI =`  
> Server: **222-DE-NetCup** | IP: `xxx.xxx.xxx.222` | NetCup.com, Germany  
> ⚠️ Full IP address is stored in the private `Secret_Privat` repository.

---

## 🖥️ Hardware & Software

| Parameter | Value |
|---|---|
| **Provider** | NetCup.com, Germany |
| **Tariff** | VPS 1000 G12 (2026) |
| **CPU** | 4 vCore AMD EPYC-Genoa |
| **RAM** | 8 GB DDR5 ECC |
| **Disk** | 256 GB NVMe |
| **OS** | Ubuntu 24 LTS |
| **Panel** | FASTPANEL |
| **CDN** | Cloudflare ✅ |
| **Monthly cost** | 8.60 € |

---

## 📦 Installed Services

| Service | Status | Purpose |
|---|---|---|
| **Nginx** | active | Web server + reverse proxy for all sites |
| **PHP 8.3 FPM** | active | PHP execution engine for WordPress sites |
| **PHP 8.4 CGI** | active | Used by `gincz` account (opt installation) |
| **MariaDB** | active | MySQL-compatible database for all sites |
| **CrowdSec** | active | Automatic threat detection and IP banning |
| **CrowdSec Bouncer** | active | Nginx integration — blocks banned IPs at web level |
| **Netdata** | active | Real-time server monitoring |
| **Docker** | active | Container runtime |
| **Exim4** | active | Mail transfer agent |
| **SSH** | active | Remote access |

---

## 🐳 Docker Containers

| Container | Status | Purpose |
|---|---|---|
| `amnezia-awg` | Up | AmneziaWG VPN server (WireGuard obfuscation) |
| `crypto-bot` | Up | Cryptocurrency trading bot |
| `semaphore` | Up | Semaphore UI — Ansible task runner / automation |

---

## ⚙️ PHP Configuration (current)

> All PHP settings are configured **globally** — no per-site or per-account exceptions.

| Parameter | Value | File |
|---|---|---|
| `memory_limit` | **256M** | `/etc/php/8.3/fpm/php.ini` |
| `max_execution_time` | 120s | per-pool `php_admin_value` |
| `upload_max_filesize` | 100M | per-pool `php_admin_value` |
| `post_max_size` | 100M | per-pool `php_admin_value` |
| `max_input_vars` | 10000 | per-pool `php_admin_value` |
| `opcache.enable` | 1 | `/etc/php/8.3/fpm/conf.d/10-opcache.ini` |
| `opcache.memory_consumption` | **256MB** | `/etc/php/8.3/fpm/conf.d/10-opcache.ini` |
| `opcache.max_accelerated_files` | 20000 | `/etc/php/8.3/fpm/conf.d/10-opcache.ini` |
| `opcache.revalidate_freq` | 60s | `/etc/php/8.3/fpm/conf.d/10-opcache.ini` |
| `opcache.jit` | off | `/etc/php/8.3/fpm/conf.d/10-opcache.ini` |

### Why memory_limit = 256M (changed 2026-04-12)
The default 128MB was insufficient for modern WordPress with WooCommerce, REST API, and multiple active plugins. `svetaform.eu` was crashing with OOM errors on every `/wp-json/oembed/` bot request. Raised to 256MB globally — OOM errors stopped immediately.

### Why OPcache = 256MB (configured 2026-04-12)
Default OPcache config had only the extension loaded with no memory settings. With 20+ WordPress sites, PHP was recompiling every file on every request. 256MB shared cache covers all PHP files across all sites with room to spare.

---

## 🛡️ Security (CrowdSec)

CrowdSec runs **fully automatically** — no manual banning needed or allowed.

| Scenario | Action |
|---|---|
| WordPress scan detected | Auto-ban |
| SSH brute force detected | Auto-ban |
| HTTP probing / crawling | Auto-ban |
| Slow scanner detected | Auto-ban |
| WP-login brute force | Auto-ban via custom scenario |

**Rule:** The server handles all threats automatically. If a specific site shows attack-related errors in logs — this is normal and expected. CrowdSec will ban the attacker. No manual intervention required.

---

## 💾 Backup System

### Docker Container Backup (`docker_backup.sh`)

- **Script:** `/root/docker_backup.sh` (repo: `222/docker_backup.sh`)
- **Storage:** `/BACKUP/222/docker/`
- **Schedule:** `0 3 * * *` (daily at 03:00) → `/var/log/docker_backup.log`
- **Rotation:** keeps last `KEEP=3` archives per container
- **Notifications:** Telegram on completion/error

| Container | Strategy | Archive location |
|---|---|---|
| `crypto-bot` | volumes (stop/archive/start) | `/BACKUP/222/docker/crypto/` |
| `semaphore` | volumes (stop/archive/start) | `/BACKUP/222/docker/semaphore/` |
| `amnezia-awg` | commit (no stop — VPN must stay up) | `/BACKUP/222/docker/amnezia/` |

#### Run manually:

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
/root/docker_backup.sh
```

#### Restore from archive:

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
# Extract
tar -xzf /BACKUP/222/docker/crypto/crypto-bot_YYYY-MM-DD_HH-MM.tar.gz -C /tmp/restore/
# Load image
docker load < /tmp/restore/tmp/crypto-bot-image.tar.gz
# Verify
docker images | grep crypto
```

---

## 📊 Monitoring

- **Netdata:** real-time metrics (CPU, RAM, disk, network, PHP-FPM pools)
- **SOS script** (`sos`): 24h summary — top CPU/RAM processes, traffic, errors, CrowdSec bans
- **PHP-FPM Watchdog** (`watchdog`): checks pool CPU every 5 min, auto-restarts runaway pools, sends Telegram alert
- **Telegram alerts:** sent on PHP-FPM pool restart, docker backup completion/failure

### Key aliases on this server:

| Alias | Command | Purpose |
|---|---|---|
| `sos` | `bash sos.sh 24` | 24h server health report |
| `watchdog` | `bash php_fpm_watchdog.sh` | PHP-FPM pool CPU check |
| `save` | `git add -A && git commit && git push` | Push changes to repo |
| `mc` | `mc` | Midnight Commander file manager |

---

## 📁 Files in This Folder

| File | Purpose |
|---|---|
| `docker_backup.sh` | Full Docker container backup with rotation and Telegram |
| `set_php_fpm_limits_v2026-04-07.sh` | Set global PHP-FPM pool limits (max_children, max_requests) |
| `php_fpm_watchdog.sh` | Auto-restart runaway PHP-FPM pools + Telegram alert |
| `fix_nginx_crowdsec_222_v2026-04-05.sh` | Fix CrowdSec engine INACTIVE state |
| `sos.sh` | 24h server health summary report |
| `motd_server.sh` | SSH login banner with server info and alias menu |
| `.bashrc` | Root user aliases and environment settings |
| `10-opcache.ini` | Global OPcache configuration for PHP 8.3 FPM |
| `php.ini` | Global PHP 8.3 FPM configuration (memory_limit=256M etc.) |

---

## 🔄 How to Apply Config Changes from Repo

🚀 **RUN ON SERVER: xxx.xxx.xxx.222 (222-DE-NetCup)**
```bash
clear
cd /root/Linux_Server_Public && git pull --rebase

# Apply PHP config
cp 222/php.ini /etc/php/8.3/fpm/php.ini
cp 222/10-opcache.ini /etc/php/8.3/fpm/conf.d/10-opcache.ini
php-fpm8.3 -t && systemctl reload php8.3-fpm
echo "✅ PHP config applied"

# Apply aliases and MOTD
cp 222/.bashrc /root/.bashrc
cp 222/motd_server.sh /etc/profile.d/motd_server.sh
source /root/.bashrc
echo "✅ Aliases and MOTD applied"
```

---

## 📜 Configuration Philosophy

> See root `README.md` → Section `### 6. ⚙️ Server Configuration Philosophy` for full rules.

**Summary:** All settings are global. If a site behaves differently from others — log into its WP Admin, update all plugins/themes/core, and verify CAPTCHA is installed and active. Never edit individual site config files.

---

*= Rooted by VladiMIR | AI =*
