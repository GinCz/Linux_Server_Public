# ~/.bashrc — EU-4Ton-237
# Type: VPN Xray + Samba (NO AmneziaWG, NO AdGuard)
# Version: v2026-05-01 | Color: Bright Cyan
# = Rooted by VladiMIR | AI =
#
# INSTALL:
#   cp /root/Linux_Server_Public/VPN/bashrc_237.sh /root/.bashrc
#   source ~/.bashrc

export PS1='\[\033[01;96m\]\u@\h:\w$\[\033[00m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# ── Navigation & shell ──────────────────────────────────────
alias 00="clear"
alias grep="grep --color=auto"
alias ls="ls --color=auto -h"
alias ll="ls -lh --color=auto"
alias la="ls -Ah --color=auto"
alias mc="/usr/bin/mc"
alias df="df -h"
alias du="du -sh"
alias ports="ss -tulnp"
alias myip="curl -s ifconfig.me && echo"
alias topcpu="ps aux --sort=-%cpu | head -10"
alias topmem="ps aux --sort=-%mem | head -10"

# ── Monitoring ───────────────────────────────────────────────
alias sos="/usr/local/bin/sos 1h"
alias sos3="/usr/local/bin/sos 3h"
alias sos24="/usr/local/bin/sos 24h"
alias sos120="/usr/local/bin/sos 120h"
alias infooo="/usr/local/bin/infooo"
alias antivir="/usr/local/bin/antivir"

# ── Git: save / load ────────────────────────────────────────
alias save='cd /root/Linux_Server_Public \
  && git add -A \
  && (git diff --cached --quiet && echo "Nothing to commit" \
    || git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)") \
  && git pull origin main --no-rebase --no-edit \
  && git push origin main \
  && echo "=== Saved to GitHub ==="'
alias load='cd /root/Linux_Server_Public \
  && git pull origin main --no-rebase --no-edit \
  && curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh \
       -o /usr/local/bin/sos && chmod +x /usr/local/bin/sos \
  && source ~/.bashrc \
  && echo "=== Loaded + sos updated ==="'

# ── Xray VPN ─────────────────────────────────────────────────
alias xray_st="systemctl status xray"
alias xray_log="journalctl -u xray -n 50 --no-pager"
alias xray_restart="systemctl restart xray"

# ── Samba ────────────────────────────────────────────────────
alias smb_st="systemctl status smbd nmbd"
alias smb_who="smbstatus --brief 2>/dev/null || echo 'Samba not responding'"
alias smb_restart="systemctl restart smbd nmbd && echo 'Samba restarted'"
alias smb_log="journalctl -u smbd -n 50 --no-pager"
alias smb_shares="net usershare list 2>/dev/null || testparm -s 2>/dev/null | grep '\[' | grep -v global"

# ── Security ────────────────────────────────────────────────
alias crowdsec_st="systemctl status crowdsec"
alias banlist="cscli decisions list 2>/dev/null || echo 'CrowdSec not installed'"
alias f2b_st="systemctl status fail2ban 2>/dev/null || echo 'fail2ban not installed'"
alias gs="git status"
alias gl="git log --oneline -10"
