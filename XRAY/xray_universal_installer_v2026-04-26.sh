#!/bin/bash
# =============================================================
# Script: xray_universal_installer_v2026-04-26.sh
# Version: v2026-04-26-FINAL
# Server: Universal (clean Ubuntu 22.04/24.04)
# Description: Interactive XRAY + 3x-ui panel installer
#              Asks for username/password, forces 0.0.0.0
# =============================================================
clear

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'

echo -e "${CYAN}=========================================================${NC}"
echo -e "${CYAN}     XRAY + 3x-ui INTERACTIVE INSTALLER v2026-04-26     ${NC}"
echo -e "${CYAN}=========================================================${NC}\n"

# --- Get credentials ---
echo -e "${YELLOW}Please enter credentials for the 3x-ui admin panel:${NC}"
read -p "Username (default: admin): " INPUT_USERNAME
INPUT_USERNAME=${INPUT_USERNAME:-admin}

read -sp "Password (default: auto-generated): " INPUT_PASSWORD
echo ""
if [ -z "$INPUT_PASSWORD" ]; then
    INPUT_PASSWORD=$(tr -dc 'A-Za-z0-9!?%=' < /dev/urandom | head -c 16)
    echo -e "${YELLOW}Auto-generated password: ${GREEN}$INPUT_PASSWORD${NC}"
fi

# --- 1. Dependencies ---
echo -e "\n${YELLOW}>>> Installing dependencies...${NC}"
apt update -y && apt upgrade -y
apt install -y curl wget ufw nano socat tar unzip jq git mc htop net-tools sqlite3

# --- 2. Firewall ---
echo -e "${YELLOW}>>> Configuring UFW firewall...${NC}"
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp
for PORT in 80 443 2096 8443 8080 8888 30000 30001 30002 30003 30004 30005 40000 45000 50000 60000 35942 54321; do
    ufw allow $PORT/tcp 2>/dev/null
done
echo "y" | ufw --force enable
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F

# --- 3. Install 3x-ui ---
echo -e "${YELLOW}>>> Installing XRAY + 3x-ui panel...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh) << EOF
1
y
EOF

# --- 4. Force config ---
echo -e "${YELLOW}>>> Applying custom settings (0.0.0.0, credentials)...${NC}"
systemctl stop x-ui
systemctl stop xray
sleep 2

# Set port and path
PORT=54321
WEB_BASE_PATH="/admin"
x-ui setting -port ${PORT}
x-ui setting -webBasePath ${WEB_BASE_PATH}
x-ui setting -username ${INPUT_USERNAME}
x-ui setting -password ${INPUT_PASSWORD}

# Patch Xray config
XRAY_CONFIG="/usr/local/x-ui/bin/config.json"
if [ -f "$XRAY_CONFIG" ]; then
    sed -i 's/"listen": "127.0.0.1"/"listen": "0.0.0.0"/g' "$XRAY_CONFIG"
    echo -e "${GREEN}✅ Xray config patched to listen on 0.0.0.0${NC}"
fi

# --- 5. Start services ---
systemctl daemon-reload
systemctl start xray
systemctl start x-ui
systemctl enable xray
systemctl enable x-ui
sleep 3

# --- 6. Collect final data ---
SERVER_IP=$(curl -s ifconfig.me)
FINAL_PORT=$(x-ui settings 2>/dev/null | grep -oP 'port: \K\d+' | head -1)
FINAL_PATH=$(x-ui settings 2>/dev/null | grep -oP 'webBasePath: \K/\S+' | head -1)

# --- 7. MOTD menu ---
cat > /etc/profile.d/motd_xray.sh << 'MOTD'
#!/bin/bash
if [ "$EUID" -ne 0 ]; then return 0; fi
BOLD='\033[1m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; NC='\033[0m'
IP=$(hostname -I | awk '{print $1}')
PANEL_PORT=$(x-ui settings 2>/dev/null | grep -oP 'port: \K\d+' | head -1)
PANEL_PATH=$(x-ui settings 2>/dev/null | grep -oP 'webBasePath: \K/\S+' | head -1)
PANEL_USER=$(x-ui settings 2>/dev/null | grep -oP 'username: \K\S+' | head -1)
clear
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  🖥  XRAY VPN SERVER${NC}          ${IP}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  Panel: https://${IP}:${PANEL_PORT}${PANEL_PATH:-/}${NC}"
echo -e "${GREEN}  Login: ${PANEL_USER}${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════════════════════${NC}"
MOTD
chmod +x /etc/profile.d/motd_xray.sh

# --- 8. Aliases ---
cat >> /root/.bashrc << 'ALIASES'
alias xray-url='echo "https://$(curl -s ifconfig.me):$(x-ui settings 2>/dev/null | grep -oP "port: \K\d+" | head -1)$(x-ui settings 2>/dev/null | grep -oP "webBasePath: \K/\S+" | head -1)"'
alias xui-settings='x-ui settings'
alias xray-status='systemctl status xray --no-pager'
alias xray-restart='systemctl restart xray'
alias vstat='systemctl status xray x-ui --no-pager | grep -E "Active|Loaded"'
alias 00='clear'
ALIASES
source /root/.bashrc

# --- 9. Final output ---
clear
echo -e "${GREEN}=========================================================${NC}"
echo -e "${GREEN}              INSTALLATION COMPLETE!                     ${NC}"
echo -e "${GREEN}=========================================================${NC}\n"
echo -e "${CYAN}🔗 PANEL ACCESS URL:${NC}"
echo -e "   ${GREEN}https://$SERVER_IP:$FINAL_PORT$FINAL_PATH${NC}\n"
echo -e "${CYAN}👤 LOGIN:${NC}    ${GREEN}$INPUT_USERNAME${NC}"
echo -e "${CYAN}🔑 PASSWORD:${NC} ${GREEN}$INPUT_PASSWORD${NC}\n"
echo -e "${CYAN}📋 USEFUL COMMANDS:${NC}"
echo -e "   ${GREEN}xray-url${NC}      - show panel link"
echo -e "   ${GREEN}xui-settings${NC}  - panel settings"
echo -e "   ${GREEN}xray-status${NC}   - XRAY status"
echo -e "   ${GREEN}vstat${NC}         - quick check\n"
echo -e "${GREEN}✅ Logout and login again to see the MOTD menu${NC}\n"

cat > /root/xray_panel_info.txt << EOF
=========================================
XRAY PANEL INFO - $(date)
=========================================
URL: https://$SERVER_IP:$FINAL_PORT$FINAL_PATH
Login: $INPUT_USERNAME
Password: $INPUT_PASSWORD
=========================================
EOF
echo -e "${GREEN}✅ Credentials saved to /root/xray_panel_info.txt${NC}"
