#!/usr/bin/env python3
# Script: app.py
# Version: v2026-03-31
# = Rooted by VladiMIR | AI =
# NOTE: Before any change - read the full repository first!
import json, os, subprocess, threading, time
from flask import Flask, render_template, request, redirect, session, jsonify, send_from_directory
from datetime import datetime

try:
    import psutil
    HAS_PSUTIL = True
except ImportError:
    HAS_PSUTIL = False

app = Flask(__name__)
app.secret_key = 'cryptobotpro2026secret'
from datetime import timedelta
app.config['PERMANENT_SESSION_LIFETIME'] = timedelta(days=30)
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
app.config['SESSION_COOKIE_SECURE'] = False

ROOT    = os.path.dirname(os.path.abspath(__file__))
SCRIPTS = os.path.join(ROOT, 'scripts')

def p(f):  return os.path.join(ROOT, f)
def sp(f): return os.path.join(SCRIPTS, f)

CONFIG_FILE = p('config.json')
PAPER_FILE  = sp('paper_balance.json')
PAPER_LOG   = sp('paper_trades.log')
SCAN_STATUS = sp('scan_status.json')

def load_config():
    with open(CONFIG_FILE) as f:
        return json.load(f)

def save_config(cfg):
    with open(CONFIG_FILE, 'w') as f:
        json.dump(cfg, f, indent=2)

def load_json(path, default):
    try:
        with open(path) as f:
            return json.load(f)
    except:
        return default

def load_list(path):
    try:
        with open(path) as f:
            return json.load(f)
    except:
        return []

def auth():
    return session.get('logged_in')

def run_delayed(cmd, delay=0.5):
    def _run():
        time.sleep(delay)
        subprocess.run(cmd, capture_output=True)
    threading.Thread(target=_run, daemon=True).start()

@app.route('/favicon.ico')
def favicon():
    return send_from_directory(
        os.path.join(app.root_path, 'static'),
        'favicon.svg', mimetype='image/svg+xml'
    )

@app.route('/login', methods=['GET', 'POST'])
def login():
    error = None
    if request.method == 'POST':
        cfg = load_config()
        if request.form['login'] == cfg.get('web_login', 'admin') and \
           request.form['password'] == cfg.get('web_password', 'crypto2026'):
            session.permanent = True
            session['logged_in'] = True
            return redirect('/')
        error = '\u041d\u0435\u0432\u0435\u0440\u043d\u044b\u0439 \u043b\u043e\u0433\u0438\u043d \u0438\u043b\u0438 \u043f\u0430\u0440\u043e\u043b\u044c'
    return render_template('login.html', error=error)

@app.route('/logout')
def logout():
    session.clear()
    return redirect('/login')

@app.route('/')
def index():
    if not auth(): return redirect('/login')
    return render_template('index.html')

@app.route('/logs')
def logs():
    if not auth(): return redirect('/login')
    return render_template('logs.html')

@app.route('/api/status')
def api_status():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    cfg    = load_config()
    paper  = load_json(PAPER_FILE, {'balance': 1000.0, 'start_balance': 1000.0, 'positions': {}, 'closed_trades': []})
    scan   = load_json(SCAN_STATUS, {'status': 'idle', 'counts': {}})
    top5   = load_list(sp('list_05.py'))
    trades = paper.get('closed_trades', [])
    wins   = sum(1 for t in trades if t.get('pnl_pct', 0) > 0)
    losses = sum(1 for t in trades if t.get('pnl_pct', 0) <= 0)
    bal    = paper.get('balance', 1000.0)
    start  = paper.get('start_balance', 1000.0)
    # Positions come from paper_balance.json (single source of truth)
    positions = paper.get('positions', {})
    positions_value = sum(pos.get('cost', 0) for pos in positions.values())
    total_bal = bal + positions_value
    pnl       = total_bal - start
    pnl_pct   = pnl / start * 100 if start else 0
    recent    = sorted(trades, key=lambda t: t.get('exit_time', ''), reverse=True)[:50]
    counts    = scan.get('counts', {})
    for i in range(1, 6):
        key = f'list_0{i}'
        if key not in counts:
            try:
                with open(sp(f'list_0{i}.py')) as f:
                    counts[key] = len(json.load(f))
            except:
                counts[key] = 0
    try:
        result = subprocess.run(['pgrep', '-f', 'paper_trade.py'],
                                    capture_output=True, text=True)
        bot_running = bool(result.stdout.strip())
    except:
        bot_running = None
    if HAS_PSUTIL:
        cpu = psutil.cpu_percent(interval=0.2)
        ram = psutil.virtual_memory()
        system = {'cpu_pct': round(cpu,1), 'ram_used_mb': round(ram.used/1024/1024),
                  'ram_total_mb': round(ram.total/1024/1024), 'ram_pct': round(ram.percent,1)}
    else:
        system = {'cpu_pct': None, 'ram_used_mb': None, 'ram_total_mb': None, 'ram_pct': None}
    panic_mode = bool(cfg.get('panic_mode', False))
    if not bot_running:
        panic_mode = True
    return jsonify({
        'paper': {'balance': round(total_bal, 4), 'start_balance': start,
                  'free_balance': round(bal, 4),
                  'pnl': round(pnl, 4), 'pnl_pct': round(pnl_pct, 2),
                  'trades_count': len(trades), 'wins': wins, 'losses': losses,
                  'start_date': paper.get('start_date', '')},
        'scanner': {'status': scan.get('status','idle'), 'last_scan': scan.get('last_scan',''), 'counts': counts},
        'positions': positions,   # <-- from paper_balance.json
        'top5': top5,
        'recent_trades': recent,
        'config': cfg,
        'system': system,
        'bot_running': bot_running,
        'panic_mode': panic_mode,
    })

@app.route('/api/settings', methods=['POST'])
def api_settings():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    data = request.json
    cfg  = load_config()
    allowed = [
        'stop_loss', 'take_profit', 'trailing_stop',
        'max_positions', 'position_size_pct', 'max_position_usd',
        'filter_growth_15m', 'filter_growth_1m', 'filter_growth_1m_max',
        'filter_volume_min_usd', 'filter_age_months',
        'drop_1m_exit',
        'cooldown_sl_sec', 'cooldown_drop_sec', 'cooldown_tp_sec',
        'scan_interval_sec', 'monitor_interval_sec', 'top_n',
    ]
    for k in allowed:
        if k in data:
            cfg[k] = data[k]
    save_config(cfg)
    return jsonify({'ok': True})

@app.route('/api/scan', methods=['POST'])
def api_scan():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    subprocess.Popen(['python3', sp('scanner.py')])
    return jsonify({'ok': True})

@app.route('/api/bot/start', methods=['POST'])
def api_bot_start():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    try:
        def _start_bot():
            time.sleep(0.3)
            subprocess.run(['pkill', '-f', 'paper_trade.py'], capture_output=True)
            time.sleep(0.5)
            subprocess.Popen(['python3', '/app/scripts/paper_trade.py'])
        threading.Thread(target=_start_bot, daemon=True).start()
        return jsonify({'ok': True, 'action': 'start'})
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)})

@app.route('/api/bot/stop', methods=['POST'])
def api_bot_stop():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    try:
        run_delayed(['pkill', '-f', 'paper_trade.py'], delay=0.8)
        return jsonify({'ok': True, 'action': 'stop'})
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)})

@app.route('/api/bot/restart', methods=['POST'])
def api_bot_restart():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    try:
        run_delayed(['pkill', '-f', 'paper_trade.py'], delay=0.3)
        threading.Thread(target=lambda: (time.sleep(1.5), subprocess.Popen(['python3', '/app/scripts/paper_trade.py'])), daemon=True).start()
        return jsonify({'ok': True, 'action': 'restart'})
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)})

@app.route('/api/reset_stats', methods=['POST'])
def api_reset_stats():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    fresh = {'balance': 1000.0, 'start_balance': 1000.0, 'positions': {},
             'closed_trades': [], 'start_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
    with open(PAPER_FILE, 'w') as f:
        json.dump(fresh, f, indent=2)
    return jsonify({'ok': True})

@app.route('/api/clear_log', methods=['POST'])
def api_clear_log():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    try:
        open(PAPER_LOG, 'w').close()
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)})
    return jsonify({'ok': True})

@app.route('/api/panic', methods=['POST'])
def api_panic():
    """PANIC: sell all positions + stop bot."""
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    paper     = load_json(PAPER_FILE, {})
    positions = paper.get('positions', {})
    for sym in list(positions.keys()):
        pos = positions[sym]
        try:
            import ccxt
            import json as _j
            with open(p('config.json')) as _f: _c = _j.load(_f)
            exchange = ccxt.okx({'apiKey': _c['okx_api_key'], 'secret': _c['okx_secret_key'], 'password': _c['okx_passphrase'], 'hostname': 'my.okx.com', 'enableRateLimit': True})
            price = exchange.fetch_ticker(pos['symbol_ccxt'])['last']
        except:
            price = pos.get('entry_price', 0)
        val = pos['amount'] * price
        paper['balance'] += val
        pnl = (price - pos['entry_price']) / pos['entry_price'] * 100 if pos['entry_price'] else 0
        paper.setdefault('closed_trades', []).append({
            'symbol': pos['symbol'], 'reason': 'PANIC', 'pnl_pct': round(pnl, 2),
            'profit_usd': round(val - pos['cost'], 4), 'cost': pos['cost'],
            'entry_price': pos['entry_price'], 'exit_price': price,
            'entry_time': pos['entry_time'],
            'exit_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'duration_min': round((datetime.now().timestamp() - pos.get('entry_ts', 0)) / 60, 1)
        })
        del positions[sym]
    paper['positions'] = positions
    with open(PAPER_FILE, 'w') as f:
        json.dump(paper, f, indent=2)
    cfg = load_config()
    cfg['panic_mode'] = True
    save_config(cfg)
    run_delayed(['pkill', '-f', 'paper_trade.py'], delay=0.5)
    return jsonify({'ok': True, 'panic_mode': True})

@app.route('/api/panic_reset', methods=['POST'])
def api_panic_reset():
    """RESUME: reset panic_mode and start bot."""
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    cfg = load_config()
    cfg['panic_mode'] = False
    save_config(cfg)
    def _resume_bot():
        time.sleep(0.3)
        subprocess.run(['pkill', '-f', 'paper_trade.py'], capture_output=True)
        time.sleep(0.5)
        subprocess.Popen(['python3', '/app/scripts/paper_trade.py'])
    threading.Thread(target=_resume_bot, daemon=True).start()
    return jsonify({'ok': True, 'panic_mode': False})

@app.route('/api/sell/<symbol>', methods=['POST'])
def api_sell_one(symbol):
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    paper     = load_json(PAPER_FILE, {})
    positions = paper.get('positions', {})
    if symbol in positions:
        pos = positions[symbol]
        try:
            import ccxt
            import json as _j
            with open(p('config.json')) as _f: _c = _j.load(_f)
            exchange = ccxt.okx({'apiKey': _c['okx_api_key'], 'secret': _c['okx_secret_key'], 'password': _c['okx_passphrase'], 'hostname': 'my.okx.com', 'enableRateLimit': True})
            price = exchange.fetch_ticker(pos['symbol_ccxt'])['last']
        except:
            price = pos.get('entry_price', 0)
        val = pos['amount'] * price
        pnl = (price - pos['entry_price']) / pos['entry_price'] * 100
        paper['balance'] += val
        paper.setdefault('closed_trades', []).append({
            'symbol': pos['symbol'], 'reason': 'MANUAL', 'pnl_pct': round(pnl, 2),
            'profit_usd': round(val - pos['cost'], 4), 'cost': pos['cost'],
            'entry_price': pos['entry_price'], 'exit_price': price,
            'entry_time': pos['entry_time'],
            'exit_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
            'duration_min': round((datetime.now().timestamp() - pos.get('entry_ts', 0)) / 60, 1)
        })
        del positions[symbol]
        paper['positions'] = positions
        with open(PAPER_FILE, 'w') as f:
            json.dump(paper, f, indent=2)
    return jsonify({'ok': True})

@app.route('/api/logs')
def api_logs():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    lines = []
    for logfile in [sp('paper_trades.log'), sp('trades.log')]:
        try:
            with open(logfile) as f:
                lines += f.read().splitlines()
        except:
            pass
    return jsonify({'lines': lines[-2000:]})

@app.route('/api/set_exchange', methods=['POST'])
def set_exchange():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    try:
        data = request.get_json()
        name = data.get('exchange', 'okx').lower()
        with open(p('config.json')) as f:
            cfg = json.load(f)
        cfg['exchange'] = name
        with open(p('config.json'), 'w') as f:
            json.dump(cfg, f, indent=2)
        return jsonify({'ok': True, 'exchange': name})
    except Exception as e:
        return jsonify({'ok': False, 'error': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)
