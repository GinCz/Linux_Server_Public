#!/bin/bash
# =============================================================================
# server_109.sh — Unified config for 109-RU-FastVDS (212.109.223.109)
# Version     : v2026-04-27
# Server      : FastVDS.ru, Russia | Ubuntu 24 / FASTPANEL / No Cloudflare
#               4 vCore AMD EPYC 7763 / 8GB RAM / 80GB NVMe
#
# This single file contains THREE sections:
#   [1] MOTD banner  — displayed on every SSH login via /etc/profile.d/
#   [2] Shell aliases — all commands available on this server
#   [3] MC menu sync  — writes /root/.config/mc/menu to match aliases
#
# HOW TO INSTALL (first time):
#   bash /root/Linux_Server_Public/109/server_109.sh --install
#
# HOW TO UPDATE (after git pull):
#   load
#
# HOW TO APPLY ALIASES ONLY:
#   source /root/Linux_Server_Public/109/server_109.sh
#
# MOTD is shown ONLY via /etc/profile.d/motd_server.sh (set by --install)
# Sourcing this file from .bashrc loads aliases ONLY — no duplicate MOTD.
#
# = Rooted by VladiMIR | AI =
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# [1] MOTD BANNER — runs at SSH login when installed to /etc/profile.d/
# ─────────────────────────────────────────────────────────────────────────────
_motd_109() {
  C="\033[1;36m"   # cyan  — borders
  G="\033[1;32m"   # green — active / online
  Y="\033[1;33m"   # yellow — labels
  W="\033[1;37m"   # white — values
  R="\033[1;31m"   # red   — inactive / error
  X="\033[0m"      # reset
  LINE="\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550"

  IP=$(hostname -I | awk '{print $1}')
  RAM_USED=$(free -m | awk '/Mem:/{print $3}')
  RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
  CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
  UPTIME=$(uptime -p | sed 's/up //')
  HN=$(hostname)
  LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

  PEERS_TOTAL=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l || echo 0)
  PEERS_ONLINE=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
    | awk -v t="$(date +%s)" '$5>0 && (t-$5)<180 {c++} END{print c+0}')
  [[ -z "$PEERS_TOTAL"  || "$PEERS_TOTAL"  == "0" ]] && PEERS_TOTAL=0
  [[ -z "$PEERS_ONLINE" ]] && PEERS_ONLINE=0

  if systemctl is-active --quiet crowdsec 2>/dev/null; then
    CS_ENGINE="${G}\u25cf ACTIVE${X}"
  else
    CS_ENGINE="${R}\u25cf INACTIVE${X}"
  fi
  if systemctl is-active --quiet crowdsec-firewall-bouncer 2>/dev/null; then
    CS_FW="${G}\u25cf ACTIVE${X}"
  else
    CS_FW="${R}\u25cf INACTIVE${X}"
  fi

  echo -e "${C}${LINE}${X}"
  printf "  ${C}\U0001f5a5  %-24s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" \
    "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
  echo -e "  ${Y}AmneziaWG: ${G}${PEERS_ONLINE} online${X}${Y} / ${W}${PEERS_TOTAL} total peers${X}${Y}  |  CrowdSec Engine: ${CS_ENGINE}${Y}  Firewall: ${CS_FW}"
  echo -e "${C}${LINE}${X}"

  echo -e "  ${Y}SCAN & SECURITY           SERVER                    WORDPRESS${X}"
  echo -e "${C}${LINE}${X}"
  echo -e "  ${G}antivir${X}(ClamAV scan)      ${G}sos${X}(errors now)           ${G}wpupd${X}(WP update)"
  echo -e "  ${G}fight${X}(block bots)         ${G}sos3${X}(last 3h)             ${G}wpcron${X}(WP cron)"
  echo -e "  ${G}banlog${X}(ban list)          ${G}sos24${X}(last 24h)           ${G}wphealth${X}(WP health)"
  echo -e "  ${G}cleanup${X}(disk clean)       ${G}watchdog${X}(PHP-FPM)         ${G}domains${X}(domain list)"
  echo -e "  ${G}banunblock${X}(unban IP)      ${G}backup${X}(system backup)     ${G}mailclean${X}(mail queue)"
  echo -e "  ${G}banblock${X}(manual ban)      ${G}allinfo${X}(all servers)"
  echo -e "${C}${LINE}${X}"

  echo -e "  ${Y}GIT                       TOOLS${X}"
  echo -e "${C}${LINE}${X}"
  echo -e "  ${G}save${X}(git push)            ${G}infooo${X}(full info)          ${G}aws-test${X}(S3 test)"
  echo -e "  ${G}load${X}(git pull)            ${G}aw${X}(VPN stats)             ${G}nginx-reload${X}(reload)"
  echo -e "  ${G}repo${X}(pull public repo)    ${G}fpm-reload${X}(reload FPM)    ${G}reload-all${X}(both)"
  echo -e "  ${G}secret${X}(private repo)      ${G}mc${X}(Midnight Cmdr)         ${G}00${X}(clear screen)"
  echo -e "${C}${LINE}${X}"

  echo -e "  ${Y}FastPanel${X} | ${Y}Ubuntu 24${X} | ${W}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
  echo
}

# ─────────────────────────────────────────────────────────────────────────────
# [2] SHELL ALIASES — sourced by /root/.bashrc
# ─────────────────────────────────────────────────────────────────────────────
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
  alias allinfo='bash /root/Linux_Server_Public/109/all_servers_info.sh'
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

  # Shared aliases (save / aw / grep / ls / mc) — load is overridden below
  source /root/Linux_Server_Public/scripts/shared_aliases.sh

  # load defined LAST — always wins over shared_aliases.sh
  alias load='cd /root/Linux_Server_Public \
    && git fetch origin main \
    && git rebase origin/main \
    && bash /root/Linux_Server_Public/109/server_109.sh --install \
    && source /root/Linux_Server_Public/109/server_109.sh \
    && echo "=== Loaded from GitHub (109) ==="'
}

# ─────────────────────────────────────────────────────────────────────────────
# [3] MC MENU INSTALLER — writes /root/.config/mc/menu
# ─────────────────────────────────────────────────────────────────────────────
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
v       VPN Stats (aw)
	clear
	bash /root/Linux_Server_Public/VPN/amnezia_stat.sh
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
I       All Servers Info (allinfo)
	clear
	bash /root/Linux_Server_Public/109/all_servers_info.sh
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

# ─────────────────────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────
if [[ "${1}" == "--install" ]]; then
  # Full install: copy MOTD to /etc/profile.d/ + write MC menu
  cp /root/Linux_Server_Public/109/server_109.sh /etc/profile.d/motd_server.sh
  chmod +x /etc/profile.d/motd_server.sh
  _install_mc_menu_109
  echo "=== server_109.sh installed (MOTD + MC menu) ==="
elif [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  # Sourced from .bashrc: load aliases ONLY.
  # MOTD is already shown by /etc/profile.d/motd_server.sh — do NOT call it here.
  _aliases_109
else
  # Executed directly (called by /etc/profile.d/): show MOTD only.
  _motd_109
fi
