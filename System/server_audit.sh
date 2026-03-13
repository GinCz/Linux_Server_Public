#!/usr/bin/env bash
HRS=${1:-24}
clear
echo -e "\e[1;31m=========================================\e[0m"
echo -e "\e[1;33m 🚨 SERVER AUDIT (Last ${HRS} hours)\e[0m"
echo -e "\e[1;31m=========================================\e[0m"
echo -e "\e[1;32m▶ TOP 10 Failed SSH Logins (IPs):\e[0m"
journalctl -u ssh --since "${HRS} hours ago" 2>/dev/null | grep "Failed password" | awk '{print $(NF-3)}' | sort | uniq -c | sort -nr | head -n 10
echo -e "\e[1;31m-----------------------------------------\e[0m"
echo -e "\e[1;32m▶ System Errors (OOM, Disk Space):\e[0m"
journalctl --since "${HRS} hours ago" 2>/dev/null | egrep -i "Out of memory|No space left on device" | tail -n 5 || echo "No critical errors found."
echo -e "\e[1;31m=========================================\e[0m"
