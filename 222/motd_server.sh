#!/bin/bash
# =============================================================================
# motd_server.sh — MOTD banner for 222-EU-NetCup (152.53.182.222)
# Version     : v2026.06.10d
# Server      : NetCup.com, Germany | Ubuntu 24 / FASTPANEL / Cloudflare
# Install     : cp 222/motd_server.sh /etc/profile.d/motd_server.sh
#               chmod +x /etc/profile.d/motd_server.sh
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
# =============================================================================

shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0

C="\033[1;36m"; G="\033[1;32m"; Y="\033[1;33m"
W="\033[1;37m"; R="\033[1;31m"; X="\033[0m"
LINE="\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550"

# --- Stats ---
IP=$(hostname -I | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
HN=$(hostname)
LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

# --- Xray / x-ui ---
XUI_URL="http://127.0.0.1:30452/OkNrdoVybueUzHY"
XUI_COOKIE="/tmp/xui_motd.cookie"
XUI_USER="vlad"
XUI_PASS="Gin-79513"

XRAY_TOTAL=0
XRAY_ENABLED=0

curl -s -c "$XUI_COOKIE" -X POST "${XUI_URL}/login" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=${XUI_USER}&password=${XUI_PASS}" -o /dev/null 2>/dev/null

XUI_JSON=$(curl -s -b "$XUI_COOKIE" "${XUI_URL}/xui/API/inbounds/" 2>/dev/null)
if echo "$XUI_JSON" | grep -q '"success":true'; then
  XRAY_TOTAL=$(echo "$XUI_JSON" | python3 -c \
    "import sys,json; data=json.load(sys.stdin); print(sum(len(i.get('clientStats',[])) for i in data.get('obj',[])))" 2>/dev/null || echo 0)
  XRAY_ENABLED=$(echo "$XUI_JSON" | python3 -c \
    "import sys,json; data=json.load(sys.stdin); print(sum(1 for i in data.get('obj',[]) for c in i.get('clientStats',[]) if c.get('enable')))" 2>/dev/null || echo 0)
fi

# --- CrowdSec ---
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

# --- Header ---
echo -e "${C}${LINE}${X}"
printf "  ${C}\U0001f310  %-22s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" \
  "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
echo -e "  ${Y}Xray: ${G}${XRAY_ENABLED} enabled${X}${Y} / ${W}${XRAY_TOTAL} total${X}  ${Y}CrowdSec Engine: ${CS_ENGINE}  Firewall: ${CS_FW}"
echo -e "${C}${LINE}${X}"

# --- Row 1: SCAN & SECURITY | SERVER | WORDPRESS ---
echo -e "  ${Y}SCAN & SECURITY           SERVER                    WORDPRESS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}antivir${X}(ClamAV scan)      ${G}sos${X}(errors 1h)            ${G}wpupd${X}(WP update)"
echo -e "  ${G}fight${X}(block bots)         ${G}sos3${X}(last 3h)             ${G}wpcron${X}(WP cron)"
echo -e "  ${G}banlog${X}(ban list)          ${G}sos24${X}(last 24h)           ${G}qs${X}(quick status)"
echo -e "  ${G}cleanup${X}(disk clean)       ${G}watchdog${X}(PHP-FPM)         ${G}domains${X}(domain list)"
echo -e "  ${G}banunblock${X}(unban IP)       ${G}backup${X}(system backup)     ${G}mailclean${X}(mail queue)"
echo -e "  ${G}banblock${X}(manual ban)"
echo -e "${C}${LINE}${X}"

# --- Row 2: GIT | TOOLS ---
echo -e "  ${Y}GIT                       TOOLS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}save${X}(git push)            ${G}infooo${X}(full info)          ${G}bot_st${X}(CryptoBot)"
echo -e "  ${G}load${X}(git pull)            ${G}aw${X}(VPN stats)             ${G}nginx-reload${X}(reload)"
echo -e "  ${G}repo${X}(pull public repo)    ${G}fpm-reload${X}(reload FPM)    ${G}reload-all${X}(both)"
echo -e "  ${G}secret${X}(private repo)      ${G}mc${X}(Midnight Cmdr)         ${G}00${X}(clear screen)"
echo -e "${C}${LINE}${X}"

# --- Footer ---
echo -e "  ${Y}FastPanel+CF${X} | ${Y}Ubuntu 24${X} | ${W}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
echo
