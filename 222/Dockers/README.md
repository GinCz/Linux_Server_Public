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
| `f5bot` | `bash /root/docker_backup.sh` | Бэкап всех Docker на .222 |
| `f9bot` | `bash /root/Linux_Server_Public/222/Dockers/f9bot_restore.sh` | Восстановление Docker на .222 |
| `f5vpn` | `bash /root/Linux_Server_Public/222/Dockers/vpn_docker_backup.sh` | Бэкап Docker со всех VPN серверов |

### Добавить `f5vpn` в `.bashrc` (сервер .222)
```bash
echo "alias f5vpn='bash /root/Linux_Server_Public/222/Dockers/vpn_docker_backup.sh'" >> ~/.bashrc && source ~/.bashrc
```

### Обновить `f9bot` в `.bashrc`
```bash
sed -i "s|alias f9bot=.*|alias f9bot='bash /root/Linux_Server_Public/222/Dockers/f9bot_restore.sh'|" ~/.bashrc && source ~/.bashrc
```

---

## 🔄 Как работает f9bot

**Шаг 1 — выбор контейнера:**
```
[1] crypto-bot
[2] amnezia-awg
[3] semaphore
```

**Шаг 2 — выбор резервной копии:**
```
  [1] amnezia-awg_2026-04-08.tar.gz  1.8G  [NEWEST]
  [2] amnezia-awg_2026-04-07.tar.gz  1.8G
  [3] amnezia-awg_2026-04-06.tar.gz  1.7G  [OLDEST]
```

> ℹ️ Для `amnezia-awg`: перед остановкой покажет публичный ключ и количество peers.

---

## 📡 Как работает f5vpn

Скрипт запускается с сервера `.222`, по SSH MASTER ключу (`/root/.ssh/id_ed25519`) подключается ко всем VPN серверам, автоматически определяет запущенные контейнеры и делает `docker commit` бэкап каждого.

```
💻 alex47 (109.234.38.47)
  📸 commit amnezia-awg ...
  ✅ amnezia-awg → /BACKUP/vpn/alex47/amnezia-awg_2026-04-08.tar.gz (1.8G)

💻 4ton237 (144.124.228.237)
  📸 commit amnezia-awg ...
  ✅ amnezia-awg → /BACKUP/vpn/4ton237/amnezia-awg_2026-04-08.tar.gz (1.7G)
  ...
```

**Список VPN серверов:**

| Метка | IP |
|---|---|
| alex47 | 109.234.38.47 |
| 4ton237 | 144.124.228.237 |
| tatra9 | 144.124.232.9 |
| shahin227 | 144.124.228.227 |
| stolb24 | 144.124.239.24 |
| pilik178 | 91.84.118.178 |
| ilya176 | 146.103.110.176 |
| so38 | 144.124.233.38 |

**Cron (04:00 ежедневно, сервер .222):**
```
0 4 * * * /root/Linux_Server_Public/222/Dockers/vpn_docker_backup.sh >> /var/log/vpn_docker_backup.log 2>&1
```

---

## 🚨 Стратегии бэкапа

### Strategy A — VOLUMES (crypto-bot, semaphore)
- Docker image → `docker save`
- Папка данных → `tar`

### Strategy B — COMMIT (amnezia-awg, VPN сервера) ⭐
`docker commit` — полный снимок. Сохраняет ВСЁ: ключи, `wg0.conf`, пользователей.

---

## ⚙️ Параметры AmneziaWG (.222)

| Параметр | Значение | Описание |
|---|---|---|
| `ListenPort` | `123` | UDP порт |
| `S1` | `53` | Junk size 1 |
| `S2` | `138` | Junk size 2 |
| `H1-H4` | см. ниже | Header magic |
| VPN subnet | `10.8.1.0/24` | |

---

## 📁 Файлы в этой папке

```
222/Dockers/
├── README.md              ← этот файл
├── f9bot_restore.sh       ← f9bot (universal restore .222)
├── vpn_docker_backup.sh   ← f5vpn (backup all VPN servers)
└── awg_restore.sh         ← AWG restore (запасной)
```

---

## ❗ Типичные ошибки

| Ошибка | Решение |
|---|---|
| VPN не работает после запуска | `-p 123:123/udp` |
| `CreateTUN device failed` | `--privileged` |
| Пользователи не подключаются | `ufw allow 123/udp` |
| `wg show` пустой | `docker logs amnezia-awg` + подождать 10с |

---

> = Rooted by VladiMIR | AI =
