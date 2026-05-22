#!/bin/bash
clear
# ==========================================================================================
# Script:      setup_aliases_modded_mc.sh
# Version:     v2026.05.22c
# Location:    scripts/setup_aliases_modded_mc.sh
# Repository:  https://github.com/GinCz/Linux_Server_Public
# Server:      ALL (222-DE-NetCup | 109-RU-FastVDS | VPN nodes | any clean server)
# One-liner:
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/setup_aliases_modded_mc.sh)
# ==========================================================================================
# SAFE     : Does NOT run apt, does NOT touch UFW, does NOT install CrowdSec.
# IDEMPOTENT: Safe to run multiple times — always replaces, NEVER duplicates.
# CLEANS   : Removes legacy banners written by install_vpn.sh into .bashrc
# = Rooted by VladiMIR + AI | v2026.05.22c | github.com/GinCz =
# ==========================================================================================

REPO_URL="https://github.com/GinCz/Linux_Server_Public.git"
REPO="/root/Linux_Server_Public"
SCRIPTS="$REPO/scripts"
BASHRC="/root/.bashrc"
BASH_PROFILE="/root/.bash_profile"

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

# Detect server type by IP
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
  *) echo "Wrong choice, skipping color"; PS1_COLOR=''; PS1_RESET=''; COLOR_NAME='DEFAULT'; BC='\033[01;96m' ;;
esac

if [ -n "$PS1_COLOR" ]; then
    sed -i '/export PS1=/d' "$BASHRC"
    sed -i '/export PS1=/d' "$BASH_PROFILE" 2>/dev/null
    echo "export PS1=\"${PS1_COLOR}\\u@\\h:\\w\\$ ${PS1_RESET}\"" >> "$BASHRC"
    echo "export PS1=\"${PS1_COLOR}\\u@\\h:\\w\\$ ${PS1_RESET}\"" >> "$BASH_PROFILE"
    echo "OK: PS1 set to $COLOR_NAME"
fi
echo ""

# ==========================================================================================
# STEP 2: Install sos to /usr/local/bin/sos
# ==========================================================================================
echo "=========================================="
echo " [2/6] SOS"
echo "=========================================="
if [ -f "$SCRIPTS/sos.sh" ]; then
    cp "$SCRIPTS/sos.sh" /usr/local/bin/sos && chmod +x /usr/local/bin/sos
    echo "OK: /usr/local/bin/sos installed"
elif [ -f "$SCRIPTS/sos-fastpanel.sh" ]; then
    cp "$SCRIPTS/sos-fastpanel.sh" /usr/local/bin/sos && chmod +x /usr/local/bin/sos
    echo "OK: /usr/local/bin/sos installed (fastpanel)"
else
    echo "SKIP: sos not found in $SCRIPTS"
fi
echo ""

# ==========================================================================================
# STEP 3: Clean legacy banners from install_vpn.sh + write fresh aliases block
# ==========================================================================================
echo "=========================================="
echo " [3/6] ALIASES"
echo "=========================================="

MARKER="# === Linux_Server_Public aliases ==="

# --- Remove legacy install_vpn.sh .bashrc block (cat > .bashrc rewrites) ---
# install_vpn.sh uses: cat > /root/.bashrc << 'BASHEOF' ... BASHEOF
# It embeds banners like: # v2026-05-01d | = Rooted by VladiMIR | AI =
# We strip those legacy echo/banner lines completely:
for PATTERN in \
    'Rooted by VladiMIR' \
    'v2026-05-0' \
    'VPN NODE FULL INSTALL' \
    '# ~/.bashrc — VPN' \
    'echo.*===.*===' \
; do
    sed -i "/${PATTERN}/d" "$BASHRC" 2>/dev/null
    sed -i "/${PATTERN}/d" "$BASH_PROFILE" 2>/dev/null
done

# --- Remove old Linux_Server_Public aliases block (from MARKER to end) ---
if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    sed -i "/^${MARKER}/,\$d" "$BASHRC"
    echo "INFO: old aliases block removed — writing fresh"
fi

# --- Write fresh aliases block ---
echo "" >> "$BASHRC"
echo "$MARKER" >> "$BASHRC"

if [ "$SERVER_TYPE" = "222" ]; then
    echo "source $SCRIPTS/shared_aliases_222.sh" >> "$BASHRC"
    echo "OK: aliases added (222)"
elif [ "$SERVER_TYPE" = "109" ]; then
    echo "source $SCRIPTS/shared_aliases_109.sh" >> "$BASHRC"
    echo "OK: aliases added (109)"
else
    # VPN node aliases
    cat >> "$BASHRC" << 'ALIASEOF'
alias 00='clear'
alias sos='/usr/local/bin/sos 1h'
alias sos1='/usr/local/bin/sos 1h'
alias sos3='/usr/local/bin/sos 3h'
alias sos24='/usr/local/bin/sos 24h'
alias sos120='/usr/local/bin/sos 120h'
alias infooo='bash /root/Linux_Server_Public/scripts/infooo.sh'
alias ports='ss -tlnp'
alias myip='curl -s ifconfig.me && echo'
alias ll='ls -lh --color=auto'
alias la='ls -Ah --color=auto'
alias df='df -h'
alias du='du -sh'
alias gs='git status'
alias gl='git log --oneline -10'
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
alias save='cd /root/Linux_Server_Public && git add -A && (git diff --cached --quiet && echo "Nothing to commit" || git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)") && git pull origin main --no-rebase --no-edit && git push origin main && echo "=== Saved ==="'
alias load='cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit && sed -i "/# === Linux_Server_Public aliases ===/,\$d" ~/.bashrc && bash /root/Linux_Server_Public/scripts/setup_aliases_modded_mc.sh && source ~/.bashrc && echo "=== Loaded ==="'
ALIASEOF
    echo "OK: aliases added (vpn)"
fi
echo ""

# ==========================================================================================
# STEP 4: MOTD — remove ALL old motd files, install single fresh one
# ==========================================================================================
echo "=========================================="
echo " [4/6] MOTD"
echo "=========================================="

# Remove every possible old MOTD file — no duplicates ever
rm -f /etc/profile.d/motd_*.sh
chmod -x /etc/update-motd.d/* 2>/dev/null
echo "INFO: all old /etc/profile.d/motd_*.sh removed"

cat > /etc/profile.d/motd_banner.sh << MOTD_SCRIPT
#!/bin/bash
# motd_banner.sh — SSH-only MOTD for VPN nodes
# = Rooted by VladiMIR + AI | v2026.05.22c | github.com/GinCz =
[ -n "\$SSH_CONNECTION" ] || return 0
shopt -q login_shell 2>/dev/null || return 0
clear

HN=\$(hostname)
IP=\$(hostname -I | awk '{print \$1}')
RAM_USED=\$(free -m | awk '/Mem:/{print \$3}')
RAM_TOTAL=\$(free -m | awk '/Mem:/{print \$2}')
CPU=\$(top -bn1 | grep 'Cpu(s)' | awk '{print int(\$2+\$4)}')
UPTIME=\$(uptime -p | sed 's/up //')
LOAD=\$(awk '{print \$1" "\$2" "\$3}' /proc/loadavg)

C='\033[01;96m'
G='\033[1;32m'
Y='\033[1;33m'
W='\033[1;37m'
R='\033[1;31m'
X='\033[0m'
LINE='\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501'

# Xray VPN status
if systemctl is-active --quiet xray 2>/dev/null; then
  XRAY_LINE="  \${Y}Xray VPN:\${X} \${G}\u25cf ACTIVE\${X}"
else
  XRAY_LINE=""
fi

# AmneziaWG peers
AWG_LINE=""
if docker exec amnezia-awg wg show wg0 dump &>/dev/null 2>&1; then
  PT=\$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l)
  PO=\$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
    | awk -v t="\$(date +%s)" '\$5>0 && (t-\$5)<180 {c++} END{print c+0}')
  [[ -z "\$PT" ]] && PT=0; [[ -z "\$PO" ]] && PO=0
  AWG_LINE="  \${Y}AmneziaWG:\${X} \${G}\${PO} online\${X} / \${W}\${PT} total peers\${X}"
fi

# CrowdSec status
if systemctl is-active --quiet crowdsec 2>/dev/null; then
  BC=\$(cscli decisions list -o raw 2>/dev/null | grep -c ',' || echo 0)
  CS_LINE="  \${Y}CrowdSec:\${X} \${G}\u25cf ACTIVE\${X} | bans: \${W}\${BC}\${X}"
else
  CS_LINE="  \${Y}CrowdSec:\${X} \${R}\u2717 INACTIVE — no protection!\${X}"
fi

echo -e "\${C}\${LINE}\${X}"
echo -e "  \${C}\U0001f512  \${W}\${HN}\${X}  \${Y}\${IP}\${X}  RAM:\${W}\${RAM_USED}/\${RAM_TOTAL}MB\${X}  CPU:\${W}\${CPU}%%\${X}"
[ -n "\$XRAY_LINE" ] && echo -e "\$XRAY_LINE"
[ -n "\$AWG_LINE"  ] && echo -e "\$AWG_LINE"
echo -e "\$CS_LINE"
echo -e "\${C}\${LINE}\${X}"
echo -e "  \${Y}VPN MANAGEMENT            SERVER                    GIT\${X}"
echo -e "\${C}\${LINE}\${X}"
echo -e "  \${G}banlog\${X}(ban list)         \${G}sos\${X}(audit 1h)           \${G}save\${X}(git push)"
echo -e "  \${G}banblock\${X}(ban IP)         \${G}sos3\${X}(audit 3h)          \${G}load\${X}(git pull+deploy)"
echo -e "  \${G}antivir\${X}(ClamAV scan)     \${G}sos24\${X}(audit 24h)        \${G}mc\${X}(Midnight Cmdr)"
echo -e "  \${G}backup\${X}(VPN configs)      \${G}infooo\${X}(server info)     \${G}00\${X}(clear screen)"
echo -e "\${C}\${LINE}\${X}"
echo -e "  \${Y}Ubuntu 24\${X} | \${Y}VPN Node\${X} | up \${W}\${UPTIME}\${X} | load: \${G}\${LOAD}\${X}"
echo ""
MOTD_SCRIPT

chmod +x /etc/profile.d/motd_banner.sh
echo "OK: /etc/profile.d/motd_banner.sh installed (SSH-only)"
echo ""

# ==========================================================================================
# STEP 5: Midnight Commander F2 menu
# ==========================================================================================
echo "=========================================="
echo " [5/6] MC F2 MENU"
echo "=========================================="
MC_DIR="/root/.config/mc"
mkdir -p "$MC_DIR"
MC_MENU="$MC_DIR/mc.menu"

# Remove old location if exists
[ -f "/root/.mc.menu" ] && rm -f "/root/.mc.menu" && echo "FIXED: removed old ~/.mc.menu"

cat > "$MC_MENU" << MCEOF
# Midnight Commander F2 User Menu
# = Rooted by VladiMIR + AI | v2026.05.22c | github.com/GinCz =

i   infooo — server info
    bash $SCRIPTS/infooo.sh

s   sos — health monitor (1h)
    /usr/local/bin/sos 1h

a   antivirus — ClamAV scan
    bash $SCRIPTS/scan_clamav.sh

g   git save — push to GitHub
    cd /root/Linux_Server_Public && git add -A && git commit -m "save: \$(hostname) \$(date +%Y-%m-%d_%H:%M)" && git push origin main && echo "=== Saved ==="

l   git load — pull from GitHub + redeploy
    cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit && bash /root/Linux_Server_Public/scripts/setup_aliases_modded_mc.sh && echo "=== Loaded ==="

x   xray — status
    systemctl status xray

w   wireguard / amnezia — status
    wg show 2>/dev/null || docker ps | grep amnezia

b   backup — VPN configs
    bash $SCRIPTS/xray_backup_node.sh
MCEOF

MC_INI="$MC_DIR/ini"
[ -f "$MC_INI" ] && sed -i 's/auto_save_setup=true/auto_save_setup=false/' "$MC_INI"

echo "OK: $MC_MENU created"
echo ""

# ==========================================================================================
# STEP 6: Apply + Summary
# ==========================================================================================
echo "=========================================="
echo " [6/6] DONE"
echo "=========================================="
source "$BASHRC" 2>/dev/null
echo ""
echo "=========================================================================================="
echo "  DONE! [ $SERVER_NAME | $SERVER_TYPE | $SERVER_IP ]"
echo "=========================================================================================="
echo ""
echo "  OK  /usr/local/bin/sos"
echo "  OK  $BASHRC — aliases ($SERVER_TYPE) — replaced, no duplicates"
echo "  OK  /etc/profile.d/motd_banner.sh — MOTD, all old motd_*.sh removed"
echo "  OK  $MC_MENU — MC F2 menu"
echo "  OK  PS1 color: $COLOR_NAME"
echo ""
echo "  Reconnect SSH to see new MOTD"
echo ""
