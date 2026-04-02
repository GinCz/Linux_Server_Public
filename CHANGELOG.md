# CHANGELOG
*= Rooted by VladiMIR | AI =*

---

## v2026-04-02 — all_servers_info, MOTD fix, aws_test, Cursor AI

### 🖥 all_servers_info.sh — new script (222 and 109)
- ✅ New script: `222/all_servers_info.sh` and `109/all_servers_info.sh`
- ✅ Shows RAM and Disk for ALL 10 servers in one colored table
- ✅ Columns: SERVER | IP | RAM | DISK with status indicators
- ✅ Status indicators: `◆ OK` (green <80%) / `◆ WARN` (yellow 80-89%) / `◆ CRIT` (red ≥90%)
- ✅ Format: total size + (% used) for both RAM and Disk
- ✅ Local server (222 or 109) runs directly, remote via SSH master key
- ✅ Alias: `allinfo` added to `.bashrc` on both 222 and 109
- ✅ Added to MOTD banner on both servers (replacing `dbackup`, `sos3/24/120`)

### 🛠 HOW-TO-UPDATE-MOTD.md — deployment instructions
- ✅ Created `222/HOW-TO-UPDATE-MOTD.md` and `109/HOW-TO-UPDATE-MOTD.md`
- ✅ Documents the 3-layer architecture of MOTD system
- ✅ **Key lesson:** `git pull` alone does NOT update the live MOTD.
  The live file `/etc/profile.d/motd_server.sh` must be copied manually every time.
- ✅ Correct one-liner for 222:
  ```bash
  cd && load && cp -f /root/Linux_Server_Public/222/motd_server.sh /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh && bash /etc/profile.d/motd_server.sh
  ```
- ✅ Same for 109 (replace `222` with `109`)
- ✅ Documents danger of old duplicate aliases at bottom of `/root/.bashrc`

### 🧹 .bashrc cleanup (222)
- ❌ Removed: `sos3`, `sos24`, `sos120` (redundant)
- ❌ Removed: `i` (too short, replaced by `infooo`)
- ❌ Removed: `dbackup` (replaced by `f5bot`)
- ✅ Added: `allinfo` alias
- ⚠️ Old aliases block `# WP Tools v2026-04-01` at bottom of `/root/.bashrc`
  was overriding correct ones. Removed with:
  ```bash
  sed -i '/^# WP Tools/,$ d' /root/.bashrc
  ```

### ✨ aws_test.sh — redesign
- ✅ Full latency test to all 13 AWS regions (ping 4 packets, 1450 bytes)
- ✅ Results sorted by latency (best first)
- ✅ Color coding: green (<50ms) / cyan (50-149ms) / gray (>=150ms or timeout)
- ✅ Header style: cyan `═══` lines (was yellow `+++ ===`)
- ✅ Consistent with project color scheme

### 🤖 Cursor AI — SSH + GitHub access configured
- ✅ Cursor connected to server 222 via Remote SSH
- ✅ Cursor has access to GitHub repository via SSH key
- ✅ Files added: `cursor/SSH-Cursor-Setup.md`, `cursor/authorized_keys.md`
- ✅ Cursor key added to `authorized_keys` on server 222
- ⚠️ Cursor commits with author `VladiMIR Bulantsev <gin@volny.cz>` — same as main
- ⚠️ Cursor can edit files directly on server and push to GitHub
- ⚠️ Always review Cursor commits before trusting them

### 📄 MOTD banners updated (222 and 109)
| Was | Now |
|-----|-----|
| `sos3/24/120` | removed |
| `dbackup` | removed |
| `i(full info)` | `infooo(full info)` |
| `f5bot/dbackup` | `f5bot(docker backup)` |
| `torg/torg3/24/120` | removed |
| *(new)* | `allinfo(all servers)` |
| *(new)* | `watchdog(PHP-FPM)` |
| *(new)* | `clog100(last 100 logs)` |

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
- ❌ Убраны дубли: `banlog`, `m='mc'`

#### `222/.bashrc` и `109/.bashrc`
- ❌ Убран `alias i=` (слишком короткий)
- ✅ Добавлен `alias infooo=`
- ❌ Убраны `wpcron`, `cronwp`
- ❌ Убран `wphealth`

### 🔧 Проблемы при применении

#### 222 — git pull не работал (SSH ключ)
```bash
git@github.com: Permission denied (publickey)
```
Решение: добавить ключ на https://github.com/settings/keys

#### VPN-4Ton-237, VPN-Tatra-9 — immutable .bashrc
```bash
chattr -i ~/.bashrc
cp /root/Linux_Server_Public/VPN/.bashrc /root/.bashrc
source /root/.bashrc
```

---

## v2026-03-30 — Security: Git history cleanup, IP masking

### 🔒 Очистка истории Git от реальных IP

```bash
clear
apt install git-filter-repo -y
cd /tmp && git clone git@github.com:GinCz/Linux_Server_Public.git Linux_Server_Public_clean
cd Linux_Server_Public_clean
git filter-repo --replace-text /tmp/replacements.txt --force
git remote add origin git@github.com:GinCz/Linux_Server_Public.git
git push --force --all && git push --force --tags
```

---

## v2026-03-29 — Semaphore: 04_status.yml БИТВА (7 попыток!)

| # | Ошибка | Причина | Решение |
|---|--------|---------|--------|
| 1 | `rc:1` docker PATH | Ansible запускает sh без PATH | `which docker` |
| 2 | `declare -A` | Ansible /bin/sh | `case` + `executable: /bin/bash` |
| 3 | Jinja2 `{{ }}` | `docker ps --format` | `{% raw %}...{% endraw %}` |
| 4 | `rc:1` wg-easy | образ удалён | проверять наличие перед inspect |
| 5 | `$2/$5` буквально | YAML `\|` | заменить `\|` на `>` |
| 6 | `0 MB0 MB` двойной | echo + awk | `[ -n "$RAW" ]` |
| 7 | остановленные | `docker ps -a` | убрать `-a` |

---

## v2026-03-28 — Semaphore установка, Crypto-Bot фиксы

- Semaphore: пароль admin через `docker run`, WebSocket обязателен
- wp-login rate limit: `10r/m burst=5` → `6r/m burst=3`

---

## v2026-03-27 — Ansible/Semaphore, Timezone, wg-easy удалён

- Timezone Europe/Prague — все 10 серверов ✅
- wg-easy удалён с vpn-tatra-9: несовместим с AWG

---

## v2026-03-26 — Backup+Clean, SSH-ключи, Crypto-Bot

- backup_clean.sh: 196MB → 1.4MB архив
- `tr` → `bot` (потом обратно в `tr` через `bot`)
- `[ -z "$PS1" ] && return` — закомментирован (блокировал aliases)

---

## v2026-03-25 — RAM Crisis Fix
- 222: RAM 6.8GB/7.7GB → 2.6GB
- PHP-FPM: 40 пулов переключены в `ondemand`

---

## v2026-03-24 — Major Refactor
- Полный рефакторинг репозитория
- Цветовая система: 222=жёлтый, 109=розовый, VPN=бирюзовый

---

_Last updated: 2026-04-02 by Ing. VladiMIR Bulantsev_
