# ~/.bashrc — 222-DE-NetCup
# Version: v2026-03-26
# PS1 color: YELLOW
# = Rooted by VladiMIR | AI =

export PS1='\[\033[01;33m\]\u@\h:\w\$\[\033[00m\] '

# [ -z "$PS1" ] && return  # commented out — was blocking aliases in new sessions

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# --- Server-specific aliases ---
alias sos='bash /root/Linux_Server_Public/222/sos.sh 1h'
alias sos3='bash /root/Linux_Server_Public/222/sos.sh 3h'
alias sos24='bash /root/Linux_Server_Public/222/sos.sh 24h'
alias sos120='bash /root/Linux_Server_Public/222/sos.sh 120h'
alias i='bash /root/Linux_Server_Public/222/infooo.sh'
alias d='bash /root/Linux_Server_Public/222/domains.sh'
alias fight='bash /root/Linux_Server_Public/222/block_bots.sh'
alias wpcron='bash /root/Linux_Server_Public/222/run_all_wp_cron.sh'
alias cronwp='bash /root/Linux_Server_Public/222/run_all_wp_cron.sh'
alias watchdog='bash /root/Linux_Server_Public/222/php_fpm_watchdog.sh'
alias backup='bash /root/Linux_Server_Public/222/system_backup.sh'
alias antivir='bash /root/Linux_Server_Public/222/scan_clamav.sh'
alias mailclean='bash /root/Linux_Server_Public/222/mailclean.sh'
alias wphealth='bash /root/Linux_Server_Public/222/wphealth.sh'
alias cleanup='bash /root/Linux_Server_Public/222/server_cleanup.sh'
alias aws-test='bash /root/Linux_Server_Public/222/aws_test.sh'
alias banlog='cscli alerts list -l 20'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias m='mc'
alias 00='clear'

# --- Crypto-bot Docker aliases (v2026-03-26) ---
# ВАЖНО: alias 'tr' НЕ используется — это системная утилита Linux (translate characters)
# Вместо этого используется alias 'bot'
alias bot='bash /root/crypto-docker/scripts/tr_docker.sh'
alias reset='bash /root/crypto-docker/scripts/reset.sh'
# deploy — НЕ alias! Только для свежей установки: bash /root/crypto-docker/scripts/deploy.sh
alias torg='bash /root/crypto-docker/scripts/torg.sh 1'
alias torg1='bash /root/crypto-docker/scripts/torg.sh 1'
alias torg3='bash /root/crypto-docker/scripts/torg.sh 3'
alias torg24='bash /root/crypto-docker/scripts/torg.sh 24'
alias torg120='bash /root/crypto-docker/scripts/torg.sh 120'
alias clog='docker logs crypto-bot --tail 40'
alias clog100='docker logs crypto-bot --tail 100'

# --- Shared aliases (load / save / aw / vpnstat) ---
source /root/Linux_Server_Public/scripts/shared_aliases.sh
