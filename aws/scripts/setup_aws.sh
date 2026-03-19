#!/usr/bin/env bash
# Script:  setup_aws.sh
# Version: v2026-03-19
# Purpose: One-command setup for AWS EC2 Ubuntu server.
#          Installs server_tools, tmux, configures aliases and 303.
# Usage:   curl -s https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/aws/scripts/setup_aws.sh | sudo bash
# User:    ubuntu (sudo required)

clear
echo "====================================================="
echo " AWS SERVER SETUP v2026-03-19"
echo "====================================================="
echo ""

SERVER_TOOLS="/opt/server_tools"
BASHRC="/home/ubuntu/.bashrc"

# 1. Install/update server_tools in correct location
echo "[1/5] Setting up /opt/server_tools..."
if [ -d "$SERVER_TOOLS/.git" ]; then
    echo "      Already a git repo - pulling latest..."
    git config --global --add safe.directory "$SERVER_TOOLS" 2>/dev/null
    cd "$SERVER_TOOLS" && git fetch origin && git reset --hard origin/main
else
    echo "      Cloning from GitHub into $SERVER_TOOLS ..."
    rm -rf "$SERVER_TOOLS"
    git clone https://github.com/GinCz/Linux_Server_Public.git "$SERVER_TOOLS"
fi
git config --global --add safe.directory "$SERVER_TOOLS" 2>/dev/null
chmod -R 755 "$SERVER_TOOLS"
echo "      OK"

# 2. Install tmux
echo "[2/5] Installing tmux..."
apt-get update -qq
apt-get install -y tmux > /dev/null 2>&1
echo "      OK: $(tmux -V)"

# 3. Write tmux config for ubuntu user
echo "[3/5] Writing /home/ubuntu/.tmux.conf..."
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
chown ubuntu:ubuntu /home/ubuntu/.tmux.conf
echo "      OK"

# 4. Add aliases + tmux autostart to ubuntu .bashrc
echo "[4/5] Configuring aliases in $BASHRC..."
MARKER="# === SERVER TOOLS AWS ==="
if grep -q "$MARKER" "$BASHRC" 2>/dev/null; then
    echo "      Already configured."
else
    cat >> "$BASHRC" << 'BASHBLOCK'

# === SERVER TOOLS AWS ===
git config --global --add safe.directory /opt/server_tools 2>/dev/null
source /opt/server_tools/scripts/aws/shared_aliases_aws.sh 2>/dev/null

# tmux auto-start on SSH login
if [[ -z "$TMUX" ]] && [[ -n "$SSH_CONNECTION" ]] && [[ $- == *i* ]]; then
    tmux new-session -A -s main
fi
# === END SERVER TOOLS AWS ===
BASHBLOCK
    chown ubuntu:ubuntu "$BASHRC"
    echo "      OK: added to $BASHRC"
fi

# 5. Done
echo "[5/5] Done!"
echo ""
echo "====================================================="
echo " SETUP COMPLETE!"
echo "====================================================="
echo ""
echo "  NEXT: Reconnect SSH as ubuntu - tmux + aliases auto-load."
echo ""
echo "  Quick commands after reconnect:"
echo "    303          = copy terminal scrollback to clipboard"
echo "    infooo       = server info"
echo "    load         = reload aliases"
echo "    bot-deploy   = deploy crypto bot"
echo "    bot-log      = watch bot log live"
echo "    antivir      = run ClamAV scan"
echo "====================================================="
