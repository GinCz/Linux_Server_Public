# Semaphore — УСТАНОВКА, НАСТРОЙКА И TROUBLESHOOTING
**Version:** v2026-03-29  
**Server:** xxx.xxx.xxx.222 (222-DE-NetCup, Ubuntu 24, FASTPANEL)  
**Domain:** https://sem.gincz.com  
**Установка заняла:** 3 дня (27-29 марта 2026)  
*= Rooted by VladiMIR | AI =*

---

## 📌 Что такое Semaphore и зачем он нужен

Ansible Semaphore — это веб-интерфейс для управления серверами через Ansible.  
Вместо ручных SSH команд на каждый сервер — один клик в браузере запускает задачу сразу на всех 10 серверах.

**Адрес:** https://sem.gincz.com  
**Логин:** `vlad` / `***REMOVED***`

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

## 📦 УСТАНОВКА SEMAPHORE В DOCKER

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
      SEMAPHORE_ADMIN_PASSWORD: ***REMOVED***
      SEMAPHORE_ADMIN_NAME: Administrator
      SEMAPHORE_ADMIN_EMAIL: gin@volny.cz
      SEMAPHORE_ACCESS_KEY_ENCRYPTION: <случайная строка base64>
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

**Симптом:** логин `admin` / `***REMOVED***` — ошибка авторизации.

**Причина:** при первом запуске с BoltDB пользователь иногда не создаётся корректно.

### ✅ Решение: создать нового пользователя `vlad` через Docker

```bash
# Остановить контейнер
docker stop semaphore

# Создать пользователя vlad
docker run --rm \
  -v semaphore_semaphore_config:/etc/semaphore \
  semaphoreui/semaphore:latest \
  semaphore user add \
  --login vlad \
  --name "VladiMIR" \
  --email "gin@volny.cz" \
  --password "***REMOVED***" \
  --admin

# Запустить контейнер
docker start semaphore
```

**Логин:** `vlad` / `***REMOVED***`

---

## ❌ ПРОБЛЕМА 2: Кнопка "New Template" в UI пересоздаёт проект

**Симптом:** при переходе на `/project/1/templates/new` — проект полностью пересоздаётся, все настройки теряются.

**Причина:** баг в версии Semaphore UI при определённых конфигурациях.

### ✅ Решение: создавать Templates через REST API по SSH

```bash
# Шаг 1 — авторизация
curl -s -c /tmp/sem_cookies.txt \
  -H "Content-Type: application/json" \
  -d '{"auth":"vlad","password":"***REMOVED***"}' \
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
# Шаг 3 — создать Template через API
curl -s -b /tmp/sem_cookies.txt \
  -H "Content-Type: application/json" \
  -d '{"project_id":1,"inventory_id":1,"repository_id":1,"environment_id":2,
       "app":"ansible","name":"05 - Restart VPN",
       "playbook":"222/semaphore/playbooks/05_restart_vpn.yml",
       "description":"Restart amnezia-awg on all servers","type":""}' \
  http://localhost:3000/api/project/1/templates | python3 -m json.tool
```

> **ВАЖНО:** поле `"app":"ansible"` обязательно! Без него → ошибка `"Invalid app id: "`

### Альтернатива (проще): создавать через UI кнопкой "New Template"
В новых версиях Semaphore (после обновления) кнопка работает нормально.
При создании выбирать **App = Ansible**.

---

## ❌ ПРОБЛЕМА 3: Ошибка `"Invalid app id: "` при создании Template через API

**Симптом:** API возвращает `{ "error": "Invalid app id: " }`

**Причина:** не передано поле `"app"` в JSON.

### ✅ Решение: добавить `"app":"ansible"` в тело запроса

---

## ❌ ПРОБЛЕМА 4: Дубликаты Templates в UI

**Симптом:** в списке шаблонов появились двойники (01-Ping дважды и т.д.)

**Причина:** Templates создавались несколько раз через API.

### ✅ Решение: удалить старые через API

```bash
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/1
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/2
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/3
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/4
echo "Дубликаты удалены"
```

---

## ❌ ПРОБЛЕМА 5: Nginx 502 Bad Gateway после настройки

**Симптом:** https://sem.gincz.com возвращает 502.

**Причины и решения:**

1. **Semaphore контейнер не запущен:**
```bash
docker ps | grep semaphore
docker start semaphore  # если не запущен
```

2. **Nginx не проксирует на 127.0.0.1:3000:**
```bash
# Проверить конфиг
cat /etc/nginx/conf.d/sem.gincz.com.conf
# Должно быть: proxy_pass http://127.0.0.1:3000;
nginx -t && systemctl reload nginx
```

3. **FASTPANEL перезаписал nginx конфиг:**  
FASTPANEL при обновлении сайта перезаписывает `.conf` файл.  
Решение — прописать proxy_pass прямо в FASTPANEL настройках сайта.

---

## ❌ ПРОБЛЕМА 6: SSL сертификат не применяется к sem.gincz.com

**Симптом:** браузер показывает "Небезопасное соединение" или сертификат другого домена.

**Причина:** FASTPANEL выдаёт сертификат но не прописывает его в nginx конфиг для проксируемых доменов.

### ✅ Решение: прописать SSL вручную

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

## ❌ ПРОБЛЕМА 7: SSH ключ не работает внутри Docker контейнера

**Симптом:** Ansible не может подключиться к серверам, ошибка `Permission denied (publickey)`.

**Причина:** SSH ключ в `/root/.ssh/` монтируется в контейнер как `readonly (:ro)` — это нормально.  
Но если ключ создан с неправильными правами или не тот ключ указан в Semaphore.

### ✅ Решение:
```bash
# Проверить что ключ есть
ls -la /root/.ssh/

# Проверить права (должно быть 600)
chmod 600 /root/.ssh/id_rsa

# Тест подключения вручную
ssh -i /root/.ssh/id_rsa root@xxx.xxx.xxx.47 "echo OK"
```

В Semaphore → Key Store → убедиться что SSH Key указывает на правильный ключ.

---

## ❌ ПРОБЛЕМА 8: Плейбук падает с rc:1 — длинный `cmd:` в логе

**Симптом:** при ошибке в плейбуке Ansible выводит полный текст shell скрипта в лог (`cmd:` блок).  
Лог становится огромным и нечитаемым.

**Причина:** Ansible при `FAILED` всегда показывает `cmd:` — это нормальное поведение.  
Проблема была в самом скрипте — `docker image inspect` на несуществующий образ возвращает код 1.

### ✅ Решение для `04_status.yml`:
- Убрать флаг `-a` из `docker ps` — показывать только **запущенные** контейнеры
- Проверять `SIZE_BYTES` перед делением: `if [ -n "$RAW" ] && [ "$RAW" -gt 0 ]`
- Использовать YAML `>` (folded) для однострочных awk команд вместо `|` (literal)

---

## ❌ ПРОБЛЕМА 9: `Disk /  : 5.0G/"$2" ("$5" used)` — сломанный вывод

**Симптом:** в выводе плейбука диск показывается как `5.0G/"$2" ("$5" used)` вместо реального значения.

**Причина:** YAML блок `|` (literal block) передаёт строку как есть, включая `\"` — экранирование конфликтует с awk.

### ✅ Решение: использовать YAML `>` (folded scalar) для awk команд

```yaml
# НЕПРАВИЛЬНО:
- name: Get disk usage
  ansible.builtin.shell: df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}'

# ПРАВИЛЬНО:
- name: Get disk usage
  ansible.builtin.shell: >
    df -h / | tail -1 | awk '{print $3"/"$2" ("$5" used)"}'
  args:
    executable: /bin/bash
```

---

## ❌ ПРОБЛЕМА 10: Размер контейнера `0 MB0 MB` — двойной вывод

**Симптом:** `Размер : 0 MB0 MB` в выводе статуса.

**Причина:** конструкция `$(команда || echo 0)` — если команда возвращает пустой результат И echo 0, то SIZE_BYTES = `0`, а awk превращает это в `0 MB`. Но если образ реально пустой — получается двойной вывод.

### ✅ Решение: явная проверка значения

```bash
RAW=$($DOCKER image inspect "$IMAGE" --format '{{.Size}}' 2>/dev/null)
if [ -n "$RAW" ] && [ "$RAW" -gt 0 ] 2>/dev/null; then
  SIZE=$(echo "$RAW" | awk '{printf "%.0f MB", $1/1024/1024}')
else
  SIZE="n/a"
fi
```

---

## 📋 ИТОГОВАЯ СТРУКТУРА ПРОЕКТА

```
Project: VladiMIR_Servers (ID: 1)
├── Inventory:    all-servers (ID: 1)  — статический, все 10 серверов
├── Repository:   Linux_Server_Public (ID: 1)  — github.com/GinCz/Linux_Server_Public
├── Environment:  servers-env (ID: 2)
└── Templates:
    ├── 01 - Ping          → playbooks/01_ping.yml
    ├── 02 - System Update → playbooks/02_update.yml
    ├── 03 - Cleanup       → playbooks/03_cleanup.yml
    ├── 04 - Status        → playbooks/04_status.yml
    ├── 05 - Restart VPN   → playbooks/05_restart_vpn.yml
    └── 06 - Disk Usage    → playbooks/06_disk_usage.yml
```

**Путь к плейбукам в репозитории:** `222/semaphore/playbooks/`

---

## 🔑 ВАЖНЫЕ ДАННЫЕ

| Параметр | Значение |
|----------|----------|
| URL | https://sem.gincz.com |
| Login | vlad |
| Password | ***REMOVED*** |
| Email | gin@volny.cz |
| Docker container | semaphore |
| Port | 127.0.0.1:3000 |
| DB | BoltDB (embedded) |
| Config volume | semaphore_semaphore_config |
| Data volume | semaphore_data |
| docker-compose | /root/semaphore/docker-compose.yml |
| SSH ключи | /root/.ssh/ (монтируются в контейнер) |

---

## 🔄 КАК ДОБАВИТЬ НОВЫЙ TEMPLATE (быстро)

1. Создать файл `222/semaphore/playbooks/NN_name.yml` в GitHub
2. В Semaphore UI → Templates → **New Template**
3. Заполнить: Name, **App = Ansible**, Playbook path, Inventory = all-servers, Repository = Linux_Server_Public
4. Save → Run

> Шаблоны НЕ создаются автоматически из GitHub — только вручную через UI.

---

## 🛠️ ПОЛЕЗНЫЕ КОМАНДЫ

```bash
# Статус контейнера
docker ps | grep semaphore

# Логи Semaphore
docker logs semaphore --tail=50

# Перезапуск
docker restart semaphore

# Обновить образ
cd /root/semaphore
docker compose pull
docker compose up -d

# Управление всеми серверами с 222 (пример)
for H in xxx.xxx.xxx.109 xxx.xxx.xxx.47 xxx.xxx.xxx.237 xxx.xxx.xxx.9 \
         xxx.xxx.xxx.227 xxx.xxx.xxx.24 xxx.xxx.xxx.176 xxx.xxx.xxx.178 xxx.xxx.xxx.38; do
  echo -n "$H → "
  ssh -o ConnectTimeout=5 root@$H "uptime -p"
done
```
