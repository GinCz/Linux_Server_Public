# 🖥️ Aliases Reference — 222-DE-NetCup (152.53.182.222)

> Server: **NetCup.com, Germany** | Ubuntu 24 / FASTPANEL / **Cloudflare** | CZ+EU sites  
> Shell prompt colour: **Yellow** `\[\033[01;33m\]`  
> Source file: [`222/.bashrc`](https://github.com/GinCz/Linux_Server_Public/blob/main/222/.bashrc)

---

## 💾 How to restore `.bashrc` on the server

```bash
curl -sS https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/.bashrc \
  > ~/.bashrc && source ~/.bashrc
```

---

## 🔵 System — Quick Commands

| Alias | Command | Description |
|---|---|---|
| `00` | `clear` | Clear the terminal screen |
| `infooo` | `222/infooo.sh` | Quick server overview: RAM, CPU, Disk, Load |
| `domains` | `222/domains.sh` | List all domains on this server with status |
| `cleanup` | `222/server_cleanup.sh` | Remove old logs, apt cache, temp files |
| `allinfo` | `222/all_servers_info.sh` | SSH into both servers, show combined RAM/Disk status |

---

## 🛡️ Security — CrowdSec & Bot Blocking

| Alias | Command | Description |
|---|---|---|
| `fight` | `222/block_bots.sh` | Block bad bots in Nginx (adds `deny` rules) |
| `banlog` | `222/banlog.sh 30` | CrowdSec dashboard: stats + top countries + top scenarios + **last 30 bans** |
| `banlog50` | `222/banlog.sh 50` | Same as `banlog` but shows **last 50 bans** |

> **Note:** `banunblock` and `banblock` use `cscli` directly, not aliased here — use raw commands:
> ```bash
> cscli decisions delete --ip 1.2.3.4   # unban
> cscli decisions add --ip 1.2.3.4       # manual ban
> ```

---

## ⏱️ Server Health Monitoring (SOS = "Show On Screen")

| Alias | Command | Description |
|---|---|---|
| `sos` | `222/sos.sh 1h` | Show Nginx errors / PHP-FPM errors from **last 1 hour** |
| `sos3` | `222/sos.sh 3h` | Last **3 hours** |
| `sos24` | `222/sos.sh 24h` | Last **24 hours** |
| `sos120` | `222/sos.sh 120h` | Last **120 hours** (5 days) |

---

## ⚙️ PHP-FPM & Nginx (Zero-Downtime Reload)

> ⚠️ **NEVER use `systemctl restart nginx`** — it drops ALL connections.  
> Always use `reload` which does a graceful hot-swap.

| Alias | Command | Description |
|---|---|---|
| `watchdog` | `222/php_fpm_watchdog.sh` | Scan and kill runaway PHP-FPM workers |
| `nginx-reload` | `nginx -t && systemctl reload nginx` | Test config + zero-downtime reload |
| `fpm-reload` | `php-fpm8.3 -t && systemctl reload php8.3-fpm` | Test + reload PHP 8.3 FPM |
| `reload-all` | fpm-reload + nginx-reload | Reload both in correct order |

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
| `backup` | `/root/backup_clean.sh` | Run local backup cleanup (keep last N copies) |
| `antivir` | `222/scan_clamav.sh` | ClamAV antivirus scan on all web directories |
| `aws-test` | `222/aws_test.sh` | Test S3 backup connectivity and credentials |

---

## 📬 Mail

| Alias | Command | Description |
|---|---|---|
| `mailclean` | `222/mailclean.sh` | Flush Postfix mail queue |

---

## 🐳 Crypto Bot (Docker)

| Alias | Command | Description |
|---|---|---|
| `tr` | `crypto-docker/scripts/tr_docker.sh` | Start/restart crypto trading bot container |
| `reset` | `crypto-docker/scripts/reset.sh` | Reset bot state and restart |
| `clog` | `docker logs crypto-bot --tail 40` | Show last **40 lines** of bot log |
| `clog100` | `docker logs crypto-bot --tail 100` | Show last **100 lines** of bot log |
| `f5bot` | `/root/docker_backup.sh` | Backup Docker volumes and configs |
| `f9bot` | `222/crypto_restore.sh` | Restore bot from last backup |

---

## 📁 Repository

| Alias | Command | Description |
|---|---|---|
| `repo` | `cd /root/Linux_Server_Public && git pull` | Pull latest public repo |
| `secret` | `cd ~/Secret_Privat && git pull && ls -la` | Go to private/secret repo |
| `save` | (in shared_aliases) | Push current server configs to GitHub |

---

## 🔗 Shared Aliases (from `scripts/shared_aliases.sh`)

Loaded automatically at the bottom of `.bashrc`. Documented separately in  
[`scripts/shared_aliases.sh`](https://github.com/GinCz/Linux_Server_Public/blob/main/scripts/shared_aliases.sh)

| Alias | Description |
|---|---|
| `load` | Pull latest from GitHub (git pull) |
| `save` | Add + commit + push all changes to GitHub |
| `aw` | `awk` shorthand |
| `grep` | `grep --color=auto` |
| `ls` | `ls --color=auto` |
| `mc` | Midnight Commander |

---

*= Rooted by VladiMIR | AI =*
