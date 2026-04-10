# 📊 server_status.sh — Real-Time Server Snapshot

> **Version:** v2026-04-10  
> **Server:** 222-DE-NetCup | IP: 152.53.182.222 | Ubuntu 24 / FASTPANEL  
> **= Rooted by VladiMIR | AI =**

---

## 🎯 Назначение скрипта

`server_status.sh` — главный инструмент мгновенной диагностики сервера.  
Отвечает на вопрос: **«Что прямо сейчас происходит на сервере?»**

Скрипт создавался потому, что стандартные команды (`top`, `htop`, `ps`) дают разрозненную картину. Нужен **один вызов**, который показывает:

- кто ест память и CPU (MariaDB, Netdata, PHP-FPM пулы по сайтам)
- работают ли Docker-контейнеры (crypto-bot, VPN-ноды)
- какие сервисы упали и почему
- идёт ли атака на `wp-login.php` прямо сейчас
- сколько банов выдал CrowdSec
- кто последний заходил по SSH

---

## 🚀 Установка (persistent — не слетает после перезагрузки)

```bash
# 1. Скопировать скрипт в системный PATH
cp /root/Linux_Server_Public/222/server_status.sh /usr/local/bin/server_status.sh
chmod +x /usr/local/bin/server_status.sh

# 2. Добавить алиас в .bashrc
echo "alias status='bash /usr/local/bin/server_status.sh'" >> /root/.bashrc
source /root/.bashrc

# 3. Проверить
status
```

> ⚠️ Скрипт хранится в двух местах:  
> - `/usr/local/bin/server_status.sh` — **рабочая копия на сервере** (не слетает при перезагрузке)  
> - `/root/Linux_Server_Public/222/server_status.sh` — **резервная копия в репозитории**  
>
> После редактирования — синхронизировать оба места!

---

## 📌 Быстрое обновление скрипта с GitHub

```bash
# Обновить репо и перекопировать
cd /root/Linux_Server_Public && git pull --rebase
cp /root/Linux_Server_Public/222/server_status.sh /usr/local/bin/server_status.sh
chmod +x /usr/local/bin/server_status.sh
echo "Done — status updated"
```

---

## 🖥️ Использование

```bash
status                          # Полный снапшот (алиас)
bash /usr/local/bin/server_status.sh    # Напрямую
status 2>/dev/null | less -R    # С прокруткой (если экран мал)
```

### Автоматическое логирование (опционально — cron)

```bash
# Запись раз в час в лог
0 * * * * /usr/local/bin/server_status.sh >> /var/log/server_status.log 2>&1

# Очистка лога (чтобы не рос вечно) — добавить в cron:
0 4 * * 1 echo "" > /var/log/server_status.log
```

---

## 📋 Что показывает скрипт — раздел за разделом

### 1. LOAD AVERAGE & UPTIME
Показывает нагрузку за последние 1/5/15 минут в % от числа ядер (4 vCore).  
**Цвет:** зелёный (<60%), жёлтый (60–90%), красный (>90%).  
*Почему важно:* Если load1 > 4.0 — сервер перегружен, надо срочно искать виновника.

### 2. MEMORY (RAM + SWAP)
Полная таблица free/used/available RAM и Swap.  
*Сервер: 8GB DDR5 ECC.*  
*Почему важно:* MariaDB один занимает ~1 GB, Netdata ~220 MB, PHP-FPM пулы — ещё по 100–160 MB каждый.  
При нехватке RAM — сервер начинает свопить → резкое замедление всех сайтов.

### 3. DISK USAGE
Показывает все смонтированные разделы с % заполнения.  
*Сервер: 256GB NVMe.*  
*Почему важно:* Переполнение диска → Nginx и MySQL перестают писать логи → сайты падают без очевидной причины.

### 4. TOP 20 PROCESSES BY MEMORY (RSS)
Отсортированный список процессов по реальной занятой памяти (RSS).  
Показывает: PID, USER, %CPU, %MEM, RSS в МБ, имя процесса.  
*Почему важно:* Именно здесь видно, что MariaDB (mysql-пользователь) держит 1GB, Netdata — 220MB, каждый PHP-FPM worker wowflow.cz — по 160MB.

### 5. TOP 10 PROCESSES BY CPU%
Процессы, которые прямо сейчас грузят процессор.  
*Почему важно:* При атаках — здесь видно 100% CPU на nginx или php-fpm.

### 6. PHP-FPM POOLS
Агрегированная статистика по пулам PHP-FPM: сколько воркеров запущено и сколько памяти занимает каждый пул.  
*На сервере сайты:* wowflow.cz, bio-zahrada.eu, svetaform.eu, gincz (PHP 8.4), lybawa.com и др.  
*Почему важно:* Если один пул держит 20+ воркеров — у него проблемы (бесконечный запрос, дедлок MySQL, атака).

### 7. MYSQL / MARIADB
Показывает: количество подключений, запущенных потоков, медленные запросы, uptime БД, список активных PROCESSLIST.  
*Почему важно:* Медленные запросы и зависшие connections — причина #1 зависания WordPress сайтов.

### 8. NGINX STATUS
Количество воркеров, статус stub_status (если включён), число TCP-соединений ESTABLISHED.  
*Почему важно:* При DDoS — число connections резко растёт. Видно сразу.

### 9. DOCKER CONTAINERS
Статус всех Docker-контейнеров: CPU%, Memory, статус (Up/Exited).  
*На сервере запущены:*  
- `crypto-bot` — торговый бот (Python)
- VPN-ноды (8 штук, бекапируются через `f5vpn`)
*Почему важно:* Если crypto-bot упал — видно здесь сразу, а не через 2 часа.

### 10. KEY SERVICES STATUS
Состояние всех ключевых служб: nginx, mariadb, php-fpm (все версии), crowdsec, netdata, exim4, dovecot, named, docker, ssh, cron.  
*Показывает:* active/inactive/failed + enabled/disabled.  
*Почему важно:* Cron, который помечен как disabled, не запустится после перезагрузки.

### 11. CROWDSEC — ACTIVE BANS
Текущее число активных банов + последние 10 заблокированных IP.  
*Почему важно:* CrowdSec защищает все 15+ сайтов. Если бан-листа нет — значит bouncer не работает.

### 12. WP-LOGIN BRUTE FORCE ATTACKS
Сканирует все access.log файлы (`/var/www/*/data/logs/*access.log`) и считает обращения к `wp-login.php` по IP.  
*Цвет:* красный (>100 попыток), жёлтый (>20), белый (мало).  
*Реальный пример (2026-04-10):*  
```
1033 hits — 141.98.11.120 (balance-b2b.eu)  
  25 hits — 167.179.19.229 (doska-hun.ru)  
```
*Почему важно:* 1033 попытки с одного IP — это атака, которую CrowdSec должен был поймать.

### 13. OPEN PORTS
Список всех TCP портов в состоянии LISTEN с именем процесса.  
*Почему важно:* Позволяет заметить неожиданно открытый порт (взлом, майнер).

### 14. LAST LOGINS
Последние 5 успешных входов на сервер.  
*Почему важно:* Аудит доступа.

### 15. FAILED SSH LOGIN ATTEMPTS
Уникальные IP-адреса с неудачными попытками SSH за последние 24 часа.  
*Почему важно:* Если CrowdSec работает — эти IP должны уже быть забанены.

### 16. DISK USAGE BY SITE (/var/www)
Топ-10 самых тяжёлых сайтов по размеру файлов.  
*Почему важно:* Один разросшийся сайт может съесть весь NVMe.

---

## 📁 Связанные скрипты (алиасы из .bashrc)

| Алиас | Скрипт | Что делает |
|-------|--------|------------|
| `status` | `server_status.sh` | ⭐ Этот скрипт — полный снапшот |
| `infooo` | `infooo.sh` | Системные версии + benchmark CPU/RAM/Disk |
| `watchdog` | `php_fpm_watchdog.sh` | Перезапуск зависших PHP-FPM пулов |
| `fight` | `block_bots.sh` | Блокировка ботов по user-agent |
| `banlog` | `banlog.sh 30` | Лог банов за 30 минут |
| `sos` | `sos.sh 1h` | Детальный анализ логов за 1 час |
| `domains` | `domains.sh` | Проверка SSL и статуса всех доменов |
| `allinfo` | `all_servers_info.sh` | Статус обоих серверов (222 + 109) |
| `clog` | docker logs | Логи crypto-bot (последние 40 строк) |
| `f5vpn` | `vpn_docker_backup.sh` | Бекап всех VPN Docker-нод |

---

## 🔧 История изменений

| Дата | Изменение |
|------|-----------|
| 2026-04-10 | ✅ Создан скрипт v2026-04-10. Добавлены все 16 разделов. Документация. |

---

## ⚠️ Важные замечания

1. **MySQL PROCESSLIST** — скрипт запускается от root, поэтому `mysql -e` работает без пароля (socket auth).  
2. **Nginx stub_status** — если не настроен, раздел покажет предупреждение. Для включения: добавить `location /nginx_status { stub_status on; allow 127.0.0.1; deny all; }` в nginx конфиг.
3. **Docker stats** занимает ~1-2 секунды (необходим для получения CPU%).  
4. **wp-login scan** на 15+ сайтах может занять 2-5 секунд при большом объёме логов.  
5. **Полное время выполнения** скрипта: 5–10 секунд.

---

*= Rooted by VladiMIR | AI = | GitHub: https://github.com/GinCz/Linux_Server_Public*
