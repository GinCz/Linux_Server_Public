#!/bin/bash
clear
# =============================================================
# Script:      setup_motd_aliases_mc.sh
# Version:     v2026.05.22
# Location:    scripts/setup_motd_aliases_mc.sh
# Server:      ALL (222-DE-NetCup | 109-RU-FastVDS | VPN nodes)
# Alias:       none (run directly)
# Run from repo (curl one-liner — works on ANY server without cloning):
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/setup_motd_aliases_mc.sh)
# Or after git clone/pull:
#   bash /root/Linux_Server_Public/scripts/setup_motd_aliases_mc.sh
# Description: Universal setup for any server.
#              Auto-detects server type by IP (222 / 109 / VPN node).
#              1) Clones or pulls Linux_Server_Public repo
#              2) Installs sos to /usr/local/bin/sos
#              3) Adds aliases block to ~/.bashrc (idempotent)
#              4) Sets up MOTD via motd_vpn.sh (SSH login only, no double output)
#              5) Creates Midnight Commander F2 user menu
# Dependencies: git, bash, curl, cp, sed, mkdir
# WARNING:     Appends to ~/.bashrc (safe — skips if marker exists).
#              Overwrites /etc/profile.d/motd_custom.sh.
#              Overwrites ~/.config/mc/mc.menu.
# = Rooted by VladiMIR + AI | v2026.05.22 | github.com/GinCz =
# =============================================================

REPO_URL="https://github.com/GinCz/Linux_Server_Public.git"
REPO="/root/Linux_Server_Public"
SCRIPTS="$REPO/scripts"

# Colors
GRN='\033[0;32m'
YEL='\033[1;33m'
CYN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYN}=============================================================${NC}"
echo -e "${CYN}  Setup: MOTD + Aliases + MC  |  v2026.05.22${NC}"
echo -e "${CYN}=============================================================${NC}"
echo ""

# =============================================================
# STEP 0: Clone or pull repo
# =============================================================
echo -e "${CYN}--- STEP 0: Repo ---${NC}"
if [ -d "$REPO/.git" ]; then
    echo "Pulling latest..."
    cd "$REPO" && git pull origin main --no-rebase --no-edit
else
    echo "Cloning repo..."
    cd /root && git clone "$REPO_URL"
fi
echo -e "${GRN}OK: Repo ready at $REPO${NC}"
echo ""

# --- Detect server type by IP ---
MY_IP=$(hostname -I | awk '{print $1}')
case "$MY_IP" in
    152.53.182.222) SERVER_TYPE="222" ;;
    212.109.223.109) SERVER_TYPE="109" ;;
    *) SERVER_TYPE="vpn" ;;
esac

echo -e "${YEL}Server: $(hostname)  |  IP: $MY_IP  |  Type: $SERVER_TYPE${NC}"
echo ""

# =============================================================
# STEP 1: Install sos to /usr/local/bin/sos
# =============================================================
echo -e "${CYN}--- STEP 1: sos ---${NC}"
if [ -f "$SCRIPTS/sos.sh" ]; then
    cp "$SCRIPTS/sos.sh" /usr/local/bin/sos
    chmod +x /usr/local/bin/sos
    echo -e "${GRN}OK: /usr/local/bin/sos installed (sos.sh)${NC}"
elif [ -f "$SCRIPTS/sos-fastpanel.sh" ]; then
    cp "$SCRIPTS/sos-fastpanel.sh" /usr/local/bin/sos
    chmod +x /usr/local/bin/sos
    echo -e "${GRN}OK: /usr/local/bin/sos installed (sos-fastpanel.sh)${NC}"
else
    echo -e "${YEL}SKIP: sos script not found in $SCRIPTS${NC}"
fi
echo ""

# =============================================================
# STEP 2: Add aliases block to ~/.bashrc
# =============================================================
echo -e "${CYN}--- STEP 2: Aliases ---${NC}"
BASHRC="$HOME/.bashrc"
MARKER="# === Linux_Server_Public aliases ==="

if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    echo -e "${YEL}SKIP: aliases already in ~/.bashrc (remove marker to re-add)${NC}"
else
    echo "" >> "$BASHRC"
    echo "$MARKER" >> "$BASHRC"

    if [ "$SERVER_TYPE" = "222" ]; then
        echo "source $SCRIPTS/shared_aliases_222.sh" >> "$BASHRC"
        echo -e "${GRN}OK: aliases added (222)${NC}"
    elif [ "$SERVER_TYPE" = "109" ]; then
        echo "source $SCRIPTS/shared_aliases_109.sh" >> "$BASHRC"
        echo -e "${GRN}OK: aliases added (109)${NC}"
    else
        # VPN node aliases
        cat >> "$BASHRC" << 'EOF'
alias 00='clear'
alias sos='/usr/local/bin/sos 1h'
alias sos1='/usr/local/bin/sos 1h'
alias sos3='/usr/local/bin/sos 3h'
alias sos24='/usr/local/bin/sos 24h'
alias sos120='/usr/local/bin/sos 120h'
alias infooo='bash /root/Linux_Server_Public/scripts/infooo.sh'
alias ports='ss -tlnp'
alias save='cd /root/Linux_Server_Public && git add -A && (git diff --cached --quiet && echo "Nothing to commit" || git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)") && git pull origin main --no-rebase --no-edit && git push origin main && echo "=== Saved ==="'
alias load='cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit && sed -i "/# === Linux_Server_Public aliases ===/,$ d" ~/.bashrc && bash /root/Linux_Server_Public/scripts/setup_motd_aliases_mc.sh && source ~/.bashrc && echo "=== Loaded ==="'
alias xray_log='journalctl -u xray -n 50 --no-pager 2>/dev/null'
alias xray_st='systemctl status xray 2>/dev/null'
alias amn_st='systemctl status amneziawg 2>/dev/null || docker ps | grep amnezia 2>/dev/null || echo "AmneziaWG not found"'
alias wg_st='wg show 2>/dev/null || echo "WireGuard not active"'
alias adg_st='systemctl status AdGuardHome 2>/dev/null || echo "AdGuard not installed"'
alias banlist='cscli decisions list 2>/dev/null || echo "CrowdSec not installed"'
EOF
        echo -e "${GRN}OK: aliases added (vpn)${NC}"
    fi
fi
echo ""

# =============================================================
# STEP 3: MOTD — SSH login only, no double output
#
# motd_vpn.sh has built-in guards:
#   shopt -q login_shell || return 0
#   [ -n "$SSH_CONNECTION" ] || return 0
# Fires ONLY on real SSH login — exactly once.
# =============================================================
echo -e "${CYN}--- STEP 3: MOTD ---${NC}"
MOTD_FILE="/etc/profile.d/motd_custom.sh"

if [ -f "$SCRIPTS/motd_vpn.sh" ]; then
    cat > "$MOTD_FILE" << EOF
#!/usr/bin/env bash
# MOTD — auto-added by setup_motd_aliases_mc.sh v2026.05.22
# motd_vpn.sh fires ONLY on SSH login (has SSH_CONNECTION + login_shell guard)
bash $SCRIPTS/motd_vpn.sh
EOF
    chmod +x "$MOTD_FILE"
    echo -e "${GRN}OK: MOTD set — $MOTD_FILE (SSH-only via motd_vpn.sh)${NC}"
else
    echo -e "${RED}SKIP: motd_vpn.sh not found in $SCRIPTS${NC}"
fi
echo ""

# =============================================================
# STEP 4: Midnight Commander F2 menu
# =============================================================
echo -e "${CYN}--- STEP 4: MC F2 menu ---${NC}"
MC_DIR="$HOME/.config/mc"
mkdir -p "$MC_DIR"
MC_MENU="$MC_DIR/mc.menu"

# Remove mc trap file if exists (known bug — see README)
if [ -f "$HOME/.mc.menu" ]; then
    rm -f "$HOME/.mc.menu"
    echo -e "${YEL}FIXED: removed ~/.mc.menu trap file${NC}"
fi

cat > "$MC_MENU" << EOF
# Midnight Commander F2 User Menu
# = Rooted by VladiMIR + AI | v2026.05.22 | github.com/GinCz =

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
EOF

# Fix mc ini: disable auto_save_setup to prevent menu overwrite on exit
MC_INI="$MC_DIR/ini"
if [ -f "$MC_INI" ]; then
    sed -i 's/auto_save_setup=true/auto_save_setup=false/' "$MC_INI"
    echo -e "${GRN}OK: mc.ini auto_save_setup=false${NC}"
fi

echo -e "${GRN}OK: MC F2 menu created — $MC_MENU${NC}"
echo ""

# =============================================================
# DONE
# =============================================================
echo -e "${GRN}=============================================================${NC}"
echo -e "${GRN}  DONE! Run: source ~/.bashrc${NC}"
echo -e "${GRN}=============================================================${NC}"
echo ""
echo "  Installed on: $(hostname) [$SERVER_TYPE]"
echo "    /usr/local/bin/sos"
echo "    ~/.bashrc  — aliases block"
echo "    /etc/profile.d/motd_custom.sh  — MOTD (SSH-only)"
echo "    ~/.config/mc/mc.menu  — F2 menu"
echo ""
echo "  Re-login via SSH to see MOTD."
echo ""
