#!/bin/bash
clear
# ===================================================================
# Script: php_fpm_watchdog.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup
# Purpose: Monitors PHP-FPM and auto-restarts problematic pools.
#
# What this script does:
# 1. Checks PHP-FPM status and memory usage.
# 2. Restarts pools if thresholds exceeded.
#
# Potential consequences and warnings:
# - May restart PHP-FPM → short downtime for some sites.
# - Many working websites — run after backup.
#
# Usage: cd ~/Linux_Server_Public/222 && bash php_fpm_watchdog_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== PHP-FPM Watchdog v2026-04-25 started ==="

# === INSERT YOUR OLD php_fpm_watchdog CODE HERE BELOW THIS LINE ===

echo "PHP-FPM watchdog check completed."
