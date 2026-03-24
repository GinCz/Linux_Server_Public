#!/usr/bin/env bash
clear
set -euo pipefail

# Version: v2026-03-12
# Description: Install CrowdSec, tighten WP rules, block XML-RPC globally

echo "--- 1. CROWDSEC & BOUNCER INSTALLATION ---"
curl -s https://packagecloud.io/install/repositories/crowdsec/crowdsec/script.deb.sh | bash
apt-get install -y crowdsec crowdsec-firewall-bouncer-iptables

echo "--- 2. WORDPRESS PROTECTION (5 ATTEMPTS) ---"
cscli collections install crowdsecurity/wordpress
find /etc/crowdsec/scenarios/ -name "*.yaml" -exec sed -i 's/capacity: [0-9]*/capacity: 5/g' {} \+ 2>/dev/null || true

echo "--- 3. WHITELISTING OWN IPs ---"
mkdir -p /etc/crowdsec/parsers/s02-enrich/
cat > /etc/crowdsec/parsers/s02-enrich/my_whitelist.yaml << 'EOF'
name: user/my_whitelist
description: "Whitelist for my servers"
whitelist:
  reason: "Own servers protection"
  ip:
    - "xxx.xxx.xxx.222"   # 222 DE NetCup
    - "xxx.xxx.xxx.109"  # 109 RU FastVDS
    - "5.101.114.114"    # 114 RU FastVPS
EOF

echo "--- 4. GLOBAL XML-RPC BLOCK (FASTPANEL) ---"
mkdir -p /etc/nginx/snippets
cat > /etc/nginx/snippets/block-xmlrpc-global.conf << 'EOF'
location = /xmlrpc.php {
    deny all;
    access_log off;
    log_not_found off;
}
EOF

for cfg in /etc/nginx/fastpanel2-sites/*/*.conf; do
    if [ -f "$cfg" ] && ! grep -q "block-xmlrpc-global.conf" "$cfg"; then
        sed -i '/server_name /a \    include /etc/nginx/snippets/block-xmlrpc-global.conf;' "$cfg"
    fi
done

echo "--- 5. RESTART & APPLY ---"
systemctl restart crowdsec
nginx -t && systemctl reload nginx
echo "✅ Done: CrowdSec active, XML-RPC blocked, whitelist set."
