#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  install_vpn.sh | [v2026-05-01]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : VPN server setup utility with XRAY, Amnezia and Samba
# Servers     : VPN Nodes
# Usage       : bash scripts/install_vpn.sh
# ==========================================================================================
C='\033[01;96m'; G='\033[1;32m'; R='\033[1;31m'; X='\033[0m'
echo -e "${C}======================================${X}"
echo -e "${C}  VPN NODE FULL INSTALL v2026-05-01d${X}"
echo -e "${C}  XRay + AmneziaWG + AdGuard + Semaphore${X}"
echo -e "${R}  WARNING: Run ONLY on a NEW clean server!${X}"
echo -e "${C}======================================${X}\n"
read -rp "Enter server name (e.g. VPN-DE-1): " SRV_NAME
[[ -n "${SRV_NAME:-}" ]] || { echo "Name cannot be empty"; exit 1; }
read -rp "Continue FULL install on [${SRV_NAME}]? [YES/no]: " OK
[[ "${OK:-YES}" =~ ^(YES|yes|y|)$ ]] || { echo "Aborted"; exit 1; }

echo -e "\n${C}[1/10] Hostname + timezone...${X}"
hostnamectl set-hostname "${SRV_NAME}"
grep -q '^127.0.1.1' /etc/hosts \
  && sed -i "s/^127.0.1.1.*/127.0.1.1 ${SRV_NAME}/" /etc/hosts \
  || echo "127.0.1.1 ${SRV_NAME}" >> /etc/hosts
echo "${SRV_NAME}" > /etc/hostname
timedatectl set-timezone Europe/Prague && timedatectl set-ntp true
update-locale LANG=en_US.UTF-8 >/dev/null 2>&1 || true
echo -e "${G}OK: hostname=${SRV_NAME}, TZ=Europe/Prague${X}"

echo -e "\n${C}[2/10] apt update + upgrade...${X}"
killall apt apt-get unattended-upgrade 2>/dev/null || true
rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/cache/apt/archives/lock
dpkg --configure -a >/dev/null 2>&1 || true
apt update -y && apt upgrade -y
echo -e "${G}OK${X}"

echo -e "\n${C}[3/10] Packages + fail2ban...${X}"
apt install -y mc curl wget git htop net-tools sysbench \
  clamav clamav-freshclam ca-certificates uuid-runtime jq socat ufw fail2ban
echo -e "${G}OK${X}"

echo -e "\n${C}[4/10] SWAP 1GB...${X}"
if [ ! -f /swapfile ]; then
  fallocate -l 1G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '/swapfile' /etc/fstab \
    || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  # Tune swappiness for VPS (less aggressive swapping)
  sysctl -w vm.swappiness=10 >/dev/null
  grep -q 'vm.swappiness' /etc/sysctl.conf \
    || echo 'vm.swappiness=10' >> /etc/sysctl.conf
  echo -e "${G}OK: swap 1GB created, swappiness=10${X}"
else
  SWAP_MB=$(free -m | awk '/^Swap:/{print $2}')
  echo -e "${G}SKIP: swapfile already exists (${SWAP_MB} MB)${X}"
fi

echo -e "\n${C}[5/10] Git repo...${X}"
if [ -d /root/Linux_Server_Public ]; then
  cd /root/Linux_Server_Public
  git fetch origin main && git stash 2>/dev/null || true
  git rebase origin/main && git stash pop 2>/dev/null || true
else
  git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public
fi
echo -e "${G}OK${X}"

echo -e "\n${C}[6/10] Scripts...${X}"
curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh \
  -o /usr/local/bin/sos && chmod +x /usr/local/bin/sos
cp /root/Linux_Server_Public/scripts/infooo.sh /usr/local/bin/infooo 2>/dev/null || true
chmod +x /usr/local/bin/infooo 2>/dev/null || true
cp /root/Linux_Server_Public/scripts/scan_clamav.sh /usr/local/bin/antivir 2>/dev/null || true
chmod +x /usr/local/bin/antivir 2>/dev/null || true
echo -e "${G}OK: sos infooo antivir${X}"

echo -e "\n${C}[7/10] fail2ban...${X}"
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
echo -e "${G}OK${X}"

echo -e "\n${C}[8/10] .bashrc...${X}"
cat > /root/.bashrc << 'BASHEOF'
# ~/.bashrc — VPN | XRay + AmneziaWG + AdGuard + Semaphore
# v2026-05-01d | = Rooted by VladiMIR + AI | github.com/GinCz =
export PS1='\[\033[01;96m\]\u@\h:\w\$\[\033[00m\] '
HISTCONTROL=ignoredups:ignorespace
shopt -s histappend
HISTSIZE=1000; HISTFILESIZE=2000
shopt -s checkwinsize
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
alias sos="/usr/local/bin/sos 1h"
alias sos3="/usr/local/bin/sos 3h"
alias sos24="/usr/local/bin/sos 24h"
alias sos120="/usr/local/bin/sos 120h"
alias infooo="/usr/local/bin/infooo"
alias antivir="/usr/local/bin/antivir"
alias nginx_st="systemctl status nginx"
alias crowdsec_st="systemctl status crowdsec"
alias banlist="cscli decisions list 2>/dev/null || echo CrowdSec not installed"
alias xray_log="journalctl -u xray -n 50 --no-pager 2>/dev/null"
alias amn_st="systemctl status amneziawg 2>/dev/null || echo AmneziaWG not installed"
alias amn_stat="bash /root/Linux_Server_Public/VPN/AmneziaWG/amnezia_stat.sh 2>/dev/null || echo not found"
alias adg_st="systemctl status AdGuardHome 2>/dev/null || echo AdGuard not installed"
alias adg_restart="systemctl restart AdGuardHome 2>/dev/null || echo AdGuard not installed"
alias adg_log="journalctl -u AdGuardHome -n 30 --no-pager 2>/dev/null"
alias wg_st="wg show 2>/dev/null || echo WireGuard not active"
alias gs="git status"
alias gl="git log --oneline -10"
alias save='cd /root/Linux_Server_Public && git add -A && (git diff --cached --quiet && echo "Nothing to commit" || git commit -m "save: $(hostname) $(date +%Y-%m-%d_%H:%M)") && git pull origin main --no-rebase --no-edit && git push origin main && echo "=== Saved ==="'
alias load='cd /root/Linux_Server_Public && git pull origin main --no-rebase --no-edit && curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh -o /usr/local/bin/sos && chmod +x /usr/local/bin/sos && source ~/.bashrc && echo "=== Loaded ==="'
BASHEOF
echo -e "${G}OK${X}"

echo -e "\n${C}[9/10] UFW...${X}"
ufw --force enable
ufw allow 22/tcp    comment 'SSH'
ufw allow 443/tcp   comment 'Xray/HTTPS'
ufw allow 443/udp   comment 'Xray/QUIC'
ufw allow 51820/udp comment 'WireGuard/AmneziaWG'
ufw allow 53/udp    comment 'AdGuard DNS'
ufw allow 53/tcp    comment 'AdGuard DNS'
ufw allow 853/tcp   comment 'AdGuard DoT'
ufw allow 8080/tcp  comment 'AdGuard Web UI'
ufw reload
echo -e "${G}OK${X}"
ufw status numbered | sed 's/^/  /'

echo -e "\n${C}[10/10] CrowdSec...${X}"
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | bash
apt-get install -y crowdsec crowdsec-firewall-bouncer-iptables
cscli collections install crowdsecurity/linux 2>/dev/null
cscli collections install crowdsecurity/sshd 2>/dev/null
cscli scenarios install crowdsecurity/portscan 2>/dev/null
cscli scenarios install crowdsecurity/ssh-bf 2>/dev/null
systemctl enable crowdsec --now 2>/dev/null
systemctl enable crowdsec-firewall-bouncer --now 2>/dev/null
echo -e "${G}OK${X}"

echo -e "\n${C}======================================"
echo -e "  DONE: ${SRV_NAME} installed!"
echo -e "  Run: source ~/.bashrc && sos"
echo -e "======================================${X}"
source ~/.bashrc 2>/dev/null || true
sos

# = Rooted by VladiMIR | AI = v2026-05-01 = github.com/GinCz/Linux_Server_Public
