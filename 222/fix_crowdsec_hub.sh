#!/bin/bash
clear
# =============================================================================
#  fix_crowdsec_hub.sh
# =============================================================================
#  Version    : v2026-04-05
#  Author     : Ing. VladiMIR Bulantsev
#  GitHub     : https://github.com/GinCz/Linux_Server_Public
#  Server     : 222-DE-NetCup (152.53.182.222)
# =============================================================================
#
#  PROBLEM
#  -------
#  CrowdSec fails to start with:
#  FATAL invalid hub index: unable to read index file:
#  open /etc/crowdsec/hub/.index.json: no such file or directory
#
#  CAUSE
#  -----
#  /etc/crowdsec/hub/ directory was missing (deleted or never created).
#  'cscli hub update' cannot download because the target dir doesn't exist.
#
#  FIX
#  ---
#  1. Stop crowdsec (kills restart loop)
#  2. Create /etc/crowdsec/hub/
#  3. Download .index.json directly via curl
#  4. Start crowdsec
#
#  ALSO APPLIED
#  ------------
#  - Ban TTL changed from 4h -> 168h in profiles.yaml
#  - 3 attacker IPs banned manually for 720h
#
# =============================================================================
#  = Rooted by VladiMIR | AI =
# =============================================================================

echo "Stopping CrowdSec..."
systemctl stop crowdsec

echo "Creating hub directory..."
mkdir -p /etc/crowdsec/hub

echo "Downloading hub index..."
curl -fsSL \
  "https://raw.githubusercontent.com/crowdsecurity/hub/master/.index.json" \
  -o /etc/crowdsec/hub/.index.json

if [ ! -s /etc/crowdsec/hub/.index.json ]; then
    echo "ERROR: Failed to download hub index!"
    exit 1
fi

echo "Hub index downloaded: $(ls -lh /etc/crowdsec/hub/.index.json | awk '{print $5}')"

echo "Starting CrowdSec..."
systemctl start crowdsec
sleep 8

systemctl status crowdsec --no-pager | head -8
echo
echo "CrowdSec hub fixed successfully."
echo "= Rooted by VladiMIR | AI ="
