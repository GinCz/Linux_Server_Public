#!/bin/bash
clear
# =============================================================
# Script:      setup_motd_aliases_mc.sh
# Version:     v2026.05.22b
# Location:    scripts/setup_motd_aliases_mc.sh
# Server:      ALL (222-DE-NetCup | 109-RU-FastVDS | VPN nodes)
# One-liner:
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/setup_motd_aliases_mc.sh)
# Description:
#   1) Clone or pull repo
#   2) Choose PS1 color (5 options, interactive)
#   3) Set PS1 in .bashrc + .bash_profile
#   4) Install sos to /usr/local/bin/sos
#   5) Add aliases to ~/.bashrc (idempotent, always replaces)
#   6) Create MOTD: /etc/profile.d/motd_banner.sh (SSH login only)
#   7) Create Midnight Commander F2 user menu
# SAFE: does NOT run apt, does NOT touch UFW, does NOT install CrowdSec
# CLEANS: removes legacy banners written by install_vpn.sh into .bashrc
# = Rooted by VladiMIR + AI | v2026.05.22b | github.com/GinCz =
# =============================================================

REPO_URL="https://github.com/GinCz/Linux_Server_Public.git"
REPO="/root/Linux_Server_Public"
SCRIPTS="$REPO/scripts"
BASHRC="/root/.bashrc"
BASH_PROFILE="/root/.bash_profile"

SERVER_NAME=$(hostname)
SERVER_IP=$(hostname -I | awk '{print $1}')

echo ""
echo "====================================="
echo "  SETUP: $SERVER_NAME  [$SERVER_IP]"
echo "====================================="
echo ""

# =============================================================
# STEP 0: Clone or pull repo
# =============================================================
echo "--- [0/6] Repo ---"
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
echo "Server type: $SERVER_TYPE"
echo ""

# =============================================================
# STEP 1: Color picker + PS1
# =============================================================
echo "--- [1/6] Color picker ---"
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
    sed -i '/export PS1=/d' "$BASHRC"
    echo "export PS1=\"${PS1_COLOR}\\u@\\h:\\w\\$ ${PS1_RESET}\"" >> "$BASHRC"
    sed -i '/export PS1=/d' "$BASH_PROFILE" 2>/dev/null
    echo "export PS1=\"${PS1_COLOR}\\u@\\h:\\w\\$ ${PS1_RESET}\"" >> "$BASH_PROFILE"
    echo "OK: PS1 set to $COLOR_NAME"
fi
echo ""

# =============================================================
# STEP 2: Install sos
# =============================================================
echo "--- [2/6] sos ---"
if [ -f "$SCRIPTS/sos.sh" ]; then
    cp "$SCRIPTS/sos.sh" /usr/local/bin/sos && chmod +x /usr/local/bin/sos
    echo "OK: /usr/local/bin/sos installed"
elif [ -f "$SCRIPTS/sos-fastpanel.sh" ]; then
    cp "$SCRIPTS/sos-fastpanel.sh" /usr/local/bin/sos && chmod +x /usr/local/bin/sos
    echo "OK: /usr/local/bin/sos installed (fastpanel)"
else
    echo "SKIP: sos not found"
fi
echo ""

# =============================================================
# STEP 3: Clean legacy install_vpn.sh banners + write aliases
# install_vpn.sh rewrites .bashrc with cat > and embeds banners:
#   # v2026-05-01d | = Rooted by VladiMIR | AI =
#   # ~/.bashrc — VPN | ...
# We strip those lines, then always replace the aliases block.
# =============================================================
echo "--- [3/6] Aliases ---"
MARKER="# === Linux_Server_Public aliases ==="

# Strip legacy banners from install_vpn.sh
for PATTERN in \
    'Rooted by VladiMIR' \
    'v2026-05-0' \
    '# ~/.bashrc — VPN' \
    'VPN NODE FULL INSTALL' \
; do
    sed -i "/${PATTERN}/d" "$BASHRC" 2>/dev/null
    sed -i "/${PATTERN}/d" "$BASH_PROFILE" 2>/dev/null
done

# Always replace aliases block (idempotent: remove old, write fresh)
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
alias upd='/usr/local/bin/upd'
alias mc='MC_SKIN=default mc'
alias save='cd /root/Linux_Server_Public && git add -A && (git diff --cached --quiet && echo "Nothing to commit" || git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)") && git pull origin main --no-rebase --no-edit && git push origin main && echo "=== Saved ==="'
alias load='cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit && sed -i "/# === Linux_Server_Public aliases ===/,\$d" ~/.bashrc && bash /root/Linux_Server_Public/scripts/setup_motd_aliases_mc.sh && source ~/.bashrc && echo "=== Loaded ==="'
ALIASEOF
    echo "OK: aliases added (vpn)"
fi
echo ""

# =============================================================
# STEP 4: MOTD — remove ALL old files, install one fresh
# =============================================================
echo "--- [4/6] MOTD ---"
rm -f /etc/profile.d/motd_*.sh
chmod -x /etc/update-motd.d/* 2>/dev/null
echo "INFO: old MOTD files removed"

cat > /etc/profile.d/motd_banner.sh << MOTD_SCRIPT
#!/bin/bash
[ -n "\$SSH_CONNECTION" ] || return 0
shopt -q login_shell 2>/dev/null || return 0
clear

SERVER_NAME=\$(hostname)
SERVER_IP=\$(hostname -I | awk '{print \$1}')
RAM_USED=\$(free -m | awk '/Mem:/{print \$3}')
RAM_TOTAL=\$(free -m | awk '/Mem:/{print \$2}')
CPU=\$(top -bn1 | grep 'Cpu(s)' | awk '{print int(\$2+\$4)}')
UPTIME=\$(uptime -p)
LOAD=\$(uptime | awk -F'load average:' '{print \$2}')

COLOR='${BC}'
RESET='\033[0m'
BOLD='\033[1m'
LINE=\$(printf '%.0s\u2500' {1..80})

echo -e "\${COLOR}\${LINE}\${RESET}"
printf "\${COLOR}  \u2665  %-22s %-22s RAM:%s/%sMB  CPU:%s%%\n\${RESET}" "\$SERVER_NAME" "\$SERVER_IP" "\$RAM_USED" "\$RAM_TOTAL" "\$CPU"
echo -e "\${COLOR}\${LINE}\${RESET}"

ALL_ALIASES=\$(grep -h 'alias ' /root/.bashrc /root/.bash_profile 2>/dev/null | sed 's/alias //g' | awk -F'=' '{print \$1}' | grep -v '^#' | sort -u | tr '\n' ' ')
echo -e "  \${BOLD}ALIASES:\${RESET} \$ALL_ALIASES" | fold -s -w 78 | sed '2,\$ s/^/  /'

echo -e "\${COLOR}\${LINE}\${RESET}"
echo -e "  \$(lsb_release -ds 2>/dev/null || echo Linux) | \$SERVER_IP | \$UPTIME | load:\$LOAD"
echo -e "\${COLOR}\${LINE}\${RESET}"
echo ""
MOTD_SCRIPT

chmod +x /etc/profile.d/motd_banner.sh
echo "OK: MOTD installed — /etc/profile.d/motd_banner.sh (SSH-only)"
echo ""

# =============================================================
# STEP 5: Midnight Commander F2 menu
# =============================================================
echo "--- [5/6] MC menu ---"
MC_DIR="/root/.config/mc"
mkdir -p "$MC_DIR"
MC_MENU="$MC_DIR/mc.menu"

[ -f "/root/.mc.menu" ] && rm -f "/root/.mc.menu" && echo "FIXED: removed ~/.mc.menu trap"

cat > "$MC_MENU" << MCEOF
# Midnight Commander F2 User Menu
# = Rooted by VladiMIR + AI | v2026.05.22b | github.com/GinCz =

i   infooo — server info
    bash $SCRIPTS/infooo.sh

s   sos — health monitor (1h)
    /usr/local/bin/sos 1h

a   antivirus — ClamAV scan
    bash $SCRIPTS/scan_clamav.sh

g   git save — push to GitHub
    cd /root/Linux_Server_Public && git add -A && git commit -m "save: \$(hostname) \$(date +%Y-%m-%d_%H:%M)" && git push origin main && echo "=== Saved ==="

l   git load — pull from GitHub + redeploy
    cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit && bash /root/Linux_Server_Public/scripts/setup_motd_aliases_mc.sh && echo "=== Loaded ==="

x   xray status
    systemctl status xray

w   wireguard / amnezia status
    wg show 2>/dev/null || docker ps | grep amnezia

b   backup — VPN configs
    bash $SCRIPTS/xray_backup_node.sh
MCEOF

MC_INI="$MC_DIR/ini"
[ -f "$MC_INI" ] && sed -i 's/auto_save_setup=true/auto_save_setup=false/' "$MC_INI"

echo "OK: MC F2 menu created — $MC_MENU"
echo ""

# =============================================================
# STEP 6: Apply
# =============================================================
echo "--- [6/6] Apply ---"
source /root/.bashrc 2>/dev/null
echo ""
echo "====================================="
echo "  DONE! [$SERVER_NAME / $SERVER_TYPE]"
echo "====================================="
echo ""
echo "  OK  /usr/local/bin/sos"
echo "  OK  ~/.bashrc — aliases ($SERVER_TYPE) — replaced, no duplicates"
echo "  OK  /etc/profile.d/motd_banner.sh — MOTD (SSH-only)"
echo "  OK  ~/.config/mc/mc.menu — F2 menu"
echo "  OK  PS1 color: $COLOR_NAME"
echo ""
echo "  Reconnect SSH to see new MOTD"
echo "  Preview MOTD: bash /etc/profile.d/motd_banner.sh"
echo ""
