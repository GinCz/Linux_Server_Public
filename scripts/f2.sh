#!/bin/bash
# =============================================================================
# f2.sh — Interactive commands menu (universal, all server types)
# Version     : v2026-04-30
# Install     : cp scripts/f2.sh /usr/local/bin/f2 && chmod +x /usr/local/bin/f2
# Usage       : f2
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; W='\033[1;37m'; X='\033[0m'

# --- Detect server type ---
IS_VPN=false
IS_WEB=false

docker exec amnezia-awg wg show &>/dev/null 2>&1 && IS_VPN=true
systemctl is-active --quiet nginx 2>/dev/null && IS_WEB=true
[[ -f /usr/local/bin/audit ]] && IS_VPN=true

HN=$(hostname)
IP=$(hostname -I | awk '{print $1}')
LOAD=$(awk '{print $1"/"$2"/"$3}' /proc/loadavg)
RAM=$(free -m | awk '/Mem:/{printf "%d/%dMB", $3, $2}')

echo -e "${Y}╔$(printf '═%.0s' {1..52})╗${X}"
printf "${Y}║${X}  ${C}F2 — Commands Menu${X}  %-32s ${Y}║${X}\n" ""
printf "${Y}║${X}  ${W}%-50s${X}  ${Y}║${X}\n" "${HN}  ${IP}  RAM:${RAM}  Load:${LOAD}"
echo -e "${Y}╠$(printf '═%.0s' {1..52})╣${X}"

if $IS_VPN; then
    echo -e "${Y}║${X}  ${Y}VPN NODE${X}$(printf ' %.0s' {1..44})${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 1${X}) audit        — security + load (1h)        ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 2${X}) audit 3h     — audit last 3h               ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 3${X}) audit 24h    — audit last 24h              ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 4${X}) aw            — AmneziaWG peers stats        ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 5${X}) banlog        — CrowdSec ban list            ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 6${X}) antivir       — ClamAV scan                  ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 7${X}) infooo        — full server info             ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 8${X}) backup        — backup VPN configs           ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 9${X}) f5servers     — interactive backup menu      ${Y}║${X}"
    echo -e "${Y}║${X}  ${G}10${X}) f9servers     — interactive restore menu     ${Y}║${X}"
elif $IS_WEB; then
    echo -e "${Y}║${X}  ${Y}WEB SERVER (222)${X}$(printf ' %.0s' {1..35})${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 1${X}) sos           — server audit 1h              ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 2${X}) sos3          — audit last 3h                ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 3${X}) sos24         — audit last 24h               ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 4${X}) wpupd         — update all WordPress         ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 5${X}) wphealth      — WP health check              ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 6${X}) antivir       — ClamAV scan                  ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 7${X}) banlog        — CrowdSec bans                ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 8${X}) infooo        — full server info             ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 9${X}) f5servers     — interactive backup menu      ${Y}║${X}"
    echo -e "${Y}║${X}  ${G}10${X}) f9servers     — interactive restore menu     ${Y}║${X}"
else
    echo -e "${Y}║${X}  ${Y}GENERIC SERVER${X}$(printf ' %.0s' {1..37})${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 1${X}) infooo        — full server info             ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 2${X}) antivir       — ClamAV scan                  ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 3${X}) f5servers     — interactive backup menu      ${Y}║${X}"
    echo -e "${Y}║${X}  ${G} 4${X}) f9servers     — interactive restore menu     ${Y}║${X}"
fi
echo -e "${Y}╠$(printf '═%.0s' {1..52})╣${X}"
echo -e "${Y}║${X}  ${G} 0${X}) EXIT (Ctrl+C)$(printf ' %.0s' {1..38})${Y}║${X}"
echo -e "${Y}╚$(printf '═%.0s' {1..52})╝${X}"
echo
read -rp "  Choice: " CHOICE
echo

if $IS_VPN; then
    case "$CHOICE" in
        1) audit 1h ;;
        2) audit 3h ;;
        3) audit 24h ;;
        4) docker exec amnezia-awg wg show 2>/dev/null || echo "AmneziaWG not running" ;;
        5) bash /root/Linux_Server_Public/222/banlog.sh 30 2>/dev/null || cscli decisions list 2>/dev/null ;;
        6) /usr/local/bin/antivir ;;
        7) /usr/local/bin/infooo ;;
        8) bash /root/Linux_Server_Public/VPN/vpn_backup.sh ;;
        9) bash /root/Linux_Server_Public/222/f5servers.sh ;;
       10) bash /root/Linux_Server_Public/222/f9servers.sh ;;
        0) exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
elif $IS_WEB; then
    case "$CHOICE" in
        1) /usr/local/bin/sos 1h ;;
        2) /usr/local/bin/sos 3h ;;
        3) /usr/local/bin/sos 24h ;;
        4) bash /root/Linux_Server_Public/222/wp_update_all.sh ;;
        5) bash /root/Linux_Server_Public/222/wphealth.sh ;;
        6) bash /root/Linux_Server_Public/222/scan_clamav.sh ;;
        7) bash /root/Linux_Server_Public/222/banlog.sh 30 ;;
        8) /usr/local/bin/infooo ;;
        9) bash /root/Linux_Server_Public/222/f5servers.sh ;;
       10) bash /root/Linux_Server_Public/222/f9servers.sh ;;
        0) exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
else
    case "$CHOICE" in
        1) /usr/local/bin/infooo ;;
        2) /usr/local/bin/antivir ;;
        3) bash /root/Linux_Server_Public/222/f5servers.sh ;;
        4) bash /root/Linux_Server_Public/222/f9servers.sh ;;
        0) exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
fi
