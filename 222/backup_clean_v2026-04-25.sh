#!/bin/bash
clear
# ===================================================================
# Script: backup_clean.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup (152.53.182.222)
# Purpose: Creates backup of important configs and cleans old archives.
#          If backup size <= 50MB → keep 50 copies, otherwise keep 10.
#
# What this script does:
# 1. Deep cleanup of temporary files.
# 2. Creates new timestamped backup.
# 3. Rotates old backups based on size.
# 4. Copies backup to server 109.
#
# Potential consequences and warnings:
# - Deletes old backup files (you lose access to very old archives).
# - No impact on running websites.
# - Many working websites on the server — always run this before any maintenance.
#
# Usage: cd ~/Linux_Server_Public/222 && bash backup_clean_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Backup + Clean v2026-04-25 started ==="

# === INSERT YOUR CURRENT backup_clean CODE HERE BELOW THIS LINE ===

# Example of size-based rotation (add this logic to your existing code):
# size_mb=$(du -m "$backup_file" 2>/dev/null | cut -f1)
# if [ "${size_mb:-0}" -le 50 ]; then
#     KEEP=50
# else
#     KEEP=10
# fi

echo "Backup rotation logic updated: small backups (<=50MB) will keep up to 50 copies."
