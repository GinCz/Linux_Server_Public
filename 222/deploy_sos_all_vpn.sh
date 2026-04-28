#!/usr/bin/env bash
# = Rooted by VladiMIR | AI =
# deploy_sos_all_vpn.sh — Install/update sos on all 8 VPN nodes
# v2026-04-28
#
# Run from: 222-DE-NetCup as root
# Requirements: passwordless SSH keys must be set up from 222 to all nodes
#
# USAGE:
#   bash deploy_sos_all_vpn.sh
#
# HOW TO ADD SSH KEY TO A NODE (one-time, if password is requested):
#   ssh-copy-id -o StrictHostKeyChecking=accept-new root@<IP>
#
# HOW TO CLEAR OLD HOST KEY (if server was reinstalled):
#   ssh-keygen -f "/root/.ssh/known_hosts" -R "<IP>"

clear

SOS_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/222/sos.sh"
SOS_DST="/usr/local/bin/sos"

# Real IPs are kept private — replace xxx.xxx.xxx.XX with actual node IPs
NODES=(
  "ALEX_47     xxx.xxx.xxx.47"
  "4TON_237    xxx.xxx.xxx.237"
  "TATRA_9     xxx.xxx.xxx.9"
  "SHAHIN_227  xxx.xxx.xxx.227"
  "STOLB_24    xxx.xxx.xxx.24"
  "PILIK_178   xxx.xxx.xxx.178"
  "ILYA_176    xxx.xxx.xxx.176"
  "SO_38       xxx.xxx.xxx.38"
)

G=$'\033[1;32m'; R=$'\033[1;31m'; Y=$'\033[1;33m'; W=$'\033[1;37m'; X=$'\033[0m'

echo "${W}================================================================${X}"
echo "${W}  Deploy SOS → all 8 VPN nodes   $(date '+%Y-%m-%d %H:%M:%S')${X}"
echo "${W}================================================================${X}"
echo ""

OK=0; FAIL=0

for entry in "${NODES[@]}"; do
  NAME=$(echo "$entry" | awk '{print $1}')
  IP=$(echo   "$entry" | awk '{print $2}')

  printf "  %-14s  ${W}%-18s${X} ... " "${Y}${NAME}${X}" "${IP}"

  ssh -o ConnectTimeout=8 \
      -o StrictHostKeyChecking=accept-new \
      -o BatchMode=yes \
      root@"${IP}" \
      "curl -fsSL ${SOS_URL} -o ${SOS_DST} && chmod +x ${SOS_DST} && echo OK" \
      2>/dev/null | grep -q "^OK$"

  if [[ $? -eq 0 ]]; then
    echo "${G}✓ installed${X}"
    (( OK++ ))
  else
    echo "${R}✗ FAILED${X}"
    (( FAIL++ ))
  fi
done

echo ""
echo "${W}================================================================${X}"
echo "  Result: ${G}${OK} OK${X}  /  ${R}${FAIL} FAILED${X}"
echo "${W}================================================================${X}"
