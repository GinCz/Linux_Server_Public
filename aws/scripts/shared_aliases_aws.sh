#!/usr/bin/env bash
# Script:  shared_aliases_aws.sh
# Version: v2026-03-19
# Purpose: Aliases for AWS EC2 Ubuntu server.
#          Adapted from shared_aliases.sh - uses sudo where needed,
#          home dir is /home/ubuntu (not /root).
# Usage:   source /opt/server_tools/scripts/shared_aliases_aws.sh

alias 00='clear'
alias load='source /opt/server_tools/scripts/shared_aliases_aws.sh && echo "Aliases reloaded (AWS)"'
alias 303='bash /opt/server_tools/scripts/log_303.sh'
alias infooo='bash /opt/server_tools/scripts/infooo.sh'
alias audit='bash /opt/server_tools/scripts/full_audit.sh'
alias antivir='bash /opt/server_tools/scripts/aws/scan_clamav_aws.sh'
alias save='cd /opt/server_tools && sudo git add -A && sudo git commit -m "v$(date +%Y-%m-%d) update from aws" && sudo git push'
alias update='cd /opt/server_tools && sudo git fetch origin && sudo git reset --hard origin/main && source /opt/server_tools/scripts/shared_aliases_aws.sh'

# Crypto bot shortcuts
alias bot-deploy='cd ~/aws-setup && bash scripts/deploy.sh'
alias bot-status='pgrep -a python3'
alias bot-log='tail -f ~/aws-setup/app.log'
alias bot-scanner='tail -f ~/aws-setup/scanner.log'
alias bot-trade='tail -f ~/aws-setup/trade_engine.log'
alias bot-stop='pkill -f python3 && echo "Bot stopped"'

echo "Aliases: AWS EC2 Ubuntu server"
