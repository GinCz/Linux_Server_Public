# CHANGELOG

## v2026-03-28 — Crypto-Bot: удаление Binance из UI, fix reset.sh, перезапуск

### 🎯 Обзор сессии
Восстановление crypto-bot после удаления FreqTrade (который убил сервер).
Бот поднялся сам (`restart: unless-stopped`), но UI показывал старую версию с кнопкой Binance.
Исправлены: кнопка Binance в шаблоне, старые пути в `reset.sh`, пересборка образа.

---

### ⚠️ ВАЖНО — КАК РЕДАКТИРОВАТЬ UI КРИПТО-БОТА

**Веб-интерфейс:** https://crypto.gincz.com  
**Расположение файлов на сервере 222:** `/root/crypto-docker/`

#### Архитектура — почему volume важен
В `docker-compose.yml` шаблоны и скрипты смонтированы как **volume**:
```yaml
volumes:
  - ./templates:/app/templates
  - ./scripts:/app/scripts
```
Это значит:
- ✅ Правки HTML/JS в `/root/crypto-docker/templates/` — **сразу видны без пересборки**
- ✅ Правки скриптов в `/root/crypto-docker/scripts/` — тоже сразу
- ❌ Правки `app.py`, `Dockerfile` — требуют `docker-compose down && docker-compose up -d --build`

---

### 🔴 УДАЛЕНИЕ КНОПКИ БИРЖИ ИЗ UI

**Проблема:** После пересборки/рестарта появляется кнопка Binance в веб-интерфейсе.  
**Причина:** В `index.html` захардкожена кнопка и массив бирж `['okx','mexc','binance']`.  
**Файл:** `/root/crypto-docker/templates/index.html`

```bash
# Убираем кнопку Binance из HTML
sed -i "/<button onclick=\"setExchange('binance')/d" /root/crypto-docker/templates/index.html

# Убираем binance из JS-массива
sed -i "s/\['okx','mexc','binance'\]/['okx','mexc']/g" /root/crypto-docker/templates/index.html

# Проверка:
grep -i binance /root/crypto-docker/templates/index.html && echo "ЕЩЁ ЕСТЬ!" || echo "ЧИСТО ✅"
```

> ⚠️ После правки шаблона **перезапуск НЕ нужен** — volume смонтирован live.  
> Обнови: **Ctrl+Shift+R** (хард-релоад, сброс кэша).  
> Если через Cloudflare — **Purge Cache** в Cloudflare Dashboard.

---

### 🔄 Полный перезапуск крипто-бота

```bash
cd /root/crypto-docker

# Шаг 1 — убираем Binance (ПЕРЕД пересборкой!)
sed -i "/<button onclick=\"setExchange('binance')/d" templates/index.html
sed -i "s/\['okx','mexc','binance'\]/['okx','mexc']/g" templates/index.html

# Шаг 2 — пересборка
docker-compose down && docker-compose up -d --build

# Шаг 3 — проверка
docker logs crypto-bot --tail 30
```

> ⚠️ НЕ использовать `docker compose` (без дефиса) — не установлен buildx.  
> Только `docker-compose` (с дефисом, legacy).

---

### 🛠️ Исправление reset.sh — старые пути

```bash
sed -i 's|/root/aws-setup/scripts/|/root/crypto-docker/scripts/|g' /root/crypto-docker/scripts/reset.sh
sed -i 's|cd /root/aws-setup|cd /root/crypto-docker|g' /root/crypto-docker/scripts/reset.sh

grep "aws-setup" /root/crypto-docker/scripts/reset.sh && echo "ЕЩЁ ЕСТЬ!" || echo "ЧИСТО ✅"
```

---

### 📁 Структура crypto-bot (сервер 222)

```
/root/crypto-docker/
├── app.py                  # Flask веб-сервер
├── config.json             # Конфиг: биржа, параметры (КЛЮЧИ — в репо Secret!)
├── docker-compose.yml
├── Dockerfile
├── templates/
│   ├── index.html          # Главная страница (здесь была кнопка Binance)
│   ├── login.html
│   └── logs.html
└── scripts/
    ├── paper_trade.py
    ├── scanner.py
    └── reset.sh
```

---

### 📋 Шпаргалка — что где менять

| Задача | Файл | Нужен рестарт? |
|--------|------|----------------|
| Убрать/добавить кнопку биржи | `templates/index.html` | ❌ только Ctrl+Shift+R |
| Изменить UI | `templates/*.html` | ❌ только Ctrl+Shift+R |
| Торговая логика | `scripts/paper_trade.py` | ❌ |
| Параметры бота | `config.json` | ❌ |
| API маршруты | `app.py` | ✅ `docker-compose down && up -d --build` |
| Зависимости Python | `Dockerfile` | ✅ `docker-compose down && up -d --build` |

---

## v2026-03-27 — Ansible/Semaphore, Timezone, wg-easy removed, YAML fixes

### 🎯 Обзор сессии
Полная настройка Ansible + Semaphore UI.  
Установка Europe/Prague на всех серверах.  
Удаление лишнего контейнера wg-easy с vpn-tatra-9.  
Исправление YAML синтаксиса.

---

### 🗺 Timezone — установлено на всех серверах

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
| vpn-shahin-227 | Europe/Prague (CET, +0100) | ␅ |
| vpn-so-38 | Europe/Prague (CET, +0100) | ✅ |

---

### 🗑 wg-easy удалён с vpn-tatra-9

**Причина:** несовместим с AWG клиентами, дублирует функцию, был забыт.

```bash
# Команда удаления (c сервера 222):
ssh root@xxx.xxx.xxx.9 "docker stop wg-easy && docker rm wg-easy"
```

---

### 📋 Semaphore — известные ограничения

| Проблема | Статус | Решение |
|----------|--------|--------|
| PLAY RECAP в конце лога | Не убирается | Встроено в Ansible |
| Summary пустая | Исправлено | Убран `stdout_callback=debug` |
| WARNING Python | Исправлено | `interpreter_python=auto_silent` |
| awk кавычки | Исправлено | Экранировать `\"` |
| docker format YAML | Исправлено | `{% raw %}...{% endraw %}` |

---

## v2026-03-26 (вечер) — Backup+Clean, SSH-ключи, Telegram отключён, Crypto-Bot фиксы

### 🤖 Crypto-Bot — исправления

#### 1. Динамическая биржа (`paper_trade.py`)
- Функция `_make_exchange(cfg)` читает `config.json['exchange']`
- `"okx"` → инициализирует OKX (ключи хранятся в репо Secret!)
- `"mexc"` → инициализирует MEXC (ключи хранятся в репо Secret!)

#### 2. Новое условие выхода ENTRY-DROP
- `config.json["drop_from_entry"]` (default: 1.0 = 1%)
- выход если `pnl_entry <= -drop_from_entry`

#### 3. `config.json` — новые поля
```json
{
  "exchange": "okx",
  "drop_from_entry": 1.0,
  "tg_alerts_enabled": false
}
```
> ⚠️ API-ключи бирж — хранить только в приватном репо Secret!

---

### 🔒 SSH-ключи между серверами

#### 222 → 109
```bash
# На 109: создать папку vlad
mkdir -p /home/vlad/.ssh && chmod 700 /home/vlad/.ssh
# Добавить публичный ключ сервера 222 в authorized_keys
# (публичный ключ — не секрет, в ~/.ssh/id_rsa.pub)
echo "<пуб. ключ root@server-222>" >> /home/vlad/.ssh/authorized_keys
chmod 600 /home/vlad/.ssh/authorized_keys
chown -R vlad:vlad /home/vlad/.ssh
```

#### 109 → 222
```bash
# На 109:
ssh-copy-id -i ~/.ssh/id_rsa.pub vlad@xxx.xxx.xxx.222
```

---

### 📦 Новый скрипт `backup_clean.sh`

| Сервер | Путь |
|--------|------|
| 222 | `/root/backup_clean.sh` |
| 109 | `/root/backup_clean.sh` |

**Шаги:**
```
[1/6] Cleaning old files
[2/6] Pre-cleanup old backups
[3/6] Creating archive
[4/6] Saving locally
[5/6] Sending copy to remote (SSH-ключ vlad)
[6/6] Telegram (только при ошибке)
```

| Сервер | Размер | До оптимизации |
|--------|--------|----------------|
| 222 | ~1.4 MB | 196 MB |
| 109 | ~2.5 MB | 97 MB |

| Сервер | Cron | Лог |
|--------|-------|-----|
| 222 | `0 2 * * *` | `/var/log/system-backup.log` |
| 109 | `0 1 * * *` | `/var/log/system-backup.log` |

---

### 🔕 Telegram-алерты — отключены

- CPU/RAM алерты на 109: удалён cron
- BEAR/BULL алерты crypto-bot: `tg_alerts_enabled: false`
- BACKUP OK уведомления: убраны (только при ошибке)

---

### 🛠️ Финальный cron сервер 222
```
0 23 * * * php /var/www/.../wp-cron.php > /dev/null 2>&1
*/15 * * * * bash /opt/server_tools/scripts/php_fpm_watchdog.sh
@reboot sleep 60 && bash /root/Linux_Server_Public/scripts/fastpanel_php_ondemand_v2026-03-25.sh
0 2 * * * /root/backup_clean.sh >> /var/log/system-backup.log 2>&1
0 3 * * * /root/docker_backup.sh >> /var/log/docker-backup.log 2>&1
```

### 🛠️ Финальный cron сервер 109
```
0 1 * * * /root/backup_clean.sh >> /var/log/system-backup.log 2>&1
0 3 * * 0 /opt/server_tools/scripts/disk_cleanup.sh
30 3 * * 0 /usr/local/bin/auto_upgrade.sh
0 23 * * * curl -s "https://[...].ru/wp-cron.php" > /dev/null 2>&1
  ... (24 WordPress сайта)
```

---

## v2026-03-26 (ночь 25→26) — BACKUP Restructure + SSH Keys

- `/BackUP/` → `/BACKUP/` на обоих серверах
- `docker_backup.sh` перенесён в `/root/`
- `sshpass` удалён полностью, заменён SSH-ключами

---

## v2026-03-25/26 — Crypto-Bot Docker Migration

- Миграция из `/root/aws-setup/` в `/root/crypto-docker/`
- Alias `tr` → `bot` (`tr` — стандартная утилита Linux!)
- `[ -z "$PS1" ] && return` — закомментирован в `.bashrc`
- Binance удалён из UI

---

## v2026-03-25 — RAM Crisis Fix + PHP-FPM ondemand

- Сервер 222: RAM 6.8GB/7.7GB → 2.6GB после переключения 40 PHP-FPM пулов в `ondemand`

---

## v2026-03-24 — Major Refactor + Telegram Alerts + SSH Banner

- Полный рефакторинг репозитория
- Цветовая система терминала
- Универсальный SSH баннер
- Telegram мониторинг

---

_Last updated: 2026-03-30 by VladiMIR Bulantsev_
