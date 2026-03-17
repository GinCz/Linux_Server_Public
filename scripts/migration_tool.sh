#!/usr/bin/env bash
# Script:  migration_tool.sh
# Version: v2026-03-17
# Purpose: Migrate a single WordPress/PHP site from old server to this FastPanel server.
#          Copies files via rsync over SSH and imports MySQL database.
# Usage:   /opt/server_tools/scripts/migration_tool.sh
# WARNING: Overwrites existing files and database on this server.

clear
Y='\033[1;33m'; G='\033[1;32m'; R='\033[1;31m'; X='\033[0m'

echo -e "${Y}=== Site Migration Tool ===${X}"
read -p "Domain (e.g. example.com):     " D
read -p "DB name:                        " DB
read -p "FastPanel user on THIS server:  " U
read -p "Old server IP:                  " OLD_IP
read -s -p "Old server root password:       " PASS
echo ""

P="/var/www/$U/data/www/$D"

if [ ! -d "$P" ]; then
    echo -e "${R}ERROR: Directory $P does not exist on this server.${X}"
    echo "Create the site in FastPanel first, then run this script."
    exit 1
fi

echo -e "\n${Y}>>> Copying files from $OLD_IP...${X}"
sshpass -p "$PASS" rsync -az \
    -e "ssh -o StrictHostKeyChecking=no" \
    root@$OLD_IP:$P/ $P/

echo -e "${Y}>>> Importing database $DB...${X}"
sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no root@$OLD_IP \
    "mysqldump $DB" | mysql $DB

echo -e "${Y}>>> Setting permissions...${X}"
chown -R $U:$U $P
find $P -type d -exec chmod 755 {} \;
find $P -type f -exec chmod 644 {} \;

echo -e "\n${G}DONE! Site $D migrated successfully.${X}"
