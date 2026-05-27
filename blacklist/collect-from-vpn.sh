#!/bin/bash
clear
# ==========================================================
# collect-from-vpn.sh — Collect IPs from ALL nodes via SSH
# Run ON SERVER 222 (152.53.182.222)
# Collects CrowdSec decisions + iptables manual bans from each node
# Merges with local 222 list, deduplicates, pushes to GitHub
# = Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =
# ==========================================================

set -euo pipefail

REPO_DIR="/root/Linux_Server_Public"
BLACKLIST_TXT="$REPO_DIR/blacklist/blacklist.txt"
BLACKLIST_CSV="$REPO_DIR/blacklist/blacklist-full.csv"
DATE=$(date +%Y-%m-%d)
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')

# All remote nodes (name:ip)
ALL_NODES=(
  "109-RU-FastVDS:212.109.223.109"
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
TMP_CSV=$(mktemp)

echo "================================================"
echo " All-Nodes Blacklist Collector"
echo " Master : 222-EU-NetCup (152.53.182.222)"
echo " Date   : $DATETIME"
echo "================================================"
echo ""

# Remote collection command (runs on each node via SSH)
# Strips Ip: prefix, validates IP, outputs ip,reason,server,date
REMOTE_CMD='bash -s'
REMOTE_SCRIPT='#!/bin/bash
HN=$(hostname)
DATE=$(date +%Y-%m-%d)
# CrowdSec if available
if command -v cscli &>/dev/null; then
  cscli decisions list -o raw 2>/dev/null | awk -F"," -v hn="$HN" -v dt="$DATE" "
    NR==1{next}
    {
      ip=\$3; reason=\$4; dur=\$9
      gsub(/^ +| +$/,"",ip); gsub(/^ +| +$/,"",reason); gsub(/^ +| +$/,"",dur)
      sub(/^[Ii]p:/,"",ip)
      if(ip=="" || ip !~ /^[0-9]/) next
      print ip
      print ip "," reason "," hn "," dt ",crowdsec," dur > "/dev/stderr"
    }
  " 2>/tmp/cs_csv.tmp
  cat /tmp/cs_csv.tmp >&2
  rm -f /tmp/cs_csv.tmp
fi
# iptables manual bans from vladblacklist chain
if iptables -L vladblacklist -n &>/dev/null; then
  iptables -L vladblacklist -n | awk "/^DROP/{print \$4}" | grep -E "^[0-9]" || true
fi
'

# [1] Collect from local server 222 first
echo "[LOCAL] 222-EU-NetCup (152.53.182.222)"
LOCAL_TMP=$(mktemp)
LOCAL_CSV=$(mktemp)
cscli decisions list -o raw 2>/dev/null | awk -F',' -v dt="$DATE" '
  NR==1{next}
  {
    ip=$3; reason=$4; dur=$9
    gsub(/^ +| +$/,"",ip); gsub(/^ +| +$/,"",reason); gsub(/^ +| +$/,"",dur)
    sub(/^[Ii]p:/,"",ip)
    if(ip=="" || ip !~ /^[0-9]/) next
    print ip
  }
' > "$LOCAL_TMP" || true

cscli decisions list -o raw 2>/dev/null | awk -F',' -v dt="$DATE" '
  NR==1{next}
  {
    ip=$3; reason=$4; dur=$9
    gsub(/^ +| +$/,"",ip); gsub(/^ +| +$/,"",reason); gsub(/^ +| +$/,"",dur)
    sub(/^[Ii]p:/,"",ip)
    if(ip=="" || ip !~ /^[0-9]/) next
    print ip "," reason ",222-EU-NetCup," dt ",crowdsec," dur
  }
' > "$LOCAL_CSV" || true

LOCAL_COUNT=$(wc -l < "$LOCAL_TMP")
cat "$LOCAL_TMP" >> "$TMP_ALL"
cat "$LOCAL_CSV" >> "$TMP_CSV"
rm -f "$LOCAL_TMP" "$LOCAL_CSV"
echo "        $LOCAL_COUNT IPs from CrowdSec"
echo ""

# [2] Collect from each remote node
for NODE in "${ALL_NODES[@]}"; do
  NAME="${NODE%%:*}"
  IP="${NODE##*:}"
  printf "[NODE] %-25s " "$NAME ($IP)"

  NODE_TMP=$(mktemp)
  NODE_CSV=$(mktemp)

  # Run remote collection: CrowdSec decisions (strip Ip: prefix) + iptables bans
  ssh -o ConnectTimeout=8 -o StrictHostKeyChecking=no root@"$IP" \
    "bash -c '
      HN=\$(hostname); DT=$DATE
      if command -v cscli &>/dev/null; then
        cscli decisions list -o raw 2>/dev/null | awk -F\",\" -v hn=\"\$HN\" -v dt=\"\$DT\" \"
          NR==1{next}
          {
            ip=\\\$3; reason=\\\$4; dur=\\\$9
            gsub(/^ +| +$/,\"\",ip); sub(/^[Ii]p:/,\"\",ip)
            if(ip==\"\" || ip !~ /^[0-9]/) next
            print ip
            print ip \",\" reason \",\" hn \",\" dt \",crowdsec,\" dur > \"/tmp/_bl_csv\" 
          }
        \" && cat /tmp/_bl_csv >/dev/null 2>&1 || true
      fi
      iptables -L vladblacklist -n 2>/dev/null | awk \"/^DROP/{print \\\$4}\" | grep -E \"^[0-9]\" || true
    '" > "$NODE_TMP" 2>/dev/null || true

  # Also grab CSV via separate call
  ssh -o ConnectTimeout=8 -o StrictHostKeyChecking=no root@"$IP" \
    "bash -c '
      HN=\$(hostname); DT=$DATE
      if command -v cscli &>/dev/null; then
        cscli decisions list -o raw 2>/dev/null | awk -F\",\" -v hn=\"\$HN\" -v dt=\"\$DT\" \"
          NR==1{next}
          {
            ip=\\\$3; reason=\\\$4; dur=\\\$9
            gsub(/^ +| +$/,\"\",ip); sub(/^[Ii]p:/,\"\",ip)
            if(ip==\"\" || ip !~ /^[0-9]/) next
            print ip \",\" reason \",\" hn \",\" dt \",crowdsec,\" dur
          }
        \"
      fi
    '" > "$NODE_CSV" 2>/dev/null || true

  NODE_COUNT=$(grep -cE '^[0-9]' "$NODE_TMP" || true)
  cat "$NODE_TMP" >> "$TMP_ALL"
  cat "$NODE_CSV" >> "$TMP_CSV"
  rm -f "$NODE_TMP" "$NODE_CSV"

  if [[ $NODE_COUNT -gt 0 ]]; then
    echo "$NODE_COUNT IPs"
  else
    echo "0 IPs (no CrowdSec or offline)"
  fi
done

echo ""

# Deduplicate
TOTAL=$(sort -u "$TMP_ALL" | grep -cE '^[0-9]' || true)
echo "Total unique IPs from all nodes: $TOTAL"

if [[ $TOTAL -eq 0 ]]; then
  echo "Nothing to update."
  rm -f "$TMP_ALL" "$TMP_CSV"
  exit 0
fi

# Write blacklist.txt
cat > "$BLACKLIST_TXT" << HEADER
# ==========================================================
# VladiMIR IP Blacklist — Real Attack IPs
# Sources: CrowdSec on all 10 nodes of VladiMIR infrastructure
# Updated: $DATETIME | Total: $TOTAL IPs
# Repo: github.com/GinCz/Linux_Server_Public
# = Rooted by VladiMIR + AI | v.$DATE | github.com/GinCz =
# ==========================================================
HEADER
sort -u "$TMP_ALL" | grep -E '^[0-9]' >> "$BLACKLIST_TXT"

# Write blacklist-full.csv
cat > "$BLACKLIST_CSV" << CSVHEADER
# ==========================================================
# VladiMIR IP Blacklist — Full Database (CSV)
# Columns: ip,reason,source_server,date_added,source,duration
# Updated: $DATETIME | Total: $TOTAL entries
# = Rooted by VladiMIR + AI | v.$DATE | github.com/GinCz =
# ==========================================================
ip,reason,source_server,date_added,source,duration
CSVHEADER
sort -u "$TMP_CSV" | grep -E '^[0-9]' >> "$BLACKLIST_CSV" || true

rm -f "$TMP_ALL" "$TMP_CSV"

# Git push
cd "$REPO_DIR"
git stash 2>/dev/null || true
git pull --rebase
git add blacklist/blacklist.txt blacklist/blacklist-full.csv

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
