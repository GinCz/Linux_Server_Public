#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  deploy-blacklist.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Phase 3: Global deployment (pull GitHub blacklist, apply ipset DROP rules)
# Servers     : All Linux Nodes (222-DE / 109-RU / VPN Nodes)
# Usage       : Cron -> 30 */3 * * * bash deploy-blacklist.sh
# ==========================================================================================

set -euo pipefail

BLACKLIST_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt"
IPSET_NAME="vladblacklist"
IPSET_TMP="vladblacklist_tmp"
LOG_FILE="/var/log/vladblacklist.log"
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
HOSTNAME=$(hostname)

# ==========================================================
# get_insert_position — Find correct position for vladblacklist DROP rule
# Must be AFTER all DNS/VPN bypass rules (port 53, 853, 443, 8443)
# DNS bypass rules must always be first — before any blacklist/CrowdSec
# ==========================================================
get_insert_position() {
  local last_bypass_pos=0
  local pos
  # Find the last bypass rule position (53, 853, 443, 8443, 8080)
  while IFS= read -r line; do
    pos=$(echo "$line" | awk '{print $1}')
    if echo "$line" | grep -qE "dpt:(53|853|443|8443|8080)"; then
      if [[ "$pos" =~ ^[0-9]+$ ]] && [ "$pos" -gt "$last_bypass_pos" ]; then
        last_bypass_pos=$pos
      fi
    fi
  done < <(iptables -L INPUT -n --line-numbers 2>/dev/null)

  # Insert AFTER last bypass rule
  echo $((last_bypass_pos + 1))
}

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
    echo " [OK] ipset '$IPSET_NAME'     ACTIVE  — $ip_count IPs blocked"
    ((ok++)) || true
  elif command -v ipset &>/dev/null && ipset list "$IPSET_NAME" 2>/dev/null | grep -q 'Name:'; then
    echo " [OK] ipset '$IPSET_NAME'     ACTIVE"
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

  # --- DNS bypass check ---
  local dns_pos cs_pos vlad_pos
  dns_pos=$(iptables -L INPUT -n --line-numbers 2>/dev/null | grep "dpt:53" | head -1 | awk '{print $1}')
  vlad_pos=$(iptables -L INPUT -n --line-numbers 2>/dev/null | grep "$IPSET_NAME" | head -1 | awk '{print $1}')
  if [ -n "$dns_pos" ] && [ -n "$vlad_pos" ] && [ "$dns_pos" -lt "$vlad_pos" ]; then
    echo " [OK] DNS bypass pos $dns_pos is BEFORE vladblacklist pos $vlad_pos — DNS open to world!"
    ((ok++)) || true
  elif [ -n "$dns_pos" ] && [ -n "$vlad_pos" ]; then
    echo " [!!] WARNING: DNS bypass pos $dns_pos is AFTER vladblacklist pos $vlad_pos — DNS may be blocked!"
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

  # --- UFW ---
  if systemctl is-active --quiet ufw 2>/dev/null || ufw status 2>/dev/null | grep -q 'Status: active'; then
    echo " [OK] UFW firewall             ACTIVE"
    ((ok++)) || true
  elif systemctl is-active --quiet firewalld 2>/dev/null; then
    echo " [OK] firewalld                ACTIVE"
    ((ok++)) || true
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
ipset destroy "$IPSET_TMP"
echo "      Swapped '$IPSET_TMP' -> '$IPSET_NAME' atomically."

# Apply iptables rule — insert AFTER DNS/VPN bypass rules, NOT at position 1!
# DNS ports 53/853/443/8443 must ALWAYS be before any DROP rules.
echo "[3/4] Applying iptables rule (after DNS bypass)..."
iptables -D INPUT -m set --match-set "$IPSET_NAME" src -j DROP 2>/dev/null || true
INSERT_POS=$(get_insert_position)
iptables -I INPUT "$INSERT_POS" -m set --match-set "$IPSET_NAME" src -j DROP
echo "      iptables rule added at position $INSERT_POS: DROP all from $IPSET_NAME."

# Verify DNS bypass is still before vladblacklist
DNS_POS=$(iptables -L INPUT -n --line-numbers 2>/dev/null | grep "dpt:53" | head -1 | awk '{print $1}')
VLAD_POS=$(iptables -L INPUT -n --line-numbers 2>/dev/null | grep "$IPSET_NAME" | head -1 | awk '{print $1}')
if [ -n "$DNS_POS" ] && [ -n "$VLAD_POS" ] && [ "$DNS_POS" -lt "$VLAD_POS" ]; then
  echo "      DNS bypass pos $DNS_POS is BEFORE vladblacklist pos $VLAD_POS -- OK!"
else
  echo "      WARNING: DNS pos=$DNS_POS vladblacklist pos=$VLAD_POS -- check manually!"
fi

# Persist ipset only (NOT iptables rules — netfilter-persistent handles that with clean rules)
echo "[4/4] Saving ipset for persistence..."
ipset save > /etc/ipset.rules 2>/dev/null || true
echo "      ipset saved to /etc/ipset.rules"
# NOTE: We do NOT save iptables rules here.
# rules.v4 must stay clean (only bypass rules, no ipset/UFW/CrowdSec chains).
# See /etc/iptables/rules.v4 — managed manually, not by this script.

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
echo "To verify:"
echo "  ipset list $IPSET_NAME | head -20"
echo "  iptables -L INPUT -n --line-numbers | head -15"
echo ""

# Run protection status check after every deploy
check_protection_status
