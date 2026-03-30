#!/usr/bin/env bash
clear
# =============================================================================
# vpn_deploy.sh — Run a command on ALL VPN servers via SSH loop
# =============================================================================
# Version : v2026-03-30
# Author  : Ing. VladiMIR Bulantsev
# Usage   : bash /root/Linux_Server_Public/222/vpn_deploy.sh
#           or alias: vpndeploy
# = Rooted by VladiMIR | AI =
# =============================================================================
#
# SERVER NOTES (do NOT remove services on these servers!):
#   vpn-tatra-9   (144.124.232.9)  — uptime-kuma monitoring (all VPN)
#   vpn-stolb-24  (144.124.239.24) — AdGuard Home (DNS filtering)
#
# =============================================================================

G='\033[1;32m'; Y='\033[1;33m'; R='\033[1;31m'; C='\033[1;36m'; X='\033[0m'

# Command to run on each VPN server
# Change CMD to run any command on all VPN servers
CMD="cd /root/Linux_Server_Public && git pull --rebase -q && bash /root/Linux_Server_Public/VPN/deploy_bashrc.sh"

# All VPN servers
declare -A VPN_SERVERS=(
    [vpn-alex-47]="109.234.38.47"
    [vpn-4ton-237]="144.124.228.237"
    [vpn-tatra-9]="144.124.232.9"
    [vpn-shahin-227]="144.124.228.227"
    [vpn-stolb-24]="144.124.239.24"
    [vpn-pilik-178]="91.84.118.178"
    [vpn-ilya-176]="146.103.110.176"
    [vpn-so-38]="144.124.233.38"
)

echo -e "${Y}============================================${X}"
echo -e "${Y}   VPN Deploy — $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${Y}============================================${X}"
echo -e "${C}CMD:${X} $CMD"
echo

OK=0; FAIL=0

for NAME in "${!VPN_SERVERS[@]}"; do
    IP="${VPN_SERVERS[$NAME]}"
    echo -e "${C}>>> $NAME ($IP)${X}"
    ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 root@"$IP" "$CMD" 2>&1 | tail -4
    if [ $? -eq 0 ]; then
        echo -e "  ${G}✔ OK${X}"
        OK=$((OK+1))
    else
        echo -e "  ${R}✘ FAILED${X}"
        FAIL=$((FAIL+1))
    fi
    echo
done

echo -e "${Y}============================================${X}"
echo -e "${G}Done: $OK${X}  ${R}Failed: $FAIL${X}  / Total: ${#VPN_SERVERS[@]}"
echo -e "${Y}============================================${X}"
