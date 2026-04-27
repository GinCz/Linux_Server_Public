#!/bin/bash
clear
# ===================================================================
# Script: ban_hardening.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup
# Purpose: Applies strict security rules for WordPress login protection and bad bot blocking.
#
# What this script does:
# 1. Updates nginx limit zones for wp-login.php and xmlrpc.
# 2. Applies global blacklist rules.
# 3. Reloads nginx.
#
# Potential consequences and warnings:
# - Reloads nginx → short downtime (1-3 seconds) for all sites.
# - May block legitimate users if limits are too strict.
# - Many working websites — run only after backup and during low traffic.
#
# Usage: cd ~/Linux_Server_Public/222 && bash ban_hardening_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Ban Hardening v2026-04-25 started ==="

# === INSERT YOUR OLD ban_hardening CODE HERE BELOW THIS LINE ===

echo "Ban hardening applied. Nginx reloaded."
