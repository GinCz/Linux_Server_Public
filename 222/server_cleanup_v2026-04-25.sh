#!/bin/bash
clear
# ===================================================================
# Script: server_cleanup.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup (152.53.182.222)
# Purpose: Safe cleanup of temporary files, old logs, apt cache and unused packages.
#
# What this script does:
# 1. Cleans apt cache and old journal logs.
# 2. Removes temporary files.
# 3. Cleans old PHP session files if needed.
#
# Potential consequences and warnings:
# - Deletes old logs and temp files — you will lose old debug information.
# - Frees disk space.
# - No direct impact on running websites, but may cause short I/O load.
# - Many working websites on the server — run after backup and during low traffic.
#
# Usage: cd ~/Linux_Server_Public/222 && bash server_cleanup_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Server Cleanup v2026-04-25 started ==="

# === INSERT YOUR OLD server_cleanup CODE HERE BELOW THIS LINE ===

echo "Server cleanup completed."
