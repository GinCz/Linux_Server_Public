# Linux Server Public — Scripts & Configs
GitHub: https://github.com/GinCz/Linux_Server_Public
Author: Ing. VladiМIR Bulantsev
Last updated: v2026-03-27

---

## Git Clone — always use SSH, never HTTPS

```bash
# CORRECT (no password prompt):
git clone git@github.com:GinCz/Linux_Server_Public.git

# WRONG (asks password every time):
# git clone https://github.com/GinCz/Linux_Server_Public.git
```

---

## MAIN RULE
Every script used on a specific server MUST be present in that server's own folder.
Each server folder is self-contained and fully independent.
Scripts MAY be duplicated across folders — this is intentional.

---

## COLOR SCHEME (SSH terminal)
- 222 EU Germany  : YELLOW       `PS1 033[01;33m`
- 109 RU Russia   : LIGHT PINK   `PS1 e[38;5;217m`
- VPN             : TURQUOISE    `PS1 e[38;5;87m`

---

## REPOSITORY STRUCTURE

```
Linux_Server_Public/
├── 222/         ← EU Server Germany NetCup  xxx.xxx.xxx.222
├── 109/         ← RU Server Russia FastVDS  xxx.xxx.xxx.109
├── VPN/         ← VPN Servers AmneziaWG
├── ansible/     ← Ansible playbooks (Semaphore UI)
├── scripts/     ← Universal scripts (shared across all servers)
└── README.md
```

---

## SERVERS OVERVIEW (актуально 2026-03-27)

### 🖥 222-DE-NetCup (xxx.xxx.xxx.222)
- **Провайдер:** NetCup.com, Германия
- **Тариф:** VPS 1000 G12 (2026) — 8.60 €/mo
- **Железо:** 4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe
- **ОС:** Ubuntu 24 / FASTPANEL
- **Назначение:** Европейские сайты с Cloudflare
- **Docker:** `crypto-bot` (порт 5000), `semaphore` (порт 3000)
- **Timezone:** Europe/Prague (CET/CEST)
- **Бэкап:** `/BACKUP/222/` локально + копия на 109 (user vlad, SSH-ключ)

### 🖥 109-RU-FastVDS (xxx.xxx.xxx.109)
- **Провайдер:** FastVDS.ru, Россия
- **Тариф:** VDS-KVM-NVMe-Otriv-10.0 — 13 €/mo
- **Железо:** 4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe
- **ОС:** Ubuntu 24 LTS / FASTPANEL
- **Назначение:** Русские сайты без Cloudflare (24 WordPress сайта)
- **Docker:** `amnezia-awg`
- **Timezone:** Europe/Prague (CET/CEST)
- **Бэкап:** `/BACKUP/109/` локально + копия на 222 (user vlad, SSH-ключ)

### 🔒 VPN серверы (все на AmneziaWG)

| Хост | IP | Docker | Особенности |
|------|----|--------|-------------|
| vpn-alex-47 | — | amnezia-awg | wireguard-go ~20% RAM |
| vpn-4ton-237 | — | amnezia-awg | Up 3+ weeks стабильно |
| vpn-tatra-9 | xxx.xxx.xxx.9 | amnezia-awg, uptime-kuma | мониторинг всех VPN |
| vpn-stolb-24 | — | amnezia-awg | + AdGuardHome |
| vpn-pilik-178 | — | amnezia-awg | journald требует внимания |
| vpn-ilya-176 | — | amnezia-awg | — |
| vpn-shahin-227 | — | amnezia-awg | — |
| vpn-so-38 | — | amnezia-awg | — |

> ⚠️ **wg-easy удалён с vpn-tatra-9** (2026-03-27) — был лишним, несовместим с AWG клиентами

---

## BACKUP SYSTEM (актуально 2026-03-27)

Все серверы делают бэкап через пользователя `vlad` по **SSH-ключу** (без паролей, sshpass удалён).

| Сервер | Локальная копия | Удалённая копия |
|--------|----------------|------------------|
| 222-EU | `/BACKUP/222/` на себе | `/BACKUP/222/` на 109 |
| 109-RU | `/BACKUP/109/` на себе | `/BACKUP/109/` на 222 |
| VPN-*  | — | `/BACKUP/VPN/` на 222 |

- **Ротация:** 10 последних бэкапов, старые удаляются автоматически
- **Telegram:** только при ошибке (при успехе — тишина)
- **Cron 222:** `0 2 * * *` → `backup_clean.sh`, `0 3 * * *` → `docker_backup.sh`
- **Cron 109:** `0 1 * * *` → `backup_clean.sh`
- **Архив включает:** `/etc` + `/root` + `/usr/local/fastpanel2`
- **Архив исключает:** `.git`, кэш, `node_modules`, VSCode-server, `www/data`

### SSH-ключи (настроены 2026-03-26)
```
222 → 109: root@222 → /home/vlad/.ssh/authorized_keys на 109  ✅
109 → 222: root@109 → /home/vlad/.ssh/authorized_keys на 222  ✅
```

---

## ANSIBLE / SEMAPHORE (новое 2026-03-27)

**Semaphore UI:** https://sem.gincz.com (Docker на сервере 222, порт 3000)

### ansible/ — плейбуки

| Файл | Шаблон в Semaphore | Описание |
|------|-------------------|----------|
| `ansible.cfg` | — | Глобальная конфигурация: `interpreter_python=auto_silent`, `pipelining=true` |
| `ping.yml` | Ping All Servers | Проверка доступности всех серверов |
| `server_info.yml` | Server Info Report | Полный отчёт: OS, RAM, CPU, диск, Docker, топ процессы |
| `cleanup_vpn.yml` | Cleanup VPN Servers | Очистка APT, journal, tmp, Docker — только VPN серверы |
| `update_servers.yml` | Update All Servers | apt update + upgrade на всех серверах |
| `docker_status.yml` | Docker Status | Статус Docker контейнеров на всех серверах |
| `set_timezone.yml` | Set Timezone Prague | Установка Europe/Prague на всех серверах |

### ansible.cfg — важные настройки
```ini
[defaults]
interpreter_python = auto_silent   # убирает WARNING про Python версию
nocows = 1                          # без cowsay
display_skipped_hosts = false       # не показывать skipped

[ssh_connection]
pipelining = true                   # быстрее SSH
```

> ⚠️ **НЕ ставить** `stdout_callback = debug` — ломает Summary вкладку в Semaphore!

### Известные особенности YAML/Ansible
- Команды с `awk` и внутренними кавычками — экранировать: `\"` внутри `"..."`
- `docker ps --format` — обязательно оборачивать в `{% raw %}...{% endraw %}`
- PLAY RECAP в конце лога **убрать невозможно** — это встроено в Ansible
- Summary вкладка в Semaphore показывает только OK/NOT OK счётчик, не текст debug

### Создать шаблон в Semaphore через API
```bash
TOKEN="твой_токен"
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

---

## TIMEZONE (2026-03-27)

На **всех серверах** установлена `Europe/Prague` (CET +0100 / CEST +0200).
Формат времени: 24-часовой (стандарт Ubuntu).

```bash
# Проверить:
timedatectl show --property=Timezone --value
date '+%d.%m.%Y %H:%M:%S'

# Установить вручную:
timedatectl set-timezone Europe/Prague
```

---

## Aliases Quick Reference

### Shared (all servers) — из scripts/shared_aliases.sh

| Alias | Описание |
|-------|----------|
| `load` | `git pull --rebase` + `source .bashrc` |
| `save` | `git add . && commit && push` |
| `aw` | AmneziaWG статистика клиентов |
| `00` | Очистить экран |
| `la` | `ls -A` (показать скрытые) |
| `l` | `ls -CF` (компактный список) |

### Сервера 222 и 109

| Alias | Описание |
|-------|----------|
| `sos` / `sos3` / `sos24` / `sos120` | Аудит сервера 1ч / 3ч / 24ч / 5 дней |
| `infooo` | Полный инфо + бенчмарк |
| `backup` | Бэкап (локально + удалённо) |
| `bot` | Управление crypto-bot (**НЕ** `tr` — это стандартная утилита Linux!) |
| `antivir` | ClamAV сканирование |
| `cleanup` | Очистка диска |
| `wphealth` | WordPress health check |
| `banlog` | CrowdSec последние 20 алертов |
| `domains` | Проверка статуса доменов |

### VPN серверы

| Alias | Описание |
|-------|----------|
| `aw` | AmneziaWG статистика |
| `audit` | VPN нагрузка + мониторинг атак |
| `infooo` | Инфо VPN сервера |
| `backup` | Бэкап VPN → 222 |
| `load` / `save` | git pull / push |
| `00` | Очистить экран |

---

## Установка aliases на НОВЫЙ VPN сервер

```bash
clear
[ -d /root/Linux_Server_Public ] \
  && cd /root/Linux_Server_Public && git pull \
  || cd /root && git clone https://github.com/GinCz/Linux_Server_Public.git && cd Linux_Server_Public
bash VPN/01_vpn_alliances_v1.0.sh
```

После установки — установить timezone:
```bash
timedatectl set-timezone Europe/Prague
```

---

## CRYPTO-BOT (сервер 222)

**Расположение:** `/root/crypto-docker/`
**Docker:** контейнер `crypto-bot`, порт `5000`
**Режим:** paper-trading (OKX или MEXC)

### Управление
```bash
alias bot   # показать статус, логи, перезапустить
cd /root/crypto-docker
docker compose logs -f crypto-bot
```

### config.json — ключевые параметры
```json
{
  "exchange": "okx",          // или "mexc"
  "drop_from_entry": 1.0,     // выход если цена упала >1% от входа
  "tg_alerts_enabled": false  // BEAR/BULL алерты отключены
}
```

### Биржи
- `okx` → ключи: `okx_api_key`, `okx_api_secret`, `okx_passphrase`
- `mexc` → ключи: `api_key`, `api_secret`
- Binance — **удалён из UI** (убран из index.html)

> ⚠️ Alias `tr` переименован в `bot` — `tr` это стандартная утилита Linux!

---

## = Rooted by VladiMIR | AI =
Last updated: v2026-03-27
