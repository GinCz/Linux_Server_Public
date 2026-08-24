#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  server_cleanup.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Universal system cleanup (Journal vacuum, /tmp, package cache, Docker prune)
# Servers     : All Linux Nodes (222-DE / 109-RU / VPN Nodes)
# Usage       : bash scripts/server_cleanup.sh [--reboot-friday]
# ==========================================================================================

GRN='\033[0;32m'; YEL='\033[1;33m'; CYN='\033[0;36m'; NC='\033[0m'

echo -e "${CYN}=== Server Cleanup: $(hostname) ===${NC}"

# 1. Vacuum systemd journal logs (>2 days)
journalctl --vacuum-time=2d >/dev/null 2>&1 && \
  echo -e "${GRN}✔ Journal logs vacuumed (>2d)${NC}"

# 2. Clean APT cache and orphaned packages
apt-get autoremove -y >/dev/null 2>&1
apt-get clean >/dev/null 2>&1 && \
  echo -e "${GRN}✔ APT package cache cleared${NC}"

# 3. Clean temporary files older than 1 day
find /tmp -type f -atime +1 -delete 2>/dev/null
rm -f /root/*.0.0 /root/benchmark_results.txt /tmp/disk_test_file.* 2>/dev/null && \
  echo -e "${GRN}✔ Temporary files in /tmp and /root cleaned${NC}"

# 4. Clean old Nginx compressed logs (>7 days)
find /var/log/nginx -name 'access.log.*' -mtime +7 -delete 2>/dev/null
find /var/log/nginx -name '*.gz' -mtime +7 -delete 2>/dev/null && \
  echo -e "${GRN}✔ Old compressed Nginx logs pruned (>7d)${NC}"

# 5. Clean Docker dangling objects if docker is present
if command -v docker >/dev/null 2>&1; then
    docker system prune -f --volumes >/dev/null 2>&1 || true
    echo -e "${GRN}✔ Docker dangling containers & cache pruned${NC}"
fi

echo -e "${CYN}=== Cleanup complete: $(date '+%Y-%m-%d %H:%M:%S') ===${NC}"

# 6. Friday night safe reboot handler (only on Friday/Saturday night)
if [[ "${1:-}" == "--reboot-friday" ]]; then
    DAY_OF_WEEK=$(date +%u) # 5 = Friday, 6 = Saturday
    if [ "$DAY_OF_WEEK" -eq 5 ] || [ "$DAY_OF_WEEK" -eq 6 ]; then
        echo -e "${YEL}Friday/Saturday maintenance reboot triggered in 10 seconds...${NC}"
        sleep 10
        /sbin/reboot
    fi
fi

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
