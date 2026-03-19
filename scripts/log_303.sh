#!/usr/bin/env bash
# Script:  log_303.sh
# Version: v2026-03-19
# Purpose: Capture full terminal scrollback and copy to LOCAL clipboard.
#          SELF-INSTALLING: installs tmux and configures auto-start on first run.
#          Supports mRemoteNG, Windows Terminal, iTerm2, MobaXterm via OSC 52.
# Usage:   303

clear

SCRIPTS_DIR="/opt/server_tools/scripts"
BACKUP="/tmp/303_last.txt"
MAX_LINES=5000

# ============================================================
# SELF-INSTALL: if tmux not running - install everything now
# ============================================================
if [ -z "$TMUX" ]; then

    echo "====================================================="
    echo " 303 SETUP v2026-03-19"
    echo "====================================================="
    echo ""

    # 1. Install tmux if missing
    if ! command -v tmux &>/dev/null; then
        echo "[1/3] Installing tmux..."
        apt-get update -qq && apt-get install -y tmux > /dev/null 2>&1
        echo "      OK: $(tmux -V)"
    else
        echo "[1/3] tmux already installed: $(tmux -V)"
    fi

    # 2. Write ~/.tmux.conf
    echo "[2/3] Writing /root/.tmux.conf..."
    cat > /root/.tmux.conf << 'TMUXCONF'
set -g history-limit 50000
set -g status-bg colour235
set -g status-fg colour250
set -g status-left "[#h] "
set -g status-right "%d.%m.%Y %H:%M"
set -g status-interval 5
set -g mouse on
set -g base-index 1
setw -g pane-base-index 1
set -sg escape-time 0
TMUXCONF
    echo "      OK"

    # 3. Add auto-start to ~/.bashrc (only once)
    echo "[3/3] Configuring tmux auto-start on SSH login..."
    BASHRC="/root/.bashrc"
    MARKER="# === TMUX AUTO-START ==="
    if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
        echo "      Already configured."
    else
        cat >> "$BASHRC" << 'BASHBLOCK'

# === TMUX AUTO-START ===
if [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]] && [[ $- == *i* ]]; then
    tmux new-session -A -s main
fi
# === END TMUX AUTO-START ===
BASHBLOCK
        echo "      OK: added to $BASHRC"
    fi

    echo ""
    echo "====================================================="
    echo " SETUP COMPLETE!"
    echo "====================================================="
    echo ""
    echo "  Reconnect SSH - tmux will start automatically."
    echo "  Then type: 303"
    echo ""
    echo "  TMUX KEYS:"
    echo "    Ctrl+B, D  = detach (session keeps running)"
    echo "    Ctrl+B, [  = scroll mode (q to exit)"
    echo "    tmux ls    = list sessions"
    echo "    tmux a     = re-attach"
    echo "====================================================="
    echo ""
    exit 0
fi

# ============================================================
# MAIN: we are inside tmux - capture scrollback
# ============================================================
tmux capture-pane -p -J -S -$MAX_LINES 2>/dev/null \
    | sed '/^[[:space:]]*$/d' \
    > "$BACKUP"

COUNT=$(wc -l < "$BACKUP")

if [ "$COUNT" -eq 0 ]; then
    echo "\u26a0\ufe0f  303: nothing captured. Is tmux session active?"
    exit 1
fi

# Send to clipboard via OSC 52
CONTENT=$(cat "$BACKUP")
B64=$(printf '%s' "$CONTENT" | base64 -w 0)
printf "\033]52;c;%s\007" "$B64"

echo "\u2705 303 DONE"
echo "\u2514 $COUNT lines captured from tmux scrollback"
echo "\u2514 Saved to: $BACKUP"
echo ""
echo "\u25b6 Press Ctrl+V in browser or chat to paste."
echo ""
echo "--- LAST 10 LINES PREVIEW ---"
tail -10 "$BACKUP"
echo "--- END ---"
