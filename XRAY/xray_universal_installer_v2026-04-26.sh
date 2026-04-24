#!/bin/bash
# =============================================================
# Script: xray_universal_installer_v2026-04-26.sh
# Version: v2026-04-26
# Server: Универсальный (чистый Ubuntu 22.04/24.04)
# Description: Полная установка XRAY + 3x-ui панель
#              Исправлено: Xray слушает на 0.0.0.0, порты открыты
# Usage: bash xray_universal_installer_v2026-04-26.sh
# =============================================================
clear

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}=========================================================${NC}"
echo -e "${CYAN}     XRAY + 3x-ui UNIVERSAL INSTALLER v2026-04-26       ${NC}"
echo -e "${CYAN}=========================================================${NC}\n"

# 1. Базовые пакеты
echo -e "${YELLOW}>>> Установка зависимостей...${NC}"
apt update -y && apt upgrade -y
apt install -y curl wget ufw nano socat tar unzip jq git mc htop net-tools sqlite3

# 2. Настройка UFW (открываем всё)
echo -e "${YELLOW}>>> Настройка фаервола...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
for PORT in 80 443 2096 8443 8080 8888 30000 30001 30002 30003 30004 30005 40000 45000 50000 60000 35942; do
    ufw allow $PORT/tcp 2>/dev/null
done
echo "y" | ufw --force enable
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F

# 3. Установка XRAY + 3x-ui
echo -e "${YELLOW}>>> Установка XRAY + 3x-ui панели...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) << EOF
1
y
EOF

# 4. ПРИНУДИТЕЛЬНАЯ НАСТРОЙКА: Xray слушает на 0.0.0.0
echo -e "${YELLOW}>>> Настройка Xray на прослушивание всех интерфейсов...${NC}"
systemctl stop xray 2>/dev/null
sleep 2

XRAY_CONFIG="/usr/local/x-ui/bin/config.json"
if [ -f "$XRAY_CONFIG" ]; then
    sed -i 's/"listen": "127.0.0.1"/"listen": "0.0.0.0"/g' "$XRAY_CONFIG"
    echo -e "${GREEN}✅ Конфиг Xray исправлен (слушает на 0.0.0.0)${NC}"
fi

# 5. Запуск сервисов
systemctl start xray 2>/dev/null || (nohup /usr/local/x-ui/bin/xray run -c "$XRAY_CONFIG" > /dev/null 2>&1 &)
systemctl restart x-ui
sleep 3

# 6. Получение данных панели
SERVER_IP=$(curl -s ifconfig.me)
PANEL_PORT=$(x-ui settings 2>/dev/null | grep -oP 'port: \K\d+' | head -1)
PANEL_PATH=$(x-ui settings 2>/dev/null | grep -oP 'webBasePath: \K/\S+' | head -1)
PANEL_USER=$(x-ui settings 2>/dev/null | grep -oP 'username: \K\S+' | head -1)
PANEL_PASS=$(x-ui settings 2>/dev/null | grep -oP 'password: \K\S+' | head -1)

# 7. MOTD меню
cat > /etc/profile.d/motd_xray.sh << 'MOTD'
#!/bin/bash
if [ "$EUID" -ne 0 ]; then return 0; fi
BOLD='\033[1m'; RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
HOSTNAME=$(hostname); IP=$(hostname -I | awk '{print $1}')
RAM_TOTAL=$(free -m | awk '/^Mem:/{print $2}'); RAM_USED=$(free -m | awk '/^Mem:/{print $3}')
CPU_LOAD=$(uptime | awk -F'load average:' '{print $2}' | awk -F',' '{print $1}' | xargs)
XRAY_STATUS=$(systemctl is-active xray 2>/dev/null || echo "inactive")
PANEL_STATUS=$(systemctl is-active x-ui 2>/dev/null || echo "inactive")
XRAY_ICON="${GREEN}●${NC}"; [ "$XRAY_STATUS" != "active" ] && XRAY_ICON="${RED}○${NC}"
PANEL_ICON="${GREEN}●${NC}"; [ "$PANEL_STATUS" != "active" ] && PANEL_ICON="${RED}○${NC}"
PANEL_PORT=$(x-ui settings 2>/dev/null | grep -oP 'port: \K\d+' | head -1)
PANEL_PATH=$(x-ui settings 2>/dev/null | grep -oP 'webBasePath: \K/\S+' | head -1)
clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  🖥  ${HOSTNAME}${NC}          ${IP}          RAM: ${RAM_USED}/${RAM_TOTAL}MB  CPU: ${CPU_LOAD}"
echo -e "  XRAY VPN: ${XRAY_ICON} ${XRAY_STATUS}     PANEL: ${PANEL_ICON} ${PANEL_STATUS}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  xray-url${NC}      ${GREEN}xui-settings${NC}    ${GREEN}xray-status${NC}     ${GREEN}vstat${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "  Panel: https://${IP}:${PANEL_PORT}${PANEL_PATH:-/} | Login: $(x-ui settings 2>/dev/null | grep -oP 'username: \K\S+' | head -1)"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
MOTD
chmod +x /etc/profile.d/motd_xray.sh

# 8. Алиасы
cat >> /root/.bashrc << 'ALIASES'
alias xray-url='echo "https://$(curl -s ifconfig.me):$(x-ui settings 2>/dev/null | grep -oP "port: \K\d+" | head -1)$(x-ui settings 2>/dev/null | grep -oP "webBasePath: \K/\S+" | head -1)"'
alias xui-settings='x-ui settings'
alias xray-status='systemctl status xray --no-pager'
alias xray-restart='systemctl restart xray'
alias vstat='systemctl status xray x-ui --no-pager | grep -E "Active|Loaded"'
alias 00='clear'
ALIASES
source /root/.bashrc

# 9. Финальный вывод
clear
echo -e "${GREEN}=========================================================${NC}"
echo -e "${GREEN}              УСТАНОВКА ЗАВЕРШЕНА!                       ${NC}"
echo -e "${GREEN}=========================================================${NC}\n"
echo -e "${CYAN}🔗 ССЫЛКА ДЛЯ ВХОДА В ПАНЕЛЬ:${NC}"
echo -e "   ${GREEN}https://$SERVER_IP:$PANEL_PORT$PANEL_PATH${NC}\n"
echo -e "${CYAN}👤 ДАННЫЕ ДЛЯ ВХОДА:${NC}"
echo -e "   Логин: ${GREEN}$PANEL_USER${NC}"
echo -e "   Пароль: ${GREEN}$PANEL_PASS${NC}\n"
echo -e "${CYAN}📋 КОМАНДЫ ДЛЯ УПРАВЛЕНИЯ:${NC}"
echo -e "   ${GREEN}xray-url${NC}      - показать ссылку на панель"
echo -e "   ${GREEN}xui-settings${NC}  - настройки панели"
echo -e "   ${GREEN}xray-status${NC}   - статус XRAY"
echo -e "   ${GREEN}vstat${NC}         - быстрая проверка\n"
echo -e "${GREEN}✅ Выйдите и зайдите заново по SSH для красивого меню${NC}\n"
