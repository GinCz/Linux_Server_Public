# CHANGELOG
*= Rooted by VladiMIR | AI =*

---

## v2026-04-01 — SSH Banner + Aliases Cleanup (222 и 109)

### 🖥 motd_server.sh — новый SSH banner (оба сервера)
- ✅ Цветовая схема: голубые рамки `════`, светло-зелёный/светло-жёлтый текст
- ✅ Динамический RAM, CPU (корректная формула через `/proc/stat`, без >100%)
- ✅ Убран двойной `up up` в uptime (`sed 's/^up //'`)
- ✅ `222`: отдельный файл с IP `152.53.182.222` + блок CRYPTO-BOT
- ✅ `109`: отдельный файл с IP `212.109.223.109` + без CRYPTO-BOT блока
- Файл: `/etc/profile.d/motd_server.sh` на обоих серверах

### 📋 Aliases — .bashrc (оба сервера)
- ❌ Удалены: `audit`, `wphealth`, `antivir-status`, `bot`, `m`, `303`
- ✅ Восстановлены/добавлены: `cleanup`, `aws-test`, `f5bot`, `f9bot`, `tr`, `antivir`
- ✅ Добавлен новый: `wpupd='bash /root/wp_update_all.sh'`

### 📋 mc.menu — 222
- ✅ Пункт `o`: переименован `Quick Report (bot)` → `Quick Report (tr)`
- ✅ Добавлен пункт `w`: `WP Update (wpupd)`
- ✅ Пункт `W`: `WP Cron (wpcron)` сохранён

---

## v2026-03-30 — Aliases Refactor (все серверы)

### 📋 Что изменено

Полный рефакторинг системы алиасов на всех серверах (222, 109, VPN).

#### `scripts/shared_aliases.sh` — общий файл
- ✅ Добавлен `ll='ls -lh'`
- ✅ Добавлен `-h` флаг к `ls` (human-readable размеры)
- ✅ `mc` → wrapper с восстановлением последней директории
- ❌ Убраны дубли: `banlog`, `m='mc'` (каждый сервер имел своё)

#### `222/.bashrc` и `109/.bashrc`
- ❌ Убран `alias i=` (слишком короткий, путаница)
- ✅ Добавлен `alias infooo=` (унифицировано с VPN)
- ❌ Убран `alias d=` (слишком короткий)
- ✅ Добавлен `alias domains=` (читаемо)
- ❌ Убраны `wpcron`, `cronwp` — не работали, заменены на `sos`
- ❌ Убран `wphealth` — скрипт удалён, показывал `+` вместо `=` на 109
- ❌ Убран `alias m=` из shared (каждый сервер имеет свою логику mc)

#### `VPN/.bashrc`
- ❌ Убран `alias fight` — на VPN нет nginx/сайтов, смысла нет
- ❌ Убран `alias m=` — заменён на wrapper
- ✅ `mc` → wrapper (восстановление директории)

### 🔧 Проблемы при применении

#### 222 — git pull не работал (SSH ключ)
```
git@github.com: Permission denied (publickey)
```
Причина: публичный ключ `id_rsa.pub` сервера 222 не добавлен в GitHub.
Решение: добавить ключ на https://github.com/settings/keys

#### VPN-4Ton-237, VPN-Tatra-9 — immutable .bashrc
```
cp: cannot create regular file '/root/.bashrc': Operation not permitted
```
Причина: `chattr +i /root/.bashrc` — флаг защиты от записи.
Решение:
```bash
clear
chattr -i ~/.bashrc
cp /root/Linux_Server_Public/VPN/.bashrc /root/.bashrc
source /root/.bashrc && echo OK
```

### 🛠 Новые скрипты

#### `VPN/deploy_bashrc.sh` (v2026-03-30)
Одна команда деплоя `.bashrc` + mc_wrapper на VPN сервер:
- Делает `git pull --rebase`
- Снимает `chattr -i` если установлен
- Копирует `.bashrc` и `mc_lastdir_wrapper.sh`
- Делает `source`

```bash
clear
bash /root/Linux_Server_Public/VPN/deploy_bashrc.sh
```

> ⚠️ **Семафор:** для массового применения на всех VPN — создать плейбук Ansible
> с задачей `bash /root/Linux_Server_Public/VPN/deploy_bashrc.sh` и запустить из sem.gincz.com.

#### `222/mc_lastdir_wrapper.sh` (v2026-03-26)
Midnight Commander с памятью последней директории:
- Запускает `mc -P ~/.cache/mc/lastdir`
- После выхода — `cd` в ту папку в текущем шелле
- Алиас `mc` → ссылается на этот wrapper на ВСЕХ серверах

### 📊 Итоговая таблица алиасов (v2026-04-01)

| Alias | 222 | 109 | VPN | Источник |
|-------|-----|-----|-----|----------|
| `load` | ✅ | ✅ | ✅ | shared |
| `save` | ✅ | ✅ | ✅ | shared |
| `aw` | ✅ | ✅ | ✅ | shared |
| `grep` | ✅ | ✅ | ✅ | shared |
| `ls/ll/la/l` | ✅ | ✅ | ✅ | shared |
| `mc` (wrapper) | ✅ | ✅ | ✅ | shared |
| `00` | ✅ | ✅ | ✅ | shared |
| `infooo` | ✅ | ✅ | ✅ | server |
| `sos/sos3/sos24/sos120` | ✅ | ✅ | ✅ | server |
| `domains` | ✅ | ✅ | — | server |
| `fight` | ✅ | ✅ | ❌ | server |
| `backup` | ✅ | ✅ | ✅ | server |
| `antivir` | ✅ | ✅ | — | server |
| `mailclean` | ✅ | ✅ | — | server |
| `cleanup` | ✅ | ✅ | — | server |
| `aws-test` | ✅ | ✅ | — | server |
| `banlog` | ✅ | ✅ | ✅ | server |
| `wpupd` | ✅ | ✅ | — | server |
| `f5bot` | ✅ | ✅ | — | server |
| `f9bot` | ✅ | ✅ | — | server |
| `tr` | ✅ | — | — | 222 only |
| `clog/torg*/reset` | ✅ | — | — | 222 only |

---

## v2026-03-30 — Security: Git history cleanup, IP masking

### 🔒 Очистка истории Git от реальных IP

**Проблема:** в публичном репозитории в старых коммитах оставались реальные IP и пароли.

**Решение:** `git filter-repo` — переписал всю историю (245 коммитов).

```bash
clear
# Установка
apt install git-filter-repo -y

# Свежая копия репо
cd /tmp && rm -rf Linux_Server_Public_clean
git clone git@github.com:GinCz/Linux_Server_Public.git Linux_Server_Public_clean
cd Linux_Server_Public_clean

# Файл замен (пример)
cat > /tmp/replacements.txt << 'EOF'
<реальный IP>==>xxx.xxx.xxx.222
EOF

# Перезапись истории
git filter-repo --replace-text /tmp/replacements.txt --force

# Force push
git remote add origin git@github.com:GinCz/Linux_Server_Public.git
git push --force --all && git push --force --tags

# Обновить серверы после force push
cd /root/Linux_Server_Public
git fetch --all && git reset --hard origin/main
```

---

## v2026-03-29 — Semaphore: 04_status.yml БИТВА (7 попыток!)

### 🔥 История `04_status.yml`

| # | Ошибка | Причина | Решение |
|---|--------|---------|--------|
| 1 | `rc:1` docker PATH | Ansible запускает sh без PATH | `which docker \|\| echo /usr/bin/docker` |
| 2 | `declare -A` не работает | Ansible использует `/bin/sh` | `case` вместо `declare -A` + `executable: /bin/bash` |
| 3 | Jinja2 конфликт `{{ }}` | `docker ps --format "{{.Names}}"` | `{% raw %}...{% endraw %}` |
| 4 | `rc:1` wg-easy inspect | образ удалён, inspect падает | проверять наличие образа перед inspect |
| 5 | `$2` / `$5` буквально | YAML `\|` передаёт литерально | заменить `\|` на `>` (folded) |
| 6 | `0 MB0 MB` двойной вывод | `echo 0` + awk = двойной результат | явная проверка `[ -n "$RAW" ]` |
| 7 | остановленные контейнеры | `docker ps -a` включает stopped | убрать `-a` |

---

## v2026-03-28 — Semaphore установка, Crypto-Bot фиксы

### 🔧 Semaphore — ключевые уроки
- Пароль `admin` при BoltDB — создавать через `docker run` команду
- Кнопка "New Template" в UI багует — использовать REST API
- Поле `"app":"ansible"` обязательно в API запросе
- FASTPANEL перезаписывает nginx — SSL и proxy_pass прописывать вручную
- WebSocket (`Upgrade`, `Connection`) обязательны для Semaphore UI

### 🔒 wp-login rate limit ужесточен (222 и 109)
- Было: `10r/m burst=5` → Стало: `6r/m burst=3`

---

## v2026-03-27 — Ansible/Semaphore, Timezone, wg-easy удалён

### 🗺 Timezone Europe/Prague — все 10 серверов ✅

### 🗑 wg-easy удалён с vpn-tatra-9
Несовместим с AWG клиентами, дублировал функцию.

---

## v2026-03-26 — Backup+Clean, SSH-ключи, Crypto-Bot

### 📦 backup_clean.sh
| Сервер | До оптимизации | Размер архива |
|--------|----------------|---------------|
| 222 | 196 MB | ~1.4 MB |
| 109 | 97 MB | ~2.5 MB |

### 🔒 SSH-ключи (без паролей, sshpass удалён)
```
222 → 109 (user vlad) ✅
109 → 222 (user vlad) ✅
```

### 🤖 Crypto-Bot исправления
- `tr` → `bot` (`tr` стандартная утилита Linux!)
- Binance удалён из UI (`sed` до `--build`!)
- `[ -z "$PS1" ] && return` — закомментирован (блокировал aliases)
- Только `docker-compose` с дефисом (buildx не установлен)

---

## v2026-03-25 — RAM Crisis Fix
- Сервер 222: RAM 6.8GB/7.7GB → 2.6GB
- PHP-FPM: 40 пулов переключены в `ondemand`

---

## v2026-03-24 — Major Refactor
- Полный рефакторинг репозитория
- Цветовая система: 222=жёлтый, 109=розовый, VPN=бирюзовый
- Универсальный SSH баннер
- Telegram мониторинг

---

_Last updated: 2026-04-01 by Ing. VladiMIR Bulantsev_
