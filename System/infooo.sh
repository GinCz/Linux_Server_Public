#!/usr/bin/env bash
clear
echo -e "\e[1;36m=========================================\e[0m"
echo -e "\e[1;32m 📊 SERVER INFO\e[0m"
echo -e "\e[1;36m=========================================\e[0m"
echo -e "▶ \e[1;33mOS:\e[0m $(lsb_release -d 2>/dev/null | cut -f2-)"
echo -e "▶ \e[1;33mUPTIME:\e[0m $(uptime -p)"
echo -e "▶ \e[1;33mLOAD:\e[0m $(cat /proc/loadavg | awk '{print $1, $2, $3}')"
echo -e "▶ \e[1;33mRAM:\e[0m $(free -m | awk '/Mem:/ {printf "%d MB used / %d MB total", $3, $2}')"
echo -e "▶ \e[1;33mDISK:\e[0m $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
echo -e "\e[1;36m=========================================\e[0m"
