#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  install_panel.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : FastPanel installer wrapper with automated presets
# Servers     : Debian / Ubuntu 24
# Usage       : bash scripts/install_panel.sh
# ==========================================================================================
wget -qO- http://repo.fastpanel.direct/install_fastpanel.sh | bash -s -- -m mariadb10.11; ufw allow 20,21,25,80,110,443,465,587,993,995,8888/tcp; ufw status; I=$(hostname -I | awk '{print $1}'); echo "DONE: https://$I:8888"

echo "========================================="

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
