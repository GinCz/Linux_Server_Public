#!/usr/bin/env bash
# Script:  change_hostname.sh
# Version: v2026-03-17
# Purpose: Interactively change server hostname and update /etc/hosts and Netdata.
# Usage:   /opt/server_tools/scripts/change_hostname.sh
# Alias:   chname

clear
read -p "New hostname: " N

hostnamectl set-hostname "$N"
sed -i "s/127.0.1.1.*/127.0.1.1 $N/" /etc/hosts

if [ -d /etc/netdata ]; then
    echo -e "[global]\n    hostname = $N" | tee /etc/netdata/netdata.conf >/dev/null
    systemctl restart netdata 2>/dev/null || true
fi

echo "Done: $N"
exec bash
