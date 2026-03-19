#!/usr/bin/env bash
#
# Script: log_303.sh
# Version: v2026-03-19
# Purpose:
#   Capture everything currently visible/scrollable in the terminal
#   and copy it to the LOCAL clipboard via OSC 52 escape sequence.
#   Works in mRemoteNG, Windows Terminal, iTerm2, MobaXterm.
#
# How it works:
#   1. If inside tmux  -> capture full scrollback buffer
#   2. If inside screen -> use hardcopy
#   3. Fallback        -> capture last 500 lines via `script` replay
#      (start logging first with: script /tmp/sess.log, then exit, then 303)
#
# After running:
#   - Text is sent to your LOCAL clipboard via OSC 52
#   - Also saved to /tmp/303_last.txt as backup
#   - Just press Ctrl+V in your browser/chat to paste
#
# Alias in shared_aliases.sh:
#   alias 303='/opt/server_tools/scripts/log_303.sh'
#

# Send data to local clipboard via OSC 52 (works in mRemoteNG / modern terminals)
osc52_copy() {
    local data
    data=$(base64 -w 0 <<< "$1")
    # OSC 52 sequence: ESC ] 52 ; c ; <base64> BEL
    printf "\033]52;c;%s\007" "$data"
}

BACKUP="/tmp/303_last.txt"
LINES=500

# --- Capture source ---
if [ -n "$TMUX" ]; then
    # Best case: tmux - capture full scrollback
    tmux capture-pane -p -J -S -50000 | grep -v '^[[:space:]]*$' > "$BACKUP"
    SOURCE="tmux scrollback"

elif [ -n "$STY" ]; then
    # GNU screen
    TMPF=$(mktemp)
    screen -X hardcopy -h "$TMPF"
    grep -v '^[[:space:]]*$' "$TMPF" > "$BACKUP"
    rm -f "$TMPF"
    SOURCE="screen hardcopy"

elif [ -f "/tmp/sess.log" ]; then
    # Fallback: previously recorded script session
    # Strip terminal control codes, take last N lines
    cat /tmp/sess.log | sed 's/\x1b\[[0-9;]*[mKHfABCDJsr]//g' \
        | sed 's/\r//g' \
        | grep -v '^[[:space:]]*$' \
        | tail -$LINES > "$BACKUP"
    SOURCE="script session /tmp/sess.log"

else
    # No session recorded - show instructions
    clear
    echo "╔══════════════════════════════════════════════════════╗"
    echo "║  303: No capture source found                        ║"
    echo "║                                                      ║"
    echo "║  OPTION 1 (best) - use tmux:                         ║"
    echo "║    tmux new -s main                                  ║"
    echo "║    ... work normally ...                             ║"
    echo "║    303   <- captures everything                      ║"
    echo "║                                                      ║"
    echo "║  OPTION 2 - record session first:                    ║"
    echo "║    script /tmp/sess.log                              ║"
    echo "║    ... do your work ...                              ║"
    echo "║    exit   <- stops recording                         ║"
    echo "║    303    <- copies to clipboard                     ║"
    echo "╚══════════════════════════════════════════════════════╝"
    exit 1
fi

COUNT=$(wc -l < "$BACKUP")
CONTENT=$(cat "$BACKUP")

# --- Send to clipboard via OSC 52 ---
osc52_copy "$CONTENT"

# --- Report ---
clear
echo "✅ 303 DONE — $COUNT lines copied to clipboard"
echo "📋 Source : $SOURCE"
echo "💾 Backup : $BACKUP"
echo ""
echo "👉 Now press Ctrl+V in your browser/chat to paste"
echo ""
echo "--- PREVIEW (last 20 lines) ---"
tail -20 "$BACKUP"
echo "--- END PREVIEW ---"
