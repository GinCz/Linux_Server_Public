#!/bin/bash
# =============================================================
# Script:      ports.sh
# Version:     v2026.07.01d
# Description: Show all open TCP/UDP ports with process names.
#              Key ports table + UFW status.
# Fix:         Pure awk port detection — no grep -c in arithmetic
# Usage:       ports
# = Rooted by VladiMIR + AI | v.2026.07.01d | github.com/GinCz =
# =============================================================
clear
C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'

HN=$(hostname)
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
DT=$(date '+%Y-%m-%d %H:%M')

echo -e "${C}$(printf '%0.s═' {1..60})${X}"
echo -e "  ${W}OPEN PORTS — ${HN}${X}  |  ${DT}  |  ${IP}"
echo -e "${C}$(printf '%0.s═' {1..60})${X}"

# ── TCP LISTEN (deduplicated by port:process) ────────────────
echo -e "\n  ${C}TCP LISTEN:${X}"
ss -tlnp 2>/dev/null | awk '
  NR>1 {
    addr=$4; proc=$NF
    gsub(/users:\(\(|\)\)/, "", proc)
    sub(/,.*/, "", proc)
    port=addr; sub(/.*:/, "", port)
    key=port ":" proc
    if (!seen[key]++) printf "    %-32s %s\n", addr, proc
  }
' | sort -t: -k2 -n

# ── UDP LISTEN (deduplicated by port:process) ────────────────
echo -e "\n  ${C}UDP LISTEN:${X}"
ss -ulnp 2>/dev/null | awk '
  NR>1 {
    addr=$4; proc=$NF
    gsub(/users:\(\(|\)\)/, "", proc)
    sub(/,.*/, "", proc)
    port=addr; sub(/.*:/, "", port)
    key=port ":" proc
    if (!seen[key]++) printf "    %-32s %s\n", addr, proc
  }
' | sort -t: -k2 -n

# ── KEY PORTS ────────────────────────────────────────────────
echo -e "\n${C}$(printf '%0.s─' {1..60})${X}"
echo -e "  ${C}KEY PORTS:${X}"

# Build open port list once via awk (avoids any grep -c issues)
TCP_PORTS=$(ss -tlnp 2>/dev/null | awk 'NR>1{addr=$4; sub(/.*:/,"",addr); print addr}' | sort -un)
UDP_PORTS=$(ss -ulnp 2>/dev/null | awk 'NR>1{addr=$4; sub(/.*:/,"",addr); print addr}' | sort -un)

declare -A PNAMES
PNAMES=(
  [21]="FTP"
  [22]="SSH"
  [25]="SMTP"
  [53]="DNS"
  [80]="HTTP"
  [443]="HTTPS"
  [445]="Samba/SMB"
  [587]="SMTP-Submit"
  [993]="IMAPS"
  [995]="POP3S"
  [2222]="SSH-alt"
  [3000]="Semaphore/AGH"
  [3306]="MySQL/MariaDB"
  [8080]="AGH-Web/Alt-HTTP"
  [8443]="Alt-HTTPS/Xray"
  [51820]="WireGuard/AMN"
)

for P in 21 22 25 53 80 443 445 587 993 995 2222 3000 3306 8080 8443 51820; do
  NAME="${PNAMES[$P]}"
  TC=0; UC=0
  echo "$TCP_PORTS" | grep -qx "$P" && TC=1
  echo "$UDP_PORTS" | grep -qx "$P" && UC=1
  TOTAL=$(( TC + UC ))
  if [ "$TOTAL" -gt 0 ]; then
    PROTO=""
    [ "$TC" -gt 0 ] && PROTO="${PROTO}TCP "
    [ "$UC" -gt 0 ] && PROTO="${PROTO}UDP"
    printf "    ${G}●${X}  ${W}%-6s${X}  ${C}%-18s${X}  ${G}OPEN${X}  [${Y}%s${X}]\n" "$P" "$NAME" "${PROTO% }"
  else
    printf "    ${Y}-${X}  ${W}%-6s${X}  ${C}%-18s${X}  closed\n" "$P" "$NAME"
  fi
done

# ── UFW ─────────────────────────────────────────────────────────
echo -e "\n${C}$(printf '%0.s─' {1..60})${X}"
echo -e "  ${C}FIREWALL (UFW):${X}"
if command -v ufw >/dev/null 2>&1; then
  UFW_OUT=$(ufw status 2>/dev/null)
  UFW_ST=$(echo "$UFW_OUT" | head -1)
  if echo "$UFW_ST" | grep -qi 'active'; then
    echo -e "    ${G}● $UFW_ST${X}"
    echo "$UFW_OUT" | grep -v '^Status\|^To\|^--\|^$' | head -15 | \
      while IFS= read -r L; do echo -e "    ${W}${L}${X}"; done
  else
    echo -e "    ${R}● $UFW_ST${X}"
  fi
else
  echo -e "    ${Y}ufw not installed${X}"
fi

echo -e "\n${C}$(printf '%0.s═' {1..60})${X}"
echo -e "  ${W}ports v2026.07.01d${X} | ${C}Rooted by VladiMIR + AI${X} | ${C}github.com/GinCz${X}"
