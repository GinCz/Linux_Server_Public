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
9. **Команды на НЕСКОЛЬКО серверов — через SSH цикл с сервера 222** (см. раздел ниже). Не заходить на каждый сервер руками. Semaphore — для сложных плейбуков с историей и расписанием.
10. **Секреты (IP, пароли, ключи)** — только в приватном репо **Secret_Privat**. В этом репо — только маски: `xxx.xxx.xxx.222`.

---

## 🔑 МАСТЕР SSH КЛЮЧ — главный инструмент управления

Сервер **222 является главным управляющим сервером**. Его SSH ключ (`/root/.ssh/id_ed25519`) добавлен в `authorized_keys` на **всех VPN серверах** и на сервере **109**.

```
Схема управления:

Ты (терминал)
    ↓ SSH
Сервер 222 (МАСТЕР)
    ├── SSH ключ → vpn-alex-47
    ├── SSH ключ → vpn-4ton-237
    ├── SSH ключ → vpn-tatra-9
    ├── SSH ключ → vpn-shahin-227
    ├── SSH ключ → vpn-stolb-24
    ├── SSH ключ → vpn-pilik-178
    ├── SSH ключ → vpn-ilya-176
    ├── SSH ключ → vpn-so-38
    └── SSH ключ → server-109 (user: vlad, для backup)
```

**Публичный ключ 222** — сохранён в приватном репо `Secret_Privat/ssh_keys.md`.

---

## 🖥 МАССОВОЕ УПРАВЛЕНИЕ VPN СЕРВЕРАМИ (с сервера 222)

> ⚡ Когда нужно сделать что-то на всех VPN — **НЕ заходить на каждый сервер руками**.
> Одна команда с сервера 222 применяется ко всем 8 VPN серверам через SSH ключ.

### Задеплоить .bashrc на все VPN (алиас):
```bash
vpndeploy
```

### Запустить ЛЮБУЮ команду на всех VPN:
```bash
clear
for HOST in 109.234.38.47 144.124.228.237 144.124.232.9 144.124.228.227 144.124.239.24 91.84.118.178 146.103.110.176 144.124.233.38; do
  echo "=== $HOST ==="
  ssh -o StrictHostKeyChecking=no root@$HOST "КОМАНДА_ЗДЕСЬ"
done
```

### Скрипт с красивым выводом:
```bash
bash /root/Linux_Server_Public/222/vpn_deploy.sh
# (поменяй CMD внутри скрипта на нужную команду)
```

### ⚠️ Особые серверы — не удалять сервисы!

| Сервер | IP | Сервис | Назначение |
|--------|----|--------|------------|
| vpn-tatra-9 | xxx.xxx.xxx.9 | `uptime-kuma` | Мониторинг ВСЕХ VPN серверов |
| vpn-stolb-24 | xxx.xxx.xxx.24 | `AdGuard Home` | DNS фильтрация для пользователей |

### Когда использовать SSH цикл vs Semaphore:
| Задача | Инструмент |
|--------|------------|
| Быстрая команда / скрипт на всех VPN | SSH цикл с 222 (`vpndeploy`) |
| Обновление, рестарт, деплой | SSH цикл с 222 |
| Нужна история запусков | Semaphore |
| Запуск по расписанию | Semaphore |
| Красивый UI с логами | Semaphore |

---

## 🚀 SEMAPHORE

**Semaphore UI:** https://sem.gincz.com (Docker на сервере 222, порт 3000)

### Текущие шаблоны

| ID | Название | Плейбук | Группа |
|----|---------|---------|--------|
| 5 | 01 - Ping | 01_ping.yml | все |
| 6 | 02 - System Update | 02_update.yml | все |
| 7 | 03 - Cleanup | 03_cleanup.yml | все |
| 8 | 04 - Status | 04_status.yml | все |
| 9 | 05 - Restart VPN | 05_restart_vpn.yml | VPN |
| 10 | 06 - Disk Usage | 06_disk_usage.yml | все |

### Правила написания плейбуков
- `awk` с кавычками — экранировать: `\"`
- `docker ps --format` — обязательно `{% raw %}...{% endraw %}`
- `args: executable: /bin/bash` — если `declare`, `source`, `[[ ]]`
- **НЕ ставить** `stdout_callback = debug` — ломает Summary вкладку!

---

## Git Clone — always use SSH, never HTTPS

```bash
clear
# CORRECT (no password prompt):
git clone git@github.com:GinCz/Linux_Server_Public.git

# WRONG (asks password every time):
# git clone https://github.com/GinCz/Linux_Server_Public.git

# If SSH key not added to GitHub yet — temporary HTTPS pull:
git pull https://github.com/GinCz/Linux_Server_Public.git
```

---

## СТРУКТУРА РЕПОЗИТОРИЯ

```
Linux_Server_Public/
├── 222/              ← EU Server Germany NetCup (скрипты, .bashrc, vpn_deploy.sh)
├── 109/              ← RU Server Russia FastVDS (скрипты, .bashrc)
├── VPN/              ← VPN Servers AmneziaWG (скрипты, .bashrc, deploy_bashrc.sh)
├── ansible/          ← Ansible playbooks (Semaphore UI)
├── scripts/          ← Универсальные скрипты (shared_aliases.sh)
└── README.md
```

> **Правило:** каждый сервер — самостоятельная папка. Дублирование допустимо намеренно.

---

## СИСТЕМА АЛИАСОВ

### Как устроено

```
/root/.bashrc  ←  скопирован из репо (222/.bashrc, 109/.bashrc, VPN/.bashrc)
    └── source /root/Linux_Server_Public/scripts/shared_aliases.sh
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
| `ls/ll/la/l` | Цветной листинг |
| `00` | Очистить экран (`clear`) |
| `mc` | Midnight Commander (помнит последнюю директорию) |

#### Серверы 222 и 109
| Alias | Действие |
|-------|----------|
| `infooo` | Полный инфо + бенчмарк |
| `sos/sos3/sos24/sos120` | Аудит сервера 1ч/3ч/24ч/5дней |
| `domains` | Проверка статуса доменов |
| `fight` | Блокировка ботов |
| `watchdog` | PHP-FPM мониторинг CPU |
| `backup` | Бэкап локально + удалённо |
| `antivir` | ClamAV сканирование |
| `mailclean` | Очистка mail очереди |
| `cleanup` | Очистка диска |
| `banlog` | CrowdSec последние 20 алертов |
| `vpndeploy` | 🆕 Деплой на все VPN серверы сразу |

#### VPN серверы
| Alias | Действие |
|-------|----------|
| `infooo` | Инфо VPN сервера |
| `sos/sos3/sos24/sos120` | Аудит VPN сервера |
| `backup` | Бэкап VPN → 222 |
| `banlog` | CrowdSec алерты |
| `load/save` | git pull / push |
| `00` | Очистить экран |

---

## СЕРВЕРЫ (актуально 2026-03-30)

### 🖥 server-222 (DE-NetCup) — МАСТЕР
- **Провайдер:** NetCup.com, Германия
- **Тариф:** VPS 1000 G12 (2026) — 8.60 €/mo
- **Железо:** 4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe
- **ОС:** Ubuntu 24 / FASTPANEL
- **Назначение:** Европейские сайты с Cloudflare
- **Docker:** `crypto-bot` (порт 5000), `semaphore` (порт 3000)
- **Timezone:** Europe/Prague
- **SSH ключ:** `/root/.ssh/id_ed25519` — МАСТЕР КЛЮЧ (управляет всеми VPN)
- **Бэкап:** `/BACKUP/` — хранит бэкапы ВСЕХ серверов (222, 109, все VPN)

### 🖥 server-109 (RU-FastVDS)
- **Провайдер:** FastVDS.ru, Россия
- **Тариф:** VDS-KVM-NVMe-Otriv-10.0 — 13 €/mo
- **Железо:** 4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe
- **ОС:** Ubuntu 24 LTS / FASTPANEL
- **Назначение:** Русские сайты без Cloudflare (24 WordPress сайта)
- **Docker:** `amnezia-awg`
- **Timezone:** Europe/Prague
- **Бэкап:** `/BACKUP/109/` локально + копия на 222

### 🔒 VPN серверы (все на AmneziaWG)

| Хост | IP (маска) | Docker | Особенности |
|------|-----------|--------|-------------|
| vpn-alex-47 | xxx.xxx.38.47 | amnezia-awg | — |
| vpn-4ton-237 | xxx.xxx.228.237 | amnezia-awg | стабильно 3+ нед. |
| vpn-tatra-9 | xxx.xxx.232.9 | amnezia-awg | ⚠️ uptime-kuma |
| vpn-shahin-227 | xxx.xxx.228.227 | amnezia-awg | — |
| vpn-stolb-24 | xxx.xxx.239.24 | amnezia-awg | ⚠️ AdGuard Home |
| vpn-pilik-178 | xxx.xxx.118.178 | amnezia-awg | journald |
| vpn-ilya-176 | xxx.xxx.110.176 | amnezia-awg | — |
| vpn-so-38 | xxx.xxx.233.38 | amnezia-awg | — |

---

## BACKUP SYSTEM

| Сервер | Локальная копия | Удалённая копия |
|--------|----------------|------------------|
| 222-EU | `/BACKUP/222/` | `/BACKUP/222/` на 109 |
| 109-RU | `/BACKUP/109/` | `/BACKUP/109/` на 222 |
| VPN-* | — | `/BACKUP/VPN/` на 222 |

- **Ротация:** 10 последних, старые удаляются автоматически
- **Telegram:** только при ошибке
- SSH-ключи без паролей: `222→109` и `109→222` через user `vlad` ✅

---

## CRYPTO-BOT (сервер 222)

```bash
bot   # статус, логи, перезапуск
```

> ⚠️ `tr` — стандартная утилита Linux, alias называется `bot`!
> ⚠️ Binance удалён из UI — после `--build` может вернуться!

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
