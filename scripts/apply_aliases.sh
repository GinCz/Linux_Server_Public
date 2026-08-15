#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  apply_aliases.sh | [v2026-05-22]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Deploy shared aliases and system profile shortcuts
# Servers     : All Linux Nodes
# Usage       : bash scripts/apply_aliases.sh
# ==========================================================================================
REPO="/root/Linux_Server_Public"
SCRIPTS="$REPO/scripts"

# --- Detect server type by IP ---
MY_IP=$(hostname -I | awk '{print $1}')
case "$MY_IP" in
    152.53.182.222) SERVER_TYPE="222" ;;
    212.109.223.109) SERVER_TYPE="109" ;;
    *) SERVER_TYPE="vpn" ;;
esac

echo "=== Server: $(hostname)  IP: $MY_IP  Type: $SERVER_TYPE ==="
echo ""

# =============================================================
# STEP 1: Install sos to /usr/local/bin/sos
# =============================================================
if [ -f "$SCRIPTS/sos.sh" ]; then
    cp "$SCRIPTS/sos.sh" /usr/local/bin/sos
    chmod +x /usr/local/bin/sos
    echo "OK: /usr/local/bin/sos installed (sos.sh)"
elif [ -f "$SCRIPTS/sos-fastpanel.sh" ]; then
    cp "$SCRIPTS/sos-fastpanel.sh" /usr/local/bin/sos
    chmod +x /usr/local/bin/sos
    echo "OK: /usr/local/bin/sos installed (sos-fastpanel.sh)"
else
    echo "SKIP: sos script not found in $SCRIPTS"
fi

# =============================================================
# STEP 2: Add aliases block to ~/.bashrc
# =============================================================
BASHRC="$HOME/.bashrc"
MARKER="# === Linux_Server_Public aliases ==="

if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    echo "OK: aliases already in ~/.bashrc — skipping (remove marker to re-add)"
else
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
alias load='cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit && sed -i "/# === Linux_Server_Public aliases ===/,$ d" ~/.bashrc && bash /root/Linux_Server_Public/scripts/apply_aliases.sh && source ~/.bashrc && echo "=== Loaded ==="'
alias xray_log='journalctl -u xray -n 50 --no-pager 2>/dev/null'
alias xray_st='systemctl status xray 2>/dev/null'
alias amn_st='systemctl status amneziawg 2>/dev/null || docker ps | grep amnezia 2>/dev/null || echo "AmneziaWG not found"'
alias wg_st='wg show 2>/dev/null || echo "WireGuard not active"'
alias adg_st='systemctl status AdGuardHome 2>/dev/null || echo "AdGuard not installed"'
alias banlist='cscli decisions list 2>/dev/null || echo "CrowdSec not installed"'
EOF
        echo "OK: aliases added (vpn)"
    fi
fi

# =============================================================
# STEP 3: MOTD — SSH login only, no double output
#
# IMPORTANT: Do NOT use infooo.sh here — it has no SSH guard
# and fires on every bash start (new mc panel, su, cron, etc.)
# causing double/triple output on login.
#
# motd_vpn.sh has built-in guards:
#   shopt -q login_shell || return 0
#   [ -n "$SSH_CONNECTION" ] || return 0
# So it fires ONLY on real SSH login — exactly once.
# =============================================================
MOTD_FILE="/etc/profile.d/motd_custom.sh"

if [ -f "$SCRIPTS/motd_vpn.sh" ]; then
    cat > "$MOTD_FILE" << EOF
#!/usr/bin/env bash
# MOTD — auto-added by apply_aliases.sh v2026.05.22
# motd_vpn.sh fires ONLY on SSH login (has SSH_CONNECTION + login_shell guard)
bash $SCRIPTS/motd_vpn.sh
EOF
    chmod +x "$MOTD_FILE"
    echo "OK: MOTD set — $MOTD_FILE (uses motd_vpn.sh, SSH-only)"
else
    echo "SKIP: motd_vpn.sh not found in $SCRIPTS"
fi

# =============================================================
# STEP 4: Midnight Commander F2 menu
# =============================================================
MC_DIR="$HOME/.config/mc"
mkdir -p "$MC_DIR"
MC_MENU="$MC_DIR/mc.menu"

if [ -f "$MC_MENU" ] && grep -q "Linux_Server_Public" "$MC_MENU" 2>/dev/null; then
    echo "OK: MC menu already configured — skipping"
else
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
    echo "OK: MC F2 menu created — $MC_MENU"
fi

# =============================================================
# DONE
# =============================================================
echo ""
echo -e "\033[1;32m=== DONE! Run: source ~/.bashrc ===\033[0m"
echo ""
echo "  Installed:"
echo "    /usr/local/bin/sos"
echo "    ~/.bashrc aliases (type: $SERVER_TYPE)"
echo "    /etc/profile.d/motd_custom.sh  (SSH-only via motd_vpn.sh)"
echo "    ~/.config/mc/mc.menu (F2)"
echo ""

# = Rooted by VladiMIR | AI = v2026-05-22 = github.com/GinCz/Linux_Server_Public
