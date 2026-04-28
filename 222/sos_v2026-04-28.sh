#!/usr/bin/env bash
# = Rooted by VladiMIR | AI =
# sos — Server Overall Status
# Version: v2026-04-28
# Install: cp sos_v2026-04-28.sh /usr/local/bin/sos && chmod +x /usr/local/bin/sos
# Usage:
#   sos          — last 1h (default)
#   sos 1h       — last 1 hour
#   sos 3h       — last 3 hours
#   sos 24h      — last 24 hours
#   sos 120h     — last 5 days

clear

TW="${1:-1h}"

# ── COLORS ───────────────────────────────────────
RED='\033[1;31m'
GRN='\033[1;32m'
YLW='\033[1;33m'
MAG='\033[1;35m'
CYN='\033[1;36m'
WHT='\033[1;37m'
ORG='\033[38;5;214m'
LBL='\033[38;5;117m'
GRY='\033[0;37m'
DIM='\033[2m'
X='\033[0m'
BG_RED='\033[41m'
BG_GRN='\033[42m'

# ── HEADER ───────────────────────────────────────
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"
echo -e "${WHT}   ⚡  SOS — Server Status  │  ${GRN}222-DE-NetCup${WHT}  │  ${YLW}152.53.182.222${WHT}  │  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"
echo -e "${DIM}   Time window: ${WHT}${TW}${X}"
echo ""

# ── UPTIME / LOAD ─────────────────────────────────
echo -e "${YLW} ► SYSTEM${X}"
UPTIME=$(uptime -p 2>/dev/null || uptime)
LOAD=$(cat /proc/loadavg | awk '{print $1" "$2" "$3}')
MEM_TOTAL=$(free -m | awk '/^Mem/{print $2}')
MEM_USED=$(free -m  | awk '/^Mem/{print $3}')
MEM_PCT=$(awk "BEGIN{printf \"%.0f\", ${MEM_USED}/${MEM_TOTAL}*100}")
DISK_PCT=$(df / | awk 'NR==2{print $5}')
echo -e "   Uptime:  ${GRN}${UPTIME}${X}"
echo -e "   Load:    ${WHT}${LOAD}${X}"
echo -e "   RAM:     ${WHT}${MEM_USED}M / ${MEM_TOTAL}M${X}  ${DIM}(${MEM_PCT}%)${X}"
echo -e "   Disk /:  ${WHT}${DISK_PCT}${X} used"
echo ""

# ── SERVICES ──────────────────────────────────────
echo -e "${YLW} ► SERVICES${X}"
for SVC in nginx php8.3-fpm mysql crowdsec docker; do
    STATUS=$(systemctl is-active "$SVC" 2>/dev/null)
    if [ "$STATUS" = "active" ]; then
        echo -e "   ${GRN}● ${SVC}${X}   ${DIM}active${X}"
    else
        echo -e "   ${RED}✗ ${SVC}${X}   ${RED}${STATUS}${X}"
    fi
done
echo ""

# ── NGINX ERRORS (last TW) ────────────────────────
echo -e "${YLW} ► NGINX ERRORS  ${DIM}(last ${TW})${X}"
SINCE=$(date -d "-${TW}" '+%Y/%m/%d %H:%M:%S' 2>/dev/null || date -v-${TW} '+%Y/%m/%d %H:%M:%S' 2>/dev/null)
ERR_LOG="/var/log/nginx/error.log"
if [ -f "$ERR_LOG" ]; then
    ERR_COUNT=$(awk -v since="$SINCE" '$0 >= since' "$ERR_LOG" 2>/dev/null | grep -c '\[error\]' || echo 0)
    WARN_COUNT=$(awk -v since="$SINCE" '$0 >= since' "$ERR_LOG" 2>/dev/null | grep -c '\[warn\]' || echo 0)
    echo -e "   Errors:   ${RED}${ERR_COUNT}${X}"
    echo -e "   Warnings: ${YLW}${WARN_COUNT}${X}"
    if [ "$ERR_COUNT" -gt 0 ] 2>/dev/null; then
        echo -e "${DIM}   ── last 5 errors:${X}"
        grep '\[error\]' "$ERR_LOG" | tail -5 | while IFS= read -r line; do
            echo -e "   ${RED}${line}${X}"
        done
    fi
else
    echo -e "   ${GRY}log not found: ${ERR_LOG}${X}"
fi
echo ""

# ── NGINX ACCESS: HTTP 4xx/5xx (last TW) ──────────
echo -e "${YLW} ► NGINX HTTP STATUS  ${DIM}(last ${TW})${X}"
ACCESS_LOG="/var/log/nginx/access.log"
if [ -f "$ACCESS_LOG" ]; then
    python3 -c "
import sys, re
from datetime import datetime, timedelta

tw = '${TW}'
unit = tw[-1]
val  = int(tw[:-1])
if unit == 'h':
    delta = timedelta(hours=val)
elif unit == 'd':
    delta = timedelta(days=val)
else:
    delta = timedelta(hours=val)

since = datetime.now() - delta
counts = {}
pattern = re.compile(r'\"(?:GET|POST|PUT|DELETE|HEAD|OPTIONS)[^\"]*\" (\d{3})')
ts_pat  = re.compile(r'\[(\d{2}/\w+/\d{4}:\d{2}:\d{2}:\d{2})')
months  = {'Jan':1,'Feb':2,'Mar':3,'Apr':4,'May':5,'Jun':6,
           'Jul':7,'Aug':8,'Sep':9,'Oct':10,'Nov':11,'Dec':12}

with open('${ACCESS_LOG}', errors='ignore') as f:
    for line in f:
        m_ts = ts_pat.search(line)
        if not m_ts:
            continue
        try:
            ts_str = m_ts.group(1)
            parts = ts_str.split(':')
            d, mo, y = parts[0].split('/')
            h, mi, s = parts[1], parts[2], parts[3]
            dt = datetime(int(y), months[mo], int(d), int(h), int(mi), int(s))
        except:
            continue
        if dt < since:
            continue
        m = pattern.search(line)
        if m:
            code = m.group(1)
            counts[code] = counts.get(code, 0) + 1

if not counts:
    print('   no data in window')
    sys.exit()

RED='\033[1;31m'; YLW='\033[1;33m'; GRN='\033[1;32m'; GRY='\033[0;37m'; X='\033[0m'
for code in sorted(counts):
    cnt = counts[code]
    c = GRN if code.startswith('2') else YLW if code.startswith('3') else RED if code.startswith(('4','5')) else GRY
    print(f'   {c}HTTP {code}{X}  {cnt}')
" 2>/dev/null || echo "   (python3 required)"
else
    echo -e "   ${GRY}log not found: ${ACCESS_LOG}${X}"
fi
echo ""

# ── CROWDSEC BANS ─────────────────────────────────
echo -e "${YLW} ► CROWDSEC  ${DIM}(active bans)${X}"
CS_STATUS=$(systemctl is-active crowdsec 2>/dev/null)
if [ "$CS_STATUS" = "active" ]; then
    BAN_COUNT=$(cscli decisions list -o json 2>/dev/null | python3 -c \
        "import sys,json;d=json.load(sys.stdin);print(len(d) if d else 0)" 2>/dev/null || echo 0)
    echo -e "   Active bans: ${RED}${BAN_COUNT}${X}"
else
    echo -e "   ${GRY}CrowdSec not running${X}"
fi
echo ""

# ── DOCKER ────────────────────────────────────────
echo -e "${YLW} ► DOCKER CONTAINERS${X}"
if command -v docker &>/dev/null; then
    docker ps --format "   {{.Names}}\t{{.Status}}" 2>/dev/null | while IFS=$'\t' read -r name status; do
        if echo "$status" | grep -q "^Up"; then
            echo -e "   ${GRN}●${X} ${WHT}${name}${X}  ${DIM}${status}${X}"
        else
            echo -e "   ${RED}✗${X} ${WHT}${name}${X}  ${RED}${status}${X}"
        fi
    done
else
    echo -e "   ${GRY}docker not installed${X}"
fi
echo ""

# ── FOOTER ────────────────────────────────────────
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"
echo -e "${DIM}   Usage: sos [1h|3h|24h|120h]   default: 1h${X}"
echo -e "${DIM}   = Rooted by VladiMIR | AI =   v2026-04-28${X}"
echo ""
