# 🐳 Docker — Backup & Restore Guide

> **Server:** 222-DE-NetCup | IP: 152.53.182.222  
> **Version:** v2026-04-08  
> **Author:** Ing. VladiMIR Bulantsev  
> = Rooted by VladiMIR | AI =

---

## 📦 Контейнеры на сервере .222

| # | Имя контейнера | Стратегия | Порт | Данные |
|---|---|---|---|---|
| 1 | `crypto-docker_crypto-bot` | VOLUMES | — | `/root/crypto-docker/` |
| 2 | `semaphore` | VOLUMES | — | `/root/semaphore-data/` |
| 3 | `amnezia-awg` | COMMIT | `123/udp` | внутри контейнера `/opt/amnezia/awg/` |

---

## 🔄 Стратегии бэкапа

### Strategy A — VOLUMES (crypto-bot, semaphore)

Сохраняет:
- Docker image (через `docker save`)
- Папку с данными на хосте (через `tar`)

Восстановление:
```bash
# 1. Распаковать архив
tar -xzf /BACKUP/222/docker/crypto/crypto-bot_ДАТА.tar.gz -C /tmp/restore/

# 2. Загрузить образ
docker load -i /tmp/restore/crypto-bot-image.tar.gz

# 3. Восстановить данные
cp -r /tmp/restore/root/crypto-docker/ /root/crypto-docker/

# 4. Запустить через compose
cd /root/crypto-docker && docker-compose up -d
```

---

### Strategy B — COMMIT (amnezia-awg) ⭐

`docker commit` делает **полный снимок живого контейнера** — сохраняет ВСЁ:
- WireGuard ключи (server private/public/psk)
- Конфиг `wg0.conf` (порт, junk параметры S1/S2/H1-H4)
- Базу пользователей `clientsTable` (все пиры с ключами)
- Бинарники и настройки AmneziaWG

> ⚠️ **ВАЖНО:** `docker load` после `docker commit` загружает образ,  
> но НЕ запускает контейнер автоматически!  
> Нужно вручную запустить с правильными параметрами (см. ниже).

---

## 🚨 Восстановление amnezia-awg (ПОШАГОВО)

### Шаг 1 — Загрузить бэкап
```bash
# Смотрим доступные бэкапы
ls -lah /BACKUP/222/docker/amnezia/

# Загружаем последний (или нужную дату)
docker load -i /BACKUP/222/docker/amnezia/amnezia-awg_ДАТА.tar.gz
```

### Шаг 2 — Проверить что внутри бэкапа
```bash
# Проверяем ключи и пользователей БЕЗ запуска wg0
docker run --rm --entrypoint="" amnezia-awg-backup:ДАТА ls -lah /opt/amnezia/awg/
docker run --rm --entrypoint="" amnezia-awg-backup:ДАТА cat /opt/amnezia/awg/wireguard_server_public_key.key
docker run --rm --entrypoint="" amnezia-awg-backup:ДАТА cat /opt/amnezia/awg/clientsTable
```

### Шаг 3 — Тегировать образ
```bash
docker tag amnezia-awg-backup:ДАТА amnezia-awg:latest
```

### Шаг 4 — Остановить старый контейнер (если есть)
```bash
docker stop amnezia-awg 2>/dev/null
docker rm amnezia-awg 2>/dev/null
```

### Шаг 5 — Запустить контейнер
```bash
docker run -d \
  --name amnezia-awg \
  --privileged \
  --cap-add CAP_NET_ADMIN \
  --cap-add CAP_SYS_MODULE \
  --sysctl net.ipv4.ip_forward=1 \
  --sysctl net.ipv4.conf.all.src_valid_mark=1 \
  -p 123:123/udp \
  -v /lib/modules:/lib/modules \
  --restart always \
  amnezia-awg
```

> ⚠️ **Порт 123/udp** — намеренно выбранный порт для маскировки под NTP трафик.

### Шаг 6 — Проверить
```bash
sleep 8
docker exec amnezia-awg wg show
ss -ulnp | grep 123
```

### Шаг 7 — UFW (если порт не открыт)
```bash
ufw allow 123/udp
ufw status | grep 123
```

---

## ✅ Быстрое восстановление (одной командой)

Используй готовый скрипт:
```bash
bash /root/Linux_Server_Public/222/Dockers/awg_restore.sh
```
См. файл `awg_restore.sh` в этой же папке.

---

## ⚙️ Параметры AmneziaWG (сервер .222)

Эти параметры зашиты в `wg0.conf` внутри контейнера и **автоматически сохраняются в бэкап**.

| Параметр | Значение | Описание |
|---|---|---|
| `ListenPort` | `123` | Порт UDP (маскировка под NTP) |
| `S1` | `53` | Junk size 1 |
| `S2` | `138` | Junk size 2 |
| `H1` | `930746957` | Header magic 1 |
| `H2` | `603274345` | Header magic 2 |
| `H3` | `1910889985` | Header magic 3 |
| `H4` | `1478872475` | Header magic 4 |
| `JC` | `4` | Junk count |
| `Jmin` | `10` | Junk min size |
| `Jmax` | `50` | Junk max size |
| Server public key | `qpZOpC2TFxc0//NL1B9XOqTuTW88/anmu9nB2igtXWQ=` | Публичный ключ сервера |
| VPN subnet | `10.8.1.0/24` | Внутренняя сеть VPN |

---

## 👥 Пользователи VPN (актуально на 2026-04-08)

| IP | Имя | Устройство | Создан |
|---|---|---|---|
| 10.8.1.1 | Admin | Windows 10 21H1 | 28.03.2026 |
| 10.8.1.2 | Admin | Android 10 | 29.03.2026 |
| 10.8.1.3 | TanLun | iPhone | 29.03.2026 |
| 10.8.1.4 | TanLun | Android | 29.03.2026 |
| 10.8.1.5 | MaxLun | Android | 29.03.2026 |
| 10.8.1.6 | MaxLun | iPhone | 30.03.2026 |
| 10.8.1.7 | Evgen | Android ZFold | 02.04.2026 |

> ℹ️ Пользователи **НЕ требуют пересоздания ключей** при восстановлении из бэкапа.  
> Все ключи, PSK и конфиги сохраняются внутри `docker commit` образа.

---

## 📅 Расписание бэкапов (cron)

```
0 3 * * * /root/docker_backup.sh >> /var/log/docker-backup.log 2>&1
```

Бэкап запускается **каждый день в 03:00**.  
Хранится **последних 3 архива** на каждый контейнер.  
Лог: `/var/log/docker-backup.log`

---

## 🔑 Алиасы (aliases)

| Алиас | Команда | Описание |
|---|---|---|
| `f5bot` | `bash /root/docker_backup.sh` | Запустить бэкап вручную |
| `awgstat` | `bash /root/Linux_Server_Public/scripts/awg-stats.sh` | Статистика VPN пользователей |
| `awgrestore` | `bash /root/Linux_Server_Public/222/Dockers/awg_restore.sh` | Восстановить amnezia-awg |

Добавить алиасы в `.bashrc`:
```bash
echo "alias f5bot='bash /root/docker_backup.sh'" >> ~/.bashrc
echo "alias awgstat='bash /root/Linux_Server_Public/scripts/awg-stats.sh'" >> ~/.bashrc
echo "alias awgrestore='bash /root/Linux_Server_Public/222/Dockers/awg_restore.sh'" >> ~/.bashrc
source ~/.bashrc
```

---

## 📁 Расположение файлов

```
/root/
├── docker_backup.sh              # Основной скрипт бэкапа (запускается cron)
├── Linux_Server_Public/
│   └── 222/
│       └── Dockers/
│           ├── README.md         # Этот файл
│           └── awg_restore.sh    # Скрипт восстановления amnezia-awg
│
/BACKUP/222/docker/
├── amnezia/                      # Бэкапы amnezia-awg (3 последних)
│   ├── amnezia-awg_ДАТА.tar.gz
│   └── ...
├── crypto/                       # Бэкапы crypto-bot
└── semaphore/                    # Бэкапы semaphore
```

---

## ❗ Типичные ошибки при восстановлении

| Ошибка | Причина | Решение |
|---|---|---|
| Контейнер запустился но VPN не работает | Неправильный проброс порта | `-p 123:123/udp` (не 34337!) |
| `docker load` загрузил образ, но данных нет | Использовали чистый образ `amneziavpn/amnezia-wg:latest` | Загружать ТОЛЬКО из бэкапа `/BACKUP/222/docker/amnezia/` |
| `CreateTUN device failed` | Контейнер запущен без `--privileged` | Добавить `--privileged` и `--cap-add` |
| Пользователи не подключаются | UFW блокирует порт | `ufw allow 123/udp` |
| `wg show` пустой | wg0 не поднялся | `docker logs amnezia-awg` и подождать 10 сек |

---

> = Rooted by VladiMIR | AI =
