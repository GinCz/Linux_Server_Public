# shared_aliases.sh — Universal aliases for all servers
# Version: v2026-03-31
# Sourced by /root/.bashrc on each server
# DO NOT put server-specific paths here — those go in each server's .bashrc
# = Rooted by VladiMIR | AI =

# Git: load from GitHub / save to GitHub
alias load='cd /root/Linux_Server_Public && git pull --rebase && source /root/.bashrc && echo "=== Loaded from GitHub ==="'
alias save='cd /root/Linux_Server_Public && git add . && git commit -m "Save $(date +%Y-%m-%d_%H:%M)" && git push && echo "=== Saved to GitHub ==="'

# AmneziaWG / WireGuard stats
alias aw='bash /root/Linux_Server_Public/scripts/amnezia_stat.sh'

# Colors & navigation
alias grep='grep --color=auto'
alias ls='ls --color=auto -h'
alias ll='ls -lh --color=auto'
alias la='ls -Ah --color=auto'
alias l='ls -CFh'
alias 00='clear'

# Midnight Commander
alias mc='/usr/bin/mc'
