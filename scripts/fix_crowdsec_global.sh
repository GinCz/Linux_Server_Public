#!/bin/bash
# = Rooted by VladiMIR + AI | v.2026.05.28c | github.com/GinCz =
# fix_crowdsec_global.sh
# Universal CrowdSec SSH+SMB fix + Samba cleanup + RAM optimization for ALL 10 servers
# Run from: DE-222 via SSH loop, or directly on any server
#
# CHANGES:
#   v2026.05.28c - Step 6: disable packagekit/udisks2/ModemManager (useless desktop daemons)
#   v2026.05.28b - sshd.yaml: journalctl as primary + _COMM=sshd + auth.log as secondary
#   v2026.05.28  - initial version

clear

HOSTNAME=$(hostname)
DATE=$(date '+%Y-%m-%d %H:%M:%S')

echo "======================================================================"
echo "  GLOBAL FIX: CrowdSec SSH+SMB + Samba + RAM | $HOSTNAME | $DATE"
echo "======================================================================"

# --- STEP 1: Fix sshd.yaml ---
echo ""
echo "[1/6] Fixing CrowdSec SSH acquisition..."

echo "--- Current sshd.yaml ---"
cat /etc/crowdsec/acquis.d/sshd.yaml 2>/dev/null || echo "(not found)"
echo ""

cat > /etc/crowdsec/acquis.d/sshd.yaml << 'EOF'
---
source: journalctl
journalctl_filter:
  - "_SYSTEMD_UNIT=ssh.service"
  - "_COMM=sshd"
labels:
  type: syslog
---
filenames:
  - /var/log/auth.log
  - /var/log/auth.log.1
labels:
  type: syslog
source: file
EOF
echo "[OK] sshd.yaml -> journalctl _COMM=sshd (primary) + auth.log (secondary)"

# --- STEP 2: Fix SMB acquisition ---
echo ""
echo "[2/6] Fixing CrowdSec SMB acquisition..."

if [ -f /etc/samba/smb.conf ]; then
    cat > /etc/crowdsec/acquis.d/setup.smb.yaml << 'EOF'
filenames:
  - /var/log/samba/log.smbd
labels:
  type: smb
source: file
EOF
    echo "[OK] setup.smb.yaml -> single log.smbd"
else
    echo "[SKIP] Samba not installed on this server"
fi

# --- STEP 3: Fix smb.conf ---
echo ""
echo "[3/6] Fixing smb.conf..."

if [ -f /etc/samba/smb.conf ]; then
    cp /etc/samba/smb.conf /etc/samba/smb.conf.bak.$(date +%Y%m%d_%H%M%S)
    sed -i 's/^   log level = [0-9].*/   log level = 1/' /etc/samba/smb.conf
    sed -i 's/^   log level = 1 auth:[0-9]/   log level = 1/' /etc/samba/smb.conf
    sed -i 's|log file = /var/log/samba/log\.%m|log file = /var/log/samba/log.smbd|' /etc/samba/smb.conf
    sed -i 's|log file = /var/log/samba/log\.%d|log file = /var/log/samba/log.smbd|' /etc/samba/smb.conf
    sed -i '/^   vfs objects = full_audit$/d' /etc/samba/smb.conf
    sed -i '/^   full_audit:/d' /etc/samba/smb.conf
    rm -f /etc/rsyslog.d/49-samba-audit.conf
    echo "[OK] smb.conf: log level=1, log.smbd, no full_audit"
else
    echo "[SKIP] smb.conf not found - Samba not installed"
fi

# --- STEP 4: Clean old per-IP Samba logs ---
echo ""
echo "[4/6] Cleaning old Samba IP logs..."

if [ -d /var/log/samba ]; then
    BEFORE=$(du -sh /var/log/samba/ | cut -f1)
    COUNT=$(find /var/log/samba -name "log.*.*" -mtime +1 2>/dev/null | wc -l)
    find /var/log/samba -name "log.*.*" -mtime +1 -delete 2>/dev/null
    AFTER=$(du -sh /var/log/samba/ | cut -f1)
    echo "[OK] Deleted $COUNT files | Before: $BEFORE -> After: $AFTER"
else
    echo "[SKIP] /var/log/samba not found"
fi

# --- STEP 5: Disable fwupd ---
echo ""
echo "[5/6] Disabling fwupd..."
if systemctl list-unit-files fwupd.service &>/dev/null 2>&1; then
    systemctl stop fwupd 2>/dev/null
    systemctl disable fwupd 2>/dev/null
    systemctl mask fwupd 2>/dev/null
    echo "[OK] fwupd stopped and masked"
else
    echo "[SKIP] fwupd not found"
fi

# --- STEP 6: Disable useless desktop daemons ---
echo ""
echo "[6/6] Disabling desktop daemons (packagekit / udisks2 / ModemManager)..."

FREED=0
for SVC in packagekit udisks2 ModemManager; do
    if systemctl list-unit-files ${SVC}.service &>/dev/null 2>&1; then
        systemctl stop $SVC 2>/dev/null
        systemctl disable $SVC 2>/dev/null
        systemctl mask $SVC 2>/dev/null
        echo "[OK] $SVC stopped and masked"
    else
        echo "[SKIP] $SVC not found"
    fi
done
echo "[OK] Desktop daemons disabled (~30MB RAM freed)"

# --- Restart services ---
echo ""
echo "--- Restarting services ---"

# Fix rsyslog timestamp format (Ubuntu 24 may use ISO format)
if ! grep -q "RSYSLOG_TraditionalFileFormat" /etc/rsyslog.conf 2>/dev/null; then
    sed -i "1s/^/\$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat\n/" /etc/rsyslog.conf
    echo "[FIXED] rsyslog -> TraditionalFileFormat"
fi
systemctl restart rsyslog 2>/dev/null

if [ -f /etc/samba/smb.conf ]; then
    systemctl stop smbd nmbd 2>/dev/null
    sleep 2
    systemctl start smbd nmbd
fi

systemctl stop crowdsec 2>/dev/null
sleep 2
systemctl start crowdsec
sleep 10

echo ""
echo "--- Services status ---"
for svc in smbd nmbd crowdsec crowdsec-firewall-bouncer fail2ban docker; do
    STATUS=$(systemctl is-active $svc 2>/dev/null)
    [ "$STATUS" = "inactive" ] && continue
    [ -z "$STATUS" ] && continue
    echo "  $svc: $STATUS"
done

# --- Final verification ---
echo ""
echo "====== FINAL VERIFICATION ======"

echo ""
echo "--- CrowdSec Parser Stats (sshd) ---"
cscli metrics 2>/dev/null | grep -E "sshd-logs|Hits|Parsed|Unparsed" | head -10

echo ""
echo "--- CrowdSec Active Bans ---"
cscli decisions list 2>/dev/null | head -10

echo ""
echo "--- Disk /var/log/samba ---"
du -sh /var/log/samba/ 2>/dev/null && \
  ls -lh /var/log/samba/log.smbd /var/log/samba/log.nmbd 2>/dev/null || \
  echo "(no samba)"

echo ""
echo "--- RAM ---"
free -m | grep -E "Mem|Swap"

echo ""
echo "======================================================================"
echo "  DONE: $HOSTNAME | $(date '+%Y-%m-%d %H:%M:%S')"
echo "  = Rooted by VladiMIR + AI | v.2026.05.28c | github.com/GinCz ="
echo "======================================================================"
