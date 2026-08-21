#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  amnezia_stat.sh | [v2026-08-21]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : VPN node live status reporter (AmneziaWG / WireGuard / Xray / X-UI)
# Servers     : All VPN Nodes
# Usage       : bash scripts/amnezia_stat.sh
# ==========================================================================================

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"; R="\033[1;31m"; W="\033[1;37m"; X="\033[0m"
HR="${C}==========================================================================================${X}"

echo -e "$HR"
echo -e "  🌐  ${W}$(hostname)${X}  ${C}$(hostname -I | awk '{print $1}')${X}  —  ${Y}VPN NODE STATUS${X}"
echo -e "$HR"

# 1. Check AmneziaWG Docker container
if command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' | grep -qiE 'amnezia|awg'; then
    CONT=$(docker ps --format '{{.Names}}' | grep -iE 'amnezia|awg' | head -n1)
    echo -e "${G}● AmneziaWG Container:${X} ${W}${CONT}${X} (running)"
    echo -e "${C}--- AmneziaWG Status ---${X}"
    docker exec "$CONT" awg show 2>/dev/null || docker exec "$CONT" wg show 2>/dev/null || echo "No active peers"
    echo ""
fi

# 2. Check native AmneziaWG / WireGuard
if command -v awg >/dev/null 2>&1 && awg show >/dev/null 2>&1; then
    echo -e "${G}● Native AmneziaWG (awg):${X}"
    awg show
    echo ""
elif command -v wg >/dev/null 2>&1 && wg show >/dev/null 2>&1; then
    echo -e "${G}● Native WireGuard (wg):${X}"
    wg show
    echo ""
fi

# 3. Check Xray / X-UI
if systemctl is-active --quiet x-ui 2>/dev/null || pgrep -f "xray" >/dev/null 2>&1; then
    echo -e "${G}● Xray / X-UI Core:${X} ${G}ACTIVE${X}"
    echo -e "${C}Listening VPN Ports:${X}"
    ss -tulnp | grep -E 'xray|x-ui' | awk '{printf "  %-8s %-25s %s\n", $1, $5, $7}'
    echo ""
    echo -e "${C}Recent Xray Logs (last 10 lines):${X}"
    journalctl -u xray -n 10 --no-pager 2>/dev/null || journalctl -u x-ui -n 10 --no-pager 2>/dev/null || true
    echo ""
fi

# 4. Check AdGuard Home
if systemctl is-active --quiet AdGuardHome 2>/dev/null; then
    echo -e "${G}● AdGuard Home:${X} ${G}ACTIVE${X}"
    ss -tulnp | grep -i adguard | awk '{printf "  %-8s %-25s %s\n", $1, $5, $7}'
    echo ""
fi

echo -e "$HR"
