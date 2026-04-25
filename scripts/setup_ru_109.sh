#!/usr/bin/env bash
# English comments: RU Node (109) Security Setup. No hardcoded passwords.
# This script pulls SAMBA_PASS_VLAD, SAMBA_PASS_USR, TG_TOKEN from /root/.server_env

source /root/.server_env

echo "--- [002] Starting RU Node (109) HARD SECURITY Setup ---"

# 1. Базовый софт
apt update -qq && apt install -y -qq fail2ban ipset acl samba >/dev/null

# 2. Настройка пользователей и Samba (пароли берутся из локального .server_env)
groupadd -f storage
for u in vlad usr; do
    id -u "$u" &>/dev/null || useradd -m -s /bin/bash "$u"
    usermod -aG storage "$u"
done
echo -e "$SAMBA_PASS_VLAD\n$SAMBA_PASS_VLAD" | smbpasswd -a -s vlad
echo -e "$SAMBA_PASS_USR\n$SAMBA_PASS_USR" | smbpasswd -a -s usr

# 3. CrowdSec (Антивирус трафика)
curl -s https://install.crowdsec.net | sudo sh >/dev/null
apt install -y crowdsec crowdsec-firewall-bouncer-iptables >/dev/null
cscli collections install crowdsecurity/nginx crowdsecurity/wordpress crowdsecurity/http-cve >/dev/null
systemctl restart crowdsec

# 4. Скрипт FIGHT (Локальный блокировщик)
cat > /usr/local/bin/fight << 'INNER'
#!/usr/bin/env bash
LIMIT=800
LOG_GLOB="/var/www/*/data/logs/*access.log"
BAD_IPS=$(awk '{if($0~/xmlrpc\.php|wp-login\.php/) print $1}' $LOG_GLOB 2>/dev/null | sort | uniq -c | sort -nr | awk -v limit="$LIMIT" '$1>limit{print $2}')
for ip in $BAD_IPS; do
    iptables -C INPUT -s "$ip" -j DROP >/dev/null 2>&1 || { iptables -I INPUT -s "$ip" -j DROP; echo "Banned: $ip"; }
done
INNER
chmod +x /usr/local/bin/fight

# 5. Уведомление в Telegram
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
     -d "chat_id=${TG_CHAT_ID}" \
     -d "text=🛡️ RU NODE (109) SECURED: $(hostname)%0A✅ CrowdSec Installed%0A✅ Samba Configured" >/dev/null

echo "✅ 109 Node Setup Finished!"

echo "========================================="
echo "📘 HOW TO ADD USERS (READ THIS):"
echo "https://github.com/GinCz/Linux_Server_Public/tree/main/xray"
echo "========================================="

