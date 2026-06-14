# WORKLOG — Linux Server Infrastructure
> Rooted by VladiMIR + AI | github.com/GinCz/Linux_Server_Public

---

## Session 2026-06-15 — night_update.sh полный рефакторинг + деплой на 10 серверов

### Контекст
Проверка состояния всех 10 серверов инфраструктуры выявила серьёзный конфликт: на большинстве серверов параллельно работали два независимых механизма обновления — старый cron с жёстким `apt + /sbin/reboot` каждую ночь, и новый `night_update.sh` через systemd timer. Это приводило к двойному обновлению, непредсказуемым ребутам и пустым логам.

### Инфраструктура (10 серверов)

| IP | Имя | Тип | Провайдер |
|---|---|---|---|
| 152.53.182.222 | 222-DE-NetCup | Сайты (DE) | NetCup |
| 212.109.223.109 | 109-RU | Сайты (RU) | VDS |
| 109.234.38.47 | VPN-1 | VPN | NetCup |
| 144.124.228.237 | VPN-2 | VPN | NetCup |
| 144.124.232.9 | VPN-3 | VPN | NetCup |
| 144.124.228.227 | VPN-4 | VPN | NetCup |
| 144.124.239.24 | VPN-5 | VPN | NetCup |
| 146.103.110.176 | VPN-6 | VPN | NetCup |
| 144.124.233.38 | VPN-7 | VPN | NetCup |
| 3.79.14.42 | VPN-Amazon | VPN | Amazon AWS |
| 82.223.116.38 | VPN-IONOS | VPN | IONOS |

---

### Проблемы, которые были обнаружены

#### 1. Двойной апдейтер — конфликт cron + systemd timer
**Симптом:** Каждую ночь на большинстве серверов запускалось два обновления:
- Старый cron (`0 2 * * *` или `0 3 * * *`): тупой apt-get + немедленный `/sbin/reboot`
- Systemd `night-update.timer`: запускал умный `night_update.sh` в 03:30

**Последствия:**
- Сервер ребутался в 02:00 от cron, а в 03:30 timer запускал второй apt upgrade уже после ребута
- Лог `/var/log/night_update.log` был пустой — cron писал в `/var/log/auto-upgrade.log`
- На серверах 222 и 109 (с сайтами!) происходил автоматический ежедневный ребут в 02:00 — это нарушало работу сайтов

#### 2. Мусорные алерты в Telegram от --audit
**Симптом:** После каждого ребута приходили Telegram-уведомления о "проблемах" с сервисами:
```
❌ Failed units: certbot.service exim4-base.service fwupd-refresh.service logrotate.service motd-news.service openipmi.service
```
**Причина:** Скрипт `--audit` проверял все failed-сервисы без фильтрации. Перечисленные сервисы — системный шум, они периодически падают в exit-code при плановом запуске и это абсолютно нормально:
- `certbot` — возвращает ненулевой exit если нет обновлений для продления
- `exim4-base` — housekeeping задача
- `fwupd-refresh` — обновление метаданных прошивок (на VPS прошивок нет)
- `motd-news` — загрузка новостей дня
- `logrotate` — ротация логов (иногда падает при пустых логах)
- `openipmi` — IPMI драйвер, которого **никогда не будет** на VPS/виртуалках

#### 3. Разные варианты старого cron
На серверах были разные версии старого апдейт-cron:
- Вариант A: `0 2 * * *` с `--force-confold`
- Вариант B: `0 3 * * *` с `DEBIAN_FRONTEND=noninteractive` но без `--force-confdef`
- Вариант C (сервер .237, .227, Amazon): неправильный порядок флагов — redirect `>>` стоял перед некоторыми командами, из-за чего часть ошибок не логировалась

#### 4. server_monitor.sh проверял несуществующий php8.1-fpm
**Симптом:** На 222 `server_monitor.sh` мониторил `php8.1-fpm` которого нет (есть 8.3 и 8.4). Каждые N минут скрипт мог слать ложный алерт о падении несуществующего сервиса.

#### 5. voyage4u.ru — сайт упал (отдельный инцидент, 109)
**Причина:** PHP 5.6 FPM (`fp2-php56-fpm.service`) был остановлен. Nginx отдавал 502 Bad Gateway.
**Диагностика:**
```bash
nginx -t                          # OK
systemctl status fp2-php56-fpm   # inactive (dead)
journalctl -u fp2-php56-fpm -n30 # stopped, no errors
```
**Fix:**
```bash
systemctl start fp2-php56-fpm
systemctl enable fp2-php56-fpm
```
**Результат:** HTTP 200 восстановлен.

**⚠️ ВАЖНО для сервера 109 — voyage4u.ru:**
| Категория | Действие | Риск |
|---|---|---|
| 🔴 НЕЛЬЗЯ | `systemctl stop fp2-php56-fpm` | Сайт упадёт немедленно |
| 🔴 НЕЛЬЗЯ | `apt-get remove php5.6\*` или `fp2-php\*` | Сайт упадёт |
| 🔴 НЕЛЬЗЯ | Менять `/etc/nginx/sites-enabled/voyage4u.ru` | Сайт упадёт |
| 🟡 ОСТОРОЖНО | `reboot` на 109 | fp2-php56-fpm должен подняться (enabled), проверить после |
| 🟡 ОСТОРОЖНО | `apt upgrade` на 109 | Если обновится fp2-php56 — проверить сайт |
| 🟢 МОЖНО | Обновлять php8.3-fpm, php8.4-fpm | Не влияет на PHP 5.6 |

**Конфигурационные пути voyage4u.ru:**
- Pool config: `/etc/opt/remi/php56/php-fpm.d/voyage4u.conf`
- Socket: `/var/run/fp2-php56-fpm/voyage4u.sock`
- Nginx config: `/etc/nginx/sites-enabled/voyage4u.ru`
- Логи FPM: `/var/opt/remi/php56/log/php-fpm/`

**📋 TODO:** Мигрировать voyage4u.ru с PHP 5.6 на 7.4+ (или удалить если сайт не нужен)

---

### Что было сделано

#### 1. Написана новая версия night_update.sh (v2026.06.15)

**Файл:** `scripts/night_update.sh`
**Коммит:** f4e7a74

Ключевые изменения по сравнению с v2026.06.10b:

| Что | Было | Стало |
|---|---|---|
| Режимы запуска | Один скрипт без параметров | `--mode=sites` и `--mode=vpn` |
| Расписание | Каждую ночь | Среда+суббота (vpn), только суббота (sites) |
| Ребут на сайтах | Каждую ночь автоматически ❌ | Никогда — только TG алерт |
| Ребут на VPN | Каждую ночь (через старый cron) | Каждую Ср+Сб после обновления ✅ |
| Audit шум | Все failed-сервисы в TG | Фильтр: certbot, exim4, fwupd, motd-news, logrotate, openipmi |
| Очистка tmp | Не было | `find /tmp -mtime +1`, `find /var/tmp -mtime +7` |
| Флаг --force | Не было | Игнорирует расписание, запускает сейчас |
| apt clean | Только autoclean | autoclean + clean |
| TG при успехе | Только при ребуте | Всегда — подтверждение OK + состояние диска |

#### 2. Деплой на все 10 серверов

С 222-DE через SSH батч-скрипт:
- Скачан свежий `night_update.sh` с GitHub
- Удалены старые cron строки (`apt-get`, `auto-upgrade`, `night_update.sh`)
- Добавлены правильные cron строки по режиму
- Отключён дублирующий systemd `night-update.timer`
- Уникальные строки каждого сервера (ipset, iptables, dns-bypass, acme.sh, blacklist) **не тронуты**

**Итоговый crontab на VPN серверах:**
```cron
# Ночное обновление — среда и суббота, автоматический reboot
0 2 * * 3,6 bash /root/night_update.sh --mode=vpn >> /var/log/night_update.log 2>&1
@reboot sleep 30 && bash /root/night_update.sh --audit >> /var/log/night_update.log 2>&1
```

**Итоговый crontab на серверах с сайтами (222, 109):**
```cron
# Ночное обновление — только суббота, без авторебута (сайты)
0 2 * * 6 bash /root/night_update.sh --mode=sites >> /var/log/night_update.log 2>&1
@reboot sleep 30 && bash /root/night_update.sh --audit >> /var/log/night_update.log 2>&1
```

#### 3. Результат деплоя по серверам

| IP | Сервер | Статус | Режим | Примечание |
|---|---|---|---|---|
| 152.53.182.222 | 222-DE | ✅ | sites | Локально (SSH к себе не работает) |
| 212.109.223.109 | 109-RU | ✅ | sites | |
| 109.234.38.47 | VPN-1 | ✅ | vpn | |
| 144.124.228.237 | VPN-2 | ✅ | vpn | |
| 144.124.232.9 | VPN-3 | ✅ | vpn | |
| 144.124.228.227 | VPN-4 | ✅ | vpn | IPGuard комментарии очищены |
| 144.124.239.24 | VPN-5 | ✅ | vpn | dns-bypass-ensure.sh сохранён |
| 146.103.110.176 | VPN-6 | ✅ | vpn | deploy-blacklist.sh @reboot сохранён |
| 144.124.233.38 | VPN-7 | ✅ | vpn | |
| 3.79.14.42 | Amazon | ✅ | vpn | |
| 82.223.116.38 | IONOS | ✅ | vpn | Дублирующие IPGuard комментарии очищены |

---

### Итоговая схема обновлений

```
СРЕДА 02:00  → VPN серверы (8шт): apt upgrade + cleanup + reboot → @reboot audit
СУББОТА 02:00 → ВСЕ 10 серверов:
                  VPN: apt upgrade + cleanup + reboot → @reboot audit
                  Сайты (222,109): apt upgrade + cleanup + TG если нужен ребут
```

### Следующие шаги
- [ ] Мигрировать voyage4u.ru (109) с PHP 5.6 → 7.4+
- [ ] Проверить первый плановый запуск в ближайшую субботу
- [ ] Рассмотреть удаление устаревшего `night-update.service` файла (уже не используется)

---

## Session 2026-06-15 Part 1 — voyage4u.ru 502, диагностика 222

### Диагностика 222-DE-NetCup

**Проблема:** voyage4u.ru отдавал 502 Bad Gateway.

**Пошаговая диагностика:**
```bash
curl -I https://voyage4u.ru          # 502
nginx -t                              # syntax OK
ls /var/run/fp2-php56-fpm/           # voyage4u.sock — ОТСУТСТВУЕТ
systemctl status fp2-php56-fpm      # inactive (dead)
journalctl -u fp2-php56-fpm -n30    # явных ошибок нет, просто остановлен
```

**Fix:**
```bash
systemctl start fp2-php56-fpm
systemctl enable fp2-php56-fpm
curl -I https://voyage4u.ru          # 200 OK ✅
```

**Failed services на 222 (системный шум, не критично):**
- `certbot.service` — нет сертификатов для продления
- `exim4-base.service` — housekeeping
- `fwupd-refresh.service` — нет прошивок на VPS
- `logrotate.service` — эпизодические сбои нормальны
- `motd-news.service` — новости дня
- `openipmi.service` — IPMI не существует на VPS, **всегда будет FAIL**

---

_Лог ведётся автоматически | VladiMIR + AI_
