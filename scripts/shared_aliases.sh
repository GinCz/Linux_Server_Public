#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  shared_aliases.sh | [v2026-06-10]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Shared aliases and bash functions for VPN nodes
# Servers     : VPN Nodes
# Usage       : bash scripts/shared_aliases.sh
# ==========================================================================================
REPO="/root/Linux_Server_Public"
SCRIPTS="$REPO/scripts"
VPN="$REPO/VPN"

# --- SYSTEM ---
alias mc='mc'
alias ll='ls -la --color=auto'
alias la='ls -la --color=auto'
alias infooo="/usr/local/bin/infooo.sh"

# --- SOS HEALTH MONITOR ---
alias sos="/usr/local/bin/sos 1h"
alias sos1="/usr/local/bin/sos 1h"
alias sos3="/usr/local/bin/sos 3h"
alias sos24="/usr/local/bin/sos 24h"
alias sos120="/usr/local/bin/sos 120h"

# --- UPDATE & CLEANUP ---
# upd: apt upgrade + autoremove + clean logs/tmp + reboot
alias upd="bash $SCRIPTS/upd.sh"

# --- SECURITY / CROWDSEC ---
alias banlist="cscli decisions list 2>/dev/null || echo 'CrowdSec not installed'"
alias banblock='cscli decisions add --ip'
alias banunblock='cscli decisions delete --ip'
alias fight="/usr/local/bin/block_bots.sh 2>/dev/null || echo 'block_bots.sh not found'"

# --- BACKUP & ANTIVIRUS ---
alias antivir="/usr/local/bin/scan_clamav.sh 2>/dev/null || bash $SCRIPTS/scan_clamav.sh 2>/dev/null || echo 'ClamAV scan script not found'"
alias backup="/usr/local/bin/system_backup.sh 2>/dev/null || echo 'backup script not found'"

# --- GIT REPO ---
alias save="bash $SCRIPTS/save.sh"
alias load="bash $SCRIPTS/load.sh"
alias repo="cd $REPO"

# --- NIGHT MAINTENANCE LOGS ---
alias nightlog='tail -50 /var/log/auto-upgrade.log'

# --- SERVER THEME & RECONFIG ---
alias style="bash /root/Linux_Server_Public/scripts/new_server_install.sh 2>/dev/null || bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)"
alias theme='style'

# = Rooted by VladiMIR | AI = v2026-06-10 = github.com/GinCz/Linux_Server_Public
