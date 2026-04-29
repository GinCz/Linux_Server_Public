#!/bin/bash
# =============================================================================
# new_server_install.sh — Universal setup for any new server (Ubuntu 24)
# Version     : v2026-04-30
# Covers      : FastPanel / VPN (XRay/Amnezia) / any Ubuntu 24
# Installs    : mc, clamav, sysbench, git, curl + motd + aliases + mc.menu
# Usage       : bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/new_server_install.sh)
# = Rooted by VladiMIR | AI =
# =============================================================================
clear
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; X='\033[0m'

echo -e "${Y}=========================================${X}"
echo -e "${Y}   NEW SERVER SETUP v2026-04-30${X}"
echo -e "${Y}   = Rooted by VladiMIR | AI =${X}"
echo -e "${Y}=========================================${X}"
echo

read -rp "Enter server name (e.g. VPN-DE-1): " SRV_NAME
[[ -n "${SRV_NAME:-}" ]] || { echo -e "${R}Server name cannot be empty${X}"; exit 1; }

echo
echo "Select server type:"
echo "  1) VPN / XRay / AmneziaWG (blue PS1)"
echo "  2) FastPanel / Web (yellow PS1)"
echo "  3) Generic Ubuntu (cyan PS1)"
read -rp "Type [1/2/3, default 1]: " SRV_TYPE
SRV_TYPE="${SRV_TYPE:-1}"

case "$SRV_TYPE" in
  2) PS1_COLOR='01;33m'; PS1_NAME="YELLOW (Web)" ;;
  3) PS1_COLOR='01;36m'; PS1_NAME="CYAN (Generic)" ;;
  *) SRV_TYPE=1; PS1_COLOR='01;34m'; PS1_NAME="BLUE (VPN)" ;;
esac

echo
echo -e "${C}Server  : ${G}${SRV_NAME}${X}"
echo -e "${C}Type    : ${G}${PS1_NAME}${X}"
read -rp "Continue? [YES/no]: " OK
[[ "${OK:-YES}" =~ ^(YES|yes|y|)$ ]] || { echo "Aborted"; exit 1; }

# ---- [1/7] Hostname + timezone ----------------------------------------------
echo -e "\n${C}[1/7] Setting hostname + timezone...${X}"
hostnamectl set-hostname "${SRV_NAME}"
grep -q '^127.0.1.1' /etc/hosts \
  && sed -i "s/^127.0.1.1.*/127.0.1.1 ${SRV_NAME}/" /etc/hosts \
  || echo "127.0.1.1 ${SRV_NAME}" >> /etc/hosts
echo "${SRV_NAME}" > /etc/hostname
timedatectl set-timezone Europe/Prague
timedatectl set-ntp true
update-locale LANG=en_US.UTF-8 >/dev/null 2>&1 || true
echo -e "${G}OK: hostname=${SRV_NAME}, TZ=Europe/Prague, NTP=on${X}"

# ---- [2/7] apt update -------------------------------------------------------
echo -e "\n${C}[2/7] apt update + upgrade...${X}"
killall apt apt-get unattended-upgrade 2>/dev/null || true
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
dpkg --configure -a >/dev/null 2>&1 || true
apt update -y && apt upgrade -y
echo -e "${G}OK${X}"

# ---- [3/7] Packages ---------------------------------------------------------
echo -e "\n${C}[3/7] Installing packages...${X}"
apt install -y mc curl wget git htop net-tools sysbench \
  clamav clamav-freshclam ca-certificates uuid-runtime jq socat ufw
echo -e "${G}OK${X}"

# ---- [4/7] Clone repo -------------------------------------------------------
echo -e "\n${C}[4/7] Cloning GitHub repo...${X}"
if [ -d /root/Linux_Server_Public ]; then
  cd /root/Linux_Server_Public && git fetch origin main && git rebase origin/main
  echo -e "${G}OK: Repo updated${X}"
else
  git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public
  echo -e "${G}OK: Repo cloned${X}"
fi

# ---- [5/7] Install system scripts -------------------------------------------
echo -e "\n${C}[5/7] Installing scripts to /usr/local/bin/...${X}"

# infooo (universal)
cp /root/Linux_Server_Public/222/infooo.sh /usr/local/bin/infooo
chmod +x /usr/local/bin/infooo
echo -e "  ${G}OK: infooo${X}"

# antivir (universal)
if [[ -f /root/Linux_Server_Public/scripts/scan_clamav.sh ]]; then
  cp /root/Linux_Server_Public/scripts/scan_clamav.sh /usr/local/bin/antivir
else
  cp /root/Linux_Server_Public/222/scan_clamav.sh /usr/local/bin/antivir
fi
chmod +x /usr/local/bin/antivir
echo -e "  ${G}OK: antivir${X}"

# f2 (universal interactive menu)
cp /root/Linux_Server_Public/scripts/f2.sh /usr/local/bin/f2
chmod +x /usr/local/bin/f2
echo -e "  ${G}OK: f2${X}"

# Type-specific: audit / sos
if [[ "$SRV_TYPE" == "1" ]]; then
  # VPN node: use vpn_audit.sh as /usr/local/bin/audit
  cp /root/Linux_Server_Public/scripts/vpn_audit.sh /usr/local/bin/audit
  chmod +x /usr/local/bin/audit
  echo -e "  ${G}OK: audit (VPN)${X}"
else
  # Web/Generic: use server_audit.sh as /usr/local/bin/sos
  if [[ -f /root/Linux_Server_Public/scripts/server_audit.sh ]]; then
    cp /root/Linux_Server_Public/scripts/server_audit.sh /usr/local/bin/sos
    chmod +x /usr/local/bin/sos
    echo -e "  ${G}OK: sos (Web)${X}"
  fi
fi

# ---- [6/7] .bashrc ----------------------------------------------------------
echo -e "\n${C}[6/7] Writing .bashrc...${X}"

if [[ "$SRV_TYPE" == "1" ]]; then
  # VPN node .bashrc — sources VPN/vpn_aliases.sh from repo
  cat > /root/.bashrc << BASHEOF
# ~/.bashrc — ${SRV_NAME}
# Version: v2026-04-30 for VPN-Node
# PS1: ${PS1_NAME}
# = Rooted by VladiMIR | AI =

export PS1='\[\033[${PS1_COLOR}\]\u@\h:\w\$\[\033[00m\] '

HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000
HISTFILESIZE=2000
shopt -s checkwinsize

# Load VPN aliases from repo (updated on every 'load')
[[ -f /root/Linux_Server_Public/VPN/vpn_aliases.sh ]] \
  && source /root/Linux_Server_Public/VPN/vpn_aliases.sh

echo "=== .bashrc v2026-04-30 for VPN-Node loaded ==="
BASHEOF

else
  # Web/Generic .bashrc — minimal, sources shared_aliases
  cat > /root/.bashrc << BASHEOF
# ~/.bashrc — ${SRV_NAME}
# Version: v2026-04-30 | PS1: ${PS1_NAME}
# = Rooted by VladiMIR | AI =

export PS1='\[\033[${PS1_COLOR}\]\u@\h:\w\$\[\033[00m\] '

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
  && (git diff --cached --quiet && echo "Nothing to commit" || git commit -m "save: \$(hostname) \$(date +%Y-%m-%d_%H:%M)") \
  && git push origin main && echo "=== Saved ==="'
alias load='cd /root/Linux_Server_Public \
  && git fetch origin main \
  && (git stash 2>/dev/null || true) \
  && git rebase origin/main \
  && (git stash pop 2>/dev/null || true) \
  && source ~/.bashrc \
  && echo "=== Loaded ==="'
BASHEOF
fi

echo -e "${G}OK: .bashrc written${X}"

# ---- [7/7] MOTD + mc.menu ---------------------------------------------------
echo -e "\n${C}[7/7] Installing MOTD + mc.menu...${X}"

# Install correct MOTD based on type
if [[ "$SRV_TYPE" == "1" ]]; then
  cp /root/Linux_Server_Public/scripts/motd_vpn.sh /etc/profile.d/motd_server.sh
else
  cp /root/Linux_Server_Public/222/motd_server.sh /etc/profile.d/motd_server.sh
fi
chmod +x /etc/profile.d/motd_server.sh
echo -e "  ${G}OK: MOTD installed${X}"

# mc.menu
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
2	F2 Menu (f2)
	clear
	/usr/local/bin/f2

MCEOF

# Add type-specific mc.menu entries
if [[ "$SRV_TYPE" == "1" ]]; then
  cat >> /root/.config/mc/menu << 'MCEOF'
+ ! t t
d	VPN Audit 1h (audit)
	clear
	/usr/local/bin/audit 1h
	printf "\nPress any key..."; read key

+ ! t t
w	AmneziaWG Peers (aw)
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
echo -e "  ${G}OK: mc.menu created${X}"

# ---- Done -------------------------------------------------------------------
echo
echo -e "${Y}=========================================${X}"
echo -e "${G}  SETUP COMPLETE: ${SRV_NAME} (${PS1_NAME})${X}"
echo -e "${Y}=========================================${X}"
echo -e "  ${C}source ~/.bashrc${X}  — activate aliases"
echo -e "  ${C}f2${X}              — commands menu"
echo -e "  ${C}audit${X} / ${C}sos${X}    — server audit"
echo -e "  ${C}save${X}            — git push configs"
echo -e "  ${C}load${X}            — git pull + deploy"
echo
echo -e "${Y}Run: ${G}source ~/.bashrc${X}"
echo -e "${Y}=========================================${X}"
