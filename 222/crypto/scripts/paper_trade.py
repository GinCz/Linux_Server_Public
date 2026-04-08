#!/usr/bin/env python3
# =============================================================================
# paper_trade.py — CryptoBot Trade60 / Trade15 engine
# Version  : v2026-04-08
# Author   : Ing. VladiMIR Bulantsev
# GitHub   : https://github.com/GinCz/Linux_Server_Public
# = Rooted by VladiMIR | AI =
# =============================================================================
# STRATEGY MODES:
#   trade60 — filters: 1h candle UP + 15m candle UP + 6x live checks every 10s
#   trade15 — filters: 15m candle UP + 6x live checks every 10s
# EXIT (both modes):
#   live price polling every monitor_interval_sec
#   if price drops >= drop_from_peak % from local peak → SELL
#   if price drops >= stop_loss % from entry → SELL (+ cooldown)
# =============================================================================

import json, os, time, logging
from datetime import datetime

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
# Config helpers
# ---------------------------------------------------------------------------
def load_config():
    with open(CONFIG_FILE) as f:
        return json.load(f)

def load_paper():
    try:
        with open(PAPER_FILE) as f:
            return json.load(f)
    except:
        return {'balance': 1000.0, 'start_balance': 1000.0,
                'positions': {}, 'closed_trades': [],
                'start_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

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
# Telegram notify
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
# OHLCV helpers
# ---------------------------------------------------------------------------
def get_candle_change(ex, symbol, timeframe, limit=2):
    """Return % change of last closed candle. Positive = up."""
    try:
        ohlcv = ex.fetch_ohlcv(symbol, timeframe, limit=limit)
        if len(ohlcv) < 2:
            return None
        prev_open  = ohlcv[-2][1]
        prev_close = ohlcv[-2][4]
        if prev_open == 0:
            return None
        return (prev_close - prev_open) / prev_open * 100
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

# ---------------------------------------------------------------------------
# ENTRY CONFIRMATION
# strategy: trade60 → 1h UP + 15m UP + 6x live checks (10s interval)
# strategy: trade15 → 15m UP + 6x live checks (10s interval)
# ---------------------------------------------------------------------------
LIVE_CHECKS   = 6
LIVE_INTERVAL = 10  # seconds

def confirm_entry_trade60(ex, symbol, cfg):
    """Trade60: 1h candle up + 15m candle up + 6x live price rising."""
    ch_1h = get_candle_change(ex, symbol, '1h')
    if ch_1h is None or ch_1h < cfg.get('filter_growth_1h', 0.5):
        log.info(f'[T60] {symbol} 1h={ch_1h:.2f}% — SKIP')
        return False

    ch_15m = get_candle_change(ex, symbol, '15m')
    if ch_15m is None or ch_15m < cfg.get('filter_growth_15m', 1.0):
        log.info(f'[T60] {symbol} 15m={ch_15m:.2f}% — SKIP')
        return False

    log.info(f'[T60] {symbol} 1h={ch_1h:.2f}% 15m={ch_15m:.2f}% — checking live x{LIVE_CHECKS}')
    return _live_rising_check(ex, symbol)

def confirm_entry_trade15(ex, symbol, cfg):
    """Trade15: 15m candle up + 6x live price rising."""
    ch_15m = get_candle_change(ex, symbol, '15m')
    if ch_15m is None or ch_15m < cfg.get('filter_growth_15m', 1.0):
        log.info(f'[T15] {symbol} 15m={ch_15m:.2f}% — SKIP')
        return False

    log.info(f'[T15] {symbol} 15m={ch_15m:.2f}% — checking live x{LIVE_CHECKS}')
    return _live_rising_check(ex, symbol)

def _live_rising_check(ex, symbol):
    """6 checks every 10 sec — at least 4 of 6 must be rising."""
    prices = []
    for i in range(LIVE_CHECKS):
        p = get_live_price(ex, symbol)
        if p:
            prices.append(p)
            log.info(f'  live[{i+1}/{LIVE_CHECKS}] {symbol} = {p}')
        if i < LIVE_CHECKS - 1:
            time.sleep(LIVE_INTERVAL)

    if len(prices) < 3:
        return False

    rising = sum(1 for i in range(1, len(prices)) if prices[i] > prices[i-1])
    ok = rising >= (len(prices) // 2 + 1)
    log.info(f'  live rising {rising}/{len(prices)-1} — {"OK" if ok else "SKIP"}')
    return ok

# ---------------------------------------------------------------------------
# EXIT MONITOR — runs in main loop per position
# ---------------------------------------------------------------------------
def should_exit(pos, current_price, cfg):
    """
    Returns (True, reason) or (False, '')
    EXIT conditions (NO candles, only live price):
      1. drop >= drop_from_peak % from local peak → trailing exit
      2. drop >= stop_loss % from entry           → hard stop
    """
    entry = pos.get('entry_price', 0)
    peak  = pos.get('peak_price', entry)
    sl    = cfg.get('stop_loss', 1.0)
    drop  = cfg.get('drop_from_peak', 0.5)  # default 0.5%

    # Update peak
    if current_price > peak:
        pos['peak_price'] = current_price
        peak = current_price

    # Trailing drop from peak
    if peak > 0:
        drop_from_peak_pct = (peak - current_price) / peak * 100
        if drop_from_peak_pct >= drop:
            return True, f'DROP_PEAK {drop_from_peak_pct:.2f}%'

    # Hard stop-loss from entry
    if entry > 0:
        drop_from_entry = (entry - current_price) / entry * 100
        if drop_from_entry >= sl:
            return True, f'STOP_LOSS {drop_from_entry:.2f}%'

    return False, ''

# ---------------------------------------------------------------------------
# OPEN POSITION
# ---------------------------------------------------------------------------
def open_position(paper, cfg, symbol, symbol_ccxt, current_price, ex):
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
        'symbol':       symbol,
        'symbol_ccxt':  symbol_ccxt,
        'entry_price':  current_price,
        'peak_price':   current_price,
        'amount':       amount,
        'cost':         cost,
        'entry_time':   datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'entry_ts':     time.time(),
        'mode':         cfg.get('trade_mode', 'trade60'),
    }
    paper['balance'] -= cost
    return True, 'OK'

# ---------------------------------------------------------------------------
# CLOSE POSITION
# ---------------------------------------------------------------------------
def close_position(paper, cfg, symbol, current_price, reason, cooldowns):
    positions = paper.get('positions', {})
    if symbol not in positions:
        return

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

    # Cooldown on stop-loss
    if 'STOP_LOSS' in reason:
        cooldown_sec = cfg.get('cooldown_sl_sec', 3600)
        cooldowns[symbol] = time.time() + cooldown_sec
        log.info(f'[COOLDOWN] {symbol} for {cooldown_sec}s after SL')

    line = (f"{datetime.now():%Y-%m-%d %H:%M:%S} "
            f"SELL {pos['symbol']} "
            f"entry={entry:.6f} exit={current_price:.6f} "
            f"pnl={pnl:+.2f}% profit={profit:+.4f}$ "
            f"reason={reason} mode={pos.get('mode','?')}")
    log_trade(line)
    log.info(f'[CLOSE] {line}')
    return pnl, profit

# ---------------------------------------------------------------------------
# MAIN LOOP
# ---------------------------------------------------------------------------
def main():
    log.info('=== CryptoBot paper_trade.py starting ===')
    cooldowns = {}  # symbol → timestamp until which it is blocked

    while True:
        try:
            cfg = load_config()

            if cfg.get('panic_mode', False):
                log.info('[PANIC] panic_mode=true, sleeping 30s')
                time.sleep(30)
                continue

            mode = cfg.get('trade_mode', 'trade60')
            log.info(f'[MODE] {mode}')

            ex     = make_exchange(cfg)
            paper  = load_paper()

            # ----------------------------------------------------------------
            # MONITOR open positions (exit logic — live price only)
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
            save_paper(paper)

            # ----------------------------------------------------------------
            # SCAN for new entries
            # ----------------------------------------------------------------
            scan_interval = cfg.get('scan_interval_sec', 60)
            candidates    = load_list(os.path.join(SCRIPTS, 'list_05.py'))
            if not candidates:
                log.info('[SCAN] list_05.py empty, sleeping')
                time.sleep(scan_interval)
                continue

            for item in candidates:
                cfg = load_config()  # reload each symbol to pick up live changes
                if cfg.get('panic_mode', False):
                    break

                paper = load_paper()
                if len(paper.get('positions', {})) >= cfg.get('max_positions', 5):
                    break

                symbol_ccxt = item if isinstance(item, str) else item.get('symbol', '')
                symbol      = symbol_ccxt.replace('/', '_').replace(':', '_')

                # Cooldown check
                if symbol in cooldowns and time.time() < cooldowns[symbol]:
                    remaining = int(cooldowns[symbol] - time.time())
                    log.info(f'[COOLDOWN] {symbol} blocked for {remaining}s')
                    continue

                # Already in position
                if symbol in paper.get('positions', {}):
                    continue

                # Entry confirmation based on mode
                try:
                    if mode == 'trade60':
                        confirmed = confirm_entry_trade60(ex, symbol_ccxt, cfg)
                    else:  # trade15
                        confirmed = confirm_entry_trade15(ex, symbol_ccxt, cfg)
                except Exception as e:
                    log.warning(f'[ENTRY] {symbol_ccxt} error: {e}')
                    confirmed = False

                if not confirmed:
                    continue

                # Get price and open
                price = get_live_price(ex, symbol_ccxt)
                if not price:
                    continue

                ok, msg = open_position(paper, cfg, symbol, symbol_ccxt, price, ex)
                if ok:
                    save_paper(paper)
                    log.info(f'[BUY] {symbol} @ {price} mode={mode}')
                    log_trade(
                        f"{datetime.now():%Y-%m-%d %H:%M:%S} "
                        f"BUY {symbol} price={price:.6f} mode={mode}"
                    )
                    tg_send(cfg,
                        f'🟢 <b>BUY</b> {symbol}\n'
                        f'Price: {price:.6f}\n'
                        f'Mode: {mode}'
                    )
                else:
                    log.info(f'[SKIP] {symbol} reason={msg}')

            time.sleep(cfg.get('monitor_interval_sec', 5))

        except KeyboardInterrupt:
            log.info('Stopped by user.')
            break
        except Exception as e:
            log.error(f'[MAIN LOOP ERROR] {e}')
            time.sleep(10)

if __name__ == '__main__':
    main()
