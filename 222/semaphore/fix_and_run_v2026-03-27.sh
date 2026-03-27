#!/bin/bash
# =============================================================
# fix_and_run_v2026-03-27.sh
# Fix: docker-compose-plugin + start Semaphore container
# Server: xxx.xxx.xxx.222 (NetCup DE, Ubuntu 24)
# Version: v2026-03-27
# = Rooted by VladiMIR | AI =
# =============================================================

clear

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
log()  { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo -e "${GREEN}=== Semaphore: Fix & Run | v2026-03-27 ===${NC}"
echo "= Rooted by VladiMIR | AI ="
echo ""

[ "$(id -u)" -ne 0 ] && err "Run as root!"

# --- Fix 1: Install docker-compose-plugin the correct way ---
warn "Installing docker-compose-plugin via official Docker repo..."

# Add Docker's official GPG key and repo (if not already done)
if [ ! -f /etc/apt/keyrings/docker.gpg ]; then
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
        gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    chmod a+r /etc/apt/keyrings/docker.gpg
fi

# Add Docker repo
if [ ! -f /etc/apt/sources.list.d/docker.list ]; then
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
      https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      tee /etc/apt/sources.list.d/docker.list > /dev/null
fi

apt-get update -qq
apt-get install -y docker-compose-plugin
log "docker-compose-plugin installed: $(docker compose version)"

# --- Verify Docker is running ---
if ! systemctl is-active --quiet docker; then
    systemctl start docker
fi
log "Docker running: $(docker --version)"

# --- Working directory ---
WORKDIR="/root/semaphore"
mkdir -p "$WORKDIR"
cd "$WORKDIR"
log "Working dir: $WORKDIR"

# --- Generate encryption key ---
ENCRYPTION_KEY=$(openssl rand -base64 32)
log "Encryption key generated"

# --- Create docker-compose.yml ---
cat > "$WORKDIR/docker-compose.yml" << COMPOSE
# docker-compose.yml - Semaphore on 222-DE-NetCup
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
      SEMAPHORE_DB_DIALECT:            bolt
      SEMAPHORE_DB:                    /var/lib/semaphore/database.boltdb
      SEMAPHORE_ADMIN:                 admin
      SEMAPHORE_ADMIN_PASSWORD:        "***REMOVED***"
      SEMAPHORE_ADMIN_NAME:            "VladiMIR"
      SEMAPHORE_ADMIN_EMAIL:           gin.vladimir@gmail.com
      SEMAPHORE_ACCESS_KEY_ENCRYPTION: "${ENCRYPTION_KEY}"
      SEMAPHORE_PLAYBOOK_PATH:         /tmp/semaphore
      SEMAPHORE_PORT:                  ":3000"
      TZ:                              "Europe/Prague"
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

# --- Pull and start ---
warn "Pulling Semaphore image (semaphoreui/semaphore:latest)..."
docker compose pull

warn "Starting container..."
docker compose up -d

# --- Wait for ready ---
echo -n "Waiting for Semaphore to respond on port 3000"
for i in $(seq 1 20); do
    sleep 2
    if curl -s http://127.0.0.1:3000 > /dev/null 2>&1; then
        echo -e " ${GREEN}OK${NC}"
        break
    fi
    echo -n "."
done
echo ""

# --- Status ---
docker ps --filter "name=semaphore" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"

# --- Memory usage ---
log "Memory usage:"
docker stats semaphore --no-stream --format "  Container: {{.Name}} | CPU: {{.CPUPerc}} | RAM: {{.MemUsage}}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Semaphore container is RUNNING!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo "  Local test:  curl -I http://127.0.0.1:3000"
echo "  Logs:        docker compose -f $WORKDIR/docker-compose.yml logs -f"
echo ""
warn "Next step: configure SSL in FASTPANEL (see README)"
echo ""
