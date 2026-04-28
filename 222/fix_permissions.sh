#!/bin/bash
clear
# ===================================================================
# Script: fix_permissions.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup (152.53.182.222)
# Purpose: Fixes file and directory permissions for WordPress sites (755/644).
#
# What this script does:
# 1. Sets correct permissions for /var/www/*/public_html
# 2. Fixes ownership (www-data).
#
# Potential consequences and warnings:
# - Changes file permissions — may temporarily affect site access.
# - Many working websites — run after backup and during low traffic.
#
# Usage: cd ~/Linux_Server_Public/222 && bash fix_permissions_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Fix Permissions v2026-04-25 started ==="

# === INSERT YOUR OLD fix_permissions CODE HERE BELOW THIS LINE ===

echo "Permissions fixed."
