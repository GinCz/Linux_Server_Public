#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  new_server_install.sh | [v2026-08-20]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Initial provisioning & sync script for Ubuntu 24 LTS servers (222, 109, VPN)
# Servers     : 222-DE-NetCup, 109-RU-FastVDS, VPN Nodes
# Usage       : bash scripts/new_server_install.sh
# ==========================================================================================
clear
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin:/usr/local/bin

C='\033[1;37m'; X='\033[0m'
echo -e "${C}=========================================${X}"
echo -e "${C}   NEW SERVER SETUP v2026-08-20          ${X}"
echo -e "${C}   = Rooted by VladiMIR | AI =           ${X}"
echo -e "${C}=========================================${X}"
echo

# ── Auto-detection ────────────────────────────────────────────
DETECTED_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
CURRENT_HN="$(hostname 2>/dev/null)"
[[ -n "$CURRENT_HN" ]] || CURRENT_HN="Server-${DETECTED_IP}"

if [[ "$DETECTED_IP" == *"152.53.182.222"* ]] || [[ "$CURRENT_HN" == *"222"* ]]; then
  AUTO_TYPE=2
elif [[ "$DETECTED_IP" == *"212.109.223.109"* ]] || [[ "$CURRENT_HN" == *"109"* ]]; then
  AUTO_TYPE=3
else
  AUTO_TYPE=1
fi

echo -e "  \033[1;33m[1/5] Server Name:\033[0m"
echo -e "  Current hostname: \033[1;37m${CURRENT_HN}\033[0m"
echo -en "  Press \033[1;32mENTER\033[0m to keep '${CURRENT_HN}', or enter new name: "
read -r SRV_NAME
SRV_NAME="${SRV_NAME:-$CURRENT_HN}"

echo
echo -e "  \033[1;33m[2/5] Server Profile:\033[0m"
echo -e "  \033[1;36m1)\033[0m VPN / XRay / AmneziaWG  (all VPN nodes)"
echo -e "  \033[1;36m2)\033[0m Web server 222           (FastPanel + Cloudflare + CryptoBot)"
echo -e "  \033[1;36m3)\033[0m Web server 109           (FastPanel, Russian sites, no Cloudflare)"
echo -en "  Choose profile [1-3, default: \033[1;32m${AUTO_TYPE}\033[0m]: "
read -r SRV_TYPE
SRV_TYPE="${SRV_TYPE:-$AUTO_TYPE}"
[[ "$SRV_TYPE" =~ ^[123]$ ]] || SRV_TYPE=$AUTO_TYPE

echo
echo -e "  \033[1;33m[3/5] MOTD Header Color (Commands, Borders, IP):\033[0m"
echo -e "  \033[38;5;81m1) Sky Blue        — light blue (VPN default)\033[0m"
echo -e "  \033[38;5;196m2) Bright Red      — red\033[0m"
echo -e "  \033[01;92m3) Bright Green    — green\033[0m"
echo -e "  \033[01;93m4) Bright Yellow   — yellow (222 default)\033[0m"
echo -e "  \033[01;95m5) Bright Magenta  — magenta\033[0m"
echo -e "  \033[38;5;208m6) Orange          — orange\033[0m"
echo -e "  \033[38;5;213m7) Bright Pink     — pink\033[0m"
echo -e "  \033[38;5;252m8) Light Grey      — grey/silver (109 default)\033[0m"

case "$SRV_TYPE" in
  2) DEF_HDR_COLOR=4 ;;
  3) DEF_HDR_COLOR=8 ;;
  *) DEF_HDR_COLOR=1 ;;
esac
echo -en "  Choose header color [1-8, default: \033[1;32m${DEF_HDR_COLOR}\033[0m]: "
read -r HC
HC="${HC:-${DEF_HDR_COLOR}}"
case "$HC" in
  1) HDR_CODE='38;5;81m';   HDR_NAME="Sky Blue" ;;
  2) HDR_CODE='38;5;196m';  HDR_NAME="Bright Red" ;;
  3) HDR_CODE='01;92m';     HDR_NAME="Bright Green" ;;
  4) HDR_CODE='01;93m';     HDR_NAME="Bright Yellow" ;;
  5) HDR_CODE='01;95m';     HDR_NAME="Bright Magenta" ;;
  6) HDR_CODE='38;5;208m';  HDR_NAME="Orange" ;;
  7) HDR_CODE='38;5;213m';  HDR_NAME="Bright Pink" ;;
  8) HDR_CODE='38;5;252m';  HDR_NAME="Light Grey" ;;
  *) HDR_CODE='38;5;81m';   HDR_NAME="Sky Blue" ;;
esac

echo
echo -e "  \033[1;33m[4/5] Terminal Prompt (PS1) Color:\033[0m"
echo -e "  \033[38;5;81m1) Sky Blue        — light blue\033[0m"
echo -e "  \033[38;5;196m2) Bright Red      — red\033[0m"
echo -e "  \033[01;92m3) Bright Green    — green (VPN default)\033[0m"
echo -e "  \033[01;93m4) Bright Yellow   — yellow (222 default)\033[0m"
echo -e "  \033[01;95m5) Bright Magenta  — magenta\033[0m"
echo -e "  \033[38;5;208m6) Orange          — orange\033[0m"
echo -e "  \033[38;5;213m7) Bright Pink     — pink\033[0m"
echo -e "  \033[38;5;252m8) Light Grey      — grey/silver (109 default)\033[0m"

case "$SRV_TYPE" in
  2) DEF_PS1_COLOR=4 ;;
  3) DEF_PS1_COLOR=8 ;;
  *) DEF_PS1_COLOR=3 ;;
esac
echo -en "  Choose prompt color [1-8, default: \033[1;32m${DEF_PS1_COLOR}\033[0m]: "
read -r PC
PC="${PC:-${DEF_PS1_COLOR}}"
case "$PC" in
  1) PS1_CODE='38;5;81m';   PS1_NAME="Sky Blue" ;;
  2) PS1_CODE='38;5;196m';  PS1_NAME="Bright Red" ;;
  3) PS1_CODE='01;92m';     PS1_NAME="Bright Green" ;;
  4) PS1_CODE='01;93m';     PS1_NAME="Bright Yellow" ;;
  5) PS1_CODE='01;95m';     PS1_NAME="Bright Magenta" ;;
  6) PS1_CODE='38;5;208m';  PS1_NAME="Orange" ;;
  7) PS1_CODE='38;5;213m';  PS1_NAME="Bright Pink" ;;
  8) PS1_CODE='38;5;252m';  PS1_NAME="Light Grey" ;;
  *) PS1_CODE='01;92m';     PS1_NAME="Bright Green" ;;
esac

case "$SRV_TYPE" in
  2) TYPE_NAME="Web 222 / FastPanel / Cloudflare / XRay / CryptoBot" ;;
  3) TYPE_NAME="Web 109 / FastPanel / XRay (no Cloudflare)" ;;
  *) TYPE_NAME="VPN / XRay / AmneziaWG / AdGuard / CrowdSec" ;;
esac

echo
echo -e "  \033[1;33m[5/5] Install / Update Mode:\033[0m"
echo -e "  \033[1;36m1)\033[0m FULL    — fresh server setup (apt upgrade, UFW, CrowdSec)"
echo -e "  \033[1;36m2)\033[0m UPDATE  — safe update (aliases, mc.menu, repo pull, tools)"
echo -e "  \033[1;36m3)\033[0m UPDATE  — on a live server with active websites"
echo -en "  Choose mode [1-3, default: \033[1;32m2\033[0m]: "
read -r INSTALL_MODE
INSTALL_MODE="${INSTALL_MODE:-2}"
[[ "$INSTALL_MODE" =~ ^[123]$ ]] || INSTALL_MODE="2"
[[ "$INSTALL_MODE" == "1" ]] && INSTALL_MODE="FULL" || INSTALL_MODE="UPDATE"

echo
echo -e "  \033[${HDR_CODE}●\033[0m  Server       : ${SRV_NAME}"
echo -e "  \033[${HDR_CODE}●\033[0m  Type         : ${TYPE_NAME}"
echo -e "  \033[${HDR_CODE}●\033[0m  Header Color : ${HDR_NAME}"
echo -e "  \033[${PS1_CODE}●\033[0m  Prompt Color : ${PS1_NAME}"
echo -e "  \033[${HDR_CODE}●\033[0m  Mode         : ${INSTALL_MODE}"
[[ "$INSTALL_MODE" == "FULL" ]] && echo -e "  \033[1;31m⚠️  FULL mode — apt upgrade + UFW + CrowdSec will run!\033[0m"
[[ "$INSTALL_MODE" == "UPDATE" ]] && echo -e "  \033[1;32m✓  UPDATE mode — safe for live servers (aliases/MOTD/mc.menu/tools only)\033[0m"
echo
echo -en "  Apply changes? [\033[1;32mYES\033[0m/no]: "
read -r OK
[[ "${OK:-YES}" =~ ^(YES|yes|y|)$ ]] || { echo "Aborted"; exit 1; }

# ─── Step 1/11 ────────────────────────────────────────────────
if [[ "$INSTALL_MODE" == "FULL" ]]; then
  echo -e "\n\033[${PS1_CODE}[1/11] Hostname + timezone...\033[0m"
  hostnamectl set-hostname "${SRV_NAME}"
  grep -q '^127.0.1.1' /etc/hosts \
    && sed -i "s/^127.0.1.1.*/127.0.1.1 ${SRV_NAME}/" /etc/hosts \
    || echo "127.0.1.1 ${SRV_NAME}" >> /etc/hosts
  echo "${SRV_NAME}" > /etc/hostname
  timedatectl set-timezone Europe/Prague
  timedatectl set-ntp true
  update-locale LANG=en_US.UTF-8 >/dev/null 2>&1 || true
  echo -e "\033[1;32mOK: hostname=${SRV_NAME}, TZ=Europe/Prague\033[0m"
else
  echo -e "\n\033[${PS1_CODE}[1/11] Hostname + timezone — SKIPPED (UPDATE mode)\033[0m"
fi

# ─── Step 2/11 ────────────────────────────────────────────────
if [[ "$INSTALL_MODE" == "FULL" ]]; then
  echo -e "\n\033[${PS1_CODE}[2/11] apt update + upgrade...\033[0m"
  killall apt apt-get unattended-upgrade 2>/dev/null || true
  rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
  dpkg --configure -a >/dev/null 2>&1 || true
  apt update -y && apt upgrade -y
  echo -e "\033[1;32mOK\033[0m"
else
  echo -e "\n\033[${PS1_CODE}[2/11] apt upgrade — SKIPPED (UPDATE mode)\033[0m"
fi

# ─── Step 3/11 ────────────────────────────────────────────────
if [[ "$INSTALL_MODE" == "FULL" ]]; then
  echo -e "\n\033[${PS1_CODE}[3/11] Installing base packages + fail2ban...\033[0m"
  apt install -y mc curl wget git htop net-tools sysbench \
    clamav clamav-freshclam ca-certificates uuid-runtime jq socat ufw fail2ban
  echo -e "\033[1;32mOK\033[0m"
else
  echo -e "\n\033[${PS1_CODE}[3/11] Package install — SKIPPED (UPDATE mode)\033[0m"
fi

# ─── Step 4/11 ────────────────────────────────────────────────
echo -e "\n\033[${PS1_CODE}[4/11] Cloning / updating GitHub repo...\033[0m"
if [ -d /root/Linux_Server_Public ]; then
  cd /root/Linux_Server_Public \
    && git fetch origin main \
    && (git stash 2>/dev/null || true) \
    && git rebase origin/main \
    && (git stash pop 2>/dev/null || true)
  echo -e "\033[1;32mOK: Repo updated\033[0m"
else
  git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public
  echo -e "\033[1;32mOK: Repo cloned\033[0m"
fi
cd /root

# ─── Step 5/11 ────────────────────────────────────────────────
echo -e "\n\033[${PS1_CODE}[5/11] Installing scripts to /usr/local/bin/...\033[0m"
mkdir -p /usr/local/bin /etc/cron.d 2>/dev/null

if [[ "$SRV_TYPE" == "2" || "$SRV_TYPE" == "3" ]]; then
  TOOLS_LIST=(
    "sos"
    "wp_update_all"
    "run_all_wp_cron"
    "scan_clamav"
    "server_cleanup"
    "block_bots"
    "system_backup"
    "domains"
    "infooo"
    "mailclean"
    "banlog"
    "php_fpm_watchdog"
    "set_php_fpm_limits"
    "f2"
  )
else
  TOOLS_LIST=(
    "sos"
    "scan_clamav"
    "server_cleanup"
    "block_bots"
    "infooo"
    "banlog"
    "f2"
  )
fi

for tool in "${TOOLS_LIST[@]}"; do
  SRC_PATH=""
  if [ -f "/root/Linux_Server_Public/scripts/${tool}.sh" ]; then
    SRC_PATH="/root/Linux_Server_Public/scripts/${tool}.sh"
  elif [ -f "/root/Linux_Server_Public/scripts/${tool}" ]; then
    SRC_PATH="/root/Linux_Server_Public/scripts/${tool}"
  fi

  if [ -n "$SRC_PATH" ]; then
    cp "$SRC_PATH" "/usr/local/bin/${tool}.sh" 2>/dev/null || true
    cp "$SRC_PATH" "/usr/local/bin/${tool}" 2>/dev/null || true
    chmod +x "/usr/local/bin/${tool}.sh" "/usr/local/bin/${tool}" 2>/dev/null || true
    echo -e "  \033[1;32mOK: ${tool}\033[0m"
  else
    curl -fsSL "https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/${tool}.sh" -o "/usr/local/bin/${tool}.sh" 2>/dev/null \
      || curl -fsSL "https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/${tool}" -o "/usr/local/bin/${tool}" 2>/dev/null || true
    chmod +x "/usr/local/bin/${tool}"* 2>/dev/null || true
    echo -e "  \033[1;32mOK (fetched): ${tool}\033[0m"
  fi
done

ln -sf /usr/local/bin/sos.sh /usr/local/bin/sos 2>/dev/null
ln -sf /usr/local/bin/scan_clamav.sh /usr/local/bin/antivir 2>/dev/null
ln -sf /usr/local/bin/infooo.sh /usr/local/bin/infooo 2>/dev/null

if [[ "$SRV_TYPE" == "2" || "$SRV_TYPE" == "3" ]]; then
  echo "0 2 * * 3,6 root /usr/local/bin/wp_update_all.sh >> /var/log/wp_update_all.log 2>&1" > /etc/cron.d/wp_update_all
  echo "0 */3 * * * root /usr/local/bin/run_all_wp_cron.sh >> /var/log/run_all_wp_cron.log 2>&1" > /etc/cron.d/run_all_wp_cron
  chmod 644 /etc/cron.d/wp_update_all /etc/cron.d/run_all_wp_cron 2>/dev/null || true
  echo -e "  \033[1;32mOK: cron jobs configured (WP update + WP cron)\033[0m"
fi

echo -e "\033[1;32mOK: all scripts installed\033[0m"

# ─── Step 6/11 ────────────────────────────────────────────────
if [[ "$INSTALL_MODE" == "FULL" ]]; then
  echo -e "\n\033[${PS1_CODE}[6/11] Configuring fail2ban...\033[0m"
  systemctl enable fail2ban --now 2>/dev/null || true
  cat > /etc/fail2ban/jail.local << 'F2BEOF'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
backend  = systemd

[sshd]
enabled  = true
port     = ssh
logpath  = %(sshd_log)s
maxretry = 3
bantime  = 7200
F2BEOF
  systemctl restart fail2ban 2>/dev/null || true
  F2B=$(systemctl is-active fail2ban 2>/dev/null)
  [[ "$F2B" == "active" ]] \
    && echo -e "  \033[1;32mOK: fail2ban active\033[0m" \
    || echo -e "  \033[1;33mWARN: fail2ban=${F2B}\033[0m"
else
  echo -e "\n\033[${PS1_CODE}[6/11] fail2ban config — SKIPPED (UPDATE mode)\033[0m"
fi

# ─── Step 7/11 — .bashrc with full modern alias sets ───────────
echo -e "\n\033[${PS1_CODE}[7/11] Writing .bashrc (type-specific aliases)...\033[0m"

sed -i '/wpupd/d; /wpcron/d; /sos/d; /cleanup/d; /antivir/d; /fight/d; /backup/d; /domains/d; /infooo/d; /mailclean/d; /banlog/d; /banlist/d; /watchdog/d; /reload-all/d; /nginx-reload/d; /fpm-reload/d; /alias 00=/d; /Linux_Server_Public/d; /MOTD ALIASES/d; /bot_st/d; /aw/d; /repo/d; /secret/d; /setphp/d; /wphealth/d; /banunblock/d; /banblock/d; /show_motd/d; /ports=/d; /xray_log/d; /amn_st/d; /amn_stat/d; /adg_st/d; /adg_restart/d; /adg_log/d; /wg_st/d' /root/.bashrc /root/.bash_aliases 2>/dev/null

BASHRC_HEADER="# ~/.bashrc — ${SRV_NAME}
# Type: ${TYPE_NAME}
# Version: v2026-08-20 | Color: ${PS1_NAME}
# = Rooted by VladiMIR | AI =

export PS1='\[\033[${PS1_CODE}\]\u@\h:\w\$\[\033[00m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize
"

ALIASES_COMMON='
# ── Common System Aliases ─────────────────────────────────────
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

# ── Monitoring & Security ─────────────────────────────────────
alias sos="/usr/local/bin/sos 1h"
alias antivir="/usr/local/bin/scan_clamav.sh"
alias cleanup="/usr/local/bin/server_cleanup.sh"
alias fight="/usr/local/bin/block_bots.sh"
alias infooo="/usr/local/bin/infooo.sh"
alias banlist="cscli decisions list 2>/dev/null || echo CrowdSec not installed"
alias banlog="/usr/local/bin/banlog.sh 2>/dev/null || cscli decisions list"
alias banunblock="cscli decisions delete --ip"
alias banblock="cscli decisions add --duration 24h --ip"

# ── Git & Repos ───────────────────────────────────────────────
alias save="bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/save.sh)"
alias load="bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/load.sh)"
alias repo="cd /root/Linux_Server_Public"
alias secret="cd /root/Secret_Privat 2>/dev/null || cd /root/Linux_Server_Public_Private 2>/dev/null || echo Private repo directory not found"
'

  ALIASES_222='
  # ── Web Server 222 (FastPanel + CF + CryptoBot) ─────────────
  alias backup="/usr/local/bin/system_backup.sh"
  alias wpupd="/usr/local/bin/wp_update_all.sh"
  alias wpcron="/usr/local/bin/run_all_wp_cron.sh"
  alias domains="/usr/local/bin/domains.sh"
  alias nginx-reload="nginx -t && systemctl reload nginx"
  alias fpm-reload="systemctl reload php8.3-fpm 2>/dev/null || systemctl reload php8.1-fpm 2>/dev/null"
  '

  ALIASES_109='
  # ── Web Server 109 (FastPanel RU) ───────────────────────────
  alias backup="/usr/local/bin/system_backup.sh"
  alias wpupd="/usr/local/bin/wp_update_all.sh"
  alias wpcron="/usr/local/bin/run_all_wp_cron.sh"
  alias domains="/usr/local/bin/domains.sh"
  alias nginx-reload="nginx -t && systemctl reload nginx"
  alias fpm-reload="systemctl reload php8.3-fpm 2>/dev/null || systemctl reload php8.1-fpm 2>/dev/null"
  '

  ALIASES_VPN='
  # ── VPN Node (Xray / AdGuard) ───────────────────────────────
  alias xray_log="journalctl -u xray -n 50 --no-pager 2>/dev/null || journalctl -u x-ui -n 50 --no-pager 2>/dev/null"
  alias xray_restart="systemctl restart xray 2>/dev/null || systemctl restart x-ui 2>/dev/null"
  alias adg_st="systemctl status AdGuardHome 2>/dev/null || echo AdGuard not installed"
  '

case "$SRV_TYPE" in
  2) TYPE_BLOCK="$ALIASES_222" ;;
  3) TYPE_BLOCK="$ALIASES_109" ;;
  *) TYPE_BLOCK="$ALIASES_VPN" ;;
esac

printf '%s\n%s\n%s\n' \
  "$BASHRC_HEADER" \
  "$ALIASES_COMMON" \
  "$TYPE_BLOCK" \
  > /root/.bashrc

# Ensure SSH login shells load .bashrc and export PS1
cat > /root/.bash_profile << PROFEOF
# ~/.bash_profile — ${SRV_NAME}
[ -f ~/.bashrc ] && . ~/.bashrc
export PS1='\[\033[${PS1_CODE}\]\u@\h:\w\$\[\033[00m\] '
PROFEOF

cat > /etc/profile.d/00-ps1.sh << PROFEOF
export PS1='\[\033[${PS1_CODE}\]\u@\h:\w\$\[\033[00m\] '
PROFEOF
chmod +x /etc/profile.d/00-ps1.sh

echo -e "  \033[1;32mOK: .bashrc and PS1 configured for type ${SRV_TYPE} (${TYPE_NAME})\033[0m"

# ─── Step 8/11 ────────────────────────────────────────────────
if [[ "$INSTALL_MODE" == "FULL" ]]; then
  echo -e "\n\033[${PS1_CODE}[8/11] UFW Firewall rules...\033[0m"
  ufw --force enable
  ufw allow 22/tcp  comment 'SSH'
  if [[ "$SRV_TYPE" == "2" || "$SRV_TYPE" == "3" ]]; then
    ufw allow 80/tcp  comment 'HTTP'
    ufw allow 443/tcp comment 'HTTPS'
    ufw allow samba   comment 'Samba shares'
  fi
  if [[ "$SRV_TYPE" == "1" ]]; then
    ufw allow 443/tcp   comment 'Xray/HTTPS'
    ufw allow 443/udp   comment 'Xray/QUIC'
    ufw allow 51820/udp comment 'WireGuard/AmneziaWG'
    ufw allow 53/udp    comment 'AdGuard DNS'
    ufw allow 53/tcp    comment 'AdGuard DNS'
    ufw allow 853/tcp   comment 'AdGuard DoT'
    ufw allow 8080/tcp  comment 'AdGuard Web UI'
  fi
  ufw reload
  echo -e "  \033[1;32mOK: UFW rules applied\033[0m"
else
  echo -e "\n\033[${PS1_CODE}[8/11] UFW rules — SKIPPED (UPDATE mode)\033[0m"
fi

# ─── Step 9/11 ────────────────────────────────────────────────
if [[ "$INSTALL_MODE" == "FULL" ]]; then
  echo -e "\n\033[${PS1_CODE}[9/11] Installing CrowdSec...\033[0m"
  curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | bash
  apt-get install -y crowdsec crowdsec-firewall-bouncer-iptables
  cscli collections install crowdsecurity/linux 2>/dev/null
  cscli collections install crowdsecurity/sshd 2>/dev/null
  cscli scenarios install crowdsecurity/portscan 2>/dev/null
  cscli scenarios install crowdsecurity/ssh-bf 2>/dev/null
  if [[ "$SRV_TYPE" == "2" || "$SRV_TYPE" == "3" ]]; then
    cscli collections install crowdsecurity/nginx 2>/dev/null
    cscli collections install crowdsecurity/wordpress 2>/dev/null
  fi
  systemctl enable crowdsec --now 2>/dev/null
  systemctl enable crowdsec-firewall-bouncer --now 2>/dev/null
  echo -e "  \033[1;32mOK: CrowdSec installed and active\033[0m"
else
  echo -e "\n\033[${PS1_CODE}[9/11] CrowdSec install — SKIPPED (UPDATE mode)\033[0m"
fi

# ─── Step 10/11 ───────────────────────────────────────────────
echo -e "\n\033[${PS1_CODE}[10/11] MOTD + mc.menu (F2)...\033[0m"

# Clean any existing / obsolete MOTD scripts in /etc/profile.d/
rm -f /etc/profile.d/*motd*.sh /etc/profile.d/motd*.sh /usr/local/bin/*motd*.sh /root/.motd* 2>/dev/null
sed -i '/motd/d; /show_motd/d' /etc/bash.bashrc /root/.profile /root/.bash_profile 2>/dev/null || true
chmod -x /etc/update-motd.d/* 2>/dev/null || true
> /etc/motd

if [[ "$SRV_TYPE" == "1" ]]; then
  MOTD_SRC="/root/Linux_Server_Public/scripts/motd_vpn.sh"
elif [[ "$SRV_TYPE" == "2" ]]; then
  MOTD_SRC="/root/Linux_Server_Public/222/motd_server.sh"
else
  MOTD_SRC="/root/Linux_Server_Public/109/motd_server.sh"
fi

if [[ -f "$MOTD_SRC" ]]; then
  cp "$MOTD_SRC" /etc/profile.d/motd_server.sh
  sed -i "s|^C=.*|C='\\\\033[${HDR_CODE}'|" /etc/profile.d/motd_server.sh
  chmod +x /etc/profile.d/motd_server.sh
  echo -e "  \033[1;32mOK: MOTD installed from ${MOTD_SRC}\033[0m"
else
  # Fallback inline generation if file not in local repo
  if [[ "$SRV_TYPE" == "2" || "$SRV_TYPE" == "3" ]]; then
    TAG="FastPanel+CF | Ubuntu 24"
    [[ "$SRV_TYPE" == "3" ]] && TAG="FastPanel | Ubuntu 24"
    cat << MOTDEOF > /etc/profile.d/motd_server.sh
#!/usr/bin/env bash
[ -z "\$PS1" ] && return
if [ -n "\$_MOTD_LOADED" ]; then return 0 2>/dev/null || exit 0; fi
export _MOTD_LOADED=1
clear
C='\033[${HDR_CODE}'
G='\033[0;92m'; Y='\033[0;93m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
HR="\${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${X}"
HOST="\$(hostname)"
IP="\$(hostname -I 2>/dev/null | awk '{print \$1}')"
RAM="\$(free -m 2>/dev/null | awk '/^Mem:/{printf "%d%% (%.1f/%.1fG)", (\$3*100)/\$2, \$3/1024, \$2/1024}')"
SWAP="\$(free -m 2>/dev/null | awk '/^Swap:/{if (\$2>0) printf "%.1fG", \$2/1024; else printf "0G"}')"
CPU="\$(top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{print int(\$2 + \$4)}')%"
UP="\$(uptime -p 2>/dev/null | sed 's/up //')"
LOAD="\$(cat /proc/loadavg 2>/dev/null | awk '{print \$1, \$2, \$3}')"
XRAY_ST="\${R}○ INACTIVE\${X}"
(systemctl is-active --quiet x-ui 2>/dev/null || pgrep -f "xray" >/dev/null 2>&1) && XRAY_ST="\${G}● ACTIVE\${X}"
CS_ST="\${R}○ INACTIVE\${X}"
systemctl is-active --quiet crowdsec 2>/dev/null && CS_ST="\${G}● ACTIVE\${X}"
FW_ST="\${G}● ACTIVE\${X}"
ufw status 2>/dev/null | grep -q "inactive" && FW_ST="\${R}○ INACTIVE\${X}"

echo -e "\$HR"
echo -e "  🌐  \${W}\${HOST}\${X}  \${C}\${IP}\${X}  |  ${TAG}  |  load: \${G}\${LOAD}\${X}"
echo -e "  📊  RAM: \${G}\${RAM}\${X}  Swap: \${G}\${SWAP}\${X}  CPU: \${G}\${CPU}\${X}  up: \${W}\${UP}\${X}"
echo -e "  🛡️   Xray: \${XRAY_ST}    CrowdSec: \${CS_ST}    Firewall: \${FW_ST}"
echo -e "\$HR"
echo -e "  \${Y}SCAN & SECURITY\${X}             \${Y}SERVER\${X}                        \${Y}WORDPRESS\${X}"
echo -e "\$HR"
echo -e "  \${C}antivir\${X} (ClamAV scan)       \${C}sos\${X} (server audit)            \${C}wpupd\${X} (WP update all)"
echo -e "  \${C}fight\${X} (block bots)          \${C}watchdog\${X} (PHP-FPM)            \${C}wpcron\${X} (WP CLI cron)"
echo -e "  \${C}banlist\${X} (CrowdSec IPs)      \${C}mailclean\${X} (mail queue)        \${C}domains\${X} (domain & SSL)"
echo -e "  \${C}cleanup\${X} (disk clean)        \${C}setphp\${X} (PHP limits)           \${C}wphealth\${X} (WP check)"
echo -e "  \${C}banunblock\${X} (unban IP)      \${C}style\${X} (theme/colors)          \${C}00\${X} (clear screen)"
echo -e "  \${C}banblock\${X} (manual ban)"
echo -e "\$HR"
echo -e "  \${Y}GIT\${X}                         \${Y}TOOLS\${X}                         \${Y}NGINX & SYSTEM\${X}"
echo -e "\$HR"
echo -e "  \${C}save\${X} (git push)             \${C}infooo\${X} (hardware info)        \${C}nginx-reload\${X} (Nginx)"
echo -e "  \${C}load\${X} (git pull)             \${C}mc\${X} (Midnight Cmdr)            \${C}fpm-reload\${X} (PHP-FPM)"
echo -e "  \${C}repo\${X} (open repo)            \${C}bot\${X} (CryptoBot status)        \${C}reload-all\${X} (Both)"
echo -e "  \${C}secret\${X} (private repo)      \${C}upd\${X} (apt upgrade)"
echo -e "\$HR"
MOTDEOF
    chmod +x /etc/profile.d/motd_server.sh
  elif [[ "$SRV_TYPE" == "1" ]]; then
    cat << MOTDEOF > /etc/profile.d/motd_server.sh
#!/usr/bin/env bash
[ -z "\$PS1" ] && return
if [ -n "\$_MOTD_LOADED" ]; then return 0 2>/dev/null || exit 0; fi
export _MOTD_LOADED=1
clear
C='\033[${HDR_CODE}'
G='\033[0;92m'; Y='\033[0;93m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
HR="\${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\${X}"
HOST="\$(hostname)"
IP="\$(hostname -I 2>/dev/null | awk '{print \$1}')"
RAM="\$(free -m 2>/dev/null | awk '/^Mem:/{printf "%d%% (%.1f/%.1fG)", (\$3*100)/\$2, \$3/1024, \$2/1024}')"
SWAP="\$(free -m 2>/dev/null | awk '/^Swap:/{if (\$2>0) printf "%.1fG", \$2/1024; else printf "0G"}')"
CPU="\$(top -bn1 2>/dev/null | grep 'Cpu(s)' | awk '{print int(\$2 + \$4)}')%"
UP="\$(uptime -p 2>/dev/null | sed 's/up //')"
LOAD="\$(cat /proc/loadavg 2>/dev/null | awk '{print \$1, \$2, \$3}')"

SERVICES=(
  "x-ui:Xray"
  "xray:Xray"
  "AdGuardHome:AdGuardHome"
  "fail2ban:fail2ban"
  "smbd:smbd"
  "crowdsec:CrowdSec"
)
SVC_LINE=""
for item in "\${SERVICES[@]}"; do
  svc="\${item%%:*}"
  disp="\${item##*:}"
  [[ "\$SVC_LINE" == *"\$disp"* ]] && continue
  if systemctl is-active --quiet "\$svc" 2>/dev/null; then
    SVC_LINE+=" \${G}●\${X} \${disp}  "
  else
    SVC_LINE+=" \${R}✗\${X} \${disp}  "
  fi
done

echo -e "\$HR"
echo -e "  🌐  \${W}\${HOST}\${X}  \${C}\${IP}\${X}  |  VPN Node | Ubuntu 24  |  load: \${G}\${LOAD}\${X}"
echo -e "  📊  RAM: \${G}\${RAM}\${X}  Swap: \${G}\${SWAP}\${X}  CPU: \${G}\${CPU}\${X}  up: \${W}\${UP}\${X}"
echo -e "\$HR"
echo -e "  Services:\${SVC_LINE}"
echo -e "\$HR"
echo -e "  \${Y}SCAN & SECURITY\${X}             \${Y}VPN & STATUS\${X}                    \${Y}GIT & TOOLS\${X}"
echo -e "\$HR"
echo -e "  \${C}antivir\${X} (ClamAV menu)       \${C}sos\${X} (server audit)            \${C}save\${X} (git push)"
echo -e "  \${C}fight\${X} (block bots)          \${C}cleanup\${X} (disk clean)          \${C}load\${X} (git pull)"
echo -e "  \${C}banlist\${X} (CrowdSec IPs)      \${C}ports\${X} (open ports)            \${C}infooo\${X} (hardware info)"
echo -e "\$HR"
MOTDEOF
    chmod +x /etc/profile.d/motd_server.sh
  fi
fi

# Midnight Commander Menu (F2)
mkdir -p /root/.config/mc /etc/mc
if [[ "$SRV_TYPE" == "2" || "$SRV_TYPE" == "3" ]]; then
  cat > /root/.config/mc/menu << 'MCEOF'
+ ! t t
@       === SERVER & SYSTEM TOOLS ===
s       SOS: Run Server Audit (interactive)
	/usr/local/bin/sos

u       WP: Batch Update All (Core + Plugins + Themes)
	/usr/local/bin/wp_update_all.sh

c       WP: Run WP-Cron via CLI
	/usr/local/bin/run_all_wp_cron.sh

d       Domains: Check HTTP/SSL Status
	/usr/local/bin/domains.sh

a       Antivirus: ClamAV Interactive Menu
	/usr/local/bin/scan_clamav.sh

b       CrowdSec: Active Ban List
	/usr/local/bin/banlog.sh
MCEOF
else
  cat > /root/.config/mc/menu << 'MCEOF'
+ ! t t
@       === VPN SERVER TOOLS ===
s       SOS: Run Server Audit (interactive)
	/usr/local/bin/sos

a       Antivirus: ClamAV Interactive Menu
	/usr/local/bin/scan_clamav.sh

x       Xray log (last 50 lines)
	journalctl -u xray -n 50 --no-pager 2>/dev/null || journalctl -u x-ui -n 50 --no-pager 2>/dev/null

g       AdGuard status
	systemctl status AdGuardHome 2>/dev/null || echo "AdGuard not installed"

c       Disk Cleanup: Vacuum journals & clean apt
	/usr/local/bin/server_cleanup.sh
MCEOF
fi
cp /root/.config/mc/menu /etc/mc/mc.menu 2>/dev/null

echo -e "  \033[1;32mOK: mc.menu written for type ${SRV_TYPE}\033[0m"

# ─── Step 11/11 ───────────────────────────────────────────────
echo -e "\n\033[${PS1_CODE}[11/11] Finalizing and reloading environment...\033[0m"
source /root/.bashrc 2>/dev/null || true

echo
echo -e "\033[${PS1_CODE}========================================\033[0m"
echo -e "\033[${PS1_CODE}  DONE: ${SRV_NAME}\033[0m"
echo -e "\033[${PS1_CODE}  Type: ${TYPE_NAME}\033[0m"
echo -e "\033[${PS1_CODE}  Mode: ${INSTALL_MODE}\033[0m"
echo -e "\033[${PS1_CODE}  Color: ${PS1_NAME}\033[0m"
echo -e "\033[${PS1_CODE}========================================\033[0m"
echo -e "  \033[1;32msource ~/.bashrc\033[0m  — activate aliases now"
echo -e "  \033[1;32msos\033[0m               — server audit"
echo -e "  \033[1;32msave / load\033[0m       — git push / pull"
echo -e "\033[${PS1_CODE}========================================\033[0m"
