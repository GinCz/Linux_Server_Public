#!/bin/bash
clear
# ==========================================================
# deploy-blacklist.sh — Apply GitHub blacklist to THIS server
# Run on ANY server (VPN nodes, 109, 222, new servers)
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh)
# = Rooted by VladiMIR + AI | v.2026.05.27e | github.com/GinCz =
# ==========================================================

set -euo pipefail

BLACKLIST_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt"
IPSET_NAME="vladblacklist"
IPSET_TMP="vladblacklist_tmp"
LOG_FILE="/var/log/vladblacklist.log"
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

# ==========================================================
# check_protection_status — Universal defense health check
# Works on ALL servers: 222, 109, VPN nodes, any new server
# Checks: ipset, iptables blacklist rule, fail2ban, crowdsec
# ==========================================================
check_protection_status() {
  echo ""
  echo "================================================"
  echo " Protection Status Check — $HOSTNAME"
  echo "================================================"

  local ok=0
  local warn=0

  # --- ipset ---
  if command -v ipset &>/dev/null && ipset list "$IPSET_NAME" &>/dev/null; then
    local ip_count
    ip_count=$(ipset list "$IPSET_NAME" 2>/dev/null | grep -c "^\." 2>/dev/null || \
               ipset list "$IPSET_NAME" 2>/dev/null | awk '/^Members:/{found=1;next} found && NF' | wc -l || echo 0)
    echo " [✅] ipset '$IPSET_NAME'     ACTIVE  — $ip_count IPs blocked"
    ((ok++)) || true
  elif command -v ipset &>/dev/null && ipset list "$IPSET_NAME" 2>/dev/null | grep -q 'Name:'; then
    echo " [✅] ipset '$IPSET_NAME'     ACTIVE"
    ((ok++)) || true
  else
    echo " [❌] ipset '$IPSET_NAME'     NOT LOADED — run this script to deploy"
    ((warn++)) || true
  fi

  # --- iptables rule ---
  if iptables -L INPUT -n 2>/dev/null | grep -q "$IPSET_NAME"; then
    echo " [✅] iptables DROP rule      ACTIVE  — blocking ipset '$IPSET_NAME'"
    ((ok++)) || true
  else
    echo " [❌] iptables DROP rule      MISSING — blacklist not enforced"
    ((warn++)) || true
  fi

  # --- fail2ban ---
  if systemctl is-active --quiet fail2ban 2>/dev/null; then
    local jails
    jails=$(fail2ban-client status 2>/dev/null | grep 'Jail list' | sed 's/.*Jail list:\s*//' | tr -d ' ' | tr ',' ' ' | wc -w || echo "?")
    echo " [✅] fail2ban                RUNNING — $jails jail(s) active"
    ((ok++)) || true
  elif command -v fail2ban-client &>/dev/null; then
    echo " [⚠️ ] fail2ban                INSTALLED but not running"
    ((warn++)) || true
  else
    echo " [➖] fail2ban                NOT INSTALLED (optional)"
  fi

  # --- CrowdSec ---
  if systemctl is-active --quiet crowdsec 2>/dev/null; then
    local cs_bans
    cs_bans=$(cscli decisions list 2>/dev/null | grep -c 'ban' || echo "?")
    echo " [✅] CrowdSec                RUNNING — $cs_bans active ban(s)"
    ((ok++)) || true
  elif command -v cscli &>/dev/null; then
    echo " [⚠️ ] CrowdSec                INSTALLED but not running"
    ((warn++)) || true
  else
    echo " [➖] CrowdSec                NOT INSTALLED (optional)"
  fi

  # --- UFW / firewalld (bonus check) ---
  if systemctl is-active --quiet ufw 2>/dev/null || ufw status 2>/dev/null | grep -q 'Status: active'; then
    echo " [✅] UFW firewall             ACTIVE"
    ((ok++)) || true
  elif systemctl is-active --quiet firewalld 2>/dev/null; then
    echo " [✅] firewalld                ACTIVE"
    ((ok++)) || true
  fi

  # --- Auto-update cron ---
  if crontab -l 2>/dev/null | grep -q 'deploy-blacklist'; then
    local cron_line
    cron_line=$(crontab -l 2>/dev/null | grep 'deploy-blacklist' | head -1)
    echo " [✅] Auto-update cron        SET     — $cron_line"
    ((ok++)) || true
  else
    echo " [⚠️ ] Auto-update cron        NOT SET — blacklist won't auto-refresh"
    ((warn++)) || true
  fi

  echo "------------------------------------------------"
  if [[ $warn -eq 0 ]]; then
    echo " RESULT: ✅ All protection systems OPERATIONAL"
  else
    echo " RESULT: ⚠️  $warn check(s) need attention, $ok OK"
  fi
  echo "================================================"
  echo ""
}

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
echo ""

# Run protection status check after every deploy
check_protection_status
