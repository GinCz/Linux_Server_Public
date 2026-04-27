#!/bin/bash
clear
# ===================================================================
# Script: docker_backup.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup
# Purpose: Creates backup of Docker containers and volumes (used for VPN services).
#
# What this script does:
# 1. Backs up Docker volumes and compose files.
# 2. Saves archives to /BACKUP.
# 3. Optionally sends to server 109.
#
# Potential consequences and warnings:
# - May briefly stop Docker containers → short downtime for VPN services.
# - No impact on main FASTPANEL websites.
# - Many working websites — run after backup_clean.
#
# Usage: cd ~/Linux_Server_Public/222 && bash docker_backup_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Docker Backup v2026-04-25 started ==="

# === INSERT YOUR OLD docker_backup CODE HERE BELOW THIS LINE ===

echo "Docker backup completed."
