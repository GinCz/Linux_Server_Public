#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  deploy-blacklist.sh | [v2026-08-18]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Phase 3: Global deployment (pull GitHub blacklist, apply ipset DROP rules)
# Servers     : All Linux Nodes (222-DE / 109-RU / VPN Nodes)
# Usage       : Cron -> 30 */3 * * * bash deploy-blacklist.sh
# ==========================================================================================

set -uo pipefail

BLACKLIST_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/IPGuard/blacklist.txt"
IPSET_NAME="vladblacklist"
IPSET_TMP="vladblacklist_tmp"
LOG_FILE="/var/log/vladblacklist.log"
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

# ==========================================================
# ensure_admin_whitelist — Guarantee Admin IP is Top-1 Priority
# Prevents accidental lockout by CrowdSec, ipset, or Fail2ban
# ==========================================================
ensure_admin_whitelist() {
  local admin_ip="194.228.224.76"
  # If admin rule is not at position 1, re-insert it
  local pos1_rule
  pos1_rule=$(iptables -L INPUT 1 -n 2>/dev/null || true)
  if ! echo "$pos1_rule" | grep -q "$admin_ip"; then
    iptables -D INPUT -s "$admin_ip" -j ACCEPT 2>/dev/null || true
    iptables -I INPUT 1 -s "$admin_ip" -j ACCEPT
    echo "      [TOP-1] Admin IP $admin_ip guaranteed at iptables INPUT position 1."
  fi
}

# ==========================================================
# get_insert_position — Find correct position for vladblacklist DROP rule
# Must be AFTER admin whitelist (pos 1) and DNS/VPN bypass rules
# ==========================================================
get_insert_position() {
  local last_bypass_pos=1
  local pos=0
  while IFS= read -r line; do
    pos=$(echo "$line" | awk '{print $1}')
    if echo "$line" | grep -qE "(194\.228\.224\.76|dpt:(53|853|443|8443|8080|22|2222))"; then
      if [[ "$pos" =~ ^[0-9]+$ ]] && [ "$pos" -gt "$last_bypass_pos" ]; then
        last_bypass_pos=$pos
      fi
    fi
  done < <(iptables -L INPUT -n --line-numbers 2>/dev/null || true)

  echo $((last_bypass_pos + 1))
}

# ==========================================================
# check_protection_status — Universal defense health check
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
    ip_count=$(ipset list "$IPSET_NAME" 2>/dev/null | awk '/^Members:/{found=1;next} found && NF' | wc -l || echo 0)
    echo " [OK] ipset '$IPSET_NAME'     ACTIVE  — $ip_count IPs blocked"
    ((ok++)) || true
  else
    echo " [!!] ipset '$IPSET_NAME'     NOT LOADED — run this script to deploy"
    ((warn++)) || true
  fi

  # --- iptables rule ---
  if iptables -L INPUT -n 2>/dev/null | grep -q "$IPSET_NAME"; then
    echo " [OK] iptables DROP rule      ACTIVE  — blocking ipset '$IPSET_NAME'"
    ((ok++)) || true
  else
    echo " [!!] iptables DROP rule      MISSING — blacklist not enforced"
    ((warn++)) || true
  fi

  # --- fail2ban ---
  if systemctl is-active --quiet fail2ban 2>/dev/null; then
    local jails
    jails=$(fail2ban-client status 2>/dev/null | grep 'Jail list' | sed 's/.*Jail list:\s*//' | tr -d ' ' | tr ',' ' ' | wc -w || echo "?")
    echo " [OK] fail2ban                RUNNING — $jails jail(s) active"
    ((ok++)) || true
  elif command -v fail2ban-client &>/dev/null; then
    echo " [!!] fail2ban                INSTALLED but not running"
    ((warn++)) || true
  else
    echo " [--] fail2ban                NOT INSTALLED (optional)"
  fi

  # --- CrowdSec ---
  if systemctl is-active --quiet crowdsec 2>/dev/null; then
    local cs_bans
    cs_bans=$(cscli decisions list 2>/dev/null | grep -c 'ban' || echo "?")
    echo " [OK] CrowdSec                RUNNING — $cs_bans active ban(s)"
    ((ok++)) || true
  elif command -v cscli &>/dev/null; then
    echo " [!!] CrowdSec                INSTALLED but not running"
    ((warn++)) || true
  else
    echo " [--] CrowdSec                NOT INSTALLED (optional)"
  fi

  # --- Auto-update cron ---
  if crontab -l 2>/dev/null | grep -q 'deploy-blacklist'; then
    local cron_line
    cron_line=$(crontab -l 2>/dev/null | grep 'deploy-blacklist' | head -1)
    echo " [OK] Auto-update cron        SET     — $cron_line"
    ((ok++)) || true
  else
    echo " [!!] Auto-update cron        NOT SET — blacklist won't auto-refresh"
    ((warn++)) || true
  fi

  echo "------------------------------------------------"
  if [[ $warn -eq 0 ]]; then
    echo " RESULT: All protection systems OPERATIONAL"
  else
    echo " RESULT: $warn check(s) need attention, $ok OK"
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
echo "[2/4] Building ipset '$IPSET_NAME'..."
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

if ! ipset list "$IPSET_NAME" &>/dev/null; then
  ipset create "$IPSET_NAME" hash:net maxelem 65536
fi

# Atomic swap
ipset swap "$IPSET_TMP" "$IPSET_NAME"
ipset destroy "$IPSET_TMP" 2>/dev/null || true
echo "      Swapped '$IPSET_TMP' -> '$IPSET_NAME' atomically."

# Apply iptables rule — ensure admin whitelist first, then insert AFTER bypass rules
echo "[3/4] Applying iptables rule (guaranteeing admin whitelist & after DNS bypass)..."
ensure_admin_whitelist
iptables -D INPUT -m set --match-set "$IPSET_NAME" src -j DROP 2>/dev/null || true
INSERT_POS=$(get_insert_position)
iptables -I INPUT "$INSERT_POS" -m set --match-set "$IPSET_NAME" src -j DROP
echo "      iptables rule added at position $INSERT_POS: DROP all from $IPSET_NAME."

# Persist ipset only
echo "[4/4] Saving ipset for persistence..."
ipset save > /etc/ipset.rules 2>/dev/null || true
echo "      ipset saved to /etc/ipset.rules"

# Add @reboot restore to cron if not already there
if ! crontab -l 2>/dev/null | grep -q 'ipset restore'; then
  (crontab -l 2>/dev/null; echo "@reboot sleep 15 && ipset restore < /etc/ipset.rules 2>/dev/null; iptables-restore < /etc/iptables/rules.v4 2>/dev/null; ip6tables-restore < /etc/iptables/rules.v6 2>/dev/null") | crontab -
  echo "      @reboot restore added to crontab."
fi

# Log the deployment
echo "$DATETIME | $HOSTNAME | $ADDED IPs applied from vladblacklist" >> "$LOG_FILE" 2>/dev/null || true

echo ""
echo "================================================"
echo " Blacklist deployed successfully!"
echo " Server   : $HOSTNAME"
echo " IPs added: $ADDED"
echo " Rule pos : $INSERT_POS (after DNS bypass)"
echo " Log      : $LOG_FILE"
echo "================================================"
echo ""

# Run protection status check after every deploy
check_protection_status
