#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  banlog.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : CrowdSec & IPTables security ban dashboard & attacker analytics
# Servers     : All Linux Nodes (222-DE / 109-RU / VPN Nodes)
# Usage       : bash scripts/banlog.sh [limit]
# ==========================================================================================
LIMIT=${1:-30}

# ── COLORS ───────────────────────────────────────
RED='\033[1;31m'; GRN='\033[1;32m'; YLW='\033[1;33m'; MAG='\033[1;35m'
CYN='\033[1;36m'; WHT='\033[1;37m'; ORG='\033[38;5;214m'; LBL='\033[38;5;117m'
GRY='\033[0;37m'; DIM='\033[2m'; X='\033[0m'
BG_RED='\033[41m'; BG_GRN='\033[42m'

MY_HOST=$(hostname)
MY_IP=$(hostname -I 2>/dev/null | awk '{print $1}')

# ── HEADER ───────────────────────────────────────
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"
echo -e "${WHT}   🛡  CrowdSec Security Dashboard  │  ${GRN}${MY_HOST}${WHT}  │  ${YLW}${MY_IP}${WHT}  │  ${DIM}$(date '+%Y-%m-%d %H:%M:%S')${X}"
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"
echo ""

# ── SERVICE STATUS ─────────────────────────────────
CS=$(systemctl is-active crowdsec 2>/dev/null)
BN_SVC=$(systemctl list-units --type=service --all 2>/dev/null \
  | grep -oE 'crowdsec[a-z-]*bouncer[a-z-]*\.service' | head -1)
BN_SVC=${BN_SVC:-crowdsec-firewall-bouncer-iptables.service}
BN=$(systemctl is-active "$BN_SVC" 2>/dev/null || echo 'not-found')
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
ssh    = sum(1 for x in d if 'ssh' in sc(x))
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

# ── TOP COUNTRIES ──────────────────────────────────
echo -e "${YLW} ► TOP ATTACKING COUNTRIES${X}"
echo "$ALR_JSON" | python3 -c "
import sys, json
from collections import Counter
try:
    d = json.load(sys.stdin) or []
    c = Counter(x.get('source',{}).get('cn','??') for x in d if x.get('source',{}).get('cn'))
    top = c.most_common(5)
    if top:
        print('   ' + '   '.join(f'{k}: {v}' for k, v in top))
    else:
        print('   No country data')
except:
    print('   No country data')
" 2>/dev/null
echo ""

# ── ACTIVE DECISIONS TABLE ─────────────────────────
echo -e "${YLW} ► ACTIVE BANS LIST (cscli decisions list)${X}"
cscli decisions list 2>/dev/null || echo "No active decisions"

echo ""
echo -e "${CYN}══════════════════════════════════════════════════════════════════════${X}"

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
