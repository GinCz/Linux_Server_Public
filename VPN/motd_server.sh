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

STATUS_LINE=""

# AmneziaWG (docker container)
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q 'amnezia-awg'; then
  PEERS_TOTAL=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l || echo 0)
  PEERS_ONLINE=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
    | awk -v t="$(date +%s)" '$5>0 && (t-$5)<180 {c++} END{print c+0}' || echo 0)
  STATUS_LINE+="  🛡️   AmneziaWG: ${G}${PEERS_ONLINE} online${X} / ${W}${PEERS_TOTAL} total${X}   "
fi

# AdGuard Home
if systemctl is-active AdGuardHome >/dev/null 2>&1; then
  STATUS_LINE+="  🛑   AdGuard: ${G}ACTIVE${X}   "
elif command -v AdGuardHome >/dev/null 2>&1 || [ -f /opt/AdGuardHome/AdGuardHome ]; then
  STATUS_LINE+="  🛑   AdGuard: ${R}INACTIVE${X}   "
fi

# Xray VPN
if systemctl list-units --full -all 2>/dev/null | grep -q 'xray.service'; then
  if systemctl is-active xray >/dev/null 2>&1; then
    STATUS_LINE+="  ⚡   Xray: ${G}ACTIVE${X}   "
  else
    STATUS_LINE+="  ⚡   Xray: ${R}INACTIVE${X}   "
  fi
fi

# Samba
if systemctl list-units --full -all 2>/dev/null | grep -q 'smbd.service'; then
  if systemctl is-active smbd >/dev/null 2>&1; then
    SMB_USERS=$(smbstatus --brief 2>/dev/null | grep -c '^[0-9]' || echo 0)
    STATUS_LINE+="  📁   Samba: ${G}${SMB_USERS} users${X}   "
  else
    STATUS_LINE+="  📁   Samba: ${R}INACTIVE${X}   "
  fi
fi

[[ -z "$STATUS_LINE" ]] && STATUS_LINE="  🛡️   No VPN services detected"

echo -e "$HR"
echo -e "  🌐  ${W}${HOST}${X}  ${C}${IP}${X}  |  VPN Node | Ubuntu 24  |  load: ${G}${LOAD}${X}"
echo -e "  📊  RAM: ${G}${RAM}${X}  CPU: ${G}${CPU}${X}  up: ${W}${UP}${X}"
echo -e "${STATUS_LINE}"
echo -e "$HR"
echo -e "  ${Y}VPN MANAGEMENT${X}          ${Y}SERVER${X}                    ${Y}GIT${X}"
echo -e "$HR"
echo -e "  ${C}sos${X}(audit 1h)             ${C}ports${X}(open ports)         ${C}save${X}(git push)"
echo -e "  ${C}sos24${X}(audit 24h)           ${C}banlist${X}(banned IPs)       ${C}load${X}(git pull+upd)"
echo -e "  ${C}infooo${X}(full hw info)       ${C}antivir${X}(clamav menu)      ${C}00${X}(clear screen)"
echo -e "  ${C}upd${X}(apt upgrade+reboot)   ${C}xray_st${X} ${C}smb_st${X} ${C}adg_st${X}    ${C}mc${X}(Midnight Cmdr)"
echo -e "$HR"
