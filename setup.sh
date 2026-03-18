#!/usr/bin/env bash
# Script:  setup.sh
# Version: v2026-03-18
# Purpose: Universal one-command setup for any new Ubuntu server
# Usage:   curl -sSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/setup.sh | bash

clear
echo "--- SETUP START ---"

# 1. Clone or update repo
mkdir -p /opt
if [ -d /opt/server_tools/.git ]; then
    cd /opt/server_tools
    git fetch --all && git reset --hard origin/main && git clean -fd
else
    git clone https://github.com/GinCz/Linux_Server_Public.git /opt/server_tools
    cd /opt/server_tools
fi

# 2. Make all scripts executable
chmod +x scripts/*.sh

# 3. Add permanent source to root .bashrc
BASHRC="/root/.bashrc"
grep -q "server_tools/shared_aliases" "$BASHRC" || \
    echo "source /opt/server_tools/shared_aliases.sh" >> "$BASHRC"

# 4. Symlinks for load/save as global commands
ln -sf /opt/server_tools/scripts/load.sh /usr/local/bin/load
ln -sf /opt/server_tools/scripts/save.sh /usr/local/bin/save

# 5. Apply aliases immediately in current session
source /opt/server_tools/shared_aliases.sh

echo "OK: Setup complete!"
echo "Commands: load / save / infooo / sos / fight / domains / backup"
exec bash
