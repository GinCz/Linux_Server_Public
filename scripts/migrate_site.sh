#!/usr/bin/env bash
# Debian 11 to Ubuntu 24 Website Migration Tool
clear

# --- UI COLORS ---
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
GREEN='\033[0;32m'
NC='\033[0m'

# --- SETTINGS (Load from environment or edit here) ---
# For public safety, real credentials should be passed as variables or edited locally
DOMAIN="your-domain.com"
DB_NAME="db_name"
OLD_IP="0.0.0.0"
OLD_PASS="your_password"
USER_NAME="user_name"
DB_PASS="db_password"

BASE_PATH="/var/www/$USER_NAME/data/www/$DOMAIN"

echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}   STARTING MIGRATION: ${YELLOW}$DOMAIN${NC}"
echo -e "${CYAN}======================================================${NC}"

# 1. Syncing Files via rsync
echo -e "${YELLOW}>>> Step 1: Syncing files...${NC}"
START_SIZE=$(sshpass -p "$OLD_PASS" ssh -o StrictHostKeyChecking=no root@$OLD_IP "du -sh /var/www/$USER_NAME/data/www/$DOMAIN/" | cut -f1)
sshpass -p "$OLD_PASS" rsync -az -q -e "ssh -o StrictHostKeyChecking=no" root@$OLD_IP:/var/www/$USER_NAME/data/www/$DOMAIN/ $BASE_PATH/

# 2. Database Migration
echo -e "${YELLOW}>>> Step 2: Moving database...${NC}"
sshpass -p "$OLD_PASS" ssh -o StrictHostKeyChecking=no root@$OLD_IP "mysqldump $DB_NAME > /tmp/$DB_NAME.sql"
sshpass -p "$OLD_PASS" scp -q -o StrictHostKeyChecking=no root@$OLD_IP:/tmp/$DB_NAME.sql /tmp/
mysql $DB_NAME < /tmp/$DB_NAME.sql
DB_SIZE=$(du -h /tmp/$DB_NAME.sql | cut -f1)

# 3. Permissions and WordPress Config Update
echo -e "${YELLOW}>>> Step 3: Updating permissions and configuration...${NC}"
chown -R $USER_NAME:$USER_NAME $BASE_PATH
find $BASE_PATH -type d -exec chmod 755 {} \;
find $BASE_PATH -type f -exec chmod 644 {} \;

CONFIG_STATUS="Not Found"
if [ -f "$BASE_PATH/wp-config.php" ]; then
    sed -i "s|define(\s*[\'\"]DB_NAME[\'\"]\s*,\s*[\'\"].*[\'\"]\s*);|define( 'DB_NAME', '$DB_NAME' );|" "$BASE_PATH/wp-config.php"
    sed -i "s|define(\s*[\'\"]DB_USER[\'\"]\s*,\s*[\'\"].*[\'\"]\s*);|define( 'DB_USER', '$DB_NAME' );|" "$BASE_PATH/wp-config.php"
    sed -i "s|define(\s*[\'\"]DB_PASSWORD[\'\"]\s*,\s*[\'\"].*[\'\"]\s*);|define( 'DB_PASSWORD', '$DB_PASS' );|" "$BASE_PATH/wp-config.php"
    CONFIG_STATUS="UPDATED"
fi

# --- FINAL MIGRATION REPORT ---
echo -e "\n${CYAN}================ MIGRATION STATUS ================${NC}"
echo -e "${GREEN}✔ Domain:               ${YELLOW}$DOMAIN${NC}"
echo -e "${GREEN}✔ Files Copied:         ${YELLOW}$START_SIZE${NC}"
echo -e "${GREEN}✔ Database:             ${YELLOW}$DB_NAME ($DB_SIZE)${NC}"
echo -e "${GREEN}✔ WordPress Config:     ${YELLOW}$CONFIG_STATUS${NC}"
echo -e "${CYAN}==================================================${NC}"

echo "Migration successfully completed!"
ls -la $BASE_PATH | head -n 5
