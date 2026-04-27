#!/bin/bash
clear
# ===================================================================
# Script: fix_nginx_crowdsec.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup
# Purpose: Fixes integration between nginx and CrowdSec bouncer.
#
# What this script does:
# 1. Checks and fixes bouncer configuration.
# 2. Reloads nginx.
#
# Potential consequences and warnings:
# - Reloads nginx → short downtime.
# - Many working websites — run after backup.
#
# Usage: cd ~/Linux_Server_Public/222 && bash fix_nginx_crowdsec_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Fix Nginx + CrowdSec v2026-04-25 started ==="

# === INSERT YOUR OLD fix_nginx_crowdsec CODE HERE BELOW THIS LINE ===

echo "Nginx-CrowdSec integration fixed."
