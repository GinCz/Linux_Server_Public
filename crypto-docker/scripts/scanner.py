#!/usr/bin/env python3
# Script:  scanner.py
# Version: v2026-04-12
# Changes: soft entry filters — lower thresholds to catch early growth, not overheated coins
# = Rooted by VladiMIR | AI =

import ccxt, json, time, requests, os, sys, fcntl
from datetime import datetime

BASE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(BASE)

def path(f):      return os.path.join(BASE, f)
def root_path(f): return os.path.join(ROOT, f)

LOCK_FILE = path('scanner.lock')
_lock_fh  = open(LOCK_FILE, 'w')
try:
    fcntl.flock(_lock_fh, fcntl.LOCK_EX | fcntl.LOCK_NB)
except IOError:
    print(f"[{datetime.now().strftime('%H:%M:%S')}] Scanner already running, exit.", flush=True)
    sys.exit(0)

def load_config():
    try:
        with open(root_path('config.json')) as f:
            return json.load(f)
    except:
        return {}

def log(msg):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {msg}", flush=True)

def tg_send(token, chat_id, text):
    try:
        requests.post(f"https://api.telegram.org/bot{token}/sendMessage",
                      data={'chat_id': chat_id, 'text': text, 'parse_mode': 'HTML'}, timeout=5)
    except Exception as e:
        log(f"TG error: {e}")

def save_list(filename, data):
    with open(path(filename), 'w') as f:
        json.dump(data, f, indent=2)
    log(f"  {filename}: {len(data)} coins")

def load_market_state():
    try:
        with open(path('market_state.json')) as f:
            return json.load(f)
    except:
        return {'state': 'unknown', 'last_alert_ts': 0}

def save_market_state(ms):
    with open(path('market_state.json'), 'w') as f:
        json.dump(ms, f)

def build_exchange(cfg):
    exchange_name = cfg.get('exchange', 'mexc').lower()
    if exchange_name == 'mexc':
        log("Exchange: MEXC")
        return ccxt.mexc({
            'apiKey':          cfg.get('api_key', ''),
            'secret':          cfg.get('api_secret', ''),
            'enableRateLimit': True,
        })
    else:
        log("Exchange: OKX")
        return ccxt.okx({
            'apiKey':          cfg.get('okx_api_key', ''),
            'secret':          cfg.get('okx_secret_key', ''),
            'password':        cfg.get('okx_passphrase', ''),
            'hostname':        'my.okx.com',
            'enableRateLimit': True,
        })

def build_list_01(exchange, exchange_name, age_months):
    log(f"STEP 1: All {exchange_name.upper()} USDT coins...")
    markets = exchange.load_markets()
    result  = []
    for symbol, market in markets.items():
        if not symbol.endswith('/USDT'): continue
        if not market.get('active'):     continue
        result.append({'symbol': symbol.replace('/', ''), 'symbol_ccxt': symbol,
                        'base': market.get('base', '')})
    save_list('list_01.py', result)
    return result

def build_list_02(exchange, list_01, min_volume):
    log(f"STEP 2: Volume >= ${min_volume/1e3:.0f}k...")
    result  = []
    symbols = [i['symbol_ccxt'] for i in list_01]
    tickers = {}
    for i in range(0, len(symbols), 100):
        try:
            t = exchange.fetch_tickers(symbols[i:i+100])
            tickers.update(t)
        except: pass
        time.sleep(0.3)
    for item in list_01:
        ticker = tickers.get(item['symbol_ccxt'], {})
        vol    = ticker.get('quoteVolume', 0) or 0
        if vol >= min_volume:
            item['quote_volume_24h'] = round(vol, 0)
            item['price']            = ticker.get('last', 0) or 0
            result.append(item)
    save_list('list_02.py', result)
    return result

def build_list_03_1h(exchange, list_02, min_g1h, max_g1h, min_g15, max_g15):
    """
    STEP 3 — soft entry: buy early growth, NOT overheated pumps.
    1h: min_g1h .. max_g1h  (default 0.3% .. 6.0%)
    15m: min_g15 .. max_g15  (default 0.2% .. 3.0%)
    Extra guard: reject if last 1m candle is already falling < -0.2%
    """
    log(f"STEP 3: 1h:{min_g1h}-{max_g1h}% AND 15m:{min_g15}-{max_g15}%...")
    result = []
    for item in list_02:
        try:
            ohlcv_1h = exchange.fetch_ohlcv(item['symbol_ccxt'], '1h', limit=2)
            if len(ohlcv_1h) < 2: continue
            h0, h1 = float(ohlcv_1h[0][4]), float(ohlcv_1h[1][4])
            if h0 <= 0: continue
            g1h = (h1 - h0) / h0 * 100
            if not (min_g1h <= g1h <= max_g1h): continue

            ohlcv_15 = exchange.fetch_ohlcv(item['symbol_ccxt'], '15m', limit=2)
            if len(ohlcv_15) < 2: continue
            p0, p1 = float(ohlcv_15[0][4]), float(ohlcv_15[1][4])
            if p0 <= 0: continue
            g15 = (p1 - p0) / p0 * 100
            if not (min_g15 <= g15 <= max_g15): continue

            # Guard: reject if 1m candle is already pulling back
            ohlcv_1m = exchange.fetch_ohlcv(item['symbol_ccxt'], '1m', limit=2)
            if len(ohlcv_1m) >= 2:
                m0, m1 = float(ohlcv_1m[-1][1]), float(ohlcv_1m[-1][4])
                if m0 > 0 and (m1 - m0) / m0 * 100 < -0.2:
                    continue  # coin already reversing — skip

            item['growth_1h']  = round(g1h, 2)
            item['growth_15m'] = round(g15, 2)
            item['price']      = p1
            result.append(item)
        except: pass
        time.sleep(0.1)
    save_list('list_03.py', result)
    return result

def build_list_04(exchange, list_03, min_g1, max_g1, min_g5, max_g5):
    log(f"STEP 4: 1m:{min_g1}-{max_g1}% AND 5m:{min_g5}-{max_g5}%...")
    result = []
    for item in list_03:
        try:
            ohlcv = exchange.fetch_ohlcv(item['symbol_ccxt'], '1m', limit=6)
            if len(ohlcv) < 6: continue

            p5_open  = float(ohlcv[-6][4])
            p5_close = float(ohlcv[-1][4])
            if p5_open <= 0: continue
            g5m = (p5_close - p5_open) / p5_open * 100

            p1_open  = float(ohlcv[-1][1])
            p1_close = float(ohlcv[-1][4])
            if p1_open <= 0: continue
            g1m = (p1_close - p1_open) / p1_open * 100

            if not (min_g1 <= g1m <= max_g1): continue
            if not (min_g5 <= g5m <= max_g5): continue

            item['growth_1m'] = round(g1m, 2)
            item['growth_5m'] = round(g5m, 2)
            item['price']     = p1_close
            result.append(item)
        except: pass
        time.sleep(0.05)
    save_list('list_04.py', result)
    return result

def build_list_05(list_04, top_n=2):
    seen, unique = set(), []
    for item in list_04:
        if item['symbol'] not in seen:
            seen.add(item['symbol'])
            unique.append(item)
    top = sorted(unique, key=lambda x: x.get('growth_5m', 0), reverse=True)[:top_n]
    save_list('list_05.py', top)
    tops = [x['symbol'] + ' 1h:' + str(round(x.get('growth_1h',0),2)) + '% 15m:' + str(round(x.get('growth_15m',0),2)) + '%' for x in top]
    log(f"  TOP-{top_n}: {tops}")
    return top

def check_and_alert(l2, l3, l4, top5):
    cfg     = load_config()
    if not cfg.get('scanner_tg_notify', True):
        log("TG scanner alerts disabled (scanner_tg_notify=false)")
        return
    token   = cfg.get('tg_token', '')
    chat_id = cfg.get('tg_chat_id', '')
    if not token or not chat_id or l2 == 0:
        return
    ms            = load_market_state()
    now_ts        = time.time()
    growth_ratio  = l3 / l2
    new_state     = 'bear' if (growth_ratio < 0.03 and len(top5) == 0) else \
                    'bull' if (growth_ratio > 0.08 or len(top5) >= 2) else 'neutral'
    changed       = new_state != ms['state']
    cd_ok         = (now_ts - ms['last_alert_ts']) > 3600
    if new_state == 'bear' and (changed or cd_ok):
        tg_send(token, chat_id,
                f"BEAR MARKET | coins:{l2} | 15m_up:{l3}({growth_ratio*100:.1f}%) | "
                f"1m_up:{l4} | top:{len(top5)} | {datetime.now().strftime('%d.%m %H:%M')}")
        ms['last_alert_ts'] = now_ts
    elif new_state == 'bull' and (changed or (ms['state'] == 'bear' and cd_ok)):
        top_str = ', '.join([x['symbol'] for x in top5]) or '—'
        tg_send(token, chat_id,
                f"BULL SIGNAL | coins:{l2} | 15m_up:{l3}({growth_ratio*100:.1f}%) | "
                f"top:{top_str} | {datetime.now().strftime('%d.%m %H:%M')}")
        ms['last_alert_ts'] = now_ts
    ms['state'] = new_state
    save_market_state(ms)

def run_scan():
    import os; os.system('clear')
    cfg           = load_config()
    exchange_name = cfg.get('exchange', 'mexc').lower()
    exchange      = build_exchange(cfg)

    min_vol    = cfg.get('filter_volume_min_usd',   500_000)
    min_g15    = cfg.get('filter_growth_15m',           0.2)
    max_g15    = cfg.get('filter_growth_15m_max',       3.0)
    min_g1h    = cfg.get('filter_growth_1h',            0.3)
    max_g1h    = cfg.get('filter_growth_1h_max',        6.0)
    min_g1     = cfg.get('filter_growth_1m',            0.1)
    max_g1     = cfg.get('filter_growth_1m_max',       99.0)
    min_g5     = cfg.get('filter_growth_5m',            0.1)
    max_g5     = cfg.get('filter_growth_5m_max',       99.0)
    age_months = cfg.get('filter_age_months',             1)
    top_n      = int(cfg.get('top_n',                     2))

    log(f"SCAN [{exchange_name.upper()}] | vol>${min_vol/1e3:.0f}k "
        f"1h:{min_g1h}-{max_g1h}% 15m:{min_g15}-{max_g15}% 1m:{min_g1}-{max_g1}% top{top_n}")
    start = time.time()
    l1 = build_list_01(exchange, exchange_name, age_months)
    l2 = build_list_02(exchange, l1, min_vol)
    l3 = build_list_03_1h(exchange, l2, min_g1h, max_g1h, min_g15, max_g15)
    l4 = build_list_04(exchange, l3, min_g1, max_g1, min_g5, max_g5)
    l5 = build_list_05(l4, top_n)
    log(f"DONE {time.time()-start:.1f}s | {len(l1)}/{len(l2)}/{len(l3)}/{len(l4)}/{len(l5)}")

    with open(path('scan_status.json'), 'w') as f:
        json.dump({'last_scan': datetime.now().isoformat(), 'status': 'idle',
                   'exchange': exchange_name,
                   'counts': {'list_01': len(l1), 'list_02': len(l2), 'list_03': len(l3),
                              'list_04': len(l4), 'list_05': len(l5)},
                   'filters': {'age_months': age_months, 'volume_min_usd': min_vol,
                               'growth_1h_min': min_g1h, 'growth_1h_max': max_g1h,
                               'growth_15m': min_g15, 'growth_15m_max': max_g15,
                               'growth_1m_min': min_g1, 'growth_1m_max': max_g1,
                               'growth_5m_min': min_g5, 'growth_5m_max': max_g5,
                               'top_n': top_n}}, f)
    check_and_alert(len(l2), len(l3), len(l4), l5)
    return l5

if __name__ == '__main__':
    run_scan()
    fcntl.flock(_lock_fh, fcntl.LOCK_UN)
    _lock_fh.close()
