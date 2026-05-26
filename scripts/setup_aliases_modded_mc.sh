#!/bin/bash
clear

# ===============================================================================================
# SYSTEM SETUP SCRIPT | v2026.05.26
# Automated Environment & Environment Customization Tool
# = Rooted by VladiMIR + AI | v.2026.05.26 | github.com/GinCz =
# ===============================================================================================

# --- COLOR PALETTE (Universal ANSI Codes) ------------------------------------------------------
CYAN='\033[01;96m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
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
SERVER_NAME=$(hostname)
SERVER_IP=$(hostname -I | awk '{print $1}')

echo -e "${YELLOW}  [1/7] Validating network parameters and hostname...${RESET}"
echo -e "        Hostname  : ${GREEN}$SERVER_NAME${RESET}"
echo -e "        Server IP : ${GREEN}$SERVER_IP${RESET}"

# --- GIT REPOSITORY INTEGRATION ----------------------------------------------------------------
echo -e "${YELLOW}  [2/7] Checking local script repository...${RESET}"
if [ ! -d "$REPO/.git" ]; then
    echo -e "        Repository not found. Cloning from GitHub..."
    cd /root && git clone "$REPO_URL"
else
    echo -e "        ${GREEN}Local repository replica exists. Skipping clone.${RESET}"
fi

# --- SERVER TYPE IDENTIFICATION ----------------------------------------------------------------
case "$SERVER_IP" in
    152.53.182.222)  SERVER_TYPE="fast-panel+cloudflare" ;;
    212.109.223.109) SERVER_TYPE="fast-panel" ;;
    *)               SERVER_TYPE="vpn" ;;
esac
echo -e "        Detected Profile: ${GREEN}$SERVER_TYPE${RESET}"

# --- INTERACTIVE PS1 COLOR SELECTION -----------------------------------------------------------
echo -e "${CYAN}${LINE}${RESET}"
echo -e "  Select prompt color scheme (PS1):"
echo -e "  1) \e[01;33mYELLOW\e[0m  2) \e[38;5;217mLIGHT PINK\e[0m  3) \e[38;5;87mTURQUOISE\e[0m  4) \e[01;32mGREEN\e[0m  5) \e[38;5;214mORANGE\e[0m"
read -p "  Choose number [1-5]: " C

case $C in
    1) PS1_COLOR='\[\033[01;33m\]'; PS1_RESET='\[\033[00m\]'; BC='\033[01;33m';;
    2) PS1_COLOR='\[\e[38;5;217m\]'; PS1_RESET='\[\e[m\]'; BC='\e[38;5;217m';;
    3) PS1_COLOR='\[\e[38;5;87m\]';  PS1_RESET='\[\e[m\]'; BC='\e[38;5;87m';;
    4) PS1_COLOR='\[\033[01;32m\]'; PS1_RESET='\[\033[00m\]'; BC='\033[01;32m';;
    5) PS1_COLOR='\[\e[38;5;214m\]'; PS1_RESET='\[\e[m\]'; BC='\e[38;5;214m';;
    *) PS1_COLOR=''; PS1_RESET=''; BC='\033[01;96m';;
esac

echo -e "${YELLOW}  [3/7] Configuring command line prompt...${RESET}"
if [ -n "$PS1_COLOR" ]; then
    sed -i '/export PS1=/d' "$BASHRC"
    sed -i '/export PS1=/d' "$BASH_PROFILE" 2>/dev/null
    echo "export PS1=\"${PS1_COLOR}\\u@\\h:\\w\\$ ${PS1_RESET}\"" >> "$BASHRC"
    echo "export PS1=\"${PS1_COLOR}\\u@\\h:\\w\\$ ${PS1_RESET}\"" >> "$BASH_PROFILE"
    echo -e "        ${GREEN}Color configuration injected into profile configurations.${RESET}"
fi

# --- SOS MONITOR INSTALLATION ------------------------------------------------------------------
if [ -f "$SCRIPTS/sos.sh" ]; then
    cp "$SCRIPTS/sos.sh" /usr/local/bin/sos
    chmod +x /usr/local/bin/sos
    echo -e "        ${GREEN}sos monitor installed: /usr/local/bin/sos${RESET}"
fi

# --- PURGE LEGACY MARKERS & WRITE ALIASES -----------------------------------------------------
echo -e "${YELLOW}  [4/7] Updating environment alias definitions...${RESET}"
MARKER="# === Linux_Server_Public aliases ==="
for P in 'Rooted by VladiMIR' 'v2026-05-0' '# ~/.bashrc — VPN' 'VPN NODE FULL INSTALL'; do
    sed -i "/${P}/d" "$BASHRC" 2>/dev/null
    sed -i "/${P}/d" "$BASH_PROFILE" 2>/dev/null
done
grep -q "$MARKER" "$BASHRC" 2>/dev/null && sed -i "/^${MARKER}/,\$d" "$BASHRC"

echo "" >> "$BASHRC"
echo "$MARKER" >> "$BASHRC"

# Global system aliases
printf '%s\n' \
"alias 00='clear'" \
"alias sos='/usr/local/bin/sos 1h'" \
"alias sos1='/usr/local/bin/sos 1h'" \
"alias sos3='/usr/local/bin/sos 3h'" \
"alias sos24='/usr/local/bin/sos 24h'" \
"alias sos120='/usr/local/bin/sos 120h'" \
"alias infooo='bash $SCRIPTS/infooo.sh'" \
"alias load='cd $REPO && git pull origin main --no-rebase --no-edit && sed -i \"/# === Linux_Server_Public aliases ===/,\\\$d\" ~/.bashrc && bash $SCRIPTS/setup_aliases_modded_mc.sh && source ~/.bashrc && echo \"=== Loaded ===\"'" >> "$BASHRC"

# Dynamic split for target configurations
if [ "$SERVER_TYPE" = "fast-panel+cloudflare" ]; then
    echo "source $SCRIPTS/shared_aliases_222.sh" >> "$BASHRC"
    echo "alias save='cd $REPO && git add -A && (git diff --cached --quiet && echo \"Nothing to commit\" || git commit -m \"save: \$(hostname) \$(date +%Y-%m-%d_%H:%M)\") && git push origin main && echo \"=== Saved ===\"'" >> "$BASHRC"
elif [ "$SERVER_TYPE" = "fast-panel" ]; then
    echo "source $SCRIPTS/shared_aliases_109.sh" >> "$BASHRC"
else
    # Dedicated network block for standalone VPN servers
    printf '%s\n' \
    "alias ports='ss -tlnp'" \
    "alias myip='curl -s ifconfig.me && echo'" \
    "alias ll='ls -lh --color=auto'" \
    "alias la='ls -Ah --color=auto'" \
    "alias df='df -h'" \
    "alias du='du -sh'" \
    "alias gs='git status'" \
    "alias gl='git log --oneline -10'" \
    "alias xray_log='journalctl -u xray -n 50 --no-pager 2>/dev/null'" \
    "alias xray_st='systemctl status xray 2>/dev/null'" \
    "alias amn_st='systemctl status amneziawg 2>/dev/null || docker ps | grep amnezia 2>/dev/null || echo \"AmneziaWG not found\"'" \
    "alias wg_st='wg show 2>/dev/null || echo \"WireGuard not active\"'" \
    "alias adg_st='systemctl status AdGuardHome 2>/dev/null || echo \"AdGuard not installed\"'" \
    "alias banlist='cscli decisions list 2>/dev/null || echo \"CrowdSec not installed\"'" \
    "alias banlog='cscli decisions list 2>/dev/null || echo \"CrowdSec not installed\"'" \
    "alias banblock='cscli decisions add --ip'" \
    "alias backup='bash $SCRIPTS/xray_backup_node.sh 2>/dev/null || echo \"backup script not found\"'" \
    "alias antivir='bash $SCRIPTS/scan_clamav.sh 2>/dev/null || echo \"ClamAV script not found\"'" \
    "alias mc='MC_SKIN=default mc'" >> "$BASHRC"
fi

# --- FIX /etc/bash.bashrc — REPAIR BROKEN SYSTEM ALIASES BLOCK --------------------------------
echo -e "${YELLOW}  [5/7] Repairing /etc/bash.bashrc system aliases block...${RESET}"
BASHRC_SYS="/etc/bash.bashrc"
sed -i '/# === USER ALIASES BLOCK ===/,/# === END USER ALIASES BLOCK ===/d' "$BASHRC_SYS" 2>/dev/null

cat >> "$BASHRC_SYS" << 'SYSEOF'
# === USER ALIASES BLOCK ===
# = Rooted by VladiMIR + AI | v.2026.05.26 =
alias 00='clear'
alias mod='/usr/local/bin/mod'
alias cls='clear'
alias c='clear'
alias ls='ls --color=auto'
alias ll='ls -alF --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
export MC_COLOR_TABLE='_default_=lightgray,blue:marked=yellow,blue:errors=white,red:menu=black,lightgray:menusel=white,blue:menuhot=red,lightgray:menuhotsel=red,blue:dnormal=lightgray,blue:dfocus=white,cyan:dhotnormal=red,blue:dhotfocus=red,cyan:execute=lightgreen,blue:directory=white,blue:link=cyan,blue:device=brightmagenta,blue:special=lightgray,blue:core=red,blue:stalelink=red,blue'
# === END USER ALIASES BLOCK ===
SYSEOF

echo -e "        ${GREEN}/etc/bash.bashrc aliases block repaired.${RESET}"

# --- DYNAMIC SSH WELCOME BANNER GENERATION (MOTD) ---------------------------------------------
echo -e "${YELLOW}  [6/7] Building dynamic MOTD framework...${RESET}"
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
echo -e "  ${C}🖥  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%${X}"
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
echo -e "  FastPanel | Ubuntu 24 | ${Y}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
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
'systemctl is-active --quiet xray 2>/dev/null && XRAY_LINE="  ${Y}Xray VPN:${X} ${G}● ACTIVE${X}" || XRAY_LINE=""' \
'AWG_LINE=""' \
'if docker exec amnezia-awg wg show wg0 dump &>/dev/null 2>&1;then PT=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l);PO=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | awk -v t="$(date +%s)" "\$5>0 && (t-\$5)<180 {c++} END{print c+0}");[[ -z "$PT" ]] && PT=0;[[ -z "$PO" ]] && PO=0;AWG_LINE="  ${Y}AmneziaWG:${X} ${G}${PO} online${X} / ${W}${PT} total peers${X}";fi' \
'if systemctl is-active --quiet crowdsec 2>/dev/null;then BC=$(cscli decisions list -o raw 2>/dev/null | grep -c "," || echo 0);CS_LINE="  ${Y}CrowdSec:${X} ${G}● ACTIVE${X} | bans: ${W}${BC}${X}";else CS_LINE="  ${Y}CrowdSec:${X} ${R}✗ INACTIVE${X}";fi' \
'echo -e "${C}${LINE}${X}"' \
'echo -e "  ${C}🔒  ${W}${HN}${X}  ${Y}${IP}${X}  RAM:${W}${RAM_USED}/${RAM_TOTAL}MB${X}  CPU:${W}${CPU}%%${X}"' \
'[ -n "$XRAY_LINE" ] && echo -e "$XRAY_LINE"' \
'[ -n "$AWG_LINE" ] && echo -e "$AWG_LINE"' \
'echo -e "$CS_LINE"' \
'echo -e "${C}${LINE}${X}"' \
'echo -e "  ${Y}VPN MANAGEMENT            SERVER                    GIT${X}"' \
'echo -e "${C}${LINE}${X}"' \
'echo -e "  ${G}banlog${X}(ban list)         ${G}sos${X}(audit 1h)           ${G}save${X}(git push)"' \
'echo -e "  ${G}banblock${X}(ban IP)         ${G}sos3${X}(audit 3h)          ${G}load${X}(git pull+deploy)"' \
'echo -e "  ${G}antivir${X}(ClamAV scan)     ${G}sos24${X}(audit 24h)        ${G}mc${X}(Midnight Cmdr)"' \
'echo -e "  ${G}backup${X}(VPN configs)      ${G}infooo${X}(server info)     ${G}00${X}(clear screen)"' \
'echo -e "${C}${LINE}${X}"' \
'echo -e "  ${Y}Ubuntu 24${X} | ${Y}VPN Node${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"' \
'echo ""' > /etc/profile.d/motd_banner.sh
chmod +x /etc/profile.d/motd_banner.sh
fi

# --- MIDNIGHT COMMANDER USER MENU OPTIMIZATION (F2) -------------------------------------------
echo -e "${YELLOW}  [7/7] Generating Midnight Commander layout (F2 menu)...${RESET}"
MC_DIR="/root/.config/mc"
mkdir -p "$MC_DIR"
MC_MENU="$MC_DIR/mc.menu"
[ -f "/root/.mc.menu" ] && rm -f "/root/.mc.menu"

# Base common blueprint for MC user workspace
printf '%s\n' \
'# Midnight Commander F2 User Menu' \
'' \
'0   00 — Clear screen' \
'    clear' \
'' \
'i   infooo — Server Info' \
"    bash $SCRIPTS/infooo.sh" \
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
'l   load — Git pull + deploy' \
"    cd $REPO && git pull origin main --no-rebase --no-edit && bash $SCRIPTS/setup_aliases_modded_mc.sh && source ~/.bashrc && echo \"=== Loaded ===\"" > "$MC_MENU"

# Inject save macro exclusively into the primary management target
if [ "$SERVER_TYPE" = "fast-panel+cloudflare" ]; then
    printf '%s\n' \
    '' \
    's   save — Git push to GitHub' \
    "    cd $REPO && git add -A && git commit -m \"save: \$(hostname) \$(date +%Y-%m-%d_%H:%M)\" && git push origin main && echo \"=== Saved ===\"" >> "$MC_MENU"
fi

# Append active firewall security nodes exclusively to VPN infrastructure profiles
if [ "$SERVER_TYPE" = "vpn" ]; then
    printf '%s\n' \
    '' \
    'b   banlog — CrowdSec Ban List' \
    '    cscli decisions list 2>/dev/null' \
    '' \
    'B   banblock — CrowdSec ban IP' \
    '    read -p "Enter IP to block: " BIP && cscli decisions add --ip $BIP' \
    '' \
    'k   backup — Backup VPN configs' \
    "    bash $SCRIPTS/xray_backup_node.sh" >> "$MC_MENU"
fi

# MC persistent structural state configuration
[ -f "$MC_DIR/ini" ] && sed -i 's/auto_save_setup=true/auto_save_setup=false/' "$MC_DIR/ini"

# --- SHELL GLOBAL RE-INDEXING ------------------------------------------------------------------
source "$BASHRC" 2>/dev/null

echo -e "${CYAN}${LINE}${RESET}"
echo -e "${GREEN}  CONFIGURATION DEPLOYMENT COMPLETE!${RESET}"
echo -e "  Node identity: ${YELLOW}$SERVER_NAME${RESET} | Profile: ${YELLOW}$SERVER_TYPE${RESET} | Active IP: ${YELLOW}$SERVER_IP${RESET}"
echo -e "  Establish a new SSH terminal session to load the updated MOTD visualizer."
echo -e "${CYAN}${LINE}${RESET}"

# = Rooted by VladiMIR + AI | v.2026.05.26 | github.com/GinCz =
