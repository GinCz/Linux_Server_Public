#!/bin/bash
# =============================================================================
# vpn_aliases.sh — Aliases for VPN nodes (AmneziaWG / Xray)
# Version     : v2026-04-30
# Usage       : sourced from ~/.bashrc
# Update      : load (git pull → auto-installs scripts → source .bashrc)
# = Rooted by VladiMIR | AI =
# =============================================================================

alias 00='clear'
alias infooo='/usr/local/bin/infooo'
alias audit='/usr/local/bin/audit'
alias antivir='/usr/local/bin/antivir'
alias f2='/usr/local/bin/f2'

# --- AmneziaWG ---
alias aw='docker exec amnezia-awg wg show 2>/dev/null || echo "AmneziaWG not running"'

# --- CrowdSec ---
alias banlog='bash /root/Linux_Server_Public/222/banlog.sh 30 2>/dev/null || cscli decisions list 2>/dev/null || echo "CrowdSec not installed"'
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --ip'

# --- Backup / Restore ---
alias backup='bash /root/Linux_Server_Public/VPN/vpn_backup.sh'
alias f5servers='bash /root/Linux_Server_Public/222/f5servers.sh'
alias f9servers='bash /root/Linux_Server_Public/222/f9servers.sh'

# --- Navigation ---
alias grep='grep --color=auto'
alias ls='ls --color=auto -h'
alias ll='ls -lh --color=auto'
alias la='ls -Ah --color=auto'
alias mc='/usr/bin/mc'

# --- Git ---
alias save='cd /root/Linux_Server_Public \
  && git add -A \
  && (git diff --cached --quiet && echo "Nothing to commit" || git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)") \
  && git fetch origin main \
  && (git stash 2>/dev/null || true) \
  && git rebase origin/main \
  && (git stash pop 2>/dev/null || true) \
  && git push origin main \
  && echo "=== Saved ==="'

alias load='cd /root/Linux_Server_Public \
  && git fetch origin main \
  && (git stash 2>/dev/null || true) \
  && git rebase origin/main \
  && (git stash pop 2>/dev/null || true) \
  && cp /root/Linux_Server_Public/scripts/motd_vpn.sh /etc/profile.d/motd_server.sh \
  && chmod +x /etc/profile.d/motd_server.sh \
  && cp /root/Linux_Server_Public/scripts/vpn_audit.sh /usr/local/bin/audit \
  && chmod +x /usr/local/bin/audit \
  && cp /root/Linux_Server_Public/scripts/f2.sh /usr/local/bin/f2 \
  && chmod +x /usr/local/bin/f2 \
  && cp /root/Linux_Server_Public/222/infooo.sh /usr/local/bin/infooo \
  && chmod +x /usr/local/bin/infooo \
  && source ~/.bashrc \
  && echo "=== Loaded (VPN) ==="'
