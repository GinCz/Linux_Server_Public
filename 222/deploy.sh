#!/bin/bash
# Script:  deploy.sh
# Version: v2026-03-25
# Purpose: Full deploy crypto-bot in Docker on 222-DE-NetCup
#          IP: xxx.xxx.xxx.222 | Domain: crypto.gincz.com
# = Rooted by VladiMIR | AI =

clear
set -e

DOCKER_DIR="/root/crypto-docker"
DOMAIN="crypto.gincz.com"

echo "================================================="
echo " CRYPTO BOT - DEPLOY v2026-03-25 (Docker)"
echo "================================================="

# --- 1. Dependencies ---
echo "[1/5] Installing dependencies..."
apt-get install -y docker.io docker-compose-plugin nginx certbot python3-certbot-nginx mc -q 2>/dev/null || true
echo "OK"

# --- 2. Docker build & start ---
echo "[2/5] Building and starting Docker container..."
cd "$DOCKER_DIR"
docker compose down 2>/dev/null || true
docker compose build --no-cache
docker compose up -d
sleep 5
if docker ps | grep -q crypto-bot; then
    echo "OK: crypto-bot running"
else
    echo "ERROR: container failed!"
    docker logs crypto-bot --tail 20
    exit 1
fi

# --- 3. NGINX ---
echo "[3/5] Setting up nginx..."
cp "$DOCKER_DIR/scripts/nginx-crypto.conf" /etc/nginx/sites-available/crypto
ln -sf /etc/nginx/sites-available/crypto /etc/nginx/sites-enabled/crypto
nginx -t && systemctl reload nginx
echo "OK"

# --- 4. SSL ---
echo "[4/5] SSL certificate ($DOMAIN)..."
if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
    echo "OK: SSL already exists"
else
    certbot --nginx -d $DOMAIN --non-interactive --agree-tos -m gin@volny.cz
fi

# --- 5. Aliases ---
echo "[5/5] Aliases..."
source ~/.bashrc
echo "OK: bot reset torg torg1/3/24/120 clog clog100"

echo "================================================="
echo " DEPLOY COMPLETE!"
echo " URL:   https://$DOMAIN"
echo " Cmds:  bot | reset | torg | torg1/3/24/120 | clog"
echo "================================================="
