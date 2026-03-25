#!/bin/bash
clear
# = Rooted by VladiMIR | AI =
# v2026-03-25 | Fix dpkg + remove nginx + disable nginx alert cron on VPN node

echo "======================================"
echo " VPN Node Fix: $(hostname) $(hostname -I)"
echo " v2026-03-25 | Rooted by VladiMIR | AI"
echo "======================================"

echo ""
echo ">>> [1/5] Fix dpkg if interrupted..."
dpkg --configure -a 2>/dev/null && echo "OK" || echo "Nothing to fix"

echo ""
echo ">>> [2/5] Fix broken packages..."
apt install -f -y 2>/dev/null && echo "OK"

echo ""
echo ">>> [3/5] Remove nginx..."
apt remove --purge nginx nginx-common nginx-full -y 2>/dev/null && echo "OK" || echo "nginx not installed"

echo ""
echo ">>> [4/5] Autoremove..."
apt autoremove -y 2>/dev/null && echo "OK"

echo ""
echo ">>> [5/5] Remove telegram_alert cron (nginx not needed on VPN node)..."
# Remove the cron line that runs telegram_alert.sh
crontab -l 2>/dev/null | grep -v 'telegram_alert.sh' | crontab -
echo "OK - cron telegram_alert removed"

echo ""
echo "======================================"
echo " Current crontab:"
crontab -l 2>/dev/null || echo " (empty)"
echo "======================================"
echo " ✅ DONE: $(hostname) - nginx removed, alert cron disabled"
echo "======================================"
