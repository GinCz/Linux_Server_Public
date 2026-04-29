# shared_aliases.sh — Universal aliases for all servers
# Version: v2026-04-30
# Sourced by each server's .bashrc via:
#   source /root/Linux_Server_Public/scripts/shared_aliases.sh
# = Rooted by VladiMIR | AI =
#
# NOTE: alias "load" is defined in each server's .bashrc individually
#       because it must source the correct server-specific .bashrc.

# ── Git: save ─ commit + push (rock-solid) ───────────────────────────────────────────
alias save='cd /root/Linux_Server_Public \
  && git add -A \
  && (git diff --cached --quiet && echo "Nothing to commit" || git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)") \
  && git fetch origin main \
  && (git stash 2>/dev/null; git rebase origin/main; git stash pop 2>/dev/null || true) \
  && git push origin main \
  && echo "=== Saved to GitHub ==="'

# ── Navigation & colors ─────────────────────────────────────────────────────
alias grep='grep --color=auto'
alias ls='ls --color=auto -h'
alias ll='ls -lh --color=auto'
alias la='ls -Ah --color=auto'
alias l='ls -CFh'
alias 00='clear'

# ── Midnight Commander ──────────────────────────────────────────────────
alias mc='/usr/bin/mc'
