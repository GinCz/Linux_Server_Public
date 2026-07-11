#!/bin/bash
clear
# = Rooted by VladiMIR + AI | v.2026.07.11 | github.com/GinCz =
# Setup swap and journald limits on the server
# Idempotent: safe to run multiple times

set -e

BTMP=/var/log/btmp
BTMP_SIZE=$(du -m "$BTMP" 2>/dev/null | cut -f1 || echo 0)

# 1. Journald limit: 100MB / 7 days
if ! grep -q '^SystemMaxUse=100M' /etc/systemd/journald.conf 2>/dev/null; then
  sed -i '/^#\?SystemMaxUse/d; /^#\?MaxRetentionSec/d' /etc/systemd/journald.conf
  printf '\nSystemMaxUse=100M\nMaxRetentionSec=7day\n' >> /etc/systemd/journald.conf
  systemctl restart systemd-journald
  echo "[OK] journald limited to 100MB"
else
  echo "[SKIP] journald already configured"
fi

# Clear btmp if it's too large
if [ "$BTMP_SIZE" -gt 10 ]; then
  > "$BTMP"
  echo "[OK] btmp cleared (was ${BTMP_SIZE}MB)"
fi

# 2. Swap — only if not already present
if swapon --show | grep -q '.'; then
  echo "[SKIP] Swap already configured: $(swapon --show | grep -v NAME)"
else
  fallocate -l 512M /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  grep -q '/swapfile' /etc/fstab || echo '/swapfile none swap sw 0 0' >> /etc/fstab
  sysctl vm.swappiness=10
  grep -q 'vm.swappiness' /etc/sysctl.conf || echo 'vm.swappiness=10' >> /etc/sysctl.conf
  echo "[OK] Swap 512MB created and activated"
fi

# Status
echo ""
echo "=== System status ==="
echo "Swap:"
swapon --show
echo ""
echo "Journald:"
grep -E '^(SystemMaxUse|MaxRetentionSec)' /etc/systemd/journald.conf
echo ""
echo "Memory:"
free -h
echo ""
echo "DONE on this server"
