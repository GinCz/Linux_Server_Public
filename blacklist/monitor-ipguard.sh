#!/bin/bash
# ==========================================================
# monitor-ipguard.sh — Daily IPGuard/CrowdSec health check
# Runs on SERVER 222 ONLY — checks ALL nodes via SSH
# Checks: CrowdSec status, ipset vladblacklist, iptables DROP rule, cron jobs
# Sends silent Telegram report daily at 10:00
#
# IMPORTANT: This is a TEMPLATE — no credentials inside.
# Copy to /root/monitor-ipguard.sh on server 222 and fill in:
#   TG_TOKEN — your Telegram bot token
#   TG_CHAT  — your Telegram chat ID
# (credentials stored in Secret_Privat repo)
#
# Installation on server 222:
#   cp monitor-ipguard.sh /root/monitor-ipguard.sh
#   chmod +x /root/monitor-ipguard.sh
#   crontab -e
#   -> 0 10 * * * /root/monitor-ipguard.sh >> /var/log/monitor-ipguard.log 2>&1
#
# Cron schedule on server 222 (full picture):
#   0  */3 * * *  collect-from-vpn.sh   — collect from nodes -> push GitHub
#   30 */3 * * *  deploy-blacklist.sh   — pull GitHub -> apply ipset
#   0  10  * * *  monitor-ipguard.sh    — daily health check -> Telegram
#
# = Rooted by VladiMIR + AI | v.2026.07.04 | github.com/GinCz =
# ==========================================================

TG_TOKEN="YOUR_BOT_TOKEN_HERE"
TG_CHAT="YOUR_CHAT_ID_HERE"
DATETIME=$(date "+%d.%m.%Y %H:%M")
LOG="/var/log/monitor-ipguard.log"

tg() {
  curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
    -d chat_id="${TG_CHAT}" \
    -d parse_mode="HTML" \
    -d disable_notification="true" \
    --data-urlencode "text=$1" >> "$LOG" 2>&1
}
log() { echo "$(date '+%H:%M:%S') $*" >> "$LOG"; }

# ── ALL NODES TO CHECK ───────────────────────────────────────
declare -A NODES=(
  ["222-DE-NetCup"]="152.53.182.222"
  ["109-RU-FastVDS"]="212.109.223.109"
  ["IONOS-38"]="82.223.116.38"
  ["ALEX-47"]="109.234.38.47"
  ["4TON-237"]="144.124.228.237"
  ["TATRA-9"]="144.124.232.9"
  ["SHAHIN-227"]="144.124.228.227"
  ["STOLB-24"]="144.124.239.24"
  ["PILIK-33"]="195.63.138.33"
  ["ILYA-176"]="146.103.110.176"
  ["SO-38"]="144.124.233.38"
)

# Remote command — runs on each node via SSH (or locally on 222)
# Returns pipe-separated key:value string
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

  # Run locally on 222, via SSH on all other nodes
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
    REPORT_LINES="${REPORT_LINES}$(printf '\U274C') <b>${NODE}</b> <code>${IP}</code> - SSH unreachable\n"
    TOTAL_ISSUES=$((TOTAL_ISSUES+1))
    continue
  fi

  # Parse result
  CS=$(echo "$RESULT"    | grep -oP 'CS:\K[^|]+')
  BANS=$(echo "$RESULT"  | grep -oP 'BANS:\K[^|]+')
  IPSET=$(echo "$RESULT" | grep -oP 'IPSET:\K[^|]+')
  COUNT=$(echo "$RESULT" | grep -oP 'COUNT:\K[^|]+')
  IPT=$(echo "$RESULT"   | grep -oP 'IPTABLES:\K[^|]+')
  DCRON=$(echo "$RESULT" | grep -oP 'DEPLOY_CRON:\K[^|]+')
  CCRON=$(echo "$RESULT" | grep -oP 'COLLECT_CRON:\K[^|]+')

  NODE_ISSUES=0
  NODE_WARN=""
  [ "$CS"    != "active" ] && { NODE_WARN="${NODE_WARN}CrowdSec not running; "; NODE_ISSUES=$((NODE_ISSUES+1)); }
  [ "$IPSET" != "ok"     ] && { NODE_WARN="${NODE_WARN}ipset not loaded; ";     NODE_ISSUES=$((NODE_ISSUES+1)); }
  [ "$IPT"   != "ok"     ] && { NODE_WARN="${NODE_WARN}iptables DROP missing; "; NODE_ISSUES=$((NODE_ISSUES+1)); }
  [ "$DCRON" != "ok"     ] && { NODE_WARN="${NODE_WARN}deploy-cron missing; ";   NODE_ISSUES=$((NODE_ISSUES+1)); }

  # collect cron only required on master node 222
  [ "$IP" = "152.53.182.222" ] && [ "$CCRON" != "ok" ] && {
    NODE_WARN="${NODE_WARN}collect-cron missing; "
    NODE_ISSUES=$((NODE_ISSUES+1))
  }

  # Warn if blacklist is suspiciously small (fresh deploy or failed update)
  if [ "$IPSET" = "ok" ] && [ "${COUNT:-0}" -lt 100 ] 2>/dev/null; then
    NODE_WARN="${NODE_WARN}blacklist too small (${COUNT} IP); "
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
  REPORT_LINES="${REPORT_LINES}${ICON} <b>${NODE}</b> <code>${IP}</code>\n   ${STATUS}\n"
done

TOTAL_NODES=${#NODES[@]}
BL_COUNT=$(wc -l < /root/Linux_Server_Public/blacklist/blacklist.txt 2>/dev/null || echo "?")
BL_UPD=$(git -C /root/Linux_Server_Public log -1 --format="%ar" -- blacklist/blacklist.txt 2>/dev/null || echo "?")
FAILED=$((TOTAL_NODES - OK_COUNT))

if [ "$TOTAL_ISSUES" -eq 0 ]; then
  HEADER="$(printf '\U2705') <b>IPGuard OK — all ${TOTAL_NODES} servers protected</b>"
else
  HEADER="$(printf '\U1F6A8') <b>IPGuard PROBLEMS: ${TOTAL_ISSUES} errors on ${FAILED} nodes</b>"
fi

MSG="${HEADER}
$(printf '\U1F4C5') ${DATETIME}

${REPORT_LINES}
$(printf '\U1F4CA') GitHub blacklist: <b>${BL_COUNT}</b> IP | updated: <b>${BL_UPD}</b>
$(printf '\U2714') OK: ${OK_COUNT}/${TOTAL_NODES}"

tg "$MSG"
log "Telegram sent. OK:${OK_COUNT}/${TOTAL_NODES} Issues:${TOTAL_ISSUES}"
log "=== IPGuard Monitor END ==="
# = Rooted by VladiMIR + AI | v.2026.07.04 | github.com/GinCz =
