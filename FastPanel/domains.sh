#!/usr/bin/env bash
# Domain Health Check to Telegram (Autonomous Version)
T="1226649515:AAEW2Vk2HSb_O693hhHfiHcPgfye4AcTURQ"; C="261784949"; S=$(hostname); clear; echo "Checking domains on $S..."
R="📊 SERVER: $S%0A---------------------------%0A"; D=$(grep -roP 'server_name \K[^; ]+' /etc/nginx/fastpanel2-sites/ /etc/nginx/fastpanel2-available/ /etc/nginx/sites-enabled/ 2>/dev/null | awk -F: '{print $2}' | awk '{print $1}' | sort -u | grep "\." | grep -v "localhost")
for d in $D; do st=$(curl -Lsk -o /dev/null -w "%{http_code}" --connect-timeout 5 "https://$d"); i="✅"; [ "$st" -ne 200 ] && i="⚠️"; [ "$st" -ge 400 ] && i="❌"; [ "$st" -eq 000 ] && st="OFF"; R+="$i $d | $st%0A"
if [ ${#R} -gt 3800 ]; then curl -s -X POST "https://api.telegram.org/bot$T/sendMessage" -d "chat_id=$C&text=$R" >/dev/null; R="📊 $S (cont...)%0A"; fi; done
curl -s -X POST "https://api.telegram.org/bot$T/sendMessage" -d "chat_id=$C&text=$R" >/dev/null; echo "Done. Report sent."
