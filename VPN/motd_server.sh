#!/bin/bash
# =============================================================================
# motd_server.sh — Universal MOTD for ALL VPN nodes
# Version     : v2026-05-01
# Author      : Ing. VladiMIR Bulantsev
# Description : Auto-detects installed services and shows only what is present:
#               - AmneziaWG (docker container amnezia-awg)
#               - AdGuard Home
#               - Xray VPN
#               - Samba
#               - CrowdSec / fail2ban
# Install     : cp /root/Linux_Server_Public/VPN/motd_server.sh /etc/profile.d/motd_server.sh
#               chmod +x /etc/profile.d/motd_server.sh
# Update      : load  (= git pull + deploy automatically)
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

# ── Auto-detect services ──────────────────────────────────────────────────────
STATUS_LINE=""

# AmneziaWG (docker container)
if docker ps --format '{{.Names}}' 2>/dev/null | grep -q 'amnezia-awg'; then
  PEERS_TOTAL=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l || echo 0)
  PEERS_ONLINE=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
    | awk -v t="$(date +%s)" '$5>0 && (t-$5)<180 {c++} END{print c+0}' || echo 0)
  STATUS_LINE+="  ${Y}AmneziaWG: ${G}${PEERS_ONLINE} online${X}${Y} / ${W}${PEERS_TOTAL} total peers${X}\n"
fi

# AdGuard Home
if systemctl is-active AdGuardHome >/dev/null 2>&1; then
  AGH_ST="${G}active${X}"
elif command -v AdGuardHome >/dev/null 2>&1 || [ -f /opt/AdGuardHome/AdGuardHome ]; then
  AGH_ST="${R}stopped${X}"
fi
[[ -n "${AGH_ST:-}" ]] && STATUS_LINE+="  ${Y}AdGuard: ${AGH_ST}\n"

# Xray VPN
if systemctl list-units --full -all 2>/dev/null | grep -q 'xray.service'; then
  if systemctl is-active xray >/dev/null 2>&1; then
    XRAY_ST="${G}active${X}"
  else
    XRAY_ST="${R}stopped${X}"
  fi
  STATUS_LINE+="  ${Y}Xray VPN: ${XRAY_ST}\n"
fi

# Samba
if systemctl list-units --full -all 2>/dev/null | grep -q 'smbd.service'; then
  if systemctl is-active smbd >/dev/null 2>&1; then
    SMB_USERS=$(smbstatus --brief 2>/dev/null | grep -c '^[0-9]' || echo 0)
    SMB_ST="${G}active${X}${Y} / ${W}${SMB_USERS} users${X}"
  else
    SMB_ST="${R}stopped${X}"
  fi
  STATUS_LINE+="  ${Y}Samba: ${SMB_ST}\n"
fi

# Fallback if nothing detected (bare server)
[[ -z "$STATUS_LINE" ]] && STATUS_LINE="  ${Y}No VPN services detected${X}\n"

# ── Output ───────────────────────────────────────────────────────────────────
echo -e "${C}${LINE}${X}"
printf "  ${C}\U0001f512  %-24s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" \
  "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
echo -ne "${STATUS_LINE}"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}VPN MANAGEMENT            SERVER                    GIT${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}sos${X}(audit 1h)             ${G}ports${X}(open ports)          ${G}save${X}(git push)"
echo -e "  ${G}sos24${X}(audit 24h)           ${G}banlist${X}(crowdsec/f2b bans)  ${G}load${X}(git pull+sos)"
echo -e "  ${G}infooo${X}(full server info)   ${G}antivir${X}(clamav scan)        ${G}00${X}(clear)"
echo -e "  ${G}xray_st${X} ${G}smb_st${X} ${G}adg_st${X}     ${G}ll${X}(list) ${G}la${X}(hidden) ${G}mc${X}(MC)"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}Ubuntu 24${X} | up ${W}${UPTIME}${X} | load 1m/5m/15m: ${G}${LOAD1} ${LOAD5} ${LOAD15}${X}"
echo
