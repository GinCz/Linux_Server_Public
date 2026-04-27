# MOTD & Aliases — Полная архитектура сервера 222-DE-NetCup

> Version: v2026-04-27  
> = Rooted by VladiMIR | AI =

---

## ⚡ Быстрый справочник (читай это первым)

| Что нужно сделать | Команда |
|---|---|
| Добавить / убрать алиас | Редактируй `_aliases_222()` в `server_222.sh`, затем `load` |
| Изменить текст MOTD (меню) | Редактируй `_motd_222()` в `server_222.sh`, затем `load` |
| Применить изменения после редактирования | `load` (на сервере 222) |
| Полная переустановка с нуля | `bash /root/Linux_Server_Public/222/server_222.sh --install` |
| Проверить что показывается при входе | `bash /etc/profile.d/motd_server.sh` |
| MOTD показывается 2 раза | см. раздел "Частые ошибки" ниже |
| MOTD не показывается совсем | см. раздел "Частые ошибки" ниже |

---

## 📁 Какой файл за что отвечает

```
/root/Linux_Server_Public/
└── 222/
    ├── server_222.sh         ← ГЛАВНЫЙ ФАЙЛ. Всё в нём: MOTD + алиасы + MC меню
    ├── .bash_profile         ← Загружается при SSH-логине. Показывает MOTD + грузит алиасы
    ├── .bashrc               ← Только делает source server_222.sh (алиасы)
    └── HOW-TO-UPDATE-MOTD.md ← Этот файл

/root/                        ← Файлы НА СЕРВЕРЕ (не в репо)
├── .bash_profile             ← КОПИЯ из репо. Должна совпадать с 222/.bash_profile
└── .bashrc                   ← КОПИЯ из репо. Должна совпадать с 222/.bashrc

/etc/profile.d/
└── motd_server.sh            ← КОПИЯ server_222.sh. Устанавливается командой --install
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
      │         │         └─► вызывает _motd_222() → показывает цветное меню ✅
      │         │
      │         └─► [2] source /root/Linux_Server_Public/222/.bashrc
      │                   └─► source server_222.sh (sourced-режим)
      │                             └─► вызывает _aliases_222() → загружает алиасы ✅
      │
      └─► Промпт root@222-DE-NetCup:~#  (жёлтый цвет)
```

**Ключевое правило:** MOTD показывается ТОЛЬКО через `/etc/profile.d/motd_server.sh`.  
Алиасы загружаются ТОЛЬКО через `source` (sourced-режим).  
Эти два действия никогда не должны дублироваться.

---

## 🏗 Архитектура server_222.sh (три секции)

Файл `server_222.sh` содержит три секции и умный ENTRY POINT:

```bash
# Секция [1]: функция _motd_222()    — рисует цветное меню
# Секция [2]: функция _aliases_222() — все alias + PS1 + HISTCONTROL
# Секция [3]: функция _install_mc_menu_222() — пишет /root/.config/mc/menu

# ENTRY POINT — определяет что делать в зависимости от способа запуска:
if [[ "${1}" == "--install" ]]; then
    # Запущен как: bash server_222.sh --install
    # → копирует себя в /etc/profile.d/motd_server.sh
    # → вызывает _install_mc_menu_222()

elif [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Запущен как: source server_222.sh
    # → вызывает ТОЛЬКО _aliases_222()
    # → MOTD НЕ показывает (он уже был показан через /etc/profile.d/)

else
    # Запущен как: bash server_222.sh  (из /etc/profile.d/)
    # → вызывает ТОЛЬКО _motd_222()
fi
```

---

## ✏️ Как добавить новый алиас

**Шаг 1.** Открой `server_222.sh`, найди функцию `_aliases_222()`.  
**Шаг 2.** Добавь строку внутри функции:
```bash
alias mycommand='bash /root/Linux_Server_Public/222/my_script.sh'
```
**Шаг 3.** Сохрани файл в репо (`save` на сервере или через GitHub).  
**Шаг 4.** Примени на сервере:
```bash
load
```
Готово. Алиас доступен сразу в текущей сессии и при каждом следующем SSH-логине.

**Если хочешь чтобы алиас был виден в MOTD-меню** — также добавь строку в `_motd_222()`  
в блоке `echo -e` с нужной колонкой.

---

## ✏️ Как изменить текст MOTD (меню)

**Шаг 1.** Открой `server_222.sh`, найди функцию `_motd_222()`.  
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
bash /root/Linux_Server_Public/222/server_222.sh --install

# 3. Скопировать .bash_profile и .bashrc на сервер
cp /root/Linux_Server_Public/222/.bash_profile /root/.bash_profile
cp /root/Linux_Server_Public/222/.bashrc /root/.bashrc

# 4. Перезайти по SSH — всё работает
```

---

## ❌ Частые ошибки и их причины

### MOTD показывается 2 раза

**Причина:** В ENTRY POINT файла `server_222.sh` в ветке `sourced` есть вызов `_motd_222()`.  
Это неправильно — в sourced-режиме MOTD вызывать нельзя, он уже был показан через `/etc/profile.d/`.

**Диагностика:**
```bash
grep -n '_motd_222' /root/Linux_Server_Public/222/server_222.sh
```
Должна быть только одна строка — в ветке `else` (executed-режим).

**Исправление:** убрать вызов `_motd_222` из ветки `elif [[ sourced ]]`.

---

### MOTD не показывается совсем

**Причина A:** `/etc/profile.d/motd_server.sh` не обновлён (старая версия или не установлен).  
**Проверка:** `bash /etc/profile.d/motd_server.sh` — если меню есть, проблема в .bash_profile  
**Исправление:** `bash /root/Linux_Server_Public/222/server_222.sh --install`

**Причина B:** `/root/.bash_profile` на сервере не вызывает MOTD.  
**Проверка:** `cat /root/.bash_profile`  
Должна быть строка: `bash /etc/profile.d/motd_server.sh`  
**Исправление:**
```bash
cd /root/Linux_Server_Public && git pull --rebase
cp /root/Linux_Server_Public/222/.bash_profile /root/.bash_profile
```

**Причина C:** `/root/.bash_profile` существует и НЕ вызывает `/etc/profile`.  
Когда существует `~/.bash_profile`, Ubuntu читает его ВМЕСТО `/etc/profile`.  
Файлы из `/etc/profile.d/` выполняются только через `/etc/profile`.  
Поэтому в `.bash_profile` мы вызываем MOTD напрямую: `bash /etc/profile.d/motd_server.sh`

---

### Алиасы не работают после SSH-логина

**Причина:** `/root/.bashrc` на сервере устарел или перезаписан.  
**Исправление:**
```bash
cp /root/Linux_Server_Public/222/.bashrc /root/.bashrc
source /root/.bashrc
```

---

### load не обновляет MOTD

**Причина:** `load` делает `source server_222.sh` (загрузка алиасов) + `--install` (копирует в /etc/profile.d/).  
Если `load` работает правильно, MOTD обновляется автоматически.  
**Проверка алиаса:**
```bash
alias load
```
Должно содержать: `bash /root/Linux_Server_Public/222/server_222.sh --install`

---

## 📋 Проверочный чеклист после любых изменений

```bash
# 1. Изменения применены?
load

# 2. /etc/profile.d/ обновлён?
head -5 /etc/profile.d/motd_server.sh  # должна быть свежая дата

# 3. MOTD работает?
bash /etc/profile.d/motd_server.sh

# 4. Алиасы работают?
type sos
type load

# 5. .bash_profile актуален?
diff /root/.bash_profile /root/Linux_Server_Public/222/.bash_profile
# вывод должен быть пустым (файлы одинаковые)
```

---

## ⚠️ Что НЕЛЬЗЯ делать

- ❌ Не вызывать `_motd_222()` в sourced-ветке ENTRY POINT — это вызовет двойное меню
- ❌ Не добавлять `source /etc/profile` в `.bash_profile` — это вызовет тройной запуск
- ❌ Не редактировать `/etc/profile.d/motd_server.sh` напрямую — он перезаписывается при `load`
- ❌ Не создавать отдельные файлы типа `motd_server_v2026-XX-XX.sh` — есть один файл `server_222.sh`
- ❌ Не редактировать `/root/.bashrc` вручную — только через репо и `cp`
