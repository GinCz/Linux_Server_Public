#!/bin/bash
# =============================================================================
# motd_server.sh — MOTD banner for 109-RU-FastVDS (212.109.223.109)
# Version     : v2026-04-08c
# Server      : FastVDS.ru, Russia | Ubuntu 24 / FASTPANEL / No Cloudflare
#               4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe
# Install     : cp /root/Linux_Server_Public/109/motd_server.sh /etc/profile.d/motd_server.sh
#               chmod +x /etc/profile.d/motd_server.sh
# Update      : cd /root/Linux_Server_Public && git pull
#               cp 109/motd_server.sh /etc/profile.d/motd_server.sh
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"   # cyan  — borders
G="\033[1;32m"   # green — alias names
Y="\033[1;33m"   # yellow — section headers, labels
W="\033[1;37m"   # white — values
R="\033[1;31m"   # red   — bans/alerts
X="\033[0m"      # reset
LINE="\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550"

# ── Gather server stats ───────────────────────────────────────────────
IP=$(hostname -I | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
HN=$(hostname)
LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

# ── CrowdSec: count banned IPs with 3s timeout to prevent hang ───────────
CS_BANNED=$(timeout 3s cscli decisions list -o raw 2>/dev/null \
  | awk -F',' '/ban/{c++} END{print c+0}')
[[ -z "$CS_BANNED" ]] && CS_BANNED="?"

# ── Nginx: active HTTP/HTTPS connections ─────────────────────────────
NGINX_CONN=$(ss -tn state established '( dport = :80 or dport = :443 )' 2>/dev/null \
  | tail -n +2 | wc -l | tr -d ' ')
[[ -z "$NGINX_CONN" ]] && NGINX_CONN=0

# ── Header ───────────────────────────────────────────────────
echo -e "${C}${LINE}${X}"
printf "  ${C}\U0001f5a5  %-24s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" \
  "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
echo -e "  ${Y}CrowdSec: ${R}${CS_BANNED} banned IPs${X}${Y} / Nginx: ${G}${NGINX_CONN}${X}${Y} active connections${X}"
echo -e "${C}${LINE}${X}"

# ── Row 1: SCAN & SECURITY | SERVER | WORDPRESS ────────────────────────
echo -e "  ${Y}SCAN & SECURITY           SERVER                    WORDPRESS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}antivir${X}(ClamAV scan)      ${G}sos${X}(errors now)           ${G}wpupd${X}(WP update)"
echo -e "  ${G}fight${X}(block bots)         ${G}sos3${X}(last 3h)             ${G}wpcron${X}(WP cron)"
echo -e "  ${G}banlog${X}(ban list)          ${G}sos24${X}(last 24h)           ${G}wphealth${X}(WP health)"
echo -e "  ${G}cleanup${X}(disk clean)       ${G}watchdog${X}(PHP-FPM)         ${G}domains${X}(domain list)"
echo -e "  ${G}banunblock${X}(unban IP)      ${G}backup${X}(system backup)     ${G}mailclean${X}(mail queue)"
echo -e "  ${G}banblock${X}(manual ban)      ${G}allinfo${X}(all servers)"
echo -e "${C}${LINE}${X}"

# ── Row 2: GIT | TOOLS ───────────────────────────────────────────────
echo -e "  ${Y}GIT                       TOOLS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}save${X}(git push)            ${G}infooo${X}(full info)          ${G}aws-test${X}(S3 test)"
echo -e "  ${G}load${X}(git pull)            ${G}aw${X}(VPN stats)             ${G}nginx-reload${X}(reload)"
echo -e "  ${G}repo${X}(pull public repo)    ${G}fpm-reload${X}(reload FPM)    ${G}reload-all${X}(both)"
echo -e "  ${G}secret${X}(private repo)      ${G}mc${X}(Midnight Cmdr)         ${G}00${X}(clear screen)"
echo -e "${C}${LINE}${X}"

# ── Footer ───────────────────────────────────────────────────
echo -e "  ${Y}FastPanel${X} | ${Y}Ubuntu 24${X} | ${W}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
echo
