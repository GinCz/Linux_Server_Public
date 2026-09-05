#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  samba_fix_remote.sh | [v2026-07-04]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Remote SSH dispatcher for Samba configuration repair
# Servers     : All Samba Nodes
# Usage       : bash scripts/samba_fix_remote.sh
# ==========================================================================================
G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
SEP="${Y}$(printf '=%.0s' {1..62})${X}"

PAYLOAD_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/samba_fix_payload.sh"

# Target servers: label:IP:PORT:USER
SERVERS=(
    "109-RU-FastVDS:212.109.223.109:22:root"
    "ALEX-47:212.34.148.51:22:root"
    "4TON-237:144.124.228.237:22:root"
    "TATRA-9:144.124.232.9:22:root"
    "SHAHIN-227:144.124.228.227:22:root"
    "STOLB-24:144.124.239.24:22:root"
    "PILIK-33:195.63.138.33:22:root"
    "ILYA-176:146.103.110.176:22:root"
    "SO-38:144.124.233.38:22:root"
    "IONOS:82.223.116.38:22:root"
)

echo -e "$SEP"
echo -e "  ${W}SAMBA REMOTE FIX -- ALL SERVERS${X}"
echo -e "  ${C}Source: $(hostname)  (222-DE)${X}"
echo -e "  ${C}Targets: ${#SERVERS[@]} servers${X}"
echo -e "  ${C}Payload: $PAYLOAD_URL${X}"
echo -e "$SEP"
echo
echo -e "  Each server will:"
echo -e "  ${G}1.${X} Fix create mask 0664 -> 0775 (execute bit)"
echo -e "  ${G}2.${X} Add force create mode = 0775"
echo -e "  ${G}3.${X} Fix /storage permissions (chmod 2775)"
echo -e "  ${G}4.${X} Restart smbd"
echo -e "  ${Y}  Servers without Samba are auto-skipped.${X}"
echo
read -rp "  Type YES to run on all ${#SERVERS[@]} servers: " CONFIRM
[[ "${CONFIRM}" == "YES" ]] || { echo "Aborted"; exit 1; }
echo

OK_LIST=()
FAIL_LIST=()
SKIP_LIST=()

for ENTRY in "${SERVERS[@]}"; do
    LABEL=$(cut -d: -f1 <<< "$ENTRY")
    IP=$(cut    -d: -f2 <<< "$ENTRY")
    PORT=$(cut  -d: -f3 <<< "$ENTRY")
    USER=$(cut  -d: -f4 <<< "$ENTRY")

    echo -e "$SEP"
    echo -e "  ${W}[${LABEL}]${X}  ${C}${USER}@${IP}:${PORT}${X}"
    echo -e "$SEP"

    # Connectivity check
    if ! ssh -o ConnectTimeout=5 \
             -o StrictHostKeyChecking=no \
             -o BatchMode=yes \
             -p "$PORT" "${USER}@${IP}" 'echo PING' &>/dev/null; then
        echo -e "  ${R}UNREACHABLE -- skipping${X}"
        SKIP_LIST+=("$LABEL ($IP)")
        echo
        continue
    fi

    # Run: download payload on remote server and execute it
    if ssh -o ConnectTimeout=15 \
           -o StrictHostKeyChecking=no \
           -p "$PORT" "${USER}@${IP}" \
           "bash <(curl -fsSL --connect-timeout 10 '${PAYLOAD_URL}')"; then
        OK_LIST+=("$LABEL ($IP)")
        echo -e "  ${G}DONE: $LABEL${X}"
    else
        FAIL_LIST+=("$LABEL ($IP)")
        echo -e "  ${R}FAILED: $LABEL${X}"
    fi
    echo
done

echo -e "$SEP"
echo -e "  ${W}SUMMARY${X}"
echo -e "$SEP"
[ ${#OK_LIST[@]}   -gt 0 ] && echo -e "  ${G}SUCCESS (${#OK_LIST[@]}):${X}"   && for S in "${OK_LIST[@]}";   do echo -e "    ${G}+${X} $S"; done
[ ${#SKIP_LIST[@]} -gt 0 ] && echo -e "  ${Y}UNREACHABLE (${#SKIP_LIST[@]}):${X}" && for S in "${SKIP_LIST[@]}"; do echo -e "    ${Y}?${X} $S"; done
[ ${#FAIL_LIST[@]} -gt 0 ] && echo -e "  ${R}FAILED (${#FAIL_LIST[@]}):${X}"   && for S in "${FAIL_LIST[@]}"; do echo -e "    ${R}x${X} $S"; done
echo
echo -e "  ${C}Server 222 (this server) -- already fixed manually.${X}"
echo
echo -e "$SEP"
echo -e "  ${W}= Rooted by VladiMIR + AI | v2026.07.04 | github.com/GinCz =${X}"
echo -e "$SEP"

# = Rooted by VladiMIR | AI = v2026-07-04 = github.com/GinCz/Linux_Server_Public
