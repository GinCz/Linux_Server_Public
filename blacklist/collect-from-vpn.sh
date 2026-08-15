#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  collect-from-vpn.sh [FORWARDER]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Legacy wrapper forwarding to /IPGuard/collect-from-vpn.sh
# Servers     : Server 222-DE (Master Node) ONLY
# Usage       : bash blacklist/collect-from-vpn.sh -> executes IPGuard/collect-from-vpn.sh
# ==========================================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_LOCAL="$(dirname "$SCRIPT_DIR")/IPGuard/collect-from-vpn.sh"

if [[ -f "$TARGET_LOCAL" ]]; then
    exec bash "$TARGET_LOCAL" "$@"
else
    exec bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/IPGuard/collect-from-vpn.sh) "$@"
fi

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
