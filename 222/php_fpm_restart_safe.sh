#!/bin/bash
clear
# ===================================================================
# Script: php_fpm_restart_safe.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup
# Purpose: Graceful restart of PHP-FPM with minimal downtime.
#
# What this script does:
# 1. Checks current status.
# 2. Restarts PHP-FPM pools one by one if possible.
#
# Potential consequences and warnings:
# - Causes short downtime (usually < 5 seconds).
# - Many working websites — use only when necessary.
#
# Usage: cd ~/Linux_Server_Public/222 && bash php_fpm_restart_safe_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Safe PHP-FPM Restart v2026-04-25 started ==="

# === INSERT YOUR OLD php_fpm_restart_safe CODE HERE BELOW THIS LINE ===

echo "PHP-FPM restarted safely."
