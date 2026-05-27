#!/bin/bash
clear
# ==========================================================
# collect-from-vpn.sh — Collect IPs from ALL VPN nodes
# Run ON SERVER 222 — loops all 8 VPN nodes via SSH
# Merges into blacklist.txt and pushes to GitHub
# = Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =
# ==========================================================

set -euo pipefail

REPO_DIR="/root/Linux_Server_Public"
BLACKLIST_TXT="$REPO_DIR/blacklist/blacklist.txt"
DATE=$(date +%Y-%m-%d)
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# All VPN nodes
VPN_NODES=(
  "EU-Alex-47:109.234.38.47"
  "EU-4Ton-237:144.124.228.237"
  "EU-Tatra-Kuma-9:144.124.232.9"
  "VPN-EU-Shahin-227:144.124.228.227"
  "EU-Stolb-AG-24:144.124.239.24"
  "VPN-EU-Pilik-178:91.84.118.178"
  "VPN-EU-ILYA-176:146.103.110.176"
  "EU-SO-38:144.124.233.38"
)

TMP_ALL=$(mktemp)

echo "================================================"
echo " VPN Blacklist Collector — All Nodes"
echo " Date: $DATETIME"
echo "================================================"
echo ""

# Collect from local server 222 first
echo "[LOCAL] 222-DE-NetCup (152.53.182.222)"
cscli decisions list -o raw 2>/dev/null | awk -F',' 'NR>1{gsub(/^ +| +$/, "", $3); if($3 != "") print $3}' >> "$TMP_ALL" || true
LOCAL_COUNT=$(wc -l < "$TMP_ALL")
echo "        $LOCAL_COUNT IPs from CrowdSec"
echo ""

# Collect from each VPN node
for NODE in "${VPN_NODES[@]}"; do
  NAME="${NODE%%:*}"
  IP="${NODE##*:}"
  echo -n "[VPN] $NAME ($IP)... "
  
  # Try to get CrowdSec decisions from this node
  VPN_IPS=$(ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no root@"$IP" \
    "cscli decisions list -o raw 2>/dev/null | awk -F',' 'NR>1{gsub(/^ +| +\\$/, \"\", \\$3); if(\\$3 != \"\") print \\$3}'" \
    2>/dev/null || echo "")
  
  if [[ -n "$VPN_IPS" ]]; then
    COUNT_VPN=$(echo "$VPN_IPS" | wc -l)
    echo "$VPN_IPS" >> "$TMP_ALL"
    echo "$COUNT_VPN IPs"
  else
    echo "skipped (offline or no CrowdSec)"
  fi
done

echo ""

# Deduplicate
TOTAL=$(sort -u "$TMP_ALL" | grep -cE '^[0-9]' || true)
echo "Total unique IPs collected: $TOTAL"

if [[ $TOTAL -eq 0 ]]; then
  echo "Nothing to update."
  rm -f "$TMP_ALL"
  exit 0
fi

# Merge with existing list (preserve existing IPs)
if [[ -f "$BLACKLIST_TXT" ]]; then
  grep -vE '^#|^$' "$BLACKLIST_TXT" >> "$TMP_ALL" || true
fi

# Write new blacklist.txt
cat > "$BLACKLIST_TXT" << HEADER
# ==========================================================
# VladiMIR IP Blacklist — Real Attack IPs
# Source: CrowdSec — server 222 + all 8 VPN nodes
# Updated: $DATETIME | Total: $TOTAL IPs
# Repo: github.com/GinCz/Linux_Server_Public
# = Rooted by VladiMIR + AI | v.$DATE | github.com/GinCz =
# ==========================================================
HEADER

sort -u "$TMP_ALL" | grep -E '^[0-9]' >> "$BLACKLIST_TXT"
rm -f "$TMP_ALL"

# Git push
cd "$REPO_DIR"
git stash 2>/dev/null || true
git pull --rebase
git add blacklist/blacklist.txt

if git diff --cached --quiet; then
  echo "No new IPs since last update."
else
  git commit -m "blacklist: all-nodes update $DATE — $TOTAL unique IPs"
  git push
  echo ""
  echo "================================================"
  echo " Pushed to GitHub! ✅"
  echo " Total IPs: $TOTAL"
  echo " URL: https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt"
  echo "================================================"
fi
