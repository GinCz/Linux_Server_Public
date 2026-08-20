#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  motd_vpn.sh | [v2026-06-10]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Dynamic SSH login MOTD banner for VPN servers
# Servers     : VPN Nodes
# Usage       : bash scripts/motd_vpn.sh
# ==========================================================================================
shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0

C="\033[01;96m"
G="\033[1;32m"
Y="\033[1;33m"
W="\033[1;37m"
R="\033[1;31m"
X="\033[0m"
LINE="\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501"

HN=$(cat /etc/hostname 2>/dev/null | head -1 | tr -d '[:space:]')
[[ -z "$HN" ]] && HN=$(hostname 2>/dev/null || echo "unknown")
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
SWAP=$(free -m 2>/dev/null | awk '/^Swap:/{if ($2>0) printf "%.1fG", $2/1024; else printf "0G"}')
CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

# ── Xray ───────────────────────────────────────────────────────────────────────────────
if systemctl is-active --quiet xray 2>/dev/null; then
  XRAY_ST="${G}\u25cf ACTIVE${X}"
else
  XRAY_ST="${R}\u2717 stopped${X}"
fi

# ── CrowdSec ───────────────────────────────────────────────────────────────────────────
if systemctl is-active --quiet crowdsec 2>/dev/null; then
  BAN_COUNT=$(cscli decisions list -o raw 2>/dev/null | grep -c ',' || echo 0)
  CS_PART="${Y}CrowdSec:${X} ${G}\u25cf ACTIVE${X} | bans: ${W}${BAN_COUNT}${X}"
else
  CS_PART="${Y}CrowdSec:${X} ${R}\u2717 INACTIVE${X}"
fi

# ── Services: show green ● if active, red ✗ if inactive ──────────────────────────────
SVC_LINE=""
for svc in crowdsec fail2ban smbd; do
  if systemctl is-active --quiet "$svc" 2>/dev/null; then
    SVC_LINE+=" ${G}\u25cf${X} ${svc}"
  else
    SVC_LINE+=" ${R}\u2717${X} ${svc}"
  fi
done

echo -e "${C}${LINE}${X}"
echo -e "  \U0001F511  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  Swap:${W}${SWAP}${X}  CPU:${W}${CPU}%%${X}  up ${W}${UPTIME}${X}"
echo -e "  ${Y}Type:${X} ${W}VPN / Xray${X} ${XRAY_ST}   ${CS_PART}"
echo -e "  Services:${SVC_LINE}"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}VPN MANAGEMENT            SERVER                    GIT${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}banlog${X}(ban list)         ${G}sos${X}(audit 1h)           ${G}save${X}(git push)"
echo -e "  ${G}banblock${X}(ban IP)         ${G}sos3${X}(audit 3h)          ${G}load${X}(git pull+deploy)"
echo -e "  ${G}antivir${X}(ClamAV scan)     ${G}sos24${X}(audit 24h)        ${G}mc${X}(Midnight Cmdr)"
echo -e "  ${G}backup${X}(VPN configs)      ${G}infooo${X}(server info)     ${G}00${X}(clear screen)"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}Ubuntu 24${X} | load: ${G}${LOAD}${X}"
echo

# = Rooted by VladiMIR | AI = v2026-06-10 = github.com/GinCz/Linux_Server_Public
