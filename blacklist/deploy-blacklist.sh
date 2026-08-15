#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  deploy-blacklist.sh [FORWARDER]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Legacy wrapper forwarding to /IPGuard/deploy-blacklist.sh
# Servers     : All Linux Nodes (222-DE / 109-RU / VPN Nodes)
# Usage       : bash blacklist/deploy-blacklist.sh -> executes IPGuard/deploy-blacklist.sh
# ==========================================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_LOCAL="$(dirname "$SCRIPT_DIR")/IPGuard/deploy-blacklist.sh"

if [[ -f "$TARGET_LOCAL" ]]; then
    exec bash "$TARGET_LOCAL" "$@"
else
    exec bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/IPGuard/deploy-blacklist.sh) "$@"
fi

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
