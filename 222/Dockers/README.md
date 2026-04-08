# 🐳 Docker — Backup & Restore Guide

> **Server:** 222-DE-NetCup | IP: ...222  
> **Version:** v2026-04-08  
> **Author:** Ing. VladiMIR Bulantsev  
> = Rooted by VladiMIR | AI =

---

## 📦 Контейнеры на сервере .222

| # | Имя | Стратегия | Папка данных |
|---|---|---|---|
| 1 | `crypto-docker_crypto-bot` | VOLUMES | `/root/crypto-docker/` |
| 2 | `semaphore` | VOLUMES | `/root/semaphore-data/` |
| 3 | `amnezia-awg` | COMMIT | внутри контейнера `/opt/amnezia/awg/` |

---

## 🔑 Алиасы

| Алиас | Команда | Описание |
|---|---|---|
| `f5bot` | `bash /root/docker_backup.sh` | Запустить бэкап всех Docker |
| `f9` | `bash /root/Linux_Server_Public/222/Dockers/f9_restore.sh` | Универсальное меню восстановления |
| `f9bot` | `bash /root/Linux_Server_Public/222/crypto_restore.sh` | Старый скрипт (crypto only) |

### Добавить алиас `f9` в `.bashrc`
```bash
echo "alias f9='bash /root/Linux_Server_Public/222/Dockers/f9_restore.sh'" >> ~/.bashrc
source ~/.bashrc
```

---

## 🔄 Как работает F9 (меню восстановления)

```
[1] crypto-bot       — crypto trading bot
[2] amnezia-awg      — VPN (AmneziaWG)
[3] semaphore        — Semaphore CI/CD

➤ Select container [1-3]:
```
Затем:
```
  [1] crypto-bot_2026-04-08.tar.gz   1.2G   2026-04-08 03:00  [NEWEST]
  [2] crypto-bot_2026-04-07.tar.gz   1.2G   2026-04-07 03:00
  [3] crypto-bot_2026-04-06.tar.gz   1.1G   2026-04-06 03:00  [OLDEST]

➤ Select backup [1-3]:
```

> ℹ️ Список всех доступных бэкапов с пометками `[NEWEST]` / `[OLDEST]`.

---

## 🚨 Стратегии бэкапа

### Strategy A — VOLUMES (crypto-bot, semaphore)

- Docker image → `docker save`
- Папка данных → `tar` архив

### Strategy B — COMMIT (amnezia-awg) ⭐

`docker commit` — полный снимок живого контейнера.

Сохраняет ВСЁ: ключи WireGuard, `wg0.conf` (порт, junk S1/S2/H1-H4), базу пользователей `clientsTable`.

> ⚠️ `docker load` загружает образ, но **НЕ** запускает контейнер автоматически.

---

## ⚙️ Параметры AmneziaWG (сервер .222)

| Параметр | Значение | Описание |
|---|---|---|
| `ListenPort` | `123` | UDP порт (маскировка под NTP) |
| `S1` | `53` | Junk size 1 |
| `S2` | `138` | Junk size 2 |
| `H1` | `930746957` | Header magic 1 |
| `H2` | `603274345` | Header magic 2 |
| `H3` | `1910889985` | Header magic 3 |
| `H4` | `1478872475` | Header magic 4 |
| `JC` | `4` | Junk count |
| `Jmin` | `10` | Junk min |
| `Jmax` | `50` | Junk max |
| VPN subnet | `10.8.1.0/24` | Внутренняя сеть VPN |

> Текущий рабочий порт: `123/udp`.
> **НЕ менять** без предварительной диагностики!

---

## 📅 Расписание cron

```
0 3 * * * /root/docker_backup.sh >> /var/log/docker-backup.log 2>&1
```

Хранится **последних 3 архива** на каждый контейнер.

---

## 📁 Файла в этой папке

```
222/Dockers/
├── README.md           ← этот файл
├── f9_restore.sh       ← универсальный restore (F9)
└── awg_restore.sh      ← старый AWG-специфичный restore
```

Скрипты на сервере:
```
/root/docker_backup.sh               ← F5 (cron + ручной запуск)
/root/Linux_Server_Public/222/
├── crypto_restore.sh                ← f9bot (legacy, crypto only)
└── Dockers/
    └── f9_restore.sh                ← f9 (universal menu)
```

---

## ❗ Типичные ошибки

| Ошибка | Решение |
|---|---|
| VPN не работает после запуска | Проверить порт: `-p 123:123/udp` |
| `docker load` загрузил, данных нет | Использовать ТОЛЬКО бэкап из `/BACKUP/222/docker/amnezia/` |
| `CreateTUN device failed` | Добавить `--privileged` |
| Пользователи не подключаются | `ufw allow 123/udp` |
| `wg show` пустой | `docker logs amnezia-awg` и подождать 10 сек |

---

> = Rooted by VladiMIR | AI =
