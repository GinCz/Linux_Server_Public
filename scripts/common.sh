#!/usr/bin/env bash
# Shared Logic for 109 & 222 servers
# Author: Ing. VladiMIR Bulantsev | 2026
source /root/.server_alliances.conf 2>/dev/null || true

is_interactive(){ [ -t 1 ] || [ -n "${SSH_TTY:-}" ]; }
lock_or_exit(){ mkdir -p /var/lock; exec 9>"/var/lock/$1.lock"; flock -n 9 || exit 0; }

# Automatically detect if we are on 222 or 109
detect_node(){ 
    IP="$(hostname -I | awk '{print $1}')"
    [[ "$IP" == "xxx.xxx.xxx.222" ]] && echo "222" || echo "109"
}
