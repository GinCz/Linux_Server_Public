#!/bin/bash
# =============================================================================
# motd_server.sh — MOTD banner for 109-RU-FastVDS
# Version     : v2026-03-26
# Author      : Ing. VladiMIR Bulantsev
# Install     : cp 109/motd_server.sh /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"   # cyan
G="\033[1;32m"   # green
Y="\033[1;33m"   # yellow
W="\033[1;37m"   # white
X="\033[0m"      # reset

IP=$(hostname -I | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
HN=$(hostname)
LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"
printf "  ${C}🖥  %-24s${X} ${W}%-24s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"
echo -e "  ${Y}SCAN & SECURITY           ${Y}SERVER                    ${Y}WORDPRESS${X}"
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"
echo -e "  ${G}antivir${X}(scan)             ${G}sos${X}(now)                  ${G}wphealth${X}(WP health)"
echo -e "  ${G}fight${X}(block bots)         ${G}sos3/24/120${X}(3/24/120h)    ${G}wpcron${X}(WP cron)"
echo -e "  ${G}banlog${X}(ban list)          ${G}backup${X}(system backup)      ${G}mailclean${X}(mail queue)"
echo -e "  ${G}cleanup${X}(disk clean)       ${G}i${X}(full info)              ${G}domains${X}(domains)"
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"
echo -e "  ${Y}GIT & TOOLS               ${Y}VPN / STATS               ${Y}EXTRAS${X}"
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"
echo -e "  ${G}save${X}(git push)            ${G}aw${X}(VPN stats)             ${G}aws-test${X}(speed test)"
echo -e "  ${G}load${X}(git pull)            ${G}00${X}(clear)                 ${G}m${X}(Midnight Commander)"
echo -e "  ${G}wphealth${X}(WP check)        ${G}banlog${X}(crowdsec bans)      ${G}watchdog${X}(PHP-FPM)"
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"
echo -e "  ${Y}FastPanel${X} | ${Y}Ubuntu 24${X} | ${W}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
echo
