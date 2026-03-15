#!/usr/bin/env bash
# Description: Clean OS caches and set safe PHP-FPM limits (8) across all sites
clear
echo -e "\033[1;33m--- 1. CLEANING SYSTEM ---\033[0m"
apt-get clean && apt-get autoremove -y && journalctl --vacuum-time=3d

echo -e "\033[1;33m--- 2. OPTIMIZING PHP LIMITS (SAFE MODE: 8 CHILDREN) ---\033[0m"
find /etc/php/*/fpm/pool.d/ -name "*.conf" -exec sed -i 's/^pm.max_children =.*/pm.max_children = 8/' {} \+
find /etc/php/*/fpm/pool.d/ -name "*.conf" -exec sed -i 's/^pm.process_idle_timeout =.*/pm.process_idle_timeout = 10s/' {} \+

echo -e "\033[1;33m--- 3. RESTARTING SERVICES ---\033[0m"
ls /etc/php/ -1 | xargs -I {} systemctl restart php{}-fpm 2>/dev/null
nginx -t && systemctl reload nginx
echo -e "\033[1;32mDONE! System cleaned and PHP safely optimized.\033[0m"
