#!/bin/bash
# =============================================================================
# server_cleanup.sh — Clean old logs, tmp files, apt cache on 222-DE-NetCup
# Version     : v2026-04-30
# Server      : 222-DE-NetCup (152.53.182.222)
# Usage       : cleanup  (alias) or bash /root/Linux_Server_Public/222/server_cleanup.sh
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

GRN='\033[0;32m'; YEL='\033[1;33m'; CYN='\033[0;36m'; NC='\033[0m'

echo -e "${CYN}=== Server Cleanup: 222-DE-NetCup ===${NC}"

rm -f /root/*.0.0 /root/benchmark_results.txt 2>/dev/null && \
  echo -e "${GRN}OK: Root temp files removed${NC}"

journalctl --vacuum-time=2d >/dev/null 2>&1 && \
  echo -e "${GRN}OK: Journal logs vacuumed (>2d)${NC}"

apt-get clean >/dev/null 2>&1 && \
  echo -e "${GRN}OK: APT cache cleared${NC}"

find /tmp -type f -atime +1 -delete 2>/dev/null && \
  echo -e "${GRN}OK: /tmp cleaned (files >1d)${NC}"

find /var/log/nginx -name 'access.log.*' -mtime +7 -delete 2>/dev/null && \
  echo -e "${GRN}OK: Old Nginx access logs removed (>7d)${NC}"

echo -e "${CYN}=== Cleanup complete ===${NC}"
