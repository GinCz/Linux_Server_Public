#!/usr/bin/env bash
# = Rooted by VladiMIR + AI | v.2026.06.09 | github.com/GinCz =
# Description: CrowdSec Installation & Configuration
# Target: 222-DE, 109-RU (FastPanel) and any VPN node
# Usage: bash <(curl -sL https://raw.githubusercontent.com/GinCz/Linux_Server_Public/main/scripts/install_crowdsec.sh)

clear
G='\033[1;32m'; Y='\033[1;33m'; C='\033[1;36m'; R='\033[1;31m'; X='\033[0m'
LINE="================================================================"

echo -e "${Y}${LINE}${X}"
echo -e "${Y}   CrowdSec Install & Configure | $(hostname) | $(date '+%Y-%m-%d %H:%M')${X}"
echo -e "${Y}${LINE}${X}"

WHITELIST_IPS=(
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

# Detect server type — reliable FastPanel detection via site log paths
IS_FASTPANEL=false
ls /var/www/*/data/logs/ 2>/dev/null | grep -q "." && IS_FASTPANEL=true

echo -e "${C}[1/5] Installing CrowdSec...${X}"
if ! command -v cscli &>/dev/null; then
    curl -s https://install.crowdsec.net | sh
    apt-get update -qq && apt-get install -y crowdsec
else
    echo -e "      ${G}Already installed: $(cscli version 2>/dev/null | head -1)${X}"
fi

echo -e "${C}[2/5] Installing Firewall Bouncer...${X}"
apt-get install -y crowdsec-firewall-bouncer-iptables 2>/dev/null || true
# Auto-detect real systemd service name
BOUNCER_SVC=""
for name in crowdsec-firewall-bouncer crowdsec-firewall-bouncer-iptables; do
    systemctl list-units --all 2>/dev/null | grep -q "$name" && BOUNCER_SVC="$name" && break
done
[ -z "$BOUNCER_SVC" ] && BOUNCER_SVC="crowdsec-firewall-bouncer"
echo -e "      ${G}Bouncer service: $BOUNCER_SVC${X}"

echo -e "${C}[3/5] Updating hub & installing collections...${X}"
cscli hub update 2>/dev/null || true
cscli collections install crowdsecurity/nginx 2>/dev/null || true
cscli collections install crowdsecurity/wordpress 2>/dev/null || true
cscli collections install crowdsecurity/http-cve 2>/dev/null || true
cscli collections install crowdsecurity/base-http-scenarios 2>/dev/null || true
cscli collections install crowdsecurity/sshd 2>/dev/null || true
cscli collections install crowdsecurity/linux 2>/dev/null || true

echo -e "${C}[4/5] Configuring log acquisition...${X}"
if [ "$IS_FASTPANEL" = true ]; then
    echo -e "      Detected: ${G}FastPanel server${X}"
    cat > /etc/crowdsec/acquis.yaml <<'EOC'
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
EOC
else
    echo -e "      Detected: ${G}VPN / standalone node${X}"
    cat > /etc/crowdsec/acquis.yaml <<'EOC'
filenames:
  - /var/log/auth.log
  - /var/log/syslog
labels:
  type: syslog
EOC
fi

echo -e "${C}[5/5] Adding whitelists...${X}"
mkdir -p /etc/crowdsec/parsers/s02-enrich
cat > /etc/crowdsec/parsers/s02-enrich/whitelist-vladimirips.yaml <<'EOW'
name: crowdsecurity/whitelist-vladimirips
description: Whitelist VladiMIR servers and VPN nodes
whitelist:
  reason: "VladiMIR trusted IP"
  ip:
    - "152.53.182.222"
    - "212.109.223.109"
    - "109.234.38.47"
    - "144.124.228.237"
    - "144.124.232.9"
    - "144.124.228.227"
    - "144.124.239.24"
    - "91.84.118.178"
    - "146.103.110.176"
    - "144.124.233.38"
    - "3.79.14.42"
    - "185.100.197.16"
    - "185.14.233.235"
    - "185.14.232.0"
    - "90.181.133.10"
EOW

for IP in "${WHITELIST_IPS[@]}"; do
    cscli decisions add --ip "$IP" --type whitelist --reason "VladiMIR trusted" 2>/dev/null || true
done

echo -e "${C}Restarting services...${X}"
systemctl restart crowdsec 2>/dev/null && echo -e "      ${G}crowdsec: OK${X}" || echo -e "      ${R}crowdsec: FAIL${X}"
systemctl restart "$BOUNCER_SVC" 2>/dev/null && echo -e "      ${G}$BOUNCER_SVC: OK${X}" || echo -e "      ${R}$BOUNCER_SVC: FAIL${X}"

echo -e "${Y}${LINE}${X}"
echo -e "${G}SUCCESS! CrowdSec active on $(hostname)${X}"
echo -e ""
echo -e "  ${C}cscli decisions list${X}     — active bans"
echo -e "  ${C}cscli alerts list -l 20${X}  — recent alerts"
echo -e "  ${C}cscli metrics${X}            — statistics"
echo -e "${Y}${LINE}${X}"
echo -e "  ${Y}Whitelisted IPs: ${#WHITELIST_IPS[@]}${X}"
for IP in "${WHITELIST_IPS[@]}"; do echo -e "    ${G}✓${X} $IP"; done
echo -e "${Y}${LINE}${X}"
# = Rooted by VladiMIR + AI | v.2026.06.09 | github.com/GinCz =
