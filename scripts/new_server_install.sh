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

read -rp "Enter server name (e.g. VPN-DE-1): " SRV_NAME
[[ -n "${SRV_NAME:-}" ]] || { echo "Server name cannot be empty"; exit 1; }

echo
echo "Select server type:"
echo "  1) VPN / XRay / AmneziaWG"
echo "  2) FastPanel / Web"
echo "  3) Generic Ubuntu"
read -rp "Type [1/2/3, default 1]: " SRV_TYPE
SRV_TYPE="${SRV_TYPE:-1}"
[[ "$SRV_TYPE" =~ ^[123]$ ]] || SRV_TYPE=1

echo
echo "Select terminal PS1 color:"
echo -e "  \033[01;96m1) Bright Cyan     \u2014 \u0431\u0438\u0440\u044e\u0437\u043e\u0432\u044b\u0439\033[0m"
echo -e "  \033[01;91m2) Bright Red      \u2014 \u043a\u0440\u0430\u0441\u043d\u044b\u0439\033[0m"
echo -e "  \033[01;92m3) Bright Green    \u2014 \u0437\u0435\u043b\u0451\u043d\u044b\u0439\033[0m"
echo -e "  \033[01;93m4) Bright Yellow   \u2014 \u0436\u0451\u043b\u0442\u044b\u0439\033[0m"
echo -e "  \033[01;95m5) Bright Magenta  \u2014 \u043c\u0430\u043b\u0438\u043d\u043e\u0432\u044b\u0439\033[0m"
echo -e "  \033[38;5;208m6) Orange          \u2014 \u043e\u0440\u0430\u043d\u0436\u0435\u0432\u044b\u0439\033[0m"
echo -e "  \033[38;5;213m7) Bright Pink     \u2014 \u0440\u043e\u0437\u043e\u0432\u044b\u0439\033[0m"
echo -e "  \033[01;97m8) Bright White    \u2014 \u0431\u0435\u043b\u044b\u0439\033[0m"

case "$SRV_TYPE" in
  2) DEF_COLOR=4 ;;
  3) DEF_COLOR=8 ;;
  *) DEF_COLOR=1 ;;
esac
read -rp "Color [1-8, default ${DEF_COLOR}]: " COLOR_CHOICE
COLOR_CHOICE="${COLOR_CHOICE:-${DEF_COLOR}}"

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

echo
echo -e "  \033[${PS1_CODE}\u25cf\033[0m  Server : ${SRV_NAME}"
echo -e "  \033[${PS1_CODE}\u25cf\033[0m  Type   : ${TYPE_NAME}"
echo -e "  \033[${PS1_CODE}\u25cf\033[0m  Color  : ${PS1_NAME}"
echo
read -rp "Continue? [YES/no]: " OK
[[ "${OK:-YES}" =~ ^(YES|yes|y|)$ ]] || { echo "Aborted"; exit 1; }

echo -e "\n\033[${PS1_CODE}[1/8] Hostname + timezone...\033[0m"
hostnamectl set-hostname "${SRV_NAME}"
grep -q '^127.0.1.1' /etc/hosts \
  && sed -i "s/^127.0.1.1.*/127.0.1.1 ${SRV_NAME}/" /etc/hosts \
  || echo "127.0.1.1 ${SRV_NAME}" >> /etc/hosts
echo "${SRV_NAME}" > /etc/hostname
timedatectl set-timezone Europe/Prague
timedatectl set-ntp true
update-locale LANG=en_US.UTF-8 >/dev/null 2>&1 || true
echo -e "\033[1;32mOK: hostname=${SRV_NAME}, TZ=Europe/Prague\033[0m"

echo -e "\n\033[${PS1_CODE}[2/8] apt update + upgrade...\033[0m"
killall apt apt-get unattended-upgrade 2>/dev/null || true
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
dpkg --configure -a >/dev/null 2>&1 || true
apt update -y && apt upgrade -y
echo -e "\033[1;32mOK\033[0m"

echo -e "\n\033[${PS1_CODE}[3/8] Installing packages...\033[0m"
apt install -y mc curl wget git htop net-tools sysbench \
  clamav clamav-freshclam ca-certificates uuid-runtime jq socat ufw
echo -e "\033[1;32mOK\033[0m"

echo -e "\n\033[${PS1_CODE}[4/8] Cloning GitHub repo...\033[0m"
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

echo -e "\n\033[${PS1_CODE}[5/8] Installing scripts to /usr/local/bin/...\033[0m"

# infooo (universal)
cp /root/Linux_Server_Public/222/infooo.sh /usr/local/bin/infooo
chmod +x /usr/local/bin/infooo
echo -e "  \033[1;32mOK: infooo\033[0m"

# antivir — universal scan (auto-detects FastPanel vs VPN path)
cp /root/Linux_Server_Public/222/scan_clamav.sh /usr/local/bin/antivir
chmod +x /usr/local/bin/antivir
echo -e "  \033[1;32mOK: antivir\033[0m"

# sos — universal audit script from 222/sos.sh (same for ALL server types)
cp /root/Linux_Server_Public/222/sos.sh /usr/local/bin/sos
chmod +x /usr/local/bin/sos
echo -e "  \033[1;32mOK: sos (from 222/sos.sh, universal)\033[0m"

# f2 (universal interactive menu)
cp /root/Linux_Server_Public/scripts/f2.sh /usr/local/bin/f2
chmod +x /usr/local/bin/f2
echo -e "  \033[1;32mOK: f2\033[0m"

echo -e "\n\033[${PS1_CODE}[6/8] Writing .bashrc...\033[0m"

if [[ "$SRV_TYPE" == "1" ]]; then
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
alias sos='/usr/local/bin/sos 1h'
alias sos3='/usr/local/bin/sos 3h'
alias sos24='/usr/local/bin/sos 24h'
alias sos120='/usr/local/bin/sos 120h'
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

# =============================================================================
echo -e "\n\033[${PS1_CODE}[7/8] Installing CrowdSec (DDoS/SSH/portscan protection)...\033[0m"
# =============================================================================
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | bash
apt-get install -y crowdsec crowdsec-firewall-bouncer-iptables

cscli collections install crowdsecurity/linux 2>/dev/null
cscli collections install crowdsecurity/sshd 2>/dev/null
cscli scenarios install crowdsecurity/portscan 2>/dev/null
cscli scenarios install crowdsecurity/ssh-bf 2>/dev/null
cscli scenarios install crowdsecurity/ssh-slow-bf 2>/dev/null

# Web server: add nginx + WordPress protection
if [[ "$SRV_TYPE" == "2" ]]; then
  cscli collections install crowdsecurity/nginx 2>/dev/null
  cscli collections install crowdsecurity/wordpress 2>/dev/null
  cat > /etc/crowdsec/acquis.d/nginx.yaml << 'EOF'
filenames:
  - /var/log/nginx/*.log
labels:
  type: nginx
EOF
fi

# SSH log acquisition (all server types)
cat > /etc/crowdsec/acquis.d/sshd.yaml << 'EOF'
filenames:
  - /var/log/auth.log
  - /var/log/syslog
labels:
  type: syslog
EOF

systemctl enable crowdsec --now 2>/dev/null
systemctl enable crowdsec-firewall-bouncer --now 2>/dev/null

CS=$(systemctl is-active crowdsec 2>/dev/null)
BN=$(systemctl is-active crowdsec-firewall-bouncer 2>/dev/null)
if [[ "$CS" == "active" && "$BN" == "active" ]]; then
  echo -e "  \033[1;32mOK: CrowdSec engine + firewall bouncer active\033[0m"
else
  echo -e "  \033[1;33mWARN: CS=${CS} Bouncer=${BN} — check manually\033[0m"
fi

echo -e "\n\033[${PS1_CODE}[8/8] MOTD + mc.menu...\033[0m"

if [[ "$SRV_TYPE" == "1" ]]; then
  cp /root/Linux_Server_Public/scripts/motd_vpn.sh /etc/profile.d/motd_server.sh
else
  cp /root/Linux_Server_Public/222/motd_server.sh /etc/profile.d/motd_server.sh
fi
chmod +x /etc/profile.d/motd_server.sh
chmod -x /etc/update-motd.d/* 2>/dev/null || true
> /etc/motd
echo -e "  \033[1;32mOK: MOTD installed\033[0m"

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
s	Server Audit 1h (sos)
	clear
	/usr/local/bin/sos 1h
	printf "\nPress any key..."; read key

+ ! t t
S	Server Audit 24h (sos24)
	clear
	/usr/local/bin/sos 24h
	printf "\nPress any key..."; read key

+ ! t t
b	Ban List (banlog)
	clear
	cscli decisions list 2>/dev/null || echo "CrowdSec not installed"
	printf "\nPress any key..."; read key
MCEOF
echo -e "  \033[1;32mOK: mc.menu\033[0m"

echo
echo -e "\033[${PS1_CODE}=========================================${X}"
echo -e "\033[${PS1_CODE}  SETUP COMPLETE: ${SRV_NAME}  |  ${TYPE_NAME}  |  ${PS1_NAME}${X}"
echo -e "\033[${PS1_CODE}=========================================${X}"
echo -e "  \033[1;32msource ~/.bashrc\033[0m  \u2014 activate aliases"
echo -e "  \033[1;32msos\033[0m / \033[1;32msos24\033[0m    \u2014 server audit"
echo -e "  \033[1;32msave\033[0m            \u2014 git push"
echo -e "  \033[1;32mload\033[0m            \u2014 git pull + deploy"
echo -e "  \033[1;32mcscli decisions list\033[0m \u2014 active bans"
echo
echo -e "\033[${PS1_CODE}Run: source ~/.bashrc\033[0m"
echo -e "\033[${PS1_CODE}=========================================${X}"
