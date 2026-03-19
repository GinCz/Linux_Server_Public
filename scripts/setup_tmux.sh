#!/usr/bin/env bash
# Script:  setup_tmux.sh
# Version: v2026-03-19
# Purpose: Install tmux and configure it to auto-start on every SSH login.
#          After this, alias 303 captures full scrollback and copies to clipboard.
# Usage:   bash /opt/server_tools/scripts/setup_tmux.sh

clear
echo "====================================================="
echo " TMUX AUTO-START SETUP v2026-03-19"
echo "====================================================="

# 1. Install tmux
echo "[1/4] Installing tmux..."
apt-get update -qq
apt-get install -y tmux > /dev/null 2>&1
echo "      OK: $(tmux -V)"

# 2. Create /root/.tmux.conf with good defaults
echo "[2/4] Writing /root/.tmux.conf..."
cat > /root/.tmux.conf << 'TMUXCONF'
# Scrollback buffer - keep 50000 lines (enough for any session)
set -g history-limit 50000

# Status bar
set -g status-bg colour235
set -g status-fg colour250
set -g status-left "[#h] "
set -g status-right "%d.%m.%Y %H:%M"
set -g status-interval 5

# Mouse support (scroll with mouse wheel)
set -g mouse on

# Start windows and panes at 1, not 0
set -g base-index 1
setw -g pane-base-index 1

# No delay for escape key
set -sg escape-time 0
TMUXCONF
echo "      OK"

# 3. Add auto-start to /root/.bashrc
#    - Only starts tmux if: interactive shell + not already inside tmux + SSH session
echo "[3/4] Adding tmux auto-start to /root/.bashrc..."
BASHRC="/root/.bashrc"
MARKER="# === TMUX AUTO-START (setup_tmux.sh) ==="

if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    echo "      Already configured, skipping."
else
    cat >> "$BASHRC" << 'BASHBLOCK'

# === TMUX AUTO-START (setup_tmux.sh) ===
# Auto-attach or create tmux session named 'main' on every SSH login
if [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]] && [[ $- == *i* ]]; then
    tmux new-session -A -s main
fi
# === END TMUX AUTO-START ===
BASHBLOCK
    echo "      OK: added to $BASHRC"
fi

# 4. Apply now for current session hint
echo "[4/4] Done!"
echo ""
echo "====================================================="
echo " RESULT"
echo "====================================================="
echo " tmux will auto-start on every NEW SSH connection."
echo " Current session: reconnect SSH to activate."
echo ""
echo " HOW TO USE 303:"
echo "   - Connect via SSH (tmux starts automatically)"
echo "   - Work normally, run any commands"
echo "   - Type: 303"
echo "   - All terminal text copied to clipboard"
echo "   - Press Ctrl+V in browser/chat to paste"
echo ""
echo " USEFUL TMUX KEYS:"
echo "   Ctrl+B, D    = detach (session keeps running)"
echo "   Ctrl+B, [    = scroll mode (q to exit)"
echo "   tmux ls      = list sessions"
echo "   tmux a       = re-attach"
echo "====================================================="
