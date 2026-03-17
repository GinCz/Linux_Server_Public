#!/usr/bin/env bash
#
# Script: log_303.sh
# Version: v2026-03-17
# Purpose:
#   Start full interactive SSH session logging and save all terminal output
#   to a timestamped log file. This is useful for troubleshooting, sharing
#   server console history, keeping audit notes, and sending full session
#   output for review.
#
# What this script does:
#   - Creates a log directory if it does not exist.
#   - Starts a new terminal recording session using the Linux `script` tool.
#   - Saves the full screen output and command interaction into a log file.
#   - Stops only when the user exits the recorded subshell.
#
# Default log location:
#   /root/ssh_logs
#
# Output file format:
#   ssh_full_HOSTNAME_YYYY-MM-DD_HH-MM-SS.log
#
# Usage:
#   log_303.sh
#   log_303.sh /custom/log/path
#
# Related alias:
#   303='sudo /opt/server_tools/scripts/log_303.sh'
#
# Notes:
#   - Run `exit` to stop logging.
#   - Best used in SSH sessions for full text capture.
#   - The script records from the moment it starts, not past terminal history.
#

set -euo pipefail
LOG_DIR="${1:-/root/ssh_logs}"
mkdir -p "$LOG_DIR"
OUT="$LOG_DIR/ssh_full_$(hostname)_$(date +%Y-%m-%d_%H-%M-%S).log"
echo "303: logging started -> $OUT"
echo "303: type exit to stop"
exec script -q -f "$OUT"
