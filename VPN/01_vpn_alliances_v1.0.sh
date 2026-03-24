#!/bin/bash
clear
# 01_vpn_alliances_v1.0.sh — Setup aliases on any VPN server
# Version: v2026-03-24
# Author: Ing. VladiMIR Bulantsev
# Usage: bash /root/Linux_Server_Public/VPN/01_vpn_alliances_v1.0.sh
#
# What this script does:
# 1. Clones Linux_Server_Public repo if not present
# 2. Copies VPN/.bashrc to /root/.bashrc
# 3. Adds shared_aliases.sh source if missing
# 4. Sources .bashrc immediately (aw, vpnstat, load, save work right away)

echo "=== VPN ALIASES SETUP ==="
echo

# Step 1: Clone repo if missing
if [ ! -d /root/Linux_Server_Public ]; then
    echo "[1/3] Cloning repo..."
    cd /root && git clone https://github.com/GinCz/Linux_Server_Public.git
else
    echo "[1/3] Repo found, pulling latest..."
    cd /root/Linux_Server_Public && git pull --rebase
fi

# Step 2: Install .bashrc
echo "[2/3] Installing VPN .bashrc..."
cp /root/Linux_Server_Public/VPN/.bashrc /root/.bashrc

# Step 3: Source immediately
echo "[3/3] Applying aliases..."
source /root/.bashrc

echo
echo "============================="
echo " Aliases installed!"
echo "============================="
echo
echo "Available commands:"
echo "  aw / vpnstat  — AmneziaWG client stats"
echo "  sos           — server audit 1h"
echo "  sos3/sos24    — audit 3h / 24h"
echo "  i             — server info"
echo "  load          — git pull + apply"
echo "  save          — git push"
echo "  m             — Midnight Commander"
echo "  00            — clear screen"
echo
echo "Testing aw..."
bash /root/Linux_Server_Public/scripts/amnezia_stat.sh
