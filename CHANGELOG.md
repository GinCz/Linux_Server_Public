# Changelog — Linux_Server_Public

> All notable changes to server infrastructure, scripts, and configurations are documented here.
> Format: `[YYYY-MM-DD] | Server | Category | Description`

---

## [2026-06-10 14:19] — sos.sh v2026.06.10h — Verified ✅ + Incident Snapshot

**Server:** 222-DE-NetCup (152.53.182.222)  
**Version:** `v.2026.06.10h`  
**Time:** 14:19:18 CEST

### Верификация

Запустили `sos 24h` — полный вывод 31 секций без ошибок. Новая секция 27 работает корректно.

**Секция 27. OPEN PORTS — вывод подтверждён:**

```
  TCP LISTEN: (57 уникальных записей, без дублей named)
  UDP LISTEN: (25 уникальных записей)
  Key ports:
    21   FTP          open [TCP ]
    22   SSH          open [TCP ]
    53   DNS          open [TCP UDP]
    80   HTTP         open [TCP ]
    443  HTTPS        open [TCP UDP]
    ...  (23 порта всего)
    51820 WireGuard   closed
```

### Инциденты выявленные при верификации

| # | Инцидент | Секция | Приоритет |
|---|---|---|---|
| 1 | CrowdSec OOM kill повторяется — limit 400MB превышен (была 300M) | 04, 28 | 🔴 HIGH |
| 2 | 91.234.25.247 — 153 WP-login атаки, не забанен | 11 | 🔴 HIGH |
| 3 | crypto.gincz.com — 107×502 errors | 12 | 🟡 MEDIUM |
| 4 | kadernik-olga.eu — PHP Fatal: Unknown named parameter | 20 | 🟡 MEDIUM |
| 5 | MariaDB uptime: 13h32m — RECENT RESTART | 18 | 🟡 MEDIUM |
| 6 | Боты сканируют /secrets/gcp.json, /secrets/aws.json (8s slow) | 14 | ℹ️ INFO |

### Server State Snapshot 14:19

| Метрика | Значение |
|---|---|
| Load | 0.56 / 0.53 / 0.85 (14%) |
| RAM | 54% — 4.2Gi / 7.7Gi |
| Swap | 37% — 1.5Gi / 4.0Gi |
| Disk / | 23% — 59G / 247G |
| TCP connections | 202 (estab 25) |
| CrowdSec bans | 46 active |
| ipset vladblacklist | 119 IPs |
| PHP-FPM pools | 10 active |
| Docker | crypto-bot Up 20h |
| HTTP 200 (24h) | 21800 |
| HTTP 404 (24h) | 2725 |
| HTTP 502 (24h) | 142 |

### CrowdSec OOM — детали

```
memory: usage 409600kB, limit 409600kB (= 400MB)
swap:   usage 102160kB, limit 102400kB (= 100MB — почти заполнен)
Killed: pid 85542 (crowdsec) vm:2768708kB, rss:400468kB
Killed: pid 97457 (crowdsec) vm:3012944kB, rss:402504kB
OOM events total: 6
```

Нужно поднять лимит: `MemoryMax=500M`, `MemorySwapMax=200M`.

---

## [2026-06-10] — sos.sh v2026.06.10h — Полная секция Open Ports + удалён алиас `ports`

**Script:** `scripts/sos.sh`  
**Server:** 222-DE-NetCup (152.53.182.222)  
**Version:** `v2026.06.10h`

### Что сделано

#### 1. Переписана секция 27. ALL OPEN PORTS

Старая секция делала простой `ss -tlnp` без анализа — всё вываливалось сырым. Новая версия:

| Старая проблема | Решение |
|---|---|
| Тысячи дублей (named × 4 интерфейса × 4 строки) | `sort -u` по "addr:port + process" |  
| Нет UDP | Отдельный блок UDP LISTEN |
| Нет группировки | Группировка TCP и UDP по секциям |
| Нет сводной таблицы | Таблица Key ports с флагами [TCP ] / [TCP UDP] / closed |

#### 2. Удалён `alias ports` из `shared_aliases_222.sh`

`ports` стал полностью избыточным — вся его функциональность встроена в `sos` как секция 27.

### Files Changed

| File | Action |
|---|---|
| `scripts/sos.sh` | Переписана секция 27 OPEN PORTS: дедупликация, TCP+UDP, Key ports таблица |
| `scripts/shared_aliases_222.sh` | Удалён `alias ports=...` |
| `WORKLOG.md` | Подробный worklog сессии |
| `CHANGELOG.md` | Эта запись |

---

## [2026-06-10] — sos.sh v2026.06.10d — Unified Installer + Audit Script

**Script:** `scripts/sos.sh`
**Version:** `v2026.06.10d`

### Summary

The `install_sos.sh` script was eliminated entirely. All installation logic was merged
directly into `sos.sh`. The script now serves two purposes in a single file:
1. **Installer** — downloads itself, places binary at `/usr/local/bin/sos`, writes aliases
2. **Audit tool** — runs the full server status report for the selected time window

---

### Problem 1 — Two Scripts Were Redundant

Previously the workflow required:
```bash
bash <(curl install_sos.sh)   # step 1 — install
sos                           # step 2 — run audit
```

This was redundant. The user had to maintain two separate scripts in the repository,
keep them in sync, and run two commands for a simple setup. The `install_sos.sh` script
did nothing that `sos.sh` itself could not do.

**Fix:** Deleted `install_sos.sh`. All install logic (`curl` self-download, `chmod +x`,
alias injection into `.bashrc` / `.bash_profile`) moved into `sos.sh` as `do_install()`.

---

### Problem 2 — Missing "Run / Install" First Menu Step

When running `bash <(curl -fsSL .../sos.sh)`, the script was skipping the first
selection menu and jumping directly to the time window selection (1h / 3h / 24h / 120h).

**Final fix:** Compare `realpath "$0"` against `realpath "/usr/local/bin/sos"`.

```bash
SELF_REAL="$(realpath "$0" 2>/dev/null || echo "$0")"
SOS_BIN_REAL="$(realpath "/usr/local/bin/sos" 2>/dev/null || echo "/usr/local/bin/sos")"

if [ "$SELF_REAL" = "$SOS_BIN_REAL" ]; then
  IS_INSTALLED=1   # launched as installed binary → go directly to time window
else
  IS_INSTALLED=0   # launched via curl|bash → show "Run / Install" first
fi
```

---

### Final Behavior

#### Mode A — From GitHub (curl-pipe, first-time setup)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh)
```
Shows: `1) Run` / `2) Install` menu.

#### Mode B — Installed binary

```bash
sos          # asks time window
sos 1h       # runs immediately
sos 24h      # runs immediately
```

Aliases: `sos`, `sos1`, `sos3`, `sos24`, `sos120`

---

### Install Command

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh) && source ~/.bashrc
```

### Files Changed

| File | Action |
|---|---|
| `scripts/sos.sh` | Rewrote entry point, added `do_install()`, `IS_INSTALLED` detection via `realpath` |
| `scripts/install_sos.sh` | **Deleted** |
| `CHANGELOG.md` | This entry |

---

## [2026-05-31] — Go Runtime mmap Crash Fix (FastPanel File Manager / wowflow)

**Server:** 152.53.182.222 (EU-NetCup)  
**Affected service:** `filemanagersystemd@wowflow.service`

### Problem
`@wowflow hard as 300000` in `/etc/security/limits.conf` → 293 MB virtual address limit.
Go runtime reserves hundreds of GB virtual address space via `mmap` at startup.
Kernel enforces `RLIMIT_AS` → Go panics before `main()`.

### Fix
```bash
sed -i '/@wowflow hard as/d' /etc/security/limits.conf
systemctl daemon-reload
systemctl reset-failed filemanagersystemd@wowflow.service
systemctl start filemanagersystemd@wowflow.service
```

**Full postmortem:** `222/FASTPANEL_GO_MMAP_FIX.md`

---

## [2026-05-30] — Multi-Server ClamAV Audit + FastPanel File Manager Fix

### 🛡️ ClamAV — Full Network Audit (9 servers)

| Server IP | ClamAV Before | DB Before | Action | Result |
|---|---|---|---|---|
| 109.234.38.47 | ✅ INSTALLED | ✅ Present | No action needed | ✅ OK |
| 144.124.228.237 | ✅ INSTALLED | ❌ Missing | Sync DB from donor | ✅ Fixed |
| 144.124.232.9 | ✅ INSTALLED | ❌ Missing | Sync DB from donor | ✅ Fixed |
| 144.124.228.227 | ❌ NOT installed | ❌ Missing | Install + sync DB | ✅ Fixed |
| 144.124.239.24 | ✅ INSTALLED | ❌ Missing | Sync DB from donor | ✅ Fixed |
| 91.84.118.178 | ❌ NOT installed | ❌ Missing | Install + sync DB | ✅ Fixed |
| 146.103.110.176 | ❌ NOT installed | ❌ Missing | Install + sync DB | ✅ Fixed |
| 144.124.233.38 | ✅ INSTALLED | ✅ Present | No action needed | ✅ OK |
| 212.109.223.109 | ✅ INSTALLED | ✅ Present | No action needed | ✅ OK |

**Donor server:** `152.53.182.222`

---

## [2026-05-29] — ClamAV Scan Script + Multi-Server Monitoring

- `scan_clamav.sh` established on `212.109.223.109` — weekly Sunday 02:00 cron
- Multi-server monitoring scripts reviewed and updated
- VPN server network audit performed

---

## [2026-03-12] — Cloudflare Configuration Backup

- `109/cloudflare.conf.bak.20260312` — backup before Cloudflare IP range update
- `109/cloudflare_real_ip.conf.bak.20260312` — backup of real IP resolution config
- Nginx reloaded after applying updated Cloudflare IP ranges

---

> _= Rooted by VladiMIR + AI | v.2026.06.10h | github.com/GinCz/Linux_Server_Public =_
