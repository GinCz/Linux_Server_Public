# shared_aliases.sh — Universal aliases for all servers (VPN + WWW)
# Version: v2026-04-10
# Sourced by 222/.bashrc and 109/.bashrc on each server via:
#   source /root/Linux_Server_Public/scripts/shared_aliases.sh
# = Rooted by VladiMIR | AI =

# ── Git ───────────────────────────────────────────────────────────────────────
# load — git pull + reload .bashrc FROM REPO (not /root/.bashrc!)
# .bash_profile loads /root/Linux_Server_Public/222/.bashrc (or 109/.bashrc)
# so we must source that file, not the system one
alias load='cd /root/Linux_Server_Public && git pull --rebase && source /root/Linux_Server_Public/222/.bashrc && echo "=== Loaded from GitHub ==="'

# save — git add + commit + push
alias save='cd /root/Linux_Server_Public && git add . && git commit -m "Save $(date +%Y-%m-%d_%H:%M)" && git push && echo "=== Saved to GitHub ==="'

# ── AmneziaWG stats ───────────────────────────────────────────────────────────
# aw — show all WireGuard peers traffic + active last 15 min
alias aw='bash /root/Linux_Server_Public/VPN/amnezia_stat.sh'

# ── Navigation & colors ───────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias ls='ls --color=auto -h'
alias ll='ls -lh --color=auto'
alias la='ls -Ah --color=auto'
alias l='ls -CFh'
alias 00='clear'

# ── Midnight Commander ────────────────────────────────────────────────────────
alias mc='/usr/bin/mc'
