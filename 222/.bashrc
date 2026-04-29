# ~/.bashrc — 222-DE-NetCup (152.53.182.222)
# Version: v2026-04-30
# PS1 color: YELLOW (01;33m)
# = Rooted by VladiMIR | AI =

export PS1='\[\033[01;33m\]\u@\h:\w\$\[\033[00m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# --- Quick commands ---
alias 00='clear'
alias infooo='bash /root/Linux_Server_Public/222/infooo.sh'
alias allinfo='bash /root/Linux_Server_Public/222/all_servers_info.sh'
alias domains='bash /root/Linux_Server_Public/222/domains.sh'
alias fight='bash /root/Linux_Server_Public/222/block_bots.sh'
alias watchdog='bash /root/Linux_Server_Public/222/php_fpm_watchdog.sh'
alias backup='bash /root/backup_clean.sh'
alias antivir='bash /root/Linux_Server_Public/222/scan_clamav.sh'
alias mailclean='bash /root/Linux_Server_Public/222/mailclean.sh'
alias cleanup='bash /root/Linux_Server_Public/222/server_cleanup.sh'
alias aws-test='bash /root/Linux_Server_Public/222/aws_test.sh'
alias nginx-reload='nginx -t && systemctl reload nginx && echo "Nginx reloaded"'

# --- CrowdSec ---
alias banlog='bash /root/Linux_Server_Public/222/banlog.sh 30'
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --ip'

# --- WordPress ---
alias wpupd='bash /root/Linux_Server_Public/222/wp_update_all.sh'
alias wpcron='bash /root/Linux_Server_Public/222/run_all_wp_cron.sh'
alias wphealth='bash /root/Linux_Server_Public/222/wphealth.sh'

# --- Crypto-bot Docker ---
alias tr='bash /root/crypto-docker/scripts/tr_docker.sh'
alias reset='bash /root/crypto-docker/scripts/reset.sh'
alias clog='docker logs crypto-bot --tail 40'
alias clog100='docker logs crypto-bot --tail 100'
alias f5bot='bash /root/docker_backup.sh'
alias f9bot='bash /root/Linux_Server_Public/222/crypto_restore.sh'

# --- Backup / Restore (interactive) ---
alias f5servers='bash /root/Linux_Server_Public/222/f5servers.sh'
alias f9servers='bash /root/Linux_Server_Public/222/f9servers.sh'

# --- Xray backup (all nodes) ---
alias f5xray='bash /root/Linux_Server_Public/VPN/xray_backup_all_nodes_v2026-04-28.sh'

# --- SOS health monitor ---
alias sos='/usr/local/bin/sos 1h'
alias sos1='/usr/local/bin/sos 1h'
alias sos3='/usr/local/bin/sos 3h'
alias sos24='/usr/local/bin/sos 24h'
alias sos120='/usr/local/bin/sos 120h'

# --- Git repos ---
alias repo='cd /root/Linux_Server_Public && git pull --rebase && source /root/Linux_Server_Public/222/.bashrc && echo "=== Public repo loaded ==="'

# --- Shared aliases (save / grep / ls / mc) ---
source /root/Linux_Server_Public/scripts/shared_aliases.sh

# --- load: pull + stash auto + reload .bashrc + update MOTD (rock-solid) ---
alias load='cd /root/Linux_Server_Public \
  && git fetch origin main \
  && (git stash 2>/dev/null || true) \
  && git rebase origin/main \
  && (git stash pop 2>/dev/null || true) \
  && cp /root/Linux_Server_Public/222/motd_server.sh /etc/profile.d/motd_server.sh \
  && chmod +x /etc/profile.d/motd_server.sh \
  && bash /root/Linux_Server_Public/222/mc_menu_setup.sh \
  && source /root/Linux_Server_Public/222/.bashrc \
  && echo "=== Loaded from GitHub (222) ==="'
