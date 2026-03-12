#!/usr/bin/env bash
# English comments: RU Node Setup (v2.0) - Hard Security & FastPanel Tuning
source /root/.server_env

echo "--- [002] Starting RU Node (109) HARD SECURITY Setup ---"

# 1. Инсталляция базовой защиты (Fail2Ban + IPSet)
apt update -qq && apt install -y -qq fail2ban ipset acl >/dev/null

# 2. Установка CROWDSEC (Антивирус для трафика)
echo "Installing CrowdSec..."
curl -s https://install.crowdsec.net | sudo sh >/dev/null
apt install -y crowdsec crowdsec-firewall-bouncer-iptables >/dev/null
# Установка коллекций для защиты Nginx и WordPress
cscli collections install crowdsecurity/nginx crowdsecurity/wordpress crowdsecurity/http-cve >/dev/null
systemctl restart crowdsec

# 3. Установка скрипта FIGHT (Блокировщик ботов по логам)
echo "Installing FIGHT script..."
cat > /usr/local/bin/fight << 'INNER'
#!/usr/bin/env bash
# Scans logs for WP attacks and bans IPs in IPTables
LIMIT=800
LOG_GLOB="/var/www/*/data/logs/*access.log"
BAD_IPS=$(awk '{if($0~/xmlrpc\.php|wp-login\.php/) print $1}' $LOG_GLOB 2>/dev/null | sort | uniq -c | sort -nr | awk -v limit="$LIMIT" '$1>limit{print $2}')
for ip in $BAD_IPS; do
    iptables -C INPUT -s "$ip" -j DROP >/dev/null 2>&1 || { iptables -I INPUT -s "$ip" -j DROP; echo "Banned: $ip"; }
done
INNER
chmod +x /usr/local/bin/fight
# Крон для FIGHT (каждый вечер в 21:00)
(crontab -l 2>/dev/null | grep -v "/usr/local/bin/fight" ; echo "0 21 * * * /usr/local/bin/fight > /dev/null 2>&1") | crontab -

# 4. Оптимизация PHP-FPM (Max Performance)
echo "Tuning PHP-FPM Performance..."
find /etc/php/*/fpm/pool.d/ -name "*.conf" -exec sed -i 's/^pm.max_children =.*/pm.max_children = 20/' {} \;
find /etc/php/*/fpm/pool.d/ -name "*.conf" -exec sed -i 's/^pm.process_idle_timeout =.*/pm.process_idle_timeout = 20s/' {} \;
ls /etc/php/ -1 2>/dev/null | xargs -I {} systemctl restart php{}-fpm 2>/dev/null || true

# 5. Telegram Alert
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
     -d "chat_id=${TG_CHAT_ID}" \
     -d "text=🛡️ RU NODE READY (109): $(hostname)%0A🔥 CrowdSec: Installed%0A👊 FIGHT Script: Active%0A⚡ PHP-FPM: Optimized" >/dev/null

echo "✅ RU Node Setup Finished! CrowdSec is now hunting."
