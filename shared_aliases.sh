#!/usr/bin/env bash
# Script:  shared_aliases.sh
# Version: v2026-03-18
# Purpose: Shared aliases for all server types. Sourced by ~/.bashrc for root and adminer.
#          Different sets for Type 1 (222), Type 2 (109), Type 3 (VPN).
# Usage:   source /opt/server_tools/shared_aliases.sh

# Universal for all server types
alias 00='clear'
alias infooo='sudo /opt/server_tools/scripts/infooo.sh'
alias load='bash /opt/server_tools/scripts/load.sh'
alias save='bash /opt/server_tools/scripts/save.sh'
alias audit='sudo /opt/server_tools/scripts/full_audit.sh'
alias aws-test='sudo /opt/server_tools/scripts/aws_region_test.sh'

# Type 1 & 2: FastPanel servers (222 and 109)
if [[ "$(hostname)" =~ "222" ]] || [[ "$(hostname)" =~ "109" ]]; then
    alias sos='sudo /opt/server_tools/scripts/server_audit.sh'
    alias sos1='sudo /opt/server_tools/scripts/server_audit.sh 1'
    alias sos3='sudo /opt/server_tools/scripts/server_audit.sh 3'
    alias sos24='sudo /opt/server_tools/scripts/server_audit.sh 24'
    alias sos120='sudo /opt/server_tools/scripts/server_audit.sh 120'
    alias aw='sudo /opt/server_tools/scripts/amnezia_stat.sh'
    alias fight='sudo /opt/server_tools/scripts/block_bots.sh'
    alias backup='sudo /opt/server_tools/scripts/system_backup.sh'
    alias domains='sudo /opt/server_tools/scripts/domains.sh'
    alias antivir='cscli decisions list'
    alias banlog='cscli alerts list -l 20'
    alias 303='sudo /opt/server_tools/scripts/log_303.sh'
    alias chname='sudo /opt/server_tools/scripts/change_hostname.sh'
    alias mailclean='sudo /opt/server_tools/scripts/mail_queue.sh'
    echo "Aliases: FastPanel server (222/109)"

# Type 3: VPN servers only
else
    alias sos='sudo /opt/server_tools/scripts/node_audit.sh'
    alias sos120='sudo /opt/server_tools/scripts/node_audit.sh'
    alias aw='sudo /opt/server_tools/scripts/amnezia_stat.sh'
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
