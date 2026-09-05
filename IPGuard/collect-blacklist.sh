#!/bin/bash
clear
# ==========================================================
# collect-blacklist.sh — Collect IPs from CrowdSec & push to GitHub
# Run ON SERVER 222 (152.53.182.222)
# Usage: bash collect-blacklist.sh
# Requires: git repo cloned at ~/Linux_Server_Public
# = Rooted by VladiMIR + AI | v.2026.06.29 | github.com/GinCz =
# NOTE: CrowdSec v1.7 raw output has format: Ip:1.2.3.4 in the ip column
#       This script strips that prefix automatically.
# WHITELIST: own infrastructure IPs are ALWAYS excluded from blacklist!
# ==========================================================

set -euo pipefail

REPO_DIR="/root/Linux_Server_Public"
BLACKLIST_DIR="$REPO_DIR/blacklist"
BLACKLIST_TXT="$BLACKLIST_DIR/blacklist.txt"
BLACKLIST_CSV="$BLACKLIST_DIR/blacklist-full.csv"
DATE=$(date +%Y-%m-%d)
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

# ==========================================================
# WHITELIST — these IPs/subnets are NEVER added to blacklist
# Own servers, VPN nodes, home/work IPs
# ==========================================================
WHITELIST_IPS=(
  # Own servers
  "152.53.182.222"   # DE server 222
  "212.109.223.109"  # RU server 109
  "82.223.116.38"    # IONOS
  "3.79.14.42"       # AWS VPN XRAY
  # VPN nodes
  "212.34.148.51"    # VPN ALEX_51
  "144.124.228.237"  # VPN 4TON_237
  "144.124.232.9"    # VPN TATRA_9
  "144.124.228.227"  # VPN SHAHIN_227
  "144.124.239.24"   # VPN STOLB_24
  "195.63.138.33"    # VPN PILIK_33
  "146.103.110.176"  # VPN ILYA_176
  "144.124.233.38"   # VPN SO_38
  # Home IPs
  "185.100.197.16"   # Home IP
  "185.14.233.235"   # Home IP
  "185.14.232.0"     # Home IP
  # Work IP
  "90.181.133.10"    # Work IP
  # Mobile IPs
  "37.48.9.111"      # Vladimir mobile
  "89.24.41.133"     # Wife mobile
  # Konstantin Stolb
  "83.217.9.81"
  "188.226.83.81"
  # CloudFlare (do not ban CF nodes)
  "141.101.234.14"
  "82.112.63.133"
)

# Build regex pattern from whitelist
WHITELIST_PATTERN=$(printf '%s\n' "${WHITELIST_IPS[@]}" | grep -v '^#' | grep -v '^$' | sed 's|\.|\\.|g' | paste -sd'|')

is_whitelisted() {
  local ip="$1"
  for wip in "${WHITELIST_IPS[@]}"; do
    [[ "$wip" == "#"* ]] && continue
    [[ -z "$wip" ]] && continue
    if [[ "$ip" == "$wip" ]]; then
      return 0
    fi
  done
  return 1
}

echo "================================================"
echo " Blacklist Collector — VladiMIR Infrastructure"
echo " Server : $HOSTNAME"
echo " Date   : $DATETIME"
echo "================================================"
echo ""
echo " Whitelist: ${#WHITELIST_IPS[@]} protected IPs (never blacklisted)"
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

echo "[2/5] Collecting CrowdSec decisions..."
TMP_IPS=$(mktemp)
TMP_CSV_ROWS=$(mktemp)
TMP_RAW=$(mktemp)
TMP_FILTERED=$(mktemp)

# Dump full raw output
cscli decisions list -o raw 2>/dev/null > "$TMP_RAW" || true

# Show header + example for debug
echo "      CrowdSec raw header:"
head -2 "$TMP_RAW" | sed 's/^/        /'

# Detect column indices from header
HEADER_LINE=$(head -1 "$TMP_RAW")
IP_COL=$(echo "$HEADER_LINE" | tr ',' '\n' | grep -in '^ip$' | cut -d: -f1)
TYPE_COL=$(echo "$HEADER_LINE" | tr ',' '\n' | grep -in '^reason$' | cut -d: -f1)
DUR_COL=$(echo "$HEADER_LINE" | tr ',' '\n' | grep -in '^expiration$' | cut -d: -f1)

# Fallbacks
IP_COL=${IP_COL:-3}
TYPE_COL=${TYPE_COL:-4}
DUR_COL=${DUR_COL:-9}

echo "      Columns: ip=$IP_COL reason=$TYPE_COL expiration=$DUR_COL"

# Parse: skip header, extract IP, strip 'Ip:' prefix (CrowdSec v1.7 format)
awk -F',' -v ipcol="$IP_COL" -v typecol="$TYPE_COL" -v durcol="$DUR_COL" '
  NR == 1 { next }
  {
    ip  = $ipcol
    typ = $typecol
    dur = $durcol
    gsub(/^ +| +$/, "", ip)
    gsub(/^ +| +$/, "", typ)
    gsub(/^ +| +$/, "", dur)
    sub(/^[Ii]p:/, "", ip)
    if (ip == "" || ip !~ /^[0-9]/) next
    print ip
  }
' "$TMP_RAW" >> "$TMP_IPS" || true

# Collect reason+duration for CSV
awk -F',' -v ipcol="$IP_COL" -v typecol="$TYPE_COL" -v durcol="$DUR_COL" -v date="$DATE" '
  NR == 1 { next }
  {
    ip  = $ipcol; typ = $typecol; dur = $durcol
    gsub(/^ +| +$/, "", ip)
    gsub(/^ +| +$/, "", typ)
    gsub(/^ +| +$/, "", dur)
    sub(/^[Ii]p:/, "", ip)
    if (ip == "" || ip !~ /^[0-9]/) next
    print ip "," typ ",222-DE-NetCup," date ",unknown," dur
  }
' "$TMP_RAW" >> "$TMP_CSV_ROWS" || true

rm -f "$TMP_RAW"

# Also grab IPs from iptables manual bans
if iptables -L vladblacklist -n &>/dev/null; then
  iptables -L vladblacklist -n | awk '/^DROP/{print $4}' | grep -E '^[0-9]+\.' >> "$TMP_IPS" || true
  echo "      + manual iptables bans collected."
fi

# Also grab permanent bans
if [[ -f /etc/crowdsec/ban-list.txt ]]; then
  grep -vE '^#|^$' /etc/crowdsec/ban-list.txt >> "$TMP_IPS" || true
  echo "      + permanent ban-list.txt collected."
fi

# ==========================================================
# WHITELIST FILTER — remove own IPs before writing blacklist
# ==========================================================
echo "      Applying whitelist filter..."
WHITELISTED_REMOVED=0
while IFS= read -r ip; do
  [[ -z "$ip" ]] && continue
  if is_whitelisted "$ip"; then
    echo "      ⚠️  WHITELIST HIT — removed from blacklist: $ip"
    ((WHITELISTED_REMOVED++)) || true
  else
    echo "$ip" >> "$TMP_FILTERED"
  fi
done < <(sort -u "$TMP_IPS" | grep -E '^[0-9]')

if [[ $WHITELISTED_REMOVED -gt 0 ]]; then
  echo "      ✅ Removed $WHITELISTED_REMOVED whitelisted IP(s) from blacklist!"
fi

COUNT_NEW=$(grep -cE '^[0-9]' "$TMP_FILTERED" || true)
echo "      Found $COUNT_NEW unique IPs (after whitelist filter)."

rm -f "$TMP_IPS"

if [[ $COUNT_NEW -eq 0 ]]; then
  echo "      No IPs found. Nothing to update."
  rm -f "$TMP_FILTERED" "$TMP_CSV_ROWS"
  exit 0
fi

# Build new blacklist.txt — also include manual.txt entries
echo "[3/5] Writing blacklist.txt..."
cat > "$BLACKLIST_TXT" << HEADER
# ==========================================================
# VladiMIR IP Blacklist — Real Attack IPs
# Source: CrowdSec decisions, server 222 (152.53.182.222)
# Updated: $DATETIME | Total: $COUNT_NEW IPs
# WHITELIST applied: own infrastructure IPs never appear here
# Repo: github.com/GinCz/Linux_Server_Public
# = Rooted by VladiMIR + AI | v.$DATE | github.com/GinCz =
# ==========================================================
HEADER

# Include manual.txt entries (subnets, manual bans) if exists
if [[ -f "$BLACKLIST_DIR/manual.txt" ]]; then
  echo "# --- Manual subnets/IPs (from manual.txt) ---" >> "$BLACKLIST_TXT"
  grep -vE '^#|^[[:space:]]*$' "$BLACKLIST_DIR/manual.txt" >> "$BLACKLIST_TXT" || true
  echo "# --- Auto-collected from CrowdSec ---" >> "$BLACKLIST_TXT"
  MANUAL_COUNT=$(grep -cvE '^#|^[[:space:]]*$' "$BLACKLIST_DIR/manual.txt" || true)
  echo "      + manual.txt included ($MANUAL_COUNT entries)."
fi

cat "$TMP_FILTERED" >> "$BLACKLIST_TXT"
rm -f "$TMP_FILTERED"

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

# Filter CSV rows through whitelist too
while IFS= read -r row; do
  ip=$(echo "$row" | cut -d',' -f1)
  is_whitelisted "$ip" || echo "$row" >> "$BLACKLIST_CSV"
done < <(sort -u "$TMP_CSV_ROWS" | grep -E '^[0-9]')

rm -f "$TMP_CSV_ROWS"
echo "      Written: $BLACKLIST_CSV"

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
echo " Whitelist   : ${#WHITELIST_IPS[@]} IPs protected (never blacklisted)"
echo " File        : blacklist/blacklist.txt"
echo " Public URL  : https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt"
echo "================================================"
