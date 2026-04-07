# AmneziaWG VPN Server — Setup & Management Guide

> = Rooted by VladiMIR | AI =  
> v2026-04-07

---

## Overview

- **VPN Software:** [AmneziaWG](https://github.com/amnezia-vpn/amneziawg-go) (обфусцированный WireGuard)
- **Runs in:** Docker container `amnezia-awg`
- **Why AmneziaWG:** в России обычный WireGuard блокируется DPI. AmneziaWG добавляет мусорные пакеты (junk) перед handshake, что делает трафик неотличимым от случайного UDP
- **Protocol:** UDP
- **Default subnet:** `10.8.1.0/24`

---

## Servers

| Server | IP | Provider | Port | Purpose |
|---|---|---|---|---|
| VPN-EU-Tatra-9 | 144.124.232.9 | NetCup (Germany) | 42430 | Европа, с Cloudflare |
| VPN-RU | 212.109.223.109 | FastVDS (Russia) | — | Россия, без Cloudflare |

---

## Installation (fresh Ubuntu 24)

### 1. Prerequisites

```bash
apt update && apt upgrade -y
apt install -y docker.io docker-compose curl
systemctl enable docker --now
```

### 2. Install AmneziaWG via Docker

AmneziaWG устанавливается через официальный скрипт или docker-compose.

```bash
# Скачать и запустить установщик
curl -fsSL https://raw.githubusercontent.com/amnezia-vpn/amnezia-client/master/client/server_scripts/amneziawg/start.sh -o /opt/amnezia/start.sh
bash /opt/amnezia/start.sh
```

Или вручную через docker run:

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

### 3. ВАЖНО: порт при установке

> ⚠️ При установке вручную указывать порт **42430** (или любой нестандартный, не 51820).
> Стандартный порт 51820 блокируется в России по номеру порта.
> Нестандартный порт снижает вероятность блокировки.

Значения junk-параметров (обфускация, защита от DPI):
```
Jc = 3
Jmin = 10
Jmax = 50
S1 = 115
S2 = 96
H1-H4 = случайные числа (генерируются автоматически)
```

---

## Container Management

```bash
# Статус контейнера
docker ps | grep amnezia

# Войти в контейнер
docker exec -it amnezia-awg sh

# Внутри контейнера — статус пиров
wg show

# Перезапустить контейнер
docker restart amnezia-awg

# Логи (если logging driver поддерживает)
docker logs amnezia-awg --tail 100

# Конфиг сервера
cat /opt/amnezia/awg/wg0.conf

# Таблица клиентов (имена + ключи)
cat /opt/amnezia/awg/clientsTable
```

---

## Adding a New User

Пользователи добавляются через **Amnezia Client** (десктоп приложение) или вручную.

### Через Amnezia Client (рекомендуется)

1. Открыть Amnezia Client на своём компьютере
2. Подключиться к серверу как администратор
3. `Настройки` → `Пользователи` → `Добавить пользователя`
4. Ввести имя (например: `Pavel_iPhone`)
5. Скачать QR-код или `.conf` файл
6. Передать пользователю

### Вручную (через wg0.conf)

```bash
# 1. Войти в контейнер
docker exec -it amnezia-awg sh

# 2. Сгенерировать ключи
wg genkey | tee /tmp/client_priv | wg pubkey > /tmp/client_pub
cat /tmp/client_pub  # скопировать

# 3. Добавить в конфиг сервера
cat >> /opt/amnezia/awg/wg0.conf << EOF

[Peer]
PublicKey = <client_pub_key>
PresharedKey = <preshared_key>
AllowedIPs = 10.8.1.XX/32
EOF

# 4. Применить изменения
wg syncconf wg0 <(wg-quick strip wg0)
```

### Назначение IP пользователям

| IP | User |
|---|---|
| 10.8.1.4 | Admin Windows |
| 10.8.1.5 | Pavel_iPhone |
| 10.8.1.6 | Pavel_PC |
| 10.8.1.7 | Andr_iPhone |
| 10.8.1.9 | Serg_iPhone |
| 10.8.1.10 | Konstantine_iPhone |
| 10.8.1.11 | ilya_iPhone |
| 10.8.1.12 | Olga_Kre_iPhone |
| 10.8.1.13 | Irina_Ilya_Samsung |
| 10.8.1.14 | Olesya_Valery_iPhone |
| 10.8.1.15 | Elena_Andr_iPhone |
| 10.8.1.16 | Elis_Star_iPhone |
| 10.8.1.17 | Lev_Star_iPhone |
| 10.8.1.18 | Evgenia_iPhone |
| 10.8.1.19 | Admin Android |
| 10.8.1.20 | Valer_iPhone |
| 10.8.1.21 | (резерв) |

---

## Scripts

| Script | Description |
|---|---|
| `amnezia_stat.sh` | Статистика трафика всех пиров + активные за 15 мин |
| `quick_status.sh` | Быстрый статус контейнера |
| `infooo.sh` | Системная информация сервера |
| `motd_server.sh` | MOTD при входе по SSH |
| `system_backup.sh` | Бэкап конфигов |

### Запуск статистики

```bash
bash /root/amnezia_stat.sh
# или если скрипт в PATH:
amnezia_stat
```

---

## Diagnostics

```bash
# Проверить статус всех пиров (последний handshake)
docker exec -it amnezia-awg sh -c "wg show"

# Пир активен если latest handshake < 3 минут назад
# Пир offline если latest handshake отсутствует или > 3 минут

# Проверить UFW
ufw status | grep 42430

# Порт слушается?
ss -ulnp | grep 42430

# tcpdump для отладки (осторожно — много вывода!)
tcpdump -i any udp port 42430 -n -c 50
```

## Firewall (UFW)

```bash
# Разрешить VPN порт
ufw allow 42430/udp
ufw reload
```

---

## Known Issues

| Problem | Cause | Solution |
|---|---|---|
| Клиент не подключается, нет handshake | Неверный конфиг на клиенте | Перегенерировать конфиг через Amnezia Client |
| `wg` not found на хосте | AmneziaWG в Docker, wg-tools не установлен | Использовать `docker exec -it amnezia-awg sh` |
| `awg` not found в контейнере | Версия образа использует `wg` вместо `awg` | Использовать `wg show` внутри контейнера |
| 100% packet loss на ping пира | Пир за NAT или блокирует ICMP | Это нормально, UDP туннель всё равно работает |
| `Error: configured logging driver does not support reading` | docker logs не поддерживается | Нормально, смотреть логи через `wg show` |
