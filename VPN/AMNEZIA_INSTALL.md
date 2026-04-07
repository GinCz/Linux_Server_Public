# AmneziaWG — Установка нового VPN-сервера

> = Rooted by VladiMIR | AI =  
> v2026-04-07

---

## Порт

> ⚠️ **Порт всегда: `123`**  
> При установке через Amnezia Client в поле «Порт WireGuard» вводим вручную: **123**  
> Стандартный порт 51820 блокируется в России по номеру порта — никогда его не использовать.

---

## Шаг 1 — Подготовка сервера (Ubuntu 24)

```bash
apt update && apt upgrade -y
apt install -y docker.io curl git mc
systemctl enable docker --now
```

## Шаг 2 — Клонировать репозиторий

```bash
cd /root
git clone https://github.com/GinCz/Linux_Server_Public.git
```

## Шаг 3 — Настроить .bashrc

```bash
cp /root/Linux_Server_Public/VPN/.bashrc /root/.bashrc
source /root/.bashrc
```

Проверить что алиасы работают:
```bash
aw       # статистика WireGuard
00       # clear
la       # список с hidden
mc       # Midnight Commander
load     # git pull
save     # git push
audit    # аудит сервера
```

## Шаг 4 — Установить AmneziaWG через Amnezia Client

1. Открыть **Amnezia Client** на своём компьютере (Windows/Mac/Linux)
2. `Добавить сервер` → ввести IP, порт SSH (обычно 22), логин `root`, пароль
3. Протокол: **AmneziaWG**
4. ⚠️ **Порт WireGuard: `123`** — ввести вручную, не оставлять default!
5. Нажать `Установить` — клиент сам поставит Docker, скачает образ, создаст контейнер
6. После установки — добавить первого пользователя прямо в Amnezia Client

**Что создаётся автоматически:**
```
/opt/amnezia/awg/wg0.conf        # конфиг интерфейса + все пиры
/opt/amnezia/awg/clientsTable    # имена клиентов (JSON)
```

**Docker-контейнер:**
```bash
docker ps | grep amnezia   # проверить что запущен
```

## Шаг 5 — Проверить что порт открыт в UFW

```bash
ufw allow 123/udp
ufw reload
ufw status | grep 123
```

Проверить что порт слушается:
```bash
ss -ulnp | grep 123
```

Ожидаемый вывод:
```
udp  UNCONN  0  0  0.0.0.0:123  0.0.0.0:*  users:(("docker-proxy",...
```

## Шаг 6 — Первый запуск статистики

```bash
aw
```

Ожидаемый вывод — таблица со всеми пирами и блок «Active peers (last 15 minutes)».

Если `aw` не работает:
```bash
# Проверить путь скрипта
ls /root/Linux_Server_Public/VPN/amnezia_stat.sh

# Перезагрузить алиасы
source /root/.bashrc

# Запустить вручную
bash /root/Linux_Server_Public/VPN/amnezia_stat.sh
```

---

## Добавление нового пользователя

1. Открыть Amnezia Client
2. Выбрать нужный сервер
3. `Настройки` → `Пользователи` → `Добавить`
4. Имя в формате: `Имя_Устройство` (например: `Pavel_iPhone`, `Anna_PC`)
5. Скачать QR-код → отсканировать приложением Amnezia на телефоне

Следующий свободный IP автоматически назначается из `10.8.1.x`.

---

## Диагностика

```bash
# Войти в контейнер
docker exec -it amnezia-awg sh

# Статус всех пиров
wg show

# Пир активен если «latest handshake: Xs ago»
# Пир offline если нет строки «latest handshake»

# Посмотреть порт
ss -ulnp | grep 123

# Проверить UFW
ufw status numbered | grep 123
```

| Проблема | Причина | Решение |
|---|---|---|
| `aw: command not found` | .bashrc не загружен | `source /root/.bashrc` |
| Пустая таблица в `aw` | Контейнер не запущен | `docker start amnezia-awg` |
| Клиент не подключается | Неверный порт в конфиге клиента | Проверить что в конфиге порт 123 |
| `awg: not found` в контейнере | Версия образа использует wg | Использовать `wg show` внутри |
| Нет handshake, tcpdump пустой | Порт закрыт в UFW | `ufw allow 123/udp && ufw reload` |
