# MOTD & Aliases — Полная архитектура сервера 109-RU-FastVDS

> Version: v2026-04-27  
> = Rooted by VladiMIR | AI =

---

## ⚡ Быстрый справочник (читай это первым)

| Что нужно сделать | Команда |
|---|---|
| Добавить / убрать алиас | Редактируй `_aliases_109()` в `server_109.sh`, затем `load` |
| Изменить текст MOTD (меню) | Редактируй `_motd_109()` в `server_109.sh`, затем `load` |
| Применить изменения после редактирования | `load` (на сервере 109) |
| Полная переустановка с нуля | `bash /root/Linux_Server_Public/109/server_109.sh --install` |
| Проверить что показывается при входе | `bash /etc/profile.d/motd_server.sh` |
| MOTD показывается 2 раза | см. раздел "Частые ошибки" ниже |
| MOTD не показывается совсем | см. раздел "Частые ошибки" ниже |

---

## 📁 Какой файл за что отвечает

```
/root/Linux_Server_Public/
└── 109/
    ├── server_109.sh         ← ГЛАВНЫЙ ФАЙЛ. Всё в нём: MOTD + алиасы + MC меню
    ├── .bash_profile         ← Загружается при SSH-логине. Показывает MOTD + грузит алиасы
    ├── .bashrc               ← Только делает source server_109.sh (алиасы)
    └── HOW-TO-UPDATE-MOTD.md ← Этот файл

/root/                        ← Файлы НА СЕРВЕРЕ (не в репо)
├── .bash_profile             ← КОПИЯ из репо. Должна совпадать с 109/.bash_profile
└── .bashrc                   ← Только source 109/.bashrc из репо

/etc/profile.d/
└── motd_server.sh            ← КОПИЯ server_109.sh. Устанавливается командой --install
                                 При SSH-логине Ubuntu запускает ВСЕ файлы из этой папки
```

---

## 🔄 Как работает SSH-логин (порядок загрузки)

```
SSH подключение
      │
      ├─► Ubuntu читает /root/.bash_profile
      │         │
      │         ├─► [1] bash /etc/profile.d/motd_server.sh
      │         │         └─► вызывает _motd_109() → показывает цветное меню ✅
      │         │
      │         └─► [2] source /root/Linux_Server_Public/109/.bashrc
      │                   └─► source server_109.sh (sourced-режим)
      │                             └─► вызывает _aliases_109() → загружает алиасы ✅
      │
      └─► Промпт root@109-RU-FastVDS:~#  (розовый цвет, \e[38;5;217m)
```

**Ключевое правило:** MOTD показывается ТОЛЬКО через `/etc/profile.d/motd_server.sh`.  
Алиасы загружаются ТОЛЬКО через `source` (sourced-режим).  
Эти два действия никогда не должны дублироваться.

---

## 🏗 Архитектура server_109.sh (три секции)

Файл `server_109.sh` содержит три секции и умный ENTRY POINT:

```bash
# Секция [1]: функция _motd_109()    — рисует цветное меню (розово-зелёная гамма)
# Секция [2]: функция _aliases_109() — все alias + PS1 (розовый) + HISTCONTROL
# Секция [3]: функция _install_mc_menu_109() — пишет /root/.config/mc/menu

# ENTRY POINT — определяет что делать в зависимости от способа запуска:
if [[ "${1}" == "--install" ]]; then
    # Запущен как: bash server_109.sh --install
    # → копирует себя в /etc/profile.d/motd_server.sh
    # → вызывает _install_mc_menu_109()

elif [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Запущен как: source server_109.sh
    # → вызывает ТОЛЬКО _aliases_109()
    # → MOTD НЕ показывает (он уже был показан через /etc/profile.d/)

else
    # Запущен как: bash server_109.sh  (из /etc/profile.d/)
    # → вызывает ТОЛЬКО _motd_109()
fi
```

---

## ✏️ Как добавить новый алиас

**Шаг 1.** Открой `server_109.sh`, найди функцию `_aliases_109()`.  
**Шаг 2.** Добавь строку внутри функции:
```bash
alias mycommand='bash /root/Linux_Server_Public/109/my_script.sh'
```
**Шаг 3.** Сохрани файл в репо (`save` на сервере или через GitHub).  
**Шаг 4.** Примени на сервере:
```bash
load
```
Готово. Алиас доступен сразу в текущей сессии и при каждом следующем SSH-логине.

**Если хочешь чтобы алиас был виден в MOTD-меню** — также добавь строку в `_motd_109()`  
в блоке `echo -e` с нужной колонкой.

---

## ✏️ Как изменить текст MOTD (меню)

**Шаг 1.** Открой `server_109.sh`, найди функцию `_motd_109()`.  
**Шаг 2.** Отредактируй нужные строки `echo -e`.  
Цвета: `$C`=cyan(рамки), `$G`=green(команды), `$Y`=yellow(заголовки), `$W`=white(значения), `$R`=red(ошибки).  
**Шаг 3.** Запусти на сервере:
```bash
load
```
`load` автоматически делает `--install` (обновляет `/etc/profile.d/`) + перегружает алиасы.

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

**Причина:** В ENTRY POINT файла `server_109.sh` в ветке `sourced` есть вызов `_motd_109()`.  
Это неправильно — в sourced-режиме MOTD вызывать нельзя.

**Диагностика:**
```bash
grep -n '_motd_109' /root/Linux_Server_Public/109/server_109.sh
```
Должна быть только одна строка — в ветке `else` (executed-режим).

**Исправление:** убрать вызов `_motd_109` из ветки `elif [[ sourced ]]`.

---

### MOTD не показывается совсем

**Причина A:** `/etc/profile.d/motd_server.sh` не обновлён.  
**Проверка:** `bash /etc/profile.d/motd_server.sh`  
**Исправление:** `bash /root/Linux_Server_Public/109/server_109.sh --install`

**Причина B:** `/root/.bash_profile` на сервере не вызывает MOTD.  
**Проверка:** `cat /root/.bash_profile`  
Должна быть строка: `bash /etc/profile.d/motd_server.sh`  
**Исправление:**
```bash
cd /root/Linux_Server_Public && git pull --rebase
cp /root/Linux_Server_Public/109/.bash_profile /root/.bash_profile
```

**Причина C (ВАЖНО):** Когда существует `~/.bash_profile`, Ubuntu читает его ВМЕСТО `/etc/profile`.  
Файлы из `/etc/profile.d/` выполняются только через `/etc/profile`.  
Поэтому мы вызываем MOTD напрямую в `.bash_profile`: `bash /etc/profile.d/motd_server.sh`

---

### Алиасы не работают после SSH-логина

**Причина:** `/root/.bashrc` на сервере устарел.  
**Исправление:**
```bash
cp /root/Linux_Server_Public/109/.bashrc /root/.bashrc
source /root/.bashrc
```

---

### load не обновляет MOTD

**Проверка алиаса:**
```bash
alias load
```
Должно содержать: `bash /root/Linux_Server_Public/109/server_109.sh --install`

---

## 📋 Проверочный чеклист после любых изменений

```bash
# 1. Изменения применены?
load

# 2. /etc/profile.d/ обновлён?
head -5 /etc/profile.d/motd_server.sh

# 3. MOTD работает?
bash /etc/profile.d/motd_server.sh

# 4. Алиасы работают?
type sos
type load

# 5. .bash_profile актуален?
diff /root/.bash_profile /root/Linux_Server_Public/109/.bash_profile
# вывод должен быть пустым
```

---

## ⚠️ Что НЕЛЬЗЯ делать

- ❌ Не вызывать `_motd_109()` в sourced-ветке ENTRY POINT — двойное меню
- ❌ Не добавлять `source /etc/profile` в `.bash_profile` — тройной запуск
- ❌ Не редактировать `/etc/profile.d/motd_server.sh` напрямую — перезаписывается при `load`
- ❌ Не создавать отдельные файлы типа `motd_server_v2026-XX-XX.sh` — есть один `server_109.sh`
- ❌ Не редактировать `/root/.bashrc` вручную — только через репо и `cp`
