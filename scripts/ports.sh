#!/bin/bash
# =============================================================
# Script:      ports.sh
# Version:     v2026.07.01c
# Description: Show all open TCP/UDP ports with process names.
#              Displays key ports table with open/closed status.
# Fixes:       - grep -c arithmetic error (|| echo 0 in subshell)
#              - deduplicate repeated ss entries (named/docker)
#              - UFW status full output
# Usage:       ports
# = Rooted by VladiMIR + AI | v.2026.07.01c | github.com/GinCz =
# =============================================================
clear
C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'

echo -e "${C}════════════════════════════════════════════════════${X}"
echo -e "  ${W}OPEN PORTS — $(hostname)${X}  |  $(date '+%Y-%m-%d %H:%M')  |  $(hostname -I 2>/dev/null | awk '{print $1}')"
echo -e "${C}════════════════════════════════════════════════════${X}"

# TCP listening ports — deduplicated by port:process
echo -e "\n  ${C}TCP LISTEN:${X}"
ss -tlnp 2>/dev/null | awk 'NR>1 {
    addr=$4; proc=$NF
    gsub(/users:\(\(|\)\)/,"",proc)
    sub(/,.*/,"",proc)
    # extract port for dedup key
    port=addr; sub(/.*:/,"",port)
    key=port":"proc
    if (!seen[key]++) printf "    %-30s %s\n", addr, proc
}' | sort -t: -k2 -n

# UDP listening ports — deduplicated by port:process
echo -e "\n  ${C}UDP LISTEN:${X}"
ss -ulnp 2>/dev/null | awk 'NR>1 {
    addr=$4; proc=$NF
    gsub(/users:\(\(|\)\)/,"",proc)
    sub(/,.*/,"",proc)
    port=addr; sub(/.*:/,"",port)
    key=port":"proc
    if (!seen[key]++) printf "    %-30s %s\n", addr, proc
}' | sort -t: -k2 -n

# ── KEY PORTS status table ────────────────────────────────────
echo -e "\n${C}────────────────────────────────────────────────────${X}"
echo -e "  ${C}KEY PORTS:${X}"

declare -A PNAMES=(
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
    [3000]="Semaphore/AGH"
    [3306]="MySQL/MariaDB"
    [8080]="AGH-Web/Alt-HTTP"
    [8443]="Alt-HTTPS/Xray"
    [51820]="WireGuard/AMN"
)

check_port() {
    local P=$1
    local TC UC
    TC=$(ss -tlnp 2>/dev/null | awk 'NR>1{print $4}' | awk -F: '{print $NF}' | grep -c "^${P}$")
    UC=$(ss -ulnp 2>/dev/null | awk 'NR>1{print $4}' | awk -F: '{print $NF}' | grep -c "^${P}$")
    # grep -c returns 1 on no match (exit 1) — force numeric
    TC=$(( TC + 0 ))
    UC=$(( UC + 0 ))
    echo "$TC $UC"
}

for P in 21 22 25 53 80 443 445 587 993 995 3000 3306 8080 8443 51820; do
    NAME="${PNAMES[$P]}"
    read TC UC <<< $(check_port $P)
    TOTAL=$(( TC + UC ))
    if [ "$TOTAL" -gt 0 ]; then
        PROTO=""
        [ "$TC" -gt 0 ] && PROTO="${PROTO}TCP "
        [ "$UC" -gt 0 ] && PROTO="${PROTO}UDP"
        printf "    ${G}●${X}  ${W}%-6s${X}  ${C}%-18s${X}  ${G}OPEN${X}  [${Y}%s${X}]\n" "$P" "$NAME" "$PROTO"
    else
        printf "    ${Y}-${X}  ${W}%-6s${X}  ${C}%-18s${X}  closed\n" "$P" "$NAME"
    fi
done

# ── UFW status ───────────────────────────────────────────────
echo -e "\n${C}────────────────────────────────────────────────────${X}"
echo -e "  ${C}FIREWALL (UFW):${X}"
if command -v ufw >/dev/null 2>&1; then
    UFW_STATUS=$(ufw status 2>/dev/null)
    UFW_LINE=$(echo "$UFW_STATUS" | head -1)
    if echo "$UFW_LINE" | grep -qi "active"; then
        echo -e "    ${G}● $UFW_LINE${X}"
        # Show allowed ports summary (non-DENY rules)
        echo "$UFW_STATUS" | grep -v '^Status\|^To\|^--\|^$' | head -20 | while read LINE; do
            echo -e "    ${W}$LINE${X}"
        done
    else
        echo -e "    ${R}● $UFW_LINE${X}"
    fi
else
    echo -e "    ${Y}ufw not installed${X}"
fi

echo -e "\n${C}════════════════════════════════════════════════════${X}"
echo -e "  ${W}ports v2026.07.01c${X} | ${C}Rooted by VladiMIR + AI${X} | ${C}github.com/GinCz${X}"
