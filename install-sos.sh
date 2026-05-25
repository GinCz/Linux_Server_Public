#!/usr/bin/env bash
# = Rooted by VladiMIR + AI | v.2026.05.25 | github.com/GinCz =
# SOS installer — downloads sos.sh from GitHub and sets up alias
clear

RAW="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh"
DEST="/usr/local/bin/sos"

echo "[1/4] Downloading sos.sh..."
curl -fsSL "$RAW" -o "$DEST" || { echo "ERROR: curl failed"; exit 1; }

echo "[2/4] Setting permissions..."
chmod +x "$DEST"

echo "[3/4] Testing syntax..."
bash -n "$DEST" || { echo "ERROR: syntax check failed"; exit 1; }

echo "[4/4] Done!"
echo ""
echo "  Run:  sos          # default 1h window"
echo "  Run:  sos 30m      # last 30 minutes"
echo "  Run:  sos 6h       # last 6 hours"
echo ""
echo "= Rooted by VladiMIR + AI | v.2026.05.25 | github.com/GinCz ="
