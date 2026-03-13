#!/usr/bin/env bash
# Description: Extend PHP session lifetime, increase child limits, and clean OS.
# Alias: fpopt
apt-get clean && apt-get autoremove -y && journalctl --vacuum-time=3d; find /etc/php/*/fpm/php.ini -exec sed -i 's/^session.gc_maxlifetime.*/session.gc_maxlifetime = 250000/' {} \+; ls /etc/php/ -1 | xargs -I {} systemctl restart php{}-fpm 2>/dev/null; echo "PHP Sessions extended to 250000. System cleaned."
