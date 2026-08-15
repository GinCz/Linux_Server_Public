#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  setup.sh | [v2026-03-14]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : VPN Node Setup (Samba users, Docker log cleanup cron, Security, Telegram)
# Servers     : VPN nodes (Amnezia / XRAY / Samba)
# Usage       : bash scripts/setup.sh
# ==========================================================================================

source /root/.server_env

echo "--- [003] Starting VPN Node Configuration ---"

# 1. Install software packages
apt update -qq && apt install -y -qq samba fail2ban acl >/dev/null

# 2. Configure Samba users and permissions
groupadd -f storage
for u in vlad usr; do
    id -u "$u" &>/dev/null || useradd -m -s /bin/bash "$u"
    usermod -aG storage "$u"
done

# Passwords from local .server_env
(echo "$SAMBA_PASS_VLAD"; echo "$SAMBA_PASS_VLAD") | smbpasswd -a -s vlad
(echo "$SAMBA_PASS_USR"; echo "$SAMBA_PASS_USR") | smbpasswd -a -s usr

# 3. Disk optimization (Docker log cleanup)
cat > /usr/local/bin/docker_clean_logs.sh << 'INNER'
#!/usr/bin/env bash
find /var/lib/docker/containers/ -name "*.log" -exec truncate -s 0 {} \;
INNER
chmod +x /usr/local/bin/docker_clean_logs.sh

# Register weekly cron job
(crontab -l 2>/dev/null | grep -v "docker_clean_logs.sh" ; echo "30 3 * * 0 /usr/local/bin/docker_clean_logs.sh > /dev/null 2>&1") | crontab -

# 4. Telegram Alert
curl -s -X POST "https://api.telegram.org/bot${TG_TOKEN}/sendMessage" \
     -d "chat_id=${TG_CHAT_ID}" \
     -d "text=✅ VPN NODE READY: $(hostname)%0A🛡️ Fail2ban: Active%0A📂 Samba: Configured" >/dev/null

echo "✅ VPN Node Setup Finished!"
echo "========================================="

# = Rooted by VladiMIR | AI = v2026-03-14 = github.com/GinCz/Linux_Server_Public


