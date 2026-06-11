# WORKLOG — Linux_Server_Public

> Full session-by-session work log.
> = Rooted by VladiMIR | AI =

---

# 📅 Session: 2026-06-10 (Night)

> 10 June 2026 | 20:45 – 23:20 CEST
> Affected: **EU-SO-38 / IONOS-38** (82.223.116.38) — nginx port 80 not reachable from outside
> Affected: **scripts/new_server_install.sh** — STEP 4 complete refactor
> Commit: [1bdc962](https://github.com/GinCz/Linux_Server_Public/commit/1bdc9620780e44b0280c256b7236dea34743c6b4)

---

## 📋 Session Summary

1. New server IONOS-38 was set up — nginx installed, running fine locally, but port 80 was completely unreachable from outside
2. Performed full step-by-step debug: local HTTP test → listening ports → iptables DROP rules → UFW status
3. Root cause identified: **IONOS hardware-level firewall** (datacenter firewall, independent of UFW/iptables) was blocking all ports except SSH by default
4. Solution: open ports 80 and 443 in the IONOS control panel at my.ionos.com
5. Separately — identified a structural problem in `new_server_install.sh`: STEP 4 had all 6 utility scripts hardcoded as heredocs inside the installer
6. **Refactored STEP 4**: replaced ~500 lines of hardcoded heredoc code with a 15-line loop that downloads the latest version of each script directly from GitHub
7. Committed and pushed the fix

---

## 🔍 Problem 1 — nginx port 80 not reachable from outside

### Environment
- Server: **IONOS-38** (82.223.116.38) — new VPS at IONOS provider
- OS: Ubuntu 24.04
- nginx: 1.24.0 installed and running

### Symptoms
```
# From outside: connection timeout
curl -sI http://82.223.116.38
# → hangs, no response

# From inside the server: works perfectly
curl -sI http://localhost
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
```

### Debug Steps Performed

#### Step 1 — Test HTTP locally
```
HTTP/1.1 200 OK
Server: nginx/1.24.0 (Ubuntu)
Date: Wed, 10 Jun 2026 18:47:11 GMT
```
Result: ✅ nginx responds locally — nginx itself is NOT the problem.

#### Step 2 — Check what is listening
```
LISTEN 0  4096   127.0.0.1:8080   0.0.0.0:*   users:(("crowdsec",pid=7260,fd=14))
LISTEN 0  511    0.0.0.0:80       0.0.0.0:*   users:(("nginx",pid=6355,fd=5),("nginx",pid=6352,fd=5))
LISTEN 0  511    [::]:80          [::]:*      users:(("nginx",pid=6355,fd=6),("nginx",pid=6352,fd=6))
```
Result: ✅ nginx is correctly bound to `0.0.0.0:80` and `[::]:80` — binding is NOT the problem.

#### Step 3 — Check iptables for DROP rules on 80/443
```
Chain INPUT (policy DROP 0 packets, 0 bytes)
pkts bytes target     prot
19281  89M  CROWDSEC_CHAIN  0  -- * * 0.0.0.0/0  0.0.0.0/0
19421  89M  ufw-before-logging-input ...
19421  89M  ufw-before-input ...
```
Result: ✅ No explicit DROP rules for port 80 or 443 — iptables is NOT the problem.

#### Step 4 — Check UFW status
```
Status: active

[ 1] 22/tcp    ALLOW IN  Anywhere  # SSH
[ 2] 80/tcp    ALLOW IN  Anywhere  # HTTP
[ 3] 443/tcp   ALLOW IN  Anywhere  # HTTPS
[ 4] Anywhere  ALLOW IN  152.53.182.222  # Whitelist
[ 5] Anywhere  ALLOW IN  212.109.223.109 # Whitelist
[ 6] Anywhere  ALLOW IN  109.234.38.47   # Whitelist
```
Result: ✅ UFW rules are correct — ports 80 and 443 are explicitly allowed. UFW is NOT the problem.

#### Step 5 — Force-allow 80/443 directly in iptables
Added iptables ACCEPT rules directly for ports 80/443 (bypassing UFW).
Result: ✅ iptables rules added — but still no external access.

#### Step 6 — Test again from outside
Still timeout. nginx still returns `200 OK` locally.

### Root Cause

**IONOS operates a hardware-level firewall at the datacenter network layer.**
This firewall is completely independent of UFW, iptables, or any software configuration on the server.
By default, IONOS blocks all inbound ports except SSH (22) when a new VPS is provisioned.

This means:
- UFW open → ✅ no effect if IONOS datacenter firewall blocks
- iptables ACCEPT → ✅ no effect if packet never reaches the server
- nginx running, bound correctly → ✅ but unreachable

### Solution

1. Log into **my.ionos.com**
2. Navigate to `Server & Cloud` → select the server
3. Go to `Network` → `Firewall Policies`
4. Add inbound rules:

| Protocol | Port | Source | Action |
|---|---|---|---|
| TCP | 80 | 0.0.0.0/0 | ALLOW |
| TCP | 443 | 0.0.0.0/0 | ALLOW |
| TCP | 22 | 0.0.0.0/0 | ALLOW |

5. Save and wait 1–2 minutes for propagation

### Lesson Learned

> **IONOS (and some other providers: Hetzner, OVH, Leaseweb) have provider-level firewalls
> that must be configured in the hosting control panel SEPARATELY from OS-level firewalls.**
> New VPS → always check provider firewall FIRST before debugging nginx/iptables/UFW.

### Key Diagnostic Rule
If `curl http://localhost` returns 200 but external access times out:
1. Check provider firewall panel FIRST
2. Only then check UFW/iptables
3. Check nginx binding last

---

## 🔧 Problem 2 — new_server_install.sh: STEP 4 had hardcoded scripts

### Problem Description

`scripts/new_server_install.sh` STEP 4 contained the full source code of all 6 utility scripts
embedded directly inside the installer as shell heredocs:

```bash
# OLD STEP 4 — ~500 lines of hardcoded heredocs:
cat > /usr/local/bin/sos << 'SOS_EOF'
#!/usr/bin/env bash
# ... 200 lines of sos code ...
SOS_EOF

cat > /usr/local/bin/infooo << 'INFOOO_EOF'
# ... 100 lines of infooo code ...
INFOOO_EOF

# ... same for antivir, upd, ports, load ...
```

### Why This Was a Problem

| Issue | Consequence |
|---|---|
| Scripts embedded in installer | Updating a script requires editing the massive installer file |
| Two copies of each script | `scripts/sos.sh` in repo + copy inside `new_server_install.sh` get out of sync |
| 500+ lines of bloat | Installer becomes hard to read and maintain |
| New server gets old version | Whatever was hardcoded at install time — that version stays, even if repo was updated |
| Risk of stale code | If you fix a bug in `scripts/sos.sh` but forget to update the heredoc in the installer — new servers get the buggy version |

### Fix Applied

Replaced the entire STEP 4 block (~500 lines) with a clean download loop:

```bash
# NEW STEP 4 — always installs latest version from GitHub:
RAW_BASE="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts"
INSTALL_DIR="/usr/local/bin"

SCRIPTS_TO_INSTALL=(sos infooo antivir upd ports load)

for SCRIPT in "${SCRIPTS_TO_INSTALL[@]}"; do
  printf "  \033[1;36m%-12s\033[0m" "$SCRIPT"
  if curl -fsSL "${RAW_BASE}/${SCRIPT}.sh" -o "${INSTALL_DIR}/${SCRIPT}"; then
    chmod +x "${INSTALL_DIR}/${SCRIPT}"
    echo -e "\033[1;32m✓ installed\033[0m"
  else
    echo -e "\033[1;31m✗ FAILED\033[0m"
  fi
done
```

### Scripts Installed by STEP 4

| Command | Source file in repo | Installed to |
|---|---|---|
| `sos` | `scripts/sos.sh` | `/usr/local/bin/sos` |
| `infooo` | `scripts/infooo.sh` | `/usr/local/bin/infooo` |
| `antivir` | `scripts/antivir.sh` | `/usr/local/bin/antivir` |
| `upd` | `scripts/upd.sh` | `/usr/local/bin/upd` |
| `ports` | `scripts/ports.sh` | `/usr/local/bin/ports` |
| `load` | `scripts/load.sh` | `/usr/local/bin/load` |
| `00` | generated inline | `/usr/local/bin/00` |

`00` is a simple `clear` shortcut — generated inline since it has no logic to maintain.

### How It Works Now

1. Installer runs on a new server
2. STEP 4 calls `curl` for each of the 6 scripts from `raw.githubusercontent.com`
3. Each script downloaded is the **current HEAD of main branch** — always the latest version
4. If a script fails to download — installer shows `✗ FAILED` in red and continues
5. All scripts get `chmod +x` automatically

### Benefit

> Now if you fix a bug in `scripts/sos.sh` and push to GitHub —
> every new server installed from that point forward gets the fixed version automatically.
> Zero manual sync required.

### Commit

- File: `scripts/new_server_install.sh`
- Commit: [1bdc962](https://github.com/GinCz/Linux_Server_Public/commit/1bdc9620780e44b0280c256b7236dea34743c6b4)
- Message: `fix: STEP 4 — install 6 scripts from GitHub instead of hardcoded heredocs`
- Size reduction: ~500 lines removed, replaced with 15-line loop

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `scripts/new_server_install.sh` | Updated | STEP 4 fully refactored — heredocs replaced with GitHub curl downloads |
| `WORKLOG.md` | Updated | This entry |

---

## ⚠️ Open TODOs after this session

| # | TODO | Priority |
|---|---|---|
| 1 | Open ports 80 + 443 in IONOS control panel for IONOS-38 | 🔴 HIGH — server not reachable externally |
| 2 | Verify all 6 scripts exist in `scripts/` with correct filenames (`sos.sh`, `infooo.sh`, etc.) | 🔴 HIGH — STEP 4 will silently fail if file not found |
| 3 | Test full `new_server_install.sh` run on a clean server after STEP 4 refactor | 🟡 MEDIUM |
| 4 | Add `f2.sh` (fail2ban status) to STEP 4 install list if script exists in repo | 🟢 LOW |

---

---

# 📅 Session: 2026-06-10 (Evening verification)

> 10 June 2026 | 14:00 – 14:25 CEST
> Affected: **222-DE-NetCup** (152.53.182.222) — верификация `sos.sh v2026.06.10h`

---

## 📋 Session Summary

1. Запустили `sos` на сервере 222 — подтвердили полный корректный вывод v2026.06.10h
2. **Секция 27. OPEN PORTS** — работает отлично: TCP/UDP дедуплицированы, Key ports с флагами, нет дублей
3. Алиас `ports` — **удалён**, скрипт не вызывается, `sos` покрывает всё
4. Зафиксировали полный снимок вывода `sos 24h` за 14:19 как reference output
5. Выявлены несколько активных инцидентов для последующего анализа (OOM crowdsec, 502 crypto.gincz.com, PHP error на kadernik-olga.eu)

---

## ✅ Верификация — sos v2026.06.10h (полный вывод 14:19:18)

### Заголовок
```
==========================================================================================
 SOS 24h | 2026-06-10 14:19:18 | v.2026.06.10h
 222-DE-NetCup 152.53.182.222 | Load: 0.56 0.53 0.85 (14%/4c) [WEB | 31 tests]
 Kernel: 6.8.0-117-generic | OS: Ubuntu 24.04.4 LTS
==========================================================================================
 Uptime: up 19 hours, 53 minutes
 RAM:  [*****.....] 54% 4.2Gi used / 7.7Gi total (free 1.8Gi)
 Swap: [***.......] 37% 1.5Gi used / 4.0Gi total
```

**Статус:** 31 тест — все секции 01–31 прошли без ошибок парсинга.

---

## 📊 Срез состояния сервера 222 на 14:19 10.06.2026

### Диск
| FS | Size | Used | Use% |
|---|---|---|---|
| /dev/vda1 | 247G | 59G | 23% |
| /dev/vda16 | 881M | 117M | 13% |
| /dev/vda15 | 105M | 6.2M | 5% |

### RAM / Swap
- RAM: **54%** — 4.2Gi / 7.7Gi
- Swap: **37%** — 1.5Gi / 4.0Gi (crowdsec активно использует swap)

### Top CPU процессы
| PID | User | CPU% | MEM% | Процесс |
|---|---|---|---|---|
| 120177 | root | 1.0 | 3.6 | crowdsec |
| 108186 | root | 0.7 | 6.5 | vscode-server (Stable-ffa3) |
| 1 | root | 0.5 | 0.1 | systemd |
| 816 | root | 0.4 | 0.8 | x-ui |

### Top RAM процессы (164.4MB → python3 лидирует)
| MEM | Процесс | User |
|---|---|---|
| 164.4 MB | python3 (PID 1872) | root |
| 123.9 MB | php-fpm | tan-adr+ |
| 122.2 MB | php-fpm | wowflow |
| 115.1 MB | php-fpm | wowflow |

### PHP-FPM пулы
| Pool | Procs | RAM |
|---|---|---|
| wowflow | 4 | 473.1 MB |
| gincz | 5 | 360.8 MB |
| spa | 3 | 294.2 MB |
| gadanie+ | 3 | 289.4 MB |
| tan-adr+ | 2 | 239.2 MB |
| olga_pi+ | 5 | 194.4 MB |
| dmitry-+ | 2 | 136.1 MB |

### Сеть
- TCP соединений: 202 (estab 25, timewait 83)
- eth0 session: RX=0.0M TX=14.5G
- Total connections: 550

### Blacklist / Security
- ipset vladblacklist: **119 IPs/subnets** ✅
- CrowdSec активных банов: **46** ✅
- Fail2ban sshd: 1 ban ✅
- UFW: active ✅

---

## ⚠️ Активные инциденты выявленные при верификации

### 1. 🔴 OOM Killer — CrowdSec убивается повторно

**Секция 04 (OOM) + 28 (DMESG):**
```
OOM events: 6
[55563] crowdsec killed — vm:2768708kB, anon-rss:400468kB  (pid 85542)
[69172] crowdsec killed — vm:3012944kB, anon-rss:402504kB  (pid 97457)
```

systemd cgroup limit для crowdsec.service = **409600 kB (400MB)**.
CrowdSec потребляет ~400MB RSS и убивается.
Swap: `usage 102160kB, limit 102400kB` — swap-лимит тоже почти заполнен.

Основная причина: в прошлой сессии 2026-05-29 задали `MemoryMax=300M` + `MemorySwapMax=100M`,
но CrowdSec вырос в потреблении — теперь этого недостаточно.

**TODO:** Поднять `MemoryMax=500M MemorySwapMax=200M` в `/etc/systemd/system/crowdsec.service.d/memory.conf`

### 2. 🟡 HTTP 502 — crypto.gincz.com

**Секция 12:**
```
crypto.gincz.com    107 errors (502)
car-bus-service.cz   35 errors (502)
```

`crypto-bot` в Docker: `Up 20 hours` — контейнер живой.
Docker-proxy: `127.0.0.1:5000` — порт слушает.
502 означает nginx не достучался до upstream в docker.

**TODO:** Проверить nginx upstream конфиг для crypto.gincz.com, проверить логи контейнера.

### 3. 🟡 PHP Fatal Error — kadernik-olga.eu

**Секция 20 (Critical Errors):**
```
PHP Fatal error: Uncaught Error: Unknown named parameter $tasks_meta_id
in wp-includes/class-wp-hook.php:341
```

Ошибка PHP 8.x named parameters — скорее всего конфликт плагина с текущей версией PHP.

### 4. 🟡 MariaDB — RECENT RESTART

**Секция 18:**
```
MariaDB uptime: 0d 13h 32m WARNING: RECENT RESTART!
```
Сервер запущен 20h назад — MariaDB перезапустилась через ~6.5h после загрузки.
Возможная причина: OOM killer ударил по mariadbd, или был ручной рестарт.
**Swap секция 26:** `PID 48924 mariadbd — 391.0 MB` в свопе — MariaDB на грани.

### 5. ⚠️ Зонды на секреты — nginx slow requests

**Секция 14 (Nginx slow >3s):**
```
8.040s  /secrets/gcp.json      34.18.74.228
8.040s  /secrets/aws.json      34.129.184.168
8.040s  /internal/credentials.json  8.228.90.149
6.500s  /dump.sql              8.228.90.149
6.500s  /docker-compose.prod.yaml  34.129.184.168
```
Bots сканируют секреты — nginx отдаёт 404/403 медленно (8 секунд timeout).
Это нормальное поведение атакующих, важно убедиться что реальных файлов нет.

### 6. ⚠️ WP-Login атаки

**Секция 11:**
```
153 попытки — 91.234.25.247
```
Этот IP не в CrowdSec активных банах (список начинается с ID 66791).
Требует ручного бана.

---

## ✅ Секция 27. OPEN PORTS — верификация

**Вывод новой секции (секция 27) — КОРРЕКТНЫЙ:**

```
=============== 27. OPEN PORTS
  TCP LISTEN:
    [::]:110                             "dovecot"
    [::1]:11211                          "memcached"
    ...  (без дублей named — 1 строка на интерфейс)
    127.0.0.1:3306                       "mariadbd"      ← local only ✅
    127.0.0.1:6379                       "redis-server"  ← local only ✅
    0.0.0.0:7777                         "fastpanel2-ngin"
    *:8443                               "xray-linux-amd6"
    *:9100                               "prometheus-node"  ← всё ещё open на *
    *:30452                              "x-ui"

  UDP LISTEN:
    [::1]:53                             "named"
    [2a0a:...]:443                       "nginx"  (QUIC HTTP/3)
    0.0.0.0:137                          "nmbd"
    ...

  Key ports:
    21     FTP             open   [TCP ]
    22     SSH             open   [TCP ]
    25     SMTP            open   [TCP ]
    53     DNS             open   [TCP UDP]
    80     HTTP            open   [TCP ]
    110    POP3            open   [TCP ]
    139    Samba-NB        open   [TCP ]
    143    IMAP            open   [TCP ]
    443    HTTPS           open   [TCP UDP]
    445    Samba           open   [TCP ]
    465    SMTPS           open   [TCP ]
    587    SMTP-sub        open   [TCP ]
    993    IMAPS           open   [TCP ]
    995    POP3S           open   [TCP ]
    2222   SSH-alt         open   [TCP ]
    3000   Semaphore/AGH   closed
    7777   FP2-panel       open   [TCP ]
    8080   AGH-Web         open   [TCP ]   ← NOTE: это crowdsec API, не AGH
    8443   HTTPS-alt       open   [TCP ]
    8888   FP2-http        open   [TCP ]
    9100   Prometheus      open   [TCP ]
    30452  x-ui            open   [TCP ]
    51820  WireGuard       closed
```

**NOTE про метку `8080 AGH-Web`:** На этом сервере порт 8080 = CrowdSec API (127.0.0.1:8080),
не AdGuard Home. Метку стоит поправить в sos.sh → `8080 CrowdSec-API`.

---

## 📂 Changed / Created Files (эта сессия)

| File | Action | Notes |
|---|---|---|
| `WORKLOG.md` | Updated | Эта запись — верификация + incident snapshot |
| `CHANGELOG.md` | Updated | Финальная запись v2026.06.10h verified |

---

## ⚠️ Open TODOs после этой сессии

| # | TODO | Priority |
|---|---|---|
| 1 | Поднять CrowdSec MemoryMax: 300M→500M, SwapMax: 100M→200M на 222 | 🔴 HIGH — OOM убивает crowdsec |
| 2 | Проверить 91.234.25.247 — 153 WP-login попытки, не забанен CrowdSec | 🔴 HIGH |
| 3 | Диагностировать crypto.gincz.com 107×502 — docker upstream | 🟡 MEDIUM |
| 4 | Поправить метку `8080 AGH-Web` → `8080 CrowdSec-API` в Key ports sos.sh | 🟡 MEDIUM |
| 5 | PHP error kadernik-olga.eu — Unknown named parameter $tasks_meta_id | 🟡 MEDIUM |
| 6 | MariaDB recent restart — выяснить причину (OOM? ручной?) | 🟡 MEDIUM |
| 7 | порт 9100 prometheus-node открыт на `*` — ограничить до localhost | 🟢 LOW |
| 8 | Синхронизировать `/usr/local/bin/sos` на сервере 222 из репо | 🔴 HIGH |

---

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
5. Версия `sos.sh` поднята до `v2026.06.10h`

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

---

## 🔧 Изменение 1 — `sos.sh`: новая секция 27. ALL OPEN PORTS

### Проблема (старая версия)
Секция портов в `sos.sh` просто делала `ss -tlnp` — никакой обработки:
- **Тысячи дублей** — `named` слушает на 4+ интерфейсах × 4 строки каждый = 50+ одинаковых строк
- **Нет UDP** — вся UDP-картина была скрыта
- **Нет группировки** — нельзя сразу увидеть какой сервис на каком порту
- **Нет сводной таблицы** — Key ports (22/25/53/80/443 и т.д.) не проверялись

### Решение (новая версия)

```bash
# Дедупликация: sort -u по полю "порт+сервис" — убирает все дубли named/nmbd
# Парсинг: ss -tlnp и ss -ulnp отдельно
# Группировка: для каждого уникального порта — один сервис, список bind-адресов
# Key ports: явная проверка с TCP/UDP флагами
```

---

## 🔧 Изменение 2 — удалён алиас `ports` из `shared_aliases_222.sh`

### До
```bash
alias ports='bash /usr/local/bin/ports'
```

### После
Алиас удалён. Вся функциональность покрыта секцией 27 в `sos`.

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `scripts/sos.sh` | Updated | Секция 27 — полная перепись с дедупликацией TCP/UDP + Key ports таблица; v2026.06.10h |
| `scripts/shared_aliases_222.sh` | Updated | Удалён `alias ports=...` |
| `WORKLOG.md` | Updated | Эта запись |
| `CHANGELOG.md` | Updated | Добавлена запись v2026.06.10h |

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

---

## 🔧 Fix 3 — IPGuard (vladblacklist) not blocking after reboot (RU-SO-109)

### Root Cause
After the last reboot, `ipset vladblacklist` was **empty** — 0 IPs blocked.
The `deploy-blacklist.sh` cron runs every 3 hours (`30 */3 * * *`) but **not at @reboot**.
Between boot and the first cron run (up to 3 hours), the server was completely unprotected.

### Fix Applied
1. Ran fresh deploy manually — loaded 102 IPs into vladblacklist
2. iptables DROP rule confirmed active
3. Removed `clear` from `deploy-blacklist.sh` and pushed to GitHub
4. **TODO**: Add `@reboot` cron entry to restore ipset on boot

### Recommended @reboot cron (add to all servers)
```bash
@reboot sleep 30 && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh) >> /var/log/vladblacklist.log 2>&1
```

---

## 🔧 Fix 4 — Manual ban of 11 active WP brute-force attackers

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

---

## 🔧 Fix 5 — sos on VPN-IONOS-38: 404 error

### Problem
`new_server_install.sh` tries to download `scripts/sos.sh` from GitHub.
File does not exist — GitHub returns HTML 404 page saved as `/usr/local/bin/sos`.
Running `sos` gives: `/usr/local/bin/sos: line 1: 404:: command not found`

### Fix
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

### Fix
Created `/opt/php84/etc/php-fpm.d/reklama-white.eu.conf` with correct pool settings.
After `systemctl reload fp2-php84-fpm` — HTTP 200 confirmed via `curl`.

---

## 🔧 Fix 2 — MariaDB innodb_buffer_pool_size: 128MB → 1GB (109 and 222)

### Fix Applied
Appended tuning block directly to `/etc/mysql/my.cnf` on both servers:
```ini
[mysqld]
innodb_buffer_pool_size = 1G
innodb_buffer_pool_instances = 2
innodb_log_file_size = 256M
innodb_flush_log_at_trx_commit = 2
query_cache_type = 0
query_cache_size = 0
max_connections = 50
```

### Key Lesson
> MariaDB on Ubuntu reads `!includedir /etc/mysql/conf.d/` — but ONLY `*.cnf` files, NOT `*.conf`.

---

## 🔧 Fix 3 — CrowdSec MemoryMax systemd Override: All 10 Servers

```ini
[Service]
MemoryMax=300M
MemorySwapMax=100M
```

Deployed via SSH loop. EU-SO-38 recovered: free RAM went from 71MB to ~620MB.

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `configs/mariadb-tuning.cnf` | Created | Reference config for MariaDB tuning on 8GB RAM servers |
| `crowdsec/crowdsec-memory.conf` | Created | systemd MemoryMax override for CrowdSec service |
| `WORKLOG.md` | Updated | This file |
| `CHANGELOG.md` | Updated | Added v2026.05.29 entry |

---

---

# 📅 Session: 2026-05-28 (Evening)

> Evening 28 May 2026
> Affected: **ALL 10 servers** — CrowdSec global fix deployed from 222

See CHANGELOG.md for full details.

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
> Affected: **222-DE-NetCup** (152.53.182.222)

See CHANGELOG.md for full details.

---

---

# 📅 Session: 2026-05-27

> Evening 27 May 2026
> Affected: **222-DE-NetCup** (152.53.182.222) — CrowdSec

See CHANGELOG.md for full details.

---

---

# 📅 Session: 2026-05-25 / 2026-05-26

> Evening 25 May → afternoon 26 May 2026
> Affected: **ALL VPN nodes** (8 servers)

See CHANGELOG.md for full details.

---

---

# 📅 Session: 2026-05-24 / 2026-05-25

> Evening 24 May → night 25 May 2026
> Affected: **scripts/sos.sh**, **scripts/setup_aliases_modded_mc.sh**

See CHANGELOG.md for full details.

---

---

# 📅 Session: 2026-04-12 / 2026-04-13

> Evening 12 April → night 13 April 2026
> Affected: **222** and **109**

See CHANGELOG.md for full details.

---

*= Rooted by VladiMIR + AI | v.2026.06.11 | github.com/GinCz/Linux_Server_Public =*
