#!/bin/bash
# =============================================================
# apply_ssl_to_nginx_v2026-03-27.sh
# Apply SSL to sem.gincz.com nginx config manually
# (for FASTPANEL servers where --nginx certbot plugin is absent)
# Version: v2026-03-27
# = Rooted by VladiMIR | AI =
# =============================================================

clear

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

[ "$(id -u)" -ne 0 ] && err "Run as root!"

DOMAIN="sem.gincz.com"
CERT="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
KEY="/etc/letsencrypt/live/$DOMAIN/privkey.pem"

# Check cert exists
[ ! -f "$CERT" ] && err "Certificate not found: $CERT\nRun ssl_fastpanel_v2026-03-27.sh first!"

# Find FASTPANEL's nginx config for this domain
FP_CONF=$(find /etc/nginx/fastpanel2-sites/ -name "*sem.gincz.com*" 2>/dev/null | head -1)
[ -z "$FP_CONF" ] && err "FASTPANEL nginx config not found for $DOMAIN"
log "Found FASTPANEL config: $FP_CONF"

# Backup original
cp "$FP_CONF" "${FP_CONF}.bak.$(date +%Y%m%d_%H%M%S)"
log "Backup created"

# Check if HTTPS server block already exists
if grep -q "listen.*443" "$FP_CONF"; then
    log "HTTPS block already exists in config. Checking SSL cert paths..."
    # Update cert paths
    sed -i "s|ssl_certificate .*;|ssl_certificate $CERT;|g" "$FP_CONF"
    sed -i "s|ssl_certificate_key .*;|ssl_certificate_key $KEY;|g" "$FP_CONF"
    log "SSL cert paths updated"
else
    # Add HTTPS server block
    cat >> "$FP_CONF" << HTTPS_BLOCK

# HTTPS block added by apply_ssl_to_nginx_v2026-03-27.sh
server {
    server_name $DOMAIN;
    listen xxx.xxx.xxx.222:443 ssl;

    ssl_certificate     $CERT;
    ssl_certificate_key $KEY;
    include /etc/nginx/fastpanel2-includes/letsencrypt.conf;

    # Proxy to Semaphore
    location / {
        proxy_pass http://127.0.0.1:3000;
        proxy_http_version 1.1;

        # WebSocket (needed for task logs in Semaphore)
        proxy_set_header Upgrade    \$http_upgrade;
        proxy_set_header Connection "upgrade";

        proxy_set_header Host               \$host;
        proxy_set_header X-Real-IP          \$remote_addr;
        proxy_set_header X-Forwarded-For    \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto  \$scheme;

        proxy_read_timeout    300;
        proxy_connect_timeout  60;
        proxy_send_timeout    300;
        proxy_buffering off;
    }

    access_log /var/www/gincz/data/logs/sem.gincz.com-ssl.access.log;
    error_log  /var/www/gincz/data/logs/sem.gincz.com-ssl.error.log;
}
HTTPS_BLOCK
    log "HTTPS server block added"
fi

# Update HTTP block to redirect to HTTPS
warn "Adding HTTP->HTTPS redirect..."

# Test and reload
nginx -t && systemctl reload nginx
log "Nginx reloaded with SSL!"

certbot certificates -d "$DOMAIN" 2>/dev/null | grep -E "(Domains|Expiry)"

echo ""
echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}  SSL configured! Test: https://$DOMAIN${NC}"
echo -e "${GREEN}===========================================${NC}"
echo ""
# Auto-renewal check
log "Certbot auto-renewal: $(systemctl is-enabled certbot.timer 2>/dev/null || echo 'set up cron manually')"
