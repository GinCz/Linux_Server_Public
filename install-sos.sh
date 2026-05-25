#!/usr/bin/env bash
# = Rooted by VladiMIR + AI | v.2026.05.26 | github.com/GinCz =
# SOS installer — force update sos.sh + setup aliases
clear

RAW="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/sos.sh"
DEST="/usr/local/bin/sos"
BASHRC="/root/.bashrc"

echo "[1/5] Downloading sos.sh (force update)..."
curl -fsSL "$RAW" -o "$DEST" || { echo "ERROR: curl failed"; exit 1; }

echo "[2/5] Setting permissions..."
chmod +x "$DEST"

echo "[3/5] Testing syntax..."
bash -n "$DEST" || { echo "ERROR: syntax check failed"; exit 1; }

echo "[4/5] Setting up aliases..."
for ALIAS in \
  "alias sos='sos 1h'" \
  "alias sos30='sos 30m'" \
  "alias sos6='sos 6h'" \
  "alias sos24='sos 24h'"; do
  KEY=$(echo "$ALIAS" | grep -oP "alias \K[^=]+")
  sed -i "/alias ${KEY}=/d" "$BASHRC" 2>/dev/null
  echo "$ALIAS" >> "$BASHRC"
done

source "$BASHRC" 2>/dev/null || true

echo "[5/5] Done!"
echo ""
echo "  sos      => sos 1h   (last 1 hour)"
echo "  sos30    => sos 30m  (last 30 minutes)"
echo "  sos6     => sos 6h   (last 6 hours)"
echo "  sos24    => sos 24h  (last 24 hours)"
echo "  sos 2h   => custom window"
echo ""
echo "  NOTE: run 'source ~/.bashrc' or reconnect SSH for aliases to take effect"
echo ""
echo "= Rooted by VladiMIR + AI | v.2026.05.26 | github.com/GinCz ="
