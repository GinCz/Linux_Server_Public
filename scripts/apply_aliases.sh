#!/usr/bin/env bash
clear
# =============================================================
# Script:      apply_aliases.sh
# Version:     v2026.05.20
# Location:    scripts/apply_aliases.sh
# Servers:     222-DE / 109-RU / VPN nodes
# Description: Universal setup script. Detects server type and:
#              1) Installs sos to /usr/local/bin/sos
#              2) Adds aliases to ~/.bashrc
#              3) Sets up MOTD header
#              4) Sets up Midnight Commander F2 menu
# Usage:       bash ~/Linux_Server_Public/scripts/apply_aliases.sh
# = Rooted by VladiMIR + AI | v2026.05.20 | github.com/GinCz =
# =============================================================

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
if [ -f "$SCRIPTS/sos-fastpanel.sh" ]; then
    cp "$SCRIPTS/sos-fastpanel.sh" /usr/local/bin/sos
    chmod +x /usr/local/bin/sos
    echo "OK: /usr/local/bin/sos installed"
else
    echo "SKIP: sos-fastpanel.sh not found in $SCRIPTS"
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
    elif [ "$SERVER_TYPE" = "109" ]; then
        echo "source $SCRIPTS/shared_aliases_109.sh" >> "$BASHRC"
    else
        # VPN node — minimal aliases
        cat >> "$BASHRC" << 'EOF'
alias 00='clear'
alias save="bash /root/Linux_Server_Public/scripts/save.sh"
alias load="bash /root/Linux_Server_Public/scripts/load.sh"
alias sos='sos 1h'
alias sos1='sos 1h'
alias sos3='sos 3h'
alias sos24='sos 24h'
alias sos120='sos 120h'
alias infooo='bash /root/Linux_Server_Public/scripts/infooo.sh'
alias ports='ss -tlnp'
EOF
    fi
    echo "OK: aliases added to ~/.bashrc"
fi

# =============================================================
# STEP 3: MOTD header (/etc/profile.d/motd_custom.sh)
# =============================================================
MOTD_FILE="/etc/profile.d/motd_custom.sh"
if [ -f "$SCRIPTS/infooo.sh" ]; then
    cat > "$MOTD_FILE" << EOF
#!/usr/bin/env bash
# MOTD — auto-added by apply_aliases.sh
bash $SCRIPTS/infooo.sh
EOF
    chmod +x "$MOTD_FILE"
    echo "OK: MOTD set — $MOTD_FILE"
else
    echo "SKIP: infooo.sh not found, MOTD not set"
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
# = Rooted by VladiMIR + AI | v2026.05.20 | github.com/GinCz =

i   infooo — server info
    bash $SCRIPTS/infooo.sh

s   sos — health monitor (1h)
    sos 1h

d   domains — list domains
    bash $SCRIPTS/domains.sh

b   backup — all servers
    bash $REPO/222/backup_all_servers.sh

a   antivirus ClamAV scan
    bash $SCRIPTS/scan_clamav.sh

w   watchdog PHP-FPM
    bash $SCRIPTS/php_fpm_watchdog.sh

f   fight — block bots
    bash $SCRIPTS/block_bots.sh

g   git save — push to GitHub
    bash $SCRIPTS/save.sh

l   git load — pull from GitHub
    bash $SCRIPTS/load.sh
EOF
    echo "OK: MC F2 menu created — $MC_MENU"
fi

# =============================================================
# DONE
# =============================================================
echo ""
echo -e "\033[1;32m✅ DONE! Run: source ~/.bashrc\033[0m"
echo ""
echo "  Installed:"
echo "    /usr/local/bin/sos"
echo "    ~/.bashrc aliases (type: $SERVER_TYPE)"
echo "    /etc/profile.d/motd_custom.sh"
echo "    ~/.config/mc/mc.menu (F2)"
echo ""
