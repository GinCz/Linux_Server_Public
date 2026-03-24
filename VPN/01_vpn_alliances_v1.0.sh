#!/bin/bash
clear
# 01_vpn_alliances_v1.0.sh — Setup aliases + MC menu on any VPN server
# Version: v2026-03-24
# Author: Ing. VladiMIR Bulantsev
# Usage: bash /root/Linux_Server_Public/VPN/01_vpn_alliances_v1.0.sh
#
# What this script does:
# 1. Clones Linux_Server_Public repo if not present, or pulls latest
# 2. Copies VPN/.bashrc to /root/.bashrc
# 3. Copies VPN/mc.menu to /root/.config/mc/menu
# 4. Sources .bashrc immediately
# 5. Tests: aw (AmneziaWG stats)

echo "=== VPN ALIASES + MC MENU SETUP ==="
echo

# Step 1: Clone repo or pull latest
if [ ! -d /root/Linux_Server_Public ]; then
    echo "[1/4] Cloning repo..."
    cd /root && git clone git@github.com:GinCz/Linux_Server_Public.git
else
    echo "[1/4] Repo found — pulling latest..."
    cd /root/Linux_Server_Public && git pull --rebase
fi

# Step 2: Install .bashrc
echo "[2/4] Installing VPN .bashrc..."
cp /root/Linux_Server_Public/VPN/.bashrc /root/.bashrc

# Step 3: Install MC menu
echo "[3/4] Installing MC menu..."
mkdir -p /root/.config/mc
cp /root/Linux_Server_Public/VPN/mc.menu /root/.config/mc/menu

# Step 4: Apply aliases
echo "[4/4] Applying aliases..."
source /root/.bashrc

echo
echo "============================="
echo " Done! VPN server ready."
echo "============================="
echo
echo "Aliases available:"
echo "  aw       — AmneziaWG client stats"
echo "  sos      — server audit 1h"
echo "  sos3     — server audit 3h"
echo "  sos24    — server audit 24h"
echo "  sos120   — server audit 120h"
echo "  infooo   — server info"
echo "  backup   — system backup"
echo "  load     — git pull + apply"
echo "  save     — git push"
echo "  m        — Midnight Commander (F2 = menu)"
echo "  00       — clear screen"
echo
echo "Testing aw..."
bash /root/Linux_Server_Public/scripts/amnezia_stat.sh
