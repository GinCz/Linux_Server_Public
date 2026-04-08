# CryptoBot — Trade60 / Trade15

> Version: v2026-04-08  
> Author: Ing. VladiMIR Bulantsev  
> = Rooted by VladiMIR | AI =

---

## Overview

Two trading strategy modes, switchable via web UI or `config.json`:

| Mode | Filters | Use case |
|------|---------|----------|
| **Trade60** | 1h candle UP + 15m candle UP + 6× live checks | Stable growth, less noise |
| **Trade15** | 15m candle UP + 6× live checks | Fast pumps, quick scalp |

**Exit (both modes):** live price only — no candles.

---

## Entry Logic

### Trade60
```
1. Last 1h candle closed UP (>= filter_growth_1h, default 0.5%)
2. Last 15m candle closed UP (>= filter_growth_15m, default 1.0%)
3. 6 × live price checks every 10 seconds
   → at least 4 of 6 must be RISING → BUY
```

### Trade15
```
1. Last 15m candle closed UP (>= filter_growth_15m, default 1.0%)
2. 6 × live price checks every 10 seconds
   → at least 4 of 6 must be RISING → BUY
```

---

## Exit Logic (same for both modes)

```
Price polling every monitor_interval_sec (default 5s)

IF current_price dropped >= drop_from_peak % from local_peak:
    SELL → reason: DROP_PEAK

IF current_price dropped >= stop_loss % from entry_price:
    SELL → reason: STOP_LOSS → cooldown_sl_sec (default 3600s)
```

> Default `drop_from_peak = 0.5%`  
> Default `stop_loss = 1.0%`

---

## Switch mode via API

```bash
# Set Trade60
curl -s -X POST http://localhost:5000/api/set_trade_mode \
  -H 'Content-Type: application/json' \
  -d '{"mode": "trade60"}' -b 'session=...'

# Set Trade15
curl -s -X POST http://localhost:5000/api/set_trade_mode \
  -H 'Content-Type: application/json' \
  -d '{"mode": "trade15"}' -b 'session=...'
```

---

## config.json keys added

```json
{
  "trade_mode":       "trade60",
  "drop_from_peak":   0.5,
  "filter_growth_1h": 0.5,
  "live_checks":      6,
  "live_interval_sec": 10
}
```

---

## Files

```
scripts/paper_trade.py          ← main bot engine (Trade60 + Trade15)
app.py                          ← add /api/set_trade_mode route (see patch file)
templates/index.html            ← add switcher snippet
crypto/app_patch_trade_mode.py  ← patch instructions for app.py
crypto/templates/index_trade_mode_snippet.html  ← UI switcher HTML+JS
crypto/config_trade_modes.json  ← reference config
crypto/README_TRADE_MODES.md    ← this file
```

---

## Deploy

```bash
# 1. Copy new paper_trade.py into container
docker cp /path/to/paper_trade.py crypto-bot:/app/scripts/paper_trade.py

# 2. Restart bot via web UI — or:
docker exec crypto-bot pkill -f paper_trade.py
docker exec crypto-bot python3 /app/scripts/paper_trade.py &

# 3. Add route to app.py (see app_patch_trade_mode.py)
# 4. Add switcher to templates/index.html (see index_trade_mode_snippet.html)
# 5. Rebuild container:
cd /root/crypto-docker && docker-compose up -d --build
```
