#!/bin/bash
# =============================================================================
# motd_server.sh — MOTD banner for 109-RU-FastVDS (212.109.223.109)
# Version     : v2026.05.21
# Server      : FastVDS.ru, Russia | Ubuntu 24 / FASTPANEL / No Cloudflare
#               4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe
# Install     : cp /root/Linux_Server_Public/109/motd_server.sh /etc/profile.d/motd_server.sh
#               chmod +x /etc/profile.d/motd_server.sh
# Update      : cd /root/Linux_Server_Public && git pull
#               cp 109/motd_server.sh /etc/profile.d/motd_server.sh
# = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =
# =============================================================================

C="\033[1;36m"   # cyan  — borders
G="\033[1;32m"   # green — active / online
Y="\033[1;33m"   # yellow — labels
W="\033[1;37m"   # white — values
R="\033[1;31m"   # red   — inactive / error
X="\033[0m"      # reset
LINE="\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550"

# ── Server stats ─────────────────────────────────────────────────────────
IP=$(hostname -I | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
HN=$(hostname)
LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

# ── AmneziaWG peers ──────────────────────────────────────────────────────
PEERS_TOTAL=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l || echo 0)
PEERS_ONLINE=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
  | awk -v t="$(date +%s)" '$5>0 && (t-$5)<180 {c++} END{print c+0}')
[[ -z "$PEERS_TOTAL" || "$PEERS_TOTAL" == "0" ]] && PEERS_TOTAL=0
[[ -z "$PEERS_ONLINE" ]] && PEERS_ONLINE=0

# ── CrowdSec status ───────────────────────────────────────────────────────
if systemctl is-active --quiet crowdsec 2>/dev/null; then
  CS_ENGINE="${G}\u25cf ACTIVE${X}"
else
  CS_ENGINE="${R}\u25cf INACTIVE${X}"
fi

if systemctl is-active --quiet crowdsec-firewall-bouncer 2>/dev/null; then
  CS_FW="${G}\u25cf ACTIVE${X}"
else
  CS_FW="${R}\u25cf INACTIVE${X}"
fi

# ── Header ───────────────────────────────────────────────────────────────
echo -e "${C}${LINE}${X}"
printf "  ${C}\U0001f5a5  %-24s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" \
  "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
echo -e "  ${Y}AmneziaWG: ${G}${PEERS_ONLINE} online${X}${Y} / ${W}${PEERS_TOTAL} total peers${X}${Y}  |  CrowdSec Engine: ${CS_ENGINE}${Y}  Firewall: ${CS_FW}"
echo -e "${C}${LINE}${X}"

# ── Row 1: SCAN & SECURITY | SERVER | WORDPRESS ──────────────────────────
echo -e "  ${Y}SCAN & SECURITY           SERVER                    WORDPRESS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}antivir${X}(ClamAV scan)      ${G}sos${X}(errors now)           ${G}wpupd${X}(WP update)"
echo -e "  ${G}fight${X}(block bots)         ${G}sos3${X}(last 3h)             ${G}wpcron${X}(WP cron)"
echo -e "  ${G}banlog${X}(ban list)          ${G}sos24${X}(last 24h)           ${G}wphealth${X}(WP health)"
echo -e "  ${G}cleanup${X}(disk clean)       ${G}watchdog${X}(PHP-FPM)         ${G}domains${X}(domain list)"
echo -e "  ${G}banunblock${X}(unban IP)      ${G}backup${X}(system backup)     ${G}mailclean${X}(mail queue)"
echo -e "  ${G}banblock${X}(manual ban)"
echo -e "${C}${LINE}${X}"

# ── Row 2: GIT | TOOLS ───────────────────────────────────────────────────
echo -e "  ${Y}GIT                       TOOLS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}save${X}(git push)            ${G}infooo${X}(full info)          ${G}aws-test${X}(S3 test)"
echo -e "  ${G}load${X}(git pull)            ${G}aw${X}(VPN stats)             ${G}nginx-reload${X}(reload)"
echo -e "  ${G}repo${X}(pull public repo)    ${G}fpm-reload${X}(reload FPM)    ${G}reload-all${X}(both)"
echo -e "  ${G}secret${X}(private repo)      ${G}mc${X}(Midnight Cmdr)         ${G}00${X}(clear screen)"
echo -e "${C}${LINE}${X}"

# ── Footer ───────────────────────────────────────────────────────────────
echo -e "  ${Y}FastPanel${X} | ${Y}Ubuntu 24${X} | ${W}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
echo
