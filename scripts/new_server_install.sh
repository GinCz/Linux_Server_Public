#!/bin/bash
# =============================================================
# Script:      new_server_install.sh
# Version:     v2026-05-01d
# Description: Universal bootstrap AND update script for any Ubuntu 24 server.
#              Two modes:
#                FULL  — fresh server: apt upgrade, UFW, fail2ban, CrowdSec,
#                        MOTD, mc.menu, .bashrc aliases, clone repo, sos
#                UPDATE— safe for live servers with sites: ONLY updates
#                        .bashrc aliases, mc.menu, pulls repo, updates sos.
#                        Does NOT touch apt, UFW, CrowdSec or hostname.
#              3 server types:
#                Type 1 = VPN + XRay + AmneziaWG + AdGuard + Semaphore
#                Type 2 = Web 222: FastPanel + Cloudflare + XRay + CryptoBot
#                Type 3 = Web 109: FastPanel + XRay (no Cloudflare)
#              All servers get full repo clone — aliases activate per type.
#
# Changelog v2026-05-01d:
#   - VPN type aliases now include sos/save/load (were missing)
#   - Step 5: sos always fetched fresh from GitHub (not just cp from repo)
#   - Step 11: added "load" run after install to ensure sos is latest
#   - Header comments updated to reflect all included sections
#
# Usage:
#   bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
# WARNING: FULL mode modifies hostname, UFW, installs packages — FRESH servers only!
#          UPDATE mode is safe for any live server.
# = Rooted by VladiMIR | AI =
# =============================================================
clear
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

C='\033[1;37m'; X='\033[0m'
echo -e "${C}=========================================${X}"
echo -e "${C}   NEW SERVER SETUP v2026-05-01d${X}"
echo -e "${C}   = Rooted by VladiMIR | AI =${X}"
echo -e "${C}=========================================${X}"
echo

read -rp "Enter server name (e.g. VPN-DE-1 or Srv-222): " SRV_NAME
[[ -n "${SRV_NAME:-}" ]] || { echo "Server name cannot be empty"; exit 1; }

echo
echo "Select server type:"
echo "  1) VPN / XRay / AmneziaWG  (all VPN nodes)"
echo "  2) Web server 222           (FastPanel + Cloudflare + CryptoBot)"
echo "  3) Web server 109           (FastPanel, Russian sites, no Cloudflare)"
read -rp "Type [1/2/3, default 1]: " SRV_TYPE
SRV_TYPE="${SRV_TYPE:-1}"
[[ "$SRV_TYPE" =~ ^[123]$ ]] || SRV_TYPE=1

echo
echo "Select terminal PS1 color:"
echo -e "  \033[01;96m1) Bright Cyan     — бирюзовый (VPN default)\033[0m"
echo -e "  \033[01;91m2) Bright Red      — красный\033[0m"
echo -e "  \033[01;92m3) Bright Green    — зелёный\033[0m"
echo -e "  \033[01;93m4) Bright Yellow   — жёлтый (222 default)\033[0m"
echo -e "  \033[01;95m5) Bright Magenta  — малиновый\033[0m"
echo -e "  \033[38;5;208m6) Orange          — оранжевый\033[0m"
echo -e "  \033[38;5;213m7) Bright Pink     — розовый\033[0m"
echo -e "  \033[01;97m8) Bright White    — белый (109 default)\033[0m"

case "$SRV_TYPE" in
  2) DEF_COLOR=4 ;;
  3) DEF_COLOR=8 ;;
  *) DEF_COLOR=1 ;;
esac
read -rp "Color [1-8, default ${DEF_COLOR}]: " CC
CC="${CC:-${DEF_COLOR}}"
case "$CC" in
  1) PS1_CODE='01;96m';    PS1_NAME="Bright Cyan" ;;
  2) PS1_CODE='01;91m';    PS1_NAME="Bright Red" ;;
  3) PS1_CODE='01;92m';    PS1_NAME="Bright Green" ;;
  4) PS1_CODE='01;93m';    PS1_NAME="Bright Yellow" ;;
  5) PS1_CODE='01;95m';    PS1_NAME="Bright Magenta" ;;
  6) PS1_CODE='38;5;208m'; PS1_NAME="Orange" ;;
  7) PS1_CODE='38;5;213m'; PS1_NAME="Bright Pink" ;;
  8) PS1_CODE='01;97m';    PS1_NAME="Bright White" ;;
  *) PS1_CODE='01;96m';    PS1_NAME="Bright Cyan" ;;
esac

case "$SRV_TYPE" in
  2) TYPE_NAME="Web 222 / FastPanel / Cloudflare / XRay / CryptoBot" ;;
  3) TYPE_NAME="Web 109 / FastPanel / XRay (no Cloudflare)" ;;
  *) TYPE_NAME="VPN / XRay / AmneziaWG / AdGuard / Semaphore" ;;
esac

echo
echo "Select install mode:"
echo "  F) FULL    — fresh server (apt upgrade, UFW, CrowdSec, full setup)"
echo "  U) UPDATE  — safe update  (aliases, mc.menu, repo pull, sos only)"
echo "  !! UPDATE is safe to run on live servers with active websites !!"
read -rp "Mode [F/U, default U]: " INSTALL_MODE
INSTALL_MODE="${INSTALL_MODE:-U}"
[[ "$INSTALL_MODE" =~ ^[FfUu]$ ]] || INSTALL_MODE="U"
[[ "$INSTALL_MODE" =~ ^[Ff]$ ]] && INSTALL_MODE="FULL" || INSTALL_MODE="UPDATE"

echo
echo -e "  \033[${PS1_CODE}●\033[0m  Server : ${SRV_NAME}"
echo -e "  \033[${PS1_CODE}●\033[0m  Type   : ${TYPE_NAME}"
echo -e "  \033[${PS1_CODE}●\033[0m  Color  : ${PS1_NAME}"
echo -e "  \033[${PS1_CODE}●\033[0m  Mode   : ${INSTALL_MODE}"
[[ "$INSTALL_MODE" == "FULL" ]] && echo -e "  \033[1;31m⚠️  FULL mode — apt upgrade + UFW + CrowdSec will run!\033[0m"
[[ "$INSTALL_MODE" == "UPDATE" ]] && echo -e "  \033[1;32m✓  UPDATE mode — safe for live servers (aliases/mc.menu/repo only)\033[0m"
echo
read -rp "Continue? [YES/no]: " OK
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

# sos — ALWAYS from GitHub (freshest version, not from local repo copy)
curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh \
  -o /usr/local/bin/sos && chmod +x /usr/local/bin/sos
echo -e "  \033[1;32mOK: sos (fetched fresh from GitHub)\033[0m"

# infooo
cp /root/Linux_Server_Public/scripts/infooo.sh /usr/local/bin/infooo 2>/dev/null \
  || cp /root/Linux_Server_Public/222/infooo.sh /usr/local/bin/infooo 2>/dev/null || true
chmod +x /usr/local/bin/infooo 2>/dev/null || true
echo -e "  \033[1;32mOK: infooo\033[0m"

# antivir
cp /root/Linux_Server_Public/scripts/scan_clamav.sh /usr/local/bin/antivir 2>/dev/null \
  || cp /root/Linux_Server_Public/222/scan_clamav.sh /usr/local/bin/antivir 2>/dev/null || true
chmod +x /usr/local/bin/antivir 2>/dev/null || true
echo -e "  \033[1;32mOK: antivir\033[0m"

# f2 helper
cp /root/Linux_Server_Public/scripts/f2.sh /usr/local/bin/f2 2>/dev/null || true
chmod +x /usr/local/bin/f2 2>/dev/null || true
echo -e "  \033[1;32mOK: f2\033[0m"

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
  F2B=$(systemctl is-active fail2ban 2>/dev/null)
  echo -e "  fail2ban current status: ${F2B:-not installed}"
fi

# ─── Step 7/11 — .bashrc with 3 alias sets ───────────────────
echo -e "\n\033[${PS1_CODE}[7/11] Writing .bashrc (type-specific aliases)...\033[0m"

# ══════════════════════════════════════════════
# ALIAS BLOCK: COMMON — all 3 server types
# ══════════════════════════════════════════════
ALIASES_COMMON='
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

# ── Services quick status ────────────────────────────────────
alias nginx_st="systemctl status nginx"
alias crowdsec_st="systemctl status crowdsec"
alias banlist="cscli decisions list 2>/dev/null || echo CrowdSec not installed"

# ── Xray log (available on all servers) ─────────────────────
alias xray_log="journalctl -u xray -n 50 --no-pager 2>/dev/null"

# ── Git shortcuts ────────────────────────────────────────────
alias gs="git status"
alias gl="git log --oneline -10"
'

# ══════════════════════════════════════════════
# SAVE / LOAD — each server type uses its own subfolder
# ══════════════════════════════════════════════
case "$SRV_TYPE" in
  2) REPO_SUBFOLDER="222" ;;
  3) REPO_SUBFOLDER="109" ;;
  *) REPO_SUBFOLDER="VPN" ;;
esac

ALIASES_SAVELOAD="
# ── save / load (push/pull folder: ${REPO_SUBFOLDER}/) ──────
alias save='cd /root/Linux_Server_Public \\
  && git add -A \\
  && (git diff --cached --quiet && echo \"Nothing to commit\" \\
    || git commit -m \"save: \$(hostname) \$(date +%Y-%m-%d_%H:%M)\") \\
  && git pull origin main --no-rebase --no-edit \\
  && git push origin main \\
  && echo \"=== Saved to GitHub ===\"'
alias load='cd /root/Linux_Server_Public \\
  && git pull origin main --no-rebase --no-edit \\
  && curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh \\
       -o /usr/local/bin/sos && chmod +x /usr/local/bin/sos \\
  && source ~/.bashrc \\
  && echo \"=== Loaded + sos updated ===\"'
"

# ══════════════════════════════════════════════
# ALIAS BLOCK: TYPE 1 — VPN nodes (XRay, AmneziaWG, AdGuard)
# ══════════════════════════════════════════════
ALIASES_VPN='
# ── AmneziaWG ────────────────────────────────────────────────
alias amn_st="systemctl status amneziawg 2>/dev/null || echo AmneziaWG not installed"
alias amn_stat="bash /root/Linux_Server_Public/VPN/AmneziaWG/amnezia_stat.sh 2>/dev/null || echo amnezia_stat.sh not found"

# ── AdGuard Home ──────────────────────────────────────────────
alias adg_st="systemctl status AdGuardHome 2>/dev/null || echo AdGuard not installed"
alias adg_restart="systemctl restart AdGuardHome 2>/dev/null || echo AdGuard not installed"
alias adg_log="journalctl -u AdGuardHome -n 30 --no-pager 2>/dev/null || echo AdGuard not installed"

# ── WireGuard ────────────────────────────────────────────────
alias wg_st="wg show 2>/dev/null || echo WireGuard not active"
'

# ══════════════════════════════════════════════
# ALIAS BLOCK: TYPE 2 — server 222 (FastPanel + Cloudflare + CryptoBot)
# ══════════════════════════════════════════════
ALIASES_222='
# ── FastPanel (server 222) ───────────────────────────────────
alias fp="cd /var/www && ll"
alias fp_log="tail -f /var/log/nginx/error.log"
alias nginx_reload="systemctl reload nginx"
alias nginx_test="nginx -t"
alias php_restart="systemctl restart php8.1-fpm 2>/dev/null || systemctl restart php-fpm 2>/dev/null || true"

# ── Cloudflare ────────────────────────────────────────────────
alias cf_flush="echo Flush Cloudflare cache via API needed — check scripts/cloudflare_flush.sh"

# ── CryptoBot ────────────────────────────────────────────────
alias bot="cd /root && ls -la"
alias bot_log="journalctl -u cryptobot -n 50 --no-pager 2>/dev/null || echo CryptoBot service not found"
alias bot_st="systemctl status cryptobot 2>/dev/null || echo CryptoBot not configured"
alias bot_restart="systemctl restart cryptobot 2>/dev/null || echo CryptoBot not configured"
alias tr="cd /root && /root/Linux_Server_Public/222/tr_stat.sh 2>/dev/null || echo tr_stat.sh not found in 222/"

# ── Backup shortcuts ──────────────────────────────────────────
alias bk="bash /root/Linux_Server_Public/222/backup_clean.sh 2>/dev/null || echo backup_clean.sh not found"
'

# ══════════════════════════════════════════════
# ALIAS BLOCK: TYPE 3 — server 109 (FastPanel, Russian sites, no Cloudflare)
# ══════════════════════════════════════════════
ALIASES_109='
# ── FastPanel (server 109) ───────────────────────────────────
alias fp="cd /var/www && ll"
alias fp_log="tail -f /var/log/nginx/error.log"
alias nginx_reload="systemctl reload nginx"
alias nginx_test="nginx -t"
alias php_restart="systemctl restart php8.1-fpm 2>/dev/null || systemctl restart php-fpm 2>/dev/null || true"

# ── Backup shortcuts ──────────────────────────────────────────
alias bk="bash /root/Linux_Server_Public/109/backup_clean.sh 2>/dev/null || echo backup_clean.sh not found"
'

# ── Build .bashrc ────────────────────────────────────────────
BASHRC_HEADER="# ~/.bashrc — ${SRV_NAME}
# Type: ${TYPE_NAME}
# Version: v2026-05-01d | Color: ${PS1_NAME}
# = Rooted by VladiMIR | AI =

export PS1='\[\033[${PS1_CODE}\]\u@\h:\w\$\[\033[00m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize
"

case "$SRV_TYPE" in
  2) TYPE_BLOCK="$ALIASES_222" ;;
  3) TYPE_BLOCK="$ALIASES_109" ;;
  *) TYPE_BLOCK="$ALIASES_VPN" ;;
esac

printf '%s\n%s\n%s\n%s\n' \
  "$BASHRC_HEADER" \
  "$ALIASES_COMMON" \
  "$ALIASES_SAVELOAD" \
  "$TYPE_BLOCK" \
  > /root/.bashrc

echo -e "  \033[1;32mOK: .bashrc written for type ${SRV_TYPE} (${TYPE_NAME})\033[0m"

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
  ufw status numbered | sed 's/^/  /'
else
  echo -e "\n\033[${PS1_CODE}[8/11] UFW rules — SKIPPED (UPDATE mode)\033[0m"
  echo -e "  Current UFW status:"
  ufw status | head -5 | sed 's/^/  /'
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
  CS=$(systemctl is-active crowdsec 2>/dev/null)
  [[ "$CS" == "active" ]] \
    && echo -e "  \033[1;32mOK: CrowdSec active\033[0m" \
    || echo -e "  \033[1;33mWARN: CrowdSec=${CS}\033[0m"
else
  echo -e "\n\033[${PS1_CODE}[9/11] CrowdSec install — SKIPPED (UPDATE mode)\033[0m"
  CS=$(systemctl is-active crowdsec 2>/dev/null)
  echo -e "  CrowdSec current status: ${CS:-not installed}"
fi

# ─── Step 10/11 ───────────────────────────────────────────────
echo -e "\n\033[${PS1_CODE}[10/11] MOTD + mc.menu (F2)...\033[0m"

# MOTD
if [[ "$SRV_TYPE" == "1" ]]; then
  MOTD_SRC="/root/Linux_Server_Public/VPN/motd_server.sh"
  [[ -f "$MOTD_SRC" ]] || MOTD_SRC="/root/Linux_Server_Public/scripts/motd_vpn.sh"
else
  MOTD_SRC="/root/Linux_Server_Public/222/motd_server.sh"
fi
[[ -f "$MOTD_SRC" ]] && cp "$MOTD_SRC" /etc/profile.d/motd_server.sh \
  && chmod +x /etc/profile.d/motd_server.sh \
  || echo "  WARN: MOTD source not found: $MOTD_SRC"
chmod -x /etc/update-motd.d/* 2>/dev/null || true
> /etc/motd
echo -e "  \033[1;32mOK: MOTD installed\033[0m"

# mc.menu
mkdir -p /root/.config/mc
rm -f /root/.mc.menu

if [[ "$SRV_TYPE" == "1" ]]; then
  cat > /root/.config/mc/menu << 'MCEOF'
+ ! t t
0    Clear screen
     clear

+ ! t t
i    Server Info (infooo)
     clear; /usr/local/bin/infooo; printf "\nPress any key..."; read k

+ ! t t
s    Server Audit 1h (sos)
     clear; /usr/local/bin/sos 1h; printf "\nPress any key..."; read k

+ ! t t
S    Server Audit 24h (sos24)
     clear; /usr/local/bin/sos 24h; printf "\nPress any key..."; read k

+ ! t t
x    Xray log (last 50 lines)
     clear; journalctl -u xray -n 50 --no-pager 2>/dev/null || echo "Xray not found"; printf "\nPress any key..."; read k

+ ! t t
g    AdGuard status
     clear; systemctl status AdGuardHome 2>/dev/null || echo "AdGuard not installed"; printf "\nPress any key..."; read k

+ ! t t
G    AdGuard restart
     systemctl restart AdGuardHome 2>/dev/null; echo Done

+ ! t t
w    WireGuard / AmneziaWG status
     clear; wg show 2>/dev/null || echo "WireGuard not active"; printf "\nPress any key..."; read k

+ ! t t
a    AmneziaWG stat
     clear; bash /root/Linux_Server_Public/VPN/AmneziaWG/amnezia_stat.sh 2>/dev/null || echo "amnezia_stat.sh not found"; printf "\nPress any key..."; read k

+ ! t t
b    Ban List (CrowdSec)
     clear; cscli decisions list 2>/dev/null || echo "CrowdSec not installed"; printf "\nPress any key..."; read k
MCEOF

elif [[ "$SRV_TYPE" == "2" ]]; then
  cat > /root/.config/mc/menu << 'MCEOF'
+ ! t t
0    Clear screen
     clear

+ ! t t
i    Server Info (infooo)
     clear; /usr/local/bin/infooo; printf "\nPress any key..."; read k

+ ! t t
s    Server Audit 1h (sos)
     clear; /usr/local/bin/sos 1h; printf "\nPress any key..."; read k

+ ! t t
S    Server Audit 24h (sos24)
     clear; /usr/local/bin/sos 24h; printf "\nPress any key..."; read k

+ ! t t
a    Antivirus Scan
     clear; /usr/local/bin/antivir; printf "\nPress any key..."; read k

+ ! t t
n    Nginx reload
     nginx -t && systemctl reload nginx && echo "OK: Nginx reloaded" || echo "ERROR: Nginx config fail"

+ ! t t
N    Nginx status + log (last 30)
     clear; systemctl status nginx; echo; tail -n 30 /var/log/nginx/error.log; printf "\nPress any key..."; read k

+ ! t t
b    CryptoBot status
     clear; systemctl status cryptobot 2>/dev/null || echo "CryptoBot not configured"; printf "\nPress any key..."; read k

+ ! t t
B    CryptoBot restart
     systemctl restart cryptobot 2>/dev/null && echo "Restarted" || echo "CryptoBot not configured"

+ ! t t
t    CryptoBot stats (tr)
     clear; bash /root/Linux_Server_Public/222/tr_stat.sh 2>/dev/null || echo "tr_stat.sh not found in 222/"; printf "\nPress any key..."; read k

+ ! t t
c    Ban List (CrowdSec)
     clear; cscli decisions list 2>/dev/null || echo "CrowdSec not installed"; printf "\nPress any key..."; read k
MCEOF

else
  cat > /root/.config/mc/menu << 'MCEOF'
+ ! t t
0    Clear screen
     clear

+ ! t t
i    Server Info (infooo)
     clear; /usr/local/bin/infooo; printf "\nPress any key..."; read k

+ ! t t
s    Server Audit 1h (sos)
     clear; /usr/local/bin/sos 1h; printf "\nPress any key..."; read k

+ ! t t
S    Server Audit 24h (sos24)
     clear; /usr/local/bin/sos 24h; printf "\nPress any key..."; read k

+ ! t t
a    Antivirus Scan
     clear; /usr/local/bin/antivir; printf "\nPress any key..."; read k

+ ! t t
n    Nginx reload
     nginx -t && systemctl reload nginx && echo "OK: Nginx reloaded" || echo "ERROR: Nginx config fail"

+ ! t t
N    Nginx status + log (last 30)
     clear; systemctl status nginx; echo; tail -n 30 /var/log/nginx/error.log; printf "\nPress any key..."; read k

+ ! t t
c    Ban List (CrowdSec)
     clear; cscli decisions list 2>/dev/null || echo "CrowdSec not installed"; printf "\nPress any key..."; read k
MCEOF
fi

echo -e "  \033[1;32mOK: mc.menu written for type ${SRV_TYPE}\033[0m"

# ─── Step 11/11 ───────────────────────────────────────────────
echo -e "\n\033[${PS1_CODE}[11/11] Final: source .bashrc + load (sos fresh) + run sos...\033[0m"

# Reload .bashrc
source /root/.bashrc 2>/dev/null || true

# load — git pull + fresh sos from GitHub (ensure we have latest)
cd /root/Linux_Server_Public 2>/dev/null || true
git pull origin main --no-rebase --no-edit 2>/dev/null || true
curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh \
  -o /usr/local/bin/sos && chmod +x /usr/local/bin/sos
echo -e "  \033[1;32mOK: repo pulled + sos updated from GitHub\033[0m"

# Final audit
/usr/local/bin/sos 1h

echo
echo -e "\033[${PS1_CODE}========================================\033[0m"
echo -e "\033[${PS1_CODE}  DONE: ${SRV_NAME}\033[0m"
echo -e "\033[${PS1_CODE}  Type: ${TYPE_NAME}\033[0m"
echo -e "\033[${PS1_CODE}  Mode: ${INSTALL_MODE}\033[0m"
echo -e "\033[${PS1_CODE}  Color: ${PS1_NAME}\033[0m"
echo -e "\033[${PS1_CODE}========================================\033[0m"
echo -e "  \033[1;32msource ~/.bashrc\033[0m  — activate aliases now"
echo -e "  \033[1;32msos / sos24\033[0m       — server audit"
echo -e "  \033[1;32msave\033[0m              — git push"
echo -e "  \033[1;32mload\033[0m              — git pull + update sos"
echo -e "\033[${PS1_CODE}========================================\033[0m"
