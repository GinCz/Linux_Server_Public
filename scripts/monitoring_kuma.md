# Uptime Kuma — Monitoring Reference
# = Rooted by VladiMIR | AI =
# v2026-03-27

---

## Сервер мониторинга

| Параметр         | Значение                              |
|------------------|---------------------------------------|
| Сервер           | VPN-EU (VDSina)                       |
| Веб-интерфейс   | http://[VPN-IP]:3001                  |
| Timezone         | Europe/Prague (CET/CEST)              |
| Docker-контейнер | `uptime-kuma` (louislam/uptime-kuma:2)|
| База данных      | `/app/data/kuma.db` (SQLite)          |
| Порт             | 3001 → 3001 (tcp)                     |

---

## Расположение данных

```
Docker container name: uptime-kuma
Docker volume / bind:  /app/data/kuma.db  — основная БД
```

### Доступ к БД напрямую:
```bash
docker exec uptime-kuma sqlite3 /app/data/kuma.db "SELECT name FROM monitor;"
```

---

## Текущие настройки мониторов (применено 2026-03-27)

| Параметр               | Значение      | Колонка в БД   |
|------------------------|---------------|----------------|
| Интервал опроса        | 90 секунд     | `interval`     |
| Попыток до алерта      | 3             | `maxretries`   |
| Тайм-аут запроса       | 48 секунд     | `timeout`      |
| VPN мониторы timeout   | 10 секунд     | `timeout`      |

**Логика алертов:** 3 попытки × 90 сек = **4.5 минуты** до отправки уведомления.
Cold start PHP-FPM (ondemand) не триггерит алерт.

---

## Мониторы по группам

| Группа           | Описание                                      |
|-----------------|------------------------------------------------------|
| Сервер **222**   | Сайты европейского хостинга, с Cloudflare       |
| Сервер **109**   | Русские сайты, без Cloudflare                    |
| **VPN** мониторы | 8 VPN-узлов, timeout=10, maxretries=3           |

---

## Управление через SQL

### Посмотреть все мониторы:
```bash
docker exec uptime-kuma sqlite3 /app/data/kuma.db \
  "SELECT name, maxretries, timeout, interval FROM monitor ORDER BY name;"
```

### Установить maxretries=3 для всех:
```bash
docker exec uptime-kuma sqlite3 /app/data/kuma.db \
  "UPDATE monitor SET maxretries=3 WHERE maxretries < 2;"
```

### Изменить timeout для конкретного монитора:
```bash
docker exec uptime-kuma sqlite3 /app/data/kuma.db \
  "UPDATE monitor SET timeout=10 WHERE name='monitor_name';"
```

### Структура таблицы monitor (важные колонки):
```
id             — ID монитора
name           — Название
interval       — Интервал опроса (секунды)
maxretries     — Попыток до алерта (НЕ max_retries!)
timeout        — Тайм-аут запроса (секунды, DOUBLE)
retry_interval — Интервал между попытками
active         — 1=активен, 0=пауза
url            — URL для HTTP мониторов
type           — тип: http / ping / tcp / ...
```

---

## Резервное копирование БД Kuma

### Статус:
```bash
# Бэкап в Telegram (cron, 1 раз в месяц):
# 0 3 1 * * /bin/bash /root/scripts/kuma_tele_backup.sh
```

### Ручной бэкап БД:
```bash
docker cp uptime-kuma:/app/data/kuma.db /tmp/kuma_$(date +%F).db
```

---

## Перезапуск Kuma

```bash
docker restart uptime-kuma
docker ps | grep kuma
docker logs uptime-kuma --tail=50
```

---

## Timezone сервера

```bash
timedatectl set-timezone Europe/Prague
locale-gen en_GB.UTF-8
update-locale LC_TIME=en_GB.UTF-8
```

---

## Известные проблемы

| Монитор (222)     | Проблема                    | Причина                 |
|------------------|-----------------------------|-------------------------|
| sveta-drobot.cz  | HTTP 500 периодически       | PHP ошибка на сайте       |
| sveta-drobot.cz  | timeout 48000ms (редко)     | PHP ondemand cold start |
| kk-med.cz        | timeout=30 (особый)         | Намеренно уменьшен      |

---

## Whitelist IP-адресов

```
xxx.xxx.xxx.222
xxx.xxx.xxx.109
xxx.xxx.xxx.9
xxx.xxx.xxx.47
89.221.219.178
```

---

*Документ создан: 2026-03-27 | = Rooted by VladiMIR | AI =*
