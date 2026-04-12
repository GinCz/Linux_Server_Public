#!/usr/bin/env python3
# Script:  paper_trade.py
# Version: v2026-04-12
# Changes: fast trailing stop — monitors price every 1s via fetch_ticker loop,
#          exits immediately on drop >= stop_loss%, trailing stop tracks peak price.
#          No candle dependency on exit side. Buy only from list_05.py (scanner output).
# = Rooted by VladiMIR | AI =

import ccxt, json, os, time, requests
from datetime import datetime

BASE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(BASE)

def path(f):      return os.path.join(BASE, f)
def root_path(f): return os.path.join(ROOT, f)

PAPER_FILE = path('paper_balance.json')
LOG_FILE   = path('paper_trades.log')
LIST_05    = path('list_05.py')
CONFIG     = root_path('config.json')

# ─────────────────────────────────────────
def load_config():
    try:
        with open(CONFIG) as f: return json.load(f)
    except: return {}

def load_paper():
    try:
        with open(PAPER_FILE) as f: return json.load(f)
    except:
        return {'balance': 1000.0, 'start_balance': 1000.0,
                'positions': {}, 'closed_trades': [],
                'start_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

def save_paper(d):
    with open(PAPER_FILE, 'w') as f: json.dump(d, f, indent=2)

def load_top5():
    try:
        with open(LIST_05) as f: return json.load(f)
    except: return []

def log(msg):
    line = f"[{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}] {msg}"
    print(line, flush=True)
    try:
        with open(LOG_FILE, 'a') as f: f.write(line + '\n')
    except: pass

def tg_send(token, chat_id, text):
    if not token or not chat_id: return
    try:
        requests.post(f"https://api.telegram.org/bot{token}/sendMessage",
                      data={'chat_id': chat_id, 'text': text, 'parse_mode': 'HTML'}, timeout=5)
    except: pass

# ─────────────────────────────────────────
def build_exchange(cfg):
    name = cfg.get('exchange', 'mexc').lower()
    if name == 'mexc':
        return ccxt.mexc({'apiKey': cfg.get('api_key',''), 'secret': cfg.get('api_secret',''),
                          'enableRateLimit': True})
    return ccxt.okx({'apiKey': cfg.get('okx_api_key',''), 'secret': cfg.get('okx_secret_key',''),
                     'password': cfg.get('okx_passphrase',''), 'hostname': 'my.okx.com',
                     'enableRateLimit': True})

def get_price(exchange, symbol_ccxt):
    """Fetch current price. Returns float or None on error."""
    try:
        t = exchange.fetch_ticker(symbol_ccxt)
        return float(t['last'])
    except:
        return None

# ─────────────────────────────────────────
def try_buy(exchange, cfg, paper, candidate):
    """
    Attempt to open a paper position for candidate from list_05.
    Skips if: max_positions reached, already in position, panic_mode, insufficient balance.
    """
    if cfg.get('panic_mode', False):
        return

    max_pos   = int(cfg.get('max_positions', 3))
    pos_pct   = float(cfg.get('position_size_pct', 20))
    max_usd   = float(cfg.get('max_position_usd', 200))
    symbol    = candidate['symbol']       # e.g. BTCUSDT
    sym_ccxt  = candidate['symbol_ccxt'] # e.g. BTC/USDT

    positions = paper.get('positions', {})
    if len(positions) >= max_pos:
        return
    if symbol in positions:
        return

    balance = paper.get('balance', 0)
    cost    = min(balance * pos_pct / 100, max_usd)
    if cost < 1.0:
        log(f"  BUY SKIP {symbol}: insufficient balance ${balance:.2f}")
        return

    price = get_price(exchange, sym_ccxt)
    if not price or price <= 0:
        log(f"  BUY SKIP {symbol}: price fetch failed")
        return

    amount = cost / price
    paper['balance'] = balance - cost
    paper['positions'][symbol] = {
        'symbol':      symbol,
        'symbol_ccxt': sym_ccxt,
        'entry_price': price,
        'amount':      amount,
        'cost':        cost,
        'peak_price':  price,         # trailing stop tracking
        'entry_time':  datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'entry_ts':    time.time(),
        'growth_1m':   candidate.get('growth_1m', 0),
        'growth_15m':  candidate.get('growth_15m', 0),
    }
    save_paper(paper)

    tg_cfg = load_config()
    tg_send(tg_cfg.get('tg_token',''), tg_cfg.get('tg_chat_id',''),
            f"📈 BUY {symbol} @ ${price:.6f}  cost:${cost:.2f}  "
            f"1m:{candidate.get('growth_1m',0):+.2f}% 15m:{candidate.get('growth_15m',0):+.2f}%")
    log(f"  BUY  {symbol} @ ${price:.6f}  cost=${cost:.2f}  qty={amount:.6f}")

def close_position(paper, symbol, price, reason):
    """Close one position, record trade, update balance."""
    pos    = paper['positions'][symbol]
    val    = pos['amount'] * price
    pnl    = (price - pos['entry_price']) / pos['entry_price'] * 100
    profit = val - pos['cost']
    dur    = round((time.time() - pos.get('entry_ts', time.time())) / 60, 1)

    paper['balance'] += val
    paper.setdefault('closed_trades', []).append({
        'symbol':      symbol,
        'reason':      reason,
        'pnl_pct':     round(pnl, 4),
        'profit_usd':  round(profit, 4),
        'cost':        pos['cost'],
        'entry_price': pos['entry_price'],
        'exit_price':  price,
        'entry_time':  pos['entry_time'],
        'exit_time':   datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'duration_min': dur,
    })
    del paper['positions'][symbol]
    save_paper(paper)

    emoji = '✅' if pnl > 0 else '❌'
    tg_cfg = load_config()
    tg_send(tg_cfg.get('tg_token',''), tg_cfg.get('tg_chat_id',''),
            f"{emoji} {reason} {symbol} @ ${price:.6f}  "
            f"pnl:{pnl:+.2f}%  ${profit:+.4f}  {dur}min")
    log(f"  SELL {symbol} @ ${price:.6f}  reason={reason}  pnl={pnl:+.4f}%  ${profit:+.4f}  {dur}min")

# ─────────────────────────────────────────
def monitor_and_trade():
    """
    Main loop — runs forever.

    Every MONITOR_INTERVAL seconds:
      1. For each open position: fetch live price, update trailing peak,
         exit if stop_loss OR trailing_stop OR take_profit hit.
      2. Every SCAN_CHECK_INTERVAL loops: check list_05 for new buy candidates.

    Exit logic (NO candles — pure price comparison):
      - stop_loss:      price drops X% below entry_price
      - trailing_stop:  price drops X% below peak_price (tracks highest seen)
      - take_profit:    price rises X% above entry_price
    """
    log("=" * 60)
    log("paper_trade.py v2026-04-12 START")
    log("=" * 60)

    scan_check_counter = 0

    while True:
        try:
            cfg = load_config()

            if cfg.get('panic_mode', False):
                log("PANIC MODE — bot sleeping, no trades")
                time.sleep(10)
                continue

            monitor_interval = float(cfg.get('monitor_interval_sec', 1))
            scan_check_every = int(cfg.get('scan_interval_sec', 60) / max(monitor_interval, 1))

            sl_pct       = float(cfg.get('stop_loss',      0.5))
            tp_pct       = float(cfg.get('take_profit',    1.5))
            trail_pct    = float(cfg.get('trailing_stop',  0.4))
            trail_on     = bool(cfg.get('trailing_stop_enabled', True))

            exchange = build_exchange(cfg)
            paper    = load_paper()

            # ── MONITOR OPEN POSITIONS ──────────────────────────
            for symbol in list(paper.get('positions', {}).keys()):
                pos   = paper['positions'][symbol]
                price = get_price(exchange, pos['symbol_ccxt'])
                if price is None:
                    continue

                entry = pos['entry_price']
                peak  = pos.get('peak_price', entry)

                # Update trailing peak
                if price > peak:
                    paper['positions'][symbol]['peak_price'] = price
                    peak = price

                drop_from_entry = (price - entry) / entry * 100
                drop_from_peak  = (price - peak)  / peak  * 100

                reason = None
                if drop_from_entry <= -sl_pct:
                    reason = f'SL({sl_pct}%)'
                elif trail_on and drop_from_peak <= -trail_pct:
                    reason = f'TRAIL({trail_pct}%)'
                elif drop_from_entry >= tp_pct:
                    reason = f'TP({tp_pct}%)'

                if reason:
                    paper = load_paper()  # reload fresh before write
                    if symbol in paper['positions']:
                        close_position(paper, symbol, price, reason)

            save_paper(paper)

            # ── CHECK FOR NEW BUYS ──────────────────────────────
            scan_check_counter += 1
            if scan_check_counter >= scan_check_every:
                scan_check_counter = 0
                paper   = load_paper()
                top5    = load_top5()
                for candidate in top5:
                    paper = load_paper()  # reload each time — balance may have changed
                    try_buy(exchange, cfg, paper, candidate)

        except KeyboardInterrupt:
            log("Stopped by user.")
            break
        except Exception as e:
            log(f"ERROR in main loop: {e}")
            time.sleep(5)

        time.sleep(max(monitor_interval, 0.5))

if __name__ == '__main__':
    monitor_and_trade()
