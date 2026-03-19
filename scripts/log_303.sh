#!/usr/bin/env bash
# Script:  log_303.sh
# Version: v2026-03-19
# Purpose: Capture full terminal scrollback and copy to LOCAL clipboard.
#          Works automatically when tmux is running (setup via setup_tmux.sh).
#          Supports mRemoteNG, Windows Terminal, iTerm2, MobaXterm via OSC 52.
# Usage:   303
#
# REQUIREMENTS: run setup_tmux.sh once per server first.

clear

BACKUP="/tmp/303_last.txt"
MAX_LINES=5000

# ---- Step 1: Capture scrollback ----
if [ -n "$TMUX" ]; then
    # tmux: capture full scrollback buffer (up to history-limit lines)
    tmux capture-pane -p -J -S -$MAX_LINES 2>/dev/null \
        | sed '/^[[:space:]]*$/d' \
        > "$BACKUP"
    SOURCE="tmux"

elif [ -n "$STY" ]; then
    # GNU screen fallback
    TMPF=$(mktemp)
    screen -X hardcopy -h "$TMPF"
    sed '/^[[:space:]]*$/d' "$TMPF" > "$BACKUP"
    rm -f "$TMPF"
    SOURCE="screen"

else
    # Not in tmux - show setup instructions
    echo ""
    echo "  \u274c 303 requires tmux to capture terminal output."
    echo ""
    echo "  Run once to set up automatic tmux on SSH login:"
    echo ""
    echo "    bash /opt/server_tools/scripts/setup_tmux.sh"
    echo ""
    echo "  Then reconnect via SSH - tmux starts automatically."
    echo "  After that, 303 will work every time with no preparation."
    echo ""
    exit 1
fi

COUNT=$(wc -l < "$BACKUP")

if [ "$COUNT" -eq 0 ]; then
    echo "\u26a0\ufe0f  303: nothing captured. Is tmux running?"
    exit 1
fi

# ---- Step 2: Send to clipboard via OSC 52 ----
# OSC 52 tells the terminal emulator to put data into system clipboard.
# Supported by: Windows Terminal, iTerm2, MobaXterm, mRemoteNG (PuTTY mode may need
# AllowSetSelection=yes in PuTTY settings or use Windows Terminal profile in mRemoteNG).
CONTENT=$(cat "$BACKUP")
B64=$(printf '%s' "$CONTENT" | base64 -w 0)
printf "\033]52;c;%s\007" "$B64"

# ---- Step 3: Report ----
echo "\u2705 303 DONE"
echo "\u2514 $COUNT lines captured from $SOURCE scrollback"
echo "\u2514 Saved backup: $BACKUP"
echo ""
echo "\u25b6 Press Ctrl+V in your browser or chat to paste."
echo ""
echo "--- LAST 10 LINES PREVIEW ---"
tail -10 "$BACKUP"
echo "--- END ---"
