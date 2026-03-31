# tr_report.py - v2026-03-31
# = Rooted by VladiMIR | AI =
import json
from datetime import datetime

# --- ANSI colors ---
CYAN   = "\033[1;36m"
YELLOW = "\033[1;33m"
GREEN  = "\033[1;32m"
RED    = "\033[1;31m"
WHITE  = "\033[1;37m"
RESET  = "\033[0m"

BAR  = CYAN + "=" * 62 + RESET
DASH = CYAN + "-" * 62 + RESET

with open('/app/scripts/paper_balance.json') as f:
    d = json.load(f)

trades = d.get('closed_trades', [])
bal    = d.get('balance', 0)
start  = d.get('start_balance', 1000)
pnl    = bal - start
pos    = d.get('positions', {})
wins   = [t for t in trades if t['pnl_pct'] > 0]
losses = [t for t in trades if t['pnl_pct'] <= 0]

pnl_color  = GREEN if pnl >= 0 else RED
bal_color  = GREEN if bal >= start else RED

print(BAR)
print(f"{CYAN}=={RESET}  {YELLOW}  ███ CRYPTO BOT REPORT  {datetime.now().strftime('%Y-%m-%d %H:%M')}  ███  {RESET}  {CYAN}=={RESET}")
print(BAR)
print(f"  {WHITE}Balance{RESET} : {bal_color}${bal:.2f}{RESET}  {CYAN}(start: ${start:.2f}){RESET}")
print(f"  {WHITE}PnL    {RESET} : {pnl_color}${pnl:+.2f}  ({pnl/start*100:+.2f}%){RESET}")
print(f"  {WHITE}Trades {RESET} : {YELLOW}{len(trades)}{RESET}  {GREEN}W:{len(wins)}{RESET}  {RED}L:{len(losses)}{RESET}")
open_str = ', '.join(pos.keys()) if pos else f"{CYAN}—нет—{RESET}"
print(f"  {WHITE}Open   {RESET} : {YELLOW}{open_str}{RESET}")
print(DASH)
print(f"  {CYAN}{'Symbol':12s} {'PnL%':>7s} {'USD':>8s}  {'Reason':22s} {'Min':>4s}{RESET}")
print(DASH)
for t in trades[-20:]:
    sym    = t.get('symbol','')[:12]
    pnlp   = t.get('pnl_pct', 0)
    profit = t.get('profit_usd', 0)
    reason = t.get('reason','')[:22]
    dur    = t.get('duration_min', 0)
    if pnlp > 0:
        row_color = GREEN
        flag = "✔ "
    else:
        row_color = RED
        flag = "✖ "
    print(f"  {row_color}{flag}{sym:12s} {pnlp:>+6.2f}% {profit:>+8.2f}  {reason:22s} {dur:>4.1f}{RESET}")
print(BAR)
