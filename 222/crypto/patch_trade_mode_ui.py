#!/usr/bin/env python3
# =============================================================================
# patch_trade_mode_ui.py
# Version : v2026-04-08
# Патчит /app/templates/index.html + /app/app.py в контейнере crypto-bot:
#   1. Добавляет кнопки Trade60 / Trade15 в панель НАСТРОЙКИ
#   2. Добавляет /api/set_trade_mode POST в app.py
#   3. Обновляет updateTradeModeUI() в loadData()
# Запуск: python3 patch_trade_mode_ui.py
# = Rooted by VladiΜIR | AI =
# =============================================================================

import re, sys

INDEX = '/app/templates/index.html'
APP   = '/app/app.py'

# ---------------------------------------------------------------------------
# 1. PATCH index.html
# ---------------------------------------------------------------------------
with open(INDEX, 'r', encoding='utf-8') as f:
    html = f.read()

# -- 1a. CSS for trade mode buttons (insert before </style>) ----------------
CSS_TRADE = '''
/* Trade Mode Switcher */
.trade-mode-btn{
  flex:1;padding:10px 6px;border-radius:8px;border:2px solid var(--border);
  background:var(--bg3);color:var(--muted);font-weight:700;cursor:pointer;
  font-size:20px;transition:.2s;text-align:center;line-height:1.3;
}
.trade-mode-btn.active60{border-color:var(--green);background:var(--green);color:#000;}
.trade-mode-btn.active15{border-color:var(--orange);background:var(--orange);color:#000;}
.trade-mode-btn:hover{opacity:.85;}
'''

if '.trade-mode-btn' not in html:
    html = html.replace('</style>', CSS_TRADE + '</style>', 1)
    print('[OK] CSS вставлен')
else:
    print('[SKIP] CSS уже есть')

# -- 1b. HTML buttons (insert at top of SETTINGS card, after card-title) ----
BTNS_HTML = '''  <div style="display:flex;gap:8px;margin-bottom:14px">
    <button class="trade-mode-btn" id="btn-trade60" onclick="setTradeMode('trade60')">
      ⏱ Trade60<br><small style="font-size:15px">1h+15m+1m live</small>
    </button>
    <button class="trade-mode-btn" id="btn-trade15" onclick="setTradeMode('trade15')">
      ⚡ Trade15<br><small style="font-size:15px">15m+1m live</small>
    </button>
  </div>
'''

# Anchor: the SETTINGS card-title line
ANCHOR_HTML = '<div class="card-title">&#x2699;&#xFE0F; &#1053;&#1040;&#1057;&#1058;&#1056;&#1054;&#1049;&#1050;&#1048;</div>'

if 'btn-trade60' not in html:
    html = html.replace(ANCHOR_HTML, ANCHOR_HTML + '\n' + BTNS_HTML, 1)
    print('[OK] Кнопки Trade60/Trade15 вставлены')
else:
    print('[SKIP] Кнопки уже есть')

# -- 1c. JS functions (insert before </script> at end) ----------------------
JS_TRADE = '''
function updateTradeModeUI(mode) {
  var b60 = document.getElementById('btn-trade60');
  var b15 = document.getElementById('btn-trade15');
  if (!b60 || !b15) return;
  b60.className = 'trade-mode-btn' + (mode === 'trade60' ? ' active60' : '');
  b15.className = 'trade-mode-btn' + (mode === 'trade15' ? ' active15' : '');
}
async function setTradeMode(mode) {
  var r = await fetch('/api/set_trade_mode', {
    method:'POST',
    headers:{'Content-Type':'application/json'},
    body: JSON.stringify({mode: mode})
  });
  var d = await r.json();
  if (d.ok) {
    updateTradeModeUI(mode);
    var msg = document.getElementById('save-msg');
    if (msg) { msg.style.display='block'; msg.textContent='\u2705 Mode: '+mode; setTimeout(()=>{msg.style.display='none';},2000); }
  }
}
'''

if 'setTradeMode' not in html:
    # Insert before the last </script>
    html = html[::-1].replace('>tpircs/<'[::-1], (JS_TRADE + '</script>')[::-1], 1)[::-1]
    print('[OK] JS функции вставлены')
else:
    print('[SKIP] JS уже есть')

# -- 1d. Hook updateTradeModeUI into loadData --------------------------------
# Find: applyToForm(data.config)  ->  add updateTradeModeUI after it
if 'updateTradeModeUI' not in html or 'applyToForm' in html and 'updateTradeModeUI(d' not in html:
    html = html.replace(
        'applyToForm(data.config)',
        'applyToForm(data.config); updateTradeModeUI(data.config.trade_mode || \'trade60\');',
        1
    )
    print('[OK] Hook в loadData вставлен')
else:
    print('[SKIP] Hook уже есть')

with open(INDEX, 'w', encoding='utf-8') as f:
    f.write(html)
print('[OK] index.html сохранён')

# ---------------------------------------------------------------------------
# 2. PATCH app.py — add /api/set_trade_mode if not present
# ---------------------------------------------------------------------------
with open(APP, 'r', encoding='utf-8') as f:
    app_src = f.read()

NEW_ROUTE = """
@app.route('/api/set_trade_mode', methods=['POST'])
def api_set_trade_mode():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    data = request.json or {}
    mode = data.get('mode', 'trade60')
    if mode not in ('trade60', 'trade15'):
        return jsonify({'error': 'invalid mode'}), 400
    cfg = load_config()
    cfg['trade_mode'] = mode
    save_config(cfg)
    return jsonify({'ok': True, 'trade_mode': mode})
"""

if 'api_set_trade_mode' not in app_src:
    # Insert before the last app.run or end of file
    if 'if __name__' in app_src:
        app_src = app_src.replace("if __name__", NEW_ROUTE + "\nif __name__", 1)
    else:
        app_src += NEW_ROUTE
    with open(APP, 'w', encoding='utf-8') as f:
        f.write(app_src)
    print('[OK] /api/set_trade_mode добавлен в app.py')
else:
    print('[SKIP] /api/set_trade_mode уже есть')

print()
print('=== ГОТ;&#1054;&#1042;&#1054;! Перезапусти Flask: ===')
print('docker exec crypto-bot pkill -f "python.*app.py"')
print('docker exec -d crypto-bot python3 /app/app.py')
