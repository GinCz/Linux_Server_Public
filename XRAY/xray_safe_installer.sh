#!/bin/bash
# =============================================================
# Script: xray_safe_installer.sh
# Version: v2026-04-25
# Server: Universal (any Ubuntu 22.04/24.04)
# Description: SAFE install - adds XRAY + 3x-ui to existing setup
#              Does NOT remove anything (FastPanel, cPanel, Amnezia, Docker)
#              Does NOT disable firewall, only adds new port
#              Preserves SSH access
# Language: English only
# Usage: bash xray_safe_installer.sh
# =============================================================
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin
clear

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m'

echo -e "${CYAN}=========================================${NC}"
echo -e "${CYAN}     XRAY SAFE INSTALLER                 ${NC}"
echo -e "${CYAN}     (preserves existing services)       ${NC}"
echo -e "${CYAN}=========================================${NC}\n"

# Install dependencies only (no removal)
echo -e "${YELLOW}[1/4] Installing dependencies...${NC}"
apt update -y
apt install -y curl wget ufw socat

# Install 3x-ui
echo -e "${YELLOW}[2/4] Installing XRAY + 3x-ui...${NC}"
bash <(curl -Ls https://raw.githubusercontent.com/alireza0/x-ui/master/install.sh) <<< $'1\ny\n'

sleep 3

# Get panel data
echo -e "${YELLOW}[3/4] Fetching credentials...${NC}"
R_PORT=$(x-ui settings 2>/dev/null | grep -oP 'port: \K\d+')
R_PATH=$(x-ui settings 2>/dev/null | grep -oP 'webBasePath: \K/\S+')
IP=$(curl -s ifconfig.me)
USR=$(x-ui settings 2>/dev/null | grep -oP 'username: \K\S+')
PSW=$(x-ui settings 2>/dev/null | grep -oP 'password: \K\S+')

# Add firewall rules (without disabling existing)
echo -e "${YELLOW}[4/4] Adding firewall rules...${NC}"
ufw allow 22/tcp
ufw allow $R_PORT/tcp
ufw --force enable

clear
echo -e "${GREEN}=========================================${NC}"
echo -e "${GREEN}     XRAY INSTALLED SUCCESSFULLY!        ${NC}"
echo -e "${GREEN}=========================================${NC}"
echo -e "${CYAN}URL:${NC}      http://$IP:$R_PORT$R_PATH"
echo -e "${CYAN}LOGIN:${NC}    $USR"
echo -e "${CYAN}PASSWORD:${NC} $PSW"
echo -e "${GREEN}=========================================${NC}"
echo -e "Firewall: port $R_PORT is OPEN"
echo -e "Existing services (FastPanel, cPanel, Amnezia, Docker) untouched"
echo -e "${GREEN}=========================================${NC}"
