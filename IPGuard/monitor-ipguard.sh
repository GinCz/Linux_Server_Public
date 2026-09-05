#!/bin/bash
# = Rooted by VladiMIR + AI | v.2026.07.16 | github.com/GinCz =
# monitor-ipguard.sh - Daily IPGuard/CrowdSec health check
# Cron: 0 10 * * * /root/monitor-ipguard.sh
# Token loaded from /root/.server_env

[ -f /root/.server_env ] && source /root/.server_env
TG_TOKEN="${TG_TOKEN:-}"
TG_CHAT="261784949"
DATETIME=$(date "+%d.%m.%Y %H:%M")
LOG="/var/log/monitor-ipguard.log"

tg() {
# Send ONLY if there are issues
if [ "$ISSUE_COUNT" -gt 0 ]; then
      curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
        -d chat_id="${TG_CHAT}" \
        -d parse_mode="HTML" \
        -d disable_notification="true" \
        --data-urlencode "text=$1" >> "$LOG" 2>&1
fi

}
log() { echo "$(date '+%H:%M:%S') $*" >> "$LOG"; }

declare -A NODES=(
  ["222-DE-NetCup"]="152.53.182.222"
  ["109-RU-FastVDS"]="212.109.223.109"
  ["IONOS-38"]="82.223.116.38"
  ["ALEX-47"]="212.34.148.51"
  ["4TON-237"]="144.124.228.237"
  ["TATRA-9"]="144.124.232.9"
  ["SHAHIN-227"]="144.124.228.227"
  ["STOLB-24"]="144.124.239.24"
  ["PILIK-33"]="195.63.138.33"
  ["ILYA-176"]="146.103.110.176"
  ["SO-38"]="144.124.233.38"
)

REMOTE_CMD='
CS=$(systemctl is-active crowdsec 2>/dev/null || echo inactive)
BANS=0; IPSET_ST=no; CNT=0; IPT=no; DCRON=no; CCRON=no
[ "$CS" = "active" ] && BANS=$(cscli decisions list 2>/dev/null | grep -c ban || echo 0)
ipset list vladblacklist >/dev/null 2>&1 && IPSET_ST=ok && CNT=$(ipset list vladblacklist 2>/dev/null | awk "/^Members:/{f=1;next}f&&NF" | wc -l)
iptables -L INPUT -n 2>/dev/null | grep -q vladblacklist && IPT=ok
crontab -l 2>/dev/null | grep -q deploy-blacklist && DCRON=ok
crontab -l 2>/dev/null | grep -q collect-from-vpn && CCRON=ok
echo "CS:${CS}|BANS:${BANS}|IPSET:${IPSET_ST}|COUNT:${CNT}|IPTABLES:${IPT}|DEPLOY_CRON:${DCRON}|COLLECT_CRON:${CCRON}"
'

echo "" >> "$LOG"
log "=== IPGuard Monitor START ==="
TOTAL_ISSUES=0
OK_COUNT=0
REPORT_LINES=""

for NODE in $(echo "${!NODES[@]}" | tr " " "\n" | sort); do
  IP="${NODES[$NODE]}"

  if [ "$IP" = "152.53.182.222" ]; then
    RESULT=$(eval "$REMOTE_CMD" 2>/dev/null)
    SSH_OK=$?
  else
    RESULT=$(ssh -o ConnectTimeout=8 -o BatchMode=yes \
      -o StrictHostKeyChecking=no root@"$IP" "$REMOTE_CMD" 2>/dev/null)
    SSH_OK=$?
  fi

  if [ $SSH_OK -ne 0 ] || [ -z "$RESULT" ]; then
    log "FAIL: $NODE ($IP) SSH unreachable"
    REPORT_LINES="${REPORT_LINES}$(printf '\U274C') <b>${NODE}</b> <code>${IP}</code> - SSH \u043d\u0435\u0434\u043e\u0441\u0442\u0443\u043f\u0435\u043d\n"
    TOTAL_ISSUES=$((TOTAL_ISSUES+1))
    continue
  fi

  CS=$(echo "$RESULT"    | grep -oP 'CS:\K[^|]+')
  BANS=$(echo "$RESULT"  | grep -oP 'BANS:\K[^|]+')
  IPSET=$(echo "$RESULT" | grep -oP 'IPSET:\K[^|]+')
  COUNT=$(echo "$RESULT" | grep -oP 'COUNT:\K[^|]+')
  IPT=$(echo "$RESULT"   | grep -oP 'IPTABLES:\K[^|]+')
  DCRON=$(echo "$RESULT" | grep -oP 'DEPLOY_CRON:\K[^|]+')
  CCRON=$(echo "$RESULT" | grep -oP 'COLLECT_CRON:\K[^|]+')

  NODE_ISSUES=0
  NODE_WARN=""
  [ "$CS"    != "active" ] && { NODE_WARN="${NODE_WARN}CrowdSec \u043d\u0435 \u0440\u0430\u0431\u043e\u0442\u0430\u0435\u0442; "; NODE_ISSUES=$((NODE_ISSUES+1)); }
  [ "$IPSET" != "ok"     ] && { NODE_WARN="${NODE_WARN}ipset \u043d\u0435 \u0437\u0430\u0433\u0440\u0443\u0436\u0435\u043d; ";    NODE_ISSUES=$((NODE_ISSUES+1)); }
  [ "$IPT"   != "ok"     ] && { NODE_WARN="${NODE_WARN}iptables DROP missing; "; NODE_ISSUES=$((NODE_ISSUES+1)); }
  [ "$DCRON" != "ok"     ] && { NODE_WARN="${NODE_WARN}deploy-cron \u043d\u0435\u0442; ";      NODE_ISSUES=$((NODE_ISSUES+1)); }
  [ "$IP" = "152.53.182.222" ] && [ "$CCRON" != "ok" ] && {
    NODE_WARN="${NODE_WARN}collect-cron \u043d\u0435\u0442; "
    NODE_ISSUES=$((NODE_ISSUES+1))
  }
  if [ "$IPSET" = "ok" ] && [ "${COUNT:-0}" -lt 100 ] 2>/dev/null; then
    NODE_WARN="${NODE_WARN}blacklist \u043c\u0430\u043b (${COUNT} IP); "
    NODE_ISSUES=$((NODE_ISSUES+1))
  fi

  TOTAL_ISSUES=$((TOTAL_ISSUES+NODE_ISSUES))

  if [ "$NODE_ISSUES" -eq 0 ]; then
    OK_COUNT=$((OK_COUNT+1))
    ICON=$(printf '\U1F7E2')
    STATUS="bans: ${BANS} | ipset: ${COUNT} IP"
    log "OK:   $NODE ($IP) bans:${BANS} ipset:${COUNT}"
  else
    ICON=$(printf '\U274C')
    STATUS="${NODE_WARN}"
    log "WARN: $NODE ($IP) - $NODE_WARN"
  fi
  REPORT_LINES="${REPORT_LINES}${ICON} <b>${NODE}</b> <code>${IP}</code>
   ${STATUS}
"
done

TOTAL_NODES=${#NODES[@]}
BL_COUNT=$(wc -l < /root/Linux_Server_Public/blacklist/blacklist.txt 2>/dev/null || echo "?")
BL_UPD=$(git -C /root/Linux_Server_Public log -1 --format="%ar" -- blacklist/blacklist.txt 2>/dev/null || echo "?")
FAILED=$((TOTAL_NODES - OK_COUNT))

if [ "$TOTAL_ISSUES" -eq 0 ]; then
  HEADER="$(printf '\U2705') <b>IPGuard OK - \u0432\u0441\u0435 ${TOTAL_NODES} \u0441\u0435\u0440\u0432\u0435\u0440\u043e\u0432 \u0437\u0430\u0449\u0438\u0449\u0435\u043d\u044b</b>"
else
  HEADER="$(printf '\U1F6A8') <b>IPGuard PROBLEMS: ${TOTAL_ISSUES} \u043e\u0448\u0438\u0431\u043e\u043a \u043d\u0430 ${FAILED} \u0443\u0437\u043b\u0430\u0445</b>"
fi

MSG="${HEADER}
$(printf '\U1F4C5') ${DATETIME}

${REPORT_LINES}
$(printf '\U1F4CA') GitHub blacklist: <b>${BL_COUNT}</b> IP | \u043e\u0431\u043d\u043e\u0432\u043b\u0451\u043d: <b>${BL_UPD}</b>
$(printf '\U2714') OK: ${OK_COUNT}/${TOTAL_NODES}"

if [ "$TOTAL_ISSUES" -gt 0 ]; then
  tg "$MSG"
  log "Telegram sent. OK:${OK_COUNT}/${TOTAL_NODES} Issues:${TOTAL_ISSUES}"
else
  log "All OK \u2014 Telegram silent (no issues)"
fi
log "=== IPGuard Monitor END ==="
# = Rooted by VladiMIR + AI | v.2026.07.16 | github.com/GinCz =
