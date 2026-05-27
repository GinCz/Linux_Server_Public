#!/bin/bash
clear
# ==========================================================
# deploy-blacklist.sh — Apply GitHub blacklist to THIS server
# Run on ANY server (VPN nodes, 109, 222, new servers)
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh)
# = Rooted by VladiMIR + AI | v.2026.05.27d | github.com/GinCz =
# ==========================================================

set -euo pipefail

BLACKLIST_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt"
IPSET_NAME="vladblacklist"
IPSET_TMP="vladblacklist_tmp"
LOG_FILE="/var/log/vladblacklist.log"
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

echo "================================================"
echo " Blacklist Deploy — VladiMIR Infrastructure"
echo " Server : $HOSTNAME"
echo " Date   : $DATETIME"
echo " Source : $BLACKLIST_URL"
echo "================================================"
echo ""

# Check requirements
for cmd in curl iptables ipset; do
  if ! command -v $cmd &>/dev/null; then
    echo "Installing $cmd..."
    apt-get install -y $cmd -qq
  fi
done

# Download blacklist
echo "[1/4] Downloading blacklist..."
TMP_LIST=$(mktemp)
curl -fsSL "$BLACKLIST_URL" -o "$TMP_LIST"
COUNT=$(grep -cvE '^#|^$' "$TMP_LIST" || true)
echo "      Downloaded $COUNT IPs."

if [[ $COUNT -eq 0 ]]; then
  echo "      Blacklist is empty. Nothing to apply."
  rm -f "$TMP_LIST"
  exit 0
fi

# Build NEW ipset in a temp set, then swap atomically
# This way the iptables rule is never broken during update
echo "[2/4] Building ipset '$IPSET_NAME'..."

# Destroy temp set if leftover from previous failed run
ipset destroy "$IPSET_TMP" 2>/dev/null || true
ipset create "$IPSET_TMP" hash:net maxelem 65536

ADDED=0
FAILED=0
while IFS= read -r line; do
  [[ "$line" =~ ^#|^[[:space:]]*$ ]] && continue
  ip=$(echo "$line" | sed 's/#.*//' | tr -d '[:space:]')
  [[ -z "$ip" ]] && continue
  if ipset add "$IPSET_TMP" "$ip" 2>/dev/null; then
    ((ADDED++)) || true
  else
    ((FAILED++)) || true
  fi
done < "$TMP_LIST"

rm -f "$TMP_LIST"
echo "      Added: $ADDED IPs | Skipped/Failed: $FAILED"

# If main set doesn't exist yet — create it, then swap
if ! ipset list "$IPSET_NAME" &>/dev/null; then
  ipset create "$IPSET_NAME" hash:net maxelem 65536
fi

# Atomic swap: replace live set contents without breaking iptables rule
ipset swap "$IPSET_TMP" "$IPSET_NAME"
ipset destroy "$IPSET_TMP"
echo "      Swapped '$IPSET_TMP' -> '$IPSET_NAME' atomically."

# Apply iptables rule (idempotent)
echo "[3/4] Applying iptables rule..."
iptables -D INPUT -m set --match-set "$IPSET_NAME" src -j DROP 2>/dev/null || true
iptables -I INPUT 1 -m set --match-set "$IPSET_NAME" src -j DROP
echo "      iptables rule added: DROP all from $IPSET_NAME."

# Persist rules across reboots
echo "[4/4] Saving rules for persistence..."
mkdir -p /etc/iptables
if command -v netfilter-persistent &>/dev/null; then
  netfilter-persistent save
else
  iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
  ip6tables-save > /etc/iptables/rules.v6 2>/dev/null || true
  echo "      Saved to /etc/iptables/rules.v4"
fi

# Persist ipset
ipset save > /etc/ipset.rules 2>/dev/null || true

# Add @reboot restore to cron if not already there
if ! crontab -l 2>/dev/null | grep -q 'ipset restore'; then
  (crontab -l 2>/dev/null; echo "@reboot sleep 5 && ipset restore < /etc/ipset.rules 2>/dev/null; iptables-restore < /etc/iptables/rules.v4 2>/dev/null") | crontab -
  echo "      @reboot restore added to crontab."
fi

# Log the deployment
echo "$DATETIME | $HOSTNAME | $ADDED IPs applied from vladblacklist" >> "$LOG_FILE" 2>/dev/null || true

echo ""
echo "================================================"
echo " Blacklist deployed successfully! ✅"
echo " Server   : $HOSTNAME"
echo " IPs added: $ADDED"
echo " Rule     : iptables DROP all from ipset '$IPSET_NAME'"
echo " Log      : $LOG_FILE"
echo "================================================"
echo ""
echo "To verify:"
echo "  ipset list $IPSET_NAME | head -20"
echo "  iptables -L INPUT -n | grep $IPSET_NAME"
