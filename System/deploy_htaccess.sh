#!/usr/bin/env bash
# Universal .htaccess Deployer (Cloudflare & RU-VDS Ready)
# For Ing. VladiMIR Bulantsev | 2026
clear; C='\033[0;32m'; Y='\033[1;33m'; X='\033[0m'
echo -e "${Y}>>> Deploying Universal HTACCESS to all sites...${X}"

# Create the Master Template
cat << 'HT' > /tmp/master_htaccess
# ✅ Optimized SEO & Security — 03/2026
# Works with Cloudflare and direct IP (RU/EU)

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
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains" env=HTTPS
</IfModule>

<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    RewriteRule ^index\.php$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.php [L]
</IfModule>

<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
    ExpiresByType text/html "access plus 1 day"
    ExpiresByType image/webp "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType text/css "access plus 6 months"
    ExpiresByType application/javascript "access plus 6 months"
</IfModule>

<FilesMatch "^(xmlrpc\.php|wp-config\.php|readme\.html|license\.txt|\.env|\.log|.*\.sh|.*\.sql)$">
    Require all denied
</FilesMatch>

Options -Indexes
HT

# Deploy to all directories
for site_dir in /var/www/*/data/www/*; do
    if [ -d "$site_dir" ] && [ ! -L "$site_dir" ]; then
        target="$site_dir/.htaccess"
        cp /tmp/master_htaccess "$target"
        OWN_UID=$(stat -c '%u' "$site_dir")
        OWN_GID=$(stat -c '%g' "$site_dir")
        chown "$OWN_UID:$OWN_GID" "$target"
        chmod 644 "$target"
        echo -e "${C}Success:${X} $target"
    fi
done

rm -f /tmp/master_htaccess
echo -e "${C}Global protection active!${X}"
