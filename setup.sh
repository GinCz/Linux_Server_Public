#!/usr/bin/env bash
# Script:  setup.sh
# Version: v2026-03-17
# Purpose: Universal setup for all server types (222/109/3)
# Usage:   curl -sSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/setup.sh | bash

cd /opt || mkdir -p /opt
git clone https://github.com/GinCz/Linux_Server_Public.git server_tools || git -C server_tools pull
cd server_tools

# Apply aliases based on server type
source shared_aliases.sh
echo "✅ Setup complete. Use 'load' to update, 'save' to commit."
