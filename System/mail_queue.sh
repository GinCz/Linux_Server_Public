#!/usr/bin/env bash
# Description: Show Exim queue size and optionally clear all stuck emails.
# Alias: mailclean
echo "Queue size: $(exim -bpc 2>/dev/null)"; read -p "Clear all? (y/n): " A; [ "$A" = "y" ] && { exipick -i 2>/dev/null | xargs -r exim -Mrm 2>/dev/null; echo "Queue cleared."; }
