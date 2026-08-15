#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  migration_tool.sh | [v2026-05-01]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Site and database migration utility
# Servers     : 109-RU FastVDS
# Usage       : bash 109/migration_tool.sh
# ==========================================================================================
# Description: Automated rsync/mysql migration from Debian to Ubuntu FastPanel.
# Usage: Edit variables inside the script before running.
D="domain.com"; DB="db_name"; U="user"; OLD_IP="1.1.1.1"; PASS="pwd"; P="/var/www/$U/data/www/$D"; echo "Migrating $D..."; sshpass -p "$PASS" rsync -az -e "ssh -o StrictHostKeyChecking=no" root@$OLD_IP:$P/ $P/; sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$OLD_IP "mysqldump $DB" | mysql $DB; chown -R $U:$U $P; find $P -type d -exec chmod 755 {} \;; find $P -type f -exec chmod 644 {} \;; echo "Done."

# = Rooted by VladiMIR | AI = v2026-05-01 = github.com/GinCz/Linux_Server_Public
