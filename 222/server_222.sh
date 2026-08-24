#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  server_222.sh | [v2026-05-21]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Aliases and shortcuts for EU NetCup Server 222-DE
# Servers     : 222-DE NetCup (152.53.182.222)
# Usage       : source 222/server_222.sh
# ==========================================================================================

alias wpupd='bash /root/wp_update_all.sh'
alias servers_stat='bash /root/Linux_Server_Public/scripts/servers_stat.sh'
alias stars='servers_stat'

# Additional management aliases
alias nginx-reload='nginx -s reload'
alias fpm-reload='systemctl restart php8.3-fpm'
alias reload-all='nginx -s reload && systemctl restart php8.3-fpm'

# = Rooted by VladiMIR | AI = v2026-05-21 = github.com/GinCz/Linux_Server_Public

