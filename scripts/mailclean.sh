#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  mailclean.sh | [v2026-08-15]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : Universal mail queue cleaner (Exim4, Postfix, Sendmail, root mailbox)
# Servers     : All Linux Nodes (222-DE / 109-RU / Mail Nodes)
# Usage       : bash scripts/mailclean.sh
# ==========================================================================================

echo "=== MAIL CLEAN: $(hostname) ==="
echo ""

# 1. Exim4
if command -v exim4 &>/dev/null || command -v exim &>/dev/null; then
    EXIM_CMD="exim"
    command -v exim4 &>/dev/null && EXIM_CMD="exim4"
    echo "[Exim] Checking mail queue..."
    FROZEN_COUNT=$($EXIM_CMD -bpu 2>/dev/null | grep -c frozen || echo 0)
    TOTAL_QUEUE=$($EXIM_CMD -bpc 2>/dev/null || echo 0)
    echo "[Exim] Total queued messages: $TOTAL_QUEUE (Frozen: $FROZEN_COUNT)"

    if [ "$FROZEN_COUNT" -gt 0 ]; then
        echo "[Exim] Purging frozen messages..."
        $EXIM_CMD -bpu 2>/dev/null | grep frozen | awk '{print $3}' | xargs -r $EXIM_CMD -Mrm 2>/dev/null || true
        echo "[Exim] Frozen messages deleted."
    fi
fi

# 2. Postfix
if command -v postfix &>/dev/null; then
    echo "[Postfix] Checking mail queue..."
    postqueue -p | tail -5
    echo "[Postfix] Deleting ALL queued mail..."
    postsuper -d ALL 2>/dev/null || true
    echo "[Postfix] Done."
fi

# 3. Sendmail
if command -v sendmail &>/dev/null && [ -d /var/spool/mqueue ]; then
    echo "[Sendmail] Clearing queue..."
    rm -f /var/spool/mqueue/* 2>/dev/null || true
    echo "[Sendmail] Done."
fi

# 4. Root Mailbox
echo ""
if [ -f /var/mail/root ] && [ -s /var/mail/root ]; then
    SIZE=$(du -sh /var/mail/root | cut -f1)
    echo "[Root mailbox] Size: $SIZE — clearing..."
    > /var/mail/root
    echo "[Root mailbox] Cleared."
else
    echo "[Root mailbox] Empty or not found — OK."
fi

# 5. Old mail logs
if [ -d /var/log/exim4 ]; then
    find /var/log/exim4/ -name "*.gz" -mtime +7 -delete 2>/dev/null || true
fi

echo ""
echo "=== MAIL CLEAN COMPLETE ==="

# = Rooted by VladiMIR | AI = v2026-08-15 = github.com/GinCz/Linux_Server_Public
