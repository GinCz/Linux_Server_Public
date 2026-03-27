#!/bin/bash
# =============================================================
# ssl_fastpanel_v2026-03-27.sh
# Get SSL cert for sem.gincz.com using certbot standalone
# (NOT --nginx plugin, which is not installed in FASTPANEL)
# Server: xxx.xxx.xxx.222 | Ubuntu 24
# Version: v2026-03-27
# = Rooted by VladiMIR | AI =
# =============================================================

clear

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${GREEN}=== SSL for sem.gincz.com | v2026-03-27 ===${NC}"
echo "= Rooted by VladiMIR | AI ="
echo ""

[ "$(id -u)" -ne 0 ] && err "Run as root!"

DOMAIN="sem.gincz.com"
EMAIL="gin.vladimir@gmail.com"

# --- Check DNS resolves to our IP ---
RESOLVED_IP=$(dig +short "$DOMAIN" | tail -1)
OWN_IP="xxx.xxx.xxx.222"
if [ "$RESOLVED_IP" != "$OWN_IP" ]; then
    warn "DNS check: $DOMAIN resolves to $RESOLVED_IP (expected $OWN_IP)"
    warn "Make sure Cloudflare DNS is set to 'DNS Only' (grey cloud) for sem.gincz.com!"
    read -p "Continue anyway? [y/N]: " CONT
    [[ "$CONT" != "y" && "$CONT" != "Y" ]] && exit 1
else
    log "DNS OK: $DOMAIN -> $RESOLVED_IP"
fi

# --- Install certbot if needed ---
if ! command -v certbot &>/dev/null; then
    warn "Installing certbot..."
    apt-get install -y certbot
fi
log "Certbot: $(certbot --version 2>&1)"

# --- Method: webroot via FASTPANEL's existing HTTP vhost ---
# FASTPANEL already serves sem.gincz.com on port 80
# and includes /etc/nginx/fastpanel2-includes/*.conf which has letsencrypt.conf
# Webroot is the site's document root

WEBROOT="/var/www/gincz/data/www/sem.gincz.com"

if [ -d "$WEBROOT" ]; then
    log "Using webroot method: $WEBROOT"
    certbot certonly \
        --webroot \
        --webroot-path "$WEBROOT" \
        -d "$DOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive \
        --keep-until-expiring
else
    warn "Webroot $WEBROOT not found. Using standalone method..."
    warn "This will temporarily stop Nginx for 30 seconds!"
    read -p "Continue? [y/N]: " CONT2
    [[ "$CONT2" != "y" && "$CONT2" != "Y" ]] && exit 1

    systemctl stop nginx
    certbot certonly \
        --standalone \
        -d "$DOMAIN" \
        --email "$EMAIL" \
        --agree-tos \
        --non-interactive
    systemctl start nginx
fi

# --- Check cert was issued ---
CERT_PATH="/etc/letsencrypt/live/$DOMAIN/fullchain.pem"
if [ ! -f "$CERT_PATH" ]; then
    err "Certificate not found at $CERT_PATH"
fi
log "Certificate issued: $CERT_PATH"
certbot certificates -d "$DOMAIN" 2>/dev/null | grep -E "(Domains|Expiry|Certificate)"

echo ""
warn "Now go to FASTPANEL -> Sites -> sem.gincz.com -> SSL"
warn "Select: Custom certificate"
warn "Cert:   /etc/letsencrypt/live/$DOMAIN/fullchain.pem"
warn "Key:    /etc/letsencrypt/live/$DOMAIN/privkey.pem"
echo ""
log "Or run: bash /root/semaphore/apply_ssl_to_nginx_v2026-03-27.sh"
echo ""
