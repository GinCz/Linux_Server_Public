# WORKLOG — Linux_Server_Public

> Full session-by-session work log.
> = Rooted by VladiMIR | AI =

---

# 📅 Session: 2026-06-10

> 10 June 2026 | 12:00 – 14:00 CEST
> Affected: **222-DE-NetCup** (152.53.182.222) — `sos.sh`, `shared_aliases_222.sh`

---

## 📋 Session Summary

1. Диагностировали текущее состояние открытых портов на 222 — запустили `ports` алиас, получили полный вывод
2. Выявлен системный баг: в `sos.sh` секция портов была убогой — дубликаты, нет группировки, нет UDP, нет таблицы Key ports
3. Переписали секцию `27. ALL OPEN PORTS` в `sos.sh` — полная дедупликация, группировка по сервисам, TCP/UDP флаги, таблица с ключевыми портами и их статусами
4. Удалили алиас `ports` из `shared_aliases_222.sh` — стал полностью избыточным после улучшения sos
5. Версия `sos.sh` поднята до `v2026.06.10`

---

## 🔍 Диагностика — что показал `ports` перед удалением

Запуск `ports` на сервере 222 показал полную картину:

**TCP LISTEN (выборка ключевых):**
| Порт | Сервис | Bind |
|---|---|---|
| 22, 2222 | sshd | 0.0.0.0, [::] |
| 25, 465, 587 | exim4 | 0.0.0.0, [::] |
| 80, 443 | nginx | 152.53.182.222, [2a0a:4cc0:...] |
| 110, 143, 993, 995 | dovecot | 0.0.0.0, [::] |
| 139, 445 | smbd | 0.0.0.0, [::] |
| 3306 | mariadbd | 127.0.0.1 (local only) ✅ |
| 5000 | docker-proxy | 127.0.0.1 (local only) ✅ |
| 6379 | redis-server | 127.0.0.1, [::1] (local only) ✅ |
| 7777, 8888 | fastpanel2-nginx | 0.0.0.0 |
| 8443 | xray-linux-amd64 | * (any) |
| 9100 | prometheus-node | * (any) |
| 30452 | x-ui | * (any) |
| 11211 | memcached | 127.0.0.1, [::1] (local only) ✅ |

**UDP LISTEN:**
- `named` (BIND9) слушает на всех интерфейсах включая `[::1]`, `fe80::` link-local, публичный IPv6 `[2a0a:...]`
- `nginx` слушает UDP 443 (HTTP/3 QUIC) — на публичном IPv4 и IPv6
- `nmbd` (NetBIOS) открыт на 137/138 UDP — широковещательные адреса нескольких интерфейсов

---

## 🔧 Изменение 1 — `sos.sh`: новая секция 27. ALL OPEN PORTS

### Проблема (старая версия)
Секция портов в `sos.sh` просто делала `ss -tlnp` — никакой обработки:
- **Тысячи дублей** — `named` слушает на 4+ интерфейсах × 4 строки каждый = 50+ одинаковых строк
- **Нет UDP** — вся UDP-картина была скрыта
- **Нет группировки** — нельзя сразу увидеть какой сервис на каком порту
- **Нет сводной таблицы** — Key ports (22/25/53/80/443 и т.д.) не проверялись

### Решение (новая версия)

Секция переписана по образцу отдельного скрипта `ports`, но умнее:

```bash
# Дедупликация: sort -u по полю "порт+сервис" — убирает все дубли named/nmbd
# Парсинг: ss -tlnp и ss -ulnp отдельно
# Группировка: для каждого уникального порта — один сервис, список bind-адресов
# Key ports: явная проверка 22/25/53/80/443/139/445/8080/8443/51820 с TCP/UDP флагами
```

**Что показывает новая секция:**

```
══════════════════════════════════════════
  OPEN PORTS — 222-DE-NetCup
══════════════════════════════════════════

  TCP LISTEN:
    [::]:110                  "dovecot"
    [::1]:11211               "memcached"
    ...  (дедуплицировано, без повторов named)

  UDP LISTEN:
    [::1]:53                  "named"
    ...  (только уникальные)

  Key ports:
    22     SSH             open [TCP ]
    25     SMTP            open [TCP ]
    53     DNS             open [TCP UDP]
    80     HTTP            open [TCP ]
    139    Samba-NB        open [TCP ]
    443    HTTPS           open [TCP UDP]
    445    Samba           open [TCP ]
    3000   Semaphore/AGH   closed
    8080   AGH-Web         open [TCP ]
    8443   HTTPS-alt       open [TCP ]
    51820  WireGuard       closed
══════════════════════════════════════════
```

### Логика дедупликации
```bash
# Парсим ss, выбираем поле адрес:порт + имя сервиса
# sort -u — убирает полные дубли
# Для named (53) это убирает 16+ одинаковых строк → остаётся по одной на интерфейс
```

### Key ports — логика
```bash
# Для каждого ключевого порта:
# TCP: grep ss output на этот порт → есть/нет
# UDP: grep ss -u output на этот порт → есть/нет
# Выводим: open [TCP UDP] / open [TCP ] / closed
```

---

## 🔧 Изменение 2 — удалён алиас `ports` из `shared_aliases_222.sh`

### До
```bash
alias ports='bash /usr/local/bin/ports'
```
И отдельный скрипт `/usr/local/bin/ports` — `222/ports.sh` в репозитории.

### После
Алиас удалён. Скрипт `ports.sh` помечен как deprecated (или удалён).

### Обоснование
Вся функциональность `ports` теперь встроена в `sos` как секция 27.
Запуск `sos` (или `sos 24h`) включает полный анализ портов с дедупликацией.
Поддерживать два отдельных источника информации о портах — избыточно и создаёт рассинхрон.

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `scripts/sos.sh` | Updated | Секция 27 — полная перепись с дедупликацией TCP/UDP + Key ports таблица; v2026.06.10 |
| `scripts/shared_aliases_222.sh` | Updated | Удалён `alias ports=...` |
| `WORKLOG.md` | Updated | Эта запись |
| `CHANGELOG.md` | Updated | Добавлена запись v2026.06.10 |

---

## ⚠️ Open TODOs после этой сессии

| # | TODO | Priority |
|---|---|---|
| 1 | Синхронизировать `/usr/local/bin/sos` с обновлённым `scripts/sos.sh` на сервере 222 | 🔴 HIGH |
| 2 | Удалить или задепрекейтить `222/ports.sh` из репозитория | 🟡 MEDIUM |
| 3 | Обновить `222/ALIASES.md` — убрать строку с `ports` | 🟡 MEDIUM |
| 4 | Проверить порт 9100 (prometheus-node) — открыт на `*` (all), возможно лишнее | 🟢 LOW |
| 5 | Проверить `@reboot` cron для deploy-blacklist.sh (TODO из 2026-06-09) | 🔴 HIGH — не сделано |

---

---

# 📅 Session: 2026-06-09

> 09 June 2026 | 17:00 – 18:00 CEST
> Affected: **RU-SO-109** (212.109.223.109) — systemd OnFailure, DNS port 53, PHP OOM, IPGuard
> Affected: **blacklist/deploy-blacklist.sh** — `clear` bug removed

---

## 📋 Session Summary

1. Fixed `OnFailure=` in systemd override.conf on 5 services — was causing crash loops on nginx/php/mariadb/crowdsec/apache2
2. Closed DNS port 53 from internet — was wide open on IPv6 `any`, whitelisted only trusted IPs
3. PHP memory_limit confirmed at 256M for `valeriia` pool (nail-space-ekb.ru) — was already 256M, no change needed
4. Diagnosed why **IPGuard (vladblacklist ipset) was not blocking attackers** after last reboot
5. Fixed deploy-blacklist.sh: removed `clear` command that wiped output when called from inside other scripts
6. Manually banned 11 active WP brute-force attackers via CrowdSec (720h)
7. Added VPN docs: `VPN/3XUI_XRAY_README.md` — full XRAY/REALITY key locations, Hiddify setup guide

---

## 🔧 Fix 1 — systemd OnFailure removed from 5 services (RU-SO-109)

### Problem
`/etc/systemd/system/<service>.service.d/override.conf` contained `OnFailure=` directives
on nginx, php8.3-fpm, mariadb, crowdsec, apache2.
This caused systemd dependency loops and crash-restart chains.

### Services fixed
| Service | File |
|---|---|
| nginx | `/etc/systemd/system/nginx.service.d/override.conf` |
| php8.3-fpm | `/etc/systemd/system/php8.3-fpm.service.d/override.conf` |
| mariadb | `/etc/systemd/system/mariadb.service.d/override.conf` |
| crowdsec | `/etc/systemd/system/crowdsec.service.d/override.conf` |
| apache2 | `/etc/systemd/system/apache2.service.d/override.conf` |

### Fix
Removed `OnFailure=` line from each override.conf, then `systemctl daemon-reload`.

---

## 🔧 Fix 2 — DNS port 53 closed from internet (RU-SO-109)

### Problem
`named` (BIND9) was configured with `listen-on-v6 { any; }` — port 53 was open to the entire internet.
Any IP could query the DNS resolver — potential amplification attack vector.

### Fix
- Added iptables rules to DROP port 53 from all IPs except the whitelist (10 VPN nodes + home/work IPs)
- Whitelisted: 152.53.182.222, 212.109.223.109, all VPN nodes, 185.100.197.16, 185.14.233.235, 185.14.232.0, 90.181.133.10
- Saved to `/etc/iptables/rules.v4` for persistence

### Verify
```bash
iptables -L INPUT -n | grep "dpt:53"
```

---

## 🔧 Fix 3 — IPGuard (vladblacklist) not blocking after reboot (RU-SO-109)

### Root Cause
After the last reboot, `ipset vladblacklist` was **empty** — 0 IPs blocked.
The `deploy-blacklist.sh` cron runs every 3 hours (`30 */3 * * *`) but **not at @reboot**.
Between boot and the first cron run (up to 3 hours), the server was completely unprotected.

Additionally, `deploy-blacklist.sh` contained `clear` at the top which:
- Wiped screen output when called from inside `new_server_install.sh` or diagnostic scripts
- Made it impossible to see what steps 1-6 did before deploy ran

### Fix Applied
1. Ran fresh deploy manually — loaded 102 IPs into vladblacklist
2. iptables DROP rule confirmed active
3. Removed `clear` from `deploy-blacklist.sh` and pushed to GitHub
4. **TODO**: Add `@reboot` cron entry to restore ipset on boot (see below)

### Recommended @reboot cron (add to all servers)
```bash
@reboot sleep 30 && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh) >> /var/log/vladblacklist.log 2>&1
```

### Status after fix
| Protection layer | Status |
|---|---|
| ipset vladblacklist | ✅ 102 IPs |
| iptables DROP rule | ✅ Active |
| fail2ban | ✅ 5 jails |
| CrowdSec | ✅ 71 bans |
| UFW | ✅ Active |
| Auto-update cron | ✅ Every 3h |

---

## 🔧 Fix 4 — Manual ban of 11 active WP brute-force attackers

### Context
These IPs were found in `sos` output making mass requests to `/wp-login.php` and `xmlrpc.php`.
They were NOT in the ipset blacklist yet (blacklist is updated from GitHub, not auto-populated from logs).

### IPs banned (720h via CrowdSec)
| IP | Reason |
|---|---|
| 206.189.151.195 | wp-login brute-force |
| 134.209.110.232 | wp-login brute-force |
| 167.172.79.49 | wp-login brute-force |
| 129.212.238.200 | wp-login brute-force |
| 34.159.181.54 | wp-login brute-force |
| 46.224.234.158 | wp-login brute-force |
| 213.171.208.62 | wp-login brute-force |
| 103.127.30.137 | wp-login brute-force |
| 188.241.62.83 | wp-login brute-force |
| 159.89.126.105 | wp-login brute-force |
| 138.197.154.112 | wp-login brute-force |

### ⚠️ Important: Manual ban vs automatic IPGuard

**These IPs were banned MANUALLY** via `cscli decisions add` — NOT by the automatic IPGuard system.

| Method | What it does | Who adds IPs |
|---|---|---|
| **IPGuard (vladblacklist ipset)** | Blocks IPs from **GitHub blacklist.txt** | VladiMIR manually adds to blacklist.txt + git push |
| **CrowdSec auto-ban** | Detects attacks from logs and bans automatically | CrowdSec engine (crowdsecurity/wordpress, nginx, ssh collections) |
| **Manual cscli ban** | One-time emergency ban for specific IPs | We added manually in this session |

**These 11 IPs should ideally be added to `blacklist/blacklist.txt`** so they are blocked on ALL servers, not just 109.
CrowdSec bans expire (720h = 30 days); ipset blocks are permanent until removed from blacklist.txt.

### TODO: Add these IPs to blacklist.txt
```bash
# Run on DE-222 (master server):
cd /root/Linux_Server_Public
cat >> blacklist/blacklist.txt << 'EOF'
# WP brute-force 2026-06-09 — RU-SO-109
206.189.151.195
134.209.110.232
167.172.79.49
129.212.238.200
34.159.181.54
46.224.234.158
213.171.208.62
103.127.30.137
188.241.62.83
159.89.126.105
138.197.154.112
EOF
git add blacklist/blacklist.txt
git commit -m "blacklist: add 11 WP brute-force IPs from 2026-06-09 RU-SO-109"
git push
```

---

## 🔧 Fix 5 — sos on VPN-IONOS-38: 404 error

### Problem
`new_server_install.sh` tries to download `scripts/sos.sh` from GitHub.
File does not exist — GitHub returns HTML 404 page saved as `/usr/local/bin/sos`.
Running `sos` gives: `/usr/local/bin/sos: line 1: 404:: command not found`

### Root Cause
The script references `sos.sh` but only `sos-fastpanel.sh` exists in `scripts/`.

### Fix
Use `sos-fastpanel.sh` as the `sos` binary:
```bash
cp /root/Linux_Server_Public/scripts/sos-fastpanel.sh /usr/local/bin/sos
chmod +x /usr/local/bin/sos
```
**TODO**: Fix `new_server_install.sh` step 5 to use `sos-fastpanel.sh` instead of `sos.sh`.

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `blacklist/deploy-blacklist.sh` | Updated | Removed `clear` — was wiping output when called from other scripts |
| `VPN/3XUI_XRAY_README.md` | Created | XRAY/REALITY key locations, Hiddify setup guide пошагово |
| `VPN/README.md` | Updated | Added quick navigator, REALITY key cheatsheet, updated troubleshooting |
| `WORKLOG.md` | Updated | This file |

---

## ⚠️ Open TODOs after this session

| # | TODO | Priority |
|---|---|---|
| 1 | Add `@reboot` cron for deploy-blacklist.sh to ALL 10 servers | 🔴 HIGH — servers unprotected up to 3h after reboot |
| 2 | Add 11 WP brute-force IPs to `blacklist/blacklist.txt` and push | 🟡 MEDIUM |
| 3 | Fix `new_server_install.sh` step 5: `sos.sh` → `sos-fastpanel.sh` | 🟡 MEDIUM |
| 4 | Run IPGuard check script on DE-222 to verify all 10 nodes | 🟡 MEDIUM |
| 5 | `openipmi.service` failed on RU-SO-109 — mask it (not needed on VDS) | 🟢 LOW |

---

---

# 📅 Session: 2026-05-29 (Night)

> Night 29 May 2026 | 01:00 – 01:40 CEST
> Affected: **109-RU-FastVDS** (212.109.223.109) — PHP-FPM pool, MariaDB tuning
> Affected: **222-DE-NetCup** (152.53.182.222) — MariaDB tuning
> Affected: **ALL 10 servers** — CrowdSec MemoryMax systemd override

---

## 📋 Session Summary

1. Discovered missing PHP-FPM socket for `reklama-white.eu` on 109 — pool was never created
2. Diagnosed `ne-son.ru` returning HTTP 503 — confirmed intentional (site under construction)
3. Fixed MariaDB `innodb_buffer_pool_size` on both main servers: 128MB → 1GB
4. Found root cause: `/etc/mysql/conf.d/*.conf` was ignored — MariaDB only reads `*.cnf` from that dir
5. Fixed by appending tuning block directly to `/etc/mysql/my.cnf` on both servers
6. Deployed CrowdSec systemd `MemoryMax=300M` override to all 10 servers in one SSH loop
7. Fixed critical OOM issue on EU-SO-38 where CrowdSec was being killed repeatedly

---

## 🔧 Fix 1 — reklama-white.eu: Missing PHP-FPM Pool (109-RU-FastVDS)

### Problem
The domain `reklama-white.eu` had no PHP-FPM pool configured on server 109.
Nginx was trying to connect to `/var/run/reklama-white.eu.sock` which did not exist.
Result: HTTP 502 for all requests to the site.

### Root Cause
The site was added to FastPanel but the corresponding PHP-FPM pool config file was never
generated in `/opt/php84/etc/php-fpm.d/`.

### Fix
Automatically determined the system user (`reklama-white`, uid=1036) and last used port (3300),
then created `/opt/php84/etc/php-fpm.d/reklama-white.eu.conf` with:
- `listen = /var/run/reklama-white.eu.sock`
- `listen.owner = reklama-white`, `listen.group = www-data`, `listen.mode = 0660`
- `pm = dynamic`, max_children=2, min/max_spare=1/2
- All standard FastPanel PHP settings (opcache, sendmail, session paths, etc.)
- `env[SERVICE_PORT] = 3301`

After `systemctl reload fp2-php84-fpm`:
- `/var/run/reklama-white.eu.sock` created with correct ownership
- HTTP 200 confirmed via `curl`

### How to detect missing pools in the future
```bash
grep -rh "fastcgi_pass unix:" /etc/nginx/fastpanel2-sites/*/*.conf 2>/dev/null \
| grep -oP 'unix:\K[^;]+' | sort -u \
| while read SOCK; do
    [ -S "$SOCK" ] || echo "MISSING: $SOCK"
  done
```

---

## 🔧 Fix 2 — MariaDB innodb_buffer_pool_size: 128MB → 1GB (109 and 222)

### Problem
Both main servers had MariaDB running with the default `innodb_buffer_pool_size = 134217728` (128MB).
Both servers have 8GB RAM — the buffer pool was severely undersized, causing excessive disk I/O
for every database query as data had to be re-read from disk instead of being served from memory.

### Root Cause of Config Not Being Applied
Initial attempt placed config in `/etc/mysql/conf.d/vladmir-tuning.conf`.
This file was **silently ignored** because:
- MariaDB's `!includedir /etc/mysql/conf.d/` directive only loads `*.cnf` files
- Files with `.conf` extension are not loaded by MariaDB

Verified via: `mysql --help | grep -A1 "Default options"`
Output confirmed MariaDB only reads: `/etc/my.cnf`, `/etc/mysql/my.cnf`, `~/.my.cnf`

### Fix Applied
Appended tuning block directly to `/etc/mysql/my.cnf` on both servers:
```ini
# = Rooted by VladiMIR + AI | v.2026.05.29 =
[mysqld]
innodb_buffer_pool_size = 1G
innodb_buffer_pool_instances = 2
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
query_cache_type = 0
query_cache_size = 0
max_connections = 50
```

After `systemctl restart mariadb`:

| Server | Before | After | RAM freed |
|---|---|---|---|
| 109-RU-FastVDS | 128 MB | **1 GB** | 5.1 GB → 3.5 GB used |
| 222-DE-NetCup | 128 MB | **1 GB** | 3.8 GB → 2.6 GB used |

### Key Lesson
> MariaDB on Ubuntu reads `!includedir /etc/mysql/conf.d/` — but ONLY `*.cnf` files, NOT `*.conf`.
> Always use `.cnf` extension or append directly to `/etc/mysql/my.cnf`.

### Cleanup
Removed the incorrectly named file after the fix:
```bash
rm /etc/mysql/conf.d/vladmir-tuning.conf
```

---

## 🔧 Fix 3 — CrowdSec MemoryMax systemd Override: All 10 Servers

### Problem
CrowdSec has no default memory limit in its systemd unit file.
On servers with 957MB RAM (all VPN nodes), CrowdSec was consuming ~200MB with no upper bound.

On **EU-SO-38** (144.124.233.38) the situation was critical:
- systemd cgroup had set a hard limit of `80MB` for the CrowdSec service
- CrowdSec needed ~200MB → was killed by OOM killer repeatedly
- `/proc/*/status` showed 3 OOM events since last boot
- `dmesg` confirmed: `Memory cgroup out of memory: Killed process (crowdsec)`
- Server had only 71MB free RAM with CrowdSec in restart loop

### Fix
Created systemd drop-in override on all 10 servers:
```
/etc/systemd/system/crowdsec.service.d/memory.conf
```

Content:
```ini
[Service]
MemoryMax=300M
MemorySwapMax=100M
```

Deployed via SSH loop from 222-DE-NetCup with `systemctl daemon-reload && systemctl restart crowdsec`.

### Results

| Server | RAM used by CrowdSec | Status |
|---|---|---|
| 222-EU-NetCup (152.53.182.222) | 158 MB | active |
| 109-RU-FastVDS (212.109.223.109) | 189 MB | active |
| EU-Alex-47 (109.234.38.47) | 135 MB | active |
| EU-4Ton-237 (144.124.228.237) | 131 MB | active |
| EU-Tatra-Kuma-9 (144.124.232.9) | 112 MB | active |
| VPN-EU-Shain-227 (144.124.228.227) | 108 MB | active |
| EU-Stolb-AG-24 (144.124.239.24) | 114 MB | active |
| VPN-EU-Pilik-178 (91.84.118.178) | 137 MB | active |
| VPN-EU-ILYA-176 (146.103.110.176) | 131 MB | active |
| EU-SO-38 (144.124.233.38) | 125 MB | active |

**EU-SO-38** recovered: free RAM went from 71MB to ~620MB after CrowdSec stabilized.

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `configs/mariadb-tuning.cnf` | Created | Reference config for MariaDB tuning on 8GB RAM servers |
| `crowdsec/crowdsec-memory.conf` | Created | systemd MemoryMax override for CrowdSec service |
| `configs/README.md` | Created/Updated | Added MariaDB tuning notes |
| `crowdsec/README.md` | Updated | Added CrowdSec OOM section |
| `WORKLOG.md` | Updated | This file |
| `CHANGELOG.md` | Updated | Added v2026.05.29 entry |

---

---

# 📅 Session: 2026-05-28 (Evening)

> Evening 28 May 2026
> Affected: **ALL 10 servers** — CrowdSec global fix deployed from 222

---

## 📋 Session Summary

1. Created `scripts/fix_crowdsec_global.sh` v2026.05.28 — universal CrowdSec + Samba fix
2. Deployed script to all 10 servers in one SSH loop from server 222
3. Fixed 4 identical misconfigurations present on all servers (see details below)
4. Disabled `fwupd` on servers where it was running (wasting ~26MB RAM on VPS)
5. Added `scripts/README.md` and `crowdsec/README.md` with full documentation
6. Updated `WORKLOG.md` and `CHANGELOG.md`

---

## 🔧 Fix 1 — sshd.yaml: duplicate journalctl + wrong type

### Problem
On 8 of 10 servers, `sshd.yaml` contained **two sources**:
- `journalctl` (SYSLOG_IDENTIFIER=sshd)
- file `/var/log/auth.log` with **wrong** `type: ssh` instead of `type: syslog`

Result: CrowdSec tried to parse SSH logs twice, with the wrong parser → high Unparsed rate.

### Fix
Replaced with single clean source:
```yaml
filenames:
  - /var/log/auth.log
  - /var/log/auth.log.1
labels:
  type: syslog
source: file
```

### Special cases
- **222-DE-NetCup**: `sshd.yaml` was completely **missing** — created from scratch
- **VPN-ALEX-47**: `setup.smb.yaml` was reading Samba via `journalctl` instead of file — corrected

---

## 🔧 Fix 2 — setup.smb.yaml: wide glob → single log.smbd

### Problem
Auto-generated `setup.smb.yaml` used glob patterns:
```yaml
filenames:
  - /var/log/samba/*.log
  - /var/log/samba/log.*
```
This caused CrowdSec to tail **hundreds** of per-IP files.

### Fix
```yaml
filenames:
  - /var/log/samba/log.smbd
```

---

## 🔧 Fix 3 — smb.conf: log level = 1 + unified log file

### Problem
`log level = 2` wrote a separate `log.<IP>` for every Samba client connection.

### Fix
`log level = 1`, all logs go to `/var/log/samba/log.smbd`.

---

## 🔧 Fix 4 — Samba per-IP log cleanup

| Server | Files deleted |
|---|---|
| 222-DE-NetCup | 2407 |
| 109-RU-FastVDS | 329 |
| VPN-ALEX-47 | 571 |
| VPN-SO-38 | 547 |
| VPN-STOLB-24 | 277 |
| VPN-TATRA-9 | 19 |
| VPN-4TON-237 | 19 |
| VPN-SHAHIN-227 | 0 (already clean) |
| VPN-PILIK-178 | 0 (already clean) |
| VPN-ILYA-176 | 0 (already clean) |

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `scripts/fix_crowdsec_global.sh` | Created/Updated | v2026.05.28 — deployed to all 10 servers |
| `scripts/README.md` | Created | Full scripts documentation |
| `crowdsec/README.md` | Created | CrowdSec docs + known issues + fix summary |
| `WORKLOG.md` | Updated | This file |
| `CHANGELOG.md` | Updated | Added v2026.05.28 entry |

---

---

# 📅 Session: 2026-05-28 (Afternoon)

> Afternoon 28 May 2026
> Affected: **222-DE-NetCup** (152.53.182.222) — Semaphore cleanup, CrowdSec whitelist, sos.sh default

---

## 📋 Session Summary

1. Investigated 502 errors in `sem.gincz.com-ssl` logs — root cause: stale browser tab, not a real incident
2. Cleaned `sem.gincz.com` and `server.gincz.com` logs (truncated to 0, removed `.bak`)
3. Confirmed `sem.gincz.com` has no active nginx config — service properly removed
4. Fixed broken CrowdSec whitelist — file was accidentally overwritten with bare IP list (invalid YAML)
5. Consolidated 3 duplicate whitelist files into 1 clean `my_whitelist.yaml`
6. Updated `sos.sh` — changed default time window from `1h` to `24h`
7. Added `scripts/install_sos.sh` — universal installer for new servers
8. Saved `crowdsec/my_whitelist.yaml` to repository

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `crowdsec/my_whitelist.yaml` | Created | Consolidated trusted IP whitelist v2026-05-28 |
| `scripts/install_sos.sh` | Created | Universal sos installer for new servers |
| `WORKLOG.md` | Updated | This file |

---

---

# 📅 Session: 2026-05-27

> Evening 27 May 2026
> Affected: **222-DE-NetCup** (152.53.182.222) — CrowdSec

---

## 📋 Session Summary

1. Fixed `letsencrypt-whitelist.yaml` — wrong `name:` field caused conflict with other whitelists
2. Diagnosed root cause of 60+ WARNING messages on every `cscli` command
3. Confirmed CrowdSec v1.7.8 — already latest version, no upgrade needed
4. Cleaned stale hub symlinks and reinstalled all collections with `--force`
5. All WARNING eliminated — parsers now show clean versions

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `222/crowdsec/letsencrypt-whitelist.yaml` | Created | Whitelist config for Let's Encrypt ACME IPs |
| `CHANGELOG.md` | Updated | Added session v2026.05.27 |
| `WORKLOG.md` | Updated | This file |

---

---

# 📅 Session: 2026-05-25 / 2026-05-26

> Evening 25 May → afternoon 26 May 2026
> Affected: **ALL VPN nodes** (8 servers), **scripts/shared_aliases.sh**, **install-night-maintenance.sh**

---

## 📋 Session Summary

1. Audited cron jobs on all 10 servers from main server 222 via SSH loop
2. Unified nightly maintenance: apt update + upgrade + reboot + post-reboot Telegram report
3. Removed duplicate `auto_upgrade.sh` cron entries from 4 VPN servers
4. Created `scripts/shared_aliases.sh` for VPN nodes (fixes `.bashrc` line 79 error on pilik178 + ilya176)
5. Fixed outdated repo on pilik178 and ilya176 via `git pull`
6. Created `install-night-maintenance.sh` — universal installer deployable via `curl` from GitHub
7. Deployed to all 8 VPN servers in one SSH loop from server 222

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `install-night-maintenance.sh` | Created | Universal VPN nightly maintenance installer |
| `scripts/shared_aliases.sh` | Created | VPN node aliases, fixes `.bashrc` line 79 error |
| `CHANGELOG.md` | Updated | Added session v2026.05.26 |
| `WORKLOG.md` | Updated | This file |

---

---

# 📅 Session: 2026-05-24 / 2026-05-25

> Evening 24 May → night 25 May 2026
> Affected: **scripts/sos.sh**, **scripts/setup_aliases_modded_mc.sh**

---

## 📋 Session Summary

1. `sos.sh` — full safety rewrite: eliminated all `integer expression expected` runtime errors
2. `sos.sh` — fixed HTTP 502/503 domain deduplication logic
3. `sos.sh` — added top-N output limits to all long sections (no content removed)
4. `setup_aliases_modded_mc.sh` — added step [5/7]: auto-repair of `/etc/bash.bashrc` aliases block
5. Version bumped to `v2026.05.25` in both scripts

---

## 📂 Changed Files

| File | What changed | Version |
|---|---|---|
| `scripts/sos.sh` | safe_int/safe_float/safe_pct added; 502/503 dedup fixed; tool self-contamination fix; top-N limits | v2026.05.25 |
| `scripts/setup_aliases_modded_mc.sh` | New step [5/7]: /etc/bash.bashrc repair; step count 6→7 | v2026.05.25 |
| `CHANGELOG.md` | Added session v2026.05.25 | — |
| `WORKLOG.md` | Added this session | — |

---

---

# 📅 Session: 2026-04-12 / 2026-04-13

> Evening 12 April → night 13 April 2026
> Affected: **222** (152.53.182.222) and **109** (212.109.223.109)

---

## 📋 Session Summary

1. `sos.sh` updated with color output and time-window parameters (`1h`, `3h`, `24h`, `120h`)
2. Server **222** — alias `sos1` was already present, no changes needed
3. Server **109** — alias `sos1` was missing, added to `.bashrc`
4. `ALIASES.md` updated on both servers

---

## 📂 Changed Files

| File | What changed | Commit |
|---|---|---|
| `109/.bashrc` | Added `alias sos1=...`, version bumped to v2026-04-13 | [f6486a2](https://github.com/GinCz/Linux_Server_Public/commit/f6486a25fcdf35ea7c51a1d20d443627e37c37f0) |
| `109/ALIASES.md` | Added `sos1` to SOS table | [f0be4c5](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085) |
| `222/ALIASES.md` | Added `sos1` to SOS table | [f0be4c5](https://github.com/GinCz/Linux_Server_Public/commit/f0be4c5439263b497e1634b32e7a8717735e0085) |

---

*= Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz/Linux_Server_Public =*
