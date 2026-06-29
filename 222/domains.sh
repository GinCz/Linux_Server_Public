#!/usr/bin/env bash
# =============================================================================
# domains.sh — Check all domains + SSL cert status + auto-renew if needed
# Version     : v2026-06-29
# Server      : 222-DE-NetCup (152.53.182.222)
# Usage       : domains  (alias) or bash /root/Linux_Server_Public/222/domains.sh
# Cron        : 15 2 * * 6  bash /root/Linux_Server_Public/222/domains.sh
#               (каждую субботу в 02:15 — проверка + авторенью <15 дней)
# = Rooted by VladiMIR | AI =
# =============================================================================
clear

C='\033[0;32m'; R='\033[0;31m'; Y='\033[1;33m'; B='\033[0;34m'; X='\033[0m'
SERVER_NAME=$(hostname)
REPORT_MSG="📊 SERVER: ${SERVER_NAME}\n---------------------------\n"
RENEW_THRESHOLD=15  # дней до истечения — порог для принудительного перевыпуска

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
            SSL_INFO="${R}🔴 SSL ИСТЁК!${X}"
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

    # Авторенью если <15 дней и домен зарегистрирован в acme.sh
    if [ -n "$DAYS_LEFT" ] && [ "$DAYS_LEFT" -le "$RENEW_THRESHOLD" ]; then
        ACME_DOMAIN=$(/.acme.sh/acme.sh --list 2>/dev/null | awk 'NR>1 {print $1}' | grep -x "$domain")
        if [ -n "$ACME_DOMAIN" ]; then
            echo -e "  ${Y}↪ Forcing renew for ${domain}...${X}"
            /.acme.sh/acme.sh --renew -d "$domain" -d "www.$domain" --force >> /var/log/acme-deploy.log 2>&1
            REPORT_MSG="${REPORT_MSG}  ↪ RENEW triggered: ${domain}\n"
        else
            echo -e "  ${R}⚠️  ${domain} не в acme.sh — нужна ручная регистрация (см. SSL_ACME_FASTPANEL_FIX.md)${X}"
            REPORT_MSG="${REPORT_MSG}  ⚠️ ${domain}: not in acme.sh — manual action needed\n"
        fi
    fi
done

echo "---------------------------"
echo -e "${C}Done!${X}"

[ -n "${TG_TOKEN:-}" ] && curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
  -d "chat_id=${TG_CHAT_ID}" \
  -d "text=$(echo -e "$REPORT_MSG")" > /dev/null
