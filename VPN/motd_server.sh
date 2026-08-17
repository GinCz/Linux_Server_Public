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

# ── Services: show green ● if active, red ✗ if inactive ──────
SVC_LINE=""
for svc in x-ui AdGuardHome crowdsec fail2ban smbd; do
  # Determine display name
  case "$svc" in
    x-ui) disp="Xray" ;;
    *) disp="$svc" ;;
  esac
  
  if systemctl is-active --quiet "$svc" 2>/dev/null; then
    SVC_LINE+=" ${G}●${X} ${disp}  "
  else
    SVC_LINE+=" ${R}✗${X} ${disp}  "
  fi
done

echo -e "$HR"
echo -e "  🌐  ${W}${HOST}${X}  ${C}${IP}${X}  |  VPN Node | Ubuntu 24  |  load: ${G}${LOAD}${X}"
echo -e "  📊  RAM: ${G}${RAM}${X}  CPU: ${G}${CPU}${X}  up: ${W}${UP}${X}"
echo -e "$HR"
echo -e "  Services:${SVC_LINE}"
echo -e "$HR"
echo -e "  ${Y}VPN MANAGEMENT${X}          ${Y}SERVER${X}                    ${Y}GIT${X}"
echo -e "$HR"
echo -e "  ${C}sos${X}(audit 1h)             ${C}ports${X}(open ports)         ${C}save${X}(git push)"
echo -e "  ${C}infooo${X}(full hw info)       ${C}banlist${X}(banned IPs)       ${C}load${X}(git pull+upd)"
echo -e "  ${C}upd${X}(apt upgrade+reboot)   ${C}antivir${X}(clamav menu)      ${C}mc${X}(Midnight Cmdr)"
echo -e "$HR"
