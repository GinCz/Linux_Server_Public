# WORKLOG — Linux_Server_Public

> Full session-by-session work log.
> = Rooted by VladiMIR | AI =

---

# 📅 Session: 2026-06-15 (Night) — Part 2

> 15 June 2026 | 00:30 – 01:00 CEST
> Affected: **109-RU-FirstVDS** (212.109.223.109) — voyage4u.ru PHP 5.6 recovery

---

## 📋 Session Summary

1. Получено алерт-сообщение в Telegram: `[voyage4u.ru] [🔴 Down] Request failed with status code 502`
2. Диагностировали — сайт на PHP 5.6, сервис `fp2-php56-fpm` был остановлен после нашей предыдущей сессии
3. Запустили сервис, добавили в автозапуск, сайт восстановлен (HTTP 200)
4. Зафиксировали критическое предупреждение: PHP 5.6 = EOL 2018, нельзя останавливать без последствий

---

## 🔧 Fix — voyage4u.ru: 502 Bad Gateway → восстановление PHP 5.6

### Симптом
```
[voyage4u.ru] [🔴 Down] Request failed with status code 502
```

### Диагностика

#### Шаг 1 — Определить сервер
Сайт voyage4u.ru не найден на 222-DE. Найден на **109-RU-FirstVDS**.

#### Шаг 2 — Найти PHP pool конфиг
```bash
find /opt/php*/etc/php-fpm.d/ -name "voyage4u.ru.conf"
# → /opt/php56/etc/php-fpm.d/voyage4u.ru.conf
```
Пул настроен на **PHP 5.6** (`/opt/php56/`), сокет: `/var/run/voyage4u.ru.sock`

#### Шаг 3 — Проверить сокет
```bash
ls -la /var/run/voyage4u.ru.sock
# → ls: cannot access '/var/run/voyage4u.ru.sock': No such file or directory
```
**Сокет не существует** — PHP-FPM не запущен → nginx получает 502.

#### Шаг 4 — Статус сервиса
```bash
systemctl status fp2-php56-fpm
# → inactive (dead)
# Последняя остановка: Jun 14 22:30:31 — в нашу сессию!
```

### Причина
Сервис `fp2-php56-fpm` был **остановлен 14.06.2026 в 22:30** — предположительно во время нашей рабочей сессии при работе с PHP-сервисами на сервере 109. После остановки сокет удалился, nginx начал возвращать 502.

### Исправление
```bash
systemctl start fp2-php56-fpm
systemctl enable fp2-php56-fpm
# Created symlink /etc/systemd/system/multi-user.target.wants/fp2-php56-fpm.service
```

### Результат проверки
```bash
ls -la /var/run/voyage4u.ru.sock
# srw-rw---- 1 gincz www-data 0 Jun 15 00:44 /var/run/voyage4u.ru.sock  ✅

curl -sk -o /dev/null -w "%{http_code}" https://voyage4u.ru
# 200  ✅
```

### Статус после ребута
`systemctl enable` создал симлинк в `multi-user.target.wants` → **PHP 5.6 стартует автоматически при каждом ребуте**. Сокет появится, nginx подключится, сайт работает.

---

## ⚠️ КРИТИЧЕСКОЕ ПРЕДУПРЕЖДЕНИЕ — voyage4u.ru на PHP 5.6 (EOL 2018)

> **Этот сайт — единственная причина, почему PHP 5.6 живёт на сервере 109.**
> PHP 5.6 конец поддержки: **декабрь 2018 года** (8 лет без патчей).
> Joomla на PHP 5.6 — дополнительно устаревший CMS без обновлений безопасности.

### 🔴 НЕЛЬЗЯ делать пока voyage4u.ru не удалён

| Действие | Последствие |
|---|---|
| `systemctl stop fp2-php56-fpm` | Сокет исчезнет → немедленно 502 |
| `systemctl disable fp2-php56-fpm` | После ребута сервис не стартует → 502 |
| `apt purge` / `rm -rf /opt/php56/` | PHP 5.6 умрёт насовсем |
| `apt upgrade` без контроля | Может задеть php56-пакеты → проверять вручную |

### 🟡 ОСТОРОЖНО

| Действие | Что проверить после |
|---|---|
| Ребут сервера 109 | Убедиться что voyage4u.ru отвечает (мониторинг пришлёт алерт) |
| `upd` (apt upgrade) на 109 | После обновления — проверить `curl https://voyage4u.ru` вручную |
| Любые правки nginx конфига | Не трогать `fastpanel2-available/gincz/voyage4u.ru.conf` без понимания |

### 🟢 МОЖНО спокойно

- Перезапускать nginx (он только читает сокет, не управляет PHP)
- Обновлять PHP 8.3, 8.4 — они независимы
- Работать с другими сайтами на 109

### Конфигурация сайта

| Параметр | Значение |
|---|---|
| PHP версия | **5.6** (EOL декабрь 2018) |
| PHP сервис | `fp2-php56-fpm.service` |
| PHP pool конфиг | `/opt/php56/etc/php-fpm.d/voyage4u.ru.conf` |
| CMS | Joomla |
| Пользователь | `gincz` |
| Сокет | `/var/run/voyage4u.ru.sock` |
| nginx конфиг | `/etc/nginx/fastpanel2-available/gincz/voyage4u.ru.conf` |
| Лог nginx | `/var/www/gincz/data/logs/voyage4u.ru-frontend.error.log` |
| Лог PHP | `/var/www/gincz/data/logs/voyage4u.ru-backend.access.log` |

### TODO
- [ ] Мигрировать voyage4u.ru на PHP 7.4 или 8.x (или удалить сайт если не нужен)
- [ ] До миграции — не останавливать `fp2-php56-fpm`

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `WORKLOG.md` | Updated | Эта запись — voyage4u.ru recovery + предупреждение |

---

## ⚠️ Open TODOs после этой сессии

| # | TODO | Priority |
|---|---|---|
| 1 | Мигрировать voyage4u.ru с PHP 5.6 на PHP 7.4+ (или удалить сайт) | 🔴 HIGH |
| 2 | Проверить 91.84.118.178 (PILIK_178) — UNREACHABLE, неизвестен статус защиты | 🔴 HIGH |
| 3 | Поднять CrowdSec MemoryMax 300M→500M на сервере 222 (OOM из сессии 10.06) | 🔴 HIGH |
| 4 | Диагностировать crypto.gincz.com 107×502 — docker upstream (из сессии 10.06) | 🟡 MEDIUM |
| 5 | PHP error kadernik-olga.eu — Unknown named parameter (из сессии 10.06) | 🟡 MEDIUM |

---

---

# 📅 Session: 2026-06-15 (Night) — Part 1

> 15 June 2026 | 00:00 – 00:30 CEST
> Affected: **AWS-VPN-42** (3.79.14.42) — полная установка защиты с нуля
> Affected: **ALL 11 servers** — глобальная проверка безопасности

---

## 📋 Session Summary

1. Новый сервер Amazon (3.79.14.42) не имел никакой защиты — установили полный стек: Fail2Ban + CrowdSec + IPGuard (ipset vladblacklist) + Samba + SOS
2. Добавили SSH-ключ сервера 222 на Amazon — теперь управление без пароля
3. Провели глобальную проверку безопасности всех 11 серверов одним скриптом
4. Подтвердили: 10 из 11 серверов — Fail2Ban ✅ CrowdSec ✅ IPGuard 157+ IPs ✅ @reboot cron ✅
5. Выявлена единственная проблема: **91.84.118.178 (PILIK_178) — UNREACHABLE** по SSH с сервера 222

---

## 🔧 Fix 1 — AWS-VPN-42: Установка полного стека защиты

### Что было
Сервер Amazon EC2 (3.79.14.42) был добавлен в инфраструктуру как VPN-нода (XRAY),
но не имел ни одного компонента защиты нашего стандартного стека.

### Что установили

| Компонент | Статус | Путь |
|---|---|---|
| Fail2Ban | ✅ active | `/etc/fail2ban/` |
| CrowdSec | ✅ active | `/etc/crowdsec/` |
| ipset vladblacklist | ✅ 157 IPs | `ipset list vladblacklist` |
| deploy-blacklist.sh @reboot cron | ✅ EXISTS | `crontab -l` |
| SOS | ✅ `/usr/local/bin/sos` 33720 bytes | установлен 15.06 00:29 |
| Samba | ✅ active smbd | `/etc/samba/` |

### Проверка итогового состояния Amazon
```
=== Fail2Ban ===
active
=== CrowdSec ===
active
=== IPGuard ipset ===
Name: vladblacklist
Type: hash:net
Revision: 7
=== SOS ===
-rwxr-xr-x 1 root root 33720 Jun 15 00:29 /usr/local/bin/sos
=== Samba ===
active
```

---

## 🔧 Fix 2 — Глобальный аудит безопасности всех серверов

### Скрипт проверки
Запущен с сервера 222 через SSH-loop по всем 11 узлам.
Проверялось: Fail2Ban active, CrowdSec active, ipset vladblacklist count, @reboot cron exists.

### Результаты

| Сервер | Fail2Ban | CrowdSec | IPSET | @reboot cron |
|---|---|---|---|---|
| 212.109.223.109 (RU-109) | ✅ | ✅ | 159 IPs | ✅ EXISTS |
| 109.234.38.47 (VPN ALEX) | ✅ | ✅ | 157 IPs | ✅ EXISTS |
| 144.124.228.237 (VPN 4TON) | ✅ | ✅ | 157 IPs | ✅ EXISTS |
| 144.124.232.9 (VPN TATRA) | ✅ | ✅ | 157 IPs | ✅ EXISTS |
| 144.124.228.227 (VPN SHAHIN) | ✅ | ✅ | 157 IPs | ✅ EXISTS |
| 144.124.239.24 (VPN STOLB) | ✅ | ✅ | 157 IPs | ✅ EXISTS |
| 146.103.110.176 (VPN ILYA) | ✅ | ✅ | 157 IPs | ✅ EXISTS |
| 144.124.233.38 (VPN SO) | ✅ | ✅ | 157 IPs | ✅ EXISTS |
| 3.79.14.42 (AWS VPN) | ✅ | ✅ | 157 IPs | ✅ EXISTS |
| 82.223.116.38 (IONOS) | ✅ | ✅ | 157 IPs | ✅ EXISTS |
| **91.84.118.178 (PILIK)** | ❓ | ❓ | ❓ | ❓ |

### Примечание по @reboot cron
TODO из сессии 2026-06-09 (добавить @reboot cron на все серверы) — **уже был выполнен ранее**.
Все 10 доступных серверов имеют `@reboot sleep 30 && bash <(curl ..deploy-blacklist.sh)`.
Это закрывает уязвимость: после ребута ipset vladblacklist восстанавливается через 30 секунд, а не через 3 часа.

---

## ⚠️ Открытая проблема — PILIK_178 (91.84.118.178) UNREACHABLE

### Симптом
SSH-подключение с 222 → 91.84.118.178 не устанавливается (timeout).

### Возможные причины
1. Сервер выключен — проверить в панели хостинга
2. SSH-ключ 222 никогда не добавлялся на этот узел — требует ручного подключения
3. Firewall/CrowdSec заблокировал IP 152.53.182.222 на узле PILIK

### Действие
Подключиться напрямую со своего ПК → добавить SSH-ключ 222 → запустить проверку.

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `WORKLOG.md` | Updated | Эта запись |

---

## ⚠️ Open TODOs после этой сессии

| # | TODO | Priority |
|---|---|---|
| 1 | Проверить 91.84.118.178 (PILIK_178) — UNREACHABLE, неизвестен статус защиты | 🔴 HIGH |
| 2 | Добавить SSH-ключ 222 на PILIK_178 для удалённого управления | 🔴 HIGH |
| 3 | Поднять CrowdSec MemoryMax 300M→500M на сервере 222 (OOM из сессии 10.06) | 🔴 HIGH |
| 4 | Диагностировать crypto.gincz.com 107×502 — docker upstream (из сессии 10.06) | 🟡 MEDIUM |
| 5 | PHP error kadernik-olga.eu — Unknown named parameter (из сессии 10.06) | 🟡 MEDIUM |

---

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

## ⚠️ Активные инциденты выявленные при верификации

### 1. 🔴 OOM Killer — CrowdSec убивается повторно

systemd cgroup limit для crowdsec.service = **409600 kB (400MB)**.
CrowdSec потребляет ~400MB RSS и убивается.

**TODO:** Поднять `MemoryMax=500M MemorySwapMax=200M` в `/etc/systemd/system/crowdsec.service.d/memory.conf`

### 2. 🟡 HTTP 502 — crypto.gincz.com

`crypto-bot` в Docker: `Up 20 hours` — контейнер живой.
Docker-proxy: `127.0.0.1:5000` — порт слушает.
502 означает nginx не достучался до upstream в docker.

### 3. 🟡 PHP Fatal Error — kadernik-olga.eu

```
PHP Fatal error: Uncaught Error: Unknown named parameter $tasks_meta_id
in wp-includes/class-wp-hook.php:341
```

### 4. 🟡 MariaDB — RECENT RESTART

### 5. ⚠️ WP-Login атаки — 153 попытки от 91.234.25.247

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

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `scripts/sos.sh` | Updated | Секция 27 — полная перепись с дедупликацией TCP/UDP + Key ports таблица; v2026.06.10h |
| `scripts/shared_aliases_222.sh` | Updated | Удалён `alias ports=...` |
| `WORKLOG.md` | Updated | Эта запись |
| `CHANGELOG.md` | Updated | Добавлена запись v2026.06.10h |

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

## 🔧 Fix 3 — IPGuard (vladblacklist) not blocking after reboot (RU-SO-109)

### Root Cause
After the last reboot, `ipset vladblacklist` was **empty** — 0 IPs blocked.
The `deploy-blacklist.sh` cron runs every 3 hours (`30 */3 * * *`) but **not at @reboot**.
Between boot and the first cron run (up to 3 hours), the server was completely unprotected.

### Fix Applied
1. Ran fresh deploy manually — loaded 102 IPs into vladblacklist
2. iptables DROP rule confirmed active
3. Removed `clear` from `deploy-blacklist.sh` and pushed to GitHub
4. Added `@reboot` cron entry — deployed to all servers in session 2026-06-15 ✅

### @reboot cron (deployed to all servers)
```bash
@reboot sleep 30 && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh) >> /var/log/vladblacklist.log 2>&1
```

---

## 📂 Changed / Created Files

| File | Action | Notes |
|---|---|---|
| `blacklist/deploy-blacklist.sh` | Updated | Removed `clear` — was wiping output when called from other scripts |
| `VPN/3XUI_XRAY_README.md` | Created | XRAY/REALITY key locations, Hiddify setup guide пошагово |
| `VPN/README.md` | Updated | Added quick navigator, REALITY key cheatsheet, updated troubleshooting |
| `WORKLOG.md` | Updated | This file |

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

## 🔧 Fix 2 — MariaDB innodb_buffer_pool_size: 128MB → 1GB (109 and 222)

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

*= Rooted by VladiMIR + AI | v.2026.06.15 | github.com/GinCz/Linux_Server_Public =*
