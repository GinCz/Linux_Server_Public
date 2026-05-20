# MOTD & Aliases — Полная архитектура сервера 109-RU-FastVDS

> Version: v2026.05.21
> = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =

---

## ⚡ Быстрый справочник (читай это ПЕРВЫМ)

| Что нужно сделать | Команда |
|---|---|
| Добавить / убрать алиас | Редактируй `_aliases_109()` в `server_109.sh`, затем `load` |
| Изменить текст MOTD (меню) | Редактируй `_motd_109()` в `server_109.sh`, затем `load` |
| Применить изменения после редактирования | `load` (на сервере 109) |
| Полная переустановка с нуля | `bash /root/Linux_Server_Public/109/server_109.sh --install` |
| Проверить что показывается при входе | `bash /etc/profile.d/motd_server.sh` |
| MOTD показывается 2 раза | см. раздел «Частые ошибки» ниже |
| MOTD не показывается совсем | см. раздел «Частые ошибки» ниже |

---

## 📁 Какой файл за что отвечает

```
/root/Linux_Server_Public/
└── 109/
    ├── server_109.sh         ← ГЛАВНЫЙ ФАЙЛ. Всё в нём: MOTD + алиасы + MC меню
    ├── .bash_profile         ← Загружается при SSH-логине. Показывает MOTD + грузит алиасы
    ├── .bashrc               ← source server_109.sh (sourced-режим → только алиасы)
    └── HOW-TO-UPDATE-MOTD.md ← Этот файл

/root/                        ← Файлы НА СЕРВЕРЕ (не в репо)
├── .bash_profile             ← КОПИЯ из репо 109/.bash_profile
└── .bashrc                   ← КОПИЯ из репо 109/.bashrc

/etc/profile.d/
└── motd_server.sh            ← КОПИЯ server_109.sh. Устанавливается через --install
                                 При SSH-логине Ubuntu запускает этот файл → MOTD
```

**Отличие от 222:** на 109 используется `/etc/profile.d/motd_server.sh` для показа MOTD.
Алиасы загружаются отдельно через `source` из `.bashrc`. ENTRY POINT в `server_109.sh`
различает режимы запуска и никогда не делает лишнего.

---

## 🔄 Как работает SSH-логин (порядок загрузки)

```
SSH подключение
      │
      ├─► Ubuntu читает /root/.bash_profile
      │         │
      │         ├─► [1] bash /etc/profile.d/motd_server.sh
      │         │         └─► ENTRY POINT: executed-режим → _motd_109() → показывает меню ✅
      │         │
      │         └─► [2] source /root/Linux_Server_Public/109/.bashrc
      │                   └─► source server_109.sh (sourced-режим)
      │                             └─► ENTRY POINT: sourced-режим → _aliases_109() ТОЛЬКО ✅
      │
      └─► Промпт root@109-RU-FastVDS:~# (розовый)
```

**Ключевые правила:**
- MOTD показывается ТОЛЬКО через `/etc/profile.d/motd_server.sh` (executed-режим)
- Алиасы загружаются ТОЛЬКО через `source` (sourced-режим)
- Эти два действия НИКОГДА не дублируются — за это отвечает ENTRY POINT
- В `.bashrc` **нет** прямых вызовов `bash ...infooo.sh` или `bash ...motd_server.sh`

---

## 🏗 Архитектура server_109.sh (три секции + ENTRY POINT)

```bash
# Секция [1]: _motd_109()    — рисует цветное меню (розово-зелёная гамма)
# Секция [2]: _aliases_109() — все alias + PS1 (розовый) + HISTCONTROL
# Секция [3]: _install_mc_menu_109() — пишет /root/.config/mc/menu

# ENTRY POINT:
if [[ "${1}" == "--install" ]]; then
    # bash server_109.sh --install
    # → копирует себя в /etc/profile.d/motd_server.sh
    # → вызывает _install_mc_menu_109()

elif [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # source server_109.sh  (из .bashrc)
    # → вызывает ТОЛЬКО _aliases_109()
    # → MOTD НЕ показывает ← КРИТИЧЕСКИ ВАЖНО

else
    # bash server_109.sh  (из /etc/profile.d/)
    # → вызывает ТОЛЬКО _motd_109()
fi
```

---

## ✏️ Как добавить новый алиас

1. Открой `server_109.sh`, найди функцию `_aliases_109()`
2. Добавь: `alias mycommand='bash /root/Linux_Server_Public/109/my_script.sh'`
3. `save` → `load` на сервере

**Если хочешь чтобы алиас был виден в MOTD-меню** — также добавь строку в `_motd_109()` в нужном блоке `echo -e`.

---

## ✏️ Как изменить текст MOTD (меню)

1. Открой `server_109.sh`, найди функцию `_motd_109()`
2. Отредактируй нужные строки `echo -e`
3. `load` на сервере (автоматически делает `--install` + перегружает алиасы)

Цвета: `$C`=cyan(рамки), `$G`=green(команды), `$Y`=yellow(заголовки), `$W`=white(значения), `$R`=red.

---

## 🔧 Установка с нуля (новый сервер)

```bash
# 1. Клонировать репо
git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public

# 2. Установить MOTD + алиасы + MC меню
bash /root/Linux_Server_Public/109/server_109.sh --install

# 3. Скопировать .bash_profile и .bashrc на сервер
cp /root/Linux_Server_Public/109/.bash_profile /root/.bash_profile
cp /root/Linux_Server_Public/109/.bashrc /root/.bashrc

# 4. Перезайти по SSH — всё работает
```

---

## ❌ Частые ошибки и их причины

### MOTD показывается 2 раза

**Причина A (самая частая):** В `/root/.bashrc` на сервере есть прямая строка запуска скрипта.

**Диагностика (одна команда):**
```bash
grep -r "infooo\|motd\|bash.*\.sh" /etc/profile.d/ /root/.bashrc /root/.bash_profile 2>/dev/null && ls -la /etc/profile.d/
```

Что ожидать:
- `/etc/profile.d/` — только `motd_server.sh` (копия `server_109.sh`) + стандартные Ubuntu-файлы
- `/root/.bashrc` — только `source /root/Linux_Server_Public/109/.bashrc`
- `/root/.bash_profile` — только вызов `motd_server.sh` + source `.bashrc`

**Исправление:**
```bash
cp /root/Linux_Server_Public/109/.bashrc /root/.bashrc
source /root/.bashrc
```

**Причина B:** В sourced-ветке ENTRY POINT есть вызов `_motd_109()`.
```bash
grep -n '_motd_109' /root/Linux_Server_Public/109/server_109.sh
# Должна быть только одна строка — в ветке else (executed-режим)
```

**Причина C:** Появился лишний файл в `/etc/profile.d/` помимо `motd_server.sh`.
```bash
ls -la /etc/profile.d/
# Лишний файл — удалить: rm /etc/profile.d/motd_custom.sh
```

---

### MOTD не показывается совсем

**Причина A:** `/etc/profile.d/motd_server.sh` не обновлён.
```bash
bash /etc/profile.d/motd_server.sh
# Если не работает:
bash /root/Linux_Server_Public/109/server_109.sh --install
```

**Причина B:** `/root/.bash_profile` на сервере не вызывает MOTD.
```bash
diff /root/.bash_profile /root/Linux_Server_Public/109/.bash_profile
# Если есть различия:
cp /root/Linux_Server_Public/109/.bash_profile /root/.bash_profile
```

**Причина C (ВАЖНО):** Когда существует `~/.bash_profile`, Ubuntu читает его ВМЕСТО `/etc/profile`.
Файлы из `/etc/profile.d/` выполняются только через `/etc/profile`.
Поэтому мы вызываем MOTD напрямую в `.bash_profile`: `bash /etc/profile.d/motd_server.sh`

---

### Алиасы не работают после SSH-логина

```bash
cp /root/Linux_Server_Public/109/.bashrc /root/.bashrc
source /root/.bashrc
```

---

### load не обновляет MOTD

```bash
alias load
# Должно содержать: bash /root/Linux_Server_Public/109/server_109.sh --install
```

---

## 📋 Проверочный чеклист после любых изменений

```bash
# 1. Применить изменения
load

# 2. /etc/profile.d/ обновлён?
head -5 /etc/profile.d/motd_server.sh

# 3. MOTD работает?
bash /etc/profile.d/motd_server.sh

# 4. Алиасы работают?
type sos && type load

# 5. Файлы актуальны?
diff /root/.bash_profile /root/Linux_Server_Public/109/.bash_profile
diff /root/.bashrc /root/Linux_Server_Public/109/.bashrc
# Оба вывода должны быть пустыми
```

---

## ⚠️ Что НЕЛЬЗЯ делать

- ❌ Не вызывать `_motd_109()` в sourced-ветке ENTRY POINT — двойное меню
- ❌ Не добавлять `source /etc/profile` в `.bash_profile` — тройной запуск
- ❌ Не редактировать `/etc/profile.d/motd_server.sh` напрямую — перезапишется при `load`
- ❌ Не создавать отдельные файлы `motd_server_v2026-XX-XX.sh` — есть один `server_109.sh`
- ❌ Не редактировать `/root/.bashrc` вручную — только через репо и `cp`
- ❌ Не добавлять прямые `bash ...infooo.sh` в `/root/.bashrc` — только через флаг-блок или алиас

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
