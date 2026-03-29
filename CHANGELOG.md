# CHANGELOG
*= Rooted by VladiMIR | AI =*

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

# Файл замен
cat > /tmp/replacements.txt << 'EOF'
<реальный IP 222>==>xxx.xxx.xxx.222
<реальный IP 109>==>xxx.xxx.xxx.109
... (все IP серверов)
<пароль>==>***REMOVED***
EOF

# Перезапись истории
git filter-repo --replace-text /tmp/replacements.txt --force

# Force push
git remote add origin git@github.com:GinCz/Linux_Server_Public.git
git push --force --all
git push --force --tags

# Обновить оба сервера (на 222 и 109):
cd /root/Linux_Server_Public
git fetch --all && git reset --hard origin/main
```

> ⚠️ Имя файла `caught_by_212.109.223.109.txt` содержит IP атакующего в названии — это безопасно, не наш IP.

---

## v2026-03-29 — Semaphore: 04_status.yml БИТВА (7 попыток!), новые плейбуки

### 🔥 История `04_status.yml` — почему мы потратили 3 дня

Этот плейбук потребовал 7 исправлений. Каждая ошибка описана ниже:

#### Ошибка 1: `rc:1` — docker PATH не найден в Ansible
**Причина:** Ansible запускает shell без PATH пользователя, `docker` не находится.
```yaml
# Решение: искать docker самостоятельно
- name: Find docker path
  ansible.builtin.shell: which docker || echo /usr/bin/docker
  register: docker_path
```

#### Ошибка 2: `declare -A` не работает в Ansible shell
**Причина:** Ansible запускает shell через `/bin/sh`, а не bash — `declare -A` (ассоц. массив) не поддерживается.
```yaml
# Решение: использовать case вместо declare -A
# + указывать executable: /bin/bash в args
  args:
    executable: /bin/bash
```

#### Ошибка 3: Jinja2 конфликт с `{{ }}` в shell
**Причина:** `docker ps --format "{{ .Names }}"` — Jinja2 пытается обработать `{{}}` и падает.
```yaml
# Решение: обернуть в {% raw %}...{% endraw %}
  ansible.builtin.shell: >
    {% raw %}docker ps --format "{{.Names}} {{.Status}}"{% endraw %}
  args:
    executable: /bin/bash
```

#### Ошибка 4: `rc:1` на VPN — `docker image inspect wg-easy` не нашлён
**Причина:** wg-easy был удалён, но плейбук всё равно пытался получить его размер — `inspect` возвращал `rc:1`.
```bash
# Решение: проверять наличие образа перед inspect
RAW=$(docker image inspect "$IMAGE" --format '{{.Size}}' 2>/dev/null)
if [ -n "$RAW" ] && [ "$RAW" -gt 0 ] 2>/dev/null; then
  SIZE=$(echo "$RAW" | awk '{printf "%.0f MB", $1/1024/1024}')
else
  SIZE="n/a"
fi
```

#### Ошибка 5: `Disk: 5.0G/"$2" ("$5" used)` — сломанный awk
**Причина:** YAML блок `|` передаёт строку буквально, включая `\"` — awk получает литеральные `"$2"`.
```yaml
# НЕПРАВИЛЬНО — YAML | (literal):
  shell: df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}'

# ПРАВИЛЬНО — YAML > (folded):
  shell: >
    df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}'
  args:
    executable: /bin/bash
```

#### Ошибка 6: `0 MB0 MB` — двойной вывод размера
**Причина:** `$(docker inspect ... || echo 0)` — если образ пустой — `echo 0` даёт `0`, awk делает `0 MB`, плюс сам `0` — выходит `0 MB0 MB`.
```bash
# Решение: явная проверка
RAW=$(docker image inspect "$IMAGE" --format '{{.Size}}' 2>/dev/null)
if [ -n "$RAW" ] && [ "$RAW" -gt 0 ] 2>/dev/null; then
  SIZE=$(echo "$RAW" | awk '{printf "%.0f MB", $1/1024/1024}')
else
  SIZE="n/a"
fi
```

#### Ошибка 7: `docker ps -a` показывал остановленные контейнеры
**Причина:** остановленные контейнеры попадали в список, для них `image inspect` — `rc:1`.
```bash
# Решение: убрать -a, показывать только запущенные
docker ps  # без -a!
```

---

### 🎕 Новые плейбуки (2026-03-29)

#### `05_restart_vpn.yml` — перезапуск amnezia-awg
**Проблема:** первая версия запускалась только на VPN серверах, хотя hosts=all_servers.  
**Решение:** добавить `when: ansible_host != "xxx.xxx.xxx.222"` и проверку наличия amnezia-awg.

#### `06_disk_usage.yml` — отчёт по диску
Показывает использование диска на всех 10 серверах.

---

### 📋 Статус шаблонов Semaphore (итог)

| ID | Название | Плейбук | Статус |
|----|---------|---------|--------|
| 5 | 01 - Ping | 222/semaphore/playbooks/01_ping.yml | ✅ |
| 6 | 02 - System Update | .../02_update.yml | ✅ |
| 7 | 03 - Cleanup | .../03_cleanup.yml | ✅ |
| 8 | 04 - Status | .../04_status.yml | ✅ |
| 9 | 05 - Restart VPN | .../05_restart_vpn.yml | ✅ |
| 10 | 06 - Disk Usage | .../06_disk_usage.yml | ✅ |

> ⚠️ Помни: Template ID 1-4 были дубликатами — удалены через API DELETE.

---

## v2026-03-28 — Semaphore установка, Crypto-Bot фиксы, wphealth

### 🔧 Semaphore настройка с нуля

**3 дня потрачено** на настройку. Подробнее все проблемы: `222/semaphore/TROUBLESHOOTING.md`

**Ключевые уроки:**
- Пароль `admin` может не работать при BoltDB — создавать пользователя через `docker run`
- Кнопка "New Template" в UI багует (bug) — использовать REST API
- Поле `"app":"ansible"` обязательно в API запросе
- `docker-compose-plugin` не установлен — пришлось добавить вручную
- FASTPANEL перезаписывает nginx конфиг — SSL и proxy_pass прописывать вручную
- WebSocket (`Upgrade`, `Connection`) обязательны для Semaphore UI

### 🤖 Crypto-Bot — удаление Binance из UI

См. подробности ниже в `v2026-03-26`.

### 📄 wphealth.sh (109) — добавлены проверки

- `FS_METHOD` в `wp-config.php` (должно быть `direct`)
- `WP_AUTO_UPDATE_CORE` (должно быть `false`)

### 🔒 wp-login rate limit ужесточен

- Было: `10r/m burst=5`
- Стало: `6r/m burst=3`
- На обоих серверах (222 и 109)

---

## v2026-03-27 — Ansible/Semaphore, Timezone, wg-easy удалён

### 🗺 Timezone Europe/Prague на всех 10 серверах

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
| vpn-shahin-227 | Europe/Prague (CET, +0100) | ✅ |
| vpn-so-38 | Europe/Prague (CET, +0100) | ✅ |

### 🗑 wg-easy удалён с vpn-tatra-9

**Причина:** несовместим с AWG, дублирует функцию, был забыт.

```bash
clear
ssh root@xxx.xxx.xxx.9 "docker stop wg-easy && docker rm wg-easy"
```

### 📋 Ansible playbooks — известные проблемы YAML

| Проблема | Статус | Решение |
|----------|--------|--------|
| `awk` кавычки YAML error | ✅ | экранировать `\"` |
| `docker format` Jinja2 | ✅ | `{% raw %}...{% endraw %}` |
| `stdout_callback=debug` | ✅ удалён | Ломает Summary вкладку Semaphore |
| WARNING Python interpreter | ✅ | `interpreter_python=auto_silent` |
| `requirements.yml not found` | неубираемо | Semaphore проверяет перед каждым запуском |
| PLAY RECAP в логе | неубираемо | Встроено в Ansible |
| Samba двойной статус | ✅ | `head -1 | awk '{print $1}'` |

---

## v2026-03-26 (вечер) — Backup+Clean, SSH-ключи, Crypto-Bot фиксы

### 🤖 Crypto-Bot — исправления

#### Динамическая биржа (`paper_trade.py`)
Функция `_make_exchange(cfg)` читает `config.json['exchange']`:
- `"okx"` → OKX (ключи — в репо Secret!)
- `"mexc"` → MEXC (ключи — в репо Secret!)

#### Новое условие ENTRY-DROP
```json
{
  "exchange": "okx",
  "drop_from_entry": 1.0,
  "tg_alerts_enabled": false
}
```

#### Удаление кнопки Binance из UI (делали 3 раза!)
```bash
clear
sed -i "/<button onclick=\"setExchange('binance')/d" /root/crypto-docker/templates/index.html
sed -i "s/\['okx','mexc','binance'\]/['okx','mexc']/g" /root/crypto-docker/templates/index.html
grep -i binance /root/crypto-docker/templates/index.html && echo "ЕЩЁ ЕСТЬ!" || echo "ЧИСТО ✅"
```

> ⚠️ После `--build` кнопка возвращается! Сначала `sed`, потом `--build`.

### 🔒 SSH-ключи между серверами

```bash
clear
# На 109: добавить публичный ключ 222 в authorized_keys vlad
mkdir -p /home/vlad/.ssh && chmod 700 /home/vlad/.ssh
echo "<пуб. ключ root@server-222>" >> /home/vlad/.ssh/authorized_keys
chmod 600 /home/vlad/.ssh/authorized_keys && chown -R vlad:vlad /home/vlad/.ssh

# На 109 → 222:
ssh-copy-id -i ~/.ssh/id_rsa.pub vlad@xxx.xxx.xxx.222
```

### 📦 backup_clean.sh (новый скрипт)

```
[1/6] Cleaning old files
[2/6] Pre-cleanup old backups (храним 10 последних)
[3/6] Creating archive
[4/6] Saving locally
[5/6] Sending copy to remote (SSH-ключ vlad)
[6/6] Telegram (только при ошибке)
```

| Сервер | Размер архива | До оптимизации |
|--------|-------------|----------------|
| 222 | ~1.4 MB | 196 MB |
| 109 | ~2.5 MB | 97 MB |

---

## v2026-03-26 (ночь) — BACKUP Restructure + SSH Keys

- `/BackUP/` → `/BACKUP/` на обоих серверах
- `docker_backup.sh` перенесён в `/root/`
- `sshpass` удалён, заменён SSH-ключами (sshpass хранил пароль в шелл скрипте!)

---

## v2026-03-25/26 — Crypto-Bot Docker Migration

- Миграция `/root/aws-setup/` → `/root/crypto-docker/`
- Alias `tr` → `bot` (`tr` — стандартная утилита Linux, не переименовывать!)
- `[ -z "$PS1" ] && return` — закомментирован в `.bashrc` (блокировал aliases)
- Binance удалён из UI
- Не использовать `docker compose` (без дефиса) — buildx не установлен, только `docker-compose`

---

## v2026-03-25 — RAM Crisis Fix + PHP-FPM ondemand

- Сервер 222: RAM 6.8GB/7.7GB → 2.6GB после переключения 40 PHP-FPM пулов в `ondemand`

---

## v2026-03-24 — Major Refactor + Telegram Alerts + SSH Banner

- Полный рефакторингрепозитория
- Цветовая система терминала (222=жёлтый, 109=розовый, VPN=бирюзовый)
- Универсальный SSH баннер
- Telegram мониторинг с защитой от SSH атак

---

_Last updated: 2026-03-30 by VladiMIR Bulantsev_
