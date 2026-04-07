#!/usr/bin/env bash
# = Rooted by VladiMIR | AI =
# banlog.sh — CrowdSec Security Dashboard
# Version: v2026-04-08
# Usage: banlog [limit]   default: 30
# JSON source: cscli alerts list -o json
# Structure: alert.source.cn = country code, alert.scenario = attack type

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
BG_GRN='\033[42m'

# ── HEADER ───────────────────────────────────────
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"
echo -e "${WHT}   🛡  CrowdSec Dashboard  │  ${GRN}109-RU-VDS${WHT}  │  ${YLW}212.109.223.109${WHT}  │  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"
echo ""

# ── SERVICE STATUS ─────────────────────────────────
CS=$(systemctl is-active crowdsec 2>/dev/null)
# Detect bouncer service name (may differ by install method)
BN_SVC=$(systemctl list-units --type=service --all 2>/dev/null \
  | grep -oE 'crowdsec[a-z-]*bouncer[a-z-]*\.service' | head -1)
BN_SVC=${BN_SVC:-crowdsec-firewall-bouncer-iptables.service}
BN=$(systemctl is-active "$BN_SVC" 2>/dev/null || echo 'not-found')
# Also check via cscli bouncers list
BN_CSCLI=$(cscli bouncers list 2>/dev/null | grep -c 'valid' || echo 0)

echo -e "${YLW} ► SERVICES${X}"
if [ "$CS" = "active" ]; then
  echo -e "   CrowdSec Engine        ${GRN}● ACTIVE${X}"
else
  echo -e "   CrowdSec Engine        ${RED}✗ $CS${X}"
fi
if [ "$BN" = "active" ]; then
  echo -e "   Firewall Bouncer       ${GRN}● ACTIVE${X}  ${DIM}(${BN_SVC})${X}"
elif [ "$BN_CSCLI" -gt 0 ] 2>/dev/null; then
  echo -e "   Firewall Bouncer       ${GRN}● ACTIVE${X}  ${DIM}(${BN_CSCLI} bouncer(s) via cscli)${X}"
else
  echo -e "   Firewall Bouncer       ${BG_RED}${WHT} ✗ DOWN — BANS NOT ENFORCED! ${X}"
  echo -e "   ${DIM}  Fix: apt install crowdsec-firewall-bouncer-iptables -y${X}"
fi
echo ""

# ── FETCH ALERTS JSON ──────────────────────────────
# cscli alerts list -o json returns alerts (not decisions)
# Each alert: { scenario, source: { cn, ip, as_name, as_number }, decisions: [...] }
ALR_JSON=$(cscli alerts list -o json 2>/dev/null)

# ── STATS via python ──────────────────────────────
eval $(echo "$ALR_JSON" | python3 -c "
import sys, json
try:
    d = json.load(sys.stdin)
except:
    d = []
if not d: d = []

def sc(x): return (x.get('scenario') or '').lower()

total  = len(d)
ssh    = sum(1 for x in d if 'ssh'  in sc(x))
http   = sum(1 for x in d if any(k in sc(x) for k in ['http','wordpress','web']))
other  = total - ssh - http
print(f'TOTAL={total}')
print(f'SSH_B={ssh}')
print(f'HTTP_B={http}')
print(f'OTHER_B={other}')
" 2>/dev/null || echo 'TOTAL=0;SSH_B=0;HTTP_B=0;OTHER_B=0')

# Active bans count from decisions
BAN_COUNT=$(cscli decisions list -o json 2>/dev/null | python3 -c \
  "import sys,json;d=json.load(sys.stdin);print(len(d) if d else 0)" 2>/dev/null || echo 0)

echo -e "${YLW} ► STATISTICS${X}"
echo -e "   ${CYN}Active bans (iptables) ${RED}${BAN_COUNT}${X}"
echo -e "   ${CYN}Alerts (last 50)       ${WHT}${TOTAL}${X}"
echo -e "   ${YLW}  SSH brute-force        ${YLW}${SSH_B}${X}"
echo -e "   ${MAG}  HTTP / WordPress       ${MAG}${HTTP_B}${X}"
echo -e "   ${GRY}  Other                  ${GRY}${OTHER_B}${X}"
echo ""

# ── TOP COUNTRIES (source.cn field) ──────────────────
echo -e "${YLW} ► TOP ATTACKING COUNTRIES${X}"
echo "$ALR_JSON" | python3 -c "
import sys, json
from collections import Counter
try:
    d = json.load(sys.stdin)
except:
    d = []
if not d: print('   no data'); sys.exit()
# country is in source.cn
countries = Counter()
for x in d:
    src = x.get('source', {})
    cc = src.get('cn') or src.get('country') or '??'
    countries[cc] += 1
mx = max(v for _,v in countries.most_common(1)) if countries else 1
palette = ['\033[1;31m','\033[1;33m','\033[38;5;214m','\033[1;35m','\033[38;5;117m',
           '\033[1;36m','\033[1;32m','\033[38;5;213m','\033[0;37m','\033[2m']
for i,(cc,cnt) in enumerate(countries.most_common(10)):
    bar = '\u2588' * max(1, int(cnt/mx*36))
    c = palette[min(i, len(palette)-1)]
    print(f'   {c}{cc:<5}\033[0m {c}{bar:<36}\033[0m  {cnt}')
" 2>/dev/null
echo ""

# ── TOP SCENARIOS (alert.scenario field) ───────────────
echo -e "${YLW} ► TOP ATTACK SCENARIOS${X}"
echo "$ALR_JSON" | python3 -c "
import sys, json
from collections import Counter
try:
    d = json.load(sys.stdin)
except:
    d = []
if not d: print('   no data'); sys.exit()
scenarios = Counter(x.get('scenario','unknown') for x in d)
mx = max(v for _,v in scenarios.most_common(1)) if scenarios else 1
for sc, cnt in scenarios.most_common(10):
    bar = '\u2588' * max(1, int(cnt/mx*28))
    if 'ssh'         in sc: c = '\033[1;33m'
    elif 'wordpress'  in sc: c = '\033[1;35m'
    elif 'proxy'      in sc: c = '\033[38;5;214m'
    elif 'http'       in sc: c = '\033[1;36m'
    elif 'cve'        in sc: c = '\033[1;31m'
    else:                    c = '\033[0;37m'
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
echo -e "${DIM} banlog50 — 50 rows   ${ORG}banblock 1.2.3.4 — ban${X}${DIM}   ${GRN}banunblock 1.2.3.4 — unban${X}"
echo ""
