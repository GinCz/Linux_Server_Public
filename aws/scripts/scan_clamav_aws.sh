#!/usr/bin/env bash
# Script:  scan_clamav_aws.sh
# Version: v2026-03-19
# Purpose: ClamAV antivirus scan adapted for AWS Ubuntu (user: ubuntu, sudo access).
#          Fixes issues with freshclam not in PATH and polkit auth failures.
# Usage:   bash /opt/server_tools/scripts/aws/scan_clamav_aws.sh

clear
echo "====================================================="
echo " CLAMAV SCAN - AWS v2026-03-19"
echo "====================================================="
echo ""

# Check if ClamAV installed
if ! command -v clamscan &>/dev/null; then
    echo "[!] ClamAV not installed. Installing..."
    sudo apt-get update -qq
    sudo apt-get install -y clamav clamav-daemon
fi

# 1. Update virus definitions
echo "[1/3] Updating virus database..."
sudo systemctl stop clamav-freshclam 2>/dev/null || true
sudo /usr/bin/freshclam --quiet 2>/dev/null || echo "      Warning: freshclam update skipped (will use existing DB)"
sudo systemctl start clamav-freshclam 2>/dev/null || true
echo "      OK"

# 2. Set scan target
SCAN_DIR="/home/ubuntu"
LOG_FILE="/tmp/clamav_scan_$(date +%Y%m%d_%H%M%S).log"

echo "[2/3] Scanning: $SCAN_DIR"
echo "      Log: $LOG_FILE"

# 3. Run scan
clamscan -r --bell \
    --exclude-dir="^/proc" \
    --exclude-dir="^/sys" \
    --exclude-dir="^/dev" \
    "$SCAN_DIR" \
    > "$LOG_FILE" 2>&1

EXIT_CODE=$?

echo ""
echo "====================================================="
echo " SCAN RESULTS"
echo "====================================================="

# Parse results
INFECTED=$(grep "Infected files:" "$LOG_FILE" | awk '{print $3}')
SCANNED=$(grep "Scanned files:" "$LOG_FILE" | awk '{print $3}')

echo "  Scanned : $SCANNED files"
echo "  Infected: $INFECTED files"
echo ""

if [ "$INFECTED" = "0" ] || [ -z "$INFECTED" ]; then
    echo "  ✅ No viruses found!"
else
    echo "  ❌ VIRUSES FOUND! Check log:"
    grep "FOUND" "$LOG_FILE"
fi

echo ""
echo "  Full log: $LOG_FILE"
echo "====================================================="
