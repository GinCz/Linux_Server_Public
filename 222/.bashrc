# ~/.bashrc — 222-DE-NetCup (152.53.182.222)
# Version: v2026-04-13
# PS1 color: YELLOW (01;33m)
# = Rooted by VladiMIR | AI =
#
# HOW TO APPLY:
#   source /root/Linux_Server_Public/222/.bashrc
# HOW TO SAVE TO REPO:
#   cd /root/Linux_Server_Public && save

export PS1='\[\033[01;33m\]\u@\h:\w\$\[\033[00m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# --- SOS: Server Health Monitor ---
# Usage: sos | sos1 | sos3 | sos24 | sos120
# Script: /root/Linux_Server_Public/222/sos.sh
alias sos='bash /root/Linux_Server_Public/222/sos.sh 1h'
alias sos1='bash /root/Linux_Server_Public/222/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/222/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/222/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/222/sos.sh 120h'

# --- Quick commands ---
alias 00='clear'
alias infooo='bash /root/Linux_Server_Public/222/infooo.sh'
alias domains='bash /root/Linux_Server_Public/222/domains.sh'
alias fight='bash /root/Linux_Server_Public/222/block_bots.sh'
alias watchdog='bash /root/Linux_Server_Public/222/php_fpm_watchdog.sh'
alias backup='bash /root/backup_clean.sh'
alias antivir='bash /root/Linux_Server_Public/222/scan_clamav.sh'
alias mailclean='bash /root/Linux_Server_Public/222/mailclean.sh'
alias cleanup='bash /root/Linux_Server_Public/222/server_cleanup.sh'
alias aws-test='bash /root/Linux_Server_Public/222/aws_test.sh'
alias allinfo='bash /root/Linux_Server_Public/222/all_servers_info.sh'
alias nginx-reload='nginx -t && systemctl reload nginx && echo "Nginx reloaded"'

# --- CrowdSec ---
alias banlog='bash /root/Linux_Server_Public/222/banlog.sh 30'
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --ip'

# --- WordPress ---
alias wpupd='bash /root/Linux_Server_Public/222/wp_update_all.sh'
alias wpcron='bash /root/Linux_Server_Public/222/run_all_wp_cron.sh'
alias wphealth='bash /root/Linux_Server_Public/222/wphealth.sh'

# --- Crypto-bot Docker ---
alias tr='bash /root/crypto-docker/scripts/tr_docker.sh'
alias reset='bash /root/crypto-docker/scripts/reset.sh'
alias clog='docker logs crypto-bot --tail 40'
alias clog100='docker logs crypto-bot --tail 100'
alias f5bot='bash /root/docker_backup.sh'
alias f9bot='bash /root/Linux_Server_Public/222/crypto_restore.sh'

# --- VPN Docker Backup & Restore ---
alias f5vpn='bash /root/Linux_Server_Public/VPN/vpn_docker_backup.sh'
alias vpn-restore='bash /root/Linux_Server_Public/VPN/vpn_restore_v2026-04-13.sh'

# --- Git repos ---
alias secret='cd /root/Linux_Server_Public && git -C /root/Secret_Privat pull --rebase 2>/dev/null || echo "Private repo not found at /root/Secret_Privat"'
alias repo='cd /root/Linux_Server_Public && git pull --rebase && source /root/Linux_Server_Public/222/.bashrc && echo "=== Public repo loaded ==="'

# --- Shared aliases (load / save / aw / grep / ls / mc) ---
source /root/Linux_Server_Public/scripts/shared_aliases.sh
