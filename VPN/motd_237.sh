#!/bin/bash
# =============================================================================
# motd_237.sh — MOTD for EU-4Ton-237: Samba + Xray VPN (NO AmneziaWG/AdGuard)
# Version     : v2026-05-01
# Author      : Ing. VladiMIR Bulantsev
# Install     : cp /root/Linux_Server_Public/VPN/motd_237.sh /etc/profile.d/motd_server.sh
#               chmod +x /etc/profile.d/motd_server.sh
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"   # cyan
G="\033[1;32m"   # green
Y="\033[1;33m"   # yellow
W="\033[1;37m"   # white
R="\033[1;31m"   # red
X="\033[0m"      # reset
LINE="\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501"

IP=$(hostname -I | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep "Cpu(s)" | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
HN=$(hostname)

LOAD1=$(awk '{printf "%.0f%%", $1*100}' /proc/loadavg)
LOAD5=$(awk '{printf "%.0f%%", $2*100}' /proc/loadavg)
LOAD15=$(awk '{printf "%.0f%%", $3*100}' /proc/loadavg)

# Xray status
XRAY_ST=$(systemctl is-active xray 2>/dev/null || echo "unknown")
if [[ "$XRAY_ST" == "active" ]]; then
  XRAY_LABEL="${G}Xray: active${X}"
else
  XRAY_LABEL="${R}Xray: ${XRAY_ST}${X}"
fi

# Samba status
SMB_ST=$(systemctl is-active smbd 2>/dev/null || echo "unknown")
if [[ "$SMB_ST" == "active" ]]; then
  SMB_LABEL="${G}Samba: active${X}"
else
  SMB_LABEL="${R}Samba: ${SMB_ST}${X}"
fi

# Samba connected users (quick count)
SMB_USERS=$(smbstatus --brief 2>/dev/null | grep -c '^[0-9]' || echo "0")

echo -e "${C}${LINE}${X}"
printf "  ${C}\U0001f512  %-24s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" \
  "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
printf "  %b  |  %b  |  ${Y}Samba users: ${W}%s${X}\n" \
  "$XRAY_LABEL" "$SMB_LABEL" "$SMB_USERS"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}VPN/SAMBA                 SERVER                    GIT${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}xray_st${X}(xray status)      ${G}sos${X}(server audit 1h)      ${G}save${X}(git push)"
echo -e "  ${G}xray_log${X}(xray logs)       ${G}sos24${X}(audit 24h)           ${G}load${X}(git pull+sos)"
echo -e "  ${G}smb_st${X}(samba status)      ${G}ports${X}(open ports)          ${G}infooo${X}(full info)"
echo -e "  ${G}smb_who${X}(samba users)      ${G}banlist${X}(crowdsec bans)      ${G}00${X}(clear)"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}Ubuntu 24${X} | up ${W}${UPTIME}${X} | load 1m/5m/15m: ${G}${LOAD1} ${LOAD5} ${LOAD15}${X}"
echo
