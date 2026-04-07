#!/usr/bin/env bash
# = Rooted by VladiMIR | AI =
# banlog.sh — CrowdSec Security Dashboard
# Version: v2026-04-07
# Usage: bash banlog.sh [limit]
# Default limit: 30

clear

LIMIT=${1:-30}
R='\033[0;31m'
Y='\033[1;33m'
G='\033[0;32m'
C='\033[0;36m'
B='\033[1;34m'
M='\033[0;35m'
W='\033[1;37m'
X='\033[0m'
BOLD='\033[1m'

# ─── HEADER ────────────────────────────────────────────────────────────────
echo -e "${BOLD}${C}"
echo "  ╔══════════════════════════════════════════════════════════════╗"
echo "  ║         🛡  CrowdSec Security Dashboard — 109-RU-VDS        ║"
echo "  ║         IP: 212.109.223.109   $(date '+%Y-%m-%d %H:%M:%S %Z')        ║"
echo "  ╚══════════════════════════════════════════════════════════════╝"
echo -e "${X}"

# ─── CROWDSEC SERVICE STATUS ───────────────────────────────────────────────
CS_STATUS=$(systemctl is-active crowdsec 2>/dev/null)
BN_STATUS=$(systemctl is-active crowdsec-firewall-bouncer-iptables 2>/dev/null)

if [ "$CS_STATUS" = "active" ]; then
  echo -e "  CrowdSec Engine:   ${G}● ACTIVE${X}"
else
  echo -e "  CrowdSec Engine:   ${R}✗ DOWN ($CS_STATUS)${X}"
fi

if [ "$BN_STATUS" = "active" ]; then
  echo -e "  Firewall Bouncer:  ${G}● ACTIVE${X}  (iptables bans enforced)"
else
  echo -e "  Firewall Bouncer:  ${R}✗ DOWN ($BN_STATUS)${X}  ${R}⚠ BANS NOT ENFORCED!${X}"
fi
echo ""

# ─── COUNTERS ──────────────────────────────────────────────────────────────
TOTAL_BANS=$(cscli decisions list -o json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if d else 0)" 2>/dev/null || echo "?")
TOTAL_ALERTS=$(cscli alerts list -o json 2>/dev/null | python3 -c "import sys,json; d=json.load(sys.stdin); print(len(d) if d else 0)" 2>/dev/null || echo "?")

# Count by attack type from decisions
SSH_BANS=$(cscli decisions list -o json 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
if d: print(sum(1 for x in d if 'ssh' in x.get('value','').lower() or 'ssh' in str(x.get('reason','')).lower()))
else: print(0)
" 2>/dev/null || echo "?")

HTTP_BANS=$(cscli decisions list -o json 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
if d: print(sum(1 for x in d if 'http' in str(x.get('reason','')).lower() or 'wordpress' in str(x.get('reason','')).lower()))
else: print(0)
" 2>/dev/null || echo "?")

echo -e "  ${BOLD}${W}📊 STATISTICS${X}"
echo -e "  ┌─────────────────────────────────────┐"
echo -e "  │  Active bans (iptables):  ${R}${BOLD}${TOTAL_BANS}${X}"
echo -e "  │  SSH brute-force bans:    ${Y}${BOLD}${SSH_BANS}${X}"
echo -e "  │  HTTP/WordPress bans:     ${M}${BOLD}${HTTP_BANS}${X}"
echo -e "  │  Total alerts (history):  ${C}${BOLD}${TOTAL_ALERTS}${X}"
echo -e "  └─────────────────────────────────────┘"
echo ""

# ─── TOP COUNTRIES ─────────────────────────────────────────────────────────
echo -e "  ${BOLD}${W}🌍 TOP ATTACKING COUNTRIES (active bans)${X}"
cscli decisions list -o json 2>/dev/null | python3 -c "
import sys, json
from collections import Counter
d = json.load(sys.stdin)
if not d: print('  No data'); sys.exit()
countries = Counter(x.get('country','??') for x in d if x.get('country'))
for country, count in countries.most_common(8):
    bar = '█' * min(count, 30)
    print(f'  {country:<4} {bar:<30} {count}')
" 2>/dev/null
echo ""

# ─── TOP ATTACK SCENARIOS ──────────────────────────────────────────────────
echo -e "  ${BOLD}${W}🎯 TOP ATTACK SCENARIOS (active bans)${X}"
cscli decisions list -o json 2>/dev/null | python3 -c "
import sys, json
from collections import Counter
d = json.load(sys.stdin)
if not d: print('  No data'); sys.exit()
scenarios = Counter(x.get('reason','unknown') for x in d)
for scenario, count in scenarios.most_common(8):
    bar = '█' * min(count, 30)
    # Color coding
    if 'ssh' in scenario: color = '\033[1;33m'
    elif 'wordpress' in scenario: color = '\033[0;35m'
    elif 'http' in scenario: color = '\033[0;36m'
    else: color = '\033[0;37m'
    reset = '\033[0m'
    print(f'  {color}{scenario:<45}{reset} {bar:<30} {count}')
" 2>/dev/null
echo ""

# ─── LAST BANS TABLE ───────────────────────────────────────────────────────
echo -e "  ${BOLD}${W}🚫 LAST ${LIMIT} BANNED IPs${X}"
echo -e "  ${Y}(newest first)${X}"
echo ""
cscli decisions list -l "$LIMIT"

# ─── RECENT ALERTS ─────────────────────────────────────────────────────────
echo ""
echo -e "  ${BOLD}${W}⚡ LAST 10 ALERTS${X}"
cscli alerts list -l 10

# ─── FOOTER ────────────────────────────────────────────────────────────────
echo ""
echo -e "  ${C}────────────────────────────────────────────────────────────────${X}"
echo -e "  ${BOLD}Useful commands:${X}"
echo -e "  ${G}cscli decisions list -l 100${X}          — show 100 bans"
echo -e "  ${G}cscli decisions delete --ip 1.2.3.4${X}  — unban IP"
echo -e "  ${G}cscli decisions add --ip 1.2.3.4${X}     — manual ban"
echo -e "  ${G}cscli metrics${X}                         — full engine stats"
echo -e "  ${C}────────────────────────────────────────────────────────────────${X}"
echo ""
