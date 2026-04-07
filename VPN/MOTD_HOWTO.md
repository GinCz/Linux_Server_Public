# MOTD (SSH Banner) — Полная документация

> Version: v2026-04-07  
> Author: Ing. VladiMIR Bulantsev  
> = Rooted by VladiMIR | AI =

---

## ❗ ГЛАВНОЕ ПРАВИЛО

> На каждом сервере должен быть **ТОЛЬКО ОДИН** файл MOTD.
> Если появляются два баннера при входе по SSH — значит есть дублирующий файл.

---

## 🗂 Где живёт каждый MOTD-файл

### VPN-серверы (все 8 нод: Alex-47, 4Ton-237, Tatra-9, Shahin-227, Stolb-24, Pilik-178, Ilya-176, So-38)

| Что | Путь в репозитории | Куда устанавливается на сервере |
|-----|--------------------|----------------------------------|
| ✅ Актуальный MOTD (исходник) | `VPN/motd_server.sh` | `/etc/profile.d/motd_server.sh` |
| ✅ Установщик | `VPN/deploy_vpn_node.sh` | Запускается вручную или через vpndeploy |
| ✅ .bashrc для VPN | `VPN/.bashrc` | `/root/.bashrc` |

### Сервер 222 (DE-NetCup, 152.53.182.222)

| Что | Путь в репозитории | Куда устанавливается на сервере |
|-----|--------------------|----------------------------------|
| ✅ .bashrc | `222/.bashrc` | `/root/.bashrc` |
| ✅ Общие алиасы | `scripts/shared_aliases.sh` | sourced из .bashrc |
| ✅ MOTD установщик (интерактивный) | `scripts/setup_motd.sh` | создаёт `/etc/profile.d/motd_banner.sh` |

### Сервер 109 (RU-FastVDS, 212.109.223.109)

| Что | Путь в репозитории | Куда устанавливается на сервере |
|-----|--------------------|----------------------------------|
| ✅ .bashrc | `scripts/` (через setup_ru_109.sh) | `/root/.bashrc` |
| ✅ MOTD установщик (интерактивный) | `scripts/setup_motd.sh` | создаёт `/etc/profile.d/motd_banner.sh` |

---

## 🚫 УСТАРЕВШИЕ ФАЙЛЫ (не использовать!)

| Файл | Статус | Примечание |
|------|--------|------------|
| `222/motd_server.sh` | ❌ DEPRECATED | Перенаправляет на VPN/motd_server.sh. Не устанавливать! |
| `/etc/profile.d/motd_vpn.sh` | ❌ УДАЛИТЬ | Старый файл, создан вручную 24.03. Удалён с VPN-EU-Alex-47 в апреле 2026 |
| `/etc/profile.d/motd_banner.sh` | ⚠️ ТОЛЬКО для 222/109 | На VPN-серверах НЕ должен существовать |
| `/etc/profile.d/ps1_color.sh` | ❌ УДАЛИТЬ | Конфликтует с PS1 из .bashrc |

---

## 🔧 Как обновить MOTD на VPN-серверах

### Один сервер (например, Alex-47):
```bash
cd /root/Linux_Server_Public && git pull --rebase && bash VPN/deploy_vpn_node.sh
```

### Все VPN-серверы сразу (запускать с сервера 222!):
```bash
# На сервере 222:
vpndeploy
# CMD в vpn_deploy.sh должен быть:
# bash /root/Linux_Server_Public/VPN/deploy_vpn_node.sh
```

---

## 🔧 Как обновить MOTD на 222/109

```bash
bash /root/Linux_Server_Public/scripts/setup_motd.sh
# Интерактивный скрипт — выбери цвет (1-5)
# Устанавливает: /etc/profile.d/motd_banner.sh
```

---

## 🩺 Диагностика: два баннера при входе

```bash
# Шаг 1: посмотреть всё что в profile.d
ls -la /etc/profile.d/

# Шаг 2: найти все файлы которые рисуют баннер
grep -l "VPN\|IP:\|RAM:\|WG peers\|uptime" /etc/profile.d/*.sh 2>/dev/null

# Шаг 3: удалить лишние (оставить ТОЛЬКО motd_server.sh на VPN)
rm -f /etc/profile.d/motd_vpn.sh
rm -f /etc/profile.d/motd_banner.sh   # только на VPN-серверах!
rm -f /etc/profile.d/ps1_color.sh

# Шаг 4: проверить что осталось
ls /etc/profile.d/*.sh
```

---

## 📋 История проблем и решений

### 07.04.2026 — два баннера на VPN-EU-Alex-47

**Проблема:** При SSH-логине показывались два баннера:
1. Большой (`motd_server.sh`) — актуальный ✅
2. Маленький (`motd_vpn.sh`) — старый ❌

**Причина:** Файл `/etc/profile.d/motd_vpn.sh` был создан вручную 24 марта 2026 старым скриптом (предшественник `setup_motd.sh`). В репозитории его нет — поэтому `deploy_vpn_node.sh` его не удалял.

**Также был** `/etc/profile.d/motd_banner.sh` — создан `scripts/setup_motd.sh` во время ранней настройки.

**Решение:**
```bash
rm -f /etc/profile.d/motd_vpn.sh
rm -f /etc/profile.d/motd_banner.sh
rm -f /etc/profile.d/ps1_color.sh
```

**Защита:** В `VPN/deploy_vpn_node.sh` (шаг 4) добавлено явное удаление этих файлов при каждом деплое.

---

## 📁 Структура папок по серверам

```
Linux_Server_Public/
├── VPN/                      ← ВСЁ для VPN-нод
│   ├── .bashrc               ← .bashrc для всех VPN-серверов
│   ├── motd_server.sh        ← АКТУАЛЬНЫЙ MOTD для VPN (исходник)
│   ├── deploy_vpn_node.sh    ← ГЛАВНЫЙ деплой-скрипт для VPN
│   ├── deploy_bashrc.sh      ← Только .bashrc (без MOTD, устарел)
│   ├── amnezia_stat.sh       ← alias: aw
│   ├── vpn_node_clean_audit.sh ← alias: audit
│   ├── infooo.sh             ← alias: infooo
│   └── system_backup.sh      ← alias: backup
│
├── scripts/                  ← Общие скрипты (222 + 109)
│   ├── shared_aliases.sh     ← load/save/aw/mc/ll/la/00 — sourced из .bashrc
│   ├── setup_motd.sh         ← Интерактивный установщик MOTD (222/109)
│   ├── setup_ru_109.sh       ← Настройка сервера 109
│   ├── setup_eu_222.sh       ← Настройка сервера 222
│   └── ...
│
├── 222/                      ← Скрипты специфичные для сервера 222
│   ├── .bashrc               ← .bashrc для сервера 222 (желтый PS1)
│   ├── motd_server.sh        ← ❌ DEPRECATED! Только редирект
│   ├── vpn_deploy.sh         ← Массовый деплой на все VPN-ноды
│   └── ...
```
