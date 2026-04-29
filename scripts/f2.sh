#!/bin/bash
# =============================================================================
# f2.sh — Interactive commands menu (universal, all server types)
# Version     : v2026-04-30
# Install     : cp scripts/f2.sh /usr/local/bin/f2 && chmod +x /usr/local/bin/f2
# Note        : f5servers/f9servers shown only on Web server (222), not VPN
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; W='\033[1;37m'; X='\033[0m'

# Detect server type
IS_VPN=false
IS_WEB=false
docker exec amnezia-awg wg show &>/dev/null 2>&1 && IS_VPN=true
[[ -f /usr/local/bin/audit ]] && IS_VPN=true
systemctl is-active --quiet nginx 2>/dev/null && IS_WEB=true

HN=$(hostname)
IP=$(hostname -I | awk '{print $1}')
LOAD=$(awk '{print $1"/"$2"/"$3}' /proc/loadavg)
RAM=$(free -m | awk '/Mem:/{printf "%d/%dMB", $3, $2}')

echo -e "${Y}\u2554$(printf '\u2550%.0s' {1..52})\u2557${X}"
printf "${Y}\u2551${X}  ${C}F2 \u2014 Commands Menu${X}  %-32s ${Y}\u2551${X}\n" ""
printf "${Y}\u2551${X}  ${W}%-50s${X}  ${Y}\u2551${X}\n" "${HN}  ${IP}  ${RAM}  Load:${LOAD}"
echo -e "${Y}\u2560$(printf '\u2550%.0s' {1..52})\u2563${X}"

if $IS_VPN; then
    echo -e "${Y}\u2551${X}  ${Y}VPN NODE${X}$(printf ' %.0s' {1..44})${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 1${X}) audit        \u2014 security + load (1h)        ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 2${X}) audit 3h     \u2014 audit last 3h               ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 3${X}) audit 24h    \u2014 audit last 24h              ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 4${X}) aw            \u2014 AmneziaWG peers stats        ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 5${X}) banlog        \u2014 CrowdSec ban list            ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 6${X}) antivir       \u2014 ClamAV scan                  ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 7${X}) infooo        \u2014 full server info             ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 8${X}) backup        \u2014 backup VPN configs           ${Y}\u2551${X}"
elif $IS_WEB; then
    echo -e "${Y}\u2551${X}  ${Y}WEB SERVER (222)${X}$(printf ' %.0s' {1..35})${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 1${X}) sos           \u2014 server audit 1h              ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 2${X}) sos3          \u2014 audit last 3h                ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 3${X}) sos24         \u2014 audit last 24h               ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 4${X}) wpupd         \u2014 update all WordPress         ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 5${X}) wphealth      \u2014 WP health check              ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 6${X}) antivir       \u2014 ClamAV scan                  ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 7${X}) banlog        \u2014 CrowdSec bans                ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 8${X}) infooo        \u2014 full server info             ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 9${X}) f5servers     \u2014 interactive backup menu      ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G}10${X}) f9servers     \u2014 interactive restore menu     ${Y}\u2551${X}"
else
    echo -e "${Y}\u2551${X}  ${Y}GENERIC SERVER${X}$(printf ' %.0s' {1..37})${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 1${X}) infooo        \u2014 full server info             ${Y}\u2551${X}"
    echo -e "${Y}\u2551${X}  ${G} 2${X}) antivir       \u2014 ClamAV scan                  ${Y}\u2551${X}"
fi
echo -e "${Y}\u2560$(printf '\u2550%.0s' {1..52})\u2563${X}"
echo -e "${Y}\u2551${X}  ${G} 0${X}) EXIT$(printf ' %.0s' {1..47})${Y}\u2551${X}"
echo -e "${Y}\u255a$(printf '\u2550%.0s' {1..52})\u255d${X}"
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
        0) exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
fi
