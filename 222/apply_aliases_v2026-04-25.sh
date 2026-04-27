#!/bin/bash
clear
# ===================================================================
# Script: apply_aliases.sh
# Version: v2026-04-25
# Server: 222-DE-NetCup
# Purpose: Reloads aliases and .bashrc without logout.
#
# What this script does:
# 1. Sources latest .bashrc and aliases.
#
# Potential consequences and warnings:
# - Affects only current session.
# - No impact on websites.
# - Safe.
#
# Usage: cd ~/Linux_Server_Public/222 && bash apply_aliases_v2026-04-25.sh
#
# = Rooted by VladiMIR | AI =
# github.com/GinCz/Linux_Server_Public
# ===================================================================

echo "=== Apply Aliases v2026-04-25 ==="

source ~/.bashrc 2>/dev/null || true
echo "✅ Aliases reloaded successfully."
