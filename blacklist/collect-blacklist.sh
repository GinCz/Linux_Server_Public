#!/bin/bash
clear
# ==========================================================
# collect-blacklist.sh — Collect IPs from CrowdSec & push to GitHub
# Run ON SERVER 222 (152.53.182.222)
# Usage: bash collect-blacklist.sh
# Requires: git repo cloned at ~/Linux_Server_Public
# = Rooted by VladiMIR + AI | v.2026.05.27 | github.com/GinCz =
# ==========================================================

set -euo pipefail

REPO_DIR="/root/Linux_Server_Public"
BLACKLIST_DIR="$REPO_DIR/blacklist"
BLACKLIST_TXT="$BLACKLIST_DIR/blacklist.txt"
BLACKLIST_CSV="$BLACKLIST_DIR/blacklist-full.csv"
DATE=$(date +%Y-%m-%d)
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

echo "================================================"
echo " Blacklist Collector — VladiMIR Infrastructure"
echo " Server : $HOSTNAME"
echo " Date   : $DATETIME"
echo "================================================"
echo ""

# Check we're on server 222
SERVER_IP=$(hostname -I | awk '{print $1}')
if [[ "$SERVER_IP" != "152.53.182.222" ]]; then
  echo "WARNING: This script is designed for server 222 (152.53.182.222)"
  echo "Current IP: $SERVER_IP"
  echo "Continue anyway? [y/N]"
  read -r CONFIRM
  [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && exit 1
fi

# Check repo exists
if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "ERROR: Git repo not found at $REPO_DIR"
  echo "Run: git clone https://github.com/GinCz/Linux_Server_Public ~/Linux_Server_Public"
  exit 1
fi

# Pull latest repo
echo "[1/5] Updating repo..."
cd "$REPO_DIR"
git stash 2>/dev/null || true
git pull --rebase
echo "      Done."

# Collect IPs from CrowdSec decisions
echo "[2/5] Collecting CrowdSec decisions..."
TMP_IPS=$(mktemp)
TMP_CSV_ROWS=$(mktemp)

# Active decisions: parse raw CSV output
cscli decisions list -o raw 2>/dev/null | awk -F',' '
  NR > 1 {
    ip   = $3
    type = $5
    dur  = $6
    gsub(/^ +| +$/, "", ip)
    gsub(/^ +| +$/, "", type)
    gsub(/^ +| +$/, "", dur)
    if (ip != "" && ip !~ /^#/) {
      print ip > "/dev/stdout"
      print ip "," type ",222-DE-NetCup,'$DATE',unknown," dur > "/dev/stderr"
    }
  }
' 1>>"$TMP_IPS" 2>>"$TMP_CSV_ROWS" || true

# Also grab IPs from iptables manual bans (vladblacklist chain if exists)
if iptables -L vladblacklist -n &>/dev/null; then
  iptables -L vladblacklist -n | awk '/^DROP/{print $4}' | grep -E '^[0-9]+\.' >> "$TMP_IPS" || true
fi

# Also grab permanent bans from /etc/crowdsec/ban-list.txt if exists
[[ -f /etc/crowdsec/ban-list.txt ]] && grep -vE '^#|^$' /etc/crowdsec/ban-list.txt >> "$TMP_IPS" || true

COUNT_NEW=$(sort -u "$TMP_IPS" | wc -l)
echo "      Found $COUNT_NEW unique IPs."

if [[ $COUNT_NEW -eq 0 ]]; then
  echo "      No IPs found. Nothing to update."
  rm -f "$TMP_IPS" "$TMP_CSV_ROWS"
  exit 0
fi

# Build new blacklist.txt
echo "[3/5] Writing blacklist.txt..."
cat > "$BLACKLIST_TXT" << HEADER
# ==========================================================
# VladiMIR IP Blacklist — Real Attack IPs
# Source: CrowdSec decisions, server 222 (152.53.182.222)
# Updated: $DATETIME | Total: $COUNT_NEW IPs
# Repo: github.com/GinCz/Linux_Server_Public
# = Rooted by VladiMIR + AI | v.$DATE | github.com/GinCz =
# ==========================================================
HEADER

sort -u "$TMP_IPS" | grep -vE '^#|^$' >> "$BLACKLIST_TXT"
echo "      Written: $BLACKLIST_TXT"

# Build/update blacklist-full.csv
echo "[4/5] Writing blacklist-full.csv..."
cat > "$BLACKLIST_CSV" << CSVHEADER
# ==========================================================
# VladiMIR IP Blacklist — Full Database (CSV)
# Columns: ip,reason,source_server,date_added,country,duration
# Source: CrowdSec + manual bans on server 222
# Updated: $DATETIME | Total: $COUNT_NEW entries
# = Rooted by VladiMIR + AI | v.$DATE | github.com/GinCz =
# ==========================================================
ip,reason,source_server,date_added,country,duration
CSVHEADER

sort -u "$TMP_CSV_ROWS" | grep -vE '^#|^$' >> "$BLACKLIST_CSV" || true
echo "      Written: $BLACKLIST_CSV"

rm -f "$TMP_IPS" "$TMP_CSV_ROWS"

# Git commit & push
echo "[5/5] Pushing to GitHub..."
cd "$REPO_DIR"
git add blacklist/blacklist.txt blacklist/blacklist-full.csv

if git diff --cached --quiet; then
  echo "      No changes to commit."
else
  git commit -m "blacklist: auto-update $DATE — $COUNT_NEW IPs from $HOSTNAME"
  git push
  echo "      Pushed to GitHub! ✅"
fi

echo ""
echo "================================================"
echo " Blacklist update complete!"
echo " IPs in list : $COUNT_NEW"
echo " File        : blacklist/blacklist.txt"
echo " Public URL  : https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt"
echo "================================================"
