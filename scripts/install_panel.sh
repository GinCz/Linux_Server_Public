#!/usr/bin/env bash
# Script:  install_panel.sh
# Version: v2026-03-17
# Purpose: Install FastPanel with MariaDB 10.11, open UFW ports,
#          install extra packages, and optimize PHP-FPM.
#          Run on a clean Ubuntu 24.04 server before setup.sh.
# Usage:   /opt/server_tools/scripts/install_panel.sh
# License: https://cp.fastpanel.direct/order/panel/license
# WARNING: Run only on a CLEAN server — overwrites web server configuration.

clear
Y='\033[1;33m'; G='\033[1;32m'; X='\033[0m'

# 1. Install FastPanel with MariaDB 10.11
echo -e "${Y}>>> Installing FastPanel with MariaDB 10.11...${X}"
wget -qO- http://repo.fastpanel.direct/install_fastpanel.sh | bash -s -- -m mariadb10.11

# 2. Open required UFW ports
echo -e "${Y}>>> Configuring UFW firewall...${X}"
ufw allow 20,21,25,80,110,443,465,587,993,995,8888/tcp
ufw status

# 3. Install extra packages
echo -e "${Y}>>> Installing additional packages...${X}"
apt install -y bind9 redis memcached fail2ban php8.4 quota

# 4. Optimize PHP-FPM (safe mode: 8 children per pool)
echo -e "${Y}>>> Optimizing PHP-FPM limits...${X}"
apt-get clean && apt-get autoremove -y
journalctl --vacuum-time=3d

find /etc/php/*/fpm/pool.d/ -name "*.conf" \
    -exec sed -i 's/^pm.max_children =.*/pm.max_children = 8/' {} \+
find /etc/php/*/fpm/pool.d/ -name "*.conf" \
    -exec sed -i 's/^pm.process_idle_timeout =.*/pm.process_idle_timeout = 10s/' {} \+

ls /etc/php/ | xargs -I {} systemctl restart php{}-fpm 2>/dev/null || true
nginx -t && systemctl reload nginx

I=$(hostname -I | awk '{print $1}')
echo -e "\n${G}DONE! FastPanel available at: https://$I:8888${X}"
echo -e "${G}License: https://cp.fastpanel.direct/order/panel/license${X}"
