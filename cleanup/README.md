# 🧹 Server Cleanup & Disk Optimizer

Глубокая дисковая очистка и безопасная оптимизация накопителей для Linux-серверов (**Ubuntu 24.04 / 22.04**, **Debian 12**, **DietPi**).

---

## ⚡ Быстрый запуск в 1 команду

``bash
clear; apt-get update -qq && apt-get install -y -qq curl ca-certificates && bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/server_cleanup.sh)
``

*(На серверах с настроенными алиасами достаточно просто набрать команду: cleanup)*

---

## 🛡️ Безопасность и защищенные сервисы

Скрипт **100% безопасен** для продакшн-серверов, веб-нод и VPN:
- 🔐 **VPN:** x-ui, xray, mnezia, wireguard — туннели и трафик не прерываются;
- 🗂️ **Samba:** smbd, 
mbd — сетевые диски и шары активны;
- 🌐 **Web & DB:** 
ginx, astpanel2, mariadb, mysql, php*-fpm — сессии и веб-сайты работают без даунтайма;
- 🛡️ **DNS & Monitoring:** AdGuardHome, uptime-kuma, cryptobot (Docker);
- 🛡️ **Безопасность:** ssh, dropbear, crowdsec, ail2ban, ufw.

---

## 🛠️ Что очищается:

1. **Журналы systemd-journald:** сжатие и вакуум до 30 MB / 2 дней;
2. **Пакеты и ядра APT:** utoremove --purge, clean, utoclean, удаление старых модулей ядер;
3. **Умный Swapfile:** уменьшение избыточного swapfile (с 3 GB до 1 GB) на компактных VPS (<= 35 GB) с сохранением zram;
4. **Телеметрия Canonical:** удаление pport, whoopsie, ubuntu-report, popularity-contest;
5. **Временные файлы и логи:** /tmp, /var/tmp, /var/crash, архивы *.gz, *.1, *.old без удаления активных сокетов .sock;
6. **Docker кэш:** docker system prune -f --volumes (если установлен Docker).
