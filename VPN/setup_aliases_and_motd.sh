#!/bin/bash
clear
# =============================================================
# Script:      setup_aliases_and_motd.sh
# Version:     v2026-04-29
# Server:      All VPN nodes (STOLB_24 / TATRA_9 / ALEX_47 / 4TON_237 / SO_38)
# Description: One-click universal setup for VPN server aliases + MOTD.
#              Auto-clones Linux_Server_Public repo if not present.
#              Deploys .bashrc with VPN-specific aliases, PS1 prompt (green),
#              MOTD banner and Midnight Commander F2 menu.
# Usage:       bash /root/Linux_Server_Public/VPN/setup_aliases_and_motd.sh
#              OR on fresh node (no repo yet):
#              bash <(curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/VPN/setup_aliases_and_motd.sh)
# Dependencies: bash, git, curl
# WARNING:     Affects only new SSH sessions. Safe on production VPN node.
# = Rooted by VladiMIR | AI =
# =============================================================

echo "=== Setup Aliases + MOTD for VPN Nodes ==="

# --- auto-clone repo if missing ----------------------------------------
REPO_DIR="/root/Linux_Server_Public"
if [ ! -d "$REPO_DIR" ]; then
    echo "[INFO] Repo not found at $REPO_DIR — cloning from GitHub..."
    git clone https://github.com/GinCz/Linux_Server_Public.git "$REPO_DIR"
    echo "[OK] Repo cloned to $REPO_DIR"
else
    echo "[INFO] Repo found at $REPO_DIR — pulling latest..."
    git -C "$REPO_DIR" pull
fi

cat > ~/.bashrc << 'INNER'
clear
if [ -f ~/Linux_Server_Public/VPN/shared_aliases_vpn.sh ]; then
    . ~/Linux_Server_Public/VPN/shared_aliases_vpn.sh
fi

# green prompt for VPN nodes
PS1='\[\e[32m\]root@VPN-Node\[\e[0m\]:\[\e[33m\]\w\[\e[0m\]# '

if [ -f ~/Linux_Server_Public/VPN/motd_server.sh ]; then
    bash ~/Linux_Server_Public/VPN/motd_server.sh
fi

echo "=== .bashrc v2026-04-29 for VPN-Node loaded ==="
INNER

echo "\u2705 Universal VPN aliases and MOTD configured (AdGuard + Uptime Kuma support)."
echo "Reconnect SSH or run: source ~/.bashrc"
