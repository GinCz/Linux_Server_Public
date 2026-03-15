#!/usr/bin/env bash
# Description: Install FastPanel with MariaDB 10.11 and configure UFW.
# Alias: fpinstall
wget -qO- http://repo.fastpanel.direct/install_fastpanel.sh | bash -s -- -m mariadb10.11; ufw allow 20,21,25,80,110,443,465,587,993,995,8888/tcp; ufw status; I=$(hostname -I | awk '{print $1}'); echo "DONE: https://$I:8888"
