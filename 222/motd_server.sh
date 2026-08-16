#!/usr/bin/env bash
# Защита от повторного запуска в одной SSH-сессии
if [ -n "$_MOTD_LOADED" ]; then
    return 0 2>/dev/null || exit 0
fi
export _MOTD_LOADED=1

# Очищаем экран (стирает "Using username root" и системный шум)
clear

C='\033[1;36m'; G='\033[0;92m'; Y='\033[0;93m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
HR="${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"

HOST="$(hostname)"
IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
RAM="$(free -m 2>/dev/null | awk '/^Mem:/{printf "%d/%dMB", $3, $2}')"
CPU="$(top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{print int($2 + $4)}')%"
UP="$(uptime -p 2>/dev/null | sed 's/up //')"
LOAD="$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}')"

XRAY_ST="${R}○ INACTIVE${X}"
if systemctl is-active --quiet x-ui 2>/dev/null || pgrep -f "xray" >/dev/null 2>&1; then
    XRAY_ST="${G}● ACTIVE${X}"
fi

CS_ST="${R}○ INACTIVE${X}"
systemctl is-active --quiet crowdsec 2>/dev/null && CS_ST="${G}● ACTIVE${X}"

FW_ST="${G}● ACTIVE${X}"
ufw status 2>/dev/null | grep -q "inactive" && FW_ST="${R}○ INACTIVE${X}"

echo -e "$HR"
echo -e "  🌐  ${W}${HOST}${X}  ${C}${IP}${X}  |  FastPanel+CF | Ubuntu 24  |  load: ${G}${LOAD}${X}"
echo -e "  📊  RAM: ${G}${RAM}${X}  CPU: ${G}${CPU}${X}  up: ${W}${UP}${X}"
echo -e "  🛡️   Xray: ${XRAY_ST}    CrowdSec: ${CS_ST}    Firewall: ${FW_ST}"
echo -e "$HR"
echo -e "  ${Y}SCAN & SECURITY${X}             ${Y}SERVER${X}                      ${Y}WORDPRESS${X}"
echo -e "$HR"
echo -e "  ${C}antivir${X}(ClamAV menu)        ${C}sos${X}(server audit)         ${C}wpupd${X}(WP update all)"
echo -e "  ${C}fight${X}(block bots)           ${C}watchdog${X}(PHP-FPM)         ${C}wpcron${X}(WP CLI cron)"
echo -e "  ${C}banlog${X}(ban list)            ${C}backup${X}(system backup)     ${C}domains${X}(domain & SSL)"
echo -e "  ${C}cleanup${X}(disk clean)         ${C}mailclean${X}(mail queue)     ${C}wphealth${X}(WP check)"
echo -e "  ${C}banunblock${X}(unban IP)        ${C}setphp${X}(PHP limits)        ${C}00${X}(clear screen)"
echo -e "  ${C}banblock${X}(manual ban)"
echo -e "$HR"
echo -e "  ${Y}GIT${X}                         ${Y}TOOLS${X}"
echo -e "$HR"
echo -e "  ${C}save${X}(git push)              ${C}infooo${X}(hardware info)     ${C}nginx-reload${X}(Nginx)"
echo -e "  ${C}load${X}(git pull)              ${C}aw${X}(VPN stats)             ${C}fpm-reload${X}(PHP-FPM)"
echo -e "  ${C}repo${X}(open repo)             ${C}mc${X}(Midnight Cmdr)         ${C}reload-all${X}(Both)"
echo -e "  ${C}secret${X}(private repo)       ${C}bot_st${X}(CryptoBot)"
echo -e "$HR"
