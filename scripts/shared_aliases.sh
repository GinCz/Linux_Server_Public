# shared_aliases.sh — Universal aliases for all servers (VPN + WWW)
# Version: v2026-04-27
# Sourced by 222/.bashrc and 109/.bashrc on each server via:
#   source /root/Linux_Server_Public/scripts/shared_aliases.sh
# = Rooted by VladiMIR | AI =
#
# NOTE: alias "load" is defined individually in each server's .bashrc
#       because it must source the correct server-specific .bashrc file.
#       Do NOT add "load" here — it will override the correct server version.

# ── Git: save — commit + push ─────────────────────────────────────────────────
# - If nothing to commit: skips commit silently (|| true ignores exit code 1)
# - If remote is ahead: pull --rebase first, then push
# - Full error-tolerant chain: nothing stops if a step has "nothing to do"
alias save='cd /root/Linux_Server_Public \
  && git add -A \
  && git commit -m "Save $(date +%Y-%m-%d_%H:%M)" || true \
  && git pull --rebase \
  && git push \
  && echo "=== Saved to GitHub ==="'

# ── AmneziaWG stats ──────────────────────────────────────────────────────────
# aw — show all WireGuard peers traffic + active last 15 min
alias aw='bash /root/Linux_Server_Public/VPN/amnezia_stat.sh'

# ── Navigation & colors ──────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias ls='ls --color=auto -h'
alias ll='ls -lh --color=auto'
alias la='ls -Ah --color=auto'
alias l='ls -CFh'
alias 00='clear'

# ── Midnight Commander ───────────────────────────────────────────────────────
alias mc='/usr/bin/mc'
