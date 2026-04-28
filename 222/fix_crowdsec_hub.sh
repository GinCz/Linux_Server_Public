#!/bin/bash
clear
# ===================================================================
# Script: fix_crowdsec_hub.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup
# Purpose: Fixes CrowdSec hub, updates scenarios and restarts services.
#
# What this script does:
# 1. Updates CrowdSec hub.
# 2. Reinstalls collections.
# 3. Restarts CrowdSec and bouncer.
#
# Potential consequences and warnings:
# - Restarts CrowdSec → short nginx reload possible (1-3 seconds).
# - Many working websites — run after backup.
#
# Usage: cd ~/Linux_Server_Public/222 && bash fix_crowdsec_hub_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Fix CrowdSec Hub v2026-04-25 started ==="

# === INSERT YOUR OLD fix_crowdsec_hub CODE HERE BELOW THIS LINE ===

echo "CrowdSec hub fix completed."
