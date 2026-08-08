#!/bin/bash
# ==========================================
# SOS MONITOR - SYSTEM AUDIT (READ-ONLY)
# ==========================================

echo "=========================================="
echo "    SOS SYSTEM MONITOR (READ-ONLY)"
echo "    Host: $(hostname) | IP: $(curl -s ifconfig.me)"
echo "    Date: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

echo ""
echo "[ PROTECTION STATUS ]"
if ss -tulpn | grep -q '80\|443'; then
    echo -n "Cloudflare HTTP coverage: "
    if curl -sI http://localhost 2>/dev/null | grep -qi "cloudflare"; then
        echo "DETECTED (Web traffic protected)"
    else
        echo "NOT DETECTED (or local proxy hides headers)"
    fi
else
    echo "Cloudflare HTTP coverage: N/A (No Web Server)"
fi

echo -n "CrowdSec Engine: "
if systemctl is-active --quiet crowdsec; then
    BANS=$(cscli decisions list -a -o json 2>/dev/null | grep -c '"id"')
    echo "ACTIVE (Bans: $BANS)"
else
    echo "INACTIVE"
fi

echo -n "CrowdSec Firewall Bouncer: "
if systemctl is-active --quiet crowdsec-firewall-bouncer; then
    echo "ACTIVE"
else
    echo "INACTIVE"
fi

echo -n "Local Firewall (UFW): "
if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Active: active"; then
    echo "ACTIVE"
else
    echo "INACTIVE"
fi

echo -n "Fail2ban: "
if systemctl is-active --quiet fail2ban; then
    echo "ACTIVE"
else
    echo "INACTIVE"
fi

echo ""
echo "[ SWAP DEVICES ]"
swapon --show
echo ""
echo "[ SWAP USAGE BY PROCESSES (Top 5) ]"
for file in /proc/*/status; do 
    awk '/VmSwap|Name/{printf $2 " " $3}END{ print ""}' "$file" 2>/dev/null
done | awk 'NF>=2 {print $2, $1}' | sort -k 1 -n -r | head -n 5 | awk '{print $2 " - " $1 " kB"}' | grep -v "^ - " || echo "No processes actively using Swap."

echo ""
echo "[ PORT AUDIT (LISTEN) ]"
printf "%-7s | %-15s | %-20s | %-15s\n" "PORT" "PROCESS" "BIND ADDRESS" "SCOPE"
echo "----------------------------------------------------------------------"
ss -tulpn | awk 'NR>1 {print $5, $7}' | sed -E 's/users:\(\("([^"]+)".*/\1/' | while read -r BIND_RAW PROC; do
    IP=$(echo "$BIND_RAW" | rev | cut -d: -f2- | rev)
    PORT=$(echo "$BIND_RAW" | rev | cut -d: -f1 | rev)
    
    if [ "$IP" = "0.0.0.0" ] || [ "$IP" = "[::]" ] || [ "$IP" = "*" ]; then
        SCOPE="PUBLIC_BIND"
    elif [[ "$IP" == 127.* ]] || [[ "$IP" == ::1 ]]; then
        SCOPE="LOCAL_ONLY"
    else
        SCOPE="PRIVATE_BIND"
    fi
    printf "%-7s | %-15s | %-20s | %-15s\n" "$PORT" "$PROC" "$IP" "$SCOPE"
done

echo ""
echo "[ HTTP STATUS SUMMARY (NGINX/APACHE LOGS) ]"
LOG_DIRS=("/var/log/nginx" "/var/log/apache2")
HTTP_301=0
HTTP_502=0

for DIR in "${LOG_DIRS[@]}"; do
    if [ -d "$DIR" ]; then
        HTTP_301=$((HTTP_301 + $(cat $DIR/*access.log 2>/dev/null | awk '$9 == 301 || $9 == 302' | wc -l)))
        HTTP_502=$((HTTP_502 + $(cat $DIR/*access.log 2>/dev/null | awk '$9 == 502 || $9 == 503' | wc -l)))
    fi
done

echo "301/302 Redirects: $HTTP_301 (Normal for HTTPS/Canonical/Migrations)"
echo "502/503 Errors:    $HTTP_502 (Backend issues or development)"

echo ""
echo "[ WORDPRESS UPDATERS ]"
WP_CRON_FILE="/etc/cron.d/wp_update_all"
MAIN_SCRIPT="/root/wp_update_all.sh"

if [ -f "$WP_CRON_FILE" ]; then
    echo "WP-Cron Task: ACTIVE"
else
    echo "WP-Cron Task: INACTIVE/MISSING"
fi

if [ -f "$MAIN_SCRIPT" ]; then
    echo "WP Script ($MAIN_SCRIPT): FOUND"
    grep -q "wp core update" "$MAIN_SCRIPT" && echo " - Core updater: ACTIVE" || echo " - Core updater: INACTIVE"
    grep -q "wp plugin update" "$MAIN_SCRIPT" && echo " - Plugin updater: ACTIVE" || echo " - Plugin updater: INACTIVE"
    grep -q "wp theme update" "$MAIN_SCRIPT" && echo " - Theme updater: ACTIVE" || echo " - Theme updater: INACTIVE"
else
    echo "WP Script ($MAIN_SCRIPT): NOT FOUND"
fi

echo "=========================================="
echo "    AUDIT COMPLETE"
echo "=========================================="
# = Rooted by VladiMIR + AI | v.2026.08.08 | github.com/GinCz =
