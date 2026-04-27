#!/bin/bash
clear
# ===================================================================
# Script: nginx_hardening.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup
# Purpose: Applies additional security headers and hardening for nginx.
#
# What this script does:
# 1. Adds security headers (HSTS, CSP, X-Frame-Options etc.).
# 2. Reloads nginx.
#
# Potential consequences and warnings:
# - Reloads nginx → short downtime (1-3 seconds) for all sites.
# - Many working websites — run after backup.
#
# Usage: cd ~/Linux_Server_Public/222 && bash nginx_hardening_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Nginx Hardening v2026-04-25 started ==="

# === INSERT YOUR OLD nginx_hardening CODE HERE BELOW THIS LINE ===

echo "Nginx hardening applied."
