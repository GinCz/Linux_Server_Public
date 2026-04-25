#!/usr/bin/env bash
# Configures Midnight Commander F2 Menu
mkdir -p /root/.config/mc
cat > /root/.config/mc/menu << 'MENU'
+ ! t t
0   Clear Screen
	clear
+ ! t t
1   Quick Audit (sos)
	/usr/local/bin/server_audit.sh
+ ! t t
2   Fight Bots (fight)
	/root/scripts/block_bots.sh
+ ! t t
3   Backup System (backup)
	/usr/local/bin/backup
+ ! t t
4   System Info & Benchmark (infoo)
	/usr/local/bin/infoo
MENU
echo "MC Menu updated. Press F2 in MC to see changes."

echo "========================================="
echo "📘 HOW TO ADD USERS (READ THIS):"
echo "https://github.com/GinCz/Linux_Server_Public/tree/main/xray"
echo "========================================="

