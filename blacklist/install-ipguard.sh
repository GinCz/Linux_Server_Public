#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  install-ipguard.sh [FORWARDER]   █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Legacy wrapper forwarding to /IPGuard/install-ipguard.sh
# Servers     : All Linux Nodes
# Usage       : bash blacklist/install-ipguard.sh -> executes IPGuard/install-ipguard.sh
# ==========================================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_LOCAL="$(dirname "$SCRIPT_DIR")/IPGuard/install-ipguard.sh"

if [[ -f "$TARGET_LOCAL" ]]; then
    exec bash "$TARGET_LOCAL" "$@"
else
    exec bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/IPGuard/install-ipguard.sh) "$@"
fi

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
