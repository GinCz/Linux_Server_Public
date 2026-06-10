#!/usr/bin/env bash
# =============================================================
# File:        shared_aliases.sh
# Version:     v2026.06.10
# Location:    scripts/shared_aliases.sh
# Server:      ALL VPN nodes (alex47, 4ton237, tatra9, shahin227,
#              stolb24, pilik178, ilya176, so38, ...)
# Description: Shared aliases for VPN nodes ~/.bashrc
#              Loaded via: source ~/Linux_Server_Public/scripts/shared_aliases.sh
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
# =============================================================

REPO="/root/Linux_Server_Public"
SCRIPTS="$REPO/scripts"
VPN="$REPO/VPN"

# --- SYSTEM ---
alias 00='clear'
alias mc='mc'
alias ll='ls -la --color=auto'
alias la='ls -la --color=auto'
alias infooo="bash $SCRIPTS/infooo.sh"

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
alias fight="bash $SCRIPTS/block_bots.sh 2>/dev/null || echo 'block_bots.sh not found'"

# --- BACKUP & ANTIVIRUS ---
alias antivir="bash $VPN/scan_clamav_vpn.sh 2>/dev/null || bash $SCRIPTS/scan_clamav.sh 2>/dev/null || echo 'ClamAV scan script not found'"
alias backup="bash $VPN/xray_backup_node.sh 2>/dev/null || echo 'backup script not found'"

# --- VPN SERVICE STATUS ---
alias xray_st='systemctl status xray 2>/dev/null || echo "Xray not installed"'
alias smb_st='systemctl status smbd 2>/dev/null || echo "Samba not installed"'
alias adg_st='systemctl status AdGuardHome 2>/dev/null || echo "AdGuard not installed"'
alias awg_st='docker ps --filter name=amnezia-awg 2>/dev/null || echo "AmneziaWG not installed"'

# --- GIT REPO ---
alias save="bash $SCRIPTS/save.sh"
alias load="bash $SCRIPTS/load.sh"
alias repo="cd $REPO"

# --- NIGHT MAINTENANCE LOGS ---
alias nightlog='tail -50 /var/log/auto-upgrade.log'
