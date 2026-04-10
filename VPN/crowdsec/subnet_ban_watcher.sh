#!/bin/bash
# =============================================================================
# subnet_ban_watcher.sh — Auto-ban /24 subnet if 3+ IPs attack from same range
# Version: v2026-04-10
# Author:  = Rooted by VladiMIR | AI =
# Description:
#   CrowdSec bans individual IPs but cannot auto-ban a /24 subnet.
#   This script checks every 5 minutes: if 3 or more IPs from the same /24
#   are already banned, it bans the entire /24 subnet for 720h (30 days).
#
#   NOTE: cscli decisions list -o raw outputs IP as "Ip:1.2.3.4"
#   This script correctly strips the "Ip:" prefix before processing.
#
# Install:
#   cp subnet_ban_watcher.sh /usr/local/bin/subnet_ban_watcher.sh
#   chmod +x /usr/local/bin/subnet_ban_watcher.sh
#
# Cron (every 5 min):
#   echo '*/5 * * * * root /usr/local/bin/subnet_ban_watcher.sh >> /var/log/subnet_ban_watcher.log 2>&1' \
#     > /etc/cron.d/subnet-ban-watcher
# =============================================================================

# --- Config
THRESHOLD=3          # how many IPs from same /24 before banning subnet
BAN_DURATION="720h"  # 30 days
LOG_TAG="[subnet-ban]"

# --- Get all currently banned IPs from CrowdSec
# Raw format column 3 = "Ip:1.2.3.4" or "Range:1.2.3.0/24"
# We only want individual IPs (Ip: prefix), strip the prefix
BANNED_IPS=$(cscli decisions list -o raw 2>/dev/null \
  | awk -F',' 'NR>1 && $5=="ban" && $3~/^Ip:/ {
      ip=$3
      sub(/^Ip:/, "", ip)
      print ip
    }')

if [ -z "$BANNED_IPS" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_TAG No banned IPs found, exiting."
  exit 0
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_TAG Found banned IPs: $(echo "$BANNED_IPS" | wc -l)"

# --- Count IPs per /24 subnet
declare -A SUBNET_COUNT

while IFS= read -r ip; do
  # Extract /24 prefix: 1.2.3.4 -> 1.2.3
  subnet=$(echo "$ip" | cut -d. -f1-3)
  SUBNET_COUNT[$subnet]=$(( ${SUBNET_COUNT[$subnet]:-0} + 1 ))
done <<< "$BANNED_IPS"

# --- Check each subnet against threshold
BANNED_ANY=0
for subnet in "${!SUBNET_COUNT[@]}"; do
  count=${SUBNET_COUNT[$subnet]}
  echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_TAG Subnet ${subnet}.0/24 has $count banned IPs"

  if [ "$count" -ge "$THRESHOLD" ]; then
    range="${subnet}.0/24"

    # Skip if already banned as a range
    already=$(cscli decisions list -o raw 2>/dev/null \
      | awk -F',' -v r="Range:${range}" '$3==r {print $3}' | head -1)

    if [ -n "$already" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_TAG $range already banned as range, skipping."
      continue
    fi

    # Ban the entire /24
    cscli decisions add \
      --range "$range" \
      --reason "subnet-ban: ${count} IPs from same /24 attacked" \
      --duration "$BAN_DURATION" \
      --type ban 2>&1

    echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_TAG *** BANNED subnet $range ($count IPs, duration $BAN_DURATION) ***"
    BANNED_ANY=1
  fi
done

if [ "$BANNED_ANY" -eq 0 ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_TAG No subnets exceeded threshold of $THRESHOLD IPs. Nothing to ban."
fi

# = Rooted by VladiMIR | AI = v2026-04-10
