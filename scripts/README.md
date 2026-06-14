# scripts/ — Документация скриптов

> Rooted by VladiMIR + AI | github.com/GinCz/Linux_Server_Public

---

## night_update.sh

**Версия:** v2026.06.15  
**Путь на серверах:** `/root/night_update.sh`  
**Источник:** `https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/night_update.sh`

### Назначение

Унифицированный скрипт ночного обслуживания для всех 10 серверов инфраструктуры. Выполняет обновление системы, очистку временных файлов и журналов, опционально перезагружает сервер. В случае ошибки отправляет тихое уведомление в Telegram.

### Режимы запуска

```bash
bash /root/night_update.sh --mode=vpn    # VPN: обновление + авторебут (Ср и Сб)
bash /root/night_update.sh --mode=sites  # Сайты: обновление без ребута (только Сб)
bash /root/night_update.sh --audit       # Пост-ребут проверка (через @reboot cron)
bash /root/night_update.sh --mode=vpn --force   # Запуск немедленно, игнорируя расписание
```

### Расписание (cron)

**VPN серверы** — среда и суббота в 02:00:
```cron
0 2 * * 3,6 bash /root/night_update.sh --mode=vpn >> /var/log/night_update.log 2>&1
@reboot sleep 30 && bash /root/night_update.sh --audit >> /var/log/night_update.log 2>&1
```

**Серверы с сайтами (222-DE, 109-RU)** — только суббота в 02:00, без ребута:
```cron
0 2 * * 6 bash /root/night_update.sh --mode=sites >> /var/log/night_update.log 2>&1
@reboot sleep 30 && bash /root/night_update.sh --audit >> /var/log/night_update.log 2>&1
```

### Что делает скрипт

#### Основное обновление (`--mode=vpn` / `--mode=sites`)

1. **Проверка расписания** — если сегодня не день обновления и нет `--force`, скрипт выходит без действий
2. **`apt-get update`** — обновление списков пакетов
3. **`apt-get upgrade`** — установка обновлений с `DEBIAN_FRONTEND=noninteractive`, `--force-confdef`, `--force-confold`
4. **Очистка:**
   - `apt-get autoremove` + `apt-get autoclean` + `apt-get clean`
   - `find /tmp -mindepth 1 -mtime +1 -delete`
   - `find /var/tmp -mindepth 1 -mtime +7 -delete`
   - `journalctl --vacuum-size=100M` + `--vacuum-time=14d`
   - btmp/wtmp очищаются если размер > 50MB
   - Лог `/var/log/night_update.log` обрезается если > 10MB (сохраняются последние 500 строк)
5. **Ребут (только `--mode=vpn`)** — всегда после успешного обновления, с TG уведомлением
6. **TG алерт (только `--mode=sites`)** — если `/var/run/reboot-required` существует → уведомление о необходимости ручного ребута

#### Пост-ребут аудит (`--audit`)

Запускается через `@reboot` cron с задержкой 30 секунд (ещё 90 секунд ждёт внутри). Проверяет:
- **Failed сервисы** — `systemctl list-units --state=failed`, фильтрует системный шум
- **RAM > 90%** — критическое использование памяти
- **Disk > 85%** — критическое заполнение диска

Если проблемы обнаружены — тихий Telegram алерт. Если всё OK — только запись в лог.

**Фильтр шума (сервисы которые игнорируются):**
```
certbot, exim4, fwupd, motd-news, logrotate, openipmi, packagekit, apport
```
Эти сервисы периодически завершаются с ненулевым кодом в штатном режиме работы — на VPS это норма.

### Telegram уведомления

Все уведомления тихие (`disable_notification=true`). Типы:

| Событие | Сообщение |
|---|---|
| apt update FAILED | ❌ hostname: apt update FAILED |
| apt upgrade ERROR | ❌ hostname: apt upgrade ERROR (exit N) |
| VPN ребут | 🔄 hostname — ночное обновление OK, перезагрузка |
| Нужен ребут (sites) | 🔄 hostname — нужна **ручная перезагрузка**, kernel packages: ... |
| Обновление OK (sites) | ✅ hostname — ночное обновление OK + состояние диска |
| Проблема после ребута | 🚨 hostname — problems after reboot! + детали |

### Лог

```bash
tail -f /var/log/night_update.log   # live мониторинг
grep 'START\|FINISH\|ERROR\|ALERT' /var/log/night_update.log  # только ключевые события
```

Пример нормального лога:
```
========================================
2026-06-15 02:00:01 NIGHT UPDATE START — vpn-server [mode=vpn]
2026-06-15 02:01:43 UPDATE + CLEANUP OK — Disk: 4.2G used / 20G total (15G free)
2026-06-15 02:01:43 REBOOTING (VPN mode)...
========================================
2026-06-15 02:03:15 POST-REBOOT AUDIT — vpn-server
2026-06-15 02:03:15 AUDIT OK — no issues
```

### Ручной запуск (тест)

```bash
# Тест без реального выполнения — проверить что расписание правильное
bash /root/night_update.sh --mode=vpn
# (если сегодня не Ср/Сб — выведет SKIP)

# Принудительный запуск прямо сейчас
bash /root/night_update.sh --mode=vpn --force

# Только аудит без ребута
bash /root/night_update.sh --audit
```

### Деплой / обновление скрипта на сервере

```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/night_update.sh \
  -o /root/night_update.sh && chmod +x /root/night_update.sh
```

### История версий

| Версия | Дата | Изменения |
|---|---|---|
| v2026.06.15 | 2026-06-15 | Режимы vpn/sites, расписание Ср+Сб, фильтр шума audit, очистка tmp, --force |
| v2026.06.10b | 2026-06-10 | Первая версия: базовое обновление, kernel reboot check, audit |

---

## server_monitor.sh

**Путь:** `/usr/local/bin/server_monitor.sh` (или `/root/server_monitor.sh`)  
**Запуск:** через cron каждые несколько минут

### Назначение
Мониторинг критических сервисов. При падении — Telegram алерт + попытка автоматического рестарта.

### Актуальный список сервисов (222-DE)
```bash
SERVICES=("nginx" "mysql" "crowdsec" "php8.3-fpm" "fp2-php84-fpm" "apache2")
```

> ⚠️ `php8.1-fpm` убран — на 222-DE его нет. Актуальные: php8.3-fpm и fp2-php84-fpm (FastPanel)

### Логика
1. Для каждого сервиса из списка: проверяет `systemctl list-unit-files` (сервис существует?)
2. Если существует — проверяет `systemctl is-active`
3. Если упал — тихий TG алерт + `systemctl restart`
4. Если рестарт успешен — TG подтверждение восстановления

---

## tg_service_problem.sh

**Путь:** `/root/tg_service_problem.sh` (или `/usr/local/bin/`)

### Назначение
Утилита для отправки Telegram-алерта о проблеме с конкретным сервисом. Используется из других скриптов или systemd unit'ов.

### Использование
```bash
bash /root/tg_service_problem.sh nginx
bash /root/tg_service_problem.sh mysql
```

### Формат сообщения
```
⚠️ SERVER: Server_EU_222
❌ SERVICE PROBLEM: nginx
🖥 Host: 222-DE-NetCup
🕒 Time: 2026-06-15 02:05:33
```

---

_Документация обновляется при каждом изменении скриптов_  
_VladiMIR + AI | 2026-06-15_
