# ~/.bashrc — 109-RU-FastVDS (212.109.223.109)
# Version: v2026-04-27
# PS1 color: light pink (38;5;217m)
# = Rooted by VladiMIR | AI =
#
# HOW TO APPLY:
#   source /root/Linux_Server_Public/109/.bashrc
# HOW TO SAVE TO REPO:
#   cd /root/Linux_Server_Public && save

export PS1='\[\e[38;5;217m\]\u@\h:\w\$\[\e[m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# --- SOS: Server Health Monitor ---

# --- Quick commands ---
alias 00='clear'
alias infooo='bash /root/Linux_Server_Public/109/infooo.sh'
alias domains='bash /root/Linux_Server_Public/109/domains.sh'
alias fight='bash /root/Linux_Server_Public/109/block_bots.sh'
alias watchdog='bash /root/Linux_Server_Public/109/php_fpm_watchdog.sh'
alias backup='bash /root/Linux_Server_Public/109/system_backup.sh'
alias antivir='bash /root/Linux_Server_Public/109/scan_clamav.sh'
alias mailclean='bash /root/Linux_Server_Public/109/mailclean.sh'
alias cleanup='bash /root/Linux_Server_Public/109/server_cleanup.sh'
alias aws-test='bash /root/Linux_Server_Public/109/aws_test.sh'
alias allinfo='bash /root/Linux_Server_Public/109/all_servers_info.sh'
alias nginx-reload='nginx -t && systemctl reload nginx && echo "OK nginx reloaded"'
alias fpm-reload='php-fpm8.3 -t && systemctl reload php8.3-fpm && echo "OK php8.3-fpm reloaded"'
alias reload-all='php-fpm8.3 -t && systemctl reload php8.3-fpm && sleep 1 && nginx -t && systemctl reload nginx && echo "OK all reloaded"'

# --- CrowdSec ---
alias banlog='bash /root/Linux_Server_Public/109/banlog.sh 30'
alias banlog50='bash /root/Linux_Server_Public/109/banlog.sh 50'
alias banunblock='cscli decisions delete --ip'
alias banblock='cscli decisions add --ip'

# --- WordPress ---
alias wpupd='bash /root/Linux_Server_Public/109/wp_update_all.sh'
alias wpcron='bash /root/Linux_Server_Public/109/run_all_wp_cron.sh'
alias wphealth='bash /root/Linux_Server_Public/109/wphealth.sh'

# --- Shared aliases (save / aw / grep / ls / mc) ---
# NOTE: load is defined HERE (not in shared_aliases.sh) so it always
#       sources the correct server-specific .bashrc (109) after git pull
source /root/Linux_Server_Public/scripts/shared_aliases.sh

# --- load: pull from GitHub + reload THIS server's .bashrc + update MOTD ---
# Defined AFTER source shared_aliases.sh to override any accidental definition there.
# Steps:
#   1. cd to repo
#   2. fetch + rebase (safe pull, no merge commits)
#   3. copy updated motd_server.sh to /etc/profile.d/ so next SSH login shows new menu
#   4. source this .bashrc to reload all aliases and PS1
alias load='cd /root/Linux_Server_Public \
  && git fetch origin main \
  && git rebase origin/main \
  && cp /root/Linux_Server_Public/109/motd_server.sh /etc/profile.d/motd_server.sh \
  && chmod +x /etc/profile.d/motd_server.sh \
  && source /root/Linux_Server_Public/109/.bashrc \
  && echo "=== Loaded from GitHub (109) ==="'
alias sos='/usr/local/bin/sos 1h'
alias sos1='/usr/local/bin/sos 1h'
alias sos3='/usr/local/bin/sos 3h'
alias sos24='/usr/local/bin/sos 24h'
alias sos120='/usr/local/bin/sos 120h'
