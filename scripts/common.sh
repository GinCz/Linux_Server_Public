#!/usr/bin/env bash
# Script:  common.sh
# Version: v2026-03-17
# Purpose: Shared functions library for server scripts (222 and 109).
#          Source this file in other scripts: source /opt/server_tools/scripts/common.sh
# Usage:   Not called directly — sourced by other scripts.

source /root/.server_alliances.conf 2>/dev/null || true

is_interactive() {
    [ -t 1 ] || [ -n "${SSH_TTY:-}" ]
}

lock_or_exit() {
    mkdir -p /var/lock
    exec 9>"/var/lock/$1.lock"
    flock -n 9 || exit 0
}

# Detect server type by IP: returns "222" or "109"
detect_node() {
    IP="$(hostname -I | awk '{print $1}')"
    [[ "$IP" == "152.53.182.222" ]] && echo "222" || echo "109"
}
