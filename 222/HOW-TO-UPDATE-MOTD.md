# MOTD & Aliases — Полная архитектура сервера 222-DE-NetCup

> Version: v2026.05.21
> = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =

---

## ⚡ Быстрый справочник (читай это ПЕРВЫМ)

| Что нужно сделать | Команда |
|---|---|
| Добавить / убрать алиас | Редактируй `222/.bashrc` в репо, затем `load` |
| Изменить текст MOTD (меню) | Редактируй `222/motd_server.sh`, затем `load` |
| Применить изменения | `load` (на сервере 222) |
| Установить с нуля | см. раздел «Установка с нуля» ниже |
| Проверить что показывается при входе | `bash /root/Linux_Server_Public/222/motd_server.sh` |
| MOTD показывается 2 раза | см. раздел «Частые ошибки» ниже |
| MOTD не показывается совсем | см. раздел «Частые ошибки» ниже |

---

## 📁 Какой файл за что отвечает

```
/root/Linux_Server_Public/
└── 222/
    ├── motd_server.sh        ← Цветное MOTD-меню (рисует баннер при входе)
    ├── .bash_profile         ← Загружается при SSH-логине → source .bashrc
    ├── .bashrc               ← ГЛАВНЫЙ ФАЙЛ: PS1 + MOTD-логика + ВСЕ алиасы
    └── HOW-TO-UPDATE-MOTD.md ← Этот файл

/root/                        ← Файлы НА СЕРВЕРЕ (не в репо)
├── .bash_profile             ← КОПИЯ из репо 222/.bash_profile
└── .bashrc                   ← КОПИЯ из репо 222/.bashrc
```

**Отличие от 109:** на 222 нет отдельного `server_222.sh` и нет копии в `/etc/profile.d/`.
Всё работает через `/root/.bashrc` напрямую — MOTD и алиасы в одном файле.

---

## 🔄 Как работает SSH-логин (порядок загрузки)

```
SSH подключение
      │
      ├─► Ubuntu читает /root/.bash_profile
      │         └─► source /root/.bashrc
      │                   ├─► [1] PS1='yellow prompt root@222-DE-NetCup'
      │                   ├─► [2] MOTD-блок (показывает ОДИН РАЗ за сессию):
      │                   │         _MOTD_FLAG="/tmp/motd_shown_${SSH_CLIENT// /_}"
      │                   │         если SSH_CONNECTION есть И флаг-файл НЕ существует:
      │                   │           touch $_MOTD_FLAG
      │                   │           bash /root/Linux_Server_Public/222/motd_server.sh
      │                   └─► [3] Загружаются все alias (sos, save, load, tr, ...)
      │
      └─► Промпт root@222-DE-NetCup:~# (жёлтый)
```

**Ключевые правила:**
- MOTD показывается через флаг-файл `/tmp/motd_shown_*` — ровно ОДИН раз за SSH-сессию
- При новом SSH-подключении PID меняется → флаг другой → MOTD снова показывается
- В `/etc/profile.d/` на 222 **нет файлов MOTD** — в этом принципиальное отличие от 109
- Файлы из `/etc/profile.d/` выполняются через `/etc/profile`, но когда есть `~/.bash_profile`, Ubuntu читает его ВМЕСТО `/etc/profile`

---

## ✏️ Как добавить новый алиас

1. Открой `222/.bashrc` в репо
2. Найди нужную секцию (NAVIGATION / GIT / SECURITY / SOS / ...)
3. Добавь строку: `alias mycommand='bash /root/Linux_Server_Public/222/my_script.sh'`
4. `save` → `load` на сервере

**Если хочешь чтобы алиас отображался в MOTD-меню** — также добавь строку в `motd_server.sh` в нужном блоке `echo -e`.

---

## ✏️ Как изменить текст MOTD (меню)

1. Открой `222/motd_server.sh`
2. Отредактируй нужные строки `echo -e`
3. `save` → `load` на сервере

Цвета в скрипте: `$G`=green(команды), `$Y`=yellow(заголовки), `$C`=cyan(рамки), `$W`=white(значения), `$X`=reset.

---

## 🔧 Установка с нуля (новый сервер или после сброса)

```bash
# 1. Клонировать репо
git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public

# 2. Скопировать .bash_profile и .bashrc на сервер
cp /root/Linux_Server_Public/222/.bash_profile /root/.bash_profile
cp /root/Linux_Server_Public/222/.bashrc /root/.bashrc

# 3. Перезайти по SSH — всё работает
```

Никаких установок в `/etc/profile.d/` не нужно — в отличие от сервера 109.

---

## ❌ Частые ошибки и их причины

### MOTD показывается 2 раза

**Причина A:** Кто-то создал файл в `/etc/profile.d/` с вызовом MOTD или `infooo`.

**Диагностика (одна команда):**
```bash
grep -r "infooo\|motd\|infooo" /etc/profile.d/ /root/.bashrc /root/.bash_profile 2>/dev/null && ls -la /etc/profile.d/
```
Должны быть только стандартные файлы Ubuntu: `01-locale-fix.sh`, `bash_completion.sh`, `gawk.*`
Любой лишний файл типа `motd_custom.sh`, `motd_server.sh`, `infooo*` — **удалить**.

**Исправление:**
```bash
rm /etc/profile.d/motd_custom.sh   # или как называется лишний файл
```

**Причина B:** В `/root/.bashrc` на сервере есть старая прямая строка `bash ~/...infooo.sh` вне флаг-блока.

**Исправление:**
```bash
cp /root/Linux_Server_Public/222/.bashrc /root/.bashrc
source /root/.bashrc
```

---

### MOTD не показывается совсем

**Причина A:** `/root/.bashrc` на сервере устарел или перезаписан вручную.
```bash
diff /root/.bashrc /root/Linux_Server_Public/222/.bashrc
# Если есть различия:
cp /root/Linux_Server_Public/222/.bashrc /root/.bashrc
```

**Причина B:** Флаг-файл завис (редко).
```bash
rm -f /tmp/motd_shown_*
# Перезайти по SSH
```

**Причина C:** `motd_server.sh` не найден.
```bash
ls -la /root/Linux_Server_Public/222/motd_server.sh
# Если нет — git pull
cd /root/Linux_Server_Public && git pull --rebase
```

---

### Алиасы не работают после SSH-логина

```bash
cp /root/Linux_Server_Public/222/.bashrc /root/.bashrc
source /root/.bashrc
```

---

## 📋 Проверочный чеклист после любых изменений

```bash
# 1. Изменения применены?
load

# 2. MOTD работает?
bash /root/Linux_Server_Public/222/motd_server.sh

# 3. Алиасы работают?
type sos
type load
type save

# 4. .bashrc актуален?
diff /root/.bashrc /root/Linux_Server_Public/222/.bashrc
# Вывод должен быть пустым

# 5. Нет лишних файлов в /etc/profile.d/ ?
ls -la /etc/profile.d/
# Только стандартные Ubuntu-файлы
```

---

## ⚠️ Что НЕЛЬЗЯ делать

- ❌ Не создавать файлы MOTD в `/etc/profile.d/` — на 222 это не нужно и вызовет дублирование
- ❌ Не добавлять `bash ...infooo.sh` напрямую в `/root/.bashrc` — только через флаг-блок
- ❌ Не редактировать `/root/.bashrc` на сервере вручную — только через репо и `cp`
- ❌ Не путать архитектуру 222 с архитектурой 109 — они разные (см. таблицу ниже)

---

## 🔁 Сравнение архитектур всех серверов

| | 222-DE-NetCup | 109-RU-FastVDS | VPN-серверы |
|---|---|---|---|
| **Главный файл** | `222/.bashrc` | `109/server_109.sh` | `VPN/.bashrc` |
| **MOTD-файл** | `222/motd_server.sh` | `109/server_109.sh` | `VPN/motd_server.sh` |
| **Алиасы** | в `222/.bashrc` | в `server_109.sh` → `_aliases_109()` | в `VPN/.bashrc` |
| **`/etc/profile.d/`** | ❌ не используется | ✅ `motd_server.sh` копируется сюда | ❌ не используется |
| **Защита от дублирования** | флаг-файл `/tmp/motd_shown_*` | ENTRY POINT (bash vs source) | флаг-файл `/tmp/motd_shown_*` |
| **Команда обновить всё** | `load` (git pull) | `load` (git pull + `--install`) | `load` (git pull + deploy) |
| **Цвет промпта** | 🟡 жёлтый | 🩷 розовый | 🩵 бирюзовый |
