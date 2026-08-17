#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  setup_ru_109.sh | [v2026-05-01]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Main Web-109 update script (FastPanel + XRay + Aliases + mc.menu, no Cloudflare)
# Servers     : 109-RU (FastVDS 212.109.223.109)
# Usage       : bash scripts/setup_ru_109.sh
# ==========================================================================================
clear
SRV_NAME=$(hostname)
C='\033[01;97m'; G='\033[1;32m'; X='\033[0m'
echo -e "${C}======================================${X}"
echo -e "${C}  UPDATE: ${SRV_NAME} (Web-109)${X}"
echo -e "${C}  FastPanel + XRay (no Cloudflare)${X}"
echo -e "${C}  SAFE — apt/UFW/CrowdSec skipped${X}"
echo -e "${C}======================================${X}"

echo -e "\n${C}[1/4] Git repo pull...${X}"
if [ -d /root/Linux_Server_Public ]; then
  cd /root/Linux_Server_Public
  git fetch origin main
  git stash 2>/dev/null || true
  git rebase origin/main
  git stash pop 2>/dev/null || true
else
  git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public
fi
echo -e "${G}OK${X}"

echo -e "\n${C}[2/4] Updating scripts...${X}"
curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh \
  -o /usr/local/bin/sos && chmod +x /usr/local/bin/sos
cp /root/Linux_Server_Public/scripts/infooo.sh /usr/local/bin/infooo 2>/dev/null \
  || cp /root/Linux_Server_Public/109/infooo.sh /usr/local/bin/infooo 2>/dev/null || true
chmod +x /usr/local/bin/infooo 2>/dev/null || true
cp /root/Linux_Server_Public/scripts/scan_clamav.sh /usr/local/bin/antivir 2>/dev/null || true
chmod +x /usr/local/bin/antivir 2>/dev/null || true
echo -e "${G}OK: sos infooo antivir${X}"

echo -e "\n${C}[3/4] Writing .bashrc...${X}"
cat > /root/.bashrc << 'BASHEOF'
# ~/.bashrc — Web-109 | FastPanel + XRay (no Cloudflare)
# v2026-05-01 | = Rooted by VladiMIR | AI =
export PS1='\[\033[01;97m\]\u@\h:\w\$\[\033[00m\] '
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000; HISTFILESIZE=2000
shopt -s checkwinsize
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
alias sos="/usr/local/bin/sos 1h"
alias sos3="/usr/local/bin/sos 3h"
alias sos24="/usr/local/bin/sos 24h"
alias sos120="/usr/local/bin/sos 120h"
alias infooo="/usr/local/bin/infooo"
alias antivir="/usr/local/bin/antivir"
alias nginx_st="systemctl status nginx"
alias crowdsec_st="systemctl status crowdsec"
alias banlist="cscli decisions list 2>/dev/null || echo CrowdSec not installed"
alias xray_log="journalctl -u xray -n 50 --no-pager 2>/dev/null"
alias gs="git status"
alias gl="git log --oneline -10"
alias save='cd /root/Linux_Server_Public && git add -A && (git diff --cached --quiet && echo "Nothing to commit" || git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)") && git pull origin main --no-rebase --no-edit && git push origin main && echo "=== Saved ==="'
alias load='cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit && curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh -o /usr/local/bin/sos && chmod +x /usr/local/bin/sos && source ~/.bashrc && echo "=== Loaded ==="'
alias fp="cd /var/www && ll"
alias fp_log="tail -f /var/log/nginx/error.log"
alias nginx_reload="systemctl reload nginx"
alias nginx_test="nginx -t"
alias php_restart="systemctl restart php8.1-fpm 2>/dev/null || systemctl restart php-fpm 2>/dev/null || true"
alias bk="bash /root/Linux_Server_Public/109/backup_clean.sh 2>/dev/null || echo not found"
BASHEOF
echo -e "${G}OK${X}"

echo -e "\n${C}[4/4] mc.menu F2...${X}"
mkdir -p /root/.config/mc; rm -f /root/.mc.menu
cat > /root/.config/mc/menu << 'MCEOF'
+ ! t t
0    Clear screen
     clear
+ ! t t
i    infooo
     clear; /usr/local/bin/infooo; printf "\nPress any key..."; read k
+ ! t t
B    banlist (CrowdSec)
     clear; cscli decisions list 2>/dev/null || echo "CrowdSec not installed"; printf "\nPress any key..."; read k
+ ! t t
s    sos 1h
     clear; /usr/local/bin/sos 1h; printf "\nPress any key..."; read k
+ ! t t
S    sos 24h
     clear; /usr/local/bin/sos 24h; printf "\nPress any key..."; read k
+ ! t t
n    Nginx test + reload
     nginx -t && systemctl reload nginx && echo "OK"
+ ! t t
l    Nginx error log
     clear; tail -f /var/log/nginx/error.log
+ ! t t
x    Xray log
     clear; journalctl -u xray -n 50 --no-pager 2>/dev/null; printf "\nPress any key..."; read k
+ ! t t
g    Git save
     cd /root/Linux_Server_Public && git add -A && git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)" && git push origin main && echo Done
MCEOF
echo -e "${G}OK${X}"

echo -e "\n${C}======================================"
echo -e "  DONE: ${SRV_NAME} — run: source ~/.bashrc"
echo -e "======================================${X}"
source ~/.bashrc 2>/dev/null || true
sos

# = Rooted by VladiMIR | AI = v2026-05-01 = github.com/GinCz/Linux_Server_Public

