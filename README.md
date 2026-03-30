# Linux Server Public — Scripts & Configs
GitHub: https://github.com/GinCz/Linux_Server_Public
Author: Ing. VladiМIR Bulantsev
Last updated: v2026-03-30

---

## 🤖 ПРАВИЛА РАБОТЫ С AI (обязательно соблюдать!)

> Эти правила установлены VladiMIR и применяются при КАЖДОМ сеансе работы с AI.

1. **Весь код и команды — только на английском**, включая комментарии.
2. **В начале каждого скрипта — `clear`** (очистка терминала от предыдущего вывода).
3. **Подпись в каждом скрипте:** `# = Rooted by VladiMIR | AI =`
4. **Версия в каждом скрипте:** `# Version: v2026-XX-XX` (дата сегодняшнего дня).
5. **Код всегда одним блоком** — не разбивать на 10 частей, копировать должно быть удобно.
6. **Никогда не трогать сервер без изучения репозитория** — сначала `git pull`, потом понять как устроено.
7. **Перед изменением `.bashrc`** — изучить структуру алиасов (`.bashrc` каждого сервера + `shared_aliases.sh`).
8. **Алиасы после перезагрузки** — хранятся в `.bashrc` (копируется из репо), загружаются автоматически при каждом SSH-входе. НЕ использовать `/etc/profile.d/` или другие места.
9. **Многосерверные команды — через Semaphore** (не открывать каждый сервер руками). Плейбук создать, запустить из `sem.gincz.com`.
10. **Секреты (IP, пароли, ключи)** — только в приватном репо **Secret**. В этом репо — только маски: `xxx.xxx.xxx.222`.

---

## 🚀 SEMAPHORE — главный инструмент управления серверами

**Semaphore UI:** https://sem.gincz.com (Docker на сервере 222, порт 3000)

> ⚡ Когда нужно выполнить что-то на нескольких серверах — **НЕ заходить на каждый сервер руками**.
> Создать плейбук Ansible, добавить шаблон в Semaphore, запустить один раз — применится ко всем.

### Как создать шаблон (API)
```bash
clear
TOKEN="твой_токен"  # ← хранится в репо Secret!
docker exec semaphore wget -q -O- \
  --header="Content-Type: application/json" \
  --header="X-Requested-With: XMLHttpRequest" \
  --header="Authorization: Bearer $TOKEN" \
  --post-data='{
    "name": "Название шаблона",
    "app": "ansible",
    "playbook": "ansible/файл.yml",
    "inventory_id": 1,
    "repository_id": 1,
    "environment_id": 2,
    "ssh_key_id": 2
  }' \
  http://localhost:3000/api/project/1/templates
```

### Текущие шаблоны Semaphore

| ID | Название | Плейбук | Группа серверов |
|----|---------|---------|----------------|
| 5 | 01 - Ping | 01_ping.yml | все |
| 6 | 02 - System Update | 02_update.yml | все |
| 7 | 03 - Cleanup | 03_cleanup.yml | все |
| 8 | 04 - Status | 04_status.yml | все |
| 9 | 05 - Restart VPN | 05_restart_vpn.yml | только VPN |
| 10 | 06 - Disk Usage | 06_disk_usage.yml | все |

### Правила написания плейбуков
- `awk` с кавычками — экранировать: `\"`
- `docker ps --format` — обязательно `{% raw %}...{% endraw %}`
- `args: executable: /bin/bash` — если используется `declare`, `source`, `[[ ]]`
- **НЕ ставить** `stdout_callback = debug` — ломает Summary вкладку!
- `interpreter_python = auto_silent` — убирает WARNING про Python

---

## Git Clone — always use SSH, never HTTPS

```bash
clear
# CORRECT (no password prompt):
git clone git@github.com:GinCz/Linux_Server_Public.git

# WRONG (asks password every time):
# git clone https://github.com/GinCz/Linux_Server_Public.git
```

---

## СТРУКТУРА РЕПОЗИТОРИЯ

```
Linux_Server_Public/
├── 222/              ← EU Server Germany NetCup (скрипты, .bashrc, конфиги)
├── 109/              ← RU Server Russia FastVDS (скрипты, .bashrc, конфиги)
├── VPN/              ← VPN Servers AmneziaWG (скрипты, .bashrc)
├── ansible/          ← Ansible playbooks (Semaphore UI)
├── scripts/          ← Универсальные скрипты (shared_aliases.sh, amnezia_stat.sh)
└── README.md
```

> **Правило:** каждый сервер — самостоятельная папка. Скрипт используется на сервере X — он должен быть в папке X. Дублирование допустимо намеренно.

---

## СИСТЕМА АЛИАСОВ

### Как устроено

```
/root/.bashrc  ←  скопирован из репо (222/.bashrc, 109/.bashrc, VPN/.bashrc)
    └── source /root/Linux_Server_Public/scripts/shared_aliases.sh
```

- **`.bashrc`** загружается при каждом SSH-входе → алиасы всегда доступны после перезагрузки
- **`shared_aliases.sh`** — общие алиасы для ВСЕХ серверов (load, save, aw, grep, ls, 00)
- **`server/.bashrc`** — специфичные алиасы каждого сервера (infooo, domains, fight, backup и т.д.)
- **`mc`** — открывает Midnight Commander с восстановлением последней директории (wrapper)

### Применить алиасы на сервере

```bash
clear
# Разово — применить вручную (222):
cp /root/Linux_Server_Public/222/.bashrc /root/.bashrc
cp /root/Linux_Server_Public/222/mc_lastdir_wrapper.sh /root/.mc_lastdir_wrapper.sh
chmod +x /root/.mc_lastdir_wrapper.sh
source /root/.bashrc && echo OK

# Если .bashrc защищён immutable (VPN серверы):
chattr -i ~/.bashrc
cp /root/Linux_Server_Public/VPN/.bashrc /root/.bashrc
source /root/.bashrc && echo OK

# Через семафор (VPN сервер):
bash /root/Linux_Server_Public/VPN/deploy_bashrc.sh
```

### Цвета SSH терминала
| Сервер | Цвет | PS1 код |
|--------|------|---------|
| 222 DE Germany | 🟡 YELLOW | `033[01;33m` |
| 109 RU Russia | 🩷 LIGHT PINK | `e[38;5;217m` |
| VPN | 🩵 TURQUOISE | `e[38;5;87m` |

### Таблица алиасов

#### Shared — все серверы (`scripts/shared_aliases.sh`)
| Alias | Действие |
|-------|----------|
| `load` | git pull --rebase + source .bashrc |
| `save` | git add . && commit && push |
| `aw` | AmneziaWG статистика клиентов |
| `grep` | grep с подсветкой цветом |
| `ls` / `ll` / `la` / `l` | Цветной листинг |
| `00` | Очистить экран (`clear`) |
| `mc` | Midnight Commander (помнит последнюю директорию) |

#### Серверы 222 и 109
| Alias | Действие |
|-------|----------|
| `infooo` | Полный инфо + бенчмарк |
| `sos` / `sos3` / `sos24` / `sos120` | Аудит сервера 1ч / 3ч / 24ч / 5 дней |
| `domains` | Проверка статуса доменов |
| `fight` | Блокировка ботов |
| `watchdog` | PHP-FPM мониторинг CPU |
| `backup` | Бэкап (локально + удалённо на другой сервер) |
| `antivir` | ClamAV сканирование |
| `mailclean` | Очистка mail очереди |
| `cleanup` | Очистка диска (крон по субботам) |
| `aws-test` | AWS тест (только вручную) |
| `banlog` | CrowdSec последние 20 алертов |

#### VPN серверы
| Alias | Действие |
|-------|----------|
| `infooo` | Инфо VPN сервера |
| `sos` / `sos3` / `sos24` / `sos120` | Аудит VPN сервера |
| `backup` | Бэкап VPN → 222 |
| `banlog` | CrowdSec алерты (если установлен) |
| `load` / `save` | git pull / push |
| `00` | Очистить экран |

---

## СЕРВЕРЫ (актуально 2026-03-30)

### 🖥 server-222 (DE-NetCup)
- **Провайдер:** NetCup.com, Германия
- **Тариф:** VPS 1000 G12 (2026) — 8.60 €/mo
- **Железо:** 4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe
- **ОС:** Ubuntu 24 / FASTPANEL
- **Назначение:** Европейские сайты с Cloudflare
- **Docker:** `crypto-bot` (порт 5000), `semaphore` (порт 3000)
- **Timezone:** Europe/Prague
- **Бэкап:** `/BACKUP/222/` локально + копия на 109 (user vlad, SSH-ключ)

### 🖥 server-109 (RU-FastVDS)
- **Провайдер:** FastVDS.ru, Россия
- **Тариф:** VDS-KVM-NVMe-Otriv-10.0 — 13 €/mo
- **Железо:** 4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe
- **ОС:** Ubuntu 24 LTS / FASTPANEL
- **Назначение:** Русские сайты без Cloudflare (24 WordPress сайта)
- **Docker:** `amnezia-awg`
- **Timezone:** Europe/Prague
- **Бэкап:** `/BACKUP/109/` локально + копия на 222 (user vlad, SSH-ключ)

### 🔒 VPN серверы (все на AmneziaWG)

| Хост | Docker | Особенности |
|------|--------|-------------|
| vpn-alex-47 | amnezia-awg | wireguard-go ~20% RAM |
| vpn-4ton-237 | amnezia-awg | Up 3+ weeks стабильно |
| vpn-tatra-9 | amnezia-awg, uptime-kuma | мониторинг всех VPN |
| vpn-stolb-24 | amnezia-awg | + AdGuardHome |
| vpn-pilik-178 | amnezia-awg | journald требует внимания |
| vpn-ilya-176 | amnezia-awg | — |
| vpn-shahin-227 | amnezia-awg | — |
| vpn-so-38 | amnezia-awg | — |

---

## BACKUP SYSTEM (актуально 2026-03-26)

| Сервер | Локальная копия | Удалённая копия |
|--------|----------------|------------------|
| 222-EU | `/BACKUP/222/` на себе | `/BACKUP/222/` на 109 |
| 109-RU | `/BACKUP/109/` на себе | `/BACKUP/109/` на 222 |
| VPN-* | — | `/BACKUP/VPN/` на 222 |

- **Ротация:** 10 последних бэкапов, старые удаляются автоматически
- **Telegram:** только при ошибке
- **Cron 222:** `0 2 * * *` → `backup_clean.sh`, `0 3 * * *` → `docker_backup.sh`
- **Cron 109:** `0 1 * * *` → `backup_clean.sh`
- SSH-ключи (без паролей): `222→109` и `109→222` через user `vlad` ✅

---

## CRYPTO-BOT (сервер 222)

**Расположение:** `/root/crypto-docker/`  
**Docker:** контейнер `crypto-bot`, порт `5000`

```bash
alias bot   # управление: статус, логи, перезапуск
```

> ⚠️ Alias `tr` → `bot` — `tr` это стандартная утилита Linux, не переименовывать!
> ⚠️ Binance **удалён из UI** — после `--build` может вернуться, проверять `grep -i binance index.html`

---

## Установка алиасов на НОВЫЙ VPN сервер

```bash
clear
[ -d /root/Linux_Server_Public ] \
  && cd /root/Linux_Server_Public && git pull \
  || git clone git@github.com:GinCz/Linux_Server_Public.git /root/Linux_Server_Public
bash /root/Linux_Server_Public/VPN/deploy_bashrc.sh
timedatectl set-timezone Europe/Prague
```

---

## = Rooted by VladiMIR | AI =
Last updated: v2026-03-30
