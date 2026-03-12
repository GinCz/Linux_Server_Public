#!/usr/bin/env bash
clear
# English comments: Global Infrastructure Orchestrator v2.1
# Author: Ing. VladiMIR Bulantsev

CONF_FILE="/root/.server_env"
[ ! -f "$CONF_FILE" ] && { echo "❌ Error: /root/.server_env missing!"; exit 1; }
source "$CONF_FILE"

echo "============================================================"
echo "🛡️  VladiMIR's Infrastructure Deployment Center"
echo "============================================================"
echo "Select Server Type:"
echo "1) 💎 [222_FastPanel_EU]"
echo "2) 🇷🇺 [109_FastPanel_RU]"
echo "3) 🚀 [VPN_Server]"
echo "q) Exit"
echo "------------------------------------------------------------"
read -p "Enter choice [1-3]: " CHOICE

case $CHOICE in
    1) 
       export SERVER_TAG="💎 222_FastPanel_EU"
       bash ./modules/001_netcup_main.sh 
       ;;
    2) 
       export SERVER_TAG="🇷🇺 109_FastPanel_RU"
       bash ./modules/002_fastvds_ru.sh 
       ;;
    3) 
       export SERVER_TAG="🚀 VPN_Server"
       bash ./modules/003_vpn_node.sh 
       ;;
    q) exit 0 ;;
    *) echo "Invalid choice";;
esac
