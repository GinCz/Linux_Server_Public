# 🚀 New Server Setup & Quick Commands Cheat Sheet

> Репозиторий: [GinCz/Linux_Server_Public](https://github.com/GinCz/Linux_Server_Public)  
> Автор: [Владимир Буланцев (GinCz)](https://github.com/GinCz)

Шпаргалка быстрых 1-строчных команд для развертывания, оптимизации, очистки и диагностики серверов (**Ubuntu 24.04**, **Debian 12**, **DietPi**).

---

## ⚡ 1. Инициализация и настройка нового сервера (New Server Setup)

Установка окружения, цветного PS1, кастомного Midnight Commander, MOTD-шапки и алиасов:

`ash
clear; apt-get update -qq && apt-get install -y -qq curl ca-certificates && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
`

---

## 🧹 2. Глубокая очистка диска (Universal Disk Cleanup)

Безопасное освобождение 2–4 ГБ диска, сжатие логов до 30 MB, оптимизация swapfile и удаление мусора (сохраняет **Xray VPN, Samba, FastPanel, Nginx, AdGuard Home, Uptime Kuma, SSH**):

`ash
clear; apt-get update -qq && apt-get install -y -qq curl ca-certificates && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/server_cleanup.sh)
`
*(Или в терминале сервера: cleanup)*

---

## 🚀 3. Hardcore Slim & Performance Optimizer (Ubuntu 24)

Снижение потребления RAM до 60–80 МБ, включение TCP BBR, отключение балласта:

`ash
clear; apt-get update -qq && apt-get install -y -qq curl ca-certificates && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/Ubuntu24_Slim/ubuntu24_slim.sh)
`

---

## 🔍 4. Диагностика и аудит безопасности (SOS Health Monitor)

Полный аудит системы, портов, VPN-сессий, OOM-киллера, дисков и сетевых интерфейсов:

`ash
sos
`
*(Или прямой запуск: ash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh) 1h)*

---

## 📊 5. Мониторинг всех серверов кластера (Cluster Live Monitor)

Параллельный интерактивный монитор всех серверов кластера со статусами VPN и Samba:

`ash
servers_stat
`
*(Или алиас: stars)*

---

## 🛡️ 6. Антивирус ClamAV (Antivirus Suite)

Интерактивное меню ClamAV:

`ash
antivir
`

---

## 🔄 7. Синхронизация репозитория на серверах

- **load** — мгновенно подтягивает все свежие скрипты из GitHub на сервер.
- **save** — фиксирует локальные изменения и пушит в GitHub.

---

*= Rooted by VladiMIR + AI | v.2026.08.25 | github.com/GinCz/Linux_Server_Public =*
