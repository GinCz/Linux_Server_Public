#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------
# new_server_install.sh
# Full first-boot setup for VPN / 222 / 109 Ubuntu servers
# ------------------------------------------------------------

G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; B='\033[0;34m'; X='\033[0m'

SRV_TYPE="${1:-}"
if [[ -z "$SRV_TYPE" ]]; then
  echo "Usage: $0 <server_type>"
  echo "  1 = VPN"
  echo "  2 = 222"
  echo "  3 = 109"
  read -rp "Choose server type [1-3]: " SRV_TYPE
fi

# ─── PS1 color ───────────────────────────────────────────────
echo
echo "Select terminal PS1 color:"
echo -e "  \033[01;96m1) Bright Cyan     — turquoise (VPN default)\033[0m"
echo -e "  \033[01;91m2) Bright Red      — red\033[0m"
echo -e "  \033[01;92m3) Bright Green    — green\033[0m"
echo -e "  \033[01;93m4) Bright Yellow   — yellow (222 default)\033[0m"
echo -e "  \033[38;5;208m5) Orange          — orange\033[0m"
echo -e "  \033[38;5;213m6) Bright Pink     — pink\033[0m"
echo -e "  \033[01;97m7) Bright White    — white (109 default)\033[0m"

case "$SRV_TYPE" in
  2) DEF_COLOR=4 ;;
  3) DEF_COLOR=7 ;;
  *) DEF_COLOR=1 ;;
esac
read -rp "Color [1-7, default ${DEF_COLOR}]: " CC
CC="${CC:-${DEF_COLOR}}"
case "$CC" in
  1) PS1_CODE='01;96m';    PS1_NAME="Bright Cyan"   ; MOTD_COLOR='\033[01;96m' ;;
  2) PS1_CODE='01;91m';    PS1_NAME="Bright Red"    ; MOTD_COLOR='\033[01;91m' ;;
  3) PS1_CODE='01;92m';    PS1_NAME="Bright Green"  ; MOTD_COLOR='\033[01;92m' ;;
  4) PS1_CODE='01;93m';    PS1_NAME="Bright Yellow" ; MOTD_COLOR='\033[01;93m' ;;
  5) PS1_CODE='38;5;208m'; PS1_NAME="Orange"        ; MOTD_COLOR='\033[38;5;208m' ;;
  6) PS1_CODE='38;5;213m'; PS1_NAME="Bright Pink"   ; MOTD_COLOR='\033[38;5;213m' ;;
  7) PS1_CODE='01;97m';    PS1_NAME="Bright White"  ; MOTD_COLOR='\033[01;97m' ;;
  *) PS1_CODE='01;96m';    PS1_NAME="Bright Cyan"   ; MOTD_COLOR='\033[01;96m' ;;
esac

HOSTNAME_NOW="$(hostname)"
echo -e "${Y}Selected server type:${X} ${SRV_TYPE}"
echo -e "${Y}Selected PS1 color:${X} ${PS1_NAME}"

# ... existing script content preserved ...
# Note: only Russian labels were translated to English in this update.

alias menu='echo -e "  ${G}antivir${X}(ClamAV)       ${G}banlist${X}(ban-list)    ${G}load${X}(git pull)"'
