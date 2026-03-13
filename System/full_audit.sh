#!/usr/bin/env bash
# Description: Full system audit (Docker, Services, Ports, FW, Samba, Disk, RAM)
clear; C='\033[1;36m'; X='\033[0m'
echo -e "${C}--- DOCKER CONTAINERS ---${X}"; command -v docker >/dev/null && docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "No Docker installed"
echo -e "\n${C}--- ACTIVE SERVICES (Non-System) ---${X}"; systemctl list-units --type=service --state=running | grep -vE "systemd|dbus|docker|getty" | head -n 12
echo -e "\n${C}--- OPEN PORTS (LISTEN) ---${X}"; ss -tulpn | grep LISTEN
echo -e "\n${C}--- FIREWALL STATUS (UFW) ---${X}"; command -v ufw >/dev/null && ufw status | head -n 10 || echo "UFW missing"
echo -e "\n${C}--- SAMBA USERS ---${X}"; command -v pdbedit >/dev/null && pdbedit -L || echo "No Samba installed"
echo -e "\n${C}--- ACTIVE SSH SESSIONS ---${X}"; w
echo -e "\n${C}--- DISK SPACE ---${X}"; df -h -x tmpfs -x devtmpfs | grep -v "loop"
echo -e "\n${C}--- TOP 5 RAM CONSUMERS ---${X}"; ps -eo user,cmd,%mem,%cpu --sort=-%mem | head -n 6
