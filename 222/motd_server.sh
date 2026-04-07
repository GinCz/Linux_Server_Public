#!/bin/bash
# =============================================================================
# motd_server.sh — MOTD banner for 222-DE-NetCup (152.53.182.222)
# Version     : v2026-04-08d
# Server      : NetCup.com, Germany | Ubuntu 24 / FASTPANEL / Cloudflare
#               4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe
# Install     : cp /root/Linux_Server_Public/222/motd_server.sh /etc/profile.d/motd_server.sh
#               chmod +x /etc/profile.d/motd_server.sh
# CrowdSec    : add to crontab (crontab -e):
#               * * * * * cscli decisions list -o raw 2>/dev/null | awk -F',' '/ban/{c++} END{print c+0}' > /tmp/cs_banned_count
# Update      : cd /root/Linux_Server_Public && git pull
#               cp 222/motd_server.sh /etc/profile.d/motd_server.sh
# = Rooted by VladiMIR | AI =
# =============================================================================

C="\033[1;36m"   # cyan  — borders
G="\033[1;32m"   # green — alias names
Y="\033[1;33m"   # yellow — section headers, labels
W="\033[1;37m"   # white — values
R="\033[1;31m"   # red   — bans/alerts
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

# ── AmneziaWG: online peers / total peers (from Docker container) ─────────
# Online = peers that have sent a handshake in the last 3 minutes
AWG_RAW=$(docker exec amneziawg awg show all 2>/dev/null)
if [[ -n "$AWG_RAW" ]]; then
  AWG_TOTAL=$(echo "$AWG_RAW" | grep -c '^peer:')
  AWG_ONLINE=$(echo "$AWG_RAW" | awk '
    /latest handshake:/ {
      # parse seconds ago: "X seconds ago", "X minutes ago", "X hours ago"
      if ($3 ~ /second/ && $2 < 180) online++
      else if ($3 ~ /minute/ && $2 <= 3) online++
    }
    END { print online+0 }
  ')
else
  AWG_TOTAL="?"
  AWG_ONLINE="?"
fi

# ── CrowdSec: read from cron-updated cache (instant, no hang) ────────────
CS_BANNED=$(cat /tmp/cs_banned_count 2>/dev/null | tr -d ' \n')
[[ -z "$CS_BANNED" ]] && CS_BANNED="?"

# ── Nginx: active HTTP/HTTPS connections ─────────────────────────────
NGINX_CONN=$(ss -tn state established '( dport = :80 or dport = :443 )' 2>/dev/null \
  | tail -n +2 | wc -l | tr -d ' ')
[[ -z "$NGINX_CONN" ]] && NGINX_CONN=0

# ── Header ───────────────────────────────────────────────────
echo -e "${C}${LINE}${X}"
printf "  ${C}\U0001f5a5  %-24s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" \
  "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
echo -e "  ${Y}AmneziaWG: ${G}${AWG_ONLINE} online${X}${Y} / ${W}${AWG_TOTAL} total peers${X}${Y} | CrowdSec: ${R}${CS_BANNED} banned${X}${Y} / Nginx: ${G}${NGINX_CONN}${X}${Y} connections${X}"
echo -e "${C}${LINE}${X}"

# ── Row 1: SCAN & SECURITY | SERVER | WORDPRESS ────────────────────────
echo -e "  ${Y}SCAN & SECURITY           SERVER                    WORDPRESS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}antivir${X}(ClamAV scan)      ${G}sos${X}(errors now)           ${G}wpupd${X}(WP update)"
echo -e "  ${G}fight${X}(block bots)         ${G}sos3${X}(last 3h)             ${G}wpcron${X}(WP cron)"
echo -e "  ${G}banlog${X}(ban list)          ${G}sos24${X}(last 24h)           ${G}wphealth${X}(WP health)"
echo -e "  ${G}cleanup${X}(disk clean)       ${G}watchdog${X}(PHP-FPM)         ${G}domains${X}(domain list)"
echo -e "${C}${LINE}${X}"

# ── Row 2: CRYPTO-BOT | GIT | TOOLS ──────────────────────────────────
echo -e "  ${Y}CRYPTO-BOT                GIT                       TOOLS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}tr${X}(start bot)            ${G}save${X}(git push)            ${G}infooo${X}(full info)"
echo -e "  ${G}clog${X}(last 40 logs)       ${G}load${X}(git pull)            ${G}aws-test${X}(S3 test)"
echo -e "  ${G}clog100${X}(last 100 logs)   ${G}00${X}(clear screen)          ${G}backup${X}(local backup)"
echo -e "  ${G}reset${X}(restart bot)       ${G}mc${X}(Midnight Cmdr)         ${G}allinfo${X}(all servers)"
echo -e "  ${G}f5bot${X}(docker backup)     ${G}repo${X}(pull public repo)    ${G}mailclean${X}(mail queue)"
echo -e "  ${G}f9bot${X}(bot restore)       ${G}secret${X}(private repo)      ${G}nginx-reload${X}(reload)"
echo -e "${C}${LINE}${X}"

# ── Footer ───────────────────────────────────────────────────
echo -e "  ${Y}FastPanel${X} | ${Y}Ubuntu 24${X} | ${W}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
echo
