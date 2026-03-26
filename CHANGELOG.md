# CHANGELOG

## v2026-03-26 (вечер) — Backup+Clean, SSH-ключи, Telegram отключён, Crypto-Bot фиксы

### 🎯 Обзор сессии
Вечерняя сессия на серверах **222-DE-NetCup** и **109-RU-FastVDS**.
Основные задачи: новый скрипт `backup_clean.sh` (чистка + бэкап), настройка SSH-ключей
между серверами для пользователя `vlad`, отключение лишних Telegram-алертов,
исправление crypto-bot (динамическая биржа + условие выхода ENTRY-DROP).

---

### 🤖 Crypto-Bot — исправления (сервер 222)

#### 1. `paper_trade.py` — динамическая биржа
- **Было:** `exchange = ccxt.okx({...})` жёстко прошит OKX
- **Стало:** функция `_make_exchange(cfg)` читает `config.json['exchange']`
  - `"exchange": "okx"` → инициализирует OKX с ключами `okx_api_key/secret/passphrase`
  - `"exchange": "mexc"` → инициализирует MEXC с ключами `api_key/api_secret`
- **Файл:** `/root/crypto-docker/scripts/paper_trade.py` строки 54–72

#### 2. `paper_trade.py` — новое условие выхода ENTRY-DROP
- **Добавлено:** выход если цена упала >N% от цены входа (до пика)
- **Параметр:** `config.json["drop_from_entry"]` (по умолчанию `1.0` = 1%)
- **Логика:**
  ```
  if pnl_entry <= -drop_from_entry → ENTRY-DROP
  ```
- Работает ДО проверки `PEAK-DROP` — защищает от медленного слива

#### 3. `config.json` — новые поля
```json
{
  "exchange": "okx",
  "drop_from_entry": 1.0
}
```

#### 4. `scanner.py` — BEAR/BULL алерты отключены
- **Добавлено:** проверка флага `tg_alerts_enabled` в начале `check_and_alert()`
- **config.json:** `"tg_alerts_enabled": false`
- Telegram-бот остался настроенным — только алерты об ошибках

---

### 🔒 SSH-ключи между серверами (пользователь vlad)

#### Проблема
Бэкап `222 → 109` падал с `Permission denied (publickey,password)`.
Ключ `root@222` не был авторизован у `vlad@109`.

#### Решение — 222 → 109
```bash
# На 109: создали папку и дали права
mkdir -p /home/vlad/.ssh
chmod 700 /home/vlad/.ssh
echo "ssh-rsa AAAAB3Nz...root@222-DE-NetCup" >> /home/vlad/.ssh/authorized_keys
chmod 600 /home/vlad/.ssh/authorized_keys
chown -R vlad:vlad /home/vlad/.ssh
```
- ✅ `ssh vlad@xxx.xxx.xxx.109` — без пароля

#### Решение — 109 → 222
```bash
# На 109:
ssh-copy-id -i ~/.ssh/id_rsa.pub vlad@xxx.xxx.xxx.222
# Ввели пароль vlad один раз → ключ добавлен
```
- ✅ `ssh vlad@xxx.xxx.xxx.222` — без пароля

#### Папки бэкапа созданы
```bash
# На 222:
mkdir -p /BACKUP/109
chown -R vlad:vlad /BACKUP/109

# На 109 уже была:
/BACKUP/222/  (владелец vlad:vlad)
```

---

### 📦 Новый скрипт `backup_clean.sh`

Заменяет старый `system_backup.sh`. Объединяет чистку сервера и создание бэкапа.

#### Расположение
| Сервер | Путь |
|--------|------|
| 222 | `/root/backup_clean.sh` |
| 109 | `/root/backup_clean.sh` |

#### Что делает (6 шагов)
```
[1/6] Cleaning old files     — удаляем мусор перед архивом
[2/6] Pre-cleanup old backups — удаляем старые архивы (храним 10)
[3/6] Creating archive        — создаём tar.gz только нужного
[4/6] Saving locally          — копируем в /BACKUP/XXX/
[5/6] Sending copy to remote  — scp через SSH-ключ vlad
[6/6] Telegram                — только при ошибке (тишина при успехе)
```

#### Что чистится перед архивом `[1/6]`
- `/root/ssh_logs/` и `/root/ssh_full_*.log`
- Файлы `*.txt`, `diag-*`, `alliances_inventory_*` старше 30 дней
- Файлы `*.log` старше 7 дней
- `*-bak-*` и `safe-backup*` старше 30 дней
- `/root/wireguard.tar`
- `/root/nginx_backups_*`, старые wp/nginx бэкапы
- `/root/.vscode-server/cli/servers/*/server/node_modules` (бинарники VSCode!)
- `/root/.vscode-server/cli/servers/*/server/node`
- `/root/.vscode-server/code-*`
- `/etc/proftpd/blacklist.dat`
- `journalctl --vacuum-time=30d`
- `apt-get clean`

#### Что включается в архив
```
/etc                                      — конфиги системы
/root                                     — скрипты и конфиги root
/usr/local/fastpanel2/config              — настройки FASTPANEL
/usr/local/fastpanel2/templates           — шаблоны
/usr/local/fastpanel2/letsencrypt         — SSL сертификаты
/usr/local/fastpanel2/ssl                 — SSL ключи
/usr/local/fastpanel2/skel               — skel
/usr/local/fastpanel2/location-nginx      — nginx конфиги
/usr/local/fastpanel2/configuration_backup — бэкапы конфигов FP
```

#### Что исключается из архива
```
*/.git  */session/*  */cache/*
root/wireguard.tar  root/*.log  root/ssh_logs  root/ssh_full_*  root/diag-*
root/Linux_Server_Public  root/scripts  root/public_git
root/build_*  root/refresh_*  root/*.py
root/.vscode-server
etc/crowdsec/hub  etc/apparmor.d
etc/proftpd/blacklist.dat
var/www/*/data/www  var/www/*/data/backups
```

#### Итоговый размер архивов
| Сервер | Размер | До оптимизации |
|--------|--------|----------------|
| 222-EU | ~1.4 MB | 196 MB |
| 109-RU | ~2.5 MB | 97 MB |

#### Cron
| Сервер | Время | Лог |
|--------|-------|-----|
| 222 | `0 2 * * *` | `/var/log/system-backup.log` |
| 109 | `0 1 * * *` | `/var/log/system-backup.log` |

#### Telegram — только ошибки
- ✅ При успехе — тишина
- ⚠️ При ошибке копирования на удалённый сервер — уведомление

---

### 🔕 Telegram-алерты — отключены лишние

#### CPU/RAM алерты (сервер 109)
- **Источник:** `*/5 * * * * bash /root/Linux_Server_Public/scripts/telegram_alert.sh`
- **Действие:** удалён из crontab на 109
- **Команда:** `(crontab -l | grep -v "telegram_alert") | crontab -`
- Сам скрипт `telegram_alert.sh` — **оставлен** на сервере (не удалён)

#### BEAR/BULL Market алерты (crypto-bot на 222)
- **Источник:** `scanner.py` функция `check_and_alert()`
- **Действие:** добавлена проверка `cfg.get('tg_alerts_enabled', True)`
- **config.json:** `"tg_alerts_enabled": false`

#### BACKUP OK алерты
- **Действие:** убрана отправка при успехе из `system_backup.sh` (222) и `backup_clean.sh` (оба)
- Уведомление только при `REMOTE_OK=0`

---

### 🛠️ Финальный cron на сервере 222
```
0 23 * * * php /var/www/spa/data/www/svetaform.eu/wp-cron.php > /dev/null 2>&1
*/15 * * * * bash /opt/server_tools/scripts/php_fpm_watchdog.sh
@reboot sleep 60 && bash /root/Linux_Server_Public/scripts/fastpanel_php_ondemand_v2026-03-25.sh >> /var/log/php_ondemand.log 2>&1
0 2 * * * /root/backup_clean.sh >> /var/log/system-backup.log 2>&1
0 3 * * * /root/docker_backup.sh >> /var/log/docker-backup.log 2>&1
```

### 🛠️ Финальный cron на сервере 109
```
0 1 * * * /root/backup_clean.sh >> /var/log/system-backup.log 2>&1
0 3 * * 0 /opt/server_tools/scripts/disk_cleanup.sh
30 3 * * 0 /usr/local/bin/auto_upgrade.sh
0 23 * * * curl -s "https://[сайт].ru/wp-cron.php?doing_wp_cron" > /dev/null 2>&1
  ... (24 WordPress сайта)
```
**Удалено:** `*/5 * * * * bash /root/Linux_Server_Public/scripts/telegram_alert.sh`

---

### 📁 Файлы изменены

#### Сервер 222 (`/root/`)
| Файл | Изменение |
|------|-----------|
| `backup_clean.sh` | НОВЫЙ — заменяет `system_backup.sh` |
| `system_backup.sh` | Оставлен как резерв, cron переключён на `backup_clean.sh` |
| `crypto-docker/scripts/paper_trade.py` | `_make_exchange()` + `ENTRY-DROP` условие |
| `crypto-docker/scripts/scanner.py` | `tg_alerts_enabled` флаг в `check_and_alert()` |
| `crypto-docker/config.json` | `drop_from_entry: 1.0`, `tg_alerts_enabled: false` |

#### Сервер 109 (`/root/`)
| Файл | Изменение |
|------|-----------|
| `backup_clean.sh` | НОВЫЙ — заменяет `system_backup.sh` |
| `system_backup.sh` | Оставлен как резерв |

#### Сервер 109 (`/home/vlad/.ssh/`)
| Файл | Изменение |
|------|-----------|
| `authorized_keys` | Добавлен pub key `root@222-DE-NetCup` |

#### Сервер 222 (`/home/vlad/.ssh/`)
| Файл | Изменение |
|------|-----------|
| `authorized_keys` | Добавлен pub key `root@109-ru-vds` через `ssh-copy-id` |

#### Сервер 222 (`/BACKUP/`)
| Папка | Изменение |
|-------|-----------|
| `/BACKUP/109/` | СОЗДАНА, владелец `vlad:vlad` |

---

### 🖥️ Описание серверов (актуально на 2026-03-26)

#### 222-DE-NetCup (xxx.xxx.xxx.222)
- **Провайдер:** NetCup.com, Германия
- **Тариф:** VPS 1000 G12 (2026) — 8.60 €/mo
- **Железо:** 4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe
- **ОС:** Ubuntu 24 / FASTPANEL
- **Назначение:** Европейские сайты с Cloudflare
- **Crypto-Bot:** Docker `crypto-bot`, порт 5000, paper-trading OKX
- **Бэкап:** `/BACKUP/222/` локально + копия на 109
- **SSH user vlad:** доступ с 109 по ключу

#### 109-RU-FastVDS (xxx.xxx.xxx.109)
- **Провайдер:** FastVDS.ru, Россия
- **Тариф:** VDS-KVM-NVMe-Otriv-10.0 — 13 €/mo
- **Железо:** 4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe
- **ОС:** Ubuntu 24 LTS / FASTPANEL
- **Назначение:** Русские сайты без Cloudflare (24 WordPress сайта)
- **Бэкап:** `/BACKUP/109/` локально + копия на 222
- **SSH user vlad:** доступ с 222 по ключу

---

_Last updated: 2026-03-26 22:59 by VladiMIR Bulantsev_

---

## v2026-03-26 (ночь 25→26 марта) — BACKUP Restructure + SSH Keys + sshpass removal

### 🎯 Обзор сессии
Полная реорганизация системы резервного копирования на серверах **222-DE-NetCup** и **109-RU-FastVDS**.
Переименование папки `/BackUP/` → `/BACKUP/`, унификация путей, добавление `docker_backup.sh`,
настройка SSH-ключей между серверами (без паролей), удаление `sshpass`.

---

### 🚨 Проблемы найдены и исправлены

#### 1. `system_backup.sh` на 222 — не было в `/root/`
- **Было:** скрипт существовал только в репозитории `/root/Linux_Server_Public/222/`
- **Стало:** скопирован в `/root/system_backup.sh`, добавлен в cron

#### 2. `docker_backup.sh` — неверное расположение
- **Было:** `/root/crypto-docker/docker_backup.sh`
- **Стало:** перенесён в `/root/docker_backup.sh` (единообразно с system_backup.sh)
- **Cron 222:** добавлено `0 3 * * * /root/docker_backup.sh >> /var/log/docker-backup.log 2>&1`

#### 3. Папка `/BackUP/` → переименована в `/BACKUP/`
- **Было:** `/BackUP/222/` на обоих серверах
- **Стало:** `/BACKUP/222/` и `/BACKUP/109/`
- Пути исправлены во всех скриптах через `sed -i`

#### 4. На сервере 109 не было cron для `system_backup.sh`
- **Добавлено:** `0 1 * * * /root/system_backup.sh >> /var/log/system-backup.log 2>&1`

#### 5. sshpass с захардкоженным паролем в скриптах
- **Было:** `sshpass -p "${REMOTE_PASS}" scp ...`
- **Удалено:** полностью из `system_backup.sh` на обоих серверах

---

### 📦 Commits этой сессии

```
433f4f1  v2026-03-26 | Remove sshpass/REMOTE_PASS, use SSH keys on 222
18b11e9  v2026-03-26 | Remove sshpass/REMOTE_PASS, use SSH keys on 109
0b52fbf  v2026-03-25 | Fix backup paths BackUP→BACKUP on 109
39264bd  v2026-03-25 | Fix backup paths BackUP→BACKUP, add docker_backup.sh (222)
```

---

## v2026-03-25/26 — Crypto-Bot Docker Migration + Alias Fixes (222-DE-NetCup)

### 🎯 Overview
Full migration of crypto-bot from bare-metal (`/root/aws-setup/`) to Docker (`/root/crypto-docker/`).
New server 222-DE-NetCup (IP: xxx.xxx.xxx.222, NetCup Germany) replacing old AWS setup.
All scripts, aliases, and paths updated. Binance removed from UI. Exchange switching bug found.

---

### 🔄 Migration: aws-setup → crypto-docker

**New paths (current):**
- `/root/crypto-docker/` — root of Docker project
- `/root/crypto-docker/scripts/` — all Python/bash scripts
- `/root/crypto-docker/templates/` — Flask HTML templates
- `/root/crypto-docker/config.json` — main config (mounted into container)
- Inside container: `/app/scripts/` — same scripts via Docker volume

---

### ⚠️ Critical Bug: alias `tr` → renamed to `bot`
- `tr` is a standard Linux utility — alias had no effect
- **Fix:** Alias renamed to `bot`

### ⚠️ Critical Bug: `[ -z "$PS1" ] && return` blocked all aliases
- **Fix:** Line commented out in `.bashrc`

---

### 🔧 UI Fix: Binance button removed
- Removed from `index.html` line 197
- Fixed JS array: `['okx','mexc','binance']` → `['okx','mexc']`

---

## v2026-03-25 — RAM Crisis Fix + PHP-FPM ondemand optimization

### Overview
Server 222-DE-NetCup was critically low on RAM (6.8GB used of 7.7GB).
Fixed by switching 40 idle PHP-FPM pools to `ondemand` mode.
Result: RAM dropped from 6.8GB → 2.6GB used.

---

## v2026-03-24 — Major Refactor + Telegram Alerts + SSH Banner

### Overview
Full repository restructure, terminal color system, universal SSH banner,
Telegram monitoring alerts with SSH login protection.

---

_Last updated: 2026-03-26 23:00 by VladiMIR Bulantsev_
