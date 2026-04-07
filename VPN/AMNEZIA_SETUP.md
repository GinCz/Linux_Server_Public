# AmneziaWG VPN Server — Setup & Management Guide

> = Rooted by VladiMIR | AI =  
> v2026-04-07

---

## Что это и зачем

- **VPN Software:** [AmneziaWG](https://github.com/amnezia-vpn/amneziawg-go) — обфусцированный WireGuard
- **Запускается в:** Docker-контейнер `amnezia-awg`
- **Почему не обычный WireGuard:** в России обычный WireGuard блокируется DPI (Deep Packet Inspection) по характерной сигнатуре handshake-пакетов. AmneziaWG добавляет перед handshake мусорные (junk) пакеты с рандомными параметрами — трафик становится неотличимым от случайного UDP
- **Протокол:** UDP
- **Подсеть:** `10.8.1.0/24`
- **Интерфейс внутри контейнера:** `wg0`
- **Интерфейс на хосте:** `amn0`

---

## Серверы

| Сервер | IP | Провайдер | Порт | Назначение |
|---|---|---|---|---|
| VPN-EU-Tatra-9 | 144.124.232.9 | NetCup (Германия) | 42430 | Европа, с Cloudflare |
| VPN-RU | 212.109.223.109 | FastVDS (Россия) | — | Россия, без Cloudflare |

---

## Установка на чистый Ubuntu 24

### 1. Подготовка системы

```bash
apt update && apt upgrade -y
apt install -y docker.io docker-compose curl
systemctl enable docker --now
```

### 2. Установка AmneziaWG

Устанавливается через официальный клиент **Amnezia Client** (рекомендуется) или вручную через Docker.

**Способ 1 — через Amnezia Client (рекомендуется):**
1. Скачать [Amnezia Client](https://amnezia.org) на свой компьютер (Windows/Mac/Linux)
2. Открыть клиент → `Добавить сервер` → ввести IP, порт SSH, логин/пароль root
3. Клиент сам установит Docker, скачает образ, создаст контейнер и настроит туннель
4. После установки — добавить пользователей прямо из клиента

**Способ 2 — вручную через Docker:**
```bash
docker run -d \
  --name amnezia-awg \
  --cap-add NET_ADMIN \
  --cap-add SYS_MODULE \
  -p 42430:42430/udp \
  -v /opt/amnezia/awg:/opt/amnezia/awg \
  --restart unless-stopped \
  ghcr.io/amnezia-vpn/amnezia-awg:latest
```

### 3. ⚠️ ВАЖНО: какой порт указывать

При установке через Amnezia Client или вручную — **всегда указывать нестандартный порт**.

| Порт | Проблема |
|---|---|
| 51820 | Стандартный порт WireGuard — блокируется в России по номеру порта |
| 1194 | Стандартный OpenVPN — тоже блокируется |
| **42430** | Нестандартный — не блокируется |

> На наших серверах используется порт **42430**. При установке новых VPN-серверов указывать именно его.

### 4. Параметры обфускации (junk)

Эти параметры прописываются автоматически при установке через Amnezia Client.  
Они хранятся в `/opt/amnezia/awg/wg0.conf` в секции `[Interface]`:

```
Jc = 3        # количество junk-пакетов перед handshake
Jmin = 10     # минимальный размер junk-пакета (байт)
Jmax = 50     # максимальный размер junk-пакета (байт)
S1 = 115      # сдвиг первого пакета инициации
S2 = 96       # сдвиг ответного пакета
H1-H4 = ...   # magic headers — случайные числа, генерируются при установке
```

---

## Файлы конфигурации на сервере

Всё хранится на хосте в директории `/opt/amnezia/awg/` (смонтировано в контейнер):

```
/opt/amnezia/awg/
├── wg0.conf        # конфиг WireGuard интерфейса (интерфейс + все пиры)
├── clientsTable    # JSON: имена клиентов + их публичные ключи
└── start.sh        # скрипт запуска контейнера
```

### Просмотр конфига сервера

```bash
cat /opt/amnezia/awg/wg0.conf
```

Пример вывода:
```
[Interface]
PrivateKey = SBiNPxi5KhtzzI6OgP+FZQMg9Ey8jSyCXA5lpk7kzWA=
Address = 10.8.1.0/24
ListenPort = 42430
Jc = 3
Jmin = 10
Jmax = 50
S1 = 115
S2 = 96
H1 = 1759142089
H2 = 1948227888
H3 = 11875121
H4 = 754506434

[Peer]
PublicKey = xd/y9Lxnq7vHSlgZwUMSbAM8pfRZ5ZQ2xIa43q5VykM=
PresharedKey = yb7iprzwxp1FXWrY0ATVwiI0mdOVT+sDiV9qJEMlgg0=
AllowedIPs = 10.8.1.4/32

[Peer]
...
```

> ℹ️ На сервере в `[Peer]` нет поля `Endpoint` — это нормально. Сервер не знает заранее IP клиента, клиенты сами приходят с любого IP.

### Просмотр таблицы клиентов (имена)

```bash
cat /opt/amnezia/awg/clientsTable
```

JSON-файл — содержит публичный ключ клиента, имя (`clientName`) и его IP (`allowedIps`).

---

## Управление контейнером

```bash
# Проверить что контейнер запущен
docker ps | grep amnezia

# Перезапустить контейнер
docker restart amnezia-awg

# Войти внутрь контейнера
docker exec -it amnezia-awg sh
```

> ⚠️ Команды `wg` и `awg` доступны ТОЛЬКО внутри контейнера, не на хосте.  
> На хосте `wg` не установлен — это нормально, wireguard-tools не нужен.

### Внутри контейнера

```bash
# Войти
docker exec -it amnezia-awg sh

# Статус всех пиров (ключевая команда диагностики)
wg show

# Подробный дамп с timestamp handshake и трафиком
wg show wg0 dump
```

**Пример вывода `wg show`:**
```
interface: wg0
  public key: aN/9OA10G0HqPBY1/5ktTIcXIZP+XGJQ8SbU7pqrxDk=
  listening port: 42430
  jc: 3  jmin: 10  jmax: 50  s1: 115  s2: 96

peer: uoW4QeKgb8LYExGRSsbHBJxjKx1iEM6c63vWoRlcBn0=
  endpoint: 5.189.4.217:28208
  allowed ips: 10.8.1.15/32
  latest handshake: 1 second ago
  transfer: 1.15 MiB received, 129.03 MiB sent

peer: xd/y9Lxnq7vHSlgZwUMSbAM8pfRZ5ZQ2xIa43q5VykM=
  allowed ips: 10.8.1.4/32
  (no handshake — клиент ни разу не подключался)
```

**Как читать вывод:**
- `endpoint` — текущий IP:порт клиента (появляется только если клиент подключался)
- `latest handshake: Xs ago` — клиент активен
- `latest handshake: (none)` или строка отсутствует — клиент никогда не подключался или очень давно
- Если handshake был < 3 минут назад — клиент онлайн

**Формат `wg show wg0 dump` (используется в скриптах):**
```
pubkey  preshared  endpoint  allowed_ips  last_handshake_unix  rx_bytes  tx_bytes  keepalive
```
- `last_handshake_unix` = 0 означает «никогда не подключался»

---

## Добавление нового пользователя

### Через Amnezia Client (рекомендуется)

1. Открыть **Amnezia Client** на своём компьютере
2. Выбрать сервер (VPN-EU-Tatra-9)
3. `Настройки` → раздел `Пользователи` → кнопка `Добавить пользователя`
4. Ввести имя в формате `Имя_Устройство` (например: `Pavel_iPhone`, `Elena_PC`)
5. Нажать `Создать` — клиент автоматически:
   - Генерирует пару ключей
   - Добавляет пира в `wg0.conf` на сервере
   - Записывает имя в `clientsTable`
   - Присваивает следующий свободный IP из подсети `10.8.1.x`
6. Скачать QR-код → отсканировать приложением Amnezia на телефоне
7. Или скачать `.conf` файл → импортировать в Amnezia на ПК

### Назначение IP пользователям (текущее состояние)

| IP | User | Статус |
|---|---|---|
| 10.8.1.4 | Admin [Windows 10 22H2] | не подключался |
| 10.8.1.5 | Pavel_iPhone | не подключался |
| 10.8.1.6 | Pavel_PC | не подключался |
| 10.8.1.7 | Andr_iPhone | ✅ активен |
| 10.8.1.9 | Serg_iPhone | ✅ активен |
| 10.8.1.10 | Konstantine_iPhone | ✅ активен |
| 10.8.1.11 | ilya_iPhone | ✅ активен |
| 10.8.1.12 | Olga_Kre_iPhone | не подключался |
| 10.8.1.13 | Irina_Ilya_Samsung | не подключался |
| 10.8.1.14 | Olesya_Valery_iPhone | не подключался |
| 10.8.1.15 | Elena_Andr_iPhone | ✅ активен |
| 10.8.1.16 | Elis_Star_iPhone | ✅ активен |
| 10.8.1.17 | Lev_Star_iPhone | не подключался |
| 10.8.1.18 | Evgenia_iPhone | ✅ активен |
| 10.8.1.19 | Admin [Android 10] | не подключался |
| 10.8.1.20 | Valer_iPhone | не подключался |
| 10.8.1.21 | (резерв) | — |

> Следующий свободный IP для нового пользователя: **10.8.1.22**

---

## Скрипты

Все скрипты лежат в `/root/` на сервере и в этом репозитории в папке `VPN/`.

### Обновить скрипты с GitHub

```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/amnezia_stat.sh \
  -o /root/amnezia_stat.sh
```

---

### `amnezia_stat.sh` — Статистика трафика

Главный скрипт мониторинга. Показывает:
- **Секция 1:** таблицу всех пиров с трафиком (inbound/outbound/total в ГБ), отсортированную по убыванию трафика
- **Секция 2:** только те пиры, у которых был handshake за последние 15 минут (реально активные прямо сейчас)

**Запуск:**
```bash
bash /root/amnezia_stat.sh
```

**Пример вывода:**
```
=== AmneziaWG Stats v2026-04-07b ===

┌─────────────────────┬──────────────────────────────────────────┬──────────────┬──────────────┬──────────────┐
│ IP Address          │ User Name                                │ Inbound(GB)  │ Outbound(GB) │ Total(GB)    │
├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤
│ 10.8.1.7            │ Andr_iPhone                              │ 0.05         │ 1.09         │ 1.13         │
│ 10.8.1.15           │ Elena_Andr_iPhone                        │ 0.01         │ 0.80         │ 0.81         │
│ 10.8.1.10           │ Konstantine_iPhone                       │ 0.01         │ 0.70         │ 0.72         │
│ ...                 │ ...                                      │ ...          │ ...          │ ...          │
├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤
│ TOTAL               │ All Clients Combined                     │ 0.07         │ 2.65         │ 2.73         │
└─────────────────────┴──────────────────────────────────────────┴──────────────┴──────────────┴──────────────┘

=== Active peers (last 15 minutes) ===

  10.8.1.9             Serg_iPhone              1m 7s ago     rx:2.9 MB     tx:4.4 MB
  10.8.1.7             Andr_iPhone              2m 3s ago     rx:47.5 MB    tx:1112.9 MB
  10.8.1.15            Elena_Andr_iPhone        1m 49s ago    rx:5.3 MB     tx:820.9 MB
  10.8.1.11            ilya_iPhone              1m 12s ago    rx:0.3 MB     tx:0.8 MB
  10.8.1.18            Evgenia_iPhone           5m 9s ago     rx:0.1 MB     tx:0.2 MB
```

**Как работает скрипт изнутри:**

1. Читает `/opt/amnezia/awg/clientsTable` — JSON с именами клиентов
2. Определяет команду: `awg show awg0 dump` или `wg show wg0 dump` (в зависимости от версии образа)
3. Парсит dump — колонки: `pubkey | preshared | endpoint | allowed_ips | last_handshake_unix | rx | tx | keepalive`
4. Для каждого пира ищет имя и IP в clientsTable по публичному ключу
5. Секция 1: конвертирует байты в ГБ, сортирует по убыванию
6. Секция 2: сравнивает `last_handshake_unix` с `$(date +%s)` — если разница ≤ 900 секунд (15 мин) — пир активен

**Полный код скрипта** — см. файл [`amnezia_stat.sh`](./amnezia_stat.sh)

---

### Быстрый однострочник (без файла)

Если нужно быстро посмотреть статистику без скачивания файла — скопировать и вставить в терминал:

```bash
clear; echo "= Rooted by VladiMIR | AI = v2026-04-07"; C="\033[1;36m"; Y="\033[1;33m"; R="\033[0m"; printf "${C}┌─────────────────────┬──────────────────────────────────────────┬──────────────┬──────────────┬──────────────┐${R}\n"; printf "${C}│ ${Y}%-19s ${C}│ ${Y}%-40s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│ ${Y}%-12s ${C}│${R}\n" "IP Address" "User Name" "Inbound(GB)" "Outbound(GB)" "Total(GB)"; printf "${C}├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤${R}\n"; J=$(docker exec amnezia-awg cat /opt/amnezia/awg/clientsTable 2>/dev/null); if docker exec amnezia-awg awg show awg0 dump >/dev/null 2>&1; then D="awg show awg0 dump"; else D="wg show wg0 dump"; fi; docker exec amnezia-awg $D | tail -n +2 | awk '{print $1, $6, $7}' | while read k r t; do b=$(echo "$J" | grep -B5 -A5 "$k"); n=$(echo "$b" | grep '"clientName"' | sed 's/.*"clientName": "//;s/".*//' | head -1); ip=$(echo "$b" | grep '"allowedIps"' | sed 's/.*"allowedIps": "//;s/".*//;s|/32||' | head -1); [ -z "$n" ] || [ "$n" == "null" ] && n="Unknown"; [ -z "$ip" ] && ip="N/A"; rg=$(awk -v r="$r" 'BEGIN {printf "%.2f", r/1073741824}'); tg=$(awk -v t="$t" 'BEGIN {printf "%.2f", t/1073741824}'); tt=$(awk -v r="$r" -v t="$t" 'BEGIN {printf "%.2f", (r+t)/1073741824}'); echo "$tt|$ip|$n|$rg|$tg"; done | sort -t'|' -k1 -rn | awk -F'|' -v c="$C" -v y="$Y" -v r="$R" '{si+=$4; so+=$5; st+=$1; printf "%s│ %s%-19s %s│ %s%-40s %s│ %s%-12s %s│ %s%-12s %s│ %s%-12s %s│%s\n", c, r, $2, c, r, $3, c, r, $4, c, r, $5, c, r, $1, c, r} END {printf "%s├─────────────────────┼──────────────────────────────────────────┼──────────────┼──────────────┼──────────────┤%s\n", c, r; printf "%s│ %s%-19s %s│ %s%-40s %s│ %s%-12.2f %s│ %s%-12.2f %s│ %s%-12.2f %s│%s\n", c, y, "TOTAL", c, y, "All Clients Combined", c, y, si, c, y, so, c, y, st, c, r; printf "%s└─────────────────────┴──────────────────────────────────────────┴──────────────┴──────────────┴──────────────┘%s\n", c, r}'
```

---

## Диагностика

### Клиент не подключается

```bash
# Шаг 1: зайти внутрь контейнера
docker exec -it amnezia-awg sh

# Шаг 2: проверить статус пира
wg show
# Ищем нужный пир по IP (allowed ips: 10.8.1.X/32)
# Если нет "latest handshake" или он очень старый — клиент не соединяется

# Шаг 3: выйти из контейнера
exit

# Шаг 4: проверить что порт открыт в UFW
ufw status | grep 42430

# Шаг 5: проверить что порт слушается
ss -ulnp | grep 42430

# Шаг 6: tcpdump — смотрим приходят ли пакеты от клиента (осторожно, много вывода)
tcpdump -i any udp port 42430 -n -c 50
```

**Типичные причины что клиент не подключается:**

| Симптом | Причина | Решение |
|---|---|---|
| Нет handshake, пакеты в tcpdump есть | Неверный ключ или конфиг клиента | Перегенерировать конфиг через Amnezia Client |
| Нет пакетов в tcpdump | Клиент не запущен или неверный IP/порт сервера | Проверить endpoint в конфиге клиента |
| 100% packet loss на ping | Пир за NAT или блокирует ICMP | Норма, UDP туннель работает независимо от ping |
| `wg` not found на хосте | wireguard-tools не установлен на хосте | Использовать `docker exec -it amnezia-awg sh` |
| `awg` not found в контейнере | Версия образа использует `wg` вместо `awg` | Использовать `wg show` внутри контейнера |
| `Error: logging driver does not support reading` | docker logs не поддерживает этот драйвер | Норма, диагностировать через `wg show` |

### Firewall

```bash
# Открыть порт VPN
ufw allow 42430/udp
ufw reload

# Проверить
ufw status numbered | grep 42430
```

---

## Резервное копирование конфигов

```bash
# Скопировать всю папку amnezia
cp -r /opt/amnezia/awg/ /root/backup_amnezia_$(date +%Y%m%d)/

# Или через system_backup.sh
bash /root/system_backup.sh
```

Критически важные файлы для бэкапа:
- `/opt/amnezia/awg/wg0.conf` — все ключи и пиры
- `/opt/amnezia/awg/clientsTable` — имена клиентов
