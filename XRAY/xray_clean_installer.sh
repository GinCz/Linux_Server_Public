#!/bin/bash
# =============================================================
# Script: xray_clean_installer.sh
# Version: v2026-04-25
# Server: Universal (clean Ubuntu 22.04/24.04)
# Description: CLEAN install - removes old Xray/3x-ui before installation
#              Preserves SSH access (port 22 opened first)
#              Removes: old Xray, old 3x-ui, old configs
#              Does NOT touch: FastPanel, cPanel, Amnezia, Docker
# Language: English only
# Usage: bash xray_clean_installer.sh
# =============================================================
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin
clear

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${RED}=========================================${NC}"
echo -e "${RED}     XRAY CLEAN INSTALLER                ${NC}"
echo -e "${RED}     (removes old Xray only)             ${NC}"
echo -e "${RED}=========================================${NC}\n"

# Clean only Xray/3x-ui (not other services)
echo -e "${YELLOW}[1/5] Removing old Xray/3x-ui...${NC}"
systemctl stop xray x-ui 2>/dev/null
rm -rf /usr/local/x-ui /usr/local/xray /etc/xray
apt remove -y x-ui 2>/dev/null

# Install dependencies
echo -e "${YELLOW}[2/5] Installing dependencies...${NC}"
apt update -y
apt install -y curl wget ufw socat

# Install 3x-ui
echo -e "${YELLOW}[3/5] Installing XRAY + 3x-ui...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh) <<< $'1\ny\n'

sleep 3

# Get panel data
echo -e "${YELLOW}[4/5] Fetching credentials...${NC}"
R_PORT=$(x-ui settings 2>/dev/null | grep -oP 'port: \K\d+')
R_PATH=$(x-ui settings 2>/dev/null | grep -oP 'webBasePath: \K/\S+')
IP=$(curl -s ifconfig.me)
USR=$(x-ui settings 2>/dev/null | grep -oP 'username: \K\S+')
PSW=$(x-ui settings 2>/dev/null | grep -oP 'password: \K\S+')

# Configure firewall (preserve SSH)
echo -e "${YELLOW}[5/5] Configuring firewall...${NC}"
ufw allow 22/tcp
ufw allow $R_PORT/tcp
echo "y" | ufw --force enable

clear
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}     XRAY INSTALLED SUCCESSFULLY!        ${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "${CYAN}URL:${NC}      http://$IP:$R_PORT$R_PATH"
echo -e "${CYAN}LOGIN:${NC}    $USR"
echo -e "${CYAN}PASSWORD:${NC} $PSW"
echo -e "${GREEN}=========================================${NC}"
echo -e "Firewall: port $R_PORT is OPEN, SSH preserved"
echo -e "${GREEN}=========================================${NC}"

echo "========================================="
echo "📘 HOW TO ADD USERS (READ THIS):"
echo "https://github.com/GinCz/Linux_Server_Public/tree/main/xray"
echo "========================================="

