#!/bin/bash
# =============================================================
# Script:      ports.sh
# Version:     v2026.07.01b
# Description: Show all open TCP/UDP ports with process names.
#              Displays key ports table (SSH/HTTP/HTTPS/Samba/
#              WireGuard/AdGuard/Semaphore) with open/closed status.
# Usage:       ports
# Fix:         awk filter corrected — ss -tlnp rows have no /LISTEN/ keyword
# = Rooted by VladiMIR + AI | v.2026.07.01b | github.com/GinCz =
# =============================================================
clear
C='\033[1;36m'; G='\033[1;32m'; Y='\033[1;33m'; W='\033[1;37m'; R='\033[1;31m'; X='\033[0m'

echo -e "${C}════════════════════════════════════════════════════${X}"
echo -e "  ${W}OPEN PORTS — $(hostname)${X}  |  $(date '+%Y-%m-%d %H:%M')  |  $(hostname -I 2>/dev/null | awk '{print $1}')"
echo -e "${C}════════════════════════════════════════════════════${X}"

# TCP listening ports
echo -e "\n  ${C}TCP LISTEN:${X}"
ss -tlnp 2>/dev/null | awk 'NR>1 {
    addr=$4; proc=$NF
    gsub(/users:\(\(|\)\)/,"",proc)
    sub(/,.*/,"",proc)
    printf "    %-28s %s\n", addr, proc
}' | sort -t: -k2 -n

# UDP listening ports
echo -e "\n  ${C}UDP LISTEN:${X}"
ss -ulnp 2>/dev/null | awk 'NR>1 {
    addr=$4; proc=$NF
    gsub(/users:\(\(|\)\)/,"",proc)
    sub(/,.*/,"",proc)
    printf "    %-28s %s\n", addr, proc
}' | sort -t: -k2 -n

# Key ports status table
echo -e "\n${C}────────────────────────────────────────────────────${X}"
echo -e "  ${C}KEY PORTS:${X}"

declare -A PNAMES=(
    [22]="SSH"
    [25]="SMTP"
    [53]="DNS"
    [80]="HTTP"
    [443]="HTTPS"
    [445]="Samba/SMB"
    [3000]="Semaphore/AGH-DNS"
    [3306]="MySQL/MariaDB"
    [6443]="Kubernetes API"
    [8080]="AGH-Web/Alt-HTTP"
    [8443]="Alt-HTTPS"
    [51820]="WireGuard/AMN"
)

for P in 22 25 53 80 443 445 3000 3306 8080 8443 51820; do
    NAME="${PNAMES[$P]}"
    TC=$(ss -tlnp 2>/dev/null | awk 'NR>1{print $4}' | grep -c ":${P}$" || echo 0)
    UC=$(ss -ulnp 2>/dev/null | awk 'NR>1{print $4}' | grep -c ":${P}$" || echo 0)
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

# UFW status summary
echo -e "\n${C}────────────────────────────────────────────────────${X}"
echo -e "  ${C}FIREWALL (UFW):${X}"
UFW_ST=$(ufw status 2>/dev/null | head -1)
echo -e "    $UFW_ST"

echo -e "\n${C}════════════════════════════════════════════════════${X}"
echo -e "  ${W}ports v2026.07.01b${X} | ${C}Rooted by VladiMIR + AI${X} | ${C}github.com/GinCz${X}"
