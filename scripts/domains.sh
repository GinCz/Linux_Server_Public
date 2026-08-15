#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  domains.sh | [v2026-06-29]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Check all virtual host domains, HTTP status, SSL expiry, auto-renew ACME SSL
# Servers     : All Web Nodes (222-DE / 109-RU FastPanel)
# Usage       : bash scripts/domains.sh
# ==========================================================================================
clear

C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; B='\033[0;34m'; X='\033[0m'
SERVER_NAME=$(hostname)
REPORT_MSG="📊 SERVER: ${SERVER_NAME}\n---------------------------\n"
RENEW_THRESHOLD=15  # Days remaining threshold for forced renewal

echo -e "${Y}🚀 Checking domains on ${SERVER_NAME}...${X}"
echo "---------------------------"

DOMAINS=$(nginx -T 2>/dev/null | grep "server_name " | awk '{for(i=2;i<=NF;i++) print $i}' | tr -d ';' | grep "\." | grep -v "^www\." | grep -v "localhost" | sort -u)

if [ -z "$DOMAINS" ]; then
    echo -e "${R}❌ No domains found in Nginx config!${X}"
    exit 1
fi

# --- HTTP + SSL check ---
for domain in $DOMAINS; do
    # HTTP status
    STATUS=$(curl -o /dev/null -s -L -w "%{http_code}" --max-time 5 "http://$domain")
    if [ "$STATUS" == "200" ] || [ "$STATUS" == "301" ] || [ "$STATUS" == "302" ]; then
        COLOR=$C; SYMBOL="✅"
    else
        COLOR=$R; SYMBOL="❌"
    fi

    # SSL days remaining
    SSL_INFO=""
    DAYS_LEFT=""
    EXPIRY=$(echo | openssl s_client -servername "$domain" -connect "${domain}:443" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
    if [ -n "$EXPIRY" ]; then
        EXPIRY_TS=$(date -d "$EXPIRY" +%s 2>/dev/null)
        NOW_TS=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_TS - NOW_TS) / 86400 ))
        if [ "$DAYS_LEFT" -le 0 ]; then
            SSL_INFO="${R}🔴 SSL EXPIRED!${X}"
        elif [ "$DAYS_LEFT" -le "$RENEW_THRESHOLD" ]; then
            SSL_INFO="${R}⚠️  SSL: ${DAYS_LEFT}d — RENEWING...${X}"
        elif [ "$DAYS_LEFT" -le 30 ]; then
            SSL_INFO="${Y}🟡 SSL: ${DAYS_LEFT}d${X}"
        else
            SSL_INFO="${C}🟢 SSL: ${DAYS_LEFT}d${X}"
        fi
    else
        SSL_INFO="${B}🔵 SSL: no HTTPS${X}"
    fi

    echo -e "${SYMBOL} ${domain} | ${COLOR}HTTP:${STATUS}${X} | ${SSL_INFO}"
    REPORT_MSG="${REPORT_MSG}${SYMBOL} ${domain} | HTTP:${STATUS} | SSL: ${DAYS_LEFT:-?}d\n"

    # Auto-renew if <15 days and domain registered in acme.sh
    if [ -n "$DAYS_LEFT" ] && [ "$DAYS_LEFT" -le "$RENEW_THRESHOLD" ]; then
        ACME_DOMAIN=$(/.acme.sh/acme.sh --list 2>/dev/null | awk 'NR>1 {print $1}' | grep -x "$domain")
        if [ -n "$ACME_DOMAIN" ]; then
            echo -e "  ${Y}↪ Forcing renew for ${domain}...${X}"
            /.acme.sh/acme.sh --renew -d "$domain" -d "www.$domain" --force >> /var/log/acme-deploy.log 2>&1
            REPORT_MSG="${REPORT_MSG}  ↪ RENEW triggered: ${domain}\n"
        else
            echo -e "  ${R}⚠️  ${domain} not in acme.sh — manual action needed${X}"
            REPORT_MSG="${REPORT_MSG}  ⚠️ ${domain}: not in acme.sh — manual action needed\n"
        fi
    fi
done

echo "---------------------------"
echo -e "${C}Done!${X}"

[ -n "${TG_TOKEN:-}" ] && curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
  -d "chat_id=${TG_CHAT_ID}" \
  -d "text=$(echo -e "$REPORT_MSG")" > /dev/null

# = Rooted by VladiMIR | AI = v2026-06-29 = github.com/GinCz/Linux_Server_Public
