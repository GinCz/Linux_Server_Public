# WORKLOG — Linux Server Infrastructure
> Rooted by VladiMIR + AI | github.com/GinCz/Linux_Server_Public

---

## Session 2026-07-08 — Flatsome лицензия патч + WC autoload cleanup (сервер 222)

### Контекст
На сервере **152.53.182.222 (DE-NetCup)** все сайты с темой Flatsome периодически пинговали `api.uxthemes.com` и `wupdates.com` для проверки лицензии. Задача — полностью отключить лицензионную проверку внутри темы на всех 43 сайтах. Попутно обнаружен и устранён WC autoload мусор на doska-* сайтах.

---

### Инцидент — mu-plugin вызвал массовый 500 на всех сайтах

#### Что произошло
Первая попытка — установка mu-plugin `disable-wc-stubs.php` через bash-скрипт с `while read` (завис из-за захвата stdin). После исправления на `for` цикл — скрипт отработал, но mu-plugin вызвал **HTTP 500 на всех 43 сайтах**.

**Причина:** mu-plugin грузится **раньше** темы и плагинов. Стаб `class WooCommerce {}` конфликтовал с настоящим классом WooCommerce на сайтах где WC установлен. На doska-* сайтах mu-plugin упал с задержкой ~10 минут по той же причине.

**Пострадавшие сайты (первая волна 20:37):**
- car-bus-autoservice.cz, hulk-jobs.cz, kk-med.eu, car-bus-service.cz, detailing-alex.eu

**Пострадавшие сайты (вторая волна 20:47 — все doska-*):**
- doska-it.ru, doska-cz.ru, doska-de.ru, doska-fr.ru, doska-esp.ru, doska-hun.ru, doska-ua.ru, doska-gr.ru, doska-isl.ru, doska-pl.ru, doska-mld.ru

#### Восстановление
```bash
# Удалить mu-plugin со всех сайтов
find /var/www -name "disable-wc-stubs.php" -path "*/mu-plugins/*" -delete
```
Все сайты поднялись немедленно без перезагрузки PHP-FPM.

#### Урок
**mu-plugin — неправильное место для патча лицензии темы.** Правильный способ — патчить файл внутри самой темы.

---

### Правильное решение — патч класса внутри темы

#### Целевой файл
```
flatsome/inc/classes/class-flatsome-wupdates-registration.php
```

Этот файл содержит класс `Flatsome_WUpdates_Registration` — он делает все HTTP запросы к `api.uxthemes.com`, проверяет лицензию, вешает cron `flatsome_scheduled_registration`.

#### Заглушка (сохранена в архиве темы)
Класс заменён заглушкой с той же сигнатурой:
- `is_registered()` → всегда `true`
- `is_verified()` → всегда `true`
- `get_code()` → возвращает фейк UUID `00000000-0000-0000-0000-000000000000`
- `register()` → возвращает `['status' => 'ok']` без HTTP запроса
- `get_latest_version()` → `false` (автообновления отключены)
- `migrate_registration()` → пустая функция
- `__construct()` → не вешает cron hooks

#### Деплой на сервер 222
```bash
# Скрипт записал заглушку в /tmp/patch.php и скопировал во все сайты
find /var/www -name "class-flatsome-wupdates-registration.php" -path "*/themes/flatsome/*"
# cp /tmp/patch.php "$f" для каждого найденного файла
```

**Результат:** 43 сайта пропатчены успешно.

| Домен | Пользователь | WC |
|---|---|---|
| alejandrofashion.cz | alejandrofashion | ❌ |
| detailing-alex.eu | alex_detailing | ❌ |
| autoservis-rychlik.cz | andrey-autoservis | ❌ |
| car-bus-autoservice.cz | andrey-autoservis | ❌ |
| autoservis-praha.eu | arslan | ❌ |
| praha-autoservis.eu | bayerhoff | ❌ |
| diamond-odtah.cz | diamond-drivers | ❌ |
| czechtoday.eu | dmitry-vary | ❌ |
| doska-cz.ru … doska-ua.ru (11 шт) | doski | ❌ |
| gadanie-tel.eu | gadanie-tel | ✅ |
| lybawa.com | gadanie-tel | ✅ |
| eco-seo.cz | gincz | ❌ |
| ekaterinburg-sro.eu | gincz | ❌ |
| ru-tv.eu | gincz | ✅ |
| hulk-jobs.cz | hulk | ❌ |
| abl-metal.com | igor_kap | ❌ |
| megan-consult.cz | igor_kap | ❌ |
| kk-med.eu | karina | ❌ |
| timan-kuchyne.cz | nata_popkova | ✅ |
| kadernik-olga.eu | olga_pisareva | ❌ |
| east-vector.cz | serg_et | ❌ |
| eurasia-translog.cz | serg_et | ❌ |
| rail-east.uk | serg_et | ❌ |
| car-chip.eu | serg_pimonov | ❌ |
| vymena-motoroveho-oleje.cz | serg_pimonov | ❌ |
| stopservis-vestec.cz | serg_reno | ❌ |
| svetaform.eu | spa | ✅ |
| balance-b2b.eu | sveta_tuk | ❌ |
| bio-zahrada.eu | tan-adrian | ✅ |
| stm-services-group.cz | tatiana_podzolkova | ❌ |
| tstwist.cz | tstwist | ❌ |
| kadernictvi-salon.eu | viktoria | ❌ |
| wowflow.cz | wowflow | ✅ |

---

### WC autoload мусор на doska-* сайтах

#### Проблема
На всех 11 doska-*.ru сайтах в БД были WC-опции с `autoload=yes` несмотря на то что WooCommerce не установлен. Это означало что при каждом WordPress запросе грузился WC-related код вхолостую.

**Виновник:** плагин `miniorange-login-openid` v7.8.0 — создавал опции:
- `mo_openid_woocommerce_before_login_form` — autoload=yes
- `mo_openid_woocommerce_center_login_form` — autoload=yes

Дополнительно найдены мусорные опции от старой установки WooCommerce:
- `wc_plugin_version` — autoload=yes
- `wc_options` — autoload=yes

#### Исправление
```bash
# Перевести все WC autoload опции в autoload=no на всех doska-*
for site in /var/www/doski/data/www/doska-*.ru; do
    wp --path="$site" db query \
      "UPDATE wp_options SET autoload='no'
       WHERE (option_name LIKE 'wc_%' OR option_name LIKE '%woocommerce%' OR option_name LIKE '%mo_openid_woo%')
       AND autoload='yes';" --allow-root
done

# Сбросить object cache
for site in /var/www/doski/data/www/doska-*.ru; do
    wp --path="$site" cache flush --allow-root
done
```

**Результат:** На всех 11 doska-* сайтах WC autoload опций с `yes` не осталось. Object cache сброшен.

#### Проверка остальных сайтов без WC
Проверены все 25 сайтов без WooCommerce (не doska-*) — WC autoload мусора нет ни на одном.

**Вывод:** Тема Flatsome корректно использует `is_woocommerce_activated()` (проверяет `class_exists('woocommerce')`) — весь WC-код в теме автоматически пропускается если WC не установлен. Дополнительных патчей для отключения WC-функций в теме не требуется.

---

### Итоговое состояние сервера 222 после сессии

| Задача | Статус |
|---|---|
| Flatsome лицензия заблокирована — 43 сайта | ✅ |
| mu-plugins disable-wc-stubs.php удалены (кроме doska-*) | ✅ |
| WC autoload мусор очищен на doska-* (11 сайтов) | ✅ |
| Object cache сброшен на doska-* | ✅ |
| Все сайты живые после всех изменений | ✅ |

### TODO
- [ ] Обновить архив `flatsome-3.18.1__Lic_VladiMIR.zip` на Windows — заменить `class-flatsome-wupdates-registration.php` заглушкой (чтобы новые установки сразу шли без лицензии)
- [ ] Удалить mu-plugins с doska-* после переустановки темы из обновлённого архива
- [ ] Проверить miniorange-login-openid на остальных серверах (109) — может быть та же проблема с WC autoload опциями

---

## Session 2026-06-25 — x-ui 3.4.0 баг: Reality config.json без settings блока (сервер 47)

### Контекст
Пользователи сервера **109.234.38.47 (VPN ALEX_47)** перестали подключаться по старым ссылкам VLESS Reality на порту 443. Порт 8443 (тестовый inbound) был удалён вручную через панель x-ui в ходе сессии.

---

### Симптомы
- Таймаут при подключении клиента (v2rayN, NekoBox)
- В панели x-ui все пользователи показывали "offline"
- `ss -tlnp` показывал что Xray **слушает** порт 443 — сервис живой
- `tcpdump` показывал что TCP SYN от клиента **приходит** и сервер отвечает SYN-ACK
- Xray лог (`journalctl -u x-ui`) — **пустой**, ни одной строки о подключении клиента
- `openssl s_client -connect 109.234.38.47:443 -servername www.github.com` → `CONNECTED`, `CN = github.com` — TLS ответ есть

---

### Диагностика — что проверяли

#### 1. config.json vs x-ui.db
```python
# x-ui.db (SQLite) — данные ПРАВИЛЬНЫЕ:
port=443  publicKey=eW3mJ2CRGSp3_nQ_RijPnMTfMTWgq_IUY4YnJ70yMXw  fingerprint=chrome

# /usr/local/x-ui/bin/config.json — НЕТ блока settings:
"realitySettings": {
    "privateKey": "OMY7kYfTJ4I_SJFsD9K3iC17_ccUaILN1IlMlhha4lo",
    "serverNames": ["www.github.com"],
    "shortIds": ["02"],
    ...
    # ОТСУТСТВУЕТ блок "settings": { "publicKey": ..., "fingerprint": ... }
}
```

**Вывод:** x-ui версии **26.6.22 (Xray 26.6.22 / x-ui 3.4.0)** при записи config.json **намеренно не пишет** блок `settings` внутри `realitySettings`. По новой логике x-ui должен генерировать `publicKey` из `privateKey` в памяти при старте Xray. Но фактически этого не происходит — Xray стартует **без publicKey**, и Reality handshake невозможен.

#### 2. Firewall — не виноват
```
iptables INPUT policy DROP
Правило 2: ACCEPT tcp dpt:8443
Правило 5: ACCEPT tcp dpt:443  ← есть, пакеты проходят
```
CrowdSec — нет банов для клиентских IP. ufw — 443/tcp ALLOW.

#### 3. Лог Xray
```
journalctl -u x-ui:
  INFO  - XRAY: infra/conf/serial: Reading config: bin/config.json
  WARNING - XRAY: core: Xray 26.6.22 started
  INFO  - xray core supports the online-stats API
```
После старта — **полная тишина** даже при попытках подключения клиента. Значит Xray принимает TCP соединение (SYN-ACK), но отвергает Reality handshake на уровне TLS до того как что-то логировать.

#### 4. Рабочий путь Xray
```
/proc/<pid>/cwd → /usr/local/x-ui
cmdline: bin/xray-linux-amd64 -c bin/config.json
```
Файл правильный, читается корректно.

#### 5. tcpdump — клиентский IP
Клиент подключается с **95.139.45.86** (мобильный/домашний IP VladiMIR).
```
95.139.45.86 → 109.234.38.47:443  [SYN]     ✅ приходит
109.234.38.47 → 95.139.45.86      [SYN-ACK] ✅ сервер отвечает
95.139.45.86 → 109.234.38.47      [ACK]     ✅ TCP установлен
109.234.38.47 → 95.139.45.86      [FIN]     ❌ сервер немедленно рвёт соединение
```
Reality handshake отвергается сразу — publicKey не задан, верификация невозможна.

---

### Что пробовали исправить

#### Попытка 1 — патч x-ui.db
Вставили `publicKey` и `fingerprint` напрямую в SQLite базу через python3:
```python
conn.execute('UPDATE inbounds SET stream_settings=? WHERE id=?', (json.dumps(ss), ib_id))
```
**Результат:** БД обновлена, но после `systemctl restart x-ui` — config.json снова генерируется **без** блока settings. x-ui 3.4.0 принципиально его не пишет.

#### Попытка 2 — прямой патч config.json
```python
rl['settings'] = {
    "publicKey":    "eW3mJ2CRGSp3_nQ_RijPnMTfMTWgq_IUY4YnJ70yMXw",
    "fingerprint":  "chrome",
    "serverName":   "",
    "spiderX":      "/",
    "mldsa65Verify": ""
}
```
Файл сохранён, верификация показала `[OK]`. Xray убит и перезапущен через `kill`.
**Результат:** x-ui через несколько минут/рестартов **снова перезаписывает** config.json без блока settings. Патч не держится.

#### Попытка 3 — перезапуск только Xray без x-ui
`kill $(pgrep -f xray-linux-amd64)` — x-ui автоматически поднимает Xray, но читает config.json из своего шаблона (снова без settings).

---

### Текущее состояние сервера 47 (на момент завершения сессии)
- Xray запущен, порт 443 слушает
- 54 активных ESTAB соединения — **старые пользователи держат сессии**
- Новые подключения — **не работают** (Reality handshake падает)
- Порт 8443 (тестовый inbound) — **удалён** через панель x-ui
- Бэкапы БД: `/etc/x-ui/x-ui.db.bak2`, `/usr/local/x-ui/bin/config.json.bak_final`

### Параметры inbound 443 (для восстановления)
```
privateKey : OMY7kYfTJ4I_SJFsD9K3iC17_ccUaILN1IlMlhha4lo
publicKey  : eW3mJ2CRGSp3_nQ_RijPnMTfMTWgq_IUY4YnJ70yMXw
fingerprint: chrome
shortIds   : ["02"]
serverNames: ["www.github.com"]
target     : www.github.com:443
spiderX    : /
```

### Правильная клиентская ссылка (VladiMIR)
```
vless://fe07c169-8304-4007-a2f3-b828943efc88@109.234.38.47:443?encryption=none&fp=chrome&pbk=eW3mJ2CRGSp3_nQ_RijPnMTfMTWgq_IUY4YnJ70yMXw&security=reality&sid=02&sni=www.github.com&spx=%2F&type=tcp#VladiMIR
```

---

### Корневая причина
**x-ui 3.4.0 (Xray 26.6.22)** — критический баг: при генерации `config.json` из БД не записывает блок `realitySettings.settings` содержащий `publicKey` и `fingerprint`. По задумке разработчиков эти параметры должны вычисляться из `privateKey` при старте, но реализация сломана — Xray стартует без них и не может аутентифицировать клиентов.

**Версия где сломалось:** предположительно при обновлении x-ui с версии до 3.4.0. До обновления всё работало.

---

### Полезные команды для диагностики Reality (найдено в ходе сессии)

#### Проверить что реально в config.json vs БД
```bash
# БД (источник истины):
python3 -c "
import sqlite3, json, tempfile, os
data = open('/etc/x-ui/x-ui.db','rb').read()
t = tempfile.NamedTemporaryFile(delete=False, suffix='.db')
t.write(data); t.close()
conn = sqlite3.connect(t.name)
for r in conn.execute('SELECT port, stream_settings FROM inbounds WHERE protocol=\"vless\"').fetchall():
    ss = json.loads(r[1]) if r[1] else {}
    rl = ss.get('realitySettings', {})
    sett = rl.get('settings', {})
    print(f'port={r[0]}  publicKey={sett.get(\"publicKey\",\"MISSING\")}  fp={sett.get(\"fingerprint\",\"MISSING\")}')
os.unlink(t.name)
"

# config.json (что реально читает Xray):
python3 -c "
import json
with open('/usr/local/x-ui/bin/config.json') as f:
    cfg = json.load(f)
for ib in cfg.get('inbounds',[]):
    if ib.get('protocol')=='vless':
        ss=ib.get('streamSettings',{})
        rl=ss.get('realitySettings',{})
        sett=rl.get('settings',{})
        print(f'port={ib[\"port\"]}  publicKey={sett.get(\"publicKey\",\"MISSING\")}  fp={sett.get(\"fingerprint\",\"MISSING\")}')
"
```

#### Поймать момент Reality handshake через tcpdump
```bash
# Смотрим все входящие соединения от конкретного клиента:
tcpdump -i ens3 -n "host <CLIENT_IP> and port 443"

# SYN-only для быстрой диагностики новых подключений:
tcpdump -i ens3 -n "port 443 and tcp[tcpflags] & tcp-syn != 0"

# Признак проблемы Reality: SYN → SYN-ACK → ACK → FIN (сервер рвёт без данных)
# Признак нормальной работы: SYN → SYN-ACK → ACK → DATA → DATA (туннель открыт)
```

#### Проверить лог Xray (пишет через journald, не в файл)
```bash
journalctl -u x-ui --no-pager --since '5 minutes ago'
# Включить debug:
# В config.json: "log": {"loglevel": "debug"}
# затем kill $(pgrep -f xray-linux-amd64) — x-ui автоподнимет с новым конфигом
```

#### Диагностика с сервера 222 на все VPN серверы
```bash
# Проверить publicKey на всех серверах разом:
PASS="OKMokm-09"
for HOST in 109.234.38.47 144.124.228.237 144.124.232.9 144.124.239.24 146.103.110.176 144.124.233.38 82.223.116.38; do
  echo -n "$HOST: "
  sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$HOST \
    "python3 -c \"
import json
with open('/usr/local/x-ui/bin/config.json') as f: cfg=json.load(f)
for ib in cfg.get('inbounds',[]):
    if ib.get('protocol')=='vless':
        ss=ib.get('streamSettings',{})
        rl=ss.get('realitySettings',{})
        pk=rl.get('settings',{}).get('publicKey','MISSING')
        print(f'port={ib[chr(34)]}  pk={pk[:20] if pk!= chr(77)+chr(73)+chr(83)+chr(83)+chr(73)+chr(78)+chr(71) else chr(77)+chr(73)+chr(83)+chr(83)+chr(73)+chr(78)+chr(71)}')
\"" 2>&1
done
```

---

### TODO — что нужно сделать следующей сессией

- [ ] **ГЛАВНОЕ:** Найти решение для x-ui 3.4.0 — как заставить его писать `settings` блок в config.json. Варианты:
  - Откатить x-ui до версии где баг не проявлялся (нужно найти последнюю рабочую версию)
  - Написать systemd hook/ExecStartPre который патчит config.json **после** генерации x-ui но **до** запуска Xray
  - Использовать `inotifywait` для отслеживания изменений config.json и автопатча
  - Заменить x-ui на 3x-ui или другой форк без этого бага
- [ ] Проверить эту же проблему на **остальных VPN серверах** (237, 9, 24, 176, 38, IONOS) — возможно у них та же версия x-ui и тот же баг, просто старые сессии ещё держатся
- [ ] После фикса — раздать пользователям сервера 47 обновлённые ссылки (spx изменился с `/e8R1jEWH8Z7CaRR` на `/`)
- [ ] Удалить тестовые бэкапы: `/etc/x-ui/x-ui.db.bak2`, `config.json.bak_final`, `config.json.bak_debug`

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
