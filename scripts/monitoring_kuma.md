# Uptime Kuma — Monitoring Reference
# = Rooted by VladiMIR | AI =
# v2026-03-27

---

## Сервер мониторинга

| Параметр        | Значение                          |
|-----------------|-----------------------------------|
| Сервер          | VPN-EU-Tatra (VDSina)             |
| IP              | xxx.xxx.xxx.9                     |
| Веб-интерфейс  | http://xxx.xxx.xxx.9:3001         |
| Timezone        | Europe/Prague (CET/CEST)          |
| Docker-контейнер| `uptime-kuma` (louislam/uptime-kuma:2) |
| База данных     | `/app/data/kuma.db` (SQLite)      |
| Порт            | 3001 → 3001 (tcp)                 |

---

## Расположение данных

```
Docker volume / bind:  /app/data/kuma.db   — основная БД
Docker container name: uptime-kuma
```

### Доступ к БД напрямую (на сервере xxx.xxx.xxx.9):
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
Случайный cold start PHP-FPM (ondemand) не триггерит алерт.

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
id            — ID монитора
name          — Название
interval      — Интервал опроса (секунды)
maxretries    — Попыток до алерта (НЕ max_retries!)
timeout       — Тайм-аут запроса (секунды, DOUBLE)
retry_interval— Интервал между попытками
active        — 1=активен, 0=пауза
url           — URL для HTTP мониторов
type          — тип: http / ping / tcp / ...
```

---

## Список мониторов (сайты — 2026-03-27)

### Сервер EU-222 (xxx.xxx.xxx.222) — с Cloudflare:
- svetaform.eu, sveta-drobot.cz, bio-zahrada.eu, gadanie-tel.eu
- wowflow.cz, czechtoday.eu, neonella.eu, tstwist.cz
- alejandrofashion.cz, kadernictvi-salon.eu, kadernik-olga.eu
- hockey4u.eu, balance-b2b.eu, eco-seo.cz, eco-seo.eu
- ekaterinburg-sro.eu, kk-med.cz (timeout=30!), kk-med.eu
- lybawa.com, megan-consult.cz, rail-east.uk, ru-tv.eu
- study-italy.eu, voyage4u.ru, gincz.com
- abl-metal.com, east-vector.cz, stm-services-group.cz
- car-chip.eu, autoservis-praha.eu, autoservis-rychlik.cz
- car-bus-autoservice.cz, car-bus-service.cz, detailing-alex.eu
- diamond-odtah.cz, stopservis-vestec.cz, vymena-motoroveho-oleje.cz
- Praha-autoservis.eu, hulk-jobs.cz, reklama-white.eu

### Сервер RU-109 (xxx.xxx.xxx.109) — без Cloudflare:
- 4ton-96.ru, andrey-maiorov.ru, comfort-eng.ru, geodesia-ekb.ru
- lvo-endo.ru, mtek-expert.ru, nail-space-ekb.ru, natal-karta.ru
- ne-son.ru, news-port.ru, novorr-art.ru, prodvig-saita.ru
- septik4dom.ru, shapkioptom.ru, stanok-ural.ru, stassinhouse.ru
- stomatolog-belchikov.ru, stuba-dom.ru, tatra-ural.ru, tri-sure.ru
- ugfp.ru, ver7.ru, mariela.ru, palantins.ru, doska-*.ru

### VPN мониторы (timeout=10, maxretries=3):
- VDSina_VPN_EU_STOLB_24
- VDSina_VPN_EU_Tatra_(Kuma)
- VPN_EU_4Ton_237
- VPN_EU_Alex_47
- VPN_EU_ILYA_176
- VPN_EU_Pilik_178
- VPN_EU_Shahin_227
- VPN_EU_ShapkiOptom_38

---

## Резервное копирование БД Kuma → сервер 222

### Скрипт бэкапа (запускать на xxx.xxx.xxx.9):
```bash
# Проверить наличие задания:
crontab -l | grep kuma

# Ручной бэкап БД:
docker exec uptime-kuma sqlite3 /app/data/kuma.db ".backup /tmp/kuma_backup.db"
rsync -avz /tmp/kuma_backup.db root@xxx.xxx.xxx.222:/BACKUP/kuma/

# Или экспорт через docker cp:
docker cp uptime-kuma:/app/data/kuma.db /tmp/kuma_$(date +%F).db
rsync -avz /tmp/kuma_$(date +%F).db root@xxx.xxx.xxx.222:/BACKUP/kuma/
```

### Добавить в cron (еженедельно, воскресенье 04:00):
```bash
# Выполнить на xxx.xxx.xxx.9:
(crontab -l 2>/dev/null; echo "0 4 * * 0 docker cp uptime-kuma:/app/data/kuma.db /tmp/kuma_\$(date +\%F).db && rsync -avz /tmp/kuma_\$(date +\%F).db root@xxx.xxx.xxx.222:/BACKUP/kuma/ >> /var/log/kuma_backup.log 2>&1") | crontab -
```

---

## Перезапуск Kuma

```bash
# Перезапустить контейнер (при необходимости):
docker restart uptime-kuma

# Статус:
docker ps | grep kuma

# Логи:
docker logs uptime-kuma --tail=50
```

---

## Timezone сервера

```bash
# Установлено:
timedatectl set-timezone Europe/Prague

# Формат даты (24-часовой английский):
locale-gen en_GB.UTF-8
update-locale LC_TIME=en_GB.UTF-8
```

---

## Известные проблемы

| Сайт            | Проблема                    | Причина              |
|-----------------|-----------------------------|----------------------|
| sveta-drobot.cz | HTTP 500 периодически       | PHP ошибка на сайте  |
| sveta-drobot.cz | timeout 48000ms (редко)     | PHP ondemand cold start |
| kk-med.cz       | timeout=30 (особый)         | Намеренно уменьшен   |

---

*Документ создан: 2026-03-27 | = Rooted by VladiMIR | AI =*
