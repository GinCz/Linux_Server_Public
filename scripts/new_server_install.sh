#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  new_server_install.sh | [v2026-08-17]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Initial provisioning script for fresh Ubuntu 24 LTS servers
# Servers     : All Fresh Nodes
# Usage       : bash scripts/new_server_install.sh
# ==========================================================================================
clear
export PATH=$PATH:/usr/sbin:/sbin:/usr/bin:/bin

C='\033[1;37m'; X='\033[0m'
echo -e "${C}=========================================${X}"
echo -e "${C}   NEW SERVER SETUP v2026-08-17${X}"
echo -e "${C}   = Rooted by VladiMIR | AI =${X}"
echo -e "${C}=========================================${X}"
echo

CURR_HOST="$(hostname)"
read -rp "Enter server name [default: ${CURR_HOST}]: " SRV_NAME
SRV_NAME="${SRV_NAME:-${CURR_HOST}}"
[[ -n "${SRV_NAME:-}" ]] || SRV_NAME="Server-$(hostname -I 2>/dev/null | awk '{print $1}')"

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
echo -e "  \033[01;96m1) Bright Cyan     — turquoise (VPN default)\033[0m"
echo -e "  \033[01;91m2) Bright Red      — red\033[0m"
echo -e "  \033[01;92m3) Bright Green    — green\033[0m"
echo -e "  \033[01;93m4) Bright Yellow   — yellow (222 default)\033[0m"
echo -e "  \033[01;95m5) Bright Magenta  — magenta\033[0m"
echo -e "  \033[38;5;208m6) Orange          — orange\033[0m"
echo -e "  \033[38;5;213m7) Bright Pink     — pink\033[0m"
echo -e "  \033[01;97m8) Bright White    — white (109 default)\033[0m"

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
echo
read -rp "Continue? [YES/no]: " OK
[[ "${OK:-YES}" =~ ^(YES|yes|y|)$ ]] || { echo "Aborted"; exit 1; }

# Hostname
if [[ "$INSTALL_MODE" == "FULL" ]]; then
  hostnamectl set-hostname "${SRV_NAME}"
  sed -i "s/^127.0.1.1.*/127.0.1.1 ${SRV_NAME}/" /etc/hosts 2>/dev/null || echo "127.0.1.1 ${SRV_NAME}" >> /etc/hosts
  echo "${SRV_NAME}" > /etc/hostname
  timedatectl set-timezone Europe/Prague
fi

# Clone/Pull public repo
mkdir -p /root/Linux_Server_Public
if [ ! -d "/root/Linux_Server_Public/.git" ]; then
  git clone https://github.com/GinCz/Linux_Server_Public.git /root/Linux_Server_Public 2>/dev/null || true
else
  cd /root/Linux_Server_Public && git pull origin main 2>/dev/null || true
fi

# Apply Aliases & MC Menu
if [ -x /root/Linux_Server_Public/scripts/apply_aliases.sh ]; then
  case "$SRV_TYPE" in
    2) bash /root/Linux_Server_Public/scripts/apply_aliases.sh 222 ;;
    3) bash /root/Linux_Server_Public/scripts/apply_aliases.sh 109 ;;
    *) bash /root/Linux_Server_Public/scripts/apply_aliases.sh VPN ;;
  esac
fi

# Apply MOTD Banner
case "$SRV_TYPE" in
  2) MOTD_SRC="/root/Linux_Server_Public/222/motd_server.sh" ;;
  3) MOTD_SRC="/root/Linux_Server_Public/109/motd_server.sh" ;;
  *) MOTD_SRC="/root/Linux_Server_Public/VPN/motd_server.sh" ;;
esac
[[ -f "$MOTD_SRC" ]] && cp -f "$MOTD_SRC" /etc/profile.d/motd_server.sh && chmod +x /etc/profile.d/motd_server.sh

chmod -x /etc/update-motd.d/* 2>/dev/null || true
> /etc/motd
touch /root/.hushlogin

echo
echo -e "\033[1;32m✔ Установка завершена успешно! Нажмите Enter для перезагрузки оболочки...\033[0m"
read -r
exec bash -l
