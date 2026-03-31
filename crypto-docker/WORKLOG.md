# WORKLOG — Крипто-бот / Сервер 222-DE-NetCup

> Лог ведётся на русском языке. Всё важное — здесь.
> Репозиторий приватный. Пишем подробно.

---

## 31 марта 2026 (вторник)

### 🔧 Восстановление крипто-бота из резервной копии
- Контейнер `crypto-bot` завис / не запускался корректно
- Выбран бэкап: `crypto-bot_2026-03-31_03-00.tar.gz` (98M, из `/BACKUP/222/docker/crypto/`)
- Процедура восстановления:
  1. `docker stop crypto-bot && docker rm crypto-bot`
  2. `cp -a /root/crypto-docker /root/crypto-docker.bak_2026-03-31` — сохранили текущее состояние
  3. `tar -xzf /BACKUP/222/docker/crypto/crypto-bot_2026-03-31_03-00.tar.gz -C /` — распаковка
  4. `docker load -i /tmp/crypto-bot-image.tar.gz` — загрузка образа (267MB, `crypto-docker_crypto-bot:latest`)
  5. `cd /root/crypto-docker && docker-compose up -d` — запуск
- Результат: контейнер запустился, порт `127.0.0.1:5000->5000/tcp` активен ✔

### 📝 Создан скрипт `crypto_restore.sh`
- Путь: `/root/Linux_Server_Public/222/crypto_restore.sh`
- Показывает последние 3 бэкапа с размером и датой
- Выбор по номеру `[1-3]`, подтверждение `[Y/N]`
- Автоматически: стоп контейнера → бэкап текущей папки → распаковка → загрузка образа → запуск
- Цветной вывод: голубые полосы `=====`, жёлтые вопросы, зелёные `✔ Done.`, красное предупреждение ⚠
- Запуск: `bash /root/Linux_Server_Public/222/crypto_restore.sh`

### 🔧 Исправлен alias `mc` (Midnight Commander)
- Проблема: `mc` зависал при запуске — использовался wrapper `mc_lastdir_wrapper.sh`
  который вешался на `source` в некоторых сессиях
- Решение: wrapper удалён, alias упрощён до `alias mc='/usr/bin/mc'` в `shared_aliases.sh`
- Файл `/root/.mc_lastdir_wrapper.sh` удалён с сервера

---

## 30 марта 2026 (понедельник)

### 🐳 Система резервного копирования Docker
- Создан универсальный скрипт `docker_backup.sh` (версия v2026-03-30c)
- Бэкапит 3 контейнера: `crypto-bot`, `semaphore`, `amnezia-awg`
- Использует `pigz` для быстрого сжатия (параллельное)
- Бэкапы хранятся в `/BACKUP/222/docker/{имя_контейнера}/`
- Alias: `dbackup`
- Расписание cron: ежедневно в 03:00

### 📋 Рефакторинг aliases на всех серверах
- Файл `scripts/shared_aliases.sh` — универсальные aliases для всех серверов (222, 109, VPN)
- Удалены устаревшие aliases
- Добавлен `alias aw` — статистика AmneziaWG/WireGuard
- Порядок: git → VPN → цвета/навигация → mc

### 🚀 VPN mass management
- Создан скрипт `vpn_deploy.sh` — выполняет команду на ВСЕХ VPN серверах одновременно
- Alias: `vpndeploy`
- Создан `VPN/deploy_bashrc.sh` — разворачивает `.bashrc` + aliases на новом VPN сервере

### 📊 Обновлён server-info.md
- Добавлены: Semaphore CI/CD, AmneziaVPN docker, расписание бэкапов, admin ссылки
- Исправлены поддомены, восстановлена ссылка Netdata
- Добавлена колонка Server в domains.md

### 📦 Скрипт backup_clean.sh
- Объединил лучшее из двух предыдущих скриптов
- Максимальная очистка системы перед архивацией
- Избирательная архивация файлов < 30MB
- Alias: `backup`
- Старый `system_backup.sh` — удалён

---

## 29 марта 2026 (воскресенье)

### ⚔️ Semaphore CI/CD — 3-дневная битва с установкой
- Проблема: Semaphore не запускался в Docker из-за конфликта конфигурации
- Исправлены: переменные окружения, порты, volume mapping
- Итог: Semaphore работает, доступен через nginx reverse proxy
- Подробности в CHANGELOG.md

### 🔒 Безопасность
- Добавлен мастер SSH-ключ в README для доступа ко всем серверам
- Описаны правила VPN mass management (не запускать опасные команды без проверки!)
- Правила для AI-ассистента при работе с сервером — предупреждение перед опасными операциями

---

## Структура бэкапов криптобота

```
/BACKUP/222/docker/crypto/
├── crypto-bot_2026-03-31_03-00.tar.gz   ← самый свежий (авто, cron 03:00)
├── crypto-bot_2026-03-30_03-00.tar.gz
├── crypto-bot_2026-03-30_01-41.tar.gz
└── crypto_2026-03-30_01-15.tar.gz
```

Внутри каждого архива:
- `root/crypto-docker/` — все файлы проекта (скрипты, конфиги, шаблоны, .git)
- `tmp/crypto-bot-image.tar.gz` — Docker образ (267MB, `crypto-docker_crypto-bot:latest`)

## Как восстановить бота вручную

```bash
# 1. Остановить контейнер
docker stop crypto-bot && docker rm crypto-bot

# 2. Распаковать бэкап
tar -xzf /BACKUP/222/docker/crypto/crypto-bot_ДАТА.tar.gz -C /

# 3. Загрузить Docker образ
docker load -i /tmp/crypto-bot-image.tar.gz

# 4. Запустить
cd /root/crypto-docker && docker-compose up -d

# Или одной командой через скрипт:
bash /root/Linux_Server_Public/222/crypto_restore.sh
```
