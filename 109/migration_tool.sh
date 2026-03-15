#!/usr/bin/env bash
# Description: Automated rsync/mysql migration from Debian to Ubuntu FastPanel.
# Usage: Edit variables inside the script before running.
D="domain.com"; DB="db_name"; U="user"; OLD_IP="1.1.1.1"; PASS="pwd"; P="/var/www/$U/data/www/$D"; echo "Migrating $D..."; sshpass -p "$PASS" rsync -az -e "ssh -o StrictHostKeyChecking=no" root@$OLD_IP:$P/ $P/; sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$OLD_IP "mysqldump $DB" | mysql $DB; chown -R $U:$U $P; find $P -type d -exec chmod 755 {} \;; find $P -type f -exec chmod 644 {} \;; echo "Done."
