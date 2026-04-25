#!/bin/bash
# =============================================================
# Script: xray_installer.sh
# Version: v2026-04-25
# Server: Universal (clean Ubuntu 22.04/24.04)
# Description: Full automatic XRAY + 3x-ui installation
#              No prompts, no manual fixes needed
#              Shows working URL, login and password at the end
# =============================================================
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin
clear

# Colors
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${RED}=========================================${NC}"
echo -e "${RED}     XRAY + 3x-ui INSTALLER             ${NC}"
echo -e "${RED}=========================================${NC}\n"

# Cleanup
echo -e "${YELLOW}[1/6] Cleaning server...${NC}"
systemctl stop xray x-ui 2>/dev/null
rm -rf /usr/local/x-ui /usr/local/xray /etc/xray
apt remove -y x-ui 2>/dev/null
ufw disable 2>/dev/null

# Dependencies
echo -e "${YELLOW}[2/6] Installing dependencies...${NC}"
apt update -y
apt install -y curl wget ufw socat

# Install panel
echo -e "${YELLOW}[3/6] Installing XRAY + 3x-ui...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh) << EOF
1
y
EOF

sleep 3

# Get real data
echo -e "${YELLOW}[4/6] Fetching credentials...${NC}"
REAL_PORT=$(x-ui settings 2>/dev/null | grep -oP 'port: \K\d+')
REAL_PATH=$(x-ui settings 2>/dev/null | grep -oP 'webBasePath: \K/\S+')
SERVER_IP=$(curl -s ifconfig.me)
USER=$(x-ui settings 2>/dev/null | grep -oP 'username: \K\S+')
PASS=$(x-ui settings 2>/dev/null | grep -oP 'password: \K\S+')

# Firewall
echo -e "${YELLOW}[5/6] Configuring firewall...${NC}"
ufw allow $REAL_PORT/tcp
ufw allow 22/tcp
echo "y" | ufw --force enable

# Final output
clear
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}        INSTALLATION COMPLETE!           ${NC}"
echo -e "${GREEN}=========================================${NC}\n"
echo -e "${CYAN}URL:${NC}      http://$SERVER_IP:$REAL_PORT$REAL_PATH"
echo -e "${CYAN}LOGIN:${NC}    $USER"
echo -e "${CYAN}PASSWORD:${NC} $PASS"
echo -e "${GREEN}=========================================${NC}"
echo -e "${YELLOW}Firewall: port $REAL_PORT is OPEN${NC}"
echo -e "${GREEN}=========================================${NC}\n"
