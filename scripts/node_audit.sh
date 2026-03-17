#!/usr/bin/env bash
# Script:  node_audit.sh
# Version: v2026-03-17
# Purpose: VPN node health report: RAM, disk, network, Samba, top processes, dmesg.
#          Designed for Type 3 VPN servers.
# Usage:   /opt/server_tools/scripts/node_audit.sh
# Alias:   sos (on VPN nodes)

clear
C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; X='\033[0m'
H="$(hostname)"; D="$(date)"

echo -e "${Y}==================== NODE REPORT: $H ====================${X}"
echo -e "Time: $D | $(uptime -p)"

echo -e "\n${C}--- RESOURCE USAGE ---${X}"
free -h | awk '/Mem:/{printf "RAM: %s / %s used\n", $3, $2}'
df -h / | awk 'NR==2{printf "Disk: %s / %s (%s used)\n", $3, $2, $5}'

echo -e "\n${C}--- NETWORK STATS ---${X}"
ss -s | grep -E "Total|TCP:|UDP:"
echo -e "${G}Interface traffic:${X}"
ip -s link show | awk '
    /^[0-9]+: (eth|ens|enp|en)[^:]*:/ { iface=$2 }
    iface && /RX:/ { getline; rx=$1 }
    iface && /TX:/ { getline; print iface " RX=" rx " B  TX=" $1 " B"; iface="" }
'

echo -e "\n${C}--- SAMBA & DISK I/O ---${X}"
if command -v iostat >/dev/null; then
    iostat -xd 1 1 | awk '/Device/{p=1;next} p && $1!=""{printf "%-10s load: %s%%  write: %s MB/s\n", $1, $14, $4}'
else
    echo "iostat not found — install: apt install sysstat"
fi
command -v pdbedit >/dev/null \
    && echo -e "${G}Samba users:${X} $(pdbedit -L 2>/dev/null | wc -l)" \
    || echo "Samba not installed"

echo -e "\n${C}--- TOP PROCESSES (CPU/RAM) ---${X}"
ps -eo user,pcpu,pmem,comm --sort=-pcpu | grep -vE "(ps|awk|grep|\[)" | head -n 6

echo -e "\n${C}--- RECENT SYSTEM ERRORS (dmesg) ---${X}"
dmesg -T 2>/dev/null | tail -n 5 | sed 's/^/  /'

echo -e "${Y}==========================================================${X}"
