#!/bin/bash
clear
# ==========================================================================================
# Script:      setup_aliases_modded_mc.sh
# Version:     v2026.05.22b
# Location:    scripts/setup_aliases_modded_mc.sh
# Repository:  https://github.com/GinCz/Linux_Server_Public
# Server:      ALL (222-DE-NetCup | 109-RU-FastVDS | VPN nodes | any clean server)
# One-liner (works on ANY server without pre-cloning):
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/setup_aliases_modded_mc.sh)
# Or after git clone/pull:
#   bash /root/Linux_Server_Public/scripts/setup_aliases_modded_mc.sh
# ==========================================================================================
# Description:
#   1) Clone or pull repo (git)
#   2) Choose PS1 color (5 options, interactive)
#   3) Set PS1 in .bashrc + .bash_profile
#   4) Install sos to /usr/local/bin/sos
#   5) Add/UPDATE aliases to ~/.bashrc (always replaces old block — no duplicates)
#   6) Create MOTD: /etc/profile.d/motd_banner.sh (SSH login only, removes ALL old motd_*.sh)
#   7) Create Midnight Commander F2 user menu
# ==========================================================================================
# SAFE: Does NOT run apt, does NOT touch UFW, does NOT install CrowdSec.
# IDEMPOTENT: Safe to run multiple times — always replaces, never duplicates.
# = Rooted by VladiMIR + AI | v2026.05.22b | github.com/GinCz =
# ==========================================================================================

REPO_URL="https://github.com/GinCz/Linux_Server_Public.git"
REPO="/root/Linux_Server_Public"
SCRIPTS="$REPO/scripts"

SERVER_NAME=$(hostname)
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "=========================================================================================="
echo "  SETUP: $SERVER_NAME  [$SERVER_IP]"
echo "=========================================================================================="
echo ""

# ==========================================================================================
# STEP 0: Clone or pull repo
# ==========================================================================================
echo "=========================================="
echo " [0/6] REPO"
echo "=========================================="
if [ -d "$REPO/.git" ]; then
    echo "Pulling latest..."
    cd "$REPO" && git pull origin main --no-rebase --no-edit
else
    echo "Cloning repo..."
    cd /root && git clone "$REPO_URL"
fi
echo ""

# --- Detect server type by IP ---
case "$SERVER_IP" in
    152.53.182.222)  SERVER_TYPE="222" ;;
    212.109.223.109) SERVER_TYPE="109" ;;
    *)               SERVER_TYPE="vpn" ;;
esac
echo "Server type detected: $SERVER_TYPE"
echo ""

# ==========================================================================================
# STEP 1: Color picker + PS1
# ==========================================================================================
echo "=========================================="
echo " [1/6] COLOR PICKER"
echo "=========================================="
echo ""
echo -e "  Pick banner color:"
echo -e "  1) \e[01;33mYELLOW\e[0m  2) \e[38;5;217mLIGHT PINK\e[0m  3) \e[38;5;87mTURQUOISE\e[0m  4) \e[01;32mGREEN\e[0m  5) \e[38;5;214mORANGE\e[0m"
echo ""
read -p "  Choose [1-5]: " C

case $C in
  1) PS1_COLOR='\[\033[01;33m\]' ; PS1_RESET='\[\033[00m\]' ; COLOR_NAME='YELLOW'       ; BC='\033[01;33m' ;;
  2) PS1_COLOR='\[\e[38;5;217m\]'; PS1_RESET='\[\e[m\]'     ; COLOR_NAME='LIGHT PINK'   ; BC='\e[38;5;217m' ;;
  3) PS1_COLOR='\[\e[38;5;87m\]' ; PS1_RESET='\[\e[m\]'     ; COLOR_NAME='TURQUOISE'    ; BC='\e[38;5;87m' ;;
  4) PS1_COLOR='\[\033[01;32m\]' ; PS1_RESET='\[\033[00m\]' ; COLOR_NAME='BRIGHT GREEN' ; BC='\033[01;32m' ;;
  5) PS1_COLOR='\[\e[38;5;214m\]'; PS1_RESET='\[\e[m\]'     ; COLOR_NAME='ORANGE'       ; BC='\e[38;5;214m' ;;
  *) echo "Wrong choice, skipping color"; PS1_COLOR=''; PS1_RESET=''; COLOR_NAME='DEFAULT'; BC='\033[0m' ;;
esac

if [ -n "$PS1_COLOR" ]; then
    sed -i '/export PS1=/d' /root/.bashrc
    echo "export PS1=\"${PS1_COLOR}\\u@\\h:\\w\\$ ${PS1_RESET}\"" >> /root/.bashrc
    sed -i '/export PS1=/d' /root/.bash_profile 2>/dev/null
    echo "export PS1=\"${PS1_COLOR}\\u@\\h:\\w\\$ ${PS1_RESET}\"" >> /root/.bash_profile
    echo "OK: PS1 set to $COLOR_NAME"
fi
echo ""

# ==========================================================================================
# STEP 2: Install sos
# ==========================================================================================
echo "=========================================="
echo " [2/6] SOS"
echo "=========================================="
if [ -f "$SCRIPTS/sos.sh" ]; then
    cp "$SCRIPTS/sos.sh" /usr/local/bin/sos
    chmod +x /usr/local/bin/sos
    echo "OK: /usr/local/bin/sos installed"
elif [ -f "$SCRIPTS/sos-fastpanel.sh" ]; then
    cp "$SCRIPTS/sos-fastpanel.sh" /usr/local/bin/sos
    chmod +x /usr/local/bin/sos
    echo "OK: /usr/local/bin/sos installed (fastpanel)"
else
    echo "SKIP: sos not found in $SCRIPTS"
fi
echo ""

# ==========================================================================================
# STEP 3: Aliases — ALWAYS replace old block (idempotent, no duplicates)
# ==========================================================================================
echo "=========================================="
echo " [3/6] ALIASES"
echo "=========================================="
BASHRC="$HOME/.bashrc"
MARKER="# === Linux_Server_Public aliases ==="

# Remove old aliases block (from MARKER to end of file) if it exists
if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    sed -i "/^${MARKER}/,\$d" "$BASHRC"
    echo "INFO: old aliases block removed — writing fresh"
fi

echo "" >> "$BASHRC"
echo "$MARKER" >> "$BASHRC"

if [ "$SERVER_TYPE" = "222" ]; then
    echo "source $SCRIPTS/shared_aliases_222.sh" >> "$BASHRC"
    echo "OK: aliases added (222)"
elif [ "$SERVER_TYPE" = "109" ]; then
    echo "source $SCRIPTS/shared_aliases_109.sh" >> "$BASHRC"
    echo "OK: aliases added (109)"
else
    cat >> "$BASHRC" << 'ALIASEOF'
alias 00='clear'
alias sos='/usr/local/bin/sos 1h'
alias sos1='/usr/local/bin/sos 1h'
alias sos3='/usr/local/bin/sos 3h'
alias sos24='/usr/local/bin/sos 24h'
alias sos120='/usr/local/bin/sos 120h'
alias infooo='bash /root/Linux_Server_Public/scripts/infooo.sh'
alias ports='ss -tlnp'
alias save='cd /root/Linux_Server_Public && git add -A && (git diff --cached --quiet && echo "Nothing to commit" || git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)") && git pull origin main --no-rebase --no-edit && git push origin main && echo "=== Saved ==="'
alias load='cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit && sed -i "/# === Linux_Server_Public aliases ===/,\$d" ~/.bashrc && bash /root/Linux_Server_Public/scripts/setup_aliases_modded_mc.sh && source ~/.bashrc && echo "=== Loaded ==="'
alias xray_log='journalctl -u xray -n 50 --no-pager 2>/dev/null'
alias xray_st='systemctl status xray 2>/dev/null'
alias amn_st='systemctl status amneziawg 2>/dev/null || docker ps | grep amnezia 2>/dev/null || echo "AmneziaWG not found"'
alias wg_st='wg show 2>/dev/null || echo "WireGuard not active"'
alias adg_st='systemctl status AdGuardHome 2>/dev/null || echo "AdGuard not installed"'
alias banlist='cscli decisions list 2>/dev/null || echo "CrowdSec not installed"'
alias banlog='cscli decisions list 2>/dev/null || echo "CrowdSec not installed"'
alias banblock='cscli decisions add --ip'
alias backup='bash /root/Linux_Server_Public/scripts/xray_backup_node.sh 2>/dev/null || echo "backup script not found"'
alias antivir='bash /root/Linux_Server_Public/scripts/scan_clamav.sh 2>/dev/null || echo "ClamAV script not found"'
alias mc='MC_SKIN=default mc'
ALIASEOF
    echo "OK: aliases added (vpn/other)"
fi
echo ""

# ==========================================================================================
# STEP 4: MOTD — SSH-only banner (removes ALL old motd_*.sh — no duplicates ever)
# ==========================================================================================
echo "=========================================="
echo " [4/6] MOTD"
echo "=========================================="
# Remove ALL possible old MOTD files to prevent duplication
rm -f /etc/profile.d/motd_banner.sh
rm -f /etc/profile.d/motd_custom.sh
rm -f /etc/profile.d/motd_vpn.sh
rm -f /etc/profile.d/motd_*.sh
chmod -x /etc/update-motd.d/* 2>/dev/null
echo "INFO: old MOTD files removed"

cat > /etc/profile.d/motd_banner.sh << MOTD_SCRIPT
#!/bin/bash
# SSH-only MOTD banner — motd_banner.sh
# = Rooted by VladiMIR + AI | v2026.05.22b | github.com/GinCz =
[ -n "\$SSH_CONNECTION" ] || return 0
shopt -q login_shell 2>/dev/null || return 0
clear

SERVER_NAME=\$(hostname)
SERVER_IP=\$(hostname -I | awk '{print \$1}')
RAM_USED=\$(free -m | awk '/Mem:/{print \$3}')
RAM_TOTAL=\$(free -m | awk '/Mem:/{print \$2}')
CPU=\$(top -bn1 | grep 'Cpu(s)' | awk '{print int(\$2+\$4)}')
UPTIME=\$(uptime -p | sed 's/up //')
LOAD=\$(awk '{print \$1" "\$2" "\$3}' /proc/loadavg)

COLOR='${BC}'
RESET='\033[0m'
C='\033[01;96m'
G='\033[1;32m'
Y='\033[1;33m'
W='\033[1;37m'
R='\033[1;31m'
LINE='\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501'

# CrowdSec status
if systemctl is-active --quiet crowdsec 2>/dev/null; then
  BAN_COUNT=\$(cscli decisions list -o raw 2>/dev/null | grep -c ',' || echo 0)
  CS_LINE="  \${Y}CrowdSec:\${RESET} \${G}\u25cf ACTIVE\${RESET} | bans: \${W}\${BAN_COUNT}\${RESET}"
else
  CS_LINE="  \${Y}CrowdSec:\${RESET} \${R}\u2717 INACTIVE\${RESET}"
fi

# Xray status
if systemctl is-active --quiet xray 2>/dev/null; then
  XRAY_LINE="  \${Y}Xray VPN:\${RESET} \${G}\u25cf ACTIVE\${RESET}"
else
  XRAY_LINE=""
fi

# AmneziaWG status
AWG_LINE=""
if docker exec amnezia-awg wg show wg0 dump &>/dev/null 2>&1; then
  PEERS_TOTAL=\$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l)
  PEERS_ONLINE=\$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
    | awk -v t="\$(date +%s)" '\$5>0 && (t-\$5)<180 {c++} END{print c+0}')
  [[ -z "\$PEERS_TOTAL" ]]  && PEERS_TOTAL=0
  [[ -z "\$PEERS_ONLINE" ]] && PEERS_ONLINE=0
  AWG_LINE="  \${Y}AmneziaWG:\${RESET} \${G}\${PEERS_ONLINE} online\${RESET} / \${W}\${PEERS_TOTAL} total peers\${RESET}"
fi

echo -e "\${C}\${LINE}\${RESET}"
echo -e "  \${C}\U0001f512  \${W}\${SERVER_NAME}\${RESET}  \${Y}\${SERVER_IP}\${RESET}  RAM:\${W}\${RAM_USED}/\${RAM_TOTAL}MB\${RESET}  CPU:\${W}\${CPU}%%\${RESET}"
[ -n "\$XRAY_LINE" ] && echo -e "\${XRAY_LINE}"
[ -n "\$AWG_LINE"  ] && echo -e "\${AWG_LINE}"
echo -e "\${CS_LINE}"
echo -e "\${C}\${LINE}\${RESET}"
echo -e "  \${Y}VPN MANAGEMENT            SERVER                    GIT\${RESET}"
echo -e "\${C}\${LINE}\${RESET}"
echo -e "  \${G}banlog\${RESET}(ban list)         \${G}sos\${RESET}(audit 1h)           \${G}save\${RESET}(git push)"
echo -e "  \${G}banblock\${RESET}(ban IP)         \${G}sos3\${RESET}(audit 3h)          \${G}load\${RESET}(git pull+deploy)"
echo -e "  \${G}antivir\${RESET}(ClamAV scan)     \${G}sos24\${RESET}(audit 24h)        \${G}mc\${RESET}(Midnight Cmdr)"
echo -e "  \${G}backup\${RESET}(VPN configs)      \${G}infooo\${RESET}(server info)     \${G}00\${RESET}(clear screen)"
echo -e "\${C}\${LINE}\${RESET}"
echo -e "  \${Y}Ubuntu 24\${RESET} | \${Y}VPN Node\${RESET} | up \${W}\${UPTIME}\${RESET} | load: \${G}\${LOAD}\${RESET}"
echo ""
MOTD_SCRIPT

chmod +x /etc/profile.d/motd_banner.sh
echo "OK: MOTD installed — /etc/profile.d/motd_banner.sh (SSH-only)"
echo ""

# ==========================================================================================
# STEP 5: Midnight Commander F2 menu
# ==========================================================================================
echo "=========================================="
echo " [5/6] MC F2 MENU"
echo "=========================================="
MC_DIR="$HOME/.config/mc"
mkdir -p "$MC_DIR"
MC_MENU="$MC_DIR/mc.menu"

[ -f "$HOME/.mc.menu" ] && rm -f "$HOME/.mc.menu" && echo "FIXED: removed old ~/.mc.menu"

cat > "$MC_MENU" << MCEOF
# Midnight Commander F2 User Menu
# = Rooted by VladiMIR + AI | v2026.05.22b | github.com/GinCz =
# ==========================================================================================

i   infooo — server info
    bash $SCRIPTS/infooo.sh

s   sos — health monitor (1h)
    /usr/local/bin/sos 1h

a   antivirus ClamAV scan
    bash $SCRIPTS/scan_clamav.sh

g   git save — push to GitHub
    cd /root/Linux_Server_Public && git add -A && git commit -m "save: \$(hostname) \$(date +%Y-%m-%d_%H:%M)" && git push origin main && echo "=== Saved ==="

l   git load — pull from GitHub
    cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit && echo "=== Loaded ==="

x   xray status
    systemctl status xray

w   wireguard / amnezia status
    wg show 2>/dev/null || docker ps | grep amnezia

b   backup VPN configs
    bash $SCRIPTS/xray_backup_node.sh
MCEOF

MC_INI="$MC_DIR/ini"
[ -f "$MC_INI" ] && sed -i 's/auto_save_setup=true/auto_save_setup=false/' "$MC_INI"

echo "OK: MC F2 menu created — $MC_MENU"
echo ""

# ==========================================================================================
# STEP 6: Apply + Summary
# ==========================================================================================
echo "=========================================="
echo " [6/6] APPLY"
echo "=========================================="
source /root/.bashrc 2>/dev/null
echo ""
echo "=========================================================================================="
echo "  DONE! [ $SERVER_NAME | $SERVER_TYPE | $SERVER_IP ]"
echo "=========================================================================================="
echo ""
echo "  OK  /usr/local/bin/sos"
echo "  OK  ~/.bashrc — aliases ($SERVER_TYPE) — REPLACED (no duplicates)"
echo "  OK  /etc/profile.d/motd_banner.sh — MOTD (SSH-only, all old motd_*.sh removed)"
echo "  OK  ~/.config/mc/mc.menu — F2 menu"
echo "  OK  PS1 color: $COLOR_NAME"
echo ""
echo "  Preview MOTD : bash /etc/profile.d/motd_banner.sh"
echo "  Apply aliases: source ~/.bashrc"
echo ""
