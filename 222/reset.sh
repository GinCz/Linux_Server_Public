#!/bin/bash
# Script:  reset.sh
# Version: v2026-04-01
# Purpose: Reset bot: stop -> clear all data inside container -> restart
# = Rooted by VladiMIR | AI =

clear
echo "=== RESET BOT v2026-04-01 ==="

echo "[1] Останавливаем контейнер..."
cd /root/crypto-docker
docker compose down
sleep 2

echo "[2] Очищаем lock файлы..."
rm -f /root/crypto-docker/scripts/scanner.lock
rm -f /root/crypto-docker/scripts/paper_trade.lock

echo "[3] Сбрасываем cooldown..."
echo '{}' > /root/crypto-docker/scripts/paper_cooldown.json

echo "[4] Сбрасываем статистику..."
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

echo "[5] Очищаем lists..."
for i in 1 2 3 4 5; do
  echo '[]' > /root/crypto-docker/scripts/list_0${i}.py
done

echo "[6] Очищаем логи..."
> /root/crypto-docker/logs/paper.log 2>/dev/null || true

echo "[7] Запускаем контейнер..."
docker compose up -d
sleep 3

echo "[8] Перезапускаем crypto-bot..."
docker restart crypto-bot
sleep 3

echo ""
echo "=== СТАТУС ==="
docker ps | grep crypto-bot
echo ""
docker logs crypto-bot --tail 10
echo "=== ГОТОВО ==="
