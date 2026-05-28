#!/bin/bash
# = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz =
# fix_crowdsec_global.sh
# Universal CrowdSec SSH+SMB fix + Samba cleanup for all VPN nodes
# Tested on: EU-Stolb-AG-24, VPN-EU-Shain-227
# Run on: any VPN server with CrowdSec + Samba

clear

echo "======================================================================"
echo "  GLOBAL FIX: CrowdSec SSH+SMB + Samba | $(hostname) | $(date '+%Y-%m-%d %H:%M:%S')"
echo "======================================================================"

# --- STEP 1: Fix sshd.yaml ---
echo ""
echo "[1/5] Fixing CrowdSec SSH acquisition..."

# Remove journalctl duplicate if present, set correct type: syslog
cat > /etc/crowdsec/acquis.d/sshd.yaml << 'EOF'
filenames:
  - /var/log/auth.log
  - /var/log/auth.log.1
labels:
  type: syslog
source: file
EOF
echo "[OK] sshd.yaml -> type: syslog, source: auth.log"

# --- STEP 2: Fix SMB acquisition ---
echo ""
echo "[2/5] Fixing CrowdSec SMB acquisition..."

cat > /etc/crowdsec/acquis.d/setup.smb.yaml << 'EOF'
filenames:
  - /var/log/samba/log.smbd
labels:
  type: smb
source: file
EOF
echo "[OK] setup.smb.yaml -> single log.smbd"

# --- STEP 3: Fix smb.conf ---
echo ""
echo "[3/5] Fixing smb.conf..."

if [ -f /etc/samba/smb.conf ]; then
    cp /etc/samba/smb.conf /etc/samba/smb.conf.bak.$(date +%Y%m%d_%H%M%S)

    # Lower log level to 1
    sed -i 's/^   log level = [0-9].*/   log level = 1/' /etc/samba/smb.conf
    # Remove auth:2 or auth:3 suffixes
    sed -i 's/^   log level = 1 auth:[0-9]/   log level = 1/' /etc/samba/smb.conf
    # Unified log file
    sed -i 's|log file = /var/log/samba/log\.%m|log file = /var/log/samba/log.smbd|' /etc/samba/smb.conf
    sed -i 's|log file = /var/log/samba/log\.%d|log file = /var/log/samba/log.smbd|' /etc/samba/smb.conf
    # Remove vfs_full_audit if accidentally added
    sed -i '/vfs objects = full_audit/d' /etc/samba/smb.conf
    sed -i '/full_audit:/d' /etc/samba/smb.conf
    # Remove rsyslog LOCAL7 rule if present
    rm -f /etc/rsyslog.d/49-samba-audit.conf

    echo "[OK] smb.conf: log level=1, log.smbd, no full_audit"
    grep -n "log level\|log file\|logging\|vfs objects" /etc/samba/smb.conf | grep -v "^.*#"
else
    echo "[SKIP] smb.conf not found - Samba not installed"
fi

# --- STEP 4: Clean old per-IP Samba logs ---
echo ""
echo "[4/5] Cleaning old Samba IP logs..."

if [ -d /var/log/samba ]; then
    BEFORE=$(du -sh /var/log/samba/ | cut -f1)
    COUNT=$(find /var/log/samba -name "log.*.*" -mtime +1 2>/dev/null | wc -l)
    find /var/log/samba -name "log.*.*" -mtime +1 -delete 2>/dev/null
    AFTER=$(du -sh /var/log/samba/ | cut -f1)
    echo "[OK] Deleted $COUNT old log files | Before: $BEFORE -> After: $AFTER"
else
    echo "[SKIP] /var/log/samba not found"
fi

# --- STEP 5: Disable fwupd (firmware update daemon - useless on VPS) ---
echo ""
echo "[5/5] Disabling fwupd (useless on VPS)..."
if systemctl is-active --quiet fwupd 2>/dev/null; then
    systemctl stop fwupd
    systemctl disable fwupd
    systemctl mask fwupd
    echo "[OK] fwupd stopped and masked"
else
    echo "[SKIP] fwupd not running"
fi

# --- Restart services ---
echo ""
echo "--- Restarting services ---"
systemctl restart rsyslog 2>/dev/null
systemctl stop smbd nmbd crowdsec 2>/dev/null
sleep 3
[ -f /etc/samba/smb.conf ] && systemctl start smbd nmbd
sleep 2
systemctl start crowdsec
sleep 8

echo ""
echo "--- Services status ---"
for svc in smbd nmbd crowdsec crowdsec-firewall-bouncer; do
    STATUS=$(systemctl is-active $svc 2>/dev/null || echo "not-installed")
    echo "  $svc: $STATUS"
done

# --- Final verification ---
echo ""
echo "====== FINAL VERIFICATION ======"

echo ""
echo "--- CrowdSec Parsers ---"
cscli metrics | grep -E "Parsers|Hits|Parsed|Unparsed" | head -20

echo ""
echo "--- CrowdSec Active Bans ---"
cscli decisions list 2>/dev/null | head -10

echo ""
echo "--- CrowdSec Scenarios (24h) ---"
cscli alerts list --limit 5 2>/dev/null | head -15

echo ""
echo "--- Disk /var/log/samba ---"
du -sh /var/log/samba/ 2>/dev/null
ls -lh /var/log/samba/log.smbd /var/log/samba/log.nmbd 2>/dev/null

echo ""
echo "--- RAM after fix ---"
free -m | grep -E "Mem|Swap"

echo ""
echo "======================================================================"
echo "  DONE: $(hostname) | $(date '+%Y-%m-%d %H:%M:%S')"
echo "  = Rooted by VladiMIR + AI | v.2026.05.28 | github.com/GinCz ="
echo "======================================================================"
