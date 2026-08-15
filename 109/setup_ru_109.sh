#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  setup_ru_109.sh | [v2026-05-01]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : RU Node (109) Security Setup (Samba, CrowdSec, FIGHT script, Telegram)
# Servers     : 109-RU FastVDS (212.109.223.109)
# Usage       : bash 109/setup_ru_109.sh
# ==========================================================================================

source /root/.server_env

echo "--- [002] Starting RU Node (109) HARD SECURITY Setup ---"

# 1. Base software packages
apt update -qq && apt install -y -qq fail2ban ipset acl samba >/dev/null

# 2. Configure users and Samba (passwords pulled from local .server_env)
groupadd -f storage
for u in vlad usr; do
    id -u "$u" &>/dev/null || useradd -m -s /bin/bash "$u"
    usermod -aG storage "$u"
done
echo -e "$SAMBA_PASS_VLAD\n$SAMBA_PASS_VLAD" | smbpasswd -a -s vlad
echo -e "$SAMBA_PASS_USR\n$SAMBA_PASS_USR" | smbpasswd -a -s usr

# 3. CrowdSec traffic security engine
curl -s https://install.crowdsec.net | sudo sh >/dev/null
apt install -y crowdsec crowdsec-firewall-bouncer-iptables >/dev/null
cscli collections install crowdsecurity/nginx crowdsecurity/wordpress crowdsecurity/http-cve >/dev/null
systemctl restart crowdsec

# 4. FIGHT script (Local aggressive attacker blocker)
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

# 5. Telegram Alert
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
     -d "chat_id=${TG_CHAT_ID}" \
     -d "text=🛡️ RU NODE (109) SECURED: $(hostname)%0A✅ CrowdSec Installed%0A✅ Samba Configured" >/dev/null

echo "✅ 109 Node Setup Finished!"
echo "========================================="

# = Rooted by VladiMIR | AI = v2026-05-01 = github.com/GinCz/Linux_Server_Public


