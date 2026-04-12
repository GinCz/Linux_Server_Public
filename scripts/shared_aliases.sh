# shared_aliases.sh — Universal aliases for all servers (VPN + WWW)
# Version: v2026-04-12
# Sourced by 222/.bashrc and 109/.bashrc on each server via:
#   source /root/Linux_Server_Public/scripts/shared_aliases.sh
# = Rooted by VladiMIR | AI =

# ── Git ───────────────────────────────────────────────────────────────────────────────
# load — pull from GitHub + reload .bashrc
#   - If remote has new commits: rebase local on top of them
#   - If nothing to pull: just reload .bashrc silently
#   - Never fails on "already up to date" or conflicts (rebase auto-resolves)
alias load='cd /root/Linux_Server_Public \
  && git fetch origin main \
  && git rebase origin/main \
  && source /root/Linux_Server_Public/222/.bashrc \
  && echo "=== Loaded from GitHub ==="'

# save — commit + push
#   - If nothing to commit: skips commit silently (git commit returns 1 = nothing staged,
#     but || true makes the push run anyway so branch stays in sync)
#   - If remote is ahead: pull --rebase first, then push
#   - Full error-tolerant chain: nothing stops if a step has "nothing to do"
alias save='cd /root/Linux_Server_Public \
  && git add -A \
  && git commit -m "Save $(date +%Y-%m-%d_%H:%M)" || true \
  && git pull --rebase \
  && git push \
  && echo "=== Saved to GitHub ==="'

# ── AmneziaWG stats ─────────────────────────────────────────────────────────────────
# aw — show all WireGuard peers traffic + active last 15 min
alias aw='bash /root/Linux_Server_Public/VPN/amnezia_stat.sh'

# ── Navigation & colors ───────────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias ls='ls --color=auto -h'
alias ll='ls -lh --color=auto'
alias la='ls -Ah --color=auto'
alias l='ls -CFh'
alias 00='clear'

# ── Midnight Commander ────────────────────────────────────────────────────────────────
alias mc='/usr/bin/mc'
