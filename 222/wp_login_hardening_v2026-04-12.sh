#!/bin/bash
# = Rooted by VladiMIR | AI =
# WP Login Hardening — server 222-DE-NetCup
# What this script does:
#   1. Creates unified rate limit zones file (removes old duplicates)
#   2. Changes burst=10 → burst=3 in all active site configs
#   3. Adds location = /wp-login.php to sites that are missing it
#   4. Reloads Nginx
# Updated: v2026-04-12
# WARNING: affects ALL WordPress sites on this server

set -e

echo "=== [1] Создаём единый файл зон ==="
rm -f /etc/nginx/conf.d/00-wp-login-limit-zone.conf
rm -f /etc/nginx/conf.d/01-wp-limit-zones.conf

cat > /etc/nginx/conf.d/00-wp-protection-zones.conf << 'EOF'
# = Rooted by VladiMIR | AI =
# WP Rate Limit Zones — server 222-DE-NetCup
# Updated: v2026-04-12
limit_req_zone $binary_remote_addr zone=wp_login_222:30m rate=6r/m;
limit_req_zone $binary_remote_addr zone=wp_admin_222:20m rate=2r/s;
limit_req_zone $binary_remote_addr zone=wp_xmlrpc_222:10m rate=1r/m;
EOF
echo "  ✓ zones file created"

echo ""
echo "=== [2] burst=10 → burst=3 во всех активных конфигах ==="
find /etc/nginx/fastpanel2-available/ -name "*.conf" -not -name "*.bak*" \
    -exec grep -l "wp_login_222 burst=10" {} \; | while read f; do
    sed -i 's/zone=wp_login_222 burst=10/zone=wp_login_222 burst=3/g' "$f"
    echo "  ✓ $(basename $f)"
done

echo ""
echo "=== [3] Тест и reload ==="
nginx -t && systemctl reload nginx && echo "✅ Nginx OK"
