#!/bin/bash
# =============================================================================
# motd_server.sh — MOTD banner for 222-DE-NetCup (xxx.xx.xxx.222)
# Version     : v2026-04-28
# Server      : NetCup.com, Germany | Ubuntu 24 / FASTPANEL / Cloudflare
#               4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe
# Install     : cp /root/Linux_Server_Public/222/motd_server.sh /etc/profile.d/motd_server.sh
#               chmod +x /etc/profile.d/motd_server.sh
# Update      : cd /root/Linux_Server_Public && git pull
#               cp 222/motd_server.sh /etc/profile.d/motd_server.sh
# = Rooted by VladiMIR | AI =
# =============================================================================
#
# FIX v2026-04-28: Guard against double MOTD display.
# Problem: profile.d fires on BOTH login shell AND every `source .bashrc`.
# Solution: only display when this is a true SSH login shell:
#   - shopt login_shell must be on
#   - AND $SSH_CONNECTION must be set (real remote SSH session)
# This way `source .bashrc` and `bash -c ...` never trigger MOTD.
# =============================================================================

# ── Guard: only show on real SSH login shell ──────────────────────────────────
shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0

C="\033[1;36m"   # cyan   — borders
G="\033[1;32m"   # green  — active / online / commands
Y="\033[1;33m"   # yellow — labels / section headers
W="\033[1;37m"   # white  — values
R="\033[1;31m"   # red    — inactive / error
X="\033[0m"      # reset
LINE="\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550"

# ── Server stats ──────────────────────────────────────────────────────────────
IP=$(hostname -I | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
HN=$(hostname)
LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

# ── AmneziaWG peers ───────────────────────────────────────────────────────────
# Count total peers and peers active within last 3 minutes (handshake < 180s ago)
PEERS_TOTAL=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l || echo 0)
PEERS_ONLINE=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
  | awk -v t="$(date +%s)" '$5>0 && (t-$5)<180 {c++} END{print c+0}')
[[ -z "$PEERS_TOTAL" || "$PEERS_TOTAL" == "0" ]] && PEERS_TOTAL=0
[[ -z "$PEERS_ONLINE" ]] && PEERS_ONLINE=0

# ── CrowdSec status ───────────────────────────────────────────────────────────
# Check if CrowdSec engine (IDS) and firewall bouncer (IPS) are running
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

# ── Header ────────────────────────────────────────────────────────────────────
echo -e "${C}${LINE}${X}"
printf "  ${C}\U0001f5a5  %-24s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" \
  "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
echo -e "  ${Y}AmneziaWG: ${G}${PEERS_ONLINE} online${X}${Y} / ${W}${PEERS_TOTAL} total peers${X}${Y}  |  CrowdSec Engine: ${CS_ENGINE}${Y}  Firewall: ${CS_FW}"
echo -e "${C}${LINE}${X}"

# ── Row 1: SCAN & SECURITY | SERVER | WORDPRESS ───────────────────────────────
echo -e "  ${Y}SCAN & SECURITY           SERVER                    WORDPRESS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}antivir${X}(ClamAV scan)      ${G}sos${X}(errors now)           ${G}wpupd${X}(WP update)"
echo -e "  ${G}fight${X}(block bots)         ${G}sos3${X}(last 3h)             ${G}wpcron${X}(WP cron)"
echo -e "  ${G}banlog${X}(ban list)          ${G}sos24${X}(last 24h)           ${G}wphealth${X}(WP health)"
echo -e "  ${G}cleanup${X}(disk clean)       ${G}watchdog${X}(PHP-FPM)         ${G}domains${X}(domain list)"
echo -e "${C}${LINE}${X}"

# ── Row 2: CRYPTO-BOT | GIT | TOOLS ──────────────────────────────────────────
echo -e "  ${Y}CRYPTO-BOT                GIT                       TOOLS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}tr${X}(start bot)            ${G}save${X}(git push)            ${G}infooo${X}(full info)"
echo -e "  ${G}clog100${X}(last 100 logs)   ${G}load${X}(git pull)            ${G}aws-test${X}(S3 test)"
echo -e "  ${G}reset${X}(restart bot)       ${G}00${X}(clear screen)          ${G}backup${X}(local backup)"
echo -e "  ${G}f5bot${X}(docker backup)     ${G}mc${X}(Midnight Cmdr)         ${G}allinfo${X}(all servers)"
echo -e "  ${G}f9bot${X}(bot restore)       ${G}repo${X}(pull public repo)    ${G}mailclean${X}(mail queue)"
echo -e "  ${G}f5vpn${X}(VPN backup)        ${G}secret${X}(private repo)      ${G}nginx-reload${X}(reload)"
echo -e "  ${G}allvpnstat${X}(VPN traffic)  ${G}allservers${X}(servers info)  ${G}banlog${X}(ban log)"
echo -e "${C}${LINE}${X}"

# ── Footer ────────────────────────────────────────────────────────────────────
echo -e "  ${Y}FastPanel${X} | ${Y}Ubuntu 24${X} | ${W}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
echo
