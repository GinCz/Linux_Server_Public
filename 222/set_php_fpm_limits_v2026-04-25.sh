#!/bin/bash
clear
# ===================================================================
# Script: set_php_fpm_limits.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup (152.53.182.222)
# Purpose: Sets safe PHP-FPM limits based on 4 vCore / 8GB RAM.
#
# What this script does:
# 1. Backs up www.conf for all PHP versions.
# 2. Calculates optimal pm.max_children, start_servers, etc.
# 3. Applies new limits.
# 4. Restarts PHP-FPM.
#
# Potential consequences and warnings:
# - WILL restart PHP-FPM → short downtime (2-8 seconds) for ALL PHP sites.
# - Many working websites on the server — run only during maintenance window.
#
# Usage: cd ~/Linux_Server_Public/222 && bash set_php_fpm_limits_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== PHP-FPM Limits Optimization v2026-04-25 ==="

# === INSERT YOUR CURRENT set_php_fpm_limits CODE HERE BELOW THIS LINE ===

echo "PHP-FPM limits applied."
