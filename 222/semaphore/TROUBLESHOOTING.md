# Semaphore — TROUBLESHOOTING & Templates Setup
**Version:** v2026-03-28  
**Server:** xxx.xxx.xxx.222 (222-DE-NetCup, Ubuntu 24, FASTPANEL)  
**Domain:** https://sem.gincz.com  
*= Rooted by VladiMIR | AI =*

---

## ❌ Проблема 1: Кнопка "New Template" в UI не работает

При переходе по ссылке `https://sem.gincz.com/project/1/templates/new`  
**проект полностью пересоздаётся заново**, убивая все настройки.

### ✅ Решение: Создавать Templates через Semaphore REST API по SSH

---

## 📋 Шаг 1 — Авторизация через API

```bash
clear
curl -s -c /tmp/sem_cookies.txt \
  -H "Content-Type: application/json" \
  -d '{"auth":"vlad","password":"***REMOVED***"}' \
  http://localhost:3000/api/auth/login
```

**Ожидаемый результат:** пустой ответ `""` или `{}` = успешный логин.  
Cookies сохраняются в `/tmp/sem_cookies.txt` для следующих запросов.

---

## 📋 Шаг 2 — Получить ID проекта

```bash
curl -s -b /tmp/sem_cookies.txt \
  http://localhost:3000/api/projects | python3 -m json.tool
```

**Результат:**
```json
[{ "id": 1, "name": "VladiMIR_Servers" }]
```
→ Project ID = **1**

---

## 📋 Шаг 3 — Получить ID Inventory, Repository, Environment

```bash
# Inventory
curl -s -b /tmp/sem_cookies.txt http://localhost:3000/api/project/1/inventory | python3 -m json.tool

# Repository
curl -s -b /tmp/sem_cookies.txt http://localhost:3000/api/project/1/repositories | python3 -m json.tool

# Environment
curl -s -b /tmp/sem_cookies.txt http://localhost:3000/api/project/1/environment | python3 -m json.tool
```

**Наши ID (сервер 222):**
| Ресурс | ID | Название |
|--------|----|----------|
| Inventory | 1 | all-servers |
| Repository | 1 | semaphore-playbooks |
| Environment | 2 | servers-env |
| SSH Key | 2 | — |

---

## ❌ Проблема 2: Ошибка `"Invalid app id: "` при создании Template

При создании шаблона через API без поля `"app"` возвращается ошибка:
```json
{ "error": "Invalid app id: " }
```

### ✅ Решение: Добавить `"app":"ansible"` в JSON тело запроса

---

## 📋 Шаг 4 — Создать все 4 Templates через API

```bash
clear
# = Rooted by VladiMIR | AI = v2026-03-28

# Template 1: Ping
curl -s -b /tmp/sem_cookies.txt \
  -H "Content-Type: application/json" \
  -d '{"project_id":1,"inventory_id":1,"repository_id":1,"environment_id":2,"app":"ansible","name":"01 - Ping","playbook":"222/semaphore/playbooks/01_ping.yml","description":"Check connectivity to all servers","type":""}' \
  http://localhost:3000/api/project/1/templates | python3 -m json.tool

# Template 2: System Update
curl -s -b /tmp/sem_cookies.txt \
  -H "Content-Type: application/json" \
  -d '{"project_id":1,"inventory_id":1,"repository_id":1,"environment_id":2,"app":"ansible","name":"02 - System Update","playbook":"222/semaphore/playbooks/02_update.yml","description":"Update all servers","type":""}' \
  http://localhost:3000/api/project/1/templates | python3 -m json.tool

# Template 3: Cleanup
curl -s -b /tmp/sem_cookies.txt \
  -H "Content-Type: application/json" \
  -d '{"project_id":1,"inventory_id":1,"repository_id":1,"environment_id":2,"app":"ansible","name":"03 - Cleanup","playbook":"222/semaphore/playbooks/03_cleanup.yml","description":"Remove unnecessary files","type":""}' \
  http://localhost:3000/api/project/1/templates | python3 -m json.tool

# Template 4: Status
curl -s -b /tmp/sem_cookies.txt \
  -H "Content-Type: application/json" \
  -d '{"project_id":1,"inventory_id":1,"repository_id":1,"environment_id":2,"app":"ansible","name":"04 - Status","playbook":"222/semaphore/playbooks/04_status.yml","description":"Check status of all servers","type":""}' \
  http://localhost:3000/api/project/1/templates | python3 -m json.tool
```

**Ожидаемый результат каждого запроса:**
```json
{
  "id": 5,
  "project_id": 1,
  "name": "01 - Ping",
  "playbook": "222/semaphore/playbooks/01_ping.yml",
  "app": "ansible",
  "tasks": 0
}
```

---

## ❌ Проблема 3: Дубликаты Templates

Если Templates уже существовали (ID 1-4) и создались новые (ID 5-8) —  
в UI будут дубликаты.

### ✅ Решение: Удалить старые через API

```bash
clear
# = Rooted by VladiMIR | AI = v2026-03-28

# Удаляем дубликаты (старые ID 1-4)
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/1
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/2
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/3
curl -s -b /tmp/sem_cookies.txt -X DELETE http://localhost:3000/api/project/1/templates/4
echo "✅ Дубликаты удалены"
```

---

## 📋 Шаг 5 — Проверить список Templates

```bash
curl -s -b /tmp/sem_cookies.txt \
  http://localhost:3000/api/project/1/templates | python3 -m json.tool
```

Или открыть в браузере: **https://sem.gincz.com** → Templates

---

## ❌ Проблема 4: Пароль admin не работает

После установки дефолтный пользователь `admin` с паролем `***REMOVED***`  
не всегда принимался. Создавали нового пользователя `vlad` через Docker:

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

## 📋 Итоговая структура проекта в Semaphore

```
Project: VladiMIR_Servers (ID: 1)
├── Inventory:    all-servers (ID: 1)
│   ├── [main]   server-222 (xxx.xxx.xxx.222)
│   │            server-109 (xxx.xxx.xxx.109)
│   └── [vpn]    8 VPN серверов
├── Repository:  semaphore-playbooks (ID: 1)
│   └── https://github.com/GinCz/Linux_Server_Public (branch: main)
├── Environment: servers-env (ID: 2)
│   └── ansible_python_interpreter, ansible_ssh_common_args
└── Templates:
    ├── 01 - Ping         → 222/semaphore/playbooks/01_ping.yml
    ├── 02 - System Update→ 222/semaphore/playbooks/02_update.yml
    ├── 03 - Cleanup      → 222/semaphore/playbooks/03_cleanup.yml
    └── 04 - Status       → 222/semaphore/playbooks/04_status.yml
```

---

## 🔑 Важные данные

| Параметр | Значение |
|----------|----------|
| URL | https://sem.gincz.com |
| Login | vlad |
| Email | gin@volny.cz |
| Docker container | semaphore |
| Port | 127.0.0.1:3000 |
| DB | BoltDB (embedded) |
| Config volume | semaphore_semaphore_config |
| Data volume | semaphore_data |
| docker-compose | /root/semaphore/docker-compose.yml |
