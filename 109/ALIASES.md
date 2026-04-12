# 🖥️ Aliases Reference — 109-RU-FastVDS (212.109.223.109)

> Server: **FastVDS.ru, Russia** | Ubuntu 24 / FASTPANEL | **No Cloudflare** | RU sites  
> Shell prompt colour: **Light Pink** `\[\e[38;5;217m\]`  
> Source file: [`109/.bashrc`](https://github.com/GinCz/Linux_Server_Public/blob/main/109/.bashrc)

---

## 💾 How to restore `.bashrc` on the server

```bash
curl -sS https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/109/.bashrc \
  > ~/.bashrc && source ~/.bashrc
```

---

## ⏱️ Server Health Monitoring — SOS ("Show On Screen")

> Script: `109/sos.sh` — показывает ошибки Nginx + PHP-FPM за указанный период.  
> Параметры: `1h` `3h` `24h` `120h` — передаются скрипту как аргумент.  
> ✅ Правильные команды: `sos` `sos1` `sos3` `sos24` `sos120`  
> ❌ Неправильно: `SOS 1` `SOS1` — bash алиасы регистрозависимы!

| Alias | Скрипт + аргумент | Период | Описание |
|---|---|---|---|
| `sos` | `sos.sh 1h` | **1 час** | Ошибки за последний час (то же что `sos1`) |
| `sos1` | `sos.sh 1h` | **1 час** | Ошибки за последний час (то же что `sos`) |
| `sos3` | `sos.sh 3h` | **3 часа** | Ошибки за последние 3 часа |
| `sos24` | `sos.sh 24h` | **24 часа** | Ошибки за последние 24 часа |
| `sos120` | `sos.sh 120h` | **120 часов** | Ошибки за последние 5 дней |

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
| `banlog` | `109/banlog.sh 30` | CrowdSec dashboard: stats + top countries + top scenarios + **last 30 bans** |
| `banlog50` | `109/banlog.sh 50` | Same as `banlog` but shows **last 50 bans** |
| `banunblock` | `cscli decisions delete --ip` | Unban an IP address: `banunblock 1.2.3.4` |
| `banblock` | `cscli decisions add --ip` | Manually ban an IP: `banblock 1.2.3.4` |

---

## ⚙️ PHP-FPM & Nginx (Zero-Downtime Reload)

> ⚠️ **NEVER use `systemctl restart nginx`** — it drops ALL connections.  
> Always use `reload` which does a graceful hot-swap.

| Alias | Command | Description |
|---|---|---|
| `watchdog` | `109/php_fpm_watchdog.sh` | Scan and kill runaway PHP-FPM workers |
| `nginx-reload` | `nginx -t && systemctl reload nginx` | Test config + zero-downtime reload |
| `fpm-reload` | `php-fpm8.3 -t && systemctl reload php8.3-fpm` | Test + reload PHP 8.3 FPM |
| `reload-all` | fpm-reload + nginx-reload | Reload both in correct order (fpm first, then nginx) |

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
| `mailclean` | `109/mailclean.sh` | Flush Postfix mail queue |

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
