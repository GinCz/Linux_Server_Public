# CHANGELOG

## v2026-03-27 — Ansible/Semaphore, Timezone, wg-easy removed, YAML fixes

### 🎯 Обзор сессии
Полная настройка Ansible + Semaphore UI. Установка Europe/Prague на всех серверах.
Удаление лишнего контейнера wg-easy с vpn-tatra-9. Исправление YAML синтаксиса.

---

### 🗂 Новые файлы ansible/

#### `ansible/ansible.cfg` — НОВЫЙ
```ini
[defaults]
interpreter_python = auto_silent   # убирает WARNING Python interpreter
nocows = 1
display_skipped_hosts = false

[ssh_connection]
pipelining = true
```
> ⚠️ НЕ добавлять `stdout_callback = debug` — ломает Summary в Semaphore!

#### `ansible/set_timezone.yml` — НОВЫЙ
- Устанавливает `Europe/Prague` на все серверы через `community.general.timezone`
- Fallback: `timedatectl set-timezone Europe/Prague`
- Отчёт: `%-16s | Europe/Prague | DD.MM.YYYY HH:MM:SS`
- Шаблон Semaphore: **Set Timezone Prague** (Template ID: 9)

#### `ansible/cleanup_vpn.yml` — ОБНОВЛЁН
- Добавлена финальная таблица отчёта:
```
+------------------+--------+------+--------+------+---------+----------+----------+
| Server           | Before | %    | After  | %    | Freed   | AWG      | Samba    |
+------------------+--------+------+--------+------+---------+----------+----------+
```
- Исправлен Samba статус: `head -1 | awk '{print $1}'` — только первое слово (убирает дублирование `inactive\ninactive`)
- Шаблон Semaphore: **Cleanup VPN Servers** (Template ID: 8)

#### `ansible/server_info.yml` — ИСПРАВЛЕН
- YAML ошибка: `awk` кавычки внутри shell команд экранированы `\"`
- `docker ps --format` обёрнут в `{% raw %}...{% endraw %}`
- Шаблон Semaphore: **Server Info Report** (Template ID: 7)

---

### 🌍 Timezone — установлено на всех серверах

До: UTC (разные серверы показывали разное время)
После: **Europe/Prague (CET +0100)** на всех 10 серверах

| Сервер | TZ | Проверено |
|--------|-----|----------|
| server-222 | Europe/Prague (CET, +0100) | ✅ |
| server-109 | Europe/Prague (CET, +0100) | ✅ |
| vpn-alex-47 | Europe/Prague (CET, +0100) | ✅ |
| vpn-4ton-237 | Europe/Prague (CET, +0100) | ✅ |
| vpn-tatra-9 | Europe/Prague (CET, +0100) | ✅ |
| vpn-stolb-24 | Europe/Prague (CET, +0100) | ✅ |
| vpn-pilik-178 | Europe/Prague (CET, +0100) | ✅ |
| vpn-ilya-176 | Europe/Prague (CET, +0100) | ✅ |
| vpn-shahin-227 | Europe/Prague (CET, +0100) | ✅ |
| vpn-so-38 | Europe/Prague (CET, +0100) | ✅ |

---

### 🗑 wg-easy удалён с vpn-tatra-9

**Что такое wg-easy:** веб-интерфейс для обычного WireGuard (порты 51820/51821)
**Почему удалён:**
- Несовместим с AmneziaWG клиентами
- Дублирует функцию AWG без обфускации
- Был установлен при первоначальной настройке сервера и забыт

```bash
# Команда удаления (выполнена с сервера 222):
ssh root@xxx.xxx.xxx.9 "docker stop wg-easy && docker rm wg-easy"
```

**Проверка всех серверов через Server Info Report показала:**
- vpn-tatra-9: было `uptime-kuma, amnezia-awg, wg-easy` → стало `uptime-kuma, amnezia-awg`
- Все остальные VPN: только `amnezia-awg` ✅

---

### 📋 Semaphore — известные ограничения

| Проблема | Статус | Решение |
|----------|--------|--------|
| PLAY RECAP в конце лога | Не убирается | Это встроено в Ansible |
| Summary вкладка пустая | Было при `stdout_callback=debug` | Убран из ansible.cfg |
| WARNING: Python interpreter | Исправлено | `interpreter_python=auto_silent` в ansible.cfg |
| `requirements.yml not found` | Не убирается | Это Semaphore проверяет перед запуском |
| awk кавычки YAML error | Исправлено | Экранировать `\"` внутри `"..."` |
| docker format YAML error | Исправлено | Обернуть в `{% raw %}...{% endraw %}` |

---

### 📁 Файлы изменены 2026-03-27

| Файл | Изменение |
|------|-----------|
| `ansible/ansible.cfg` | НОВЫЙ |
| `ansible/set_timezone.yml` | НОВЫЙ |
| `ansible/cleanup_vpn.yml` | Таблица отчёта + Samba fix |
| `ansible/server_info.yml` | YAML awk + docker format fix |
| `README.md` | Полное обновление |
| `CHANGELOG.md` | Добавлена эта запись |

---

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

---

### 🔕 Telegram-алерты — отключены лишние

- CPU/RAM алерты на 109: удалён cron `*/5 * * * * telegram_alert.sh`
- BEAR/BULL алерты crypto-bot: `tg_alerts_enabled: false` в config.json
- BACKUP OK уведомления: убраны (только при ошибке)

---

### 🛠️ Финальный cron на сервере 222
```
0 23 * * * php /var/www/spa/data/www/svetaform.eu/wp-cron.php > /dev/null 2>&1
*/15 * * * * bash /opt/server_tools/scripts/php_fpm_watchdog.sh
@reboot sleep 60 && bash /root/Linux_Server_Public/scripts/fastpanel_php_ondemand_v2026-03-25.sh
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

---

## v2026-03-26 (ночь 25→26) — BACKUP Restructure + SSH Keys + sshpass removal

### 🎯 Обзор
Полная реорганизация бэкапов. Переименование `/BackUP/` → `/BACKUP/`. Добавление `docker_backup.sh`.
Настройка SSH-ключей. Удаление sshpass.

#### Ключевые исправления
- `system_backup.sh` на 222 — не был в `/root/`, скопирован из репозитория
- `docker_backup.sh` — перенесён из `/root/crypto-docker/` в `/root/`
- `/BackUP/` → `/BACKUP/` на обоих серверах (пути исправлены через `sed -i`)
- На 109 не было cron для бэкапа — добавлен
- `sshpass` с захардкоженным паролем — полностью удалён, заменён SSH-ключами

---

## v2026-03-25/26 — Crypto-Bot Docker Migration (222-DE-NetCup)

### 🎯 Обзор
Полная миграция crypto-bot из bare-metal (`/root/aws-setup/`) в Docker (`/root/crypto-docker/`).
Новый сервер 222-DE-NetCup заменяет старый AWS.

#### Критические баги исправлены
- Alias `tr` → переименован в `bot` (`tr` — стандартная утилита Linux!)
- `[ -z "$PS1" ] && return` в `.bashrc` блокировал все aliases — закомментирован
- Binance удалён из UI `index.html`

---

## v2026-03-25 — RAM Crisis Fix + PHP-FPM ondemand

### 🎯 Обзор
Сервер 222 критически низкая RAM: 6.8GB из 7.7GB используется.
Исправлено переключением 40 PHP-FPM пулов в режим `ondemand`.
Результат: RAM упала с 6.8GB → 2.6GB.

---

## v2026-03-24 — Major Refactor + Telegram Alerts + SSH Banner

### 🎯 Обзор
Полный рефакторинг репозитория. Цветовая система терминала. Универсальный SSH баннер.
Telegram мониторинг с защитой от SSH атак.

---

_Last updated: 2026-03-27 23:50 by VladiMIR Bulantsev_
