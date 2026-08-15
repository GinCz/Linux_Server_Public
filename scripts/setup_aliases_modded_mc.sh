#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  setup_aliases_modded_mc.sh | [v2026-06-10]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Environment customization tool and Midnight Commander enhancements
# Servers     : All Linux Nodes
# Usage       : bash scripts/setup_aliases_modded_mc.sh
# ==========================================================================================
CYAN='\033[01;96m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
WHITE='\033[1;37m'
RESET='\033[0m'

LINE="================================================================================================="

echo -e "${CYAN}${LINE}${RESET}"
echo -e "${GREEN}  SERVER SETUP INITIALIZATION — Deploying Environment...${RESET}"
echo -e "${CYAN}${LINE}${RESET}"

# --- VARIABLES AND PATHS -----------------------------------------------------------------------
REPO_URL="https://github.com/GinCz/Linux_Server_Public.git"
REPO="/root/Linux_Server_Public"
SCRIPTS="$REPO/scripts"
BASHRC="/root/.bashrc"
BASH_PROFILE="/root/.bash_profile"

# --- HOSTNAME SETUP ----------------------------------------------------------------------------
CURRENT_HOSTNAME=$(hostname)
echo -e "${CYAN}${LINE}${RESET}"
echo -e "  ${YELLOW}[1/11] Set server hostname${RESET}"
echo -e "         Current hostname: ${WHITE}${CURRENT_HOSTNAME}${RESET}"
read -p "  Enter new hostname (leave blank to keep '${CURRENT_HOSTNAME}'): " NEW_HOSTNAME

if [ -n "$NEW_HOSTNAME" ] && [ "$NEW_HOSTNAME" != "$CURRENT_HOSTNAME" ]; then
    hostnamectl set-hostname "$NEW_HOSTNAME"
    sed -i "s/\b${CURRENT_HOSTNAME}\b/${NEW_HOSTNAME}/g" /etc/hosts
    if ! grep -q "127.0.1.1" /etc/hosts; then
        echo "127.0.1.1   ${NEW_HOSTNAME}" >> /etc/hosts
    fi
    SERVER_NAME="$NEW_HOSTNAME"
    echo -e "         ${GREEN}Hostname set to: ${SERVER_NAME}${RESET}"
else
    SERVER_NAME="$CURRENT_HOSTNAME"
    echo -e "         ${GREEN}Hostname unchanged: ${SERVER_NAME}${RESET}"
fi

SERVER_IP=$(hostname -I | awk '{print $1}')
echo -e "         IP Address: ${GREEN}${SERVER_IP}${RESET}"

# --- GIT REPOSITORY INTEGRATION ----------------------------------------------------------------
echo -e "${YELLOW}  [2/11] Checking local script repository...${RESET}"
if [ ! -d "$REPO/.git" ]; then
    echo -e "        Repository not found. Cloning from GitHub..."
    cd /root && git clone "$REPO_URL"
else
    echo -e "        ${GREEN}Local repository replica exists. Skipping clone.${RESET}"
fi

# --- MANUAL SERVER TYPE SELECTION --------------------------------------------------------------
echo -e "${CYAN}${LINE}${RESET}"
echo -e "  Select server profile:"
echo -e "  ${GREEN}1)${RESET} FastPanel + Cloudflare  ${YELLOW}(Web EU — 152.53.182.222)${RESET}"
echo -e "  ${GREEN}2)${RESET} FastPanel               ${YELLOW}(Web RU — 212.109.223.109)${RESET}"
echo -e "  ${GREEN}3)${RESET} VPN Node                ${YELLOW}(standalone VPN server)${RESET}"
echo -e "${CYAN}${LINE}${RESET}"
read -p "  Choose profile [1-3]: " PROFILE_CHOICE

case $PROFILE_CHOICE in
    1) SERVER_TYPE="fast-panel+cloudflare" ;;
    2) SERVER_TYPE="fast-panel" ;;
    3) SERVER_TYPE="vpn" ;;
    *)
        echo -e "  ${YELLOW}Invalid choice. Defaulting to VPN profile.${RESET}"
        SERVER_TYPE="vpn"
        ;;
esac
echo -e "        Selected Profile: ${GREEN}$SERVER_TYPE${RESET}"

# --- INTERACTIVE PS1 COLOR SELECTION -----------------------------------------------------------
echo -e "${CYAN}${LINE}${RESET}"
echo -e "  Select prompt color scheme (PS1):"
echo -e "  1) \e[01;33mYELLOW\e[0m  2) \e[38;5;217mLIGHT PINK\e[0m  3) \e[38;5;87mTURQUOISE\e[0m  4) \e[01;32mGREEN\e[0m  5) \e[38;5;214mORANGE\e[0m"
read -p "  Choose number [1-5]: " C

case $C in
    1) PS1_COLOR='\[\033[01;33m\]'; PS1_RESET='\[\033[00m\]'; PS1_NAME="YELLOW";;
    2) PS1_COLOR='\[\e[38;5;217m\]'; PS1_RESET='\[\e[m\]';    PS1_NAME="LIGHT PINK";;
    3) PS1_COLOR='\[\e[38;5;87m\]';  PS1_RESET='\[\e[m\]';    PS1_NAME="TURQUOISE";;
    4) PS1_COLOR='\[\033[01;32m\]'; PS1_RESET='\[\033[00m\]';  PS1_NAME="GREEN";;
    5) PS1_COLOR='\[\e[38;5;214m\]'; PS1_RESET='\[\e[m\]';    PS1_NAME="ORANGE";;
    *) PS1_COLOR=''; PS1_RESET=''; PS1_NAME="default (no change)";;
esac

echo -e "${YELLOW}  [3/11] Configuring command line prompt...${RESET}"
if [ -n "$PS1_COLOR" ]; then
    sed -i '/export PS1=/d' "$BASHRC"
    sed -i '/export PS1=/d' "$BASH_PROFILE" 2>/dev/null
    echo "export PS1=\"${PS1_COLOR}\\u@\\h:\\w\\$ ${PS1_RESET}\"" >> "$BASHRC"
    echo "export PS1=\"${PS1_COLOR}\\u@\\h:\\w\\$ ${PS1_RESET}\"" >> "$BASH_PROFILE"
    echo -e "        ${GREEN}Prompt color set: $PS1_NAME${RESET}"
fi

# --- TIMEZONE & TIMESYNC -----------------------------------------------------------------------
echo -e "${YELLOW}  [4/11] Setting timezone to Europe/Prague...${RESET}"
timedatectl set-timezone Europe/Prague
systemctl restart systemd-timesyncd
TZ_SET=$(timedatectl show --property=Timezone --value)
echo -e "        ${GREEN}Timezone set: $TZ_SET${RESET}"

# --- AUTO-UPGRADE CRON SETUP -------------------------------------------------------------------
echo -e "${YELLOW}  [5/11] Configuring auto-upgrade + autoremove + reboot cron (daily 03:00)...${RESET}"
(crontab -l 2>/dev/null | grep -v 'reboot\|apt.*update\|apt.*upgrade\|apt.*autoremove'; \
echo "0 3 * * * DEBIAN_FRONTEND=noninteractive apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get upgrade -y -qq && apt-get autoremove -y -qq >> /var/log/auto-upgrade.log 2>&1 && /sbin/reboot") | crontab -
echo -e "        ${GREEN}Cron installed (03:00 daily — update + upgrade + autoremove + reboot):${RESET}"
crontab -l | grep -v '^#' | grep .
echo -e "        Current server time: ${GREEN}$(date)${RESET}"

# --- SOS MONITOR INSTALLATION ------------------------------------------------------------------
echo -e "${YELLOW}  [6/11] Installing sos monitor...${RESET}"
SOS_STATUS="NOT FOUND"
if [ -f "$SCRIPTS/install_sos.sh" ]; then
    bash "$SCRIPTS/install_sos.sh"
    SOS_STATUS="/usr/local/bin/sos (via install_sos.sh)"
    echo -e "        ${GREEN}sos installed via install_sos.sh${RESET}"
elif [ -f "$SCRIPTS/sos.sh" ]; then
    cp "$SCRIPTS/sos.sh" /usr/local/bin/sos
    chmod +x /usr/local/bin/sos
    SOS_STATUS="/usr/local/bin/sos"
    echo -e "        ${GREEN}sos monitor installed: /usr/local/bin/sos${RESET}"
else
    echo -e "        ${YELLOW}sos script not found, skipping.${RESET}"
fi

# --- INFOOO INSTALLATION -----------------------------------------------------------------------
echo -e "${YELLOW}  [7/11] Installing infooo...${RESET}"
INFOOO_STATUS="NOT FOUND"
if [ -f "$SCRIPTS/infooo.sh" ]; then
    cp "$SCRIPTS/infooo.sh" /usr/local/bin/infooo
    chmod +x /usr/local/bin/infooo
    INFOOO_STATUS="/usr/local/bin/infooo"
    echo -e "        ${GREEN}infooo installed: /usr/local/bin/infooo${RESET}"
else
    echo -e "        ${YELLOW}infooo.sh not found in $SCRIPTS, skipping.${RESET}"
fi

# --- LOAD GLOBAL COMMAND INSTALLATION ----------------------------------------------------------
# load = git pull only. Full installer = bash scripts/setup_aliases_modded_mc.sh
echo -e "${YELLOW}  [8/11] Installing global 'load' command...${RESET}"
cat > /usr/local/bin/load << 'LOADEOF'
#!/bin/bash
REPO="/root/Linux_Server_Public"
cd "$REPO" || { echo "ERROR: Repo not found at $REPO"; exit 1; }
git pull origin main --no-rebase --no-edit
echo "=== Done. Re-login or run: source ~/.bashrc ==="
LOADEOF
chmod +x /usr/local/bin/load
echo -e "        ${GREEN}load installed: /usr/local/bin/load (git pull only)${RESET}"

# --- PURGE LEGACY MARKERS & WRITE ALIASES -----------------------------------------------------
echo -e "${YELLOW}  [9/11] Updating environment alias definitions...${RESET}"
MARKER="# === Linux_Server_Public aliases ==="

# Purge old motd_vpn.sh source calls from .bashrc and .bash_profile (cause of double banner)
for FILE in "$BASHRC" "$BASH_PROFILE"; do
    sed -i '/motd_vpn\.sh/d' "$FILE" 2>/dev/null
    sed -i '/scripts\/motd/d' "$FILE" 2>/dev/null
done

for P in 'Rooted by VladiMIR' 'v2026-05-0' '# ~/.bashrc — VPN' 'VPN NODE FULL INSTALL'; do
    sed -i "/${P}/d" "$BASHRC" 2>/dev/null
    sed -i "/${P}/d" "$BASH_PROFILE" 2>/dev/null
done
grep -q "$MARKER" "$BASHRC" 2>/dev/null && sed -i "/^${MARKER}/,\$d" "$BASHRC"

echo "" >> "$BASHRC"
echo "$MARKER" >> "$BASHRC"

# === GLOBAL aliases — all 3 profiles ===
printf '%s\n' \
"alias 00='clear'" \
"alias cls='clear'" \
"alias c='clear'" \
"alias sos='/usr/local/bin/sos 1h'" \
"alias sos1='/usr/local/bin/sos 1h'" \
"alias sos3='/usr/local/bin/sos 3h'" \
"alias sos24='/usr/local/bin/sos 24h'" \
"alias sos120='/usr/local/bin/sos 120h'" \
"alias infooo='/usr/local/bin/infooo'" \
"alias load='/usr/local/bin/load'" \
"alias antivir='bash $SCRIPTS/scan_clamav.sh 2>/dev/null || echo \"ClamAV script not found\"'" \
"alias upd='bash $SCRIPTS/upd.sh 2>/dev/null || echo \"upd.sh not found\"'" >> "$BASHRC"

# === PROFILE-SPECIFIC aliases ===
if [ "$SERVER_TYPE" = "fast-panel+cloudflare" ]; then
    echo "source $SCRIPTS/shared_aliases_222.sh" >> "$BASHRC"
    echo "alias save='cd $REPO && git add -A && (git diff --cached --quiet && echo \"Nothing to commit\" || git commit -m \"save: \$(hostname) \$(date +%Y-%m-%d_%H:%M)\") && git push origin main && echo \"=== Saved ===\"'" >> "$BASHRC"
elif [ "$SERVER_TYPE" = "fast-panel" ]; then
    echo "source $SCRIPTS/shared_aliases_109.sh" >> "$BASHRC"
# vpn profile: no extra aliases — only global block above
fi

echo -e "        ${GREEN}Aliases written to $BASHRC${RESET}"

# --- FIX /etc/bash.bashrc — REPAIR BROKEN SYSTEM ALIASES BLOCK --------------------------------
BASHRC_SYS="/etc/bash.bashrc"
sed -i '/# === USER ALIASES BLOCK ===/,/# === END USER ALIASES BLOCK ===/d' "$BASHRC_SYS" 2>/dev/null

cat >> "$BASHRC_SYS" << 'SYSEOF'
# === USER ALIASES BLOCK ===
# = Rooted by VladiMIR + AI | v.2026.06.10 =
alias 00='clear'
alias cls='clear'
alias c='clear'
alias mod='/usr/local/bin/mod'
alias ls='ls --color=auto'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
export MC_COLOR_TABLE='_default_=lightgray,blue:marked=yellow,blue:errors=white,red:menu=black,lightgray:menusel=white,blue:menuhot=red,lightgray:menuhotsel=red,blue:dnormal=lightgray,blue:dfocus=white,cyan:dhotnormal=red,blue:dhotfocus=red,cyan:execute=lightgreen,blue:directory=white,blue:link=cyan,blue:device=brightmagenta,blue:special=lightgray,blue:core=red,blue:stalelink=red,blue'
# === END USER ALIASES BLOCK ===
SYSEOF

# --- DYNAMIC SSH WELCOME BANNER GENERATION (MOTD) ---------------------------------------------
echo -e "${YELLOW}  [10/11] Building dynamic MOTD + MC F2 menu...${RESET}"
rm -f /etc/profile.d/motd_*.sh; chmod -x /etc/update-motd.d/* 2>/dev/null

# ---- MOTD for WEB server 222 (fast-panel+cloudflare) -----------------------------------------
if [ "$SERVER_TYPE" = "fast-panel+cloudflare" ]; then
cat > /etc/profile.d/motd_banner.sh << 'MOTDEOF'
#!/bin/bash
[ -n "$SSH_CONNECTION" ] || return 0
shopt -q login_shell 2>/dev/null || return 0
clear
HN=$(hostname)
IP=$(hostname -I | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)
C='\033[01;96m'; G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'
LINE='════════════════════════════════════════════════════════════════════════════════'
CS_ACTIVE=$(systemctl is-active crowdsec 2>/dev/null)
if [ "$CS_ACTIVE" = "active" ]; then
  BC=$(cscli decisions list -o raw 2>/dev/null | grep -c "," || echo 0)
  CS_LINE="  ${Y}CrowdSec:${X} ${G}● ACTIVE${X} | bans: ${W}${BC}${X}"
else
  CS_LINE="  ${Y}CrowdSec:${X} ${R}✗ INACTIVE${X}"
fi
echo -e "${C}${LINE}${X}"
echo -e "  ${C}🌐  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%${X}"
echo -e "$CS_LINE"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}SCAN & SECURITY           SERVER                    WORDPRESS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}antivir${X}(ClamAV scan)      ${G}sos${X}(errors now)           ${G}wpupd${X}(WP update)"
echo -e "  ${G}fight${X}(block bots)         ${G}sos3${X}(last 3h)             ${G}wpcron${X}(WP cron)"
echo -e "  ${G}banlog${X}(ban list)          ${G}sos24${X}(last 24h)           ${G}wphealth${X}(WP health)"
echo -e "  ${G}cleanup${X}(disk clean)       ${G}watchdog${X}(PHP-FPM)         ${G}domains${X}(domain list)"
echo -e "  ${G}banunblock${X}(unban IP)      ${G}backup${X}(system backup)     ${G}mailclean${X}(mail queue)"
echo -e "  ${G}banblock${X}(manual ban)"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}GIT                       TOOLS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}save${X}(git push)            ${G}infooo${X}(full info)          ${G}aws-test${X}(S3 test)"
echo -e "  ${G}load${X}(git pull)            ${G}bot${X}(cryptobot status)     ${G}nginx-reload${X}(reload)"
echo -e "  ${G}repo${X}(go to repo)          ${G}fpm-reload${X}(reload FPM)    ${G}reload-all${X}(both)"
echo -e "  ${G}secret${X}(private repo)      ${G}mc${X}(Midnight Cmdr)         ${G}00${X}(clear screen)"
echo -e "${C}${LINE}${X}"
echo -e "  FastPanel+CF | Ubuntu 24 | ${Y}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
echo ""
MOTDEOF
chmod +x /etc/profile.d/motd_banner.sh

# ---- MOTD for WEB server 109 (fast-panel) ----------------------------------------------------
elif [ "$SERVER_TYPE" = "fast-panel" ]; then
cat > /etc/profile.d/motd_banner.sh << 'MOTDEOF'
#!/bin/bash
[ -n "$SSH_CONNECTION" ] || return 0
shopt -q login_shell 2>/dev/null || return 0
clear
HN=$(hostname)
IP=$(hostname -I | awk '{print $1}')
RAM_USED=$(free -m | awk '/Mem:/{print $3}')
RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
UPTIME=$(uptime -p | sed 's/up //')
LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)
C='\033[01;96m'; G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'
LINE='════════════════════════════════════════════════════════════════════════════════'
XRAY_TOTAL=$(grep -c '"tag"' /usr/local/etc/xray/config.json 2>/dev/null || echo 0)
XRAY_ENABLED=$(systemctl is-active xray 2>/dev/null | grep -c 'active' || echo 0)
XRAY_LINE="  ${Y}Xray:${X} ${G}${XRAY_ENABLED} enabled${X} / ${W}${XRAY_TOTAL} total${X}"
CS_ACTIVE=$(systemctl is-active crowdsec 2>/dev/null)
FW_ACTIVE=$(systemctl is-active crowdsec-firewall-bouncer 2>/dev/null)
if [ "$CS_ACTIVE" = "active" ]; then
  CS_LINE="  CrowdSec Engine: ${G}● ACTIVE${X}  Firewall: $([ "$FW_ACTIVE" = 'active' ] && echo "${G}● ACTIVE${X}" || echo "${R}✗ INACTIVE${X}")"
else
  CS_LINE="  CrowdSec Engine: ${R}✗ INACTIVE${X}"
fi
echo -e "${C}${LINE}${X}"
echo -e "  ${C}🖥  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%${X}"
echo -e "$XRAY_LINE  $CS_LINE"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}SCAN & SECURITY           SERVER                    WORDPRESS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}antivir${X}(ClamAV scan)      ${G}sos${X}(errors now)           ${G}wpupd${X}(WP update)"
echo -e "  ${G}fight${X}(block bots)         ${G}sos3${X}(last 3h)             ${G}wpcron${X}(WP cron)"
echo -e "  ${G}banlog${X}(ban list)          ${G}sos24${X}(last 24h)           ${G}wphealth${X}(WP health)"
echo -e "  ${G}cleanup${X}(disk clean)       ${G}watchdog${X}(PHP-FPM)         ${G}domains${X}(domain list)"
echo -e "  ${G}banunblock${X}(unban IP)      ${G}backup${X}(system backup)     ${G}mailclean${X}(mail queue)"
echo -e "  ${G}banblock${X}(manual ban)"
echo -e "${C}${LINE}${X}"
echo -e "  ${Y}GIT                       TOOLS${X}"
echo -e "${C}${LINE}${X}"
echo -e "  ${G}save${X}(git push)            ${G}infooo${X}(full info)          ${G}aws-test${X}(S3 test)"
echo -e "  ${G}load${X}(git pull)            ${G}aw${X}(VPN stats)             ${G}nginx-reload${X}(reload)"
echo -e "  ${G}repo${X}(pull public repo)    ${G}fpm-reload${X}(reload FPM)    ${G}reload-all${X}(both)"
echo -e "  ${G}secret${X}(private repo)      ${G}mc${X}(Midnight Cmdr)         ${G}00${X}(clear screen)"
echo -e "${C}${LINE}${X}"
echo -e "  FastPanel | Ubuntu 24 | ${Y}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
echo ""
MOTDEOF
chmod +x /etc/profile.d/motd_banner.sh

# ---- MOTD for VPN nodes ----------------------------------------------------------------------
else
printf '%s\n' \
'#!/bin/bash' \
'[ -n "$SSH_CONNECTION" ] || return 0' \
'shopt -q login_shell 2>/dev/null || return 0' \
'clear' \
'HN=$(hostname);IP=$(hostname -I | awk "{print \$1}");RAM_USED=$(free -m | awk "/Mem:/{print \$3}");RAM_TOTAL=$(free -m | awk "/Mem:/{print \$2}");CPU=$(top -bn1 | grep "Cpu(s)" | awk "{print int(\$2+\$4)}");UPTIME=$(uptime -p | sed "s/up //");LOAD=$(awk "{print \$1\" \"\$2\" \"\$3}" /proc/loadavg)' \
"C='\033[01;96m';G='\033[1;32m';Y='\033[1;33m';W='\033[1;37m';R='\033[1;31m';X='\033[0m'" \
"LINE='\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501'" \
'systemctl is-active --quiet xray 2>/dev/null && XRAY_LINE="  ${Y}Xray VPN:${X} ${G}\u25cf ACTIVE${X}" || XRAY_LINE=""' \
'AWG_LINE=""' \
'if docker exec amnezia-awg wg show wg0 dump &>/dev/null 2>&1;then PT=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l);PO=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | awk -v t="$(date +%s)" "\$5>0 && (t-\$5)<180 {c++} END{print c+0}");[[ -z "$PT" ]] && PT=0;[[ -z "$PO" ]] && PO=0;AWG_LINE="  ${Y}AmneziaWG:${X} ${G}${PO} online${X} / ${W}${PT} total peers${X}";fi' \
'if systemctl is-active --quiet crowdsec 2>/dev/null;then BC=$(cscli decisions list -o raw 2>/dev/null | grep -c "," || echo 0);CS_LINE="  ${Y}CrowdSec:${X} ${G}\u25cf ACTIVE${X} | bans: ${W}${BC}${X}";else CS_LINE="  ${Y}CrowdSec:${X} ${R}\u2717 INACTIVE${X}";fi' \
'svc_dot(){ systemctl is-active --quiet "$1" 2>/dev/null && echo "${G}\u25cf${X}" || echo "${R}\u2717${X}"; }' \
'SERVICES_LINE="  ${Y}Services:${X}  $(svc_dot crowdsec) crowdsec  $(svc_dot fail2ban) fail2ban  $(svc_dot smbd) smbd"' \
'echo -e "${C}${LINE}${X}"' \
'echo -e "  ${C}\U0001f512  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%%${X}"' \
'[ -n "$XRAY_LINE" ] && echo -e "$XRAY_LINE"' \
'[ -n "$AWG_LINE" ] && echo -e "$AWG_LINE"' \
'echo -e "$CS_LINE"' \
'echo -e "$SERVICES_LINE"' \
'echo -e "${C}${LINE}${X}"' \
'echo -e "  ${Y}VPN MANAGEMENT            SERVER                    GIT${X}"' \
'echo -e "${C}${LINE}${X}"' \
'echo -e "  ${G}antivir${X}(ClamAV scan)     ${G}sos${X}(audit 1h)           ${G}load${X}(git pull)"' \
'echo -e "  ${G}infooo${X}(server info)      ${G}sos3${X}(audit 3h)          ${G}00${X}(clear screen)"' \
'echo -e "  ${G}upd${X}(apt upgrade+reboot)  ${G}sos24${X}(audit 24h)        ${G}save${X}(git push)"' \
'echo -e "${C}${LINE}${X}"' \
'echo -e "  ${Y}Ubuntu 24${X} | ${Y}VPN Node${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"' \
'echo ""' > /etc/profile.d/motd_banner.sh
chmod +x /etc/profile.d/motd_banner.sh
fi

# --- MIDNIGHT COMMANDER USER MENU OPTIMIZATION (F2) -------------------------------------------
MC_DIR="/root/.config/mc"
mkdir -p "$MC_DIR"
MC_MENU="$MC_DIR/mc.menu"
[ -f "/root/.mc.menu" ] && rm -f "/root/.mc.menu"

printf '%s\n' \
'# Midnight Commander F2 User Menu' \
'' \
'0   00 — Clear screen' \
'    clear' \
'' \
'i   infooo — Server Info' \
'    /usr/local/bin/infooo' \
'' \
'a   antivir — ClamAV antivirus scan' \
"    bash $SCRIPTS/scan_clamav.sh" \
'' \
'1   sos — Server Audit (1h)' \
'    /usr/local/bin/sos 1h' \
'' \
'3   sos3 — Server Audit (3h)' \
'    /usr/local/bin/sos 3h' \
'' \
'4   sos24 — Server Audit (24h)' \
'    /usr/local/bin/sos 24h' \
'' \
'5   sos120 — Server Audit (120h)' \
'    /usr/local/bin/sos 120h' \
'' \
'u   upd — apt upgrade + cleanup + reboot' \
"    bash $SCRIPTS/upd.sh" \
'' \
'l   load — Git pull' \
'    /usr/local/bin/load' > "$MC_MENU"

if [ "$SERVER_TYPE" = "fast-panel+cloudflare" ]; then
    printf '%s\n' \
    '' \
    's   save — Git push to GitHub' \
    "    cd $REPO && git add -A && git commit -m \"save: \$(hostname) \$(date +%Y-%m-%d_%H:%M)\" && git push origin main && echo \"=== Saved ===\"" >> "$MC_MENU"
fi

[ -f "$MC_DIR/ini" ] && sed -i 's/auto_save_setup=true/auto_save_setup=false/' "$MC_DIR/ini"

# --- SHELL GLOBAL RE-INDEXING ------------------------------------------------------------------
source "$BASHRC" 2>/dev/null

# ===============================================================================================
# INSTALLATION COMPLETE — DETAILED REPORT
# ===============================================================================================
echo -e ""
echo -e "${CYAN}${LINE}${RESET}"
echo -e "${GREEN}  ✅  SETUP COMPLETE — INSTALLATION REPORT${RESET}"
echo -e "${CYAN}${LINE}${RESET}"
echo -e ""
echo -e "  ${YELLOW}► SERVER IDENTITY${RESET}"
echo -e "    Hostname     : ${WHITE}$SERVER_NAME${RESET}"
echo -e "    IP Address   : ${WHITE}$SERVER_IP${RESET}"
echo -e "    Profile      : ${WHITE}$SERVER_TYPE${RESET}"
if [ "$(hostname)" = "$SERVER_NAME" ]; then
    echo -e "    Hostname OK  : ${GREEN}✔ Applied and verified ($(hostname))${RESET}"
else
    echo -e "    Hostname     : ${YELLOW}⚠ May require re-login to reflect in prompt${RESET}"
fi
echo -e ""
echo -e "  ${YELLOW}► SYSTEM${RESET}"
echo -e "    Timezone     : ${GREEN}$TZ_SET${RESET}  (Prague / Europe / UTC+1/+2)"
echo -e "    NTP Sync     : ${GREEN}systemd-timesyncd restarted${RESET}"
echo -e "    Current Time : ${WHITE}$(date '+%Y-%m-%d %H:%M:%S %Z')${RESET}"
echo -e ""
echo -e "  ${YELLOW}► AUTO-MAINTENANCE CRON (daily 03:00 Prague time)${RESET}"
echo -e "    ${GREEN}✔${RESET} apt-get update"
echo -e "    ${GREEN}✔${RESET} apt-get upgrade -y  (non-interactive, no prompts)"
echo -e "    ${GREEN}✔${RESET} apt-get autoremove -y  (disk cleanup)"
echo -e "    ${GREEN}✔${RESET} /sbin/reboot  (auto-reboot after update)"
echo -e "    Log file     : /var/log/auto-upgrade.log"
echo -e ""
echo -e "  ${YELLOW}► INSTALLED GLOBAL COMMANDS${RESET}"
[ "$SOS_STATUS" != "NOT FOUND" ] && \
    echo -e "    ${GREEN}✔${RESET} sos        — server audit log viewer    [$SOS_STATUS]" || \
    echo -e "    ${RED}✗${RESET} sos        — script not found in repo"
[ "$INFOOO_STATUS" != "NOT FOUND" ] && \
    echo -e "    ${GREEN}✔${RESET} infooo     — full server info panel     [$INFOOO_STATUS]" || \
    echo -e "    ${RED}✗${RESET} infooo     — script not found in repo"
echo -e "    ${GREEN}✔${RESET} load       — git pull only                [/usr/local/bin/load]"
echo -e ""
echo -e "  ${YELLOW}► ALIASES — ALL PROFILES (1/2/3)${RESET}"
echo -e "    ${GREEN}00 / cls / c${RESET}              — clear screen"
echo -e "    ${GREEN}sos / sos1 / sos3 / sos24 / sos120${RESET}  — server audit (time window)"
echo -e "    ${GREEN}infooo${RESET}                    — full server info"
echo -e "    ${GREEN}load${RESET}                      — git pull only"
echo -e "    ${GREEN}antivir${RESET}                   — ClamAV scan (all profiles)"
echo -e "    ${GREEN}upd${RESET}                       — apt upgrade + cleanup + reboot"
if [ "$SERVER_TYPE" = "fast-panel+cloudflare" ]; then
echo -e ""
echo -e "  ${YELLOW}► ALIASES — FastPanel+CF specific${RESET}"
echo -e "    ${GREEN}save${RESET}                      — git add + commit + push"
echo -e "    ${GREEN}+ shared_aliases_222.sh${RESET}  — full web server alias set"
elif [ "$SERVER_TYPE" = "fast-panel" ]; then
echo -e ""
echo -e "  ${YELLOW}► ALIASES — FastPanel specific${RESET}"
echo -e "    ${GREEN}+ shared_aliases_109.sh${RESET}  — full web server alias set"
else
echo -e ""
echo -e "  ${YELLOW}► ALIASES — VPN profile${RESET}"
echo -e "    ${GREEN}(only global aliases above — no extra VPN-specific aliases)${RESET}"
fi
echo -e ""
echo -e "  ${YELLOW}► TERMINAL PROMPT COLOR${RESET}"
echo -e "    PS1 color    : ${WHITE}$PS1_NAME${RESET}  (affects ~/.bashrc + ~/.bash_profile)"
echo -e ""
echo -e "  ${YELLOW}► MIDNIGHT COMMANDER (F2 menu)${RESET}"
echo -e "    Config       : ${WHITE}$MC_MENU${RESET}"
echo -e "    ${GREEN}0${RESET} — clear screen"
echo -e "    ${GREEN}i${RESET} — infooo (server info)"
echo -e "    ${GREEN}a${RESET} — antivir (ClamAV scan)"
echo -e "    ${GREEN}1/3/4/5${RESET} — sos 1h / 3h / 24h / 120h"
echo -e "    ${GREEN}u${RESET} — upd (apt upgrade + cleanup + reboot)"
echo -e "    ${GREEN}l${RESET} — load (git pull)"
[ "$SERVER_TYPE" = "fast-panel+cloudflare" ] && echo -e "    ${GREEN}s${RESET} — save (git push)"
echo -e ""
echo -e "  ${YELLOW}► MOTD (SSH login banner)${RESET}"
echo -e "    File         : /etc/profile.d/motd_banner.sh"
echo -e "    Shows        : hostname, IP, RAM, CPU, uptime, load, security status"
echo -e "    Triggers     : on SSH login (new session only)"
echo -e ""
echo -e "  ${YELLOW}► REPO${RESET}"
echo -e "    Local clone  : $REPO"
echo -e "    Scripts      : $SCRIPTS"
echo -e ""
echo -e "  ${CYAN}⚠  Open a NEW SSH session to activate MOTD and aliases.${RESET}"
echo -e "  ${CYAN}   Or run: source ~/.bashrc${RESET}"
echo -e "${CYAN}${LINE}${RESET}"
echo -e ""

# = Rooted by VladiMIR | AI = v2026-06-10 = github.com/GinCz/Linux_Server_Public
