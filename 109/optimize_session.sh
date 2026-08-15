#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  optimize_session.sh | [v2026-05-01]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : PHP session garbage collector cleanup
# Servers     : 109-RU FastVDS
# Usage       : bash 109/optimize_session.sh
# ==========================================================================================
apt-get clean && apt-get autoremove -y && journalctl --vacuum-time=3d; find /etc/php/*/fpm/php.ini -exec sed -i 's/^session.gc_maxlifetime.*/session.gc_maxlifetime = 250000/' {} \+; ls /etc/php/ -1 | xargs -I {} systemctl restart php{}-fpm 2>/dev/null; echo "PHP Sessions extended to 250000. System cleaned."

# = Rooted by VladiMIR | AI = v2026-05-01 = github.com/GinCz/Linux_Server_Public
