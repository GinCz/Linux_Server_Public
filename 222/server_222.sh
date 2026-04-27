#!/bin/bash
# =============================================================================
# server_222.sh — Unified config for 222-DE-NetCup (152.53.182.222)
# Version     : v2026-04-27
# Server      : NetCup.com, Germany | Ubuntu 24 / FASTPANEL / Cloudflare
#               4 vCore AMD EPYC-Genoa / 8GB DDR5 ECC / 256GB NVMe
#
# This single file contains THREE sections:
#   [1] MOTD banner  — displayed on every SSH login via /etc/profile.d/
#   [2] Shell aliases — all commands available on this server
#   [3] MC menu sync  — writes /root/.config/mc/menu to match aliases
#
# HOW TO INSTALL (first time):
#   bash /root/Linux_Server_Public/222/server_222.sh --install
#
# HOW TO UPDATE (after git pull):
#   load
#   (load already calls --install automatically)
#
# HOW TO APPLY ALIASES ONLY (no MOTD/MC changes):
#   source /root/Linux_Server_Public/222/server_222.sh
#
# = Rooted by VladiMIR | AI =
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# [1] MOTD BANNER — runs at SSH login when installed to /etc/profile.d/
# ─────────────────────────────────────────────────────────────────────────────
_motd_222() {
  C="\033[1;36m"   # cyan   — borders
  G="\033[1;32m"   # green  — active / online / commands
  Y="\033[1;33m"   # yellow — labels / section headers
  W="\033[1;37m"   # white  — values
  R="\033[1;31m"   # red    — inactive / error
  X="\033[0m"      # reset
  LINE="\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550\u2550"

  # Server stats
  IP=$(hostname -I | awk '{print $1}')
  RAM_USED=$(free -m | awk '/Mem:/{print $3}')
  RAM_TOTAL=$(free -m | awk '/Mem:/{print $2}')
  CPU=$(top -bn1 | grep 'Cpu(s)' | awk '{print int($2+$4)}')
  UPTIME=$(uptime -p | sed 's/up //')
  HN=$(hostname)
  LOAD=$(awk '{print $1" "$2" "$3}' /proc/loadavg)

  # AmneziaWG peers — total and active within last 3 minutes (handshake < 180s)
  PEERS_TOTAL=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 | wc -l || echo 0)
  PEERS_ONLINE=$(docker exec amnezia-awg wg show wg0 dump 2>/dev/null | tail -n +2 \
    | awk -v t="$(date +%s)" '$5>0 && (t-$5)<180 {c++} END{print c+0}')
  [[ -z "$PEERS_TOTAL"  || "$PEERS_TOTAL"  == "0" ]] && PEERS_TOTAL=0
  [[ -z "$PEERS_ONLINE" ]] && PEERS_ONLINE=0

  # CrowdSec — check IDS engine and firewall bouncer
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

  # Header
  echo -e "${C}${LINE}${X}"
  printf "  ${C}\U0001f5a5  %-24s${X} ${W}%-22s${X} ${Y}RAM:${W}%s/%sMB${X}  ${Y}CPU:${W}%s%%${X}\n" \
    "$HN" "$IP" "$RAM_USED" "$RAM_TOTAL" "$CPU"
  echo -e "  ${Y}AmneziaWG: ${G}${PEERS_ONLINE} online${X}${Y} / ${W}${PEERS_TOTAL} total peers${X}${Y}  |  CrowdSec Engine: ${CS_ENGINE}${Y}  Firewall: ${CS_FW}"
  echo -e "${C}${LINE}${X}"

  # Row 1: SCAN & SECURITY | SERVER | WORDPRESS
  echo -e "  ${Y}SCAN & SECURITY           SERVER                    WORDPRESS${X}"
  echo -e "${C}${LINE}${X}"
  echo -e "  ${G}antivir${X}(ClamAV scan)      ${G}sos${X}(errors now)           ${G}wpupd${X}(WP update)"
  echo -e "  ${G}fight${X}(block bots)         ${G}sos3${X}(last 3h)             ${G}wpcron${X}(WP cron)"
  echo -e "  ${G}banlog${X}(ban list)          ${G}sos24${X}(last 24h)           ${G}wphealth${X}(WP health)"
  echo -e "  ${G}cleanup${X}(disk clean)       ${G}watchdog${X}(PHP-FPM)         ${G}domains${X}(domain list)"
  echo -e "${C}${LINE}${X}"

  # Row 2: CRYPTO-BOT | GIT | TOOLS
  echo -e "  ${Y}CRYPTO-BOT                GIT                       TOOLS${X}"
  echo -e "${C}${LINE}${X}"
  echo -e "  ${G}tr${X}(start bot)            ${G}save${X}(git push)            ${G}infooo${X}(full info)"
  echo -e "  ${G}clog100${X}(last 100 logs)   ${G}load${X}(git pull)            ${G}aws-test${X}(S3 test)"
  echo -e "  ${G}reset${X}(restart bot)       ${G}00${X}(clear screen)          ${G}backup${X}(local backup)"
  echo -e "  ${G}f5bot${X}(docker backup)     ${G}mc${X}(Midnight Cmdr)         ${G}allinfo${X}(all servers)"
  echo -e "  ${G}f9bot${X}(bot restore)       ${G}repo${X}(pull public repo)    ${G}mailclean${X}(mail queue)"
  echo -e "  ${G}f5vpn${X}(VPN backup)        ${G}secret${X}(private repo)      ${G}nginx-reload${X}(reload)"
  echo -e "  ${G}allvpnstat${X}(VPN traffic)  ${G}allservers${X}(servers info)  ${G}banlog${X}(ban log)"
  echo -e "${C}${LINE}${X}"

  # Footer
  echo -e "  ${Y}FastPanel${X} | ${Y}Ubuntu 24${X} | ${W}${IP}${X} | up ${W}${UPTIME}${X} | load: ${G}${LOAD}${X}"
  echo
}

# ─────────────────────────────────────────────────────────────────────────────
# [2] SHELL ALIASES — sourced by /root/.bashrc
# ─────────────────────────────────────────────────────────────────────────────
_aliases_222() {
  export PS1='\[\033[01;33m\]\u@\h:\w\$\[\033[00m\] '

  HISTCONTROL=ignoredups:ignorespace
  shopt -s histappend
  HISTSIZE=1000
  HISTFILESIZE=2000
  shopt -s checkwinsize

  # --- SOS: Server Health Monitor ---
  # Usage: sos | sos1 | sos3 | sos24 | sos120
  alias sos='bash /root/Linux_Server_Public/222/sos.sh 1h'
  alias sos1='bash /root/Linux_Server_Public/222/sos.sh 1h'
  alias sos3='bash /root/Linux_Server_Public/222/sos.sh 3h'
  alias sos24='bash /root/Linux_Server_Public/222/sos.sh 24h'
  alias sos120='bash /root/Linux_Server_Public/222/sos.sh 120h'

  # --- Quick server commands ---
  alias 00='clear'
  alias infooo='bash /root/Linux_Server_Public/222/infooo.sh'
  alias domains='bash /root/Linux_Server_Public/222/domains.sh'
  alias fight='bash /root/Linux_Server_Public/222/block_bots.sh'
  alias watchdog='bash /root/Linux_Server_Public/222/php_fpm_watchdog.sh'
  alias backup='bash /root/backup_clean.sh'
  alias antivir='bash /root/Linux_Server_Public/222/scan_clamav.sh'
  alias mailclean='bash /root/Linux_Server_Public/222/mailclean.sh'
  alias cleanup='bash /root/Linux_Server_Public/222/server_cleanup.sh'
  alias aws-test='bash /root/Linux_Server_Public/222/aws_test.sh'
  alias allinfo='bash /root/Linux_Server_Public/222/all_servers_info.sh'
  alias nginx-reload='nginx -t && systemctl reload nginx && echo "OK nginx reloaded"'

  # --- CrowdSec ---
  alias banlog='bash /root/Linux_Server_Public/222/banlog.sh 30'
  alias banlog50='bash /root/Linux_Server_Public/222/banlog.sh 50'
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

  # --- VPN Docker Backup & Restore ---
  alias f5vpn='bash /root/Linux_Server_Public/VPN/vpn_docker_backup.sh'
  alias vpn-restore='bash /root/Linux_Server_Public/VPN/vpn_restore_v2026-04-13.sh'

  # --- Git repos ---
  alias secret='cd /root/Linux_Server_Public && git -C /root/Secret_Privat pull --rebase 2>/dev/null || echo "Private repo not found at /root/Secret_Privat"'
  alias repo='cd /root/Linux_Server_Public && git pull --rebase && source /root/Linux_Server_Public/222/server_222.sh && echo "=== Public repo loaded ==="'

  # --- Shared aliases (save / aw / grep / ls / mc) ---
  # NOTE: load is defined BELOW to override any definition from shared_aliases.sh
  source /root/Linux_Server_Public/scripts/shared_aliases.sh

  # --- load: pull from GitHub + reinstall MOTD + reload aliases ---
  # Defined LAST so it always wins over shared_aliases.sh
  # Steps: fetch+rebase -> install MOTD -> install MC menu -> source this file
  alias load='cd /root/Linux_Server_Public \
    && git fetch origin main \
    && git rebase origin/main \
    && bash /root/Linux_Server_Public/222/server_222.sh --install \
    && source /root/Linux_Server_Public/222/server_222.sh \
    && echo "=== Loaded from GitHub (222) ==="'
}

# ─────────────────────────────────────────────────────────────────────────────
# [3] MC MENU INSTALLER — writes /root/.config/mc/menu
# Called automatically by --install and by load alias
# ─────────────────────────────────────────────────────────────────────────────
_install_mc_menu_222() {
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
	bash /root/Linux_Server_Public/222/sos.sh 1h
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
3       Audit 3h (sos3)
	clear
	bash /root/Linux_Server_Public/222/sos.sh 3h
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
4       Audit 24h (sos24)
	clear
	bash /root/Linux_Server_Public/222/sos.sh 24h
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
5       Audit 120h (sos120)
	clear
	bash /root/Linux_Server_Public/222/sos.sh 120h
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
i       Server Info (infooo)
	clear
	bash /root/Linux_Server_Public/222/infooo.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
d       Check Domains (domains)
	clear
	bash /root/Linux_Server_Public/222/domains.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
f       Block Bots (fight)
	clear
	bash /root/Linux_Server_Public/222/block_bots.sh
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
	bash /root/Linux_Server_Public/222/wp_update_all.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
W       WP Cron (wpcron)
	clear
	bash /root/Linux_Server_Public/222/run_all_wp_cron.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
H       WP Health (wphealth)
	clear
	bash /root/Linux_Server_Public/222/wphealth.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
m       Mail Clean (mailclean)
	clear
	bash /root/Linux_Server_Public/222/mailclean.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
x       Cleanup Disk (cleanup)
	clear
	bash /root/Linux_Server_Public/222/server_cleanup.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
p       PHP-FPM Watchdog (watchdog)
	clear
	bash /root/Linux_Server_Public/222/php_fpm_watchdog.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
o       Crypto-Bot: Quick Report (tr)
	clear
	bash /root/crypto-docker/scripts/tr_docker.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
c       Crypto-Bot: Container Logs (clog100)
	clear
	docker logs crypto-bot --tail 100
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
t       Crypto-Bot: Trades 1h
	clear
	bash /root/crypto-docker/scripts/torg.sh 1
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
r       Crypto-Bot: Restart (reset)
	clear
	bash /root/crypto-docker/scripts/reset.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
K       Backup Docker (f5bot)
	clear
	bash /root/docker_backup.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
V       VPN Backup (f5vpn)
	clear
	bash /root/Linux_Server_Public/VPN/vpn_docker_backup.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
v       VPN Stats (aw)
	clear
	bash /root/Linux_Server_Public/VPN/amnezia_stat.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
B       Backup System (backup)
	clear
	bash /root/backup_clean.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
A       AWS S3 Test (aws-test)
	clear
	bash /root/Linux_Server_Public/222/aws_test.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
I       All Servers Info (allinfo)
	clear
	bash /root/Linux_Server_Public/222/all_servers_info.sh
	echo ""; read -n 1 -s -r -p "Press any key..."

+ ! t t
g       Git: Load from GitHub (load)
	clear
	cd /root/Linux_Server_Public \
	  && git fetch origin main \
	  && git rebase origin/main \
	  && bash /root/Linux_Server_Public/222/server_222.sh --install \
	  && source /root/Linux_Server_Public/222/server_222.sh \
	  && echo "=== Loaded from GitHub (222) ==="
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
  cp /root/Linux_Server_Public/222/server_222.sh /etc/profile.d/motd_server.sh
  chmod +x /etc/profile.d/motd_server.sh
  _install_mc_menu_222
  echo "=== server_222.sh installed (MOTD + MC menu) ==="
elif [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
  # Sourced (not executed): load aliases only, run MOTD if interactive login
  _aliases_222
  if [[ $- == *i* ]] && shopt -q login_shell 2>/dev/null; then
    _motd_222
  fi
else
  # Executed directly without --install: run MOTD (used by /etc/profile.d/)
  _motd_222
fi
