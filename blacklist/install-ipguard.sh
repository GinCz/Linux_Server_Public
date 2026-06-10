#!/usr/bin/env bash
# ==========================================================
# install-ipguard.sh — IPGuard Unified Security Installer
# Installs: CrowdSec + fail2ban + IPGuard ipset blacklist
# Works on: VPN nodes, Web servers (222/109), any Ubuntu/Debian
# Usage:
#   bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/install-ipguard.sh)
#
# What it does:
#   1. Installs & configures fail2ban  (SSH brute-force, own iptables chain)
#   2. Installs & configures CrowdSec  (pattern detection, own iptables chain)
#   3. Deploys IPGuard ipset blacklist (shared list from all 10 nodes via GitHub)
#   4. Sets up cron: deploy-blacklist every 3h, @reboot restore
#   5. Whitelists all trusted IPs in both CrowdSec and fail2ban
#
# No conflicts: fail2ban → chain F2B-sshd | CrowdSec → chain CROWDSEC | IPGuard → ipset vladblacklist
#
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
# ==========================================================

set -euo pipefail
clear

# ── Colors ──────────────────────────────────────────────────
G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'
R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
LINE="================================================================"

# ── Config ───────────────────────────────────────────────────
HOSTNAME=$(hostname)
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
BLACKLIST_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/blacklist.txt"
DEPLOY_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh"
IPSET_NAME="vladblacklist"

# All trusted IPs — whitelisted in CrowdSec, fail2ban and iptables
TRUSTED_IPS=(
    "127.0.0.1"
    "152.53.182.222"
    "212.109.223.109"
    "109.234.38.47"
    "144.124.228.237"
    "144.124.232.9"
    "144.124.228.227"
    "144.124.239.24"
    "91.84.118.178"
    "146.103.110.176"
    "144.124.233.38"
    "3.79.14.42"
    "185.100.197.16"
    "185.14.233.235"
    "185.14.232.0"
    "90.181.133.10"
)

# Build space-separated and newline-separated versions
TRUSTED_SPACE="${TRUSTED_IPS[*]}"
TRUSTED_YAML=""
for ip in "${TRUSTED_IPS[@]}"; do
    TRUSTED_YAML+="    - \"$ip\"\n"
done

# ── Header ───────────────────────────────────────────────────
echo -e "${Y}${LINE}${X}"
echo -e "${Y}   IPGuard — Unified Security Installer${X}"
echo -e "${Y}   Server : ${W}${HOSTNAME}${X}"
echo -e "${Y}   Date   : ${DATETIME}${X}"
echo -e "${Y}${LINE}${X}"
echo ""

# ── Root check ───────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${R}ERROR: Must be run as root.${X}"
    exit 1
fi

# ── Detect server type ───────────────────────────────────────
IS_FASTPANEL=false
IS_VPN=false
ls /var/www/*/data/logs/ 2>/dev/null | grep -q "." && IS_FASTPANEL=true
(docker exec amnezia-awg wg show &>/dev/null 2>&1 || \
 systemctl is-active --quiet awg-quick@* 2>/dev/null || \
 systemctl is-active --quiet xray 2>/dev/null) && IS_VPN=true

echo -e "${C}Server type detected:${X}"
$IS_FASTPANEL && echo -e "  ${G}✓${X} FastPanel (web server)" || echo -e "  ➖ Not FastPanel"
$IS_VPN       && echo -e "  ${G}✓${X} VPN node"               || echo -e "  ➖ Not VPN"
echo ""

# ════════════════════════════════════════════════════════════
# STEP 1 — fail2ban
# Uses its own chain: f2b-sshd (auto-created by fail2ban)
# Does NOT touch CROWDSEC chain or ipset vladblacklist
# ════════════════════════════════════════════════════════════
echo -e "${Y}[1/4] Installing fail2ban (SSH brute-force protection)...${X}"

apt-get update -qq
apt-get install -y fail2ban -qq

# Write /etc/fail2ban/jail.local — override defaults safely
# fail2ban manages its own chains (f2b-sshd etc), no conflict with CrowdSec
cat > /etc/fail2ban/jail.local << JAILEOF
[DEFAULT]
# Trusted IPs — never ban these
ignoreip = ${TRUSTED_SPACE}

# Ban for 1 hour after 5 failures in 10 minutes
bantime  = 3600
findtime = 600
maxretry = 5

# Use iptables-multiport backend — creates own chains f2b-*
banaction = iptables-multiport
backend   = auto

[sshd]
enabled  = true
port     = ssh
logpath  = /var/log/auth.log
maxretry = 5
findtime = 300
bantime  = 7200

[sshd-ddos]
enabled  = true
port     = ssh
logpath  = /var/log/auth.log
maxretry = 20
findtime = 60
bantime  = 86400
filter   = sshd
JAILEOF

systemctl enable fail2ban --now 2>/dev/null
systemctl restart fail2ban 2>/dev/null
sleep 2

if systemctl is-active --quiet fail2ban; then
    JAILS=$(fail2ban-client status 2>/dev/null | grep 'Jail list' | sed 's/.*://;s/ //g' | tr ',' '\n' | wc -l || echo "?")
    echo -e "  ${G}✓ fail2ban RUNNING — ${JAILS} jail(s) active${X}"
else
    echo -e "  ${R}✗ fail2ban failed to start — check: journalctl -u fail2ban -n 30${X}"
fi
echo ""

# ════════════════════════════════════════════════════════════
# STEP 2 — CrowdSec
# Uses its own chain: CROWDSEC (managed by firewall-bouncer)
# Does NOT touch f2b-* chains or ipset vladblacklist
# ════════════════════════════════════════════════════════════
echo -e "${Y}[2/4] Installing CrowdSec (pattern-based detection)...${X}"

if ! command -v cscli &>/dev/null; then
    curl -s https://install.crowdsec.net | sh -s -- -y 2>/dev/null
    apt-get install -y crowdsec -qq 2>/dev/null || true
else
    echo -e "  ${G}Already installed: $(cscli version 2>/dev/null | head -1)${X}"
fi

# Install firewall bouncer — creates CROWDSEC chain in iptables
apt-get install -y crowdsec-firewall-bouncer-iptables -qq 2>/dev/null || true

# Auto-detect bouncer service name
BOUNCER_SVC=""
for svc in crowdsec-firewall-bouncer crowdsec-firewall-bouncer-iptables; do
    systemctl list-units --all 2>/dev/null | grep -q "$svc" && BOUNCER_SVC="$svc" && break
done
[[ -z "$BOUNCER_SVC" ]] && BOUNCER_SVC="crowdsec-firewall-bouncer"

# Update hub and install collections
cscli hub update 2>/dev/null || true
cscli collections install crowdsecurity/sshd 2>/dev/null || true
cscli collections install crowdsecurity/linux 2>/dev/null || true

if $IS_FASTPANEL || command -v nginx &>/dev/null; then
    cscli collections install crowdsecurity/nginx 2>/dev/null || true
    cscli collections install crowdsecurity/wordpress 2>/dev/null || true
    cscli collections install crowdsecurity/http-cve 2>/dev/null || true
    cscli collections install crowdsecurity/base-http-scenarios 2>/dev/null || true
fi

# Configure log sources based on server type
if $IS_FASTPANEL; then
    cat > /etc/crowdsec/acquis.yaml << 'ACQUIS'
filenames:
  - /var/log/nginx/*.log
  - /var/www/*/data/logs/*.log
labels:
  type: nginx
---
filenames:
  - /var/log/auth.log
  - /var/log/syslog
labels:
  type: syslog
ACQUIS
else
    cat > /etc/crowdsec/acquis.yaml << 'ACQUIS'
filenames:
  - /var/log/auth.log
  - /var/log/syslog
labels:
  type: syslog
ACQUIS
fi

# Whitelist trusted IPs in CrowdSec
mkdir -p /etc/crowdsec/parsers/s02-enrich
cat > /etc/crowdsec/parsers/s02-enrich/whitelist-trusted.yaml << WHITEEOF
name: crowdsecurity/whitelist-trusted
description: IPGuard — whitelist trusted VladiMIR IPs
whitelist:
  reason: "IPGuard trusted IP"
  ip:
$(printf "${TRUSTED_YAML}")
WHITEEOF

# Also whitelist in CrowdSec decisions (belt + suspenders)
for IP in "${TRUSTED_IPS[@]}"; do
    [[ "$IP" == "127.0.0.1" ]] && continue
    cscli decisions add --ip "$IP" --type whitelist --reason "IPGuard trusted" 2>/dev/null || true
done

systemctl enable crowdsec --now 2>/dev/null
systemctl restart crowdsec 2>/dev/null
systemctl enable "$BOUNCER_SVC" --now 2>/dev/null
systemctl restart "$BOUNCER_SVC" 2>/dev/null
sleep 2

if systemctl is-active --quiet crowdsec; then
    CS_BANS=$(cscli decisions list 2>/dev/null | grep -c 'ban' || echo "?")
    echo -e "  ${G}✓ CrowdSec RUNNING — ${CS_BANS} active ban(s)${X}"
else
    echo -e "  ${R}✗ CrowdSec failed to start — check: journalctl -u crowdsec -n 30${X}"
fi
echo ""

# ════════════════════════════════════════════════════════════
# STEP 3 — IPGuard blacklist (ipset vladblacklist)
# Uses ipset hash:net + iptables rule at INPUT position 1
# Completely separate from CrowdSec and fail2ban chains
# ════════════════════════════════════════════════════════════
echo -e "${Y}[3/4] Deploying IPGuard blacklist (ipset)...${X}"

# Install dependencies
for pkg in ipset iptables iptables-persistent; do
    command -v "${pkg%%-*}" &>/dev/null || apt-get install -y "$pkg" -qq 2>/dev/null || true
done

# Download and apply blacklist
TMP=$(mktemp)
curl -fsSL "$BLACKLIST_URL" -o "$TMP"
COUNT=$(grep -cvE '^#|^$' "$TMP" || true)
echo -e "  Downloaded ${COUNT} IPs from GitHub"

ipset destroy "${IPSET_NAME}_tmp" 2>/dev/null || true
ipset create "${IPSET_NAME}_tmp" hash:net maxelem 65536

ADDED=0
while IFS= read -r line; do
    [[ "$line" =~ ^#|^[[:space:]]*$ ]] && continue
    ip=$(echo "$line" | sed 's/#.*//' | tr -d '[:space:]')
    [[ -z "$ip" ]] && continue
    ipset add "${IPSET_NAME}_tmp" "$ip" 2>/dev/null && ((ADDED++)) || true
done < "$TMP"
rm -f "$TMP"

# Create main set if not exists, then atomic swap
ipset list "$IPSET_NAME" &>/dev/null || ipset create "$IPSET_NAME" hash:net maxelem 65536
ipset swap "${IPSET_NAME}_tmp" "$IPSET_NAME"
ipset destroy "${IPSET_NAME}_tmp" 2>/dev/null || true

# iptables DROP rule — position 1, before any other rules
iptables -D INPUT -m set --match-set "$IPSET_NAME" src -j DROP 2>/dev/null || true
iptables -I INPUT 1 -m set --match-set "$IPSET_NAME" src -j DROP
echo -e "  ${G}✓ ipset '${IPSET_NAME}' active — ${ADDED} IPs blocked${X}"

# Persist iptables + ipset across reboots
mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
ipset save > /etc/ipset.rules 2>/dev/null || true
echo -e "  ${G}✓ Rules saved for persistence${X}"
echo ""

# ════════════════════════════════════════════════════════════
# STEP 4 — Cron jobs
# ════════════════════════════════════════════════════════════
echo -e "${Y}[4/4] Setting up cron jobs...${X}"

# Remove old/duplicate IPGuard cron entries
crontab -l 2>/dev/null | grep -v 'deploy-blacklist\|ipset restore\|ipguard' | crontab - 2>/dev/null || true

# Add fresh cron entries
(crontab -l 2>/dev/null; cat << 'CRONEOF'
# IPGuard — pull latest blacklist from GitHub and apply every 3 hours
30 */3 * * * bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh) >> /var/log/vladblacklist.log 2>&1
# IPGuard — restore ipset + iptables after reboot
@reboot sleep 10 && ipset restore < /etc/ipset.rules 2>/dev/null; iptables-restore < /etc/iptables/rules.v4 2>/dev/null; true
CRONEOF
) | crontab -

echo -e "  ${G}✓ Cron: deploy-blacklist every 3h (at :30)${X}"
echo -e "  ${G}✓ Cron: @reboot restore ipset + iptables${X}"
echo ""

# ════════════════════════════════════════════════════════════
# FINAL STATUS
# ════════════════════════════════════════════════════════════
echo -e "${Y}${LINE}${X}"
echo -e "${G}  IPGuard installation complete! ✅${X}"
echo -e "${Y}  Server: ${W}${HOSTNAME}${X}"
echo -e "${Y}${LINE}${X}"
echo ""
echo -e "${C}  Active protection layers:${X}"
echo ""

# fail2ban
if systemctl is-active --quiet fail2ban 2>/dev/null; then
    echo -e "  ${G}●${X} fail2ban      RUNNING  — SSH brute-force  → chain f2b-sshd"
else
    echo -e "  ${R}✗${X} fail2ban      NOT RUNNING"
fi

# CrowdSec
if systemctl is-active --quiet crowdsec 2>/dev/null; then
    echo -e "  ${G}●${X} CrowdSec      RUNNING  — pattern detection → chain CROWDSEC"
else
    echo -e "  ${R}✗${X} CrowdSec      NOT RUNNING"
fi

# IPGuard ipset
if ipset list "$IPSET_NAME" &>/dev/null && iptables -L INPUT -n 2>/dev/null | grep -q "$IPSET_NAME"; then
    IPS_COUNT=$(ipset list "$IPSET_NAME" 2>/dev/null | awk '/^Members:/{found=1;next} found && NF' | wc -l)
    echo -e "  ${G}●${X} IPGuard ipset ACTIVE   — ${IPS_COUNT} IPs blocked  → ipset vladblacklist"
else
    echo -e "  ${R}✗${X} IPGuard ipset NOT ACTIVE"
fi

echo ""
echo -e "${C}  iptables chain overview:${X}"
echo -e "  INPUT → vladblacklist (ipset DROP, pos 1)"
echo -e "  INPUT → CROWDSEC       (CrowdSec bouncer)"
echo -e "  INPUT → f2b-sshd       (fail2ban SSH)"
echo ""
echo -e "${C}  Cron schedule:${X}"
crontab -l 2>/dev/null | grep -E 'deploy-blacklist|@reboot' | sed 's/^/  /'
echo ""
echo -e "${C}  Useful commands:${X}"
echo -e "  ${W}cscli decisions list${X}      — CrowdSec active bans"
echo -e "  ${W}fail2ban-client status sshd${X} — fail2ban SSH jail"
echo -e "  ${W}ipset list vladblacklist | tail -20${X} — IPGuard blacklist"
echo -e "  ${W}iptables -L INPUT -n --line-numbers${X} — all iptables rules"
echo ""
echo -e "${Y}${LINE}${X}"
echo -e "  ${Y}Whitelisted trusted IPs (${#TRUSTED_IPS[@]}):${X}"
for IP in "${TRUSTED_IPS[@]}"; do echo -e "    ${G}✓${X} $IP"; done
echo -e "${Y}${LINE}${X}"
echo ""
echo -e "${C}  For external users (no VladiMIR infra):${X}"
echo -e "  The IPGuard blacklist is public — anyone can apply it:"
echo -e "  ${W}bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/blacklist/deploy-blacklist.sh)${X}"
echo -e "${Y}${LINE}${X}"
# = Rooted by VladiMIR + AI | v.2026.06.10 | github.com/GinCz =
