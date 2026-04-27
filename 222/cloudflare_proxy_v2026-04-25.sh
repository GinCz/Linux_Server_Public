#!/bin/bash
clear
# ===================================================================
# Script: cloudflare_proxy.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup
# Purpose: Configures nginx to correctly handle real visitor IP from Cloudflare.
#
# What this script does:
# 1. Adds Cloudflare IP ranges to real_ip_header.
# 2. Reloads nginx.
#
# Potential consequences and warnings:
# - Reloads nginx → short downtime (1-3 seconds) for all sites.
# - Many working websites — run after backup.
#
# Usage: cd ~/Linux_Server_Public/222 && bash cloudflare_proxy_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Cloudflare Proxy Setup v2026-04-25 started ==="

# === INSERT YOUR OLD cloudflare_proxy CODE HERE BELOW THIS LINE ===

echo "Cloudflare proxy configured."
