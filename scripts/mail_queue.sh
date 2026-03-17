#!/usr/bin/env bash
# Script:  mail_queue.sh
# Version: v2026-03-17
# Purpose: Show Exim mail queue size and optionally clear all stuck emails.
# Usage:   /opt/server_tools/scripts/mail_queue.sh
# Alias:   mailclean

clear
echo "Queue size: $(exim -bpc 2>/dev/null || echo 'exim not found')"
read -p "Clear all stuck emails? (y/n): " A
if [ "$A" = "y" ]; then
    exipick -i 2>/dev/null | xargs -r exim -Mrm 2>/dev/null
    echo "Queue cleared."
else
    echo "Cancelled."
fi
