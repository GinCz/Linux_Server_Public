# Server 222-EU-NetCup — Scripts & MOD Documentation

**Server:** 152.53.182.222 | NetCup DE | Ubuntu 24 | FASTPANEL | Cloudflare  
**Repo:** github.com/GinCz/Linux_Server_Public  
= Rooted by VladiMIR | AI =

---

## Структура «мода» — что делает кастомизация при входе

При каждом SSH-входе на сервер автоматически происходит следующее:

```
SSH login
   │
   └─► /root/.bash_profile  (login shell — главный файл)
            │
            ├─► source /root/Linux_Server_Public/222/.bashrc
            │       │
            │       ├─► PS1 = ЖЁЛТЫЙ (root@222-EU-NetCup:~/path#)
            │       ├─► MOTD banner (один раз за сессию, флаг /tmp/motd_shown_*)
            │       │     └─► bash /root/Linux_Server_Public/222/motd_server.sh
            │       └─► все алиасы (sos, mc, save, load, f5bot, ...)
            │
            └─► export PS1 ЖЁЛТЫЙ (принудительно, последнее слово)
```

---

## Файлы мода и их роли

| Файл | Где лежит | Роль |
|------|-----------|------|
| `.bash_profile` | `/root/.bash_profile` | **Главный файл login shell.** Запускается при каждом SSH-входе. Подгружает репо `.bashrc`, устанавливает жёлтый PS1. |
| `.bashrc` | `/root/Linux_Server_Public/222/.bashrc` | **Центральный файл мода.** Устанавливает PS1, запускает MOTD (один раз), определяет все алиасы. |
| `motd_server.sh` | `/etc/profile.d/motd_server.sh` | **MOTD-баннер.** Красивый ASCII-дисплей: имя сервера, IP, RAM, CPU, Xray статус, список алиасов. |
| `mc.menu` | `/root/Linux_Server_Public/222/mc.menu` | **F2-меню Midnight Commander.** Кастомное меню с командами сервера. Редактировать только здесь. |
| `mc_menu_setup.sh` | `/root/Linux_Server_Public/222/mc_menu_setup.sh` | **Деплой mc.menu** из репо в `~/.config/mc/menu`. |
| `apply_aliases.sh` | `/root/Linux_Server_Public/222/apply_aliases.sh` | Перезагружает алиасы в **текущей сессии** без выхода. |

---

## Xray / x-ui — статус в MOTD

MOTD показывает количество клиентов Xray через локальный x-ui API:

```
Xray: 6 enabled / 6 total
```

- **Панель x-ui:** `http://152.53.182.222:30452/OkNrdoVybueUzHY/`
- **Порт x-ui API:** `30452` (локально: `127.0.0.1:30452`)
- **API endpoint:** `/xui/API/inbounds/`
- **Xray порт (VLESS/Reality):** `8443`
- `enabled` — клиенты с `enable: true` в x-ui
- `total` — все клиенты во всех inbound
- Онлайн-статус недоступен: VLESS/Reality не держит постоянное соединение как WireGuard

### Обновить motd_server.sh на сервере

```bash
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/motd_server.sh \
     -o /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh
```

---

## Правило без дубликатов — ВАЖНО

> **НЕЛЬЗЯ** иметь `source ~/.bashrc` или `source /root/.bashrc` в `.bash_profile`.  
> Это создаёт конфликт: системный `/root/.bashrc` может перезаписать PS1 или сломать MOTD.

**Правильная цепочка** (только одна):
```
.bash_profile  →  source 222/.bashrc  →  PS1 жёлтый
```

**Запрещённые дубликаты в `.bash_profile`:**
```bash
# ❌ НЕ ДОБАВЛЯТЬ:
[[ -f ~/.bashrc ]] && source ~/.bashrc        # перебивает PS1 на красный
bash /etc/profile.d/motd_server.sh            # MOTD уже вызывается из 222/.bashrc
source /root/.bashrc                          # то же самое
```

---

## MOTD — логика показа «один раз за сессию»

В `222/.bashrc` используется флаг-файл в `/tmp/`:

```bash
_MOTD_FLAG="/tmp/motd_shown_${SSH_CLIENT// /_}"
if [ -n "$SSH_CONNECTION" ] && [ ! -f "$_MOTD_FLAG" ]; then
    touch "$_MOTD_FLAG"
    bash /root/Linux_Server_Public/222/motd_server.sh
fi
```

- Флаг создаётся по IP клиента из `$SSH_CLIENT`
- При **новом SSH-подключении** — IP в переменной другой → MOTD показывается снова ✅
- При открытии **нового таба в той же сессии** — флаг уже есть → MOTD не повторяется ✅
- `/tmp` очищается при перезагрузке сервера → после reboot MOTD всегда показывается ✅

---

## F2-меню Midnight Commander

### Как работает

- Файл меню: `/root/Linux_Server_Public/222/mc.menu`
- После деплоя копируется в: `/root/.config/mc/menu`
- Вызов в mc: нажать **F2**

### Как обновить меню

```bash
# 1. Отредактировать исходник в репо
nano /root/Linux_Server_Public/222/mc.menu

# 2. Задеплоить на сервер
bash /root/Linux_Server_Public/222/mc_menu_setup.sh

# 3. Сохранить в репо
cd /root/Linux_Server_Public && save
```

> ⚠️ **НИКОГДА** не редактировать `/root/.config/mc/menu` напрямую —  
> после следующего деплоя изменения будут перезаписаны.

---

## Установка мода на сервер — полный установщик

```bash
clear

# 1. Клонировать репо (если ещё нет)
# git clone git@github.com:GinCz/Linux_Server_Public.git /root/Linux_Server_Public

# 2. Установить .bash_profile (login shell)
cp /root/Linux_Server_Public/222/.bash_profile /root/.bash_profile

# 3. Установить .bashrc (алиасы + MOTD + PS1)
cp /root/Linux_Server_Public/222/.bashrc /root/.bashrc

# 4. Установить MOTD
curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/motd_server.sh \
     -o /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh

# 5. Задеплоить F2-меню mc
bash /root/Linux_Server_Public/222/mc_menu_setup.sh

# 6. Применить алиасы в текущей сессии (без выхода)
source /root/Linux_Server_Public/222/.bashrc

echo "=== MOD INSTALLED ==="
echo "Выйди и зайди снова — MOTD и жёлтый PS1 должны работать."
```

---

## Применение алиасов без перезахода

```bash
bash /root/Linux_Server_Public/222/apply_aliases.sh
# или:
source /root/Linux_Server_Public/222/.bashrc
```

---

## Быстрые алиасы

| Алиас | Действие |
|-------|----------|
| `sos` | Полный статус сервера |
| `save` | git add -A + commit + push |
| `load` | git pull |
| `mc` | Midnight Commander (F2 = меню) |
| `00` | clear |
| `f5bot` | Бэкап docker trading-bot |
| `domains` | Список доменов |
| `nginx-reload` | Проверка + reload nginx |
| `cleanup` | Очистка бэкапов |

---

## Частые ошибки и решения

### PS1 стал красным после перезахода
**Причина:** В `.bash_profile` была строка `[[ -f ~/.bashrc ]] && source ~/.bashrc`.  
**Решение:** Удалить эту строку из `.bash_profile`. Оставить только `source 222/.bashrc`.

### MOTD не показывается при входе
**Причина:** `clear` в начале `.bashrc` стирал MOTD, или флаг `/tmp/motd_shown_*` не удалялся.  
**Решение:**
```bash
ls /tmp/motd_shown_*
rm /tmp/motd_shown_*   # сбросить флаг вручную
```

### Xray показывает 0/0 в MOTD
**Причина:** x-ui не запущен или изменился путь/порт панели.  
**Решение:** Проверить `systemctl status x-ui` и обновить переменные `XUI_URL`, `XUI_USER`, `XUI_PASS` в `/etc/profile.d/motd_server.sh`.

### F2-меню в mc пустое или старое
```bash
bash /root/Linux_Server_Public/222/mc_menu_setup.sh
```

---

## Важные скрипты папки 222/

| Скрипт | Назначение |
|--------|-----------|
| `sos.sh` | Полный статус сервера (nginx, PHP, docker, диск, RAM) |
| `motd_server.sh` | MOTD-баннер при входе (Xray + CrowdSec) |
| `backup_clean.sh` | Очистка старых бэкапов |
| `docker_backup.sh` | Бэкап trading-bot docker |
| `banlog.sh` | Лог банов CrowdSec |
| `domains.sh` | Список всех доменов |
| `mc_menu_setup.sh` | Деплой F2-меню mc |
| `apply_aliases.sh` | Перезагрузка алиасов без выхода |

---

> ⚠️ **На этом сервере работают многие сайты.**  
> Перед любыми изменениями в nginx/PHP/docker — делай бэкап: `cleanup`

*= Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =*
