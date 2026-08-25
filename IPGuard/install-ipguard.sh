#!/usr/bin/env bash
# ==========================================================================================
#  ░▒▓█░▒▓█░▒▓█░▒▓█░▒▓█  install-ipguard.sh | [v2026-08-25]  █▓▒░█▓▒░█▓▒░█▓▒░█▓▒░
# ==========================================================================================
# Description : IPGuard Unified Security Installer (CrowdSec + fail2ban + IPGuard ipset)
# Servers     : All Linux Nodes (VPN nodes, Web servers 222/109, any Ubuntu/Debian)
# Usage       : bash <(curl -fsSL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/IPGuard/install-ipguard.sh)
# ==========================================================================================

set -euo pipefail
clear

# ── Colors ──────────────────────────────────────────────────
G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'
R='\033[1;31m'; W='\033[1;37m'; X='\033[0m'
LINE="================================================================"

# ── Config ───────────────────────────────────────────────────
HOSTNAME=$(hostname)
DATETIME=$(date '+%Y-%m-%d %H:%M:%S')
BLACKLIST_URL="https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/IPGuard/blacklist.txt"
IPSET_NAME="vladblacklist"

TRUSTED_IPS=(
    "127.0.0.1"
    "152.53.182.222"
    "212.109.223.109"
    "109.234.38.47"
    "144.124.228.237"
    "144.124.232.9"
    "144.124.228.227"
    "144.124.239.24"
    "195.63.138.33"
    "146.103.110.176"
    "144.124.233.38"
    "3.79.14.42"
    "185.100.197.16"
    "185.14.233.235"
    "185.14.232.0"
    "90.181.133.10"
)

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
 systemctl is-active --quiet xray 2>/dev/null) && IS_VPN=true || true

echo -e "${C}Server type detected:${X}"
$IS_FASTPANEL && echo -e "  ${G}✓${X} FastPanel (web server)" || echo -e "  ➖ Not FastPanel"
$IS_VPN       && echo -e "  ${G}✓${X} VPN node"               || echo -e "  ➖ Not VPN"
echo ""

# ════════════════════════════════════════════════════════════
# STEP 1 — fail2ban
# ════════════════════════════════════════════════════════════
echo -e "${Y}[1/4] Installing fail2ban (SSH brute-force protection)...${X}"

apt-get update -qq
apt-get install -y fail2ban python3-systemd rsyslog -qq 2>/dev/null || apt-get install -y fail2ban -qq

# Ensure rsyslog is active if available
systemctl enable --now rsyslog 2>/dev/null || true

# Stop fail2ban and clean any leftover sockets/pid files before reconfiguration
systemctl stop fail2ban 2>/dev/null || true
rm -f /var/run/fail2ban/fail2ban.sock /var/run/fail2ban/fail2ban.pid /run/fail2ban/fail2ban.sock 2>/dev/null || true

# ── FIX: Backup any broken jail.d configs (e.g. samba.conf with %(action_)s) ──
# These use old fail2ban syntax and crash the server on startup
if ls /etc/fail2ban/jail.d/*.conf /etc/fail2ban/jail.d/*.local 2>/dev/null | grep -q .; then
    echo -e "  ${Y}Checking jail.d for broken configs...${X}"
    for f in /etc/fail2ban/jail.d/*.conf /etc/fail2ban/jail.d/*.local; do
        [[ -f "$f" ]] || continue
        if grep -q '%(action_)s\|%(action_mw)s\|%(action_mwl)s' "$f" 2>/dev/null; then
            mv "$f" "${f}.bak"
            echo -e "  ${Y}Backed up broken config: $f → ${f}.bak${X}"
        fi
    done
fi

# ── FIX: Restore missing fail2ban.conf from deb package if absent ──
# Ubuntu 22 package sometimes doesn't create fail2ban.conf on fresh install
if [[ ! -f /etc/fail2ban/fail2ban.conf ]]; then
    echo -e "  ${Y}fail2ban.conf missing — restoring from package...${X}"
    # Try extracting from downloaded deb
    DEB_TMP=$(mktemp -d)
    apt-get download fail2ban -qq 2>/dev/null && \
        dpkg -x fail2ban_*.deb "$DEB_TMP" 2>/dev/null && \
        cp -rn "$DEB_TMP/etc/fail2ban/." /etc/fail2ban/ 2>/dev/null || true
    rm -rf "$DEB_TMP" fail2ban_*.deb 2>/dev/null || true

    # If still missing — create minimal working config
    if [[ ! -f /etc/fail2ban/fail2ban.conf ]]; then
        cat > /etc/fail2ban/fail2ban.conf << 'F2BCONF'
[Definition]
loglevel = INFO
logtarget = /var/log/fail2ban.log
syslogsocket = auto
socket = /var/run/fail2ban/fail2ban.sock
pidfile = /var/run/fail2ban/fail2ban.pid
dbfile = /var/lib/fail2ban/fail2ban.sqlite3
dbpurgeage = 86400
F2BCONF
        echo -e "  ${Y}Created minimal fail2ban.conf${X}"
    fi
fi

# ── Write jail.local (Universal for systemd journal & auth.log) ──
cat > /etc/fail2ban/jail.local << JAILEOF
[DEFAULT]
ignoreip = ${TRUSTED_SPACE}
bantime  = 3600
findtime = 600
maxretry = 5
banaction = iptables-multiport
backend   = systemd

[sshd]
enabled  = true
port     = ssh
maxretry = 5
findtime = 300
bantime  = 7200

[sshd-ddos]
enabled  = true
port     = ssh
maxretry = 20
findtime = 60
bantime  = 86400
filter   = sshd
JAILEOF

systemctl daemon-reload 2>/dev/null || true
systemctl enable fail2ban --now 2>/dev/null || true
systemctl restart fail2ban 2>/dev/null || true
sleep 3

if systemctl is-active --quiet fail2ban; then
    JAILS=$(fail2ban-client status 2>/dev/null | grep 'Jail list' | sed 's/.*://;s/ //g' | tr ',' '\n' | wc -l || echo "?")
    echo -e "  ${G}✓ fail2ban RUNNING — ${JAILS} jail(s) active${X}"
else
    echo -e "  ${R}✗ fail2ban failed to start — check: journalctl -u fail2ban -n 30${X}"
fi
echo ""

# ════════════════════════════════════════════════════════════
# STEP 2 — CrowdSec
# ════════════════════════════════════════════════════════════
echo -e "${Y}[2/4] Installing CrowdSec (pattern-based detection)...${X}"

if ! command -v cscli &>/dev/null; then
    curl -s https://install.crowdsec.net | sh -s -- -y 2>/dev/null
    apt-get install -y crowdsec -qq 2>/dev/null || true
else
    echo -e "  ${G}Already installed: $(cscli version 2>/dev/null | head -1)${X}"
fi

apt-get install -y crowdsec-firewall-bouncer-iptables -qq 2>/dev/null || true

BOUNCER_SVC=""
for svc in crowdsec-firewall-bouncer crowdsec-firewall-bouncer-iptables; do
    systemctl list-units --all 2>/dev/null | grep -q "$svc" && BOUNCER_SVC="$svc" && break
done
[[ -z "$BOUNCER_SVC" ]] && BOUNCER_SVC="crowdsec-firewall-bouncer"

cscli hub update 2>/dev/null || true
cscli collections install crowdsecurity/sshd 2>/dev/null || true
cscli collections install crowdsecurity/linux 2>/dev/null || true

if $IS_FASTPANEL || command -v nginx &>/dev/null; then
    cscli collections install crowdsecurity/nginx 2>/dev/null || true
    cscli collections install crowdsecurity/wordpress 2>/dev/null || true
    cscli collections install crowdsecurity/http-cve 2>/dev/null || true
    cscli collections install crowdsecurity/base-http-scenarios 2>/dev/null || true
fi

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

mkdir -p /etc/crowdsec/parsers/s02-enrich
cat > /etc/crowdsec/parsers/s02-enrich/whitelist-trusted.yaml << WHITEEOF
name: crowdsecurity/whitelist-trusted
description: IPGuard — whitelist trusted VladiMIR IPs
whitelist:
  reason: "IPGuard trusted IP"
  ip:
$(printf "${TRUSTED_YAML}")
WHITEEOF

for IP in "${TRUSTED_IPS[@]}"; do
    [[ "$IP" == "127.0.0.1" ]] && continue
    cscli decisions add --ip "$IP" --type whitelist --reason "IPGuard trusted" 2>/dev/null || true
done

systemctl enable crowdsec --now 2>/dev/null || true
systemctl restart crowdsec 2>/dev/null || true
systemctl enable "$BOUNCER_SVC" --now 2>/dev/null || true
systemctl restart "$BOUNCER_SVC" 2>/dev/null || true
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
# ════════════════════════════════════════════════════════════
echo -e "${Y}[3/4] Deploying IPGuard blacklist (ipset)...${X}"

for pkg in ipset iptables iptables-persistent; do
    command -v "${pkg%%-*}" &>/dev/null || apt-get install -y "$pkg" -qq 2>/dev/null || true
done

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

ipset list "$IPSET_NAME" &>/dev/null || ipset create "$IPSET_NAME" hash:net maxelem 65536
ipset swap "${IPSET_NAME}_tmp" "$IPSET_NAME"
ipset destroy "${IPSET_NAME}_tmp" 2>/dev/null || true

iptables -D INPUT -m set --match-set "$IPSET_NAME" src -j DROP 2>/dev/null || true
iptables -I INPUT 1 -m set --match-set "$IPSET_NAME" src -j DROP
echo -e "  ${G}✓ ipset '${IPSET_NAME}' active — ${ADDED} IPs blocked${X}"

mkdir -p /etc/iptables
iptables-save > /etc/iptables/rules.v4 2>/dev/null || true
ipset save > /etc/ipset.rules 2>/dev/null || true
echo -e "  ${G}✓ Rules saved for persistence${X}"
echo ""

# ════════════════════════════════════════════════════════════
# STEP 4 — Cron jobs
# ════════════════════════════════════════════════════════════
echo -e "${Y}[4/4] Setting up cron jobs...${X}"

crontab -l 2>/dev/null | grep -v 'deploy-blacklist\|ipset restore\|ipguard' | crontab - 2>/dev/null || true

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

if systemctl is-active --quiet fail2ban 2>/dev/null; then
    JAILS=$(fail2ban-client status 2>/dev/null | grep 'Jail list' | sed 's/.*://;s/ //g' | tr ',' '\n' | wc -l || echo "?")
    echo -e "  ${G}●${X} fail2ban      RUNNING  — SSH brute-force   → chain f2b-sshd (${JAILS} jails)"
else
    echo -e "  ${R}✗${X} fail2ban      NOT RUNNING"
fi

if systemctl is-active --quiet crowdsec 2>/dev/null; then
    CS_BANS=$(cscli decisions list 2>/dev/null | grep -c 'ban' || echo "?")
    echo -e "  ${G}●${X} CrowdSec      RUNNING  — pattern detection → chain CROWDSEC (${CS_BANS} bans)"
else
    echo -e "  ${R}✗${X} CrowdSec      NOT RUNNING"
fi

if ipset list "$IPSET_NAME" &>/dev/null && iptables -L INPUT -n 2>/dev/null | grep -q "$IPSET_NAME"; then
    IPS_COUNT=$(ipset list "$IPSET_NAME" 2>/dev/null | awk '/^Members:/{found=1;next} found && NF' | wc -l)
    echo -e "  ${G}●${X} IPGuard ipset ACTIVE   — shared blacklist  → ipset vladblacklist (${IPS_COUNT} IPs)"
else
    echo -e "  ${R}✗${X} IPGuard ipset NOT ACTIVE"
fi

echo ""
echo -e "${C}  iptables chain order:${X}"
echo -e "  INPUT → vladblacklist (ipset DROP, pos 1)   — shared blacklist"
echo -e "  INPUT → CROWDSEC       (CrowdSec bouncer)    — pattern detection"
echo -e "  INPUT → f2b-sshd       (fail2ban SSH)        — brute-force"
echo ""
echo -e "${C}  Cron schedule:${X}"
crontab -l 2>/dev/null | grep -E 'deploy-blacklist|@reboot' | sed 's/^/  /'
echo ""
echo -e "${C}  Useful commands:${X}"
echo -e "  ${W}cscli decisions list${X}         — CrowdSec active bans"
echo -e "  ${W}fail2ban-client status sshd${X}  — fail2ban SSH jail stats"
echo -e "  ${W}ipset list vladblacklist | tail -20${X} — IPGuard blocked IPs"
echo -e "  ${W}iptables -L INPUT -n --line-numbers${X} — full iptables INPUT chain"
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
# = Rooted by VladiMIR + AI | v.2026.06.10b | github.com/GinCz =
