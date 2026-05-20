# MOTD & Aliases — Полная архитектура VPN-серверов

> Version: v2026.05.21
> = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =

Серверы: VPN-EU-Alex-47, VPN-EU-4Ton-237, VPN-EU-Tatra-9, VPN-EU-Pilik-178,
VPN-EU-Shahin-227, VPN-EU-Stolb-24, VPN-EU-Ilya-176, VPN-EU-So-38

---

## ⚡ Быстрый справочник (читай это ПЕРВЫМ)

| Что нужно сделать | Команда |
|---|---|
| Добавить / убрать алиас | Редактируй `VPN/.bashrc` в репо, затем `load` |
| Изменить текст MOTD (меню) | Редактируй `VPN/motd_server.sh`, затем `load` |
| Применить изменения | `load` (на VPN-сервере) |
| Установить с нуля | см. раздел «Установка с нуля» ниже |
| MOTD показывается 2 раза | см. раздел «Частые ошибки» ниже |
| MOTD не показывается совсем | см. раздел «Частые ошибки» ниже |

---

## 📁 Какой файл за что отвечает

```
/root/Linux_Server_Public/
└── VPN/
    ├── motd_server.sh        ← Цветное MOTD-меню VPN (бирюзовая гамма)
    ├── .bashrc               ← PS1 + SOS-алиасы + VPN-алиасы + shared_aliases
    ├── deploy_vpn_node.sh    ← Деплой: копирует .bashrc на сервер + install MOTD
    └── MOTD_HOWTO.md         ← Этот файл

/root/                        ← Файлы НА СЕРВЕРЕ (не в репо)
├── .bash_profile             ← Загружается при SSH → source .bashrc
└── .bashrc                   ← КОПИЯ из репо VPN/.bashrc

/root/Linux_Server_Public/scripts/
└── shared_aliases.sh         ← Общие алиасы: save, aw, ls, mc, 00, la, ll
```

---

## 🔄 Как работает SSH-логин (порядок загрузки)

```
SSH подключение
      │
      ├─► Ubuntu читает /root/.bash_profile
      │         └─► source /root/.bashrc
      │                   ├─► [1] PS1='бирюзовый промпт \u@\h'
      │                   ├─► [2] HISTCONTROL, shopt настройки
      │                   ├─► [3] SOS-алиасы (sos, sos3, sos24, sos120)
      │                   │         → bash /root/Linux_Server_Public/VPN/sos_vpn.sh <часы>
      │                   ├─► [4] VPN-алиасы (audit, infooo, backup, banlog, antivir, load)
      │                   └─► [5] source /root/Linux_Server_Public/scripts/shared_aliases.sh
      │                               └─► общие алиасы: save, aw, ls, mc, 00, la, ll
      │
      └─► Промпт root@VPN-EU-*:~# (бирюзовый \e[38;5;87m)
```

**Важно:** MOTD на VPN-серверах показывается через механизм, описанный в `deploy_vpn_node.sh`.
VPN-серверы используют ту же флаг-файловую защиту от дублирования что и сервер 222.
В `/etc/profile.d/` на VPN — **нет файлов MOTD** (аналогично серверу 222, не как 109).

---

## 🆚 SOS на VPN vs SOS на 222/109

**Это разные скрипты!**

| | 222-DE-NetCup / 109-RU-FastVDS | VPN-серверы |
|---|---|---|
| **Скрипт** | `scripts/sos-fastpanel.sh` | `VPN/sos_vpn.sh` |
| **Параметр** | `1h`, `3h`, `24h`, `120h` | `1`, `3`, `24`, `120` (числа часов) |
| **Алиасы** | `sos` / `sos3` / `sos24` / `sos120` | `sos` / `sos3` / `sos24` / `sos120` |
| **Специфика** | FastPanel, Nginx, PHP-FPM, WP, Docker | AmneziaWG, WireGuard, Xray, VPN peers |

Нельзя использовать `sos-fastpanel.sh` на VPN-серверах и наоборот.

---

## ✏️ Как добавить новый алиас

1. Открой `VPN/.bashrc` в репо
2. Найди нужную секцию и добавь строку
3. `save` → `load` на сервере

**Общие алиасы** (save, aw, 00, la, ll, mc) — в `scripts/shared_aliases.sh`. Они подключаются на все VPN-серверы автоматически.

---

## 🔧 Установка с нуля (новый VPN-сервер)

```bash
# 1. Клонировать репо
git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public

# 2. Задеплоить MOTD + алиасы
bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh

# 3. Перезайти по SSH — всё работает
```

---

## ❌ Частые ошибки и их причины

### MOTD показывается 2 раза

**Диагностика (одна команда):**
```bash
grep -r "infooo\|motd\|bash.*\.sh" /etc/profile.d/ /root/.bashrc /root/.bash_profile 2>/dev/null && ls -la /etc/profile.d/
```

На VPN-серверах `/etc/profile.d/` должен содержать только стандартные Ubuntu-файлы.
Любой лишний файл — удалить:
```bash
rm /etc/profile.d/<лишний_файл>.sh
```

### MOTD не показывается / алиасы не работают

```bash
cd /root/Linux_Server_Public && git pull --rebase
bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh
source /root/.bashrc
```

---

## 📋 Проверочный чеклист после изменений

```bash
# 1. Применить
load

# 2. Алиасы работают?
type sos && type load && type audit

# 3. .bashrc актуален?
diff /root/.bashrc /root/Linux_Server_Public/VPN/.bashrc
# Вывод должен быть пустым

# 4. Нет лишних файлов?
ls -la /etc/profile.d/
```

---

## ⚠️ Что НЕЛЬЗЯ делать

- ❌ Не создавать файлы MOTD в `/etc/profile.d/` — на VPN это не нужно
- ❌ Не использовать `sos-fastpanel.sh` на VPN-серверах — там свой `sos_vpn.sh`
- ❌ Не редактировать `/root/.bashrc` на сервере вручную — только через репо и deploy
- ❌ Не путать архитектуру VPN с архитектурой 109 (у 109 — `/etc/profile.d/`, у VPN — нет)

---

## 🔁 Сравнение архитектур всех серверов

| | 222-DE-NetCup | 109-RU-FastVDS | VPN-серверы |
|---|---|---|---|
| **Главный файл** | `222/.bashrc` | `109/server_109.sh` | `VPN/.bashrc` |
| **MOTD-файл** | `222/motd_server.sh` | `109/server_109.sh` | `VPN/motd_server.sh` |
| **Алиасы** | в `222/.bashrc` | в `server_109.sh` → `_aliases_109()` | в `VPN/.bashrc` + `shared_aliases.sh` |
| **`/etc/profile.d/`** | ❌ не используется | ✅ `motd_server.sh` копируется сюда | ❌ не используется |
| **Защита от дублирования** | флаг-файл `/tmp/motd_shown_*` | ENTRY POINT (bash vs source) | флаг-файл `/tmp/motd_shown_*` |
| **Команда обновить всё** | `load` (git pull) | `load` (git pull + `--install`) | `load` (git pull + deploy) |
| **SOS-скрипт** | `scripts/sos-fastpanel.sh` | `scripts/sos-fastpanel.sh` | `VPN/sos_vpn.sh` |
| **Цвет промпта** | 🟡 жёлтый | 🩷 розовый | 🩵 бирюзовый |
