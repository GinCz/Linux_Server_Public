#!/bin/bash
clear
# ===================================================================
# Script: optimize_php.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup (152.53.182.222)
# Purpose: General PHP performance optimization (opcache, realpath_cache, session settings).
#
# What this script does:
# 1. Backs up php.ini files.
# 2. Applies optimal opcache and session parameters.
# 3. Restarts PHP-FPM.
#
# Potential consequences and warnings:
# - WILL restart PHP-FPM → short downtime (2-10 seconds) for all PHP sites.
# - Many working websites on the server — run only during maintenance window after backup.
#
# Usage: cd ~/Linux_Server_Public/222 && bash optimize_php_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== PHP General Optimization v2026-04-25 started ==="

# === INSERT YOUR OLD optimize_php CODE HERE BELOW THIS LINE ===

echo "PHP optimization completed."
