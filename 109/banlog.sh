#!/usr/bin/env bash
# = Rooted by VladiMIR | AI =
# banlog.sh — CrowdSec Security Dashboard
# Version: v2026-04-07
# Usage: banlog [limit]   default: 30

clear
LIMIT=${1:-30}

# ── COLORS ───────────────────────────────────────
RED='\033[1;31m'
GRN='\033[1;32m'
YLW='\033[1;33m'
BLU='\033[1;34m'
MAG='\033[1;35m'
CYN='\033[1;36m'
WHT='\033[1;37m'
ORG='\033[38;5;214m'
PNK='\033[38;5;213m'
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

# ── STATS ─────────────────────────────────────────
DEC_JSON=$(cscli decisions list -o json 2>/dev/null)
ALR_JSON=$(cscli alerts list -o json 2>/dev/null)

TOTAL=$(echo "$DEC_JSON" | python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d) if d else 0)" 2>/dev/null || echo 0)
SSH_B=$(echo "$DEC_JSON" | python3 -c "import sys,json;d=json.load(sys.stdin);print(sum(1 for x in (d or []) if 'ssh' in str(x.get('reason','')).lower()))" 2>/dev/null || echo 0)
HTTP_B=$(echo "$DEC_JSON" | python3 -c "import sys,json;d=json.load(sys.stdin);print(sum(1 for x in (d or []) if any(k in str(x.get('reason','')).lower() for k in ['http','wordpress'])))" 2>/dev/null || echo 0)
OTHER_B=$(( TOTAL - SSH_B - HTTP_B ))
ALERT_T=$(echo "$ALR_JSON" | python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d) if d else 0)" 2>/dev/null || echo 0)

echo -e "${YLW} ► STATISTICS${X}"
echo -e "   ${CYN}Total active bans    ${RED}${TOTAL}${X}"
echo -e "   ${YLW}SSH brute-force      ${YLW}${SSH_B}${X}"
echo -e "   ${MAG}HTTP / WordPress     ${MAG}${HTTP_B}${X}"
echo -e "   ${GRY}Other                ${GRY}${OTHER_B}${X}"
echo -e "   ${LBL}Total alerts (all)   ${LBL}${ALERT_T}${X}"
echo ""

# ── TOP COUNTRIES (bar chart) ─────────────────────────
echo -e "${YLW} ► TOP ATTACKING COUNTRIES${X}"
echo "$DEC_JSON" | python3 -c "
import sys, json
from collections import Counter
d = json.load(sys.stdin)
if not d: print('   no data'); sys.exit()
countries = Counter(x.get('country','??') for x in d if x.get('country'))
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
d = json.load(sys.stdin)
if not d: print('   no data'); sys.exit()
scenarios = Counter(x.get('reason','unknown') for x in d)
mx = max(v for _,v in scenarios.most_common(1)) if scenarios else 1
for sc, cnt in scenarios.most_common(10):
    bar = '\u2588' * max(1, int(cnt/mx*28))
    if 'ssh' in sc:         c = '\033[1;33m'
    elif 'wordpress' in sc: c = '\033[1;35m'
    elif 'proxy' in sc:     c = '\033[38;5;214m'
    elif 'http' in sc:      c = '\033[1;36m'
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
