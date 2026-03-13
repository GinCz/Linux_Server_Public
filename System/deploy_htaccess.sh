#!/usr/bin/env bash
# Universal .htaccess Deployer (Cloudflare & RU-VDS Ready)
# For Ing. VladiMIR Bulantsev | 2026
clear; C='\033[0;32m'; Y='\033[1;33m'; X='\033[0m'
echo -e "${Y}>>> Deploying Universal HTACCESS to all sites...${X}"

cat << 'HT' > /tmp/master_htaccess
# ✅ Optimized SEO & Security — 03/2026
# Works with Cloudflare and direct IP (RU/EU)

# 1. BLOCK AGGRESSIVE BOTS (CPU Protection)
<IfModule mod_setenvif.c>
    SetEnvIfNoCase User-Agent "AhrefsBot|SemrushBot|MJ12bot|DotBot|Rogerbot|Baiduspider" bad_bot
    <RequireAll>
        Require all granted
        Require not env bad_bot
    </RequireAll>
</IfModule>

# 2. SECURITY HEADERS
<IfModule mod_headers.c>
    Header set X-XSS-Protection "1; mode=block"
    Header set X-Content-Type-Options "nosniff"
    Header always set X-Frame-Options "SAMEORIGIN"
    # HSTS only for HTTPS (Safe for Cloudflare)
    Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains" env=HTTPS
</IfModule>

# 3. WORDPRESS / CORE REWRITES
<IfModule mod_rewrite.c>
    RewriteEngine On
    RewriteBase /
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    RewriteRule ^index\.php$ - [L]
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteRule . /index.php [L]
</IfModule>

# 4. EXPIRES (Speed Optimization)
<IfModule mod_expires.c>
    ExpiresActive On
    ExpiresDefault "access plus 1 month"
    ExpiresByType text/html "access plus 1 day"
    ExpiresByType image/webp "access plus 1 year"
    ExpiresByType image/jpeg "access plus 1 year"
    ExpiresByType text/css "access plus 6 months"
    ExpiresByType application/javascript "access plus 6 months"
</IfModule>

# 5. BLOCK SENSITIVE FILES
<FilesMatch "^(xmlrpc\.php|wp-config\.php|readme\.html|license\.txt|\.env|\.log|.*\.sh|.*\.sql)$">
    Require all denied
</FilesMatch>

Options -Indexes
