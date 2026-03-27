#!/bin/bash
# =============================================================
# install_semaphore_v2026-03-27.sh
# Semaphore (Ansible UI) — Docker install on server 222
# Server: xxx.xxx.xxx.222 (NetCup DE, Ubuntu 24, FASTPANEL)
# Domain: sem.gincz.com
# Version: v2026-03-27
# = Rooted by VladiMIR | AI =
# =============================================================

clear

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${GREEN}"
echo "  ███████╗███████╗███╗   ███╗ █████╗ ██████╗ ██╗  ██╗ ██████╗ ██████╗ ███████╗"
echo "  ██╔════╝██╔════╝████╗ ████║██╔══██╗██╔══██╗██║  ██║██╔═══██╗██╔══██╗██╔════╝"
echo "  ███████╗█████╗  ██╔████╔██║███████║██████╔╝███████║██║   ██║██████╔╝█████╗  "
echo "  ╚════██║██╔══╝  ██║╚██╔╝██║██╔══██║██╔═══╝ ██╔══██║██║   ██║██╔══██╗██╔══╝  "
echo "  ███████║███████╗██║ ╚═╝ ██║██║  ██║██║     ██║  ██║╚██████╔╝██║  ██║███████╗"
echo "  ╚══════╝╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝"
echo -e "${NC}"
echo "  Ansible UI — Docker install | sem.gincz.com | v2026-03-27"
echo "  = Rooted by VladiMIR | AI ="
echo "  ─────────────────────────────────────────────────────────"
echo ""

# --- Check root ---
[ "$(id -u)" -ne 0 ] && err "Run as root!"

# --- Check Docker ---
if ! command -v docker &>/dev/null; then
    warn "Docker not found. Installing..."
    curl -fsSL https://get.docker.com | bash
    systemctl enable --now docker
    log "Docker installed"
else
    log "Docker: $(docker --version)"
fi

# --- Check Docker Compose ---
if ! docker compose version &>/dev/null 2>&1; then
    warn "Docker Compose plugin not found. Installing..."
    apt-get install -y docker-compose-plugin
else
    log "Docker Compose: $(docker compose version)"
fi

# --- Create working directory ---
WORKDIR="/root/semaphore"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
log "Working directory: $WORKDIR"

# --- Generate encryption key (random, unique per install) ---
ENCRYPTION_KEY=$(openssl rand -base64 32)
log "Encryption key generated"

# --- Create docker-compose.yml ---
cat > "$WORKDIR/docker-compose.yml" << COMPOSE
# docker-compose.yml — Semaphore on 222-DE-NetCup
# Version: v2026-03-27
# = Rooted by VladiMIR | AI =

version: '3.8'

services:
  semaphore:
    image: semaphoreui/semaphore:latest
    container_name: semaphore
    restart: unless-stopped
    ports:
      - "127.0.0.1:3000:3000"
    environment:
      SEMAPHORE_DB_DIALECT:             bolt
      SEMAPHORE_DB:                     /var/lib/semaphore/database.boltdb
      SEMAPHORE_ADMIN:                  admin
      SEMAPHORE_ADMIN_PASSWORD:         "***REMOVED***"
      SEMAPHORE_ADMIN_NAME:             "VladiMIR"
      SEMAPHORE_ADMIN_EMAIL:            gin.vladimir@gmail.com
      SEMAPHORE_ACCESS_KEY_ENCRYPTION:  "${ENCRYPTION_KEY}"
      SEMAPHORE_PLAYBOOK_PATH:          /tmp/semaphore
      SEMAPHORE_PORT:                   ":3000"
      TZ:                               "Europe/Prague"
    volumes:
      - semaphore_data:/var/lib/semaphore
      - semaphore_config:/etc/semaphore
      - semaphore_tmp:/tmp/semaphore
    mem_limit: 512m
    mem_reservation: 128m
    cpus: 0.5

volumes:
  semaphore_data:
    driver: local
  semaphore_config:
    driver: local
  semaphore_tmp:
    driver: local
COMPOSE

log "docker-compose.yml created"

# --- Pull image and start container ---
log "Pulling Semaphore image..."
docker compose pull

log "Starting Semaphore container..."
docker compose up -d

# --- Wait for container to start ---
echo -n "Waiting for Semaphore to start"
for i in $(seq 1 15); do
    sleep 2
    if curl -s http://127.0.0.1:3000 > /dev/null 2>&1; then
        echo " OK"
        break
    fi
    echo -n "."
done
echo ""

# --- Container status ---
log "Container status:"
docker ps --filter "name=semaphore" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

# --- Nginx config ---
NGINX_CONF="/etc/nginx/sites-available/sem.gincz.com.conf"

cat > "$NGINX_CONF" << 'NGINX'
# sem.gincz.com.conf — Nginx reverse proxy for Semaphore
# Version: v2026-03-27
# = Rooted by VladiMIR | AI =

server {
    server_name sem.gincz.com;
    listen xxx.xxx.xxx.222:80;
    include /etc/nginx/fastpanel2-includes/letsencrypt.conf;
    location / {
        return 301 https://$host$request_uri;
    }
    error_log /dev/null crit;
    access_log off;
}
NGINX

# --- Enable site ---
if [ -d /etc/nginx/sites-enabled ]; then
    ln -sf "$NGINX_CONF" /etc/nginx/sites-enabled/sem.gincz.com.conf
fi

# --- Test Nginx config ---
nginx -t && systemctl reload nginx
log "Nginx config reloaded"

# --- Issue SSL with Certbot ---
warn "Now run Certbot to get SSL certificate:"
echo ""
echo "  certbot --nginx -d sem.gincz.com --email gin.vladimir@gmail.com --agree-tos --non-interactive"
echo ""
echo "  Or with FASTPANEL: add domain sem.gincz.com and enable SSL there"
echo ""

# --- Summary ---
echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Semaphore installed successfully!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "  🌐 URL (after SSL):    https://sem.gincz.com"
echo "  🌐 Local access:       http://127.0.0.1:3000"
echo "  👤 Login:              admin"
echo "  🔑 Password:           ***REMOVED***  ← CHANGE IT!"
echo "  📁 Working dir:        $WORKDIR"
echo "  🐳 Container:          semaphore"
echo ""
echo "  Management commands:"
echo "  docker compose -f $WORKDIR/docker-compose.yml ps"
echo "  docker compose -f $WORKDIR/docker-compose.yml logs -f"
echo "  docker compose -f $WORKDIR/docker-compose.yml restart"
echo "  docker compose -f $WORKDIR/docker-compose.yml down"
echo ""
echo -e "${YELLOW}  ⚠️  Change default password after first login!${NC}"
echo ""
