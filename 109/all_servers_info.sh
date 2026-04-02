#!/bin/bash
clear
# = Rooted by VladiMIR | AI =
# v2026-04-02
# Script: all_servers_info.sh
# Alias:  allinfo
# Location: /root/Linux_Server_Public/109/all_servers_info.sh
#
# PURPOSE:
#   Display RAM and Disk usage for ALL servers in the infrastructure
#   in a single colored table — run from server-109 (FastVDS, RU).
#
# HOW IT WORKS — SSH KEY ARCHITECTURE:
#   Windows (mRemoteNG/PuTTY)
#       └──► server-222 (152.53.182.222)  ← MASTER hub, connects to all VPN nodes
#       └──► server-109 (212.109.223.109)  ← THIS server (no Cloudflare, RU sites)
#
#   server-109 connects to server-222 and all VPN nodes
#   using its own MASTER key: /root/.ssh/id_ed25519
#
# STATUS INDICATORS:
#   ◆ OK    (green)  — usage below 80%
#   ◆ WARN  (yellow) — usage 80–89%
#   ◆ CRIT  (red)    — usage 90% or higher
#
# ALIAS (add to ~/.bashrc on server-109):
#   alias allinfo='bash /root/Linux_Server_Public/109/all_servers_info.sh'
#
# USAGE:
#   allinfo
#   bash /root/Linux_Server_Public/109/all_servers_info.sh

W="\e[36m"
Y="\e[93m"
G="\e[92m"
R="\e[31m"
C="\e[96m"
X="\e[0m"

LINE="${W}$(printf '═%.0s' {1..104})${X}"
DIV="${W}$(printf '─%.0s' {1..104})${X}"

dot() {
    local p=$1
    (( p>=90 )) && printf "${R}◆ CRIT${X}" || { (( p>=80 )) && printf "\e[93m◆ WARN${X}" || printf "${G}◆ OK  ${X}"; }
}

echo -e "$LINE"
echo -e "${Y}  ALL SERVERS RESOURCES — $(date '+%Y-%m-%d %H:%M')${X}"
echo -e "$LINE"
printf "${Y}  %-20s %-18s %-30s %-28s${X}\n" "SERVER" "IP" "RAM" "DISK"
echo -e "$LINE"

for E in \
    "109-RU-FastVDS:212.109.223.109" \
    "222-DE-NetCup:152.53.182.222" \
    "alex47:109.234.38.47" \
    "4ton237:144.124.228.237" \
    "tatra9:144.124.232.9" \
    "shahin227:144.124.228.227" \
    "stolb24:144.124.239.24" \
    "pilik178:91.84.118.178" \
    "ilya176:146.103.110.176" \
    "so38:144.124.233.38"
do
    N="${E%%:*}"
    I="${E##*:}"
    CMD="free -m|awk 'NR==2{printf \"%s %s\",\$2,\$3}'; echo; df -h /|awk 'NR==2{printf \"%s %s\",\$2,\$5}'"

    # Local server (109 itself) — run directly, no SSH needed
    if [[ "$I" == "212.109.223.109" ]]; then
        RES=$(eval "$CMD")
    else
        # Remote servers — connect via MASTER key /root/.ssh/id_ed25519
        RES=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 root@$I "$CMD" 2>/dev/null)
    fi

    if [[ -z "$RES" ]]; then
        printf "${Y}  %-20s ${C}%-18s${X} ${R}◆ UNREACHABLE${X}\n" "$N" "$I"
    else
        RT=$(echo "$RES" | awk 'NR==1{print $1}')
        RU=$(echo "$RES" | awk 'NR==1{print $2}')
        DT=$(echo "$RES" | awk 'NR==2{print $1}')
        DP=$(echo "$RES" | awk 'NR==2{print $2}')
        RP=$(awk "BEGIN{printf \"%d\",($RU/$RT)*100}")
        DNP=${DP/\%/}
        printf "${Y}  %-20s${X} ${C}%-18s${X} ${G}%-24s${X} $(dot $RP)   ${G}%-20s${X} $(dot $DNP)\n" \
            "$N" "$I" "${RT}Mb  (${RP}% used)" "${DT}  (${DP} used)"
    fi
    echo -e "$DIV"
done

echo -e "$LINE"
