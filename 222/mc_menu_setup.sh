#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  mc_menu_setup.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Deploy Midnight Commander interactive menu for server 222-DE
# Servers     : 222-DE NetCup (152.53.182.222)
# Usage       : bash 222/mc_menu_setup.sh
# ==========================================================================================

mkdir -p ~/.config/mc
cat > ~/.config/mc/menu << 'EOF'
+ ! t t
0       Clear Screen (00)
	clear

+ ! t t
1       Quick Server Audit (15 min) (sos)
	clear
	/usr/local/bin/sos 1h
	read -p "Press Enter to exit..."

+ ! t t
2       Server Audit (1 hour) (sos1)
	clear
	/usr/local/bin/sos 1h
	read -p "Press Enter to exit..."

+ ! t t
3       Server Audit (24 hours) (sos24)
	clear
	/usr/local/bin/sos 24h
	read -p "Press Enter to exit..."

+ ! t t
4       Bot Shield (fight)
	clear
	bash /root/Linux_Server_Public/scripts/block_bots.sh
	read -p "Press Enter to exit..."

+ ! t t
5       Domain Health Check (domains)
	clear
	bash /root/Linux_Server_Public/scripts/domains.sh
	read -p "Press Enter to exit..."

+ ! t t
6       Full Backup & Sync (backup)
	clear
	bash /root/Linux_Server_Public/scripts/system_backup.sh
	read -p "Press Enter to exit..."

+ ! t t
7       CrowdSec Active Bans (antivir)
	clear
	cscli decisions list
	read -p "Press Enter to exit..."

+ ! t t
8       CrowdSec Recent Alerts (banlog)
	clear
	bash /root/Linux_Server_Public/scripts/banlog.sh 30
	read -p "Press Enter to exit..."

+ ! t t
9       System Info (infooo)
	clear
	bash /root/Linux_Server_Public/scripts/infooo.sh --run
	read -p "Press Enter to exit..."

+ ! t t
Q       Quick Status (qs)
	clear
	bash /root/Linux_Server_Public/scripts/quick_status.sh --run
	read -p "Press Enter to exit..."
EOF

echo "✔ MC Menu installed for 222-DE (~/.config/mc/menu)"

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
