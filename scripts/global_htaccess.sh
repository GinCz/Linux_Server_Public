#!/usr/bin/env bash
# Description: Deploy strict SEO/Security .htaccess to all FastPanel sites.
# Alias: wpsec
H="/tmp/m_ht"; cat << 'HTEOF' > $H
<IfModule mod_setenvif.c>
SetEnvIfNoCase User-Agent "AhrefsBot|SemrushBot|MJ12bot|DotBot|Rogerbot|Baiduspider" bad_bot
<RequireAll>
Require all granted
Require not env bad_bot
</RequireAll>
</IfModule>
<IfModule mod_headers.c>
Header set X-XSS-Protection "1; mode=block"
Header set X-Content-Type-Options "nosniff"
Header always set X-Frame-Options "SAMEORIGIN"
</IfModule>
<FilesMatch "\.(env|log|sh|sql)$">
Require all denied
</FilesMatch>
Options -Indexes
HTEOF
for d in /var/www/*/data/www/*; do if [ -d "$d" ] && [ ! -L "$d" ]; then cp $H "$d/.htaccess"; chown $(stat -c '%U:%G' "$d") "$d/.htaccess"; chmod 644 "$d/.htaccess"; echo "Patched: $d"; fi; done; rm -f $H; echo "Global .htaccess applied."
