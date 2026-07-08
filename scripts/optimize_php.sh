#!/usr/bin/env bash
# =============================================================================
# optimize_php.sh — Clean OS caches, set safe PHP-FPM limits and extend sessions
# = Rooted by VladiMIR + AI | v.2026.07.04 | github.com/GinCz =
# =============================================================================

clear

Y='\033[1;33m'; G='\033[1;32m'; X='\033[0m'

echo -e "${Y}--- 1. CLEANING SYSTEM ---${X}"
apt-get clean && apt-get autoremove -y && journalctl --vacuum-time=3d

echo -e "${Y}--- 2. OPTIMIZING PHP-FPM LIMITS (SAFE MODE: 8 CHILDREN) ---${X}"
find /etc/php/*/fpm/pool.d/ -name "*.conf" -exec sed -i \
  's/^pm.max_children =.*/pm.max_children = 8/' {} \+
find /etc/php/*/fpm/pool.d/ -name "*.conf" -exec sed -i \
  's/^pm.process_idle_timeout =.*/pm.process_idle_timeout = 10s/' {} \+

echo -e "${Y}--- 3. EXTENDING PHP SESSION LIFETIME (session.gc_maxlifetime) ---${X}"
find /etc/php/*/fpm/php.ini -exec sed -i \
  's/^session.gc_maxlifetime.*/session.gc_maxlifetime = 250000/' {} \+

echo -e "${Y}--- 4. RESTARTING SERVICES ---${X}"
ls /etc/php/ -1 | xargs -I {} systemctl restart php{}-fpm 2>/dev/null
nginx -t && systemctl reload nginx

echo -e "${G}DONE! System cleaned, PHP-FPM safely optimized and sessions extended.${X}"
