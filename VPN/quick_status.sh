#!/usr/bin/env bash
# Description: Fast audit of Docker, Services, Ports, Samba, and Disk.
# Alias: qstat
clear; echo "--- DOCKER ---"; docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" 2>/dev/null; echo -e "\n--- SERVICES ---"; systemctl list-units --type=service --state=running | grep -vE "systemd|dbus|docker"; echo -e "\n--- PORTS ---"; netstat -tulpn 2>/dev/null | grep LISTEN; echo -e "\n--- SAMBA ---"; pdbedit -L 2>/dev/null; echo -e "\n--- DISK ---"; df -h /
