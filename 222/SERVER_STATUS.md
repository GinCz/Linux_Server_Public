# 📊 server_status.sh — Real-Time Server Snapshot

> **Version:** v2026-07-08
> **Server:** 222-DE-NetCup | IP: 152.53.182.222 | Ubuntu 24 / FASTPANEL
> **= Rooted by VladiMIR | AI =**

---

## 🎯 Purpose

`server_status.sh` is the main tool for instant server diagnostics.
It answers the question: **"What is happening on the server right now?"**

The script was created because standard commands (`top`, `htop`, `ps`) give a fragmented picture. A **single call** is needed to show:

- who is consuming memory and CPU (MariaDB, Netdata, PHP-FPM pools per site)
- whether Docker containers are running (crypto-bot, VPN nodes)
- which services have crashed and why
- whether a `wp-login.php` attack is happening right now
- how many bans CrowdSec has issued
- who last logged in via SSH

---

## 🚀 Installation (persistent — survives reboot)

```bash
# 1. Copy the script to system PATH
cp /root/Linux_Server_Public/222/server_status.sh /usr/local/bin/server_status.sh
chmod +x /usr/local/bin/server_status.sh

# 2. Add alias to .bashrc
echo "alias status='bash /usr/local/bin/server_status.sh'" >> /root/.bashrc
source /root/.bashrc

# 3. Verify
status
```

> ⚠️ The script is stored in two places:
> - `/usr/local/bin/server_status.sh` — **working copy on the server** (survives reboot)
> - `/root/Linux_Server_Public/222/server_status.sh` — **backup copy in the repository**
>
> After editing — sync both locations!

---

## 📌 Quick update from GitHub

```bash
# Update repo and recopy
cd /root/Linux_Server_Public && git pull --rebase
cp /root/Linux_Server_Public/222/server_status.sh /usr/local/bin/server_status.sh
chmod +x /usr/local/bin/server_status.sh
echo "Done — status updated"
```

---

## 🖥️ Usage

```bash
status                          # Full snapshot (alias)
bash /usr/local/bin/server_status.sh    # Direct call
status 2>/dev/null | less -R    # With scrolling (if screen is small)
```

### Automatic logging (optional — cron)

```bash
# Write once per hour to log
0 * * * * /usr/local/bin/server_status.sh >> /var/log/server_status.log 2>&1

# Clear log (to prevent indefinite growth) — add to cron:
0 4 * * 1 echo "" > /var/log/server_status.log
```

---

## 📋 What the script shows — section by section

### 1. LOAD AVERAGE & UPTIME
Shows load for the last 1/5/15 minutes as % of core count (4 vCore).
**Color:** green (<60%), yellow (60–90%), red (>90%).
*Why it matters:* If load1 > 4.0 — server is overloaded, need to find the culprit urgently.

### 2. MEMORY (RAM + SWAP)
Full table of free/used/available RAM and Swap.
*Server: 8GB DDR5 ECC.*
*Why it matters:* MariaDB alone takes ~1 GB, Netdata ~220 MB, PHP-FPM pools — another 100–160 MB each.
When RAM runs out — server starts swapping → sharp slowdown of all sites.

### 3. DISK USAGE
Shows all mounted partitions with % fill level.
*Server: 256GB NVMe.*
*Why it matters:* Full disk → Nginx and MySQL stop writing logs → sites crash without obvious reason.

### 4. TOP 20 PROCESSES BY MEMORY (RSS)
Sorted list of processes by actual memory used (RSS).
Shows: PID, USER, %CPU, %MEM, RSS in MB, process name.
*Why it matters:* This is where you see that MariaDB (mysql user) holds 1GB, Netdata — 220MB, each PHP-FPM worker for wowflow.cz — 160MB.

### 5. TOP 10 PROCESSES BY CPU%
Processes currently loading the CPU.
*Why it matters:* During attacks — you can see 100% CPU on nginx or php-fpm right here.

### 6. PHP-FPM POOLS
Aggregated statistics by PHP-FPM pools: how many workers are running and how much memory each pool is using.
*Sites on the server:* wowflow.cz, bio-zahrada.eu, svetaform.eu, gincz (PHP 8.4), lybawa.com etc.
*Why it matters:* If one pool holds 20+ workers — it has problems (infinite request, MySQL deadlock, attack).

### 7. MYSQL / MARIADB
Shows: number of connections, running threads, slow queries, DB uptime, active PROCESSLIST.
*Why it matters:* Slow queries and hanging connections — #1 cause of WordPress site freezes.

### 8. NGINX STATUS
Number of workers, stub_status status (if enabled), number of TCP connections ESTABLISHED.
*Why it matters:* During DDoS — connection count rises sharply. Visible immediately.

### 9. DOCKER CONTAINERS
Status of all Docker containers: CPU%, Memory, status (Up/Exited).
*Running on the server:*
- `crypto-bot` — trading bot (Python)
- VPN nodes (8 units, backed up via `f5vpn`)
*Why it matters:* If crypto-bot crashes — visible here immediately, not 2 hours later.

### 10. KEY SERVICES STATUS
State of all key services: nginx, mariadb, php-fpm (all versions), crowdsec, netdata, exim4, dovecot, named, docker, ssh, cron.
*Shows:* active/inactive/failed + enabled/disabled.
*Why it matters:* Cron marked as disabled will not start after reboot.

### 11. CROWDSEC — ACTIVE BANS
Current number of active bans + last 10 blocked IPs.
*Why it matters:* CrowdSec protects all 15+ sites. If there's no ban list — bouncer is not working.

### 12. WP-LOGIN BRUTE FORCE ATTACKS
Scans all access.log files (`/var/www/*/data/logs/*access.log`) and counts requests to `wp-login.php` by IP.
*Color:* red (>100 attempts), yellow (>20), white (few).
*Real example (2026-04-10):*
```
1033 hits — 141.98.11.120 (balance-b2b.eu)
  25 hits — 167.179.19.229 (doska-hun.ru)
```
*Why it matters:* 1033 attempts from one IP — this is an attack that CrowdSec should have caught.

### 13. OPEN PORTS
List of all TCP ports in LISTEN state with process name.
*Why it matters:* Allows you to notice an unexpectedly open port (hack, miner).

### 14. LAST LOGINS
Last 5 successful logins to the server.
*Why it matters:* Access audit.

### 15. FAILED SSH LOGIN ATTEMPTS
Unique IPs with failed SSH attempts in the last 24 hours.
*Why it matters:* If CrowdSec is working — these IPs should already be banned.

### 16. DISK USAGE BY SITE (/var/www)
Top 10 heaviest sites by file size.
*Why it matters:* One overgrown site can consume all NVMe space.

---

## 📁 Related scripts (aliases from .bashrc)

| Alias | Script | What it does |
|-------|--------|--------------|
| `status` | `server_status.sh` | ⭐ This script — full snapshot |
| `infooo` | `infooo.sh` | System versions + CPU/RAM/Disk benchmark |
| `watchdog` | `php_fpm_watchdog.sh` | Restart hung PHP-FPM pools |
| `fight` | `block_bots.sh` | Block bots by user-agent |
| `banlog` | `banlog.sh 30` | Ban log for last 30 minutes |
| `sos` | `sos.sh 1h` | Detailed log analysis for 1 hour |
| `domains` | `domains.sh` | HTTP status + **SSL days to expiry** + auto-renew <15d |
| `allinfo` | `all_servers_info.sh` | Status of both servers (222 + 109) |
| `clog` | docker logs | crypto-bot logs (last 40 lines) |
| `f5vpn` | `vpn_docker_backup.sh` | Backup all VPN Docker nodes |

---

## 🔒 IP Whitelist (Trusted IPs)

> **Date added:** 12.04.2026
> **Reason:** Trusted IPs (VladiMIR + AmneziaWG clients + servers) were not excluded from protection and could be accidentally banned. Fixed at two levels simultaneously.

### Level 1 — Nginx `geo` whitelist

File: `/etc/nginx/conf.d/00-wp-protection-zones.conf`
Mechanism: IPs with key `""` are completely ignored by all `limit_req_zone`.

### Level 2 — CrowdSec allowlist `trusted-ips`

```bash
cscli allowlists inspect trusted-ips   # view
cscli allowlists add trusted-ips IP    # add new IP
```

### Trusted IP list

| IP | Name | Purpose |
|----|------|---------|
| `185.100.197.16` | VladiMIR home | Nupaky — home/work PC |
| `90.181.133.10` | VladiMIR work | work IP |
| `185.14.233.235` | VladiMIR home #2 | backup home IP |
| `185.14.232.0` | VladiMIR home #3 | backup IP |
| `212.34.148.51` | ALEX_51 | XRAY + Samba |
| `144.124.228.237` | 4TON_237 | XRAY + Samba |
| `144.124.232.9` | TATRA_9 | XRAY + Samba + Kuma Monitoring |
| `144.124.228.227` | SHAHIN_227 | AmneziaWG + Samba |
| `144.124.239.24` | STOLB_24 | XRAY + Samba + AdGuard Home |
| `195.63.138.33` | PILIK_33 | XRAY + Samba |
| `146.103.110.176` | ILYA_176 | XRAY + Samba |
| `144.124.233.38` | SO_38 | XRAY + Samba |
| `3.79.14.42` | AWS | XRAY |
| `82.223.116.38` | IONOS | XRAY |
| `152.53.182.222` | 222-DE-NetCup | this server |
| `212.109.223.109` | RU-FastVDS | second server |
| `141.101.234.14` | infra-1 | Cloudflare / infrastructure |
| `82.112.63.133` | infra-2 | infrastructure |

> ⚠️ When adding a new IP — update **both** places: Nginx conf + CrowdSec allowlist!
> ⛔ `91.84.118.178` — **removed** (old VPN 178, replaced by PILIK_33)

---

## 🔧 Change History

| Date | Change |
|------|--------|
| 2026-04-10 | ✅ Script v2026-04-10 created. All 16 sections added. Documentation. |
| 2026-04-12 | ✅ IP whitelist added: Nginx geo + CrowdSec allowlist `trusted-ips` (16 IPs, expiry: never). |
| 2026-06-29 | ✅ SSL system: 4 domains migrated to acme.sh + DNS-01/Cloudflare. Written `acme-deploy-fastpanel.sh`. `domains.sh` updated — shows SSL days + auto-renew <15d. Cron: weekly check Saturday 02:15. Documentation: [`SSL_ACME_FASTPANEL_FIX.md`](https://github.com/GinCz/Linux_Server_Public/blob/main/222/SSL_ACME_FASTPANEL_FIX.md). |
| 2026-07-08 | ✅ CrowdSec allowlist: removed `91.84.118.178` (old VPN 178), added `195.63.138.33` (PILIK_33). Fixed CrowdSec scenarios: `custom/wp-login-hardban` (removed `distinct`, filter any POST), `custom/wp-login-bf-any` (leakspeed 36s, blackhole 1h). Added AWS/IONOS to whitelist table. |

---

## ⚠️ Important Notes

1. **MySQL PROCESSLIST** — script runs as root, so `mysql -e` works without a password (socket auth).
2. **Nginx stub_status** — if not configured, the section will show a warning. To enable: add `location /nginx_status { stub_status on; allow 127.0.0.1; deny all; }` to nginx config.
3. **Docker stats** takes ~1-2 seconds (required to get CPU%).
4. **wp-login scan** on 15+ sites can take 2-5 seconds with large log volumes.
5. **Total execution time** of the script: 5–10 seconds.

---

*= Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =*
