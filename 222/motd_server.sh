#!/usr/bin/env bash
# Защита от повторного запуска в одной SSH-сессии
if [ -n "$_MOTD_LOADED" ]; then
    return 0 2>/dev/null || exit 0
fi
export _MOTD_LOADED=1

# Очищаем экран (стирает "Using username root" и системный шум)
clear

C='\033[01;93m'
G='\033[0;92m'
Y='\033[0;93m'
R='\033[1;31m'
W='\033[1;37m'
X='\033[0m'
HR="${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${X}"

HOST="$(hostname)"
# Instant IP detection (DMI check for AWS EC2, else instant hostname -I)
IP=""
if grep -qiE 'amazon|ec2' /sys/class/dmi/id/* 2>/dev/null; then
    _AWS_TOKEN="$(curl -s --connect-timeout 0.2 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60" 2>/dev/null)"
    if [ -n "$_AWS_TOKEN" ]; then
        IP="$(curl -s --connect-timeout 0.2 -H "X-aws-ec2-metadata-token: $_AWS_TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)"
    fi
fi
[ -z "$IP" ] && IP="$(hostname -I 2>/dev/null | awk '{print $1}')"

RAM="$(free -m 2>/dev/null | awk '/^Mem:/{printf "%d%% (%.1f/%.1fG)", ($3*100)/$2, $3/1024, $2/1024}')"
SWAP="$(free -m 2>/dev/null | awk '/^Swap:/{if ($2>0) printf "%.1fG", $2/1024; else printf "0G"}')"
CPU="$(grep 'cpu ' /proc/stat 2>/dev/null | awk '{u=$2+$4; t=$2+$4+$5; if (t>0) printf "%d%%", (u*100)/t; else print "0%"}')"
SSD="$(df -h / 2>/dev/null | awk 'NR==2 {printf "%s (%s/%s)", $5, $3, $2}')"

# Compact Uptime: e.g. 15d 14h 39m
UP_SEC=$(awk '{print int($1)}' /proc/uptime 2>/dev/null || echo 0)
UP_DAYS=$(( UP_SEC / 86400 ))
UP_HOURS=$(( (UP_SEC % 86400) / 3600 ))
UP_MINS=$(( (UP_SEC % 3600) / 60 ))
if [ "$UP_DAYS" -gt 0 ]; then
    UP="${UP_DAYS}d ${UP_HOURS}h ${UP_MINS}m"
elif [ "$UP_HOURS" -gt 0 ]; then
    UP="${UP_HOURS}h ${UP_MINS}m"
else
    UP="${UP_MINS}m"
fi

LOAD="$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}')"

XRAY_ST="${R}○ INACTIVE${X}"
if systemctl is-active --quiet x-ui 2>/dev/null || pgrep -f "xray" >/dev/null 2>&1; then
    XRAY_ST="${G}● ACTIVE${X}"
fi

CS_ST="${R}○ INACTIVE${X}"
systemctl is-active --quiet crowdsec 2>/dev/null && CS_ST="${G}● ACTIVE${X}"

FW_ST="${G}● ACTIVE${X}"
ufw status 2>/dev/null | grep -q "inactive" && FW_ST="${R}○ INACTIVE${X}"

GIT_ST="${G}● SYNC${X}"
if [ -d "/root/Linux_Server_Public/.git" ]; then
    (cd /root/Linux_Server_Public && git fetch -q origin main 2>/dev/null &)
    LOCAL_REV=$(git --git-dir=/root/Linux_Server_Public/.git rev-parse HEAD 2>/dev/null)
    REMOTE_REV=$(git --git-dir=/root/Linux_Server_Public/.git rev-parse origin/main 2>/dev/null)
    if [ -n "$LOCAL_REV" ] && [ -n "$REMOTE_REV" ] && [ "$LOCAL_REV" != "$REMOTE_REV" ]; then
        GIT_ST="${Y}⚡ UPDATE${X}"
    fi
else
    GIT_ST="${R}○ NO REPO${X}"
fi

echo -e "$HR"
echo -e "  🌐  ${W}${HOST}${X}  ${C}${IP}${X}  |  FastPanel+CF | Ubuntu 24  |  load: ${G}${LOAD}${X}"
echo -e "  📊  RAM: ${G}${RAM}${X}  Swap: ${G}${SWAP}${X}  CPU: ${G}${CPU}${X}  SSD: ${G}${SSD}${X}  up: ${W}${UP}${X}"
echo -e "  🛡️   Xray: ${XRAY_ST}    CrowdSec: ${CS_ST}    Firewall: ${FW_ST}    GitHub: ${GIT_ST}"
echo -e "$HR"
echo -e "  ${Y}SCAN & SECURITY${X}             ${Y}SERVER${X}                        ${Y}WORDPRESS${X}"
echo -e "$HR"
echo -e "  ${C}antivir${X} (ClamAV scan)       ${C}sos${X} (server audit)            ${C}wpupd${X} (WP update all)"
echo -e "  ${C}fight${X} (block bots)          ${C}watchdog${X} (PHP-FPM)            ${C}wpcron${X} (WP CLI cron)"
echo -e "  ${C}banlist${X} (CrowdSec IPs)      ${C}backup${X} (system backup)        ${C}domains${X} (domain & SSL)"
echo -e "  ${C}cleanup${X} (disk clean)        ${C}mailclean${X} (mail queue)        ${C}wphealth${X} (WP check)"
echo -e "  ${C}banunblock${X} (unban IP)      ${C}setphp${X} (PHP limits)           ${C}00${X} (clear screen)"
echo -e "  ${C}banblock${X} (manual ban)"
echo -e "$HR"
echo -e "  ${Y}GIT${X}                         ${Y}TOOLS & MONITOR${X}                 ${Y}NGINX & SYSTEM${X}"
echo -e "$HR"
echo -e "  ${C}save${X} (git push)             ${C}stars${X} (10-★ cluster monitor)  ${C}nginx-reload${X} (Nginx)"
echo -e "  ${C}load${X} (git pull)             ${C}infooo${X} (hardware info)        ${C}fpm-reload${X} (PHP-FPM)"
echo -e "  ${C}repo${X} (open repo)            ${C}style${X} (theme/colors)          ${C}reload-all${X} (Both)"
echo -e "  ${C}secret${X} (private repo)      ${C}mc${X} (Midnight Cmdr)            ${C}upd${X} (apt upgrade)"
echo -e "                              ${C}bot${X} (CryptoBot status)"
echo -e "$HR"

# ── Check for GitHub updates (instant local ref check + quiet bg fetch) ──
if [ -d "/root/Linux_Server_Public/.git" ]; then
    (cd /root/Linux_Server_Public && git fetch -q origin main 2>/dev/null &)
    LOCAL_REV=$(git --git-dir=/root/Linux_Server_Public/.git rev-parse HEAD 2>/dev/null)
    REMOTE_REV=$(git --git-dir=/root/Linux_Server_Public/.git rev-parse origin/main 2>/dev/null)
    if [ -n "$LOCAL_REV" ] && [ -n "$REMOTE_REV" ] && [ "$LOCAL_REV" != "$REMOTE_REV" ]; then
        echo -e "  ${Y}⚡ New updates available on GitHub! Type ${W}load${Y} to update.${X}"
        echo -e "$HR"
    fi
fi

