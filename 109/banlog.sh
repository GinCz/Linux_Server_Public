#!/usr/bin/env bash
# = Rooted by VladiMIR | AI =
# banlog.sh — CrowdSec Security Dashboard
# Version: v2026-04-07b
# Usage: banlog [limit]   default: 30

clear
LIMIT=${1:-30}

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

# ── HEADER ───────────────────────────────────────
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"
echo -e "${WHT}   🛡  CrowdSec Dashboard  │  ${GRN}109-RU-VDS${WHT}  │  ${YLW}212.109.223.109${WHT}  │  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"
echo ""

# ── SERVICE STATUS ─────────────────────────────────
CS=$(systemctl is-active crowdsec 2>/dev/null)
BN=$(systemctl is-active crowdsec-firewall-bouncer-iptables 2>/dev/null)
echo -e "${YLW} ► SERVICES${X}"
if [ "$CS" = "active" ]; then
  echo -e "   CrowdSec Engine        ${GRN}● ACTIVE${X}"
else
  echo -e "   CrowdSec Engine        ${RED}✗ $CS${X}"
fi
if [ "$BN" = "active" ]; then
  echo -e "   Firewall Bouncer       ${GRN}● ACTIVE${X}  ${DIM}(iptables bans enforced)${X}"
else
  echo -e "   Firewall Bouncer       ${BG_RED}${WHT} ✗ DOWN — BANS NOT ENFORCED! ${X}"
fi
echo ""

# ── FETCH JSON ───────────────────────────────────────
# cscli decisions list -o json returns array of objects with keys:
# id, source, scope, value, action, reason, country, as, events_count, expiration, alert_id
# The "reason" field IS correct for decisions (not alerts)
# But "country" may be nested under source{} in newer versions
DEC_JSON=$(cscli decisions list -o json 2>/dev/null)
ALR_JSON=$(cscli alerts list -o json 2>/dev/null)

# ── STATS ─────────────────────────────────────────
eval $(echo "$DEC_JSON" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
except:
    d = []
if not d: d = []
total = len(d)

def get_reason(x):
    # Try both flat and nested structures
    r = x.get('reason') or x.get('scenario') or ''
    if not r:
        src = x.get('source', {})
        r = src.get('reason','') if isinstance(src, dict) else ''
    return r.lower()

def get_country(x):
    cc = x.get('country','')
    if not cc:
        src = x.get('source',{})
        cc = src.get('ip_range_score','') if isinstance(src,dict) else ''
    if not cc:
        cc = x.get('scope','')
    return cc

ssh  = sum(1 for x in d if 'ssh'  in get_reason(x))
http = sum(1 for x in d if any(k in get_reason(x) for k in ['http','wordpress']))
other = total - ssh - http
alert_t = 0
print(f'TOTAL={total}')
print(f'SSH_B={ssh}')
print(f'HTTP_B={http}')
print(f'OTHER_B={other}')
" 2>/dev/null || echo 'TOTAL=0; SSH_B=0; HTTP_B=0; OTHER_B=0')

ALERT_T=$(echo "$ALR_JSON" | python3 -c "
import sys,json
try: d=json.load(sys.stdin)
except: d=[]
print(len(d) if d else 0)" 2>/dev/null || echo 0)

echo -e "${YLW} ► STATISTICS${X}"
echo -e "   ${CYN}Total active bans    ${RED}${TOTAL}${X}"
echo -e "   ${YLW}SSH brute-force      ${YLW}${SSH_B}${X}"
echo -e "   ${MAG}HTTP / WordPress     ${MAG}${HTTP_B}${X}"
echo -e "   ${GRY}Other                ${GRY}${OTHER_B}${X}"
echo -e "   ${LBL}Total alerts (all)   ${LBL}${ALERT_T}${X}"
echo ""

# ── DEBUG: print first decision keys (temporary) ───────
# Uncomment next line to debug JSON structure:
# echo "$DEC_JSON" | python3 -c "import sys,json;d=json.load(sys.stdin);print(list(d[0].keys()) if d else 'empty')" 2>/dev/null

# ── TOP COUNTRIES (bar chart) ─────────────────────────
echo -e "${YLW} ► TOP ATTACKING COUNTRIES${X}"
echo "$DEC_JSON" | python3 -c "
import sys, json
from collections import Counter
try:
    d = json.load(sys.stdin)
except:
    d = []
if not d: print('   no data'); sys.exit()

def get_country(x):
    cc = x.get('country','')
    if not cc:
        src = x.get('source',{})
        if isinstance(src, dict): cc = src.get('country','')
    return cc or '??'

countries = Counter(get_country(x) for x in d)
mx = max(v for _,v in countries.most_common(1)) if countries else 1
palette = ['\033[1;31m','\033[1;33m','\033[38;5;214m','\033[1;35m','\033[38;5;117m',
           '\033[1;36m','\033[1;32m','\033[38;5;213m','\033[0;37m','\033[2m']
for i,(cc,cnt) in enumerate(countries.most_common(10)):
    bar = '\u2588' * max(1, int(cnt/mx*36))
    c = palette[min(i, len(palette)-1)]
    print(f'   {c}{cc:<5}\033[0m {c}{bar:<36}\033[0m  {cnt}')
" 2>/dev/null
echo ""

# ── TOP SCENARIOS (bar chart) ────────────────────────
echo -e "${YLW} ► TOP ATTACK SCENARIOS${X}"
echo "$DEC_JSON" | python3 -c "
import sys, json
from collections import Counter
try:
    d = json.load(sys.stdin)
except:
    d = []
if not d: print('   no data'); sys.exit()

def get_reason(x):
    r = x.get('reason') or x.get('scenario') or ''
    if not r:
        src = x.get('source',{})
        if isinstance(src, dict): r = src.get('reason','')
    return r or 'unknown'

scenarios = Counter(get_reason(x) for x in d)
mx = max(v for _,v in scenarios.most_common(1)) if scenarios else 1
for sc, cnt in scenarios.most_common(10):
    bar = '\u2588' * max(1, int(cnt/mx*28))
    if 'ssh'        in sc: c = '\033[1;33m'
    elif 'wordpress' in sc: c = '\033[1;35m'
    elif 'proxy'     in sc: c = '\033[38;5;214m'
    elif 'http'      in sc: c = '\033[1;36m'
    else:                   c = '\033[0;37m'
    label = sc.replace('crowdsecurity/','').replace('crowdsec-cve-','cve-')
    print(f'   {c}{label:<40}\033[0m {c}{bar:<28}\033[0m  {cnt}')
" 2>/dev/null
echo ""

# ── LAST BANS TABLE ────────────────────────────────────
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"
echo -e "${WHT} 🚫 LAST ${LIMIT} BANNED IPs  ${DIM}(newest first)${X}"
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"
cscli decisions list -l "$LIMIT"
echo ""

# ── FOOTER ─────────────────────────────────────────
echo -e "${DIM} banlog50 — 50 bans   ${ORG}banblock 1.2.3.4 — ban${X}${DIM}   ${GRN}banunblock 1.2.3.4 — unban${X}"
echo ""
