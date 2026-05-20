# =============================================================
# server_222.sh — EU NetCup Server (152.53.182.222)
# Aliases only — MOTD handled by .bash_profile
# = Rooted by VladiMIR + AI | v.2026.05.21 | github.com/GinCz =
# =============================================================

alias wpupd='bash /root/wp_update_all.sh'
alias 00='clear'

# Добавь сюда остальные нужные алиасы при необходимости
alias nginx-reload='nginx -s reload'
alias fpm-reload='systemctl restart php8.3-fpm'
alias reload-all='nginx -s reload && systemctl restart php8.3-fpm'
