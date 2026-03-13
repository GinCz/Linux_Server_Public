#!/usr/bin/env bash
# Description: Global .htaccess deployment for FastPanel sites
# Version: 13/03/2026 | Cloudflare & RU-VDS Optimized
# Author: Ing. VladiMIR Bulantsev
clear; C='\033[0;32m'; Y='\033[1;33m'; X='\033[0m'
echo -e "${Y}>>> Deploying Universal HTACCESS to all sites...${X}"

# Create the master template in /tmp
cat << 'HT' > /tmp/master_htaccess
# ✅ Optimized SEO & Security — 13/03/2026
# Universal version for Ing. VladiMIR Bulantsev

<IfModule mod_setenvif.c>
    # Block aggressive SEO and scraping bots
    SetEnvIfNoCase User-Agent "AhrefsBot|SemrushBot|MJ12bot|DotBot|Rogerbot|Baiduspider" bad_bot
    <RequireAll>
        Require all granted
        Require not env bad_bot
    </RequireAll>
</IfModule>

<IfModule mod_headers.c>
    # Security Headers
    Header set X-XSS-Protection "1; mode=block"
    Header set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    # Enable HSTS only when HTTPS is active
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains" env=HTTPS
</IfModule>

<IfModule mod_rewrite.c>
    # Core WordPress & SEO Friendly Rules
    RewriteEngine On
    RewriteBase /
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    RewriteRule ^index\.php$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.php [L]
</IfModule>

<IfModule mod_expires.c>
    # Speed Optimization - Browser Caching
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
    ExpiresByType text/html "access plus 1 day"
    ExpiresByType image/webp "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType text/css "access plus 6 months"
    ExpiresByType application/javascript "access plus 6 months"
</IfModule>

<FilesMatch "^(xmlrpc\.php|wp-config\.php|readme\.html|license\.txt|\.env|\.log|.*\.sh|.*\.sql)$">
    # Block sensitive files and common attack targets
    Require all denied
</FilesMatch>

Options -Indexes
HT

# Iterate through FastPanel site directories
for site_dir in /var/www/*/data/www/*; do
    if [ -d "$site_dir" ] && [ ! -L "$site_dir" ]; then
        DOMAIN=$(basename "$site_dir")
        target="$site_dir/.htaccess"
        
        # Deploy template
        cp /tmp/master_htaccess "$target"
        
        # Apply correct ownership and permissions
        OWN_UID=$(stat -c '%u' "$site_dir")
        OWN_GID=$(stat -c '%g' "$site_dir")
        chown "$OWN_UID:$OWN_GID" "$target"
        chmod 644 "$target"
        
        echo -e "${C}Applied to:${X} $DOMAIN"
    fi
done

# Cleanup and Finish
rm -f /tmp/master_htaccess
echo -e "${Y}>>> System successfully updated to version 13/03/2026.${X}"
