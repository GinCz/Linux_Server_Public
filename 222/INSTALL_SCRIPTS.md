# 🔧 Установка скриптов — Persistent после перезагрузки

> **Server:** 222-DE-NetCup | IP: 152.53.182.222  
> **= Rooted by VladiMIR | AI = | v2026-04-10**

Все скрипты хранятся в репозитории `/root/Linux_Server_Public/222/`.  
Чтобы они **не слетали после перезагрузки** — скрипты копируются в `/usr/local/bin/`  
и алиасы прописываются в `/root/.bashrc`.

---

## 📌 Принцип работы

```
 GitHub Repo
    ↓  git pull
 /root/Linux_Server_Public/222/  ← «исходники» (версионированы)
    ↓  cp + chmod
 /usr/local/bin/                 ← «исполняемые» (в PATH, не слетают)
    ↓  alias в .bashrc
 alias status='...'              ← «удобный вызов» (применяется при login)
```

---

## 🚀 Установить ВСЕ основные скрипты одной командой

```bash
clear

# ---- Подтягиваем свежую версию из репо ----
cd /root/Linux_Server_Public && git pull --rebase

# ---- Копируем скрипты в /usr/local/bin ----
for SCRIPT in \
  server_status.sh \
  infooo.sh \
  php_fpm_watchdog.sh \
  block_bots.sh \
  banlog.sh \
  domains.sh \
  all_servers_info.sh \
  mailclean.sh \
  server_cleanup.sh \
  quick_status.sh
do
  SRC="/root/Linux_Server_Public/222/${SCRIPT}"
  DST="/usr/local/bin/${SCRIPT}"
  if [ -f "$SRC" ]; then
    cp "$SRC" "$DST"
    chmod +x "$DST"
    echo "✓ Installed: $DST"
  else
    echo "✗ Not found: $SRC"
  fi
done

echo ""
echo "✅ All scripts installed to /usr/local/bin"
echo "   Now add aliases to .bashrc if not already there."
```

---

## 📝 Алиасы в .bashrc (уже прописаны)

Алиасы уже есть в `/root/.bashrc`. После `git pull` + обновления скриптов —  
достаточно выполнить:

```bash
source /root/.bashrc
```

Если нужно добавить новый алиас `status`:

```bash
# Проверить — есть ли уже
grep 'status' /root/.bashrc

# Если нет — добавить
echo "alias status='bash /usr/local/bin/server_status.sh'" >> /root/.bashrc
source /root/.bashrc
```

---

## 🔄 Как обновить скрипт после правок в репозитории

```bash
# 1. Подтянуть изменения
cd /root/Linux_Server_Public && git pull --rebase

# 2. Перекопировать нужный скрипт
cp /root/Linux_Server_Public/222/server_status.sh /usr/local/bin/server_status.sh
chmod +x /usr/local/bin/server_status.sh
echo "Updated"
```

---

## 🔒 Почему /usr/local/bin — правильное место

| Место | Выживает после reboot? | Причина |
|-------|----------------------|----------|
| `/root/` | ✅ Да | Домашняя папка — постоянная |
| `/root/Linux_Server_Public/` | ✅ Да | Git-репо на диске |
| `/usr/local/bin/` | ✅ Да | Системная папка, в PATH для root |
| `/tmp/` | ❌ НЕТ | Очищается при перезагрузке |
| Переменная среды (export) | ❌ НЕТ | Слетает при закрытии сессии |

`/usr/local/bin/` всегда в `$PATH` для root → скрипты вызываются без полного пути.

---

## 🕐 Cron-задачи (опционально)

```bash
crontab -e
```

```cron
# Ежечасный снапшот состояния сервера
0 * * * * /usr/local/bin/server_status.sh >> /var/log/server_status.log 2>&1

# Очистка лога раз в неделю (понедельник 04:00)
0 4 * * 1 truncate -s 0 /var/log/server_status.log

# Watchdog PHP-FPM — каждые 5 минут
*/5 * * * * /usr/local/bin/php_fpm_watchdog.sh >> /var/log/php_fpm_watchdog.log 2>&1
```

---

## ✅ Проверка что всё установлено правильно

```bash
clear
echo "=== Checking installed scripts ==="
for SCRIPT in server_status.sh infooo.sh php_fpm_watchdog.sh block_bots.sh; do
  if [ -x "/usr/local/bin/${SCRIPT}" ]; then
    echo "✓ /usr/local/bin/${SCRIPT}"
  else
    echo "✗ MISSING: /usr/local/bin/${SCRIPT}"
  fi
done
echo ""
echo "=== Checking aliases ==="
grep 'alias status\|alias infooo\|alias watchdog\|alias fight' /root/.bashrc
```

---

*= Rooted by VladiMIR | AI = | https://github.com/GinCz/Linux_Server_Public*
