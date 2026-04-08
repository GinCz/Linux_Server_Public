# CryptoBot — Логика торговли

> Version: v2026-04-08  
> Author: Ing. VladiΜIR Bulantsev  
> GitHub: https://github.com/GinCz/Linux_Server_Public  
> = Rooted by VladiΜIR | AI =

---

## Режимы (trade_mode в config.json)

| Параметр | trade60 (по умолчанию) | trade15 |
|---|---|---|
| `trade_mode` | `trade60` | `trade15` |

---

## Стратегия входа (BUY)

### trade60 — ОСНОВНОЙ режим

Все 4 фильтра должны пройти, чтобы открыть позицию:

1. **1h свеча** — рост за последний час `>= filter_growth_1h` (**1.0%**)  
   Смотрим последнюю закрытую 1h-свечу (предыдущую час). Если open→close < 1% — пропускаем.

2. **15m свеча** — рост за последние 15 минут `>= filter_growth_15m` (**1.0%**)  
   Смотрим последнюю закрытую 15m-свечу. Если < 1% — пропускаем.

3. **Live 1 минута** — 6 чеков каждые 10 секунд (итого 60 секунд):  
   - Общий рост за 1 минуту `>= filter_growth_1m` (**0.5%**)  
   - Минимум 4 из 6 тиков должны быть растущими

4. **Фильтры монеты:**  
   - Возраст листинга `>= filter_age_months` (**1 месяц**)  
   - Объём 24h `>= filter_volume_min_usd` (**100 000 USD**)

### trade15

То же самое, без шага 1h:

1. **15m свеча** `>= 1.0%`
2. **Live 1 минута** (6×10s, рост >= 0.5%, 4/6 растущих)
3. Фильтры возраста и объёма (те же)

---

## Стратегия выхода (SELL)

Только live-цена, свечи не используются:

| Условие | Значение | Параметр | Причина |
|---|---|---|---|
| Трейлинг: падение от пика | >= **0.5%** | `drop_from_peak` | `DROP_PEAK` |
| Жёсткий стоп: падение от входа | >= **1.0%** | `stop_loss` | `STOP_LOSS` |

Алгоритм trailing:
- Пик обновляется при каждом новом максимуме цены
- Как только цена упала на 0.5% от пика — продаём
- При срабатывании STOP_LOSS — cooldown 3600с

---

## Параметры config.json (актуальные)

```json
{
  "trade_mode":            "trade60",
  "filter_growth_1h":      1.0,
  "filter_growth_15m":     1.0,
  "filter_growth_1m":      0.5,
  "drop_from_peak":        0.5,
  "stop_loss":             1.0,
  "filter_age_months":     1,
  "filter_volume_min_usd": 100000,
  "monitor_interval_sec":  0.2,
  "scan_interval_sec":     60,
  "max_positions":         5,
  "position_size_pct":     20,
  "max_position_usd":      200,
  "min_balance":           100,
  "cooldown_sl_sec":       3600,
  "panic_mode":            false
}
```

---

## Структура файлов

```
crypto/
├── scripts/
│   ├── paper_trade.py      — главный движок: вход / выход / мониторинг
│   ├── list_05.py          — JSON-список кандидатов [«СИМВОЛ/USDT», ...]
│   ├── paper_balance.json  — Текущий баланс / позиции / сделки
│   └── paper_trades.log    — История BUY/SELL
├── templates/
│   └── index.html          — Web UI (дашборд)
├── app.py              — Flask-сервер (Web UI + API)
└── config.json         — Настройки (должен быть на сервере, не в репо)
```

---

## Управление ботом

```bash
# Статус / процессы
docker exec crypto-bot pgrep -a -f paper_trade.py

# Лог реального времени
docker exec crypto-bot tail -f /app/scripts/paper_trades.log

# Перезапустить бот
docker exec crypto-bot pkill -9 -f paper_trade.py
docker exec -d crypto-bot python3 /app/scripts/paper_trade.py

# Обновить код из репо (альяс save)
save
```

---

## Поток обновлений

После каждого изменения кода:
1. Файл заливается в репо `GinCz/Linux_Server_Public`
2. На сервере: `save` — скачивает свежую версию из репо
3. Перезапуск бота если изменился `paper_trade.py`
