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
# Universal IP resolver (AWS EC2 IMDSv2/v1 + standard VPS fallback)
_AWS_TOKEN="$(curl -s --connect-timeout 1 -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 60" 2>/dev/null)"
if [ -n "$_AWS_TOKEN" ]; then
    _AWS_IP="$(curl -s --connect-timeout 1 -H "X-aws-ec2-metadata-token: $_AWS_TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null)"
fi
IP="${_AWS_IP:-$(curl -s --connect-timeout 1 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || hostname -I 2>/dev/null | awk '{print $1}')}"
RAM="$(free -m 2>/dev/null | awk '/^Mem:/{printf "%d%% (%.1f/%.1fG)", ($3*100)/$2, $3/1024, $2/1024}')"
SWAP="$(free -m 2>/dev/null | awk '/^Swap:/{if ($2>0) printf "%.1fG", $2/1024; else printf "0G"}')"
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
echo -e "  📊  RAM: ${G}${RAM}${X}  Swap: ${G}${SWAP}${X}  CPU: ${G}${CPU}${X}  up: ${W}${UP}${X}"
echo -e "  🛡️   Xray: ${XRAY_ST}    CrowdSec: ${CS_ST}    Firewall: ${FW_ST}"
echo -e "$HR"
echo -e "  ${Y}SCAN & SECURITY${X}             ${Y}SERVER & SYSTEM${X}                 ${Y}WORDPRESS & GIT${X}"
echo -e "$HR"
echo -e "  ${C}antivir${X} (ClamAV menu)       ${C}sos${X} (server audit)            ${C}wpupd${X} (WP update all)"
echo -e "  ${C}fight${X} (block bots)          ${C}backup${X} (system backup)        ${C}wpcron${X} (WP CLI cron)"
echo -e "  ${C}banlist${X} (CrowdSec IPs)      ${C}cleanup${X} (disk clean)          ${C}domains${X} (domain & SSL)"
echo -e "  ${C}infooo${X} (hardware info)      ${C}save${X} (git push)              ${C}load${X} (git pull)"
echo -e "$HR"
