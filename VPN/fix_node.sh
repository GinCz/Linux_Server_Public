#!/bin/bash
clear
# = Rooted by VladiMIR | AI =
# v2026-03-25 | Fix dpkg + remove nginx (run locally on each VPN node)

echo "======================================"
echo " VPN Node Fix: $(hostname) $(hostname -I)"
echo " v2026-03-25 | Rooted by VladiMIR | AI"
echo "======================================"

echo ""
echo ">>> [1/4] Fix dpkg if interrupted..."
dpkg --configure -a 2>/dev/null && echo "OK" || echo "Nothing to fix"

echo ""
echo ">>> [2/4] Fix broken packages..."
apt install -f -y 2>/dev/null && echo "OK"

echo ""
echo ">>> [3/4] Remove nginx..."
apt remove --purge nginx nginx-common nginx-full -y 2>/dev/null && echo "OK" || echo "nginx not installed"

echo ""
echo ">>> [4/4] Autoremove..."
apt autoremove -y 2>/dev/null && echo "OK"

echo ""
echo "======================================"
echo " ✅ DONE: $(hostname) - nginx removed"
echo "======================================"
