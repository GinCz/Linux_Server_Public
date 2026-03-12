#!/usr/bin/env bash
clear
# English comments: High-speed Domain Monitoring Script (v. 12-03-2026)
# Features: Strict deduplication, skips WWW, IPv4 only for speed.
# Compatibility: FastPanel (Ubuntu/Debian)

# 1. Load sensitive data from local environment
source /root/.server_env 2>/dev/null || true

# Fallback values if config is missing
TOKEN="${TG_TOKEN:-1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ}"
CHAT_ID="${TG_CHAT_ID:-261784949}"
SERVER_NAME=$(hostname)

REPORT="📊 SERVER: $SERVER_NAME%0A---------------------------%0A"

# 2. Collect unique root domains (Removes WWW and duplicates)
DOMAINS=$(grep -roP 'server_name \K[^; ]+' /etc/nginx/fastpanel2-sites/ /etc/nginx/fastpanel2-available/ 2>/dev/null | \
          awk -F: '{print $2}' | tr ' ' '\n' | \
          sed 's/^www\.//' | grep "\." | grep -v "localhost" | \
          sort -u)

echo "🚀 Starting High-Speed Check for $SERVER_NAME..."

# 3. Fast HTTP Check Loop
for DOMAIN in $DOMAINS; do
    echo -n "Check: $DOMAIN... "
    # -4: IPv4 only, -Ls: Follow redirects, --connect-timeout: prevent hanging
    STATUS=$(curl -4 -Ls -o /dev/null -w "%{http_code}" --connect-timeout 2 "https://$DOMAIN" 2>/dev/null || echo "000")
    
    ICON="✅"
    [ "$STATUS" -ne 200 ] && ICON="❌"
    [ "$STATUS" -eq 000 ] && STATUS="OFF"
    
    echo "$STATUS"
    REPORT+="$ICON $DOMAIN | $STATUS%0A"
    
    # 4. Handle Telegram message length limit (4096 chars)
    if [ ${#REPORT} -gt 3500 ]; then
        curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$REPORT" > /dev/null
        REPORT="📊 $SERVER_NAME (continued)%0A---------------------------%0A"
    fi
done

# 5. Send final report
curl -s -X POST "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$REPORT" > /dev/null
echo "✅ Done! Clean report sent to Telegram."
