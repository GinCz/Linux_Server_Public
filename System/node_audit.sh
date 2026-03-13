#!/usr/bin/env bash
# Description: VPN Node Auditor (Network & Disk focus)
# Focus: Bandwidth, I/O Load, Samba, System Health
clear; C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; X='\033[0m'
H="$(hostname)"; D="$(date)"

echo -e "${Y}==================== NODE REPORT: $H ====================${X}"
echo -e "Time: $D | $(uptime -p)"

echo -e "\n${C}--- RESOURCE USAGE ---${X}"
free -h | awk '/Mem:/{printf "RAM: %s / %s (Used: %s)\n", $3, $2, $3}'
df -h / | awk 'NR==2{printf "Disk: %s / %s (%s used)\n", $3, $2, $5}'

echo -e "\n${C}--- NETWORK STATS (Connections & Traffic) ---${X}"
ss -s | grep -E "Total|TCP:|UDP:"
echo -e "${G}Interface Activity:${X}"
ip -s link | awk '/^[0-9]: (eth0|ens3|enp|en|wl)/ {iface=$2; getline; getline; print iface " RX=" $1 " B, TX=" $1 " B"}'

echo -e "\n${C}--- SAMBA & DISK I/O ---${X}"
if command -v iostat >/dev/null; then
  iostat -xd 1 1 | awk '/Device/ {p=1; next} p && $1!="" {print "Device: " $1 " | Load: " $14 "% | Write: " $4 "MB/s"}'
else
  echo "iostat missing (apt install sysstat)"
fi
command -v pdbedit >/dev/null && echo -e "${G}Samba Users:${X} $(pdbedit -L | wc -l)"

echo -e "\n${C}--- TOP PROCESSES (CPU/RAM) ---${X}"
ps -eo user,pcpu,pmem,comm --sort=-pcpu | grep -vE "(ps|awk|grep|\[)" | head -n 6

echo -e "\n${C}--- RECENT SYSTEM ERRORS (dmesg) ---${X}"
dmesg -T | tail -n 5 | sed 's/^/  /'
echo -e "${Y}==========================================================${X}"
