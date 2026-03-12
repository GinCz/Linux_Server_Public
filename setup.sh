#!/usr/bin/env bash
clear
# English comments: Global Infrastructure Orchestrator v2.0
CONF_FILE="/root/.server_env"
[ ! -f "$CONF_FILE" ] && { echo "❌ Error: /root/.server_env missing!"; exit 1; }
source "$CONF_FILE"

echo "============================================================"
echo "🛡️  VladiMIR's Infrastructure Deployment Center"
echo "============================================================"
echo "Select Server Type:"
echo "1) [001] Main Node (NetCup 222, FastPanel, Cloudflare)"
echo "2) [002] RU Node (FastVDS 109, FastPanel, No Cloudflare, Hard Security)"
echo "3) [003] VPN Node (Amnezia, Samba, Monitoring)"
echo "q) Exit"
echo "------------------------------------------------------------"
read -p "Enter choice [1-3]: " CHOICE

case $CHOICE in
    1) bash ./modules/001_netcup_main.sh ;;
    2) bash ./modules/002_fastvds_ru.sh ;;
    3) bash ./modules/003_vpn_node.sh ;;
    q) exit 0 ;;
    *) echo "Invalid choice";;
esac
