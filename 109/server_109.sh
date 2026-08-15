#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  server_109.sh | [v2026-05-21]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Comprehensive 109 server status and diagnostic inspector
# Servers     : 109-RU FastVDS
# Usage       : bash 109/server_109.sh
# ==========================================================================================

# ───────────────────────────────────────────────────────────────────────────────
# [1] SHELL ALIASES — sourced by /root/.bashrc
# ───────────────────────────────────────────────────────────────────────────────
_aliases_109() {
  export PS1='\[\e[38;5;217m\]\u@\h:\w\$\[\e[m\] '

  HISTCONTROL=ignoredups:ignorespace
  shopt -s histappend
  HISTSIZE=1000
  HISTFILESIZE=2000
  shopt -s checkwinsize

  alias sos='bash /root/Linux_Server_Public/109/sos.sh 1h'
  alias sos1='bash /root/Linux_Server_Public/109/sos.sh 1h'
  alias sos3='bash /root/Linux_Server_Public/109/sos.sh 3h'
  alias sos24='bash /root/Linux_Server_Public/109/sos.sh 24h'
  alias sos120='bash /root/Linux_Server_Public/109/sos.sh 120h'

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
  alias nginx-reload='nginx -t && systemctl reload nginx && echo "OK nginx reloaded"'
  alias fpm-reload='php-fpm8.3 -t && systemctl reload php8.3-fpm && echo "OK php8.3-fpm reloaded"'
  alias reload-all='php-fpm8.3 -t && systemctl reload php8.3-fpm && sleep 1 && nginx -t && systemctl reload nginx && echo "OK all reloaded"'

  alias banlog='bash /root/Linux_Server_Public/109/banlog.sh 30'
  alias banlog50='bash /root/Linux_Server_Public/109/banlog.sh 50'
  alias banunblock='cscli decisions delete --ip'
  alias banblock='cscli decisions add --ip'

  alias wpupd='bash /root/Linux_Server_Public/109/wp_update_all.sh'
  alias wpcron='bash /root/Linux_Server_Public/109/run_all_wp_cron.sh'
  alias wphealth='bash /root/Linux_Server_Public/109/wphealth.sh'

  alias secret='cd /root/Linux_Server_Public && git -C /root/Secret_Privat pull --rebase 2>/dev/null || echo "Private repo not found at /root/Secret_Privat"'
  alias repo='cd /root/Linux_Server_Public && git pull --rebase && source /root/Linux_Server_Public/109/server_109.sh && echo "=== Public repo loaded ==="'

  source /root/Linux_Server_Public/scripts/shared_aliases.sh

  alias load='cd /root/Linux_Server_Public \
    && git fetch origin main \
    && git rebase origin/main \
    && bash /root/Linux_Server_Public/109/server_109.sh --install \
    && source /root/Linux_Server_Public/109/server_109.sh \
    && echo "=== Loaded from GitHub (109) ==="'
}

# ───────────────────────────────────────────────────────────────────────────────
# [2] MC MENU INSTALLER — writes /root/.config/mc/menu
# ───────────────────────────────────────────────────────────────────────────────
_install_mc_menu_109() {
  local MC_DIR="/root/.config/mc"
  local MC_MENU="${MC_DIR}/menu"
  mkdir -p "$MC_DIR"
  cat > "$MC_MENU" << 'MCMENU'
+ ! t t
0       Clear screen
	clear

+ ! t t
1       Audit 1h (sos)
	clear
	bash /root/Linux_Server_Public/109/sos.sh 1h
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
3       Audit 3h (sos3)
	clear
	bash /root/Linux_Server_Public/109/sos.sh 3h
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
4       Audit 24h (sos24)
	clear
	bash /root/Linux_Server_Public/109/sos.sh 24h
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
5       Audit 120h (sos120)
	clear
	bash /root/Linux_Server_Public/109/sos.sh 120h
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
i       Server Info (infooo)
	clear
	bash /root/Linux_Server_Public/109/infooo.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
d       Check Domains (domains)
	clear
	bash /root/Linux_Server_Public/109/domains.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
f       Block Bots (fight)
	clear
	bash /root/Linux_Server_Public/109/block_bots.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
a       CrowdSec: Ban List (banlog)
	clear
	cscli decisions list
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
l       CrowdSec: Alerts (banlog50)
	clear
	cscli alerts list -l 50
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
w       WP Update (wpupd)
	clear
	bash /root/Linux_Server_Public/109/wp_update_all.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
W       WP Cron (wpcron)
	clear
	bash /root/Linux_Server_Public/109/run_all_wp_cron.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
H       WP Health (wphealth)
	clear
	bash /root/Linux_Server_Public/109/wphealth.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
m       Mail Clean (mailclean)
	clear
	bash /root/Linux_Server_Public/109/mailclean.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
x       Cleanup Disk (cleanup)
	clear
	bash /root/Linux_Server_Public/109/server_cleanup.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
p       PHP-FPM Watchdog (watchdog)
	clear
	bash /root/Linux_Server_Public/109/php_fpm_watchdog.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
P       PHP-FPM Reload (fpm-reload)
	clear
	php-fpm8.3 -t && systemctl reload php8.3-fpm && echo "OK php8.3-fpm reloaded"
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
n       Nginx Reload (nginx-reload)
	clear
	nginx -t && systemctl reload nginx && echo "OK nginx reloaded"
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
R       Reload All (reload-all)
	clear
	php-fpm8.3 -t && systemctl reload php8.3-fpm && sleep 1 && nginx -t && systemctl reload nginx && echo "OK all reloaded"
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
B       Backup System (backup)
	clear
	bash /root/Linux_Server_Public/109/system_backup.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
A       AWS S3 Test (aws-test)
	clear
	bash /root/Linux_Server_Public/109/aws_test.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
g       Git: Load from GitHub (load)
	clear
	cd /root/Linux_Server_Public \
	  && git fetch origin main \
	  && git rebase origin/main \
	  && bash /root/Linux_Server_Public/109/server_109.sh --install \
	  && source /root/Linux_Server_Public/109/server_109.sh \
	  && echo "=== Loaded from GitHub (109) ==="
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
s       Git: Save to GitHub (save)
	clear
	cd /root/Linux_Server_Public \
	  && git add -A \
	  && git commit -m "Save $(date +%Y-%m-%d_%H:%M)" || true \
	  && git pull --rebase \
	  && git push \
	  && echo "=== Saved to GitHub ==="
	echo ""; read -n 1 -s -r -p "Press any key..."
MCMENU
  echo "=== MC menu installed: ${MC_MENU} ==="
}

# ───────────────────────────────────────────────────────────────────────────────
# ENTRY POINT
# ───────────────────────────────────────────────────────────────────────────────
if [[ "${1}" == "--install" ]]; then
  # Install MC menu only — MOTD is managed separately via /etc/profile.d/motd_server.sh
  _install_mc_menu_109
  echo "=== server_109.sh --install done (MC menu) ==="
  echo "--- To update MOTD run:"
  echo "    curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/109/motd_server.sh \\"
  echo "         -o /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh"
elif [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  _aliases_109
fi

# = Rooted by VladiMIR | AI = v2026-05-21 = github.com/GinCz/Linux_Server_Public
