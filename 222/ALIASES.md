# 🖥️ Aliases Reference — 222-DE-NetCup (152.53.182.222)

> **Server:** NetCup.com, Germany | Ubuntu 24 / FASTPANEL | **Cloudflare** | EU/CZ/DE sites
> **Shell prompt color:** Yellow `\[\033[01;33m\]`
> **Source file:** [`222/.bashrc`](https://github.com/GinCz/Linux_Server_Public/blob/main/222/.bashrc)
> **Version:** v2026-06-29

---

## 🔄 How to restore `.bashrc` on the server

```bash
curl -sS https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/.bashrc \
  > ~/.bashrc && source ~/.bashrc
```

---

## 📊 SOS — Server Health Monitor

**Script:** [`222/sos.sh`](https://github.com/GinCz/Linux_Server_Public/blob/main/222/sos.sh)
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
| `infooo` | `222/infooo.sh` | Quick server overview: RAM, CPU, Disk, Load, Docker |
| `domains` | `222/domains.sh` | All domains: HTTP status + **SSL days to expiry** + auto-renew if <15d |
| `cleanup` | `222/server_cleanup.sh` | Remove old logs, apt cache, temp files |
| `allinfo` | ⚠️ TODO | SSH into both servers + combined RAM/Disk — script `222/all_servers_info.sh` not yet created |

---

## 🔐 SSL / Certificates — acme.sh + FastPanel

> ⚠️ **IMPORTANT: read [`SSL_ACME_FASTPANEL_FIX.md`](https://github.com/GinCz/Linux_Server_Public/blob/main/222/SSL_ACME_FASTPANEL_FIX.md) before any actions with certificates!**

**Problem:** FastPanel updates SSL via HTTP-01 challenge, which fails behind Cloudflare proxy (🟠).
**Solution:** acme.sh with DNS-01 challenge via Cloudflare API — works always, regardless of proxy.

| Domain | Method | Next renew |
|---|---|---|
| timan-kuchyne.cz | acme.sh DNS-01 / Cloudflare | ~2026-08-28 |
| eco-seo.eu | acme.sh DNS-01 / Cloudflare | ~2026-08-28 |
| gincz.com | acme.sh DNS-01 / Cloudflare | ~2026-08-28 |
| kk-med.cz | acme.sh DNS-01 / Cloudflare | ~2026-08-27 |
| *all others* | FastPanel HTTP-01 (auto) | — |

**❌ DO NOT CLICK** "Renew certificate" in FastPanel for the domains above — it will overwrite the paths!

**Cron (every Saturday at 02:15):**
```
15 2 * * 6  bash /root/Linux_Server_Public/222/domains.sh >> /var/log/acme-deploy.log 2>&1
```

**Key commands:**
```bash
domains                                          # check all domains + SSL right now
/.acme.sh/acme.sh --list                         # list of domains under acme.sh
tail -50 /var/log/acme-deploy.log               # log of last deploy/renew
/.acme.sh/acme.sh --renew -d DOMAIN --force     # force re-issue
```

**Add a new domain (if behind Cloudflare proxy):**
```bash
/.acme.sh/acme.sh --issue --dns dns_cf -d DOMAIN -d www.DOMAIN --keylength ec-256
/.acme.sh/acme.sh --install-cert -d DOMAIN \
  --cert-file /var/www/httpd-cert/DOMAIN_$(date +%Y-%m-%d).crt \
  --key-file /var/www/httpd-cert/DOMAIN_$(date +%Y-%m-%d).key \
  --fullchain-file /var/www/httpd-cert/DOMAIN_$(date +%Y-%m-%d)_fullchain.crt \
  --reloadcmd "bash /root/acme-deploy-fastpanel.sh DOMAIN"
```

> 📄 Full documentation: [`SSL_ACME_FASTPANEL_FIX.md`](https://github.com/GinCz/Linux_Server_Public/blob/main/222/SSL_ACME_FASTPANEL_FIX.md)

---

## 🛡️ Security — CrowdSec & Bot Blocking

> ℹ️ **CrowdSec 0 bans = NORMAL.** Empty ban list means no active bans right now, not a malfunction.

| Alias | Command | Description |
|---|---|---|
| `fight` | `222/block_bots.sh` | Block bad bots in Nginx (adds `deny` rules) |
| `banlog` | `222/banlog.sh 30` | CrowdSec dashboard: stats + top countries + last 30 bans |
| `banunblock` | `cscli decisions delete --ip` | Unban an IP: `banunblock 1.2.3.4` |
| `banblock` | `cscli decisions add --ip` | Manually ban an IP: `banblock 1.2.3.4` |

---

## ⚙️ PHP-FPM & Nginx (Zero-Downtime Reload)

> ⚠️ **NEVER use `systemctl restart nginx`** — it drops ALL active connections.
> Always use `reload` — graceful hot-swap with zero downtime.

| Alias | Command | Description |
|---|---|---|
| `watchdog` | `222/php_fpm_watchdog.sh` | Scan and kill runaway PHP-FPM workers |
| `nginx-reload` | `nginx -t && systemctl reload nginx` | Test config + zero-downtime Nginx reload |

---

## 💾 WordPress

| Alias | Command | Description |
|---|---|---|
| `wpupd` | `222/wp_update_all.sh` | Update all WP sites: core + plugins + themes |
| `wpcron` | `222/run_all_wp_cron.sh` | Manually trigger WP-Cron on all sites |
| `wphealth` | `222/wphealth.sh` | Check health status of all WP sites |

---

## 💻 Backup & Antivirus

| Alias | Command | Description |
|---|---|---|
| `backup` | `222/backup_clean.sh` | Full system backup (files + databases) |
| `antivir` | `222/scan_clamav.sh` | ClamAV antivirus scan on all web directories |
| `aws-test` | `222/aws_test.sh` | Test S3 backup connectivity and credentials |

---

## 📬 Mail

| Alias | Command | Description |
|---|---|---|
| `mailclean` | `222/mailclean.sh` | Flush Postfix/Exim mail queue |

---

## 🤖 Crypto-Bot (Docker)

| Alias | Command | Description |
|---|---|---|
| `tr` | `crypto-docker/scripts/tr_docker.sh` | Start/restart trading bot in Docker |
| `reset` | `crypto-docker/scripts/reset.sh` | Reset bot state and restart |
| `clog` | `docker logs crypto-bot --tail 40` | Show last 40 lines of bot logs |
| `clog100` | `docker logs crypto-bot --tail 100` | Show last 100 lines of bot logs |
| `f5bot` | `/root/docker_backup.sh` | Backup crypto-bot Docker container |
| `f9bot` | `222/crypto_restore.sh` | Restore crypto-bot from backup |

---

## 🔒 VPN

| Alias | Command | Description |
|---|---|---|
| `f5vpn` | ⚠️ BROKEN | `VPN/vpn_docker_backup.sh` — fails on all 8 VPN servers (SSH unreachable). **Do not use until fixed.** |

---

## 📁 Repository

| Alias | Command | Description |
|---|---|---|
| `repo` | `git pull + source .bashrc` | Pull latest public repo + reload aliases |
| `save` | add + commit + push | Push current server configs to GitHub |
| `load` | git stash → pull → stash pop | Pull latest from GitHub. **Auto-stash** added — no more "unstaged changes" error |

> ⚠️ **`secret` alias removed** — private repo pull disabled (was `git -C ~/Secret_Privat pull`)

---

## 📅 Full Cron Schedule

```
@reboot   sleep 5 && ipset restore + iptables-restore          # firewall at startup
@reboot   sleep 30 && night_update.sh --audit                  # audit at startup
0 */3     IPGuard collect → GitHub                             # collect blacklist from VPN nodes
30 */3    IPGuard deploy → ipset local                         # apply blacklist
0 2 * * 6 night_update.sh --mode=sites                        # package update (Saturday 02:00)
15 2 * * 6 domains.sh → SSL check + auto-renew <15d           # certificate check (Saturday 02:15)
```

> Saturday 02:00 → system update first, 02:15 → then SSL check (correct order).

---

*= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =*
