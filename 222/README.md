# 🐳 222-DE-NetCup — Docker Backup Script

> `= Rooted by VladiMIR | AI =`  
> Server: **222-DE-NetCup** | IP: `152.53.182.222` | NetCup VPS 1000 G12, Ubuntu 24, FASTPANEL

---

## 📋 Overview

`docker_backup.sh` — полный бэкап всех Docker-контейнеров сервера в один запуск.  
Сохраняет образ + данные в `.tar.gz` архив с ротацией (хранит последние N копий).  
Поддерживает два режима: **volumes** (образ + данные) и **commit** (снимок запущенного контейнера).

---

## 🗂 Структура файлов

```
222/
├── docker_backup.sh    # основной скрипт бэкапа
└── README.md           # эта документация

/BACKUP/222/docker/     # папка хранения архивов на сервере
├── crypto/             # архивы crypto-bot
│   └── crypto-bot_YYYY-MM-DD_HH-MM.tar.gz
├── semaphore/          # архивы semaphore
│   └── semaphore_YYYY-MM-DD_HH-MM.tar.gz
└── amnezia/            # архивы amnezia-awg
    └── amnezia-awg_YYYY-MM-DD_HH-MM.tar.gz
```

---

## 🐳 Контейнеры

| # | Контейнер | Стратегия | Данные | Образ |
|---|-----------|-----------|--------|-------|
| 1 | `crypto-bot` | volumes | `/root/crypto-docker` | `crypto-docker_crypto-bot:latest` |
| 2 | `semaphore` | volumes | `/root/semaphore-data` | `semaphoreui/semaphore:latest` |
| 3 | `amnezia-awg` | commit | — (commit snapshot) | `amnezia-awg` |

---

## ⚙️ Стратегии бэкапа

### 🔵 Strategy: `volumes`
Для контейнеров, которые **можно остановить** на время архивации.

**Алгоритм:**
1. 🧹 Очистка мусора в `data_dir` — удаление `*.log`, `*.pyc`, `*.tmp`, `*.bak`, `__pycache__`
2. 💾 Сохранение Docker-образа: `docker save image | pigz → /tmp/<label>-image.tar.gz`
3. ⏸ Остановка `docker-compose stop` (только если указан `compose_dir`)
4. 📦 Создание архива: `tar + pigz → /BACKUP/222/docker/<label>/<label>_DATE.tar.gz`
   - Содержит: `data_dir` + `image.tar.gz`
5. ▶️ Запуск обратно: `docker-compose up -d`
6. 🗑 Ротация: удаление старых архивов, оставляет последние `$KEEP` штук

**Почему semaphore весит 296M?**  
Образ `semaphoreui/semaphore:latest` = **869MB** несжатый.  
После pigz = **296MB** (~34% от оригинала). Это нормально — Go-бинарник + всё окружение.

---

### 🟣 Strategy: `commit`
Для контейнеров, которые **нельзя останавливать** (VPN, туннели — `amnezia-awg`).

**Алгоритм:**
1. 🧹 Очистка мусора внутри контейнера: `docker exec ... sh -c cleanup`
   - Удаляет `/tmp/*` и `/var/log/*.log`, `*.gz`
2. 📸 Снимок: `docker commit <container> <label>-backup:DATE` → возвращает `commit_id`
3. 📦 Архивация снимка: `docker save <snapshot> | pigz → /BACKUP/222/docker/<label>/<label>_DATE.tar.gz`
4. 🗑 Удаление временного снимка: `docker rmi <label>-backup:DATE`
5. 🗑 Ротация старых архивов

---

## 🚀 Установка и запуск

### Первичная установка

```bash
# Скачать скрипт на сервер
cd /root
git clone https://github.com/GinCz/Linux_Server_Public.git
cp Linux_Server_Public/222/docker_backup.sh /root/docker_backup.sh
chmod +x /root/docker_backup.sh
```

### Обновление скрипта

```bash
cd /root/Linux_Server_Public && git pull --rebase && \
cp 222/docker_backup.sh /root/docker_backup.sh && \
chmod +x /root/docker_backup.sh && echo "✅ OK"
```

### Ручной запуск

```bash
/root/docker_backup.sh
```

### Автоматический запуск (cron)

```bash
crontab -e
```

Добавить строку (пример — каждую ночь в 03:00):

```cron
0 3 * * * /root/docker_backup.sh >> /var/log/docker_backup.log 2>&1
```

---

## ⚙️ Конфигурация

Все настройки в верхней части скрипта:

```bash
TOKEN=""              # Telegram Bot Token (оставь пустым, чтобы отключить уведомления)
CHAT_ID=""            # Telegram Chat ID
BACKUP_ROOT="/BACKUP/222/docker"  # корень хранения архивов
KEEP=3                # сколько архивов хранить на контейнер
SERVER_LABEL="222-DE-NetCup"      # метка сервера в выводе
```

### Как добавить новый контейнер

Скопируй блок конфигурации, увеличь номер, выбери стратегию и добавь вызов в `MAIN`:

```bash
# Пример нового контейнера (strategy: volumes)
CONTAINER_4_LABEL="my-app"
CONTAINER_4_STRATEGY="volumes"
CONTAINER_4_COMPOSE_DIR="/root/my-app"   # путь к docker-compose (или "" если нет)
CONTAINER_4_DATA_DIR="/root/my-app/data" # папка с данными для архивации
CONTAINER_4_IMAGE="my-app"               # часть имени образа (grep -i)
CONTAINER_4_CLEANUP="
    find /root/my-app -name '*.log' -delete 2>/dev/null;
"
```

В секции `MAIN`:

```bash
print_header "4" "$CONTAINER_4_LABEL" "$CONTAINER_4_STRATEGY"
backup_volumes \
    "$CONTAINER_4_LABEL" "$CONTAINER_4_IMAGE" \
    "$CONTAINER_4_COMPOSE_DIR" "$CONTAINER_4_DATA_DIR" \
    "$CONTAINER_4_CLEANUP" "${BACKUP_ROOT}/my-app"
```

> Не забудь обновить `TOTAL_CONTAINERS=4`

---

## 📤 Telegram-уведомления

По завершении скрипт отправляет итоговый отчёт в Telegram:

- ✅ при успехе: список архивов + общий размер + время
- ⚠️ при ошибках: количество ошибок + список контейнеров

Чтобы включить — заполни `TOKEN` и `CHAT_ID` в конфиге.  
Чтобы получить `CHAT_ID`: напиши боту [@userinfobot](https://t.me/userinfobot).

---

## 🔧 Зависимости

| Утилита | Назначение | Автоустановка |
|---------|-----------|---------------|
| `pigz` | параллельное сжатие (быстрее gzip) | ✅ да, если не найден |
| `docker` | управление контейнерами | ❌ должен быть установлен |
| `docker-compose` | запуск/остановка стека | ❌ только для volumes-стратегии |
| `tar` | архивация | ✅ есть в Ubuntu |
| `bc` | расчёт скорости MB/s | ✅ есть в Ubuntu |
| `curl` | Telegram API | ✅ есть в Ubuntu |

---

## 📊 Пример вывода

```
══════════════════════════════════════════════════════════════════════════════════════════════
  = Rooted by VladiMIR | AI =   🐳 DOCKER BACKUP   222-DE-NetCup
  📅 2026-04-08 22:56:00   compression: pigz ⚡
  🖥️  Hostname: 222-DE-NetCup   IP: 152.53.182.222
  💿 Disk free: 196G   Load: 0.38, 0.90, 1.23
  📦 Containers: 3   Keep: 3   Root: /BACKUP/222/docker
══════════════════════════════════════════════════════════════════════════════════════════════
  [1/3] crypto-bot   strategy: volumes
22:56:00   🧹 crypto-bot cleanup...  data: 2.1M
22:56:00   💾 crypto-bot saving image...
22:56:00      └─ crypto-docker_crypto-bot:latest (267MB)
22:56:16   📦 crypto-bot archiving (pigz ⚡)...
22:56:17 ✅ crypto-bot: crypto-bot_2026-04-08_22-56.tar.gz
     ├─ Size   : 98M
     ├─ Time   : 1s  @ 97.7 MB/s
     └─ Status : OK ✓
     📂 Archives: 3/3 kept
        └─ 98M 2026-04-08 22:51:52 — crypto-bot_2026-04-08_22-51.tar.gz
        └─ 98M 2026-04-08 22:46:39 — crypto-bot_2026-04-08_22-46.tar.gz
...
══════════════════════════════════════════════════════════════════════════════════════════════
  ✅  ALL DONE — NO ERRORS
  ├─ Total size  : 1.2G
  ├─ Total time  : 40s
  ├─ Errors      : 0
  └─ Finished at : 2026-04-08 22:56:40
══════════════════════════════════════════════════════════════════════════════════════════════
```

---

## 🗄 Восстановление из архива

### Восстановление образа

```bash
# Распаковать архив
tar -xzf /BACKUP/222/docker/crypto/crypto-bot_2026-04-08_22-56.tar.gz -C /tmp/restore/

# Загрузить образ обратно в Docker
docker load < /tmp/restore/tmp/crypto-bot-image.tar.gz

# Проверить
docker images | grep crypto
```

### Восстановление данных

```bash
# Данные находятся в архиве по оригинальному пути
# Пример: восстановить /root/crypto-docker из архива
tar -xzf /BACKUP/222/docker/crypto/crypto-bot_2026-04-08_22-56.tar.gz \
    -C / root/crypto-docker --strip-components=1
```

---

## 📜 История версий

| Версия | Дата | Изменения |
|--------|------|-----------|
| v2026-04-08d | 2026-04-08 | `= Rooted by VladiMIR | AI =` в первую строку шапки; убрана пустая строка после commit-блока |
| v2026-04-08c | 2026-04-08 | Убран progress bar полностью; компактный вывод; нет пустых строк между шапкой и контейнерами |
| v2026-04-08b | 2026-04-08 | Живой progress bar (\r ping-pong); убраны статичные star_progress; убран HR-разделитель |
| v2026-04-08  | 2026-04-08 | Первая версия: spinner, цветной вывод, две стратегии, Telegram, ротация |

---

*= Rooted by VladiMIR | AI =*
