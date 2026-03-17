#!/usr/bin/env bash
# v2026-03-17
# Start full SSH session logging to file
set -euo pipefail; LOG_DIR="${1:-/root/ssh_logs}"; mkdir -p "$LOG_DIR"; OUT="$LOG_DIR/ssh_full_$(hostname)_$(date +%Y-%m-%d_%H-%M-%S).log"; echo "303: logging started -> $OUT"; echo "303: type exit to stop"; exec script -q -f "$OUT"
