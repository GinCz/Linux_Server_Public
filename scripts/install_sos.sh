#!/usr/bin/env bash
# =============================================================
# Script:      install_sos.sh
# Version:     v2026.05.20b
# Location:    scripts/install_sos.sh
# Servers:     222-DE-NetCup / 109-RU-FastVDS (FastPanel web servers)
# Description: Install sos-fastpanel.sh to /usr/local/bin/sos
#              and register aliases in ~/.bashrc.
#              Run once per server after git pull or fresh clone.
# Usage:       bash ~/Linux_Server_Public/scripts/install_sos.sh
# = Rooted by VladiMIR + AI | v2026.05.20b | github.com/GinCz =
# =============================================================

clear

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Installing sos to /usr/local/bin/sos ==="
cp "$SCRIPT_DIR/sos-fastpanel.sh" /usr/local/bin/sos
chmod +x /usr/local/bin/sos
echo "OK: /usr/local/bin/sos"

# Add aliases to ~/.bashrc if not already there
if grep -q "alias sos120" ~/.bashrc 2>/dev/null; then
  echo "OK: aliases already in ~/.bashrc — skipping"
else
  echo "" >> ~/.bashrc
  echo "# ── SOS — server health monitor (added by install_sos.sh) ───" >> ~/.bashrc
  echo "alias sos='sos 1h'" >> ~/.bashrc
  echo "alias sos1='sos 1h'" >> ~/.bashrc
  echo "alias sos3='sos 3h'" >> ~/.bashrc
  echo "alias sos24='sos 24h'" >> ~/.bashrc
  echo "alias sos120='sos 120h'" >> ~/.bashrc
  echo "OK: aliases added to ~/.bashrc"
fi

echo ""
echo "=== Done! Run: source ~/.bashrc ==="
echo ""
echo "  Commands available:"
echo "    sos      -> sos 1h  (default)"
echo "    sos1     -> sos 1h"
echo "    sos3     -> sos 3h"
echo "    sos24    -> sos 24h"
echo "    sos120   -> sos 120h  (5 days)"
echo ""
