#!/usr/bin/env bash
# Script:  shared_aliases.sh
# Version: v2026-03-22
# Purpose: Shared aliases for all server types. Sourced by ~/.bashrc for root and adminer.
#          Different sets for Type 1 (222), Type 2 (109), Type 3 (VPN).\n# Usage:   source /opt/server_tools/shared_aliases.sh

# Universal for all server types
alias 00='clear'
alias infooo='/opt/server_tools/scripts/infooo.sh'
alias load='bash /opt/server_tools/scripts/load.sh && source /opt/server_tools/shared_aliases.sh'
alias save='bash /opt/server_tools/scripts/save.sh'
alias audit='/opt/server_tools/scripts/full_audit.sh'
alias aws-test='/opt/server_tools/scripts/aws_region_test.sh'
alias 303='bash /opt/server_tools/scripts/log_303.sh'

# Type 1 & 2: FastPanel servers (222 and 109)
if [[ "$(hostname)" =~ "222" ]] || [[ "$(hostname)" =~ "109" ]]; then
    alias sos='/opt/server_tools/scripts/server_audit.sh'
    alias sos1='/opt/server_tools/scripts/server_audit.sh 1'
    alias sos3='/opt/server_tools/scripts/server_audit.sh 3'
    alias sos24='/opt/server_tools/scripts/server_audit.sh 24'
    alias sos120='/opt/server_tools/scripts/server_audit.sh 120'
    alias aw='/opt/server_tools/scripts/amnezia_stat.sh'
    alias fight='/opt/server_tools/scripts/block_bots.sh'
    alias backup='/opt/server_tools/scripts/system_backup.sh'
    alias domains='/opt/server_tools/scripts/domains.sh'
    alias antivir='bash /opt/server_tools/scripts/scan_clamav.sh'
    alias antivir-stop='bash /opt/server_tools/scripts/scan_clamav.sh --stop'
    alias antivir-status='bash /opt/server_tools/scripts/scan_clamav.sh --status'
    alias bans='cscli decisions list'
    alias banlog='cscli alerts list -l 20'
    alias chname='/opt/server_tools/scripts/change_hostname.sh'
    alias mailclean='/opt/server_tools/scripts/mail_queue.sh'
    alias wphealth='/opt/server_tools/scripts/wp_health.sh'
    alias cleanup='/opt/server_tools/scripts/disk_cleanup.sh'
    alias wpcron='/opt/server_tools/scripts/wp_cron_setup.sh'
    echo "Aliases: FastPanel server (222/109)"

# Type 3: VPN servers only
else
    alias sos='/opt/server_tools/scripts/node_audit.sh'
    alias sos120='/opt/server_tools/scripts/node_audit.sh'
    alias aw='/opt/server_tools/scripts/amnezia_stat.sh'
    echo "Aliases: VPN server"
fi

# Telegram notifications (universal)
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT_ID="${TG_CHAT_ID:-}"
tg_notify() {
    curl -s "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
        -d "chat_id=$TG_CHAT_ID" \
        -d "text=\`$(hostname)\`: $1" > /dev/null
}
