# shared_aliases.sh — Universal aliases for all servers (VPN + WWW)
# Version: v2026-04-07
# Sourced by /root/.bashrc on each server via:
#   source /root/Linux_Server_Public/scripts/shared_aliases.sh
# = Rooted by VladiMIR | AI =

# ── Git ───────────────────────────────────────────────────────────────────────
# load — git pull + reload .bashrc
alias load='cd /root/Linux_Server_Public && git pull --rebase && source /root/.bashrc && echo "=== Loaded from GitHub ==="'
# save — git add + commit + push
alias save='cd /root/Linux_Server_Public && git add . && git commit -m "Save $(date +%Y-%m-%d_%H:%M)" && git push && echo "=== Saved to GitHub ==="'

# ── AmneziaWG stats ───────────────────────────────────────────────────────────
# aw — show all WireGuard peers traffic + active last 15 min
# Script path: /root/Linux_Server_Public/VPN/amnezia_stat.sh
alias aw='bash /root/Linux_Server_Public/VPN/amnezia_stat.sh'

# ── Navigation & colors ───────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias ls='ls --color=auto -h'
alias ll='ls -lh --color=auto'
alias la='ls -Ah --color=auto'
alias l='ls -CFh'
alias 00='clear'

# ── Midnight Commander ────────────────────────────────────────────────────────
# mc — file manager (replaces old alias 'm')
alias mc='/usr/bin/mc'
