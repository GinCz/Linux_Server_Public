#!/usr/bin/env bash
# Description: Interactively change server hostname and update hosts/netdata.
# Alias: chname
read -p "New hostname: " N; hostnamectl set-hostname "$N"; sed -i "s/127.0.1.1.*/127.0.1.1 $N/" /etc/hosts; [ -d /etc/netdata ] && { echo -e "[global]\n    hostname = $N" | tee /etc/netdata/netdata.conf >/dev/null; systemctl restart netdata 2>/dev/null; }; echo "Done: $N"; exec bash
