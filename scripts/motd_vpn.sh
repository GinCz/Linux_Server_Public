#!/usr/bin/env bash
# Защита от повторного запуска в одной SSH-сессии
if [ -n "$_MOTD_LOADED" ]; then
    return 0 2>/dev/null || exit 0
fi
export _MOTD_LOADED=1

# Очищаем экран (стирает "Using username root" и системный шум)
clear

C='\033[38;5;81m'
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
UP="$(uptime -p 2>/dev/null | sed 's/up //')"
LOAD="$(cat /proc/loadavg 2>/dev/null | awk '{print $1, $2, $3}')"

# ── Services: show green ● if active, red ✗ if inactive ──────
SERVICES=(
  "x-ui:Xray"
  "xray:Xray"
  "AdGuardHome:AdGuardHome"
  "fail2ban:fail2ban"
  "smbd:smbd"
  "crowdsec:CrowdSec"
)
SVC_LINE=""
for item in "${SERVICES[@]}"; do
  svc="${item%%:*}"
  disp="${item##*:}"
  [[ "$SVC_LINE" == *"$disp"* ]] && continue
  if systemctl is-active --quiet "$svc" 2>/dev/null; then
    SVC_LINE+=" ${G}●${X} ${disp}  "
  else
    SVC_LINE+=" ${R}✗${X} ${disp}  "
  fi
done

echo -e "$HR"
echo -e "  🌐  ${W}${HOST}${X}  ${C}${IP}${X}  |  VPN Node | Ubuntu 24  |  load: ${G}${LOAD}${X}"
echo -e "  📊  RAM: ${G}${RAM}${X}  Swap: ${G}${SWAP}${X}  CPU: ${G}${CPU}${X}  up: ${W}${UP}${X}"
echo -e "$HR"
echo -e "  Services:${SVC_LINE}"
echo -e "$HR"
echo -e "  ${Y}SCAN & SECURITY${X}             ${Y}VPN & STATUS${X}                    ${Y}GIT & TOOLS${X}"
echo -e "$HR"
echo -e "  ${C}antivir${X} (ClamAV menu)       ${C}sos${X} (server audit)            ${C}save${X} (git push)"
echo -e "  ${C}fight${X} (block bots)          ${C}cleanup${X} (disk clean)          ${C}load${X} (git pull)"
echo -e "  ${C}banlist${X} (CrowdSec IPs)      ${C}ports${X} (open ports)            ${C}infooo${X} (hardware info)"
echo -e "  ${C}style${X} (theme/colors)        ${C}upd${X} (apt upgrade)             ${C}mc${X} (Midnight Cmdr)"
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

