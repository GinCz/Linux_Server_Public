#!/usr/bin/env python3
# =============================================================================
# app_patch_trade_mode.py
# Patch to add to app.py: API route /api/set_trade_mode
# Version  : v2026-04-08
# = Rooted by VladiMIR | AI =
# =============================================================================
# Add this route to your existing app.py:

"""
@app.route('/api/set_trade_mode', methods=['POST'])
def set_trade_mode():
    if not auth(): return jsonify({'error': 'unauthorized'}), 401
    data = request.get_json()
    mode = data.get('mode', 'trade60')
    if mode not in ('trade60', 'trade15'):
        return jsonify({'ok': False, 'error': 'invalid mode'})
    cfg = load_config()
    cfg['trade_mode'] = mode
    save_config(cfg)
    return jsonify({'ok': True, 'trade_mode': mode})
"""

# And also add 'trade_mode' to the allowed list in api_settings():
# allowed = [..., 'trade_mode']

print('Read this file and manually patch app.py with the route above.')
print('Or use the full patched app.py provided in crypto/app.py')
