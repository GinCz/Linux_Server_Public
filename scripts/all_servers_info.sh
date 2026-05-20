#!/usr/bin/env bash
clear
# =============================================================
# Script:      all_servers_info.sh
# Version:     v2026.05.21
# Location:    scripts/all_servers_info.sh
# Server:      222-DE-NetCup (run from here for all servers)
# Description: Quick ping/SSH check of all known servers.
#              Shows: ping, SSH port open, uptime via SSH.
# Usage:       allinfo
# = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =
# =============================================================

C="\033[1;36m"
G="\033[1;32m"
Y="\033[1;33m"
W="\033[1;37m"
R="\033[1;31m"
X="\033[0m"
LINE="══════════════════════════════════════════════════════════════════════════════════"

SSH_OPTS="-o ConnectTimeout=5 -o StrictHostKeyChecking=no -o BatchMode=yes -o LogLevel=ERROR"

echo -e "${C}${LINE}${X}"
echo -e "  ${Y}ALL SERVERS STATUS CHECK${X}   $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "${C}${LINE}${X}"
printf "  ${Y}%-28s %-16s %-8s %-8s %s${X}\n" "SERVER" "IP" "PING" "SSH" "UPTIME / INFO"
echo -e "${C}${LINE}${X}"

check_server() {
    local NAME="$1"
    local IP="$2"
    local PORT="${3:-22}"
    local SSH_USER="${4:-root}"

    # Ping check
    if ping -c1 -W3 "$IP" &>/dev/null; then
        PING_STATUS="${G}OK${X}"
    else
        PING_STATUS="${R}FAIL${X}"
    fi

    # SSH port check
    if timeout 5 bash -c "echo > /dev/tcp/$IP/$PORT" 2>/dev/null; then
        SSH_STATUS="${G}OK${X}"
        # Try to get uptime
        UPTIME_RAW=$(ssh $SSH_OPTS -p "$PORT" "${SSH_USER}@${IP}" "uptime -p 2>/dev/null || echo 'no uptime'" 2>/dev/null)
        UPTIME_INFO=$(echo "$UPTIME_RAW" | sed 's/up //' | cut -c1-30)
        [ -z "$UPTIME_INFO" ] && UPTIME_INFO="${Y}(no key)${X}"
    else
        SSH_STATUS="${R}FAIL${X}"
        UPTIME_INFO="${R}unreachable${X}"
    fi

    printf "  ${W}%-28s${X} ${C}%-16s${X} %-14b %-14b %b\n" \
        "$NAME" "$IP" "$PING_STATUS" "$SSH_STATUS" "$UPTIME_INFO"
}

# ── MAIN SERVERS ─────────────────────────────────────────────
check_server "222-DE-NetCup (this)"     "152.53.182.222"   22
check_server "109-RU-FastVDS"           "212.109.223.109"  22

# ── VPN NODES ────────────────────────────────────────────────
# Add your VPN node IPs below (SSH port may differ)
# check_server "VPN-Node-1"             "1.2.3.4"          22
# check_server "VPN-Node-2"             "5.6.7.8"          22

echo -e "${C}${LINE}${X}"
echo -e "  ${Y}Hint:${X} To add VPN nodes — edit ${W}scripts/all_servers_info.sh${X}"
echo -e "  ${Y}SSH key required for uptime. Without key — ping+port only.${X}"
echo -e "${C}${LINE}${X}"
echo
