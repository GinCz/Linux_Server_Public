#!/usr/bin/env bash
clear
source /root/.server_alliances.conf 2>/dev/null || true
LIMIT=800
LOG_GLOB="/var/www/*/data/logs/*access.log"
BAN_DB="/root/scripts/state/fight_bans.txt"
SSH_IP="$(echo "${SSH_CLIENT:-}" | awk '{print $1}')"
TRUSTED_IPS=("127.0.0.1" "8.8.8.8" "$REMOTE_IP" "xxx.xxx.xxx.222" "xxx.xxx.xxx.109" "109.172.90.168" "xxx.xxx.xxx.47" "xxx.xxx.xxx.176" "xxx.xxx.xxx.178")
touch "$BAN_DB"
trusted(){ local ip="$1"; [[ -z "$ip" || "$ip" == "$SSH_IP" ]] && return 0; for t in "${TRUSTED_IPS[@]}"; do [[ "$ip" == "$t" ]] && return 0; done; return 1; }
chain(){ iptables -S FIGHT_BOTS >/dev/null 2>&1 || iptables -N FIGHT_BOTS; iptables -C INPUT -j FIGHT_BOTS >/dev/null 2>&1 || iptables -I INPUT 1 -j FIGHT_BOTS; }
has(){ iptables -C FIGHT_BOTS -s "$1" -j DROP >/dev/null 2>&1; }
ban(){ iptables -I FIGHT_BOTS -s "$1" -j DROP; echo "$(date -u '+%F %T') $1" >>"$BAN_DB"; }
collect(){ awk '{ip=$1;l=$0;if(l~/ (GET|POST) (\/\/)?\/(xmlrpc|wp-login)\.php/ || l~/ (GET|POST) (\/\/)?\/wp-admin\//)c[ip]++} END{for(i in c)print c[i],i}' $LOG_GLOB 2>/dev/null | sort -nr; }
main(){
  chain
  local out bad n=0 list=""
  out="$(collect || true)"
  bad="$(echo "$out" | awk -v limit="$LIMIT" '$1>limit{print $2}')"
  for ip in $bad; do
    trusted "$ip" && continue
    has "$ip" && continue
    ban "$ip"
    n=$((n+1))
    list="${list} ${ip}"
  done
  if [ "$n" -gt 0 ] && [ -n "${TG_TOKEN:-}" ]; then
    curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
      -d "chat_id=${TG_CHAT_ID}" \
      -d "text=FIGHT ($SERVER_TAG): blocked ${n} IP(s):${list}" \
      -d "disable_notification=true" >/dev/null 2>&1 || true
  fi
  echo "FIGHT sync done. New bans: $n"
}
main
