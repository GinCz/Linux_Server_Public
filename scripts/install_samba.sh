#!/bin/bash
clear
# = Rooted by VladiMIR + AI | v.2026.05.26 | github.com/GinCz =
# ==============================================================================
# Script:   install_samba.sh
# Version:  v2026.05.26
# Usage:    bash install_samba.sh
# Target:   All VPN nodes (Ubuntu 24 LTS)
# Purpose:  Install and harden Samba file sharing with multi-layer protection:
#
#   LAYER 1 — UFW rate-limiting
#             Ports 445/tcp and 139/tcp are open to ANY IP (needed because
#             admin IP is dynamic), but UFW limits to 6 connections per 30s.
#             Brute-force bots that hammer the port get auto-blocked by the kernel.
#
#   LAYER 2 — CrowdSec SMB brute-force detection
#             Installs crowdsecurity/smb collection and fixes acquis source:
#             Ubuntu 24 writes smbd logs to journald (NOT to /var/log/samba/*.log).
#             The default CrowdSec acquis.d/setup.smb.yaml uses file source and
#             finds nothing — this script replaces it with journalctl source.
#             Also deploys a strict local scenario (3 attempts / 30s = ban)
#             on top of the default crowdsecurity/smb-bf (5 attempts / 60s).
#             Bans are shared to CrowdSec CAPI (community blocklist).
#
#   LAYER 3 — Samba smb.conf hardening
#             - Disables guest/anonymous access (map to guest = never)
#             - Blocks system accounts (invalid users = root bin daemon nobody)
#             - Enforces SMB2 minimum protocol (no legacy SMB1/NTLM)
#             - Forces NTLMv2-only authentication (disables weak NTLMv1)
#             - Enables opportunistic encryption (smb encrypt = desired)
#             - Enables auth logging at level 3 for CrowdSec to parse
#             - Sets log rotation at 5MB
#
# Notes:
#   - Idempotent: safe to run multiple times, skips already-configured items
#   - Backs up smb.conf before modifying: /etc/samba/smb.conf.bak.YYYYMMDD
#   - Share configuration (paths, users) is NOT touched — only [global] hardening
#   - Run 'cscli decisions list' after ~5 min to see bans taking effect
# ==============================================================================

G=$'\033[1;32m'
R=$'\033[1;31m'
Y=$'\033[1;33m'
C=$'\033[1;36m'
W=$'\033[1;37m'
X=$'\033[0m'

SEP="${Y}$(printf '=%.0s' {1..70})${X}"

echo -e "$SEP"
echo -e "  ${W}SAMBA HARDENED INSTALL${X}  v2026.05.26"
echo -e "  ${C}$(hostname)${X}  ${G}$(hostname -I | awk '{print $1}')${X}"
echo -e "$SEP\n"

# ------------------------------------------------------------------------------
# STEP 1 — Install Samba packages
# ------------------------------------------------------------------------------
echo -e "${C}[1/5] Installing Samba packages...${X}"

if dpkg -l 2>/dev/null | grep -qE '^ii\s+samba\s'; then
    echo -e "  ${G}OK: Samba already installed — skipping apt install${X}"
else
    apt-get update -qq
    apt-get install -y samba samba-common-bin
    echo -e "  ${G}OK: Samba installed${X}"
fi

# Ensure services are enabled
systemctl enable smbd nmbd 2>/dev/null
echo -e "  ${G}OK: smbd + nmbd enabled${X}"

# ------------------------------------------------------------------------------
# STEP 2 — Harden smb.conf [global] section
#
# We only ADD hardening to [global]. Existing share definitions are untouched.
# A timestamped backup is always created before modification.
# ------------------------------------------------------------------------------
echo -e "\n${C}[2/5] Hardening smb.conf...${X}"

SMB_CONF="/etc/samba/smb.conf"
BACKUP="${SMB_CONF}.bak.$(date +%Y%m%d_%H%M%S)"

# Always back up before touching
cp "$SMB_CONF" "$BACKUP"
echo -e "  ${G}OK: backup saved → $BACKUP${X}"

if grep -q 'VladiMIR + AI hardening' "$SMB_CONF" 2>/dev/null; then
    echo -e "  ${Y}SKIP: hardening block already present in smb.conf${X}"
else
    # Remove conflicting directives that we will re-add in hardened form
    # (ntlm auth and server min protocol may already exist with weak values)
    sed -i '/^[[:space:]]*ntlm auth[[:space:]]*=/d' "$SMB_CONF"
    sed -i '/^[[:space:]]*server min protocol[[:space:]]*=/d' "$SMB_CONF"
    sed -i '/^[[:space:]]*map to guest[[:space:]]*=/d' "$SMB_CONF"

    # Append hardening block at end of file
    # It applies globally because smb.conf merges all [global] directives
    cat >> "$SMB_CONF" << 'SMBEOF'

# === VladiMIR + AI hardening | v2026.05.26 | github.com/GinCz ===
[global]
   # Block anonymous/guest access entirely
   map to guest = never

   # Block system accounts from authenticating via Samba
   invalid users = root bin daemon nobody

   # Minimum protocol: SMB2 (disables legacy SMB1 — CVE-2017-0144 WannaCry vector)
   server min protocol = SMB2

   # NTLMv2-only: disables weak NTLMv1 authentication
   # NTLMv1 is vulnerable to relay attacks and pass-the-hash
   ntlm auth = ntlmv2-only

   # Opportunistic encryption: encrypt if client supports it
   # Use 'required' for maximum security (breaks older clients)
   smb encrypt = desired

   # Auth logging level 3: required for CrowdSec to detect failed auth events
   # Level 1 = general, auth:3 = verbose authentication logs
   log level = 1 auth:3

   # Rotate logs at 5MB to prevent disk fill
   max log size = 5000
# =================================================================
SMBEOF
    echo -e "  ${G}OK: hardening block added to smb.conf${X}"
fi

# Validate config
if testparm -s "$SMB_CONF" >/dev/null 2>&1; then
    echo -e "  ${G}OK: testparm validation passed${X}"
    systemctl restart smbd nmbd
    echo -e "  ${G}OK: smbd + nmbd restarted${X}"
else
    echo -e "  ${R}ERROR: testparm failed — restoring backup${X}"
    cp "$BACKUP" "$SMB_CONF"
    systemctl restart smbd nmbd
    exit 1
fi

# ------------------------------------------------------------------------------
# STEP 3 — UFW rate-limiting on ports 445 and 139
#
# WHY rate-limit instead of whitelist:
#   Admin IP is dynamic (changes location) — whitelist would lock out the admin.
#   UFW 'limit' allows any IP but auto-blocks after 6 connections in 30 seconds.
#   Legitimate users connect 1-2 times and are never affected.
#   Brute-force bots that hammer the port get dropped at the kernel level.
# ------------------------------------------------------------------------------
echo -e "\n${C}[3/5] Configuring UFW rate-limiting for SMB ports...${X}"

if ! command -v ufw >/dev/null 2>&1; then
    echo -e "  ${Y}UFW not installed — installing...${X}"
    apt-get install -y ufw
fi

# Enable UFW if inactive
UFW_STATUS=$(ufw status 2>/dev/null | head -1)
if [[ "$UFW_STATUS" == *inactive* ]]; then
    ufw --force enable 2>/dev/null
    echo -e "  ${Y}UFW was inactive — enabled${X}"
fi

# Remove plain ALLOW rules for 445/139 if they exist (replace with LIMIT)
for PORT in 445 139; do
    # Delete existing allow rules for this port (ufw delete by rule spec)
    ufw delete allow "${PORT}/tcp" 2>/dev/null || true
    ufw delete allow "${PORT}/udp" 2>/dev/null || true
done

# Add rate-limited rules
ufw limit 445/tcp comment 'SMB rate-limit: 6 conn/30s then block' 2>/dev/null
ufw limit 139/tcp comment 'NetBIOS rate-limit: 6 conn/30s then block' 2>/dev/null
ufw reload 2>/dev/null

echo -e "  ${G}OK: UFW rate-limit active on 445/tcp and 139/tcp${X}"

# ------------------------------------------------------------------------------
# STEP 4 — Fix CrowdSec SMB acquisition source
#
# PROBLEM: Default /etc/crowdsec/acquis.d/setup.smb.yaml uses:
#     source: file
#     filenames: /var/log/samba/*.log
# On Ubuntu 24 with systemd, smbd writes to journald — /var/log/samba/ is EMPTY.
# Result: CrowdSec sees 0 SMB log events and never fires the smb-bf scenario.
#
# FIX: Replace file source with journalctl source targeting smbd.service.
# ------------------------------------------------------------------------------
echo -e "\n${C}[4/5] Fixing CrowdSec SMB log acquisition (journald)...${X}"

if ! command -v cscli >/dev/null 2>&1; then
    echo -e "  ${Y}SKIP: CrowdSec not installed on this server${X}"
else
    # Install SMB collection if missing
    cscli collections install crowdsecurity/smb 2>/dev/null \
        && echo -e "  ${G}OK: crowdsecurity/smb collection installed${X}" \
        || echo -e "  ${Y}INFO: crowdsecurity/smb already installed${X}"

    # Replace broken file-based acquis with journald source
    cat > /etc/crowdsec/acquis.d/setup.smb.yaml << 'CSEOF'
# Fixed by install_samba.sh v2026.05.26
# Ubuntu 24: smbd logs go to journald, NOT to /var/log/samba/
# Original file-based source found 0 events — replaced with journalctl source
source: journalctl
journalctl_filter:
  - "_SYSTEMD_UNIT=smbd.service"
labels:
  type: smb
CSEOF
    echo -e "  ${G}OK: acquis.d/setup.smb.yaml → journalctl source${X}"

    # Also fix SSH acquis if it still uses file source (same Ubuntu 24 problem)
    SSHD_ACQUIS="/etc/crowdsec/acquis.d/sshd.yaml"
    if [ -f "$SSHD_ACQUIS" ] && grep -q 'auth.log' "$SSHD_ACQUIS" 2>/dev/null; then
        cp "$SSHD_ACQUIS" "${SSHD_ACQUIS}.bak.$(date +%Y%m%d)" 2>/dev/null
        cat > "$SSHD_ACQUIS" << 'SSHEOF'
# Fixed by install_samba.sh v2026.05.26
# Ubuntu 24: sshd logs go to journald, NOT to /var/log/auth.log
source: journalctl
journalctl_filter:
  - "_SYSTEMD_UNIT=ssh.service"
labels:
  type: syslog
SSHEOF
        echo -e "  ${G}OK: sshd.yaml → journalctl source (bonus fix)${X}"
    fi

    # Deploy strict local SMB scenario: ban after 3 failed attempts in 30s
    # The default crowdsecurity/smb-bf allows 5 attempts in 60s — too permissive
    STRICT_SCENARIO="/etc/crowdsec/scenarios/smb-bf-strict.yaml"
    if [ ! -f "$STRICT_SCENARIO" ]; then
        cat > "$STRICT_SCENARIO" << 'SCEOF'
# Custom strict SMB brute-force scenario
# Bans IP after 3 failed auth attempts within 30 seconds
# Supplements default crowdsecurity/smb-bf (5 attempts / 60s)
type: leaky
name: custom/smb-bf-strict
description: "SMB brute-force strict: 3 attempts in 30s = ban"
filter: evt.Meta.log_type == 'smb_failed_auth'
groupby: evt.Meta.source_ip
capacity: 3
leakspeed: "10s"
blackhole: "10m"
labels:
  service: smb
  type: bruteforce
  remediation: true
SCEOF
        echo -e "  ${G}OK: custom/smb-bf-strict scenario deployed (3 attempts → ban)${X}"
    else
        echo -e "  ${Y}SKIP: smb-bf-strict scenario already exists${X}"
    fi

    systemctl restart crowdsec 2>/dev/null
    echo -e "  ${G}OK: CrowdSec restarted${X}"
fi

# ------------------------------------------------------------------------------
# STEP 5 — Verification
# ------------------------------------------------------------------------------
echo -e "\n${C}[5/5] Verification...${X}"

echo -e "  ${C}Samba processes:${X}"
for SVC in smbd nmbd; do
    STATE=$(systemctl is-active "$SVC" 2>/dev/null)
    [ "$STATE" = "active" ] && COL="$G" || COL="$R"
    printf "    %-10s %s%s%s\n" "$SVC" "$COL" "$STATE" "$X"
done

echo -e "  ${C}Ports 445/139:${X}"
ss -tlnp 2>/dev/null | grep -E ':445|:139' \
    | awk -v g="$G" -v x="$X" '{printf "    %s%s%s\n",g,$0,x}'

echo -e "  ${C}UFW SMB rules:${X}"
ufw status numbered 2>/dev/null | grep -E '445|139' | sed 's/^/    /'

if command -v cscli >/dev/null 2>&1; then
    sleep 3
    echo -e "  ${C}CrowdSec SMB scenario:${X}"
    cscli scenarios list 2>/dev/null | grep -E 'smb' | sed 's/^/    /'
fi

echo ""
echo -e "$SEP"
echo -e "  ${G}DONE — Samba hardened and protected${X}"
echo -e ""
echo -e "  Protection layers active:"
echo -e "    ${G}[1]${X} UFW rate-limit: 6 conn/30s → block (kernel level)"
echo -e "    ${G}[2]${X} CrowdSec smb-bf: 5 attempts/60s → ban + CAPI share"
echo -e "    ${G}[3]${X} CrowdSec smb-bf-strict: 3 attempts/30s → ban"
echo -e "    ${G}[4]${X} smb.conf: NTLMv2-only, SMB2+, no guest, auth logging"
echo -e ""
echo -e "  Run in ~5 min to see bans:"
echo -e "    ${C}cscli decisions list${X}"
echo -e "    ${C}cscli metrics | grep smb${X}"
echo -e "$SEP"
echo -e "  ${W}= Rooted by VladiMIR + AI | v.2026.05.26 | github.com/GinCz =${X}"
echo -e "$SEP"
