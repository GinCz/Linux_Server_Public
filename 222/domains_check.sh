#!/usr/bin/env bash
clear
# Domain and SSL Expiry Check Script (v.12-03-2026)
source /root/.server_alliances.conf 2>/dev/null || true

TAG="${SERVER_TAG:-$(hostname)}"
REPORT="📊 *Domain & SSL Status: ${TAG}*%0A---------------------------%0A"

DOMAINS=$(grep -roP 'server_name \K[^; ]+' /etc/nginx/fastpanel2-sites/ /etc/nginx/fastpanel2-available/ 2>/dev/null | awk -F: '{print $2}' | awk '{print $1}' | sort -u | grep "\." | grep -v "localhost" || true)

for DOMAIN in $DOMAINS; do
    STATUS=$(curl -k -Ls -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://$DOMAIN" || echo "OFF")
    ICON="✅"
    [ "$STATUS" != "200" ] && ICON="❌"
    EXPIRY_DATE=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN":443 2>/dev/null | openssl x509 -noout -dates | grep notAfter | cut -d= -f2)
    if [ -n "$EXPIRY_DATE" ]; then
        EXPIRY_SS=$(date -d "$EXPIRY_DATE" +%s)
        NOW_SS=$(date +%s)
        DAYS_LEFT=$(( (EXPIRY_SS - NOW_SS) / 86400 ))
        SSL_INFO=" (SSL: ${DAYS_LEFT}d)"
        [ "$DAYS_LEFT" -lt 7 ] && SSL_INFO=" (⚠️ SSL EXPIRES: ${DAYS_LEFT}d)"
    else
        SSL_INFO=" (SSL: N/A)"
    fi
    REPORT+="${ICON} ${DOMAIN} | ${STATUS}${SSL_INFO}%0A"
done

if [ -n "${TG_TOKEN:-}" ]; then
    curl -s -X POST "https://api.telegram.org/bot$TG_TOKEN/sendMessage" \
    -d "chat_id=$TG_CHAT_ID&text=$REPORT&parse_mode=Markdown" >/dev/null 2>&1
fi
echo "SSL & Domain check complete."
