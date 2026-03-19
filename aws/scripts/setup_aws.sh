#!/usr/bin/env bash
# Script:  setup_aws.sh
# Version: v2026-03-19
# Purpose: One-command setup for AWS EC2 Ubuntu server.
#          Installs server_tools, tmux, configures aliases and 303.
# Usage:   bash setup_aws.sh
# User:    ubuntu (sudo required)

clear
echo "====================================================="
echo " AWS SERVER SETUP v2026-03-19"
echo "====================================================="
echo ""

SERVER_TOOLS="/opt/server_tools"
BASHRC="/home/ubuntu/.bashrc"

# 1. Install server_tools
echo "[1/5] Setting up /opt/server_tools..."
if [ -d "$SERVER_TOOLS/.git" ]; then
    echo "      Already a git repo - pulling latest..."
    cd "$SERVER_TOOLS" && sudo git fetch origin && sudo git reset --hard origin/main
else
    echo "      Cloning from GitHub..."
    sudo rm -rf "$SERVER_TOOLS"
    sudo git clone https://github.com/GinCz/Linux_Server_Public.git "$SERVER_TOOLS"
fi
sudo chmod -R 755 "$SERVER_TOOLS"
echo "      OK"

# 2. Install tmux
echo "[2/5] Installing tmux..."
sudo apt-get update -qq
sudo apt-get install -y tmux > /dev/null 2>&1
echo "      OK: $(tmux -V)"

# 3. Write tmux config
echo "[3/5] Writing ~/.tmux.conf..."
cat > /home/ubuntu/.tmux.conf << 'TMUXCONF'
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

# 4. Add aliases to .bashrc
echo "[4/5] Configuring aliases..."
MARKER="# === SERVER TOOLS AWS ==="
if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    echo "      Already configured."
else
    cat >> "$BASHRC" << 'BASHBLOCK'

# === SERVER TOOLS AWS ===
source /opt/server_tools/scripts/shared_aliases_aws.sh 2>/dev/null

# tmux auto-start on SSH login
if [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]] && [[ $- == *i* ]]; then
    tmux new-session -A -s main
fi
# === END SERVER TOOLS AWS ===
BASHBLOCK
    echo "      OK: added to $BASHRC"
fi

# 5. Done
echo "[5/5] Done!"
echo ""
echo "====================================================="
echo " SETUP COMPLETE!"
echo "====================================================="
echo ""
echo "  Reconnect SSH - tmux + aliases will load automatically."
echo "  Then type: 303 (to capture terminal to clipboard)"
echo ""
echo "  Quick commands after reconnect:"
echo "    303        = copy terminal to clipboard"
echo "    infooo     = server info"
echo "    load       = reload aliases"
echo "====================================================="
