#!/bin/bash
# =============================================================================
# vpn_aliases.sh — Aliases for VPN nodes (AmneziaWG / Xray)
# Version     : v2026-04-30
# Usage       : sourced from ~/.bashrc
# Update      : load (git pull → auto-installs scripts → source .bashrc)
# = Rooted by VladiMIR | AI =
# =============================================================================

# PS1: use color set at install time (VPN_PS1_COLOR), default bright cyan
export PS1="\[\033[${VPN_PS1_COLOR:-01;96m}\]\u@\h:\w\$\[\033[00m\] "

alias 00='clear'
alias infooo='/usr/local/bin/infooo'
alias antivir='/usr/local/bin/antivir'

# --- SOS (universal server audit, same script as on 222) ---
alias sos='/usr/local/bin/sos 1h'
alias sos3='/usr/local/bin/sos 3h'
alias sos24='/usr/local/bin/sos 24h'
alias sos120='/usr/local/bin/sos 120h'

# --- AmneziaWG ---
alias aw='docker exec amnezia-awg wg show 2>/dev/null || echo "AmneziaWG not running"'

# --- CrowdSec ---
alias banlog='bash /root/Linux_Server_Public/222/banlog.sh 30 2>/dev/null || cscli decisions list 2>/dev/null || echo "CrowdSec not installed"'
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --ip'

# --- VPN backup (local to this node) ---
alias backup='bash /root/Linux_Server_Public/VPN/vpn_backup.sh'

# --- Navigation ---
alias grep='grep --color=auto'
alias ls='ls --color=auto -h'
alias ll='ls -lh --color=auto'
alias la='ls -Ah --color=auto'
alias mc='/usr/bin/mc'

# --- Git (rock-solid: auto-stash) ---
alias save='cd /root/Linux_Server_Public \
  && git add -A \
  && (git diff --cached --quiet && echo "Nothing to commit" \
    || git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)") \
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
  && chmod -x /etc/update-motd.d/* 2>/dev/null; true \
  && > /etc/motd \
  && [[ -f /root/Linux_Server_Public/scripts/server_audit.sh ]] \
       && cp /root/Linux_Server_Public/scripts/server_audit.sh /usr/local/bin/sos \
       && chmod +x /usr/local/bin/sos || true \
  && cp /root/Linux_Server_Public/222/infooo.sh /usr/local/bin/infooo \
  && chmod +x /usr/local/bin/infooo \
  && cp /root/Linux_Server_Public/scripts/f2.sh /usr/local/bin/f2 \
  && chmod +x /usr/local/bin/f2 \
  && source ~/.bashrc \
  && echo "=== Loaded (VPN) ==="'
