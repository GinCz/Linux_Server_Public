#!/bin/bash
# =============================================================================
# new_server_install.sh — Universal setup for any new server (Ubuntu 24)
# Version     : v2026-04-30
# Usage       : bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
# = Rooted by VladiMIR | AI =
# =============================================================================
clear
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

DEF='\033[1;37m'; X='\033[0m'

echo -e "${DEF}=========================================${X}"
echo -e "${DEF}   NEW SERVER SETUP v2026-04-30${X}"
echo -e "${DEF}   = Rooted by VladiMIR | AI =${X}"
echo -e "${DEF}=========================================${X}"
echo

# --- Server name ---
read -rp "Enter server name (e.g. VPN-DE-1): " SRV_NAME
[[ -n "${SRV_NAME:-}" ]] || { echo "Server name cannot be empty"; exit 1; }

# --- Server type ---
echo
echo "Select server type:"
echo "  1) VPN / XRay / AmneziaWG"
echo "  2) FastPanel / Web"
echo "  3) Generic Ubuntu"
read -rp "Type [1/2/3, default 1]: " SRV_TYPE
SRV_TYPE="${SRV_TYPE:-1}"
[[ "$SRV_TYPE" =~ ^[123]$ ]] || SRV_TYPE=1

# --- PS1 color selection (shown in their own color) ---
echo
echo "Select terminal color for PS1:"
echo -e "  \033[01;96m1) Bright Cyan     — бирюзовый\033[0m"
echo -e "  \033[01;91m2) Bright Red      — красный\033[0m"
echo -e "  \033[01;92m3) Bright Green    — зелёный\033[0m"
echo -e "  \033[01;93m4) Bright Yellow   — жёлтый\033[0m"
echo -e "  \033[01;95m5) Bright Magenta  — малиновый\033[0m"
echo -e "  \033[38;5;208m6) Orange          — оранжевый\033[0m"
echo -e "  \033[38;5;213m7) Bright Pink     — розовый\033[0m"
echo -e "  \033[01;97m8) Bright White    — белый\033[0m"

# Default color depends on server type
case "$SRV_TYPE" in
  1) DEFAULT_COLOR=1 ;;
  2) DEFAULT_COLOR=4 ;;
  *) DEFAULT_COLOR=8 ;;
esac

read -rp "Color [1-8, default ${DEFAULT_COLOR}]: " COLOR_CHOICE
COLOR_CHOICE="${COLOR_CHOICE:-${DEFAULT_COLOR}}"

case "$COLOR_CHOICE" in
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
  2) TYPE_NAME="Web / FastPanel" ;;
  3) TYPE_NAME="Generic" ;;
  *) TYPE_NAME="VPN" ;;
esac

# --- Confirm ---
echo
echo -e "  \033[${PS1_CODE}\u25cf\033[0m  Server : ${SRV_NAME}"
echo -e "  \033[${PS1_CODE}\u25cf\033[0m  Type   : ${TYPE_NAME}"
echo -e "  \033[${PS1_CODE}\u25cf\033[0m  Color  : ${PS1_NAME} (${PS1_CODE})"
echo
read -rp "Continue? [YES/no]: " OK
[[ "${OK:-YES}" =~ ^(YES|yes|y|)$ ]] || { echo "Aborted"; exit 1; }

# =============================================================================

echo -e "\n\033[${PS1_CODE}[1/7] Hostname + timezone...\033[0m"
hostnamectl set-hostname "${SRV_NAME}"
grep -q '^127.0.1.1' /etc/hosts \
  && sed -i "s/^127.0.1.1.*/127.0.1.1 ${SRV_NAME}/" /etc/hosts \
  || echo "127.0.1.1 ${SRV_NAME}" >> /etc/hosts
echo "${SRV_NAME}" > /etc/hostname
timedatectl set-timezone Europe/Prague
timedatectl set-ntp true
update-locale LANG=en_US.UTF-8 >/dev/null 2>&1 || true
echo -e "\033[1;32mOK: hostname=${SRV_NAME}, TZ=Europe/Prague, NTP=on\033[0m"

echo -e "\n\033[${PS1_CODE}[2/7] apt update + upgrade...\033[0m"
killall apt apt-get unattended-upgrade 2>/dev/null || true
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
dpkg --configure -a >/dev/null 2>&1 || true
apt update -y && apt upgrade -y
echo -e "\033[1;32mOK\033[0m"

echo -e "\n\033[${PS1_CODE}[3/7] Installing packages...\033[0m"
apt install -y mc curl wget git htop net-tools sysbench \
  clamav clamav-freshclam ca-certificates uuid-runtime jq socat ufw
echo -e "\033[1;32mOK\033[0m"

echo -e "\n\033[${PS1_CODE}[4/7] Cloning GitHub repo...\033[0m"
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

echo -e "\n\033[${PS1_CODE}[5/7] Installing scripts to /usr/local/bin/...\033[0m"

cp /root/Linux_Server_Public/222/infooo.sh /usr/local/bin/infooo && chmod +x /usr/local/bin/infooo
echo -e "  \033[1;32mOK: infooo\033[0m"

SCANSRC=/root/Linux_Server_Public/scripts/scan_clamav.sh
[[ -f "$SCANSRC" ]] || SCANSRC=/root/Linux_Server_Public/222/scan_clamav.sh
cp "$SCANSRC" /usr/local/bin/antivir && chmod +x /usr/local/bin/antivir
echo -e "  \033[1;32mOK: antivir\033[0m"

cp /root/Linux_Server_Public/scripts/f2.sh /usr/local/bin/f2 && chmod +x /usr/local/bin/f2
echo -e "  \033[1;32mOK: f2\033[0m"

if [[ "$SRV_TYPE" == "1" ]]; then
  cp /root/Linux_Server_Public/scripts/vpn_audit.sh /usr/local/bin/audit && chmod +x /usr/local/bin/audit
  echo -e "  \033[1;32mOK: audit (VPN)\033[0m"
else
  if [[ -f /root/Linux_Server_Public/scripts/server_audit.sh ]]; then
    cp /root/Linux_Server_Public/scripts/server_audit.sh /usr/local/bin/sos && chmod +x /usr/local/bin/sos
    echo -e "  \033[1;32mOK: sos (Web)\033[0m"
  fi
fi

echo -e "\n\033[${PS1_CODE}[6/7] Writing .bashrc...\033[0m"

if [[ "$SRV_TYPE" == "1" ]]; then
  # VPN: sources vpn_aliases.sh from repo (PS1 color is inside vpn_aliases.sh)
  # Write a custom PS1_COLOR into a local override so vpn_aliases.sh uses the right color
  cat > /root/.bashrc << BASHEOF
# ~/.bashrc — ${SRV_NAME}
# Version: v2026-04-30 for VPN-Node | Color: ${PS1_NAME}
# = Rooted by VladiMIR | AI =

export VPN_PS1_COLOR='${PS1_CODE}'

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

[[ -f /root/Linux_Server_Public/VPN/vpn_aliases.sh ]] \
  && source /root/Linux_Server_Public/VPN/vpn_aliases.sh

echo "=== .bashrc v2026-04-30 for VPN-Node loaded ==="
BASHEOF

else
  cat > /root/.bashrc << BASHEOF
# ~/.bashrc — ${SRV_NAME}
# Version: v2026-04-30 | Color: ${PS1_NAME}
# = Rooted by VladiMIR | AI =

export PS1='\[\033[${PS1_CODE}\]\u@\h:\w\$\[\033[00m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

alias 00='clear'
alias infooo='/usr/local/bin/infooo'
alias antivir='/usr/local/bin/antivir'
alias f2='/usr/local/bin/f2'
alias grep='grep --color=auto'
alias ls='ls --color=auto -h'
alias ll='ls -lh --color=auto'
alias la='ls -Ah --color=auto'
alias mc='/usr/bin/mc'
alias save='cd /root/Linux_Server_Public \
  && git add -A \
  && (git diff --cached --quiet && echo "Nothing to commit" \
    || git commit -m "save: \$(hostname) \$(date +%Y-%m-%d_%H:%M)") \
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
  && source ~/.bashrc \
  && echo "=== Loaded ==="'
BASHEOF
fi
echo -e "\033[1;32mOK\033[0m"

echo -e "\n\033[${PS1_CODE}[7/7] MOTD + mc.menu...\033[0m"

if [[ "$SRV_TYPE" == "1" ]]; then
  cp /root/Linux_Server_Public/scripts/motd_vpn.sh /etc/profile.d/motd_server.sh
else
  cp /root/Linux_Server_Public/222/motd_server.sh /etc/profile.d/motd_server.sh
fi
chmod +x /etc/profile.d/motd_server.sh
chmod -x /etc/update-motd.d/* 2>/dev/null || true
> /etc/motd
echo -e "  \033[1;32mOK: MOTD installed, Ubuntu default MOTD disabled\033[0m"

mkdir -p /root/.config/mc
cat > /root/.config/mc/menu << 'MCEOF'
+ ! t t
0	Clear screen
	clear

+ ! t t
i	Server Info (infooo)
	clear
	/usr/local/bin/infooo
	printf "\nPress any key..."; read key

+ ! t t
a	Antivirus Scan (antivir)
	clear
	/usr/local/bin/antivir
	printf "\nPress any key..."; read key

+ ! t t
2	F2 Menu
	clear
	/usr/local/bin/f2
MCEOF

if [[ "$SRV_TYPE" == "1" ]]; then
  cat >> /root/.config/mc/menu << 'MCEOF'

+ ! t t
d	VPN Audit 1h
	clear
	/usr/local/bin/audit 1h
	printf "\nPress any key..."; read key

+ ! t t
w	AmneziaWG Peers
	clear
	docker exec amnezia-awg wg show 2>/dev/null || echo "Not running"
	printf "\nPress any key..."; read key
MCEOF
else
  cat >> /root/.config/mc/menu << 'MCEOF'

+ ! t t
s	Server Audit 1h (sos)
	clear
	/usr/local/bin/sos 1h
	printf "\nPress any key..."; read key

+ ! t t
S	Server Audit 24h (sos24)
	clear
	/usr/local/bin/sos 24h
	printf "\nPress any key..."; read key
MCEOF
fi
echo -e "  \033[1;32mOK: mc.menu\033[0m"

# ============================================================================
echo
echo -e "\033[${PS1_CODE}=========================================${X}"
echo -e "\033[${PS1_CODE}  SETUP COMPLETE: ${SRV_NAME}${X}"
echo -e "\033[${PS1_CODE}  Type: ${TYPE_NAME} | Color: ${PS1_NAME}${X}"
echo -e "\033[${PS1_CODE}=========================================${X}"
echo -e "  \033[1;32msource ~/.bashrc\033[0m  — activate aliases"
echo -e "  \033[1;32mf2\033[0m              — commands menu"
echo -e "  \033[1;32maudit\033[0m / \033[1;32msos\033[0m    — server audit"
echo -e "  \033[1;32msave\033[0m            — git push"
echo -e "  \033[1;32mload\033[0m            — git pull + deploy"
echo
echo -e "\033[${PS1_CODE}Run: source ~/.bashrc\033[0m"
echo -e "\033[${PS1_CODE}=========================================${X}"
