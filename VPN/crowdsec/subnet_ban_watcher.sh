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
# Install:
#   cp subnet_ban_watcher.sh /usr/local/bin/subnet_ban_watcher.sh
#   chmod +x /usr/local/bin/subnet_ban_watcher.sh
#
# Cron (every 5 min):
#   echo '*/5 * * * * root /usr/local/bin/subnet_ban_watcher.sh >> /var/log/subnet_ban_watcher.log 2>&1' \
#     > /etc/cron.d/subnet-ban-watcher
# =============================================================================

clear

# --- Config
THRESHOLD=3          # how many IPs from same /24 before banning subnet
BAN_DURATION="720h"  # 30 days
LOG_TAG="[subnet-ban]"

# --- Get all currently banned IPs from CrowdSec
BANNED_IPS=$(cscli decisions list -o raw 2>/dev/null \
  | awk -F',' 'NR>1 && $3=="ban" {print $2}' \
  | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}')

if [ -z "$BANNED_IPS" ]; then
  echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_TAG No banned IPs found, exiting."
  exit 0
fi

# --- Count IPs per /24 subnet
declare -A SUBNET_COUNT

while IFS= read -r ip; do
  # Extract /24 prefix: 1.2.3.4 -> 1.2.3
  subnet=$(echo "$ip" | cut -d. -f1-3)
  SUBNET_COUNT[$subnet]=$(( ${SUBNET_COUNT[$subnet]:-0} + 1 ))
done <<< "$BANNED_IPS"

# --- Check each subnet against threshold
for subnet in "${!SUBNET_COUNT[@]}"; do
  count=${SUBNET_COUNT[$subnet]}
  if [ "$count" -ge "$THRESHOLD" ]; then
    range="${subnet}.0/24"

    # Skip if already banned
    already=$(cscli decisions list -o raw 2>/dev/null \
      | awk -F',' -v r="$range" '$2==r {print $2}' | head -1)

    if [ -n "$already" ]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_TAG $range already banned, skipping."
      continue
    fi

    # Ban the entire /24
    cscli decisions add \
      --range "$range" \
      --reason "subnet-ban: ${count} IPs from same /24 attacked" \
      --duration "$BAN_DURATION" \
      --type ban 2>/dev/null

    echo "$(date '+%Y-%m-%d %H:%M:%S') $LOG_TAG BANNED subnet $range ($count IPs found, duration $BAN_DURATION)"
  fi
done

# = Rooted by VladiMIR | AI = v2026-04-10
