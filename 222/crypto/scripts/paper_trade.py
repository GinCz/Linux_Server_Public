#!/usr/bin/env python3
# =============================================================================
# paper_trade.py — CryptoBot Trade60 / Trade15 engine
# Version  : v2026-04-08b
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
# = Rooted by VladiMIR | AI =
# =============================================================================
#
# STRATEGY TRADE60 (default):
#   1. Last 1h candle UP >= filter_growth_1h  (default 1.0%)   — свечи
#   2. Last 15m candle UP >= filter_growth_15m (default 1.0%)  — свечи
#   3. Live checks 6x every 10s (1 minute total):
#        growth over 1 minute >= filter_growth_1m (default 0.5%)
#        AND at least 4/6 ticks rising
#   4. Symbol age >= 1 month (filter_age_months)
#   5. 24h volume >= filter_volume_min_usd (default 100_000 USD)
#
# STRATEGY TRADE15:
#   1. Last 15m candle UP >= filter_growth_15m (default 1.0%)  — свечи
#   2. Live checks 6x every 10s (same as Trade60)
#   3. Same age + volume filters
#
# EXIT (both modes — live price only, no candles):
#   Trailing: price drops >= drop_from_peak% from local peak  → SELL DROP_PEAK
#   Hard SL:  price drops >= stop_loss% from entry            → SELL STOP_LOSS
#
# DEFAULT CONFIG VALUES (config.json):
#   filter_growth_1h      : 1.0   (1h candle min growth %)
#   filter_growth_15m     : 1.0   (15m candle min growth %)
#   filter_growth_1m      : 0.5   (live 1min total growth %)
#   drop_from_peak        : 0.5   (trailing exit %)
#   stop_loss             : 1.0   (hard stop %)
#   filter_age_months     : 1     (coin listed >= N months)
#   filter_volume_min_usd : 100000 (24h volume min USD)
#   monitor_interval_sec  : 0.2   (exit polling interval)
#   scan_interval_sec     : 60    (pause when no candidates)
#   max_positions         : 5
#   position_size_pct     : 20
#   max_position_usd      : 200
#   min_balance           : 100
#   cooldown_sl_sec       : 3600
#
# =============================================================================

import json, os, time, logging
from datetime import datetime, timezone

try:
    import ccxt
    HAS_CCXT = True
except ImportError:
    HAS_CCXT = False
    print('[ERROR] ccxt not installed!')
    exit(1)

try:
    import requests
    HAS_REQUESTS = True
except ImportError:
    HAS_REQUESTS = False

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------
ROOT        = '/app'
SCRIPTS     = os.path.join(ROOT, 'scripts')
CONFIG_FILE = os.path.join(ROOT, 'config.json')
PAPER_FILE  = os.path.join(SCRIPTS, 'paper_balance.json')
PAPER_LOG   = os.path.join(SCRIPTS, 'paper_trades.log')
SCAN_STATUS = os.path.join(SCRIPTS, 'scan_status.json')

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
log = logging.getLogger('paper_trade')

# ---------------------------------------------------------------------------
# Config / Paper helpers
# ---------------------------------------------------------------------------
def load_config():
    with open(CONFIG_FILE) as f:
        return json.load(f)

def load_paper():
    try:
        with open(PAPER_FILE) as f:
            return json.load(f)
    except:
        return {
            'balance': 1000.0, 'start_balance': 1000.0,
            'positions': {}, 'closed_trades': [],
            'start_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        }

def save_paper(data):
    with open(PAPER_FILE, 'w') as f:
        json.dump(data, f, indent=2)

def load_list(path):
    try:
        with open(path) as f:
            return json.load(f)
    except:
        return []

def log_trade(line):
    with open(PAPER_LOG, 'a') as f:
        f.write(line + '\n')

# ---------------------------------------------------------------------------
# Telegram
# ---------------------------------------------------------------------------
def tg_send(cfg, text):
    if not HAS_REQUESTS:
        return
    token = cfg.get('tg_token', '')
    chat  = cfg.get('tg_chat_id', '')
    if not token or not chat:
        return
    try:
        requests.post(
            f'https://api.telegram.org/bot{token}/sendMessage',
            json={'chat_id': chat, 'text': text, 'parse_mode': 'HTML'},
            timeout=5
        )
    except:
        pass

# ---------------------------------------------------------------------------
# Exchange factory
# ---------------------------------------------------------------------------
def make_exchange(cfg):
    name = cfg.get('exchange', 'okx').lower()
    if name == 'mexc':
        return ccxt.mexc({'enableRateLimit': True})
    return ccxt.okx({
        'apiKey':   cfg.get('okx_api_key', ''),
        'secret':   cfg.get('okx_secret_key', ''),
        'password': cfg.get('okx_passphrase', ''),
        'hostname': 'my.okx.com',
        'enableRateLimit': True
    })

# ---------------------------------------------------------------------------
# Market info: age check
# ---------------------------------------------------------------------------
def get_market_age_months(ex, symbol):
    """Return age of symbol in months. Returns 99 if unknown (allow trade)."""
    try:
        markets = ex.load_markets()
        m = markets.get(symbol)
        if not m:
            return 99
        # Some exchanges provide 'info.listTime' or similar
        info = m.get('info', {})
        list_ts = None
        for key in ('listTime', 'onboardDate', 'created', 'listing_date', 'launchTime'):
            val = info.get(key)
            if val:
                try:
                    list_ts = int(val) / 1000 if int(val) > 1e10 else int(val)
                    break
                except:
                    pass
        if list_ts is None:
            return 99  # unknown — allow
        age_days = (time.time() - list_ts) / 86400
        return age_days / 30
    except Exception as e:
        log.debug(f'age_check {symbol}: {e}')
        return 99

# ---------------------------------------------------------------------------
# OHLCV helpers
# ---------------------------------------------------------------------------
def get_candle_change(ex, symbol, timeframe, limit=2):
    """% change of the last CLOSED candle."""
    try:
        ohlcv = ex.fetch_ohlcv(symbol, timeframe, limit=limit)
        if len(ohlcv) < 2:
            return None
        o = ohlcv[-2][1]
        c = ohlcv[-2][4]
        if o == 0:
            return None
        return (c - o) / o * 100
    except Exception as e:
        log.warning(f'OHLCV {symbol} {timeframe}: {e}')
        return None

def get_live_price(ex, symbol):
    try:
        t = ex.fetch_ticker(symbol)
        return t.get('last') or t.get('close') or 0
    except Exception as e:
        log.warning(f'Ticker {symbol}: {e}')
        return None

def get_24h_volume_usd(ex, symbol):
    """Return 24h quoteVolume in USD."""
    try:
        t = ex.fetch_ticker(symbol)
        return t.get('quoteVolume') or 0
    except:
        return 0

# ---------------------------------------------------------------------------
# LIVE 1-MINUTE CHECK
# 6 ticks every 10 seconds = 1 minute window
# Pass if:
#   a) total growth (last - first) / first >= filter_growth_1m (default 0.5%)
#   b) at least 4/6 consecutive ticks are rising
# ---------------------------------------------------------------------------
LIVE_CHECKS   = 6
LIVE_INTERVAL = 10  # seconds → 6×10 = 60s = 1 minute

def _live_1m_check(ex, symbol, cfg):
    min_growth_1m = cfg.get('filter_growth_1m', 0.5)  # % total over 1 min
    prices = []

    for i in range(LIVE_CHECKS):
        p = get_live_price(ex, symbol)
        if p:
            prices.append(p)
            log.info(f'  live[{i+1}/{LIVE_CHECKS}] {symbol} = {p}')
        if i < LIVE_CHECKS - 1:
            time.sleep(LIVE_INTERVAL)

    if len(prices) < 3:
        log.info(f'  live SKIP — not enough ticks ({len(prices)})')
        return False

    # Condition A: total 1-minute growth
    total_growth = (prices[-1] - prices[0]) / prices[0] * 100 if prices[0] else 0

    # Condition B: at least 4/6 rising ticks
    rising = sum(1 for i in range(1, len(prices)) if prices[i] > prices[i-1])
    min_rising = len(prices) // 2 + 1  # 4 out of 6

    ok = total_growth >= min_growth_1m and rising >= min_rising
    log.info(
        f'  live 1m: growth={total_growth:+.3f}% (need>={min_growth_1m}%) '
        f'rising={rising}/{len(prices)-1} (need>={min_rising}) → {"OK" if ok else "SKIP"}'
    )
    return ok

# ---------------------------------------------------------------------------
# ENTRY FILTERS — shared pre-checks
# ---------------------------------------------------------------------------
def _base_filters(ex, symbol, cfg):
    """Volume + age filter. Returns (True, '') or (False, reason)."""
    vol_min = cfg.get('filter_volume_min_usd', 100000)
    age_min = cfg.get('filter_age_months', 1)

    vol = get_24h_volume_usd(ex, symbol)
    if vol < vol_min:
        return False, f'volume {vol:.0f} < {vol_min}'

    age = get_market_age_months(ex, symbol)
    if age < age_min:
        return False, f'age {age:.1f}mo < {age_min}mo'

    return True, ''

# ---------------------------------------------------------------------------
# ENTRY CONFIRMATION
# ---------------------------------------------------------------------------
def confirm_entry_trade60(ex, symbol, cfg):
    """
    Trade60:
      1h candle >= filter_growth_1h (1.0%)
      15m candle >= filter_growth_15m (1.0%)
      Live 1m check (6×10s): growth >= 0.5% AND 4/6 rising
      Volume + age filters
    """
    ok, reason = _base_filters(ex, symbol, cfg)
    if not ok:
        log.info(f'[T60] {symbol} base filter SKIP: {reason}')
        return False

    ch_1h = get_candle_change(ex, symbol, '1h')
    thr_1h = cfg.get('filter_growth_1h', 1.0)
    if ch_1h is None or ch_1h < thr_1h:
        log.info(f'[T60] {symbol} 1h={ch_1h}% < {thr_1h}% — SKIP')
        return False

    ch_15m = get_candle_change(ex, symbol, '15m')
    thr_15m = cfg.get('filter_growth_15m', 1.0)
    if ch_15m is None or ch_15m < thr_15m:
        log.info(f'[T60] {symbol} 15m={ch_15m}% < {thr_15m}% — SKIP')
        return False

    log.info(f'[T60] {symbol} 1h={ch_1h:.2f}% 15m={ch_15m:.2f}% → live check')
    return _live_1m_check(ex, symbol, cfg)


def confirm_entry_trade15(ex, symbol, cfg):
    """
    Trade15:
      15m candle >= filter_growth_15m (1.0%)
      Live 1m check (6×10s)
      Volume + age filters
    """
    ok, reason = _base_filters(ex, symbol, cfg)
    if not ok:
        log.info(f'[T15] {symbol} base filter SKIP: {reason}')
        return False

    ch_15m = get_candle_change(ex, symbol, '15m')
    thr_15m = cfg.get('filter_growth_15m', 1.0)
    if ch_15m is None or ch_15m < thr_15m:
        log.info(f'[T15] {symbol} 15m={ch_15m}% < {thr_15m}% — SKIP')
        return False

    log.info(f'[T15] {symbol} 15m={ch_15m:.2f}% → live check')
    return _live_1m_check(ex, symbol, cfg)

# ---------------------------------------------------------------------------
# EXIT MONITOR
# ---------------------------------------------------------------------------
def should_exit(pos, current_price, cfg):
    """
    Returns (True, reason) or (False, '')
    Trailing: drop from peak >= drop_from_peak %
    Hard SL:  drop from entry >= stop_loss %
    """
    entry = pos.get('entry_price', 0)
    peak  = pos.get('peak_price', entry)
    sl    = cfg.get('stop_loss', 1.0)
    drop  = cfg.get('drop_from_peak', 0.5)

    if current_price > peak:
        pos['peak_price'] = current_price
        peak = current_price

    if peak > 0:
        drop_pct = (peak - current_price) / peak * 100
        if drop_pct >= drop:
            return True, f'DROP_PEAK {drop_pct:.2f}%'

    if entry > 0:
        sl_pct = (entry - current_price) / entry * 100
        if sl_pct >= sl:
            return True, f'STOP_LOSS {sl_pct:.2f}%'

    return False, ''

# ---------------------------------------------------------------------------
# OPEN POSITION
# ---------------------------------------------------------------------------
def open_position(paper, cfg, symbol, symbol_ccxt, current_price):
    bal     = paper.get('balance', 0)
    max_pos = cfg.get('max_positions', 5)
    pos_pct = cfg.get('position_size_pct', 20) / 100
    max_usd = cfg.get('max_position_usd', 200)
    min_bal = cfg.get('min_balance', 100)

    if len(paper.get('positions', {})) >= max_pos:
        return False, 'max_positions'
    if bal <= min_bal:
        return False, 'min_balance'

    cost   = min(bal * pos_pct, max_usd)
    amount = cost / current_price

    paper.setdefault('positions', {})[symbol] = {
        'symbol':      symbol,
        'symbol_ccxt': symbol_ccxt,
        'entry_price': current_price,
        'peak_price':  current_price,
        'amount':      amount,
        'cost':        cost,
        'entry_time':  datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'entry_ts':    time.time(),
        'mode':        cfg.get('trade_mode', 'trade60'),
    }
    paper['balance'] -= cost
    return True, 'OK'

# ---------------------------------------------------------------------------
# CLOSE POSITION
# ---------------------------------------------------------------------------
def close_position(paper, cfg, symbol, current_price, reason, cooldowns):
    positions = paper.get('positions', {})
    if symbol not in positions:
        return 0, 0

    pos    = positions[symbol]
    val    = pos['amount'] * current_price
    entry  = pos['entry_price']
    pnl    = (current_price - entry) / entry * 100 if entry else 0
    profit = val - pos['cost']

    paper['balance'] = paper.get('balance', 0) + val
    paper.setdefault('closed_trades', []).append({
        'symbol':       pos['symbol'],
        'reason':       reason,
        'pnl_pct':      round(pnl, 2),
        'profit_usd':   round(profit, 4),
        'cost':         pos['cost'],
        'entry_price':  entry,
        'exit_price':   current_price,
        'entry_time':   pos['entry_time'],
        'exit_time':    datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'duration_min': round((time.time() - pos.get('entry_ts', time.time())) / 60, 1),
        'mode':         pos.get('mode', '?'),
    })
    del positions[symbol]
    paper['positions'] = positions

    if 'STOP_LOSS' in reason:
        cooldown_sec = cfg.get('cooldown_sl_sec', 3600)
        cooldowns[symbol] = time.time() + cooldown_sec
        log.info(f'[COOLDOWN] {symbol} for {cooldown_sec}s after SL')

    line = (
        f"{datetime.now():%Y-%m-%d %H:%M:%S} "
        f"SELL {pos['symbol']} "
        f"entry={entry:.6f} exit={current_price:.6f} "
        f"pnl={pnl:+.2f}% profit={profit:+.4f}$ "
        f"reason={reason} mode={pos.get('mode','?')}"
    )
    log_trade(line)
    log.info(f'[CLOSE] {line}')
    return pnl, profit

# ---------------------------------------------------------------------------
# MAIN LOOP
# ---------------------------------------------------------------------------
def main():
    log.info('=== CryptoBot paper_trade.py v2026-04-08b starting ===')
    log.info('Trade60: 1h>=1% + 15m>=1% + live_1m>=0.5% + age>=1mo + vol>=100k')
    cooldowns = {}

    while True:
        try:
            cfg = load_config()

            if cfg.get('panic_mode', False):
                log.info('[PANIC] panic_mode=true, sleeping 30s')
                time.sleep(30)
                continue

            mode = cfg.get('trade_mode', 'trade60')
            ex   = make_exchange(cfg)
            paper = load_paper()

            # ----------------------------------------------------------------
            # MONITOR open positions
            # ----------------------------------------------------------------
            for sym in list(paper.get('positions', {}).keys()):
                pos   = paper['positions'][sym]
                price = get_live_price(ex, pos['symbol_ccxt'])
                if price is None:
                    continue
                exit_flag, reason = should_exit(pos, price, cfg)
                if exit_flag:
                    pnl, profit = close_position(paper, cfg, sym, price, reason, cooldowns)
                    tg_send(cfg,
                        f'🔴 <b>SELL</b> {sym}\n'
                        f'Reason: {reason}\n'
                        f'PnL: {pnl:+.2f}%  Profit: {profit:+.4f}$\n'
                        f'Mode: {pos.get("mode","?")}'
                    )
                else:
                    entry = pos.get('entry_price', 0)
                    peak  = pos.get('peak_price', entry)
                    ep    = (price - entry) / entry * 100 if entry else 0
                    pp    = (price - peak)  / peak  * 100 if peak  else 0
                    log.info(
                        f'[HOLD] {sym:20s} '
                        f'entry:{ep:+.2f}% peak:{pp:+.2f}% ${price:.6f}'
                    )
            save_paper(paper)

            # ----------------------------------------------------------------
            # SCAN for new entries
            # ----------------------------------------------------------------
            candidates = load_list(os.path.join(SCRIPTS, 'list_05.py'))
            if not candidates:
                log.info(f'[SCAN] list_05.py empty, sleeping {cfg.get("scan_interval_sec",60)}s')
                time.sleep(cfg.get('scan_interval_sec', 60))
                continue

            log.info(f'[SCAN] {len(candidates)} candidates | mode={mode}')

            for item in candidates:
                cfg   = load_config()
                paper = load_paper()

                if cfg.get('panic_mode', False):
                    break
                if len(paper.get('positions', {})) >= cfg.get('max_positions', 5):
                    log.info('[SCAN] max_positions reached, skip')
                    break

                symbol_ccxt = item if isinstance(item, str) else item.get('symbol', '')
                symbol      = symbol_ccxt.replace('/', '_').replace(':', '_')

                if symbol in cooldowns and time.time() < cooldowns[symbol]:
                    remaining = int(cooldowns[symbol] - time.time())
                    log.info(f'[COOLDOWN] {symbol} blocked {remaining}s')
                    continue

                if symbol in paper.get('positions', {}):
                    continue

                try:
                    if mode == 'trade60':
                        confirmed = confirm_entry_trade60(ex, symbol_ccxt, cfg)
                    else:
                        confirmed = confirm_entry_trade15(ex, symbol_ccxt, cfg)
                except Exception as e:
                    log.warning(f'[ENTRY] {symbol_ccxt} error: {e}')
                    confirmed = False

                if not confirmed:
                    continue

                price = get_live_price(ex, symbol_ccxt)
                if not price:
                    continue

                ok, msg = open_position(paper, cfg, symbol, symbol_ccxt, price)
                if ok:
                    save_paper(paper)
                    line = (
                        f"{datetime.now():%Y-%m-%d %H:%M:%S} "
                        f"BUY {symbol} price={price:.6f} mode={mode}"
                    )
                    log_trade(line)
                    log.info(f'[BUY] {line}')
                    tg_send(cfg,
                        f'🟢 <b>BUY</b> {symbol}\n'
                        f'Price: {price:.6f}\n'
                        f'Mode: {mode}'
                    )
                else:
                    log.info(f'[SKIP] {symbol} reason={msg}')

            time.sleep(cfg.get('monitor_interval_sec', 0.2))

        except KeyboardInterrupt:
            log.info('Stopped by user.')
            break
        except Exception as e:
            log.error(f'[MAIN LOOP ERROR] {e}')
            time.sleep(10)

if __name__ == '__main__':
    main()
