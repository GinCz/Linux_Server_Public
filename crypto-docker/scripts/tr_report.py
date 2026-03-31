# tr_report.py - v2026-03-31
# = Rooted by VladiMIR | AI =
import json, os, requests
from datetime import datetime

# --- ANSI colors ---
CYAN   = "\033[1;36m"
YELLOW = "\033[1;33m"
GREEN  = "\033[1;32m"
RED    = "\033[1;31m"
WHITE  = "\033[1;37m"
DIM    = "\033[0;37m"
RESET  = "\033[0m"

BAR  = CYAN + "=" * 66 + RESET
DASH = CYAN + "-" * 66 + RESET

# --- BTC market state ---
def get_btc():
    try:
        r = requests.get('https://api.binance.com/api/v3/ticker/24hr?symbol=BTCUSDT', timeout=3)
        d = r.json()
        price  = float(d['lastPrice'])
        change = float(d['priceChangePercent'])
        return price, change
    except:
        return None, None

btc_price, btc_pct = get_btc()
if btc_price:
    btc_color = GREEN if btc_pct >= 0 else RED
    btc_str = f"{btc_color}BTC ${btc_price:,.0f}  {btc_pct:+.2f}%{RESET}"
    market  = f"{GREEN}🚀 BULL{RESET}" if btc_pct > 1 else (f"{RED}🔻 BEAR{RESET}" if btc_pct < -1 else f"{YELLOW}➡ FLAT{RESET}")
else:
    btc_str = f"{DIM}BTC n/a{RESET}"
    market  = f"{DIM}?{RESET}"

# --- Load config ---
try:
    with open('/app/config.json') as f:
        cfg = json.load(f)
    exchange = cfg.get('exchange', '???').upper()
except:
    exchange = '???'

# --- Load scan status ---
try:
    with open('/app/scripts/scan_status.json') as f:
        sc = json.load(f)
    counts    = sc.get('counts', {})
    last_scan = sc.get('last_scan', '')[:16].replace('T', ' ')
    c1 = counts.get('list_01', 0)
    c2 = counts.get('list_02', 0)
    c3 = counts.get('list_03', 0)
    c4 = counts.get('list_04', 0)
    c5 = counts.get('list_05', 0)
except:
    c1=c2=c3=c4=c5=0; last_scan='—'

# --- Load paper balance ---
with open('/app/scripts/paper_balance.json') as f:
    d = json.load(f)

trades = d.get('closed_trades', [])
bal    = d.get('balance', 0)
start  = d.get('start_balance', 1000)
pos    = d.get('positions', {})
wins   = [t for t in trades if t['pnl_pct'] > 0]
losses = [t for t in trades if t['pnl_pct'] <= 0]

# total balance incl open positions cost
pos_cost = sum(p.get('cost', 0) for p in pos.values())
total    = bal + pos_cost
pnl      = total - start

pnl_color = GREEN if pnl >= 0 else RED
bal_color = GREEN if bal >= start else RED

# --- Print ---
print(BAR)
print(f"{CYAN}=={RESET}  {YELLOW}  ███ CRYPTO BOT REPORT  {datetime.now().strftime('%Y-%m-%d %H:%M')}  ███  {RESET}  {CYAN}=={RESET}")
print(f"{CYAN}=={RESET}  {WHITE}{exchange:4s}{RESET}  {btc_str}  {market}  {' ' * 10}{CYAN}=={RESET}")
print(BAR)
print(f"  {WHITE}Balance{RESET} : {bal_color}${bal:.2f}{RESET}  {DIM}free  |  total: {pnl_color}${total:.2f}{RESET}  {CYAN}(start: ${start:.2f}){RESET}")
print(f"  {WHITE}PnL    {RESET} : {pnl_color}${pnl:+.2f}  ({pnl/start*100:+.2f}%){RESET}")
print(f"  {WHITE}Trades {RESET} : {YELLOW}{len(trades)}{RESET}  {GREEN}W:{len(wins)}{RESET}  {RED}L:{len(losses)}{RESET}")
print(f"  {WHITE}Скан   {RESET} : {DIM}{last_scan}{RESET}  {CYAN}[{c1}→{c2}→{c3}→{c4}→{c5}]{RESET}")
print(DASH)

# --- Open positions ---
if pos:
    print(f"  {YELLOW}{'ОТКРЫТЫЕ ПОЗИЦИИ':^62}{RESET}")
    print(DASH)
    print(f"  {CYAN}{'Symbol':10s} {'Вход':>10s} {'Кол-во':>12s} {'Cost':>7s} {'Вход':>16s}{RESET}")
    print(DASH)
    for sym, p in pos.items():
        entry  = p.get('entry_price', 0)
        amount = p.get('amount', 0)
        cost   = p.get('cost', 0)
        etime  = p.get('entry_time', '')[-8:]
        g1m    = p.get('growth_1m', 0)
        g15m   = p.get('growth_15m', 0)
        print(f"  {GREEN}▶ {sym[:10]:10s}{RESET} {WHITE}${entry:<9.4f}{RESET} {YELLOW}{amount:>12.2f}{RESET} {WHITE}${cost:>6.0f}{RESET}  {DIM}{etime}{RESET}  1m:{GREEN}{g1m:+.2f}%{RESET} 15m:{GREEN}{g15m:+.2f}%{RESET}")
    print(DASH)

# --- Closed trades ---
if trades:
    print(f"  {CYAN}{'Symbol':10s} {'PnL%':>7s} {'USD':>8s}  {'Reason':18s} {'Min':>4s}  {'Время':>8s}{RESET}")
    print(DASH)
    for t in trades[-15:]:
        sym    = t.get('symbol','')[:10]
        pnlp   = t.get('pnl_pct', 0)
        profit = t.get('profit_usd', 0)
        reason = t.get('reason','')[:18]
        dur    = t.get('duration_min', 0)
        etime  = t.get('exit_time', '')[-8:]
        rc     = GREEN if pnlp > 0 else RED
        flag   = "✔" if pnlp > 0 else "✖"
        print(f"  {rc}{flag} {sym:10s} {pnlp:>+6.2f}% {profit:>+8.2f}  {reason:18s} {dur:>4.1f}  {etime}{RESET}")
else:
    print(f"  {DIM}  Сделок пока нет — ждём кандидатов...{RESET}")

print(BAR)
