#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  reset.sh | [v2026-04-01]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Reset CryptoBot container: stop, purge state/locks, restart
# Servers     : 222-DE NetCup (152.53.182.222)
# Usage       : bash 222/reset.sh
# ==========================================================================================

clear
echo "=== RESET BOT v2026-04-01 ==="

echo "[1] Stopping container..."
cd /root/crypto-docker
docker compose down
sleep 2

echo "[2] Clearing lock files..."
rm -f /root/crypto-docker/scripts/scanner.lock
rm -f /root/crypto-docker/scripts/paper_trade.lock

echo "[3] Resetting cooldown..."
echo '{}' > /root/crypto-docker/scripts/paper_cooldown.json

echo "[4] Resetting balance statistics..."
NOW=$(date '+%Y-%m-%d %H:%M:%S')
cat > /root/crypto-docker/scripts/paper_balance.json << BALANCE
{
  "balance": 1000.0,
  "start_balance": 1000.0,
  "positions": {},
  "closed_trades": [],
  "start_date": "$NOW"
}
BALANCE

echo "[5] Resetting lists..."
for i in 1 2 3 4 5; do
  echo '[]' > /root/crypto-docker/scripts/list_0${i}.py
done

echo "[6] Clearing logs..."
> /root/crypto-docker/logs/paper.log 2>/dev/null || true

echo "[7] Starting container..."
docker compose up -d
sleep 3

echo "[8] Restarting crypto-bot..."
docker restart crypto-bot
sleep 3

echo ""
echo "=== STATUS ==="
docker ps | grep crypto-bot
echo ""
docker logs crypto-bot --tail 10
echo "=== DONE ==="

# = Rooted by VladiMIR | AI = v2026-04-01 = github.com/GinCz/Linux_Server_Public

