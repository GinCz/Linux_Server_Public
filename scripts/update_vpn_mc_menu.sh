#!/usr/bin/env bash
MC_DIR="/root/.config/mc"
mkdir -p "$MC_DIR"
MC_MENU="$MC_DIR/menu"

printf '%s\n' \
'# Midnight Commander F2 User Menu' \
'' \
'0   00 — Clear screen' \
'    clear' \
'' \
'b   banlist — CrowdSec ban list' \
'    clear; cscli decisions list 2>/dev/null || echo "CrowdSec not installed"; printf "\nPress any key..."; read k' \
'' \
'i   infooo — Server Info' \
'    /usr/local/bin/infooo' \
'' \
'a   antivir — ClamAV antivirus scan' \
'    bash /root/Linux_Server_Public/scripts/scan_clamav.sh' \
'' \
'1   sos — Server Audit (1h)' \
'    /usr/local/bin/sos 1h' \
'' \
'3   sos3 — Server Audit (3h)' \
'    /usr/local/bin/sos 3h' \
'' \
'4   sos24 — Server Audit (24h)' \
'    /usr/local/bin/sos 24h' \
'' \
'5   sos120 — Server Audit (120h)' \
'    /usr/local/bin/sos 120h' \
'' \
'u   upd — apt upgrade + cleanup + reboot' \
'    bash /root/Linux_Server_Public/scripts/upd.sh' \
'' \
'l   load — Git pull' \
'    /usr/local/bin/load' > "$MC_MENU"

echo "MC Menu updated!"
