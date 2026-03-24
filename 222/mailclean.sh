#!/usr/bin/env bash
clear
# mailclean.sh — Clean local mail queue and logs
# Version: v2026-03-24
# Server: 222-DE-NetCup
# Author: Ing. VladiMIR Bulantsev

echo "=== MAIL CLEAN: $(hostname) ==="
echo

# Check if postfix/sendmail is installed
if command -v postfix &>/dev/null; then
    echo "[Postfix] Mail queue:"
    postqueue -p | tail -5
    echo
    echo "[Postfix] Flushing queue..."
    postqueue -f
    echo "[Postfix] Deleting ALL queued mail..."
    postsuper -d ALL
    echo "[Postfix] Done."
elif command -v sendmail &>/dev/null; then
    echo "[Sendmail] Clearing queue..."
    rm -f /var/spool/mqueue/*
    echo "[Sendmail] Done."
else
    echo "[INFO] No mail server (postfix/sendmail) found on this server."
    echo "[INFO] Nothing to clean."
fi

echo
# Clean root mailbox
if [ -f /var/mail/root ] && [ -s /var/mail/root ]; then
    SIZE=$(du -sh /var/mail/root | cut -f1)
    echo "[Root mailbox] Size: $SIZE — clearing..."
    > /var/mail/root
    echo "[Root mailbox] Cleared."
else
    echo "[Root mailbox] Empty or not found — OK."
fi

echo
# Clean mail logs older than 7 days
if [ -d /var/log/mail ]; then
    echo "[Mail logs] Cleaning logs older than 7 days..."
    find /var/log/mail* -mtime +7 -delete 2>/dev/null
    echo "[Mail logs] Done."
fi

echo
echo "=== DONE ==="
