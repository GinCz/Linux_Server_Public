#!/usr/bin/env bash
# Script:  mail_queue.sh
# Version: v2026-03-17
# Purpose: Show Exim queue: size, last 10 messages, option to clear.
# Usage:   /opt/server_tools/scripts/mail_queue.sh
# Alias:   mailclean

clear
R='\033[1;31m'; G='\033[1;32m'; Y='\033[1;33m'; X='\033[0m'

QUEUE_SIZE=$(exim -bpc 2>/dev/null || echo 0)
echo -e "${Y}=== EXIM MAIL QUEUE ===${X}"
echo -e "${G}Total emails:${X} $QUEUE_SIZE"

if [ "$QUEUE_SIZE" -gt 0 ]; then
    echo -e "\n${Y}=== LAST 10 MESSAGES ===${X}"
    exim -bp | tail -n 20
    echo -e "\n${R}⚠️  WARNING: This will DELETE ALL emails in queue!${X}"
    read -p "Clear queue? (y/N): " CLEAR
    if [[ "$CLEAR" =~ ^[Yy]$ ]]; then
        exipick -i 2>/dev/null | xargs -r exim -Mrm 2>/dev/null
        echo -e "${G}✅ Queue cleared (${QUEUE_SIZE} emails deleted)${X}"
    else
        echo -e "${G}Cancelled${X}"
    fi
else
    echo -e "${G}✅ Queue empty${X}"
fi
