#!/usr/bin/env bash
# Description: Scan logs for WP attacks & block bad IPs (Fight)
set -euo pipefail
LIMIT=800; LOGS="/var/www/*/data/logs/*access.log"; BANS="/root/scripts/state/fight_bans.txt"; mkdir -p /root/scripts/state
TG_TOKEN="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"; TG_CHAT_ID="261784949"; S_NAME="$(hostname)"
TRUSTED=("127.0.0.1" "8.8.8.8" "1.1.1.1" "xxx.xxx.xxx.109" "xxx.xxx.xxx.222" "5.101.114.114" "xxx.xxx.xxx.47" "xxx.xxx.xxx.237" "xxx.xxx.xxx.9" "xxx.xxx.xxx.227" "xxx.xxx.xxx.24" "xxx.xxx.xxx.178" "xxx.xxx.xxx.176" "xxx.xxx.xxx.38")
is_trusted(){ for t in "${TRUSTED[@]}"; do [[ "$1" == "$t" ]] && return 0; done; return 1; }
chain(){ iptables -S FIGHT_BOTS >/dev/null 2>&1 || { iptables -N FIGHT_BOTS; iptables -I INPUT 1 -j FIGHT_BOTS; }; }
ban(){ iptables -I FIGHT_BOTS -s "$1" -j DROP; echo "$(date '+%F %T') $1" >> "$BANS"; }
collect(){ awk '{ip=$1;l=$0;if(l~/ (GET|POST) .*xmlrpc\.php/ || l~/wp-login\.php/ || l~/wp-admin\//)c[ip]++} END{for(i in c)print c[i],i}' $LOGS 2>/dev/null | sort -nr; }
tg(){ curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" -d "chat_id=${TG_CHAT_ID}" -d "text=🛡️ FIGHT ($S_NAME): blocked $1 IP(s): $2" >/dev/null 2>&1 || true; }
main(){ chain; local out="$(collect)"; local bad="$(echo "$out" | awk -v l="$LIMIT" '$1>l{print $2}')"; local n=0; local list=""
for ip in $bad; do is_trusted "$ip" && continue; iptables -C FIGHT_BOTS -s "$ip" -j DROP >/dev/null 2>&1 && continue; ban "$ip"; n=$((n+1)); list="$list $ip"; done
[ $n -gt 0 ] && tg "$n" "$list"; echo "FIGHT complete. New: $n. Candidates: $(echo "$out" | wc -l)" ; }
main
