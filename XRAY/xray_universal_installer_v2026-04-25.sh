#!/bin/bash
# =============================================================
# Script: xray_universal_installer_v2026-04-25.sh
# Version: v2026-04-25
# Server: Универсальный (чистый Ubuntu 22.04/24.04)
# Description: Полная установка XRAY + 3x-ui панель + MOTD меню
# Usage: bash xray_universal_installer_v2026-04-25.sh
# =============================================================
clear

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}=========================================================${NC}"
echo -e "${CYAN}     XRAY + 3x-ui UNIVERSAL INSTALLER v2026-04-25       ${NC}"
echo -e "${CYAN}=========================================================${NC}\n"

# 1. Обновление и базовые пакеты
echo -e "${YELLOW}>>> Установка зависимостей...${NC}"
apt update -y && apt upgrade -y
apt install -y curl wget ufw nano socat tar unzip jq git mc htop net-tools bc

# 2. Настройка UFW
echo -e "${YELLOW}>>> Настройка фаервола...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 2096/tcp
echo "y" | ufw --force enable

# 3. Установка XRAY + 3x-ui
echo -e "${YELLOW}>>> Установка XRAY + 3x-ui панели...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) << EOF
1
y
EOF

# 4. Получаем данные панели
sleep 3
XRAY_PORT=$(x-ui settings 2>/dev/null | grep -oP 'port: \K\d+' | head -1)
XRAY_PATH=$(x-ui settings 2>/dev/null | grep -oP 'webBasePath: \K/\S+' | head -1)
XRAY_USER=$(x-ui settings 2>/dev/null | grep -oP 'username: \K\S+' | head -1)
XRAY_PASS=$(x-ui settings 2>/dev/null | grep -oP 'password: \K\S+' | head -1)
SERVER_IP=$(curl -s ifconfig.me)

# 5. СОЗДАНИЕ КРАСИВОГО MOTD МЕНЮ
echo -e "${YELLOW}>>> Создание MOTD меню...${NC}"

mkdir -p /etc/profile.d/

cat > /etc/profile.d/motd_xray.sh << 'MOTD'
#!/bin/bash
# XRAY VPN Server MOTD - Rooted by VladiMIR | AI

if [ "$EUID" -ne 0 ]; then
    return 0
fi

# Colors
BOLD='\033[1m'
DIM='\033[2m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'

# Get server info
HOSTNAME=$(hostname)
IP=$(hostname -I | awk '{print $1}')
RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}')
RAM_USED=$(free -m | awk '/^Mem:/{print $3}')
RAM_PERCENT=$((RAM_USED * 100 / RAM_TOTAL))
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
UPTIME=$(uptime -p | sed 's/up //')
XRAY_STATUS=$(systemctl is-active xray 2>/dev/null || echo "inactive")
PANEL_STATUS=$(systemctl is-active x-ui 2>/dev/null || echo "inactive")

if [ "$XRAY_STATUS" = "active" ]; then
    XRAY_ICON="${GREEN}●${NC}"
else
    XRAY_ICON="${RED}○${NC}"
fi

if [ "$PANEL_STATUS" = "active" ]; then
    PANEL_ICON="${GREEN}●${NC}"
else
    PANEL_ICON="${RED}○${NC}"
fi

# Get panel settings
PANEL_PORT=$(x-ui settings 2>/dev/null | grep -oP 'port: \K\d+' | head -1)
PANEL_PATH=$(x-ui settings 2>/dev/null | grep -oP 'webBasePath: \K/\S+' | head -1)
PANEL_USER=$(x-ui settings 2>/dev/null | grep -oP 'username: \K\S+' | head -1)
PANEL_PASS=$(x-ui settings 2>/dev/null | grep -oP 'password: \K\S+' | head -1)

clear
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${WHITE}  🖥  ${BOLD}${HOSTNAME}${NC}${WHITE}           ${IP}${NC}          ${WHITE}RAM:${NC} ${RAM_USED}${GRAY}/${RAM_TOTAL}MB${NC} ${WHITE}CPU:${NC} ${CPU_LOAD}"
echo -e "${WHITE}  XRAY VPN: ${XRAY_ICON} ${XRAY_STATUS}     PANEL: ${PANEL_ICON} ${PANEL_STATUS}${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${CYAN}  XRAY PANEL                VPN MANAGEMENT            TOOLS${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  xray-url${GRAY}(show panel link)${NC}   ${YELLOW}xray-status${GRAY}(status)${NC}        ${GREEN}vstat${GRAY}(full audit)${NC}"
echo -e "${GREEN}  xui-settings${GRAY}(panel config)${NC}  ${YELLOW}xray-restart${GRAY}(restart)${NC}     ${GREEN}xray-log${GRAY}(view logs)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  save${GRAY}(git push)${NC}               ${YELLOW}load${GRAY}(git pull)${NC}           ${GREEN}00${GRAY}(clear screen)${NC}"
echo -e "${GREEN}  infooo${GRAY}(full info)${NC}            ${YELLOW}backup${GRAY}(local backup)${NC}      ${GREEN}mc${GRAY}(Midnight Cmdr)${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${DIM}  Panel: https://${IP}:${PANEL_PORT}${PANEL_PATH:-/} | Login: ${PANEL_USER:-unknown}${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GRAY}  ${HOSTNAME} | up ${UPTIME} | load: ${CPU_LOAD}${NC}"
echo ""
MOTD

chmod +x /etc/profile.d/motd_xray.sh

# 6. СОЗДАНИЕ АЛИАСОВ
echo -e "${YELLOW}>>> Создание алиасов...${NC}"

cat >> /root/.bashrc << 'ALIASES'

# XRAY VPN Aliases
alias xray-status='systemctl status xray --no-pager'
alias xray-restart='systemctl restart xray'
alias xray-log='journalctl -u xray -f --no-pager'
alias xui-status='systemctl status x-ui --no-pager'
alias xui-restart='systemctl restart x-ui'
alias xui-settings='x-ui settings'
alias xray-url='echo "https://$(curl -s ifconfig.me):$(x-ui settings 2>/dev/null | grep -oP "port: \K\d+" | head -1)$(x-ui settings 2>/dev/null | grep -oP "webBasePath: \K/\S+" | head -1)"'

# System Aliases
alias 00='clear'
alias infooo='hostnamectl && free -h && df -h / && echo "IP: $(curl -s ifconfig.me)"'
alias vstat='systemctl status xray x-ui --no-pager | grep -E "Active|Loaded"'
alias backup='tar -czf /root/xray_backup_$(date +%Y%m%d).tar.gz /usr/local/x-ui /etc/xray 2>/dev/null'
alias load='cd /root/Linux_Server_Public && git pull 2>/dev/null || echo "No repo"'
alias save='cd /root/Linux_Server_Public && git add . && git commit -m "Save $(date +%Y-%m-%d_%H:%M)" && git push 2>/dev/null || echo "No repo"'

# Midnight Commander
alias mc='mc -a'
ALIASES

# 7. СОЗДАНИЕ MC F2 МЕНЮ
mkdir -p /root/.config/mc
cat > /root/.config/mc/menu << 'MCMENU'
+-------[F2] XRAY VPN Management Menu-------------------+
| 00      Clear screen                                |
| xray-url  Show panel link                           |
| xray-status  Xray status                            |
| xray-restart  Restart Xray                          |
| xui-settings  Panel settings                        |
| vstat    Quick audit                                |
| infooo   Full system info                           |
| backup   Backup configs                             |
| load     Update from GitHub                         |
| save     Save to GitHub                             |
+-----------------------------------------------------+
MCMENU

source /root/.bashrc

# 8. ФИНАЛЬНЫЙ ВЫВОД
clear
echo -e "${GREEN}=========================================================${NC}"
echo -e "${GREEN}              УСТАНОВКА ЗАВЕРШЕНА!                       ${NC}"
echo -e "${GREEN}=========================================================${NC}\n"

echo -e "${CYAN}🔗 ДАННЫЕ ДЛЯ ВХОДА В ПАНЕЛЬ:${NC}"
echo -e "   ${GREEN}https://$SERVER_IP:${XRAY_PORT:-unknown}${XRAY_PATH:-/}${NC}"
echo -e "   ${GREEN}Логин: ${XRAY_USER:-unknown}${NC}"
echo -e "   ${GREEN}Пароль: ${XRAY_PASS:-unknown}${NC}\n"

echo -e "${CYAN}📋 КОМАНДЫ ДЛЯ УПРАВЛЕНИЯ:${NC}"
echo -e "   ${GREEN}xray-url${NC}      - показать ссылку на панель"
echo -e "   ${GREEN}xui-settings${NC}  - показать настройки панели"
echo -e "   ${GREEN}xray-status${NC}   - статус XRAY"
echo -e "   ${GREEN}vstat${NC}         - быстрая проверка\n"

echo -e "${CYAN}🔄 ДЛЯ ОБНОВЛЕНИЯ MOTD (после смены IP):${NC}"
echo -e "   ${GREEN}bash /etc/profile.d/motd_xray.sh${NC}\n"

echo -e "${GREEN}✅ Выйдите и зайдите заново по SSH, чтобы увидеть красивое меню!${NC}\n"
