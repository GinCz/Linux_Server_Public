#!/usr/bin/env bash
# Script:  motd.sh
# Version: v2026-03-23
# Purpose: SSH login banner — compact, 80 chars wide, no benchmarks

C='\033[1;36m'; Y='\033[1;33m'; G='\033[1;32m'; X='\033[0m'
LINE="${C}────────────────────────────────────────────────────────────────────────────────${X}"

HOST=$(hostname)
IP=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1)
MEM_FREE=$(awk '/MemAvailable/{printf "%.0f", $2/1024}' /proc/meminfo)
MEM_TOTAL=$(awk '/MemTotal/{printf "%.0f", $2/1024}' /proc/meminfo)
CPU=$(awk '{u=$2+$4; t=$2+$4+$5; if(NR==1){u1=u;t1=t} else printf "%.0f", (u-u1)*100/(t-t1)}' \
    <(grep '^cpu ' /proc/stat) <(sleep 0.2; grep '^cpu ' /proc/stat))

r() { printf "  ${G}%-26s${X}${G}%-26s${X}${G}%-26s${X}\n" "$1" "$2" "$3"; }

echo -e "$LINE"
printf "${C}  🖥  %-22s${X}${G}%-22s${X}${Y}RAM:${MEM_FREE}/${MEM_TOTAL}MB  CPU:${CPU}%%${X}\n" "$HOST" "$IP"
echo -e "$LINE"
printf "  ${Y}%-26s%-26s%-26s${X}\n" "SCAN & SECURITY" "SERVER" "WORDPRESS"
echo -e "$LINE"
r "antivir(scan)"         "sos(now)"           "wphealth(WP health)"
r "antivir-status(stat)"  "sos1/3/24(1/3/24h)" "wpcron(WP cron)"
r "antivir-stop(stop)"    "audit(security)"    "mailclean(mail queue)"
r "fight(block bots)"     "bans(ban list)"     "domains(domains)"
r "303(303 logs)"         "backup(backup)"     "cleanup(disk clean)"
echo -e "$LINE"
r "savesss(sync 109→222)" "save(git push)"     "load(git pull)"
r "infooo(full info)"     "00(clear)"          ""
echo -e "$LINE"
