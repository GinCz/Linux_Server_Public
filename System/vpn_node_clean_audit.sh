#!/usr/bin/env bash
# Description: VPN Node Maintenance (Log Purge & System Audit)
# Focus: Auto-cleaning logs/benchmarks and monitoring Network/Disk/Samba
C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; X='\033[0m'

# 1. MAINTENANCE: Purge Logs and Benchmark leftovers
journalctl --vacuum-time=1s >/dev/null 2>&1
find /var/log -type f -regex ".*\.log\|.*\.gz" -delete 2>/dev/null
find / -maxdepth 2 -type f -name "*test_file*" -delete 2>/dev/null
rm -f ~/test_file ~/temp_vps_test

clear
H="$(hostname)"; D="$(date)"; UP="$(uptime -p)"
echo -e "${Y}==================== VPN NODE: $H ====================${X}"
echo -e "Status: ${G}PURGED & CLEANED${X} | Time: $D | $UP"

# 2. RESOURCE USAGE
echo -e "\n${C}--- RESOURCE USAGE ---${X}"
free -h | awk '/Mem:/{printf "RAM: %s / %s (Used: %s)\n", $3, $2, $3}'
D_USE=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
D_INF=$(df -h / | awk 'NR==2{printf "Disk: %s / %s (%s used)", $3, $2, $5}')
[ "$D_USE" -gt 80 ] && echo -e "${R}⚠️  $D_INF (CRITICAL)${X}" || echo -e "✅ $D_INF"

# 3. NETWORK STATS
echo -e "\n${C}--- NETWORK STATS ---${X}"
ss -s | grep -E "Total|TCP:|UDP:"
echo -e "${G}Traffic Flow:${X}"
ip -s link | awk '/^[0-9]: (eth0|ens3|enp)/ {
    iface=$2; sub(/:/,"",iface); 
    getline; getline; rx=$1; 
    getline; tx=$1; 
    printf "  %-6s: RX=%-7s TX=%-7s\n", iface, (rx/1024/1024 > 1024 ? sprintf("%.1fG", rx/1024/1024/1024) : sprintf("%.1fM", rx/1024/1024)), (tx/1024/1024 > 1024 ? sprintf("%.1fG", tx/1024/1024/1024) : sprintf("%.1fM", tx/1024/1024))
}'

# 4. SERVICES & PROCESSES
echo -e "\n${C}--- ACTIVITY ---${X}"
command -v iostat >/dev/null && iostat -xd 1 1 | awk '/Device/ {p=1; next} p && $1!="" {print "Device: " $1 " | Load: " $14 "%"}' || echo "iostat not found"
command -v pdbedit >/dev/null && echo -e "Samba Users: $(pdbedit -L | wc -l)"
echo -e "\n${C}--- TOP PROCESSES ---${X}"
ps -eo user,pcpu,pmem,comm --sort=-pcpu | grep -vE "(ps|awk|grep|\[)" | head -n 6
echo -e "\n${C}--- SYSTEM ERRORS (dmesg) ---${X}"
dmesg -T | tail -n 5 | sed 's/^/  /'
echo -e "${Y}==========================================================${X}"
