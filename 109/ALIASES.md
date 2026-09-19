# 🖥️ Aliases Reference — 109-RU-FastVDS (xxx.xxx.xxx.109)

> **Server:** FastVDS.ru, Russia | Ubuntu 24 / FASTPANEL | **No Cloudflare** | RU sites  
> **Shell prompt color:** Light Pink `\[\e[38;5;217m\]`  
> **Source file:** [`109/.bashrc`](https://github.com/GinCz/Linux_Server_Public/blob/main/109/.bashrc)  
> **Version:** v2026-04-13

---

## 🔄 How to restore `.bashrc` on the server

```bash
curl -sS https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/109/.bashrc \
  > ~/.bashrc && source ~/.bashrc
```

---

## 📊 SOS — Server Health Monitor

**Script:** [`109/sos.sh`](https://github.com/GinCz/Linux_Server_Public/blob/main/109/sos.sh)  
**Purpose:** Full real-time server health report — system load, RAM, disk, top processes,
traffic, HTTP errors, security events, services status and more.  
**Time window** is passed as argument by the alias (1h / 3h / 24h / 120h).

> ✅ **Correct usage:** `sos` `sos1` `sos3` `sos24` `sos120`  
> ❌ **Wrong:** `sos 24h` `SOS1` — aliases are case-sensitive!

| Alias | Argument | Period | Description |
|---|---|---|---|
| `sos` | `1h` | **1 hour** | Quick check — last 1 hour (same as `sos1`) |
| `sos1` | `1h` | **1 hour** | Quick check — last 1 hour (same as `sos`) |
| `sos3` | `3h` | **3 hours** | Last 3 hours — for recent incidents |
| `sos24` | `24h` | **24 hours** | Last 24 hours — daily overview |
| `sos120` | `120h` | **5 days** | Last 5 days — for trend analysis |

### 📋 What SOS displays (in order)

| # | Block | Description |
|---|---|---|
| 1 | ⚙️ SYSTEM | Uptime, RAM usage, Swap usage |
| 2 | 💿 DISK | All `/dev/*` mounts: size, used, available, % |
| 3 | 🔥 TOP 10 CPU% | Top 10 processes by CPU usage |
| 4 | 🔍 TOP 15 RAM | Top 15 processes by RAM (RSS in MB) |
| 5 | 🧠 PHP-FPM POOLS | Workers count + RAM per pool user |
| 6 | 🚀 TOP-5 TRAFFIC | Top 5 access logs by request count in time window |
| 7 | 🌍 TOP-10 IPs | Top 10 client IPs by request count in time window |
| 8 | 📈 HTTP STATUS | HTTP response codes breakdown (2xx/3xx/4xx/5xx) |
| 9 | 🔐 WP-LOGIN ATTACKS | Top IPs hitting `wp-login.php` — brute force detection |
| 10 | 🔗 NGINX | Worker count, active TCP connections, stub status |
| 11 | 💾 MYSQL | Threads connected, running, slow queries count |
| 12 | 🐳 DOCKER | All containers with status (green=Up / red=stopped) |
| 13 | ❌ CRITICAL ERRORS | Fatal errors from all site error logs in time window |
| 14 | 🛡️ CROWDSEC | Active bans count + recent alerts in time window |
| 15 | 🔧 SERVICES | Status of: nginx, mariadb, php-fpm, crowdsec, ssh, etc. |
| 16 | 💤 SWAP TOP-3 | Top 3 processes consuming swap memory |
| 17 | 🐢 PHP-FPM SLOW LOG | Slow log entries per pool (last 24h) — red if > 0 |
| 18 | 🔴 HTTP 502/503 BY DOMAIN | 502/503 errors grouped by domain — red if ≥ 10 |
| 19 | 💽 DISK I/O | Real-time NVMe read/write speed (MB/s, 1s sample) |
| 20 | 🛡️ CROWDSEC METRICS | Parser metrics: parsed / overflow / dropped |
| 21 | 🗄️ MARIADB UPTIME | MariaDB uptime in days/hours/min — red + warning if < 24h |

---

## 🔵 System — Quick Commands

| Alias | Command | Description |
|---|---|---|
| `00` | `clear` | Clear the terminal screen |
| `infooo` | `109/infooo.sh` | Quick server overview: RAM, CPU, Disk, Load |
| `domains` | `109/domains.sh` | List all domains on this server with status |
| `cleanup` | `109/server_cleanup.sh` | Remove old logs, apt cache, temp files |
| `allinfo` | `109/all_servers_info.sh` | SSH into both servers, show combined RAM/Disk status |

---

## 🛡️ Security — CrowdSec & Bot Blocking

| Alias | Command | Description |
|---|---|---|
| `fight` | `109/block_bots.sh` | Block bad bots in Nginx (adds `deny` rules) |
| `banlog` | `109/banlog.sh 30` | CrowdSec dashboard: stats + top countries + top scenarios + last 30 bans |
| `banlog50` | `109/banlog.sh 50` | Same as `banlog` but shows last 50 bans |
| `banunblock` | `cscli decisions delete --ip` | Unban an IP: `banunblock 1.2.3.4` |
| `banblock` | `cscli decisions add --ip` | Manually ban an IP: `banblock 1.2.3.4` |

---

## ⚙️ PHP-FPM & Nginx (Zero-Downtime Reload)

> ⚠️ **NEVER use `systemctl restart nginx`** — it drops ALL active connections.  
> Always use `reload` — graceful hot-swap with zero downtime.

| Alias | Command | Description |
|---|---|---|
| `watchdog` | `109/php_fpm_watchdog.sh` | Scan and kill runaway PHP-FPM workers |
| `nginx-reload` | `nginx -t && systemctl reload nginx` | Test config + zero-downtime reload |
| `fpm-reload` | `php-fpm8.3 -t && systemctl reload php8.3-fpm` | Test + reload PHP 8.3 FPM |
| `reload-all` | fpm-reload + nginx-reload | Reload both in correct order (FPM first, then Nginx) |

---

## 💾 WordPress

| Alias | Command | Description |
|---|---|---|
| `wpupd` | `109/wp_update_all.sh` | Update all WP sites: core + plugins + themes |
| `wpcron` | `109/run_all_wp_cron.sh` | Manually trigger WP-Cron on all sites |
| `wphealth` | `109/wphealth.sh` | Check health status of all WP sites |

---

## 💻 Backup & Antivirus

| Alias | Command | Description |
|---|---|---|
| `backup` | `109/system_backup.sh` | Full system backup (files + databases) |
| `antivir` | `109/scan_clamav.sh` | ClamAV antivirus scan on all web directories |
| `aws-test` | `109/aws_test.sh` | Test S3 backup connectivity and credentials |

---

## 📬 Mail

| Alias | Command | Description |
|---|---|---|
| `mailclean` | `109/mailclean.sh` | Flush Postfix/Exim mail queue |

---

## 📁 Repository

| Alias | Command | Description |
|---|---|---|
| `repo` | `cd /root/Linux_Server_Public && git pull` | Pull latest public repo |
| `secret` | `cd ~/Secret_Privat && git pull` | Go to private/secret repo |
| `save` | add + commit + push | Push current server configs to GitHub |
| `load` | `git pull` | Pull latest from GitHub |

---

*= Rooted by VladiMIR | AI = v2026-04-13*
