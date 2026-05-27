#!/bin/bash
clear
# ==========================================================
# collect-blacklist.sh — Collect IPs from CrowdSec & push to GitHub
# Run ON SERVER 222 (152.53.182.222)
# Usage: bash collect-blacklist.sh
# Requires: git repo cloned at ~/Linux_Server_Public
# = Rooted by VladiMIR + AI | v.2026.05.27b | github.com/GinCz =
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

# Debug: show raw CrowdSec output header to detect column order
echo "[2/5] Collecting CrowdSec decisions..."
TMP_IPS=$(mktemp)
TMP_CSV_ROWS=$(mktemp)
TMP_RAW=$(mktemp)

# Dump full raw output to temp file
cscli decisions list -o raw 2>/dev/null > "$TMP_RAW" || true

# Show first 2 lines for debug
echo "      CrowdSec raw header:"
head -2 "$TMP_RAW" | sed 's/^/        /'

# Detect which column contains the IP
# Header line looks like: Id,Source,Ip,Reason,Action,Country,Banned,Until
# Find column index of "Ip" header (case-insensitive)
IP_COL=$(head -1 "$TMP_RAW" | tr ',' '\n' | grep -in '^ip$' | cut -d: -f1)
TYPE_COL=$(head -1 "$TMP_RAW" | tr ',' '\n' | grep -in '^reason$' | cut -d: -f1)
DUR_COL=$(head -1 "$TMP_RAW" | tr ',' '\n' | grep -in '^until$' | cut -d: -f1)

# Fallback to column 3 if detection fails
IP_COL=${IP_COL:-3}
TYPE_COL=${TYPE_COL:-4}
DUR_COL=${DUR_COL:-8}

echo "      IP column: $IP_COL | Reason column: $TYPE_COL | Until column: $DUR_COL"

# Parse: skip header row, extract IP, skip empty/header values
awk -F',' -v ipcol="$IP_COL" -v typecol="$TYPE_COL" -v durcol="$DUR_COL" -v date="$DATE" '
  NR == 1 { next }   # skip header
  {
    ip   = $ipcol
    typ  = $typecol
    dur  = $durcol
    gsub(/^ +| +$/, "", ip)
    gsub(/^ +| +$/, "", typ)
    gsub(/^ +| +$/, "", dur)
    # Skip empty, skip header leak ("Ip", "ip", "IP")
    if (ip == "" || tolower(ip) == "ip") next
    # Skip if not a valid IP (must start with digit)
    if (ip !~ /^[0-9]/) next
    print ip
  }
' "$TMP_RAW" >> "$TMP_IPS" || true

# Also collect reason+duration for CSV
awk -F',' -v ipcol="$IP_COL" -v typecol="$TYPE_COL" -v durcol="$DUR_COL" -v date="$DATE" '
  NR == 1 { next }
  {
    ip  = $ipcol; typ = $typecol; dur = $durcol
    gsub(/^ +| +$/, "", ip)
    gsub(/^ +| +$/, "", typ)
    gsub(/^ +| +$/, "", dur)
    if (ip == "" || tolower(ip) == "ip") next
    if (ip !~ /^[0-9]/) next
    print ip "," typ ",222-DE-NetCup," date ",unknown," dur
  }
' "$TMP_RAW" >> "$TMP_CSV_ROWS" || true

rm -f "$TMP_RAW"

# Also grab IPs from iptables manual bans (vladblacklist chain if exists)
if iptables -L vladblacklist -n &>/dev/null; then
  iptables -L vladblacklist -n | awk '/^DROP/{print $4}' | grep -E '^[0-9]+\.' >> "$TMP_IPS" || true
  echo "      + manual iptables bans collected."
fi

# Also grab permanent bans from /etc/crowdsec/ban-list.txt if exists
if [[ -f /etc/crowdsec/ban-list.txt ]]; then
  grep -vE '^#|^$' /etc/crowdsec/ban-list.txt >> "$TMP_IPS" || true
  echo "      + permanent ban-list.txt collected."
fi

COUNT_NEW=$(sort -u "$TMP_IPS" | grep -cE '^[0-9]' || true)
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

sort -u "$TMP_IPS" | grep -E '^[0-9]' >> "$BLACKLIST_TXT"
echo "      Written: $BLACKLIST_TXT"
echo "      Preview (first 5 IPs):"
grep -v '^#' "$BLACKLIST_TXT" | head -5 | sed 's/^/        /'

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

sort -u "$TMP_CSV_ROWS" | grep -E '^[0-9]' >> "$BLACKLIST_CSV" || true
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
