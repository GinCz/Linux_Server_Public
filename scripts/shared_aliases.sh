# shared_aliases.sh — Universal aliases for all servers
# Version: v2026-03-24
# Sourced by /root/.bashrc on each server
# DO NOT put server-specific paths here — those go in each server's .bashrc

# Git: load from GitHub / save to GitHub
alias load='cd /root/Linux_Server_Public && git pull --rebase && echo "=== Loaded from GitHub ==="'
alias save='cd /root/Linux_Server_Public && git add . && git commit -m "Save $(date +%Y-%m-%d_%H:%M)" && git push && echo "=== Saved to GitHub ==="'

# Common tools
alias banlog='cscli alerts list -l 20'
alias ls='ls --color=auto'
alias grep='grep --color=auto'
alias la='ls -A'
alias l='ls -CF'
alias m='mc'
alias 00='clear'
