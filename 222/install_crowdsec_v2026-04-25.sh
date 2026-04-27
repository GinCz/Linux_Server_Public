#!/bin/bash
clear
# ===================================================================
# Script: install_crowdsec.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup
# Purpose: Installs or updates CrowdSec security system.
#
# What this script does:
# 1. Installs CrowdSec and bouncer.
# 2. Applies basic collections.
# 3. Restarts services.
#
# Potential consequences and warnings:
# - Restarts nginx/CrowdSec → short downtime possible.
# - Many working websites — run after backup.
#
# Usage: cd ~/Linux_Server_Public/222 && bash install_crowdsec_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== CrowdSec Installation v2026-04-25 started ==="

# === INSERT YOUR OLD install_crowdsec CODE HERE BELOW THIS LINE ===

echo "CrowdSec installation/update completed."
