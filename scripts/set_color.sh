#!/bin/bash
# set_color.sh — PS1 color picker + server type + MOTD
# Version: v2026.06.09
# = Rooted by VladiMIR + AI | v.2026.06.09 | github.com/GinCz =
# ============================================================
# ONE-LINER (copy to any server):
# bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/set_color.sh)
# ============================================================

clear

C='\033[1;36m'; W='\033[1;37m'; Y='\033[1;33m'; G='\033[1;32m'; X='\033[0m'

echo -e "${C}════════════════════════════════════════════${X}"
echo -e "  ${W}SET COLOR + SERVER TYPE + MOTD${X}"
echo -e "${C}════════════════════════════════════════════${X}"
echo

# ─── STEP 1: Server type ─────────────────────────────────────
echo -e "  ${Y}Select server type:${X}"
echo -e "  1) VPN              (XRay + AmneziaWG + AdGuard)"
echo -e "  2) FastPanel + CF   (server 222: Cloudflare + XRay + CryptoBot)"
echo -e "  3) FastPanel only   (server 109: Russian sites, no Cloudflare)"
echo
read -rp "  Type [1/2/3, default 1]: " SRV_TYPE
SRV_TYPE="${SRV_TYPE:-1}"
[[ "$SRV_TYPE" =~ ^[123]$ ]] || SRV_TYPE=1

case "$SRV_TYPE" in
  1) TYPE_NAME="VPN / XRay / AmneziaWG / AdGuard / Semaphore" ;;
  2) TYPE_NAME="FastPanel + Cloudflare + XRay + CryptoBot" ;;
  3) TYPE_NAME="FastPanel + XRay (no Cloudflare)" ;;
esac

echo
echo -e "  ${G}Type: ${TYPE_NAME}${X}"
echo

# ─── STEP 2: PS1 color ───────────────────────────────────────
echo -e "  ${Y}Select terminal PS1 color:${X}"
echo -e "  \033[01;96m1) Bright Cyan     — бирюзовый (VPN default)\033[0m"
echo -e "  \033[01;91m2) Bright Red      — красный\033[0m"
echo -e "  \033[01;92m3) Bright Green    — зелёный\033[0m"
echo -e "  \033[01;93m4) Bright Yellow   — жёлтый (222 default)\033[0m"
echo -e "  \033[01;95m5) Bright Magenta  — малиновый\033[0m"
echo -e "  \033[38;5;208m6) Orange          — оранжевый\033[0m"
echo -e "  \033[38;5;213m7) Bright Pink     — розовый\033[0m"
echo -e "  \033[01;97m8) Bright White    — белый (109 default)\033[0m"
echo

case "$SRV_TYPE" in
  2) DEF_COLOR=4 ;;
  3) DEF_COLOR=8 ;;
  *) DEF_COLOR=1 ;;
esac

read -rp "  Color [1-8, default ${DEF_COLOR}]: " CC
CC="${CC:-${DEF_COLOR}}"

case "$CC" in
  1) PS1_CODE='01;96m';    PS1_NAME="Bright Cyan"    ; MOTD_COLOR='\033[01;96m' ;;
  2) PS1_CODE='01;91m';    PS1_NAME="Bright Red"     ; MOTD_COLOR='\033[01;91m' ;;
  3) PS1_CODE='01;92m';    PS1_NAME="Bright Green"   ; MOTD_COLOR='\033[01;92m' ;;
  4) PS1_CODE='01;93m';    PS1_NAME="Bright Yellow"  ; MOTD_COLOR='\033[01;93m' ;;
  5) PS1_CODE='01;95m';    PS1_NAME="Bright Magenta" ; MOTD_COLOR='\033[01;95m' ;;
  6) PS1_CODE='38;5;208m'; PS1_NAME="Orange"         ; MOTD_COLOR='\033[38;5;208m' ;;
  7) PS1_CODE='38;5;213m'; PS1_NAME="Bright Pink"    ; MOTD_COLOR='\033[38;5;213m' ;;
  8) PS1_CODE='01;97m';    PS1_NAME="Bright White"   ; MOTD_COLOR='\033[01;97m' ;;
  *) PS1_CODE='01;96m';    PS1_NAME="Bright Cyan"    ; MOTD_COLOR='\033[01;96m' ;;
esac

# ─── STEP 3: Apply PS1 to .bashrc ────────────────────────────
PS1_VALUE="\\[\\033[${PS1_CODE}\\]\\u@\\h:\\w\\\$\\[\\033[00m\\] "

sed -i '/^export PS1=/d' /root/.bashrc
sed -i '/^PS1=/d' /root/.bashrc
echo "export PS1='${PS1_VALUE}'" >> /root/.bashrc

sed -i '/^export PS1=/d' /root/.bash_profile 2>/dev/null || true
sed -i '/^PS1=/d' /root/.bash_profile 2>/dev/null || true
echo "export PS1='${PS1_VALUE}'" >> /root/.bash_profile 2>/dev/null || true

# ─── STEP 4: Build MOTD cheatsheet per server type ───────────
case "$SRV_TYPE" in
  1) MOTD_TYPE_LINE="VPN / XRay / AmneziaWG / AdGuard / Semaphore"
     MOTD_CHEATSHEET='  ${G}amn_st${X}(AmneziaWG)    ${G}adg_st${X}(AdGuard)      ${G}save${X}(git push)
  ${G}antivir${X}(ClamAV)       ${G}banlist${X}(bans)        ${G}load${X}(git pull)
  ${G}sos${X}(audit 1h)         ${G}sos24${X}(audit 24h)     ${G}infooo${X}(server info)
  ${G}upd${X}(apt upgrade)      ${G}ports${X}(open ports)    ${G}00${X}(clear screen)' ;;
  2) MOTD_TYPE_LINE="FastPanel + Cloudflare + XRay + CryptoBot"
     MOTD_CHEATSHEET='  ${G}save${X}(git push)        ${G}fp${X}(web dir)           ${G}antivir${X}(ClamAV)
  ${G}load${X}(git pull)        ${G}nginx_test${X}           ${G}infooo${X}(server info)
  ${G}bk${X}(backup)            ${G}bot_log${X}(CryptoBot)   ${G}upd${X}(apt upgrade)
  ${G}sos${X}(audit 1h)         ${G}sos24${X}(audit 24h)     ${G}ports${X}(open ports)' ;;
  3) MOTD_TYPE_LINE="FastPanel + XRay (no Cloudflare)"
     MOTD_CHEATSHEET='  ${G}save${X}(git push)        ${G}fp${X}(web dir)           ${G}antivir${X}(ClamAV)
  ${G}load${X}(git pull)        ${G}nginx_test${X}           ${G}infooo${X}(server info)
  ${G}bk${X}(backup)            ${G}nginx_reload${X}         ${G}upd${X}(apt upgrade)
  ${G}sos${X}(audit 1h)         ${G}sos24${X}(audit 24h)     ${G}ports${X}(open ports)' ;;
esac

# ─── STEP 5: Write MOTD to /etc/profile.d/ ───────────────────
SRV_NAME_MOTD=$(hostname)

chmod -x /etc/update-motd.d/* 2>/dev/null || true
rm -f /etc/update-motd.d/10-help-text /etc/update-motd.d/50-motd-news 2>/dev/null || true

cat > /etc/profile.d/motd_server.sh << MOTD_SCRIPT
#!/bin/bash
# MOTD — ${SRV_NAME_MOTD} | v2026.06.09
# = Rooted by VladiMIR + AI | github.com/GinCz =
shopt -q login_shell || return 0 2>/dev/null || exit 0
[ -n "\$SSH_CONNECTION" ] || return 0 2>/dev/null || exit 0

C="${MOTD_COLOR}"; G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'
LINE=\$(printf '%0.s━' {1..78})

HN=\$(cat /etc/hostname 2>/dev/null | head -1 | tr -d '[:space:]')
[[ -z "\$HN" ]] && HN=\$(hostname 2>/dev/null || echo "unknown")
IP=\$(hostname -I 2>/dev/null | awk '{print \$1}')
RAM_USED=\$(free -m | awk '/Mem:/{print \$3}')
RAM_TOTAL=\$(free -m | awk '/Mem:/{print \$2}')
CPU=\$(top -bn1 | grep 'Cpu(s)' | awk '{print int(\$2+\$4)}')
UPTIME=\$(uptime -p | sed 's/up //')
LOAD=\$(awk '{print \$1" "\$2" "\$3}' /proc/loadavg)

if systemctl is-active --quiet crowdsec 2>/dev/null; then
  BAN_COUNT=\$(cscli decisions list -o raw 2>/dev/null | grep -c ',' || echo 0)
  CS_LINE="  \${Y}CrowdSec:\${X} \${G}● ACTIVE\${X} | bans: \${W}\${BAN_COUNT}\${X}"
else
  CS_LINE="  \${Y}CrowdSec:\${X} \${R}✗ INACTIVE\${X}"
fi

echo -e "\${C}\${LINE}\${X}"
echo -e "  \${C}🖥  \${W}\${HN}\${X}  \${Y}\${IP}\${X}  RAM:\${W}\${RAM_USED}/\${RAM_TOTAL}MB\${X}  CPU:\${W}\${CPU}%\${X}  up \${W}\${UPTIME}\${X}"
echo -e "  \${Y}Type:\${X} ${MOTD_TYPE_LINE}"
echo -e "\${CS_LINE}"
echo -e "\${C}\${LINE}\${X}"
echo -e "  \${Y}CHEATSHEET:\${X}"
echo -e "${MOTD_CHEATSHEET}"
echo -e "\${C}\${LINE}\${X}"
echo -e "  load: \${G}\${LOAD}\${X}  |  \${Y}Ubuntu 24\${X}  |  \${W}= Rooted by VladiMIR + AI =\${X}"
echo
MOTD_SCRIPT

chmod +x /etc/profile.d/motd_server.sh

# ─── Done ────────────────────────────────────────────────────
source /root/.bashrc 2>/dev/null || true

echo
echo -e "${C}════════════════════════════════════════════${X}"
echo -e "  ${G}✓ Color : ${PS1_NAME}${X}"
echo -e "  ${G}✓ Type  : ${TYPE_NAME}${X}"
echo -e "  ${G}✓ MOTD  : /etc/profile.d/motd_server.sh${X}"
echo -e "  ${G}✓ PS1   : saved to .bashrc + .bash_profile${X}"
echo -e "${C}════════════════════════════════════════════${X}"
echo -e "  Reconnect SSH to see new MOTD"
echo -e "  ${W}= Rooted by VladiMIR + AI | v.2026.06.09 | github.com/GinCz =${X}"
echo
