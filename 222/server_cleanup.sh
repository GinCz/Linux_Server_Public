#!/usr/bin/env bash
clear
source /root/scripts/common.sh
lock_or_exit server_cleanup
rm -f /root/*.0.0 /root/benchmark_results.txt 2>/dev/null || true
journalctl --vacuum-time=2d >/dev/null 2>&1 || true
apt-get clean >/dev/null 2>&1 || true
find /tmp -type f -atime +1 -delete 2>/dev/null || true
echo "Cleanup complete"
