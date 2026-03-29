# Semaphore — УСТАНОВКА, НАСТРОЙКА И TROUBLESHOOTING
**Version:** v2026-03-29  
**Server:** xxx.xxx.xxx.222 (222-DE-NetCup, Ubuntu 24, FASTPANEL)  
**Domain:** https://sem.gincz.com  
**Установка заняла:** 3 дня (27-29 марта 2026)  
*= Rooted by VladiMIR | AI =*

> ⚠️ **Безопасность:** все пароли, IP-адреса, SSH-ключи и приватные данные хранятся в защищённом месте.  
> См. раздел **[🔒 Секретные данные](#-секретные-данные)** в конце документа.

---

## 📌 Что такое Semaphore и зачем он нужен

Ansible Semaphore — это веб-интерфейс для управления серверами через Ansible.  
Вместо ручных SSH команд на каждый сервер — один клик в браузере запускает задачу сразу на всех 10 серверах.

**Адрес:** https://sem.gincz.com  
**Логин:** `<см. секретные данные>`

---

## 🏗️ АРХИТЕКТУРА

```
sem.gincz.com
    │
    ▼
Nginx (FASTPANEL) — reverse proxy → 127.0.0.1:3000
    │
    ▼
Docker контейнер: semaphore (semaphoreui/semaphore:latest)
    │
    ├── BoltDB (встроенная БД, volume: semaphore_semaphore_config)
    ├── SSH ключ → все 10 серверов
    └── GitHub: github.com/GinCz/Linux_Server_Public (плейбуки)
```

**10 серверов в управлении:**
| Имя | IP | Роль |
|-----|----|------|
| server-222 | xxx.xxx.xxx.222 | Главный (DE, NetCup) — здесь живёт Semaphore |
| server-109 | xxx.xxx.xxx.109 | Главный (RU, FastVDS) |
| vpn-tatra-9 | xxx.xxx.xxx.9 | VPN + Uptime Kuma |
| vpn-stolb-24 | xxx.xxx.xxx.24 | VPN + AdGuard Home |
| vpn-alex-47 | xxx.xxx.xxx.47 | VPN |
| vpn-4ton-237 | xxx.xxx.xxx.237 | VPN |
| vpn-shahin-227 | xxx.xxx.xxx.227 | VPN |
| vpn-ilya-176 | xxx.xxx.xxx.176 | VPN |
| vpn-pilik-178 | xxx.xxx.xxx.178 | VPN |
| vpn-so-38 | xxx.xxx.xxx.38 | VPN |

---

## 📦 УСТАНОВКа SEMAPHORE В DOCKER

### docker-compose.yml
```yaml
# /root/semaphore/docker-compose.yml
version: '3.8'
services:
  semaphore:
    image: semaphoreui/semaphore:latest
    container_name: semaphore
    restart: always
    ports:
      - "127.0.0.1:3000:3000"
    volumes:
      - semaphore_data:/var/lib/semaphore
      - semaphore_semaphore_config:/etc/semaphore
      - /root/.ssh:/root/.ssh:ro
    environment:
      SEMAPHORE_DB_DIALECT: bolt
      SEMAPHORE_ADMIN: admin
      SEMAPHORE_ADMIN_PASSWORD: <см. секретные данные>
      SEMAPHORE_ADMIN_NAME: Administrator
      SEMAPHORE_ADMIN_EMAIL: <см. секретные данные>
      SEMAPHORE_ACCESS_KEY_ENCRYPTION: <случайная строка base64, хранить локально!>
volumes:
  semaphore_data:
  semaphore_semaphore_config:
```

```bash
cd /root/semaphore
docker compose up -d
```

---

## ❌ ПРОБЛЕМА 1: Пароль admin не работает после установки

**Симптом:** логин `admin` — ошибка авторизации.

**Причина:** при первом запуске с BoltDB пользователь иногда не создаётся корректно.

### ✅ Решение: создать нового пользователя через Docker

```bash
docker stop semaphore

docker run --rm \
  -v semaphore_semaphore_config:/etc/semaphore \
  semaphoreui/semaphore:latest \
  semaphore user add \
  --login <логин> \
  --name "<имя>" \
  --email "<email>" \
  --password "<пароль>" \
  --admin

docker start semaphore
```

---

## ❌ ПРОБЛЕМА 2: Кнопка "New Template" в UI пересоздаёт проект

**Симптом:** при переходе на `/project/1/templates/new` — проект полностью пересоздаётся, все настройки теряются.

**Причина:** баг в версии Semaphore UI.

### ✅ Решение: создавать Templates через REST API

```bash
# Шаг 1 — авторизация
curl -s -c /tmp/sem_cookies.txt \
  -H "Content-Type: application/json" \
  -d '{"auth":"<логин>","password":"<пароль>"}' \
  http://localhost:3000/api/auth/login

# Шаг 2 — получить ID ресурсов
curl -s -b /tmp/sem_cookies.txt http://localhost:3000/api/project/1/inventory | python3 -m json.tool
curl -s -b /tmp/sem_cookies.txt http://localhost:3000/api/project/1/repositories | python3 -m json.tool
curl -s -b /tmp/sem_cookies.txt http://localhost:3000/api/project/1/environment | python3 -m json.tool
```

**Наши ID:**
| Ресурс | ID |
|--------|----|  
| Inventory | 1 |
| Repository | 1 |
| Environment | 2 |
| SSH Key | 2 |

```bash
# Шаг 3 — создать Template
curl -s -b /tmp/sem_cookies.txt \
  -H "Content-Type: application/json" \
  -d '{"project_id":1,"inventory_id":1,"repository_id":1,"environment_id":2,
       "app":"ansible","name":"05 - Restart VPN",
       "playbook":"222/semaphore/playbooks/05_restart_vpn.yml",
       "description":"Restart amnezia-awg on all servers","type":""}' \
  http://localhost:3000/api/project/1/templates | python3 -m json.tool
```

> **ВАЖНО:** поле `"app":"ansible"` обязательно!

### Альтернатива: через UI
В новых версиях Semaphore кнопка работает нормально. Выбирать **App = Ansible**.

---

## ❌ ПРОБЛЕМА 3: `"Invalid app id: "` при создании Template через API

**Причина:** не передано поле `"app"` в JSON.

### ✅ Решение: добавить `"app":"ansible"` в тело запроса

---

## ❌ ПРОБЛЕМА 4: Дубликаты Templates в UI

### ✅ Решение: удалить старые через API

```bash
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/1
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/2
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/3
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/4
```

---

## ❌ ПРОБЛЕМА 5: Nginx 502 Bad Gateway

**Причины и решения:**

1. **Semaphore не запущен:**
```bash
docker ps | grep semaphore
docker start semaphore
```

2. **Nginx не проксирует:**
```bash
cat /etc/nginx/conf.d/sem.gincz.com.conf
# Должно: proxy_pass http://127.0.0.1:3000;
nginx -t && systemctl reload nginx
```

3. **FASTPANEL перезаписал конфиг:** прописать proxy_pass прямо в FASTPANEL настройках сайта.

---

## ❌ ПРОБЛЕМА 6: SSL не применяется

```nginx
server {
    listen 443 ssl;
    server_name sem.gincz.com;
    ssl_certificate     /etc/letsencrypt/live/sem.gincz.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sem.gincz.com/privkey.pem;
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
```

---

## ❌ ПРОБЛЕМА 7: SSH ключ не работает в Docker

```bash
ls -la /root/.ssh/
chmod 600 /root/.ssh/id_rsa
ssh -i /root/.ssh/id_rsa root@<IP сервера> "echo OK"
```

---

## ❌ ПРОБЛЕМА 8: rc:1 + длинный `cmd:` в логе

**Причина:** `docker image inspect` на несуществующий образ возвращает код 1.

### ✅ Решение:
- `docker ps` без флага `-a` — показывать только **запущенные** контейнеры
- Проверять `$RAW` перед делением

---

## ❌ ПРОБЛЕМА 9: `Disk: 5.0G/"$2"` — сломанный awk

**Причина:** YAML `|` конфликтует с экранированием awk.

```yaml
# НЕПРАВИЛЬНО:
  ansible.builtin.shell: df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}'

# ПРАВИЛЬНО:
  ansible.builtin.shell: >
    df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}'
  args:
    executable: /bin/bash
```

---

## ❌ ПРОБЛЕМА 10: `0 MB0 MB` — двойной вывод размера

```bash
# НЕПРАВИЛЬНО:
SIZE_BYTES=$($DOCKER image inspect "$IMAGE" --format '{{.Size}}' 2>/dev/null || echo 0)

# ПРАВИЛЬНО:
RAW=$($DOCKER image inspect "$IMAGE" --format '{{.Size}}' 2>/dev/null)
if [ -n "$RAW" ] && [ "$RAW" -gt 0 ] 2>/dev/null; then
  SIZE=$(echo "$RAW" | awk '{printf "%.0f MB", $1/1024/1024}')
else
  SIZE="n/a"
fi
```

---

## 📋 ИТОГОВАЯ СТРУКТУРА

```
Project: VladiMIR_Servers (ID: 1)
├── Inventory:    all-servers (ID: 1)
├── Repository:   Linux_Server_Public (ID: 1)
├── Environment:  servers-env (ID: 2)
└── Templates:
    ├── 01 - Ping
    ├── 02 - System Update
    ├── 03 - Cleanup
    ├── 04 - Status
    ├── 05 - Restart VPN
    └── 06 - Disk Usage
```

**Путь к плейбукам:** `222/semaphore/playbooks/`

---

## 🔒 СЕКРЕТНЫЕ ДАННЫЕ

> ⚠️ Данный раздел — только для владельца сервера.  
> НИКОГДА не публикуйте реальные пароли, IP и ключи в публичных репозиториях!

| Параметр | Где хранится | Описание |
|----------|-----------------|----------|
| URL Semaphore | публично | https://sem.gincz.com |
| Логин Semaphore | локально / память | логин пользователя Semaphore |
| Пароль Semaphore | локально / память | никому не передавать |
| IP серверов | локально / inventory | известны хозяину |
| SSH приватный ключ | /root/.ssh/id_rsa | никому не передавать |
| SSH публичный ключ | /root/.ssh/id_rsa.pub | можно делиться |
| SEMAPHORE_ACCESS_KEY_ENCRYPTION | /root/semaphore/.env | без него не запустится после переустановки |
| Email | локально | не хранить в Git |
| Пароли SSH серверов | не актуально (вход по ключу) | root-пароль используется не всегда |

### Где хранить секреты:
- Файл `/root/semaphore/.env` на сервере (никогда не добавлять в Git)
- Менеджер паролей: Bitwarden, KeePass, 1Password
- Inventory файл с IP: можно хранить в **приватном** репозитории

---

## 🔄 КАК ДОБАВИТЬ НОВЫЙ TEMPLATE

1. Создать `222/semaphore/playbooks/NN_name.yml` в GitHub
2. Semaphore UI → Templates → **New Template**
3. Заполнить: Name, **App = Ansible**, Playbook path, Inventory, Repository
4. Save → Run

> Шаблоны НЕ создаются автоматически из GitHub — только вручную через UI.

---

## 🛠️ ПОЛЕЗНЫЕ КОМАНДЫ

```bash
# Статус Semaphore
docker ps | grep semaphore
docker logs semaphore --tail=50
docker restart semaphore

# Обновить образ
cd /root/semaphore && docker compose pull && docker compose up -d

# Быстрая проверка всех серверов с 222
for H in <IP1> <IP2> <IP3>; do
  echo -n "$H → "
  ssh -o ConnectTimeout=5 root@$H "uptime -p"
done
```
