#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  all_servers_info.sh | [v2026-05-21]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Cluster multi-server hardware and status overview
# Servers     : 109-RU FastVDS
# Usage       : bash 109/all_servers_info.sh
# ==========================================================================================
clear
# = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =
# Script:   all_servers_info.sh
# Alias:    allinfo
# Location: /root/Linux_Server_Public/109/all_servers_info.sh
#
# PURPOSE:
#   Display RAM and Disk usage for ALL servers in the infrastructure
#   in a single colored table.
#   Works correctly from BOTH server-109 and server-222 (no password prompt).
#
# HOW IT WORKS — SSH KEY ARCHITECTURE:
#   Windows (mRemoteNG/PuTTY)
#       └──► server-222 (152.53.182.222)  ← connects to all VPN nodes via key
#       └──► server-109 (212.109.223.109)  ← connects to all VPN nodes via key
#
#   Each server detects its own IPs (all interfaces) and skips SSH for itself.
#   Remote servers connect via MASTER key: /root/.ssh/id_ed25519
#   tail -2 strips MOTD from SSH output — only last 2 lines (RAM + DISK) are used.
#
# STATUS INDICATORS:
#   ◆ OK    (green)  — usage below 80%
#   ◆ WARN  (yellow) — usage 80–89%
#   ◆ CRIT  (red)    — usage 90% or higher
#
# ALIAS (add to ~/.bashrc on both servers):
#   alias allinfo='bash /root/Linux_Server_Public/109/all_servers_info.sh'
#
# USAGE:
#   allinfo

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

# Collect ALL IPs of this machine (all interfaces) into one string
ALL_LOCAL_IPS=$(hostname -I 2>/dev/null)

is_local() {
    local ip="$1"
    [[ " $ALL_LOCAL_IPS " == *" $ip "* ]]
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
    "pilik33:195.63.138.33" \
    "ilya176:146.103.110.176" \
    "so38:144.124.233.38"
do
    N="${E%%:*}"
    I="${E##*:}"
    CMD="free -m|awk 'NR==2{printf \"%s %s\",\$2,\$3}'; echo; df -h /|awk 'NR==2{printf \"%s %s\",\$2,\$5}'"

    # If target IP belongs to this machine — run locally, skip SSH
    if is_local "$I"; then
        RES=$(eval "$CMD")
    else
        # Remote — connect via MASTER key /root/.ssh/id_ed25519
        # tail -2: strip any MOTD output, keep only the last 2 lines (RAM + DISK)
        RES=$(ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
              -o BatchMode=yes root@"$I" "$CMD" 2>/dev/null | tail -2)
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

# = Rooted by VladiMIR | AI = v2026-05-21 = github.com/GinCz/Linux_Server_Public
