#!/bin/bash
clear
# ==========================================================
# install-sos-and-deploy-all.sh
# Run ON SERVER 222 (152.53.182.222) — ONLY from 222!
# 1. Applies fresh blacklist + check_protection_status() on 222
# 2. Pushes the same deploy-blacklist.sh to all 9 remote nodes
# = Rooted by VladiMIR + AI | v.2026.05.27b | github.com/GinCz =
# ==========================================================

set -eo pipefail

RAW="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist"
DEPLOY_URL="$RAW/deploy-blacklist.sh"
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
MY_IP=$(hostname -I | awk '{print $1}')

# Safety check — must run on 222
if [[ "$MY_IP" != "152.53.182.222" ]]; then
  echo "======================================================"
  echo " WARNING: This script must run on server 222!"
  echo " Current IP : $MY_IP"
  echo " Required   : 152.53.182.222 (222-EU-NetCup)"
  echo " SSH keys to all nodes exist only on 222."
  echo ""
  echo " Run this instead on your current server:"
  echo "   bash <(curl -fsSL $DEPLOY_URL)"
  echo "======================================================"
  exit 1
fi

# All 9 remote nodes  name:ip
NODES=(
  "109-RU-FastVDS:212.109.223.109"
  "EU-Alex-47:212.34.148.51"
  "EU-4Ton-237:144.124.228.237"
  "EU-Tatra-Kuma-9:144.124.232.9"
  "VPN-EU-Shahin-227:144.124.228.227"
  "EU-Stolb-AG-24:144.124.239.24"
  "VPN-EU-Pilik-178:195.63.138.33"
  "VPN-EU-ILYA-176:146.103.110.176"
  "EU-SO-38:144.124.233.38"
)

echo "======================================================"
echo " SOS Deploy - VladiMIR Infrastructure (10 Servers)"
echo " Master : 222-EU-NetCup (152.53.182.222)"
echo " Date   : $DATETIME"
echo "======================================================"
echo ""

# ----------------------------------------------------
# STEP 1 - Apply locally on server 222 first
# ----------------------------------------------------
echo "--- [LOCAL] 222-EU-NetCup (152.53.182.222) ---"
bash <(curl -fsSL "$DEPLOY_URL")
echo ""
echo "--- 222 done. Deploying to 9 remote nodes... ---"
echo ""

# ----------------------------------------------------
# STEP 2 - Deploy on all 9 remote nodes via SSH
# ----------------------------------------------------
SUCCESS=0
FAILED=0
FAILED_LIST=""

for ENTRY in "${NODES[@]}"; do
  NAME="${ENTRY%%:*}"
  IP="${ENTRY##*:}"

  echo "--- [REMOTE] $NAME ($IP) ---"

  if ssh \
    -o ConnectTimeout=10 \
    -o StrictHostKeyChecking=no \
    -o BatchMode=yes \
    root@"$IP" \
    "bash <(curl -fsSL '$DEPLOY_URL')" ; then
    echo " OK $NAME"
    ((SUCCESS++)) || true
  else
    echo " FAIL $NAME ($IP) - offline or no SSH key"
    ((FAILED++)) || true
    FAILED_LIST="$FAILED_LIST $NAME($IP)"
  fi
  echo ""
done

# ----------------------------------------------------
# SUMMARY
# ----------------------------------------------------
TOTAL=$((SUCCESS + FAILED + 1))
echo "======================================================"
echo " DEPLOYMENT SUMMARY"
echo "======================================================"
echo " Attempted : $TOTAL servers"
echo " SUCCESS   : $((SUCCESS + 1))  (incl. local 222)"
echo " FAILED    : $FAILED"
if [[ $FAILED -gt 0 ]]; then
  echo " Failed    :$FAILED_LIST"
  echo ""
  echo " Retry manually:"
  echo "   ssh root@IP 'bash <(curl -fsSL $DEPLOY_URL)'"
fi
echo ""
echo " Blacklist: github.com/GinCz/Linux_Server_Public"
echo "======================================================"
