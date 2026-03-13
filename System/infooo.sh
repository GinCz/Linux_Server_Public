#!/usr/bin/env bash
clear
echo -e "\e[1;36m============================================================\e[0m"
echo -e "\e[1;32m 📊 ADVANCED SERVER INFO\e[0m"
echo -e "\e[1;36m============================================================\e[0m"
echo -e "\e[1;33m▶ SYSTEM:\e[0m $(lsb_release -d 2>/dev/null | cut -f2-) | Kernel: $(uname -r)"
echo -e "\e[1;33m▶ UPTIME:\e[0m $(uptime -p)"
echo -e "\e[1;33m▶ CPU:\e[0m $(lscpu | grep "Model name" | cut -f 2 -d ":" | awk '{$1=$1}1') ($(nproc) vCores)"
echo -e "\e[1;33m▶ LOAD AVG:\e[0m $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo -e "\e[1;36m------------------------------------------------------------\e[0m"
echo -e "\e[1;33m▶ NETWORK:\e[0m"
echo -e "  Public IP: $(curl -s ifconfig.me 2>/dev/null)"
echo -e "  Local IP:  $(hostname -I | awk '{print $1}')"
echo -e "\e[1;36m------------------------------------------------------------\e[0m"
echo -e "\e[1;33m▶ RAM USAGE:\e[0m"
free -h | awk 'NR==1{print "  " $0} NR==2{print "  " $0}'
echo -e "\e[1;36m------------------------------------------------------------\e[0m"
echo -e "\e[1;33m▶ DISK USAGE (Active Partitions):\e[0m"
df -h -x tmpfs -x devtmpfs | grep -v "loop" | awk '{print "  " $0}'
echo -e "\e[1;36m------------------------------------------------------------\e[0m"
echo -e "\e[1;33m▶ TOP 5 PROCESSES (By RAM):\e[0m"
ps -eo pid,cmd,%mem,%cpu --sort=-%mem | head -n 6 | awk '{print "  " $0}'
echo -e "\e[1;36m============================================================\e[0m"
